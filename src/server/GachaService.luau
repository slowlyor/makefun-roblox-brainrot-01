-- GachaService.luau
-- The MESIN GACHA BRAINROT machine in the plaza: pay an escalating cash
-- price per roll, spin the weighted rarity table, and the prize brainrot
-- walks out of the machine and all the way home to a free pad in your base.
-- If the base is full the roll never happens, so nobody pays for nothing.

local GachaService = {}

GachaService.BASE_COST = 250
GachaService.COST_GROWTH = 1.6
GachaService.MACHINE_POSITION = Vector3.new(14, 0, -14)

-- Price of the player's next roll: 250, 400, 640, 1024, ...
function GachaService.CostFor(record)
	return math.floor(GachaService.BASE_COST * (GachaService.COST_GROWTH ^ record.GachaRolls))
end

local function makePart(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.Parent = parent
	return p
end

-- Build the machine: chunky cabinet, glass dome with capsules inside, a
-- glowing roll button and the big sign. Returns the prompt part and the
-- spot where prizes pop out.
function GachaService.Build(worldBuilder)
	local machine = Instance.new("Model")
	machine.Name = "MesinGacha"
	machine.Parent = workspace

	local pos = GachaService.MACHINE_POSITION
	makePart(machine, "Cabinet", Vector3.new(7, 5, 5), CFrame.new(pos.X, 2.5, pos.Z),
		Color3.fromRGB(255, 110, 160), Enum.Material.SmoothPlastic)
	makePart(machine, "BaseTrim", Vector3.new(7.6, 0.8, 5.6), CFrame.new(pos.X, 0.4, pos.Z),
		Color3.fromRGB(255, 205, 60), Enum.Material.Neon)
	local dome = makePart(machine, "Dome", Vector3.new(5.6, 5.6, 5.6), CFrame.new(pos.X, 7.6, pos.Z),
		Color3.fromRGB(200, 240, 255), Enum.Material.Glass)
	dome.Shape = Enum.PartType.Ball
	dome.Transparency = 0.45
	dome.CanCollide = false
	-- Colourful capsules tumbling inside the dome.
	for i = 1, 7 do
		local angle = i * 2.4
		local cap = makePart(machine, "Capsule", Vector3.new(1.1, 1.1, 1.1),
			CFrame.new(pos.X + math.cos(angle) * 1.6, 6.6 + (i % 3) * 0.8, pos.Z + math.sin(angle) * 1.6),
			Color3.fromHSV(i / 7, 0.7, 1), Enum.Material.SmoothPlastic)
		cap.Shape = Enum.PartType.Ball
		cap.CanCollide = false
	end
	local button = makePart(machine, "RollButton", Vector3.new(2, 0.7, 2),
		CFrame.new(pos.X, 3.4, pos.Z - 2.8), Color3.fromRGB(80, 255, 140), Enum.Material.Neon)
	button.Shape = Enum.PartType.Cylinder
	button.CanCollide = false

	worldBuilder.MakeSign(machine, "GachaSign", "MESIN GACHA BRAINROT",
		pos + Vector3.new(0, 0, -6), Vector3.new(16, 3.6, 0.5), Color3.fromRGB(170, 60, 220))

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GachaPrompt"
	prompt.ActionText = "Putar Gacha"
	prompt.ObjectText = "Mesin Gacha Brainrot"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.Parent = button

	return {
		Prompt = prompt,
		ExitPosition = Vector3.new(pos.X, 1, pos.Z - 6),
		Button = button,
	}
end

-- Handle one roll for a player. ctx carries the shared services.
function GachaService.Roll(ctx, player)
	local record = ctx.GameState.Get(player)
	if not record then
		return
	end
	local padIndex = ctx.GameState.FindFreePad(record)
	if not padIndex then
		-- Base full: no charge, no roll, clear message.
		ctx.Toast(player, "Base penuh! Jual atau rebirth dulu sebelum gacha.")
		return
	end
	local cost = GachaService.CostFor(record)
	if record.Cash < cost then
		ctx.Toast(player, "Uang kurang untuk gacha: butuh " .. ctx.BrainrotData.FormatMoney(cost))
		return
	end

	record.Cash -= cost
	record.GachaRolls += 1

	local rng = Random.new()
	local entry = ctx.BrainrotData.RollEntry(rng)
	local mutation = ctx.BrainrotData.RollMutation(rng)
	local income = ctx.BrainrotData.IncomeOf(entry, mutation)
	local rarity = ctx.BrainrotData.GetRarity(entry.Rarity)

	-- Reserve the pad first so a second roll cannot double-book it.
	ctx.GameState.PlaceOnPad(record, padIndex, entry, mutation, income)

	local model = ctx.BrainrotFactory.Create(entry, mutation, tostring(income), rarity.Color)
	model.Parent = workspace
	local exitPos = ctx.Machine.ExitPosition
	ctx.MoveService.PlaceAt(model, exitPos + Vector3.new(0, 2.2, 0), math.pi)

	if entry.Rarity == "Divine" then
		ctx.BrainrotFactory.SparkleBurst(exitPos)
	end

	local label = mutation and (mutation.Name .. " ") or ""
	ctx.Toast(player, "Gacha: " .. label .. entry.Name .. " (" .. entry.Rarity .. ") jalan ke base kamu!")
	ctx.SyncState(player)

	local padPos = ctx.GameState.GetPadPosition(record.BaseIndex, padIndex)
	ctx.MoveService.Walk(model, {
		Vector3.new(exitPos.X, 0, exitPos.Z - 10),
		Vector3.new(padPos.X, 0, padPos.Z + 12),
		padPos,
	}, 13, 2.2, function()
		if record.Pads[padIndex] then
			record.Pads[padIndex].Model = model
		else
			model:Destroy()
		end
	end)
end

-- Preview the next few roll prices, for signs and future shop UI.
function GachaService.PreviewCosts(record, count)
	local prices = {}
	local rolls = record.GachaRolls
	for i = 1, count do
		table.insert(prices, math.floor(GachaService.BASE_COST * (GachaService.COST_GROWTH ^ (rolls + i - 1))))
	end
	return prices
end

-- Wire the machine's prompt to the roll handler.
function GachaService.Start(ctx)
	ctx.Machine.Prompt.Triggered:Connect(function(player)
		GachaService.Roll(ctx, player)
	end)
end

return GachaService
