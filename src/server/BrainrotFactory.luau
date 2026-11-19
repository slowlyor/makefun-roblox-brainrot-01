-- BrainrotFactory.luau
-- Brainrot Bazaar: builds a brainrot character Model out of plain
-- parts -- a chunky body, a head with eyes, and one silly accessory
-- chosen by the character's Accessory kind. No external assets.
-- Every model is built standing on Y=0 with its Root part centred at
-- Y=1, so MoveService can pin the pivot to (ground height + 1).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))

local BrainrotFactory = {}

BrainrotFactory.ROOT_LIFT = 1 -- Root centre height above the ground it stands on

local function part(parent, name, size, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function ball(parent, name, radius, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
	p.Position = pos
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.Parent = parent
	return p
end

local function addAccessory(model, kind, accent, bodyColor)
	local gold = Color3.fromRGB(255, 205, 48)
	if kind == "blades" then
		part(model, "BladeA", Vector3.new(2.4, 0.18, 0.5), Vector3.new(0, 5.35, 0), accent, Enum.Material.Metal)
		local b = part(model, "BladeB", Vector3.new(2.4, 0.18, 0.5), Vector3.new(0, 5.35, 0), accent, Enum.Material.Metal)
		b.CFrame = CFrame.new(0, 5.35, 0) * CFrame.Angles(0, math.rad(90), 0)
		part(model, "Jug", Vector3.new(1.2, 1, 1.2), Vector3.new(0, 4.75, 0), Color3.fromRGB(200, 235, 255), Enum.Material.Glass).Transparency = 0.4
	elseif kind == "broom" then
		local stick = part(model, "BroomStick", Vector3.new(0.22, 3.4, 0.22), Vector3.new(1.7, 2.6, 0), accent, Enum.Material.Wood)
		stick.CFrame = CFrame.new(1.7, 2.6, 0) * CFrame.Angles(0, 0, math.rad(-14))
		part(model, "BroomHead", Vector3.new(0.7, 1.1, 0.7), Vector3.new(2.1, 0.8, 0), Color3.fromRGB(232, 197, 110), Enum.Material.Grass)
	elseif kind == "fan" then
		for i = 0, 2 do
			local a = i * math.pi * 2 / 3
			local blade = part(model, "FanBlade", Vector3.new(0.5, 1.5, 0.14), Vector3.new(math.sin(a) * 0.55, 4.15 + math.cos(a) * 0.55, -0.95), accent, Enum.Material.Metal)
			blade.CFrame = CFrame.new(blade.Position) * CFrame.Angles(0, 0, -a)
		end
		part(model, "FanRing", Vector3.new(2.5, 2.5, 0.12), Vector3.new(0, 4.15, -0.9), bodyColor, Enum.Material.Metal).Transparency = 0.55
	elseif kind == "lid" then
		local lid = Instance.new("Part")
		lid.Name = "PotLid"
		lid.Shape = Enum.PartType.Cylinder
		lid.Size = Vector3.new(0.3, 2, 2)
		lid.CFrame = CFrame.new(0, 5.05, 0) * CFrame.Angles(0, 0, math.rad(90))
		lid.Color = accent
		lid.Material = Enum.Material.Metal
		lid.Anchored = true
		lid.CanCollide = false
		lid.Parent = model
		ball(model, "LidKnob", 0.28, Vector3.new(0, 5.35, 0), Color3.fromRGB(40, 40, 46))
	elseif kind == "steam" then
		ball(model, "SteamA", 0.34, Vector3.new(-0.4, 5.3, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic).Transparency = 0.35
		ball(model, "SteamB", 0.26, Vector3.new(0.3, 5.65, 0.1), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic).Transparency = 0.45
		ball(model, "SteamC", 0.2, Vector3.new(0, 5.95, -0.1), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic).Transparency = 0.55
	elseif kind == "skewers" then
		for i = -1, 1 do
			local s = part(model, "Skewer", Vector3.new(0.14, 2.2, 0.14), Vector3.new(i * 0.55, 5.2, 0), Color3.fromRGB(196, 144, 84), Enum.Material.Wood)
			s.CFrame = CFrame.new(i * 0.55, 5.2, 0) * CFrame.Angles(math.rad(18), 0, 0)
			ball(model, "Meatball", 0.3, Vector3.new(i * 0.55, 5.7, -0.35), Color3.fromRGB(140, 84, 44))
		end
	elseif kind == "spout" then
		local sp = part(model, "Spout", Vector3.new(0.4, 1.6, 0.4), Vector3.new(1.35, 3.4, 0), accent, Enum.Material.Metal)
		sp.CFrame = CFrame.new(1.35, 3.4, 0) * CFrame.Angles(0, 0, math.rad(-38))
		part(model, "Handle", Vector3.new(0.24, 1.6, 0.24), Vector3.new(-1.3, 3.2, 0), accent, Enum.Material.Metal)
	elseif kind == "antenna" then
		part(model, "AntennaRod", Vector3.new(0.14, 2.2, 0.14), Vector3.new(0.5, 5.9, 0), accent, Enum.Material.Metal)
		ball(model, "AntennaTip", 0.24, Vector3.new(0.5, 7.05, 0), Color3.fromRGB(255, 80, 80), Enum.Material.Neon)
		part(model, "SpeakerCone", Vector3.new(1.3, 1.3, 0.3), Vector3.new(0, 2.2, -0.8), Color3.fromRGB(30, 30, 36), Enum.Material.SmoothPlastic)
	elseif kind == "flame" then
		ball(model, "FlameA", 0.5, Vector3.new(0, 5.35, 0), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
		ball(model, "FlameB", 0.32, Vector3.new(0.15, 5.8, 0), Color3.fromRGB(255, 210, 80), Enum.Material.Neon)
	elseif kind == "drum" then
		local drum = Instance.new("Part")
		drum.Name = "DrumWindow"
		drum.Shape = Enum.PartType.Cylinder
		drum.Size = Vector3.new(0.3, 1.7, 1.7)
		drum.CFrame = CFrame.new(0, 2.2, -0.75)
		drum.Color = Color3.fromRGB(160, 220, 250)
		drum.Material = Enum.Material.Glass
		drum.Anchored = true
		drum.CanCollide = false
		drum.Parent = model
	elseif kind == "snow" then
		ball(model, "SnowA", 0.26, Vector3.new(-0.6, 5.25, 0.3), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
		ball(model, "SnowB", 0.2, Vector3.new(0.55, 5.45, -0.2), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
		ball(model, "SnowC", 0.16, Vector3.new(0, 5.6, 0.4), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
	elseif kind == "crown" then
		part(model, "CrownBand", Vector3.new(1.9, 0.5, 1.9), Vector3.new(0, 5.1, 0), gold, Enum.Material.Metal)
		for _, dx in ipairs({ -0.7, 0, 0.7 }) do
			part(model, "CrownSpike", Vector3.new(0.4, 0.7, 0.4), Vector3.new(dx, 5.65, 0.7), gold, Enum.Material.Metal)
			part(model, "CrownSpike", Vector3.new(0.4, 0.7, 0.4), Vector3.new(dx, 5.65, -0.7), gold, Enum.Material.Metal)
		end
	elseif kind == "screen" then
		part(model, "Screen", Vector3.new(1.7, 1.2, 0.2), Vector3.new(0, 2.4, -0.8), Color3.fromRGB(20, 30, 26), Enum.Material.SmoothPlastic)
		part(model, "ScreenGlow", Vector3.new(1.4, 0.9, 0.1), Vector3.new(0, 2.4, -0.92), Color3.fromRGB(140, 255, 190), Enum.Material.Neon)
	elseif kind == "wings" then
		for _, side in ipairs({ -1, 1 }) do
			local w = part(model, "Wing", Vector3.new(1.8, 1.1, 0.16), Vector3.new(side * 1.8, 3.4, 0.6), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
			w.CFrame = CFrame.new(side * 1.8, 3.4, 0.6) * CFrame.Angles(0, 0, side * math.rad(-18))
		end
	elseif kind == "halo" then
		local halo = Instance.new("Part")
		halo.Name = "Halo"
		halo.Shape = Enum.PartType.Cylinder
		halo.Size = Vector3.new(0.22, 2.2, 2.2)
		halo.CFrame = CFrame.new(0, 5.6, 0) * CFrame.Angles(0, 0, math.rad(90))
		halo.Color = gold
		halo.Material = Enum.Material.Neon
		halo.Anchored = true
		halo.CanCollide = false
		halo.Parent = model
	end
end

local function mutationVisual(mutationName, bodyPart, trimPart)
	if mutationName == "Gold" then
		bodyPart.Color = Color3.fromRGB(255, 205, 48)
		bodyPart.Material = Enum.Material.Metal
		trimPart.Color = Color3.fromRGB(255, 230, 120)
	elseif mutationName == "Diamond" then
		bodyPart.Color = Color3.fromRGB(150, 240, 255)
		bodyPart.Material = Enum.Material.Glass
		trimPart.Color = Color3.fromRGB(220, 255, 255)
	elseif mutationName == "Rainbow" then
		bodyPart.Color = Color3.fromRGB(255, 110, 220)
		bodyPart.Material = Enum.Material.Neon
		trimPart.Color = Color3.fromRGB(140, 255, 170)
	end
end

-- Build a character standing at the origin on ground height 0.
-- Returns the Model; set its label with SetLabel before showing prices.
function BrainrotFactory.Create(def, mutationName)
	local model = Instance.new("Model")
	model.Name = "Brainrot_" .. def.Id
	local root = part(model, "Root", Vector3.new(2, 2, 1), Vector3.new(0, BrainrotFactory.ROOT_LIFT, 0), Color3.fromRGB(255, 255, 255))
	root.Transparency = 1
	local body = part(model, "Body", Vector3.new(2.2, 2.4, 1.4), Vector3.new(0, 2.2, 0), def.Body, Enum.Material.SmoothPlastic)
	part(model, "Belly", Vector3.new(1.6, 1.5, 0.3), Vector3.new(0, 2, -0.72), def.Accent, Enum.Material.SmoothPlastic)
	local head = part(model, "Head", Vector3.new(1.7, 1.5, 1.5), Vector3.new(0, 4.15, 0), def.Accent, Enum.Material.SmoothPlastic)
	-- Eyes and a grin on the -Z face (the way the character walks).
	ball(model, "EyeL", 0.14, Vector3.new(-0.38, 4.35, -0.78), Color3.fromRGB(20, 20, 24))
	ball(model, "EyeR", 0.14, Vector3.new(0.38, 4.35, -0.78), Color3.fromRGB(20, 20, 24))
	part(model, "Grin", Vector3.new(0.8, 0.16, 0.1), Vector3.new(0, 3.85, -0.78), Color3.fromRGB(20, 20, 24))
	-- Little feet so the walk cycle reads from a distance.
	part(model, "FootL", Vector3.new(0.8, 0.4, 1.2), Vector3.new(-0.55, 0.2, -0.1), def.Accent)
	part(model, "FootR", Vector3.new(0.8, 0.4, 1.2), Vector3.new(0.55, 0.2, -0.1), def.Accent)
	addAccessory(model, def.Accessory, def.Accent, def.Body)
	if mutationName and mutationName ~= "Normal" then
		mutationVisual(mutationName, body, head)
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(220, 74)
	gui.StudsOffset = Vector3.new(0, 2.1, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	gui.Parent = head
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 0.35
	text.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.Parent = gui
	model.PrimaryPart = root
	model:SetAttribute("DefId", def.Id)
	model:SetAttribute("Rarity", def.Rarity)
	if mutationName then
		model:SetAttribute("Mutation", mutationName)
	end
	return model
end

function BrainrotFactory.SetLabel(model, line1, line2, color)
	local head = model:FindFirstChild("Head")
	local gui = head and head:FindFirstChild("Label")
	local text = gui and gui:FindFirstChild("Text")
	if text then
		text.Text = line2 and (line1 .. "\n" .. line2) or line1
		if color then
			text.TextColor3 = color
		end
	end
end

function BrainrotFactory.LabelFor(model, title, sub)
	BrainrotFactory.SetLabel(model, title, sub)
end

-- A burst of procedural sparkle parts, used when a Divine spawns.
function BrainrotFactory.SparkleBurst(position)
	local folder = Instance.new("Folder")
	folder.Name = "DivineSparkles"
	folder.Parent = workspace
	local rng = Random.new()
	local bits = {}
	local colors = { Color3.fromRGB(255, 240, 160), Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 150, 220) }
	for i = 1, 14 do
		local bit = Instance.new("Part")
		bit.Name = "Sparkle" .. i
		bit.Shape = Enum.PartType.Ball
		bit.Size = Vector3.new(0.45, 0.45, 0.45)
		bit.Color = colors[(i % #colors) + 1]
		bit.Material = Enum.Material.Neon
		bit.Anchored = true
		bit.CanCollide = false
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(0.6, 2.6)
		bit.Position = position + Vector3.new(math.cos(a) * r, rng:NextNumber(0.4, 2.4), math.sin(a) * r)
		bit.Parent = folder
		table.insert(bits, bit)
	end
	task.spawn(function()
		for step = 1, 12 do
			for _, bit in ipairs(bits) do
				bit.Position += Vector3.new(0, 0.22, 0)
				bit.Transparency = step / 12
			end
			task.wait(0.05)
		end
		folder:Destroy()
	end)
	return folder
end

-- The thief NPC: a shady character in black with a mask band and a
-- loot sack, built from the same part kit as the brainrots.
function BrainrotFactory.CreateThief()
	local model = Instance.new("Model")
	model.Name = "ThiefNPC"
	local root = part(model, "Root", Vector3.new(2, 2, 1), Vector3.new(0, BrainrotFactory.ROOT_LIFT, 0), Color3.fromRGB(30, 30, 36))
	root.Transparency = 1
	part(model, "Body", Vector3.new(2.2, 2.4, 1.4), Vector3.new(0, 2.2, 0), Color3.fromRGB(34, 34, 42), Enum.Material.SmoothPlastic)
	local head = part(model, "Head", Vector3.new(1.7, 1.5, 1.5), Vector3.new(0, 4.15, 0), Color3.fromRGB(232, 190, 150), Enum.Material.SmoothPlastic)
	part(model, "Mask", Vector3.new(1.75, 0.5, 1.55), Vector3.new(0, 4.35, 0), Color3.fromRGB(12, 12, 16), Enum.Material.SmoothPlastic)
	ball(model, "EyeL", 0.13, Vector3.new(-0.38, 4.38, -0.78), Color3.fromRGB(255, 255, 255))
	ball(model, "EyeR", 0.13, Vector3.new(0.38, 4.38, -0.78), Color3.fromRGB(255, 255, 255))
	part(model, "FootL", Vector3.new(0.8, 0.4, 1.2), Vector3.new(-0.55, 0.2, -0.1), Color3.fromRGB(20, 20, 26))
	part(model, "FootR", Vector3.new(0.8, 0.4, 1.2), Vector3.new(0.55, 0.2, -0.1), Color3.fromRGB(20, 20, 26))
	local sack = ball(model, "LootSack", 0.85, Vector3.new(0, 2.9, 0.95), Color3.fromRGB(140, 110, 70), Enum.Material.Fabric)
	sack.Name = "LootSack"
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(200, 60)
	gui.StudsOffset = Vector3.new(0, 2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 110
	gui.Parent = head
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 0.35
	text.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	text.TextColor3 = Color3.fromRGB(255, 90, 90)
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.Parent = gui
	model.PrimaryPart = root
	return model
end

return BrainrotFactory
