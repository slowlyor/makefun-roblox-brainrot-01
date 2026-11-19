-- Thief.luau
-- Brainrot Bazaar: the thief NPC. Every so often he jogs in from the
-- plaza, grabs the single richest brainrot sitting in any UNLOCKED
-- base, and jogs off with it. A locked base is completely safe.

local Thief = {}

Thief.MIN_WAIT = 45
Thief.MAX_WAIT = 75
Thief.SPEED = 11

local function pickTarget(ctx)
	local best = nil
	for player, data in pairs(ctx.GameState.Players) do
		if not ctx.GameState.IsLocked(data) then
			local padIndex = ctx.GameState.RichestPad(data)
			if padIndex then
				local entry = data.Pads[padIndex]
				if entry and (not best or entry.Price > best.Entry.Price) then
					best = { Player = player, Data = data, PadIndex = padIndex, Entry = entry }
				end
			end
		end
	end
	return best
end

local function runOnce(ctx)
	local target = pickTarget(ctx)
	if not target then
		return
	end
	local plot = ctx.World.Plots[target.Data.PlotIndex]
	if not plot then
		return
	end
	local padPos = plot.Pads[target.PadIndex]
	local thief = ctx.Factory.CreateThief()
	thief.Name = "ThiefNPC"
	thief.Parent = workspace
	local startPos = Vector3.new(0, 0, 44)
	thief:PivotTo(CFrame.new(startPos.X, ctx.Factory.ROOT_LIFT, startPos.Z))
	ctx.Factory.SetLabel(thief, "PENCURI!", "jangan sampai lolos", Color3.fromRGB(255, 90, 90))
	ctx.ToastAll("Pencuri datang! Kunci basemu!")
	ctx.MoveService.Add(thief, {
		Path = { Vector3.new(padPos.X, 0, padPos.Z) },
		Speed = Thief.SPEED,
		PivotY = ctx.Factory.ROOT_LIFT,
		Tag = "thief",
		OnArrive = function()
			-- The base may have locked (or the pad emptied) on the way.
			local data = target.Data
			local stillThere = data.Pads[target.PadIndex] == target.Entry
			if stillThere and not ctx.GameState.IsLocked(data) then
				local def = ctx.BrainrotData.GetById(target.Entry.DefId)
				ctx.GameState.RemoveFromPad(data, target.PadIndex)
				if def then
					ctx.ToastPlayer(target.Player, "Pencuri membawa lari " .. def.Name .. "!")
				else
					ctx.ToastPlayer(target.Player, "Pencuri membawa lari brainrot-mu!")
				end
				ctx.SyncPlayer(target.Player)
			else
				ctx.ToastPlayer(target.Player, "Pencuri gagal — basemu aman!")
			end
			-- Jog off to the map corner and vanish.
			ctx.MoveService.Add(thief, {
				Path = { Vector3.new(-176, 0, -138) },
				Speed = Thief.SPEED + 2,
				PivotY = ctx.Factory.ROOT_LIFT,
				Tag = "thief",
				OnArrive = function()
					thief:Destroy()
				end,
				OnCancel = function()
					thief:Destroy()
				end,
			})
		end,
		OnCancel = function()
			thief:Destroy()
		end,
	})
end

function Thief.Start(ctx)
	task.spawn(function()
		local rng = Random.new()
		while true do
			task.wait(rng:NextNumber(Thief.MIN_WAIT, Thief.MAX_WAIT))
			local ok, err = pcall(runOnce, ctx)
			if not ok then
				warn("Thief failed: " .. tostring(err))
			end
		end
	end)
end

-- Run one theft immediately (used by tests and admin tooling); the
-- scheduled loop in Start is the normal driver.
function Thief.RunOnce(ctx)
	local ok, err = pcall(runOnce, ctx)
	if not ok then
		warn("Thief.RunOnce failed: " .. tostring(err))
	end
	return ok
end

-- Who would the thief rob right now? Nil when every base is locked
-- or empty.
function Thief.NextTarget(ctx)
	return pickTarget(ctx)
end

return Thief
