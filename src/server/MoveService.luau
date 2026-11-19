-- MoveService.luau
-- Walks brainrot models (and the thief) along a list of waypoints.
--
-- Movement rule that keeps this service safe: steering happens on the XZ
-- plane only, and the model's height is PINNED every step to the current
-- waypoint's absolute Y plus the mover's fixed lift. The model's current Y
-- is never read back into its height, so a model can never ratchet itself
-- upward step by step.

local RunService = game:GetService("RunService")

local MoveService = {}

local movers = {}
local heartbeatBound = false

local BOB_HEIGHT = 0.12
local BOB_SPEED = 7

local function stepMover(mover, dt)
	local model = mover.Model
	if not model.Parent then
		movers[model] = nil
		return
	end
	local target = mover.Targets[mover.Index]
	if not target then
		movers[model] = nil
		if mover.OnArrive then
			mover.OnArrive()
		end
		return
	end

	-- Absolute pinned height for this leg: waypoint Y + fixed lift + bob.
	local bob = math.sin(os.clock() * BOB_SPEED + mover.Phase) * BOB_HEIGHT
	local pinnedY = target.Y + mover.Lift + bob

	local pivot = model:GetPivot()
	local dx = target.X - pivot.Position.X
	local dz = target.Z - pivot.Position.Z
	local dist = math.sqrt(dx * dx + dz * dz)
	local step = mover.Speed * dt

	if dist <= math.max(step, 0.15) then
		-- Arrive on this waypoint: snap XZ exactly, keep the pinned height.
		model:PivotTo(CFrame.new(target.X, pinnedY, target.Z))
		mover.Index += 1
		if mover.Index > #mover.Targets then
			movers[model] = nil
			if mover.OnArrive then
				mover.OnArrive()
			end
		end
		return
	end

	local nx = pivot.Position.X + dx / dist * step
	local nz = pivot.Position.Z + dz / dist * step
	-- Face the walk direction while moving.
	local facing = CFrame.lookAt(Vector3.new(nx, pinnedY, nz), Vector3.new(target.X, pinnedY, target.Z))
	model:PivotTo(facing)
end

local function ensureHeartbeat()
	if heartbeatBound then
		return
	end
	heartbeatBound = true
	RunService.Heartbeat:Connect(function(dt)
		for _, mover in pairs(movers) do
			stepMover(mover, dt)
		end
	end)
end

-- Walk a model through waypoints (Vector3 list) at speed studs/second.
-- lift is the fixed height above each waypoint's Y the pivot rides at.
-- onArrive fires once, when the last waypoint is reached.
function MoveService.Walk(model, waypoints, speed, lift, onArrive)
	ensureHeartbeat()
	movers[model] = {
		Model = model,
		Targets = waypoints,
		Index = 1,
		Speed = speed,
		Lift = lift,
		Phase = math.random() * math.pi * 2,
		OnArrive = onArrive,
	}
end

-- Walk in a straight line to one point.
function MoveService.WalkTo(model, point, speed, lift, onArrive)
	MoveService.Walk(model, { point }, speed, lift, onArrive)
end

-- Teleport a model so its pivot sits at an absolute position, facing angle.
function MoveService.PlaceAt(model, position, facingAngle)
	local angle = facingAngle or 0
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, angle, 0))
end

function MoveService.Stop(model)
	movers[model] = nil
end

function MoveService.IsWalking(model)
	return movers[model] ~= nil
end

-- Turn a model to face a world point without moving it (XZ plane only, the
-- height stays exactly where the pivot already is).
function MoveService.FaceToward(model, point)
	local pivot = model:GetPivot()
	local flat = Vector3.new(point.X, pivot.Position.Y, point.Z)
	if (flat - pivot.Position).Magnitude > 0.01 then
		model:PivotTo(CFrame.lookAt(pivot.Position, flat))
	end
end

-- How many models are mid-walk right now (debug and tsunami bookkeeping).
function MoveService.ActiveCount()
	local count = 0
	for _ in pairs(movers) do
		count += 1
	end
	return count
end

return MoveService
