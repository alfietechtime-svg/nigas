on this local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Wait for PlayerGui to load properly
local PlayerGui
local function waitForPlayerGui()
    local attempts = 0
    while attempts < 50 do
        PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if PlayerGui then break end
        task.wait(0.1)
        attempts = attempts + 1
    end
    if not PlayerGui then
        PlayerGui = Instance.new("ScreenGui")
        PlayerGui.Name = "PlayerGui"
        PlayerGui.Parent = LocalPlayer
    end
    return PlayerGui
end

PlayerGui = waitForPlayerGui()

-- ============================================================
-- CONFIG SYSTEM
-- ============================================================
local CONFIG_KEY = "TPNOW_Config"
local configData = {
    autoTPOnLoad = false,
    autoTPEnabled = false
}

-- Load config
local function loadConfig()
    local success, data = pcall(function()
        return HttpService:GetAsync(CONFIG_KEY)
    end)
    
    if success and data then
        local decoded = HttpService:JSONDecode(data)
        if decoded then
            configData.autoTPOnLoad = decoded.autoTPOnLoad or false
            configData.autoTPEnabled = decoded.autoTPEnabled or false
            print("[Config] Loaded: autoTPOnLoad=" .. tostring(configData.autoTPOnLoad))
        end
    else
        print("[Config] No saved config found, using defaults")
    end
end

-- Save config
local function saveConfig()
    local success, err = pcall(function()
        local json = HttpService:JSONEncode(configData)
        HttpService:SetAsync(CONFIG_KEY, json)
    end)
    
    if success then
        print("[Config] Saved successfully")
    else
        print("[Config] Failed to save: " .. tostring(err))
    end
end

-- ============================================================
-- MONEY FORMATTER
-- ============================================================
local function fmtMoney(n)
    if n >= 1e9  then return string.format("$%.2fB", n/1e9)
    elseif n >= 1e6 then return string.format("$%.2fM", n/1e6)
    elseif n >= 1e3 then return string.format("$%.1fK", n/1e3)
    end
    return "$" .. tostring(n)
end

-- EXTRACT GENERATION FROM PET
local function extractGenerationFromPet(petModel)
    if not petModel then return 0, "0" end
    
    local debris = Workspace:FindFirstChild("Debris")
    if debris then
        for _, part in pairs(debris:GetChildren()) do
            if part.Name == "FastOverheadTemplate" and part:IsA("BasePart") then
                local animalOverhead = part:FindFirstChild("AnimalOverhead")
                if animalOverhead and animalOverhead:IsA("SurfaceGui") then
                    local generationLabel = animalOverhead:FindFirstChild("Generation")
                    local displayNameLabel = animalOverhead:FindFirstChild("DisplayName")
                    if generationLabel and displayNameLabel and displayNameLabel.Text == petModel.Name then
                        local generationText = generationLabel.Text or ""
                        if generationText ~= "" then
                            local stripped = generationText:gsub("^%$", "")
                            local firstValue = stripped:match("^([^%s/]+)")
                            if firstValue then
                                local cleanText = firstValue:gsub(" ", "")
                                local multiplier = 1
                                local value = cleanText
                                if cleanText:find("T") then multiplier = 1e12; value = cleanText:gsub("T","")
                                elseif cleanText:find("B") then multiplier = 1e9;  value = cleanText:gsub("B","")
                                elseif cleanText:find("M") then multiplier = 1e6;  value = cleanText:gsub("M","")
                                elseif cleanText:find("K") then multiplier = 1e3;  value = cleanText:gsub("K","")
                                end
                                local numValue = tonumber(value)
                                if numValue then return (numValue * multiplier), stripped end
                            end
                        end
                    end
                end
            end
        end
    end
    
    local genAttr = petModel:GetAttribute("Generation")
    if genAttr and type(genAttr) == "number" and genAttr > 0 then
        return genAttr, fmtMoney(genAttr):gsub("^%$", "")
    end
    
    for _, child in ipairs(petModel:GetChildren()) do
        if child:IsA("NumberValue") and (child.Name == "Generation" or child.Name == "Value" or child.Name == "Gen") then
            if child.Value > 0 then
                return child.Value, fmtMoney(child.Value):gsub("^%$", "")
            end
        end
    end
    
    return 0, "0"
end

-- GET MUTATION
local function getMutation(petModel)
    local attrMut = petModel:GetAttribute("Mutation")
    if attrMut and attrMut ~= "" then return tostring(attrMut) end
    
    local mutObj = petModel:FindFirstChild("Mutation")
    if mutObj then
        if mutObj:IsA("StringValue") and mutObj.Value ~= "" then
            return mutObj.Value
        elseif mutObj:IsA("ObjectValue") and mutObj.Value then
            return mutObj.Value.Name
        end
    end
    
    return "None"
end

-- CHECK IF PLAYER'S OWN BASE
local function isPlayerBase(plot)
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yourBase = sign:FindFirstChild("YourBase")
        if yourBase and yourBase.Enabled then return true end
    end
    return false
end

-- GET BASE BOUNDARIES (to avoid walking through bases)
local function getBaseBoundaries(plotName)
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return nil end
    
    -- Get the base's bounding box
    local minX, maxX = math.huge, -math.huge
    local minZ, maxZ = math.huge, -math.huge
    
    for _, part in ipairs(plot:GetDescendants()) do
        if part:IsA("BasePart") then
            local pos = part.Position
            local size = part.Size
            local halfX = size.X / 2
            local halfZ = size.Z / 2
            minX = math.min(minX, pos.X - halfX)
            maxX = math.max(maxX, pos.X + halfX)
            minZ = math.min(minZ, pos.Z - halfZ)
            maxZ = math.max(maxZ, pos.Z + halfZ)
        end
    end
    
    return {minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ}
end

-- Check if a position is inside any base (except the target base)
local function isInsideOtherBase(pos, targetPlot)
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return false end
    
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") and plot.Name ~= targetPlot then
            local boundaries = getBaseBoundaries(plot.Name)
            if boundaries then
                if pos.X >= boundaries.minX and pos.X <= boundaries.maxX and
                   pos.Z >= boundaries.minZ and pos.Z <= boundaries.maxZ then
                    return true
                end
            end
        end
    end
    return false
end

-- Get safe path to pet (avoiding other bases)
local function getSafePath(startPos, targetPos, targetPlot)
    local path = {startPos}
    local currentPos = startPos
    
    -- Direct path check
    local midPos = (startPos + targetPos) / 2
    if not isInsideOtherBase(midPos, targetPlot) then
        -- Direct path is safe
        table.insert(path, targetPos)
        return path
    end
    
    -- Find path around bases
    local waypoints = {}
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return {startPos, targetPos} end
    
    -- Try different offset directions
    local offsets = {
        Vector3.new(10, 0, 0),
        Vector3.new(-10, 0, 0),
        Vector3.new(0, 0, 10),
        Vector3.new(0, 0, -10),
        Vector3.new(15, 0, 15),
        Vector3.new(-15, 0, 15),
        Vector3.new(15, 0, -15),
        Vector3.new(-15, 0, -15),
    }
    
    local bestPath = nil
    local bestDist = math.huge
    
    for _, offset in ipairs(offsets) do
        local testPath = {}
        local p1 = startPos + offset
        local p2 = targetPos + offset
        
        if not isInsideOtherBase(p1, targetPlot) and not isInsideOtherBase(p2, targetPlot) then
            -- Check if path between waypoints is clear
            local mid1 = (startPos + p1) / 2
            local mid2 = (p1 + p2) / 2
            local mid3 = (p2 + targetPos) / 2
            
            if not isInsideOtherBase(mid1, targetPlot) and 
               not isInsideOtherBase(mid2, targetPlot) and 
               not isInsideOtherBase(mid3, targetPlot) then
                table.insert(testPath, startPos)
                table.insert(testPath, p1)
                table.insert(testPath, p2)
                table.insert(testPath, targetPos)
                
                local totalDist = (startPos - p1).Magnitude + (p1 - p2).Magnitude + (p2 - targetPos).Magnitude
                if totalDist < bestDist then
                    bestDist = totalDist
                    bestPath = testPath
                end
            end
        end
    end
    
    if bestPath then
        return bestPath
    end
    
    -- Fallback: go high and come down
    local highPoint = Vector3.new(
        (startPos.X + targetPos.X) / 2,
        startPos.Y + 20,
        (startPos.Z + targetPos.Z) / 2
    )
    
    if not isInsideOtherBase(highPoint, targetPlot) then
        return {startPos, highPoint, targetPos}
    end
    
    -- Final fallback: just direct path
    return {startPos, targetPos}
end

-- WORKING SCANNER
local function scanPets()
    local results = {}
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return results end
    
    for _, plot in ipairs(plots:GetChildren()) do
        if not plot:IsA("Model") then
            -- skip
        elseif not isPlayerBase(plot) then
            for _, desc in ipairs(plot:GetDescendants()) do
                if desc:IsA("Model") then
                    local hasHumanoid = desc:FindFirstChildOfClass("Humanoid")
                    local hasHRP = desc:FindFirstChild("HumanoidRootPart")
                    
                    if hasHumanoid or hasHRP then
                        local gen, genText = extractGenerationFromPet(desc)
                        if gen > 0 then
                            local hrp = desc:FindFirstChild("HumanoidRootPart")
                            local pos = hrp and hrp.Position or desc:GetPivot().Position
                            
                            table.insert(results, {
                                name = desc.Name or "Unknown",
                                gen = gen,
                                genText = genText,
                                mutation = getMutation(desc),
                                position = pos,
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
    
    table.sort(results, function(a, b) return (a.gen or 0) > (b.gen or 0) end)
    return results
end

-- FIND STEAL PROMPT
local function findStealPrompt(pet)
    if not pet or not pet.model then return nil end
    
    for _, d in ipairs(pet.model:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.ActionText and string.find(string.lower(d.ActionText), "steal") then
            return d
        end
    end
    
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local plot = plots:FindFirstChild(pet.plot)
    if not plot then return nil end
    
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if podiums then
        for _, podium in ipairs(podiums:GetChildren()) do
            for _, d in ipairs(podium:GetDescendants()) do
                if d:IsA("ProximityPrompt") and d.ActionText and string.find(string.lower(d.ActionText), "steal") then
                    return d
                end
            end
        end
    end
    
    return nil
end

-- FIRE STEAL PROMPT
local function fireStealPrompt(prompt)
    if not prompt or not prompt.Parent then return end
    
    pcall(function() prompt.HoldDuration = 0 end)
    pcall(function() prompt.MaxActivationDistance = math.huge end)
    
    if typeof(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt)
    end
    
    local ok, conns = pcall(getconnections, prompt.Triggered)
    if ok and type(conns) == "table" then
        for _, c in ipairs(conns) do
            pcall(function() if c.Fire then c:Fire() end end)
        end
    end
end

-- ============================================================
-- 3RD FLOOR PLATFORM (NO CAMERA NOCLIP)
-- ============================================================

local thirdFloorPlatform = nil
local platformParts = {}

-- Create platform for 3rd floor
local function createThirdFloorPlatform()
    if thirdFloorPlatform then
        thirdFloorPlatform:Destroy()
        thirdFloorPlatform = nil
    end
    platformParts = {}
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local pos = hrp.Position
    local isThirdFloor = pos.Y > 80 or pos.Y < -20
    
    if not isThirdFloor then
        print("[3rd Floor] Not on 3rd floor, skipping platform")
        return
    end
    
    print("[3rd Floor] Creating platform...")
    
    thirdFloorPlatform = Instance.new("Model")
    thirdFloorPlatform.Name = "ThirdFloorPlatform"
    thirdFloorPlatform.Parent = workspace
    
    local platform = Instance.new("Part")
    platform.Name = "Platform"
    platform.Size = Vector3.new(200, 1, 200)
    platform.Position = Vector3.new(pos.X, pos.Y - 3, pos.Z)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 1
    platform.Material = Enum.Material.Plastic
    platform.Parent = thirdFloorPlatform
    table.insert(platformParts, platform)
    
    local wallPositions = {
        {pos.X + 100, pos.Y + 5, pos.Z},
        {pos.X - 100, pos.Y + 5, pos.Z},
        {pos.X, pos.Y + 5, pos.Z + 100},
        {pos.X, pos.Y + 5, pos.Z - 100},
    }
    
    for _, wp in ipairs(wallPositions) do
        local wall = Instance.new("Part")
        wall.Name = "Wall"
        wall.Size = Vector3.new(2, 10, 200)
        wall.Position = Vector3.new(wp[1], wp[2], wp[3])
        wall.Anchored = true
        wall.CanCollide = true
        wall.Transparency = 1
        wall.Parent = thirdFloorPlatform
        table.insert(platformParts, wall)
    end
    
    print("[3rd Floor] Platform created")
end

local function removeThirdFloorPlatform()
    if thirdFloorPlatform then
        thirdFloorPlatform:Destroy()
        thirdFloorPlatform = nil
    end
    platformParts = {}
end

-- ============================================================
-- SXE TP COORDINATES SYSTEM
-- ============================================================

local UPPER = {
    B = {
        {coord=Vector3.new(-487.921448,16.850713,-75.768013), facing="NORTH"},
        {coord=Vector3.new(-332.379730,16.850722,-75.762100), facing="NORTH"},
        {coord=Vector3.new(-487.134918,16.850713,-18.094154), facing="SOUTH"},
        {coord=Vector3.new(-316.300171,16.850713,-17.845898), facing="SOUTH"}
    },
    C = {
        {coord=Vector3.new(-330.765381,16.850713,31.424425), facing="NORTH"},
        {coord=Vector3.new(-502.989349,16.850713,31.172430), facing="NORTH"},
        {coord=Vector3.new(-489.077087,16.850713,89.010147), facing="SOUTH"},
        {coord=Vector3.new(-330.908936,16.850713,88.930145), facing="SOUTH"}
    },
    D = {
        {coord=Vector3.new(-331.264893,16.850713,138.209167), facing="NORTH"},
        {coord=Vector3.new(-487.935181,16.850713,138.026321), facing="NORTH"},
        {coord=Vector3.new(-487.774933,16.850713,195.882538), facing="SOUTH"},
        {coord=Vector3.new(-330.799133,16.850575,196.022354), facing="SOUTH"}
    },
}

local LOWER = {
    B = {
        {coord=Vector3.new(-335.725586,-3.048217,-74.984589), facing="NORTH"},
        {coord=Vector3.new(-503.214233,-3.048217,-75.043137), facing="NORTH"},
        {coord=Vector3.new(-483.619385,-3.718430,-18.844337), facing="SOUTH"},
        {coord=Vector3.new(-316.147095,-3.048218,-18.818844), facing="SOUTH"}
    },
    C = {
        {coord=Vector3.new(-335.985413,-3.048218,32.051426), facing="NORTH"},
        {coord=Vector3.new(-503.277008,-3.048217,31.956175), facing="NORTH"},
        {coord=Vector3.new(-483.749390,-3.048218,88.147003), facing="SOUTH"},
        {coord=Vector3.new(-315.793823,-3.048217,88.163979), facing="SOUTH"}
    },
    D = {
        {coord=Vector3.new(-335.476654,-3.048218,139.001083), facing="NORTH"},
        {coord=Vector3.new(-503.710083,-3.048218,138.989883), facing="NORTH"},
        {coord=Vector3.new(-315.654938,-3.048218,195.302444), facing="SOUTH"},
        {coord=Vector3.new(-483.859253,-3.048218,195.269043), facing="SOUTH"}
    },
}

local UPPER_Y_THRESHOLD = 7
local TALL_PETS = { ["La Secret Combinasion"]=true, ["La Jolly Grande"]=true }
local TALL_OFFSET = 3

local BASES_LOW = {
    [1]=Vector3.new(-476.52,-2,220.94), [2]=Vector3.new(-476.52,-2,113.77),
    [3]=Vector3.new(-476.52,-2,6.18), [4]=Vector3.new(-476.52,-2,-101.07),
    [5]=Vector3.new(-342.66,-2,221.45), [6]=Vector3.new(-342.66,-2,113.41),
    [7]=Vector3.new(-342.66,-2,6.25), [8]=Vector3.new(-342.66,-2,-99.73),
}

local BASES_HIGH = {
    [1]=Vector3.new(-479.51,18,220.94), [2]=Vector3.new(-479.51,18,113.77),
    [3]=Vector3.new(-479.51,18,6.18), [4]=Vector3.new(-479.51,18,-101.07),
    [5]=Vector3.new(-339.48,18,221.45), [6]=Vector3.new(-339.48,18,113.41),
    [7]=Vector3.new(-339.48,18,6.25), [8]=Vector3.new(-339.48,18,-99.73),
}

local FRONT_Y_LOW = -3.048217
local FRONT_Y_HIGH = 16.850713
local COLUMN_SPLIT_X = -410
local FRONT_Z_CLAMP = 18
local SIDE_NEAR_Z = 45

local function getClosestBaseIdx(pos)
    local closest, dist = 1, math.huge
    for i = 1, 8 do
        local b = BASES_LOW[i]
        local d = (pos.X - b.X)^2 + (pos.Z - b.Z)^2
        if d < dist then dist = d; closest = i end
    end
    return closest
end

local function buildFrontCandidate(idx, isUpper, playerZ)
    local base = isUpper and BASES_HIGH[idx] or BASES_LOW[idx]
    local frontY = isUpper and FRONT_Y_HIGH or FRONT_Y_LOW
    local frontZ = math.clamp(playerZ - base.Z, -FRONT_Z_CLAMP, FRONT_Z_CLAMP) + base.Z
    local coord = Vector3.new(base.X, frontY, frontZ)
    local faceDir = (idx <= 4) and Vector3.new(-1, 0, 0) or Vector3.new(1, 0, 0)
    return coord, faceDir
end

local function plotSides(coordTable, idx)
    local base = BASES_LOW[idx]
    local isWest = idx <= 4
    local out = {}
    for skyKey, coords in pairs(coordTable) do
        for _, data in ipairs(coords) do
            if ((data.coord.X < COLUMN_SPLIT_X) == isWest)
               and math.abs(data.coord.Z - base.Z) < SIDE_NEAR_Z then
                out[#out + 1] = data
            end
        end
    end
    return out
end

local function findClosestCoord(petPos, coordTable)
    local best, bestKey, bestDist = nil, nil, math.huge
    for skyKey, coords in pairs(coordTable) do
        for _, data in ipairs(coords) do
            local c = data.coord
            local d = math.sqrt((petPos.X - c.X)^2 + (petPos.Z - c.Z)^2)
            if d < bestDist then bestDist = d; best = data; bestKey = skyKey end
        end
    end
    return best, bestKey
end

-- ============================================================
-- NETWORK REMOTE RESOLVER
-- ============================================================
local remoteCache = {}
_G.__tpUseItemRemote = nil
_G.__tpOnTelRemote = nil

local function resolveRemote(name)
    local pkg = ReplicatedStorage:FindFirstChild("Packages")
    local net = pkg and pkg:FindFirstChild("Net")
    if not net then return nil end
    
    for _, obj in ipairs(net:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            if obj.Name == name then
                remoteCache[name] = obj
                return obj
            end
        end
    end
    return nil
end

local function getRemote(name)
    if remoteCache[name] and remoteCache[name].Parent then
        return remoteCache[name]
    end
    return resolveRemote(name)
end

-- ============================================================
-- TP MOVEMENT SYSTEM
-- ============================================================

local function vZero(hrp)
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function equipCarpet()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    
    local CARPET_NAMES = { "Flying Carpet", "Carpet", "Cloud", "Witch's Broom", "Cupid's Wings", "Santa's Sleigh", "Magic Carpet" }
    for _, name in ipairs(CARPET_NAMES) do
        local tool = (char and char:FindFirstChild(name)) or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild(name))
        if tool and tool:IsA("Tool") then
            if tool.Parent ~= char then pcall(function() hum:EquipTool(tool) end) end
            return name
        end
    end
    return nil
end

local function carpetEngage()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum then return nil end
    
    pcall(function() hum:UnequipTools() end)
    task.wait(0.1)
    local cn = equipCarpet()
    task.wait(0.15)
    return cn
end

local function velMoveThrough(hrp, waypoints, speed)
    if not hrp or not hrp.Parent or #waypoints == 0 then return end
    local SPEED = speed or 150
    local ARRIVE = 3
    local MAX_CLIMB = 60
    
    local wpIdx = 1
    local done = false
    local conn
    
    local function finish()
        if done then return end
        done = true
        if hrp and hrp.Parent then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
        if conn then conn:Disconnect() end
    end
    
    local lastDist, stall = math.huge, 0
    
    conn = RunService.Heartbeat:Connect(function()
        if not hrp or not hrp.Parent or done then
            if conn then conn:Disconnect() end
            return
        end
        
        equipCarpet()
        local target = waypoints[wpIdx]
        local diff = target - hrp.Position
        local mag = diff.Magnitude
        
        if mag < ARRIVE then
            wpIdx = wpIdx + 1
            if wpIdx > #waypoints then finish(); return end
            lastDist, stall = math.huge, 0
            target = waypoints[wpIdx]
            diff = target - hrp.Position
            mag = diff.Magnitude
        end
        
        if mag > lastDist - 0.05 then stall = stall + 1 else stall = 0 end
        lastDist = mag
        if stall >= 18 then finish(); return end
        
        if mag >= 0.1 then
            local dir = diff.Unit
            local _vy = dir.Y * SPEED
            if _vy > MAX_CLIMB then _vy = MAX_CLIMB end
            hrp.AssemblyLinearVelocity = Vector3.new(dir.X * SPEED, _vy, dir.Z * SPEED)
        end
    end)
    
    local totalDist = 0
    local prev = hrp.Position
    for _, wp in ipairs(waypoints) do
        totalDist = totalDist + (prev - wp).Magnitude
        prev = wp
    end
    local timeout = totalDist / math.min(SPEED, 150) + 2
    local elapsed = 0
    while not done and elapsed < timeout do
        task.wait(0.05)
        elapsed = elapsed + 0.05
    end
    finish()
    vZero(hrp)
end

-- ============================================================
-- CLONE TELEPORT (DOES FULL TP FIRST, THEN CLONES)
-- ============================================================
local function doFullTPThenClone(destPos, facingDir, petPos, target)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end
    
    print("[TP] Engaging carpet...")
    carpetEngage()
    vZero(hrp)
    task.wait(0.3)
    
    if hrp and hrp.Parent then
        hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + facingDir)
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    
    print("[TP] Moving to sky position: " .. tostring(destPos))
    local route = { destPos }
    velMoveThrough(hrp, route, 150)
    
    if hrp and hrp.Parent then
        hrp.CFrame = CFrame.lookAt(destPos, destPos + facingDir)
        vZero(hrp)
    end
    
    local syncFrames = 10
    local syncConn
    syncConn = RunService.Heartbeat:Connect(function()
        if not hrp or not hrp.Parent then syncConn:Disconnect(); return end
        syncFrames = syncFrames - 1
        hrp.CFrame = CFrame.lookAt(destPos, destPos + facingDir)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if syncFrames <= 0 then syncConn:Disconnect() end
    end)
    
    print("[TP] Stabilizing position...")
    for _ = 1, 30 do
        task.wait(0.05)
        if hum.FloorMaterial ~= Enum.Material.Air then break end
    end
    
    print("[TP] Position reached! Now cloning into base...")
    
    local cloner = (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Quantum Cloner"))
                or char:FindFirstChild("Quantum Cloner")
    if not cloner then
        print("[TP] No Quantum Cloner found!")
        return false
    end
    
    if cloner.Parent ~= char then
        pcall(function() hum:EquipTool(cloner) end)
        task.wait(0.05)
    end
    
    local prePos = hrp.Position
    
    print("[TP] Activating Quantum Cloner...")
    pcall(function() cloner:Activate() end)
    task.wait(0.1)
    
    local ToolsFrames = PlayerGui:FindFirstChild("ToolsFrames")
    if ToolsFrames then
        local QuantumCloner = ToolsFrames:FindFirstChild("QuantumCloner")
        if QuantumCloner then
            local TeleportToClone = QuantumCloner:FindFirstChild("TeleportToClone")
            if TeleportToClone then
                print("[TP] Found TeleportToClone button, clicking...")
                TeleportToClone.Visible = true
                task.wait(0.05)
                
                if typeof(firesignal) == "function" then
                    pcall(function() firesignal(TeleportToClone.MouseButton1Click) end)
                    pcall(function() firesignal(TeleportToClone.MouseButton1Up) end)
                    pcall(function() firesignal(TeleportToClone.Activated) end)
                else
                    local inset = GuiService:GetGuiInset()
                    local pos = TeleportToClone.AbsolutePosition + TeleportToClone.AbsoluteSize / 2 + inset
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                    task.wait()
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                end
                task.wait(0.2)
            end
        end
    end
    
    local onTel = getRemote("QuantumCloner/OnTeleport")
    if onTel then
        print("[TP] Firing teleport remote...")
        pcall(function() onTel:FireServer() end)
        task.wait(0.2)
    end
    
    local newHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if newHrp and prePos then
        local dx = newHrp.Position.X - prePos.X
        local dz = newHrp.Position.Z - prePos.Z
        if dx*dx + dz*dz > 4 then
            print("[TP] Teleported into clone! Distance: " .. math.sqrt(dx*dx + dz*dz))
            return true
        end
    end
    
    print("[TP] Teleport into clone failed")
    return false
end

-- ============================================================
-- MAIN TP FUNCTION
-- ============================================================
local isTeleporting = false
local isStealing = false
local autoTPEnabled = false
local autoTPThread = nil

local function startAutoTP()
    if autoTPThread then return end
    
    autoTPThread = task.spawn(function()
        while autoTPEnabled and LocalPlayer.Character do
            if not isTeleporting and not isStealing then
                print("[AutoTP] Running auto TP...")
                TPNow()
            end
            task.wait(15)
        end
        autoTPThread = nil
    end)
end

function TPNow()
    if isTeleporting then return end
    isTeleporting = true
    
    task.spawn(function()
        pcall(function()
            print("\n[TP] ===== STARTING TP =====")
            
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if hrp.Position.Y > 80 or hrp.Position.Y < -20 then
                    print("[TP] 3rd floor detected, creating platform")
                    createThirdFloorPlatform()
                else
                    removeThirdFloorPlatform()
                end
            end
            
            print("[TP] Scanning for pets...")
            local pets = scanPets()
            if #pets == 0 then
                ShowNotification("TP NOW", "No pets found!")
                isTeleporting = false
                return
            end
            
            local target = pets[1]
            if not target or not target.position then
                ShowNotification("TP NOW", "No valid pet target")
                isTeleporting = false
                return
            end
            
            print(string.format("[TP] Target: %s | %s in plot %s", target.name, target.genText, target.plot))
            ShowNotification("TP NOW", "Target: " .. target.name .. " (" .. target.genText .. ")")
            
            if not char or not hrp then
                ShowNotification("TP NOW", "Character not ready")
                isTeleporting = false
                return
            end
            
            local petPos = target.position
            local petName = target.name
            
            local adjY = petPos.Y
            if TALL_PETS[petName] then adjY = petPos.Y - TALL_OFFSET end
            local coordTable = adjY > UPPER_Y_THRESHOLD and UPPER or LOWER
            local isUpper = (coordTable == UPPER)
            
            local closestData, skyKey = findClosestCoord(petPos, coordTable)
            if not closestData then
                print("[TP] No sky coordinate found!")
                isTeleporting = false
                return
            end
            
            local destPos = closestData.coord
            local facingDir = closestData.facing == "NORTH" and Vector3.new(0, 0, -1) or Vector3.new(0, 0, 1)
            
            local idx = getClosestBaseIdx(petPos)
            local frontCoord, frontFace = buildFrontCandidate(idx, isUpper, hrp.Position.Z)
            local bestCoord, bestFace = frontCoord, frontFace
            local bestDist = (hrp.Position - frontCoord).Magnitude
            
            for _, d in ipairs(plotSides(coordTable, idx)) do
                local dd = (hrp.Position - d.coord).Magnitude
                if dd < bestDist then
                    bestDist = dd
                    bestCoord = d.coord
                    bestFace = d.facing == "NORTH" and Vector3.new(0, 0, -1) or Vector3.new(0, 0, 1)
                end
            end
            
            destPos = bestCoord
            facingDir = bestFace
            
            print(string.format("[TP] TP Position: %s", tostring(destPos)))
            print(string.format("[TP] Facing: %s", tostring(facingDir)))
            
            local cloneSuccess = false
            for attempt = 1, 3 do
                cloneSuccess = doFullTPThenClone(destPos, facingDir, petPos, target)
                if cloneSuccess then break end
                print("[TP] Clone attempt " .. attempt .. " failed, retrying...")
                task.wait(0.5)
            end
            
            if not cloneSuccess then
                print("[TP] All clone attempts failed!")
                ShowNotification("TP NOW", "Clone failed!")
                isTeleporting = false
                return
            end
            
            print("[TP] Clone successful! Navigating to pet safely...")
            ShowNotification("TP NOW", "Walking to " .. target.name .. "...")
            
            -- Get safe path avoiding other bases
            local startPos = hrp.Position
            local targetPos = Vector3.new(petPos.X, petPos.Y + 3, petPos.Z)
            local safePath = getSafePath(startPos, targetPos, target.plot)
            
            print("[TP] Safe path has " .. #safePath .. " waypoints")
            
            -- Follow safe path
            for i = 1, #safePath - 1 do
                local wpStart = safePath[i]
                local wpEnd = safePath[i + 1]
                local dist = (wpEnd - wpStart).Magnitude
                
                if dist > 0 then
                    -- Move to each waypoint
                    local t0 = os.clock()
                    while hrp.Parent and os.clock() - t0 < (dist / 160) + 2 do
                        equipCarpet()
                        local diff = wpEnd - hrp.Position
                        local mag = diff.Magnitude
                        
                        if mag < 4 then
                            break
                        end
                        
                        local dir = diff.Unit
                        hrp.AssemblyLinearVelocity = Vector3.new(dir.X * 160, 0, dir.Z * 160)
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        
                        RunService.Heartbeat:Wait()
                    end
                    
                    vZero(hrp)
                    task.wait(0.1)
                end
            end
            
            print("[TP] Reached pet")
            vZero(hrp)
            
            task.wait(0.3)
            
            local prompt = findStealPrompt(target)
            if prompt then
                print("[TP] Stealing...")
                isStealing = true
                ShowNotification("TP NOW", "Stealing " .. target.name .. "...")
                
                fireStealPrompt(prompt)
                
                local stealTimer = 0
                while stealTimer < 5 do
                    if LocalPlayer:GetAttribute("Stealing") then
                        print("[TP] Stole " .. target.name .. "!")
                        ShowNotification("TP NOW", "Stole " .. target.name .. "!")
                        isStealing = false
                        break
                    end
                    task.wait(0.1)
                    stealTimer = stealTimer + 0.1
                end
                
                if stealTimer >= 5 and not LocalPlayer:GetAttribute("Stealing") then
                    print("[TP] Steal may have failed")
                    ShowNotification("TP NOW", "Steal failed, try again")
                end
            else
                print("[TP] No steal prompt found")
                ShowNotification("TP NOW", "No steal prompt found")
            end
            
            removeThirdFloorPlatform()
            
            print("[TP] ===== TP COMPLETE =====")
        end)
        
        isTeleporting = false
    end)
end

-- NOTIFICATION
function ShowNotification(title, text)
    local old = PlayerGui:FindFirstChild("MiniNotif")
    if old then old:Destroy() end
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "MiniNotif"
    sg.ResetOnSpawn = false
    sg.Parent = PlayerGui
    
    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0, 290, 0, 54)
    f.Position = UDim2.new(0.5, -145, 0, 80)
    f.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    f.BackgroundTransparency = 0
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 9)
    
    local t1 = Instance.new("TextLabel", f)
    t1.Size = UDim2.new(1, -22, 0, 18)
    t1.Position = UDim2.new(0, 16, 0, 7)
    t1.BackgroundTransparency = 1
    t1.Text = title:upper()
    t1.Font = Enum.Font.GothamBlack
    t1.TextSize = 11
    t1.TextColor3 = Color3.fromRGB(150, 150, 150)
    t1.TextXAlignment = Enum.TextXAlignment.Left
    
    local t2 = Instance.new("TextLabel", f)
    t2.Size = UDim2.new(1, -22, 0, 15)
    t2.Position = UDim2.new(0, 16, 0, 27)
    t2.BackgroundTransparency = 1
    t2.Text = text
    t2.Font = Enum.Font.GothamMedium
    t2.TextSize = 10
    t2.TextColor3 = Color3.fromRGB(180, 180, 180)
    t2.TextXAlignment = Enum.TextXAlignment.Left
    
    task.delay(2.5, function()
        if sg.Parent then sg:Destroy() end
    end)
end

-- ============================================
-- GUI - BIG TP NOW BUTTON WITH AUTO TP TOGGLE
-- ============================================
task.spawn(function()
    task.wait(1)
    
    -- Load config first
    loadConfig()
    
    -- Make sure PlayerGui exists
    if not PlayerGui or not PlayerGui.Parent then
        PlayerGui = Instance.new("ScreenGui")
        PlayerGui.Name = "PlayerGui"
        PlayerGui.Parent = LocalPlayer
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "TPNOW_GUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = PlayerGui
    
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 210, 0, 240)
    frame.Position = UDim2.new(0.5, -100, 0.15, 0)
    frame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(50, 45, 70)
    stroke.Thickness = 1
    
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "TP NOW"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    local subtitle = Instance.new("TextLabel", frame)
    subtitle.Size = UDim2.new(1, -20, 0, 20)
    subtitle.Position = UDim2.new(0, 10, 0, 32)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Auto-find best pet"
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextSize = 11
    subtitle.TextColor3 = Color3.fromRGB(160, 160, 180)
    subtitle.TextXAlignment = Enum.TextXAlignment.Center
    
    -- TP NOW Button
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, 60)
    btn.BackgroundColor3 = Color3.fromRGB(52, 211, 153)
    btn.BackgroundTransparency = 0
    btn.Text = "TP NOW"
    btn.Font = Enum.Font.GothamBlack
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(80, 230, 180)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(52, 211, 153)
    end)
    
    btn.MouseButton1Click:Connect(function()
        TPNow()
    end)
    
    -- Auto TP Toggle
    local autoBtn = Instance.new("TextButton", frame)
    autoBtn.Size = UDim2.new(1, -20, 0, 35)
    autoBtn.Position = UDim2.new(0, 10, 0, 108)
    autoBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    autoBtn.BackgroundTransparency = 0
    autoBtn.Text = "AUTO TP: OFF"
    autoBtn.Font = Enum.Font.GothamMedium
    autoBtn.TextSize = 13
    autoBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    autoBtn.AutoButtonColor = false
    Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 8)
    
    autoBtn.MouseEnter:Connect(function()
        autoBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    end)
    autoBtn.MouseLeave:Connect(function()
        if not autoTPEnabled then
            autoBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        else
            autoBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 60)
        end
    end)
    
    autoBtn.MouseButton1Click:Connect(function()
        autoTPEnabled = not autoTPEnabled
        configData.autoTPEnabled = autoTPEnabled
        saveConfig()
        
        if autoTPEnabled then
            autoBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 60)
            autoBtn.Text = "AUTO TP: ON"
            autoBtn.TextColor3 = Color3.fromRGB(100, 255, 150)
            print("[AutoTP] Enabled")
            ShowNotification("AUTO TP", "Enabled - TPing every 15s")
            startAutoTP()
        else
            autoBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            autoBtn.Text = "AUTO TP: OFF"
            autoBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
            print("[AutoTP] Disabled")
            ShowNotification("AUTO TP", "Disabled")
            if autoTPThread then
                task.cancel(autoTPThread)
                autoTPThread = nil
            end
        end
    end)
    
    -- Auto TP On Load Toggle
    local loadBtn = Instance.new("TextButton", frame)
    loadBtn.Size = UDim2.new(1, -20, 0, 30)
    loadBtn.Position = UDim2.new(0, 10, 0, 150)
    loadBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    loadBtn.BackgroundTransparency = 0
    loadBtn.Text = "AUTO ON LOAD: OFF"
    loadBtn.Font = Enum.Font.GothamMedium
    loadBtn.TextSize = 11
    loadBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    loadBtn.AutoButtonColor = false
    Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 8)
    
    -- Set initial state from config
    if configData.autoTPOnLoad then
        loadBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 60)
        loadBtn.Text = "AUTO ON LOAD: ON"
        loadBtn.TextColor3 = Color3.fromRGB(100, 255, 150)
    end
    
    loadBtn.MouseEnter:Connect(function()
        loadBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    end)
    loadBtn.MouseLeave:Connect(function()
        if not configData.autoTPOnLoad then
            loadBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        else
            loadBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 60)
        end
    end)
    
    loadBtn.MouseButton1Click:Connect(function()
        configData.autoTPOnLoad = not configData.autoTPOnLoad
        saveConfig()
        
        if configData.autoTPOnLoad then
            loadBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 60)
            loadBtn.Text = "AUTO ON LOAD: ON"
            loadBtn.TextColor3 = Color3.fromRGB(100, 255, 150)
            ShowNotification("AUTO ON LOAD", "Will TP on script load")
        else
            loadBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            loadBtn.Text = "AUTO ON LOAD: OFF"
            loadBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
            ShowNotification("AUTO ON LOAD", "Disabled")
        end
    end)
    
    -- Status label
    local status = Instance.new("TextLabel", frame)
    status.Size = UDim2.new(1, -20, 0, 20)
    status.Position = UDim2.new(0, 10, 0, 188)
    status.BackgroundTransparency = 1
    status.Text = "Ready"
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 10
    status.TextColor3 = Color3.fromRGB(80, 80, 100)
    status.TextXAlignment = Enum.TextXAlignment.Center
    
    -- Floor indicator
    local floorLabel = Instance.new("TextLabel", frame)
    floorLabel.Size = UDim2.new(1, -20, 0, 18)
    floorLabel.Position = UDim2.new(0, 10, 0, 212)
    floorLabel.BackgroundTransparency = 1
    floorLabel.Text = "Floor: Ground"
    floorLabel.Font = Enum.Font.GothamMedium
    floorLabel.TextSize = 9
    floorLabel.TextColor3 = Color3.fromRGB(60, 60, 80)
    floorLabel.TextXAlignment = Enum.TextXAlignment.Center
    
    task.spawn(function()
        -- If autoTPOnLoad is enabled, run TP after 3 seconds
        if configData.autoTPOnLoad then
            print("[Config] Auto TP on load enabled, will TP in 3 seconds...")
            task.wait(3)
            if LocalPlayer.Character then
                print("[Config] Running initial auto TP...")
                TPNow()
            end
        end
        
        while true do
            if isTeleporting then
                status.Text = "Teleporting..."
                status.TextColor3 = Color3.fromRGB(255, 150, 100)
            elseif isStealing then
                status.Text = "Stealing..."
                status.TextColor3 = Color3.fromRGB(255, 150, 100)
            elseif LocalPlayer:GetAttribute("Stealing") then
                status.Text = "Stealing brainrot!"
                status.TextColor3 = Color3.fromRGB(100, 255, 150)
            else
                local pets = scanPets()
                if #pets > 0 then
                    status.Text = "Best: " .. pets[1].name .. " (" .. pets[1].genText .. ")"
                    status.TextColor3 = Color3.fromRGB(160, 160, 180)
                else
                    status.Text = "Scanning..."
                    status.TextColor3 = Color3.fromRGB(80, 80, 100)
                end
            end
            
            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if hrp.Position.Y > 80 then
                        floorLabel.Text = "Floor: 3rd"
                        floorLabel.TextColor3 = Color3.fromRGB(200, 150, 100)
                    elseif hrp.Position.Y > 20 then
                        floorLabel.Text = "Floor: 2nd"
                        floorLabel.TextColor3 = Color3.fromRGB(150, 200, 150)
                    elseif hrp.Position.Y > -10 then
                        floorLabel.Text = "Floor: Ground"
                        floorLabel.TextColor3 = Color3.fromRGB(60, 60, 80)
                    else
                        floorLabel.Text = "Floor: Basement"
                        floorLabel.TextColor3 = Color3.fromRGB(100, 100, 150)
                    end
                end
            end
            
            task.wait(0.5)
        end
    end)
    
    -- Dragging
    local dragging = false
    local dragStart, startPos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end)

print("[TP NOW] Loaded! Config saved, auto TP on load, safe pathfinding around bases.")
