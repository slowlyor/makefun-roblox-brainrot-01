-- GachaService.luau
-- The plaza gacha machine: pay the escalating roll price, spin the
-- weighted rarity table, and the prize brainrot WALKS from the machine
-- to a free pad in your base like it means it. If the base is full the
-- roll is refunded in full -- the machine never eats money for nothing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local GameState = require(script.Parent.GameState)
local MoveService = require(script.Parent.MoveService)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local WorldBuilder = require(script.Parent.WorldBuilder)

local GachaService = {}

GachaService.WALK_SPEED = 10

-- Perform one roll for a player. `deps` supplies the plot refs, the
-- walkers folder, the workspace root (for sparkles) and callbacks to
-- toast the player and push their fresh state.
-- Returns true when a prize was won and sent walking home.
function GachaService.roll(player: Player, deps): boolean
	local state = GameState.get(player)
	if not state or state.plotIndex == 0 then
		deps.toast(player, "Kamu belum punya base!")
		return false
	end
	local padIndex = GameState.freePad(state)
	if not padIndex then
		deps.toast(player, "Base penuh! Gacha dibatalkan, uang kembali.")
		return false
	end
	local cost = GameState.gachaCost(state)
	if state.cash < cost then
		deps.toast(player, "Uang kurang untuk gacha: perlu " .. BrainrotData.formatMoney(cost))
		return false
	end
	state.cash -= cost
	state.gachaRolls += 1

	local rng = deps.rng
	local def = BrainrotData.pickWeighted(rng, "gachaWeight")
	local mutation = BrainrotData.rollMutation(rng:NextNumber())
	state.everOwned[def.id] = true

	-- Reserve the pad immediately so a belt purchase in the same second
	-- cannot race the prize for the same spot.
	state.pads[padIndex] = { defId = def.id, mutation = mutation, model = nil, stored = 0 }

	local model = BrainrotFactory.create(def, mutation)
	model.Parent = deps.walkersFolder
	local machinePos = deps.gachaBase.Position
	MoveService.placeOn(model, machinePos.X + 4, machinePos.Z, 0, 1, 0)

	if def.rarity == "Divine" or mutation == "Rainbow" then
		local burst = WorldBuilder.sparkleBurst(deps.root, model:GetPivot().Position)
		task.delay(1.2, function()
			burst:Destroy()
		end)
	end

	local plot = deps.plots[state.plotIndex]
	local padPos = plot.PadPositions[padIndex]
	deps.toast(player, "Gacha: " .. (mutation and (mutation .. " ") or "") .. def.name .. " jalan ke base-mu!")
	MoveService.walk(model, { Vector3.new(padPos.X, 0, padPos.Z) }, GachaService.WALK_SPEED, 0, function()
		local current = GameState.get(player)
		if current and current.pads[padIndex] and current.pads[padIndex].defId == def.id then
			current.pads[padIndex].model = model
			MoveService.placeOn(model, padPos.X, padPos.Z, deps.padTop, 0, plot.Center.Z > 0 and -1 or 1)
		else
			model:Destroy() -- the pad was reset (rebirth) mid-walk
		end
		deps.pushState(player)
	end)
	deps.pushState(player)
	return true
end

-- Hang the interact prompt on the machine. Prompt activation is routed
-- through the same roll() the HUD gacha button uses, so both entry
-- points can never drift apart.
function GachaService.attachPrompt(deps)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GachaPrompt"
	prompt.ActionText = "Putar Gacha"
	prompt.ObjectText = "Gacha Brainrot"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 12
	prompt.Parent = deps.gachaBase
	prompt.Triggered:Connect(function(player)
		GachaService.roll(player, deps)
	end)
	return prompt
end

-- The next roll's price for a player, for prompt/HUD readouts; nil when
-- the player has no state yet.
function GachaService.nextCost(player: Player): number?
	local state = GameState.get(player)
	if not state then
		return nil
	end
	return GameState.gachaCost(state)
end

return GachaService
