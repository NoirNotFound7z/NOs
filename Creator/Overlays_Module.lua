local Overlays = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local notifyFn = nil

function Overlays.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then notifyFn(title, content, icon) end
end

-- ==========================================================
-- STATE
-- ==========================================================
Overlays.State = {
    RecIndicator = false,
    WatermarkOn = false,
    RuleOfThirds = false,
    CenterCross = false,
    HideUI = false,
    HidePlayers = false,
    NametagsHidden = false,
    RecFrame = nil,
    WatermarkFrame = nil,
    ThirdsFrame = nil,
    CrossFrame = nil,
    CineTop = nil,
    CineBottom = nil,
    Connections = {},
}

local S = Overlays.State

-- ==========================================================
-- SCREEN GUI (overlay container)
-- ==========================================================
local OverlayGui

local function ensureGui()
    if OverlayGui and OverlayGui.Parent then return OverlayGui end
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("NoirOverlayGui")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "NoirOverlayGui"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999
    pcall(function() sg.Parent = pg end)
    if not sg.Parent then
        sg.Parent = game:GetService("CoreGui")
    end

    OverlayGui = sg
    return sg
end

-- ==========================================================
-- REC INDICATOR
-- ==========================================================
function Overlays.ToggleRec(state)
    S.RecIndicator = state
    if state then
        local sg = ensureGui()

        local rec = Instance.new("Frame")
        rec.Name = "RECIndicator"
        rec.Size = UDim2.new(0, 80, 0, 28)
        rec.Position = UDim2.new(0, 20, 0, 20)
        rec.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        rec.BackgroundTransparency = 0.3
        rec.BorderSizePixel = 0
        rec.ZIndex = 50
        rec.Parent = sg

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = rec

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 10, 0, 10)
        dot.Position = UDim2.new(0, 8, 0.5, -5)
        dot.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
        dot.BorderSizePixel = 0
        dot.ZIndex = 51
        dot.Parent = rec

        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(1, 0)
        dc.Parent = dot

        local recTxt = Instance.new("TextLabel")
        recTxt.Size = UDim2.new(1, -26, 1, 0)
        recTxt.Position = UDim2.new(0, 22, 0, 0)
        recTxt.BackgroundTransparency = 1
        recTxt.Text = "REC"
        recTxt.Font = Enum.Font.GothamBold
        recTxt.TextSize = 14
        recTxt.TextColor3 = Color3.fromRGB(255, 40, 40)
        recTxt.TextXAlignment = Enum.TextXAlignment.Left
        recTxt.ZIndex = 51
        recTxt.Parent = rec

        S.RecFrame = rec

        task.spawn(function()
            while rec.Parent do
                TweenService:Create(dot, TweenInfo.new(0.6), {BackgroundTransparency = 0.8}):Play()
                task.wait(0.6)
                TweenService:Create(dot, TweenInfo.new(0.6), {BackgroundTransparency = 0}):Play()
                task.wait(0.6)
            end
        end)

        notify("REC", "Recording indicator shown", "circle-dot")
    else
        if S.RecFrame then S.RecFrame:Destroy(); S.RecFrame = nil end
        notify("REC OFF", "", "x")
    end
end

-- ==========================================================
-- RULE OF THIRDS
-- ==========================================================
function Overlays.ToggleThirds(state)
    S.RuleOfThirds = state
    if state then
        local sg = ensureGui()

        local f = Instance.new("Frame")
        f.Name = "ThirdsOverlay"
        f.Size = UDim2.new(1, 0, 1, 0)
        f.BackgroundTransparency = 1
        f.ZIndex = 40
        f.Parent = sg

        for i = 1, 2 do
            local vLine = Instance.new("Frame")
            vLine.Size = UDim2.new(0, 1, 1, 0)
            vLine.Position = UDim2.new(i/3, 0, 0, 0)
            vLine.BackgroundColor3 = Color3.new(1, 1, 1)
            vLine.BackgroundTransparency = 0.6
            vLine.BorderSizePixel = 0
            vLine.ZIndex = 41
            vLine.Parent = f

            local hLine = Instance.new("Frame")
            hLine.Size = UDim2.new(1, 0, 0, 1)
            hLine.Position = UDim2.new(0, 0, i/3, 0)
            hLine.BackgroundColor3 = Color3.new(1, 1, 1)
            hLine.BackgroundTransparency = 0.6
            hLine.BorderSizePixel = 0
            hLine.ZIndex = 41
            hLine.Parent = f
        end

        S.ThirdsFrame = f
        notify("Thirds", "Grid overlay active", "grid")
    else
        if S.ThirdsFrame then S.ThirdsFrame:Destroy(); S.ThirdsFrame = nil end
        notify("Thirds OFF", "", "x")
    end
end

-- ==========================================================
-- CENTER CROSSHAIR
-- ==========================================================
function Overlays.ToggleCross(state)
    S.CenterCross = state
    if state then
        local sg = ensureGui()

        local f = Instance.new("Frame")
        f.Name = "CenterCross"
        f.Size = UDim2.new(0, 30, 0, 30)
        f.Position = UDim2.new(0.5, -15, 0.5, -15)
        f.BackgroundTransparency = 1
        f.ZIndex = 40
        f.Parent = sg

        local h = Instance.new("Frame")
        h.Size = UDim2.new(1, 0, 0, 1)
        h.Position = UDim2.new(0, 0, 0.5, 0)
        h.BackgroundColor3 = Color3.new(1, 1, 1)
        h.BackgroundTransparency = 0.4
        h.BorderSizePixel = 0
        h.ZIndex = 41
        h.Parent = f

        local v = Instance.new("Frame")
        v.Size = UDim2.new(0, 1, 1, 0)
        v.Position = UDim2.new(0.5, 0, 0, 0)
        v.BackgroundColor3 = Color3.new(1, 1, 1)
        v.BackgroundTransparency = 0.4
        v.BorderSizePixel = 0
        v.ZIndex = 41
        v.Parent = f

        S.CrossFrame = f
        notify("Crosshair", "Center guide active", "crosshair")
    else
        if S.CrossFrame then S.CrossFrame:Destroy(); S.CrossFrame = nil end
        notify("Cross OFF", "", "x")
    end
end

-- ==========================================================
-- CINEMATIC BARS
-- ==========================================================
function Overlays.ToggleBars(state)
    if state then
        local sg = ensureGui()

        local topBar = Instance.new("Frame")
        topBar.Name = "CineTop"
        topBar.Size = UDim2.new(1, 0, 0, 0)
        topBar.Position = UDim2.new(0, 0, 0, 0)
        topBar.BackgroundColor3 = Color3.new(0, 0, 0)
        topBar.BorderSizePixel = 0
        topBar.ZIndex = 45
        topBar.Parent = sg
        TweenService:Create(topBar, TweenInfo.new(0.8), {Size = UDim2.new(1, 0, 0.12, 0)}):Play()

        local btmBar = Instance.new("Frame")
        btmBar.Name = "CineBottom"
        btmBar.Size = UDim2.new(1, 0, 0, 0)
        btmBar.Position = UDim2.new(0, 0, 1, 0)
        btmBar.AnchorPoint = Vector2.new(0, 1)
        btmBar.BackgroundColor3 = Color3.new(0, 0, 0)
        btmBar.BorderSizePixel = 0
        btmBar.ZIndex = 45
        btmBar.Parent = sg
        TweenService:Create(btmBar, TweenInfo.new(0.8), {Size = UDim2.new(1, 0, 0.12, 0)}):Play()

        S.CineTop = topBar
        S.CineBottom = btmBar
        notify("Cinematic", "Letterbox bars active", "film")
    else
        if S.CineTop then
            local t = S.CineTop
            TweenService:Create(t, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0, 0)}):Play()
            task.delay(0.55, function() t:Destroy() end)
            S.CineTop = nil
        end
        if S.CineBottom then
            local b = S.CineBottom
            TweenService:Create(b, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0, 0)}):Play()
            task.delay(0.55, function() b:Destroy() end)
            S.CineBottom = nil
        end
        notify("Bars OFF", "", "x")
    end
end

-- ==========================================================
-- WATERMARK
-- ==========================================================
function Overlays.ToggleWatermark(state)
    S.WatermarkOn = state
    if state then
        local sg = ensureGui()

        local wm = Instance.new("TextLabel")
        wm.Name = "Watermark"
        wm.Size = UDim2.new(0, 200, 0, 24)
        wm.Position = UDim2.new(1, -210, 1, -34)
        wm.BackgroundTransparency = 1
        wm.Text = "© " .. LocalPlayer.Name .. " | Studio Pro"
        wm.Font = Enum.Font.GothamBold
        wm.TextSize = 12
        wm.TextColor3 = Color3.new(1, 1, 1)
        wm.TextTransparency = 0.4
        wm.TextXAlignment = Enum.TextXAlignment.Right
        wm.ZIndex = 50
        wm.Parent = sg

        S.WatermarkFrame = wm
        notify("Watermark", "Your name shown", "copyright")
    else
        if S.WatermarkFrame then S.WatermarkFrame:Destroy(); S.WatermarkFrame = nil end
        notify("Watermark OFF", "", "x")
    end
end

-- ==========================================================
-- SCENE CLEANUP
-- ==========================================================
function Overlays.ToggleHidePlayers(state)
    S.HidePlayers = state
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = state and 1 or 0
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    part.Transparency = state and 1 or 0
                end
            end
        end
    end
    notify(state and "Players Hidden" or "Players Visible", "", state and "eye-off" or "eye")
end

function Overlays.ToggleHideNametags(state)
    S.NametagsHidden = state
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                for _, bg in pairs(head:GetChildren()) do
                    if bg:IsA("BillboardGui") then
                        bg.Enabled = not state
                    end
                end
            end
        end
    end
    notify(state and "Tags Hidden" or "Tags Shown", "", state and "eye-off" or "eye")
end

function Overlays.ToggleHideUI(state)
    S.HideUI = state
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not state)
    end)
    notify(state and "UI Hidden" or "UI Shown", "", state and "eye-off" or "eye")
end

-- ==========================================================
-- CLEANUP
-- ==========================================================
function Overlays.Cleanup()
    if S.RecFrame then S.RecFrame:Destroy() end
    if S.ThirdsFrame then S.ThirdsFrame:Destroy() end
    if S.CrossFrame then S.CrossFrame:Destroy() end
    if S.CineTop then S.CineTop:Destroy() end
    if S.CineBottom then S.CineBottom:Destroy() end
    if S.WatermarkFrame then S.WatermarkFrame:Destroy() end
    if OverlayGui then OverlayGui:Destroy() end

    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
    end)
end

return Overlays