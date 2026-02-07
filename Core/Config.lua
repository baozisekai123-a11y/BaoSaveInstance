--[[
    BaoSaveInstance API Framework
    File: Core/Config.lua
    Description: Configuration Management
]]

local HttpService = game:GetService("HttpService")

local Config = {}

--// ═══════════════════════════════════════════════════════════════════════════
--// DEFAULT CONFIGURATION
--// ═══════════════════════════════════════════════════════════════════════════

local DefaultConfig = {
    -- Save options
    Save = {
        Mode = "All",
        FileName = "",
        FilePath = "BaoSaveInstance",
        Binary = true,
        Timeout = 60,
        ShowStatus = true,
    },
    
    -- Decompile options
    Decompile = {
        Enabled = true,
        Timeout = 10,
        IgnoreErrors = true,
        Cache = true,
        MaxRetries = 3,
    },
    
    -- Instance options
    Instance = {
        RemovePlayers = true,
        SaveTerrain = true,
        SaveLighting = true,
        SaveCameras = false,
        NilInstances = false,
        IsolatePlayers = true,
        IgnoreList = {},
        IgnoreClasses = {"Player", "PlayerGui", "PlayerScripts"},
    },
    
    -- Script options
    Script = {
        IgnoreDefaultScripts = true,
        SaveBytecode = false,
        MarkProtected = true,
        DecompileModules = true,
        DecompileLocalScripts = true,
        DecompileServerScripts = true,
    },
    
    -- Terrain options
    Terrain = {
        Enabled = true,
        Resolution = 4,
        ChunkSize = 64,
        Compress = true,
        SaveWater = true,
    },
    
    -- Performance options
    Performance = {
        BatchSize = 100,
        YieldInterval = 0.01,
        CacheEnabled = true,
        MaxCacheSize = 1000,
        ParallelProcessing = false,
    },
    
    -- GUI options
    GUI = {
        Enabled = true,
        Theme = "Dark",
        Keybind = Enum.KeyCode.RightShift,
        ShowProgress = true,
        Notifications = true,
        AutoClose = false,
        Position = nil,
    },
    
    -- Debug options
    Debug = {
        Enabled = false,
        LogLevel = "INFO", -- DEBUG, INFO, WARN, ERROR
        SaveLogs = false,
        LogFile = "BaoSaveInstance/logs.txt",
        VerboseMode = false,
    },
    
    -- Plugin options
    Plugins = {
        Enabled = true,
        AutoLoad = true,
        PluginPath = "BaoSaveInstance/Plugins",
    },
}

--// ═══════════════════════════════════════════════════════════════════════════
--// INTERNAL STATE
--// ═══════════════════════════════════════════════════════════════════════════

local CurrentConfig = nil
local ConfigListeners = {}

--// ═══════════════════════════════════════════════════════════════════════════
--// HELPER FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════

local function DeepClone(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[DeepClone(k)] = DeepClone(v)
    end
    return copy
end

local function GetNestedValue(tbl, path)
    local keys = string.split(path, ".")
    local value = tbl
    
    for _, key in ipairs(keys) do
        if type(value) ~= "table" then
            return nil
        end
        value = value[key]
    end
    
    return value
end

local function SetNestedValue(tbl, path, value)
    local keys = string.split(path, ".")
    local current = tbl
    
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    
    current[keys[#keys]] = value
end

local function NotifyListeners(path, newValue, oldValue)
    for _, listener in ipairs(ConfigListeners) do
        if listener.Path == nil or listener.Path == path or path:find("^" .. listener.Path) then
            pcall(listener.Callback, path, newValue, oldValue)
        end
    end
end

--// ═══════════════════════════════════════════════════════════════════════════
--// PUBLIC API
--// ═══════════════════════════════════════════════════════════════════════════

-- Initialize config
function Config.Init()
    CurrentConfig = DeepClone(DefaultConfig)
    return CurrentConfig
end

-- Get config value
function Config.Get(path, default)
    if not CurrentConfig then
        Config.Init()
    end
    
    if not path then
        return DeepClone(CurrentConfig)
    end
    
    local value = GetNestedValue(CurrentConfig, path)
    
    if value ~= nil then
        if type(value) == "table" then
            return DeepClone(value)
        end
        return value
    end
    
    return default
end

-- Set config value
function Config.Set(path, value)
    if not CurrentConfig then
        Config.Init()
    end
    
    local oldValue = Config.Get(path)
    SetNestedValue(CurrentConfig, path, value)
    
    NotifyListeners(path, value, oldValue)
    
    return true
end

-- Set multiple config values
function Config.SetMultiple(configs)
    for path, value in pairs(configs) do
        Config.Set(path, value)
    end
end

-- Reset config to default
function Config.Reset(path)
    if path then
        local defaultValue = GetNestedValue(DefaultConfig, path)
        return Config.Set(path, DeepClone(defaultValue))
    else
        local oldConfig = CurrentConfig
        CurrentConfig = DeepClone(DefaultConfig)
        NotifyListeners(nil, CurrentConfig, oldConfig)
        return true
    end
end

-- Get default value
function Config.GetDefault(path)
    if not path then
        return DeepClone(DefaultConfig)
    end
    
    local value = GetNestedValue(DefaultConfig, path)
    
    if type(value) == "table" then
        return DeepClone(value)
    end
    
    return value
end

-- Check if path exists
function Config.Exists(path)
    return Config.Get(path) ~= nil
end

-- Get all config
function Config.GetAll()
    return Config.Get()
end

-- Merge with existing config
function Config.Merge(newConfig)
    local function merge(base, override)
        for k, v in pairs(override) do
            if type(v) == "table" and type(base[k]) == "table" then
                merge(base[k], v)
            else
                base[k] = v
            end
        end
    end
    
    if not CurrentConfig then
        Config.Init()
    end
    
    merge(CurrentConfig, newConfig)
    NotifyListeners(nil, CurrentConfig, nil)
end

-- Listen for config changes
function Config.OnChange(callback, path)
    local listener = {
        ID = tostring(os.time()) .. "_" .. math.random(10000, 99999),
        Path = path,
        Callback = callback,
    }
    
    table.insert(ConfigListeners, listener)
    
    return listener.ID
end

-- Remove listener
function Config.RemoveListener(listenerID)
    for i, listener in ipairs(ConfigListeners) do
        if listener.ID == listenerID then
            table.remove(ConfigListeners, i)
            return true
        end
    end
    return false
end

-- Export config to JSON
function Config.Export()
    if not CurrentConfig then
        Config.Init()
    end
    
    local success, json = pcall(function()
        return HttpService:JSONEncode(CurrentConfig)
    end)
    
    return success and json or nil
end

-- Import config from JSON
function Config.Import(jsonString)
    local success, config = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    
    if success and type(config) == "table" then
        Config.Merge(config)
        return true
    end
    
    return false
end

-- Save config to file
function Config.Save(filePath)
    filePath = filePath or "BaoSaveInstance/config.json"
    
    if not writefile then
        return false, "writefile not available"
    end
    
    local json = Config.Export()
    if not json then
        return false, "Failed to export config"
    end
    
    local success, err = pcall(writefile, filePath, json)
    return success, err
end

-- Load config from file
function Config.Load(filePath)
    filePath = filePath or "BaoSaveInstance/config.json"
    
    if not readfile then
        return false, "readfile not available"
    end
    
    local success, content = pcall(readfile, filePath)
    if not success then
        return false, "Failed to read file"
    end
    
    return Config.Import(content)
end

-- Validate config value
function Config.Validate(path, value)
    local validators = {
        ["Save.Timeout"] = function(v) return type(v) == "number" and v > 0 end,
        ["Decompile.Timeout"] = function(v) return type(v) == "number" and v > 0 end,
        ["Performance.BatchSize"] = function(v) return type(v) == "number" and v > 0 end,
        ["Terrain.Resolution"] = function(v) return type(v) == "number" and (v == 1 or v == 2 or v == 4) end,
        ["Debug.LogLevel"] = function(v) return v == "DEBUG" or v == "INFO" or v == "WARN" or v == "ERROR" end,
    }
    
    local validator = validators[path]
    if validator then
        return validator(value)
    end
    
    return true
end

-- Initialize on load
Config.Init()

return Config
