-- Index.client.luau -- the "Buku Koleksi" collection index.
-- A book of all 24 brainrots: the ones the player has owned are lit up
-- with their name, rarity, price and income; the rest are dark
-- silhouettes marked "???" so there is always a next one to hunt.
-- Ownership arrives with the server's StateSync snapshots.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local stateSync = remotes:WaitForChild("StateSync")

local gui = Instance.new("ScreenGui")
gui.Name = "BukuKoleksiGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Toggle button, bottom-left.
local openButton = Instance.new("TextButton")
openButton.Name = "OpenIndexButton"
openButton.AnchorPoint = Vector2.new(0, 1)
openButton.Position = UDim2.new(0, 12, 1, -12)
openButton.Size = UDim2.fromOffset(210, 56)
openButton.BackgroundColor3 = Color3.fromRGB(40, 130, 200)
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.Font = Enum.Font.FredokaOne
openButton.TextSize = 19
openButton.Text = "BUKU KOLEKSI"
openButton.Parent = gui
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = openButton

-- The book panel, centred, hidden until opened.
local panel = Instance.new("Frame")
panel.Name = "IndexPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(640, 470)
panel.BackgroundColor3 = Color3.fromRGB(24, 22, 38)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.fromOffset(18, 10)
title.Size = UDim2.fromOffset(500, 34)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 230, 140)
title.Font = Enum.Font.FredokaOne
title.TextSize = 26
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "BUKU KOLEKSI BRAINROT"
title.Parent = panel

local progressLabel = Instance.new("TextLabel")
progressLabel.Name = "Progress"
progressLabel.Position = UDim2.fromOffset(18, 44)
progressLabel.Size = UDim2.fromOffset(500, 22)
progressLabel.BackgroundTransparency = 1
progressLabel.TextColor3 = Color3.fromRGB(200, 200, 215)
progressLabel.Font = Enum.Font.FredokaOne
progressLabel.TextSize = 16
progressLabel.TextXAlignment = Enum.TextXAlignment.Left
progressLabel.Text = "Koleksi: 0 / 24"
progressLabel.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseIndexButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -12, 0, 12)
closeButton.Size = UDim2.fromOffset(40, 40)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.FredokaOne
closeButton.TextSize = 20
closeButton.Text = "X"
closeButton.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Cells"
scroll.Position = UDim2.fromOffset(14, 76)
scroll.Size = UDim2.new(1, -28, 1, -90)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.fromOffset(0, 560)
scroll.ScrollBarThickness = 8
scroll.Parent = panel
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(142, 104)
grid.CellPadding = UDim2.fromOffset(8, 8)
grid.Parent = scroll

-- One cell per character, created once; colours update per snapshot.
local cells = {}
local function buildCells()
	for index, c in ipairs(BrainrotData.Characters) do
		local cell = Instance.new("Frame")
		cell.Name = "Cell" .. index
		cell.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
		cell.BorderSizePixel = 0
		cell.LayoutOrder = BrainrotData.RarityRank(c.Rarity) * 100 + index
		cell.Parent = scroll
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 8)
		cc.Parent = cell

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Position = UDim2.fromOffset(6, 4)
		nameLabel.Size = UDim2.new(1, -12, 0, 40)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.TextSize = 14
		nameLabel.TextWrapped = true
		nameLabel.Text = "???"
		nameLabel.TextColor3 = Color3.fromRGB(90, 90, 105)
		nameLabel.Parent = cell

		local statLabel = Instance.new("TextLabel")
		statLabel.Name = "Stats"
		statLabel.Position = UDim2.fromOffset(6, 46)
		statLabel.Size = UDim2.new(1, -12, 0, 52)
		statLabel.BackgroundTransparency = 1
		statLabel.Font = Enum.Font.FredokaOne
		statLabel.TextSize = 12
		statLabel.TextWrapped = true
		statLabel.Text = "Belum ditemukan"
		statLabel.TextColor3 = Color3.fromRGB(90, 90, 105)
		statLabel.Parent = cell

		cells[index] = { Frame = cell, Name = nameLabel, Stats = statLabel }
	end
end
buildCells()

local ownedSet = {}
local function refresh()
	local ownedCount = 0
	for index, c in ipairs(BrainrotData.Characters) do
		local cell = cells[index]
		if ownedSet[index] then
			ownedCount += 1
			cell.Frame.BackgroundColor3 = BrainrotData.RarityColors[c.Rarity]
			cell.Name.Text = c.Name
			cell.Name.TextColor3 = Color3.fromRGB(20, 20, 30)
			cell.Stats.Text = string.format("%s\n%s\n%s/dtk", string.upper(c.Rarity),
				BrainrotData.FormatMoney(c.Price), BrainrotData.FormatMoney(c.Income))
			cell.Stats.TextColor3 = Color3.fromRGB(30, 30, 40)
		else
			cell.Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
			cell.Name.Text = "???"
			cell.Name.TextColor3 = Color3.fromRGB(90, 90, 105)
			cell.Stats.Text = "Belum ditemukan"
			cell.Stats.TextColor3 = Color3.fromRGB(90, 90, 105)
		end
	end
	progressLabel.Text = string.format("Koleksi: %d / %d", ownedCount, BrainrotData.Count())
end
refresh()

openButton.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		refresh()
	end
end)
closeButton.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

stateSync.OnClientEvent:Connect(function(snapshot)
	local before = 0
	for _ in pairs(ownedSet) do
		before += 1
	end
	ownedSet = {}
	for _, defIndex in ipairs(snapshot.Collection) do
		ownedSet[defIndex] = true
	end
	local after = 0
	for _ in pairs(ownedSet) do
		after += 1
	end
	-- Keep the toggle button honest: it counts the collection too.
	openButton.Text = string.format("BUKU KOLEKSI (%d/%d)", after, BrainrotData.Count())
	if panel.Visible or after ~= before then
		refresh()
	end
end)
