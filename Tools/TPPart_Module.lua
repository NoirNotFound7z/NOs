local TPPart = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local notifyFn = nil

function TPPart.SetNotify(fn)
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
    Warn       = Color3.fromRGB(235, 160, 80),
    WarnH      = Color3.fromRGB(250, 180, 100),
}

-- ==========================================================
-- STATE
-- ==========================================================
local foundParts = {}
local blacklistedParts = {}
local originalPositions = {}
local currentIndex = 0
local currentOffsetIndex = 1
local offsetValues = {0.1, 0.3, 0.5, 0.8, 1, 2, 5}
local isHighlightAll = false
local isPicking = false
local isMultiPicking = false
local pickInputStart = nil

local currentWeldTarget = nil
local targetAttachment = nil
local myAttachment = nil
local alignPos = nil
local alignOri = nil
local isViewing = false

TPPart.OnSelectionChanged = nil

local function fireSelectionChanged()
    if TPPart.OnSelectionChanged then
        TPPart.OnSelectionChanged(currentIndex, #foundParts)
    end
end

-- ==========================================================
-- ESP HIGHLIGHT (CoreGui)
-- ==========================================================
local CoreGuiRef = game:GetService("CoreGui")

local ESP = Instance.new("Highlight")
ESP.Name = "SkitESP"
ESP.FillColor = Color3.fromRGB(45, 110, 255)
ESP.OutlineColor = Color3.fromRGB(255, 255, 255)
ESP.FillTransparency = 0.5
ESP.OutlineTransparency = 0
ESP.Parent = CoreGuiRef
ESP.Adornee = nil

local AllHighlightsFolder = Instance.new("Folder")
AllHighlightsFolder.Name = "SkitESP_All"
AllHighlightsFolder.Parent = CoreGuiRef

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

local function isFuzzyMatch(targetName, query)
    targetName = string.lower(targetName)
    query = string.lower(query)
    if string.find(targetName, query, 1, true) then return true end
    local words = string.split(query, " ")
    local validWordsCount = 0
    local successfulMatches = 0
    for _, word in ipairs(words) do
        if word ~= "" and word ~= " " then
            validWordsCount = validWordsCount + 1
            if string.find(targetName, word, 1, true) then successfulMatches = successfulMatches + 1 end
        end
    end
    return (validWordsCount > 0 and successfulMatches == validWordsCount)
end

-- ==========================================================
-- SEARCH
-- ==========================================================
function TPPart.PerformSearch(query)
    foundParts = {}

    if query and query ~= "" then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if isFuzzyMatch(p.Name, query) or isFuzzyMatch(p.DisplayName, query) then
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    if root and not blacklistedParts[root] then
                        table.insert(foundParts, root)
                    end
                end
            end
        end

        if #foundParts == 0 then
            for _, obj in pairs(workspace:GetDescendants()) do
                if isFuzzyMatch(obj.Name, query) then
                    if obj:IsA("BasePart") and not blacklistedParts[obj] then
                        table.insert(foundParts, obj)
                    elseif obj:IsA("Model") and obj.PrimaryPart and not blacklistedParts[obj.PrimaryPart] then
                        table.insert(foundParts, obj.PrimaryPart)
                    end
                end
            end
        end
    end

    currentIndex = #foundParts > 0 and 1 or 0
    TPPart.UpdateSelection()
    TPPart.UpdateHighlightAll()
end

function TPPart.UpdateHighlightAll()
    AllHighlightsFolder:ClearAllChildren()
    if isHighlightAll then
        for _, part in ipairs(foundParts) do
            local h = Instance.new("Highlight")
            h.Adornee = part
            h.FillColor = Color3.fromRGB(255, 150, 45)
            h.OutlineColor = Color3.fromRGB(255, 255, 255)
            h.FillTransparency = 0.6
            h.Parent = AllHighlightsFolder
        end
    end
end

function TPPart.UpdateSelection()
    if #foundParts == 0 then
        ESP.Adornee = nil
        if isViewing then
            isViewing = false
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                workspace.CurrentCamera.CameraSubject = char.Humanoid
            end
        end
    else
        ESP.Adornee = foundParts[currentIndex]
        if isViewing then
            workspace.CurrentCamera.CameraSubject = foundParts[currentIndex]
        end
    end
    fireSelectionChanged()
end

function TPPart.CycleLeft()
    if #foundParts > 0 then
        currentIndex = currentIndex - 1
        if currentIndex < 1 then currentIndex = #foundParts end
        TPPart.UpdateSelection()
    end
end

function TPPart.CycleRight()
    if #foundParts > 0 then
        currentIndex = currentIndex + 1
        if currentIndex > #foundParts then currentIndex = 1 end
        TPPart.UpdateSelection()
    end
end

function TPPart.GetCounters()
    return currentIndex, #foundParts
end

-- ==========================================================
-- HIDE / BLACKLIST
-- ==========================================================
function TPPart.HideCurrent()
    if #foundParts > 0 and currentIndex > 0 then
        local part = foundParts[currentIndex]
        blacklistedParts[part] = true
        table.remove(foundParts, currentIndex)

        if currentIndex > #foundParts then currentIndex = #foundParts end
        if currentIndex == 0 and #foundParts > 0 then currentIndex = 1 end

        TPPart.UpdateSelection()
        TPPart.UpdateHighlightAll()
        TPPart.RefreshHiddenPartsPanel()
    end
end

function TPPart.ClearSelection()
    foundParts = {}
    currentIndex = 0
    TPPart.UpdateSelection()
    TPPart.UpdateHighlightAll()
end

function TPPart.ToggleHighlightAll()
    isHighlightAll = not isHighlightAll
    TPPart.UpdateHighlightAll()
    return isHighlightAll
end

function TPPart.GetHighlightAll()
    return isHighlightAll
end

-- ==========================================================
-- PHYSICS / WELD
-- ==========================================================
local function toggleCharacterPhysics(isWelded)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Massless = isWelded
            if part.Name ~= "HumanoidRootPart" then part.CanCollide = not isWelded end
        end
    end
    if humanoid then humanoid.PlatformStand = isWelded end
end

function TPPart.StopWeld()
    if targetAttachment then targetAttachment:Destroy() targetAttachment = nil end
    if myAttachment then myAttachment:Destroy() myAttachment = nil end
    if alignPos then alignPos:Destroy() alignPos = nil end
    if alignOri then alignOri:Destroy() alignOri = nil end
    currentWeldTarget = nil
    toggleCharacterPhysics(false)
    notify("TP Part", "Unwelded", "unlink")
end

function TPPart.Weld()
    if #foundParts == 0 or currentIndex == 0 then
        notify("TP Part", "No target found", "x")
        return false
    end

    local targetPart = foundParts[currentIndex]
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if hrp and targetPart and targetPart.Parent then
        TPPart.StopWeld()
        currentWeldTarget = targetPart

        targetAttachment = Instance.new("Attachment")
        targetAttachment.Name = "SkitTargetAtt"
        targetAttachment.Parent = currentWeldTarget
        targetAttachment.Position = Vector3.new(0, (currentWeldTarget.Size.Y / 2) + (hrp.Size.Y / 2), 0)

        myAttachment = Instance.new("Attachment")
        myAttachment.Name = "SkitMyAtt"
        myAttachment.Parent = hrp

        alignPos = Instance.new("AlignPosition")
        alignPos.Attachment0 = myAttachment
        alignPos.Attachment1 = targetAttachment
        alignPos.RigidityEnabled = true
        alignPos.Parent = hrp

        alignOri = Instance.new("AlignOrientation")
        alignOri.Attachment0 = myAttachment
        alignOri.Attachment1 = targetAttachment
        alignOri.RigidityEnabled = true
        alignOri.Parent = hrp

        toggleCharacterPhysics(true)
        notify("TP Part", "Welded to " .. targetPart.Name, "link")
        return true
    end
    return false
end

function TPPart.Teleport()
    if #foundParts == 0 or currentIndex == 0 then
        notify("TP Part", "No target found", "x")
        return false
    end

    local targetPart = foundParts[currentIndex]
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if hrp and targetPart and targetPart.Parent then
        hrp.CFrame = targetPart.CFrame
        notify("TP Part", "Teleported to " .. targetPart.Name, "move")
        return true
    end
    return false
end

function TPPart.ToggleView()
    if #foundParts == 0 or currentIndex == 0 then
        notify("TP Part", "No target found", "x")
        return false
    end

    local targetPart = foundParts[currentIndex]
    local char = LocalPlayer.Character
    local human = char and char:FindFirstChild("Humanoid")

    if isViewing then
        isViewing = false
        if human then workspace.CurrentCamera.CameraSubject = human end
        notify("TP Part", "View off", "eye-off")
    else
        isViewing = true
        workspace.CurrentCamera.CameraSubject = targetPart
        notify("TP Part", "View on " .. targetPart.Name, "eye")
    end
    return isViewing
end

-- ==========================================================
-- BRING / RESET
-- ==========================================================
function TPPart.Bring()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local partsToBring = {}

    if #foundParts > 1 then
        partsToBring = foundParts
    elseif #foundParts == 1 and currentIndex > 0 then
        table.insert(partsToBring, foundParts[currentIndex])
    end

    if #partsToBring > 0 then
        for _, part in ipairs(partsToBring) do
            if part and part.Parent and part:IsA("BasePart") then
                if not originalPositions[part] then
                    originalPositions[part] = part.CFrame
                end
                part.CFrame = hrp.CFrame
            end
        end
        notify("TP Part", "Brought " .. #partsToBring .. " parts", "download")
    end
end

function TPPart.ResetPositions()
    local count = 0
    for part, origCFrame in pairs(originalPositions) do
        if part and part.Parent and part:IsA("BasePart") then
            part.CFrame = origCFrame
            count = count + 1
        end
    end
    originalPositions = {}
    notify("TP Part", "Reset " .. count .. " parts", "rotate-ccw")
end

-- ==========================================================
-- STEP SIZE
-- ==========================================================
function TPPart.CycleStepSize()
    currentOffsetIndex = currentOffsetIndex + 1
    if currentOffsetIndex > #offsetValues then currentOffsetIndex = 1 end
    return offsetValues[currentOffsetIndex]
end

function TPPart.GetStepSize()
    return offsetValues[currentOffsetIndex]
end

function TPPart.OffsetCharacter(dirVector)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local currentStep = offsetValues[currentOffsetIndex]

    if currentWeldTarget and targetAttachment then
        targetAttachment.CFrame = targetAttachment.CFrame * CFrame.new(dirVector * currentStep)
    else
        hrp.CFrame = hrp.CFrame * CFrame.new(dirVector * currentStep)
    end
end

-- ==========================================================
-- PICK MODE
-- ==========================================================
local pickOverlayGui
local pickOverlay

local function ensurePickOverlay()
    if pickOverlayGui and pickOverlayGui.Parent then return pickOverlayGui, pickOverlay end

    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("TPPart_PickOverlay")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "TPPart_PickOverlay"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 997
    pcall(function() sg.Parent = pg end)
    if not sg.Parent then
        sg.Parent = game:GetService("CoreGui")
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 40)
    frame.Position = UDim2.new(0.5, -110, 0, 40)
    frame.BackgroundColor3 = THEME.Bg
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = sg
    makeCorner(frame, 20)
    makeStroke(frame, THEME.Accent, 0.3, 1.5)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0, 16, 0.5, -5)
    dot.BackgroundColor3 = THEME.Accent
    dot.BorderSizePixel = 0
    dot.Parent = frame
    makeCorner(dot, 5)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 34, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "Pick Mode: Click a part"
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = THEME.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    pickOverlayGui = sg
    pickOverlay = frame

    return sg, frame
end

local function setPickOverlayText(text)
    local _, frame = ensurePickOverlay()
    if frame then
        local label = frame:FindFirstChildWhichIsA("TextLabel")
        if label then label.Text = text end
    end
end

local function setPickOverlayVisible(v)
    local _, frame = ensurePickOverlay()
    if not frame then return end

    if v then
        frame.Visible = true
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(0, 200, 0, 36)
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.1,
            Size = UDim2.new(0, 220, 0, 40)
        }):Play()
    else
        frame.Visible = false
    end
end

function TPPart.SetPicking(v)
    isPicking = v
    if v then
        isMultiPicking = false
        setPickOverlayText("Pick Mode: Click a part")
        setPickOverlayVisible(true)
        notify("TP Part", "Pick mode ON", "mouse-pointer")
    else
        if not isMultiPicking then setPickOverlayVisible(false) end
        notify("TP Part", "Pick mode OFF", "mouse-pointer")
    end
end

function TPPart.GetPicking() return isPicking end

function TPPart.SetMultiPicking(v)
    isMultiPicking = v
    if v then
        isPicking = false
        isHighlightAll = true
        TPPart.UpdateHighlightAll()
        setPickOverlayText("Multi-Pick: Click to add/remove")
        setPickOverlayVisible(true)
        notify("TP Part", "Multi-Pick ON", "mouse-pointer-click")
    else
        if not isPicking then setPickOverlayVisible(false) end
        notify("TP Part", "Multi-Pick OFF", "mouse-pointer-click")
    end
end

function TPPart.GetMultiPicking() return isMultiPicking end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if (isPicking or isMultiPicking) then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pickInputStart = input.Position
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if pickInputStart then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local dist = (input.Position - pickInputStart).Magnitude
            pickInputStart = nil

            if dist < 10 then
                local target = Mouse.Target
                if target then
                    if isPicking then
                        isPicking = false
                        setPickOverlayVisible(false)
                        TPPart.PerformSearch(target.Name)
                        if TPPart.OnPickDone then TPPart.OnPickDone(target.Name) end
                        notify("TP Part", "Picked: " .. target.Name, "target")
                    elseif isMultiPicking then
                        local indexToRemove = nil
                        for i, p in ipairs(foundParts) do
                            if p == target then
                                indexToRemove = i
                                break
                            end
                        end

                        if indexToRemove then
                            table.remove(foundParts, indexToRemove)
                            if currentIndex > #foundParts then currentIndex = #foundParts end
                            if currentIndex == 0 and #foundParts > 0 then currentIndex = 1 end
                        elseif not blacklistedParts[target] then
                            table.insert(foundParts, target)
                            currentIndex = #foundParts
                        end

                        TPPart.UpdateSelection()
                        TPPart.UpdateHighlightAll()
                    end
                end
            end
        end
    end
end)

TPPart.OnPickDone = nil

-- ==========================================================
-- HIDDEN PARTS PANEL
-- ==========================================================
local hiddenGui, hiddenPanel, hiddenListRef

local function createHiddenEntry(parent, part, index)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -8, 0, 34)
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

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -70, 1, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = part.Name
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextSize = 11
    nameLabel.TextColor3 = THEME.Text
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = entry

    local restoreBtn = Instance.new("TextButton")
    restoreBtn.Size = UDim2.new(0, 56, 0, 24)
    restoreBtn.Position = UDim2.new(1, -62, 0.5, -12)
    restoreBtn.BackgroundColor3 = THEME.Success
    restoreBtn.BorderSizePixel = 0
    restoreBtn.Text = "Restore"
    restoreBtn.Font = Enum.Font.GothamBold
    restoreBtn.TextSize = 10
    restoreBtn.TextColor3 = Color3.new(1, 1, 1)
    restoreBtn.AutoButtonColor = false
    restoreBtn.Parent = entry
    makeCorner(restoreBtn, 5)

    restoreBtn.MouseEnter:Connect(function()
        TweenService:Create(restoreBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.SuccessH}):Play()
    end)
    restoreBtn.MouseLeave:Connect(function()
        TweenService:Create(restoreBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Success}):Play()
    end)
    restoreBtn.MouseButton1Click:Connect(function()
        blacklistedParts[part] = nil
        TPPart.RefreshHiddenPartsPanel()
        notify("TP Part", "Restored: " .. part.Name, "undo")
    end)
end

local function makePanelHeader(parent, titleText, closeCallback)
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

    return header
end

local function ensureHiddenPanel()
    if hiddenGui and hiddenGui.Parent then return hiddenGui, hiddenPanel, hiddenListRef end

    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("TPPart_HiddenGui")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "TPPart_HiddenGui"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 998
    pcall(function() sg.Parent = pg end)
    if not sg.Parent then
        sg.Parent = game:GetService("CoreGui")
    end

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 200, 0, 280)
    panel.Position = UDim2.new(0.5, -100, 0.5, -140)
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

    makePanelHeader(panel, "Hidden Parts", function()
        if TPPart.OnHiddenPanelToggle then TPPart.OnHiddenPanelToggle(false) end
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
    emptyLabel.Text = "No hidden parts"
    emptyLabel.Font = Enum.Font.Gotham
    emptyLabel.TextSize = 11
    emptyLabel.TextColor3 = THEME.TextDim
    emptyLabel.Visible = true
    emptyLabel.Parent = listScroll

    hiddenGui = sg
    hiddenPanel = panel
    hiddenListRef = listScroll

    return sg, panel, listScroll
end

function TPPart.RefreshHiddenPartsPanel()
    if not hiddenGui then return end
    local _, _, listScroll = ensureHiddenPanel()

    for _, child in ipairs(listScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local emptyLabel = listScroll:FindFirstChild("EmptyLabel")
    local count = 0

    for part, _ in pairs(blacklistedParts) do
        if part and part.Parent then
            count = count + 1
            createHiddenEntry(listScroll, part, count)
        else
            blacklistedParts[part] = nil
        end
    end

    if count == 0 then
        if emptyLabel then emptyLabel.Visible = true end
    else
        if emptyLabel then emptyLabel.Visible = false end
    end
end

function TPPart.SetHiddenPanelVisible(v)
    local _, panel = ensureHiddenPanel()
    if v then
        TPPart.RefreshHiddenPartsPanel()
        if panel.Visible then return end
        panel.Visible = true
        panel.BackgroundTransparency = 1
        panel.Size = UDim2.new(0, 185, 0, 265)
        TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 200, 0, 280)
        }):Play()
    else
        if panel then panel.Visible = false end
    end
end

TPPart.OnHiddenPanelToggle = nil

return TPPart