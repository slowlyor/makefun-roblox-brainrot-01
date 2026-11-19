-- init.server.luau -- Brainrot Bazaar server bootstrap.
-- Builds the world, owns the remotes, runs the economy loops (income,
-- belt spawner, tsunami clock) and wires the pad/lock/gacha interactables
-- to GameState. All rules live in the modules; this script is the glue.
--
-- Remote protocol (ReplicatedStorage/BrainrotRemotes):
--   Action (RemoteEvent, client -> server): FireServer("rebirth") /
--     ("gacha") / ("lock") / ("collect") -- the two-tap and distance
--     rules are re-checked server-side, the client is never trusted.
--   State (RemoteEvent, server -> client): a GameState.snapshot table.
--   Toast (RemoteEvent, server -> client): one short string.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local GameState = require(script.GameState)
local WorldBuilder = require(script.WorldBuilder)
local BrainrotFactory = require(script.BrainrotFactory)
local MoveService = require(script.MoveService)
local Thief = require(script.Thief)
local GachaService = require(script.GachaService)

local rng = Random.new()

-- Remotes -----------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "BrainrotRemotes"
remotes.Parent = ReplicatedStorage
local actionRemote = Instance.new("RemoteEvent")
actionRemote.Name = "Action"
actionRemote.Parent = remotes
local stateRemote = Instance.new("RemoteEvent")
stateRemote.Name = "State"
stateRemote.Parent = remotes
local toastRemote = Instance.new("RemoteEvent")
toastRemote.Name = "Toast"
toastRemote.Parent = remotes

local function toast(player: Player, text: string)
	toastRemote:FireClient(player, text)
end

local function toastAll(text: string)
	toastRemote:FireAllClients(text)
end

local function pushState(player: Player)
	local state = GameState.get(player)
	if state then
		stateRemote:FireClient(player, GameState.snapshot(state))
	end
end

-- World -------------------------------------------------------------------
local refs = WorldBuilder.Build(Workspace)

local deps = {
	plots = refs.Plots,
	walkersFolder = refs.WalkersFolder,
	root = refs.Root,
	gachaBase = refs.GachaBase,
	padTop = refs.PadTop,
	rng = rng,
	toast = toast,
	toastAll = toastAll,
	pushState = pushState,
}
GachaService.attachPrompt(deps)
Thief.startLoop(deps)

-- Fountain water spins and the ferris wheel turns, slowly, forever.
task.spawn(function()
	local angle = 0
	while true do
		local dt = task.wait(0.1)
		angle += dt * 0.12
		refs.FountainWater.CFrame = CFrame.new(0, 1.35 - 0.075, 44) * CFrame.Angles(0, angle * 2, math.rad(90))
		WorldBuilder.RotateWheel(angle)
	end
end)

-- Players -------------------------------------------------------------------
local function characterSpawned(player: Player, character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root then
		root.CFrame = CFrame.new(0, 3, 26)
	end
end

Players.PlayerAdded:Connect(function(player)
	local state = GameState.join(player)
	if state.plotIndex == 0 then
		toast(player, "Semua base penuh! Kamu jadi penonton dulu.")
	else
		toast(player, "Selamat datang! Base-mu: BASE " .. state.plotIndex)
	end
	player.CharacterAdded:Connect(function(character)
		characterSpawned(player, character)
	end)
	if player.Character then
		characterSpawned(player, player.Character)
	end
	pushState(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local state = GameState.get(player)
	if state then
		for i = 1, GameState.PADS_PER_BASE do
			local pad = state.pads[i]
			if pad and pad.model then
				pad.model:Destroy()
			end
		end
	end
	GameState.leave(player)
end)

-- Income: every second, placed brainrots drip income*multiplier into
-- their owner's stored cash. Stored is banked only at the collect pad.
task.spawn(function()
	while true do
		task.wait(1)
		for player, state in pairs(GameState.all()) do
			local gain = GameState.baseIncome(state) * GameState.multiplier(state)
			if gain > 0 then
				state.stored += gain
			end
			pushState(player)
		end
	end
end)

-- Conveyor belt shop ---------------------------------------------------------
-- Brainrots spawn at the arch end (X=-66), ride the belt to X=66 and
-- despawn. Each carries a buy prompt: pay its (mutation-adjusted) price
-- and it hops off the belt and walks home to a free pad in your base.
local beltWalkers: { [Model]: boolean } = {}

local function buyBeltWalker(player: Player, model: Model)
	local state = GameState.get(player)
	if not state or state.plotIndex == 0 then
		toast(player, "Kamu belum punya base!")
		return
	end
	if not beltWalkers[model] then
		return -- already sold (or never was for sale)
	end
	local padIndex = GameState.freePad(state)
	if not padIndex then
		toast(player, "Base penuh! Jual/rebirth dulu atau tunggu pad kosong.")
		return
	end
	local price = model:GetAttribute("Price")
	if state.cash < price then
		toast(player, "Uang kurang: perlu " .. BrainrotData.formatMoney(price))
		return
	end
	state.cash -= price
	beltWalkers[model] = nil
	local prompt = model:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt:Destroy()
	end
	local defId = model:GetAttribute("BrainrotId")
	local mutation = model:GetAttribute("Mutation")
	if mutation == "" then
		mutation = nil
	end
	state.everOwned[defId] = true
	state.pads[padIndex] = { defId = defId, mutation = mutation, model = model, stored = 0 }
	MoveService.stop(model)
	local plot = refs.Plots[state.plotIndex]
	local padPos = plot.PadPositions[padIndex]
	local pos = model:GetPivot().Position
	toast(player, "Dapat " .. (BrainrotData.BY_ID[defId] and BrainrotData.BY_ID[defId].name or defId) .. "!")
	-- Off the belt (surface drops from belt top to ground), then home.
	MoveService.walk(model, { Vector3.new(pos.X, 0, 12), Vector3.new(padPos.X, 0, padPos.Z) }, 11, 0, function()
		local current = GameState.get(player)
		if current and current.pads[padIndex] and current.pads[padIndex].model == model then
			MoveService.placeOn(model, padPos.X, padPos.Z, refs.PadTop, 0, plot.Center.Z > 0 and -1 or 1)
		else
			model:Destroy()
		end
		pushState(player)
	end)
	pushState(player)
end

task.spawn(function()
	while true do
		task.wait(2.8)
		if MoveService.activeCount() < 26 then
			local def = BrainrotData.pickWeighted(rng, "beltWeight")
			local mutation = BrainrotData.rollMutation(rng:NextNumber())
			local model = BrainrotFactory.create(def, mutation)
			model.Parent = refs.WalkersFolder
			beltWalkers[model] = true
			MoveService.placeOn(model, -66, 0, refs.BeltTop, 1, 0)
			if def.rarity == "Divine" then
				local burst = WorldBuilder.sparkleBurst(refs.Root, Vector3.new(-66, refs.BeltTop, 0))
				task.delay(1.2, function()
					burst:Destroy()
				end)
				toastAll("BRAINROT DIVINE muncul di conveyor!")
			end
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "BuyPrompt"
			prompt.ActionText = "Beli " .. BrainrotData.formatMoney(BrainrotData.priceOf(def, mutation))
			prompt.ObjectText = (mutation and (mutation .. " ") or "") .. def.name
			prompt.HoldDuration = 0.25
			prompt.MaxActivationDistance = 13
			prompt.Parent = model.PrimaryPart
			prompt.Triggered:Connect(function(player)
				buyBeltWalker(player, model)
			end)
			MoveService.walk(model, { Vector3.new(66, 0, 0) }, 6, refs.BeltTop, function()
				beltWalkers[model] = nil
				model:Destroy()
			end)
		end
	end
end)

-- Tsunami ---------------------------------------------------------------------
-- Every 180s: a 10s warning, then the wave. Belt/walking brainrots are
-- washed away and any player caught outside a base is killed. Placed
-- brainrots on pads are safe -- the dash home is for the player.
local function isInsideAnyBase(pos: Vector3): boolean
	for _, plot in ipairs(refs.Plots) do
		if math.abs(pos.X - plot.Center.X) <= 22 and math.abs(pos.Z - plot.Center.Z) <= 15 then
			return true
		end
	end
	return false
end

task.spawn(function()
	local wave = Instance.new("Part")
	wave.Name = "TsunamiWave"
	wave.Size = Vector3.new(6, 26, 300)
	wave.Color = Color3.fromRGB(40, 140, 255)
	wave.Material = Enum.Material.Glass
	wave.Transparency = 0.35
	wave.Anchored = true
	wave.CanCollide = false
	wave.CFrame = CFrame.new(-400, 13, 0)
	wave.Parent = refs.Root

	while true do
		GameState.tsunamiIn = GameState.TSUNAMI_PERIOD
		GameState.tsunamiWarning = false
		while GameState.tsunamiIn > 0 do
			task.wait(1)
			GameState.tsunamiIn -= 1
			if GameState.tsunamiIn == GameState.TSUNAMI_WARNING then
				GameState.tsunamiWarning = true
				toastAll("TSUNAMI 10 detik lagi! Lari ke base terdekat!")
			end
		end
		-- Strike: sweep the wave visual across the map over ~4 seconds.
		task.spawn(function()
			for x = -200, 200, 8 do
				wave.CFrame = CFrame.new(x, 13, 0)
				task.wait(0.05)
			end
			wave.CFrame = CFrame.new(-400, 13, 0)
		end)
		for model in pairs(beltWalkers) do
			MoveService.stop(model)
			model:Destroy()
		end
		beltWalkers = {}
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and not isInsideAnyBase(root.Position) then
				humanoid.Health = 0
				toast(player, "Kamu tersapu tsunami! Brainrot di base tetap aman.")
			end
		end
		toastAll("Tsunami lewat! Conveyor mulai lagi.")
	end
end)

-- Client actions ---------------------------------------------------------------
-- Rebirth is two-tap on the client, but the server is the authority: it
-- re-checks the cost and wipes cash + brainrots for the multiplier.
actionRemote.OnServerEvent:Connect(function(player, action)
	local state = GameState.get(player)
	if not state then
		return
	end
	if action == "rebirth" then
		local cost = GameState.rebirthCost(state)
		if state.cash < cost then
			toast(player, "Rebirth perlu " .. BrainrotData.formatMoney(cost))
			return
		end
		for i = 1, GameState.PADS_PER_BASE do
			local pad = state.pads[i]
			if pad and pad.model then
				pad.model:Destroy()
			end
			state.pads[i] = nil
		end
		state.cash = 0
		state.stored = 0
		state.rebirths += 1
		toast(player, "REBIRTH! Pengali penghasilan sekarang x" .. string.format("%.2f", GameState.multiplier(state)))
		pushState(player)
	elseif action == "gacha" then
		GachaService.roll(player, deps)
	elseif action == "lock" then
		if state.plotIndex == 0 then
			return
		end
		if GameState.isLocked(state) then
			toast(player, "Base sudah terkunci (" .. GameState.lockSecondsLeft(state) .. " dtk lagi)")
			return
		end
		state.lockedUntil = os.clock() + GameState.LOCK_SECONDS
		toast(player, "Base terkunci 60 detik!")
		pushState(player)
	elseif action == "collect" then
		if state.stored >= 1 then
			local amount = math.floor(state.stored)
			state.cash += amount
			state.stored -= amount
			toast(player, "Panen " .. BrainrotData.formatMoney(amount) .. "!")
			pushState(player)
		end
	end
end)

-- Collect pads + lock buttons ----------------------------------------------
for _, plot in ipairs(refs.Plots) do
	local debounce = {}
	plot.CollectPad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local state = GameState.get(player)
		if not state or state.plotIndex ~= plot.Index then
			return
		end
		if debounce[player] and os.clock() - debounce[player] < 0.5 then
			return
		end
		debounce[player] = os.clock()
		if state.stored >= 1 then
			local amount = math.floor(state.stored)
			state.cash += amount
			state.stored -= amount
			toast(player, "Panen " .. BrainrotData.formatMoney(amount) .. " dari brainrot-mu!")
			pushState(player)
		end
	end)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LockPrompt"
	prompt.ActionText = "Kunci Base (60 dtk)"
	prompt.ObjectText = "BASE " .. plot.Index
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.Parent = plot.LockButton
	prompt.Triggered:Connect(function(player)
		local state = GameState.get(player)
		if not state or state.plotIndex ~= plot.Index then
			toast(player, "Ini bukan base-mu!")
			return
		end
		if GameState.isLocked(state) then
			toast(player, "Base sudah terkunci (" .. GameState.lockSecondsLeft(state) .. " dtk lagi)")
			return
		end
		state.lockedUntil = os.clock() + GameState.LOCK_SECONDS
		toast(player, "Base terkunci 60 detik! Pencuri tidak bisa masuk.")
		pushState(player)
	end)
end
