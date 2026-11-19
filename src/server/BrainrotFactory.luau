-- BrainrotFactory.luau -- builds a walking brainrot character model
-- procedurally: body (shape varies by character), head, eyes, little legs
-- and a billboard label with name, rarity, price and income per second.
-- Divine spawns also get a sparkle burst of small neon parts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local BrainrotFactory = {}

local function bodyPart(name, shape, size, pos, color, parent)
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.Parent = parent
	return p
end

-- Build a model for character defIndex with a mutation applied.
-- The model is placed with its feet at the given position; its pivot Y
-- lift (feet to pivot centre) is stored as the "Lift" attribute so
-- MoveService can pin heights without reading the model's current Y.
function BrainrotFactory.Create(defIndex, mutationName, position)
	local c = BrainrotData.Get(defIndex)
	local mutation = BrainrotData.MutationByName(mutationName)
	local bodyColor = mutation.Color or c.Color
	local rarityColor = BrainrotData.RarityColors[c.Rarity]

	local model = Instance.new("Model")
	model.Name = c.Name

	-- Body: shape and size depend on the character kind.
	local body
	if c.Kind == "round" then
		body = bodyPart("Body", Enum.PartType.Ball, Vector3.new(2.4, 2.4, 2.4),
			position + Vector3.new(0, 1.7, 0), bodyColor, model)
	elseif c.Kind == "tall" then
		body = bodyPart("Body", Enum.PartType.Cylinder, Vector3.new(3.2, 1.7, 1.7),
			position + Vector3.new(0, 1.6, 0), bodyColor, model)
	else
		body = bodyPart("Body", nil, Vector3.new(2.2, 2.6, 1.6),
			position + Vector3.new(0, 1.75, 0), bodyColor, model)
	end

	-- Head with two eyes and a smile-coloured mouth stripe.
	bodyPart("Head", Enum.PartType.Ball, Vector3.new(1.5, 1.5, 1.5),
		position + Vector3.new(0, 3.6, 0), bodyColor, model)
	for _, dx in ipairs({ -0.35, 0.35 }) do
		bodyPart("Eye", Enum.PartType.Ball, Vector3.new(0.28, 0.28, 0.28),
			position + Vector3.new(dx, 3.8, 0.68), Color3.fromRGB(20, 20, 20), model)
	end
	bodyPart("Mouth", nil, Vector3.new(0.7, 0.16, 0.1),
		position + Vector3.new(0, 3.3, 0.72), Color3.fromRGB(120, 30, 30), model)

	-- Rarity band around the body so rarity reads at a glance.
	local band = bodyPart("RarityBand", Enum.PartType.Cylinder, Vector3.new(0.5, 2.6, 2.6),
		position + Vector3.new(0, 0.75, 0), rarityColor, model)
	band.Material = Enum.Material.Neon

	-- Two stubby legs.
	for _, dx in ipairs({ -0.6, 0.6 }) do
		bodyPart("Leg", nil, Vector3.new(0.55, 0.9, 0.55),
			position + Vector3.new(dx, 0.45, 0), Color3.fromRGB(60, 50, 45), model)
	end

	model.PrimaryPart = body
	model:SetAttribute("DefIndex", defIndex)
	model:SetAttribute("Mutation", mutationName)
	model:SetAttribute("Lift", 1.75)
	model:PivotTo(CFrame.new(position + Vector3.new(0, 1.75, 0)))

	BrainrotFactory.AttachLabel(model, defIndex, mutationName)
	if c.Rarity == "Divine" then
		BrainrotFactory.SparkleBurst(model, position)
	end
	return model
end

-- Billboard label: name on line one, rarity + price + income below.
function BrainrotFactory.AttachLabel(model, defIndex, mutationName)
	local c = BrainrotData.Get(defIndex)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(220, 64)
	gui.StudsOffset = Vector3.new(0, 5.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	gui.Parent = model

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.BackgroundTransparency = 1
	title.Text = ((mutationName ~= "Normal") and (mutationName .. " ") or "") .. c.Name
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0.4
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 20
	title.Parent = gui

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Position = UDim2.new(0, 0, 0.55, 0)
	sub.Size = UDim2.new(1, 0, 0.45, 0)
	sub.BackgroundTransparency = 1
	sub.Text = string.format("%s  %s  %s/s", string.upper(c.Rarity),
		BrainrotData.FormatMoney(BrainrotData.PriceFor(defIndex, mutationName)),
		BrainrotData.FormatMoney(BrainrotData.IncomeFor(defIndex, mutationName)))
	sub.TextColor3 = BrainrotData.RarityColors[c.Rarity]
	sub.TextStrokeTransparency = 0.4
	sub.Font = Enum.Font.FredokaOne
	sub.TextSize = 16
	sub.Parent = gui
	return gui
end

-- A burst of small neon cubes around a fresh Divine spawn. The parts
-- are anchored, non-colliding decoration; the caller fades them out.
function BrainrotFactory.SparkleBurst(model, position)
	local folder = Instance.new("Folder")
	folder.Name = "DivineSparkles"
	folder.Parent = model
	local rng = Random.new()
	for i = 1, 14 do
		local s = Instance.new("Part")
		s.Name = "Sparkle" .. i
		s.Size = Vector3.new(0.35, 0.35, 0.35)
		s.Position = position + Vector3.new(rng:NextNumber(-2.4, 2.4), rng:NextNumber(0.4, 4.6), rng:NextNumber(-2.4, 2.4))
		s.Color = Color3.fromRGB(255, 240, 150)
		s.Material = Enum.Material.Neon
		s.Anchored = true
		s.CanCollide = false
		s.Parent = folder
	end
	return folder
end

-- Rewrite a placed brainrot's pad label to show the cash it has stored,
-- e.g. "SIMPANAN: $1.2K" -- this is the number the collect pad harvests.
function BrainrotFactory.SetStoredLabel(model, stored)
	local gui = model:FindFirstChild("Label")
	if not gui then
		return
	end
	local sub = gui:FindFirstChild("Sub")
	if sub then
		sub.Text = "SIMPANAN: " .. BrainrotData.FormatMoney(stored)
		sub.TextColor3 = Color3.fromRGB(120, 255, 140)
	end
end

-- A shadowy thief NPC model: dark body, mask band, sack on its back.
function BrainrotFactory.CreateThief(position)
	local model = Instance.new("Model")
	model.Name = "PencuriBrainrot"
	local dark = Color3.fromRGB(35, 35, 45)
	bodyPart("Body", nil, Vector3.new(2.2, 2.8, 1.6), position + Vector3.new(0, 1.85, 0), dark, model)
	bodyPart("Head", Enum.PartType.Ball, Vector3.new(1.5, 1.5, 1.5), position + Vector3.new(0, 3.8, 0), dark, model)
	bodyPart("Mask", nil, Vector3.new(1.55, 0.4, 1.55), position + Vector3.new(0, 3.9, 0), Color3.fromRGB(200, 40, 40), model)
	bodyPart("Sack", Enum.PartType.Ball, Vector3.new(1.8, 1.8, 1.8), position + Vector3.new(0, 2.4, -1.3), Color3.fromRGB(150, 120, 80), model)
	for _, dx in ipairs({ -0.6, 0.6 }) do
		bodyPart("Leg", nil, Vector3.new(0.55, 0.9, 0.55), position + Vector3.new(dx, 0.45, 0), Color3.fromRGB(20, 20, 25), model)
	end
	model.PrimaryPart = model:FindFirstChild("Body")
	model:SetAttribute("Lift", 1.85)
	model:PivotTo(CFrame.new(position + Vector3.new(0, 1.85, 0)))
	return model
end

return BrainrotFactory
