-- BrainrotData.luau
-- The single source of truth for the Brainrot Bazaar cast: 24 original
-- Indonesian-meme characters (food and household objects come to life),
-- six rarities, and the mutation table. Shared by server and client so the
-- shop belt, the gacha machine and the Buku Koleksi index all agree.

local BrainrotData = {}

-- Rarity ladder, weakest first. Weight is the spawn weight per 1000 rolls:
-- Common 450, Rare 270, Epic 150, Legendary 80, Mythic 35, Divine 15.
BrainrotData.Rarities = {
	{ Name = "Common", Weight = 450, Color = Color3.fromRGB(205, 205, 205) },
	{ Name = "Rare", Weight = 270, Color = Color3.fromRGB(70, 160, 255) },
	{ Name = "Epic", Weight = 150, Color = Color3.fromRGB(170, 85, 255) },
	{ Name = "Legendary", Weight = 80, Color = Color3.fromRGB(255, 180, 30) },
	{ Name = "Mythic", Weight = 35, Color = Color3.fromRGB(255, 70, 120) },
	{ Name = "Divine", Weight = 15, Color = Color3.fromRGB(255, 240, 150) },
}

-- Mutations multiply BOTH the price and the income of a brainrot.
-- Chance is rolled per spawn: Gold 10%, Diamond 4%, Rainbow 1.5%.
BrainrotData.Mutations = {
	{ Name = "Gold", Multiplier = 2, Chance = 0.10, Color = Color3.fromRGB(255, 205, 40) },
	{ Name = "Diamond", Multiplier = 3, Chance = 0.04, Color = Color3.fromRGB(140, 235, 255) },
	{ Name = "Rainbow", Multiplier = 5, Chance = 0.015, Color = Color3.fromRGB(255, 120, 220) },
}

-- One row per character. Kind names the procedural body plan the factory
-- builds (body box plus a themed accessory), so no external asset is needed.
-- Income is cash per second before mutation and rebirth multipliers.
BrainrotData.List = {
	-- Common: humble kitchen heroes.
	{ Id = "blender_baper", Name = "Blender Baper", Rarity = "Common", Price = 25, Income = 1, Kind = "Blender", Color = Color3.fromRGB(240, 120, 120) },
	{ Id = "kipas_kepo", Name = "Kipas Angin Kepo", Rarity = "Common", Price = 60, Income = 2, Kind = "Fan", Color = Color3.fromRGB(150, 210, 250) },
	{ Id = "piring_lokal", Name = "Piring Terbang Lokal", Rarity = "Common", Price = 120, Income = 5, Kind = "Plate", Color = Color3.fromRGB(245, 245, 235) },
	{ Id = "sapu_sakti", Name = "Sapu Lidi Sakti", Rarity = "Common", Price = 250, Income = 10, Kind = "Broom", Color = Color3.fromRGB(200, 160, 90) },
	{ Id = "gayung_palsu", Name = "Gayung Emas Palsu", Rarity = "Common", Price = 450, Income = 18, Kind = "Dipper", Color = Color3.fromRGB(255, 215, 90) },
	{ Id = "ember_bocor", Name = "Ember Bocor Legenda", Rarity = "Common", Price = 800, Income = 32, Kind = "Bucket", Color = Color3.fromRGB(90, 180, 120) },
	-- Rare: appliances with stage dreams.
	{ Id = "ricecooker_nyanyi", Name = "Rice Cooker Nyanyi", Rarity = "Rare", Price = 1500, Income = 62, Kind = "RiceCooker", Color = Color3.fromRGB(250, 250, 250) },
	{ Id = "speaker_dangdut", Name = "Speaker Dangdut Mini", Rarity = "Rare", Price = 2800, Income = 115, Kind = "Speaker", Color = Color3.fromRGB(60, 60, 70) },
	{ Id = "kompor_galau", Name = "Kompor Gas Galau", Rarity = "Rare", Price = 5000, Income = 205, Kind = "Stove", Color = Color3.fromRGB(110, 130, 150) },
	{ Id = "setrika_sultan", Name = "Setrika Uap Sultan", Rarity = "Rare", Price = 9000, Income = 370, Kind = "Iron", Color = Color3.fromRGB(190, 170, 230) },
	{ Id = "teko_ajaib", Name = "Teko Ajaib Berisik", Rarity = "Rare", Price = 12000, Income = 495, Kind = "Kettle", Color = Color3.fromRGB(230, 200, 120) },
	-- Epic: the big appliances take the stage.
	{ Id = "kulkas_joget", Name = "Kulkas Joget Sebelah", Rarity = "Epic", Price = 16000, Income = 680, Kind = "Fridge", Color = Color3.fromRGB(200, 230, 240) },
	{ Id = "mesincuci_putar", Name = "Mesin Cuci Putar Balik", Rarity = "Epic", Price = 30000, Income = 1280, Kind = "Washer", Color = Color3.fromRGB(220, 220, 235) },
	{ Id = "tv_tabung", Name = "TV Tabung Nostalgia", Rarity = "Epic", Price = 55000, Income = 2350, Kind = "TV", Color = Color3.fromRGB(90, 80, 70) },
	{ Id = "oven_pesta", Name = "Oven Pesta Kembang Api", Rarity = "Epic", Price = 85000, Income = 3650, Kind = "Oven", Color = Color3.fromRGB(240, 140, 60) },
	-- Legendary: dishes of legend.
	{ Id = "sate_seribu", Name = "Sate Seribu Tusuk", Rarity = "Legendary", Price = 100000, Income = 4500, Kind = "Satay", Color = Color3.fromRGB(170, 100, 50) },
	{ Id = "rendang_raja", Name = "Rendang Raja Daging", Rarity = "Legendary", Price = 180000, Income = 8100, Kind = "Rendang", Color = Color3.fromRGB(120, 60, 35) },
	{ Id = "omelet_emas", Name = "Omelet Emas Raksasa", Rarity = "Legendary", Price = 320000, Income = 14500, Kind = "Omelet", Color = Color3.fromRGB(255, 205, 60) },
	{ Id = "durian_mahkota", Name = "Durian Bermahkota", Rarity = "Legendary", Price = 500000, Income = 22800, Kind = "Durian", Color = Color3.fromRGB(150, 190, 80) },
	-- Mythic: food that breaks physics.
	{ Id = "sambal_petir", Name = "Sambal Petir Nusantara", Rarity = "Mythic", Price = 600000, Income = 28500, Kind = "Sambal", Color = Color3.fromRGB(230, 40, 30) },
	{ Id = "bakso_meteor", Name = "Bakso Meteor Jumbo", Rarity = "Mythic", Price = 1100000, Income = 53000, Kind = "Meatball", Color = Color3.fromRGB(190, 140, 110) },
	{ Id = "nasgor_pelangi", Name = "Nasi Goreng Pelangi", Rarity = "Mythic", Price = 2000000, Income = 97000, Kind = "FriedRice", Color = Color3.fromRGB(255, 160, 200) },
	-- Divine: the kitchen gods themselves.
	{ Id = "rendang_abadi", Name = "Mahkota Rendang Abadi", Rarity = "Divine", Price = 3000000, Income = 150000, Kind = "Rendang", Color = Color3.fromRGB(255, 225, 130) },
	{ Id = "sambal_kosmik", Name = "Tahta Sambal Kosmik", Rarity = "Divine", Price = 4000000, Income = 205000, Kind = "Sambal", Color = Color3.fromRGB(255, 110, 160) },
}

local byId = {}
for _, entry in ipairs(BrainrotData.List) do
	byId[entry.Id] = entry
end

function BrainrotData.GetById(id)
	return byId[id]
end

function BrainrotData.GetRarity(name)
	for _, rarity in ipairs(BrainrotData.Rarities) do
		if rarity.Name == name then
			return rarity
		end
	end
	return BrainrotData.Rarities[1]
end

-- Weighted rarity roll. rng is a Random so tests and spawns can seed it.
function BrainrotData.RollRarity(rng)
	local total = 0
	for _, rarity in ipairs(BrainrotData.Rarities) do
		total += rarity.Weight
	end
	local roll = rng:NextNumber(0, total)
	local acc = 0
	for _, rarity in ipairs(BrainrotData.Rarities) do
		acc += rarity.Weight
		if roll <= acc then
			return rarity.Name
		end
	end
	return "Common"
end

-- Pick a uniformly random character of one rarity.
function BrainrotData.RandomOfRarity(rarityName, rng)
	local pool = {}
	for _, entry in ipairs(BrainrotData.List) do
		if entry.Rarity == rarityName then
			table.insert(pool, entry)
		end
	end
	if #pool == 0 then
		return BrainrotData.List[1]
	end
	return pool[rng:NextInteger(1, #pool)]
end

function BrainrotData.RollEntry(rng)
	return BrainrotData.RandomOfRarity(BrainrotData.RollRarity(rng), rng)
end

-- Mutation roll: returns the mutation table or nil for a plain brainrot.
function BrainrotData.RollMutation(rng)
	local roll = rng:NextNumber()
	local acc = 0
	-- Rarest first so the small chances are not shadowed by the big ones.
	local ordered = { BrainrotData.Mutations[3], BrainrotData.Mutations[2], BrainrotData.Mutations[1] }
	for _, mutation in ipairs(ordered) do
		acc += mutation.Chance
		if roll <= acc then
			return mutation
		end
	end
	return nil
end

-- Final price and income for an entry under a mutation (nil means plain).
function BrainrotData.PriceOf(entry, mutation)
	if mutation then
		return math.floor(entry.Price * mutation.Multiplier)
	end
	return entry.Price
end

function BrainrotData.IncomeOf(entry, mutation)
	if mutation then
		return math.floor(entry.Income * mutation.Multiplier)
	end
	return entry.Income
end

-- "$1,250" style formatting used by every label and the HUD.
function BrainrotData.FormatMoney(amount)
	local n = math.floor(amount)
	local sign = ""
	if n < 0 then
		sign = "-"
		n = -n
	end
	local digits = tostring(n)
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if grouped:sub(1, 1) == "," then
		grouped = grouped:sub(2)
	end
	return sign .. "$" .. grouped
end

-- How many characters live at one rarity (the index shows these per tier).
function BrainrotData.CountByRarity(rarityName)
	local count = 0
	for _, entry in ipairs(BrainrotData.List) do
		if entry.Rarity == rarityName then
			count += 1
		end
	end
	return count
end

-- Display name for a spawn: mutations ride in front of the character name.
function BrainrotData.DisplayName(entry, mutation)
	if mutation then
		return mutation.Name .. " " .. entry.Name
	end
	return entry.Name
end

return BrainrotData
