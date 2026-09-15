local HideLimbs = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local notifyFn = nil

function HideLimbs.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then notifyFn(title, content, icon) end
end

HideLimbs.visibilityStates = {
    ["Head"] = false,
    ["Torso"] = false,
    ["Right Arm"] = false,
    ["Left Arm"] = false,
    ["Right Leg"] = false,
    ["Left Leg"] = false,
}

local mapping = {
    ["Head"] = { "Head" },
    ["Torso"] = { "Torso", "UpperTorso", "LowerTorso" },
    ["Right Arm"] = { "Right Arm", "RightUpperArm", "RightLowerArm", "RightHand" },
    ["Left Arm"] = { "Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand" },
    ["Right Leg"] = { "Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot" },
    ["Left Leg"] = { "Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
}

local function getCharacter()
    return LocalPlayer.Character
end

local function syncBodyVisibility()
    local char = getCharacter()
    if not char then return end

    for partName, isHidden in pairs(HideLimbs.visibilityStates) do
        local targetParts = mapping[partName]
        if targetParts then
            for _, targetPartName in ipairs(targetParts) do
                local part = char:FindFirstChild(targetPartName)
                if part and part:IsA("BasePart") then
                    local targetTrans = isHidden and 1 or 0
                    if part.Transparency ~= targetTrans then
                        part.Transparency = targetTrans
                    end
                    for _, child in pairs(part:GetChildren()) do
                        if child:IsA("Decal") then
                            child.Transparency = targetTrans
                        end
                    end
                end
            end
        end
    end
end

local function resetBodyVisibility()
    local char = getCharacter()
    if not char then return end

    for _, targetParts in pairs(mapping) do
        for _, targetPartName in ipairs(targetParts) do
            local part = char:FindFirstChild(targetPartName)
            if part and part:IsA("BasePart") then
                part.Transparency = 0
                for _, child in pairs(part:GetChildren()) do
                    if child:IsA("Decal") then
                        child.Transparency = 0
                    end
                end
            end
        end
    end
end

function HideLimbs.SetVisibility(partName, state)
    HideLimbs.visibilityStates[partName] = state
    syncBodyVisibility()
end

function HideLimbs.GetVisibility(partName)
    return HideLimbs.visibilityStates[partName]
end

function HideLimbs.ResetAll()
    for k in pairs(HideLimbs.visibilityStates) do
        HideLimbs.visibilityStates[k] = false
    end
    resetBodyVisibility()
    notify("Hide Limbs", "Đã hiện lại tất cả bộ phận!", "eye-off")
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    syncBodyVisibility()
end)

return HideLimbs