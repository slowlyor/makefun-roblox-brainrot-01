-- GachaService.luau
-- Brainrot Bazaar: the plaza gacha machine. Each roll costs more than
-- the last, rolls a weighted rarity, and the prize brainrot walks
-- from the machine across the plaza to a free pad in the winner's
-- base. A full base is never charged: the roll refuses up front,
-- which is the refund rule with no money ever leaving the wallet.

local GachaService = {}

GachaService.WALK_SPEED = 9

function GachaService.CanRoll(ctx, data)
	if ctx.GameState.FreePad(data) == nil then
		return false, "Base penuh! Jual atau rebirth dulu."
	end
	local cost = ctx.GameState.GachaCost(data)
	if data.Cash < cost then
		return false, "Uang kurang untuk gacha ($" .. cost .. ")."
	end
	return true, nil
end

function GachaService.Roll(ctx, player)
	local data = ctx.GameState.Get(player)
	if not data then
		return false
	end
	local ok, reason = GachaService.CanRoll(ctx, data)
	if not ok then
		ctx.ToastPlayer(player, reason)
		return false
	end
	local padIndex = ctx.GameState.FreePad(data)
	local plot = ctx.World.Plots[data.PlotIndex]
	if not padIndex or not plot then
		ctx.ToastPlayer(player, "Base penuh! Jual atau rebirth dulu.")
		return false
	end
	local cost = ctx.GameState.GachaCost(data)
	data.Cash -= cost
	data.GachaRolls += 1
	local rng = ctx.Rng
	local rarity = ctx.BrainrotData.RollRarity(ctx.BrainrotData.GACHA_WEIGHTS, rng)
	local def = ctx.BrainrotData.RandomOfRarity(rarity, rng)
	local mutation = ctx.BrainrotData.RollMutation(rng)
	local entry = {
		DefId = def.Id,
		Mutation = mutation.Name,
		Price = ctx.BrainrotData.PriceFor(def, mutation),
		Income = ctx.BrainrotData.IncomeFor(def, mutation),
		Stored = 0,
	}
	-- Reserve the pad at once so a second roll cannot target it too.
	ctx.GameState.PlaceBrainrot(data, padIndex, entry)
	local padPos = plot.Pads[padIndex]
	local model = ctx.Factory.Create(def, mutation.Name)
	model.Parent = workspace
	local start = ctx.World.GachaPosition
	model:PivotTo(CFrame.new(start.X, ctx.Factory.ROOT_LIFT, start.Z))
	local mutText = mutation.Name ~= "Normal" and (" " .. mutation.Name) or ""
	ctx.Factory.SetLabel(model, def.Name .. mutText, def.Rarity .. " - GACHA!", ctx.BrainrotData.RARITY_COLORS[def.Rarity])
	if def.Rarity == "Divine" then
		ctx.Factory.SparkleBurst(Vector3.new(start.X, 1, start.Z))
		ctx.ToastAll(player.Name .. " menarik " .. def.Name .. " DIVINE dari gacha!")
	else
		ctx.ToastPlayer(player, "Gacha: " .. def.Name .. " (" .. def.Rarity .. mutText .. ") berjalan ke basemu!")
	end
	ctx.SyncPlayer(player)
	ctx.MoveService.Add(model, {
		Path = {
			Vector3.new(start.X, 0, 44),
			Vector3.new(padPos.X, 0, plot.Center.Z),
			Vector3.new(padPos.X, 0, padPos.Z),
		},
		Speed = GachaService.WALK_SPEED,
		PivotY = ctx.Factory.ROOT_LIFT,
		Tag = "gacha",
		OnArrive = function()
			-- Swap the walker for the standing pad model.
			model:Destroy()
			if data.Pads[padIndex] == entry then
				local placed = ctx.Factory.Create(def, mutation.Name)
				placed.Parent = workspace
				placed:PivotTo(CFrame.new(padPos.X, plot.Pads[padIndex].Y + ctx.Factory.ROOT_LIFT, padPos.Z))
				ctx.Factory.SetLabel(placed, def.Name .. mutText, "$" .. entry.Income .. "/s", ctx.BrainrotData.RARITY_COLORS[def.Rarity])
				data.PadModels[padIndex] = placed
				if def.Rarity == "Divine" then
					ctx.Factory.SparkleBurst(padPos + Vector3.new(0, 1, 0))
				end
			end
			ctx.SyncPlayer(player)
		end,
		OnCancel = function()
			-- Never lose a paid prize: if the walk is interrupted the
			-- brainrot simply appears on its reserved pad.
			if data.Pads[padIndex] == entry and not data.PadModels[padIndex] then
				local placed = ctx.Factory.Create(def, mutation.Name)
				placed.Parent = workspace
				placed:PivotTo(CFrame.new(padPos.X, plot.Pads[padIndex].Y + ctx.Factory.ROOT_LIFT, padPos.Z))
				ctx.Factory.SetLabel(placed, def.Name .. mutText, "$" .. entry.Income .. "/s", ctx.BrainrotData.RARITY_COLORS[def.Rarity])
				data.PadModels[padIndex] = placed
			end
		end,
	})
	return true
end

-- The price of the roll after the next one, for "next: $X" labels.
function GachaService.CostAfterNext(ctx, data)
	local clone = { GachaRolls = data.GachaRolls + 1 }
	return ctx.GameState.GachaCost(clone)
end

-- Rarity odds as percentages, for the machine's help text.
function GachaService.OddsText(ctx)
	local weights = ctx.BrainrotData.GACHA_WEIGHTS
	local total = 0
	for _, rarity in ipairs(ctx.BrainrotData.RARITIES) do
		total += weights[rarity] or 0
	end
	local parts = {}
	for i = #ctx.BrainrotData.RARITIES, 1, -1 do
		local rarity = ctx.BrainrotData.RARITIES[i]
		local pct = (weights[rarity] or 0) / total * 100
		table.insert(parts, rarity .. " " .. string.format("%.0f", pct) .. "%")
	end
	return table.concat(parts, " - ")
end

return GachaService
