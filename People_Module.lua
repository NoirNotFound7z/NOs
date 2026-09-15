local People = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- ==========================================================
-- STATE
-- ==========================================================
People.selectedTarget = nil
People.selectedPlayer = nil
People.quickSwitchEnabled = true
People.aimMode = "camera"
People.camSensitivity = 0.35
People.charSensitivity = 0.5
People.aimKey = Enum.KeyCode.F
People.followSpeed = 20
People.orbitSpeed = 16
People.orbitRadius = 3
People.orbitHeight = 0
People.mimicPosition = "Sau"
People.mimicDistance = 3
People.mimicFollowSpeed = 16
People.mimicAnimSpeed = 1
People.selectedPosition = "Normal"
People.selectedMethod = "CFrame"
People.selectedShape = "Tron"

local isAiming = false
local aimTarget = nil
local cameraAim = false
local characterAim = false
local keyHeld = false
local isFollowing = false
local isOrbiting = false
local orbitAngle = 0
local orbitBodyVelocity = nil
local mimicEnabled = false
local mimicTarget = nil
local mimicConnection = nil
local loopTP = false

-- LockOn
local lockOnGui = nil
local lockOnBillboard = nil
local lockOnImage = nil

-- Nav
local navGui = nil
local navPrevBtn = nil
local navNextBtn = nil
local navRef = nil

-- Spectate
local isSpectating = false
local spectateIndex = 1
local specGui = nil
local specDisplayName, specUsername, specUserId, specAvatar
local specAge, specMembership, specUnder13, specVoice
local specDevice, specRes, specLocale, specSysLocale
local specPing, specFps, specMemory
local specTeam, specHealth, specDist, specState

-- ==========================================================
-- HELPERS
-- ==========================================================
function People.GetSelectedPlayer()
    if not People.selectedTarget then return nil end
    local obj = Players:FindFirstChild(People.selectedTarget)
    if obj and obj:IsA("Player") then return obj end
    People.selectedTarget = nil
    People.selectedPlayer = nil
    return nil
end

local function safeCharacter(p)
    if not p or not p:IsA("Player") then return nil end
    return p.Character
end

local function getTargetHRP(p)
    local c = safeCharacter(p)
    return c and c:FindFirstChild("HumanoidRootPart")
end

function People.CopyToClipboard(text)
    if setclipboard then
        pcall(function() setclipboard(tostring(text)) end)
    end
end

function People.GetAllPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p) end
    end
    return list
end

-- ==========================================================
-- TELEPORT
-- ==========================================================
function People.TpToPlayer(p)
    pcall(function()
        if not p or not p:IsA("Player") then return end
        local hrp1 = getTargetHRP(LocalPlayer)
        local hrp2 = getTargetHRP(p)
        if hrp1 and hrp2 then
            hrp1.CFrame = hrp2.CFrame * CFrame.new(2, 0, 2)
            return true
        end
        return false
    end)
end

function People.GetNearestPlayer()
    local best, bestDist = nil, math.huge
    local myHRP = getTargetHRP(LocalPlayer)
    if not myHRP then return nil end
    for _, p in ipairs(People.GetAllPlayers()) do
        local hrp = getTargetHRP(p)
        if hrp then
            local d = (myHRP.Position - hrp.Position).Magnitude
            if d < bestDist then bestDist = d; best = p end
        end
    end
    return best
end

function People.GetFarthestPlayer()
    local best, bestDist = nil, 0
    local myHRP = getTargetHRP(LocalPlayer)
    if not myHRP then return nil end
    for _, p in ipairs(People.GetAllPlayers()) do
        local hrp = getTargetHRP(p)
        if hrp then
            local d = (myHRP.Position - hrp.Position).Magnitude
            if d > bestDist then bestDist = d; best = p end
        end
    end
    return best
end

function People.SetSelectedPlayer(plr)
    if plr and plr:IsA("Player") then
        People.selectedTarget = plr.Name
        People.selectedPlayer = plr
        if isAiming then
            aimTarget = plr
            People.UpdateLockOn(aimTarget)
            if navRef then navRef:SetTarget(aimTarget.DisplayName) end
        end
        mimicTarget = plr
    end
end

function People.SetLoopTP(state)
    loopTP = state
    if state then
        task.spawn(function()
            while loopTP do
                local target = People.GetSelectedPlayer()
                if target then People.TpToPlayer(target) end
                task.wait(0.5)
            end
        end)
    end
end

-- ==========================================================
-- AIM
-- ==========================================================
function People.CreateLockOnIndicator()
    if lockOnGui then return end
    lockOnGui = Instance.new("ScreenGui")
    lockOnGui.Name = "LockOnIndicator"
    lockOnGui.ResetOnSpawn = false
    lockOnGui.Parent = CoreGui
    lockOnGui.Enabled = false
    
    lockOnBillboard = Instance.new("BillboardGui")
    lockOnBillboard.Size = UDim2.new(0, 80, 0, 80)
    lockOnBillboard.AlwaysOnTop = true
    lockOnBillboard.LightInfluence = 0
    lockOnBillboard.Parent = lockOnGui
    
    lockOnImage = Instance.new("ImageLabel")
    lockOnImage.Size = UDim2.new(1, 0, 1, 0)
    lockOnImage.BackgroundTransparency = 1
    lockOnImage.Image = "rbxassetid://100230908593841"
    lockOnImage.ImageColor3 = Color3.fromRGB(0, 255, 255)
    lockOnImage.Parent = lockOnBillboard
    
    task.spawn(function()
        local angle = 0
        while lockOnGui and lockOnGui.Enabled do
            angle = angle + 0.5
            if angle > 360 then angle = 0 end
            if lockOnImage then lockOnImage.Rotation = angle end
            task.wait(0.016)
        end
    end)
end

function People.UpdateLockOn(target)
    if not lockOnGui then People.CreateLockOnIndicator() end
    if target and target:IsA("Player") and target.Character then
        local adornee = target.Character:FindFirstChild("HumanoidRootPart") 
            or target.Character:FindFirstChild("UpperTorso") 
            or target.Character:FindFirstChild("Torso")
        if adornee then
            lockOnBillboard.Adornee = adornee
            lockOnGui.Enabled = true
            local hum = target.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                lockOnBillboard.StudsOffset = Vector3.new(0, hum.HipHeight * 0.5, 0)
            else
                lockOnBillboard.StudsOffset = Vector3.new(0, 0, 0)
            end
            return
        end
    end
    lockOnGui.Enabled = false
end

function People.DestroyLockOn()
    if lockOnGui then
        lockOnGui:Destroy()
        lockOnGui = nil
        lockOnBillboard = nil
        lockOnImage = nil
    end
end

local function getValidTargets()
    local targets = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then table.insert(targets, player) end
            end
        end
    end
    return targets
end

local function getNextTarget()
    local targets = getValidTargets()
    if #targets == 0 then return nil end
    if not aimTarget then return targets[1] end
    for i, player in ipairs(targets) do
        if player == aimTarget then return targets[(i % #targets) + 1] end
    end
    return targets[1]
end

local function getPrevTarget()
    local targets = getValidTargets()
    if #targets == 0 then return nil end
    if not aimTarget then return targets[#targets] end
    for i, player in ipairs(targets) do
        if player == aimTarget then return targets[((i - 2 + #targets) % #targets) + 1] end
    end
    return targets[#targets]
end

local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    if not player:IsA("Player") then return false end
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
end

local function getAimPosition(player)
    if not player or not player:IsA("Player") then return nil end
    local char = player.Character
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    if not head then return nil end
    local neckAtt = head:FindFirstChild("NeckAttachment")
    if neckAtt and neckAtt:IsA("Attachment") then return neckAtt.WorldPosition end
    return (head.CFrame * CFrame.new(0, -0.5, 0)).Position
end

local function resetCamera()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        Camera.CameraType = Enum.CameraType.Fixed
        Camera.CameraSubject = char.Humanoid
        Camera.CameraType = Enum.CameraType.Custom
    end
end

local function aimCamera(targetPos)
    if not targetPos then return end
    local rightVec = Camera.CFrame.RightVector
    local offsetPos = targetPos - (rightVec * 1.27)
    local targetCFrame = CFrame.new(Camera.CFrame.Position, offsetPos)
    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, People.camSensitivity)
end

local function aimCharacter(targetPlayer)
    if not targetPlayer or not targetPlayer:IsA("Player") then return end
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    local aimPos = getAimPosition(targetPlayer)
    if not aimPos then return end
    local direction = aimPos - rootPart.Position
    local horizontalDir = Vector3.new(direction.X, 0, direction.Z)
    local mag = horizontalDir.Magnitude
    if mag > 0.1 then
        horizontalDir = horizontalDir / mag
        local targetCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + horizontalDir)
        rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, People.charSensitivity)
    end
end

-- Nav buttons
function People.CreateAimNavButtons()
    if navGui then navGui:Destroy() end
    navGui = Instance.new("ScreenGui")
    navGui.Name = "AimNavButtons"
    navGui.ResetOnSpawn = false
    navGui.Parent = CoreGui
    navGui.Enabled = false
    navGui.IgnoreGuiInset = true
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 240, 0, 100)
    container.Position = UDim2.new(0.5, -120, 0.65, 0)
    container.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    container.BackgroundTransparency = 0.15
    container.BorderSizePixel = 0
    container.Parent = navGui
    
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 14)
    local cs = Instance.new("UIStroke", container)
    cs.Color = Color3.fromRGB(138, 116, 249)
    cs.Thickness = 1.5
    cs.Transparency = 0.3
    
    local targetLabel = Instance.new("TextLabel")
    targetLabel.Size = UDim2.new(1, -20, 0, 30)
    targetLabel.Position = UDim2.new(0, 10, 0, 8)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = "No Target"
    targetLabel.TextColor3 = Color3.fromRGB(200, 190, 255)
    targetLabel.TextSize = 15
    targetLabel.Font = Enum.Font.GothamBold
    targetLabel.TextXAlignment = Enum.TextXAlignment.Center
    targetLabel.Parent = container
    
    local counter = Instance.new("TextLabel")
    counter.Size = UDim2.new(1, -20, 0, 16)
    counter.Position = UDim2.new(0, 10, 0, 36)
    counter.BackgroundTransparency = 1
    counter.Text = "0 / 0"
    counter.TextColor3 = Color3.fromRGB(150, 140, 180)
    counter.TextSize = 11
    counter.Font = Enum.Font.Gotham
    counter.Parent = container
    
    local prevBtn = Instance.new("TextButton")
    prevBtn.Size = UDim2.new(0, 70, 0, 36)
    prevBtn.Position = UDim2.new(0, 15, 1, -46)
    prevBtn.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
    prevBtn.BackgroundTransparency = 0.1
    prevBtn.Text = "◀"
    prevBtn.TextColor3 = Color3.fromRGB(200, 190, 255)
    prevBtn.TextSize = 18
    prevBtn.Font = Enum.Font.GothamBold
    prevBtn.AutoButtonColor = false
    prevBtn.Parent = container
    Instance.new("UICorner", prevBtn).CornerRadius = UDim.new(0, 8)
    local ps = Instance.new("UIStroke", prevBtn)
    ps.Color = Color3.fromRGB(138, 116, 249)
    ps.Thickness = 1.5
    ps.Transparency = 0.4
    
    local nextBtn = Instance.new("TextButton")
    nextBtn.Size = UDim2.new(0, 70, 0, 36)
    nextBtn.Position = UDim2.new(1, -85, 1, -46)
    nextBtn.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
    nextBtn.BackgroundTransparency = 0.1
    nextBtn.Text = "▶"
    nextBtn.TextColor3 = Color3.fromRGB(200, 190, 255)
    nextBtn.TextSize = 18
    nextBtn.Font = Enum.Font.GothamBold
    nextBtn.AutoButtonColor = false
    nextBtn.Parent = container
    Instance.new("UICorner", nextBtn).CornerRadius = UDim.new(0, 8)
    local ns = Instance.new("UIStroke", nextBtn)
    ns.Color = Color3.fromRGB(138, 116, 249)
    ns.Thickness = 1.5
    ns.Transparency = 0.4
    
    navPrevBtn = prevBtn
    navNextBtn = nextBtn
    
    local ref = {}
    function ref:SetTarget(name) targetLabel.Text = name or "No Target" end
    function ref:SetCounter(c, t) counter.Text = c .. " / " .. t end
    return ref
end

function People.UpdateNavButtons(state)
    if state then
        if not navRef then navRef = People.CreateAimNavButtons() end
        navGui.Enabled = true
        if aimTarget then navRef:SetTarget(aimTarget.DisplayName) else navRef:SetTarget("No Target") end
        local targets = getValidTargets()
        local idx = 0
        for i, p in ipairs(targets) do if p == aimTarget then idx = i break end end
        navRef:SetCounter(idx, #targets)
    else
        if navGui then navGui.Enabled = false end
    end
end

local function onPrevClick()
    if not isAiming or not People.quickSwitchEnabled then return end
    local prev = getPrevTarget()
    if prev then
        aimTarget = prev
        People.UpdateLockOn(aimTarget)
        if navRef then navRef:SetTarget(aimTarget.DisplayName) end
        local targets = getValidTargets()
        local idx = 0
        for i, p in ipairs(targets) do if p == aimTarget then idx = i break end end
        if navRef then navRef:SetCounter(idx, #targets) end
    end
end

local function onNextClick()
    if not isAiming or not People.quickSwitchEnabled then return end
    local next = getNextTarget()
    if next then
        aimTarget = next
        People.UpdateLockOn(aimTarget)
        if navRef then navRef:SetTarget(aimTarget.DisplayName) end
        local targets = getValidTargets()
        local idx = 0
        for i, p in ipairs(targets) do if p == aimTarget then idx = i break end end
        if navRef then navRef:SetCounter(idx, #targets) end
    end
end

function People.ToggleAim(state)
    isAiming = state
    if state then
        People.CreateLockOnIndicator()
        local p = People.GetSelectedPlayer()
        if p then
            aimTarget = p
            People.UpdateLockOn(aimTarget)
            if navRef then navRef:SetTarget(aimTarget.DisplayName) end
        else
            aimTarget = nil
        end
        if People.quickSwitchEnabled then People.UpdateNavButtons(true) else if navGui then navGui.Enabled = false end end
    else
        aimTarget = nil
        People.DestroyLockOn()
        People.UpdateNavButtons(false)
        if cameraAim or People.aimMode == "camera" or People.aimMode == "both" then resetCamera() end
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then char.Humanoid.AutoRotate = true end
    end
end

-- ==========================================================
-- FOLLOW
-- ==========================================================
local function doFollow(target, myRoot)
    if not target or not target:IsA("Player") or not myRoot then return end
    local targetRoot = getTargetHRP(target)
    if not targetRoot then return end
    local direction = (targetRoot.Position - myRoot.Position).Unit
    local distance = (targetRoot.Position - myRoot.Position).Magnitude
    if distance > 3 then
        myRoot.Velocity = direction * People.followSpeed
    else
        myRoot.Velocity = Vector3.zero
    end
end

function People.ToggleFollow(state)
    isFollowing = state
end

-- ==========================================================
-- ORBIT
-- ==========================================================
local function getOrbitOffset()
    local radius = People.orbitRadius
    local height = People.orbitHeight
    local angSpeed = math.rad(People.orbitSpeed)
    orbitAngle = orbitAngle + angSpeed * 0.1
    
    if People.selectedPosition == "Sau lung" then return Vector3.new(0, height, radius) end
    if People.selectedPosition == "Truoc mat" then return Vector3.new(0, height, -radius) end
    if People.selectedPosition == "Tren dau" then return Vector3.new(0, radius + 2, 0) end
    if People.selectedPosition == "Duoi chan" then return Vector3.new(0, -radius - 2, 0) end
    
    if People.selectedShape == "Tron" then
        return Vector3.new(math.cos(orbitAngle) * radius, height, math.sin(orbitAngle) * radius)
    elseif People.selectedShape == "Elip" then
        return Vector3.new(math.cos(orbitAngle) * radius * 1.5, height, math.sin(orbitAngle) * radius * 0.7)
    elseif People.selectedShape == "So 8" then
        return Vector3.new(radius * math.sin(orbitAngle), height, radius * math.sin(2 * orbitAngle) * 0.7)
    elseif People.selectedShape == "Xoan oc" then
        local sr = radius * (1 + 0.5 * math.sin(orbitAngle * 2))
        return Vector3.new(math.cos(orbitAngle) * sr, height, math.sin(orbitAngle) * sr)
    end
    return Vector3.new(0, height, 0)
end

local function orbitWithCFrame(target, myRoot)
    if not target or not target:IsA("Player") or not myRoot then return end
    local targetRoot = getTargetHRP(target)
    if not targetRoot then return end
    local worldOffset = targetRoot.CFrame:VectorToWorldSpace(getOrbitOffset())
    local targetPos = targetRoot.Position + worldOffset
    myRoot.CFrame = CFrame.new(targetPos, targetRoot.Position)
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = false end
end

local function orbitWithLerp(target, myRoot)
    if not target or not target:IsA("Player") or not myRoot then return end
    local targetRoot = getTargetHRP(target)
    if not targetRoot then return end
    local worldOffset = targetRoot.CFrame:VectorToWorldSpace(getOrbitOffset())
    local targetPos = targetRoot.Position + worldOffset
    myRoot.CFrame = myRoot.CFrame:Lerp(CFrame.new(targetPos, targetRoot.Position), 0.3)
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = false end
end

local function orbitWithBodyVelocity(target, myRoot)
    if not target or not target:IsA("Player") or not myRoot then return end
    local targetRoot = getTargetHRP(target)
    if not targetRoot then return end
    local worldOffset = targetRoot.CFrame:VectorToWorldSpace(getOrbitOffset())
    local targetPos = targetRoot.Position + worldOffset
    if not orbitBodyVelocity or orbitBodyVelocity.Parent ~= myRoot then
        if orbitBodyVelocity then orbitBodyVelocity:Destroy() end
        orbitBodyVelocity = Instance.new("BodyVelocity")
        orbitBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        orbitBodyVelocity.P = 100000
        orbitBodyVelocity.Parent = myRoot
    end
    orbitBodyVelocity.Velocity = (targetPos - myRoot.Position) * 10
    myRoot.CFrame = CFrame.new(myRoot.Position, targetRoot.Position)
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = false end
end

function People.StopOrbit()
    if orbitBodyVelocity then orbitBodyVelocity:Destroy(); orbitBodyVelocity = nil end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end
end

function People.ToggleOrbit(state)
    isOrbiting = state
    if not state then People.StopOrbit() end
end

-- ==========================================================
-- MIMIC
-- ==========================================================
local function getAnimator(character)
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    return animator
end

local function getAnimationTracks(animator)
    local tracks = {}
    if animator then
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            table.insert(tracks, track)
        end
    end
    return tracks
end

local function getMimicPosition(targetRoot, myRoot, position, distance)
    if not targetRoot or not myRoot then return myRoot.Position end
    local targetPos = targetRoot.Position
    local targetCF = targetRoot.CFrame
    local forward = targetCF.LookVector
    local right = targetCF.RightVector
    local up = targetCF.UpVector
    
    if position == "Sau" then return targetPos - forward * distance end
    if position == "Truoc" then return targetPos + forward * distance end
    if position == "Trai" then return targetPos - right * distance end
    if position == "Phai" then return targetPos + right * distance end
    if position == "Above" then return targetPos + up * distance end
    return targetPos
end

function People.UpdateMimic()
    if not mimicEnabled then return end
    local target = mimicTarget
    if not target or not target:IsA("Player") then return end
    
    local targetChar = target.Character
    local myChar = LocalPlayer.Character
    if not targetChar or not myChar then return end
    
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
    local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
    if not targetRoot or not myRoot or not targetHumanoid or not myHumanoid then return end
    
    local targetPos = getMimicPosition(targetRoot, myRoot, People.mimicPosition, People.mimicDistance)
    
    local targetState = targetHumanoid:GetState()
    local myState = myHumanoid:GetState()
    local isTargetJumping = targetState == Enum.HumanoidStateType.Jumping or targetState == Enum.HumanoidStateType.Freefall
    
    if isTargetJumping and myState ~= Enum.HumanoidStateType.Jumping and myState ~= Enum.HumanoidStateType.Freefall then
        myHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    
    local currentPos = myRoot.Position
    local direction = (targetPos - currentPos).Unit
    local distance = (targetPos - currentPos).Magnitude
    
    if distance > 0.5 then
        local bv = myRoot:FindFirstChild("MimicVelocity")
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "MimicVelocity"
            bv.MaxForce = Vector3.new(4000, 4000, 4000)
            bv.P = 1000
            bv.Parent = myRoot
        end
        bv.Velocity = direction * math.min(People.mimicFollowSpeed, distance * 10)
    else
        local bv = myRoot:FindFirstChild("MimicVelocity")
        if bv then bv:Destroy() end
        myRoot.CFrame = CFrame.new(targetPos, targetRoot.Position)
    end
    
    local targetLook = targetRoot.CFrame.LookVector
    local targetLookHorizontal = Vector3.new(targetLook.X, 0, targetLook.Z).Unit
    if targetLookHorizontal.Magnitude > 0.1 then
        local targetCF = CFrame.lookAt(myRoot.Position, myRoot.Position + targetLookHorizontal)
        myRoot.CFrame = CFrame.new(myRoot.Position, targetCF.Position + targetCF.LookVector)
    end
    
    local targetAnimator = getAnimator(targetChar)
    local myAnimator = getAnimator(myChar)
    if targetAnimator and myAnimator then
        local targetTracks = getAnimationTracks(targetAnimator)
        for _, track in pairs(getAnimationTracks(myAnimator)) do
            local shouldKeep = false
            for _, targetTrack in pairs(targetTracks) do
                if targetTrack.IsPlaying and track.Animation.AnimationId == targetTrack.Animation.AnimationId then
                    shouldKeep = true
                    break
                end
            end
            if not shouldKeep then
                pcall(function() track:Stop() end)
            end
        end
        for _, targetTrack in pairs(targetTracks) do
            if targetTrack.IsPlaying then
                local found = false
                for _, myTrack in pairs(getAnimationTracks(myAnimator)) do
                    if myTrack.Animation.AnimationId == targetTrack.Animation.AnimationId and myTrack.IsPlaying then
                        found = true
                        pcall(function()
                            myTrack.TimePosition = targetTrack.TimePosition
                            myTrack.Speed = targetTrack.Speed * People.mimicAnimSpeed
                        end)
                        break
                    end
                end
                if not found then
                    pcall(function()
                        local anim = Instance.new("Animation")
                        anim.AnimationId = targetTrack.Animation.AnimationId
                        local newTrack = myAnimator:LoadAnimation(anim)
                        newTrack:Play()
                        newTrack.TimePosition = targetTrack.TimePosition
                        newTrack.Speed = targetTrack.Speed * People.mimicAnimSpeed
                        newTrack.Looped = targetTrack.Looped
                        newTrack.Priority = targetTrack.Priority
                    end)
                end
            end
        end
    end
    
    myHumanoid.WalkSpeed = targetHumanoid.WalkSpeed
    myHumanoid.JumpPower = targetHumanoid.JumpPower
end

function People.StopMimic()
    mimicEnabled = false
    if mimicConnection then
        mimicConnection:Disconnect()
        mimicConnection = nil
    end
    local myChar = LocalPlayer.Character
    if myChar then
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if myRoot then
            local bv = myRoot:FindFirstChild("MimicVelocity")
            if bv then bv:Destroy() end
        end
        local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
        if myHumanoid then
            myHumanoid.WalkSpeed = 16
            myHumanoid.JumpPower = 50
        end
        local myAnimator = getAnimator(myChar)
        if myAnimator then
            for _, track in pairs(getAnimationTracks(myAnimator)) do
                pcall(function() track:Stop() end)
            end
        end
    end
end

function People.ToggleMimic(state)
    if state then
        local p = People.GetSelectedPlayer()
        if not p or not p.Character then
            return false
        end
        mimicTarget = p
        mimicEnabled = true
        if mimicConnection then
            mimicConnection:Disconnect()
            mimicConnection = nil
        end
        mimicConnection = RunService.Heartbeat:Connect(function()
            if mimicEnabled then People.UpdateMimic() end
        end)
        return true
    else
        People.StopMimic()
        return true
    end
end

-- ==========================================================
-- SPECTATE
-- ==========================================================
local spectateInfoRefs = {}

function People.GetSpectatePlayerAtIndex(index)
    local list = People.GetAllPlayers()
    if #list == 0 then return nil end
    if index < 1 then index = #list end
    if index > #list then index = 1 end
    return list[index]
end

function People.CreateSpectateGUI()
    if specGui then return end
    
    specGui = Instance.new("ScreenGui")
    specGui.Enabled = false
    specGui.Name = "NoirSpectate"
    specGui.Parent = CoreGui
    specGui.ResetOnSpawn = false
    specGui.IgnoreGuiInset = true
    specGui.DisplayOrder = 999999
    
    local specFrame = Instance.new("Frame")
    specFrame.Size = UDim2.new(0, 340, 0, 300)
    specFrame.Position = UDim2.new(1, -355, 0.05, 0)
    specFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    specFrame.BackgroundTransparency = 0.05
    specFrame.BorderSizePixel = 0
    specFrame.Parent = specGui
    
    Instance.new("UICorner", specFrame).CornerRadius = UDim.new(0, 12)
    
    local specStroke = Instance.new("UIStroke", specFrame)
    specStroke.Color = Color3.fromRGB(138, 116, 249)
    specStroke.Thickness = 1.5
    specStroke.Transparency = 0.3
    
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 90)
    headerFrame.BackgroundTransparency = 1
    headerFrame.Parent = specFrame
    
    specAvatar = Instance.new("ImageLabel")
    specAvatar.Size = UDim2.new(0, 65, 0, 65)
    specAvatar.Position = UDim2.new(0, 14, 0, 12)
    specAvatar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    specAvatar.BorderSizePixel = 0
    specAvatar.Parent = headerFrame
    Instance.new("UICorner", specAvatar).CornerRadius = UDim.new(1, 0)
    
    local avatarStroke = Instance.new("UIStroke", specAvatar)
    avatarStroke.Color = Color3.fromRGB(138, 116, 249)
    avatarStroke.Thickness = 2
    
    specDisplayName = Instance.new("TextLabel")
    specDisplayName.Size = UDim2.new(1, -95, 0, 24)
    specDisplayName.Position = UDim2.new(0, 90, 0, 8)
    specDisplayName.BackgroundTransparency = 1
    specDisplayName.Text = "No Target"
    specDisplayName.TextColor3 = Color3.fromRGB(255, 255, 255)
    specDisplayName.Font = Enum.Font.GothamBlack
    specDisplayName.TextSize = 18
    specDisplayName.TextXAlignment = Enum.TextXAlignment.Left
    specDisplayName.TextTruncate = Enum.TextTruncate.AtEnd
    specDisplayName.Parent = headerFrame
    
    specUsername = Instance.new("TextButton")
    specUsername.Size = UDim2.new(1, -95, 0, 16)
    specUsername.Position = UDim2.new(0, 90, 0, 34)
    specUsername.BackgroundTransparency = 1
    specUsername.Text = "@username (click)"
    specUsername.TextColor3 = Color3.fromRGB(140, 140, 160)
    specUsername.Font = Enum.Font.Gotham
    specUsername.TextSize = 12
    specUsername.TextXAlignment = Enum.TextXAlignment.Left
    specUsername.AutoButtonColor = false
    specUsername.Parent = headerFrame
    
    specUserId = Instance.new("TextButton")
    specUserId.Size = UDim2.new(1, -95, 0, 16)
    specUserId.Position = UDim2.new(0, 90, 0, 52)
    specUserId.BackgroundTransparency = 1
    specUserId.Text = "ID: 0 (click)"
    specUserId.TextColor3 = Color3.fromRGB(200, 180, 255)
    specUserId.Font = Enum.Font.Gotham
    specUserId.TextSize = 12
    specUserId.TextXAlignment = Enum.TextXAlignment.Left
    specUserId.AutoButtonColor = false
    specUserId.Parent = headerFrame
    
    local headerDivider = Instance.new("Frame")
    headerDivider.Size = UDim2.new(1, -28, 0, 1)
    headerDivider.Position = UDim2.new(0, 14, 0, 82)
    headerDivider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    headerDivider.BorderSizePixel = 0
    headerDivider.Parent = headerFrame
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 1, -140)
    scrollFrame.Position = UDim2.new(0, 5, 0, 86)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(138, 116, 249)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = specFrame
    
    local scrollLayout = Instance.new("UIListLayout", scrollFrame)
    scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scrollLayout.Padding = UDim.new(0, 2)
    
    local function makeHeader(text)
        local h = Instance.new("TextLabel")
        h.Size = UDim2.new(1, -20, 0, 18)
        h.BackgroundTransparency = 1
        h.Text = "— " .. text .. " —"
        h.TextColor3 = Color3.fromRGB(138, 116, 249)
        h.Font = Enum.Font.GothamBold
        h.TextSize = 11
        h.TextXAlignment = Enum.TextXAlignment.Left
        h.Parent = scrollFrame
        return h
    end
    
    local function makeInfo(color)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -20, 0, 15)
        l.BackgroundTransparency = 1
        l.Text = ""
        l.TextColor3 = color or Color3.fromRGB(200, 200, 200)
        l.Font = Enum.Font.Code
        l.TextSize = 11
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.Parent = scrollFrame
        return l
    end
    
    makeHeader("ACCOUNT")
    specAge = makeInfo(Color3.fromRGB(255, 215, 0))
    specMembership = makeInfo(Color3.fromRGB(255, 180, 100))
    specUnder13 = makeInfo(Color3.fromRGB(255, 150, 150))
    specVoice = makeInfo(Color3.fromRGB(150, 255, 200))
    
    makeHeader("DEVICE")
    specDevice = makeInfo(Color3.fromRGB(180, 220, 255))
    specRes = makeInfo(Color3.fromRGB(180, 220, 255))
    specLocale = makeInfo(Color3.fromRGB(180, 220, 255))
    specSysLocale = makeInfo(Color3.fromRGB(180, 220, 255))
    
    makeHeader("NETWORK")
    specPing = makeInfo(Color3.fromRGB(255, 200, 150))
    specFps = makeInfo(Color3.fromRGB(255, 200, 150))
    specMemory = makeInfo(Color3.fromRGB(255, 200, 150))
    
    makeHeader("STATUS")
    specTeam = makeInfo(Color3.fromRGB(200, 255, 200))
    specHealth = makeInfo(Color3.fromRGB(255, 100, 100))
    specDist = makeInfo(Color3.fromRGB(100, 200, 255))
    specState = makeInfo(Color3.fromRGB(200, 160, 255))
    
    specUsername.MouseButton1Click:Connect(function()
        local target = People.GetSelectedPlayer()
        if target then People.CopyToClipboard(target.Name) end
    end)
    
    specUserId.MouseButton1Click:Connect(function()
        local target = People.GetSelectedPlayer()
        if target then People.CopyToClipboard(target.UserId) end
    end)
    
    local btnLeft = Instance.new("TextButton")
    btnLeft.Size = UDim2.new(0, 40, 0, 30)
    btnLeft.Position = UDim2.new(0, 14, 1, -38)
    btnLeft.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
    btnLeft.BackgroundTransparency = 0.1
    btnLeft.Text = "◀"
    btnLeft.TextColor3 = Color3.fromRGB(200, 190, 255)
    btnLeft.TextSize = 16
    btnLeft.Font = Enum.Font.GothamBold
    btnLeft.AutoButtonColor = false
    btnLeft.Parent = specFrame
    Instance.new("UICorner", btnLeft).CornerRadius = UDim.new(0, 8)
    
    local btnRight = Instance.new("TextButton")
    btnRight.Size = UDim2.new(0, 40, 0, 30)
    btnRight.Position = UDim2.new(0, 60, 1, -38)
    btnRight.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
    btnRight.BackgroundTransparency = 0.1
    btnRight.Text = "▶"
    btnRight.TextColor3 = Color3.fromRGB(200, 190, 255)
    btnRight.TextSize = 16
    btnRight.Font = Enum.Font.GothamBold
    btnRight.AutoButtonColor = false
    btnRight.Parent = specFrame
    Instance.new("UICorner", btnRight).CornerRadius = UDim.new(0, 8)
    
    btnLeft.MouseButton1Click:Connect(function()
        spectateIndex = spectateIndex - 1
        local target = People.GetSpectatePlayerAtIndex(spectateIndex)
        if target then People.selectedTarget = target.Name end
    end)
    
    btnRight.MouseButton1Click:Connect(function()
        spectateIndex = spectateIndex + 1
        local target = People.GetSpectatePlayerAtIndex(spectateIndex)
        if target then People.selectedTarget = target.Name end
    end)
end

function People.ToggleSpectate(state)
    if not specGui then People.CreateSpectateGUI() end
    isSpectating = state
    specGui.Enabled = state
    
    if state then
        local firstPlayer = People.GetSpectatePlayerAtIndex(1)
        if firstPlayer then
            People.selectedTarget = firstPlayer.Name
            spectateIndex = 1
            return true
        else
            isSpectating = false
            specGui.Enabled = false
            return false
        end
    else
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then Camera.CameraSubject = hum end
        end
        People.selectedTarget = nil
        return true
    end
end

-- ==========================================================
-- MAIN LOOPS
-- ==========================================================
RunService.RenderStepped:Connect(function()
    if isSpectating and specDisplayName then
        if not People.selectedTarget then
            local firstPlayer = People.GetSpectatePlayerAtIndex(1)
            if firstPlayer then
                People.selectedTarget = firstPlayer.Name
                spectateIndex = 1
            else
                specDisplayName.Text = "No players"
                return
            end
        end
        
        local target = Players:FindFirstChild(People.selectedTarget)
        if not target or not target:IsA("Player") then
            spectateIndex = spectateIndex + 1
            local nextPlayer = People.GetSpectatePlayerAtIndex(spectateIndex)
            if nextPlayer then
                People.selectedTarget = nextPlayer.Name
            else
                specDisplayName.Text = "No players"
                return
            end
            return
        end
        
        local char = target.Character
        
        specDisplayName.Text = target.DisplayName
        specUsername.Text = "@" .. target.Name .. " "
        specUserId.Text = "ID: " .. target.UserId .. " "
        specAvatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. target.UserId .. "&width=150&height=150&format=png"
        
        specAge.Text = "Age: " .. target.AccountAge .. " days"
        specMembership.Text = "Membership: " .. tostring(target.MembershipType):gsub("Enum.MembershipType.", "")
        
        local under13Text = "N/A"
        pcall(function() under13Text = target:GetUnder13() and "Yes" or "No" end)
        specUnder13.Text = "Under 13: " .. under13Text
        
        specVoice.Text = "Voice Chat: N/A"
        
        specDevice.Text = "Device: " .. (UserInputService.TouchEnabled and "Mobile" or UserInputService.GamepadEnabled and "Console" or UserInputService.VREnabled and "VR" or "PC")
        specRes.Text = "Resolution: " .. Camera.ViewportSize.X .. "x" .. Camera.ViewportSize.Y
        specLocale.Text = "Locale: " .. tostring(LocalizationService.RobloxLocaleId)
        specSysLocale.Text = "Sys Locale: " .. tostring(LocalizationService.SystemLocaleId)
        
        local ping = 0
        pcall(function() ping = math.floor(target:GetNetworkPing() * 1000) end)
        specPing.Text = "Ping: " .. ping .. " ms"
        
        specFps.Text = "FPS: 60"
        
        local mem = 0
        pcall(function() mem = math.floor(Stats:GetTotalMemoryUsageMb()) end)
        specMemory.Text = "Memory: " .. mem .. " MB"
        
        specTeam.Text = "Team: " .. (target.Team and target.Team.Name or "None")
        
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            
            if hum and hrp then
                Camera.CameraSubject = hum
                
                local myChar = LocalPlayer.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local dist = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
                
                local vel = hrp.Velocity
                local spd = math.floor(Vector3.new(vel.X, 0, vel.Z).Magnitude)
                
                specHealth.Text = "Health: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                specDist.Text = "Dist: " .. dist .. "m | Speed: " .. spd .. " studs/s"
                
                local ok, st = pcall(function() return hum:GetState() end)
                specState.Text = "State: " .. (ok and tostring(st):gsub("Enum.HumanoidStateType.", "") or "Unknown")
            end
        else
            specHealth.Text = "Health: N/A"
            specDist.Text = "Dist: N/A"
            specState.Text = "State: Waiting..."
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local myRoot = getTargetHRP(LocalPlayer)
    if not myRoot then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    if isFollowing or isOrbiting then
        if not People.selectedPlayer or not People.selectedPlayer:IsA("Player") or not People.selectedPlayer.Character then
            People.selectedPlayer = People.GetSelectedPlayer()
            if not People.selectedPlayer then
                if isFollowing then isFollowing = false end
                if isOrbiting then isOrbiting = false; People.StopOrbit() end
                return
            end
        end
    end
    
    local targetRoot = getTargetHRP(People.selectedPlayer)
    if not targetRoot then
        if isOrbiting then People.StopOrbit() end
        return
    end
    
    if isFollowing then doFollow(People.selectedPlayer, myRoot) end
    
    if isOrbiting then
        if People.selectedMethod == "CFrame" then orbitWithCFrame(People.selectedPlayer, myRoot)
        elseif People.selectedMethod == "Lerp" then orbitWithLerp(People.selectedPlayer, myRoot)
        elseif People.selectedMethod == "BodyVelocity" then orbitWithBodyVelocity(People.selectedPlayer, myRoot)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not isAiming then return end
    if People.selectedTarget and not People.quickSwitchEnabled then
        local newPlayer = People.GetSelectedPlayer()
        if newPlayer then People.selectedPlayer = newPlayer; aimTarget = newPlayer end
    end
    if not isValidTarget(aimTarget) then
        local nextT = getNextTarget()
        if nextT then
            aimTarget = nextT
            People.UpdateLockOn(aimTarget)
            if navRef then navRef:SetTarget(aimTarget.DisplayName) end
        else
            if lockOnGui then lockOnGui.Enabled = false end
            if navRef then navRef:SetTarget("No Target") end
            return
        end
    end
    People.UpdateLockOn(aimTarget)
    local aimPos = getAimPosition(aimTarget)
    if not aimPos then return end
    if People.aimMode == "camera" or People.aimMode == "both" then
        cameraAim = true
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            Camera.CameraType = Enum.CameraType.Fixed
            Camera.CameraSubject = char.Humanoid
            Camera.CameraType = Enum.CameraType.Custom
        end
        aimCamera(aimPos)
    else cameraAim = false end
    if People.aimMode == "character" or People.aimMode == "both" then
        characterAim = true
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then char.Humanoid.AutoRotate = false end
        aimCharacter(aimTarget)
    else
        characterAim = false
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then char.Humanoid.AutoRotate = true end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == People.aimKey then
        keyHeld = true
        if not isAiming then
            isAiming = true
            People.CreateLockOnIndicator()
            local p = People.GetSelectedPlayer()
            if p then aimTarget = p else aimTarget = nil end
            if aimTarget then
                People.UpdateLockOn(aimTarget)
                if navRef then navRef:SetTarget(aimTarget.DisplayName) end
            end
            if People.quickSwitchEnabled then People.UpdateNavButtons(true) end
        end
    end
    if input.KeyCode == Enum.KeyCode.Q and isAiming and People.quickSwitchEnabled then onPrevClick() end
    if input.KeyCode == Enum.KeyCode.E and isAiming and People.quickSwitchEnabled then onNextClick() end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == People.aimKey then
        keyHeld = false
        if isAiming then
            isAiming = false
            aimTarget = nil
            People.DestroyLockOn()
            People.UpdateNavButtons(false)
            if cameraAim or People.aimMode == "camera" or People.aimMode == "both" then resetCamera() end
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then char.Humanoid.AutoRotate = true end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if navPrevBtn and not navPrevBtn:GetAttribute("Connected") then
            navPrevBtn:SetAttribute("Connected", true)
            navPrevBtn.MouseButton1Click:Connect(onPrevClick)
        end
        if navNextBtn and not navNextBtn:GetAttribute("Connected") then
            navNextBtn:SetAttribute("Connected", true)
            navNextBtn.MouseButton1Click:Connect(onNextClick)
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    if plr == mimicTarget then
        if mimicEnabled then People.StopMimic() end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if mimicEnabled then People.StopMimic() end
end)

return People
