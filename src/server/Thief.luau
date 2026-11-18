-- Thief.luau
-- The MALING: a sneaky NPC who periodically creeps toward the richest
-- unlocked base, grabs its most valuable brainrot and runs off with it.
-- Locked bases are skipped entirely. While he approaches, the server shows
-- every player a "MALING!" warning toast through the shared toast callback
-- the bootstrap installs.

local GameState = require(script.Parent.GameState)
local MoveService = require(script.Parent.MoveService)

local Thief = {}

-- Installed by init.server.luau: function(text, duration) shown to everyone.
Thief.BroadcastToast = nil

local function buildThiefModel()
	local model = Instance.new("Model")
	model.Name = "Maling"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1.9, 2.4, 1.2)
	body.Color = Color3.fromRGB(35, 35, 40)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 1.2, 0)
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.3, 1.1, 1.3)
	head.Color = Color3.fromRGB(230, 190, 150)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(0, 3, 0)
	head.Parent = model

	-- Black mask stripe across the eyes.
	local mask = Instance.new("Part")
	mask.Name = "Mask"
	mask.Size = Vector3.new(1.35, 0.35, 1.35)
	mask.Color = Color3.fromRGB(10, 10, 10)
	mask.Material = Enum.Material.SmoothPlastic
	mask.Anchored = true
	mask.CanCollide = false
	mask.Position = Vector3.new(0, 3.05, 0)
	mask.Parent = model

	-- Loot sack on his back.
	local sack = Instance.new("Part")
	sack.Name = "Sack"
	sack.Size = Vector3.new(1.4, 1.6, 0.9)
	sack.Color = Color3.fromRGB(120, 90, 50)
	sack.Material = Enum.Material.Fabric
	sack.Anchored = true
	sack.CanCollide = false
	sack.Position = Vector3.new(0, 1.8, 0.95)
	sack.Parent = model

	model.PrimaryPart = body
	return model
end

-- The richest unlocked plot that actually holds a brainrot, plus the index
-- of its most valuable brainrot entry.
local function pickTarget()
	local bestPlot, bestEntry, bestIncome = nil, nil, -1
	for _, state in pairs(GameState.Players) do
		local plot = state.Plot
		if plot and not GameState.IsLocked(plot) then
			for _, entry in ipairs(state.Brainrots) do
				if entry.PadIndex and entry.Income > bestIncome then
					bestPlot, bestEntry, bestIncome = plot, entry, entry.Income
				end
			end
		end
	end
	return bestPlot, bestEntry
end

-- Run one theft. Returns true when a brainrot was stolen.
function Thief.RunOnce()
	local plot, victim = pickTarget()
	if not plot or not victim then
		return false
	end
	local ownerState = plot.Owner
	if not ownerState then
		return false
	end

	if Thief.BroadcastToast then
		Thief.BroadcastToast("MALING! Ada maling mengincar base terkaya!", 5)
	end

	local thief = buildThiefModel()
	thief.Parent = workspace
	-- He slinks in from the map edge nearest the target plot.
	local startPos = Vector3.new(plot.Centre.X > 0 and 210 or -210, 1, plot.Centre.Z)
	thief:PivotTo(CFrame.new(startPos))

	local pad = plot.Pads[victim.PadIndex]
	local arrived = false
	MoveService.WalkTo(thief, Vector3.new(pad.Position.X, 1, pad.Position.Z), GameState.Constants.ThiefSpeed, function()
		arrived = true
	end)
	-- Wait for arrival, but give up if the walk stalls, the thief vanishes,
	-- or the victim's owner leaves mid-approach.
	local waited = 0
	while not arrived and thief.Parent and waited < 30 do
		if GameState.GetPlayerState(ownerState.Player) ~= ownerState then
			break
		end
		task.wait(0.25)
		waited += 0.25
	end
	MoveService.Stop(thief)

	-- The situation may have changed while he walked: re-validate.
	if not thief.Parent
		or GameState.GetPlayerState(ownerState.Player) ~= ownerState
		or GameState.IsLocked(plot)
		or not table.find(ownerState.Brainrots, victim)
	then
		thief:Destroy()
		return false
	end

	-- Grab: detach the brainrot from its owner and carry it on his back.
	for i, entry in ipairs(ownerState.Brainrots) do
		if entry == victim then
			table.remove(ownerState.Brainrots, i)
			break
		end
	end
	MoveService.Stop(victim.Model)
	victim.Model.Parent = workspace
	local thiefPivot = thief:GetPivot().Position
	victim.Model:PivotTo(CFrame.new(thiefPivot.X, 3.4, thiefPivot.Z))

	if Thief.BroadcastToast then
		Thief.BroadcastToast("MALING berhasil mencuri " .. victim.Model.Name .. "!", 5)
	end

	-- Carry the loot along as he escapes to the map edge.
	local escapePos = Vector3.new(startPos.X, 1, plot.Centre.Z)
	local carryConn
	carryConn = game:GetService("RunService").Heartbeat:Connect(function()
		if not thief.Parent or not victim.Model.Parent then
			carryConn:Disconnect()
			return
		end
		local p = thief:GetPivot().Position
		victim.Model:PivotTo(CFrame.new(p.X, 3.4, p.Z))
	end)
	MoveService.WalkTo(thief, escapePos, GameState.Constants.ThiefSpeed + 3, function()
		carryConn:Disconnect()
		victim.Model:Destroy()
		thief:Destroy()
	end)
	return true
end

-- Endless loop with a randomised pause between visits; started once by the
-- bootstrap.
function Thief.StartLoop()
	task.spawn(function()
		while true do
			local delay = GameState.Constants.ThiefMinDelay
				+ math.random() * (GameState.Constants.ThiefMaxDelay - GameState.Constants.ThiefMinDelay)
			task.wait(delay)
			local ok, err = pcall(Thief.RunOnce)
			if not ok then
				warn("[BrainrotBazaar] thief failed: " .. tostring(err))
			end
		end
	end)
end

return Thief
