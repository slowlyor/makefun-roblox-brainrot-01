-- init.server.luau
-- Brainrot Bazaar server bootstrap. Builds the world, wires the remotes the
-- HUD uses, then runs the four game loops: the shop spawner (brainrots ride
-- the conveyor), the per-second income tick, the tsunami cycle and the
-- thief loop. Player join/leave, buying, collecting and locking all live
-- here because they tie the other modules together.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local GameState = require(script.GameState)
local WorldBuilder = require(script.WorldBuilder)
local BrainrotFactory = require(script.BrainrotFactory)
local MoveService = require(script.MoveService)
local Thief = require(script.Thief)

local C = GameState.Constants

-- Remotes the client HUD talks through.
local remotes = Instance.new("Folder")
remotes.Name = "BrainrotRemotes"
remotes.Parent = ReplicatedStorage

local statsEvent = Instance.new("RemoteEvent")
statsEvent.Name = "Stats"
statsEvent.Parent = remotes

local toastEvent = Instance.new("RemoteEvent")
toastEvent.Name = "Toast"
toastEvent.Parent = remotes

local rebirthEvent = Instance.new("RemoteFunction")
rebirthEvent.Name = "Rebirth"
rebirthEvent.Parent = remotes

WorldBuilder.Build()

-- Toast helpers ------------------------------------------------------------

local function toast(player, text, duration)
	toastEvent:FireClient(player, text, duration or 3)
end

local function toastAll(text, duration)
	toastEvent:FireAllClients(text, duration or 3)
end

Thief.BroadcastToast = toastAll

-- Stat sync ----------------------------------------------------------------

local function pushStats(state)
	local player = state.Player
	local plot = state.Plot
	local stored = plot and plot.Stored or 0
	statsEvent:FireClient(player, {
		Cash = math.floor(state.Cash),
		Income = GameState.IncomePerSecond(state),
		Stored = math.floor(stored),
		Rebirths = state.Rebirths,
		Multiplier = GameState.MultiplierFor(state.Rebirths),
		RebirthCost = GameState.RebirthCostFor(state.Rebirths),
		TsunamiIn = math.max(0, math.floor(GameState.TsunamiCountdown)),
		TsunamiActive = GameState.TsunamiActive,
	})
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Cash.Value = math.floor(state.Cash)
		leaderstats.Rebirth.Value = state.Rebirths
	end
	-- Refresh the plot's owner sign.
	if plot and plot.SignLabel then
		plot.SignLabel.Text = string.format(
			"Base %s\nTersimpan: $%s  •  $%s/s",
			player.DisplayName,
			BrainrotData.FormatCash(stored),
			BrainrotData.FormatCash(GameState.IncomePerSecond(state))
		)
	end
end

local function pushAllStats()
	for _, state in pairs(GameState.Players) do
		pushStats(state)
	end
end

-- Transients (belt riders + walkers) ----------------------------------------

local function removeTransient(model)
	for i, entry in ipairs(GameState.Transients) do
		if entry.Model == model then
			table.remove(GameState.Transients, i)
			break
		end
	end
	MoveService.Stop(model)
	if model and model.Parent then
		model:Destroy()
	end
end

local function clearTransients()
	local models = {}
	for _, entry in ipairs(GameState.Transients) do
		table.insert(models, entry.Model)
	end
	for _, model in ipairs(models) do
		removeTransient(model)
	end
end

-- Buying -------------------------------------------------------------------

local function onBuyPrompt(triggeredPlayer, entry)
	local state = GameState.GetPlayerState(triggeredPlayer)
	if not state then
		return
	end
	if not entry.Model.Parent then
		return -- already gone
	end
	if state.Cash < entry.Price then
		toast(triggeredPlayer, string.format("Uang tidak cukup! Butuh $%s", BrainrotData.FormatCash(entry.Price)), 3)
		return
	end
	local plot = state.Plot
	if not plot then
		toast(triggeredPlayer, "Kamu belum punya base!", 3)
		return
	end
	local padIndex = GameState.FirstFreePadIndex(state)
	if not padIndex then
		toast(triggeredPlayer, "Base penuh! (maks 6 brainrot)", 3)
		return
	end

	state.Cash -= entry.Price
	-- Remove from the transient list and from the belt.
	for i, e in ipairs(GameState.Transients) do
		if e == entry then
			table.remove(GameState.Transients, i)
			break
		end
	end
	local prompt = entry.Model:FindFirstChildOfClass("ProximityPrompt", true)
	if prompt then
		prompt:Destroy()
	end

	local owned = {
		Model = entry.Model,
		Def = entry.Def,
		Mutation = entry.Mutation,
		Income = entry.Income,
		PadIndex = padIndex,
	}
	table.insert(state.Brainrots, owned)

	-- Walk from wherever the rider was bought to the free pad.
	local pad = plot.Pads[padIndex]
	MoveService.WalkTo(entry.Model, Vector3.new(pad.Position.X, 1.4, pad.Position.Z), C.WalkSpeed, function()
		toast(triggeredPlayer, entry.Model.Name .. " mulai menghasilkan uang!", 2)
	end)
	pushStats(state)
end

-- Shop spawner ---------------------------------------------------------------

local function spawnRider()
	local def = BrainrotData.RollCharacter()
	local mutation = BrainrotData.RollMutation()
	local model = BrainrotFactory.Create(def, mutation)
	model.Parent = workspace

	local startX = -C.BeltLength / 2 + 4
	local beltY = C.BeltTopY + 0.2
	model:PivotTo(CFrame.new(startX, beltY, 0))

	local entry = {
		Model = model,
		Kind = "belt",
		Def = def,
		Mutation = mutation,
		Price = BrainrotData.PriceOf(def, mutation),
		Income = BrainrotData.IncomeOf(def, mutation),
	}
	table.insert(GameState.Transients, entry)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Beli $" .. BrainrotData.FormatCash(entry.Price)
	prompt.ObjectText = BrainrotData.DisplayName(def, mutation)
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 14
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		onBuyPrompt(player, entry)
	end)

	-- Ride the belt to the far end, then despawn.
	MoveService.WalkTo(model, Vector3.new(C.BeltLength / 2 - 2, beltY, 0), C.BeltSpeed, function()
		removeTransient(model)
	end)
end

-- Collect pads + lock buttons ----------------------------------------------

local function watchPlot(plot)
	plot.CollectPad.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		local state = GameState.GetPlayerState(player)
		if state and state.Plot == plot and plot.Stored >= 1 then
			local gained = math.floor(plot.Stored)
			plot.Stored = 0
			state.Cash += gained
			toast(player, string.format("+$%s terkumpul!", BrainrotData.FormatCash(gained)), 2)
			pushStats(state)
		end
	end)

	plot.LockPrompt.Triggered:Connect(function(player)
		local state = GameState.GetPlayerState(player)
		if not state or state.Plot ~= plot then
			toast(player, "Ini bukan base kamu!", 2)
			return
		end
		plot.LockedUntil = os.clock() + C.LockDuration
		WorldBuilder.SetBarriersVisible(plot, true)
		toast(player, "Base dikunci selama 60 detik!", 3)
	end)
end

for _, plot in ipairs(GameState.Plots) do
	watchPlot(plot)
end

-- Rebirth --------------------------------------------------------------------

rebirthEvent.OnServerInvoke = function(player)
	local state = GameState.GetPlayerState(player)
	if not state then
		return false, "State tidak ditemukan"
	end
	local cost = GameState.RebirthCostFor(state.Rebirths)
	if state.Cash < cost then
		return false, string.format("Butuh $%s untuk rebirth", BrainrotData.FormatCash(cost))
	end
	state.Cash -= cost
	state.Rebirths += 1
	-- All placed brainrots are sold back into the bazaar void.
	for _, entry in ipairs(state.Brainrots) do
		if entry.Model and entry.Model.Parent then
			entry.Model:Destroy()
		end
	end
	state.Brainrots = {}
	if state.Plot then
		state.Plot.Stored = 0
	end
	pushStats(state)
	return true, string.format("Rebirth! Pengali sekarang x%.2f", GameState.MultiplierFor(state.Rebirths))
end

-- Players --------------------------------------------------------------------

local function onPlayerAdded(player)
	local state = GameState.NewPlayerState(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = math.floor(state.Cash)
	cashValue.Parent = leaderstats
	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirth"
	rebirthValue.Value = 0
	rebirthValue.Parent = leaderstats
	leaderstats.Parent = player

	GameState.ClaimFreePlot(state)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			task.wait(3)
			player:LoadCharacter()
		end)
	end)
	player:LoadCharacter()
	pushStats(state)
	if state.Plot then
		toast(player, "Selamat datang! Base #" .. state.Plot.Index .. " jadi milikmu.", 4)
	else
		toast(player, "Server penuh: semua base sudah terisi.", 4)
	end
end

local function onPlayerRemoving(player)
	local state = GameState.GetPlayerState(player)
	if not state then
		return
	end
	for _, entry in ipairs(state.Brainrots) do
		if entry.Model and entry.Model.Parent then
			entry.Model:Destroy()
		end
	end
	if state.Plot then
		local plot = state.Plot
		plot.Owner = nil
		plot.Stored = 0
		plot.LockedUntil = 0
		WorldBuilder.SetBarriersVisible(plot, false)
		if plot.SignLabel then
			plot.SignLabel.Text = "Base kosong"
		end
		state.Plot = nil
	end
	GameState.RemovePlayerState(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Income tick: every second, placed brainrots add their income (times the
-- owner's rebirth multiplier) to their plot's stored cash.
task.spawn(function()
	while true do
		task.wait(1)
		for _, state in pairs(GameState.Players) do
			local plot = state.Plot
			if plot then
				plot.Stored += GameState.IncomePerSecond(state)
			end
		end
		-- Lock expiry: hide barriers whose time ran out.
		for _, plot in ipairs(GameState.Plots) do
			if plot.LockedUntil ~= 0 and not GameState.IsLocked(plot) then
				plot.LockedUntil = 0
				WorldBuilder.SetBarriersVisible(plot, false)
			end
		end
		pushAllStats()
	end
end)

-- Shop loop.
task.spawn(function()
	while true do
		local ok, err = pcall(spawnRider)
		if not ok then
			warn("[BrainrotBazaar] spawn failed: " .. tostring(err))
		end
		task.wait(C.SpawnInterval)
	end
end)

-- Tsunami cycle ---------------------------------------------------------------

local function runTsunami()
	GameState.TsunamiActive = true
	toastAll("TSUNAMI DATANG! Masuk ke base sekarang!", 4)

	-- The wave: a tall glass wall sweeping west to east.
	local wave = Instance.new("Part")
	wave.Name = "TsunamiWave"
	wave.Size = Vector3.new(6, 26, 340)
	wave.Color = Color3.fromRGB(60, 170, 255)
	wave.Material = Enum.Material.Glass
	wave.Transparency = 0.35
	wave.Anchored = true
	wave.CanCollide = false
	wave.Position = Vector3.new(-230, 13, 0)
	wave.Parent = workspace

	-- Belt riders and walking brainrots are washed away.
	clearTransients()

	-- Players caught outside any plot are killed.
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			if not MoveService.IsInsideAnyPlot(root.Position, GameState.Plots) then
				humanoid.Health = 0
			end
		end
	end

	-- Sweep the wall across the map over ~6 seconds.
	local startX, endX = -230, 230
	local duration = 6
	local elapsed = 0
	while elapsed < duration do
		local dt = task.wait()
		elapsed += dt
		local alpha = math.clamp(elapsed / duration, 0, 1)
		wave.Position = Vector3.new(startX + (endX - startX) * alpha, 13, 0)
	end
	wave:Destroy()
	GameState.TsunamiActive = false
	GameState.TsunamiCountdown = C.TsunamiPeriod
	toastAll("Tsunami lewat. Bazaar aman lagi!", 3)
end

task.spawn(function()
	local warned = false
	while true do
		task.wait(1)
		if GameState.TsunamiActive then
			continue
		end
		GameState.TsunamiCountdown -= 1
		if GameState.TsunamiCountdown == C.TsunamiWarning and not warned then
			warned = true
			toastAll("PERINGATAN: Tsunami dalam 10 detik! Masuk ke base!", 5)
		end
		if GameState.TsunamiCountdown <= 0 then
			warned = false
			local ok, err = pcall(runTsunami)
			if not ok then
				warn("[BrainrotBazaar] tsunami failed: " .. tostring(err))
				GameState.TsunamiActive = false
				GameState.TsunamiCountdown = C.TsunamiPeriod
			end
		end
	end
end)

-- Thief loop.
Thief.StartLoop()

print("[BrainrotBazaar] Brainrot Bazaar server ready: " .. #GameState.Plots .. " plots")
