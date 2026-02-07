--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              BaoSaveInstance - Logger API                    ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local HttpService = game:GetService("HttpService")

local Logger = {}

--// Log levels
Logger.Levels = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
}

--// Storage
local Logs = {}
local CurrentLevel = Logger.Levels.INFO
local MaxLogs = 1000

--// Set log level
function Logger.SetLevel(level)
    if Logger.Levels[level] then
        CurrentLevel = Logger.Levels[level]
    elseif type(level) == "number" then
        CurrentLevel = level
    end
end

--// Core log function
function Logger.Log(level, message, data)
    local levelNum = Logger.Levels[level] or Logger.Levels.INFO
    
    local entry = {
        Time = os.time(),
        TimeStr = os.date("%Y-%m-%d %H:%M:%S"),
        Level = level,
        LevelNum = levelNum,
        Message = message,
        Data = data,
    }
    
    table.insert(Logs, entry)
    
    -- Limit log size
    while #Logs > MaxLogs do
        table.remove(Logs, 1)
    end
    
    -- Print if level >= current level
    if levelNum >= CurrentLevel then
        local prefix = string.format("[BaoAPI:%s]", level)
        
        if level == "ERROR" then
            warn(prefix, message)
        elseif level == "WARN" then
            warn(prefix, message)
        else
            print(prefix, message)
        end
    end
    
    return entry
end

--// Convenience functions
function Logger.Debug(message, data)
    return Logger.Log("DEBUG", message, data)
end

function Logger.Info(message, data)
    return Logger.Log("INFO", message, data)
end

function Logger.Warn(message, data)
    return Logger.Log("WARN", message, data)
end

function Logger.Error(message, data)
    return Logger.Log("ERROR", message, data)
end

--// Get logs
function Logger.GetLogs(level, limit)
    limit = limit or 100
    local filtered = {}
    
    for i = #Logs, math.max(1, #Logs - limit + 1), -1 do
        local entry = Logs[i]
        if not level or entry.Level == level then
            table.insert(filtered, entry)
        end
    end
    
    return filtered
end

--// Get all logs
function Logger.GetAll()
    return Logs
end

--// Clear logs
function Logger.Clear()
    Logs = {}
end

--// Export logs to JSON
function Logger.Export()
    return HttpService:JSONEncode(Logs)
end

--// Get log count
function Logger.Count(level)
    if not level then
        return #Logs
    end
    
    local count = 0
    for _, entry in ipairs(Logs) do
        if entry.Level == level then
            count = count + 1
        end
    end
    return count
end

--// Set max logs
function Logger.SetMaxLogs(max)
    MaxLogs = max or 1000
end

--// Create child logger with prefix
function Logger.CreateChild(prefix)
    local child = {}
    
    function child.Log(level, message, data)
        return Logger.Log(level, "[" .. prefix .. "] " .. message, data)
    end
    
    function child.Debug(message, data)
        return child.Log("DEBUG", message, data)
    end
    
    function child.Info(message, data)
        return child.Log("INFO", message, data)
    end
    
    function child.Warn(message, data)
        return child.Log("WARN", message, data)
    end
    
    function child.Error(message, data)
        return child.Log("ERROR", message, data)
    end
    
    return child
end

return Logger