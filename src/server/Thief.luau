-- Thief: a sneaky NPC that periodically steals the richest brainrot from an
-- UNLOCKED base. Locked bases (60s seal) are safe. The thief walks in from the
-- map edge, grabs the brainrot, and walks away with it.

local Thief = {}

Thief.INTERVAL = 90 -- seconds between theft attempts

local function buildThiefModel()
	local model = Instance.new("Model")
	model.Name = "Maling Brainrot"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(2, 3, 1.4)
	body.Color = Color3.fromRGB(40, 40, 45)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Position = Vector3.new(0, 2.2, 0)
	head.Color = Color3.fromRGB(40, 40, 45)
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model
	local mask = Instance.new("Part")
	mask.Name = "Mask"
	mask.Shape = Enum.PartType.Block
	mask.Size = Vector3.new(1.4, 0.5, 0.3)
	mask.Position = Vector3.new(0, 2.3, 0.8)
	mask.Color = Color3.fromRGB(20, 20, 20)
	mask.Anchored = true
	mask.CanCollide = false
	mask.Parent = model
	local sack = Instance.new("Part")
	sack.Name = "Sack"
	sack.Shape = Enum.PartType.Ball
	sack.Size = Vector3.new(1.4, 1.4, 1.4)
	sack.Position = Vector3.new(1.3, 0.5, 0)
	sack.Color = Color3.fromRGB(150, 110, 60)
	sack.Material = Enum.Material.Fabric
	sack.Anchored = true
	sack.CanCollide = false
	sack.Parent = model
	model.PrimaryPart = body
	return model
end

-- Attempt one theft. `ctx` carries: plots, gameState, remotes, moveService, lift.
-- Returns true when a brainrot was stolen.
function Thief.attempt(ctx)
	local now = os.time()
	local candidates = {}
	for player, data in pairs(ctx.gameState.allPlayers()) do
		if data.plotIndex > 0 and now >= data.lockedUntil then
			local richestPad, richestIncome = nil, 0
			for padIndex, model in pairs(data.pads) do
				if model and model.Parent then
					local income = model:GetAttribute("Income") or 0
					if income > richestIncome then
						richestIncome = income
						richestPad = padIndex
					end
				end
			end
			if richestPad then
				table.insert(candidates, { player = player, data = data, pad = richestPad })
			end
		end
	end
	if #candidates == 0 then
		return false
	end

	local pick = candidates[math.random(1, #candidates)]
	local data = pick.data
	local victimModel = data.pads[pick.pad]
	local plot = ctx.plots[data.plotIndex]
	if not victimModel or not plot then
		return false
	end

	local padPos = plot.pads[pick.pad].Position
	data.pads[pick.pad] = nil

	local thief = buildThiefModel()
	thief.Parent = game:GetService("Workspace")
	-- Walk in from the nearest map edge, XZ only, Y pinned to 0 + lift.
	local startX = padPos.X + 60
	if padPos.X > 0 then
		startX = padPos.X - 60
	end
	thief:PivotTo(CFrame.new(startX, 1.8, padPos.Z))
	ctx.gameState.toast(ctx.remotes, pick.player, "MALING! Ada yang nyuri brainrot kamu, lari ke base!")
	ctx.gameState.toastAll(ctx.remotes, "Seorang maling mengincar base yang tidak terkunci!")

	ctx.moveService.walkTo(thief, 1.8, Vector3.new(padPos.X, 0, padPos.Z), function()
		-- Grab the brainrot and run away with it.
		if victimModel.Parent then
			-- Carry it above the thief's head while fleeing.
			victimModel:PivotTo(thief:GetPivot() * CFrame.new(0, 3.2, 0))
			victimModel.Parent = thief
		end
		local fleeX = padPos.X + 80
		if padPos.X > 0 then
			fleeX = padPos.X - 80
		end
		ctx.moveService.walkTo(thief, 1.8, Vector3.new(fleeX, 0, padPos.Z + 30), function()
			thief:Destroy()
		end)
		task.delay(12, function()
			if thief.Parent then
				thief:Destroy()
			end
		end)
	end)
	task.delay(30, function()
		if thief.Parent then
			thief:Destroy()
		end
	end)
	return true
end

-- The theft loop: one attempt every INTERVAL seconds.
function Thief.startLoop(ctx)
	task.spawn(function()
		while true do
			task.wait(Thief.INTERVAL)
			local ok, err = pcall(Thief.attempt, ctx)
			if not ok then
				warn("Thief attempt failed: " .. tostring(err))
			end
		end
	end)
end

return Thief
