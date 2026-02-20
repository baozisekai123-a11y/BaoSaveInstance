--[[
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
    
    BaoSaveInstance API v2.0 Official
    Advanced Roblox Decompile & Export Tool
    Single-file complete system — Enhanced Edition
]]

-- ============================================================
-- UTILITY FUNCTIONS LAYER
-- ============================================================

local Utility = {}

Utility.Logs = {}
Utility._timers = {}

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

function Utility.TimerStart(name)
    Utility._timers[name] = os.clock()
end

function Utility.TimerEnd(name)
    local startTime = Utility._timers[name]
    if not startTime then return 0 end
    local elapsed = os.clock() - startTime
    Utility._timers[name] = nil
    Utility.Log("PERF", string.format("%s took %.2fs", name, elapsed))
    return elapsed
end

function Utility.FormatBytes(bytes)
    if bytes < 1024 then return bytes .. " B" end
    if bytes < 1048576 then return string.format("%.1f KB", bytes / 1024) end
    return string.format("%.2f MB", bytes / 1048576)
end

function Utility.GetMemoryUsage()
    local mem = 0
    pcall(function() mem = gcinfo() end)
    return mem
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
        return nil
    end
    local success, clone = pcall(function()
        return instance:Clone()
    end)
    if success and clone then
        return clone
    end
    return nil
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
    pcall(function()
        count = #instance:GetDescendants()
    end)
    return count
end

function Utility.IsFilteredService(serviceName)
    local filtered = {
        ["CoreGui"] = true, ["CorePackages"] = true,
        ["RobloxPluginGuiService"] = true, ["Visit"] = true,
        ["PluginGuiService"] = true, ["PluginDebugService"] = true,
        ["TestService"] = true, ["StudioService"] = true,
        ["StudioData"] = true, ["NetworkClient"] = true,
        ["NetworkServer"] = true, ["PluginManager"] = true,
    }
    return filtered[serviceName] == true
end

function Utility.IsRuntimePlayerGui(instance)
    local success, result = pcall(function()
        if instance:IsA("PlayerGui") then return true end
        local current = instance.Parent
        while current do
            if current:IsA("PlayerGui") then return true end
            current = current.Parent
        end
        return false
    end)
    return success and result
end

function Utility.FormatNumber(n)
    if n < 1000 then return tostring(n) end
    if n < 1000000 then return string.format("%.1fK", n / 1000) end
    return string.format("%.2fM", n / 1000000)
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

-- Try to read a property safely (with hidden property executor support)
function Utility.TryGetProperty(instance, propName)
    local success, value = pcall(function()
        return instance[propName]
    end)
    if success then return value end
    if gethiddenproperty then
        local s2, v2 = pcall(function()
            return gethiddenproperty(instance, propName)
        end)
        if s2 then return v2 end
    end
    return nil
end

-- Safely set a property
function Utility.TrySetProperty(instance, propName, value)
    local ok = pcall(function()
        instance[propName] = value
    end)
    if not ok and sethiddenproperty then
        pcall(function()
            sethiddenproperty(instance, propName, value)
        end)
    end
end


-- ============================================================
-- API LOGIC LAYER
-- ============================================================

local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance

BaoSaveInstance.VERSION = "2.0 Official"
BaoSaveInstance._initialized = false
BaoSaveInstance._status = "Idle"
BaoSaveInstance._progress = 0
BaoSaveInstance._collectedData = nil
BaoSaveInstance._decompileCache = {} -- Hash -> Source cache
BaoSaveInstance._mode = nil
BaoSaveInstance._startTime = 0
BaoSaveInstance._cancelled = false
BaoSaveInstance._cancelRequested = false
BaoSaveInstance._operationStartTime = 0
BaoSaveInstance._stats = { 
    Objects = 0, 
    Scripts = 0, 
    ScriptsCached = 0,
    ScriptsFailed = 0, 
    ScriptsBytecodeOnly = 0,
    Errors = 0, 
    NilInstances = 0 
}

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
    WriteSourceToClone = true,
    AdaptiveStreaming = true,
    -- Max Power Decompiler Config
    DecompileTimeout = 6,          -- Seconds before giving up on a specific decompile call
    DecompileMaxRetries = 2,       -- Retries per decompiler function
    SaveBytecodeOnFail = true,     -- Dump bytecode if source recovery fails
    DecompileNilScripts = true,     -- Capture scripts from getnilinstances()
    ObfuscationCheck = true,        -- Analyze source for obfuscation/junk
}

BaoSaveInstance._callbacks = {
    OnStatusChanged = nil,
    OnProgressChanged = nil,
    OnLogAdded = nil,
}

-- Capabilities detected at runtime
BaoSaveInstance._capabilities = {
    ExecutorName = "Unknown",
    HasDecompile = false,
    HasSaveinstance = false,
    HasGetScriptBytecode = false,
    HasGetHiddenProperty = false,
    HasGetNilInstances = false,
    HasGetLoadedModules = false,
    HasWriteFile = false,
    HasGetScriptHash = false,
    HasFireSignal = false,
    IsStudio = false,
}

-- Services references
local Services = {}

function BaoSaveInstance._DetectCapabilities()
    local cap = BaoSaveInstance._capabilities

    -- Detect environment
    pcall(function() cap.IsStudio = game:GetService("RunService"):IsStudio() end)

    -- Detect executor
    local executorChecks = {
        {"Synapse", function() return syn and syn.protect_gui end},
        {"ScriptWare", function() return isscriptware and isscriptware() end},
        {"Fluxus", function() return fluxus and fluxus.decompile end},
        {"Krnl", function() return krnl and krnl.decompile end},
        {"Wave", function() return Wave and Wave.decompile end},
        {"Solara", function() return Solara ~= nil end},
        {"Delta", function() return Delta ~= nil end},
    }
    for _, check in ipairs(executorChecks) do
        local ok, result = pcall(check[2])
        if ok and result then
            cap.ExecutorName = check[1]
            break
        end
    end

    -- Detect functions
    local fnChecks = {
        {"HasDecompile", function() return decompile ~= nil or (getgenv and getgenv().decompile ~= nil) end},
        {"HasSaveinstance", function() return saveinstance ~= nil end},
        {"HasGetScriptBytecode", function() return getscriptbytecode ~= nil end},
        {"HasGetHiddenProperty", function() return gethiddenproperty ~= nil end},
        {"HasGetNilInstances", function() return getnilinstances ~= nil end},
        {"HasGetLoadedModules", function() return getloadedmodules ~= nil end},
        {"HasWriteFile", function() return writefile ~= nil end},
        {"HasGetScriptHash", function() return getscripthash ~= nil end},
        {"HasFireSignal", function() return firesignal ~= nil end},
    }
    for _, check in ipairs(fnChecks) do
        local ok, result = pcall(check[2])
        cap[check[1]] = ok and result == true
    end

    Utility.Log("INFO", string.format("Environment: %s | Studio: %s", cap.ExecutorName, tostring(cap.IsStudio)))
    Utility.Log("INFO", string.format("Caps: Decompile=%s, HiddenProp=%s, NilInst=%s, WriteFile=%s, Bytecode=%s",
        tostring(cap.HasDecompile), tostring(cap.HasGetHiddenProperty),
        tostring(cap.HasGetNilInstances), tostring(cap.HasWriteFile),
        tostring(cap.HasGetScriptBytecode)))
end

function BaoSaveInstance.Init()
    if BaoSaveInstance._initialized then
        Utility.Log("INFO", "BaoSaveInstance already initialized")
        return true
    end
    
    Utility.Log("INFO", "Initializing BaoSaveInstance API " .. BaoSaveInstance.VERSION .. "...")
    Utility.TimerStart("Init")
    
    -- Detect capabilities first
    BaoSaveInstance._DetectCapabilities()
    
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
        end
    end
    
    BaoSaveInstance._initialized = true
    BaoSaveInstance._status = "Idle"
    BaoSaveInstance._progress = 0
    BaoSaveInstance._stats = { Objects = 0, Scripts = 0, ScriptsCached = 0, ScriptsFailed = 0, ScriptsBytecodeOnly = 0, Errors = 0, NilInstances = 0 }
    
    Utility.TimerEnd("Init")
    Utility.Log("INFO", "BaoSaveInstance " .. BaoSaveInstance.VERSION .. " initialized (Mem: " .. Utility.FormatBytes(Utility.GetMemoryUsage() * 1024) .. ")")
    return true
end

function BaoSaveInstance._SetStatus(status)
    BaoSaveInstance._status = status
    -- V2: track elapsed time for operations
    if status == "Processing" or status == "Exporting" then
        BaoSaveInstance._operationStartTime = os.clock()
        BaoSaveInstance._cancelRequested = false
    end
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
-- Helper to get ALL available decompilers in priority order
function BaoSaveInstance._GetAllDecompilers()
    local decompilers = {}
    
    local function add(fn, name)
        if fn and type(fn) == "function" then
            table.insert(decompilers, {func = fn, name = name})
        end
    end
    
    if getgenv then
        local env = getgenv()
        -- Priority 1: Modern/Custom Executors
        add(env.getscriptsource, "getscriptsource")
        add(env.decompile, "decompile")
        
        -- Priority 2: Known Executors (Specific Tables)
        if env.syn then add(env.syn.decompile, "syn.decompile") end
        if env.fluxus then add(env.fluxus.decompile, "fluxus.decompile") end
        if env.krnl then add(env.krnl.decompile, "krnl.decompile") end
        if env.sentinel then add(env.sentinel.decompile, "sentinel.decompile") end
        if env.oxygen then add(env.oxygen.decompile, "oxygen.decompile") end
        if env.electron then add(env.electron.decompile, "electron.decompile") end
        if env.valyse then add(env.valyse.decompile, "valyse.decompile") end
        if env.unitary then add(env.unitary.decompile, "unitary.decompile") end
        
        -- Priority 3: Fallbacks
        if env.secure_decompile then add(env.secure_decompile, "secure_decompile") end
        if env.recover_script then add(env.recover_script, "recover_script") end
    end
    
    -- Global fallback
    if not next(decompilers) then
        add(decompile, "decompile (global)")
        add(getscriptsource, "getscriptsource (global)")
    end
    
    return decompilers
end

-- Timeout-protected Decompile
function BaoSaveInstance._DecompileWithTimeout(decompilerFn, scriptInstance, timeout)
    local result = nil
    local finished = false
    local errorMsg = nil
    
    local thread = coroutine.create(function()
        local ok, res = pcall(decompilerFn, scriptInstance)
        if ok then
            result = res
        else
            errorMsg = res
        end
        finished = true
    end)
    
    coroutine.resume(thread)
    
    local start = os.clock()
    while not finished do
        if os.clock() - start > timeout then
            -- Kill thread if possible (Lua 5.1 coroutines can't be killed externally easily without yield, 
            -- but we stop waiting for it)
            return nil, "Timeout (" .. timeout .. "s)"
        end
        task.wait(0.05)
    end
    
    if errorMsg then return nil, "Error: " .. tostring(errorMsg) end
    if not result or result == "" then return nil, "Empty result" end
    
    return result, nil
end

-- Validate Source Quality & Check Obfuscation
function BaoSaveInstance._ValidateSource(source)
    if not source or #source == 0 then return false, 0, "Empty" end
    if #source < 10 then return false, 0, "Too short" end
    
    -- Check for common decompiler failure messages
    if source:find("stack index") or source:find("decompile failed") or source:find("error while decompiling") then
        return false, 0, "Decompiler error message"
    end
    
    local quality = 100
    local notes = {}
    
    -- Obfuscation / Junk Checks
    local junkPatterns = {
        { "string%.char", 15 }, -- Heavily used in obfuscation
        { "getfenv", 10 },
        { "setfenv", 10 },
        { "loadstring", 20 },
        { "bit32%.bxor", 10 },
        { "RunService%]%]%:FireServer", 50 }, -- Common in some exploit logs
    }
    
    for _, check in ipairs(junkPatterns) do
        local _, count = source:gsub(check[1], "")
        if count > 5 then
            quality = quality - math.min(check[2] * count, 60)
            table.insert(notes, check[1] .. " detected")
        end
    end
    
    if quality < 15 then
        return true, quality, "Low Quality / Obfuscated: " .. table.concat(notes, ", ")
    end
    
    return true, quality, "OK"
end

-- Dump Bytecode as Fallback
function BaoSaveInstance._DumpBytecodeAsComment(scriptInstance)
    local bytecode = nil
    
    pcall(function()
        if getscriptbytecode then
            bytecode = getscriptbytecode(scriptInstance)
        end
    end)
    
    if not bytecode then return nil end
    
    local b64 = Utility.Base64Encode(bytecode)
    local hash = "N/A"
    pcall(function() hash = getscripthash(scriptInstance) end)
    
    return string.format("--[[\n\t[BaoSaveInstance V2] BYTECODE DUMP\n\tReason: Decompile failed\n\tHash: %s\n\tSize: %d bytes\n\tBase64: %s\n]]", 
        hash, #bytecode, b64)
end

-- Enhanced Script Collector V3 (Maximum Power)
function BaoSaveInstance._CollectScriptSource(scriptInstance)
    if not scriptInstance then return nil end
    local config = BaoSaveInstance._config
    local fullName = scriptInstance:GetFullName()
    
    -- 0. Check Cache
    local scriptHash = nil
    if BaoSaveInstance._capabilities.HasGetScriptHash then
        pcall(function() scriptHash = getscripthash(scriptInstance) end)
    end
    
    -- Try hash-based cache first (most accurate)
    if scriptHash and BaoSaveInstance._decompileCache[scriptHash] then
        BaoSaveInstance._stats.ScriptsCached = BaoSaveInstance._stats.ScriptsCached + 1
        return BaoSaveInstance._decompileCache[scriptHash]
    end
    
    -- Try name-based cache (fallback)
    if not scriptHash and BaoSaveInstance._decompileCache[fullName] then
        BaoSaveInstance._stats.ScriptsCached = BaoSaveInstance._stats.ScriptsCached + 1
        return BaoSaveInstance._decompileCache[fullName]
    end
    
    local source = nil
    local success = false
    local method = "Unknown"
    local qualityScore = 0
    local qualityNote = ""
    local attempts = 0
    
    -- 1. Try Source property (Studio / High Privileges)
    if not success then
        pcall(function()
            if scriptInstance:IsA("LuaSourceContainer") and scriptInstance.Source ~= "" then
                local valid, qual, note = BaoSaveInstance._ValidateSource(scriptInstance.Source)
                if valid then
                    source = scriptInstance.Source
                    method = "SourceProperty"
                    qualityScore = qual
                    qualityNote = note
                    success = true
                end
            end
        end)
    end
    
    -- 2. Try ALL Decompilers (Multi-Executor Power)
    if not success and config.UseExecutorDecompiler then
        local decompilers = BaoSaveInstance._GetAllDecompilers()
        local maxRetries = config.DecompileMaxRetries or 2
        
        for _, d in ipairs(decompilers) do
            for retry = 1, maxRetries do
                attempts = attempts + 1
                local src, err = BaoSaveInstance._DecompileWithTimeout(d.func, scriptInstance, config.DecompileTimeout)
                
                if src then
                    local valid, qual, note = BaoSaveInstance._ValidateSource(src)
                    if valid then
                        source = src
                        method = d.name
                        qualityScore = qual
                        qualityNote = note
                        success = true
                        break
                    end
                end
                
                -- GC between retries to free memory for large scripts
                if retry < maxRetries then
                    collectgarbage("collect")
                    task.wait(0.1)
                end
            end
            if success then break end
        end
    end
    
    -- 3. Try getscriptclosure (Closure Decompile)
    if not success and getscriptclosure then
        pcall(function()
            local closure = getscriptclosure(scriptInstance)
            if closure and type(closure) == "function" then
                -- Try to decompile the closure itself
                local decompilers = BaoSaveInstance._GetAllDecompilers()
                for _, d in ipairs(decompilers) do
                    pcall(function()
                        local src = d.func(closure)
                        if src and src ~= "" then
                            local valid, qual, note = BaoSaveInstance._ValidateSource(src)
                            if valid then
                                source = src
                                method = d.name .. " (closure)"
                                qualityScore = qual
                                qualityNote = note
                                success = true
                            end
                        end
                    end)
                    if success then break end
                end
            end
        end)
    end
    
    -- 4. Try require() trick for ModuleScripts
    if not success and scriptInstance:IsA("ModuleScript") then
        pcall(function()
            local moduleResult = require(scriptInstance)
            if moduleResult ~= nil then
                local resultStr = nil
                if type(moduleResult) == "table" then
                    -- Serialize table as readable Lua
                    local lines = {"-- [BaoSaveInstance] Module return value (serialized)", "return {"}
                    for k, v in pairs(moduleResult) do
                        local keyStr = type(k) == "string" and string.format('["%s"]', k) or string.format("[%s]", tostring(k))
                        local valStr
                        if type(v) == "string" then
                            valStr = string.format('"%s"', v:gsub('"', '\\"'))
                        elseif type(v) == "number" or type(v) == "boolean" then
                            valStr = tostring(v)
                        elseif type(v) == "function" then
                            valStr = '"<function>"'
                        else
                            valStr = string.format('"%s"', tostring(v))
                        end
                        table.insert(lines, string.format("    %s = %s,", keyStr, valStr))
                    end
                    table.insert(lines, "}")
                    resultStr = table.concat(lines, "\n")
                elseif type(moduleResult) == "function" then
                    resultStr = "-- [BaoSaveInstance] Module returns a function\nreturn function() end"
                else
                    resultStr = "-- [BaoSaveInstance] Module return value\nreturn " .. tostring(moduleResult)
                end
                
                if resultStr then
                    source = resultStr
                    method = "require() serialize"
                    qualityScore = 40  -- Lower quality since it's just the return value
                    qualityNote = "Serialized return value only"
                    success = true
                end
            end
        end)
    end
    
    -- 5. Try Constant Pool Extraction from Bytecode
    if not success and BaoSaveInstance._capabilities.HasGetScriptBytecode then
        pcall(function()
            local bytecode = getscriptbytecode(scriptInstance)
            if bytecode and #bytecode > 4 then
                -- Extract readable string constants from bytecode
                local constants = {}
                -- Scan for string patterns in bytecode (strings are stored as length-prefixed)
                local pos = 1
                while pos < #bytecode - 4 do
                    -- Look for printable ASCII sequences of 4+ chars
                    local chunk = bytecode:sub(pos, pos + 200)
                    local str = chunk:match("([%w%p ]{4,100})")
                    if str and not str:match("^%x+$") then
                        -- Filter likely strings (not just hex data)
                        local clean = str:gsub("[^%w%p ]", "")
                        if #clean >= 4 then
                            constants[clean] = true
                        end
                    end
                    pos = pos + 1
                end
                
                if next(constants) then
                    local lines = {
                        "-- [BaoSaveInstance] CONSTANT POOL EXTRACTION",
                        "-- Full decompile failed. Extracted string constants from bytecode:",
                        "--",
                    }
                    local count = 0
                    for str, _ in pairs(constants) do
                        if count < 200 then -- Cap at 200 constants
                            table.insert(lines, '-- "' .. str .. '"')
                            count = count + 1
                        end
                    end
                    table.insert(lines, "--")
                    table.insert(lines, "-- Total constants found: " .. count)
                    
                    source = table.concat(lines, "\n")
                    method = "ConstantPool"
                    qualityScore = 15
                    qualityNote = "Constants only, no logic recovered"
                    success = true
                end
            end
        end)
    end
    
    -- 6. Try ScriptEditorService (Studio Fallback)
    if not success and BaoSaveInstance._capabilities.IsStudio then
        pcall(function()
            local ses = game:GetService("ScriptEditorService")
            if ses then
                local doc = ses:FindScriptDocument(scriptInstance)
                if doc then
                    local src = doc:GetText()
                    if src and src ~= "" then
                        source = src
                        method = "ScriptEditorService"
                        qualityScore = 100
                        success = true
                    end
                end
            end
        end)
    end
    
    -- 4. Result Processing
    if success and source then
        BaoSaveInstance._stats.Scripts = BaoSaveInstance._stats.Scripts + 1
        
        local className = "Script"
        pcall(function() className = scriptInstance.ClassName end)
        
        local hashInfo = scriptHash and string.format("\n\tHash: %s", tostring(scriptHash)) or ""
        local noteInfo = qualityNote ~= "OK" and string.format("\n\tNote: %s", qualityNote) or ""
        
        local header = string.format("--[[\n\tBaoSaveInstance V2 Official\n\tClass: %s\n\tSource: %s\n\tMethod: %s\n\tQuality: %d%%%s\n\tTime: %s%s\n]]\n\n",
            className,
            fullName,
            method,
            qualityScore,
            noteInfo,
            os.date("%c"),
            hashInfo
        )
        
        local finalSource = header .. source
        
        -- Cache result
        if scriptHash then
            BaoSaveInstance._decompileCache[scriptHash] = finalSource
        else
            BaoSaveInstance._decompileCache[fullName] = finalSource
        end
        
        return finalSource
        
    else
        -- 5. FAILURE FALLBACK -> Bytecode Dump
        BaoSaveInstance._stats.ScriptsFailed = BaoSaveInstance._stats.ScriptsFailed + 1
        
        if config.SaveBytecodeOnFail then
            local dump = BaoSaveInstance._DumpBytecodeAsComment(scriptInstance)
            if dump then
                BaoSaveInstance._stats.ScriptsBytecodeOnly = BaoSaveInstance._stats.ScriptsBytecodeOnly + 1
                return dump
            end
        end
        
        -- Absolute failure
        BaoSaveInstance._stats.Errors = BaoSaveInstance._stats.Errors + 1
        if scriptInstance:IsA("Script") or scriptInstance:IsA("LocalScript") or scriptInstance:IsA("ModuleScript") then
             return string.format("--[[\n\t[BaoSaveInstance V2] FAILED TO DECOMPILE\n\tSource: %s\n\tReason: All %d attempts failed.\n]]", 
                fullName, attempts)
        end
    end
    
    return nil
end

-- V2: Process scripts in cloned tree — WRITES source back into .Source property
function BaoSaveInstance._ProcessScriptsInTree(root)
    if not root then return 0 end
    
    local scriptCount = 0
    local writeBack = BaoSaveInstance._config.WriteSourceToClone
    local descendants = {}
    
    Utility.Log("INFO", "Collecting scripts from tree...")
    pcall(function()
        descendants = root:GetDescendants()
    end)
    table.insert(descendants, root)
    
    -- Filter only scripts first to know total count for progress
    local scriptsToProcess = {}
    for _, desc in ipairs(descendants) do
        if desc:IsA("LuaSourceContainer") then
            table.insert(scriptsToProcess, desc)
        end
    end
    
    local totalScripts = #scriptsToProcess
    Utility.Log("INFO", "Found " .. totalScripts .. " scripts to process")
    
    -- Batch process
    local batchSize = 10
    local processed = 0
    
    for i, scriptInstance in ipairs(scriptsToProcess) do
        -- Check Cancel
        if BaoSaveInstance._cancelRequested then
            Utility.Log("WARN", "Operation cancelled by user during script processing")
            BaoSaveInstance._cancelled = true
            break
        end
        
        pcall(function()
            -- Check if source already exists (e.g. from Studio)
            local hasSource = false
            pcall(function()
                hasSource = (scriptInstance.Source ~= nil and scriptInstance.Source ~= "")
            end)
            
            if not hasSource and writeBack then
                -- Decompile and write source back into the cloned script
                local decompiled = BaoSaveInstance._CollectScriptSource(scriptInstance)
                if decompiled then
                    pcall(function()
                        scriptInstance.Source = decompiled
                    end)
                end
            elseif hasSource then
                -- Even if it has source, we might want to validate/header it if it's raw
                -- But for now let's assume if it has source it's good (optimization)
                BaoSaveInstance._stats.Scripts = BaoSaveInstance._stats.Scripts + 1
            end
            
            scriptCount = scriptCount + 1
        end)
        
        processed = processed + 1
        
        -- Update Progress & Yield
        if i % batchSize == 0 then
            local progress = (i / totalScripts) * 100
             BaoSaveInstance._SetProgress(progress)
             BaoSaveInstance._SetStatus("Processing Scripts (" .. i .. "/" .. totalScripts .. ")")
             task.wait() 
        end
    end
    
    return scriptCount
end

-- V3: Sweep hidden scripts (Loaded Modules + Nil Instances + Running Scripts)
function BaoSaveInstance._CollectLoadedModules(container)
    local count = 0
    local processedHashes = {}
    local config = BaoSaveInstance._config
    
    local hiddenFolder = Instance.new("Folder")
    hiddenFolder.Name = "_HiddenScripts"
    
    local function processScript(scriptInstance, sourceName)
        if not scriptInstance then return end
        
        -- Duplicate check via Hash (if available) or unique ID
        local hash = nil
        pcall(function()
            if BaoSaveInstance._capabilities.HasGetScriptHash then
                hash = getscripthash(scriptInstance)
            end
        end)
        
        -- If we have a hash and saw it, skip
        if hash and processedHashes[hash] then return end
        if hash then processedHashes[hash] = true end
        
        -- Check if it's already in the game tree
        local isInTree = false
        pcall(function()
            if scriptInstance:IsDescendantOf(game) then
                isInTree = true
            end
        end)
        
        if not isInTree or scriptInstance.Parent == nil then
            -- Clone and decompile
            local clone = nil
            -- Try to clone, but some nil instances are locked
            pcall(function()
                 -- Special handling for nil instances: we might need to create a new script and copy source
                 -- because cloning a nil/locked script might fail or return emptiness
                 if scriptInstance:IsA("ModuleScript") then
                    clone = Instance.new("ModuleScript")
                 elseif scriptInstance:IsA("LocalScript") then
                    clone = Instance.new("LocalScript")
                 else
                    clone = Instance.new("Script")
                 end
                 clone.Name = scriptInstance.Name .. " (" .. sourceName .. ")"
                 
                 -- Try to copy properties if possible
                 pcall(function() clone.Name = scriptInstance.Name end)
            end)
            
            if clone then
                local src = BaoSaveInstance._CollectScriptSource(scriptInstance)
                if src then
                    pcall(function() clone.Source = src end)
                    clone.Parent = hiddenFolder
                    count = count + 1
                end
            end
        end
    end
    
    -- 1. Get Loaded Modules
    if BaoSaveInstance._capabilities.HasGetLoadedModules then
        pcall(function()
            local modules = getloadedmodules()
            if modules then
                Utility.Log("INFO", "Scanning " .. #modules .. " loaded modules...")
                for _, mod in ipairs(modules) do
                    processScript(mod, "LoadedModule")
                end
            end
        end)
    end
    
    -- 2. Get Nil Instances (Scripts)
    if config.DecompileNilScripts and BaoSaveInstance._capabilities.HasGetNilInstances then
         pcall(function()
            local nils = getnilinstances()
            if nils then
                Utility.Log("INFO", "Scanning " .. #nils .. " nil instances...")
                for _, inst in ipairs(nils) do
                    if inst:IsA("LuaSourceContainer") then
                        processScript(inst, "NilInstance")
                    end
                end
            end
        end)
    end
    
    -- 3. Get Running Scripts (if available)
    if getrunningscripts then
         pcall(function()
            local running = getrunningscripts()
            if running then
                Utility.Log("INFO", "Scanning " .. #running .. " running scripts...")
                for _, s in ipairs(running) do
                    processScript(s, "RunningScript")
                end
            end
        end)
    end
    
    if count > 0 then
        hiddenFolder.Parent = container
        Utility.Log("INFO", "Recovered " .. count .. " hidden scripts/modules")
    else
        hiddenFolder:Destroy()
    end
    
    return count
end

-- ============================================================
-- DEEP CLONE SYSTEM
-- ============================================================

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
-- TERRAIN CAPTURE SYSTEM V3 (Full Power)
-- ============================================================

-- All 22 Roblox terrain material types
local TERRAIN_MATERIALS = {
    Enum.Material.Grass, Enum.Material.Sand, Enum.Material.Rock, Enum.Material.Water,
    Enum.Material.Glacier, Enum.Material.Snow, Enum.Material.Sandstone, Enum.Material.Mud,
    Enum.Material.Basalt, Enum.Material.Ground, Enum.Material.CrackedLava, Enum.Material.Asphalt,
    Enum.Material.Cobblestone, Enum.Material.Ice, Enum.Material.LeafyGrass, Enum.Material.Salt,
    Enum.Material.Limestone, Enum.Material.Pavement, Enum.Material.Slate, Enum.Material.Concrete,
    Enum.Material.WoodPlanks, Enum.Material.Air,
}

function BaoSaveInstance._CaptureTerrain()
    local terrain = nil
    pcall(function()
        terrain = Services.Workspace and Services.Workspace.Terrain
    end)
    
    if not terrain then
        Utility.Log("WARN", "Terrain not found")
        return nil
    end
    
    Utility.TimerStart("TerrainCapture")
    
    -- Clone terrain object first
    local terrainClone = Utility.SafeClone(terrain)
    if not terrainClone then
        pcall(function()
            terrainClone = Instance.new("Terrain")
        end)
    end
    
    if not terrainClone then
        Utility.Log("ERROR", "Cannot create Terrain instance")
        return nil
    end
    
    Utility.Log("INFO", "Terrain object captured — starting full decompile")
    
    -- 1. Copy Water Properties
    pcall(function()
        terrainClone.WaterColor = terrain.WaterColor
        terrainClone.WaterReflectance = terrain.WaterReflectance
        terrainClone.WaterTransparency = terrain.WaterTransparency
        terrainClone.WaterWaveSize = terrain.WaterWaveSize
        terrainClone.WaterWaveSpeed = terrain.WaterWaveSpeed
    end)
    
    -- 2. Copy Decoration flag
    pcall(function() terrainClone.Decoration = terrain.Decoration end)
    
    -- 3. Capture MaterialColors (all 22 material types)
    local matColorCount = 0
    for _, mat in ipairs(TERRAIN_MATERIALS) do
        pcall(function()
            local color = terrain:GetMaterialColor(mat)
            if color then
                terrainClone:SetMaterialColor(mat, color)
                matColorCount = matColorCount + 1
            end
        end)
    end
    Utility.Log("INFO", "Captured " .. matColorCount .. " material colors")
    
    -- 4. Get terrain bounds
    local extents = Vector3.new(0, 0, 0)
    pcall(function()
        extents = terrain:GetExtentsSize()
        Utility.Log("INFO", string.format("Terrain extents: %.0f x %.0f x %.0f studs", 
            extents.X, extents.Y, extents.Z))
    end)
    
    -- 5. Capture Voxel Data with Adaptive Chunking
    if extents.X > 0 and extents.Y > 0 and extents.Z > 0 then
        local RESOLUTION = 4
        local minBound = Vector3.new(-extents.X/2, -extents.Y/2, -extents.Z/2)
        local maxBound = Vector3.new(extents.X/2, extents.Y/2, extents.Z/2)
        
        -- Estimate total regions for progress
        local chunkSizes = {512, 256, 128, 64} -- Adaptive: try large first, fall back to small
        local regionCount = 0
        local failedRegions = 0
        local emptyRegions = 0
        local memWarnings = 0
        
        -- Calculate total number of chunks for progress reporting
        local initialChunk = chunkSizes[1]
        local totalChunksEstimate = math.ceil((maxBound.X - minBound.X) / initialChunk)
            * math.ceil((maxBound.Y - minBound.Y) / initialChunk)
            * math.ceil((maxBound.Z - minBound.Z) / initialChunk)
        local chunksDone = 0
        
        -- Adaptive ReadVoxels: try chunk, if it fails, split into smaller chunks
        local function captureRegion(rStart, rEnd, chunkIdx)
            if chunkIdx > #chunkSizes then
                failedRegions = failedRegions + 1
                return
            end
            
            -- Memory safety check
            local mem = 0
            pcall(function() mem = gcinfo() end)
            if mem > 500000 then -- ~500MB warning
                memWarnings = memWarnings + 1
                collectgarbage("collect")
                task.wait(0.2)
            end
            
            local region = Region3.new(rStart, rEnd)
            region = region:ExpandToGrid(RESOLUTION)
            
            local ok, materials, occupancy = false, nil, nil
            ok = pcall(function()
                materials, occupancy = terrain:ReadVoxels(region, RESOLUTION)
            end)
            
            if ok and materials and occupancy then
                -- Check if region has any non-air content
                local hasContent = false
                pcall(function()
                    for xi = 1, #materials do
                        for yi = 1, #materials[xi] do
                            for zi = 1, #materials[xi][yi] do
                                if materials[xi][yi][zi] ~= Enum.Material.Air then
                                    hasContent = true
                                    return
                                end
                            end
                            if hasContent then return end
                        end
                        if hasContent then return end
                    end
                end)
                
                if hasContent then
                    pcall(function()
                        terrainClone:WriteVoxels(region, RESOLUTION, materials, occupancy)
                    end)
                    regionCount = regionCount + 1
                else
                    emptyRegions = emptyRegions + 1
                end
            else
                -- Failed — try smaller chunk size
                local nextIdx = chunkIdx + 1
                if nextIdx <= #chunkSizes then
                    local subSize = chunkSizes[nextIdx]
                    for sx = rStart.X, rEnd.X - 1, subSize do
                        for sy = rStart.Y, rEnd.Y - 1, subSize do
                            for sz = rStart.Z, rEnd.Z - 1, subSize do
                                local subStart = Vector3.new(sx, sy, sz)
                                local subEnd = Vector3.new(
                                    math.min(sx + subSize, rEnd.X),
                                    math.min(sy + subSize, rEnd.Y),
                                    math.min(sz + subSize, rEnd.Z)
                                )
                                captureRegion(subStart, subEnd, nextIdx)
                            end
                        end
                    end
                else
                    failedRegions = failedRegions + 1
                end
            end
        end
        
        -- Main loop: iterate with largest chunk size
        local mainChunk = chunkSizes[1]
        for x = minBound.X, maxBound.X - 1, mainChunk do
            for y = minBound.Y, maxBound.Y - 1, mainChunk do
                for z = minBound.Z, maxBound.Z - 1, mainChunk do
                    -- Cancel check
                    if BaoSaveInstance._cancelRequested then
                        Utility.Log("WARN", "Terrain capture cancelled")
                        break
                    end
                    
                    local rStart = Vector3.new(x, y, z)
                    local rEnd = Vector3.new(
                        math.min(x + mainChunk, maxBound.X),
                        math.min(y + mainChunk, maxBound.Y),
                        math.min(z + mainChunk, maxBound.Z)
                    )
                    
                    captureRegion(rStart, rEnd, 1)
                    
                    chunksDone = chunksDone + 1
                    
                    -- Progress + yield
                    if chunksDone % 5 == 0 then
                        local pct = math.min(99, math.floor((chunksDone / math.max(totalChunksEstimate, 1)) * 100))
                        Utility.Log("INFO", string.format("Terrain: %d%% (%d regions captured, %d empty, %d failed)",
                            pct, regionCount, emptyRegions, failedRegions))
                        task.wait()
                    end
                end
                if BaoSaveInstance._cancelRequested then break end
            end
            if BaoSaveInstance._cancelRequested then break end
        end
        
        Utility.Log("INFO", string.format(
            "Terrain voxels complete: %d regions written, %d empty, %d failed, %d mem warnings",
            regionCount, emptyRegions, failedRegions, memWarnings))
    else
        Utility.Log("WARN", "Terrain has zero extents, skipping voxel capture")
    end
    
    Utility.TimerEnd("TerrainCapture")
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
            
            -- ===== V2: Constraint Types =====
            pcall(function()
                if inst:IsA("Constraint") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Enabled">' .. tostring(inst.Enabled) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Visible">' .. tostring(inst.Visible) .. '</bool>')
                    
                    pcall(function()
                        if inst:IsA("RopeConstraint") or inst:IsA("RodConstraint") then
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Length">' .. tostring(inst.Length) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Thickness">' .. tostring(inst.Thickness) .. '</float>')
                        end
                    end)
                    pcall(function()
                        if inst:IsA("SpringConstraint") then
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Stiffness">' .. tostring(inst.Stiffness) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Damping">' .. tostring(inst.Damping) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="FreeLength">' .. tostring(inst.FreeLength) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="MinLength">' .. tostring(inst.MinLength) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="MaxLength">' .. tostring(inst.MaxLength) .. '</float>')
                        end
                    end)
                    pcall(function()
                        if inst:IsA("HingeConstraint") then
                            table.insert(xml, string.rep(" ", depth + 2) .. '<token name="ActuatorType">' .. inst.ActuatorType.Value .. '</token>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="AngularSpeed">' .. tostring(inst.AngularSpeed) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="MotorMaxTorque">' .. tostring(inst.MotorMaxTorque) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="LimitsEnabled">' .. tostring(inst.LimitsEnabled) .. '</bool>')
                        end
                    end)
                    pcall(function()
                        if inst:IsA("BallSocketConstraint") then
                            table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="LimitsEnabled">' .. tostring(inst.LimitsEnabled) .. '</bool>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="UpperAngle">' .. tostring(inst.UpperAngle) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="TwistUpperAngle">' .. tostring(inst.TwistUpperAngle) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="TwistLowerAngle">' .. tostring(inst.TwistLowerAngle) .. '</float>')
                        end
                    end)
                    pcall(function()
                        if inst:IsA("PrismaticConstraint") then
                            table.insert(xml, string.rep(" ", depth + 2) .. '<token name="ActuatorType">' .. inst.ActuatorType.Value .. '</token>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Speed">' .. tostring(inst.Speed) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="UpperLimit">' .. tostring(inst.UpperLimit) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="LowerLimit">' .. tostring(inst.LowerLimit) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="LimitsEnabled">' .. tostring(inst.LimitsEnabled) .. '</bool>')
                        end
                    end)
                    pcall(function()
                        if inst:IsA("AlignPosition") then
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="MaxForce">' .. tostring(inst.MaxForce) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Responsiveness">' .. tostring(inst.Responsiveness) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<token name="Mode">' .. inst.Mode.Value .. '</token>')
                        end
                    end)
                    pcall(function()
                        if inst:IsA("AlignOrientation") then
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="MaxTorque">' .. tostring(inst.MaxTorque) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Responsiveness">' .. tostring(inst.Responsiveness) .. '</float>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<token name="Mode">' .. inst.Mode.Value .. '</token>')
                        end
                    end)
                    pcall(function()
                        if inst:IsA("LinearVelocity") then
                            local lv = inst.VectorVelocity
                            table.insert(xml, string.rep(" ", depth + 2) .. '<Vector3 name="VectorVelocity">')
                            table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. lv.X .. '</X><Y>' .. lv.Y .. '</Y><Z>' .. lv.Z .. '</Z>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '</Vector3>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="MaxForce">' .. tostring(inst.MaxForce) .. '</float>')
                        end
                    end)
                    pcall(function()
                        if inst:IsA("AngularVelocity") then
                            local av = inst.AngularVelocity
                            table.insert(xml, string.rep(" ", depth + 2) .. '<Vector3 name="AngularVelocity">')
                            table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. av.X .. '</X><Y>' .. av.Y .. '</Y><Z>' .. av.Z .. '</Z>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '</Vector3>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '<float name="MaxTorque">' .. tostring(inst.MaxTorque) .. '</float>')
                        end
                    end)
                    pcall(function()
                        if inst:IsA("VectorForce") then
                            local vf = inst.Force
                            table.insert(xml, string.rep(" ", depth + 2) .. '<Vector3 name="Force">')
                            table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. vf.X .. '</X><Y>' .. vf.Y .. '</Y><Z>' .. vf.Z .. '</Z>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '</Vector3>')
                        end
                    end)
                    pcall(function()
                        if inst:IsA("Torque") then
                            local tq = inst.Torque
                            table.insert(xml, string.rep(" ", depth + 2) .. '<Vector3 name="Torque">')
                            table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. tq.X .. '</X><Y>' .. tq.Y .. '</Y><Z>' .. tq.Z .. '</Z>')
                            table.insert(xml, string.rep(" ", depth + 2) .. '</Vector3>')
                        end
                    end)
                end
            end)
            
            -- ===== V2: UILayout Types =====
            pcall(function()
                if inst:IsA("UIListLayout") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="FillDirection">' .. inst.FillDirection.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="HorizontalAlignment">' .. inst.HorizontalAlignment.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="VerticalAlignment">' .. inst.VerticalAlignment.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="SortOrder">' .. inst.SortOrder.Value .. '</token>')
                    local pd = inst.Padding
                    table.insert(xml, string.rep(" ", depth + 2) .. '<UDim name="Padding">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<S>' .. pd.Scale .. '</S><O>' .. pd.Offset .. '</O>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</UDim>')
                    pcall(function()
                        table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Wraps">' .. tostring(inst.Wraps) .. '</bool>')
                    end)
                end
            end)
            pcall(function()
                if inst:IsA("UIGridLayout") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="FillDirection">' .. inst.FillDirection.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="HorizontalAlignment">' .. inst.HorizontalAlignment.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="VerticalAlignment">' .. inst.VerticalAlignment.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="SortOrder">' .. inst.SortOrder.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="StartCorner">' .. inst.StartCorner.Value .. '</token>')
                    local cs = inst.CellSize
                    table.insert(xml, string.rep(" ", depth + 2) .. '<UDim2 name="CellSize">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<XS>' .. cs.X.Scale .. '</XS><XO>' .. cs.X.Offset .. '</XO>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<YS>' .. cs.Y.Scale .. '</YS><YO>' .. cs.Y.Offset .. '</YO>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</UDim2>')
                    local cp = inst.CellPadding
                    table.insert(xml, string.rep(" ", depth + 2) .. '<UDim2 name="CellPadding">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<XS>' .. cp.X.Scale .. '</XS><XO>' .. cp.X.Offset .. '</XO>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<YS>' .. cp.Y.Scale .. '</YS><YO>' .. cp.Y.Offset .. '</YO>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</UDim2>')
                end
            end)
            pcall(function()
                if inst:IsA("UIPadding") then
                    local pl, pr, pt, pb = inst.PaddingLeft, inst.PaddingRight, inst.PaddingTop, inst.PaddingBottom
                    table.insert(xml, string.rep(" ", depth + 2) .. '<UDim name="PaddingLeft"><S>' .. pl.Scale .. '</S><O>' .. pl.Offset .. '</O></UDim>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<UDim name="PaddingRight"><S>' .. pr.Scale .. '</S><O>' .. pr.Offset .. '</O></UDim>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<UDim name="PaddingTop"><S>' .. pt.Scale .. '</S><O>' .. pt.Offset .. '</O></UDim>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<UDim name="PaddingBottom"><S>' .. pb.Scale .. '</S><O>' .. pb.Offset .. '</O></UDim>')
                end
            end)
            pcall(function()
                if inst:IsA("UIScale") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Scale">' .. tostring(inst.Scale) .. '</float>')
                end
            end)
            pcall(function()
                if inst:IsA("UIAspectRatioConstraint") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="AspectRatio">' .. tostring(inst.AspectRatio) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="AspectType">' .. inst.AspectType.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="DominantAxis">' .. inst.DominantAxis.Value .. '</token>')
                end
            end)
            pcall(function()
                if inst:IsA("UISizeConstraint") then
                    local minS = inst.MinSize
                    local maxS = inst.MaxSize
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Vector2 name="MinSize"><X>' .. minS.X .. '</X><Y>' .. minS.Y .. '</Y></Vector2>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Vector2 name="MaxSize"><X>' .. maxS.X .. '</X><Y>' .. maxS.Y .. '</Y></Vector2>')
                end
            end)
            pcall(function()
                if inst:IsA("UITextSizeConstraint") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<int name="MinTextSize">' .. tostring(inst.MinTextSize) .. '</int>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<int name="MaxTextSize">' .. tostring(inst.MaxTextSize) .. '</int>')
                end
            end)
            pcall(function()
                if inst:IsA("UIFlexItem") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="FlexMode">' .. inst.FlexMode.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="GrowRatio">' .. tostring(inst.GrowRatio) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="ShrinkRatio">' .. tostring(inst.ShrinkRatio) .. '</float>')
                end
            end)
            
            -- ===== V2: Highlight =====
            pcall(function()
                if inst:IsA("Highlight") then
                    local fc = inst.FillColor
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="FillColor"><R>' .. fc.R .. '</R><G>' .. fc.G .. '</G><B>' .. fc.B .. '</B></Color3>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="FillTransparency">' .. tostring(inst.FillTransparency) .. '</float>')
                    local oc = inst.OutlineColor
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Color3 name="OutlineColor"><R>' .. oc.R .. '</R><G>' .. oc.G .. '</G><B>' .. oc.B .. '</B></Color3>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="OutlineTransparency">' .. tostring(inst.OutlineTransparency) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="DepthMode">' .. inst.DepthMode.Value .. '</token>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Enabled">' .. tostring(inst.Enabled) .. '</bool>')
                end
            end)
            
            -- ===== V2: Trail =====
            pcall(function()
                if inst:IsA("Trail") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="Texture"><url>' .. escapeXml(inst.Texture) .. '</url></Content>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="Lifetime">' .. tostring(inst.Lifetime) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="MinLength">' .. tostring(inst.MinLength) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="MaxLength">' .. tostring(inst.MaxLength) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="WidthScale">' .. tostring(inst.WidthScale) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="LightEmission">' .. tostring(inst.LightEmission) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="Enabled">' .. tostring(inst.Enabled) .. '</bool>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="FaceCamera">' .. tostring(inst.FaceCamera) .. '</token>')
                end
            end)
            
            -- ===== V2: Camera =====
            pcall(function()
                if inst:IsA("Camera") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="FieldOfView">' .. tostring(inst.FieldOfView) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<token name="CameraType">' .. inst.CameraType.Value .. '</token>')
                    local ccf = inst.CFrame
                    local cx, cy, cz, cR00, cR01, cR02, cR10, cR11, cR12, cR20, cR21, cR22 = ccf:GetComponents()
                    table.insert(xml, string.rep(" ", depth + 2) .. '<CoordinateFrame name="CFrame">')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<X>' .. cx .. '</X><Y>' .. cy .. '</Y><Z>' .. cz .. '</Z>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R00>' .. cR00 .. '</R00><R01>' .. cR01 .. '</R01><R02>' .. cR02 .. '</R02>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R10>' .. cR10 .. '</R10><R11>' .. cR11 .. '</R11><R12>' .. cR12 .. '</R12>')
                    table.insert(xml, string.rep(" ", depth + 3) .. '<R20>' .. cR20 .. '</R20><R21>' .. cR21 .. '</R21><R22>' .. cR22 .. '</R22>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '</CoordinateFrame>')
                end
            end)
            
            -- ===== V2: SurfaceAppearance =====
            pcall(function()
                if inst:IsA("SurfaceAppearance") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="ColorMap"><url>' .. escapeXml(inst.ColorMap) .. '</url></Content>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="MetalnessMap"><url>' .. escapeXml(inst.MetalnessMap) .. '</url></Content>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="NormalMap"><url>' .. escapeXml(inst.NormalMap) .. '</url></Content>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="RoughnessMap"><url>' .. escapeXml(inst.RoughnessMap) .. '</url></Content>')
                    pcall(function()
                        table.insert(xml, string.rep(" ", depth + 2) .. '<token name="AlphaMode">' .. inst.AlphaMode.Value .. '</token>')
                    end)
                end
            end)
            
            -- ===== V2: ClickDetector =====
            pcall(function()
                if inst:IsA("ClickDetector") then
                    table.insert(xml, string.rep(" ", depth + 2) .. '<float name="MaxActivationDistance">' .. tostring(inst.MaxActivationDistance) .. '</float>')
                    table.insert(xml, string.rep(" ", depth + 2) .. '<Content name="CursorIcon"><url>' .. escapeXml(inst.CursorIcon) .. '</url></Content>')
                end
            end)
            
            -- ===== V2: UnionOperation =====
            pcall(function()
                if inst:IsA("UnionOperation") then
                    pcall(function()
                        table.insert(xml, string.rep(" ", depth + 2) .. '<token name="CollisionFidelity">' .. inst.CollisionFidelity.Value .. '</token>')
                        table.insert(xml, string.rep(" ", depth + 2) .. '<token name="RenderFidelity">' .. inst.RenderFidelity.Value .. '</token>')
                        table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="UsePartColor">' .. tostring(inst.UsePartColor) .. '</bool>')
                        table.insert(xml, string.rep(" ", depth + 2) .. '<bool name="SmoothingAngle">' .. tostring(inst.SmoothingAngle) .. '</bool>')
                    end)
                end
            end)
            
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
        
        -- Yield periodically for large trees
        refCounter = refCounter  -- already incremented
        if refCounter % 200 == 0 then task.wait() end
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

-- ============================================================
-- UI LAYER (V3 ULTIMATE EDITION)
-- ============================================================

local UIBuilder = {}

-- V3: SafeGUI Loader to fix "Menu Not Showing" issues
local function SafeParent(gui)
    local checkParent = function(parent)
        if parent then
            local success, err = pcall(function()
                gui.Parent = parent
            end)
            return success
        end
        return false
    end

    -- Priority 1: CoreGui (Secure)
    if checkParent(game:GetService("CoreGui")) then return "CoreGui" end
    
    -- Priority 2: PlayerGui (Standard)
    local player = game:GetService("Players").LocalPlayer
    if player and checkParent(player:WaitForChild("PlayerGui", 2)) then return "PlayerGui" end
    
    -- Priority 3: StarterGui (Fallback)
    if checkParent(game:GetService("StarterGui")) then return "StarterGui" end
    
    return nil
end

function UIBuilder.Create()
    -- Services
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    
    -- Destroy existing GUI if any
    pcall(function()
        if game:GetService("CoreGui"):FindFirstChild("BaoSaveInstanceGUI_V3") then
            game:GetService("CoreGui").BaoSaveInstanceGUI_V3:Destroy()
        end
        local player = Players.LocalPlayer
        if player and player.PlayerGui:FindFirstChild("BaoSaveInstanceGUI_V3") then
            player.PlayerGui.BaoSaveInstanceGUI_V3:Destroy()
        end
    end)
    
    -- ================================
    -- V3 Theme Engine (Cyber-Glass)
    -- ================================
    local Theme = {
        Background      = Color3.fromRGB(10, 10, 15),
        Sidebar         = Color3.fromRGB(15, 15, 20),
        Content         = Color3.fromRGB(18, 18, 24),
        
        Surface         = Color3.fromRGB(30, 30, 40),
        SurfaceHover    = Color3.fromRGB(45, 45, 60),
        SurfaceLight    = Color3.fromRGB(50, 50, 70),
        
        -- Gradients
        Gradient1       = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)), -- Blurple
            ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 40, 140))  -- Pink
        },
        
        Primary         = Color3.fromRGB(88, 101, 242), 
        Accent          = Color3.fromRGB(0, 255, 170), -- Neon Cyan
        
        TextPrimary     = Color3.fromRGB(255, 255, 255),
        TextSecondary   = Color3.fromRGB(180, 180, 190),
        TextMuted       = Color3.fromRGB(100, 100, 110),
        
        Border          = Color3.fromRGB(60, 60, 80),
        Separator       = Color3.fromRGB(40, 40, 50),
        
        Success         = Color3.fromRGB(60, 220, 130),
        Warning         = Color3.fromRGB(255, 180, 40),
        Error           = Color3.fromRGB(255, 70, 70),
        
        Shadow          = Color3.fromRGB(0, 0, 0),
    }

    -- Animation Helper
    local function tween(obj, props, time, style, dir)
        TweenService:Create(obj, TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
    end
    
    -- ================================
    -- Create ScreenGui
    -- ================================
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstanceGUI_V3"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 10000 -- Force on top
    screenGui.IgnoreGuiInset = true
    
    local parentedTo = SafeParent(screenGui)
    if not parentedTo then
        warn("CRITICAL ERROR: Could not parent UI to any GUI container!")
        return nil
    end
    Utility.Log("INFO", "UI Parented to: " .. parentedTo)
    
    -- ================================
    -- Shadow/Backdrop (Blur Logic)
    -- ================================
    -- Using a darkened frame as fallback for blur
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.new(0,0,0)
    backdrop.BackgroundTransparency = 1 -- Start transparent for animation
    backdrop.ZIndex = 0
    backdrop.Parent = screenGui
    
    tween(backdrop, {BackgroundTransparency = 0.6}, 1)
    
    -- ================================
    -- Main Frame (Window)
    -- ================================
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.new(0, 0, 0, 0) -- Start small for expanding animation
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    mainFrame.ZIndex = 2
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = mainFrame
    
    -- Animated Border (Gradient Stroke)
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0
    mainStroke.Parent = mainFrame
    
    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = Theme.Gradient1
    strokeGradient.Rotation = 45
    strokeGradient.Parent = mainStroke
    
    -- Intro Animation
    task.spawn(function()
        tween(mainFrame, {
            Size = UDim2.new(0, 700, 0, 500) -- Slightly larger for V3
        }, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        
        -- Rotating border animation loop
        while mainFrame.Parent do
            local tweenRot = TweenService:Create(strokeGradient, TweenInfo.new(3, Enum.EasingStyle.Linear), {Rotation = 405})
            tweenRot:Play()
            tweenRot.Completed:Wait()
            strokeGradient.Rotation = 45
        end
    end)
    
    -- ================================
    -- Draggable Logic Setup
    -- ================================
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local function updateDrag(input)
        if dragging and dragStart and startPos then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            tween(mainFrame, {Position = newPos}, 0.1)
        end
    end
    
    -- ================================
    -- Title Bar
    -- ================================
    -- ================================
    -- Sidebar (Left) V3
    -- ================================
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 180, 1, 0) -- Wider sidebar
    sidebar.BackgroundColor3 = Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame
    sidebar.ZIndex = 3
    
    -- Logo Area
    local logoArea = Instance.new("Frame")
    logoArea.Size = UDim2.new(1, 0, 0, 80)
    logoArea.BackgroundTransparency = 1
    logoArea.Parent = sidebar
    logoArea.ZIndex = 4
    
    local logoText = Instance.new("TextLabel")
    logoText.Text = "BAO\nSAVE"
    logoText.Size = UDim2.new(1, -20, 1, 0)
    logoText.Position = UDim2.new(0, 20, 0, 0)
    logoText.BackgroundTransparency = 1
    logoText.TextColor3 = Theme.TextPrimary
    logoText.TextSize = 24
    logoText.Font = Enum.Font.FredokaOne
    logoText.TextXAlignment = Enum.TextXAlignment.Left
    logoText.Parent = logoArea
    logoText.ZIndex = 5
    
    local logoGrad = Instance.new("UIGradient")
    logoGrad.Color = Theme.Gradient1
    logoGrad.Parent = logoText
    
    -- Navigation
    local navContainer = Instance.new("Frame")
    navContainer.Size = UDim2.new(1, 0, 1, -120)
    navContainer.Position = UDim2.new(0, 0, 0, 80)
    navContainer.BackgroundTransparency = 1
    navContainer.Parent = sidebar
    navContainer.ZIndex = 4
    
    local navList = Instance.new("UIListLayout")
    navList.Padding = UDim.new(0, 8)
    navList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    navList.Parent = navContainer
    
    local navButtons = {}
    local panels = {}
    local currentTab = 1
    
    local function createNavBtn(id, text, icon, layoutOrder)
        local btn = Instance.new("TextButton")
        btn.Name = "Nav_" .. id
        btn.Size = UDim2.new(0, 150, 0, 40)
        btn.BackgroundColor3 = Theme.SurfaceLight
        btn.BackgroundTransparency = 1 -- Default transparent
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.LayoutOrder = layoutOrder
        btn.Parent = navContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn
        
        local ico = Instance.new("TextLabel")
        ico.Text = icon
        ico.Size = UDim2.new(0, 30, 1, 0)
        ico.Position = UDim2.new(0, 10, 0, 0)
        ico.BackgroundTransparency = 1
        ico.TextColor3 = Theme.TextSecondary
        ico.TextSize = 20
        ico.Parent = btn
        
        local lbl = Instance.new("TextLabel")
        lbl.Text = text
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.Position = UDim2.new(0, 45, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Theme.TextSecondary
        lbl.TextSize = 14
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn
        
        -- Logic
        btn.MouseEnter:Connect(function()
            if currentTab ~= layoutOrder then
                tween(btn, {BackgroundTransparency = 0.9}, 0.2)
                tween(lbl, {TextColor3 = Theme.TextPrimary}, 0.2)
            end
        end)
        btn.MouseLeave:Connect(function()
            if currentTab ~= layoutOrder then
                tween(btn, {BackgroundTransparency = 1}, 0.2)
                tween(lbl, {TextColor3 = Theme.TextSecondary}, 0.2)
            end
        end)
        
        table.insert(navButtons, {Button = btn, Label = lbl, Icon = ico, Id = layoutOrder})
        return btn
    end
    
    createNavBtn("Home", "Dashboard", "🏠", 1)
    createNavBtn("Explorer", "Explorer", "⚡", 2)
    createNavBtn("Script", "Script Hub", "📜", 3)
    createNavBtn("Model", "3D View", "🧊", 4)
    createNavBtn("Settings", "Settings", "⚙️", 5)
    
    -- Executor Info (Bottom Left)
    local execInfo = Instance.new("TextLabel")
    execInfo.Size = UDim2.new(1, -20, 0, 40)
    execInfo.Position = UDim2.new(0, 10, 1, -45)
    execInfo.BackgroundTransparency = 1
    execInfo.Text = (BaoSaveInstance._capabilities.ExecutorName or "Unknown") .. "\n" .. (BaoSaveInstance._capabilities.IsStudio and "Studio Mode" or "Executor Mode")
    execInfo.TextColor3 = Theme.TextMuted
    execInfo.TextSize = 10
    execInfo.Font = Enum.Font.Code
    execInfo.TextXAlignment = Enum.TextXAlignment.Left
    execInfo.Parent = sidebar
    execInfo.ZIndex = 4
    
    -- ================================
    -- Content Area
    -- ================================
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "Content"
    contentContainer.Size = UDim2.new(1, -180, 1, 0)
    contentContainer.Position = UDim2.new(0, 180, 0, 0)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame
    
    -- Top Bar
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 50)
    topBar.BackgroundTransparency = 1
    topBar.Parent = contentContainer
    
    -- Window Controls
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -40, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.TextSecondary
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamMedium
    closeBtn.Parent = topBar
    closeBtn.ZIndex = 6
    
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "Minimize"
    minimizeBtn.Size = UDim2.new(0, 40, 0, 40)
    minimizeBtn.Position = UDim2.new(1, -80, 0, 5)
    minimizeBtn.BackgroundTransparency = 1
    minimizeBtn.Text = "─"
    minimizeBtn.TextColor3 = Theme.TextSecondary
    minimizeBtn.TextSize = 16
    minimizeBtn.Font = Enum.Font.GothamMedium
    minimizeBtn.Parent = topBar
    minimizeBtn.ZIndex = 6

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    topBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateDrag(input)
        end
    end)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "BaoSave Instance // Ultimate Edition"
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Theme.TextMuted
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.Code
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topBar
    
    -- Create Panels
    local panelContainer = Instance.new("Frame")
    panelContainer.Size = UDim2.new(1, -40, 1, -100) -- Padding
    panelContainer.Position = UDim2.new(0, 20, 0, 60)
    panelContainer.BackgroundTransparency = 1
    panelContainer.Parent = contentContainer
    
    for i=1, 5 do
        local p = Instance.new("Frame")
        p.Size = UDim2.new(1, 0, 1, 0)
        p.BackgroundTransparency = 1
        p.Visible = false
        p.Parent = panelContainer
        panels[i] = p
    end
    
    -- Status Bar
    local statusBarMain = Instance.new("Frame")
    statusBarMain.Size = UDim2.new(1, -40, 0, 6)
    statusBarMain.Position = UDim2.new(0, 20, 1, -20)
    statusBarMain.BackgroundColor3 = Theme.SurfaceLight
    statusBarMain.BorderSizePixel = 0
    statusBarMain.Parent = contentContainer
    
    Instance.new("UICorner", statusBarMain).CornerRadius = UDim.new(1,0)
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Theme.Accent
    progressBar.BorderSizePixel = 0
    progressBar.Parent = statusBarMain
    Instance.new("UICorner", progressBar).CornerRadius = UDim.new(1,0)
    
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, 0, 0, 15)
    statusText.Position = UDim2.new(0, 0, -20, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Ready for Decompilation"
    statusText.TextColor3 = Theme.TextSecondary
    statusText.TextSize = 12
    statusText.Font = Enum.Font.Gotham
    statusText.TextXAlignment = Enum.TextXAlignment.Right
    statusText.Parent = statusBarMain

    -- Tab Switch Logic
    local function switchTab(id)
        currentTab = id
        for i, p in ipairs(panels) do p.Visible = (i == id) end
        
        for i, b in ipairs(navButtons) do
            local isSel = (b.Id == id)
            if isSel then
                tween(b.Button, {BackgroundColor3 = Theme.Primary, BackgroundTransparency = 0}, 0.2)
                tween(b.Label, {TextColor3 = Theme.TextPrimary}, 0.2)
                tween(b.Icon, {TextColor3 = Theme.TextPrimary}, 0.2)
            else
                tween(b.Button, {BackgroundColor3 = Theme.SurfaceLight, BackgroundTransparency = 1}, 0.2)
                tween(b.Label, {TextColor3 = Theme.TextSecondary}, 0.2)
                tween(b.Icon, {TextColor3 = Theme.TextSecondary}, 0.2)
            end
        end
    end
    
    for _, btnData in ipairs(navButtons) do
        btnData.Button.MouseButton1Click:Connect(function() switchTab(btnData.Id) end)
    end
    switchTab(1)

    
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
    infoFrame.Parent = mainPanel
    
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
    -- V3 Component Library
    -- ================================
    local Components = {}

    function Components.CreateCard(parent, title, icon, size, pos)
        local card = Instance.new("Frame")
        card.Size = size
        card.Position = pos
        card.BackgroundColor3 = Theme.Surface
        card.BorderSizePixel = 0
        card.Parent = parent
        
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Border
        stroke.Transparency = 0.5
        stroke.Parent = card
        
        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -20, 0, 30)
        titleLbl.Position = UDim2.new(0, 10, 0, 5)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = icon .. " " .. title
        titleLbl.TextColor3 = Theme.TextSecondary
        titleLbl.TextSize = 14
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = card
        
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 1, -40)
        container.Position = UDim2.new(0, 10, 0, 35)
        container.BackgroundTransparency = 1
        container.Parent = card
        
        return card, container
    end

    function Components.CreateButton(parent, text, icon, color, size, pos)
        local btn = Instance.new("TextButton")
        btn.Size = size
        btn.Position = pos
        btn.BackgroundColor3 = color or Theme.SurfaceLight
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = parent
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = color or Theme.Border
        btnStroke.Transparency = 0.5
        btnStroke.Parent = btn
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = icon .. "  " .. text
        lbl.TextColor3 = Theme.TextPrimary
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamMedium
        lbl.Parent = btn

        local hoverColor = color and Color3.new(
            math.clamp(color.R + 0.1, 0, 1),
            math.clamp(color.G + 0.1, 0, 1),
            math.clamp(color.B + 0.1, 0, 1)
        ) or Theme.SurfaceHover
        
        btn.MouseEnter:Connect(function()
            tween(btn, {BackgroundColor3 = hoverColor}, 0.2)
            tween(btnStroke, {Transparency = 0}, 0.2)
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, {BackgroundColor3 = color or Theme.SurfaceLight}, 0.2)
            tween(btnStroke, {Transparency = 0.5}, 0.2)
        end)
        btn.MouseButton1Down:Connect(function()
            tween(btn, {Size = UDim2.new(size.X.Scale, size.X.Offset - 4, size.Y.Scale, size.Y.Offset - 2), Position = UDim2.new(pos.X.Scale, pos.X.Offset + 2, pos.Y.Scale, pos.Y.Offset + 1)}, 0.1)
        end)
        btn.MouseButton1Up:Connect(function()
            tween(btn, {Size = size, Position = pos}, 0.1)
        end)
        
        return btn
    end

    function Components.CreateToggle(parent, text, key)
        local frame = Instance.new("TextButton")
        frame.Size = UDim2.new(1, 0, 0, 40)
        frame.BackgroundColor3 = Theme.SurfaceLight
        frame.AutoButtonColor = false
        frame.Text = ""
        frame.Parent = parent
        
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 15, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.TextPrimary
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 13
        label.Parent = frame
        
        local checkBg = Instance.new("Frame")
        checkBg.Size = UDim2.new(0, 40, 0, 20)
        checkBg.Position = UDim2.new(1, -55, 0.5, -10)
        checkBg.BackgroundColor3 = BaoSaveInstance._config[key] and Theme.Success or Theme.Surface
        checkBg.Parent = frame
        Instance.new("UICorner", checkBg).CornerRadius = UDim.new(1, 0)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = BaoSaveInstance._config[key] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = Color3.new(1,1,1)
        knob.Parent = checkBg
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        
        frame.MouseButton1Click:Connect(function()
            BaoSaveInstance._config[key] = not BaoSaveInstance._config[key]
            local on = BaoSaveInstance._config[key]
            tween(checkBg, {BackgroundColor3 = on and Theme.Success or Theme.Surface}, 0.2)
            tween(knob, {Position = on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.2)
        end)
        
        return frame
    end

    -- ================================
    -- Populate Settings Panel
    -- ================================
    local settingsScroll = Instance.new("ScrollingFrame")
    settingsScroll.Size = UDim2.new(1, -20, 1, -20)
    settingsScroll.Position = UDim2.new(0, 10, 0, 10)
    settingsScroll.BackgroundTransparency = 1
    settingsScroll.ScrollBarThickness = 4
    settingsScroll.Parent = panels[5]

    local settingsLayout = Instance.new("UIListLayout")
    settingsLayout.Padding = UDim.new(0, 8)
    settingsLayout.Parent = settingsScroll

    Components.CreateToggle(settingsScroll, "Use Executor Decompiler", "UseExecutorDecompiler")
    Components.CreateToggle(settingsScroll, "Save Attributes", "SaveAttributes")
    Components.CreateToggle(settingsScroll, "Save Tags (CollectionService)", "SaveTags")
    Components.CreateToggle(settingsScroll, "Save Scripts", "SaveScripts")
    Components.CreateToggle(settingsScroll, "Save Terrain", "SaveTerrain")
    Components.CreateToggle(settingsScroll, "Deep Clone (Shell Fallback)", "DeepClone")
    Components.CreateToggle(settingsScroll, "Save Nil Instances", "SaveNilInstances")
    Components.CreateToggle(settingsScroll, "Safe Stream (Stealth)", "StreamingSafeMode")

    -- ================================
    -- Populate Home Dashboard
    -- ================================
    local homeScroll = Instance.new("ScrollingFrame")
    homeScroll.Size = UDim2.new(1, -20, 1, -20)
    homeScroll.Position = UDim2.new(0, 10, 0, 10)
    homeScroll.BackgroundTransparency = 1
    homeScroll.ScrollBarThickness = 4
    homeScroll.CanvasSize = UDim2.new(0, 0, 1.2, 0)
    homeScroll.Parent = panels[1]
    
    local statsCard, statsContainer = Components.CreateCard(homeScroll, "Statistics", "📊", UDim2.new(1, 0, 0, 90), UDim2.new(0, 0, 0, 0))
    
    local function createStatValue(parent, labelText, valueText, pos)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0.33, -4, 1, 0)
        frame.Position = pos
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 15)
        lbl.Position = UDim2.new(0, 0, 0, 5)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = Theme.TextMuted
        lbl.TextSize = 11
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.Parent = frame
        
        local val = Instance.new("TextLabel")
        val.Name = "Value"
        val.Size = UDim2.new(1, 0, 0, 25)
        val.Position = UDim2.new(0, 0, 0, 20)
        val.BackgroundTransparency = 1
        val.Text = valueText
        val.TextColor3 = Theme.TextPrimary
        val.TextSize = 20
        val.Font = Enum.Font.GothamBold
        val.TextXAlignment = Enum.TextXAlignment.Center
        val.Parent = frame
        
        return val
    end
    
    local statTime = createStatValue(statsContainer, "Time Elapsed", "0s", UDim2.new(0, 0, 0, 0))
    local statObjects = createStatValue(statsContainer, "Total Objects", "0", UDim2.new(0.33, 2, 0, 0))
    local statMemory = createStatValue(statsContainer, "Scripts", "0", UDim2.new(0.66, 4, 0, 0))
    
    local actionsCard, actionsContainer = Components.CreateCard(homeScroll, "Quick Actions", "⚡", UDim2.new(1, 0, 0, 160), UDim2.new(0, 0, 0, 100))
    
    local btnStreamDecompile = Components.CreateButton(actionsContainer, "Stream & Decompile", "🚀", 
        Theme.Primary, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0))
    local btnFullGame = Components.CreateButton(actionsContainer, "Decompile Full Game", "🎮", 
        Theme.SurfaceLight, UDim2.new(0.5, -4, 0, 40), UDim2.new(0, 0, 0, 48))
    local btnExport = Components.CreateButton(actionsContainer, "Export (.rbxl)", "💾", 
        Theme.SurfaceLight, UDim2.new(0.5, -4, 0, 40), UDim2.new(0.5, 4, 0, 48))
    local btnTerrain = Components.CreateButton(actionsContainer, "Decompile Terrain", "🌍", 
        Theme.SurfaceLight, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 96))
    
    -- ================================
    -- Progress Section
    -- ================================
    -- ================================
    -- Hook Backend to New Status Bar
    -- ================================
    
    -- Add Percentage Label to Status Bar
    local percentLabel = Instance.new("TextLabel")
    percentLabel.Name = "PercentLabel"
    percentLabel.Size = UDim2.new(0, 40, 1, 0)
    percentLabel.Position = UDim2.new(1, -160, 0, 0) -- Left of progress bar
    percentLabel.BackgroundTransparency = 1
    percentLabel.Text = "0%"
    percentLabel.TextColor3 = Theme.PrimaryHover
    percentLabel.TextSize = 11
    percentLabel.Font = Enum.Font.GothamBold
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentLabel.Parent = statusBarMain
    percentLabel.ZIndex = 5
    
    -- Add Cancel Button to Status Bar
    local cancelBtnSmall = Instance.new("TextButton")
    cancelBtnSmall.Name = "CancelSmall"
    cancelBtnSmall.Size = UDim2.new(0, 20, 0, 20)
    cancelBtnSmall.Position = UDim2.new(1, -25, 0.5, -10) -- Right edge
    cancelBtnSmall.BackgroundColor3 = Theme.Error
    cancelBtnSmall.BackgroundTransparency = 0.2
    cancelBtnSmall.Text = "✕"
    cancelBtnSmall.TextColor3 = Theme.TextPrimary
    cancelBtnSmall.TextSize = 10
    cancelBtnSmall.Font = Enum.Font.GothamBold
    cancelBtnSmall.Parent = statusBarMain
    cancelBtnSmall.ZIndex = 6
    
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 4)
    cancelCorner.Parent = cancelBtnSmall
    
    cancelBtnSmall.MouseButton1Click:Connect(function()
        BaoSaveInstance._cancelRequested = true
        Utility.Log("WARN", "User requested cancel")
    end)
    
    -- Link variables
    BaoSaveInstance._statusLabel = statusText
    BaoSaveInstance._progressLabel = percentLabel
    BaoSaveInstance._progressBar = progressFillMain

    

    
    -- ================================
    -- V2: Live Log Viewer
    -- ================================
    local logSectionLabel = Instance.new("TextLabel")
    logSectionLabel.Name = "LogSectionLabel"
    logSectionLabel.Size = UDim2.new(1, 0, 0, 18)
    logSectionLabel.Position = UDim2.new(0, 0, 0, 510)
    logSectionLabel.BackgroundTransparency = 1
    logSectionLabel.Text = "LIVE LOG"
    logSectionLabel.TextColor3 = Theme.TextMuted
    logSectionLabel.TextSize = 10
    logSectionLabel.Font = Enum.Font.GothamBold
    logSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    logSectionLabel.ZIndex = 3
    logSectionLabel.Parent = mainPanel
    
    local logFrame = Instance.new("ScrollingFrame")
    logFrame.Name = "LogViewer"
    logFrame.Size = UDim2.new(1, 0, 0, 110)
    logFrame.Position = UDim2.new(0, 0, 0, 530)
    logFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
    logFrame.BorderSizePixel = 0
    logFrame.ScrollBarThickness = 4
    logFrame.ScrollBarImageColor3 = Theme.Primary
    logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    logFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logFrame.ZIndex = 3
    logFrame.Parent = mainPanel
    
    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0, 6)
    logCorner.Parent = logFrame
    
    local logStroke = Instance.new("UIStroke")
    logStroke.Color = Theme.Border
    logStroke.Thickness = 1
    logStroke.Transparency = 0.6
    logStroke.Parent = logFrame
    
    local logLayout = Instance.new("UIListLayout")
    logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logLayout.Padding = UDim.new(0, 1)
    logLayout.Parent = logFrame
    
    local logPadding = Instance.new("UIPadding")
    logPadding.PaddingLeft = UDim.new(0, 6)
    logPadding.PaddingRight = UDim.new(0, 6)
    logPadding.PaddingTop = UDim.new(0, 4)
    logPadding.PaddingBottom = UDim.new(0, 4)
    logPadding.Parent = logFrame
    
    local logColors = {
        INFO = Theme.TextSecondary,
        WARN = Theme.Warning,
        ERROR = Theme.Error,
        PERF = Theme.Accent2,
    }
    
    local lastLogCount = 0
    
    -- Forward declarations for circular dependencies
    local showScriptSource
    local preview3DModel
    
    -- ================================
    -- EXPLORER PANEL CONTENT
    -- ================================
    -- ================================
    -- EXPLORER PANEL CONTENT
    -- ================================
    local explorerHeader = Instance.new("Frame")
    explorerHeader.Size = UDim2.new(1, 0, 0, 36)
    explorerHeader.BackgroundTransparency = 1
    explorerHeader.Parent = explorerPanel
    
    local explorerTitle = Instance.new("TextLabel")
    explorerTitle.Size = UDim2.new(0, 150, 1, 0)
    explorerTitle.Position = UDim2.new(0, 0, 0, 0)
    explorerTitle.BackgroundTransparency = 1
    explorerTitle.Text = "📁 Game Explorer"
    explorerTitle.TextColor3 = Theme.TextPrimary
    explorerTitle.TextSize = 14
    explorerTitle.Font = Enum.Font.GothamBold
    explorerTitle.TextXAlignment = Enum.TextXAlignment.Left
    explorerTitle.Parent = explorerHeader
    
    -- Search Bar
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(1, -160, 0, 26)
    searchFrame.Position = UDim2.new(0, 160, 0.5, -13)
    searchFrame.BackgroundColor3 = Theme.Surface
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = explorerHeader
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 6)
    searchCorner.Parent = searchFrame
    
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -10, 1, 0)
    searchBox.Position = UDim2.new(0, 5, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search instances..."
    searchBox.PlaceholderColor3 = Theme.TextMuted
    searchBox.TextColor3 = Theme.TextPrimary
    searchBox.TextSize = 12
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Parent = searchFrame
    
    local explorerScroll = Instance.new("ScrollingFrame")
    explorerScroll.Name = "ExplorerTree"
    explorerScroll.Size = UDim2.new(1, 0, 1, -40)
    explorerScroll.Position = UDim2.new(0, 0, 0, 40)
    explorerScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
    explorerScroll.BorderSizePixel = 0
    explorerScroll.ScrollBarThickness = 5
    explorerScroll.ScrollBarImageColor3 = Theme.Primary
    explorerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    explorerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    explorerScroll.ZIndex = 3
    explorerScroll.Parent = explorerPanel
    
    local explorerScrollCorner = Instance.new("UICorner")
    explorerScrollCorner.CornerRadius = UDim.new(0, 6)
    explorerScrollCorner.Parent = explorerScroll
    
    local explorerScrollStroke = Instance.new("UIStroke")
    explorerScrollStroke.Color = Theme.Border
    explorerScrollStroke.Thickness = 1
    explorerScrollStroke.Transparency = 0.5
    explorerScrollStroke.Parent = explorerScroll
    
    local explorerLayout = Instance.new("UIListLayout")
    explorerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    explorerLayout.Padding = UDim.new(0, 1)
    explorerLayout.Parent = explorerScroll
    
    -- Class icons for Explorer
    local classIcons = {
        Folder = "📁", Script = "📝", LocalScript = "📜", ModuleScript = "📦",
        Part = "🧱", MeshPart = "🔷", UnionOperation = "🔶", Model = "📐",
        SpawnLocation = "🏁", Camera = "📷", Attachment = "📌",
        PointLight = "💡", SpotLight = "🔦", SurfaceLight = "☀️",
        Sound = "🔊", ParticleEmitter = "✨", Fire = "🔥", Smoke = "💨",
        Decal = "🖼️", Texture = "🎨", SurfaceAppearance = "🎭",
        Humanoid = "🧑", HumanoidRootPart = "🦴",
        ScreenGui = "🖥️", Frame = "⬜", TextLabel = "📋", TextButton = "🔘",
        ImageLabel = "🖼️", ImageButton = "🖱️", ScrollingFrame = "📜",
        Terrain = "🌍", Workspace = "🌐",
        ReplicatedStorage = "📦", ServerStorage = "🗄️", ServerScriptService = "⚙️",
        StarterGui = "🖥️", StarterPack = "🎒", Players = "👥",
        Lighting = "☀️", SoundService = "🔈",
    }
    
    local function getClassIcon(className)
        return classIcons[className] or "⬜"
    end
    
    local expandedNodes = {}  -- Track expanded states
    local searchTerm = ""
    
    local function buildExplorerRow(instance, depth, layoutOrder, isMatch)
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 22)
        row.BackgroundColor3 = isMatch and Theme.Primary or Theme.Surface
        row.BackgroundTransparency = isMatch and 0.2 or 0.6 -- Fade background
        row.BorderSizePixel = 0
        row.Text = ""
        row.AutoButtonColor = false
        row.ZIndex = 4
        row.LayoutOrder = layoutOrder
        row.Parent = explorerScroll
        
        local className = "Unknown"
        local instName = "?"
        local childCount = 0
        pcall(function() className = instance.ClassName end)
        pcall(function() instName = instance.Name end)
        pcall(function() childCount = #instance:GetChildren() end)
        
        local indent = depth * 16
        local icon = getClassIcon(className)
        local arrow = (childCount > 0 and not isMatch) and "▶ " or "   "
        if expandedNodes[instance] then arrow = "▼ " end
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -indent - 8, 1, 0)
        label.Position = UDim2.new(0, indent + 4, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = arrow .. icon .. " " .. instName .. "  (" .. className .. ")"
        label.TextColor3 = isMatch and Color3.new(1,1,1) or Theme.TextPrimary
        label.TextSize = 11
        label.Font = Enum.Font.Code
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.ZIndex = 5
        label.Parent = row
        
        -- Hover effect
        row.MouseEnter:Connect(function()
            row.BackgroundTransparency = 0.4
        end)
        row.MouseLeave:Connect(function()
            row.BackgroundTransparency = isMatch and 0.2 or 0.6
        end)
        
        -- Click
        row.MouseButton1Click:Connect(function()
            -- View file logic
            if instance:IsA("LuaSourceContainer") then
                switchTab(3)
                task.spawn(function() showScriptSource(instance) end)
                return
            end
            if instance:IsA("BasePart") or instance:IsA("Model") then
                switchTab(4)
                task.spawn(function() preview3DModel(instance) end)
                return
            end
            
        -- Expand/Collapse
            if childCount > 0 then
                if expandedNodes[instance] then
                    expandedNodes[instance] = nil
                else
                    expandedNodes[instance] = true
                end
                refreshExplorer()
            end
        end)
        
        -- Context Menu (Right Click)
        row.MouseButton2Click:Connect(function()
            if _G.ContextMenu then _G.ContextMenu:Destroy() end
            
            local cMenu = Instance.new("Frame")
            cMenu.Name = "ContextMenu"
            cMenu.Size = UDim2.new(0, 160, 0, 90)
            local mousePos = UserInputService:GetMouseLocation()
            cMenu.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y - 40)
            cMenu.BackgroundColor3 = Theme.Surface
            cMenu.BorderSizePixel = 0
            cMenu.ZIndex = 100
            cMenu.Parent = mainFrame
            _G.ContextMenu = cMenu
            
            Instance.new("UICorner", cMenu).CornerRadius = UDim.new(0, 6)
            local mStroke = Instance.new("UIStroke")
            mStroke.Color = Theme.Border
            mStroke.Parent = cMenu
            
            local mLayout = Instance.new("UIListLayout")
            mLayout.Padding = UDim.new(0, 2)
            mLayout.Parent = cMenu
            
            local function addCtxBtn(txt, callback)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 28)
                btn.BackgroundTransparency = 1
                btn.Text = "  " .. txt
                btn.TextColor3 = Theme.TextSecondary
                btn.TextSize = 12
                btn.Font = Enum.Font.GothamMedium
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.ZIndex = 101
                btn.Parent = cMenu
                
                btn.MouseEnter:Connect(function()
                    btn.BackgroundTransparency = 0.8
                    btn.BackgroundColor3 = Theme.SurfaceLight
                    btn.TextColor3 = Theme.TextPrimary
                end)
                btn.MouseLeave:Connect(function()
                    btn.BackgroundTransparency = 1
                    btn.TextColor3 = Theme.TextSecondary
                end)
                btn.MouseButton1Click:Connect(function()
                    cMenu:Destroy()
                    callback()
                end)
            end
            
            addCtxBtn("💾 Save this Instance", function()
                Utility.Log("INFO", "Saving: " .. instName)
                -- Hook to save specific instance
            end)
            addCtxBtn("📋 Copy Name", function()
                setclipboard(instName)
                Utility.Log("INFO", "Copied name to clipboard.")
            end)
            addCtxBtn("📂 Copy Path", function()
                setclipboard(instance:GetFullName())
                Utility.Log("INFO", "Copied path to clipboard.")
            end)
            
            -- Close menu when clicking outside
            task.spawn(function()
                local conn
                conn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                        -- Check if click is inside cMenu
                        local pos = input.Position
                        local ax, ay = cMenu.AbsolutePosition.X, cMenu.AbsolutePosition.Y
                        local asx, asy = cMenu.AbsoluteSize.X, cMenu.AbsoluteSize.Y
                        if pos.X < ax or pos.X > ax + asx or pos.Y < ay or pos.Y > ay + asy then
                            cMenu:Destroy()
                            conn:Disconnect()
                        end
                    end
                end)
            end)
        end)
        
        return row
    end
    
    local function refreshExplorer()
        -- Clear
        for _, c in ipairs(explorerScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        
        local order = 0
        
        -- If searching, flat list of matches
        if searchTerm and #searchTerm > 2 then
            local matches = {}
            local function search(parent)
                for _, child in ipairs(parent:GetChildren()) do
                    if not Utility.IsProtected(child) then
                        if child.Name:lower():find(searchTerm:lower()) then
                            table.insert(matches, child)
                        end
                        -- Limit search depth/count
                        if #matches < 50 then
                            search(child)
                        end
                    end
                end
            end
            search(game)
            
            for _, m in ipairs(matches) do
                order = order + 1
                buildExplorerRow(m, 0, order, true)
            end
            return
        end
        
        -- Normal Tree View
        local function buildTree(instance, depth)
            if depth > 10 then return end
            order = order + 1
            buildExplorerRow(instance, depth, order, false)
            
            if expandedNodes[instance] then
                local children = instance:GetChildren()
                table.sort(children, function(a,b) return a.Name < b.Name end)
                for _, child in ipairs(children) do
                    if not Utility.IsProtected(child) then
                        buildTree(child, depth + 1)
                    end
                end
            end
        end
        
        pcall(function()
            local services = game:GetChildren()
            table.sort(services, function(a,b) return a.Name < b.Name end)
            for _, svc in ipairs(services) do
                buildTree(svc, 0)
            end
        end)
    end
    
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchTerm = searchBox.Text
        refreshExplorer()
    end)
    
    -- Initial Load
    task.delay(1, refreshExplorer)

    
    -- ================================
    -- SCRIPT VIEWER PANEL CONTENT (V3 Tabbed)
    -- ================================
    local scriptHeader = Instance.new("Frame")
    scriptHeader.Size = UDim2.new(1, 0, 0, 36)
    scriptHeader.BackgroundTransparency = 1
    scriptHeader.Parent = scriptPanel
    
    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Size = UDim2.new(1, -90, 1, 0)
    tabBar.BackgroundTransparency = 1
    tabBar.ScrollBarThickness = 0
    tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabBar.Parent = scriptHeader
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = tabBar
    
    local copyScriptBtn = Instance.new("TextButton")
    copyScriptBtn.Size = UDim2.new(0, 80, 0, 24)
    copyScriptBtn.Position = UDim2.new(1, -80, 0.5, -12)
    copyScriptBtn.BackgroundColor3 = Theme.Surface
    copyScriptBtn.Text = "Copy All"
    copyScriptBtn.TextColor3 = Theme.TextSecondary
    copyScriptBtn.TextSize = 11
    copyScriptBtn.Font = Enum.Font.GothamBold
    copyScriptBtn.Parent = scriptHeader
    Instance.new("UICorner", copyScriptBtn).CornerRadius = UDim.new(0, 4)
    
    local scriptContainer = Instance.new("Frame")
    scriptContainer.Size = UDim2.new(1, 0, 1, -40)
    scriptContainer.Position = UDim2.new(0, 0, 0, 40)
    scriptContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    scriptContainer.BorderSizePixel = 0
    scriptContainer.Parent = scriptPanel
    Instance.new("UICorner", scriptContainer).CornerRadius = UDim.new(0, 6)
    
    local scriptHolder = Instance.new("Frame")
    scriptHolder.Size = UDim2.new(1, 0, 1, 0)
    scriptHolder.BackgroundTransparency = 1
    scriptHolder.ClipsDescendants = true
    scriptHolder.Parent = scriptContainer
    
    local openScripts = {}
    local activeScript = nil
    
    copyScriptBtn.MouseButton1Click:Connect(function()
        if activeScript and openScripts[activeScript] then
            if setclipboard then
                setclipboard(openScripts[activeScript].Source)
                copyScriptBtn.Text = "Copied!"
                task.delay(1, function() copyScriptBtn.Text = "Copy All" end)
            else
                copyScriptBtn.Text = "No Clipboard"
            end
        end
    end)
    
    -- Syntax Highlighting V2
    local syntaxColors = {
        keyword  = Color3.fromRGB(249, 105, 142), -- Pink
        string   = Color3.fromRGB(253, 221, 146), -- Yellow
        comment  = Color3.fromRGB(120, 130, 150), -- Gray
        number   = Color3.fromRGB(150, 220, 255), -- Light Blue
        builtin  = Color3.fromRGB(80, 200, 255),  -- Cyan
        method   = Color3.fromRGB(220, 220, 170), -- Pale Yellow
        normal   = Color3.fromRGB(230, 230, 230), -- White
    }
    
    local function highlightLine(line)
        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1, -34, 1, 0)
        frame.Position = UDim2.new(0, 34, 0, 0)
        
        -- Default simple coloring for performance (RichText can be slow for large scripts)
        local code = Instance.new("TextLabel")
        code.Size = UDim2.new(1, 0, 1, 0)
        code.BackgroundTransparency = 1
        code.Text = line
        code.TextSize = 12
        code.Font = Enum.Font.Code
        code.TextXAlignment = Enum.TextXAlignment.Left
        code.TextTruncate = Enum.TextTruncate.AtEnd
        code.Parent = frame
        
        -- Very basic regex highlight for V2 speed
        if line:match("^%s*%-%-") then
            code.TextColor3 = syntaxColors.comment
        elseif line:match('^%s*".-"$') or line:match("^%s*'.*'$") then
            code.TextColor3 = syntaxColors.string
        else
            local first = line:match("^%s*(%a+)")
            if first and (first == "local" or first == "function" or first == "if" or first == "end" or first == "return" or first == "for" or first == "while" or first == "then" or first == "else" or first == "do") then
                code.TextColor3 = syntaxColors.keyword
            else
                code.TextColor3 = syntaxColors.normal
            end
        end
        return frame
    end
    
    local function activateTab(scriptInstance)
        if not openScripts[scriptInstance] then return end
        activeScript = scriptInstance
        
        for inst, data in pairs(openScripts) do
            if inst == scriptInstance then
                data.Tab.BackgroundColor3 = Theme.Primary
                data.Tab.TextColor3 = Color3.new(1,1,1)
                data.Viewer.Visible = true
            else
                data.Tab.BackgroundColor3 = Theme.Surface
                data.Tab.TextColor3 = Theme.TextSecondary
                data.Viewer.Visible = false
            end
        end
    end
    
    local function closeTab(scriptInstance)
        if not openScripts[scriptInstance] then return end
        openScripts[scriptInstance].Tab:Destroy()
        openScripts[scriptInstance].Viewer:Destroy()
        openScripts[scriptInstance] = nil
        
        if activeScript == scriptInstance then
            activeScript = nil
            -- Activate another tab if possible
            local nextInst, _ = next(openScripts)
            if nextInst then activateTab(nextInst) end
        end
    end
    
    function showScriptSource(scriptInstance)
        if openScripts[scriptInstance] then
            activateTab(scriptInstance)
            return
        end
        
        -- Create Tab Bubble
        local tab = Instance.new("TextButton")
        tab.Size = UDim2.new(0, 120, 1, 0)
        tab.BackgroundColor3 = Theme.Surface
        tab.Text = " " .. scriptInstance.Name
        tab.TextColor3 = Theme.TextSecondary
        tab.TextSize = 12
        tab.Font = Enum.Font.GothamMedium
        tab.TextXAlignment = Enum.TextXAlignment.Left
        tab.TextTruncate = Enum.TextTruncate.AtEnd
        tab.AutoButtonColor = false
        tab.Parent = tabBar
        Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 6)
        
        local closeT = Instance.new("TextButton")
        closeT.Size = UDim2.new(0, 20, 0, 20)
        closeT.Position = UDim2.new(1, -25, 0.5, -10)
        closeT.BackgroundTransparency = 1
        closeT.Text = "✕"
        closeT.TextColor3 = Theme.TextMuted
        closeT.TextSize = 10
        closeT.Font = Enum.Font.GothamBold
        closeT.Parent = tab
        
        closeT.MouseButton1Click:Connect(function() closeTab(scriptInstance) end)
        tab.MouseButton1Click:Connect(function() activateTab(scriptInstance) end)
        
        -- Create Viewer
        local viewer = Instance.new("ScrollingFrame")
        viewer.Size = UDim2.new(1, 0, 1, 0)
        viewer.BackgroundTransparency = 1
        viewer.ScrollBarThickness = 5
        viewer.ScrollBarImageColor3 = Theme.Primary
        viewer.CanvasSize = UDim2.new(0, 0, 0, 0)
        viewer.AutomaticCanvasSize = Enum.AutomaticSize.Y
        viewer.Visible = false
        viewer.Parent = scriptHolder
        
        local vLayout = Instance.new("UIListLayout")
        vLayout.SortOrder = Enum.SortOrder.LayoutOrder
        vLayout.Parent = viewer
        
        Instance.new("UIPadding", viewer).PaddingLeft = UDim.new(0, 4)
        
        local src = "-- Loading..."
        openScripts[scriptInstance] = { Tab = tab, Viewer = viewer, Source = src }
        activateTab(scriptInstance)
        
        task.spawn(function()
            src = BaoSaveInstance._CollectScriptSource(scriptInstance)
            if not src then src = "-- Failed to decompile" end
            openScripts[scriptInstance].Source = src
            
            local i = 0
            for line in (src.."\n"):gmatch("([^\n]*)\n") do
                i = i + 1
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 16)
                row.BackgroundTransparency = 1
                row.LayoutOrder = i
                row.Parent = viewer
                
                local num = Instance.new("TextLabel")
                num.Size = UDim2.new(0, 30, 1, 0)
                num.BackgroundTransparency = 1
                num.Text = tostring(i)
                num.TextColor3 = Theme.TextMuted
                num.TextSize = 10
                num.Font = Enum.Font.Code
                num.TextXAlignment = Enum.TextXAlignment.Right
                num.Parent = row
                
                local hl = highlightLine(line)
                hl.Parent = row
                
                if i % 100 == 0 then task.wait() end
            end
        end)
    end
    
    -- ================================
    -- 3D MODEL VIEWER PANEL CONTENT
    -- ================================
    -- ================================
    -- 3D MODEL VIEWER PANEL CONTENT
    -- ================================
    local model3DHeader = Instance.new("Frame")
    model3DHeader.Size = UDim2.new(1, 0, 0, 30)
    model3DHeader.BackgroundTransparency = 1
    model3DHeader.Parent = model3DPanel
    
    local model3DTitle = Instance.new("TextLabel")
    model3DTitle.Size = UDim2.new(1, -200, 1, 0)
    model3DTitle.BackgroundTransparency = 1
    model3DTitle.Text = "🎨 Select a Model/Part to view"
    model3DTitle.TextColor3 = Theme.TextPrimary
    model3DTitle.TextSize = 12
    model3DTitle.Font = Enum.Font.GothamBold
    model3DTitle.Parent = model3DHeader
    
    local wireframeBtn = Components.CreateButton(model3DHeader, "Wireframe", "🕸️", Theme.SurfaceLight, UDim2.new(0, 100, 0, 24), UDim2.new(1, -110, 0.5, -12))
    local gridBtn = Components.CreateButton(model3DHeader, "Grid", "⬛", Theme.SurfaceLight, UDim2.new(0, 80, 0, 24), UDim2.new(1, -200, 0.5, -12))
    
    local vpContainer = Instance.new("Frame")
    vpContainer.Size = UDim2.new(1, 0, 1, -30)
    vpContainer.Position = UDim2.new(0, 0, 0, 30)
    vpContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    vpContainer.BorderSizePixel = 0
    vpContainer.Parent = model3DPanel
    Instance.new("UICorner", vpContainer).CornerRadius = UDim.new(0, 6)
    
    local viewportFrame = Instance.new("ViewportFrame")
    viewportFrame.Size = UDim2.new(1, 0, 1, 0)
    viewportFrame.BackgroundTransparency = 1
    viewportFrame.Parent = vpContainer
    
    local vpCamera = Instance.new("Camera")
    viewportFrame.CurrentCamera = vpCamera
    vpCamera.Parent = viewportFrame
    
    -- Controls Info
    local controlsLabel = Instance.new("TextLabel")
    controlsLabel.Size = UDim2.new(1, 0, 0, 20)
    controlsLabel.Position = UDim2.new(0, 0, 1, -20)
    controlsLabel.BackgroundTransparency = 0.5
    controlsLabel.BackgroundColor3 = Color3.new(0,0,0)
    controlsLabel.Text = "Drag to Rotate • Scroll to Zoom • Right-Click Pan"
    controlsLabel.TextColor3 = Color3.new(1,1,1)
    controlsLabel.TextSize = 10
    controlsLabel.Parent = vpContainer
    
    -- 3D Logic Variables
    local currentModel = nil
    local camAngleX = 0
    local camAngleY = 0
    local camDist = 10
    local camPan = Vector3.new(0,0,0)
    local draggingVP = false
    local panningVP = false
    local lastMouse = Vector2.new()
    local wireframeEnabled = false
    local gridEnabled = true
    
    vpContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingVP = true
            lastMouse = input.Position
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            panningVP = true
            lastMouse = input.Position
        end
    end)
    
    vpContainer.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingVP = false end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then panningVP = false end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if draggingVP and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - lastMouse
            lastMouse = input.Position
            camAngleX = camAngleX - delta.X * 0.01
            camAngleY = math.clamp(camAngleY - delta.Y * 0.01, -1.5, 1.5)
        elseif panningVP and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - lastMouse
            lastMouse = input.Position
            -- Pan logic relative to camera is complex, simplest approach is adjusting center
            local right = CFrame.Angles(0, camAngleX, 0).RightVector
            local up = CFrame.Angles(0, camAngleX, 0).UpVector
            camPan = camPan + (-right * delta.X * 0.05) + (up * delta.Y * 0.05)
        elseif input.UserInputType == Enum.UserInputType.MouseWheel then
            if model3DPanel.Visible then
                camDist = math.clamp(camDist - input.Position.Z * 2, 2, 500)
            end
        end
    end)
    
    -- Render Loop for 3D Camera
    task.spawn(function()
        while screenGui and screenGui.Parent do
            if model3DPanel.Visible and currentModel then
                local center = Vector3.new(0,0,0)
                if currentModel:IsA("Model") and currentModel.PrimaryPart then
                    center = currentModel.PrimaryPart.Position
                elseif currentModel:IsA("BasePart") then
                    center = currentModel.Position
                end
                
                center = center + camPan
                local cf = CFrame.new(center) 
                    * CFrame.Angles(0, camAngleX, 0) 
                    * CFrame.Angles(camAngleY, 0, 0) 
                    * CFrame.new(0, 0, camDist)
                vpCamera.CFrame = cf
            end
            task.wait(0.01)
        end
    end)
    
    local function applyWireframe(model, enabled)
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("BasePart") then
                if enabled then
                    local hl = Instance.new("SelectionBox")
                    hl.Name = "WireHL"
                    hl.Adornee = desc
                    hl.LineThickness = 0.05
                    hl.Color3 = Theme.Primary
                    hl.SurfaceTransparency = 1
                    hl.Parent = desc
                    desc.Transparency = 0.8
                else
                    if desc:FindFirstChild("WireHL") then desc.WireHL:Destroy() end
                    desc.Transparency = desc:GetAttribute("OrigTrans") or 0
                end
            end
        end
    end
    
    wireframeBtn.MouseButton1Click:Connect(function()
        wireframeEnabled = not wireframeEnabled
        wireframeBtn.BackgroundColor3 = wireframeEnabled and Theme.Primary or Theme.SurfaceLight
        if currentModel then applyWireframe(currentModel, wireframeEnabled) end
    end)
    
    gridBtn.MouseButton1Click:Connect(function()
        gridEnabled = not gridEnabled
        gridBtn.BackgroundColor3 = gridEnabled and Theme.Primary or Theme.SurfaceLight
        local grid = viewportFrame:FindFirstChild("BaseGrid")
        if grid then grid.Visible = gridEnabled end
    end)
    
    function preview3DModel(instance)
        viewportFrame:ClearAllChildren()
        model3DTitle.Text = "🎨 " .. instance.Name
        camPan = Vector3.new(0,0,0)
        
        local clone = nil
        pcall(function() clone = instance:Clone() end)
        
        if not clone then
            model3DTitle.Text = "🎨 Failed to clone: " .. instance.Name
            return
        end
        
        -- Save original transparency for wireframe toggle
        for _, desc in ipairs(clone:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc:SetAttribute("OrigTrans", desc.Transparency)
            end
        end
        if clone:IsA("BasePart") then clone:SetAttribute("OrigTrans", clone.Transparency) end
        
        clone.Parent = viewportFrame
        
        local center = Vector3.new(0,0,0)
        local size = Vector3.new(4,4,4)
        if clone:IsA("Model") then
             local cf, sz = clone:GetBoundingBox()
             center = cf.Position
             size = sz
        elseif clone:IsA("BasePart") then
             center = clone.Position
             size = clone.Size
        end
        
        -- Create Base Grid
        local grid = Instance.new("Part")
        grid.Name = "BaseGrid"
        grid.Size = UDim2.new(0, 100, 0, 100)
        grid.Size = Vector3.new(100, 0.1, 100)
        grid.Position = Vector3.new(center.X, center.Y - size.Y/2 - 0.5, center.Z)
        grid.Anchored = true
        grid.Transparency = 0.8
        grid.BrickColor = BrickColor.new("Institutional white")
        grid.Material = Enum.Material.ForceField
        grid.Visible = gridEnabled
        grid.Parent = viewportFrame
        
        currentModel = clone
        camDist = math.max(size.Magnitude * 1.5, 5)
        camAngleX = 0
        camAngleY = -0.3
        
        applyWireframe(currentModel, wireframeEnabled)
        gridBtn.BackgroundColor3 = gridEnabled and Theme.Primary or Theme.SurfaceLight
    end
    
    -- ================================
    -- LOGIC: Auto-Build Explorer
    -- ================================
    local explorerBuilt = false
    local origSwitchTab = switchTab -- Save strict ref
    
    navButtons[2].Button.MouseButton1Click:Connect(function()
        if not explorerBuilt then
            explorerBuilt = true
            task.spawn(refreshExplorer)
        end
    end)
    
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
        
        BaoSaveInstance._statusLabel.Text = icon .. " " .. status
        
        TweenService:Create(BaoSaveInstance._statusLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            TextColor3 = color
        }):Play()
        
        -- Update progress bar color based on status
        if status == "Done" then
            TweenService:Create(BaoSaveInstance._progressBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
                BackgroundColor3 = Theme.Success
            }):Play()
        elseif status == "Error" then
            TweenService:Create(BaoSaveInstance._progressBar, TweenInfo.new(0.3), {
                BackgroundColor3 = Theme.Error
            }):Play()
        else
            TweenService:Create(BaoSaveInstance._progressBar, TweenInfo.new(0.3), {
                BackgroundColor3 = Theme.ProgressFill
            }):Play()
        end
        
        -- V2: Show/hide cancel button
        cancelBtn.Visible = (status == "Processing" or status == "Exporting")
        if cancelBtn.Visible then
            cancelBtn.Text = "⛔  Cancel Operation"
            cancelBtn.Active = true
        end
    end
    
    local function updateProgress(percent)
        local clampedPercent = math.clamp(percent, 0, 100)
        
        TweenService:Create(BaoSaveInstance._progressBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(clampedPercent / 100, 0, 1, 0)
        }):Play()
        
        BaoSaveInstance._progressLabel.Text = math.floor(clampedPercent) .. "%"
        
        if clampedPercent >= 100 then
            TweenService:Create(BaoSaveInstance._progressLabel, TweenInfo.new(0.3), {
                TextColor3 = Theme.Success
            }):Play()
        else
            TweenService:Create(BaoSaveInstance._progressLabel, TweenInfo.new(0.3), {
                TextColor3 = Theme.Primary
            }):Play()
        end
    end
    
    local function setButtonsEnabled(enabled)
        -- We need references to buttons. They were local to Main Panel creation.
        -- But this scope is still UIBuilder.Create, so they SHOULD be accessible if defined earlier.
        -- Yes, they were defined in previous logic block.
        local alpha = enabled and 1 or 0.5
        for _, btn in ipairs({btnStreamDecompile, btnFullGame, btnFullModel, btnTerrain, btnExport}) do
            if btn then
                btn.Active = enabled
                TweenService:Create(btn, TweenInfo.new(0.2), {
                    BackgroundTransparency = enabled and 0 or 0.4
                }):Play()
            end
        end
    end
    
    local function updateModeLabel(text)
       BaoSaveInstance._statusLabel.Text = text
    end
    
    -- ================================
    -- Shine Animation Loop
    -- ================================
    task.spawn(function()
        while screenGui and screenGui.Parent do
             -- We skip shine for now or find it via FindFirstChild.
             task.wait(1)
        end
    end)
    
    -- ================================
    -- V2: Log Viewer Update Loop
    -- ================================
    task.spawn(function()
        while screenGui and screenGui.Parent do
            local logs = Utility.Logs
            if #logs > lastLogCount then
                for i = lastLogCount + 1, math.min(#logs, lastLogCount + 10) do
                    local entry = logs[i]
                    if logFrame then -- Ensure logFrame exists
                        local logLabel = Instance.new("TextLabel")
                        logLabel.Size = UDim2.new(1, 0, 0, 13)
                        logLabel.BackgroundTransparency = 1
                        logLabel.Text = string.format("[%.1f] [%s] %s", entry.Time, entry.Level, entry.Message)
                        logLabel.TextColor3 = logColors[entry.Level] or Theme.TextMuted
                        logLabel.TextSize = 9
                        logLabel.Font = Enum.Font.Code
                        logLabel.TextXAlignment = Enum.TextXAlignment.Left
                        logLabel.TextTruncate = Enum.TextTruncate.AtEnd
                        logLabel.LayoutOrder = i
                        logLabel.Parent = logFrame
                    end
                end
                lastLogCount = #logs
                if logFrame then
                    logFrame.CanvasPosition = Vector2.new(0, logFrame.AbsoluteCanvasSize.Y)
                end
            end
            task.wait(0.3)
        end
    end)
    
    -- ================================
    -- TOAST NOTIFICATION SYSTEM V3
    -- ================================
    local toastContainer = Instance.new("Frame")
    toastContainer.Name = "ToastContainer"
    toastContainer.Size = UDim2.new(0, 300, 1, -20)
    toastContainer.Position = UDim2.new(1, -320, 0, 10)
    toastContainer.BackgroundTransparency = 1
    toastContainer.ZIndex = 1000
    toastContainer.Parent = screenGui
    
    local toastLayout = Instance.new("UIListLayout")
    toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
    toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    toastLayout.Padding = UDim.new(0, 8)
    toastLayout.Parent = toastContainer
    
    local toastCount = 0
    function BaoSaveInstance.Notify(title, text, typeStr, duration)
        duration = duration or 3
        local color = Theme.Primary
        if typeStr == "Success" then color = Theme.Success
        elseif typeStr == "Error" then color = Theme.Error
        elseif typeStr == "Warning" then color = Theme.Warning end
        
        local toast = Instance.new("Frame")
        toast.Size = UDim2.new(0, 280, 0, 60)
        toast.BackgroundColor3 = Theme.Surface
        toast.BackgroundTransparency = 1
        toast.ZIndex = 1001
        toast.Parent = toastContainer
        
        toastCount = toastCount + 1
        toast.LayoutOrder = toastCount
        
        Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 6)
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = color
        stroke.Thickness = 1
        stroke.Transparency = 1
        stroke.Parent = toast
        
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 4, 1, -12)
        bar.Position = UDim2.new(0, 6, 0, 6)
        bar.BackgroundColor3 = color
        bar.BorderSizePixel = 0
        bar.BackgroundTransparency = 1
        bar.ZIndex = 1002
        bar.Parent = toast
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)
        
        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -24, 0, 20)
        tLabel.Position = UDim2.new(0, 16, 0, 8)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = title
        tLabel.TextColor3 = Theme.TextPrimary
        tLabel.TextTransparency = 1
        tLabel.TextSize = 13
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.ZIndex = 1002
        tLabel.Parent = toast
        
        local msgLabel = Instance.new("TextLabel")
        msgLabel.Size = UDim2.new(1, -24, 0, 26)
        msgLabel.Position = UDim2.new(0, 16, 0, 28)
        msgLabel.BackgroundTransparency = 1
        msgLabel.Text = text
        msgLabel.TextColor3 = Theme.TextSecondary
        msgLabel.TextTransparency = 1
        msgLabel.TextSize = 11
        msgLabel.Font = Enum.Font.Gotham
        msgLabel.TextXAlignment = Enum.TextXAlignment.Left
        msgLabel.TextYAlignment = Enum.TextYAlignment.Top
        msgLabel.TextWrapped = true
        msgLabel.ZIndex = 1002
        msgLabel.Parent = toast
        
        -- Animate In
        TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 0.5 }):Play()
        TweenService:Create(bar, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
        TweenService:Create(tLabel, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
        TweenService:Create(msgLabel, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
        
        task.delay(duration, function()
            -- Animate Out
            TweenService:Create(toast, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(stroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
            TweenService:Create(bar, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(tLabel, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            TweenService:Create(msgLabel, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            task.wait(0.3)
            toast:Destroy()
        end)
    end
    
    -- ================================
    -- COMMAND PALETTE V3 (Ctrl+P)
    -- ================================
    local cpOverlay = Instance.new("Frame")
    cpOverlay.Size = UDim2.new(1, 0, 1, 0)
    cpOverlay.BackgroundColor3 = Color3.new(0,0,0)
    cpOverlay.BackgroundTransparency = 1
    cpOverlay.ZIndex = 2000
    cpOverlay.Visible = false
    cpOverlay.Parent = screenGui
    
    local cpFrame = Instance.new("Frame")
    cpFrame.Size = UDim2.new(0, 500, 0, 50)
    cpFrame.Position = UDim2.new(0.5, -250, 0.2, 0)
    cpFrame.BackgroundColor3 = Theme.Background
    cpFrame.ZIndex = 2001
    cpFrame.ClipsDescendants = true
    cpFrame.Parent = cpOverlay
    Instance.new("UICorner", cpFrame).CornerRadius = UDim.new(0, 8)
    
    local cpStroke = Instance.new("UIStroke")
    cpStroke.Color = Theme.Primary
    cpStroke.Thickness = 1
    cpStroke.Parent = cpFrame
    
    local cpInput = Instance.new("TextBox")
    cpInput.Size = UDim2.new(1, -40, 0, 50)
    cpInput.Position = UDim2.new(0, 40, 0, 0)
    cpInput.BackgroundTransparency = 1
    cpInput.Text = ""
    cpInput.PlaceholderText = "Type a command... (e.g. Export, Settings)"
    cpInput.TextColor3 = Theme.TextPrimary
    cpInput.PlaceholderColor3 = Theme.TextMuted
    cpInput.TextSize = 16
    cpInput.Font = Enum.Font.GothamMedium
    cpInput.TextXAlignment = Enum.TextXAlignment.Left
    cpInput.ZIndex = 2002
    cpInput.ClearTextOnFocus = false
    cpInput.Parent = cpFrame
    
    local cpIcon = Instance.new("TextLabel")
    cpIcon.Size = UDim2.new(0, 40, 0, 50)
    cpIcon.BackgroundTransparency = 1
    cpIcon.Text = "⚡"
    cpIcon.TextColor3 = Theme.Primary
    cpIcon.TextSize = 18
    cpIcon.ZIndex = 2002
    cpIcon.Parent = cpFrame
    
    local cpResults = Instance.new("ScrollingFrame")
    cpResults.Size = UDim2.new(1, 0, 1, -50)
    cpResults.Position = UDim2.new(0, 0, 0, 50)
    cpResults.BackgroundTransparency = 1
    cpResults.ScrollBarThickness = 2
    cpResults.ZIndex = 2002
    cpResults.Parent = cpFrame
    local cpLayout = Instance.new("UIListLayout")
    cpLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cpLayout.Parent = cpResults
    
    local commands = {
        { name = "Go to Home", action = function() switchTab(1) end },
        { name = "Go to Explorer", action = function() switchTab(2) end },
        { name = "Go to Script Hub", action = function() switchTab(3) end },
        { name = "Go to 3D Viewer", action = function() switchTab(4) end },
        { name = "Go to Settings", action = function() switchTab(5) end },
        { name = "Decompile Full Game", action = function() handleDecompile("FullGame") end },
        { name = "Decompile Terrain", action = function() handleDecompile("Terrain") end },
        { name = "Export Place (.rbxl)", action = function() btnExport.MouseButton1Click:Fire() end }
    }
    
    local cpOpen = false
    local function toggleCommandPalette()
        cpOpen = not cpOpen
        if cpOpen then
            cpOverlay.Visible = true
            cpInput.Text = ""
            cpInput:CaptureFocus()
            TweenService:Create(cpOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
            TweenService:Create(cpFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 50)}):Play()
        else
            TweenService:Create(cpOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            local tw = TweenService:Create(cpFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 500, 0, 50)})
            tw:Play()
            tw.Completed:Connect(function() if not cpOpen then cpOverlay.Visible = false end end)
        end
    end
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if input.KeyCode == Enum.KeyCode.P and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            toggleCommandPalette()
        elseif input.KeyCode == Enum.KeyCode.Escape and cpOpen then
            toggleCommandPalette()
        end
    end)
    
    cpInput:GetPropertyChangedSignal("Text"):Connect(function()
        for _, c in ipairs(cpResults:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        local txt = cpInput.Text:lower()
        local matches = 0
        
        for _, cmd in ipairs(commands) do
            if txt == "" or cmd.name:lower():find(txt, 1, true) then
                matches = matches + 1
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 36)
                btn.BackgroundColor3 = Theme.Surface
                btn.BackgroundTransparency = 1
                btn.Text = "   " .. cmd.name
                btn.TextColor3 = Theme.TextSecondary
                btn.TextSize = 13
                btn.Font = Enum.Font.GothamMedium
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.ZIndex = 2003
                btn.Parent = cpResults
                
                btn.MouseEnter:Connect(function()
                    btn.BackgroundTransparency = 0
                    btn.TextColor3 = Theme.TextPrimary
                end)
                btn.MouseLeave:Connect(function()
                    btn.BackgroundTransparency = 1
                    btn.TextColor3 = Theme.TextSecondary
                end)
                btn.MouseButton1Click:Connect(function()
                    toggleCommandPalette()
                    cmd.action()
                end)
            end
        end
        
        local h = 50 + math.min(matches * 36, 200)
        TweenService:Create(cpFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 500, 0, h)}):Play()
    end)
    
    -- Return to normal API Registering
    -- ================================
    -- Register API Callbacks
    -- ================================
    BaoSaveInstance._callbacks.OnStatusChanged = updateStatus
    BaoSaveInstance._callbacks.OnProgressChanged = updateProgress
    
    -- ================================
    -- Button Click Handlers
    -- ================================
    
    local isProcessing = false
    
    local function handleDecompile(mode)
        if isProcessing then return end
        isProcessing = true
        setButtonsEnabled(false)
        updateStatus("Processing")
        BaoSaveInstance.Notify("Decompiling", "Starting decompile mode: " .. mode, "Warning")
        BaoSaveInstance.Cleanup()
        task.spawn(function()
            local success = BaoSaveInstance.StreamAndDecompile(mode)
            updateStatus(success and "Done" or "Error")
            if success then
                BaoSaveInstance.Notify("Success", "Decompilation complete!", "Success")
            else
                BaoSaveInstance.Notify("Error", "Decompilation encountered an error.", "Error")
            end
            isProcessing = false
            setButtonsEnabled(true)
        end)
    end
    
    btnStreamDecompile.MouseButton1Click:Connect(function() handleDecompile("FullGame") end)
    btnFullGame.MouseButton1Click:Connect(function() handleDecompile("FullGame") end)
    if btnFullModel then btnFullModel.MouseButton1Click:Connect(function() handleDecompile("Models") end) end
    btnTerrain.MouseButton1Click:Connect(function() handleDecompile("Terrain") end)
    
    btnExport.MouseButton1Click:Connect(function()
        if isProcessing then return end
        if not BaoSaveInstance._collectedData then
            updateStatus("Error: No Data")
            BaoSaveInstance.Notify("Export Failed", "No game data has been decompiled yet.", "Error")
            task.wait(2)
            updateStatus("Idle")
            return
        end
        isProcessing = true
        setButtonsEnabled(false)
        updateStatus("Exporting")
        BaoSaveInstance.Notify("Exporting", "Preparing Roblox Place (RBXL) file...", "Warning")
        task.spawn(function()
            local success = BaoSaveInstance.ExportRBXL()
            updateStatus(success and "Done" or "Error")
            if success then
                BaoSaveInstance.Notify("Export Complete", "File saved to your executor's workspace.", "Success")
            else
                BaoSaveInstance.Notify("Export Failed", "An error occurred during export.", "Error")
            end
            isProcessing = false
            setButtonsEnabled(true)
        end)
    end)
    
    -- ================================
    -- CLOSE / MINIMIZE ANIMATIONS
    -- ================================
    
    local isMinimized = false
    local fullSize = UDim2.new(0, 640, 0, 520)
    local fullShadowSize = UDim2.new(0, 654, 0, 534)
    local minSize = UDim2.new(0, 640, 0, 40)
    local minShadowSize = UDim2.new(0, 654, 0, 54)
    local midPos = UDim2.new(0.5, -320, 0.5, -260)
    
    closeBtn.MouseButton1Click:Connect(function()
        -- Animate out
        TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        TweenService:Create(shadowFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.3)
        screenGui:Destroy()
        BaoSaveInstance.Cleanup()
    end)
    
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
             -- Hide panel container
             panelContainer.Visible = false
             statusBarMain.Visible = false
             mainFrame.ClipsDescendants = true
             
            TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = minSize
            }):Play()
            TweenService:Create(shadowFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = minShadowSize
            }):Play()
            minimizeBtn.Text = "□"
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = fullSize
            }):Play()
            TweenService:Create(shadowFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = fullShadowSize
            }):Play()
             task.delay(0.2, function()
                 panelContainer.Visible = true
                 statusBarMain.Visible = true
                 mainFrame.ClipsDescendants = false
             end)
            minimizeBtn.Text = "─"
        end
    end)
    
    -- ================================
    -- OPEN ANIMATION
    -- ================================
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1
    shadowFrame.Size = UDim2.new(0, 0, 0, 0)
    shadowFrame.BackgroundTransparency = 1
    
    task.wait(0.1)
    
    TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = fullSize,
        Position = midPos,
        BackgroundTransparency = 0
    }):Play()
    
    TweenService:Create(shadowFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = fullShadowSize,
        Position = UDim2.new(midPos.X.Scale, midPos.X.Offset - 7, midPos.Y.Scale, midPos.Y.Offset - 7),
        BackgroundTransparency = 0.6
    }):Play()
    
    Utility.Log("INFO", "UI Created")
    return screenGui
end


-- ============================================================
-- MAIN ENTRY POINT
-- ============================================================

-- Initialize API
BaoSaveInstance.Init()

-- Create UI
UIBuilder.Create()

Utility.Log("INFO", "BaoSaveInstance V2 Official loaded and ready")
Utility.Log("INFO", "================================")
Utility.Log("INFO", "Game: " .. Utility.GetGameName())
Utility.Log("INFO", "PlaceId: " .. tostring(game.PlaceId))
Utility.Log("INFO", "================================")
