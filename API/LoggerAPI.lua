--[[
    BaoSaveInstance API Framework
    File: API/LoggerAPI.lua
    Description: Logging System
]]

local LoggerAPI = {}

--// ═══════════════════════════════════════════════════════════════════════════
--// LOG LEVELS
--// ═══════════════════════════════════════════════════════════════════════════

LoggerAPI.Levels = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    FATAL = 5,
}

local LevelNames = {
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARN",
    [4] = "ERROR",
    [5] = "FATAL",
}

local LevelColors = {
    [1] = Color3.fromRGB(150, 150, 150),
    [2] = Color3.fromRGB(100, 200, 255),
    [3] = Color3.fromRGB(255, 200, 100),
    [4] = Color3.fromRGB(255, 100, 100),
    [5] = Color3.fromRGB(255, 50, 50),
}

--// ═══════════════════════════════════════════════════════════════════════════
--// INTERNAL STATE
--// ═══════════════════════════════════════════════════════════════════════════

local Logs = {}
local Config = {
    MinLevel = LoggerAPI.Levels.INFO,
    MaxLogs = 1000,
    PrintToConsole = true,
    SaveToFile = false,
    FilePath = "BaoSaveInstance/logs.txt",
    IncludeTimestamp = true,
    IncludeSource = false,
}

local Listeners = {}

--// ═══════════════════════════════════════════════════════════════════════════
--// CONFIGURATION
--// ═══════════════════════════════════════════════════════════════════════════

function LoggerAPI.SetConfig(newConfig)
    for key, value in pairs(newConfig) do
        if Config[key] ~= nil then
            Config[key] = value
        end
    end
end

function LoggerAPI.GetConfig()
    local copy = {}
    for k, v in pairs(Config) do
        copy[k] = v
    end
    return copy
end

function LoggerAPI.SetLevel(level)
    if type(level) == "string" then
        level = LoggerAPI.Levels[level:upper()] or LoggerAPI.Levels.INFO
    end
    Config.MinLevel = level
end

--// ═══════════════════════════════════════════════════════════════════════════
--// CORE LOGGING
--// ═══════════════════════════════════════════════════════════════════════════

function LoggerAPI.Log(level, message, data, source)
    -- Convert string level to number
    if type(level) == "string" then
        level = LoggerAPI.Levels[level:upper()] or LoggerAPI.Levels.INFO
    end
    
    -- Check minimum level
    if level < Config.MinLevel then
        return
    end
    
    -- Create log entry
    local entry = {
        Time = os.time(),
        TimeFormatted = os.date("%Y-%m-%d %H:%M:%S"),
        Level = level,
        LevelName = LevelNames[level] or "UNKNOWN",
        Message = tostring(message),
        Data = data,
        Source = source or "Unknown",
    }
    
    -- Add to logs
    table.insert(Logs, entry)
    
    -- Trim logs if too many
    while #Logs > Config.MaxLogs do
        table.remove(Logs, 1)
    end
    
    -- Print to console
    if Config.PrintToConsole then
        local prefix = string.format("[BaoAPI:%s]", entry.LevelName)
        
        if Config.IncludeTimestamp then
            prefix = string.format("[%s] %s", entry.TimeFormatted, prefix)
        end
        
        if Config.IncludeSource and source then
            prefix = prefix .. " [" .. source .. "]"
        end
        
        local fullMessage = prefix .. " " .. entry.Message
        
        if level >= LoggerAPI.Levels.ERROR then
            warn(fullMessage)
        else
            print(fullMessage)
        end
    end
    
    -- Save to file
    if Config.SaveToFile and appendfile then
        pcall(function()
            local line = string.format("[%s] [%s] %s\n", 
                entry.TimeFormatted, entry.LevelName, entry.Message)
            appendfile(Config.FilePath, line)
        end)
    end
    
    -- Notify listeners
    for _, listener in ipairs(Listeners) do
        pcall(listener, entry)
    end
    
    return entry
end

--// ═══════════════════════════════════════════════════════════════════════════
--// CONVENIENCE METHODS
--// ═══════════════════════════════════════════════════════════════════════════

function LoggerAPI.Debug(message, data, source)
    return LoggerAPI.Log(LoggerAPI.Levels.DEBUG, message, data, source)
end

function LoggerAPI.Info(message, data, source)
    return LoggerAPI.Log(LoggerAPI.Levels.INFO, message, data, source)
end

function LoggerAPI.Warn(message, data, source)
    return LoggerAPI.Log(LoggerAPI.Levels.WARN, message, data, source)
end

function LoggerAPI.Error(message, data, source)
    return LoggerAPI.Log(LoggerAPI.Levels.ERROR, message, data, source)
end

function LoggerAPI.Fatal(message, data, source)
    return LoggerAPI.Log(LoggerAPI.Levels.FATAL, message, data, source)
end

--// ═══════════════════════════════════════════════════════════════════════════
--// LOG RETRIEVAL
--// ═══════════════════════════════════════════════════════════════════════════

-- Get all logs
function LoggerAPI.GetAll()
    local copy = {}
    for _, entry in ipairs(Logs) do
        table.insert(copy, entry)
    end
    return copy
end

-- Get logs by level
function LoggerAPI.GetByLevel(level, limit)
    if type(level) == "string" then
        level = LoggerAPI.Levels[level:upper()]
    end
    
    limit = limit or 100
    local result = {}
    
    for i = #Logs, 1, -1 do
        local entry = Logs[i]
        if entry.Level == level then
            table.insert(result, entry)
            if #result >= limit then
                break
            end
        end
    end
    
    return result
end

-- Get recent logs
function LoggerAPI.GetRecent(count)
    count = count or 50
    local result = {}
    
    local start = math.max(1, #Logs - count + 1)
    for i = start, #Logs do
        table.insert(result, Logs[i])
    end
    
    return result
end

-- Get logs since time
function LoggerAPI.GetSince(timestamp)
    local result = {}
    
    for _, entry in ipairs(Logs) do
        if entry.Time >= timestamp then
            table.insert(result, entry)
        end
    end
    
    return result
end

-- Search logs
function LoggerAPI.Search(query, limit)
    limit = limit or 100
    local result = {}
    query = query:lower()
    
    for i = #Logs, 1, -1 do
        local entry = Logs[i]
        if entry.Message:lower():find(query) then
            table.insert(result, entry)
            if #result >= limit then
                break
            end
        end
    end
    
    return result
end

-- Get log count
function LoggerAPI.Count(level)
    if level then
        if type(level) == "string" then
            level = LoggerAPI.Levels[level:upper()]
        end
        
        local count = 0
        for _, entry in ipairs(Logs) do
            if entry.Level == level then
                count = count + 1
            end
        end
        return count
    end
    
    return #Logs
end

--// ═══════════════════════════════════════════════════════════════════════════
--// LOG MANAGEMENT
--// ═══════════════════════════════════════════════════════════════════════════

-- Clear all logs
function LoggerAPI.Clear()
    Logs = {}
end

-- Clear logs by level
function LoggerAPI.ClearByLevel(level)
    if type(level) == "string" then
        level = LoggerAPI.Levels[level:upper()]
    end
    
    local newLogs = {}
    for _, entry in ipairs(Logs) do
        if entry.Level ~= level then
            table.insert(newLogs, entry)
        end
    end
    
    Logs = newLogs
end

--// ═══════════════════════════════════════════════════════════════════════════
--// EXPORT
--// ═══════════════════════════════════════════════════════════════════════════

-- Export to string
function LoggerAPI.Export(format)
    format = format or "text"
    
    if format == "json" then
        local HttpService = game:GetService("HttpService")
        return HttpService:JSONEncode(Logs)
    else
        local lines = {}
        for _, entry in ipairs(Logs) do
            local line = string.format("[%s] [%s] %s", 
                entry.TimeFormatted, entry.LevelName, entry.Message)
            table.insert(lines, line)
        end
        return table.concat(lines, "\n")
    end
end

-- Save to file
function LoggerAPI.SaveToFile(filePath)
    filePath = filePath or Config.FilePath
    
    if not writefile then
        return false, "writefile not available"
    end
    
    local content = LoggerAPI.Export("text")
    local success, err = pcall(writefile, filePath, content)
    
    return success, err
end

--// ═══════════════════════════════════════════════════════════════════════════
--// LISTENERS
--// ═══════════════════════════════════════════════════════════════════════════

-- Add listener
function LoggerAPI.OnLog(callback)
    if type(callback) ~= "function" then
        return nil
    end
    
    local id = tostring(os.time()) .. "_" .. math.random(10000, 99999)
    table.insert(Listeners, {
        ID = id,
        Callback = callback,
    })
    
    return id
end

-- Remove listener
function LoggerAPI.RemoveListener(id)
    for i, listener in ipairs(Listeners) do
        if listener.ID == id then
            table.remove(Listeners, i)
            return true
        end
    end
    return false
end

--// ═══════════════════════════════════════════════════════════════════════════
--// UTILITIES
--// ═══════════════════════════════════════════════════════════════════════════

-- Create scoped logger
function LoggerAPI.CreateScope(scopeName)
    return {
        Debug = function(msg, data) return LoggerAPI.Debug(msg, data, scopeName) end,
        Info = function(msg, data) return LoggerAPI.Info(msg, data, scopeName) end,
        Warn = function(msg, data) return LoggerAPI.Warn(msg, data, scopeName) end,
        Error = function(msg, data) return LoggerAPI.Error(msg, data, scopeName) end,
        Fatal = function(msg, data) return LoggerAPI.Fatal(msg, data, scopeName) end,
    }
end

-- Performance timer
function LoggerAPI.Time(label)
    local startTime = os.clock()
    
    return function()
        local elapsed = os.clock() - startTime
        LoggerAPI.Debug(string.format("%s: %.4f seconds", label, elapsed))
        return elapsed
    end
end

-- Assert with logging
function LoggerAPI.Assert(condition, message, level)
    if not condition then
        level = level or LoggerAPI.Levels.ERROR
        LoggerAPI.Log(level, message or "Assertion failed")
    end
    return condition
end

return LoggerAPI