local Studio = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local notifyFn = nil

function Studio.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then notifyFn(title, content, icon) end
end

Studio.State = {
    GreenScreen = nil,
    GreenScreenOn = false,
    ScreenColor = Color3.fromRGB(0, 177, 64),
    ScreenSize = Vector3.new(40, 30, 1),
    ScreenDist = 15,
}

local function GetRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function applyColor(color)
    Studio.State.ScreenColor = color
    if Studio.State.GreenScreen then
        for _, p in pairs(Studio.State.GreenScreen:GetChildren()) do
            if p:IsA("BasePart") then p.Color = color end
        end
    end
end

local COLOR_NAMES = {
    { Name = "Green (Chroma Key)", Color = Color3.fromRGB(0, 177, 64), Msg = "Đã chọn màu xanh chroma!" },
    { Name = "Blue Screen", Color = Color3.fromRGB(0, 71, 187), Msg = "Đã chọn màu xanh dương!" },
    { Name = "Black Screen", Color = Color3.fromRGB(0, 0, 0), Msg = "Đã chọn màu đen!" },
    { Name = "White Screen", Color = Color3.fromRGB(255, 255, 255), Msg = "Đã chọn màu trắng!" },
}

Studio.ColorPresets = COLOR_NAMES

function Studio.SetScreenColor(index)
    local preset = COLOR_NAMES[index]
    if not preset then return end
    applyColor(preset.Color)
    notify("Screen", preset.Msg, "check")
end

function Studio.ToggleGreenScreen(state)
    Studio.State.GreenScreenOn = state
    local S = Studio.State

    if state then
        local root = GetRoot()
        if not root then
            notify("Green Screen", "Không tìm thấy nhân vật!", "x")
            return
        end

        if S.GreenScreen then S.GreenScreen:Destroy() end

        local model = Instance.new("Model")
        model.Name = "StudioGreenScreen"

        local back = Instance.new("Part")
        back.Size = S.ScreenSize
        back.CFrame = root.CFrame * CFrame.new(0, S.ScreenSize.Y/2 - 3, -S.ScreenDist)
        back.Anchored = true
        back.CanCollide = false
        back.Material = Enum.Material.SmoothPlastic
        back.Color = S.ScreenColor
        back.Name = "Back"
        back.Parent = model

        local floor = Instance.new("Part")
        floor.Size = Vector3.new(S.ScreenSize.X, 1, S.ScreenSize.X * 0.6)
        floor.CFrame = root.CFrame * CFrame.new(0, -3, -S.ScreenDist + S.ScreenSize.X * 0.3 - S.ScreenSize.Z/2)
        floor.Anchored = true
        floor.CanCollide = true
        floor.Material = Enum.Material.SmoothPlastic
        floor.Color = S.ScreenColor
        floor.Name = "Floor"
        floor.Parent = model

        local left = Instance.new("Part")
        left.Size = Vector3.new(1, S.ScreenSize.Y, S.ScreenSize.X * 0.6)
        left.CFrame = root.CFrame * CFrame.new(-S.ScreenSize.X/2, S.ScreenSize.Y/2 - 3, -S.ScreenDist + S.ScreenSize.X * 0.3 - S.ScreenSize.Z/2)
        left.Anchored = true
        left.CanCollide = false
        left.Material = Enum.Material.SmoothPlastic
        left.Color = S.ScreenColor
        left.Name = "Left"
        left.Parent = model

        local right = Instance.new("Part")
        right.Size = Vector3.new(1, S.ScreenSize.Y, S.ScreenSize.X * 0.6)
        right.CFrame = root.CFrame * CFrame.new(S.ScreenSize.X/2, S.ScreenSize.Y/2 - 3, -S.ScreenDist + S.ScreenSize.X * 0.3 - S.ScreenSize.Z/2)
        right.Anchored = true
        right.CanCollide = false
        right.Material = Enum.Material.SmoothPlastic
        right.Color = S.ScreenColor
        right.Name = "Right"
        right.Parent = model

        local ceiling = Instance.new("Part")
        ceiling.Size = Vector3.new(S.ScreenSize.X, 1, S.ScreenSize.X * 0.6)
        ceiling.CFrame = root.CFrame * CFrame.new(0, S.ScreenSize.Y - 3, -S.ScreenDist + S.ScreenSize.X * 0.3 - S.ScreenSize.Z/2)
        ceiling.Anchored = true
        ceiling.CanCollide = false
        ceiling.Material = Enum.Material.SmoothPlastic
        ceiling.Color = S.ScreenColor
        ceiling.Name = "Ceiling"
        ceiling.Parent = model

        model.Parent = Workspace
        S.GreenScreen = model

        notify("Green Screen", "Đã tạo màn hình xanh!", "check")
    else
        if S.GreenScreen then
            S.GreenScreen:Destroy()
            S.GreenScreen = nil
        end
        notify("Green Screen", "Đã xóa màn hình xanh!", "trash")
    end
end

function Studio.SetWidth(v)
    Studio.State.ScreenSize = Vector3.new(v, Studio.State.ScreenSize.Y, Studio.State.ScreenSize.Z)
    if Studio.State.GreenScreen then
        for _, p in pairs(Studio.State.GreenScreen:GetChildren()) do
            if p:IsA("BasePart") and p.Name == "Back" then
                p.Size = Studio.State.ScreenSize
            end
        end
    end
end

function Studio.SetHeight(v)
    Studio.State.ScreenSize = Vector3.new(Studio.State.ScreenSize.X, v, Studio.State.ScreenSize.Z)
    if Studio.State.GreenScreen then
        for _, p in pairs(Studio.State.GreenScreen:GetChildren()) do
            if p:IsA("BasePart") and p.Name == "Back" then
                p.Size = Studio.State.ScreenSize
            end
        end
    end
end

function Studio.SetDistance(v)
    Studio.State.ScreenDist = v
    if Studio.State.GreenScreen then
        local root = GetRoot()
        if root and Studio.State.GreenScreen:FindFirstChild("Back") then
            Studio.State.GreenScreen.Back.CFrame = root.CFrame * CFrame.new(0, Studio.State.ScreenSize.Y/2 - 3, -v)
        end
    end
end

-- ==========================================================
-- STUDIO LIGHTS
-- ==========================================================
local LIGHT_DEFS = {
    Key = {
        Name = "StudioKeyLight",
        Size = Vector3.new(2, 2, 2),
        Color = Color3.fromRGB(255, 250, 235),
        Offset = CFrame.new(8, 8, -5),
        Brightness = 3,
        Range = 40,
        Notify = "Đã thêm Key Light!",
    },
    Fill = {
        Name = "StudioFillLight",
        Size = Vector3.new(2, 2, 2),
        Color = Color3.fromRGB(200, 220, 255),
        Offset = CFrame.new(-8, 6, -3),
        Brightness = 1.5,
        Range = 30,
        Notify = "Đã thêm Fill Light!",
    },
    Back = {
        Name = "StudioBackLight",
        Size = Vector3.new(2, 2, 2),
        Color = Color3.fromRGB(255, 200, 150),
        Offset = "Back",
        Brightness = 2,
        Range = 35,
        Notify = "Đã thêm Back Light!",
    },
}

local function createLight(def)
    local root = GetRoot()
    if not root then return end

    local light = Instance.new("Part")
    light.Name = def.Name
    light.Size = def.Size
    light.Shape = Enum.PartType.Ball
    light.Material = Enum.Material.Neon
    light.Color = def.Color
    light.Anchored = true
    light.CanCollide = false
    light.Transparency = 0.5

    if def.Offset == "Back" then
        light.CFrame = root.CFrame * CFrame.new(0, 10, -Studio.State.ScreenDist - 5)
    else
        light.CFrame = root.CFrame * def.Offset
    end

    light.Parent = Workspace

    local pl = Instance.new("PointLight")
    pl.Color = def.Color
    pl.Brightness = def.Brightness
    pl.Range = def.Range
    pl.Parent = light

    notify("Light", def.Notify, "sun")
end

function Studio.AddKeyLight() createLight(LIGHT_DEFS.Key) end
function Studio.AddFillLight() createLight(LIGHT_DEFS.Fill) end
function Studio.AddBackLight() createLight(LIGHT_DEFS.Back) end

function Studio.RemoveAllLights()
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj.Name == "StudioKeyLight" or obj.Name == "StudioFillLight" or obj.Name == "StudioBackLight" then
            obj:Destroy()
        end
    end
    notify("Lights", "Đã xóa tất cả đèn!", "trash")
end

return Studio