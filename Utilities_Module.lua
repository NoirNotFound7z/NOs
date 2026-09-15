local Utilities = {}

local LocalPlayer = game:GetService("Players").LocalPlayer
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- ==========================================================
-- STATE - MINIMAP
-- ==========================================================
Utilities.Zoom = 5
local MapGui, MapFrame, InfoPanel = nil, nil, nil
local MapObjects = {}
local MapEnabled = false
local RenderConnection = nil
local SmoothYaw = 0
local CurrentTarget = nil
local TPMode = false

-- ==========================================================
-- STATE - VHS
-- ==========================================================
_G.VHS_Control = nil
_G.VHS_Ready = false
_G.VHS_ToggleVisible = false
local vhsButtonVisible = false

-- ==========================================================
-- STATE - CAMERA
-- ==========================================================
local thirdPersonEnabled = false
local thirdPersonLoop = nil
local camLocked = false
local savedCFrame = nil
local camConn = nil

-- ==========================================================
-- MINIMAP FUNCTIONS
-- ==========================================================
local function createMap()
    MapGui = Instance.new("ScreenGui")
    MapGui.IgnoreGuiInset = true
    MapGui.ResetOnSpawn = false
    MapGui.Parent = CoreGui
    
    MapFrame = Instance.new("Frame")
    MapFrame.Size = UDim2.new(0, 150, 0, 150)
    MapFrame.Position = UDim2.new(1, -160, 0, 10)
    MapFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MapFrame.BackgroundTransparency = 0.4
    MapFrame.BorderSizePixel = 0
    MapFrame.ClipsDescendants = true
    MapFrame.Parent = MapGui
    Instance.new("UICorner", MapFrame)
    
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0, 150, 0, 30)
    tpBtn.Position = UDim2.new(1, -160, 0, 165)
    tpBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tpBtn.TextColor3 = Color3.new(1, 1, 1)
    tpBtn.Text = "TP: OFF"
    tpBtn.Parent = MapGui
    Instance.new("UICorner", tpBtn)
    
    tpBtn.MouseButton1Click:Connect(function()
        TPMode = not TPMode
        tpBtn.Text = TPMode and "TP: ON" or "TP: OFF"
    end)
    
    InfoPanel = Instance.new("Frame")
    InfoPanel.Size = UDim2.new(0, 320, 0, 145)
    InfoPanel.Position = UDim2.new(1, -520, 0, 10)
    InfoPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    InfoPanel.BackgroundTransparency = 0.05
    InfoPanel.BorderSizePixel = 0
    InfoPanel.Visible = false
    InfoPanel.Parent = MapGui
    Instance.new("UICorner", InfoPanel).CornerRadius = UDim.new(0, 12)
    
    local stroke = Instance.new("UIStroke")
    stroke.Parent = InfoPanel
    stroke.Color = Color3.fromRGB(60, 60, 80)
    stroke.Thickness = 1
    
    local padding = Instance.new("Frame")
    padding.Name = "Padding"
    padding.Size = UDim2.new(1, -20, 1, -20)
    padding.Position = UDim2.new(0, 10, 0, 10)
    padding.BackgroundTransparency = 1
    padding.Parent = InfoPanel
    
    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.Size = UDim2.new(0, 50, 0, 50)
    avatar.Position = UDim2.new(0, 0, 0, 0)
    avatar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    avatar.BackgroundTransparency = 0.2
    avatar.BorderSizePixel = 0
    avatar.Parent = padding
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
    
    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Parent = avatar
    avatarStroke.Color = Color3.fromRGB(138, 116, 249)
    avatarStroke.Thickness = 2
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "PlayerName"
    nameLabel.Size = UDim2.new(1, -60, 0, 25)
    nameLabel.Position = UDim2.new(0, 60, 0, -2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextSize = 16
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = padding
    
    local usernameLabel = Instance.new("TextLabel")
    usernameLabel.Name = "Username"
    usernameLabel.Size = UDim2.new(1, -60, 0, 16)
    usernameLabel.Position = UDim2.new(0, 60, 0, 22)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.Font = Enum.Font.Gotham
    usernameLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
    usernameLabel.TextSize = 12
    usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    usernameLabel.Parent = padding
    
    local hpBarBg = Instance.new("Frame")
    hpBarBg.Name = "HpBarBg"
    hpBarBg.Size = UDim2.new(1, -60, 0, 10)
    hpBarBg.Position = UDim2.new(0, 60, 0, 48)
    hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    hpBarBg.BorderSizePixel = 0
    hpBarBg.Parent = padding
    Instance.new("UICorner", hpBarBg).CornerRadius = UDim.new(1, 0)
    
    local hpBar = Instance.new("Frame")
    hpBar.Name = "HpBar"
    hpBar.Size = UDim2.new(1, 0, 1, 0)
    hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    hpBar.BorderSizePixel = 0
    hpBar.Parent = hpBarBg
    Instance.new("UICorner", hpBar).CornerRadius = UDim.new(1, 0)
    
    local hpText = Instance.new("TextLabel")
    hpText.Name = "HP"
    hpText.Size = UDim2.new(0.5, 0, 0, 16)
    hpText.Position = UDim2.new(0, 60, 0, 66)
    hpText.BackgroundTransparency = 1
    hpText.Font = Enum.Font.Gotham
    hpText.TextColor3 = Color3.fromRGB(200, 200, 200)
    hpText.TextSize = 12
    hpText.TextXAlignment = Enum.TextXAlignment.Left
    hpText.Parent = padding
    
    local dist = Instance.new("TextLabel")
    dist.Name = "Distance"
    dist.Size = UDim2.new(0.5, 0, 0, 16)
    dist.Position = UDim2.new(0, 60, 0, 84)
    dist.BackgroundTransparency = 1
    dist.Font = Enum.Font.Gotham
    dist.TextColor3 = Color3.fromRGB(255, 215, 0)
    dist.TextSize = 12
    dist.TextXAlignment = Enum.TextXAlignment.Left
    dist.Parent = padding
    
    local speedText = Instance.new("TextLabel")
    speedText.Name = "Speed"
    speedText.Size = UDim2.new(0.5, -60, 0, 16)
    speedText.Position = UDim2.new(0.5, 0, 0, 66)
    speedText.BackgroundTransparency = 1
    speedText.Font = Enum.Font.Gotham
    speedText.TextColor3 = Color3.fromRGB(100, 200, 255)
    speedText.TextSize = 12
    speedText.TextXAlignment = Enum.TextXAlignment.Right
    speedText.Parent = padding
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "Status"
    statusText.Size = UDim2.new(0.5, -60, 0, 16)
    statusText.Position = UDim2.new(0.5, 0, 0, 84)
    statusText.BackgroundTransparency = 1
    statusText.Font = Enum.Font.Gotham
    statusText.TextColor3 = Color3.fromRGB(180, 255, 180)
    statusText.TextSize = 12
    statusText.TextXAlignment = Enum.TextXAlignment.Right
    statusText.Parent = padding
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 10)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.TextSize = 16
    closeBtn.Parent = InfoPanel
    
    closeBtn.MouseButton1Click:Connect(function()
        CurrentTarget = nil
        InfoPanel.Visible = false
    end)
end

local function createDot(player)
    if MapObjects[player] then return end
    
    local dot = Instance.new("ImageButton")
    dot.Size = UDim2.new(0, 20, 0, 20)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.BackgroundTransparency = 1
    dot.Parent = MapFrame
    dot.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
    Instance.new("UICorner", dot)
    
    dot.MouseButton1Click:Connect(function()
        if TPMode then
            local myChar = LocalPlayer.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if myHRP and hrp then
                myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
            end
            return
        end
        
        if CurrentTarget == player then
            CurrentTarget = nil
            InfoPanel.Visible = false
        else
            CurrentTarget = player
            InfoPanel.Visible = true
            local padding = InfoPanel:FindFirstChild("Padding")
            if padding then
                local nameLabel = padding:FindFirstChild("PlayerName")
                local usernameLabel = padding:FindFirstChild("Username")
                local avatar = padding:FindFirstChild("Avatar")
                if nameLabel then nameLabel.Text = player.DisplayName end
                if usernameLabel then usernameLabel.Text = "@" .. player.Name end
                if avatar then
                    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
                end
                local hpBar = padding:FindFirstChild("HpBar")
                if hpBar then hpBar.Size = UDim2.new(1, 0, 1, 0) end
            end
        end
    end)
    
    MapObjects[player] = dot
end

local function updateDots(dt)
    if not MapEnabled then return end
    
    local char = LocalPlayer.Character
    local center = char and char:FindFirstChild("HumanoidRootPart")
    if not center then return end
    
    local targetYaw = math.atan2(Camera.CFrame.LookVector.Z, Camera.CFrame.LookVector.X)
    SmoothYaw = SmoothYaw + (targetYaw - SmoothYaw) * math.clamp(dt * 8, 0, 1)
    
    for player, dot in pairs(MapObjects) do
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            local offset = (hrp.Position - center.Position) / Utilities.Zoom
            local rx = offset.X * math.cos(SmoothYaw) + offset.Z * math.sin(SmoothYaw)
            local rz = -offset.X * math.sin(SmoothYaw) + offset.Z * math.cos(SmoothYaw)
            
            if math.abs(rx) <= 70 and math.abs(rz) <= 70 then
                dot.Visible = true
                dot.Position = UDim2.new(0.5, rx, 0.5, rz)
            else
                dot.Visible = false
            end
        else
            dot.Visible = false
        end
        
        if player == CurrentTarget then
            dot.ImageColor3 = Color3.fromRGB(255, 100, 100)
        else
            dot.ImageColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
    
    if CurrentTarget and InfoPanel.Visible then
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local character = CurrentTarget.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        
        local padding = InfoPanel:FindFirstChild("Padding")
        if padding then
            local hpBar = padding:FindFirstChild("HpBar")
            local hpText = padding:FindFirstChild("HP")
            local distText = padding:FindFirstChild("Distance")
            local speedText = padding:FindFirstChild("Speed")
            local statusText = padding:FindFirstChild("Status")
            
            if hum then
                local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                if hpBar then
                    hpBar.Size = UDim2.new(hpPercent, 0, 1, 0)
                    if hpPercent > 0.5 then
                        hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    elseif hpPercent > 0.25 then
                        hpBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                    else
                        hpBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                    end
                end
                if hpText then
                    hpText.Text = "HP: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                end
            else
                if hpText then hpText.Text = "HP: N/A" end
            end
            
            if myHRP and hrp then
                if distText then
                    distText.Text = "Dist: " .. math.floor((hrp.Position - myHRP.Position).Magnitude) .. "m"
                end
                if speedText then
                    local speed = math.floor(hrp.AssemblyLinearVelocity.Magnitude * 10) / 10
                    speedText.Text = "Speed: " .. speed .. " studs/s"
                end
                if statusText and hum then
                    local stateName = hum:GetState()
                    statusText.Text = "Status: " .. stateName.Name
                end
            else
                if distText then distText.Text = "Dist: N/A" end
                if speedText then speedText.Text = "Speed: N/A" end
                if statusText then statusText.Text = "Status: N/A" end
            end
        end
    end
end

local function initMap()
    createMap()
    
    for _, p in pairs(Players:GetPlayers()) do
        createDot(p)
    end
    
    Players.PlayerAdded:Connect(createDot)
    Players.PlayerRemoving:Connect(function(p)
        if MapObjects[p] then
            MapObjects[p]:Destroy()
            MapObjects[p] = nil
        end
        if CurrentTarget == p then
            CurrentTarget = nil
            InfoPanel.Visible = false
        end
    end)
    
    RenderConnection = RunService.RenderStepped:Connect(updateDots)
end

function Utilities.ToggleMiniMap(state)
    MapEnabled = state
    if state then
        if not MapGui then initMap() end
        MapGui.Enabled = true
    else
        if MapGui then MapGui.Enabled = false end
        if RenderConnection then
            RenderConnection:Disconnect()
            RenderConnection = nil
        end
    end
end

function Utilities.SetMapZoom(v)
    Utilities.Zoom = v
end

-- ==========================================================
-- VHS FUNCTIONS
-- ==========================================================
local function createVHS()
    local Config = {
        MaxDist = 80,
        LabelDist = 40,
        DangerDist = 15,
        ScanInterval = 1,
        ImgOff = "rbxassetid://135631823633524",
        ImgOn = "rbxassetid://101616742358473",
        SndToggle = "rbxassetid://73037893555019",
        SndLoop = "rbxassetid://9117158786",
        SndPulse = "rbxassetid://83171274972325",
        SndWarning = "rbxassetid://5476307813"
    }

    local Colors = {
        Self = Color3.fromRGB(255, 255, 255),
        Player = {Dark = Color3.fromRGB(0, 100, 0), Light = Color3.fromRGB(50, 255, 150)},
        NPC = {Dark = Color3.fromRGB(100, 80, 0), Light = Color3.fromRGB(255, 220, 50)},
        Monster = {Dark = Color3.fromRGB(150, 0, 0), Light = Color3.fromRGB(255, 50, 50)},
        Item = {Dark = Color3.fromRGB(80, 0, 80), Light = Color3.fromRGB(255, 100, 255)}
    }

    local isActive = false
    local isScanning = false
    local scanProgress = 0
    local isEnabled = false
    local isFOVMode = false
    local isHighlightMode = false
    local isWarning = false
    local defaultFOV = 70
    local currentFOV = 70
    local minFOV = 20
    local scanSpeed = 20

    local detectedEntities = {}
    local scanTimer = 0
    local warningTimer = nil

    local gui = Instance.new("ScreenGui")
    gui.Name = "VHS_System"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 10000
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui

    local overlay = Instance.new("ScreenGui")
    overlay.Name = "OverlaySystem"
    overlay.Parent = CoreGui
    overlay.IgnoreGuiInset = true
    overlay.DisplayOrder = 9999
    overlay.Enabled = false

    local vhsEffect = Instance.new("ColorCorrectionEffect")
    vhsEffect.Name = "VHS_Effect"
    vhsEffect.Parent = Lighting
    vhsEffect.Saturation = 0
    vhsEffect.Contrast = 0

    local scannerEffect = Instance.new("ColorCorrectionEffect")
    scannerEffect.Name = "ScannerEffect"
    scannerEffect.Parent = Lighting
    scannerEffect.TintColor = Color3.fromRGB(180, 255, 180)
    scannerEffect.Saturation = -0.2
    scannerEffect.Contrast = 0.1
    scannerEffect.Enabled = false

    local function createOverlay(imageId, transparency, zIndex)
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.Image = "rbxassetid://" .. imageId
        img.ImageTransparency = transparency
        img.ZIndex = zIndex
        img.Parent = overlay
        return img
    end

    createOverlay("124065757852836", 0.85, 1)
    local blackTransition = Instance.new("Frame")
    blackTransition.Name = "ScannerTransition"
    blackTransition.Parent = overlay
    blackTransition.Size = UDim2.new(1, 0, 1, 0)
    blackTransition.BackgroundColor3 = Color3.new(0, 0, 0)
    blackTransition.BackgroundTransparency = 1
    blackTransition.ZIndex = 200

    local ghostTint = Instance.new("Frame")
    ghostTint.Name = "GhostTint"
    ghostTint.Parent = overlay
    ghostTint.Size = UDim2.new(1, 0, 1, 0)
    ghostTint.BackgroundColor3 = Color3.fromRGB(0, 190, 255)
    ghostTint.BackgroundTransparency = 0.92
    ghostTint.ZIndex = 2

    local centerStatic = Instance.new("ImageLabel")
    centerStatic.Name = "CenterStatic"
    centerStatic.Parent = overlay
    centerStatic.Size = UDim2.new(0.6, 0, 0.6, 0)
    centerStatic.Position = UDim2.new(0.2, 0, 0.2, 0)
    centerStatic.BackgroundTransparency = 1
    centerStatic.Image = "rbxassetid://94577834870332"
    centerStatic.ImageTransparency = 0.92
    centerStatic.ScaleType = Enum.ScaleType.Tile
    centerStatic.TileSize = UDim2.new(0, 256, 0, 256)
    centerStatic.ZIndex = 3

    local scanFrame = Instance.new("Frame")
    scanFrame.Parent = overlay
    scanFrame.Size = UDim2.new(1, 0, 1, 0)
    scanFrame.BackgroundTransparency = 1
    scanFrame.Visible = false
    scanFrame.ZIndex = 10

    local warningFrame = Instance.new("Frame")
    warningFrame.Parent = scanFrame
    warningFrame.Size = UDim2.new(1, 0, 1, 0)
    warningFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    warningFrame.BackgroundTransparency = 1
    warningFrame.ZIndex = 13

    local scanOverlay = Instance.new("Frame")
    scanOverlay.Parent = scanFrame
    scanOverlay.Size = UDim2.new(1, 0, 1, 0)
    scanOverlay.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    scanOverlay.BackgroundTransparency = 0.92
    scanOverlay.ZIndex = 11

    local scanNoise = Instance.new("ImageLabel")
    scanNoise.Parent = scanFrame
    scanNoise.Size = UDim2.new(1, 0, 1, 0)
    scanNoise.BackgroundTransparency = 1
    scanNoise.Image = "rbxassetid://14902356596"
    scanNoise.ImageTransparency = 0.85
    scanNoise.ScaleType = Enum.ScaleType.Tile
    scanNoise.TileSize = UDim2.new(0, 256, 0, 256)
    scanNoise.ZIndex = 12

    local scanBeam = Instance.new("Frame")
    scanBeam.Name = "ScanBeam"
    scanBeam.Parent = scanFrame
    scanBeam.Size = UDim2.new(1, 0, 0, 40)
    scanBeam.AnchorPoint = Vector2.new(0, 0.5)
    scanBeam.BackgroundColor3 = Color3.fromRGB(150, 255, 150)
    scanBeam.BackgroundTransparency = 0.6
    scanBeam.BorderSizePixel = 0
    scanBeam.ZIndex = 12

    local beamGradient = Instance.new("UIGradient")
    beamGradient.Parent = scanBeam
    beamGradient.Rotation = 90
    beamGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0.5),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.8, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })

    createOverlay("18993146937", 0, 4)

    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = gui
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ZIndex = 100
    mainFrame.Visible = false

    local contentFrame = Instance.new("Frame")
    contentFrame.Parent = gui
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Visible = false

    local contentBg = Instance.new("Frame")
    contentBg.Parent = contentFrame
    contentBg.Size = UDim2.new(1, 0, 1, 0)
    contentBg.BackgroundColor3 = Color3.new(0, 0, 0)
    contentBg.BackgroundTransparency = 1
    contentBg.ZIndex = 0

    local function createLabel(text, position, parent, size, color)
        local label = Instance.new("TextLabel")
        label.Text = text
        label.Position = position
        label.Size = UDim2.new(0, 500, 0, 40)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBlack
        label.TextSize = size or 32
        label.TextColor3 = color or Color3.fromRGB(254, 254, 254)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTransparency = 0.1
        label.Parent = parent
        return label
    end

    local topLeft = Instance.new("Frame")
    topLeft.Parent = contentFrame
    topLeft.Position = UDim2.new(0.05, 0, 0.13, 0)
    topLeft.BackgroundTransparency = 1

    local playLabel = createLabel("PLAY", UDim2.new(0, 0, 0, 0), topLeft, 32)
    local playIcon = createLabel("▶", UDim2.new(0, 80, 0, -4), topLeft, 50)
    local timeLabel = createLabel("00:00:00", UDim2.new(0, 120, 0, 0), topLeft, 26, Color3.fromRGB(252, 252, 252))

    local bottomLeft = Instance.new("Frame")
    bottomLeft.Parent = contentFrame
    bottomLeft.Position = UDim2.new(0.05, 0, 0.8, 0)
    bottomLeft.BackgroundTransparency = 1

    local amLabel = createLabel("AM. 00:00", UDim2.new(0, 0, 0, 0), bottomLeft, 22)
    local dateLabel = createLabel("NOW. 00/00/0000", UDim2.new(0, 0, 0, 28), bottomLeft, 22)

    local topRight = Instance.new("Frame")
    topRight.Parent = contentFrame
    topRight.AnchorPoint = Vector2.new(0.97, 0)
    topRight.Position = UDim2.new(0.97, 0, 0.13, 0)
    topRight.BackgroundTransparency = 1
    topRight.Size = UDim2.new(0, 150, 0, 40)

    local recDot = Instance.new("Frame")
    recDot.Parent = topRight
    recDot.Size = UDim2.new(0, 16, 0, 16)
    recDot.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    recDot.AnchorPoint = Vector2.new(0, 0.5)
    recDot.Position = UDim2.new(0, 0, 0.5, 0)
    Instance.new("UICorner", recDot).CornerRadius = UDim.new(1, 0)

    local recLabel = createLabel("REC", UDim2.new(0, 25, 0.5, 0), topRight, 32, Color3.fromRGB(200, 40, 40))
    recLabel.AnchorPoint = Vector2.new(0, 0.5)
    recLabel.Size = UDim2.new(0, 100, 0, 40)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = contentFrame
    closeBtn.Text = "x"
    closeBtn.BackgroundTransparency = 1
    closeBtn.TextColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.TextSize = 35
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Size = UDim2.new(0, 70, 0, 70)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.new(1, 0, 0.08, 0)

    local btnFOV = Instance.new("ImageButton")
    btnFOV.Parent = contentFrame
    btnFOV.BackgroundTransparency = 1
    btnFOV.AnchorPoint = Vector2.new(1, 0.5)
    btnFOV.Position = UDim2.new(0.97, 0, 0.32, 0)
    btnFOV.Size = UDim2.new(0, 75, 0, 75)
    btnFOV.Image = "rbxassetid://5363460918"

    local btnScan = Instance.new("ImageButton")
    btnScan.Parent = contentFrame
    btnScan.BackgroundTransparency = 1
    btnScan.AnchorPoint = Vector2.new(1, 0.5)
    btnScan.Position = UDim2.new(0.97, 0, 0.54, 0)
    btnScan.Size = UDim2.new(0, 75, 0, 75)
    btnScan.Image = "rbxassetid://108860650354064"

    local btnToggle = Instance.new("ImageButton")
    btnToggle.Parent = contentFrame
    btnToggle.BackgroundTransparency = 1
    btnToggle.AnchorPoint = Vector2.new(1, 0.5)
    btnToggle.Position = UDim2.new(0.9, 0, 0.68, 0)
    btnToggle.Size = UDim2.new(0, 50, 0, 50)
    btnToggle.Image = Config.ImgOff
    btnToggle.ZIndex = 20

    local radar = Instance.new("Frame")
    radar.Parent = contentFrame
    radar.Size = UDim2.new(0, 140, 0, 140)
    radar.Position = UDim2.new(0, 30, 1, -170)
    radar.BackgroundColor3 = Color3.fromRGB(0, 20, 10)
    radar.BackgroundTransparency = 0.1
    radar.Visible = false
    radar.ClipsDescendants = true
    radar.ZIndex = 15
    Instance.new("UICorner", radar).CornerRadius = UDim.new(1, 0)

    local radarStroke = Instance.new("UIStroke")
    radarStroke.Parent = radar
    radarStroke.Color = Color3.fromRGB(50, 255, 100)
    radarStroke.Thickness = 3

    local radarCenter = Instance.new("Frame")
    radarCenter.Parent = radar
    radarCenter.AnchorPoint = Vector2.new(0.5, 0.5)
    radarCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
    radarCenter.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
    radarCenter.BackgroundTransparency = 0.6
    Instance.new("UICorner", radarCenter).CornerRadius = UDim.new(1, 0)

    local radarDot = Instance.new("Frame")
    radarDot.Parent = radar
    radarDot.Size = UDim2.new(0, 6, 0, 6)
    radarDot.AnchorPoint = Vector2.new(0.5, 0.5)
    radarDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    radarDot.BackgroundColor3 = Colors.Self
    radarDot.ZIndex = 20
    Instance.new("UICorner", radarDot)

    local toggleBtn = Instance.new("ImageButton")
    toggleBtn.Parent = gui
    toggleBtn.Size = UDim2.new(0, 60, 0, 60)
    toggleBtn.Position = UDim2.new(0.95, 0, 0.67, 0)
    toggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    toggleBtn.Image = "rbxassetid://12111472209"
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.ZIndex = 101
    toggleBtn.Visible = false

    local soundToggle = Instance.new("Sound")
    soundToggle.Parent = gui
    soundToggle.SoundId = "rbxassetid://6058448438"
    soundToggle.Volume = 1

    local soundLoop = Instance.new("Sound")
    soundLoop.Parent = gui
    soundLoop.SoundId = "rbxassetid://93400361700718"
    soundLoop.Volume = 1

    local soundPulse = Instance.new("Sound")
    soundPulse.Parent = gui
    soundPulse.SoundId = "rbxassetid://129467277313845"
    soundPulse.Volume = 0.2
    soundPulse.Looped = true

    local soundBtnFOV = Instance.new("Sound")
    soundBtnFOV.Parent = btnFOV
    soundBtnFOV.SoundId = "rbxassetid://78878058005997"
    soundBtnFOV.Volume = 1

    local soundBtnScan = Instance.new("Sound")
    soundBtnScan.Parent = btnScan
    soundBtnScan.SoundId = "rbxassetid://9070807695"
    soundBtnScan.Volume = 1

    local soundBtnToggle = Instance.new("Sound")
    soundBtnToggle.Parent = btnToggle
    soundBtnToggle.SoundId = Config.SndToggle
    soundBtnToggle.Volume = 0.3
    soundBtnToggle.Looped = true

    local soundBtnToggleOn = Instance.new("Sound")
    soundBtnToggleOn.Parent = btnToggle
    soundBtnToggleOn.SoundId = Config.SndPulse
    soundBtnToggleOn.Volume = 0.2
    soundBtnToggleOn.Looped = true

    local flashlightEnabled = false
    local flashlightSpot = nil

    local function toggleFlashlight()
        flashlightEnabled = not flashlightEnabled
        if flashlightEnabled then
            local character = LocalPlayer.Character
            local head = character and character:FindFirstChild("Head")
            if head then
                flashlightSpot = Instance.new("SpotLight")
                flashlightSpot.Name = "FlashlightSpot"
                flashlightSpot.Parent = head
                flashlightSpot.Angle = 60
                flashlightSpot.Range = 60
                flashlightSpot.Brightness = 5
                flashlightSpot.Enabled = true
            end
            btnScan.Image = "rbxassetid://135873273752805"
            soundBtnScan:Play()
        else
            if flashlightSpot then
                flashlightSpot:Destroy()
                flashlightSpot = nil
            end
            btnScan.Image = "rbxassetid://108860650354064"
            soundBtnScan:Play()
        end
    end

    local function getEntityType(entity)
        if entity:IsA("Tool") then return Colors.Item end
        if Players:GetPlayerFromCharacter(entity) then return Colors.Player end
        local name = entity.Name:lower()
        if name:find("monster") or name:find("entity") or name:find("killer") or name:match("a%-%d+") or entity:FindFirstChild("Damage") or entity:FindFirstChild("Hitbox") or entity:FindFirstChild("Humanoid") then
            return Colors.Monster
        end
        return Colors.NPC
    end

    local function addEntity(entity)
        if detectedEntities[entity] then return end
        if entity == LocalPlayer.Character then return end
        
        local root = entity:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local colorSet = getEntityType(entity)
        local data = {
            root = root,
            colorSet = colorSet,
            scanned = false,
            isMonster = colorSet == Colors.Monster
        }
        
        data.dot = Instance.new("Frame")
        data.dot.Parent = radar
        data.dot.Size = UDim2.new(0, 5, 0, 5)
        data.dot.AnchorPoint = Vector2.new(0.5, 0.5)
        data.dot.BackgroundColor3 = colorSet.Dark
        data.dot.Visible = false
        data.dot.ZIndex = 15
        Instance.new("UICorner", data.dot)
        
        data.hl = Instance.new("Highlight")
        data.hl.Parent = gui
        data.hl.Adornee = entity
        data.hl.FillColor = colorSet.Light
        data.hl.OutlineColor = colorSet.Light
        data.hl.FillTransparency = 0.8
        data.hl.OutlineTransparency = 0
        data.hl.Enabled = false
        
        if not entity:IsA("Tool") then
            data.bb = Instance.new("BillboardGui")
            data.bb.Parent = entity
            data.bb.Size = UDim2.new(0, 120, 0, 30)
            data.bb.AlwaysOnTop = true
            data.bb.Enabled = false
            data.bb.StudsOffset = Vector3.new(0, 3, 0)
            
            local label = Instance.new("TextLabel")
            label.Parent = data.bb
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = colorSet.Light
            label.Font = Enum.Font.Code
            label.TextScaled = true
            label.Text = entity.Name
            data.txt = label
        end
        
        detectedEntities[entity] = data
        
        entity.AncestryChanged:Connect(function(_, parent)
            if not parent and detectedEntities[entity] then
                if data.dot then data.dot:Destroy() end
                if data.hl then data.hl:Destroy() end
                if data.bb then data.bb:Destroy() end
                detectedEntities[entity] = nil
            end
        end)
    end

    local function stopWarning()
        isWarning = false
        soundPulse:Stop()
        warningFrame.BackgroundTransparency = 1
        scanOverlay.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        if warningTimer then
            task.cancel(warningTimer)
            warningTimer = nil
        end
    end

    local function triggerWarning()
        if isWarning or not isActive then return end
        isWarning = true
        soundPulse:Play()
        warningTimer = task.spawn(function()
            for i = 1, 4 do
                if not isWarning or not isActive then break end
                scanOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                warningFrame.BackgroundTransparency = 0.5
                warningFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                task.wait(0.3)
                if not isWarning or not isActive then break end
                warningFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                task.wait(0.1)
                warningFrame.BackgroundTransparency = 1
                task.wait(0.35)
            end
            stopWarning()
        end)
    end

    local function toggleScanner()
        if isScanning then return end
        isScanning = true
        isActive = not isActive
        btnToggle.Image = isActive and Config.ImgOn or Config.ImgOff
        
        if isActive then
            soundBtnToggleOn:Play()
            local tween = TweenService:Create(blackTransition, TweenInfo.new(0.5), {BackgroundTransparency = 0})
            tween:Play()
            task.wait(0.55)
            
            scanFrame.Visible = true
            radar.Visible = true
            scannerEffect.Enabled = true
            scanProgress = 0
            scanOverlay.BackgroundTransparency = 0.92
            scanNoise.ImageTransparency = 0.85
            scanBeam.BackgroundTransparency = 0.6
            soundBtnToggle:Play()
            
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character then addEntity(plr.Character) end
            end
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then addEntity(obj) end
            end
            
            tween = TweenService:Create(blackTransition, TweenInfo.new(0.5), {BackgroundTransparency = 1})
            tween:Play()
            task.wait(0.5)
        else
            stopWarning()
            soundBtnToggle:Play()
            local tween = TweenService:Create(blackTransition, TweenInfo.new(0.5), {BackgroundTransparency = 0})
            tween:Play()
            task.wait(0.55)
            
            soundBtnToggleOn:Stop()
            soundBtnToggle:Stop()
            scanFrame.Visible = false
            radar.Visible = false
            scannerEffect.Enabled = false
            
            for _, data in pairs(detectedEntities) do
                if data.dot then data.dot.Visible = false end
                if data.hl then data.hl.Enabled = false end
                if data.bb then data.bb.Enabled = false end
            end
            
            tween = TweenService:Create(blackTransition, TweenInfo.new(0.5), {BackgroundTransparency = 1})
            tween:Play()
            task.wait(0.5)
            isScanning = false
            return
        end
        isScanning = false
    end

    local function toggleFOV()
        if not isEnabled or isFOVMode then return end
        isFOVMode = true
        isHighlightMode = not isHighlightMode
        btnFOV.Image = isHighlightMode and "rbxthumb://type=Asset&id=5363459031&w=420&h=420" or "rbxassetid://5363460918"
        soundBtnFOV:Play()
        
        local startFOV = currentFOV
        local endFOV = isHighlightMode and minFOV or defaultFOV
        local steps = 3
        local stepSize = (endFOV - startFOV) / steps
        
        task.spawn(function()
            for i = 1, steps do
                currentFOV = startFOV + stepSize * i
                task.wait(0.4)
            end
            currentFOV = endFOV
            isFOVMode = false
        end)
    end

    local function toggleSystem()
        if not isEnabled then
            soundToggle:Play()
            mainFrame.Visible = true
            local tween = TweenService:Create(mainFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0})
            tween:Play()
            task.wait(0.5)
            
            isHighlightMode = false
            isActive = false
            scannerEffect.Enabled = false
            vhsEffect.Saturation = -0.6
            vhsEffect.Contrast = 0.3
            contentFrame.Visible = true
            overlay.Enabled = true
            toggleBtn.Visible = false
            
            LocalPlayer.CameraMaxZoomDistance = 0.5
            LocalPlayer.CameraMinZoomDistance = 0.5
            Camera.FieldOfView = currentFOV
            
            tween = TweenService:Create(mainFrame, TweenInfo.new(1), {BackgroundTransparency = 1})
            tween:Play()
            task.wait(1)
            mainFrame.Visible = false
            isEnabled = true
            soundLoop:Play()
        else
            if isActive then
                isActive = false
                btnToggle.Image = Config.ImgOff
                soundBtnToggleOn:Stop()
                soundBtnToggle:Stop()
                stopWarning()
                scanFrame.Visible = false
                radar.Visible = false
                scannerEffect.Enabled = false
                blackTransition.BackgroundTransparency = 1
                for _, data in pairs(detectedEntities) do
                    if data.dot then data.dot.Visible = false end
                    if data.hl then data.hl.Enabled = false end
                    if data.bb then data.bb.Enabled = false end
                end
                isScanning = false
            end
            
            soundLoop:Stop()
            soundToggle:Play()
            isHighlightMode = false
            isEnabled = false
            scannerEffect.Enabled = false
            vhsEffect.Saturation = 0
            vhsEffect.Contrast = 0
            contentFrame.Visible = false
            overlay.Enabled = false
            
            if _G.VHS_ToggleVisible then toggleBtn.Visible = true end
            
            LocalPlayer.CameraMaxZoomDistance = 50
            LocalPlayer.CameraMinZoomDistance = 0.5
            Camera.FieldOfView = 70
            
            mainFrame.Visible = true
            local tween = TweenService:Create(mainFrame, TweenInfo.new(0.6), {BackgroundTransparency = 0})
            tween:Play()
            task.wait(0.6)
            mainFrame.Visible = false
        end
    end

    toggleBtn.MouseButton1Click:Connect(toggleSystem)
    closeBtn.MouseButton1Click:Connect(toggleSystem)
    btnToggle.MouseButton1Click:Connect(toggleScanner)
    btnScan.MouseButton1Click:Connect(toggleFlashlight)
    btnFOV.MouseButton1Click:Connect(toggleFOV)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if isEnabled then
            if input.KeyCode == Enum.KeyCode.Q then toggleScanner()
            elseif input.KeyCode == Enum.KeyCode.Z then toggleFOV()
            elseif input.KeyCode == Enum.KeyCode.X then toggleSystem()
            elseif input.KeyCode == Enum.KeyCode.C then toggleFlashlight()
            end
        end
    end)

    task.spawn(function()
        while gui.Parent do
            if isEnabled then
                contentBg.BackgroundTransparency = 0.95
                task.wait(0.05)
                contentBg.BackgroundTransparency = 1
                task.wait(math.random(1) / 10)
            else
                task.wait(1)
            end
        end
    end)

    task.spawn(function()
        while gui.Parent do
            if isEnabled then
                playLabel.Visible = true
                playIcon.Visible = true
                task.wait(0.8)
                playLabel.Visible = false
                playIcon.Visible = false
                task.wait(0.4)
            else
                task.wait(1)
            end
        end
    end)

    task.spawn(function()
        while gui.Parent do
            if isEnabled then
                recDot.Visible = true
                recLabel.Position = UDim2.new(0, 26, 0.5, 0)
                task.wait(1)
                recDot.Visible = false
                recLabel.Position = UDim2.new(0, 22, 0.5, 0)
                task.wait(1)
            else
                task.wait(0.6)
            end
        end
    end)

    RunService.Heartbeat:Connect(function(delta)
        if isActive and scanFrame.Visible then
            scanNoise.Position = UDim2.new(math.random(-5, 5) / 100, 0, math.random(-5, 5) / 100, 0)
            scanBeam.Position = UDim2.new(0, 0, os.clock() % 2.5 / 2.5, -20)
            scanProgress = scanProgress + delta * 0.7
            
            if scanProgress > 1.2 then
                scanProgress = 0
                soundBtnToggleOn:Play()
                for _, data in pairs(detectedEntities) do
                    data.scanned = false
                end
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then addEntity(obj) end
                end
            end
            
            radarCenter.Size = UDim2.new(scanProgress, 0, scanProgress, 0)
            radarCenter.BackgroundTransparency = 0.6 + scanProgress * 0.3
            
            local camPos = Camera.CFrame.Position
            for entity, data in pairs(detectedEntities) do
                if data.root and data.root.Parent then
                    local dist = (camPos - data.root.Position).Magnitude
                    data.hl.Enabled = true
                    
                    if dist <= Config.MaxDist then
                        local relativePos = Camera.CFrame:VectorToObjectSpace(data.root.Position - camPos)
                        if not data.scanned and scanProgress >= Vector2.new(relativePos.X, relativePos.Z).Magnitude / Config.MaxDist then
                            data.scanned = true
                            data.dot.Position = UDim2.new(0.5 + relativePos.X / Config.MaxDist * 0.5, 0, 0.5 + relativePos.Z / Config.MaxDist * 0.5, 0)
                            data.dot.Visible = true
                            data.dot.BackgroundColor3 = data.colorSet.Light
                            local tween = TweenService:Create(data.dot, TweenInfo.new(0.5), {BackgroundColor3 = data.colorSet.Dark})
                            tween:Play()
                        end
                        if data.bb then
                            data.bb.Enabled = dist <= Config.LabelDist
                            data.txt.Text = string.format("%s [%dm]", entity.Name, math.floor(dist))
                        end
                    else
                        if scanProgress == 0 then data.dot.Visible = false end
                    end
                else
                    detectedEntities[entity] = nil
                end
            end
            
            for _, data in pairs(detectedEntities) do
                if data.isMonster then
                    local dist = (camPos - data.root.Position).Magnitude
                    if dist < Config.DangerDist and not isWarning then
                        triggerWarning()
                        break
                    end
                end
            end
            
            if isWarning then stopWarning() end
        end
        
        if not isEnabled then return end
        
        local t = os.date("*t")
        local hour = t.hour % 12
        if hour == 0 then hour = 12 end
        
        amLabel.Text = string.format("%s. %d:%02d", t.hour >= 12 and "PM" or "AM", hour, t.min)
        dateLabel.Text = string.format("NOW. %02d/%02d/%d", t.day, t.month, t.year)
        
        local elapsed = os.clock()
        timeLabel.Text = string.format("%02d:%02d:%02d", 
            math.floor(elapsed / 60), 
            math.floor(elapsed % 60), 
            math.floor(elapsed % 1 * 100)
        )
        
        centerStatic.Position = UDim2.new(0.2, math.random(-5, 5), 0.2, math.random(-5, 5))
        
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoid and rootPart then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = part.Name == "Head" and 1 or 0
                    elseif part:IsA("Accessory") then
                        local handle = part:FindFirstChild("Handle")
                        if handle then handle.LocalTransparencyModifier = 1 end
                    end
                end
                
                local speed = rootPart.Velocity.Magnitude
                local targetFOV = currentFOV + speed * 0.2
                Camera.FieldOfView = Camera.FieldOfView + (targetFOV - Camera.FieldOfView) * 0.1
            end
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid")
        local rootPart = char:WaitForChild("HumanoidRootPart")
    end)

    _G.VHS_Control = {
        showButton = function()
            if toggleBtn then
                toggleBtn.Visible = true
                _G.VHS_ToggleVisible = true
                return true
            end
            return false
        end,
        hideButton = function()
            if toggleBtn then
                if isEnabled then return false, "VHS is active" end
                toggleBtn.Visible = false
                _G.VHS_ToggleVisible = false
                return true
            end
            return false
        end,
        isButtonVisible = function()
            return toggleBtn and toggleBtn.Visible or false
        end,
        getGUI = function() return gui end,
        getToggleBtn = function() return toggleBtn end,
        isVHSActive = function() return isEnabled end,
        toggleVHS = function() toggleSystem() end
    }
    
    _G.VHS_Ready = true
end

function Utilities.InitVHS()
    if not _G.VHS_Ready then
        createVHS()
    end
end

function Utilities.ToggleVHS(state)
    if not _G.VHS_Ready then
        createVHS()
        task.wait(0.2)
    end
    
    if state then
        if _G.VHS_Control and _G.VHS_Ready then
            _G.VHS_Control.showButton()
            return true
        end
        return false
    else
        if _G.VHS_Control and _G.VHS_Ready then
            if _G.VHS_Control.isVHSActive and _G.VHS_Control.isVHSActive() then
                return false, "VHS is active"
            end
            _G.VHS_Control.hideButton()
            return true
        end
        return false
    end
end

-- ==========================================================
-- CAMERA FUNCTIONS
-- ==========================================================
function Utilities.ToggleThirdPerson(state)
    thirdPersonEnabled = state
    if state then
        thirdPersonLoop = RunService.RenderStepped:Connect(function()
            if LocalPlayer and LocalPlayer.Character then
                LocalPlayer.CameraMode = Enum.CameraMode.Classic
                LocalPlayer.CameraMinZoomDistance = 0
                LocalPlayer.CameraMaxZoomDistance = math.huge
            end
        end)
    else
        if thirdPersonLoop then
            thirdPersonLoop:Disconnect()
            thirdPersonLoop = nil
        end
    end
end

function Utilities.LockFirstPerson()
    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    LocalPlayer.CameraMinZoomDistance = 0
    LocalPlayer.CameraMaxZoomDistance = 0
end

function Utilities.ToggleLockCamera(state)
    camLocked = state
    if state then
        savedCFrame = Camera.CFrame
        camConn = RunService.RenderStepped:Connect(function()
            if camLocked and savedCFrame then
                Camera.CFrame = savedCFrame
            end
        end)
    else
        if camConn then
            camConn:Disconnect()
            camConn = nil
        end
        savedCFrame = nil
    end
end

function Utilities.SetFOV(v)
    Camera.FieldOfView = v
end

return Utilities
