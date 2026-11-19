-- Brainrot Bazaar: server entry point.
-- Wires the world, the conveyor shop, buying, income, collect, lock, thief,
-- tsunami, rebirth and gacha together. In-memory data only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local GameState = require(script.Parent.GameState)
local WorldBuilder = require(script.Parent.WorldBuilder)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local MoveService = require(script.Parent.MoveService)
local Thief = require(script.Parent.Thief)
local GachaService = require(script.Parent.GachaService)

local LIFT = BrainrotFactory.lift()
local SPAWN_INTERVAL = 6 -- seconds between belt spawns
local TSUNAMI_CYCLE = 180 -- seconds between tsunamis
local TSUNAMI_WARN = 10 -- seconds of warning before the wave hits
local LOCK_SECONDS = 60

local world = WorldBuilder.build()
local plots = world.plots
local remotes = GameState.createRemotes()
local rng = Random.new()

local beltRiders = {} -- [model] = { handle = ..., price = ... }

local function pushState(player)
	GameState.pushState(remotes, player)
end

local function pushAll()
	for player in pairs(GameState.allPlayers()) do
		pushState(player)
	end
end

-- Claim the first free plot for a joining player.
local function claimPlot(data)
	for i, plot in ipairs(plots) do
		local taken = false
		for _, other in pairs(GameState.allPlayers()) do
			if other.plotIndex == i then
				taken = true
				break
			end
		end
		if not taken then
			data.plotIndex = i
			return i
		end
	end
	return 0
end

-- Spawn one brainrot on the belt at X=-70; it rides to X=70, then despawns.
local function spawnBeltBrainrot()
	local char, mutName, mutMult, mutColor = BrainrotFactory.rollSpawn(rng)
	local model = BrainrotFactory.create(char, mutName, mutMult, mutColor)
	model.Parent = Workspace
	local price = model:GetAttribute("Price")
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 20
	click.Parent = model.PrimaryPart
	click.MouseClick:Connect(function(player)
		buyBrainrot(player, model)
	end)
	local handle = MoveService.startBeltRide(model, world.beltTopY, LIFT, world.beltXMin, world.beltXMax, 0)
	beltRiders[model] = { handle = handle, price = price }
	if char.rarity == "Divine" then
		BrainrotFactory.sparkleBurst(Workspace, Vector3.new(world.beltXMin, 3, 0))
		GameState.toastAll(remotes, "DIVINE muncul di toko! " .. char.name .. " seharga " .. BrainrotData.formatMoney(price) .. "!")
	end
	task.spawn(function()
		while not handle.finished and not handle.stopped do
			task.wait(0.25)
		end
		if beltRiders[model] then
			beltRiders[model] = nil
			model:Destroy()
		end
	end)
end

-- Buy a brainrot off the belt: it walks to a free pad in the buyer's base.
function buyBrainrot(player, model)
	local data = GameState.get(player)
	if not data or not model.Parent or not beltRiders[model] then
		return
	end
	if data.plotIndex == 0 then
		GameState.toast(remotes, player, "Kamu belum punya base!")
		return
	end
	local price = model:GetAttribute("Price") or 0
	if data.cash < price then
		GameState.toast(remotes, player, "Uang tidak cukup! Butuh " .. BrainrotData.formatMoney(price) .. ".")
		return
	end
	local padIndex = GameState.freePadIndex(data)
	if not padIndex then
		GameState.toast(remotes, player, "Base penuh! Kumpulkan uang dulu atau rebirth.")
		return
	end
	data.cash = data.cash - price
	local rider = beltRiders[model]
	beltRiders[model] = nil
	if rider then
		rider.handle.stop()
	end
	model.PrimaryPart:FindFirstChildWhichIsA("ClickDetector"):Destroy()
	local charId = model:GetAttribute("CharId") or 0
	data.owned[charId] = true
	data.pads[padIndex] = model
	BrainrotFactory.setOwner(model, player.Name)
	local plot = plots[data.plotIndex]
	local padPos = plot.pads[padIndex].Position
	GameState.toast(remotes, player, "Berhasil beli " .. model.Name .. "!")
	-- Walk off the belt: down to the ground at the belt end, then home to the pad.
	local groundPos = MoveService.groundXZ(model)
	MoveService.walkTo(model, LIFT, Vector3.new(groundPos.X, 0, 12), function()
		MoveService.walkTo(model, LIFT, Vector3.new(padPos.X, 0, padPos.Z), function()
			MoveService.snapToPad(model, LIFT, padPos)
		end)
	end)
	pushState(player)
end

-- Collect stored cash from the green collect pad.
local function collectCash(player)
	local data = GameState.get(player)
	if not data then
		return
	end
	if data.stored <= 0 then
		GameState.toast(remotes, player, "Belum ada uang tersimpan di base.")
		return
	end
	local amount = math.floor(data.stored)
	data.stored = 0
	data.cash = data.cash + amount
	GameState.toast(remotes, player, "Kamu mengambil " .. BrainrotData.formatMoney(amount) .. " dari base!")
	pushState(player)
end

-- Lock a base for 60 seconds (thief-proof).
local function toggleLock(player)
	local data = GameState.get(player)
	if not data or data.plotIndex == 0 then
		return
	end
	local now = os.time()
	if now < data.lockedUntil then
		GameState.toast(remotes, player, "Base sudah terkunci.")
		return
	end
	data.lockedUntil = now + LOCK_SECONDS
	GameState.toast(remotes, player, "Base dikunci selama 60 detik! Maling tidak bisa masuk.")
	GameState.toastAll(remotes, player.Name .. " mengunci base-nya selama 60 detik.")
	pushState(player)
end

-- Rebirth: reset cash/stored/pads for a permanent +0.75x income multiplier.
local function doRebirth(player)
	local data = GameState.get(player)
	if not data then
		return
	end
	local cost = GameState.rebirthCost(data)
	if data.cash < cost then
		GameState.toast(remotes, player, "Rebirth butuh " .. BrainrotData.formatMoney(cost) .. ".")
		return
	end
	data.cash = data.cash - cost
	for _, model in pairs(data.pads) do
		if model then
			model:Destroy()
		end
	end
	data.pads = {}
	data.stored = 0
	data.cash = GameState.START_CASH
	data.rebirths = data.rebirths + 1
	GameState.toastAll(remotes, player.Name .. " REBIRTH ke-" .. data.rebirths .. "! Multiplier sekarang x" .. string.format("%.2f", GameState.multiplier(data)) .. ".")
	pushState(player)
end

-- Tsunami: 10s warning, then a wave that clears the belt and kills players
-- who are outside every base slab.
local tsunamiAt = os.clock() + TSUNAMI_CYCLE
local lastWarnSecs = -1
local function tsunamiTick()
	local now = os.clock()
	local remaining = tsunamiAt - now
	if remaining <= TSUNAMI_WARN and remaining > 0 then
		local secs = math.ceil(remaining)
		-- Fire only when the displayed second changes (once per second, not per frame).
		if secs ~= lastWarnSecs then
			lastWarnSecs = secs
			remotes.TsunamiWarning:FireAllClients(secs)
		end
	end
	if remaining <= 0 then
		lastWarnSecs = -1
		tsunamiAt = now + TSUNAMI_CYCLE
		GameState.toastAll(remotes, "TSUNAMI! Lari ke base kamu, sekarang!")
		-- The wave: a big translucent wall sweeping across the map.
		local wave = Instance.new("Part")
		wave.Name = "TsunamiWave"
		wave.Shape = Enum.PartType.Block
		wave.Size = Vector3.new(20, 18, 300)
		wave.Position = Vector3.new(-190, 9, 0)
		wave.Color = Color3.fromRGB(40, 140, 255)
		wave.Material = Enum.Material.Neon
		wave.Transparency = 0.4
		wave.Anchored = true
		wave.CanCollide = false
		wave.Parent = Workspace
		task.spawn(function()
			for x = -190, 190, 8 do
				wave.Position = Vector3.new(x, 9, 0)
				task.wait(0.05)
			end
			wave:Destroy()
		end)
		-- Wash away every belt rider and walking brainrot.
		for model in pairs(beltRiders) do
			local rider = beltRiders[model]
			beltRiders[model] = nil
			if rider then
				rider.handle.stop()
			end
			model:Destroy()
		end
		-- Kill players caught outside the bases.
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				if not WorldBuilder.isInsideAnyBase(plots, root.Position) then
					hum.Health = 0
					GameState.toast(remotes, player, "Kamu tersapu tsunami! Sembunyi di base lain kali.")
				end
			end
		end
	end
end

-- Income tick: every owned brainrot pays into the owner's stored cash.
local function incomeTick()
	for player, data in pairs(GameState.allPlayers()) do
		local perSec = GameState.incomePerSecond(data)
		if perSec > 0 then
			data.stored = data.stored + perSec
		end
	end
end

-- Ambient animation: ferris wheel turns, fountain water spins, beacon pulses.
local wheelAngle = 0
RunService.Heartbeat:Connect(function(dt)
	wheelAngle = wheelAngle + dt * 0.12
	local hub = world.wheelHub
	local r = world.wheelRadius
	for _, entry in ipairs(world.wheelParts) do
		local a = entry.angle + wheelAngle
		local y = hub.Y + math.cos(a) * r
		local z = hub.Z + math.sin(a) * r
		entry.rim.CFrame = CFrame.new(hub.X, y, z)
		entry.pod.CFrame = CFrame.new(hub.X, y, z)
	end
	world.fountainWater.CFrame = world.fountainWater.CFrame * CFrame.Angles(0, dt * 0.4, 0)
	local pulse = 0.5 + 0.5 * math.sin(os.clock() * 2)
	world.beacon.Transparency = 0.1 + pulse * 0.4
	tsunamiTick()
end)

-- Wire the plot ClickDetectors (collect pad + lock button) and the gacha button.
for _, plot in ipairs(plots) do
	local collectClick = Instance.new("ClickDetector")
	collectClick.MaxActivationDistance = 16
	collectClick.Parent = plot.collectPad
	collectClick.MouseClick:Connect(collectCash)
	local lockClick = Instance.new("ClickDetector")
	lockClick.MaxActivationDistance = 16
	lockClick.Parent = plot.lockButton
	lockClick.MouseClick:Connect(toggleLock)
end
local gachaClick = world.gachaButton:FindFirstChildWhichIsA("ClickDetector")
if gachaClick then
	gachaClick.MouseClick:Connect(function(player)
		local ok, msg = GachaService.roll({
			gameState = GameState,
			remotes = remotes,
			factory = BrainrotFactory,
			moveService = MoveService,
			plots = plots,
			lift = LIFT,
		}, player)
		if msg then
			GameState.toast(remotes, player, msg)
		end
		if ok then
			pushState(player)
		end
	end)
end

-- Remote handlers.
remotes.BuyBrainrot.OnServerEvent:Connect(function(player, model)
	if typeof(model) == "Instance" then
		buyBrainrot(player, model)
	end
end)
remotes.CollectCash.OnServerEvent:Connect(collectCash)
remotes.ToggleLock.OnServerEvent:Connect(toggleLock)
remotes.Rebirth.OnServerEvent:Connect(doRebirth)
remotes.GachaRoll.OnServerEvent:Connect(function(player)
	local ok, msg = GachaService.roll({
		gameState = GameState,
		remotes = remotes,
		factory = BrainrotFactory,
		moveService = MoveService,
		plots = plots,
		lift = LIFT,
	}, player)
	if msg then
		GameState.toast(remotes, player, msg)
	end
	if ok then
		pushState(player)
	end
end)

-- Player lifecycle.
local function onPlayerAdded(player)
	local data = GameState.addPlayer(player)
	claimPlot(data)
	GameState.toast(remotes, player, "Selamat datang di Brainrot Bazaar! Beli brainrot di toko, kumpulkan uang di base.")
	pushState(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		pushState(player)
	end)
end

local function onPlayerRemoving(player)
	local data = GameState.get(player)
	if data then
		for _, model in pairs(data.pads) do
			if model then
				model:Destroy()
			end
		end
	end
	GameState.removePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Main loops: belt spawner, income tick, HUD push.
task.spawn(function()
	while true do
		task.wait(SPAWN_INTERVAL)
		local ok, err = pcall(spawnBeltBrainrot)
		if not ok then
			warn("Belt spawn failed: " .. tostring(err))
		end
	end
end)
task.spawn(function()
	while true do
		task.wait(1)
		incomeTick()
		pushAll()
	end
end)

-- Seed the belt so the shop is never empty at start.
for _ = 1, 3 do
	spawnBeltBrainrot()
	task.wait(0.2)
end

print("Brainrot Bazaar server ready: 8 bases, 24 characters, tsunami every " .. TSUNAMI_CYCLE .. "s.")
