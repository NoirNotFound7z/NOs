local ShaderSettings = {}

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local notifyFn = nil

function ShaderSettings.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then
        notifyFn(title, content, icon)
    end
end

local function CreateEffect(effectName, className)
    local effect = Lighting:FindFirstChild(effectName)
    if not effect then
        effect = Instance.new(className, Lighting)
        effect.Name = effectName
        if effect:IsA("BloomEffect") or effect:IsA("ColorCorrectionEffect") or
           effect:IsA("DepthOfFieldEffect") or effect:IsA("BlurEffect") or
           effect:IsA("SunRaysEffect") then
            effect.Enabled = false
        end
    end
    return effect
end

local bloom = CreateEffect("ShaderBloom", "BloomEffect")
local colorCor = CreateEffect("ShaderColorCorrection", "ColorCorrectionEffect")
local depth = CreateEffect("ShaderDepthOfField", "DepthOfFieldEffect")
local blur = CreateEffect("ShaderBlur", "BlurEffect")
local sunRays = CreateEffect("ShaderSunRays", "SunRaysEffect")

local atmosphere = Lighting:FindFirstChild("ShaderAtmosphere")
if not atmosphere then
    atmosphere = Instance.new("Atmosphere", Lighting)
    atmosphere.Name = "ShaderAtmosphere"
end

local sky = Lighting:FindFirstChild("ShaderSky")
if not sky then
    sky = Instance.new("Sky", Lighting)
    sky.Name = "ShaderSky"
end

local terrain = Workspace:FindFirstChild("Terrain")
local clouds
if terrain then
    clouds = terrain:FindFirstChild("ShaderClouds") or Instance.new("Clouds", terrain)
    clouds.Name = "ShaderClouds"
    clouds.Enabled = false
end

local flareEnabled = false
local flareImage = Instance.new("ImageLabel")
flareImage.Size = UDim2.new(0, 100, 0, 100)
flareImage.Position = UDim2.new(0.5, -50, 0.5, -50)
flareImage.BackgroundTransparency = 1
flareImage.Image = "rbxassetid://277033149"
flareImage.ImageTransparency = 0.5
flareImage.Visible = false
flareImage.Parent = Camera

RunService.RenderStepped:Connect(function()
    if flareEnabled then
        local sunPos, visible = Camera:WorldToScreenPoint(Camera.CFrame.Position + Lighting:GetSunDirection() * 1000)
        if visible then
            flareImage.Position = UDim2.new(0, sunPos.X - 50, 0, sunPos.Y - 50)
            flareImage.Visible = true
        else
            flareImage.Visible = false
        end
    else
        flareImage.Visible = false
    end
end)

function ShaderSettings.SetFlareEnabled(state)
    flareEnabled = state
end

function ShaderSettings.GetFlareEnabled()
    return flareEnabled
end

function ShaderSettings.ResetToDefault()
    bloom.Enabled = false
    colorCor.Enabled = false
    depth.Enabled = false
    blur.Enabled = false
    sunRays.Enabled = false
    if clouds then clouds.Enabled = false end

    atmosphere.Parent = nil
    sky.Parent = nil

    flareEnabled = false
    flareImage.Visible = false

    Lighting.Ambient = Color3.fromRGB(127, 127, 127)
    Lighting.Brightness = 1
    Lighting.ClockTime = 14
    Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
    Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    Lighting.ExposureCompensation = 0
    Lighting.FogEnd = 100000
    Lighting.FogStart = 100000
    Lighting.FogColor = Color3.fromRGB(255, 255, 255)
    Lighting.GeographicLatitude = 45
    Lighting.EnvironmentDiffuseScale = 1
    Lighting.EnvironmentSpecularScale = 1
    Lighting.GlobalShadows = true
    Lighting.ShadowSoftness = 0.5
end

ShaderSettings.ResetToDefault()

function ShaderSettings.ApplyPreset(name, presetData)
    if name == "None" then
        ShaderSettings.ResetToDefault()
        notify("Shader", "Đã chọn None (không có shader)", "check")
        return
    end

    flareEnabled = false
    flareImage.Visible = false

    atmosphere.Parent = Lighting
    sky.Parent = Lighting

    if presetData.lighting then
        for key, value in pairs(presetData.lighting) do
            Lighting[key] = value
        end
    end
    if presetData.bloom then
        for key, value in pairs(presetData.bloom) do
            bloom[key] = value
        end
        bloom.Enabled = true
    end
    if presetData.colorCor then
        for key, value in pairs(presetData.colorCor) do
            colorCor[key] = value
        end
        colorCor.Enabled = true
    end
    if presetData.depth then
        for key, value in pairs(presetData.depth) do
            depth[key] = value
        end
        depth.Enabled = true
    end
    if presetData.blur then
        for key, value in pairs(presetData.blur) do
            blur[key] = value
        end
        blur.Enabled = true
    end
    if presetData.sunRays then
        for key, value in pairs(presetData.sunRays) do
            sunRays[key] = value
        end
        sunRays.Enabled = true
    end
    if presetData.atmosphere then
        for key, value in pairs(presetData.atmosphere) do
            atmosphere[key] = value
        end
    end
    if presetData.sky then
        for key, value in pairs(presetData.sky) do
            sky[key] = value
        end
    end
    if clouds and presetData.clouds then
        for key, value in pairs(presetData.clouds) do
            clouds[key] = value
        end
        clouds.Enabled = true
    end

    notify("Shader", "Đã áp dụng: " .. name, "check")
end

ShaderSettings.skyboxPresets = {
    ["Mặc Định"] = {
        SkyboxBk = "rbxassetid://9544505500",
        SkyboxDn = "rbxassetid://9544547905",
        SkyboxFt = "rbxassetid://9544504852",
        SkyboxLf = "rbxassetid://9544547694",
        SkyboxRt = "rbxassetid://9544547542",
        SkyboxUp = "rbxassetid://9544547398"
    },
    ["Bình Minh"] = {
        SkyboxBk = "rbxassetid://9120338653",
        SkyboxDn = "rbxassetid://9120341254",
        SkyboxFt = "rbxassetid://9120337104",
        SkyboxLf = "rbxassetid://9120340051",
        SkyboxRt = "rbxassetid://9120338896",
        SkyboxUp = "rbxassetid://9120339494"
    },
    ["Ban Ngày"] = {
        SkyboxBk = "rbxassetid://9120338253",
        SkyboxDn = "rbxassetid://9120341254",
        SkyboxFt = "rbxassetid://9120337104",
        SkyboxLf = "rbxassetid://9120340051",
        SkyboxRt = "rbxassetid://9120338896",
        SkyboxUp = "rbxassetid://9120339494"
    },
    ["Hoàng Hôn"] = {
        SkyboxBk = "rbxassetid://9120338253",
        SkyboxDn = "rbxassetid://9120341254",
        SkyboxFt = "rbxassetid://9120337104",
        SkyboxLf = "rbxassetid://9120340051",
        SkyboxRt = "rbxassetid://9120338896",
        SkyboxUp = "rbxassetid://9120339494"
    },
    ["Đêm"] = {
        SkyboxBk = "rbxassetid://9120338653",
        SkyboxDn = "rbxassetid://9120341254",
        SkyboxFt = "rbxassetid://9120337104",
        SkyboxLf = "rbxassetid://9120340051",
        SkyboxRt = "rbxassetid://9120338896",
        SkyboxUp = "rbxassetid://9120339494"
    }
}

function ShaderSettings.ApplySkyPreset(presetName)
    local preset = ShaderSettings.skyboxPresets[presetName]
    if preset then
        for key, value in pairs(preset) do
            sky[key] = value
        end
    end
end

ShaderSettings.skyIds = {
    {id = "339406852", name = "Classic Roblox Sky"},
    {id = "113859918879279", name = "Sunset 1"},
    {id = "96736589365838", name = "Minecraft 1"},
    {id = "8735253332", name = "Minecraft 2"},
    {id = "407719830", name = "Sunset 2"},
    {id = "169210648", name = "TropicalSunset"},
    {id = "5877137658", name = "Lightning Kit"},
    {id = "4607457995", name = "Realistic Cloudy"},
    {id = "3146864089", name = "Realistic Bright"},
    {id = "10256505900", name = "Realistic Afternoon"},
    {id = "8613979186", name = "Realistic Lightning"},
    {id = "10594723714", name = "Brookhaven"},
    {id = "16573649975", name = "SkyRainbow"},
    {id = "246481636", name = "RainyCloud"},
    {id = "4604073339", name = "Snow Cloud"},
    {id = "6216752998", name = "Cartoon Cloud"},
    {id = "11549102836", name = "Crossroads"},
    {id = "8539737017", name = "Classic"},
    {id = "9355798790", name = "Grayish"},
    {id = "12425447749", name = "Orange"},
    {id = "95200634", name = "Green"},
    {id = "17279880951", name = "Purple"},
    {id = "15670851503", name = "Yellow"},
    {id = "12635340429", name = "Pinkie"},
    {id = "340909375", name = "Aurora"},
    {id = "7975080965", name = "Scary Night"},
    {id = "90988519", name = "Sparkling Night"},
    {id = "5834531764", name = "Red Night"},
    {id = "911025794", name = "Starry Night"},
}

local selectedSkyId = nil
local selectedSkyName = "Classic Roblox Sky"

function ShaderSettings.SetSkyboxById(id, name)
    if not id then return end
    selectedSkyId = id
    selectedSkyName = name or selectedSkyName

    local oldSky = Lighting:FindFirstChild("Sky")
    if oldSky then oldSky:Destroy() end

    pcall(function()
        local objects = game:GetObjects("rbxassetid://" .. id)
        if #objects > 0 then
            if objects[1]:IsA("Sky") then
                objects[1].Parent = Lighting
            else
                local skyObj = objects[1]:FindFirstChildOfClass("Sky")
                if skyObj then
                    skyObj.Parent = Lighting
                else
                    objects[1].Parent = Lighting
                end
            end
            notify("Skybox", "Đã thay đổi bầu trời thành " .. selectedSkyName, "cloud")
        else
            notify("Skybox", "Không thể tải Skybox!", "x")
        end
    end)
end

function ShaderSettings.GetSelectedSky()
    return selectedSkyId, selectedSkyName
end

function ShaderSettings.GetEffects()
    return {
        bloom = bloom,
        colorCor = colorCor,
        depth = depth,
        blur = blur,
        sunRays = sunRays,
        atmosphere = atmosphere,
        sky = sky,
        clouds = clouds,
        flareImage = flareImage,
        Lighting = Lighting,
    }
end

return ShaderSettings
