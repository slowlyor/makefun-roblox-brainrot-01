-- GameState.luau
-- Central in-memory state for Brainrot Bazaar. Nothing is persisted: when a
-- player leaves, their cash, brainrots and plot claim are released. All other
-- server modules read and mutate state through the tables exposed here.

local GameState = {}

-- Tuning constants for the whole game loop.
GameState.Constants = {
	StartCash = 100,
	SpawnInterval = 3.5, -- seconds between shop spawns
	BeltLength = 140, -- conveyor length along X
	BeltSpeed = 7, -- studs per second a rider travels
	BeltTopY = 1.3, -- height of the belt surface
	WalkSpeed = 10, -- studs per second for bought brainrots walking home
	LockDuration = 60, -- seconds a base stays locked
	TsunamiPeriod = 180, -- seconds between waves
	TsunamiWarning = 10, -- seconds of warning before the wave hits
	ThiefMinDelay = 70, -- thief visits somewhere in this window
	ThiefMaxDelay = 120,
	ThiefSpeed = 12,
	PadsPerPlot = 6,
	RebirthBaseCost = 10000, -- cost = base * 3 ^ rebirths
	RebirthCostGrowth = 3,
	RebirthBonusPer = 0.75, -- multiplier = 1 + bonus * rebirths
}

-- Per-player record, created on join:
--   Cash (spendable), Rebirths, Plot (plot record or nil),
--   Brainrots: array of { Model, Def, Mutation, Income, PadIndex }
GameState.Players = {}

-- Plot records are created by WorldBuilder and registered here. A plot is:
--   { Index, Folder, Floor, Pads = {BasePart...}, CollectPad, LockButton,
--     Sign, Barriers = {Part...}, Owner = playerState or nil,
--     Stored = cash waiting on the collect pad, LockedUntil = os.clock() end }
GameState.Plots = {}

-- Live transient brainrots: belt riders and walkers heading to a base.
-- Each entry: { Model, Kind = "belt" | "walker", Def, Mutation, Price, Income }
GameState.Transients = {}

-- Seconds until the next tsunami; the server bootstrap owns the countdown
-- and mirrors it here so the HUD payload and the wave logic agree.
GameState.TsunamiCountdown = GameState.Constants.TsunamiPeriod
GameState.TsunamiActive = false

function GameState.NewPlayerState(player)
	local state = {
		Player = player,
		Cash = GameState.Constants.StartCash,
		Rebirths = 0,
		Plot = nil,
		Brainrots = {},
	}
	GameState.Players[player] = state
	return state
end

function GameState.GetPlayerState(player)
	return GameState.Players[player]
end

function GameState.RemovePlayerState(player)
	GameState.Players[player] = nil
end

-- Income multiplier from rebirths: 1 + 0.75 per rebirth.
function GameState.MultiplierFor(rebirths)
	return 1 + GameState.Constants.RebirthBonusPer * rebirths
end

-- Cash needed for the next rebirth: 10000 * 3 ^ current rebirths.
function GameState.RebirthCostFor(rebirths)
	return GameState.Constants.RebirthBaseCost * (GameState.Constants.RebirthCostGrowth ^ rebirths)
end

-- Total income per second a player's placed brainrots produce, before the
-- rebirth multiplier is applied.
function GameState.RawIncomePerSecond(state)
	local total = 0
	for _, entry in ipairs(state.Brainrots) do
		total += entry.Income
	end
	return total
end

function GameState.IncomePerSecond(state)
	return GameState.RawIncomePerSecond(state) * GameState.MultiplierFor(state.Rebirths)
end

-- First unclaimed plot, or nil when the server is full.
function GameState.ClaimFreePlot(state)
	for _, plot in ipairs(GameState.Plots) do
		if plot.Owner == nil then
			plot.Owner = state
			plot.Stored = 0
			plot.LockedUntil = 0
			state.Plot = plot
			return plot
		end
	end
	return nil
end

-- First pad index (1..PadsPerPlot) not occupied by one of the owner's
-- brainrots, or nil when the base is full.
function GameState.FirstFreePadIndex(state)
	local used = {}
	for _, entry in ipairs(state.Brainrots) do
		if entry.PadIndex then
			used[entry.PadIndex] = true
		end
	end
	for i = 1, GameState.Constants.PadsPerPlot do
		if not used[i] then
			return i
		end
	end
	return nil
end

-- How many brainrots currently sit on pads across every base? Handy for
-- diagnostics and for the thief's target scan.
function GameState.PlacedBrainrotCount()
	local total = 0
	for _, state in pairs(GameState.Players) do
		total += #state.Brainrots
	end
	return total
end

-- Is this plot's lock currently holding?
function GameState.IsLocked(plot)
	return plot.LockedUntil ~= nil and os.clock() < plot.LockedUntil
end

return GameState
