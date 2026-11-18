-- BrainrotFactory.luau
-- Builds brainrot characters out of plain parts: a rounded body, a head, one
-- themed prop part whose shape depends on the character, simple face decals
-- made from small dark parts, and an AlwaysOnTop BillboardGui label showing
-- "Name $price — $income/s". Mutated spawns get the mutation's colour wash
-- and its name as a prefix in the label.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local BrainrotFactory = {}

local function makePart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

-- Prop shapes: every character carries one themed prop. Props are simple but
-- distinct silhouettes so players can recognise a character from afar.
local function buildProp(def, bodyColor)
	local propName = def.Prop
	if propName == "BlenderJar" then
		local jar = makePart("Prop", Vector3.new(1.1, 1.4, 1.1), Color3.fromRGB(200, 235, 255), Enum.Material.Glass)
		return jar, Vector3.new(0, 2.6, 0)
	elseif propName == "SpeakerCone" then
		local cone = makePart("Prop", Vector3.new(1.3, 1.3, 0.5), Color3.fromRGB(30, 30, 35))
		cone.Shape = Enum.PartType.Cylinder
		return cone, Vector3.new(0, 1.5, -0.95)
	elseif propName == "ShrimpTail" then
		local tail = makePart("Prop", Vector3.new(0.5, 1.2, 1.4), Color3.fromRGB(255, 110, 70))
		return tail, Vector3.new(0, 1.6, 0.9)
	elseif propName == "FridgeDoor" then
		local door = makePart("Prop", Vector3.new(1.6, 2.4, 0.3), Color3.fromRGB(225, 240, 248))
		return door, Vector3.new(1.15, 1.4, 0)
	elseif propName == "CookerLid" or propName == "RendangPot" or propName == "SteamerPot" then
		local pot = makePart("Prop", Vector3.new(1.5, 0.9, 1.5), bodyColor)
		pot.Shape = Enum.PartType.Cylinder
		return pot, Vector3.new(0, 2.7, 0)
	elseif propName == "MeatballBowl" or propName == "GalaxyWok" then
		local bowl = makePart("Prop", Vector3.new(1.6, 0.7, 1.6), Color3.fromRGB(240, 240, 240))
		bowl.Shape = Enum.PartType.Ball
		return bowl, Vector3.new(0, 1.4, -1)
	elseif propName == "Megaphone" then
		local horn = makePart("Prop", Vector3.new(1, 1, 1.3), Color3.fromRGB(255, 80, 60))
		horn.Shape = Enum.PartType.Cylinder
		return horn, Vector3.new(0, 2, -1)
	elseif propName == "NeonCane" then
		local cane = makePart("Prop", Vector3.new(0.25, 2.2, 0.25), Color3.fromRGB(255, 90, 200), Enum.Material.Neon)
		return cane, Vector3.new(1.1, 1.2, 0)
	elseif propName == "SateSkewers" then
		local skewer = makePart("Prop", Vector3.new(0.18, 2.4, 0.18), Color3.fromRGB(200, 150, 80))
		return skewer, Vector3.new(1.1, 1.8, 0)
	elseif propName == "StarMedal" then
		local medal = makePart("Prop", Vector3.new(0.7, 0.7, 0.2), Color3.fromRGB(255, 215, 0), Enum.Material.Metal)
		medal.Shape = Enum.PartType.Ball
		return medal, Vector3.new(0, 1.7, -0.85)
	elseif propName == "NoodleCrown" or propName == "ChiliCrown" then
		local crown = makePart("Prop", Vector3.new(1.3, 0.6, 1.3), Color3.fromRGB(255, 215, 0), Enum.Material.Metal)
		crown.Shape = Enum.PartType.Cylinder
		return crown, Vector3.new(0, 3.15, 0)
	elseif propName == "FanBlades" then
		local fan = makePart("Prop", Vector3.new(1.6, 1.6, 0.25), Color3.fromRGB(200, 230, 255), Enum.Material.Metal)
		fan.Shape = Enum.PartType.Cylinder
		return fan, Vector3.new(0, 2.9, 0)
	elseif propName == "DasterCloth" then
		local cloth = makePart("Prop", Vector3.new(1.9, 1.6, 0.25), Color3.fromRGB(255, 170, 210))
		return cloth, Vector3.new(0, 1.5, 0.85)
	elseif propName == "OmeletPan" then
		local pan = makePart("Prop", Vector3.new(1.4, 0.3, 1.4), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
		pan.Shape = Enum.PartType.Cylinder
		return pan, Vector3.new(1.2, 1.6, 0)
	end
	-- Fallback prop: a cheerful block on the head.
	local block = makePart("Prop", Vector3.new(0.9, 0.9, 0.9), bodyColor)
	return block, Vector3.new(0, 2.9, 0)
end

-- Create a brainrot model for `def` with an optional mutation. The model's
-- origin is at the ground under its feet, so callers position it by pivot.
function BrainrotFactory.Create(def, mutation)
	local model = Instance.new("Model")
	model.Name = BrainrotData.DisplayName(def, mutation)
	model:SetAttribute("CharacterName", def.Name)
	model:SetAttribute("Rarity", def.Rarity)
	model:SetAttribute("Mutation", mutation and mutation.Name or "")

	local bodyColor = def.Color
	if mutation then
		bodyColor = mutation.Color
	end

	local body = makePart("Body", Vector3.new(1.8, 2, 1.2), bodyColor)
	body.Position = Vector3.new(0, 1, 0)
	body.Parent = model

	local head = makePart("Head", Vector3.new(1.3, 1.1, 1.3), bodyColor:Lerp(Color3.new(1, 1, 1), 0.15))
	head.Position = Vector3.new(0, 2.55, 0)
	head.Parent = model

	-- Face: two eyes and a smile, all tiny dark parts on the head's front.
	for _, offsetX in ipairs({ -0.32, 0.32 }) do
		local eye = makePart("Eye", Vector3.new(0.18, 0.24, 0.06), Color3.fromRGB(20, 20, 20))
		eye.Position = Vector3.new(offsetX, 2.65, -0.67)
		eye.Parent = model
	end
	local mouth = makePart("Mouth", Vector3.new(0.55, 0.1, 0.06), Color3.fromRGB(20, 20, 20))
	mouth.Position = Vector3.new(0, 2.32, -0.67)
	mouth.Parent = model

	local prop, propOffset = buildProp(def, bodyColor)
	prop.Position = propOffset
	prop.Parent = model

	model.PrimaryPart = body

	-- Price / income label, always facing the camera.
	local price = BrainrotData.PriceOf(def, mutation)
	local income = BrainrotData.IncomeOf(def, mutation)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(220, 54)
	billboard.StudsOffset = Vector3.new(0, 3.9, 0)
	billboard.Adornee = head
	billboard.Parent = model

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.BackgroundTransparency = 0.35
	text.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.4
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.Size = UDim2.fromScale(1, 1)
	text.Text = string.format(
		"%s $%s — $%s/s",
		BrainrotData.DisplayName(def, mutation),
		BrainrotData.FormatCash(price),
		BrainrotData.FormatCash(income)
	)
	text.Parent = billboard

	-- Rarity stripe under the body so rarity reads at a glance.
	local stripe = makePart("RarityStripe", Vector3.new(2, 0.18, 1.4), BrainrotData.RarityColors[def.Rarity], Enum.Material.Neon)
	stripe.Position = Vector3.new(0, 0.09, 0)
	stripe.Parent = model

	return model
end

return BrainrotFactory
