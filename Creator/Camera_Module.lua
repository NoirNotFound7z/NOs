local CameraStudio = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local notifyFn = nil

function CameraStudio.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then notifyFn(title, content, icon) end
end

CameraStudio.State = {
    CamSlots = {},
    CamSpeed = 2,
    CamFOV = 70,
    FreecamOn = false,
    FreecamSpeed = 1,
    OrbitOn = false,
    OrbitSpeed = 1,
    OrbitDist = 20,
    OrbitHeight = 5,
    OrbitAngle = 0,
}

local function GetRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function tweenCamera(cf, fov)
    local info = TweenInfo.new(CameraStudio.State.CamSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    local props = { CFrame = cf }
    if fov then props.FieldOfView = fov end
    TweenService:Create(Camera, info, props):Play()
end

-- ==========================================================
-- FREECAM
-- ==========================================================
function CameraStudio.SetFreecam(state)
    CameraStudio.State.FreecamOn = state
    if state then
        Camera.CameraType = Enum.CameraType.Scriptable
        notify("Freecam", "Đã bật Freecam! WASD QE để di chuyển", "camera")
    else
        Camera.CameraType = Enum.CameraType.Custom
        notify("Freecam", "Đã tắt Freecam!", "camera")
    end
end

function CameraStudio.SetFreecamSpeed(v)
    CameraStudio.State.FreecamSpeed = v
end

function CameraStudio.SetFOV(v)
    CameraStudio.State.CamFOV = v
    Camera.FieldOfView = v
end

-- ==========================================================
-- CAMERA SLOTS
-- ==========================================================
function CameraStudio.SaveSlot(i)
    CameraStudio.State.CamSlots[i] = { cf = Camera.CFrame, fov = Camera.FieldOfView }
    notify("Camera", "Đã save slot " .. i .. "!", "check")
end

function CameraStudio.LoadSlot(i)
    local slot = CameraStudio.State.CamSlots[i]
    if slot then
        Camera.CameraType = Enum.CameraType.Scriptable
        CameraStudio.State.FreecamOn = true
        tweenCamera(slot.cf, slot.fov)
        notify("Camera", "Đã load slot " .. i .. "!", "camera")
    else
        notify("Camera", "Slot " .. i .. " trống!", "x")
    end
end

function CameraStudio.SetTransitionSpeed(v)
    CameraStudio.State.CamSpeed = v
end

-- ==========================================================
-- ORBIT
-- ==========================================================
function CameraStudio.SetOrbit(state)
    CameraStudio.State.OrbitOn = state
    if state then
        Camera.CameraType = Enum.CameraType.Scriptable
        notify("Orbit", "Đã bật Orbit!", "rotate")
    else
        Camera.CameraType = Enum.CameraType.Custom
        notify("Orbit", "Đã tắt Orbit!", "rotate")
    end
end

function CameraStudio.SetOrbitSpeed(v) CameraStudio.State.OrbitSpeed = v end
function CameraStudio.SetOrbitDistance(v) CameraStudio.State.OrbitDist = v end
function CameraStudio.SetOrbitHeight(v) CameraStudio.State.OrbitHeight = v end

-- ==========================================================
-- QUICK ANGLES
-- ==========================================================
function CameraStudio.QuickAngle(angleName)
    local root = GetRoot()
    if not root then return end

    Camera.CameraType = Enum.CameraType.Scriptable
    CameraStudio.State.FreecamOn = true

    if angleName == "front" then
        local target = root.CFrame * CFrame.new(0, 1.5, 8)
        tweenCamera(CFrame.lookAt(target.Position, root.Position + Vector3.new(0, 1.5, 0)))
    elseif angleName == "side" then
        local target = root.CFrame * CFrame.new(10, 1, 0)
        tweenCamera(CFrame.lookAt(target.Position, root.Position + Vector3.new(0, 1, 0)))
    elseif angleName == "bird" then
        local target = root.Position + Vector3.new(0, 30, 5)
        tweenCamera(CFrame.lookAt(target, root.Position))
    elseif angleName == "closeup" then
        local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
        if not head then return end
        local target = head.CFrame * CFrame.new(0, 0, 3)
        tweenCamera(CFrame.lookAt(target.Position, head.Position), 40)
    elseif angleName == "shoulder" then
        local target = root.CFrame * CFrame.new(2, 2, 3)
        tweenCamera(CFrame.lookAt(target.Position, (root.CFrame * CFrame.new(0, 1, -20)).Position))
    end

    notify("Camera", angleName, "camera")
end

function CameraStudio.Reset()
    CameraStudio.State.FreecamOn = false
    CameraStudio.State.OrbitOn = false
    Camera.CameraType = Enum.CameraType.Custom
    Camera.FieldOfView = 70
    CameraStudio.State.CamFOV = 70
    notify("Camera", "Đã reset camera!", "refresh")
end

-- ==========================================================
-- ORBIT LOOP
-- ==========================================================
RunService.RenderStepped:Connect(function(dt)
    if CameraStudio.State.OrbitOn then
        local root = GetRoot()
        if root then
            local S = CameraStudio.State
            S.OrbitAngle = S.OrbitAngle + S.OrbitSpeed * dt
            local x = math.cos(S.OrbitAngle) * S.OrbitDist
            local z = math.sin(S.OrbitAngle) * S.OrbitDist
            local center = root.Position + Vector3.new(0, S.OrbitHeight, 0)
            local camPos = center + Vector3.new(x, 0, z)
            Camera.CFrame = CFrame.lookAt(camPos, center)
        end
    end
end)

return CameraStudio