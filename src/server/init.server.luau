-- init.server.luau -- Brainrot Bazaar server orchestration.
-- Builds the world, runs the conveyor-belt shop, pad income, collecting,
-- base locking, the thief NPC, the tsunami, gacha and rebirths, and
-- keeps every client's HUD in sync. State lives in GameState only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local GameState = require(script:WaitForChild("GameState"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local BrainrotFactory = require(script:WaitForChild("BrainrotFactory"))
local MoveService = require(script:WaitForChild("MoveService"))
local Thief = require(script:WaitForChild("Thief"))
local GachaService = require(script:WaitForChild("GachaService"))

local rng = Random.new()

-- Remotes the clients read: state snapshots and toast messages up,
-- rebirth requests down.
local remotes = Instance.new("Folder")
remotes.Name = "BrainrotRemotes"
remotes.Parent = ReplicatedStorage
local stateSync = Instance.new("RemoteEvent")
stateSync.Name = "StateSync"
stateSync.Parent = remotes
local toastRemote = Instance.new("RemoteEvent")
toastRemote.Name = "Toast"
toastRemote.Parent = remotes
local rebirthRequest = Instance.new("RemoteEvent")
rebirthRequest.Name = "RebirthRequest"
rebirthRequest.Parent = remotes

local refs = WorldBuilder.Build()

local function toastPlayer(player, text)
	toastRemote:FireClient(player, text)
end

local function toastAll(text)
	toastRemote:FireAllClients(text)
end

-- Settle a brainrot model onto a pad of the player's base and start it
-- earning. Used by belt purchases and by the gacha machine alike.
local function placeBrainrot(state, padIndex, model)
	if GameState.Players[state.UserId] ~= state then
		model:Destroy()
		return
	end
	if state.Pads[padIndex] then
		padIndex = GameState.FreePad(state)
		if not padIndex then
			model:Destroy()
			return
		end
	end
	local padPos = refs.Plots[state.PlotIndex].PadPositions[padIndex]
	MoveService.PlaceAt(model, padPos.X, padPos.Z, 0.45, math.atan2(
		refs.Plots[state.PlotIndex].Center.X - padPos.X,
		refs.Plots[state.PlotIndex].Center.Z - padPos.Z))
	GameState.PlaceOnPad(state, padIndex, model:GetAttribute("DefIndex"),
		model:GetAttribute("Mutation"), model)
end

local deps = {
	GameState = GameState,
	BrainrotFactory = BrainrotFactory,
	MoveService = MoveService,
	Refs = refs,
	Rng = rng,
	ToastAll = toastAll,
	ToastPlayer = toastPlayer,
	PlaceBrainrot = placeBrainrot,
}

----------------------------------------------------------------------
-- The conveyor belt shop
----------------------------------------------------------------------

local beltModels = {} -- [model] = true, everything currently for sale

local function spawnBeltBrainrot()
	local defIndex = BrainrotData.RollCharacter(rng, BrainrotData.BeltWeights)
	local mutation = BrainrotData.RollMutation(rng)
	local model = BrainrotFactory.Create(defIndex, mutation.Name, Vector3.new(refs.BeltStartX, 0, refs.BeltZ))
	model:SetAttribute("ForSale", true)
	model.Parent = refs.World
	beltModels[model] = true

	if BrainrotData.Get(defIndex).Rarity == "Divine" then
		toastAll("DIVINE MUNCUL DI TOKO! " .. BrainrotData.Get(defIndex).Name .. " berjalan di sabuk!")
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Beli " .. BrainrotData.FormatMoney(BrainrotData.PriceFor(defIndex, mutation.Name))
	prompt.ObjectText = BrainrotData.Get(defIndex).Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		buyBeltBrainrot(player, model, prompt)
	end)

	MoveService.WalkTo(model, refs.BeltEndX, refs.BeltZ, MoveService.BELT_Y, 6, function()
		if model:GetAttribute("ForSale") then
			beltModels[model] = nil
			model:Destroy()
		end
	end)
end

function buyBeltBrainrot(player, model, prompt)
	if not model:GetAttribute("ForSale") or not model.Parent then
		return
	end
	if model:GetAttribute("Claimed") then
		return -- another player's purchase is already walking this one home
	end
	local state = GameState.Get(player)
	if not state then
		return
	end
	local defIndex = model:GetAttribute("DefIndex")
	local mutationName = model:GetAttribute("Mutation")
	local price = BrainrotData.PriceFor(defIndex, mutationName)
	local padIndex = GameState.FreePad(state)
	if not padIndex then
		toastPlayer(player, "Basis PENUH! Jual ruang dulu (atau rebirth).")
		return
	end
	if state.Cash < price then
		toastPlayer(player, "Uang tidak cukup! Butuh " .. BrainrotData.FormatMoney(price))
		return
	end

	state.Cash -= price
	model:SetAttribute("Claimed", true)
	model:SetAttribute("ForSale", false)
	beltModels[model] = nil
	prompt:Destroy()
	toastPlayer(player, "Kamu membeli " .. BrainrotData.Get(defIndex).Name .. "!")

	-- Off the belt, across the plaza path, onto the pad.
	local plot = refs.Plots[state.PlotIndex]
	local padPos = plot.PadPositions[padIndex]
	MoveService.WalkPath(model, {
		{ X = padPos.X, Z = refs.BeltZ, BaseY = MoveService.BELT_Y, Speed = 8 },
		{ X = padPos.X, Z = plot.Center.Z + plot.FrontDir * 20, BaseY = MoveService.GROUND_Y, Speed = 8 },
		{ X = padPos.X, Z = padPos.Z, BaseY = 0.45, Speed = 8 },
	}, function()
		placeBrainrot(state, padIndex, model)
	end)
end

task.spawn(function()
	while true do
		task.wait(2.2)
		local count = 0
		for _ in pairs(beltModels) do
			count += 1
		end
		if count < 9 then
			spawnBeltBrainrot()
		end
	end
end)

----------------------------------------------------------------------
-- Collect pads, lock buttons and the gacha machine
----------------------------------------------------------------------

for _, plot in ipairs(refs.Plots) do
	local lastCollect = {}
	plot.CollectPad.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		local state = GameState.Get(player)
		if not state or state.PlotIndex ~= plot.Index then
			return
		end
		local now = os.clock()
		if lastCollect[player.UserId] and now - lastCollect[player.UserId] < 1 then
			return
		end
		lastCollect[player.UserId] = now
		local amount = GameState.Collect(state)
		if amount > 0 then
			toastPlayer(player, "Kamu memanen " .. BrainrotData.FormatMoney(amount) .. "!")
		end
	end)

	local lockPrompt = Instance.new("ProximityPrompt")
	lockPrompt.ActionText = "Kunci Basis 60 detik"
	lockPrompt.ObjectText = "Tombol Kunci"
	lockPrompt.MaxActivationDistance = 10
	lockPrompt.Parent = plot.LockButton
	lockPrompt.Triggered:Connect(function(player)
		local state = GameState.Get(player)
		if not state or state.PlotIndex ~= plot.Index then
			return
		end
		if GameState.IsLocked(state) then
			toastPlayer(player, "Basis sudah terkunci (" .. GameState.LockSecondsLeft(state) .. " dtk).")
			return
		end
		state.LockedUntil = os.clock() + GameState.LOCK_SECONDS
		toastPlayer(player, "Basis TERKUNCI selama 60 detik! Pencuri tidak bisa masuk.")
	end)
end

local gachaPrompt = Instance.new("ProximityPrompt")
gachaPrompt.ActionText = "Putar Gacha"
gachaPrompt.ObjectText = "Mesin Gacha Brainrot"
gachaPrompt.MaxActivationDistance = 12
gachaPrompt.Parent = refs.GachaMachine
gachaPrompt.Triggered:Connect(function(player)
	local state = GameState.Get(player)
	if state then
		GachaService.Roll(state, deps)
	end
end)

----------------------------------------------------------------------
-- Rebirth (the client asks twice before firing this; see Hud)
----------------------------------------------------------------------

rebirthRequest.OnServerEvent:Connect(function(player)
	local state = GameState.Get(player)
	if not state then
		return
	end
	local cost = GameState.RebirthCost(state)
	if state.Cash < cost then
		toastPlayer(player, "Rebirth butuh " .. BrainrotData.FormatMoney(cost))
		return
	end
	for _, pad in pairs(state.Pads) do
		if pad.Model then
			MoveService.Stop(pad.Model)
			pad.Model:Destroy()
		end
	end
	GameState.ApplyRebirth(state)
	toastPlayer(player, string.format("REBIRTH! Penghasilan permanen x%.2f", GameState.Multiplier(state)))
end)

----------------------------------------------------------------------
-- Players joining and leaving
----------------------------------------------------------------------

local function freePlotIndex()
	for i = 1, 8 do
		if not GameState.PlotOwners[i] then
			return i
		end
	end
	return nil
end

Players.PlayerAdded:Connect(function(player)
	local plotIndex = freePlotIndex()
	if not plotIndex then
		toastPlayer(player, "Semua basis penuh! Menonton dulu ya.")
		return
	end
	local state = GameState.CreatePlayer(player, plotIndex)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		local root = character:WaitForChild("HumanoidRootPart", 5)
		if root then
			root.CFrame = CFrame.new(Vector3.new(0, 3, 26)) * CFrame.Angles(0, math.rad(180), 0)
		end
	end)
	toastPlayer(player, "Selamat datang! Basismu: Basis " .. string.char(64 + plotIndex)
		.. ". Beli brainrot dari sabuk berjalan!")
end)

Players.PlayerRemoving:Connect(function(player)
	local state = GameState.RemovePlayer(player)
	if state then
		for _, pad in pairs(state.Pads) do
			if pad.Model then
				pad.Model:Destroy()
			end
		end
	end
end)

----------------------------------------------------------------------
-- Ambient animation: ferris wheel, belt stripes, fountain foam
----------------------------------------------------------------------

local wheelAngle = 0
local foamOrbs = {}
for i = 1, 3 do
	local orb = Instance.new("Part")
	orb.Name = "FountainFoam" .. i
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(0.9, 0.9, 0.9)
	orb.Color = Color3.fromRGB(230, 250, 255)
	orb.Material = Enum.Material.Neon
	orb.Anchored = true
	orb.CanCollide = false
	orb.Parent = refs.World
	foamOrbs[i] = orb
end

RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	MoveService.Update(dt, now)

	wheelAngle = (wheelAngle + dt * 0.12) % (math.pi * 2)
	if refs.Wheel and refs.Wheel.PrimaryPart then
		refs.Wheel:PivotTo(CFrame.new(refs.WheelHubPos) * CFrame.Angles(wheelAngle, 0, 0))
	end
	for _, stripe in ipairs(refs.Stripes) do
		local x = stripe.Position.X + dt * 6
		if x > 70 then
			x = -70
		end
		stripe.Position = Vector3.new(x, stripe.Position.Y, stripe.Position.Z)
	end
	for i, orb in ipairs(foamOrbs) do
		local a = now * 0.9 + i * (math.pi * 2 / 3)
		orb.Position = Vector3.new(math.cos(a) * 5, 1.6 + math.sin(now * 2 + i) * 0.15, 44 + math.sin(a) * 5)
	end
	if refs.Beacon then
		local pulse = 4 + math.sin(now * 3) * 0.5
		refs.Beacon.Size = Vector3.new(pulse, pulse, pulse)
	end
end)

----------------------------------------------------------------------
-- Timed world events: income ticks, the thief, the tsunami, HUD sync
----------------------------------------------------------------------

local TSUNAMI_PERIOD = 180
local TSUNAMI_WARNING = 10
local nextTsunamiAt = os.clock() + TSUNAMI_PERIOD
local tsunamiWarned = false
local nextThiefAt = os.clock() + Thief.RAID_INTERVAL

local function tsunamiSecondsLeft()
	return math.max(0, math.ceil(nextTsunamiAt - os.clock()))
end

local function fireTsunami()
	toastAll("TSUNAMI! Semua brainrot di sabuk hanyut! Pemain di luar basis hanyut!")
	for model in pairs(beltModels) do
		MoveService.Stop(model)
		model:Destroy()
	end
	beltModels = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and not WorldBuilder.PositionInAnyPlot(refs, root.Position) then
			humanoid.Health = 0
		end
	end
end

task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()
		for _, state in pairs(GameState.Players) do
			GameState.TickIncome(state, 1)
			for _, pad in pairs(state.Pads) do
				if pad.Model then
					BrainrotFactory.SetStoredLabel(pad.Model, pad.Stored)
				end
			end
			local plot = refs.Plots[state.PlotIndex]
			if plot and plot.LockShield then
				local locked = GameState.IsLocked(state)
				plot.LockShield.Transparency = locked and 0.65 or 1
				plot.LockShield.CanCollide = locked
			end
			stateSync:FireClient(state.Player, GameState.Snapshot(state,
				tsunamiSecondsLeft(), math.max(0, math.ceil(nextThiefAt - now))))
		end

		if not tsunamiWarned and nextTsunamiAt - now <= TSUNAMI_WARNING then
			tsunamiWarned = true
			toastAll("PERINGATAN: Tsunami datang dalam 10 detik! Masuk ke basis sekarang!")
		end
		if now >= nextTsunamiAt then
			fireTsunami()
			nextTsunamiAt = now + TSUNAMI_PERIOD
			tsunamiWarned = false
		end
		if now >= nextThiefAt then
			nextThiefAt = now + Thief.RAID_INTERVAL
			Thief.RunRaid(deps)
		end
	end
end)

-- Startup layout audit: log the anchor positions from the same layout
-- constants WorldBuilder built from, so a bad coordinate is visible in
-- the server log before a player ever joins.
for name, entry in pairs(WorldBuilder.Layout) do
	if type(entry) == "table" and entry.X then
		print(string.format("[BrainrotBazaar] Layout %s at (%d, %d) baseY=%d", name, entry.X, entry.Z, entry.BaseY))
	end
end
for i, c in ipairs(WorldBuilder.Layout.PlotCenters) do
	print(string.format("[BrainrotBazaar] Layout Plot%d at (%d, %d) baseY=%d", i, c.X, c.Z, c.BaseY))
end
print("[BrainrotBazaar] Server ready: 8 bases, belt shop, gacha, thief, tsunami.")
