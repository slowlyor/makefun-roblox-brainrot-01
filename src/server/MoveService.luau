-- MoveService.luau
-- Brainrot Bazaar: walks Models along XZ waypoints.
-- The one rule that keeps walkers glued to their floor: a walker's
-- pivot Y comes ONLY from the PivotY it registered with (belt top +
-- lift, or ground + lift). The model's current Y is never read back
-- into its height, so a walker can never sink or float away.

local RunService = game:GetService("RunService")

local MoveService = {}

MoveService.Walkers = {}
local connection = nil

local function stepWalker(walker, dt)
	local model = walker.Model
	if not model or not model.Parent then
		walker.Dead = true
		return
	end
	local target = walker.Path[walker.Index]
	if not target then
		walker.Dead = true
		if walker.OnArrive then
			walker.OnArrive(walker)
		end
		return
	end
	local pivot = model:GetPivot()
	local dx = target.X - pivot.X
	local dz = target.Z - pivot.Z
	local dist = math.sqrt(dx * dx + dz * dz)
	local step = walker.Speed * dt
	if dist <= math.max(step, 0.05) then
		-- Land exactly on the waypoint, still at the pinned height.
		local pos = Vector3.new(target.X, walker.PivotY, target.Z)
		if dist > 0.001 then
			model:PivotTo(CFrame.lookAt(pos, Vector3.new(target.X + dx, walker.PivotY, target.Z + dz)))
		else
			model:PivotTo(CFrame.new(pos) * (pivot - pivot.Position))
		end
		walker.Index += 1
		if walker.Index > #walker.Path then
			walker.Dead = true
			if walker.OnArrive then
				walker.OnArrive(walker)
			end
		end
		return
	end
	local nx = pivot.X + dx / dist * step
	local nz = pivot.Z + dz / dist * step
	local pos = Vector3.new(nx, walker.PivotY, nz)
	local ahead = Vector3.new(nx + dx, walker.PivotY, nz + dz)
	model:PivotTo(CFrame.lookAt(pos, ahead))
	-- A gentle bob and foot shuffle sell the walk without touching Y.
	walker.BobPhase = (walker.BobPhase or 0) + dt * 9
	local footL = model:FindFirstChild("FootL")
	local footR = model:FindFirstChild("FootR")
	if footL and footR then
		local swing = math.sin(walker.BobPhase) * 0.3
		local base = model:GetPivot()
		footL.Position = base:PointToWorldSpace(Vector3.new(-0.55, -0.8, -0.1 + swing))
		footR.Position = base:PointToWorldSpace(Vector3.new(0.55, -0.8, -0.1 - swing))
	end
end

-- Register a walker. opts: { Path = {Vector3,...}, Speed, PivotY,
-- OnArrive = fn(walker), OnCancel = fn(walker), Tag = string }
function MoveService.Add(model, opts)
	local walker = {
		Model = model,
		Path = opts.Path,
		Index = 1,
		Speed = opts.Speed or 7,
		PivotY = opts.PivotY,
		OnArrive = opts.OnArrive,
		OnCancel = opts.OnCancel,
		Tag = opts.Tag,
		Dead = false,
		BobPhase = 0,
		Extra = opts.Extra,
	}
	table.insert(MoveService.Walkers, walker)
	return walker
end

function MoveService.Remove(walker, destroyModel)
	walker.Dead = true
	if destroyModel and walker.Model then
		walker.Model:Destroy()
	end
end

function MoveService.FindByModel(model)
	for _, walker in ipairs(MoveService.Walkers) do
		if walker.Model == model and not walker.Dead then
			return walker
		end
	end
	return nil
end

-- Cancel every walker with a tag (the tsunami uses Tag = "belt").
-- onCancel decides whether the model is destroyed or just stopped.
function MoveService.CancelByTag(tag, destroyModel)
	local cancelled = {}
	for _, walker in ipairs(MoveService.Walkers) do
		if walker.Tag == tag and not walker.Dead then
			walker.Dead = true
			table.insert(cancelled, walker)
			if walker.OnCancel then
				walker.OnCancel(walker)
			end
			if destroyModel and walker.Model then
				walker.Model:Destroy()
			end
		end
	end
	return cancelled
end

function MoveService.CountByTag(tag)
	local n = 0
	for _, walker in ipairs(MoveService.Walkers) do
		if walker.Tag == tag and not walker.Dead then
			n += 1
		end
	end
	return n
end

function MoveService.Start()
	if connection then
		return
	end
	connection = RunService.Heartbeat:Connect(function(dt)
		for i = #MoveService.Walkers, 1, -1 do
			local walker = MoveService.Walkers[i]
			if walker.Dead then
				table.remove(MoveService.Walkers, i)
			else
				stepWalker(walker, dt)
			end
		end
	end)
end

function MoveService.ActiveCount()
	local n = 0
	for _, walker in ipairs(MoveService.Walkers) do
		if not walker.Dead then
			n += 1
		end
	end
	return n
end

-- Stop every walker without destroying its model (used when a round
-- or a service shuts down and the models are cleaned up elsewhere).
function MoveService.StopAll()
	for _, walker in ipairs(MoveService.Walkers) do
		walker.Dead = true
	end
end

return MoveService
