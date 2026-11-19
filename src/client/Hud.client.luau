-- Hud.client.luau -- the Brainrot Bazaar heads-up display.
-- Top-right money panel (kept clear of Roblox's top-left menu buttons),
-- a tsunami countdown banner, toast messages, and the two-tap rebirth
-- button. All numbers arrive from the server's StateSync remote.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local stateSync = remotes:WaitForChild("StateSync")
local toastRemote = remotes:WaitForChild("Toast")
local rebirthRequest = remotes:WaitForChild("RebirthRequest")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(parent, name, pos, size, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = pos
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = ""
	label.Parent = parent
	return label
end

-- Money panel, top-right.
local panel = Instance.new("Frame")
panel.Name = "MoneyPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -12, 0, 12)
panel.Size = UDim2.fromOffset(280, 132)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
panel.BackgroundTransparency = 0.25
panel.BorderSizePixel = 0
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local cashLabel = makeLabel(panel, "Cash", UDim2.fromOffset(14, 8), UDim2.fromOffset(252, 30), 24, Color3.fromRGB(140, 255, 140))
local incomeLabel = makeLabel(panel, "Income", UDim2.fromOffset(14, 42), UDim2.fromOffset(252, 24), 18)
local storedLabel = makeLabel(panel, "Stored", UDim2.fromOffset(14, 68), UDim2.fromOffset(252, 24), 18, Color3.fromRGB(160, 220, 255))
local multLabel = makeLabel(panel, "Multiplier", UDim2.fromOffset(14, 94), UDim2.fromOffset(252, 24), 18, Color3.fromRGB(255, 220, 120))
cashLabel.Text = "Uang: $150"
incomeLabel.Text = "Penghasilan: $0/dtk"
storedLabel.Text = "Simpanan di pad: $0"
multLabel.Text = "Rebirth: 0 (x1.00)"

-- Tsunami countdown banner, top-centre.
local tsunamiLabel = makeLabel(gui, "TsunamiCountdown", UDim2.new(0.5, -160, 0, 14), UDim2.fromOffset(320, 34), 22, Color3.fromRGB(120, 210, 255))
tsunamiLabel.TextXAlignment = Enum.TextXAlignment.Center
tsunamiLabel.Text = "Tsunami: 180 dtk"

-- Toast line, bottom-centre.
local toastLabel = makeLabel(gui, "Toast", UDim2.new(0.5, -300, 1, -120), UDim2.fromOffset(600, 36), 22, Color3.fromRGB(255, 240, 160))
toastLabel.TextXAlignment = Enum.TextXAlignment.Center

-- A small hint line under the money panel: how the loop works, for a
-- first-time player reading the screen in the thumbnail moment.
local hintLabel = makeLabel(panel, "Hint", UDim2.fromOffset(14, 118), UDim2.fromOffset(252, 14), 12, Color3.fromRGB(200, 200, 210))
hintLabel.Text = "Beli dari sabuk - panen di pad hijau - kunci basis!"

local toastToken = 0
local function showToast(text)
	toastToken += 1
	local myToken = toastToken
	toastLabel.Text = text
	toastLabel.TextTransparency = 0
	task.spawn(function()
		task.wait(3.6)
		if toastToken == myToken then
			toastLabel.TextTransparency = 1
		end
	end)
end
toastRemote.OnClientEvent:Connect(showToast)

-- Rebirth button, bottom-right: first tap arms it, second tap within
-- 3 seconds actually fires the request to the server.
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.AnchorPoint = Vector2.new(1, 1)
rebirthButton.Position = UDim2.new(1, -12, 1, -12)
rebirthButton.Size = UDim2.fromOffset(230, 56)
rebirthButton.BackgroundColor3 = Color3.fromRGB(150, 60, 220)
rebirthButton.TextColor3 = Color3.new(1, 1, 1)
rebirthButton.Font = Enum.Font.FredokaOne
rebirthButton.TextSize = 19
rebirthButton.Text = "REBIRTH"
rebirthButton.Parent = gui
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = rebirthButton

local armed = false
local lastSnapshot = nil
rebirthButton.MouseButton1Click:Connect(function()
	if not lastSnapshot then
		return
	end
	if not armed then
		armed = true
		rebirthButton.Text = "YAKIN? KETUK LAGI! " .. BrainrotData.FormatMoney(lastSnapshot.RebirthCost)
		rebirthButton.BackgroundColor3 = Color3.fromRGB(230, 60, 60)
		task.delay(3, function()
			armed = false
			rebirthButton.BackgroundColor3 = Color3.fromRGB(150, 60, 220)
			if lastSnapshot then
				rebirthButton.Text = "REBIRTH " .. BrainrotData.FormatMoney(lastSnapshot.RebirthCost)
			end
		end)
	else
		armed = false
		rebirthButton.BackgroundColor3 = Color3.fromRGB(150, 60, 220)
		rebirthRequest:FireServer()
	end
end)

stateSync.OnClientEvent:Connect(function(snapshot)
	lastSnapshot = snapshot
	cashLabel.Text = "Uang: " .. BrainrotData.FormatMoney(snapshot.Cash)
	incomeLabel.Text = "Penghasilan: " .. BrainrotData.FormatMoney(snapshot.IncomePerSecond) .. "/dtk"
	storedLabel.Text = "Simpanan di pad: " .. BrainrotData.FormatMoney(snapshot.Stored)
		.. "  (pad " .. snapshot.PadsUsed .. "/6)"
	multLabel.Text = string.format("Rebirth: %d (x%.2f)", snapshot.Rebirths, snapshot.Multiplier)
	if not armed then
		rebirthButton.Text = "REBIRTH " .. BrainrotData.FormatMoney(snapshot.RebirthCost)
	end
	if snapshot.LockLeft > 0 then
		tsunamiLabel.Text = "Basis terkunci: " .. snapshot.LockLeft .. " dtk   |   Tsunami: " .. snapshot.TsunamiIn .. " dtk"
	else
		tsunamiLabel.Text = "Tsunami: " .. snapshot.TsunamiIn .. " dtk   |   Pencuri: " .. snapshot.ThiefIn .. " dtk"
	end
	tsunamiLabel.TextColor3 = (snapshot.TsunamiIn <= 10)
		and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(120, 210, 255)
end)
