-- MoveService: moves brainrots. XZ-plane steering only.
-- The pivot Y is pinned absolutely from the target (belt riders: belt top 1.3
-- + lift; ground walkers: 0 + lift). Current Y is NEVER fed back into height.

local RunService = game:GetService("RunService")

local MoveService = {}

local BELT_SPEED = 4 -- studs per second along the belt
local WALK_SPEED = 7 -- studs per second on the ground

-- Place a model pivot at (x, absoluteY, z), facing +X (belt) or a heading.
local function placeAt(model, x, y, z, headingX, headingZ)
	local cf = CFrame.new(x, y, z)
	if headingX ~= nil and (headingX ~= 0 or headingZ ~= 0) then
		cf = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(x + headingX, y, z + headingZ))
	end
	model:PivotTo(cf)
end

-- One belt rider: walks +X from xMin to xMax at beltTopY + lift.
-- Returns a handle with .stop() and .finished (true when it reached the end).
function MoveService.startBeltRide(model, beltTopY, lift, xMin, xMax, z)
	local handle = { finished = false, stopped = false }
	local x = xMin
	placeAt(model, x, beltTopY + lift, z, 1, 0)
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if handle.stopped then
			conn:Disconnect()
			return
		end
		x = x + BELT_SPEED * dt
		if x >= xMax then
			handle.finished = true
			handle.stopped = true
			conn:Disconnect()
			return
		end
		placeAt(model, x, beltTopY + lift, z, 1, 0)
	end)
	function handle.stop()
		handle.stopped = true
		if conn then
			conn:Disconnect()
		end
	end
	return handle
end

-- Walk a model on the ground from its current XZ to a target XZ.
-- onArrive fires once when it gets within 0.6 studs. Returns a handle with .stop().
function MoveService.walkTo(model, lift, targetXZ, onArrive)
	local handle = { stopped = false, arrived = false }
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if handle.stopped then
			conn:Disconnect()
			return
		end
		local pivot = model:GetPivot()
		local px, pz = pivot.X, pivot.Z
		local dx, dz = targetXZ.X - px, targetXZ.Z - pz
		local dist = math.sqrt(dx * dx + dz * dz)
		if dist <= 0.6 then
			handle.arrived = true
			handle.stopped = true
			conn:Disconnect()
			if onArrive then
				onArrive()
			end
			return
		end
		local step = math.min(WALK_SPEED * dt, dist)
		local nx = px + (dx / dist) * step
		local nz = pz + (dz / dist) * step
		-- Y pinned to 0 + lift; heading from the XZ direction only.
		placeAt(model, nx, lift, nz, dx / dist, dz / dist)
	end)
	function handle.stop()
		handle.stopped = true
		if conn then
			conn:Disconnect()
		end
	end
	return handle
end

-- Hop a model straight to a pad (used for the final snap onto a pad).
function MoveService.snapToPad(model, lift, padPos)
	placeAt(model, padPos.X, lift, padPos.Z, 0, 1)
end

-- Current XZ of a model, as a Vector3 with Y forced to 0 (height never leaks in).
function MoveService.groundXZ(model)
	local pivot = model:GetPivot()
	return Vector3.new(pivot.X, 0, pivot.Z)
end

return MoveService
