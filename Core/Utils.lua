--[[
    BaoSaveInstance API Framework
    File: Core/Utils.lua
    Description: Utility Functions
]]

local Utils = {}

--// ═══════════════════════════════════════════════════════════════════════════
--// ERROR HANDLING
--// ═══════════════════════════════════════════════════════════════════════════

-- Safe pcall wrapper
function Utils.Try(func, ...)
    local args = {...}
    local success, result = pcall(function()
        return func(unpack(args))
    end)
    return success, result
end

-- Safe pcall with default value
function Utils.TryOr(func, default, ...)
    local success, result = Utils.Try(func, ...)
    return success and result or default
end

-- Safe pcall with error handler
function Utils.TryCatch(func, catchFunc, ...)
    local success, result = Utils.Try(func, ...)
    if not success and catchFunc then
        catchFunc(result)
    end
    return success, result
end

--// ═══════════════════════════════════════════════════════════════════════════
--// TYPE CHECKING
--// ═══════════════════════════════════════════════════════════════════════════

function Utils.TypeOf(value)
    return typeof(value)
end

function Utils.IsType(value, typeName)
    return typeof(value) == typeName
end

function Utils.IsInstance(value)
    return typeof(value) == "Instance"
end

function Utils.IsFunction(value)
    return type(value) == "function"
end

function Utils.IsTable(value)
    return type(value) == "table"
end

function Utils.IsString(value)
    return type(value) == "string"
end

function Utils.IsNumber(value)
    return type(value) == "number"
end

function Utils.IsBool(value)
    return type(value) == "boolean"
end

function Utils.IsNil(value)
    return value == nil
end

--// ═══════════════════════════════════════════════════════════════════════════
--// TABLE OPERATIONS
--// ═══════════════════════════════════════════════════════════════════════════

-- Deep clone table
function Utils.DeepClone(tbl)
    if type(tbl) ~= "table" then 
        return tbl 
    end
    
    local copy = {}
    for k, v in pairs(tbl) do
        copy[Utils.DeepClone(k)] = Utils.DeepClone(v)
    end
    
    return setmetatable(copy, getmetatable(tbl))
end

-- Shallow clone table
function Utils.Clone(tbl)
    if type(tbl) ~= "table" then 
        return tbl 
    end
    
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    
    return copy
end

-- Merge tables (deep)
function Utils.Merge(base, override)
    local result = Utils.DeepClone(base or {})
    
    for k, v in pairs(override or {}) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = Utils.Merge(result[k], v)
        else
            result[k] = v
        end
    end
    
    return result
end

-- Merge tables (shallow)
function Utils.MergeShallow(base, override)
    local result = Utils.Clone(base or {})
    
    for k, v in pairs(override or {}) do
        result[k] = v
    end
    
    return result
end

-- Check if table contains value
function Utils.Contains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Check if table contains key
function Utils.HasKey(tbl, key)
    return tbl[key] ~= nil
end

-- Get table keys
function Utils.Keys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

-- Get table values
function Utils.Values(tbl)
    local values = {}
    for _, v in pairs(tbl) do
        table.insert(values, v)
    end
    return values
end

-- Get table length (works for non-array tables)
function Utils.Count(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Filter table
function Utils.Filter(tbl, predicate)
    local result = {}
    for k, v in pairs(tbl) do
        if predicate(v, k) then
            if type(k) == "number" then
                table.insert(result, v)
            else
                result[k] = v
            end
        end
    end
    return result
end

-- Map table
function Utils.Map(tbl, mapper)
    local result = {}
    for k, v in pairs(tbl) do
        result[k] = mapper(v, k)
    end
    return result
end

-- Find in table
function Utils.Find(tbl, predicate)
    for k, v in pairs(tbl) do
        if predicate(v, k) then
            return v, k
        end
    end
    return nil
end

-- Reduce table
function Utils.Reduce(tbl, reducer, initial)
    local result = initial
    for k, v in pairs(tbl) do
        result = reducer(result, v, k)
    end
    return result
end

--// ═══════════════════════════════════════════════════════════════════════════
--// STRING OPERATIONS
--// ═══════════════════════════════════════════════════════════════════════════

-- Generate unique ID
function Utils.GenerateID(prefix)
    prefix = prefix or "id"
    return string.format("%s_%s_%s", prefix, os.time(), math.random(10000, 99999))
end

-- Generate UUID
function Utils.GenerateUUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format("%x", v)
    end)
end

-- Get timestamp
function Utils.GetTimestamp(format)
    format = format or "%Y%m%d_%H%M%S"
    return os.date(format)
end

-- Get formatted date
function Utils.GetDate(format)
    format = format or "%Y-%m-%d %H:%M:%S"
    return os.date(format)
end

-- Sanitize string for file name
function Utils.Sanitize(str, maxLen)
    maxLen = maxLen or 50
    return tostring(str):gsub("[^%w%-_]", "_"):sub(1, maxLen)
end

-- Escape XML special characters
function Utils.EscapeXML(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    
    local replacements = {
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ["&"] = "&amp;",
        ['"'] = "&quot;",
        ["'"] = "&apos;",
    }
    
    for char, replacement in pairs(replacements) do
        str = str:gsub(char, replacement)
    end
    
    -- Remove invalid XML characters
    str = str:gsub("[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "")
    
    return str
end

-- Trim whitespace
function Utils.Trim(str)
    return str:match("^%s*(.-)%s*$")
end

-- Split string
function Utils.Split(str, delimiter)
    delimiter = delimiter or ","
    local result = {}
    
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    
    return result
end

-- Join array to string
function Utils.Join(tbl, delimiter)
    delimiter = delimiter or ","
    return table.concat(tbl, delimiter)
end

-- Pad string
function Utils.PadLeft(str, length, char)
    char = char or " "
    return string.rep(char, length - #str) .. str
end

function Utils.PadRight(str, length, char)
    char = char or " "
    return str .. string.rep(char, length - #str)
end

-- Truncate string
function Utils.Truncate(str, maxLen, suffix)
    suffix = suffix or "..."
    if #str <= maxLen then
        return str
    end
    return str:sub(1, maxLen - #suffix) .. suffix
end

--// ═══════════════════════════════════════════════════════════════════════════
--// ASYNC/TIMING OPERATIONS
--// ═══════════════════════════════════════════════════════════════════════════

-- Wait with timeout
function Utils.WaitFor(condition, timeout, interval)
    timeout = timeout or 10
    interval = interval or 0.1
    local elapsed = 0
    
    while not condition() and elapsed < timeout do
        task.wait(interval)
        elapsed = elapsed + interval
    end
    
    return condition()
end

-- Delay execution
function Utils.Delay(seconds, callback)
    task.delay(seconds, callback)
end

-- Debounce function
function Utils.Debounce(func, delay)
    delay = delay or 0.5
    local lastCall = 0
    
    return function(...)
        local now = os.clock()
        if now - lastCall >= delay then
            lastCall = now
            return func(...)
        end
    end
end

-- Throttle function
function Utils.Throttle(func, delay)
    delay = delay or 0.5
    local isThrottled = false
    
    return function(...)
        if isThrottled then return end
        isThrottled = true
        
        task.delay(delay, function()
            isThrottled = false
        end)
        
        return func(...)
    end
end

-- Batch process with yield
function Utils.BatchProcess(items, batchSize, processor, onProgress)
    batchSize = batchSize or 100
    local results = {}
    local total = #items
    
    for i, item in ipairs(items) do
        local success, result = pcall(processor, item, i)
        if success then
            table.insert(results, result)
        end
        
        if i % batchSize == 0 then
            if onProgress then
                onProgress(i, total, math.floor(i / total * 100))
            end
            task.wait()
        end
    end
    
    return results
end

--// ═══════════════════════════════════════════════════════════════════════════
--// INSTANCE OPERATIONS
--// ═══════════════════════════════════════════════════════════════════════════

-- Check if instance is valid
function Utils.IsValidInstance(instance)
    local success, result = pcall(function()
        return instance and instance.Parent ~= nil
    end)
    return success and result
end

-- Get descendants safely
function Utils.GetDescendantsSafe(instance)
    local success, descendants = pcall(function()
        return instance:GetDescendants()
    end)
    return success and descendants or {}
end

-- Get children safely
function Utils.GetChildrenSafe(instance)
    local success, children = pcall(function()
        return instance:GetChildren()
    end)
    return success and children or {}
end

-- Get property safely
function Utils.GetProperty(instance, propertyName, default)
    local success, value = pcall(function()
        return instance[propertyName]
    end)
    return success and value or default
end

-- Set property safely
function Utils.SetProperty(instance, propertyName, value)
    local success, err = pcall(function()
        instance[propertyName] = value
    end)
    return success, err
end

-- Get full name safely
function Utils.GetFullName(instance)
    local success, fullName = pcall(function()
        return instance:GetFullName()
    end)
    return success and fullName or "Unknown"
end

--// ═══════════════════════════════════════════════════════════════════════════
--// MATH OPERATIONS
--// ═══════════════════════════════════════════════════════════════════════════

-- Clamp value
function Utils.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Lerp
function Utils.Lerp(a, b, t)
    return a + (b - a) * t
end

-- Round to decimal places
function Utils.Round(value, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(value * mult + 0.5) / mult
end

-- Format number with commas
function Utils.FormatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Format bytes
function Utils.FormatBytes(bytes)
    local units = {"B", "KB", "MB", "GB", "TB"}
    local unit = 1
    
    while bytes >= 1024 and unit < #units do
        bytes = bytes / 1024
        unit = unit + 1
    end
    
    return string.format("%.2f %s", bytes, units[unit])
end

-- Format time duration
function Utils.FormatDuration(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, mins, secs)
    else
        return string.format("%02d:%02d", mins, secs)
    end
end

return Utils