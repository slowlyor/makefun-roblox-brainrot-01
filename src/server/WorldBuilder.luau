-- WorldBuilder.luau
-- Builds the whole Brainrot Bazaar world from procedural Parts: ground,
-- central plaza, the TOKO BRAINROT conveyor shop, eight player bases, and
-- the dressing that makes the place read at a glance — fountain, market
-- stalls, the BIANGLALA BRAINROT ferris wheel, MENARA BRAINROT tower,
-- rainbow arch, trees, rocks, lamps and big readable signs.

local WorldBuilder = {}

local function part(parent, name, size, cframe, color, material)
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

-- A free-standing sign: post plus a board with a SurfaceGui text face.
function WorldBuilder.MakeSign(parent, name, text, position, size, boardColor, textColor, fontSize)
	local group = Instance.new("Model")
	group.Name = name
	group.Parent = parent
	local post = part(group, "Post", Vector3.new(0.6, size.Y + 3, 0.6),
		CFrame.new(position.X, (size.Y + 3) / 2, position.Z), Color3.fromRGB(90, 70, 50), Enum.Material.Wood)
	post.CanCollide = false
	local board = part(group, "Board", size,
		CFrame.new(position.X, size.Y + 3 + size.Y / 2 - 1, position.Z), boardColor, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.Parent = gui
	local back = gui:Clone()
	back.Face = Enum.NormalId.Back
	back.Parent = board
	return group
end

-- A billboard-style floating sign that always faces the camera.
local function floatingSign(parent, name, text, position, size, color)
	local anchor = part(parent, name, Vector3.new(1, 1, 1), CFrame.new(position),
		Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	anchor.Transparency = 1
	anchor.CanCollide = false
	local gui = Instance.new("BillboardGui")
	gui.Name = "SignGui"
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.AlwaysOnTop = false
	gui.Adornee = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
	label.BackgroundTransparency = 0.15
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color
	label.Parent = gui
	gui.Parent = anchor
	return anchor
end

local function buildGround(world)
	part(world, "Ground", Vector3.new(240, 2, 240), CFrame.new(0, -1, 20),
		Color3.fromRGB(105, 190, 95), Enum.Material.Grass)
	part(world, "Plaza", Vector3.new(56, 0.6, 56), CFrame.new(0, 0.3, 0),
		Color3.fromRGB(235, 215, 170), Enum.Material.Sand)
	-- Plaza ring trim.
	part(world, "PlazaTrim", Vector3.new(60, 0.35, 60), CFrame.new(0, 0.15, 0),
		Color3.fromRGB(200, 120, 90), Enum.Material.Brick)
end

local function buildFountain(world)
	local fountain = Instance.new("Model")
	fountain.Name = "Fountain"
	fountain.Parent = world
	part(fountain, "Basin", Vector3.new(16, 1.6, 16), CFrame.new(0, 0.8, 0),
		Color3.fromRGB(170, 180, 195), Enum.Material.Marble)
	local rim = part(fountain, "Rim", Vector3.new(17.5, 0.7, 17.5), CFrame.new(0, 1.7, 0),
		Color3.fromRGB(140, 150, 170), Enum.Material.Marble)
	rim.Shape = Enum.PartType.Cylinder
	local pillar = part(fountain, "Pillar", Vector3.new(2.2, 6, 2.2), CFrame.new(0, 3.5, 0),
		Color3.fromRGB(170, 180, 195), Enum.Material.Marble)
	pillar.Shape = Enum.PartType.Cylinder
	local crown = part(fountain, "Crown", Vector3.new(3.4, 3.4, 3.4), CFrame.new(0, 7.6, 0),
		Color3.fromRGB(255, 205, 60), Enum.Material.Neon)
	crown.Shape = Enum.PartType.Ball
	-- The animated water disc: WorldBuilder.Animate spins and pulses it.
	local water = part(fountain, "WaterDisc", Vector3.new(14.5, 0.4, 14.5), CFrame.new(0, 1.75, 0),
		Color3.fromRGB(70, 180, 255), Enum.Material.Glass)
	water.Shape = Enum.PartType.Cylinder
	water.Transparency = 0.3
	water.CanCollide = false
	return water
end

local function buildStall(world, index, position, awningColor)
	local stall = Instance.new("Model")
	stall.Name = "Stall" .. index
	stall.Parent = world
	local baseAngle = math.atan2(-position.X, -position.Z)
	part(stall, "Counter", Vector3.new(10, 2.4, 4), CFrame.new(position) * CFrame.Angles(0, baseAngle, 0) * CFrame.new(0, 1.2, 0),
		Color3.fromRGB(160, 110, 70), Enum.Material.Wood)
	for _, dx in ipairs({ -4.5, 4.5 }) do
		part(stall, "Pole", Vector3.new(0.4, 6.5, 0.4),
			CFrame.new(position) * CFrame.Angles(0, baseAngle, 0) * CFrame.new(dx, 3.25, -1.5),
			Color3.fromRGB(110, 80, 55), Enum.Material.Wood)
	end
	-- Striped awning: alternating colour slats tilted over the counter.
	for i = 0, 5 do
		local stripeColor = i % 2 == 0 and awningColor or Color3.fromRGB(255, 255, 255)
		part(stall, "AwningStripe", Vector3.new(1.8, 0.25, 6.5),
			CFrame.new(position) * CFrame.Angles(0, baseAngle, 0) * CFrame.new(-4.5 + i * 1.8, 6.2, 0) * CFrame.Angles(0.35, 0, 0),
			stripeColor, Enum.Material.Fabric)
	end
	-- Crates of colourful "goods" on the counter.
	for i = 1, 3 do
		part(stall, "Crate", Vector3.new(1.6, 1.6, 1.6),
			CFrame.new(position) * CFrame.Angles(0, baseAngle, 0) * CFrame.new(-3 + i * 2.4, 3.2, 0),
			Color3.fromHSV(i * 0.22, 0.6, 0.95), Enum.Material.SmoothPlastic)
	end
	return stall
end

local function buildFerrisWheel(world)
	local wheel = Instance.new("Model")
	wheel.Name = "BianglalaBrainrot"
	wheel.Parent = world
	local center = Vector3.new(-95, 26, -20)
	for _, dz in ipairs({ -3, 3 }) do
		part(wheel, "Leg", Vector3.new(1.2, 28, 1.2),
			CFrame.new(center.X, 13, center.Z + dz) * CFrame.Angles(0.25, 0, 0),
			Color3.fromRGB(255, 120, 170), Enum.Material.Metal)
	end
	local hub = part(wheel, "Hub", Vector3.new(3, 3, 8), CFrame.new(center),
		Color3.fromRGB(255, 205, 60), Enum.Material.Neon)
	hub.Shape = Enum.PartType.Cylinder
	-- The rotating group: spokes and brainrot pods around the hub.
	local rotor = Instance.new("Model")
	rotor.Name = "Rotor"
	rotor.Parent = wheel
	local pivot = part(rotor, "Pivot", Vector3.new(1, 1, 1), CFrame.new(center),
		Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	pivot.Transparency = 1
	pivot.CanCollide = false
	rotor.PrimaryPart = pivot
	for i = 1, 8 do
		local angle = (i - 1) * math.pi / 4
		local rimPos = center + Vector3.new(math.cos(angle) * 17, math.sin(angle) * 17, 0)
		local spoke = part(rotor, "Spoke", Vector3.new(17, 0.7, 0.7),
			CFrame.new((center + rimPos) / 2) * CFrame.Angles(0, 0, angle),
			Color3.fromRGB(120, 200, 255), Enum.Material.Metal)
		spoke.CanCollide = false
		local pod = part(rotor, "Pod", Vector3.new(4.2, 3.6, 4.2), CFrame.new(rimPos),
			Color3.fromHSV(i / 8, 0.65, 1), Enum.Material.SmoothPlastic)
		pod.CanCollide = false
		local rider = part(rotor, "PodRider", Vector3.new(2, 2, 2),
			CFrame.new(rimPos + Vector3.new(0, 2.6, 0)), Color3.fromHSV(i / 8 + 0.4, 0.6, 1),
			Enum.Material.SmoothPlastic)
		rider.CanCollide = false
	end
	floatingSign(wheel, "WheelSign", "BIANGLALA BRAINROT", center + Vector3.new(0, -24, -6),
		Vector2.new(300, 60), Color3.fromRGB(255, 170, 220))
	return rotor
end

local function buildTower(world)
	local tower = Instance.new("Model")
	tower.Name = "MenaraBrainrot"
	tower.Parent = world
	local basePos = Vector3.new(98, 0, -24)
	for level = 0, 5 do
		local width = 13 - level * 1.4
		part(tower, "Level", Vector3.new(width, 7, width),
			CFrame.new(basePos.X, 3.5 + level * 7, basePos.Z),
			Color3.fromHSV(0.75 - level * 0.04, 0.45, 0.9), Enum.Material.Brick)
	end
	local beacon = part(tower, "Beacon", Vector3.new(3.2, 3.2, 3.2), CFrame.new(basePos.X, 47, basePos.Z),
		Color3.fromRGB(255, 80, 80), Enum.Material.Neon)
	beacon.Shape = Enum.PartType.Ball
	beacon.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 120)
	light.Range = 40
	light.Brightness = 2
	light.Parent = beacon
	floatingSign(tower, "TowerSign", "MENARA BRAINROT", basePos + Vector3.new(0, 54, 0),
		Vector2.new(280, 56), Color3.fromRGB(255, 150, 150))
	return beacon
end

local function buildRainbowArch(world, position)
	local arch = Instance.new("Model")
	arch.Name = "RainbowArch"
	arch.Parent = world
	local colors = {
		Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 160, 40),
		Color3.fromRGB(255, 235, 90), Color3.fromRGB(90, 220, 110),
		Color3.fromRGB(80, 160, 255), Color3.fromRGB(180, 100, 255),
	}
	for band, color in ipairs(colors) do
		local radius = 10 + band * 1.1
		for step = 0, 10 do
			local angle = math.pi * step / 10
			local segPos = position + Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, 0)
			local seg = part(arch, "ArchBand", Vector3.new(2.6, 1.05, 1.6), CFrame.new(segPos),
				color, Enum.Material.Neon)
			seg.CanCollide = false
		end
	end
	return arch
end

local function buildTree(world, position, scale)
	local tree = Instance.new("Model")
	tree.Name = "Tree"
	tree.Parent = world
	part(tree, "Trunk", Vector3.new(1.2 * scale, 4 * scale, 1.2 * scale),
		CFrame.new(position.X, 2 * scale, position.Z), Color3.fromRGB(120, 85, 55), Enum.Material.Wood)
	local leaves = part(tree, "Leaves", Vector3.new(5 * scale, 5 * scale, 5 * scale),
		CFrame.new(position.X, (4 + 2.5) * scale, position.Z), Color3.fromRGB(60, 165, 70), Enum.Material.Grass)
	leaves.Shape = Enum.PartType.Ball
	leaves.CanCollide = false
end

local function buildRock(world, position, scale)
	local rock = part(world, "Rock", Vector3.new(2.4 * scale, 1.6 * scale, 2 * scale),
		CFrame.new(position) * CFrame.Angles(0, position.X, 0.3), Color3.fromRGB(140, 140, 150), Enum.Material.Rock)
	rock.CanCollide = true
end

local function buildLamp(world, position)
	local lamp = Instance.new("Model")
	lamp.Name = "Lamp"
	lamp.Parent = world
	part(lamp, "Pole", Vector3.new(0.35, 6, 0.35), CFrame.new(position.X, 3, position.Z),
		Color3.fromRGB(50, 50, 60), Enum.Material.Metal)
	local bulb = part(lamp, "Bulb", Vector3.new(1.1, 1.1, 1.1), CFrame.new(position.X, 6.4, position.Z),
		Color3.fromRGB(255, 240, 170), Enum.Material.Neon)
	bulb.Shape = Enum.PartType.Ball
	bulb.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 240, 190)
	light.Range = 18
	light.Brightness = 1.2
	light.Parent = bulb
end

-- Build everything and return the animated handles:
-- { WaterDisc, WheelRotor, TowerBeacon, World }
function WorldBuilder.Build(gameState)
	local world = Instance.new("Folder")
	world.Name = "BazaarWorld"
	world.Parent = workspace

	buildGround(world)
	local water = buildFountain(world)

	local stallColors = {
		Color3.fromRGB(255, 90, 90), Color3.fromRGB(70, 170, 255),
		Color3.fromRGB(255, 190, 50), Color3.fromRGB(140, 230, 130),
	}
	local stallSpots = {
		Vector3.new(-22, 0, -20), Vector3.new(22, 0, -20),
		Vector3.new(-22, 0, 20), Vector3.new(22, 0, 20),
	}
	for i, spot in ipairs(stallSpots) do
		buildStall(world, i, spot, stallColors[i])
	end

	local rotor = buildFerrisWheel(world)
	local beacon = buildTower(world)
	buildRainbowArch(world, Vector3.new(0, 0, 68))

	-- Nature and light dressing scattered between the landmarks.
	local treeSpots = {
		Vector3.new(-40, 0, -34), Vector3.new(42, 0, -36), Vector3.new(-48, 0, 8),
		Vector3.new(50, 0, 10), Vector3.new(-14, 0, -40), Vector3.new(16, 0, 38),
		Vector3.new(-88, 0, 30), Vector3.new(88, 0, 34),
	}
	for i, spot in ipairs(treeSpots) do
		buildTree(world, spot, 0.9 + (i % 3) * 0.25)
	end
	local rockSpots = {
		Vector3.new(-60, 0.6, -10), Vector3.new(63, 0.6, -14),
		Vector3.new(-35, 0.6, 62), Vector3.new(38, 0.6, 60),
	}
	for _, spot in ipairs(rockSpots) do
		buildRock(world, spot, 1 + (spot.X % 3) * 0.2)
	end
	local lampSpots = {
		Vector3.new(-28, 0, 0), Vector3.new(28, 0, 0), Vector3.new(0, 0, -28),
		Vector3.new(0, 0, 28), Vector3.new(-80, 0, 44), Vector3.new(80, 0, 44),
	}
	for _, spot in ipairs(lampSpots) do
		buildLamp(world, spot)
	end

	WorldBuilder.BuildShop(world, gameState)
	WorldBuilder.BuildBases(world, gameState)
	WorldBuilder.BuildRarityBillboards(world)

	WorldBuilder.MakeSign(world, "WelcomeSign", "SELAMAT DATANG DI BRAINROT BAZAAR!",
		Vector3.new(0, 0, 78), Vector3.new(30, 5, 0.6), Color3.fromRGB(255, 140, 60))
	floatingSign(world, "PlazaSign", "PLAZA BRAINROT", Vector3.new(0, 16, 0),
		Vector2.new(260, 52), Color3.fromRGB(255, 230, 140))

	return { WaterDisc = water, WheelRotor = rotor, TowerBeacon = beacon, World = world }
end

-- The conveyor shop: a raised belt, side rails, end caps and the big arch.
function WorldBuilder.BuildShop(world, gameState)
	local shop = Instance.new("Model")
	shop.Name = "TokoBrainrot"
	shop.Parent = world
	local beltY = gameState.BELT_Y
	part(shop, "BeltBase", Vector3.new(150, 1.2, 12), CFrame.new(0, beltY - 0.6, 42),
		Color3.fromRGB(60, 60, 75), Enum.Material.Metal)
	local belt = part(shop, "BeltTop", Vector3.new(150, 0.4, 10), CFrame.new(0, beltY + 0.2, 42),
		Color3.fromRGB(45, 45, 55), Enum.Material.Rubber)
	belt.Name = "BeltTop"
	for _, dz in ipairs({ -5.6, 5.6 }) do
		part(shop, "Rail", Vector3.new(150, 1, 0.7), CFrame.new(0, beltY + 0.9, 42 + dz),
			Color3.fromRGB(255, 170, 40), Enum.Material.Metal)
	end
	-- Moving-look chevrons painted along the belt.
	for x = -72, 72, 8 do
		local chev = part(shop, "Chevron", Vector3.new(2.4, 0.1, 2.4), CFrame.new(x, beltY + 0.45, 42),
			Color3.fromRGB(255, 220, 80), Enum.Material.Neon)
		chev.CanCollide = false
	end
	-- Shop arch with the store name over the belt's middle.
	for _, dx in ipairs({ -8, 8 }) do
		part(shop, "ArchPost", Vector3.new(1.4, 13, 1.4), CFrame.new(dx, 6.5, 34),
			Color3.fromRGB(255, 120, 150), Enum.Material.SmoothPlastic)
	end
	part(shop, "ArchTop", Vector3.new(19, 2.2, 1.4), CFrame.new(0, 13.4, 34),
		Color3.fromRGB(255, 120, 150), Enum.Material.SmoothPlastic)
	WorldBuilder.MakeSign(shop, "ShopSign", "TOKO BRAINROT", Vector3.new(0, 11, 33.2),
		Vector3.new(20, 4.4, 0.5), Color3.fromRGB(200, 50, 110))
	return shop
end

-- Eight bases: floor, low walls, six glowing pads each, a green collect pad,
-- a lock button pillar and an owner board. Returns nothing; the pads are
-- found by name (Base<i>/Pad<j>) from the game logic.
function WorldBuilder.BuildBases(world, gameState)
	local bases = Instance.new("Folder")
	bases.Name = "Bases"
	bases.Parent = world
	for i = 1, gameState.BASE_COUNT do
		local origin = gameState.GetBaseOrigin(i)
		local base = Instance.new("Model")
		base.Name = "Base" .. i
		base.Parent = bases
		local hue = (i - 1) / gameState.BASE_COUNT
		local baseColor = Color3.fromHSV(hue, 0.35, 0.95)
		part(base, "Floor", gameState.BASE_SIZE, CFrame.new(origin.X, 0.5, origin.Z),
			baseColor, Enum.Material.SmoothPlastic)
		-- Low walls on three sides; the plaza-facing side stays open.
		local half = gameState.BASE_SIZE
		part(base, "WallBack", Vector3.new(half.X, 3, 1), CFrame.new(origin.X, 2, origin.Z - half.Z / 2),
			baseColor, Enum.Material.Brick)
		part(base, "WallLeft", Vector3.new(1, 3, half.Z), CFrame.new(origin.X - half.X / 2, 2, origin.Z),
			baseColor, Enum.Material.Brick)
		part(base, "WallRight", Vector3.new(1, 3, half.Z), CFrame.new(origin.X + half.X / 2, 2, origin.Z),
			baseColor, Enum.Material.Brick)
		for padIndex = 1, gameState.PADS_PER_BASE do
			local pos = gameState.GetPadPosition(i, padIndex)
			local pad = part(base, "Pad" .. padIndex, Vector3.new(6.5, 0.5, 6.5),
				CFrame.new(pos.X, 1.25, pos.Z), Color3.fromRGB(120, 130, 150), Enum.Material.Neon)
			pad.CanCollide = false
		end
		local collectPos = gameState.GetCollectPadPosition(i)
		local collect = part(base, "CollectPad", Vector3.new(6, 0.5, 6),
			CFrame.new(collectPos.X, 1.25, collectPos.Z), Color3.fromRGB(50, 220, 90), Enum.Material.Neon)
		collect.CanCollide = false
		local lockPos = gameState.GetLockButtonPosition(i)
		part(base, "LockPillar", Vector3.new(1.6, 3.4, 1.6), CFrame.new(lockPos.X, 2.7, lockPos.Z),
			Color3.fromRGB(90, 90, 105), Enum.Material.Metal)
		local button = part(base, "LockButton", Vector3.new(1.7, 0.6, 1.7),
			CFrame.new(lockPos.X, 4.6, lockPos.Z), Color3.fromRGB(255, 190, 40), Enum.Material.Neon)
		button.Shape = Enum.PartType.Cylinder
		button.CanCollide = false
		WorldBuilder.MakeSign(base, "OwnerSign", "BASE " .. i, origin + Vector3.new(0, 0, -half.Z / 2 - 2),
			Vector3.new(12, 3, 0.5), Color3.fromHSV(hue, 0.5, 0.8))
	end
	return bases
end

-- Rarity billboards flanking the shop belt: the whole ladder at a glance,
-- each tier in its own colour, cheapest on the left, Divine on the right.
function WorldBuilder.BuildRarityBillboards(world)
	local tiers = {
		{ "COMMON", Color3.fromRGB(205, 205, 205) },
		{ "RARE", Color3.fromRGB(70, 160, 255) },
		{ "EPIC", Color3.fromRGB(170, 85, 255) },
		{ "LEGENDARY", Color3.fromRGB(255, 180, 30) },
		{ "MYTHIC", Color3.fromRGB(255, 70, 120) },
		{ "DIVINE", Color3.fromRGB(255, 240, 150) },
	}
	for i, tier in ipairs(tiers) do
		local x = -62 + (i - 1) * 25
		floatingSign(world, "RarityBillboard" .. tier[1], tier[1],
			Vector3.new(x, 10, 30), Vector2.new(190, 44), tier[2])
		part(world, "BillboardPost" .. i, Vector3.new(0.7, 9, 0.7), CFrame.new(x, 4.5, 30.6),
			Color3.fromRGB(80, 70, 60), Enum.Material.Wood)
	end
	return world
end

-- Slow ambient animation: fountain water spins and breathes, the ferris
-- wheel turns, the tower beacon pulses. Runs forever on its own task.
function WorldBuilder.Animate(handles)
	task.spawn(function()
		local wheelAngle = 0
		while true do
			local dt = task.wait(0.05)
			if handles.WaterDisc and handles.WaterDisc.Parent then
				local spin = handles.WaterDisc.CFrame * CFrame.Angles(0, dt * 0.7, 0)
				handles.WaterDisc.CFrame = spin
				local pulse = 14.5 + math.sin(os.clock() * 2) * 0.5
				handles.WaterDisc.Size = Vector3.new(pulse, 0.4, pulse)
			end
			if handles.WheelRotor and handles.WheelRotor.PrimaryPart then
				wheelAngle += dt * 0.12
				local pivot = handles.WheelRotor.PrimaryPart
				local center = pivot.Position
				for _, child in ipairs(handles.WheelRotor:GetChildren()) do
					if child:IsA("BasePart") and child ~= pivot then
						local offset = child.Position - center
						local cosA = math.cos(dt * 0.12)
						local sinA = math.sin(dt * 0.12)
						local rotated = Vector3.new(
							offset.X * cosA - offset.Y * sinA,
							offset.X * sinA + offset.Y * cosA,
							offset.Z)
						child.CFrame = CFrame.new(center + rotated) * CFrame.Angles(0, 0, dt * 0.12) * (child.CFrame - child.Position)
					end
				end
			end
			if handles.TowerBeacon and handles.TowerBeacon.Parent then
				local glow = 0.75 + math.sin(os.clock() * 3) * 0.25
				handles.TowerBeacon.Color = Color3.fromRGB(255, math.floor(80 * glow) + 40, math.floor(80 * glow) + 40)
			end
		end
	end)
end

return WorldBuilder
