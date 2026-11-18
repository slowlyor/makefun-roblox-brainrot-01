-- WorldBuilder.luau
-- Builds the whole Brainrot Bazaar map out of parts at server start: ground,
-- the shop conveyor, eight player bases (pads, collect pad, lock button,
-- owner sign, lock barriers) and decorations. Nothing is authored in the
-- project tree, so the place works the moment Play is pressed.

local GameState = require(script.Parent:WaitForChild("GameState"))

local WorldBuilder = {}

WorldBuilder.Layout = {
	BeltY = 1.3, -- feet height while riding the conveyor
	BeltStartX = -64,
	BeltEndX = 64,
	BeltZ = 0,
	WaveWallZ = 0,
}

local PLOT_COLORS = {
	Color3.fromRGB(255, 183, 165),
	Color3.fromRGB(165, 220, 255),
	Color3.fromRGB(190, 255, 190),
	Color3.fromRGB(255, 240, 170),
	Color3.fromRGB(230, 190, 255),
	Color3.fromRGB(255, 205, 225),
	Color3.fromRGB(180, 255, 240),
	Color3.fromRGB(255, 220, 185),
}

local function part(name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.Parent = parent
	return p
end

local function billboard(parent: Instance, size: Vector2, offset: Vector3): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffset = offset
	gui.AlwaysOnTop = true
	gui.MaxDistance = 160
	gui.Parent = parent
	return gui
end

local function boardLabel(gui: GuiObject, name: string, text: string, yScale: number, hScale: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, yScale)
	label.Size = UDim2.fromScale(1, hScale)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextStrokeTransparency = 0.4
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
	return label
end

local function buildPlot(index: number, center: Vector3, parent: Folder)
	local folder = Instance.new("Folder")
	folder.Name = "Plot" .. index
	folder.Parent = parent

	local floorColor = PLOT_COLORS[((index - 1) % #PLOT_COLORS) + 1]
	local floor = part("Floor", Vector3.new(44, 0.5, 44), center + Vector3.new(0, 0.25, 0), floorColor, Enum.Material.SmoothPlastic, folder)
	floor.TopSurface = Enum.SurfaceType.Smooth

	-- Border trim
	local trimColor = floorColor:Lerp(Color3.fromRGB(40, 40, 50), 0.45)
	part("TrimN", Vector3.new(44, 1, 1), center + Vector3.new(0, 0.6, -22), trimColor, nil, folder)
	part("TrimS", Vector3.new(44, 1, 1), center + Vector3.new(0, 0.6, 22), trimColor, nil, folder)
	part("TrimE", Vector3.new(1, 1, 44), center + Vector3.new(22, 0.6, 0), trimColor, nil, folder)
	part("TrimW", Vector3.new(1, 1, 44), center + Vector3.new(-22, 0.6, 0), trimColor, nil, folder)

	-- Six brainrot pads in two rows of three; feet rest at y = 1.0.
	local padPositions = {}
	local padOccupants = {}
	for row, dz in ipairs({ -10, 10 }) do
		for col, dx in ipairs({ -13, 0, 13 }) do
			local padIndex = (row - 1) * 3 + col
			local padPos = center + Vector3.new(dx, 0, dz)
			part("Pad" .. padIndex, Vector3.new(8, 0.5, 8), padPos + Vector3.new(0, 0.75, 0), Color3.fromRGB(52, 56, 68), Enum.Material.Slate, folder)
			padPositions[padIndex] = padPos + Vector3.new(0, 1.0, 0)
			padOccupants[padIndex] = nil
		end
	end

	-- Front of the plot faces the conveyor (toward z = 0).
	local frontSign = center.Z < 0 and 1 or -1

	-- Collect pad: step on it to bank the cash your brainrots earned.
	local collectPad = part("CollectPad", Vector3.new(12, 0.5, 6),
		center + Vector3.new(0, 0.75, frontSign * 17), Color3.fromRGB(60, 220, 110), Enum.Material.Neon, folder)
	local collectGui = billboard(collectPad, Vector2.new(200, 60), Vector3.new(0, 3.4, 0))
	local collectLabel = boardLabel(collectGui, "Amount", "$0", 0, 1, Color3.fromRGB(190, 255, 205))

	-- Lock button on a post by the front-right corner.
	local lockBasePos = center + Vector3.new(18, 0, frontSign * 18)
	part("LockPost", Vector3.new(0.8, 3, 0.8), lockBasePos + Vector3.new(0, 1.5, 0), Color3.fromRGB(60, 60, 70), Enum.Material.Metal, folder)
	local lockButton = part("LockButton", Vector3.new(1.8, 0.6, 1.8), lockBasePos + Vector3.new(0, 3.3, 0), Color3.fromRGB(235, 60, 60), Enum.Material.SmoothPlastic, folder)
	lockButton.Shape = Enum.PartType.Cylinder
	local lockPrompt = Instance.new("ProximityPrompt")
	lockPrompt.Name = "LockPrompt"
	lockPrompt.ActionText = "Kunci Basis"
	lockPrompt.ObjectText = "Lock 60 detik"
	lockPrompt.HoldDuration = 0.4
	lockPrompt.MaxActivationDistance = 12
	lockPrompt.Parent = lockButton

	-- Owner sign on a pole at the back.
	local signPolePos = center + Vector3.new(-18, 0, -frontSign * 19)
	part("SignPole", Vector3.new(0.7, 8, 0.7), signPolePos + Vector3.new(0, 4, 0), Color3.fromRGB(80, 60, 40), Enum.Material.Wood, folder)
	local signBoard = part("SignBoard", Vector3.new(10, 4.5, 0.6), signPolePos + Vector3.new(0, 9, 0), Color3.fromRGB(50, 45, 60), Enum.Material.Wood, folder)
	local signGui = billboard(signBoard, Vector2.new(280, 100), Vector3.new(0, 0.5, 0))
	local signName = boardLabel(signGui, "Owner", "Basis Kosong", 0, 0.55, Color3.fromRGB(255, 255, 255))
	local signInfo = boardLabel(signGui, "Info", "menunggu pemain...", 0.55, 0.45, Color3.fromRGB(200, 220, 255))

	-- Lock barriers: invisible walls that appear while the base is locked.
	local barriers = {}
	local barrierColor = Color3.fromRGB(110, 200, 255)
	local function barrier(name: string, size: Vector3, offset: Vector3)
		local b = part(name, size, center + offset, barrierColor, Enum.Material.ForceField, folder)
		b.Transparency = 1
		b.CanCollide = false
		table.insert(barriers, b)
		return b
	end
	barrier("BarrierN", Vector3.new(44, 9, 1), Vector3.new(0, 4.5, -22))
	barrier("BarrierS", Vector3.new(44, 9, 1), Vector3.new(0, 4.5, 22))
	barrier("BarrierE", Vector3.new(1, 9, 44), Vector3.new(22, 4.5, 0))
	barrier("BarrierW", Vector3.new(1, 9, 44), Vector3.new(-22, 4.5, 0))

	return {
		Index = index,
		Center = center,
		PadPositions = padPositions,
		PadOccupants = padOccupants,
		CollectPad = collectPad,
		CollectLabel = collectLabel,
		LockPrompt = lockPrompt,
		LockButton = lockButton,
		SignName = signName,
		SignInfo = signInfo,
		Barriers = barriers,
		Owner = nil,
		Locked = false,
		LockUntil = 0,
		Folder = folder,
	}
end

local function buildDecor(parent: Folder)
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = parent

	-- Trees around the edges and between bases.
	local treeSpots = {
		Vector3.new(-150, 0, -60), Vector3.new(150, 0, -60), Vector3.new(-150, 0, 60), Vector3.new(150, 0, 60),
		Vector3.new(-58, 0, -120), Vector3.new(58, 0, -120), Vector3.new(-58, 0, 120), Vector3.new(58, 0, 120),
		Vector3.new(-170, 0, 0), Vector3.new(170, 0, 0), Vector3.new(0, 0, -135), Vector3.new(0, 0, 135),
	}
	for i, spot in ipairs(treeSpots) do
		part("Trunk" .. i, Vector3.new(1.4, 6, 1.4), spot + Vector3.new(0, 3, 0), Color3.fromRGB(110, 78, 48), Enum.Material.Wood, decor)
		local leaves = part("Leaves" .. i, Vector3.new(6, 6, 6), spot + Vector3.new(0, 8.5, 0), Color3.fromRGB(70, 160, 75), Enum.Material.Grass, decor)
		leaves.Shape = Enum.PartType.Ball
		local leavesTop = part("LeavesTop" .. i, Vector3.new(4, 4, 4), spot + Vector3.new(0, 11.5, 0), Color3.fromRGB(85, 180, 90), Enum.Material.Grass, decor)
		leavesTop.Shape = Enum.PartType.Ball
	end

	-- Rocks.
	for i, spot in ipairs({
		Vector3.new(-120, 0, -20), Vector3.new(125, 0, 25), Vector3.new(-80, 0, 118),
		Vector3.new(85, 0, -118), Vector3.new(190, 0, -100), Vector3.new(-190, 0, 105),
	}) do
		local rock = part("Rock" .. i, Vector3.new(3.5, 2.5, 3.5), spot + Vector3.new(0, 0.6, 0), Color3.fromRGB(130, 130, 140), Enum.Material.Slate, decor)
		rock.Shape = Enum.PartType.Ball
	end

	-- Lamp posts along the plaza.
	for _, x in ipairs({ -50, -17, 17, 50 }) do
		for _, z in ipairs({ -16, 16 }) do
			part("LampPost", Vector3.new(0.45, 7, 0.45), Vector3.new(x, 3.5, z), Color3.fromRGB(45, 45, 55), Enum.Material.Metal, decor)
			local bulb = part("LampBulb", Vector3.new(1.3, 1.3, 1.3), Vector3.new(x, 7.4, z), Color3.fromRGB(255, 230, 160), Enum.Material.Neon, decor)
			bulb.Shape = Enum.PartType.Ball
		end
	end

	-- Welcome sign behind the spawn point.
	local signPos = Vector3.new(0, 0, 40)
	part("WelcomePostL", Vector3.new(1, 11, 1), signPos + Vector3.new(-11, 5.5, 0), Color3.fromRGB(90, 65, 40), Enum.Material.Wood, decor)
	part("WelcomePostR", Vector3.new(1, 11, 1), signPos + Vector3.new(11, 5.5, 0), Color3.fromRGB(90, 65, 40), Enum.Material.Wood, decor)
	local board = part("WelcomeBoard", Vector3.new(24, 7, 1), signPos + Vector3.new(0, 9, 0), Color3.fromRGB(255, 170, 60), Enum.Material.Wood, decor)
	local gui = billboard(board, Vector2.new(560, 150), Vector3.new(0, 0.5, 0))
	boardLabel(gui, "Title", "BRAINROT BAZAAR", 0, 0.55, Color3.fromRGB(255, 255, 255))
	boardLabel(gui, "Sub", "beli di conveyor - kumpulkan cash - kunci basismu!", 0.55, 0.45, Color3.fromRGB(255, 245, 210))
end

function WorldBuilder.Build()
	local world = Instance.new("Folder")
	world.Name = "BrainrotWorld"
	world.Parent = workspace

	local live = Instance.new("Folder")
	live.Name = "LiveBrainrots"
	live.Parent = world

	-- Ground and plaza.
	local ground = part("Ground", Vector3.new(460, 1, 340), Vector3.new(0, -0.5, 0), Color3.fromRGB(96, 165, 82), Enum.Material.Grass, world)
	ground.TopSurface = Enum.SurfaceType.Smooth
	part("Plaza", Vector3.new(170, 0.3, 46), Vector3.new(0, 0.15, 0), Color3.fromRGB(196, 188, 170), Enum.Material.Concrete, world)

	-- Spawn.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = Vector3.new(0, 0.5, 26)
	spawn.Color = Color3.fromRGB(255, 205, 80)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.35
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = world

	-- Conveyor: belt, rails and the shop arch.
	local belt = part("Belt", Vector3.new(140, 1, 10), Vector3.new(0, 0.8, 0), Color3.fromRGB(40, 40, 48), Enum.Material.DiamondPlate, world)
	belt.TopSurface = Enum.SurfaceType.Smooth
	part("RailN", Vector3.new(140, 0.9, 0.6), Vector3.new(0, 1.2, -5.4), Color3.fromRGB(255, 170, 60), Enum.Material.Metal, world)
	part("RailS", Vector3.new(140, 0.9, 0.6), Vector3.new(0, 1.2, 5.4), Color3.fromRGB(255, 170, 60), Enum.Material.Metal, world)
	part("ArchPostL", Vector3.new(1.2, 11, 1.2), Vector3.new(-70, 5.5, -6.5), Color3.fromRGB(255, 120, 150), Enum.Material.SmoothPlastic, world)
	part("ArchPostR", Vector3.new(1.2, 11, 1.2), Vector3.new(-70, 5.5, 6.5), Color3.fromRGB(255, 120, 150), Enum.Material.SmoothPlastic, world)
	local archTop = part("ArchTop", Vector3.new(1.6, 2.4, 15), Vector3.new(-70, 11.5, 0), Color3.fromRGB(255, 120, 150), Enum.Material.SmoothPlastic, world)
	local archGui = billboard(archTop, Vector2.new(420, 90), Vector3.new(0, 1.5, 0))
	boardLabel(archGui, "Title", "TOKO BRAINROT", 0, 1, Color3.fromRGB(255, 255, 255))

	-- Player bases: two rows of four.
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = world
	local plots = {}
	local index = 0
	for _, z in ipairs({ -84, 84 }) do
		for _, x in ipairs({ -102, -34, 34, 102 }) do
			index += 1
			plots[index] = buildPlot(index, Vector3.new(x, 0, z), plotsFolder)
		end
	end

	buildDecor(world)

	GameState.Plots = plots
	return plots
end

return WorldBuilder
