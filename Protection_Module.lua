local Protection = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- State
Protection.protectToggles = {
    AntiFling = false,
    AntiVoid = false,
    SafePosition = false,
    SmartAntiTP = false,
    AntiStun = false
}

Protection.LastSafePos = nil
Protection.AntiAFKActive = false

Protection.AntiFlingData = {
    LastVelocity = nil,
    LastPosition = nil,
    LastTime = nil,
    FlingCount = 0,
    LastAlertTime = 0
}

local loopTouchEnabled = false
local loopClickEnabled = false
local loopPromptEnabled = false
local loopRemoteEnabled = false
local loopInvokeEnabled = false
local tpTool = nil
local tpToolEnabled = false
local abusiveToggles = {TouchFling = false, ClickFling = false}
local touchFlingActive = false
local touchFlingThread = nil
local trackingCoords = false
local coordsFloatGui = nil
local coordsXValue = nil
local coordsYValue = nil
local coordsZValue = nil
local tpX, tpY, tpZ = 0, 0, 0
local quickTPEnabled = false
local quickTPGui = nil
local quickTPMenu = nil
local savedSlots = {nil, nil, nil, nil}
local currentSlot = 1
local pointLabels = {}

-- Helpers
local function getChar() return LocalPlayer.Character end
local function getHum()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function fixCharacter(hum, root)
    if not hum or not root then return end
    if hum.PlatformStand or hum:GetState() == Enum.HumanoidStateType.Physics or hum:GetState() == Enum.HumanoidStateType.Ragdoll then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        root.AssemblyAngularVelocity = Vector3.zero
        if root.Orientation.Z > 45 or root.Orientation.Z < -45 then
            root.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(0, 0, 1))
        end
    end
end

-- ==========================================================
-- PROTECTION TOGGLES
-- ==========================================================
function Protection.SetAntiFling(state)
    Protection.protectToggles.AntiFling = state
end

function Protection.SetAntiStun(state)
    Protection.protectToggles.AntiStun = state
end

function Protection.SetAntiVoid(state)
    Protection.protectToggles.AntiVoid = state
end

function Protection.SetSafePosition(state)
    Protection.protectToggles.SafePosition = state
end

function Protection.SetSmartAntiTP(state)
    Protection.protectToggles.SmartAntiTP = state
end

function Protection.ToggleAntiAFK(notify)
    if Protection.AntiAFKActive then
        if notify then notify("Anti AFK", "Đã bật rồi!", "shield") end
        return
    end
    Protection.AntiAFKActive = true
    for _, v in pairs(getconnections(LocalPlayer.Idled)) do
        v:Disable()
    end
    task.spawn(function()
        while Protection.AntiAFKActive do
            task.wait(30)
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
            end)
        end
    end)
    if notify then notify("Anti AFK", "Đã bật chống AFK!", "shield") end
end

-- ==========================================================
-- FIRE ALL
-- ==========================================================
function Protection.FireAllTouchInterests()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("TouchTransmitter") then
            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, v.Parent, 0)
        end
    end
end

function Protection.FireAllClickDetectors()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ClickDetector") then
            fireclickdetector(v)
        end
    end
end

function Protection.FireAllProximityPrompts()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            fireproximityprompt(v)
        end
    end
end

function Protection.FireAllRemoteEvents()
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            v:FireServer()
        end
    end
end

function Protection.InvokeAllRemoteFunctions()
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteFunction") then
            task.spawn(function()
                v:InvokeServer()
            end)
        end
    end
end

-- ==========================================================
-- LOOP FIRE
-- ==========================================================
function Protection.ToggleLoopTouch(state)
    loopTouchEnabled = state
    if state then
        task.spawn(function()
            while loopTouchEnabled do
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("TouchTransmitter") then
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, v.Parent, 0)
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end

function Protection.ToggleLoopClick(state)
    loopClickEnabled = state
    if state then
        task.spawn(function()
            while loopClickEnabled do
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("ClickDetector") then
                        fireclickdetector(v)
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end

function Protection.ToggleLoopPrompt(state)
    loopPromptEnabled = state
    if state then
        task.spawn(function()
            while loopPromptEnabled do
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") then
                        fireproximityprompt(v)
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end

function Protection.ToggleLoopRemote(state)
    loopRemoteEnabled = state
    if state then
        task.spawn(function()
            while loopRemoteEnabled do
                for _, v in ipairs(game:GetDescendants()) do
                    if v:IsA("RemoteEvent") then
                        v:FireServer()
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end

function Protection.ToggleLoopInvoke(state)
    loopInvokeEnabled = state
    if state then
        task.spawn(function()
            while loopInvokeEnabled do
                for _, v in ipairs(game:GetDescendants()) do
                    if v:IsA("RemoteFunction") then
                        task.spawn(function()
                            v:InvokeServer()
                        end)
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end

-- ==========================================================
-- MISC
-- ==========================================================
function Protection.ToggleTouchInterests(state)
    if state then
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("TouchTransmitter") then
                v.Parent.CanTouch = false
            end
        end
        Workspace.DescendantAdded:Connect(function(v)
            if state and v:IsA("TouchTransmitter") then
                v.Parent.CanTouch = false
            end
        end)
    else
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("TouchTransmitter") then
                v.Parent.CanTouch = true
            end
        end
    end
end

function Protection.MaxClickDistance()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ClickDetector") then
            v.MaxActivationDistance = 9999
        end
    end
end

-- ==========================================================
-- TP TOOL (Skit TP — raycast + PivotTo, giữ rotation)
-- ==========================================================
local tpToolEquipped = false
local tpToolConnections = {}

local function teleportToScreenPosition(screenPos)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local unitRay = Camera:ViewportPointToRay(screenPos.X, screenPos.Y)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.IgnoreWater = true

    local raycastResult = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)

    if raycastResult then
        local targetPosition = raycastResult.Position + Vector3.new(0, 3, 0)
        local currentRotation = character:GetPivot().Rotation
        character:PivotTo(CFrame.new(targetPosition) * currentRotation)
    end
end

local function giveTPTool()
    if tpTool then return end
    if LocalPlayer.Backpack:FindFirstChild("Skit TP") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Skit TP")) then
        return
    end

    tpTool = Instance.new("Tool")
    tpTool.Name = "Skit TP"
    tpTool.RequiresHandle = false
    tpTool.CanBeDropped = false

    table.insert(tpToolConnections, tpTool.Equipped:Connect(function()
        tpToolEquipped = true
    end))

    table.insert(tpToolConnections, tpTool.Unequipped:Connect(function()
        tpToolEquipped = false
    end))

    tpTool.Parent = LocalPlayer.Backpack
end

local function destroyTPTool()
    tpToolEquipped = false
    for _, conn in ipairs(tpToolConnections) do
        pcall(function() conn:Disconnect() end)
    end
    tpToolConnections = {}
    if tpTool then
        tpTool:Destroy()
        tpTool = nil
    end
end

UserInputService.TouchTapInWorld:Connect(function(touchPos, gameProcessed)
    if not tpToolEnabled then return end
    if not tpToolEquipped then return end
    if gameProcessed then return end
    teleportToScreenPosition(touchPos)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not tpToolEnabled then return end
    if not tpToolEquipped then return end
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        teleportToScreenPosition(input.Position)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    tpToolEquipped = false
    task.wait(0.5)
    if tpToolEnabled then
        giveTPTool()
    end
end)

function Protection.ToggleTPTool(state)
    tpToolEnabled = state
    if state then
        giveTPTool()
    else
        destroyTPTool()
    end
end

-- ==========================================================
-- ANCHOR POSITION TOOL
-- 2 tool riêng biệt: Set Position + Anchor Player
-- ==========================================================
local anchorState = {
    part = nil,
    toolSetPos = nil,
    toolAnchor = nil,
    isAnchored = false,
    heartbeatConn = nil,
    toolConns = {},
    enabled = false,
}

local function giveAnchorTools()
    if anchorState.toolSetPos or anchorState.toolAnchor then return end

    -- Part indicator
    if not anchorState.part then
        local part = Instance.new("Part")
        part.Size = Vector3.new(2, 2, 1)
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.BrickColor = BrickColor.new("White")
        part.Material = Enum.Material.SmoothPlastic
        part.Parent = Workspace
        anchorState.part = part
    end

    -- Tool 1: Set Position
    local toolSetPos = Instance.new("Tool")
    toolSetPos.Name = "Set Position"
    toolSetPos.RequiresHandle = false
    toolSetPos.CanBeDropped = false
    toolSetPos.Parent = LocalPlayer.Backpack
    anchorState.toolSetPos = toolSetPos

    table.insert(anchorState.toolConns, toolSetPos.Equipped:Connect(function()
        if anchorState.part then anchorState.part.Transparency = 0.5 end
    end))

    table.insert(anchorState.toolConns, toolSetPos.Unequipped:Connect(function()
        if anchorState.part then anchorState.part.Transparency = 1 end
    end))

    table.insert(anchorState.toolConns, toolSetPos.Activated:Connect(function()
        if anchorState.part then
            anchorState.part.Position = Mouse.Hit.Position + Vector3.new(0, 1.5, 0)
        end
    end))

    -- Tool 2: Anchor Player
    local toolAnchor = Instance.new("Tool")
    toolAnchor.Name = "Anchor Player: OFF"
    toolAnchor.RequiresHandle = false
    toolAnchor.CanBeDropped = false
    toolAnchor.Parent = LocalPlayer.Backpack
    anchorState.toolAnchor = toolAnchor

    table.insert(anchorState.toolConns, toolAnchor.Activated:Connect(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and anchorState.part then
            local hrp = char.HumanoidRootPart
            anchorState.isAnchored = not anchorState.isAnchored

            if anchorState.isAnchored then
                toolAnchor.Name = "Anchor Player: ON"
                hrp.CFrame = CFrame.new(anchorState.part.Position + Vector3.new(0, 1.5, 0))
                hrp.Anchored = true
            else
                toolAnchor.Name = "Anchor Player: OFF"
                hrp.Anchored = false
            end
        end
    end))

    -- Heartbeat enforcement (chống tap-to-move mobile)
    if anchorState.heartbeatConn then
        anchorState.heartbeatConn:Disconnect()
    end
    anchorState.heartbeatConn = RunService.Heartbeat:Connect(function()
        if anchorState.isAnchored then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and anchorState.part then
                local hrp = char.HumanoidRootPart
                hrp.Anchored = true
                hrp.CFrame = CFrame.new(anchorState.part.Position + Vector3.new(0, 1.5, 0))
            end
        end
    end)
end

local function destroyAnchorTools()
    anchorState.isAnchored = false

    if anchorState.heartbeatConn then
        anchorState.heartbeatConn:Disconnect()
        anchorState.heartbeatConn = nil
    end

    for _, conn in ipairs(anchorState.toolConns) do
        pcall(function() conn:Disconnect() end)
    end
    anchorState.toolConns = {}

    if anchorState.toolSetPos then
        anchorState.toolSetPos:Destroy()
        anchorState.toolSetPos = nil
    end
    if anchorState.toolAnchor then
        anchorState.toolAnchor:Destroy()
        anchorState.toolAnchor = nil
    end
    if anchorState.part then
        anchorState.part:Destroy()
        anchorState.part = nil
    end

    -- Unanchor player khi tắt toggle
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.Anchored = false
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if anchorState.enabled then
        destroyAnchorTools()
        giveAnchorTools()
    end
end)

function Protection.ToggleAnchorTool(state)
    anchorState.enabled = state
    if state then
        giveAnchorTools()
    else
        destroyAnchorTools()
    end
end

-- ==========================================================
-- TOUCH / CLICK FLING
-- ==========================================================
local function startTouchFling()
    if touchFlingThread then return end
    touchFlingActive = true

    touchFlingThread = task.spawn(function()
        while touchFlingActive do
            RunService.Heartbeat:Wait()
            pcall(function()
                local c = LocalPlayer.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")

                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        for _, part in ipairs(player.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end

                if hrp then
                    local vel = hrp.Velocity
                    hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
                    RunService.RenderStepped:Wait()
                    hrp.Velocity = vel
                    RunService.Stepped:Wait()
                    hrp.Velocity = vel + Vector3.new(0, 0.1, 0)
                end
            end)
        end
    end)
end

local function stopTouchFling()
    touchFlingActive = false
    touchFlingThread = nil
end

function Protection.ToggleTouchFling(state)
    abusiveToggles.TouchFling = state
    if state then
        startTouchFling()
    else
        stopTouchFling()
    end
end

local function getTargetFromMouse()
    local target = Mouse.Target
    if not target then return nil end
    local targetChar = target:FindFirstAncestorOfClass("Model")
    if not targetChar then return nil end
    local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
    if not targetPlayer or targetPlayer == LocalPlayer then return nil end
    return targetPlayer
end

local function performClickFling(targetPlayer)
    pcall(function()
        if not targetPlayer then return end
        local targetChar = targetPlayer.Character
        local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if not targetHRP then return end

        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local origin = myHRP.CFrame

        myHRP.CFrame = targetHRP.CFrame
        pcall(function() sethiddenproperty(myHRP, "PhysicsRepRootPart", targetHRP) end)

        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVel.Velocity = Vector3.new(0, 10000, 0)
        bodyVel.Parent = targetHRP

        local bodyAngular = Instance.new("BodyAngularVelocity")
        bodyAngular.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyAngular.AngularVelocity = Vector3.new(0, 1000, 0)
        bodyAngular.Parent = targetHRP

        task.wait(0.5)

        if bodyVel then bodyVel:Destroy() end
        if bodyAngular then bodyAngular:Destroy() end

        pcall(function() sethiddenproperty(myHRP, "PhysicsRepRootPart", nil) end)
        myHRP.CFrame = origin
        myHRP.AssemblyLinearVelocity = Vector3.new()
        myHRP.AssemblyAngularVelocity = Vector3.new()
    end)
end

local function createClickFlingTool()
    local tool = Instance.new("Tool")
    tool.Name = "ClickFling"
    tool.RequiresHandle = false
    tool.CanBeDropped = false
    tool.Parent = LocalPlayer.Backpack

    tool.Activated:Connect(function()
        local targetPlayer = getTargetFromMouse()
        if targetPlayer then
            performClickFling(targetPlayer)
        end
    end)
end

function Protection.ToggleClickFling(state)
    abusiveToggles.ClickFling = state
    if state then
        createClickFlingTool()
    else
        local tool = LocalPlayer.Backpack:FindFirstChild("ClickFling")
        if tool then tool:Destroy() end
    end
end

-- ==========================================================
-- COORDS TRACKER
-- ==========================================================
local function createCoordsFloat()
    if coordsFloatGui then return end

    coordsFloatGui = Instance.new("ScreenGui")
    coordsFloatGui.Name = "CoordsTrackerFloat"
    coordsFloatGui.ResetOnSpawn = false
    coordsFloatGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 260, 0, 80)
    mainFrame.Position = UDim2.new(0.02, 0, 0.15, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = coordsFloatGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(138, 116, 249)
    mainStroke.Thickness = 1.5
    mainStroke.Transparency = 0.3
    mainStroke.Parent = mainFrame

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 30, 0, 30)
    iconLabel.Position = UDim2.new(0, 10, 0, 10)
    iconLabel.BackgroundColor3 = Color3.fromRGB(138, 116, 249)
    iconLabel.BackgroundTransparency = 0.2
    iconLabel.Text = "X"
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.TextSize = 16
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Parent = mainFrame
    Instance.new("UICorner", iconLabel).CornerRadius = UDim.new(1, 0)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 0, 20)
    titleLabel.Position = UDim2.new(0, 48, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Coords Tracker"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = mainFrame

    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(1, -50, 0, 15)
    subLabel.Position = UDim2.new(0, 48, 0, 28)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = "Position"
    subLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    subLabel.TextSize = 11
    subLabel.Font = Enum.Font.Gotham
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.Parent = mainFrame

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -20, 0, 1)
    line.Position = UDim2.new(0, 10, 0, 50)
    line.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    line.BorderSizePixel = 0
    line.Parent = mainFrame

    local coordRow = Instance.new("Frame")
    coordRow.Size = UDim2.new(1, -20, 0, 20)
    coordRow.Position = UDim2.new(0, 10, 0, 55)
    coordRow.BackgroundTransparency = 1
    coordRow.Parent = mainFrame

    local coordLayout = Instance.new("UIListLayout")
    coordLayout.FillDirection = Enum.FillDirection.Horizontal
    coordLayout.SortOrder = Enum.SortOrder.LayoutOrder
    coordLayout.Padding = UDim.new(0, 6)
    coordLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    coordLayout.Parent = coordRow

    local function createCoordItem(name, color, order)
        local item = Instance.new("Frame")
        item.Size = UDim2.new(0, 76, 1, 0)
        item.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        item.BorderSizePixel = 0
        item.LayoutOrder = order
        item.Parent = coordRow
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 6)

        local itemStroke = Instance.new("UIStroke")
        itemStroke.Color = color
        itemStroke.Thickness = 1
        itemStroke.Transparency = 0.5
        itemStroke.Parent = item

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, 18, 1, 0)
        nameLabel.Position = UDim2.new(0, 5, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = color
        nameLabel.TextSize = 12
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = item

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(1, -25, 1, 0)
        valueLabel.Position = UDim2.new(0, 23, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = "0.0"
        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueLabel.TextSize = 11
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.Parent = item

        return valueLabel
    end

    coordsXValue = createCoordItem("X", Color3.fromRGB(255, 100, 100), 1)
    coordsYValue = createCoordItem("Y", Color3.fromRGB(100, 255, 100), 2)
    coordsZValue = createCoordItem("Z", Color3.fromRGB(100, 150, 255), 3)
end

local function destroyCoordsFloat()
    if coordsFloatGui then
        coordsFloatGui:Destroy()
        coordsFloatGui = nil
        coordsXValue = nil
        coordsYValue = nil
        coordsZValue = nil
    end
end

function Protection.CopyCharPosition(notify)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pos = char.HumanoidRootPart.Position
        local text = string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z)
        setclipboard(text)
        if notify then notify("Copy", "Đã sao chép: " .. text, "clipboard") end
    else
        if notify then notify("Copy", "Không tìm thấy nhân vật!", "x") end
    end
end

function Protection.CopyCameraPosition(notify)
    local camPos = Camera.CFrame.Position
    local text = string.format("%.2f, %.2f, %.2f", camPos.X, camPos.Y, camPos.Z)
    setclipboard(text)
    if notify then notify("Copy", "Đã sao chép: " .. text, "clipboard") end
end

function Protection.ToggleCoordsTracker(state)
    trackingCoords = state
    if state then
        createCoordsFloat()
    else
        destroyCoordsFloat()
    end
end

function Protection.SetTeleportCoords(text)
    local coords = {}
    for val in string.gmatch(text, "([^,]+)") do
        local num = tonumber(val:match("^%s*(.-)%s*$"))
        if num then table.insert(coords, num) end
    end
    if #coords == 3 then
        tpX, tpY, tpZ = coords[1], coords[2], coords[3]
        return true
    end
    return false
end

function Protection.TeleportToCoords(notify)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(tpX, tpY, tpZ)
        if notify then notify("TP", "Đã dịch chuyển đến (" .. tpX .. ", " .. tpY .. ", " .. tpZ .. ")", "target") end
    else
        if notify then notify("TP", "Không tìm thấy nhân vật!", "x") end
    end
end

-- ==========================================================
-- QUICK TP
-- ==========================================================
local function createPointLabel(slot, position)
    if pointLabels[slot] then
        pointLabels[slot]:Destroy()
        pointLabels[slot] = nil
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 180, 0, 70)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.MaxDistance = 500
    billboard.Parent = Workspace

    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Transparency = 1
    part.Size = Vector3.new(0.1, 0.1, 0.1)
    part.CFrame = CFrame.new(position)
    part.Parent = Workspace
    billboard.Parent = part

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = billboard
    titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Point " .. slot
    titleLabel.TextColor3 = Color3.fromRGB(180, 160, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 22
    titleLabel.TextStrokeTransparency = 0

    local coordsLabel = Instance.new("TextLabel")
    coordsLabel.Parent = billboard
    coordsLabel.Size = UDim2.new(1, 0, 0.5, 0)
    coordsLabel.Position = UDim2.new(0, 0, 0.5, 0)
    coordsLabel.BackgroundTransparency = 1
    coordsLabel.Text = string.format("X: %.1f Y: %.1f Z: %.1f", position.X, position.Y, position.Z)
    coordsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    coordsLabel.Font = Enum.Font.Gotham
    coordsLabel.TextSize = 13
    coordsLabel.TextStrokeTransparency = 0.5

    pointLabels[slot] = billboard
end

local function createQuickTPMenu()
    if quickTPGui then
        quickTPGui:Destroy()
        quickTPGui = nil
        quickTPMenu = nil
    end

    quickTPGui = Instance.new("ScreenGui")
    quickTPGui.Name = "NoirQuickTP"
    quickTPGui.ResetOnSpawn = false
    quickTPGui.IgnoreGuiInset = true
    quickTPGui.DisplayOrder = 999999999
    quickTPGui.Parent = CoreGui

    quickTPMenu = Instance.new("Frame", quickTPGui)
    quickTPMenu.Size = UDim2.new(0, 210, 0, 170)
    quickTPMenu.Position = UDim2.new(0, 350, 0, 200)
    quickTPMenu.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    quickTPMenu.Active = true
    quickTPMenu.Draggable = true

    local menuCorner = Instance.new("UICorner", quickTPMenu)
    menuCorner.CornerRadius = UDim.new(0, 12)

    local menuStroke = Instance.new("UIStroke", quickTPMenu)
    menuStroke.Color = Color3.fromRGB(40, 40, 40)
    menuStroke.Thickness = 1

    local title = Instance.new("TextLabel", quickTPMenu)
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    title.Text = "Quick TP"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.ZIndex = 2
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    local mainLayout = Instance.new("UIListLayout", quickTPMenu)
    mainLayout.Padding = UDim.new(0, 6)
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local function tpBtn(txt, icon, func)
        local btn = Instance.new("TextButton", quickTPMenu)
        btn.Size = UDim2.new(0.9, 0, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        btn.Text = "  " .. icon .. "  " .. txt
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold        btn.TextSize = 14
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
        end)

        btn.MouseButton1Click:Connect(func)
        return btn
    end

    tpBtn("Set Point", "P", function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local pos = LocalPlayer.Character.HumanoidRootPart.Position
            savedSlots[currentSlot] = pos
            createPointLabel(currentSlot, pos)
        end
    end)

    tpBtn("Teleport", "T", function()
        if savedSlots[currentSlot] and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(savedSlots[currentSlot])
        end
    end)

    local slotFrame = Instance.new("Frame", quickTPMenu)
    slotFrame.Size = UDim2.new(0.9, 0, 0, 28)
    slotFrame.BackgroundTransparency = 1
    slotFrame.LayoutOrder = 10

    local slotLayout = Instance.new("UIListLayout", slotFrame)
    slotLayout.FillDirection = Enum.FillDirection.Horizontal
    slotLayout.Padding = UDim.new(0, 6)
    slotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local slotButtons = {}

    for i = 1, 4 do
        local slotBtn = Instance.new("TextButton", slotFrame)
        slotBtn.Size = UDim2.new(0, 35, 1, 0)
        slotBtn.Text = tostring(i)
        slotBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        slotBtn.TextColor3 = Color3.new(1, 1, 1)
        slotBtn.Font = Enum.Font.GothamBold
        slotBtn.TextSize = 14
        slotBtn.AutoButtonColor = false
        Instance.new("UICorner", slotBtn).CornerRadius = UDim.new(0, 6)

        slotBtn.MouseEnter:Connect(function()
            if currentSlot ~= i then
                TweenService:Create(slotBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
            end
        end)
        slotBtn.MouseLeave:Connect(function()
            if currentSlot ~= i then
                TweenService:Create(slotBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
            end
        end)

        slotBtn.MouseButton1Click:Connect(function()
            currentSlot = i
            for _, other in ipairs(slotFrame:GetChildren()) do
                if other:IsA("TextButton") then
                    TweenService:Create(other, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                end
            end
            TweenService:Create(slotBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(138, 116, 249)}):Play()
        end)

        table.insert(slotButtons, slotBtn)
    end

    currentSlot = 1
    for i, btn in ipairs(slotButtons) do
        if i == 1 then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(138, 116, 249)}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
        end
    end
end

function Protection.ToggleQuickTP(state)
    quickTPEnabled = state
    if state then
        createQuickTPMenu()
    else
        if quickTPGui then
            quickTPGui:Destroy()
            quickTPGui = nil
            quickTPMenu = nil
        end
        for _, v in pairs(pointLabels) do
            if v then v:Destroy() end
        end
        pointLabels = {}
    end
end

-- ==========================================================
-- MAIN LOOP
-- ==========================================================
RunService.Heartbeat:Connect(function()
    local char = getChar()
    local hum = getHum()
    local hrp = getHRP()
    if not char or not hum or not hrp then return end

    if Protection.protectToggles.AntiFling then
        local now = tick()
        local currentVel = hrp.AssemblyLinearVelocity
        local currentPos = hrp.Position

        if Protection.AntiFlingData.LastVelocity and Protection.AntiFlingData.LastTime then
            local dt = now - Protection.AntiFlingData.LastTime
            if dt > 0 and dt < 0.2 then
                local deltaVel = (currentVel - Protection.AntiFlingData.LastVelocity).Magnitude
                local velJump = currentVel.Magnitude - Protection.AntiFlingData.LastVelocity.Magnitude
                local posJump = (currentPos - Protection.AntiFlingData.LastPosition).Magnitude

                local isFling = false

                if deltaVel > 1000 then
                    isFling = true
                elseif velJump > 1000 and currentVel.Magnitude > 80 then
                    isFling = true
                elseif posJump > 100 and dt < 0.1 then
                    isFling = true
                end

                if isFling then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = CFrame.new(Protection.AntiFlingData.LastPosition or currentPos)
                    hrp.Anchored = true
                    task.spawn(function()
                        task.wait(0.1)
                        if hrp then hrp.Anchored = false end
                    end)
                    currentVel = Vector3.zero
                end
            end
        end

        Protection.AntiFlingData.LastVelocity = currentVel
        Protection.AntiFlingData.LastPosition = currentPos
        Protection.AntiFlingData.LastTime = now
    end

    if Protection.protectToggles.AntiVoid and hrp.Position.Y < -10 then
        hrp.CFrame = CFrame.new(hrp.Position.X, 20, hrp.Position.Z)
        hrp.AssemblyLinearVelocity = Vector3.zero
    end

    if Protection.protectToggles.SafePosition then
        Protection.LastSafePos = Protection.LastSafePos or hrp.Position
        local dist = (hrp.Position - Protection.LastSafePos).Magnitude
        if dist < 30 then
            Protection.LastSafePos = hrp.Position
        elseif dist > 80 then
            hrp.CFrame = CFrame.new(Protection.LastSafePos)
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end

    if Protection.protectToggles.SmartAntiTP then
        if Protection.LastSafePos and (hrp.Position - Protection.LastSafePos).Magnitude > 100 then
            hrp.CFrame = CFrame.new(Protection.LastSafePos)
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end

    if Protection.protectToggles.AntiStun then
        fixCharacter(hum, hrp)
    end
end)

RunService.RenderStepped:Connect(function()
    if trackingCoords and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local pos = LocalPlayer.Character.HumanoidRootPart.Position
        if coordsXValue then coordsXValue.Text = string.format("%.1f", pos.X) end
        if coordsYValue then coordsYValue.Text = string.format("%.1f", pos.Y) end
        if coordsZValue then coordsZValue.Text = string.format("%.1f", pos.Z) end
    end
end)

return Protection
