-- MoveService.luau -- steers brainrot models across the map.
-- Movement is on the XZ plane only. A model's pivot Y is pinned
-- ABSOLUTELY from its mover spec (baseY + the model's Lift attribute):
-- belt riders ride at belt top 1.3 + lift, ground walkers at 0 + lift.
-- The model's current Y is never read back into its height, so a model
-- can step off the belt without sinking or floating.

local MoveService = {}

MoveService.Movers = {} -- [model] = mover
MoveService.BELT_Y = 1.3
MoveService.GROUND_Y = 0

local function liftOf(model)
	return model:GetAttribute("Lift") or 1.75
end

-- Start moving a model toward (targetX, targetZ). baseY is the ground
-- height under the model (belt top or ground). onArrive fires once.
function MoveService.WalkTo(model, targetX, targetZ, baseY, speed, onArrive)
	MoveService.Movers[model] = {
		Model = model,
		TargetX = targetX,
		TargetZ = targetZ,
		BaseY = baseY,
		Speed = speed or 7,
		OnArrive = onArrive,
		Arrived = false,
	}
end

-- Queue a chain of waypoints: each entry { X, Z, BaseY, Speed }.
-- The model walks them in order; onDone fires after the last one.
function MoveService.WalkPath(model, waypoints, onDone)
	if #waypoints == 0 then
		if onDone then
			onDone()
		end
		return
	end
	local index = 0
	local function step()
		index += 1
		local wp = waypoints[index]
		if not wp then
			if onDone then
				onDone()
			end
			return
		end
		MoveService.WalkTo(model, wp.X, wp.Z, wp.BaseY, wp.Speed, step)
	end
	step()
end

function MoveService.Stop(model)
	MoveService.Movers[model] = nil
end

-- Drop every mover whose model belongs to a set (used by the tsunami,
-- which destroys belt models wholesale while their movers still exist).
function MoveService.StopWhere(predicate)
	for model in pairs(MoveService.Movers) do
		if predicate(model) then
			MoveService.Movers[model] = nil
		end
	end
end

function MoveService.ActiveCount()
	local n = 0
	for _ in pairs(MoveService.Movers) do
		n += 1
	end
	return n
end

function MoveService.IsMoving(model)
	return MoveService.Movers[model] ~= nil
end

-- Teleport a model onto a flat spot, pinning its height from baseY.
function MoveService.PlaceAt(model, x, z, baseY, facingAngle)
	local lift = liftOf(model)
	local cf = CFrame.new(Vector3.new(x, baseY + lift, z))
	if facingAngle then
		cf = cf * CFrame.Angles(0, facingAngle, 0)
	end
	model:PivotTo(cf)
end

-- Advance every mover. Called once per Heartbeat from init.server.luau.
-- Walking bob: a small sine hop added on top of the pinned height.
function MoveService.Update(dt, now)
	for model, mover in pairs(MoveService.Movers) do
		if not model.Parent then
			MoveService.Movers[model] = nil
		else
			local pivot = model:GetPivot()
			local dx = mover.TargetX - pivot.Position.X
			local dz = mover.TargetZ - pivot.Position.Z
			local dist = math.sqrt(dx * dx + dz * dz)
			local lift = liftOf(model)
			if dist < 0.35 then
				model:PivotTo(CFrame.new(Vector3.new(mover.TargetX, mover.BaseY + lift, mover.TargetZ))
					* (pivot - pivot.Position))
				MoveService.Movers[model] = nil
				if mover.OnArrive and not mover.Arrived then
					mover.Arrived = true
					mover.OnArrive()
				end
			else
				local step = math.min(dist, mover.Speed * dt)
				local nx = pivot.Position.X + dx / dist * step
				local nz = pivot.Position.Z + dz / dist * step
				local bob = math.abs(math.sin(now * 9 + pivot.Position.X)) * 0.16
				local facing = math.atan2(dx, dz)
				model:PivotTo(CFrame.new(Vector3.new(nx, mover.BaseY + lift + bob, nz))
					* CFrame.Angles(0, facing, 0))
			end
		end
	end
end

return MoveService
