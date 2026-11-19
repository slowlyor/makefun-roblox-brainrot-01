-- Hud.client.luau
-- The Brainrot Bazaar HUD: a cash / income / stored panel (kept clear of
-- the top-left corner, where Roblox's own menu buttons sit), a tsunami
-- countdown that turns into a red warning, a toast line, a gacha button
-- and the two-tap rebirth button (first tap arms it, second confirms --
-- rebirth wipes your base, so it must never fire on a stray click).
--
-- The HUD only displays state and sends intents; every number it shows
-- came from a server snapshot and every action is re-checked server-side.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local actionRemote = remotes:WaitForChild("Action")
local stateRemote = remotes:WaitForChild("State")
local toastRemote = remotes:WaitForChild("Toast")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local function label(parent: Instance, name: string, pos: UDim2, size: UDim2, text: string, color: Color3, textSize: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = pos
	l.Size = size
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextSize = textSize
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.4
	l.Text = text
	l.Parent = parent
	return l
end

local function panel(parent: Instance, name: string, pos: UDim2, size: UDim2, color: Color3): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Position = pos
	f.Size = size
	f.BackgroundColor3 = color
	f.BackgroundTransparency = 0.25
	f.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = f
	f.Parent = parent
	return f
end

-- Stats panel: top-centre, safely right of the Roblox menu corner.
local stats = panel(gui, "StatsPanel", UDim2.new(0.5, -190, 0, 12), UDim2.new(0, 380, 0, 86), Color3.fromRGB(30, 32, 45))
local cashLabel = label(stats, "Cash", UDim2.new(0, 14, 0, 4), UDim2.new(1, -28, 0, 34), "Uang: $150", Color3.fromRGB(120, 255, 140), 26)
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
local incomeLabel = label(stats, "Income", UDim2.new(0, 14, 0, 40), UDim2.new(0.5, -14, 0, 22), "Penghasilan: $0/dtk", Color3.fromRGB(255, 230, 130), 16)
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
local storedLabel = label(stats, "Stored", UDim2.new(0.5, 0, 0, 40), UDim2.new(0.5, -14, 0, 22), "Tersimpan: $0", Color3.fromRGB(140, 220, 255), 16)
storedLabel.TextXAlignment = Enum.TextXAlignment.Left
local multLabel = label(stats, "Multiplier", UDim2.new(0, 14, 0, 62), UDim2.new(1, -28, 0, 20), "Pengali: x1.00 - Rebirth: 0", Color3.fromRGB(255, 170, 220), 14)
multLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Tsunami countdown under the stats panel.
local tsunamiLabel = label(gui, "Tsunami", UDim2.new(0.5, -150, 0, 106), UDim2.new(0, 300, 0, 28), "Tsunami: 180 dtk", Color3.fromRGB(255, 255, 255), 20)

-- Toast line: server messages (buys, thefts, warnings) land here.
local toastLabel = label(gui, "Toast", UDim2.new(0.5, -320, 1, -120), UDim2.new(0, 640, 0, 34), "", Color3.fromRGB(255, 255, 160), 22)
local toastToken = 0
toastRemote.OnClientEvent:Connect(function(text: string)
	toastToken += 1
	local my = toastToken
	toastLabel.Text = text
	task.delay(3.5, function()
		if toastToken == my then
			toastLabel.Text = ""
		end
	end)
end)

-- Buttons -----------------------------------------------------------------
local function button(name: string, pos: UDim2, size: UDim2, text: string, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = pos
	b.Size = size
	b.BackgroundColor3 = color
	b.BackgroundTransparency = 0.1
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 18
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.TextStrokeTransparency = 0.5
	b.Text = text
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = b
	b.Parent = gui
	return b
end

local collectButton = button("CollectButton", UDim2.new(1, -190, 1, -170), UDim2.new(0, 176, 0, 52), "PANEN UANG", Color3.fromRGB(46, 180, 100))
collectButton.Activated:Connect(function()
	actionRemote:FireServer("collect")
end)

local gachaButton = button("GachaButton", UDim2.new(1, -190, 1, -108), UDim2.new(0, 176, 0, 52), "GACHA $500", Color3.fromRGB(230, 80, 140))
gachaButton.Activated:Connect(function()
	actionRemote:FireServer("gacha")
end)

local lockButton = button("LockButton", UDim2.new(0, 14, 1, -108), UDim2.new(0, 176, 0, 52), "KUNCI BASE", Color3.fromRGB(90, 120, 220))
lockButton.Activated:Connect(function()
	actionRemote:FireServer("lock")
end)

-- Two-tap rebirth: first tap arms for 3 seconds, second tap confirms.
local rebirthButton = button("RebirthButton", UDim2.new(0, 14, 1, -170), UDim2.new(0, 176, 0, 52), "REBIRTH", Color3.fromRGB(150, 80, 220))
local rebirthArmed = false
local rebirthCost = 0
rebirthButton.Activated:Connect(function()
	if not rebirthArmed then
		rebirthArmed = true
		rebirthButton.Text = "YAKIN? KETUK LAGI!"
		rebirthButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
		task.delay(3, function()
			rebirthArmed = false
			rebirthButton.Text = "REBIRTH " .. BrainrotData.formatMoney(rebirthCost)
			rebirthButton.BackgroundColor3 = Color3.fromRGB(150, 80, 220)
		end)
	else
		rebirthArmed = false
		actionRemote:FireServer("rebirth")
		rebirthButton.BackgroundColor3 = Color3.fromRGB(150, 80, 220)
	end
end)

-- A small "how to play" strip at the bottom centre, so a first-time
-- player learns the loop from the screen itself: buy on the belt, the
-- brainrot walks home, stand on the green pad to harvest.
label(gui, "HowTo", UDim2.new(0.5, -330, 1, -34), UDim2.new(0, 660, 0, 22), "Beli brainrot di conveyor - dia jalan ke base-mu - injak pad hijau untuk panen!", Color3.fromRGB(255, 255, 255), 15)

-- State snapshots ---------------------------------------------------------
stateRemote.OnClientEvent:Connect(function(snap)
	cashLabel.Text = "Uang: " .. BrainrotData.formatMoney(snap.cash)
	incomeLabel.Text = "Penghasilan: " .. BrainrotData.formatMoney(snap.income) .. "/dtk"
	storedLabel.Text = "Tersimpan: " .. BrainrotData.formatMoney(snap.stored)
	multLabel.Text = string.format("Pengali: x%.2f - Rebirth: %d - Base %d", snap.multiplier, snap.rebirths, snap.plotIndex)
	gachaButton.Text = "GACHA " .. BrainrotData.formatMoney(snap.gachaCost)
	rebirthCost = snap.rebirthCost
	if not rebirthArmed then
		rebirthButton.Text = "REBIRTH " .. BrainrotData.formatMoney(snap.rebirthCost)
	end
	if snap.lockLeft > 0 then
		lockButton.Text = "TERKUNCI " .. snap.lockLeft .. " dtk"
	else
		lockButton.Text = "KUNCI BASE"
	end
	if snap.tsunamiWarning then
		tsunamiLabel.Text = "TSUNAMI " .. snap.tsunamiIn .. " DTK - LARI KE BASE!"
		tsunamiLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	else
		tsunamiLabel.Text = "Tsunami: " .. snap.tsunamiIn .. " dtk"
		tsunamiLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end)
