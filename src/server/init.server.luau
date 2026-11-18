-- Brainrot Bazaar — server bootstrap.
-- Builds the world, then runs the whole game loop: players claim bases,
-- brainrots ride the shop conveyor, bought brainrots walk home and earn
-- cash, a tsunami sweeps the map every few minutes, a thief stalks unlocked
-- bases, and rebirths trade a full reset for a permanent income multiplier.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local GameState = require(script:WaitForChild("GameState"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local BrainrotFactory = require(script:WaitForChild("BrainrotFactory"))
local MoveService = require(script:WaitForChild("MoveService"))
local Thief = require(script:WaitForChild("Thief"))

GameState.CreateRemotes()
WorldBuilder.Build()

local worldFolder = workspace:WaitForChild("BrainrotWorld")
local liveFolder = worldFolder:WaitForChild("LiveBrainrots")
local layout = WorldBuilder.Layout

-- Helpers --------------------------------------------------------------------

local function pushStats(data)
	local income = 0
	for _, record in ipairs(data.Brainrots) do
		if record.State == "Home" then
			income += record.Income
		end
	end
	income *= GameState.IncomeMultiplier(data.Rebirths)
	data.IncomePerSec = income

	GameState.Remote("StatsUpdate"):FireClient(data.Player, {
		Cash = math.floor(data.Cash),
		StoredCash = math.floor(data.StoredCash),
		IncomePerSec = income,
		Rebirths = data.Rebirths,
		Multiplier = GameState.IncomeMultiplier(data.Rebirths),
		RebirthCost = GameState.RebirthCost(data.Rebirths),
	})

	local leaderstats = data.Player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Cash.Value = math.floor(data.Cash)
		leaderstats.Rebirth.Value = data.Rebirths
	end
	if data.Plot then
		data.Plot.SignInfo.Text = "pendapatan " .. BrainrotData.FormatCash(income) .. "/s"
	end
end

-- Push the current tsunami countdown to one player. The wave loop also
-- broadcasts it to everyone each second; this per-player copy rides the
-- stats tick (and CharacterAdded) so a late-connecting client converges
-- within a second instead of sitting on the "--:--" placeholder.
local function pushWave(player: Player)
	GameState.Remote("WaveUpdate"):FireClient(player, {
		SecondsLeft = GameState.WaveSecondsLeft,
		Phase = GameState.WavePhase,
	})
end

local function destroyBrainrot(record)
	local model = record.Model
	MoveService.Remove(model)
	GameState.Brainrots[model] = nil
	if record.Plot and record.PadIndex then
		if record.Plot.PadOccupants[record.PadIndex] == record then
			record.Plot.PadOccupants[record.PadIndex] = nil
		end
	end
	if record.Owner then
		local idx = table.find(record.Owner.Brainrots, record)
		if idx then
			table.remove(record.Owner.Brainrots, idx)
		end
	end
	if model.Parent then
		model:Destroy()
	end
end

local function freePad(plot): number?
	for i = 1, GameState.PADS_PER_PLOT do
		if plot.PadOccupants[i] == nil then
			return i
		end
	end
	return nil
end

-- Players --------------------------------------------------------------------

local function assignPlot(data): boolean
	for _, plot in ipairs(GameState.Plots) do
		if plot.Owner == nil then
			plot.Owner = data
			data.Plot = plot
			plot.SignName.Text = "Basis " .. data.Player.DisplayName
			plot.SignInfo.Text = "pendapatan $0/s"
			return true
		end
	end
	return false
end

local function onPlayerAdded(player: Player)
	if GameState.Players[player.UserId] then
		return
	end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = GameState.STARTING_CASH
	cashValue.Parent = leaderstats
	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirth"
	rebirthValue.Parent = leaderstats
	leaderstats.Parent = player

	local data = {
		Player = player,
		Cash = GameState.STARTING_CASH,
		StoredCash = 0,
		Rebirths = 0,
		IncomePerSec = 0,
		Plot = nil,
		Brainrots = {},
	}
	GameState.Players[player.UserId] = data

	if assignPlot(data) then
		GameState.Notify(player, "Selamat datang di Brainrot Bazaar! Basismu: Basis " .. data.Plot.Index .. ". Beli brainrot di conveyor!", "info")
	else
		GameState.Notify(player, "Semua basis penuh! Kamu jadi penonton dulu.", "danger")
	end
	pushStats(data)
	pushWave(player)
	player.CharacterAdded:Connect(function()
		pushStats(data)
		pushWave(player)
	end)
end

local function onPlayerRemoving(player: Player)
	local data = GameState.Players[player.UserId]
	if not data then
		return
	end
	for _, record in ipairs(table.clone(data.Brainrots)) do
		destroyBrainrot(record)
	end
	if data.Plot then
		data.Plot.Owner = nil
		data.Plot.SignName.Text = "Basis Kosong"
		data.Plot.SignInfo.Text = "menunggu pemain..."
		data.Plot.CollectLabel.Text = "$0"
	end
	GameState.Players[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Collect pads + lock buttons (wired once, they read the plot's owner) -------

for _, plot in ipairs(GameState.Plots) do
	plot.CollectPad.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		local data = player and GameState.Players[player.UserId]
		if data and data.Plot == plot and data.StoredCash >= 1 then
			local amount = math.floor(data.StoredCash)
			data.StoredCash -= amount
			data.Cash += amount
			plot.CollectLabel.Text = "$0"
			pushStats(data)
		end
	end)

	plot.LockPrompt.Triggered:Connect(function(player)
		local data = GameState.Players[player.UserId]
		if data and data.Plot == plot and not plot.Locked then
			plot.Locked = true
			plot.LockUntil = os.clock() + GameState.LOCK_DURATION
			plot.LockButton.Color = Color3.fromRGB(60, 220, 110)
			for _, barrier in ipairs(plot.Barriers) do
				barrier.Transparency = 0.45
				barrier.CanCollide = true
			end
			GameState.Notify(player, "Basismu terkunci 60 detik. Aman dari maling!", "good")
		end
	end)
end

local function unlockPlot(plot)
	plot.Locked = false
	plot.LockButton.Color = Color3.fromRGB(235, 60, 60)
	for _, barrier in ipairs(plot.Barriers) do
		barrier.Transparency = 1
		barrier.CanCollide = false
	end
end

-- Shop conveyor ---------------------------------------------------------------

local function onBuy(player: Player, record)
	if record.State ~= "Shop" then
		return
	end
	local data = GameState.Players[player.UserId]
	if not data or not data.Plot then
		return
	end
	local padIndex = freePad(data.Plot)
	if not padIndex then
		GameState.Notify(player, "Basismu penuh! (maks 6 brainrot)", "danger")
		return
	end
	if data.Cash < record.Price then
		GameState.Notify(player, "Cash tidak cukup untuk " .. record.Def.Name .. " (" .. BrainrotData.FormatCash(record.Price) .. ")", "danger")
		return
	end

	data.Cash -= record.Price
	if record.Prompt then
		record.Prompt:Destroy()
		record.Prompt = nil
	end
	record.Owner = data
	record.Plot = data.Plot
	record.PadIndex = padIndex
	record.State = "Walking"
	data.Plot.PadOccupants[padIndex] = record
	table.insert(data.Brainrots, record)
	BrainrotFactory.SetInfo(record.Model, BrainrotData.FormatCash(record.Income) .. "/s")

	local padPos = data.Plot.PadPositions[padIndex]
	MoveService.Add(record.Model, function()
		return padPos
	end, GameState.WALK_HOME_SPEED, function()
		if record.State == "Walking" then
			record.State = "Home"
		end
	end)
	GameState.Notify(player, "Kamu membeli " .. record.Def.Name .. "! Dia berlari ke basismu.", "good")
	pushStats(data)
end

local function spawnShopWalker()
	local def = BrainrotData.PickRandom(GameState.Rng)
	local mutation = BrainrotData.RollMutation(GameState.Rng)
	local model = BrainrotFactory.CreateBrainrot(def, mutation)
	local mutationMultiplier = mutation and mutation.Multiplier or 1
	local record = {
		Model = model,
		Def = def,
		MutationName = mutation and mutation.Name or nil,
		MutationMultiplier = mutationMultiplier,
		Price = math.floor(def.Cost * mutationMultiplier),
		Income = def.Income * mutationMultiplier,
		Owner = nil,
		State = "Shop",
		Plot = nil,
		PadIndex = nil,
		Prompt = nil,
	}
	GameState.Brainrots[model] = record

	BrainrotFactory.SetInfo(model,
		BrainrotData.FormatCash(record.Price) .. "  -  " .. BrainrotData.FormatCash(record.Income) .. "/s")

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Beli " .. BrainrotData.FormatCash(record.Price)
	prompt.ObjectText = def.Name
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 11
	prompt.Parent = model.PrimaryPart
	record.Prompt = prompt
	prompt.Triggered:Connect(function(player)
		onBuy(player, record)
	end)

	model.Parent = liveFolder
	local startPos = Vector3.new(layout.BeltStartX, layout.BeltY, layout.BeltZ)
	model:PivotTo(CFrame.new(startPos + Vector3.new(0, model:GetAttribute("PivotLift") or 1.3, 0)))
	MoveService.Add(model, function()
		return Vector3.new(layout.BeltEndX, layout.BeltY, layout.BeltZ)
	end, GameState.SHOP_WALK_SPEED, function()
		if record.State == "Shop" then
			destroyBrainrot(record) -- walked the whole belt unsold
		end
	end)
end

task.spawn(function()
	while true do
		task.wait(GameState.SHOP_SPAWN_INTERVAL)
		local walkers = 0
		for _, record in pairs(GameState.Brainrots) do
			if record.State == "Shop" then
				walkers += 1
			end
		end
		if walkers < GameState.SHOP_MAX_WALKERS then
			spawnShopWalker()
		end
	end
end)

-- Income, locks and labels: one tick per second -------------------------------

task.spawn(function()
	while true do
		task.wait(1)
		for _, plot in ipairs(GameState.Plots) do
			if plot.Locked and os.clock() >= plot.LockUntil then
				unlockPlot(plot)
			end
		end
		for _, data in pairs(GameState.Players) do
			local income = 0
			for _, record in ipairs(data.Brainrots) do
				if record.State == "Home" then
					income += record.Income
				end
			end
			income *= GameState.IncomeMultiplier(data.Rebirths)
			if income > 0 then
				data.StoredCash += income
			end
			if data.Plot then
				data.Plot.CollectLabel.Text = BrainrotData.FormatCash(data.StoredCash)
			end
			pushStats(data)
			pushWave(data.Player)
		end
	end
end)

-- Rainbow mutations cycle their colours ---------------------------------------

task.spawn(function()
	while true do
		task.wait(0.15)
		local hue = (os.clock() * 0.12) % 1
		for model, record in pairs(GameState.Brainrots) do
			if record.MutationName == "Rainbow" and model.Parent then
				local body = model:FindFirstChild("Body")
				if body then
					body.Color = Color3.fromHSV(hue, 0.65, 1)
				end
			end
		end
	end
end)

-- Tsunami ----------------------------------------------------------------------

local function playerInsideAnyBase(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return true -- no character: nothing to kill
	end
	for _, plot in ipairs(GameState.Plots) do
		local offset = root.Position - plot.Center
		if math.abs(offset.X) <= 23 and math.abs(offset.Z) <= 23 then
			return true
		end
	end
	return false
end

local function runWave()
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Size = Vector3.new(12, 36, 380)
	wall.Color = Color3.fromRGB(60, 140, 255)
	wall.Material = Enum.Material.Glass
	wall.Transparency = 0.3
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanQuery = false
	wall.CanTouch = false
	wall.Position = Vector3.new(GameState.WAVE_MIN_X, 14, 0)
	wall.Parent = worldFolder

	local crest = Instance.new("Part")
	crest.Name = "TsunamiCrest"
	crest.Size = Vector3.new(13, 5, 380)
	crest.Color = Color3.fromRGB(235, 248, 255)
	crest.Material = Enum.Material.Neon
	crest.Transparency = 0.25
	crest.Anchored = true
	crest.CanCollide = false
	crest.CanQuery = false
	crest.CanTouch = false
	crest.Position = Vector3.new(GameState.WAVE_MIN_X, 33, 0)
	crest.Parent = worldFolder

	GameState.Notify(nil, "TSUNAMI DATANG! Brainrot di luar basis akan hanyut!", "danger")
	local killed = {}
	local started = os.clock()
	while true do
		local alpha = (os.clock() - started) / GameState.WAVE_SWEEP_TIME
		if alpha >= 1 then
			break
		end
		local waveX = GameState.WAVE_MIN_X + (GameState.WAVE_MAX_X - GameState.WAVE_MIN_X) * alpha
		wall.Position = Vector3.new(waveX, 14, 0)
		crest.Position = Vector3.new(waveX, 33, 0)

		-- Brainrots caught outside a base (on the belt or walking home) wash away.
		for model, record in pairs(GameState.Brainrots) do
			if (record.State == "Shop" or record.State == "Walking") and model.Parent then
				if MoveService.FeetPosition(model).X <= waveX + 6 then
					local owner = record.Owner
					local name = record.Def.Name
					destroyBrainrot(record)
					if owner then
						GameState.Notify(owner.Player, name .. " kebawa tsunami sebelum sampai basis!", "danger")
						pushStats(owner)
					end
				end
			end
		end

		-- Players caught in the open get swept too.
		for _, player in ipairs(Players:GetPlayers()) do
			if not killed[player.UserId] then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if root and humanoid and humanoid.Health > 0 and root.Position.X <= waveX + 6 then
					if not playerInsideAnyBase(player) then
						killed[player.UserId] = true
						humanoid.Health = 0
						GameState.Notify(player, "Kamu keseret tsunami! Masuk ke basis sebelum gelombang datang.", "danger")
					end
				end
			end
		end
		RunService.Heartbeat:Wait()
	end

	wall:Destroy()
	crest:Destroy()
	GameState.Notify(nil, "Tsunami sudah lewat. Aman... untuk sekarang.", "good")
end

task.spawn(function()
	while true do
		local remaining = GameState.WAVE_INTERVAL
		while remaining > 0 do
			local phase = remaining <= GameState.WAVE_WARNING and "Warning" or "Calm"
			GameState.WaveSecondsLeft = remaining
			GameState.WavePhase = phase
			GameState.Remote("WaveUpdate"):FireAllClients({ SecondsLeft = remaining, Phase = phase })
			task.wait(1)
			remaining -= 1
		end
		GameState.WaveSecondsLeft = 0
		GameState.WavePhase = "Sweep"
		GameState.Remote("WaveUpdate"):FireAllClients({ SecondsLeft = 0, Phase = "Sweep" })
		local ok, err = pcall(runWave)
		if not ok then
			warn("Wave failed: " .. tostring(err))
		end
	end
end)

-- Rebirth -----------------------------------------------------------------------

GameState.Remote("RebirthRequest").OnServerEvent:Connect(function(player)
	local data = GameState.Players[player.UserId]
	if not data then
		return
	end
	local cost = GameState.RebirthCost(data.Rebirths)
	if data.Cash < cost then
		GameState.Notify(player, "Rebirth butuh cash " .. BrainrotData.FormatCash(cost) .. " di tangan.", "danger")
		return
	end
	for _, record in ipairs(table.clone(data.Brainrots)) do
		destroyBrainrot(record)
	end
	data.Cash = 0
	data.StoredCash = 0
	data.Rebirths += 1
	if data.Plot then
		data.Plot.CollectLabel.Text = "$0"
	end
	GameState.Notify(player, "REBIRTH! Penghasilanmu sekarang x" .. string.format("%.2f", GameState.IncomeMultiplier(data.Rebirths)) .. " permanen.", "good")
	pushStats(data)
end)

-- Movement heartbeat -------------------------------------------------------------

RunService.Heartbeat:Connect(function(dt)
	MoveService.Step(dt)
end)

Thief.Start(liveFolder)

print("Brainrot Bazaar server ready: world built, conveyor running.")
