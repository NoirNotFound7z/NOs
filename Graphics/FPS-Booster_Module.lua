local Graphics = {}

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Terrain = Workspace:FindFirstChildOfClass("Terrain")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

-- ==========================================================
-- STATE
-- ==========================================================
Graphics.memorySub = {Memory = true, Send = false, Receive = false}
Graphics.statsEnabled = {FPS = false, Ping = false, Memory = false}

local statsGui = nil
local statsContainer = nil
local statsRows = {}
local statsOrder = 0

local renderState = false
local renderDistance = 1000
local renderConnection = nil
local renderParts = {}

local deltaLightingSaved = {}
local deltaPostEffects = {}
local deltaMaterials = {}
local deltaTextures = {}
local deltaParticles = {}

local fpsOptimizerSaved = {
    Textures = {},
    VisualEffects = {},
    Parts = {},
    Particles = {},
    Sky = {},
}

local extremeFullbrightSaved = {}
local extremeParticles = {}
local extremeTextures = {}
local extremePostEffects = {}
local extremeShadows = {}
local extremeTerrainSaved = {}
local extremeAvatarSaved = {}

local fullbrightValue = 5
local fullbrightState = false
local savedLighting = {}

local fogState = false
local removedEffects = {}
local fogRestoreData = {}

local decoState = false
local removedDecos = {}

local fpsUnlocked = false
local boostState = false
local boostEffects = {}
local boostConnection = nil

local ultraState = false
local ultraEffects = {}
local ultraBoostConnection = nil

-- ==========================================================
-- COLOR HELPERS
-- ==========================================================
local STAT_COLORS = {
    FPS = Color3.fromRGB(100, 200, 255),
    Ping = Color3.fromRGB(255, 180, 100),
    Memory = Color3.fromRGB(180, 160, 255),
}

local STAT_ICONS = {
    FPS = "rbxassetid://10734950309",
    Ping = "rbxassetid://10734897102",
    Memory = "rbxassetid://10734896881",
}

local STAT_LABELS = {
    FPS = "FPS",
    Ping = "Ping",
    Memory = "Mem",
}

local function getFPSColor(fps)
    if fps >= 60 then return Color3.fromRGB(0, 255, 150)
    elseif fps >= 30 then return Color3.fromRGB(255, 200, 50)
    else return Color3.fromRGB(255, 80, 80) end
end

local function getPingColor(ping)
    if ping <= 50 then return Color3.fromRGB(0, 255, 150)
    elseif ping <= 100 then return Color3.fromRGB(255, 200, 50)
    elseif ping <= 200 then return Color3.fromRGB(255, 140, 50)
    else return Color3.fromRGB(255, 80, 80) end
end

local function getMemColor(mem)
    if mem <= 1000 then return Color3.fromRGB(0, 255, 150)
    elseif mem <= 2000 then return Color3.fromRGB(255, 200, 50)
    else return Color3.fromRGB(255, 80, 80) end
end

local function getNetColor(kbps)
    if kbps <= 50 then return Color3.fromRGB(0, 255, 150)
    elseif kbps <= 200 then return Color3.fromRGB(255, 200, 50)
    else return Color3.fromRGB(255, 80, 80) end
end

-- ==========================================================
-- PERFORMANCE STATS GUI
-- ==========================================================
local function createStatsGui()
    if statsGui then return end
    
    statsGui = Instance.new("ScreenGui")
    statsGui.Name = "NoirPerfStats"
    statsGui.ResetOnSpawn = false
    statsGui.IgnoreGuiInset = true
    statsGui.DisplayOrder = 999999999
    statsGui.Parent = CoreGui
    
    statsContainer = Instance.new("Frame")
    statsContainer.Name = "Container"
    statsContainer.AnchorPoint = Vector2.new(1, 0)
    statsContainer.Position = UDim2.new(1, -10, 0, 10)
    statsContainer.Size = UDim2.new(0, 160, 0, 0)
    statsContainer.AutomaticSize = Enum.AutomaticSize.Y
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = statsGui
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = statsContainer
end

local function createStatRow(statName)
    local color = STAT_COLORS[statName]
    local icon = STAT_ICONS[statName]
    local label = STAT_LABELS[statName]
    
    local row = Instance.new("Frame")
    row.Name = statName
    row.Size = UDim2.new(1, 0, 0, 24)
    row.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    row.BackgroundTransparency = 0.15
    row.BorderSizePixel = 0
    row.LayoutOrder = statsOrder
    row.Parent = statsContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = row
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = row
    
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 14, 0, 14)
    iconLabel.Position = UDim2.new(0, 6, 0.5, 0)
    iconLabel.AnchorPoint = Vector2.new(0, 0.5)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Image = icon
    iconLabel.ImageColor3 = color
    iconLabel.Parent = row
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "StatName"
    nameLabel.Size = UDim2.new(0, 32, 1, 0)
    nameLabel.Position = UDim2.new(0, 24, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = label
    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "StatValue"
    valueLabel.Size = UDim2.new(1, -60, 1, 0)
    valueLabel.Position = UDim2.new(0, 58, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = "-"
    valueLabel.TextColor3 = color
    valueLabel.TextSize = 11
    valueLabel.Font = Enum.Font.Code
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.RichText = true
    valueLabel.Parent = row
    
    statsRows[statName] = {
        row = row,
        valueLabel = valueLabel,
        stroke = stroke,
    }
end

local function removeStatRow(statName)
    if statsRows[statName] then
        statsRows[statName].row:Destroy()
        statsRows[statName] = nil
    end
end

local function refreshStatsLayout()
    local count = 0
    for _ in pairs(statsRows) do count = count + 1 end
    if count == 0 and statsGui then
        statsGui:Destroy()
        statsGui = nil
        statsContainer = nil
    end
end

function Graphics.SetStatEnabled(statName, enabled)
    if enabled == Graphics.statsEnabled[statName] then return end
    Graphics.statsEnabled[statName] = enabled
    
    if enabled then
        createStatsGui()
        if statsContainer then
            statsOrder = statsOrder + 1
            createStatRow(statName)
        end
    else
        removeStatRow(statName)
        refreshStatsLayout()
    end
end

-- Update loop
spawn(function()
    local frameTimes = {}
    local frameIndex = 1
    local sampleSize = 30
    
    local lastRecvKB = 0
    local lastSentKB = 0
    local lastNetTime = tick()
    local recvRate = 0
    local sentRate = 0
    
    pcall(function()
        local recvStat = Stats.Network.ServerStatsItem["Data Received"]
        if recvStat then lastRecvKB = recvStat:GetValue() end
        local sentStat = Stats.Network.ServerStatsItem["Data Sent"]
        if sentStat then lastSentKB = sentStat:GetValue() end
    end)
    lastNetTime = tick()
    
    while true do
        RunService.RenderStepped:Wait()
        
        local dt = RunService.RenderStepped:Wait() or 0.016
        frameTimes[frameIndex] = dt
        frameIndex = frameIndex + 1
        if frameIndex > sampleSize then frameIndex = 1 end
        
        local sum = 0
        local count = 0
        for _, t in pairs(frameTimes) do
            sum = sum + t
            count = count + 1
        end
        local avgDt = count > 0 and (sum / count) or 0.016
        local fps = math.floor(1 / avgDt)
        
        local pingStat = Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
        local ping = pingStat and math.floor(pingStat:GetValue()) or 0
        
        local mem = math.floor(Stats:GetTotalMemoryUsageMb())
        
        local now = tick()
        if now - lastNetTime >= 1 then
            pcall(function()
                local recvStat = Stats.Network.ServerStatsItem["Data Received"]
                if recvStat then
                    local currentRecv = recvStat:GetValue()
                    recvRate = (currentRecv - lastRecvKB) / (now - lastNetTime)
                    lastRecvKB = currentRecv
                end
                local sentStat = Stats.Network.ServerStatsItem["Data Sent"]
                if sentStat then
                    local currentSent = sentStat:GetValue()
                    sentRate = (currentSent - lastSentKB) / (now - lastNetTime)
                    lastSentKB = currentSent
                end
            end)
            lastNetTime = now
        end
        
        if statsRows.FPS then
            local fClr = getFPSColor(fps)
            statsRows.FPS.valueLabel.Text = fps .. " FPS"
            statsRows.FPS.valueLabel.TextColor3 = fClr
            statsRows.FPS.stroke.Color = fClr
        end
        
        if statsRows.Ping then
            local pClr = getPingColor(ping)
            statsRows.Ping.valueLabel.Text = ping .. " ms"
            statsRows.Ping.valueLabel.TextColor3 = pClr
            statsRows.Ping.stroke.Color = pClr
        end
        
        if statsRows.Memory then
            local parts = {}
            
            if Graphics.memorySub.Memory then
                local mClr = getMemColor(mem)
                local r, g, b = math.floor(mClr.R * 255), math.floor(mClr.G * 255), math.floor(mClr.B * 255)
                table.insert(parts, string.format("<font color='rgb(%d,%d,%d)'>%dMB</font>", r, g, b, mem))
            end
            
            if Graphics.memorySub.Send then
                local sClr = getNetColor(sentRate)
                local r, g, b = math.floor(sClr.R * 255), math.floor(sClr.G * 255), math.floor(sClr.B * 255)
                table.insert(parts, string.format("↑<font color='rgb(%d,%d,%d)'>%.1f</font>", r, g, b, sentRate))
            end
            
            if Graphics.memorySub.Receive then
                local rClr = getNetColor(recvRate)
                local r, g, b = math.floor(rClr.R * 255), math.floor(rClr.G * 255), math.floor(rClr.B * 255)
                table.insert(parts, string.format("↓<font color='rgb(%d,%d,%d)'>%.1f</font>", r, g, b, recvRate))
            end
            
            statsRows.Memory.valueLabel.Text = table.concat(parts, " ")
            
            local maxSeverity = 0
            if Graphics.memorySub.Memory then
                if mem > 2000 then maxSeverity = math.max(maxSeverity, 2)
                elseif mem > 1000 then maxSeverity = math.max(maxSeverity, 1) end
            end
            if Graphics.memorySub.Send then
                if sentRate > 200 then maxSeverity = math.max(maxSeverity, 2)
                elseif sentRate > 50 then maxSeverity = math.max(maxSeverity, 1) end
            end
            if Graphics.memorySub.Receive then
                if recvRate > 200 then maxSeverity = math.max(maxSeverity, 2)
                elseif recvRate > 50 then maxSeverity = math.max(maxSeverity, 1) end
            end
            
            if maxSeverity == 2 then
                statsRows.Memory.stroke.Color = Color3.fromRGB(255, 80, 80)
            elseif maxSeverity == 1 then
                statsRows.Memory.stroke.Color = Color3.fromRGB(255, 200, 50)
            else
                statsRows.Memory.stroke.Color = Color3.fromRGB(0, 255, 150)
            end
        end
    end
end)

-- ==========================================================
-- RENDER DISTANCE
-- ==========================================================
local function applyRenderDistance(dist)
    local count = 0
    local camPos = Camera.CFrame.Position
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Transparency == 0 then
            local pos = obj.Position
            local distance = (pos - camPos).Magnitude
            
            if distance > dist then
                if not renderParts[obj] then
                    renderParts[obj] = obj.Transparency
                end
                obj.Transparency = 1
                count = count + 1
            else
                if renderParts[obj] then
                    obj.Transparency = renderParts[obj]
                    renderParts[obj] = nil
                end
            end
        end
    end
    
    return count
end

local function resetRenderDistance()
    for obj, trans in pairs(renderParts) do
        pcall(function()
            if obj and obj.Parent then
                obj.Transparency = trans
            end
        end)
    end
    renderParts = {}
end

function Graphics.SetRenderDistance(v)
    renderDistance = v
    if renderState then
        resetRenderDistance()
        local count = applyRenderDistance(v)
        return count
    end
    return 0
end

function Graphics.ToggleRenderDistance(state, notify)
    renderState = state
    if state then
        local count = applyRenderDistance(renderDistance)
        
        if renderConnection then renderConnection:Disconnect() end
        renderConnection = RunService.RenderStepped:Connect(function()
            if renderState then
                applyRenderDistance(renderDistance)
            end
        end)
        
        if notify then notify("Render Distance", "Đã bật! Ẩn " .. count .. " part", "eye") end
    else
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        resetRenderDistance()
        if notify then notify("Render Distance", "Đã tắt!", "eye") end
    end
end

-- ==========================================================
-- DELTA ENGINE
-- ==========================================================
function Graphics.DeltaQualityLevel(state, notify)
    if state then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        if notify then notify("Delta", "Đã set QualityLevel = Level01!", "zap") end
    else
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level10
        end)
        if notify then notify("Delta", "Đã restore QualityLevel!", "refresh") end
    end
end

function Graphics.DeltaLightingOptimizer(state, notify)
    if state then
        deltaLightingSaved = {
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd
        }
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        if notify then notify("Delta", "Đã tắt GlobalShadows và set FogEnd!", "zap") end
    else
        for key, value in pairs(deltaLightingSaved) do
            pcall(function()
                Lighting[key] = value
            end)
        end
        if notify then notify("Delta", "Đã khôi phục Lighting!", "refresh") end
    end
end

function Graphics.DeltaPostEffectDestroyer(state, notify)
    if state then
        local count = 0
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("PostEffect") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") then
                if not deltaPostEffects[obj] then
                    deltaPostEffects[obj] = {
                        Parent = obj.Parent,
                        Enabled = obj.Enabled
                    }
                    obj:Destroy()
                    count = count + 1
                end
            end
        end
        if notify then notify("Delta", "Đã xóa " .. count .. " PostEffect!", "zap") end
    else
        if notify then notify("Delta", "PostEffect đã bị xóa vĩnh viễn!", "x") end
    end
end

function Graphics.DeltaMaterialOptimizer(state, notify)
    if state then
        local count = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                if not deltaMaterials[obj] then
                    deltaMaterials[obj] = {
                        Material = obj.Material,
                        Reflectance = obj.Reflectance
                    }
                end
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                count = count + 1
            end
        end
        if notify then notify("Delta", "Đã chuyển " .. count .. " part thành SmoothPlastic!", "zap") end
    else
        local count = 0
        for obj, data in pairs(deltaMaterials) do
            pcall(function()
                if obj and obj.Parent then
                    obj.Material = data.Material
                    obj.Reflectance = data.Reflectance
                    count = count + 1
                end
            end)
        end
        deltaMaterials = {}
        if notify then notify("Delta", "Đã khôi phục " .. count .. " part!", "refresh") end
    end
end

function Graphics.DeltaTextureDestroyer(state, notify)
    if state then
        local count = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Texture") or obj:IsA("Decal") then
                if not deltaTextures[obj] then
                    deltaTextures[obj] = {
                        Parent = obj.Parent,
                        Texture = obj.Texture
                    }
                    obj:Destroy()
                    count = count + 1
                end
            end
        end
        if notify then notify("Delta", "Đã xóa " .. count .. " Texture/Decal!", "zap") end
    else
        if notify then notify("Delta", "Texture/Decal đã bị xóa vĩnh viễn!", "x") end
    end
end

function Graphics.DeltaParticleDestroyer(state, notify)
    if state then
        local count = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Fire") then
                if not deltaParticles[obj] then
                    deltaParticles[obj] = {
                        Parent = obj.Parent,
                        Enabled = obj.Enabled
                    }
                    obj:Destroy()
                    count = count + 1
                end
            end
        end
        if notify then notify("Delta", "Đã xóa " .. count .. " Particle!", "zap") end
    else
        if notify then notify("Delta", "Particle đã bị xóa vĩnh viễn!", "x") end
    end
end

-- ==========================================================
-- FPS OPTIMIZER
-- ==========================================================
function Graphics.OptimizeTextures(enable, notify)
    if enable then
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then
                if not fpsOptimizerSaved.Textures[v] then
                    fpsOptimizerSaved.Textures[v] = v.Texture
                end
                v.Texture = ""
            end
        end
        if notify then notify("FPS", "Đã xóa textures!", "zap") end
    else
        for v, texture in pairs(fpsOptimizerSaved.Textures) do
            pcall(function()
                if v and v.Parent then
                    v.Texture = texture
                end
            end)
        end
        fpsOptimizerSaved.Textures = {}
        if notify then notify("FPS", "Đã khôi phục textures!", "zap") end
    end
end

function Graphics.OptimizeVisualEffects(enable, notify)
    if enable then
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
                if not fpsOptimizerSaved.VisualEffects[v] then
                    fpsOptimizerSaved.VisualEffects[v] = v.Enabled
                end
                v.Enabled = false
            end
        end
        if notify then notify("FPS", "Đã tắt visual effects!", "zap") end
    else
        for v, enabled in pairs(fpsOptimizerSaved.VisualEffects) do
            pcall(function()
                if v and v.Parent then
                    v.Enabled = enabled
                end
            end)
        end
        fpsOptimizerSaved.VisualEffects = {}
        if notify then notify("FPS", "Đã khôi phục visual effects!", "zap") end
    end
end

function Graphics.OptimizeParts(enable, notify)
    if enable then
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("Part") or v:IsA("Union") or v:IsA("BasePart") then
                if not fpsOptimizerSaved.Parts[v] then
                    fpsOptimizerSaved.Parts[v] = v.Material
                end
                v.Material = Enum.Material.SmoothPlastic
            end
        end
        if notify then notify("FPS", "Đã chuyển parts thành SmoothPlastic!", "zap") end
    else
        for v, material in pairs(fpsOptimizerSaved.Parts) do
            pcall(function()
                if v and v.Parent then
                    v.Material = material
                end
            end)
        end
        fpsOptimizerSaved.Parts = {}
        if notify then notify("FPS", "Đã khôi phục parts!", "zap") end
    end
end

function Graphics.OptimizeParticles(enable, notify)
    if enable then
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Explosion") or v:IsA("Sparkles") or v:IsA("Fire") then
                if not fpsOptimizerSaved.Particles[v] then
                    fpsOptimizerSaved.Particles[v] = v.Enabled
                end
                v.Enabled = false
            end
        end
        if notify then notify("FPS", "Đã tắt particles!", "zap") end
    else
        for v, enabled in pairs(fpsOptimizerSaved.Particles) do
            pcall(function()
                if v and v.Parent then
                    v.Enabled = enabled
                end
            end)
        end
        fpsOptimizerSaved.Particles = {}
        if notify then notify("FPS", "Đã khôi phục particles!", "zap") end
    end
end

function Graphics.OptimizeSky(enable, notify)
    if enable then
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Sky") then
                if not fpsOptimizerSaved.Sky[v] then
                    fpsOptimizerSaved.Sky[v] = {
                        Parent = v.Parent,
                        Enabled = v.Enabled
                    }
                end
                v.Parent = nil
            end
        end
        if notify then notify("FPS", "Đã xóa Sky!", "zap") end
    else
        for v, data in pairs(fpsOptimizerSaved.Sky) do
            pcall(function()
                if v then
                    v.Parent = data.Parent
                    v.Enabled = data.Enabled
                end
            end)
        end
        fpsOptimizerSaved.Sky = {}
        if notify then notify("FPS", "Đã khôi phục Sky!", "zap") end
    end
end

function Graphics.OptimizeFullBright(enable, notify)
    if enable then
        Lighting.FogColor = Color3.fromRGB(255, 255, 255)
        Lighting.FogEnd = math.huge
        Lighting.FogStart = math.huge
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 5
        Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Outlines = true
        if notify then notify("FPS", "Đã bật FullBright!", "sun") end
    else
        Lighting.FogColor = Color3.fromRGB(0, 0, 0)
        Lighting.FogEnd = 1000
        Lighting.FogStart = 0
        Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        Lighting.Brightness = 1
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
        Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
        Lighting.Outlines = false
        if notify then notify("FPS", "Đã tắt FullBright!", "sun") end
    end
end

-- ==========================================================
-- EXTREME FPS BOOSTER
-- ==========================================================
function Graphics.ExtremeFullbrightLock(state, notify)
    if state then
        extremeFullbrightSaved = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            GlobalShadows = Lighting.GlobalShadows,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient
        }
        
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1e9
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        
        if notify then notify("Extreme", "Đã bật Fullbright Lock!", "sun") end
    else
        for key, value in pairs(extremeFullbrightSaved) do
            pcall(function()
                Lighting[key] = value
            end)
        end
        if notify then notify("Extreme", "Đã tắt Fullbright Lock!", "moon") end
    end
end

function Graphics.ExtremeParticleTrailDisabler(state, notify)
    if state then
        local count = 0
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then
                if not extremeParticles[v] then
                    extremeParticles[v] = v.Enabled
                end
                v.Enabled = false
                count = count + 1
            end
        end
        if notify then notify("Extreme", "Đã tắt " .. count .. " Particle/Trail!", "zap") end
    else
        local count = 0
        for v, enabled in pairs(extremeParticles) do
            pcall(function()
                if v and v.Parent then
                    v.Enabled = enabled
                    count = count + 1
                end
            end)
        end
        extremeParticles = {}
        if notify then notify("Extreme", "Đã khôi phục " .. count .. " Particle/Trail!", "refresh") end
    end
end

function Graphics.ExtremeDecalTextureTransparency(state, notify)
    if state then
        local count = 0
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then
                if not extremeTextures[v] then
                    extremeTextures[v] = v.Transparency
                end
                v.Transparency = 1
                count = count + 1
            end
        end
        if notify then notify("Extreme", "Đã set Transparency=1 cho " .. count .. " Decal/Texture!", "zap") end
    else
        local count = 0
        for v, transparency in pairs(extremeTextures) do
            pcall(function()
                if v and v.Parent then
                    v.Transparency = transparency
                    count = count + 1
                end
            end)
        end
        extremeTextures = {}
        if notify then notify("Extreme", "Đã khôi phục " .. count .. " Decal/Texture!", "refresh") end
    end
end

function Graphics.ExtremePostEffectDisabler(state, notify)
    if state then
        local count = 0
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") then
                if not extremePostEffects[v] then
                    extremePostEffects[v] = v.Enabled
                end
                v.Enabled = false
                count = count + 1
            end
        end
        if notify then notify("Extreme", "Đã tắt " .. count .. " PostEffect!", "zap") end
    else
        local count = 0
        for v, enabled in pairs(extremePostEffects) do
            pcall(function()
                if v and v.Parent then
                    v.Enabled = enabled
                    count = count + 1
                end
            end)
        end
        extremePostEffects = {}
        if notify then notify("Extreme", "Đã khôi phục " .. count .. " PostEffect!", "refresh") end
    end
end

function Graphics.ExtremeCastShadowDisabler(state, notify)
    if state then
        local count = 0
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                if not extremeShadows[v] then
                    extremeShadows[v] = v.CastShadow
                end
                v.CastShadow = false
                count = count + 1
            end
        end
        if notify then notify("Extreme", "Đã tắt CastShadow cho " .. count .. " BasePart!", "zap") end
    else
        local count = 0
        for v, shadow in pairs(extremeShadows) do
            pcall(function()
                if v and v.Parent then
                    v.CastShadow = shadow
                    count = count + 1
                end
            end)
        end
        extremeShadows = {}
        if notify then notify("Extreme", "Đã khôi phục CastShadow cho " .. count .. " BasePart!", "refresh") end
    end
end

function Graphics.ExtremeTerrainOptimizer(state, notify)
    if state and Terrain then
        extremeTerrainSaved = {
            Decoration = Terrain.Decoration,
            WaterWaveSize = Terrain.WaterWaveSize,
            WaterWaveSpeed = Terrain.WaterWaveSpeed,
            WaterReflectance = Terrain.WaterReflectance,
            WaterTransparency = Terrain.WaterTransparency
        }
        
        pcall(function()
            Terrain.Decoration = false
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end)
        
        if notify then notify("Extreme", "Đã tối ưu Terrain & Water!", "zap") end
    else
        if Terrain then
            for key, value in pairs(extremeTerrainSaved) do
                pcall(function()
                    Terrain[key] = value
                end)
            end
        end
        if notify then notify("Extreme", "Đã khôi phục Terrain!", "refresh") end
    end
end

function Graphics.ExtremeQualityLevel(state, notify)
    if state then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        if notify then notify("Extreme", "Đã set QualityLevel = Level01!", "zap") end
    else
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level10
        end)
        if notify then notify("Extreme", "Đã restore QualityLevel!", "refresh") end
    end
end

-- ==========================================================
-- EXTREME AVATAR OPTIMIZER
-- ==========================================================
local extremeAvatarState = false

local function optimizeCharacter(char, owner)
    if owner == LocalPlayer then return 0 end
    
    local count = 0
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
            if not extremeAvatarSaved[v] then
                extremeAvatarSaved[v] = {Type = "Clothing", Parent = v.Parent}
            end
            v:Destroy()
            count = count + 1
        end

        if v:IsA("Accessory") then
            if not extremeAvatarSaved[v] then
                extremeAvatarSaved[v] = {Type = "Accessory", Parent = v.Parent}
            end
            v:Destroy()
            count = count + 1
        end

        if v:IsA("Decal") and v.Name == "face" then
            if not extremeAvatarSaved[v] then
                extremeAvatarSaved[v] = {Type = "Face", Transparency = v.Transparency}
            end
            v.Transparency = 1
            count = count + 1
        end
    end
    return count
end

function Graphics.ExtremeAvatarOptimizer(state, notify)
    extremeAvatarState = state
    if state then
        local totalCount = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                local count = optimizeCharacter(plr.Character, plr)
                totalCount = totalCount + count
            end
        end
        
        for _, plr in ipairs(Players:GetPlayers()) do
            plr.CharacterAdded:Connect(function(char)
                if extremeAvatarState then
                    task.wait(0.8)
                    optimizeCharacter(char, plr)
                end
            end)
        end
        
        Players.PlayerAdded:Connect(function(plr)
            plr.CharacterAdded:Connect(function(char)
                if extremeAvatarState then
                    task.wait(0.8)
                    optimizeCharacter(char, plr)
                end
            end)
        end)
        
        if notify then notify("Extreme", "Đã tối ưu avatar của " .. totalCount .. " item!", "zap") end
    else
        if notify then notify("Extreme", "Avatar đã bị xóa vĩnh viễn!", "x") end
    end
end

-- ==========================================================
-- VISUAL SETTINGS
-- ==========================================================
local function saveLighting()
    savedLighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient,
        ColorShift_Top = Lighting.ColorShift_Top,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
    }
end

local function applyFullbright(value)
    Lighting.Brightness = value
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
    Lighting.EnvironmentDiffuseScale = 1
    Lighting.EnvironmentSpecularScale = 1
end

local function restoreLighting()
    for key, value in pairs(savedLighting) do
        pcall(function()
            Lighting[key] = value
        end)
    end
end

function Graphics.ToggleFullbright(state, notify)
    fullbrightState = state
    if state then
        saveLighting()
        applyFullbright(fullbrightValue)
        if notify then notify("Fullbright", "Đã bật Fullbright!", "sun") end
    else
        restoreLighting()
        if notify then notify("Fullbright", "Đã tắt Fullbright!", "moon") end
    end
end

function Graphics.SetFullbrightBrightness(v)
    fullbrightValue = v
    if fullbrightState then
        Lighting.Brightness = v
    end
end

function Graphics.ToggleRemoveFog(state, notify)
    fogState = state
    if state then
        fogRestoreData = {
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            FogColor = Lighting.FogColor
        }
        
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.FogColor = Color3.fromRGB(0, 0, 0)
        
        local count = 0
        for _, obj in pairs(Lighting:GetDescendants()) do
            if obj:IsA("Atmosphere") or obj:IsA("BlurEffect") or obj:IsA("Rays") or obj:IsA("Sky") then
                if not removedEffects[obj] then
                    removedEffects[obj] = {
                        Parent = obj.Parent,
                        Enabled = obj.Enabled
                    }
                    obj.Parent = nil
                    count = count + 1
                end
            end
        end
        if notify then notify("Remove Fog", "Đã xóa fog và " .. count .. " effect!", "eye") end
    else
        for key, value in pairs(fogRestoreData) do
            pcall(function()
                Lighting[key] = value
            end)
        end
        
        for obj, data in pairs(removedEffects) do
            pcall(function()
                if obj then
                    obj.Parent = data.Parent
                    if data.Enabled ~= nil then
                        obj.Enabled = data.Enabled
                    end
                end
            end)
        end
        removedEffects = {}
        if notify then notify("Remove Fog", "Đã khôi phục fog!", "eye") end
    end
end

function Graphics.ToggleRemoveDecorations(state, notify)
    decoState = state
    if state then
        local count = 0
        
        for _, terrain in pairs(workspace:GetDescendants()) do
            if terrain:IsA("Terrain") then
                pcall(function()
                    terrain:ClearAllDecorations()
                    count = count + 1
                end)
            end
        end
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Material == Enum.Material.Grass then
                if not removedDecos[obj] then
                    removedDecos[obj] = obj.Material
                    obj.Material = Enum.Material.SmoothPlastic
                    count = count + 1
                end
            elseif obj:IsA("Model") and obj:FindFirstChild("Handle") and (obj.Name:match("Tree") or obj.Name:match("Bush") or obj.Name:match("Plant")) then
                if not removedDecos[obj] then
                    removedDecos[obj] = {Parent = obj.Parent}
                    obj.Parent = nil
                    count = count + 1
                end
            end
        end
        
        if notify then notify("Remove Decorations", "Đã xóa " .. count .. " đối tượng!", "trash") end
    else
        local count = 0
        for obj, data in pairs(removedDecos) do
            pcall(function()
                if obj:IsA("BasePart") then
                    obj.Material = data
                    count = count + 1
                elseif obj:IsA("Model") then
                    obj.Parent = data.Parent
                    count = count + 1
                end
            end)
        end
        removedDecos = {}
        if notify then notify("Remove Decorations", "Đã khôi phục " .. count .. " đối tượng!", "refresh") end
    end
end

-- ==========================================================
-- FPS BOOST
-- ==========================================================
function Graphics.UnlockFPS(state, notify)
    fpsUnlocked = state
    if state then
        local success = pcall(function()
            RunService:SetThrottleFpsEnabled(false)
            RunService:SetMinimumFrameRate(0)
            if setfpscap then setfpscap(0) end
        end)
        if success then
            if notify then notify("FPS", "Đã mở khóa FPS!", "zap") end
        else
            if notify then notify("FPS Unlock", "Executor không hỗ trợ!", "x") end
        end
    else
        pcall(function()
            RunService:SetThrottleFpsEnabled(true)
            RunService:SetMinimumFrameRate(60)
            if setfpscap then setfpscap(60) end
        end)
        if notify then notify("FPS", "Đã khóa FPS về 60!", "lock") end
    end
end

local function isBoostable(obj)
    return obj:IsA("ParticleEmitter") or 
           obj:IsA("Trail") or 
           obj:IsA("Smoke") or 
           obj:IsA("Fire") or 
           obj:IsA("Sparkles") or 
           obj:IsA("BloomEffect") or 
           obj:IsA("SunRaysEffect") or 
           obj:IsA("DepthOfFieldEffect") or 
           obj:IsA("ColorCorrectionEffect") or 
           obj:IsA("BlurEffect") or
           obj:IsA("Beam") or
           obj:IsA("PointLight") or
           obj:IsA("SpotLight") or
           obj:IsA("SurfaceLight")
end

local function applyBoost(mode)
    local count = 0
    Lighting.GlobalShadows = false
    
    for _, obj in pairs(game:GetDescendants()) do
        if isBoostable(obj) and not boostEffects[obj] then
            boostEffects[obj] = {
                Type = "Enabled",
                Value = obj.Enabled,
                Parent = obj.Parent
            }
            
            if mode == "soft" then
                if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
                    obj.Enabled = false
                    count = count + 1
                end
            else
                obj.Enabled = false
                count = count + 1
            end
        end
    end
    
    return count
end

local function revertBoost()
    for obj, data in pairs(boostEffects) do
        pcall(function()
            if obj and obj.Parent then
                if data.Type == "Enabled" then
                    obj.Enabled = data.Value
                end
            end
        end)
    end
    boostEffects = {}
    Lighting.GlobalShadows = true
end

function Graphics.SetBoostMode(option, notify)
    if boostState then
        revertBoost()
        task.wait(0.1)
        local mode = option == "Soft (Suggest)" and "soft" or "full"
        local count = applyBoost(mode)
        if notify then notify("Boost FPS", "Đã áp dụng mode " .. option .. ", tắt " .. count .. " effect!", "zap") end
    end
end

function Graphics.ToggleBoostFPS(state, notify)
    boostState = state
    if state then
        local count = applyBoost("soft")
        
        if boostConnection then boostConnection:Disconnect() end
        boostConnection = game.DescendantAdded:Connect(function(obj)
            task.wait(0.1)
            if isBoostable(obj) and not boostEffects[obj] then
                boostEffects[obj] = {
                    Type = "Enabled",
                    Value = obj.Enabled,
                    Parent = obj.Parent
                }
                obj.Enabled = false
            end
        end)
        
        if notify then notify("Boost FPS", "Đã tắt " .. count .. " effect!", "zap") end
    else
        if boostConnection then
            boostConnection:Disconnect()
            boostConnection = nil
        end
        revertBoost()
        if notify then notify("Boost FPS", "Đã khôi phục!", "refresh") end
    end
end

local function isUltraBoostable(obj)
    return obj:IsA("ParticleEmitter") or 
           obj:IsA("Trail") or 
           obj:IsA("Smoke") or 
           obj:IsA("Fire") or 
           obj:IsA("Sparkles") or 
           obj:IsA("Beam") or
           (obj:IsA("BasePart") and obj.Material == Enum.Material.Neon) or
           obj:IsA("PostEffect") or 
           obj:IsA("Atmosphere") or
           obj:IsA("PointLight") or
           obj:IsA("SpotLight") or
           obj:IsA("SurfaceLight")
end

local function applyUltraBoost()
    local count = 0
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100
    Lighting.FogStart = 10000
    
    for _, obj in pairs(game:GetDescendants()) do
        if isUltraBoostable(obj) and not ultraEffects[obj] then
            if obj:IsA("BasePart") then
                ultraEffects[obj] = {Type = "Material", Value = obj.Material}
                obj.Material = Enum.Material.SmoothPlastic
                count = count + 1
            elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                ultraEffects[obj] = {Type = "Enabled", Value = obj.Enabled}
                obj.Enabled = false
                count = count + 1
            else
                ultraEffects[obj] = {Type = "Enabled", Value = obj.Enabled}
                obj.Enabled = false
                count = count + 1
            end
        end
    end
    return count
end

local function revertUltraBoost()
    for obj, data in pairs(ultraEffects) do
        pcall(function()
            if obj and obj.Parent then
                if data.Type == "Material" then
                    obj.Material = data.Value
                else
                    obj.Enabled = data.Value
                end
            end
        end)
    end
    ultraEffects = {}
    Lighting.GlobalShadows = true
    Lighting.FogEnd = fogRestoreData.FogEnd or Lighting.FogEnd
    Lighting.FogStart = fogRestoreData.FogStart or Lighting.FogStart
end

function Graphics.ToggleUltraBoost(state, notify)
    ultraState = state
    if state then
        local count = applyUltraBoost()
        
        if ultraBoostConnection then ultraBoostConnection:Disconnect() end
        ultraBoostConnection = game.DescendantAdded:Connect(function(obj)
            task.wait(0.1)
            if isUltraBoostable(obj) and not ultraEffects[obj] then
                if obj:IsA("BasePart") then
                    ultraEffects[obj] = {Type = "Material", Value = obj.Material}
                    obj.Material = Enum.Material.SmoothPlastic
                else
                    ultraEffects[obj] = {Type = "Enabled", Value = obj.Enabled}
                    obj.Enabled = false
                end
            end
        end)
        
        if notify then notify("Ultra Boost", "Đã tắt " .. count .. " effect!", "zap") end
    else
        if ultraBoostConnection then
            ultraBoostConnection:Disconnect()
            ultraBoostConnection = nil
        end
        revertUltraBoost()
        if notify then notify("Ultra Boost", "Đã khôi phục!", "refresh") end
    end
end

-- ==========================================================
-- CLEANUP
-- ==========================================================
function Graphics.ClearAllEffects(notify)
    local count = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or 
           obj:IsA("Trail") or 
           obj:IsA("Smoke") or 
           obj:IsA("Fire") or 
           obj:IsA("Sparkles") or
           obj:IsA("BloomEffect") or
           obj:IsA("SunRaysEffect") or
           obj:IsA("DepthOfFieldEffect") or
           obj:IsA("ColorCorrectionEffect") or
           obj:IsA("BlurEffect") or
           obj:IsA("Beam") then
            obj:Destroy()
            count = count + 1
        end
    end
    if notify then notify("Cleanup", "Đã xóa " .. count .. " effect!", "trash") end
end

function Graphics.ResetGraphicsSettings(notify)
    pcall(function()
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.fromRGB(127, 127, 127)
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.ClockTime = 14
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
        Lighting.FogColor = Color3.fromRGB(127, 127, 127)
        
        if Camera then
            Camera.FieldOfView = 70
        end
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Transparency = 0
            end
        end
        
        fullbrightState = false
        fogState = false
        decoState = false
        boostState = false
        ultraState = false
        
        if notify then notify("Reset Graphics", "Đã reset cài đặt đồ họa!", "refresh") end
    end)
end

function Graphics.ResetAllFPSSettings(notify)
    pcall(function()
        fullbrightState = false
        restoreLighting()
        
        fogState = false
        for obj, data in pairs(removedEffects) do
            pcall(function()
                if obj then
                    obj.Parent = data.Parent
                    if data.Enabled ~= nil then
                        obj.Enabled = data.Enabled
                    end
                end
            end)
        end
        removedEffects = {}
        
        decoState = false
        for obj, data in pairs(removedDecos) do
            pcall(function()
                if obj:IsA("BasePart") then
                    obj.Material = data
                elseif obj:IsA("Model") then
                    obj.Parent = data.Parent
                end
            end)
        end
        removedDecos = {}
        
        boostState = false
        if boostConnection then
            boostConnection:Disconnect()
            boostConnection = nil
        end
        revertBoost()
        
        ultraState = false
        if ultraBoostConnection then
            ultraBoostConnection:Disconnect()
            ultraBoostConnection = nil
        end
        revertUltraBoost()
        
        RunService:SetThrottleFpsEnabled(true)
        RunService:SetMinimumFrameRate(60)
        if setfpscap then setfpscap(60) end
        fpsUnlocked = false
        
        if notify then notify("Reset All", "Đã reset tất cả cài đặt FPS!", "refresh") end
    end)
end

-- ==========================================================
-- COMBO LOADERS
-- ==========================================================
local comboScripts = {
    UniverHubFPSBooster = "https://raw.githubusercontent.com/Uranus197/-Univers-Hub-Graphics-Script-/refs/heads/main/UniversHub",
    AntiLagv1 = "https://pastebin.com/raw/tZXpzBNs",
    AntiLagv2 = "https://pastefy.app/dhiPeX7H/raw",
    FPSBooster = "https://raw.githubusercontent.com/MerebennieOfficial/ExoticJn/refs/heads/main/Fpsboosterv2",
    AntiLagTSB = "https://raw.githubusercontent.com/VikiChardd/AntiLag_TSB/main/Protect_MeowTBS1999.lua.txt",
    TSBAntiLag = "https://raw.githubusercontent.com/louismich4el/ItsLouisPlayz-Scripts/refs/heads/main/TSB%20Anti%20Lag%20Rewrited.lua",
    Bloxstrap = "https://raw.githubusercontent.com/qwertyui-is-back/Bloxstrap/main/Initiate.lua",
}

function Graphics.LoadComboScript(name, notify)
    local url = comboScripts[name]
    if not url then return end
    pcall(function()
        loadstring(game:HttpGet(url))()
    end)
    if notify then notify("FPS Booster", "Đã tải " .. name .. "!", "zap") end
end

return Graphics
