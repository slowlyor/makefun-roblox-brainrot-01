-- GachaService.luau -- the plaza gacha machine. Each roll costs more
-- than the last; the prize is a weighted-rarity brainrot that walks
-- from the machine to a free pad in the winner's base. If the base is
-- full the roll is refunded in full and nothing is charged.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local GachaService = {}

GachaService.BASE_COST = 500
GachaService.COST_GROWTH = 1.6 -- each roll costs 1.6x the previous one

function GachaService.NextCost(state)
	return math.floor(GachaService.BASE_COST * (GachaService.COST_GROWTH ^ state.GachaRolls))
end

-- Attempt one roll for a player. deps: { GameState, BrainrotFactory,
-- MoveService, Refs, Rng, ToastPlayer, PlaceBrainrot } where
-- PlaceBrainrot(state, padIndex, model) settles a model onto its pad.
-- Returns true when a brainrot was won and sent walking home.
function GachaService.Roll(state, deps)
	local GameState = deps.GameState
	local cost = GachaService.NextCost(state)
	local padIndex = GameState.FreePad(state)
	if not padIndex then
		deps.ToastPlayer(state.Player, "Basis PENUH! Roll gacha dibatalkan, uang kembali.")
		return false
	end
	if state.Cash < cost then
		deps.ToastPlayer(state.Player, "Uang tidak cukup untuk gacha! Butuh " .. BrainrotData.FormatMoney(cost))
		return false
	end

	state.Cash -= cost
	state.GachaRolls += 1

	local defIndex = BrainrotData.RollCharacter(deps.Rng, BrainrotData.GachaWeights)
	local mutation = BrainrotData.RollMutation(deps.Rng)
	local machinePos = deps.Refs.GachaPos
	local model = deps.BrainrotFactory.Create(defIndex, mutation.Name,
		Vector3.new(machinePos.X, 0, machinePos.Z + 4))
	model.Parent = deps.Refs.World

	local c = BrainrotData.Get(defIndex)
	local mutationNote = ""
	if mutation.Name ~= "Normal" then
		mutationNote = " Mutasi " .. mutation.Name .. " x" .. tostring(mutation.Multiplier) .. "!"
	end
	deps.ToastPlayer(state.Player, string.format("GACHA: %s [%s] berjalan ke basismu!%s",
		c.Name, string.upper(c.Rarity), mutationNote))

	-- The prize walks home: plaza -> plot front -> its pad.
	local plot = deps.Refs.Plots[state.PlotIndex]
	local padPos = plot.PadPositions[padIndex]
	deps.MoveService.WalkPath(model, {
		{ X = padPos.X, Z = plot.Center.Z + plot.FrontDir * 20, BaseY = 0, Speed = 9 },
		{ X = padPos.X, Z = padPos.Z, BaseY = 0.45, Speed = 9 },
	}, function()
		deps.PlaceBrainrot(state, padIndex, model)
	end)
	return true
end

return GachaService
