local AnimPack = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local notifyFn = nil

function AnimPack.SetNotify(fn)
    notifyFn = fn
end

local function notify(title, content, icon)
    if notifyFn then notifyFn(title, content, icon) end
end

AnimPack.isApplying = false
AnimPack.currentPackName = nil

function AnimPack.GetCharacterRig()
    local char = LocalPlayer.Character
    if not char then return "Unknown" end
    if char:FindFirstChild("UpperTorso") and char:FindFirstChild("LowerTorso") then
        return "R15"
    end
    if char:FindFirstChild("Torso") then
        return "R6"
    end
    return "Unknown"
end

AnimPack.PACKS = {
    ["Adidas Sports"] = {
        WalkAnim = 18537392113,
        RunAnim  = 18537384940,
        JumpAnim = 18537380791,
        FallAnim = 18537367238,
        SwimIdle = 18537387180,
        Swim     = 18537389531,
        Animation1 = 18537376492,
        Animation2 = 18537371272,
        ClimbAnim = 18537363391,
        Rig = "Both"
    },
    ["Adidas Community"] = {
        WalkAnim = 122150855457006,
        RunAnim  = 82598234841035,
        JumpAnim = 75290611992385,
        FallAnim = 98600215928904,
        SwimIdle = 109346520324160,
        Swim     = 133308483266208,
        Animation1 = 122257458498464,
        Animation2 = 102357151005774,
        ClimbAnim = 88763136693023,
        Rig = "Both"
    },
    ["Adidas Aura"] = {
        WalkAnim = 83842218823011,
        RunAnim  = 118320322718866,
        JumpAnim = 109996626521204,
        FallAnim = 95603166884636,
        SwimIdle = 94922130551805,
        Swim     = 134530128383903,
        Animation1 = 110211186840347,
        Animation2 = 114191137265065,
        ClimbAnim = 97824616490448,
        Rig = "Both"
    },
    ["Wicked Popular"] = {
        WalkAnim = 92072849924640,
        RunAnim = 72301599441680,
        JumpAnim = 104325245285198,
        FallAnim = 121152442762481,
        Animation1 = 118832222982049,
        ClimbAnim = 131326830509784,
        SwimIdle = 113199415118199,
        Swim = 99384245425157,
        Animation2 = 76049494037641,
        Rig = "Both"
    },
    Elder = {
        WalkAnim = 10921111375,
        RunAnim  = 10921104374,
        JumpAnim = 10921107367,
        FallAnim = 10921105765,
        SwimIdle = 10921110146,
        Swim     = 10921108971,
        ClimbAnim = 10921100400,
        Animation1 = 10921101664,
        Animation2 = 10921102574,
        Rig = "Both"
    },
    Zombie = {
        WalkAnim = 10921355261,
        RunAnim  = 616163682,
        JumpAnim = 10921351278,
        FallAnim = 10921350320,
        SwimIdle = 10921353442,
        Swim     = 10921352344,
        Animation1 = 10921344533,
        Animation2 = 10921345304,
        ClimbAnim = 10921343576,
        Rig = "R15"
    },
    Mage = {
        WalkAnim = 10921152678,
        RunAnim  = 10921148209,
        JumpAnim = 10921149743,
        FallAnim = 10921148939,
        SwimIdle = 10921151661,
        Swim     = 10921150788,
        ClimbAnim = 10921143404,
        Animation1 = 10921144709,
        Animation2 = 10921145797,
        Rig = "Both"
    },
    ["Catwalk Glam"] = {
        WalkAnim = 109168724482748,
        RunAnim  = 81024476153754,
        JumpAnim = 116936326516985,
        FallAnim = 92294537340807,
        SwimIdle = 98854111361360,
        Swim     = 134591743181628,
        ClimbAnim = 119377220967554,
        Animation1 = 133806214992291,
        Animation2 = 94970088341563,
        Rig = "Both"
    },
    Astronaut = {
        WalkAnim = 10921046031,
        RunAnim  = 10921039308,
        JumpAnim = 10921042494,
        FallAnim = 10921040576,
        SwimIdle = 10921045006,
        Swim     = 10921044000,
        ClimbAnim = 10921032124,
        Animation1 = 10921034824,
        Animation2 = 10921036806,
        Rig = "Both"
    },
    ['Wicked "Dancing Through Life"'] = {
        WalkAnim = 73718308412641,
        RunAnim  = 135515454877967,
        JumpAnim = 78508480717326,
        FallAnim = 78147885297412,
        SwimIdle = 129183123083281,
        Swim     = 110657013921774,
        ClimbAnim = 129447497744818,
        Animation1 = 92849173543269,
        Animation2 = 132238900951109,
        Rig = "Both"
    },
    Werewolf = {
        WalkAnim = 10921342074,
        RunAnim  = 10921336997,
        JumpAnim = nil,
        FallAnim = 10921337907,
        SwimIdle = 10921341319,
        Swim     = 10921340419,
        ClimbAnim = 10921329322,
        Animation1 = 10921330408,
        Animation2 = 10921333667,
        Rig = "R15"
    },
    Superhero = {
        WalkAnim = 10921298616,
        RunAnim  = 10921291831,
        JumpAnim = 10921294559,
        FallAnim = 10921293373,
        SwimIdle = 10921297391,
        Swim     = 10921295495,
        ClimbAnim = 10921286911,
        Animation1 = 10921288909,
        Animation2 = 10921290167,
        Rig = "R15"
    },
    Toy = {
        WalkAnim = 10921312010,
        RunAnim  = 10921306285,
        JumpAnim = 10921308158,
        FallAnim = 10921307241,
        SwimIdle = 10921310341,
        Swim     = 10921309319,
        ClimbAnim = 10921300839,
        Animation1 = 10921301576,
        Animation2 = nil,
        Rig = "R15"
    },
    ["No Boundaries"] = {
        WalkAnim = 18747074203,
        RunAnim  = 18747070484,
        JumpAnim = 18747069148,
        FallAnim = 18747062535,
        SwimIdle = 18747071682,
        Swim     = 18747073181,
        ClimbAnim = 18747060903,
        Animation1 = 18747067405,
        Animation2 = 18747063918,
        Rig = "Both"
    },
    NFL = {
        WalkAnim = 110358958299415,
        RunAnim  = 117333533048078,
        JumpAnim = 119846112151352,
        FallAnim = 129773241321032,
        SwimIdle = 79090109939093,
        Swim     = 132697394189921,
        ClimbAnim = 134630013742019,
        Animation1 = 92080889861410,
        Animation2 = 74451233229259,
        Rig = "Both"
    },
    ["Amazon Unboxed"] = {
        WalkAnim = 90478085024465,
        RunAnim  = 134824450619865,
        JumpAnim = 121454505477205,
        FallAnim = 94788218468396,
        SwimIdle = 129126268464847,
        Swim     = 105962919001086,
        ClimbAnim = 121145883950231,
        Animation1 = 98281136301627,
        Animation2 = nil,
        Rig = "Both"
    },
    Vampire = {
        WalkAnim = 10921326949,
        RunAnim  = 10921320299,
        JumpAnim = 10921322186,
        FallAnim = 10921321317,
        SwimIdle = 10921325443,
        Swim     = 10921324408,
        ClimbAnim = 10921314188,
        Animation1 = 10921315373,
        Animation2 = nil,
        Rig = "R15"
    },
    ["Ninja"] = {
        Run=656118852, Walk=656121766, Jump=656117878, Fall=656115606,
        Swim=656119721, SwimIdle=656121397, Climb=656114359,
        Idle={656117400,656118341,886742569},
        Rig = "Both"
    },
    ["Robot"] = {
        Run=616091570, Walk=616095330, Jump=616090535, Fall=616087089,
        Swim=616092998, SwimIdle=616094091, Climb=616086039,
        Idle={616088211,616089559,885531463},
        Rig = "Both"
    },
    ["Levitation"] = {
        Run=616010382, Walk=616013216, Jump=616008936, Fall=616005863,
        Swim=616011509, SwimIdle=616012453, Climb=616003713,
        Idle={616006778,616008087,886862142},
        Rig = "Both"
    },
    ["Stylish"] = {
        Run=616140816, Walk=616146177, Jump=616139451, Fall=616134815,
        Swim=616143378, SwimIdle=616144772, Climb=616133594,
        Idle={616136790,616138447,886888594},
        Rig = "Both"
    },
    ["Bubbly"] = {
        Run=910025107, Walk=910034870, Jump=910016857, Fall=910001910,
        Swim=910028158, SwimIdle=910030921, Climb=909997997,
        Idle={910004836,910009958,1018536639},
        Rig = "Both"
    },
    ["Cartoon"] = {
        Run=742638842, Walk=742640026, Jump=742637942, Fall=742637151,
        Swim=742639220, SwimIdle=742639812, Climb=742636889,
        Idle={742637544,742638445,885477856},
        Rig = "Both"
    },
}

AnimPack.DEFAULT_ANIMS = {
    WalkAnim = 8913843362,
    RunAnim = 8913846406,
    JumpAnim = 8913844767,
    FallAnim = 8913843030,
    SwimIdle = 8913848098,
    Swim = 8913847316,
    Animation1 = 8913837058,
    Animation2 = 8913838814,
    ClimbAnim = 8913834912,
}

local function waitForAnimate(char)
    for _ = 1, 40 do
        local a = char:FindFirstChild("Animate")
        if a and a:FindFirstChild("idle") and a:FindFirstChild("run") and a:FindFirstChild("walk") then
            return a
        end
        task.wait(0.1)
    end
    return nil
end

local function setAnim(animObj, id)
    if animObj and id then
        animObj.AnimationId = "rbxassetid://" .. tostring(id)
    end
end

local function ensureAnim(folder, name)
    if not folder then return nil end
    local a = folder:FindFirstChild(name)
    if not a then
        a = Instance.new("Animation")
        a.Name = name
        a.Parent = folder
    end
    return a
end

local function ensureIdleSlots(idleFolder, n)
    if not idleFolder then return end
    n = n or 2
    for i = 1, n do
        ensureAnim(idleFolder, "Animation" .. i)
    end
end

local function pick(pack, ...)
    for i = 1, select("#", ...) do
        local k = select(i, ...)
        local v = pack[k]
        if v ~= nil then return v end
    end
    return nil
end

function AnimPack.ApplyPack(packName)
    if AnimPack.isApplying then return false end
    AnimPack.isApplying = true

    local pack = AnimPack.PACKS[packName]
    if not pack then
        AnimPack.isApplying = false
        return false
    end

    local rig = AnimPack.GetCharacterRig()
    local packRig = pack.Rig or "Both"

    if packRig == "R6" and rig == "R15" then
        notify("Anim Pack", "Pack này chỉ dùng cho R6, bạn đang dùng R15!", "x")
        AnimPack.isApplying = false
        return false
    elseif packRig == "R15" and rig == "R6" then
        notify("Anim Pack", "Pack này chỉ dùng cho R15, bạn đang dùng R6!", "x")
        AnimPack.isApplying = false
        return false
    end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local animate = waitForAnimate(char)
    if not animate then
        AnimPack.isApplying = false
        return false
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
            pcall(function() t:Stop(0) end)
        end
    end

    local runObj   = ensureAnim(animate:FindFirstChild("run"),   "RunAnim")
    local walkObj  = ensureAnim(animate:FindFirstChild("walk"),  "WalkAnim")
    local jumpObj  = ensureAnim(animate:FindFirstChild("jump"),  "JumpAnim")
    local fallObj  = ensureAnim(animate:FindFirstChild("fall"),  "FallAnim")
    local climbObj = ensureAnim(animate:FindFirstChild("climb"), "ClimbAnim")
    local swimObj  = ensureAnim(animate:FindFirstChild("swim"),     "Swim")
    local swimIdleObj = ensureAnim(animate:FindFirstChild("swimidle"), "SwimIdle")
    local idleFolder = animate:FindFirstChild("idle")

    setAnim(walkObj,  pick(pack, "WalkAnim", "Walk"))
    setAnim(runObj,   pick(pack, "RunAnim", "Run"))
    setAnim(jumpObj,  pick(pack, "JumpAnim", "Jump"))
    setAnim(fallObj,  pick(pack, "FallAnim", "Fall"))
    setAnim(climbObj, pick(pack, "ClimbAnim", "Climb"))
    setAnim(swimObj,      pick(pack, "Swim"))
    setAnim(swimIdleObj,  pick(pack, "SwimIdle") or pick(pack, "Swim"))

    if idleFolder then
        local a1 = pick(pack, "Animation1")
        local a2 = pick(pack, "Animation2")
        if a1 or a2 then
            ensureIdleSlots(idleFolder, 2)
            local id1 = a1 or a2
            local id2 = a2 or a1 or id1
            setAnim(idleFolder:FindFirstChild("Animation1"), id1)
            setAnim(idleFolder:FindFirstChild("Animation2"), id2)
        elseif pack.Idle and #pack.Idle > 0 then
            ensureIdleSlots(idleFolder, math.max(2, #pack.Idle))
            setAnim(idleFolder:FindFirstChild("Animation1"), pack.Idle[1])
            setAnim(idleFolder:FindFirstChild("Animation2"), pack.Idle[2] or pack.Idle[1])
            for i = 3, #pack.Idle do
                local a = idleFolder:FindFirstChild("Animation" .. i)
                if a then setAnim(a, pack.Idle[i]) end
            end
        end
    end

    animate.Disabled = true
    task.wait(0.06)
    animate.Disabled = false

    AnimPack.currentPackName = packName
    AnimPack.isApplying = false

    notify("Anim Pack", "Đã áp dụng: " .. packName, "music")
    return true
end

function AnimPack.ResetToDefault()
    local char = LocalPlayer.Character
    if not char then
        notify("Anim Pack", "Không tìm thấy nhân vật!", "x")
        return
    end

    local animate = waitForAnimate(char)
    if not animate then
        notify("Anim Pack", "Không tìm thấy Animate!", "x")
        return
    end

    local runObj   = ensureAnim(animate:FindFirstChild("run"),   "RunAnim")
    local walkObj  = ensureAnim(animate:FindFirstChild("walk"),  "WalkAnim")
    local jumpObj  = ensureAnim(animate:FindFirstChild("jump"),  "JumpAnim")
    local fallObj  = ensureAnim(animate:FindFirstChild("fall"),  "FallAnim")
    local climbObj = ensureAnim(animate:FindFirstChild("climb"), "ClimbAnim")
    local swimObj  = ensureAnim(animate:FindFirstChild("swim"),     "Swim")
    local swimIdleObj = ensureAnim(animate:FindFirstChild("swimidle"), "SwimIdle")
    local idleFolder = animate:FindFirstChild("idle")

    setAnim(walkObj, AnimPack.DEFAULT_ANIMS.WalkAnim)
    setAnim(runObj, AnimPack.DEFAULT_ANIMS.RunAnim)
    setAnim(jumpObj, AnimPack.DEFAULT_ANIMS.JumpAnim)
    setAnim(fallObj, AnimPack.DEFAULT_ANIMS.FallAnim)
    setAnim(climbObj, AnimPack.DEFAULT_ANIMS.ClimbAnim)
    setAnim(swimObj, AnimPack.DEFAULT_ANIMS.Swim)
    setAnim(swimIdleObj, AnimPack.DEFAULT_ANIMS.SwimIdle)

    if idleFolder then
        setAnim(idleFolder:FindFirstChild("Animation1"), AnimPack.DEFAULT_ANIMS.Animation1)
        setAnim(idleFolder:FindFirstChild("Animation2"), AnimPack.DEFAULT_ANIMS.Animation2)
    end

    animate.Disabled = true
    task.wait(0.06)
    animate.Disabled = false

    AnimPack.currentPackName = nil
    notify("Anim Pack", "Đã reset về mặc định!", "refresh")
end

function AnimPack.ApplyCustomAnimations(customAnimIds)
    local char = LocalPlayer.Character
    if not char then
        notify("Anim", "Không tìm thấy nhân vật!", "x")
        return
    end

    local animate = waitForAnimate(char)
    if not animate then
        notify("Anim", "Không tìm thấy Animate!", "x")
        return
    end

    local animKeys = {"WalkAnim", "RunAnim", "JumpAnim", "FallAnim", "SwimIdle", "Swim", "Animation1", "Animation2", "ClimbAnim"}
    local applied = 0

    for _, key in ipairs(animKeys) do
        local id = customAnimIds[key]
        if id then
            if key == "Animation1" or key == "Animation2" then
                local idleFolder = animate:FindFirstChild("idle")
                if idleFolder then
                    local animObj = ensureAnim(idleFolder, key)
                    setAnim(animObj, id)
                    applied = applied + 1
                end
            else
                local folderName = key:gsub("Anim$", ""):lower()
                local folder = animate:FindFirstChild(folderName)
                if folder then
                    local animObj = ensureAnim(folder, key)
                    setAnim(animObj, id)
                    applied = applied + 1
                end
            end
        end
    end

    animate.Disabled = true
    task.wait(0.06)
    animate.Disabled = false

    notify("Anim", "Đã apply " .. applied .. " animation!", "check")
end

function AnimPack.GetPackNames()
    local names = {}
    for name in pairs(AnimPack.PACKS) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

return AnimPack