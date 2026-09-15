local ShaderStudio = {}

local Lighting = game:GetService("Lighting")

local notifyFn = nil

function ShaderStudio.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then notifyFn(title, content, icon) end
end

-- ==========================================================
-- BACKUP LIGHTING
-- ==========================================================
ShaderStudio.OrigLighting = {}
for _, prop in ipairs({
    "Brightness", "ClockTime", "Ambient", "OutdoorAmbient", "GlobalShadows",
    "ShadowSoftness", "FogEnd", "FogStart", "FogColor", "ExposureCompensation",
    "ColorShift_Top", "ColorShift_Bottom", "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
    "GeographicLatitude"
}) do
    pcall(function() ShaderStudio.OrigLighting[prop] = Lighting[prop] end)
end

-- ==========================================================
-- HELPERS
-- ==========================================================
local function GetOrCreate(cls, name, props)
    local e = Lighting:FindFirstChild(name)
    if e and e.ClassName == cls then
        for k, v in pairs(props or {}) do pcall(function() e[k] = v end) end
        return e
    end
    local o = Instance.new(cls)
    o.Name = name
    for k, v in pairs(props or {}) do pcall(function() o[k] = v end) end
    o.Parent = Lighting
    return o
end

local function ClearShaderEffects()
    for _, n in pairs({"SPBloom", "SPBlur", "SPCC", "SPSunRays", "SPDOF", "SPAtmo"}) do
        local o = Lighting:FindFirstChild(n)
        if o then o:Destroy() end
    end
end

function ShaderStudio.ApplyPreset(name, s)
    ClearShaderEffects()
    for k, v in pairs(ShaderStudio.OrigLighting) do
        pcall(function() Lighting[k] = v end)
    end

    if s.Brightness then Lighting.Brightness = s.Brightness end
    if s.ClockTime then Lighting.ClockTime = s.ClockTime end
    if s.Exposure then Lighting.ExposureCompensation = s.Exposure end
    if s.Ambient then Lighting.Ambient = s.Ambient end
    if s.OutdoorAmbient then Lighting.OutdoorAmbient = s.OutdoorAmbient end
    if s.GlobalShadows ~= nil then Lighting.GlobalShadows = s.GlobalShadows end
    if s.ShadowSoftness then Lighting.ShadowSoftness = s.ShadowSoftness end
    if s.FogStart then Lighting.FogStart = s.FogStart end
    if s.FogEnd then Lighting.FogEnd = s.FogEnd end
    if s.FogColor then Lighting.FogColor = s.FogColor end
    if s.ColorShift_Top then Lighting.ColorShift_Top = s.ColorShift_Top end
    if s.ColorShift_Bottom then Lighting.ColorShift_Bottom = s.ColorShift_Bottom end
    if s.EnvDiffuse then Lighting.EnvironmentDiffuseScale = s.EnvDiffuse end
    if s.EnvSpecular then Lighting.EnvironmentSpecularScale = s.EnvSpecular end

    if s.Bloom then GetOrCreate("BloomEffect", "SPBloom", s.Bloom) end
    if s.SunRays then GetOrCreate("SunRaysEffect", "SPSunRays", s.SunRays) end
    if s.Blur then GetOrCreate("BlurEffect", "SPBlur", s.Blur) end
    if s.CC then GetOrCreate("ColorCorrectionEffect", "SPCC", s.CC) end
    if s.DOF then GetOrCreate("DepthOfFieldEffect", "SPDOF", s.DOF) end
    if s.Atmo then GetOrCreate("Atmosphere", "SPAtmo", s.Atmo) end

    notify("Shader", "Đã áp dụng: " .. name, "palette")
end

function ShaderStudio.ResetAll()
    ClearShaderEffects()
    for k, v in pairs(ShaderStudio.OrigLighting) do
        pcall(function() Lighting[k] = v end)
    end
    notify("Shader", "Đã reset tất cả shader!", "refresh")
end

function ShaderStudio.Fullbright()
    ClearShaderEffects()
    Lighting.Brightness = 3
    Lighting.ClockTime = 14
    Lighting.FogEnd = 1e6
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.fromRGB(200, 200, 200)
    Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    notify("Fullbright", "Đã bật Fullbright!", "sun")
end

-- ==========================================================
-- PRESETS DATA
-- ==========================================================
ShaderStudio.Presets = {
    -- NATURE & TIME
    { Section = "Nature & Time", Name = "Cinematic", Data = {
        Brightness = 1.5, ClockTime = 15, Exposure = 0.3, GlobalShadows = true, ShadowSoftness = 0.3,
        Ambient = Color3.fromRGB(40, 35, 30), OutdoorAmbient = Color3.fromRGB(120, 110, 95),
        ColorShift_Top = Color3.fromRGB(255, 240, 210), EnvDiffuse = 0.7, EnvSpecular = 0.5,
        Bloom = {Intensity = 0.4, Size = 30, Threshold = 0.9, Enabled = true},
        SunRays = {Intensity = 0.12, Spread = 0.7, Enabled = true},
        CC = {Brightness = 0.02, Contrast = 0.15, Saturation = -0.1, TintColor = Color3.fromRGB(255, 245, 230), Enabled = true},
        DOF = {FarIntensity = 0.15, FocusDistance = 30, InFocusRadius = 50, NearIntensity = 0.2, Enabled = true},
        Atmo = {Density = 0.25, Offset = 0.2, Glare = 0.15, Haze = 1.5, Color = Color3.fromRGB(210, 200, 180), Decay = Color3.fromRGB(100, 90, 70)},
    }},
    { Section = "Nature & Time", Name = "Golden Hour", Data = {
        Brightness = 2, ClockTime = 17.5, Exposure = 0.5, GlobalShadows = true, ShadowSoftness = 0.4,
        Ambient = Color3.fromRGB(60, 40, 20), OutdoorAmbient = Color3.fromRGB(180, 130, 60),
        ColorShift_Top = Color3.fromRGB(255, 200, 100), ColorShift_Bottom = Color3.fromRGB(200, 120, 50),
        Bloom = {Intensity = 0.8, Size = 40, Threshold = 0.6, Enabled = true},
        SunRays = {Intensity = 0.25, Spread = 0.9, Enabled = true},
        CC = {Brightness = 0.05, Contrast = 0.1, Saturation = 0.2, TintColor = Color3.fromRGB(255, 220, 170), Enabled = true},
        Atmo = {Density = 0.35, Offset = 0.3, Glare = 0.4, Haze = 3, Color = Color3.fromRGB(255, 200, 130), Decay = Color3.fromRGB(200, 130, 60)},
    }},
    { Section = "Nature & Time", Name = "Midnight", Data = {
        Brightness = 0.3, ClockTime = 0, Exposure = -0.3, GlobalShadows = true, ShadowSoftness = 0.8,
        Ambient = Color3.fromRGB(15, 20, 40), OutdoorAmbient = Color3.fromRGB(20, 30, 60),
        Bloom = {Intensity = 0.3, Size = 20, Threshold = 0.95, Enabled = true},
        CC = {Brightness = -0.08, Contrast = 0.2, Saturation = -0.3, TintColor = Color3.fromRGB(180, 200, 255), Enabled = true},
        Atmo = {Density = 0.4, Offset = 0.1, Glare = 0, Haze = 2, Color = Color3.fromRGB(30, 40, 80), Decay = Color3.fromRGB(15, 20, 50)},
    }},

    -- MOOD & STYLE
    { Section = "Mood & Style", Name = "Horror", Data = {
        Brightness = 0.2, ClockTime = 22, Exposure = -0.5, GlobalShadows = true, ShadowSoftness = 0.1,
        Ambient = Color3.fromRGB(8, 8, 12), FogStart = 0, FogEnd = 200, FogColor = Color3.fromRGB(10, 10, 15),
        CC = {Brightness = -0.12, Contrast = 0.35, Saturation = -0.7, TintColor = Color3.fromRGB(200, 210, 230), Enabled = true},
        Atmo = {Density = 0.5, Offset = 0, Glare = 0, Haze = 5, Color = Color3.fromRGB(15, 15, 25), Decay = Color3.fromRGB(5, 5, 10)},
    }},
    { Section = "Mood & Style", Name = "Dream", Data = {
        Brightness = 2.5, ClockTime = 12, Exposure = 0.8, GlobalShadows = false,
        Ambient = Color3.fromRGB(120, 100, 140),
        Bloom = {Intensity = 1.5, Size = 56, Threshold = 0.4, Enabled = true},
        CC = {Brightness = 0.1, Contrast = -0.1, Saturation = -0.2, TintColor = Color3.fromRGB(240, 225, 255), Enabled = true},
        Blur = {Size = 6, Enabled = true},
        Atmo = {Density = 0.2, Offset = 0.5, Glare = 0.3, Haze = 4, Color = Color3.fromRGB(200, 180, 230), Decay = Color3.fromRGB(150, 130, 180)},
    }},
    { Section = "Mood & Style", Name = "Neon", Data = {
        Brightness = 0.8, ClockTime = 21, Exposure = 0.2, GlobalShadows = true,
        Ambient = Color3.fromRGB(20, 5, 30), ColorShift_Top = Color3.fromRGB(200, 50, 255),
        Bloom = {Intensity = 1.2, Size = 35, Threshold = 0.5, Enabled = true},
        CC = {Brightness = 0.05, Contrast = 0.3, Saturation = 0.6, TintColor = Color3.fromRGB(220, 180, 255), Enabled = true},
        Atmo = {Density = 0.3, Offset = 0.15, Glare = 0.1, Haze = 2, Color = Color3.fromRGB(60, 20, 80), Decay = Color3.fromRGB(30, 10, 50)},
    }},
    { Section = "Mood & Style", Name = "Retro VHS", Data = {
        Brightness = 1.2, ClockTime = 14, Exposure = 0.1, ShadowSoftness = 0.5,
        CC = {Brightness = 0.03, Contrast = 0.25, Saturation = -0.4, TintColor = Color3.fromRGB(255, 230, 200), Enabled = true},
        Bloom = {Intensity = 0.6, Size = 20, Threshold = 0.7, Enabled = true},
        Blur = {Size = 2, Enabled = true},
    }},

    -- ENVIRONMENTS
    { Section = "Environments", Name = "Underwater", Data = {
        Brightness = 0.6, ClockTime = 12, Exposure = -0.2,
        Ambient = Color3.fromRGB(10, 30, 50), FogStart = 0, FogEnd = 300, FogColor = Color3.fromRGB(20, 60, 100),
        CC = {Brightness = -0.05, Contrast = 0.1, Saturation = -0.2, TintColor = Color3.fromRGB(150, 210, 255), Enabled = true},
        Blur = {Size = 3, Enabled = true},
        Atmo = {Density = 0.5, Offset = 0, Glare = 0, Haze = 6, Color = Color3.fromRGB(30, 70, 120), Decay = Color3.fromRGB(10, 30, 60)},
    }},
    { Section = "Environments", Name = "Sunrise", Data = {
        Brightness = 1.8, ClockTime = 6, Exposure = 0.4, GlobalShadows = true, ShadowSoftness = 0.5,
        ColorShift_Top = Color3.fromRGB(255, 180, 120),
        Bloom = {Intensity = 0.6, Size = 35, Threshold = 0.7, Enabled = true},
        SunRays = {Intensity = 0.2, Spread = 0.85, Enabled = true},
        CC = {Brightness = 0.03, Contrast = 0.08, Saturation = 0.15, TintColor = Color3.fromRGB(255, 230, 200), Enabled = true},
        Atmo = {Density = 0.3, Offset = 0.35, Glare = 0.3, Haze = 2.5, Color = Color3.fromRGB(230, 180, 140), Decay = Color3.fromRGB(180, 120, 80)},
    }},
    { Section = "Environments", Name = "Arctic", Data = {
        Brightness = 2, ClockTime = 12, Exposure = 0.3,
        Ambient = Color3.fromRGB(80, 100, 120), FogStart = 50, FogEnd = 800, FogColor = Color3.fromRGB(220, 235, 255),
        CC = {Brightness = 0.08, Contrast = 0.05, Saturation = -0.3, TintColor = Color3.fromRGB(210, 230, 255), Enabled = true},
        Bloom = {Intensity = 0.5, Size = 30, Threshold = 0.75, Enabled = true},
        Atmo = {Density = 0.35, Offset = 0.4, Glare = 0.2, Haze = 3, Color = Color3.fromRGB(200, 220, 245), Decay = Color3.fromRGB(160, 180, 210)},
    }},

    -- SPECIAL
    { Section = "Special", Name = "Noir", Data = {
        Brightness = 1, ClockTime = 14,
        CC = {Brightness = 0, Contrast = 0.4, Saturation = -1, TintColor = Color3.new(1, 1, 1), Enabled = true},
        Bloom = {Intensity = 0.2, Size = 18, Threshold = 0.9, Enabled = true},
    }},
    { Section = "Special", Name = "Inferno", Data = {
        Brightness = 1.5, ClockTime = 19, Exposure = 0.2,
        Ambient = Color3.fromRGB(50, 10, 0), ColorShift_Top = Color3.fromRGB(255, 100, 20),
        FogStart = 0, FogEnd = 400, FogColor = Color3.fromRGB(60, 15, 5),
        CC = {Brightness = 0.05, Contrast = 0.3, Saturation = 0.3, TintColor = Color3.fromRGB(255, 180, 120), Enabled = true},
        Bloom = {Intensity = 1, Size = 40, Threshold = 0.5, Enabled = true},
        SunRays = {Intensity = 0.15, Spread = 0.6, Enabled = true},
        Atmo = {Density = 0.4, Offset = 0.1, Glare = 0.2, Haze = 4, Color = Color3.fromRGB(150, 50, 10), Decay = Color3.fromRGB(80, 20, 5)},
    }},
    { Section = "Special", Name = "Enchanted", Data = {
        Brightness = 1.6, ClockTime = 16, Exposure = 0.3,
        Ambient = Color3.fromRGB(20, 50, 30), ColorShift_Top = Color3.fromRGB(150, 255, 180),
        Bloom = {Intensity = 0.7, Size = 32, Threshold = 0.65, Enabled = true},
        SunRays = {Intensity = 0.18, Spread = 0.75, Enabled = true},
        CC = {Brightness = 0.02, Contrast = 0.08, Saturation = 0.25, TintColor = Color3.fromRGB(220, 255, 230), Enabled = true},
        Atmo = {Density = 0.3, Offset = 0.2, Glare = 0.15, Haze = 2, Color = Color3.fromRGB(120, 180, 130), Decay = Color3.fromRGB(60, 100, 70)},
    }},
    { Section = "Special", Name = "Sakura", Data = {
        Brightness = 1.8, ClockTime = 10, Exposure = 0.2,
        Ambient = Color3.fromRGB(60, 40, 50), ColorShift_Top = Color3.fromRGB(255, 200, 220),
        Bloom = {Intensity = 0.8, Size = 38, Threshold = 0.6, Enabled = true},
        CC = {Brightness = 0.04, Contrast = 0.05, Saturation = 0.1, TintColor = Color3.fromRGB(255, 220, 235), Enabled = true},
        Atmo = {Density = 0.2, Offset = 0.3, Glare = 0.2, Haze = 2, Color = Color3.fromRGB(230, 190, 210), Decay = Color3.fromRGB(180, 140, 160)},
    }},
}

return ShaderStudio