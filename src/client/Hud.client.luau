-- Hud.client.luau
-- The Brainrot Bazaar HUD: a top panel with cash, income per second, stored
-- cash waiting on the collect pad, rebirth count and multiplier; a tsunami
-- countdown chip; toast messages; and the two-tap rebirth button (first tap
-- arms it, second tap confirms) plus a gacha price hint.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local toastEvent = remotes:WaitForChild("Toast")
local stateEvent = remotes:WaitForChild("StateUpdate")
local rebirthEvent = remotes:WaitForChild("RebirthRequest")
local tsunamiValue = ReplicatedStorage:WaitForChild("TsunamiIn")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(name, parent, position, size, textSize, color, align)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextScaled = false
	label.TextSize = textSize
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color
	label.TextXAlignment = align or Enum.TextXAlignment.Left
	label.TextStrokeTransparency = 0.6
	label.Parent = parent
	return label
end

-- Top stats panel, kept clear of the top-left corner where Roblox puts its
-- own menu buttons: the panel starts a little down and centred-left.
local panel = Instance.new("Frame")
panel.Name = "StatsPanel"
panel.Position = UDim2.new(0, 90, 0, 14)
panel.Size = UDim2.fromOffset(330, 118)
panel.BackgroundColor3 = Color3.fromRGB(35, 32, 55)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = gui
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local cashLabel = makeLabel("Cash", panel, UDim2.new(0, 14, 0, 6), UDim2.new(1, -28, 0, 34), 26,
	Color3.fromRGB(140, 255, 150))
cashLabel.Text = "$100"
local incomeLabel = makeLabel("Income", panel, UDim2.new(0, 14, 0, 44), UDim2.new(1, -28, 0, 24), 17,
	Color3.fromRGB(255, 235, 160))
incomeLabel.Text = "Penghasilan: $0/dtk"
local storedLabel = makeLabel("Stored", panel, UDim2.new(0, 14, 0, 68), UDim2.new(1, -28, 0, 24), 17,
	Color3.fromRGB(140, 220, 255))
storedLabel.Text = "Di pad panen: $0"
local rebirthLabel = makeLabel("RebirthInfo", panel, UDim2.new(0, 14, 0, 92), UDim2.new(1, -28, 0, 22), 15,
	Color3.fromRGB(255, 170, 230))
rebirthLabel.Text = "Rebirth: 0  Pengali: x1.00"

-- Tsunami countdown chip, top centre.
local tsunamiChip = Instance.new("Frame")
tsunamiChip.Name = "TsunamiChip"
tsunamiChip.AnchorPoint = Vector2.new(0.5, 0)
tsunamiChip.Position = UDim2.new(0.5, 0, 0, 14)
tsunamiChip.Size = UDim2.fromOffset(250, 44)
tsunamiChip.BackgroundColor3 = Color3.fromRGB(30, 90, 160)
tsunamiChip.BackgroundTransparency = 0.1
tsunamiChip.BorderSizePixel = 0
tsunamiChip.Parent = gui
local tsunamiCorner = Instance.new("UICorner")
tsunamiCorner.CornerRadius = UDim.new(0, 12)
tsunamiCorner.Parent = tsunamiChip
local tsunamiLabel = makeLabel("TsunamiText", tsunamiChip, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 20,
	Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Center)
tsunamiLabel.Text = "Tsunami: 180 dtk"

local function refreshTsunami()
	local seconds = math.max(0, math.floor(tsunamiValue.Value))
	tsunamiLabel.Text = "Tsunami: " .. seconds .. " dtk"
	if seconds <= 10 then
		tsunamiChip.BackgroundColor3 = Color3.fromRGB(200, 45, 45)
		tsunamiLabel.Text = "TSUNAMI " .. seconds .. " DTK! MASUK BASE!"
	else
		tsunamiChip.BackgroundColor3 = Color3.fromRGB(30, 90, 160)
	end
end
tsunamiValue.Changed:Connect(refreshTsunami)
refreshTsunami()

-- Toast stack, bottom centre: newest on top, each fades after 4 seconds.
local toastFrame = Instance.new("Frame")
toastFrame.Name = "Toasts"
toastFrame.AnchorPoint = Vector2.new(0.5, 1)
toastFrame.Position = UDim2.new(0.5, 0, 1, -110)
toastFrame.Size = UDim2.fromOffset(560, 160)
toastFrame.BackgroundTransparency = 1
toastFrame.Parent = gui
local toastLayout = Instance.new("UIListLayout")
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.Padding = UDim.new(0, 6)
toastLayout.Parent = toastFrame

local function showToast(message)
	local label = Instance.new("TextLabel")
	label.Name = "Toast"
	label.Size = UDim2.new(1, 0, 0, 36)
	label.BackgroundColor3 = Color3.fromRGB(30, 28, 45)
	label.BackgroundTransparency = 0.15
	label.Text = message
	label.TextSize = 18
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextWrapped = true
	label.Parent = toastFrame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = label
	task.delay(4, function()
		label:Destroy()
	end)
end
toastEvent.OnClientEvent:Connect(showToast)

-- Rebirth button: two-tap confirm so nobody wipes a base by accident.
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.AnchorPoint = Vector2.new(1, 1)
rebirthButton.Position = UDim2.new(1, -16, 1, -16)
rebirthButton.Size = UDim2.fromOffset(240, 62)
rebirthButton.BackgroundColor3 = Color3.fromRGB(170, 60, 220)
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.TextSize = 19
rebirthButton.Font = Enum.Font.FredokaOne
rebirthButton.Text = "REBIRTH"
rebirthButton.Parent = gui
local rebirthCorner = Instance.new("UICorner")
rebirthCorner.CornerRadius = UDim.new(0, 12)
rebirthCorner.Parent = rebirthButton

local rebirthCost = 10000
local rebirthArmed = false
rebirthButton.MouseButton1Click:Connect(function()
	if not rebirthArmed then
		rebirthArmed = true
		rebirthButton.Text = "YAKIN? KETUK LAGI!"
		rebirthButton.BackgroundColor3 = Color3.fromRGB(230, 60, 60)
		task.delay(3, function()
			rebirthArmed = false
			rebirthButton.Text = "REBIRTH " .. BrainrotData.FormatMoney(rebirthCost)
			rebirthButton.BackgroundColor3 = Color3.fromRGB(170, 60, 220)
		end)
	else
		rebirthArmed = false
		rebirthEvent:FireServer()
		rebirthButton.Text = "REBIRTH " .. BrainrotData.FormatMoney(rebirthCost)
		rebirthButton.BackgroundColor3 = Color3.fromRGB(170, 60, 220)
	end
end)

-- Gacha price hint under the rebirth button.
local gachaHint = makeLabel("GachaHint", gui, UDim2.new(1, -256, 1, -108), UDim2.fromOffset(240, 24), 15,
	Color3.fromRGB(255, 190, 235), Enum.TextXAlignment.Right)
gachaHint.Text = "Gacha di plaza: $250"

-- Server state pushes drive every number on the panel.
stateEvent.OnClientEvent:Connect(function(state)
	cashLabel.Text = BrainrotData.FormatMoney(state.Cash)
	incomeLabel.Text = "Penghasilan: " .. BrainrotData.FormatMoney(state.Income) .. "/dtk"
	storedLabel.Text = "Di pad panen: " .. BrainrotData.FormatMoney(state.Stored)
	rebirthLabel.Text = string.format("Rebirth: %d  Pengali: x%.2f  Base #%d%s",
		state.Rebirths, state.Multiplier, state.BaseIndex, state.Locked and "  TERKUNCI" or "")
	rebirthCost = state.RebirthCost
	if not rebirthArmed then
		rebirthButton.Text = "REBIRTH " .. BrainrotData.FormatMoney(state.RebirthCost)
	end
	gachaHint.Text = "Gacha di plaza: " .. BrainrotData.FormatMoney(state.GachaCost)
end)

-- Objective line under the stats panel: always one clear next step.
local objectiveLabel = makeLabel("Objective", gui, UDim2.new(0, 90, 0, 196), UDim2.fromOffset(420, 24), 15,
	Color3.fromRGB(255, 255, 255))
objectiveLabel.Text = "Tujuan: beli brainrot, panen di pad hijau, kunci base!"

showToast("Beli brainrot dari ban berjalan TOKO BRAINROT!")
