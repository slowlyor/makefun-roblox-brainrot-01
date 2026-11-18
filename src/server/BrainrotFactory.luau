-- BrainrotFactory.luau
-- Builds brainrot characters (and the thief) out of plain parts at runtime:
-- a body, a head with eyes, a silly prop on top and a BillboardGui carrying
-- the name / price / income labels. No meshes or assets are authored in the
-- project tree; everything is procedural so the place runs as-is.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local BrainrotFactory = {}

local PROP_TYPES = {
	Block = Enum.PartType.Block,
	Ball = Enum.PartType.Ball,
	Cylinder = Enum.PartType.Cylinder,
}

local function makePart(name: string, size: Vector3, color: Color3, material: Enum.Material?): Part
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

local function makeLabel(parent: Instance, name: string, yScale: number, heightScale: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, yScale)
	label.Size = UDim2.fromScale(1, heightScale)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextStrokeTransparency = 0.35
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Parent = parent
	return label
end

-- A floating name plate: line 1 is the character name, line 2 the price while
-- shopping or the income once owned.
local function makeBillboard(head: Part): (TextLabel, TextLabel)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Plate"
	gui.Size = UDim2.fromOffset(240, 84)
	gui.StudsOffset = Vector3.new(0, 2.4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	gui.Parent = head

	local nameLabel = makeLabel(gui, "NameLabel", 0, 0.52)
	local infoLabel = makeLabel(gui, "InfoLabel", 0.52, 0.48)
	return nameLabel, infoLabel
end

-- Create one brainrot character model standing on the origin (feet at y = 0).
-- `mutation` is a BrainrotData.MUTATIONS entry or nil.
function BrainrotFactory.CreateBrainrot(def, mutation): Model
	local rarity = BrainrotData.RarityByName[def.Rarity]
	local model = Instance.new("Model")
	model.Name = def.Name

	local bodyColor = def.BodyColor
	local bodyMaterial = Enum.Material.SmoothPlastic
	local transparency = 0
	if mutation then
		if mutation.Name == "Gold" then
			bodyColor = mutation.Color
			bodyMaterial = Enum.Material.Metal
		elseif mutation.Name == "Diamond" then
			bodyColor = mutation.Color
			bodyMaterial = Enum.Material.Glass
			transparency = 0.25
		elseif mutation.Name == "Rainbow" then
			bodyColor = mutation.Color
			bodyMaterial = Enum.Material.Neon
		end
	end

	local body = makePart("Body", Vector3.new(2.2, 2.6, 1.2), bodyColor, bodyMaterial)
	body.Transparency = transparency
	body.Position = Vector3.new(0, 1.3, 0)
	body.Parent = model

	local head = makePart("Head", Vector3.new(1.7, 1.5, 1.7), def.HeadColor)
	head.Position = Vector3.new(0, 3.35, 0)
	head.Parent = model

	for _, side in ipairs({ -0.42, 0.42 }) do
		local eye = makePart("Eye", Vector3.new(0.28, 0.28, 0.1), Color3.fromRGB(20, 20, 25))
		eye.Position = Vector3.new(side, 3.5, -0.86)
		eye.Parent = model
	end

	local prop = makePart("Prop", Vector3.new(1.1, 0.9, 1.1), def.PropColor)
	prop.Shape = PROP_TYPES[def.PropType] or Enum.PartType.Block
	prop.Position = Vector3.new(0, 4.55, 0)
	prop.Parent = model

	-- A rarity-coloured base disc so the tier reads at a glance.
	local disc = makePart("Disc", Vector3.new(3, 0.18, 3), rarity.Color, Enum.Material.Neon)
	disc.Shape = Enum.PartType.Cylinder
	disc.Position = Vector3.new(0, 0.09, 0)
	disc.Parent = model

	model.PrimaryPart = body

	local nameLabel, infoLabel = makeBillboard(head)
	local title = def.Name
	if mutation then
		title = mutation.Name .. " " .. def.Name
	end
	nameLabel.Text = title
	nameLabel.TextColor3 = rarity.Color
	infoLabel.Text = ""

	model:SetAttribute("PivotLift", 1.3) -- PrimaryPart centre height above the feet
	model:SetAttribute("BrainrotName", def.Name)
	model:SetAttribute("Rarity", def.Rarity)
	model:SetAttribute("Mutation", mutation and mutation.Name or "")
	return model
end

function BrainrotFactory.SetInfo(model: Model, text: string)
	local head = model:FindFirstChild("Head")
	local plate = head and head:FindFirstChild("Plate")
	local info = plate and plate:FindFirstChild("InfoLabel")
	if info then
		info.Text = text
	end
end

-- The wandering thief: a shifty figure in black with a sack on his back.
function BrainrotFactory.CreateThief(): Model
	local model = Instance.new("Model")
	model.Name = "Maling"

	local body = makePart("Body", Vector3.new(2.2, 2.8, 1.2), Color3.fromRGB(35, 35, 45))
	body.Position = Vector3.new(0, 1.4, 0)
	body.Parent = model

	local head = makePart("Head", Vector3.new(1.7, 1.5, 1.7), Color3.fromRGB(240, 200, 160))
	head.Position = Vector3.new(0, 3.55, 0)
	head.Parent = model

	local mask = makePart("Mask", Vector3.new(1.75, 0.5, 1.75), Color3.fromRGB(15, 15, 20))
	mask.Position = Vector3.new(0, 3.65, 0)
	mask.Parent = model

	local sack = makePart("Sack", Vector3.new(1.6, 1.8, 1), Color3.fromRGB(120, 95, 60))
	sack.Position = Vector3.new(0, 2.2, 0.95)
	sack.Parent = model

	model.PrimaryPart = body
	model:SetAttribute("PivotLift", 1.4)

	local nameLabel, infoLabel = makeBillboard(head)
	nameLabel.Text = "MALING!"
	nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	infoLabel.Text = "kunci basismu!"
	return model
end

return BrainrotFactory
