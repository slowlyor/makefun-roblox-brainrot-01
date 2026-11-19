-- Thief.luau
-- The tension engine: every so often a sneaky thief NPC creeps out of the
-- shadows, walks to the richest brainrot sitting in an UNLOCKED base,
-- snatches it, and runs off with it. Locked bases are completely safe,
-- which is what the 60-second lock button is for.

local Thief = {}

local FIRST_VISIT_DELAY = 50
local VISIT_INTERVAL_MIN = 55
local VISIT_INTERVAL_MAX = 85
local THIEF_SPEED = 17
local HIDEOUT = Vector3.new(-108, 1, 66)

local function buildThiefModel()
	local model = Instance.new("Model")
	model.Name = "PencuriBrainrot"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2, 2.6, 1.2)
	body.Color = Color3.fromRGB(35, 35, 45)
	body.Material = Enum.Material.SmoothPlastic
	body.CanCollide = false
	body.Parent = model
	model.PrimaryPart = body

	local function attach(name, size, offset, color, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide = false
		if shape then
			p.Shape = shape
		end
		p.CFrame = body.CFrame * offset
		p.Parent = model
		local joint = Instance.new("WeldConstraint")
		joint.Part0 = body
		joint.Part1 = p
		joint.Parent = p
		return p
	end

	-- Hood, mask stripe and a big empty loot sack on the back.
	attach("Hood", Vector3.new(1.5, 1.1, 1.5), CFrame.new(0, 1.8, 0), Color3.fromRGB(25, 25, 35), Enum.PartType.Ball)
	attach("Mask", Vector3.new(1.3, 0.35, 0.2), CFrame.new(0, 1.85, -0.65), Color3.fromRGB(200, 200, 210))
	attach("Sack", Vector3.new(1.7, 2, 1), CFrame.new(0, 0.3, 1.1), Color3.fromRGB(150, 120, 80), Enum.PartType.Ball)
	attach("LegL", Vector3.new(0.6, 1.2, 0.6), CFrame.new(-0.5, -1.9, 0), Color3.fromRGB(25, 25, 35))
	attach("LegR", Vector3.new(0.6, 1.2, 0.6), CFrame.new(0.5, -1.9, 0), Color3.fromRGB(25, 25, 35))

	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(180, 44)
	gui.StudsOffset = Vector3.new(0, 3.6, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "PENCURI BRAINROT!"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(255, 90, 90)
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	gui.Parent = model
	return model
end

-- One theft attempt. Returns true when something was actually stolen.
local function attemptTheft(ctx)
	local target = ctx.GameState.FindRichestStolenCandidate()
	if not target or not target.Pad.Model then
		return false
	end
	local record = target.Record
	local victim = record.Player
	local padPos = ctx.GameState.GetPadPosition(record.BaseIndex, target.PadIndex)
	local stolenModel = target.Pad.Model
	local stolenName = target.Pad.Entry.Name

	local thief = buildThiefModel()
	thief.Parent = workspace
	ctx.MoveService.PlaceAt(thief, HIDEOUT + Vector3.new(0, 3.2, 0), 0)
	ctx.ToastAll("Ada pencuri mengintai bazaar... kunci base kalian!")

	local arrived = Instance.new("BindableEvent")
	ctx.MoveService.Walk(thief, {
		Vector3.new(padPos.X, 0, padPos.Z + 14),
		Vector3.new(padPos.X, 0, padPos.Z),
	}, THIEF_SPEED, 3.2, function()
		arrived:Fire()
	end)
	arrived.Event:Wait()

	-- If the owner locked the base or sold the pad mid-creep, back off.
	if ctx.GameState.IsLocked(record) or record.Pads[target.PadIndex] == nil then
		ctx.Toast(victim, "Pencuri gagal masuk — base terkunci!")
		ctx.MoveService.WalkTo(thief, HIDEOUT + Vector3.new(0, 3.2, 0), THIEF_SPEED, 3.2, function()
			thief:Destroy()
		end)
		return false
	end

	-- Snatch: clear the pad, parent the prize into the thief's sack spot.
	ctx.GameState.ClearPad(record, target.PadIndex)
	stolenModel.Parent = thief
	ctx.MoveService.PlaceAt(stolenModel, thief:GetPivot().Position + Vector3.new(0, 1.5, 1.8), 0)
	ctx.Toast(victim, "Pencuri mencuri " .. stolenName .. " dari base kamu!")
	ctx.ToastAll(stolenName .. " dicuri dari base yang tidak terkunci!")
	ctx.SyncState(victim)

	ctx.MoveService.WalkTo(thief, HIDEOUT + Vector3.new(0, 3.2, 0), THIEF_SPEED + 4, 3.2, function()
		thief:Destroy()
	end)
	return true
end

-- How long until the next visit, randomised so players cannot time it.
function Thief.NextVisitDelay(rng)
	return rng:NextNumber(VISIT_INTERVAL_MIN, VISIT_INTERVAL_MAX)
end

-- Start the endless thief loop on its own task.
function Thief.Start(ctx)
	task.spawn(function()
		local rng = Random.new()
		task.wait(FIRST_VISIT_DELAY)
		while true do
			local ok, err = pcall(function()
				attemptTheft(ctx)
			end)
			if not ok then
				warn("Thief visit failed: " .. tostring(err))
			end
			task.wait(Thief.NextVisitDelay(rng))
		end
	end)
end

return Thief
