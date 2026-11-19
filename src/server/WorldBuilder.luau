-- WorldBuilder.luau -- builds the whole Brainrot Bazaar map procedurally.
-- No external assets: every part is created here, sitting ON the ground
-- (ground top surface is Y=0; each part's base is at Y=0 or on its slab).
-- Layout constants live in WorldBuilder.Layout so they can be audited.

local WorldBuilder = {}

WorldBuilder.Layout = {
	Fountain = { X = 0, Z = 44, BaseY = 0 },
	WheelHub = { X = -128, Z = -52, BaseY = 0, HubY = 26 },
	Tower = { X = 128, Z = -52, BaseY = 0, TopY = 44 },
	RainbowArch = { X = 0, Z = 58, BaseY = 0, PeakY = 12 },
	SpawnPad = { X = 0, Z = 26, BaseY = 0 },
	Plaza = { X = 0, Z = 44, BaseY = 0, Radius = 34 },
	BeltStart = { X = -70, Z = 0, BaseY = 0, TopY = 1.3 },
	BeltEnd = { X = 70, Z = 0, BaseY = 0, TopY = 1.3 },
	PlotCenters = {
		{ X = -102, Z = -84, BaseY = 0 }, { X = -34, Z = -84, BaseY = 0 },
		{ X = 34, Z = -84, BaseY = 0 }, { X = 102, Z = -84, BaseY = 0 },
		{ X = -102, Z = 84, BaseY = 0 }, { X = -34, Z = 84, BaseY = 0 },
		{ X = 34, Z = 84, BaseY = 0 }, { X = 102, Z = 84, BaseY = 0 },
	},
}

local BELT_TOP = 1.3

local function makePart(parent, name, size, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- A flat cylinder whose TOP surface is exactly topY (base sits lower).
local function flatCylinder(parent, name, radius, topY, x, z, color)
	local thickness = math.max(0.1, topY)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(thickness, radius * 2, radius * 2)
	p.Rotation = Vector3.new(0, 0, 90)
	p.Position = Vector3.new(x, topY - thickness / 2, z)
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function addText(board, text, face, textColor, textSize)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor or Color3.new(1, 1, 1)
	label.TextSize = textSize or 42
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = false
	label.Parent = gui
	return gui
end

-- A sign: two posts from the ground and a board whose CENTER is boardY.
local function makeSign(parent, name, x, z, boardY, width, text, boardColor)
	local postColor = Color3.fromRGB(120, 85, 50)
	for _, dx in ipairs({ -width / 2 + 0.6, width / 2 - 0.6 }) do
		makePart(parent, name .. "Post", Vector3.new(0.6, boardY, 0.6),
			Vector3.new(x + dx, boardY / 2, z), postColor, Enum.Material.Wood)
	end
	local board = makePart(parent, name .. "Board", Vector3.new(width, 3, 0.6),
		Vector3.new(x, boardY, z), boardColor, Enum.Material.WoodPlanks)
	addText(board, text, Enum.NormalId.Front, Color3.new(1, 1, 1))
	addText(board, text, Enum.NormalId.Back, Color3.new(1, 1, 1))
	return board
end

function WorldBuilder.Build()
	local world = Instance.new("Folder")
	world.Name = "BrainrotWorld"

	local refs = { Plots = {}, Stripes = {}, Lamps = {} }
	refs.BeltTopY = BELT_TOP
	refs.BeltStartX = -66
	refs.BeltEndX = 66
	refs.BeltZ = 0

	-- Ground: one big flat part, top surface exactly Y=0.
	makePart(world, "Ground", Vector3.new(380, 1, 300), Vector3.new(0, -0.5, 0),
		Color3.fromRGB(95, 205, 80), Enum.Material.Grass)

	-- Plaza disc, top Y=0.15.
	flatCylinder(world, "Plaza", 34, 0.15, 0, 44, Color3.fromRGB(245, 200, 120))

	-- Paths (top Y=0.06): plaza to belt, and out to both plot rows.
	local pathColor = Color3.fromRGB(200, 200, 200)
	makePart(world, "PathToBelt", Vector3.new(6, 0.06, 46), Vector3.new(0, 0.03, 23), pathColor, Enum.Material.Concrete)
	makePart(world, "PathRowSouth", Vector3.new(240, 0.06, 6), Vector3.new(0, 0.03, -62), pathColor, Enum.Material.Concrete)
	makePart(world, "PathRowNorth", Vector3.new(240, 0.06, 6), Vector3.new(0, 0.03, 62), pathColor, Enum.Material.Concrete)
	for _, px in ipairs({ -102, -34, 34, 102 }) do
		-- South legs run from the belt (Z=0) to the south row path (Z=-62);
		-- north legs run from the plaza edge (Z=44) to the north plots (Z=84).
		makePart(world, "PathSouth" .. px, Vector3.new(6, 0.06, 64), Vector3.new(px, 0.03, -32), pathColor, Enum.Material.Concrete)
		makePart(world, "PathNorth" .. px, Vector3.new(6, 0.06, 40), Vector3.new(px, 0.03, 64), pathColor, Enum.Material.Concrete)
	end

	-- Conveyor belt along X at Z=0, top surface Y=1.3, with side rails.
	local belt = makePart(world, "ConveyorBelt", Vector3.new(140, BELT_TOP, 10),
		Vector3.new(0, BELT_TOP / 2, 0), Color3.fromRGB(45, 45, 55), Enum.Material.Metal)
	refs.Belt = belt
	for _, rz in ipairs({ -4.8, 4.8 }) do
		makePart(world, "BeltRail", Vector3.new(140, 0.7, 0.5),
			Vector3.new(0, BELT_TOP + 0.35, rz), Color3.fromRGB(255, 170, 40), Enum.Material.Metal)
	end
	for i = 0, 13 do
		local stripe = makePart(world, "BeltStripe", Vector3.new(1.2, 0.06, 9),
			Vector3.new(-65 + i * 10, BELT_TOP + 0.03, 0), Color3.fromRGB(255, 220, 90), Enum.Material.Neon)
		stripe.CanCollide = false
		table.insert(refs.Stripes, stripe)
	end

	-- "TOKO BRAINROT" arch at X=-70: posts at Z=-7 and Z=7 up to Y=14,
	-- board across the top centered Y=13, spanning Z -8..8.
	for _, pz in ipairs({ -7, 7 }) do
		makePart(world, "ArchPost", Vector3.new(1, 14, 1), Vector3.new(-70, 7, pz),
			Color3.fromRGB(200, 60, 60), Enum.Material.Wood)
	end
	local archBoard = makePart(world, "ArchBoard", Vector3.new(1.2, 3, 16),
		Vector3.new(-70, 13, 0), Color3.fromRGB(255, 120, 60), Enum.Material.WoodPlanks)
	addText(archBoard, "TOKO BRAINROT", Enum.NormalId.Left, Color3.new(1, 1, 1), 48)
	addText(archBoard, "TOKO BRAINROT", Enum.NormalId.Right, Color3.new(1, 1, 1), 48)

	-- Spawn pad and welcome sign.
	flatCylinder(world, "SpawnPad", 5, 0.2, 0, 26, Color3.fromRGB(80, 200, 255))
	makeSign(world, "WelcomeSign", 0, 40, 9, 12, "SELAMAT DATANG DI BRAINROT BAZAAR!",
		Color3.fromRGB(60, 160, 255))

	WorldBuilder.BuildPlots(world, refs)
	WorldBuilder.BuildPlaza(world, refs)
	WorldBuilder.BuildAttractions(world, refs)
	WorldBuilder.BuildBillboards(world, refs)
	WorldBuilder.BuildScatter(world, refs)

	world.Parent = workspace
	refs.World = world
	return refs
end

function WorldBuilder.BuildPlots(world, refs)
	local plotNames = { "Basis A", "Basis B", "Basis C", "Basis D", "Basis E", "Basis F", "Basis G", "Basis H" }
	for i, c in ipairs(WorldBuilder.Layout.PlotCenters) do
		local plot = { Index = i, Center = Vector3.new(c.X, 0, c.Z), PadPositions = {}, PadParts = {} }
		local frontDir = (c.Z > 0) and -1 or 1 -- front edge faces the map centre
		plot.FrontDir = frontDir

		-- Base slab 44x30, top Y=0.25.
		makePart(world, "PlotSlab" .. i, Vector3.new(44, 0.25, 30),
			Vector3.new(c.X, 0.125, c.Z), Color3.fromRGB(230, 220, 190), Enum.Material.Concrete)

		-- 6 pads in 2 rows of 3, flat cylinders radius 2.6, top Y=0.45.
		local n = 0
		for _, dz in ipairs({ -7, 7 }) do
			for _, dx in ipairs({ -13, 0, 13 }) do
				n += 1
				local pad = flatCylinder(world, "Pad" .. i .. "_" .. n, 2.6, 0.45,
					c.X + dx, c.Z + dz, Color3.fromRGB(255, 240, 200))
				pad:SetAttribute("PlotIndex", i)
				pad:SetAttribute("PadIndex", n)
				plot.PadParts[n] = pad
				plot.PadPositions[n] = Vector3.new(c.X + dx, 0.45, c.Z + dz)
			end
		end

		-- Green collect pad (5x5, top Y=0.45) at the front edge.
		local collect = makePart(world, "CollectPad" .. i, Vector3.new(5, 0.2, 5),
			Vector3.new(c.X, 0.35, c.Z + frontDir * 12), Color3.fromRGB(60, 220, 90), Enum.Material.Neon)
		collect:SetAttribute("PlotIndex", i)
		plot.CollectPad = collect

		-- Lock button on a post at the front corner.
		makePart(world, "LockPost" .. i, Vector3.new(0.5, 2.6, 0.5),
			Vector3.new(c.X + 18, 1.3, c.Z + frontDir * 12), Color3.fromRGB(90, 90, 90), Enum.Material.Metal)
		local lockBtn = makePart(world, "LockButton" .. i, Vector3.new(1.4, 0.6, 1.4),
			Vector3.new(c.X + 18, 2.9, c.Z + frontDir * 12), Color3.fromRGB(255, 80, 80), Enum.Material.Neon)
		lockBtn:SetAttribute("PlotIndex", i)
		plot.LockButton = lockBtn

		-- Lock shield: a translucent dome-wall over the pads, hidden until locked.
		local shield = makePart(world, "LockShield" .. i, Vector3.new(42, 7, 28),
			Vector3.new(c.X, 3.75, c.Z), Color3.fromRGB(90, 180, 255), Enum.Material.Glass)
		shield.Transparency = 1
		shield.CanCollide = false
		plot.LockShield = shield

		makeSign(world, "PlotSign" .. i, c.X - 13, c.Z + frontDir * 13, 8, 11,
			plotNames[i], Color3.fromRGB(120, 90, 200))
		refs.Plots[i] = plot
	end
end

function WorldBuilder.BuildPlaza(world, refs)
	-- Fountain at (0,44): basin rim top Y=1.2, column to Y=6, water at 1.35.
	local basin = Instance.new("Part")
	basin.Name = "FountainBasin"
	basin.Shape = Enum.PartType.Cylinder
	basin.Size = Vector3.new(1.2, 18, 18)
	basin.Rotation = Vector3.new(0, 0, 90)
	basin.Position = Vector3.new(0, 0.6, 44)
	basin.Color = Color3.fromRGB(170, 200, 230)
	basin.Material = Enum.Material.Marble
	basin.Anchored = true
	basin.Parent = world
	makePart(world, "FountainColumn", Vector3.new(2, 6, 2), Vector3.new(0, 3, 44),
		Color3.fromRGB(170, 200, 230), Enum.Material.Marble)
	local water = flatCylinder(world, "FountainWater", 7.5, 1.35, 0, 44, Color3.fromRGB(80, 190, 255))
	water.Material = Enum.Material.Glass
	water.Transparency = 0.3
	water.CanCollide = false
	refs.WaterDisc = water
	refs.FountainPos = Vector3.new(0, 0, 44)

	-- 4 market stalls facing the plaza.
	for _, s in ipairs({ { -16, 62 }, { 16, 62 }, { -16, 26 }, { 16, 26 } }) do
		local sx, sz = s[1], s[2]
		local stall = Instance.new("Folder")
		stall.Name = "MarketStall"
		stall.Parent = world
		makePart(stall, "Counter", Vector3.new(10, 1.6, 4), Vector3.new(sx, 0.8, sz),
			Color3.fromRGB(160, 110, 70), Enum.Material.Wood)
		for _, px in ipairs({ -4.5, 4.5 }) do
			for _, pz in ipairs({ -1.8, 1.8 }) do
				makePart(stall, "StallPost", Vector3.new(0.4, 5, 0.4),
					Vector3.new(sx + px, 2.5, sz + pz), Color3.fromRGB(120, 85, 50), Enum.Material.Wood)
			end
		end
		local awning = makePart(stall, "Awning", Vector3.new(11, 0.3, 5.5),
			Vector3.new(sx, 5.2, sz), Color3.fromRGB(255, 90, 90), Enum.Material.Fabric)
		awning.Rotation = Vector3.new(math.rad(10), 0, 0)
	end

	-- Gacha machine on the plaza edge: base, glass dome and a crank.
	local gacha = Instance.new("Model")
	gacha.Name = "GachaMachine"
	gacha.Parent = world
	local base = makePart(gacha, "GachaBase", Vector3.new(4, 3, 4), Vector3.new(22, 1.5, 58),
		Color3.fromRGB(255, 80, 160), Enum.Material.Metal)
	local dome = Instance.new("Part")
	dome.Name = "GachaDome"
	dome.Shape = Enum.PartType.Ball
	dome.Size = Vector3.new(4.4, 4.4, 4.4)
	dome.Position = Vector3.new(22, 5.2, 58)
	dome.Color = Color3.fromRGB(200, 240, 255)
	dome.Material = Enum.Material.Glass
	dome.Transparency = 0.35
	dome.Anchored = true
	dome.Parent = gacha
	makePart(gacha, "GachaCrank", Vector3.new(0.5, 1.6, 0.5), Vector3.new(24.4, 1.6, 58),
		Color3.fromRGB(255, 210, 60), Enum.Material.Metal)
	gacha.PrimaryPart = base
	refs.GachaMachine = base
	refs.GachaPos = Vector3.new(22, 0, 58)
end

function WorldBuilder.BuildAttractions(world, refs)
	-- Ferris wheel "BIANGLALA BRAINROT" at (-128,-52), hub Y=26, ring
	-- radius 20 in the YZ plane at X=-128, rotating around the X axis.
	local hubPos = Vector3.new(-128, 26, -52)
	for _, dz in ipairs({ -9, 9 }) do
		local leg = makePart(world, "WheelLeg", Vector3.new(1.6, 30, 1.6),
			Vector3.new(-128, 13, -52 + dz * 0.55), Color3.fromRGB(255, 130, 180), Enum.Material.Metal)
		leg.Rotation = Vector3.new(math.rad(dz > 0 and -20 or 20), 0, 0)
	end
	local wheel = Instance.new("Model")
	wheel.Name = "FerrisWheel"
	wheel.Parent = world
	local hub = Instance.new("Part")
	hub.Name = "WheelHub"
	hub.Shape = Enum.PartType.Cylinder
	hub.Size = Vector3.new(3, 4, 4)
	hub.Position = hubPos
	hub.Color = Color3.fromRGB(255, 210, 60)
	hub.Material = Enum.Material.Metal
	hub.Anchored = true
	hub.Parent = wheel
	wheel.PrimaryPart = hub
	local podPalette = {
		Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 170, 60),
		Color3.fromRGB(255, 240, 90), Color3.fromRGB(120, 220, 120),
		Color3.fromRGB(90, 180, 255), Color3.fromRGB(180, 120, 255),
		Color3.fromRGB(255, 110, 200), Color3.fromRGB(120, 240, 220),
	}
	for seg = 0, 11 do
		local a = math.rad(seg * 30)
		local y = hubPos.Y + math.cos(a) * 20
		local z = hubPos.Z + math.sin(a) * 20
		local rim = makePart(wheel, "WheelRim", Vector3.new(0.8, 10.6, 0.8),
			Vector3.new(-128, y, z), Color3.fromRGB(255, 130, 180), Enum.Material.Metal)
		rim.Rotation = Vector3.new(-a, 0, 0)
	end
	for pod = 0, 7 do
		local a = math.rad(pod * 45)
		local y = hubPos.Y + math.cos(a) * 20
		local z = hubPos.Z + math.sin(a) * 20
		makePart(wheel, "WheelPod", Vector3.new(3, 3, 3), Vector3.new(-128, y, z),
			podPalette[pod + 1], Enum.Material.SmoothPlastic)
	end
	refs.Wheel = wheel
	refs.WheelHubPos = hubPos
	makeSign(world, "WheelSign", -112, -40, 8, 13, "BIANGLALA BRAINROT", Color3.fromRGB(255, 130, 180))

	-- Tower "MENARA BRAINROT" at (128,-52): tapering boxes Y 0..44, beacon Y=47.
	local widths = { 18, 15, 12, 9, 6 }
	local heights = { 9, 9, 9, 9, 8 }
	local y = 0
	for i = 1, 5 do
		makePart(world, "TowerTier" .. i, Vector3.new(widths[i], heights[i], widths[i]),
			Vector3.new(128, y + heights[i] / 2, -52),
			Color3.fromRGB(140 + i * 18, 120, 220 - i * 12), Enum.Material.Brick)
		y += heights[i]
	end
	makePart(world, "BeaconPole", Vector3.new(0.5, 1.5, 0.5), Vector3.new(128, 44.75, -52),
		Color3.fromRGB(80, 80, 80), Enum.Material.Metal)
	local beacon = Instance.new("Part")
	beacon.Name = "TowerBeacon"
	beacon.Shape = Enum.PartType.Ball
	beacon.Size = Vector3.new(4, 4, 4)
	beacon.Position = Vector3.new(128, 47, -52)
	beacon.Color = Color3.fromRGB(255, 80, 80)
	beacon.Material = Enum.Material.Neon
	beacon.Anchored = true
	beacon.Parent = world
	refs.Beacon = beacon
	makeSign(world, "TowerSign", 112, -40, 8, 13, "MENARA BRAINROT", Color3.fromRGB(140, 120, 220))

	-- Rainbow arch over the spawn path at (0,58): 7 rotated box segments
	-- from (-10,58) up to Y=12 and back down to (10,58).
	local rainbow = {
		Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 150, 40), Color3.fromRGB(255, 230, 60),
		Color3.fromRGB(80, 220, 90), Color3.fromRGB(70, 160, 255), Color3.fromRGB(130, 90, 255),
		Color3.fromRGB(255, 110, 220),
	}
	for i = 0, 6 do
		local t0 = i / 7
		local t1 = (i + 1) / 7
		local x0, y0 = -10 + 20 * t0, 12 * math.sin(math.pi * t0)
		local x1, y1 = -10 + 20 * t1, 12 * math.sin(math.pi * t1)
		local mid = Vector3.new((x0 + x1) / 2, (y0 + y1) / 2 + 0.4, 58)
		local len = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2) + 0.6
		local seg = makePart(world, "RainbowSeg" .. i, Vector3.new(len, 1.4, 1.4), mid,
			rainbow[i + 1], Enum.Material.Neon)
		seg.Rotation = Vector3.new(0, 0, math.atan2(y1 - y0, x1 - x0))
		seg.CanCollide = false
	end
end

function WorldBuilder.BuildBillboards(world, refs)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
	local xs = { -60, -36, -12, 12, 36, 60 }
	for i, rarity in ipairs(BrainrotData.RarityOrder) do
		makeSign(world, "RarityBoard" .. rarity, xs[i], 14, 7, 10,
			string.upper(rarity), BrainrotData.RarityColors[rarity])
	end
end

function WorldBuilder.BuildScatter(world, refs)
	-- 14 trees and 8 rocks spread along the map edges, clear of the action.
	local treeSpots = {
		{ -170, -130 }, { 170, -130 }, { -170, 130 }, { 170, 130 }, { -160, 0 }, { 160, 30 },
		{ -60, 135 }, { 60, -135 }, { 125, 135 }, { -125, -135 }, { 178, -70 }, { -178, 70 },
		{ 45, 138 }, { -45, -138 },
	}
	for i, s in ipairs(treeSpots) do
		local trunk = Instance.new("Part")
		trunk.Name = "TreeTrunk" .. i
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(4, 1.4, 1.4)
		trunk.Position = Vector3.new(s[1], 2, s[2])
		trunk.Color = Color3.fromRGB(130, 90, 55)
		trunk.Material = Enum.Material.Wood
		trunk.Anchored = true
		trunk.Parent = world
		local foliage = Instance.new("Part")
		foliage.Name = "TreeFoliage" .. i
		foliage.Shape = Enum.PartType.Ball
		foliage.Size = Vector3.new(7, 7, 7)
		foliage.Position = Vector3.new(s[1], 6, s[2])
		foliage.Color = Color3.fromRGB(60, 170, 70)
		foliage.Material = Enum.Material.Grass
		foliage.Anchored = true
		foliage.Parent = world
	end
	local rockSpots = {
		{ -150, -100 }, { 150, 100 }, { -90, 138 }, { 90, -138 },
		{ 178, 90 }, { -178, -90 }, { 30, -140 }, { -30, 142 },
	}
	for i, s in ipairs(rockSpots) do
		local rock = Instance.new("Part")
		rock.Name = "Rock" .. i
		rock.Shape = Enum.PartType.Ball
		rock.Size = Vector3.new(3.5, 2.6, 3.5)
		rock.Position = Vector3.new(s[1], 0.8, s[2])
		rock.Color = Color3.fromRGB(140, 140, 145)
		rock.Material = Enum.Material.Slate
		rock.Anchored = true
		rock.Parent = world
	end
	-- 10 lamp posts along the paths: post to Y=7 plus a glowing sphere.
	local lampSpots = {
		{ 6, 10 }, { -6, 76 }, { 30, 44 }, { -30, 44 }, { 70, -62 },
		{ -70, 62 }, { 102, -62 }, { -102, 62 }, { 34, -20 }, { -34, 108 },
	}
	for i, s in ipairs(lampSpots) do
		makePart(world, "LampPost" .. i, Vector3.new(0.4, 7, 0.4), Vector3.new(s[1], 3.5, s[2]),
			Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
		local bulb = Instance.new("Part")
		bulb.Name = "LampBulb" .. i
		bulb.Shape = Enum.PartType.Ball
		bulb.Size = Vector3.new(1.4, 1.4, 1.4)
		bulb.Position = Vector3.new(s[1], 7.4, s[2])
		bulb.Color = Color3.fromRGB(255, 240, 170)
		bulb.Material = Enum.Material.Neon
		bulb.Anchored = true
		bulb.CanCollide = false
		bulb.Parent = world
		table.insert(refs.Lamps, bulb)
	end
end

-- Is a ground position inside a plot's slab rectangle (44 x 30)?
-- The tsunami uses this: inside any base means safe ground.
function WorldBuilder.PositionInPlot(refs, plotIndex, pos)
	local plot = refs.Plots[plotIndex]
	if not plot then
		return false
	end
	return math.abs(pos.X - plot.Center.X) <= 22 and math.abs(pos.Z - plot.Center.Z) <= 15
end

function WorldBuilder.PositionInAnyPlot(refs, pos)
	for i = 1, #refs.Plots do
		if WorldBuilder.PositionInPlot(refs, i, pos) then
			return true
		end
	end
	return false
end

return WorldBuilder
