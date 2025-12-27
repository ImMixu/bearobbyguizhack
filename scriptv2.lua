local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")

-- Настройки
local TEAM_NAME = "Survivors" -- Название команды для телепортации
local TELEPORT_DURATION = 4 -- Длительность телепортации в секундах
local BEHIND_OFFSET = 2 -- Расстояние за спиной (установлено в 2 studs для небольшого расстояния)
local HEIGHT_OFFSET = 0 -- Высота относительно игрока
local CLUSTER_SPREAD = 0.5 -- Небольшой разброс для создания "кучки" (случайный offset в пределах 0.5 единиц)

-- Словарь для отслеживания активных телепортаций
local activeTeleportations = {}

-- Функция для получения команды
local function getTeam(teamName)
    for _, team in pairs(Teams:GetTeams()) do
        if team.Name:lower() == teamName:lower() then
            return team
        end
    end
    return nil
end

-- Функция для проверки, может ли игрок телепортировать
local function canPlayerTeleport(player)
    -- Здесь можно добавить дополнительные проверки
    -- Например, проверку на админ права, уровень и т.д.
    return true -- Пока разрешаем всем
end

-- Функция для телепортации за спину
local function teleportBehind(targetPlayer, playerToTeleport)
    if not targetPlayer.Character or not playerToTeleport.Character then
        return false
    end
    
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local playerHRP = playerToTeleport.Character:FindFirstChild("HumanoidRootPart")
    
    if not targetHRP or not playerHRP then
        return false
    end
    
    -- Получаем направление взгляда
    local lookVector = targetHRP.CFrame.LookVector
    local upVector = Vector3.new(0, 1, 0)
    
    -- Вычисляем базовую позицию за спиной
    local behindPosition = targetHRP.Position - (lookVector * BEHIND_OFFSET)
    behindPosition = behindPosition + (upVector * HEIGHT_OFFSET)
    
    -- Добавляем небольшой случайный разброс для создания "кучки"
    local randomOffset = Vector3.new(
        (math.random() - 0.5) * CLUSTER_SPREAD * 2,
        0,
        (math.random() - 0.5) * CLUSTER_SPREAD * 2
    )
    behindPosition = behindPosition + randomOffset
    
    -- Проверяем, не занято ли место
    local rayOrigin = behindPosition + Vector3.new(0, 5, 0)
    local rayDirection = Vector3.new(0, -10, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {targetPlayer.Character, playerToTeleport.Character}
    
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if rayResult then
        behindPosition = rayResult.Position + Vector3.new(0, 3, 0)
    end
    
    -- Телепортируем
    playerHRP.CFrame = CFrame.new(behindPosition, behindPosition + lookVector)
    
    -- Визуальный эффект (опционально)
    spawn(function()
        local teleportEffect = Instance.new("Part")
        teleportEffect.Size = Vector3.new(2, 0.1, 2)
        teleportEffect.Position = behindPosition
        teleportEffect.Anchored = true
        teleportEffect.CanCollide = false
        teleportEffect.Transparency = 0.5
        teleportEffect.Color = Color3.fromRGB(0, 170, 255)
        teleportEffect.Material = Enum.Material.Neon
        teleportEffect.Parent = workspace
        
        game:GetService("TweenService"):Create(
            teleportEffect,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 1, Size = Vector3.new(4, 0.1, 4)}
        ):Play()
        
        wait(0.5)
        teleportEffect:Destroy()
    end)
    
    return true
end

-- Основная функция телепортации
local function startMassTeleport(instigatorPlayer)
    -- Проверяем, может ли игрок телепортировать
    if not canPlayerTeleport(instigatorPlayer) then
        instigatorPlayer:SetAttribute("LastTeleportMessage", "У вас нет прав для телепортации!")
        return
    end
    
    -- Проверяем, не активна ли уже телепортация
    if activeTeleportations[instigatorPlayer.UserId] then
        instigatorPlayer:SetAttribute("LastTeleportMessage", "Телепортация уже активна!")
        return
    end
    
    local survivorsTeam = getTeam(TEAM_NAME)
    if not survivorsTeam then
        instigatorPlayer:SetAttribute("LastTeleportMessage", "Команда '" .. TEAM_NAME .. "' не найдена!")
        return
    end
    
    -- Получаем всех игроков в команде Survivors
    local playersToTeleport = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team == survivorsTeam and player ~= instigatorPlayer then
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                table.insert(playersToTeleport, player)
            end
        end
    end
    
    if #playersToTeleport == 0 then
        instigatorPlayer:SetAttribute("LastTeleportMessage", "Нет игроков для телепортации!")
        return
    end
    
    -- Помечаем телепортацию как активную
    activeTeleportations[instigatorPlayer.UserId] = true
    
    -- Уведомление игроку
    instigatorPlayer:SetAttribute("LastTeleportMessage", "Телепортирую " .. #playersToTeleport .. " игроков!")
    
    -- Запускаем телепортацию
    local startTime = tick()
    local connection
    
    connection = RunService.Heartbeat:Connect(function()
        -- Проверяем время
        if tick() - startTime >= TELEPORT_DURATION then
            connection:Disconnect()
            activeTeleportations[instigatorPlayer.UserId] = nil
            instigatorPlayer:SetAttribute("LastTeleportMessage", "Телепортация завершена!")
            return
        end
        
        -- Проверяем, жив ли инициатор
        if not instigatorPlayer.Character or not instigatorPlayer.Character:FindFirstChild("HumanoidRootPart") then
            connection:Disconnect()
            activeTeleportations[instigatorPlayer.UserId] = nil
            return
        end
        
        -- Телепортируем каждого игрока
        for _, player in pairs(playersToTeleport) do
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                teleportBehind(instigatorPlayer, player)
            end
        end
    end)
    
    -- Автоматическое отключение через заданное время
    delay(TELEPORT_DURATION, function()
        if connection and connection.Connected then
            connection:Disconnect()
        end
        activeTeleportations[instigatorPlayer.UserId] = nil
    end)
end

-- Настройка команды чата для телепортации
local function setupChatCommand()
    local function onPlayerChatted(player, message)
        -- Команда для телепортации (можно изменить)
        if message:lower() == "/tpbehind" or message:lower() == "!teleport" then
            startMassTeleport(player)
        end
    end
    
    -- Обработчик для новых игроков
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            onPlayerChatted(player, message)
        end)
    end)
    
    -- Для уже подключенных игроков
    for _, player in pairs(Players:GetPlayers()) do
        player.Chatted:Connect(function(message)
            onPlayerChatted(player, message)
        end)
    end
end

-- GUI для кнопки телепортации (опционально)
local function createTeleportGUI(player)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleportGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 50)
    frame.Position = UDim2.new(0.5, -100, 0.9, -25)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 1, -20)
    button.Position = UDim2.new(0, 10, 0, 10)
    button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = "Телепортировать игроков"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.Parent = frame
    
    local cooldown = false
    
    button.MouseButton1Click:Connect(function()
        if not cooldown then
            startMassTeleport(player)
            cooldown = true
            button.Text = "whatthefuck"
            button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            
            wait(TELEPORT_DURATION + 5) -- 5 секунд дополнительной перезарядки
            
            cooldown = false
            button.Text = "idkwhatthissays"
            button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        end
    end)
    
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, 0, 0, 30)
    messageLabel.Position = UDim2.new(0, 0, -1, -5)
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.Text = ""
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 12
    messageLabel.Parent = frame
    while screenGui.Parent do
        local message = player:GetAttribute("LastTeleportMessage") or ""
        messageLabel.Text = message
        wait(0.1)
    end
end


setupChatCommand()


Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Wait()
    createTeleportGUI(player)
end)


for _, player in pairs(Players:GetPlayers()) do
    if player.Character then
        createTeleportGUI(player)
    end
end


return {
    startMassTeleport = startMassTeleport,
    teleportBehind = teleportBehind,
    

    settings = {
        TeamName = TEAM_NAME,
        Duration = TELEPORT_DURATION,
        Offset = BEHIND_OFFSET,
        ClusterSpread = CLUSTER_SPREAD
    }
}
