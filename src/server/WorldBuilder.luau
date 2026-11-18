-- WorldBuilder.luau
-- Builds the whole Brainrot Bazaar map out of anchored parts: grass, the
-- concrete plaza, the conveyor belt with its shop arch, the spawn pad, the
-- welcome sign, eight base plots in two rows, and decorative trees, rocks
-- and lamp posts. Plot records are registered into GameState.Plots so the
-- rest of the server can claim and use them.

local GameState = require(script.Parent.GameState)

local WorldBuilder = {}

local PLOT_COLORS = {
	Color3.fromRGB(255, 99, 99),
	Color3.fromRGB(255, 165, 60),
	Color3.fromRGB(255, 230, 80),
	Color3.fromRGB(90, 210, 110),
	Color3.fromRGB(70, 170, 255),
	Color3.fromRGB(150, 100, 255),
	Color3.fromRGB(255, 110, 200),
	Color3.fromRGB(90, 230, 210),
}

local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function billboard(parent, adornee, size, offset, text, textColor, fontSize)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.AlwaysOnTop = true
	gui.Size = size
	gui.StudsOffset = offset
	gui.Adornee = adornee
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = textColor or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui
	return label
end

local function buildPlot(parent, index, centreX, centreZ)
	local folder = Instance.new("Folder")
	folder.Name = "Plot" .. index
	folder.Parent = parent

	local color = PLOT_COLORS[((index - 1) % #PLOT_COLORS) + 1]
	local floor = part(folder, "Floor", Vector3.new(56, 1, 40), Vector3.new(centreX, 0.5, centreZ), color, Enum.Material.SmoothPlastic)
	floor:SetAttribute("PlotIndex", index)

	-- Six brainrot pads in two rows of three, on the half away from plaza.
	local pads = {}
	local rowDirection = centreZ < 0 and -1 or 1
	for i = 1, 6 do
		local col = (i - 1) % 3
		local row = math.floor((i - 1) / 3)
		local px = centreX + (col - 1) * 12
		local pz = centreZ + rowDirection * (4 + row * 11)
		local pad = part(folder, "Pad" .. i, Vector3.new(8, 0.4, 8), Vector3.new(px, 1.2, pz), color:Lerp(Color3.new(1, 1, 1), 0.35), Enum.Material.Neon)
		table.insert(pads, pad)
	end

	-- Green collect pad near the plaza-facing edge of the plot.
	local collectZ = centreZ - rowDirection * 14
	local collect = part(folder, "CollectPad", Vector3.new(10, 0.4, 6), Vector3.new(centreX, 1.2, collectZ), Color3.fromRGB(40, 220, 80), Enum.Material.Neon)
	collect.Name = "CollectPad"

	-- Lock button block with its proximity prompt.
	local lockBlock = part(folder, "LockButton", Vector3.new(3, 3, 3), Vector3.new(centreX + 22, 2.5, collectZ), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LockPrompt"
	prompt.ActionText = "Lock 60 detik"
	prompt.ObjectText = "Kunci Base"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.Parent = lockBlock

	-- Owner sign post + billboard; text is refreshed by the server tick.
	local post = part(folder, "SignPost", Vector3.new(1, 7, 1), Vector3.new(centreX - 22, 3.5, collectZ), Color3.fromRGB(100, 70, 40), Enum.Material.Wood)
	local signLabel = billboard(folder, post, UDim2.fromOffset(300, 90), Vector3.new(0, 5, 0), "Base kosong", Color3.new(1, 1, 1))

	-- Lock barriers: four walls that only appear (solid + visible) while the
	-- base is locked.
	local barriers = {}
	local wallSpecs = {
		{ Vector3.new(56, 8, 1), Vector3.new(centreX, 4, centreZ - 20) },
		{ Vector3.new(56, 8, 1), Vector3.new(centreX, 4, centreZ + 20) },
		{ Vector3.new(1, 8, 40), Vector3.new(centreX - 28, 4, centreZ) },
		{ Vector3.new(1, 8, 40), Vector3.new(centreX + 28, 4, centreZ) },
	}
	for i, spec in ipairs(wallSpecs) do
		local wall = part(folder, "Barrier" .. i, spec[1], spec[2], Color3.fromRGB(120, 200, 255), Enum.Material.Glass)
		wall.Transparency = 1
		wall.CanCollide = false
		table.insert(barriers, wall)
	end

	local plot = {
		Index = index,
		Folder = folder,
		Floor = floor,
		Pads = pads,
		CollectPad = collect,
		LockButton = lockBlock,
		LockPrompt = prompt,
		SignLabel = signLabel,
		Barriers = barriers,
		Owner = nil,
		Stored = 0,
		LockedUntil = 0,
		Centre = Vector3.new(centreX, 1, centreZ),
	}
	table.insert(GameState.Plots, plot)
	return plot
end

local function buildDecor(parent)
	-- Trees: trunk + leafy ball, scattered outside the plaza and plots.
	local treeSpots = {
		{ -150, -40 }, { -150, 40 }, { 150, -40 }, { 150, 40 },
		{ -80, -130 }, { 0, -135 }, { 80, -130 }, { -80, 130 },
		{ 0, 135 }, { 80, 130 }, { -170, 0 }, { 170, 0 },
	}
	for i, spot in ipairs(treeSpots) do
		part(parent, "TreeTrunk" .. i, Vector3.new(2, 7, 2), Vector3.new(spot[1], 3.5, spot[2]), Color3.fromRGB(110, 75, 40), Enum.Material.Wood)
		local leaves = part(parent, "TreeLeaves" .. i, Vector3.new(9, 8, 9), Vector3.new(spot[1], 10, spot[2]), Color3.fromRGB(60, 160, 70), Enum.Material.SmoothPlastic)
		leaves.Shape = Enum.PartType.Ball
	end
	-- Rocks: grey boulders near the map corners.
	for i, spot in ipairs({ { -185, -120 }, { 185, -120 }, { -185, 120 }, { 185, 120 }, { -130, 60 }, { 130, -60 } }) do
		local rock = part(parent, "Rock" .. i, Vector3.new(5, 3.5, 5), Vector3.new(spot[1], 1.75, spot[2]), Color3.fromRGB(130, 130, 135), Enum.Material.Slate)
		rock.Shape = Enum.PartType.Ball
	end
	-- Lamp posts along the plaza edges, glowing at the top.
	for _, x in ipairs({ -60, -20, 20, 60 }) do
		for _, z in ipairs({ -28, 28 }) do
			part(parent, "LampPost", Vector3.new(0.7, 9, 0.7), Vector3.new(x, 4.5, z), Color3.fromRGB(40, 40, 45), Enum.Material.Metal)
			local bulb = part(parent, "LampBulb", Vector3.new(1.6, 1.6, 1.6), Vector3.new(x, 9.4, z), Color3.fromRGB(255, 240, 170), Enum.Material.Neon)
			bulb.Shape = Enum.PartType.Ball
		end
	end
end

-- Build everything and return the workspace folder that holds it.
function WorldBuilder.Build()
	local world = Instance.new("Folder")
	world.Name = "BrainrotBazaar"
	world.Parent = workspace

	-- Grass ground far below the plaza pieces.
	part(world, "Grass", Vector3.new(440, 1, 340), Vector3.new(0, -0.5, 0), Color3.fromRGB(95, 190, 85), Enum.Material.Grass)

	-- Concrete plaza at the origin.
	part(world, "Plaza", Vector3.new(170, 1, 46), Vector3.new(0, 0.05, 0), Color3.fromRGB(165, 165, 170), Enum.Material.Concrete)

	-- Conveyor belt along X at z = 0, top at y ~= 1.3, with orange rails.
	local belt = part(world, "Belt", Vector3.new(140, 1.3, 10), Vector3.new(0, 0.65, 0), Color3.fromRGB(45, 45, 55), Enum.Material.DiamondPlate)
	belt.Name = "ConveyorBelt"
	for _, side in ipairs({ -5.6, 5.6 }) do
		part(world, "BeltRail", Vector3.new(140, 0.8, 0.6), Vector3.new(0, 1.7, side), Color3.fromRGB(255, 130, 30), Enum.Material.Neon)
	end

	-- Pink shop arch at the west end of the belt.
	local archColor = Color3.fromRGB(255, 110, 180)
	part(world, "ArchLeft", Vector3.new(2, 12, 2), Vector3.new(-70, 6, -7), archColor, Enum.Material.SmoothPlastic)
	part(world, "ArchRight", Vector3.new(2, 12, 2), Vector3.new(-70, 6, 7), archColor, Enum.Material.SmoothPlastic)
	local archTop = part(world, "ArchTop", Vector3.new(2, 3, 16), Vector3.new(-70, 13, 0), archColor, Enum.Material.SmoothPlastic)
	billboard(world, archTop, UDim2.fromOffset(320, 70), Vector3.new(0, 3.5, 0), "TOKO BRAINROT", Color3.fromRGB(255, 255, 255))

	-- Yellow spawn pad south of the plaza (a SpawnLocation doubles as the
	-- visible pad and the respawn point).
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "SpawnLocation"
	spawnLocation.Size = Vector3.new(14, 1, 14)
	spawnLocation.Position = Vector3.new(0, 0.8, 26)
	spawnLocation.Color = Color3.fromRGB(255, 220, 50)
	spawnLocation.Material = Enum.Material.Neon
	spawnLocation.Anchored = true
	spawnLocation.Neutral = true
	spawnLocation.Parent = world

	-- Wooden welcome sign further south.
	local signPost = part(world, "WelcomePost", Vector3.new(1.2, 8, 1.2), Vector3.new(0, 4, 40), Color3.fromRGB(110, 75, 40), Enum.Material.Wood)
	local signBoard = part(world, "WelcomeBoard", Vector3.new(22, 6, 0.8), Vector3.new(0, 9, 40), Color3.fromRGB(140, 95, 55), Enum.Material.Wood)
	billboard(world, signBoard, UDim2.fromOffset(420, 110), Vector3.new(0, 1, 0), "BRAINROT BAZAAR\nSelamat datang di pasar brainrot!", Color3.fromRGB(255, 240, 200))
	signPost.Parent = world

	-- Eight plots: two rows of four.
	local plotFolder = Instance.new("Folder")
	plotFolder.Name = "Plots"
	plotFolder.Parent = world
	local index = 0
	for _, z in ipairs({ -84, 84 }) do
		for _, x in ipairs({ -102, -34, 34, 102 }) do
			index += 1
			buildPlot(plotFolder, index, x, z)
		end
	end

	buildDecor(world)

	return world
end

-- Show or hide a plot's lock barriers.
function WorldBuilder.SetBarriersVisible(plot, visible)
	for _, wall in ipairs(plot.Barriers) do
		wall.Transparency = visible and 0.45 or 1
		wall.CanCollide = visible
	end
end

return WorldBuilder
