-- GameState.luau -- the single home for all per-player state.
-- In-memory only (no DataStore): cash, pads, collection, locks, rebirths.
-- init.server.luau owns the loops; this module only holds and computes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local GameState = {}

GameState.START_CASH = 150
GameState.PADS_PER_BASE = 6
GameState.LOCK_SECONDS = 60
GameState.REBIRTH_BASE_COST = 10000
GameState.REBIRTH_BONUS = 0.75 -- +0.75x income multiplier per rebirth

GameState.Players = {} -- [userId] = state
GameState.PlotOwners = {} -- [plotIndex] = userId

function GameState.CreatePlayer(player, plotIndex)
	local state = {
		Player = player,
		UserId = player.UserId,
		PlotIndex = plotIndex,
		Cash = GameState.START_CASH,
		Rebirths = 0,
		Pads = {}, -- [padIndex] = { DefIndex, Mutation, Stored, Model }
		Collection = {}, -- [defIndex] = true, everything ever owned
		LockedUntil = 0,
		GachaRolls = 0,
	}
	GameState.Players[player.UserId] = state
	GameState.PlotOwners[plotIndex] = player.UserId
	return state
end

function GameState.RemovePlayer(player)
	local state = GameState.Players[player.UserId]
	if state then
		GameState.PlotOwners[state.PlotIndex] = nil
		GameState.Players[player.UserId] = nil
	end
	return state
end

function GameState.Get(player)
	return GameState.Players[player.UserId]
end

function GameState.Multiplier(state)
	return 1 + GameState.REBIRTH_BONUS * state.Rebirths
end

function GameState.RebirthCost(state)
	return GameState.REBIRTH_BASE_COST * (3 ^ state.Rebirths)
end

function GameState.FreePad(state)
	for i = 1, GameState.PADS_PER_BASE do
		if not state.Pads[i] then
			return i
		end
	end
	return nil
end

function GameState.OccupiedPads(state)
	local n = 0
	for _ in pairs(state.Pads) do
		n += 1
	end
	return n
end

-- Income per second across all pads, before the rebirth multiplier.
function GameState.BaseIncomePerSecond(state)
	local total = 0
	for _, pad in pairs(state.Pads) do
		total += BrainrotData.IncomeFor(pad.DefIndex, pad.Mutation)
	end
	return total
end

function GameState.IncomePerSecond(state)
	return GameState.BaseIncomePerSecond(state) * GameState.Multiplier(state)
end

function GameState.StoredTotal(state)
	local total = 0
	for _, pad in pairs(state.Pads) do
		total += pad.Stored
	end
	return total
end

-- The pad holding the single most valuable brainrot (by purchase price):
-- this is what the thief NPC comes for.
function GameState.RichestPad(state)
	local bestIndex, bestValue = nil, -1
	for i, pad in pairs(state.Pads) do
		local value = BrainrotData.PriceFor(pad.DefIndex, pad.Mutation)
		if value > bestValue then
			bestIndex, bestValue = i, value
		end
	end
	return bestIndex, bestValue
end

function GameState.IsLocked(state)
	return os.clock() < state.LockedUntil
end

function GameState.LockSecondsLeft(state)
	return math.max(0, math.ceil(state.LockedUntil - os.clock()))
end

-- Add one second of income to every pad's stored cash.
function GameState.TickIncome(state, dt)
	local mult = GameState.Multiplier(state)
	for _, pad in pairs(state.Pads) do
		pad.Stored += BrainrotData.IncomeFor(pad.DefIndex, pad.Mutation) * mult * dt
	end
end

-- Harvest every pad into cash; returns the amount collected.
function GameState.Collect(state)
	local amount = 0
	for _, pad in pairs(state.Pads) do
		amount += math.floor(pad.Stored)
		pad.Stored = 0
	end
	state.Cash += amount
	return amount
end

function GameState.PlaceOnPad(state, padIndex, defIndex, mutationName, model)
	state.Pads[padIndex] = {
		DefIndex = defIndex, Mutation = mutationName, Stored = 0, Model = model,
	}
	state.Collection[defIndex] = true
end

function GameState.RemoveFromPad(state, padIndex)
	local pad = state.Pads[padIndex]
	state.Pads[padIndex] = nil
	return pad
end

-- Reset for a rebirth: cash back to the starter amount, pads emptied.
-- The caller destroys the pad models; collection history is KEPT, since
-- the Buku Koleksi records everything a player has ever owned.
function GameState.ApplyRebirth(state)
	state.Rebirths += 1
	state.Cash = GameState.START_CASH
	state.Pads = {}
	state.LockedUntil = 0
end

-- The table the client HUD and collection index render from.
function GameState.Snapshot(state, tsunamiIn, thiefIn)
	local collection = {}
	for defIndex in pairs(state.Collection) do
		table.insert(collection, defIndex)
	end
	table.sort(collection)
	return {
		Cash = math.floor(state.Cash),
		IncomePerSecond = GameState.IncomePerSecond(state),
		Stored = math.floor(GameState.StoredTotal(state)),
		Rebirths = state.Rebirths,
		Multiplier = GameState.Multiplier(state),
		RebirthCost = GameState.RebirthCost(state),
		LockLeft = GameState.LockSecondsLeft(state),
		TsunamiIn = tsunamiIn,
		ThiefIn = thiefIn,
		Collection = collection,
		PadsUsed = GameState.OccupiedPads(state),
	}
end

return GameState
