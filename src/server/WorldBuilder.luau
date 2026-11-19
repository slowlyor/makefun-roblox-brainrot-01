-- WorldBuilder: builds the whole Brainrot Bazaar world procedurally at runtime.
-- Ground top surface is Y=0. EVERY part/model sits ON the ground (base at Y=0,
-- never below); signs sit on posts with the board centre at the stated height.

local WorldBuilder = {}

-- Layout constants (the single source of truth; the sanity list reads these).
WorldBuilder.Layout = {
	ground = { xMin = -190, xMax = 190, zMin = -150, zMax = 150 },
	plaza = { x = 0, z = 44, radius = 34 },
	belt = { xMin = -70, xMax = 70, z = 0, width = 10, topY = 1.3 },
	spawnPad = { x = 0, z = 26, radius = 5 },
	welcomeSign = { x = 0, z = 40, boardY = 9 },
	plotXs = { -102, -34, 34, 102 },
	plotZs = { -84, 84 },
	plotSlab = { w = 44, d = 30, topY = 0.25 },
	fountain = { x = 0, z = 44 },
	wheel = { x = -128, z = -52, hubY = 26, radius = 20, signX = -112, signZ = -40 },
	tower = { x = 128, z = -52, topY = 44, beaconY = 47, signX = 112, signZ = -40 },
	rainbowArch = { x = 0, z = 58, topY = 12 },
	billboardZ = 14,
	billboardXs = { -60, -36, -12, 12, 36, 60 },
	gacha = { x = 24, z = 44 },
}

local function part(parent, name, size, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = true
	p.Parent = parent
	return p
end

local function cyl(parent, name, height, diameter, pos, color, material)
	-- A vertical cylinder: Roblox cylinders run along X, so rotate 90 deg about Z.
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, diameter, diameter)
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = true
	p.Parent = parent
	return p
end

local function ball(parent, name, diameter, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(diameter, diameter, diameter)
	p.Position = pos
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = true
	p.Parent = parent
	return p
end

local function signBoard(parent, name, pos, size, text, bg, fg)
	local board = part(parent, name, size, pos, bg, Enum.Material.Wood)
	local gui = Instance.new("BillboardGui")
	gui.Name = "SignGui"
	gui.Size = UDim2.fromOffset(220, 80)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
	gui.AlwaysOnTop = false
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = fg
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = gui
	return board
end

-- Two posts plus a board whose centre is at boardY.
local function signOnPosts(parent, name, x, z, boardY, boardW, boardH, text, bg, fg)
	local postH = boardY - boardH / 2
	local postY = postH / 2
	part(parent, name .. "PostL", Vector3.new(0.8, postH, 0.8), Vector3.new(x - boardW / 2 + 0.6, postY, z), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
	part(parent, name .. "PostR", Vector3.new(0.8, postH, 0.8), Vector3.new(x + boardW / 2 - 0.6, postY, z), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
	return signBoard(parent, name, Vector3.new(x, boardY, z), Vector3.new(boardW, boardH, 0.8), text, bg, fg)
end

local function flatPath(parent, name, x, z, w, d)
	-- 0.06 thick, base exactly on the ground, top at Y=0.06.
	return part(parent, name, Vector3.new(w, 0.06, d), Vector3.new(x, 0.03, z), Color3.fromRGB(200, 200, 205), Enum.Material.Slate)
end

function WorldBuilder.build()
	local L = WorldBuilder.Layout
	local world = Instance.new("Folder")
	world.Name = "World"

	-- Ground: one big flat part, top at Y=0 (size Y=1, centre Y=-0.5).
	part(world, "Ground", Vector3.new(380, 1, 300), Vector3.new(0, -0.5, 0), Color3.fromRGB(80, 200, 90), Enum.Material.Grass)

	-- Plaza disc: flat cylinder, 0.15 thick, base on the ground, top Y=0.15.
	cyl(world, "Plaza", 0.15, 68, Vector3.new(L.plaza.x, 0.075, L.plaza.z), Color3.fromRGB(220, 210, 190), Enum.Material.Concrete)

	-- Light-gray path strips (top Y=0.06) from plaza to belt and to each plot row.
	flatPath(world, "PathPlazaBelt", 0, 22, 10, 44)
	flatPath(world, "PathPlazaNorth", 0, 66, 10, 44)
	for _, px in ipairs(L.plotXs) do
		flatPath(world, "PathPlot" .. px .. "N", px, -56, 10, 56)
		flatPath(world, "PathPlot" .. px .. "S", px, 56, 10, 56)
	end

	-- Conveyor belt along X at Z=0, X -70..70, belt top Y=1.3, base on the ground.
	local belt = part(world, "Belt", Vector3.new(140, 1.3, 10), Vector3.new(0, 0.65, 0), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
	belt.Name = "Belt"
	part(world, "BeltRailN", Vector3.new(140, 0.8, 0.6), Vector3.new(0, 1.7, -5.2), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
	part(world, "BeltRailS", Vector3.new(140, 0.8, 0.6), Vector3.new(0, 1.7, 5.2), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
	-- Belt chevrons: small raised strips so the belt reads as moving.
	for x = -66, 66, 12 do
		part(world, "BeltChevron", Vector3.new(1.2, 0.15, 8), Vector3.new(x, 1.35, 0), Color3.fromRGB(255, 220, 80), Enum.Material.Neon)
	end

	-- 'TOKO BRAINROT' arch at X=-70: posts at Z=-7 and Z=7 up to Y=14, board centre Y=13.
	part(world, "ShopArchPostN", Vector3.new(1.2, 14, 1.2), Vector3.new(-70, 7, -7), Color3.fromRGB(200, 60, 90), Enum.Material.Wood)
	part(world, "ShopArchPostS", Vector3.new(1.2, 14, 1.2), Vector3.new(-70, 7, 7), Color3.fromRGB(200, 60, 90), Enum.Material.Wood)
	signBoard(world, "ShopArchBoard", Vector3.new(-70, 13, 0), Vector3.new(1.5, 4, 16), "TOKO BRAINROT", Color3.fromRGB(255, 90, 130), Color3.fromRGB(255, 255, 255))

	-- Spawn pad (0, 26): flat cylinder radius 5, 0.2 thick, base on the ground, top Y=0.2.
	-- It IS the SpawnLocation.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnPad"
	spawn.Shape = Enum.PartType.Cylinder
	spawn.Size = Vector3.new(0.2, 10, 10)
	spawn.CFrame = CFrame.new(0, 0.1, 26) * CFrame.Angles(0, 0, math.rad(90))
	spawn.Color = Color3.fromRGB(255, 220, 80)
	spawn.Material = Enum.Material.Neon
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = world

	-- Welcome sign on two posts at (0, 40), board centre Y=9.
	signOnPosts(world, "WelcomeSign", 0, 40, 9, 12, 3, "SELAMAT DATANG DI BRAINROT BAZAAR", Color3.fromRGB(255, 180, 40), Color3.fromRGB(60, 30, 0))

	-- 8 plots: base slab 44x30 (top Y=0.25), 6 pads in 2 rows of 3, collect pad,
	-- lock button post, plot sign (board centre Y=8).
	local plots = {}
	local plotIndex = 0
	for _, pz in ipairs(L.plotZs) do
		for _, px in ipairs(L.plotXs) do
			plotIndex = plotIndex + 1
			local dir = 1
			if pz > 0 then dir = -1 end -- front edge faces the map centre
			local frontZ = pz + dir * 13
			local backZ = pz - dir * 13
			local folder = Instance.new("Folder")
			folder.Name = "Plot" .. plotIndex
			folder.Parent = world
			part(folder, "Slab", Vector3.new(44, 0.5, 30), Vector3.new(px, 0, pz), Color3.fromRGB(150, 150, 160), Enum.Material.Concrete)
			local pads = {}
			for row = 1, 2 do
				for col = 1, 3 do
					local padX = px + (col - 2) * 12
					local padZ = pz + (row - 1.5) * 14
					local pad = cyl(folder, "Pad" .. ((row - 1) * 3 + col), 0.4, 5.2, Vector3.new(padX, 0.25, padZ), Color3.fromRGB(120, 200, 255), Enum.Material.Neon)
					pad.CanCollide = false
					table.insert(pads, pad)
				end
			end
			local collect = part(folder, "CollectPad", Vector3.new(5, 0.4, 5), Vector3.new(px, 0.25, frontZ), Color3.fromRGB(60, 220, 90), Enum.Material.Neon)
			collect.Name = "CollectPad"
			local lockPost = part(folder, "LockPost", Vector3.new(1, 4, 1), Vector3.new(px + 20, 2, frontZ), Color3.fromRGB(200, 60, 60), Enum.Material.Metal)
			lockPost.Name = "LockPost"
			local lockBtn = part(folder, "LockButton", Vector3.new(1.6, 1, 1.6), Vector3.new(px + 20, 4.4, frontZ), Color3.fromRGB(255, 60, 60), Enum.Material.Neon)
			lockBtn.Name = "LockButton"
			signOnPosts(folder, "PlotSign" .. plotIndex, px, backZ, 8, 14, 3, "BASE " .. plotIndex, Color3.fromRGB(70, 140, 255), Color3.fromRGB(255, 255, 255))
			table.insert(plots, {
				index = plotIndex,
				center = Vector3.new(px, 0, pz),
				slabMinX = px - 22, slabMaxX = px + 22,
				slabMinZ = pz - 15, slabMaxZ = pz + 15,
				pads = pads,
				collectPad = collect,
				lockButton = lockBtn,
				folder = folder,
			})
		end
	end

	-- Plaza fountain at (0, 44): basin rim top Y=1.2, column to Y=6, water disc at Y=1.35.
	cyl(world, "FountainBasin", 1.2, 18, Vector3.new(0, 0.6, 44), Color3.fromRGB(120, 160, 200), Enum.Material.Concrete)
	cyl(world, "FountainColumn", 6, 3, Vector3.new(0, 3, 44), Color3.fromRGB(200, 200, 210), Enum.Material.Marble)
	ball(world, "FountainTop", 3, Vector3.new(0, 6.8, 44), Color3.fromRGB(90, 180, 255), Enum.Material.Neon)
	local water = cyl(world, "FountainWater", 0.3, 15, Vector3.new(0, 1.35, 44), Color3.fromRGB(60, 160, 255), Enum.Material.Neon)
	water.CanCollide = false
	water.Transparency = 0.25

	-- 4 market stalls at (+/-16, 62) and (+/-16, 26), facing the plaza.
	local stallColors = {
		Color3.fromRGB(255, 90, 90),
		Color3.fromRGB(90, 200, 255),
		Color3.fromRGB(255, 200, 60),
		Color3.fromRGB(140, 220, 110),
	}
	local stallSpots = { { -16, 62 }, { 16, 62 }, { -16, 26 }, { 16, 26 } }
	for i, spot in ipairs(stallSpots) do
		local sx, sz = spot[1], spot[2]
		local stall = Instance.new("Folder")
		stall.Name = "Stall" .. i
		stall.Parent = world
		part(stall, "Counter", Vector3.new(6, 1.6, 3), Vector3.new(sx, 0.8, sz), Color3.fromRGB(160, 110, 60), Enum.Material.Wood)
		for _, ox in ipairs({ -2.5, 2.5 }) do
			for _, oz in ipairs({ -1.2, 1.2 }) do
				part(stall, "Post", Vector3.new(0.5, 5, 0.5), Vector3.new(sx + ox, 2.5, sz + oz), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
			end
		end
		local awning = part(stall, "Awning", Vector3.new(7, 0.3, 4), Vector3.new(sx, 5.2, sz), stallColors[i], Enum.Material.Fabric)
		awning.CFrame = CFrame.new(sx, 5.2, sz) * CFrame.Angles(math.rad(15), 0, 0)
		-- Goods on the counter: little coloured food boxes.
		for k = 1, 3 do
			part(stall, "Goods" .. k, Vector3.new(1, 1, 1), Vector3.new(sx - 2 + k * 1.6, 2.1, sz), Color3.fromRGB(255, 150 + k * 20, 80), Enum.Material.SmoothPlastic)
		end
	end

	-- Ferris wheel 'BIANGLALA BRAINROT' at (-128, -52): hub Y=26, ring radius 20
	-- in the YZ plane at X=-128, 8 pods, rotates slowly about the X axis.
	local wheel = Instance.new("Folder")
	wheel.Name = "FerrisWheel"
	wheel.Parent = world
	local legN = part(wheel, "LegN", Vector3.new(1.2, 26.4, 1.2), Vector3.new(-128, 13, -55), Color3.fromRGB(220, 220, 230), Enum.Material.Metal)
	legN.CFrame = CFrame.new(-128, 13, -55) * CFrame.Angles(math.rad(13), 0, 0)
	local legS = part(wheel, "LegS", Vector3.new(1.2, 26.4, 1.2), Vector3.new(-128, 13, -49), Color3.fromRGB(220, 220, 230), Enum.Material.Metal)
	legS.CFrame = CFrame.new(-128, 13, -49) * CFrame.Angles(math.rad(-13), 0, 0)
	local hub = cyl(wheel, "Hub", 2, 4, Vector3.new(-128, 26, -52), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
	hub.CFrame = CFrame.new(-128, 26, -52) * CFrame.Angles(0, 0, math.rad(90))
	local rimParts = {}
	local podColors = {
		Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 180, 40), Color3.fromRGB(120, 220, 90),
		Color3.fromRGB(70, 140, 255), Color3.fromRGB(170, 90, 230), Color3.fromRGB(255, 120, 200),
		Color3.fromRGB(90, 240, 230), Color3.fromRGB(255, 255, 255),
	}
	for i = 1, 8 do
		local angle = (i - 1) * math.rad(45)
		local rim = part(wheel, "Rim" .. i, Vector3.new(1, 2.5, 2.5), Vector3.new(-128, 26, -52), Color3.fromRGB(230, 230, 240), Enum.Material.Metal)
		rim.CanCollide = false
		local pod = part(wheel, "Pod" .. i, Vector3.new(3, 3, 3), Vector3.new(-128, 26, -52), podColors[i], Enum.Material.SmoothPlastic)
		pod.CanCollide = false
		table.insert(rimParts, { rim = rim, pod = pod, angle = angle })
	end
	signOnPosts(world, "WheelSign", -112, -40, 8, 16, 3, "BIANGLALA BRAINROT", Color3.fromRGB(255, 90, 130), Color3.fromRGB(255, 255, 255))

	-- Tower 'MENARA BRAINROT' at (128, -52): stacked tapering boxes Y=0 to 44, beacon Y=47.
	local tower = Instance.new("Folder")
	tower.Name = "Tower"
	tower.Parent = world
	local widths = { 16, 13, 10, 7, 4 }
	local heights = { 10, 9, 9, 8, 8 }
	local y = 0
	local towerColors = {
		Color3.fromRGB(90, 120, 200), Color3.fromRGB(120, 140, 220), Color3.fromRGB(150, 160, 235),
		Color3.fromRGB(180, 185, 245), Color3.fromRGB(210, 210, 255),
	}
	for i, w in ipairs(widths) do
		local h = heights[i]
		part(tower, "Level" .. i, Vector3.new(w, h, w), Vector3.new(128, y + h / 2, -52), towerColors[i], Enum.Material.Concrete)
		y = y + h
	end
	part(tower, "BeaconPole", Vector3.new(0.8, 1.5, 0.8), Vector3.new(128, 44.75, -52), Color3.fromRGB(80, 80, 80), Enum.Material.Metal)
	local beacon = ball(tower, "Beacon", 4, Vector3.new(128, 47, -52), Color3.fromRGB(255, 80, 80), Enum.Material.Neon)
	beacon.Name = "Beacon"
	signOnPosts(world, "TowerSign", 112, -40, 8, 16, 3, "MENARA BRAINROT", Color3.fromRGB(70, 140, 255), Color3.fromRGB(255, 255, 255))

	-- Rainbow arch over the spawn path at (0, 58): 7 segments from (-10, 58) up to Y=12.
	-- The end segments' centres sit at Y=1.75 (half their rotated height) so every
	-- segment's base is exactly on the ground; the top segment's centre is Y=12.
	local archColors = {
		Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 140, 40), Color3.fromRGB(255, 230, 60),
		Color3.fromRGB(90, 220, 90), Color3.fromRGB(60, 140, 255), Color3.fromRGB(120, 80, 220),
		Color3.fromRGB(220, 90, 200),
	}
	local archParts = {}
	for i = 1, 7 do
		local a = math.rad(180 - (i - 1) * 30)
		local ax = 10 * math.cos(a)
		local ay = 1.75 + 10.25 * math.sin(a)
		local seg = part(world, "RainbowSeg" .. i, Vector3.new(3.5, 1.2, 1.2), Vector3.new(ax, ay, 58), archColors[i], Enum.Material.Neon)
		seg.CFrame = CFrame.new(ax, ay, 58) * CFrame.Angles(0, 0, a - math.rad(90))
		table.insert(archParts, seg)
	end

	-- 6 rarity billboards on posts along the belt's south side, Z=14, board centre Y=7.
	local rarityNames = { "COMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC", "DIVINE" }
	local rarityBg = {
		Color3.fromRGB(120, 200, 90), Color3.fromRGB(70, 140, 255), Color3.fromRGB(170, 90, 230),
		Color3.fromRGB(255, 180, 30), Color3.fromRGB(255, 70, 120), Color3.fromRGB(90, 240, 230),
	}
	for i, bx in ipairs(L.billboardXs) do
		signOnPosts(world, "RarityBoard" .. rarityNames[i], bx, 14, 7, 10, 3, rarityNames[i], rarityBg[i], Color3.fromRGB(255, 255, 255))
	end

	-- Gacha machine in the plaza at (24, 44).
	local gacha = Instance.new("Folder")
	gacha.Name = "GachaMachine"
	gacha.Parent = world
	part(gacha, "Body", Vector3.new(4, 6, 3), Vector3.new(24, 3, 44), Color3.fromRGB(200, 60, 160), Enum.Material.Metal)
	local gachaBtn = part(gacha, "RollButton", Vector3.new(1.6, 1.6, 0.8), Vector3.new(24, 3, 42.3), Color3.fromRGB(255, 220, 40), Enum.Material.Neon)
	gachaBtn.Name = "RollButton"
	signBoard(gacha, "GachaSign", Vector3.new(24, 6.8, 44), Vector3.new(5, 1.6, 0.6), "GACHA!", Color3.fromRGB(255, 220, 40), Color3.fromRGB(120, 20, 90))
	local gachaClick = Instance.new("ClickDetector")
	gachaClick.MaxActivationDistance = 14
	gachaClick.Parent = gachaBtn

	-- Scatter: 14 trees and 8 rocks at spread edge coordinates, away from plots/belt/plaza.
	local treeSpots = {
		{ -170, -130 }, { -170, 130 }, { 170, -130 }, { 170, 130 },
		{ -170, 0 }, { 170, 0 }, { -150, -110 }, { 150, 110 },
		{ -150, 110 }, { 150, -110 }, { -60, -135 }, { 60, 135 },
		{ -60, 135 }, { 60, -135 },
	}
	for i, spot in ipairs(treeSpots) do
		local tx, tz = spot[1], spot[2]
		cyl(world, "TreeTrunk" .. i, 4, 1.6, Vector3.new(tx, 2, tz), Color3.fromRGB(120, 80, 40), Enum.Material.Wood)
		ball(world, "TreeTop" .. i, 5, Vector3.new(tx, 6, tz), Color3.fromRGB(50, 170, 70), Enum.Material.Leaf)
	end
	local rockSpots = {
		{ -180, -60 }, { 180, 60 }, { -180, 60 }, { 180, -60 },
		{ -140, 140 }, { 140, -140 }, { -40, -140 }, { 40, 140 },
	}
	for i, spot in ipairs(rockSpots) do
		-- Ball diameter 3, centre Y=1.5: base exactly on the ground.
		ball(world, "Rock" .. i, 3, Vector3.new(spot[1], 1.5, spot[2]), Color3.fromRGB(140, 140, 145), Enum.Material.Rock)
	end

	-- 10 lamp posts along the paths (post to Y=7 + glowing sphere).
	local lampSpots = {
		{ -8, 10 }, { 8, 10 }, { -8, 34 }, { 8, 34 }, { -8, 58 }, { 8, 58 },
		{ -8, -34 }, { 8, -34 }, { -8, 80 }, { 8, 80 },
	}
	for i, spot in ipairs(lampSpots) do
		local lx, lz = spot[1], spot[2]
		cyl(world, "LampPost" .. i, 7, 0.6, Vector3.new(lx, 3.5, lz), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
		local lamp = ball(world, "LampGlow" .. i, 1.6, Vector3.new(lx, 7.4, lz), Color3.fromRGB(255, 240, 150), Enum.Material.Neon)
		lamp.CanCollide = false
	end

	world.Parent = game:GetService("Workspace")

	return {
		world = world,
		plots = plots,
		beltTopY = L.belt.topY,
		beltXMin = L.belt.xMin,
		beltXMax = L.belt.xMax,
		fountainWater = water,
		wheelHub = Vector3.new(L.wheel.x, L.wheel.hubY, L.wheel.z),
		wheelRadius = L.wheel.radius,
		wheelParts = rimParts,
		beacon = beacon,
		archParts = archParts,
		gachaButton = gachaBtn,
	}
end

-- True when a world position is inside one of the 8 base slabs (tsunami shelter).
function WorldBuilder.isInsideAnyBase(plots, pos)
	for _, plot in ipairs(plots) do
		if pos.X >= plot.slabMinX and pos.X <= plot.slabMaxX
			and pos.Z >= plot.slabMinZ and pos.Z <= plot.slabMaxZ then
			return true
		end
	end
	return false
end

return WorldBuilder
