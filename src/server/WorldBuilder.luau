-- WorldBuilder.luau
-- Brainrot Bazaar: builds the whole 3D world out of plain parts.
-- Ground rule for every coordinate below: the ground's top surface is
-- Y=0 and every part or model sits ON it with its base at Y=0 or on the
-- slab/belt top it belongs to -- nothing is ever placed below Y=0.
-- All layout numbers live in WorldBuilder.Layout so the map in code is
-- the map in the report, word for word.

local WorldBuilder = {}

WorldBuilder.Layout = {
	GroundTopY = 0,
	GroundSizeX = 380, -- X -190..190
	GroundSizeZ = 300, -- Z -150..150
	Plaza = { X = 0, Z = 44, Radius = 34, TopY = 0.15 },
	Belt = { FromX = -70, ToX = 70, Z = 0, Width = 10, TopY = 1.3 },
	Arch = { X = -70, PostZ = 7, PostTopY = 14, BoardY = 13 },
	SpawnPad = { X = 0, Z = 26, Radius = 5, TopY = 0.2 },
	WelcomeSign = { X = 0, Z = 40, BoardY = 9 },
	PlotXs = { -102, -34, 34, 102 },
	PlotZs = { -84, 84 },
	PlotSlab = { SizeX = 44, SizeZ = 30, TopY = 0.25 },
	PadTopY = 0.45,
	PadRadius = 2.6,
	CollectPadTopY = 0.45,
	PlotSignY = 8,
	Fountain = { X = 0, Z = 44, BasinRadius = 9, RimTopY = 1.2, ColumnTopY = 6, WaterY = 1.35, WaterRadius = 7.5 },
	Stalls = { { X = -16, Z = 62 }, { X = 16, Z = 62 }, { X = -16, Z = 26 }, { X = 16, Z = 26 } },
	Wheel = { X = -128, Z = -52, HubY = 26, RingRadius = 20 },
	WheelSign = { X = -112, Z = -40, BoardY = 8 },
	Tower = { X = 128, Z = -52, TopY = 44, BeaconY = 47 },
	TowerSign = { X = 112, Z = -40, BoardY = 8 },
	RainbowArch = { X = 0, Z = 58, HalfWidth = 10, PeakY = 12 },
	BillboardZ = 14,
	BillboardXs = { -60, -36, -12, 12, 36, 60 },
	BillboardY = 7,
	Gacha = { X = 12, Z = 52 },
}

local L = WorldBuilder.Layout

local function newPart(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- A flat cylinder whose top face is exactly topY (base at topY-height).
local function newCylinder(parent, name, radius, height, centerX, topY, centerZ, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, radius * 2, radius * 2)
	p.CFrame = CFrame.new(centerX, topY - height / 2, centerZ) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function makeLabel(board, text, textColor, fontSize)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Parent = gui
	end
end

-- A sign: two posts from the ground plus a board centred at boardY.
local function makeSign(parent, name, centerX, centerZ, boardY, boardW, boardH, text, boardColor, postGap)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	local gap = postGap or (boardW / 2 - 0.6)
	for _, side in ipairs({ -1, 1 }) do
		newPart(model, "Post", Vector3.new(0.55, boardY, 0.55), CFrame.new(centerX + side * gap, boardY / 2, centerZ), Color3.fromRGB(101, 67, 33), Enum.Material.Wood)
	end
	local board = newPart(model, "Board", Vector3.new(boardW, boardH, 0.4), CFrame.new(centerX, boardY, centerZ), boardColor, Enum.Material.WoodPlanks)
	makeLabel(board, text, Color3.fromRGB(255, 255, 255))
	return model
end

local function buildGroundAndPaths(world)
	local ground = newPart(world, "Ground", Vector3.new(L.GroundSizeX, 1, L.GroundSizeZ), CFrame.new(0, -0.5, 0), Color3.fromRGB(86, 199, 74), Enum.Material.Grass)
	ground.Locked = true
	local plaza = newCylinder(world, "PlazaDisc", L.Plaza.Radius, 0.3, L.Plaza.X, L.Plaza.TopY, L.Plaza.Z, Color3.fromRGB(255, 214, 140), Enum.Material.Sand)
	plaza.Name = "PlazaDisc"
	local pathColor = Color3.fromRGB(196, 200, 205)
	local function path(name, cx, cz, sx, sz)
		newPart(world, name, Vector3.new(sx, 0.12, sz), CFrame.new(cx, 0, cz), pathColor, Enum.Material.Concrete)
	end
	path("PathPlazaToBelt", 0, 5, 8, 12)
	path("PathPlazaSouth", 0, 66, 8, 46)
	path("PathPlazaNorth", 0, -42, 8, 84)
	path("PathSouthRow", 0, 84, 268, 8)
	path("PathNorthRow", 0, -84, 268, 8)
	path("PathPlazaRow", 0, 44, 250, 8)
	return ground
end

local function buildBelt(world)
	local belt = Instance.new("Model")
	belt.Name = "ConveyorBelt"
	belt.Parent = world
	local length = L.Belt.ToX - L.Belt.FromX
	local midX = (L.Belt.FromX + L.Belt.ToX) / 2
	local bed = newPart(belt, "BeltBed", Vector3.new(length, L.Belt.TopY, L.Belt.Width), CFrame.new(midX, L.Belt.TopY / 2, L.Belt.Z), Color3.fromRGB(52, 54, 62), Enum.Material.Metal)
	bed.Name = "BeltBed"
	-- Pale stripes across the bed so the belt reads as a conveyor.
	for x = L.Belt.FromX + 5, L.Belt.ToX - 5, 10 do
		local stripe = newPart(belt, "BeltStripe", Vector3.new(1.2, 0.06, L.Belt.Width - 1), CFrame.new(x, L.Belt.TopY + 0.03, L.Belt.Z), Color3.fromRGB(120, 124, 134), Enum.Material.Metal)
		stripe.CanCollide = false
	end
	for _, side in ipairs({ -1, 1 }) do
		newPart(belt, "BeltRail", Vector3.new(length, 0.5, 0.4), CFrame.new(midX, L.Belt.TopY + 0.25, L.Belt.Z + side * (L.Belt.Width / 2 + 0.2)), Color3.fromRGB(255, 176, 32), Enum.Material.Metal)
	end
	for x = L.Belt.FromX + 7, L.Belt.ToX - 7, 14 do
		newPart(belt, "BeltLeg", Vector3.new(0.7, L.Belt.TopY, 0.7), CFrame.new(x, L.Belt.TopY / 2, L.Belt.Z - 4), Color3.fromRGB(90, 90, 98), Enum.Material.Metal)
		newPart(belt, "BeltLeg", Vector3.new(0.7, L.Belt.TopY, 0.7), CFrame.new(x, L.Belt.TopY / 2, L.Belt.Z + 4), Color3.fromRGB(90, 90, 98), Enum.Material.Metal)
	end
	-- TOKO BRAINROT arch at the west end where brainrots walk in.
	local arch = Instance.new("Model")
	arch.Name = "TokoArch"
	arch.Parent = world
	for _, side in ipairs({ -1, 1 }) do
		newPart(arch, "ArchPost", Vector3.new(1.2, L.Arch.PostTopY, 1.2), CFrame.new(L.Arch.X, L.Arch.PostTopY / 2, side * L.Arch.PostZ), Color3.fromRGB(255, 120, 90), Enum.Material.Brick)
	end
	local board = newPart(arch, "ArchBoard", Vector3.new(1, 3.4, 16), CFrame.new(L.Arch.X, L.Arch.BoardY, 0), Color3.fromRGB(255, 120, 90), Enum.Material.Brick)
	-- The board faces along X, so label its two X faces.
	for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "TOKO BRAINROT"
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Parent = gui
	end
	return belt
end

local function buildSpawn(world)
	newCylinder(world, "SpawnPad", L.SpawnPad.Radius, 0.4, L.SpawnPad.X, L.SpawnPad.TopY, L.SpawnPad.Z, Color3.fromRGB(120, 220, 255), Enum.Material.Neon)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(6, 0.4, 6)
	spawn.CFrame = CFrame.new(L.SpawnPad.X, 0.2, L.SpawnPad.Z)
	spawn.Color = Color3.fromRGB(120, 220, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 0.4
	spawn.Parent = world
	makeSign(world, "WelcomeSign", L.WelcomeSign.X, L.WelcomeSign.Z, L.WelcomeSign.BoardY, 11, 3, "SELAMAT DATANG DI BRAINROT BAZAAR!", Color3.fromRGB(64, 156, 255), 3)
end

local PLOT_COLORS = {
	Color3.fromRGB(255, 150, 150), Color3.fromRGB(150, 220, 255), Color3.fromRGB(170, 255, 170), Color3.fromRGB(255, 230, 150),
	Color3.fromRGB(230, 170, 255), Color3.fromRGB(255, 190, 130), Color3.fromRGB(150, 255, 220), Color3.fromRGB(255, 170, 210),
}

local function buildPlots(world)
	local plots = {}
	local index = 0
	for _, cz in ipairs(L.PlotZs) do
		for _, cx in ipairs(L.PlotXs) do
			index += 1
			local model = Instance.new("Model")
			model.Name = "Plot" .. index
			model.Parent = world
			local slabColor = PLOT_COLORS[index]
			newPart(model, "Slab", Vector3.new(L.PlotSlab.SizeX, 0.5, L.PlotSlab.SizeZ), CFrame.new(cx, 0, cz), slabColor, Enum.Material.Concrete)
			local frontDir = (cz < 0) and 1 or -1 -- front edge faces map centre
			local frontZ = cz + frontDir * 12
			-- Six pads, two rows of three.
			local padPositions = {}
			for row, dz in ipairs({ -7, 5 }) do
				for col, dx in ipairs({ -13, 0, 13 }) do
					local padIndex = (row - 1) * 3 + col
					local px, pz = cx + dx, cz + dz
					local pad = newCylinder(model, "Pad" .. padIndex, L.PadRadius, 0.9, px, L.PadTopY, pz, Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic)
					pad.CanCollide = false
					padPositions[padIndex] = Vector3.new(px, L.PadTopY, pz)
				end
			end
			-- Green collect pad on the front edge.
			local collect = newPart(model, "CollectPad", Vector3.new(5, 0.45, 5), CFrame.new(cx, 0, frontZ), Color3.fromRGB(46, 220, 90), Enum.Material.Neon)
			collect.Name = "CollectPad"
			local collectLabelPart = newPart(model, "CollectSign", Vector3.new(5, 1.6, 0.3), CFrame.new(cx, 1.25, frontZ + frontDir * 2.8), Color3.fromRGB(30, 160, 70), Enum.Material.WoodPlanks)
			makeLabel(collectLabelPart, "AMBIL $", Color3.fromRGB(255, 255, 255))
			-- Lock button on a post at the front corner.
			local lockX = cx + 19
			newPart(model, "LockPost", Vector3.new(0.5, 1.4, 0.5), CFrame.new(lockX, 0.7, frontZ), Color3.fromRGB(101, 67, 33), Enum.Material.Wood)
			local lockButton = newPart(model, "LockButton", Vector3.new(1.4, 0.7, 1.4), CFrame.new(lockX, 1.75, frontZ), Color3.fromRGB(255, 90, 90), Enum.Material.Neon)
			-- Four translucent barrier walls, hidden until the base locks.
			local barrier = {}
			local wallColor = Color3.fromRGB(120, 220, 255)
			local function wall(name, sx, sz, wx, wz)
				local w = newPart(model, name, Vector3.new(sx, 3.4, sz), CFrame.new(wx, 1.95, wz), wallColor, Enum.Material.ForceField)
				w.Transparency = 0.45
				w.CanCollide = false
				w.Visible = false
				table.insert(barrier, w)
				return w
			end
			wall("WallN", L.PlotSlab.SizeX, 0.4, cx, cz - L.PlotSlab.SizeZ / 2)
			wall("WallS", L.PlotSlab.SizeX, 0.4, cx, cz + L.PlotSlab.SizeZ / 2)
			wall("WallW", 0.4, L.PlotSlab.SizeZ, cx - L.PlotSlab.SizeX / 2, cz)
			wall("WallE", 0.4, L.PlotSlab.SizeZ, cx + L.PlotSlab.SizeX / 2, cz)
			local signZ = cz + frontDir * 14
			makeSign(model, "PlotSign", cx, signZ, L.PlotSignY, 11, 3, "BASE " .. index, slabColor, 3.5)
			plots[index] = {
				Index = index,
				Center = Vector3.new(cx, 0, cz),
				FrontZ = frontZ,
				Pads = padPositions,
				CollectPad = collect,
				LockButton = lockButton,
				Barrier = barrier,
				Model = model,
			}
		end
	end
	return plots
end

local function buildFountain(world)
	local f = Instance.new("Model")
	f.Name = "Fountain"
	f.Parent = world
	newCylinder(f, "Basin", L.Fountain.BasinRadius, 1.2, L.Fountain.X, L.Fountain.RimTopY, L.Fountain.Z, Color3.fromRGB(170, 200, 220), Enum.Material.Marble)
	newCylinder(f, "Column", 1.2, L.Fountain.ColumnTopY, L.Fountain.X, L.Fountain.ColumnTopY, L.Fountain.Z, Color3.fromRGB(190, 215, 230), Enum.Material.Marble)
	local cap = Instance.new("Part")
	cap.Name = "ColumnCap"
	cap.Shape = Enum.PartType.Ball
	cap.Size = Vector3.new(2.4, 2.4, 2.4)
	cap.CFrame = CFrame.new(L.Fountain.X, L.Fountain.ColumnTopY + 1, L.Fountain.Z)
	cap.Color = Color3.fromRGB(120, 220, 255)
	cap.Material = Enum.Material.Neon
	cap.Anchored = true
	cap.Parent = f
	local water = newCylinder(f, "WaterDisc", L.Fountain.WaterRadius, 0.12, L.Fountain.X, L.Fountain.WaterY + 0.06, L.Fountain.Z, Color3.fromRGB(90, 200, 255), Enum.Material.Glass)
	water.Transparency = 0.25
	water.CanCollide = false
	-- Four spokes on the disc so its slow spin is visible.
	for i = 0, 3 do
		local a = i * math.pi / 2
		local spoke = newPart(water.Parent, "WaterSpoke", Vector3.new(6.4, 0.1, 0.8), CFrame.new(L.Fountain.X + math.cos(a) * 3.4, L.Fountain.WaterY + 0.08, L.Fountain.Z + math.sin(a) * 3.4) * CFrame.Angles(0, -a, 0), Color3.fromRGB(200, 245, 255), Enum.Material.Neon)
		spoke.CanCollide = false
		spoke.Name = "WaterSpoke" .. i
		-- Spokes are children of the fountain model, spun with the disc group.
		spoke:SetAttribute("SpinWithWater", true)
	end
	return water
end

local function buildStalls(world)
	local awningColors = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(90, 160, 255), Color3.fromRGB(255, 190, 60), Color3.fromRGB(120, 220, 120) }
	for i, s in ipairs(L.Stalls) do
		local stall = Instance.new("Model")
		stall.Name = "MarketStall" .. i
		stall.Parent = world
		local faceDir = (s.Z > L.Plaza.Z) and -1 or 1
		newPart(stall, "Counter", Vector3.new(7, 1.6, 3), CFrame.new(s.X, 0.8, s.Z), Color3.fromRGB(150, 100, 60), Enum.Material.WoodPlanks)
		for _, dx in ipairs({ -3.3, 3.3 }) do
			for _, dz in ipairs({ -1.8, 1.8 }) do
				newPart(stall, "Post", Vector3.new(0.4, 5, 0.4), CFrame.new(s.X + dx, 2.5, s.Z + dz), Color3.fromRGB(101, 67, 33), Enum.Material.Wood)
			end
		end
		local awning = newPart(stall, "Awning", Vector3.new(8, 0.3, 4.6), CFrame.new(s.X, 5.2, s.Z) * CFrame.Angles(math.rad(12) * faceDir, 0, 0), awningColors[i], Enum.Material.Fabric)
		awning.Name = "Awning"
		for k = -1, 1 do
			local stripe = newPart(stall, "AwningStripe", Vector3.new(8.1, 0.34, 0.9), CFrame.new(s.X, 5.2, s.Z) * CFrame.Angles(math.rad(12) * faceDir, 0, 0) * CFrame.new(0, 0, k * 1.5), Color3.fromRGB(255, 255, 255), Enum.Material.Fabric)
			stripe.CanCollide = false
		end
		-- A few goods boxes on the counter.
		newPart(stall, "Goods", Vector3.new(1.2, 1, 1.2), CFrame.new(s.X - 1.6, 2.1, s.Z), Color3.fromRGB(255, 200, 80), Enum.Material.WoodPlanks)
		newPart(stall, "Goods", Vector3.new(1, 0.8, 1), CFrame.new(s.X + 1.4, 2, s.Z), Color3.fromRGB(255, 130, 160), Enum.Material.WoodPlanks)
	end
end

local function buildFerrisWheel(world)
	local wheel = Instance.new("Model")
	wheel.Name = "FerrisWheel"
	wheel.Parent = world
	local hx, hz, hy = L.Wheel.X, L.Wheel.Z, L.Wheel.HubY
	-- Two A-frame legs leaning together up to the hub.
	for _, side in ipairs({ -1, 1 }) do
		local leg = newPart(wheel, "Leg", Vector3.new(1, 29, 1), CFrame.new(hx, hy / 2 + 0.5, hz + side * 4.6) * CFrame.Angles(math.rad(10) * side, 0, 0), Color3.fromRGB(255, 120, 170), Enum.Material.Metal)
		leg.Name = "Leg"
	end
	newPart(wheel, "LegBar", Vector3.new(1, 0.8, 20), CFrame.new(hx, 0.4, hz), Color3.fromRGB(255, 120, 170), Enum.Material.Metal)
	local hub = Instance.new("Part")
	hub.Name = "Hub"
	hub.Shape = Enum.PartType.Cylinder
	hub.Size = Vector3.new(3, 3.4, 3.4)
	hub.CFrame = CFrame.new(hx, hy, hz)
	hub.Color = Color3.fromRGB(255, 215, 60)
	hub.Material = Enum.Material.Neon
	hub.Anchored = true
	hub.Parent = wheel
	local ring = Instance.new("Model")
	ring.Name = "Ring"
	ring.Parent = wheel
	local podColors = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 170, 40), Color3.fromRGB(255, 240, 90), Color3.fromRGB(110, 230, 110), Color3.fromRGB(80, 200, 255), Color3.fromRGB(120, 130, 255), Color3.fromRGB(200, 110, 255), Color3.fromRGB(255, 120, 200) }
	for i = 0, 15 do
		local a = i * math.pi / 8
		local seg = newPart(ring, "RingSeg", Vector3.new(1.2, 8.2, 1.2), CFrame.new(hx, hy + math.sin(a) * L.Wheel.RingRadius, hz + math.cos(a) * L.Wheel.RingRadius) * CFrame.Angles(a, 0, 0), Color3.fromRGB(240, 240, 245), Enum.Material.Metal)
		seg.CanCollide = false
	end
	for i = 0, 7 do
		local a = i * math.pi / 4
		local pod = newPart(ring, "Pod", Vector3.new(3.2, 3, 3.2), CFrame.new(hx, hy + math.sin(a) * L.Wheel.RingRadius, hz + math.cos(a) * L.Wheel.RingRadius), podColors[i + 1], Enum.Material.SmoothPlastic)
		pod.Name = "Pod" .. (i + 1)
	end
	wheel.PrimaryPart = hub
	makeSign(world, "WheelSign", L.WheelSign.X, L.WheelSign.Z, L.WheelSign.BoardY, 13, 3, "BIANGLALA BRAINROT", Color3.fromRGB(255, 120, 170), 4)
	return wheel
end

local function buildTower(world)
	local tower = Instance.new("Model")
	tower.Name = "Tower"
	tower.Parent = world
	local levels = { { 18, 10 }, { 15, 10 }, { 12, 9 }, { 9, 8 }, { 6, 7 } }
	local y = 0
	local shades = { 150, 168, 186, 204, 222 }
	for i, lv in ipairs(levels) do
		local w, h = lv[1], lv[2]
		newPart(tower, "Level" .. i, Vector3.new(w, h, w), CFrame.new(L.Tower.X, y + h / 2, L.Tower.Z), Color3.fromRGB(shades[i], shades[i], shades[i] + 12), Enum.Material.Concrete)
		y += h
	end
	local beacon = Instance.new("Part")
	beacon.Name = "Beacon"
	beacon.Shape = Enum.PartType.Ball
	beacon.Size = Vector3.new(4, 4, 4)
	beacon.CFrame = CFrame.new(L.Tower.X, L.Tower.BeaconY, L.Tower.Z)
	beacon.Color = Color3.fromRGB(255, 70, 70)
	beacon.Material = Enum.Material.Neon
	beacon.Anchored = true
	beacon.Parent = tower
	local light = Instance.new("PointLight")
	light.Color = beacon.Color
	light.Range = 30
	light.Brightness = 2
	light.Parent = beacon
	makeSign(world, "TowerSign", L.TowerSign.X, L.TowerSign.Z, L.TowerSign.BoardY, 12, 3, "MENARA BRAINROT", Color3.fromRGB(90, 100, 120), 3.5)
	return tower
end

local function buildRainbowArch(world)
	local arch = Instance.new("Model")
	arch.Name = "RainbowArch"
	arch.Parent = world
	local colors = { Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 150, 50), Color3.fromRGB(255, 235, 90), Color3.fromRGB(110, 230, 110), Color3.fromRGB(80, 190, 255), Color3.fromRGB(120, 110, 255), Color3.fromRGB(205, 110, 255) }
	for i = 0, 6 do
		local theta = math.rad((i + 0.5) * 180 / 7)
		local x = L.RainbowArch.X + math.cos(theta) * L.RainbowArch.HalfWidth
		local y = math.sin(theta) * L.RainbowArch.PeakY
		local seg = newPart(arch, "ArcSeg" .. (i + 1), Vector3.new(3.6, 1.7, 2.2), CFrame.new(x, y, L.RainbowArch.Z) * CFrame.Angles(0, 0, theta - math.pi / 2), colors[i + 1], Enum.Material.Neon)
		seg.CanCollide = false
	end
	return arch
end

local RARITY_NAMES = { "COMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC", "DIVINE" }
local RARITY_BOARD_COLORS = {
	Color3.fromRGB(120, 128, 140), Color3.fromRGB(64, 156, 255), Color3.fromRGB(168, 85, 247),
	Color3.fromRGB(255, 176, 32), Color3.fromRGB(244, 63, 120), Color3.fromRGB(190, 160, 60),
}

local function buildBillboards(world)
	for i, bx in ipairs(L.BillboardXs) do
		makeSign(world, "Billboard" .. RARITY_NAMES[i], bx, L.BillboardZ, L.BillboardY, 10.5, 3.6, RARITY_NAMES[i], RARITY_BOARD_COLORS[i], 3)
	end
end

local function buildGachaMachine(world)
	local g = Instance.new("Model")
	g.Name = "GachaMachine"
	g.Parent = world
	local gx, gz = L.Gacha.X, L.Gacha.Z
	newPart(g, "Body", Vector3.new(4.4, 4.6, 4.4), CFrame.new(gx, 2.3, gz), Color3.fromRGB(255, 110, 180), Enum.Material.SmoothPlastic)
	local globe = Instance.new("Part")
	globe.Name = "Globe"
	globe.Shape = Enum.PartType.Ball
	globe.Size = Vector3.new(3.6, 3.6, 3.6)
	globe.CFrame = CFrame.new(gx, 6.2, gz)
	globe.Color = Color3.fromRGB(190, 240, 255)
	globe.Material = Enum.Material.Glass
	globe.Transparency = 0.3
	globe.Anchored = true
	globe.Parent = g
	for i = 1, 5 do
		local ball = Instance.new("Part")
		ball.Name = "Capsule"
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(0.9, 0.9, 0.9)
		ball.CFrame = CFrame.new(gx + math.sin(i * 2.3) * 1.1, 5.6 + (i % 2) * 0.7, gz + math.cos(i * 2.3) * 1.1)
		ball.Color = RARITY_BOARD_COLORS[(i % 6) + 1]
		ball.Material = Enum.Material.Neon
		ball.Anchored = true
		ball.Parent = g
	end
	local slot = newPart(g, "Slot", Vector3.new(2, 1.2, 0.4), CFrame.new(gx, 1.4, gz - 2.3), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
	slot.Name = "Slot"
	local signPart = newPart(g, "GachaSign", Vector3.new(5.4, 1.6, 0.3), CFrame.new(gx, 8.6, gz), Color3.fromRGB(190, 60, 140), Enum.Material.WoodPlanks)
	makeLabel(signPart, "GACHA", Color3.fromRGB(255, 255, 255))
	return g
end

local TREE_SPOTS = {
	{ -170, -130 }, { -150, 122 }, { -60, -136 }, { 60, -136 }, { 172, -118 }, { 172, 118 }, { 152, -18 },
	{ -152, -18 }, { -172, 42 }, { 172, 62 }, { -88, 136 }, { 88, 136 }, { -38, 122 }, { 42, -122 },
}
local ROCK_SPOTS = {
	{ -178, -60 }, { 178, -30 }, { -120, 138 }, { 128, 138 }, { -178, 100 }, { 60, 140 }, { -64, 140 }, { 178, 140 },
}

local function buildScatter(world)
	for i, spot in ipairs(TREE_SPOTS) do
		local tree = Instance.new("Model")
		tree.Name = "Tree" .. i
		tree.Parent = world
		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(4, 1.4, 1.4)
		trunk.CFrame = CFrame.new(spot[1], 2, spot[2]) * CFrame.Angles(0, 0, math.rad(90))
		trunk.Color = Color3.fromRGB(110, 76, 44)
		trunk.Material = Enum.Material.Wood
		trunk.Anchored = true
		trunk.Parent = tree
		local leaf = Instance.new("Part")
		leaf.Name = "Foliage"
		leaf.Shape = Enum.PartType.Ball
		leaf.Size = Vector3.new(6, 6, 6)
		leaf.CFrame = CFrame.new(spot[1], 6, spot[2])
		leaf.Color = Color3.fromRGB(52, 160, 64)
		leaf.Material = Enum.Material.Grass
		leaf.Anchored = true
		leaf.Parent = tree
	end
	for i, spot in ipairs(ROCK_SPOTS) do
		local rock = Instance.new("Part")
		rock.Name = "Rock" .. i
		rock.Shape = Enum.PartType.Ball
		rock.Size = Vector3.new(3.4, 2.2, 3)
		rock.CFrame = CFrame.new(spot[1], 0.7, spot[2]) * CFrame.Angles(0, i * 0.7, 0)
		rock.Color = Color3.fromRGB(128, 130, 136)
		rock.Material = Enum.Material.Slate
		rock.Anchored = true
		rock.Parent = world
	end
end

local LAMP_SPOTS = {
	{ 8, 12 }, { -8, 12 }, { 8, 76 }, { -8, 76 }, { 8, -40 }, { -8, -40 },
	{ 30, 44 }, { -30, 44 }, { 62, 84 }, { -62, -84 },
}

local function buildLamps(world)
	for i, spot in ipairs(LAMP_SPOTS) do
		local lamp = Instance.new("Model")
		lamp.Name = "Lamp" .. i
		lamp.Parent = world
		local post = Instance.new("Part")
		post.Name = "Post"
		post.Shape = Enum.PartType.Cylinder
		post.Size = Vector3.new(7, 0.45, 0.45)
		post.CFrame = CFrame.new(spot[1], 3.5, spot[2]) * CFrame.Angles(0, 0, math.rad(90))
		post.Color = Color3.fromRGB(50, 52, 60)
		post.Material = Enum.Material.Metal
		post.Anchored = true
		post.Parent = lamp
		local bulb = Instance.new("Part")
		bulb.Name = "Bulb"
		bulb.Shape = Enum.PartType.Ball
		bulb.Size = Vector3.new(1.5, 1.5, 1.5)
		bulb.CFrame = CFrame.new(spot[1], 7.4, spot[2])
		bulb.Color = Color3.fromRGB(255, 240, 170)
		bulb.Material = Enum.Material.Neon
		bulb.Anchored = true
		bulb.CanCollide = false
		bulb.Parent = lamp
		local light = Instance.new("PointLight")
		light.Color = bulb.Color
		light.Range = 20
		light.Brightness = 1.5
		light.Parent = bulb
	end
end

-- Build everything and hand back the handles the game logic needs.
function WorldBuilder.Build()
	local world = Instance.new("Folder")
	world.Name = "BrainrotWorld"
	world.Parent = workspace
	buildGroundAndPaths(world)
	local belt = buildBelt(world)
	buildSpawn(world)
	local plots = buildPlots(world)
	local water = buildFountain(world)
	buildStalls(world)
	local wheel = buildFerrisWheel(world)
	buildTower(world)
	buildRainbowArch(world)
	buildBillboards(world)
	local gacha = buildGachaMachine(world)
	buildScatter(world)
	buildLamps(world)
	return {
		Folder = world,
		Belt = belt,
		Plots = plots,
		FountainWater = water,
		FerrisWheel = wheel,
		WheelHub = Vector3.new(L.Wheel.X, L.Wheel.HubY, L.Wheel.Z),
		GachaMachine = gacha,
		GachaPosition = Vector3.new(L.Gacha.X, 0, L.Gacha.Z),
	}
end

-- A plain-text sanity list of the layout, printed by the server at
-- boot and quoted in the entry report: name, X, Z, base Y (the ground
-- or floor top the thing stands on).
function WorldBuilder.DescribeLayout()
	local lines = {}
	local function row(name, x, z, baseY)
		table.insert(lines, string.format("%s X=%d Z=%d baseY=%.2f", name, x, z, baseY))
	end
	row("Fountain", L.Fountain.X, L.Fountain.Z, L.Plaza.TopY)
	row("WheelHub", L.Wheel.X, L.Wheel.Z, L.Wheel.HubY)
	row("Tower", L.Tower.X, L.Tower.Z, 0)
	row("RainbowArchPeak", L.RainbowArch.X, L.RainbowArch.Z, L.RainbowArch.PeakY)
	row("BeltStart", L.Belt.FromX, L.Belt.Z, L.Belt.TopY)
	row("BeltEnd", L.Belt.ToX, L.Belt.Z, L.Belt.TopY)
	for i, plot in ipairs(WorldBuilder.PlotCenters()) do
		row("Plot" .. i, plot.X, plot.Z, 0)
	end
	return lines
end

function WorldBuilder.PlotCenters()
	local centers = {}
	for _, cz in ipairs(L.PlotZs) do
		for _, cx in ipairs(L.PlotXs) do
			table.insert(centers, { X = cx, Z = cz })
		end
	end
	return centers
end

return WorldBuilder
