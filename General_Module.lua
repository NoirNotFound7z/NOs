-- ==========================================================
-- GENERAL MODULE — Data + GUI runtime + Server Actions
-- ==========================================================
local General = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

local notifyFn = nil

function General.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then notifyFn(title, content, icon) end
end

-- ==========================================================
-- STATE
-- ==========================================================
General.JoinTime = os.time()
General.AvatarCache = {}
General.SelectedPlayer = nil

-- Callback khi toggle panel thay đổi (UI gán)
General.OnPanelClosed = nil

-- ==========================================================
-- HELPERS
-- ==========================================================
function General.getMembership(player)
    local ok, membershipType = pcall(function()
        return player.MembershipType
    end)
    if ok and membershipType then
        local name = tostring(membershipType):gsub("Enum.MembershipType.", "")
        if name == "Premium" then return "Premium" end
        if name == "None" then return "Free" end
        return name
    end
    return "Unknown"
end

function General.getRig(char)
    if not char then return "N/A" end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return "N/A" end
    return hum.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
end

function General.getHealthInfo(char)
    if not char then return 0, 0 end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return 0, 0 end
    return math.floor(hum.Health), math.floor(hum.MaxHealth)
end

function General.getDistance(player)
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local theirChar = player.Character
    local theirHRP = theirChar and theirChar:FindFirstChild("HumanoidRootPart")
    if myHRP and theirHRP then
        return math.floor((myHRP.Position - theirHRP.Position).Magnitude)
    end
    return nil
end

function General.getPositionString(char)
    if not char then return "N/A" end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return "N/A" end
    local p = hrp.Position
    return string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
end

function General.getState(char)
    if not char then return "N/A" end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return "N/A" end
    local ok, state = pcall(function() return hum:GetState() end)
    if ok and state then
        return tostring(state):gsub("Enum.HumanoidStateType.", "")
    end
    return "N/A"
end

function General.getTeamName(player)
    if player.Team then
        return player.Team.Name
    end
    return "No Team"
end

function General.getPing()
    local ok, val = pcall(function()
        return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    return ok and val or 0
end

function General.getMemoryMB()
    local ok, val = pcall(function()
        return math.floor(Stats:GetTotalMemoryUsageMb())
    end)
    return ok and val or 0
end

function General.getUptime()
    return os.time() - General.JoinTime
end

function General.copyToClipboard(text)
    if setclipboard then
        pcall(function() setclipboard(text) end)
        return true
    end
    return false
end

function General.getOtherPlayers()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, plr)
        end
    end
    table.sort(list, function(a, b)
        return a.UserId < b.UserId
    end)
    return list
end

function General.getPlayerVelocityString(char)
    if not char then return "N/A" end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return "N/A" end
    local v = hrp.AssemblyLinearVelocity
    return string.format("%.1f, %.1f, %.1f (%.1f)", v.X, v.Y, v.Z, v.Magnitude)
end

function General.getLookVectorString(char)
    if not char then return "N/A" end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return "N/A" end
    local lv = hrp.CFrame.LookVector
    return string.format("%.2f, %.2f, %.2f", lv.X, lv.Y, lv.Z)
end

function General.getFloorMaterial(char)
    if not char then return "N/A" end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return "N/A" end
    return tostring(hum.FloorMaterial):gsub("Enum.Material.", "")
end

function General.getWalkSpeed(char)
    if not char then return 0 end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return 0 end
    return hum.WalkSpeed
end

function General.getJumpPower(char)
    if not char then return 0 end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return 0 end
    return hum.JumpPower
end

function General.getHipHeight(char)
    if not char then return 0 end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return 0 end
    return hum.HipHeight
end

function General.getMoveDirectionString(char)
    if not char then return "N/A" end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return "N/A" end
    local m = hum.MoveDirection
    return string.format("%.2f, %.2f, %.2f", m.X, m.Y, m.Z)
end

function General.getPartCount(char)
    if not char then return 0 end
    local count = 0
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then count = count + 1 end
    end
    return count
end

function General.getAccessoryCount(char)
    if not char then return 0 end
    local count = 0
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Accessory") then count = count + 1 end
    end
    return count
end

function General.getCameraMode(player)
    local ok, mode = pcall(function() return player.CameraMode end)
    if ok and mode then
        return tostring(mode):gsub("Enum.CameraMode.", "")
    end
    return "Unknown"
end

function General.getLocaleId(player)
    local ok, locale = pcall(function() return player.LocaleId end)
    return ok and locale or "Unknown"
end

-- ==========================================================
-- AVATAR FETCH (cached)
-- ==========================================================
function General.fetchAvatar(player)
    if General.AvatarCache[player.UserId] then
        return General.AvatarCache[player.UserId]
    end
    local ok, thumb = pcall(function()
        return Players:GetUserThumbnailAsync(
            player.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
    end)
    if ok and thumb then
        General.AvatarCache[player.UserId] = thumb
        return thumb
    end
    return nil
end

-- ==========================================================
-- STATS SNAPSHOT
-- ==========================================================
function General.GetUserProfileText()
    return string.format(
        "Username: %s\nDisplayName: %s\nUserID: %d\nAccountAge: %d days\nMembership: %s\nFollowUserId: %d",
        LocalPlayer.Name,
        LocalPlayer.DisplayName,
        LocalPlayer.UserId,
        LocalPlayer.AccountAge,
        General.getMembership(LocalPlayer),
        LocalPlayer.FollowUserId
    )
end

function General.GetUserTeamText()
    return string.format(
        "Team: %s\nTeamColor: %s",
        General.getTeamName(LocalPlayer),
        LocalPlayer.TeamColor and tostring(LocalPlayer.TeamColor) or "N/A"
    )
end

function General.GetUserCharacterText()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if char and hum then
        return string.format(
            "Rig: %s\nHealth: %d / %d\nWalkSpeed: %.1f\nJumpPower: %.1f\nHipHeight: %.1f\nPosition: %s\nState: %s",
            General.getRig(char),
            math.floor(hum.Health),
            math.floor(hum.MaxHealth),
            hum.WalkSpeed,
            hum.JumpPower,
            hum.HipHeight,
            General.getPositionString(char),
            General.getState(char)
        )
    end
    return "No character loaded"
end

function General.GetUserStatsText(fps)
    return string.format(
        "FPS: %d\nPing: %d ms\nMemory: %d MB\nUptime: %d sec",
        fps or 0,
        General.getPing(),
        General.getMemoryMB(),
        General.getUptime()
    )
end

function General.GetServerInfoText()
    local creatorName = "Unknown"
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        if info and info.Creator and info.Creator.Name then
            creatorName = info.Creator.Name
        end
    end)
    return string.format(
        "JobId: %s\nPlaceId: %d\nGameId: %d\nCreatorName: %s\nWorkspace: %s\nPlaceVersion: %d",
        game.JobId,
        game.PlaceId,
        game.GameId,
        creatorName,
        game.Workspace.Name,
        game.PlaceVersion
    )
end

function General.GetServerStatsText(fps)
    return string.format(
        "FPS: %d\nPing: %d ms\nMemory: %d MB\nUptime: %d sec\nPlayerCount: %d / %d",
        fps or 0,
        General.getPing(),
        General.getMemoryMB(),
        General.getUptime(),
        #Players:GetPlayers(),
        Players.MaxPlayers
    )
end

function General.GetServerNetworkText()
    local ping = General.getPing()
    local pingStatus = ping < 50 and "Excellent" or ping < 100 and "Good" or ping < 200 and "Fair" or "Poor"
    return string.format("Ping: %d ms (%s)", ping, pingStatus)
end

function General.GetPlayersListText()
    local lines = {}
    local count = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        count = count + 1
        local isMe = (plr == LocalPlayer)
        local prefix = isMe and "[YOU] " or "      "
        table.insert(lines, string.format("%s%s (@%s)", prefix, plr.DisplayName, plr.Name))
    end
    return string.format("Total: %d / %d players\n\n%s", count, Players.MaxPlayers, table.concat(lines, "\n"))
end

-- ==========================================================
-- SERVER ACTIONS
-- ==========================================================
function General.RejoinServer()
    notify("Server", "Đang rejoin server...", "refresh-cw")
    task.spawn(function()
        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
        if not ok then
            notify("Server", "Rejoin failed: " .. tostring(err), "x")
        end
    end)
end

function General.ServerHopRandom()
    notify("Server", "Đang tìm server mới...", "search")
    task.spawn(function()
        local ok, err = pcall(function()
            local url = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
                game.PlaceId
            )
            local response = game:HttpGet(url)
            local data = HttpService:JSONDecode(response)

            if not data or not data.data then
                notify("Server", "Không lấy được danh sách server!", "x")
                return
            end

            local candidates = {}
            for _, srv in ipairs(data.data) do
                if srv.id ~= game.JobId and (srv.playing or 0) < (srv.maxPlayers or 100) then
                    table.insert(candidates, srv)
                end
            end

            if #candidates == 0 then
                notify("Server", "Không tìm thấy server mới!", "x")
                return
            end

            local pick = candidates[math.random(1, #candidates)]
            notify("Server", "Đang hop đến server: " .. pick.id, "check")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, LocalPlayer)
        end)
        if not ok then
            notify("Server", "Server Hop failed: " .. tostring(err), "x")
        end
    end)
end

function General.ServerHopBest()
    notify("Server", "Đang tìm server còn nhiều slot...", "search")
    task.spawn(function()
        local ok, err = pcall(function()
            local url = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100",
                game.PlaceId
            )
            local response = game:HttpGet(url)
            local data = HttpService:JSONDecode(response)

            if not data or not data.data then
                notify("Server", "Không lấy được danh sách server!", "x")
                return
            end

            local best = nil
            local bestScore = -math.huge
            for _, srv in ipairs(data.data) do
                if srv.id ~= game.JobId then
                    local free = (srv.maxPlayers or 100) - (srv.playing or 0)
                    if free > bestScore and free > 0 then
                        bestScore = free
                        best = srv
                    end
                end
            end

            if not best then
                notify("Server", "Không tìm thấy server!", "x")
                return
            end

            notify("Server", "Đang hop đến server " .. best.id .. " (" .. bestScore .. " slots free)", "check")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, LocalPlayer)
        end)
        if not ok then
            notify("Server", "Server Hop failed: " .. tostring(err), "x")
        end
    end)
end

function General.CopyAllServerIds()
    task.spawn(function()
        local ok = pcall(function()
            local url = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
                game.PlaceId
            )
            local response = game:HttpGet(url)
            local data = HttpService:JSONDecode(response)

            if not data or not data.data then
                notify("Server", "Không lấy được danh sách!", "x")
                return
            end

            local lines = {}
            for _, srv in ipairs(data.data) do
                table.insert(lines, string.format(
                    "JobId: %s | Players: %d/%d | Ping: %s",
                    srv.id,
                    srv.playing or 0,
                    srv.maxPlayers or 0,
                    srv.ping or "N/A"
                ))
            end

            if General.copyToClipboard(table.concat(lines, "\n")) then
                notify("Server", "Đã copy " .. #data.data .. " server IDs!", "clipboard")
            end
        end)
        if not ok then
            notify("Server", "Copy failed!", "x")
        end
    end)
end

function General.JoinByClipboard()
    if not getclipboard then
        notify("Server", "getclipboard không khả dụng!", "x")
        return
    end
    local ok, jobId = pcall(getclipboard)
    if not ok or not jobId or jobId == "" then
        notify("Server", "Clipboard trống!", "x")
        return
    end
    jobId = jobId:match("^%s*(.-)%s*$")
    notify("Server", "Đang join: " .. jobId, "check")
    task.spawn(function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
        end)
    end)
end

-- ==========================================================
-- PLAYER INFO PANEL (GUI runtime)
-- ==========================================================
local infoGui, infoFrame
local listScroll, listLayout
local infoTitle, infoContent
local playerEntries = {}

local THEME = {
    Bg         = Color3.fromRGB(18, 18, 24),
    BgLight    = Color3.fromRGB(26, 26, 34),
    BgInput    = Color3.fromRGB(14, 14, 18),
    Card       = Color3.fromRGB(30, 30, 40),
    CardHover  = Color3.fromRGB(44, 44, 58),
    Border     = Color3.fromRGB(55, 55, 70),
    Accent     = Color3.fromRGB(138, 116, 249),
    AccentHi   = Color3.fromRGB(160, 140, 255),
    Text       = Color3.fromRGB(240, 240, 245),
    TextDim    = Color3.fromRGB(150, 150, 165),
    Danger     = Color3.fromRGB(220, 70, 90),
}

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

local function createInfoPanel()
    if infoGui then return end

    local pg = LocalPlayer:WaitForChild("PlayerGui")

    local sg = Instance.new("ScreenGui")
    sg.Name = "NoirHub_PlayerInfoGui"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 998
    pcall(function() sg.Parent = pg end)
    if not sg.Parent then
        sg.Parent = game:GetService("CoreGui")
    end

    local frame = Instance.new("Frame")
    frame.Name = "PlayerInfoPanel"
    frame.Size = UDim2.new(0, 420, 0, 300)
    frame.Position = UDim2.new(0.5, -210, 0.5, -150)
    frame.BackgroundColor3 = THEME.Bg
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = sg
    makeCorner(frame, 10)
    makeStroke(frame, THEME.Accent, 0.4, 1.5)

    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, -24, 0, 2)
    glow.Position = UDim2.new(0, 12, 0, 0)
    glow.BackgroundColor3 = THEME.Accent
    glow.BackgroundTransparency = 0.2
    glow.BorderSizePixel = 0
    glow.Parent = frame

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 34)
    header.BackgroundColor3 = THEME.BgLight
    header.BackgroundTransparency = 0.1
    header.BorderSizePixel = 0
    header.Parent = frame
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
    dot.Position = UDim2.new(0, 10, 0.5, -3)
    dot.BackgroundColor3 = THEME.Accent
    dot.BorderSizePixel = 0
    dot.Parent = header
    makeCorner(dot, 3)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 22, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Player Info"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = THEME.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 22, 0, 22)
    closeBtn.Position = UDim2.new(1, -28, 0.5, -11)
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

    closeBtn.MouseButton1Click:Connect(function()
        frame.Visible = false
        if General.OnPanelClosed then General.OnPanelClosed() end
    end)

    local dragStart, startPos, dragging
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local leftFrame = Instance.new("Frame")
    leftFrame.Size = UDim2.new(0, 150, 1, -44)
    leftFrame.Position = UDim2.new(0, 8, 0, 38)
    leftFrame.BackgroundColor3 = THEME.BgInput
    leftFrame.BackgroundTransparency = 0.3
    leftFrame.BorderSizePixel = 0
    leftFrame.Parent = frame
    makeCorner(leftFrame, 6)

    local leftScroll = Instance.new("ScrollingFrame")
    leftScroll.Size = UDim2.new(1, -6, 1, -6)
    leftScroll.Position = UDim2.new(0, 3, 0, 3)
    leftScroll.BackgroundTransparency = 1
    leftScroll.BorderSizePixel = 0
    leftScroll.ScrollBarThickness = 2
    leftScroll.ScrollBarImageColor3 = THEME.Accent
    leftScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    leftScroll.Parent = leftFrame

    local leftLayout = Instance.new("UIListLayout")
    leftLayout.Padding = UDim.new(0, 3)
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftLayout.Parent = leftScroll

    leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        leftScroll.CanvasSize = UDim2.new(0, 0, 0, leftLayout.AbsoluteContentSize.Y + 8)
    end)

    listScroll = leftScroll
    listLayout = leftLayout

    local rightFrame = Instance.new("Frame")
    rightFrame.Size = UDim2.new(1, -168, 1, -44)
    rightFrame.Position = UDim2.new(0, 160, 0, 38)
    rightFrame.BackgroundColor3 = THEME.BgInput
    rightFrame.BackgroundTransparency = 0.3
    rightFrame.BorderSizePixel = 0
    rightFrame.Parent = frame
    makeCorner(rightFrame, 6)

    local rightTitle = Instance.new("TextLabel")
    rightTitle.Name = "InfoTitle"
    rightTitle.Size = UDim2.new(1, -16, 0, 20)
    rightTitle.Position = UDim2.new(0, 8, 0, 4)
    rightTitle.BackgroundTransparency = 1
    rightTitle.Text = "Select a player..."
    rightTitle.Font = Enum.Font.GothamBold
    rightTitle.TextSize = 11
    rightTitle.TextColor3 = THEME.Text
    rightTitle.TextXAlignment = Enum.TextXAlignment.Left
    rightTitle.TextTruncate = Enum.TextTruncate.AtEnd
    rightTitle.Parent = rightFrame

    infoTitle = rightTitle

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -16, 0, 1)
    divider.Position = UDim2.new(0, 8, 0, 26)
    divider.BackgroundColor3 = THEME.Accent
    divider.BackgroundTransparency = 0.7
    divider.BorderSizePixel = 0
    divider.Parent = rightFrame

    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Size = UDim2.new(1, -10, 1, -34)
    contentScroll.Position = UDim2.new(0, 5, 0, 30)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 2
    contentScroll.ScrollBarImageColor3 = THEME.Accent
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScroll.Parent = rightFrame

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 2)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentScroll

    local contentPad = Instance.new("UIPadding")
    contentPad.PaddingLeft = UDim.new(0, 4)
    contentPad.PaddingRight = UDim.new(0, 4)
    contentPad.PaddingTop = UDim.new(0, 2)
    contentPad.PaddingBottom = UDim.new(0, 4)
    contentPad.Parent = contentScroll

    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 6)
    end)

    infoContent = contentScroll

    infoGui = sg
    infoFrame = frame
end

local function buildInfoRow(parent, order, key, value, copyValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 16)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    row.Parent = parent

    local keyLbl = Instance.new("TextLabel")
    keyLbl.Size = UDim2.new(0, 78, 1, 0)
    keyLbl.Position = UDim2.new(0, 0, 0, 0)
    keyLbl.BackgroundTransparency = 1
    keyLbl.Text = key
    keyLbl.Font = Enum.Font.Gotham
    keyLbl.TextSize = 10
    keyLbl.TextColor3 = THEME.TextDim
    keyLbl.TextXAlignment = Enum.TextXAlignment.Left
    keyLbl.TextTruncate = Enum.TextTruncate.AtEnd
    keyLbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, -132, 1, 0)
    valLbl.Position = UDim2.new(0, 80, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(value)
    valLbl.Font = Enum.Font.Code
    valLbl.TextSize = 10
    valLbl.TextColor3 = THEME.Text
    valLbl.TextXAlignment = Enum.TextXAlignment.Left
    valLbl.TextTruncate = Enum.TextTruncate.AtEnd
    valLbl.Parent = row

    if copyValue ~= nil then
        local copyBtn = Instance.new("TextButton")
        copyBtn.Size = UDim2.new(0, 42, 0, 14)
        copyBtn.Position = UDim2.new(1, -44, 0.5, -7)
        copyBtn.BackgroundColor3 = THEME.Card
        copyBtn.BorderSizePixel = 0
        copyBtn.Text = "Copy"
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.TextSize = 9
        copyBtn.TextColor3 = THEME.Text
        copyBtn.AutoButtonColor = false
        copyBtn.Parent = row
        makeCorner(copyBtn, 4)

        copyBtn.MouseEnter:Connect(function()
            TweenService:Create(copyBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Accent}):Play()
        end)
        copyBtn.MouseLeave:Connect(function()
            TweenService:Create(copyBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Card}):Play()
        end)
        copyBtn.MouseButton1Click:Connect(function()
            if General.copyToClipboard(tostring(copyValue)) then
                notify("Copy", "Đã copy " .. key .. "!", "clipboard")
            end
        end)
    end

    return row
end

local function updateInfoContent()
    if not infoContent or not infoTitle then return end

    for _, child in ipairs(infoContent:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    if not General.SelectedPlayer or not General.SelectedPlayer.Parent then
        infoTitle.Text = "Select a player..."
        return
    end

    local plr = General.SelectedPlayer
    local char = plr.Character
    local health, maxHealth = General.getHealthInfo(char)
    local dist = General.getDistance(plr)

    infoTitle.Text = plr.DisplayName

    local rows = {
        { "DisplayName", plr.DisplayName, plr.DisplayName },
        { "Username", plr.Name, plr.Name },
        { "UserID", tostring(plr.UserId), tostring(plr.UserId) },
        { "AccountAge", plr.AccountAge .. " days", tostring(plr.AccountAge) },
        { "Membership", General.getMembership(plr), nil },
        { "FollowUserId", tostring(plr.FollowUserId), tostring(plr.FollowUserId) },
        { "Team", General.getTeamName(plr), nil },
        { "Locale", General.getLocaleId(plr), nil },
        { "CameraMode", General.getCameraMode(plr), nil },
        { "Character", char and "Loaded" or "Not loaded", nil },
        { "Rig", General.getRig(char), nil },
        { "Health", health .. " / " .. maxHealth, nil },
        { "WalkSpeed", string.format("%.1f", General.getWalkSpeed(char)), nil },
        { "JumpPower", string.format("%.1f", General.getJumpPower(char)), nil },
        { "HipHeight", string.format("%.1f", General.getHipHeight(char)), nil },
        { "Floor", General.getFloorMaterial(char), nil },
        { "State", General.getState(char), nil },
        { "MoveDir", General.getMoveDirectionString(char), nil },
        { "Distance", dist and (dist .. " studs") or "N/A", nil },
        { "Position", General.getPositionString(char), nil },
        { "Velocity", General.getPlayerVelocityString(char), nil },
        { "LookVector", General.getLookVectorString(char), nil },
        { "PartCount", tostring(General.getPartCount(char)), nil },
        { "Accessories", tostring(General.getAccessoryCount(char)), nil },
    }

    for i, r in ipairs(rows) do
        buildInfoRow(infoContent, i, r[1], r[2], r[3])
    end
end

local function rebuildPlayerList()
    if not listScroll or not listLayout then return end

    for _, child in ipairs(listScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    playerEntries = {}

    for i, plr in ipairs(General.getOtherPlayers()) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 30)
        btn.BackgroundColor3 = THEME.Card
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.LayoutOrder = i
        btn.Parent = listScroll
        makeCorner(btn, 4)

        local stroke = Instance.new("UIStroke")
        stroke.Color = THEME.Border
        stroke.Transparency = 0.5
        stroke.Thickness = 1
        stroke.Parent = btn

        local avatar = Instance.new("ImageLabel")
        avatar.Size = UDim2.new(0, 22, 0, 22)
        avatar.Position = UDim2.new(0, 4, 0.5, -11)
        avatar.BackgroundColor3 = THEME.BgInput
        avatar.BorderSizePixel = 0
        avatar.Parent = btn
        makeCorner(avatar, 11)

        task.spawn(function()
            local cached = General.AvatarCache[plr.UserId]
            if cached then
                if avatar.Parent then avatar.Image = cached end
                return
            end
            local thumb = General.fetchAvatar(plr)
            if thumb and avatar.Parent then
                avatar.Image = thumb
            end
        end)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -34, 0, 12)
        nameLbl.Position = UDim2.new(0, 30, 0, 3)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = plr.DisplayName
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 10
        nameLbl.TextColor3 = THEME.Text
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Parent = btn

        local subLbl = Instance.new("TextLabel")
        subLbl.Size = UDim2.new(1, -34, 0, 10)
        subLbl.Position = UDim2.new(0, 30, 0, 16)
        subLbl.BackgroundTransparency = 1
        subLbl.Text = "@" .. plr.Name
        subLbl.Font = Enum.Font.Code
        subLbl.TextSize = 8
        subLbl.TextColor3 = THEME.TextDim
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.TextTruncate = Enum.TextTruncate.AtEnd
        subLbl.Parent = btn

        playerEntries[plr] = { button = btn, stroke = stroke }

        btn.MouseEnter:Connect(function()
            if General.SelectedPlayer ~= plr then
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
            end
        end)

        btn.MouseLeave:Connect(function()
            if General.SelectedPlayer ~= plr then
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
            end
        end)

        btn.MouseButton1Click:Connect(function()
            General.SelectedPlayer = plr
            updateInfoContent()

            for _, entry in pairs(playerEntries) do
                TweenService:Create(entry.button, TweenInfo.new(0.15), {
                    BackgroundColor3 = THEME.Card,
                    BackgroundTransparency = 0.3
                }):Play()
                TweenService:Create(entry.stroke, TweenInfo.new(0.15), {
                    Color = THEME.Border,
                    Transparency = 0.5
                }):Play()
            end

            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = THEME.Accent,
                BackgroundTransparency = 0.3
            }):Play()
            TweenService:Create(stroke, TweenInfo.new(0.15), {
                Color = THEME.Accent,
                Transparency = 0
            }):Play()
        end)
    end

    updateInfoContent()
end

function General.TogglePanel(show)
    if show then
        createInfoPanel()
        infoFrame.Visible = true
        infoFrame.BackgroundTransparency = 1
        infoFrame.Size = UDim2.new(0, 400, 0, 285)
        TweenService:Create(infoFrame, TweenInfo.new(0.22), {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 420, 0, 300)
        }):Play()
        rebuildPlayerList()
    else
        if infoFrame then
            infoFrame.Visible = false
        end
    end
end

-- ==========================================================
-- AUTO UPDATE TICK (gọi từ UI hoặc tự đây)
-- ==========================================================
function General.TickInfoPanel()
    if infoFrame and infoFrame.Visible then
        pcall(updateInfoContent)
        if #General.getOtherPlayers() ~= #playerEntries then
            pcall(rebuildPlayerList)
        end
    end
end

return General
