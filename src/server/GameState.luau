-- GameState: in-memory player data only (nothing is saved between sessions).
-- Cash is spendable money; Stored is unclaimed income on the base's collect pad.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = {}

GameState.START_CASH = 150
GameState.REBIRTH_BASE_COST = 10000
GameState.REBIRTH_COST_MULT = 3
GameState.REBIRTH_BONUS = 0.75 -- +0.75x income multiplier per rebirth

local players = {} -- [Player] = data

local function newData()
	return {
		cash = GameState.START_CASH,
		stored = 0,
		rebirths = 0,
		rolls = 0,
		plotIndex = 0,
		lockedUntil = 0,
		owned = {}, -- [charId] = true, for the Collection Index
		pads = {}, -- [padIndex] = brainrot Model (or nil)
	}
end

function GameState.get(player)
	return players[player]
end

function GameState.addPlayer(player)
	local data = newData()
	players[player] = data
	return data
end

function GameState.removePlayer(player)
	players[player] = nil
end

function GameState.allPlayers()
	return players
end

function GameState.multiplier(data)
	return 1 + GameState.REBIRTH_BONUS * data.rebirths
end

function GameState.rebirthCost(data)
	return GameState.REBIRTH_BASE_COST * (GameState.REBIRTH_COST_MULT ^ data.rebirths)
end

function GameState.gachaCost(data)
	return 500 * (data.rolls + 1)
end

function GameState.incomePerSecond(data)
	local total = 0
	for _, model in pairs(data.pads) do
		if model and model.Parent then
			total = total + (model:GetAttribute("Income") or 0)
		end
	end
	return math.floor(total * GameState.multiplier(data) + 0.5)
end

function GameState.freePadIndex(data)
	for i = 1, 6 do
		if data.pads[i] == nil then
			return i
		end
	end
	return nil
end

function GameState.ownedCount(data)
	local n = 0
	for _ in pairs(data.owned) do
		n = n + 1
	end
	return n
end

-- The owned character ids, as a plain array the client can read.
local function ownedIds(data)
	local out = {}
	for id in pairs(data.owned) do
		table.insert(out, id)
	end
	return out
end

-- RemoteEvents, created once by init and shared by the server modules.
function GameState.createRemotes()
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
	local names = {
		"BuyBrainrot", "CollectCash", "ToggleLock", "Rebirth", "GachaRoll",
		"StateUpdate", "Toast", "TsunamiWarning",
	}
	local out = {}
	for _, name in ipairs(names) do
		local ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = remotes
		out[name] = ev
	end
	return out
end

-- Push a HUD snapshot to one player.
function GameState.pushState(remotes, player)
	local data = players[player]
	if not data then
		return
	end
	remotes.StateUpdate:FireClient(player, {
		cash = data.cash,
		stored = data.stored,
		income = GameState.incomePerSecond(data),
		rebirths = data.rebirths,
		multiplier = GameState.multiplier(data),
		rebirthCost = GameState.rebirthCost(data),
		gachaCost = GameState.gachaCost(data),
		locked = os.time() < data.lockedUntil,
		ownedCount = GameState.ownedCount(data),
		plotIndex = data.plotIndex,
		ownedIds = ownedIds(data),
	})
end

function GameState.toast(remotes, player, text)
	remotes.Toast:FireClient(player, text)
end

function GameState.toastAll(remotes, text)
	remotes.Toast:FireAllClients(text)
end

return GameState
