local SkitF3X = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local notifyFn = nil

function SkitF3X.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then notifyFn(title, content, icon) end
end

-- ==========================================================
-- STATE
-- ==========================================================
SkitF3X.Enabled = false
SkitF3X.MultiSelect = false
SkitF3X.GizmoMode = "Move"
SkitF3X.targetPart = nil
SkitF3X.selectedPartsList = {}
SkitF3X.undoStack = {}
SkitF3X.originalCFrame = nil
SkitF3X.originalSize = nil
SkitF3X.originalAxisCFrame = nil
SkitF3X.isDraggingGizmo = false
SkitF3X.savedWalkSpeed = 16

SkitF3X.OnSelectionChanged = nil
SkitF3X.OnMovingPartStateChanged = nil
SkitF3X.OnMultiSelectChanged = nil

-- ==========================================================
-- GUI PARENT
-- ==========================================================
local guiParentRef

local function ensureGuiParent()
    if guiParentRef and guiParentRef.Parent then return guiParentRef end
    guiParentRef = LocalPlayer:WaitForChild("PlayerGui")
    return guiParentRef
end

-- ==========================================================
-- GIZMO INSTANCES
-- ==========================================================
local selectionBox = Instance.new("SelectionBox")
selectionBox.Color3 = Color3.fromRGB(0, 255, 0)
selectionBox.LineThickness = 0.05
selectionBox.Adornee = nil

local handles = Instance.new("Handles")
handles.Color3 = Color3.fromRGB(255, 0, 0)
handles.Adornee = nil

local arcHandles = Instance.new("ArcHandles")
arcHandles.Color3 = Color3.fromRGB(0, 150, 255)
arcHandles.Adornee = nil

local multiSelectBoxes = {}

-- ==========================================================
-- HELPERS
-- ==========================================================
local function round4(val)
    if type(val) == "number" then
        return math.floor(val * 10000 + 0.5) / 10000
    elseif type(val) == "table" then
        local t = {}
        for k, v in pairs(val) do
            t[k] = round4(v)
        end
        return t
    end
    return val
end

local function saveState(part, oldCFrame, oldSize)
    if not part then return end
    table.insert(SkitF3X.undoStack, {Part = part, CFrame = oldCFrame, Size = oldSize})
    if #SkitF3X.undoStack > 20 then table.remove(SkitF3X.undoStack, 1) end
end

local function freezePlayer()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        SkitF3X.savedWalkSpeed = hum.WalkSpeed
        hum.WalkSpeed = 0
    end
end

local function unfreezePlayer()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = SkitF3X.savedWalkSpeed
    end
end

local function fireSelectionChanged()
    if SkitF3X.OnSelectionChanged then
        SkitF3X.OnSelectionChanged(SkitF3X.targetPart)
    end
end

local function fireMultiSelectChanged()
    if SkitF3X.OnMultiSelectChanged then
        local count = 0
        for _ in pairs(SkitF3X.selectedPartsList) do count = count + 1 end
        SkitF3X.OnMultiSelectChanged(count)
    end
end

local function fireMovingPartState()
    local hasMoving = false
    local targetPart = SkitF3X.targetPart
    if targetPart then
        local root = targetPart:FindFirstChild("IsMovingPart") and targetPart or targetPart.Parent
        if root and root:FindFirstChild("IsMovingPart") then
            hasMoving = true
            if SkitF3X.OnMovingPartStateChanged then
                SkitF3X.OnMovingPartStateChanged(true, {
                    Speed = root.IsMovingPart.ForwardSpeed.Value,
                    BackSpeed = root.IsMovingPart.BackSpeed.Value,
                    ReturnMode = root.IsMovingPart.ReturnMode.Value,
                })
            end
        end
    end
    if not hasMoving and SkitF3X.OnMovingPartStateChanged then
        SkitF3X.OnMovingPartStateChanged(false)
    end
end

-- ==========================================================
-- GIZMO STATE
-- ==========================================================
local function updateGizmoState()
    if not SkitF3X.Enabled or not SkitF3X.targetPart then
        handles.Adornee = nil
        arcHandles.Adornee = nil
        return
    end
    if SkitF3X.GizmoMode == "Move" then
        handles.Style = Enum.HandlesStyle.Movement
        handles.Adornee = SkitF3X.targetPart
        arcHandles.Adornee = nil
    elseif SkitF3X.GizmoMode == "Resize" then
        handles.Style = Enum.HandlesStyle.Resize
        handles.Adornee = SkitF3X.targetPart
        arcHandles.Adornee = nil
    elseif SkitF3X.GizmoMode == "Rotate" then
        handles.Adornee = nil
        arcHandles.Adornee = SkitF3X.targetPart
    end
end

-- ==========================================================
-- SELECTION
-- ==========================================================
function SkitF3X.SelectPart(target)
    if target and target:IsA("BasePart") then
        SkitF3X.targetPart = target
        selectionBox.Adornee = target
        updateGizmoState()
        fireSelectionChanged()
        fireMovingPartState()
    else
        SkitF3X.targetPart = nil
        selectionBox.Adornee = nil
        handles.Adornee = nil
        arcHandles.Adornee = nil
        fireSelectionChanged()
        fireMovingPartState()
    end
end

function SkitF3X.ToggleMultiSelectTarget(target)
    if not target or not target:IsA("BasePart") then return end
    if SkitF3X.selectedPartsList[target] then
        SkitF3X.selectedPartsList[target] = nil
        if multiSelectBoxes[target] then
            multiSelectBoxes[target]:Destroy()
            multiSelectBoxes[target] = nil
        end
    else
        SkitF3X.selectedPartsList[target] = true
        local box = Instance.new("SelectionBox")
        box.Color3 = Color3.fromRGB(255, 255, 0)
        box.LineThickness = 0.05
        box.Adornee = target
        box.Parent = ensureGuiParent()
        multiSelectBoxes[target] = box
    end
    fireMultiSelectChanged()
end

function SkitF3X.SetMultiSelect(v)
    SkitF3X.MultiSelect = v
    if v then
        SkitF3X.SelectPart(nil)
    else
        for _, box in pairs(multiSelectBoxes) do
            box:Destroy()
        end
        table.clear(multiSelectBoxes)
        table.clear(SkitF3X.selectedPartsList)
        fireMultiSelectChanged()
    end
end

function SkitF3X.GetMultiSelect()
    return SkitF3X.MultiSelect
end

-- ==========================================================
-- ENABLE / DISABLE
-- ==========================================================
function SkitF3X.SetEnabled(v)
    SkitF3X.Enabled = v
    if v then
        local pg = ensureGuiParent()
        selectionBox.Parent = pg
        handles.Parent = pg
        arcHandles.Parent = pg
        notify("Skit F3X", "Tool enabled - click parts to select", "mouse-pointer")
    else
        selectionBox.Adornee = nil
        handles.Adornee = nil
        arcHandles.Adornee = nil
        selectionBox.Parent = nil
        handles.Parent = nil
        arcHandles.Parent = nil
        SkitF3X.SelectPart(nil)
        Camera.CameraType = Enum.CameraType.Custom
        SkitF3X.isDraggingGizmo = false
        notify("Skit F3X", "Tool disabled", "x")
    end
end

function SkitF3X.GetEnabled()
    return SkitF3X.Enabled
end

-- ==========================================================
-- GIZMO MODE
-- ==========================================================
function SkitF3X.SetGizmoMode(mode)
    SkitF3X.GizmoMode = mode
    updateGizmoState()
end

function SkitF3X.GetGizmoMode()
    return SkitF3X.GizmoMode
end

-- ==========================================================
-- COLLISION / ANCHOR
-- Không gọi fireSelectionChanged ở đây — tránh infinite loop với UI sync
-- ==========================================================
function SkitF3X.ToggleCollision(v)
    if SkitF3X.targetPart then
        SkitF3X.targetPart.CanCollide = v
    end
end

function SkitF3X.GetCollision()
    if SkitF3X.targetPart then
        return SkitF3X.targetPart.CanCollide
    end
    return true
end

function SkitF3X.ToggleAnchor(v)
    if SkitF3X.targetPart then
        SkitF3X.targetPart.Anchored = v

        for _, desc in pairs(workspace:GetDescendants()) do
            if desc:IsA("WeldConstraint") and desc.Name == "GroupWeld" then
                if desc.Part0 == SkitF3X.targetPart or desc.Part1 == SkitF3X.targetPart then
                    if desc.Part0 then desc.Part0.Anchored = v end
                    if desc.Part1 then desc.Part1.Anchored = v end
                end
            end
        end
    end
end

function SkitF3X.GetAnchor()
    if SkitF3X.targetPart then
        return SkitF3X.targetPart.Anchored
    end
    return false
end

-- ==========================================================
-- SPAWN
-- ==========================================================
function SkitF3X.SpawnPart()
    local p = Instance.new("Part")
    p.Size = Vector3.new(4, 1, 4)
    p.Anchored = true
    p.BrickColor = BrickColor.new("Medium stone grey")
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        p.CFrame = hrp.CFrame * CFrame.new(0, 0, -10)
    else
        p.CFrame = CFrame.new(0, 5, 0)
    end
    p.Parent = workspace
    if not SkitF3X.MultiSelect then
        SkitF3X.SelectPart(p)
    end
    notify("Skit F3X", "Spawned part", "box")
end

function SkitF3X.SpawnMovingPart()
    local p = Instance.new("Part")
    p.Size = Vector3.new(4, 1, 4)
    p.Anchored = true
    p.BrickColor = BrickColor.new("Bright blue")
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        p.CFrame = hrp.CFrame * CFrame.new(0, 0, -10)
    else
        p.CFrame = CFrame.new(0, 5, 0)
    end
    p.Parent = workspace

    local moveData = Instance.new("Configuration", p)
    moveData.Name = "IsMovingPart"
    local fSpeed = Instance.new("NumberValue", moveData)
    fSpeed.Name = "ForwardSpeed"
    fSpeed.Value = 2.5
    local bSpeed = Instance.new("NumberValue", moveData)
    bSpeed.Name = "BackSpeed"
    bSpeed.Value = 2.5
    local retMode = Instance.new("StringValue", moveData)
    retMode.Name = "ReturnMode"
    retMode.Value = "SNAP"

    local p1 = p:Clone()
    p1.Name = "Place1"
    p1.BrickColor = BrickColor.new("Lime green")
    p1.Transparency = 0.6
    p1.CanCollide = false
    p1.CFrame = p.CFrame
    p1:ClearAllChildren()
    p1.Parent = p

    local p2 = p:Clone()
    p2.Name = "Place2"
    p2.BrickColor = BrickColor.new("Really red")
    p2.Transparency = 0.6
    p2.CanCollide = false
    p2.CFrame = p.CFrame * CFrame.new(0, 5, -10)
    p2:ClearAllChildren()
    p2.Parent = p

    if not SkitF3X.MultiSelect then
        SkitF3X.SelectPart(p)
    end
    notify("Skit F3X", "Spawned moving part", "box")
end

function SkitF3X.TriggerMove()
    local targetPart = SkitF3X.targetPart
    local root = (targetPart and targetPart:FindFirstChild("IsMovingPart")) and targetPart or (targetPart and targetPart.Parent)
    if not root or not root:FindFirstChild("IsMovingPart") then
        notify("Skit F3X", "No moving part selected", "x")
        return
    end
    local p1 = root:FindFirstChild("Place1")
    local p2 = root:FindFirstChild("Place2")
    local md = root.IsMovingPart

    if p1 and p2 then
        root.CFrame = p1.CFrame
        local tweenInfoForward = TweenInfo.new(md.ForwardSpeed.Value, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        local t1 = TweenService:Create(root, tweenInfoForward, {CFrame = p2.CFrame})
        t1:Play()
        t1.Completed:Connect(function()
            task.wait(0.2)
            if md.ReturnMode.Value == "SNAP" then
                root.CFrame = p1.CFrame
            else
                local tweenInfoBack = TweenInfo.new(md.BackSpeed.Value, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                TweenService:Create(root, tweenInfoBack, {CFrame = p1.CFrame}):Play()
            end
        end)
    end
end

-- ==========================================================
-- GROUP
-- ==========================================================
function SkitF3X.Group()
    local list = {}
    if next(SkitF3X.selectedPartsList) then
        for p in pairs(SkitF3X.selectedPartsList) do
            table.insert(list, p)
        end
    end
    if #list < 2 then
        notify("Skit F3X", "Select 2+ parts to group", "x")
        return
    end

    local root = list[1]
    for i = 2, #list do
        local p = list[i]
        local oldWeld = p:FindFirstChild("GroupWeld")
        if oldWeld then oldWeld:Destroy() end

        local weld = Instance.new("WeldConstraint")
        weld.Name = "GroupWeld"
        weld.Part0 = root
        weld.Part1 = p
        weld.Parent = p
    end
    notify("Skit F3X", "Grouped " .. #list .. " parts", "link")
end

function SkitF3X.Ungroup()
    local list = {}
    if next(SkitF3X.selectedPartsList) then
        for p in pairs(SkitF3X.selectedPartsList) do
            table.insert(list, p)
        end
    elseif SkitF3X.targetPart then
        table.insert(list, SkitF3X.targetPart)
    end

    local count = 0
    for _, p in ipairs(list) do
        for _, child in pairs(p:GetChildren()) do
            if child:IsA("WeldConstraint") and child.Name == "GroupWeld" then
                child:Destroy()
                count = count + 1
            end
        end
    end
    if count > 0 then
        notify("Skit F3X", "Ungrouped", "unlink")
    end
end

-- ==========================================================
-- UNDO
-- ==========================================================
function SkitF3X.Undo()
    if #SkitF3X.undoStack > 0 then
        local lastAction = table.remove(SkitF3X.undoStack, #SkitF3X.undoStack)
        if lastAction.Part and lastAction.Part.Parent then
            lastAction.Part.CFrame = lastAction.CFrame
            lastAction.Part.Size = lastAction.Size
            if not SkitF3X.MultiSelect then
                SkitF3X.SelectPart(lastAction.Part)
            end
            notify("Skit F3X", "Undone", "undo")
        end
    end
end

-- ==========================================================
-- COLOR
-- ==========================================================
function SkitF3X.SetColor(color)
    if next(SkitF3X.selectedPartsList) then
        for p in pairs(SkitF3X.selectedPartsList) do
            p.Color = color
        end
    elseif SkitF3X.targetPart then
        SkitF3X.targetPart.Color = color
    end
end

-- ==========================================================
-- MATERIAL
-- ==========================================================
function SkitF3X.SetMaterial(materialName)
    local list = {}
    if next(SkitF3X.selectedPartsList) then
        for p in pairs(SkitF3X.selectedPartsList) do
            table.insert(list, p)
        end
    elseif SkitF3X.targetPart then
        table.insert(list, SkitF3X.targetPart)
    end

    for _, p in ipairs(list) do
        if materialName == "Studs" then
            p.TopSurface = Enum.SurfaceType.Studs
        elseif materialName == "Inlet" then
            p.TopSurface = Enum.SurfaceType.Inlet
        else
            p.TopSurface = Enum.SurfaceType.Smooth
            local matEnum = Enum.Material[materialName]
            if matEnum then p.Material = matEnum end
            if materialName == "Ice" then
                p.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.3, 0.5, 1, 1)
            end
        end
    end
end

-- ==========================================================
-- PROPERTIES
-- ==========================================================
function SkitF3X.SetFriction(val)
    if SkitF3X.targetPart then
        val = math.clamp(val, 0, 10)
        SkitF3X.targetPart.CustomPhysicalProperties = PhysicalProperties.new(val, 0.3, 0.5, 1, 1)
    end
end

function SkitF3X.SetTransparency(val)
    if SkitF3X.targetPart then
        val = math.clamp(val, 0, 1)
        SkitF3X.targetPart.Transparency = val
    end
end

-- ==========================================================
-- MOVING PART SETTINGS
-- ==========================================================
function SkitF3X.SetMovingSpeed(val)
    local targetPart = SkitF3X.targetPart
    local root = (targetPart and targetPart:FindFirstChild("IsMovingPart")) and targetPart or (targetPart and targetPart.Parent)
    if root and root:FindFirstChild("IsMovingPart") then
        root.IsMovingPart.ForwardSpeed.Value = val
    end
end

function SkitF3X.SetMovingBackSpeed(val)
    local targetPart = SkitF3X.targetPart
    local root = (targetPart and targetPart:FindFirstChild("IsMovingPart")) and targetPart or (targetPart and targetPart.Parent)
    if root and root:FindFirstChild("IsMovingPart") then
        root.IsMovingPart.BackSpeed.Value = val
    end
end

function SkitF3X.SetMovingGlide(useGlide)
    local targetPart = SkitF3X.targetPart
    local root = (targetPart and targetPart:FindFirstChild("IsMovingPart")) and targetPart or (targetPart and targetPart.Parent)
    if root and root:FindFirstChild("IsMovingPart") then
        root.IsMovingPart.ReturnMode.Value = useGlide and "GLIDE" or "SNAP"
    end
end

function SkitF3X.GetMovingGlide()
    local targetPart = SkitF3X.targetPart
    local root = (targetPart and targetPart:FindFirstChild("IsMovingPart")) and targetPart or (targetPart and targetPart.Parent)
    if root and root:FindFirstChild("IsMovingPart") then
        return root.IsMovingPart.ReturnMode.Value == "GLIDE"
    end
    return false
end

-- ==========================================================
-- EXPORT / IMPORT
-- ==========================================================
function SkitF3X.ExportData()
    local exportData = {}
    local listToSave = {}

    if next(SkitF3X.selectedPartsList) then
        for p in pairs(SkitF3X.selectedPartsList) do
            table.insert(listToSave, p)
        end
    elseif SkitF3X.targetPart then
        table.insert(listToSave, SkitF3X.targetPart)
    else
        for _, child in pairs(workspace:GetChildren()) do
            if child:IsA("BasePart") and child.Name ~= "Terrain" and child.Name ~= "Baseplate" and not Players:GetPlayerFromCharacter(child.Parent) then
                table.insert(listToSave, child)
            end
        end
    end

    for _, child in ipairs(listToSave) do
        local data = {
            Name = child.Name,
            Size = {child.Size.X, child.Size.Y, child.Size.Z},
            CFrame = {child.CFrame:GetComponents()},
            Color = {child.Color.R, child.Color.G, child.Color.B},
            Transparency = child.Transparency,
            Anchored = child.Anchored,
            CanCollide = child.CanCollide,
            Material = child.Material.Name,
            TopSurface = child.TopSurface.Name,
            Friction = child.CustomPhysicalProperties and child.CustomPhysicalProperties.Friction or 0.7,
        }
        if child:FindFirstChild("IsMovingPart") then
            data.MoveData = {
                F = child.IsMovingPart.ForwardSpeed.Value,
                B = child.IsMovingPart.BackSpeed.Value,
                R = child.IsMovingPart.ReturnMode.Value,
                P1 = {child.Place1.CFrame:GetComponents()},
                P2 = {child.Place2.CFrame:GetComponents()},
            }
        end
        table.insert(exportData, data)
    end

    local roundedData = round4(exportData)
    return HttpService:JSONEncode(roundedData)
end

function SkitF3X.ImportData(text)
    local success, decoded = pcall(function() return HttpService:JSONDecode(text) end)
    if not success or type(decoded) ~= "table" then
        notify("Skit F3X", "Invalid code", "x")
        return false
    end

    for _, v in ipairs(decoded) do
        local p = Instance.new("Part")
        p.Name = v.Name
        p.Size = Vector3.new(unpack(v.Size))
        p.CFrame = CFrame.new(unpack(v.CFrame))
        p.Color = Color3.new(unpack(v.Color))
        p.Transparency = v.Transparency
        p.Anchored = v.Anchored
        p.CanCollide = v.CanCollide
        if v.Material and Enum.Material[v.Material] then
            p.Material = Enum.Material[v.Material]
        end
        if v.TopSurface and Enum.SurfaceType[v.TopSurface] then
            p.TopSurface = Enum.SurfaceType[v.TopSurface]
        end
        if v.Friction then
            p.CustomPhysicalProperties = PhysicalProperties.new(v.Friction, 0.3, 0.5, 1, 1)
        end

        if v.MoveData then
            local md = Instance.new("Configuration", p)
            md.Name = "IsMovingPart"
            local f = Instance.new("NumberValue", md)
            f.Name = "ForwardSpeed"
            f.Value = v.MoveData.F
            local b = Instance.new("NumberValue", md)
            b.Name = "BackSpeed"
            b.Value = v.MoveData.B
            local r = Instance.new("StringValue", md)
            r.Name = "ReturnMode"
            r.Value = v.MoveData.R

            local p1 = p:Clone()
            p1.Name = "Place1"
            p1.BrickColor = BrickColor.new("Lime green")
            p1.Transparency = 0.6
            p1.CanCollide = false
            p1.CFrame = CFrame.new(unpack(v.MoveData.P1))
            p1:ClearAllChildren()
            p1.Parent = p

            local p2 = p:Clone()
            p2.Name = "Place2"
            p2.BrickColor = BrickColor.new("Really red")
            p2.Transparency = 0.6
            p2.CanCollide = false
            p2.CFrame = CFrame.new(unpack(v.MoveData.P2))
            p2:ClearAllChildren()
            p2.Parent = p
        end
        p.Parent = workspace
    end

    notify("Skit F3X", "Imported " .. #decoded .. " parts", "check")
    return true
end

-- ==========================================================
-- GIZMO DRAGGING
-- ==========================================================
handles.MouseButton1Down:Connect(function()
    if not SkitF3X.targetPart then return end
    freezePlayer()
    SkitF3X.isDraggingGizmo = true
    Camera.CameraType = Enum.CameraType.Scriptable
    SkitF3X.originalCFrame = SkitF3X.targetPart.CFrame
    SkitF3X.originalSize = SkitF3X.targetPart.Size
end)

handles.MouseDrag:Connect(function(face, distance)
    if not SkitF3X.targetPart or not SkitF3X.originalCFrame then return end
    local axis = Vector3.FromNormalId(face)
    if SkitF3X.GizmoMode == "Move" then
        SkitF3X.targetPart.CFrame = SkitF3X.originalCFrame * CFrame.new(axis * distance)
    elseif SkitF3X.GizmoMode == "Resize" then
        local sizeChange = Vector3.new(math.abs(axis.X), math.abs(axis.Y), math.abs(axis.Z)) * distance
        SkitF3X.targetPart.Size = Vector3.new(
            math.max(0.1, SkitF3X.originalSize.X + sizeChange.X),
            math.max(0.1, SkitF3X.originalSize.Y + sizeChange.Y),
            math.max(0.1, SkitF3X.originalSize.Z + sizeChange.Z)
        )
        SkitF3X.targetPart.CFrame = SkitF3X.originalCFrame * CFrame.new(axis * (distance / 2))

        if SkitF3X.targetPart:FindFirstChild("Place1") then
            SkitF3X.targetPart.Place1.Size = SkitF3X.targetPart.Size
        end
        if SkitF3X.targetPart:FindFirstChild("Place2") then
            SkitF3X.targetPart.Place2.Size = SkitF3X.targetPart.Size
        end
    end
end)

handles.MouseButton1Up:Connect(function()
    unfreezePlayer()
    SkitF3X.isDraggingGizmo = false
    Camera.CameraType = Enum.CameraType.Custom
    saveState(SkitF3X.targetPart, SkitF3X.originalCFrame, SkitF3X.originalSize)
end)

arcHandles.MouseButton1Down:Connect(function()
    if not SkitF3X.targetPart then return end
    freezePlayer()
    SkitF3X.isDraggingGizmo = true
    Camera.CameraType = Enum.CameraType.Scriptable
    SkitF3X.originalAxisCFrame = SkitF3X.targetPart.CFrame
end)

arcHandles.MouseDrag:Connect(function(axis, relativeAngle)
    if not SkitF3X.targetPart or not SkitF3X.originalAxisCFrame then return end
    local axisVec = Vector3.FromAxis(axis)
    SkitF3X.targetPart.CFrame = SkitF3X.originalAxisCFrame * CFrame.Angles(
        axisVec.X * relativeAngle,
        axisVec.Y * relativeAngle,
        axisVec.Z * relativeAngle
    )
end)

arcHandles.MouseButton1Up:Connect(function()
    unfreezePlayer()
    SkitF3X.isDraggingGizmo = false
    Camera.CameraType = Enum.CameraType.Custom
    saveState(SkitF3X.targetPart, SkitF3X.originalAxisCFrame, SkitF3X.targetPart.Size)
end)

-- ==========================================================
-- INPUT
-- ==========================================================
local touchStartPos = nil
local isDraggingCamera = false

UserInputService.InputBegan:Connect(function(input, gp)
    if not SkitF3X.Enabled or SkitF3X.isDraggingGizmo or gp then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        touchStartPos = input.Position
        isDraggingCamera = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        if touchStartPos and (input.Position - touchStartPos).Magnitude > 10 then
            isDraggingCamera = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if not SkitF3X.Enabled or SkitF3X.isDraggingGizmo then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if touchStartPos and not isDraggingCamera then
            local finalTarget = Mouse.Target
            if SkitF3X.MultiSelect then
                SkitF3X.ToggleMultiSelectTarget(finalTarget)
            else
                SkitF3X.SelectPart(finalTarget)
            end
        end
        touchStartPos = nil
        isDraggingCamera = false
    end
end)

return SkitF3X