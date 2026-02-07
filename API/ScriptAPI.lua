--[[
    BaoSaveInstance API Framework
    File: API/ScriptAPI.lua
    Description: Script Decompilation & Processing
]]

local ScriptAPI = {}

--// ═══════════════════════════════════════════════════════════════════════════
--// CONFIGURATION
--// ═══════════════════════════════════════════════════════════════════════════

ScriptAPI.Config = {
    DefaultTimeout = 10,
    MaxRetries = 3,
    CacheEnabled = true,
    MarkProtected = true,
}

--// ═══════════════════════════════════════════════════════════════════════════
--// MARKERS
--// ═══════════════════════════════════════════════════════════════════════════

ScriptAPI.Markers = {
    Protected = "--[[\n\tSCRIPT PROTECTED/ENCRYPTED\n\tSource not available\n\tSaved by BaoSaveInstance\n]]",
    Failed = "--[[\n\tDECOMPILATION FAILED\n\tCould not retrieve source\n\tSaved by BaoSaveInstance\n]]",
    Timeout = "--[[\n\tDECOMPILATION TIMEOUT\n\tScript took too long to decompile\n\tSaved by BaoSaveInstance\n]]",
    Empty = "--[[\n\tEMPTY SCRIPT\n\tNo source code\n\tSaved by BaoSaveInstance\n]]",
    NotAvailable = "--[[\n\tSOURCE NOT AVAILABLE\n\tClient does not support decompilation\n\tSaved by BaoSaveInstance\n]]",
}

--// ═══════════════════════════════════════════════════════════════════════════
--// INTERNAL STATE
--// ═══════════════════════════════════════════════════════════════════════════

local SourceCache = {}
local Stats = {
    Decompiled = 0,
    Failed = 0,
    Cached = 0,
    Protected = 0,
}

--// ═══════════════════════════════════════════════════════════════════════════
--// CAPABILITY DETECTION
--// ═══════════════════════════════════════════════════════════════════════════

function ScriptAPI.GetCapabilities()
    return {
        Decompile = decompile ~= nil,
        GetScriptSource = getscriptsource ~= nil,
        SynDecompile = syn and syn.decompile ~= nil,
        GetScriptBytecode = getscriptbytecode ~= nil,
        GetScriptHash = getscripthash ~= nil,
    }
end

function ScriptAPI.CanDecompile()
    local caps = ScriptAPI.GetCapabilities()
    return caps.Decompile or caps.SynDecompile or caps.GetScriptSource
end

--// ═══════════════════════════════════════════════════════════════════════════
--// DECOMPILATION
--// ═══════════════════════════════════════════════════════════════════════════

-- Try to get source using all available methods
function ScriptAPI.GetSource(script, options)
    options = options or {}
    local timeout = options.Timeout or ScriptAPI.Config.DefaultTimeout
    
    -- Check cache first
    if ScriptAPI.Config.CacheEnabled and SourceCache[script] then
        Stats.Cached = Stats.Cached + 1
        return SourceCache[script].Source, SourceCache[script].Method, "cached"
    end
    
    local source = nil
    local method = "none"
    local status = "failed"
    
    -- Method 1: Direct Source property
    local success1, result1 = pcall(function()
        return script.Source
    end)
    
    if success1 and result1 and type(result1) == "string" and #result1 > 0 then
        source = result1
        method = "direct"
        status = "success"
        Stats.Decompiled = Stats.Decompiled + 1
    end
    
    -- Method 2: decompile()
    if not source and decompile then
        local success2, result2 = pcall(function()
            return decompile(script)
        end)
        
        if success2 and result2 and type(result2) == "string" and #result2 > 0 then
            source = result2
            method = "decompile"
            status = "success"
            Stats.Decompiled = Stats.Decompiled + 1
        end
    end
    
    -- Method 3: syn.decompile()
    if not source and syn and syn.decompile then
        local success3, result3 = pcall(function()
            return syn.decompile(script)
        end)
        
        if success3 and result3 and type(result3) == "string" and #result3 > 0 then
            source = result3
            method = "syn.decompile"
            status = "success"
            Stats.Decompiled = Stats.Decompiled + 1
        end
    end
    
    -- Method 4: getscriptsource()
    if not source and getscriptsource then
        local success4, result4 = pcall(function()
            return getscriptsource(script)
        end)
        
        if success4 and result4 and type(result4) == "string" and #result4 > 0 then
            source = result4
            method = "getscriptsource"
            status = "success"
            Stats.Decompiled = Stats.Decompiled + 1
        end
    end
    
    -- Handle failure
    if not source then
        Stats.Failed = Stats.Failed + 1
        
        if ScriptAPI.Config.MarkProtected then
            if not ScriptAPI.CanDecompile() then
                source = ScriptAPI.Markers.NotAvailable
                status = "not_available"
            else
                source = ScriptAPI.Markers.Protected
                status = "protected"
                Stats.Protected = Stats.Protected + 1
            end
        else
            source = ""
            status = "empty"
        end
    end
    
    -- Cache result
    if ScriptAPI.Config.CacheEnabled then
        SourceCache[script] = {
            Source = source,
            Method = method,
            Status = status,
            Time = os.time(),
        }
    end
    
    return source, method, status
end

-- Decompile with timeout
function ScriptAPI.DecompileWithTimeout(script, timeout)
    timeout = timeout or ScriptAPI.Config.DefaultTimeout
    
    local result = nil
    local completed = false
    
    task.spawn(function()
        result = ScriptAPI.GetSource(script, {Timeout = timeout})
        completed = true
    end)
    
    local elapsed = 0
    while not completed and elapsed < timeout do
        task.wait(0.1)
        elapsed = elapsed + 0.1
    end
    
    if not completed then
        return ScriptAPI.Markers.Timeout, "timeout", "timeout"
    end
    
    return result
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SCRIPT INFO
--// ═══════════════════════════════════════════════════════════════════════════

-- Get comprehensive script info
function ScriptAPI.GetInfo(script, options)
    options = options or {}
    
    local source, method, status = ScriptAPI.GetSource(script, options)
    
    local info = {
        -- Basic info
        Name = script.Name,
        ClassName = script.ClassName,
        FullName = "",
        
        -- Source info
        Source = source,
        Method = method,
        Status = status,
        
        -- Properties
        Disabled = false,
        
        -- Analysis
        LineCount = 0,
        CharCount = 0,
        IsEmpty = false,
        IsProtected = false,
        HasRemoteLoad = false,
        
        -- Metadata
        DecompiledAt = os.time(),
    }
    
    -- Get full name safely
    pcall(function()
        info.FullName = script:GetFullName()
    end)
    
    -- Get disabled state
    pcall(function()
        info.Disabled = script.Disabled
    end)
    
    -- Analyze source
    if source and #source > 0 then
        info.CharCount = #source
        info.LineCount = select(2, source:gsub("\n", "\n")) + 1
        info.IsEmpty = false
        
        -- Check for remote loading patterns
        local lowerSource = source:lower()
        if lowerSource:find("loadstring") and (lowerSource:find("http") or lowerSource:find("game:httget")) then
            info.HasRemoteLoad = true
        end
        
        -- Check if protected marker
        for markerName, marker in pairs(ScriptAPI.Markers) do
            if source:find(marker:sub(1, 20), 1, true) then
                info.IsProtected = true
                break
            end
        end
    else
        info.IsEmpty = true
    end
    
    return info
end

--// ═══════════════════════════════════════════════════════════════════════════
--// COLLECTION
--// ═══════════════════════════════════════════════════════════════════════════

-- Collect all scripts from root
function ScriptAPI.CollectAll(root, filter)
    root = root or game
    
    local scripts = {}
    
    local success, descendants = pcall(function()
        return root:GetDescendants()
    end)
    
    if not success then
        return scripts
    end
    
    for _, descendant in ipairs(descendants) do
        if descendant:IsA("LuaSourceContainer") then
            local include = true
            
            if filter then
                if type(filter) == "function" then
                    include = filter(descendant)
                elseif type(filter) == "table" then
                    -- Filter by class names
                    include = false
                    for _, className in ipairs(filter) do
                        if descendant:IsA(className) then
                            include = true
                            break
                        end
                    end
                end
            end
            
            if include then
                table.insert(scripts, descendant)
            end
        end
    end
    
    return scripts
end

-- Collect scripts by type
function ScriptAPI.CollectByType(root, scriptType)
    local validTypes = {
        Script = true,
        LocalScript = true,
        ModuleScript = true,
    }
    
    if not validTypes[scriptType] then
        return {}
    end
    
    return ScriptAPI.CollectAll(root, function(script)
        return script.ClassName == scriptType
    end)
end

-- Collect LocalScripts
function ScriptAPI.CollectLocalScripts(root)
    return ScriptAPI.CollectByType(root, "LocalScript")
end

-- Collect ModuleScripts
function ScriptAPI.CollectModuleScripts(root)
    return ScriptAPI.CollectByType(root, "ModuleScript")
end

-- Collect Server Scripts
function ScriptAPI.CollectServerScripts(root)
    return ScriptAPI.CollectByType(root, "Script")
end

--// ═══════════════════════════════════════════════════════════════════════════
--// BATCH PROCESSING
--// ═══════════════════════════════════════════════════════════════════════════

-- Process multiple scripts
function ScriptAPI.ProcessBatch(scripts, options, callbacks)
    options = options or {}
    callbacks = callbacks or {}
    
    local results = {
        Scripts = {},
        Success = 0,
        Failed = 0,
        Protected = 0,
        Total = #scripts,
        StartTime = os.time(),
        EndTime = nil,
    }
    
    for i, script in ipairs(scripts) do
        local info = ScriptAPI.GetInfo(script, options)
        table.insert(results.Scripts, info)
        
        if info.Status == "success" then
            results.Success = results.Success + 1
        elseif info.Status == "protected" then
            results.Protected = results.Protected + 1
        else
            results.Failed = results.Failed + 1
        end
        
        -- Progress callback
        if callbacks.OnProgress then
            callbacks.OnProgress(i, #scripts, info)
        end
        
        -- Script callback
        if callbacks.OnScript then
            callbacks.OnScript(info, i)
        end
        
        -- Yield every 10 scripts
        if i % 10 == 0 then
            task.wait()
        end
    end
    
    results.EndTime = os.time()
    results.Duration = results.EndTime - results.StartTime
    
    -- Complete callback
    if callbacks.OnComplete then
        callbacks.OnComplete(results)
    end
    
    return results
end

--// ═══════════════════════════════════════════════════════════════════════════
--// FORMATTING
--// ═══════════════════════════════════════════════════════════════════════════

-- Format script source with header
function ScriptAPI.FormatSource(scriptInfo)
    local header = string.format([[
--[[
    Script: %s
    ClassName: %s
    Path: %s
    Status: %s
    Method: %s
    Disabled: %s
    Lines: %d
    Protected: %s
    Remote Loading: %s
    Decompiled: %s
    
    Saved by BaoSaveInstance API
--]]

]], 
        scriptInfo.Name,
        scriptInfo.ClassName,
        scriptInfo.FullName,
        scriptInfo.Status,
        scriptInfo.Method,
        tostring(scriptInfo.Disabled),
        scriptInfo.LineCount,
        tostring(scriptInfo.IsProtected),
        tostring(scriptInfo.HasRemoteLoad),
        os.date("%Y-%m-%d %H:%M:%S", scriptInfo.DecompiledAt)
    )
    
    return header .. (scriptInfo.Source or "")
end

-- Format as module
function ScriptAPI.FormatAsModule(scriptInfo)
    if scriptInfo.ClassName ~= "ModuleScript" then
        return ScriptAPI.FormatSource(scriptInfo)
    end
    
    return scriptInfo.Source or ""
end

--// ═══════════════════════════════════════════════════════════════════════════
--// FILTERING
--// ═══════════════════════════════════════════════════════════════════════════

-- Default script filter (ignore player scripts, etc)
function ScriptAPI.DefaultFilter(script)
    local fullName = ""
    pcall(function()
        fullName = script:GetFullName()
    end)
    
    -- Ignore player scripts
    if fullName:find("PlayerScripts") or 
       fullName:find("PlayerGui") or
       fullName:find("Backpack") then
        return false
    end
    
    -- Ignore default Roblox scripts
    local defaultScripts = {
        "Animate", "Health", "Sound", "ChatScript", "BubbleChat",
        "RbxCharacterSounds", "ControlScript", "CameraScript",
    }
    
    for _, name in ipairs(defaultScripts) do
        if script.Name == name then
            return false
        end
    end
    
    return true
end

-- Create custom filter
function ScriptAPI.CreateFilter(options)
    options = options or {}
    
    return function(script)
        -- Ignore list
        if options.IgnoreNames then
            for _, name in ipairs(options.IgnoreNames) do
                if script.Name == name then
                    return false
                end
            end
        end
        
        -- Ignore paths
        if options.IgnorePaths then
            local fullName = ""
            pcall(function()
                fullName = script:GetFullName()
            end)
            
            for _, path in ipairs(options.IgnorePaths) do
                if fullName:find(path) then
                    return false
                end
            end
        end
        
        -- Only include specific classes
        if options.OnlyClasses then
            local found = false
            for _, className in ipairs(options.OnlyClasses) do
                if script.ClassName == className then
                    found = true
                    break
                end
            end
            if not found then
                return false
            end
        end
        
        -- Apply default filter
        if options.UseDefaultFilter ~= false then
            return ScriptAPI.DefaultFilter(script)
        end
        
        return true
    end
end

--// ═══════════════════════════════════════════════════════════════════════════
--// STATS & CACHE
--// ═══════════════════════════════════════════════════════════════════════════

-- Get stats
function ScriptAPI.GetStats()
    return {
        Decompiled = Stats.Decompiled,
        Failed = Stats.Failed,
        Cached = Stats.Cached,
        Protected = Stats.Protected,
        CacheSize = 0,
    }
end

-- Reset stats
function ScriptAPI.ResetStats()
    Stats = {
        Decompiled = 0,
        Failed = 0,
        Cached = 0,
        Protected = 0,
    }
end

-- Clear cache
function ScriptAPI.ClearCache()
    SourceCache = {}
end

-- Get cache info
function ScriptAPI.GetCacheInfo()
    local count = 0
    for _ in pairs(SourceCache) do
        count = count + 1
    end
    return {
        Size = count,
        Enabled = ScriptAPI.Config.CacheEnabled,
    }
end

-- Set config
function ScriptAPI.SetConfig(config)
    for key, value in pairs(config) do
        if ScriptAPI.Config[key] ~= nil then
            ScriptAPI.Config[key] = value
        end
    end
end

return ScriptAPI