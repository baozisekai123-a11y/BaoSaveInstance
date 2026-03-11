--[[
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
    ██╗███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗ ██████╗███████╗
    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║██╔════╝██╔════╝
    ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║██║     █████╗  
    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║██║     ██╔══╝  
    ██║██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║╚██████╗███████╗
    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝
    
    BaoSaveInstance v2.0 - Advanced Roblox Game Decompiler
    Stronger, more complete, and more flexible than Synapse saveinstance
    
    Features:
    - 4 Decompile modes: Full Game / Map / Terrain / Scripts
    - Multi-API decompile with intelligent fallback
    - Full property preservation
    - Progress tracking with detailed logging
    - Configurable output options
    - GUI interface with console log
]]

-- ============================================================================
-- SECTION 1: CONFIGURATION
-- ============================================================================

local BaoSaveConfig = {
    PreferredAPI = "AUTO",          -- "AUTO", "API1", "API2", "API3", "API4"
    EnableFallback = true,          -- Allow trying other APIs if preferred fails
    SaveScriptsToFolder = true,     -- Also export scripts to separate folder
    AddTimestampToFileName = false, -- Add timestamp to output filename
    VerboseLogging = true,          -- Print detailed logs
    ScriptFolderName = "BaoSaveInstance_Scripts", -- Folder name for exported scripts
    MaxDecompileAttempts = 3,       -- Max retry attempts per script
    DecompileTimeout = 10,          -- Timeout per script in seconds
    IncludeEmptyScripts = false,    -- Include scripts that failed to decompile
    PreserveHierarchy = true,       -- Preserve folder hierarchy in script export
    ExportFormat = "rbxl",          -- "rbxl" or "rbxlx"
    
    -- Service inclusion toggles
    Services = {
        Workspace = true,
        Lighting = true,
        ReplicatedFirst = true,
        ReplicatedStorage = true,
        ServerScriptService = true,
        ServerStorage = true,
        StarterGui = true,
        StarterPack = true,
        StarterPlayer = true,
        SoundService = true,
        Chat = true,
        LocalizationService = true,
        TestService = true,
        Teams = true,
    },
    
    -- Terrain options
    Terrain = {
        IncludeWater = true,
        IncludeAll = true,
        ChunkSize = 1024,
    },
}

-- ============================================================================
-- SECTION 2: ENVIRONMENT DETECTION & API AVAILABILITY
-- ============================================================================

local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance
BaoSaveInstance.Version = "2.0.0"
BaoSaveInstance.Config = BaoSaveConfig

-- Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Exploit environment detection
local ExploitEnv = {
    Name = "Unknown",
    HasSaveInstance = false,
    HasDecompile = false,
    HasGetHiddenProperty = false,
    HasGetInstances = false,
    HasGetNilInstances = false,
    HasReadFile = false,
    HasWriteFile = false,
    HasMakeFolder = false,
    HasIsFile = false,
    HasSetClipboard = false,
    HasGetGC = false,
    HasGetLoadedModules = false,
    HasFireSignal = false,
}

-- Detect exploit capabilities
local function DetectEnvironment()
    -- Detect exploit name
    if identifyexecutor then
        ExploitEnv.Name = identifyexecutor()
    elseif getexecutorname then
        ExploitEnv.Name = getexecutorname()
    elseif KRNL_LOADED then
        ExploitEnv.Name = "Krnl"
    elseif syn then
        ExploitEnv.Name = "Synapse X"
    elseif fluxus then
        ExploitEnv.Name = "Fluxus"
    elseif SENTINEL_V2 then
        ExploitEnv.Name = "Sentinel"
    end

    -- Check capabilities
    ExploitEnv.HasSaveInstance = (saveinstance ~= nil) or (syn and syn.saveinstance ~= nil)
    ExploitEnv.HasDecompile = (decompile ~= nil) or (syn and syn.decompile ~= nil)
    ExploitEnv.HasGetHiddenProperty = (gethiddenproperty ~= nil)
    ExploitEnv.HasGetInstances = (getinstances ~= nil) or (get_gc_objects ~= nil)
    ExploitEnv.HasGetNilInstances = (getnilinstances ~= nil)
    ExploitEnv.HasReadFile = (readfile ~= nil)
    ExploitEnv.HasWriteFile = (writefile ~= nil)
    ExploitEnv.HasMakeFolder = (makefolder ~= nil) or (isfolder ~= nil)
    ExploitEnv.HasIsFile = (isfile ~= nil)
    ExploitEnv.HasSetClipboard = (setclipboard ~= nil) or (toclipboard ~= nil)
    ExploitEnv.HasGetGC = (getgc ~= nil)
    ExploitEnv.HasGetLoadedModules = (getloadedmodules ~= nil)
    ExploitEnv.HasFireSignal = (firesignal ~= nil)

    return ExploitEnv
end

DetectEnvironment()

-- ============================================================================
-- SECTION 3: UTILITY FUNCTIONS
-- ============================================================================

local Utilities = {}

function Utilities.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if success then
        return true, result
    else
        return false, tostring(result)
    end
end

function Utilities.SanitizeFileName(name)
    if not name or name == "" then
        return "UnknownGame"
    end
    -- Remove invalid filename characters
    local sanitized = name:gsub('[/\\:*?"<>|%c]', '_')
    -- Remove leading/trailing spaces and dots
    sanitized = sanitized:gsub('^[%s%.]+', ''):gsub('[%s%.]+$', '')
    -- Limit length
    if #sanitized > 200 then
        sanitized = sanitized:sub(1, 200)
    end
    if sanitized == "" then
        sanitized = "UnknownGame"
    end
    return sanitized
end

function Utilities.GetGameName()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and info and info.Name then
        return Utilities.SanitizeFileName(info.Name)
    end
    -- Fallback
    return "Game_" .. tostring(game.PlaceId)
end

function Utilities.GetTimestamp()
    local now = os.date("*t")
    return string.format("%04d-%02d-%02d %02d-%02d-%02d",
        now.year, now.month, now.day, now.hour, now.min, now.sec)
end

function Utilities.GenerateFileName(mode)
    local gameName = Utilities.GetGameName()
    local modeStr = ""
    if mode == "game" then
        modeStr = ""
    elseif mode == "map" then
        modeStr = " [Map]"
    elseif mode == "terrain" then
        modeStr = " [Terrain]"
    elseif mode == "scripts" then
        modeStr = " [Scripts]"
    end

    local timestamp = ""
    if BaoSaveConfig.AddTimestampToFileName then
        timestamp = " [" .. Utilities.GetTimestamp() .. "]"
    end

    local ext = "." .. BaoSaveConfig.ExportFormat
    local baseName = gameName .. modeStr .. " Decompile By BaoSaveInstance" .. timestamp

    -- Check for existing files and add suffix
    if ExploitEnv.HasIsFile then
        local finalName = baseName .. ext
        local counter = 1
        while isfile(finalName) do
            finalName = baseName .. " (" .. counter .. ")" .. ext
            counter = counter + 1
            if counter > 100 then break end
        end
        return finalName
    end

    return baseName .. ext
end

function Utilities.MakeFolderSafe(path)
    if ExploitEnv.HasMakeFolder then
        local checkFolder = isfolder or function() return false end
        if not checkFolder(path) then
            local success, err = pcall(function()
                makefolder(path)
            end)
            return success
        end
        return true
    end
    return false
end

function Utilities.WriteFileSafe(path, content)
    if ExploitEnv.HasWriteFile then
        local success, err = pcall(function()
            writefile(path, content)
        end)
        return success, err
    end
    return false, "writefile not available"
end

function Utilities.TableCount(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function Utilities.DeepCloneTable(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = Utilities.DeepCloneTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- ============================================================================
-- SECTION 4: LOGGING SYSTEM
-- ============================================================================

local Logger = {
    Logs = {},
    LogFrame = nil,     -- UI reference
    Callbacks = {},
}

function Logger:AddCallback(callback)
    table.insert(self.Callbacks, callback)
end

function Logger:Log(level, message)
    local timestamp = os.date("%H:%M:%S")
    local prefix = ""
    local color = Color3.fromRGB(255, 255, 255)

    if level == "INFO" then
        prefix = "[INFO]"
        color = Color3.fromRGB(200, 200, 255)
    elseif level == "SUCCESS" then
        prefix = "[SUCCESS]"
        color = Color3.fromRGB(100, 255, 100)
    elseif level == "WARN" then
        prefix = "[WARN]"
        color = Color3.fromRGB(255, 200, 50)
    elseif level == "ERROR" then
        prefix = "[ERROR]"
        color = Color3.fromRGB(255, 80, 80)
    elseif level == "PROGRESS" then
        prefix = "[PROGRESS]"
        color = Color3.fromRGB(100, 200, 255)
    elseif level == "DEBUG" then
        if not BaoSaveConfig.VerboseLogging then return end
        prefix = "[DEBUG]"
        color = Color3.fromRGB(180, 180, 180)
    end

    local fullMessage = string.format("[%s] %s %s", timestamp, prefix, message)
    table.insert(self.Logs, {
        Level = level,
        Message = fullMessage,
        Color = color,
        Time = timestamp,
    })

    -- Print to console
    if level ~= "DEBUG" or BaoSaveConfig.VerboseLogging then
        print(fullMessage)
    end

    -- Notify UI callbacks
    for _, cb in ipairs(self.Callbacks) do
        pcall(cb, fullMessage, color)
    end
end

function Logger:Info(msg) self:Log("INFO", msg) end
function Logger:Success(msg) self:Log("SUCCESS", msg) end
function Logger:Warn(msg) self:Log("WARN", msg) end
function Logger:Error(msg) self:Log("ERROR", msg) end
function Logger:Progress(msg) self:Log("PROGRESS", msg) end
function Logger:Debug(msg) self:Log("DEBUG", msg) end

-- ============================================================================
-- SECTION 5: DECOMPILER ENGINE - MULTI-API SUPPORT
-- ============================================================================

local DecompilerEngine = {
    Stats = {
        TotalScripts = 0,
        DecompiledSuccess = 0,
        DecompiledPartial = 0,
        DecompiledFailed = 0,
        APIUsage = {},
    },
    DecompiledCache = {},   -- Cache decompiled results
}

-- Define multiple decompile APIs
local Decompilers = {}

-- API1: Native decompile() function (most exploits)
Decompilers.API1 = {
    Name = "Native Decompile",
    Priority = 1,
    Available = false,
    Decompile = function(scriptInstance)
        if decompile then
            local success, source = pcall(decompile, scriptInstance)
            if success and source then
                return source
            end
        end
        return nil
    end,
}

-- API2: Synapse-specific decompile
Decompilers.API2 = {
    Name = "Synapse Decompile",
    Priority = 2,
    Available = false,
    Decompile = function(scriptInstance)
        if syn and syn.decompile then
            local success, source = pcall(syn.decompile, scriptInstance)
            if success and source then
                return source
            end
        end
        return nil
    end,
}

-- API3: getscriptbytecode + custom decompile
Decompilers.API3 = {
    Name = "Bytecode Decompile",
    Priority = 3,
    Available = false,
    Decompile = function(scriptInstance)
        if getscriptbytecode then
            local success, bytecode = pcall(getscriptbytecode, scriptInstance)
            if success and bytecode then
                -- Try to decompile from bytecode if available
                if decompile then
                    local s2, source = pcall(decompile, scriptInstance)
                    if s2 and source then
                        return source
                    end
                end
                -- Return bytecode as hex comment if no decompiler
                return "-- Bytecode available but no decompiler found\n-- Bytecode length: " .. #bytecode .. " bytes\n-- Script: " .. scriptInstance:GetFullName()
            end
        end
        return nil
    end,
}

-- API4: Script.Source direct access (works in some cases)
Decompilers.API4 = {
    Name = "Direct Source Access",
    Priority = 4,
    Available = false,
    Decompile = function(scriptInstance)
        -- Try direct Source property
        local success, source = pcall(function()
            return scriptInstance.Source
        end)
        if success and source and source ~= "" then
            return source
        end

        -- Try gethiddenproperty
        if gethiddenproperty then
            local s2, src = pcall(gethiddenproperty, scriptInstance, "Source")
            if s2 and src and src ~= "" then
                return src
            end
        end

        return nil
    end,
}

-- API5: getscripts / getloadedmodules approach
Decompilers.API5 = {
    Name = "Loaded Module Source",
    Priority = 5,
    Available = false,
    Decompile = function(scriptInstance)
        if scriptInstance:IsA("ModuleScript") then
            -- Try to require and tostring
            local success, result = pcall(function()
                if require then
                    local mod = require(scriptInstance)
                    if type(mod) == "table" then
                        return "-- Module returns a table with " .. Utilities.TableCount(mod) .. " entries\n-- Auto-reconstructed by BaoSaveInstance\nreturn " .. HttpService:JSONEncode(mod)
                    elseif type(mod) == "function" then
                        return "-- Module returns a function\n-- Could not fully decompile\nreturn function() end"
                    else
                        return "-- Module returns: " .. tostring(mod) .. "\nreturn " .. tostring(mod)
                    end
                end
            end)
            if success and result then
                return result
            end
        end
        return nil
    end,
}

-- Check which APIs are available
function DecompilerEngine:DetectAvailableAPIs()
    Decompilers.API1.Available = (decompile ~= nil)
    Decompilers.API2.Available = (syn ~= nil and syn.decompile ~= nil)
    Decompilers.API3.Available = (getscriptbytecode ~= nil)
    Decompilers.API4.Available = true -- Always available as fallback attempt
    Decompilers.API5.Available = (require ~= nil)

    local available = {}
    for name, api in pairs(Decompilers) do
        if api.Available then
            table.insert(available, name .. " (" .. api.Name .. ")")
        end
    end

    Logger:Info("Available Decompile APIs: " .. table.concat(available, ", "))
    return available
end

-- Evaluate decompile quality
function DecompilerEngine:EvaluateQuality(source)
    if not source or source == "" then
        return 0
    end

    local score = 0
    local length = #source

    -- Length-based scoring
    if length > 10 then score = score + 10 end
    if length > 100 then score = score + 20 end
    if length > 500 then score = score + 20 end
    if length > 1000 then score = score + 10 end

    -- Check for error indicators (lower score)
    local errorPatterns = {
        "failed to decompile",
        "decompilation error",
        "error decompiling",
        "-- Decompiled with errors",
        "-- Undecompilable",
        "-- Script hash:",
        "bytecode",
    }
    for _, pattern in ipairs(errorPatterns) do
        if source:lower():find(pattern:lower()) then
            score = score - 30
        end
    end

    -- Check for valid Lua constructs (higher score)
    local validPatterns = {
        "local%s+%w+",          -- local variable declaration
        "function%s*%(",        -- function definition
        "if%s+.+%s+then",      -- if statement
        "for%s+.+%s+do",       -- for loop
        "while%s+.+%s+do",     -- while loop
        "return%s+",           -- return statement
        "end",                 -- end keyword
        "%w+%s*=%s*",          -- assignment
        "game:GetService",     -- service access
        "require%(",           -- require call
    }
    for _, pattern in ipairs(validPatterns) do
        if source:find(pattern) then
            score = score + 5
        end
    end

    -- Check for only comments
    local strippedComments = source:gsub("%-%-[^\n]*", ""):gsub("%s+", "")
    if #strippedComments < 5 then
        score = math.max(score - 40, 0)
    end

    return math.max(score, 0)
end

-- Main decompile function with multi-API fallback and merge
function DecompilerEngine:DecompileScript(scriptInstance)
    if not scriptInstance then
        return nil, "nil instance"
    end

    -- Check cache
    local fullName = scriptInstance:GetFullName()
    if self.DecompiledCache[fullName] then
        return self.DecompiledCache[fullName], "cached"
    end

    local bestSource = nil
    local bestScore = -1
    local bestAPI = "none"
    local allResults = {}

    -- Determine API order
    local apiOrder = {}

    if BaoSaveConfig.PreferredAPI ~= "AUTO" and Decompilers[BaoSaveConfig.PreferredAPI] then
        table.insert(apiOrder, BaoSaveConfig.PreferredAPI)
    end

    -- Sort remaining by priority
    local sortedAPIs = {}
    for name, api in pairs(Decompilers) do
        if api.Available and name ~= BaoSaveConfig.PreferredAPI then
            table.insert(sortedAPIs, {name = name, priority = api.Priority})
        end
    end
    table.sort(sortedAPIs, function(a, b) return a.priority < b.priority end)

    for _, entry in ipairs(sortedAPIs) do
        table.insert(apiOrder, entry.name)
    end

    -- Try each API
    for _, apiName in ipairs(apiOrder) do
        local api = Decompilers[apiName]
        if api and api.Available then
            Logger:Debug("Trying " .. api.Name .. " for: " .. fullName)

            local success, source = pcall(function()
                return api.Decompile(scriptInstance)
            end)

            if success and source and source ~= "" then
                local score = self:EvaluateQuality(source)
                allResults[apiName] = {source = source, score = score}

                Logger:Debug(string.format("  %s returned score %d (length %d)", api.Name, score, #source))

                if score > bestScore then
                    bestScore = score
                    bestSource = source
                    bestAPI = apiName
                end

                -- If we got a perfect score and fallback is disabled, stop
                if score >= 80 and not BaoSaveConfig.EnableFallback then
                    break
                end

                -- If score is very good, no need to try more
                if score >= 90 then
                    break
                end
            end

            if not BaoSaveConfig.EnableFallback and apiName == BaoSaveConfig.PreferredAPI then
                break
            end
        end
    end

    -- Attempt to merge results if multiple APIs returned partial results
    if Utilities.TableCount(allResults) > 1 and bestScore < 70 then
        Logger:Debug("Attempting to merge results for: " .. fullName)
        local merged = self:MergeDecompileResults(allResults, scriptInstance)
        if merged then
            local mergedScore = self:EvaluateQuality(merged)
            if mergedScore > bestScore then
                bestSource = merged
                bestScore = mergedScore
                bestAPI = "merged"
            end
        end
    end

    -- Add header comment
    if bestSource then
        local header = string.format(
            "-- Decompiled by BaoSaveInstance v%s\n-- API: %s | Quality Score: %d\n-- Script: %s\n-- Time: %s\n\n",
            BaoSaveInstance.Version,
            bestAPI,
            bestScore,
            fullName,
            os.date("%Y-%m-%d %H:%M:%S")
        )
        bestSource = header .. bestSource

        -- Update stats
        if bestScore >= 50 then
            self.Stats.DecompiledSuccess = self.Stats.DecompiledSuccess + 1
        elseif bestScore > 0 then
            self.Stats.DecompiledPartial = self.Stats.DecompiledPartial + 1
        end

        self.Stats.APIUsage[bestAPI] = (self.Stats.APIUsage[bestAPI] or 0) + 1
    else
        self.Stats.DecompiledFailed = self.Stats.DecompiledFailed + 1
        bestSource = string.format(
            "-- BaoSaveInstance v%s: Failed to decompile\n-- Script: %s\n-- All %d APIs attempted, none returned valid source\n-- This script may be server-side only or protected\n",
            BaoSaveInstance.Version,
            fullName,
            #apiOrder
        )
    end

    -- Cache result
    self.DecompiledCache[fullName] = bestSource

    return bestSource, bestAPI
end

-- Merge decompile results from multiple APIs
function DecompilerEngine:MergeDecompileResults(results, scriptInstance)
    -- Strategy: Take the longest valid result and supplement with others
    local sorted = {}
    for apiName, data in pairs(results) do
        table.insert(sorted, {name = apiName, source = data.source, score = data.score})
    end
    table.sort(sorted, function(a, b) return a.score > b.score end)

    if #sorted == 0 then return nil end

    -- If top result is significantly better, just use it
    if sorted[1].score >= 60 then
        return sorted[1].source
    end

    -- Otherwise, try to combine: use the best one and add missing parts from others
    local primary = sorted[1].source
    local merged = primary

    -- Add comments showing what other APIs found
    merged = merged .. "\n\n--[[\n-- Additional decompile data from other APIs:\n"
    for i = 2, #sorted do
        if sorted[i].score > 0 then
            local lines = 0
            for _ in sorted[i].source:gmatch("[^\n]+") do
                lines = lines + 1
            end
            merged = merged .. string.format("-- %s (score: %d, lines: %d)\n",
                sorted[i].name, sorted[i].score, lines)
        end
    end
    merged = merged .. "]]--\n"

    return merged
end

-- Reset stats
function DecompilerEngine:ResetStats()
    self.Stats = {
        TotalScripts = 0,
        DecompiledSuccess = 0,
        DecompiledPartial = 0,
        DecompiledFailed = 0,
        APIUsage = {},
    }
    self.DecompiledCache = {}
end

-- ============================================================================
-- SECTION 6: INSTANCE SCANNER & COLLECTOR
-- ============================================================================

local Scanner = {}

function Scanner:GetAllServices()
    local services = {}
    local serviceNames = {
        "Workspace", "Lighting", "ReplicatedFirst", "ReplicatedStorage",
        "ServerScriptService", "ServerStorage", "StarterGui", "StarterPack",
        "StarterPlayer", "SoundService", "Chat", "LocalizationService",
        "TestService", "Teams"
    }

    for _, name in ipairs(serviceNames) do
        if BaoSaveConfig.Services[name] then
            local success, service = pcall(function()
                return game:GetService(name)
            end)
            if success and service then
                services[name] = service
            else
                Logger:Debug("Could not access service: " .. name)
            end
        end
    end

    return services
end

function Scanner:GetAllScripts()
    local scripts = {}
    local scriptClasses = {"LocalScript", "Script", "ModuleScript"}

    local services = self:GetAllServices()

    for serviceName, service in pairs(services) do
        local success, descendants = pcall(function()
            return service:GetDescendants()
        end)

        if success and descendants then
            for _, instance in ipairs(descendants) do
                for _, className in ipairs(scriptClasses) do
                    if instance:IsA(className) then
                        table.insert(scripts, instance)
                        break
                    end
                end
            end
        end
    end

    -- Also check nil instances
    if getnilinstances then
        local success, nilInstances = pcall(getnilinstances)
        if success and nilInstances then
            for _, instance in ipairs(nilInstances) do
                for _, className in ipairs(scriptClasses) do
                    if instance:IsA(className) then
                        table.insert(scripts, instance)
                        break
                    end
                end
            end
        end
    end

    -- Also check loaded modules
    if getloadedmodules then
        local success, modules = pcall(getloadedmodules)
        if success and modules then
            local existing = {}
            for _, s in ipairs(scripts) do
                existing[s] = true
            end
            for _, mod in ipairs(modules) do
                if not existing[mod] then
                    table.insert(scripts, mod)
                end
            end
        end
    end

    -- Remove duplicates
    local seen = {}
    local unique = {}
    for _, script in ipairs(scripts) do
        local fullName = script:GetFullName()
        if not seen[fullName] then
            seen[fullName] = true
            table.insert(unique, script)
        end
    end

    Logger:Info(string.format("Found %d unique scripts across all services", #unique))
    return unique
end

function Scanner:GetMapInstances()
    local instances = {}

    -- Primary: Workspace
    local success, descendants = pcall(function()
        return game:GetService("Workspace"):GetDescendants()
    end)

    if success and descendants then
        for _, inst in ipairs(descendants) do
            -- Skip terrain (handled separately) and camera
            if not inst:IsA("Terrain") and not inst:IsA("Camera") then
                table.insert(instances, inst)
            end
        end
    end

    -- Additional services that may contain map-related content
    local additionalServices = {"Lighting", "ReplicatedStorage", "SoundService"}
    for _, serviceName in ipairs(additionalServices) do
        if BaoSaveConfig.Services[serviceName] then
            local s, service = pcall(function()
                return game:GetService(serviceName)
            end)
            if s and service then
                local s2, desc = pcall(function()
                    return service:GetDescendants()
                end)
                if s2 and desc then
                    for _, inst in ipairs(desc) do
                        -- Include visual/audio elements
                        if inst:IsA("BasePart") or inst:IsA("Model") or inst:IsA("Folder") or
                           inst:IsA("Decal") or inst:IsA("Texture") or inst:IsA("Sound") or
                           inst:IsA("ParticleEmitter") or inst:IsA("Light") or
                           inst:IsA("Beam") or inst:IsA("Trail") then
                            table.insert(instances, inst)
                        end
                    end
                end
            end
        end
    end

    Logger:Info(string.format("Found %d map instances", #instances))
    return instances
end

function Scanner:GetTerrain()
    local terrain = nil
    local success, t = pcall(function()
        return game:GetService("Workspace").Terrain
    end)
    if success and t then
        terrain = t
        Logger:Info("Terrain found and accessible")
    else
        Logger:Warn("Could not access Workspace.Terrain")
    end
    return terrain
end

function Scanner:ClassifyInstances()
    local classification = {
        Scripts = {LocalScript = {}, Script = {}, ModuleScript = {}},
        Parts = {},
        Models = {},
        GUIs = {},
        Sounds = {},
        Effects = {},
        Lights = {},
        Other = {},
        Total = 0,
    }

    local services = self:GetAllServices()
    for _, service in pairs(services) do
        local success, descendants = pcall(function()
            return service:GetDescendants()
        end)
        if success and descendants then
            for _, inst in ipairs(descendants) do
                classification.Total = classification.Total + 1

                if inst:IsA("LocalScript") then
                    table.insert(classification.Scripts.LocalScript, inst)
                elseif inst:IsA("Script") and not inst:IsA("LocalScript") then
                    table.insert(classification.Scripts.Script, inst)
                elseif inst:IsA("ModuleScript") then
                    table.insert(classification.Scripts.ModuleScript, inst)
                elseif inst:IsA("BasePart") then
                    table.insert(classification.Parts, inst)
                elseif inst:IsA("Model") then
                    table.insert(classification.Models, inst)
                elseif inst:IsA("GuiObject") or inst:IsA("ScreenGui") or inst:IsA("BillboardGui") then
                    table.insert(classification.GUIs, inst)
                elseif inst:IsA("Sound") then
                    table.insert(classification.Sounds, inst)
                elseif inst:IsA("ParticleEmitter") or inst:IsA("Beam") or inst:IsA("Trail") or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") then
                    table.insert(classification.Effects, inst)
                elseif inst:IsA("Light") then
                    table.insert(classification.Lights, inst)
                else
                    table.insert(classification.Other, inst)
                end
            end
        end
    end

    return classification
end

-- ============================================================================
-- SECTION 7: SAVE INSTANCE ENGINE
-- ============================================================================

local SaveEngine = {}

-- Build save instance options for different modes
function SaveEngine:BuildOptions(mode, customOptions)
    local options = {
        -- Common options
        RewriteFilePath = true,
        NilInstances = true,
        RemovePlayerCharacters = true,
        SavePlayers = false,
        IsolateStarterPlayer = false,
        IgnoreDefaultProperties = true,
        SharedStringOverride = false,
        
        -- Script handling
        Decompile = false,          -- We handle decompiling ourselves
        DecompileTimeout = BaoSaveConfig.DecompileTimeout,
        DecompileIgnore = {},
        
        -- What to save
        ExtraInstances = {},
        IgnoreList = {},
        IgnoreProperties = {},
    }

    if mode == "game" then
        -- Full game: include everything
        options.NilInstances = true
        options.Decompile = true
        options.DecompileTimeout = BaoSaveConfig.DecompileTimeout
        
        -- Add all accessible services
        local services = Scanner:GetAllServices()
        for name, service in pairs(services) do
            if name ~= "Workspace" then -- Workspace is included by default
                table.insert(options.ExtraInstances, service)
            end
        end

    elseif mode == "map" then
        -- Map only: focus on visual content
        options.Decompile = false
        options.NilInstances = false
        options.IgnoreList = {"PlayerGui", "PlayerScripts", "Backpack"}
        
    elseif mode == "terrain" then
        -- Terrain only
        options.Decompile = false
        options.NilInstances = false
        options.ExtraInstances = {game:GetService("Workspace").Terrain}
        
    elseif mode == "scripts" then
        -- Scripts only: decompile everything
        options.Decompile = true
        options.NilInstances = true
        options.DecompileTimeout = BaoSaveConfig.DecompileTimeout
    end

    -- Apply custom overrides
    if customOptions then
        for k, v in pairs(customOptions) do
            options[k] = v
        end
    end

    return options
end

-- Custom save instance that handles all modes
function SaveEngine:Save(mode, fileName)
    local startTime = tick()
    Logger:Info("═══════════════════════════════════════════════════════")
    Logger:Info("BaoSaveInstance v" .. BaoSaveInstance.Version .. " - Starting " .. mode:upper() .. " mode")
    Logger:Info("═══════════════════════════════════════════════════════")
    Logger:Info("Exploit: " .. ExploitEnv.Name)
    Logger:Info("Game: " .. Utilities.GetGameName() .. " (PlaceId: " .. tostring(game.PlaceId) .. ")")

    if not fileName then
        fileName = Utilities.GenerateFileName(mode)
    end

    Logger:Info("Output: " .. fileName)

    -- Phase 1: Pre-scan
    Logger:Progress("Phase 1/4: Scanning game content...")
    local classification = Scanner:ClassifyInstances()
    Logger:Info(string.format("Scan complete: %d total instances", classification.Total))
    Logger:Info(string.format("  Scripts: %d LocalScripts, %d Scripts, %d ModuleScripts",
        #classification.Scripts.LocalScript,
        #classification.Scripts.Script,
        #classification.Scripts.ModuleScript))
    Logger:Info(string.format("  Parts: %d | Models: %d | GUIs: %d | Sounds: %d",
        #classification.Parts, #classification.Models, #classification.GUIs, #classification.Sounds))

    -- Phase 2: Decompile scripts (if needed)
    if mode == "game" or mode == "scripts" then
        Logger:Progress("Phase 2/4: Decompiling scripts...")
        DecompilerEngine:DetectAvailableAPIs()
        DecompilerEngine:ResetStats()

        local allScripts = Scanner:GetAllScripts()
        DecompilerEngine.Stats.TotalScripts = #allScripts

        for i, scriptInst in ipairs(allScripts) do
            if i % 10 == 0 or i == #allScripts then
                Logger:Progress(string.format("Decompiling script %d/%d (%d%%): %s",
                    i, #allScripts, math.floor(i / #allScripts * 100),
                    scriptInst:GetFullName()))
            end

            local source, apiUsed = DecompilerEngine:DecompileScript(scriptInst)

            -- Apply decompiled source back to the instance
            if source then
                pcall(function()
                    scriptInst.Source = source
                end)

                -- Also save to file if configured
                if BaoSaveConfig.SaveScriptsToFolder then
                    self:SaveScriptToFile(scriptInst, source)
                end
            end

            -- Yield periodically to prevent freezing
            if i % 5 == 0 then
                task.wait()
            end
        end

        -- Log decompile stats
        Logger:Info("═══ Decompile Statistics ═══")
        Logger:Info(string.format("  Total: %d | Success: %d | Partial: %d | Failed: %d",
            DecompilerEngine.Stats.TotalScripts,
            DecompilerEngine.Stats.DecompiledSuccess,
            DecompilerEngine.Stats.DecompiledPartial,
            DecompilerEngine.Stats.DecompiledFailed))

        local successRate = 0
        if DecompilerEngine.Stats.TotalScripts > 0 then
            successRate = math.floor(
                (DecompilerEngine.Stats.DecompiledSuccess + DecompilerEngine.Stats.DecompiledPartial) /
                DecompilerEngine.Stats.TotalScripts * 100
            )
        end
        Logger:Info(string.format("  Success rate: %d%%", successRate))

        Logger:Info("  API Usage:")
        for api, count in pairs(DecompilerEngine.Stats.APIUsage) do
            Logger:Info(string.format("    %s: %d scripts", api, count))
        end
    else
        Logger:Progress("Phase 2/4: Script decompilation skipped for this mode")
    end

    -- Phase 3: Prepare terrain (if needed)
    if mode == "game" or mode == "terrain" then
        Logger:Progress("Phase 3/4: Processing terrain data...")
        local terrain = Scanner:GetTerrain()
        if terrain then
            Logger:Info("Terrain data will be included in save")
        else
            Logger:Warn("No terrain data found")
        end
    else
        Logger:Progress("Phase 3/4: Terrain processing skipped for this mode")
    end

    -- Phase 4: Save instance
    Logger:Progress("Phase 4/4: Saving instance to file...")

    local saveSuccess = false
    local saveError = nil

    -- Method 1: Use native saveinstance with our options
    if ExploitEnv.HasSaveInstance then
        local options = self:BuildOptions(mode)

        -- Try syn.saveinstance first (Synapse)
        if syn and syn.saveinstance then
            Logger:Info("Using Synapse saveinstance...")
            local success, err = pcall(function()
                syn.saveinstance(game, fileName, options)
            end)
            if success then
                saveSuccess = true
                Logger:Success("Saved with Synapse saveinstance")
            else
                Logger:Warn("Synapse saveinstance failed: " .. tostring(err))
            end
        end

        -- Try generic saveinstance
        if not saveSuccess and saveinstance then
            Logger:Info("Using generic saveinstance...")
            
            -- Build the options table according to the mode
            local saveOptions = {}
            
            if mode == "game" then
                saveOptions = {
                    FileName = fileName,
                    Decompile = true,
                    DecompileTimeout = BaoSaveConfig.DecompileTimeout,
                    NilInstances = true,
                    RemovePlayerCharacters = true,
                    ExtraInstances = {},
                }
                
                -- Add extra services
                local servicesToAdd = {
                    "Lighting", "ReplicatedFirst", "ReplicatedStorage",
                    "StarterGui", "StarterPack", "StarterPlayer",
                    "SoundService", "Chat", "Teams",
                    "ServerScriptService", "ServerStorage"
                }
                for _, sName in ipairs(servicesToAdd) do
                    if BaoSaveConfig.Services[sName] then
                        pcall(function()
                            local s = game:GetService(sName)
                            if s then
                                table.insert(saveOptions.ExtraInstances, s)
                            end
                        end)
                    end
                end

            elseif mode == "map" then
                saveOptions = {
                    FileName = fileName,
                    Decompile = false,
                    NilInstances = false,
                    RemovePlayerCharacters = true,
                }

            elseif mode == "terrain" then
                saveOptions = {
                    FileName = fileName,
                    Decompile = false,
                    NilInstances = false,
                    RemovePlayerCharacters = true,
                    ExtraInstances = {},
                }
                pcall(function()
                    table.insert(saveOptions.ExtraInstances, game:GetService("Workspace").Terrain)
                end)

            elseif mode == "scripts" then
                saveOptions = {
                    FileName = fileName,
                    Decompile = true,
                    DecompileTimeout = BaoSaveConfig.DecompileTimeout,
                    NilInstances = true,
                    RemovePlayerCharacters = true,
                    ExtraInstances = {},
                }
                local servicesToAdd = {
                    "ReplicatedFirst", "ReplicatedStorage",
                    "StarterGui", "StarterPack", "StarterPlayer",
                    "ServerScriptService", "ServerStorage"
                }
                for _, sName in ipairs(servicesToAdd) do
                    if BaoSaveConfig.Services[sName] then
                        pcall(function()
                            local s = game:GetService(sName)
                            if s then
                                table.insert(saveOptions.ExtraInstances, s)
                            end
                        end)
                    end
                end
            end

            local success, err = pcall(function()
                saveinstance(saveOptions)
            end)
            
            if success then
                saveSuccess = true
                Logger:Success("Saved with generic saveinstance")
            else
                saveError = tostring(err)
                Logger:Warn("Generic saveinstance failed: " .. saveError)
                
                -- Try alternative calling convention
                local success2, err2 = pcall(function()
                    saveinstance(game, fileName)
                end)
                if success2 then
                    saveSuccess = true
                    Logger:Success("Saved with alternative saveinstance call")
                else
                    Logger:Warn("Alternative saveinstance also failed: " .. tostring(err2))
                end
            end
        end
    end

    -- Method 2: Manual RBXL construction (fallback)
    if not saveSuccess then
        Logger:Warn("No native saveinstance available. Attempting manual save...")
        saveSuccess = self:ManualSave(mode, fileName)
    end

    -- Final report
    local elapsed = tick() - startTime
    Logger:Info("═══════════════════════════════════════════════════════")
    if saveSuccess then
        Logger:Success(string.format("COMPLETED! File saved: %s", fileName))
        Logger:Success(string.format("Time elapsed: %.2f seconds", elapsed))
    else
        Logger:Error("FAILED to save file. Check errors above.")
        Logger:Error(string.format("Time elapsed: %.2f seconds", elapsed))
    end
    Logger:Info("═══════════════════════════════════════════════════════")

    return saveSuccess, fileName
end

-- Save individual script to file
function SaveEngine:SaveScriptToFile(scriptInst, source)
    if not ExploitEnv.HasWriteFile then return end

    local basePath = BaoSaveConfig.ScriptFolderName
    Utilities.MakeFolderSafe(basePath)

    local relativePath = scriptInst:GetFullName():gsub("%.", "/")
    relativePath = relativePath:gsub('[<>:"|?*]', '_')

    -- Create subdirectories
    if BaoSaveConfig.PreserveHierarchy then
        local parts = {}
        for part in relativePath:gmatch("[^/]+") do
            table.insert(parts, part)
        end

        local currentPath = basePath
        for i = 1, #parts - 1 do
            currentPath = currentPath .. "/" .. parts[i]
            Utilities.MakeFolderSafe(currentPath)
        end
    end

    local ext = ".lua"
    if scriptInst:IsA("LocalScript") then
        ext = ".client.lua"
    elseif scriptInst:IsA("Script") and not scriptInst:IsA("LocalScript") then
        ext = ".server.lua"
    elseif scriptInst:IsA("ModuleScript") then
        ext = ".lua"
    end

    local filePath
    if BaoSaveConfig.PreserveHierarchy then
        filePath = basePath .. "/" .. relativePath .. ext
    else
        local safeName = scriptInst.Name:gsub('[<>:"/\\|?*]', '_')
        filePath = basePath .. "/" .. safeName .. ext
    end

    Utilities.WriteFileSafe(filePath, source or "-- Empty script")
end

-- Manual RBXL-like save (basic fallback)
function SaveEngine:ManualSave(mode, fileName)
    Logger:Info("Attempting manual XML serialization...")

    -- This is a simplified manual save - creates a basic representation
    local xml = '<?xml version="1.0" encoding="utf-8"?>\n'
    xml = xml .. '<roblox version="4">\n'
    xml = xml .. '<!-- Saved by BaoSaveInstance v' .. BaoSaveInstance.Version .. ' -->\n'
    xml = xml .. '<!-- Game: ' .. Utilities.GetGameName() .. ' -->\n'
    xml = xml .. '<!-- Mode: ' .. mode .. ' -->\n'
    xml = xml .. '<!-- Date: ' .. os.date("%Y-%m-%d %H:%M:%S") .. ' -->\n\n'

    local function escapeXML(str)
        if not str then return "" end
        str = tostring(str)
        str = str:gsub("&", "&amp;")
        str = str:gsub("<", "&lt;")
        str = str:gsub(">", "&gt;")
        str = str:gsub('"', "&quot;")
        str = str:gsub("'", "&apos;")
        return str
    end

    local instanceCount = 0
    local maxInstances = 50000 -- Safety limit

    local function serializeInstance(instance, indent)
        if instanceCount >= maxInstances then return "" end
        instanceCount = instanceCount + 1

        local indentStr = string.rep("  ", indent or 0)
        local result = ""

        local className = instance.ClassName
        result = result .. indentStr .. '<Item class="' .. escapeXML(className) .. '">\n'
        result = result .. indentStr .. '  <Properties>\n'

        -- Name
        result = result .. indentStr .. '    <string name="Name">' .. escapeXML(instance.Name) .. '</string>\n'

        -- Common properties based on class
        pcall(function()
            if instance:IsA("BasePart") then
                local cf = instance.CFrame
                local size = instance.Size
                result = result .. indentStr .. string.format(
                    '    <CoordinateFrame name="CFrame"><X>%f</X><Y>%f</Y><Z>%f</Z></CoordinateFrame>\n',
                    cf.X, cf.Y, cf.Z)
                result = result .. indentStr .. string.format(
                    '    <Vector3 name="Size"><X>%f</X><Y>%f</Y><Z>%f</Z></Vector3>\n',
                    size.X, size.Y, size.Z)
                result = result .. indentStr .. '    <token name="Material">' .. tostring(instance.Material.Value) .. '</token>\n'
                result = result .. indentStr .. '    <bool name="Anchored">' .. tostring(instance.Anchored) .. '</bool>\n'
                result = result .. indentStr .. '    <bool name="CanCollide">' .. tostring(instance.CanCollide) .. '</bool>\n'
                result = result .. indentStr .. '    <float name="Transparency">' .. tostring(instance.Transparency) .. '</float>\n'
                local color = instance.Color
                result = result .. indentStr .. string.format(
                    '    <Color3 name="Color3"><R>%f</R><G>%f</G><B>%f</B></Color3>\n',
                    color.R, color.G, color.B)
            end

            if instance:IsA("LuaSourceContainer") then
                local source = DecompilerEngine.DecompiledCache[instance:GetFullName()]
                if source then
                    result = result .. indentStr .. '    <ProtectedString name="Source">' .. escapeXML(source) .. '</ProtectedString>\n'
                end
                if instance:IsA("LocalScript") or (instance:IsA("Script") and not instance:IsA("ModuleScript")) then
                    result = result .. indentStr .. '    <bool name="Disabled">' .. tostring(instance.Disabled) .. '</bool>\n'
                end
            end
        end)

        result = result .. indentStr .. '  </Properties>\n'

        -- Children
        local success, children = pcall(function()
            return instance:GetChildren()
        end)
        if success and children then
            for _, child in ipairs(children) do
                if not child:IsA("Terrain") or mode == "game" or mode == "terrain" then
                    result = result .. serializeInstance(child, (indent or 0) + 1)
                end
            end
        end

        result = result .. indentStr .. '</Item>\n'
        return result
    end

    -- Serialize based on mode
    if mode == "game" or mode == "map" then
        local services = Scanner:GetAllServices()
        for name, service in pairs(services) do
            if mode == "game" or (mode == "map" and (name == "Workspace" or name == "Lighting")) then
                Logger:Debug("Serializing service: " .. name)
                xml = xml .. serializeInstance(service, 0)
            end
        end
    elseif mode == "terrain" then
        local terrain = Scanner:GetTerrain()
        if terrain then
            xml = xml .. '<Item class="Workspace">\n'
            xml = xml .. '  <Properties><string name="Name">Workspace</string></Properties>\n'
            xml = xml .. '  <Item class="Terrain">\n'
            xml = xml .. '    <Properties><string name="Name">Terrain</string></Properties>\n'
            xml = xml .. '  </Item>\n'
            xml = xml .. '</Item>\n'
        end
    elseif mode == "scripts" then
        -- Create a container for all scripts
        xml = xml .. '<Item class="Folder">\n'
        xml = xml .. '  <Properties><string name="Name">DecompiledScripts</string></Properties>\n'
        local allScripts = Scanner:GetAllScripts()
        for _, scriptInst in ipairs(allScripts) do
            xml = xml .. serializeInstance(scriptInst, 1)
        end
        xml = xml .. '</Item>\n'
    end

    xml = xml .. '</roblox>\n'

    Logger:Info(string.format("Serialized %d instances to XML (%d bytes)", instanceCount, #xml))

    -- Write file
    local success, err = Utilities.WriteFileSafe(fileName, xml)
    if success then
        Logger:Success("Manual save completed: " .. fileName)
        return true
    else
        Logger:Error("Failed to write file: " .. tostring(err))
        return false
    end
end

-- ============================================================================
-- SECTION 8: GUI INTERFACE
-- ============================================================================

local GUI = {}

function GUI:Create()
    -- Cleanup existing GUI
    pcall(function()
        if CoreGui:FindFirstChild("BaoSaveInstanceGUI") then
            CoreGui:FindFirstChild("BaoSaveInstanceGUI"):Destroy()
        end
    end)

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstanceGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999

    -- Try to parent to CoreGui, fallback to PlayerGui
    local success = pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not success then
        pcall(function()
            screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end)
    end

    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    -- Corner rounding
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = mainFrame

    -- Shadow/border effect
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(80, 120, 255)
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0.3
    mainStroke.Parent = mainFrame

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar

    -- Fix bottom corners of title bar
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 10)
    titleFix.Position = UDim2.new(0, 0, 1, -10)
    titleFix.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🛡️ BaoSaveInstance v" .. BaoSaveInstance.Version
    titleLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -40, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- Minimize button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeButton"
    minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
    minimizeBtn.Position = UDim2.new(1, -80, 0, 5)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    minimizeBtn.Text = "—"
    minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    minimizeBtn.TextSize = 16
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Parent = titleBar

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 8)
    minCorner.Parent = minimizeBtn

    local isMinimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            mainFrame:TweenSize(UDim2.new(0, 500, 0, 45), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.3, true)
            minimizeBtn.Text = "□"
        else
            mainFrame:TweenSize(UDim2.new(0, 500, 0, 600), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.3, true)
            minimizeBtn.Text = "—"
        end
    end)

    -- Content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -20, 1, -55)
    contentFrame.Position = UDim2.new(0, 10, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    -- Info label
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, 0, 0, 25)
    infoLabel.Position = UDim2.new(0, 0, 0, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "🎮 " .. Utilities.GetGameName() .. " | Exploit: " .. ExploitEnv.Name
    infoLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    infoLabel.TextSize = 12
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextTruncate = Enum.TextTruncate.AtEnd
    infoLabel.Parent = contentFrame

    -- Buttons container
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Name = "Buttons"
    buttonsFrame.Size = UDim2.new(1, 0, 0, 200)
    buttonsFrame.Position = UDim2.new(0, 0, 0, 30)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.Parent = contentFrame

    local buttonLayout = Instance.new("UIGridLayout")
    buttonLayout.CellSize = UDim2.new(0.48, 0, 0, 80)
    buttonLayout.CellPadding = UDim2.new(0.04, 0, 0, 10)
    buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    buttonLayout.Parent = buttonsFrame

    -- Create action buttons
    local function CreateActionButton(name, description, emoji, color, layoutOrder, callback)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.BackgroundColor3 = color
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.LayoutOrder = layoutOrder
        btn.AutoButtonColor = true
        btn.Parent = buttonsFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(255, 255, 255)
        btnStroke.Transparency = 0.8
        btnStroke.Thickness = 1
        btnStroke.Parent = btn

        -- Emoji
        local emojiLabel = Instance.new("TextLabel")
        emojiLabel.Size = UDim2.new(1, 0, 0, 30)
        emojiLabel.Position = UDim2.new(0, 0, 0, 8)
        emojiLabel.BackgroundTransparency = 1
        emojiLabel.Text = emoji
        emojiLabel.TextSize = 24
        emojiLabel.Font = Enum.Font.GothamBold
        emojiLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        emojiLabel.Parent = btn

        -- Title
        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -10, 0, 18)
        titleLbl.Position = UDim2.new(0, 5, 0, 38)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = name
        titleLbl.TextSize = 14
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLbl.Parent = btn

        -- Description
        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, -10, 0, 14)
        descLbl.Position = UDim2.new(0, 5, 0, 56)
        descLbl.BackgroundTransparency = 1
        descLbl.Text = description
        descLbl.TextSize = 10
        descLbl.Font = Enum.Font.Gotham
        descLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
        descLbl.TextWrapped = true
        descLbl.Parent = btn

        btn.MouseButton1Click:Connect(function()
            -- Disable all buttons during operation
            for _, child in ipairs(buttonsFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child.Active = false
                    child.BackgroundTransparency = 0.5
                end
            end

            task.spawn(function()
                callback()

                -- Re-enable buttons
                for _, child in ipairs(buttonsFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        child.Active = true
                        child.BackgroundTransparency = 0
                    end
                end
            end)
        end)

        return btn
    end

    CreateActionButton(
        "Decompile Game", "Full game: Scripts + Map + Terrain",
        "🌍", Color3.fromRGB(40, 80, 160), 1,
        function() BaoSaveInstance.DecompileGame() end
    )

    CreateActionButton(
        "Decompile Map", "Map only: Parts, Models, Meshes",
        "🗺️", Color3.fromRGB(40, 130, 80), 2,
        function() BaoSaveInstance.DecompileMap() end
    )

    CreateActionButton(
        "Decompile Terrain", "Terrain only: Voxels, Materials",
        "⛰️", Color3.fromRGB(140, 100, 40), 3,
        function() BaoSaveInstance.DecompileTerrain() end
    )

    CreateActionButton(
        "Decompile Scripts", "All scripts with multi-API decompile",
        "📜", Color3.fromRGB(130, 40, 130), 4,
        function() BaoSaveInstance.DecompileScripts() end
    )

    -- Config section
    local configFrame = Instance.new("Frame")
    configFrame.Name = "ConfigFrame"
    configFrame.Size = UDim2.new(1, 0, 0, 50)
    configFrame.Position = UDim2.new(0, 0, 0, 235)
    configFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    configFrame.BorderSizePixel = 0
    configFrame.Parent = contentFrame

    local configCorner = Instance.new("UICorner")
    configCorner.CornerRadius = UDim.new(0, 8)
    configCorner.Parent = configFrame

    local configTitle = Instance.new("TextLabel")
    configTitle.Size = UDim2.new(1, -10, 0, 20)
    configTitle.Position = UDim2.new(0, 10, 0, 5)
    configTitle.BackgroundTransparency = 1
    configTitle.Text = "⚙️ Quick Config"
    configTitle.TextColor3 = Color3.fromRGB(200, 200, 220)
    configTitle.TextSize = 12
    configTitle.Font = Enum.Font.GothamBold
    configTitle.TextXAlignment = Enum.TextXAlignment.Left
    configTitle.Parent = configFrame

    -- API selector
    local apiLabel = Instance.new("TextLabel")
    apiLabel.Size = UDim2.new(0, 80, 0, 20)
    apiLabel.Position = UDim2.new(0, 10, 0, 27)
    apiLabel.BackgroundTransparency = 1
    apiLabel.Text = "API Mode:"
    apiLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    apiLabel.TextSize = 11
    apiLabel.Font = Enum.Font.Gotham
    apiLabel.TextXAlignment = Enum.TextXAlignment.Left
    apiLabel.Parent = configFrame

    local apiOptions = {"AUTO", "API1", "API2", "API3", "API4", "API5"}
    local currentAPIIndex = 1

    local apiBtn = Instance.new("TextButton")
    apiBtn.Size = UDim2.new(0, 70, 0, 20)
    apiBtn.Position = UDim2.new(0, 90, 0, 27)
    apiBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    apiBtn.Text = BaoSaveConfig.PreferredAPI
    apiBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
    apiBtn.TextSize = 11
    apiBtn.Font = Enum.Font.GothamBold
    apiBtn.BorderSizePixel = 0
    apiBtn.Parent = configFrame

    local apiBtnCorner = Instance.new("UICorner")
    apiBtnCorner.CornerRadius = UDim.new(0, 4)
    apiBtnCorner.Parent = apiBtn

    apiBtn.MouseButton1Click:Connect(function()
        currentAPIIndex = (currentAPIIndex % #apiOptions) + 1
        BaoSaveConfig.PreferredAPI = apiOptions[currentAPIIndex]
        apiBtn.Text = BaoSaveConfig.PreferredAPI
    end)

    -- Timestamp toggle
    local tsLabel = Instance.new("TextLabel")
    tsLabel.Size = UDim2.new(0, 80, 0, 20)
    tsLabel.Position = UDim2.new(0, 180, 0, 27)
    tsLabel.BackgroundTransparency = 1
    tsLabel.Text = "Timestamp:"
    tsLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    tsLabel.TextSize = 11
    tsLabel.Font = Enum.Font.Gotham
    tsLabel.TextXAlignment = Enum.TextXAlignment.Left
    tsLabel.Parent = configFrame

    local tsBtn = Instance.new("TextButton")
    tsBtn.Size = UDim2.new(0, 40, 0, 20)
    tsBtn.Position = UDim2.new(0, 260, 0, 27)
    tsBtn.BackgroundColor3 = BaoSaveConfig.AddTimestampToFileName and Color3.fromRGB(50, 130, 50) or Color3.fromRGB(130, 50, 50)
    tsBtn.Text = BaoSaveConfig.AddTimestampToFileName and "ON" or "OFF"
    tsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tsBtn.TextSize = 11
    tsBtn.Font = Enum.Font.GothamBold
    tsBtn.BorderSizePixel = 0
    tsBtn.Parent = configFrame

    local tsBtnCorner = Instance.new("UICorner")
    tsBtnCorner.CornerRadius = UDim.new(0, 4)
    tsBtnCorner.Parent = tsBtn

    tsBtn.MouseButton1Click:Connect(function()
        BaoSaveConfig.AddTimestampToFileName = not BaoSaveConfig.AddTimestampToFileName
        tsBtn.Text = BaoSaveConfig.AddTimestampToFileName and "ON" or "OFF"
        tsBtn.BackgroundColor3 = BaoSaveConfig.AddTimestampToFileName and Color3.fromRGB(50, 130, 50) or Color3.fromRGB(130, 50, 50)
    end)

    -- Fallback toggle
    local fbLabel = Instance.new("TextLabel")
    fbLabel.Size = UDim2.new(0, 70, 0, 20)
    fbLabel.Position = UDim2.new(0, 320, 0, 27)
    fbLabel.BackgroundTransparency = 1
    fbLabel.Text = "Fallback:"
    fbLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    fbLabel.TextSize = 11
    fbLabel.Font = Enum.Font.Gotham
    fbLabel.TextXAlignment = Enum.TextXAlignment.Left
    fbLabel.Parent = configFrame

    local fbBtn = Instance.new("TextButton")
    fbBtn.Size = UDim2.new(0, 40, 0, 20)
    fbBtn.Position = UDim2.new(0, 390, 0, 27)
    fbBtn.BackgroundColor3 = BaoSaveConfig.EnableFallback and Color3.fromRGB(50, 130, 50) or Color3.fromRGB(130, 50, 50)
    fbBtn.Text = BaoSaveConfig.EnableFallback and "ON" or "OFF"
    fbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fbBtn.TextSize = 11
    fbBtn.Font = Enum.Font.GothamBold
    fbBtn.BorderSizePixel = 0
    fbBtn.Parent = configFrame

    local fbBtnCorner = Instance.new("UICorner")
    fbBtnCorner.CornerRadius = UDim.new(0, 4)
    fbBtnCorner.Parent = fbBtn

    fbBtn.MouseButton1Click:Connect(function()
        BaoSaveConfig.EnableFallback = not BaoSaveConfig.EnableFallback
        fbBtn.Text = BaoSaveConfig.EnableFallback and "ON" or "OFF"
        fbBtn.BackgroundColor3 = BaoSaveConfig.EnableFallback and Color3.fromRGB(50, 130, 50) or Color3.fromRGB(130, 50, 50)
    end)

    -- Progress bar
    local progressFrame = Instance.new("Frame")
    progressFrame.Name = "ProgressFrame"
    progressFrame.Size = UDim2.new(1, 0, 0, 25)
    progressFrame.Position = UDim2.new(0, 0, 0, 290)
    progressFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    progressFrame.BorderSizePixel = 0
    progressFrame.Parent = contentFrame

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 6)
    progressCorner.Parent = progressFrame

    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressFrame

    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(0, 6)
    progressBarCorner.Parent = progressBar

    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "ProgressLabel"
    progressLabel.Size = UDim2.new(1, 0, 1, 0)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = "Ready"
    progressLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    progressLabel.TextSize = 11
    progressLabel.Font = Enum.Font.GothamBold
    progressLabel.ZIndex = 2
    progressLabel.Parent = progressFrame

    -- Console/Log area
    local consoleFrame = Instance.new("Frame")
    consoleFrame.Name = "Console"
    consoleFrame.Size = UDim2.new(1, 0, 0, 220)
    consoleFrame.Position = UDim2.new(0, 0, 0, 320)
    consoleFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
    consoleFrame.BorderSizePixel = 0
    consoleFrame.ClipsDescendants = true
    consoleFrame.Parent = contentFrame

    local consoleCorner = Instance.new("UICorner")
    consoleCorner.CornerRadius = UDim.new(0, 8)
    consoleCorner.Parent = consoleFrame

    local consoleStroke = Instance.new("UIStroke")
    consoleStroke.Color = Color3.fromRGB(40, 40, 60)
    consoleStroke.Thickness = 1
    consoleStroke.Parent = consoleFrame

    -- Console header
    local consoleHeader = Instance.new("TextLabel")
    consoleHeader.Size = UDim2.new(1, 0, 0, 20)
    consoleHeader.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    consoleHeader.BorderSizePixel = 0
    consoleHeader.Text = "  📋 Console Output"
    consoleHeader.TextColor3 = Color3.fromRGB(150, 150, 170)
    consoleHeader.TextSize = 10
    consoleHeader.Font = Enum.Font.GothamBold
    consoleHeader.TextXAlignment = Enum.TextXAlignment.Left
    consoleHeader.Parent = consoleFrame

    -- Scrolling frame for logs
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "LogScroll"
    scrollFrame.Size = UDim2.new(1, -10, 1, -25)
    scrollFrame.Position = UDim2.new(0, 5, 0, 22)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 255)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = consoleFrame

    local logLayout = Instance.new("UIListLayout")
    logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logLayout.Padding = UDim.new(0, 1)
    logLayout.Parent = scrollFrame

    local logCount = 0

    -- Register log callback
    Logger:AddCallback(function(message, color)
        logCount = logCount + 1

        local logLine = Instance.new("TextLabel")
        logLine.Size = UDim2.new(1, 0, 0, 14)
        logLine.BackgroundTransparency = logCount % 2 == 0 and 1 or 0.95
        logLine.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        logLine.Text = message
        logLine.TextColor3 = color
        logLine.TextSize = 9
        logLine.Font = Enum.Font.Code
        logLine.TextXAlignment = Enum.TextXAlignment.Left
        logLine.TextTruncate = Enum.TextTruncate.AtEnd
        logLine.LayoutOrder = logCount
        logLine.Parent = scrollFrame

        -- Auto-scroll to bottom
        task.defer(function()
            scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.AbsoluteCanvasSize.Y)
        end)

        -- Update progress bar text
        if message:find("%[PROGRESS%]") then
            progressLabel.Text = message:match("%[PROGRESS%]%s*(.+)") or message
        end

        -- Limit log lines
        if logCount > 500 then
            local children = scrollFrame:GetChildren()
            for _, child in ipairs(children) do
                if child:IsA("TextLabel") and child.LayoutOrder < logCount - 400 then
                    child:Destroy()
                end
            end
        end
    end)

    -- Footer
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, 0, 0, 15)
    footer.Position = UDim2.new(0, 0, 1, -15)
    footer.BackgroundTransparency = 1
    footer.Text = "BaoSaveInstance v" .. BaoSaveInstance.Version .. " | Press F9 for console output"
    footer.TextColor3 = Color3.fromRGB(80, 80, 100)
    footer.TextSize = 9
    footer.Font = Enum.Font.Gotham
    footer.Parent = contentFrame

    Logger:Info("GUI initialized successfully")
    Logger:Info("Game: " .. Utilities.GetGameName())
    Logger:Info("PlaceId: " .. tostring(game.PlaceId))
    Logger:Info("Exploit: " .. ExploitEnv.Name)
    Logger:Info("Ready. Select a decompile mode to begin.")

    return screenGui
end

-- ============================================================================
-- SECTION 9: PUBLIC API FUNCTIONS
-- ============================================================================

function BaoSaveInstance.DecompileGame()
    Logger:Info("Starting FULL GAME decompile...")
    return SaveEngine:Save("game")
end

function BaoSaveInstance.DecompileMap()
    Logger:Info("Starting MAP decompile...")
    return SaveEngine:Save("map")
end

function BaoSaveInstance.DecompileTerrain()
    Logger:Info("Starting TERRAIN decompile...")
    return SaveEngine:Save("terrain")
end

function BaoSaveInstance.DecompileScripts()
    Logger:Info("Starting SCRIPTS decompile...")
    return SaveEngine:Save("scripts")
end

-- Advanced API with custom options
function BaoSaveInstance.DecompileCustom(options)
    options = options or {}
    local mode = options.Mode or "game"
    local fileName = options.FileName or nil

    -- Apply custom config
    if options.Config then
        for k, v in pairs(options.Config) do
            BaoSaveConfig[k] = v
        end
    end

    return SaveEngine:Save(mode, fileName)
end

-- Get decompiled source of a single script
function BaoSaveInstance.DecompileSingle(scriptInstance)
    DecompilerEngine:DetectAvailableAPIs()
    return DecompilerEngine:DecompileScript(scriptInstance)
end

-- Get stats
function BaoSaveInstance.GetStats()
    return {
        DecompilerStats = DecompilerEngine.Stats,
        ExploitEnvironment = ExploitEnv,
        Config = BaoSaveConfig,
        Version = BaoSaveInstance.Version,
    }
end

-- Update config
function BaoSaveInstance.SetConfig(key, value)
    if BaoSaveConfig[key] ~= nil then
        BaoSaveConfig[key] = value
        Logger:Info(string.format("Config updated: %s = %s", tostring(key), tostring(value)))
        return true
    end
    Logger:Warn("Unknown config key: " .. tostring(key))
    return false
end

-- Show/hide GUI
function BaoSaveInstance.ShowGUI()
    return GUI:Create()
end

function BaoSaveInstance.HideGUI()
    pcall(function()
        if CoreGui:FindFirstChild("BaoSaveInstanceGUI") then
            CoreGui:FindFirstChild("BaoSaveInstanceGUI"):Destroy()
        end
    end)
end

-- ============================================================================
-- SECTION 10: INITIALIZATION & AUTO-START
-- ============================================================================

-- Print banner
print([[
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗   ║
║    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║   ║
║    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║    ║
║    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝   ║
║    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝    ║
║    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝   ║
║              INSTANCE v2.0.0                             ║
║                                                          ║
║    Advanced Roblox Game Decompiler                       ║
║    Stronger than Synapse saveinstance                    ║
║                                                          ║
╠══════════════════════════════════════════════════════════╣
║  Commands:                                               ║
║    BaoSaveInstance.DecompileGame()    - Full game         ║
║    BaoSaveInstance.DecompileMap()     - Map only          ║
║    BaoSaveInstance.DecompileTerrain() - Terrain only      ║
║    BaoSaveInstance.DecompileScripts() - Scripts only      ║
║    BaoSaveInstance.ShowGUI()         - Show GUI           ║
║    BaoSaveInstance.HideGUI()        - Hide GUI           ║
╚══════════════════════════════════════════════════════════╝
]])

-- Detect environment
Logger:Info("Detecting exploit environment...")
DetectEnvironment()
Logger:Info("Exploit: " .. ExploitEnv.Name)
Logger:Info("Save Instance: " .. (ExploitEnv.HasSaveInstance and "✅" or "❌"))
Logger:Info("Decompile: " .. (ExploitEnv.HasDecompile and "✅" or "❌"))
Logger:Info("Write File: " .. (ExploitEnv.HasWriteFile and "✅" or "❌"))
Logger:Info("Get Hidden Property: " .. (ExploitEnv.HasGetHiddenProperty and "✅" or "❌"))

-- Detect available decompile APIs
DecompilerEngine:DetectAvailableAPIs()

-- Auto-show GUI
BaoSaveInstance.ShowGUI()

-- Make globally accessible
getgenv().BaoSaveInstance = BaoSaveInstance
getgenv().BaoSaveConfig = BaoSaveConfig

return BaoSaveInstance
