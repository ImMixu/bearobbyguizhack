--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
-- LocalScript in StarterGui or StarterPlayerScripts
local player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Settings
local TELEPORT_COORDS = Vector3.new(407.5, 29.999954223632812, -27.5)
local TELEPORT_INTERVAL = 0 -- 100 ms

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportGUI"
screenGui.ResetOnSpawn = false

-- Main frame (draggable) - positioned at top center
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 110) -- Smaller height since we removed coordinates
mainFrame.Position = UDim2.new(0.5, -100, 0, 20) -- Center horizontally
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.BackgroundTransparency = 0.15

-- Add rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Title bar (for dragging)
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
titleBar.BorderSizePixel = 0
titleBar.BackgroundTransparency = 0.1

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 10)
titleBarCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, -10, 1, 0)
titleText.Position = UDim2.new(0, 5, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "🚀 TELEPORT TOOL"
titleText.TextColor3 = Color3.fromRGB(220, 220, 255)
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 18
titleText.TextXAlignment = Enum.TextXAlignment.Left

-- Start Button
local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(0.45, 0, 0, 36)
startButton.Position = UDim2.new(0.03, 0, 0.4, 0)
startButton.BackgroundColor3 = Color3.fromRGB(65, 195, 65)
startButton.Text = "▶ START"
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.Font = Enum.Font.SourceSansBold
startButton.TextSize = 16

-- Rounded corners for buttons
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)

local startButtonCorner = buttonCorner:Clone()
startButtonCorner.Parent = startButton

-- Stop Button
local stopButton = Instance.new("TextButton")
stopButton.Name = "StopButton"
stopButton.Size = UDim2.new(0.45, 0, 0, 36)
stopButton.Position = UDim2.new(0.52, 0, 0.4, 0)
stopButton.BackgroundColor3 = Color3.fromRGB(195, 65, 65)
stopButton.Text = "⏹ STOP"
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.Font = Enum.Font.SourceSansBold
stopButton.TextSize = 16

local stopButtonCorner = buttonCorner:Clone()
stopButtonCorner.Parent = stopButton

-- Status indicator
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -10, 0, 22)
statusLabel.Position = UDim2.new(0, 5, 1, -28)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: INACTIVE"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.SourceSansSemibold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Assemble GUI
titleText.Parent = titleBar
titleBar.Parent = mainFrame
startButton.Parent = mainFrame
stopButton.Parent = mainFrame
statusLabel.Parent = mainFrame
mainFrame.Parent = screenGui
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Teleportation variables
local isTeleporting = false
local teleportConnection = nil
local lastTeleportTime = 0

-- Teleport function
local function teleportPlayer()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(TELEPORT_COORDS)
    end
end

-- Status update function
local function updateStatus()
    if isTeleporting then
        statusLabel.Text = "Status: ACTIVE"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        statusLabel.Text = "Status: INACTIVE"
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

-- Start teleportation function
local function startTeleportation()
    if isTeleporting then return end
    
    isTeleporting = true
    startButton.BackgroundColor3 = Color3.fromRGB(45, 155, 45)
    stopButton.BackgroundColor3 = Color3.fromRGB(195, 65, 65)
    
    print("Teleportation started")
    updateStatus()
    
    -- Start teleportation every 100 ms
    teleportConnection = RunService.Heartbeat:Connect(function(deltaTime)
        local currentTime = tick()
        if currentTime - lastTeleportTime >= TELEPORT_INTERVAL then
            teleportPlayer()
            lastTeleportTime = currentTime
        end
    end)
end

-- Stop teleportation function
local function stopTeleportation()
    if not isTeleporting then return end
    
    isTeleporting = false
    startButton.BackgroundColor3 = Color3.fromRGB(65, 195, 65)
    stopButton.BackgroundColor3 = Color3.fromRGB(155, 45, 45)
    
    print("Teleportation stopped")
    updateStatus()
    
    if teleportConnection then
        teleportConnection:Disconnect()
        teleportConnection = nil
    end
end

-- Button click handlers
startButton.MouseButton1Click:Connect(startTeleportation)
stopButton.MouseButton1Click:Connect(stopTeleportation)

-- Button hover effects
startButton.MouseEnter:Connect(function()
    if not isTeleporting then
        startButton.BackgroundColor3 = Color3.fromRGB(75, 215, 75)
    end
end)

startButton.MouseLeave:Connect(function()
    if not isTeleporting then
        startButton.BackgroundColor3 = Color3.fromRGB(65, 195, 65)
    else
        startButton.BackgroundColor3 = Color3.fromRGB(45, 155, 45)
    end
end)

stopButton.MouseEnter:Connect(function()
    stopButton.BackgroundColor3 = Color3.fromRGB(215, 75, 75)
end)

stopButton.MouseLeave:Connect(function()
    if isTeleporting then
        stopButton.BackgroundColor3 = Color3.fromRGB(195, 65, 65)
    else
        stopButton.BackgroundColor3 = Color3.fromRGB(155, 45, 45)
    end
end)

-- Window dragging functionality
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
                                   startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Stop teleportation on character reload
player.CharacterAdded:Connect(function()
    stopTeleportation()
end)

player.CharacterRemoving:Connect(function()
    stopTeleportation()
end)

-- Initialize with teleportation stopped
stopTeleportation()
updateStatus()

-- Add toggle visibility with F9 key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.F9 then
            mainFrame.Visible = not mainFrame.Visible
        end
    end
end)

-- Make window return to top center when double-clicking title bar
local lastClickTime = 0
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local currentTime = tick()
        if currentTime - lastClickTime < 0.3 then -- Double click within 300ms
            mainFrame.Position = UDim2.new(0.5, -100, 0, 20) -- Return to top center
        end
        lastClickTime = currentTime
    end
end)
