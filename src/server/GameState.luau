-- GameState.luau
-- All mutable game state lives here, in memory only (no DataStore): player
-- wallets, base ownership, pad occupants, locks, rebirths and collections.
-- Every other server module reads and writes state through this module so
-- there is exactly one place where the rules of money are enforced.

local GameState = {}

GameState.START_CASH = 100
GameState.PADS_PER_BASE = 6
GameState.BASE_COUNT = 8
GameState.LOCK_SECONDS = 60
GameState.REBIRTH_BASE_COST = 10000
GameState.REBIRTH_COST_GROWTH = 3
GameState.REBIRTH_BONUS = 0.75

-- World layout constants shared by the builder and the game logic.
-- The plaza sits at the origin; the belt runs along +X in front of the shop;
-- eight bases ring the plaza in two rows of four.
GameState.PLAZA_CENTER = Vector3.new(0, 0, 0)
GameState.BELT_Y = 3
GameState.BELT_START = Vector3.new(-70, GameState.BELT_Y, 42)
GameState.BELT_END = Vector3.new(70, GameState.BELT_Y, 42)
GameState.BASE_SIZE = Vector3.new(34, 1, 30)

local baseOrigins = {}
for i = 1, GameState.BASE_COUNT do
	local col = (i - 1) % 4
	local row = math.floor((i - 1) / 4)
	local x = -66 + col * 44
	local z = row == 0 and -52 or 96
	baseOrigins[i] = Vector3.new(x, 0, z)
end

function GameState.GetBaseOrigin(baseIndex)
	return baseOrigins[baseIndex]
end

-- Pad spots inside a base, in local offsets from the base origin: two
-- columns of three, leaving the middle lane free to walk.
function GameState.GetPadPosition(baseIndex, padIndex)
	local origin = baseOrigins[baseIndex]
	local col = (padIndex - 1) % 2
	local row = math.floor((padIndex - 1) / 2)
	local dx = col == 0 and -9 or 9
	local dz = -9 + row * 9
	return origin + Vector3.new(dx, 1, dz)
end

function GameState.GetCollectPadPosition(baseIndex)
	return baseOrigins[baseIndex] + Vector3.new(0, 1, 11)
end

function GameState.GetLockButtonPosition(baseIndex)
	return baseOrigins[baseIndex] + Vector3.new(13, 1, 11)
end

-- Is a world position inside this base's floor rectangle (with a margin)?
function GameState.IsInsideBase(position, baseIndex)
	local origin = baseOrigins[baseIndex]
	return math.abs(position.X - origin.X) <= GameState.BASE_SIZE.X / 2 + 1
		and math.abs(position.Z - origin.Z) <= GameState.BASE_SIZE.Z / 2 + 1
end

function GameState.IsInsideAnyBase(position)
	for i = 1, GameState.BASE_COUNT do
		if GameState.IsInsideBase(position, i) then
			return true
		end
	end
	return false
end

-- Per-player record factory. Pads hold nil or a table:
-- { Entry = brainrot entry, Mutation = mutation table or nil,
--   Income = final income per second, Model = the placed Model }
local function newPlayerRecord(player, baseIndex)
	local pads = {}
	for i = 1, GameState.PADS_PER_BASE do
		pads[i] = nil
	end
	return {
		Player = player,
		BaseIndex = baseIndex,
		Cash = GameState.START_CASH,
		Stored = 0,
		Rebirths = 0,
		GachaRolls = 0,
		LockedUntil = 0,
		Pads = pads,
		Collection = {},
	}
end

GameState.Players = {}
GameState.BaseOwners = {}

function GameState.ClaimBase(player)
	for i = 1, GameState.BASE_COUNT do
		if GameState.BaseOwners[i] == nil then
			GameState.BaseOwners[i] = player
			local record = newPlayerRecord(player, i)
			GameState.Players[player] = record
			return record
		end
	end
	return nil
end

function GameState.ReleasePlayer(player)
	local record = GameState.Players[player]
	if record then
		GameState.BaseOwners[record.BaseIndex] = nil
		GameState.Players[player] = nil
	end
end

function GameState.Get(player)
	return GameState.Players[player]
end

function GameState.Multiplier(record)
	return 1 + GameState.REBIRTH_BONUS * record.Rebirths
end

function GameState.RebirthCost(record)
	return GameState.REBIRTH_BASE_COST * (GameState.REBIRTH_COST_GROWTH ^ record.Rebirths)
end

-- Income per second summed over the pads, before the rebirth multiplier.
function GameState.PadIncome(record)
	local total = 0
	for _, pad in ipairs(record.Pads) do
		if pad then
			total += pad.Income
		end
	end
	return total
end

function GameState.IncomePerSecond(record)
	return GameState.PadIncome(record) * GameState.Multiplier(record)
end

function GameState.FindFreePad(record)
	for i, pad in ipairs(record.Pads) do
		if pad == nil then
			return i
		end
	end
	return nil
end

function GameState.IsLocked(record)
	return os.clock() < record.LockedUntil
end

function GameState.LockBase(record)
	record.LockedUntil = os.clock() + GameState.LOCK_SECONDS
end

-- Place a brainrot on a pad and remember the collection entry. The model is
-- attached by the caller once it has walked home.
function GameState.PlaceOnPad(record, padIndex, entry, mutation, income)
	record.Pads[padIndex] = {
		Entry = entry,
		Mutation = mutation,
		Income = income,
		Model = nil,
	}
	record.Collection[entry.Id] = true
	local player = record.Player
	if player then
		player:SetAttribute("Owned_" .. entry.Id, true)
	end
end

function GameState.ClearPad(record, padIndex)
	record.Pads[padIndex] = nil
end

-- The richest placed brainrot across every unlocked base, for the thief.
function GameState.FindRichestStolenCandidate()
	local best = nil
	for _, record in pairs(GameState.Players) do
		if not GameState.IsLocked(record) then
			for padIndex, pad in ipairs(record.Pads) do
				if pad and (best == nil or pad.Income > best.Pad.Income) then
					best = { Record = record, PadIndex = padIndex, Pad = pad }
				end
			end
		end
	end
	return best
end

-- Rebirth: wipe cash and pads, keep the collection, gain the multiplier.
-- Returns true when the player could afford it.
function GameState.TryRebirth(record)
	local cost = GameState.RebirthCost(record)
	if record.Cash + record.Stored < cost then
		return false
	end
	record.Cash = 0
	record.Stored = 0
	for i = 1, GameState.PADS_PER_BASE do
		local pad = record.Pads[i]
		if pad and pad.Model then
			pad.Model:Destroy()
		end
		record.Pads[i] = nil
	end
	record.Rebirths += 1
	return true
end

-- How many distinct brainrots this player has ever owned (index progress).
function GameState.CollectionCount(record)
	local count = 0
	for _ in pairs(record.Collection) do
		count += 1
	end
	return count
end

-- Occupied pad count, for "base full" checks and HUD flavour.
function GameState.OccupiedPads(record)
	local count = 0
	for _, pad in ipairs(record.Pads) do
		if pad then
			count += 1
		end
	end
	return count
end

return GameState
