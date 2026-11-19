-- Index: the 'Buku Koleksi' (Collection Index) GUI.
-- Every one of the 24 characters is listed: owned ones are lit with their
-- rarity colour, unowned ones show as '???'. Opened from the HUD's BUKU KOLEKSI
-- button; starts closed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("StateUpdate")

local gui = Instance.new("ScreenGui")
gui.Name = "CollectionIndex"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "IndexFrame"
frame.Size = UDim2.fromOffset(460, 520)
frame.Position = UDim2.new(0.5, -230, 0.5, -260)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 0, 44)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 220, 90)
title.Font = Enum.Font.FredokaOne
title.TextSize = 26
title.Text = "BUKU KOLEKSI"
title.Parent = frame

local countLabel = Instance.new("TextLabel")
countLabel.Name = "Count"
countLabel.Size = UDim2.new(1, -20, 0, 26)
countLabel.Position = UDim2.new(0, 10, 0, 52)
countLabel.BackgroundTransparency = 1
countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
countLabel.Font = Enum.Font.FredokaOne
countLabel.TextSize = 18
countLabel.Text = "0 / 24 terkumpul"
countLabel.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.Size = UDim2.fromOffset(40, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 22
closeBtn.Text = "X"
closeBtn.Parent = frame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "List"
scroll.Size = UDim2.new(1, -20, 1, -96)
scroll.Position = UDim2.new(0, 10, 0, 86)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 24 * 46)
scroll.Parent = frame
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = scroll

local function money(n)
	n = math.floor(n + 0.5)
	local s = tostring(n)
	local out = ""
	while #s > 3 do
		out = "," .. string.sub(s, -3) .. out
		s = string.sub(s, 1, -4)
	end
	return "$" .. s .. out
end

-- One row per character, built once; refresh() repaints owned vs '???'.
local rows = {}
for _, char in ipairs(BrainrotData.Characters) do
	local row = Instance.new("Frame")
	row.Name = "Row" .. char.id
	row.Size = UDim2.new(1, -8, 0, 40)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	row.BorderSizePixel = 0
	row.Parent = scroll
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 8)
	rc.Parent = row

	local dot = Instance.new("Frame")
	dot.Name = "Dot"
	dot.Size = UDim2.fromOffset(18, 18)
	dot.Position = UDim2.new(0, 8, 0.5, -9)
	dot.BackgroundColor3 = BrainrotData.RarityColors[char.rarity]
	dot.BorderSizePixel = 0
	dot.Parent = row
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(1, 0)
	dc.Parent = dot

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -120, 1, 0)
	nameLabel.Position = UDim2.new(0, 34, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextSize = 17
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = "???"
	nameLabel.Parent = row

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Size = UDim2.new(0, 84, 1, 0)
	priceLabel.Position = UDim2.new(1, -88, 0, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
	priceLabel.Font = Enum.Font.FredokaOne
	priceLabel.TextSize = 15
	priceLabel.TextXAlignment = Enum.TextXAlignment.Right
	priceLabel.Text = ""
	priceLabel.Parent = row

	rows[char.id] = { row = row, dot = dot, name = nameLabel, price = priceLabel, char = char }
end

local ownedSet = {}
local function refresh()
	local n = 0
	for id, entry in pairs(rows) do
		local char = entry.char
		if ownedSet[id] then
			n = n + 1
			entry.name.Text = char.name .. "  (" .. char.rarity .. ")"
			entry.name.TextColor3 = Color3.fromRGB(255, 255, 255)
			entry.price.Text = money(char.price) .. "  |  " .. money(char.income) .. "/s"
			entry.dot.BackgroundColor3 = BrainrotData.RarityColors[char.rarity]
			entry.row.BackgroundColor3 = Color3.fromRGB(50, 60, 80)
		else
			entry.name.Text = "???  (" .. char.rarity .. ")"
			entry.name.TextColor3 = Color3.fromRGB(150, 150, 160)
			entry.price.Text = money(char.price)
			entry.dot.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
			entry.row.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		end
	end
	countLabel.Text = n .. " / 24 terkumpul"
end

stateEvent.OnClientEvent:Connect(function(state)
	ownedSet = {}
	if state.ownedIds then
		for _, id in ipairs(state.ownedIds) do
			ownedSet[id] = true
		end
	end
	refresh()
end)

refresh()
