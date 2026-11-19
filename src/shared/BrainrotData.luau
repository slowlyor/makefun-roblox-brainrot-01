-- BrainrotData: the 24 original Brainrot Bazaar characters.
-- All names are original Indonesian food / household-object memes.
-- No copyrighted characters. Prices in dollars; income is per second.

local BrainrotData = {}

BrainrotData.Rarities = {
	"Common",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Divine",
}

-- Rarity display colours (RGB).
BrainrotData.RarityColors = {
	Common = Color3.fromRGB(120, 200, 90),
	Rare = Color3.fromRGB(70, 140, 255),
	Epic = Color3.fromRGB(170, 90, 230),
	Legendary = Color3.fromRGB(255, 180, 30),
	Mythic = Color3.fromRGB(255, 70, 120),
	Divine = Color3.fromRGB(90, 240, 230),
}

-- Gacha weights per rarity (out of 100).
BrainrotData.GachaWeights = {
	Common = 50,
	Rare = 25,
	Epic = 13,
	Legendary = 7,
	Mythic = 4,
	Divine = 1,
}

-- Mutation roll chances; a mutation multiplies BOTH price and income.
BrainrotData.Mutations = {
	{ name = "Rainbow", chance = 0.015, mult = 5, color = Color3.fromRGB(255, 120, 220) },
	{ name = "Diamond", chance = 0.04, mult = 3, color = Color3.fromRGB(140, 220, 255) },
	{ name = "Gold", chance = 0.10, mult = 2, color = Color3.fromRGB(255, 215, 0) },
}

-- id, name, rarity, price, income per second.
local function char(id, name, rarity, price, income)
	return { id = id, name = name, rarity = rarity, price = price, income = income }
end

BrainrotData.Characters = {
	-- Common
	char(1, "Nasi Goreng Terbang", "Common", 25, 1),
	char(2, "Tahu Bulat Panas", "Common", 60, 2),
	char(3, "Kerupuk Meledak", "Common", 120, 4),
	char(4, "Tempe Mendoan Joget", "Common", 200, 7),
	char(5, "Cilok Kenyal Manja", "Common", 300, 10),
	char(6, "Gorengan Panas Garing", "Common", 400, 14),
	char(7, "Es Teh Manis Viral", "Common", 550, 19),
	char(8, "Kopi Susu Gula Aren", "Common", 750, 26),
	-- Rare
	char(9, "Indomie Rebus Sultan", "Rare", 1200, 42),
	char(10, "Bakso Beranak Lima", "Rare", 2500, 85),
	char(11, "Pisang Goreng Coklat", "Rare", 4500, 150),
	char(12, "Cireng Bumbu Rujak", "Rare", 8000, 260),
	char(13, "Sate Ayam Bakar Asap", "Rare", 14000, 450),
	char(14, "Mie Ayam Gerobak Emas", "Rare", 24000, 780),
	-- Epic
	char(15, "Seblak Pedas Level 5", "Epic", 45000, 1500),
	char(16, "Roti Bakar Coklat Keju", "Epic", 90000, 3000),
	char(17, "Soto Ayam Kampung Juara", "Epic", 180000, 6000),
	char(18, "Martabak Manis Coklat", "Epic", 350000, 11500),
	-- Legendary
	char(19, "Rendang Sapi Empuk", "Legendary", 700000, 23000),
	char(20, "Gado-Gado Jakarta Raya", "Legendary", 1200000, 40000),
	char(21, "Klepon Gula Merah Meletus", "Legendary", 2000000, 66000),
	-- Mythic
	char(22, "Onde-Onde Wijen Sakti", "Mythic", 2800000, 95000),
	char(23, "Bubur Ayam Gerobak Terbang", "Mythic", 3400000, 115000),
	-- Divine
	char(24, "Es Cendol Dawet Dewa", "Divine", 4000000, 150000),
}

BrainrotData.ById = {}
for _, c in ipairs(BrainrotData.Characters) do
	BrainrotData.ById[c.id] = c
end

function BrainrotData.get(id)
	return BrainrotData.ById[id]
end

function BrainrotData.ofRarity(rarity)
	local out = {}
	for _, c in ipairs(BrainrotData.Characters) do
		if c.rarity == rarity then
			table.insert(out, c)
		end
	end
	return out
end

-- Roll a mutation for a fresh spawn. Returns name, multiplier, colour (or nil, 1, nil).
function BrainrotData.rollMutation(rng)
	local roll = rng:NextNumber()
	local acc = 0
	for _, m in ipairs(BrainrotData.Mutations) do
		acc = acc + m.chance
		if roll < acc then
			return m.name, m.mult, m.color
		end
	end
	return nil, 1, nil
end

-- Weighted rarity roll for the gacha machine.
function BrainrotData.rollRarity(rng)
	local total = 0
	for _, r in ipairs(BrainrotData.Rarities) do
		total = total + BrainrotData.GachaWeights[r]
	end
	local roll = rng:NextNumber() * total
	local acc = 0
	for _, r in ipairs(BrainrotData.Rarities) do
		acc = acc + BrainrotData.GachaWeights[r]
		if roll < acc then
			return r
		end
	end
	return "Common"
end

function BrainrotData.randomOfRarity(rarity, rng)
	local pool = BrainrotData.ofRarity(rarity)
	return pool[rng:NextInteger(1, #pool)]
end

-- "$1,250" style formatting for HUD and signs.
function BrainrotData.formatMoney(n)
	n = math.floor(n + 0.5)
	local s = tostring(n)
	local out = ""
	while #s > 3 do
		out = "," .. string.sub(s, -3) .. out
		s = string.sub(s, 1, -4)
	end
	return "$" .. s .. out
end

return BrainrotData
