-- Index.client.luau
-- The Buku Koleksi (Collection Index): a book-style panel listing all 24
-- brainrots from BrainrotData. Characters the player has owned at least
-- once (the server sets an Owned_<id> attribute) are lit up in their rarity
-- colour with price and income; the rest stay dark silhouettes named "???"
-- so the hunt always has a next target.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))

local gui = Instance.new("ScreenGui")
gui.Name = "BukuKoleksi"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- The open/close button, left side under the stats panel.
local openButton = Instance.new("TextButton")
openButton.Name = "OpenIndex"
openButton.Position = UDim2.new(0, 90, 0, 146)
openButton.Size = UDim2.fromOffset(170, 44)
openButton.BackgroundColor3 = Color3.fromRGB(120, 85, 40)
openButton.TextColor3 = Color3.fromRGB(255, 240, 200)
openButton.TextSize = 18
openButton.Font = Enum.Font.FredokaOne
openButton.Text = "BUKU KOLEKSI"
openButton.Parent = gui
local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 10)
openCorner.Parent = openButton

-- The book panel itself.
local book = Instance.new("Frame")
book.Name = "Book"
book.AnchorPoint = Vector2.new(0.5, 0.5)
book.Position = UDim2.fromScale(0.5, 0.5)
book.Size = UDim2.fromOffset(620, 470)
book.BackgroundColor3 = Color3.fromRGB(48, 38, 30)
book.BorderSizePixel = 0
book.Visible = false
book.Parent = gui
local bookCorner = Instance.new("UICorner")
bookCorner.CornerRadius = UDim.new(0, 14)
bookCorner.Parent = book

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 52)
title.BackgroundTransparency = 1
title.Text = "BUKU KOLEKSI BRAINROT"
title.TextSize = 26
title.Font = Enum.Font.FredokaOne
title.TextColor3 = Color3.fromRGB(255, 225, 150)
title.Parent = book

local progressLabel = Instance.new("TextLabel")
progressLabel.Name = "Progress"
progressLabel.Position = UDim2.new(0, 0, 0, 50)
progressLabel.Size = UDim2.new(1, 0, 0, 26)
progressLabel.BackgroundTransparency = 1
progressLabel.Text = "0 / 24 terkumpul"
progressLabel.TextSize = 16
progressLabel.Font = Enum.Font.FredokaOne
progressLabel.TextColor3 = Color3.fromRGB(230, 220, 200)
progressLabel.Parent = book

-- Explicit close button in the book's top-right corner.
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseIndex"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -10, 0, 10)
closeButton.Size = UDim2.fromOffset(40, 40)
closeButton.BackgroundColor3 = Color3.fromRGB(190, 60, 60)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 20
closeButton.Font = Enum.Font.FredokaOne
closeButton.Text = "X"
closeButton.Parent = book
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 9)
closeCorner.Parent = closeButton
closeButton.MouseButton1Click:Connect(function()
	book.Visible = false
end)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Cards"
scroll.Position = UDim2.new(0, 14, 0, 84)
scroll.Size = UDim2.new(1, -28, 1, -98)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 8
scroll.Parent = book
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(138, 108)
grid.CellPadding = UDim2.fromOffset(8, 8)
grid.Parent = scroll

local cardById = {}

local function buildCard(entry)
	local rarity = BrainrotData.GetRarity(entry.Rarity)
	local card = Instance.new("Frame")
	card.Name = "Card_" .. entry.Id
	card.BackgroundColor3 = Color3.fromRGB(30, 28, 30)
	card.BorderSizePixel = 0
	card.Parent = scroll
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local swatch = Instance.new("Frame")
	swatch.Name = "Swatch"
	swatch.Position = UDim2.new(0.5, -22, 0, 8)
	swatch.Size = UDim2.fromOffset(44, 36)
	swatch.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
	swatch.BorderSizePixel = 0
	swatch.Parent = card
	local swatchCorner = Instance.new("UICorner")
	swatchCorner.CornerRadius = UDim.new(0, 8)
	swatchCorner.Parent = swatch

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "CardName"
	nameLabel.Position = UDim2.new(0, 4, 0, 48)
	nameLabel.Size = UDim2.new(1, -8, 0, 30)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "???"
	nameLabel.TextSize = 13
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = Color3.fromRGB(120, 120, 125)
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	local statLabel = Instance.new("TextLabel")
	statLabel.Name = "CardStats"
	statLabel.Position = UDim2.new(0, 4, 0, 78)
	statLabel.Size = UDim2.new(1, -8, 0, 26)
	statLabel.BackgroundTransparency = 1
	statLabel.Text = entry.Rarity .. " - belum ketemu"
	statLabel.TextSize = 11
	statLabel.Font = Enum.Font.FredokaOne
	statLabel.TextColor3 = Color3.fromRGB(110, 110, 115)
	statLabel.TextWrapped = true
	statLabel.Parent = card

	cardById[entry.Id] = {
		Card = card,
		Swatch = swatch,
		NameLabel = nameLabel,
		StatLabel = statLabel,
		RarityColor = rarity.Color,
		BodyColor = entry.Color,
	}
	return cardById[entry.Id]
end

for _, entry in ipairs(BrainrotData.List) do
	buildCard(entry)
end

-- Repaint every card from the player's Owned_<id> attributes.
local function refreshIndex()
	local owned = 0
	for _, entry in ipairs(BrainrotData.List) do
		local view = cardById[entry.Id]
		local isOwned = player:GetAttribute("Owned_" .. entry.Id) == true
		if isOwned then
			owned += 1
			view.Card.BackgroundColor3 = Color3.fromRGB(52, 48, 44)
			view.Swatch.BackgroundColor3 = view.BodyColor
			view.NameLabel.Text = entry.Name
			view.NameLabel.TextColor3 = view.RarityColor
			view.StatLabel.Text = BrainrotData.FormatMoney(entry.Price) .. "  +" .. entry.Income .. "/dtk"
			view.StatLabel.TextColor3 = Color3.fromRGB(235, 230, 215)
		else
			view.Card.BackgroundColor3 = Color3.fromRGB(30, 28, 30)
			view.Swatch.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
			view.NameLabel.Text = "???"
			view.NameLabel.TextColor3 = Color3.fromRGB(120, 120, 125)
			view.StatLabel.Text = entry.Rarity .. " - belum ketemu"
			view.StatLabel.TextColor3 = Color3.fromRGB(110, 110, 115)
		end
	end
	progressLabel.Text = owned .. " / " .. #BrainrotData.List .. " terkumpul"
	openButton.Text = "BUKU KOLEKSI " .. owned .. "/" .. #BrainrotData.List
end

player.AttributeChanged:Connect(function(attributeName)
	if attributeName:sub(1, 6) == "Owned_" then
		refreshIndex()
	end
end)

openButton.MouseButton1Click:Connect(function()
	book.Visible = not book.Visible
	if book.Visible then
		refreshIndex()
	end
end)

refreshIndex()
