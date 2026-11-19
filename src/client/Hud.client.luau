-- Hud.client.luau
-- Brainrot Bazaar: the heads-up display. A top-centre money panel
-- (kept clear of Roblox's own top-left menu buttons), a stored-cash
-- panel, the tsunami countdown, toast messages, and the action
-- buttons: Panen (collect), Kunci (lock), Gacha, and a two-tap
-- Rebirth button that must be armed before it fires.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BB_Remotes")
local stateRemote = remotes:WaitForChild("State")
local toastRemote = remotes:WaitForChild("Toast")
local actionRemote = remotes:WaitForChild("Action")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(parent, name, size, pos, text, color, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = pos
	label.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	label.BackgroundTransparency = 0.25
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = textSize or 20
	label.Text = text
	label.Parent = parent
	return label
end

local function makeButton(parent, name, size, pos, text, bg)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = pos
	button.BackgroundColor3 = bg
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.FredokaOne
	button.TextSize = 18
	button.Text = text
	button.AutoButtonColor = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

-- Top-centre panel: cash, income, stored, multiplier.
local panel = Instance.new("Frame")
panel.Name = "MoneyPanel"
panel.Size = UDim2.fromOffset(430, 64)
panel.Position = UDim2.new(0.5, -215, 0, 12)
panel.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
panel.BackgroundTransparency = 0.2
panel.Parent = gui
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local cashLabel = makeLabel(panel, "Cash", UDim2.fromOffset(200, 30), UDim2.fromOffset(10, 4), "$0", Color3.fromRGB(120, 255, 140), 24)
cashLabel.BackgroundTransparency = 1
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
local incomeLabel = makeLabel(panel, "Income", UDim2.fromOffset(200, 26), UDim2.fromOffset(10, 34), "+$0/s", Color3.fromRGB(170, 230, 255), 17)
incomeLabel.BackgroundTransparency = 1
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
local storedLabel = makeLabel(panel, "Stored", UDim2.fromOffset(200, 30), UDim2.fromOffset(220, 4), "Tersimpan: $0", Color3.fromRGB(255, 220, 120), 19)
storedLabel.BackgroundTransparency = 1
storedLabel.TextXAlignment = Enum.TextXAlignment.Left
local multLabel = makeLabel(panel, "Mult", UDim2.fromOffset(200, 26), UDim2.fromOffset(220, 34), "x1.00", Color3.fromRGB(255, 170, 230), 17)
multLabel.BackgroundTransparency = 1
multLabel.TextXAlignment = Enum.TextXAlignment.Left

local tsunamiLabel = makeLabel(gui, "Tsunami", UDim2.fromOffset(300, 34), UDim2.new(0.5, -150, 0, 84), "Tsunami: 180s", Color3.fromRGB(140, 220, 255), 19)
local toastLabel = makeLabel(gui, "Toast", UDim2.fromOffset(560, 40), UDim2.new(0.5, -280, 0, 124), "", Color3.fromRGB(255, 255, 160), 21)
toastLabel.BackgroundTransparency = 1

-- Bottom action bar.
local bar = Instance.new("Frame")
bar.Name = "ActionBar"
bar.Size = UDim2.fromOffset(560, 58)
bar.Position = UDim2.new(0.5, -280, 1, -72)
bar.BackgroundTransparency = 1
bar.Parent = gui

local collectButton = makeButton(bar, "Collect", UDim2.fromOffset(130, 52), UDim2.fromOffset(0, 3), "PANEN $0", Color3.fromRGB(38, 180, 80))
local lockButton = makeButton(bar, "Lock", UDim2.fromOffset(130, 52), UDim2.fromOffset(142, 3), "KUNCI BASE", Color3.fromRGB(220, 70, 70))
local gachaButton = makeButton(bar, "Gacha", UDim2.fromOffset(130, 52), UDim2.fromOffset(284, 3), "GACHA $750", Color3.fromRGB(190, 60, 160))
local rebirthButton = makeButton(bar, "Rebirth", UDim2.fromOffset(142, 52), UDim2.fromOffset(426, 3), "REBIRTH", Color3.fromRGB(240, 160, 40))

collectButton.MouseButton1Click:Connect(function()
	actionRemote:FireServer("collect")
end)
lockButton.MouseButton1Click:Connect(function()
	actionRemote:FireServer("lock")
end)
gachaButton.MouseButton1Click:Connect(function()
	actionRemote:FireServer("gacha")
end)

-- Two-tap rebirth: first tap arms for 3 seconds, second tap fires.
local rebirthArmed = false
local rebirthCostNow = 0
rebirthButton.MouseButton1Click:Connect(function()
	if not rebirthArmed then
		rebirthArmed = true
		rebirthButton.Text = "YAKIN? $" .. rebirthCostNow
		rebirthButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
		task.delay(3, function()
			rebirthArmed = false
			rebirthButton.Text = "REBIRTH $" .. rebirthCostNow
			rebirthButton.BackgroundColor3 = Color3.fromRGB(240, 160, 40)
		end)
	else
		rebirthArmed = false
		actionRemote:FireServer("rebirth")
		rebirthButton.BackgroundColor3 = Color3.fromRGB(240, 160, 40)
	end
end)

local toastToken = 0
local function showToast(text)
	toastToken += 1
	local myToken = toastToken
	toastLabel.Text = text
	toastLabel.TextTransparency = 0
	task.delay(3.2, function()
		if toastToken == myToken then
			toastLabel.Text = ""
		end
	end)
end

toastRemote.OnClientEvent:Connect(showToast)

local lastState = nil
stateRemote.OnClientEvent:Connect(function(state)
	lastState = state
	cashLabel.Text = "$" .. state.Cash
	incomeLabel.Text = "+$" .. state.IncomePerSecond .. "/s  (" .. state.Occupied .. "/" .. state.PadsMax .. ")"
	storedLabel.Text = "Tersimpan: $" .. state.Stored
	multLabel.Text = "x" .. string.format("%.2f", state.Multiplier) .. "  Koleksi " .. state.CollectionCount .. "/" .. state.CollectionTotal
	collectButton.Text = "PANEN $" .. state.Stored
	if state.LockedSeconds > 0 then
		lockButton.Text = "TERKUNCI " .. state.LockedSeconds .. "s"
	else
		lockButton.Text = "KUNCI BASE"
	end
	gachaButton.Text = "GACHA $" .. state.GachaCost
	rebirthCostNow = state.RebirthCost
	if not rebirthArmed then
		rebirthButton.Text = "REBIRTH $" .. state.RebirthCost
	end
	if state.TsunamiIn <= 10 then
		tsunamiLabel.Text = "TSUNAMI " .. state.TsunamiIn .. "s — LARI KE BASE!"
		tsunamiLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
	else
		tsunamiLabel.Text = "Tsunami: " .. state.TsunamiIn .. "s"
		tsunamiLabel.TextColor3 = Color3.fromRGB(140, 220, 255)
	end
end)

-- Keyboard shortcuts mirror the buttons: C panen, L kunci, G gacha.
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.C then
		actionRemote:FireServer("collect")
	elseif input.KeyCode == Enum.KeyCode.L then
		actionRemote:FireServer("lock")
	elseif input.KeyCode == Enum.KeyCode.G then
		actionRemote:FireServer("gacha")
	end
end)

-- The last state the server sent, exposed for the collection book's
-- debugging and for any future HUD widget.
function _G.BrainrotHudLastState()
	return lastState
end
