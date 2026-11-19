-- Index.client.luau
-- "Buku Koleksi", the collection index: a toggleable book of all 24
-- brainrots in BrainrotData. Ones the player has owned at least once are
-- lit up with their name, rarity, price and $/s; the rest stay dark
-- silhouettes marked "???" -- the genre's favourite reason to keep
-- playing. Owned-ness arrives inside every server state snapshot, so
-- the book is never stale.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local stateRemote = remotes:WaitForChild("State")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "BukuKoleksi"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Toggle button, bottom-centre-left, clear of the HUD's corner buttons.
local toggle = Instance.new("TextButton")
toggle.Name = "IndexToggle"
toggle.Position = UDim2.new(0, 14, 1, -232)
toggle.Size = UDim2.new(0, 176, 0, 52)
toggle.BackgroundColor3 = Color3.fromRGB(255, 176, 32)
toggle.BackgroundTransparency = 0.1
toggle.Font = Enum.Font.FredokaOne
toggle.TextSize = 18
toggle.TextColor3 = Color3.fromRGB(60, 45, 10)
toggle.Text = "BUKU KOLEKSI"
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 12)
toggleCorner.Parent = toggle
toggle.Parent = gui

-- The book itself: a centred scrolling grid, hidden until toggled.
local book = Instance.new("Frame")
book.Name = "Book"
book.Position = UDim2.new(0.5, -330, 0.5, -240)
book.Size = UDim2.new(0, 660, 0, 480)
book.BackgroundColor3 = Color3.fromRGB(28, 26, 40)
book.BackgroundTransparency = 0.08
book.BorderSizePixel = 0
book.Visible = false
local bookCorner = Instance.new("UICorner")
bookCorner.CornerRadius = UDim.new(0, 16)
bookCorner.Parent = book
book.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 46)
title.BackgroundTransparency = 1
title.Font = Enum.Font.FredokaOne
title.TextSize = 28
title.TextColor3 = Color3.fromRGB(255, 220, 90)
title.Text = "BUKU KOLEKSI BRAINROT (0/24)"
title.Parent = book

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Grid"
scroll.Position = UDim2.new(0, 12, 0, 54)
scroll.Size = UDim2.new(1, -24, 1, -66)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = book

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0, 150, 0, 108)
layout.CellPadding = UDim2.new(0, 8, 0, 8)
layout.Parent = scroll

toggle.Activated:Connect(function()
	book.Visible = not book.Visible
end)

-- One card per character, created once; refresh() only recolours them.
local cards: { [string]: Frame } = {}

local function makeCard(def): Frame
	local card = Instance.new("Frame")
	card.Name = "Card_" .. def.id
	card.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	card.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local swatch = Instance.new("Frame")
	swatch.Name = "Swatch"
	swatch.Position = UDim2.new(0, 8, 0, 8)
	swatch.Size = UDim2.new(0, 40, 0, 40)
	swatch.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	swatch.BorderSizePixel = 0
	local swatchCorner = Instance.new("UICorner")
	swatchCorner.CornerRadius = UDim.new(0, 8)
	swatchCorner.Parent = swatch
	swatch.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Position = UDim2.new(0, 54, 0, 6)
	nameLabel.Size = UDim2.new(1, -60, 0, 44)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextSize = 14
	nameLabel.TextWrapped = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextYAlignment = Enum.TextYAlignment.Top
	nameLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
	nameLabel.Text = "???"
	nameLabel.Parent = card

	local stats = Instance.new("TextLabel")
	stats.Name = "Stats"
	stats.Position = UDim2.new(0, 8, 0, 56)
	stats.Size = UDim2.new(1, -16, 0, 46)
	stats.BackgroundTransparency = 1
	stats.Font = Enum.Font.FredokaOne
	stats.TextSize = 13
	stats.TextWrapped = true
	stats.TextXAlignment = Enum.TextXAlignment.Left
	stats.TextYAlignment = Enum.TextYAlignment.Top
	stats.TextColor3 = Color3.fromRGB(170, 175, 190)
	stats.Text = "Belum pernah dimiliki"
	stats.Parent = card

	card.Parent = scroll
	return card
end

for _, def in ipairs(BrainrotData.LIST) do
	cards[def.id] = makeCard(def)
end

-- Refresh every card from the latest snapshot's owned-id list.
local function refresh(ownedList: { string })
	local owned: { [string]: boolean } = {}
	for _, id in ipairs(ownedList) do
		owned[id] = true
	end
	local count = 0
	for _, def in ipairs(BrainrotData.LIST) do
		local card = cards[def.id]
		local swatch = card:FindFirstChild("Swatch")
		local nameLabel = card:FindFirstChild("Name")
		local stats = card:FindFirstChild("Stats")
		if owned[def.id] then
			count += 1
			card.BackgroundColor3 = Color3.fromRGB(46, 44, 66)
			if swatch then
				swatch.BackgroundColor3 = def.color
			end
			if nameLabel then
				nameLabel.Text = def.name
				nameLabel.TextColor3 = BrainrotData.RARITY_INFO[def.rarity].color
			end
			if stats then
				stats.Text = string.format("%s\n%s - %s/dtk", def.rarity, BrainrotData.formatMoney(def.price), BrainrotData.formatMoney(def.income))
			end
		else
			card.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
			if swatch then
				swatch.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
			end
			if nameLabel then
				nameLabel.Text = "???"
				nameLabel.TextColor3 = Color3.fromRGB(120, 122, 135)
			end
			if stats then
				stats.Text = "Belum pernah dimiliki"
			end
		end
	end
	title.Text = string.format("BUKU KOLEKSI BRAINROT (%d/%d)", count, #BrainrotData.LIST)
end

stateRemote.OnClientEvent:Connect(function(snap)
	if snap and snap.owned then
		refresh(snap.owned)
	end
end)

-- Keyboard shortcut: B opens and closes the book, for players who would
-- rather not reach for the mouse mid-dash during a tsunami warning.
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		book.Visible = not book.Visible
	end
end)
