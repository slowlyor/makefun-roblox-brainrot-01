-- BrainrotData.luau
-- Shared catalogue for Brainrot Bazaar: every brainrot character, the rarity
-- table used by the shop spawner, and the mutation table. Both the server
-- (spawning, pricing, income) and the client (labels are server-made, but the
-- client reads rarity colours for its HUD accents) require this module from
-- ReplicatedStorage.Shared.

local BrainrotData = {}

-- Rarity colours, also used for plot accents and label strokes.
BrainrotData.RarityColors = {
	Common = Color3.fromRGB(180, 180, 180),
	Rare = Color3.fromRGB(70, 140, 255),
	Epic = Color3.fromRGB(170, 80, 255),
	Legendary = Color3.fromRGB(255, 190, 40),
	Mythic = Color3.fromRGB(255, 70, 90),
	Divine = Color3.fromRGB(80, 255, 220),
}

-- Spawn weights out of 1000 total rolls.
BrainrotData.RarityWeights = {
	Common = 450,
	Rare = 270,
	Epic = 150,
	Legendary = 80,
	Mythic = 35,
	Divine = 15,
}

BrainrotData.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine" }

-- One entry per character: display name, rarity, base price in cash, base
-- income per second, a body colour and the name of its themed prop.
BrainrotData.Characters = {
	{ Name = "Bambang Blender", Rarity = "Common", Price = 25, Income = 1, Color = Color3.fromRGB(200, 200, 205), Prop = "BlenderJar" },
	{ Name = "Siti Speaker", Rarity = "Common", Price = 60, Income = 2, Color = Color3.fromRGB(60, 60, 70), Prop = "SpeakerCone" },
	{ Name = "Udin Udang", Rarity = "Common", Price = 120, Income = 4, Color = Color3.fromRGB(255, 140, 90), Prop = "ShrimpTail" },
	{ Name = "Kakek Kulkas", Rarity = "Rare", Price = 300, Income = 8, Color = Color3.fromRGB(210, 230, 240), Prop = "FridgeDoor" },
	{ Name = "Ratu Rice Cooker", Rarity = "Rare", Price = 650, Income = 15, Color = Color3.fromRGB(245, 245, 245), Prop = "CookerLid" },
	{ Name = "Budi Bakso", Rarity = "Rare", Price = 1200, Income = 28, Color = Color3.fromRGB(190, 130, 80), Prop = "MeatballBowl" },
	{ Name = "Dewi Dandang", Rarity = "Epic", Price = 2500, Income = 55, Color = Color3.fromRGB(150, 150, 160), Prop = "SteamerPot" },
	{ Name = "Pak RT Raksasa", Rarity = "Epic", Price = 5000, Income = 110, Color = Color3.fromRGB(90, 160, 90), Prop = "Megaphone" },
	{ Name = "Nenek Neon", Rarity = "Epic", Price = 9500, Income = 210, Color = Color3.fromRGB(255, 90, 200), Prop = "NeonCane" },
	{ Name = "Sultan Sate", Rarity = "Legendary", Price = 18000, Income = 420, Color = Color3.fromRGB(220, 160, 60), Prop = "SateSkewers" },
	{ Name = "Jenderal Jengkol", Rarity = "Legendary", Price = 35000, Income = 800, Color = Color3.fromRGB(110, 80, 50), Prop = "StarMedal" },
	{ Name = "Maharaja Mie", Rarity = "Legendary", Price = 65000, Income = 1500, Color = Color3.fromRGB(255, 215, 90), Prop = "NoodleCrown" },
	{ Name = "Kaisar Kipas Angin", Rarity = "Mythic", Price = 120000, Income = 3000, Color = Color3.fromRGB(170, 220, 255), Prop = "FanBlades" },
	{ Name = "Dewa Daster", Rarity = "Mythic", Price = 220000, Income = 5800, Color = Color3.fromRGB(255, 170, 210), Prop = "DasterCloth" },
	{ Name = "Ratu Rendang Abadi", Rarity = "Divine", Price = 400000, Income = 11000, Color = Color3.fromRGB(140, 60, 30), Prop = "RendangPot" },
	{ Name = "Sang Pencipta Sambal", Rarity = "Divine", Price = 750000, Income = 21000, Color = Color3.fromRGB(230, 40, 30), Prop = "ChiliCrown" },
	{ Name = "Om Omelet Omega", Rarity = "Divine", Price = 1400000, Income = 40000, Color = Color3.fromRGB(255, 200, 60), Prop = "OmeletPan" },
	{ Name = "TITAN TUMIS GALAKSI", Rarity = "Divine", Price = 2500000, Income = 65000, Color = Color3.fromRGB(120, 60, 220), Prop = "GalaxyWok" },
}

-- Mutations: rolled per spawn. Chance is a fraction; Multiplier scales both
-- the price and the income of the spawned brainrot.
BrainrotData.Mutations = {
	{ Name = "Gold", Chance = 0.10, Multiplier = 2, Color = Color3.fromRGB(255, 205, 50) },
	{ Name = "Diamond", Chance = 0.04, Multiplier = 3, Color = Color3.fromRGB(140, 235, 255) },
	{ Name = "Rainbow", Chance = 0.015, Multiplier = 5, Color = Color3.fromRGB(255, 120, 220) },
}

-- Characters grouped by rarity, built once at load.
BrainrotData.ByRarity = {}
for _, def in ipairs(BrainrotData.Characters) do
	local bucket = BrainrotData.ByRarity[def.Rarity]
	if not bucket then
		bucket = {}
		BrainrotData.ByRarity[def.Rarity] = bucket
	end
	table.insert(bucket, def)
end

local rng = Random.new()

-- Pick a rarity by weight, then a random character of that rarity.
function BrainrotData.RollCharacter()
	local roll = rng:NextInteger(1, 1000)
	local cumulative = 0
	for _, rarity in ipairs(BrainrotData.RarityOrder) do
		cumulative += BrainrotData.RarityWeights[rarity]
		if roll <= cumulative then
			local bucket = BrainrotData.ByRarity[rarity]
			return bucket[rng:NextInteger(1, #bucket)]
		end
	end
	local fallback = BrainrotData.ByRarity.Common
	return fallback[rng:NextInteger(1, #fallback)]
end

-- Roll a mutation for a spawn; returns nil for a plain brainrot. Rainbow is
-- checked first so the rarest mutation wins when several rolls succeed.
function BrainrotData.RollMutation()
	for i = #BrainrotData.Mutations, 1, -1 do
		local mutation = BrainrotData.Mutations[i]
		if rng:NextNumber() < mutation.Chance then
			return mutation
		end
	end
	return nil
end

-- Display name with the mutation prefix, e.g. "Gold Bambang Blender".
function BrainrotData.DisplayName(def, mutation)
	if mutation then
		return mutation.Name .. " " .. def.Name
	end
	return def.Name
end

-- Effective price / income after the mutation multiplier.
function BrainrotData.PriceOf(def, mutation)
	local mult = mutation and mutation.Multiplier or 1
	return math.floor(def.Price * mult)
end

function BrainrotData.IncomeOf(def, mutation)
	local mult = mutation and mutation.Multiplier or 1
	return math.floor(def.Income * mult)
end

-- Look a character definition up by its exact display name (used by tests
-- and by the thief when it narrates what it stole).
function BrainrotData.FindByName(name)
	for _, def in ipairs(BrainrotData.Characters) do
		if def.Name == name then
			return def
		end
	end
	return nil
end

-- Compact cash formatting shared by labels and the HUD: 1500 -> "1.5K".
function BrainrotData.FormatCash(amount)
	amount = math.floor(amount)
	if amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	end
	return tostring(amount)
end

return BrainrotData
