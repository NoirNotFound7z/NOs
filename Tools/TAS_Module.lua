local TAS = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local notifyFn = nil

function TAS.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then notifyFn(title, content, icon) end
end

-- ==========================================================
-- THEME
-- ==========================================================
local THEME = {
    Accent     = Color3.fromRGB(138, 116, 249),
    AccentH    = Color3.fromRGB(160, 140, 255),
    AccentD    = Color3.fromRGB(110, 90, 210),
    Bg         = Color3.fromRGB(18, 18, 24),
    BgLight    = Color3.fromRGB(26, 26, 34),
    BgInput    = Color3.fromRGB(14, 14, 18),
    Border     = Color3.fromRGB(55, 55, 70),
    BorderHi   = Color3.fromRGB(80, 80, 100),
    Text       = Color3.fromRGB(240, 240, 245),
    TextDim    = Color3.fromRGB(150, 150, 165),
    TextMuted  = Color3.fromRGB(100, 100, 115),
    Success    = Color3.fromRGB(76, 175, 130),
    SuccessH   = Color3.fromRGB(95, 195, 150),
    Danger     = Color3.fromRGB(220, 70, 90),
    DangerH    = Color3.fromRGB(240, 90, 110),
    Warn       = Color3.fromRGB(235, 160, 80),
    WarnH      = Color3.fromRGB(250, 180, 100),
}

-- ==========================================================
-- STATE
-- ==========================================================
local character, humanoid, rootPart

local camEnabled = true
local recording, replaying, paused = false, false, false
local frames = {}
local backupFrames = {}
local backupTime = 0
local replayIndex, startTime, pauseOffset, pauseStart = 1, 0, 0, 0
local recordedTime = 0
local currentSpeed = 1.0

local isHoldingAction = false
local wasHoldingAction = false
local activeTouches = {}
local isStepping = false
local spamCounter = 0

local gameName = game.Name
task.spawn(function()
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)
end)

TAS.OnFramesChanged = nil

local function setFramesCount(n)
    if TAS.OnFramesChanged then TAS.OnFramesChanged(n) end
end

-- ==========================================================
-- GODMODE
-- ==========================================================
local function toggleGodMode(state)
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanTouch = not state end
        end
        if rootPart then rootPart.CanTouch = true end
    end
end

-- ==========================================================
-- CHARACTER SETUP
-- ==========================================================
local function updateVars(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")

    humanoid.StateChanged:Connect(function(oldState, newState)
        if oldState == Enum.HumanoidStateType.Climbing and (newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Jumping) then
            task.defer(function()
                if rootPart then
                    local vel = rootPart.AssemblyLinearVelocity
                    rootPart.AssemblyLinearVelocity = Vector3.new(vel.X * 0.05, vel.Y, vel.Z * 0.05)
                end
            end)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(updateVars)
if LocalPlayer.Character then updateVars(LocalPlayer.Character) end

-- ==========================================================
-- STOP ALL
-- ==========================================================
function TAS.StopAll()
    if recording and #frames == 0 and #backupFrames > 0 then
        frames = backupFrames
        recordedTime = backupTime
        setFramesCount(#frames)
    end

    recording, replaying, paused = false, false, false
    isHoldingAction, wasHoldingAction = false, false
    table.clear(activeTouches)
    if rootPart then rootPart.Anchored = false end
    Camera.CameraType = Enum.CameraType.Custom
    toggleGodMode(false)
end

-- ==========================================================
-- INPUT TRACKING
-- ==========================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if recording then
            isHoldingAction = true
            activeTouches[input] = {x = input.Position.X, y = input.Position.Y}
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if activeTouches[input] then
        activeTouches[input] = {x = input.Position.X, y = input.Position.Y}
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if activeTouches[input] then activeTouches[input] = nil end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local count = 0
        for _ in pairs(activeTouches) do count = count + 1 end
        if count == 0 then isHoldingAction = false end
    end
end)

-- ==========================================================
-- ANIMATION SYNC
-- ==========================================================
RunService.Stepped:Connect(function()
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    local targetSpeed = 1
    if paused and not isStepping then
        targetSpeed = 0
    elseif replaying then
        targetSpeed = 1
    elseif recording then
        targetSpeed = currentSpeed
    end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if math.abs(track.Speed - targetSpeed) > 0.01 then
            track:AdjustSpeed(targetSpeed)
        end
    end
end)

-- ==========================================================
-- CAPTURE / RECORD LOOP
-- ==========================================================
local function captureFrameData()
    local tool = character and character:FindFirstChildOfClass("Tool")
    local currentTouches = {}
    for _, touchData in pairs(activeTouches) do
        table.insert(currentTouches, {x = touchData.x, y = touchData.y})
    end

    table.insert(frames, {
        t = recordedTime,
        pos = rootPart.CFrame,
        cam = camEnabled and Camera.CFrame or nil,
        vel = rootPart.AssemblyLinearVelocity,
        holding = isHoldingAction,
        touches = currentTouches,
        target = Mouse.Hit.p,
        equipped = tool and tool.Name or nil,
    })
    setFramesCount(#frames)
end

RunService.Heartbeat:Connect(function()
    if not recording or paused or not rootPart then return end
    if currentSpeed >= 1 then
        recordedTime = recordedTime + (1/60)
        captureFrameData()
    else
        if isStepping then return end
        spamCounter = spamCounter + 1
        local framesToWait = math.floor(1 / currentSpeed) - 1

        if spamCounter >= framesToWait then
            spamCounter = 0
            task.spawn(function()
                isStepping = true
                rootPart.Anchored = false
                RunService.Heartbeat:Wait()
                if recording and not paused and rootPart then
                    rootPart.Anchored = true
                    recordedTime = recordedTime + (1/60)
                    captureFrameData()
                end
                isStepping = false
            end)
        end
    end
end)

-- ==========================================================
-- REPLAY LOOP
-- ==========================================================
RunService.Heartbeat:Connect(function()
    if not replaying or paused or not rootPart then return end
    if replayIndex > #frames then TAS.StopAll() return end

    local elapsed = tick() - startTime - pauseOffset
    while replayIndex <= #frames and frames[replayIndex].t <= elapsed do
        local f = frames[replayIndex]
        rootPart.CFrame, rootPart.AssemblyLinearVelocity = f.pos, f.vel

        if camEnabled and f.cam then
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = f.cam
        else
            Camera.CameraType = Enum.CameraType.Custom
        end

        local currentTool = character:FindFirstChildOfClass("Tool")
        if f.equipped then
            if not currentTool or currentTool.Name ~= f.equipped then
                local t = LocalPlayer.Backpack:FindFirstChild(f.equipped) or character:FindFirstChild(f.equipped)
                if t then humanoid:EquipTool(t) currentTool = t end
            end
        else
            humanoid:UnequipTools()
        end

        if currentTool then
            if f.holding and not wasHoldingAction then
                currentTool:Activate()
            elseif not f.holding and wasHoldingAction then
                currentTool:Deactivate()
            end
        end
        wasHoldingAction = f.holding
        replayIndex = replayIndex + 1
    end
end)

-- ==========================================================
-- PAUSE
-- ==========================================================
function TAS.TogglePause()
    if not (recording or replaying) then return end
    paused = not paused
    if rootPart then
        if replaying or (recording and currentSpeed >= 1) then
            rootPart.Anchored = paused
        elseif recording and currentSpeed < 1 then
            rootPart.Anchored = true
        end
    end
    if paused then
        pauseStart = tick()
        Camera.CameraType = Enum.CameraType.Custom
        notify("TAS", "Paused", "pause")
    else
        pauseOffset = pauseOffset + (tick() - pauseStart)
        notify("TAS", recording and "Recording" or "Replaying", "play")
    end
end

-- ==========================================================
-- RECORD / RESUME / PLAY
-- ==========================================================
function TAS.StartRecord()
    if #frames > 0 then
        backupFrames = table.clone(frames)
        backupTime = recordedTime
    end
    frames, recordedTime, spamCounter = {}, 0, 0
    table.clear(activeTouches)
    recording, paused, isHoldingAction, wasHoldingAction = true, true, false, false
    if rootPart then rootPart.Anchored = true end
    toggleGodMode(true)
    setFramesCount(0)
    notify("TAS", "Record mode (Ready)", "circle")
end

function TAS.Resume()
    if #frames > 0 then
        rootPart.CFrame = frames[#frames].pos
        recording, paused = true, true
        rootPart.Anchored = true
        notify("TAS", "Resumed", "play")
    end
end

function TAS.Play()
    if #frames > 0 then
        recording, replaying, paused, pauseOffset, replayIndex, startTime = false, true, false, 0, 1, tick()
        wasHoldingAction = false
        table.clear(activeTouches)
        toggleGodMode(true)
        if rootPart then rootPart.Anchored = false end
        notify("TAS", "Playing", "play")
    end
end

-- ==========================================================
-- SPEED
-- ==========================================================
function TAS.SetSpeed(v)
    currentSpeed = v
    if recording and not paused and rootPart then
        rootPart.Anchored = (currentSpeed < 1)
    end
end

function TAS.GetSpeed()
    return currentSpeed
end

-- ==========================================================
-- FRAME STEP
-- ==========================================================
function TAS.AdvanceFrame()
    if not paused or isStepping then return end
    isStepping = true
    if replaying then
        if replayIndex < #frames then
            replayIndex = replayIndex + 1
            local f = frames[replayIndex]
            if rootPart then rootPart.CFrame, rootPart.AssemblyLinearVelocity = f.pos, f.vel end
            recordedTime = f.t
        end
        isStepping = false
    elseif recording then
        if rootPart then rootPart.Anchored = false end
        RunService.Heartbeat:Wait()
        if recording and rootPart then
            rootPart.Anchored = true
            recordedTime = recordedTime + (1/60)
            captureFrameData()
        end
        isStepping = false
    else
        isStepping = false
    end
end

function TAS.RewindFrame()
    if not paused or isStepping then return end
    isStepping = true
    if replaying and replayIndex > 1 then
        replayIndex = replayIndex - 1
        local f = frames[replayIndex]
        if rootPart then rootPart.CFrame, rootPart.AssemblyLinearVelocity = f.pos, f.vel end
        recordedTime = f.t
    elseif recording and #frames > 1 then
        table.remove(frames, #frames)
        setFramesCount(#frames)
        local f = frames[#frames]
        if rootPart then rootPart.CFrame, rootPart.AssemblyLinearVelocity = f.pos, f.vel end
        recordedTime = f.t
    end
    isStepping = false
end

-- ==========================================================
-- UNDO 5s
-- ==========================================================
function TAS.Undo5s()
    if #frames > 5 then
        local undoAmount = math.min(#frames, 300)
        local targetIndex = #frames - undoAmount
        recordedTime = targetIndex > 0 and frames[targetIndex].t or 0
        for _ = 1, undoAmount do table.remove(frames, #frames) end
        setFramesCount(#frames)
        if frames[#frames] then rootPart.CFrame = frames[#frames].pos end
        notify("TAS", "Undo 5s", "undo")
    end
end

-- ==========================================================
-- CAM
-- ==========================================================
function TAS.SetCamEnabled(v)
    camEnabled = v
    notify("TAS", v and "Camera Recording ON" or "Camera Recording OFF", "camera")
end

function TAS.GetCamEnabled() return camEnabled end

function TAS.GetFramesCount() return #frames end

-- ==========================================================
-- BASE64 LZW COMPRESSION
-- ==========================================================
local B64_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b64ToVal, valToB64 = {}, {}
for i = 1, 64 do
    local char = string.sub(B64_ALPHABET, i, i)
    b64ToVal[char] = i - 1
    valToB64[i - 1] = char
end

local function lzwCompress(str)
    local dict = {}
    for i = 0, 255 do dict[string.char(i)] = i end
    local w, res, code = "", {}, 256

    for i = 1, #str do
        local c = string.sub(str, i, i)
        local wc = w .. c
        if dict[wc] then
            w = wc
        else
            local val = dict[w]
            table.insert(res, valToB64[math.floor(val / 64)] .. valToB64[val % 64])
            dict[wc] = code
            code = code + 1
            if code > 4095 then
                table.clear(dict)
                for j = 0, 255 do dict[string.char(j)] = j end
                code = 256
            end
            w = c
        end
    end
    if w ~= "" then
        local val = dict[w]
        table.insert(res, valToB64[math.floor(val / 64)] .. valToB64[val % 64])
    end
    return table.concat(res)
end

local function lzwDecompress(b64str)
    if #b64str % 2 ~= 0 then warn("TAS Decompress: Malformed Base64 length.") return "" end
    local dict = {}
    for i = 0, 255 do dict[i] = string.char(i) end
    local res, code = {}, 256
    local firstVal = b64ToVal[string.sub(b64str, 1, 1)] * 64 + b64ToVal[string.sub(b64str, 2, 2)]
    local w = dict[firstVal]
    table.insert(res, w)

    for i = 3, #b64str, 2 do
        local val = b64ToVal[string.sub(b64str, i, i)] * 64 + b64ToVal[string.sub(b64str, i+1, i+1)]
        local entry
        if dict[val] then
            entry = dict[val]
        elseif val == code then
            entry = w .. string.sub(w, 1, 1)
        else return "" end

        table.insert(res, entry)
        dict[code] = w .. string.sub(entry, 1, 1)
        code = code + 1
        if code > 4095 then
            table.clear(dict)
            for j = 0, 255 do dict[j] = string.char(j) end
            code = 256
        end
        w = entry
    end
    return table.concat(res)
end

local function compressTAS(rawString)
    local parts = string.split(rawString, ";")
    if #parts < 2 then return rawString end
    local header, out, lastState = parts[1], {}, {"", "", "", "", "", ""}

    for i = 2, #parts do
        local frameStr = parts[i]
        if frameStr == "" then continue end
        local vals = string.split(frameStr, ",")
        if #vals >= 7 then
            local t = tostring(tonumber(vals[1]))
            local current = {
                tostring(tonumber(vals[2])), tostring(tonumber(vals[3])), tostring(tonumber(vals[4])),
                tostring(tonumber(vals[5])), tostring(tonumber(vals[6])), tostring(tonumber(vals[7]))
            }
            local isIdentical, delta = true, {t}
            for j = 1, 6 do
                if current[j] ~= lastState[j] then
                    isIdentical, delta[j+1], lastState[j] = false, current[j], current[j]
                else
                    delta[j+1] = ""
                end
            end
            if isIdentical then
                table.insert(out, t)
            else
                local idx = 7
                while idx > 1 and delta[idx] == "" do delta[idx] = nil idx = idx - 1 end
                table.insert(out, table.concat(delta, ","))
            end
        end
    end
    return header .. "|COMPRESSED|" .. lzwCompress(table.concat(out, ";"))
end

local function decompressTAS(compString)
    if not string.find(compString, "|COMPRESSED|") then return compString end
    local splitData = string.split(compString, "|COMPRESSED|")
    local deltaStr = lzwDecompress(splitData[2])
    if deltaStr == "" then return "" end

    local out, lastState = {splitData[1]}, {"0", "0", "0", "0", "0", "0"}
    local fr = string.split(deltaStr, ";")

    for i = 1, #fr do
        local f = fr[i]
        if f == "" then continue end
        local vals = string.split(f, ",")
        for j = 1, 6 do
            if vals[j+1] and vals[j+1] ~= "" then lastState[j] = vals[j+1] end
        end
        table.insert(out, vals[1] .. "," .. lastState[1] .. "," .. lastState[2] .. "," .. lastState[3] .. "," .. lastState[4] .. "," .. lastState[5] .. "," .. lastState[6])
    end
    return table.concat(out, ";")
end

-- ==========================================================
-- EXPORT / IMPORT DATA
-- ==========================================================
local function compressFrames()
    local str = {}
    table.insert(str, "TAS_GAME: " .. string.gsub(gameName, ";", ""))
    for _, f in ipairs(frames) do
        local rx, ry, rz = f.pos:ToEulerAnglesXYZ()
        table.insert(str, string.format("%.2f,%.1f,%.1f,%.1f,%.2f,%.2f,%.2f", f.t, f.pos.X, f.pos.Y, f.pos.Z, rx, ry, rz))
    end
    return table.concat(str, ";")
end

local function decompressFrames(dataStr)
    local newFrames = {}
    local prevFrame = nil

    for frameStr in string.gmatch(dataStr, "([^;]+)") do
        if string.sub(frameStr, 1, 9) == "TAS_GAME:" then continue end
        local pts = string.split(frameStr, ",")
        if #pts >= 7 then
            local t = tonumber(pts[1])
            local x, y, z = tonumber(pts[2]), tonumber(pts[3]), tonumber(pts[4])
            local rx, ry, rz = tonumber(pts[5]), tonumber(pts[6]), tonumber(pts[7])

            if t and x then
                local pos = CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz)
                local vel = Vector3.zero

                if prevFrame and t > prevFrame.t then
                    vel = (pos.Position - prevFrame.pos.Position) / (t - prevFrame.t)
                end

                local currentFrame = {t = t, pos = pos, vel = vel, touches = {}, holding = false}
                table.insert(newFrames, currentFrame)
                prevFrame = currentFrame
            end
        end
    end
    return newFrames
end

function TAS.ExportData()
    local rawString = compressFrames()
    return compressTAS(rawString)
end

function TAS.ImportData(dataStr)
    local rawString = decompressTAS(dataStr)
    local loaded = decompressFrames(rawString)

    if #loaded > 0 then
        frames = loaded
        recordedTime = frames[#frames].t
        setFramesCount(#frames)
        notify("TAS", "Loaded " .. #frames .. " frames", "check")
        return true
    else
        notify("TAS", "Load failed", "x")
        return false
    end
end

-- ==========================================================
-- EXPORT / IMPORT PANEL (REDESIGNED)
-- ==========================================================
local expImpGui
local panelRef
local dataBoxRef
local statsLabelRef
local mainBtnRefs = {}

local function makeCorner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
    return c
end

local function makeStroke(obj, color, trans, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.Border
    s.Transparency = trans or 0.5
    s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function updateStats()
    if not statsLabelRef then return end
    local n = #frames
    local t = recordedTime
    statsLabelRef.Text = string.format("%d frames  •  %.2fs", n, t)
end

local function createButton(parent, text, baseColor, hoverColor, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, -6, 1, 0)
    btn.BackgroundColor3 = baseColor
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = parent

    makeCorner(btn, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Transparency = 0.85
    stroke.Thickness = 1
    stroke.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.ZIndex = 2
    lbl.Parent = btn

    local pressTween = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, pressTween, {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, pressTween, {BackgroundColor3 = baseColor}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.05), {BackgroundColor3 = baseColor:Lerp(Color3.new(0, 0, 0), 0.3)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, pressTween, {BackgroundColor3 = hoverColor}):Play()
    end)

    if callback then
        btn.MouseButton1Click:Connect(callback)
    end

    return btn
end

local function ensurePanel()
    if expImpGui and expImpGui.Parent then return expImpGui, panelRef, dataBoxRef end

    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("TAS_ExpImpGui")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "TAS_ExpImpGui"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999
    pcall(function() sg.Parent = pg end)
    if not sg.Parent then
        sg.Parent = game:GetService("CoreGui")
    end

    -- Main panel
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 380, 0, 300)
    panel.Position = UDim2.new(0.5, -190, 0.5, -150)
    panel.BackgroundColor3 = THEME.Bg
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = sg
    makeCorner(panel, 12)
    makeStroke(panel, THEME.Accent, 0.5, 1.5)

    -- Top accent glow
    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, -32, 0, 2)
    glow.Position = UDim2.new(0, 16, 0, 0)
    glow.BackgroundColor3 = THEME.Accent
    glow.BackgroundTransparency = 0.2
    glow.BorderSizePixel = 0
    glow.Parent = panel

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = THEME.BgLight
    header.BackgroundTransparency = 0.1
    header.BorderSizePixel = 0
    header.Parent = panel
    makeCorner(header, 12)

    local headerExt = Instance.new("Frame")
    headerExt.Size = UDim2.new(1, 0, 0, 20)
    headerExt.Position = UDim2.new(0, 0, 1, -20)
    headerExt.BackgroundColor3 = THEME.BgLight
    headerExt.BackgroundTransparency = 0.1
    headerExt.BorderSizePixel = 0
    headerExt.Parent = header

    -- Accent dot
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 14, 0.5, -4)
    dot.BackgroundColor3 = THEME.Accent
    dot.BorderSizePixel = 0
    dot.Parent = header
    makeCorner(dot, 4)

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 30, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Export / Import"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = THEME.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -36, 0.5, -13)
    closeBtn.BackgroundColor3 = THEME.Danger
    closeBtn.BackgroundTransparency = 0.15
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 11
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = header
    makeCorner(closeBtn, 8)

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.DangerH, BackgroundTransparency = 0}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Danger, BackgroundTransparency = 0.15}):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
    end)

    -- Draggable
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, panel.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Stats bar
    local statsBar = Instance.new("Frame")
    statsBar.Size = UDim2.new(1, -24, 0, 22)
    statsBar.Position = UDim2.new(0, 12, 0, 52)
    statsBar.BackgroundColor3 = THEME.BgInput
    statsBar.BackgroundTransparency = 0.2
    statsBar.BorderSizePixel = 0
    statsBar.Parent = panel
    makeCorner(statsBar, 6)

    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -16, 1, 0)
    statsLabel.Position = UDim2.new(0, 10, 0, 0)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "0 frames  •  0.00s"
    statsLabel.Font = Enum.Font.Code
    statsLabel.TextSize = 11
    statsLabel.TextColor3 = THEME.TextDim
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Parent = statsBar

    statsLabelRef = statsLabel

    -- Data input
    local dataBox = Instance.new("TextBox")
    dataBox.Size = UDim2.new(1, -24, 1, -150)
    dataBox.Position = UDim2.new(0, 12, 0, 82)
    dataBox.BackgroundColor3 = THEME.BgInput
    dataBox.BorderSizePixel = 0
    dataBox.TextColor3 = THEME.Text
    dataBox.TextXAlignment = Enum.TextXAlignment.Left
    dataBox.TextYAlignment = Enum.TextYAlignment.Top
    dataBox.ClearTextOnFocus = false
    dataBox.MultiLine = true
    dataBox.TextWrapped = true
    dataBox.Font = Enum.Font.Code
    dataBox.TextSize = 11
    dataBox.Text = ""
    dataBox.PlaceholderText = "Paste TAS data here or export to generate..."
    dataBox.PlaceholderColor3 = THEME.TextMuted
    dataBox.Parent = panel
    makeCorner(dataBox, 8)

    local dataBoxStroke = Instance.new("UIStroke")
    dataBoxStroke.Color = THEME.Border
    dataBoxStroke.Transparency = 0.4
    dataBoxStroke.Thickness = 1
    dataBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    dataBoxStroke.Parent = dataBox

    dataBox.Focused:Connect(function()
        TweenService:Create(dataBoxStroke, TweenInfo.new(0.15), {Color = THEME.Accent, Transparency = 0.2}):Play()
    end)
    dataBox.FocusLost:Connect(function()
        TweenService:Create(dataBoxStroke, TweenInfo.new(0.15), {Color = THEME.Border, Transparency = 0.4}):Play()
    end)

    dataBoxRef = dataBox

    -- Padding inside textbox
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.Parent = dataBox

    -- Button row
    local btnRow = Instance.new("Frame")
    btnRow.Size = UDim2.new(1, -24, 0, 34)
    btnRow.Position = UDim2.new(0, 12, 1, -46)
    btnRow.BackgroundTransparency = 1
    btnRow.Parent = panel

    local rowLayout = Instance.new("UIListLayout")
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.Padding = UDim.new(0, 6)
    rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rowLayout.Parent = btnRow

    -- 4 đồng bộ màu nút: cùng tone accent NoirUI
    createButton(btnRow, "Copy", THEME.Accent, THEME.AccentH, 1, function()
        if setclipboard then
            pcall(function() setclipboard(dataBox.Text) end)
            notify("TAS", "Copied " .. #dataBox.Text .. " chars", "clipboard")
        else
            notify("TAS", "setclipboard unavailable", "x")
        end
    end)

    createButton(btnRow, "Paste", THEME.Accent, THEME.AccentH, 2, function()
        if getclipboard then
            local ok, content = pcall(getclipboard)
            if ok and content and content ~= "" then
                dataBox.Text = content
                notify("TAS", "Pasted " .. #content .. " chars", "clipboard")
            else
                notify("TAS", "Clipboard empty", "x")
            end
        else
            notify("TAS", "getclipboard unavailable", "x")
        end
    end)

    createButton(btnRow, "Load", THEME.Success, THEME.SuccessH, 3, function()
        if dataBox.Text and dataBox.Text ~= "" then
            TAS.ImportData(dataBox.Text)
            updateStats()
        else
            notify("TAS", "Data box is empty", "x")
        end
    end)

    createButton(btnRow, "Clear", THEME.Card, THEME.CardH, 4, function()
        dataBox.Text = ""
        notify("TAS", "Data cleared", "trash")
    end)

    panelRef = panel
    expImpGui = sg

    TAS.OnFramesChanged = function()
        updateStats()
    end

    return sg, panel, dataBox
end

function TAS.OpenExportImport()
    local _, panel, dataBox = ensurePanel()
    local data = TAS.ExportData()
    if dataBox then dataBox.Text = data end
    updateStats()

    if panel.Visible then return end

    panel.Visible = true
    panel.BackgroundTransparency = 1
    panel.Size = UDim2.new(0, 360, 0, 285)

    TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
        Size = UDim2.new(0, 380, 0, 300)
    }):Play()
end

function TAS.CloseExportImport()
    if panelRef then panelRef.Visible = false end
end

return TAS