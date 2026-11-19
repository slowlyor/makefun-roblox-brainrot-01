-- GameState.luau
-- Brainrot Bazaar: the single home of all per-player state.
-- Cash, pads, stored income, rebirths, locks and the collection set
-- live here and nowhere else; services read and mutate through these
-- functions so the rules (multiplier, costs) are written exactly once.
-- Everything is in memory only: no DataStore, by design.

local GameState = {}

GameState.START_CASH = 100
GameState.PADS_PER_BASE = 6
GameState.LOCK_SECONDS = 60
GameState.REBIRTH_BONUS = 0.75

-- [Player] -> data table
GameState.Players = {}

function GameState.Now()
	return workspace:GetServerTimeNow()
end

function GameState.CreatePlayer(player, plotIndex)
	local data = {
		Player = player,
		PlotIndex = plotIndex,
		Cash = GameState.START_CASH,
		Rebirths = 0,
		Pads = {}, -- [padIndex] -> entry { DefId, Mutation, Price, Income, Stored }
		PadModels = {}, -- [padIndex] -> Model standing on the pad
		Collection = {}, -- [defId] -> true once ever owned
		GachaRolls = 0,
		LockUntil = 0,
		TotalEarned = 0,
		TotalBuys = 0,
	}
	GameState.Players[player] = data
	return data
end

function GameState.Get(player)
	return GameState.Players[player]
end

function GameState.RemovePlayer(player)
	GameState.Players[player] = nil
end

function GameState.Multiplier(data)
	return 1 + GameState.REBIRTH_BONUS * data.Rebirths
end

function GameState.RebirthCost(data)
	return 10000 * (3 ^ data.Rebirths)
end

-- Gacha price climbs with every roll the player has ever paid for.
function GameState.GachaCost(data)
	return math.floor(750 * (1.8 ^ data.GachaRolls) + 0.5)
end

function GameState.IsLocked(data)
	return GameState.Now() < data.LockUntil
end

function GameState.LockSecondsLeft(data)
	return math.max(0, math.ceil(data.LockUntil - GameState.Now()))
end

function GameState.FreePad(data)
	for i = 1, GameState.PADS_PER_BASE do
		if data.Pads[i] == nil then
			return i
		end
	end
	return nil
end

function GameState.OccupiedCount(data)
	local n = 0
	for i = 1, GameState.PADS_PER_BASE do
		if data.Pads[i] ~= nil then
			n += 1
		end
	end
	return n
end

-- Place an entry on a pad and remember the character as collected.
function GameState.PlaceBrainrot(data, padIndex, entry)
	entry.Stored = 0
	data.Pads[padIndex] = entry
	data.Collection[entry.DefId] = true
	return entry
end

function GameState.RemoveFromPad(data, padIndex)
	local entry = data.Pads[padIndex]
	data.Pads[padIndex] = nil
	local model = data.PadModels[padIndex]
	data.PadModels[padIndex] = nil
	if model then
		model:Destroy()
	end
	return entry
end

function GameState.IncomePerSecond(data)
	local sum = 0
	for i = 1, GameState.PADS_PER_BASE do
		local entry = data.Pads[i]
		if entry then
			sum += entry.Income
		end
	end
	return math.floor(sum * GameState.Multiplier(data) + 0.5)
end

function GameState.StoredTotal(data)
	local sum = 0
	for i = 1, GameState.PADS_PER_BASE do
		local entry = data.Pads[i]
		if entry then
			sum += entry.Stored
		end
	end
	return math.floor(sum)
end

-- One income tick: every pad brainrot banks its share of cash.
function GameState.TickIncome(data, dt)
	local mult = GameState.Multiplier(data)
	for i = 1, GameState.PADS_PER_BASE do
		local entry = data.Pads[i]
		if entry then
			entry.Stored += entry.Income * mult * dt
		end
	end
end

-- The green collect pad harvests every pad's stored cash at once.
function GameState.Collect(data)
	local amount = GameState.StoredTotal(data)
	if amount <= 0 then
		return 0
	end
	for i = 1, GameState.PADS_PER_BASE do
		local entry = data.Pads[i]
		if entry then
			entry.Stored = 0
		end
	end
	data.Cash += amount
	data.TotalEarned += amount
	return amount
end

-- The richest single brainrot a player owns (the thief's target).
function GameState.RichestPad(data)
	local bestIndex = nil
	local bestValue = -1
	for i = 1, GameState.PADS_PER_BASE do
		local entry = data.Pads[i]
		if entry and entry.Price > bestValue then
			bestValue = entry.Price
			bestIndex = i
		end
	end
	return bestIndex
end

function GameState.CollectionList(data)
	local list = {}
	for defId in pairs(data.Collection) do
		table.insert(list, defId)
	end
	table.sort(list)
	return list
end

function GameState.CollectionCount(data)
	local n = 0
	for _ in pairs(data.Collection) do
		n += 1
	end
	return n
end

-- Rebirth: wipe cash and brainrots, keep the collection book and the
-- permanent multiplier that Rebirths already encodes.
function GameState.DoRebirth(data)
	for i = 1, GameState.PADS_PER_BASE do
		GameState.RemoveFromPad(data, i)
	end
	data.Rebirths += 1
	data.Cash = GameState.START_CASH
	data.LockUntil = 0
	return data.Rebirths
end

-- Spend cash if the player can afford it; returns whether it spent.
function GameState.TrySpend(data, amount)
	if data.Cash < amount then
		return false
	end
	data.Cash -= amount
	return true
end

-- A plain-data snapshot of the pads for debugging and state sync.
function GameState.PadSnapshot(data)
	local snap = {}
	for i = 1, GameState.PADS_PER_BASE do
		local entry = data.Pads[i]
		if entry then
			snap[i] = { DefId = entry.DefId, Mutation = entry.Mutation, Income = entry.Income, Stored = math.floor(entry.Stored) }
		end
	end
	return snap
end

return GameState
