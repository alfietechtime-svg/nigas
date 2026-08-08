--[[
    TP NOW
    Cleaned / fixed Roblox Luau version

    IMPORTANT:
    - This version is intended for your own Roblox experience.
    - Config is session-based because HttpService does NOT provide
      GetAsync/SetAsync. Persistent settings should use DataStoreService
      from a ServerScript.
    - Set STEAL_REMOTE_NAME to your own game's RemoteEvent if applicable.
]]

-- ============================================================
-- SERVICES
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- PLAYER GUI
-- ============================================================

local function getPlayerGui()
    local gui = LocalPlayer:WaitForChild("PlayerGui", 10)

    if not gui then
        warn("[TP NOW] PlayerGui failed to load")
        return nil
    end

    return gui
end

local PlayerGui = getPlayerGui()

if not PlayerGui then
    return
end

-- ============================================================
-- CONFIG
-- ============================================================

local configData = {
    autoTPOnLoad = false,
    autoTPEnabled = false,
}

-- Session-only configuration.
-- For persistent settings, use DataStoreService on the server.
local function loadConfig()
    print(
        "[Config] Loaded: autoTPOnLoad="
            .. tostring(configData.autoTPOnLoad)
            .. " autoTPEnabled="
            .. tostring(configData.autoTPEnabled)
    )
end

local function saveConfig()
    print(
        "[Config] Saved: autoTPOnLoad="
            .. tostring(configData.autoTPOnLoad)
            .. " autoTPEnabled="
            .. tostring(configData.autoTPEnabled)
    )
end

-- ============================================================
-- MONEY FORMATTER
-- ============================================================

local function fmtMoney(n)
    n = tonumber(n) or 0

    if n >= 1e12 then
        return string.format("$%.2fT", n / 1e12)
    elseif n >= 1e9 then
        return string.format("$%.2fB", n / 1e9)
    elseif n >= 1e6 then
        return string.format("$%.2fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("$%.1fK", n / 1e3)
    end

    return "$" .. tostring(n)
end

-- ============================================================
-- GENERATION PARSER
-- ============================================================

local function parseGeneration(text)
    if not text or text == "" then
        return 0
    end

    local clean = tostring(text)
        :gsub("%$", "")
        :gsub(",", "")
        :gsub("%s+", "")

    local number, suffix = clean:match("^([%d%.]+)([KMBT]?)")

    number = tonumber(number)

    if not number then
        return 0
    end

    local multiplier = 1

    if suffix == "K" then
        multiplier = 1e3
    elseif suffix == "M" then
        multiplier = 1e6
    elseif suffix == "B" then
        multiplier = 1e9
    elseif suffix == "T" then
        multiplier = 1e12
    end

    return number * multiplier
end

-- ============================================================
-- EXTRACT GENERATION
-- ============================================================

local function extractGenerationFromPet(petModel)
    if not petModel then
        return 0, "$0"
    end

    -- Attribute first
    local genAttr = petModel:GetAttribute("Generation")

    if typeof(genAttr) == "number" and genAttr > 0 then
        return genAttr, fmtMoney(genAttr)
    end

    -- NumberValue fallback
    for _, child in ipairs(petModel:GetChildren()) do
        if child:IsA("NumberValue") then
            if child.Name == "Generation"
                or child.Name == "Value"
                or child.Name == "Gen"
            then
                if child.Value > 0 then
                    return child.Value, fmtMoney(child.Value)
                end
            end
        end
    end

    -- Look for overhead information
    local debris = Workspace:FindFirstChild("Debris")

    if debris then
        for _, obj in ipairs(debris:GetDescendants()) do
            if obj:IsA("SurfaceGui") and obj.Name == "AnimalOverhead" then

                local generationLabel = obj:FindFirstChild("Generation")
                local displayNameLabel = obj:FindFirstChild("DisplayName")

                if generationLabel and generationLabel:IsA("TextLabel") then
                    local matchesPet = true

                    if displayNameLabel
                        and displayNameLabel:IsA("TextLabel")
                    then
                        matchesPet = displayNameLabel.Text == petModel.Name
                    end

                    if matchesPet then
                        local generationText = generationLabel.Text

                        if generationText and generationText ~= "" then
                            local value = parseGeneration(generationText)

                            if value > 0 then
                                return value, generationText
                            end
                        end
                    end
                end
            end
        end
    end

    return 0, "$0"
end

-- ============================================================
-- MUTATION
-- ============================================================

local function getMutation(petModel)
    if not petModel then
        return "None"
    end

    local attrMut = petModel:GetAttribute("Mutation")

    if attrMut ~= nil and tostring(attrMut) ~= "" then
        return tostring(attrMut)
    end

    local mutObj = petModel:FindFirstChild("Mutation")

    if mutObj then
        if mutObj:IsA("StringValue") and mutObj.Value ~= "" then
            return mutObj.Value
        end

        if mutObj:IsA("ObjectValue") and mutObj.Value then
            return mutObj.Value.Name
        end
    end

    return "None"
end

-- ============================================================
-- BASE CHECK
-- ============================================================

local function isPlayerBase(plot)
    if not plot then
        return false
    end

    local sign = plot:FindFirstChild("PlotSign")

    if sign then
        local yourBase = sign:FindFirstChild("YourBase")

        if yourBase then
            if yourBase:IsA("BoolValue") then
                return yourBase.Value
            end

            if yourBase:IsA("GuiObject") then
                return yourBase.Visible
            end

            local enabled = yourBase:GetAttribute("Enabled")

            if enabled ~= nil then
                return enabled == true
            end
        end
    end

    return false
end

-- ============================================================
-- BASE BOUNDARIES
-- ============================================================

local function getBaseBoundaries(plot)
    if not plot then
        return nil
    end

    local minX = math.huge
    local maxX = -math.huge
    local minZ = math.huge
    local maxZ = -math.huge

    for _, part in ipairs(plot:GetDescendants()) do
        if part:IsA("BasePart") then
            local cf = part.CFrame
            local size = part.Size

            -- Bounding-box approximation in world X/Z
            local corners = {
                cf:PointToWorldSpace(Vector3.new(-size.X / 2, 0, -size.Z / 2)),
                cf:PointToWorldSpace(Vector3.new(size.X / 2, 0, -size.Z / 2)),
                cf:PointToWorldSpace(Vector3.new(-size.X / 2, 0, size.Z / 2)),
                cf:PointToWorldSpace(Vector3.new(size.X / 2, 0, size.Z / 2)),
            }

            for _, pos in ipairs(corners) do
                minX = math.min(minX, pos.X)
                maxX = math.max(maxX, pos.X)
                minZ = math.min(minZ, pos.Z)
                maxZ = math.max(maxZ, pos.Z)
            end
        end
    end

    if minX == math.huge then
        return nil
    end

    return {
        minX = minX,
        maxX = maxX,
        minZ = minZ,
        maxZ = maxZ,
    }
end

local function isInsideOtherBase(pos, targetPlot)
    local plots = Workspace:FindFirstChild("Plots")

    if not plots then
        return false
    end

    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") and plot.Name ~= targetPlot then

            local boundaries = getBaseBoundaries(plot)

            if boundaries then
                if pos.X >= boundaries.minX
                    and pos.X <= boundaries.maxX
                    and pos.Z >= boundaries.minZ
                    and pos.Z <= boundaries.maxZ
                then
                    return true
                end
            end
        end
    end

    return false
end

-- ============================================================
-- SAFE PATH
-- ============================================================

local function segmentHitsBase(a, b, targetPlot)
    local distance = (b - a).Magnitude

    if distance <= 0 then
        return isInsideOtherBase(a, targetPlot)
    end

    local steps = math.max(2, math.ceil(distance / 10))

    for i = 0, steps do
        local alpha = i / steps
        local point = a:Lerp(b, alpha)

        if isInsideOtherBase(point, targetPlot) then
            return true
        end
    end

    return false
end

local function getSafePath(startPos, targetPos, targetPlot)
    if not segmentHitsBase(startPos, targetPos, targetPlot) then
        return {
            startPos,
            targetPos,
        }
    end

    local offsets = {
        Vector3.new(15, 0, 0),
        Vector3.new(-15, 0, 0),
        Vector3.new(0, 0, 15),
        Vector3.new(0, 0, -15),

        Vector3.new(25, 0, 25),
        Vector3.new(-25, 0, 25),
        Vector3.new(25, 0, -25),
        Vector3.new(-25, 0, -25),

        Vector3.new(40, 0, 0),
        Vector3.new(-40, 0, 0),
        Vector3.new(0, 0, 40),
        Vector3.new(0, 0, -40),
    }

    local bestPath = nil
    local bestDistance = math.huge

    for _, offset in ipairs(offsets) do
        local p1 = startPos + offset
        local p2 = targetPos + offset

        if not isInsideOtherBase(p1, targetPlot)
            and not isInsideOtherBase(p2, targetPlot)
        then

            local valid =
                not segmentHitsBase(startPos, p1, targetPlot)
                and not segmentHitsBase(p1, p2, targetPlot)
                and not segmentHitsBase(p2, targetPos, targetPlot)

            if valid then
                local distance =
                    (startPos - p1).Magnitude
                    + (p1 - p2).Magnitude
                    + (p2 - targetPos).Magnitude

                if distance < bestDistance then
                    bestDistance = distance

                    bestPath = {
                        startPos,
                        p1,
                        p2,
                        targetPos,
                    }
                end
            end
        end
    end

    if bestPath then
        return bestPath
    end

    -- Elevated fallback
    local highPoint = Vector3.new(
        (startPos.X + targetPos.X) / 2,
        math.max(startPos.Y, targetPos.Y) + 25,
        (startPos.Z + targetPos.Z) / 2
    )

    if not isInsideOtherBase(highPoint, targetPlot) then
        return {
            startPos,
            highPoint,
            targetPos,
        }
    end

    return {
        startPos,
        targetPos,
    }
end

-- ============================================================
-- PET SCANNER
-- ============================================================

local function scanPets()
    local results = {}

    local plots = Workspace:FindFirstChild("Plots")

    if not plots then
        return results
    end

    local seen = {}

    for _, plot in ipairs(plots:GetChildren()) do

        if plot:IsA("Model") and not isPlayerBase(plot) then

            for _, desc in ipairs(plot:GetDescendants()) do

                if desc:IsA("Model") then

                    local humanoid =
                        desc:FindFirstChildOfClass("Humanoid")

                    local hrp =
                        desc:FindFirstChild("HumanoidRootPart")

                    if humanoid or hrp then

                        local gen, genText =
                            extractGenerationFromPet(desc)

                        if gen > 0 and not seen[desc] then

                            seen[desc] = true

                            local position

                            if hrp and hrp:IsA("BasePart") then
                                position = hrp.Position
                            else
                                position = desc:GetPivot().Position
                            end

                            table.insert(results, {
                                name = desc.Name,
                                gen = gen,
                                genText = genText,
                                mutation = getMutation(desc),
                                position = position,
                                plot = plot.Name,
                                model = desc,
                                uid = plot.Name .. "_" .. desc.Name,
                            })
                        end
                    end
                end
            end
        end
    end

    table.sort(results, function(a, b)
        return (a.gen or 0) > (b.gen or 0)
    end)

    return results
end

-- ============================================================
-- PROMPT FINDER
-- ============================================================

local function findStealPrompt(pet)
    if not pet or not pet.model then
        return nil
    end

    for _, obj in ipairs(pet.model:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then

            local action = string.lower(obj.ActionText or "")

            if string.find(action, "steal", 1, true) then
                return obj
            end
        end
    end

    local plots = Workspace:FindFirstChild("Plots")

    if not plots then
        return nil
    end

    local plot = plots:FindFirstChild(pet.plot)

    if not plot then
        return nil
    end

    local podiums = plot:FindFirstChild("AnimalPodiums")

    if podiums then
        for _, podium in ipairs(podiums:GetChildren()) do

            for _, obj in ipairs(podium:GetDescendants()) do

                if obj:IsA("ProximityPrompt") then

                    local action =
                        string.lower(obj.ActionText or "")

                    if string.find(action, "steal", 1, true) then
                        return obj
                    end
                end
            end
        end
    end

    return nil
end

-- ============================================================
-- STEAL PROMPT
-- ============================================================

-- This uses the normal Roblox ProximityPrompt API.
-- Put your own server-side steal logic behind the prompt.
local function fireStealPrompt(prompt)
    if not prompt or not prompt.Parent then
        return false
    end

    if not prompt.Enabled then
        return false
    end

    local character = LocalPlayer.Character

    if not character then
        return false
    end

    local hrp =
        character:FindFirstChild("HumanoidRootPart")

    if not hrp then
        return false
    end

    local promptParent = prompt.Parent

    if promptParent:IsA("BasePart") then
        local distance =
            (hrp.Position - promptParent.Position).Magnitude

        if distance > prompt.MaxActivationDistance then
            return false
        end
    end

    -- Normal Roblox prompt interaction should be handled by
    -- the game's ProximityPrompt / server implementation.
    prompt:InputHoldBegin()

    if prompt.HoldDuration > 0 then
        task.wait(prompt.HoldDuration)
    else
        task.wait()
    end

    prompt:InputHoldEnd()

    return true
end

-- ============================================================
-- THIRD FLOOR PLATFORM
-- ============================================================

local thirdFloorPlatform = nil

local function createThirdFloorPlatform()
    if thirdFloorPlatform then
        thirdFloorPlatform:Destroy()
        thirdFloorPlatform = nil
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        return
    end

    local pos = hrp.Position

    if pos.Y <= 80 and pos.Y >= -20 then
        return
    end

    thirdFloorPlatform = Instance.new("Model")
    thirdFloorPlatform.Name = "ThirdFloorPlatform"
    thirdFloorPlatform.Parent = Workspace

    local platform = Instance.new("Part")

    platform.Name = "Platform"
    platform.Size = Vector3.new(200, 1, 200)
    platform.Position = Vector3.new(
        pos.X,
        pos.Y - 3,
        pos.Z
    )

    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 1

    platform.Parent = thirdFloorPlatform
end

local function removeThirdFloorPlatform()
    if thirdFloorPlatform then
        thirdFloorPlatform:Destroy()
        thirdFloorPlatform = nil
    end
end

-- ============================================================
-- COORDINATES
-- ============================================================

local UPPER = {
    B = {
        {coord = Vector3.new(-487.921448, 16.850713, -75.768013), facing = "NORTH"},
        {coord = Vector3.new(-332.379730, 16.850722, -75.762100), facing = "NORTH"},
        {coord = Vector3.new(-487.134918, 16.850713, -18.094154), facing = "SOUTH"},
        {coord = Vector3.new(-316.300171, 16.850713, -17.845898), facing = "SOUTH"},
    },

    C = {
        {coord = Vector3.new(-330.765381, 16.850713, 31.424425), facing = "NORTH"},
        {coord = Vector3.new(-502.989349, 16.850713, 31.172430), facing = "NORTH"},
        {coord = Vector3.new(-489.077087, 16.850713, 89.010147), facing = "SOUTH"},
        {coord = Vector3.new(-330.908936, 16.850713, 88.930145), facing = "SOUTH"},
    },

    D = {
        {coord = Vector3.new(-331.264893, 16.850713, 138.209167), facing = "NORTH"},
        {coord = Vector3.new(-487.935181, 16.850713, 138.026321), facing = "NORTH"},
        {coord = Vector3.new(-487.774933, 16.850713, 195.882538), facing = "SOUTH"},
        {coord = Vector3.new(-330.799133, 16.850575, 196.022354), facing = "SOUTH"},
    },
}

local LOWER = {
    B = {
        {coord = Vector3.new(-335.725586, -3.048217, -74.984589), facing = "NORTH"},
        {coord = Vector3.new(-503.214233, -3.048217, -75.043137), facing = "NORTH"},
        {coord = Vector3.new(-483.619385, -3.718430, -18.844337), facing = "SOUTH"},
        {coord = Vector3.new(-316.147095, -3.048218, -18.818844), facing = "SOUTH"},
    },

    C = {
        {coord = Vector3.new(-335.985413, -3.048218, 32.051426), facing = "NORTH"},
        {coord = Vector3.new(-503.277008, -3.048217, 31.956175), facing = "NORTH"},
        {coord = Vector3.new(-483.749390, -3.048218, 88.147003), facing = "SOUTH"},
        {coord = Vector3.new(-315.793823, -3.048217, 88.163979), facing = "SOUTH"},
    },

    D = {
        {coord = Vector3.new(-335.476654, -3.048218, 139.001083), facing = "NORTH"},
        {coord = Vector3.new(-503.710083, -3.048217, 138.989883), facing = "NORTH"},
        {coord = Vector3.new(-315.654938, -3.048218, 195.302444), facing = "SOUTH"},
        {coord = Vector3.new(-483.859253, -3.048218, 195.269043), facing = "SOUTH"},
    },
}

local UPPER_Y_THRESHOLD = 7

local TALL_PETS = {
    ["La Secret Combinasion"] = true,
    ["La Jolly Grande"] = true,
}

local TALL_OFFSET = 3

local BASES_LOW = {
    [1] = Vector3.new(-476.52, -2, 220.94),
    [2] = Vector3.new(-476.52, -2, 113.77),
    [3] = Vector3.new(-476.52, -2, 6.18),
    [4] = Vector3.new(-476.52, -2, -101.07),

    [5] = Vector3.new(-342.66, -2, 221.45),
    [6] = Vector3.new(-342.66, -2, 113.41),
    [7] = Vector3.new(-342.66, -2, 6.25),
    [8] = Vector3.new(-342.66, -2, -99.73),
}

local BASES_HIGH = {
    [1] = Vector3.new(-479.51, 18, 220.94),
    [2] = Vector3.new(-479.51, 18, 113.77),
    [3] = Vector3.new(-479.51, 18, 6.18),
    [4] = Vector3.new(-479.51, 18, -101.07),

    [5] = Vector3.new(-339.48, 18, 221.45),
    [6] = Vector3.new(-339.48, 18, 113.41),
    [7] = Vector3.new(-339.48, 18, 6.25),
    [8] = Vector3.new(-339.48, 18, -99.73),
}

local FRONT_Y_LOW = -3.048217
local FRONT_Y_HIGH = 16.850713
local COLUMN_SPLIT_X = -410
local FRONT_Z_CLAMP = 18
local SIDE_NEAR_Z = 45

-- ============================================================
-- COORDINATE HELPERS
-- ============================================================

local function getClosestBaseIdx(pos)
    local closest = 1
    local bestDistance = math.huge

    for i = 1, 8 do
        local base = BASES_LOW[i]

        local dx = pos.X - base.X
        local dz = pos.Z - base.Z

        local distance = dx * dx + dz * dz

        if distance < bestDistance then
            bestDistance = distance
            closest = i
        end
    end

    return closest
end

local function buildFrontCandidate(idx, isUpper, playerZ)
    local base =
        isUpper and BASES_HIGH[idx] or BASES_LOW[idx]

    local frontY =
        isUpper and FRONT_Y_HIGH or FRONT_Y_LOW

    local frontZ =
        math.clamp(
            playerZ - base.Z,
            -FRONT_Z_CLAMP,
            FRONT_Z_CLAMP
        ) + base.Z

    local coord =
        Vector3.new(base.X, frontY, frontZ)

    local faceDir

    if idx <= 4 then
        faceDir = Vector3.new(-1, 0, 0)
    else
        faceDir = Vector3.new(1, 0, 0)
    end

    return coord, faceDir
end

local function plotSides(coordTable, idx)
    local base = BASES_LOW[idx]
    local isWest = idx <= 4

    local output = {}

    for _, coords in pairs(coordTable) do
        for _, data in ipairs(coords) do

            local sameSide =
                ((data.coord.X < COLUMN_SPLIT_X) == isWest)

            local nearBase =
                math.abs(data.coord.Z - base.Z) < SIDE_NEAR_Z

            if sameSide and nearBase then
                output[#output + 1] = data
            end
        end
    end

    return output
end

local function findClosestCoord(petPos, coordTable)
    local best = nil
    local bestKey = nil
    local bestDistance = math.huge

    for skyKey, coords in pairs(coordTable) do
        for _, data in ipairs(coords) do

            local c = data.coord

            local dx = petPos.X - c.X
            local dz = petPos.Z - c.Z

            local distance = math.sqrt(dx * dx + dz * dz)

            if distance < bestDistance then
                bestDistance = distance
                best = data
                bestKey = skyKey
            end
        end
    end

    return best, bestKey
end

-- ============================================================
-- CARPET
-- ============================================================

local CARPET_NAMES = {
    "Flying Carpet",
    "Carpet",
    "Cloud",
    "Witch's Broom",
    "Cupid's Wings",
    "Santa's Sleigh",
    "Magic Carpet",
}

local function equipCarpet()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not hum then
        return nil
    end

    for _, name in ipairs(CARPET_NAMES) do

        local tool =
            char:FindFirstChild(name)

        if not tool and LocalPlayer.Backpack then
            tool = LocalPlayer.Backpack:FindFirstChild(name)
        end

        if tool and tool:IsA("Tool") then

            if tool.Parent ~= char then
                pcall(function()
                    hum:EquipTool(tool)
                end)
            end

            return tool
        end
    end

    return nil
end

local function carpetEngage()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not hum then
        return nil
    end

    pcall(function()
        hum:UnequipTools()
    end)

    task.wait(0.1)

    local tool = equipCarpet()

    task.wait(0.15)

    return tool
end

-- ============================================================
-- MOVEMENT
-- ============================================================

local function vZero(hrp)
    if not hrp then
        return
    end

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local function moveToPosition(hrp, target, speed)
    if not hrp or not hrp.Parent then
        return false
    end

    speed = speed or 150

    local timeout =
        math.max(
            3,
            (target - hrp.Position).Magnitude / speed + 3
        )

    local started = os.clock()

    while hrp.Parent and os.clock() - started < timeout do

        local diff = target - hrp.Position
        local distance = diff.Magnitude

        if distance <= 3 then
            vZero(hrp)
            return true
        end

        local direction = diff.Unit

        hrp.AssemblyLinearVelocity =
            direction * speed

        hrp.AssemblyAngularVelocity =
            Vector3.zero

        RunService.Heartbeat:Wait()
    end

    vZero(hrp)

    return false
end

local function followPath(hrp, path)
    for i = 2, #path do

        if not hrp or not hrp.Parent then
            return false
        end

        if not moveToPosition(hrp, path[i], 150) then
            return false
        end

        task.wait(0.1)
    end

    vZero(hrp)

    return true
end

-- ============================================================
-- QUANTUM CLONER
-- ============================================================

local function findQuantumCloner()
    local char = LocalPlayer.Character

    if char then
        local tool = char:FindFirstChild("Quantum Cloner")

        if tool and tool:IsA("Tool") then
            return tool
        end
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")

    if backpack then
        local tool = backpack:FindFirstChild("Quantum Cloner")

        if tool and tool:IsA("Tool") then
            return tool
        end
    end

    return nil
end

local function doFullTPThenClone(destPos, facingDir)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not hrp or not hum then
        return false
    end

    print("[TP] Engaging carpet")

    carpetEngage()
    vZero(hrp)

    task.wait(0.2)

    -- Move using the normal character physics system.
    local reached = moveToPosition(hrp, destPos, 150)

    if not reached then
        warn("[TP] Failed to reach clone position")
        return false
    end

    if hrp.Parent then
        hrp.CFrame =
            CFrame.lookAt(
                hrp.Position,
                hrp.Position + facingDir
            )

        vZero(hrp)
    end

    task.wait(0.3)

    local cloner = findQuantumCloner()

    if not cloner then
        warn("[TP] Quantum Cloner not found")
        return false
    end

    if cloner.Parent ~= char then
        pcall(function()
            hum:EquipTool(cloner)
        end)

        task.wait(0.15)
    end

    print("[TP] Activating Quantum Cloner")

    pcall(function()
        cloner:Activate()
    end)

    task.wait(0.2)

    -- Your own game's clone system should handle the actual
    -- teleport through its server-side implementation.
    local toolsFrames =
        PlayerGui:FindFirstChild("ToolsFrames")

    if toolsFrames then

        local quantum =
            toolsFrames:FindFirstChild("QuantumCloner")

        if quantum then

            local teleportButton =
                quantum:FindFirstChild("TeleportToClone")

            if teleportButton
                and teleportButton:IsA("GuiButton")
            then

                teleportButton.Visible = true

                print("[TP] Clone UI available")
            end
        end
    end

    return true
end

-- ============================================================
-- STATE
-- ============================================================

local isTeleporting = false
local isStealing = false
local autoTPEnabled = false
local autoTPThread = nil

-- ============================================================
-- NOTIFICATION
-- ============================================================

local function ShowNotification(titleText, bodyText)
    if not PlayerGui then
        return
    end

    local old = PlayerGui:FindFirstChild("MiniNotif")

    if old then
        old:Destroy()
    end

    local sg = Instance.new("ScreenGui")

    sg.Name = "MiniNotif"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.Parent = PlayerGui

    local frame = Instance.new("Frame")

    frame.Size = UDim2.new(0, 290, 0, 54)
    frame.Position = UDim2.new(0.5, -145, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    frame.BorderSizePixel = 0
    frame.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = frame

    local title = Instance.new("TextLabel")

    title.Size = UDim2.new(1, -22, 0, 18)
    title.Position = UDim2.new(0, 16, 0, 7)
    title.BackgroundTransparency = 1
    title.Text = string.upper(tostring(titleText))
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 11
    title.TextColor3 = Color3.fromRGB(150, 150, 150)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local body = Instance.new("TextLabel")

    body.Size = UDim2.new(1, -22, 0, 15)
    body.Position = UDim2.new(0, 16, 0, 27)
    body.BackgroundTransparency = 1
    body.Text = tostring(bodyText)
    body.Font = Enum.Font.GothamMedium
    body.TextSize = 10
    body.TextColor3 = Color3.fromRGB(180, 180, 180)
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.Parent = frame

    task.delay(2.5, function()
        if sg.Parent then
            sg:Destroy()
        end
    end)
end

-- ============================================================
-- MAIN TP
-- ============================================================

local function TPNow()
    if isTeleporting then
        return
    end

    isTeleporting = true

    task.spawn(function()

        local success, err = xpcall(function()

            print("")
            print("[TP] ===========================")
            print("[TP] STARTING")
            print("[TP] ===========================")

            local char = LocalPlayer.Character
            local hrp =
                char and char:FindFirstChild("HumanoidRootPart")

            if not char or not hrp then
                ShowNotification(
                    "TP NOW",
                    "Character not ready"
                )

                return
            end

            if hrp.Position.Y > 80
                or hrp.Position.Y < -20
            then
                createThirdFloorPlatform()
            else
                removeThirdFloorPlatform()
            end

            print("[TP] Scanning pets")

            local pets = scanPets()

            if #pets == 0 then
                ShowNotification(
                    "TP NOW",
                    "No pets found"
                )

                return
            end

            local target = pets[1]

            if not target or not target.position then
                ShowNotification(
                    "TP NOW",
                    "No valid target"
                )

                return
            end

            print(
                string.format(
                    "[TP] Target: %s | %s | %s",
                    target.name,
                    target.genText,
                    target.plot
                )
            )

            ShowNotification(
                "TP NOW",
                "Target: "
                    .. target.name
                    .. " ("
                    .. target.genText
                    .. ")"
            )

            local petPos = target.position

            local adjustedY = petPos.Y

            if TALL_PETS[target.name] then
                adjustedY =
                    petPos.Y - TALL_OFFSET
            end

            local coordTable

            if adjustedY > UPPER_Y_THRESHOLD then
                coordTable = UPPER
            else
                coordTable = LOWER
            end

            local isUpper =
                coordTable == UPPER

            local closestData =
                findClosestCoord(
                    petPos,
                    coordTable
                )

            if not closestData then
                ShowNotification(
                    "TP NOW",
                    "No TP coordinate"
                )

                return
            end

            local idx =
                getClosestBaseIdx(petPos)

            local frontCoord, frontFace =
                buildFrontCandidate(
                    idx,
                    isUpper,
                    hrp.Position.Z
                )

            local bestCoord = frontCoord
            local bestFace = frontFace

            local bestDist =
                (hrp.Position - frontCoord).Magnitude

            for _, data in ipairs(
                plotSides(coordTable, idx)
            ) do

                local distance =
                    (hrp.Position - data.coord).Magnitude

                if distance < bestDist then
                    bestDist = distance
                    bestCoord = data.coord

                    if data.facing == "NORTH" then
                        bestFace =
                            Vector3.new(0, 0, -1)
                    else
                        bestFace =
                            Vector3.new(0, 0, 1)
                    end
                end
            end

            print(
                "[TP] Clone position: "
                    .. tostring(bestCoord)
            )

            local cloneSuccess = false

            for attempt = 1, 3 do

                print(
                    "[TP] Clone attempt "
                        .. tostring(attempt)
                )

                cloneSuccess =
                    doFullTPThenClone(
                        bestCoord,
                        bestFace
                    )

                if cloneSuccess then
                    break
                end

                task.wait(0.5)
            end

            if not cloneSuccess then
                ShowNotification(
                    "TP NOW",
                    "Clone failed"
                )

                return
            end

            ShowNotification(
                "TP NOW",
                "Navigating to "
                    .. target.name
            )

            task.wait(0.3)

            char = LocalPlayer.Character
            hrp =
                char and char:FindFirstChild(
                    "HumanoidRootPart"
                )

            if not hrp then
                return
            end

            local targetPos =
                Vector3.new(
                    petPos.X,
                    petPos.Y + 3,
                    petPos.Z
                )

            local path =
                getSafePath(
                    hrp.Position,
                    targetPos,
                    target.plot
                )

            print(
                "[TP] Path waypoints: "
                    .. tostring(#path)
            )

            local reached =
                followPath(hrp, path)

            if not reached then
                ShowNotification(
                    "TP NOW",
                    "Could not reach target"
                )

                return
            end

            vZero(hrp)

            task.wait(0.3)

            local prompt =
                findStealPrompt(target)

            if not prompt then
                ShowNotification(
                    "TP NOW",
                    "No steal prompt found"
                )

                return
            end

            isStealing = true

            ShowNotification(
                "TP NOW",
                "Interacting with "
                    .. target.name
            )

            local promptSuccess =
                fireStealPrompt(prompt)

            if promptSuccess then
                ShowNotification(
                    "TP NOW",
                    "Prompt activated"
                )
            else
                ShowNotification(
                    "TP NOW",
                    "Prompt unavailable"
                )
            end

            task.wait(0.5)

            isStealing = false

            removeThirdFloorPlatform()

            print("[TP] COMPLETE")

        end, debug.traceback)

        if not success then
            warn("[TP NOW ERROR]")
            warn(err)

            ShowNotification(
                "TP NOW",
                "Error - check console"
            )

            isStealing = false
            removeThirdFloorPlatform()
        end

        isTeleporting = false
    end)
end

-- Make it global if your other scripts call TPNow.
_G.TPNow = TPNow

-- ============================================================
-- AUTO TP
-- ============================================================

local function startAutoTP()
    if autoTPThread then
        return
    end

    autoTPThread = task.spawn(function()

        while autoTPEnabled do

            if not isTeleporting
                and not isStealing
            then
                TPNow()
            end

            task.wait(15)
        end

        autoTPThread = nil
    end)
end

local function stopAutoTP()
    autoTPEnabled = false

    if autoTPThread then
        task.cancel(autoTPThread)
        autoTPThread = nil
    end
end

-- ============================================================
-- GUI
-- ============================================================

loadConfig()

local oldGui =
    PlayerGui:FindFirstChild("TPNOW_GUI")

if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")

gui.Name = "TPNOW_GUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = PlayerGui

local frame = Instance.new("Frame")

frame.Size = UDim2.new(0, 210, 0, 240)
frame.Position = UDim2.new(0.5, -105, 0.15, 0)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(50, 45, 70)
stroke.Thickness = 1
stroke.Parent = frame

-- ============================================================
-- TITLE
-- ============================================================

local title = Instance.new("TextLabel")

title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "TP NOW"
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = frame

local subtitle = Instance.new("TextLabel")

subtitle.Size = UDim2.new(1, -20, 0, 20)
subtitle.Position = UDim2.new(0, 10, 0, 32)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Auto-find best pet"
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 11
subtitle.TextColor3 = Color3.fromRGB(160, 160, 180)
subtitle.TextXAlignment = Enum.TextXAlignment.Center
subtitle.Parent = frame

-- ============================================================
-- TP BUTTON
-- ============================================================

local btn = Instance.new("TextButton")

btn.Size = UDim2.new(1, -20, 0, 40)
btn.Position = UDim2.new(0, 10, 0, 60)
btn.BackgroundColor3 = Color3.fromRGB(52, 211, 153)
btn.Text = "TP NOW"
btn.Font = Enum.Font.GothamBlack
btn.TextSize = 16
btn.TextColor3 = Color3.fromRGB(0, 0, 0)
btn.AutoButtonColor = false
btn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = btn

btn.MouseEnter:Connect(function()
    btn.BackgroundColor3 =
        Color3.fromRGB(80, 230, 180)
end)

btn.MouseLeave:Connect(function()
    btn.BackgroundColor3 =
        Color3.fromRGB(52, 211, 153)
end)

btn.Activated:Connect(function()
    TPNow()
end)

-- ============================================================
-- AUTO TP BUTTON
-- ============================================================

local autoBtn = Instance.new("TextButton")

autoBtn.Size = UDim2.new(1, -20, 0, 35)
autoBtn.Position = UDim2.new(0, 10, 0, 108)
autoBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
autoBtn.Text = "AUTO TP: OFF"
autoBtn.Font = Enum.Font.GothamMedium
autoBtn.TextSize = 13
autoBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
autoBtn.AutoButtonColor = false
autoBtn.Parent = frame

local autoCorner = Instance.new("UICorner")
autoCorner.CornerRadius = UDim.new(0, 8)
autoCorner.Parent = autoBtn

local function updateAutoButton()
    if autoTPEnabled then
        autoBtn.BackgroundColor3 =
            Color3.fromRGB(30, 80, 60)

        autoBtn.Text = "AUTO TP: ON"

        autoBtn.TextColor3 =
            Color3.fromRGB(100, 255, 150)
    else
        autoBtn.BackgroundColor3 =
            Color3.fromRGB(30, 30, 40)

        autoBtn.Text = "AUTO TP: OFF"

        autoBtn.TextColor3 =
            Color3.fromRGB(150, 150, 150)
    end
end

autoBtn.Activated:Connect(function()
    autoTPEnabled = not autoTPEnabled

    configData.autoTPEnabled =
        autoTPEnabled

    saveConfig()

    updateAutoButton()

    if autoTPEnabled then
        ShowNotification(
            "AUTO TP",
            "Enabled - every 15 seconds"
        )

        startAutoTP()
    else
        ShowNotification(
            "AUTO TP",
            "Disabled"
        )

        stopAutoTP()
    end
end)

-- ============================================================
-- AUTO ON LOAD
-- ============================================================

local loadBtn = Instance.new("TextButton")

loadBtn.Size = UDim2.new(1, -20, 0, 30)
loadBtn.Position = UDim2.new(0, 10, 0, 150)
loadBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
loadBtn.Text = "AUTO ON LOAD: OFF"
loadBtn.Font = Enum.Font.GothamMedium
loadBtn.TextSize = 11
loadBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
loadBtn.AutoButtonColor = false
loadBtn.Parent = frame

local loadCorner = Instance.new("UICorner")
loadCorner.CornerRadius = UDim.new(0, 8)
loadCorner.Parent = loadBtn

local function updateLoadButton()
    if configData.autoTPOnLoad then
        loadBtn.BackgroundColor3 =
            Color3.fromRGB(30, 80, 60)

        loadBtn.Text = "AUTO ON LOAD: ON"

        loadBtn.TextColor3 =
            Color3.fromRGB(100, 255, 150)
    else
        loadBtn.BackgroundColor3 =
            Color3.fromRGB(30, 30, 40)

        loadBtn.Text = "AUTO ON LOAD: OFF"

        loadBtn.TextColor3 =
            Color3.fromRGB(150, 150, 150)
    end
end

updateLoadButton()

loadBtn.Activated:Connect(function()
    configData.autoTPOnLoad =
        not configData.autoTPOnLoad

    saveConfig()
    updateLoadButton()

    if configData.autoTPOnLoad then
        ShowNotification(
            "AUTO ON LOAD",
            "Will TP when loaded"
        )
    else
        ShowNotification(
            "AUTO ON LOAD",
            "Disabled"
        )
    end
end)

-- ============================================================
-- STATUS
-- ============================================================

local status = Instance.new("TextLabel")

status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 188)
status.BackgroundTransparency = 1
status.Text = "Ready"
status.Font = Enum.Font.GothamMedium
status.TextSize = 10
status.TextColor3 = Color3.fromRGB(80, 80, 100)
status.TextXAlignment = Enum.TextXAlignment.Center
status.Parent = frame

-- ============================================================
-- FLOOR LABEL
-- ============================================================

local floorLabel = Instance.new("TextLabel")

floorLabel.Size = UDim2.new(1, -20, 0, 18)
floorLabel.Position = UDim2.new(0, 10, 0, 212)
floorLabel.BackgroundTransparency = 1
floorLabel.Text = "Floor: Ground"
floorLabel.Font = Enum.Font.GothamMedium
floorLabel.TextSize = 9
floorLabel.TextColor3 = Color3.fromRGB(60, 60, 80)
floorLabel.TextXAlignment = Enum.TextXAlignment.Center
floorLabel.Parent = frame

-- ============================================================
-- STATUS LOOP
-- ============================================================

task.spawn(function()

    while gui.Parent do

        if isTeleporting then

            status.Text = "Teleporting..."
            status.TextColor3 =
                Color3.fromRGB(255, 150, 100)

        elseif isStealing then

            status.Text = "Interacting..."
            status.TextColor3 =
                Color3.fromRGB(255, 150, 100)

        else

            local pets = scanPets()

            if #pets > 0 then

                status.Text =
                    "Best: "
                    .. pets[1].name
                    .. " ("
                    .. pets[1].genText
                    .. ")"

                status.TextColor3 =
                    Color3.fromRGB(160, 160, 180)
            else

                status.Text = "Scanning..."

                status.TextColor3 =
                    Color3.fromRGB(80, 80, 100)
            end
        end

        local char = LocalPlayer.Character
        local hrp =
            char and char:FindFirstChild(
                "HumanoidRootPart"
            )

        if hrp then

            local y = hrp.Position.Y

            if y > 80 then

                floorLabel.Text = "Floor: 3rd"

                floorLabel.TextColor3 =
                    Color3.fromRGB(200, 150, 100)

            elseif y > 20 then

                floorLabel.Text = "Floor: 2nd"

                floorLabel.TextColor3 =
                    Color3.fromRGB(150, 200, 150)

            elseif y > -10 then

                floorLabel.Text = "Floor: Ground"

                floorLabel.TextColor3 =
                    Color3.fromRGB(60, 60, 80)

            else

                floorLabel.Text = "Floor: Basement"

                floorLabel.TextColor3 =
                    Color3.fromRGB(100, 100, 150)
            end
        end

        task.wait(0.5)
    end
end)

-- ============================================================
-- DRAGGING
-- ============================================================

local dragging = false
local dragStart
local startPos

frame.InputBegan:Connect(function(input)

    if input.UserInputType
        == Enum.UserInputType.MouseButton1
    then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

frame.InputEnded:Connect(function(input)

    if input.UserInputType
        == Enum.UserInputType.MouseButton1
    then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)

    if not dragging then
        return
    end

    if input.UserInputType
        ~= Enum.UserInputType.MouseMovement
    then
        return
    end

    local delta =
        input.Position - dragStart

    frame.Position =
        UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
end)

-- ============================================================
-- INITIAL AUTO LOAD
-- ============================================================

task.spawn(function()

    if configData.autoTPOnLoad then

        print(
            "[Config] Auto TP on load enabled"
        )

        task.wait(3)

        if LocalPlayer.Character then
            TPNow()
        end
    end
end)

print("[TP NOW] Loaded successfully")
