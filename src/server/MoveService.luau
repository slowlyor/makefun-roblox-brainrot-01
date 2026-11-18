-- MoveService.luau
-- A tiny stepping walker. Callers register a model with a target position and
-- a speed; every Heartbeat step the service glides each registered model
-- toward its target along the ground plane.
--
-- The important rule: the model's height is FIXED at registration time from
-- the target's Y. The walker never reads the model's current pivot Y and
-- never accumulates height step over step, so belt riders stay glued to the
-- belt-top height and base walkers stay at pad height forever.

local RunService = game:GetService("RunService")

local MoveService = {}

-- Active walks: model -> { Target = Vector3, Speed = number, FixedY = number,
--                          OnArrive = function or nil }
local walks = {}

-- Begin walking `model` toward `target`. The model's Y is pinned to
-- target.Y for the whole walk. onArrive fires once, on arrival.
function MoveService.WalkTo(model, target, speed, onArrive)
	if not model or not model.Parent then
		return
	end
	walks[model] = {
		Target = target,
		Speed = speed,
		FixedY = target.Y,
		OnArrive = onArrive,
	}
end

-- Stop walking a model (despawn, theft, tsunami wash-away).
function MoveService.Stop(model)
	walks[model] = nil
end

function MoveService.IsWalking(model)
	return walks[model] ~= nil
end

-- Number of models currently walking (diagnostics).
function MoveService.ActiveWalkCount()
	local count = 0
	for _ in pairs(walks) do
		count += 1
	end
	return count
end

-- Is the model standing on (or inside) any plot floor? Used by the tsunami
-- to decide who is sheltered. Plot floors are tagged with a PlotIndex
-- attribute by WorldBuilder.
function MoveService.IsInsideAnyPlot(position, plots)
	for _, plot in ipairs(plots) do
		local floor = plot.Floor
		if floor then
			local half = floor.Size / 2
			local centre = floor.Position
			if math.abs(position.X - centre.X) <= half.X and math.abs(position.Z - centre.Z) <= half.Z then
				return true
			end
		end
	end
	return false
end

RunService.Heartbeat:Connect(function(dt)
	-- Collect arrivals first so callbacks can safely start new walks.
	local arrived = {}
	for model, walk in pairs(walks) do
		if not model.Parent then
			walks[model] = nil
		else
			local pivot = model:GetPivot()
			local dx = walk.Target.X - pivot.Position.X
			local dz = walk.Target.Z - pivot.Position.Z
			local distance = math.sqrt(dx * dx + dz * dz)
			local step = walk.Speed * dt
			if distance <= math.max(step, 0.15) then
				-- Horizontal arrival: snap exactly onto the target, keeping
				-- the pinned height.
				model:PivotTo(CFrame.new(walk.Target.X, walk.FixedY, walk.Target.Z))
				table.insert(arrived, model)
			else
				local nx = pivot.Position.X + (dx / distance) * step
				local nz = pivot.Position.Z + (dz / distance) * step
				-- Face the direction of travel while gliding.
				local facing = CFrame.lookAt(
					Vector3.new(nx, walk.FixedY, nz),
					Vector3.new(walk.Target.X, walk.FixedY, walk.Target.Z)
				)
				model:PivotTo(facing)
			end
		end
	end
	for _, model in ipairs(arrived) do
		local walk = walks[model]
		walks[model] = nil
		if walk and walk.OnArrive then
			task.spawn(walk.OnArrive, model)
		end
	end
end)

return MoveService
