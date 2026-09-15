local NoirCape = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local notifyFn = nil

function NoirCape.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then notifyFn(title, content, icon) end
end

NoirCape.Config = {
    Scale = 1,
    PositionY = 0.6,
    Color = Color3.fromRGB(0, 0, 0),
    TextOnCape = "NOIR",
    ImageId = "",
    UseImageTexture = false,
    Enabled = false,
    ModHPBar = false
}

if _G.NoirCapeConfig then
    for k, v in pairs(_G.NoirCapeConfig) do
        NoirCape.Config[k] = v
    end
else
    _G.NoirCapeConfig = NoirCape.Config
end

function NoirCape.SaveConfig()
    for k, v in pairs(NoirCape.Config) do
        _G.NoirCapeConfig[k] = v
    end
end

function NoirCape.ParseImageId(input)
    if not input or input == "" then return "" end
    if string.match(input, "^rbxassetid://") then
        return input
    end
    if string.match(input, "^%d+$") then
        return "rbxassetid://" .. input
    end
    return input
end

-- ==========================================================
-- CAPE LOGIC
-- ==========================================================
local CapeInstance = nil
local renderConnection = nil
local currentMotor = nil

local function ResetCapeReferences()
    if currentMotor then currentMotor = nil end
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    if CapeInstance then CapeInstance = nil end
end

function NoirCape.CreateNoirCape()
    local Config = NoirCape.Config

    if not Config.Enabled then
        if CapeInstance then CapeInstance:Destroy() end
        CapeInstance = nil
        if renderConnection then renderConnection:Disconnect() end
        renderConnection = nil
        return
    end

    local Character = LocalPlayer.Character
    if not Character or not Character.Parent then return end

    local Torso = Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")
    local Root = Character:FindFirstChild("HumanoidRootPart")

    if not Torso or not Root then return end

    local oldCape = Character:FindFirstChild("NoirCape_V1")
    if oldCape then oldCape:Destroy() end

    if renderConnection then renderConnection:Disconnect() end

    local Cape = Instance.new("Part")
    Cape.Name = "NoirCape_V1"
    Cape.Parent = Character
    Cape.Size = Vector3.new(1.6 * Config.Scale, 2.6 * Config.Scale, 0.05)
    Cape.CanCollide = false
    Cape.Massless = true
    Cape.Material = Enum.Material.SmoothPlastic
    Cape.Color = Config.Color

    local Mesh = Instance.new("SpecialMesh", Cape)
    Mesh.MeshType = Enum.MeshType.Wedge
    Mesh.Scale = Vector3.new(1, 1, 0.1)

    for _, decal in pairs(Cape:GetChildren()) do
        if decal:IsA("Decal") then decal:Destroy() end
    end

    if Config.UseImageTexture and Config.ImageId and Config.ImageId ~= "" then
        local parsedId = NoirCape.ParseImageId(Config.ImageId)
        local decal = Instance.new("Decal", Cape)
        decal.Face = Enum.NormalId.Back
        decal.Texture = parsedId

        local decalFront = Instance.new("Decal", Cape)
        decalFront.Face = Enum.NormalId.Front
        decalFront.Texture = parsedId

        local decalRight = Instance.new("Decal", Cape)
        decalRight.Face = Enum.NormalId.Right
        decalRight.Texture = parsedId

        local decalLeft = Instance.new("Decal", Cape)
        decalLeft.Face = Enum.NormalId.Left
        decalLeft.Texture = parsedId

        Cape.Color = Color3.fromRGB(255, 255, 255)
    end

    local oldGui = Cape:FindFirstChildOfClass("SurfaceGui")
    if oldGui then oldGui:Destroy() end

    local Gui = Instance.new("SurfaceGui", Cape)
    Gui.Face = Enum.NormalId.Back
    Gui.CanvasSize = Vector2.new(400, 600)
    Gui.PixelsPerStud = 50
    Gui.Adornee = Cape

    local Text = Instance.new("TextLabel", Gui)
    Text.Name = "TextLabel"
    Text.Size = UDim2.new(0.9, 0, 0.5, 0)
    Text.Position = UDim2.new(0.05, 0, 0.25, 0)
    Text.BackgroundTransparency = 1
    Text.Text = Config.TextOnCape
    Text.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text.Font = Enum.Font.GothamBold
    Text.TextScaled = true
    Text.TextWrapped = true
    Text.Visible = not Config.UseImageTexture

    local Motor = Instance.new("Motor6D", Cape)
    Motor.Part0 = Torso
    Motor.Part1 = Cape
    currentMotor = Motor

    local offsetY = (Character:FindFirstChild("UpperTorso") and Config.PositionY) or (Config.PositionY + 0.5)
    local offsetZ = 0.5
    Motor.C0 = CFrame.new(0, offsetY, offsetZ)
    Motor.C1 = CFrame.new(0, 1.2 * Config.Scale, 0)

    CapeInstance = Cape

    renderConnection = RunService.RenderStepped:Connect(function()
        if not Cape or not Cape.Parent or not Character or not Character.Parent then return end
        local hum = Character:FindFirstChild("Humanoid")
        if not hum then return end

        if not Config.UseImageTexture and Cape then
            Cape.Color = Config.Color
        end

        local moveSpeed = Root.Velocity.Magnitude
        local timeTick = tick()
        local currentOffsetY = (Character:FindFirstChild("UpperTorso") and Config.PositionY) or (Config.PositionY + 0.5)

        if moveSpeed > 2 then
            local wave = math.sin(timeTick * 16) * 3
            Motor.C0 = Motor.C0:Lerp(CFrame.new(0, currentOffsetY, offsetZ) * CFrame.Angles(math.rad(-60 + wave), 0, 0), 0.15)
        else
            local idleSway = math.sin(timeTick * 2) * 5
            Motor.C0 = Motor.C0:Lerp(CFrame.new(0, currentOffsetY, offsetZ) * CFrame.Angles(math.rad(-10 + idleSway), 0, 0), 0.05)
        end
    end)
end

function NoirCape.ResetCapeReferences()
    ResetCapeReferences()
end

-- ==========================================================
-- MINECRAFT HEARTS LOGIC
-- ==========================================================
local MinecraftHearts = {
    currentHearts = {},
    heartbeatConnection = nil,
    shakeLoop = nil,
    pGui = nil,
    isActive = false
}

function MinecraftHearts:hideDefaultUI()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end

function MinecraftHearts:drawPixel(container, x, y, color)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    f.BackgroundColor3 = color
    f.Position = UDim2.new(0, x * 2, 0, y * 2)
    f.Size = UDim2.new(0, 2, 0, 2)
    f.Parent = container
    return f
end

function MinecraftHearts:createMinecraftHeart(parent, xPos)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 28, 0, 26)
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, xPos, 0, 0)
    container.Parent = parent

    local RED = Color3.fromRGB(220, 40, 40)
    local DARK_RED = Color3.fromRGB(140, 20, 20)
    local LIGHT_RED = Color3.fromRGB(255, 80, 80)
    local WHITE = Color3.fromRGB(255, 255, 255)
    local GRAY = Color3.fromRGB(90, 90, 90)
    local DARK_GRAY = Color3.fromRGB(55, 55, 55)

    local heartMatrix = {
        {0,0,0,0,1,2,1,0,0,0,0,0,0,0},
        {0,0,0,1,2,3,2,1,0,0,0,0,0,0},
        {0,0,1,2,3,4,3,2,1,0,0,0,0,0},
        {0,1,2,3,4,4,4,3,2,1,0,0,0,0},
        {1,2,3,4,4,4,4,4,3,2,1,0,0,0},
        {1,2,3,4,4,4,4,4,3,2,1,0,0,0},
        {0,1,2,3,4,4,4,3,2,1,0,0,0,0},
        {0,0,1,2,3,4,3,2,1,0,0,0,0,0},
        {0,0,0,1,2,3,2,1,0,0,0,0,0,0},
        {0,0,0,0,1,2,1,0,0,0,0,0,0,0},
        {0,0,0,0,0,1,0,0,0,0,0,0,0,0}
    }

    local redPixels = {}
    local grayPixels = {}
    local halfPixels = {}

    for y = 1, 11 do
        for x = 1, 14 do
            local val = heartMatrix[y][x]
            if val > 0 then
                local redColor = RED
                if val == 1 then redColor = WHITE
                elseif val == 2 then redColor = LIGHT_RED
                elseif val == 3 then redColor = RED
                elseif val == 4 then redColor = DARK_RED
                end

                local redPixel = self:drawPixel(container, x-1, y-1, redColor)
                table.insert(redPixels, redPixel)

                local grayColor = GRAY
                if val == 4 then grayColor = DARK_GRAY end

                local grayPixel = self:drawPixel(container, x-1, y-1, grayColor)
                grayPixel.Visible = false
                table.insert(grayPixels, grayPixel)

                if x <= 7 then
                    local halfPixel = self:drawPixel(container, x-1, y-1, redColor)
                    halfPixel.Visible = false
                    table.insert(halfPixels, halfPixel)
                end
            end
        end
    end

    return {
        container = container,
        redPixels = redPixels,
        grayPixels = grayPixels,
        halfPixels = halfPixels,
        baseX = xPos,
        baseY = 0,
        currentY = 0,
        shakeTimer = 0,
        shakeAmount = 0,
        isShaking = false
    }
end

function MinecraftHearts:createHeartsUI()
    local old = self.pGui:FindFirstChild("Minecraft_Hearts_Logic_V21")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Minecraft_Hearts_Logic_V21"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = self.pGui

    local heartFrame = Instance.new("Frame")
    heartFrame.Name = "HeartFrame"
    heartFrame.Size = UDim2.new(0, 310, 0, 35)
    heartFrame.Position = UDim2.new(0.65, 0, 0.03, 0)
    heartFrame.BackgroundTransparency = 1
    heartFrame.Parent = screenGui

    local hearts = {}
    for i = 1, 10 do
        hearts[i] = self:createMinecraftHeart(heartFrame, (i - 1) * 28)
    end

    return hearts
end

function MinecraftHearts:updateColors(hp, max)
    local healthPercent = hp / max

    for i = 1, 10 do
        local heart = self.currentHearts[i]
        if heart then
            local heartPercent = i / 10
            local isFull = healthPercent >= heartPercent
            local isHalf = healthPercent >= (heartPercent - 0.05)

            if isFull then
                for _, p in pairs(heart.redPixels) do p.Visible = true end
                for _, p in pairs(heart.grayPixels) do p.Visible = false end
                for _, p in pairs(heart.halfPixels) do p.Visible = false end
            elseif isHalf then
                for _, p in pairs(heart.redPixels) do p.Visible = false end
                for _, p in pairs(heart.grayPixels) do p.Visible = true end
                for _, p in pairs(heart.halfPixels) do p.Visible = true end
            else
                for _, p in pairs(heart.redPixels) do p.Visible = false end
                for _, p in pairs(heart.grayPixels) do p.Visible = true end
                for _, p in pairs(heart.halfPixels) do p.Visible = false end
            end
        end
    end
end

function MinecraftHearts:startHeartShake(heart, isLowHealthMode)
    if not heart or heart.isShaking then return end

    local duration = math.random(900, 1800)
    local intensity = isLowHealthMode and math.random(3, 6) or math.random(1, 3)

    heart.shakeTimer = duration
    heart.shakeAmount = intensity
    heart.currentY = 0
    heart.isShaking = true
end

function MinecraftHearts:updateShakes()
    for _, heart in pairs(self.currentHearts) do
        if heart.isShaking then
            heart.shakeTimer = heart.shakeTimer - 1

            if heart.shakeTimer <= 0 then
                heart.container.Position = UDim2.new(0, heart.baseX, 0, heart.baseY)
                heart.isShaking = false
                heart.currentY = 0
            else
                local t = tick() * 10
                local offset = math.sin(t) * (heart.shakeAmount / 1.5)
                heart.currentY = offset
                heart.container.Position = UDim2.new(0, heart.baseX, 0, heart.baseY + offset)
            end
        end
    end
end

function MinecraftHearts:randomShake()
    for _, heart in pairs(self.currentHearts) do
        if not heart.isShaking and math.random(1, 200) == 1 then
            self:startHeartShake(heart, false)
        end
    end
end

function MinecraftHearts:lowHealthShake(healthPercent)
    if healthPercent < 0.4 then
        for _, heart in pairs(self.currentHearts) do
            if not heart.isShaking and math.random(1, 50) == 1 then
                self:startHeartShake(heart, true)
            end
        end
    end
end

function MinecraftHearts:initialize()
    self:hideDefaultUI()
    self.currentHearts = self:createHeartsUI()
    if not self.currentHearts then return end

    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end

    local maxHealth = hum.MaxHealth
    self:updateColors(hum.Health, maxHealth)

    if self.heartbeatConnection then
        self.heartbeatConnection:Disconnect()
    end

    self.heartbeatConnection = hum.HealthChanged:Connect(function(newHealth)
        local max = hum.MaxHealth
        self:updateColors(newHealth, max)
    end)
end

function MinecraftHearts:startMainLoop()
    if self.shakeLoop then self.shakeLoop:Disconnect() end
    self.shakeLoop = RunService.Heartbeat:Connect(function()
        if self.currentHearts and #self.currentHearts > 0 then
            self:updateShakes()
            self:randomShake()

            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    local healthPercent = hum.Health / hum.MaxHealth
                    self:lowHealthShake(healthPercent)
                end
            end
        end
    end)
end

function MinecraftHearts:enable()
    if self.isActive then return end
    self.pGui = LocalPlayer:WaitForChild("PlayerGui")
    self:initialize()
    self:startMainLoop()
    self.isActive = true
end

function MinecraftHearts:disable()
    if not self.isActive then return end
    if self.heartbeatConnection then
        self.heartbeatConnection:Disconnect()
        self.heartbeatConnection = nil
    end
    if self.shakeLoop then
        self.shakeLoop:Disconnect()
        self.shakeLoop = nil
    end
    local old = self.pGui and self.pGui:FindFirstChild("Minecraft_Hearts_Logic_V21")
    if old then old:Destroy() end
    self.currentHearts = {}
    self.isActive = false
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
end

NoirCape.MinecraftHearts = MinecraftHearts

-- ==========================================================
-- AURA LOGIC
-- ==========================================================
local activeAuras = {}

function NoirCape.ToggleAura(auraId, state)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if state then
        if root and not activeAuras[auraId] then
            local att = Instance.new("Attachment")
            att.Name = "PinAuraAtt_" .. auraId
            att.Parent = root

            local pEmitter = Instance.new("ParticleEmitter")
            pEmitter.Name = "PinAuraEffect_" .. auraId
            pEmitter.Texture = "rbxassetid://" .. auraId
            pEmitter.Rate = 25
            pEmitter.Lifetime = NumberRange.new(1, 2)
            pEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 2.5)})
            pEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
            pEmitter.Parent = att

            activeAuras[auraId] = att
        end
    else
        if activeAuras[auraId] then
            activeAuras[auraId]:Destroy()
            activeAuras[auraId] = nil
        end
    end
end

-- ==========================================================
-- CHARACTER ADDED HANDLER
-- ==========================================================
LocalPlayer.CharacterAdded:Connect(function(character)
    ResetCapeReferences()

    task.wait(0.5)
    if NoirCape.Config.Enabled then
        NoirCape.CreateNoirCape()
    end
    if NoirCape.Config.ModHPBar then
        if MinecraftHearts.isActive then
            MinecraftHearts:disable()
            task.wait(0.3)
        end
        MinecraftHearts:enable()
    end
end)

task.spawn(function() NoirCape.CreateNoirCape() end)

if NoirCape.Config.ModHPBar then
    task.spawn(function()
        task.wait(0.5)
        MinecraftHearts:enable()
    end)
end

return NoirCape