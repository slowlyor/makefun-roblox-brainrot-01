-- Thief.luau -- the Pencuri Brainrot: an NPC who periodically sneaks
-- into the richest UNLOCKED base, grabs its most valuable brainrot and
-- runs off the map with it. Locked bases (and empty bases) are safe.
-- init.server.luau schedules the raids; this module runs one raid.

local Thief = {}

Thief.RAID_INTERVAL = 75 -- seconds between raids
Thief.SPEED = 13 -- the thief runs faster than brainrots walk

-- Find the best victim: the unlocked player whose richest pad brainrot
-- is worth the most. Returns (state, padIndex) or nil.
function Thief.FindVictim(GameState)
	local bestState, bestPad, bestValue = nil, nil, -1
	for _, state in pairs(GameState.Players) do
		if not GameState.IsLocked(state) then
			local padIndex, value = GameState.RichestPad(state)
			if padIndex and value > bestValue then
				bestState, bestPad, bestValue = state, padIndex, value
			end
		end
	end
	return bestState, bestPad, bestValue
end

-- Run one raid. deps carries the shared modules and world refs so this
-- module stays free of circular requires.
-- deps: { GameState, BrainrotFactory, MoveService, Refs, ToastAll, ToastPlayer }
function Thief.RunRaid(deps)
	local GameState = deps.GameState
	local victim, padIndex = Thief.FindVictim(GameState)
	if not victim then
		return false
	end
	local pad = victim.Pads[padIndex]
	if not pad or not pad.Model then
		return false
	end

	local plot = deps.Refs.Plots[victim.PlotIndex]
	local padPos = plot.PadPositions[padIndex]
	local spawnAt = Vector3.new(padPos.X, 0, padPos.Z + plot.FrontDir * 26)

	deps.ToastAll("PENCURI DATANG! Dia mengincar basis yang tidak dikunci!")
	local thief = deps.BrainrotFactory.CreateThief(spawnAt)
	thief.Parent = deps.Refs.World

	local stolenModel = pad.Model
	-- If the victim locks the base mid-raid the thief gives up at the
	-- shield; the check happens when he reaches the pad, below.
	deps.MoveService.WalkTo(thief, padPos.X, padPos.Z, deps.MoveService.GROUND_Y, Thief.SPEED, function()
		if GameState.IsLocked(victim) or victim.Pads[padIndex] == nil then
			deps.ToastPlayer(victim.Player, "Pencuri kabur! Basismu terkunci tepat waktu.")
			deps.MoveService.WalkTo(thief, spawnAt.X, spawnAt.Z, deps.MoveService.GROUND_Y, Thief.SPEED + 1, function()
				thief:Destroy()
			end)
			return
		end
		-- Grab: the pad empties, the brainrot follows the thief out.
		GameState.RemoveFromPad(victim, padIndex)
		deps.ToastPlayer(victim.Player, "Brainrot terbesarmu DICURI pencuri! Kunci basismu!")
		local exitX = padPos.X
		local exitZ = padPos.Z + plot.FrontDir * 40
		deps.MoveService.WalkTo(stolenModel, exitX, exitZ, deps.MoveService.GROUND_Y, Thief.SPEED, function()
			stolenModel:Destroy()
		end)
		deps.MoveService.WalkTo(thief, exitX, exitZ, deps.MoveService.GROUND_Y, Thief.SPEED + 1, function()
			thief:Destroy()
		end)
	end)
	return true
end

return Thief
