-- BrainrotFactory.luau
-- Builds a brainrot character out of plain procedural Parts: a rounded body
-- in the character's colour, a face, two stubby legs, and a themed accessory
-- per Kind (blender jar, fan blades, satay skewers, sambal bowl and friends).
-- A BillboardGui over the head carries the readable name / rarity / income
-- label the whole genre runs on. No external assets are used.

local BrainrotFactory = {}

local function makePart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CastShadow = true
	return part
end

local function weld(model, part, offset)
	part.CFrame = model.PrimaryPart.CFrame * offset
	part.Parent = model
	local joint = Instance.new("WeldConstraint")
	joint.Part0 = model.PrimaryPart
	joint.Part1 = part
	joint.Parent = part
	return part
end

-- Accessory builders, one per Kind family. Each receives the model and its
-- main colour and decorates around the body at origin height.
local accessoryBuilders = {}

local function addLid(model, color)
	local lid = makePart("Lid", Vector3.new(1.7, 0.35, 1.7), color)
	lid.Shape = Enum.PartType.Cylinder
	weld(model, lid, CFrame.new(0, 1.55, 0))
end

accessoryBuilders.Blender = function(model, color)
	local jar = makePart("Jar", Vector3.new(1.3, 1.5, 1.3), Color3.fromRGB(220, 240, 250), Enum.Material.Glass)
	jar.Transparency = 0.35
	weld(model, jar, CFrame.new(0, 2.1, 0))
	addLid(model, color)
end

accessoryBuilders.Fan = function(model, color)
	local hub = makePart("FanHub", Vector3.new(0.5, 0.5, 0.5), color)
	hub.Shape = Enum.PartType.Ball
	weld(model, hub, CFrame.new(0, 2.2, -0.9))
	for i = 1, 3 do
		local blade = makePart("Blade", Vector3.new(0.35, 1.1, 0.12), Color3.fromRGB(240, 240, 240))
		local angle = (i - 1) * math.pi * 2 / 3
		weld(model, blade, CFrame.new(0, 2.2, -0.95) * CFrame.Angles(0, 0, angle) * CFrame.new(0, 0.55, 0))
	end
end

accessoryBuilders.Speaker = function(model, color)
	local cone = makePart("Cone", Vector3.new(1.2, 1.2, 0.3), Color3.fromRGB(30, 30, 35))
	cone.Shape = Enum.PartType.Cylinder
	weld(model, cone, CFrame.new(0, 0.9, -1.05) * CFrame.Angles(math.pi / 2, 0, 0))
	local knob = makePart("Knob", Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(255, 90, 90))
	knob.Shape = Enum.PartType.Ball
	weld(model, knob, CFrame.new(0.7, 1.9, 0))
end

accessoryBuilders.Satay = function(model, color)
	for i = -1, 1 do
		local skewer = makePart("Skewer", Vector3.new(0.14, 2.4, 0.14), Color3.fromRGB(230, 200, 150))
		weld(model, skewer, CFrame.new(i * 0.55, 2.2, 0) * CFrame.Angles(0, 0, i * 0.18))
		local chunk = makePart("MeatChunk", Vector3.new(0.5, 0.5, 0.5), color)
		weld(model, chunk, CFrame.new(i * 0.75, 2.9, 0))
	end
end

accessoryBuilders.Sambal = function(model, color)
	local bowl = makePart("Bowl", Vector3.new(1.9, 0.6, 1.9), Color3.fromRGB(250, 250, 250))
	bowl.Shape = Enum.PartType.Cylinder
	weld(model, bowl, CFrame.new(0, 1.7, 0))
	local paste = makePart("Paste", Vector3.new(1.5, 0.35, 1.5), color)
	paste.Shape = Enum.PartType.Cylinder
	weld(model, paste, CFrame.new(0, 1.95, 0))
end

accessoryBuilders.Rendang = function(model, color)
	local pot = makePart("Pot", Vector3.new(2.0, 0.8, 2.0), Color3.fromRGB(70, 70, 75))
	pot.Shape = Enum.PartType.Cylinder
	weld(model, pot, CFrame.new(0, -0.9, 0))
	local chunk = makePart("BeefChunk", Vector3.new(0.7, 0.5, 0.7), color)
	weld(model, chunk, CFrame.new(0.4, 1.8, 0.2))
end

accessoryBuilders.Omelet = function(model, color)
	local fold = makePart("Fold", Vector3.new(2.1, 0.5, 1.4), color)
	fold.Shape = Enum.PartType.Ball
	weld(model, fold, CFrame.new(0, 1.6, 0))
end

accessoryBuilders.Meatball = function(model, color)
	local bowl = makePart("Bowl", Vector3.new(2.1, 0.6, 2.1), Color3.fromRGB(250, 250, 250))
	bowl.Shape = Enum.PartType.Cylinder
	weld(model, bowl, CFrame.new(0, 1.65, 0))
	local ball = makePart("BigMeatball", Vector3.new(1.2, 1.2, 1.2), color)
	ball.Shape = Enum.PartType.Ball
	weld(model, ball, CFrame.new(0, 2.3, 0))
end

accessoryBuilders.FriedRice = function(model, color)
	local plate = makePart("Plate", Vector3.new(2.2, 0.3, 2.2), Color3.fromRGB(250, 250, 250))
	plate.Shape = Enum.PartType.Cylinder
	weld(model, plate, CFrame.new(0, 1.6, 0))
	local mound = makePart("RiceMound", Vector3.new(1.5, 0.9, 1.5), color)
	mound.Shape = Enum.PartType.Ball
	weld(model, mound, CFrame.new(0, 2.0, 0))
end

accessoryBuilders.Durian = function(model, color)
	for i = 1, 6 do
		local angle = i * math.pi / 3
		local spike = makePart("Spike", Vector3.new(0.3, 0.8, 0.3), Color3.fromRGB(210, 190, 90))
		spike.Shape = Enum.PartType.Cylinder
		weld(model, spike, CFrame.new(math.cos(angle) * 0.9, 1.9, math.sin(angle) * 0.9))
	end
	local crown = makePart("Crown", Vector3.new(1, 0.5, 1), Color3.fromRGB(255, 215, 60), Enum.Material.Neon)
	crown.Shape = Enum.PartType.Cylinder
	weld(model, crown, CFrame.new(0, 2.5, 0))
end

-- Kinds without a bespoke builder get a cheerful party hat in their colour.
local function addPartyHat(model, color)
	local hat = makePart("PartyHat", Vector3.new(1.1, 1.2, 1.1), color, Enum.Material.Neon)
	hat.Shape = Enum.PartType.Cylinder
	weld(model, hat, CFrame.new(0, 2.0, 0))
	local pom = makePart("PomPom", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
	pom.Shape = Enum.PartType.Ball
	weld(model, pom, CFrame.new(0, 2.7, 0))
end

local function addFace(model)
	for _, side in ipairs({ -0.42, 0.42 }) do
		local eye = makePart("Eye", Vector3.new(0.28, 0.38, 0.1), Color3.fromRGB(25, 25, 30))
		weld(model, eye, CFrame.new(side, 0.55, -1.01))
		local glint = makePart("Glint", Vector3.new(0.1, 0.12, 0.05), Color3.fromRGB(255, 255, 255))
		weld(model, glint, CFrame.new(side + 0.07, 0.65, -1.07))
	end
	local mouth = makePart("Mouth", Vector3.new(0.7, 0.14, 0.08), Color3.fromRGB(120, 40, 40))
	weld(model, mouth, CFrame.new(0, 0.05, -1.02))
end

local function addLegs(model, color)
	for _, side in ipairs({ -0.5, 0.5 }) do
		local leg = makePart("Leg", Vector3.new(0.55, 0.8, 0.55), color)
		weld(model, leg, CFrame.new(side, -1.35, 0))
		local foot = makePart("Foot", Vector3.new(0.65, 0.25, 0.95), Color3.fromRGB(60, 45, 35))
		weld(model, foot, CFrame.new(side, -1.8, -0.15))
	end
end

-- The floating label: name on top, rarity in its colour, income per second.
local function addBillboard(model, entry, mutation, incomeText, rarityColor)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(220, 74)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = model.PrimaryPart

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.42, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.25
	nameLabel.Text = entry.Name
	nameLabel.Parent = gui

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "InfoLabel"
	infoLabel.Position = UDim2.new(0, 0, 0.42, 0)
	infoLabel.Size = UDim2.new(1, 0, 0.58, 0)
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextScaled = true
	infoLabel.Font = Enum.Font.FredokaOne
	infoLabel.TextColor3 = rarityColor
	infoLabel.TextStrokeTransparency = 0.25
	local prefix = entry.Rarity
	if mutation then
		prefix = mutation.Name .. " " .. prefix
	end
	infoLabel.Text = prefix .. "  +" .. incomeText .. "/s"
	infoLabel.Parent = gui

	gui.Parent = model
	return gui
end

-- A burst of neon sparkle parts around a fresh Divine spawn. The parts are
-- unanchored, fly outward, and clean themselves up with Debris.
function BrainrotFactory.SparkleBurst(position)
	local debris = game:GetService("Debris")
	for i = 1, 18 do
		local spark = makePart("Sparkle", Vector3.new(0.35, 0.35, 0.35),
			Color3.fromHSV(i / 18, 0.55, 1), Enum.Material.Neon)
		spark.Shape = Enum.PartType.Ball
		spark.Anchored = false
		spark.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
		spark.AssemblyLinearVelocity = Vector3.new(
			math.random(-9, 9), math.random(6, 15), math.random(-9, 9))
		spark.Parent = workspace
		debris:AddItem(spark, 1.1)
	end
end

-- Build one brainrot model at a CFrame. Mutation tints the body: Gold and
-- Diamond recolour it, Rainbow keeps the base colour but turns it neon.
function BrainrotFactory.Create(entry, mutation, incomeText, rarityColor)
	local model = Instance.new("Model")
	model.Name = entry.Name

	local bodyColor = entry.Color
	local material = Enum.Material.SmoothPlastic
	if mutation then
		if mutation.Name == "Rainbow" then
			material = Enum.Material.Neon
		else
			bodyColor = mutation.Color
		end
	end

	local body = makePart("Body", Vector3.new(2, 2, 2), bodyColor, material)
	body.Shape = Enum.PartType.Block
	body.CanCollide = false
	model.PrimaryPart = body
	body.Parent = model

	addLegs(model, entry.Color)
	addFace(model)
	local builder = accessoryBuilders[entry.Kind]
	if builder then
		builder(model, entry.Color)
	else
		addPartyHat(model, entry.Color)
	end
	addBillboard(model, entry, mutation, incomeText, rarityColor)

	model:SetAttribute("BrainrotId", entry.Id)
	model:SetAttribute("Rarity", entry.Rarity)
	if mutation then
		model:SetAttribute("Mutation", mutation.Name)
	end
	return model
end

return BrainrotFactory
