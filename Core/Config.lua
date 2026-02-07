--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              BaoSaveInstance - Configuration                 ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local Utils = {} -- Will be injected

local Config = {}

--// Default configuration
local DefaultConfig = {
    -- Save options
    Save = {
        Mode = "All",
        FileName = "",
        FilePath = "BaoSaveInstance",
        Binary = true,
        Timeout = 60,
    },
    
    -- Decompile options
    Decompile = {
        Enabled = true,
        Timeout = 10,
        IgnoreErrors = true,
        Cache = true,
    },
    
    -- Instance options
    Instance = {
        RemovePlayers = true,
        SaveTerrain = true,
        SaveLighting = true,
        IgnoreList = {},
        IgnoreClasses = {"Player"},
    },
    
    -- Script options
    Script = {
        IgnoreDefaultScripts = true,
        SaveBytecode = false,
        MarkProtected = true,
    },
    
    -- Terrain options
    Terrain = {
        Resolution = 4,
        ChunkSize = 64,
        Compress = true,
    },
    
    -- Performance options
    Performance = {
        BatchSize = 100,
        YieldInterval = 0.01,
        CacheEnabled = true,
    },
    
    -- GUI options
    GUI = {
        Enabled = true,
        Theme = "Dark",
        Keybind = Enum.KeyCode.RightShift,
        ShowProgress = true,
    },
    
    -- Debug options
    Debug = {
        Enabled = false,
        LogLevel = "INFO",
        SaveLogs = false,
    },
}

--// Current config storage
local CurrentConfig = {}

--// Initialize
function Config.Init(utils)
    Utils = utils or Utils
    CurrentConfig = Utils.DeepClone and Utils.DeepClone(DefaultConfig) or DefaultConfig
end

--// Get config value by path
function Config.Get(path, default)
    local keys = type(Utils.Split) == "function" and Utils.Split(path, ".") or {path}
    local value = CurrentConfig
    
    for _, key in ipairs(keys) do
        if type(value) ~= "table" then
            return default
        end
        value = value[key]
    end
    
    return value ~= nil and value or default
end

--// Set config value by path
function Config.Set(path, value)
    local keys = type(Utils.Split) == "function" and Utils.Split(path, ".") or {path}
    local current = CurrentConfig
    
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    
    local lastKey = keys[#keys]
    local oldValue = current[lastKey]
    current[lastKey] = value
    
    return true, oldValue
end

--// Reset config
function Config.Reset(path)
    if path then
        local defaultValue = Config.GetDefault(path)
        return Config.Set(path, defaultValue)
    else
        CurrentConfig = Utils.DeepClone and Utils.DeepClone(DefaultConfig) or DefaultConfig
        return true
    end
end

--// Get default value
function Config.GetDefault(path)
    local keys = type(Utils.Split) == "function" and Utils.Split(path, ".") or {path}
    local value = DefaultConfig
    
    for _, key in ipairs(keys) do
        if type(value) ~= "table" then
            return nil
        end
        value = value[key]
    end
    
    return Utils.DeepClone and Utils.DeepClone(value) or value
end

--// Get all config
function Config.GetAll()
    return Utils.DeepClone and Utils.DeepClone(CurrentConfig) or CurrentConfig
end

--// Set multiple configs
function Config.SetMultiple(configs)
    for path, value in pairs(configs) do
        Config.Set(path, value)
    end
end

--// Export config to JSON
function Config.Export()
    local HttpService = game:GetService("HttpService")
    return HttpService:JSONEncode(CurrentConfig)
end

--// Import config from JSON
function Config.Import(jsonString)
    local HttpService = game:GetService("HttpService")
    local success, config = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    
    if success and type(config) == "table" then
        CurrentConfig = Utils.Merge and Utils.Merge(DefaultConfig, config) or config
        return true
    end
    
    return false
end

--// Get default config table
function Config.GetDefaults()
    return Utils.DeepClone and Utils.DeepClone(DefaultConfig) or DefaultConfig
end

-- Auto-initialize with empty utils if needed
Config.Init({
    DeepClone = function(t)
        if type(t) ~= "table" then return t end
        local copy = {}
        for k, v in pairs(t) do
            copy[k] = Config.GetDefaults and type(v) == "table" and Config.Init({}).DeepClone(v) or v
        end
        return copy
    end,
    Split = function(str, delim)
        local result = {}
        for match in (str .. delim):gmatch("(.-)" .. delim) do
            table.insert(result, match)
        end
        return result
    end,
    Merge = function(a, b)
        local result = {}
        for k, v in pairs(a or {}) do result[k] = v end
        for k, v in pairs(b or {}) do result[k] = v end
        return result
    end
})

return Config
