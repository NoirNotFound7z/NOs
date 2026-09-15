local Movement = {}

local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- ==========================================================
-- STATE
-- ==========================================================
Movement.speedMode = "Classic"
Movement.walkspeed = 40
Movement.physicsSpeed = 80
Movement.jumppower = 100
Movement.dashLength = 10
Movement.dashByCamera = false
Movement.glitchPower = 100
Movement.autoJumpMode = "Normal"

local speedLoop = nil
local defaultSpeed = nil
local speedToggleState = false
local physicsBodyVelocity = nil
local physicsBodyGyro = nil
local glitchEnabled = false
local glitchLoop = nil
local jumpEnabled = false
local infJumpConnection = nil
local autoJumpConnection = nil
local dashGui = nil
local dashCooldown = false
local curveDashGui = nil
local RANGE = 30
local BEHIND_DISTANCE = 3.5
local SIDE_DISTANCE = 2.5
local DASH_TIME = 0.22
local CURVE_STRENGTH = 2.0
local RANDOM_SIDE = false

-- Fly
local isFlying = false
local flyConnection = nil
local flyVelocityHandler = nil
local flyOrientationHandler = nil
local flyAttachment = nil
local currentFlySpeed = 50
local flyIdleAnim = "rbxassetid://91106826233224"
local flyMoveAnim = "rbxassetid://114833664438028"

-- Vehicle Fly
local vflyEnabled = false
local vflySpeed = 5
local vflyConnection = nil
local vflyBodyVelocity = nil
local vflyBodyGyro = nil
local vflyTargetPart = nil
local vflyCanLookUpDown = true
local vflyDirectionLocked = false
local vflyLockedLookVector = Vector3.new(0, 0, -1)
local vflyRotationOffsetY = 0

-- Freecam
local freecamState = {
    active = false,
    speed = 1.0,
    movePart = nil,
    connection = nil,
    screenGui = nil,
    joystickContainer = nil,
    outer = nil,
    inner = nil,
    outerStroke = nil,
    innerStroke = nil,
    tpButton = nil,
    origMinZoom = nil,
    origMaxZoom = nil,
    currentPos = nil,
    dragging = false,
    activeTouch = nil,
    sizeOuter = 120,
    sizeInner = 50,
    joystickData = {
        DraggingLevel = 0,
        Direction = Vector3.new(0, 0, 0),
    },
}

-- ==========================================================
-- INTERNAL HELPERS
-- ==========================================================
local function stopPhysicsMode()
    if physicsBodyVelocity then physicsBodyVelocity:Destroy(); physicsBodyVelocity = nil end
    if physicsBodyGyro then physicsBodyGyro:Destroy(); physicsBodyGyro = nil end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.PlatformStand = false
    end
end

local function getAnimator(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    return animator, humanoid
end

local function playFlyAnimation(character, animId, looped)
    local animator, humanoid = getAnimator(character)
    if not animator then return nil end
    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
        if track.Name == "FlyAnim" then track:Stop() end
    end
    if not animId or animId == "" then return nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local track = animator:LoadAnimation(anim)
    track.Name = "FlyAnim"
    track.Looped = looped or true
    track.Priority = Enum.AnimationPriority.Action4
    track:Play()
    return track
end

-- ==========================================================
-- SPEED
-- ==========================================================
function Movement.ToggleSpeed(state, notify)
    speedToggleState = state
    if speedLoop then speedLoop:Disconnect(); speedLoop = nil end
    stopPhysicsMode()

    if not state then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = defaultSpeed or 16
        end
        if notify then notify("Speed disabled!", "zap") end
        return
    end

    if Movement.speedMode == "Classic" then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            if not defaultSpeed then defaultSpeed = char.Humanoid.WalkSpeed end
        end
        speedLoop = RunService.Heartbeat:Connect(function()
            if not speedToggleState then return end
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                local hum = character.Humanoid
                if hum.WalkSpeed ~= Movement.walkspeed then hum.WalkSpeed = Movement.walkspeed end
            end
        end)
        if notify then notify("Classic mode enabled!", "zap") end
    elseif Movement.speedMode == "Physics" then
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            if notify then notify("Character not found!", "x") end
            return
        end
        local hrp = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")
        hum.PlatformStand = true
        physicsBodyVelocity = Instance.new("BodyVelocity")
        physicsBodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
        physicsBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        physicsBodyVelocity.Parent = hrp
        physicsBodyGyro = Instance.new("BodyGyro")
        physicsBodyGyro.MaxTorque = Vector3.new(0, math.huge, 0)
        physicsBodyGyro.CFrame = hrp.CFrame
        physicsBodyGyro.Parent = hrp
        speedLoop = RunService.Heartbeat:Connect(function()
            if not speedToggleState then return end
            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChildOfClass("Humanoid") then return end
            local hum = character.Humanoid
            local hrp = character.HumanoidRootPart
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                physicsBodyVelocity.Velocity = moveDir * Movement.physicsSpeed
                physicsBodyGyro.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + moveDir)
            else
                physicsBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end)
        if notify then notify("Physics mode enabled!", "zap") end
    end
end

function Movement.SetSpeedMode(option)
    if option == "Classic (WalkSpeed)" then
        Movement.speedMode = "Classic"
        if Movement.walkspeed > 1500 then Movement.walkspeed = 1500 end
    elseif option == "Physics (BodyVelocity)" then
        Movement.speedMode = "Physics"
        if Movement.walkspeed > 150 then Movement.walkspeed = 150 end
    end
end

function Movement.ToggleSpeedGlitch(state, notify)
    glitchEnabled = state
    if state and speedToggleState then Movement.ToggleSpeed(false, notify) end
    if state then
        glitchLoop = RunService.Heartbeat:Connect(function()
            if not glitchEnabled then return end
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                local hum = char.Humanoid
                if hum.FloorMaterial == Enum.Material.Air then
                    hum.WalkSpeed = Movement.glitchPower
                else
                    if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
                end
            end
        end)
        if notify then notify("Speed glitch enabled!", "zap") end
    else
        if glitchLoop then glitchLoop:Disconnect(); glitchLoop = nil end
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = 16 end
        if notify then notify("Speed glitch disabled!", "zap") end
    end
end

-- ==========================================================
-- JUMP
-- ==========================================================
function Movement.ApplyJump()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = jumpEnabled and Movement.jumppower or 50
        end
    end
end

function Movement.SetJumpEnabled(state)
    jumpEnabled = state
    Movement.ApplyJump()
end

function Movement.ToggleInfJump(state, notify)
    if state then
        infJumpConnection = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        if notify then notify("Infinity jump enabled!", "arrow-up") end
    else
        if infJumpConnection then infJumpConnection:Disconnect(); infJumpConnection = nil end
        if notify then notify("Infinity jump disabled!", "arrow-up") end
    end
end

local function stopAutoJump()
    if autoJumpConnection then autoJumpConnection:Disconnect(); autoJumpConnection = nil end
end

function Movement.ToggleAutoJump(state, notify)
    if state then
        stopAutoJump()
        autoJumpConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if hum.FloorMaterial == Enum.Material.Air then return end
            if Movement.autoJumpMode == "Normal" then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            elseif Movement.autoJumpMode == "Smart" then
                if hum.MoveDirection.Magnitude > 0 then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            elseif Movement.autoJumpMode == "BHop" then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        if notify then notify("Auto jump enabled!", "arrow-up") end
    else
        stopAutoJump()
        if notify then notify("Auto jump disabled!", "arrow-up") end
    end
end

-- ==========================================================
-- DASH
-- ==========================================================
local function Dash()
    if dashCooldown then return end
    dashCooldown = true
    task.delay(0.3, function() dashCooldown = false end)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(0, 1e5, 0)
    bg.CFrame = hrp.CFrame
    local dir
    if Movement.dashByCamera then
        dir = Camera.CFrame.LookVector.Unit
    else
        local look = hrp.CFrame.LookVector
        dir = Vector3.new(look.X, 0, look.Z).Unit
    end
    local speed = Movement.dashLength / 0.05
    if Movement.dashByCamera then
        bv.Velocity = dir * speed
    else
        bv.Velocity = (dir * speed) + Vector3.new(0, 20, 0)
    end
    bv.Parent = hrp
    bg.Parent = hrp
    task.wait(0.05)
    bv:Destroy()
    bg:Destroy()
end

function Movement.ToggleDashButton(state, notify)
    if state then
        if dashGui then return end
        dashGui = Instance.new("ScreenGui")
        dashGui.Name = "NoirDashUI"
        dashGui.Parent = game.CoreGui
        dashGui.ResetOnSpawn = false
        dashGui.IgnoreGuiInset = true
        dashGui.DisplayOrder = 999999999

        local btn = Instance.new("TextButton")
        btn.Parent = dashGui
        btn.Size = UDim2.new(0, 75, 0, 75)
        btn.Position = UDim2.new(0.85, 0, 0.5, 0)
        btn.Text = ""
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = 0.3
        btn.Draggable = true
        btn.ZIndex = 2

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = btn

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(1, 0, 1, 0)
        icon.Position = UDim2.new(0.5, 0, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://10709797382"
        icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
        icon.ScaleType = Enum.ScaleType.Fit
        icon.Parent = btn

        btn.MouseButton1Click:Connect(Dash)
        if notify then notify("Dash enabled!", "zap") end
    else
        if dashGui then dashGui:Destroy(); dashGui = nil end
        if notify then notify("Dash disabled!", "zap") end
    end
end

local function getClosestTarget()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    local camera = workspace.CurrentCamera
    local bestTarget, bestScore = nil, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist <= RANGE then
                    local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        local score = screenDist + dist * 2
                        if score < bestScore then
                            bestScore = score
                            bestTarget = hrp
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

local function createRainbowTrail(root)
    local att0 = Instance.new("Attachment", root)
    local att1 = Instance.new("Attachment", root)
    att0.Position = Vector3.new(0, 0.5, 0)
    att1.Position = Vector3.new(0, -0.5, 0)
    local trail = Instance.new("Trail")
    trail.Attachment0 = att0
    trail.Attachment1 = att1
    trail.Lifetime = 0.3
    trail.MinLength = 0.1
    trail.FaceCamera = true
    trail.WidthScale = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(1, 0)
    }
    trail.Parent = root
    local hue = 0
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        if not trail or not trail.Parent then
            if conn then conn:Disconnect() end
            return
        end
        hue = hue + dt * 2
        local function c(o) return Color3.fromHSV((hue + o) % 1, 1, 1) end
        trail.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, c(0)),
            ColorSequenceKeypoint.new(0.2, c(0.2)),
            ColorSequenceKeypoint.new(0.4, c(0.4)),
            ColorSequenceKeypoint.new(0.6, c(0.6)),
            ColorSequenceKeypoint.new(0.8, c(0.8)),
            ColorSequenceKeypoint.new(1, c(1))
        }
    end)
    return trail, att0, att1, conn
end

local function curveDash(root, target)
    local trail, att0, att1, trailConn = createRainbowTrail(root)
    local startPos = root.Position
    local targetCF = target.CFrame
    local targetVel = target.Velocity or Vector3.zero
    local predictedPos = target.Position + targetVel * 0.1
    local distanceToTarget = (predictedPos - startPos).Magnitude
    local endPos
    local useSideDash = distanceToTarget > 7
    if useSideDash then
        local randomSide = RANDOM_SIDE and math.random(0, 1) or 0
        if randomSide == 0 then
            endPos = predictedPos + targetCF.RightVector * SIDE_DISTANCE
        else
            endPos = predictedPos - targetCF.RightVector * SIDE_DISTANCE
        end
    else
        endPos = predictedPos - targetCF.LookVector * BEHIND_DISTANCE
    end
    local rayOrigin = endPos + Vector3.new(0, 5, 0)
    local rayDirection = Vector3.new(0, -10, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if rayResult then
        endPos = Vector3.new(endPos.X, rayResult.Position.Y + 3, endPos.Z)
    else
        endPos = Vector3.new(endPos.X, startPos.Y, endPos.Z)
    end
    local function cubicBezier(t, p0, p1, p2, p3)
        local mt = 1 - t
        return mt^3 * p0 + 3 * mt^2 * t * p1 + 3 * mt * t^2 * p2 + t^3 * p3
    end
    local function easeInOut(t)
        return t < 0.5 and 4 * t * t * t or 1 - math.pow(-2 * t + 2, 3) / 2
    end
    local midDir = (endPos - startPos).Unit
    local perp = Vector3.new(-midDir.Z, 0, midDir.X)
    local curveDir = (math.random(0,1) == 0 and 1 or -1)
    local midOffset = perp * CURVE_STRENGTH * curveDir
    local mid1 = startPos:Lerp(endPos, 0.3) + midOffset
    local mid2 = startPos:Lerp(endPos, 0.6) + midOffset * 0.7
    local points = {startPos, mid1, mid2, endPos}
    local t = 0
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        t = t + dt / DASH_TIME
        if t >= 1 then
            conn:Disconnect()
            root.CFrame = CFrame.new(endPos)
            task.delay(0.3, function()
                if trail then trail:Destroy() end
                if att0 then att0:Destroy() end
                if att1 then att1:Destroy() end
                if trailConn then trailConn:Disconnect() end
            end)
            return
        end
        local smoothT = easeInOut(t)
        local pos = cubicBezier(smoothT, points[1], points[2], points[3], points[4])
        root.CFrame = CFrame.new(pos)
    end)
end

function Movement.ToggleCurveDash(state, notify)
    if state then
        if curveDashGui then return end
        curveDashGui = Instance.new("ScreenGui")
        curveDashGui.Name = "NoirCurveDashUI"
        curveDashGui.Parent = game.CoreGui
        curveDashGui.ResetOnSpawn = false
        curveDashGui.IgnoreGuiInset = true
        curveDashGui.DisplayOrder = 999999999

        local btn = Instance.new("TextButton")
        btn.Parent = curveDashGui
        btn.Size = UDim2.new(0, 75, 0, 75)
        btn.Position = UDim2.new(0.7, 0, 0.7, 0)
        btn.Text = ""
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = 0.3
        btn.Draggable = true
        btn.ZIndex = 2

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = btn

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(1, 0, 1, 0)
        icon.Position = UDim2.new(0.5, 0, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://96467707042169"
        icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
        icon.ScaleType = Enum.ScaleType.Fit
        icon.Parent = btn

        btn.MouseButton1Click:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local target = getClosestTarget()
            if not target then return end
            curveDash(root, target)
        end)
        if notify then notify("Curve dash enabled!", "zap") end
    else
        if curveDashGui then curveDashGui:Destroy(); curveDashGui = nil end
        if notify then notify("Curve dash disabled!", "zap") end
    end
end

function Movement.SetCurveStrength(v) CURVE_STRENGTH = v end
function Movement.SetRandomSide(state) RANDOM_SIDE = state end

function Movement.LockDragDashButtons(state)
    if dashGui then
        local btn = dashGui:FindFirstChildOfClass("TextButton")
        if btn then btn.Draggable = not state end
    end
    if curveDashGui then
        local btn = curveDashGui:FindFirstChildOfClass("TextButton")
        if btn then btn.Draggable = not state end
    end
end

-- ==========================================================
-- FLY
-- ==========================================================
function Movement.StopFlying(notify)
    isFlying = false
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if flyVelocityHandler then flyVelocityHandler:Destroy(); flyVelocityHandler = nil end
    if flyOrientationHandler then flyOrientationHandler:Destroy(); flyOrientationHandler = nil end
    if flyAttachment then flyAttachment:Destroy(); flyAttachment = nil end
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
        end
        local animator = getAnimator(character)
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                if track.Name == "FlyAnim" then track:Stop() end
            end
        end
    end
    if notify then notify("Đã tắt chế độ bay!", "rocket") end
end

function Movement.StartFlying(notify)
    local character = LocalPlayer.Character
    if not character then
        if notify then notify("Không tìm thấy nhân vật!", "x") end
        return
    end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then
        if notify then notify("Không tìm thấy HumanoidRootPart!", "x") end
        return
    end
    Movement.StopFlying(notify)
    isFlying = true
    playFlyAnimation(character, flyIdleAnim, true)
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    flyAttachment = Instance.new("Attachment")
    flyAttachment.Name = "FlyAttachment"
    flyAttachment.Parent = rootPart
    flyVelocityHandler = Instance.new("LinearVelocity")
    flyVelocityHandler.Name = "FlyVelocity"
    flyVelocityHandler.Attachment0 = flyAttachment
    flyVelocityHandler.MaxForce = 100000
    flyVelocityHandler.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    flyVelocityHandler.VectorVelocity = Vector3.new(0, 0, 0)
    flyVelocityHandler.Parent = rootPart
    flyOrientationHandler = Instance.new("AlignOrientation")
    flyOrientationHandler.Name = "FlyOrientation"
    flyOrientationHandler.Attachment0 = flyAttachment
    flyOrientationHandler.Mode = Enum.OrientationAlignmentMode.OneAttachment
    flyOrientationHandler.MaxTorque = 100000
    flyOrientationHandler.Responsiveness = 200
    flyOrientationHandler.CFrame = rootPart.CFrame
    flyOrientationHandler.Parent = rootPart
    local PlayerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    local controls = PlayerModule:GetControls()
    flyConnection = RunService.RenderStepped:Connect(function()
        if not character or not character.Parent or not humanoid or humanoid.Health <= 0 then
            Movement.StopFlying(notify)
            return
        end
        local camera = Camera
        local moveVector = controls:GetMoveVector()
        if moveVector.Magnitude > 0 then
            playFlyAnimation(character, flyMoveAnim, true)
            local camCFrame = camera.CFrame
            local flyDir = (camCFrame * CFrame.new(moveVector)).Position - camCFrame.Position
            flyVelocityHandler.VectorVelocity = flyDir.Unit * currentFlySpeed
            flyOrientationHandler.CFrame = camCFrame
        else
            playFlyAnimation(character, flyIdleAnim, true)
            flyVelocityHandler.VectorVelocity = Vector3.new(0, 0, 0)
            flyOrientationHandler.CFrame = camera.CFrame
        end
    end)
    if notify then notify("Đã bật chế độ bay!", "rocket") end
end

function Movement.SetFlySpeed(v) currentFlySpeed = v end
function Movement.SetFlyIdleAnim(id) flyIdleAnim = "rbxassetid://" .. id end
function Movement.SetFlyMoveAnim(id) flyMoveAnim = "rbxassetid://" .. id end

-- ==========================================================
-- VEHICLE FLY
-- ==========================================================
local function getFlyTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local seat = hum.SeatPart
    if seat and seat:IsA("VehicleSeat") then return seat end
    return hrp
end

function Movement.DisableVehicleFly(notify)
    vflyEnabled = false
    if vflyConnection then vflyConnection:Disconnect(); vflyConnection = nil end
    if vflyBodyVelocity then vflyBodyVelocity:Destroy(); vflyBodyVelocity = nil end
    if vflyBodyGyro then vflyBodyGyro:Destroy(); vflyBodyGyro = nil end
    vflyTargetPart = nil
    if notify then notify("Đã tắt Vehicle Fly!", "rocket") end
end

function Movement.EnableVehicleFly(notify)
    if vflyEnabled then return end
    local target = getFlyTarget()
    if not target then
        if notify then notify("Không tìm thấy target!", "x") end
        return
    end
    vflyEnabled = true
    vflyTargetPart = target
    vflyBodyVelocity = Instance.new("BodyVelocity")
    vflyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    vflyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    vflyBodyVelocity.Parent = target
    vflyBodyGyro = Instance.new("BodyGyro")
    vflyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    vflyBodyGyro.CFrame = target.CFrame
    vflyBodyGyro.Parent = target
    local PlayerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    local controls = PlayerModule:GetControls()
    vflyConnection = RunService.RenderStepped:Connect(function()
        if not vflyEnabled then return end
        local targetPart = getFlyTarget()
        if not targetPart or not targetPart.Parent then
            Movement.DisableVehicleFly(notify)
            return
        end
        vflyTargetPart = targetPart
        local moveDirection = Vector3.new(0, 0, 0)
        local rawInput = controls:GetMoveVector()
        if rawInput.Magnitude > 0 then
            local camCFrame = Camera.CFrame
            local look = camCFrame.LookVector * -rawInput.Z
            local side = camCFrame.RightVector * rawInput.X
            moveDirection = (look + side).Unit
        end
        if vflyBodyVelocity then
            vflyBodyVelocity.Velocity = moveDirection * (vflySpeed * 25)
        end
        local baseLook = vflyDirectionLocked and vflyLockedLookVector or Camera.CFrame.LookVector
        if not vflyCanLookUpDown then
            baseLook = Vector3.new(baseLook.X, 0, baseLook.Z)
            if baseLook.Magnitude < 0.01 then baseLook = Vector3.new(0, 0, -1) end
        end
        local customOffset = CFrame.Angles(0, math.rad(vflyRotationOffsetY), 0)
        if vflyBodyGyro then
            vflyBodyGyro.CFrame = CFrame.lookAt(targetPart.Position, targetPart.Position + baseLook) * customOffset
        end
    end)
    if notify then notify("Đã bật Vehicle Fly!", "rocket") end
end

function Movement.SetVehicleFlySpeed(v) vflySpeed = v end
function Movement.SetVehicleLookUpDown(state) vflyCanLookUpDown = state end

function Movement.SetVehicleDirectionLock(state)
    vflyDirectionLocked = state
    if state then
        vflyLockedLookVector = Camera.CFrame.LookVector
    end
end

function Movement.RotateVehicleY()
    vflyRotationOffsetY = (vflyRotationOffsetY + 45) % 360
    return vflyRotationOffsetY
end

function Movement.ResetVehicleRotation()
    vflyRotationOffsetY = 0
end

-- ==========================================================
-- FREECAM (MOVE PART AS CAMERA SUBJECT + JOYSTICK + TP)
-- ==========================================================
local FREECAM_THEME = {
    Bg = Color3.fromRGB(18, 18, 24),
    Card = Color3.fromRGB(30, 30, 40),
    Accent = Color3.fromRGB(138, 116, 249),
    AccentH = Color3.fromRGB(160, 140, 255),
    Border = Color3.fromRGB(55, 55, 70),
    Text = Color3.fromRGB(240, 240, 245),
}

local function buildFreecamGui()
    if freecamState.screenGui then return end

    local sg = Instance.new("ScreenGui")
    sg.Name = "NoirFreecamGui"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999999
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not sg.Parent then
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    freecamState.screenGui = sg

    -- Joystick container
    local jc = Instance.new("Frame")
    jc.Name = "JoystickContainer"
    jc.Size = UDim2.new(1, 0, 1, 0)
    jc.BackgroundTransparency = 1
    jc.Parent = sg
    freecamState.joystickContainer = jc

    local outer = Instance.new("Frame")
    outer.Name = "Outer"
    outer.Size = UDim2.fromOffset(freecamState.sizeOuter, freecamState.sizeOuter)
    outer.Position = UDim2.new(0.15, 0, 0.75, 0)
    outer.AnchorPoint = Vector2.new(0.5, 0.5)
    outer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    outer.BackgroundTransparency = 0.5
    outer.Parent = jc
    outer.ZIndex = 1
    outer.Active = true
    local oc = Instance.new("UICorner")
    oc.CornerRadius = UDim.new(1, 0)
    oc.Parent = outer
    local outerStroke = Instance.new("UIStroke")
    outerStroke.Color = FREECAM_THEME.Border
    outerStroke.Transparency = 0.5
    outerStroke.Thickness = 1.5
    outerStroke.Parent = outer
    freecamState.outer = outer
    freecamState.outerStroke = outerStroke

    local inner = Instance.new("Frame")
    inner.Name = "Inner"
    inner.Size = UDim2.fromOffset(freecamState.sizeInner, freecamState.sizeInner)
    inner.Position = UDim2.new(0.5, -freecamState.sizeInner/2, 0.5, -freecamState.sizeInner/2)
    inner.BackgroundColor3 = FREECAM_THEME.Accent
    inner.BackgroundTransparency = 0.2
    inner.Parent = outer
    inner.ZIndex = 2
    local ic = Instance.new("UICorner")
    ic.CornerRadius = UDim.new(1, 0)
    ic.Parent = inner
    local innerStroke = Instance.new("UIStroke")
    innerStroke.Color = Color3.fromRGB(0, 0, 0)
    innerStroke.Transparency = 0.8
    innerStroke.Thickness = 2
    innerStroke.Parent = inner
    freecamState.inner = inner
    freecamState.innerStroke = innerStroke

    -- TP button
    local tpBtn = Instance.new("TextButton")
    tpBtn.Name = "TPButton"
    tpBtn.Size = UDim2.new(0, 80, 0, 80)
    tpBtn.Position = UDim2.new(0.85, 0, 0.5, 0)
    tpBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    tpBtn.BackgroundColor3 = FREECAM_THEME.Card
    tpBtn.BackgroundTransparency = 0.15
    tpBtn.Text = ""
    tpBtn.AutoButtonColor = false
    tpBtn.Parent = sg
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1, 0)
    tc.Parent = tpBtn
    local tstroke = Instance.new("UIStroke")
    tstroke.Color = FREECAM_THEME.Accent
    tstroke.Transparency = 0.3
    tstroke.Thickness = 2
    tstroke.Parent = tpBtn

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0.5, 0, 0.4, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://10734955080"
    icon.ImageColor3 = FREECAM_THEME.Accent
    icon.Parent = tpBtn

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 16)
    label.Position = UDim2.new(0, 0, 0.85, 0)
    label.BackgroundTransparency = 1
    label.Text = "TP"
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextColor3 = FREECAM_THEME.Text
    label.Parent = tpBtn

    freecamState.tpButton = tpBtn

    -- TP button drag
    local tpDragging = false
    local tpDragStart, tpStartPos
    tpBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            tpDragging = true
            tpDragStart = input.Position
            tpStartPos = tpBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if tpDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - tpDragStart
            tpBtn.Position = UDim2.new(tpStartPos.X.Scale, tpStartPos.X.Offset + delta.X, tpStartPos.Y.Scale, tpStartPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            tpDragging = false
        end
    end)

    tpBtn.MouseEnter:Connect(function()
        TweenService:Create(tpBtn, TweenInfo.new(0.15), {BackgroundColor3 = FREECAM_THEME.AccentH}):Play()
    end)
    tpBtn.MouseLeave:Connect(function()
        TweenService:Create(tpBtn, TweenInfo.new(0.15), {BackgroundColor3 = FREECAM_THEME.Card}):Play()
    end)

    -- Joystick logic
    local radius = freecamState.sizeOuter / 2
    local center

    local function toV2(pos)
        return Vector2.new(pos.X, pos.Y)
    end

    local function updateCenter()
        center = Vector2.new(
            outer.AbsolutePosition.X + radius,
            outer.AbsolutePosition.Y + radius
        )
    end

    local function moveInner(posV2)
        local dir = posV2 - center
        local dist = math.min(dir.Magnitude, radius)
        local offset = dir.Magnitude > 0 and dir.Unit * dist or Vector2.new(0, 0)
        inner.Position = UDim2.new(0.5, offset.X - freecamState.sizeInner/2, 0.5, offset.Y - freecamState.sizeInner/2)

        local dragLevel = math.floor((dist / radius) * 100)
        local dir3 = Vector3.new(offset.X / radius, 0, offset.Y / radius)

        freecamState.joystickData.DraggingLevel = dragLevel
        freecamState.joystickData.Direction = dir3
    end

    local function animatePress()
        TweenService:Create(outer, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(freecamState.sizeOuter * 1.1, freecamState.sizeOuter * 1.1),
            BackgroundTransparency = 0.3
        }):Play()
        TweenService:Create(inner, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(freecamState.sizeInner * 1.2, freecamState.sizeInner * 1.2)
        }):Play()
    end

    local function animateRelease()
        TweenService:Create(outer, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(freecamState.sizeOuter, freecamState.sizeOuter),
            BackgroundTransparency = 0.5
        }):Play()
        TweenService:Create(inner, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(freecamState.sizeInner, freecamState.sizeInner)
        }):Play()
    end

    outer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not freecamState.dragging then
                updateCenter()
                freecamState.dragging = true
                freecamState.activeTouch = input
                moveInner(toV2(input.Position))
                animatePress()
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if freecamState.dragging and freecamState.activeTouch and input == freecamState.activeTouch then
            moveInner(toV2(input.Position))
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if freecamState.dragging and freecamState.activeTouch and input == freecamState.activeTouch then
            freecamState.dragging = false
            freecamState.activeTouch = nil
            inner.Position = UDim2.new(0.5, -freecamState.sizeInner/2, 0.5, -freecamState.sizeInner/2)
            freecamState.joystickData.DraggingLevel = 0
            freecamState.joystickData.Direction = Vector3.new(0, 0, 0)
            animateRelease()
        end
    end)

    -- TP button click
    tpBtn.MouseButton1Click:Connect(function()
        if not freecamState.active then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and freecamState.movePart then
            hrp.CFrame = CFrame.new(freecamState.movePart.Position)
        end
    end)
end

function Movement.SetFreecamEnabled(v, notify)
    if not freecamState.origMinZoom then
        freecamState.origMinZoom = LocalPlayer.CameraMinZoomDistance
        freecamState.origMaxZoom = LocalPlayer.CameraMaxZoomDistance
    end

    freecamState.active = v

    if v then
        buildFreecamGui()

        if not freecamState.movePart then
            local mp = Instance.new("Part")
            mp.Name = "NoirFreecamPart"
            mp.Size = Vector3.new(0, 0, 0)
            mp.Anchored = true
            mp.Transparency = 1
            mp.CanCollide = false
            mp.CanQuery = false
            mp.CanTouch = false
            mp.Parent = workspace
            mp.CFrame = Camera.CFrame
            freecamState.movePart = mp
        end

        freecamState.currentPos = Camera.CFrame.Position
        freecamState.movePart.CFrame = Camera.CFrame

        Camera.CameraSubject = freecamState.movePart
        Camera.CameraType = Enum.CameraType.Custom
        LocalPlayer.CameraMinZoomDistance = 0
        LocalPlayer.CameraMaxZoomDistance = 0

        if freecamState.joystickContainer then freecamState.joystickContainer.Visible = true end
        if freecamState.tpButton then freecamState.tpButton.Visible = true end

        if freecamState.connection then freecamState.connection:Disconnect() end
        freecamState.connection = RunService.RenderStepped:Connect(function(dt)
            if not freecamState.active then return end
            local dir = freecamState.joystickData.Direction
            local level = freecamState.joystickData.DraggingLevel

            if level > 1 then
                local moveSpeed = (level * 0.02) * freecamState.speed * 60
                local camCF = Camera.CFrame
                local moveDir = (camCF.LookVector * -dir.Z) + (camCF.RightVector * dir.X) + Vector3.new(0, dir.Y, 0)
                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit
                    freecamState.currentPos = freecamState.currentPos + moveDir * moveSpeed * dt
                end
            end

            local camLook = Camera.CFrame.LookVector
            local yaw = math.atan2(camLook.X, camLook.Z)
            if freecamState.movePart then
                freecamState.movePart.CFrame = CFrame.new(freecamState.currentPos) * CFrame.Angles(0, yaw, 0)
            end
        end)

        if notify then notify("Đã bật Freecam!", "camera") end
    else
        if freecamState.connection then
            freecamState.connection:Disconnect()
            freecamState.connection = nil
        end
        if freecamState.movePart then
            freecamState.movePart:Destroy()
            freecamState.movePart = nil
        end

        Camera.CameraType = Enum.CameraType.Custom
        Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") or nil
        LocalPlayer.CameraMinZoomDistance = freecamState.origMinZoom or 128
        LocalPlayer.CameraMaxZoomDistance = freecamState.origMaxZoom or 128

        if freecamState.joystickContainer then freecamState.joystickContainer.Visible = false end
        if freecamState.tpButton then freecamState.tpButton.Visible = false end

        freecamState.joystickData.DraggingLevel = 0
        freecamState.joystickData.Direction = Vector3.new(0, 0, 0)

        if notify then notify("Đã tắt Freecam!", "camera") end
    end
end

function Movement.SetFreecamSpeed(v)
    freecamState.speed = v
end

function Movement.GetFreecamEnabled()
    return freecamState.active
end

return Movement
