-- WorldBuilder.luau
-- Builds the whole Brainrot Bazaar map out of procedural Parts, exactly to
-- the layout spec: ground top surface is Y=0 and EVERY part sits ON the
-- ground (its base at Y=0 or on the slab/belt it belongs to), never below.
-- Signs stand on posts with the board centre at the stated height.
--
-- Returns a refs table the other server systems use: plot pad positions,
-- collect pads, lock buttons, the belt folder, the gacha machine, the
-- fountain water and the ferris wheel (with a RotateWheel driver).

local WorldBuilder = {}

-- Layout constants, exported so tooling (and humans) can sanity-print the
-- intended position and base height of every landmark.
WorldBuilder.LAYOUT = {
	Fountain = { x = 0, z = 44, baseY = 0 },
	WheelHub = { x = -128, z = -52, baseY = 26 },
	Tower = { x = 128, z = -52, baseY = 0 },
	RainbowArch = { x = 0, z = 58, baseY = 0 },
	BeltWestEnd = { x = -70, z = 0, baseY = 0 },
	BeltEastEnd = { x = 70, z = 0, baseY = 0 },
	SpawnPad = { x = 0, z = 26, baseY = 0 },
	Gacha = { x = -18, z = 44, baseY = 0 },
	PlotCenters = {
		{ x = -102, z = -84, baseY = 0 }, { x = -34, z = -84, baseY = 0 },
		{ x = 34, z = -84, baseY = 0 }, { x = 102, z = -84, baseY = 0 },
		{ x = -102, z = 84, baseY = 0 }, { x = -34, z = 84, baseY = 0 },
		{ x = 34, z = 84, baseY = 0 }, { x = 102, z = 84, baseY = 0 },
	},
}

local BELT_TOP = 1.3
local PLOT_TOP = 0.25
local PAD_TOP = 0.45

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- A box whose BASE sits at baseY: you state footprint, height and base,
-- never a centre height, so nothing can accidentally sink under Y=0.
local function box(parent: Instance, name: string, w: number, h: number, d: number, x: number, baseY: number, z: number, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(w, h, d)
	p.CFrame = CFrame.new(x, baseY + h / 2, z)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- A flat cylinder (disc) whose TOP is at topY. Cylinder parts lie on
-- their X axis, so rotate 90 degrees about Z to stand the axis upright.
local function disc(parent: Instance, name: string, radius: number, thickness: number, x: number, topY: number, z: number, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(thickness, radius * 2, radius * 2)
	p.CFrame = CFrame.new(x, topY - thickness / 2, z) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- A sign: two posts from the ground and a board whose CENTRE is at
-- boardCenterY, with the text on both broad faces.
local function sign(parent: Instance, x: number, z: number, boardCenterY: number, w: number, h: number, text: string, boardColor: Color3, textColor: Color3)
	local g = folder(parent, "Sign")
	local postColor = Color3.fromRGB(120, 85, 50)
	box(g, "PostL", 0.5, boardCenterY, 0.5, x - w / 2 + 0.6, 0, z, postColor, Enum.Material.Wood)
	box(g, "PostR", 0.5, boardCenterY, 0.5, x + w / 2 - 0.6, 0, z, postColor, Enum.Material.Wood)
	local board = box(g, "Board", w, h, 0.5, x, boardCenterY - h / 2, z, boardColor, Enum.Material.Wood)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = textColor
		label.Text = text
		label.Parent = gui
		gui.Parent = board
	end
	return g
end

local PATH_COLOR = Color3.fromRGB(205, 208, 210)

local function buildGroundAndPaths(root: Folder)
	-- One big flat part, top at Y=0, X -190..190, Z -150..150.
	local ground = box(root, "Ground", 380, 2, 300, 0, -2, 0, Color3.fromRGB(86, 199, 76), Enum.Material.Grass)
	ground.Locked = true
	-- Plaza disc: radius 34, top Y=0.15, centred (0, 44).
	disc(root, "Plaza", 34, 0.15, 0, 0.15, 44, Color3.fromRGB(245, 214, 130), Enum.Material.SmoothPlastic)
	-- Paths (top Y=0.06): plaza to belt, plaza to each plot row, belt to rows.
	box(root, "PathPlazaBelt", 8, 0.06, 36, 0, 0, 24, PATH_COLOR, Enum.Material.Concrete)
	box(root, "PathNorthRow", 250, 0.06, 7, 0, 0, 66, PATH_COLOR, Enum.Material.Concrete)
	box(root, "PathSouthRow", 250, 0.06, 7, 0, 0, -66, PATH_COLOR, Enum.Material.Concrete)
	box(root, "PathBeltNorth", 250, 0.06, 7, 0, 0, -20, PATH_COLOR, Enum.Material.Concrete)
	for _, px in ipairs({ -102, -34, 34, 102 }) do
		box(root, "PathSpur", 6, 0.06, 18, px, 0, 75, PATH_COLOR, Enum.Material.Concrete)
		box(root, "PathSpur", 6, 0.06, 18, px, 0, -75, PATH_COLOR, Enum.Material.Concrete)
	end
end

local function buildBelt(root: Folder)
	local belt = folder(root, "ConveyorBelt")
	-- Belt slab along X at Z=0, X -70..70, top surface at Y=1.3.
	box(belt, "BeltSlab", 140, BELT_TOP, 10, 0, 0, 0, Color3.fromRGB(52, 54, 64), Enum.Material.Metal)
	-- Moving-look stripes across the belt every 10 studs.
	for x = -65, 65, 10 do
		box(belt, "BeltStripe", 1.2, 0.06, 9.6, x, BELT_TOP, 0, Color3.fromRGB(90, 94, 110), Enum.Material.Metal)
	end
	-- Side rails.
	box(belt, "RailNorth", 140, 0.5, 0.4, 0, BELT_TOP, -5, Color3.fromRGB(255, 176, 32), Enum.Material.Metal)
	box(belt, "RailSouth", 140, 0.5, 0.4, 0, BELT_TOP, 5, Color3.fromRGB(255, 176, 32), Enum.Material.Metal)
	-- Support legs down to the ground.
	for x = -66, 66, 12 do
		box(belt, "BeltLeg", 1, BELT_TOP, 1, x, 0, -4, Color3.fromRGB(40, 42, 50), Enum.Material.Metal)
		box(belt, "BeltLeg", 1, BELT_TOP, 1, x, 0, 4, Color3.fromRGB(40, 42, 50), Enum.Material.Metal)
	end
	-- "TOKO BRAINROT" arch at X=-70: posts at Z=-7 and Z=7 rising to Y=14,
	-- board across the top centred Y=13, spanning Z -8..8.
	local arch = folder(belt, "ShopArch")
	box(arch, "ArchPostA", 1.4, 14, 1.4, -70, 0, -7, Color3.fromRGB(200, 60, 90), Enum.Material.SmoothPlastic)
	box(arch, "ArchPostB", 1.4, 14, 1.4, -70, 0, 7, Color3.fromRGB(200, 60, 90), Enum.Material.SmoothPlastic)
	local board = box(arch, "ArchBoard", 2, 3.4, 16, -70, 13 - 1.7, 0, Color3.fromRGB(255, 209, 26), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(120, 30, 60)
	label.Text = "TOKO BRAINROT"
	label.Parent = gui
	gui.Parent = board
	return belt
end

local function buildSpawn(root: Folder)
	-- Spawn pad at (0, 26): flat cylinder radius 5, top Y=0.2.
	local pad = disc(root, "SpawnPad", 5, 0.2, 0, 0.2, 26, Color3.fromRGB(90, 200, 255), Enum.Material.Neon)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(6, 0.4, 6)
	spawn.CFrame = CFrame.new(0, 0.2, 26)
	spawn.Color = Color3.fromRGB(90, 200, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 0.4
	spawn.Parent = root
	-- Welcome sign on two posts at (0, 40), board centre Y=9.
	sign(root, 0, 40, 9, 13, 3, "SELAMAT DATANG DI BRAINROT BAZAAR!", Color3.fromRGB(64, 156, 255), Color3.fromRGB(255, 255, 255))
	return pad
end

local PLOT_NAME_COLORS = {
	Color3.fromRGB(255, 110, 110), Color3.fromRGB(255, 176, 32), Color3.fromRGB(120, 230, 140), Color3.fromRGB(90, 200, 255),
	Color3.fromRGB(178, 82, 255), Color3.fromRGB(255, 120, 200), Color3.fromRGB(120, 240, 220), Color3.fromRGB(250, 240, 150),
}

local function buildPlots(root: Folder)
	local plots = {}
	local index = 0
	for _, cz in ipairs({ -84, 84 }) do
		for _, cx in ipairs({ -102, -34, 34, 102 }) do
			index += 1
			local g = folder(root, "Plot" .. index)
			-- Base slab 44x30, top Y=0.25.
			box(g, "Slab", 44, PLOT_TOP, 30, cx, 0, cz, PLOT_NAME_COLORS[index], Enum.Material.SmoothPlastic)
			-- 6 pads in 2 rows of 3: flat cylinders radius 2.6, top Y=0.45.
			local padPositions = {}
			for row, dz in ipairs({ -6.5, 5 }) do
				for col, dx in ipairs({ -13, 0, 13 }) do
					local padIndex = (row - 1) * 3 + col
					local pad = disc(g, "Pad" .. padIndex, 2.6, PAD_TOP - PLOT_TOP, cx + dx, PAD_TOP, cz + dz, Color3.fromRGB(240, 240, 245), Enum.Material.SmoothPlastic)
					pad:SetAttribute("PlotIndex", index)
					pad:SetAttribute("PadIndex", padIndex)
					padPositions[padIndex] = Vector3.new(cx + dx, PAD_TOP, cz + dz)
				end
			end
			-- Collect pad (green, 5x5, top Y=0.45) at the plot's front edge:
			-- the edge facing the map centre.
			local frontDir = cz > 0 and -1 or 1
			local collect = box(g, "CollectPad", 5, PAD_TOP, 5, cx, 0, cz + frontDir * 12, Color3.fromRGB(46, 204, 113), Enum.Material.Neon)
			collect:SetAttribute("PlotIndex", index)
			-- Lock button post at the front corner.
			local lockBase = box(g, "LockPost", 0.7, 2.2, 0.7, cx + 19, PLOT_TOP, cz + frontDir * 12, Color3.fromRGB(90, 90, 100), Enum.Material.Metal)
			local lockButton = box(g, "LockButton", 1.6, 0.7, 1.6, cx + 19, PLOT_TOP + 2.2, cz + frontDir * 12, Color3.fromRGB(231, 76, 60), Enum.Material.SmoothPlastic)
			lockButton:SetAttribute("PlotIndex", index)
			-- Plot sign on posts, board centre Y=8, naming the plot.
			sign(g, cx, cz - frontDir * 13, 8, 15, 2.6, "BASE " .. index, PLOT_NAME_COLORS[index], Color3.fromRGB(40, 40, 50))
			table.insert(plots, {
				Index = index,
				Center = Vector3.new(cx, 0, cz),
				PadPositions = padPositions,
				CollectPad = collect,
				LockButton = lockButton,
				Folder = g,
			})
		end
	end
	return plots
end

local function buildFountain(root: Folder)
	local g = folder(root, "Fountain")
	-- Basin cylinder radius 9 at the plaza centre (0, 44), rim top Y=1.2.
	disc(g, "Basin", 9, 1.2, 0, 1.2, 44, Color3.fromRGB(120, 180, 230), Enum.Material.SmoothPlastic)
	disc(g, "BasinFloor", 7.8, 1.0, 0, 1.0, 44, Color3.fromRGB(70, 130, 190), Enum.Material.SmoothPlastic)
	-- Central column up to Y=6 with a small crown ball.
	box(g, "Column", 1.6, 6, 1.6, 0, 0, 44, Color3.fromRGB(200, 215, 235), Enum.Material.Marble)
	local crown = box(g, "Crown", 1.6, 1.6, 1.6, 0, 6, 44, Color3.fromRGB(120, 200, 255), Enum.Material.Neon)
	crown.Shape = Enum.PartType.Ball
	-- Animated water disc (radius 7.5) at Y=1.35; init rotates it slowly.
	local water = disc(g, "Water", 7.5, 0.15, 0, 1.35, 44, Color3.fromRGB(90, 200, 255), Enum.Material.Glass)
	water.Transparency = 0.35
	water.CanCollide = false
	return water
end

local function buildStalls(root: Folder)
	-- 4 market stalls at (±16, 62) and (±16, 26), facing the plaza centre.
	local awningColors = { Color3.fromRGB(231, 76, 60), Color3.fromRGB(64, 156, 255), Color3.fromRGB(46, 204, 113), Color3.fromRGB(255, 176, 32) }
	local i = 0
	for _, sx in ipairs({ -16, 16 }) do
		for _, sz in ipairs({ 62, 26 }) do
			i += 1
			local g = folder(root, "Stall" .. i)
			box(g, "Counter", 8, 1.6, 3, sx, 0, sz, Color3.fromRGB(160, 110, 65), Enum.Material.Wood)
			for _, ox in ipairs({ -3.7, 3.7 }) do
				for _, oz in ipairs({ -1.7, 1.7 }) do
					box(g, "Post", 0.45, 5, 0.45, sx + ox, 0, sz + oz, Color3.fromRGB(120, 85, 50), Enum.Material.Wood)
				end
			end
			-- Striped awning slab tilted at Y=5.2: two-tone by pairing a
			-- coloured slab with a white stripe slab beside it.
			local tilt = (sz > 44) and -0.16 or 0.16
			local awn = box(g, "Awning", 9, 0.3, 4.6, sx, 5.05, sz, awningColors[i], Enum.Material.SmoothPlastic)
			awn.CFrame = CFrame.new(sx, 5.2, sz) * CFrame.Angles(tilt, 0, 0)
			local stripe = box(g, "AwningStripe", 9, 0.32, 1.4, sx, 5.05, sz, Color3.fromRGB(250, 250, 250), Enum.Material.SmoothPlastic)
			stripe.CFrame = CFrame.new(sx, 5.2, sz) * CFrame.Angles(tilt, 0, 0)
			-- A little merchandise: three coloured crates on the counter.
			for c = -1, 1 do
				box(g, "Crate", 1.1, 1.1, 1.1, sx + c * 2, 1.6, sz, awningColors[((i + c + 4) % 4) + 1], Enum.Material.SmoothPlastic)
			end
		end
	end
end

-- Ferris wheel state for the RotateWheel driver: every moving part's
-- original CFrame, rotated about the X axis through the hub each frame.
local wheelParts: { Part } = {}
local WHEEL_HUB = Vector3.new(-128, 26, -52)

local function buildFerrisWheel(root: Folder)
	local g = folder(root, "FerrisWheel")
	-- Two A-frame legs from the ground up to the hub at Y=26.
	for _, footZ in ipairs({ -62, -42 }) do
		local mid = Vector3.new(-128, 13, (footZ + -52) / 2)
		local tilt = math.atan2(footZ - -52, 26) -- lean in the YZ plane
		local leg = box(g, "Leg", 1.6, 28.5, 1.6, -128, 0, footZ, Color3.fromRGB(200, 60, 90), Enum.Material.Metal)
		leg.CFrame = CFrame.new(mid) * CFrame.Angles(-tilt, 0, 0)
	end
	local hub = box(g, "Hub", 3, 3, 3, -128, 24.5, -52, Color3.fromRGB(255, 209, 26), Enum.Material.Metal)
	hub.Shape = Enum.PartType.Ball
	-- The moving group: ring segments, spokes and 8 pods on the rim, in
	-- the YZ plane at X=-128 (the wheel faces the plaza, +X).
	local wheel = Instance.new("Model")
	wheel.Name = "Wheel"
	wheel.Parent = g
	local podColors = { Color3.fromRGB(255, 110, 110), Color3.fromRGB(255, 176, 32), Color3.fromRGB(120, 230, 140), Color3.fromRGB(90, 200, 255), Color3.fromRGB(178, 82, 255), Color3.fromRGB(255, 120, 200), Color3.fromRGB(120, 240, 220), Color3.fromRGB(250, 240, 150) }
	for seg = 0, 15 do
		local th = seg * math.pi / 8
		local y = WHEEL_HUB.Y + 20 * math.sin(th)
		local z = WHEEL_HUB.Z + 20 * math.cos(th)
		local segPart = box(wheel, "RingSegment", 1.2, 8.4, 1.8, -128, 0, -52, Color3.fromRGB(240, 240, 250), Enum.Material.Metal)
		segPart.CFrame = CFrame.new(-128, y, z) * CFrame.Angles(-th, 0, 0)
		table.insert(wheelParts, segPart)
	end
	for s = 0, 3 do
		local th = s * math.pi / 4
		local spoke = box(wheel, "Spoke", 0.8, 40, 0.8, -128, 0, -52, Color3.fromRGB(200, 200, 215), Enum.Material.Metal)
		spoke.CFrame = CFrame.new(WHEEL_HUB) * CFrame.Angles(-th, 0, 0)
		table.insert(wheelParts, spoke)
	end
	for pod = 0, 7 do
		local th = pod * math.pi / 4
		local y = WHEEL_HUB.Y + 20 * math.sin(th)
		local z = WHEEL_HUB.Z + 20 * math.cos(th)
		local p = box(wheel, "Pod", 3.4, 3, 3.4, -128, 0, -52, podColors[pod + 1], Enum.Material.SmoothPlastic)
		p.CFrame = CFrame.new(-128, y - 1.5, z)
		table.insert(wheelParts, p)
	end
	-- Sign on posts at (-112, -40), board centre Y=8.
	sign(g, -112, -40, 8, 15, 2.6, "BIANGLALA BRAINROT", Color3.fromRGB(200, 60, 90), Color3.fromRGB(255, 255, 255))
	return wheel
end

-- Rotate the wheel by `angle` radians about the X axis through the hub.
-- Original CFrames are captured lazily on the first call.
local wheelOriginals: { [Part]: CFrame } = nil
function WorldBuilder.RotateWheel(angle: number)
	if wheelOriginals == nil then
		wheelOriginals = {}
		for _, p in ipairs(wheelParts) do
			wheelOriginals[p] = p.CFrame
		end
	end
	local rot = CFrame.new(WHEEL_HUB) * CFrame.Angles(angle, 0, 0) * CFrame.new(-WHEEL_HUB)
	for _, p in ipairs(wheelParts) do
		p.CFrame = rot * wheelOriginals[p]
	end
end

local function buildTower(root: Folder)
	local g = folder(root, "Tower")
	-- Stacked tapering boxes from Y=0 to Y=44 at (128, -52).
	local layers = { { 18, 10 }, { 15, 9 }, { 12, 8 }, { 9, 7 }, { 6, 10 } }
	local colors = { Color3.fromRGB(120, 90, 200), Color3.fromRGB(140, 100, 215), Color3.fromRGB(160, 115, 230), Color3.fromRGB(185, 135, 245), Color3.fromRGB(210, 160, 255) }
	local y = 0
	for i, layer in ipairs(layers) do
		box(g, "Layer" .. i, layer[1], layer[2], layer[1], 128, y, -52, colors[i], Enum.Material.SmoothPlastic)
		y += layer[2]
	end
	-- Beacon sphere at Y=47 (its base rests on the Y=44 roof).
	local beacon = box(g, "Beacon", 6, 6, 6, 128, 44, -52, Color3.fromRGB(255, 90, 90), Enum.Material.Neon)
	beacon.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 90, 90)
	light.Range = 40
	light.Brightness = 2
	light.Parent = beacon
	sign(g, 112, -40, 8, 14, 2.6, "MENARA BRAINROT", Color3.fromRGB(120, 90, 200), Color3.fromRGB(255, 255, 255))
end

local function buildRainbowArch(root: Folder)
	-- 7 coloured arc segments from (-10, 58) up to Y=12 and back to
	-- (10, 58): boxes chorded across a semicircle of radius 10.
	local g = folder(root, "RainbowArch")
	local colors = { Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 140, 40), Color3.fromRGB(255, 220, 60), Color3.fromRGB(70, 210, 90), Color3.fromRGB(70, 150, 255), Color3.fromRGB(130, 90, 230), Color3.fromRGB(255, 110, 200) }
	for i = 1, 7 do
		local a0 = math.pi * (i - 1) / 7
		local a1 = math.pi * i / 7
		local x0, y0 = 10 * math.cos(a0), 10 * math.sin(a0)
		local x1, y1 = 10 * math.cos(a1), 10 * math.sin(a1)
		local mx, my = (x0 + x1) / 2, (y0 + y1) / 2
		local len = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2) + 0.7
		local seg = box(g, "ArcSegment" .. i, len, 1.4, 1.4, mx, 0, 58, colors[i], Enum.Material.Neon)
		seg.CFrame = CFrame.new(mx, my, 58) * CFrame.Angles(0, 0, math.atan2(y1 - y0, x1 - x0))
	end
end

local function buildBillboards(root: Folder)
	-- 6 rarity billboards on posts along the belt's south side (Z=14),
	-- board centres Y=7, one per rarity in ladder order.
	local rarities = { "COMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC", "DIVINE" }
	local colors = { Color3.fromRGB(180, 188, 196), Color3.fromRGB(64, 156, 255), Color3.fromRGB(178, 82, 255), Color3.fromRGB(255, 176, 32), Color3.fromRGB(255, 64, 96), Color3.fromRGB(255, 244, 160) }
	for i, x in ipairs({ -60, -36, -12, 12, 36, 60 }) do
		sign(root, x, 14, 7, 11, 2.6, rarities[i], colors[i], Color3.fromRGB(35, 35, 45))
	end
end

local function buildScatter(root: Folder)
	local g = folder(root, "Scatter")
	-- 14 trees along the map edges: trunk cylinder Y 0..4, foliage at Y=6.
	local treeSpots = { { -170, -130 }, { 170, -130 }, { -170, 130 }, { 170, 130 }, { -150, 0 }, { 150, 20 }, { -60, -132 }, { 60, 132 }, { 120, -132 }, { -120, 132 }, { 0, -136 }, { 0, 136 }, { 176, -60 }, { -176, 60 } }
	for i, spot in ipairs(treeSpots) do
		local trunk = disc(g, "TreeTrunk" .. i, 0.7, 4, spot[1], 4, spot[2], Color3.fromRGB(130, 90, 55), Enum.Material.Wood)
		trunk.Size = Vector3.new(4, 1.4, 1.4)
		trunk.CFrame = CFrame.new(spot[1], 2, spot[2]) * CFrame.Angles(0, 0, math.rad(90))
		local foliage = box(g, "TreeTop" .. i, 5.5, 5.5, 5.5, spot[1], 3.5, spot[2], Color3.fromRGB(50, 160, 60), Enum.Material.Grass)
		foliage.Shape = Enum.PartType.Ball
		foliage.CFrame = CFrame.new(spot[1], 6, spot[2])
	end
	-- 8 rocks, grey and lumpy (squashed balls half-buried look avoided:
	-- they sit on the ground like everything else).
	local rockSpots = { { -150, -100 }, { 150, 110 }, { -90, 136 }, { 90, -136 }, { 176, 90 }, { -176, -90 }, { 40, 140 }, { -40, -140 } }
	for i, spot in ipairs(rockSpots) do
		local rock = box(g, "Rock" .. i, 3.2, 2.2, 2.8, spot[1], 0, spot[2], Color3.fromRGB(140, 140, 150), Enum.Material.Slate)
		rock.CFrame = CFrame.new(spot[1], 1.1, spot[2]) * CFrame.Angles(0, math.rad(i * 37), 0)
	end
	-- 10 lamp posts along the paths: post to Y=7 plus a glowing sphere.
	local lampSpots = { { -30, 15 }, { 30, 15 }, { -60, 30 }, { 60, 30 }, { 0, 70 }, { -34, 60 }, { 34, 60 }, { -102, 60 }, { 102, 60 }, { 0, -20 } }
	for i, spot in ipairs(lampSpots) do
		box(g, "LampPost" .. i, 0.4, 7, 0.4, spot[1], 0, spot[2], Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
		local bulb = box(g, "LampBulb" .. i, 1.3, 1.3, 1.3, spot[1], 7, spot[2], Color3.fromRGB(255, 240, 170), Enum.Material.Neon)
		bulb.Shape = Enum.PartType.Ball
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 240, 170)
		light.Range = 18
		light.Brightness = 1.2
		light.Parent = bulb
	end
end

local function buildGacha(root: Folder)
	-- The gacha machine on the plaza at (-18, 44): a chunky base, a glass
	-- dome full of colourful capsules, and a crank. GachaService finds
	-- the base part by name and hangs its ProximityPrompt on it.
	local g = folder(root, "GachaMachine")
	local base = box(g, "GachaBase", 4.4, 3, 4.4, -18, 0, 44, Color3.fromRGB(255, 90, 140), Enum.Material.SmoothPlastic)
	base:SetAttribute("IsGacha", true)
	local dome = box(g, "GachaDome", 4, 4, 4, -18, 3, 44, Color3.fromRGB(200, 240, 255), Enum.Material.Glass)
	dome.Shape = Enum.PartType.Ball
	dome.Transparency = 0.4
	dome.CanCollide = false
	local rng = Random.new(7)
	for i = 1, 8 do
		local cap = box(g, "Capsule" .. i, 0.9, 0.9, 0.9, -18, 3.4, 44, Color3.fromHsv(rng:NextNumber(), 0.75, 1), Enum.Material.SmoothPlastic)
		cap.Shape = Enum.PartType.Ball
		cap.CFrame = CFrame.new(-18 + rng:NextNumber(-1.2, 1.2), 3.4 + rng:NextNumber(0, 1.4), 44 + rng:NextNumber(-1.2, 1.2))
		cap.CanCollide = false
	end
	box(g, "GachaCrank", 0.5, 1.6, 0.5, -15.6, 1.2, 44, Color3.fromRGB(255, 209, 26), Enum.Material.Metal)
	sign(g, -18, 51, 8, 11, 2.4, "GACHA BRAINROT", Color3.fromRGB(255, 90, 140), Color3.fromRGB(255, 255, 255))
	return base
end

-- A burst of procedural sparkle parts around a point (Divine spawns and
-- gacha jackpots). Returns the folder; the caller destroys it shortly.
function WorldBuilder.sparkleBurst(parent: Instance, at: Vector3): Folder
	local g = folder(parent, "SparkleBurst")
	local rng = Random.new(math.floor(os.clock() * 1000) % 100000)
	for i = 1, 12 do
		local s = box(g, "Spark" .. i, 0.45, 0.45, 0.45, at.X, 0, at.Z, Color3.fromHsv(rng:NextNumber(), 0.6, 1), Enum.Material.Neon)
		s.Shape = Enum.PartType.Ball
		s.CanCollide = false
		s.CFrame = CFrame.new(at + Vector3.new(rng:NextNumber(-2.4, 2.4), rng:NextNumber(0.5, 4), rng:NextNumber(-2.4, 2.4)))
	end
	return g
end

function WorldBuilder.Build(workspace: Workspace)
	local root = folder(workspace, "BrainrotBazaar")
	buildGroundAndPaths(root)
	local belt = buildBelt(root)
	buildSpawn(root)
	local plots = buildPlots(root)
	local water = buildFountain(root)
	buildStalls(root)
	buildFerrisWheel(root)
	buildTower(root)
	buildRainbowArch(root)
	buildBillboards(root)
	buildScatter(root)
	local gachaBase = buildGacha(root)
	local walkers = folder(workspace, "Walkers")
	return {
		Root = root,
		Belt = belt,
		Plots = plots,
		WalkersFolder = walkers,
		BeltTop = BELT_TOP,
		PadTop = PAD_TOP,
		FountainWater = water,
		GachaBase = gachaBase,
	}
end

return WorldBuilder
