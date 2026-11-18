-- Hud.client.luau
-- Brainrot Bazaar client HUD: cash + income (top centre, clear of the
-- top-left Roblox menu), tsunami countdown, toast notifications, a hint
-- line and the rebirth button (bottom right, two-tap confirm).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = playerGui

local function makeFrame(name: string, anchor: Vector2, position: UDim2, size: UDim2, color: Color3, transparency: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = anchor
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	frame.Parent = gui
	return frame
end

local function makeLabel(parent: Instance, name: string, position: UDim2, size: UDim2, textSize: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.FredokaOne
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.5
	label.Text = ""
	label.Parent = parent
	return label
end

-- Cash panel, top centre.
local cashPanel = makeFrame("CashPanel", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 8), UDim2.fromOffset(360, 76), Color3.fromRGB(25, 28, 38), 0.25)
local cashLabel = makeLabel(cashPanel, "Cash", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.55), 30, Color3.fromRGB(140, 255, 160))
cashLabel.Text = "$0"
local incomeLabel = makeLabel(cashPanel, "Income", UDim2.fromScale(0, 0.55), UDim2.fromScale(1, 0.45), 17, Color3.fromRGB(210, 225, 255))
incomeLabel.Text = "+$0/s"

-- Tsunami countdown, under the cash panel.
local wavePanel = makeFrame("WavePanel", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 92), UDim2.fromOffset(360, 34), Color3.fromRGB(30, 60, 110), 0.3)
local waveLabel = makeLabel(wavePanel, "Wave", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 18, Color3.fromRGB(200, 230, 255))
waveLabel.Text = "🌊 Tsunami: --:--"

-- Toast, bottom centre.
local toastLabel = makeLabel(gui, "Toast", UDim2.new(0.5, 0, 1, -150), UDim2.fromOffset(720, 40), 22, Color3.fromRGB(255, 255, 255))
toastLabel.AnchorPoint = Vector2.new(0.5, 1)
toastLabel.Text = ""

-- Hint line, bottom left.
local hintLabel = makeLabel(gui, "Hint", UDim2.new(0, 12, 1, -12), UDim2.fromOffset(560, 24), 15, Color3.fromRGB(230, 235, 245))
hintLabel.AnchorPoint = Vector2.new(0, 1)
hintLabel.TextXAlignment = Enum.TextXAlignment.Left
hintLabel.Text = "Tekan E di conveyor untuk beli • injak pad hijau di basis untuk ambil cash • kunci basis biar aman dari maling & tsunami"

-- Rebirth button, bottom right.
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.AnchorPoint = Vector2.new(1, 1)
rebirthButton.Position = UDim2.new(1, -14, 1, -14)
rebirthButton.Size = UDim2.fromOffset(230, 66)
rebirthButton.BackgroundColor3 = Color3.fromRGB(140, 60, 220)
rebirthButton.BorderSizePixel = 0
rebirthButton.Font = Enum.Font.FredokaOne
rebirthButton.TextSize = 17
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.TextStrokeTransparency = 0.5
rebirthButton.Text = "♻ REBIRTH"
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = rebirthButton
rebirthButton.Parent = gui

local rebirthCost = 0
local rebirthArmed = false
rebirthButton.MouseButton1Click:Connect(function()
	if not rebirthArmed then
		rebirthArmed = true
		rebirthButton.Text = "YAKIN? Reset semua!\nKlik lagi untuk rebirth"
		task.delay(3, function()
			rebirthArmed = false
		end)
		return
	end
	rebirthArmed = false
	remotes:WaitForChild("RebirthRequest"):FireServer()
end)

-- Remote wiring ---------------------------------------------------------------

local toastToken = 0
remotes:WaitForChild("Notify").OnClientEvent:Connect(function(text: string, kind: string)
	toastToken += 1
	local myToken = toastToken
	toastLabel.Text = text
	if kind == "danger" then
		toastLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	elseif kind == "good" then
		toastLabel.TextColor3 = Color3.fromRGB(150, 255, 170)
	else
		toastLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	task.delay(4.5, function()
		if toastToken == myToken then
			toastLabel.Text = ""
		end
	end)
end)

remotes:WaitForChild("StatsUpdate").OnClientEvent:Connect(function(stats)
	cashLabel.Text = BrainrotData.FormatCash(stats.Cash)
	local line = "+" .. BrainrotData.FormatCash(stats.IncomePerSec) .. "/s"
	if stats.Rebirths > 0 then
		line ..= "  •  ♻ " .. stats.Rebirths .. " (x" .. string.format("%.2f", stats.Multiplier) .. ")"
	end
	if stats.StoredCash > 0 then
		line ..= "  •  di basis: " .. BrainrotData.FormatCash(stats.StoredCash)
	end
	incomeLabel.Text = line
	rebirthCost = stats.RebirthCost
	if not rebirthArmed then
		rebirthButton.Text = "♻ REBIRTH\n" .. BrainrotData.FormatCash(rebirthCost) .. " → x" .. string.format("%.2f", stats.Multiplier + 0.75)
	end
end)

remotes:WaitForChild("WaveUpdate").OnClientEvent:Connect(function(update)
	local seconds = update.SecondsLeft
	if update.Phase == "Sweep" then
		waveLabel.Text = "🌊🌊 TSUNAMI SEDANG LEWAT! 🌊🌊"
		wavePanel.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	elseif update.Phase == "Warning" then
		waveLabel.Text = string.format("⚠ TSUNAMI %d DETIK LAGI! PULANG! ⚠", seconds)
		wavePanel.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	else
		waveLabel.Text = string.format("🌊 Tsunami: %d:%02d", math.floor(seconds / 60), seconds % 60)
		wavePanel.BackgroundColor3 = Color3.fromRGB(30, 60, 110)
	end
end)
