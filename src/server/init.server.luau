-- init.server.luau
-- Brainrot Bazaar: server bootstrap and the game's conductor.
-- Builds the world, wires every prompt and remote, runs the belt
-- spawner, the income tick, the tsunami clock and the plaza
-- animations. Rules live in GameState; this file only connects them.

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

local TSUNAMI_PERIOD = 180
local TSUNAMI_WARNING = 10
local BELT_TOP_Y = WorldBuilder.Layout.Belt.TopY
local BELT_SPAWN_X = -64
local BELT_END_X = 64
local BELT_Z = WorldBuilder.Layout.Belt.Z
local MAX_BELT = 10
local BELT_WALK_SPEED = 6

local rng = Random.new()
local world = WorldBuilder.Build()
MoveService.Start()

-- Remotes ------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "BB_Remotes"
remotes.Parent = ReplicatedStorage

local stateRemote = Instance.new("RemoteEvent")
stateRemote.Name = "State"
stateRemote.Parent = remotes

local toastRemote = Instance.new("RemoteEvent")
toastRemote.Name = "Toast"
toastRemote.Parent = remotes

local actionRemote = Instance.new("RemoteEvent")
actionRemote.Name = "Action"
actionRemote.Parent = remotes

local nextTsunamiAt = GameState.Now() + TSUNAMI_PERIOD

local function toastPlayer(player, text)
	toastRemote:FireClient(player, text)
end

local function toastAll(text)
	toastRemote:FireAllClients(text)
end

local function buildState(player, data)
	return {
		Cash = math.floor(data.Cash),
		IncomePerSecond = GameState.IncomePerSecond(data),
		Stored = GameState.StoredTotal(data),
		Multiplier = GameState.Multiplier(data),
		Rebirths = data.Rebirths,
		RebirthCost = GameState.RebirthCost(data),
		GachaCost = GameState.GachaCost(data),
		GachaRolls = data.GachaRolls,
		LockedSeconds = GameState.LockSecondsLeft(data),
		Occupied = GameState.OccupiedCount(data),
		PadsMax = GameState.PADS_PER_BASE,
		Collection = GameState.CollectionList(data),
		CollectionCount = GameState.CollectionCount(data),
		CollectionTotal = BrainrotData.Count(),
		TsunamiIn = math.max(0, math.ceil(nextTsunamiAt - GameState.Now())),
		PlotIndex = data.PlotIndex,
	}
end

local function syncPlayer(player)
	local data = GameState.Get(player)
	if not data then
		return
	end
	stateRemote:FireClient(player, buildState(player, data))
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local cash = stats:FindFirstChild("Cash")
		if cash then
			cash.Value = math.floor(data.Cash)
		end
		local rebirths = stats:FindFirstChild("Rebirth")
		if rebirths then
			rebirths.Value = data.Rebirths
		end
	end
end

local function syncAll()
	for player in pairs(GameState.Players) do
		syncPlayer(player)
	end
end

-- Context handed to the services so they never require each other.
local ctx = {
	GameState = GameState,
	BrainrotData = BrainrotData,
	World = world,
	Factory = BrainrotFactory,
	MoveService = MoveService,
	Rng = rng,
	ToastPlayer = toastPlayer,
	ToastAll = toastAll,
	SyncPlayer = syncPlayer,
}

-- Bases ---------------------------------------------------------------
local plotOwner = {} -- [plotIndex] -> Player

local function claimPlot(player)
	for i = 1, #world.Plots do
		if plotOwner[i] == nil then
			plotOwner[i] = player
			return i
		end
	end
	return nil
end

local function setBarrier(data, on)
	local plot = world.Plots[data.PlotIndex]
	if not plot then
		return
	end
	for _, wall in ipairs(plot.Barrier) do
		wall.Visible = on
		wall.CanCollide = on
	end
	local button = plot.LockButton
	if button then
		button.Color = on and Color3.fromRGB(60, 220, 90) or Color3.fromRGB(255, 90, 90)
	end
end

local function doLock(player)
	local data = GameState.Get(player)
	if not data then
		return
	end
	if GameState.IsLocked(data) then
		toastPlayer(player, "Base sudah terkunci (" .. GameState.LockSecondsLeft(data) .. "s).")
		return
	end
	data.LockUntil = GameState.Now() + GameState.LOCK_SECONDS
	setBarrier(data, true)
	toastPlayer(player, "Base terkunci 60 detik! Pencuri tidak bisa masuk.")
	task.delay(GameState.LOCK_SECONDS, function()
		if GameState.Get(player) == data and not GameState.IsLocked(data) then
			setBarrier(data, false)
			toastPlayer(player, "Kunci base habis.")
			syncPlayer(player)
		end
	end)
	syncPlayer(player)
end

local function doCollect(player)
	local data = GameState.Get(player)
	if not data then
		return
	end
	local amount = GameState.Collect(data)
	if amount > 0 then
		toastPlayer(player, "Panen $" .. amount .. "!")
	else
		toastPlayer(player, "Belum ada uang tersimpan.")
	end
	syncPlayer(player)
end

local function doRebirth(player)
	local data = GameState.Get(player)
	if not data then
		return
	end
	local cost = GameState.RebirthCost(data)
	if data.Cash < cost then
		toastPlayer(player, "Rebirth butuh $" .. cost .. ".")
		return
	end
	setBarrier(data, false)
	GameState.DoRebirth(data)
	toastPlayer(player, "REBIRTH! Penghasilan permanen x" .. string.format("%.2f", GameState.Multiplier(data)))
	syncPlayer(player)
end

-- Buying from the belt -------------------------------------------------
local beltModels = {}

local function placeOnPad(player, data, def, mutation, price, income)
	local padIndex = GameState.FreePad(data)
	if not padIndex then
		return false
	end
	local plot = world.Plots[data.PlotIndex]
	local entry = { DefId = def.Id, Mutation = mutation.Name, Price = price, Income = income, Stored = 0 }
	GameState.PlaceBrainrot(data, padIndex, entry)
	data.TotalBuys += 1
	local padPos = plot.Pads[padIndex]
	local placed = BrainrotFactory.Create(def, mutation.Name)
	placed.Parent = workspace
	placed:PivotTo(CFrame.new(padPos.X, padPos.Y + BrainrotFactory.ROOT_LIFT, padPos.Z))
	local mutText = mutation.Name ~= "Normal" and (" " .. mutation.Name) or ""
	BrainrotFactory.SetLabel(placed, def.Name .. mutText, "$" .. income .. "/s", BrainrotData.RARITY_COLORS[def.Rarity])
	data.PadModels[padIndex] = placed
	if def.Rarity == "Divine" then
		BrainrotFactory.SparkleBurst(padPos + Vector3.new(0, 1, 0))
	end
	return true
end

local function tryBuy(player, beltModel, spawn)
	local data = GameState.Get(player)
	if not data then
		return
	end
	if not beltModel.Parent then
		return
	end
	if GameState.FreePad(data) == nil then
		toastPlayer(player, "Base penuh! (6/6) Panen, rebirth, atau tunggu pencuri.")
		return
	end
	if data.Cash < spawn.Price then
		toastPlayer(player, "Uang kurang: butuh $" .. spawn.Price .. ".")
		return
	end
	data.Cash -= spawn.Price
	local ok = placeOnPad(player, data, spawn.Def, spawn.Mutation, spawn.Price, spawn.Income)
	if not ok then
		data.Cash += spawn.Price
		toastPlayer(player, "Base penuh!")
		return
	end
	-- The belt walker leaves the belt for good.
	local walker = MoveService.FindByModel(beltModel)
	if walker then
		MoveService.Remove(walker, true)
	end
	beltModels[beltModel] = nil
	toastPlayer(player, "Membeli " .. spawn.Def.Name .. " ($" .. spawn.Price .. ")")
	syncPlayer(player)
end

local function spawnBeltBrainrot()
	if MoveService.CountByTag("belt") >= MAX_BELT then
		return
	end
	local rarity = BrainrotData.RollRarity(BrainrotData.BELT_WEIGHTS, rng)
	local def = BrainrotData.RandomOfRarity(rarity, rng)
	local mutation = BrainrotData.RollMutation(rng)
	local price = BrainrotData.PriceFor(def, mutation)
	local income = BrainrotData.IncomeFor(def, mutation)
	local model = BrainrotFactory.Create(def, mutation.Name)
	model.Parent = workspace
	model:PivotTo(CFrame.new(BELT_SPAWN_X, BELT_TOP_Y + BrainrotFactory.ROOT_LIFT, BELT_Z))
	local mutText = mutation.Name ~= "Normal" and (" " .. mutation.Name) or ""
	BrainrotFactory.SetLabel(model, def.Name .. mutText, def.Rarity .. " - $" .. price .. " - $" .. income .. "/s", BrainrotData.RARITY_COLORS[def.Rarity])
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Beli $" .. price
	prompt.ObjectText = def.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.Parent = model.PrimaryPart
	local spawn = { Def = def, Mutation = mutation, Price = price, Income = income }
	beltModels[model] = spawn
	prompt.Triggered:Connect(function(player)
		tryBuy(player, model, spawn)
	end)
	if def.Rarity == "Divine" then
		BrainrotFactory.SparkleBurst(Vector3.new(BELT_SPAWN_X, BELT_TOP_Y + 1, BELT_Z))
		toastAll("BRAINROT DIVINE muncul di conveyor: " .. def.Name .. "!")
	end
	MoveService.Add(model, {
		Path = { Vector3.new(BELT_END_X, 0, BELT_Z) },
		Speed = BELT_WALK_SPEED,
		PivotY = BELT_TOP_Y + BrainrotFactory.ROOT_LIFT,
		Tag = "belt",
		OnArrive = function()
			beltModels[model] = nil
			model:Destroy()
		end,
		OnCancel = function()
			beltModels[model] = nil
		end,
	})
end

-- Per-plot prompts ------------------------------------------------------
local function wirePlotPrompts(plot)
	local collectPrompt = Instance.new("ProximityPrompt")
	collectPrompt.Name = "CollectPrompt"
	collectPrompt.ActionText = "Panen Uang"
	collectPrompt.ObjectText = "Pad Panen"
	collectPrompt.HoldDuration = 0
	collectPrompt.MaxActivationDistance = 10
	collectPrompt.Parent = plot.CollectPad
	collectPrompt.Triggered:Connect(function(player)
		local data = GameState.Get(player)
		if data and data.PlotIndex == plot.Index then
			doCollect(player)
		end
	end)
	local lockPrompt = Instance.new("ProximityPrompt")
	lockPrompt.Name = "LockPrompt"
	lockPrompt.ActionText = "Kunci Base 60s"
	lockPrompt.ObjectText = "Tombol Kunci"
	lockPrompt.HoldDuration = 0
	lockPrompt.MaxActivationDistance = 10
	lockPrompt.Parent = plot.LockButton
	lockPrompt.Triggered:Connect(function(player)
		local data = GameState.Get(player)
		if data and data.PlotIndex == plot.Index then
			doLock(player)
		end
	end)
end

for _, plot in ipairs(world.Plots) do
	wirePlotPrompts(plot)
end

-- Gacha prompt -----------------------------------------------------------
local gachaPrompt = Instance.new("ProximityPrompt")
gachaPrompt.Name = "GachaPrompt"
gachaPrompt.ActionText = "Putar Gacha"
gachaPrompt.ObjectText = "Mesin Gacha"
gachaPrompt.HoldDuration = 0
gachaPrompt.MaxActivationDistance = 12
gachaPrompt.Parent = world.GachaMachine:FindFirstChild("Body")
gachaPrompt.Triggered:Connect(function(player)
	GachaService.Roll(ctx, player)
end)

-- Client actions -----------------------------------------------------------
actionRemote.OnServerEvent:Connect(function(player, action)
	if action == "collect" then
		doCollect(player)
	elseif action == "lock" then
		doLock(player)
	elseif action == "rebirth" then
		doRebirth(player)
	elseif action == "gacha" then
		GachaService.Roll(ctx, player)
	end
end)

-- Players ------------------------------------------------------------------
local function onPlayerAdded(player)
	local plotIndex = claimPlot(player)
	if not plotIndex then
		player:Kick("Server penuh: semua base sudah terisi.")
		return
	end
	local data = GameState.CreatePlayer(player, plotIndex)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = data.Cash
	cash.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirth"
	rebirths.Value = 0
	rebirths.Parent = stats
	stats.Parent = player
	local plot = world.Plots[plotIndex]
	local signBoard = plot.Model:FindFirstChild("PlotSign")
	if signBoard then
		local board = signBoard:FindFirstChild("Board")
		if board then
			for _, gui in ipairs(board:GetChildren()) do
				local label = gui:FindFirstChildOfClass("TextLabel")
				if label then
					label.Text = "BASE " .. player.Name
				end
			end
		end
	end
	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local front = Vector3.new(plot.Center.X, 2, plot.FrontZ)
			rootPart.CFrame = CFrame.new(front, Vector3.new(0, 2, plot.Center.Z))
		end
	end)
	if player.Character then
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			rootPart.CFrame = CFrame.new(Vector3.new(plot.Center.X, 2, plot.FrontZ))
		end
	end
	toastPlayer(player, "Selamat datang di Brainrot Bazaar! Beli brainrot di conveyor.")
	syncPlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	local data = GameState.Get(player)
	if data then
		plotOwner[data.PlotIndex] = nil
		for i = 1, GameState.PADS_PER_BASE do
			GameState.RemoveFromPad(data, i)
		end
		GameState.RemovePlayer(player)
	end
end)

-- Income tick + state sync ---------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)
		for _, data in pairs(GameState.Players) do
			GameState.TickIncome(data, 1)
		end
		syncAll()
	end
end)

-- Belt spawner -----------------------------------------------------------------
task.spawn(function()
	task.wait(1)
	while true do
		spawnBeltBrainrot()
		task.wait(2.6)
	end
end)

-- Tsunami ------------------------------------------------------------------------
local function playerInsideAnyBase(character)
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end
	local pos = rootPart.Position
	for _, plot in ipairs(world.Plots) do
		if math.abs(pos.X - plot.Center.X) <= 24 and math.abs(pos.Z - plot.Center.Z) <= 17 then
			return true
		end
	end
	return false
end

task.spawn(function()
	while true do
		local waitTime = nextTsunamiAt - GameState.Now() - TSUNAMI_WARNING
		if waitTime > 0 then
			task.wait(waitTime)
		end
		toastAll("TSUNAMI 10 detik lagi! Lari ke dalam base!")
		task.wait(TSUNAMI_WARNING)
		-- The wave washes away everything on or walking off the belt.
		MoveService.CancelByTag("belt", true)
		for model in pairs(beltModels) do
			beltModels[model] = nil
		end
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and not playerInsideAnyBase(character) then
				humanoid.Health = 0
				toastPlayer(player, "Kamu tersapu tsunami!")
			end
		end
		toastAll("Tsunami lewat! Conveyor mulai lagi.")
		nextTsunamiAt = GameState.Now() + TSUNAMI_PERIOD
		syncAll()
	end
end)

-- Plaza animation: fountain water spins, the ferris wheel turns. ---------------
task.spawn(function()
	local water = world.FountainWater
	local waterBase = water.CFrame
	local waterCenter = Vector3.new(WorldBuilder.Layout.Fountain.X, waterBase.Position.Y, WorldBuilder.Layout.Fountain.Z)
	local spokes = {}
	for _, child in ipairs(world.Folder:GetDescendants()) do
		if child:IsA("BasePart") and child:GetAttribute("SpinWithWater") then
			table.insert(spokes, { Part = child, Base = child.CFrame })
		end
	end
	local wheel = world.FerrisWheel
	local hubPos = world.WheelHub
	local angle = 0
	local waterAngle = 0
	while true do
		local dt = task.wait(0.05)
		angle += dt * 0.18
		waterAngle += dt * 0.5
		wheel:PivotTo(CFrame.new(hubPos) * CFrame.Angles(angle, 0, 0))
		water.CFrame = CFrame.new(waterCenter) * CFrame.Angles(0, waterAngle, 0) * (CFrame.new(waterCenter):Inverse() * waterBase)
		for _, s in ipairs(spokes) do
			s.Part.CFrame = CFrame.new(waterCenter) * CFrame.Angles(0, waterAngle, 0) * (CFrame.new(waterCenter):Inverse() * s.Base)
		end
	end
end)

Thief.Start(ctx)

print("Brainrot Bazaar server ready: " .. #world.Plots .. " bases, belt top Y=" .. BELT_TOP_Y)
for _, line in ipairs(WorldBuilder.DescribeLayout()) do
	print("[layout] " .. line)
end

-- Server stats for the output log: live belt + walker counts on demand.
local function serverStats()
	return {
		BeltWalking = MoveService.CountByTag("belt"),
		WalkersActive = MoveService.ActiveCount(),
		PlayersSeated = GameState and #Players:GetPlayers() or 0,
		NextTsunamiIn = math.max(0, math.ceil(nextTsunamiAt - GameState.Now())),
	}
end
_G.BrainrotBazaarStats = serverStats
