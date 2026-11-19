-- Thief.luau
-- The threat that makes locks matter: every so often a thief NPC spawns
-- at the plaza, picks the richest brainrot sitting in an UNLOCKED base,
-- walks over, grabs it and runs off with it. Locked bases are skipped
-- entirely -- if every stocked base is locked, the thief shrugs and
-- leaves, which is exactly the counter-play the lock button exists for.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local GameState = require(script.Parent.GameState)
local MoveService = require(script.Parent.MoveService)

local Thief = {}

Thief.INTERVAL_MIN = 40
Thief.INTERVAL_MAX = 70
Thief.SPEED = 13

local DARK = Color3.fromRGB(35, 35, 45)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.Parent = parent
	return p
end

-- A shady figure in a striped shirt with a sack over one shoulder. Built
-- like a brainrot (pivot at half height, standing on Y=0) so MoveService
-- can walk it with the same pinning rule.
local function buildThiefModel(): Model
	local model = Instance.new("Model")
	model.Name = "PencuriBrainrot"
	part(model, "Body", Vector3.new(2, 2.2, 1.6), CFrame.new(0, 1.9, 0), Color3.fromRGB(240, 240, 240))
	part(model, "Stripe", Vector3.new(2.05, 0.5, 1.65), CFrame.new(0, 2.1, 0), DARK)
	part(model, "Head", Vector3.new(1.6, 1.3, 1.4), CFrame.new(0, 3.65, 0), DARK)
	part(model, "EyeL", Vector3.new(0.3, 0.3, 0.1), CFrame.new(-0.38, 3.7, -0.72), Color3.fromRGB(255, 255, 255))
	part(model, "EyeR", Vector3.new(0.3, 0.3, 0.1), CFrame.new(0.38, 3.7, -0.72), Color3.fromRGB(255, 255, 255))
	part(model, "LegL", Vector3.new(0.55, 0.8, 0.55), CFrame.new(-0.5, 0.4, 0), DARK)
	part(model, "LegR", Vector3.new(0.55, 0.8, 0.55), CFrame.new(0.5, 0.4, 0), DARK)
	part(model, "ArmL", Vector3.new(0.45, 1.4, 0.45), CFrame.new(-1.25, 2.0, 0), DARK)
	part(model, "ArmR", Vector3.new(0.45, 1.4, 0.45), CFrame.new(1.25, 2.0, 0), DARK)
	local sack = part(model, "Sack", Vector3.new(1.5, 1.8, 1.5), CFrame.new(1.6, 3.2, 0.4), Color3.fromRGB(170, 140, 95))
	sack.Shape = Enum.PartType.Ball
	model.PrimaryPart = model:FindFirstChild("Body")
	return model
end

-- Find the single best steal target across all players: the richest pad
-- in a base that is stocked and NOT locked right now.
local function pickTarget()
	local best = nil
	for player, state in pairs(GameState.all()) do
		if state.plotIndex > 0 and not GameState.isLocked(state) then
			local padIndex, income = GameState.richestPad(state)
			if padIndex and (best == nil or income > best.income) then
				best = { player = player, state = state, padIndex = padIndex, income = income }
			end
		end
	end
	return best
end

-- Run one theft. `deps` carries the plot refs, the walkers folder and the
-- toast callback from init.server, so this module owns no world state.
function Thief.runOnce(deps)
	local target = pickTarget()
	if not target then
		return false
	end
	local plot = deps.plots[target.state.plotIndex]
	local padPos = plot.PadPositions[target.padIndex]
	local thief = buildThiefModel()
	thief.Parent = deps.walkersFolder
	MoveService.placeOn(thief, 0, 44, 0, 1, 0)
	deps.toastAll("Pencuri brainrot mengintai base yang tidak dikunci!")
	MoveService.walk(thief, { Vector3.new(padPos.X, 0, padPos.Z) }, Thief.SPEED, 0, function()
		-- Re-check at grab time: the owner may have locked the base or
		-- the pad may have emptied while the thief was walking over.
		local state = GameState.get(target.player)
		if state and not GameState.isLocked(state) and state.pads[target.padIndex] then
			local pad = state.pads[target.padIndex]
			local def = BrainrotData.BY_ID[pad.defId]
			if pad.model then
				pad.model:Destroy()
			end
			state.pads[target.padIndex] = nil
			deps.toast(target.player, "Pencuri mengambil " .. (def and def.name or "brainrot") .. " dari base-mu!")
			deps.pushState(target.player)
		end
		-- Whatever happened, the thief legs it back to the plaza.
		MoveService.walk(thief, { Vector3.new(0, 0, 44) }, Thief.SPEED + 3, 0, function()
			thief:Destroy()
		end)
	end)
	return true
end

-- The endless patrol loop; started once by init.server.
function Thief.startLoop(deps)
	task.spawn(function()
		local rng = Random.new()
		while true do
			task.wait(rng:NextNumber(Thief.INTERVAL_MIN, Thief.INTERVAL_MAX))
			pcall(function()
				Thief.runOnce(deps)
			end)
		end
	end)
end

-- Would a theft succeed against this player right now? Exposed so the
-- HUD lock reminder and tests share one definition of "exposed": has a
-- placed brainrot and no active lock.
function Thief.isExposed(player: Player): boolean
	local state = GameState.get(player)
	if not state then
		return false
	end
	return GameState.placedCount(state) > 0 and not GameState.isLocked(state)
end

return Thief
