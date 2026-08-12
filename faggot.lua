function addPurpleGradient(parent, color1, color2)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1 or Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, color2 or Color3.fromRGB(170, 170, 178)),
    })
    g.Parent = parent
    return g
end
local HapticService = game:GetService("HapticService")
function triggerHaptic()
    pcall(function()
        if UserInputService.TouchEnabled then
            HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0.35)
            task.delay(0.06, function()
                pcall(function()
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
                end)
            end)
        end
    end)
end
function playUiSound(soundType)
    pcall(function()
        local s = Instance.new("Sound")
        s.Name = "PulseUiFeedback"
        s.Volume = 0.45
        s.SoundId = (soundType == "toggle") and "rbxassetid://6895079853" or "rbxassetid://9114223479"
        s.Parent = SoundService
        s:Play()
        task.delay(0.8, function()
            s:Destroy()
        end)
    end)
end
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
_G.PulseHubRuntimeGeneration = (tonumber(_G.PulseHubRuntimeGeneration) or 0) + 1
local PULSE_RUNTIME_GENERATION = _G.PulseHubRuntimeGeneration
function applyImpulseForVelocity(hrp, desiredVelocity)
    if not hrp then
        return
    end
    local mass = hrp.AssemblyMass
    local currentVel = hrp.AssemblyLinearVelocity
    local impulse = (desiredVelocity - currentVel) * mass
    hrp:ApplyImpulse(impulse)
end
function applyImpulseZero(hrp)
    if not hrp then
        return
    end
    local mass = hrp.AssemblyMass
    local currentVel = hrp.AssemblyLinearVelocity
    hrp:ApplyImpulse(-currentVel * mass)
end
_G.PulseIsMobile = true
_G.PulseCursedResetRemote = _G.PulseCursedResetRemote or nil
_G.PulseCursedResetGuid = _G.PulseCursedResetGuid or "f888ee6e-c86d-46e1-93d7-0639d6635d42"
pcall(function()
    if not _G.PulseCursedResetHooked and hookfunction and newcclosure then
        _G.PulseCursedResetHooked = true
        local oldFire
        oldFire = hookfunction(
            Instance.new("RemoteEvent").FireServer,
            newcclosure(function(self, ...)
                if
                    not _G.PulseCursedResetRemote
                    and typeof(self) == "Instance"
                    and self:IsA("RemoteEvent")
                    and self.Name:sub(1, 3) == "RE/"
                then
                    _G.PulseCursedResetRemote = self
                end
                return oldFire(self, ...)
            end)
        )
    end
end)
function _G.PulseCursedInstaReset()
    if not _G.PulseCursedResetRemote then
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc:IsA("RemoteEvent") and desc.Name:sub(1, 3) == "RE/" then
                _G.PulseCursedResetRemote = desc
                break
            end
        end
    end
    if not _G.PulseCursedResetRemote then
        return
    end
    local character = LP.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        pcall(function()
            _G.PulseCursedResetRemote:FireServer(_G.PulseCursedResetGuid, LP, "balloon")
        end)
        return
    end
    local resetDetected = false
    local resetConns = {}
    if humanoid then
        table.insert(
            resetConns,
            humanoid.Died:Connect(function()
                resetDetected = true
            end)
        )
        table.insert(
            resetConns,
            humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if humanoid.Health <= 0 then
                    resetDetected = true
                end
            end)
        )
    end
    if character then
        table.insert(
            resetConns,
            character.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    resetDetected = true
                end
            end)
        )
    end
    task.spawn(function()
        for _ = 1, 10 do
            if resetDetected then
                break
            end
            pcall(function()
                _G.PulseCursedResetRemote:FireServer(_G.PulseCursedResetGuid, LP, "balloon")
            end)
            task.wait(0.05)
        end
        for _, conn in ipairs(resetConns) do
            pcall(function()
                conn:Disconnect()
            end)
        end
    end)
end
function cursedInstaReset()
    return _G.PulseCursedInstaReset()
end
for _, name in ipairs({ "PulseHubAdaptReconstruct", "BrokenHubAdaptReconstruct", "AdaptHubPolished", "CyberHub" }) do
    local old = PlayerGui:FindFirstChild(name)
    if old then
        old:Destroy()
    end
end
local NS = 62
local CS = 29.7
local LAGGER_SPEED = 40
local LAGGER_CARRY_SPEED = 20
LAGGER2_SPEED = 30
LAGGER2_CARRY_SPEED = 15
_G.PulseLaggerCycleOrder = { "Lagger Carry", "Lagger Carry 2", "Lagger", "Lagger 2" }
local currentSpeedMode = "Normal"
autoCarrySpeedEnabled = false
setAutoCarrySpeedVisual = nil
_G.PulseAutoCarryWasCarrying = false
_G.PulseAutoCarrySavedMode = nil
local autoStealEnabled = false
local softStealEnabled = false
local softStealRow = nil
_G.PulseSoftStealEnabled = false
_G.PulseNormalRagdollStealEnabled = false
_G.PulseSemiRagdollStealEnabled = false
local selectedStealMode = "Normal"
local autoStealRadius = 62
_G.PulseStealRadii = _G.PulseStealRadii or { Normal = 62, Semi = 9, ["Normal V2"] = 62 }
local autoStealRadiusBox = nil
local selectedAimbotMode = "Anti Bypass"
local AIMBOT_SPEED = 58
local LAGGER_AIMBOT_SPEED = 40
_G.PulseAntiBypassAimbotSpeed = _G.PulseAntiBypassAimbotSpeed or 58
if _G.PulseAntiBypassLaggerAimbotSpeed == nil or tonumber(_G.PulseAntiBypassLaggerAimbotSpeed) == 58 then
    _G.PulseAntiBypassLaggerAimbotSpeed = 40
end
local autoSwingEnabled = false
_G.PulseNormalAimbotOn = _G.PulseNormalAimbotOn or false
_G.PulseAntiBypassAimbotOn = _G.PulseAntiBypassAimbotOn or false
local antiDesyncAutoSwingEnabled = false
_G.PulseAntiDesyncAimbotOn = _G.PulseAntiDesyncAimbotOn or false
local ANTI_DESYNC_AIMBOT_SPEED = 58
local batCounterEnabled = false
local medCounterEnabled = false
local espEnabled = false
local showTracerEnabled = false
local ragdollCountdownEnabled = false
local fpsBoostEnabled = false
local antiLagVisualEnabled = false
local fovEnabled = false
local fovValue = 70
local noCamCollisionEnabled = false
_G.PulseNoPlayerCollisionEnabled = _G.PulseNoPlayerCollisionEnabled or false
local customFontVisualEnabled = false
local skyTheme = "Off"
local setPlayerESPVisual = nil
local setTracerESPVisual = nil
local setRagdollCountdownVisual = nil
local setAntiRagdollModeRow = nil
local setMobileButtonStyleRow = nil
local setFPSBoostVisual = nil
local setAntiLagVisual = nil
local setFOVVisual = nil
local setNoCamCollisionVisual = nil
_G.PulseSetNoPlayerCollisionVisual = _G.PulseSetNoPlayerCollisionVisual or nil
local setCustomFontVisual = nil
local skyValueLabel = nil
local autoLeftEnabled = false
local autoRightEnabled = false
local DEFAULT_SPEED_KEYBINDS = {
    SpeedToggle = Enum.KeyCode.Q,
    LaggerToggle = Enum.KeyCode.R,
    DropBrainrot = Enum.KeyCode.X,
    Aimbot = Enum.KeyCode.E,
    AntiDesyncAimbot = Enum.KeyCode.V,
    AutoLeft = Enum.KeyCode.Z,
    AutoRight = Enum.KeyCode.C,
    InstantReset = Enum.KeyCode.T,
    ToggleUI = Enum.KeyCode.LeftControl,
}
local DEFAULT_TP_DOWN_KEYBIND = Enum.KeyCode.F
local speedKeybinds = {
    SpeedToggle = DEFAULT_SPEED_KEYBINDS.SpeedToggle,
    LaggerToggle = DEFAULT_SPEED_KEYBINDS.LaggerToggle,
    DropBrainrot = DEFAULT_SPEED_KEYBINDS.DropBrainrot,
    Aimbot = DEFAULT_SPEED_KEYBINDS.Aimbot,
    AntiDesyncAimbot = DEFAULT_SPEED_KEYBINDS.AntiDesyncAimbot,
    AutoLeft = DEFAULT_SPEED_KEYBINDS.AutoLeft,
    AutoRight = DEFAULT_SPEED_KEYBINDS.AutoRight,
    InstantReset = DEFAULT_SPEED_KEYBINDS.InstantReset,
    ToggleUI = DEFAULT_SPEED_KEYBINDS.ToggleUI,
}
local speedKeybindButtons = {}
local listeningForSpeedKey = nil
local autoTPEnabled = false
local autoTPHeight = 20
local autoTPConn = nil
local autoTPLastRun = 0
local autoTPClickDebounce = false
local tpDownKeybind = Enum.KeyCode.F
local tpDownKeybindButton = nil
local listeningForTPDownKey = false
local keybindListenStartedAt = 0
local setAutoTPVisual = nil
_G.PulseAutoRagdollTpState = {
    enabled = false,
    connection = nil,
    returning = false,
    plotSide = nil,
    plotName = nil,
    lastHealth = 100,
    lastPlotRefresh = 0,
    lastTrigger = 0,
    setVisual = nil,
}
local function doAutoTPDown(force)
    local char = LP.Character
    if not char then
        return
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end
    local hum2 = char:FindFirstChildOfClass("Humanoid")
    if not hum2 then
        return
    end
    if not force then
        if hum2.FloorMaterial ~= Enum.Material.Air then
            return
        end
        if not (hrp.Position.Y >= autoTPHeight) then
            return
        end
    end
    hrp.CFrame = CFrame.new(hrp.Position.X, -7.00, hrp.Position.Z)
        * CFrame.Angles(0, select(2, hrp.CFrame:ToEulerAnglesYXZ()), 0)
    hrp.Velocity = Vector3.zero
end
local function startAutoTP()
    autoTPEnabled = true
    if autoTPConn then
        pcall(function()
            task.cancel(autoTPConn)
        end)
        pcall(function()
            if typeof(autoTPConn) == "RBXScriptConnection" then
                autoTPConn:Disconnect()
            end
        end)
        autoTPConn = nil
    end
    autoTPConn = task.spawn(function()
        while autoTPEnabled do
            task.wait(0.1)
            pcall(function()
                doAutoTPDown(false)
            end)
        end
    end)
    if setAutoTPVisual then
        setAutoTPVisual(true)
    end
end
local function stopAutoTP()
    autoTPEnabled = false
    if autoTPConn then
        pcall(function()
            task.cancel(autoTPConn)
        end)
        pcall(function()
            if typeof(autoTPConn) == "RBXScriptConnection" then
                autoTPConn:Disconnect()
            end
        end)
        autoTPConn = nil
    end
    if setAutoTPVisual then
        setAutoTPVisual(false)
    end
end
local function runTPFloor()
    pcall(function()
        doAutoTPDown(true)
    end)
end
local function toggleAutoTP(on)
    if on then
        startAutoTP()
    else
        stopAutoTP()
    end
    savePulseConfig()
end
function _G.PulseStopAutoTPForAction()
    if autoTPEnabled then
        stopAutoTP()
        pcall(function()
            if setAutoTPVisual then
                setAutoTPVisual(false)
            end
        end)
        pcall(savePulseConfig)
    end
end
local dropBrainrotActive = false
local DROP_ASCEND_DURATION = 0.2
local DROP_ASCEND_SPEED = 150
local function runDropBrainrot()
    if dropBrainrotActive then
        return
    end
    if _G.PulseStopAutoTPForAction then
        _G.PulseStopAutoTPForAction()
    end
    local char = LP.Character
    if not char then
        return
    end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end
    dropBrainrotActive = true
    local startTime = tick()
    local dropConn
    dropConn = RunService.Heartbeat:Connect(function()
        local currentChar = LP.Character
        local currentRoot = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        if not currentChar or not currentRoot then
            if dropConn then
                dropConn:Disconnect()
            end
            dropBrainrotActive = false
            return
        end
        if tick() - startTime >= DROP_ASCEND_DURATION then
            if dropConn then
                dropConn:Disconnect()
            end
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = { currentChar }
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local rayResult = workspace:Raycast(currentRoot.Position, Vector3.new(0, -2000, 0), rayParams)
            if rayResult then
                local hum = currentChar:FindFirstChildOfClass("Humanoid")
                local offset = (hum and hum.HipHeight or 2) + (currentRoot.Size.Y / 2)
                currentRoot.CFrame =
                    CFrame.new(currentRoot.Position.X, rayResult.Position.Y + offset, currentRoot.Position.Z)
                applyImpulseZero(currentRoot)
            end
            dropBrainrotActive = false
            return
        end
        local currentVel = currentRoot.AssemblyLinearVelocity
        applyImpulseForVelocity(currentRoot, Vector3.new(currentVel.X, DROP_ASCEND_SPEED, currentVel.Z))
    end)
end
local infJumpEnabled = false
local antiRagdollEnabled = false
local antiRagdollConn = nil
local antiRagdollMode = "Splatter"
local antiRagdollNoSplatterCooldown = 0
local mobileButtonStyle = "Button 2"
local unwalkEnabled = false
local unwalkSavedAnimate = nil
local hitHarderAnimEnabled = false
local hitHarderOriginalAnims = {}
local selectedAnimationPack = "OFF"
local AnimationPacks = {
    ["Zombie"] = {
        idle = { { "rbxassetid://616158929", 1 }, { "rbxassetid://616158929", 1 } },
        walk = "rbxassetid://616168032",
        run = "rbxassetid://616163682",
        jump = "rbxassetid://616161997",
        fall = "rbxassetid://616157476",
        climb = "rbxassetid://616156119",
    },
    ["Ninja"] = {
        idle = { { "rbxassetid://656117400", 1 }, { "rbxassetid://656117400", 1 } },
        walk = "rbxassetid://656121766",
        run = "rbxassetid://656118852",
        jump = "rbxassetid://656117878",
        fall = "rbxassetid://656115606",
        climb = "rbxassetid://656114359",
    },
    ["Knight"] = {
        idle = { { "rbxassetid://657595757", 1 }, { "rbxassetid://657595757", 1 } },
        walk = "rbxassetid://657552124",
        run = "rbxassetid://657564596",
        jump = "rbxassetid://658409194",
        fall = "rbxassetid://657600338",
        climb = "rbxassetid://658360781",
    },
    ["Elder"] = {
        idle = { { "rbxassetid://845397899", 1 }, { "rbxassetid://845397899", 1 } },
        walk = "rbxassetid://845403856",
        run = "rbxassetid://845386501",
        jump = "rbxassetid://845398858",
        fall = "rbxassetid://845397673",
        climb = "rbxassetid://845392038",
    },
    ["Levitate"] = {
        idle = { { "rbxassetid://616006778", 1 }, { "rbxassetid://616006778", 1 } },
        walk = "rbxassetid://616013216",
        run = "rbxassetid://616013216",
        jump = "rbxassetid://616008936",
        fall = "rbxassetid://616005863",
        climb = "rbxassetid://616003713",
    },
    ["Astronaut"] = {
        idle = { { "rbxassetid://891621366", 1 }, { "rbxassetid://891621366", 1 } },
        walk = "rbxassetid://891636393",
        run = "rbxassetid://891636393",
        jump = "rbxassetid://891627522",
        fall = "rbxassetid://891617961",
        climb = "rbxassetid://891609353",
    },
    ["Pirate"] = {
        idle = { { "rbxassetid://750781874", 1 }, { "rbxassetid://750781874", 1 } },
        walk = "rbxassetid://750785693",
        run = "rbxassetid://750783738",
        jump = "rbxassetid://750782230",
        fall = "rbxassetid://750780242",
        climb = "rbxassetid://750779899",
    },
    ["Toy"] = {
        idle = { { "rbxassetid://782841498", 1 }, { "rbxassetid://782841498", 1 } },
        walk = "rbxassetid://782843345",
        run = "rbxassetid://782842708",
        jump = "rbxassetid://782847020",
        fall = "rbxassetid://782846423",
        climb = "rbxassetid://782843869",
    },
    ["Vampire"] = {
        idle = { { "rbxassetid://1083445855", 1 }, { "rbxassetid://1083445855", 1 } },
        walk = "rbxassetid://1083473930",
        run = "rbxassetid://1083462077",
        jump = "rbxassetid://1083455352",
        fall = "rbxassetid://1083443587",
        climb = "rbxassetid://1083439238",
    },
    ["Werewolf"] = {
        idle = { { "rbxassetid://1083195517", 1 }, { "rbxassetid://1083195517", 1 } },
        walk = "rbxassetid://1083178339",
        run = "rbxassetid://1083216690",
        jump = "rbxassetid://1083218792",
        fall = "rbxassetid://1083189019",
        climb = "rbxassetid://1083182000",
    },
    ["Rthro"] = {
        idle = { { "rbxassetid://2510196951", 1 }, { "rbxassetid://2510196951", 1 } },
        walk = "rbxassetid://2510202577",
        run = "rbxassetid://2510198475",
        jump = "rbxassetid://2510197830",
        fall = "rbxassetid://2510195892",
        climb = "rbxassetid://2510192778",
    },
    ["Stylish"] = {
        idle = { { "rbxassetid://616136790", 1 }, { "rbxassetid://616136790", 1 } },
        walk = "rbxassetid://616146177",
        run = "rbxassetid://616140816",
        jump = "rbxassetid://616139451",
        fall = "rbxassetid://616134815",
        climb = "rbxassetid://616133594",
    },
}
local AnimationPackList = {
    "OFF",
    "Unwalk",
    "Hit Harder",
    "Zombie",
    "Ninja",
    "Knight",
    "Elder",
    "Levitate",
    "Astronaut",
    "Pirate",
    "Toy",
    "Vampire",
    "Werewolf",
    "Rthro",
    "Stylish",
}
local AnimationPackIndex = 1
local OriginalAnims = {}
local enableUnwalk, disableUnwalk, enableHitHarderAnim, disableHitHarderAnim
local HIT_HARDER_ANIMS = {
    idle1 = "rbxassetid://133806214992291",
    idle2 = "rbxassetid://94970088341563",
    walk = "rbxassetid://707897309",
    run = "rbxassetid://707861613",
    jump = "rbxassetid://116936326516985",
    fall = "rbxassetid://116936326516985",
}
local function getAnimate(char)
    char = char or LP.Character
    return char and char:FindFirstChild("Animate") or nil
end
local function stopCurrentAnimations(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        pcall(function()
            track:Stop(0)
        end)
    end
end
local function backupAnimations(char)
    local animate = getAnimate(char)
    if not animate or next(OriginalAnims) ~= nil then
        return
    end
    local function getId(obj)
        return obj and obj.AnimationId or nil
    end
    OriginalAnims = {
        idle1 = getId(animate.idle and animate.idle:FindFirstChild("Animation1")),
        idle2 = getId(animate.idle and animate.idle:FindFirstChild("Animation2")),
        walk = getId(animate.walk and animate.walk:FindFirstChild("WalkAnim")),
        run = getId(animate.run and animate.run:FindFirstChild("RunAnim")),
        jump = getId(animate.jump and animate.jump:FindFirstChild("JumpAnim")),
        fall = getId(animate.fall and animate.fall:FindFirstChild("FallAnim")),
        climb = getId(animate.climb and animate.climb:FindFirstChild("ClimbAnim")),
    }
end
local function setAnimId(obj, id)
    if obj and id then
        pcall(function()
            obj.AnimationId = id
        end)
    end
end
local function reloadAnimate(animate)
    if not animate then
        return
    end
    pcall(function()
        animate.Disabled = true
        task.wait()
        animate.Disabled = false
    end)
end
local function resetAnimations()
    local char = LP.Character
    local animate = getAnimate(char)
    if not animate or next(OriginalAnims) == nil then
        return
    end
    stopCurrentAnimations(char)
    setAnimId(animate.idle and animate.idle:FindFirstChild("Animation1"), OriginalAnims.idle1)
    setAnimId(animate.idle and animate.idle:FindFirstChild("Animation2"), OriginalAnims.idle2)
    setAnimId(animate.walk and animate.walk:FindFirstChild("WalkAnim"), OriginalAnims.walk)
    setAnimId(animate.run and animate.run:FindFirstChild("RunAnim"), OriginalAnims.run)
    setAnimId(animate.jump and animate.jump:FindFirstChild("JumpAnim"), OriginalAnims.jump)
    setAnimId(animate.fall and animate.fall:FindFirstChild("FallAnim"), OriginalAnims.fall)
    setAnimId(animate.climb and animate.climb:FindFirstChild("ClimbAnim"), OriginalAnims.climb)
    reloadAnimate(animate)
end
local function applyAnimationPack(packName)
    selectedAnimationPack = packName or "OFF"
    if selectedAnimationPack ~= "Unwalk" and unwalkEnabled then
        disableUnwalk()
    end
    if selectedAnimationPack ~= "Hit Harder" and hitHarderAnimEnabled then
        hitHarderAnimEnabled = false
        resetAnimations()
    end
    if selectedAnimationPack == "Unwalk" then
        resetAnimations()
        enableUnwalk()
        return
    end
    if selectedAnimationPack == "Hit Harder" then
        disableUnwalk()
        enableHitHarderAnim()
        return
    end
    if selectedAnimationPack == "OFF" then
        resetAnimations()
        return
    end
    local pack = AnimationPacks[selectedAnimationPack]
    local char = LP.Character
    local animate = getAnimate(char)
    if not pack or not animate then
        return
    end
    backupAnimations(char)
    stopCurrentAnimations(char)
    setAnimId(animate.idle and animate.idle:FindFirstChild("Animation1"), pack.idle[1][1])
    setAnimId(animate.idle and animate.idle:FindFirstChild("Animation2"), pack.idle[2][1])
    setAnimId(animate.walk and animate.walk:FindFirstChild("WalkAnim"), pack.walk)
    setAnimId(animate.run and animate.run:FindFirstChild("RunAnim"), pack.run)
    setAnimId(animate.jump and animate.jump:FindFirstChild("JumpAnim"), pack.jump)
    setAnimId(animate.fall and animate.fall:FindFirstChild("FallAnim"), pack.fall)
    setAnimId(animate.climb and animate.climb:FindFirstChild("ClimbAnim"), pack.climb)
    reloadAnimate(animate)
end
enableUnwalk = function()
    unwalkEnabled = true
    local char = LP.Character
    local animate = getAnimate(char)
    if animate then
        if not unwalkSavedAnimate then
            unwalkSavedAnimate = animate:Clone()
        end
        stopCurrentAnimations(char)
        animate:Destroy()
    end
end
disableUnwalk = function()
    unwalkEnabled = false
    local char = LP.Character
    if char and not char:FindFirstChild("Animate") and unwalkSavedAnimate then
        local newAnimate = unwalkSavedAnimate:Clone()
        newAnimate.Parent = char
    end
end
enableHitHarderAnim = function()
    hitHarderAnimEnabled = true
    local char = LP.Character
    local animate = getAnimate(char)
    if not animate then
        return
    end
    backupAnimations(char)
    stopCurrentAnimations(char)
    setAnimId(animate.idle and animate.idle:FindFirstChild("Animation1"), HIT_HARDER_ANIMS.idle1)
    setAnimId(animate.idle and animate.idle:FindFirstChild("Animation2"), HIT_HARDER_ANIMS.idle2)
    setAnimId(animate.walk and animate.walk:FindFirstChild("WalkAnim"), HIT_HARDER_ANIMS.walk)
    setAnimId(animate.run and animate.run:FindFirstChild("RunAnim"), HIT_HARDER_ANIMS.run)
    setAnimId(animate.jump and animate.jump:FindFirstChild("JumpAnim"), HIT_HARDER_ANIMS.jump)
    setAnimId(animate.fall and animate.fall:FindFirstChild("FallAnim"), HIT_HARDER_ANIMS.fall)
    reloadAnimate(animate)
end
disableHitHarderAnim = function()
    hitHarderAnimEnabled = false
    resetAnimations()
    if selectedAnimationPack ~= "OFF" then
        task.wait()
        applyAnimationPack(selectedAnimationPack)
    end
end
local function startAntiRagdoll()
    if antiRagdollConn then
        return
    end
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not antiRagdollEnabled then
            return
        end
        local char = LP.Character
        if not char then
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not (hum and root) then
            return
        end
        local s = hum:GetState()
        local ragdolled = (
            s == Enum.HumanoidStateType.Physics
            or s == Enum.HumanoidStateType.Ragdoll
            or s == Enum.HumanoidStateType.FallingDown
        )
        local endTime = LP:GetAttribute("RagdollEndTime")
        if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then
            ragdolled = true
        end
        if ragdolled then
            if antiRagdollMode == "No Splatter" then
                local now = tick()
                if now - antiRagdollNoSplatterCooldown > 0.15 then
                    antiRagdollNoSplatterCooldown = now
                    pcall(function()
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                        root.Velocity = Vector3.zero
                        root.RotVelocity = Vector3.zero
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                        for _, obj in ipairs(char:GetDescendants()) do
                            if obj:IsA("Motor6D") then
                                obj.Enabled = true
                            end
                            if obj:IsA("Constraint") then
                                obj.Enabled = true
                            end
                        end
                        workspace.CurrentCamera.CameraSubject = hum
                        local PM = LP.PlayerScripts and LP.PlayerScripts:FindFirstChild("PlayerModule")
                        local controlModule = PM and PM:FindFirstChild("ControlModule")
                        if controlModule then
                            local ok, CM = pcall(require, controlModule)
                            if ok and CM and CM.Enable then
                                pcall(function()
                                    CM:Enable()
                                end)
                            end
                        end
                        hum.AutoRotate = true
                        hum.PlatformStand = false
                        hum.Sit = false
                    end)
                end
            else
                pcall(function()
                    LP:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow())
                end)
                for _, d in ipairs(char:GetDescendants()) do
                    if d:IsA("BallSocketConstraint") or (d:IsA("Attachment") and d.Name:find("RagdollAttachment")) then
                        pcall(function()
                            d:Destroy()
                        end)
                    end
                end
                for _, obj in ipairs(char:GetDescendants()) do
                    if obj:IsA("Motor6D") and obj.Enabled == false then
                        obj.Enabled = true
                    end
                end
                if hum.Health > 0 then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
                workspace.CurrentCamera.CameraSubject = hum
                root.Anchored = false
                applyImpulseZero(root)
            end
        end
    end)
end
local function stopAntiRagdoll()
    if antiRagdollConn then
        antiRagdollConn:Disconnect()
        antiRagdollConn = nil
    end
end
local function setAntiRagdoll(on)
    antiRagdollEnabled = on and true or false
    if antiRagdollEnabled then
        startAntiRagdoll()
    else
        stopAntiRagdoll()
    end
end
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if antiRagdollEnabled then
        setAntiRagdoll(true)
    end
end)
_G.PulseNormalInfJump = _G.PulseNormalInfJump
    or {
        holdPressed = false,
        holdActive = false,
        controllerActive = false,
        mobilePressed = false,
        mobileActive = false,
        hooked = {},
    }
if _G.PulseHoldInfJumpConn then
    pcall(function()
        _G.PulseHoldInfJumpConn:Disconnect()
    end)
    _G.PulseHoldInfJumpConn = nil
end
function _G.PulseStartHoldInfJump()
    if _G.PulseHoldInfJumpConn then
        _G.PulseHoldInfJumpConn:Disconnect()
    end
    _G.PulseHoldInfJumpConn = RunService.Heartbeat:Connect(function()
        if not infJumpEnabled then
            return
        end
        local char = LP.Character
        if not char then
            return
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then
            return
        end
        local isJumpHeld = UserInputService:IsKeyDown(Enum.KeyCode.Space) or (hum.Jump == true)
        if isJumpHeld and root.Velocity.Y < 35 then
            root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z)
        end
        if root.Velocity.Y < -120 then
            root.Velocity = Vector3.new(root.Velocity.X, -120, root.Velocity.Z)
        end
    end)
end
function _G.PulseStopHoldInfJump()
    if _G.PulseHoldInfJumpConn then
        _G.PulseHoldInfJumpConn:Disconnect()
        _G.PulseHoldInfJumpConn = nil
    end
end
function _G.PulseStopNormalInfJumpHoldState()
    _G.PulseNormalInfJump.holdPressed = false
    _G.PulseNormalInfJump.holdActive = false
    _G.PulseNormalInfJump.controllerActive = false
    _G.PulseNormalInfJump.mobilePressed = false
    _G.PulseNormalInfJump.mobileActive = false
end
setInfJumpInternal = function(on)
    infJumpEnabled = on and true or false
    if infJumpEnabled then
        _G.PulseStartHoldInfJump()
    else
        _G.PulseStopHoldInfJump()
        _G.PulseStopNormalInfJumpHoldState()
    end
end
local currentBackground = 0
local currentBackgroundColor = nil
local pulseGuiScaleValue = 0.52
local pulseProgressBarScaleValue = 0.83
CONFIG_FILE = "PulseHub_MainGUI_Config_DefaultsV2.json"
KEYBINDS_CONFIG_FILE = "PulseHub_Keybinds_DefaultsV2.json"
LEGACY_CONFIG_FILE = "BrokenHub_MainGUI_Config_DefaultsV2.json"
LEGACY_KEYBINDS_CONFIG_FILE = "BrokenHub_Keybinds_DefaultsV2.json"
_pulse_isfile = isfile
    or (syn and syn.isfile)
    or function(path)
        local ok, result = pcall(function()
            return readfile(path)
        end)
        return ok and result ~= nil
    end
_pulse_readfile = readfile or (syn and syn.readfile)
_pulse_writefile = writefile or (syn and syn.writefile)
canSaveConfig = (type(_pulse_readfile) == "function" and type(_pulse_writefile) == "function")
selectedIntroMusic = selectedIntroMusic or 1
_introEnabled = (_introEnabled ~= false)
setIntroVisual = nil
setIntroSongVisual = nil
INTRO_MUSIC_OPTIONS = {
    { name = "New Song", soundId = "rbxassetid://126107591945718", vol = 0.7, startAt = 34 },
    { name = "Song 1", url = "https://files.catbox.moe/bjh233.mp3", file = "Vex_Hub_Intro_Song1.mp3", startAt = 0, endAt = 7 },
    {
        name = "Song 2",
        url = "https://files.catbox.moe/tktp6l.mp3",
        file = "Vex_Hub_Intro_Song2.mp3",
        startAt = 10,
        fadeStart = 18,
        endAt = 19,
    },
    { name = "Song 3", url = "https://files.catbox.moe/jtwq3u.mp3", file = "Vex_Hub_Intro_Song3.mp3", startAt = 0 },
    { name = "Song 4", url = "https://files.catbox.moe/5g90vw.mp3", file = "Vex_Hub_Intro_Song4.mp3", startAt = 0 },
    { name = "Song 5", url = "https://files.catbox.moe/mzvrir.mp3", file = "PulseHubIntroSong_1.mp3" },
    { name = "Song 6", url = "https://files.catbox.moe/2a7jyx.mp3", file = "PulseHubIntroSong_2.mp3" },
    { name = "Song 7", url = "https://files.catbox.moe/rcgr9f.mp3", file = "PulseHubIntroSong_3.mp3" },
    { name = "Song 8", url = "https://files.catbox.moe/iknfuh.mp3", file = "PulseHubIntroSong_4.mp3" },
    { name = "Song 9", url = "https://files.catbox.moe/6eigoh.mp3", file = "PulseHubIntroSong_5.mp3" },
    { name = "Song 10", url = "https://files.catbox.moe/dvjtjk.mp3", file = "PulseHubIntroSong_6.mp3" },
    { name = "Song 11", url = "https://files.catbox.moe/iyw1cb.mp3", file = "PulseHubIntroSong_7.mp3" },
}
function getIntroSongName()
    local opt = INTRO_MUSIC_OPTIONS[selectedIntroMusic]
    return opt and opt.name or "No Songs Added"
end
introPreviewSound = nil
introPlaybackSound = nil
introPreviewToken = 0
introPlaybackToken = 0
introSongCache = introSongCache or {}
introSongDownloading = introSongDownloading or {}
function stopIntroPreview()
    introPreviewToken = introPreviewToken + 1
    if introPreviewSound then
        pcall(function()
            introPreviewSound:Stop()
        end)
        pcall(function()
            introPreviewSound:Destroy()
        end)
        introPreviewSound = nil
    end
end
function stopIntroPlayback()
    introPlaybackToken = introPlaybackToken + 1
    if introPlaybackSound then
        pcall(function()
            introPlaybackSound:Stop()
        end)
        pcall(function()
            introPlaybackSound:Destroy()
        end)
        introPlaybackSound = nil
    end
end
function _safeNotify(msg)
    if showActionNotification then
        pcall(function()
            showActionNotification(msg)
        end)
    end
end
local _pulse_getasset = getcustomasset or getsynasset or get_custom_asset or (syn and syn.getcustomasset)
function cacheIntroSong(option, allowDownload)
    if not option then
        return nil
    end
    if option.soundId and option.soundId ~= "" then
        return option.soundId
    end
    if not option.url or option.url == "" then
        return nil
    end
    if not (writefile and _pulse_getasset) then
        return nil
    end
    local fileName = option.file or ("PulseHubIntroSong_" .. tostring(option.name or "song") .. ".mp3")
    local function loadExisting()
        if introSongCache[fileName] then
            return introSongCache[fileName]
        end
        local hasFile = false
        pcall(function()
            hasFile = isfile and isfile(fileName)
        end)
        if hasFile then
            local ok = pcall(function()
                introSongCache[fileName] = _pulse_getasset(fileName)
            end)
            if ok and introSongCache[fileName] then
                return introSongCache[fileName]
            end
        end
        return nil
    end
    local cached = loadExisting()
    if cached then
        return cached
    end
    if allowDownload == false then
        return nil
    end
    if introSongDownloading[fileName] then
        local waitStart = tick()
        while introSongDownloading[fileName] and tick() - waitStart < 12 do
            task.wait(0.05)
        end
        cached = loadExisting()
        if cached then
            return cached
        end
    end
    introSongDownloading[fileName] = true
    local ok = pcall(function()
        local data = game:HttpGet(option.url)
        if data and #data > 0 then
            writefile(fileName, data)
            introSongCache[fileName] = _pulse_getasset(fileName)
        end
    end)
    introSongDownloading[fileName] = nil
    if ok and introSongCache[fileName] then
        return introSongCache[fileName]
    end
    return loadExisting()
end
function preloadIntroSongs()
    if not _introEnabled then
        return
    end
    task.spawn(function()
        cacheIntroSong(INTRO_MUSIC_OPTIONS[selectedIntroMusic], true)
    end)
end
function makeIntroSoundFromId(soundId, name, parent)
    if not soundId or soundId == "" then
        return nil
    end
    local sound = Instance.new("Sound")
    sound.Name = name or "PulseHubIntroMusic"
    sound.Volume = 2.0
    sound.PlaybackSpeed = 1.0
    sound.Looped = false
    sound.RollOffMaxDistance = 100000000
    sound.SoundId = soundId
    sound.Parent = parent or SoundService
    pcall(function()
        game:GetService("ContentProvider"):PreloadAsync({ sound })
    end)
    return sound
end
function createIntroSound(option, fileName, parent, allowDownload)
    if not option then
        return nil
    end
    local soundId = cacheIntroSong(option, allowDownload)
    if not soundId then
        return nil
    end
    return makeIntroSoundFromId(soundId, fileName, parent)
end
function previewIntroMusic(index)
    stopIntroPreview()
    stopIntroPlayback()
    if not INTRO_MUSIC_OPTIONS[index] then
        _safeNotify("ADD SONG LINKS")
        return
    end
    local token = introPreviewToken
    task.spawn(function()
        local option = INTRO_MUSIC_OPTIONS[index]
        local sound = createIntroSound(option, "PulseHubIntroPreview_" .. tostring(token), SoundService, true)
        if token ~= introPreviewToken then
            if sound then
                pcall(function()
                    sound:Destroy()
                end)
            end
            return
        end
        introPreviewSound = sound
        if not sound then
            _safeNotify("SONG LOADING...")
            return
        end
        sound.Volume = option.vol or 2.0
        sound.TimePosition = option.startAt or 0
        local loadStart = tick()
        while sound and not sound.IsLoaded and tick() - loadStart < 6 do
            task.wait(0.05)
        end
        if token ~= introPreviewToken or not sound then
            return
        end
        pcall(function()
            sound:Play()
        end)
        if option.fadeStart or option.endAt then
            local baseVol = sound.Volume
            task.spawn(function()
                local startWait = tick()
                while sound and sound.Parent and not sound.IsPlaying and tick() - startWait < 4 do
                    task.wait(0.05)
                end
                if not sound or not sound.Parent or not sound.IsPlaying then
                    return
                end
                while sound and sound.Parent and sound.IsPlaying and token == introPreviewToken do
                    if option.fadeStart and sound.TimePosition >= option.fadeStart then
                        local fadeProgress = math.clamp(
                            (sound.TimePosition - option.fadeStart)
                                / ((option.endAt or (option.fadeStart + 2)) - option.fadeStart),
                            0,
                            1
                        )
                        sound.Volume = baseVol * (1 - fadeProgress)
                    end
                    if option.endAt and sound.TimePosition >= option.endAt then
                        pcall(function()
                            sound:Stop()
                        end)
                        break
                    end
                    task.wait(0.05)
                end
            end)
        end
        task.delay(18, function()
            if token == introPreviewToken then
                stopIntroPreview()
            end
        end)
    end)
end
function playIntroMusic()
    stopIntroPreview()
    stopIntroPlayback()
    if not _introEnabled then
        return
    end
    local option = INTRO_MUSIC_OPTIONS[selectedIntroMusic]
    if not option then
        return
    end
    local token = introPlaybackToken
    task.spawn(function()
        local sound = createIntroSound(option, "PulseHubIntroMusic_" .. tostring(token), SoundService, true)
        if token ~= introPlaybackToken or not _introEnabled then
            if sound then
                pcall(function()
                    sound:Destroy()
                end)
            end
            return
        end
        introPlaybackSound = sound
        if not sound then
            _safeNotify("SONG FAILED")
            return
        end
        sound.Volume = option.vol or 2.0
        sound.TimePosition = option.startAt or 0
        local loadStart = tick()
        while sound and not sound.IsLoaded and tick() - loadStart < 8 do
            task.wait(0.05)
        end
        if token ~= introPlaybackToken or not _introEnabled or not sound then
            return
        end
        pcall(function()
            sound:Play()
        end)
        if option.fadeStart or option.endAt then
            local baseVol = sound.Volume
            task.spawn(function()
                local startWait = tick()
                while sound and sound.Parent and not sound.IsPlaying and tick() - startWait < 4 do
                    task.wait(0.05)
                end
                if not sound or not sound.Parent or not sound.IsPlaying then
                    return
                end
                while sound and sound.Parent and sound.IsPlaying and token == introPlaybackToken do
                    if option.fadeStart and sound.TimePosition >= option.fadeStart then
                        local fadeProgress = math.clamp(
                            (sound.TimePosition - option.fadeStart)
                                / ((option.endAt or (option.fadeStart + 2)) - option.fadeStart),
                            0,
                            1
                        )
                        sound.Volume = baseVol * (1 - fadeProgress)
                    end
                    if option.endAt and sound.TimePosition >= option.endAt then
                        pcall(function()
                            sound:Stop()
                        end)
                        break
                    end
                    task.wait(0.05)
                end
            end)
        end
        task.delay(18, function()
            if token == introPlaybackToken then
                stopIntroPlayback()
            end
        end)
    end)
end
savedConfig = {}
local pulseStartupBuilding = true
local pulseStartupSavePending = false
_G.PulseGuiLocked = _G.PulseGuiLocked == true
_G.PulseDragMobileButtons = _G.PulseDragMobileButtons == true
_G.PulseHideMobileButtons = _G.PulseHideMobileButtons == true
_G.PulseMobileButtonScale = 0.75
_G.PulseMobileButtonPositions = _G.PulseMobileButtonPositions or {}
_G.PulseMobileButtonDefinitions = {
    { id = "drop", label = "Drop Item", text = "DROP\nITEM", toggle = false },
    { id = "autoLeft", label = "Auto Left", text = "AUTO\nLEFT", toggle = true },
    { id = "aimbot", label = "Bat Lock", text = "BAT\nLOCK", toggle = true },
    { id = "autoRight", label = "Auto Right", text = "AUTO\nRIGHT", toggle = true },
    { id = "tp", label = "TP Down", text = "TP\nDOWN", toggle = false },
    { id = "carry", label = "Carry Speed", text = "CARRY\nSPEED", toggle = true },
    { id = "laggerNormal", label = "Lagger Normal", text = "LAGGER\nNORMAL", toggle = true },
    { id = "insta", label = "Insta Reset", text = "INSTA\nRESET", toggle = false },
    { id = "laggerCarry", label = "Lagger Carry", text = "LAGGER\nCARRY", toggle = true },
    { id = "antiDesync", label = "TP Bat", text = "TP\nBAT", toggle = true },
    { id = "lagger2Normal", label = "Lagger 2", text = "LAGGER 2\nNORMAL", toggle = true },
    { id = "lagger2Carry", label = "Lagger Carry 2", text = "LAGGER 2\nCARRY", toggle = true },
}
function _G.PulseCopyDefaultMobileButtonOrder()
    local out = {}
    for _, definition in ipairs(_G.PulseMobileButtonDefinitions) do
        out[#out + 1] = definition.id
    end
    return out
end
function _G.PulseSanitizeMobileButtonOrder(order)
    local allowed, seen, out = {}, {}, {}
    for _, definition in ipairs(_G.PulseMobileButtonDefinitions) do
        allowed[definition.id] = true
    end
    if type(order) == "table" then
        for _, id in ipairs(order) do
            if type(id) == "string" and allowed[id] and not seen[id] then
                seen[id] = true
                out[#out + 1] = id
            end
        end
    end
    for _, definition in ipairs(_G.PulseMobileButtonDefinitions) do
        if not seen[definition.id] then
            out[#out + 1] = definition.id
        end
    end
    return out
end
function _G.PulseSanitizeMobileButtonHidden(hidden)
    local out = {}
    if type(hidden) == "table" then
        for _, definition in ipairs(_G.PulseMobileButtonDefinitions) do
            if hidden[definition.id] == true then
                out[definition.id] = true
            end
        end
    end
    return out
end
function _G.PulseDefaultMobileButtonColors()
    return {
        activeBackground = "AUTO",
        inactiveBackground = "#000000",
        activeText = "#000000",
        inactiveText = "#FFFFFF",
    }
end
function _G.PulseNormalizeMobileButtonColor(value, fallback, allowAuto)
    local text = string.upper(tostring(value or "")):gsub("%s+", "")
    if allowAuto and text == "AUTO" then
        return "AUTO"
    end
    text = text:gsub("#", "")
    if #text == 6 and text:match("^[0-9A-F]+$") then
        return "#" .. text
    end
    return fallback
end
_G.PulseMobileButtonOrder = _G.PulseCopyDefaultMobileButtonOrder()
_G.PulseMobileButtonHidden = {}
_G.PulseMobileButtonColors = _G.PulseDefaultMobileButtonColors()
savedMainPositionTable = nil
savedMiniPositionTable = nil
savedMobPanelPositionTable = nil
savedSpeedCustomizerPositionTable = nil
savedStealBarPositionTable = nil
function udim2ToTable(u)
    return { xs = u.X.Scale, xo = u.X.Offset, ys = u.Y.Scale, yo = u.Y.Offset }
end
function tableToUDim2(t, fallback)
    if type(t) == "table" then
        return UDim2.new(tonumber(t.xs) or 0, tonumber(t.xo) or 0, tonumber(t.ys) or 0, tonumber(t.yo) or 0)
    end
    return fallback
end
function collectPulseMobileButtonPositions()
    local out = {}
    for key, entry in pairs(_G.PulseMobileButtonRefs or {}) do
        local holder = entry and (entry.holder or entry.btn)
        if holder then
            out[key] = udim2ToTable(holder.Position)
        end
    end
    if next(out) == nil and type(_G.PulseMobileButtonPositions) == "table" then
        return _G.PulseMobileButtonPositions
    end
    _G.PulseMobileButtonPositions = out
    return out
end
function keyToString(key)
    if not key then
        return "None"
    end
    return tostring(key):gsub("Enum.KeyCode.", "")
end
function stringToKeyCode(value)
    if type(value) ~= "string" or value == "" or value == "None" then
        return nil
    end
    return Enum.KeyCode[value]
end
function keybindsToTable()
    local out = {}
    for keyId in pairs(DEFAULT_SPEED_KEYBINDS) do
        out[keyId] = keyToString(speedKeybinds[keyId])
    end
    for keyId, key in pairs(speedKeybinds) do
        out[keyId] = keyToString(key)
    end
    return out
end
function collectPulseKeybindConfig()
    return { keybinds = keybindsToTable(), tpDownKeybind = keyToString(tpDownKeybind) }
end
function applySavedKeybinds(t)
    if type(t) ~= "table" then
        return
    end
    for keyId in pairs(speedKeybinds) do
        if t[keyId] ~= nil then
            speedKeybinds[keyId] = stringToKeyCode(t[keyId])
        end
    end
end
function applyDefaultPulseKeybinds()
    for keyId, key in pairs(DEFAULT_SPEED_KEYBINDS) do
        speedKeybinds[keyId] = key
    end
    tpDownKeybind = DEFAULT_TP_DOWN_KEYBIND
end
function collectPulseConfig()
    return {
        mainPosition = savedMainPositionTable,
        miniPosition = savedMiniPositionTable,
        mobilePanelPosition = savedMobPanelPositionTable,
        speedCustomizerPosition = savedSpeedCustomizerPositionTable,
        stealBarPosition = savedStealBarPositionTable,
        keybinds = keybindsToTable(),
        tpDownKeybind = keyToString(tpDownKeybind),
        NS = NS,
        CS = CS,
        LAGGER_SPEED = LAGGER_SPEED,
        LAGGER_CARRY_SPEED = LAGGER_CARRY_SPEED,
        LAGGER2_SPEED = LAGGER2_SPEED,
        LAGGER2_CARRY_SPEED = LAGGER2_CARRY_SPEED,
        currentSpeedMode = currentSpeedMode,
        autoCarrySpeedEnabled = autoCarrySpeedEnabled == true,
        autoSwitchDistance = _G.PulseAutoSwitchDistance or 5,
        autoTPEnabled = autoTPEnabled,
        autoTPHeight = autoTPHeight,
        infJumpEnabled = infJumpEnabled,
        antiRagdollEnabled = antiRagdollEnabled == true,
        tpDownOnRagdollEnabled = _G.PulseTpDownOnRagdollOn == true,
        autoRagdollTpEnabled = _G.PulseAutoRagdollTpState.enabled == true,
        antiRagdollMode = antiRagdollMode,
        mobileButtonStyle = mobileButtonStyle,
        selectedAnimationPack = selectedAnimationPack,
        selectedStealMode = selectedStealMode,
        normalRagdollStealEnabled = _G.PulseNormalRagdollStealEnabled == true,
        semiRagdollStealEnabled = _G.PulseSemiRagdollStealEnabled == true,
        autoStealEnabled = (
            autoStealEnabled == true
            or (
                _G.PulseNormalAutoStealRagdollPause
                and _G.PulseNormalAutoStealRagdollPause.active == true
                and _G.PulseNormalAutoStealRagdollPause.resumeWanted == true
            )
        ) == true,
        softStealEnabled = softStealEnabled == true,
        autoStealRadius = autoStealRadius,
        pulseStealRadii = _G.PulseStealRadii,
        selectedAimbotMode = selectedAimbotMode,
        AIMBOT_SPEED = AIMBOT_SPEED,
        LAGGER_AIMBOT_SPEED = LAGGER_AIMBOT_SPEED,
        ANTI_BYPASS_AIMBOT_SPEED = _G.PulseAntiBypassAimbotSpeed,
        ANTI_BYPASS_LAGGER_AIMBOT_SPEED = _G.PulseAntiBypassLaggerAimbotSpeed,
        ANTI_DESYNC_AIMBOT_SPEED = ANTI_DESYNC_AIMBOT_SPEED,
        autoSwingEnabled = autoSwingEnabled,
        normalAimbotEnabled = _G.PulseNormalAimbotOn == true,
        antiBypassAimbotEnabled = _G.PulseAntiBypassAimbotOn == true,
        antiDesyncAutoSwingEnabled = antiDesyncAutoSwingEnabled,
        antiDesyncAimbotEnabled = _G.PulseAntiDesyncAimbotOn == true,
        batCounterEnabled = batCounterEnabled,
        medCounterEnabled = medCounterEnabled,
        espEnabled = espEnabled,
        showTracerEnabled = showTracerEnabled,
        ragdollCountdownEnabled = ragdollCountdownEnabled,
        fpsBoostEnabled = fpsBoostEnabled,
        antiLagVisualEnabled = antiLagVisualEnabled,
        fovEnabled = fovEnabled,
        fovValue = fovValue,
        noCamCollisionEnabled = noCamCollisionEnabled,
        noPlayerCollisionEnabled = _G.PulseNoPlayerCollisionEnabled,
        customFontVisualEnabled = false,
        skyTheme = skyTheme,
        autoLeftEnabled = autoLeftEnabled,
        autoRightEnabled = autoRightEnabled,
        currentBackground = currentBackground,
        currentBackgroundColor = (typeof(currentBackgroundColor) == "Color3")
                and { R = currentBackgroundColor.R, G = currentBackgroundColor.G, B = currentBackgroundColor.B }
            or (type(currentBackgroundColor) == "table" and currentBackgroundColor)
            or nil,
        laggerCycleOrder = _G.PulseLaggerCycleOrder,
        pulseGuiScaleValue = pulseGuiScaleValue,
        pulseProgressBarScaleValue = pulseProgressBarScaleValue,
        introEnabled = _introEnabled == true,
        selectedIntroMusic = selectedIntroMusic,
        guiLocked = _G.PulseGuiLocked == true,
        hideMobileButtons = _G.PulseHideMobileButtons == true,
        dragMobileButtons = _G.PulseDragMobileButtons == true,
        speedCustomizerEnabled = _G.PulseSpeedCustomizerOn ~= false,
        pulseMobileButtonScale = _G.PulseMobileButtonScale,
        mobileButtonPositions = collectPulseMobileButtonPositions(),
        mobileButtonOrder = _G.PulseMobileButtonOrder,
        mobileButtonHidden = _G.PulseMobileButtonHidden,
        mobileButtonColors = _G.PulseMobileButtonColors,
    }
end
local pulseConfigSaveQueued = false
function savePulseConfig()
    if pulseStartupBuilding then
        pulseStartupSavePending = true
        return
    end
    if not canSaveConfig or pulseConfigSaveQueued then
        return
    end
    pulseConfigSaveQueued = true
    task.delay(0.15, function()
        pulseConfigSaveQueued = false
        if not canSaveConfig then
            return
        end
        pcall(function()
            _pulse_writefile(CONFIG_FILE, HttpService:JSONEncode(collectPulseConfig()))
            _pulse_writefile(KEYBINDS_CONFIG_FILE, HttpService:JSONEncode(collectPulseKeybindConfig()))
        end)
    end)
end
function loadPulseConfig()
    local activeConfigFile = CONFIG_FILE
    if not _pulse_isfile(activeConfigFile) and _pulse_isfile(LEGACY_CONFIG_FILE) then
        activeConfigFile = LEGACY_CONFIG_FILE
    end
    if not canSaveConfig or not _pulse_isfile(activeConfigFile) then
        return
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(_pulse_readfile(activeConfigFile))
    end)
    if not ok or type(data) ~= "table" then
        return
    end
    savedConfig = data
    local keybindData = data
    pcall(function()
        local activeKeybindsFile = KEYBINDS_CONFIG_FILE
        if not _pulse_isfile(activeKeybindsFile) and _pulse_isfile(LEGACY_KEYBINDS_CONFIG_FILE) then
            activeKeybindsFile = LEGACY_KEYBINDS_CONFIG_FILE
        end
        if _pulse_isfile(activeKeybindsFile) then
            local kb = HttpService:JSONDecode(_pulse_readfile(activeKeybindsFile))
            if type(kb) == "table" then
                keybindData = kb
            end
        end
    end)
    savedMainPositionTable = data.mainPosition
    savedMiniPositionTable = type(data.miniPosition) == "table" and data.miniPosition or nil
    savedMobPanelPositionTable = type(data.mobilePanelPosition) == "table" and data.mobilePanelPosition
        or savedMobPanelPositionTable
    savedSpeedCustomizerPositionTable = type(data.speedCustomizerPosition) == "table" and data.speedCustomizerPosition
        or nil
    savedStealBarPositionTable = type(data.stealBarPosition) == "table" and data.stealBarPosition or nil
    if
        savedMobPanelPositionTable
        and tonumber(savedMobPanelPositionTable.xs) == 0
        and tonumber(savedMobPanelPositionTable.xo) == 20
        and tonumber(savedMobPanelPositionTable.ys) == 0
        and tonumber(savedMobPanelPositionTable.yo) == 20
    then
        savedMobPanelPositionTable = nil
    end
    _G.PulseGuiLocked = data.guiLocked == true
    _G.PulseDragMobileButtons = data.dragMobileButtons == true
    _G.PulseSpeedCustomizerOn = (data.speedCustomizerEnabled ~= false)
    if _G.PulseGuiLocked == true and _G.PulseDragMobileButtons == true then
        _G.PulseDragMobileButtons = false
    end
    _G.PulseHideMobileButtons = data.hideMobileButtons == true
    _G.PulseMobileButtonScale =
        math.clamp(tonumber(data.pulseMobileButtonScale) or tonumber(_G.PulseMobileButtonScale) or 0.75, 0.30, 1.35)
    _G.PulseMobileButtonPositions = type(data.mobileButtonPositions) == "table" and data.mobileButtonPositions or {}
    _G.PulseMobileButtonOrder = _G.PulseSanitizeMobileButtonOrder(data.mobileButtonOrder)
    _G.PulseMobileButtonHidden = _G.PulseSanitizeMobileButtonHidden(data.mobileButtonHidden)
    do
        local defaults = _G.PulseDefaultMobileButtonColors()
        local colors = type(data.mobileButtonColors) == "table" and data.mobileButtonColors or {}
        _G.PulseMobileButtonColors = {
            activeBackground = _G.PulseNormalizeMobileButtonColor(
                colors.activeBackground,
                defaults.activeBackground,
                true
            ),
            inactiveBackground = _G.PulseNormalizeMobileButtonColor(
                colors.inactiveBackground,
                defaults.inactiveBackground,
                false
            ),
            activeText = _G.PulseNormalizeMobileButtonColor(colors.activeText, defaults.activeText, false),
            inactiveText = _G.PulseNormalizeMobileButtonColor(colors.inactiveText, defaults.inactiveText, false),
        }
    end
    applySavedKeybinds(keybindData.keybinds)
    if keybindData.tpDownKeybind ~= nil then
        if tostring(keybindData.tpDownKeybind) == "None" then
            tpDownKeybind = nil
        else
            tpDownKeybind = stringToKeyCode(keybindData.tpDownKeybind) or DEFAULT_TP_DOWN_KEYBIND
        end
    end
    for keyId, defaultKey in pairs(DEFAULT_SPEED_KEYBINDS) do
        local savedKeys = keybindData and keybindData.keybinds
        if (not savedKeys or savedKeys[keyId] == nil) and speedKeybinds[keyId] == nil then
            speedKeybinds[keyId] = defaultKey
        end
    end
    NS = tonumber(data.NS) or NS
    CS = tonumber(data.CS) or CS
    LAGGER_SPEED = tonumber(data.LAGGER_SPEED) or LAGGER_SPEED
    LAGGER_CARRY_SPEED = tonumber(data.LAGGER_CARRY_SPEED) or LAGGER_CARRY_SPEED
    LAGGER2_SPEED = tonumber(data.LAGGER2_SPEED) or LAGGER2_SPEED
    LAGGER2_CARRY_SPEED = tonumber(data.LAGGER2_CARRY_SPEED) or LAGGER2_CARRY_SPEED
    currentSpeedMode = data.currentSpeedMode or currentSpeedMode
    if type(data.laggerCycleOrder) == "table" then
        do
            local allowed =
                { ["Lagger Carry"] = true, ["Lagger Carry 2"] = true, ["Lagger"] = true, ["Lagger 2"] = true }
            local seen, out = {}, {}
            for _, m in ipairs(data.laggerCycleOrder) do
                if allowed[m] and not seen[m] then
                    seen[m] = true
                    table.insert(out, m)
                end
            end
            for _, m in ipairs({ "Lagger Carry", "Lagger Carry 2", "Lagger", "Lagger 2" }) do
                if not seen[m] then
                    table.insert(out, m)
                end
            end
            if #out == 4 then
                _G.PulseLaggerCycleOrder = out
            end
        end
    end
    if
        currentSpeedMode ~= "Normal"
        and currentSpeedMode ~= "Carry"
        and currentSpeedMode ~= "Lagger"
        and currentSpeedMode ~= "Lagger Carry"
        and currentSpeedMode ~= "Lagger 2"
        and currentSpeedMode ~= "Lagger Carry 2"
    then
        currentSpeedMode = "Normal"
    end
    autoCarrySpeedEnabled = data.autoCarrySpeedEnabled == true
    _G.PulseAutoSwitchDistance = tonumber(data.autoSwitchDistance) or 5
    autoTPEnabled = data.autoTPEnabled == true
    autoTPHeight = tonumber(data.autoTPHeight) or autoTPHeight
    infJumpEnabled = data.infJumpEnabled == true
    antiRagdollEnabled = data.antiRagdollEnabled == true
    _G.PulseTpDownOnRagdollOn = data.tpDownOnRagdollEnabled == true
    _G.PulseAutoRagdollTpState.enabled = data.autoRagdollTpEnabled == true
    antiRagdollMode = (data.antiRagdollMode == "No Splatter") and "No Splatter" or "Splatter"
    mobileButtonStyle = (data.mobileButtonStyle == "Button 1") and "Button 1" or "Button 2"
    selectedAnimationPack = data.selectedAnimationPack or selectedAnimationPack
    selectedStealMode = data.selectedStealMode or selectedStealMode
    if selectedStealMode ~= "Semi" and selectedStealMode ~= "Normal V2" then
        selectedStealMode = "Normal"
    end
    _G.PulseNormalRagdollStealEnabled = data.normalRagdollStealEnabled == true
    _G.PulseSemiRagdollStealEnabled = data.semiRagdollStealEnabled == true
    autoStealEnabled = data.autoStealEnabled == true
    softStealEnabled = data.softStealEnabled == true
    _G.PulseSoftStealEnabled = softStealEnabled
    if type(data.pulseStealRadii) == "table" then
        _G.PulseStealRadii.Normal = tonumber(data.pulseStealRadii.Normal) or _G.PulseStealRadii.Normal or 62
        _G.PulseStealRadii.Semi = tonumber(data.pulseStealRadii.Semi) or _G.PulseStealRadii.Semi or 9
        _G.PulseStealRadii["Normal V2"] = tonumber(data.pulseStealRadii["Normal V2"])
            or _G.PulseStealRadii["Normal V2"]
            or 62
    end
    autoStealRadius = tonumber(data.autoStealRadius) or autoStealRadius
    if selectedStealMode == "Normal" then
        _G.PulseStealRadii.Normal = tonumber(autoStealRadius) or _G.PulseStealRadii.Normal or 62
        autoStealRadius = _G.PulseStealRadii.Normal
    elseif selectedStealMode == "Normal V2" then
        autoStealRadius = _G.PulseStealRadii["Normal V2"] or 62
    else
        autoStealRadius = _G.PulseStealRadii.Semi or 9
    end
    selectedAimbotMode = "Anti Bypass"
    AIMBOT_SPEED = tonumber(data.AIMBOT_SPEED) or AIMBOT_SPEED
    LAGGER_AIMBOT_SPEED = tonumber(data.LAGGER_AIMBOT_SPEED) or LAGGER_AIMBOT_SPEED
    _G.PulseAntiBypassAimbotSpeed = tonumber(data.ANTI_BYPASS_AIMBOT_SPEED) or _G.PulseAntiBypassAimbotSpeed or 58
    if data.ANTI_BYPASS_LAGGER_AIMBOT_SPEED == nil or tonumber(data.ANTI_BYPASS_LAGGER_AIMBOT_SPEED) == 58 then
        _G.PulseAntiBypassLaggerAimbotSpeed = 40
    else
        _G.PulseAntiBypassLaggerAimbotSpeed = tonumber(data.ANTI_BYPASS_LAGGER_AIMBOT_SPEED) or 40
    end
    ANTI_DESYNC_AIMBOT_SPEED = tonumber(data.ANTI_DESYNC_AIMBOT_SPEED) or ANTI_DESYNC_AIMBOT_SPEED or 58
    autoSwingEnabled = data.autoSwingEnabled == true
    _G.PulseNormalAimbotOn = false
    _G.PulseAntiBypassAimbotOn = data.antiBypassAimbotEnabled == true
    antiDesyncAutoSwingEnabled = data.antiDesyncAutoSwingEnabled == true
    _G.PulseAntiDesyncAimbotOn = data.antiDesyncAimbotEnabled == true
    batCounterEnabled = data.batCounterEnabled == true
    medCounterEnabled = data.medCounterEnabled == true
    espEnabled = data.espEnabled == true
    showTracerEnabled = data.showTracerEnabled == true
    ragdollCountdownEnabled = data.ragdollCountdownEnabled == true
    fpsBoostEnabled = data.fpsBoostEnabled == true
    antiLagVisualEnabled = data.antiLagVisualEnabled == true
    fovEnabled = data.fovEnabled == true
    fovValue = tonumber(data.fovValue) or fovValue
    noCamCollisionEnabled = data.noCamCollisionEnabled == true
    _G.PulseNoPlayerCollisionEnabled = data.noPlayerCollisionEnabled == true
    customFontVisualEnabled = false
    skyTheme = (type(data.skyTheme) == "string" and data.skyTheme) or skyTheme
    do
        local savedColor = data.currentBackgroundColor
        if type(savedColor) == "table" and savedColor.R ~= nil and savedColor.G ~= nil and savedColor.B ~= nil then
            currentBackgroundColor =
                Color3.new(tonumber(savedColor.R) or 1, tonumber(savedColor.G) or 1, tonumber(savedColor.B) or 1)
        elseif typeof(savedColor) == "Color3" then
            currentBackgroundColor = savedColor
        else
            currentBackgroundColor = nil
        end
    end
    autoLeftEnabled = data.autoLeftEnabled == true
    autoRightEnabled = data.autoRightEnabled == true
    if data.introEnabled ~= nil then
        _introEnabled = data.introEnabled == true
    end
    if data.selectedIntroMusic and INTRO_MUSIC_OPTIONS[data.selectedIntroMusic] then
        selectedIntroMusic = data.selectedIntroMusic
    end
    if autoLeftEnabled and autoRightEnabled then
        autoRightEnabled = false
    end
end
loadPulseConfig()
local function createPulseIntroBootstrap()
    local oldBootstrap = PlayerGui:FindFirstChild("PulseHubIntroBootstrap")
        or PlayerGui:FindFirstChild("BrokenHubIntroBootstrap")
    if oldBootstrap then
        oldBootstrap:Destroy()
    end
    local oldIntro = PlayerGui:FindFirstChild("PulseHubIntro") or PlayerGui:FindFirstChild("BrokenHubIntro")
    if oldIntro then
        oldIntro:Destroy()
    end
    _G.PulseIntroInProgress = (_introEnabled == true)
    _G.PulseIntroFinished = not _G.PulseIntroInProgress
    if not _G.PulseIntroInProgress then
        return
    end
    for _, name in ipairs({
        "PulseHubMobileButtons",
        "BrokenHubMobileButtons",
        "MoveeMobileButtons",
        "PulseMobileButtons",
    }) do
        local oldMobile = PlayerGui:FindFirstChild(name)
        if oldMobile and oldMobile:IsA("ScreenGui") then
            oldMobile.Enabled = false
        end
    end
    pcall(function()
        local coreGui = game:GetService("CoreGui")
        for _, name in ipairs({
            "PulseHubMobileButtons",
            "BrokenHubMobileButtons",
            "MoveeMobileButtons",
            "PulseMobileButtons",
        }) do
            local oldMobile = coreGui:FindFirstChild(name)
            if oldMobile and oldMobile:IsA("ScreenGui") then
                oldMobile.Enabled = false
            end
        end
    end)
    local bootstrapGui = Instance.new("ScreenGui")
    bootstrapGui.Name = "PulseHubIntroBootstrap"
    bootstrapGui.IgnoreGuiInset = true
    bootstrapGui.ResetOnSpawn = false
    bootstrapGui.DisplayOrder = 100
    bootstrapGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(bootstrapGui)
        end
    end)
    bootstrapGui.Parent = PlayerGui
    _G.PulseIntroBootstrapGui = bootstrapGui
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Intro"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
    backdrop.BackgroundTransparency = 0.5
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 1000
    backdrop.Parent = bootstrapGui
    local art = Instance.new("ImageLabel")
    art.Name = "IntroBackdropImage"
    art.AnchorPoint = Vector2.new(0.5, 0.5)
    art.Position = UDim2.new(0.5, 0, 0.42, 0)
    art.Size = UDim2.new(0.92, 0, 0.5, 0)
    art.BackgroundTransparency = 1
    art.Image = "rbxassetid://98541566010518"
    art.ImageTransparency = 0.58
    art.ScaleType = Enum.ScaleType.Fit
    art.ZIndex = 1000
    art.Parent = backdrop
    local title = Instance.new("TextLabel")
    title.Name = "IntroBanner"
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Position = UDim2.new(0.5, 0, 0.42, 0)
    title.Size = UDim2.new(0.5, 0, 0, 78)
    title.BackgroundTransparency = 1
    title.Text = "PULSE"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 42
    title.Font = Enum.Font.GothamBlack
    title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    title.TextStrokeTransparency = 0.55
    title.ZIndex = 1002
    title.Parent = backdrop
    local titleScale = Instance.new("UIScale")
    titleScale.Scale = 0.96
    titleScale.Parent = title
    local invite = Instance.new("TextLabel")
    invite.Name = "DiscordInvite"
    invite.AnchorPoint = Vector2.new(0.5, 0.5)
    invite.Position = UDim2.new(0.5, 0, 0.42, 72)
    invite.Size = UDim2.new(0.7, 0, 0, 18)
    invite.BackgroundTransparency = 1
    invite.Text = "discord.gg/pulsee"
    invite.TextColor3 = Color3.fromRGB(255, 255, 255)
    invite.TextSize = 10
    invite.Font = Enum.Font.GothamBlack
    invite.ZIndex = 1003
    invite.Parent = backdrop
    task.spawn(function()
        while bootstrapGui.Parent and _G.PulseIntroInProgress do
            local up = TweenService:Create(
                titleScale,
                TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Scale = 1.02 }
            )
            up:Play()
            up.Completed:Wait()
            if not bootstrapGui.Parent then
                break
            end
            local down = TweenService:Create(
                titleScale,
                TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Scale = 0.96 }
            )
            down:Play()
            down.Completed:Wait()
        end
    end)
end
createPulseIntroBootstrap()
if _introEnabled then
    task.wait()
end
preloadIntroSongs()
local function syncAnimationPackIndex()
    for i, name in ipairs(AnimationPackList) do
        if name == selectedAnimationPack then
            AnimationPackIndex = i
            return
        end
    end
    selectedAnimationPack = "OFF"
    AnimationPackIndex = 1
end
local function applySavedAnimationPackToCharacter(char)
    syncAnimationPackIndex()
    if refreshAnimationPackRow then
        pcall(refreshAnimationPackRow)
    end
    if not char then
        char = LP.Character
    end
    if not char then
        return
    end
    local animate = char:FindFirstChild("Animate") or char:WaitForChild("Animate", 6)
    if not animate then
        return
    end
    task.wait(0.2)
    OriginalAnims = {}
    unwalkSavedAnimate = nil
    if selectedAnimationPack and selectedAnimationPack ~= "OFF" then
        pcall(function()
            applyAnimationPack(selectedAnimationPack)
        end)
    else
        pcall(function()
            resetAnimations()
        end)
    end
end
syncAnimationPackIndex()
task.defer(function()
    applySavedAnimationPackToCharacter(LP.Character)
end)
LP.CharacterAdded:Connect(function(char)
    task.wait(0.65)
    applySavedAnimationPackToCharacter(char)
end)
_G.PulseCounterState = _G.PulseCounterState or {}
_G.PulseCounterState.batConn = nil
_G.PulseCounterState.batDebounce = false
_G.PulseCounterState.medConns = _G.PulseCounterState.medConns or {}
_G.PulseCounterState.medDebounce = false
_G.PulseCounterState.medLastUsed = _G.PulseCounterState.medLastUsed or 0
_G.PulseMedusaCooldown = 25
function _G.PulseFindMedusa()
    local c = LP.Character
    if not c then
        return nil
    end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then
            local n = t.Name:lower()
            if n:find("medusa") or n:find("head") or n:find("stone") then
                return t
            end
        end
    end
    local bp = LP:FindFirstChild("Backpack") or LP:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("medusa") or n:find("head") or n:find("stone") then
                    return t
                end
            end
        end
    end
    return nil
end
function _G.PulseUseMedusaCounter()
    if not medCounterEnabled then
        return
    end
    if _G.PulseCounterState.medDebounce then
        return
    end
    if tick() - (_G.PulseCounterState.medLastUsed or 0) < _G.PulseMedusaCooldown then
        return
    end
    local c = LP.Character
    if not c then
        return
    end
    _G.PulseCounterState.medDebounce = true
    local med = _G.PulseFindMedusa()
    if not med then
        _G.PulseCounterState.medDebounce = false
        return
    end
    if med.Parent ~= c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum:EquipTool(med)
            end)
        end
        task.wait(0.05)
    end
    pcall(function()
        med:Activate()
    end)
    _G.PulseCounterState.medLastUsed = tick()
    _G.PulseCounterState.medDebounce = false
end
function _G.PulseOnMedusaAnchorChanged(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function()
        if medCounterEnabled and part.Anchored and part.Transparency == 1 then
            _G.PulseUseMedusaCounter()
        end
    end)
end
function _G.PulseStartMedCounter(char)
    _G.PulseStopMedCounter()
    char = char or LP.Character
    if not char then
        return
    end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(_G.PulseCounterState.medConns, _G.PulseOnMedusaAnchorChanged(part))
        end
    end
    table.insert(
        _G.PulseCounterState.medConns,
        char.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then
                table.insert(_G.PulseCounterState.medConns, _G.PulseOnMedusaAnchorChanged(part))
            end
        end)
    )
end
function _G.PulseStopMedCounter()
    for _, c in pairs(_G.PulseCounterState.medConns or {}) do
        pcall(function()
            c:Disconnect()
        end)
    end
    _G.PulseCounterState.medConns = {}
    _G.PulseCounterState.medDebounce = false
end
_G.PulseBatCounterSlapList = {
    "Bat",
    "Slap",
    "Iron Slap",
    "Gold Slap",
    "Diamond Slap",
    "Emerald Slap",
    "Ruby Slap",
    "Dark Matter Slap",
    "Flame Slap",
    "Nuclear Slap",
    "Galaxy Slap",
    "Glitched Slap",
}
function _G.PulseFindBatForCounter()
    local c = LP.Character
    if not c then
        return nil
    end
    local bp = LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")
    for _, name in ipairs(_G.PulseBatCounterSlapList) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then
            return t
        end
    end
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then
            return ch
        end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then
                return ch
            end
        end
    end
    return nil
end
function _G.PulseSwingBatForCounter(bat, char)
    if not bat or not char then
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if bat.Parent ~= char then
        if hum then
            pcall(function()
                hum:EquipTool(bat)
            end)
        end
        task.wait(0.05)
    end
    local remote = bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
    if remote and remote:IsA("RemoteEvent") then
        pcall(function()
            remote:FireServer()
        end)
        task.wait(0.15)
        pcall(function()
            remote:FireServer()
        end)
    else
        pcall(function()
            bat:Activate()
        end)
        task.wait(0.15)
        pcall(function()
            bat:Activate()
        end)
    end
end
function _G.PulseCounterIsRagdoll(hum)
    if not hum then
        return false
    end
    local st = hum:GetState()
    return st == Enum.HumanoidStateType.Physics
        or st == Enum.HumanoidStateType.Ragdoll
        or st == Enum.HumanoidStateType.FallingDown
        or hum.PlatformStand == true
end
function _G.PulseStartBatCounter()
    if _G.PulseCounterState.batConn then
        return
    end
    _G.PulseCounterState.batDebounce = false
    _G.PulseCounterState.batConn = RunService.Heartbeat:Connect(function()
        if not batCounterEnabled then
            return
        end
        if _G.PulseCounterState.batDebounce then
            return
        end
        local char = LP.Character
        if not char then
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then
            return
        end
        if _G.PulseCounterIsRagdoll(hum) then
            _G.PulseCounterState.batDebounce = true
            task.spawn(function()
                local bat = _G.PulseFindBatForCounter()
                if bat then
                    _G.PulseSwingBatForCounter(bat, char)
                end
                task.wait(0.5)
                _G.PulseCounterState.batDebounce = false
            end)
        end
    end)
end
function _G.PulseStopBatCounter()
    if _G.PulseCounterState.batConn then
        _G.PulseCounterState.batConn:Disconnect()
        _G.PulseCounterState.batConn = nil
    end
    _G.PulseCounterState.batDebounce = false
end
startBatCounter = _G.PulseStartBatCounter
stopBatCounter = _G.PulseStopBatCounter
setupMedusaCounter = _G.PulseStartMedCounter
stopMedusaCounter = _G.PulseStopMedCounter
_G.PulseNoPlayerCollisionState = _G.PulseNoPlayerCollisionState or { connections = {} }
function _G.PulseSetOtherPlayerCollision(state)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            for _, part in ipairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        part.CanCollide = state
                    end)
                end
            end
        end
    end
end
function enableNoPlayerCollision()
    if _G.PulseNoPlayerCollisionState.running then
        return
    end
    _G.PulseNoPlayerCollisionEnabled = true
    _G.PulseNoPlayerCollisionState.running = true
    for _, conn in ipairs(_G.PulseNoPlayerCollisionState.connections or {}) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    _G.PulseNoPlayerCollisionState.connections = {}
    _G.PulseSetOtherPlayerCollision(false)
    table.insert(
        _G.PulseNoPlayerCollisionState.connections,
        LP.CharacterAdded:Connect(function()
            task.wait(0.5)
            if _G.PulseNoPlayerCollisionEnabled then
                _G.PulseSetOtherPlayerCollision(false)
            end
        end)
    )
    table.insert(
        _G.PulseNoPlayerCollisionState.connections,
        Players.PlayerAdded:Connect(function(plr)
            local c = plr.CharacterAdded:Connect(function()
                task.wait(0.5)
                if _G.PulseNoPlayerCollisionEnabled then
                    _G.PulseSetOtherPlayerCollision(false)
                end
            end)
            table.insert(_G.PulseNoPlayerCollisionState.connections, c)
        end)
    )
    local collisionScanElapsed = 0
    table.insert(
        _G.PulseNoPlayerCollisionState.connections,
        RunService.Heartbeat:Connect(function(dt)
            if not _G.PulseNoPlayerCollisionEnabled then
                return
            end
            collisionScanElapsed = collisionScanElapsed + (dt or 0)
            if collisionScanElapsed < 0.25 then
                return
            end
            collisionScanElapsed = 0
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    for _, part in ipairs(plr.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide == true then
                            pcall(function()
                                part.CanCollide = false
                            end)
                        end
                    end
                end
            end
        end)
    )
end
function disableNoPlayerCollision()
    if not _G.PulseNoPlayerCollisionState.running then
        _G.PulseNoPlayerCollisionEnabled = false
        return
    end
    _G.PulseNoPlayerCollisionEnabled = false
    _G.PulseNoPlayerCollisionState.running = false
    for _, conn in ipairs(_G.PulseNoPlayerCollisionState.connections or {}) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    _G.PulseNoPlayerCollisionState.connections = {}
    _G.PulseSetOtherPlayerCollision(true)
end
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if medCounterEnabled then
        _G.PulseStartMedCounter(char)
    end
    if batCounterEnabled then
        _G.PulseStartBatCounter()
    end
end)
_G.PulseNormalAimbot = _G.PulseNormalAimbot or { conn = nil, target = nil, swingCooldown = false }
function _G.PulseFindAimbotBat()
    local char = LP.Character
    if not char then
        return nil
    end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then
            return tool
        end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then
                return tool
            end
        end
    end
    return nil
end
function _G.PulseGetClosestAimbotTarget()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end
    local closest, minDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if tRoot and hum and hum.Health > 0 then
                local dist = (tRoot.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = tRoot
                end
            end
        end
    end
    return closest
end
function _G.PulseGetAntiBypassAimbotSpeed()
    if
        currentSpeedMode == "Lagger"
        or currentSpeedMode == "Lagger Carry"
        or currentSpeedMode == "Lagger 2"
        or currentSpeedMode == "Lagger Carry 2"
    then
        return tonumber(_G.PulseAntiBypassLaggerAimbotSpeed) or 40
    end
    return tonumber(_G.PulseAntiBypassAimbotSpeed) or 58
end
function _G.PulseGetSelectedAimbotSpeedValues()
    if selectedAimbotMode == "Anti Bypass" then
        return tonumber(_G.PulseAntiBypassAimbotSpeed) or 58, tonumber(_G.PulseAntiBypassLaggerAimbotSpeed) or 40
    end
    return tonumber(AIMBOT_SPEED) or 58, tonumber(LAGGER_AIMBOT_SPEED) or 40
end
function _G.PulseSetSelectedAimbotSpeedValues(normalValue, laggerValue)
    if selectedAimbotMode == "Anti Bypass" then
        if normalValue then
            _G.PulseAntiBypassAimbotSpeed = normalValue
        end
        if laggerValue then
            _G.PulseAntiBypassLaggerAimbotSpeed = laggerValue
        end
    else
        if normalValue then
            AIMBOT_SPEED = normalValue
        end
        if laggerValue then
            LAGGER_AIMBOT_SPEED = laggerValue
        end
    end
end
function _G.PulseRefreshAimbotSpeedBoxes()
    local n, l = _G.PulseGetSelectedAimbotSpeedValues()
    if _G.PulseAimbotSpeedBox then
        _G.PulseAimbotSpeedBox.Text = tostring(n)
    end
    if _G.PulseLaggerAimbotSpeedBox then
        _G.PulseLaggerAimbotSpeedBox.Text = tostring(l)
    end
end
_G.PulseAntiBypassAimbot = _G.PulseAntiBypassAimbot or { conn = nil, swingCooldown = false, prevAutoRotate = nil }
_G.PulseAntiBypassSlapList = _G.PulseAntiBypassSlapList
    or {
        "Bat",
        "Slap",
        "Iron Slap",
        "Gold Slap",
        "Diamond Slap",
        "Emerald Slap",
        "Ruby Slap",
        "Dark Matter Slap",
        "Flame Slap",
        "Nuclear Slap",
        "Galaxy Slap",
        "Glitched Slap",
    }
function _G.PulseAntiBypassFindBat()
    local char = LP.Character
    if not char then
        return nil
    end
    for _, name in ipairs(_G.PulseAntiBypassSlapList) do
        local t = char:FindFirstChild(name)
        if t and t:IsA("Tool") then
            return t
        end
    end
    local bp = LP:FindFirstChildOfClass("Backpack")
    if bp then
        for _, name in ipairs(_G.PulseAntiBypassSlapList) do
            local t = bp:FindFirstChild(name)
            if t and t:IsA("Tool") then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    pcall(function()
                        hum:EquipTool(t)
                    end)
                end
                return t
            end
        end
    end
    for _, ch in ipairs(char:GetChildren()) do
        if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then
            return ch
        end
    end
    return nil
end
function _G.PulseAntiBypassTrySwing()
    if _G.PulseAntiBypassAimbot.swingCooldown then
        return
    end
    _G.PulseAntiBypassAimbot.swingCooldown = true
    pcall(function()
        local char = LP.Character
        if not char then
            return
        end
        local bat = _G.PulseAntiBypassFindBat()
        if bat then
            if bat.Parent ~= char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    pcall(function()
                        hum:EquipTool(bat)
                    end)
                end
            end
            pcall(function()
                bat:Activate()
            end)
        end
    end)
    task.delay(0.35, function()
        if _G.PulseAntiBypassAimbot then
            _G.PulseAntiBypassAimbot.swingCooldown = false
        end
    end)
end
function _G.PulseAntiBypassGetClosest()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil, math.huge
    end
    local closest, minDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if tRoot and hum and hum.Health > 0 then
                local dist = (tRoot.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = tRoot
                end
            end
        end
    end
    return closest, minDist
end
function _G.PulseAntiBypassQuickPatch()
    pcall(function()
        local playerGui = LP:FindFirstChild("PlayerGui")
        if playerGui then
            for _, child in ipairs(playerGui:GetChildren()) do
                local name = child.Name and child.Name:lower() or ""
                if name:find("antibat") or name:find("irish") or name:find("cryptic") then
                    child:Destroy()
                end
            end
        end
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and not hum.AutoRotate then
                hum.AutoRotate = true
            end
        end
    end)
end
function _G.PulseStartAntiBypassAimbot()
    if _G.PulseStopAutoTPForAction then
        _G.PulseStopAutoTPForAction()
    end
    if autoLeftEnabled and _G.PulseSetAutoLeft then
        _G.PulseSetAutoLeft(false, true)
    end
    if autoRightEnabled and _G.PulseSetAutoRight then
        _G.PulseSetAutoRight(false, true)
    end
    if _G.PulseAntiDesyncAimbotOn and _G.PulseStopAntiDesyncAimbot then
        _G.PulseStopAntiDesyncAimbot()
    end
    _G.PulseAntiBypassAimbotOn = true
    _G.PulseAntiBypassRespawnWanted = true
    selectedAimbotMode = "Anti Bypass"
    _G.PulseAntiBypassQuickPatch()
    if _G.PulseAntiBypassAimbot.conn then
        _G.PulseAntiBypassAimbot.conn:Disconnect()
        _G.PulseAntiBypassAimbot.conn = nil
    end
    if _G.PulseAntiBypassAimbot.patchThread then
        pcall(function()
            task.cancel(_G.PulseAntiBypassAimbot.patchThread)
        end)
    end
    _G.PulseAntiBypassAimbot.patchThread = task.spawn(function()
        while _G.PulseAntiBypassAimbotOn do
            task.wait(5)
            if _G.PulseAntiBypassAimbotOn then
                _G.PulseAntiBypassQuickPatch()
            end
        end
    end)
    _G.PulseAntiBypassAimbot.conn = RunService.Heartbeat:Connect(function()
        if not _G.PulseAntiBypassAimbotOn then
            return
        end
        local char = LP.Character
        if not char then
            return
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then
            return
        end
        if not char:FindFirstChildOfClass("Tool") then
            local bat = _G.PulseAntiBypassFindBat()
            if bat then
                pcall(function()
                    hum:EquipTool(bat)
                end)
            end
        end
        local target = _G.PulseAntiBypassGetClosest()
        if not target then
            hum.AutoRotate = true
            root.AssemblyAngularVelocity = Vector3.zero
            return
        end
        local aimTargetPos = target.Position + Vector3.new(0, 1, 0)
        hum.AutoRotate = false
        local look = aimTargetPos - root.Position
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if look.Magnitude > 0.01 and flatLook.Magnitude > 0.01 then
            local targetYaw = math.deg(math.atan2(-flatLook.X, -flatLook.Z))
            local yawDelta = (targetYaw - root.Orientation.Y + 180) % 360 - 180
            local yawRate = math.clamp(yawDelta * 8, -28, 28)
            root.AssemblyAngularVelocity = Vector3.new(0, yawRate, 0)
        else
            root.AssemblyAngularVelocity = Vector3.zero
        end
        local dir = look.Unit
        local standPos = aimTargetPos - (dir * -2.8) + Vector3.new(0, 4.75, 0)
        local moveDir = standPos - root.Position
        local hDir = Vector3.new(moveDir.X, 0, moveDir.Z)
        local chaseSpeed = _G.PulseGetAntiBypassAimbotSpeed()
        local hVel = hDir.Magnitude > 0.1 and hDir.Unit * chaseSpeed or Vector3.zero
        local vVel = Vector3.new(0, math.clamp(moveDir.Y * 3, -52, 52), 0)
        root.AssemblyLinearVelocity = hVel + vVel
        if hDir.Magnitude > 0.5 then
            hum:Move(hDir.Unit, false)
        end
        if autoSwingEnabled and (root.Position - target.Position).Magnitude < 5 then
            _G.PulseAntiBypassTrySwing()
        end
    end)
    if _G.PulseRefreshAimbotVisual then
        _G.PulseRefreshAimbotVisual()
    end
end
function _G.PulseStopAntiBypassAimbot(keepVisual)
    _G.PulseAntiBypassAimbotOn = false
    _G.PulseAntiBypassRespawnWanted = false
    if _G.PulseAntiBypassAimbot and _G.PulseAntiBypassAimbot.conn then
        _G.PulseAntiBypassAimbot.conn:Disconnect()
        _G.PulseAntiBypassAimbot.conn = nil
    end
    if _G.PulseAntiBypassAimbot then
        if _G.PulseAntiBypassAimbot.patchThread then
            pcall(function()
                task.cancel(_G.PulseAntiBypassAimbot.patchThread)
            end)
            _G.PulseAntiBypassAimbot.patchThread = nil
        end
        _G.PulseAntiBypassAimbot.swingCooldown = false
    end
    local c = LP.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.AutoRotate = (_G.PulseAntiBypassAimbot.prevAutoRotate == nil) and true
            or _G.PulseAntiBypassAimbot.prevAutoRotate
        hum.PlatformStand = false
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
    if _G.PulseAntiBypassAimbot then
        _G.PulseAntiBypassAimbot.prevAutoRotate = nil
    end
    if keepVisual ~= false and _G.PulseRefreshAimbotVisual then
        _G.PulseRefreshAimbotVisual()
    end
end
LP.CharacterAdded:Connect(function()
    task.wait(0.3)
    _G.PulseAntiBypassQuickPatch()
    local wanted = _G.PulseAntiBypassRespawnWanted == true
    if wanted then
        if _G.PulseStopAntiBypassAimbot then
            _G.PulseStopAntiBypassAimbot(false)
        end
        task.wait(0.1)
        if _G.PulseStartAntiBypassAimbot then
            _G.PulseStartAntiBypassAimbot()
        end
    end
end)
function _G.PulseToggleSelectedAimbot()
    if _G.PulseAntiBypassAimbotOn then
        if _G.PulseStopAntiBypassAimbot then
            _G.PulseStopAntiBypassAimbot()
        else
            _G.PulseAntiBypassAimbotOn = false
        end
    else
        if _G.PulseStartAntiBypassAimbot then
            _G.PulseStartAntiBypassAimbot()
        else
            _G.PulseAntiBypassAimbotOn = true
        end
    end
    if _G.PulseRefreshAimbotVisual then
        _G.PulseRefreshAimbotVisual()
    end
    savePulseConfig()
end
function _G.PulseRefreshAimbotVisual()
    if _G.PulseAimbotSetVisual then
        if selectedAimbotMode == "Anti Bypass" then
            _G.PulseAimbotSetVisual(_G.PulseAntiBypassAimbotOn == true)
        else
            _G.PulseAimbotSetVisual(_G.PulseNormalAimbotOn == true)
        end
    end
end
_G.PulseAntiBypassStart = _G.PulseStartAntiBypassAimbot
_G.PulseAntiBypassStop = _G.PulseStopAntiBypassAimbot
_G.PulseAntiDesync = _G.PulseAntiDesync or { conn = nil, hittingCooldown = false, h = nil, hrp = nil }
function _G.PulseAntiDesyncGetBat()
    local char = LP.Character
    if not char then
        return nil
    end
    local tool = char:FindFirstChild("Bat")
    if tool then
        return tool
    end
    local bp2 = LP:FindFirstChild("Backpack")
    if bp2 then
        tool = bp2:FindFirstChild("Bat")
        if tool then
            tool.Parent = char
            return tool
        end
    end
    return nil
end
function _G.PulseAntiDesyncTrySwing()
    if not _G.PulseAntiDesync then
        return
    end
    if _G.PulseAntiDesync.hittingCooldown then
        return
    end
    _G.PulseAntiDesync.hittingCooldown = true
    pcall(function()
        local bat = _G.PulseAntiDesyncGetBat()
        if bat then
            bat:Activate()
            local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
            if ev then
                ev:FireServer()
            end
        end
    end)
    task.delay(0.08, function()
        if _G.PulseAntiDesync then
            _G.PulseAntiDesync.hittingCooldown = false
        end
    end)
end
function _G.PulseAntiDesyncGetClosestPlayer()
    local hrp = _G.PulseAntiDesync and _G.PulseAntiDesync.hrp
    if not hrp then
        return nil, math.huge
    end
    local cp, cd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local d = (hrp.Position - tr.Position).Magnitude
                if d < cd then
                    cd = d
                    cp = p
                end
            end
        end
    end
    return cp, cd
end
function _G.PulseAntiDesyncSetupChar(char)
    task.wait(0.1)
    if not _G.PulseAntiDesync then
        return
    end
    _G.PulseAntiDesync.h = char and char:WaitForChild("Humanoid", 5) or nil
    _G.PulseAntiDesync.hrp = char and char:WaitForChild("HumanoidRootPart", 5) or nil
end
LP.CharacterAdded:Connect(function(char)
    pcall(function()
        _G.PulseAntiDesyncSetupChar(char)
    end)
end)
if LP.Character then
    task.spawn(function()
        pcall(function()
            _G.PulseAntiDesyncSetupChar(LP.Character)
        end)
    end)
end
function _G.PulseStartAntiDesyncAimbot()
    if _G.PulseStopAutoTPForAction then
        _G.PulseStopAutoTPForAction()
    end
    if _G.PulseStopAntiBypassAimbot then
        _G.PulseStopAntiBypassAimbot(false)
    end
    if autoLeftEnabled and _G.PulseSetAutoLeft then
        _G.PulseSetAutoLeft(false, true)
    end
    if autoRightEnabled and _G.PulseSetAutoRight then
        _G.PulseSetAutoRight(false, true)
    end
    _G.PulseAntiDesyncAimbotOn = true
    if _G.PulseAntiDesync.conn then
        _G.PulseAntiDesync.conn:Disconnect()
        _G.PulseAntiDesync.conn = nil
    end
    if LP.Character then
        pcall(function()
            _G.PulseAntiDesyncSetupChar(LP.Character)
        end)
    end
    _G.PulseAntiDesync.conn = RunService.Heartbeat:Connect(function()
        if not (_G.PulseAntiDesyncAimbotOn and _G.PulseAntiDesync.h and _G.PulseAntiDesync.hrp) then
            return
        end
        local target, dist = _G.PulseAntiDesyncGetClosestPlayer()
        _aimbotTargetPlr = target
        _G.PulseCurrentAimbotTarget = target
        _G.PulseAntiDesyncBatTarget = target
        if target and target.Character then
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                if sethiddenproperty then
                    pcall(function()
                        sethiddenproperty(_G.PulseAntiDesync.hrp, "PhysicsRepRootPart", tr)
                    end)
                end
                local targetPos = tr.Position + Vector3.new(0, 0.9, 0)
                if (_G.PulseAntiDesync.hrp.Position - targetPos).Magnitude > 8 then
                    _G.PulseAntiDesync.hrp.CFrame = CFrame.new(targetPos)
                end
                local cam = workspace.CurrentCamera
                if cam then
                    cam.CFrame = CFrame.new(cam.CFrame.Position, tr.Position)
                end
                if antiDesyncAutoSwingEnabled or autoSwingEnabled then
                    _G.PulseAntiDesyncTrySwing()
                end
            end
        end
    end)
    if _G.PulseAntiDesyncSetVisual then
        _G.PulseAntiDesyncSetVisual(true)
    end
    savePulseConfig()
    return true
end
function _G.PulseStopAntiDesyncAimbot()
    _G.PulseAntiDesyncAimbotOn = false
    if _G.PulseAntiDesync and _G.PulseAntiDesync.conn then
        _G.PulseAntiDesync.conn:Disconnect()
        _G.PulseAntiDesync.conn = nil
    end
    if _G.PulseAntiDesync then
        _G.PulseAntiDesync.hittingCooldown = false
    end
    _G.PulseAntiDesyncBatTarget = nil
    if _G.PulseCurrentAimbotTarget == _aimbotTargetPlr then
        _G.PulseCurrentAimbotTarget = nil
    end
    _aimbotTargetPlr = nil
    if _G.PulseAntiDesyncSetVisual then
        _G.PulseAntiDesyncSetVisual(false)
    end
    savePulseConfig()
end
function _G.PulseToggleAntiDesyncAimbot()
    if _G.PulseAntiDesyncAimbotOn then
        _G.PulseStopAntiDesyncAimbot()
    else
        _G.PulseStartAntiDesyncAimbot()
    end
end
_G.__PulseSetupNormalAutoSteal = function()
    _G.PulseNormalSteal = _G.PulseNormalSteal
        or {
            enabled = false,
            radius = 62,
            duration = 1.3,
            animals = {},
            promptCache = {},
            internalCache = {},
            scannerStarted = false,
            scanning = false,
            isStealing = false,
            stealConn = nil,
            refreshThread = nil,
            lastSteal = 0,
            cooldown = 0.08,
        }
    if _G.PulseNormalSteal.stealConn then
        pcall(function()
            _G.PulseNormalSteal.stealConn:Disconnect()
        end)
        _G.PulseNormalSteal.stealConn = nil
    end
    _G.PulseNormalSteal.enabled = false
    _G.PulseNormalSteal.isStealing = false
    local function barProgress(p)
        p = math.clamp(tonumber(p) or 0, 0, 1)
        pcall(function()
            if _G.StealBar then
                _G.StealBar.SetState("STEALING")
                _G.StealBar.SetProgress(p)
            end
        end)
    end
    local function resetBar()
        pcall(function()
            if _G.StealBar then
                _G.StealBar.Reset()
            end
        end)
    end
    local function getRoot()
        local char = LP.Character
        if not char then
            return nil
        end
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
    end
    local function isMyBase(plotName)
        local plots = workspace:FindFirstChild("Plots")
        local plot = plots and plots:FindFirstChild(plotName)
        if not plot then
            return false
        end
        local sign = plot:FindFirstChild("PlotSign")
        local yourBase = sign and sign:FindFirstChild("YourBase")
        return yourBase and yourBase:IsA("BillboardGui") and yourBase.Enabled == true
    end
    local function scanPlots()
        local a = _G.PulseNormalSteal
        a.animals = {}
        local plots = workspace:FindFirstChild("Plots")
        if not plots then
            return
        end
        for _, plot in ipairs(plots:GetChildren()) do
            if plot:IsA("Model") and not isMyBase(plot.Name) then
                local podiums = plot:FindFirstChild("AnimalPodiums")
                if podiums then
                    for _, podium in ipairs(podiums:GetChildren()) do
                        if podium:IsA("Model") then
                            local base = podium:FindFirstChild("Base")
                            local spawn = base and base:FindFirstChild("Spawn")
                            if spawn then
                                table.insert(
                                    a.animals,
                                    {
                                        plot = plot.Name,
                                        slot = podium.Name,
                                        worldPosition = spawn.Position,
                                        uid = plot.Name .. "_" .. podium.Name,
                                    }
                                )
                            end
                        end
                    end
                end
            end
        end
    end
    local function ensureScanner()
        local a = _G.PulseNormalSteal
        if a.scannerStarted then
            return
        end
        a.scannerStarted = true
        task.spawn(function()
            task.wait(1)
            while _G.PulseNormalSteal do
                if _G.PulseNormalSteal.enabled then
                    pcall(scanPlots)
                end
                task.wait(3)
            end
        end)
    end
    local function findPrompt(data)
        if not data then
            return nil
        end
        local a = _G.PulseNormalSteal
        local cached = a.promptCache[data.uid]
        if cached and cached.Parent then
            return cached
        end
        local plots = workspace:FindFirstChild("Plots")
        local plot = plots and plots:FindFirstChild(data.plot)
        local podiums = plot and plot:FindFirstChild("AnimalPodiums")
        local podium = podiums and podiums:FindFirstChild(data.slot)
        local base = podium and podium:FindFirstChild("Base")
        local spawn = base and base:FindFirstChild("Spawn")
        local attach = spawn and spawn:FindFirstChild("PromptAttachment")
        if not attach then
            return nil
        end
        for _, prompt in ipairs(attach:GetChildren()) do
            if prompt:IsA("ProximityPrompt") then
                a.promptCache[data.uid] = prompt
                return prompt
            end
        end
        return nil
    end
    local function cacheCallbacks(prompt)
        local a = _G.PulseNormalSteal
        if a.internalCache[prompt] then
            return
        end
        local data = { hold = {}, trigger = {}, ready = true }
        pcall(function()
            if getconnections then
                for _, conn in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if type(conn.Function) == "function" then
                        table.insert(data.hold, conn.Function)
                    end
                end
                for _, conn in ipairs(getconnections(prompt.Triggered)) do
                    if type(conn.Function) == "function" then
                        table.insert(data.trigger, conn.Function)
                    end
                end
            end
        end)
        if #data.hold > 0 or #data.trigger > 0 then
            a.internalCache[prompt] = data
        end
    end
    local function doSteal(prompt)
        local a = _G.PulseNormalSteal
        if not prompt or not prompt.Parent or a.isStealing then
            return
        end
        if tick() - (a.lastSteal or 0) < (a.cooldown or 0.08) then
            return
        end
        cacheCallbacks(prompt)
        local data = a.internalCache[prompt]
        if not data or not data.ready then
            return
        end
        data.ready = false
        a.isStealing = true
        a.lastSteal = tick()
        pcall(function()
            if _G.StealBar then
                _G.StealBar.SetState("STEALING")
            end
        end)
        task.spawn(function()
            if #data.hold > 0 then
                for _, fn in ipairs(data.hold) do
                    task.spawn(function()
                        pcall(fn)
                    end)
                end
            end
            local startTime = tick()
            local dur = 1.3
            a.duration = dur
            while a.enabled and selectedStealMode == "Normal" and tick() - startTime < dur do
                barProgress((tick() - startTime) / dur)
                task.wait(0.02)
            end
            if not a.enabled or selectedStealMode ~= "Normal" then
                data.ready = true
                a.isStealing = false
                resetBar()
                return
            end
            barProgress(1)
            if #data.trigger > 0 then
                for _, fn in ipairs(data.trigger) do
                    task.spawn(function()
                        pcall(fn)
                    end)
                end
            end
            pcall(function()
                if _G.AutoCarrySpeed and _G.AutoCarrySpeed.WatchPickup then
                    _G.AutoCarrySpeed.WatchPickup(1.25)
                end
            end)
            task.wait(0.12)
            data.ready = true
            a.isStealing = false
            resetBar()
        end)
    end
    local function nearestAnimal()
        local a = _G.PulseNormalSteal
        local root = getRoot()
        if not root then
            return nil
        end
        local best, bestDist = nil, math.huge
        for _, data in ipairs(a.animals) do
            if data.worldPosition and not isMyBase(data.plot) then
                local dist = (root.Position - data.worldPosition).Magnitude
                if dist < bestDist then
                    best = data
                    bestDist = dist
                end
            end
        end
        if best and bestDist <= (tonumber(a.radius) or 62) then
            return best
        end
        return nil
    end
    _G.PulseNormalAutoStealSetRadius = function(v)
        _G.PulseNormalSteal.radius = tonumber(v) or _G.PulseNormalSteal.radius or 62
    end
    _G.PulseNormalAutoStealStop = function()
        local a = _G.PulseNormalSteal
        a.enabled = false
        a.isStealing = false
        if a.stealConn then
            a.stealConn:Disconnect()
            a.stealConn = nil
        end
        resetBar()
    end
    _G.PulseNormalAutoStealStart = function()
        local a = _G.PulseNormalSteal
        a.radius = tonumber(autoStealRadius) or a.radius or 62
        a.duration = 1.3
        a.enabled = true
        ensureScanner()
        pcall(scanPlots)
        if a.stealConn then
            a.stealConn:Disconnect()
            a.stealConn = nil
        end
        a.stealConn = RunService.Heartbeat:Connect(function()
            if not a.enabled then
                return
            end
            if selectedStealMode ~= "Normal" then
                _G.PulseNormalAutoStealStop()
                return
            end
            if a.isStealing then
                return
            end
            local target = nearestAnimal()
            if not target then
                return
            end
            local prompt = findPrompt(target)
            if prompt then
                doSteal(prompt)
            end
        end)
    end
    _G.PulseNormalAutoStealSync = function()
        if selectedStealMode == "Normal" and autoStealEnabled then
            _G.PulseNormalAutoStealStart()
        else
            _G.PulseNormalAutoStealStop()
        end
    end
end
_G.__PulseSetupNormalAutoSteal()
_G.__PulseSetupSemiAutoSteal = function()
    _G.PulseSemiSteal = _G.PulseSemiSteal or {}
    local A = _G.PulseSemiSteal
    if A.conn then
        pcall(function()
            A.conn:Disconnect()
        end)
        A.conn = nil
    end
    A.enabled = false
    A.holdMin = 1.3
    A.holdMax = 2.6
    A.softWindow = 5
    A.entryDelay = 0.3
    A.cooldown = 0.05
    A.primeRange = 80
    A.radius = tonumber(autoStealRadius) or 10
    A.conn = A.conn
    A.scanThread = A.scanThread
    A.plotSync = A.plotSync or { caches = {}, connections = {} }
    A.animals = A.animals or {}
    A.promptCache = A.promptCache or {}
    A.internalCache = A.internalCache or {}
    A.state = A.state
        or { active = false, startTime = 0, phase = "idle", label = "", lastResult = "", lastResultTime = 0 }
    local function barSet(p, label)
        pcall(function()
            if _G.StealBar then
                _G.StealBar.SetState(label or "STEALING")
                _G.StealBar.SetProgress(math.clamp(tonumber(p) or 0, 0, 1))
            end
        end)
    end
    local function barReset()
        pcall(function()
            if _G.StealBar then
                _G.StealBar.Reset()
            end
        end)
    end
    local function rootPart()
        local char = LP.Character
        return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")) or nil
    end
    local function splitPath(path)
        if typeof(path) == "table" then
            return path
        end
        local out = {}
        for part in string.gmatch(tostring(path), "[^%.]+") do
            table.insert(out, tonumber(part) or part)
        end
        return out
    end
    local function resolvePath(path, root)
        local current, parent, key = root, nil, nil
        for _, part in ipairs(splitPath(path)) do
            parent = current
            key = part
            current = current and current[part] or nil
        end
        return current, parent, key
    end
    local function applySyncDiff(channelName, packet)
        local cache = A.plotSync.caches[channelName]
        if typeof(cache) ~= "table" then
            return
        end
        local path, action, a, b = packet[1], packet[2], packet[3], packet[4]
        local current, parent, key = resolvePath(path, cache)
        if action == "Changed" then
            if parent ~= nil then
                parent[key] = a
            end
        elseif action == "ArrayInsert" then
            if current ~= nil then
                table.insert(current, b, a)
            end
        elseif action == "ArrayRemoved" then
            if current ~= nil then
                table.remove(current, b)
            end
        elseif action == "DictionaryInsert" then
            if current ~= nil then
                current[b] = a
            end
        elseif action == "DictionaryRemoved" then
            if current ~= nil then
                current[b] = nil
            end
        end
    end
    local function attachPlotChannel(remote, plots, requestData)
        if A.plotSync.connections[remote] then
            return
        end
        local channelName = tostring(remote.Name)
        if not plots:FindFirstChild(channelName) then
            return
        end
        if requestData and A.plotSync.caches[channelName] == nil then
            local ok, data = pcall(function()
                return requestData:InvokeServer(channelName)
            end)
            A.plotSync.caches[channelName] = (ok and typeof(data) == "table") and data or {}
        elseif A.plotSync.caches[channelName] == nil then
            A.plotSync.caches[channelName] = {}
        end
        A.plotSync.connections[remote] = remote.OnClientEvent:Connect(function(queue)
            for _, packet in ipairs(queue) do
                applySyncDiff(channelName, packet)
            end
        end)
    end
    local function ensureSync()
        if A.syncReady then
            return true
        end
        local ok = pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            A.packages = rs:WaitForChild("Packages", 10)
            A.datas = rs:WaitForChild("Datas", 10)
            A.plots = workspace:WaitForChild("Plots", 10)
            if not (A.packages and A.datas and A.plots) then
                return
            end
            A.animalsData = require(A.datas:WaitForChild("Animals", 10))
            local sync = A.packages:WaitForChild("Synchronizer", 10)
            A.channelFolder = sync:WaitForChild("Channel", 10)
            A.routeRemote = sync:WaitForChild("CommunicationRoute", 10)
            A.requestData = sync:FindFirstChild("RequestData")
            for _, child in ipairs(A.channelFolder:GetChildren()) do
                if child:IsA("RemoteEvent") then
                    attachPlotChannel(child, A.plots, A.requestData)
                end
            end
            A.channelFolder.ChildAdded:Connect(function(child)
                if child:IsA("RemoteEvent") then
                    attachPlotChannel(child, A.plots, A.requestData)
                end
            end)
            A.routeRemote.OnClientEvent:Connect(function(actions)
                for _, action in ipairs(actions) do
                    local kind, channelName = action[1], tostring(action[2])
                    if A.plots and A.plots:FindFirstChild(channelName) then
                        if kind == "ListenerAdded" then
                            local remote = A.channelFolder and A.channelFolder:FindFirstChild(channelName)
                            if remote and remote:IsA("RemoteEvent") then
                                attachPlotChannel(remote, A.plots, A.requestData)
                            end
                        elseif kind == "ListenerRemoved" then
                            for remote, conn in pairs(A.plotSync.connections) do
                                if tostring(remote.Name) == channelName then
                                    pcall(function()
                                        conn:Disconnect()
                                    end)
                                    A.plotSync.connections[remote] = nil
                                    A.plotSync.caches[channelName] = nil
                                    break
                                end
                            end
                        end
                    end
                end
            end)
            A.syncReady = true
        end)
        return ok and A.syncReady == true
    end
    local function getPlotOwner(plot)
        local sign = plot and plot:FindFirstChild("PlotSign")
        local frame = sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Frame")
        local label = frame and frame:FindFirstChild("TextLabel")
        if not label or label.Text == "Empty Base" then
            return nil
        end
        return label.Text:gsub("'s [Bb]ase$", ""):gsub("%s+$", "")
    end
    local function isMyBaseAnimal(animalData)
        if not animalData or not animalData.plot or not A.plots then
            return false
        end
        local plot = A.plots:FindFirstChild(animalData.plot)
        if not plot then
            return false
        end
        local owner = getPlotOwner(plot)
        return owner == LP.DisplayName or owner == LP.Name
    end
    local function podiumFor(animalData)
        local plot = A.plots and A.plots:FindFirstChild(animalData.plot)
        local podiums = plot and plot:FindFirstChild("AnimalPodiums")
        return podiums and podiums:FindFirstChild(animalData.slot) or nil
    end
    local function animalPos(animalData)
        local podium = podiumFor(animalData)
        return podium and podium:GetPivot().Position or nil
    end
    local function distToAnimal(animalData)
        local root = rootPart()
        local pos = animalPos(animalData)
        return root and pos and (root.Position - pos).Magnitude or math.huge
    end
    local function findPromptForAnimal(animalData)
        if not animalData then
            return nil
        end
        local cached = A.promptCache[animalData.uid]
        if cached and cached.Parent then
            return cached
        end
        local podium = podiumFor(animalData)
        local base = podium and podium:FindFirstChild("Base")
        local spawn = base and base:FindFirstChild("Spawn")
        local attach = spawn and spawn:FindFirstChild("PromptAttachment")
        if not attach then
            return nil
        end
        for _, prompt in ipairs(attach:GetChildren()) do
            if prompt:IsA("ProximityPrompt") then
                A.promptCache[animalData.uid] = prompt
                return prompt
            end
        end
        return nil
    end
    local function scanAllPlots()
        if not ensureSync() then
            return 0
        end
        local newCache = {}
        for _, plot in ipairs(A.plots:GetChildren()) do
            local cache = A.plotSync.caches[plot.Name]
            local animalList = cache and cache.AnimalList
            if typeof(animalList) == "table" then
                for slot, animalData in pairs(animalList) do
                    if type(animalData) == "table" then
                        local animalName = animalData.Index
                        local info = A.animalsData and A.animalsData[animalName]
                        if info then
                            table.insert(
                                newCache,
                                {
                                    name = info.DisplayName or animalName,
                                    plot = plot.Name,
                                    slot = tostring(slot),
                                    uid = plot.Name .. "_" .. tostring(slot),
                                }
                            )
                        end
                    end
                end
            end
        end
        A.animals = newCache
        return #newCache
    end
    local function pickClosest()
        local root = rootPart()
        if not root then
            return nil
        end
        local best, bestDist = nil, math.huge
        for _, animalData in ipairs(A.animals) do
            if not isMyBaseAnimal(animalData) then
                local pos = animalPos(animalData)
                local dist = pos and (root.Position - pos).Magnitude or math.huge
                if dist <= (A.primeRange or 80) and dist < bestDist then
                    best, bestDist = animalData, dist
                end
            end
        end
        return best
    end
    local function buildCallbacks(prompt)
        if A.internalCache[prompt] then
            return
        end
        local data = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
        local okHold, holds = pcall(getconnections, prompt.PromptButtonHoldBegan)
        if okHold and type(holds) == "table" then
            for _, conn in ipairs(holds) do
                if type(conn.Function) == "function" then
                    table.insert(data.holdCallbacks, conn.Function)
                end
            end
        end
        local okTrigger, triggers = pcall(getconnections, prompt.Triggered)
        if okTrigger and type(triggers) == "table" then
            for _, conn in ipairs(triggers) do
                if type(conn.Function) == "function" then
                    table.insert(data.triggerCallbacks, conn.Function)
                end
            end
        end
        if #data.holdCallbacks > 0 or #data.triggerCallbacks > 0 then
            A.internalCache[prompt] = data
        end
    end
    local function canStillGrabSemi(prompt, animalData)
        if not A.enabled or selectedStealMode ~= "Semi" then
            return false
        end
        if not prompt or not prompt.Parent then
            return false
        end
        if prompt:IsA("ProximityPrompt") and not prompt.Enabled then
            return false
        end
        if tostring(prompt.ActionText):lower():find("steal", 1, true) == nil then
            return false
        end
        if not animalData then
            return false
        end
        if isMyBaseAnimal(animalData) then
            return false
        end
        local pod = podiumFor(animalData)
        if not pod or not pod.Parent then
            return false
        end
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then
            return false
        end
        return true
    end
    local function executeSemi(prompt, animalData)
        if not prompt or not prompt.Parent or not animalData then
            return false
        end
        buildCallbacks(prompt)
        local data = A.internalCache[prompt]
        if not data or not data.ready then
            return false
        end
        data.ready = false
        A.state.active = true
        A.state.startTime = tick()
        A.state.phase = "holding"
        A.state.label = animalData.name or "Animal"
        task.spawn(function()
            local startTime = A.state.startTime
            for _, fn in ipairs(data.holdCallbacks) do
                task.spawn(function()
                    pcall(fn)
                end)
            end
            while A.enabled and selectedStealMode == "Semi" and tick() - startTime < (A.holdMin or 1.3) do
                if not canStillGrabSemi(prompt, animalData) then
                    break
                end
                if _G.PulseSoftStealEnabled then
                    barSet((tick() - startTime) / (A.holdMin or 1.3), "PREPARING")
                else
                    barSet((tick() - startTime) / (A.holdMax or 2.6), "PREPARING")
                end
                task.wait()
            end
            if not (A.enabled and selectedStealMode == "Semi" and canStillGrabSemi(prompt, animalData)) then
                A.state.active = false
                data.ready = true
                barReset()
                return
            end
            A.state.phase = "waitingRange"
            local alreadyInRange = distToAnimal(animalData) <= (tonumber(A.radius) or 10)
            local fired = false
            local windowStart = tick()
            local controller = _G.PulseSemiRagdollStealController
            local wasRagdolled = _G.PulseSemiRagdollStealEnabled == true and controller and controller.active == true
                or false
            local recoveredAt = controller and tonumber(controller.recoveredAt) or 0
            local recoveryGraceUntil = (
                _G.PulseSemiRagdollStealEnabled == true
                and recoveredAt > 0
                and tick() - recoveredAt <= 0.5
            )
                    and (tick() + 0.30)
                or 0
            while A.enabled and selectedStealMode == "Semi" and prompt.Parent do
                if not canStillGrabSemi(prompt, animalData) then
                    break
                end
                controller = _G.PulseSemiRagdollStealController
                local ragdollActive = _G.PulseSemiRagdollStealEnabled == true
                        and controller
                        and controller.active == true
                    or false
                if ragdollActive then
                    wasRagdolled = true
                    A.state.phase = "waitingRecovery"
                    barSet(1, "READY ON RECOVERY")
                else
                    if wasRagdolled then
                        wasRagdolled = false
                        recoveryGraceUntil = _G.PulseSemiRagdollStealEnabled == true and (tick() + 0.30) or 0
                        A.state.phase = "waitingRange"
                    end
                    local inRecoveryGrace = tick() <= recoveryGraceUntil
                    if _G.PulseSoftStealEnabled then
                        local elapsedWindow = tick() - windowStart
                        local windowLimit = 1.3
                        local invisibleProgress = 1 - (math.min(elapsedWindow, windowLimit) / windowLimit) * (1 - 0.73)
                        if invisibleProgress <= 0.73 and not inRecoveryGrace then
                            break
                        end
                        barSet(1, inRecoveryGrace and "GRAB ON RECOVERY" or "GRAB NOW")
                    else
                        local elapsed = tick() - startTime
                        if elapsed > (A.holdMax or 2.6) and not inRecoveryGrace then
                            break
                        end
                        barSet(
                            math.min(1, elapsed / (A.holdMax or 2.6)),
                            inRecoveryGrace and "GRAB ON RECOVERY" or "STEALING"
                        )
                    end
                    if distToAnimal(animalData) <= (tonumber(A.radius) or 10) then
                        if not _G.PulseSoftStealEnabled then
                            barSet(1, "STEALING")
                        end
                        if not alreadyInRange and not inRecoveryGrace then
                            task.wait(A.entryDelay or 0.3)
                        end
                        controller = _G.PulseSemiRagdollStealController
                        local stillRagdolled = _G.PulseSemiRagdollStealEnabled == true
                                and controller
                                and controller.active == true
                            or false
                        if
                            A.enabled
                            and selectedStealMode == "Semi"
                            and canStillGrabSemi(prompt, animalData)
                            and not stillRagdolled
                        then
                            for _, fn in ipairs(data.triggerCallbacks) do
                                task.spawn(function()
                                    pcall(fn)
                                end)
                            end
                            pcall(function()
                                if _G.AutoCarrySpeed and _G.AutoCarrySpeed.WatchPickup then
                                    _G.AutoCarrySpeed.WatchPickup(1.25)
                                end
                            end)
                            fired = true
                        end
                        break
                    end
                end
                task.wait()
            end
            A.state.lastResult = fired and ("Stole " .. tostring(A.state.label))
                or ("Missed window: " .. tostring(A.state.label))
            A.state.active = false
            A.state.phase = "idle"
            A.state.lastResultTime = tick()
            if fired then
                barSet(1, "SUCCESS")
                task.wait(A.cooldown or 0.05)
            else
                barReset()
                task.wait(A.cooldown or 0.05)
            end
            data.ready = true
            barReset()
        end)
        return true
    end
    local function ensureScanThread()
        if A.scanThread then
            return
        end
        A.scanThread = task.spawn(function()
            while _G.PulseSemiSteal do
                if A.enabled or selectedStealMode == "Semi" then
                    pcall(scanAllPlots)
                end
                task.wait(5)
            end
        end)
    end
    _G.PulseSemiAutoStealSetRadius = function(v)
        local n = tonumber(v)
        if n then
            A.radius = n
        end
    end
    _G.PulseSemiAutoStealStop = function()
        A.enabled = false
        if A.conn then
            A.conn:Disconnect()
            A.conn = nil
        end
        A.state.active = false
        A.state.phase = "idle"
        barReset()
    end
    _G.PulseSemiAutoStealStart = function()
        A.radius = tonumber(autoStealRadius) or A.radius or 10
        A.enabled = true
        ensureSync()
        ensureScanThread()
        pcall(scanAllPlots)
        if A.conn then
            A.conn:Disconnect()
            A.conn = nil
        end
        A.conn = RunService.Heartbeat:Connect(function()
            if not A.enabled then
                return
            end
            if selectedStealMode ~= "Semi" then
                _G.PulseSemiAutoStealStop()
                return
            end
            if A.state.active then
                return
            end
            local target = pickClosest()
            if not target then
                return
            end
            local prompt = findPromptForAnimal(target)
            if prompt then
                executeSemi(prompt, target)
            end
        end)
    end
    _G.PulseSemiAutoStealSync = function()
        if selectedStealMode == "Semi" and autoStealEnabled then
            _G.PulseSemiAutoStealStart()
        else
            _G.PulseSemiAutoStealStop()
        end
    end
end
_G.__PulseSetupSemiAutoSteal()
_G.__PulseSetupNormalV2AutoSteal = function()
    _G.PulseNormalV2Steal = _G.PulseNormalV2Steal or {}
    local A = _G.PulseNormalV2Steal
    if A.conn then
        pcall(function()
            A.conn:Disconnect()
        end)
        A.conn = nil
    end
    if A.progressConn then
        pcall(function()
            A.progressConn:Disconnect()
        end)
        A.progressConn = nil
    end
    A.enabled = false
    A.isStealing = false
    A.stealStartTime = 0
    A.paused = false
    A.pauseStarted = nil
    A.pausedDuration = 0
    A.data = A.data or {}
    A.duration = 1.3
    A.radius = tonumber(autoStealRadius) or 62
    local function barSet(p, label)
        pcall(function()
            if _G.StealBar then
                _G.StealBar.SetState(label or "STEALING")
                _G.StealBar.SetProgress(math.clamp(tonumber(p) or 0, 0, 1))
            end
        end)
    end
    local function barReset()
        pcall(function()
            if _G.StealBar then
                _G.StealBar.Reset()
            end
        end)
    end
    local function getDetectedPlayerSpeed()
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local speed = 0
        if root then
            local v = root.AssemblyLinearVelocity or root.Velocity
            speed = Vector3.new(v.X, 0, v.Z).Magnitude
        elseif hum then
            speed = hum.WalkSpeed or 0
        end
        if speed >= 40 then
            A.lastSpeed = speed
        end
        return A.lastSpeed or 62
    end
    local function getAutoGrabRadius()
        local r
        if _G.PulseAutoRadiusEnabled == true then
            r = math.clamp(getDetectedPlayerSpeed() + 1, 1, 500)
        else
            r = tonumber(autoStealRadius) or A.radius or 62
        end
        return math.clamp(r, 1, 500)
    end
    local function getAutoGrabPauseFraction()
        return 0.75
    end
    local function isMyPlotByName(plotName)
        local plots = workspace:FindFirstChild("Plots")
        if not plots then
            return false
        end
        local plot = plots:FindFirstChild(plotName)
        if not plot then
            return false
        end
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local yb = sign:FindFirstChild("YourBase")
            if yb and yb:IsA("BillboardGui") then
                return yb.Enabled == true
            end
            local frame = sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Frame")
            local label = frame and frame:FindFirstChild("TextLabel")
            if label then
                local owner = label.Text:gsub("'s [Bb]ase$", ""):gsub("%s+$", "")
                if LP.DisplayName and owner == LP.DisplayName then
                    return true
                end
                if LP.Name and owner == LP.Name then
                    return true
                end
            end
        end
        return false
    end
    local function findNearestPrompt()
        local char = LP.Character
        if not char then
            return nil
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then
            return nil
        end
        local plots = workspace:FindFirstChild("Plots")
        if not plots then
            return nil
        end
        local activeRadius = getAutoGrabRadius()
        local nearest, dist = nil, math.huge
        for _, plot in ipairs(plots:GetChildren()) do
            if not isMyPlotByName(plot.Name) then
                local pods = plot:FindFirstChild("AnimalPodiums")
                if pods then
                    for _, pod in ipairs(pods:GetChildren()) do
                        local base = pod:FindFirstChild("Base")
                        local sp = base and base:FindFirstChild("Spawn")
                        if sp then
                            local d = (sp.Position - root.Position).Magnitude
                            if d <= activeRadius and d < dist then
                                local att = sp:FindFirstChild("PromptAttachment")
                                if att then
                                    for _, prompt in ipairs(att:GetChildren()) do
                                        if
                                            prompt:IsA("ProximityPrompt") and tostring(prompt.ActionText):find("Steal")
                                        then
                                            nearest, dist = prompt, d
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return nearest
    end
    local function executeSteal(prompt)
        if A.isStealing then
            return
        end
        if not prompt then
            return
        end
        if not A.data[prompt] then
            A.data[prompt] = { hold = {}, trigger = {}, ready = true }
            if getconnections then
                local okHold, holds = pcall(getconnections, prompt.PromptButtonHoldBegan)
                if okHold and type(holds) == "table" then
                    for _, c in ipairs(holds) do
                        if c.Function then
                            table.insert(A.data[prompt].hold, c.Function)
                        end
                    end
                end
                local okTrig, triggers = pcall(getconnections, prompt.Triggered)
                if okTrig and type(triggers) == "table" then
                    for _, c in ipairs(triggers) do
                        if c.Function then
                            table.insert(A.data[prompt].trigger, c.Function)
                        end
                    end
                end
            end
        end
        local data = A.data[prompt]
        if not data.ready then
            return
        end
        data.ready = false
        A.isStealing = true
        A.stealStartTime = tick()
        A.paused = false
        A.pauseStarted = nil
        A.pausedDuration = 0
        barSet(0, "STEALING")
        local targetPart = prompt:FindFirstAncestorWhichIsA("BasePart")
        local restarting = false
        local pauseFraction = getAutoGrabPauseFraction()
        local finishFraction = 1 - pauseFraction
        local function modeStillActive()
            return A.enabled and selectedStealMode == "Normal V2" and A.isStealing
        end
        local function isTargetInCurrentRadius()
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local radius = getAutoGrabRadius()
            return root
                and targetPart
                and targetPart.Parent
                and (root.Position - targetPart.Position).Magnitude <= radius
        end
        local function isCloseEnoughToGrab()
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local closeRange = math.min(getAutoGrabRadius(), 9)
            return root
                and targetPart
                and targetPart.Parent
                and (root.Position - targetPart.Position).Magnitude <= closeRange
        end
        local function canStillGrab()
            if not prompt or not prompt.Parent or not targetPart or not targetPart.Parent then
                return false
            end
            if not prompt.Enabled then
                return false
            end
            if not tostring(prompt.ActionText):lower():find("steal", 1, true) then
                return false
            end
            return isTargetInCurrentRadius()
        end
        local function restartFromZero()
            if restarting then
                return
            end
            restarting = true
            A.paused = false
            A.pauseStarted = nil
            A.pausedDuration = 0
            if A.progressConn then
                A.progressConn:Disconnect()
                A.progressConn = nil
            end
            barReset()
            data.ready = true
            A.isStealing = false
        end
        if A.progressConn then
            A.progressConn:Disconnect()
        end
        A.progressConn = RunService.Heartbeat:Connect(function()
            if not A.isStealing then
                if A.progressConn then
                    A.progressConn:Disconnect()
                    A.progressConn = nil
                end
                return
            end
            if not modeStillActive() or not canStillGrab() then
                restartFromZero()
                return
            end
            local elapsed = tick() - A.stealStartTime - (A.pausedDuration or 0)
            if A.paused and A.pauseStarted then
                elapsed = A.pauseStarted - A.stealStartTime - (A.pausedDuration or 0)
            end
            barSet(math.clamp(elapsed / (A.duration or 1.3), 0, 1), "STEALING")
        end)
        task.spawn(function()
            for _, fn in ipairs(data.hold) do
                task.spawn(fn)
            end
            if #data.hold == 0 and #data.trigger == 0 and fireproximityprompt then
                pcall(function()
                    fireproximityprompt(prompt, A.duration or 1.3)
                end)
            end
            local holdStart = tick()
            while tick() - holdStart < (A.duration or 1.3) * pauseFraction do
                if not modeStillActive() or not canStillGrab() then
                    restartFromZero()
                    return
                end
                task.wait()
            end
            A.paused = true
            A.pauseStarted = tick()
            local wasAbleToGrab = false
            local waitStart = tick()
            while modeStillActive() do
                if not canStillGrab() then
                    restartFromZero()
                    return
                end
                local isBrainrot = tostring(prompt.Parent and prompt.Parent.Parent and prompt.Parent.Parent.Name or "")
                    :lower()
                    :find("brainrot")
                if isCloseEnoughToGrab() then
                    if isBrainrot or (tick() - waitStart >= 0.8) then
                        wasAbleToGrab = true
                        break
                    end
                end
                task.wait()
            end
            if not modeStillActive() or not canStillGrab() then
                restartFromZero()
                return
            end
            if wasAbleToGrab then
                A.pausedDuration = (A.pausedDuration or 0) + (tick() - A.pauseStarted)
                A.paused = false
                A.pauseStarted = nil
                local finishStart = tick()
                while tick() - finishStart < (A.duration or 1.3) * finishFraction do
                    if not modeStillActive() or not canStillGrab() or not isCloseEnoughToGrab() then
                        restartFromZero()
                        return
                    end
                    task.wait()
                end
                for _, fn in ipairs(data.trigger) do
                    task.spawn(fn)
                end
                pcall(function()
                    if _G.AutoCarrySpeed and _G.AutoCarrySpeed.WatchPickup then
                        _G.AutoCarrySpeed.WatchPickup(1.25)
                    end
                end)
                if A.progressConn then
                    A.progressConn:Disconnect()
                    A.progressConn = nil
                end
                barSet(1, "SUCCESS")
                task.wait(0.05)
                barReset()
                data.ready = true
                A.isStealing = false
            else
                restartFromZero()
            end
        end)
    end
    _G.PulseNormalV2AutoStealSetRadius = function(v)
        local n = tonumber(v)
        if n then
            A.radius = n
        end
    end
    _G.PulseNormalV2AutoStealStop = function()
        A.enabled = false
        A.isStealing = false
        A.paused = false
        A.pauseStarted = nil
        A.pausedDuration = 0
        if A.conn then
            A.conn:Disconnect()
            A.conn = nil
        end
        if A.progressConn then
            A.progressConn:Disconnect()
            A.progressConn = nil
        end
        barReset()
    end
    _G.PulseNormalV2AutoStealStart = function()
        A.radius = tonumber(autoStealRadius) or A.radius or 62
        A.duration = 1.3
        A.enabled = true
        if A.conn then
            A.conn:Disconnect()
            A.conn = nil
        end
        A.conn = RunService.Heartbeat:Connect(function()
            if not A.enabled then
                return
            end
            if selectedStealMode ~= "Normal V2" then
                _G.PulseNormalV2AutoStealStop()
                return
            end
            if A.isStealing then
                return
            end
            local target = findNearestPrompt()
            if target then
                executeSteal(target)
            end
        end)
    end
    _G.PulseNormalV2AutoStealSync = function()
        if selectedStealMode == "Normal V2" and autoStealEnabled then
            _G.PulseNormalV2AutoStealStart()
        else
            _G.PulseNormalV2AutoStealStop()
        end
    end
end
_G.__PulseSetupNormalV2AutoSteal()
_G.PulseAutoStealSync = function()
    if not autoStealEnabled then
        if _G.PulseNormalAutoStealStop then
            _G.PulseNormalAutoStealStop()
        end
        if _G.PulseSemiAutoStealStop then
            _G.PulseSemiAutoStealStop()
        end
        if _G.PulseNormalV2AutoStealStop then
            _G.PulseNormalV2AutoStealStop()
        end
        return
    end
    if selectedStealMode == "Normal" then
        if _G.PulseSemiAutoStealStop then
            _G.PulseSemiAutoStealStop()
        end
        if _G.PulseNormalV2AutoStealStop then
            _G.PulseNormalV2AutoStealStop()
        end
        if _G.PulseNormalAutoStealSync then
            _G.PulseNormalAutoStealSync()
        end
    elseif selectedStealMode == "Semi" then
        if _G.PulseNormalAutoStealStop then
            _G.PulseNormalAutoStealStop()
        end
        if _G.PulseNormalV2AutoStealStop then
            _G.PulseNormalV2AutoStealStop()
        end
        if _G.PulseSemiAutoStealSync then
            _G.PulseSemiAutoStealSync()
        end
    elseif selectedStealMode == "Normal V2" then
        if _G.PulseNormalAutoStealStop then
            _G.PulseNormalAutoStealStop()
        end
        if _G.PulseSemiAutoStealStop then
            _G.PulseSemiAutoStealStop()
        end
        if _G.PulseNormalV2AutoStealSync then
            _G.PulseNormalV2AutoStealSync()
        end
    end
end
do
    local controller = _G.PulseSemiRagdollStealController or {}
    _G.PulseSemiRagdollStealController = controller
    if controller.connection then
        pcall(function()
            controller.connection:Disconnect()
        end)
    end
    controller.active = false
    controller.recoveredAt = 0
    controller.stableRecoveryFrames = 0
    local function isActuallyRagdolled()
        local char = LP.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local state = humanoid and humanoid:GetState()
        local stateRagdolled = humanoid
                and (humanoid.PlatformStand or state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown)
            or false
        local endTime = tonumber(LP:GetAttribute("RagdollEndTime"))
        local remaining = endTime and (endTime - workspace:GetServerTimeNow()) or nil
        local attributeRagdolled = remaining ~= nil and remaining > 0 and remaining <= 10
        return stateRagdolled or attributeRagdolled
    end
    local function finishSemiRagdoll(recovered)
        controller.active = false
        controller.stableRecoveryFrames = 0
        controller.recoveredAt = recovered and tick() or 0
    end
    local function beginSemiRagdoll()
        if controller.active then
            return
        end
        controller.active = true
        controller.recoveredAt = 0
        controller.stableRecoveryFrames = 0
    end
    controller.cancel = function()
        finishSemiRagdoll(false)
    end
    controller.isRagdolled = isActuallyRagdolled
    controller.connection = RunService.Heartbeat:Connect(function()
        if _G.PulseHubRuntimeGeneration ~= PULSE_RUNTIME_GENERATION then
            if controller.connection then
                controller.connection:Disconnect()
                controller.connection = nil
            end
            return
        end
        local eligible = _G.PulseSemiRagdollStealEnabled == true
            and selectedStealMode == "Semi"
            and autoStealEnabled == true
        local ragdolled = isActuallyRagdolled()
        if eligible and ragdolled then
            if not controller.active then
                beginSemiRagdoll()
            end
            controller.stableRecoveryFrames = 0
        elseif controller.active then
            if not eligible then
                finishSemiRagdoll(false)
            else
                controller.stableRecoveryFrames = (controller.stableRecoveryFrames or 0) + 1
                if controller.stableRecoveryFrames >= 2 then
                    finishSemiRagdoll(true)
                end
            end
        end
    end)
end
do
    local pause = _G.PulseNormalAutoStealRagdollPause or {}
    _G.PulseNormalAutoStealRagdollPause = pause
    pause.token = (tonumber(pause.token) or 0) + 1
    pause.active = false
    pause.resumeWanted = false
    pause.lastDetected = 0
    if pause.stateConnection then
        pcall(function()
            pause.stateConnection:Disconnect()
        end)
    end
    if pause.platformConnection then
        pcall(function()
            pause.platformConnection:Disconnect()
        end)
    end
    if pause.characterConnection then
        pcall(function()
            pause.characterConnection:Disconnect()
        end)
    end
    if pause.attributeConnection then
        pcall(function()
            pause.attributeConnection:Disconnect()
        end)
    end
    pause.stateConnection = nil
    pause.platformConnection = nil
    pause.characterConnection = nil
    pause.attributeConnection = nil
    local function applyAutoStealState(on)
        autoStealEnabled = on == true
        if setAutoStealVisual then
            setAutoStealVisual(autoStealEnabled)
        end
        if _G.PulseAutoStealSync then
            _G.PulseAutoStealSync()
        end
    end
    local function cancelPause(restore)
        local shouldRestore = restore == true and pause.active == true and pause.resumeWanted == true
        pause.token = (tonumber(pause.token) or 0) + 1
        pause.active = false
        pause.resumeWanted = false
        if shouldRestore then
            applyAutoStealState(true)
        end
    end
    local function pauseForRagdoll()
        if pause.active then
            return
        end
        if _G.PulseNormalRagdollStealEnabled ~= true then
            return
        end
        if selectedStealMode ~= "Normal" or autoStealEnabled ~= true then
            return
        end
        local now = tick()
        if now - (pause.lastDetected or 0) < 0.25 then
            return
        end
        pause.lastDetected = now
        pause.token = (tonumber(pause.token) or 0) + 1
        local token = pause.token
        pause.active = true
        pause.resumeWanted = true
        applyAutoStealState(false)
        task.delay(1.38, function()
            if _G.PulseHubRuntimeGeneration ~= PULSE_RUNTIME_GENERATION then
                return
            end
            if pause.token ~= token or pause.active ~= true then
                return
            end
            local shouldResume = pause.resumeWanted == true and selectedStealMode == "Normal"
            pause.active = false
            pause.resumeWanted = false
            if shouldResume then
                applyAutoStealState(true)
            end
        end)
    end
    local function hookCharacter(character)
        if character ~= LP.Character then
            return
        end
        if pause.stateConnection then
            pcall(function()
                pause.stateConnection:Disconnect()
            end)
            pause.stateConnection = nil
        end
        if pause.platformConnection then
            pcall(function()
                pause.platformConnection:Disconnect()
            end)
            pause.platformConnection = nil
        end
        local humanoid = character
            and (character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 4))
        if not humanoid or character ~= LP.Character then
            return
        end
        pause.stateConnection = humanoid.StateChanged:Connect(function(_, newState)
            if
                newState == Enum.HumanoidStateType.Physics
                or newState == Enum.HumanoidStateType.Ragdoll
                or newState == Enum.HumanoidStateType.FallingDown
            then
                pauseForRagdoll()
            end
        end)
        pause.platformConnection = humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(function()
            if humanoid.PlatformStand then
                pauseForRagdoll()
            end
        end)
        local currentState = humanoid:GetState()
        if
            humanoid.PlatformStand
            or currentState == Enum.HumanoidStateType.Physics
            or currentState == Enum.HumanoidStateType.Ragdoll
            or currentState == Enum.HumanoidStateType.FallingDown
        then
            task.defer(pauseForRagdoll)
        end
    end
    local function checkRagdollAttribute()
        local endTime = tonumber(LP:GetAttribute("RagdollEndTime"))
        local remaining = endTime and (endTime - workspace:GetServerTimeNow()) or nil
        if remaining and remaining > 0 and remaining <= 10 then
            pauseForRagdoll()
        end
    end
    pause.cancel = cancelPause
    pause.trigger = pauseForRagdoll
    pause.hookCharacter = hookCharacter
    pause.characterConnection = LP.CharacterAdded:Connect(function(character)
        task.defer(hookCharacter, character)
    end)
    pause.attributeConnection = LP:GetAttributeChangedSignal("RagdollEndTime"):Connect(checkRagdollAttribute)
    if LP.Character then
        task.defer(hookCharacter, LP.Character)
    end
    task.defer(checkRagdollAttribute)
end
task.spawn(function()
    while true do
        task.wait(30)
        if _G.PulseHubRuntimeGeneration ~= PULSE_RUNTIME_GENERATION then
            break
        end
        savePulseConfig()
    end
end)
local lastMoveDir = Vector3.new(0, 0, 0)
local function getCurrentSpeedValue()
    if currentSpeedMode == "Carry" then
        return CS
    elseif currentSpeedMode == "Lagger" then
        return LAGGER_SPEED
    elseif currentSpeedMode == "Lagger Carry" then
        return LAGGER_CARRY_SPEED
    elseif currentSpeedMode == "Lagger 2" then
        return LAGGER2_SPEED
    elseif currentSpeedMode == "Lagger Carry 2" then
        return LAGGER2_CARRY_SPEED
    end
    return NS
end
local refreshSpeedModeRows = nil
local function isCarryName(name)
    local n = tostring(name or ""):lower()
    return n:find("brainrot")
        or n:find("animal")
        or n:find("carry")
        or n:find("grab")
        or n:find("steal")
        or n:find("hold")
end
local function isIgnoredCarryTool(name)
    local n = tostring(name or ""):lower()
    return n:find("bat") or n:find("slap") or n:find("medusa") or n:find("head") or n:find("stone")
end
local function isCarryingBrainrot(char)
    if not char then
        return false
    end
    if
        LP:GetAttribute("Carrying") == true
        or LP:GetAttribute("IsCarrying") == true
        or char:GetAttribute("Carrying") == true
        or char:GetAttribute("IsCarrying") == true
    then
        return true
    end
    for _, name in ipairs({
        "Carrying",
        "IsCarrying",
        "Grabbed",
        "Holding",
        "StealHold",
        "HasGrab",
        "HasBrainrot",
        "Brainrot",
        "CarriedBrainrot",
    }) do
        local v = char:FindFirstChild(name, true)
        if v then
            if v:IsA("BoolValue") and v.Value then
                return true
            end
            if v:IsA("ObjectValue") and v.Value then
                return true
            end
            if v:IsA("StringValue") and v.Value ~= "" then
                return true
            end
            if v:IsA("Folder") and #v:GetChildren() > 0 then
                return true
            end
        end
    end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and not isIgnoredCarryTool(child.Name) then
            return true
        end
        if child:IsA("Model") and child:FindFirstChildWhichIsA("BasePart", true) then
            return true
        end
        if child:IsA("BasePart") and child.Name:lower():find("brainrot") then
            return true
        end
        if child:IsA("ObjectValue") and child.Value and child.Value:IsA("Model") then
            return true
        end
    end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Tool") and desc.Parent == char and not isIgnoredCarryTool(desc.Name) then
            return true
        end
        if desc:IsA("Motor6D") or desc:IsA("Weld") or desc:IsA("WeldConstraint") then
            local part0 = desc.Part0
            local part1 = desc.Part1
            if part0 and part1 then
                local m0 = part0:IsDescendantOf(char)
                local m1 = part1:IsDescendantOf(char)
                if m0 ~= m1 then
                    local external = m0 and part1 or part0
                    if
                        external
                        and external:IsA("BasePart")
                        and external.Parent
                        and not external:IsDescendantOf(char)
                    then
                        return true
                    end
                    if
                        external
                        and external.Parent
                        and external.Parent:IsA("Model")
                        and external.Parent:FindFirstChildWhichIsA("BasePart", true)
                    then
                        return true
                    end
                end
            end
        end
    end
    return false
end
local function setSpeedMode(mode)
    local holding = isCarryingBrainrot(LP.Character)
    if holding then
        if mode == "Normal" then
            mode = "Carry"
        elseif mode == "Lagger" then
            mode = "Lagger Carry"
        elseif mode == "Lagger 2" then
            mode = "Lagger Carry 2"
        elseif mode == "Carry" or mode == "Lagger Carry" or mode == "Lagger Carry 2" then
        else
            mode = "Lagger Carry"
        end
        if mode ~= currentSpeedMode and (mode == "Carry" or mode:find("Carry")) then
        end
    end
    if
        mode ~= "Normal"
        and mode ~= "Carry"
        and mode ~= "Lagger"
        and mode ~= "Lagger Carry"
        and mode ~= "Lagger 2"
        and mode ~= "Lagger Carry 2"
    then
        mode = "Normal"
    end
    if holding and (mode == "Normal" or mode == "Lagger" or mode == "Lagger 2") then
        mode = (mode == "Normal" and "Carry") or (mode == "Lagger" and "Lagger Carry") or "Lagger Carry 2"
    end
    currentSpeedMode = mode
    if State and not State._autoCarryInternalSwitch and autoCarrySpeedEnabled == true then
        State._manualSpeedOverride = true
        if State._autoCarryFromSteal then
            State._autoCarryFromSteal = false
            State._waitingForCarryPickup = false
            State._autoCarryGraceUntil = 0
            State._carryPickupWatchUntil = 0
            State._autoCarryReturnMode = nil
        end
    end
    if refreshSpeedModeRows then
        refreshSpeedModeRows()
    end
    savePulseConfig()
end
local function toggleCarryMode()
    if isCarryingBrainrot(LP.Character) then
        if currentSpeedMode == "Lagger Carry" or currentSpeedMode == "Lagger Carry 2" then
            setSpeedMode("Carry")
        else
            pcall(function()
                _safeNotify("BLOCKED: Normal disabled while holding")
            end)
            return
        end
        return
    end
    if currentSpeedMode == "Lagger" or currentSpeedMode == "Lagger Carry" then
        setSpeedMode("Carry")
    elseif currentSpeedMode == "Carry" then
        setSpeedMode("Normal")
    else
        setSpeedMode("Carry")
    end
end
local function cycleLaggerMode()
    local char = LP.Character
    local cycle = _G.PulseLaggerCycleOrder or { "Lagger Carry", "Lagger Carry 2", "Lagger", "Lagger 2" }
    local function getNextMode(current)
        local idx = 1
        for i, m in ipairs(cycle) do
            if m == current then
                idx = i
                break
            end
        end
        local nextIdx = (idx % #cycle) + 1
        return cycle[nextIdx]
    end
    if isCarryingBrainrot(char) then
        local carryOnlyCycle = {}
        for _, m in ipairs(cycle) do
            if m == "Lagger Carry" or m == "Lagger Carry 2" then
                table.insert(carryOnlyCycle, m)
            end
        end
        if #carryOnlyCycle == 0 then
            carryOnlyCycle = { "Lagger Carry", "Lagger Carry 2" }
        end
        local idx = 1
        for i, m in ipairs(carryOnlyCycle) do
            if m == currentSpeedMode then
                idx = i
                break
            end
        end
        local nextIdx = (idx % #carryOnlyCycle) + 1
        setSpeedMode(carryOnlyCycle[nextIdx])
    else
        setSpeedMode(getNextMode(currentSpeedMode))
    end
end
State = State or {}
State.normalSpeed = NS
State.carrySpeed = CS
State.laggerSpeed = LAGGER_SPEED
State.speedToggled = (
    currentSpeedMode == "Carry"
    or currentSpeedMode == "Lagger Carry"
    or currentSpeedMode == "Lagger Carry 2"
)
State.laggerEnabled = (
    currentSpeedMode == "Lagger"
    or currentSpeedMode == "Lagger Carry"
    or currentSpeedMode == "Lagger 2"
    or currentSpeedMode == "Lagger Carry 2"
)
toggleRefs = toggleRefs or {}
function setCarry(on)
    if isCarryingBrainrot(LP.Character) then
        if on then
            setSpeedMode("Carry")
        else
            pcall(function()
                _safeNotify("BLOCKED: Normal disabled while holding")
            end)
            return
        end
        State.speedToggled = true
        return
    end
    if on then
        setSpeedMode("Carry")
    else
        if
            currentSpeedMode == "Carry"
            or currentSpeedMode == "Lagger Carry"
            or currentSpeedMode == "Lagger Carry 2"
        then
            setSpeedMode("Normal")
        end
    end
    State.speedToggled = on == true
end
function setLagger(on)
    if isCarryingBrainrot(LP.Character) then
        if on then
            setSpeedMode("Lagger Carry")
        else
            pcall(function()
                _safeNotify("BLOCKED: Lagger Normal disabled while holding")
            end)
            return
        end
        State.laggerEnabled = true
        return
    end
    if on then
        setSpeedMode("Lagger")
    else
        if
            currentSpeedMode == "Lagger"
            or currentSpeedMode == "Lagger Carry"
            or currentSpeedMode == "Lagger 2"
            or currentSpeedMode == "Lagger Carry 2"
        then
            setSpeedMode("Normal")
        end
    end
    State.laggerEnabled = on == true
end
State = State or {}
State.normalSpeed = State.normalSpeed or 59
State.carrySpeed = State.carrySpeed or 30
State.laggerSpeed = State.laggerSpeed or 60
State.speedToggled = State.speedToggled or false
State.laggerEnabled = State.laggerEnabled or false
State._autoCarryFromSteal = State._autoCarryFromSteal or false
State._autoCarryGraceUntil = State._autoCarryGraceUntil or 0
State._waitingForCarryPickup = State._waitingForCarryPickup or false
State._carryPickupWatchUntil = State._carryPickupWatchUntil or 0
State._autoCarryReturnMode = State._autoCarryReturnMode or nil
State._manualSpeedOverride = State._manualSpeedOverride == true
State._autoCarryInternalSwitch = false
toggleRefs = toggleRefs or {}
local function safeSaveConfig()
    if type(saveConfig) == "function" then
        task.spawn(saveConfig)
    end
end
local function setCarrySpeedMode(on)
    State.speedToggled = on
    if toggleRefs.carryMode then
        toggleRefs.carryMode(on)
    end
    if type(setCarry) == "function" then
        setCarry(on)
    end
end
local function setLaggerMode(on)
    State.laggerEnabled = on
    if toggleRefs.laggerMode then
        toggleRefs.laggerMode(on)
    end
    if type(setLagger) == "function" then
        setLagger(on)
    end
end
local function enableCarrySpeedForSteal()
    State._waitingForCarryPickup = false
    State._carryPickupWatchUntil = 0
    if not State._autoCarryFromSteal then
        State._autoCarryReturnMode = currentSpeedMode
    end
    State._autoCarryFromSteal = true
    State._autoCarryGraceUntil = tick() + 0.75
    local wasLagger2 = (
        State._autoCarryReturnMode == "Lagger 2"
        or State._autoCarryReturnMode == "Lagger Carry 2"
        or currentSpeedMode == "Lagger 2"
        or currentSpeedMode == "Lagger Carry 2"
    )
    local wasLagger = (
        State._autoCarryReturnMode == "Lagger"
        or State._autoCarryReturnMode == "Lagger Carry"
        or currentSpeedMode == "Lagger"
        or currentSpeedMode == "Lagger Carry"
    )
    State._autoCarryInternalSwitch = true
    if wasLagger2 then
        State.laggerEnabled = true
        State.speedToggled = true
        if toggleRefs.laggerMode then
            toggleRefs.laggerMode(false)
        end
        if toggleRefs.carryMode then
            toggleRefs.carryMode(false)
        end
        setSpeedMode("Lagger Carry 2")
    elseif wasLagger then
        State.laggerEnabled = true
        State.speedToggled = true
        if toggleRefs.laggerMode then
            toggleRefs.laggerMode(true)
        end
        if toggleRefs.carryMode then
            toggleRefs.carryMode(true)
        end
        setSpeedMode("Lagger Carry")
    else
        setLaggerMode(false)
        setCarrySpeedMode(true)
    end
    State._autoCarryInternalSwitch = false
    safeSaveConfig()
end
local function disableAutoCarrySpeed()
    if not State._autoCarryFromSteal and not State._waitingForCarryPickup then
        return
    end
    local wasAutoApplied = State._autoCarryFromSteal == true
    local returnMode = State._autoCarryReturnMode
    State._autoCarryFromSteal = false
    State._waitingForCarryPickup = false
    State._autoCarryGraceUntil = 0
    State._carryPickupWatchUntil = 0
    State._autoCarryReturnMode = nil
    if not wasAutoApplied then
        return
    end
    State._autoCarryInternalSwitch = true
    if returnMode == "Lagger 2" or returnMode == "Lagger Carry 2" then
        State.laggerEnabled = true
        State.speedToggled = false
        if toggleRefs.laggerMode then
            toggleRefs.laggerMode(false)
        end
        if toggleRefs.carryMode then
            toggleRefs.carryMode(false)
        end
        setSpeedMode("Lagger 2")
    elseif returnMode == "Lagger" or returnMode == "Lagger Carry" then
        State.laggerEnabled = true
        State.speedToggled = false
        if toggleRefs.laggerMode then
            toggleRefs.laggerMode(true)
        end
        if toggleRefs.carryMode then
            toggleRefs.carryMode(false)
        end
        setSpeedMode("Lagger")
    elseif returnMode == "Carry" then
        State.laggerEnabled = false
        State.speedToggled = true
        if toggleRefs.laggerMode then
            toggleRefs.laggerMode(false)
        end
        if toggleRefs.carryMode then
            toggleRefs.carryMode(true)
        end
        setSpeedMode("Carry")
    else
        setLaggerMode(false)
        setCarrySpeedMode(false)
    end
    State._autoCarryInternalSwitch = false
    safeSaveConfig()
end
local function startAutoCarryPickupWatch(seconds)
    if autoCarrySpeedEnabled ~= true then
        return
    end
    State._waitingForCarryPickup = true
    State._carryPickupWatchUntil = tick() + (seconds or 1.25)
end
local function isMyBasePlot(plotName)
    local plots = workspace:FindFirstChild("Plots")
    local plot = plots and plots:FindFirstChild(plotName)
    if not plot then
        return false
    end
    local sign = plot:FindFirstChild("PlotSign")
    local yourBase = sign and sign:FindFirstChild("YourBase")
    return yourBase and yourBase:IsA("BillboardGui") and yourBase.Enabled == true
end
local function getNearestEnemyBrainrotDistance(root)
    if not root then
        return math.huge
    end
    local bestDist = math.huge
    local a = _G.PulseNormalSteal
    if a and type(a.animals) == "table" and #a.animals > 0 then
        for _, data in ipairs(a.animals) do
            if data.worldPosition and not isMyBasePlot(data.plot) then
                local d = (root.Position - data.worldPosition).Magnitude
                if d < bestDist then
                    bestDist = d
                end
            end
        end
        if bestDist < math.huge then
            return bestDist
        end
    end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then
        return math.huge
    end
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") and not isMyBasePlot(plot.Name) then
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if podiums then
                for _, podium in ipairs(podiums:GetChildren()) do
                    if podium:IsA("Model") then
                        local base = podium:FindFirstChild("Base")
                        local spawn = base and base:FindFirstChild("Spawn")
                        if spawn then
                            local d = (root.Position - spawn.Position).Magnitude
                            if d < bestDist then
                                bestDist = d
                            end
                        end
                    end
                end
            end
        end
    end
    return bestDist
end
local AUTO_CARRY_BRAINROT_DISTANCE = _G.PulseAutoSwitchDistance or 5
local _stealAttrWasActive = false
if _G.PulseAutoCarryMonitorConn then
    pcall(function()
        _G.PulseAutoCarryMonitorConn:Disconnect()
    end)
end
_G.PulseAutoCarryMonitorConn = RunService.RenderStepped:Connect(function()
    State._autoCarryInternalSwitch = false
    if autoCarrySpeedEnabled ~= true then
        State._manualSpeedOverride = false
        disableAutoCarrySpeed()
        return
    end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or not root then
        State._manualSpeedOverride = false
        disableAutoCarrySpeed()
        _stealAttrWasActive = false
        return
    end
    local st = hum:GetState()
    local gotHit = st == Enum.HumanoidStateType.Physics
        or st == Enum.HumanoidStateType.Ragdoll
        or st == Enum.HumanoidStateType.FallingDown
    if gotHit then
        return
    end
    local stealingAttr = LP:GetAttribute("Stealing") == true
    local carryingBrainrot = isCarryingBrainrot(char)
    local brainrotDist = getNearestEnemyBrainrotDistance(root)
    local nearBrainrot = brainrotDist <= AUTO_CARRY_BRAINROT_DISTANCE
    if State._manualSpeedOverride and not carryingBrainrot and not nearBrainrot and not stealingAttr then
        State._manualSpeedOverride = false
    end
    if stealingAttr and not _stealAttrWasActive then
        _stealAttrWasActive = true
        if not State._manualSpeedOverride then
            enableCarrySpeedForSteal()
        end
    elseif not stealingAttr then
        _stealAttrWasActive = false
    end
    if State._waitingForCarryPickup then
        if tick() > (State._carryPickupWatchUntil or 0) then
            State._waitingForCarryPickup = false
            State._carryPickupWatchUntil = 0
        elseif (carryingBrainrot or nearBrainrot) and not State._manualSpeedOverride then
            enableCarrySpeedForSteal()
        end
    end
    if (carryingBrainrot or nearBrainrot) and not State._autoCarryFromSteal and not State._manualSpeedOverride then
        enableCarrySpeedForSteal()
    end
    if State._autoCarryFromSteal then
        local graceDone = tick() > (State._autoCarryGraceUntil or 0)
        if graceDone and not carryingBrainrot and not stealingAttr and not nearBrainrot then
            disableAutoCarrySpeed()
        end
    end
end)
_G.AutoCarrySpeed = {
    IsCarryingBrainrot = isCarryingBrainrot,
    Enable = enableCarrySpeedForSteal,
    Disable = disableAutoCarrySpeed,
    WatchPickup = startAutoCarryPickupWatch,
    Distance = getNearestEnemyBrainrotDistance,
}
local function pulseCarrySafeMode(mode)
    if mode == "Normal" then
        return "Carry"
    end
    if mode == "Lagger" then
        return "Lagger Carry"
    end
    if mode == "Lagger 2" then
        return "Lagger Carry 2"
    end
    return mode
end
if _G.PulseBrainrotCarryEnforceConn then
    pcall(function()
        _G.PulseBrainrotCarryEnforceConn:Disconnect()
    end)
end
_G.PulseBrainrotCarryEnforceConn = RunService.RenderStepped:Connect(function()
    if State._autoCarryInternalSwitch then
        return
    end
    local holding = isCarryingBrainrot(LP.Character)
    if holding and (currentSpeedMode == "Normal" or currentSpeedMode == "Lagger" or currentSpeedMode == "Lagger 2") then
        State._autoCarryInternalSwitch = true
        setSpeedMode(pulseCarrySafeMode(currentSpeedMode))
        State._autoCarryInternalSwitch = false
    end
    if _G.PulseMobileButtonRefs then
        local function setBtnLock(btnName, locked)
            local ref = _G.PulseMobileButtonRefs[btnName]
            if ref and ref.btn then
                ref.btn.AutoButtonColor = not locked
                if locked then
                    ref.btn.BackgroundTransparency = 0.55
                    ref.btn.TextTransparency = 0.45
                else
                end
            end
        end
        setBtnLock("carry", holding and currentSpeedMode == "Carry")
        setBtnLock("laggerNormal", holding)
        setBtnLock("lagger2Normal", holding)
        setBtnLock("laggerCarry", holding and currentSpeedMode == "Lagger Carry")
        setBtnLock("lagger2Carry", holding and currentSpeedMode == "Lagger Carry 2")
    end
end)
if _G.PulseBrainrotPickupConn then
    pcall(function()
        _G.PulseBrainrotPickupConn:Disconnect()
    end)
end
_G.PulseBrainrotPickupConn = LP.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    if
        isCarryingBrainrot(char)
        and (currentSpeedMode == "Normal" or currentSpeedMode == "Lagger" or currentSpeedMode == "Lagger 2")
    then
        State._autoCarryInternalSwitch = true
        setSpeedMode(pulseCarrySafeMode(currentSpeedMode))
        State._autoCarryInternalSwitch = false
    end
end)
if _G.PulseBrainrotChildConn then
    pcall(function()
        _G.PulseBrainrotChildConn:Disconnect()
    end)
end
_G.PulseBrainrotChildConn = RunService.Heartbeat:Connect(function()
    if
        isCarryingBrainrot(LP.Character)
        and (currentSpeedMode == "Normal" or currentSpeedMode == "Lagger" or currentSpeedMode == "Lagger 2")
    then
        if not State._autoCarryInternalSwitch then
            State._autoCarryInternalSwitch = true
            setSpeedMode(pulseCarrySafeMode(currentSpeedMode))
            State._autoCarryInternalSwitch = false
        end
    end
end)
_G.PulseAutoPathState = _G.PulseAutoPathState or { leftConn = nil, rightConn = nil, leftPhase = 1, rightPhase = 1 }
_G.PulseAutoPathPoints = _G.PulseAutoPathPoints
    or {
        L1 = Vector3.new(-476.48, -6.28, 92.73),
        L2 = Vector3.new(-483.12, -4.95, 94.80),
        LFace = Vector3.new(-482.25, -4.96, 92.09),
        R1 = Vector3.new(-476.16, -6.52, 25.62),
        R2 = Vector3.new(-483.06, -5.03, 25.48),
        RFace = Vector3.new(-482.06, -6.93, 35.47),
    }
function _G.PulseAutoPathSpeed()
    if currentSpeedMode == "Lagger" or currentSpeedMode == "Lagger Carry" then
        return LAGGER_SPEED
    elseif currentSpeedMode == "Lagger 2" or currentSpeedMode == "Lagger Carry 2" then
        return LAGGER2_SPEED
    end
    return NS
end
function _G.PulseStopAutoLeft()
    local S = _G.PulseAutoPathState
    if S.leftConn then
        S.leftConn:Disconnect()
        S.leftConn = nil
    end
    S.leftPhase = 1
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hum then
        hum:Move(Vector3.zero, false)
    end
    if hrp then
        local currentVel = hrp.AssemblyLinearVelocity
        applyImpulseForVelocity(hrp, Vector3.new(0, currentVel.Y, 0))
    end
end
function _G.PulseStopAutoRight()
    local S = _G.PulseAutoPathState
    if S.rightConn then
        S.rightConn:Disconnect()
        S.rightConn = nil
    end
    S.rightPhase = 1
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hum then
        hum:Move(Vector3.zero, false)
    end
    if hrp then
        local currentVel = hrp.AssemblyLinearVelocity
        applyImpulseForVelocity(hrp, Vector3.new(0, currentVel.Y, 0))
    end
end
function _G.PulseSetAutoLeft(on, skipSave)
    autoLeftEnabled = on and true or false
    if _G.PulseSetAutoLeftVisual then
        _G.PulseSetAutoLeftVisual(autoLeftEnabled)
    end
    if autoLeftEnabled then
        autoRightEnabled = false
        if _G.PulseSetAutoRightVisual then
            _G.PulseSetAutoRightVisual(false)
        end
        if _G.PulseStopAutoRight then
            _G.PulseStopAutoRight()
        end
        if _G.PulseAntiBypassAimbotOn and _G.PulseStopAntiBypassAimbot then
            _G.PulseStopAntiBypassAimbot(false)
        end
        if _G.PulseAntiDesyncAimbotOn and _G.PulseStopAntiDesyncAimbot then
            _G.PulseStopAntiDesyncAimbot()
        end
        if _G.PulseRefreshAimbotVisual then
            _G.PulseRefreshAimbotVisual()
        end
        if _G.PulseStartAutoLeft then
            _G.PulseStartAutoLeft()
        end
    else
        if _G.PulseStopAutoLeft then
            _G.PulseStopAutoLeft()
        end
    end
    if not skipSave then
        savePulseConfig()
    end
end
function _G.PulseSetAutoRight(on, skipSave)
    autoRightEnabled = on and true or false
    if _G.PulseSetAutoRightVisual then
        _G.PulseSetAutoRightVisual(autoRightEnabled)
    end
    if autoRightEnabled then
        autoLeftEnabled = false
        if _G.PulseSetAutoLeftVisual then
            _G.PulseSetAutoLeftVisual(false)
        end
        if _G.PulseStopAutoLeft then
            _G.PulseStopAutoLeft()
        end
        if _G.PulseAntiBypassAimbotOn and _G.PulseStopAntiBypassAimbot then
            _G.PulseStopAntiBypassAimbot(false)
        end
        if _G.PulseAntiDesyncAimbotOn and _G.PulseStopAntiDesyncAimbot then
            _G.PulseStopAntiDesyncAimbot()
        end
        if _G.PulseRefreshAimbotVisual then
            _G.PulseRefreshAimbotVisual()
        end
        if _G.PulseStartAutoRight then
            _G.PulseStartAutoRight()
        end
    else
        if _G.PulseStopAutoRight then
            _G.PulseStopAutoRight()
        end
    end
    if not skipSave then
        savePulseConfig()
    end
end
function _G.PulseStartAutoLeft()
    local S = _G.PulseAutoPathState
    if S.leftConn then
        S.leftConn:Disconnect()
    end
    S.leftPhase = 1
    S.leftConn = RunService.Heartbeat:Connect(function()
        if not autoLeftEnabled then
            return
        end
        local char = LP.Character
        if not char then
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then
            return
        end
        local st = hum:GetState()
        if
            hum.PlatformStand
            or st == Enum.HumanoidStateType.Physics
            or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown
        then
            hum:Move(Vector3.zero, false)
            return
        end
        local P = _G.PulseAutoPathPoints
        local spd = _G.PulseAutoPathSpeed()
        if S.leftPhase == 1 then
            local tgt = Vector3.new(P.L1.X, hrp.Position.Y, P.L1.Z)
            if (tgt - hrp.Position).Magnitude < 1 then
                S.leftPhase = 2
                local d = P.L2 - hrp.Position
                local mv = Vector3.new(d.X, 0, d.Z).Unit
                hum:Move(mv, false)
                applyImpulseForVelocity(hrp, Vector3.new(mv.X * spd, hrp.AssemblyLinearVelocity.Y, mv.Z * spd))
                return
            end
            local d = P.L1 - hrp.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum:Move(mv, false)
            applyImpulseForVelocity(hrp, Vector3.new(mv.X * spd, hrp.AssemblyLinearVelocity.Y, mv.Z * spd))
        elseif S.leftPhase == 2 then
            local tgt = Vector3.new(P.L2.X, hrp.Position.Y, P.L2.Z)
            if (tgt - hrp.Position).Magnitude < 1 then
                hum:Move(Vector3.zero, false)
                applyImpulseZero(hrp)
                autoLeftEnabled = false
                if S.leftConn then
                    S.leftConn:Disconnect()
                    S.leftConn = nil
                end
                S.leftPhase = 1
                if _G.PulseSetAutoLeftVisual then
                    _G.PulseSetAutoLeftVisual(false)
                end
                if P.LFace and (P.LFace - hrp.Position).Magnitude > 0.01 then
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(P.LFace.X, hrp.Position.Y, P.LFace.Z))
                end
                savePulseConfig()
                return
            end
            local d = P.L2 - hrp.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum:Move(mv, false)
            applyImpulseForVelocity(hrp, Vector3.new(mv.X * spd, hrp.AssemblyLinearVelocity.Y, mv.Z * spd))
        end
    end)
end
function _G.PulseStartAutoRight()
    local S = _G.PulseAutoPathState
    if S.rightConn then
        S.rightConn:Disconnect()
    end
    S.rightPhase = 1
    S.rightConn = RunService.Heartbeat:Connect(function()
        if not autoRightEnabled then
            return
        end
        local char = LP.Character
        if not char then
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then
            return
        end
        local st = hum:GetState()
        if
            hum.PlatformStand
            or st == Enum.HumanoidStateType.Physics
            or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown
        then
            hum:Move(Vector3.zero, false)
            return
        end
        local P = _G.PulseAutoPathPoints
        local spd = _G.PulseAutoPathSpeed()
        if S.rightPhase == 1 then
            local tgt = Vector3.new(P.R1.X, hrp.Position.Y, P.R1.Z)
            if (tgt - hrp.Position).Magnitude < 1 then
                S.rightPhase = 2
                local d = P.R2 - hrp.Position
                local mv = Vector3.new(d.X, 0, d.Z).Unit
                hum:Move(mv, false)
                applyImpulseForVelocity(hrp, Vector3.new(mv.X * spd, hrp.AssemblyLinearVelocity.Y, mv.Z * spd))
                return
            end
            local d = P.R1 - hrp.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum:Move(mv, false)
            applyImpulseForVelocity(hrp, Vector3.new(mv.X * spd, hrp.AssemblyLinearVelocity.Y, mv.Z * spd))
        elseif S.rightPhase == 2 then
            local tgt = Vector3.new(P.R2.X, hrp.Position.Y, P.R2.Z)
            if (tgt - hrp.Position).Magnitude < 1 then
                hum:Move(Vector3.zero, false)
                applyImpulseZero(hrp)
                autoRightEnabled = false
                if S.rightConn then
                    S.rightConn:Disconnect()
                    S.rightConn = nil
                end
                S.rightPhase = 1
                if _G.PulseSetAutoRightVisual then
                    _G.PulseSetAutoRightVisual(false)
                end
                if P.RFace and (P.RFace - hrp.Position).Magnitude > 0.01 then
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(P.RFace.X, hrp.Position.Y, P.RFace.Z))
                end
                savePulseConfig()
                return
            end
            local d = P.R2 - hrp.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum:Move(mv, false)
            applyImpulseForVelocity(hrp, Vector3.new(mv.X * spd, hrp.AssemblyLinearVelocity.Y, mv.Z * spd))
        end
    end)
end
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    if autoLeftEnabled and _G.PulseStartAutoLeft then
        _G.PulseStartAutoLeft()
    end
    if autoRightEnabled and _G.PulseStartAutoRight then
        _G.PulseStartAutoRight()
    end
end)
local overheadGui = nil
local overheadSpeedLabel = nil
local overheadExtrasRevealed = false
local function setupOverheadInfo(char)
    if overheadGui then
        pcall(function()
            overheadGui:Destroy()
        end)
        overheadGui = nil
        overheadSpeedLabel = nil
    end
    if not char then
        return
    end
    local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 5)
    if not head then
        return
    end
    overheadGui = Instance.new("BillboardGui")
    overheadGui.Name = "PulseHubOverheadInfo"
    overheadGui.Size = UDim2.new(0, 250, 0, 88)
    overheadGui.StudsOffset = Vector3.new(0, 1.75, 0)
    overheadGui.AlwaysOnTop = true
    overheadGui.LightInfluence = 0
    overheadGui.Parent = head
    ragdollCountdownLabel = Instance.new("TextLabel")
    ragdollCountdownLabel.Name = "RagdollCountdown"
    ragdollCountdownLabel.Size = UDim2.new(1, 0, 0, 26)
    ragdollCountdownLabel.Position = UDim2.new(0, 0, 0, 0)
    ragdollCountdownLabel.BackgroundTransparency = 1
    ragdollCountdownLabel.Text = ""
    ragdollCountdownLabel.Visible = false
    ragdollCountdownLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
    ragdollCountdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    ragdollCountdownLabel.TextStrokeTransparency = 0
    ragdollCountdownLabel.Font = Enum.Font.GothamBlack
    ragdollCountdownLabel.TextSize = 22
    ragdollCountdownLabel.TextXAlignment = Enum.TextXAlignment.Center
    ragdollCountdownLabel.ZIndex = 10
    ragdollCountdownLabel.Parent = overheadGui
    local discordLbl = Instance.new("TextLabel")
    discordLbl.Name = "Discord"
    discordLbl.Size = UDim2.new(1, 0, 0, 30)
    discordLbl.Position = UDim2.new(0, 0, 0, 26)
    discordLbl.BackgroundTransparency = 1
    discordLbl.Text = "discord.gg/pulsee"
    discordLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    if _G.PulseGetAccentColor then
        discordLbl.TextColor3 = _G.PulseGetAccentColor()
    end
    discordLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    discordLbl.TextStrokeTransparency = 0
    discordLbl.Font = Enum.Font.GothamBlack
    discordLbl.TextSize = 21
    discordLbl.TextXAlignment = Enum.TextXAlignment.Center
    discordLbl.ZIndex = 10
    discordLbl.Visible = overheadExtrasRevealed
    discordLbl.Parent = overheadGui
    overheadSpeedLabel = Instance.new("TextLabel")
    overheadSpeedLabel.Name = "Speed"
    overheadSpeedLabel.Size = UDim2.new(1, 0, 0, 26)
    overheadSpeedLabel.Position = UDim2.new(0, 0, 0, 54)
    overheadSpeedLabel.BackgroundTransparency = 1
    overheadSpeedLabel.Text = "Speed: 0"
    overheadSpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    if _G.PulseGetAccentColor then
        overheadSpeedLabel.TextColor3 = _G.PulseGetAccentColor()
    end
    overheadSpeedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    overheadSpeedLabel.TextStrokeTransparency = 0
    overheadSpeedLabel.Font = Enum.Font.GothamBlack
    overheadSpeedLabel.TextSize = 19
    overheadSpeedLabel.TextXAlignment = Enum.TextXAlignment.Center
    overheadSpeedLabel.ZIndex = 10
    overheadSpeedLabel.Visible = overheadExtrasRevealed
    overheadSpeedLabel.Parent = overheadGui
end
local function revealOverheadExtras()
    overheadExtrasRevealed = true
    if overheadGui then
        local d = overheadGui:FindFirstChild("Discord")
        if d then
            d.Visible = true
        end
        if overheadSpeedLabel then
            overheadSpeedLabel.Visible = true
        end
    end
    if _G.PulseRefreshOverheadAccent then
        _G.PulseRefreshOverheadAccent()
    end
end
local ragdollCountdownConn = nil
local ragdollCountdownCharConn = nil
local ragdollCountdownEndTime = 0
local RAGDOLL_COUNTDOWN_SECONDS = 2.6
function stopRagdollCountdown()
    if ragdollCountdownConn then
        ragdollCountdownConn:Disconnect()
        ragdollCountdownConn = nil
    end
    if ragdollCountdownCharConn then
        ragdollCountdownCharConn:Disconnect()
        ragdollCountdownCharConn = nil
    end
    if ragdollCountdownLabel then
        ragdollCountdownLabel.Visible = false
        ragdollCountdownLabel.Text = ""
    end
end
function hookRagdollCountdown(char)
    stopRagdollCountdown()
    if not ragdollCountdownEnabled then
        return
    end
    char = char or LP.Character
    if not char then
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 4)
    if not hum then
        return
    end
    local function beginCountdown()
        ragdollCountdownEndTime = tick() + RAGDOLL_COUNTDOWN_SECONDS
        if ragdollCountdownLabel then
            ragdollCountdownLabel.Visible = true
        end
    end
    local function isRagdollStateForCountdown()
        local st = hum:GetState()
        return hum.PlatformStand
            or st == Enum.HumanoidStateType.Physics
            or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown
    end
    ragdollCountdownCharConn = hum.StateChanged:Connect(function(_, newState)
        if
            newState == Enum.HumanoidStateType.Physics
            or newState == Enum.HumanoidStateType.Ragdoll
            or newState == Enum.HumanoidStateType.FallingDown
        then
            beginCountdown()
        end
    end)
    ragdollCountdownConn = RunService.RenderStepped:Connect(function()
        if not ragdollCountdownEnabled then
            stopRagdollCountdown()
            return
        end
        if not ragdollCountdownLabel or not ragdollCountdownLabel.Parent then
            return
        end
        if isRagdollStateForCountdown() and ragdollCountdownEndTime < tick() then
            beginCountdown()
        end
        local left = math.max(0, ragdollCountdownEndTime - tick())
        if left > 0 then
            ragdollCountdownLabel.Visible = true
            ragdollCountdownLabel.Text = string.format("RAGDOLL %.1f", left)
            if left <= 1 then
                ragdollCountdownLabel.TextColor3 = Color3.fromRGB(255, 230, 90)
            else
                ragdollCountdownLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
            end
        else
            ragdollCountdownLabel.Visible = false
            ragdollCountdownLabel.Text = ""
        end
    end)
end
if LP.Character then
    task.spawn(function()
        setupOverheadInfo(LP.Character)
    end)
end
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    setupOverheadInfo(char)
    if ragdollCountdownEnabled then
        hookRagdollCountdown(char)
    end
end)
local tpDownOnRagdollEnabled = _G.PulseTpDownOnRagdollOn == true
local tpDownOnRagdollLast = 0
local function hookTpDownOnRagdoll(char)
    local hum = char and (char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 4))
    if not hum then
        return
    end
    hum.StateChanged:Connect(function(_, newState)
        if tpDownOnRagdollEnabled ~= true then
            return
        end
        if
            newState == Enum.HumanoidStateType.Physics
            or newState == Enum.HumanoidStateType.Ragdoll
            or newState == Enum.HumanoidStateType.FallingDown
        then
            if tick() - tpDownOnRagdollLast < 0.5 then
                return
            end
            tpDownOnRagdollLast = tick()
            task.spawn(runTPFloor)
        end
    end)
end
LP.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    hookTpDownOnRagdoll(char)
end)
if LP.Character then
    hookTpDownOnRagdoll(LP.Character)
end
do
    local autoRagdollTp = _G.PulseAutoRagdollTpState
    local AUTO_RAGDOLL_TP_Z_THRESHOLD = 60
    local AUTO_RAGDOLL_TP_LEFT_2 = Vector3.new(-475.5, -3.75, 100.5)
    local AUTO_RAGDOLL_TP_LEFT_3 = Vector3.new(-486.5, -3.75, 100.5)
    local AUTO_RAGDOLL_TP_RIGHT_2 = Vector3.new(-475.50, -3.95, 17.55)
    local AUTO_RAGDOLL_TP_RIGHT_3 = Vector3.new(-486.76, -3.95, 17.55)
    local function refreshAutoRagdollTpPlot()
        local side, plotName = nil, nil
        local plots = workspace:FindFirstChild("Plots")
        if plots then
            local displayName = tostring(LP.DisplayName or "")
            local userName = tostring(LP.Name or "")
            for _, plot in ipairs(plots:GetChildren()) do
                local sign = plot:FindFirstChild("PlotSign")
                local owned = false
                local yourBase = sign and sign:FindFirstChild("YourBase")
                if yourBase and yourBase:IsA("BillboardGui") and yourBase.Enabled == true then
                    owned = true
                end
                if not owned then
                    local surface = sign and sign:FindFirstChild("SurfaceGui")
                    local frame = surface and surface:FindFirstChild("Frame")
                    local label = frame and frame:FindFirstChild("TextLabel")
                    local text = label and tostring(label.Text) or ""
                    owned = (displayName ~= "" and text:find(displayName, 1, true) ~= nil)
                        or (userName ~= "" and text:find(userName, 1, true) ~= nil)
                end
                if owned then
                    local spawnObj = plot:FindFirstChild("Spawn")
                    local spawnZ = nil
                    if spawnObj and spawnObj:IsA("BasePart") then
                        spawnZ = spawnObj.Position.Z
                    elseif spawnObj and spawnObj:IsA("Model") then
                        spawnZ = spawnObj:GetPivot().Position.Z
                    end
                    if spawnZ then
                        side = (spawnZ < AUTO_RAGDOLL_TP_Z_THRESHOLD) and "left" or "right"
                        plotName = plot.Name
                        break
                    end
                end
            end
        end
        autoRagdollTp.plotSide = side
        autoRagdollTp.plotName = plotName
        autoRagdollTp.lastPlotRefresh = tick()
        return side, plotName
    end
    local function stopAutoPathsForRagdollTp()
        local changed = false
        if autoLeftEnabled then
            autoLeftEnabled = false
            changed = true
            if _G.PulseSetAutoLeftVisual then
                _G.PulseSetAutoLeftVisual(false)
            end
            if _G.PulseStopAutoLeft then
                _G.PulseStopAutoLeft()
            end
        end
        if autoRightEnabled then
            autoRightEnabled = false
            changed = true
            if _G.PulseSetAutoRightVisual then
                _G.PulseSetAutoRightVisual(false)
            end
            if _G.PulseStopAutoRight then
                _G.PulseStopAutoRight()
            end
        end
        if changed then
            task.defer(function()
                pcall(savePulseConfig)
            end)
        end
    end
    local function runAutoRagdollReturnTeleport(side)
        if autoRagdollTp.returning or not autoRagdollTp.enabled then
            return
        end
        if side ~= "left" and side ~= "right" then
            return
        end
        autoRagdollTp.returning = true
        task.spawn(function()
            pcall(function()
                local char = LP.Character
                if not char then
                    return
                end
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not root then
                    return
                end
                local rotation = (side == "right") and math.rad(180) or 0
                local step2 = (side == "left") and AUTO_RAGDOLL_TP_LEFT_2 or AUTO_RAGDOLL_TP_RIGHT_2
                local step3 = (side == "left") and AUTO_RAGDOLL_TP_LEFT_3 or AUTO_RAGDOLL_TP_RIGHT_3
                local function teleportTo(position)
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, rotation, 0)
                    if hum then
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                        hum:Move(Vector3.zero, false)
                    end
                    for _, object in ipairs(char:GetDescendants()) do
                        if object:IsA("Motor6D") and not object.Enabled then
                            object.Enabled = true
                        end
                    end
                end
                teleportTo(step2)
                task.wait(0.1)
                teleportTo(step3)
            end)
            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                autoRagdollTp.lastHealth = hum.Health
            end
            autoRagdollTp.returning = false
        end)
    end
    local function stopAutoRagdollTp()
        autoRagdollTp.enabled = false
        local connection = autoRagdollTp.connection
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
        autoRagdollTp.connection = nil
        if _G.PulseAutoRagdollTpConnection == connection then
            _G.PulseAutoRagdollTpConnection = nil
        end
        if autoRagdollTp.setVisual then
            autoRagdollTp.setVisual(false)
        end
    end
    local function startAutoRagdollTp()
        autoRagdollTp.enabled = true
        if autoRagdollTp.connection then
            pcall(function()
                autoRagdollTp.connection:Disconnect()
            end)
        end
        if _G.PulseAutoRagdollTpConnection then
            pcall(function()
                _G.PulseAutoRagdollTpConnection:Disconnect()
            end)
            _G.PulseAutoRagdollTpConnection = nil
        end
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        autoRagdollTp.lastHealth = hum and hum.Health or 100
        autoRagdollTp.lastTrigger = 0
        refreshAutoRagdollTpPlot()
        autoRagdollTp.connection = RunService.Heartbeat:Connect(function()
            if not autoRagdollTp.enabled then
                return
            end
            if _G.PulseHubRuntimeGeneration ~= PULSE_RUNTIME_GENERATION then
                stopAutoRagdollTp()
                return
            end
            local now = tick()
            if now - autoRagdollTp.lastPlotRefresh >= 2 then
                refreshAutoRagdollTpPlot()
            end
            local currentChar = LP.Character
            local currentHum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")
            local root = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
            if not currentHum or not root then
                return
            end
            if root.Anchored then
                autoRagdollTp.lastHealth = currentHum.Health
                return
            end
            local health = currentHum.Health
            local state = currentHum:GetState()
            local ragdolled = state == Enum.HumanoidStateType.Physics
                or state == Enum.HumanoidStateType.Ragdoll
                or state == Enum.HumanoidStateType.FallingDown
            local wasHit = health < (autoRagdollTp.lastHealth or health) - 1
            autoRagdollTp.lastHealth = health
            if not (wasHit or ragdolled) then
                return
            end
            if autoRagdollTp.returning or now - autoRagdollTp.lastTrigger < 0.25 then
                return
            end
            local side = autoRagdollTp.plotSide
            if not side then
                side = refreshAutoRagdollTpPlot()
            end
            if not side then
                return
            end
            autoRagdollTp.lastTrigger = now
            stopAutoPathsForRagdollTp()
            runAutoRagdollReturnTeleport(side)
        end)
        _G.PulseAutoRagdollTpConnection = autoRagdollTp.connection
        if autoRagdollTp.setVisual then
            autoRagdollTp.setVisual(true)
        end
    end
    autoRagdollTp.start = startAutoRagdollTp
    autoRagdollTp.stop = stopAutoRagdollTp
    autoRagdollTp.set = function(on)
        if on then
            startAutoRagdollTp()
        else
            stopAutoRagdollTp()
        end
    end
end
local overheadUiElapsed = 0
if _G.PulseMovementRenderConn then
    pcall(function()
        _G.PulseMovementRenderConn:Disconnect()
    end)
end
_G.PulseMovementRenderConn = RunService.RenderStepped:Connect(function(delta)
    overheadUiElapsed = overheadUiElapsed + (delta or 0)
    local char = LP.Character
    if not char then
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then
        return
    end
    local state = hum:GetState()
    if
        hum.PlatformStand
        or state == Enum.HumanoidStateType.Physics
        or state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.FallingDown
    then
        lastMoveDir = Vector3.new(0, 0, 0)
        return
    end
    local md = hum.MoveDirection
    local spd = getCurrentSpeedValue()
    if not autoLeftEnabled and not autoRightEnabled and md.Magnitude > 0 then
        lastMoveDir = md
        local currentVel = hrp.AssemblyLinearVelocity
        applyImpulseForVelocity(hrp, Vector3.new(md.X * spd, currentVel.Y, md.Z * spd))
    end
    if overheadSpeedLabel and overheadUiElapsed >= 0.10 then
        overheadUiElapsed = 0
        local modeName = currentSpeedMode
        local modeSpd = getCurrentSpeedValue()
        if autoLeftEnabled or autoRightEnabled then
            modeSpd = _G.PulseAutoPathSpeed()
            if currentSpeedMode == "Lagger Carry" then
                modeName = "Lagger"
            end
            if currentSpeedMode == "Lagger Carry 2" then
                modeName = "Lagger 2"
            end
            if currentSpeedMode == "Carry" then
                modeName = "Normal"
            end
        end
        overheadSpeedLabel.Text = string.format("Speed: %s (%.1f)", modeName, modeSpd)
    end
end)
local COLORS = {
    bg = Color3.fromRGB(10, 10, 12),
    row = Color3.fromRGB(24, 24, 28),
    row2 = Color3.fromRGB(34, 34, 40),
    stroke = Color3.fromRGB(235, 235, 240),
    strokeSoft = Color3.fromRGB(110, 110, 120),
    white = Color3.fromRGB(255, 255, 255),
    textDim = Color3.fromRGB(190, 190, 198),
    toggleBg = Color3.fromRGB(42, 42, 48),
    knob = Color3.fromRGB(230, 230, 235),
    purpleAccent = Color3.fromRGB(180, 180, 188),
    purpleBright = Color3.fromRGB(222, 222, 228),
}
function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end
function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color or COLORS.stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.35
    s.Parent = parent
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 160, 170)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
    })
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(1, 0.55),
    })
    g.Parent = s
    return s
end
function tween(obj, props, time)
    if pulseStartupBuilding then
        for property, value in pairs(props) do
            obj[property] = value
        end
        return nil
    end
    local animation =
        TweenService:Create(obj, TweenInfo.new(time or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    animation:Play()
    return animation
end
function pulseStyleAdaptArrow(pointer)
    if not pointer then
        return
    end
    pointer.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    pointer.BackgroundTransparency = 0.18
    pointer.Text = "▼"
    pointer.TextColor3 = COLORS.white
    pointer.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    pointer.TextStrokeTransparency = 0.20
    pointer.TextSize = 18
    pointer.Font = Enum.Font.GothamBlack
    corner(pointer, 7)
    local oldStroke = pointer:FindFirstChild("AdaptArrowStroke")
    if oldStroke then
        oldStroke:Destroy()
    end
    local oldGlow = pointer:FindFirstChild("AdaptArrowGlow")
    if oldGlow then
        oldGlow:Destroy()
    end
    local st = Instance.new("UIStroke")
    st.Name = "AdaptArrowStroke"
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    st.Color = COLORS.white
    st.Thickness = 1.8
    st.Transparency = 0.05
    st.Parent = pointer
    local sg = Instance.new("UIGradient")
    sg.Rotation = 135
    sg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.82, 0),
        NumberSequenceKeypoint.new(0.28, 0.06, 0),
        NumberSequenceKeypoint.new(0.52, 0.22, 0),
        NumberSequenceKeypoint.new(1, 0.82, 0),
    })
    sg.Parent = st
    local glow = Instance.new("UIStroke")
    glow.Name = "AdaptArrowGlow"
    glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    glow.Color = COLORS.white
    glow.Thickness = 3.6
    glow.Transparency = 0.58
    glow.Parent = pointer
    local gg = Instance.new("UIGradient")
    gg.Name = "GlowGradient"
    gg.Rotation = 180
    gg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.82, 0),
        NumberSequenceKeypoint.new(0.28, 0.06, 0),
        NumberSequenceKeypoint.new(0.52, 0.22, 0),
        NumberSequenceKeypoint.new(1, 0.82, 0),
    })
    gg.Parent = glow
end
function showPulseConfirmDialog(titleText, onYes)
    local overlayGui = Instance.new("ScreenGui")
    overlayGui.Name = "PulseConfirmOverlay"
    overlayGui.ResetOnSpawn = false
    overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    overlayGui.DisplayOrder = 999
    overlayGui.IgnoreGuiInset = true
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(overlayGui)
        end
    end)
    overlayGui.Parent = PlayerGui
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.Position = UDim2.new(0, 0, 0, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.45
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 1
    backdrop.Parent = overlayGui
    local dialog = Instance.new("Frame")
    dialog.Name = "Dialog"
    dialog.AnchorPoint = Vector2.new(0.5, 0.5)
    dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
    dialog.Size = UDim2.new(0, 260, 0, 110)
    dialog.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 2
    dialog.Parent = overlayGui
    corner(dialog, 14)
    stroke(dialog, Color3.fromRGB(255, 255, 255), 1.1, 0.18)
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Name = "Message"
    msgLabel.AnchorPoint = Vector2.new(0.5, 0)
    msgLabel.Position = UDim2.new(0.5, 0, 0, 16)
    msgLabel.Size = UDim2.new(1, -24, 0, 46)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = titleText
    msgLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
    msgLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    msgLabel.TextStrokeTransparency = 0.4
    msgLabel.TextSize = 13
    msgLabel.Font = Enum.Font.GothamBold
    msgLabel.TextWrapped = true
    msgLabel.TextXAlignment = Enum.TextXAlignment.Center
    msgLabel.ZIndex = 3
    msgLabel.Parent = dialog
    local yesBtn = Instance.new("TextButton")
    yesBtn.Name = "YesButton"
    yesBtn.AnchorPoint = Vector2.new(1, 1)
    yesBtn.Position = UDim2.new(0.5, -6, 1, -12)
    yesBtn.Size = UDim2.new(0, 100, 0, 30)
    yesBtn.BackgroundColor3 = Color3.fromRGB(232, 232, 238)
    yesBtn.BackgroundTransparency = 0
    yesBtn.BorderSizePixel = 0
    yesBtn.Text = "Yes"
    yesBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    yesBtn.TextSize = 13
    yesBtn.Font = Enum.Font.GothamBlack
    yesBtn.AutoButtonColor = false
    yesBtn.ZIndex = 3
    yesBtn.Parent = dialog
    corner(yesBtn, 8)
    stroke(yesBtn, Color3.fromRGB(255, 255, 255), 1, 0.18)
    local noBtn = Instance.new("TextButton")
    noBtn.Name = "NoButton"
    noBtn.AnchorPoint = Vector2.new(0, 1)
    noBtn.Position = UDim2.new(0.5, 6, 1, -12)
    noBtn.Size = UDim2.new(0, 100, 0, 30)
    noBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 44)
    noBtn.BackgroundTransparency = 0
    noBtn.BorderSizePixel = 0
    noBtn.Text = "No"
    noBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
    noBtn.TextSize = 13
    noBtn.Font = Enum.Font.GothamBlack
    noBtn.AutoButtonColor = false
    noBtn.ZIndex = 3
    noBtn.Parent = dialog
    corner(noBtn, 8)
    stroke(noBtn, COLORS.strokeSoft, 1, 0.45)
    local closed = false
    local function closeDialog()
        if closed then
            return
        end
        closed = true
        overlayGui:Destroy()
    end
    yesBtn.Activated:Connect(function()
        closeDialog()
        if onYes then
            onYes()
        end
    end)
    noBtn.Activated:Connect(closeDialog)
end
function makeDraggable(frame)
    local dragging = false
    local dragStart
    local startPos
    local dragInput
    frame.InputBegan:Connect(function(input)
        if _G.PulseGuiLocked == true then
            return
        end
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    task.defer(function()
                        pcall(savePulseConfig)
                    end)
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if _G.PulseGuiLocked == true then
            dragging = false
            dragInput = nil
            return
        end
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position =
                UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
local Gui = Instance.new("ScreenGui")
Gui.Name = "PulseHubAdaptReconstruct"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui
local FULL_MAIN_SIZE = UDim2.new(0, 420, 0, 536)
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0, 0.5)
Main.Size = FULL_MAIN_SIZE
Main.Position = tableToUDim2(savedMainPositionTable, UDim2.new(0, 20, 0.5, 0))
savedMainPositionTable = udim2ToTable(Main.Position)
Main.BackgroundColor3 = COLORS.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = false
Main.Visible = false
Main.Parent = Gui
corner(Main, 14)
stroke(Main, COLORS.stroke, 1.1, 0.35)
makeDraggable(Main)
Main:GetPropertyChangedSignal("Position"):Connect(function()
    savedMainPositionTable = udim2ToTable(Main.Position)
end)
local MiniFrame = Instance.new("Frame")
MiniFrame.Name = "MiniFrame"
MiniFrame.AnchorPoint = Vector2.new(0, 0)
MiniFrame.Size = UDim2.new(0, 160, 0, 38)
local MINI_DEFAULT_POSITION = UDim2.new(1, -174, 0, 20)
MiniFrame.Position = tableToUDim2(savedMiniPositionTable, MINI_DEFAULT_POSITION)
savedMiniPositionTable = udim2ToTable(MiniFrame.Position)
MiniFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MiniFrame.BackgroundTransparency = 0
MiniFrame.BorderSizePixel = 0
MiniFrame.Visible = false
MiniFrame.Active = true
MiniFrame.ZIndex = 20
MiniFrame.Parent = Gui
corner(MiniFrame, 16)
MiniFrame.ClipsDescendants = false
stroke(MiniFrame, COLORS.stroke, 1.2, 0.1)
local MiniButton = Instance.new("TextButton")
MiniButton.Name = "MiniButton"
MiniButton.Size = UDim2.new(1, 0, 1, 0)
MiniButton.BackgroundTransparency = 1
MiniButton.Text = "PULSE HUB"
MiniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
MiniButton.TextStrokeTransparency = 0.18
MiniButton.TextSize = 16
MiniButton.Font = Enum.Font.GothamBlack
MiniButton.AutoButtonColor = false
MiniButton.ZIndex = 21
MiniButton.Parent = MiniFrame
local MiniShade = Instance.new("Frame")
MiniShade.Name = "MiniShade"
MiniShade.Size = UDim2.new(1, -4, 1, -4)
MiniShade.Position = UDim2.new(0, 2, 0, 2)
MiniShade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MiniShade.BackgroundTransparency = 0.12
MiniShade.BorderSizePixel = 0
MiniShade.ZIndex = 20
MiniShade.Parent = MiniFrame
corner(MiniShade, 14)
do
    local miniDragging = false
    local miniDragStart = nil
    local miniStartPos = nil
    local miniMoved = false
    local miniHeldInput = nil
    local DRAG_DEADZONE = 6
    MiniButton.InputBegan:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            miniHeldInput = input
            miniDragStart = input.Position
            miniStartPos = MiniFrame.Position
            miniMoved = false
            if _G.PulseGuiLocked == true then
                miniDragging = false
            else
                miniDragging = true
            end
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if _G.PulseGuiLocked == true then
            miniDragging = false
            if not miniDragging then
                return
            end
        end
        if not miniDragging then
            return
        end
        if
            input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end
        if not miniDragStart or not miniStartPos then
            return
        end
        local delta = input.Position - miniDragStart
        if math.abs(delta.X) > DRAG_DEADZONE or math.abs(delta.Y) > DRAG_DEADZONE then
            miniMoved = true
        end
        MiniFrame.Position = UDim2.new(
            miniStartPos.X.Scale,
            miniStartPos.X.Offset + delta.X,
            miniStartPos.Y.Scale,
            miniStartPos.Y.Offset + delta.Y
        )
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input ~= miniHeldInput then
            return
        end
        local wasDrag = miniMoved
        miniDragging = false
        miniHeldInput = nil
        miniDragStart = nil
        miniStartPos = nil
        if wasDrag then
            savedMiniPositionTable = udim2ToTable(MiniFrame.Position)
            task.defer(function()
                pcall(savePulseConfig)
            end)
            return
        end
        Main.Visible = true
        MiniFrame.Visible = false
        Main.Size = FULL_MAIN_SIZE
        savedMainPositionTable = udim2ToTable(Main.Position)
    end)
    MiniFrame:GetPropertyChangedSignal("Position"):Connect(function()
        savedMiniPositionTable = udim2ToTable(MiniFrame.Position)
    end)
end
local BackgroundIDs = { "126860692354524", "88369503310562", "80708025126373", "102253425322931", "71300527482258" }
currentBackground = tonumber(savedConfig.currentBackground) or currentBackground
local BgImage = Instance.new("ImageLabel")
BgImage.Name = "CustomBackground"
BgImage.BackgroundTransparency = 1
BgImage.ImageTransparency = 0
BgImage.ScaleType = Enum.ScaleType.Crop
BgImage.Size = UDim2.new(1, 0, 1, 0)
BgImage.Position = UDim2.new(0, 0, 0, 0)
BgImage.Visible = false
BgImage.ZIndex = 1
BgImage.Parent = Main
corner(BgImage, 14)
function _G.PulseGetAccentColor()
    if currentBackgroundColor ~= nil then
        return currentBackgroundColor
    end
    return Color3.fromRGB(255, 255, 255)
end
function _G.PulseGetMobileActiveColor()
    local accent = _G.PulseGetAccentColor()
    if accent.R <= 0.08 and accent.G <= 0.08 and accent.B <= 0.08 then
        return Color3.fromRGB(255, 255, 255)
    end
    return accent
end
function _G.PulseResolveMobileButtonColor(key)
    local defaults = _G.PulseDefaultMobileButtonColors()
    local settings = _G.PulseMobileButtonColors or defaults
    local value = settings[key] or defaults[key]
    if key == "activeBackground" and value == "AUTO" then
        return _G.PulseGetMobileActiveColor()
    end
    local normalized = _G.PulseNormalizeMobileButtonColor(value, defaults[key], false)
    local hex = normalized:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if r and g and b then
        return Color3.fromRGB(r, g, b)
    end
    if key == "activeBackground" then
        return _G.PulseGetMobileActiveColor()
    end
    if key == "inactiveBackground" or key == "activeText" then
        return Color3.fromRGB(0, 0, 0)
    end
    return Color3.fromRGB(255, 255, 255)
end
function _G.PulseRefreshOverheadAccent()
    local accent = _G.PulseGetAccentColor()
    if overheadSpeedLabel then
        overheadSpeedLabel.TextColor3 = accent
    end
    local d = overheadGui and overheadGui:FindFirstChild("Discord")
    if d then
        d.TextColor3 = accent
    end
end
function _G.PulseRefreshMobileAccent()
    if _G.PulseMobileButtonRefs then
        for _, entry in pairs(_G.PulseMobileButtonRefs) do
            local btn = entry and entry.btn
            if btn then
                local active = entry.state == true
                local background =
                    _G.PulseResolveMobileButtonColor(active and "activeBackground" or "inactiveBackground")
                local textColor = _G.PulseResolveMobileButtonColor(active and "activeText" or "inactiveText")
                TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = background, TextColor3 = textColor })
                    :Play()
                local strokeInst = btn:FindFirstChildOfClass("UIStroke")
                if strokeInst then
                    TweenService:Create(strokeInst, TweenInfo.new(0.15), { Color = textColor }):Play()
                end
            end
        end
    end
end
function applyBackgroundColor(color)
    currentBackgroundColor = color
    if BgImage then
        BgImage.ImageColor3 = color or COLORS.white
    end
    if Main then
        Main.BackgroundColor3 = (currentBackground == 0) and COLORS.bg or (color or COLORS.bg)
    end
    if updateBackgroundColorButtons then
        updateBackgroundColorButtons()
    end
    _G.PulseRefreshOverheadAccent()
    _G.PulseRefreshMobileAccent()
    if _G.PulseMobileColorEditorRefresh then
        _G.PulseMobileColorEditorRefresh()
    end
    if _G.PulseRefreshSideIdentityAccent then
        _G.PulseRefreshSideIdentityAccent()
    end
    if _G.PulseRefreshTitleAccent then
        _G.PulseRefreshTitleAccent()
    end
    savePulseConfig()
end
function applyBackground(index)
    currentBackground = index or 0
    if currentBackground == 0 then
        Main.BackgroundColor3 = COLORS.bg
        BgImage.Image = ""
        BgImage.ImageColor3 = currentBackgroundColor or COLORS.white
        BgImage.Visible = false
        savePulseConfig()
        if updateBackgroundColorButtons then
            updateBackgroundColorButtons()
        end
        return "None"
    end
    local id = BackgroundIDs[currentBackground]
    if id then
        BgImage.Image = "rbxassetid://" .. id
        BgImage.ImageColor3 = currentBackgroundColor or COLORS.white
        BgImage.Visible = true
        Main.BackgroundColor3 = COLORS.bg
        savePulseConfig()
        if updateBackgroundColorButtons then
            updateBackgroundColorButtons()
        end
        return "Image " .. tostring(currentBackground)
    end
    currentBackground = 0
    BgImage.Image = ""
    BgImage.ImageColor3 = currentBackgroundColor or COLORS.white
    BgImage.Visible = false
    Main.BackgroundColor3 = COLORS.bg
    savePulseConfig()
    if updateBackgroundColorButtons then
        updateBackgroundColorButtons()
    end
    return "None"
end
applyBackground(currentBackground)
if currentBackgroundColor ~= nil then
    if BgImage then
        BgImage.ImageColor3 = currentBackgroundColor
    end
    if Main and currentBackground ~= 0 then
        Main.BackgroundColor3 = currentBackgroundColor
    end
end
if _G.PulseRefreshOverheadAccent then
    _G.PulseRefreshOverheadAccent()
end
if _G.PulseRefreshMobileAccent then
    _G.PulseRefreshMobileAccent()
end
local StarField = Instance.new("Frame")
StarField.Name = "HeaderStars"
StarField.Size = UDim2.new(1, 0, 0, 96)
StarField.BackgroundTransparency = 1
StarField.ClipsDescendants = true
StarField.ZIndex = 2
StarField.Parent = Main
for i = 1, 8 do
    local star = Instance.new("Frame")
    star.Name = "Star_" .. tostring(i)
    star.Size = UDim2.new(0, (i % 3 == 0) and 3 or 2, 0, (i % 3 == 0) and 3 or 2)
    star.Position = UDim2.new((i * 0.12) % 0.88 + 0.06, 0, 0.15 + (i * 0.1) % 0.65, 0)
    star.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    star.BackgroundTransparency = 0.65
    star.BorderSizePixel = 0
    star.ZIndex = 2
    star.Parent = StarField
    corner(star, 999)
    task.spawn(function()
        while star and star.Parent do
            TweenService:Create(
                star,
                TweenInfo.new(1.8 + i * 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {
                    BackgroundTransparency = 0.15,
                    Position = UDim2.new(
                        star.Position.X.Scale,
                        math.random(-4, 4),
                        star.Position.Y.Scale,
                        math.random(-3, 3)
                    ),
                }
            ):Play()
            task.wait(2.4 + i * 0.3)
        end
    end)
end
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -90, 0, 30)
Title.Position = UDim2.new(0, 16, 0, 24)
Title.Text = "PULSE HUB"
addPurpleGradient(Title, Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 178))
Title.TextColor3 = COLORS.white
Title.TextStrokeTransparency = 0.65
Title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 27
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 6
Title.Parent = Main
local Discord = Instance.new("TextLabel")
Discord.Name = "Discord"
Discord.BackgroundTransparency = 1
Discord.Size = UDim2.new(1, -90, 0, 18)
Discord.Position = UDim2.new(0, 16, 0, 55)
Discord.Text = "discord.gg/pulsee"
Discord.TextColor3 = Color3.fromRGB(235, 235, 245)
Discord.Font = Enum.Font.GothamSemibold
Discord.TextSize = 14
Discord.TextXAlignment = Enum.TextXAlignment.Left
Discord.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Discord.TextStrokeTransparency = 0.25
Discord.ZIndex = 6
Discord.Parent = Main
function _G.PulseRefreshTitleAccent()
    local titleGrad = Title:FindFirstChildOfClass("UIGradient")
    if currentBackgroundColor ~= nil then
        Title.TextColor3 = COLORS.white
        if titleGrad then
            titleGrad.Color = ColorSequence.new(currentBackgroundColor, currentBackgroundColor)
        end
        Discord.TextColor3 = currentBackgroundColor
    else
        Title.TextColor3 = COLORS.white
        if titleGrad then
            titleGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 178))
        end
        Discord.TextColor3 = Color3.fromRGB(235, 235, 245)
    end
end
_G.PulseRefreshTitleAccent()
local SearchFrame = Instance.new("Frame")
SearchFrame.Name = "SearchBar"
SearchFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
SearchFrame.BackgroundTransparency = 0.35
SearchFrame.BorderSizePixel = 0
SearchFrame.Size = UDim2.new(1, -34, 0, 20)
SearchFrame.Position = UDim2.new(0, 17, 0, 72)
SearchFrame.ZIndex = 6
SearchFrame.Parent = Main
corner(SearchFrame, 6)
stroke(SearchFrame, COLORS.strokeSoft, 1, 0.45)
local SearchIcon = Instance.new("TextLabel")
SearchIcon.Name = "Icon"
SearchIcon.BackgroundTransparency = 1
SearchIcon.Text = "  "
SearchIcon.TextSize = 10
SearchIcon.Size = UDim2.new(0, 18, 1, 0)
SearchIcon.Position = UDim2.new(0, 4, 0, 0)
SearchIcon.ZIndex = 7
SearchIcon.Parent = SearchFrame
local SearchBox = Instance.new("TextBox")
SearchBox.Name = "Input"
SearchBox.BackgroundTransparency = 1
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search features (e.g. Bat, Steal, FOV)..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
SearchBox.TextColor3 = COLORS.white
SearchBox.TextSize = 10
SearchBox.Font = Enum.Font.GothamMedium
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Size = UDim2.new(1, -26, 1, 0)
SearchBox.Position = UDim2.new(0, 22, 0, 0)
SearchBox.ZIndex = 7
SearchBox.Parent = SearchFrame
local HeaderDivider = Instance.new("Frame")
HeaderDivider.Name = "HeaderDivider"
HeaderDivider.BackgroundColor3 = Color3.fromRGB(70, 70, 82)
HeaderDivider.BackgroundTransparency = 0.45
HeaderDivider.BorderSizePixel = 0
HeaderDivider.Size = UDim2.new(1, -34, 0, 1)
HeaderDivider.Position = UDim2.new(0, 17, 0, 96)
HeaderDivider.ZIndex = 6
HeaderDivider.Parent = Main
local Close = Instance.new("TextButton")
Close.Name = "Close"
Close.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Close.BackgroundTransparency = 0.28
Close.Text = "-"
Close.TextColor3 = COLORS.white
Close.TextSize = 22
Close.Font = Enum.Font.GothamSemibold
Close.Size = UDim2.new(0, 32, 0, 28)
Close.Position = UDim2.new(1, -42, 0, 14)
Close.AutoButtonColor = false
Close.ZIndex = 5
Close.Parent = Main
corner(Close, 8)
stroke(Close, COLORS.stroke, 1, 0.35)
PulseLockTopButton = Instance.new("TextButton")
PulseLockTopButton.Name = "LockGUI"
PulseLockTopButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PulseLockTopButton.BackgroundTransparency = 0.28
PulseLockTopButton.TextColor3 = COLORS.white
PulseLockTopButton.TextSize = 16
PulseLockTopButton.Font = Enum.Font.GothamBlack
PulseLockTopButton.Size = UDim2.new(0, 32, 0, 28)
PulseLockTopButton.Position = UDim2.new(1, -78, 0, 14)
PulseLockTopButton.AutoButtonColor = false
PulseLockTopButton.ZIndex = 5
PulseLockTopButton.Parent = Main
corner(PulseLockTopButton, 8)
stroke(PulseLockTopButton, COLORS.stroke, 1, 0.35)
local PanicBtn = Instance.new("TextButton")
PanicBtn.Name = "PanicButton"
PanicBtn.BackgroundColor3 = Color3.fromRGB(28, 8, 12)
PanicBtn.BackgroundTransparency = 0.2
PanicBtn.Text = "PANIC"
PanicBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
PanicBtn.TextSize = 8.5
PanicBtn.Font = Enum.Font.GothamBlack
PanicBtn.Size = UDim2.new(0, 38, 0, 28)
PanicBtn.Position = UDim2.new(1, -122, 0, 14)
PanicBtn.AutoButtonColor = false
PanicBtn.ZIndex = 5
PanicBtn.Parent = Main
corner(PanicBtn, 8)
stroke(PanicBtn, Color3.fromRGB(255, 70, 70), 1, 0.35)
PanicBtn.MouseButton1Click:Connect(function()
    showPulseConfirmDialog("Are you sure you would like to do this?", function()
        if _G.PulseStopAntiDesyncAimbot then
            _G.PulseStopAntiDesyncAimbot()
        end
        if stopAutoTP then
            stopAutoTP()
        end
        if _G.PulseSemiRagdollStealController and _G.PulseSemiRagdollStealController.active then
            _G.PulseSemiRagdollStealController.cancel()
        end
        if setAntiRagdoll then
            setAntiRagdoll(false)
        elseif stopAntiRagdoll then
            stopAntiRagdoll()
        end
        if _G.PulseAutoRagdollTpState.stop then
            _G.PulseAutoRagdollTpState.stop()
        end
        if _G.PulseNormalAutoStealRagdollPause and _G.PulseNormalAutoStealRagdollPause.cancel then
            _G.PulseNormalAutoStealRagdollPause.cancel(false)
        end
        autoStealEnabled = false
        espEnabled = false
        showTracerEnabled = false
        NS = 62
        CS = 29.7
        if normalSpeedBox then
            normalSpeedBox.Text = "62"
        end
        if carrySpeedBox then
            carrySpeedBox.Text = "29.7"
        end
        Main.Visible = false
        if MiniFrame then
            MiniFrame.Visible = true
        end
        _safeNotify("PANIC: ALL FEATURES DISABLED")
    end)
end)
local StatPill = Instance.new("Frame")
StatPill.Name = "PerformanceStats"
StatPill.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
StatPill.BackgroundTransparency = 0.35
StatPill.BorderSizePixel = 0
StatPill.Size = UDim2.new(0, 128, 0, 16)
StatPill.Position = UDim2.new(1, -146, 0, 52)
StatPill.ZIndex = 6
StatPill.Parent = Main
corner(StatPill, 5)
stroke(StatPill, COLORS.strokeSoft, 1, 0.5)
local StatText = Instance.new("TextLabel")
StatText.Name = "Label"
StatText.BackgroundTransparency = 1
StatText.Size = UDim2.new(1, 0, 1, 0)
StatText.Text = "   60 FPS | 40ms"
StatText.TextColor3 = Color3.fromRGB(220, 220, 230)
StatText.TextSize = 9
StatText.Font = Enum.Font.GothamBold
StatText.ZIndex = 7
StatText.Parent = StatPill
local fpsCount = 0
local lastFpsTime = tick()
local currentFps = 60
RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    local now = tick()
    if now - lastFpsTime >= 0.5 then
        currentFps = math.floor(fpsCount / (now - lastFpsTime) + 0.5)
        fpsCount = 0
        lastFpsTime = now
        local pingVal = 0
        pcall(function()
            pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
        end)
        local pingDot = currentFps >= 45 and "  " or (currentFps >= 25 and "  " or "  ")
        StatText.Text = string.format("%s %d FPS | %dms", pingDot, currentFps, pingVal)
    end
end)
function PulseUpdateGuiLockVisual()
    if PulseLockTopButton then
        PulseLockTopButton.Text = (_G.PulseGuiLocked == true) and "  " or "  "
        PulseLockTopButton.BackgroundTransparency = (_G.PulseGuiLocked == true) and 0.08 or 0.28
        local st = PulseLockTopButton:FindFirstChildOfClass("UIStroke")
        if st then
            st.Transparency = (_G.PulseGuiLocked == true) and 0.08 or 0.35
            st.Color = (_G.PulseGuiLocked == true) and Color3.fromRGB(255, 255, 255) or COLORS.stroke
        end
    end
    if setLockGuiVisual then
        pcall(setLockGuiVisual, _G.PulseGuiLocked == true)
    end
    if MiniFrame then
        MiniFrame.Active = true
        MiniButton.Active = true
        local miniStroke = MiniFrame:FindFirstChildOfClass("UIStroke")
        if miniStroke then
            miniStroke.Transparency = (_G.PulseGuiLocked == true) and 0.35 or 0.1
            miniStroke.Color = (_G.PulseGuiLocked == true) and Color3.fromRGB(180, 180, 180) or COLORS.stroke
        end
        if _G.PulseGuiLocked == true then
            MiniButton.TextTransparency = 0.15
            MiniFrame.BackgroundTransparency = 0.12
        else
            MiniButton.TextTransparency = 0
            MiniFrame.BackgroundTransparency = 0
        end
    end
end
PulseLockTopButton.Activated:Connect(function()
    _G.PulseGuiLocked = not (_G.PulseGuiLocked == true)
    PulseUpdateGuiLockVisual()
    savePulseConfig()
end)
PulseUpdateGuiLockVisual()
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 102, 0, 106)
Content.Size = UDim2.new(1, -114, 1, -118)
Content.ZIndex = 3
Content.Parent = Main
local Tabs = Instance.new("Frame")
Tabs.Name = "Tabs"
Tabs.BackgroundTransparency = 1
Tabs.Position = UDim2.new(0, 12, 0, 106)
Tabs.Size = UDim2.new(0, 80, 1, -118)
Tabs.ZIndex = 3
Tabs.Parent = Main
local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Vertical
TabLayout.Padding = UDim.new(0, 6)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Top
TabLayout.Parent = Tabs
local pages = {}
local tabButtons = {}
local tabNames = { "BINDS", "MECHANICS", "SPEED", "UTILITY", "VISUALS" }
local activeTab = "BINDS"
local TabGlowPill = Instance.new("Frame")
TabGlowPill.Name = "ActiveTabGlowPill"
TabGlowPill.Size = UDim2.new(0, 80, 0, 36)
TabGlowPill.Position = Tabs.Position
TabGlowPill.BackgroundColor3 = Color3.fromRGB(255, 60, 172)
TabGlowPill.BackgroundTransparency = 0.82
TabGlowPill.BorderSizePixel = 0
TabGlowPill.ZIndex = 2
TabGlowPill.Parent = Main
corner(TabGlowPill, 7)
local tabPillStroke = Instance.new("UIStroke")
tabPillStroke.Color = Color3.fromRGB(255, 60, 172)
tabPillStroke.Thickness = 1.2
tabPillStroke.Transparency = 0.2
tabPillStroke.Parent = TabGlowPill
function addPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 0
    page.ScrollBarImageTransparency = 1
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Size = UDim2.new(1, 0, 1, 0)
    page.ZIndex = 3
    page.Visible = false
    page.Parent = Content
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page
    pages[name] = page
    return page
end
function setTab(name)
    activeTab = name
    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end
    for tabName, btn in pairs(tabButtons) do
        local on = tabName == name
        btn.TextColor3 = on and COLORS.white or Color3.fromRGB(170, 170, 180)
        btn.BackgroundTransparency = on and 0.28 or 0.72
        local st = btn:FindFirstChildOfClass("UIStroke")
        if st then
            st.Transparency = on and 0.05 or 0.52
            st.Color = on and Color3.fromRGB(245, 245, 255) or COLORS.stroke
        end
        if on and TabGlowPill and btn then
            local acc = (_G.PulseGetAccentColor and _G.PulseGetAccentColor()) or Color3.fromRGB(255, 60, 172)
            TabGlowPill.BackgroundColor3 = acc
            tabPillStroke.Color = acc
            local tabIndex = 0
            for i, tabName in ipairs(tabNames) do
                if tabName == name then
                    tabIndex = i - 1
                    break
                end
            end
            TweenService:Create(
                TabGlowPill,
                TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Position = UDim2.new(
                        Tabs.Position.X.Scale,
                        Tabs.Position.X.Offset,
                        Tabs.Position.Y.Scale,
                        Tabs.Position.Y.Offset + tabIndex * 42
                    ),
                }
            ):Play()
        end
    end
end
for _, name in ipairs(tabNames) do
    addPage(name)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
    btn.BackgroundTransparency = 0.72
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(170, 170, 180)
    btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    btn.TextStrokeTransparency = 0.35
    btn.TextSize = 8
    btn.Font = Enum.Font.GothamBlack
    btn.AutoButtonColor = false
    btn.ZIndex = 4
    btn.Parent = Tabs
    corner(btn, 7)
    stroke(btn, COLORS.stroke, 1, 0.52)
    tabButtons[name] = btn
    local actDot = Instance.new("Frame")
    actDot.Name = "ActiveDot"
    actDot.AnchorPoint = Vector2.new(1, 0.5)
    actDot.Position = UDim2.new(1, -6, 0.5, 0)
    actDot.Size = UDim2.new(0, 5, 0, 5)
    actDot.BackgroundColor3 = Color3.fromRGB(80, 255, 140)
    actDot.BorderSizePixel = 0
    actDot.Visible = false
    actDot.ZIndex = 6
    actDot.Parent = btn
    corner(actDot, 999)
    btn.MouseButton1Click:Connect(function()
        setTab(name)
    end)
end
local SideId = Instance.new("Frame")
SideId.Name = "SideIdentity"
SideId.ZIndex = 6
SideId.Position = UDim2.new(0, 12, 1, -144)
SideId.Size = UDim2.new(0, 80, 0, 132)
SideId.BackgroundTransparency = 1
SideId.BorderSizePixel = 0
SideId.Parent = Main
local SideAvatar = Instance.new("ImageLabel")
SideAvatar.Name = "AvatarImage"
SideAvatar.ZIndex = 7
SideAvatar.AnchorPoint = Vector2.new(0.5, 0)
SideAvatar.Position = UDim2.new(0.5, 0, 0, 0)
SideAvatar.Size = UDim2.new(0, 68, 0, 68)
SideAvatar.BackgroundColor3 = Color3.fromRGB(8, 9, 11)
SideAvatar.BorderSizePixel = 0
SideAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LP.UserId) .. "&w=150&h=150"
SideAvatar.ScaleType = Enum.ScaleType.Crop
SideAvatar.Parent = SideId
corner(SideAvatar, 34)
local SideAvatarStroke = Instance.new("UIStroke")
SideAvatarStroke.Color = (_G.PulseGetAccentColor and _G.PulseGetAccentColor()) or Color3.fromRGB(255, 60, 172)
SideAvatarStroke.Thickness = 2
SideAvatarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
SideAvatarStroke.Parent = SideAvatar
local SideBuyerLabel = Instance.new("TextLabel")
SideBuyerLabel.Name = "BuyerLabel"
SideBuyerLabel.ZIndex = 7
SideBuyerLabel.Position = UDim2.new(0, 0, 0, 74)
SideBuyerLabel.Size = UDim2.new(1, 0, 0, 14)
SideBuyerLabel.BackgroundTransparency = 1
SideBuyerLabel.Text = "buyer of,"
SideBuyerLabel.TextColor3 = COLORS.textDim
SideBuyerLabel.TextSize = 9
SideBuyerLabel.Font = Enum.Font.GothamMedium
SideBuyerLabel.TextTruncate = Enum.TextTruncate.AtEnd
SideBuyerLabel.Parent = SideId
local SideDisplayNameLabel = Instance.new("TextLabel")
SideDisplayNameLabel.Name = "DisplayNameLabel"
SideDisplayNameLabel.ZIndex = 7
SideDisplayNameLabel.Position = UDim2.new(0, 0, 0, 88)
SideDisplayNameLabel.Size = UDim2.new(1, 0, 0, 18)
SideDisplayNameLabel.BackgroundTransparency = 1
SideDisplayNameLabel.Text = LP.DisplayName
SideDisplayNameLabel.TextColor3 = COLORS.white
SideDisplayNameLabel.TextSize = 11
SideDisplayNameLabel.Font = Enum.Font.GothamBold
SideDisplayNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
SideDisplayNameLabel.Parent = SideId
local SideStatusLabel = Instance.new("TextLabel")
SideStatusLabel.Name = "StatusLabel"
SideStatusLabel.ZIndex = 7
SideStatusLabel.Position = UDim2.new(0, 0, 0, 108)
SideStatusLabel.Size = UDim2.new(1, 0, 0, 12)
SideStatusLabel.BackgroundTransparency = 1
SideStatusLabel.Text = "CORES LOADED"
SideStatusLabel.TextColor3 = (_G.PulseGetAccentColor and _G.PulseGetAccentColor()) or Color3.fromRGB(255, 60, 172)
SideStatusLabel.TextSize = 8
SideStatusLabel.Font = Enum.Font.GothamBold
SideStatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
SideStatusLabel.Parent = SideId
function _G.PulseRefreshSideIdentityAccent()
    local acc = (_G.PulseGetAccentColor and _G.PulseGetAccentColor()) or Color3.fromRGB(255, 60, 172)
    if SideAvatarStroke and SideAvatarStroke.Parent then
        SideAvatarStroke.Color = acc
    end
    if SideStatusLabel and SideStatusLabel.Parent then
        SideStatusLabel.TextColor3 = acc
    end
end
local function performSearch(query)
    query = string.lower(string.gsub(query or "", "^%s*(.-)%s*$", "%1"))
    if query == "" then
        for _, page in pairs(pages) do
            for _, child in ipairs(page:GetChildren()) do
                if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                    child.Visible = true
                end
            end
        end
        return
    end
    local firstMatchTab = nil
    for tabName, page in pairs(pages) do
        local tabMatched = false
        for _, child in ipairs(page:GetChildren()) do
            if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                local lbl = child:FindFirstChild("Label") or child:FindFirstChildOfClass("TextLabel")
                local rowName = string.lower(child.Name .. " " .. (lbl and lbl.Text or ""))
                local isMatch = (string.find(rowName, query, 1, true) ~= nil)
                child.Visible = isMatch
                if isMatch then
                    tabMatched = true
                end
            end
        end
        if tabMatched and not firstMatchTab then
            firstMatchTab = tabName
        end
    end
    if firstMatchTab and setTab then
        setTab(firstMatchTab)
    end
end
if SearchBox then
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        performSearch(SearchBox.Text)
    end)
end
function section(parent, text, order)
    local label = Instance.new("TextLabel")
    label.Name = text
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(245, 245, 255)
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0.22
    label.TextSize = 11
    label.Font = Enum.Font.GothamBlack
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, -6, 0, 15)
    label.LayoutOrder = order
    label.ZIndex = 8
    label.Parent = parent
    return label
end
function baseRow(parent, labelText, order)
    local row = Instance.new("Frame")
    row.Name = labelText
    row.BackgroundColor3 = COLORS.row
    row.BackgroundTransparency = 0.3
    row.Size = UDim2.new(1, -4, 0, 34)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 4
    row.Parent = parent
    corner(row, 9)
    stroke(row, COLORS.strokeSoft, 1.15, 0.38)
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(245, 245, 255)
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0.25
    label.TextSize = 12
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(1, -132, 1, 0)
    label.ZIndex = 5
    label.Parent = row
    row.MouseEnter:Connect(function()
        tween(row, { BackgroundTransparency = 0.22 })
    end)
    row.MouseLeave:Connect(function()
        tween(row, { BackgroundTransparency = 0.3 })
    end)
    return row
end
function textboxRow(parent, labelText, value, order)
    local row = baseRow(parent, labelText, order)
    local box = Instance.new("TextBox")
    box.Name = "ValueBox"
    box.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    box.BackgroundTransparency = 0.18
    box.Text = tostring(value or "")
    box.TextColor3 = COLORS.white
    box.TextSize = 12
    box.Font = Enum.Font.GothamSemibold
    box.ClearTextOnFocus = false
    box.Size = UDim2.new(0, 58, 0, 24)
    box.Position = UDim2.new(1, -68, 0.5, -12)
    box.BorderSizePixel = 0
    box.ZIndex = 6
    box.Parent = row
    corner(box, 7)
    stroke(box, COLORS.strokeSoft, 1, 0.45)
    return row, box
end
function toggleRow(parent, labelText, default, order)
    local row = baseRow(parent, labelText, order)
    local button = Instance.new("TextButton")
    button.Name = "ToggleButton"
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Position = UDim2.new(0, 0, 0, 0)
    button.AutoButtonColor = false
    button.ZIndex = 7
    button.Parent = row
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.BackgroundColor3 = COLORS.toggleBg
    track.BackgroundTransparency = 0.2
    track.Size = UDim2.new(0, 34, 0, 18)
    track.Position = UDim2.new(1, -44, 0.5, -9)
    track.BorderSizePixel = 0
    track.ZIndex = 5
    track.Parent = button
    corner(track, 9)
    stroke(track, COLORS.strokeSoft, 1, 0.45)
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.BackgroundColor3 = COLORS.knob
    knob.Size = UDim2.new(0, 13, 0, 13)
    knob.Position = default and UDim2.new(1, -16, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    knob.BorderSizePixel = 0
    knob.ZIndex = 6
    knob.Parent = track
    corner(knob, 999)
    local shine = Instance.new("Frame")
    shine.Name = "Shine"
    shine.BackgroundColor3 = COLORS.white
    shine.BackgroundTransparency = 0.72
    shine.Size = UDim2.new(1, -4, 0, 4)
    shine.Position = UDim2.new(0, 2, 0, 2)
    shine.BorderSizePixel = 0
    shine.ZIndex = 7
    shine.Parent = knob
    corner(shine, 4)
    local state = default and true or false
    local trackStroke = track:FindFirstChildOfClass("UIStroke")
    local rowStroke = row:FindFirstChildOfClass("UIStroke")
    local function setVisual(on)
        state = on and true or false
        if playUiSound then
            playUiSound("toggle")
        end
        if triggerHaptic then
            triggerHaptic()
        end
        tween(knob, { Position = state and UDim2.new(1, -16, 0.5, -6) or UDim2.new(0, 3, 0.5, -6) })
        tween(
            track,
            {
                BackgroundTransparency = state and 0.03 or 0.2,
                BackgroundColor3 = state and Color3.fromRGB(36, 36, 46) or COLORS.toggleBg,
            }
        )
        if trackStroke then
            tween(
                trackStroke,
                {
                    Color = state and Color3.fromRGB(255, 255, 255) or COLORS.strokeSoft,
                    Transparency = state and 0.05 or 0.45,
                    Thickness = state and 1.25 or 1,
                }
            )
        end
        if rowStroke then
            tween(
                rowStroke,
                {
                    Color = state and Color3.fromRGB(245, 245, 255) or COLORS.strokeSoft,
                    Transparency = state and 0.12 or 0.38,
                    Thickness = state and 1.25 or 1.15,
                }
            )
        end
        tween(row, { BackgroundTransparency = state and 0.16 or 0.3 })
    end
    setVisual(state)
    return row, setVisual
end
_G.PulseSyncToggleVisuals = function()
    pcall(function()
        if setAutoStealVisual then
            setAutoStealVisual(autoStealEnabled == true)
        end
    end)
    pcall(function()
        if _G.PulseSetNormalRagdollStealVisual then
            _G.PulseSetNormalRagdollStealVisual(_G.PulseNormalRagdollStealEnabled == true)
        end
        if _G.PulseRefreshNormalRagdollStealRow then
            _G.PulseRefreshNormalRagdollStealRow()
        end
        if _G.PulseSetSemiRagdollStealVisual then
            _G.PulseSetSemiRagdollStealVisual(_G.PulseSemiRagdollStealEnabled == true)
        end
        if _G.PulseRefreshSemiRagdollStealRow then
            _G.PulseRefreshSemiRagdollStealRow()
        end
    end)
    pcall(function()
        if setInfJumpVisual then
            setInfJumpVisual(infJumpEnabled == true)
        end
    end)
    pcall(function()
        if setAntiRagdollVisual then
            setAntiRagdollVisual(antiRagdollEnabled == true)
        end
    end)
    pcall(function()
        if setAutoCarrySpeedVisual then
            setAutoCarrySpeedVisual(autoCarrySpeedEnabled == true)
        end
    end)
    pcall(function()
        if setAutoTPVisual then
            setAutoTPVisual(autoTPEnabled == true)
        end
    end)
end
_G.PulseActionToggleRow = function(parent, labelText, default, order)
    local row = baseRow(parent, labelText, order)
    local button = Instance.new("TextButton")
    button.Name = "ToggleButton"
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Position = UDim2.new(0, 0, 0, 0)
    button.AutoButtonColor = false
    button.ZIndex = 7
    button.Parent = row
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.BackgroundColor3 = COLORS.toggleBg
    track.BackgroundTransparency = 0.2
    track.Size = UDim2.new(0, 34, 0, 18)
    track.Position = UDim2.new(1, -44, 0.5, -9)
    track.BorderSizePixel = 0
    track.ZIndex = 5
    track.Parent = button
    corner(track, 9)
    stroke(track, COLORS.strokeSoft, 1, 0.45)
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.BackgroundColor3 = COLORS.knob
    knob.Size = UDim2.new(0, 13, 0, 13)
    knob.Position = default and UDim2.new(1, -16, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    knob.BorderSizePixel = 0
    knob.ZIndex = 6
    knob.Parent = track
    corner(knob, 999)
    local shine = Instance.new("Frame")
    shine.Name = "Shine"
    shine.BackgroundColor3 = COLORS.white
    shine.BackgroundTransparency = 0.72
    shine.Size = UDim2.new(1, -4, 0, 4)
    shine.Position = UDim2.new(0, 2, 0, 2)
    shine.BorderSizePixel = 0
    shine.ZIndex = 7
    shine.Parent = knob
    corner(shine, 4)
    local trackStroke = track:FindFirstChildOfClass("UIStroke")
    local rowStroke = row:FindFirstChildOfClass("UIStroke")
    local function setVisual(on)
        local state = on and true or false
        tween(knob, { Position = state and UDim2.new(1, -16, 0.5, -6) or UDim2.new(0, 3, 0.5, -6) })
        tween(
            track,
            {
                BackgroundTransparency = state and 0.03 or 0.2,
                BackgroundColor3 = state and Color3.fromRGB(36, 36, 46) or COLORS.toggleBg,
            }
        )
        if trackStroke then
            tween(
                trackStroke,
                {
                    Color = state and Color3.fromRGB(255, 255, 255) or COLORS.strokeSoft,
                    Transparency = state and 0.05 or 0.45,
                    Thickness = state and 1.25 or 1,
                }
            )
        end
        if rowStroke then
            tween(
                rowStroke,
                {
                    Color = state and Color3.fromRGB(245, 245, 255) or COLORS.strokeSoft,
                    Transparency = state and 0.12 or 0.38,
                    Thickness = state and 1.25 or 1.15,
                }
            )
        end
        tween(row, { BackgroundTransparency = state and 0.16 or 0.3 })
    end
    setVisual(default)
    return row, setVisual, button
end
function dropdownRow(parent, labelText, value, order)
    local row = baseRow(parent, labelText, order)
    local select = Instance.new("TextButton")
    select.Name = "Dropdown"
    select.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    select.BackgroundTransparency = 0.18
    select.Text = tostring(value or "None") .. " ▼"
    select.TextColor3 = COLORS.white
    select.TextSize = 11
    select.Font = Enum.Font.GothamSemibold
    select.Size = UDim2.new(0, 70, 0, 24)
    select.Position = UDim2.new(1, -80, 0.5, -12)
    select.BorderSizePixel = 0
    select.ZIndex = 6
    select.Parent = row
    corner(select, 7)
    stroke(select, COLORS.strokeSoft, 1, 0.45)
    return row, select
end
local animationPackValueLabel = nil
function refreshAnimationPackRow()
    if animationPackValueLabel then
        animationPackValueLabel.Text = selectedAnimationPack
    end
end
function animationPackRow(parent, order)
    local row = baseRow(parent, "Animation Pack", order)
    row.Size = UDim2.new(1, -4, 0, 42)
    local label = row:FindFirstChild("Label")
    if label then
        label.Text = "Animation Pack"
        label.Size = UDim2.new(0, 112, 1, 0)
        label.TextSize = 11
    end
    local left = Instance.new("TextButton")
    left.Name = "LeftArrow"
    left.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    left.BackgroundTransparency = 0.18
    left.Text = "<"
    left.TextColor3 = COLORS.white
    left.TextSize = 12
    left.Font = Enum.Font.GothamSemibold
    left.Size = UDim2.new(0, 42, 0, 28)
    left.Position = UDim2.new(1, -156, 0.5, -14)
    left.BorderSizePixel = 0
    left.ZIndex = 6
    left.Parent = row
    corner(left, 8)
    stroke(left, COLORS.strokeSoft, 1, 0.45)
    animationPackValueLabel = Instance.new("TextLabel")
    animationPackValueLabel.Name = "AnimationPackValue"
    animationPackValueLabel.BackgroundTransparency = 1
    animationPackValueLabel.Text = selectedAnimationPack
    animationPackValueLabel.TextColor3 = COLORS.white
    animationPackValueLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    animationPackValueLabel.TextStrokeTransparency = 0.25
    animationPackValueLabel.TextSize = 11
    animationPackValueLabel.Font = Enum.Font.GothamSemibold
    animationPackValueLabel.TextXAlignment = Enum.TextXAlignment.Center
    animationPackValueLabel.Size = UDim2.new(0, 62, 1, 0)
    animationPackValueLabel.Position = UDim2.new(1, -112, 0, 0)
    animationPackValueLabel.ZIndex = 6
    animationPackValueLabel.Parent = row
    local right = Instance.new("TextButton")
    right.Name = "RightArrow"
    right.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    right.BackgroundTransparency = 0.18
    right.Text = ">"
    right.TextColor3 = COLORS.white
    right.TextSize = 12
    right.Font = Enum.Font.GothamSemibold
    right.Size = UDim2.new(0, 42, 0, 28)
    right.Position = UDim2.new(1, -48, 0.5, -14)
    right.BorderSizePixel = 0
    right.ZIndex = 6
    right.Parent = row
    corner(right, 8)
    stroke(right, COLORS.strokeSoft, 1, 0.45)
    local function setPackIndex(nextIndex)
        if nextIndex < 1 then
            nextIndex = #AnimationPackList
        end
        if nextIndex > #AnimationPackList then
            nextIndex = 1
        end
        AnimationPackIndex = nextIndex
        selectedAnimationPack = AnimationPackList[AnimationPackIndex]
        refreshAnimationPackRow()
        applyAnimationPack(selectedAnimationPack)
        if savePulseConfig then
            pcall(savePulseConfig)
        end
    end
    left.MouseButton1Click:Connect(function()
        setPackIndex(AnimationPackIndex - 1)
    end)
    right.MouseButton1Click:Connect(function()
        setPackIndex(AnimationPackIndex + 1)
    end)
    return row
end
PULSE_KEY_DISPLAY_NAMES = {
    ButtonA = "✕",
    ButtonB = "○",
    ButtonX = "□",
    ButtonY = "△",
    ButtonL1 = "L1",
    ButtonR1 = "R1",
    ButtonL2 = "L2",
    ButtonR2 = "R2",
    Thumbstick1 = "L3",
    Thumbstick2 = "R3",
    ButtonSelect = "Select",
    ButtonStart = "Start",
    DPadUp = "↑",
    DPadDown = "↓",
    DPadLeft = "←",
    DPadRight = "→",
}
function pulseIsGamepadKey(key)
    if not key then
        return false
    end
    local name = tostring(key):gsub("Enum.KeyCode.", "")
    return name:sub(1, 6) == "Button" or name:sub(1, 4) == "DPad" or name:sub(1, 11) == "Thumbstick"
end
function keyName(key)
    if not key then
        return "None"
    end
    local name = tostring(key):gsub("Enum.KeyCode.", "")
    return PULSE_KEY_DISPLAY_NAMES[name] or name
end
function refreshSpeedKeybindButton(keyId)
    local btn = speedKeybindButtons[keyId]
    if btn then
        if listeningForSpeedKey == keyId then
            btn.Text = "Press..."
            btn.TextSize = 11
        else
            btn.Text = keyName(speedKeybinds[keyId])
            btn.TextSize = pulseIsGamepadKey(speedKeybinds[keyId]) and 16 or 11
        end
    end
end
function refreshAllSpeedKeybinds()
    for keyId in pairs(speedKeybindButtons) do
        refreshSpeedKeybindButton(keyId)
    end
end
function refreshTPDownKeybind()
    if tpDownKeybindButton then
        tpDownKeybindButton.Text = listeningForTPDownKey and "Press..." or keyName(tpDownKeybind)
        tpDownKeybindButton.TextSize = (not listeningForTPDownKey and pulseIsGamepadKey(tpDownKeybind)) and 16 or 11
    end
end
function tpDownKeybindRow(parent, order)
    local row = baseRow(parent, "TP Down", order)
    local btn = Instance.new("TextButton")
    btn.Name = "TPDownKeybindButton"
    btn.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    btn.BackgroundTransparency = 0.18
    btn.Text = keyName(tpDownKeybind)
    btn.TextColor3 = COLORS.white
    btn.TextSize = pulseIsGamepadKey(tpDownKeybind) and 16 or 11
    btn.Font = Enum.Font.GothamSemibold
    btn.Size = UDim2.new(0, 56, 0, 24)
    btn.Position = UDim2.new(1, -64, 0.5, -12)
    btn.BorderSizePixel = 0
    btn.ZIndex = 6
    btn.AutoButtonColor = false
    btn.Parent = row
    corner(btn, 7)
    stroke(btn, COLORS.strokeSoft, 1, 0.45)
    tpDownKeybindButton = btn
    btn.Activated:Connect(function()
        listeningForSpeedKey = nil
        listeningForTPDownKey = true
        keybindListenStartedAt = tick()
        refreshAllSpeedKeybinds()
        refreshTPDownKeybind()
    end)
    return row, btn
end
function speedKeybindRow(parent, labelText, keyId, order)
    local row = baseRow(parent, labelText, order)
    local btn = Instance.new("TextButton")
    btn.Name = "KeybindButton"
    btn.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    btn.BackgroundTransparency = 0.18
    btn.Text = keyName(speedKeybinds[keyId])
    btn.TextColor3 = COLORS.white
    btn.TextSize = pulseIsGamepadKey(speedKeybinds[keyId]) and 16 or 11
    btn.Font = Enum.Font.GothamSemibold
    btn.Size = UDim2.new(0, 56, 0, 24)
    btn.Position = UDim2.new(1, -64, 0.5, -12)
    btn.BorderSizePixel = 0
    btn.ZIndex = 6
    btn.AutoButtonColor = false
    btn.Parent = row
    corner(btn, 7)
    stroke(btn, COLORS.strokeSoft, 1, 0.45)
    speedKeybindButtons[keyId] = btn
    btn.Activated:Connect(function()
        listeningForSpeedKey = keyId
        listeningForTPDownKey = false
        keybindListenStartedAt = tick()
        refreshAllSpeedKeybinds()
        refreshTPDownKeybind()
    end)
    return row, btn
end
local normalModeValueLabel = nil
local laggerModeValueLabel = nil
local aimbotButtonLabel = nil
local aimbotSpeedLabel = nil
local laggerAimbotSpeedLabel = nil
local combatAimbotKeybindLabel = nil
function getAimbotModeDisplay()
    if selectedAimbotMode == "Anti Bypass" or selectedAimbotMode == "Bypass" then
        return "Anti Bypass"
    end
    return "Normal"
end
function refreshAimbotButtonLabel()
    if aimbotButtonLabel then
        aimbotButtonLabel.Text = getAimbotModeDisplay() .. " Aimbot"
    end
end
function refreshAimbotModeLabels()
    if aimbotSpeedLabel then
        aimbotSpeedLabel.Text = "Normal Chase Speed"
    end
    if laggerAimbotSpeedLabel then
        laggerAimbotSpeedLabel.Text = "Lagger Chase Speed"
    end
    if combatAimbotKeybindLabel then
        combatAimbotKeybindLabel.Text = "Bat Aimbot"
    end
    refreshAimbotButtonLabel()
end
refreshSpeedModeRows = function()
    if normalModeValueLabel then
        normalModeValueLabel.Text = (currentSpeedMode == "Carry") and "Carry" or "Normal"
    end
    if laggerModeValueLabel then
        laggerModeValueLabel.Text = (currentSpeedMode == "Lagger Carry") and "Lagger Carry" or "Lagger"
    end
    if _G.PulseLagger2ModeValueLabel then
        _G.PulseLagger2ModeValueLabel.Text = (currentSpeedMode == "Lagger Carry 2") and "Lagger Carry 2" or "Lagger 2"
    end
    pcall(function()
        local holding = isCarryingBrainrot(LP.Character)
        for _, lbl in ipairs({ normalModeValueLabel, laggerModeValueLabel, _G.PulseLagger2ModeValueLabel }) do
            if lbl and lbl.Parent then
                local row = lbl.Parent
                if holding then
                    row.BackgroundTransparency = 0.55
                    lbl.TextTransparency = 0.4
                else
                    row.BackgroundTransparency = 0.42
                    lbl.TextTransparency = 0
                end
            end
        end
    end)
end
function modeDisplayRow(parent, order, side)
    local row = baseRow(parent, "Mode", order)
    row.Size = UDim2.new(1, -4, 0, 42)
    row.BackgroundTransparency = 0.42
    local label = row:FindFirstChild("Label")
    if label then
        label.Text = "Mode"
        label.TextSize = 11
        label.Size = UDim2.new(0, 110, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.TextColor3 = Color3.fromRGB(245, 245, 255)
    end
    local value = Instance.new("TextLabel")
    value.Name = "ModeValue"
    value.BackgroundTransparency = 1
    value.Text = side == "Normal" and "Normal" or ((side == "Lagger 2") and "Lagger 2" or "Lagger")
    value.TextColor3 = Color3.fromRGB(255, 255, 255)
    value.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    value.TextStrokeTransparency = 0.25
    value.TextSize = 12
    value.Font = Enum.Font.GothamSemibold
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.Position = UDim2.new(1, -132, 0, 0)
    value.Size = UDim2.new(0, 120, 1, 0)
    value.ZIndex = 6
    value.Parent = row
    local click = Instance.new("TextButton")
    click.Name = "ModeClick"
    click.BackgroundTransparency = 1
    click.Text = ""
    click.Size = UDim2.new(1, 0, 1, 0)
    click.Position = UDim2.new(0, 0, 0, 0)
    click.AutoButtonColor = false
    click.ZIndex = 8
    click.Parent = row
    if side == "Normal" then
        normalModeValueLabel = value
        click.MouseButton1Click:Connect(function()
            if isCarryingBrainrot(LP.Character) then
                pcall(function()
                    _safeNotify("BLOCKED: Normal disabled while holding")
                end)
                return
            end
            setSpeedMode(currentSpeedMode == "Normal" and "Carry" or "Normal")
        end)
    elseif side == "Lagger 2" then
        _G.PulseLagger2ModeValueLabel = value
        click.MouseButton1Click:Connect(function()
            if isCarryingBrainrot(LP.Character) then
                pcall(function()
                    _safeNotify("BLOCKED: Lagger 2 Normal disabled while holding")
                end)
                return
            end
            setSpeedMode(currentSpeedMode == "Lagger 2" and "Lagger Carry 2" or "Lagger 2")
        end)
    else
        laggerModeValueLabel = value
        click.MouseButton1Click:Connect(function()
            if isCarryingBrainrot(LP.Character) then
                pcall(function()
                    _safeNotify("BLOCKED: Lagger Normal disabled while holding")
                end)
                return
            end
            setSpeedMode(currentSpeedMode == "Lagger" and "Lagger Carry" or "Lagger")
        end)
    end
    refreshSpeedModeRows()
    return row, value
end
function aimbotModeButtonRow(parent, order)
    local row, setVisual = toggleRow(parent, tostring(selectedAimbotMode) .. " Aimbot", false, order)
    aimbotButtonLabel = row and row:FindFirstChild("Label")
    _G.PulseAimbotSetVisual = setVisual
    refreshAimbotButtonLabel()
    if _G.PulseRefreshAimbotVisual then
        _G.PulseRefreshAimbotVisual()
    end
    _pulseBtn = row and row:FindFirstChild("ToggleButton")
    if _pulseBtn then
        _pulseBtn.Activated:Connect(function()
            if _G.PulseToggleSelectedAimbot then
                _G.PulseToggleSelectedAimbot()
            end
        end)
    end
    return row, setVisual
end
function autoStealSelectorRow(parent, order)
    local holder = Instance.new("Frame")
    holder.Name = "Steal Mode"
    holder.BackgroundColor3 = COLORS.row
    holder.BackgroundTransparency = 0.28
    holder.Size = UDim2.new(1, -4, 0, 42)
    holder.BorderSizePixel = 0
    holder.LayoutOrder = order
    holder.ZIndex = 4
    holder.ClipsDescendants = true
    holder.Parent = parent
    corner(holder, 9)
    stroke(holder, COLORS.strokeSoft, 1.15, 0.38)
    local title = Instance.new("TextLabel")
    title.Name = "Label"
    title.BackgroundTransparency = 1
    title.Text = "Steal Mode"
    title.TextColor3 = Color3.fromRGB(245, 245, 255)
    title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    title.TextStrokeTransparency = 0.25
    title.TextSize = 12
    title.Font = Enum.Font.GothamSemibold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0, 12, 0, 0)
    title.Size = UDim2.new(1, -86, 0, 42)
    title.ZIndex = 8
    title.Parent = holder
    local value = Instance.new("TextLabel")
    value.Name = "ModeValue"
    value.BackgroundTransparency = 1
    value.Text = "Normal"
    value.TextColor3 = Color3.fromRGB(200, 200, 205)
    value.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    value.TextStrokeTransparency = 0.4
    value.TextSize = 11
    value.Font = Enum.Font.GothamMedium
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.Position = UDim2.new(1, -146, 0, 0)
    value.Size = UDim2.new(0, 84, 0, 42)
    value.ZIndex = 8
    value.Parent = holder
    local pointer = Instance.new("TextLabel")
    pointer.Name = "Pointer"
    pointer.BackgroundTransparency = 1
    pointer.AnchorPoint = Vector2.new(0, 0)
    pointer.Position = UDim2.new(1, -38, 0, 9)
    pointer.Size = UDim2.new(0, 30, 0, 24)
    pointer.Rotation = 0
    pointer.TextColor3 = COLORS.white
    pointer.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    pointer.TextStrokeTransparency = 0.20
    pointer.TextSize = 18
    pointer.Font = Enum.Font.GothamBlack
    pointer.ZIndex = 10
    pointer.Parent = holder
    pulseStyleAdaptArrow(pointer)
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Text = ""
    header.AutoButtonColor = false
    header.Size = UDim2.new(1, 0, 0, 42)
    header.ZIndex = 9
    header.Parent = holder
    local optionBtns = {}
    local function refreshOptions()
        for _, name in ipairs({ "Normal", "Normal V2", "Semi" }) do
            local btn = optionBtns[name]
            if btn then
                local active = (selectedStealMode == name)
                btn.BackgroundTransparency = active and 0.08 or 0.5
                btn.TextColor3 = active and COLORS.white or Color3.fromRGB(190, 190, 200)
                local st = btn:FindFirstChildOfClass("UIStroke")
                if st then
                    st.Color = active and Color3.fromRGB(245, 245, 255) or COLORS.strokeSoft
                    st.Transparency = active and 0.12 or 0.4
                end
            end
        end
        value.Text = selectedStealMode
    end
    local function setMode(mode)
        if mode ~= "Semi" and mode ~= "Normal V2" then
            mode = "Normal"
        end
        if _G.PulseNormalAutoStealRagdollPause and _G.PulseNormalAutoStealRagdollPause.active then
            _G.PulseNormalAutoStealRagdollPause.cancel(true)
        end
        if mode ~= "Semi" and _G.PulseSemiRagdollStealController and _G.PulseSemiRagdollStealController.active then
            _G.PulseSemiRagdollStealController.cancel()
        end
        _G.PulseStealRadii = _G.PulseStealRadii or { Normal = 62, Semi = 9, ["Normal V2"] = 62 }
        _G.PulseStealRadii[selectedStealMode] = tonumber(autoStealRadius) or _G.PulseStealRadii[selectedStealMode]
        selectedStealMode = mode
        if _G.PulseRefreshNormalRagdollStealRow then
            _G.PulseRefreshNormalRagdollStealRow()
        end
        if _G.PulseRefreshSemiRagdollStealRow then
            _G.PulseRefreshSemiRagdollStealRow()
        end
        if mode == "Normal" or mode == "Normal V2" then
            softStealEnabled = false
            _G.PulseSoftStealEnabled = false
            if setSoftStealVisual then
                setSoftStealVisual(false)
            end
            if softStealRow then
                softStealRow.Visible = false
            end
        else
            if softStealRow then
                softStealRow.Visible = true
            end
        end
        autoStealRadius = _G.PulseStealRadii[selectedStealMode] or ((selectedStealMode == "Semi") and 9 or 62)
        if autoStealRadiusBox then
            autoStealRadiusBox.Text = tostring(autoStealRadius)
        end
        savePulseConfig()
        if _G.PulseNormalAutoStealSetRadius then
            _G.PulseNormalAutoStealSetRadius(_G.PulseStealRadii.Normal or 62)
        end
        if _G.PulseSemiAutoStealSetRadius then
            _G.PulseSemiAutoStealSetRadius(_G.PulseStealRadii.Semi or 9)
        end
        if _G.PulseNormalV2AutoStealSetRadius then
            _G.PulseNormalV2AutoStealSetRadius(_G.PulseStealRadii["Normal V2"] or 62)
        end
        if _G.PulseAutoStealSync then
            _G.PulseAutoStealSync()
        end
        refreshOptions()
    end
    local isOpen = false
    local function setOpen(open)
        isOpen = open and true or false
        for _, btn in pairs(optionBtns) do
            btn.Visible = isOpen
        end
        tween(pointer, { Rotation = isOpen and 180 or 0 }, 0.15)
        tween(holder, { Size = isOpen and UDim2.new(1, -4, 0, 162) or UDim2.new(1, -4, 0, 42) }, 0.18)
    end
    header.MouseButton1Click:Connect(function()
        setOpen(not isOpen)
    end)
    for i, name in ipairs({ "Normal", "Normal V2", "Semi" }) do
        local btn = Instance.new("TextButton")
        btn.Name = "Option" .. name
        btn.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
        btn.BackgroundTransparency = 0.5
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(190, 190, 200)
        btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        btn.TextStrokeTransparency = 0.35
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamSemibold
        btn.Size = UDim2.new(1, -16, 0, 32)
        btn.Position = UDim2.new(0, 8, 0, 48 + (i - 1) * 38)
        btn.BorderSizePixel = 0
        btn.ZIndex = 8
        btn.AutoButtonColor = false
        btn.Visible = false
        btn.Parent = holder
        corner(btn, 8)
        stroke(btn, COLORS.strokeSoft, 1, 0.4)
        optionBtns[name] = btn
        btn.MouseButton1Click:Connect(function()
            setMode(name)
            setOpen(false)
        end)
    end
    setMode(selectedStealMode)
    return holder, setMode
end
function antiRagdollSelectorRow(parent, order)
    local holder = Instance.new("Frame")
    holder.Name = "Ragdoll Mode"
    holder.BackgroundColor3 = COLORS.row
    holder.BackgroundTransparency = 0.28
    holder.Size = UDim2.new(1, -4, 0, 42)
    holder.BorderSizePixel = 0
    holder.LayoutOrder = order
    holder.ZIndex = 4
    holder.ClipsDescendants = true
    holder.Parent = parent
    corner(holder, 9)
    stroke(holder, COLORS.strokeSoft, 1.15, 0.38)
    local title = Instance.new("TextLabel")
    title.Name = "Label"
    title.BackgroundTransparency = 1
    title.Text = "Ragdoll Mode"
    title.TextColor3 = Color3.fromRGB(245, 245, 255)
    title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    title.TextStrokeTransparency = 0.25
    title.TextSize = 12
    title.Font = Enum.Font.GothamSemibold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0, 12, 0, 0)
    title.Size = UDim2.new(1, -86, 0, 42)
    title.ZIndex = 8
    title.Parent = holder
    local value = Instance.new("TextLabel")
    value.Name = "ModeValue"
    value.BackgroundTransparency = 1
    value.Text = "Splatter"
    value.TextColor3 = Color3.fromRGB(200, 200, 205)
    value.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    value.TextStrokeTransparency = 0.4
    value.TextSize = 11
    value.Font = Enum.Font.GothamMedium
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.Position = UDim2.new(1, -146, 0, 0)
    value.Size = UDim2.new(0, 84, 0, 42)
    value.ZIndex = 8
    value.Parent = holder
    local pointer = Instance.new("TextLabel")
    pointer.Name = "Pointer"
    pointer.BackgroundTransparency = 1
    pointer.AnchorPoint = Vector2.new(0, 0)
    pointer.Position = UDim2.new(1, -38, 0, 9)
    pointer.Size = UDim2.new(0, 30, 0, 24)
    pointer.Rotation = 0
    pointer.TextColor3 = COLORS.white
    pointer.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    pointer.TextStrokeTransparency = 0.20
    pointer.TextSize = 18
    pointer.Font = Enum.Font.GothamBlack
    pointer.ZIndex = 10
    pointer.Parent = holder
    pulseStyleAdaptArrow(pointer)
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Text = ""
    header.AutoButtonColor = false
    header.Size = UDim2.new(1, 0, 0, 42)
    header.ZIndex = 9
    header.Parent = holder
    local optionBtns = {}
    local function refreshOptions()
        for _, name in ipairs({ "Splatter", "No Splatter" }) do
            local btn = optionBtns[name]
            if btn then
                local active = (antiRagdollMode == name)
                btn.BackgroundTransparency = active and 0.08 or 0.5
                btn.TextColor3 = active and COLORS.white or Color3.fromRGB(190, 190, 200)
                local st = btn:FindFirstChildOfClass("UIStroke")
                if st then
                    st.Color = active and Color3.fromRGB(245, 245, 255) or COLORS.strokeSoft
                    st.Transparency = active and 0.12 or 0.4
                end
            end
        end
        value.Text = (antiRagdollMode == "No Splatter") and "No Splatter" or "Splatter"
    end
    local function setMode(mode)
        if mode ~= "No Splatter" then
            mode = "Splatter"
        end
        antiRagdollMode = mode
        savePulseConfig()
        refreshOptions()
    end
    local isOpen = false
    local function setOpen(open)
        isOpen = open and true or false
        for _, btn in pairs(optionBtns) do
            btn.Visible = isOpen
        end
        tween(pointer, { Rotation = isOpen and 180 or 0 }, 0.15)
        tween(holder, { Size = isOpen and UDim2.new(1, -4, 0, 124) or UDim2.new(1, -4, 0, 42) }, 0.18)
    end
    header.MouseButton1Click:Connect(function()
        setOpen(not isOpen)
    end)
    for i, name in ipairs({ "Splatter", "No Splatter" }) do
        local btn = Instance.new("TextButton")
        btn.Name = "Option" .. name
        btn.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
        btn.BackgroundTransparency = 0.5
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(190, 190, 200)
        btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        btn.TextStrokeTransparency = 0.35
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamSemibold
        btn.Size = UDim2.new(1, -16, 0, 32)
        btn.Position = UDim2.new(0, 8, 0, 48 + (i - 1) * 38)
        btn.BorderSizePixel = 0
        btn.ZIndex = 8
        btn.AutoButtonColor = false
        btn.Visible = false
        btn.Parent = holder
        corner(btn, 8)
        stroke(btn, COLORS.strokeSoft, 1, 0.4)
        optionBtns[name] = btn
        btn.MouseButton1Click:Connect(function()
            setMode(name)
            setOpen(false)
        end)
    end
    setMode(antiRagdollMode)
    return holder, setMode
end
function mobileButtonStyleSelectorRow(parent, order)
    local styleDisplayNames = { ["Button 1"] = "Compact", ["Button 2"] = "Square" }
    local holder = Instance.new("Frame")
    holder.Name = "Button Style"
    holder.BackgroundColor3 = COLORS.row
    holder.BackgroundTransparency = 0.28
    holder.Size = UDim2.new(1, -4, 0, 42)
    holder.BorderSizePixel = 0
    holder.LayoutOrder = order
    holder.ZIndex = 4
    holder.ClipsDescendants = true
    holder.Parent = parent
    corner(holder, 9)
    stroke(holder, COLORS.strokeSoft, 1.15, 0.38)
    local title = Instance.new("TextLabel")
    title.Name = "Label"
    title.BackgroundTransparency = 1
    title.Text = "Button Style"
    title.TextColor3 = Color3.fromRGB(245, 245, 255)
    title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    title.TextStrokeTransparency = 0.25
    title.TextSize = 12
    title.Font = Enum.Font.GothamSemibold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0, 12, 0, 0)
    title.Size = UDim2.new(1, -86, 0, 42)
    title.ZIndex = 8
    title.Parent = holder
    local value = Instance.new("TextLabel")
    value.Name = "ModeValue"
    value.BackgroundTransparency = 1
    value.Text = "Square"
    value.TextColor3 = Color3.fromRGB(200, 200, 205)
    value.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    value.TextStrokeTransparency = 0.4
    value.TextSize = 11
    value.Font = Enum.Font.GothamMedium
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.Position = UDim2.new(1, -146, 0, 0)
    value.Size = UDim2.new(0, 84, 0, 42)
    value.ZIndex = 8
    value.Parent = holder
    local pointer = Instance.new("TextLabel")
    pointer.Name = "Pointer"
    pointer.BackgroundTransparency = 1
    pointer.AnchorPoint = Vector2.new(0, 0)
    pointer.Position = UDim2.new(1, -38, 0, 9)
    pointer.Size = UDim2.new(0, 30, 0, 24)
    pointer.Rotation = 0
    pointer.TextColor3 = COLORS.white
    pointer.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    pointer.TextStrokeTransparency = 0.20
    pointer.TextSize = 18
    pointer.Font = Enum.Font.GothamBlack
    pointer.ZIndex = 10
    pointer.Parent = holder
    pulseStyleAdaptArrow(pointer)
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Text = ""
    header.AutoButtonColor = false
    header.Size = UDim2.new(1, 0, 0, 42)
    header.ZIndex = 9
    header.Parent = holder
    local optionBtns = {}
    local function refreshOptions()
        for _, name in ipairs({ "Button 1", "Button 2" }) do
            local btn = optionBtns[name]
            if btn then
                local active = (mobileButtonStyle == name)
                btn.BackgroundTransparency = active and 0.08 or 0.5
                btn.TextColor3 = active and COLORS.white or Color3.fromRGB(190, 190, 200)
                local st = btn:FindFirstChildOfClass("UIStroke")
                if st then
                    st.Color = active and Color3.fromRGB(245, 245, 255) or COLORS.strokeSoft
                    st.Transparency = active and 0.12 or 0.4
                end
            end
        end
        value.Text = styleDisplayNames[mobileButtonStyle] or "Square"
    end
    local function setMode(mode)
        if mode ~= "Button 1" then
            mode = "Button 2"
        end
        mobileButtonStyle = mode
        savePulseConfig()
        if _G.PulseRebuildMobileButtons then
            _G.PulseRebuildMobileButtons(mode)
        end
        refreshOptions()
    end
    local isOpen = false
    local function setOpen(open)
        isOpen = open and true or false
        for _, btn in pairs(optionBtns) do
            btn.Visible = isOpen
        end
        tween(pointer, { Rotation = isOpen and 180 or 0 }, 0.15)
        tween(holder, { Size = isOpen and UDim2.new(1, -4, 0, 124) or UDim2.new(1, -4, 0, 42) }, 0.18)
    end
    header.MouseButton1Click:Connect(function()
        setOpen(not isOpen)
    end)
    for i, name in ipairs({ "Button 1", "Button 2" }) do
        local btn = Instance.new("TextButton")
        btn.Name = "Option" .. name
        btn.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
        btn.BackgroundTransparency = 0.5
        btn.Text = styleDisplayNames[name] or name
        btn.TextColor3 = Color3.fromRGB(190, 190, 200)
        btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        btn.TextStrokeTransparency = 0.35
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamSemibold
        btn.Size = UDim2.new(1, -16, 0, 32)
        btn.Position = UDim2.new(0, 8, 0, 48 + (i - 1) * 38)
        btn.BorderSizePixel = 0
        btn.ZIndex = 8
        btn.AutoButtonColor = false
        btn.Visible = false
        btn.Parent = holder
        corner(btn, 8)
        stroke(btn, COLORS.strokeSoft, 1, 0.4)
        optionBtns[name] = btn
        btn.MouseButton1Click:Connect(function()
            setMode(name)
            setOpen(false)
        end)
    end
    setMode(mobileButtonStyle)
    return holder, setMode
end
task.wait()
local speedCustomizerGui = nil
local speedCustomizerEnabled = _G.PulseSpeedCustomizerOn ~= false
local function setupSpeedCustomizer()
    if speedCustomizerGui then
        return
    end
    speedCustomizerGui = Instance.new("ScreenGui")
    speedCustomizerGui.Name = "PulseSpeedCustomizerGui"
    speedCustomizerGui.ResetOnSpawn = false
    speedCustomizerGui.DisplayOrder = 997
    speedCustomizerGui.IgnoreGuiInset = true
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(speedCustomizerGui)
        end
    end)
    speedCustomizerGui.Parent = PlayerGui
    local holder = Instance.new("Frame")
    holder.Name = "SpeedCustomizer"
    holder.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    holder.BackgroundTransparency = 0.2
    holder.Size = UDim2.new(0, 185, 0, 36)
    holder.Position = tableToUDim2(savedSpeedCustomizerPositionTable, UDim2.new(0, 20, 0.42, 0))
    holder.BorderSizePixel = 0
    holder.ZIndex = 50
    holder.ClipsDescendants = true
    holder.Parent = speedCustomizerGui
    corner(holder, 10)
    stroke(holder, Color3.fromRGB(245, 245, 255), 1.15, 0.28)
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Text = "SPEED CUSTOMIZER"
    title.TextColor3 = Color3.fromRGB(245, 245, 255)
    title.TextSize = 10
    title.Font = Enum.Font.GothamBlack
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0, 10, 0, 0)
    title.Size = UDim2.new(1, -44, 0, 36)
    title.ZIndex = 52
    title.Parent = holder
    local pointer = Instance.new("TextLabel")
    pointer.Name = "Pointer"
    pointer.BackgroundTransparency = 1
    pointer.Position = UDim2.new(1, -32, 0, 6)
    pointer.Size = UDim2.new(0, 24, 0, 24)
    pointer.Rotation = 0
    pointer.TextColor3 = COLORS.white
    pointer.TextSize = 16
    pointer.Font = Enum.Font.GothamBlack
    pointer.ZIndex = 53
    pointer.Parent = holder
    pulseStyleAdaptArrow(pointer)
    local headerBtn = Instance.new("TextButton")
    headerBtn.Name = "HeaderToggle"
    headerBtn.BackgroundTransparency = 1
    headerBtn.Text = ""
    headerBtn.Size = UDim2.new(1, 0, 0, 36)
    headerBtn.ZIndex = 54
    headerBtn.Parent = holder
    local scDragging = false
    local scDragMoved = false
    local scDragStart = nil
    local scStartPos = nil
    local scDragInput = nil
    local scDragEndedAt = 0
    local function beginSpeedCustomizerDrag(input)
        if _G.PulseGuiLocked == true then
            return
        end
        if
            input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end
        scDragging = true
        scDragMoved = false
        scDragStart = input.Position
        local vp0 = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
        scStartPos = Vector2.new(
            holder.Position.X.Scale * vp0.X + holder.Position.X.Offset,
            holder.Position.Y.Scale * vp0.Y + holder.Position.Y.Offset
        )
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                local didMove = scDragMoved
                scDragging = false
                scDragInput = nil
                if didMove then
                    scDragEndedAt = tick()
                    savedSpeedCustomizerPositionTable = udim2ToTable(holder.Position)
                    task.defer(function()
                        pcall(savePulseConfig)
                    end)
                end
            end
        end)
    end
    holder.InputBegan:Connect(beginSpeedCustomizerDrag)
    headerBtn.InputBegan:Connect(beginSpeedCustomizerDrag)
    local function trackSpeedCustomizerInput(input)
        if
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        then
            scDragInput = input
        end
    end
    holder.InputChanged:Connect(trackSpeedCustomizerInput)
    headerBtn.InputChanged:Connect(trackSpeedCustomizerInput)
    UserInputService.InputChanged:Connect(function(input)
        if _G.PulseGuiLocked == true then
            scDragging = false
            scDragInput = nil
            return
        end
        if not scDragging or input ~= scDragInput then
            return
        end
        local delta = input.Position - scDragStart
        if not scDragMoved then
            if delta.Magnitude < 5 then
                return
            end
            scDragMoved = true
        end
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
        local targetX = math.clamp(scStartPos.X + delta.X, -holder.AbsoluteSize.X + 48, math.max(0, vp.X - 48))
        local targetY = math.clamp(scStartPos.Y + delta.Y, 0, math.max(0, vp.Y - 36))
        holder.Position = UDim2.fromOffset(targetX, targetY)
    end)
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.BackgroundTransparency = 1
    contentFrame.Position = UDim2.new(0, 8, 0, 38)
    contentFrame.Size = UDim2.new(1, -16, 0, 217)
    contentFrame.ZIndex = 52
    contentFrame.Parent = holder
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = contentFrame
    local function makeMiniInput(lblText, getVal, changeFn)
        local r = Instance.new("Frame")
        r.Size = UDim2.new(1, 0, 0, 26)
        r.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        r.BackgroundTransparency = 0.3
        r.ZIndex = 53
        r.Parent = contentFrame
        corner(r, 6)
        stroke(r, COLORS.strokeSoft, 1, 0.5)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -56, 1, 0)
        l.Position = UDim2.new(0, 6, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = lblText
        l.TextColor3 = Color3.fromRGB(230, 230, 240)
        l.TextSize = 9.5
        l.Font = Enum.Font.GothamBold
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.ZIndex = 54
        l.Parent = r
        local bx = Instance.new("TextBox")
        bx.Size = UDim2.new(0, 46, 0, 20)
        bx.Position = UDim2.new(1, -50, 0.5, -10)
        bx.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
        bx.Text = string.format("%g", tonumber(getVal()) or 0)
        bx.TextColor3 = COLORS.white
        bx.TextSize = 10
        bx.Font = Enum.Font.GothamBlack
        bx.ClearTextOnFocus = false
        bx.ZIndex = 55
        bx.Parent = r
        corner(bx, 5)
        stroke(bx, COLORS.strokeSoft, 1, 0.5)
        bx.FocusLost:Connect(function()
            local v = tonumber(bx.Text)
            if v and v > 0 then
                changeFn(v)
            end
            local cur = getVal()
            bx.Text = string.format("%g", tonumber(cur) or 0)
        end)
        return bx
    end
    local floatNormBox = makeMiniInput("Normal Speed", function()
        return NS
    end, function(v)
        NS = v
        if normalSpeedBox then
            normalSpeedBox.Text = tostring(v)
        end
        savePulseConfig()
    end)
    local floatCarryBox = makeMiniInput("Carry Speed", function()
        return CS
    end, function(v)
        CS = v
        if carrySpeedBox then
            carrySpeedBox.Text = tostring(v)
        end
        savePulseConfig()
    end)
    local floatLaggerBox = makeMiniInput("Lagger Speed", function()
        return LAGGER_SPEED
    end, function(v)
        LAGGER_SPEED = v
        if laggerSpeedBox then
            laggerSpeedBox.Text = tostring(v)
        end
        savePulseConfig()
    end)
    local floatLaggerCarryBox = makeMiniInput("Lagger Carry", function()
        return LAGGER_CARRY_SPEED
    end, function(v)
        LAGGER_CARRY_SPEED = v
        if laggerCarrySpeedBox then
            laggerCarrySpeedBox.Text = tostring(v)
        end
        savePulseConfig()
    end)
    local floatLagger2Box = makeMiniInput("Lagger 2 Speed", function()
        return LAGGER2_SPEED
    end, function(v)
        LAGGER2_SPEED = v
        if lagger2SpeedBox then
            lagger2SpeedBox.Text = tostring(v)
        end
        savePulseConfig()
    end)
    local floatLagger2CarryBox = makeMiniInput("Lagger Carry 2", function()
        return LAGGER2_CARRY_SPEED
    end, function(v)
        LAGGER2_CARRY_SPEED = v
        if lagger2CarrySpeedBox then
            lagger2CarrySpeedBox.Text = tostring(v)
        end
        savePulseConfig()
    end)
    local acRow = Instance.new("Frame")
    acRow.Size = UDim2.new(1, 0, 0, 28)
    acRow.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    acRow.BackgroundTransparency = 0.3
    acRow.ZIndex = 53
    acRow.Parent = contentFrame
    corner(acRow, 6)
    stroke(acRow, COLORS.strokeSoft, 1, 0.5)
    local acLbl = Instance.new("TextLabel")
    acLbl.Size = UDim2.new(1, -56, 1, 0)
    acLbl.Position = UDim2.new(0, 6, 0, 0)
    acLbl.BackgroundTransparency = 1
    acLbl.Text = "Auto Carry"
    acLbl.TextColor3 = Color3.fromRGB(230, 230, 240)
    acLbl.TextSize = 9.5
    acLbl.Font = Enum.Font.GothamBold
    acLbl.TextXAlignment = Enum.TextXAlignment.Left
    acLbl.ZIndex = 54
    acLbl.Parent = acRow
    local acBtn = Instance.new("TextButton")
    acBtn.Size = UDim2.new(0, 46, 0, 20)
    acBtn.Position = UDim2.new(1, -50, 0.5, -10)
    acBtn.BackgroundColor3 = autoCarrySpeedEnabled and Color3.fromRGB(80, 220, 130) or Color3.fromRGB(35, 35, 45)
    acBtn.Text = autoCarrySpeedEnabled and "ON" or "OFF"
    acBtn.TextColor3 = autoCarrySpeedEnabled and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
    acBtn.TextSize = 10
    acBtn.Font = Enum.Font.GothamBlack
    acBtn.AutoButtonColor = false
    acBtn.ZIndex = 55
    acBtn.Parent = acRow
    corner(acBtn, 5)
    acBtn.MouseButton1Click:Connect(function()
        autoCarrySpeedEnabled = not autoCarrySpeedEnabled
        acBtn.BackgroundColor3 = autoCarrySpeedEnabled and Color3.fromRGB(80, 220, 130) or Color3.fromRGB(35, 35, 45)
        acBtn.Text = autoCarrySpeedEnabled and "ON" or "OFF"
        acBtn.TextColor3 = autoCarrySpeedEnabled and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
        if setAutoCarrySpeedVisual then
            setAutoCarrySpeedVisual(autoCarrySpeedEnabled)
        end
        savePulseConfig()
    end)
    local isOpen = false
    local function syncFloatInputs()
        if floatNormBox then
            floatNormBox.Text = string.format("%g", tonumber(NS) or 0)
        end
        if floatCarryBox then
            floatCarryBox.Text = string.format("%g", tonumber(CS) or 0)
        end
        if floatLaggerBox then
            floatLaggerBox.Text = string.format("%g", tonumber(LAGGER_SPEED) or 0)
        end
        if floatLaggerCarryBox then
            floatLaggerCarryBox.Text = string.format("%g", tonumber(LAGGER_CARRY_SPEED) or 0)
        end
        if floatLagger2Box then
            floatLagger2Box.Text = string.format("%g", tonumber(LAGGER2_SPEED) or 0)
        end
        if floatLagger2CarryBox then
            floatLagger2CarryBox.Text = string.format("%g", tonumber(LAGGER2_CARRY_SPEED) or 0)
        end
    end
    local function setOpen(open)
        isOpen = open == true
        if isOpen then
            syncFloatInputs()
        end
        tween(pointer, { Rotation = isOpen and 180 or 0 }, 0.16)
        tween(holder, { Size = isOpen and UDim2.new(0, 185, 0, 258) or UDim2.new(0, 185, 0, 36) }, 0.18)
    end
    headerBtn.MouseButton1Click:Connect(function()
        if scDragMoved or scDragging or (tick() - scDragEndedAt) < 0.12 then
            scDragMoved = false
            return
        end
        setOpen(not isOpen)
    end)
end
setupSpeedCustomizer()
if speedCustomizerGui then
    speedCustomizerGui.Enabled = speedCustomizerEnabled
end
Movement = pages.SPEED
_, setAutoCarrySpeedVisual = toggleRow(Movement, "Auto Carry Speed", autoCarrySpeedEnabled, 4)
do
    local row = Movement:FindFirstChild("Auto Carry Speed")
    _pulseBtn = row and row:FindFirstChild("ToggleButton")
    if _pulseBtn then
        _pulseBtn.Activated:Connect(function()
            autoCarrySpeedEnabled = not autoCarrySpeedEnabled
            if autoCarrySpeedEnabled ~= true and _G.AutoCarrySpeed and _G.AutoCarrySpeed.Disable then
                _G.AutoCarrySpeed.Disable()
            end
            if setAutoCarrySpeedVisual then
                setAutoCarrySpeedVisual(autoCarrySpeedEnabled == true)
            end
            savePulseConfig()
        end)
    end
end
_, autoSwitchDistanceBox = textboxRow(Movement, "Auto Switch Distance", tostring(AUTO_CARRY_BRAINROT_DISTANCE), 4.5)
autoSwitchDistanceBox.FocusLost:Connect(function()
    local v = tonumber(autoSwitchDistanceBox.Text)
    if v and v > 0 and v <= 500 then
        AUTO_CARRY_BRAINROT_DISTANCE = v
    end
    autoSwitchDistanceBox.Text = tostring(AUTO_CARRY_BRAINROT_DISTANCE)
    _G.PulseAutoSwitchDistance = AUTO_CARRY_BRAINROT_DISTANCE
    savePulseConfig()
end)
section(Movement, "NORMAL SPEED", 1)
_, normalSpeedBox = textboxRow(Movement, "Normal Speed", tostring(NS), 2)
normalSpeedBox.FocusLost:Connect(function()
    local v = tonumber(normalSpeedBox.Text)
    if v and v > 0 and v <= 250 then
        NS = v
    end
    normalSpeedBox.Text = tostring(NS)
end)
_, carrySpeedBox = textboxRow(Movement, "Carry Speed", tostring(CS), 3)
carrySpeedBox.FocusLost:Connect(function()
    local v = tonumber(carrySpeedBox.Text)
    if v and v > 0 and v <= 250 then
        CS = v
    end
    carrySpeedBox.Text = tostring(CS)
end)
aimbotSpeedRow, aimbotSpeedBox = textboxRow(Movement, "Normal Chase Speed", tostring(AIMBOT_SPEED), 4)
_G.PulseAimbotSpeedBox = aimbotSpeedBox
aimbotSpeedLabel = aimbotSpeedRow and aimbotSpeedRow:FindFirstChild("Label")
refreshAimbotModeLabels()
aimbotSpeedBox.FocusLost:Connect(function()
    local v = tonumber(aimbotSpeedBox.Text)
    if v and v > 0 and v <= 250 then
        _G.PulseSetSelectedAimbotSpeedValues(v, nil)
    end
    if _G.PulseRefreshAimbotSpeedBoxes then
        _G.PulseRefreshAimbotSpeedBoxes()
    else
        aimbotSpeedBox.Text = tostring(AIMBOT_SPEED)
    end
    savePulseConfig()
end)
modeDisplayRow(Movement, 5, "Normal")
section(Movement, "LAGGER SPEED", 6)
_, laggerSpeedBox = textboxRow(Movement, "Lagger Speed", tostring(LAGGER_SPEED), 7)
laggerSpeedBox.FocusLost:Connect(function()
    local v = tonumber(laggerSpeedBox.Text)
    if v and v > 0 and v <= 250 then
        LAGGER_SPEED = v
    end
    laggerSpeedBox.Text = tostring(LAGGER_SPEED)
end)
_, laggerCarrySpeedBox = textboxRow(Movement, "Lagger Carry Speed", tostring(LAGGER_CARRY_SPEED), 8)
laggerCarrySpeedBox.FocusLost:Connect(function()
    local v = tonumber(laggerCarrySpeedBox.Text)
    if v and v > 0 and v <= 250 then
        LAGGER_CARRY_SPEED = v
    end
    laggerCarrySpeedBox.Text = tostring(LAGGER_CARRY_SPEED)
end)
laggerAimbotSpeedRow, laggerAimbotSpeedBox =
    textboxRow(Movement, "Lagger Chase Speed", tostring(LAGGER_AIMBOT_SPEED), 8.5)
_G.PulseLaggerAimbotSpeedBox = laggerAimbotSpeedBox
laggerAimbotSpeedLabel = laggerAimbotSpeedRow and laggerAimbotSpeedRow:FindFirstChild("Label")
refreshAimbotModeLabels()
if _G.PulseRefreshAimbotSpeedBoxes then
    _G.PulseRefreshAimbotSpeedBoxes()
end
laggerAimbotSpeedBox.FocusLost:Connect(function()
    local v = tonumber(laggerAimbotSpeedBox.Text)
    if v and v > 0 and v <= 250 then
        _G.PulseSetSelectedAimbotSpeedValues(nil, v)
    end
    if _G.PulseRefreshAimbotSpeedBoxes then
        _G.PulseRefreshAimbotSpeedBoxes()
    else
        laggerAimbotSpeedBox.Text = tostring(LAGGER_AIMBOT_SPEED)
    end
    savePulseConfig()
end)
modeDisplayRow(Movement, 9, "Lagger")
section(Movement, "LAGGER 2 SPEED", 10)
_, lagger2SpeedBox = textboxRow(Movement, "Lagger 2 Speed", tostring(LAGGER2_SPEED), 11)
lagger2SpeedBox.FocusLost:Connect(function()
    local v = tonumber(lagger2SpeedBox.Text)
    if v and v > 0 and v <= 250 then
        LAGGER2_SPEED = v
    end
    lagger2SpeedBox.Text = tostring(LAGGER2_SPEED)
    savePulseConfig()
end)
_, lagger2CarrySpeedBox = textboxRow(Movement, "Lagger Carry 2 Speed", tostring(LAGGER2_CARRY_SPEED), 12)
lagger2CarrySpeedBox.FocusLost:Connect(function()
    local v = tonumber(lagger2CarrySpeedBox.Text)
    if v and v > 0 and v <= 250 then
        LAGGER2_CARRY_SPEED = v
    end
    lagger2CarrySpeedBox.Text = tostring(LAGGER2_CARRY_SPEED)
    savePulseConfig()
end)
modeDisplayRow(Movement, 13, "Lagger 2")
refreshSpeedModeRows()
task.wait()
StealPage = pages.MECHANICS
section(StealPage, "AUTO STEAL", 101)
autoStealSelectorRow(StealPage, 102)
_pulseRow, setAutoStealVisual = toggleRow(StealPage, "Auto Steal", autoStealEnabled, 103)
do
    _pulseBtn = _pulseRow and _pulseRow:FindFirstChild("ToggleButton")
    if _pulseBtn then
        _pulseBtn.Activated:Connect(function()
            if _G.PulseNormalAutoStealRagdollPause and _G.PulseNormalAutoStealRagdollPause.active then
                _G.PulseNormalAutoStealRagdollPause.cancel(false)
            end
            autoStealEnabled = not autoStealEnabled
            if
                not autoStealEnabled
                and _G.PulseSemiRagdollStealController
                and _G.PulseSemiRagdollStealController.active
            then
                _G.PulseSemiRagdollStealController.cancel()
            end
            if setAutoStealVisual then
                setAutoStealVisual(autoStealEnabled)
            end
            if _G.PulseAutoStealSync then
                _G.PulseAutoStealSync()
            end
            savePulseConfig()
        end)
    end
end
_G.PulseNormalRagdollStealRow, _G.PulseSetNormalRagdollStealVisual =
    toggleRow(StealPage, "ragdoll steal", _G.PulseNormalRagdollStealEnabled == true, 103.5)
_G.PulseRefreshNormalRagdollStealRow = function()
    if _G.PulseNormalRagdollStealRow then
        _G.PulseNormalRagdollStealRow.Visible = selectedStealMode == "Normal"
    end
end
do
    local normalRagdollStealButton = _G.PulseNormalRagdollStealRow
        and _G.PulseNormalRagdollStealRow:FindFirstChild("ToggleButton")
    if normalRagdollStealButton then
        normalRagdollStealButton.Activated:Connect(function()
            _G.PulseNormalRagdollStealEnabled = not (_G.PulseNormalRagdollStealEnabled == true)
            if
                not _G.PulseNormalRagdollStealEnabled
                and _G.PulseNormalAutoStealRagdollPause
                and _G.PulseNormalAutoStealRagdollPause.active
            then
                _G.PulseNormalAutoStealRagdollPause.cancel(true)
            end
            if _G.PulseSetNormalRagdollStealVisual then
                _G.PulseSetNormalRagdollStealVisual(_G.PulseNormalRagdollStealEnabled)
            end
            if _G.PulseRefreshNormalRagdollStealRow then
                _G.PulseRefreshNormalRagdollStealRow()
            end
            savePulseConfig()
        end)
    end
end
_G.PulseRefreshNormalRagdollStealRow()
softStealRow, setSoftStealVisual = toggleRow(StealPage, "Soft Steal", softStealEnabled, 104)
if softStealRow and (selectedStealMode == "Normal" or selectedStealMode == "Normal V2") then
    softStealRow.Visible = false
end
do
    _pulseBtn = softStealRow and softStealRow:FindFirstChild("ToggleButton")
    if _pulseBtn then
        _pulseBtn.Activated:Connect(function()
            softStealEnabled = not softStealEnabled
            _G.PulseSoftStealEnabled = (softStealEnabled == true)
            if setSoftStealVisual then
                setSoftStealVisual(softStealEnabled)
            end
            savePulseConfig()
        end)
    end
end
_G.PulseSemiRagdollStealRow, _G.PulseSetSemiRagdollStealVisual =
    toggleRow(StealPage, "Ragdoll Steal", _G.PulseSemiRagdollStealEnabled == true, 104.5)
_G.PulseRefreshSemiRagdollStealRow = function()
    if _G.PulseSemiRagdollStealRow then
        _G.PulseSemiRagdollStealRow.Visible = selectedStealMode == "Semi"
    end
end
do
    local semiRagdollStealButton = _G.PulseSemiRagdollStealRow
        and _G.PulseSemiRagdollStealRow:FindFirstChild("ToggleButton")
    if semiRagdollStealButton then
        semiRagdollStealButton.Activated:Connect(function()
            _G.PulseSemiRagdollStealEnabled = not (_G.PulseSemiRagdollStealEnabled == true)
            if
                not _G.PulseSemiRagdollStealEnabled
                and _G.PulseSemiRagdollStealController
                and _G.PulseSemiRagdollStealController.active
            then
                _G.PulseSemiRagdollStealController.cancel()
            end
            if _G.PulseSetSemiRagdollStealVisual then
                _G.PulseSetSemiRagdollStealVisual(_G.PulseSemiRagdollStealEnabled)
            end
            if _G.PulseRefreshSemiRagdollStealRow then
                _G.PulseRefreshSemiRagdollStealRow()
            end
            savePulseConfig()
        end)
    end
end
_G.PulseRefreshSemiRagdollStealRow()
_, radiusBox = textboxRow(StealPage, "Radius", tostring(autoStealRadius), 105)
autoStealRadiusBox = radiusBox
radiusBox.FocusLost:Connect(function()
    local v = tonumber(radiusBox.Text)
    if v and v > 0 and v <= 500 then
        autoStealRadius = v
    end
    _G.PulseStealRadii = _G.PulseStealRadii or { Normal = 62, Semi = 9, ["Normal V2"] = 62 }
    _G.PulseStealRadii[selectedStealMode] = autoStealRadius
    radiusBox.Text = tostring(autoStealRadius)
    if _G.PulseNormalAutoStealSetRadius then
        _G.PulseNormalAutoStealSetRadius(_G.PulseStealRadii.Normal or 62)
    end
    if _G.PulseSemiAutoStealSetRadius then
        _G.PulseSemiAutoStealSetRadius(_G.PulseStealRadii.Semi or 9)
    end
    if _G.PulseNormalV2AutoStealSetRadius then
        _G.PulseNormalV2AutoStealSetRadius(_G.PulseStealRadii["Normal V2"] or 62)
    end
    if _G.PulseAutoStealSync then
        _G.PulseAutoStealSync()
    end
    savePulseConfig()
end)
Combat = pages.MECHANICS
section(Combat, "TELEPORT", 0.5)
autoTPRow = nil
autoTPRow, setAutoTPVisual = toggleRow(Combat, "Auto TP Down", autoTPEnabled, 0.6)
do
    local autoTPButton = autoTPRow and autoTPRow:FindFirstChild("ToggleButton")
    if autoTPButton then
        autoTPButton.MouseButton1Click:Connect(function()
            if autoTPClickDebounce then
                return
            end
            autoTPClickDebounce = true
            local nextState = not autoTPEnabled
            toggleAutoTP(nextState)
            task.delay(0.15, function()
                autoTPClickDebounce = false
                if setAutoTPVisual then
                    setAutoTPVisual(autoTPEnabled)
                end
            end)
        end)
    end
    if autoTPEnabled then
        startAutoTP()
    else
        stopAutoTP()
    end
end
_, autoTPHeightBox = textboxRow(Combat, "Auto TP Height", tostring(autoTPHeight), 0.7)
autoTPHeightBox.FocusLost:Connect(function()
    local v = tonumber(autoTPHeightBox.Text)
    if v and v >= -500 and v <= 500 then
        autoTPHeight = v
    end
    autoTPHeightBox.Text = tostring(autoTPHeight)
    savePulseConfig()
end)
section(Combat, "BAT LOCK", 5)
_G.PulseAimbotSetVisual = nil
if _G.PulseRefreshAimbotVisual then
    _G.PulseRefreshAimbotVisual()
end
_G.PulseNormalAutoSwingRow, _G.PulseNormalAutoSwingSetVisual, _G.PulseNormalAutoSwingBtn =
    _G.PulseActionToggleRow(Combat, "Auto Swing", autoSwingEnabled, 7)
do
    if _G.PulseNormalAutoSwingBtn then
        _G.PulseNormalAutoSwingBtn.MouseButton1Click:Connect(function()
            if _G.PulseAutoSwingClickBusy then
                return
            end
            _G.PulseAutoSwingClickBusy = true
            autoSwingEnabled = not autoSwingEnabled
            if _G.PulseNormalAutoSwingSetVisual then
                _G.PulseNormalAutoSwingSetVisual(autoSwingEnabled)
            end
            savePulseConfig()
            task.delay(0.12, function()
                _G.PulseAutoSwingClickBusy = false
            end)
        end)
    end
end
section(Combat, "ANTI DESYNC BAT", 10)
_G.PulseAntiDesyncAutoSwingRow, _G.PulseAntiDesyncAutoSwingSetVisual, _G.PulseAntiDesyncAutoSwingBtn =
    _G.PulseActionToggleRow(Combat, "Auto Swing", antiDesyncAutoSwingEnabled, 11)
do
    if _G.PulseAntiDesyncAutoSwingBtn then
        _G.PulseAntiDesyncAutoSwingBtn.MouseButton1Click:Connect(function()
            if _G.PulseAntiDesyncAutoSwingClickBusy then
                return
            end
            _G.PulseAntiDesyncAutoSwingClickBusy = true
            antiDesyncAutoSwingEnabled = not antiDesyncAutoSwingEnabled
            if _G.PulseAntiDesyncAutoSwingSetVisual then
                _G.PulseAntiDesyncAutoSwingSetVisual(antiDesyncAutoSwingEnabled)
            end
            savePulseConfig()
            task.delay(0.12, function()
                _G.PulseAntiDesyncAutoSwingClickBusy = false
            end)
        end)
    end
end
_G.PulseAntiDesyncSetVisual = function(_) end
section(Combat, "GENERAL", 13)
_pulseRow, setBatCounterVisual = _G.PulseActionToggleRow(Combat, "Bat Counter", batCounterEnabled, 14)
do
    _pulseBtn = _pulseRow and _pulseRow:FindFirstChild("ToggleButton")
    if _pulseBtn then
        _pulseBtn.Activated:Connect(function()
            batCounterEnabled = not batCounterEnabled
            if setBatCounterVisual then
                setBatCounterVisual(batCounterEnabled)
            end
            if batCounterEnabled then
                if _G.PulseStartBatCounter then
                    _G.PulseStartBatCounter()
                end
            else
                if _G.PulseStopBatCounter then
                    _G.PulseStopBatCounter()
                end
            end
            savePulseConfig()
        end)
    end
end
_pulseRow, setMedCounterVisual = _G.PulseActionToggleRow(Combat, "Medusa Counter", medCounterEnabled, 15)
do
    _pulseBtn = _pulseRow and _pulseRow:FindFirstChild("ToggleButton")
    if _pulseBtn then
        _pulseBtn.Activated:Connect(function()
            medCounterEnabled = not medCounterEnabled
            if setMedCounterVisual then
                setMedCounterVisual(medCounterEnabled)
            end
            if medCounterEnabled then
                if _G.PulseStartMedCounter then
                    _G.PulseStartMedCounter(LP.Character)
                end
            else
                if _G.PulseStopMedCounter then
                    _G.PulseStopMedCounter()
                end
            end
            savePulseConfig()
        end)
    end
end
_pulseRow, _G.PulseSetNoPlayerCollisionVisual =
    _G.PulseActionToggleRow(Combat, "Disable Player Collision", _G.PulseNoPlayerCollisionEnabled, 16)
do
    _pulseBtn = _pulseRow and _pulseRow:FindFirstChild("ToggleButton")
    if _pulseBtn then
        _pulseBtn.Activated:Connect(function()
            _G.PulseNoPlayerCollisionEnabled = not _G.PulseNoPlayerCollisionEnabled
            if _G.PulseSetNoPlayerCollisionVisual then
                _G.PulseSetNoPlayerCollisionVisual(_G.PulseNoPlayerCollisionEnabled)
            end
            if _G.PulseNoPlayerCollisionEnabled then
                if enableNoPlayerCollision then
                    enableNoPlayerCollision()
                end
            else
                if disableNoPlayerCollision then
                    disableNoPlayerCollision()
                end
            end
            savePulseConfig()
        end)
    end
end
_, setAntiRagdollModeRow = antiRagdollSelectorRow(Combat, 17)
_pulseRow, setAntiRagdollVisual = _G.PulseActionToggleRow(Combat, "Anti Ragdoll", antiRagdollEnabled, 18)
do
    _pulseBtn = _pulseRow and _pulseRow:FindFirstChild("ToggleButton")
    if _pulseBtn then
        _pulseBtn.Activated:Connect(function()
            setAntiRagdoll(not antiRagdollEnabled)
            if setAntiRagdollVisual then
                setAntiRagdollVisual(antiRagdollEnabled == true)
            end
            savePulseConfig()
        end)
    end
end
do
    _pulseRow, setTpDownOnRagdollVisual =
        _G.PulseActionToggleRow(Combat, "TP Down On Ragdoll", tpDownOnRagdollEnabled, 18.5)
    _pulseBtn = _pulseRow and _pulseRow:FindFirstChild("ToggleButton")
    if _pulseBtn then
        _pulseBtn.Activated:Connect(function()
            tpDownOnRagdollEnabled = not tpDownOnRagdollEnabled
            _G.PulseTpDownOnRagdollOn = tpDownOnRagdollEnabled
            if setTpDownOnRagdollVisual then
                setTpDownOnRagdollVisual(tpDownOnRagdollEnabled)
            end
            savePulseConfig()
        end)
    end
end
do
    _pulseRow, _G.PulseAutoRagdollTpState.setVisual =
        _G.PulseActionToggleRow(Combat, "Auto Ragdoll Tp", _G.PulseAutoRagdollTpState.enabled, 18.75)
    _pulseBtn = _pulseRow and _pulseRow:FindFirstChild("ToggleButton")
    if _pulseBtn then
        _pulseBtn.Activated:Connect(function()
            _G.PulseAutoRagdollTpState.set(not _G.PulseAutoRagdollTpState.enabled)
            if _G.PulseAutoRagdollTpState.setVisual then
                _G.PulseAutoRagdollTpState.setVisual(_G.PulseAutoRagdollTpState.enabled)
            end
            savePulseConfig()
        end)
    end
end
_pulseRow, setInfJumpVisual = _G.PulseActionToggleRow(Combat, "Infinite Jump", infJumpEnabled, 19)
do
    _pulseBtn = _pulseRow and _pulseRow:FindFirstChild("ToggleButton")
    if _pulseBtn then
        _pulseBtn.Activated:Connect(function()
            setInfJumpInternal(not infJumpEnabled)
            if setInfJumpVisual then
                setInfJumpVisual(infJumpEnabled == true)
            end
            savePulseConfig()
        end)
    end
end
task.wait()
Keybinds = pages.BINDS
section(Keybinds, "KEYBINDS", 1)
speedKeybindRow(Keybinds, "Auto Left", "AutoLeft", 2)
speedKeybindRow(Keybinds, "Auto Right", "AutoRight", 3)
speedKeybindRow(Keybinds, "Drop Brainrot", "DropBrainrot", 4)
tpDownKeybindRow(Keybinds, 5)
aimbotKeybindRow = speedKeybindRow(Keybinds, "Bat Aimbot", "Aimbot", 6)
combatAimbotKeybindLabel = aimbotKeybindRow and aimbotKeybindRow:FindFirstChild("Label")
refreshAimbotModeLabels()
speedKeybindRow(Keybinds, "Instant Reset", "InstantReset", 7)
speedKeybindRow(Keybinds, "TP Bat", "AntiDesyncAimbot", 8)
speedKeybindRow(Keybinds, "Lagger Mode Key", "LaggerToggle", 9)
speedKeybindRow(Keybinds, "Speed Key", "SpeedToggle", 10)
do
    THEME_ACCENT = THEME_ACCENT or Color3.fromRGB(230, 230, 230)
    THEME_ACCENT_DIM = THEME_ACCENT_DIM or Color3.fromRGB(145, 145, 145)
    PlayerESP = PlayerESP or { enabled = false, playerData = {}, conns = {}, discordText = "discord.gg/pulsee" }
    BoxedESPOptions = BoxedESPOptions or { box = false, tracer = false }
    BoxedESPData = BoxedESPData or {}
    BoxedESPConn = BoxedESPConn or nil
    stretchRezConn = stretchRezConn or nil
    antiLagDescConn = antiLagDescConn or nil
    noCamCollisionConn = noCamCollisionConn or nil
    noCamCollisionParts = noCamCollisionParts or {}
    _pulseCustomFontOrig = _pulseCustomFontOrig or {}
    _pulseCustomFontConn = _pulseCustomFontConn or nil
    _pulseCustomFont = _pulseCustomFont or nil
    function startPlayerESP()
        if PlayerESP.enabled then
            return
        end
        PlayerESP.enabled = true
        function cleanup(plr)
            local d = PlayerESP.playerData[plr]
            if not d then
                return
            end
            pcall(function()
                if d.highlight then
                    d.highlight:Destroy()
                end
            end)
            pcall(function()
                if d.billboard then
                    d.billboard:Destroy()
                end
            end)
            if d.conns then
                for _, c in ipairs(d.conns) do
                    pcall(function()
                        c:Disconnect()
                    end)
                end
            end
            PlayerESP.playerData[plr] = nil
        end
        function setup(plr, char)
            if not PlayerESP.enabled or plr == LP then
                return
            end
            cleanup(plr)
            local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5))
            local head = char and (char:FindFirstChild("Head") or char:WaitForChild("Head", 5))
            if not hrp or not head then
                return
            end
            local hl = Instance.new("Highlight")
            hl.Name = "PulseHubESP"
            hl.Adornee = char
            hl.FillColor = Color3.fromRGB(35, 35, 35)
            hl.FillTransparency = 0.72
            hl.OutlineColor = Color3.fromRGB(245, 245, 245)
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = char
            local bb = Instance.new("BillboardGui")
            bb.Name = "PulseHubESPTag"
            bb.Adornee = head
            bb.Size = UDim2.new(0, 124, 0, 34)
            bb.StudsOffset = Vector3.new(0, 2.7, 0)
            bb.AlwaysOnTop = true
            bb.LightInfluence = 0
            bb.Parent = head
            local box = Instance.new("Frame", bb)
            box.Size = UDim2.new(1, 0, 1, 0)
            box.BackgroundTransparency = 1
            box.BorderSizePixel = 0
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)
            local n = Instance.new("TextLabel", box)
            n.Size = UDim2.new(1, -10, 0, 17)
            n.Position = UDim2.new(0, 5, 0, 2)
            n.BackgroundTransparency = 1
            n.TextColor3 = Color3.fromRGB(255, 255, 255)
            n.Font = Enum.Font.GothamBlack
            n.TextSize = 15
            n.TextStrokeTransparency = 0.38
            local sub = Instance.new("TextLabel", box)
            sub.Size = UDim2.new(1, -10, 0, 11)
            sub.Position = UDim2.new(0, 5, 0, 19)
            sub.BackgroundTransparency = 1
            sub.TextColor3 = Color3.fromRGB(180, 180, 180)
            sub.Font = Enum.Font.GothamBold
            sub.TextSize = 10
            sub.TextStrokeTransparency = 0.58
            local conn = RunService.Heartbeat:Connect(function()
                if not PlayerESP.enabled or not hrp.Parent then
                    return
                end
                local v = hrp.AssemblyLinearVelocity or hrp.Velocity
                n.Text = string.format("%d speed", math.floor(Vector3.new(v.X, 0, v.Z).Magnitude + 0.5))
                sub.Text = plr.Name
            end)
            PlayerESP.playerData[plr] = { highlight = hl, billboard = bb, conns = { conn } }
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                if plr.Character then
                    setup(plr, plr.Character)
                end
                table.insert(
                    PlayerESP.conns,
                    plr.CharacterAdded:Connect(function(c)
                        task.defer(setup, plr, c)
                    end)
                )
            end
        end
        table.insert(
            PlayerESP.conns,
            Players.PlayerAdded:Connect(function(plr)
                if plr ~= LP then
                    table.insert(
                        PlayerESP.conns,
                        plr.CharacterAdded:Connect(function(c)
                            task.defer(setup, plr, c)
                        end)
                    )
                end
            end)
        )
        table.insert(PlayerESP.conns, Players.PlayerRemoving:Connect(cleanup))
    end
    function stopPlayerESP()
        PlayerESP.enabled = false
        for _, c in ipairs(PlayerESP.conns or {}) do
            pcall(function()
                c:Disconnect()
            end)
        end
        PlayerESP.conns = {}
        for plr, d in pairs(PlayerESP.playerData or {}) do
            pcall(function()
                if d.highlight then
                    d.highlight:Destroy()
                end
            end)
            pcall(function()
                if d.billboard then
                    d.billboard:Destroy()
                end
            end)
        end
        PlayerESP.playerData = {}
    end
    function _pulseEspColor()
        return THEME_ACCENT or Color3.fromRGB(230, 230, 230)
    end
    function _safeDrawing(kind, props)
        if not Drawing or not Drawing.new then
            return nil
        end
        local ok, obj = pcall(function()
            return Drawing.new(kind)
        end)
        if not ok or not obj then
            return nil
        end
        for k, v in pairs(props or {}) do
            pcall(function()
                obj[k] = v
            end)
        end
        return obj
    end
    function _cleanupBoxedESPPlayer(player)
        local data = BoxedESPData[player]
        if not data then
            return
        end
        for _, obj in pairs(data) do
            pcall(function()
                obj.Visible = false
                if obj.Remove then
                    obj:Remove()
                end
            end)
        end
        BoxedESPData[player] = nil
    end
    function _cleanupBoxedESP()
        for player, _ in pairs(BoxedESPData) do
            _cleanupBoxedESPPlayer(player)
        end
    end
    function _updateBoxedESP()
        local cam = workspace.CurrentCamera
        if not cam then
            return
        end
        local anyOn = BoxedESPOptions.box or BoxedESPOptions.tracer
        if not anyOn then
            _cleanupBoxedESP()
            return
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LP then
                continue
            end
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            if not root or not head then
                _cleanupBoxedESPPlayer(player)
                continue
            end
            local rootPos, onScreen = cam:WorldToViewportPoint(root.Position)
            local headPos = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.55, 0))
            local data = BoxedESPData[player]
            if not data then
                data = {
                    box = _safeDrawing(
                        "Square",
                        { Thickness = 2, Filled = false, Transparency = 1, Color = _pulseEspColor() }
                    ),
                    tracer = _safeDrawing("Line", { Thickness = 2, Transparency = 1, Color = _pulseEspColor() }),
                }
                BoxedESPData[player] = data
            end
            local color = _pulseEspColor()
            local height = math.abs(headPos.Y - rootPos.Y) * 2.15
            if height < 20 or height ~= height then
                height = 65
            end
            local width = height / 2.15
            local view = cam.ViewportSize
            local centerX, centerY = view.X / 2, view.Y / 2
            local targetX, targetY = rootPos.X, rootPos.Y + height / 2
            local targetVisible = onScreen and rootPos.Z > 0
            if not targetVisible then
                local dx = rootPos.X - centerX
                local dy = rootPos.Y - centerY
                if rootPos.Z <= 0 then
                    dx = -dx
                    dy = -dy
                end
                if math.abs(dx) < 1 and math.abs(dy) < 1 then
                    local rel = cam.CFrame:PointToObjectSpace(root.Position)
                    dx = rel.X
                    dy = -rel.Y
                    if rootPos.Z <= 0 then
                        dx = -dx
                        dy = -dy
                    end
                end
                local edgePad = 10
                local scaleX = (dx ~= 0) and ((view.X / 2 - edgePad) / math.abs(dx)) or math.huge
                local scaleY = (dy ~= 0) and ((view.Y / 2 - edgePad) / math.abs(dy)) or math.huge
                local scale = math.min(scaleX, scaleY)
                if scale == math.huge or scale ~= scale then
                    scale = 1
                end
                targetX = math.clamp(centerX + dx * scale, edgePad, view.X - edgePad)
                targetY = math.clamp(centerY + dy * scale, edgePad, view.Y - edgePad)
            end
            if data.box then
                data.box.Color = color
                data.box.Size = Vector2.new(width, height)
                data.box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                data.box.Visible = BoxedESPOptions.box == true and targetVisible
            end
            if data.tracer then
                data.tracer.Color = color
                local localChar = LP.Character
                local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
                local localHead = localChar and localChar:FindFirstChild("Head")
                local fromX, fromY
                if localRoot then
                    local localScreen = cam:WorldToViewportPoint(localRoot.Position)
                    fromX = localScreen.X
                    fromY = localScreen.Y + 15
                end
                if not fromX or not fromY then
                    fromX = cam.ViewportSize.X / 2
                    fromY = cam.ViewportSize.Y - 88
                end
                data.tracer.From = Vector2.new(fromX, fromY)
                data.tracer.To = Vector2.new(targetX, targetY)
                data.tracer.Visible = BoxedESPOptions.tracer == true
            end
        end
    end
    function refreshBoxedESP()
        local anyOn = BoxedESPOptions.box or BoxedESPOptions.tracer
        if anyOn and not BoxedESPConn then
            BoxedESPConn = RunService.RenderStepped:Connect(_updateBoxedESP)
        elseif (not anyOn) and BoxedESPConn then
            BoxedESPConn:Disconnect()
            BoxedESPConn = nil
            _cleanupBoxedESP()
        end
    end
    Players.PlayerRemoving:Connect(_cleanupBoxedESPPlayer)
    _G.PulseStretchFOV = _G.PulseStretchFOV or 120
    function enableStretchRez()
        fpsBoostEnabled = true
        local cam = workspace.CurrentCamera
        if not cam then
            return
        end
        if stretchRezConn then
            stretchRezConn:Disconnect()
            stretchRezConn = nil
        end
        stretchRezConn = RunService.RenderStepped:Connect(function()
            if not fpsBoostEnabled then
                if stretchRezConn then
                    stretchRezConn:Disconnect()
                    stretchRezConn = nil
                end
                return
            end
            cam = workspace.CurrentCamera
            if cam then
                if not fovEnabled then
                    pcall(function()
                        cam.FieldOfView = _G.PulseStretchFOV
                    end)
                end
            end
        end)
    end
    function disableStretchRez()
        fpsBoostEnabled = false
        if stretchRezConn then
            stretchRezConn:Disconnect()
            stretchRezConn = nil
        end
        if not fovEnabled and workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView = 70
        end
    end
    function enableCustomFov()
        fovEnabled = true
        workspace.CurrentCamera.FieldOfView = fovValue
        if customFovConn then
            customFovConn:Disconnect()
        end
        customFovConn = RunService.RenderStepped:Connect(function()
            if not fovEnabled then
                customFovConn:Disconnect()
                customFovConn = nil
                return
            end
            workspace.CurrentCamera.FieldOfView = fovValue
        end)
    end
    function disableCustomFov()
        fovEnabled = false
        if customFovConn then
            customFovConn:Disconnect()
            customFovConn = nil
        end
        workspace.CurrentCamera.FieldOfView = fpsBoostEnabled and 107 or 70
    end
    function _applyAntiLagObj(obj)
        pcall(function()
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
                obj.CastShadow = false
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            elseif
                obj:IsA("ParticleEmitter")
                or obj:IsA("Trail")
                or obj:IsA("Beam")
                or obj:IsA("Fire")
                or obj:IsA("Smoke")
                or obj:IsA("Sparkles")
            then
                obj.Enabled = false
            end
        end)
    end
    function applyKTMOptimization()
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1e10
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
        end)
        for _, obj in ipairs(workspace:GetDescendants()) do
            _applyAntiLagObj(obj)
        end
        if antiLagDescConn then
            antiLagDescConn:Disconnect()
        end
        antiLagDescConn = workspace.DescendantAdded:Connect(function(obj)
            if antiLagVisualEnabled then
                _applyAntiLagObj(obj)
            end
        end)
    end
    function enableAntiLag()
        if antiLagVisualEnabled and antiLagDescConn then
            return
        end
        antiLagVisualEnabled = true
        applyKTMOptimization()
    end
    function disableAntiLag()
        antiLagVisualEnabled = false
        if antiLagDescConn then
            antiLagDescConn:Disconnect()
            antiLagDescConn = nil
        end
    end
end
V = V or {}
V.skyTheme = skyTheme or V.skyTheme or "Off"
V.customFontEnabled = false
V.potatoGraphicsEnabled = V.potatoGraphicsEnabled or false
function enableNoCamCollision()
    noCamCollisionEnabled = true
    if noCamCollisionConn then
        noCamCollisionConn:Disconnect()
    end
    noCamCollisionConn = RunService.RenderStepped:Connect(function()
        if not noCamCollisionEnabled then
            if noCamCollisionConn then
                noCamCollisionConn:Disconnect()
                noCamCollisionConn = nil
            end
            return
        end
        local cam = workspace.CurrentCamera
        local char = LP.Character
        if not cam or not char then
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            return
        end
        local camPos = cam.CFrame.Position
        local charPos = hrp.Position + Vector3.new(0, 1.5, 0)
        local toChar = charPos - camPos
        if toChar.Magnitude < 0.3 then
            return
        end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { char }
        params.IgnoreWater = true
        local hit = {}
        local origin = camPos
        local remaining = toChar
        for _ = 1, 12 do
            if remaining.Magnitude < 0.2 then
                break
            end
            local res = workspace:Raycast(origin, remaining, params)
            if not res then
                break
            end
            local part = res.Instance
            if part and part:IsA("BasePart") and not part:IsDescendantOf(char) then
                hit[part] = true
                if noCamCollisionParts[part] == nil then
                    noCamCollisionParts[part] = part.LocalTransparencyModifier
                end
                part.LocalTransparencyModifier = 1
            end
            origin = res.Position + remaining.Unit * 0.02
            remaining = charPos - origin
        end
        for part, orig in pairs(noCamCollisionParts) do
            if not hit[part] then
                pcall(function()
                    if part and part.Parent then
                        part.LocalTransparencyModifier = orig
                    end
                end)
                noCamCollisionParts[part] = nil
            end
        end
    end)
end
function disableNoCamCollision()
    noCamCollisionEnabled = false
    if noCamCollisionConn then
        noCamCollisionConn:Disconnect()
        noCamCollisionConn = nil
    end
    for part, orig in pairs(noCamCollisionParts) do
        pcall(function()
            if part and part.Parent then
                part.LocalTransparencyModifier = orig
            end
        end)
    end
    noCamCollisionParts = {}
end
SKY_PRESETS_LIST = {
    "Off",
    "Night",
    "Aurora",
    "Sunset",
    "Galaxy",
    "Tech",
    "Sakura",
    "Pink Night",
    "Blood Moon",
    "Emerald Dawn",
    "Volcanic",
    "Arctic",
    "Midnight Ocean",
    "Vaporwave",
    "Toxic",
    "Solar Eclipse",
    "Hellscape",
    "Heaven",
    "Storm",
    "Sunrise",
    "Deep Space",
    "Lavender Dream",
    "Inferno",
    "Mint Sky",
}
SKY_PRESETS = {
    ["Off"] = { kind = "off" },
    ["Night"] = {
        clock = 22,
        brightness = 2,
        ambient = { 110, 100, 130 },
        outAmb = { 120, 110, 140 },
        sky = { stars = 4000, moon = 18, sun = 0, moonTex = true },
        atm = { dens = 0.45, color = { 120, 60, 180 }, decay = { 60, 20, 100 }, glare = 0.5, haze = 1.2 },
    },
    ["Aurora"] = {
        clock = 14,
        brightness = 3,
        ambient = { 150, 120, 150 },
        outAmb = { 160, 130, 150 },
        atm = { dens = 0.55, color = { 255, 80, 200 }, decay = { 255, 20, 150 }, glare = 2.5, haze = 3 },
        clouds = { cover = 0.7, dens = 0.7, color = { 255, 240, 250 } },
    },
    ["Sunset"] = {
        clock = 17.2,
        brightness = 2.5,
        ambient = { 170, 120, 100 },
        outAmb = { 180, 130, 110 },
        sky = { stars = 0, sun = 25, moon = 0 },
        atm = { dens = 0.5, color = { 255, 130, 60 }, decay = { 255, 80, 30 }, glare = 2, haze = 2.5 },
        clouds = { cover = 0.55, dens = 0.55, color = { 255, 200, 140 } },
    },
    ["Galaxy"] = {
        clock = 0,
        brightness = 1.5,
        ambient = { 70, 60, 100 },
        outAmb = { 80, 70, 110 },
        sky = { stars = 10000, moon = 30, sun = 0 },
        atm = { dens = 0.15, color = { 40, 20, 80 }, decay = { 20, 10, 50 }, glare = 0.3, haze = 0.5 },
    },
    ["Tech"] = {
        clock = 21,
        brightness = 2.2,
        ambient = { 90, 130, 170 },
        outAmb = { 100, 140, 180 },
        sky = { stars = 2000, moon = 12 },
        atm = { dens = 0.4, color = { 0, 200, 255 }, decay = { 150, 0, 255 }, glare = 2, haze = 2 },
        clouds = { cover = 0.4, dens = 0.6, color = { 100, 200, 255 } },
    },
    ["Sakura"] = {
        clock = 11,
        brightness = 3.5,
        ambient = { 170, 150, 160 },
        outAmb = { 180, 160, 170 },
        sky = { sun = 8 },
        atm = { dens = 0.3, color = { 255, 200, 220 }, decay = { 255, 170, 200 }, glare = 1, haze = 1.5 },
        clouds = { cover = 0.6, dens = 0.4, color = { 255, 250, 252 } },
    },
    ["Pink Night"] = {
        clock = 23,
        brightness = 2.2,
        ambient = { 120, 60, 110 },
        outAmb = { 140, 70, 120 },
        sky = { stars = 5000, moon = 22, sun = 0, moonTex = true },
        atm = { dens = 0.5, color = { 255, 80, 180 }, decay = { 140, 30, 100 }, glare = 0.7, haze = 1.4 },
        clouds = { cover = 0.3, dens = 0.5, color = { 180, 90, 150 } },
    },
    ["Blood Moon"] = {
        clock = 22.5,
        brightness = 1.6,
        ambient = { 130, 40, 40 },
        outAmb = { 150, 50, 50 },
        sky = { stars = 1500, moon = 28, sun = 0, moonTex = true },
        atm = { dens = 0.6, color = { 220, 30, 30 }, decay = { 120, 10, 10 }, glare = 1.4, haze = 2 },
        clouds = { cover = 0.5, dens = 0.7, color = { 120, 30, 30 } },
    },
    ["Emerald Dawn"] = {
        clock = 6.5,
        brightness = 2.8,
        ambient = { 130, 170, 140 },
        outAmb = { 140, 180, 150 },
        sky = { sun = 18, moon = 0, stars = 0 },
        atm = { dens = 0.4, color = { 80, 200, 140 }, decay = { 40, 150, 90 }, glare = 1.8, haze = 2.2 },
        clouds = { cover = 0.5, dens = 0.5, color = { 200, 255, 220 } },
    },
    ["Volcanic"] = {
        clock = 19,
        brightness = 2,
        ambient = { 180, 80, 40 },
        outAmb = { 200, 90, 50 },
        sky = { stars = 200, sun = 12, moon = 0 },
        atm = { dens = 0.75, color = { 255, 60, 0 }, decay = { 180, 20, 0 }, glare = 3, haze = 3.5 },
        clouds = { cover = 0.8, dens = 0.9, color = { 120, 40, 20 } },
    },
    ["Arctic"] = {
        clock = 9,
        brightness = 3.2,
        ambient = { 200, 220, 235 },
        outAmb = { 210, 230, 245 },
        sky = { sun = 10, stars = 0, moon = 0 },
        atm = { dens = 0.3, color = { 180, 220, 255 }, decay = { 140, 200, 240 }, glare = 1.5, haze = 1.8 },
        clouds = { cover = 0.7, dens = 0.6, color = { 250, 253, 255 } },
    },
    ["Midnight Ocean"] = {
        clock = 1.5,
        brightness = 1.7,
        ambient = { 60, 90, 130 },
        outAmb = { 70, 100, 140 },
        sky = { stars = 6000, moon = 24, sun = 0, moonTex = true },
        atm = { dens = 0.5, color = { 20, 60, 140 }, decay = { 10, 30, 90 }, glare = 0.6, haze = 1.5 },
    },
    ["Vaporwave"] = {
        clock = 19.5,
        brightness = 2.4,
        ambient = { 180, 120, 200 },
        outAmb = { 190, 130, 210 },
        sky = { stars = 1000, moon = 14 },
        atm = { dens = 0.45, color = { 255, 100, 220 }, decay = { 120, 60, 255 }, glare = 2.2, haze = 2.4 },
        clouds = { cover = 0.5, dens = 0.55, color = { 200, 150, 255 } },
    },
    ["Toxic"] = {
        clock = 13,
        brightness = 2.5,
        ambient = { 140, 180, 80 },
        outAmb = { 150, 190, 90 },
        atm = { dens = 0.55, color = { 100, 220, 40 }, decay = { 60, 150, 20 }, glare = 1.8, haze = 2.6 },
        clouds = { cover = 0.65, dens = 0.7, color = { 180, 255, 120 } },
    },
    ["Solar Eclipse"] = {
        clock = 12,
        brightness = 0.9,
        ambient = { 50, 40, 60 },
        outAmb = { 60, 50, 70 },
        sky = { stars = 3500, sun = 22, moon = 0 },
        atm = { dens = 0.5, color = { 255, 140, 40 }, decay = { 30, 20, 40 }, glare = 2.8, haze = 1.8 },
    },
    ["Hellscape"] = {
        clock = 18,
        brightness = 1.8,
        ambient = { 200, 60, 30 },
        outAmb = { 220, 70, 40 },
        sky = { stars = 100, sun = 30, moon = 0 },
        atm = { dens = 0.85, color = { 255, 30, 0 }, decay = { 120, 0, 0 }, glare = 3.5, haze = 4 },
        clouds = { cover = 0.95, dens = 0.95, color = { 80, 20, 10 } },
    },
    ["Heaven"] = {
        clock = 12,
        brightness = 4,
        ambient = { 240, 235, 210 },
        outAmb = { 250, 245, 220 },
        sky = { sun = 16, moon = 0, stars = 0 },
        atm = { dens = 0.25, color = { 255, 250, 220 }, decay = { 255, 240, 200 }, glare = 3, haze = 1.5 },
        clouds = { cover = 0.85, dens = 0.5, color = { 255, 255, 255 } },
    },
    ["Storm"] = {
        clock = 15,
        brightness = 1.4,
        ambient = { 90, 90, 110 },
        outAmb = { 100, 100, 120 },
        sky = { stars = 0, sun = 6, moon = 0 },
        atm = { dens = 0.65, color = { 80, 90, 120 }, decay = { 40, 50, 80 }, glare = 0.5, haze = 3 },
        clouds = { cover = 0.95, dens = 0.95, color = { 60, 65, 80 } },
    },
    ["Sunrise"] = {
        clock = 6.2,
        brightness = 2.8,
        ambient = { 220, 180, 130 },
        outAmb = { 230, 190, 140 },
        sky = { sun = 22, stars = 0, moon = 0 },
        atm = { dens = 0.45, color = { 255, 180, 100 }, decay = { 255, 140, 80 }, glare = 2.4, haze = 2.2 },
        clouds = { cover = 0.4, dens = 0.4, color = { 255, 220, 180 } },
    },
    ["Deep Space"] = {
        clock = 0,
        brightness = 1,
        ambient = { 30, 25, 50 },
        outAmb = { 40, 35, 60 },
        sky = { stars = 15000, moon = 0, sun = 0 },
        atm = { dens = 0.08, color = { 15, 5, 40 }, decay = { 5, 0, 20 }, glare = 0.2, haze = 0.3 },
    },
    ["Lavender Dream"] = {
        clock = 18.5,
        brightness = 2.6,
        ambient = { 180, 160, 220 },
        outAmb = { 190, 170, 230 },
        sky = { stars = 800, moon = 16, sun = 0 },
        atm = { dens = 0.4, color = { 200, 160, 255 }, decay = { 160, 120, 220 }, glare = 1.4, haze = 1.8 },
        clouds = { cover = 0.55, dens = 0.5, color = { 220, 200, 255 } },
    },
    ["Inferno"] = {
        clock = 17.5,
        brightness = 2.2,
        ambient = { 220, 100, 40 },
        outAmb = { 235, 110, 50 },
        sky = { sun = 26, moon = 0, stars = 0 },
        atm = { dens = 0.6, color = { 255, 90, 20 }, decay = { 200, 40, 0 }, glare = 3, haze = 3.2 },
        clouds = { cover = 0.7, dens = 0.7, color = { 200, 80, 40 } },
    },
    ["Mint Sky"] = {
        clock = 10,
        brightness = 3.2,
        ambient = { 180, 230, 210 },
        outAmb = { 190, 240, 220 },
        sky = { sun = 10 },
        atm = { dens = 0.32, color = { 150, 255, 210 }, decay = { 100, 220, 180 }, glare = 1.6, haze = 1.6 },
        clouds = { cover = 0.55, dens = 0.45, color = { 240, 255, 250 } },
    },
}
function _vC3(t)
    return Color3.fromRGB(t[1], t[2], t[3])
end
function _v4mpClearSky()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:GetAttribute("_PulseHubSky") then
            pcall(function()
                v:Destroy()
            end)
        end
    end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        for _, v in ipairs(terrain:GetChildren()) do
            if v:GetAttribute("_PulseHubSky") then
                pcall(function()
                    v:Destroy()
                end)
            end
        end
    end
end
function applyCustomSky(mode)
    _v4mpClearSky()
    local preset = SKY_PRESETS[mode]
    if not preset or preset.kind == "off" then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.FogColor = Color3.fromRGB(192, 192, 192)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = true
        V.skyTheme = "Off"
        return
    end
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    Lighting.FogColor = Color3.fromRGB(200, 200, 200)
    Lighting.GlobalShadows = true
    Lighting.ClockTime = preset.clock or 14
    Lighting.Brightness = preset.brightness or 2
    if preset.outAmb then
        Lighting.OutdoorAmbient = _vC3(preset.outAmb)
    end
    if preset.ambient then
        Lighting.Ambient = _vC3(preset.ambient)
    end
    if preset.sky then
        local sky = Instance.new("Sky")
        sky:SetAttribute("_PulseHubSky", true)
        if preset.sky.stars then
            sky.StarCount = preset.sky.stars
        end
        if preset.sky.moon then
            sky.MoonAngularSize = preset.sky.moon
        end
        if preset.sky.sun then
            sky.SunAngularSize = preset.sky.sun
        end
        if preset.sky.moonTex then
            sky.MoonTextureId = "rbxasset://sky/moon.jpg"
        end
        sky.Parent = Lighting
    end
    if preset.atm then
        local atm = Instance.new("Atmosphere")
        atm:SetAttribute("_PulseHubSky", true)
        atm.Density = preset.atm.dens or 0.3
        atm.Color = _vC3(preset.atm.color)
        atm.Decay = _vC3(preset.atm.decay)
        atm.Glare = preset.atm.glare or 1
        atm.Haze = preset.atm.haze or 1
        atm.Parent = Lighting
    end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if preset.clouds and terrain then
        local clouds = Instance.new("Clouds")
        clouds:SetAttribute("_PulseHubSky", true)
        clouds.Cover = preset.clouds.cover or 0.5
        clouds.Density = preset.clouds.dens or 0.5
        clouds.Color = _vC3(preset.clouds.color)
        clouds.Parent = terrain
    end
    V.skyTheme = mode
end
function enableUltraMode()
    V.ultraModeEnabled = true
    applyKTMOptimization()
end
function disableUltraMode()
    V.ultraModeEnabled = false
end
function enableRemoveAccessories()
    V.removeAccessoriesEnabledSep = true
    removeAccessoriesEnabled = true
    removeAllAccessories()
    if V.removeAccConn then
        V.removeAccConn:Disconnect()
    end
    V.removeAccConn = Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if V.removeAccessoriesEnabledSep or removeAccessoriesEnabled then
                for _, obj in ipairs(char:GetDescendants()) do
                    processAntiLagDescendant(obj)
                end
            end
        end)
    end)
    if antiLagDescConn then
        antiLagDescConn:Disconnect()
    end
    antiLagDescConn = Workspace.DescendantAdded:Connect(function(obj)
        if antiLagEnabled or V.ultraModeEnabled or removeAccessoriesEnabled or V.removeAccessoriesEnabledSep then
            processAntiLagDescendant(obj)
        end
    end)
end
function disableRemoveAccessories()
    V.removeAccessoriesEnabledSep = false
    removeAccessoriesEnabled = false
    if V.removeAccConn then
        V.removeAccConn:Disconnect()
        V.removeAccConn = nil
    end
    if not antiLagEnabled and not V.ultraModeEnabled and antiLagDescConn then
        antiLagDescConn:Disconnect()
        antiLagDescConn = nil
    end
end
function __PulseHubSetupVisualsUI()
    local Utility = pages.VISUALS
    local skyThemes = SKY_PRESETS_LIST or { "Off", "Night", "Aurora", "Sunset", "Galaxy", "Tech", "Sakura" }
    local skyIndex = 1
    for i, name in ipairs(skyThemes) do
        if name == skyTheme then
            skyIndex = i
            break
        end
    end
    function skyThemeSelectorRow(parent, order)
        local row = baseRow(parent, "Sky Theme", order)
        row.Size = UDim2.new(1, -4, 0, 42)
        row.ClipsDescendants = true
        local label = row:FindFirstChild("Label")
        if label then
            label.Size = UDim2.new(0, 92, 1, 0)
            label.TextSize = 11
        end
        local left = Instance.new("TextButton")
        left.Name = "SkyLeft"
        left.BackgroundColor3 = Color3.fromRGB(7, 7, 10)
        left.BackgroundTransparency = 0.04
        left.Text = "<"
        left.TextColor3 = COLORS.white
        left.TextSize = 12
        left.Font = Enum.Font.GothamSemibold
        left.Size = UDim2.new(0, 42, 0, 28)
        left.Position = UDim2.new(1, -186, 0.5, -14)
        left.BorderSizePixel = 0
        left.ZIndex = 8
        left.AutoButtonColor = false
        left.Parent = row
        corner(left, 8)
        stroke(left, COLORS.strokeSoft, 1, 0.42)
        local holder = Instance.new("Frame")
        holder.Name = "SkyValueHolder"
        holder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        holder.BackgroundTransparency = 0.28
        holder.BorderSizePixel = 0
        holder.Size = UDim2.new(0, 92, 0, 28)
        holder.Position = UDim2.new(1, -139, 0.5, -14)
        holder.ClipsDescendants = true
        holder.ZIndex = 7
        holder.Parent = row
        corner(holder, 8)
        stroke(holder, Color3.fromRGB(235, 235, 245), 1, 0.35)
        local smoky = Instance.new("ImageLabel")
        smoky.Name = "SmokyBackground"
        smoky.BackgroundTransparency = 1
        smoky.Image = "rbxassetid://99416158073201"
        smoky.ImageTransparency = 1
        smoky.ScaleType = Enum.ScaleType.Crop
        smoky.Size = UDim2.new(1, 0, 1, 0)
        smoky.Position = UDim2.new(0, 0, 0, 0)
        smoky.Visible = false
        smoky.ZIndex = 7
        smoky.Parent = holder
        corner(smoky, 8)
        skyValueLabel = Instance.new("TextLabel")
        skyValueLabel.Name = "SkyValue"
        skyValueLabel.BackgroundTransparency = 1
        skyValueLabel.Text = skyThemes[skyIndex]
        skyValueLabel.TextColor3 = COLORS.white
        skyValueLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        skyValueLabel.TextStrokeTransparency = 0.22
        skyValueLabel.TextSize = 11
        skyValueLabel.Font = Enum.Font.GothamSemibold
        skyValueLabel.TextXAlignment = Enum.TextXAlignment.Center
        skyValueLabel.Size = UDim2.new(1, 0, 1, 0)
        skyValueLabel.ZIndex = 9
        skyValueLabel.Parent = holder
        local right = Instance.new("TextButton")
        right.Name = "SkyRight"
        right.BackgroundColor3 = Color3.fromRGB(7, 7, 10)
        right.BackgroundTransparency = 0.04
        right.Text = ">"
        right.TextColor3 = COLORS.white
        right.TextSize = 12
        right.Font = Enum.Font.GothamSemibold
        right.Size = UDim2.new(0, 42, 0, 28)
        right.Position = UDim2.new(1, -42, 0.5, -14)
        right.BorderSizePixel = 0
        right.ZIndex = 8
        right.AutoButtonColor = false
        right.Parent = row
        corner(right, 8)
        stroke(right, COLORS.strokeSoft, 1, 0.42)
        local function setSkyIndex(nextIndex)
            if nextIndex < 1 then
                nextIndex = #skyThemes
            end
            if nextIndex > #skyThemes then
                nextIndex = 1
            end
            skyIndex = nextIndex
            skyTheme = skyThemes[skyIndex]
            if applyCustomSky then
                applyCustomSky(skyTheme)
            end
            if skyValueLabel then
                skyValueLabel.Text = skyTheme
            end
            savePulseConfig()
        end
        left.Activated:Connect(function()
            setSkyIndex(skyIndex - 1)
        end)
        right.Activated:Connect(function()
            setSkyIndex(skyIndex + 1)
        end)
        return row
    end
    section(Utility, "ESP", 1)
    do
        local espRow, setESPVisual = toggleRow(Utility, "ESP", espEnabled, 2)
        setPlayerESPVisual = setESPVisual
        _pulseBtn = espRow and espRow:FindFirstChild("ToggleButton")
        if _pulseBtn then
            _pulseBtn.Activated:Connect(function()
                espEnabled = not espEnabled
                if espEnabled then
                    if startPlayerESP then
                        startPlayerESP()
                    end
                    if BoxedESPOptions then
                        BoxedESPOptions.box = true
                    end
                else
                    if stopPlayerESP then
                        stopPlayerESP()
                    end
                    if BoxedESPOptions then
                        BoxedESPOptions.box = false
                    end
                end
                if refreshBoxedESP then
                    refreshBoxedESP()
                end
                if setESPVisual then
                    setESPVisual(espEnabled)
                end
                savePulseConfig()
            end)
        end
    end
    do
        local tracerRow, setTracerVisual = toggleRow(Utility, "Tracer", showTracerEnabled, 3)
        setTracerESPVisual = setTracerVisual
        _pulseBtn = tracerRow and tracerRow:FindFirstChild("ToggleButton")
        if _pulseBtn then
            _pulseBtn.Activated:Connect(function()
                showTracerEnabled = not showTracerEnabled
                if BoxedESPOptions then
                    BoxedESPOptions.tracer = showTracerEnabled
                    BoxedESPOptions.box = espEnabled == true
                end
                if refreshBoxedESP then
                    refreshBoxedESP()
                end
                if setTracerVisual then
                    setTracerVisual(showTracerEnabled)
                end
                savePulseConfig()
            end)
        end
    end
    do
        local row, setVisual = _G.PulseActionToggleRow(Utility, "Ragdoll Countdown", ragdollCountdownEnabled, 4)
        setRagdollCountdownVisual = setVisual
        _pulseBtn = row and row:FindFirstChild("ToggleButton")
        if _pulseBtn then
            _pulseBtn.Activated:Connect(function()
                ragdollCountdownEnabled = not ragdollCountdownEnabled
                if ragdollCountdownEnabled then
                    hookRagdollCountdown(LP.Character)
                else
                    stopRagdollCountdown()
                end
                if setVisual then
                    setVisual(ragdollCountdownEnabled)
                end
                savePulseConfig()
            end)
        end
    end
    section(Utility, "SKY THEME", 5)
    skyThemeSelectorRow(Utility, 6)
    section(Utility, "PERFORMANCE", 7)
    do
        local row, setVisual = toggleRow(Utility, "Wide View", fpsBoostEnabled, 8)
        setFPSBoostVisual = setVisual
        _pulseBtn = row and row:FindFirstChild("ToggleButton")
        if _pulseBtn then
            _pulseBtn.Activated:Connect(function()
                fpsBoostEnabled = not fpsBoostEnabled
                if fpsBoostEnabled then
                    enableStretchRez()
                else
                    disableStretchRez()
                end
                if setVisual then
                    setVisual(fpsBoostEnabled)
                end
                savePulseConfig()
            end)
        end
    end
    do
        local row, setVisual = toggleRow(Utility, "Performance Mode", antiLagVisualEnabled, 9)
        setAntiLagVisual = setVisual
        _pulseBtn = row and row:FindFirstChild("ToggleButton")
        if _pulseBtn then
            _pulseBtn.Activated:Connect(function()
                if antiLagVisualEnabled then
                    disableAntiLag()
                else
                    enableAntiLag()
                end
                if setVisual then
                    setVisual(antiLagVisualEnabled)
                end
                savePulseConfig()
            end)
        end
    end
    section(Utility, "CAMERA", 11)
    do
        local row, setVisual = toggleRow(Utility, "FOV", fovEnabled, 12)
        setFOVVisual = setVisual
        _pulseBtn = row and row:FindFirstChild("ToggleButton")
        if _pulseBtn then
            _pulseBtn.Activated:Connect(function()
                if fovEnabled then
                    disableCustomFov()
                else
                    enableCustomFov()
                end
                if setVisual then
                    setVisual(fovEnabled)
                end
                savePulseConfig()
            end)
        end
    end
    do
        local _, box = textboxRow(Utility, "FOV Value", tostring(fovValue), 13)
        box.FocusLost:Connect(function()
            local v = tonumber(box.Text)
            if v and v >= 30 and v <= 120 then
                fovValue = v
                if fovEnabled and workspace.CurrentCamera then
                    workspace.CurrentCamera.FieldOfView = fovValue
                end
            end
            box.Text = tostring(fovValue)
            savePulseConfig()
        end)
    end
    do
        local row, setVisual = toggleRow(Utility, "Disable Camera Collision", noCamCollisionEnabled, 14)
        setNoCamCollisionVisual = setVisual
        _pulseBtn = row and row:FindFirstChild("ToggleButton")
        if _pulseBtn then
            _pulseBtn.Activated:Connect(function()
                if noCamCollisionEnabled then
                    disableNoCamCollision()
                else
                    enableNoCamCollision()
                end
                if setVisual then
                    setVisual(noCamCollisionEnabled)
                end
                savePulseConfig()
            end)
        end
    end
end
task.wait()
__PulseHubSetupVisualsUI()
Settings = pages.UTILITY
pulseGuiScaleValue = tonumber(savedConfig.pulseGuiScaleValue) or pulseGuiScaleValue
pulseGuiScaleValue = math.clamp(tonumber(pulseGuiScaleValue) or 0.52, 0.50, 1.50)
pulseProgressBarScaleValue = tonumber(savedConfig.pulseProgressBarScaleValue) or pulseProgressBarScaleValue
pulseMainScale = Main:FindFirstChild("PulseMainScale") or Instance.new("UIScale")
pulseMainScale.Name = "PulseMainScale"
pulseMainScale.Scale = pulseGuiScaleValue
pulseMainScale.Parent = Main
local function applyPulseProgressBarScale()
    local sg = PlayerGui:FindFirstChild("StealBarGui")
    local bar = sg and sg:FindFirstChild("StealBar")
    if not bar then
        return
    end
    local sc = bar:FindFirstChild("PulseProgressBarScale") or Instance.new("UIScale")
    sc.Name = "PulseProgressBarScale"
    sc.Scale = pulseProgressBarScaleValue
    sc.Parent = bar
end
function _G.PulseBuildMobileCustomizerUI(parent, orderBase)
    if not parent then
        return
    end
    orderBase = tonumber(orderBase) or 17
    section(parent, "MOBILE BUTTON COLORS", orderBase)
    local colorSpecs = {
        { key = "activeBackground", label = "Active Button Color", allowAuto = true },
        { key = "inactiveBackground", label = "Inactive Button Color", allowAuto = false },
        { key = "activeText", label = "Active Text Color", allowAuto = false },
        { key = "inactiveText", label = "Inactive Text Color", allowAuto = false },
    }
    local colorBoxes = {}
    local function refreshColorBoxes()
        local colors = _G.PulseMobileButtonColors or _G.PulseDefaultMobileButtonColors()
        for i = 1, #colorSpecs do
            local spec = colorSpecs[i]
            local box = colorBoxes[spec.key]
            if box then
                box.Text = colors[spec.key]
                local preview = _G.PulseResolveMobileButtonColor(spec.key)
                box.BackgroundColor3 = preview
                local luminance = preview.R * 0.299 + preview.G * 0.587 + preview.B * 0.114
                box.TextColor3 = (luminance > 0.55) and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
                local boxStroke = box:FindFirstChildOfClass("UIStroke")
                if boxStroke then
                    boxStroke.Color = (luminance > 0.55) and Color3.fromRGB(20, 20, 24) or Color3.fromRGB(235, 235, 240)
                end
            end
        end
    end
    for i = 1, #colorSpecs do
        local spec = colorSpecs[i]
        local colors = _G.PulseMobileButtonColors or _G.PulseDefaultMobileButtonColors()
        local _, box = textboxRow(parent, spec.label, colors[spec.key], orderBase + i)
        box.Size = UDim2.new(0, 76, 0, 24)
        box.Position = UDim2.new(1, -86, 0.5, -12)
        box.PlaceholderText = spec.allowAuto and "AUTO / HEX" or "#RRGGBB"
        colorBoxes[spec.key] = box
        box.FocusLost:Connect(function()
            local defaults = _G.PulseDefaultMobileButtonColors()
            local previous = (_G.PulseMobileButtonColors and _G.PulseMobileButtonColors[spec.key]) or defaults[spec.key]
            local normalized = _G.PulseNormalizeMobileButtonColor(box.Text, previous, spec.allowAuto)
            _G.PulseMobileButtonColors = _G.PulseMobileButtonColors or defaults
            _G.PulseMobileButtonColors[spec.key] = normalized
            refreshColorBoxes()
            if _G.PulseRefreshMobileAccent then
                _G.PulseRefreshMobileAccent()
            end
            savePulseConfig()
        end)
    end
    local resetColorsRow = baseRow(parent, "Reset Mobile Colors", orderBase + 5)
    local resetColorsButton = Instance.new("TextButton")
    resetColorsButton.Name = "ResetColors"
    resetColorsButton.BackgroundColor3 = Color3.fromRGB(232, 232, 238)
    resetColorsButton.BackgroundTransparency = 0
    resetColorsButton.BorderSizePixel = 0
    resetColorsButton.Text = "RESET"
    resetColorsButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    resetColorsButton.TextSize = 9
    resetColorsButton.Font = Enum.Font.GothamBlack
    resetColorsButton.AutoButtonColor = false
    resetColorsButton.Size = UDim2.new(0, 68, 0, 24)
    resetColorsButton.Position = UDim2.new(1, -78, 0.5, -12)
    resetColorsButton.ZIndex = 8
    resetColorsButton.Parent = resetColorsRow
    corner(resetColorsButton, 7)
    stroke(resetColorsButton, Color3.fromRGB(255, 255, 255), 1, 0.18)
    resetColorsButton.Activated:Connect(function()
        _G.PulseMobileButtonColors = _G.PulseDefaultMobileButtonColors()
        refreshColorBoxes()
        if _G.PulseRefreshMobileAccent then
            _G.PulseRefreshMobileAccent()
        end
        savePulseConfig()
    end)
    local mobileColorRow = Instance.new("Frame")
    mobileColorRow.Name = "Mobile Color Picker"
    mobileColorRow.BackgroundColor3 = COLORS.row
    mobileColorRow.BackgroundTransparency = 0.3
    mobileColorRow.Size = UDim2.new(1, -4, 0, 30)
    mobileColorRow.BorderSizePixel = 0
    mobileColorRow.LayoutOrder = orderBase + 6
    mobileColorRow.ZIndex = 4
    mobileColorRow.Parent = parent
    corner(mobileColorRow, 9)
    stroke(mobileColorRow, COLORS.strokeSoft, 1.15, 0.38)
    local pulseBackgroundColorOptionsMobile = {
        { name = "PURPLE", color = Color3.fromRGB(207, 159, 255), x = 8 },
        { name = "BLUE", color = Color3.fromRGB(58, 128, 245), x = 44 },
        { name = "RED", color = Color3.fromRGB(232, 52, 68), x = 80 },
        { name = "PINK", color = Color3.fromRGB(255, 105, 180), x = 116 },
        { name = "YELLOW", color = Color3.fromRGB(255, 214, 0), x = 152 },
        { name = "GREY", color = Color3.fromRGB(13, 13, 13), x = 188 },
        { name = "WHITE", color = Color3.fromRGB(255, 255, 255), x = 224 },
        { name = "FOREST", color = Color3.fromRGB(46, 139, 87), x = 260 },
    }
    for _, entry in ipairs(pulseBackgroundColorOptionsMobile) do
        local btn = Instance.new("TextButton")
        btn.Name = entry.name
        btn.BackgroundColor3 = entry.color
        btn.BackgroundTransparency = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Size = UDim2.new(0, 30, 0, 12)
        btn.Position = UDim2.new(0, entry.x, 0.5, -6)
        btn.BorderSizePixel = 0
        btn.ZIndex = 6
        btn.Parent = mobileColorRow
        corner(btn, 4)
        local st = Instance.new("UIStroke")
        st.Color = entry.color
        st.Transparency = 0.5
        st.Thickness = 1
        st.Parent = btn
        btn.MouseButton1Click:Connect(function()
            _G.PulseMobileButtonColors = _G.PulseMobileButtonColors or _G.PulseDefaultMobileButtonColors()
            if entry.name == "PURPLE" then
                _G.PulseMobileButtonColors.activeBackground = "#C39FFF"
                _G.PulseMobileButtonColors.inactiveBackground = "#2A0040"
            elseif entry.name == "BLUE" then
                _G.PulseMobileButtonColors.activeBackground = "#3A80F5"
                _G.PulseMobileButtonColors.inactiveBackground = "#001A40"
            elseif entry.name == "RED" then
                _G.PulseMobileButtonColors.activeBackground = "#E83444"
                _G.PulseMobileButtonColors.inactiveBackground = "#400010"
            elseif entry.name == "PINK" then
                _G.PulseMobileButtonColors.activeBackground = "#FF69B4"
                _G.PulseMobileButtonColors.inactiveBackground = "#400020"
            elseif entry.name == "YELLOW" then
                _G.PulseMobileButtonColors.activeBackground = "#FFD600"
                _G.PulseMobileButtonColors.inactiveBackground = "#403000"
            elseif entry.name == "GREY" then
                _G.PulseMobileButtonColors.activeBackground = "#333333"
                _G.PulseMobileButtonColors.inactiveBackground = "#0D0D0D"
            elseif entry.name == "WHITE" then
                _G.PulseMobileButtonColors.activeBackground = "#FFFFFF"
                _G.PulseMobileButtonColors.inactiveBackground = "#000000"
            elseif entry.name == "FOREST" then
                _G.PulseMobileButtonColors.activeBackground = "#2E8B57"
                _G.PulseMobileButtonColors.inactiveBackground = "#052015"
            end
            refreshColorBoxes()
            if _G.PulseRefreshMobileAccent then
                _G.PulseRefreshMobileAccent()
            end
            savePulseConfig()
        end)
    end
    section(parent, "MOBILE BUTTON EDITOR", orderBase + 7)
    local editorRows = {}
    local function findOrderIndex(id)
        for index, orderedId in ipairs(_G.PulseMobileButtonOrder or {}) do
            if orderedId == id then
                return index
            end
        end
        return nil
    end
    local function refreshEditorRows()
        _G.PulseMobileButtonOrder = _G.PulseSanitizeMobileButtonOrder(_G.PulseMobileButtonOrder)
        _G.PulseMobileButtonHidden = _G.PulseSanitizeMobileButtonHidden(_G.PulseMobileButtonHidden)
        local count = #_G.PulseMobileButtonOrder
        for id, controls in pairs(editorRows) do
            local index = findOrderIndex(id) or count
            local visible = _G.PulseMobileButtonHidden[id] ~= true
            controls.row.LayoutOrder = orderBase + 7 + index
            controls.visibility.Text = visible and "ON" or "OFF"
            controls.visibility.BackgroundColor3 = visible and Color3.fromRGB(235, 235, 240)
                or Color3.fromRGB(20, 20, 26)
            controls.visibility.TextColor3 = visible and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(220, 220, 228)
            controls.up.TextTransparency = (index <= 1) and 0.62 or 0
            controls.down.TextTransparency = (index >= count) and 0.62 or 0
            controls.up.BackgroundTransparency = (index <= 1) and 0.55 or 0.18
            controls.down.BackgroundTransparency = (index >= count) and 0.55 or 0.18
        end
    end
    local function applyEditorLayoutChange()
        _G.PulseMobileButtonPositions = {}
        if _G.PulseRebuildMobileButtons then
            _G.PulseRebuildMobileButtons()
        end
        refreshEditorRows()
        savePulseConfig()
    end
    local function moveEditorButton(id, direction)
        _G.PulseMobileButtonOrder = _G.PulseSanitizeMobileButtonOrder(_G.PulseMobileButtonOrder)
        local index = findOrderIndex(id)
        local target = index and (index + direction) or nil
        if not index or not target or target < 1 or target > #_G.PulseMobileButtonOrder then
            return
        end
        _G.PulseMobileButtonOrder[index], _G.PulseMobileButtonOrder[target] =
            _G.PulseMobileButtonOrder[target], _G.PulseMobileButtonOrder[index]
        applyEditorLayoutChange()
    end
    local function makeEditorControl(row, name, text, offset, width)
        local button = Instance.new("TextButton")
        button.Name = name
        button.BackgroundColor3 = Color3.fromRGB(12, 12, 17)
        button.BackgroundTransparency = 0.18
        button.BorderSizePixel = 0
        button.Text = text
        button.TextColor3 = Color3.fromRGB(240, 240, 245)
        button.TextSize = 8
        button.Font = Enum.Font.GothamBlack
        button.AutoButtonColor = false
        button.Size = UDim2.new(0, width, 0, 24)
        button.Position = UDim2.new(1, offset, 0.5, -12)
        button.ZIndex = 8
        button.Parent = row
        corner(button, 7)
        stroke(button, COLORS.strokeSoft, 1, 0.38)
        return button
    end
    for _, definition in ipairs(_G.PulseMobileButtonDefinitions) do
        local id = definition.id
        local row = baseRow(parent, definition.label, orderBase + 7)
        local label = row:FindFirstChild("Label")
        if label then
            label.Size = UDim2.new(1, -132, 1, 0)
        end
        local up = makeEditorControl(row, "MoveUp", "UP", -118, 30)
        local down = makeEditorControl(row, "MoveDown", "DN", -84, 30)
        local visibility = makeEditorControl(row, "Visibility", "ON", -50, 40)
        editorRows[id] = { row = row, up = up, down = down, visibility = visibility }
        up.Activated:Connect(function()
            moveEditorButton(id, -1)
        end)
        down.Activated:Connect(function()
            moveEditorButton(id, 1)
        end)
        visibility.Activated:Connect(function()
            _G.PulseMobileButtonHidden = _G.PulseMobileButtonHidden or {}
            _G.PulseMobileButtonHidden[id] = not (_G.PulseMobileButtonHidden[id] == true)
            applyEditorLayoutChange()
        end)
    end
    local resetEditorRow = baseRow(parent, "Reset Button Editor", orderBase + 8 + #_G.PulseMobileButtonDefinitions)
    local resetEditorButton = Instance.new("TextButton")
    resetEditorButton.Name = "ResetEditor"
    resetEditorButton.BackgroundColor3 = Color3.fromRGB(232, 232, 238)
    resetEditorButton.BackgroundTransparency = 0
    resetEditorButton.BorderSizePixel = 0
    resetEditorButton.Text = "RESET"
    resetEditorButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    resetEditorButton.TextSize = 9
    resetEditorButton.Font = Enum.Font.GothamBlack
    resetEditorButton.AutoButtonColor = false
    resetEditorButton.Size = UDim2.new(0, 68, 0, 24)
    resetEditorButton.Position = UDim2.new(1, -78, 0.5, -12)
    resetEditorButton.ZIndex = 8
    resetEditorButton.Parent = resetEditorRow
    corner(resetEditorButton, 7)
    stroke(resetEditorButton, Color3.fromRGB(255, 255, 255), 1, 0.18)
    resetEditorButton.Activated:Connect(function()
        _G.PulseMobileButtonOrder = _G.PulseCopyDefaultMobileButtonOrder()
        _G.PulseMobileButtonHidden = {}
        applyEditorLayoutChange()
    end)
    _G.PulseMobileColorEditorRefresh = refreshColorBoxes
    _G.PulseMobileEditorRefresh = refreshEditorRows
    refreshColorBoxes()
    refreshEditorRows()
end
_G.__PulseHubSetupSettingsUI = function()
    section(Settings, "GUI SETTINGS", 1)
    do
        local row, setVisual = _G.PulseActionToggleRow(Settings, "Lock GUI", _G.PulseGuiLocked == true, 8)
        setLockGuiVisual = setVisual
        local btn = row and row:FindFirstChild("ToggleButton")
        if btn then
            btn.Activated:Connect(function()
                _G.PulseGuiLocked = not (_G.PulseGuiLocked == true)
                if setVisual then
                    setVisual(_G.PulseGuiLocked == true)
                end
                if PulseUpdateGuiLockVisual then
                    PulseUpdateGuiLockVisual()
                end
                savePulseConfig()
            end)
        end
    end
    do
        local pulseDragLockWasOn = (_G.PulseGuiLocked == true)
        local dragMobRow, setDragMobileButtonsVisual =
            _G.PulseActionToggleRow(Settings, "Drag Mobile Buttons", _G.PulseDragMobileButtons == true, 8.5)
        local dragMobBtn = dragMobRow and dragMobRow:FindFirstChild("ToggleButton")
        if dragMobBtn then
            dragMobBtn.Activated:Connect(function()
                _G.PulseDragMobileButtons = not (_G.PulseDragMobileButtons == true)
                if _G.PulseDragMobileButtons then
                    pulseDragLockWasOn = (_G.PulseGuiLocked == true)
                    _G.PulseGuiLocked = false
                else
                    if pulseDragLockWasOn then
                        _G.PulseGuiLocked = true
                    end
                end
                if setDragMobileButtonsVisual then
                    setDragMobileButtonsVisual(_G.PulseDragMobileButtons == true)
                end
                if setLockGuiVisual then
                    setLockGuiVisual(_G.PulseGuiLocked == true)
                end
                if PulseUpdateGuiLockVisual then
                    PulseUpdateGuiLockVisual()
                end
                savePulseConfig()
            end)
        end
    end
    do
        local row, setVisual =
            _G.PulseActionToggleRow(Settings, "Hide Mobile Buttons", _G.PulseHideMobileButtons == true, 9)
        setHideMobileButtonsVisual = setVisual
        local btn = row and row:FindFirstChild("ToggleButton")
        if btn then
            btn.Activated:Connect(function()
                _G.PulseHideMobileButtons = not (_G.PulseHideMobileButtons == true)
                if setVisual then
                    setVisual(_G.PulseHideMobileButtons == true)
                end
                if _G.PulseApplyMobileButtonsHidden then
                    _G.PulseApplyMobileButtonsHidden()
                end
                savePulseConfig()
            end)
        end
    end
    local bgRow = Instance.new("Frame")
    bgRow.Name = "Background Image Picker"
    bgRow.BackgroundColor3 = COLORS.row
    bgRow.BackgroundTransparency = 0.3
    bgRow.Size = UDim2.new(1, -4, 0, 58)
    bgRow.BorderSizePixel = 0
    bgRow.LayoutOrder = 2
    bgRow.ZIndex = 4
    bgRow.Parent = Settings
    corner(bgRow, 9)
    stroke(bgRow, COLORS.strokeSoft, 1.15, 0.38)
    local bgButtons = {}
    local bgSlotHolders = {}
    local bgSlotIndex = {}
    local bgPageStart = 1
    local BG_IMG_SLOTS = 3
    local bgLeftArrow = nil
    local bgRightArrow = nil
    function updateBackgroundButtons()
        if bgButtons[0] then
            local selected = currentBackground == 0
            bgButtons[0].BackgroundTransparency = selected and 0.12 or 0.42
            local st = bgButtons[0]:FindFirstChildOfClass("UIStroke")
            if st then
                st.Color = selected and Color3.fromRGB(245, 245, 255) or COLORS.strokeSoft
                st.Transparency = selected and 0.12 or 0.55
                st.Thickness = selected and 1.15 or 1
            end
        end
        for slot, holder in ipairs(bgSlotHolders) do
            local index = bgSlotIndex[slot]
            local visible = index ~= nil and index >= 1 and index <= #BackgroundIDs
            holder.Visible = visible
            if visible then
                local selected = index == currentBackground
                holder.BackgroundTransparency = selected and 0.12 or 0.35
                local st = holder:FindFirstChildOfClass("UIStroke")
                if st then
                    st.Color = selected and Color3.fromRGB(245, 245, 255) or COLORS.strokeSoft
                    st.Transparency = selected and 0.12 or 0.55
                    st.Thickness = selected and 1.15 or 1
                end
            end
        end
    end
    function refreshBackgroundGallery()
        for slot, holder in ipairs(bgSlotHolders) do
            local index = bgPageStart + slot - 1
            bgSlotIndex[slot] = index
            if index <= #BackgroundIDs then
                holder.Visible = true
                local img = holder:FindFirstChild("Preview")
                if img then
                    img.Image = "rbxassetid://" .. BackgroundIDs[index]
                end
            else
                holder.Visible = false
            end
        end
        if bgLeftArrow then
            bgLeftArrow.TextTransparency = (bgPageStart <= 1) and 0.65 or 0
            bgLeftArrow.BackgroundTransparency = (bgPageStart <= 1) and 0.55 or 0.25
        end
        if bgRightArrow then
            local lastStart = math.max(1, 1 + math.floor(math.max(0, #BackgroundIDs - 1) / BG_IMG_SLOTS) * BG_IMG_SLOTS)
            bgRightArrow.TextTransparency = (bgPageStart >= lastStart) and 0.65 or 0
            bgRightArrow.BackgroundTransparency = (bgPageStart >= lastStart) and 0.55 or 0.25
        end
        updateBackgroundButtons()
    end
    function makeNoneButton(index, x)
        local btn = Instance.new("TextButton")
        btn.Name = "None"
        btn.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
        btn.BackgroundTransparency = 0.12
        btn.BorderSizePixel = 0
        btn.Text = "None"
        btn.TextColor3 = COLORS.white
        btn.TextSize = 8
        btn.Font = Enum.Font.GothamSemibold
        btn.AutoButtonColor = false
        btn.Size = UDim2.new(0, 52, 0, 40)
        btn.Position = UDim2.new(0, x, 0.5, -20)
        btn.ZIndex = 6
        btn.ClipsDescendants = true
        btn.Parent = bgRow
        corner(btn, 8)
        stroke(btn, Color3.fromRGB(245, 245, 255), 1.15, 0.12)
        bgButtons[index] = btn
        btn.MouseButton1Click:Connect(function()
            applyBackground(index)
            updateBackgroundButtons()
        end)
    end
    function makeImageSlot(slot, x)
        local holder = Instance.new("Frame")
        holder.Name = "ImageSlot " .. tostring(slot)
        holder.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
        holder.BackgroundTransparency = 0.35
        holder.BorderSizePixel = 0
        holder.Size = UDim2.new(0, 52, 0, 40)
        holder.Position = UDim2.new(0, x, 0.5, -20)
        holder.ZIndex = 6
        holder.ClipsDescendants = true
        holder.Parent = bgRow
        corner(holder, 8)
        stroke(holder, COLORS.strokeSoft, 1, 0.45)
        local img = Instance.new("ImageLabel")
        img.Name = "Preview"
        img.BackgroundTransparency = 1
        img.ScaleType = Enum.ScaleType.Crop
        img.Size = UDim2.new(1, 0, 1, 0)
        img.Position = UDim2.new(0, 0, 0, 0)
        img.ZIndex = 6
        img.Parent = holder
        corner(img, 8)
        local click = Instance.new("TextButton")
        click.Name = "Click"
        click.BackgroundTransparency = 1
        click.Text = ""
        click.AutoButtonColor = false
        click.Size = UDim2.new(1, 0, 1, 0)
        click.Position = UDim2.new(0, 0, 0, 0)
        click.ZIndex = 7
        click.Parent = holder
        bgSlotHolders[slot] = holder
        click.MouseButton1Click:Connect(function()
            local index = bgSlotIndex[slot]
            if index and index >= 1 and index <= #BackgroundIDs then
                applyBackground(index)
                updateBackgroundButtons()
            end
        end)
    end
    function makeBgArrow(direction)
        local btn = Instance.new("TextButton")
        btn.Name = direction < 0 and "BgPrev" or "BgNext"
        btn.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
        btn.BackgroundTransparency = 0.25
        btn.BorderSizePixel = 0
        btn.Text = direction < 0 and "<" or ">"
        btn.TextColor3 = COLORS.white
        btn.TextTransparency = 0
        btn.TextSize = 16
        btn.Font = Enum.Font.GothamBlack
        btn.AutoButtonColor = false
        btn.Size = UDim2.new(0, 20, 0, 40)
        btn.Position = direction < 0 and UDim2.new(0, 64, 0.5, -20) or UDim2.new(1, -28, 0.5, -20)
        btn.ZIndex = 7
        btn.Parent = bgRow
        corner(btn, 7)
        stroke(btn, COLORS.strokeSoft, 1, 0.4)
        btn.MouseButton1Click:Connect(function()
            local lastStart = math.max(1, 1 + math.floor(math.max(0, #BackgroundIDs - 1) / BG_IMG_SLOTS) * BG_IMG_SLOTS)
            local nextStart = bgPageStart + direction * BG_IMG_SLOTS
            if nextStart < 1 then
                nextStart = 1
            end
            if nextStart > lastStart then
                nextStart = lastStart
            end
            bgPageStart = nextStart
            refreshBackgroundGallery()
        end)
        return btn
    end
    function stepperRow(parent, labelText, defaultValue, order, callback, minValue, maxValue, applyOnRelease)
        local row = Instance.new("Frame")
        row.Name = labelText
        row.BackgroundColor3 = COLORS.row
        row.BackgroundTransparency = 0.22
        row.Size = UDim2.new(1, -4, 0, 42)
        row.BorderSizePixel = 0
        row.LayoutOrder = order
        row.ZIndex = 4
        row.Parent = parent
        corner(row, 10)
        stroke(row, COLORS.strokeSoft, 1.15, 0.32)
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(245, 245, 255)
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.TextStrokeTransparency = 0.25
        label.TextSize = 10.5
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Position = UDim2.new(0, 10, 0, 0)
        label.Size = UDim2.new(0, 90, 1, 0)
        label.ZIndex = 5
        label.Parent = row
        local minVal = minValue or 0.30
        local maxVal = maxValue or 1.50
        local value = math.clamp(defaultValue or minVal, minVal, maxVal)
        local sliderTrack = Instance.new("Frame")
        sliderTrack.Name = "SliderTrack"
        sliderTrack.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
        sliderTrack.BackgroundTransparency = 0.15
        sliderTrack.BorderSizePixel = 0
        sliderTrack.Position = UDim2.new(0, 102, 0.5, -4)
        sliderTrack.Size = UDim2.new(1, -204, 0, 8)
        sliderTrack.ZIndex = 5
        sliderTrack.Parent = row
        corner(sliderTrack, 4)
        stroke(sliderTrack, COLORS.strokeSoft, 1, 0.5)
        local sliderFill = Instance.new("Frame")
        sliderFill.Name = "Fill"
        sliderFill.BackgroundColor3 = Color3.fromRGB(245, 245, 255)
        sliderFill.BorderSizePixel = 0
        sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
        sliderFill.ZIndex = 6
        sliderFill.Parent = sliderTrack
        corner(sliderFill, 4)
        local sliderKnob = Instance.new("Frame")
        sliderKnob.Name = "Knob"
        sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sliderKnob.BorderSizePixel = 0
        sliderKnob.Size = UDim2.new(0, 12, 0, 12)
        sliderKnob.Position = UDim2.new(0.5, -6, 0.5, -6)
        sliderKnob.ZIndex = 7
        sliderKnob.Parent = sliderTrack
        corner(sliderKnob, 999)
        do
            local ks = Instance.new("UIStroke")
            ks.Color = Color3.fromRGB(0, 0, 0)
            ks.Thickness = 1
            ks.Parent = sliderKnob
        end
        local minus = Instance.new("TextButton")
        minus.Name = "Minus"
        minus.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
        minus.BackgroundTransparency = 0.1
        minus.BorderSizePixel = 0
        minus.Text = "-"
        minus.TextColor3 = Color3.fromRGB(245, 245, 255)
        minus.TextSize = 14
        minus.Font = Enum.Font.GothamBlack
        minus.AutoButtonColor = false
        minus.Size = UDim2.new(0, 24, 0, 24)
        minus.Position = UDim2.new(1, -96, 0.5, -12)
        minus.ZIndex = 6
        minus.Parent = row
        corner(minus, 6)
        stroke(minus, COLORS.strokeSoft, 1, 0.5)
        local valueBox = Instance.new("TextLabel")
        valueBox.Name = "Value"
        valueBox.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
        valueBox.BackgroundTransparency = 0.05
        valueBox.BorderSizePixel = 0
        valueBox.Text = string.format("%.2f", value)
        valueBox.TextColor3 = Color3.fromRGB(245, 245, 255)
        valueBox.TextSize = 12
        valueBox.Font = Enum.Font.GothamBlack
        valueBox.TextXAlignment = Enum.TextXAlignment.Center
        valueBox.Size = UDim2.new(0, 38, 0, 24)
        valueBox.Position = UDim2.new(1, -68, 0.5, -12)
        valueBox.ZIndex = 6
        valueBox.Parent = row
        corner(valueBox, 6)
        stroke(valueBox, COLORS.strokeSoft, 1, 0.5)
        local plus = Instance.new("TextButton")
        plus.Name = "Plus"
        plus.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
        plus.BackgroundTransparency = 0.1
        plus.BorderSizePixel = 0
        plus.Text = "+"
        plus.TextColor3 = Color3.fromRGB(245, 245, 255)
        plus.TextSize = 14
        plus.Font = Enum.Font.GothamBlack
        plus.AutoButtonColor = false
        plus.Size = UDim2.new(0, 24, 0, 24)
        plus.Position = UDim2.new(1, -26, 0.5, -12)
        plus.ZIndex = 6
        plus.Parent = row
        corner(plus, 6)
        stroke(plus, COLORS.strokeSoft, 1, 0.5)
        local function updateVisuals(animate)
            local alpha = math.clamp((value - minVal) / math.max(0.001, maxVal - minVal), 0, 1)
            if animate then
                TweenService:Create(
                    sliderFill,
                    TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { Size = UDim2.new(alpha, 0, 1, 0) }
                ):Play()
                TweenService:Create(
                    sliderKnob,
                    TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { Position = UDim2.new(alpha, -6, 0.5, -6) }
                ):Play()
            else
                sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
                sliderKnob.Position = UDim2.new(alpha, -6, 0.5, -6)
            end
            valueBox.Text = string.format("%.2f", value)
        end
        local function setValue(nextValue, animate, triggerCallback)
            value = math.clamp(math.floor((nextValue * 100) + 0.5) / 100, minVal, maxVal)
            updateVisuals(animate)
            if triggerCallback ~= false and callback then
                callback(value)
            end
        end
        local sliderDragging = false
        local function updateFromSlider(input)
            local trackPos = sliderTrack.AbsolutePosition.X
            local trackWidth = sliderTrack.AbsoluteSize.X
            if trackWidth <= 0 then
                return
            end
            local rel = math.clamp((input.Position.X - trackPos) / trackWidth, 0, 1)
            local newVal = minVal + rel * (maxVal - minVal)
            setValue(newVal, false, applyOnRelease ~= true)
        end
        sliderTrack.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                sliderDragging = true
                updateFromSlider(input)
                local conn
                conn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        sliderDragging = false
                        if applyOnRelease == true and callback then
                            callback(value)
                        end
                        if conn then
                            conn:Disconnect()
                        end
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if
                sliderDragging
                and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                )
            then
                updateFromSlider(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if
                sliderDragging
                and (
                    input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                )
            then
                sliderDragging = false
                if applyOnRelease == true and callback then
                    callback(value)
                end
            end
        end)
        minus.MouseButton1Click:Connect(function()
            setValue(value - 0.01, true, true)
        end)
        plus.MouseButton1Click:Connect(function()
            setValue(value + 0.01, true, true)
        end)
        updateVisuals(false)
        return row
    end
    makeNoneButton(0, 8)
    bgLeftArrow = makeBgArrow(-1)
    makeImageSlot(1, 88)
    makeImageSlot(2, 146)
    makeImageSlot(3, 204)
    bgRightArrow = makeBgArrow(1)
    refreshBackgroundGallery()
    updateBackgroundButtons()
    local pulseBackgroundColorButtons = {}
    local pulseBackgroundColorOptions = {
        { name = "PURPLE", color = Color3.fromRGB(207, 159, 255), x = 8 },
        { name = "BLUE", color = Color3.fromRGB(58, 128, 245), x = 44 },
        { name = "RED", color = Color3.fromRGB(232, 52, 68), x = 80 },
        { name = "PINK", color = Color3.fromRGB(255, 105, 180), x = 116 },
        { name = "YELLOW", color = Color3.fromRGB(255, 214, 0), x = 152 },
        { name = "GREY", color = Color3.fromRGB(13, 13, 13), x = 188 },
        { name = "WHITE", color = Color3.fromRGB(255, 255, 255), x = 224 },
        { name = "FOREST", color = Color3.fromRGB(46, 139, 87), x = 260 },
    }
    local function pulseColorsMatch(c1, c2)
        if not c1 or not c2 then
            return false
        end
        return math.abs(c1.R - c2.R) < 0.02 and math.abs(c1.G - c2.G) < 0.02 and math.abs(c1.B - c2.B) < 0.02
    end
    function updateBackgroundColorButtons()
        for _, entry in ipairs(pulseBackgroundColorOptions) do
            local btn = pulseBackgroundColorButtons[entry.name]
            if btn then
                local selected = (
                    currentBackgroundColor ~= nil and pulseColorsMatch(currentBackgroundColor, entry.color)
                ) or (currentBackgroundColor == nil and entry.name == "WHITE")
                local st = btn:FindFirstChildOfClass("UIStroke")
                if st then
                    st.Color = selected and COLORS.white or entry.color
                    st.Transparency = selected and 0 or 0.5
                    st.Thickness = selected and 2 or 1
                end
            end
        end
    end
    local colorRow = Instance.new("Frame")
    colorRow.Name = "Background Color Picker"
    colorRow.BackgroundColor3 = COLORS.row
    colorRow.BackgroundTransparency = 0.3
    colorRow.Size = UDim2.new(1, -4, 0, 30)
    colorRow.BorderSizePixel = 0
    colorRow.LayoutOrder = 2.5
    colorRow.ZIndex = 4
    colorRow.Parent = Settings
    corner(colorRow, 9)
    stroke(colorRow, COLORS.strokeSoft, 1.15, 0.38)
    for _, entry in ipairs(pulseBackgroundColorOptions) do
        local btn = Instance.new("TextButton")
        btn.Name = entry.name
        btn.BackgroundColor3 = entry.color
        btn.BackgroundTransparency = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Size = UDim2.new(0, 30, 0, 12)
        btn.Position = UDim2.new(0, entry.x, 0.5, -6)
        btn.BorderSizePixel = 0
        btn.ZIndex = 6
        btn.Parent = colorRow
        corner(btn, 4)
        local st = Instance.new("UIStroke")
        st.Color = entry.color
        st.Transparency = 0.5
        st.Thickness = 1
        st.Parent = btn
        pulseBackgroundColorButtons[entry.name] = btn
        btn.MouseButton1Click:Connect(function()
            if entry.name == "WHITE" then
                applyBackgroundColor(nil)
            else
                applyBackgroundColor(entry.color)
            end
        end)
    end
    updateBackgroundColorButtons()
    local hexRow, hexBox = textboxRow(Settings, "Custom Color Hex", "#FF3CAC", 2.6)
    hexBox.PlaceholderText = "#RRGGBB"
    hexBox.FocusLost:Connect(function()
        local text = string.gsub(hexBox.Text or "", "[^%w]", "")
        if #text == 6 then
            local r = tonumber(string.sub(text, 1, 2), 16)
            local g = tonumber(string.sub(text, 3, 4), 16)
            local b = tonumber(string.sub(text, 5, 6), 16)
            if r and g and b then
                local newColor = Color3.fromRGB(r, g, b)
                applyBackgroundColor(newColor)
                _safeNotify("HEX COLOR: #" .. string.upper(text))
            end
        end
    end)
    stepperRow(Settings, "Menu Scale", pulseGuiScaleValue, 3, function(v)
        pulseGuiScaleValue = v
        pulseMainScale.Scale = v
        savePulseConfig()
    end, 0.35, 1.50, true)
    stepperRow(Settings, "Status Bar Scale", pulseProgressBarScaleValue, 4, function(v)
        pulseProgressBarScaleValue = v
        applyPulseProgressBarScale()
        savePulseConfig()
    end, 0.50, 1.50)
    do
        local scToggleRow, setSpeedCustomizerVisual =
            _G.PulseActionToggleRow(Settings, "Speed Customizer", speedCustomizerEnabled, 4.5)
        local scToggleBtn = scToggleRow and scToggleRow:FindFirstChild("ToggleButton")
        if scToggleBtn then
            scToggleBtn.Activated:Connect(function()
                speedCustomizerEnabled = not speedCustomizerEnabled
                _G.PulseSpeedCustomizerOn = speedCustomizerEnabled
                if speedCustomizerGui then
                    speedCustomizerGui.Enabled = speedCustomizerEnabled
                end
                if setSpeedCustomizerVisual then
                    setSpeedCustomizerVisual(speedCustomizerEnabled)
                end
                savePulseConfig()
            end)
        end
    end
    do
        local resetBarHolder = Instance.new("Frame")
        resetBarHolder.Name = "Reset Progress Bar Holder"
        resetBarHolder.BackgroundTransparency = 1
        resetBarHolder.BorderSizePixel = 0
        resetBarHolder.Size = UDim2.new(1, -4, 0, 44)
        resetBarHolder.LayoutOrder = 4.6
        resetBarHolder.ZIndex = 5
        resetBarHolder.Parent = Settings
        local resetBarBtn = Instance.new("TextButton")
        resetBarBtn.Name = "Reset Progress Bar"
        resetBarBtn.BackgroundColor3 = Color3.fromRGB(232, 232, 238)
        resetBarBtn.BackgroundTransparency = 0
        resetBarBtn.BorderSizePixel = 0
        resetBarBtn.Text = "Reset Progress Bar"
        resetBarBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        resetBarBtn.TextStrokeTransparency = 1
        resetBarBtn.TextSize = 12
        resetBarBtn.Font = Enum.Font.GothamBlack
        resetBarBtn.AutoButtonColor = false
        resetBarBtn.Size = UDim2.new(1, -16, 0, 42)
        resetBarBtn.Position = UDim2.new(0, 8, 0, 1)
        resetBarBtn.ZIndex = 6
        resetBarBtn.Parent = resetBarHolder
        corner(resetBarBtn, 10)
        local resetBarStroke = Instance.new("UIStroke")
        resetBarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        resetBarStroke.Color = Color3.fromRGB(255, 255, 255)
        resetBarStroke.Thickness = 1
        resetBarStroke.Transparency = 0.12
        resetBarStroke.Parent = resetBarBtn
        resetBarBtn.MouseEnter:Connect(function()
            tween(resetBarBtn, { BackgroundColor3 = Color3.fromRGB(245, 245, 250) }, 0.12)
        end)
        resetBarBtn.MouseLeave:Connect(function()
            tween(resetBarBtn, { BackgroundColor3 = Color3.fromRGB(232, 232, 238) }, 0.12)
        end)
        resetBarBtn.MouseButton1Click:Connect(function()
            showPulseConfirmDialog("Are you sure you would like to do this?", function()
                savedStealBarPositionTable = nil
                local sg = PlayerGui:FindFirstChild("StealBarGui")
                local bar = sg and sg:FindFirstChild("StealBar")
                if bar then
                    bar.Position = UDim2.new(0.5, 0, 1, -80)
                end
                savePulseConfig()
            end)
        end)
    end
    speedKeybindRow(Settings, "Toggle UI", "ToggleUI", 6)
    do
        section(Settings, "LAGGER CYCLE ORDER", 6.1)
        local cycleRows = {}
        local laggerCycleHolder = Instance.new("Frame")
        laggerCycleHolder.Name = "LaggerCycleHolder"
        laggerCycleHolder.BackgroundTransparency = 1
        laggerCycleHolder.Size = UDim2.new(1, 0, 0, 0)
        laggerCycleHolder.AutomaticSize = Enum.AutomaticSize.Y
        laggerCycleHolder.LayoutOrder = 6
        laggerCycleHolder.Parent = Settings
        local laggerCycleLayout = Instance.new("UIListLayout")
        laggerCycleLayout.Padding = UDim.new(0, 7)
        laggerCycleLayout.SortOrder = Enum.SortOrder.LayoutOrder
        laggerCycleLayout.Parent = laggerCycleHolder
        local function refreshCycleUI()
            local count = #_G.PulseLaggerCycleOrder
            for mode, controls in pairs(cycleRows) do
                local index = 1
                for i, m in ipairs(_G.PulseLaggerCycleOrder) do
                    if m == mode then
                        index = i
                        break
                    end
                end
                controls.row.LayoutOrder = index
                controls.up.TextTransparency = (index <= 1) and 0.62 or 0
                controls.down.TextTransparency = (index >= count) and 0.62 or 0
                controls.up.BackgroundTransparency = (index <= 1) and 0.55 or 0.18
                controls.down.BackgroundTransparency = (index >= count) and 0.55 or 0.18
                if controls._lastIndex ~= nil and controls._lastIndex ~= index then
                    task.spawn(function()
                        local r = controls.row
                        local orig = r.BackgroundColor3
                        pcall(function()
                            TweenService
                                :Create(
                                    r,
                                    TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                                    { BackgroundColor3 = Color3.fromRGB(70, 70, 85) }
                                )
                                :Play()
                            task.wait(0.18)
                            TweenService
                                :Create(
                                    r,
                                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                                    { BackgroundColor3 = orig }
                                )
                                :Play()
                        end)
                    end)
                end
                controls._lastIndex = index
                local lbl = controls.row:FindFirstChild("Label")
                if lbl then
                    lbl.Text = tostring(index) .. ". " .. mode
                end
            end
        end
        local function moveCycleMode(mode, dir)
            local idx = 1
            for i, m in ipairs(_G.PulseLaggerCycleOrder) do
                if m == mode then
                    idx = i
                    break
                end
            end
            local target = idx + dir
            if target < 1 or target > #_G.PulseLaggerCycleOrder then
                return
            end
            _G.PulseLaggerCycleOrder[idx], _G.PulseLaggerCycleOrder[target] =
                _G.PulseLaggerCycleOrder[target], _G.PulseLaggerCycleOrder[idx]
            refreshCycleUI()
            pcall(function()
                _safeNotify("LAGGER ORDER: " .. table.concat(_G.PulseLaggerCycleOrder, " > "))
            end)
            pcall(function()
                triggerHaptic()
            end)
            savePulseConfig()
        end
        local modes = { "Lagger Carry", "Lagger Carry 2", "Lagger", "Lagger 2" }
        for _, m in ipairs(modes) do
            local row = baseRow(laggerCycleHolder, m, 0)
            local label = row:FindFirstChild("Label")
            if label then
                label.Size = UDim2.new(1, -100, 1, 0)
            end
            local up = Instance.new("TextButton")
            up.Text = "UP"
            up.Size = UDim2.new(0, 30, 0, 24)
            up.Position = UDim2.new(1, -74, 0.5, -12)
            up.BackgroundColor3 = Color3.fromRGB(12, 12, 17)
            up.TextColor3 = Color3.fromRGB(240, 240, 245)
            up.Font = Enum.Font.GothamBlack
            up.TextSize = 8
            up.Parent = row
            corner(up, 7)
            stroke(up, COLORS.strokeSoft, 1, 0.38)
            local down = Instance.new("TextButton")
            down.Text = "DN"
            down.Size = UDim2.new(0, 30, 0, 24)
            down.Position = UDim2.new(1, -40, 0.5, -12)
            down.BackgroundColor3 = Color3.fromRGB(12, 12, 17)
            down.TextColor3 = Color3.fromRGB(240, 240, 245)
            down.Font = Enum.Font.GothamBlack
            down.TextSize = 8
            down.Parent = row
            corner(down, 7)
            stroke(down, COLORS.strokeSoft, 1, 0.38)
            cycleRows[m] = { row = row, up = up, down = down }
            up.Activated:Connect(function()
                moveCycleMode(m, -1)
            end)
            down.Activated:Connect(function()
                moveCycleMode(m, 1)
            end)
        end
        refreshCycleUI()
    end
    animationPackRow(Settings, 6)
    section(Settings, "MOBILE BUTTONS", 7)
    local autoRejoinOnKickEnabled = true
    pcall(function()
        local CoreGui = game:GetService("CoreGui")
        local promptGui = CoreGui:FindFirstChild("RobloxPromptGui")
        local overlay = promptGui and promptGui:FindFirstChild("promptOverlay")
        if overlay then
            overlay.ChildAdded:Connect(function(child)
                if autoRejoinOnKickEnabled and (child.Name == "ErrorPrompt" or child.Name:find("Prompt")) then
                    task.wait(0.8)
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
                end
            end)
        end
    end)
    local _, setAutoRejoinVisual = _G.PulseActionToggleRow(Settings, "Auto Rejoin on Kick", autoRejoinOnKickEnabled, 16)
    do
        local row = Settings:FindFirstChild("Auto Rejoin on Kick")
        local btn = row and row:FindFirstChild("ToggleButton")
        if btn then
            btn.Activated:Connect(function()
                autoRejoinOnKickEnabled = not autoRejoinOnKickEnabled
                if setAutoRejoinVisual then
                    setAutoRejoinVisual(autoRejoinOnKickEnabled)
                end
                savePulseConfig()
            end)
        end
    end
    local mobileButtonsSizeStepperRow = stepperRow(
        Settings,
        "Mobile Buttons Size",
        tonumber(_G.PulseMobileButtonScale) or 0.75,
        10,
        function(v)
            _G.PulseMobileButtonScale = math.clamp(tonumber(v) or 0.35, 0.30, 1.35)
            if _G.PulseApplyMobileButtonSize then
                _G.PulseApplyMobileButtonSize()
            end
            savePulseConfig()
        end,
        0.30,
        1.35
    )
    do
        local resetBtnPosHolder = Instance.new("Frame")
        resetBtnPosHolder.Name = "Reset Button Positions Holder"
        resetBtnPosHolder.BackgroundTransparency = 1
        resetBtnPosHolder.BorderSizePixel = 0
        resetBtnPosHolder.Size = UDim2.new(1, -4, 0, 44)
        resetBtnPosHolder.LayoutOrder = 10.5
        resetBtnPosHolder.ZIndex = 5
        resetBtnPosHolder.Parent = Settings
        local resetBtnPosBtn = Instance.new("TextButton")
        resetBtnPosBtn.Name = "Reset Button Positions"
        resetBtnPosBtn.BackgroundColor3 = Color3.fromRGB(232, 232, 238)
        resetBtnPosBtn.BackgroundTransparency = 0
        resetBtnPosBtn.BorderSizePixel = 0
        resetBtnPosBtn.Text = "Reset Button Positions"
        resetBtnPosBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        resetBtnPosBtn.TextStrokeTransparency = 1
        resetBtnPosBtn.TextSize = 12
        resetBtnPosBtn.Font = Enum.Font.GothamBlack
        resetBtnPosBtn.AutoButtonColor = false
        resetBtnPosBtn.Size = UDim2.new(1, -16, 0, 42)
        resetBtnPosBtn.Position = UDim2.new(0, 8, 0, 1)
        resetBtnPosBtn.ZIndex = 6
        resetBtnPosBtn.Parent = resetBtnPosHolder
        corner(resetBtnPosBtn, 10)
        local resetBtnPosStroke = Instance.new("UIStroke")
        resetBtnPosStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        resetBtnPosStroke.Color = Color3.fromRGB(255, 255, 255)
        resetBtnPosStroke.Thickness = 1
        resetBtnPosStroke.Transparency = 0.12
        resetBtnPosStroke.Parent = resetBtnPosBtn
        resetBtnPosBtn.MouseEnter:Connect(function()
            tween(resetBtnPosBtn, { BackgroundColor3 = Color3.fromRGB(245, 245, 250) }, 0.12)
        end)
        resetBtnPosBtn.MouseLeave:Connect(function()
            tween(resetBtnPosBtn, { BackgroundColor3 = Color3.fromRGB(232, 232, 238) }, 0.12)
        end)
        resetBtnPosBtn.MouseButton1Click:Connect(function()
            showPulseConfirmDialog("Are you sure you would like to do this?", function()
                if _G.PulseResetMobileButtons then
                    _G.PulseResetMobileButtons()
                end
                pcall(function()
                    local vb = mobileButtonsSizeStepperRow and mobileButtonsSizeStepperRow:FindFirstChild("Value")
                    if vb then
                        vb.Text = string.format("%.2f", 0.75)
                    end
                end)
            end)
        end)
    end
    if _G.PulseBuildMobileCustomizerUI then
        _G.PulseBuildMobileCustomizerUI(Settings, 17)
    end
    local stealRingAdorn = nil
    local function update3DStealRing()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not autoStealEnabled or not hrp then
            if stealRingAdorn then
                stealRingAdorn.Visible = false
            end
            return
        end
        if not stealRingAdorn then
            stealRingAdorn = Instance.new("CylinderHandleAdornment")
            stealRingAdorn.Name = "PulseStealRadiusRing"
            stealRingAdorn.Height = 0.15
            stealRingAdorn.Transparency = 0.72
            stealRingAdorn.ZIndex = 1
            stealRingAdorn.AlwaysOnTop = true
            stealRingAdorn.Parent = Workspace.Terrain
        end
        local rad = tonumber(autoStealRadius) or 62
        stealRingAdorn.Radius = rad
        stealRingAdorn.InnerRadius = math.max(0.1, rad - 0.5)
        stealRingAdorn.Color3 = (_G.PulseGetAccentColor and _G.PulseGetAccentColor()) or Color3.fromRGB(255, 60, 172)
        stealRingAdorn.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 2.8, hrp.Position.Z)
            * CFrame.Angles(math.rad(90), 0, 0)
        stealRingAdorn.Visible = true
    end
    RunService.RenderStepped:Connect(update3DStealRing)
    local aimbotHighlight = nil
    local function updateAimbotHighlight()
        local target = _G.PulseCurrentAimbotTarget or (_G.PulseNormalAimbot and _G.PulseNormalAimbot.target)
        if target and typeof(target) == "Instance" and target:IsA("Player") and target.Character then
            if not aimbotHighlight then
                aimbotHighlight = Instance.new("Highlight")
                aimbotHighlight.Name = "PulseTargetHighlight"
                aimbotHighlight.FillTransparency = 0.68
                aimbotHighlight.OutlineTransparency = 0.15
                aimbotHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                aimbotHighlight.Parent = PlayerGui
            end
            local acc = (_G.PulseGetAccentColor and _G.PulseGetAccentColor()) or Color3.fromRGB(255, 60, 172)
            aimbotHighlight.FillColor = acc
            aimbotHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            aimbotHighlight.Adornee = target.Character
            aimbotHighlight.Enabled = true
        else
            if aimbotHighlight then
                aimbotHighlight.Enabled = false
            end
        end
    end
    RunService.RenderStepped:Connect(updateAimbotHighlight)
    local aimbotTracerLine = nil
    local function updateAimbotTracer()
        local target = _G.PulseCurrentAimbotTarget or (_G.PulseNormalAimbot and _G.PulseNormalAimbot.target)
        if target and typeof(target) == "Instance" and target:IsA("Player") and target.Character then
            local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
            local cam = Workspace.CurrentCamera
            if targetHrp and cam then
                local screenPos, onScreen = cam:WorldToViewportPoint(targetHrp.Position)
                if not aimbotTracerLine then
                    aimbotTracerLine = Instance.new("Frame")
                    aimbotTracerLine.Name = "AimbotTracerLine"
                    aimbotTracerLine.BackgroundColor3 = (_G.PulseGetAccentColor and _G.PulseGetAccentColor())
                        or Color3.fromRGB(255, 60, 172)
                    aimbotTracerLine.BorderSizePixel = 0
                    aimbotTracerLine.AnchorPoint = Vector2.new(0.5, 0.5)
                    aimbotTracerLine.ZIndex = 50
                    aimbotTracerLine.Parent = PlayerGui:FindFirstChild("PulseHubMobileButtons") or Gui
                end
                local startX, startY = cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.92
                local endX, endY = screenPos.X, screenPos.Y
                if not onScreen then
                    local dir = (Vector2.new(endX, endY) - Vector2.new(
                        cam.ViewportSize.X * 0.5,
                        cam.ViewportSize.Y * 0.5
                    )).Unit
                    endX = math.clamp(
                        cam.ViewportSize.X * 0.5 + dir.X * (cam.ViewportSize.X * 0.44),
                        20,
                        cam.ViewportSize.X - 20
                    )
                    endY = math.clamp(
                        cam.ViewportSize.Y * 0.5 + dir.Y * (cam.ViewportSize.Y * 0.44),
                        20,
                        cam.ViewportSize.Y - 20
                    )
                end
                local dist = math.sqrt((endX - startX) ^ 2 + (endY - startY) ^ 2)
                local angle = math.atan2(endY - startY, endX - startX)
                aimbotTracerLine.Size = UDim2.new(0, dist, 0, 1.5)
                aimbotTracerLine.Position = UDim2.new(0, (startX + endX) * 0.5, 0, (startY + endY) * 0.5)
                aimbotTracerLine.Rotation = math.deg(angle)
                aimbotTracerLine.BackgroundColor3 = (_G.PulseGetAccentColor and _G.PulseGetAccentColor())
                    or Color3.fromRGB(255, 60, 172)
                aimbotTracerLine.Visible = true
                return
            end
        end
        if aimbotTracerLine then
            aimbotTracerLine.Visible = false
        end
    end
    RunService.RenderStepped:Connect(updateAimbotTracer)
    local resetHolder = Instance.new("Frame")
    resetHolder.Name = "Reset All Settings Holder"
    resetHolder.BackgroundTransparency = 1
    resetHolder.BorderSizePixel = 0
    resetHolder.Size = UDim2.new(1, -4, 0, 44)
    resetHolder.LayoutOrder = 1000
    resetHolder.ZIndex = 5
    resetHolder.Parent = Settings
    local resetBtn = Instance.new("TextButton")
    resetBtn.Name = "Reset All Settings"
    resetBtn.BackgroundColor3 = Color3.fromRGB(232, 232, 238)
    resetBtn.BackgroundTransparency = 0
    resetBtn.BorderSizePixel = 0
    resetBtn.Text = "Reset All Settings"
    resetBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    resetBtn.TextStrokeTransparency = 1
    resetBtn.TextSize = 12
    resetBtn.Font = Enum.Font.GothamBlack
    resetBtn.AutoButtonColor = false
    resetBtn.Size = UDim2.new(1, -16, 0, 42)
    resetBtn.Position = UDim2.new(0, 8, 0, 1)
    resetBtn.ZIndex = 6
    resetBtn.Parent = resetHolder
    corner(resetBtn, 10)
    local resetStroke = Instance.new("UIStroke")
    resetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    resetStroke.Color = Color3.fromRGB(255, 255, 255)
    resetStroke.Thickness = 1
    resetStroke.Transparency = 0.12
    resetStroke.Parent = resetBtn
    local resetDefaultBg = Color3.fromRGB(232, 232, 238)
    local resetHoverBg = Color3.fromRGB(245, 245, 250)
    local resetDoneBg = Color3.fromRGB(28, 40, 30)
    local resetDefaultText = Color3.fromRGB(0, 0, 0)
    local resetDoneText = Color3.fromRGB(140, 230, 160)
    local function doResetAllSettings()
        resetBtn.Text = "RESETTING..."
        pcall(function()
            local files = {
                CONFIG_FILE,
                KEYBINDS_CONFIG_FILE,
                "PulseHub_MainGUI_Config.json",
                "PulseHubConfig.json",
                "PulseHub_Settings.json",
                "PulseHub_Keybinds.json",
                "PulseHub_GUI.json",
                "BrokenHub_MainGUI_Config_DefaultsV2.json",
                "BrokenHub_Keybinds_DefaultsV2.json",
                "BrokenHub_MainGUI_Config.json",
                "BrokenHubConfig.json",
                "BrokenHub_Settings.json",
                "BrokenHub_Keybinds.json",
                "BrokenHub_GUI.json",
            }
            for _, fname in ipairs(files) do
                pcall(function()
                    if fname and isfile and isfile(fname) and delfile then
                        delfile(fname)
                    end
                end)
            end
        end)
        pcall(function()
            pulseGuiScaleValue = 0.52
            pulseProgressBarScaleValue = 0.83
            NS = 62
            CS = 29.7
            LAGGER_SPEED = 40
            LAGGER_CARRY_SPEED = 20
            LAGGER2_SPEED = 30
            LAGGER2_CARRY_SPEED = 15
            AUTO_CARRY_BRAINROT_DISTANCE = 5
            _G.PulseAutoSwitchDistance = 5
            if autoSwitchDistanceBox then
                autoSwitchDistanceBox.Text = "5"
            end
            currentSpeedMode = "Normal"
            autoCarrySpeedEnabled = false
            autoTPHeight = 20
            if _G.PulseSemiRagdollStealController and _G.PulseSemiRagdollStealController.active then
                _G.PulseSemiRagdollStealController.cancel()
            end
            _G.PulseSemiRagdollStealEnabled = false
            if _G.PulseSetSemiRagdollStealVisual then
                _G.PulseSetSemiRagdollStealVisual(false)
            end
            if _G.PulseRefreshSemiRagdollStealRow then
                _G.PulseRefreshSemiRagdollStealRow()
            end
            _G.PulseNormalRagdollStealEnabled = false
            if _G.PulseSetNormalRagdollStealVisual then
                _G.PulseSetNormalRagdollStealVisual(false)
            end
            if _G.PulseRefreshNormalRagdollStealRow then
                _G.PulseRefreshNormalRagdollStealRow()
            end
            if _G.PulseNormalAutoStealRagdollPause and _G.PulseNormalAutoStealRagdollPause.cancel then
                _G.PulseNormalAutoStealRagdollPause.cancel(false)
            end
            autoStealEnabled = false
            softStealEnabled = false
            _G.PulseSoftStealEnabled = false
            if setSoftStealVisual then
                setSoftStealVisual(false)
            end
            selectedStealMode = "Normal"
            autoStealRadius = 62
            _G.PulseStealRadii = { Normal = 62, Semi = 9, ["Normal V2"] = 62 }
            selectedAnimationPack = "OFF"
            selectedAimbotMode = "Anti Bypass"
            AIMBOT_SPEED = 58
            LAGGER_AIMBOT_SPEED = 40
            _G.PulseAntiBypassAimbotSpeed = 58
            _G.PulseAntiBypassLaggerAimbotSpeed = 40
            ANTI_DESYNC_AIMBOT_SPEED = 58
            autoSwingEnabled = false
            antiDesyncAutoSwingEnabled = false
            _G.PulseNormalAimbotOn = false
            _G.PulseAntiBypassAimbotOn = false
            _G.PulseAntiDesyncAimbotOn = false
            antiRagdollEnabled = false
            infJumpEnabled = false
            autoTPEnabled = false
            _G.PulseAutoRagdollTpState.enabled = false
            if _G.PulseStopHoldInfJump then
                _G.PulseStopHoldInfJump()
            end
            antiRagdollMode = "Splatter"
            if setAntiRagdollModeRow then
                setAntiRagdollModeRow("Splatter")
            end
            mobileButtonStyle = "Button 2"
            if setMobileButtonStyleRow then
                setMobileButtonStyleRow("Button 2")
            end
            batCounterEnabled = false
            medCounterEnabled = false
            espEnabled = false
            showTracerEnabled = false
            ragdollCountdownEnabled = false
            fpsBoostEnabled = false
            antiLagVisualEnabled = false
            fovEnabled = false
            fovValue = 70
            noCamCollisionEnabled = false
            _G.PulseNoPlayerCollisionEnabled = false
            skyTheme = "Off"
            currentBackground = 0
            currentBackgroundColor = nil
            selectedIntroMusic = 1
            _introEnabled = true
            if setIntroVisual then
                setIntroVisual(_introEnabled)
            end
            if setIntroSongVisual then
                setIntroSongVisual()
            end
            stopIntroPlayback()
            stopIntroPreview()
            autoLeftEnabled = false
            autoRightEnabled = false
            _G.PulseLaggerCycleOrder = { "Lagger Carry", "Lagger Carry 2", "Lagger", "Lagger 2" }
            _G.PulseGuiLocked = false
            _G.PulseHideMobileButtons = false
            _G.PulseMobileButtonScale = 0.75
            _G.PulseMobileButtonColors = _G.PulseDefaultMobileButtonColors()
            _G.PulseMobileButtonOrder = _G.PulseCopyDefaultMobileButtonOrder()
            _G.PulseMobileButtonHidden = {}
            _G.PulseMobileButtonPositions = {}
            if _G.PulseMobileColorEditorRefresh then
                _G.PulseMobileColorEditorRefresh()
            end
            if _G.PulseMobileEditorRefresh then
                _G.PulseMobileEditorRefresh()
            end
            pulseMainScale.Scale = pulseGuiScaleValue
            applyPulseProgressBarScale()
            applyBackground(0)
            if updateBackgroundColorButtons then
                updateBackgroundColorButtons()
            end
            applyDefaultPulseKeybinds()
            refreshAllSpeedKeybinds()
            refreshTPDownKeybind()
            if stopAutoTP then
                stopAutoTP()
            end
            if stopAntiRagdoll then
                stopAntiRagdoll()
            end
            if _G.PulseAutoRagdollTpState.stop then
                _G.PulseAutoRagdollTpState.stop()
            end
            if normalSpeedBox then
                normalSpeedBox.Text = tostring(NS)
            end
            if carrySpeedBox then
                carrySpeedBox.Text = tostring(CS)
            end
            if laggerSpeedBox then
                laggerSpeedBox.Text = tostring(LAGGER_SPEED)
            end
            if laggerCarrySpeedBox then
                laggerCarrySpeedBox.Text = tostring(LAGGER_CARRY_SPEED)
            end
            if lagger2SpeedBox then
                lagger2SpeedBox.Text = tostring(LAGGER2_SPEED)
            end
            if lagger2CarrySpeedBox then
                lagger2CarrySpeedBox.Text = tostring(LAGGER2_CARRY_SPEED)
            end
            if autoTPHeightBox then
                autoTPHeightBox.Text = tostring(autoTPHeight)
            end
            if radiusBox then
                radiusBox.Text = tostring(autoStealRadius)
            end
            if _G.PulseRefreshAimbotSpeedBoxes then
                _G.PulseRefreshAimbotSpeedBoxes()
            end
            if type(applyCustomSky) == "function" then
                applyCustomSky("Off")
            end
            if skyValueLabel then
                skyValueLabel.Text = "Off"
            end
            if _G.PulseResetMobileButtons then
                _G.PulseResetMobileButtons()
            end
            pcall(function()
                local vb = mobileButtonsSizeStepperRow and mobileButtonsSizeStepperRow:FindFirstChild("Value")
                if vb then
                    vb.Text = string.format("%.2f", 0.75)
                end
            end)
            if _G.PulseHubApplySavedGameplayStates then
                _G.PulseHubApplySavedGameplayStates()
            end
            savePulseConfig()
        end)
        task.wait(0.35)
        resetBtn.Text = "DONE - REJOINING..."
        resetBtn.TextColor3 = resetDoneText
        tween(resetBtn, { BackgroundColor3 = resetDoneBg }, 0.18)
        tween(resetStroke, { Color = resetDoneText, Transparency = 0.02, Thickness = 1.4 }, 0.18)
        task.wait(0.6)
        pcall(function()
            local TeleportService = game:GetService("TeleportService")
            TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
        end)
    end
    resetBtn.Text = "RESET ALL SETTINGS"
    resetBtn.MouseEnter:Connect(function()
        tween(resetBtn, { BackgroundColor3 = resetHoverBg }, 0.12)
    end)
    resetBtn.MouseLeave:Connect(function()
        tween(resetBtn, { BackgroundColor3 = resetDefaultBg }, 0.12)
    end)
    resetBtn.MouseButton1Click:Connect(function()
        showPulseConfirmDialog("Are you sure you would like to reset your settings?", function()
            doResetAllSettings()
        end)
    end)
end
task.wait()
_G.__PulseHubSetupSettingsUI()
if PulseUpdateGuiLockVisual then
    PulseUpdateGuiLockVisual()
end
if _G.PulseApplyMobileButtonsHidden then
    _G.PulseApplyMobileButtonsHidden()
end
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    local isControllerInput = tostring(input.UserInputType):find("Gamepad") ~= nil
    if
        gameProcessed
        and input.UserInputType == Enum.UserInputType.Keyboard
        and not listeningForSpeedKey
        and not listeningForTPDownKey
    then
        return
    end
    if UserInputService:GetFocusedTextBox() then
        return
    end
    if input.UserInputType ~= Enum.UserInputType.Keyboard and not isControllerInput then
        return
    end
    if input.KeyCode == Enum.KeyCode.Unknown then
        return
    end
    if speedKeybinds.ToggleUI and input.KeyCode == speedKeybinds.ToggleUI then
        if Main.Visible then
            Main.Visible = false
            MiniFrame.Visible = true
        else
            Main.Visible = true
            MiniFrame.Visible = false
            Main.Size = FULL_MAIN_SIZE
        end
        savePulseConfig()
        return
    end
    if listeningForSpeedKey then
        if tick() - (keybindListenStartedAt or 0) < 0.18 then
            return
        end
        local targetKey = listeningForSpeedKey
        if input.KeyCode == Enum.KeyCode.Escape then
            listeningForSpeedKey = nil
            refreshAllSpeedKeybinds()
            return
        end
        if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
            speedKeybinds[targetKey] = nil
        else
            for otherKeyId, boundKey in pairs(speedKeybinds) do
                if otherKeyId ~= targetKey and boundKey == input.KeyCode then
                    speedKeybinds[otherKeyId] = nil
                end
            end
            if tpDownKeybind == input.KeyCode then
                tpDownKeybind = nil
                refreshTPDownKeybind()
            end
            speedKeybinds[targetKey] = input.KeyCode
        end
        listeningForSpeedKey = nil
        refreshAllSpeedKeybinds()
        savePulseConfig()
        return
    end
    if listeningForTPDownKey then
        if tick() - (keybindListenStartedAt or 0) < 0.18 then
            return
        end
        if input.KeyCode == Enum.KeyCode.Escape then
            listeningForTPDownKey = false
            refreshTPDownKeybind()
            return
        end
        if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
            tpDownKeybind = nil
        else
            for keyId, boundKey in pairs(speedKeybinds) do
                if boundKey == input.KeyCode then
                    speedKeybinds[keyId] = nil
                end
            end
            tpDownKeybind = input.KeyCode
        end
        listeningForTPDownKey = false
        refreshAllSpeedKeybinds()
        refreshTPDownKeybind()
        savePulseConfig()
        return
    end
    if speedKeybinds.SpeedToggle and input.KeyCode == speedKeybinds.SpeedToggle then
        toggleCarryMode()
        return
    end
    if speedKeybinds.LaggerToggle and input.KeyCode == speedKeybinds.LaggerToggle then
        cycleLaggerMode()
        return
    end
    if speedKeybinds.Aimbot and input.KeyCode == speedKeybinds.Aimbot then
        if _G.PulseToggleSelectedAimbot then
            _G.PulseToggleSelectedAimbot()
        elseif _G.PulseStartAntiBypassAimbot and _G.PulseStopAntiBypassAimbot then
            if _G.PulseAntiBypassAimbotOn then
                _G.PulseStopAntiBypassAimbot()
            else
                _G.PulseStartAntiBypassAimbot()
            end
        end
        if _G.PulseRefreshAimbotVisual then
            _G.PulseRefreshAimbotVisual()
        end
        return
    end
    if speedKeybinds.AntiDesyncAimbot and input.KeyCode == speedKeybinds.AntiDesyncAimbot then
        if _G.PulseToggleAntiDesyncAimbot then
            _G.PulseToggleAntiDesyncAimbot()
        elseif _G.PulseStartAntiDesyncAimbot and _G.PulseStopAntiDesyncAimbot then
            if _G.PulseAntiDesyncAimbotOn then
                _G.PulseStopAntiDesyncAimbot()
            else
                _G.PulseStartAntiDesyncAimbot()
            end
        end
        return
    end
    if speedKeybinds.DropBrainrot and input.KeyCode == speedKeybinds.DropBrainrot then
        runDropBrainrot()
        return
    end
    if speedKeybinds.AutoLeft and input.KeyCode == speedKeybinds.AutoLeft then
        if _G.PulseSetAutoLeft then
            _G.PulseSetAutoLeft(not autoLeftEnabled)
        end
        return
    end
    if speedKeybinds.AutoRight and input.KeyCode == speedKeybinds.AutoRight then
        if _G.PulseSetAutoRight then
            _G.PulseSetAutoRight(not autoRightEnabled)
        end
        return
    end
    if speedKeybinds.InstantReset and input.KeyCode == speedKeybinds.InstantReset then
        if _G.PulseCursedInstaReset then
            _G.PulseCursedInstaReset()
        end
        return
    end
    if tpDownKeybind and input.KeyCode == tpDownKeybind then
        runTPFloor()
        return
    end
end)
setTab("BINDS")
_G.__PulseHubSetupStealBar = function()
    local RS = RunService
    local UIS = UserInputService
    local TS = TweenService
    local existingStealBar = LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild("StealBarGui")
    if existingStealBar then
        existingStealBar:Destroy()
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "StealBarGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui
    local C = {
        bg = Color3.fromRGB(10, 10, 10),
        stroke = Color3.fromRGB(255, 255, 255),
        white = Color3.fromRGB(255, 255, 255),
        grey = Color3.fromRGB(170, 170, 170),
        track = Color3.fromRGB(42, 42, 42),
        dotBg = Color3.fromRGB(85, 85, 85),
    }
    local ITALIC = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)
    local main = Instance.new("Frame")
    main.Name = "StealBar"
    main.Size = UDim2.fromOffset(320, 70)
    main.Position = tableToUDim2(savedStealBarPositionTable, UDim2.new(0.5, 0, 1, -80))
    main.AnchorPoint = Vector2.new(0.5, 1)
    main.BackgroundColor3 = C.bg
    main.BorderSizePixel = 0
    main.Active = true
    main.ClipsDescendants = true
    main.ZIndex = 5
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke")
    stroke.Color = C.stroke
    stroke.Thickness = 1.5
    stroke.Parent = main
    local pbScale = Instance.new("UIScale")
    pbScale.Name = "PulseProgressBarScale"
    pbScale.Scale = pulseProgressBarScaleValue or 1
    pbScale.Parent = main
    local function drag(frame)
        local dragging, dragStart, startPos = false, nil, nil
        frame.InputBegan:Connect(function(input)
            if _G.PulseGuiLocked == true then
                return
            end
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        savedStealBarPositionTable = udim2ToTable(frame.Position)
                        task.defer(function()
                            pcall(savePulseConfig)
                        end)
                    end
                end)
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if
                dragging
                and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                )
            then
                local d = input.Position - dragStart
                frame.Position =
                    UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
    end
    drag(main)
    local dotBg = Instance.new("Frame")
    dotBg.Size = UDim2.fromOffset(20, 20)
    dotBg.Position = UDim2.fromOffset(10, 7)
    dotBg.BackgroundColor3 = C.dotBg
    dotBg.BorderSizePixel = 0
    dotBg.ZIndex = 6
    dotBg.Parent = main
    Instance.new("UICorner", dotBg).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(8, 8)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.fromScale(0.5, 0.5)
    dot.BackgroundColor3 = C.white
    dot.BorderSizePixel = 0
    dot.ZIndex = 7
    dot.Parent = dotBg
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local pctLbl = Instance.new("TextLabel")
    pctLbl.BackgroundTransparency = 1
    pctLbl.Position = UDim2.fromOffset(36, 4)
    pctLbl.Size = UDim2.fromOffset(100, 22)
    pctLbl.FontFace = ITALIC
    pctLbl.TextSize = 18
    pctLbl.TextColor3 = C.white
    pctLbl.TextXAlignment = Enum.TextXAlignment.Left
    pctLbl.Text = "0%"
    pctLbl.ZIndex = 6
    pctLbl.Parent = main
    local radiusLbl = Instance.new("TextLabel")
    radiusLbl.BackgroundTransparency = 1
    radiusLbl.AnchorPoint = Vector2.new(1, 0)
    radiusLbl.Position = UDim2.new(1, -10, 0, 4)
    radiusLbl.Size = UDim2.fromOffset(120, 22)
    radiusLbl.FontFace = ITALIC
    radiusLbl.TextSize = 16
    radiusLbl.TextColor3 = C.white
    radiusLbl.TextXAlignment = Enum.TextXAlignment.Right
    radiusLbl.Text = "Radius: " .. string.format("%g", tonumber(autoStealRadius) or 0)
    radiusLbl.ZIndex = 6
    radiusLbl.Parent = main
    local infoLbl = Instance.new("TextLabel")
    infoLbl.BackgroundTransparency = 1
    infoLbl.Position = UDim2.fromOffset(0, 28)
    infoLbl.Size = UDim2.new(1, 0, 0, 16)
    infoLbl.Font = Enum.Font.GothamBold
    infoLbl.TextSize = 11
    infoLbl.TextColor3 = C.grey
    infoLbl.Text = "FPS: 0 · PING: 0ms · discord.gg/pulsee"
    infoLbl.ZIndex = 6
    infoLbl.Parent = main
    local track = Instance.new("Frame")
    track.Position = UDim2.new(0, 10, 1, -20)
    track.Size = UDim2.new(1, -20, 0, 14)
    track.BackgroundColor3 = C.track
    track.BorderSizePixel = 0
    track.ClipsDescendants = true
    track.ZIndex = 6
    track.Parent = main
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = C.white
    fill.BorderSizePixel = 0
    fill.ZIndex = 6
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(120, 120, 120)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(120, 120, 120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20)),
    })
    grad.Parent = fill
    local shimmerThread = nil
    local function startShimmer()
        if shimmerThread then
            return
        end
        shimmerThread = task.spawn(function()
            while shimmerThread ~= nil and main.Parent and grad.Parent do
                pcall(function()
                    local fw = TS:Create(
                        grad,
                        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        { Offset = Vector2.new(0.5, 0) }
                    )
                    fw:Play()
                    fw.Completed:Wait()
                end)
                if shimmerThread == nil or not main.Parent or not grad.Parent then
                    break
                end
                pcall(function()
                    local bk = TS:Create(
                        grad,
                        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        { Offset = Vector2.new(-0.5, 0) }
                    )
                    bk:Play()
                    bk.Completed:Wait()
                end)
            end
            if not main.Parent or not grad.Parent then
                shimmerThread = nil
            end
        end)
    end
    local function stopShimmer()
        if shimmerThread then
            task.cancel(shimmerThread)
            shimmerThread = nil
        end
    end
    startShimmer()
    local frameCount = 0
    local timeAccum = 0
    if _G.PulseStealBarStatsConn then
        pcall(function()
            _G.PulseStealBarStatsConn:Disconnect()
        end)
    end
    _G.PulseStealBarStatsConn = RS.RenderStepped:Connect(function(delta)
        frameCount = frameCount + 1
        timeAccum = timeAccum + delta
        if timeAccum >= 0.5 then
            local fps = math.floor(frameCount / timeAccum + 0.5)
            frameCount = 0
            timeAccum = 0
            local ping = 0
            pcall(function()
                ping = math.floor(LP:GetNetworkPing() * 1000 + 0.5)
            end)
            if infoLbl and infoLbl.Parent then
                infoLbl.Text = ("FPS: %d · PING: %dms · discord.gg/pulsee"):format(fps, ping)
            end
            local r = tonumber(autoStealRadius) or 0
            if radiusLbl and radiusLbl.Parent then
                radiusLbl.Text = "Radius: " .. string.format("%g", r)
            end
        end
    end)
    local StealBar = {}
    function StealBar.SetProgress(p)
        p = math.clamp(tonumber(p) or 0, 0, 1)
        fill.Size = UDim2.fromScale(p, 1)
        pctLbl.Text = math.floor(p * 100 + 0.5) .. "%"
        if p > 0 then
            stopShimmer()
        else
            startShimmer()
        end
    end
    function StealBar.Reset()
        StealBar.SetProgress(0)
        StealBar.SetState("IDLE")
    end
    function StealBar.SetState(state)
        if state == "STEALING" then
            dot.BackgroundColor3 = C.white
            stroke.Transparency = 0
        elseif state == "READY" then
            dot.BackgroundColor3 = C.grey
            stroke.Transparency = 0.3
        else
            dot.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
            stroke.Transparency = 0.45
        end
    end
    StealBar.SetState("IDLE")
    _G.StealBar = StealBar
end
_G.__PulseHubSetupStealBar()
if _G.PulseAutoStealSync then
    task.defer(_G.PulseAutoStealSync)
end
_G.__PulseHubSetupMinimizeToggle = function()
    _G.__PulseHubMinimized = false
    Close.MouseButton1Click:Connect(function()
        _G.__PulseHubMinimized = not _G.__PulseHubMinimized
        if _G.__PulseHubMinimized then
            Main.Visible = false
            MiniFrame.Visible = true
        else
            Main.Visible = true
            MiniFrame.Visible = false
            Main.Size = FULL_MAIN_SIZE
        end
        savePulseConfig()
    end)
end
_G.__PulseHubSetupMinimizeToggle()
_G.__PulseHubRunIntro = function()
    local TS = TweenService
    local introGuiParent = Gui and Gui.Parent or PlayerGui
    local origSize = FULL_MAIN_SIZE or Main.Size
    local wasMinimizedBeforeIntro = (_G.__PulseHubMinimized == true)
    _G.PulseIntroInProgress = (_introEnabled == true)
    if not _introEnabled then
        _G.PulseIntroInProgress = false
        _G.PulseIntroFinished = true
        pcall(function()
            local bootstrap = _G.PulseIntroBootstrapGui or PlayerGui:FindFirstChild("PulseHubIntroBootstrap")
            if bootstrap then
                bootstrap:Destroy()
            end
            _G.PulseIntroBootstrapGui = nil
        end)
        stopIntroPlayback()
        stopIntroPreview()
        Main.Size = origSize
        if not wasMinimizedBeforeIntro then
            Main.Visible = true
            MiniFrame.Visible = false
        else
            Main.Visible = false
            MiniFrame.Visible = true
        end
        revealOverheadExtras()
        if _G.PulseApplyMobileButtonsHidden then
            _G.PulseApplyMobileButtonsHidden()
        end
        return
    end
    playIntroMusic()
    Main.Visible = false
    MiniFrame.Visible = false
    Main.Size = UDim2.new(0, 0, 0, 0)
    task.spawn(function()
        local DARKER_BG = Color3.fromRGB(5, 5, 8)
        local WHITE = Color3.fromRGB(255, 255, 255)
        local TRAIL_COLOR = Color3.fromRGB(205, 215, 235)
        local function applyProps(inst, props)
            for k, v in pairs(props) do
                if k ~= "Parent" then
                    inst[k] = v
                end
            end
            if props.Parent then
                inst.Parent = props.Parent
            end
            return inst
        end
        local function new(class, props)
            return applyProps(Instance.new(class), props)
        end
        local function tween(obj, duration, props, style, dir)
            local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
            local t = TS:Create(obj, info, props)
            t:Play()
            return t
        end
        local introGui = new(
            "ScreenGui",
            {
                Name = "PulseHubIntro",
                IgnoreGuiInset = true,
                ResetOnSpawn = false,
                DisplayOrder = 100,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            }
        )
        pcall(function()
            if syn and syn.protect_gui then
                syn.protect_gui(introGui)
            end
        end)
        introGui.Parent = introGuiParent
        pcall(function()
            local bootstrap = _G.PulseIntroBootstrapGui or PlayerGui:FindFirstChild("PulseHubIntroBootstrap")
            if bootstrap then
                bootstrap:Destroy()
            end
            _G.PulseIntroBootstrapGui = nil
        end)
        local Intro = new(
            "Frame",
            {
                Name = "Intro",
                ZIndex = 1000,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = DARKER_BG,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Parent = introGui,
            }
        )
        local IntroBackdropImage = new(
            "ImageLabel",
            {
                Name = "IntroBackdropImage",
                Visible = false,
                ZIndex = 1000,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.42, 0),
                Size = UDim2.new(0.92, 0, 0.5, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://98541566010518",
                ImageTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                Parent = Intro,
            }
        )
        new("UIScale", { Parent = IntroBackdropImage })
        local ChainSpearStage = new(
            "Frame",
            {
                Name = "ChainSpearStage",
                ZIndex = 1000,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.42, 0),
                Size = UDim2.new(0.64, 0, 0.64, 0),
                BackgroundTransparency = 1,
                Parent = Intro,
            }
        )
        new("UIAspectRatioConstraint", { Parent = ChainSpearStage })
        new(
            "UISizeConstraint",
            { MinSize = Vector2.new(200, 200), MaxSize = Vector2.new(280, 280), Parent = ChainSpearStage }
        )
        local rotorData = {
            { rot = -1094.822, trans = 0.998 },
            { rot = -1095.4, trans = 0.998 },
            { rot = -1095.978, trans = 0.996 },
            { rot = -1096.515, trans = 0.995 },
            { rot = -1097.052, trans = 0.993 },
            { rot = -1097.548, trans = 0.991 },
            { rot = -1098.004, trans = 0.988 },
            { rot = -1098.419, trans = 0.985 },
            { rot = -1098.794, trans = 0.982 },
            { rot = -1099.128, trans = 0.978 },
            { rot = -1099.421, trans = 0.973 },
        }
        for i, data in ipairs(rotorData) do
            local rotor = new(
                "Frame",
                {
                    Name = "ChainSpearRotor" .. i,
                    ZIndex = 1000,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Rotation = data.rot,
                    Parent = ChainSpearStage,
                }
            )
            new(
                "ImageLabel",
                {
                    Name = "ChainSpearTrail" .. i,
                    ZIndex = 1000,
                    AnchorPoint = Vector2.new(0.73, 0.02),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0.553, 0, 0.829, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://118963313877514",
                    ImageColor3 = TRAIL_COLOR,
                    ImageTransparency = data.trans,
                    ScaleType = Enum.ScaleType.Fit,
                    Parent = rotor,
                }
            )
        end
        local TojiCutoutStage = new(
            "Frame",
            {
                Name = "TojiCutoutStage",
                Visible = false,
                ZIndex = 1000,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.42, 0),
                Size = UDim2.new(0.76, 0, 0, 312),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Rotation = -2,
                Parent = Intro,
            }
        )
        new("UIScale", { Parent = TojiCutoutStage })
        new(
            "ImageLabel",
            {
                Name = "TojiPantsWhiteFill",
                ZIndex = 998,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://82757811555212",
                ImageTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                Parent = TojiCutoutStage,
            }
        )
        local tojiPieceImages = {
            "rbxassetid://130451097419605",
            "rbxassetid://129030262345273",
            "rbxassetid://76292842640935",
            "rbxassetid://82757811555212",
            "rbxassetid://92910922537368",
            "rbxassetid://105960347086002",
            "rbxassetid://116720305084998",
            "rbxassetid://90341354549871",
            "rbxassetid://72399600208480",
            "rbxassetid://81834484116440",
        }
        local seamOffsets = { { x = -1, y = 0 }, { x = 1, y = 0 }, { x = 0, y = -1 }, { x = 0, y = 1 } }
        for i, imageId in ipairs(tojiPieceImages) do
            for j, offset in ipairs(seamOffsets) do
                new(
                    "ImageLabel",
                    {
                        Name = "TojiSeamFill" .. i,
                        ZIndex = 999,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, offset.x, 0.5, offset.y),
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Image = imageId,
                        ImageColor3 = DARKER_BG,
                        ImageTransparency = 1,
                        ScaleType = Enum.ScaleType.Fit,
                        Parent = TojiCutoutStage,
                    }
                )
            end
            new(
                "ImageLabel",
                {
                    Name = "TojiPiece" .. i,
                    ZIndex = 1000,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = imageId,
                    ImageTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit,
                    Parent = TojiCutoutStage,
                }
            )
            if i == 2 then
                local shine = new(
                    "ImageLabel",
                    {
                        Name = "TojiSwordShine",
                        ZIndex = 1001,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Image = imageId,
                        ImageTransparency = 1,
                        ScaleType = Enum.ScaleType.Fit,
                        Parent = TojiCutoutStage,
                    }
                )
                new(
                    "UIGradient",
                    {
                        Rotation = -25,
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1, 0),
                            NumberSequenceKeypoint.new(0.5, 0.14, 0),
                            NumberSequenceKeypoint.new(1, 1, 0),
                        }),
                        Parent = shine,
                    }
                )
            end
            if i == 6 then
                for k = 1, 4 do
                    new(
                        "ImageLabel",
                        {
                            Name = "TojiMovingHandWhiteFill" .. (k > 1 and k or ""),
                            ZIndex = 998,
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.new(0.5, seamOffsets[k].x, 0.5, seamOffsets[k].y),
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Image = imageId,
                            ImageColor3 = WHITE,
                            ImageTransparency = 1,
                            ScaleType = Enum.ScaleType.Fit,
                            Parent = TojiCutoutStage,
                        }
                    )
                end
            end
        end
        new(
            "TextLabel",
            {
                Name = "IntroBanner",
                ZIndex = 1002,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.42, 0),
                Size = UDim2.new(0.38, 0, 0, 78),
                BackgroundTransparency = 1,
                Text = "PULSE",
                TextColor3 = WHITE,
                TextSize = 42,
                Font = Enum.Font.GothamBlack,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                TextStrokeTransparency = 0.55,
                Parent = Intro,
            }
        )
        new(
            "TextLabel",
            {
                Name = "TapAnywhere",
                ZIndex = 1003,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.42, 58),
                Size = UDim2.new(0.7, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = "TAP ANYWHERE TO SKIP",
                TextColor3 = WHITE,
                TextSize = 11,
                Font = Enum.Font.GothamBlack,
                Parent = Intro,
            }
        )
        new(
            "TextLabel",
            {
                Name = "DiscordInvite",
                ZIndex = 1003,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.42, 80),
                Size = UDim2.new(0.7, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = "discord.gg/pulsee",
                TextColor3 = WHITE,
                TextSize = 10,
                Font = Enum.Font.GothamBlack,
                Parent = Intro,
            }
        )
        local IntroCaptionShield = new(
            "Frame",
            {
                Name = "IntroCaptionShield",
                Visible = false,
                ZIndex = 1002,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.42, 70),
                Size = UDim2.new(0.58, 0, 0, 48),
                BackgroundColor3 = DARKER_BG,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                Parent = Intro,
            }
        )
        new("UICorner", { CornerRadius = UDim.new(0, 14), Parent = IntroCaptionShield })
        new(
            "UIGradient",
            {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.94, 0),
                    NumberSequenceKeypoint.new(0.16, 0.14, 0),
                    NumberSequenceKeypoint.new(0.84, 0.14, 0),
                    NumberSequenceKeypoint.new(1, 0.94, 0),
                }),
                Parent = IntroCaptionShield,
            }
        )
        local TapCatcher = new(
            "TextButton",
            {
                Name = "TapCatcher",
                ZIndex = 1004,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Parent = Intro,
            }
        )
        local TapAnywhere = Intro:FindFirstChild("TapAnywhere")
        local introSkipped = false
        local function skipIntro()
            if introSkipped then
                return
            end
            introSkipped = true
            stopIntroPlayback()
            tween(Intro, 0.4, { BackgroundTransparency = 1 })
            for _, child in ipairs(Intro:GetChildren()) do
                if child:IsA("ImageLabel") then
                    tween(child, 0.3, { ImageTransparency = 1 })
                elseif child:IsA("TextLabel") then
                    tween(child, 0.3, { TextTransparency = 1 })
                elseif child:IsA("Frame") then
                    tween(child, 0.3, { BackgroundTransparency = 1 })
                    for _, sub in ipairs(child:GetDescendants()) do
                        if sub:IsA("ImageLabel") then
                            tween(sub, 0.3, { ImageTransparency = 1 })
                        end
                    end
                end
            end
            MiniFrame.Visible = false
            Main.Visible = true
            revealOverheadExtras()
            _G.PulseIntroInProgress = false
            _G.PulseIntroFinished = true
            if _G.PulseApplyMobileButtonsHidden then
                _G.PulseApplyMobileButtonsHidden()
            end
            pcall(function()
                TS
                    :Create(
                        Main,
                        TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                        { Size = origSize }
                    )
                    :Play()
            end)
            task.delay(0.5, function()
                pcall(function()
                    if introGui then
                        introGui:Destroy()
                    end
                end)
            end)
        end
        TapCatcher.MouseButton1Click:Connect(skipIntro)
        task.spawn(function()
            task.wait(0.2)
            if introSkipped then
                return
            end
            IntroBackdropImage.Visible = true
            tween(IntroBackdropImage, 0.8, { ImageTransparency = 0.3 })
            for i, rotor in ipairs(ChainSpearStage:GetChildren()) do
                if rotor:IsA("Frame") and rotor.Name:match("ChainSpearRotor") then
                    local trail = rotor:FindFirstChildWhichIsA("ImageLabel")
                    if trail then
                        task.delay(i * 0.04, function()
                            if introSkipped then
                                return
                            end
                            tween(trail, 0.5, { ImageTransparency = 0.15 })
                        end)
                    end
                    task.spawn(function()
                        local speed = 0.4 + (i * 0.05)
                        while not introSkipped do
                            rotor.Rotation = rotor.Rotation + speed
                            RunService.Heartbeat:Wait()
                        end
                    end)
                end
            end
            task.wait(0.6)
            if introSkipped then
                return
            end
            TojiCutoutStage.Visible = true
            local tojiScale = TojiCutoutStage:FindFirstChild("UIScale")
            if tojiScale then
                tojiScale.Scale = 0.85
                tween(tojiScale, 0.6, { Scale = 1 }, Enum.EasingStyle.Back)
            end
            for i = 1, 10 do
                if introSkipped then
                    return
                end
                local piece = TojiCutoutStage:FindFirstChild("TojiPiece" .. i)
                if piece then
                    tween(piece, 0.25, { ImageTransparency = 0 })
                end
                for _, child in ipairs(TojiCutoutStage:GetChildren()) do
                    if child.Name == "TojiSeamFill" .. i then
                        tween(child, 0.25, { ImageTransparency = 0 })
                    end
                end
                task.wait(0.08)
            end
            task.wait(0.3)
            if introSkipped then
                return
            end
            local shine = TojiCutoutStage:FindFirstChild("TojiSwordShine")
            if shine then
                tween(shine, 0.4, { ImageTransparency = 0.2 })
                task.wait(0.3)
                if not introSkipped then
                    tween(shine, 0.3, { ImageTransparency = 0.7 })
                end
            end
            task.wait(0.5)
            if introSkipped then
                return
            end
            IntroCaptionShield.Visible = true
            tween(IntroCaptionShield, 0.3, { BackgroundTransparency = 0.08 })
            if TapAnywhere then
                task.spawn(function()
                    while not introSkipped do
                        tween(TapAnywhere, 0.8, { TextTransparency = 0.5 })
                        task.wait(0.8)
                        if introSkipped then
                            return
                        end
                        tween(TapAnywhere, 0.8, { TextTransparency = 0 })
                        task.wait(0.8)
                    end
                end)
            end
            task.wait(6)
            if not introSkipped then
                skipIntro()
            end
        end)
    end)
end
_G.__PulseHubRunIntro()
_G.PulseHubForceSyncLoadedButtons = function()
    pcall(function()
        if setAutoTPVisual then
            setAutoTPVisual(autoTPEnabled)
        end
        if autoTPEnabled then
            startAutoTP()
        else
            stopAutoTP()
        end
    end)
    pcall(function()
        if setInfJumpVisual then
            setInfJumpVisual(infJumpEnabled)
        end
        if setInfJumpInternal then
            setInfJumpInternal(infJumpEnabled)
        end
    end)
    pcall(function()
        if setAntiRagdollVisual then
            setAntiRagdollVisual(antiRagdollEnabled)
        end
        setAntiRagdoll(antiRagdollEnabled)
    end)
    pcall(function()
        if _G.PulseAutoRagdollTpState.setVisual then
            _G.PulseAutoRagdollTpState.setVisual(_G.PulseAutoRagdollTpState.enabled)
        end
        _G.PulseAutoRagdollTpState.set(_G.PulseAutoRagdollTpState.enabled)
    end)
    pcall(function()
        if _G.PulseSetAutoLeft then
            _G.PulseSetAutoLeft(autoLeftEnabled, true)
        end
        if _G.PulseSetAutoRight then
            _G.PulseSetAutoRight(autoRightEnabled, true)
        end
    end)
    pcall(function()
        if setAutoStealVisual then
            setAutoStealVisual(autoStealEnabled)
        end
        if _G.PulseAutoStealSync then
            _G.PulseAutoStealSync()
        end
    end)
    pcall(function()
        if _G.PulseSetNormalRagdollStealVisual then
            _G.PulseSetNormalRagdollStealVisual(_G.PulseNormalRagdollStealEnabled == true)
        end
        if _G.PulseRefreshNormalRagdollStealRow then
            _G.PulseRefreshNormalRagdollStealRow()
        end
        if _G.PulseSetSemiRagdollStealVisual then
            _G.PulseSetSemiRagdollStealVisual(_G.PulseSemiRagdollStealEnabled == true)
        end
        if _G.PulseRefreshSemiRagdollStealRow then
            _G.PulseRefreshSemiRagdollStealRow()
        end
    end)
    pcall(function()
        if _G.PulseNormalAutoSwingSetVisual then
            _G.PulseNormalAutoSwingSetVisual(autoSwingEnabled)
        end
        if _G.PulseAntiDesyncAutoSwingSetVisual then
            _G.PulseAntiDesyncAutoSwingSetVisual(antiDesyncAutoSwingEnabled)
        end
        if _G.PulseAntiDesyncSetVisual then
            _G.PulseAntiDesyncSetVisual(_G.PulseAntiDesyncAimbotOn == true)
        end
        if _G.PulseAntiDesyncAimbotOn and _G.PulseStartAntiDesyncAimbot then
            _G.PulseStartAntiDesyncAimbot()
        elseif _G.PulseStopAntiDesyncAimbot then
            _G.PulseStopAntiDesyncAimbot()
        end
    end)
    pcall(function()
        if _G.PulseAntiBypassAimbotOn and _G.PulseAntiBypassStart then
            _G.PulseAntiBypassStart()
        elseif _G.PulseAntiBypassStop then
            _G.PulseAntiBypassStop()
        end
        if _G.PulseRefreshAimbotVisual then
            _G.PulseRefreshAimbotVisual()
        end
    end)
    pcall(function()
        if setBatCounterVisual then
            setBatCounterVisual(batCounterEnabled)
        end
        if setMedCounterVisual then
            setMedCounterVisual(medCounterEnabled)
        end
        if batCounterEnabled then
            if _G.PulseStartBatCounter then
                _G.PulseStartBatCounter()
            end
        else
            if _G.PulseStopBatCounter then
                _G.PulseStopBatCounter()
            end
        end
        if medCounterEnabled then
            if _G.PulseStartMedCounter then
                _G.PulseStartMedCounter(LP.Character)
            end
        else
            if _G.PulseStopMedCounter then
                _G.PulseStopMedCounter()
            end
        end
        if _G.PulseSetNoPlayerCollisionVisual then
            _G.PulseSetNoPlayerCollisionVisual(_G.PulseNoPlayerCollisionEnabled)
        end
        if _G.PulseNoPlayerCollisionEnabled then
            if enableNoPlayerCollision then
                enableNoPlayerCollision()
            end
        else
            if disableNoPlayerCollision then
                disableNoPlayerCollision()
            end
        end
    end)
    pcall(function()
        if setPlayerESPVisual then
            setPlayerESPVisual(espEnabled)
        end
        if espEnabled then
            if startPlayerESP then
                startPlayerESP()
            end
            if BoxedESPOptions then
                BoxedESPOptions.box = true
            end
        else
            if stopPlayerESP then
                stopPlayerESP()
            end
            if BoxedESPOptions then
                BoxedESPOptions.box = false
            end
        end
        if setTracerESPVisual then
            setTracerESPVisual(showTracerEnabled)
        end
        if BoxedESPOptions then
            BoxedESPOptions.tracer = showTracerEnabled
        end
        if refreshBoxedESP then
            refreshBoxedESP()
        end
        if setRagdollCountdownVisual then
            setRagdollCountdownVisual(ragdollCountdownEnabled)
        end
        if ragdollCountdownEnabled then
            hookRagdollCountdown(LP.Character)
        else
            stopRagdollCountdown()
        end
        if setFPSBoostVisual then
            setFPSBoostVisual(fpsBoostEnabled)
        end
        if fpsBoostEnabled then
            enableStretchRez()
        else
            disableStretchRez()
        end
        if setAntiLagVisual then
            setAntiLagVisual(antiLagVisualEnabled)
        end
        if antiLagVisualEnabled then
            enableAntiLag()
        else
            disableAntiLag()
        end
        if setFOVVisual then
            setFOVVisual(fovEnabled)
        end
        if fovEnabled then
            enableCustomFov()
        else
            disableCustomFov()
        end
        if setNoCamCollisionVisual then
            setNoCamCollisionVisual(noCamCollisionEnabled)
        end
        if noCamCollisionEnabled then
            enableNoCamCollision()
        else
            disableNoCamCollision()
        end
        if type(applyCustomSky) == "function" then
            applyCustomSky((skyTheme and skyTheme ~= "") and skyTheme or "Off")
        end
        if skyValueLabel then
            skyValueLabel.Text = skyTheme or "Off"
        end
    end)
    pcall(savePulseConfig)
end
customFontVisualEnabled = false
if V then
    V.customFontEnabled = false
end
_G.PulseHubApplySavedGameplayStates = function()
    pcall(function()
        if setAutoTPVisual then
            setAutoTPVisual(autoTPEnabled == true)
        end
        if autoTPEnabled then
            startAutoTP()
        else
            stopAutoTP()
        end
    end)
    pcall(function()
        if setInfJumpVisual then
            setInfJumpVisual(infJumpEnabled == true)
        end
        if setInfJumpInternal then
            setInfJumpInternal(infJumpEnabled == true)
        end
    end)
    pcall(function()
        if setAntiRagdollVisual then
            setAntiRagdollVisual(antiRagdollEnabled == true)
        end
        if setAntiRagdoll then
            setAntiRagdoll(antiRagdollEnabled == true)
        end
    end)
    pcall(function()
        if _G.PulseAutoRagdollTpState.setVisual then
            _G.PulseAutoRagdollTpState.setVisual(_G.PulseAutoRagdollTpState.enabled == true)
        end
        if _G.PulseAutoRagdollTpState.set then
            _G.PulseAutoRagdollTpState.set(_G.PulseAutoRagdollTpState.enabled == true)
        end
    end)
    pcall(function()
        if setAutoStealVisual then
            setAutoStealVisual(autoStealEnabled == true)
        end
        if _G.PulseAutoStealSync then
            _G.PulseAutoStealSync()
        end
    end)
    pcall(function()
        if _G.PulseSetNormalRagdollStealVisual then
            _G.PulseSetNormalRagdollStealVisual(_G.PulseNormalRagdollStealEnabled == true)
        end
        if _G.PulseRefreshNormalRagdollStealRow then
            _G.PulseRefreshNormalRagdollStealRow()
        end
        if _G.PulseSetSemiRagdollStealVisual then
            _G.PulseSetSemiRagdollStealVisual(_G.PulseSemiRagdollStealEnabled == true)
        end
        if _G.PulseRefreshSemiRagdollStealRow then
            _G.PulseRefreshSemiRagdollStealRow()
        end
    end)
    pcall(function()
        if setBatCounterVisual then
            setBatCounterVisual(batCounterEnabled == true)
        end
        if batCounterEnabled and _G.PulseStartBatCounter then
            _G.PulseStartBatCounter()
        elseif _G.PulseStopBatCounter then
            _G.PulseStopBatCounter()
        end
    end)
    pcall(function()
        if setMedCounterVisual then
            setMedCounterVisual(medCounterEnabled == true)
        end
        if medCounterEnabled and _G.PulseStartMedCounter then
            _G.PulseStartMedCounter(LP.Character)
        elseif _G.PulseStopMedCounter then
            _G.PulseStopMedCounter()
        end
    end)
    pcall(function()
        if _G.PulseSetNoPlayerCollisionVisual then
            _G.PulseSetNoPlayerCollisionVisual(_G.PulseNoPlayerCollisionEnabled == true)
        end
        if _G.PulseNoPlayerCollisionEnabled then
            enableNoPlayerCollision()
        else
            disableNoPlayerCollision()
        end
    end)
    pcall(function()
        if setPlayerESPVisual then
            setPlayerESPVisual(espEnabled == true)
        end
        if espEnabled then
            if startPlayerESP then
                startPlayerESP()
            end
        else
            if stopPlayerESP then
                stopPlayerESP()
            end
        end
    end)
    pcall(function()
        if setTracerESPVisual then
            setTracerESPVisual(showTracerEnabled == true)
        end
        if BoxedESPOptions then
            BoxedESPOptions.tracer = showTracerEnabled == true
        end
        if refreshBoxedESP then
            refreshBoxedESP()
        end
    end)
    pcall(function()
        if setRagdollCountdownVisual then
            setRagdollCountdownVisual(ragdollCountdownEnabled == true)
        end
        if ragdollCountdownEnabled then
            hookRagdollCountdown(LP.Character)
        else
            stopRagdollCountdown()
        end
    end)
    pcall(function()
        if setFPSBoostVisual then
            setFPSBoostVisual(fpsBoostEnabled == true)
        end
        if fpsBoostEnabled then
            enableStretchRez()
        else
            disableStretchRez()
        end
    end)
    pcall(function()
        if setAntiLagVisual then
            setAntiLagVisual(antiLagVisualEnabled == true)
        end
        if antiLagVisualEnabled then
            enableAntiLag()
        else
            disableAntiLag()
        end
    end)
    pcall(function()
        if setFOVVisual then
            setFOVVisual(fovEnabled == true)
        end
        if fovEnabled then
            enableCustomFov()
        else
            disableCustomFov()
        end
    end)
    pcall(function()
        if setNoCamCollisionVisual then
            setNoCamCollisionVisual(noCamCollisionEnabled == true)
        end
        if noCamCollisionEnabled then
            enableNoCamCollision()
        else
            disableNoCamCollision()
        end
    end)
    pcall(function()
        if type(applyCustomSky) == "function" then
            applyCustomSky((skyTheme and skyTheme ~= "") and skyTheme or "Off")
        end
        if skyValueLabel then
            skyValueLabel.Text = skyTheme or "Off"
        end
    end)
    pcall(function()
        if syncAnimationPackIndex then
            syncAnimationPackIndex()
        end
        if refreshAnimationPackRow then
            refreshAnimationPackRow()
        end
        if applySavedAnimationPackToCharacter then
            applySavedAnimationPackToCharacter(LP.Character)
        end
    end)
end
task.defer(function()
    if _G.PulseHubForceSyncLoadedButtons then
        _G.PulseHubForceSyncLoadedButtons()
    end
end)
_G.PulseAutoTPRestoreWanted = _G.PulseAutoTPRestoreWanted or false
_G.PulseAutoTPRestoreBlockedUntil = _G.PulseAutoTPRestoreBlockedUntil or 0
function pulseAnyAimbotActive()
    return (_G.PulseNormalAimbotOn == true)
        or (_G.PulseAntiBypassAimbotOn == true)
        or (_G.PulseAntiDesyncAimbotOn == true)
end
_G.PulseStopAutoTPForAction = function()
    if autoTPEnabled then
        _G.PulseAutoTPRestoreWanted = true
        _G.PulseAutoTPRestoreBlockedUntil = tick() + 0.35
        stopAutoTP()
        if setAutoTPVisual then
            setAutoTPVisual(false)
        end
    end
end
function pulseTryRestoreAutoTP()
    if not _G.PulseAutoTPRestoreWanted then
        return
    end
    if tick() < (_G.PulseAutoTPRestoreBlockedUntil or 0) then
        return
    end
    if pulseAnyAimbotActive() then
        return
    end
    if dropBrainrotActive then
        return
    end
    _G.PulseAutoTPRestoreWanted = false
    startAutoTP()
    if setAutoTPVisual then
        setAutoTPVisual(true)
    end
    savePulseConfig()
end
RunService.Heartbeat:Connect(pulseTryRestoreAutoTP)
_G._oldPulseStopAntiBypassAimbot = _G.PulseStopAntiBypassAimbot
_G.PulseStopAntiBypassAimbot = function(...)
    local r = { _G._oldPulseStopAntiBypassAimbot(...) }
    _G.PulseAutoTPRestoreBlockedUntil = tick() + 0.05
    task.delay(0.08, pulseTryRestoreAutoTP)
    return unpack(r)
end
_G.PulseAntiBypassStop = _G.PulseStopAntiBypassAimbot
_G._oldPulseStopAntiDesyncAimbot = _G.PulseStopAntiDesyncAimbot
_G.PulseStopAntiDesyncAimbot = function(...)
    local r = { _G._oldPulseStopAntiDesyncAimbot(...) }
    _G.PulseAutoTPRestoreBlockedUntil = tick() + 0.05
    task.delay(0.08, pulseTryRestoreAutoTP)
    return unpack(r)
end
task.spawn(function()
    local wasDropping = false
    while task.wait(0.05) do
        if dropBrainrotActive then
            wasDropping = true
        elseif wasDropping then
            wasDropping = false
            _G.PulseAutoTPRestoreBlockedUntil = tick() + 0.05
            task.delay(0.08, pulseTryRestoreAutoTP)
        end
    end
end)
function pulseRepairKeybinds()
    for keyId, defaultKey in pairs(DEFAULT_SPEED_KEYBINDS) do
        if speedKeybinds[keyId] == Enum.KeyCode.Unknown then
            speedKeybinds[keyId] = defaultKey
        end
    end
    if tpDownKeybind == Enum.KeyCode.Unknown then
        tpDownKeybind = DEFAULT_TP_DOWN_KEYBIND
    end
    if refreshAllSpeedKeybinds then
        refreshAllSpeedKeybinds()
    end
    if refreshTPDownKeybind then
        refreshTPDownKeybind()
    end
end
_G._oldSavePulseConfigStable = savePulseConfig
savePulseConfig = function()
    pulseRepairKeybinds()
    return _G._oldSavePulseConfigStable()
end
pulseRepairKeybinds()
pulseStartupBuilding = false
pulseStartupSavePending = false
task.defer(savePulseConfig)
task.defer(function()
    local old = PlayerGui:FindFirstChild("PulseHubMobileButtons") or PlayerGui:FindFirstChild("BrokenHubMobileButtons")
    if old then
        old:Destroy()
    end
    for _, n in ipairs({ "PulseHubMobileButtons", "BrokenHubMobileButtons", "MoveeMobileButtons", "PulseMobileButtons" }) do
        local oldC = game:GetService("CoreGui"):FindFirstChild(n)
        if oldC then
            oldC:Destroy()
        end
        local pgui = LP:FindFirstChild("PlayerGui")
        if pgui then
            local o = pgui:FindFirstChild(n)
            if o then
                o:Destroy()
            end
        end
    end
    _G.PulseMobileButtonRefs = {}
    local mobileButtons = _G.PulseMobileButtonRefs
    _G.PulseApplyMobileButtonsHidden = function()
        local g = PlayerGui:FindFirstChild("PulseHubMobileButtons")
        if g then
            g.Enabled = not (_G.PulseHideMobileButtons == true) and not (_G.PulseIntroInProgress == true)
        end
        if setHideMobileButtonsVisual then
            pcall(setHideMobileButtonsVisual, _G.PulseHideMobileButtons == true)
        end
    end
    _G.PulseApplyMobileButtonSize = function()
        _G.PulseMobileButtonScale = math.clamp(tonumber(_G.PulseMobileButtonScale) or 0.75, 0.30, 1.35)
        local g = PlayerGui:FindFirstChild("PulseHubMobileButtons")
        local p = g and g:FindFirstChild("MobPanel")
        local sc = p and p:FindFirstChild("PulseMobScale")
        if sc then
            sc.Scale = _G.PulseMobileButtonScale
        end
    end
    local MOB_STYLES = {
        ["Button 1"] = {
            w = 68,
            h = 46,
            gap = 6,
            pad = 6,
            font = Enum.Font.GothamBlack,
            textSize = 10,
            bgTrans = 0.1,
            stroke = true,
            flash = false,
            lineHeight = 1.0,
        },
        ["Button 2"] = {
            w = 58,
            h = 58,
            gap = 14,
            pad = 6,
            font = Enum.Font.GothamBold,
            textSize = 11,
            bgTrans = 0,
            stroke = false,
            flash = true,
            lineHeight = 1.2,
        },
    }
    local function currentMobStyle()
        return MOB_STYLES[mobileButtonStyle] or MOB_STYLES["Button 2"]
    end
    local function styleDims()
        local st = currentMobStyle()
        local visibleCount = 0
        local order = _G.PulseSanitizeMobileButtonOrder(_G.PulseMobileButtonOrder)
        local hidden = _G.PulseSanitizeMobileButtonHidden(_G.PulseMobileButtonHidden)
        for _, id in ipairs(order) do
            if hidden[id] ~= true then
                visibleCount = visibleCount + 1
            end
        end
        local rows = math.max(1, math.ceil(visibleCount / 2))
        return st.pad * 2 + 2 * st.w + st.gap, st.pad * 2 + rows * st.h + math.max(0, rows - 1) * st.gap
    end
    local function defaultMobPosition()
        local w, h = styleDims()
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
        return UDim2.new(0, math.max(0, vp.X - w - 14), 0, math.max(0, (vp.Y - h) / 2))
    end
    local mobGui = Instance.new("ScreenGui")
    mobGui.Name = "PulseHubMobileButtons"
    mobGui.ResetOnSpawn = false
    mobGui.Enabled = not (_G.PulseHideMobileButtons == true) and not (_G.PulseIntroInProgress == true)
    mobGui.DisplayOrder = 1000
    mobGui.IgnoreGuiInset = true
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(mobGui)
        end
    end)
    mobGui.Parent = PlayerGui
    local PANEL_W, PANEL_H = styleDims()
    local panel = Instance.new("Frame")
    panel.Name = "MobPanel"
    panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
    panel.Position = tableToUDim2(savedMobPanelPositionTable, defaultMobPosition())
    savedMobPanelPositionTable = udim2ToTable(panel.Position)
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.ZIndex = 95
    panel.Parent = mobGui
    local mobBtnScale = Instance.new("UIScale")
    mobBtnScale.Name = "PulseMobScale"
    mobBtnScale.Scale = math.clamp(tonumber(_G.PulseMobileButtonScale) or 0.75, 0.30, 1.35)
    mobBtnScale.Parent = panel
    local dragInfo = { dragging = false, start = nil, startPos = nil }
    panel.InputBegan:Connect(function(input)
        if _G.PulseGuiLocked == true then
            return
        end
        if _G.PulseDragMobileButtons == true then
            return
        end
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragInfo.dragging = true
            dragInfo.start = input.Position
            dragInfo.startPos = panel.Position
        end
    end)
    panel.InputChanged:Connect(function(input)
        if
            dragInfo.dragging
            and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            )
        then
            local delta = input.Position - dragInfo.start
            local targetX = dragInfo.startPos.X.Offset + delta.X
            local targetY = dragInfo.startPos.Y.Offset + delta.Y
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
            local pw, ph = styleDims()
            if math.abs(targetX - 10) < 16 then
                targetX = 10
            end
            if math.abs(targetX - (vp.X - pw - 10)) < 16 then
                targetX = vp.X - pw - 10
            end
            if math.abs(targetY - 10) < 16 then
                targetY = 10
            end
            if math.abs(targetY - (vp.Y - ph - 10)) < 16 then
                targetY = vp.Y - ph - 10
            end
            panel.Position = UDim2.new(dragInfo.startPos.X.Scale, targetX, dragInfo.startPos.Y.Scale, targetY)
        end
    end)
    panel.InputEnded:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragInfo.dragging = false
            savedMobPanelPositionTable = udim2ToTable(panel.Position)
            task.defer(function()
                pcall(savePulseConfig)
            end)
        end
    end)
    local Q_OFF = Color3.fromRGB(0, 0, 0)
    local Q_ON = Color3.fromRGB(255, 255, 255)
    local Q_TEXT_OFF = Color3.fromRGB(255, 255, 255)
    local Q_TEXT_ON = Color3.fromRGB(0, 0, 0)
    local function buildMobilePanel()
        local st = currentMobStyle()
        local pw, ph = styleDims()
        panel.Size = UDim2.new(0, pw, 0, ph)
        for _, ch in ipairs(panel:GetChildren()) do
            if ch:IsA("TextButton") then
                ch:Destroy()
            end
        end
        for k in pairs(mobileButtons) do
            mobileButtons[k] = nil
        end
        local function createMobileButton(name, displayText, col, row, isToggle, onAction)
            local xPos = st.pad + col * (st.w + st.gap)
            local yPos = st.pad + row * (st.h + st.gap)
            local btn = Instance.new("TextButton")
            btn.Name = "MB_" .. name
            btn.Size = UDim2.new(0, st.w, 0, st.h)
            btn.Position = tableToUDim2(
                _G.PulseMobileButtonPositions and _G.PulseMobileButtonPositions[name],
                UDim2.new(0, xPos, 0, yPos)
            )
            btn.BackgroundColor3 = (
                _G.PulseResolveMobileButtonColor and _G.PulseResolveMobileButtonColor("inactiveBackground")
            ) or Q_OFF
            btn.BackgroundTransparency = st.bgTrans
            btn.Text = displayText
            btn.TextColor3 = (_G.PulseResolveMobileButtonColor and _G.PulseResolveMobileButtonColor("inactiveText"))
                or Q_TEXT_OFF
            btn.TextScaled = false
            btn.TextSize = st.textSize
            btn.Font = st.font
            btn.TextWrapped = true
            btn.LineHeight = st.lineHeight
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.ZIndex = 99
            btn.Parent = panel
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
            if st.stroke then
                local strokeInst = Instance.new("UIStroke")
                strokeInst.Color = (
                    _G.PulseResolveMobileButtonColor and _G.PulseResolveMobileButtonColor("inactiveText")
                ) or Color3.fromRGB(235, 235, 240)
                strokeInst.Thickness = 1
                strokeInst.Transparency = 0.3
                strokeInst.Parent = btn
            end
            local lastVisualState = nil
            _G.PulseMobileButtonRefs = _G.PulseMobileButtonRefs or {}
            _G.PulseMobileButtonRefs[name] = { btn = btn, state = false }
            local function setter(s)
                s = (s == true)
                local entry = _G.PulseMobileButtonRefs[name]
                if entry then
                    entry.state = s
                end
                if lastVisualState == s then
                    return
                end
                lastVisualState = s
                local onColor = (
                    _G.PulseResolveMobileButtonColor and _G.PulseResolveMobileButtonColor("activeBackground")
                ) or Q_ON
                local offColor = (
                    _G.PulseResolveMobileButtonColor and _G.PulseResolveMobileButtonColor("inactiveBackground")
                ) or Q_OFF
                local onText = (_G.PulseResolveMobileButtonColor and _G.PulseResolveMobileButtonColor("activeText"))
                    or Q_TEXT_ON
                local offText = (_G.PulseResolveMobileButtonColor and _G.PulseResolveMobileButtonColor("inactiveText"))
                    or Q_TEXT_OFF
                TweenService
                    :Create(
                        btn,
                        TweenInfo.new(0.15),
                        { BackgroundColor3 = s and onColor or offColor, TextColor3 = s and onText or offText }
                    )
                    :Play()
                local strokeInst = btn:FindFirstChildOfClass("UIStroke")
                if strokeInst then
                    TweenService:Create(strokeInst, TweenInfo.new(0.15), { Color = s and onText or offText }):Play()
                end
            end
            local function flash()
                local onColor = (
                    _G.PulseResolveMobileButtonColor and _G.PulseResolveMobileButtonColor("activeBackground")
                ) or Q_ON
                local onText = (_G.PulseResolveMobileButtonColor and _G.PulseResolveMobileButtonColor("activeText"))
                    or Q_TEXT_ON
                TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundColor3 = onColor, TextColor3 = onText })
                    :Play()
                local flashStroke = btn:FindFirstChildOfClass("UIStroke")
                if flashStroke then
                    TweenService:Create(flashStroke, TweenInfo.new(0.08), { Color = onText }):Play()
                end
                task.delay(0.22, function()
                    local offColor = (
                        _G.PulseResolveMobileButtonColor and _G.PulseResolveMobileButtonColor("inactiveBackground")
                    ) or Q_OFF
                    local offText = (
                        _G.PulseResolveMobileButtonColor and _G.PulseResolveMobileButtonColor("inactiveText")
                    ) or Q_TEXT_OFF
                    TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = offColor, TextColor3 = offText })
                        :Play()
                    if flashStroke then
                        TweenService:Create(flashStroke, TweenInfo.new(0.15), { Color = offText }):Play()
                    end
                end)
            end
            local function pulse()
                setter(true)
                task.delay(0.18, function()
                    setter(false)
                end)
            end
            mobileButtons[name] = {
                btn = btn,
                setActive = function(state)
                    setter(state)
                end,
            }
            local bd = { dragging = false, moved = false, start = nil, startPos = nil, endedAt = 0 }
            btn.InputBegan:Connect(function(input)
                if _G.PulseDragMobileButtons ~= true then
                    return
                end
                if _G.PulseGuiLocked == true then
                    return
                end
                if
                    input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and input.UserInputType ~= Enum.UserInputType.Touch
                then
                    return
                end
                bd.dragging = true
                bd.moved = false
                bd.start = input.Position
                bd.startPos = btn.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        bd.dragging = false
                        if bd.moved then
                            bd.endedAt = tick()
                            task.delay(0.25, function()
                                bd.moved = false
                            end)
                            pcall(function()
                                _G.PulseMobileButtonPositions = _G.PulseMobileButtonPositions or {}
                                _G.PulseMobileButtonPositions[name] = udim2ToTable(btn.Position)
                            end)
                            task.defer(function()
                                pcall(savePulseConfig)
                            end)
                        end
                    end
                end)
            end)
            btn.InputChanged:Connect(function(input)
                if not bd.dragging then
                    return
                end
                if
                    input.UserInputType ~= Enum.UserInputType.MouseMovement
                    and input.UserInputType ~= Enum.UserInputType.Touch
                then
                    return
                end
                local delta = input.Position - bd.start
                if not bd.moved and delta.Magnitude < 5 then
                    return
                end
                bd.moved = true
                local sc = (mobBtnScale and mobBtnScale.Scale) or 1
                if sc <= 0 then
                    sc = 1
                end
                local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
                local panelLeft = panel.Position.X.Scale * vp.X + panel.Position.X.Offset
                local panelTop = panel.Position.Y.Scale * vp.Y + panel.Position.Y.Offset
                local minX = -panelLeft / sc
                local maxX = (vp.X - (st.w * sc) - panelLeft) / sc
                local minY = -panelTop / sc
                local maxY = (vp.Y - (st.h * sc) - panelTop) / sc
                local targetX = math.clamp(bd.startPos.X.Offset + delta.X / sc, minX, maxX)
                local targetY = math.clamp(bd.startPos.Y.Offset + delta.Y / sc, minY, maxY)
                btn.Position = UDim2.new(bd.startPos.X.Scale, targetX, bd.startPos.Y.Scale, targetY)
            end)
            btn.Activated:Connect(function()
                if bd.dragging or bd.moved or (tick() - bd.endedAt) < 0.2 then
                    return
                end
                if not isToggle then
                    if st.flash then
                        flash()
                    else
                        pulse()
                    end
                end
                if onAction then
                    onAction()
                end
            end)
            return btn, setter
        end
        local mobileActions = {
            drop = function()
                if runDropBrainrot then
                    task.spawn(runDropBrainrot)
                end
            end,
            autoLeft = function()
                if _G.PulseSetAutoLeft then
                    _G.PulseSetAutoLeft(not autoLeftEnabled)
                end
            end,
            aimbot = function()
                if _G.PulseToggleSelectedAimbot then
                    _G.PulseToggleSelectedAimbot()
                end
            end,
            autoRight = function()
                if _G.PulseSetAutoRight then
                    _G.PulseSetAutoRight(not autoRightEnabled)
                end
            end,
            tp = function()
                if runTPFloor then
                    task.spawn(runTPFloor)
                end
            end,
            carry = function()
                if isCarryingBrainrot(LP.Character) then
                    if currentSpeedMode == "Carry" then
                        pcall(function()
                            _safeNotify("BLOCKED: Normal disabled while holding")
                        end)
                        return
                    end
                    if setSpeedMode then
                        setSpeedMode("Carry")
                    end
                    return
                end
                if setSpeedMode then
                    setSpeedMode(currentSpeedMode == "Carry" and "Normal" or "Carry")
                end
            end,
            laggerNormal = function()
                if isCarryingBrainrot(LP.Character) then
                    pcall(function()
                        _safeNotify("BLOCKED: Lagger Normal disabled while holding")
                    end)
                    return
                end
                if setSpeedMode then
                    setSpeedMode(currentSpeedMode == "Lagger" and "Normal" or "Lagger")
                end
            end,
            insta = function()
                if _G.PulseCursedInstaReset then
                    _G.PulseCursedInstaReset()
                end
            end,
            laggerCarry = function()
                if isCarryingBrainrot(LP.Character) and currentSpeedMode == "Lagger Carry" then
                    pcall(function()
                        _safeNotify("BLOCKED: Normal disabled while holding")
                    end)
                    return
                end
                if setSpeedMode then
                    setSpeedMode(currentSpeedMode == "Lagger Carry" and "Normal" or "Lagger Carry")
                end
            end,
            antiDesync = function()
                if _G.PulseToggleAntiDesyncAimbot then
                    _G.PulseToggleAntiDesyncAimbot()
                end
            end,
            lagger2Normal = function()
                if isCarryingBrainrot(LP.Character) then
                    pcall(function()
                        _safeNotify("BLOCKED: Lagger 2 Normal disabled while holding")
                    end)
                    return
                end
                if setSpeedMode then
                    setSpeedMode(currentSpeedMode == "Lagger 2" and "Normal" or "Lagger 2")
                end
            end,
            lagger2Carry = function()
                if isCarryingBrainrot(LP.Character) and currentSpeedMode == "Lagger Carry 2" then
                    pcall(function()
                        _safeNotify("BLOCKED: Normal disabled while holding")
                    end)
                    return
                end
                if setSpeedMode then
                    setSpeedMode(currentSpeedMode == "Lagger Carry 2" and "Normal" or "Lagger Carry 2")
                end
            end,
        }
        local definitions = {}
        for _, definition in ipairs(_G.PulseMobileButtonDefinitions or {}) do
            definitions[definition.id] = definition
        end
        _G.PulseMobileButtonOrder = _G.PulseSanitizeMobileButtonOrder(_G.PulseMobileButtonOrder)
        _G.PulseMobileButtonHidden = _G.PulseSanitizeMobileButtonHidden(_G.PulseMobileButtonHidden)
        local visibleSlot = 0
        for _, name in ipairs(_G.PulseMobileButtonOrder) do
            local definition = definitions[name]
            if definition and _G.PulseMobileButtonHidden[name] ~= true then
                local col = visibleSlot % 2
                local row = math.floor(visibleSlot / 2)
                createMobileButton(name, definition.text, col, row, definition.toggle == true, mobileActions[name])
                visibleSlot = visibleSlot + 1
            end
        end
    end
    _G.PulseRebuildMobileButtons = function(style)
        if style and MOB_STYLES[style] then
            mobileButtonStyle = style
        end
        buildMobilePanel()
    end
    buildMobilePanel()
    _G.PulseApplyMobileButtonsHidden()
    _G.PulseResetMobileButtons = function()
        _G.PulseMobileButtonPositions = {}
        buildMobilePanel()
        panel.Position = defaultMobPosition()
        savedMobPanelPositionTable = udim2ToTable(panel.Position)
        _G.PulseMobileButtonScale = 0.75
        _G.PulseHideMobileButtons = false
        if _G.PulseApplyMobileButtonsHidden then
            _G.PulseApplyMobileButtonsHidden()
        end
        if _G.PulseApplyMobileButtonSize then
            _G.PulseApplyMobileButtonSize()
        end
        task.defer(function()
            pcall(savePulseConfig)
        end)
    end
    if _G.PulseMobileHeartbeatConn then
        pcall(function()
            _G.PulseMobileHeartbeatConn:Disconnect()
        end)
    end
    local mobileVisualElapsed = 0
    _G.PulseMobileHeartbeatConn = RunService.Heartbeat:Connect(function(delta)
        mobileVisualElapsed = mobileVisualElapsed + (delta or 0)
        if mobileVisualElapsed < 0.05 then
            return
        end
        mobileVisualElapsed = 0
        if mobileButtons.autoLeft then
            mobileButtons.autoLeft.setActive(autoLeftEnabled == true)
        end
        if mobileButtons.autoRight then
            mobileButtons.autoRight.setActive(autoRightEnabled == true)
        end
        if mobileButtons.aimbot then
            mobileButtons.aimbot.setActive((_G.PulseNormalAimbotOn == true) or (_G.PulseAntiBypassAimbotOn == true))
        end
        if mobileButtons.antiDesync then
            mobileButtons.antiDesync.setActive(_G.PulseAntiDesyncAimbotOn == true)
        end
        if mobileButtons.carry then
            mobileButtons.carry.setActive(currentSpeedMode == "Carry")
        end
        if mobileButtons.laggerNormal then
            mobileButtons.laggerNormal.setActive(currentSpeedMode == "Lagger")
        end
        if mobileButtons.laggerCarry then
            mobileButtons.laggerCarry.setActive(currentSpeedMode == "Lagger Carry")
        end
        if mobileButtons.lagger2Normal then
            mobileButtons.lagger2Normal.setActive(currentSpeedMode == "Lagger 2")
        end
        if mobileButtons.lagger2Carry then
            mobileButtons.lagger2Carry.setActive(currentSpeedMode == "Lagger Carry 2")
        end
    end)
end)
