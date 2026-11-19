-- Hud: the Brainrot Bazaar HUD. Cash / income / stored panel (top-right, clear of
-- Roblox's top-left menu buttons), tsunami countdown, toasts, and the two-tap
-- rebirth button. Buy/collect/lock/gacha all work by clicking the world parts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("StateUpdate")
local toastEvent = remotes:WaitForChild("Toast")
local tsunamiEvent = remotes:WaitForChild("TsunamiWarning")

local gui = Instance.new("ScreenGui")
gui.Name = "BazaarHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

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

-- Top-right money panel.
local panel = Instance.new("Frame")
panel.Name = "MoneyPanel"
panel.Size = UDim2.fromOffset(260, 150)
panel.Position = UDim2.new(1, -276, 0, 16)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local function makeLabel(name, y, size, color)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = UDim2.new(1, -20, 0, size)
	l.Position = UDim2.new(0, 10, 0, y)
	l.BackgroundTransparency = 1
	l.TextColor3 = color
	l.Font = Enum.Font.FredokaOne
	l.TextSize = 20
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = panel
	return l
end

local cashLabel = makeLabel("Cash", 8, 28, Color3.fromRGB(120, 255, 120))
local incomeLabel = makeLabel("Income", 40, 24, Color3.fromRGB(255, 220, 90))
local storedLabel = makeLabel("Stored", 68, 24, Color3.fromRGB(140, 220, 255))
local rebirthLabel = makeLabel("Rebirth", 96, 24, Color3.fromRGB(255, 140, 220))
local lockLabel = makeLabel("Lock", 122, 22, Color3.fromRGB(255, 120, 120))
cashLabel.Text = "Uang: $150"
incomeLabel.Text = "Income: $0/dtk"
storedLabel.Text = "Tersimpan: $0"
rebirthLabel.Text = "Rebirth: 0 (x1.00)"
lockLabel.Text = ""

-- Tsunami countdown banner (top centre).
local tsunami = Instance.new("TextLabel")
tsunami.Name = "TsunamiBanner"
tsunami.Size = UDim2.fromOffset(420, 54)
tsunami.Position = UDim2.new(0.5, -210, 0, 16)
tsunami.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
tsunami.BackgroundTransparency = 0.15
tsunami.TextColor3 = Color3.fromRGB(255, 255, 255)
tsunami.Font = Enum.Font.FredokaOne
tsunami.TextSize = 24
tsunami.Text = ""
tsunami.Visible = false
tsunami.Parent = gui
local tsunamiCorner = Instance.new("UICorner")
tsunamiCorner.CornerRadius = UDim.new(0, 12)
tsunamiCorner.Parent = tsunami

-- Toasts (bottom centre, stacked).
local toastBox = Instance.new("Frame")
toastBox.Name = "Toasts"
toastBox.Size = UDim2.fromOffset(520, 120)
toastBox.Position = UDim2.new(0.5, -260, 1, -140)
toastBox.BackgroundTransparency = 1
toastBox.Parent = gui
local toastLayout = Instance.new("UIListLayout")
toastLayout.FillDirection = Enum.FillDirection.Vertical
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.Padding = UDim.new(0, 6)
toastLayout.Parent = toastBox

local function showToast(text)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromOffset(500, 34)
	t.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	t.BackgroundTransparency = 0.15
	t.TextColor3 = Color3.fromRGB(255, 255, 255)
	t.Font = Enum.Font.FredokaOne
	t.TextSize = 18
	t.Text = text
	t.Parent = toastBox
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = t
	task.delay(5, function()
		t:Destroy()
	end)
end

-- Bottom-right buttons: rebirth (two-tap) and collection index.
local rebirthBtn = Instance.new("TextButton")
rebirthBtn.Name = "RebirthButton"
rebirthBtn.Size = UDim2.fromOffset(220, 52)
rebirthBtn.Position = UDim2.new(1, -236, 1, -140)
rebirthBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 160)
rebirthBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthBtn.Font = Enum.Font.FredokaOne
rebirthBtn.TextSize = 19
rebirthBtn.Text = "REBIRTH"
rebirthBtn.Parent = gui
local rbCorner = Instance.new("UICorner")
rbCorner.CornerRadius = UDim.new(0, 12)
rbCorner.Parent = rebirthBtn

local indexBtn = Instance.new("TextButton")
indexBtn.Name = "IndexButton"
indexBtn.Size = UDim2.fromOffset(220, 52)
indexBtn.Position = UDim2.new(1, -236, 1, -200)
indexBtn.BackgroundColor3 = Color3.fromRGB(70, 140, 255)
indexBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
indexBtn.Font = Enum.Font.FredokaOne
indexBtn.TextSize = 19
indexBtn.Text = "BUKU KOLEKSI"
indexBtn.Parent = gui
local ixCorner = Instance.new("UICorner")
ixCorner.CornerRadius = UDim.new(0, 12)
ixCorner.Parent = indexBtn

-- Two-tap rebirth: first tap arms it for 5 seconds, second tap confirms.
local rebirthArmed = false
local rebirthCost = 10000
local armToken = 0
rebirthBtn.MouseButton1Click:Connect(function()
	if not rebirthArmed then
		rebirthArmed = true
		armToken = armToken + 1
		local token = armToken
		rebirthBtn.Text = "YAKIN? KLIK LAGI!"
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(220, 30, 30)
		task.delay(5, function()
			-- Only disarm if no newer arm happened in the meantime.
			if token == armToken then
				rebirthArmed = false
				rebirthBtn.Text = "REBIRTH"
				rebirthBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 160)
			end
		end)
		return
	end
	rebirthArmed = false
	armToken = armToken + 1
	rebirthBtn.Text = "REBIRTH"
	rebirthBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 160)
	remotes:WaitForChild("Rebirth"):FireServer()
end)

-- Open/close the Collection Index (the Index client script owns the panel).
local indexOpen = false
indexBtn.MouseButton1Click:Connect(function()
	indexOpen = not indexOpen
	local indexGui = player.PlayerGui:FindFirstChild("CollectionIndex")
	if indexGui then
		indexGui.Enabled = indexOpen
	end
end)

-- Hint bar: how to play.
local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.Size = UDim2.fromOffset(560, 30)
hint.Position = UDim2.new(0.5, -280, 1, -36)
hint.BackgroundTransparency = 1
hint.TextColor3 = Color3.fromRGB(255, 255, 255)
hint.Font = Enum.Font.FredokaOne
hint.TextSize = 16
hint.Text = "Klik brainrot di toko untuk beli - Klik pad hijau untuk ambil uang - Lari ke base saat tsunami!"
hint.Parent = gui

stateEvent.OnClientEvent:Connect(function(state)
	cashLabel.Text = "Uang: " .. money(state.cash)
	incomeLabel.Text = "Income: " .. money(state.income) .. "/dtk"
	storedLabel.Text = "Tersimpan: " .. money(state.stored) .. " (klik pad hijau)"
	rebirthLabel.Text = "Rebirth: " .. state.rebirths .. " (x" .. string.format("%.2f", state.multiplier) .. ") - berikut: " .. money(state.rebirthCost)
	rebirthCost = state.rebirthCost
	if state.locked then
		lockLabel.Text = "Base TERKUNCI"
	else
		lockLabel.Text = "Base terbuka - klik tombol merah untuk kunci"
	end
end)

toastEvent.OnClientEvent:Connect(showToast)

tsunamiEvent.OnClientEvent:Connect(function(secs)
	tsunami.Visible = true
	tsunami.Text = "TSUNAMI DALAM " .. secs .. " DETIK - LARI KE BASE!"
	if secs <= 0 then
		tsunami.Visible = false
	end
	task.delay(11, function()
		tsunami.Visible = false
	end)
end)
