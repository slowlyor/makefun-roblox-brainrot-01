-- Index.client.luau
-- Brainrot Bazaar: the "Buku Koleksi" collection index. A book of all
-- 24 brainrots: the ones the player has owned are lit up with their
-- price and income, the rest stay dark "???" silhouettes so there is
-- always a reason to keep hunting the belt and the gacha machine.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BB_Remotes")
local stateRemote = remotes:WaitForChild("State")

local gui = Instance.new("ScreenGui")
gui.Name = "CollectionIndex"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local openButton = Instance.new("TextButton")
openButton.Name = "OpenIndex"
openButton.Size = UDim2.fromOffset(170, 48)
openButton.Position = UDim2.new(1, -182, 0, 12)
openButton.BackgroundColor3 = Color3.fromRGB(90, 70, 200)
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.Font = Enum.Font.FredokaOne
openButton.TextSize = 19
openButton.Text = "BUKU KOLEKSI"
openButton.Parent = gui
local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 10)
openCorner.Parent = openButton

local frame = Instance.new("Frame")
frame.Name = "Book"
frame.Size = UDim2.fromOffset(620, 470)
frame.Position = UDim2.new(0.5, -310, 0.5, -235)
frame.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
frame.BackgroundTransparency = 0.08
frame.Visible = false
frame.Parent = gui
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 14)
frameCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.fromOffset(620, 44)
title.Position = UDim2.fromOffset(0, 6)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 230, 150)
title.Font = Enum.Font.FredokaOne
title.TextSize = 26
title.Text = "BUKU KOLEKSI BRAINROT"
title.Parent = frame

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.fromOffset(40, 40)
closeButton.Position = UDim2.fromOffset(572, 6)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.FredokaOne
closeButton.TextSize = 20
closeButton.Text = "X"
closeButton.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Entries"
scroll.Size = UDim2.fromOffset(596, 404)
scroll.Position = UDim2.fromOffset(12, 56)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 8
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.Parent = frame

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(188, 96)
layout.CellPadding = UDim2.fromOffset(10, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
end)

local ownedSet = {}
local cards = {}

local function buildCards()
	-- Rarest first in the book so the chase reads top-down.
	local defs = {}
	for _, def in ipairs(BrainrotData.CHARACTERS) do
		table.insert(defs, def)
	end
	table.sort(defs, function(a, b)
		local oa = BrainrotData.RARITY_ORDER[a.Rarity]
		local ob = BrainrotData.RARITY_ORDER[b.Rarity]
		if oa ~= ob then
			return oa > ob
		end
		return a.Price > b.Price
	end)
	for i, def in ipairs(defs) do
		local card = Instance.new("Frame")
		card.Name = "Card_" .. def.Id
		card.LayoutOrder = i
		card.BackgroundColor3 = Color3.fromRGB(40, 42, 54)
		card.Parent = scroll
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = card
		local swatch = Instance.new("Frame")
		swatch.Name = "Swatch"
		swatch.Size = UDim2.fromOffset(46, 46)
		swatch.Position = UDim2.fromOffset(8, 8)
		swatch.BackgroundColor3 = def.Body
		swatch.Parent = card
		local swatchCorner = Instance.new("UICorner")
		swatchCorner.CornerRadius = UDim.new(0, 8)
		swatchCorner.Parent = swatch
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.fromOffset(124, 46)
		nameLabel.Position = UDim2.fromOffset(60, 6)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.TextSize = 15
		nameLabel.TextWrapped = true
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextYAlignment = Enum.TextYAlignment.Top
		nameLabel.Parent = card
		local statLabel = Instance.new("TextLabel")
		statLabel.Name = "Stats"
		statLabel.Size = UDim2.fromOffset(172, 36)
		statLabel.Position = UDim2.fromOffset(8, 56)
		statLabel.BackgroundTransparency = 1
		statLabel.TextColor3 = Color3.fromRGB(190, 230, 255)
		statLabel.Font = Enum.Font.FredokaOne
		statLabel.TextSize = 14
		statLabel.TextWrapped = true
		statLabel.TextXAlignment = Enum.TextXAlignment.Left
		statLabel.Parent = card
		cards[def.Id] = { Card = card, Swatch = swatch, Name = nameLabel, Stats = statLabel, Def = def }
	end
end

local function refreshCards()
	local ownedCount = 0
	for defId, entry in pairs(cards) do
		local def = entry.Def
		if ownedSet[defId] then
			ownedCount += 1
			entry.Card.BackgroundColor3 = Color3.fromRGB(52, 56, 74)
			entry.Swatch.BackgroundColor3 = def.Body
			entry.Swatch.BackgroundTransparency = 0
			entry.Name.Text = def.Name
			entry.Name.TextColor3 = BrainrotData.RARITY_COLORS[def.Rarity]
			entry.Stats.Text = def.Rarity .. " - $" .. def.Price .. " - $" .. def.Income .. "/s\n" .. def.Blurb
		else
			entry.Card.BackgroundColor3 = Color3.fromRGB(26, 27, 34)
			entry.Swatch.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
			entry.Swatch.BackgroundTransparency = 0.15
			entry.Name.Text = "???"
			entry.Name.TextColor3 = Color3.fromRGB(110, 112, 124)
			entry.Stats.Text = def.Rarity .. " - siluet misterius...\nBuruan temukan di conveyor / gacha!"
		end
	end
	title.Text = "BUKU KOLEKSI BRAINROT (" .. ownedCount .. "/" .. BrainrotData.Count() .. ")"
	openButton.Text = "BUKU KOLEKSI " .. ownedCount .. "/" .. BrainrotData.Count()
end

buildCards()
refreshCards()

openButton.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)
closeButton.MouseButton1Click:Connect(function()
	frame.Visible = false
end)

stateRemote.OnClientEvent:Connect(function(state)
	ownedSet = {}
	for _, defId in ipairs(state.Collection or {}) do
		ownedSet[defId] = true
	end
	refreshCards()
end)

-- Press B anywhere to open or close the book.
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		frame.Visible = not frame.Visible
	end
end)

-- Owned-first ordering helper: how many lit cards the book shows.
local function ownedCardCount()
	local n = 0
	for defId in pairs(ownedSet) do
		if cards[defId] then
			n += 1
		end
	end
	return n
end
_G.BrainrotIndexOwnedCount = ownedCardCount
