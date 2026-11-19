-- GachaService: the plaza gacha machine. Each roll costs escalating cash,
-- rolls a weighted rarity, and the won brainrot walks to a free pad in the
-- player's base. If the base is full, the roll is refunded in full.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

local GachaService = {}

-- Roll once for `player`. `ctx` carries: gameState, remotes, factory, moveService,
-- plots, lift. Returns (ok, message).
function GachaService.roll(ctx, player)
	local data = ctx.gameState.get(player)
	if not data then
		return false, "Data pemain belum siap."
	end
	if data.plotIndex == 0 then
		return false, "Kamu belum punya base."
	end
	local padIndex = ctx.gameState.freePadIndex(data)
	if not padIndex then
		return false, "Base penuh! Gacha dibatalkan, uang kembali."
	end
	local cost = ctx.gameState.gachaCost(data)
	if data.cash < cost then
		return false, "Uang tidak cukup! Gacha butuh " .. BrainrotData.formatMoney(cost) .. "."
	end

	data.cash = data.cash - cost
	data.rolls = data.rolls + 1

	local rng = Random.new()
	local rarity = BrainrotData.rollRarity(rng)
	local char = BrainrotData.randomOfRarity(rarity, rng)
	local mutName, mutMult, mutColor = BrainrotData.rollMutation(rng)

	-- The base filled up while the roll resolved: refund in full.
	local padIndexNow = ctx.gameState.freePadIndex(data)
	if not padIndexNow then
		data.cash = data.cash + cost
		data.rolls = data.rolls - 1
		return false, "Base penuh! Uang gacha dikembalikan."
	end

	local model = ctx.factory.create(char, mutName, mutMult, mutColor)
	model.Parent = game:GetService("Workspace")
	-- Start at the gacha machine in the plaza, then walk to the free pad.
	local plot = ctx.plots[data.plotIndex]
	local padPos = plot.pads[padIndexNow].Position
	model:PivotTo(CFrame.new(24, ctx.lift, 44))
	data.pads[padIndexNow] = model
	data.owned[char.id] = true
	ctx.factory.setOwner(model, player.Name)

	local label = char.name
	if mutName then
		label = mutName .. " " .. label
	end
	ctx.gameState.toast(ctx.remotes, player, "GACHA! Kamu dapat " .. label .. " (" .. rarity .. ")!")
	ctx.gameState.toastAll(ctx.remotes, player.Name .. " dapat " .. label .. " dari gacha!")

	-- Walk the prize home: plaza -> belt-end corner -> pad, XZ only, Y pinned to lift.
	local hop = Vector3.new(70, 0, 0)
	ctx.moveService.walkTo(model, ctx.lift, hop, function()
		ctx.moveService.walkTo(model, ctx.lift, Vector3.new(padPos.X, 0, padPos.Z), function()
			ctx.moveService.snapToPad(model, ctx.lift, padPos)
		end)
	end)
	if rarity == "Divine" then
		ctx.factory.sparkleBurst(game:GetService("Workspace"), Vector3.new(24, 2, 44))
	end
	return true, "Gacha berhasil: " .. label .. "!"
end

return GachaService
