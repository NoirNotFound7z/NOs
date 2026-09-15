local Props = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local notifyFn = nil

function Props.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then notifyFn(title, content, icon) end
end

-- ==========================================================
-- BACKUP LIGHTING (1 lần khi load)
-- ==========================================================
local OrigLighting = {}
for _, prop in ipairs({
    "Brightness", "ClockTime", "Ambient", "OutdoorAmbient", "GlobalShadows",
    "ShadowSoftness", "FogEnd", "FogStart", "FogColor", "ExposureCompensation",
    "ColorShift_Top", "ColorShift_Bottom", "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
    "GeographicLatitude"
}) do
    pcall(function() OrigLighting[prop] = Lighting[prop] end)
end

-- ==========================================================
-- STATE
-- ==========================================================
Props.State = {
    GreenScreen = nil,
}

local function GetRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ==========================================================
-- SPAWN PROPS
-- ==========================================================
local function createProp(name, size, cframeOffset, color, material, shape, transparency, reflectance)
    local root = GetRoot()
    if not root then return end

    local part = Instance.new("Part")
    part.Name = "StudioProp_" .. name
    part.Size = size
    part.CFrame = root.CFrame * cframeOffset
    part.Anchored = true
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    if shape then part.Shape = shape end
    if transparency then part.Transparency = transparency end
    if reflectance then part.Reflectance = reflectance end
    part.Parent = Workspace

    notify("Props", "Đã spawn " .. name .. "!", "check")
end

function Props.SpawnCube()
    createProp("Cube", Vector3.new(6, 6, 6), CFrame.new(0, 3, -10), Color3.fromRGB(120, 120, 120))
end

function Props.SpawnSphere()
    createProp("Sphere", Vector3.new(6, 6, 6), CFrame.new(0, 3, -10), Color3.fromRGB(200, 200, 200), nil, Enum.PartType.Ball)
end

function Props.SpawnCylinder()
    createProp("Cylinder", Vector3.new(6, 6, 6), CFrame.new(0, 3, -10), Color3.fromRGB(100, 150, 200), nil, Enum.PartType.Cylinder)
end

function Props.SpawnPlatform()
    createProp("Platform", Vector3.new(30, 1, 30), CFrame.new(0, 0, -10), Color3.fromRGB(80, 80, 85), Enum.Material.Concrete)
end

function Props.SpawnWall()
    createProp("Wall", Vector3.new(20, 12, 1), CFrame.new(0, 6, -10), Color3.fromRGB(160, 140, 120), Enum.Material.Brick)
end

function Props.SpawnNeonCube()
    createProp("NeonCube", Vector3.new(4, 4, 4), CFrame.new(0, 2, -10), Color3.fromRGB(170, 0, 255), Enum.Material.Neon)
end

function Props.SpawnGlassPanel()
    createProp("Glass", Vector3.new(15, 10, 0.5), CFrame.new(0, 5, -8), Color3.fromRGB(200, 220, 255), Enum.Material.Glass, nil, 0.5)
end

function Props.SpawnMirrorFloor()
    createProp("Mirror", Vector3.new(50, 0.5, 50), CFrame.new(0, -3, 0), Color3.fromRGB(40, 40, 45), Enum.Material.Glass, nil, nil, 0.8)
end

-- ==========================================================
-- CLEANUP
-- ==========================================================
function Props.RemoveAllProps()
    local count = 0
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj.Name:sub(1, 11) == "StudioProp_" then
            obj:Destroy()
            count = count + 1
        end
    end
    notify("Props", "Đã xóa " .. count .. " props!", "trash")
end

function Props.RemoveGreenScreen()
    if Props.State.GreenScreen then
        Props.State.GreenScreen:Destroy()
        Props.State.GreenScreen = nil
    end
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj.Name == "StudioGreenScreen" then
            obj:Destroy()
        end
    end
    notify("Cleanup", "Đã xóa Green Screen!", "trash")
end

function Props.RemoveEverythingStudio()
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj.Name:sub(1, 6) == "Studio" or obj.Name:sub(1, 11) == "StudioProp_" then
            obj:Destroy()
        end
    end
    Props.State.GreenScreen = nil
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj.Name == "StudioKeyLight" or obj.Name == "StudioFillLight" or obj.Name == "StudioBackLight" then
            obj:Destroy()
        end
    end
    notify("Cleanup", "Đã xóa tất cả Studio objects!", "trash")
end

-- ==========================================================
-- ENVIRONMENT
-- ==========================================================
function Props.RemoveSkybox()
    for _, child in pairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then
            child:Destroy()
        end
    end
    notify("Skybox", "Đã xóa Skybox!", "cloud")
end

function Props.BlankWhiteSky()
    for _, child in pairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then
            child:Destroy()
        end
    end
    Lighting.Brightness = 3
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.FogEnd = 1e6
    Lighting.GlobalShadows = false
    notify("Sky", "Đã chuyển sang White Sky!", "sun")
end

function Props.DarkStudio()
    Lighting.Brightness = 0
    Lighting.Ambient = Color3.fromRGB(5, 5, 8)
    Lighting.OutdoorAmbient = Color3.fromRGB(5, 5, 8)
    Lighting.ClockTime = 0
    Lighting.FogEnd = 200
    Lighting.FogColor = Color3.fromRGB(5, 5, 8)
    Lighting.GlobalShadows = false
    notify("Studio", "Đã chuyển sang Dark Studio!", "moon")
end

function Props.ResetLighting()
    for k, v in pairs(OrigLighting) do
        pcall(function() Lighting[k] = v end)
    end
    notify("Lighting", "Đã reset Lighting!", "refresh")
end

return Props