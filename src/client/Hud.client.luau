-- Hud.client.luau
-- The Brainrot Bazaar HUD: a ScreenGui with the player's cash, income per
-- second, cash stored at their base, a tsunami countdown, a toast area and
-- the rebirth button. The server pushes a fresh stat table every second via
-- the Stats remote; toasts arrive on their own remote; rebirth is a
-- RemoteFunction guarded by a two-tap confirm on this client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local statsEvent = remotes:WaitForChild("Stats")
local toastEvent = remotes:WaitForChild("Toast")
local rebirthEvent = remotes:WaitForChild("Rebirth")

local function formatCash(amount)
	amount = math.floor(amount)
	if amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	end
	return tostring(amount)
end

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local function makeLabel(name, position, size, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = ""
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	return label
end

-- Top-left stat stack.
local cashLabel = makeLabel("Cash", UDim2.fromOffset(12, 12), UDim2.fromOffset(280, 40), 22, Color3.fromRGB(120, 255, 140))
local incomeLabel = makeLabel("Income", UDim2.fromOffset(12, 58), UDim2.fromOffset(280, 32), 17)
local storedLabel = makeLabel("Stored", UDim2.fromOffset(12, 96), UDim2.fromOffset(280, 32), 17, Color3.fromRGB(140, 220, 255))

-- Tsunami countdown, top centre.
local tsunamiLabel = makeLabel("Tsunami", UDim2.new(0.5, -160, 0, 12), UDim2.fromOffset(320, 40), 20, Color3.fromRGB(255, 210, 90))
tsunamiLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Toast area, centre screen.
local toastLabel = makeLabel("Toast", UDim2.new(0.5, -260, 0.28, 0), UDim2.fromOffset(520, 52), 24, Color3.fromRGB(255, 240, 180))
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.BackgroundTransparency = 1
toastLabel.Visible = false

-- Rebirth button, bottom right.
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.AnchorPoint = Vector2.new(1, 1)
rebirthButton.Position = UDim2.new(1, -12, 1, -12)
rebirthButton.Size = UDim2.fromOffset(300, 64)
rebirthButton.BackgroundColor3 = Color3.fromRGB(140, 60, 220)
rebirthButton.TextColor3 = Color3.new(1, 1, 1)
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.TextSize = 18
rebirthButton.Text = "REBIRTH"
rebirthButton.Parent = gui
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = rebirthButton

-- Toasts ---------------------------------------------------------------------

local toastToken = 0
local function showToast(text, duration)
	toastToken += 1
	local myToken = toastToken
	toastLabel.Text = text
	toastLabel.Visible = true
	task.delay(duration or 3, function()
		if toastToken == myToken then
			toastLabel.Visible = false
		end
	end)
end

toastEvent.OnClientEvent:Connect(showToast)

-- Stats ----------------------------------------------------------------------

local lastStats = nil
local rebirthArmed = false
local rebirthArmToken = 0

local function refreshRebirthButton()
	if not lastStats then
		rebirthButton.Text = "REBIRTH"
		return
	end
	if rebirthArmed then
		rebirthButton.Text = string.format(
			"KETUK LAGI! $%s → pengali x%.2f",
			formatCash(lastStats.RebirthCost),
			lastStats.Multiplier + 0.75
		)
	else
		rebirthButton.Text = string.format(
			"REBIRTH $%s (pengali x%.2f)",
			formatCash(lastStats.RebirthCost),
			lastStats.Multiplier + 0.75
		)
	end
end

statsEvent.OnClientEvent:Connect(function(stats)
	lastStats = stats
	cashLabel.Text = "  $ " .. formatCash(stats.Cash)
	incomeLabel.Text = string.format("  Pendapatan: $%s/s (x%.2f)", formatCash(stats.Income), stats.Multiplier)
	storedLabel.Text = "  Di base: $" .. formatCash(stats.Stored) .. " (injak pad hijau)"
	if stats.TsunamiActive then
		tsunamiLabel.Text = "TSUNAMI DATANG!"
		tsunamiLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	elseif stats.TsunamiIn <= 10 then
		tsunamiLabel.Text = string.format("TSUNAMI DALAM %d DETIK!", stats.TsunamiIn)
		tsunamiLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	else
		tsunamiLabel.Text = "Tsunami: " .. stats.TsunamiIn .. " dtk"
		tsunamiLabel.TextColor3 = Color3.fromRGB(255, 210, 90)
	end
	refreshRebirthButton()
end)

-- Rebirth: first tap arms and shows the price, second tap confirms. The arm
-- expires after four seconds so an old tap never fires a surprise rebirth.
rebirthButton.Activated:Connect(function()
	if not lastStats then
		return
	end
	if not rebirthArmed then
		rebirthArmed = true
		rebirthArmToken += 1
		local token = rebirthArmToken
		refreshRebirthButton()
		showToast(string.format("Rebirth: $%s, brainrot hilang, pengali naik. Ketuk tombol lagi!", formatCash(lastStats.RebirthCost)), 4)
		task.delay(4, function()
			if rebirthArmToken == token then
				rebirthArmed = false
				refreshRebirthButton()
			end
		end)
		return
	end
	rebirthArmed = false
	refreshRebirthButton()
	local ok, message = rebirthEvent:InvokeServer()
	showToast(message or (ok and "Rebirth berhasil!" or "Rebirth gagal"), 4)
end)
