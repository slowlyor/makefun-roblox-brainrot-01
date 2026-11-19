-- BrainrotFactory: builds a procedural brainrot character Model from BrainrotData.
-- Body colour comes from rarity; a mutation tints the model and scales the price.
-- Movement is XZ-plane only: the caller pins the pivot Y absolutely (belt top
-- 1.3 + lift for riders, 0 + lift for ground walkers) and never feeds current Y back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

local BrainrotFactory = {}

local BODY_SIZE = Vector3.new(2.2, 2.2, 2.2)
local LIFT = 1.6 -- pivot height above the surface the brainrot stands on

function BrainrotFactory.lift()
	return LIFT
end

-- Roll a fresh spawn: picks a character (weighted by rarity curve) + a mutation.
function BrainrotFactory.rollSpawn(rng)
	-- Rarity curve for belt spawns: commons are frequent, divines are rare.
	local roll = rng:NextNumber()
	local rarity = "Common"
	if roll >= 0.985 then
		rarity = "Divine"
	elseif roll >= 0.94 then
		rarity = "Mythic"
	elseif roll >= 0.84 then
		rarity = "Legendary"
	elseif roll >= 0.62 then
		rarity = "Epic"
	elseif roll >= 0.32 then
		rarity = "Rare"
	end
	local char = BrainrotData.randomOfRarity(rarity, rng)
	local mutName, mutMult, mutColor = BrainrotData.rollMutation(rng)
	return char, mutName, mutMult, mutColor
end

-- Build the Model. `owner` is the player who will own it (nil while on the belt).
function BrainrotFactory.create(char, mutName, mutMult, mutColor)
	local price = math.floor(char.price * mutMult + 0.5)
	local income = math.floor(char.income * mutMult + 0.5)
	local rarityColor = BrainrotData.RarityColors[char.rarity]
	local bodyColor = mutColor or rarityColor

	local model = Instance.new("Model")
	model.Name = char.name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = BODY_SIZE
	body.Color = bodyColor
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	-- Head: a ball on top, slightly lighter than the body.
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.8, 1.8, 1.8)
	head.Position = Vector3.new(0, 1.9, 0)
	head.Color = bodyColor:Lerp(Color3.fromRGB(255, 255, 255), 0.25)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model

	-- Eyes: two small white balls with black pupils on the head front.
	for _, side in ipairs({ -0.45, 0.45 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.45, 0.45, 0.45)
		eye.Position = Vector3.new(side, 2.1, 0.85)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = model
		local pupil = Instance.new("Part")
		pupil.Name = "Pupil"
		pupil.Shape = Enum.PartType.Ball
		pupil.Size = Vector3.new(0.22, 0.22, 0.22)
		pupil.Position = Vector3.new(side, 2.1, 1.05)
		pupil.Color = Color3.fromRGB(20, 20, 20)
		pupil.Anchored = true
		pupil.CanCollide = false
		pupil.Parent = model
	end

	-- Feet: two small blocks so it reads as walking.
	for _, side in ipairs({ -0.6, 0.6 }) do
		local foot = Instance.new("Part")
		foot.Name = "Foot"
		foot.Shape = Enum.PartType.Block
		foot.Size = Vector3.new(0.7, 0.4, 1.1)
		foot.Position = Vector3.new(side, -1.25, 0.1)
		foot.Color = Color3.fromRGB(60, 40, 25)
		foot.Anchored = true
		foot.CanCollide = false
		foot.Parent = model
	end

	-- Name + price tag floating above the head.
	local tag = Instance.new("BillboardGui")
	tag.Name = "Tag"
	tag.Size = UDim2.fromOffset(160, 56)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	tag.AlwaysOnTop = false
	tag.Parent = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	local displayName = char.name
	if mutName then
		displayName = mutName .. " " .. displayName
	end
	label.Text = displayName .. "\n" .. BrainrotData.formatMoney(price) .. "  |  " .. BrainrotData.formatMoney(income) .. "/s"
	label.Parent = tag

	model.PrimaryPart = body

	-- Attributes the game logic reads (price/income already include the mutation).
	model:SetAttribute("CharId", char.id)
	model:SetAttribute("Rarity", char.rarity)
	model:SetAttribute("Mutation", mutName or "")
	model:SetAttribute("Price", price)
	model:SetAttribute("Income", income)

	return model
end

-- A sparkle burst of procedural parts for Divine spawns.
function BrainrotFactory.sparkleBurst(parent, pivotPos)
	local folder = Instance.new("Folder")
	folder.Name = "DivineSparkles"
	folder.Parent = parent
	local rng = Random.new()
	for i = 1, 10 do
		local star = Instance.new("Part")
		star.Name = "Sparkle" .. i
		star.Shape = Enum.PartType.Ball
		local s = 0.3 + rng:NextNumber() * 0.4
		star.Size = Vector3.new(s, s, s)
		star.Position = pivotPos + Vector3.new(rng:NextNumber() * 4 - 2, rng:NextNumber() * 3, rng:NextNumber() * 4 - 2)
		star.Color = Color3.fromRGB(90, 240, 230)
		star.Material = Enum.Material.Neon
		star.Anchored = true
		star.CanCollide = false
		star.Parent = folder
	end
	task.delay(6, function()
		folder:Destroy()
	end)
	return folder
end

-- Re-tag a model after it changes hands (price tag stays, owner recorded).
function BrainrotFactory.setOwner(model, playerName)
	model:SetAttribute("Owner", playerName or "")
end

return BrainrotFactory
