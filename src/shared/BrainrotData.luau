-- BrainrotData.luau
-- The single source of truth for the Brainrot Bazaar cast: 24 original
-- Indonesian food / household-object characters across 6 rarities, plus the
-- mutation table. Shared by server (spawning, pricing, income) and client
-- (HUD labels and the Buku Koleksi collection index), so a name, price or
-- rarity is only ever written once, here.
--
-- Income rule: a brainrot earns roughly 8% of its price every second,
-- rounded, with a floor of $1/s so even the cheapest blender feels alive.
-- Mutations multiply BOTH the price a buyer pays and the income it earns.

local BrainrotData = {}

-- Rarity ladder, cheapest first. The order drives belt spawn weights,
-- gacha weights, billboard order and the collection index layout.
BrainrotData.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine" }

BrainrotData.RARITY_INFO = {
	Common = { color = Color3.fromRGB(180, 188, 196), beltWeight = 46, gachaWeight = 40 },
	Rare = { color = Color3.fromRGB(64, 156, 255), beltWeight = 26, gachaWeight = 27 },
	Epic = { color = Color3.fromRGB(178, 82, 255), beltWeight = 15, gachaWeight = 17 },
	Legendary = { color = Color3.fromRGB(255, 176, 32), beltWeight = 8, gachaWeight = 9 },
	Mythic = { color = Color3.fromRGB(255, 64, 96), beltWeight = 3.5, gachaWeight = 4.5 },
	Divine = { color = Color3.fromRGB(255, 244, 160), beltWeight = 1.5, gachaWeight = 2.5 },
}

local function incomeFor(price: number): number
	return math.max(1, math.floor(price * 0.08 + 0.5))
end

-- One entry per character: id (stable key), name (shown on the nameplate),
-- rarity, price in $, body colour and a one-word prop the factory builds.
local RAW = {
	{ "blender", "Blender Bontot", "Common", 25, Color3.fromRGB(255, 120, 120), "jar" },
	{ "kipas", "Kipas Angin Kiki", "Common", 60, Color3.fromRGB(150, 210, 255), "blades" },
	{ "sapu", "Sapu Lidi Lala", "Common", 120, Color3.fromRGB(210, 170, 90), "broom" },
	{ "gayung", "Gayung Gaga", "Common", 200, Color3.fromRGB(120, 230, 170), "dipper" },
	{ "sendok", "Sendok Sasa", "Common", 350, Color3.fromRGB(220, 220, 230), "spoon" },
	{ "panci", "Panci Pipi", "Common", 600, Color3.fromRGB(170, 170, 185), "pot" },
	{ "ricecooker", "Rice Cooker Riri", "Rare", 1200, Color3.fromRGB(245, 245, 250), "cooker" },
	{ "speaker", "Speaker Soni", "Rare", 2500, Color3.fromRGB(60, 60, 75), "speaker" },
	{ "setrika", "Setrika Sinta", "Rare", 4500, Color3.fromRGB(255, 170, 210), "iron" },
	{ "kompor", "Kompor Komang", "Rare", 8000, Color3.fromRGB(255, 140, 60), "stove" },
	{ "kulkas", "Kulkas Dede", "Rare", 14000, Color3.fromRGB(190, 235, 255), "fridge" },
	{ "televisi", "Televisi Tivi", "Epic", 25000, Color3.fromRGB(45, 45, 60), "tv" },
	{ "mesincuci", "Mesin Cuci Momo", "Epic", 45000, Color3.fromRGB(200, 225, 255), "washer" },
	{ "acdingin", "AC Dingin Acha", "Epic", 80000, Color3.fromRGB(160, 250, 240), "ac" },
	{ "motor", "Motor Matik Mamat", "Epic", 140000, Color3.fromRGB(255, 90, 90), "scooter" },
	{ "rendang", "Rendang Raksasa", "Legendary", 250000, Color3.fromRGB(140, 70, 35), "pot" },
	{ "sate", "Sate Sultan", "Legendary", 400000, Color3.fromRGB(190, 120, 55), "skewers" },
	{ "sambal", "Sambal Setan", "Legendary", 650000, Color3.fromRGB(230, 30, 30), "jar" },
	{ "nasipadang", "Nasi Padang Nando", "Legendary", 1000000, Color3.fromRGB(250, 230, 150), "plate" },
	{ "omelet", "Omelet Emas Olla", "Mythic", 1800000, Color3.fromRGB(255, 205, 60), "plate" },
	{ "kopiluwak", "Kopi Luwak Legenda", "Mythic", 2800000, Color3.fromRGB(95, 60, 40), "cup" },
	{ "durian", "Durian Diva", "Mythic", 3400000, Color3.fromRGB(150, 200, 80), "spikes" },
	{ "bakso", "Bakso Beranak Dewa", "Divine", 3700000, Color3.fromRGB(255, 215, 130), "pot" },
	{ "rendangdewa", "Rendang Dewa Agung", "Divine", 4000000, Color3.fromRGB(255, 190, 80), "crown" },
}

BrainrotData.LIST = {}
BrainrotData.BY_ID = {}
for _, row in ipairs(RAW) do
	local def = {
		id = row[1],
		name = row[2],
		rarity = row[3],
		price = row[4],
		color = row[5],
		prop = row[6],
		income = incomeFor(row[4]),
	}
	table.insert(BrainrotData.LIST, def)
	BrainrotData.BY_ID[def.id] = def
end

-- Mutations: rolled per spawn. A mutation multiplies price AND income.
BrainrotData.MUTATIONS = {
	{ name = "Gold", chance = 0.10, mult = 2, tint = Color3.fromRGB(255, 205, 45) },
	{ name = "Diamond", chance = 0.04, mult = 3, tint = Color3.fromRGB(140, 240, 255) },
	{ name = "Rainbow", chance = 0.015, mult = 5, tint = Color3.fromRGB(255, 120, 220) },
}

-- Roll a mutation name (or nil for a plain brainrot) from a 0..1 roll.
function BrainrotData.rollMutation(roll: number): string?
	local acc = 0
	for _, m in ipairs(BrainrotData.MUTATIONS) do
		acc += m.chance
		if roll < acc then
			return m.name
		end
	end
	return nil
end

function BrainrotData.mutationInfo(name: string?)
	if name == nil then
		return nil
	end
	for _, m in ipairs(BrainrotData.MUTATIONS) do
		if m.name == name then
			return m
		end
	end
	return nil
end

-- Effective price / income of a definition under a mutation.
function BrainrotData.priceOf(def, mutation: string?): number
	local info = BrainrotData.mutationInfo(mutation)
	return def.price * (info and info.mult or 1)
end

function BrainrotData.incomeOf(def, mutation: string?): number
	local info = BrainrotData.mutationInfo(mutation)
	return def.income * (info and info.mult or 1)
end

-- Weighted pick of one definition for the conveyor belt (beltWeight) or
-- for the gacha machine (gachaWeight). `rng` is injected so the server can
-- pass its own Random and tests can pass a fixed one.
function BrainrotData.pickWeighted(rng: Random, weightField: string)
	local total = 0
	for _, def in ipairs(BrainrotData.LIST) do
		total += BrainrotData.RARITY_INFO[def.rarity][weightField]
	end
	local roll = rng:NextNumber(0, total)
	for _, def in ipairs(BrainrotData.LIST) do
		roll -= BrainrotData.RARITY_INFO[def.rarity][weightField]
		if roll <= 0 then
			return def
		end
	end
	return BrainrotData.LIST[1]
end

-- All definitions of one rarity, in ladder order; the index GUI groups by it.
function BrainrotData.byRarity(rarity: string)
	local out = {}
	for _, def in ipairs(BrainrotData.LIST) do
		if def.rarity == rarity then
			table.insert(out, def)
		end
	end
	return out
end

-- Short money formatting shared by nameplates, the HUD and the index:
-- 950 -> "$950", 250000 -> "$250K", 4000000 -> "$4.0M".
function BrainrotData.formatMoney(n: number): string
	if n >= 1000000 then
		return string.format("$%.1fM", n / 1000000)
	elseif n >= 10000 then
		return string.format("$%dK", math.floor(n / 1000 + 0.5))
	else
		return "$" .. tostring(math.floor(n))
	end
end

return BrainrotData
