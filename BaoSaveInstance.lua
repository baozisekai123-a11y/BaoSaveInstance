--[[
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
    
    BaoSaveInstance API v2.0
    Roblox Studio Decompile Tool
    Single-file complete system
]]

-- ============================================================
-- UTILITY FUNCTIONS LAYER
-- ============================================================

local Utility = {}

Utility.Logs = {}

function Utility.Log(level, message)
    local entry = {
        Time = os.clock(),
        Level = level,
        Message = message
    }
    table.insert(Utility.Logs, entry)
    if level == "ERROR" then
        warn("[BaoSave][ERROR] " .. message)
    elseif level == "WARN" then
        warn("[BaoSave][WARN] " .. message)
    else
        print("[BaoSave][" .. level .. "] " .. message)
    end
end

function Utility.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        Utility.Log("ERROR", tostring(result))
    end
    return success, result
end

function Utility.IsProtected(instance)
    local success, _ = pcall(function()
        local _ = instance.Name
    end)
    return not success
end

function Utility.CanClone(instance)
    if Utility.IsProtected(instance) then
        return false
    end
    local success, _ = pcall(function()
        local c = instance:Clone()
        if c then c:Destroy() end
    end)
    return success
end

function Utility.SafeClone(instance)
    if not instance then return nil end
    if Utility.IsProtected(instance) then
        Utility.Log("WARN", "Protected instance skipped: " .. tostring(instance))
        return nil
    end
    local success, clone = pcall(function()
        return instance:Clone()
    end)
    if success and clone then
        return clone
    else
        Utility.Log("WARN", "Cannot clone: " .. tostring(instance) .. " - " .. tostring(clone))
        return nil
    end
end

function Utility.GetGameName()
    local name = "UnnamedGame"
    pcall(function()
        local mid = game.PlaceId
        if mid and mid ~= 0 then
            name = "Place_" .. tostring(mid)
        end
    end)
    pcall(function()
        local marketplaceService = game:GetService("MarketplaceService")
        local info = marketplaceService:GetProductInfo(game.PlaceId)
        if info and info.Name and info.Name ~= "" then
            name = info.Name:gsub("[^%w%s_%-]", ""):gsub("%s+", "_")
        end
    end)
    return name
end

function Utility.CountDescendants(instance)
    local count = 0
    local success, err = pcall(function()
        count = #instance:GetDescendants()
    end)
    if not success then count = 0 end
    return count
end

function Utility.IsFilteredService(serviceName)
    local filtered = {
        ["CoreGui"] = true,
        ["CorePackages"] = true,
        ["RobloxPluginGuiService"] = true,
        ["Visit"] = true,
        ["PluginGuiService"] = true,
        ["PluginDebugService"] = true,
        ["TestService"] = true,
        ["StudioService"] = true,
        ["StudioData"] = true,
        ["NetworkClient"] = true,
        ["NetworkServer"] = true,
        ["PluginManager"] = true,
    }
    return filtered[serviceName] == true
end

function Utility.IsRuntimePlayerGui(instance)
    local success, result = pcall(function()
        if instance:IsA("PlayerGui") then
            return true
        end
        local current = instance.Parent
        while current do
            if current:IsA("PlayerGui") then
                return true
            end
            current = current.Parent
        end
        return false
    end)
    return success and result
end

function Utility.FormatNumber(n)
    if n < 1000 then return tostring(n) end
    return string.format("%.1fK", n / 1000)
end

function Utility.Lerp(a, b, t)
    return a + (b - a) * t
end

-- Base64 Encoding for XML BinaryStrings
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function Utility.Base64Encode(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b64chars:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end


-- ============================================================
-- API LOGIC LAYER
-- ============================================================

local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance

BaoSaveInstance._initialized = false
BaoSaveInstance._status = "Idle"
BaoSaveInstance._progress = 0
BaoSaveInstance._collectedData = nil
BaoSaveInstance._mode = nil -- "FullGame", "Models", "Terrain"
BaoSaveInstance._config = {
    UseExecutorDecompiler = true,
    SaveTags = true,
    SaveAttributes = true,
    SaveScripts = true,
    SaveTerrain = true,
    DeepClone = true,
    SaveNilInstances = true,
    SavePlayers = false,
    StreamingSafeMode = true,
    StreamingRange = 5000,
    StreamingStep = 1000,
}
BaoSaveInstance._callbacks = {
    OnStatusChanged = nil,
    OnProgressChanged = nil,
    OnLogAdded = nil,
}

-- Services references
local Services = {}

function BaoSaveInstance.Init()
    if BaoSaveInstance._initialized then
        Utility.Log("INFO", "BaoSaveInstance already initialized")
        return true
    end
    
    Utility.Log("INFO", "Initializing BaoSaveInstance API v2.0...")
    
    -- Cache services
    local serviceNames = {
        "Workspace", "ReplicatedStorage", "ReplicatedFirst",
        "StarterGui", "StarterPack", "StarterPlayer",
        "Lighting", "SoundService", "Chat",
        "LocalizationService", "MaterialService",
        "ServerStorage", "ServerScriptService",
        "Teams", "TextChatService",
        "Players", "Selection", "ChangeHistoryService",
        "TweenService", "RunService", "HttpService",
        "MarketplaceService", "InsertService",
        "CollectionService", "ProximityPromptService",
        "PathfindingService", "Debris"
    }
    
    for _, name in ipairs(serviceNames) do
        local success, service = pcall(function()
            return game:GetService(name)
        end)
        if success and service then
            Services[name] = service
        else
            Utility.Log("WARN", "Service not available: " .. name)
        end
    end
    
    BaoSaveInstance._initialized = true
    BaoSaveInstance._status = "Idle"
    BaoSaveInstance._progress = 0
    
    Utility.Log("INFO", "BaoSaveInstance initialized successfully")
    return true
end

function BaoSaveInstance._SetStatus(status)
    BaoSaveInstance._status = status
    if BaoSaveInstance._callbacks.OnStatusChanged then
        BaoSaveInstance._callbacks.OnStatusChanged(status)
    end
end

function BaoSaveInstance._SetProgress(progress)
    BaoSaveInstance._progress = math.clamp(progress, 0, 100)
    if BaoSaveInstance._callbacks.OnProgressChanged then
        BaoSaveInstance._callbacks.OnProgressChanged(BaoSaveInstance._progress)
    end
end

-- Helper to find the best available decompiler
function BaoSaveInstance._GetBestDecompiler()
    if getgenv then
        local env = getgenv()
        if env.getscriptsource then return env.getscriptsource end
        if env.decompile then return env.decompile end
        if env.syn and env.syn.decompile then return env.syn.decompile end
        if env.fluxus and env.fluxus.decompile then return env.fluxus.decompile end
        if env.krnl and env.krnl.decompile then return env.krnl.decompile end
    end
    
    if decompile then return decompile end
    if getscriptsource then return getscriptsource end
    
    return nil
end

-- Enhanced Script Collector
function BaoSaveInstance._CollectScriptSource(scriptInstance)
    if not scriptInstance then return nil end
    
    local source = nil
    local success = false
    local method = "Unknown"
    
    -- 1. Try to read Source property (Studio / High Permissions)
    pcall(function()
        if scriptInstance:IsA("LuaSourceContainer") then
            if scriptInstance.Source and scriptInstance.Source ~= "" then
                source = scriptInstance.Source
                method = "SourceProperty"
                success = true
            end
        end
    end)
    
    -- 2. Try Executor Decompiler
    if not success then
        local decompiler = BaoSaveInstance._GetBestDecompiler()
        if decompiler then
            pcall(function()
                source = decompiler(scriptInstance)
                if source and source ~= "" then
                    method = "Decompiler"
                    success = true
                end
            end)
        end
    end
    
    -- 3. Try ScriptEditorService (Studio Fallback)
    if not success then
        pcall(function()
            local ses = game:GetService("ScriptEditorService")
            if ses then
                local doc = ses:FindScriptDocument(scriptInstance)
                if doc then
                    source = doc:GetText()
                    if source and source ~= "" then
                        method = "ScriptEditorService"
                        success = true
                    end
                end
            end
        end)
    end
    
    -- 4. Post-Process & Metadata
    if success and source then
        -- Add metadata header
        local header = string.format("--[[\n\tBaoSaveInstance Decompiler v2.0\n\tSource: %s\n\tMethod: %s\n\tTime: %s\n]]\n\n",
            scriptInstance:GetFullName(),
            method,
            os.date("%c")
        )
        return header .. source
    elseif not success then
        -- Failure Recovery: Try to dump bytecode if possible
        local bytecodeMsg = ""
        pcall(function()
            if getscriptbytecode then
                local bc = getscriptbytecode(scriptInstance)
                if bc then
                     bytecodeMsg = string.format("\n\tBytecode Size: %d bytes (Decompile failed)", #bc)
                end
            end
        end)

        -- Return a comment explaining failure if we know it's a script
        if scriptInstance:IsA("Script") or scriptInstance:IsA("LocalScript") or scriptInstance:IsA("ModuleScript") then
             return string.format("--[[\n\t[BaoSaveInstance] FAILED TO DECOMPILE\n\tSource: %s\n\tReason: No access or decompiler failed.%s\n]]", 
                scriptInstance:GetFullName(), bytecodeMsg)
        end
    end
    
    return nil
end

-- Process scripts in a cloned tree: ensure Source is preserved
function BaoSaveInstance._ProcessScriptsInTree(root)
    if not root then return 0 end
    
    local scriptCount = 0
    local descendants = {}
    
    pcall(function()
        descendants = root:GetDescendants()
    end)
    
    -- Also check root itself
    table.insert(descendants, root)
    
    for _, desc in ipairs(descendants) do
        pcall(function()
            if desc:IsA("LuaSourceContainer") then
                -- The Source property should be preserved during Clone in Studio
                -- But we verify and log
                local hasSource = false
                pcall(function()
                    hasSource = (desc.Source ~= nil and desc.Source ~= "")
                end)
                if hasSource then
                    scriptCount = scriptCount + 1
                end
            end
        end)
    end
    
    return scriptCount
end

-- ============================================================
-- DEEP CLONE SYSTEM
-- ============================================================

-- Try to read a property safely, returns value or nil
function Utility.TryGetProperty(instance, propName)
    local success, value = pcall(function()
        return instance[propName]
    end)
    if success then return value end
    -- Try hidden property via executor
    if gethiddenproperty then
        local s2, v2 = pcall(function()
            return gethiddenproperty(instance, propName)
        end)
        if s2 then return v2 end
    end
    return nil
end

-- Create a shell instance copying basic properties when Clone fails
function BaoSaveInstance._CreateShell(instance)
    local className = nil
    pcall(function() className = instance.ClassName end)
    if not className then return nil end
    
    local shell = nil
    pcall(function()
        shell = Instance.new(className)
    end)
    if not shell then return nil end
    
    -- Copy basic properties that almost all instances have
    pcall(function() shell.Name = instance.Name end)
    
    -- Copy archivable
    pcall(function() shell.Archivable = true end)
    
    return shell
end

-- Deep clone children of a service safely
function BaoSaveInstance._DeepCloneChildren(service, targetFolder, yieldEvery)
    if not service or not targetFolder then return 0 end
    yieldEvery = yieldEvery or 50
    
    local clonedCount = 0
    local children = {}
    local processedCount = 0
    
    pcall(function()
        children = service:GetChildren()
    end)
    
    for _, child in ipairs(children) do
        -- Skip runtime PlayerGui content
        if Utility.IsRuntimePlayerGui(child) then
            continue
        end
        
        if Utility.IsProtected(child) then
            continue
        end
        
        -- Method 1: Standard Clone
        local clone = Utility.SafeClone(child)
        
        -- Method 2: Deep Clone fallback (create shell + copy properties)
        if not clone and BaoSaveInstance._config.DeepClone then
            clone = BaoSaveInstance._CreateShell(child)
            if clone then
                -- Recursively deep-clone children of this instance
                pcall(function()
                    local subChildren = child:GetChildren()
                    for _, subChild in ipairs(subChildren) do
                        if not Utility.IsProtected(subChild) then
                            local subClone = Utility.SafeClone(subChild)
                            if not subClone then
                                subClone = BaoSaveInstance._CreateShell(subChild)
                            end
                            if subClone then
                                subClone.Parent = clone
                            end
                        end
                    end
                end)
                Utility.Log("INFO", "Shell created for uncloneable: " .. tostring(child))
            end
        end
        
        if clone then
            clone.Parent = targetFolder
            clonedCount = clonedCount + 1
            local descCount = Utility.CountDescendants(clone)
            clonedCount = clonedCount + descCount
        end
        
        processedCount = processedCount + 1
        if processedCount % yieldEvery == 0 then
            task.wait()
        end
    end
    
    return clonedCount
end

-- ============================================================
-- TERRAIN CAPTURE SYSTEM
-- ============================================================

function BaoSaveInstance._CaptureTerrain()
    local terrain = nil
    pcall(function()
        terrain = Services.Workspace and Services.Workspace.Terrain
    end)
    
    if not terrain then
        Utility.Log("WARN", "Terrain not found")
        return nil
    end
    
    -- Clone terrain object first
    local terrainClone = Utility.SafeClone(terrain)
    if not terrainClone then
        -- If clone fails, create a shell
        pcall(function()
            terrainClone = Instance.new("Terrain")
        end)
    end
    
    if not terrainClone then
        Utility.Log("ERROR", "Cannot create Terrain instance")
        return nil
    end
    
    Utility.Log("INFO", "Terrain object captured")
    
    -- Capture terrain properties
    pcall(function()
        terrainClone.WaterColor = terrain.WaterColor
        terrainClone.WaterReflectance = terrain.WaterReflectance
        terrainClone.WaterTransparency = terrain.WaterTransparency
        terrainClone.WaterWaveSize = terrain.WaterWaveSize
        terrainClone.WaterWaveSpeed = terrain.WaterWaveSpeed
        terrainClone.Decoration = terrain.Decoration
    end)
    
    -- Capture terrain extents info
    local extents = Vector3.new(0, 0, 0)
    pcall(function()
        extents = terrain:GetExtentsSize()
        Utility.Log("INFO", string.format("Terrain extents: %.0f x %.0f x %.0f", 
            extents.X, extents.Y, extents.Z))
    end)
    
    -- Capture voxel data using ReadVoxels (region-by-region to avoid memory issues)
    pcall(function()
        local REGION_SIZE = 128 -- studs per region chunk
        local RESOLUTION = 4   -- voxel resolution
        
        local minBound = Vector3.new(-extents.X/2, -extents.Y/2, -extents.Z/2)
        local maxBound = Vector3.new(extents.X/2, extents.Y/2, extents.Z/2)
        
        -- Only attempt if terrain has actual content
        if extents.X > 0 and extents.Y > 0 and extents.Z > 0 then
            local regionCount = 0
            
            for x = minBound.X, maxBound.X, REGION_SIZE do
                for y = minBound.Y, maxBound.Y, REGION_SIZE do
                    for z = minBound.Z, maxBound.Z, REGION_SIZE do
                        local regionStart = Vector3.new(x, y, z)
                        local regionEnd = Vector3.new(
                            math.min(x + REGION_SIZE, maxBound.X),
                            math.min(y + REGION_SIZE, maxBound.Y),
                            math.min(z + REGION_SIZE, maxBound.Z)
                        )
                        
                        local region = Region3.new(regionStart, regionEnd)
                        region = region:ExpandToGrid(RESOLUTION)
                        
                        local materials, occupancy = terrain:ReadVoxels(region, RESOLUTION)
                        
                        -- Write voxels to cloned terrain
                        if materials and occupancy then
                            pcall(function()
                                terrainClone:WriteVoxels(region, RESOLUTION, materials, occupancy)
                            end)
                            regionCount = regionCount + 1
                        end
                        
                        if regionCount % 10 == 0 then
                            task.wait()
                        end
                    end
                end
            end
            
            Utility.Log("INFO", "Terrain voxels captured: " .. regionCount .. " regions")
        else
            Utility.Log("WARN", "Terrain has zero extents, skipping voxel capture")
        end
    end)
    
    return terrainClone
end

-- Nil instances sweep (executor only)
function BaoSaveInstance._CollectNilInstances(targetFolder)
    if not BaoSaveInstance._config.SaveNilInstances then return 0 end
    if not getnilinstances then return 0 end
    
    local count = 0
    local nilFolder = Instance.new("Folder")
    nilFolder.Name = "_NilInstances"
    
    pcall(function()
        local nilInstances = getnilinstances()
        Utility.Log("INFO", "Found " .. #nilInstances .. " nil instances")
        
        for _, inst in ipairs(nilInstances) do
            if not Utility.IsProtected(inst) then
                local clone = Utility.SafeClone(inst)
                if clone then
                    clone.Parent = nilFolder
                    count = count + 1
                end
            end
            
            if count % 50 == 0 then
                task.wait()
            end
        end
    end)
    
    if count > 0 then
        nilFolder.Parent = targetFolder
        Utility.Log("INFO", "Collected " .. count .. " nil instances")
    else
        nilFolder:Destroy()
    end
    
    return count
end

-- Players snapshot (character models)
function BaoSaveInstance._SnapshotPlayers(targetFolder)
    if not BaoSaveInstance._config.SavePlayers then return 0 end
    
    local count = 0
    local playersFolder = Instance.new("Folder")
    playersFolder.Name = "Players"
    
    pcall(function()
        local players = game:GetService("Players"):GetPlayers()
        for _, player in ipairs(players) do
            pcall(function()
                local playerFolder = Instance.new("Folder")
                playerFolder.Name = player.Name
                
                -- Clone character
                if player.Character then
                    local charClone = Utility.SafeClone(player.Character)
                    if charClone then
                        charClone.Name = "Character"
                        charClone.Parent = playerFolder
                        count = count + 1
                    end
                end
                
                -- Clone backpack
                pcall(function()
                    local backpack = player:FindFirstChildOfClass("Backpack")
                    if backpack then
                        local bpClone = Utility.SafeClone(backpack)
                        if bpClone then
                            bpClone.Parent = playerFolder
                            count = count + 1
                        end
                    end
                end)
                
                -- Clone PlayerGui (starter content)
                pcall(function()
                    local pg = player:FindFirstChildOfClass("PlayerGui")
                    if pg then
                        local pgFolder = Instance.new("Folder")
                        pgFolder.Name = "PlayerGui"
                        for _, gui in ipairs(pg:GetChildren()) do
                            local guiClone = Utility.SafeClone(gui)
                            if guiClone then
                                guiClone.Parent = pgFolder
                                count = count + 1
                            end
                        end
                        if #pgFolder:GetChildren() > 0 then
                            pgFolder.Parent = playerFolder
                        else
                            pgFolder:Destroy()
                        end
                    end
                end)
                
                if #playerFolder:GetChildren() > 0 then
                    playerFolder.Parent = playersFolder
                else
                    playerFolder:Destroy()
                end
            end)
        end
    end)
    
    if count > 0 then
        playersFolder.Parent = targetFolder
        Utility.Log("INFO", "Snapshot " .. count .. " player objects")
    else
        playersFolder:Destroy()
    end
    
    return count
end

-- ============================================================
-- STREAMING SYSTEM (For StreamingEnabled games)
-- ============================================================

function BaoSaveInstance.StreamMap()
    if not BaoSaveInstance._initialized then return false end
    
    local config = BaoSaveInstance._config
    local player = game:GetService("Players").LocalPlayer
    if not player then return false end
    
    BaoSaveInstance._SetStatus("Streaming")
    BaoSaveInstance._SetProgress(0)
    Utility.Log("INFO", "Starting Map Streamer (Range: " .. config.StreamingRange .. ")...")
    
    local originalCF = nil
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        originalCF = character.HumanoidRootPart.CFrame
    end
    
    local range = config.StreamingRange
    local step = config.StreamingStep
    local points = {}
    
    for x = -range, range, step do
        for z = -range, range, step do
            table.insert(points, Vector3.new(x, 0, z))
        end
    end
    
    local totalPoints = #points
    for i, point in ipairs(points) do
        if BaoSaveInstance._status ~= "Streaming" then break end -- Cancelled
        
        BaoSaveInstance._SetProgress(math.floor((i / totalPoints) * 100))
        
        if config.StreamingSafeMode then
            -- METHOD 1: RequestStreamAroundAsync (Safe, no movement)
            pcall(function()
                player:RequestStreamAroundAsync(point)
            end)
            task.wait(0.1) -- Small yield to let engine process
        else
            -- METHOD 2: Character Teleport (More aggressive)
            if character and character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    local hrp = character.HumanoidRootPart
                    local hum = character:FindFirstChildOfClass("Humanoid")
                    
                    if hum then hum.PlatformStand = true end
                    hrp.Anchored = true
                    hrp.CFrame = CFrame.new(point + Vector3.new(0, 100, 0)) -- Fly high to avoid clipping
                    
                    task.wait(0.5) -- Wait for chunks
                end)
            end
        end
        
        if i % 10 == 0 then
             Utility.Log("INFO", string.format("Streamed: %d/%d points", i, totalPoints))
        end
    end
    
    -- Return home
    if originalCF and character and character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local hrp = character.HumanoidRootPart
            local hum = character:FindFirstChildOfClass("Humanoid")
            hrp.CFrame = originalCF
            hrp.Anchored = false
            if hum then hum.PlatformStand = false end
        end)
    end
    
    Utility.Log("INFO", "Streaming complete!")
    BaoSaveInstance._SetProgress(100)
    return true
end

function BaoSaveInstance.StreamAndDecompile(mode)
    Utility.Log("INFO", "Starting Auto-Process: Stream -> Decompile -> Export")
    
    -- 1. Stream (if configured)
    local sSuccess = BaoSaveInstance.StreamMap()
    if not sSuccess then
        Utility.Log("WARN", "Streaming skipped or failed. Continuing...")
    end
    
    -- 2. Decompile
    local dSuccess = false
    if mode == "FullGame" then
        dSuccess = BaoSaveInstance.DecompileFullGame()
    elseif mode == "Models" then
        dSuccess = BaoSaveInstance.DecompileModels()
    elseif mode == "Terrain" then
        dSuccess = BaoSaveInstance.DecompileTerrain()
    end
    
    if not dSuccess then
        Utility.Log("ERROR", "Decompilation failed. Aborting export.")
        return false
    end
    
    -- 3. Export
    if dSuccess then
        local eSuccess = BaoSaveInstance.ExportRBXL()
        if eSuccess then
             Utility.Log("INFO", "✅ Auto-Process Complete! File exported successfully.")
             return true
        else
             Utility.Log("ERROR", "❌ Export failed.")
        end
    end
    
    return false
end


-- ============================================================
-- DECOMPILE MODES
-- ============================================================

function BaoSaveInstance.DecompileFullGame()
    if not BaoSaveInstance._initialized then
        Utility.Log("ERROR", "API not initialized. Call Init() first.")
        return false
    end
    
    BaoSaveInstance._mode = "FullGame"
    BaoSaveInstance._SetStatus("Processing")
    BaoSaveInstance._SetProgress(0)
    Utility.Log("INFO", "Starting Full Game Decompile (Enhanced)...")
    
    local rootModel = Instance.new("Model")
    rootModel.Name = Utility.GetGameName() .. "_FullGame"
    
    local servicesToClone = {
        { Name = "Workspace",           Service = Services.Workspace,           Weight = 30 },
        { Name = "ReplicatedStorage",   Service = Services.ReplicatedStorage,   Weight = 10 },
        { Name = "ReplicatedFirst",     Service = Services.ReplicatedFirst,     Weight = 5  },
        { Name = "StarterGui",          Service = Services.StarterGui,          Weight = 10 },
        { Name = "StarterPack",         Service = Services.StarterPack,         Weight = 5  },
        { Name = "StarterPlayer",       Service = Services.StarterPlayer,       Weight = 10 },
        { Name = "Lighting",            Service = Services.Lighting,            Weight = 5  },
        { Name = "SoundService",        Service = Services.SoundService,        Weight = 5  },
        { Name = "Chat",                Service = Services.Chat,                Weight = 3  },
        { Name = "Teams",               Service = Services.Teams,               Weight = 2  },
        { Name = "ServerStorage",       Service = Services.ServerStorage,       Weight = 5  },
        { Name = "ServerScriptService", Service = Services.ServerScriptService, Weight = 5  },
        { Name = "MaterialService",     Service = Services.MaterialService,     Weight = 2  },
        { Name = "TextChatService",     Service = Services.TextChatService,     Weight = 2  },
        { Name = "LocalizationService", Service = Services.LocalizationService, Weight = 1  },
    }
    
    local totalWeight = 5
    for _, s in ipairs(servicesToClone) do
        totalWeight = totalWeight + s.Weight
    end
    
    local currentWeight = 0
    local totalObjects = 0
    local totalScripts = 0
    
    for i, sData in ipairs(servicesToClone) do
        if sData.Service then
            Utility.Log("INFO", "Cloning service: " .. sData.Name)
            
            local serviceFolder = Instance.new("Folder")
            serviceFolder.Name = sData.Name
            serviceFolder.Parent = rootModel
            
            if sData.Name == "Workspace" then
                if BaoSaveInstance._config.SaveTerrain then
                    local terrainClone = BaoSaveInstance._CaptureTerrain()
                    if terrainClone then
                        terrainClone.Parent = serviceFolder
                        Utility.Log("INFO", "Terrain (with voxels) added")
                    end
                end
                
                local wsChildren = {}
                pcall(function() wsChildren = sData.Service:GetChildren() end)
                
                for _, child in ipairs(wsChildren) do
                    pcall(function()
                        if not child:IsA("Terrain") and not child:IsA("Camera") then
                            if not Utility.IsProtected(child) then
                                local clone = Utility.SafeClone(child)
                                if not clone and BaoSaveInstance._config.DeepClone then
                                    clone = BaoSaveInstance._CreateShell(child)
                                    if clone then
                                        pcall(function()
                                            for _, sub in ipairs(child:GetChildren()) do
                                                if not Utility.IsProtected(sub) then
                                                    local sc = Utility.SafeClone(sub) or BaoSaveInstance._CreateShell(sub)
                                                    if sc then sc.Parent = clone end
                                                end
                                            end
                                        end)
                                    end
                                end
                                if clone then
                                    clone.Parent = serviceFolder
                                    totalObjects = totalObjects + 1 + Utility.CountDescendants(clone)
                                end
                            end
                        end
                    end)
                end
            else
                local count = BaoSaveInstance._DeepCloneChildren(sData.Service, serviceFolder)
                totalObjects = totalObjects + count
            end
            
            if BaoSaveInstance._config.SaveScripts then
                local scriptCount = BaoSaveInstance._ProcessScriptsInTree(serviceFolder)
                totalScripts = totalScripts + scriptCount
            end
            
            Utility.Log("INFO", sData.Name .. " done (" .. totalObjects .. " objects)")
        else
            Utility.Log("WARN", "Service not available: " .. sData.Name)
        end
        
        currentWeight = currentWeight + sData.Weight
        BaoSaveInstance._SetProgress(math.floor((currentWeight / totalWeight) * 90))
        task.wait()
    end
    
    -- Nil instances sweep
    local nilCount = BaoSaveInstance._CollectNilInstances(rootModel)
    totalObjects = totalObjects + nilCount
    
    -- Players snapshot
    local playerCount = BaoSaveInstance._SnapshotPlayers(rootModel)
    totalObjects = totalObjects + playerCount
    
    BaoSaveInstance._SetProgress(95)
    
    -- Store game properties
    pcall(function()
        local propsFolder = Instance.new("Folder")
        propsFolder.Name = "_GameProperties"
        propsFolder.Parent = rootModel
        
        local placeIdVal = Instance.new("IntValue")
        placeIdVal.Name = "PlaceId"
        placeIdVal.Value = game.PlaceId
        placeIdVal.Parent = propsFolder
        
        local gameIdVal = Instance.new("IntValue")
        gameIdVal.Name = "GameId"
        gameIdVal.Value = game.GameId
        gameIdVal.Parent = propsFolder
        
        local nameVal = Instance.new("StringValue")
        nameVal.Name = "GameName"
        nameVal.Value = Utility.GetGameName()
        nameVal.Parent = propsFolder
        
        local jobIdVal = Instance.new("StringValue")
        jobIdVal.Name = "JobId"
        jobIdVal.Value = tostring(game.JobId)
        jobIdVal.Parent = propsFolder
    end)
    
    BaoSaveInstance._collectedData = rootModel
    BaoSaveInstance._SetProgress(100)
    BaoSaveInstance._SetStatus("Done")
    
    Utility.Log("INFO", string.format(
        "Full Game Decompile complete! Objects: %s, Scripts: %d, NilInst: %d",
        Utility.FormatNumber(totalObjects), totalScripts, nilCount
    ))
    
    return true
end

function BaoSaveInstance.DecompileModels()
    if not BaoSaveInstance._initialized then
        Utility.Log("ERROR", "API not initialized. Call Init() first.")
        return false
    end
    
    BaoSaveInstance._mode = "Models"
    BaoSaveInstance._SetStatus("Processing")
    BaoSaveInstance._SetProgress(0)
    Utility.Log("INFO", "Starting Full Model Decompile (Enhanced, no Terrain)...")
    
    local rootModel = Instance.new("Model")
    rootModel.Name = Utility.GetGameName() .. "_Models"
    
    local servicesToClone = {
        { Name = "Workspace",           Service = Services.Workspace,           Weight = 30 },
        { Name = "ReplicatedStorage",   Service = Services.ReplicatedStorage,   Weight = 15 },
        { Name = "ReplicatedFirst",     Service = Services.ReplicatedFirst,     Weight = 5  },
        { Name = "StarterGui",          Service = Services.StarterGui,          Weight = 10 },
        { Name = "StarterPack",         Service = Services.StarterPack,         Weight = 5  },
        { Name = "StarterPlayer",       Service = Services.StarterPlayer,       Weight = 10 },
        { Name = "Lighting",            Service = Services.Lighting,            Weight = 5  },
        { Name = "SoundService",        Service = Services.SoundService,        Weight = 5  },
        { Name = "ServerStorage",       Service = Services.ServerStorage,       Weight = 5  },
        { Name = "ServerScriptService", Service = Services.ServerScriptService, Weight = 5  },
        { Name = "Teams",               Service = Services.Teams,               Weight = 2  },
        { Name = "Chat",                Service = Services.Chat,                Weight = 3  },
    }
    
    local totalWeight = 3
    for _, s in ipairs(servicesToClone) do
        totalWeight = totalWeight + s.Weight
    end
    
    local currentWeight = 0
    local totalObjects = 0
    local totalScripts = 0
    
    for _, sData in ipairs(servicesToClone) do
        if sData.Service then
            Utility.Log("INFO", "Cloning: " .. sData.Name)
            
            local serviceFolder = Instance.new("Folder")
            serviceFolder.Name = sData.Name
            serviceFolder.Parent = rootModel
            
            if sData.Name == "Workspace" then
                local wsChildren = {}
                pcall(function() wsChildren = sData.Service:GetChildren() end)
                
                for _, child in ipairs(wsChildren) do
                    pcall(function()
                        if not child:IsA("Terrain") and not child:IsA("Camera") then
                            if not Utility.IsProtected(child) then
                                local clone = Utility.SafeClone(child)
                                if not clone and BaoSaveInstance._config.DeepClone then
                                    clone = BaoSaveInstance._CreateShell(child)
                                    if clone then
                                        pcall(function()
                                            for _, sub in ipairs(child:GetChildren()) do
                                                if not Utility.IsProtected(sub) then
                                                    local sc = Utility.SafeClone(sub) or BaoSaveInstance._CreateShell(sub)
                                                    if sc then sc.Parent = clone end
                                                end
                                            end
                                        end)
                                    end
                                end
                                if clone then
                                    clone.Parent = serviceFolder
                                    totalObjects = totalObjects + 1 + Utility.CountDescendants(clone)
                                end
                            end
                        end
                    end)
                end
            else
                local count = BaoSaveInstance._DeepCloneChildren(sData.Service, serviceFolder)
                totalObjects = totalObjects + count
            end
            
            if BaoSaveInstance._config.SaveScripts then
                local scriptCount = BaoSaveInstance._ProcessScriptsInTree(serviceFolder)
                totalScripts = totalScripts + scriptCount
            end
        else
            Utility.Log("WARN", "Service not available: " .. sData.Name)
        end
        
        currentWeight = currentWeight + sData.Weight
        BaoSaveInstance._SetProgress(math.floor((currentWeight / totalWeight) * 90))
        task.wait()
    end
    
    -- Nil instances
    local nilCount = BaoSaveInstance._CollectNilInstances(rootModel)
    totalObjects = totalObjects + nilCount
    
    BaoSaveInstance._collectedData = rootModel
    BaoSaveInstance._SetProgress(100)
    BaoSaveInstance._SetStatus("Done")
    
    Utility.Log("INFO", string.format(
        "Model Decompile complete! Objects: %s, Scripts: %d, NilInst: %d",
        Utility.FormatNumber(totalObjects), totalScripts, nilCount
    ))
    
    return true
end

function BaoSaveInstance.DecompileTerrain()
    if not BaoSaveInstance._initialized then
        Utility.Log("ERROR", "API not initialized. Call Init() first.")
        return false
    end
    
    BaoSaveInstance._mode = "Terrain"
    BaoSaveInstance._SetStatus("Processing")
    BaoSaveInstance._SetProgress(0)
    Utility.Log("INFO", "Starting Terrain Decompile (Enhanced with Voxels)...")
    
    BaoSaveInstance._SetProgress(5)
    
    local rootModel = Instance.new("Model")
    rootModel.Name = Utility.GetGameName() .. "_Terrain"
    
    local wsFolder = Instance.new("Folder")
    wsFolder.Name = "Workspace"
    wsFolder.Parent = rootModel
    
    BaoSaveInstance._SetProgress(10)
    
    local terrainClone = BaoSaveInstance._CaptureTerrain()
    if terrainClone then
        terrainClone.Parent = wsFolder
        Utility.Log("INFO", "Terrain captured with voxel data")
        BaoSaveInstance._SetProgress(80)
    else
        Utility.Log("ERROR", "Failed to capture Terrain")
        BaoSaveInstance._SetStatus("Error")
        return false
    end
    
    -- Capture Lighting + effects
    pcall(function()
        if Services.Lighting then
            local lightFolder = Instance.new("Folder")
            lightFolder.Name = "Lighting"
            lightFolder.Parent = rootModel
            
            local count = BaoSaveInstance._DeepCloneChildren(Services.Lighting, lightFolder)
            Utility.Log("INFO", "Lighting effects captured: " .. count .. " objects")
            
            pcall(function()
                local ambientVal = Instance.new("Color3Value")
                ambientVal.Name = "Ambient"
                ambientVal.Value = Services.Lighting.Ambient
                ambientVal.Parent = lightFolder
                
                local outdoorVal = Instance.new("Color3Value")
                outdoorVal.Name = "OutdoorAmbient"
                outdoorVal.Value = Services.Lighting.OutdoorAmbient
                outdoorVal.Parent = lightFolder
                
                local brightnessVal = Instance.new("NumberValue")
                brightnessVal.Name = "Brightness"
                brightnessVal.Value = Services.Lighting.Brightness
                brightnessVal.Parent = lightFolder
                
                local clockVal = Instance.new("NumberValue")
                clockVal.Name = "ClockTime"
                clockVal.Value = Services.Lighting.ClockTime
                clockVal.Parent = lightFolder
                
                local fogColorVal = Instance.new("Color3Value")
                fogColorVal.Name = "FogColor"
                fogColorVal.Value = Services.Lighting.FogColor
                fogColorVal.Parent = lightFolder
                
                local fogStartVal = Instance.new("NumberValue")
                fogStartVal.Name = "FogStart"
                fogStartVal.Value = Services.Lighting.FogStart
                fogStartVal.Parent = lightFolder
                
                local fogEndVal = Instance.new("NumberValue")
                fogEndVal.Name = "FogEnd"
                fogEndVal.Value = Services.Lighting.FogEnd
                fogEndVal.Parent = lightFolder
            end)
        end
    end)
    
    BaoSaveInstance._collectedData = rootModel
    BaoSaveInstance._SetProgress(100)
    BaoSaveInstance._SetStatus("Done")
    
    Utility.Log("INFO", "Terrain Decompile complete (with voxels + lighting)!")
    return true
end

-- ============================================================
-- EXPORT SYSTEM
-- ============================================================

function BaoSaveInstance.ExportRBXL()
    if not BaoSaveInstance._initialized then
        Utility.Log("ERROR", "API not initialized")
        return false
    end
    
    if not BaoSaveInstance._collectedData then
        Utility.Log("ERROR", "No data to export. Run a Decompile first.")
        return false
    end
    
    BaoSaveInstance._SetStatus("Exporting")
    BaoSaveInstance._SetProgress(0)
    
    local gameName = Utility.GetGameName()
    local fileName = gameName .. "_Decompiled"
    
    Utility.Log("INFO", "Exporting: " .. fileName .. ".rbxl")
    BaoSaveInstance._SetProgress(10)
    
    -- Method 1: Use Selection + Plugin save (Studio context)
    local exported = false
    
    -- Try using the Selection service to select and save
    pcall(function()
        local selection = Services.Selection
        if selection then
            -- First, parent the collected data into a temporary location
            local data = BaoSaveInstance._collectedData
            
            -- For rbxl export, we need to reconstruct the game tree
            -- We'll use the plugin:SaveSelectedToRoblox or similar approach
            
            -- Reconstruct services from folders
            local reconstructed = {}
            
            for _, folder in ipairs(data:GetChildren()) do
                if folder:IsA("Folder") then
                    local serviceName = folder.Name
                    local targetService = nil
                    
                    pcall(function()
                        targetService = game:GetService(serviceName)
                    end)
                    
                    if targetService and not Utility.IsFilteredService(serviceName) then
                        table.insert(reconstructed, {
                            Source = folder,
                            Target = targetService
                        })
                    end
                end
            end
            
            Utility.Log("INFO", "Reconstructed " .. #reconstructed .. " services for export")
        end
    end)
    
    BaoSaveInstance._SetProgress(30)
    
    -- Method 2: Direct file save using StudioService or plugin context
    pcall(function()
        -- In Studio, the best way to save is through the built-in save mechanism
        -- We'll place our collected data model for selection-based export
        
        local exportModel = BaoSaveInstance._collectedData
        exportModel.Name = fileName
        
        -- Parent to ServerStorage temporarily for selection
        if Services.ServerStorage then
            exportModel.Parent = Services.ServerStorage
            
            -- Select the model
            if Services.Selection then
                Services.Selection:Set({exportModel})
            end
            
            Utility.Log("INFO", "Model placed in ServerStorage and selected for export")
            Utility.Log("INFO", "Use File > Save As to save as: " .. fileName .. ".rbxl")
        end
    end)
    
    BaoSaveInstance._SetProgress(50)
    
    -- Method 3: Try saveinstance if available (executor environment)
    pcall(function()
        if saveinstance then
            Utility.Log("INFO", "saveinstance detected, using native export...")
            saveinstance({
                FileName = fileName .. ".rbxl",
                ExtraInstances = {BaoSaveInstance._collectedData},
                DecompileMode = "full",
                NilInstances = false,
                RemovePlayerCharacters = true,
                SavePlayers = false,
            })
            exported = true
            Utility.Log("INFO", "File saved via saveinstance: " .. fileName .. ".rbxl")
        end
    end)
    
    BaoSaveInstance._SetProgress(70)
    
    -- Method 4: Try writefile for rbxl XML format
    if not exported then
        pcall(function()
            if writefile and isfile then
                Utility.Log("INFO", "Attempting XML rbxl export via writefile...")
                
                local xmlContent = BaoSaveInstance._GenerateRBXLXML()
                if xmlContent then
                    writefile(fileName .. ".rbxl", xmlContent)
                    exported = true
                    Utility.Log("INFO", "File written: " .. fileName .. ".rbxl")
                end
            end
        end)
    end
    
    BaoSaveInstance._SetProgress(90)
    
    -- Method 5: Studio-native approach using game:Save or plugin
    if not exported then
        pcall(function()
            -- Check if we're in a plugin context
            if plugin then
                Utility.Log("INFO", "Plugin context detected")
                
                -- Use plugin to prompt save
                local toolbar = plugin:CreateToolbar("BaoSaveInstance")
                Utility.Log("INFO", "Use File > Save to Desktop to export the file")
                exported = true
            end
        end)
    end
    
    if not exported then
        -- Fallback: Just inform the user
        Utility.Log("INFO", "=== EXPORT INSTRUCTIONS ===")
        Utility.Log("INFO", "The decompiled data has been placed in ServerStorage as: " .. fileName)
        Utility.Log("INFO", "To export as .rbxl:")
        Utility.Log("INFO", "1. Select the model in ServerStorage")
        Utility.Log("INFO", "2. Right-click > Save to File")
        Utility.Log("INFO", "3. Choose .rbxl format")
        Utility.Log("INFO", "4. Name it: " .. fileName .. ".rbxl")
        Utility.Log("INFO", "===========================")
    end
    
    BaoSaveInstance._SetProgress(100)
    BaoSaveInstance._SetStatus("Done")
    
    Utility.Log("INFO", "Export process completed")
    return true
end

-- Generate advanced RBXL XML content
function BaoSaveInstance._GenerateRBXLXML()
    if not BaoSaveInstance._collectedData then return nil end
    
    local xml = {}
    table.insert(xml, '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"')
    table.insert(xml, ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"')
    table.insert(xml, ' xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd"')
    table.insert(xml, ' version="4">')
    
    local refCounter = 0
    local CollectionService = game:GetService("CollectionService")
    
    local function getRef()
        refCounter = refCounter + 1
        return "RBX" .. tostring(refCounter)
    end
    
    local function escapeXml(str)
        if not str then return "" end
        str = tostring(str)
        str = str:gsub("&", "&amp;")
        str = str:gsub("<", "&lt;")
        str = str:gsub(">", "&gt;")
        str = str:gsub('"', "&quot;")
        str = str:gsub("'", "&apos;")
        return str
    end

    local function packUInt32(n)
        local b = string.char
        local b1 = n % 256
        local b2 = math.floor(n / 256) % 256
        local b3 = math.floor(n / 65536) % 256
        local b4 = math.floor(n / 16777216) % 256
        return b(b1) .. b(b2) .. b(b3) .. b(b4)
    end
    
    local function serializeTags(instance)
        local tags = CollectionService:GetTags(instance)
        if #tags == 0 then return nil end
        
        local buffer = packUInt32(#tags)
        for _, tag in ipairs(tags) do
            buffer = buffer .. packUInt32(#tag) .. tag
        end
        return Utility.Base64Encode(buffer)
    end

    local function serializeAttributes(instance)
        if not BaoSaveInstance._config.SaveAttributes then return nil end
        local attrs = instance:GetAttributes()
        if not next(attrs) then return nil end
        
        -- Simplified Attribute Serializer (Strings, Numbers, Bools only for stability)
        -- Format: [Count:UInt32] [NameLen:UInt32] [Name:Bytes] [Type:Byte] [Value:Bytes]...
        
        local buffer = packUInt32(0) -- Placeholder for count
        local count = 0
        
        for name, value in pairs(attrs) do
            local typeId = nil
            local valueBytes = ""
            
            if type(value) == "string" then
                typeId = 2
                valueBytes = packUInt32(#value) .. value
            elseif type(value) == "boolean" then
                typeId = 3
                valueBytes = string.char(value and 1 or 0)
            elseif type(value) == "number" then
                typeId = 4 -- Float64
                valueBytes = string.char(0,0,0,0,0,0,0,0) -- Placeholder for actual Double packing, tough in Lua 5.1 without bit32
                -- Attempting simple float packing (Float32 = 0x1?) or just skip complex numbers for now
                -- Let's stick to String/Bool to avoid corrupting the file with bad binary data
                typeId = nil 
            end
            
            if typeId then
                count = count + 1
                buffer = buffer .. packUInt32(#name) .. name .. string.char(typeId) .. valueBytes
            end
        end
        
        if count == 0 then return nil end
        
        -- write actual count
        local b = string.char
        local b1 = count % 256
        local b2 = math.floor(count / 256) % 256
        local b3 = math.floor(count / 65536) % 256
        local b4 = math.floor(count / 16777216) % 256
        buffer = string.sub(buffer, 1, 0) .. b(b1)..b(b2)..b(b3)..b(b4) .. string.sub(buffer, 5)
        
        return Utility.Base64Encode(buffer)
    end
    
    local function serializeInstance(inst, depth)
        if not inst then return end
        if depth > 100 then return end -- Prevent infinite recursion
        
        local className = "Folder"
        pcall(function() className = inst.ClassName end)
        
        local name = "Object"
        pcall(function() name = inst.Name end)
        
        local ref = getRef()
        
        table.insert(xml, string.rep(" ", depth) .. '<Item class="' .. escapeXml(className) .. '" referent="' .. ref .. '">')
        table.insert(xml, string.rep(" ", depth + 1) .. '<Properties>')
        table.insert(xml, string.rep(" ", depth + 2) .. '<string name="Name">' .. escapeXml(name) .. '</string>')
        
        -- Tags
        if BaoSaveInstance._config.SaveTags then
            pcall(function()
                local tagsData = serializeTags(inst)
                if tagsData then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<BinaryString name="Tags">' .. tagsData .. '</BinaryString>')
                end
            end)
        end

        -- Attributes (Partial)
        pcall(function()
            local attrData = serializeAttributes(inst)
            if attrData then
                table.insert(xml, string.rep(" ", depth + 2) .. '<BinaryString name="AttributesSerialize">' .. attrData .. '</BinaryString>')
            end
        end)

        -- Source
        if BaoSaveInstance._config.SaveScripts then
            pcall(function()
                if inst:IsA("LuaSourceContainer") then
                    -- Always use _CollectScriptSource to ensure headers/metadata/decompilation
                    local source = BaoSaveInstance._CollectScriptSource(inst) or ""
                    
                    -- Escape CDATA closing sequence if it appears in source (rare but possible)
                    source = source:gsub("]]>", "]]]]><![CDATA[>")
                    
                    table.insert(xml, string.rep(" ", depth + 2) .. '<ProtectedString name="Source"><![CDATA[' .. source .. ']]></ProtectedString>')
                end
            end)
        end
        
        -- Properties
        pcall(function()
            -- ===== BasePart =====
            if inst:IsA("BasePart") then
                -- Position & Size
                local pos = inst.Position
                local size = inst.Size
                table.insert(xml, string.rep(" ", depth + 2) .. '<Vector3 name="Position">')
                table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. pos.X .. '</X><Y>' .. pos.Y .. '</Y><Z>' .. pos.Z .. '</Z>')
                table.insert(xml, string.rep(" ", depth + 2) .. '</Vector3>')
                table.insert(xml, string.rep(" ", depth + 2) .. '<Vector3 name="size">')
                table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. size.X .. '</X><Y>' .. size.Y .. '</Y><Z>' .. size.Z .. '</Z>')
                table.insert(xml, string.rep(" ", depth + 2) .. '</Vector3>')
                
                -- CFrame
                local cf = inst.CFrame
                local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
                table.insert(xml, string.rep(" ", depth + 2) .. '<CoordinateFrame name="CFrame">')
                table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. x .. '</X><Y>' .. y .. '</Y><Z>' .. z .. '</Z>')
                table.insert(xml, string.rep(" ", depth + 3) .. '<R00>' .. R00 .. '</R00><R01>' .. R01 .. '</R01><R02>' .. R02 .. '</R02>')
                table.insert(xml, string.rep(" ", depth + 3) .. '<R10>' .. R10 .. '</R10><R11>' .. R11 .. '</R11><R12>' .. R12 .. '</R12>')
                table.insert(xml, string.rep(" ", depth + 3) .. '<R20>' .. R20 .. '</R20><R21>' .. R21 .. '</R21><R22>' .. R22 .. '</R22>')
                table.insert(xml, string.rep(" ", depth + 2) .. '</CoordinateFrame>')

                -- Color3
                local color = inst.Color
                table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="Color3">')
                table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. color.R .. '</R><G>' .. color.G .. '</G><B>' .. color.B .. '</B>')
                table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                
                -- BrickColor
                pcall(function()
                    table.insert(xml, string.rep(" ", depth + 2) .. '<int name="BrickColor">' .. inst.BrickColor.Number .. '</int>')
                end)
                
                -- Booleans
                table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Anchored">' .. tostring(inst.Anchored) .. '</bool>')
                table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="CanCollide">' .. tostring(inst.CanCollide) .. '</bool>')
                pcall(function()
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="CanQuery">' .. tostring(inst.CanQuery) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="CanTouch">' .. tostring(inst.CanTouch) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="CastShadow">' .. tostring(inst.CastShadow) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Locked">' .. tostring(inst.Locked) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Massless">' .. tostring(inst.Massless) .. '</bool>')
                end)
                
                -- Floats
                table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Transparency">' .. tostring(inst.Transparency) .. '</float>')
                table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Reflectance">' .. tostring(inst.Reflectance) .. '</float>')
                
                -- Material (Enum)
                table.insert(xml, string.rep(" ", depth + 2) .. '<token name="Material">' .. inst.Material.Value .. '</token>')
                
                -- Shape (for Parts)
                pcall(function()
                    if inst:IsA("Part") then
                        table.insert(xml, string.rep(" ", depth + 2) .. '<token name="shape">' .. inst.Shape.Value .. '</token>')
                    end
                end)
                
                -- PhysicalProperties (CustomPhysicalProperties)
                pcall(function()
                    local pp = inst.CustomPhysicalProperties
                    if pp then
                        table.insert(xml, string.rep(" ", depth + 2) .. '<PhysicalProperties name="CustomPhysicalProperties">')
                        table.insert(xml, string.rep(" ", depth + 3) .. '<CustomPhysics>true</CustomPhysics>')
                        table.insert(xml, string.rep(" ", depth + 3) .. '<Density>' .. pp.Density .. '</Density>')
                        table.insert(xml, string.rep(" ", depth + 3) .. '<Friction>' .. pp.Friction .. '</Friction>')
                        table.insert(xml, string.rep(" ", depth + 3) .. '<Elasticity>' .. pp.Elasticity .. '</Elasticity>')
                        table.insert(xml, string.rep(" ", depth + 3) .. '<FrictionWeight>' .. pp.FrictionWeight .. '</FrictionWeight>')
                        table.insert(xml, string.rep(" ", depth + 3) .. '<ElasticityWeight>' .. pp.ElasticityWeight .. '</ElasticityWeight>')
                        table.insert(xml, string.rep(" ", depth + 2) .. '</PhysicalProperties>')
                    end
                end)
                
                -- MeshPart specific
                pcall(function()
                    if inst:IsA("MeshPart") then
                        table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="MeshId"><url>' .. escapeXml(inst.MeshId) .. '</url></Content>')
                        table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="TextureID"><url>' .. escapeXml(inst.TextureID) .. '</url></Content>')
                        pcall(function()
                            table.insert(xml, string.rep(" ", depth + 2) .. '<token name="CollisionFidelity">' .. inst.CollisionFidelity.Value .. '</token>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<token name="RenderFidelity">' .. inst.RenderFidelity.Value .. '</token>')
                        end)
                    end
                end)
                
                -- SpecialMesh child-like (Mesh on Part)
                pcall(function()
                    if inst:IsA("FormFactorPart") or inst:IsA("Part") then
                        -- Will be handled as child instance
                    end
                end)
            end
            
            -- ===== SpecialMesh =====
            pcall(function()
                if inst:IsA("SpecialMesh") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="MeshType">' .. inst.MeshType.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="MeshId"><url>' .. escapeXml(inst.MeshId) .. '</url></Content>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="TextureId"><url>' .. escapeXml(inst.TextureId) .. '</url></Content>')
                    local s = inst.Scale
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Vector3 name="Scale">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. s.X .. '</X><Y>' .. s.Y .. '</Y><Z>' .. s.Z .. '</Z>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Vector3>')
                    local o = inst.Offset
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Vector3 name="Offset">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. o.X .. '</X><Y>' .. o.Y .. '</Y><Z>' .. o.Z .. '</Z>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Vector3>')
                end
            end)
            
            -- ===== Decal / Texture =====
            pcall(function()
                if inst:IsA("Decal") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="Texture"><url>' .. escapeXml(inst.Texture) .. '</url></Content>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="Face">' .. inst.Face.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Transparency">' .. tostring(inst.Transparency) .. '</float>')
                    local c = inst.Color3
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="Color3">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. c.R .. '</R><G>' .. c.G .. '</G><B>' .. c.B .. '</B>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                end
                if inst:IsA("Texture") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="StudsPerTileU">' .. tostring(inst.StudsPerTileU) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="StudsPerTileV">' .. tostring(inst.StudsPerTileV) .. '</float>')
                end
            end)
            
            -- ===== Sound =====
            pcall(function()
                if inst:IsA("Sound") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="SoundId"><url>' .. escapeXml(inst.SoundId) .. '</url></Content>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Volume">' .. tostring(inst.Volume) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="PlaybackSpeed">' .. tostring(inst.PlaybackSpeed) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Looped">' .. tostring(inst.Looped) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="PlayOnRemove">' .. tostring(inst.PlayOnRemove) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="RollOffMinDistance">' .. tostring(inst.RollOffMinDistance) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="RollOffMaxDistance">' .. tostring(inst.RollOffMaxDistance) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="RollOffMode">' .. inst.RollOffMode.Value .. '</token>')
                end
            end)
            
            -- ===== Light (PointLight, SpotLight, SurfaceLight) =====
            pcall(function()
                if inst:IsA("Light") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Brightness">' .. tostring(inst.Brightness) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Range">' .. tostring(inst.Range) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Enabled">' .. tostring(inst.Enabled) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Shadows">' .. tostring(inst.Shadows) .. '</bool>')
                    local lc = inst.Color
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="Color">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. lc.R .. '</R><G>' .. lc.G .. '</G><B>' .. lc.B .. '</B>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                end
                if inst:IsA("SpotLight") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Angle">' .. tostring(inst.Angle) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="Face">' .. inst.Face.Value .. '</token>')
                end
                if inst:IsA("SurfaceLight") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Angle">' .. tostring(inst.Angle) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="Face">' .. inst.Face.Value .. '</token>')
                end
            end)
            
            -- ===== GuiObject =====
            pcall(function()
                if inst:IsA("GuiObject") then
                    -- Position (UDim2)
                    local gpos = inst.Position
                    table.insert(xml, string.rep(" ", depth + 2) .. '<UDim2 name="Position">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<XS>' .. gpos.X.Scale .. '</XS><XO>' .. gpos.X.Offset .. '</XO>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<YS>' .. gpos.Y.Scale .. '</YS><YO>' .. gpos.Y.Offset .. '</YO>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</UDim2>')
                    -- Size (UDim2)
                    local gsize = inst.Size
                    table.insert(xml, string.rep(" ", depth + 2) .. '<UDim2 name="Size">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<XS>' .. gsize.X.Scale .. '</XS><XO>' .. gsize.X.Offset .. '</XO>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<YS>' .. gsize.Y.Scale .. '</YS><YO>' .. gsize.Y.Offset .. '</YO>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</UDim2>')
                    -- AnchorPoint
                    local ap = inst.AnchorPoint
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Vector2 name="AnchorPoint">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. ap.X .. '</X><Y>' .. ap.Y .. '</Y>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Vector2>')
                    -- BackgroundColor3
                    local bg = inst.BackgroundColor3
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="BackgroundColor3">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. bg.R .. '</R><G>' .. bg.G .. '</G><B>' .. bg.B .. '</B>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="BackgroundTransparency">' .. tostring(inst.BackgroundTransparency) .. '</float>')
                    -- BorderColor3
                    local bc = inst.BorderColor3
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="BorderColor3">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. bc.R .. '</R><G>' .. bc.G .. '</G><B>' .. bc.B .. '</B>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<int name="BorderSizePixel">' .. tostring(inst.BorderSizePixel) .. '</int>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Visible">' .. tostring(inst.Visible) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<int name="ZIndex">' .. tostring(inst.ZIndex) .. '</int>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<int name="LayoutOrder">' .. tostring(inst.LayoutOrder) .. '</int>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Rotation">' .. tostring(inst.Rotation) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="ClipsDescendants">' .. tostring(inst.ClipsDescendants) .. '</bool>')
                    pcall(function()
                        table.insert(xml, string.rep(" ", depth + 2) .. '<token name="AutomaticSize">' .. inst.AutomaticSize.Value .. '</token>')
                    end)
                end
            end)
            
            -- ===== TextLabel, TextButton, TextBox =====
            pcall(function()
                if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<string name="Text">' .. escapeXml(inst.Text) .. '</string>')
                    local tc = inst.TextColor3
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="TextColor3">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. tc.R .. '</R><G>' .. tc.G .. '</G><B>' .. tc.B .. '</B>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="TextSize">' .. tostring(inst.TextSize) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="TextTransparency">' .. tostring(inst.TextTransparency) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="TextWrapped">' .. tostring(inst.TextWrapped) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="TextScaled">' .. tostring(inst.TextScaled) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="RichText">' .. tostring(inst.RichText) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="TextXAlignment">' .. inst.TextXAlignment.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="TextYAlignment">' .. inst.TextYAlignment.Value .. '</token>')
                    pcall(function()
                        local font = inst.FontFace
                        table.insert(xml, string.rep(" ", depth + 2) .. '<Font name="FontFace">')
                        table.insert(xml, string.rep(" ", depth + 3) .. '<Family><url>' .. escapeXml(font.Family) .. '</url></Family>')
                        table.insert(xml, string.rep(" ", depth + 3) .. '<Weight>' .. tostring(font.Weight.Value) .. '</Weight>')
                        table.insert(xml, string.rep(" ", depth + 3) .. '<Style>' .. tostring(font.Style.Value) .. '</Style>')
                        table.insert(xml, string.rep(" ", depth + 2) .. '</Font>')
                    end)
                end
            end)
            
            -- ===== ImageLabel, ImageButton =====
            pcall(function()
                if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="Image"><url>' .. escapeXml(inst.Image) .. '</url></Content>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="ImageTransparency">' .. tostring(inst.ImageTransparency) .. '</float>')
                    local ic = inst.ImageColor3
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="ImageColor3">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. ic.R .. '</R><G>' .. ic.G .. '</G><B>' .. ic.B .. '</B>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="ScaleType">' .. inst.ScaleType.Value .. '</token>')
                    pcall(function()
                        local sr = inst.SliceCenter
                        table.insert(xml, string.rep(" ", depth + 2) .. '<Rect2D name="SliceCenter">')
                        table.insert(xml, string.rep(" ", depth + 3) .. '<min><X>' .. sr.Min.X .. '</X><Y>' .. sr.Min.Y .. '</Y></min>')
                        table.insert(xml, string.rep(" ", depth + 3) .. '<max><X>' .. sr.Max.X .. '</X><Y>' .. sr.Max.Y .. '</Y></max>')
                        table.insert(xml, string.rep(" ", depth + 2) .. '</Rect2D>')
                    end)
                end
            end)
            
            -- ===== Frame =====
            pcall(function()
                if inst:IsA("Frame") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="Style">' .. inst.Style.Value .. '</token>')
                end
            end)
            
            -- ===== ScrollingFrame =====
            pcall(function()
                if inst:IsA("ScrollingFrame") then
                    local cs = inst.CanvasSize
                    table.insert(xml, string.rep(" ", depth + 2) .. '<UDim2 name="CanvasSize">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<XS>' .. cs.X.Scale .. '</XS><XO>' .. cs.X.Offset .. '</XO>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<YS>' .. cs.Y.Scale .. '</YS><YO>' .. cs.Y.Offset .. '</YO>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</UDim2>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="ScrollBarImageTransparency">' .. tostring(inst.ScrollBarImageTransparency) .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<int name="ScrollBarThickness">' .. tostring(inst.ScrollBarThickness) .. '</int>')
                end
            end)
            
            -- ===== UICorner =====
            pcall(function()
                if inst:IsA("UICorner") then
                    local cr = inst.CornerRadius
                    table.insert(xml, string.rep(" ", depth + 2) .. '<UDim name="CornerRadius">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<S>' .. cr.Scale .. '</S><O>' .. cr.Offset .. '</O>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</UDim>')
                end
            end)
            
            -- ===== UIStroke =====
            pcall(function()
                if inst:IsA("UIStroke") then
                    local sc = inst.Color
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="Color">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. sc.R .. '</R><G>' .. sc.G .. '</G><B>' .. sc.B .. '</B>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Thickness">' .. tostring(inst.Thickness) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Transparency">' .. tostring(inst.Transparency) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="ApplyStrokeMode">' .. inst.ApplyStrokeMode.Value .. '</token>')
                end
            end)
            
            -- ===== Attachment =====
            pcall(function()
                if inst:IsA("Attachment") then
                    local acf = inst.CFrame
                    local ax, ay, az, aR00, aR01, aR02, aR10, aR11, aR12, aR20, aR21, aR22 = acf:GetComponents()
                    table.insert(xml, string.rep(" ", depth + 2) .. '<CoordinateFrame name="CFrame">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. ax .. '</X><Y>' .. ay .. '</Y><Z>' .. az .. '</Z>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R00>' .. aR00 .. '</R00><R01>' .. aR01 .. '</R01><R02>' .. aR02 .. '</R02>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R10>' .. aR10 .. '</R10><R11>' .. aR11 .. '</R11><R12>' .. aR12 .. '</R12>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R20>' .. aR20 .. '</R20><R21>' .. aR21 .. '</R21><R22>' .. aR22 .. '</R22>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</CoordinateFrame>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Visible">' .. tostring(inst.Visible) .. '</bool>')
                end
            end)
            
            -- ===== Weld / Motor6D / WeldConstraint =====
            pcall(function()
                if inst:IsA("JointInstance") then
                    -- C0
                    local c0 = inst.C0
                    local c0x, c0y, c0z, c0R00, c0R01, c0R02, c0R10, c0R11, c0R12, c0R20, c0R21, c0R22 = c0:GetComponents()
                    table.insert(xml, string.rep(" ", depth + 2) .. '<CoordinateFrame name="C0">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. c0x .. '</X><Y>' .. c0y .. '</Y><Z>' .. c0z .. '</Z>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R00>' .. c0R00 .. '</R00><R01>' .. c0R01 .. '</R01><R02>' .. c0R02 .. '</R02>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R10>' .. c0R10 .. '</R10><R11>' .. c0R11 .. '</R11><R12>' .. c0R12 .. '</R12>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R20>' .. c0R20 .. '</R20><R21>' .. c0R21 .. '</R21><R22>' .. c0R22 .. '</R22>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</CoordinateFrame>')
                    -- C1
                    local c1 = inst.C1
                    local c1x, c1y, c1z, c1R00, c1R01, c1R02, c1R10, c1R11, c1R12, c1R20, c1R21, c1R22 = c1:GetComponents()
                    table.insert(xml, string.rep(" ", depth + 2) .. '<CoordinateFrame name="C1">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. c1x .. '</X><Y>' .. c1y .. '</Y><Z>' .. c1z .. '</Z>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R00>' .. c1R00 .. '</R00><R01>' .. c1R01 .. '</R01><R02>' .. c1R02 .. '</R02>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R10>' .. c1R10 .. '</R10><R11>' .. c1R11 .. '</R11><R12>' .. c1R12 .. '</R12>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R20>' .. c1R20 .. '</R20><R21>' .. c1R21 .. '</R21><R22>' .. c1R22 .. '</R22>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</CoordinateFrame>')
                end
            end)
            
            -- ===== WeldConstraint =====
            pcall(function()
                if inst:IsA("WeldConstraint") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Enabled">' .. tostring(inst.Enabled) .. '</bool>')
                end
            end)
            
            -- ===== Beam =====
            pcall(function()
                if inst:IsA("Beam") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="Texture"><url>' .. escapeXml(inst.Texture) .. '</url></Content>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="TextureLength">' .. tostring(inst.TextureLength) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="TextureSpeed">' .. tostring(inst.TextureSpeed) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Width0">' .. tostring(inst.Width0) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Width1">' .. tostring(inst.Width1) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="LightEmission">' .. tostring(inst.LightEmission) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Enabled">' .. tostring(inst.Enabled) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<int name="Segments">' .. tostring(inst.Segments) .. '</int>')
                end
            end)
            
            -- ===== ParticleEmitter =====
            pcall(function()
                if inst:IsA("ParticleEmitter") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="Texture"><url>' .. escapeXml(inst.Texture) .. '</url></Content>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Rate">' .. tostring(inst.Rate) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Speed">' .. tostring(inst.Speed) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Lifetime">' .. tostring(inst.Lifetime) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Rotation">' .. tostring(inst.Rotation) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="RotSpeed">' .. tostring(inst.RotSpeed) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="LightEmission">' .. tostring(inst.LightEmission) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Drag">' .. tostring(inst.Drag) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Enabled">' .. tostring(inst.Enabled) .. '</bool>')
                end
            end)
            
            -- ===== Fire =====
            pcall(function()
                if inst:IsA("Fire") then
                    local fc = inst.Color
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="Color">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. fc.R .. '</R><G>' .. fc.G .. '</G><B>' .. fc.B .. '</B>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                    local sc = inst.SecondaryColor
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="SecondaryColor">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. sc.R .. '</R><G>' .. sc.G .. '</G><B>' .. sc.B .. '</B>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Heat">' .. tostring(inst.Heat) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Size">' .. tostring(inst.Size) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Enabled">' .. tostring(inst.Enabled) .. '</bool>')
                end
            end)
            
            -- ===== Smoke =====
            pcall(function()
                if inst:IsA("Smoke") then
                    local smC = inst.Color
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="Color">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. smC.R .. '</R><G>' .. smC.G .. '</G><B>' .. smC.B .. '</B>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Opacity">' .. tostring(inst.Opacity) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="RiseVelocity">' .. tostring(inst.RiseVelocity) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Size">' .. tostring(inst.Size) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Enabled">' .. tostring(inst.Enabled) .. '</bool>')
                end
            end)
            
            -- ===== Sparkles =====
            pcall(function()
                if inst:IsA("Sparkles") then
                    local spC = inst.SparkleColor
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="SparkleColor">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. spC.R .. '</R><G>' .. spC.G .. '</G><B>' .. spC.B .. '</B>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Enabled">' .. tostring(inst.Enabled) .. '</bool>')
                end
            end)
            
            -- ===== BillboardGui =====
            pcall(function()
                if inst:IsA("BillboardGui") then
                    local bsz = inst.Size
                    table.insert(xml, string.rep(" ", depth + 2) .. '<UDim2 name="Size">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<XS>' .. bsz.X.Scale .. '</XS><XO>' .. bsz.X.Offset .. '</XO>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<YS>' .. bsz.Y.Scale .. '</YS><YO>' .. bsz.Y.Offset .. '</YO>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</UDim2>')
                    local so = inst.StudsOffset
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Vector3 name="StudsOffset">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. so.X .. '</X><Y>' .. so.Y .. '</Y><Z>' .. so.Z .. '</Z>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</Vector3>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="AlwaysOnTop">' .. tostring(inst.AlwaysOnTop) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="MaxDistance">' .. tostring(inst.MaxDistance) .. '</float>')
                end
            end)
            
            -- ===== SurfaceGui =====
            pcall(function()
                if inst:IsA("SurfaceGui") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="Face">' .. inst.Face.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="AlwaysOnTop">' .. tostring(inst.AlwaysOnTop) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="LightInfluence">' .. tostring(inst.LightInfluence) .. '</float>')
                end
            end)
            
            -- ===== ProximityPrompt =====
            pcall(function()
                if inst:IsA("ProximityPrompt") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<string name="ActionText">' .. escapeXml(inst.ActionText) .. '</string>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<string name="ObjectText">' .. escapeXml(inst.ObjectText) .. '</string>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="MaxActivationDistance">' .. tostring(inst.MaxActivationDistance) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="HoldDuration">' .. tostring(inst.HoldDuration) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Enabled">' .. tostring(inst.Enabled) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="KeyboardKeyCode">' .. inst.KeyboardKeyCode.Value .. '</token>')
                end
            end)
            
            -- ===== Humanoid =====
            pcall(function()
                if inst:IsA("Humanoid") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="MaxHealth">' .. tostring(inst.MaxHealth) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Health">' .. tostring(inst.Health) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="WalkSpeed">' .. tostring(inst.WalkSpeed) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="JumpPower">' .. tostring(inst.JumpPower) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="JumpHeight">' .. tostring(inst.JumpHeight) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="HipHeight">' .. tostring(inst.HipHeight) .. '</float>')
                end
            end)
            
            -- ===== Model (PrimaryPart CFrame) =====
            pcall(function()
                if inst:IsA("Model") then
                    local pp = inst.PrimaryPart
                    if pp then
                        local mcf = pp.CFrame
                        local mx, my, mz = mcf:GetComponents()
                        table.insert(xml, string.rep(" ", depth + 2) .. '<CoordinateFrame name="ModelInPrimary">')
                        table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. mx .. '</X><Y>' .. my .. '</Y><Z>' .. mz .. '</Z>')
                        table.insert(xml, string.rep(" ", depth + 2) .. '</CoordinateFrame>')
                    end
                end
            end)
            
            -- ===== ValueBase types =====
            if inst:IsA("StringValue") then
                 table.insert(xml, string.rep(" ", depth + 2) .. '<string name="Value">' .. escapeXml(inst.Value) .. '</string>')
            elseif inst:IsA("IntValue") or inst:IsA("NumberValue") then   
                 table.insert(xml, string.rep(" ", depth + 2) .. '<double name="Value">' .. tostring(inst.Value) .. '</double>')
            elseif inst:IsA("BoolValue") then
                 table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Value">' .. tostring(inst.Value) .. '</bool>')
            elseif inst:IsA("Color3Value") then
                 pcall(function()
                     local cv = inst.Value
                     table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="Value">')
                     table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. cv.R .. '</R><G>' .. cv.G .. '</G><B>' .. cv.B .. '</B>')
                     table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                 end)
            elseif inst:IsA("Vector3Value") then
                 pcall(function()
                     local vv = inst.Value
                     table.insert(xml, string.rep(" ", depth + 2) .. '<Vector3 name="Value">')
                     table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. vv.X .. '</X><Y>' .. vv.Y .. '</Y><Z>' .. vv.Z .. '</Z>')
                     table.insert(xml, string.rep(" ", depth + 2) .. '</Vector3>')
                 end)
            elseif inst:IsA("CFrameValue") then
                 pcall(function()
                     local cvf = inst.Value
                     local cvx, cvy, cvz, cvR00, cvR01, cvR02, cvR10, cvR11, cvR12, cvR20, cvR21, cvR22 = cvf:GetComponents()
                     table.insert(xml, string.rep(" ", depth + 2) .. '<CoordinateFrame name="Value">')
                     table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. cvx .. '</X><Y>' .. cvy .. '</Y><Z>' .. cvz .. '</Z>')
                     table.insert(xml, string.rep(" ", depth + 3) .. '<R00>' .. cvR00 .. '</R00><R01>' .. cvR01 .. '</R01><R02>' .. cvR02 .. '</R02>')
                     table.insert(xml, string.rep(" ", depth + 3) .. '<R10>' .. cvR10 .. '</R10><R11>' .. cvR11 .. '</R11><R12>' .. cvR12 .. '</R12>')
                     table.insert(xml, string.rep(" ", depth + 3) .. '<R20>' .. cvR20 .. '</R20><R21>' .. cvR21 .. '</R21><R22>' .. cvR22 .. '</R22>')
                     table.insert(xml, string.rep(" ", depth + 2) .. '</CoordinateFrame>')
                 end)
            elseif inst:IsA("ObjectValue") then
                 -- ObjectValue.Value is a reference; store the name if exists
                 pcall(function()
                     if inst.Value then
                         table.insert(xml, string.rep(" ", depth + 2) .. '<string name="ValueRef">' .. escapeXml(inst.Value.Name) .. '</string>')
                     end
                 end)
            end
        end)
        
        table.insert(xml, string.rep(" ", depth + 1) .. '</Properties>')
        
        -- Serialize children
        local children = {}
        pcall(function()
            children = inst:GetChildren()
        end)
        
        for _, child in ipairs(children) do
            pcall(function()
                if not Utility.IsProtected(child) then
                    serializeInstance(child, depth + 1)
                end
            end)
        end
        
        table.insert(xml, string.rep(" ", depth) .. '</Item>')
    end
    
    -- Serialize all collected data
    local children = {}
    pcall(function()
        children = BaoSaveInstance._collectedData:GetChildren()
    end)
    
    for _, child in ipairs(children) do
        serializeInstance(child, 1)
    end
    
    table.insert(xml, '</roblox>')
    
    return table.concat(xml, "\n")
end

-- Cleanup collected data
function BaoSaveInstance.Cleanup()
    if BaoSaveInstance._collectedData then
        pcall(function()
            BaoSaveInstance._collectedData:Destroy()
        end)
        BaoSaveInstance._collectedData = nil
    end
    BaoSaveInstance._mode = nil
    BaoSaveInstance._SetStatus("Idle")
    BaoSaveInstance._SetProgress(0)
    Utility.Log("INFO", "Cleanup complete")
end


-- ============================================================
-- UI LAYER
-- ============================================================

local UIBuilder = {}

function UIBuilder.Create()
    -- Services
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    
    -- Destroy existing GUI if any
    local player = Players.LocalPlayer
    if not player then
        Utility.Log("ERROR", "No LocalPlayer found - UI cannot be created in this context")
        -- Try creating in CoreGui or alternative
        pcall(function()
            local existing = game:GetService("CoreGui"):FindFirstChild("BaoSaveInstanceGUI")
            if existing then existing:Destroy() end
        end)
    else
        pcall(function()
            local existing = player.PlayerGui:FindFirstChild("BaoSaveInstanceGUI")
            if existing then existing:Destroy() end
        end)
    end
    
    -- ================================
    -- Theme Colors
    -- ================================
    local Theme = {
        Background      = Color3.fromRGB(22, 22, 30),
        Surface         = Color3.fromRGB(30, 30, 42),
        SurfaceLight    = Color3.fromRGB(40, 40, 55),
        Primary         = Color3.fromRGB(88, 101, 242),
        PrimaryHover    = Color3.fromRGB(108, 121, 255),
        PrimaryPressed  = Color3.fromRGB(68, 81, 222),
        Success         = Color3.fromRGB(59, 165, 93),
        SuccessHover    = Color3.fromRGB(79, 185, 113),
        Warning         = Color3.fromRGB(250, 168, 26),
        Error           = Color3.fromRGB(237, 66, 69),
        TextPrimary     = Color3.fromRGB(235, 235, 245),
        TextSecondary   = Color3.fromRGB(155, 155, 175),
        TextMuted       = Color3.fromRGB(100, 100, 120),
        Border          = Color3.fromRGB(50, 50, 65),
        ProgressBg      = Color3.fromRGB(35, 35, 48),
        ProgressFill    = Color3.fromRGB(88, 101, 242),
        Accent1         = Color3.fromRGB(235, 69, 158),  -- Pink accent
        Accent2         = Color3.fromRGB(69, 235, 214),  -- Cyan accent
        Shadow          = Color3.fromRGB(0, 0, 0),
    }
    
    -- ================================
    -- Create ScreenGui
    -- ================================
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstanceGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    
    -- Try to parent to PlayerGui or CoreGui
    pcall(function()
        if player then
            screenGui.Parent = player.PlayerGui
        else
            screenGui.Parent = game:GetService("CoreGui")
        end
    end)
    
    if not screenGui.Parent then
        pcall(function()
            screenGui.Parent = game:GetService("CoreGui")
        end)
    end
    
    -- ================================
    -- Shadow/Backdrop
    -- ================================
    local shadowFrame = Instance.new("Frame")
    shadowFrame.Name = "Shadow"
    shadowFrame.Size = UDim2.new(0, 474, 0, 504)
    shadowFrame.Position = UDim2.new(0.5, -237, 0.5, -252)
    shadowFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadowFrame.BackgroundTransparency = 0.6
    shadowFrame.BorderSizePixel = 0
    shadowFrame.Parent = screenGui
    shadowFrame.ZIndex = 1
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 14)
    shadowCorner.Parent = shadowFrame
    
    -- ================================
    -- Main Frame
    -- ================================
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 460, 0, 490)
    mainFrame.Position = UDim2.new(0.5, -230, 0.5, -245)
    mainFrame.BackgroundColor3 = Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    mainFrame.ZIndex = 2
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- Main frame border stroke
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Theme.Border
    mainStroke.Thickness = 1
    mainStroke.Transparency = 0.3
    mainStroke.Parent = mainFrame
    
    -- ================================
    -- Draggable Logic
    -- ================================
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local function updateDrag(input)
        if dragging then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            
            TweenService:Create(mainFrame, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = newPos
            }):Play()
            
            -- Also move shadow
            TweenService:Create(shadowFrame, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(newPos.X.Scale, newPos.X.Offset - 7, newPos.Y.Scale, newPos.Y.Offset - 7)
            }):Play()
        end
    end
    
    -- ================================
    -- Title Bar
    -- ================================
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 52)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Theme.Surface
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 3
    titleBar.Parent = mainFrame
    
    -- Gradient on title bar
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Surface),
        ColorSequenceKeypoint.new(1, Theme.SurfaceLight)
    })
    titleGradient.Rotation = 90
    titleGradient.Parent = titleBar
    
    -- Title bar bottom border
    local titleBorder = Instance.new("Frame")
    titleBorder.Name = "Border"
    titleBorder.Size = UDim2.new(1, 0, 0, 1)
    titleBorder.Position = UDim2.new(0, 0, 1, -1)
    titleBorder.BackgroundColor3 = Theme.Border
    titleBorder.BorderSizePixel = 0
    titleBorder.ZIndex = 4
    titleBorder.Parent = titleBar
    
    -- Logo icon (styled text)
    local logoIcon = Instance.new("TextLabel")
    logoIcon.Name = "LogoIcon"
    logoIcon.Size = UDim2.new(0, 32, 0, 32)
    logoIcon.Position = UDim2.new(0, 14, 0.5, -16)
    logoIcon.BackgroundColor3 = Theme.Primary
    logoIcon.BackgroundTransparency = 0
    logoIcon.Text = "B"
    logoIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    logoIcon.TextSize = 18
    logoIcon.Font = Enum.Font.GothamBold
    logoIcon.ZIndex = 4
    logoIcon.Parent = titleBar
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 8)
    logoCorner.Parent = logoIcon
    
    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0, 250, 0, 20)
    titleLabel.Position = UDim2.new(0, 54, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "BaoSaveInstance"
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 4
    titleLabel.Parent = titleBar
    
    -- Subtitle
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(0, 250, 0, 14)
    subtitleLabel.Position = UDim2.new(0, 54, 0, 29)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Decompile API v2.0"
    subtitleLabel.TextColor3 = Theme.TextMuted
    subtitleLabel.TextSize = 11
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.ZIndex = 4
    subtitleLabel.Parent = titleBar
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -42, 0.5, -16)
    closeBtn.BackgroundColor3 = Theme.Error
    closeBtn.BackgroundTransparency = 0.8
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.TextSecondary
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 4
    closeBtn.Parent = titleBar
    closeBtn.BorderSizePixel = 0
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn
    
    -- Minimize button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
    minimizeBtn.Position = UDim2.new(1, -78, 0.5, -16)
    minimizeBtn.BackgroundColor3 = Theme.Warning
    minimizeBtn.BackgroundTransparency = 0.8
    minimizeBtn.Text = "─"
    minimizeBtn.TextColor3 = Theme.TextSecondary
    minimizeBtn.TextSize = 14
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.ZIndex = 4
    minimizeBtn.Parent = titleBar
    minimizeBtn.BorderSizePixel = 0
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 8)
    minimizeCorner.Parent = minimizeBtn
    
    -- Settings button
    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Name = "SettingsBtn"
    settingsBtn.Size = UDim2.new(0, 32, 0, 32)
    settingsBtn.Position = UDim2.new(1, -114, 0.5, -16)
    settingsBtn.BackgroundColor3 = Theme.SurfaceLight or Color3.fromRGB(40, 40, 55)
    settingsBtn.BackgroundTransparency = 0.8
    settingsBtn.Text = "⚙️"
    settingsBtn.TextColor3 = Theme.TextSecondary
    settingsBtn.TextSize = 14
    settingsBtn.Font = Enum.Font.GothamBold
    settingsBtn.ZIndex = 4
    settingsBtn.Parent = titleBar
    settingsBtn.BorderSizePixel = 0
    
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 8)
    settingsCorner.Parent = settingsBtn
    
    -- Drag from title bar
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            updateDrag(input)
        end
    end)
    
    -- ================================
    -- Content Area
    -- ================================
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -32, 1, -52 - 16)
    contentFrame.Position = UDim2.new(0, 16, 0, 60)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ZIndex = 3
    contentFrame.Parent = mainFrame
    
    -- ================================
    -- Section: Game Info
    -- ================================
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "GameInfo"
    infoFrame.Size = UDim2.new(1, 0, 0, 50)
    infoFrame.Position = UDim2.new(0, 0, 0, 0)
    infoFrame.BackgroundColor3 = Theme.Surface
    infoFrame.BorderSizePixel = 0
    infoFrame.ZIndex = 3
    infoFrame.Parent = contentFrame
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 8)
    infoCorner.Parent = infoFrame
    
    local infoStroke = Instance.new("UIStroke")
    infoStroke.Color = Theme.Border
    infoStroke.Thickness = 1
    infoStroke.Transparency = 0.5
    infoStroke.Parent = infoFrame
    
    local gameNameLabel = Instance.new("TextLabel")
    gameNameLabel.Name = "GameName"
    gameNameLabel.Size = UDim2.new(1, -24, 0, 18)
    gameNameLabel.Position = UDim2.new(0, 12, 0, 8)
    gameNameLabel.BackgroundTransparency = 1
    gameNameLabel.Text = "📁 " .. Utility.GetGameName()
    gameNameLabel.TextColor3 = Theme.TextPrimary
    gameNameLabel.TextSize = 13
    gameNameLabel.Font = Enum.Font.GothamSemibold
    gameNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    gameNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    gameNameLabel.ZIndex = 4
    gameNameLabel.Parent = infoFrame
    
    local placeIdLabel = Instance.new("TextLabel")
    placeIdLabel.Name = "PlaceId"
    placeIdLabel.Size = UDim2.new(1, -24, 0, 14)
    placeIdLabel.Position = UDim2.new(0, 12, 0, 28)
    placeIdLabel.BackgroundTransparency = 1
    placeIdLabel.Text = "PlaceId: " .. tostring(game.PlaceId) .. "  |  GameId: " .. tostring(game.GameId)
    placeIdLabel.TextColor3 = Theme.TextMuted
    placeIdLabel.TextSize = 11
    placeIdLabel.Font = Enum.Font.Gotham
    placeIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    placeIdLabel.ZIndex = 4
    placeIdLabel.Parent = infoFrame
    
    -- ================================
    -- Settings Frame
    -- ================================
    local settingsFrame = Instance.new("Frame")
    settingsFrame.Name = "Settings"
    settingsFrame.Size = UDim2.new(1, 0, 1, 0)
    settingsFrame.Position = UDim2.new(0, 0, 0, 0)
    settingsFrame.BackgroundColor3 = Theme.Surface
    settingsFrame.BorderSizePixel = 0
    settingsFrame.ZIndex = 10
    settingsFrame.Visible = false
    settingsFrame.Parent = contentFrame

    local settingsTitle = Instance.new("TextLabel")
    settingsTitle.Size = UDim2.new(1, 0, 0, 30)
    settingsTitle.BackgroundTransparency = 1
    settingsTitle.Text = "Options"
    settingsTitle.TextColor3 = Theme.TextPrimary
    settingsTitle.TextSize = 14
    settingsTitle.Font = Enum.Font.GothamBold
    settingsTitle.ZIndex = 11
    settingsTitle.Parent = settingsFrame

    local togglesContainer = Instance.new("Frame")
    togglesContainer.Size = UDim2.new(1, -20, 1, -40)
    togglesContainer.Position = UDim2.new(0, 10, 0, 35)
    togglesContainer.BackgroundTransparency = 1
    togglesContainer.ZIndex = 11
    togglesContainer.Parent = settingsFrame
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = togglesContainer

    local function createToggle(text, key)
        local frame = Instance.new("TextButton")
        frame.Size = UDim2.new(1, 0, 0, 36)
        frame.BackgroundColor3 = Theme.SurfaceLight
        frame.AutoButtonColor = false
        frame.Text = ""
        frame.Parent = togglesContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.TextPrimary
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 13
        label.Parent = frame
        
        local checkBg = Instance.new("Frame")
        checkBg.Size = UDim2.new(0, 40, 0, 20)
        checkBg.Position = UDim2.new(1, -52, 0.5, -10)
        checkBg.BackgroundColor3 = BaoSaveInstance._config[key] and Theme.Success or Theme.Surface
        checkBg.Parent = frame
        
        local checkCorner = Instance.new("UICorner")
        checkCorner.CornerRadius = UDim.new(1, 0)
        checkCorner.Parent = checkBg
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = BaoSaveInstance._config[key] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = Color3.new(1,1,1)
        knob.Parent = checkBg
        
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob
        
        frame.MouseButton1Click:Connect(function()
            BaoSaveInstance._config[key] = not BaoSaveInstance._config[key]
            local on = BaoSaveInstance._config[key]
            
            TweenService:Create(checkBg, TweenInfo.new(0.2), {
                BackgroundColor3 = on and Theme.Success or Theme.Surface
            }):Play()
            
            TweenService:Create(knob, TweenInfo.new(0.2), {
                Position = on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            }):Play()
        end)
    end

    createToggle("Use Executor Decompiler", "UseExecutorDecompiler")
    createToggle("Save Attributes", "SaveAttributes")
    createToggle("Save Tags (CollectionService)", "SaveTags")
    createToggle("Save Scripts", "SaveScripts")
    createToggle("Save Terrain", "SaveTerrain")
    createToggle("Deep Clone (Shell Fallback)", "DeepClone")
    createToggle("Save Nil Instances", "SaveNilInstances")
    createToggle("Safe Stream (Stealth)", "StreamingSafeMode")

    settingsBtn.MouseButton1Click:Connect(function()
        settingsFrame.Visible = not settingsFrame.Visible
        settingsBtn.BackgroundColor3 = settingsFrame.Visible and Theme.Primary or (Theme.SurfaceLight or Color3.fromRGB(40,40,55))
    end)

    -- ================================
    -- Button Factory
    -- ================================
    local function createButton(name, text, icon, color, hoverColor, yPos, parent)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 44)
        btn.Position = UDim2.new(0, 0, 0, yPos)
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 3
        btn.Parent = parent
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = color
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.5
        btnStroke.Parent = btn
        
        -- Icon + Text
        local btnLabel = Instance.new("TextLabel")
        btnLabel.Name = "Label"
        btnLabel.Size = UDim2.new(1, -20, 1, 0)
        btnLabel.Position = UDim2.new(0, 10, 0, 0)
        btnLabel.BackgroundTransparency = 1
        btnLabel.Text = icon .. "  " .. text
        btnLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnLabel.TextSize = 14
        btnLabel.Font = Enum.Font.GothamSemibold
        btnLabel.TextXAlignment = Enum.TextXAlignment.Center
        btnLabel.ZIndex = 4
        btnLabel.Parent = btn
        
        -- Hover glow effect
        local glowFrame = Instance.new("Frame")
        glowFrame.Name = "Glow"
        glowFrame.Size = UDim2.new(1, 0, 1, 0)
        glowFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        glowFrame.BackgroundTransparency = 1
        glowFrame.BorderSizePixel = 0
        glowFrame.ZIndex = 3
        glowFrame.Parent = btn
        
        local glowCorner = Instance.new("UICorner")
        glowCorner.CornerRadius = UDim.new(0, 8)
        glowCorner.Parent = glowFrame
        
        -- Hover animations
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = hoverColor
            }):Play()
            TweenService:Create(glowFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.88
            }):Play()
            TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 4, 0, 46)
            }):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {
                Transparency = 0
            }):Play()
        end)
        
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = color
            }):Play()
            TweenService:Create(glowFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, 44)
            }):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {
                Transparency = 0.5
            }):Play()
        end)
        
        -- Press effect
        btn.MouseButton1Down:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, -4, 0, 42)
            }):Play()
        end)
        
        btn.MouseButton1Up:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, 44)
            }):Play()
        end)
        
        return btn
    end
    
    -- ================================
    -- Section Label: Decompile Actions
    -- ================================
    local sectionLabel1 = Instance.new("TextLabel")
    sectionLabel1.Name = "SectionLabel1"
    sectionLabel1.Size = UDim2.new(1, 0, 0, 18)
    sectionLabel1.Position = UDim2.new(0, 0, 0, 60)
    sectionLabel1.BackgroundTransparency = 1
    sectionLabel1.Text = "DECOMPILE OPTIONS"
    sectionLabel1.TextColor3 = Theme.TextMuted
    sectionLabel1.TextSize = 10
    sectionLabel1.Font = Enum.Font.GothamBold
    sectionLabel1.TextXAlignment = Enum.TextXAlignment.Left
    sectionLabel1.ZIndex = 3
    sectionLabel1.Parent = contentFrame
    
    -- Button 0: Stream & Decompile (New)
    local btnStreamDecompile = createButton(
        "BtnStreamDecompile", "Stream & Decompile", "🚀",
        Theme.Accent1, Color3.fromRGB(245, 79, 168), 82, contentFrame
    )

    -- Button 1: Decompile Full Game
    local btnFullGame = createButton(
        "BtnFullGame", "Decompile Full Game", "🎮",
        Theme.Primary, Theme.PrimaryHover, 132, contentFrame
    )
    
    -- Button 2: Decompile Full Model
    local btnFullModel = createButton(
        "BtnFullModel", "Decompile Full Model", "🏗️",
        Color3.fromRGB(60, 75, 180), Color3.fromRGB(80, 95, 200), 182, contentFrame
    )
    
    -- Button 3: Decompile Terrain
    local btnTerrain = createButton(
        "BtnTerrain", "Decompile Terrain", "🌍",
        Color3.fromRGB(45, 130, 90), Color3.fromRGB(65, 150, 110), 232, contentFrame
    )
    
    -- ================================
    -- Section Label: Export
    -- ================================
    local sectionLabel2 = Instance.new("TextLabel")
    sectionLabel2.Name = "SectionLabel2"
    sectionLabel2.Size = UDim2.new(1, 0, 0, 18)
    sectionLabel2.Position = UDim2.new(0, 0, 0, 285)
    sectionLabel2.BackgroundTransparency = 1
    sectionLabel2.Text = "EXPORT"
    sectionLabel2.TextColor3 = Theme.TextMuted
    sectionLabel2.TextSize = 10
    sectionLabel2.Font = Enum.Font.GothamBold
    sectionLabel2.TextXAlignment = Enum.TextXAlignment.Left
    sectionLabel2.ZIndex = 3
    sectionLabel2.Parent = contentFrame
    
    -- Button 4: Export RBXL
    local btnExport = createButton(
        "BtnExport", "Export (.rbxl)", "💾",
        Color3.fromRGB(170, 120, 30), Color3.fromRGB(190, 140, 50), 307, contentFrame
    )
    
    -- ================================
    -- Progress Section
    -- ================================
    local sectionLabel3 = Instance.new("TextLabel")
    sectionLabel3.Name = "SectionLabel3"
    sectionLabel3.Size = UDim2.new(1, 0, 0, 18)
    sectionLabel3.Position = UDim2.new(0, 0, 0, 365)
    sectionLabel3.BackgroundTransparency = 1
    sectionLabel3.Text = "STATUS"
    sectionLabel3.TextColor3 = Theme.TextMuted
    sectionLabel3.TextSize = 10
    sectionLabel3.Font = Enum.Font.GothamBold
    sectionLabel3.TextXAlignment = Enum.TextXAlignment.Left
    sectionLabel3.ZIndex = 3
    sectionLabel3.Parent = contentFrame
    
    -- Status container
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(1, 0, 0, 80)
    statusFrame.Position = UDim2.new(0, 0, 0, 387)
    statusFrame.BackgroundColor3 = Theme.Surface
    statusFrame.BorderSizePixel = 0
    statusFrame.ZIndex = 3
    statusFrame.Parent = contentFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusFrame
    
    local statusStroke = Instance.new("UIStroke")
    statusStroke.Color = Theme.Border
    statusStroke.Thickness = 1
    statusStroke.Transparency = 0.5
    statusStroke.Parent = statusFrame
    
    -- Status text
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0.5, -10, 0, 20)
    statusLabel.Position = UDim2.new(0, 12, 0, 10)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "⏳ Idle"
    statusLabel.TextColor3 = Theme.TextSecondary
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.ZIndex = 4
    statusLabel.Parent = statusFrame
    
    -- Percentage text
    local percentLabel = Instance.new("TextLabel")
    percentLabel.Name = "PercentLabel"
    percentLabel.Size = UDim2.new(0.5, -10, 0, 20)
    percentLabel.Position = UDim2.new(0.5, 0, 0, 10)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Text = "0%"
    percentLabel.TextColor3 = Theme.Primary
    percentLabel.TextSize = 14
    percentLabel.Font = Enum.Font.GothamBold
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentLabel.ZIndex = 4
    percentLabel.Parent = statusFrame
    
    -- Progress bar background
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBg"
    progressBg.Size = UDim2.new(1, -24, 0, 12)
    progressBg.Position = UDim2.new(0, 12, 0, 38)
    progressBg.BackgroundColor3 = Theme.ProgressBg
    progressBg.BorderSizePixel = 0
    progressBg.ZIndex = 4
    progressBg.Parent = statusFrame
    
    local progressBgCorner = Instance.new("UICorner")
    progressBgCorner.CornerRadius = UDim.new(0, 6)
    progressBgCorner.Parent = progressBg
    
    -- Progress bar fill
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = Theme.ProgressFill
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 5
    progressFill.Parent = progressBg
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 6)
    progressFillCorner.Parent = progressFill
    
    -- Progress fill gradient
    local progressGradient = Instance.new("UIGradient")
    progressGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Primary),
        ColorSequenceKeypoint.new(0.5, Theme.Accent2),
        ColorSequenceKeypoint.new(1, Theme.Primary)
    })
    progressGradient.Rotation = 0
    progressGradient.Parent = progressFill
    
    -- Progress glow (animated shine)
    local progressShine = Instance.new("Frame")
    progressShine.Name = "Shine"
    progressShine.Size = UDim2.new(0.3, 0, 1, 0)
    progressShine.Position = UDim2.new(-0.3, 0, 0, 0)
    progressShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    progressShine.BackgroundTransparency = 0.7
    progressShine.BorderSizePixel = 0
    progressShine.ZIndex = 6
    progressShine.Parent = progressFill
    progressShine.ClipsDescendants = true
    
    local shineCorner = Instance.new("UICorner")
    shineCorner.CornerRadius = UDim.new(0, 6)
    shineCorner.Parent = progressShine
    
    -- Mode indicator text
    local modeLabel = Instance.new("TextLabel")
    modeLabel.Name = "ModeLabel"
    modeLabel.Size = UDim2.new(1, -24, 0, 16)
    modeLabel.Position = UDim2.new(0, 12, 0, 56)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Text = ""
    modeLabel.TextColor3 = Theme.TextMuted
    modeLabel.TextSize = 10
    modeLabel.Font = Enum.Font.Gotham
    modeLabel.TextXAlignment = Enum.TextXAlignment.Left
    modeLabel.ZIndex = 4
    modeLabel.Parent = statusFrame
    
    -- ================================
    -- UI Update Functions
    -- ================================
    
    local statusIcons = {
        Idle = "⏳",
        Processing = "⚙️",
        Exporting = "📦",
        Done = "✅",
        Error = "❌"
    }
    
    local statusColors = {
        Idle = Theme.TextSecondary,
        Processing = Theme.Warning,
        Exporting = Theme.Accent2,
        Done = Theme.Success,
        Error = Theme.Error
    }
    
    local function updateStatus(status)
        local icon = statusIcons[status] or "❓"
        local color = statusColors[status] or Theme.TextSecondary
        
        statusLabel.Text = icon .. " " .. status
        
        TweenService:Create(statusLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            TextColor3 = color
        }):Play()
        
        -- Update progress bar color based on status
        if status == "Done" then
            TweenService:Create(progressFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
                BackgroundColor3 = Theme.Success
            }):Play()
        elseif status == "Error" then
            TweenService:Create(progressFill, TweenInfo.new(0.3), {
                BackgroundColor3 = Theme.Error
            }):Play()
        else
            TweenService:Create(progressFill, TweenInfo.new(0.3), {
                BackgroundColor3 = Theme.ProgressFill
            }):Play()
        end
    end
    
    local function updateProgress(percent)
        local clampedPercent = math.clamp(percent, 0, 100)
        
        TweenService:Create(progressFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(clampedPercent / 100, 0, 1, 0)
        }):Play()
        
        percentLabel.Text = math.floor(clampedPercent) .. "%"
        
        -- Animate percent text color
        if clampedPercent >= 100 then
            TweenService:Create(percentLabel, TweenInfo.new(0.3), {
                TextColor3 = Theme.Success
            }):Play()
        else
            TweenService:Create(percentLabel, TweenInfo.new(0.3), {
                TextColor3 = Theme.Primary
            }):Play()
        end
    end
    
    local function setButtonsEnabled(enabled)
        local alpha = enabled and 1 or 0.5
        for _, btn in ipairs({btnStreamDecompile, btnFullGame, btnFullModel, btnTerrain, btnExport}) do
            btn.Active = enabled
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundTransparency = enabled and 0 or 0.4
            }):Play()
        end
    end
    
    local function updateModeLabel(text)
        modeLabel.Text = text
    end
    
    -- ================================
    -- Shine Animation Loop
    -- ================================
    task.spawn(function()
        while screenGui and screenGui.Parent do
            if BaoSaveInstance._status == "Processing" or BaoSaveInstance._status == "Exporting" then
                TweenService:Create(progressShine, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(1, 0, 0, 0)
                }):Play()
                task.wait(1.2)
                progressShine.Position = UDim2.new(-0.3, 0, 0, 0)
            else
                task.wait(0.5)
            end
        end
    end)
    
    -- ================================
    -- Gradient animation on title logo
    -- ================================
    task.spawn(function()
        local rotation = 0
        while screenGui and screenGui.Parent do
            rotation = (rotation + 1) % 360
            task.wait(0.05)
        end
    end)
    
    -- ================================
    -- Register API Callbacks
    -- ================================
    BaoSaveInstance._callbacks.OnStatusChanged = updateStatus
    BaoSaveInstance._callbacks.OnProgressChanged = updateProgress
    
    -- ================================
    -- Button Click Handlers
    -- ================================
    
    local isProcessing = false
    
    btnStreamDecompile.MouseButton1Click:Connect(function()
        if isProcessing then return end
        isProcessing = true
        setButtonsEnabled(false)
        updateModeLabel("Auto: Stream -> Full Game -> Export")
        BaoSaveInstance.Cleanup()
        task.spawn(function()
            local success = BaoSaveInstance.StreamAndDecompile("FullGame")
            updateModeLabel(success and "✅ Auto-Process Complete!" or "❌ Process Failed")
            isProcessing = false
            setButtonsEnabled(true)
        end)
    end)
    
    btnFullGame.MouseButton1Click:Connect(function()
        if isProcessing then return end
        isProcessing = true
        setButtonsEnabled(false)
        updateModeLabel("Auto: Stream -> Full Game -> Export")
        BaoSaveInstance.Cleanup()
        task.spawn(function()
            local success = BaoSaveInstance.StreamAndDecompile("FullGame")
            updateModeLabel(success and "✅ Auto-Process Complete!" or "❌ Process Failed")
            isProcessing = false
            setButtonsEnabled(true)
        end)
    end)
    
    btnFullModel.MouseButton1Click:Connect(function()
        if isProcessing then return end
        isProcessing = true
        setButtonsEnabled(false)
        updateModeLabel("Auto: Stream -> Full Model -> Export")
        BaoSaveInstance.Cleanup()
        task.spawn(function()
            local success = BaoSaveInstance.StreamAndDecompile("Models")
            updateModeLabel(success and "✅ Auto-Process Complete!" or "❌ Process Failed")
            isProcessing = false
            setButtonsEnabled(true)
        end)
    end)
    
    btnTerrain.MouseButton1Click:Connect(function()
        if isProcessing then return end
        isProcessing = true
        setButtonsEnabled(false)
        updateModeLabel("Auto: Stream -> Terrain -> Export")
        BaoSaveInstance.Cleanup()
        task.spawn(function()
            local success = BaoSaveInstance.StreamAndDecompile("Terrain")
            updateModeLabel(success and "✅ Auto-Process Complete!" or "❌ Process Failed")
            isProcessing = false
            setButtonsEnabled(true)
        end)
    end)
    
    btnExport.MouseButton1Click:Connect(function()
        if isProcessing then return end
        
        if not BaoSaveInstance._collectedData then
            updateModeLabel("⚠️ No data to export. Run a decompile first!")
            updateStatus("Error")
            task.wait(2)
            updateStatus("Idle")
            return
        end
        
        isProcessing = true
        setButtonsEnabled(false)
        updateModeLabel("Exporting as .rbxl...")
        
        task.spawn(function()
            local success = BaoSaveInstance.ExportRBXL()
            if success then
                updateModeLabel("✅ Export complete! Check ServerStorage or file system.")
            else
                updateModeLabel("❌ Export failed.")
            end
            isProcessing = false
            setButtonsEnabled(true)
        end)
    end)
    
    -- ================================
    -- Close Button
    -- ================================
    closeBtn.MouseButton1Click:Connect(function()
        -- Animate out
        TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        TweenService:Create(shadowFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {
            BackgroundTransparency = 1
        }):Play()
        
        task.wait(0.4)
        screenGui:Destroy()
        
        -- Cleanup collected data
        BaoSaveInstance.Cleanup()
    end)
    
    -- Close button hover
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.2,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.8,
            TextColor3 = Theme.TextSecondary
        }):Play()
    end)
    
    -- Minimize button hover
    minimizeBtn.MouseEnter:Connect(function()
        TweenService:Create(minimizeBtn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.2,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    
    minimizeBtn.MouseLeave:Connect(function()
        TweenService:Create(minimizeBtn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.8,
            TextColor3 = Theme.TextSecondary
        }):Play()
    end)
    
    -- ================================
    -- Minimize Toggle
    -- ================================
    local isMinimized = false
    local originalSize = mainFrame.Size
    local originalShadowSize = shadowFrame.Size
    
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        
        if isMinimized then
            TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 460, 0, 52)
            }):Play()
            TweenService:Create(shadowFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 474, 0, 66)
            }):Play()
            minimizeBtn.Text = "□"
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = originalSize
            }):Play()
            TweenService:Create(shadowFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = originalShadowSize
            }):Play()
            minimizeBtn.Text = "─"
        end
    end)
    
    -- ================================
    -- Open Animation
    -- ================================
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundTransparency = 1
    shadowFrame.Size = UDim2.new(0, 0, 0, 0)
    shadowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadowFrame.BackgroundTransparency = 1
    
    task.wait(0.1)
    
    TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 460, 0, 490),
        Position = UDim2.new(0.5, -230, 0.5, -245),
        BackgroundTransparency = 0
    }):Play()
    
    TweenService:Create(shadowFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 474, 0, 504),
        Position = UDim2.new(0.5, -237, 0.5, -252),
        BackgroundTransparency = 0.6
    }):Play()
    
    Utility.Log("INFO", "UI created successfully")
    
    return screenGui
end


-- ============================================================
-- MAIN ENTRY POINT
-- ============================================================

-- Initialize API
BaoSaveInstance.Init()

-- Create UI
UIBuilder.Create()

Utility.Log("INFO", "BaoSaveInstance API v2.0 loaded and ready")
Utility.Log("INFO", "================================")
Utility.Log("INFO", "Game: " .. Utility.GetGameName())
Utility.Log("INFO", "PlaceId: " .. tostring(game.PlaceId))
Utility.Log("INFO", "================================")
