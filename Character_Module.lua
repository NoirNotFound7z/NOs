local Character = {}

local LocalPlayer = game:GetService("Players").LocalPlayer
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local mouse = LocalPlayer:GetMouse()
local Debris = game:GetService("Debris")

-- State
Character.hipHeightValue = 0
Character.pathSize = 5
Character.pathThickness = 1
Character.pathDuration = 10
Character.pathDraggable = true
Character.shiftlockCursorSize = 0.03

local noclipEnabled = false
local camNoClipConnection = nil
local spyderEnabled = false
local spyderHRP = nil
local spyderHumanoid = nil
local spyderConnection = nil
local promptConn = nil
local clickConn = nil
local crosshairEnabled = false
local crosshairColor = Color3.fromRGB(255, 255, 255)
local crosshairSize = 2
local isDesynced = false
local realChar = nil
local fakeChar = nil
local IsInvisible = false
local FocusPart = nil
local FakeCharName = "GhostEntity_" .. tostring(math.random(1000, 9999))
local OriginalProperties = {}
local TestCoordinate = CFrame.new(0, 500, 10000)
local invisConnection = nil
local invKeybind = nil
local hipHeightEnabled = false
local floatEnabled = false
local floatPart = nil
local floatConnection = nil
local pathEnabled = false
local pathButton = nil
local pathButtonGui = nil
local shiftlockUI = nil
local shiftlockActive = false
local shiftlockConnection = nil
local shiftlockButton = nil
local shiftlockCursor = nil
local shiftlockEnabled = false
local shiftlockCursorID = "rbxasset://textures/MouseLockedCursor.png"

local States = {
    Off = "rbxasset://textures/ui/mouseLock_off@2x.png",
    On = "rbxasset://textures/ui/mouseLock_on@2x.png",
    Lock = "rbxasset://textures/MouseLockedCursor.png"
}

local MaxLength = 900000
local EnabledOffset = CFrame.new(1.7, 0, 0)
local DisabledOffset = CFrame.new(-1.7, 0, 0)

local crosshair = Drawing.new("Circle")
crosshair.Visible = false
crosshair.Color = crosshairColor
crosshair.Thickness = 1
crosshair.Radius = crosshairSize
crosshair.Filled = true

local lines = {}
for i = 1, 4 do
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = crosshairColor
    line.Thickness = 2
    table.insert(lines, line)
end

-- ==========================================================
-- NOCLIP
-- ==========================================================
function Character.ToggleNoClip(state, notify)
    noclipEnabled = state
    if state then
        RunService:BindToRenderStep("NoirNoClip", Enum.RenderPriority.Character.Value, function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end)
        if notify then notify("Đã bật NoClip!", "ghost") end
    else
        RunService:UnbindFromRenderStep("NoirNoClip")
        local char = LocalPlayer.Character
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
        if notify then notify("Đã tắt NoClip!", "ghost") end
    end
end

function Character.ToggleNoClipCamera(state, notify)
    if state then
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
        camNoClipConnection = RunService.RenderStepped:Connect(function()
            if workspace.CurrentCamera then
                workspace.CurrentCamera.CameraOcclusion = Enum.CameraOcclusion.Invisicam
            end
        end)
        if notify then notify("Đã bật No Clip Camera", "eye") end
    else
        if camNoClipConnection then camNoClipConnection:Disconnect() end
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
        if workspace.CurrentCamera then
            workspace.CurrentCamera.CameraOcclusion = Enum.CameraOcclusion.Zoom
        end
        if notify then notify("Đã tắt No Clip Camera", "eye-off") end
    end
end

-- ==========================================================
-- SPYDER
-- ==========================================================
local function setupSpyderCharacter(character)
    spyderHRP = character:WaitForChild("HumanoidRootPart")
    spyderHumanoid = character:WaitForChild("Humanoid")
    spyderHumanoid.Died:Connect(function()
        spyderEnabled = false
        if spyderConnection then spyderConnection:Disconnect(); spyderConnection = nil end
    end)
end

if LocalPlayer.Character then setupSpyderCharacter(LocalPlayer.Character) end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if spyderEnabled then setupSpyderCharacter(char) end
end)

function Character.ToggleSpyder(state, notify)
    spyderEnabled = state
    if state then
        if not LocalPlayer.Character then
            if notify then notify("Không tìm thấy nhân vật!", "x") end
            spyderEnabled = false
            return
        end
        setupSpyderCharacter(LocalPlayer.Character)
        if spyderConnection then spyderConnection:Disconnect(); spyderConnection = nil end
        spyderConnection = RunService.RenderStepped:Connect(function()
            if not spyderEnabled or not spyderHRP or not spyderHumanoid then return end
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Blacklist
            params.FilterDescendantsInstances = {LocalPlayer.Character}
            local ray = workspace:Raycast(spyderHRP.Position, spyderHRP.CFrame.LookVector * 3, params)
            if ray then
                local moveDir = spyderHumanoid.MoveDirection
                if moveDir.Magnitude > 0.1 then
                    spyderHRP.AssemblyLinearVelocity = Vector3.new(
                        spyderHRP.AssemblyLinearVelocity.X,
                        18,
                        spyderHRP.AssemblyLinearVelocity.Z
                    )
                end
            end
        end)
        if notify then notify("Đã bật Spyder! Leo tường khi di chuyển", "zap") end
    else
        if spyderConnection then spyderConnection:Disconnect(); spyderConnection = nil end
        if notify then notify("Đã tắt Spyder!", "zap") end
    end
end

-- ==========================================================
-- INSTANT INTERACT
-- ==========================================================
function Character.ToggleInstantInteract(state, notify)
    if state then
        promptConn = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
            if prompt then fireproximityprompt(prompt) end
        end)
        clickConn = mouse.Button1Down:Connect(function()
            local target = mouse.Target
            if target then
                local cd = target:FindFirstChildOfClass("ClickDetector")
                if cd then fireclickdetector(cd) end
            end
        end)
        if notify then notify("Đã bật tương tác ngay!", "zap") end
    else
        if promptConn then promptConn:Disconnect(); promptConn = nil end
        if clickConn then clickConn:Disconnect(); clickConn = nil end
        if notify then notify("Đã tắt tương tác ngay!", "zap") end
    end
end

-- ==========================================================
-- CROSSHAIR
-- ==========================================================
local function drawPlus(pos, size, gap)
    lines[1].From = Vector2.new(pos.X - size, pos.Y)
    lines[1].To = Vector2.new(pos.X - gap, pos.Y)
    lines[2].From = Vector2.new(pos.X + gap, pos.Y)
    lines[2].To = Vector2.new(pos.X + size, pos.Y)
    lines[3].From = Vector2.new(pos.X, pos.Y - size)
    lines[3].To = Vector2.new(pos.X, pos.Y - gap)
    lines[4].From = Vector2.new(pos.X, pos.Y + gap)
    lines[4].To = Vector2.new(pos.X, pos.Y + size)
end

RunService.RenderStepped:Connect(function()
    if not crosshairEnabled then
        crosshair.Visible = false
        for _, l in pairs(lines) do l.Visible = false end
        return
    end
    local viewport = Camera.ViewportSize
    local center = viewport / 2
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("Head") then
        crosshair.Visible = false
        for _, l in pairs(lines) do l.Visible = false end
        return
    end
    local head = character.Head
    local distance = (Camera.CFrame.Position - head.Position).Magnitude
    local pos = center
    if distance > 1 then
        local offset = Camera.CFrame.RightVector * 3 + Camera.CFrame.UpVector * 1
        local worldPoint = Camera.CFrame.Position + Camera.CFrame.LookVector * 1000 + offset
        local screenPoint = Camera:WorldToViewportPoint(worldPoint)
        pos = Vector2.new(screenPoint.X, screenPoint.Y)
    end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local ray = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * 1000, rayParams)
    local enemyFound = false
    if ray and ray.Instance then
        local model = ray.Instance:FindFirstAncestorOfClass("Model")
        if model and Players:GetPlayerFromCharacter(model) then enemyFound = true end
    end
    if enemyFound then
        crosshair.Visible = false
        local size = crosshairSize * 4
        local gap = crosshairSize
        drawPlus(pos, size, gap)
        for _, l in pairs(lines) do l.Visible = true end
    else
        crosshair.Visible = true
        crosshair.Position = pos
        for _, l in pairs(lines) do l.Visible = false end
    end
end)

function Character.ToggleCrosshair(state, notify)
    crosshairEnabled = state
    if notify then notify(state and "Đã bật crosshair!" or "Đã tắt crosshair!", "target") end
end

function Character.SetCrosshairColor(color, notify)
    crosshairColor = color
    crosshair.Color = color
    for _, l in pairs(lines) do l.Color = color end
    if notify then notify("Đã đổi màu crosshair!", "palette") end
end

function Character.SetCrosshairSize(v)
    crosshairSize = v
    crosshair.Radius = v
end

-- ==========================================================
-- DESYNC
-- ==========================================================
local function createEsp(parent, color)
    if parent:FindFirstChild("DesyncEsp") then parent.DesyncEsp:Destroy() end
    local h = Instance.new("Highlight", parent)
    h.Name = "DesyncEsp"
    h.FillColor = color
    h.FillTransparency = 0.5
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    return h
end

function Character.ToggleDesync(state, notify)
    isDesynced = state
    if state then
        realChar = LocalPlayer.Character
        if not realChar then
            if notify then notify("Không tìm thấy nhân vật!", "x") end
            isDesynced = false
            return
        end
        createEsp(realChar, Color3.fromRGB(255, 0, 0))
        realChar.Archivable = true
        fakeChar = realChar:Clone()
        fakeChar.Name = "FakeNPC"
        fakeChar.Parent = workspace
        local oldAnim = fakeChar:FindFirstChild("Animate")
        if oldAnim then oldAnim:Destroy() end
        createEsp(fakeChar, Color3.fromRGB(0, 100, 255))
        local hrp = realChar:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = true end
        LocalPlayer.Character = fakeChar
        local fakeHum = fakeChar:FindFirstChild("Humanoid")
        if fakeHum then Camera.CameraSubject = fakeHum end
        task.wait(0.1)
        local realAnim = realChar:FindFirstChild("Animate")
        if realAnim then
            local newAnim = realAnim:Clone()
            newAnim.Parent = fakeChar
        end
        if notify then notify("Đã bật Desync! Nhân vật thật bị đóng băng", "zap") end
    else
        if not realChar or not fakeChar then return end
        if realChar:FindFirstChild("DesyncEsp") then realChar.DesyncEsp:Destroy() end
        if fakeChar:FindFirstChild("DesyncEsp") then fakeChar.DesyncEsp:Destroy() end
        local rHrp = realChar:FindFirstChild("HumanoidRootPart")
        local fHrp = fakeChar:FindFirstChild("HumanoidRootPart")
        if rHrp and fHrp then
            rHrp.Anchored = false
            rHrp.CFrame = fHrp.CFrame
        end
        LocalPlayer.Character = realChar
        local realHum = realChar:FindFirstChild("Humanoid")
        if realHum then Camera.CameraSubject = realHum end
        fakeChar:Destroy()
        fakeChar = nil
        if notify then notify("Đã tắt Desync!", "zap") end
    end
end

-- ==========================================================
-- INVISIBLE
-- ==========================================================
local function ApplyTransparency(char, turnOn)
    if not char then return end
    if turnOn then
        table.clear(OriginalProperties)
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA('BasePart') or part:IsA('Decal') or part:IsA('Texture') then
                if part.Name ~= "HumanoidRootPart" then
                    OriginalProperties[part] = { Transparency = part.Transparency }
                    part.Transparency = 0.75
                end
            elseif part:IsA('SelectionBox') or part:IsA('BoxHandleAdornment') or part:IsA('SelectionSphere') then
                OriginalProperties[part] = { Visible = part.Visible }
                part.Visible = false
            end
        end
    else
        for part, props in pairs(OriginalProperties) do
            if part and part.Parent then
                if part:IsA('BasePart') or part:IsA('Decal') or part:IsA('Texture') then
                    part.Transparency = props.Transparency
                elseif part:IsA('SelectionBox') or part:IsA('BoxHandleAdornment') or part:IsA('SelectionSphere') then
                    part.Visible = props.Visible
                end
            end
        end
    end
end

local function ToggleInvisible()
    IsInvisible = not IsInvisible
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if IsInvisible then
        if char then char.Name = FakeCharName end
        ApplyTransparency(char, true)
        pcall(function()
            LocalPlayer.GameplayPausePower = Enum.GameplayPausePower.None
            LocalPlayer.GameplayPaused = false
        end)
        if root then
            FocusPart = Instance.new("Part")
            FocusPart.Name = "InvisFocusAnchor"
            FocusPart.Anchored = true
            FocusPart.CanCollide = false
            FocusPart.Transparency = 1
            FocusPart.CFrame = root.CFrame
            FocusPart.Parent = workspace
            LocalPlayer.ReplicationFocus = FocusPart
        end
    else
        if char then char.Name = LocalPlayer.Name end
        ApplyTransparency(char, false)
        pcall(function() LocalPlayer.GameplayPausePower = Enum.GameplayPausePower.Default end)
        LocalPlayer.ReplicationFocus = nil
        if FocusPart then FocusPart:Destroy(); FocusPart = nil end
    end
    return IsInvisible
end

local function startInvisibleLoop()
    if invisConnection then invisConnection:Disconnect() end
    invisConnection = RunService.Heartbeat:Connect(function()
        if IsInvisible then
            local char = LocalPlayer.Character
            local rootPart = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if rootPart and humanoid and humanoid.Health > 0 then
                local currentCFrame = rootPart.CFrame
                local originalCamOffset = humanoid.CameraOffset
                if FocusPart then FocusPart.CFrame = currentCFrame end
                local invisPos = CFrame.new(1999, 1999, 0)
                local offsetPosition = invisPos:ToObjectSpace(currentCFrame).Position
                rootPart.CFrame = invisPos
                humanoid.CameraOffset = offsetPosition
                RunService.RenderStepped:Wait()
                if rootPart and rootPart.Parent then
                    rootPart.CFrame = currentCFrame
                    humanoid.CameraOffset = originalCamOffset
                end
            end
        end
    end)
end

local function stopInvisibleLoop()
    if invisConnection then invisConnection:Disconnect(); invisConnection = nil end
end

local function setupHotkey()
    if invKeybind then invKeybind:Disconnect() end
    invKeybind = LocalPlayer:GetMouse().KeyDown:Connect(function(key)
        if key == 'g' then
            ToggleInvisible()
        elseif key == 't' and IsInvisible then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = TestCoordinate end
        end
    end)
end

local function resetInvisibleState()
    IsInvisible = false
    LocalPlayer.ReplicationFocus = nil
    if FocusPart then FocusPart:Destroy(); FocusPart = nil end
    stopInvisibleLoop()
end

function Character.ToggleInvisible(state, notify)
    if state then
        startInvisibleLoop()
        setupHotkey()
        local result = ToggleInvisible()
        if notify then notify("Đã kích hoạt Invisible! (Hotkey: G)", "ghost") end
        return result
    else
        if IsInvisible then ToggleInvisible() end
        stopInvisibleLoop()
        resetInvisibleState()
        if invKeybind then invKeybind:Disconnect(); invKeybind = nil end
        if notify then notify("Đã tắt Invisible!", "ghost") end
    end
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    resetInvisibleState()
end)

-- ==========================================================
-- SHIFTLOCK
-- ==========================================================
local function enableShiftLock()
    if shiftlockActive then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    shiftlockActive = true
    if shiftlockButton then shiftlockButton.Image = States.On end
    if shiftlockCursor then
        shiftlockCursor.Visible = true
        shiftlockCursor.Size = UDim2.new(Character.shiftlockCursorSize, 0, Character.shiftlockCursorSize, 0)
    end
    hum.AutoRotate = false
    if shiftlockConnection then shiftlockConnection:Disconnect(); shiftlockConnection = nil end
    shiftlockConnection = RunService.RenderStepped:Connect(function()
        local character = LocalPlayer.Character
        if not character then enableShiftLock() end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end
        local cam = Camera
        rootPart.CFrame = CFrame.new(
            rootPart.Position,
            Vector3.new(
                cam.CFrame.LookVector.X * MaxLength,
                rootPart.Position.Y,
                cam.CFrame.LookVector.Z * MaxLength
            )
        )
        cam.CFrame = cam.CFrame * EnabledOffset
        cam.Focus = CFrame.fromMatrix(
            cam.Focus.Position,
            cam.CFrame.RightVector,
            cam.CFrame.UpVector
        ) * EnabledOffset
    end)
end

local function disableShiftLock()
    if not shiftlockActive then return end
    shiftlockActive = false
    if shiftlockButton then shiftlockButton.Image = States.Off end
    if shiftlockCursor then shiftlockCursor.Visible = false end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end
    local cam = Camera
    cam.CFrame = cam.CFrame * DisabledOffset
    if shiftlockConnection then shiftlockConnection:Disconnect(); shiftlockConnection = nil end
end

local function createShiftLockUI()
    if shiftlockUI then return end
    shiftlockUI = Instance.new("ScreenGui")
    shiftlockUI.Name = "Shiftlock (CoreGui)"
    shiftlockUI.Parent = CoreGui
    shiftlockUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    shiftlockUI.ResetOnSpawn = false
    shiftlockUI.Enabled = false
    
    shiftlockButton = Instance.new("ImageButton")
    shiftlockButton.Parent = shiftlockUI
    shiftlockButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    shiftlockButton.BackgroundTransparency = 1
    shiftlockButton.BorderSizePixel = 0
    shiftlockButton.Position = UDim2.new(0.7, 0, 0.75, 0)
    shiftlockButton.Size = UDim2.new(0.0636, 0, 0.0661, 0)
    shiftlockButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
    shiftlockButton.Image = States.Off
    
    shiftlockCursor = Instance.new("ImageLabel")
    shiftlockCursor.Name = "Shiftlock Cursor"
    shiftlockCursor.Parent = shiftlockUI
    shiftlockCursor.Image = shiftlockCursorID
    shiftlockCursor.Size = UDim2.new(Character.shiftlockCursorSize, 0, Character.shiftlockCursorSize, 0)
    shiftlockCursor.Position = UDim2.new(0.5, 0, 0.5, 0)
    shiftlockCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    shiftlockCursor.SizeConstraint = Enum.SizeConstraint.RelativeXX
    shiftlockCursor.BackgroundTransparency = 1
    shiftlockCursor.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    shiftlockCursor.Visible = false
    
    local cursorCorner = Instance.new("UICorner")
    cursorCorner.CornerRadius = UDim.new(0, 4)
    cursorCorner.Parent = shiftlockCursor
    
    shiftlockButton.MouseButton1Click:Connect(function()
        if shiftlockActive then disableShiftLock() else enableShiftLock() end
    end)
end

function Character.ToggleShiftLock(state, notify)
    shiftlockEnabled = state
    if state then
        if not shiftlockUI then createShiftLockUI() end
        if shiftlockUI then shiftlockUI.Enabled = true end
        if notify then notify("Đã hiện nút ShiftLock!", "lock") end
    else
        if shiftlockActive then disableShiftLock() end
        if shiftlockUI then shiftlockUI.Enabled = false end
        if notify then notify("Đã ẩn nút ShiftLock!", "lock") end
    end
end

function Character.SetShiftLockCursor(id, notify)
    if id:match("^%d+$") then
        shiftlockCursorID = "rbxassetid://" .. id
    elseif id:match("^rbxassetid://") or id:match("^rbxthumb://") or id:match("^rbxasset://") then
        shiftlockCursorID = id
    else
        if notify then notify("ID không hợp lệ!", "x") end
        return
    end
    if shiftlockCursor then shiftlockCursor.Image = shiftlockCursorID end
    if notify then notify("Đã cập nhật skin cursor!", "check") end
end

function Character.SetShiftLockCursorSize(v, notify)
    Character.shiftlockCursorSize = v / 100
    if shiftlockCursor then shiftlockCursor.Size = UDim2.new(Character.shiftlockCursorSize, 0, Character.shiftlockCursorSize, 0) end
    if notify then notify("Kích thước cursor: " .. v .. "x", "zap") end
end

LocalPlayer.CharacterAdded:Connect(function()
    if shiftlockActive then disableShiftLock() end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    if shiftlockActive then disableShiftLock() end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.L then
        if shiftlockActive then
            disableShiftLock()
        else
            if not shiftlockEnabled then
                if not shiftlockUI then createShiftLockUI() end
                shiftlockUI.Enabled = true
                shiftlockEnabled = true
            end
            enableShiftLock()
        end
    end
end)

-- ==========================================================
-- HIP HEIGHT
-- ==========================================================
local function updateHipHeight()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    if humanoid then
        if hipHeightEnabled then
            humanoid.HipHeight = Character.hipHeightValue
        else
            humanoid.HipHeight = 0
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    updateHipHeight()
end)

function Character.ToggleHipHeight(state, notify)
    hipHeightEnabled = state
    updateHipHeight()
    if notify then notify(state and "Đã kích hoạt độn chân" or "Đã tắt độn chân", "chevrons-up") end
end

function Character.SetHipHeightValue(v)
    Character.hipHeightValue = v
    if hipHeightEnabled then updateHipHeight() end
end

-- ==========================================================
-- PLATFORM
-- ==========================================================
local FloatGui = Instance.new("ScreenGui")
local UpButton = Instance.new("TextButton")
local DownButton = Instance.new("TextButton")
local UICornerUp = Instance.new("UICorner")
local UICornerDown = Instance.new("UICorner")

FloatGui.Name = "NoirFloatGui"
FloatGui.ResetOnSpawn = false
FloatGui.Enabled = false

UpButton.Name = "Up"
UpButton.Size = UDim2.new(0, 50, 0, 50)
UpButton.Position = UDim2.new(1, -115, 1, -270)
UpButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
UpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UpButton.Text = "↑ (E)"
UpButton.TextSize = 18
UpButton.Font = Enum.Font.SourceSansBold
UpButton.BackgroundTransparency = 0.3
UpButton.Parent = FloatGui
UICornerUp.CornerRadius = UDim.new(0, 12)
UICornerUp.Parent = UpButton

DownButton.Name = "Down"
DownButton.Size = UDim2.new(0, 50, 0, 50)
DownButton.Position = UDim2.new(1, -115, 1, -215)
DownButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DownButton.Text = "↓ (Q)"
DownButton.TextSize = 18
DownButton.Font = Enum.Font.SourceSansBold
DownButton.BackgroundTransparency = 0.3
DownButton.Parent = FloatGui
UICornerDown.CornerRadius = UDim.new(0, 12)
UICornerDown.Parent = DownButton

if syn and syn.protect_gui then
    syn.protect_gui(FloatGui)
    FloatGui.Parent = CoreGui
elseif gethui then
    FloatGui.Parent = gethui()
else
    FloatGui.Parent = CoreGui
end

local function moveFloat(amount)
    if floatPart then
        floatPart.Position = floatPart.Position + Vector3.new(0, amount, 0)
    end
end

function Character.TogglePlatform(state, notify)
    floatEnabled = state
    FloatGui.Enabled = state
    if state then
        floatPart = Instance.new("Part")
        floatPart.Size = Vector3.new(6, 0.5, 6)
        floatPart.Transparency = 1
        floatPart.Anchored = true
        floatPart.Material = Enum.Material.Glass
        floatPart.Parent = workspace
        floatConnection = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and floatPart then
                floatPart.CFrame = CFrame.new(root.Position.X, floatPart.Position.Y, root.Position.Z)
            end
        end)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then floatPart.Position = root.Position - Vector3.new(0, 3.1, 0) end
        if notify then notify("Đã bật Float (E: Lên | Q: Xuống)", "arrow-up-circle") end
    else
        if floatConnection then floatConnection:Disconnect() end
        if floatPart then floatPart:Destroy() floatPart = nil end
        if notify then notify("Đã tắt Float", "arrow-down-circle") end
    end
end

UpButton.MouseButton1Click:Connect(function() moveFloat(2.5) end)
DownButton.MouseButton1Click:Connect(function() moveFloat(-2.5) end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if floatEnabled and not gameProcessed then
        if input.KeyCode == Enum.KeyCode.E then
            moveFloat(5)
        elseif input.KeyCode == Enum.KeyCode.Q then
            moveFloat(-5)
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    if floatEnabled then
        task.wait(0.5)
        Character.TogglePlatform(false)
    end
end)

-- ==========================================================
-- PATH
-- ==========================================================
function Character.TogglePathButton(state, notify)
    pathEnabled = state
    if state then
        if not pathButtonGui then
            pathButtonGui = Instance.new("ScreenGui")
            pathButtonGui.Name = "NoirPathButton"
            pathButtonGui.ResetOnSpawn = false
            pathButtonGui.IgnoreGuiInset = true
            pathButtonGui.DisplayOrder = 999999999
            pathButtonGui.Parent = CoreGui
        end
        if not pathButton then
            pathButton = Instance.new("TextButton", pathButtonGui)
            pathButton.Size = UDim2.new(0, 60, 0, 40)
            pathButton.Position = UDim2.new(0, 220, 0, 200)
            pathButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            pathButton.BackgroundTransparency = 0.35
            pathButton.Text = "+"
            pathButton.TextColor3 = Color3.new(1, 1, 1)
            pathButton.Font = Enum.Font.GothamBold
            pathButton.TextSize = 25
            pathButton.Active = true
            pathButton.Draggable = Character.pathDraggable
            Instance.new("UICorner", pathButton).CornerRadius = UDim.new(0, 8)
            pathButton.MouseButton1Click:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local p = Instance.new("Part")
                    p.Size = Vector3.new(Character.pathSize, Character.pathThickness, Character.pathSize)
                    p.Position = LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(0, 3, 0)
                    p.Anchored = true
                    p.CanCollide = true
                    p.Transparency = 0.5
                    p.BrickColor = BrickColor.Random()
                    p.Parent = workspace
                    Debris:AddItem(p, Character.pathDuration)
                end
            end)
        end
        pathButton.Visible = true
        if notify then notify("Đã bật nút Path!", "plus") end
    else
        if pathButton then pathButton.Visible = false end
        if notify then notify("Đã tắt nút Path!", "plus") end
    end
end

function Character.SetPathSize(v) Character.pathSize = v end
function Character.SetPathThickness(v) Character.pathThickness = v end
function Character.SetPathDuration(v) Character.pathDuration = v end

function Character.SetPathDraggable(state, notify)
    Character.pathDraggable = state
    if pathButton then pathButton.Draggable = state end
    if notify then notify(state and "Đã bật kéo thả" or "Đã tắt kéo thả", "zap") end
end

return Character
