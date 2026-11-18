-- BrainrotData.luau
-- Shared catalogue for Brainrot Bazaar: rarities, mutations and the cast of
-- original Indonesian-meme-flavoured brainrot characters. Used by the server
-- (spawning, prices, income) and by the client (colours and labels in the HUD).

local BrainrotData = {}

-- Rarity ladder, cheapest first. Weight is the shop spawn weight.
BrainrotData.RARITIES = {
	{ Name = "Common", Color = Color3.fromRGB(168, 175, 186), Weight = 450 },
	{ Name = "Rare", Color = Color3.fromRGB(64, 156, 255), Weight = 270 },
	{ Name = "Epic", Color = Color3.fromRGB(178, 102, 255), Weight = 150 },
	{ Name = "Legendary", Color = Color3.fromRGB(255, 190, 40), Weight = 80 },
	{ Name = "Mythic", Color = Color3.fromRGB(255, 77, 141), Weight = 35 },
	{ Name = "Divine", Color = Color3.fromRGB(255, 255, 255), Weight = 15 },
}

BrainrotData.RarityByName = {}
for _, rarity in ipairs(BrainrotData.RARITIES) do
	BrainrotData.RarityByName[rarity.Name] = rarity
end

-- Mutations roll per shop spawn. Multiplier applies to income (and price).
BrainrotData.MUTATIONS = {
	{ Name = "Gold", Multiplier = 2, Chance = 0.10, Color = Color3.fromRGB(255, 205, 55) },
	{ Name = "Diamond", Multiplier = 3, Chance = 0.04, Color = Color3.fromRGB(140, 235, 255) },
	{ Name = "Rainbow", Multiplier = 5, Chance = 0.015, Color = Color3.fromRGB(255, 120, 220) },
}

-- The cast. Cost is the shop price in cash; Income is cash per second before
-- mutation and rebirth multipliers. Prop describes the silly hat/object each
-- character wears: a PartType ("Block", "Ball" or "Cylinder") plus a colour.
BrainrotData.CHARACTERS = {
	-- Common
	{ Name = "Bambang Blender", Rarity = "Common", Cost = 25, Income = 1,
		BodyColor = Color3.fromRGB(200, 205, 215), HeadColor = Color3.fromRGB(255, 214, 170),
		PropType = "Cylinder", PropColor = Color3.fromRGB(150, 220, 255) },
	{ Name = "Siti Speaker", Rarity = "Common", Cost = 60, Income = 2,
		BodyColor = Color3.fromRGB(70, 70, 80), HeadColor = Color3.fromRGB(240, 195, 150),
		PropType = "Block", PropColor = Color3.fromRGB(30, 30, 35) },
	{ Name = "Udin Udang", Rarity = "Common", Cost = 120, Income = 4,
		BodyColor = Color3.fromRGB(255, 140, 105), HeadColor = Color3.fromRGB(255, 170, 140),
		PropType = "Ball", PropColor = Color3.fromRGB(255, 110, 80) },
	-- Rare
	{ Name = "Kakek Kulkas", Rarity = "Rare", Cost = 300, Income = 8,
		BodyColor = Color3.fromRGB(225, 232, 238), HeadColor = Color3.fromRGB(235, 220, 200),
		PropType = "Block", PropColor = Color3.fromRGB(180, 190, 200) },
	{ Name = "Ratu Rice Cooker", Rarity = "Rare", Cost = 650, Income = 15,
		BodyColor = Color3.fromRGB(245, 245, 250), HeadColor = Color3.fromRGB(255, 205, 165),
		PropType = "Cylinder", PropColor = Color3.fromRGB(200, 200, 210) },
	{ Name = "Budi Bakso", Rarity = "Rare", Cost = 1200, Income = 28,
		BodyColor = Color3.fromRGB(160, 105, 70), HeadColor = Color3.fromRGB(250, 210, 175),
		PropType = "Ball", PropColor = Color3.fromRGB(120, 75, 45) },
	-- Epic
	{ Name = "Dewi Dandang", Rarity = "Epic", Cost = 2500, Income = 55,
		BodyColor = Color3.fromRGB(120, 120, 135), HeadColor = Color3.fromRGB(255, 215, 180),
		PropType = "Cylinder", PropColor = Color3.fromRGB(90, 90, 105) },
	{ Name = "Pak RT Raksasa", Rarity = "Epic", Cost = 5000, Income = 110,
		BodyColor = Color3.fromRGB(90, 140, 90), HeadColor = Color3.fromRGB(245, 200, 155),
		PropType = "Block", PropColor = Color3.fromRGB(60, 100, 60) },
	{ Name = "Nenek Neon", Rarity = "Epic", Cost = 9500, Income = 210,
		BodyColor = Color3.fromRGB(255, 120, 220), HeadColor = Color3.fromRGB(255, 225, 200),
		PropType = "Ball", PropColor = Color3.fromRGB(120, 255, 235) },
	-- Legendary
	{ Name = "Sultan Sate", Rarity = "Legendary", Cost = 18000, Income = 420,
		BodyColor = Color3.fromRGB(150, 90, 50), HeadColor = Color3.fromRGB(255, 210, 170),
		PropType = "Cylinder", PropColor = Color3.fromRGB(255, 175, 60) },
	{ Name = "Jenderal Jengkol", Rarity = "Legendary", Cost = 35000, Income = 800,
		BodyColor = Color3.fromRGB(105, 80, 55), HeadColor = Color3.fromRGB(240, 200, 160),
		PropType = "Ball", PropColor = Color3.fromRGB(85, 65, 45) },
	{ Name = "Maharaja Mie", Rarity = "Legendary", Cost = 65000, Income = 1500,
		BodyColor = Color3.fromRGB(255, 205, 90), HeadColor = Color3.fromRGB(255, 218, 180),
		PropType = "Block", PropColor = Color3.fromRGB(255, 150, 60) },
	-- Mythic
	{ Name = "Kaisar Kipas Angin", Rarity = "Mythic", Cost = 120000, Income = 2800,
		BodyColor = Color3.fromRGB(190, 200, 210), HeadColor = Color3.fromRGB(255, 210, 175),
		PropType = "Cylinder", PropColor = Color3.fromRGB(160, 225, 255) },
	{ Name = "Dewa Daster", Rarity = "Mythic", Cost = 220000, Income = 5200,
		BodyColor = Color3.fromRGB(255, 170, 200), HeadColor = Color3.fromRGB(255, 222, 190),
		PropType = "Block", PropColor = Color3.fromRGB(255, 130, 175) },
	{ Name = "Ratu Rendang Abadi", Rarity = "Mythic", Cost = 400000, Income = 9500,
		BodyColor = Color3.fromRGB(140, 60, 40), HeadColor = Color3.fromRGB(250, 205, 165),
		PropType = "Ball", PropColor = Color3.fromRGB(110, 45, 30) },
	-- Divine
	{ Name = "Sang Pencipta Sambal", Rarity = "Divine", Cost = 750000, Income = 18000,
		BodyColor = Color3.fromRGB(235, 60, 45), HeadColor = Color3.fromRGB(255, 225, 195),
		PropType = "Cylinder", PropColor = Color3.fromRGB(255, 90, 60) },
	{ Name = "Om Omelet Omega", Rarity = "Divine", Cost = 1400000, Income = 34000,
		BodyColor = Color3.fromRGB(255, 225, 110), HeadColor = Color3.fromRGB(255, 215, 175),
		PropType = "Ball", PropColor = Color3.fromRGB(255, 245, 170) },
	{ Name = "TITAN TUMIS GALAKSI", Rarity = "Divine", Cost = 2500000, Income = 65000,
		BodyColor = Color3.fromRGB(80, 70, 160), HeadColor = Color3.fromRGB(255, 220, 185),
		PropType = "Block", PropColor = Color3.fromRGB(150, 130, 255) },
}

BrainrotData.CharactersByRarity = {}
for _, def in ipairs(BrainrotData.CHARACTERS) do
	local bucket = BrainrotData.CharactersByRarity[def.Rarity]
	if not bucket then
		bucket = {}
		BrainrotData.CharactersByRarity[def.Rarity] = bucket
	end
	table.insert(bucket, def)
end

-- Pick a random character definition, weighted by rarity.
function BrainrotData.PickRandom(rng: Random)
	local totalWeight = 0
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		totalWeight += rarity.Weight
	end
	local roll = rng:NextNumber(0, totalWeight)
	local chosen = BrainrotData.RARITIES[1]
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		roll -= rarity.Weight
		if roll <= 0 then
			chosen = rarity
			break
		end
	end
	local bucket = BrainrotData.CharactersByRarity[chosen.Name]
	return bucket[rng:NextInteger(1, #bucket)]
end

-- Roll a mutation for a fresh shop spawn; returns nil most of the time.
function BrainrotData.RollMutation(rng: Random)
	local roll = rng:NextNumber()
	local cumulative = 0
	for _, mutation in ipairs(BrainrotData.MUTATIONS) do
		cumulative += mutation.Chance
		if roll <= cumulative then
			return mutation
		end
	end
	return nil
end

-- "$1.25K" style formatting used by the HUD, signs and labels.
function BrainrotData.FormatCash(amount: number): string
	amount = math.floor(amount)
	if amount >= 1e9 then
		return string.format("$%.2fB", amount / 1e9)
	elseif amount >= 1e6 then
		return string.format("$%.2fM", amount / 1e6)
	elseif amount >= 1e4 then
		return string.format("$%.1fK", amount / 1e3)
	elseif amount >= 1e3 then
		return string.format("$%.2fK", amount / 1e3)
	end
	return "$" .. tostring(amount)
end

return BrainrotData
