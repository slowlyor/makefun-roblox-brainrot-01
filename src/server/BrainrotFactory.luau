-- BrainrotFactory.luau
-- Builds every brainrot character out of plain procedural Parts: a chunky
-- body, a head with two eyes, stubby legs, and one prop that sells the
-- joke (a blender jar, a speaker cone, satay skewers, a crown...). No
-- external assets, no meshes, nothing uploaded.
--
-- Every model is built standing on Y=0 with its pivot at half its height,
-- so MoveService can pin it onto any surface by lift alone. A BillboardGui
-- nameplate over the head carries the name, rarity and $/s -- the three
-- things a buyer reads while the character walks the belt.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local BrainrotFactory = {}

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local WHITE = Color3.fromRGB(250, 250, 250)
local DARK = Color3.fromRGB(30, 30, 38)

-- The prop that makes each character read at a glance. All props are one
-- or two boxes/cylinders on or beside the body -- cheap and unmistakable.
local function buildProp(model: Model, prop: string, bodyColor: Color3)
	if prop == "jar" then -- blender jar / sambal jar on the head
		part(model, "PropJar", Vector3.new(1.1, 1.2, 1.1), CFrame.new(0, 3.6, 0), Color3.fromRGB(200, 240, 255), Enum.Material.Glass)
	elseif prop == "blades" then -- fan blades: three flat boxes in a ring
		for i = 1, 3 do
			local a = math.rad(i * 120)
			part(model, "PropBlade", Vector3.new(0.5, 1.5, 0.15), CFrame.new(math.sin(a) * 0.8, 2.6 + math.cos(a) * 0.8, -0.9) * CFrame.Angles(0, 0, a), Color3.fromRGB(230, 240, 250))
		end
	elseif prop == "broom" then
		part(model, "PropBroom", Vector3.new(0.25, 3.4, 0.25), CFrame.new(1.5, 1.9, 0) * CFrame.Angles(0, 0, math.rad(18)), Color3.fromRGB(160, 110, 60))
		part(model, "PropBristles", Vector3.new(0.9, 1.0, 0.5), CFrame.new(1.95, 0.5, 0), Color3.fromRGB(235, 205, 120))
	elseif prop == "dipper" then -- gayung: a scoop on a handle, held high
		part(model, "PropScoop", Vector3.new(1.2, 0.8, 1.2), CFrame.new(-1.5, 3.4, 0), bodyColor)
		part(model, "PropHandle", Vector3.new(0.2, 1.6, 0.2), CFrame.new(-1.5, 2.4, 0), bodyColor)
	elseif prop == "spoon" then
		part(model, "PropSpoonBowl", Vector3.new(1.0, 1.3, 0.2), CFrame.new(1.6, 3.2, 0), Color3.fromRGB(235, 235, 245), Enum.Material.Metal)
		part(model, "PropSpoonStick", Vector3.new(0.22, 1.8, 0.15), CFrame.new(1.6, 1.9, 0), Color3.fromRGB(235, 235, 245), Enum.Material.Metal)
	elseif prop == "pot" then
		part(model, "PropPot", Vector3.new(1.9, 1.0, 1.9), CFrame.new(0, 3.5, 0), Color3.fromRGB(120, 120, 135), Enum.Material.Metal)
		part(model, "PropLid", Vector3.new(2.1, 0.25, 2.1), CFrame.new(0, 4.1, 0), Color3.fromRGB(90, 90, 105), Enum.Material.Metal)
	elseif prop == "cooker" then
		part(model, "PropCookerLid", Vector3.new(2.0, 0.5, 2.0), CFrame.new(0, 3.3, 0), Color3.fromRGB(230, 230, 238), Enum.Material.Metal)
		part(model, "PropCookerLight", Vector3.new(0.4, 0.4, 0.15), CFrame.new(0, 2.4, -1.05), Color3.fromRGB(255, 90, 60), Enum.Material.Neon)
	elseif prop == "speaker" then
		local cone = part(model, "PropCone", Vector3.new(1.3, 1.3, 0.3), CFrame.new(0, 1.9, -1.0), DARK)
		cone.Shape = Enum.PartType.Cylinder
		cone.CFrame = CFrame.new(0, 1.9, -1.0) * CFrame.Angles(math.rad(90), 0, 0)
	elseif prop == "iron" then
		part(model, "PropIronHandle", Vector3.new(1.4, 0.5, 0.6), CFrame.new(0, 3.4, 0), DARK)
		part(model, "PropIronPlate", Vector3.new(1.9, 0.3, 1.1), CFrame.new(0, 3.05, 0), Color3.fromRGB(210, 215, 225), Enum.Material.Metal)
	elseif prop == "stove" then
		for _, dx in ipairs({ -0.55, 0.55 }) do
			local burner = part(model, "PropBurner", Vector3.new(0.8, 0.2, 0.8), CFrame.new(dx, 3.25, 0), DARK)
			burner.Shape = Enum.PartType.Cylinder
			part(model, "PropFlame", Vector3.new(0.45, 0.5, 0.45), CFrame.new(dx, 3.6, 0), Color3.fromRGB(80, 160, 255), Enum.Material.Neon)
		end
	elseif prop == "fridge" then
		part(model, "PropFridgeLine", Vector3.new(2.05, 0.15, 2.05), CFrame.new(0, 2.5, 0), Color3.fromRGB(150, 190, 215))
		part(model, "PropFridgeHandle", Vector3.new(0.18, 1.2, 0.18), CFrame.new(0.8, 2.0, -1.1), Color3.fromRGB(150, 150, 165), Enum.Material.Metal)
	end
end

-- Second prop bench: the bigger-ticket characters (Epic and up) get
-- chunkier, taller props so the rarity reads from across the plaza.
local function buildBigProp(model: Model, prop: string, bodyColor: Color3)
	if prop == "tv" then
		part(model, "PropScreen", Vector3.new(2.6, 1.8, 0.3), CFrame.new(0, 4.2, 0), Color3.fromRGB(90, 200, 255), Enum.Material.Neon)
		part(model, "PropAntenna", Vector3.new(0.12, 1.4, 0.12), CFrame.new(0, 5.6, 0) * CFrame.Angles(0, 0, math.rad(25)), DARK)
	elseif prop == "washer" then
		local drum = part(model, "PropDrum", Vector3.new(1.5, 1.5, 0.3), CFrame.new(0, 1.9, -0.85), Color3.fromRGB(160, 200, 235), Enum.Material.Glass)
		drum.Shape = Enum.PartType.Cylinder
		drum.CFrame = CFrame.new(0, 1.9, -0.85) * CFrame.Angles(math.rad(90), 0, 0)
	elseif prop == "ac" then
		part(model, "PropVents", Vector3.new(2.2, 0.9, 0.4), CFrame.new(0, 3.4, -0.6), Color3.fromRGB(235, 245, 250))
		part(model, "PropCold", Vector3.new(1.8, 0.5, 0.2), CFrame.new(0, 2.8, -0.75), Color3.fromRGB(170, 240, 255), Enum.Material.Neon)
	elseif prop == "scooter" then
		for _, dz in ipairs({ -1.3, 1.3 }) do
			local wheel = part(model, "PropWheel", Vector3.new(0.9, 0.9, 0.35), CFrame.new(0, 0.45, dz), DARK)
			wheel.Shape = Enum.PartType.Cylinder
			wheel.CFrame = CFrame.new(0, 0.45, dz) * CFrame.Angles(0, 0, math.rad(90))
		end
		part(model, "PropSeat", Vector3.new(1.0, 0.35, 1.6), CFrame.new(0, 1.15, 0.3), Color3.fromRGB(90, 60, 45))
	elseif prop == "skewers" then -- sate: three skewers fanned in one hand
		for i = -1, 1 do
			part(model, "PropSkewer", Vector3.new(0.14, 2.6, 0.14), CFrame.new(1.6 + i * 0.35, 3.4, 0) * CFrame.Angles(0, 0, math.rad(i * 14)), Color3.fromRGB(225, 190, 130))
			part(model, "PropMeat", Vector3.new(0.5, 0.9, 0.5), CFrame.new(1.6 + i * 0.5, 4.2, 0), Color3.fromRGB(150, 85, 40))
		end
	elseif prop == "plate" then -- nasi padang / omelet: a wide plate hat
		local plate = part(model, "PropPlate", Vector3.new(2.6, 0.3, 2.6), CFrame.new(0, 4.45, 0), Color3.fromRGB(250, 250, 245))
		plate.Shape = Enum.PartType.Cylinder
		part(model, "PropMound", Vector3.new(1.4, 0.7, 1.4), CFrame.new(0, 4.9, 0), bodyColor)
	elseif prop == "cup" then -- kopi luwak: a steaming cup on the head
		part(model, "PropCup", Vector3.new(1.2, 1.0, 1.2), CFrame.new(0, 4.6, 0), Color3.fromRGB(250, 248, 242))
		part(model, "PropCoffee", Vector3.new(1.0, 0.2, 1.0), CFrame.new(0, 5.05, 0), Color3.fromRGB(70, 45, 28))
	elseif prop == "spikes" then -- durian: spikes all over the body shell
		for i = 1, 6 do
			local a = math.rad(i * 60)
			part(model, "PropSpike", Vector3.new(0.4, 0.9, 0.4), CFrame.new(math.sin(a) * 1.15, 2.4 + math.cos(a) * 0.7, math.cos(a) * 0.9), Color3.fromRGB(105, 150, 55))
		end
	elseif prop == "crown" then -- the Divine finisher: a golden crown
		part(model, "PropCrownBand", Vector3.new(1.7, 0.55, 1.7), CFrame.new(0, 4.6, 0), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
		for i = 1, 4 do
			local a = math.rad(i * 90 + 45)
			part(model, "PropCrownTip", Vector3.new(0.4, 0.8, 0.4), CFrame.new(math.sin(a) * 0.7, 5.2, math.cos(a) * 0.7), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
		end
		local gem = part(model, "PropGem", Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 4.6, -0.9), Color3.fromRGB(255, 70, 120), Enum.Material.Neon)
		gem.Shape = Enum.PartType.Ball
	end
end

-- Build a character model for definition `def` under `mutation`
-- (nil = plain). The model is anchored, non-colliding, and carries its
-- economy as attributes so any system can read it without a lookup table.
function BrainrotFactory.create(def, mutation: string?): Model
	local info = BrainrotData.mutationInfo(mutation)
	local bodyColor = info and info.tint or def.color

	local model = Instance.new("Model")
	model.Name = def.id

	local body = part(model, "Body", Vector3.new(2, 2.2, 1.6), CFrame.new(0, 1.9, 0), bodyColor)
	part(model, "Head", Vector3.new(1.6, 1.3, 1.4), CFrame.new(0, 3.65 - 0.65, 0) + Vector3.new(0, 0.65, 0), bodyColor)
	-- Eyes on the front face (-Z is the model's forward).
	part(model, "EyeL", Vector3.new(0.32, 0.42, 0.1), CFrame.new(-0.38, 3.15, -0.72), WHITE)
	part(model, "EyeR", Vector3.new(0.32, 0.42, 0.1), CFrame.new(0.38, 3.15, -0.72), WHITE)
	part(model, "PupilL", Vector3.new(0.15, 0.2, 0.06), CFrame.new(-0.38, 3.12, -0.79), DARK)
	part(model, "PupilR", Vector3.new(0.15, 0.2, 0.06), CFrame.new(0.38, 3.12, -0.79), DARK)
	-- Stubby legs and arms.
	part(model, "LegL", Vector3.new(0.55, 0.8, 0.55), CFrame.new(-0.5, 0.4, 0), DARK)
	part(model, "LegR", Vector3.new(0.55, 0.8, 0.55), CFrame.new(0.5, 0.4, 0), DARK)
	part(model, "ArmL", Vector3.new(0.45, 1.4, 0.45), CFrame.new(-1.25, 2.0, 0), bodyColor)
	part(model, "ArmR", Vector3.new(0.45, 1.4, 0.45), CFrame.new(1.25, 2.0, 0), bodyColor)

	buildProp(model, def.prop, bodyColor)
	buildBigProp(model, def.prop, bodyColor)

	model.PrimaryPart = body
	model:SetAttribute("BrainrotId", def.id)
	model:SetAttribute("Mutation", mutation or "")
	model:SetAttribute("Price", BrainrotData.priceOf(def, mutation))
	model:SetAttribute("Income", BrainrotData.incomeOf(def, mutation))

	BrainrotFactory.refreshNameplate(model)
	return model
end

-- (Re)write the floating nameplate: name, mutation + rarity, $/s.
function BrainrotFactory.refreshNameplate(model: Model)
	local def = BrainrotData.BY_ID[model:GetAttribute("BrainrotId")]
	if not def then
		return
	end
	local mutation = model:GetAttribute("Mutation")
	if mutation == "" then
		mutation = nil
	end
	local old = model:FindFirstChild("Nameplate")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Size = UDim2.fromOffset(220, 64)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = model.PrimaryPart

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextStrokeTransparency = 0.35
	title.Text = (mutation and (mutation .. " ") or "") .. def.name
	title.Parent = gui

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Position = UDim2.new(0, 0, 0.55, 0)
	sub.Size = UDim2.new(1, 0, 0.45, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.FredokaOne
	sub.TextScaled = true
	sub.TextColor3 = BrainrotData.RARITY_INFO[def.rarity].color
	sub.TextStrokeTransparency = 0.35
	sub.Text = string.format("%s - %s/dtk", def.rarity, BrainrotData.formatMoney(BrainrotData.incomeOf(def, mutation)))
	sub.Parent = gui

	gui.Parent = model
end

return BrainrotFactory
