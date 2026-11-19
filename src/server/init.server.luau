-- init.server.luau (ServerScriptService.Server)
-- Brainrot Bazaar bootstrap: builds the world, wires the remotes, runs the
-- conveyor-belt shop, the income tick, collect pads, base locks, rebirth,
-- the tsunami cycle, the gacha machine and the thief.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))

local GameState = require(script:WaitForChild("GameState"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local BrainrotFactory = require(script:WaitForChild("BrainrotFactory"))
local MoveService = require(script:WaitForChild("MoveService"))
local Thief = require(script:WaitForChild("Thief"))
local GachaService = require(script:WaitForChild("GachaService"))

-- Remotes the client HUD and index talk through.
local remotes = Instance.new("Folder")
remotes.Name = "BrainrotRemotes"
remotes.Parent = ReplicatedStorage

local toastEvent = Instance.new("RemoteEvent")
toastEvent.Name = "Toast"
toastEvent.Parent = remotes

local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "StateUpdate"
stateEvent.Parent = remotes

local rebirthEvent = Instance.new("RemoteEvent")
rebirthEvent.Name = "RebirthRequest"
rebirthEvent.Parent = remotes

local tsunamiValue = Instance.new("NumberValue")
tsunamiValue.Name = "TsunamiIn"
tsunamiValue.Value = 180
tsunamiValue.Parent = ReplicatedStorage

local function toast(player, message)
	if player then
		toastEvent:FireClient(player, message)
	end
end

local function toastAll(message)
	toastEvent:FireAllClients(message)
end

local function syncState(player)
	local record = GameState.Get(player)
	if not record then
		return
	end
	stateEvent:FireClient(player, {
		Cash = math.floor(record.Cash),
		Stored = math.floor(record.Stored),
		Income = GameState.IncomePerSecond(record),
		Rebirths = record.Rebirths,
		Multiplier = GameState.Multiplier(record),
		RebirthCost = GameState.RebirthCost(record),
		Locked = GameState.IsLocked(record),
		GachaCost = GachaService.CostFor(record),
		BaseIndex = record.BaseIndex,
	})
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local cashValue = stats:FindFirstChild("Cash")
		if cashValue then
			cashValue.Value = math.floor(record.Cash)
		end
		local rebirthValue = stats:FindFirstChild("Rebirths")
		if rebirthValue then
			rebirthValue.Value = record.Rebirths
		end
	end
end

-- Build the world and start its ambient animation.
local handles = WorldBuilder.Build(GameState)
WorldBuilder.Animate(handles)

local beltFolder = Instance.new("Folder")
beltFolder.Name = "BeltBrainrots"
beltFolder.Parent = workspace

-- Spawn pad in the plaza, south side under the rainbow arch.
local spawnPad = Instance.new("SpawnLocation")
spawnPad.Name = "BazaarSpawn"
spawnPad.Size = Vector3.new(10, 1, 10)
spawnPad.CFrame = CFrame.new(0, 0.5, 58)
spawnPad.Color = Color3.fromRGB(255, 170, 60)
spawnPad.Material = Enum.Material.Neon
spawnPad.Anchored = true
spawnPad.Neutral = true
spawnPad.Parent = workspace

-- The gacha machine stands in the plaza; its context is shared with Thief.
local machine = GachaService.Build(WorldBuilder)
local ctx = {
	GameState = GameState,
	MoveService = MoveService,
	BrainrotFactory = BrainrotFactory,
	BrainrotData = BrainrotData,
	Toast = toast,
	ToastAll = toastAll,
	SyncState = syncState,
	Machine = machine,
}
GachaService.Start(ctx)
Thief.Start(ctx)

----------------------------------------------------------------------
-- Player lifecycle
----------------------------------------------------------------------

local function setupLeaderstats(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = GameState.START_CASH
	cashValue.Parent = stats
	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = stats
	stats.Parent = player
end

local function renameBaseSign(record)
	local bases = handles.World:FindFirstChild("Bases")
	if not bases then
		return
	end
	local base = bases:FindFirstChild("Base" .. record.BaseIndex)
	if not base then
		return
	end
	local sign = base:FindFirstChild("OwnerSign")
	local board = sign and sign:FindFirstChild("Board")
	local gui = board and board:FindFirstChildOfClass("SurfaceGui")
	local label = gui and gui:FindFirstChildOfClass("TextLabel")
	if label then
		label.Text = "BASE " .. record.Player.DisplayName
	end
end

local function onCharacterAdded(player, character)
	local record = GameState.Get(player)
	if not record then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end
	local origin = GameState.GetBaseOrigin(record.BaseIndex)
	local frontZ = origin.Z > 20 and -20 or 20
	root.CFrame = CFrame.new(origin.X, 4, origin.Z + frontZ)
end

local function onPlayerAdded(player)
	setupLeaderstats(player)
	local record = GameState.ClaimBase(player)
	if not record then
		toast(player, "Server penuh: semua base sudah terisi!")
		return
	end
	renameBaseSign(record)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
	task.delay(1, function()
		toast(player, "Selamat datang di Brainrot Bazaar! Beli brainrot dari ban berjalan.")
		syncState(player)
	end)
end

local function onPlayerRemoving(player)
	local record = GameState.Get(player)
	if record then
		for _, pad in ipairs(record.Pads) do
			if pad and pad.Model then
				pad.Model:Destroy()
			end
		end
	end
	GameState.ReleasePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

----------------------------------------------------------------------
-- Collect pads and lock buttons
----------------------------------------------------------------------

local lastCollect = {}
local function wireBaseInteractions()
	local bases = handles.World:WaitForChild("Bases")
	for i = 1, GameState.BASE_COUNT do
		local base = bases:WaitForChild("Base" .. i)
		local collectPad = base:WaitForChild("CollectPad")
		collectPad.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			local record = GameState.Get(player)
			if not record or record.BaseIndex ~= i then
				return
			end
			local now = os.clock()
			if lastCollect[player] and now - lastCollect[player] < 0.6 then
				return
			end
			lastCollect[player] = now
			if record.Stored >= 1 then
				local amount = math.floor(record.Stored)
				record.Cash += amount
				record.Stored = 0
				toast(player, "Panen! +" .. BrainrotData.FormatMoney(amount))
				syncState(player)
			end
		end)

		local lockButton = base:WaitForChild("LockButton")
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "LockPrompt"
		prompt.ActionText = "Kunci Base (60 dtk)"
		prompt.ObjectText = "Kunci Base"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 12
		prompt.Parent = lockButton
		prompt.Triggered:Connect(function(player)
			local record = GameState.Get(player)
			if not record or record.BaseIndex ~= i then
				toast(player, "Ini bukan base kamu!")
				return
			end
			if GameState.IsLocked(record) then
				toast(player, "Base sudah terkunci.")
				return
			end
			GameState.LockBase(record)
			toast(player, "Base terkunci 60 detik. Aman dari pencuri!")
			lockButton.Color = Color3.fromRGB(255, 70, 70)
			syncState(player)
			task.delay(GameState.LOCK_SECONDS, function()
				lockButton.Color = Color3.fromRGB(255, 190, 40)
				if GameState.Get(player) then
					toast(player, "Kunci base kamu sudah terbuka.")
					syncState(player)
				end
			end)
		end)
	end
end
wireBaseInteractions()

----------------------------------------------------------------------
-- The conveyor belt shop
----------------------------------------------------------------------

local MAX_BELT = 7
local BELT_LIFT = 2.3

-- Live belt occupancy is just the folder's child count: a purchased
-- brainrot leaves the folder, a sold-out one is destroyed out of it.
local function beltCount()
	return #beltFolder:GetChildren()
end

local function buyBeltBrainrot(player, model, entry, mutation, price, income)
	local record = GameState.Get(player)
	if not record then
		return
	end
	local padIndex = GameState.FindFreePad(record)
	if not padIndex then
		toast(player, "Base penuh! Brainrot tidak bisa dibeli.")
		return
	end
	if record.Cash < price then
		toast(player, "Uang kurang: butuh " .. BrainrotData.FormatMoney(price))
		return
	end
	record.Cash -= price
	GameState.PlaceOnPad(record, padIndex, entry, mutation, income)
	local prompt = model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt:Destroy()
	end
	model.Parent = workspace
	toast(player, "Membeli " .. entry.Name .. "! Dia jalan ke base kamu.")
	syncState(player)

	local padPos = GameState.GetPadPosition(record.BaseIndex, padIndex)
	local current = model:GetPivot().Position
	MoveService.Walk(model, {
		Vector3.new(current.X, 0, 42),
		Vector3.new(padPos.X, 0, padPos.Z + (padPos.Z < 42 and -13 or 13)),
		padPos,
	}, 13, 2.1, function()
		if record.Pads[padIndex] then
			record.Pads[padIndex].Model = model
		else
			model:Destroy()
		end
	end)
end

local function spawnBeltBrainrot(rng)
	local entry = BrainrotData.RollEntry(rng)
	local mutation = BrainrotData.RollMutation(rng)
	local price = BrainrotData.PriceOf(entry, mutation)
	local income = BrainrotData.IncomeOf(entry, mutation)
	local rarity = BrainrotData.GetRarity(entry.Rarity)

	local model = BrainrotFactory.Create(entry, mutation, tostring(income), rarity.Color)
	model.Parent = beltFolder
	MoveService.PlaceAt(model, GameState.BELT_START + Vector3.new(0, BELT_LIFT, 0), math.pi / 2)
	if entry.Rarity == "Divine" then
		BrainrotFactory.SparkleBurst(GameState.BELT_START)
		toastAll("BRAINROT DIVINE muncul di ban berjalan: " .. entry.Name .. "!")
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Beli " .. BrainrotData.FormatMoney(price)
	prompt.ObjectText = entry.Name .. " (" .. entry.Rarity .. ")"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 13
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		buyBeltBrainrot(player, model, entry, mutation, price, income)
	end)

	MoveService.Walk(model, { GameState.BELT_END }, 6.5, BELT_LIFT, function()
		model:Destroy()
	end)
end

task.spawn(function()
	local rng = Random.new()
	task.wait(2)
	while true do
		if beltCount() < MAX_BELT then
			spawnBeltBrainrot(rng)
		end
		task.wait(2.8)
	end
end)

----------------------------------------------------------------------
-- Income tick
----------------------------------------------------------------------

task.spawn(function()
	while true do
		task.wait(1)
		for _, record in pairs(GameState.Players) do
			local gain = GameState.IncomePerSecond(record)
			if gain > 0 then
				record.Stored += gain
			end
			syncState(record.Player)
		end
	end
end)

----------------------------------------------------------------------
-- Rebirth
----------------------------------------------------------------------

rebirthEvent.OnServerEvent:Connect(function(player)
	local record = GameState.Get(player)
	if not record then
		return
	end
	local cost = GameState.RebirthCost(record)
	if GameState.TryRebirth(record) then
		toast(player, "REBIRTH! Pengali penghasilan sekarang x" .. string.format("%.2f", GameState.Multiplier(record)))
	else
		toast(player, "Rebirth butuh " .. BrainrotData.FormatMoney(cost) .. " (tunai + simpanan).")
	end
	syncState(player)
end)

----------------------------------------------------------------------
-- Tsunami cycle: every 180 s, 10 s warning, then the wave.
----------------------------------------------------------------------

local TSUNAMI_PERIOD = 180
local TSUNAMI_WARNING = 10

local function runTsunami()
	toastAll("TSUNAMI DATANG! Masuk ke dalam base sekarang juga!")
	local wave = Instance.new("Part")
	wave.Name = "TsunamiWave"
	wave.Size = Vector3.new(14, 26, 260)
	wave.Color = Color3.fromRGB(40, 140, 255)
	wave.Material = Enum.Material.Glass
	wave.Transparency = 0.25
	wave.Anchored = true
	wave.CanCollide = false
	wave.CFrame = CFrame.new(-150, 10, 20)
	wave.Parent = workspace

	-- The wave washes every unsold belt brainrot away at first touch.
	for _, model in ipairs(beltFolder:GetChildren()) do
		model:Destroy()
	end

	local killed = {}
	local startClock = os.clock()
	while os.clock() - startClock < 7 do
		local t = (os.clock() - startClock) / 7
		local wx = -150 + t * 300
		wave.CFrame = CFrame.new(wx, 10, 20)
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 and not killed[player] then
				if math.abs(root.Position.X - wx) < 9 and not GameState.IsInsideAnyBase(root.Position) then
					killed[player] = true
					humanoid.Health = 0
					toast(player, "Kamu tersapu tsunami! Brainrot di base tetap aman.")
				end
			end
		end
		task.wait(0.05)
	end
	wave:Destroy()
	toastAll("Tsunami lewat. Ban berjalan mulai lagi!")
end

task.spawn(function()
	local remaining = TSUNAMI_PERIOD
	while true do
		task.wait(1)
		remaining -= 1
		tsunamiValue.Value = remaining
		if remaining == TSUNAMI_WARNING then
			toastAll("Peringatan: tsunami dalam 10 detik! Masuk base!")
		end
		if remaining <= 0 then
			runTsunami()
			remaining = TSUNAMI_PERIOD
			tsunamiValue.Value = remaining
		end
	end
end)

print("Brainrot Bazaar server started: 24 brainrots, 8 bases, gacha + thief + tsunami live.")
