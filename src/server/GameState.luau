-- GameState.luau
-- Central server-side state for Brainrot Bazaar: tuning constants, the player
-- table, the plot table (filled by WorldBuilder) and the live brainrot
-- registry. Kept as one module so every server system reads the same truth
-- without circular requires.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = {}

-- Tuning ---------------------------------------------------------------------

GameState.STARTING_CASH = 100
GameState.PLOT_COUNT = 8
GameState.PADS_PER_PLOT = 6

GameState.SHOP_SPAWN_INTERVAL = 3.5 -- seconds between conveyor spawns
GameState.SHOP_MAX_WALKERS = 8 -- unsold brainrots allowed on the belt at once
GameState.SHOP_WALK_SPEED = 4.5 -- studs per second along the conveyor
GameState.WALK_HOME_SPEED = 9 -- bought brainrots hurry home faster

GameState.WAVE_INTERVAL = 180 -- seconds between tsunamis
GameState.WAVE_WARNING = 10 -- countdown seconds before the wave hits
GameState.WAVE_SWEEP_TIME = 13 -- seconds the wall takes to cross the map
GameState.WAVE_MIN_X = -235
GameState.WAVE_MAX_X = 235

GameState.LOCK_DURATION = 60 -- seconds a base stays locked

GameState.THIEF_MIN_DELAY = 70 -- thief visit window, seconds
GameState.THIEF_MAX_DELAY = 120
GameState.THIEF_SPEED = 11

-- Rebirth: cost grows x3 per rebirth; each rebirth adds +0.75x income.
function GameState.RebirthCost(rebirths: number): number
	return math.floor(10000 * (3 ^ rebirths))
end

function GameState.IncomeMultiplier(rebirths: number): number
	return 1 + 0.75 * rebirths
end

-- Live state -----------------------------------------------------------------

-- userId -> { Player, Cash, StoredCash, Rebirths, Plot, Brainrots = {record} }
GameState.Players = {}

-- Filled by WorldBuilder.Build(): array of plot records.
GameState.Plots = {}

-- Model -> brainrot record { Model, Def, MutationName, MutationMultiplier,
-- Price, Income, Owner, State, Plot, PadIndex }
GameState.Brainrots = {}

GameState.Rng = Random.new()

-- Live tsunami countdown, mirrored by the wave loop every second so the
-- per-second stats tick can push it to each player on the same cadence.
GameState.WaveSecondsLeft = GameState.WAVE_INTERVAL
GameState.WavePhase = "Calm"

-- Remotes --------------------------------------------------------------------
-- Created once by the server bootstrap; the client waits for this folder.

GameState.Remotes = nil

function GameState.CreateRemotes()
	if GameState.Remotes then
		return GameState.Remotes
	end
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotRemotes"
	for _, name in ipairs({ "StatsUpdate", "WaveUpdate", "Notify", "RebirthRequest" }) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
	GameState.Remotes = folder
	return folder
end

function GameState.Remote(name: string): RemoteEvent
	return GameState.Remotes:WaitForChild(name)
end

-- Push a short toast message to one player (or everyone when player is nil).
function GameState.Notify(player: Player?, text: string, kind: string?)
	local remote = GameState.Remote("Notify")
	if player then
		remote:FireClient(player, text, kind or "info")
	else
		remote:FireAllClients(text, kind or "info")
	end
end

return GameState
