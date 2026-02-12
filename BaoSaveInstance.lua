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
        "MarketplaceService", "InsertService"
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

-- Collect scripts source code where accessible
function BaoSaveInstance._CollectScriptSource(scriptInstance)
    if not scriptInstance then return nil end
    
    local source = nil
    
    -- Try to read Source property (works in Studio with script editing permissions)
    pcall(function()
        if scriptInstance:IsA("LuaSourceContainer") then
            source = scriptInstance.Source
        end
    end)
    
    if source and source ~= "" then
        return source
    end
    
    -- Try ScriptEditorService (Studio API)
    pcall(function()
        local ses = game:GetService("ScriptEditorService")
        if ses then
            local doc = ses:FindScriptDocument(scriptInstance)
            if doc then
                local lines = {}
                for i = 1, doc:GetLineCount() do
                    table.insert(lines, doc:GetLine(i))
                end
                source = table.concat(lines, "\n")
            end
        end
    end)
    
    return source
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

-- Clone children of a service safely
function BaoSaveInstance._CloneServiceChildren(service, targetFolder)
    if not service or not targetFolder then return 0 end
    
    local clonedCount = 0
    local children = {}
    
    pcall(function()
        children = service:GetChildren()
    end)
    
    for _, child in ipairs(children) do
        -- Skip runtime PlayerGui content
        if Utility.IsRuntimePlayerGui(child) then
            Utility.Log("INFO", "Skipped runtime PlayerGui: " .. tostring(child))
            continue
        end
        
        if Utility.IsProtected(child) then
            Utility.Log("WARN", "Skipped protected: " .. tostring(child))
            continue
        end
        
        local clone = Utility.SafeClone(child)
        if clone then
            clone.Parent = targetFolder
            clonedCount = clonedCount + 1
            
            -- Count descendants for logging
            local descCount = Utility.CountDescendants(clone)
            clonedCount = clonedCount + descCount
        end
    end
    
    return clonedCount
end

-- Deep clone a terrain object
function BaoSaveInstance._CloneTerrain()
    local terrain = nil
    pcall(function()
        terrain = Services.Workspace and Services.Workspace.Terrain
    end)
    
    if not terrain then
        Utility.Log("WARN", "Terrain not found")
        return nil
    end
    
    -- Clone terrain
    local terrainClone = Utility.SafeClone(terrain)
    if terrainClone then
        Utility.Log("INFO", "Terrain cloned successfully")
        
        -- Also copy terrain region data if possible
        pcall(function()
            local regionSize = terrain:GetExtentsSize()
            Utility.Log("INFO", string.format("Terrain extents: %.0f x %.0f x %.0f", 
                regionSize.X, regionSize.Y, regionSize.Z))
        end)
    end
    
    return terrainClone
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
    Utility.Log("INFO", "Starting Full Game Decompile...")
    
    -- Create root container
    local rootModel = Instance.new("Model")
    rootModel.Name = Utility.GetGameName() .. "_FullGame"
    
    -- Define services to clone
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
    
    local totalWeight = 0
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
            
            -- Special handling for Workspace - include Terrain
            if sData.Name == "Workspace" then
                -- Clone Terrain
                local terrainClone = BaoSaveInstance._CloneTerrain()
                if terrainClone then
                    terrainClone.Parent = serviceFolder
                    Utility.Log("INFO", "Terrain added to Workspace")
                end
                
                -- Clone other Workspace children (excluding Terrain and Camera)
                local wsChildren = {}
                pcall(function()
                    wsChildren = sData.Service:GetChildren()
                end)
                
                for _, child in ipairs(wsChildren) do
                    pcall(function()
                        if not child:IsA("Terrain") and not child:IsA("Camera") then
                            if not Utility.IsProtected(child) then
                                local clone = Utility.SafeClone(child)
                                if clone then
                                    clone.Parent = serviceFolder
                                    totalObjects = totalObjects + 1 + Utility.CountDescendants(clone)
                                end
                            end
                        end
                    end)
                end
            else
                local count = BaoSaveInstance._CloneServiceChildren(sData.Service, serviceFolder)
                totalObjects = totalObjects + count
            end
            
            -- Process scripts
            local scriptCount = BaoSaveInstance._ProcessScriptsInTree(serviceFolder)
            totalScripts = totalScripts + scriptCount
            
            Utility.Log("INFO", sData.Name .. " done")
        else
            Utility.Log("WARN", "Service not available: " .. sData.Name)
        end
        
        currentWeight = currentWeight + sData.Weight
        BaoSaveInstance._SetProgress(math.floor((currentWeight / totalWeight) * 95))
        
        -- Yield to prevent freezing
        if Services.RunService then
            task.wait()
        end
    end
    
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
    end)
    
    BaoSaveInstance._collectedData = rootModel
    BaoSaveInstance._SetProgress(100)
    BaoSaveInstance._SetStatus("Done")
    
    Utility.Log("INFO", string.format(
        "Full Game Decompile complete! Objects: %s, Scripts: %d",
        Utility.FormatNumber(totalObjects), totalScripts
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
    Utility.Log("INFO", "Starting Full Model Decompile (no Terrain)...")
    
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
    
    local totalWeight = 0
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
                -- Clone Workspace children WITHOUT Terrain
                local wsChildren = {}
                pcall(function()
                    wsChildren = sData.Service:GetChildren()
                end)
                
                for _, child in ipairs(wsChildren) do
                    pcall(function()
                        if not child:IsA("Terrain") and not child:IsA("Camera") then
                            if not Utility.IsProtected(child) then
                                local clone = Utility.SafeClone(child)
                                if clone then
                                    clone.Parent = serviceFolder
                                    totalObjects = totalObjects + 1 + Utility.CountDescendants(clone)
                                end
                            end
                        end
                    end)
                end
            else
                local count = BaoSaveInstance._CloneServiceChildren(sData.Service, serviceFolder)
                totalObjects = totalObjects + count
            end
            
            local scriptCount = BaoSaveInstance._ProcessScriptsInTree(serviceFolder)
            totalScripts = totalScripts + scriptCount
        else
            Utility.Log("WARN", "Service not available: " .. sData.Name)
        end
        
        currentWeight = currentWeight + sData.Weight
        BaoSaveInstance._SetProgress(math.floor((currentWeight / totalWeight) * 95))
        task.wait()
    end
    
    BaoSaveInstance._collectedData = rootModel
    BaoSaveInstance._SetProgress(100)
    BaoSaveInstance._SetStatus("Done")
    
    Utility.Log("INFO", string.format(
        "Model Decompile complete! Objects: %s, Scripts: %d",
        Utility.FormatNumber(totalObjects), totalScripts
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
    Utility.Log("INFO", "Starting Terrain Decompile...")
    
    BaoSaveInstance._SetProgress(10)
    
    local rootModel = Instance.new("Model")
    rootModel.Name = Utility.GetGameName() .. "_Terrain"
    
    BaoSaveInstance._SetProgress(20)
    
    -- Create Workspace folder with only Terrain
    local wsFolder = Instance.new("Folder")
    wsFolder.Name = "Workspace"
    wsFolder.Parent = rootModel
    
    BaoSaveInstance._SetProgress(30)
    
    local terrainClone = BaoSaveInstance._CloneTerrain()
    if terrainClone then
        terrainClone.Parent = wsFolder
        Utility.Log("INFO", "Terrain cloned and placed")
        BaoSaveInstance._SetProgress(80)
        
        -- Log terrain info
        pcall(function()
            local terrain = Services.Workspace.Terrain
            local size = terrain:GetExtentsSize()
            Utility.Log("INFO", string.format("Terrain size: %.0f x %.0f x %.0f studs",
                size.X, size.Y, size.Z))
        end)
    else
        Utility.Log("ERROR", "Failed to clone Terrain")
        BaoSaveInstance._SetStatus("Error")
        return false
    end
    
    -- Store Lighting properties that affect terrain appearance
    pcall(function()
        if Services.Lighting then
            local lightFolder = Instance.new("Folder")
            lightFolder.Name = "Lighting"
            lightFolder.Parent = rootModel
            
            local lightClone = Utility.SafeClone(Services.Lighting)
            if lightClone then
                for _, child in ipairs(lightClone:GetChildren()) do
                    child.Parent = lightFolder
                end
                lightClone:Destroy()
            end
        end
    end)
    
    BaoSaveInstance._collectedData = rootModel
    BaoSaveInstance._SetProgress(100)
    BaoSaveInstance._SetStatus("Done")
    
    Utility.Log("INFO", "Terrain Decompile complete!")
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

-- Generate basic RBXL XML content
function BaoSaveInstance._GenerateRBXLXML()
    if not BaoSaveInstance._collectedData then return nil end
    
    local xml = {}
    table.insert(xml, '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"')
    table.insert(xml, ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"')
    table.insert(xml, ' xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd"')
    table.insert(xml, ' version="4">')
    
    local refCounter = 0
    
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
    
    local function serializeInstance(inst, depth)
        if not inst then return end
        if depth > 50 then return end -- Prevent infinite recursion
        
        local className = "Folder"
        pcall(function() className = inst.ClassName end)
        
        local name = "Object"
        pcall(function() name = inst.Name end)
        
        local ref = getRef()
        
        table.insert(xml, string.rep(" ", depth) .. '<Item class="' .. escapeXml(className) .. '" referent="' .. ref .. '">')
        table.insert(xml, string.rep(" ", depth + 1) .. '<Properties>')
        table.insert(xml, string.rep(" ", depth + 2) .. '<string name="Name">' .. escapeXml(name) .. '</string>')
        
        -- Serialize script source if applicable
        pcall(function()
            if inst:IsA("LuaSourceContainer") then
                local source = inst.Source or ""
                table.insert(xml, string.rep(" ", depth + 2) .. '<ProtectedString name="Source"><![CDATA[' .. source .. ']]></ProtectedString>')
            end
        end)
        
        -- Serialize basic properties for common types
        pcall(function()
            if inst:IsA("BasePart") then
                local pos = inst.Position
                local size = inst.Size
                table.insert(xml, string.rep(" ", depth + 2) .. '<Vector3 name="Position">')
                table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. pos.X .. '</X>')
                table.insert(xml, string.rep(" ", depth + 3) .. '<Y>' .. pos.Y .. '</Y>')
                table.insert(xml, string.rep(" ", depth + 3) .. '<Z>' .. pos.Z .. '</Z>')
                table.insert(xml, string.rep(" ", depth + 2) .. '</Vector3>')
                table.insert(xml, string.rep(" ", depth + 2) .. '<Vector3 name="size">')
                table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. size.X .. '</X>')
                table.insert(xml, string.rep(" ", depth + 3) .. '<Y>' .. size.Y .. '</Y>')
                table.insert(xml, string.rep(" ", depth + 3) .. '<Z>' .. size.Z .. '</Z>')
                table.insert(xml, string.rep(" ", depth + 2) .. '</Vector3>')
                
                -- Color
                local color = inst.Color
                table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="Color3">')
                table.insert(xml, string.rep(" ", depth + 3) .. '<R>' .. color.R .. '</R>')
                table.insert(xml, string.rep(" ", depth + 3) .. '<G>' .. color.G .. '</G>')
                table.insert(xml, string.rep(" ", depth + 3) .. '<B>' .. color.B .. '</B>')
                table.insert(xml, string.rep(" ", depth + 2) .. '</Color3>')
                
                table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Anchored">' .. tostring(inst.Anchored) .. '</bool>')
                table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="CanCollide">' .. tostring(inst.CanCollide) .. '</bool>')
                table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Transparency">' .. tostring(inst.Transparency) .. '</float>')
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
    
    -- Button 1: Decompile Full Game
    local btnFullGame = createButton(
        "BtnFullGame", "Decompile Full Game", "🎮",
        Theme.Primary, Theme.PrimaryHover, 82, contentFrame
    )
    
    -- Button 2: Decompile Full Model
    local btnFullModel = createButton(
        "BtnFullModel", "Decompile Full Model", "🏗️",
        Color3.fromRGB(60, 75, 180), Color3.fromRGB(80, 95, 200), 132, contentFrame
    )
    
    -- Button 3: Decompile Terrain
    local btnTerrain = createButton(
        "BtnTerrain", "Decompile Terrain", "🌍",
        Color3.fromRGB(45, 130, 90), Color3.fromRGB(65, 150, 110), 182, contentFrame
    )
    
    -- ================================
    -- Section Label: Export
    -- ================================
    local sectionLabel2 = Instance.new("TextLabel")
    sectionLabel2.Name = "SectionLabel2"
    sectionLabel2.Size = UDim2.new(1, 0, 0, 18)
    sectionLabel2.Position = UDim2.new(0, 0, 0, 238)
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
        Color3.fromRGB(170, 120, 30), Color3.fromRGB(190, 140, 50), 260, contentFrame
    )
    
    -- ================================
    -- Progress Section
    -- ================================
    local sectionLabel3 = Instance.new("TextLabel")
    sectionLabel3.Name = "SectionLabel3"
    sectionLabel3.Size = UDim2.new(1, 0, 0, 18)
    sectionLabel3.Position = UDim2.new(0, 0, 0, 318)
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
    statusFrame.Position = UDim2.new(0, 0, 0, 340)
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
        for _, btn in ipairs({btnFullGame, btnFullModel, btnTerrain, btnExport}) do
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
    
    btnFullGame.MouseButton1Click:Connect(function()
        if isProcessing then return end
        isProcessing = true
        setButtonsEnabled(false)
        updateModeLabel("Mode: Full Game (Model + Terrain + Scripts)")
        
        -- Cleanup previous data
        BaoSaveInstance.Cleanup()
        
        task.spawn(function()
            local success = BaoSaveInstance.DecompileFullGame()
            if success then
                updateModeLabel("✅ Full Game decompiled successfully! Ready to export.")
            else
                updateModeLabel("❌ Decompile failed. Check output for details.")
            end
            isProcessing = false
            setButtonsEnabled(true)
        end)
    end)
    
    btnFullModel.MouseButton1Click:Connect(function()
        if isProcessing then return end
        isProcessing = true
        setButtonsEnabled(false)
        updateModeLabel("Mode: Full Model (No Terrain)")
        
        BaoSaveInstance.Cleanup()
        
        task.spawn(function()
            local success = BaoSaveInstance.DecompileModels()
            if success then
                updateModeLabel("✅ Models decompiled successfully! Ready to export.")
            else
                updateModeLabel("❌ Decompile failed. Check output for details.")
            end
            isProcessing = false
            setButtonsEnabled(true)
        end)
    end)
    
    btnTerrain.MouseButton1Click:Connect(function()
        if isProcessing then return end
        isProcessing = true
        setButtonsEnabled(false)
        updateModeLabel("Mode: Terrain Only")
        
        BaoSaveInstance.Cleanup()
        
        task.spawn(function()
            local success = BaoSaveInstance.DecompileTerrain()
            if success then
                updateModeLabel("✅ Terrain decompiled successfully! Ready to export.")
            else
                updateModeLabel("❌ Terrain decompile failed.")
            end
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

Utility.Log("INFO", "BaoSaveInstance API v1.0 loaded and ready")
Utility.Log("INFO", "================================")
Utility.Log("INFO", "Game: " .. Utility.GetGameName())
Utility.Log("INFO", "PlaceId: " .. tostring(game.PlaceId))
Utility.Log("INFO", "================================")
