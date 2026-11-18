-- MoveService.luau
-- One tiny mover for every character in the game: shop walkers strolling the
-- conveyor, bought brainrots hurrying home, the thief sneaking around and his
-- victim riding on his head. Models are anchored, so movement is done by
-- stepping each model's pivot toward a target ground position every frame,
-- with a little walk-bob so they feel alive.

local MoveService = {}

type Mover = {
	Model: Model,
	Lift: number, -- pivot height above the feet, captured at Add time
	TargetFn: () -> Vector3,
	Speed: number,
	OnArrive: (() -> ())?,
	BobPhase: number,
}

local movers: { [Model]: Mover } = {}

-- Start moving a model. targetFn returns the ground position to walk to
-- (feet level); it is re-read every frame so targets can follow other models.
function MoveService.Add(model: Model, targetFn: () -> Vector3, speed: number, onArrive: (() -> ())?)
	movers[model] = {
		Model = model,
		Lift = model:GetAttribute("PivotLift") or 1.3,
		TargetFn = targetFn,
		Speed = speed,
		OnArrive = onArrive,
		BobPhase = math.random() * math.pi * 2,
	}
end

function MoveService.Remove(model: Model)
	movers[model] = nil
end

function MoveService.IsMoving(model: Model): boolean
	return movers[model] ~= nil
end

-- Current feet position of a registered (or any) model.
function MoveService.FeetPosition(model: Model): Vector3
	local entry = movers[model]
	local pivot = model:GetPivot().Position
	if entry then
		return pivot - Vector3.new(0, entry.Lift, 0)
	end
	return pivot
end

function MoveService.Step(dt: number)
	for model, entry in pairs(movers) do
		if not model.Parent then
			movers[model] = nil
		else
			local target = entry.TargetFn()
			-- Steer in the XZ plane only, and take the height from the target
			-- itself: the pivot is re-pinned to target.Y + Lift every step, so
			-- a walker's height can never accumulate from its current pivot.
			-- The old step fed the current pivot Y back in through
			-- FeetPosition (and wrote the bob into the pivot without reading
			-- it back out), which in live Studio ratcheted the shop walkers
			-- up into the sky instead of keeping them on the belt plane.
			local pivot = model:GetPivot().Position
			local dx = target.X - pivot.X
			local dz = target.Z - pivot.Z
			local distance = math.sqrt(dx * dx + dz * dz)
			if distance < 0.75 and entry.OnArrive then
				local arrived = entry.OnArrive
				movers[model] = nil
				arrived()
			elseif distance < 0.75 then
				-- Follow mode (no OnArrive): stay glued to the moving target.
				local lift = Vector3.new(0, entry.Lift, 0)
				model:PivotTo(CFrame.new(target + lift))
			else
				local step = math.min(distance, entry.Speed * dt)
				local ux = dx / distance
				local uz = dz / distance
				local nextX = pivot.X + ux * step
				local nextZ = pivot.Z + uz * step
				entry.BobPhase += dt * entry.Speed * 1.6
				local bob = math.abs(math.sin(entry.BobPhase)) * 0.22
				local pos = Vector3.new(nextX, target.Y + entry.Lift + bob, nextZ)
				local facing = pos + Vector3.new(ux, 0, uz)
				model:PivotTo(CFrame.lookAt(pos, facing))
			end
		end
	end
end

return MoveService
