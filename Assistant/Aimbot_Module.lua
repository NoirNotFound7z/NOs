local Aimbot = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local notifyFn = nil

function Aimbot.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then notifyFn(title, content, icon) end
end

Aimbot.settings = {
    Enabled = false,
    NPCEnabled = false,
    TeamCheck = true,
    WallCheck = true,
    DeathCheck = true,
    FOVRadius = 200,
    Smoothness = 0.5,
    AimPart = "Head",
    Prediction = 0,
    LockSwitchDelay = 0.5,
}

local LockedTarget = nil
local LastVelocity = Vector3.new()
local LastSwitchTime = 0
local NPCList = {}

-- ==========================================================
-- FOV CIRCLE
-- ==========================================================
local FOVScreenGui = Instance.new("ScreenGui")
FOVScreenGui.IgnoreGuiInset = true
FOVScreenGui.ResetOnSpawn = false
pcall(function() FOVScreenGui.Parent = LocalPlayer.PlayerGui end)
if not FOVScreenGui.Parent then FOVScreenGui.Parent = game:GetService("CoreGui") end

local FOVCircle = Instance.new("Frame", FOVScreenGui)
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = false
FOVCircle.Size = UDim2.new(0, Aimbot.settings.FOVRadius * 2, 0, Aimbot.settings.FOVRadius * 2)
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", FOVCircle)
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(0, 255, 0)

function Aimbot.SetFOVVisible(v) FOVCircle.Visible = v end
function Aimbot.SetFOVColor(c) stroke.Color = c end
function Aimbot.SetFOVRadius(v)
    Aimbot.settings.FOVRadius = v
    FOVCircle.Size = UDim2.new(0, v * 2, 0, v * 2)
end

-- ==========================================================
-- RIG DETECTION
-- ==========================================================
function Aimbot.GetRig()
    local char = LocalPlayer.Character
    if not char then return "Unknown" end
    if char:FindFirstChild("UpperTorso") and char:FindFirstChild("LowerTorso") then return "R15" end
    if char:FindFirstChild("Torso") then return "R6" end
    return "Unknown"
end

function Aimbot.GetAimPartOptions()
    local rig = Aimbot.GetRig()
    if rig == "R15" then
        return {"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg"}
    elseif rig == "R6" then
        return {"Head","HumanoidRootPart","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
    end
    return {"Head","HumanoidRootPart","Torso"}
end

function Aimbot.SetAimPart(v)
    Aimbot.settings.AimPart = v
    LockedTarget = nil
    notify("Aim Part", "Đã chọn: " .. tostring(v), "target")
end

-- ==========================================================
-- TOGGLES
-- ==========================================================
function Aimbot.SetEnabled(v)
    Aimbot.settings.Enabled = v
    if not v and not Aimbot.settings.NPCEnabled then
        LockedTarget = nil
    end
    notify("Aimbot", v and "Đã bật Aimbot!" or "Đã tắt Aimbot!", "crosshair")
end

function Aimbot.SetNPCEnabled(v)
    Aimbot.settings.NPCEnabled = v
    if not v and not Aimbot.settings.Enabled then
        LockedTarget = nil
    end
    notify("Aimbot NPC", v and "Đã bật Aimbot NPC!" or "Đã tắt Aimbot NPC!", "users")
end

-- ==========================================================
-- TARGET LOGIC
-- ==========================================================
local function IsDead(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return true end
    return humanoid.Health <= 0
end

local function IsVisible(origin, targetPart)
    if not targetPart then return false end
    local direction = targetPart.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { LocalPlayer.Character, targetPart.Parent }
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(origin, direction, raycastParams)
    if not result then return true end
    if result.Instance:IsDescendantOf(targetPart.Parent) then return true end
    return false
end

local function IsSameTeam(player)
    if not LocalPlayer.Team or not player.Team then return false end
    return LocalPlayer.Team == player.Team
end

local function IsValidTarget(character, player)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp or not hrp.Parent then return false end
    if Aimbot.settings.DeathCheck and IsDead(character) then return false end
    if Aimbot.settings.TeamCheck and player and IsSameTeam(player) then return false end
    return true
end

local function RefreshNPCList()
    local list = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            if not Players:GetPlayerFromCharacter(obj) then
                table.insert(list, obj)
            end
        end
    end
    NPCList = list
end

task.spawn(function()
    while true do
        task.wait(0.5)
        RefreshNPCList()
    end
end)

local function GetClosestTarget()
    local closest = nil
    local shortest = Aimbot.settings.FOVRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    local function check(character, player)
        if not IsValidTarget(character, player) then return end
        local part = character:FindFirstChild(Aimbot.settings.AimPart)
        if not part then part = character:FindFirstChild("HumanoidRootPart") end
        if not part or not part.Parent then return end
        if Aimbot.settings.WallCheck then
            local origin = Camera.CFrame.Position
            if not IsVisible(origin, part) then return end
        end
        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then return end
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if dist < shortest and dist >= 5 then
            closest = part
            shortest = dist
        end
    end

    if Aimbot.settings.Enabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character.Parent then
                check(player.Character, player)
            end
        end
    end
    if Aimbot.settings.NPCEnabled then
        for _, npc in pairs(NPCList) do
            if npc and npc.Parent then check(npc, nil) end
        end
    end
    return closest
end

-- ==========================================================
-- AIMBOT LOOP (dùng BindToRenderStep priority > Camera mặc định)
-- ==========================================================
local aimbotBindName = "NoirAimbotCamera"

local function aimbotCameraStep()
    FOVCircle.Position = UDim2.new(0, Camera.ViewportSize.X / 2, 0, Camera.ViewportSize.Y / 2)

    if not (Aimbot.settings.Enabled or Aimbot.settings.NPCEnabled) then
        LockedTarget = nil
        return
    end

    if LockedTarget then
        if not IsValidTarget(LockedTarget.Parent, Players:GetPlayerFromCharacter(LockedTarget.Parent)) then
            LockedTarget = nil
        end
    end

    if not LockedTarget then
        LockedTarget = GetClosestTarget()
    else
        local newTarget = GetClosestTarget()
        if newTarget and newTarget ~= LockedTarget and (tick() - LastSwitchTime) >= Aimbot.settings.LockSwitchDelay then
            local function getScreenDist(part)
                if not part then return 1e9 end
                local pos = Camera:WorldToViewportPoint(part.Position)
                local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                return (Vector2.new(pos.X, pos.Y) - center).Magnitude
            end
            if getScreenDist(newTarget) + 30 < getScreenDist(LockedTarget) then
                LockedTarget = newTarget
                LastSwitchTime = tick()
            end
        end
    end

    if LockedTarget and LockedTarget.Parent then
        local targetPos = LockedTarget.Position
        local velocity = LockedTarget.AssemblyLinearVelocity or Vector3.new()
        local distance = (Camera.CFrame.Position - targetPos).Magnitude
        LastVelocity = LastVelocity:Lerp(velocity, 0.5)
        local dynamicPrediction = math.clamp(distance / 150, 0, 1) * Aimbot.settings.Prediction
        if distance > 10 then targetPos = targetPos + (LastVelocity * dynamicPrediction) end
        local camPos = Camera.CFrame.Position
        local targetCF = CFrame.new(camPos, targetPos)
        local smooth = math.clamp(Aimbot.settings.Smoothness, 0, 1)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, smooth)
    end
end

RunService:BindToRenderStep(aimbotBindName, Enum.RenderPriority.Camera.Value + 1, aimbotCameraStep)

-- ==========================================================
-- LOCK ON SYSTEM
-- ==========================================================
local LockOn = {
    Enabled = false,
    Mode = 1,
    CamSmooth = 0.85,
    CharSmooth = 1,
    CameraHeight = 0,
    LockedTarget = nil,
}

local MAX_DISTANCE = 100000
local SEARCH_DISTANCE = 10000
local CAMERA_LEFT_OFFSET = -1.27
local FULL_NECK_DISTANCE = 22
local FULL_ROOT_DISTANCE = 7
local SEARCH_RATE = 0.25

local PRIMARY_COLOR = Color3.fromRGB(138, 43, 226)

local lockScreenGui
local lockToggleBtn
local lockBillboard
local lastSearchTime = 0

Aimbot.LockOn = LockOn
Aimbot.OnLockOnToggleChanged = nil

local function initLockScreenGui()
    if lockScreenGui then lockScreenGui:Destroy() end
    lockScreenGui = Instance.new("ScreenGui")
    lockScreenGui.Name = "LockOnUI"
    lockScreenGui.ResetOnSpawn = false
    lockScreenGui.IgnoreGuiInset = true
    pcall(function() lockScreenGui.Parent = LocalPlayer.PlayerGui end)
    if not lockScreenGui.Parent then
        lockScreenGui.Parent = game:GetService("CoreGui")
    end
end

local function getTargetPart(character)
    return character and character:FindFirstChild("Head")
end

local function getNeckPosition(head)
    if not head then return nil end
    local char = head.Parent
    if not char then return nil end
    local neckAtt = head:FindFirstChild("NeckAttachment")
    if not neckAtt then
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if torso then
            neckAtt = torso:FindFirstChild("NeckAttachment")
        end
    end
    if neckAtt and neckAtt:IsA("Attachment") then return neckAtt.WorldPosition end
    return (head.CFrame * CFrame.new(0, -0.5, 0)).Position
end

local function isCameraMode() return LockOn.Mode == 1 or LockOn.Mode == 2 end
local function isCharacterMode() return LockOn.Mode == 2 or LockOn.Mode == 3 end
local function showBillboard() return LockOn.Mode ~= 3 end

local function getCameraLockPosition(targetPart)
    if not targetPart or not isCameraMode() then
        return getNeckPosition(targetPart)
    end
    local char = targetPart.Parent
    if not char then return getNeckPosition(targetPart) end
    local myChar = LocalPlayer.Character
    if not myChar then return getNeckPosition(targetPart) end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return getNeckPosition(targetPart) end
    local targetRoot = char:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return getNeckPosition(targetPart) end

    local neckPos = getNeckPosition(targetPart)
    local rootPos = targetRoot.Position
    local distance = (myRoot.Position - rootPos).Magnitude

    local basePos
    if distance >= FULL_NECK_DISTANCE then
        basePos = neckPos
    elseif distance <= FULL_ROOT_DISTANCE then
        basePos = rootPos
    else
        local t = (distance - FULL_ROOT_DISTANCE) / (FULL_NECK_DISTANCE - FULL_ROOT_DISTANCE)
        basePos = rootPos:Lerp(neckPos, t)
    end
    return basePos + Vector3.new(0, LockOn.CameraHeight, 0)
end

local function getLockAdornee(targetChar)
    if not targetChar or not showBillboard() then return nil end
    return targetChar:FindFirstChild("UpperTorso")
        or targetChar:FindFirstChild("Torso")
        or targetChar:FindFirstChild("HumanoidRootPart")
end

local function findClosestTarget()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest, minDist = nil, math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = { LocalPlayer.Character }
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude

    local nearbyParts = Workspace:GetPartBoundsInRadius(myRoot.Position, SEARCH_DISTANCE, overlapParams)
    local checkedModels = {}

    for _, part in ipairs(nearbyParts) do
        local char = part:FindFirstAncestorWhichIsA("Model")
        if char and not checkedModels[char] and char ~= LocalPlayer.Character then
            checkedModels[char] = true
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local targetPart = getTargetPart(char)
                if targetPart then
                    local neckPos = getNeckPosition(targetPart)
                    if neckPos then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(neckPos)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if dist < minDist then
                                minDist = dist
                                closest = targetPart
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function isValidLockTarget(targetPart)
    if not targetPart then return false end
    local char = targetPart.Parent
    if not char or not char:IsA("Model") then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if char == LocalPlayer.Character then return false end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        local neckPos = getNeckPosition(targetPart)
        if neckPos and (neckPos - myRoot.Position).Magnitude > MAX_DISTANCE then return false end
    end
    return true
end

local function forceInstantReset()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        Camera.CameraType = Enum.CameraType.Fixed
        Camera.CameraSubject = char.Humanoid
        Camera.CameraType = Enum.CameraType.Custom
    end
end

local function setupLockDeathHandler(character)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            if LockOn.Enabled then
                Aimbot.SetLockOnEnabled(false)
            end
        end)
    end
end

local function createLockToggleButton()
    if lockToggleBtn then lockToggleBtn:Destroy() end

    lockToggleBtn = Instance.new("ImageButton")
    lockToggleBtn.Size = UDim2.new(0, 85, 0, 85)
    lockToggleBtn.Position = UDim2.new(1, -95, 0, 10)
    lockToggleBtn.BackgroundTransparency = 1
    lockToggleBtn.Image = "rbxassetid://110432273832755"
    lockToggleBtn.ScaleType = Enum.ScaleType.Fit
    lockToggleBtn.Visible = false
    lockToggleBtn.Parent = lockScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = lockToggleBtn

    lockBillboard = Instance.new("BillboardGui")
    lockBillboard.Name = "LockOnIndicator"
    lockBillboard.StudsOffset = Vector3.new(0, 0, 0)
    lockBillboard.AlwaysOnTop = true
    lockBillboard.LightInfluence = 0
    lockBillboard.Enabled = false
    lockBillboard.Parent = lockScreenGui

    local indImage = Instance.new("ImageLabel")
    indImage.Size = UDim2.new(1, 0, 1, 0)
    indImage.BackgroundTransparency = 1
    indImage.Image = "rbxassetid://100230908593841"
    indImage.ImageTransparency = 0.1
    indImage.ImageColor3 = PRIMARY_COLOR
    indImage.Parent = lockBillboard

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indImage

    local dragging, dragStart, startPos
    lockToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = lockToggleBtn.Position
        end
    end)
    lockToggleBtn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            lockToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    lockToggleBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    lockToggleBtn.MouseButton1Click:Connect(function()
        Aimbot.SetLockOnEnabled(not LockOn.Enabled)
    end)
end

function Aimbot.SetLockOnEnabled(v)
    LockOn.Enabled = v

    if not v then
        LockOn.LockedTarget = nil
        if isCameraMode() then forceInstantReset() end
        if lockBillboard then lockBillboard.Enabled = false end
        if lockToggleBtn then
            lockToggleBtn.Image = "rbxassetid://110432273832755"
        end
    else
        LockOn.LockedTarget = findClosestTarget()
        if lockToggleBtn then
            lockToggleBtn.Image = "rbxassetid://139332620449694"
        end
    end

    if Aimbot.OnLockOnToggleChanged then
        Aimbot.OnLockOnToggleChanged(v)
    end
end

function Aimbot.SetLockOnMode(mode)
    LockOn.Mode = mode
    LockOn.LockedTarget = nil
    notify("Lock On", "Đã chọn chế độ " .. mode, "crosshair")
end

function Aimbot.SetLockOnCamSmooth(v) LockOn.CamSmooth = v end
function Aimbot.SetLockOnCharSmooth(v) LockOn.CharSmooth = v end
function Aimbot.SetLockOnCameraHeight(v) LockOn.CameraHeight = v end

function Aimbot.ShowLockOnButton()
    initLockScreenGui()
    createLockToggleButton()
    lockToggleBtn.Visible = true
end

function Aimbot.HideLockOnButton()
    if lockToggleBtn then
        lockToggleBtn:Destroy()
        lockToggleBtn = nil
    end
    if lockBillboard then
        lockBillboard:Destroy()
        lockBillboard = nil
    end
    if lockScreenGui then
        lockScreenGui:Destroy()
        lockScreenGui = nil
    end
end

local lockOnBindName = "NoirLockOnCamera"

local function lockOnStep()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local isLocking = LockOn.LockedTarget and LockOn.LockedTarget.Parent
            if isCharacterMode() then
                if isLocking then
                    humanoid.AutoRotate = false
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        local neckPos = getNeckPosition(LockOn.LockedTarget)
                        if neckPos then
                            local direction = neckPos - rootPart.Position
                            local horizontalDir = Vector3.new(direction.X, 0, direction.Z)
                            local mag = horizontalDir.Magnitude
                            if mag > 0.1 then
                                horizontalDir = horizontalDir / mag
                                local targetCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + horizontalDir)
                                rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, LockOn.CharSmooth)
                            end
                        end
                    end
                else
                    humanoid.AutoRotate = true
                end
            else
                humanoid.AutoRotate = true
            end
        end
    end

    if not LockOn.Enabled then
        if lockBillboard then lockBillboard.Enabled = false end
        return
    end

    local now = tick()
    if now - lastSearchTime > SEARCH_RATE then
        if not isValidLockTarget(LockOn.LockedTarget) then
            LockOn.LockedTarget = findClosestTarget()
        end
        lastSearchTime = now
    end

    if LockOn.LockedTarget and LockOn.LockedTarget.Parent and isCameraMode() then
        forceInstantReset()
        local lockPos = getCameraLockPosition(LockOn.LockedTarget)
        if lockPos then
            local rightVec = Camera.CFrame.RightVector
            local targetPos = lockPos - (rightVec * CAMERA_LEFT_OFFSET)
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, LockOn.CamSmooth)
        end
    end

    if LockOn.LockedTarget and LockOn.LockedTarget.Parent and showBillboard() then
        local characterTarget = LockOn.LockedTarget.Parent
        local adorneePart = getLockAdornee(characterTarget)
        if adorneePart then
            lockBillboard.Adornee = adorneePart
            lockBillboard.Enabled = true

            local scaleFactor = 5.0
            local humanoid = characterTarget:FindFirstChildOfClass("Humanoid")
            local headPart = LockOn.LockedTarget
            if humanoid and headPart and characterTarget:FindFirstChild("HumanoidRootPart") then
                local rootPart = characterTarget:FindFirstChild("HumanoidRootPart")
                local feetY = rootPart.Position.Y - humanoid.HipHeight
                local headTopY = headPart.Position.Y + (headPart.Size.Y / 2)
                scaleFactor = headTopY - feetY
            elseif adorneePart then
                scaleFactor = adorneePart.Size.Y * 2.5
            end
            scaleFactor = math.clamp(scaleFactor, 3.0, 10.0)

            local distance = (Camera.CFrame.Position - adorneePart.Position).Magnitude
            local distanceMultiplier = 1400 / (distance + 8)
            local finalSize = distanceMultiplier * scaleFactor
            lockBillboard.Size = UDim2.new(0, finalSize, 0, finalSize)
        else
            lockBillboard.Enabled = false
        end
    else
        if lockBillboard then lockBillboard.Enabled = false end
    end
end

RunService:BindToRenderStep(lockOnBindName, Enum.RenderPriority.Camera.Value + 2, lockOnStep)

if LocalPlayer.Character then
    setupLockDeathHandler(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupLockDeathHandler)

return Aimbot