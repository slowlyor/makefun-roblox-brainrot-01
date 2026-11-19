-- MoveService.luau
-- XZ-plane steering for every walking model in Brainrot Bazaar: belt
-- shoppers, gacha prizes walking home, and the thief.
--
-- Height rule (the important one): a model's pivot Y is pinned ABSOLUTELY
-- from its current target -- belt riders ride at BELT_TOP + lift, ground
-- walkers at 0 + lift. The model's current Y is never read back into its
-- height, so a walker can step from the belt down to the grass (or the
-- reverse) without sinking, floating or accumulating drift.

local RunService = game:GetService("RunService")

local MoveService = {}

-- World heights the targets are pinned against.
MoveService.BELT_TOP = 1.3
MoveService.GROUND_TOP = 0

type Walker = {
	model: Model,
	lift: number, -- pivot height above the surface it walks on
	speed: number, -- studs per second
	queue: { Vector3 }, -- remaining XZ waypoints
	surfaceY: number, -- absolute Y of the surface under the current leg
	onArrive: (() -> ())?,
	face: Vector3?, -- last movement direction, for facing
}

local walkers: { [Model]: Walker } = {}
local heartbeatConn: RBXScriptConnection? = nil

-- The vertical offset of a model's pivot above the surface it stands on.
-- Models are built standing on Y=0 with the pivot at their base, so the
-- lift is simply how tall the builder left the pivot; we measure it once
-- at build time from the model's bounding box base.
local function measureLift(model: Model): number
	local cf, _size = model:GetBoundingBox()
	-- The factory builds every character with its pivot at half height.
	return math.max(0.5, cf.Position.Y)
end

-- Register a model to walk through `waypoints` (Vector3s; only X/Z are
-- used). `surfaceY` is the absolute height of the surface it walks on for
-- the whole route. onArrive fires once when the last waypoint is reached.
function MoveService.walk(model: Model, waypoints: { Vector3 }, speed: number, surfaceY: number, onArrive: (() -> ())?)
	if #waypoints == 0 then
		if onArrive then
			onArrive()
		end
		return
	end
	walkers[model] = {
		model = model,
		lift = measureLift(model),
		speed = speed,
		queue = table.clone(waypoints),
		surfaceY = surfaceY,
		onArrive = onArrive,
		face = nil,
	}
	MoveService.ensureLoop()
end

-- Stop a model where it stands (used when a belt walker is bought: the
-- purchase code immediately re-registers it toward its new home pad).
function MoveService.stop(model: Model)
	walkers[model] = nil
end

function MoveService.isWalking(model: Model): boolean
	return walkers[model] ~= nil
end

local function step(dt: number)
	for model, w in pairs(walkers) do
		if not model.Parent then
			walkers[model] = nil
		else
			local target = w.queue[1]
			local pos = model:GetPivot().Position
			local dx = target.X - pos.X
			local dz = target.Z - pos.Z
			local dist = math.sqrt(dx * dx + dz * dz)
			local stepLen = w.speed * dt
			local nx, nz = pos.X, pos.Z
			if dist <= stepLen or dist < 0.05 then
				nx, nz = target.X, target.Z
				table.remove(w.queue, 1)
			else
				nx = pos.X + dx / dist * stepLen
				nz = pos.Z + dz / dist * stepLen
				w.face = Vector3.new(dx, 0, dz)
			end
			-- Pin Y from the target surface, never from the current Y.
			local pinnedY = w.surfaceY + w.lift
			local facing = w.face or Vector3.new(1, 0, 0)
			local look = CFrame.lookAt(Vector3.new(nx, pinnedY, nz), Vector3.new(nx + facing.X, pinnedY, nz + facing.Z))
			model:PivotTo(look)
			if #w.queue == 0 then
				local cb = w.onArrive
				walkers[model] = nil
				if cb then
					cb()
				end
			end
		end
	end
end

-- Teleport a model onto a surface, still honouring the pinning rule: the
-- caller names the surface height, the lift does the rest. Used when a
-- bought brainrot is placed on its pad and when walkers first spawn.
function MoveService.placeOn(model: Model, x: number, z: number, surfaceY: number, faceX: number?, faceZ: number?)
	local lift = measureLift(model)
	local fx = faceX or 0
	local fz = faceZ or 1
	local at = Vector3.new(x, surfaceY + lift, z)
	model:PivotTo(CFrame.lookAt(at, at + Vector3.new(fx, 0, fz)))
end

-- How many models are currently walking; the spawner uses it to cap the
-- belt so a busy server never floods the map with shoppers.
function MoveService.activeCount(): number
	local n = 0
	for _ in pairs(walkers) do
		n += 1
	end
	return n
end

function MoveService.ensureLoop()
	if heartbeatConn then
		return
	end
	heartbeatConn = RunService.Heartbeat:Connect(step)
end

return MoveService
