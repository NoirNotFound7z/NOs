local Replay = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Chat = game:GetService("Chat")
local UserService = game:GetService("UserService")

local LocalPlayer = Players.LocalPlayer

local notifyFn = nil

function Replay.SetNotify(fn)
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
    Bg         = Color3.fromRGB(18, 18, 24),
    BgLight    = Color3.fromRGB(26, 26, 34),
    BgInput    = Color3.fromRGB(14, 14, 18),
    Card       = Color3.fromRGB(30, 30, 40),
    CardH      = Color3.fromRGB(44, 44, 58),
    Border     = Color3.fromRGB(55, 55, 70),
    Text       = Color3.fromRGB(240, 240, 245),
    TextDim    = Color3.fromRGB(150, 150, 165),
    Danger     = Color3.fromRGB(220, 70, 90),
    DangerH    = Color3.fromRGB(240, 90, 110),
    Success    = Color3.fromRGB(76, 175, 130),
    SuccessH   = Color3.fromRGB(95, 195, 150),
}

-- ==========================================================
-- STATE
-- ==========================================================
local savedRecordings = {}
local isRecording = false
local currentRecordingFrames = {}
local playbackSession = 0
local currentActorName = ""
local clonesCanCollide = false
local isPaused = false
local selectedOutfitDescription = nil

local activeChat = nil
local chatTimer = 0

-- Panel refs
local recordingsGui, recordingsPanel, recordingsListRef
local outfitsGui, outfitsPanel
local outfitsListRef
local outfitUsernameRef
local outfitStatusRef

-- Outfit state
local outfitUserId = nil
local outfitCurrentUserId = nil

Replay.OnRecordingsPanelToggle = nil
Replay.OnOutfitsPanelToggle = nil

-- ==========================================================
-- HELPERS
-- ==========================================================
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

-- ==========================================================
-- CREATE ACTOR CLONE
-- ==========================================================
local function createActorClone(username)
    local success, userId = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
    if not success then return nil end

    local description = nil
    if selectedOutfitDescription then
        description = selectedOutfitDescription
    else
        local descSuccess, defaultDesc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
        if not descSuccess then return nil end
        description = defaultDesc
    end

    local localHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local rigType = localHum and localHum.RigType or Enum.HumanoidRigType.R15

    local model = Players:CreateHumanoidModelFromDescription(description, rigType)
    model.Name = username
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then hum.DisplayName = username end

    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part.Parent:IsA("Accessory") then part.Anchored = true end
            part.CanCollide = clonesCanCollide
        elseif part:IsA("LocalScript") or part:IsA("Script") then
            part:Destroy()
        end
    end

    return model
end

-- ==========================================================
-- RECORD LOOP
-- ==========================================================
RunService.Heartbeat:Connect(function(dt)
    if isRecording and LocalPlayer.Character then
        if chatTimer > 0 then
            chatTimer = chatTimer - dt
        else
            activeChat = nil
        end
        local frame = { parts = {}, ChatText = activeChat }
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then
                frame.parts[part.Name] = part.CFrame
            end
        end
        table.insert(currentRecordingFrames, frame)
    end
end)

-- ==========================================================
-- PLAYBACK
-- ==========================================================
local function playOne(data, session)
    task.spawn(function()
        local clone = createActorClone(data.actorName)
        if not clone then return end
        clone.Parent = workspace

        local lastChatMessage = nil

        for _, frameData in ipairs(data.frames) do
            if playbackSession ~= session then break end

            while isPaused do
                RunService.Heartbeat:Wait()
            end

            for _, p in pairs(clone:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = clonesCanCollide end
            end

            if frameData.ChatText ~= lastChatMessage then
                lastChatMessage = frameData.ChatText
                if frameData.ChatText then
                    local head = clone:FindFirstChild("Head")
                    if head then
                        Chat:Chat(head, frameData.ChatText, Enum.ChatColor.White)
                    end
                end
            end

            for partName, cf in pairs(frameData.parts) do
                local p = clone:FindFirstChild(partName)
                if p then p.CFrame = cf end
            end
            RunService.Heartbeat:Wait()
        end
        clone:Destroy()
    end)
end

-- ==========================================================
-- PUBLIC API
-- ==========================================================
function Replay.StartRecording(actorName)
    currentActorName = (actorName and actorName ~= "") and actorName or "Roblox"
    currentRecordingFrames = {}
    activeChat = nil
    chatTimer = 0
    isRecording = true
    playbackSession = playbackSession + 1
    for _, data in pairs(savedRecordings) do
        playOne(data, playbackSession)
    end
    notify("Replay", "Recording started: " .. currentActorName, "circle")
end

function Replay.StopRecording()
    if not isRecording then return end
    isRecording = false
    if #currentRecordingFrames > 0 then
        local newRec = { actorName = currentActorName, frames = currentRecordingFrames }
        table.insert(savedRecordings, newRec)
        notify("Replay", "Saved: " .. currentActorName .. " (" .. #currentRecordingFrames .. " frames)", "save")
        Replay.RefreshRecordingsPanel()
    else
        notify("Replay", "Recording empty, discarded", "x")
    end
end

function Replay.ToggleRecord(actorName)
    if isRecording then
        Replay.StopRecording()
    else
        Replay.StartRecording(actorName)
    end
end

function Replay.GetRecordingState()
    return isRecording
end

function Replay.PlayAll()
    playbackSession = playbackSession + 1
    for _, data in pairs(savedRecordings) do
        playOne(data, playbackSession)
    end
    notify("Replay", "Playing " .. #savedRecordings .. " recordings", "play")
end

function Replay.SetPaused(v)
    isPaused = v
    notify("Replay", v and "Paused" or "Resumed", v and "pause" or "play")
end

function Replay.TogglePaused()
    isPaused = not isPaused
    notify("Replay", isPaused and "Paused" or "Resumed", isPaused and "pause" or "play")
end

function Replay.IsPaused()
    return isPaused
end

function Replay.SetGhostMode(v)
    clonesCanCollide = v
    notify("Replay", v and "Ghost Mode OFF (collide)" or "Ghost Mode ON (no collide)", "ghost")
end

function Replay.GetGhostMode()
    return clonesCanCollide
end

function Replay.SendChat(text)
    if text and text ~= "" then
        activeChat = text
        chatTimer = 4
        notify("Replay", "Chat queued: " .. text, "message-circle")
    end
end

function Replay.ClearAll()
    savedRecordings = {}
    playbackSession = playbackSession + 1
    Replay.RefreshRecordingsPanel()
    notify("Replay", "Cleared all recordings", "trash")
end

function Replay.GetRecordings()
    return savedRecordings
end

-- ==========================================================
-- OUTFITS
-- ==========================================================
function Replay.FetchUserOutfits(username)
    if not username or username == "" then
        notify("Outfits", "Username empty", "x")
        return
    end

    if outfitStatusRef then
        outfitStatusRef.Text = "Loading..."
        outfitStatusRef.TextColor3 = THEME.TextDim
    end

    task.spawn(function()
        local success, userId = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
        if not success then
            notify("Outfits", "User not found", "x")
            if outfitStatusRef then
                outfitStatusRef.Text = "User not found"
                outfitStatusRef.TextColor3 = THEME.Danger
            end
            return
        end

        outfitUserId = userId

        local thumb, isReady = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)

        local outfitSuccess, outfitsPage = pcall(function()
            return UserService:GetOutfitsAsync({ userId = userId, outfitType = Enum.OutfitType.Avatar })
        end)

        if not outfitSuccess or not outfitsPage then
            notify("Outfits", "Failed to fetch outfits", "x")
            if outfitStatusRef then
                outfitStatusRef.Text = "Failed to fetch"
                outfitStatusRef.TextColor3 = THEME.Danger
            end
            return
        end

        local outfits = outfitsPage:GetCurrentPage()

        if outfitStatusRef then
            outfitStatusRef.Text = username .. " - " .. #outfits .. " outfits"
            outfitStatusRef.TextColor3 = THEME.Success
            if isReady then
                outfitStatusRef:SetAttribute("Thumb", thumb)
            end
        end

        Replay.PopulateOutfitsPanel(userId, outfits)
        notify("Outfits", "Loaded " .. #outfits .. " outfits", "check")
    end)
end

function Replay.SelectOutfitById(outfitId, outfitName)
    if outfitId == nil then
        local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(outfitUserId) end)
        if ok and desc then
            selectedOutfitDescription = desc
            notify("Outfits", "Selected: Default Look", "check")
        end
    else
        local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromOutfitId(outfitId) end)
        if ok and desc then
            selectedOutfitDescription = desc
            notify("Outfits", "Selected: " .. outfitName, "check")
        else
            notify("Outfits", "Failed to load outfit", "x")
        end
    end
end

function Replay.ApplyOutfitToSelf()
    if selectedOutfitDescription and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local ok = pcall(function()
            LocalPlayer.Character.Humanoid:ApplyDescription(selectedOutfitDescription)
        end)
        if ok then
            notify("Outfits", "Applied to your avatar", "check")
        else
            notify("Outfits", "Failed to apply", "x")
        end
    else
        notify("Outfits", "No outfit selected", "x")
    end
end

-- ==========================================================
-- RECORDINGS PANEL (170px width)
-- ==========================================================
local function createRecordingEntry(parent, data, index)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -8, 0, 44)
    entry.BackgroundColor3 = THEME.Card
    entry.BorderSizePixel = 0
    entry.LayoutOrder = index
    entry.Parent = parent
    makeCorner(entry, 6)

    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.Border
    stroke.Transparency = 0.5
    stroke.Thickness = 1
    stroke.Parent = entry

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0, 8, 0.5, -3)
    dot.BackgroundColor3 = THEME.Accent
    dot.BorderSizePixel = 0
    dot.Parent = entry
    makeCorner(dot, 3)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -80, 0, 16)
    nameLabel.Position = UDim2.new(0, 20, 0, 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = data.actorName
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 11
    nameLabel.TextColor3 = THEME.Text
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = entry

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -80, 0, 14)
    infoLabel.Position = UDim2.new(0, 20, 0, 22)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = #data.frames .. " frames"
    infoLabel.Font = Enum.Font.Code
    infoLabel.TextSize = 9
    infoLabel.TextColor3 = THEME.TextDim
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = entry

    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(0, 26, 0, 26)
    playBtn.Position = UDim2.new(1, -60, 0.5, -13)
    playBtn.BackgroundColor3 = THEME.Accent
    playBtn.BorderSizePixel = 0
    playBtn.Text = ">"
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextSize = 12
    playBtn.TextColor3 = Color3.new(1, 1, 1)
    playBtn.AutoButtonColor = false
    playBtn.Parent = entry
    makeCorner(playBtn, 5)

    playBtn.MouseEnter:Connect(function()
        TweenService:Create(playBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.AccentH}):Play()
    end)
    playBtn.MouseLeave:Connect(function()
        TweenService:Create(playBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Accent}):Play()
    end)
    playBtn.MouseButton1Click:Connect(function()
        playbackSession = playbackSession + 1
        playOne(data, playbackSession)
        notify("Replay", "Playing: " .. data.actorName, "play")
    end)

    local delBtn = Instance.new("TextButton")
    delBtn.Size = UDim2.new(0, 26, 0, 26)
    delBtn.Position = UDim2.new(1, -30, 0.5, -13)
    delBtn.BackgroundColor3 = THEME.Danger
    delBtn.BorderSizePixel = 0
    delBtn.Text = "X"
    delBtn.Font = Enum.Font.GothamBold
    delBtn.TextSize = 10
    delBtn.TextColor3 = Color3.new(1, 1, 1)
    delBtn.AutoButtonColor = false
    delBtn.Parent = entry
    makeCorner(delBtn, 5)

    delBtn.MouseEnter:Connect(function()
        TweenService:Create(delBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.DangerH}):Play()
    end)
    delBtn.MouseLeave:Connect(function()
        TweenService:Create(delBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Danger}):Play()
    end)
    delBtn.MouseButton1Click:Connect(function()
        for i, v in ipairs(savedRecordings) do
            if v == data then
                table.remove(savedRecordings, i)
                break
            end
        end
        Replay.RefreshRecordingsPanel()
        notify("Replay", "Removed: " .. data.actorName, "trash")
    end)

    return entry
end

local function makeHeader(parent, titleText, closeCallback)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundColor3 = THEME.BgLight
    header.BackgroundTransparency = 0.1
    header.BorderSizePixel = 0
    header.Parent = parent
    makeCorner(header, 10)

    local headerExt = Instance.new("Frame")
    headerExt.Size = UDim2.new(1, 0, 0, 16)
    headerExt.Position = UDim2.new(0, 0, 1, -16)
    headerExt.BackgroundColor3 = THEME.BgLight
    headerExt.BackgroundTransparency = 0.1
    headerExt.BorderSizePixel = 0
    headerExt.Parent = header

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0, 12, 0.5, -3)
    dot.BackgroundColor3 = THEME.Accent
    dot.BorderSizePixel = 0
    dot.Parent = header
    makeCorner(dot, 3)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 24, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = THEME.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 22, 0, 22)
    closeBtn.Position = UDim2.new(1, -30, 0.5, -11)
    closeBtn.BackgroundColor3 = THEME.Danger
    closeBtn.BackgroundTransparency = 0.15
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 10
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = header
    makeCorner(closeBtn, 6)

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.DangerH, BackgroundTransparency = 0}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Danger, BackgroundTransparency = 0.15}):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        parent.Visible = false
        if closeCallback then closeCallback() end
    end)

    -- Draggable
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, parent.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            parent.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return header, closeBtn
end

local function ensureRecordingsPanel()
    if recordingsGui and recordingsGui.Parent then return recordingsGui, recordingsPanel, recordingsListRef end

    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("Replay_RecordingsGui")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "Replay_RecordingsGui"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 998
    pcall(function() sg.Parent = pg end)
    if not sg.Parent then
        sg.Parent = game:GetService("CoreGui")
    end

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 170, 0, 300)
    panel.Position = UDim2.new(0.5, -85, 0.5, -150)
    panel.BackgroundColor3 = THEME.Bg
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = sg
    makeCorner(panel, 10)
    makeStroke(panel, THEME.Accent, 0.5, 1.5)

    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, -24, 0, 2)
    glow.Position = UDim2.new(0, 12, 0, 0)
    glow.BackgroundColor3 = THEME.Accent
    glow.BackgroundTransparency = 0.2
    glow.BorderSizePixel = 0
    glow.Parent = panel

    makeHeader(panel, "Recordings", function()
        if Replay.OnRecordingsPanelToggle then Replay.OnRecordingsPanelToggle(false) end
    end)

    local listScroll = Instance.new("ScrollingFrame")
    listScroll.Size = UDim2.new(1, -14, 1, -48)
    listScroll.Position = UDim2.new(0, 7, 0, 42)
    listScroll.BackgroundColor3 = THEME.BgInput
    listScroll.BackgroundTransparency = 0.3
    listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 3
    listScroll.ScrollBarImageColor3 = THEME.Accent
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    listScroll.Parent = panel
    makeCorner(listScroll, 6)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listScroll

    local listPad = Instance.new("UIPadding")
    listPad.PaddingLeft = UDim.new(0, 4)
    listPad.PaddingRight = UDim.new(0, 4)
    listPad.PaddingTop = UDim.new(0, 4)
    listPad.PaddingBottom = UDim.new(0, 4)
    listPad.Parent = listScroll

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)

    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Name = "EmptyLabel"
    emptyLabel.Size = UDim2.new(1, -10, 0, 30)
    emptyLabel.Position = UDim2.new(0, 5, 0.5, -15)
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "No recordings"
    emptyLabel.Font = Enum.Font.Gotham
    emptyLabel.TextSize = 11
    emptyLabel.TextColor3 = THEME.TextDim
    emptyLabel.Visible = true
    emptyLabel.Parent = listScroll

    recordingsGui = sg
    recordingsPanel = panel
    recordingsListRef = listScroll

    return sg, panel, listScroll
end

function Replay.RefreshRecordingsPanel()
    if not recordingsGui then return end
    local _, _, listScroll = ensureRecordingsPanel()

    for _, child in ipairs(listScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local emptyLabel = listScroll:FindFirstChild("EmptyLabel")

    if #savedRecordings == 0 then
        if emptyLabel then emptyLabel.Visible = true end
    else
        if emptyLabel then emptyLabel.Visible = false end
        for i, data in ipairs(savedRecordings) do
            createRecordingEntry(listScroll, data, i)
        end
    end
end

function Replay.SetRecordingsPanelVisible(v)
    local _, panel = ensureRecordingsPanel()
    if v then
        Replay.RefreshRecordingsPanel()
        if panel.Visible then return end
        panel.Visible = true
        panel.BackgroundTransparency = 1
        panel.Size = UDim2.new(0, 160, 0, 285)
        TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 170, 0, 300)
        }):Play()
    else
        if panel then panel.Visible = false end
    end
end

-- ==========================================================
-- OUTFITS PANEL (340px width)
-- ==========================================================
local function createOutfitEntry(parent, outfitData, index)
    local entry = Instance.new("TextButton")
    entry.Size = UDim2.new(1, -8, 0, 34)
    entry.BackgroundColor3 = THEME.Card
    entry.BorderSizePixel = 0
    entry.Text = ""
    entry.AutoButtonColor = false
    entry.LayoutOrder = index
    entry.Parent = parent
    makeCorner(entry, 6)

    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.Border
    stroke.Transparency = 0.5
    stroke.Thickness = 1
    stroke.Parent = entry

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -16, 1, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = outfitData.Name
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextSize = 11
    nameLabel.TextColor3 = THEME.Text
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = entry

    entry.MouseEnter:Connect(function()
        TweenService:Create(entry, TweenInfo.new(0.15), {BackgroundColor3 = THEME.CardH}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), {Color = THEME.Accent, Transparency = 0.2}):Play()
    end)
    entry.MouseLeave:Connect(function()
        TweenService:Create(entry, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Card}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), {Color = THEME.Border, Transparency = 0.5}):Play()
    end)

    entry.MouseButton1Click:Connect(function()
        Replay.SelectOutfitById(outfitData.Id, outfitData.Name)

        -- Highlight
        for _, sib in ipairs(parent:GetChildren()) do
            if sib:IsA("TextButton") then
                local s = sib:FindFirstChildOfClass("UIStroke")
                if s then
                    TweenService:Create(s, TweenInfo.new(0.15), {Color = THEME.Border, Transparency = 0.5}):Play()
                end
            end
        end
        TweenService:Create(stroke, TweenInfo.new(0.15), {Color = THEME.Accent, Transparency = 0}):Play()
    end)
end

local function ensureOutfitsPanel()
    if outfitsGui and outfitsGui.Parent then return outfitsGui, outfitsPanel, outfitsListRef end

    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("Replay_OutfitsGui")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "Replay_OutfitsGui"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 998
    pcall(function() sg.Parent = pg end)
    if not sg.Parent then
        sg.Parent = game:GetService("CoreGui")
    end

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 280, 0, 340)
    panel.Position = UDim2.new(0.5, -140, 0.5, -170)
    panel.BackgroundColor3 = THEME.Bg
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = sg
    makeCorner(panel, 10)
    makeStroke(panel, THEME.Accent, 0.5, 1.5)

    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, -24, 0, 2)
    glow.Position = UDim2.new(0, 12, 0, 0)
    glow.BackgroundColor3 = THEME.Accent
    glow.BackgroundTransparency = 0.2
    glow.BorderSizePixel = 0
    glow.Parent = panel

    makeHeader(panel, "Outfits", function()
        if Replay.OnOutfitsPanelToggle then Replay.OnOutfitsPanelToggle(false) end
    end)

    -- Username input row
    local inputRow = Instance.new("Frame")
    inputRow.Size = UDim2.new(1, -16, 0, 30)
    inputRow.Position = UDim2.new(0, 8, 0, 44)
    inputRow.BackgroundTransparency = 1
    inputRow.Parent = panel

    local userBox = Instance.new("TextBox")
    userBox.Size = UDim2.new(1, -70, 1, 0)
    userBox.BackgroundColor3 = THEME.BgInput
    userBox.BorderSizePixel = 0
    userBox.Text = ""
    userBox.PlaceholderText = "Username..."
    userBox.PlaceholderColor3 = THEME.TextDim
    userBox.TextColor3 = THEME.Text
    userBox.Font = Enum.Font.Gotham
    userBox.TextSize = 11
    userBox.ClearTextOnFocus = false
    userBox.Parent = inputRow
    makeCorner(userBox, 6)

    local userBoxStroke = Instance.new("UIStroke")
    userBoxStroke.Color = THEME.Border
    userBoxStroke.Transparency = 0.4
    userBoxStroke.Thickness = 1
    userBoxStroke.Parent = userBox

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = userBox

    userBox.Focused:Connect(function()
        TweenService:Create(userBoxStroke, TweenInfo.new(0.15), {Color = THEME.Accent, Transparency = 0.2}):Play()
    end)
    userBox.FocusLost:Connect(function()
        TweenService:Create(userBoxStroke, TweenInfo.new(0.15), {Color = THEME.Border, Transparency = 0.4}):Play()
    end)

    outfitUsernameRef = userBox

    local loadBtn = Instance.new("TextButton")
    loadBtn.Size = UDim2.new(0, 62, 1, 0)
    loadBtn.Position = UDim2.new(1, -62, 0, 0)
    loadBtn.BackgroundColor3 = THEME.Accent
    loadBtn.BorderSizePixel = 0
    loadBtn.Text = "Load"
    loadBtn.Font = Enum.Font.GothamBold
    loadBtn.TextSize = 11
    loadBtn.TextColor3 = Color3.new(1, 1, 1)
    loadBtn.AutoButtonColor = false
    loadBtn.Parent = inputRow
    makeCorner(loadBtn, 6)

    loadBtn.MouseEnter:Connect(function()
        TweenService:Create(loadBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.AccentH}):Play()
    end)
    loadBtn.MouseLeave:Connect(function()
        TweenService:Create(loadBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Accent}):Play()
    end)
    loadBtn.MouseButton1Click:Connect(function()
        Replay.FetchUserOutfits(userBox.Text)
    end)

    -- Status label
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, -16, 0, 18)
    statusLbl.Position = UDim2.new(0, 8, 0, 78)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "Enter username and press Load"
    statusLbl.Font = Enum.Font.Code
    statusLbl.TextSize = 10
    statusLbl.TextColor3 = THEME.TextDim
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.Parent = panel

    outfitStatusRef = statusLbl

    -- Outfit list
    local listScroll = Instance.new("ScrollingFrame")
    listScroll.Size = UDim2.new(1, -16, 1, -160)
    listScroll.Position = UDim2.new(0, 8, 0, 100)
    listScroll.BackgroundColor3 = THEME.BgInput
    listScroll.BackgroundTransparency = 0.3
    listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 4
    listScroll.ScrollBarImageColor3 = THEME.Accent
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    listScroll.Parent = panel
    makeCorner(listScroll, 6)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listScroll

    local listPad = Instance.new("UIPadding")
    listPad.PaddingLeft = UDim.new(0, 4)
    listPad.PaddingRight = UDim.new(0, 4)
    listPad.PaddingTop = UDim.new(0, 4)
    listPad.PaddingBottom = UDim.new(0, 4)
    listPad.Parent = listScroll

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)

    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Name = "EmptyLabel"
    emptyLabel.Size = UDim2.new(1, -10, 0, 30)
    emptyLabel.Position = UDim2.new(0, 5, 0.5, -15)
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "No outfits loaded"
    emptyLabel.Font = Enum.Font.Gotham
    emptyLabel.TextSize = 11
    emptyLabel.TextColor3 = THEME.TextDim
    emptyLabel.Visible = true
    emptyLabel.Parent = listScroll

    -- Apply button
    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(1, -16, 0, 32)
    applyBtn.Position = UDim2.new(0, 8, 1, -40)
    applyBtn.BackgroundColor3 = THEME.Success
    applyBtn.BorderSizePixel = 0
    applyBtn.Text = "Apply to My Avatar"
    applyBtn.Font = Enum.Font.GothamBold
    applyBtn.TextSize = 11
    applyBtn.TextColor3 = Color3.new(1, 1, 1)
    applyBtn.AutoButtonColor = false
    applyBtn.Parent = panel
    makeCorner(applyBtn, 6)

    applyBtn.MouseEnter:Connect(function()
        TweenService:Create(applyBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.SuccessH}):Play()
    end)
    applyBtn.MouseLeave:Connect(function()
        TweenService:Create(applyBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Success}):Play()
    end)
    applyBtn.MouseButton1Click:Connect(function()
        Replay.ApplyOutfitToSelf()
    end)

    outfitsGui = sg
    outfitsPanel = panel
    outfitsListRef = listScroll

    return sg, panel, listScroll
end

function Replay.PopulateOutfitsPanel(userId, outfits)
    local _, _, listScroll = ensureOutfitsPanel()

    for _, child in ipairs(listScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local emptyLabel = listScroll:FindFirstChild("EmptyLabel")
    if emptyLabel then emptyLabel.Visible = false end

    outfitCurrentUserId = userId

    -- Default entry
    createOutfitEntry(listScroll, { Id = nil, Name = "Default Look" }, 0)

    for i, outfit in ipairs(outfits) do
        createOutfitEntry(listScroll, { Id = outfit.Id, Name = outfit.Name or "Unnamed" }, i)
    end
end

function Replay.SetOutfitsPanelVisible(v)
    local _, panel = ensureOutfitsPanel()
    if v then
        if panel.Visible then return end
        panel.Visible = true
        panel.BackgroundTransparency = 1
        panel.Size = UDim2.new(0, 260, 0, 325)
        TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 280, 0, 340)
        }):Play()
    else
        if panel then panel.Visible = false end
    end
end

return Replay