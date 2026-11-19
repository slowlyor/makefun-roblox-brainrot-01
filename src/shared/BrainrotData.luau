-- BrainrotData.luau
-- Brainrot Bazaar: the shared catalogue of every brainrot character.
-- 24 original Indonesian food / household-object characters, four per
-- rarity across six rarities. Prices run from $25 up to $4,000,000 and
-- income-per-second scales with price. This module is pure data plus
-- small pure helpers, so both the server and the client (the Buku
-- Koleksi index) can require the exact same table.

local BrainrotData = {}

BrainrotData.RARITIES = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine" }

BrainrotData.RARITY_ORDER = {
	Common = 1,
	Rare = 2,
	Epic = 3,
	Legendary = 4,
	Mythic = 5,
	Divine = 6,
}

BrainrotData.RARITY_COLORS = {
	Common = Color3.fromRGB(168, 175, 186),
	Rare = Color3.fromRGB(64, 156, 255),
	Epic = Color3.fromRGB(168, 85, 247),
	Legendary = Color3.fromRGB(255, 176, 32),
	Mythic = Color3.fromRGB(244, 63, 120),
	Divine = Color3.fromRGB(255, 240, 160),
}

-- Belt spawns favour cheap characters; the gacha machine is kinder.
BrainrotData.BELT_WEIGHTS = {
	Common = 55,
	Rare = 25,
	Epic = 11,
	Legendary = 5.5,
	Mythic = 2.5,
	Divine = 1,
}

BrainrotData.GACHA_WEIGHTS = {
	Common = 38,
	Rare = 28,
	Epic = 17,
	Legendary = 9,
	Mythic = 5,
	Divine = 3,
}

-- Mutations multiply BOTH the buy price and the income of a character.
BrainrotData.MUTATIONS = {
	{ Name = "Normal", Multiplier = 1, Chance = 84.5, Color = nil },
	{ Name = "Gold", Multiplier = 2, Chance = 10, Color = Color3.fromRGB(255, 205, 48) },
	{ Name = "Diamond", Multiplier = 3, Chance = 4, Color = Color3.fromRGB(120, 235, 255) },
	{ Name = "Rainbow", Multiplier = 5, Chance = 1.5, Color = Color3.fromRGB(255, 110, 220) },
}

-- Accessory kinds are interpreted by BrainrotFactory on the server.
BrainrotData.CHARACTERS = {
	-- Common: humble kitchen heroes.
	{ Id = "bambang_blender", Name = "Bambang Blender", Rarity = "Common", Price = 25, Income = 2, Body = Color3.fromRGB(200, 210, 220), Accent = Color3.fromRGB(90, 100, 115), Accessory = "blades", Blurb = "Berputar tiap dengar dangdut." },
	{ Id = "siti_sapu", Name = "Siti Sapu Lidi", Rarity = "Common", Price = 50, Income = 4, Body = Color3.fromRGB(196, 144, 84), Accent = Color3.fromRGB(120, 80, 40), Accessory = "broom", Blurb = "Menyapu debu dan gosip tetangga." },
	{ Id = "kiko_kipas", Name = "Kiko Kipas Kecil", Rarity = "Common", Price = 90, Income = 7, Body = Color3.fromRGB(140, 220, 240), Accent = Color3.fromRGB(60, 140, 180), Accessory = "fan", Blurb = "Anginnya kecil, semangatnya besar." },
	{ Id = "pipi_panci", Name = "Pipi Panci Presto", Rarity = "Common", Price = 150, Income = 12, Body = Color3.fromRGB(178, 182, 190), Accent = Color3.fromRGB(70, 74, 82), Accessory = "lid", Blurb = "Mendidih kalau telat makan siang." },

	-- Rare: warung legends.
	{ Id = "rudi_ricecooker", Name = "Rudi Rice Cooker", Rarity = "Rare", Price = 300, Income = 25, Body = Color3.fromRGB(245, 245, 240), Accent = Color3.fromRGB(220, 60, 60), Accessory = "steam", Blurb = "Nasinya pulen, dompetnya keren." },
	{ Id = "seno_sate", Name = "Seno Sate Madura", Rarity = "Rare", Price = 550, Income = 45, Body = Color3.fromRGB(150, 92, 50), Accent = Color3.fromRGB(255, 150, 50), Accessory = "skewers", Blurb = "Dikipas sampai asapnya menari." },
	{ Id = "tono_teko", Name = "Tono Teko Tarik", Rarity = "Rare", Price = 900, Income = 75, Body = Color3.fromRGB(110, 200, 170), Accent = Color3.fromRGB(40, 120, 100), Accessory = "spout", Blurb = "Menuang teh setinggi cita-cita." },
	{ Id = "dedi_speaker", Name = "Dedi Speaker Dangdut", Rarity = "Rare", Price = 1400, Income = 115, Body = Color3.fromRGB(60, 60, 70), Accent = Color3.fromRGB(255, 90, 90), Accessory = "antenna", Blurb = "Bass-nya terasa sampai RT sebelah." },

	-- Epic: household heavyweights.
	{ Id = "raka_rendang", Name = "Raka Rendang Raja", Rarity = "Epic", Price = 2500, Income = 200, Body = Color3.fromRGB(122, 62, 32), Accent = Color3.fromRGB(214, 132, 52), Accessory = "flame", Blurb = "Dimasak delapan jam, dihormati selamanya." },
	{ Id = "mamat_mesincuci", Name = "Mamat Mesin Cuci", Rarity = "Epic", Price = 4000, Income = 330, Body = Color3.fromRGB(210, 225, 235), Accent = Color3.fromRGB(70, 130, 200), Accessory = "drum", Blurb = "Bergetar hebat saat spin terakhir." },
	{ Id = "kiki_kulkas", Name = "Kiki Kulkas Kembar", Rarity = "Epic", Price = 6500, Income = 540, Body = Color3.fromRGB(170, 220, 235), Accent = Color3.fromRGB(240, 250, 255), Accessory = "snow", Blurb = "Dingin di luar, hangat menyimpan rendang." },
	{ Id = "gogon_kompor", Name = "Gogon Kompor Gas", Rarity = "Epic", Price = 10000, Income = 830, Body = Color3.fromRGB(80, 88, 100), Accent = Color3.fromRGB(80, 160, 255), Accessory = "flame", Blurb = "Api birunya tak pernah ingkar janji." },

	-- Legendary: street-food royalty.
	{ Id = "bimo_bakso", Name = "Bimo Bakso Raksasa", Rarity = "Legendary", Price = 18000, Income = 1500, Body = Color3.fromRGB(216, 178, 138), Accent = Color3.fromRGB(160, 60, 40), Accessory = "steam", Blurb = "Satu bakso cukup untuk sekeluarga." },
	{ Id = "sulaiman_soto", Name = "Sultan Soto Sulaiman", Rarity = "Legendary", Price = 30000, Income = 2500, Body = Color3.fromRGB(250, 205, 90), Accent = Color3.fromRGB(90, 170, 90), Accessory = "crown", Blurb = "Kuahnya kuning emas, takhtanya nyata." },
	{ Id = "jajang_tv", Name = "Jajang TV Jadul", Rarity = "Legendary", Price = 50000, Income = 4200, Body = Color3.fromRGB(96, 84, 72), Accent = Color3.fromRGB(140, 255, 190), Accessory = "screen", Blurb = "Menayangkan sinetron dari masa depan." },
	{ Id = "beben_bebek", Name = "Beben Motor Bebek", Rarity = "Legendary", Price = 80000, Income = 6700, Body = Color3.fromRGB(220, 70, 60), Accent = Color3.fromRGB(40, 40, 46), Accessory = "antenna", Blurb = "Knalpotnya batuk, larinya kencang." },

	-- Mythic: whispered about in every pasar.
	{ Id = "peri_padang", Name = "Peri Nasi Padang", Rarity = "Mythic", Price = 140000, Income = 11700, Body = Color3.fromRGB(250, 240, 210), Accent = Color3.fromRGB(200, 60, 60), Accessory = "wings", Blurb = "Sekali sentuh, lauk bertambah sendiri." },
	{ Id = "galih_gamelan", Name = "Galih Gamelan Gaib", Rarity = "Mythic", Price = 220000, Income = 18300, Body = Color3.fromRGB(176, 128, 52), Accent = Color3.fromRGB(255, 220, 130), Accessory = "drum", Blurb = "Bunyinya terdengar sebelum dipukul." },
	{ Id = "kyai_keris", Name = "Kyai Keris Dapur", Rarity = "Mythic", Price = 350000, Income = 29200, Body = Color3.fromRGB(120, 110, 140), Accent = Color3.fromRGB(200, 190, 255), Accessory = "flame", Blurb = "Mengiris bawang tanpa membuatmu menangis." },
	{ Id = "dara_durian", Name = "Dara Durian Raja", Rarity = "Mythic", Price = 550000, Income = 45800, Body = Color3.fromRGB(120, 170, 70), Accent = Color3.fromRGB(250, 225, 120), Accessory = "crown", Blurb = "Aromanya membuka semua pintu pasar." },

	-- Divine: cosmic kitchen gods.
	{ Id = "rengga_rendang", Name = "Rengga Rendang Dewa", Rarity = "Divine", Price = 900000, Income = 75000, Body = Color3.fromRGB(140, 70, 30), Accent = Color3.fromRGB(255, 215, 110), Accessory = "halo", Blurb = "Rendang yang dimasak para bintang." },
	{ Id = "baskara_blender", Name = "Baskara Blender Sakti", Rarity = "Divine", Price = 1500000, Income = 125000, Body = Color3.fromRGB(255, 160, 60), Accent = Color3.fromRGB(255, 240, 180), Accessory = "halo", Blurb = "Memutar galaksi jadi jus alpukat." },
	{ Id = "semesta_kipas", Name = "Semesta Kipas Angin", Rarity = "Divine", Price = 2400000, Income = 200000, Body = Color3.fromRGB(170, 200, 255), Accent = Color3.fromRGB(255, 255, 255), Accessory = "fan", Blurb = "Satu putaran, musim pun berganti." },
	{ Id = "kosmik_cooker", Name = "Kosmik Rice Cooker", Rarity = "Divine", Price = 4000000, Income = 333000, Body = Color3.fromRGB(230, 225, 255), Accent = Color3.fromRGB(170, 130, 255), Accessory = "halo", Blurb = "Menanak nasi dari cahaya nebula." },
}

local byId = {}
local byRarity = {}
for _, def in ipairs(BrainrotData.CHARACTERS) do
	byId[def.Id] = def
	byRarity[def.Rarity] = byRarity[def.Rarity] or {}
	table.insert(byRarity[def.Rarity], def)
end

function BrainrotData.GetById(id)
	return byId[id]
end

function BrainrotData.ByRarity(rarity)
	return byRarity[rarity] or {}
end

function BrainrotData.Count()
	return #BrainrotData.CHARACTERS
end

-- Weighted rarity roll. rng is a Random so the server stays in charge.
function BrainrotData.RollRarity(weights, rng)
	local total = 0
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		total += weights[rarity] or 0
	end
	local roll = rng:NextNumber(0, total)
	local acc = 0
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		acc += weights[rarity] or 0
		if roll <= acc then
			return rarity
		end
	end
	return "Common"
end

function BrainrotData.RandomOfRarity(rarity, rng)
	local list = BrainrotData.ByRarity(rarity)
	if #list == 0 then
		return BrainrotData.CHARACTERS[1]
	end
	return list[rng:NextInteger(1, #list)]
end

-- Mutation roll: walk the chance table from rarest-feeling to plain.
function BrainrotData.RollMutation(rng)
	local roll = rng:NextNumber(0, 100)
	local acc = 0
	-- Chances are listed Normal-first; check the rare ones by remainder.
	local rainbow = BrainrotData.MUTATIONS[4]
	local diamond = BrainrotData.MUTATIONS[3]
	local gold = BrainrotData.MUTATIONS[2]
	local normal = BrainrotData.MUTATIONS[1]
	acc += rainbow.Chance
	if roll < acc then
		return rainbow
	end
	acc += diamond.Chance
	if roll < acc then
		return diamond
	end
	acc += gold.Chance
	if roll < acc then
		return gold
	end
	return normal
end

-- Price and income of a concrete spawn, mutation applied to both.
function BrainrotData.PriceFor(def, mutation)
	return math.floor(def.Price * mutation.Multiplier + 0.5)
end

function BrainrotData.IncomeFor(def, mutation)
	return math.floor(def.Income * mutation.Multiplier + 0.5)
end

-- "$1,250,000"-style formatting shared by the HUD and the labels.
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

-- The display name of a concrete spawn, mutation prefix included.
function BrainrotData.DisplayName(def, mutationName)
	if mutationName and mutationName ~= "Normal" then
		return mutationName .. " " .. def.Name
	end
	return def.Name
end

return BrainrotData
