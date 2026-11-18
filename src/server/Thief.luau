-- Thief.luau
-- The wandering NPC thief ("Maling"). Every so often he creeps in from the
-- edge of the map, makes for the richest brainrot in an UNLOCKED base, grabs
-- it and runs off with it on his head. Locking your base keeps him out.

local GameState = require(script.Parent:WaitForChild("GameState"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))
local MoveService = require(script.Parent:WaitForChild("MoveService"))

local Thief = {}

-- Walk a model to a fixed point and wait until it gets there (or vanishes).
local function walkTo(model: Model, target: Vector3, speed: number): boolean
	local arrived = false
	MoveService.Add(model, function()
		return target
	end, speed, function()
		arrived = true
	end)
	while not arrived and model.Parent do
		task.wait(0.1)
	end
	return arrived and model.Parent ~= nil
end

local function richestBrainrot(plot): (any, number)
	local best, bestValue = nil, -1
	for padIndex, record in pairs(plot.PadOccupants) do
		if record and record.State == "Home" then
			local value = record.Def.Cost * record.MutationMultiplier
			if value > bestValue then
				best, bestValue = record, value
			end
		end
	end
	return best, bestValue
end

local function pickTargetPlot()
	local candidates = {}
	for _, plot in ipairs(GameState.Plots) do
		if plot.Owner and not plot.Locked then
			local record = richestBrainrot(plot)
			if record then
				table.insert(candidates, plot)
			end
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[GameState.Rng:NextInteger(1, #candidates)]
end

local function runHeist(liveFolder: Folder)
	local plot = pickTargetPlot()
	if not plot then
		return
	end
	local record = richestBrainrot(plot)
	if not record then
		return
	end

	local thief = BrainrotFactory.CreateThief()
	thief.Parent = liveFolder
	local edgeX = GameState.Rng:NextInteger(0, 1) == 0 and -215 or 215
	local startPos = Vector3.new(edgeX, 0, GameState.Rng:NextNumber(-30, 30))
	thief:PivotTo(CFrame.new(startPos + Vector3.new(0, 1.4, 0)))

	local ownerData = plot.Owner
	GameState.Notify(nil, "Ada MALING mengintai basis yang tidak dikunci!", "danger")

	-- Creep to the victim's pad.
	local padPos = plot.PadPositions[record.PadIndex]
	if not walkTo(thief, padPos, GameState.THIEF_SPEED) then
		thief:Destroy()
		return
	end

	-- The base may have been locked or emptied while he was walking.
	if plot.Locked or record.State ~= "Home" or not record.Model.Parent then
		walkTo(thief, startPos, GameState.THIEF_SPEED)
		thief:Destroy()
		return
	end

	-- Grab it: detach from the owner, ride on the thief's head.
	local model = record.Model
	plot.PadOccupants[record.PadIndex] = nil
	if ownerData then
		local idx = table.find(ownerData.Brainrots, record)
		if idx then
			table.remove(ownerData.Brainrots, idx)
		end
		GameState.Notify(ownerData.Player, "Maling mencuri " .. record.Def.Name .. " dari basismu!", "danger")
	end
	record.State = "Stolen"
	record.Owner = nil
	record.Plot = nil
	BrainrotFactory.SetInfo(model, "DICURI!")

	MoveService.Add(model, function()
		return MoveService.FeetPosition(thief) + Vector3.new(0, 6.4, 0)
	end, 60, nil)

	-- Run for the edge and vanish with the loot.
	walkTo(thief, startPos, GameState.THIEF_SPEED + 2)
	MoveService.Remove(model)
	GameState.Brainrots[model] = nil
	model:Destroy()
	thief:Destroy()
end

function Thief.Start(liveFolder: Folder)
	task.spawn(function()
		while true do
			task.wait(GameState.Rng:NextNumber(GameState.THIEF_MIN_DELAY, GameState.THIEF_MAX_DELAY))
			local ok, err = pcall(runHeist, liveFolder)
			if not ok then
				warn("Thief heist failed: " .. tostring(err))
			end
		end
	end)
end

return Thief
