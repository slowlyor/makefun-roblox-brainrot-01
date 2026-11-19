-- BrainrotData.luau -- the shared catalogue for Brainrot Bazaar.
-- 24 original Indonesian-meme characters: kitchen gear, street food and
-- household objects that came alive and started earning money.
-- Every server system and both client GUIs read names, prices and income
-- from this one module, so the cast stays consistent everywhere.

local BrainrotData = {}

BrainrotData.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine" }

BrainrotData.RarityColors = {
	Common = Color3.fromRGB(205, 210, 215),
	Rare = Color3.fromRGB(70, 160, 255),
	Epic = Color3.fromRGB(170, 80, 255),
	Legendary = Color3.fromRGB(255, 180, 30),
	Mythic = Color3.fromRGB(255, 70, 120),
	Divine = Color3.fromRGB(255, 240, 160),
}

-- How likely each rarity is on the conveyor belt (weights, not percents).
BrainrotData.BeltWeights = {
	Common = 620, Rare = 220, Epic = 95, Legendary = 42, Mythic = 17, Divine = 6,
}

-- The gacha machine is kinder than the belt: rares show up more often.
BrainrotData.GachaWeights = {
	Common = 460, Rare = 280, Epic = 140, Legendary = 75, Mythic = 32, Divine = 13,
}

-- Mutations multiply BOTH the price a player pays and the income earned.
BrainrotData.Mutations = {
	{ Name = "Normal", Chance = 0.845, Multiplier = 1, Color = nil },
	{ Name = "Gold", Chance = 0.10, Multiplier = 2, Color = Color3.fromRGB(255, 205, 40) },
	{ Name = "Diamond", Chance = 0.04, Multiplier = 3, Color = Color3.fromRGB(120, 230, 255) },
	{ Name = "Rainbow", Chance = 0.015, Multiplier = 5, Color = Color3.fromRGB(255, 120, 220) },
}

-- Body kinds the factory knows how to build procedurally.
-- kind: "box" | "round" (sphere) | "tall" (cylinder) -- colour is the body.
local function def(name, rarity, price, income, kind, r, g, b)
	return {
		Name = name, Rarity = rarity, Price = price, Income = income,
		Kind = kind, Color = Color3.fromRGB(r, g, b),
	}
end

BrainrotData.Characters = {
	-- Common: humble kitchen heroes, cheap and cheerful.
	def("Blender Budi", "Common", 25, 2, "tall", 240, 90, 90),
	def("Kipas Kiki", "Common", 60, 5, "round", 140, 210, 240),
	def("Sapu Lidi Lala", "Common", 130, 10, "tall", 200, 160, 90),
	def("Rice Cooker Riko", "Common", 280, 20, "box", 235, 235, 235),
	def("Speaker Soni", "Common", 550, 38, "box", 70, 70, 90),
	def("Kompor Koko", "Common", 950, 65, "box", 255, 140, 60),
	-- Rare: street-food royalty.
	def("Sate Sigit", "Rare", 1800, 120, "tall", 180, 110, 60),
	def("Rendang Ratu", "Rare", 3200, 210, "round", 150, 70, 40),
	def("Omelet Olin", "Rare", 5500, 360, "round", 255, 210, 80),
	def("Sambal Sasa", "Rare", 9000, 580, "tall", 230, 40, 40),
	def("Bakso Bimo", "Rare", 15000, 950, "round", 225, 200, 170),
	-- Epic: big appliances with big dreams.
	def("Mesin Cuci Mimi", "Epic", 26000, 1700, "box", 190, 220, 255),
	def("Kulkas Kaka", "Epic", 45000, 2900, "box", 210, 240, 245),
	def("Televisi Tono", "Epic", 75000, 4800, "box", 50, 50, 70),
	def("Motor Matic Momo", "Epic", 120000, 7700, "box", 255, 90, 120),
	-- Legendary: dishes and icons of legend.
	def("Nasi Padang Pak Haji", "Legendary", 200000, 13000, "box", 240, 230, 180),
	def("Durian Raja Dodi", "Legendary", 340000, 22000, "round", 170, 190, 70),
	def("Angklung Ajaib Angga", "Legendary", 560000, 36000, "tall", 190, 130, 70),
	def("Garuda Emas Gaga", "Legendary", 900000, 58000, "round", 255, 190, 40),
	-- Mythic: food so powerful it bends the bazaar.
	def("Istana Sambal Sakti", "Mythic", 1500000, 100000, "box", 255, 60, 60),
	def("Naga Rendang Nara", "Mythic", 2400000, 160000, "tall", 140, 50, 50),
	def("Mahkota Blender Dewa", "Mythic", 3200000, 215000, "tall", 200, 200, 230),
	-- Divine: the final two. The bazaar goes quiet when they walk the belt.
	def("Singgasana Rice Cooker Agung", "Divine", 3800000, 260000, "box", 255, 245, 200),
	def("Dewa Speaker Semesta", "Divine", 4000000, 275000, "box", 255, 250, 220),
}

function BrainrotData.Get(index)
	return BrainrotData.Characters[index]
end

function BrainrotData.Count()
	return #BrainrotData.Characters
end

-- Roll a mutation name using the chance table above.
function BrainrotData.RollMutation(rng)
	local roll = rng:NextNumber()
	local acc = 0
	for _, m in ipairs(BrainrotData.Mutations) do
		acc += m.Chance
		if roll <= acc then
			return m
		end
	end
	return BrainrotData.Mutations[1]
end

function BrainrotData.MutationByName(name)
	for _, m in ipairs(BrainrotData.Mutations) do
		if m.Name == name then
			return m
		end
	end
	return BrainrotData.Mutations[1]
end

-- Pick a random character index whose rarity comes from a weight table.
function BrainrotData.RollCharacter(rng, weights)
	local total = 0
	for _, rarity in ipairs(BrainrotData.RarityOrder) do
		total += weights[rarity] or 0
	end
	local pick = rng:NextNumber() * total
	local chosenRarity = "Common"
	local acc = 0
	for _, rarity in ipairs(BrainrotData.RarityOrder) do
		acc += weights[rarity] or 0
		if pick <= acc then
			chosenRarity = rarity
			break
		end
	end
	local pool = {}
	for i, c in ipairs(BrainrotData.Characters) do
		if c.Rarity == chosenRarity then
			table.insert(pool, i)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- Price / income after a mutation multiplier is applied.
function BrainrotData.PriceFor(index, mutationName)
	local c = BrainrotData.Characters[index]
	local m = BrainrotData.MutationByName(mutationName)
	return math.floor(c.Price * m.Multiplier)
end

function BrainrotData.IncomeFor(index, mutationName)
	local c = BrainrotData.Characters[index]
	local m = BrainrotData.MutationByName(mutationName)
	return c.Income * m.Multiplier
end

-- One-line label used on billboards, pads and the collection index:
-- "Rendang Ratu [RARE] $210/s" (mutation prefix added when mutated).
function BrainrotData.LabelFor(index, mutationName)
	local c = BrainrotData.Characters[index]
	local prefix = ""
	if mutationName and mutationName ~= "Normal" then
		prefix = mutationName .. " "
	end
	return string.format("%s%s [%s] %s/s", prefix, c.Name, string.upper(c.Rarity),
		BrainrotData.FormatMoney(BrainrotData.IncomeFor(index, mutationName)))
end

-- Rarity rank 1..6, handy for sorting the collection index best-first.
function BrainrotData.RarityRank(rarity)
	for i, r in ipairs(BrainrotData.RarityOrder) do
		if r == rarity then
			return i
		end
	end
	return 1
end

function BrainrotData.FormatMoney(n)
	n = math.floor(n)
	if n >= 1000000 then
		return string.format("$%.2fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("$%.1fK", n / 1000)
	end
	return "$" .. tostring(n)
end

return BrainrotData
