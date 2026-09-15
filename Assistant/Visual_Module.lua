local Visual = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local notifyFn = nil

function Visual.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then notifyFn(title, content, icon) end
end

-- ==========================================================
-- STATE
-- ==========================================================
local espEnabled = false
local espConnections = {}
local espInstances = {}
local nameMode = 2

local statusESPEnabled = false
local statusInstances = {}
local statusConnections = {}

local playerSkeletonEnabled = false
local playerSkeletonESP = {}

local showTracer = false
local tracerDistance = 2000
local Tracers = {}
local Boxes = {}
local HealthBars = {}

local npcSkeletonEnabled = false
local npcSkeletonESP = {}
local npcCache = {}
local npcCacheDirty = true

local xrayEnabled = false
local savedTransparency = {}
local xrayTransparency = 0.5

Visual.highlightSettings = {
    UseOutline = false,
    UseFill = false,
    Color = Color3.fromRGB(0, 255, 0),
    UseTeamColor = true,
}

Visual.npcNameSettings = { EspName = false }
Visual.npcHighlightSettings = {
    Outline = false,
    Fill = false,
    UseTeamColor = true,
    Color = Color3.fromRGB(0, 255, 255),
}
Visual.npcTracerSettings = { TracerBox = false }

-- ==========================================================
-- COLOR HELPERS
-- ==========================================================
local function getTeamColor(plr)
    if plr.Team ~= nil and LocalPlayer.Team ~= nil then
        if plr.Team == LocalPlayer.Team then
            return Color3.fromRGB(0, 255, 0)
        else
            return Color3.fromRGB(255, 0, 0)
        end
    end
    return Color3.fromRGB(255, 255, 255)
end

local function getESPColor(plr)
    return getTeamColor(plr)
end

local function getName(plr)
    if nameMode == 1 then return "@" .. plr.Name
    elseif nameMode == 2 then return plr.DisplayName
    else return plr.DisplayName .. " (@" .. plr.Name .. ")" end
end

local function getNPCColor(npc)
    if npc:FindFirstChild("TeamColor") then
        if LocalPlayer.TeamColor and npc.TeamColor == LocalPlayer.TeamColor then
            return Color3.fromRGB(0, 255, 255)
        else
            return Color3.fromRGB(255, 165, 0)
        end
    end
    return Color3.fromRGB(255, 255, 255)
end

-- ==========================================================
-- PLAYER ESP (Name + Distance)
-- ==========================================================
local function removeAllESP()
    for _, gui in pairs(espInstances) do if gui and gui.Parent then gui:Destroy() end end
    for _, conn in pairs(espConnections) do conn:Disconnect() end
    espInstances = {}
    espConnections = {}
end

local function createESP(plr)
    if plr == LocalPlayer then return end
    if not plr.Character then return end
    local head = plr.Character:FindFirstChild("Head")
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not head or not hrp then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NoirESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Parent = head

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.SourceSansBold
    txt.TextSize = 14
    txt.TextStrokeTransparency = 0.5
    txt.Parent = billboard

    local conn = RunService.RenderStepped:Connect(function()
        if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            txt.Visible = false
            return
        end
        txt.Visible = true
        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
        txt.Text = getName(plr) .. " | " .. math.floor(dist) .. "m"
        txt.TextColor3 = getESPColor(plr)
    end)

    table.insert(espInstances, billboard)
    table.insert(espConnections, conn)
end

function Visual.SetPlayerESPEnabled(state)
    espEnabled = state
    removeAllESP()
    if not state then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if plr.Character then createESP(plr) end
            table.insert(espConnections, plr.CharacterAdded:Connect(function()
                if espEnabled then task.wait(0.5); createESP(plr) end
            end))
        end
    end

    table.insert(espConnections, Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function()
            if espEnabled then task.wait(0.5); createESP(plr) end
        end)
    end))
end

function Visual.SetNameMode(mode)
    nameMode = mode
end

-- ==========================================================
-- STATUS ESP
-- ==========================================================
local function getPlayerStatus(plr)
    local char = plr.Character
    if not char then return "No Character" end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return "No Humanoid" end

    if hum:GetState() == Enum.HumanoidStateType.Freefall then return "Falling"
    elseif hum:GetState() == Enum.HumanoidStateType.Jumping then return "Jumping"
    elseif hum:GetState() == Enum.HumanoidStateType.Ragdoll then return "Ragdoll"
    elseif hum:GetState() == Enum.HumanoidStateType.Climbing then return "Climbing"
    elseif hum:GetState() == Enum.HumanoidStateType.Swimming then return "Swimming"
    elseif hum.Health <= 0 then return "Dead"
    elseif hum.Health < 30 then return "Low HP"
    end
    return "Normal"
end

local function createStatusESP(plr)
    if plr == LocalPlayer then return end
    if not plr.Character then return end
    local head = plr.Character:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "StatusESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 150, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = head

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.SourceSansBold
    txt.TextSize = 12
    txt.TextStrokeTransparency = 0.5
    txt.Parent = billboard

    local conn = RunService.RenderStepped:Connect(function()
        if not plr.Character or not plr.Character:FindFirstChild("Head") then
            txt.Visible = false
            return
        end
        txt.Visible = true
        local status = getPlayerStatus(plr)
        txt.Text = status
        if status == "Low HP" or status == "Dead" then
            txt.TextColor3 = Color3.fromRGB(255, 0, 0)
        elseif status == "Falling" or status == "Ragdoll" then
            txt.TextColor3 = Color3.fromRGB(255, 200, 0)
        else
            txt.TextColor3 = getESPColor(plr)
        end
    end)
    table.insert(statusInstances, billboard)
    table.insert(statusConnections, conn)
end

function Visual.SetStatusESPEnabled(state)
    statusESPEnabled = state
    for _, v in pairs(statusInstances) do if v then pcall(function() v:Destroy() end) end end
    for _, v in pairs(statusConnections) do if v then pcall(function() v:Disconnect() end) end end
    statusInstances = {}
    statusConnections = {}
    if not state then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if plr.Character then createStatusESP(plr) end
            table.insert(statusConnections, plr.CharacterAdded:Connect(function()
                if statusESPEnabled then task.wait(0.5); createStatusESP(plr) end
            end))
        end
    end
end

-- ==========================================================
-- PLAYER HIGHLIGHT
-- ==========================================================
local function createHighlight(char)
    if char and not char:FindFirstChild("ESPHighlight") then
        local h = Instance.new("Highlight")
        h.Name = "ESPHighlight"
        h.Adornee = char
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = char
    end
end

local function updateHighlight(char)
    local h = char and char:FindFirstChild("ESPHighlight")
    if h then
        local plr = Players:GetPlayerFromCharacter(char)
        local color = Visual.highlightSettings.Color

        if Visual.highlightSettings.UseTeamColor and plr then
            color = getESPColor(plr)
        end

        h.FillTransparency = Visual.highlightSettings.UseFill and 0.5 or 1
        h.OutlineTransparency = Visual.highlightSettings.UseOutline and 0 or 1
        h.FillColor = color
        h.OutlineColor = color
    end
end

local function applyHighlight(player)
    if player.Character then
        createHighlight(player.Character)
        updateHighlight(player.Character)
    end
    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        createHighlight(char)
        updateHighlight(char)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then applyHighlight(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then applyHighlight(p) end end)

function Visual.UpdatePlayerHighlights()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then updateHighlight(p.Character) end
    end
end

local lastHighlightSnapshot = ""
RunService.RenderStepped:Connect(function()
    local s = Visual.highlightSettings
    local snapshot = tostring(s.UseOutline) .. tostring(s.UseFill) .. tostring(s.UseTeamColor) .. tostring(s.Color)
    if snapshot ~= lastHighlightSnapshot then
        lastHighlightSnapshot = snapshot
        Visual.UpdatePlayerHighlights()
    end
end)

-- ==========================================================
-- SKELETON HELPERS (dùng chung Player + NPC)
-- ==========================================================
local function getSkeletonBones(model)
    local head = model:FindFirstChild("Head")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    local upperTorso = model:FindFirstChild("UpperTorso")
    local lowerTorso = model:FindFirstChild("LowerTorso")
    local leftUpperArm = model:FindFirstChild("LeftUpperArm")
    local rightUpperArm = model:FindFirstChild("RightUpperArm")
    local leftLowerArm = model:FindFirstChild("LeftLowerArm")
    local rightLowerArm = model:FindFirstChild("RightLowerArm")
    local leftUpperLeg = model:FindFirstChild("LeftUpperLeg")
    local rightUpperLeg = model:FindFirstChild("RightUpperLeg")
    local leftLowerLeg = model:FindFirstChild("LeftLowerLeg")
    local rightLowerLeg = model:FindFirstChild("RightLowerLeg")

    if not hrp then
        local torso = model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
        if torso then
            hrp = torso
            upperTorso = torso
        end
    end

    if not upperTorso and not hrp then return nil end

    return {
        head = head and head.Position or (hrp and hrp.Position + Vector3.new(0, 2, 0)),
        neck = (upperTorso or hrp).Position + Vector3.new(0, 0.5, 0),
        torso = (upperTorso or hrp).Position,
        hip = (lowerTorso or hrp).Position - Vector3.new(0, 1, 0),
        leftUpperArm = leftUpperArm and leftUpperArm.Position or nil,
        rightUpperArm = rightUpperArm and rightUpperArm.Position or nil,
        leftLowerArm = leftLowerArm and leftLowerArm.Position or nil,
        rightLowerArm = rightLowerArm and rightLowerArm.Position or nil,
        leftUpperLeg = leftUpperLeg and leftUpperLeg.Position or nil,
        rightUpperLeg = rightUpperLeg and rightUpperLeg.Position or nil,
        leftLowerLeg = leftLowerLeg and leftLowerLeg.Position or nil,
        rightLowerLeg = rightLowerLeg and rightLowerLeg.Position or nil,
    }
end

local function clearSkeletonTable(tbl)
    for _, lines in pairs(tbl) do
        for _, line in pairs(lines) do
            pcall(function() line:Remove() end)
        end
    end
    return {}
end

local function drawSkeletonLines(esp, bones, color)
    local function drawLine(line, from, to, visible)
        if from and to then
            local v1, on1 = Camera:WorldToViewportPoint(from)
            local v2, on2 = Camera:WorldToViewportPoint(to)
            if on1 and on2 then
                line.From = Vector2.new(v1.X, v1.Y)
                line.To = Vector2.new(v2.X, v2.Y)
                line.Color = color
                line.Visible = visible
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end

    drawLine(esp.head, bones.head, bones.neck, true)
    drawLine(esp.spine, bones.neck, bones.hip, true)
    drawLine(esp.leftArm, bones.torso, bones.leftUpperArm, true)
    drawLine(esp.rightArm, bones.torso, bones.rightUpperArm, true)
    drawLine(esp.leftForearm, bones.leftUpperArm, bones.leftLowerArm, true)
    drawLine(esp.rightForearm, bones.rightUpperArm, bones.rightLowerArm, true)
    drawLine(esp.leftLeg, bones.hip, bones.leftUpperLeg, true)
    drawLine(esp.rightLeg, bones.hip, bones.rightUpperLeg, true)
    drawLine(esp.leftShin, bones.leftUpperLeg, bones.leftLowerLeg, true)
    drawLine(esp.rightShin, bones.rightUpperLeg, bones.rightLowerLeg, true)
end

local function newSkeletonLines()
    local lines = {
        head = Drawing.new("Line"),
        spine = Drawing.new("Line"),
        leftArm = Drawing.new("Line"),
        rightArm = Drawing.new("Line"),
        leftLeg = Drawing.new("Line"),
        rightLeg = Drawing.new("Line"),
        leftForearm = Drawing.new("Line"),
        rightForearm = Drawing.new("Line"),
        leftShin = Drawing.new("Line"),
        rightShin = Drawing.new("Line"),
    }
    for _, line in pairs(lines) do
        line.Thickness = 2
        line.Visible = false
    end
    return lines
end

-- ==========================================================
-- PLAYER SKELETON ESP
-- ==========================================================
local function updatePlayerSkeleton()
    if not playerSkeletonEnabled then return end
    if not LocalPlayer.Character then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local model = plr.Character
            if not playerSkeletonESP[model] then
                playerSkeletonESP[model] = newSkeletonLines()
            end

            local bones = getSkeletonBones(model)
            if not bones then
                for _, line in pairs(playerSkeletonESP[model]) do line.Visible = false end
            else
                drawSkeletonLines(playerSkeletonESP[model], bones, getESPColor(plr))
            end
        end
    end
end

function Visual.SetPlayerSkeletonEnabled(v)
    playerSkeletonEnabled = v
    if not v then
        playerSkeletonESP = clearSkeletonTable(playerSkeletonESP)
    end
end

-- ==========================================================
-- NPC CACHE (dùng chung cho Name / Highlight / Tracer / Skeleton)
-- ==========================================================
local npcScanConn
local function rebuildNPCCache()
    local list = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(v) then
            table.insert(list, v)
        end
    end
    npcCache = list
    npcCacheDirty = false
end

local function ensureNPCScan()
    if npcScanConn then return end
    rebuildNPCCache()
    npcScanConn = Workspace.DescendantAdded:Connect(function(v)
        if v:IsA("Model") then
            task.wait(0.2)
            if v:FindFirstChild("Humanoid") and v ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(v) then
                npcCacheDirty = true
            end
        end
    end)
end

ensureNPCScan()

task.spawn(function()
    while true do
        task.wait(2)
        if npcCacheDirty then
            rebuildNPCCache()
        end
    end
end)

-- ==========================================================
-- NPC NAME ESP
-- ==========================================================
local npcNameTags = {}

local function updateNPCNames()
    for _, npc in ipairs(npcCache) do
        if not npcNameTags[npc] then
            local tag = Drawing.new("Text")
            tag.Center = true
            tag.Outline = true
            tag.Size = 14
            npcNameTags[npc] = tag
        end
        local tag = npcNameTags[npc]
        local hum = npc:FindFirstChildOfClass("Humanoid")
        local hrp = npc:FindFirstChild("HumanoidRootPart")
        if not hum or hum.Health <= 0 or not hrp then
            tag.Visible = false
        elseif Visual.npcNameSettings.EspName then
            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                tag.Visible = true
                tag.Text = npc.Name
                tag.Position = Vector2.new(vector.X, vector.Y - (2500 / vector.Z) / 2 - 20)
                tag.Color = getNPCColor(npc)
            else
                tag.Visible = false
            end
        else
            tag.Visible = false
        end
    end
end

local function hideAllNPCNames()
    for _, tag in pairs(npcNameTags) do
        pcall(function() tag.Visible = false end)
    end
end

function Visual.SetNPCNameEnabled(v)
    Visual.npcNameSettings.EspName = v
    if not v then
        hideAllNPCNames()
    end
end

-- ==========================================================
-- NPC HIGHLIGHT
-- ==========================================================
local npcHighlights = {}

local function updateNPCHighlights()
    local enabled = Visual.npcHighlightSettings.Outline or Visual.npcHighlightSettings.Fill

    for _, npc in ipairs(npcCache) do
        local hum = npc:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            local old = npcHighlights[npc]
            if old then old:Destroy(); npcHighlights[npc] = nil end
        else
            if not npcHighlights[npc] then
                local hl = Instance.new("Highlight")
                hl.Adornee = npc
                hl.Parent = npc
                npcHighlights[npc] = hl
            end
            local hl = npcHighlights[npc]
            local color = Visual.npcHighlightSettings.Color
            if Visual.npcHighlightSettings.UseTeamColor then
                color = getNPCColor(npc)
            end
            hl.Enabled = enabled
            hl.OutlineColor = color
            hl.FillColor = color
            hl.OutlineTransparency = Visual.npcHighlightSettings.Outline and 0 or 1
            hl.FillTransparency = Visual.npcHighlightSettings.Fill and 0.5 or 1
        end
    end
end

local function destroyAllNPCHighlights()
    for npc, hl in pairs(npcHighlights) do
        pcall(function() hl:Destroy() end)
        npcHighlights[npc] = nil
    end
end

function Visual.SetNPCHighlightEnabled()
    local enabled = Visual.npcHighlightSettings.Outline or Visual.npcHighlightSettings.Fill
    if not enabled then
        destroyAllNPCHighlights()
    else
        updateNPCHighlights()
    end
end

-- ==========================================================
-- NPC TRACER + BOX 2D
-- ==========================================================
local npcTracers = {}

local function updateNPCTracers()
    local enabled = Visual.npcTracerSettings.TracerBox
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, npc in ipairs(npcCache) do
        local hum = npc:FindFirstChildOfClass("Humanoid")
        local hrp = npc:FindFirstChild("HumanoidRootPart")
        if not hum or hum.Health <= 0 or not hrp then
            local obj = npcTracers[npc]
            if obj then
                obj.tracer.Visible = false
                obj.box.Visible = false
            end
        else
            if not npcTracers[npc] then
                local tracer = Drawing.new("Line")
                tracer.Thickness = 1
                local box = Drawing.new("Square")
                box.Thickness = 1
                box.Filled = false
                npcTracers[npc] = { tracer = tracer, box = box }
            end
            local obj = npcTracers[npc]
            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if enabled and onScreen then
                local color = getNPCColor(npc)
                local sizeX = 2200 / vector.Z
                local sizeY = 3200 / vector.Z

                obj.box.Visible = true
                obj.box.Size = Vector2.new(sizeX, sizeY)
                obj.box.Position = Vector2.new(vector.X - sizeX / 2, vector.Y - sizeY / 2)
                obj.box.Color = color

                obj.tracer.Visible = true
                obj.tracer.From = center
                obj.tracer.To = Vector2.new(vector.X, vector.Y)
                obj.tracer.Color = color
            else
                obj.tracer.Visible = false
                obj.box.Visible = false
            end
        end
    end
end

local function hideAllNPCTracers()
    for _, obj in pairs(npcTracers) do
        pcall(function()
            obj.tracer.Visible = false
            obj.box.Visible = false
        end)
    end
end

function Visual.SetNPCTracerEnabled(v)
    Visual.npcTracerSettings.TracerBox = v
    if not v then
        hideAllNPCTracers()
    end
end

-- ==========================================================
-- NPC SKELETON ESP
-- ==========================================================
local function updateNPCSkeleton()
    if not npcSkeletonEnabled then return end
    if not LocalPlayer.Character then return end

    for _, model in ipairs(npcCache) do
        local hum = model:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            if not npcSkeletonESP[model] then
                npcSkeletonESP[model] = newSkeletonLines()
            end
            local bones = getSkeletonBones(model)
            if bones then
                drawSkeletonLines(npcSkeletonESP[model], bones, getNPCColor(model))
            else
                for _, line in pairs(npcSkeletonESP[model]) do line.Visible = false end
            end
        end
    end
end

function Visual.SetNPCSkeletonEnabled(v)
    npcSkeletonEnabled = v
    if not v then
        npcSkeletonESP = clearSkeletonTable(npcSkeletonESP)
    end
end

-- ==========================================================
-- PLAYER TRACER + BOX + HEALTHBAR
-- ==========================================================
local function createBoxESP(player)
    if Boxes[player] then return end
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Visible = false
    Boxes[player] = box
end

local function createHealthBar(player)
    if HealthBars[player] then return end
    local bar = Drawing.new("Square")
    bar.Filled = true
    bar.Thickness = 1
    bar.Visible = false
    HealthBars[player] = bar
end

local function removeESPObjects(p)
    if Tracers[p] then Tracers[p]:Remove(); Tracers[p] = nil end
    if Boxes[p] then Boxes[p]:Remove(); Boxes[p] = nil end
    if HealthBars[p] then HealthBars[p]:Remove(); HealthBars[p] = nil end
end

local function setupPlayerESP(plr)
    if plr == LocalPlayer then return end
    createBoxESP(plr)
    createHealthBar(plr)
end

for _, plr in pairs(Players:GetPlayers()) do setupPlayerESP(plr) end
Players.PlayerAdded:Connect(setupPlayerESP)
Players.PlayerRemoving:Connect(removeESPObjects)

local function updatePlayerTracers()
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if hrp and humanoid then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local dist = (myHRP.Position - hrp.Position).Magnitude
                local color = getESPColor(player)

                if showTracer and onScreen and dist <= tracerDistance then
                    if not Tracers[player] then
                        local line = Drawing.new("Line")
                        line.Thickness = 1.5
                        Tracers[player] = line
                    end
                    local line = Tracers[player]
                    line.From = center
                    line.To = Vector2.new(pos.X, pos.Y)
                    line.Color = color
                    line.Visible = true

                    createBoxESP(player)
                    local scale = (Camera.CFrame.Position - hrp.Position).Magnitude
                    local size = math.clamp(1500 / scale, 15, 150)
                    local box = Boxes[player]
                    if box then
                        box.Size = Vector2.new(size, size * 1.4)
                        box.Position = Vector2.new(pos.X - size / 2, pos.Y - size + 5)
                        box.Color = color
                        box.Visible = true
                    end

                    createHealthBar(player)
                    local hb = HealthBars[player]
                    if hb then
                        local hp = humanoid.Health / humanoid.MaxHealth
                        local fullHeight = size * 1.4
                        local barHeight = fullHeight * hp
                        hb.Size = Vector2.new(3, barHeight)
                        hb.Position = Vector2.new(pos.X - size / 2 - 6, pos.Y - size + 5 + (fullHeight - barHeight))
                        hb.Color = Color3.fromRGB(255 - (hp * 255), hp * 255, 0)
                        hb.Visible = true
                    end
                else
                    if Tracers[player] then Tracers[player].Visible = false end
                    if Boxes[player] then Boxes[player].Visible = false end
                    if HealthBars[player] then HealthBars[player].Visible = false end
                end
            end
        end
    end
end

function Visual.SetTracerEnabled(v)
    showTracer = v
    if not v then
        for _, line in pairs(Tracers) do pcall(function() line.Visible = false end) end
        for _, box in pairs(Boxes) do pcall(function() box.Visible = false end) end
        for _, hb in pairs(HealthBars) do pcall(function() hb.Visible = false end) end
    end
end

function Visual.SetTracerDistance(v)
    tracerDistance = v
end

-- ==========================================================
-- X-RAY
-- ==========================================================
local function isPlayerCharacter(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and Players:GetPlayerFromCharacter(model) then return true end
    return false
end

local function applyXray(state)
    xrayEnabled = state
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if isPlayerCharacter(obj) then continue end
            if LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character) then continue end
            if state then
                if not savedTransparency[obj] then savedTransparency[obj] = obj.Transparency end
                obj.Transparency = xrayTransparency
            else
                if savedTransparency[obj] then obj.Transparency = savedTransparency[obj] end
            end
        end
    end
end

function Visual.SetXrayEnabled(v)
    applyXray(v)
    if not v then
        savedTransparency = {}
    end
end

function Visual.SetXrayTransparency(v)
    xrayTransparency = v
    if xrayEnabled then applyXray(true) end
end

-- ==========================================================
-- MAIN LOOP (1 RenderStepped duy nhất)
-- ==========================================================
RunService.RenderStepped:Connect(function()
    if playerSkeletonEnabled then updatePlayerSkeleton() end
    if npcSkeletonEnabled then updateNPCSkeleton() end
    if Visual.npcNameSettings.EspName then updateNPCNames() end
    if Visual.npcHighlightSettings.Outline or Visual.npcHighlightSettings.Fill then updateNPCHighlights() end
    if Visual.npcTracerSettings.TracerBox then updateNPCTracers() end
    if showTracer then updatePlayerTracers() end
end)

return Visual