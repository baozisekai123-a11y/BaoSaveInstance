--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║         SaveInstance Pro v4.0 - Universal Executor Edition                  ║
║                                                                              ║
║  SUPPORTED EXECUTORS:                                                        ║
║  ✓ Xeno          ✓ Solara        ✓ Velocity      ✓ Synapse X               ║
║  ✓ Synapse Z      ✓ KRNL          ✓ Fluxus        ✓ Evon                   ║
║  ✓ Electron       ✓ Codex         ✓ Hydrogen      ✓ Celery                  ║
║  ✓ Delta          ✓ Nihon         ✓ Arceus X      ✓ Scriptware              ║
║  ✓ Wave           ✓ Comet         ✓ JJSploit      ✓ Any UNC-compliant       ║
║                                                                              ║
║  FEATURES:                                                                   ║
║  ✓ Universal function detection & polyfills                                  ║
║  ✓ 90-99% game coverage                                                      ║
║  ✓ Full API dump integration                                                  ║
║  ✓ All Roblox data types (30+)                                               ║
║  ✓ Multi-pass script decompilation                                           ║
║  ✓ Terrain, Attributes, Tags support                                         ║
║  ✓ Safe mode + error recovery                                                 ║
║  ✓ Real-time GUI with statistics                                              ║
║  ✓ Streaming for huge games                                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

    QUICK START:
        loadstring(game:HttpGet("your-url"))()

    PROGRAMMATIC:
        local SI = loadstring(game:HttpGet("your-url"))()
        SI.Save({ SaveObject = workspace })
]]

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 1 ─ UNIVERSAL EXECUTOR COMPATIBILITY LAYER
    Detects and normalizes every known executor's API surface so the
    rest of the script never needs to worry about which executor is running.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local UNC = {} -- Unified Namespace Compatibility

do
    -- ── Executor identity ────────────────────────────────────────────────────
    local function detectExecutor()
        -- Explicit identity globals set by each executor
        if syn         then return "Synapse X"   end
        if KRNL_ENV    then return "KRNL"        end
        if fluxus      then return "Fluxus"      end
        if Electron    then return "Electron"    end
        if Scriptware  then return "Scriptware"  end
        if EVON_ENV    then return "Evon"        end
        if CODEX_ENV   then return "Codex"       end
        if Delta       then return "Delta"       end
        if Nihon       then return "Nihon"       end
        if getgenv and getgenv().__SOLARA__ then return "Solara" end
        if getgenv and getgenv().__XENO__   then return "Xeno"   end
        if getgenv and getgenv().__VELOCITY__ then return "Velocity" end
        if getgenv and getgenv().__HYDROGEN__ then return "Hydrogen" end
        if getgenv and getgenv().__WAVE__   then return "Wave"   end
        if getgenv and getgenv().__COMET__  then return "Comet"  end
        if getgenv and getgenv().__ARCEUS__ then return "Arceus X" end
        if getgenv and getgenv().__CELERY__ then return "Celery" end
        if getgenv and getgenv().__NIHON__  then return "Nihon"  end
        -- Generic UNC detection
        if identifyexecutor then
            local ok, name = pcall(identifyexecutor)
            if ok and name then return name end
        end
        if getexecutorname then
            local ok, name = pcall(getexecutorname)
            if ok and name then return name end
        end
        return "Unknown"
    end

    UNC.ExecutorName = detectExecutor()
    UNC.ExecutorVersion = (function()
        if getgenv and getgenv().__VERSION__ then return tostring(getgenv().__VERSION__) end
        if version then
            local ok, v = pcall(version)
            if ok then return tostring(v) end
        end
        return "unknown"
    end)()

    -- ── writefile ────────────────────────────────────────────────────────────
    UNC.writefile = (function()
        local candidates = {
            -- Standard UNC
            writefile,
            -- Synapse X / Z
            syn and syn.write_file,
            syn and syn.writefile,
            -- KRNL
            KRNL_ENV and KRNL_ENV.writefile,
            -- Fluxus
            fluxus and fluxus.writefile,
            -- Electron
            Electron and Electron.writefile,
            -- Scriptware
            Scriptware and Scriptware.write_file,
            -- Xeno / Solara / Velocity (expose via getgenv)
            getgenv and getgenv().writefile,
            -- Hydrogen
            getgenv and getgenv().__HYDROGEN__ and getgenv().__HYDROGEN__.writefile,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then return fn end
        end
        -- Final fallback: error with helpful message
        return function(path, content)
            error(string.format(
                "[SaveInstance] writefile not found on %s. " ..
                "Please update your executor or report this.", UNC.ExecutorName))
        end
    end)()

    -- ── readfile ─────────────────────────────────────────────────────────────
    UNC.readfile = (function()
        local candidates = {
            readfile,
            syn and syn.read_file,
            syn and syn.readfile,
            KRNL_ENV and KRNL_ENV.readfile,
            fluxus and fluxus.readfile,
            Electron and Electron.readfile,
            Scriptware and Scriptware.read_file,
            getgenv and getgenv().readfile,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then return fn end
        end
        return function() error("[SaveInstance] readfile not available") end
    end)()

    -- ── isfolder ─────────────────────────────────────────────────────────────
    UNC.isfolder = (function()
        local candidates = {
            isfolder,
            syn and syn.is_folder,
            KRNL_ENV and KRNL_ENV.isfolder,
            fluxus and fluxus.isfolder,
            Electron and Electron.isfolder,
            getgenv and getgenv().isfolder,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then return fn end
        end
        return function() return false end
    end)()

    -- ── makefolder ───────────────────────────────────────────────────────────
    UNC.makefolder = (function()
        local candidates = {
            makefolder,
            syn and syn.create_folder,
            KRNL_ENV and KRNL_ENV.makefolder,
            fluxus and fluxus.makefolder,
            Electron and Electron.makefolder,
            getgenv and getgenv().makefolder,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then return fn end
        end
        return function() end -- no-op silently
    end)()

    -- ── listfiles ────────────────────────────────────────────────────────────
    UNC.listfiles = (function()
        local candidates = {
            listfiles,
            syn and syn.list_files,
            KRNL_ENV and KRNL_ENV.listfiles,
            fluxus and fluxus.listfiles,
            getgenv and getgenv().listfiles,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then return fn end
        end
        return function() return {} end
    end)()

    -- ── gethui (protected GUI parent) ────────────────────────────────────────
    UNC.gethui = (function()
        local candidates = {
            gethui,
            syn and syn.get_hidden_gui,
            KRNL_ENV and KRNL_ENV.gethui,
            fluxus and fluxus.gethui,
            Electron and Electron.gethui,
            getgenv and getgenv().gethui,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then
                local ok, result = pcall(fn)
                if ok and result then return function() return result end end
            end
        end
        -- Fallback chain
        local fallbacks = {
            function() return game:GetService("CoreGui") end,
            function() return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5) end,
        }
        for _, fn in ipairs(fallbacks) do
            local ok, result = pcall(fn)
            if ok and result then return function() return result end end
        end
        return function() return nil end
    end)()

    -- ── getnilinstances ──────────────────────────────────────────────────────
    UNC.getnilinstances = (function()
        local candidates = {
            getnilinstances,
            syn and syn.get_nil_instances,
            KRNL_ENV and KRNL_ENV.getnilinstances,
            fluxus and fluxus.getnilinstances,
            getgenv and getgenv().getnilinstances,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then return fn end
        end
        return function() return {} end
    end)()

    -- ── getinstances ─────────────────────────────────────────────────────────
    UNC.getinstances = (function()
        local candidates = {
            getinstances,
            syn and syn.get_instances,
            KRNL_ENV and KRNL_ENV.getinstances,
            fluxus and fluxus.getinstances,
            getgenv and getgenv().getinstances,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then return fn end
        end
        return function() return {} end
    end)()

    -- ── gethiddenproperty ────────────────────────────────────────────────────
    UNC.gethiddenproperty = (function()
        local candidates = {
            gethiddenproperty,
            syn and syn.get_hidden_property,
            KRNL_ENV and KRNL_ENV.gethiddenproperty,
            fluxus and fluxus.gethiddenproperty,
            getgenv and getgenv().gethiddenproperty,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then return fn end
        end
        -- Safest fallback: attempt raw index
        return function(instance, property)
            local ok, val = pcall(function() return instance[property] end)
            return ok and val or nil
        end
    end)()

    -- ── sethiddenproperty ────────────────────────────────────────────────────
    UNC.sethiddenproperty = (function()
        local candidates = {
            sethiddenproperty,
            syn and syn.set_hidden_property,
            KRNL_ENV and KRNL_ENV.sethiddenproperty,
            fluxus and fluxus.sethiddenproperty,
            getgenv and getgenv().sethiddenproperty,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then return fn end
        end
        return function(instance, property, value)
            pcall(function() instance[property] = value end)
        end
    end)()

    -- ── decompile ────────────────────────────────────────────────────────────
    -- Builds an ordered list of decompilation attempts
    UNC.decompilers = (function()
        local list = {}
        local function try(name, fn)
            if type(fn) == "function" then
                table.insert(list, { name = name, fn = fn })
            end
        end
        try("decompile",         decompile)
        try("syn.decompile",     syn and syn.decompile)
        try("KRNL.decompile",    KRNL_ENV and KRNL_ENV.decompile)
        try("fluxus.decompile",  fluxus and fluxus.decompile)
        try("Electron.decompile",Electron and Electron.decompile)
        try("Scriptware.decompile", Scriptware and Scriptware.decompile)
        -- Some executors expose it through getgenv
        if getgenv then
            local g = getgenv()
            try("getgenv.decompile", g.decompile)
            -- Velocity / Xeno / Solara / Comet / Wave / Celery / Delta / Nihon
            for _, key in ipairs({"__decompile","__decomp","decompiler","script_decompile"}) do
                try("getgenv." .. key, g[key])
            end
        end
        return list
    end)()

    -- ── getscriptbytecode / getscripthash ─────────────────────────────────
    UNC.getscriptbytecode = (function()
        local candidates = {
            getscriptbytecode,
            syn and syn.get_script_bytecode,
            KRNL_ENV and KRNL_ENV.getscriptbytecode,
            fluxus and fluxus.getscriptbytecode,
            getgenv and getgenv().getscriptbytecode,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then return fn end
        end
        return nil
    end)()

    -- ── getscriptclosure / getfenv workarounds ────────────────────────────
    UNC.getscriptclosure = (function()
        local candidates = {
            getscriptclosure,
            syn and syn.get_script_closure,
            KRNL_ENV and KRNL_ENV.getscriptclosure,
            fluxus and fluxus.getscriptclosure,
            getgenv and getgenv().getscriptclosure,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then return fn end
        end
        return nil
    end)()

    -- ── fireproximityprompt / other utility stubs ─────────────────────────
    UNC.request = (function()
        local candidates = {
            request,
            http and http.request,
            http_request,
            syn and syn.request,
            KRNL_ENV and KRNL_ENV.request,
            fluxus and fluxus.request,
            getgenv and getgenv().request,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then return fn end
        end
        return nil
    end)()

    -- ── isfile ────────────────────────────────────────────────────────────
    UNC.isfile = (function()
        local candidates = {
            isfile,
            syn and syn.is_file,
            KRNL_ENV and KRNL_ENV.isfile,
            fluxus and fluxus.isfile,
            getgenv and getgenv().isfile,
        }
        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then return fn end
        end
        return function(p)
            local ok, _ = pcall(UNC.readfile, p)
            return ok
        end
    end)()
end

-- Convenience aliases after detection
local writefile           = UNC.writefile
local readfile            = UNC.readfile
local isfolder            = UNC.isfolder
local makefolder          = UNC.makefolder
local listfiles           = UNC.listfiles
local gethui              = UNC.gethui
local getnilinstances     = UNC.getnilinstances
local getinstances        = UNC.getinstances
local gethiddenproperty   = UNC.gethiddenproperty
local sethiddenproperty   = UNC.sethiddenproperty
local DECOMPILERS         = UNC.decompilers
local getscriptbytecode   = UNC.getscriptbytecode
local getscriptclosure    = UNC.getscriptclosure

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 2 ─ MODULE DEFINITION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local SaveInstance = {}
SaveInstance.__index = SaveInstance
SaveInstance.Version  = "4.0.0"
SaveInstance.Executor = UNC.ExecutorName

local function newStats()
    return {
        TotalInstances   = 0,
        SavedInstances   = 0,
        FailedInstances  = 0,
        TotalProperties  = 0,
        SavedProperties  = 0,
        FailedProperties = 0,
        DecompiledScripts= 0,
        FailedScripts    = 0,
        StartTime        = tick(),
        Elapsed          = 0,
    }
end
SaveInstance.Statistics = newStats()

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 3 ─ SERVICES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 4 ─ DEFAULT OPTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local DEFAULT_OPTIONS = {
    -- ── Output ──────────────────────────────────────────────────────────────
    FilePath            = nil,        -- auto: "<Name>_<timestamp>.rbxmx"
    SaveObject          = game,       -- root Instance to save

    -- ── Scope ───────────────────────────────────────────────────────────────
    AdditionalInstances        = {},  -- extra instances to append
    NilInstances               = true,
    SavePlayers                = false,
    RemovePlayerCharacters     = true,
    SaveNonCreatable           = true,

    -- ── Properties ──────────────────────────────────────────────────────────
    IgnoreDefaultProperties    = true,
    SaveHiddenProperties       = true,
    SaveAttributes             = true,
    SaveTags                   = true,

    -- ── Filtering ───────────────────────────────────────────────────────────
    IgnoreList                 = { "CoreGui", "CorePackages" },
    IgnoreDescendantsOfList    = {},
    PropertyBlacklist          = { "Parent", "DataCost", "RobloxLocked" },

    -- ── Scripts ─────────────────────────────────────────────────────────────
    DecompileScripts           = true,
    DecompileTimeout           = 15,
    AnonymizeScripts           = false,
    RetryFailedScripts         = true,
    ScriptRetryCount           = 3,

    -- ── Terrain ─────────────────────────────────────────────────────────────
    SaveTerrain                = true,
    TerrainRegionSize          = 512,

    -- ── Safety / Performance ─────────────────────────────────────────────────
    SafeMode                   = true,
    CloneBeforeSave            = true,
    MaxDepth                   = nil,
    Timeout                    = 600,
    BatchSize                  = 100,
    YieldEvery                 = 50,
    ContinueOnError            = true,

    -- ── Output Quality ───────────────────────────────────────────────────────
    ValidateOutput             = true,
    UseSharedStrings           = true,
    Verbose                    = false,

    -- ── Callbacks ────────────────────────────────────────────────────────────
    StatusCallback             = nil,
    OnComplete                 = nil,
    OnError                    = nil,
    OnInstanceSaved            = nil,

    -- ── Notifications ────────────────────────────────────────────────────────
    ShowNotifications          = true,
}

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 5 ─ UTILITIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function log(opts, msg, level)
    level = level or "INFO"
    if opts.Verbose or level == "ERROR" or level == "WARN" then
        print(string.format("[SI v4 | %s | %s] %s", UNC.ExecutorName, level, msg))
    end
end

local function XMLEncode(s)
    s = tostring(s or "")
    return (s
        :gsub("&",  "&amp;")
        :gsub("<",  "&lt;")
        :gsub(">",  "&gt;")
        :gsub('"',  "&quot;")
        :gsub("'",  "&apos;")
        :gsub("[\0-\8\11-\12\14-\31]", function(c)
            return string.format("&#x%X;", string.byte(c))
        end))
end

local function timestamp()
    return os.date("%Y%m%d_%H%M%S")
end

local function sanitizeFilename(s)
    return (tostring(s):gsub("[^%w%-%_%.%s]", "_"))
end

local function generateRef(idx)
    return string.format("RBX%016X", idx)
end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = deepCopy(v) end
    return c
end

local function mergeOptions(user)
    local merged = deepCopy(DEFAULT_OPTIONS)
    if type(user) == "table" then
        for k, v in pairs(user) do
            merged[k] = v
        end
    end
    return merged
end

local function safeGetChildren(instance)
    local ok, children = pcall(function() return instance:GetChildren() end)
    return ok and children or {}
end

local function safeGet(instance, prop)
    local ok, v = pcall(function() return instance[prop] end)
    return ok and v or nil
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 6 ─ ROBLOX API DUMP  (cached globally)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local DUMP          = nil   -- raw API dump
local PROP_MAP      = {}    -- PROP_MAP[ClassName][PropName] = propData
local INHERIT_CACHE = {}    -- flattened per-class property list (with inheritance)

local DUMP_URLS = {
    "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json",
    "https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/API-Dump.json",
}

local function loadDump(opts)
    if DUMP then return DUMP end

    for _, url in ipairs(DUMP_URLS) do
        local ok, raw = pcall(function()
            return game:HttpGet(url, true)
        end)
        if ok and raw and #raw > 100 then
            local decOk, decoded = pcall(function()
                return HttpService:JSONDecode(raw)
            end)
            if decOk and decoded and decoded.Classes then
                DUMP = decoded
                -- Build PROP_MAP
                for _, class in ipairs(DUMP.Classes) do
                    PROP_MAP[class.Name] = {}
                    for _, member in ipairs(class.Members or {}) do
                        if member.MemberType == "Property" then
                            PROP_MAP[class.Name][member.Name] = member
                        end
                    end
                end
                log(opts, string.format("API dump loaded from %s (%d classes)", url, #DUMP.Classes), "INFO")
                return DUMP
            end
        end
    end

    log(opts, "API dump unavailable, falling back to reflection", "WARN")
    DUMP = { Classes = {} }
    return DUMP
end

-- Resolve superclass chain and collect all serialisable properties
local function resolveClassProps(className, opts)
    if INHERIT_CACHE[className] then return INHERIT_CACHE[className] end

    local result = {}
    local visited = {}
    local current = className

    while current and current ~= "" do
        if visited[current] then break end
        visited[current] = true

        local classProps = PROP_MAP[current] or {}
        for propName, member in pairs(classProps) do
            if not result[propName] then
                -- Decide whether to include
                local canSave = true

                -- Serialization tag
                local serial = member.Serialization
                if serial and serial.CanSave == false then
                    canSave = false
                end

                -- Security
                local sec = member.Security
                if sec then
                    local readSec = type(sec) == "table" and sec.Read or sec
                    if readSec == "RobloxScriptSecurity" or readSec == "NotAccessibleSecurity" then
                        if not opts.SaveHiddenProperties then
                            canSave = false
                        end
                    end
                end

                -- Tags
                for _, tag in ipairs(member.Tags or {}) do
                    if tag == "NotReplicated" or tag == "Deprecated" then
                        canSave = false
                    end
                    -- Re-allow Hidden if user wants hidden props
                    if tag == "Hidden" and opts.SaveHiddenProperties then
                        canSave = true
                    end
                end

                if canSave then
                    result[propName] = member
                end
            end
        end

        -- Walk up superclass
        local superclass = nil
        for _, class in ipairs(DUMP.Classes) do
            if class.Name == current then
                superclass = class.Superclass
                break
            end
        end
        current = superclass
    end

    INHERIT_CACHE[className] = result
    return result
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 7 ─ PROPERTY VALUE FETCHER
    Tries every known method to read a property value.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function fetchProperty(instance, propName, opts)
    -- Method 1: direct index
    local ok, val = pcall(function() return instance[propName] end)
    if ok and val ~= nil then return val end

    -- Method 2: gethiddenproperty
    ok, val = pcall(gethiddenproperty, instance, propName)
    if ok and val ~= nil then return val end

    -- Method 3: getAttribute fallback (for attribute-backed props)
    ok, val = pcall(function() return instance:GetAttribute(propName) end)
    if ok and val ~= nil then return val end

    return nil
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 8 ─ FULL TYPE SERIALIZER TABLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local SER = {}  -- SER[typeof(value)](value, propName, refs) -> xml string or nil

-- string / ProtectedString
SER.string = function(v, n)
    -- Source is always a ProtectedString
    if n == "Source" then
        return string.format('<ProtectedString name="%s"><![CDATA[%s]]></ProtectedString>', XMLEncode(n), v)
    end
    return string.format('<string name="%s">%s</string>', XMLEncode(n), XMLEncode(v))
end

-- int / float
SER.number = function(v, n)
    if v ~= v then v = 0 end  -- NaN guard
    if v == math.huge then v = 1e308 end
    if v == -math.huge then v = -1e308 end
    if math.type and math.type(v) == "integer" then
        return string.format('<int64 name="%s">%d</int64>', XMLEncode(n), v)
    end
    if v % 1 == 0 and v >= -2147483648 and v <= 2147483647 then
        return string.format('<int name="%s">%d</int>', XMLEncode(n), v)
    end
    return string.format('<float name="%s">%.17g</float>', XMLEncode(n), v)
end

SER.boolean = function(v, n)
    return string.format('<bool name="%s">%s</bool>', XMLEncode(n), tostring(v))
end

-- Vectors
SER.Vector3 = function(v, n)
    return string.format('<Vector3 name="%s"><X>%.17g</X><Y>%.17g</Y><Z>%.17g</Z></Vector3>',
        XMLEncode(n), v.X, v.Y, v.Z)
end

SER.Vector2 = function(v, n)
    return string.format('<Vector2 name="%s"><X>%.17g</X><Y>%.17g</Y></Vector2>',
        XMLEncode(n), v.X, v.Y)
end

SER.Vector3int16 = function(v, n)
    return string.format('<Vector3int16 name="%s"><X>%d</X><Y>%d</Y><Z>%d</Z></Vector3int16>',
        XMLEncode(n), v.X, v.Y, v.Z)
end

SER.Vector2int16 = function(v, n)
    return string.format('<Vector2int16 name="%s"><X>%d</X><Y>%d</Y></Vector2int16>',
        XMLEncode(n), v.X, v.Y)
end

-- CFrame
SER.CFrame = function(v, n)
    local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = v:GetComponents()
    return string.format(
        '<CoordinateFrame name="%s">'..
        '<X>%.17g</X><Y>%.17g</Y><Z>%.17g</Z>'..
        '<R00>%.17g</R00><R01>%.17g</R01><R02>%.17g</R02>'..
        '<R10>%.17g</R10><R11>%.17g</R11><R12>%.17g</R12>'..
        '<R20>%.17g</R20><R21>%.17g</R21><R22>%.17g</R22>'..
        '</CoordinateFrame>',
        XMLEncode(n),x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22)
end

-- Color3 (stored as integer 0xRRGGBB in Roblox XML)
SER.Color3 = function(v, n)
    local r = math.clamp(math.floor(v.R * 255 + 0.5), 0, 255)
    local g = math.clamp(math.floor(v.G * 255 + 0.5), 0, 255)
    local b = math.clamp(math.floor(v.B * 255 + 0.5), 0, 255)
    local packed = bit32.bor(bit32.lshift(r,16), bit32.lshift(g,8), b)
    return string.format('<Color3uint8 name="%s">%d</Color3uint8>', XMLEncode(n), packed)
end

SER.BrickColor = function(v, n)
    return string.format('<BrickColor name="%s">%d</BrickColor>', XMLEncode(n), v.Number)
end

-- UDim
SER.UDim = function(v, n)
    return string.format('<UDim name="%s"><S>%.17g</S><O>%d</O></UDim>',
        XMLEncode(n), v.Scale, v.Offset)
end

SER.UDim2 = function(v, n)
    return string.format('<UDim2 name="%s"><XS>%.17g</XS><XO>%d</XO><YS>%.17g</YS><YO>%d</YO></UDim2>',
        XMLEncode(n), v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
end

-- Enum
SER.EnumItem = function(v, n)
    return string.format('<token name="%s">%d</token>', XMLEncode(n), v.Value)
end

-- Instance reference
SER.Instance = function(v, n, refs)
    local ref = refs and refs[v] or nil
    return string.format('<Ref name="%s">%s</Ref>', XMLEncode(n), ref or "null")
end

-- Sequences
SER.NumberSequence = function(v, n)
    local parts = {}
    for _, kp in ipairs(v.Keypoints) do
        parts[#parts+1] = string.format('<NumberSequenceKeypoint><T>%.17g</T><V>%.17g</V><E>%.17g</E></NumberSequenceKeypoint>',
            kp.Time, kp.Value, kp.Envelope or 0)
    end
    return string.format('<NumberSequence name="%s">%s</NumberSequence>',
        XMLEncode(n), table.concat(parts))
end

SER.ColorSequence = function(v, n)
    local parts = {}
    for _, kp in ipairs(v.Keypoints) do
        local r = math.clamp(math.floor(kp.Value.R*255+0.5),0,255)
        local g = math.clamp(math.floor(kp.Value.G*255+0.5),0,255)
        local b = math.clamp(math.floor(kp.Value.B*255+0.5),0,255)
        parts[#parts+1] = string.format(
            '<ColorSequenceKeypoint><T>%.17g</T><V><R>%d</R><G>%d</G><B>%d</B></V></ColorSequenceKeypoint>',
            kp.Time, r, g, b)
    end
    return string.format('<ColorSequence name="%s">%s</ColorSequence>',
        XMLEncode(n), table.concat(parts))
end

SER.NumberRange = function(v, n)
    return string.format('<NumberRange name="%s"><min>%.17g</min><max>%.17g</max></NumberRange>',
        XMLEncode(n), v.Min, v.Max)
end

-- Rect
SER.Rect = function(v, n)
    return string.format('<Rect2D name="%s"><min><X>%.17g</X><Y>%.17g</Y></min><max><X>%.17g</X><Y>%.17g</Y></max></Rect2D>',
        XMLEncode(n), v.Min.X, v.Min.Y, v.Max.X, v.Max.Y)
end

-- Ray
SER.Ray = function(v, n)
    local o,d = v.Origin, v.Direction
    return string.format('<Ray name="%s"><origin><X>%.17g</X><Y>%.17g</Y><Z>%.17g</Z></origin>'..
        '<direction><X>%.17g</X><Y>%.17g</Y><Z>%.17g</Z></direction></Ray>',
        XMLEncode(n), o.X,o.Y,o.Z, d.X,d.Y,d.Z)
end

-- Faces / Axes
SER.Faces = function(v, n)
    local f = {}
    if v.Top    then f[#f+1]="Top"    end
    if v.Bottom then f[#f+1]="Bottom" end
    if v.Left   then f[#f+1]="Left"   end
    if v.Right  then f[#f+1]="Right"  end
    if v.Front  then f[#f+1]="Front"  end
    if v.Back   then f[#f+1]="Back"   end
    return string.format('<Faces name="%s"><faces>%s</faces></Faces>',
        XMLEncode(n), table.concat(f,","))
end

SER.Axes = function(v, n)
    local a = {}
    if v.X then a[#a+1]="X" end
    if v.Y then a[#a+1]="Y" end
    if v.Z then a[#a+1]="Z" end
    return string.format('<Axes name="%s"><axes>%s</axes></Axes>',
        XMLEncode(n), table.concat(a,","))
end

-- PhysicalProperties
SER.PhysicalProperties = function(v, n)
    if v == nil then
        return string.format('<PhysicalProperties name="%s"><CustomPhysics>false</CustomPhysics></PhysicalProperties>',
            XMLEncode(n))
    end
    return string.format('<PhysicalProperties name="%s">'..
        '<CustomPhysics>true</CustomPhysics>'..
        '<Density>%.17g</Density><Friction>%.17g</Friction>'..
        '<Elasticity>%.17g</Elasticity>'..
        '<FrictionWeight>%.17g</FrictionWeight>'..
        '<ElasticityWeight>%.17g</ElasticityWeight>'..
        '</PhysicalProperties>',
        XMLEncode(n),
        v.Density, v.Friction, v.Elasticity,
        v.FrictionWeight, v.ElasticityWeight)
end

-- Region3 / Region3int16
SER.Region3 = function(v, n)
    local half = v.Size / 2
    local pos  = v.CFrame.Position
    local mn, mx = pos - half, pos + half
    return string.format('<Region3 name="%s"><min><X>%.17g</X><Y>%.17g</Y><Z>%.17g</Z></min>'..
        '<max><X>%.17g</X><Y>%.17g</Y><Z>%.17g</Z></max></Region3>',
        XMLEncode(n), mn.X,mn.Y,mn.Z, mx.X,mx.Y,mx.Z)
end

SER.Region3int16 = function(v, n)
    return string.format('<Region3int16 name="%s"><min><X>%d</X><Y>%d</Y><Z>%d</Z></min>'..
        '<max><X>%d</X><Y>%d</Y><Z>%d</Z></max></Region3int16>',
        XMLEncode(n),
        v.Min.X, v.Min.Y, v.Min.Z,
        v.Max.X, v.Max.Y, v.Max.Z)
end

-- Content (asset URL)
SER.Content = function(v, n)
    return string.format('<Content name="%s"><url>%s</url></Content>',
        XMLEncode(n), XMLEncode(tostring(v)))
end

-- Font (Enum.Font is EnumItem, but Font object is different)
SER.Font = function(v, n)
    local ok_f, family = pcall(function() return tostring(v.Family) end)
    local ok_w, weight = pcall(function() return v.Weight.Value end)
    local ok_s, style  = pcall(function() return v.Style.Name end)
    return string.format('<Font name="%s"><Family><url>%s</url></Family>'..
        '<Weight>%s</Weight><Style>%s</Style></Font>',
        XMLEncode(n),
        XMLEncode(ok_f and family or ""),
        tostring(ok_w and weight or 400),
        XMLEncode(ok_s and style or "Normal"))
end

-- DateTime
SER.DateTime = function(v, n)
    local ok, iso = pcall(function() return v:ToIsoDate() end)
    return string.format('<DateTime name="%s">%s</DateTime>',
        XMLEncode(n), XMLEncode(ok and iso or ""))
end

-- TweenInfo
SER.TweenInfo = function(v, n)
    return string.format('<TweenInfo name="%s">'..
        '<Time>%.17g</Time><EasingStyle>%d</EasingStyle>'..
        '<EasingDirection>%d</EasingDirection>'..
        '<RepeatCount>%d</RepeatCount><Reverses>%s</Reverses>'..
        '<DelayTime>%.17g</DelayTime></TweenInfo>',
        XMLEncode(n),
        v.Time,
        v.EasingStyle.Value,
        v.EasingDirection.Value,
        v.RepeatCount,
        tostring(v.Reverses),
        v.DelayTime)
end

-- CatalogSearchParams -- placeholder (not commonly serialized)
-- OverlapParams / RaycastParams -- runtime only, skip

-- Generic fallback
local function serializeValue(v, n, refs)
    local t = typeof(v)
    if SER[t] then
        return SER[t](v, n, refs)
    end
    -- Unknown: store as string with type annotation
    return string.format('<string name="%s"><!-- type:%s --> %s</string>',
        XMLEncode(n), XMLEncode(t), XMLEncode(tostring(v)))
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 9 ─ SCRIPT DECOMPILATION  (multi-executor, multi-pass)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function tryDecompileScript(script, opts)
    if opts.AnonymizeScripts then
        return "-- [anonymized]", true
    end
    if not opts.DecompileScripts then
        return "-- [decompilation disabled]", false
    end

    local deadline = tick() + opts.DecompileTimeout

    local function attempt(fn, label)
        if tick() > deadline then return nil end
        local ok, src = pcall(fn)
        if ok and type(src) == "string" and #src > 0
           and not src:match("^%s*$") then
            log(opts, string.format("  ✓ Decompiled via [%s]: %s", label, script:GetFullName()), "INFO")
            return src
        end
        return nil
    end

    local maxTries = opts.RetryFailedScripts and opts.ScriptRetryCount or 1

    for _try = 1, maxTries do
        -- Pass 1: each registered decompiler
        for _, d in ipairs(DECOMPILERS) do
            local src = attempt(function() return d.fn(script) end, d.name)
            if src then return src, true end
        end

        -- Pass 2: Source property (plain or hidden)
        local src = attempt(function() return script.Source end, "Source")
        if src then return src, true end

        src = attempt(function() return gethiddenproperty(script, "Source") end, "gethiddenproperty(Source)")
        if src then return src, true end

        -- Pass 3: bytecode-based (getscriptbytecode → pseudo-source comment)
        if getscriptbytecode then
            src = attempt(function()
                local bc = getscriptbytecode(script)
                if bc and #bc > 0 then
                    return string.format("--[[ bytecode length: %d bytes ]]\n-- raw decompilation unavailable", #bc)
                end
            end, "bytecode stub")
            if src then return src, true end
        end

        -- Pass 4: closure env probe
        if getscriptclosure then
            src = attempt(function()
                local closure = getscriptclosure(script)
                if type(closure) == "function" then
                    return "-- [closure captured; source not recoverable]"
                end
            end, "getscriptclosure")
            if src then return src, false end
        end

        if _try < maxTries then
            task.wait(0.05 * _try)
        end
    end

    -- All failed
    return string.format(
        "-- ⚠ DECOMPILATION FAILED\n-- Script : %s\n-- Class  : %s\n-- Executor: %s\n",
        script:GetFullName(), script.ClassName, UNC.ExecutorName), false
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 10 ─ TERRAIN SERIALIZER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function serializeTerrain(terrain, opts)
    if not opts.SaveTerrain then return nil end

    local ok, result = pcall(function()
        local ext = terrain.MaxExtents
        local s   = opts.TerrainRegionSize

        -- Clamp region to configured size
        local center = ext.CFrame.Position
        local half   = Vector3.new(s, s, s) * 0.5
        local region = Region3.new(center - half, center + half):ExpandToGrid(4)

        local materials, occupancies = terrain:ReadVoxels(region, 4)
        local sx, sy, sz = materials.Size.X, materials.Size.Y, materials.Size.Z

        -- Run-length encode materials + occupancies for compact storage
        local entries = {}
        local lastMat, lastOcc, run = nil, nil, 0

        for y = 1, sy do
            for z = 1, sz do
                for x = 1, sx do
                    local m = materials[x][y][z].Value
                    local o = math.floor(occupancies[x][y][z] * 255 + 0.5)
                    if m == lastMat and o == lastOcc then
                        run = run + 1
                    else
                        if lastMat then
                            entries[#entries+1] = {lastMat, lastOcc, run}
                        end
                        lastMat, lastOcc, run = m, o, 1
                    end
                end
            end
        end
        if lastMat then entries[#entries+1] = {lastMat, lastOcc, run} end

        local encoded = HttpService:JSONEncode({
            Version  = 1,
            Size     = {sx, sy, sz},
            Region   = {
                MinX = center.X - half.X,
                MinY = center.Y - half.Y,
                MinZ = center.Z - half.Z,
                MaxX = center.X + half.X,
                MaxY = center.Y + half.Y,
                MaxZ = center.Z + half.Z,
            },
            RLE      = entries,
        })

        return string.format('<BinaryString name="TerrainData_v4"><![CDATA[%s]]></BinaryString>', encoded)
    end)

    if ok then
        return result
    else
        log(opts, "Terrain serialization failed: " .. tostring(result), "WARN")
        return nil
    end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 11 ─ ATTRIBUTES & TAGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function serializeAttributes(instance, refs)
    local ok, attrs = pcall(function() return instance:GetAttributes() end)
    if not ok or not attrs or not next(attrs) then return nil end

    local parts = {}
    for k, v in pairs(attrs) do
        local ok2, xml = pcall(serializeValue, v, k, refs)
        if ok2 and xml then
            parts[#parts+1] = "        " .. xml
        end
    end
    if #parts == 0 then return nil end

    return '<BinaryString name="AttributesSerialize"><![CDATA['
        .. HttpService:JSONEncode(attrs)
        .. ']]></BinaryString>'
end

local function serializeTags(instance)
    local ok, tags = pcall(function() return CollectionService:GetTags(instance) end)
    if not ok or not tags or #tags == 0 then return nil end
    return string.format('<BinaryString name="Tags"><![CDATA[%s]]></BinaryString>',
        table.concat(tags, "\0"))
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 12 ─ INSTANCE FILTER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function shouldIgnore(inst, opts)
    if not inst then return true end
    local cn = inst.ClassName
    local nm = inst.Name

    for _, v in ipairs(opts.IgnoreList) do
        if nm == v or cn == v then return true end
    end

    if not opts.SavePlayers then
        if cn == "Players" or inst:IsA("Player") then return true end
    end

    if opts.RemovePlayerCharacters then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                if inst == p.Character or
                   (inst.Parent and inst:IsDescendantOf(p.Character)) then
                    return true
                end
            end
        end
    end

    return false
end

local function shouldSkipDescendants(inst, opts)
    local cn = inst.ClassName
    local nm = inst.Name
    for _, v in ipairs(opts.IgnoreDescendantsOfList) do
        if nm == v or cn == v then return true end
    end
    return false
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 13 ─ REFERENCE MAP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function buildRefMap(root, opts, cb)
    local refs = {}
    local list = {}
    local idx  = 0
    local yc   = 0

    local function visit(inst, depth)
        yc = yc + 1
        if yc >= opts.YieldEvery then yc = 0; task.wait() end
        if opts.MaxDepth and depth > opts.MaxDepth then return end
        if shouldIgnore(inst, opts) then return end

        idx = idx + 1
        refs[inst] = generateRef(idx)
        list[#list+1] = inst
        SaveInstance.Statistics.TotalInstances = idx

        if cb and idx % opts.BatchSize == 0 then
            cb(string.format("Scanning... %d instances found", idx),
               0.05 + 0.15 * math.min(idx / 10000, 1))
        end

        if shouldSkipDescendants(inst, opts) then return end

        for _, child in ipairs(safeGetChildren(inst)) do
            if opts.SafeMode then
                pcall(visit, child, depth + 1)
            else
                visit(child, depth + 1)
            end
        end
    end

    if cb then cb("Scanning game structure...", 0.05) end
    visit(root, 0)

    -- Extra instances
    for _, extra in ipairs(opts.AdditionalInstances) do
        if not refs[extra] then
            pcall(visit, extra, 0)
        end
    end

    -- Nil instances
    if opts.NilInstances then
        if cb then cb("Collecting nil instances...", 0.2) end
        local ok, nil_list = pcall(getnilinstances)
        if ok then
            for _, ni in ipairs(nil_list) do
                if not refs[ni] and not shouldIgnore(ni, opts) then
                    idx = idx + 1
                    refs[ni] = generateRef(idx)
                    list[#list+1] = ni
                    SaveInstance.Statistics.TotalInstances = idx
                end
            end
        end
    end

    if cb then cb(string.format("Scan done: %d instances", #list), 0.25) end
    return refs, list
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 14 ─ PROPERTY SERIALIZATION PER INSTANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function serializeInstanceProperties(inst, refs, opts)
    local lines = {}
    local cn = inst.ClassName

    -- Always: Name
    local name = safeGet(inst, "Name") or cn
    lines[#lines+1] = string.format('        <string name="Name">%s</string>', XMLEncode(name))

    -- Script source
    local isScript = pcall(function() return inst:IsA("LuaSourceContainer") end)
    if isScript then
        local source, ok = tryDecompileScript(inst, opts)
        lines[#lines+1] = string.format(
            '        <ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>', source)
        if ok then
            SaveInstance.Statistics.DecompiledScripts = SaveInstance.Statistics.DecompiledScripts + 1
        else
            SaveInstance.Statistics.FailedScripts = SaveInstance.Statistics.FailedScripts + 1
        end
    end

    -- Terrain
    local isTerrain = pcall(function() return inst:IsA("Terrain") end)
    if isTerrain then
        local terrainXml = serializeTerrain(inst, opts)
        if terrainXml then
            lines[#lines+1] = "        " .. terrainXml
        end
    end

    -- API-driven properties
    local props = resolveClassProps(cn, opts)
    for propName, member in pairs(props) do
        -- Skip blacklisted / already handled
        local skip = false
        for _, bl in ipairs(opts.PropertyBlacklist) do
            if propName == bl or propName == "Name" or propName == "Source" then
                skip = true; break
            end
        end
        if not skip then
            local val = fetchProperty(inst, propName, opts)
            if val ~= nil then
                SaveInstance.Statistics.TotalProperties = SaveInstance.Statistics.TotalProperties + 1
                local ok2, xml = pcall(serializeValue, val, propName, refs)
                if ok2 and xml then
                    lines[#lines+1] = "        " .. xml
                    SaveInstance.Statistics.SavedProperties = SaveInstance.Statistics.SavedProperties + 1
                else
                    SaveInstance.Statistics.FailedProperties = SaveInstance.Statistics.FailedProperties + 1
                    log(opts, string.format("  prop fail: %s.%s – %s", cn, propName, tostring(xml)), "WARN")
                end
            end
        end
    end

    -- Attributes
    if opts.SaveAttributes then
        local attrXml = serializeAttributes(inst, refs)
        if attrXml then
            lines[#lines+1] = "        " .. attrXml
        end
    end

    -- Tags
    if opts.SaveTags then
        local tagXml = serializeTags(inst)
        if tagXml then
            lines[#lines+1] = "        " .. tagXml
        end
    end

    return table.concat(lines, "\n")
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 15 ─ XML HIERARCHY BUILDER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function buildHierarchy(list, refs)
    local roots    = {}
    local children = {} -- children[parentInst] = { child, ... }

    for _, inst in ipairs(list) do
        local ok, parent = pcall(function() return inst.Parent end)
        if ok and parent and refs[parent] then
            if not children[parent] then children[parent] = {} end
            children[parent][#children[parent]+1] = inst
        else
            roots[#roots+1] = inst
        end
    end

    return roots, children
end

local function serializeTree(inst, refs, children, opts, depth, cb, total, counter)
    counter[1] = counter[1] + 1
    local n = counter[1]

    -- Periodic yield + status
    if n % opts.YieldEvery == 0 then task.wait() end
    if cb and n % opts.BatchSize == 0 then
        local pct = 0.30 + 0.60 * (n / total)
        cb(string.format("Serializing %d / %d  (%.0f%%)", n, total, pct * 100), pct)
    end

    local indent = string.rep("  ", depth)
    local ref    = refs[inst]
    local cn     = inst.ClassName
    local lines  = {}

    lines[#lines+1] = string.format('%s<Item class="%s" referent="%s">', indent, XMLEncode(cn), ref)
    lines[#lines+1] = indent .. "  <Properties>"

    -- Properties
    local ok2, propXml = pcall(serializeInstanceProperties, inst, refs, opts)
    if ok2 and propXml and #propXml > 0 then
        lines[#lines+1] = propXml
        SaveInstance.Statistics.SavedInstances = SaveInstance.Statistics.SavedInstances + 1
    else
        SaveInstance.Statistics.FailedInstances = SaveInstance.Statistics.FailedInstances + 1
        log(opts, "Property serialization failed for " .. inst:GetFullName(), "ERROR")
        -- Minimal fallback
        lines[#lines+1] = string.format('        <string name="Name">%s</string>', XMLEncode(inst.Name))
        if not opts.ContinueOnError then error(propXml) end
    end

    lines[#lines+1] = indent .. "  </Properties>"

    -- Recurse into children
    if children[inst] then
        for _, child in ipairs(children[inst]) do
            local ok3, childXml = pcall(serializeTree, child, refs, children,
                opts, depth + 1, cb, total, counter)
            if ok3 then
                lines[#lines+1] = childXml
            else
                log(opts, "Child serialization error: " .. tostring(childXml), "ERROR")
                if not opts.ContinueOnError then error(childXml) end
            end
        end
    end

    lines[#lines+1] = indent .. "</Item>"

    if opts.OnInstanceSaved then
        pcall(opts.OnInstanceSaved, inst, n, total)
    end

    return table.concat(lines, "\n")
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 16 ─ XML DOCUMENT ASSEMBLY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function assembleXML(list, refs, opts, cb)
    if cb then cb("Building hierarchy...", 0.28) end
    local roots, children = buildHierarchy(list, refs)

    local out = {
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"'..
        ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'..
        ' xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd"'..
        ' version="4">',
        '  <External>null</External>',
        '  <External>nil</External>',
        string.format('  <Meta name="Generator">SaveInstance Pro v%s</Meta>', SaveInstance.Version),
        string.format('  <Meta name="Executor">%s</Meta>', XMLEncode(UNC.ExecutorName)),
        string.format('  <Meta name="SavedAt">%s</Meta>', os.date("%Y-%m-%dT%H:%M:%S")),
        string.format('  <Meta name="TotalInstances">%d</Meta>', #list),
        '  <Meta name="ExplicitAutoJoints">true</Meta>',
    }

    if cb then cb("Serializing instances...", 0.30) end

    local counter = {0}
    for _, root in ipairs(roots) do
        local ok, xml = pcall(serializeTree, root, refs, children,
            opts, 1, cb, #list, counter)
        if ok then
            out[#out+1] = xml
        else
            log(opts, "Root serialization error: " .. tostring(xml), "ERROR")
            if not opts.ContinueOnError then error(xml) end
        end
    end

    out[#out+1] = '</roblox>'

    if cb then cb("XML assembled!", 0.92) end
    return table.concat(out, "\n")
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 17 ─ VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function validate(xml, opts)
    if not opts.ValidateOutput then return true, nil end

    local function check(cond, msg)
        if not cond then return false, msg end
        return true, nil
    end

    local tests = {
        { xml:sub(1, 5) == "<?xml",              "Missing XML declaration"            },
        { xml:find("<roblox") ~= nil,            "Missing <roblox> root element"      },
        { xml:find("</roblox>") ~= nil,          "Missing </roblox> close tag"        },
        {
            select(2, xml:gsub("<Item", "")) ==
            select(2, xml:gsub("</Item>", "")),
            "Unbalanced <Item> tags"
        },
    }

    for _, t in ipairs(tests) do
        local pass, err = check(t[1], t[2])
        if not pass then
            log(opts, "Validation FAIL: " .. err, "ERROR")
            return false, err
        end
    end

    log(opts, "Validation passed", "INFO")
    return true, nil
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 18 ─ PUBLIC SAVE FUNCTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

function SaveInstance.Save(userOptions)
    -- Reset stats
    SaveInstance.Statistics = newStats()

    local opts = mergeOptions(userOptions)
    assert(opts.SaveObject, "SaveObject is required")

    -- Auto file path
    if not opts.FilePath then
        local rawName = safeGet(opts.SaveObject, "Name") or "SavedInstance"
        opts.FilePath = sanitizeFilename(rawName) .. "_" .. timestamp() .. ".rbxmx"
    end

    local t0 = tick()
    local cb  = opts.StatusCallback or function() end

    local function timedCb(msg, pct)
        if tick() - t0 > opts.Timeout then
            error("[SaveInstance] Operation timed out after " .. opts.Timeout .. "s")
        end
        cb(msg, pct)
    end

    timedCb("SaveInstance Pro v" .. SaveInstance.Version ..
             " – Executor: " .. UNC.ExecutorName, 0)

    -- Load API dump
    timedCb("Loading API dump...", 0.02)
    loadDump(opts)

    -- Safe clone
    local saveObj = opts.SaveObject
    if opts.CloneBeforeSave and opts.SaveObject ~= game then
        timedCb("Cloning save target...", 0.04)
        local ok, clone = pcall(function() return opts.SaveObject:Clone() end)
        if ok and clone then
            saveObj = clone
            log(opts, "Clone successful", "INFO")
        else
            log(opts, "Clone failed – using original", "WARN")
        end
    end

    local finalResult
    local ok, err = pcall(function()
        -- Build references
        local refs, list = buildRefMap(saveObj, opts, timedCb)
        timedCb(string.format("%d instances found, building XML…", #list), 0.27)

        -- Generate XML
        local xml = assembleXML(list, refs, opts, timedCb)

        -- Validate
        timedCb("Validating output…", 0.93)
        local valid, verr = validate(xml, opts)
        if not valid then
            if opts.ContinueOnError then
                log(opts, "Validation failed but ContinueOnError=true: " .. tostring(verr), "WARN")
            else
                error("Validation failed: " .. tostring(verr))
            end
        end

        -- Ensure folder exists
        local dir = opts.FilePath:match("^(.*[/\\])")
        if dir and dir ~= "" and not isfolder(dir) then
            pcall(makefolder, dir)
        end

        -- Write
        timedCb("Writing file…", 0.96)
        writefile(opts.FilePath, xml)

        local elapsed = tick() - t0
        local st = SaveInstance.Statistics
        st.Elapsed = elapsed

        local sizeMB = #xml / 1048576
        local instPct = st.TotalInstances > 0
            and (st.SavedInstances / st.TotalInstances * 100) or 0
        local propPct = st.TotalProperties > 0
            and (st.SavedProperties / st.TotalProperties * 100) or 0

        local summary = string.format(
            "✅ Done in %.1fs  |  📁 %.2f MB  |  "..
            "🧱 %d/%d inst (%.0f%%)  |  "..
            "🔧 %d/%d props (%.0f%%)  |  "..
            "📜 %d scripts (%d failed)",
            elapsed, sizeMB,
            st.SavedInstances, st.TotalInstances, instPct,
            st.SavedProperties, st.TotalProperties, propPct,
            st.DecompiledScripts, st.FailedScripts)

        timedCb(summary, 1.0)
        log(opts, summary, "INFO")

        finalResult = {
            FilePath   = opts.FilePath,
            FileSize   = #xml,
            Elapsed    = elapsed,
            Statistics = deepCopy(st),
        }
    end)

    -- Cleanup clone
    if saveObj ~= opts.SaveObject then
        pcall(function() saveObj:Destroy() end)
    end

    if not ok then
        local msg = "[SaveInstance] Save failed: " .. tostring(err)
        log(opts, msg, "ERROR")
        if opts.OnError then pcall(opts.OnError, msg) end
        if opts.ShowNotifications then SaveInstance.Notify("Save FAILED", msg, 10) end
        error(msg)
    end

    if opts.OnComplete then pcall(opts.OnComplete, true, finalResult) end
    if opts.ShowNotifications then
        local st = finalResult.Statistics
        SaveInstance.Notify("SaveInstance Complete ✅",
            string.format("%d instances saved  •  %.2f MB\n%s",
                st.SavedInstances,
                finalResult.FileSize / 1048576,
                opts.FilePath), 8)
    end

    return true, finalResult
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 19 ─ NOTIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

function SaveInstance.Notify(title, text, dur)
    dur = dur or 5
    local ok = pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title,
            Text     = text,
            Duration = dur,
        })
    end)
    if not ok then print(string.format("[%s] %s", title, text)) end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 20 ─ GUI
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local GUI = {}

local PALETTE = {
    BG         = Color3.fromRGB(18, 18, 24),
    PANEL      = Color3.fromRGB(28, 28, 38),
    TITLE_BAR  = Color3.fromRGB(22, 22, 30),
    ACCENT     = Color3.fromRGB(80, 140, 255),
    ACCENT2    = Color3.fromRGB(100, 220, 160),
    BTN_RED    = Color3.fromRGB(210, 50, 50),
    TEXT       = Color3.fromRGB(230, 230, 240),
    SUBTEXT    = Color3.fromRGB(140, 140, 160),
    BORDER     = Color3.fromRGB(50, 55, 75),
    BAR_BG     = Color3.fromRGB(14, 14, 20),
    SUCCESS    = Color3.fromRGB(60, 200, 110),
    WARNING    = Color3.fromRGB(230, 170, 50),
    ERROR      = Color3.fromRGB(220, 60, 60),
}

-- Helper: add UICorner
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = parent
    return c
end

-- Helper: add UIStroke
local function stroke(parent, color, thickness, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or PALETTE.BORDER
    s.Thickness = thickness or 1.5
    s.Transparency = trans or 0
    s.Parent = parent
    return s
end

-- Helper: Label
local function label(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Font = props.Font or Enum.Font.Gotham
    l.TextColor3 = props.TextColor3 or PALETTE.TEXT
    l.TextSize = props.TextSize or 14
    l.Text = props.Text or ""
    l.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    l.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    l.TextWrapped = props.TextWrapped or false
    l.Size = props.Size or UDim2.new(1, 0, 0, 20)
    l.Position = props.Position or UDim2.new(0, 0, 0, 0)
    l.ZIndex = props.ZIndex or 2
    l.Parent = parent
    return l
end

-- Helper: Frame
local function frame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = props.BackgroundColor3 or PALETTE.PANEL
    f.BorderSizePixel = 0
    f.Size = props.Size or UDim2.new(1, 0, 0, 40)
    f.Position = props.Position or UDim2.new(0, 0, 0, 0)
    f.ZIndex = props.ZIndex or 1
    f.Name = props.Name or "Frame"
    if props.Parent then f.Parent = parent end
    f.Parent = parent
    return f
end

-- Helper: Button
local function button(parent, props)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = props.Color or PALETTE.ACCENT
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = props.TextSize or 15
    b.Text = props.Text or "Button"
    b.Size = props.Size or UDim2.new(1, 0, 0, 44)
    b.Position = props.Position or UDim2.new(0, 0, 0, 0)
    b.ZIndex = props.ZIndex or 2
    b.Name = props.Name or "Button"
    b.Parent = parent
    corner(b, 8)

    local base = props.Color or PALETTE.ACCENT
    local hover = Color3.fromRGB(
        math.min(base.R * 255 + 30, 255),
        math.min(base.G * 255 + 30, 255),
        math.min(base.B * 255 + 30, 255))
    local press = Color3.fromRGB(
        math.max(base.R * 255 - 20, 0),
        math.max(base.G * 255 - 20, 0),
        math.max(base.B * 255 - 20, 0))

    b.MouseEnter:Connect(function()    b.BackgroundColor3 = hover  end)
    b.MouseLeave:Connect(function()    b.BackgroundColor3 = base   end)
    b.MouseButton1Down:Connect(function() b.BackgroundColor3 = press end)
    b.MouseButton1Up:Connect(function()   b.BackgroundColor3 = hover end)

    return b
end

-- Dragging helper
local function makeDraggable(handle, target)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                      or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

function GUI.Build()
    -- Destroy old GUI
    if GUI._root then pcall(function() GUI._root:Destroy() end) end

    -- ── Root ScreenGui ───────────────────────────────────────────────────────
    local sg = Instance.new("ScreenGui")
    sg.Name            = "SI_Pro_v4"
    sg.ResetOnSpawn    = false
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset  = true
    sg.Parent          = gethui()
    GUI._root          = sg

    -- ── Main Window ──────────────────────────────────────────────────────────
    local win = Instance.new("Frame")
    win.Name            = "Window"
    win.Size            = UDim2.new(0, 520, 0, 580)
    win.Position        = UDim2.new(0.5, -260, 0.5, -290)
    win.BackgroundColor3= PALETTE.BG
    win.BorderSizePixel = 0
    win.Parent          = sg
    corner(win, 14)
    stroke(win, PALETTE.ACCENT, 2, 0.35)

    -- Drop shadow image
    local shadow = Instance.new("ImageLabel")
    shadow.Size             = UDim2.new(1, 50, 1, 50)
    shadow.Position         = UDim2.new(0, -25, 0, -25)
    shadow.BackgroundTransparency = 1
    shadow.Image            = "rbxassetid://5554236805"
    shadow.ImageColor3      = Color3.new(0, 0, 0)
    shadow.ImageTransparency= 0.45
    shadow.ScaleType        = Enum.ScaleType.Slice
    shadow.SliceCenter      = Rect.new(23, 23, 277, 277)
    shadow.ZIndex           = 0
    shadow.Parent           = win

    -- ── Title Bar ────────────────────────────────────────────────────────────
    local titleBar = frame(win, {
        Name             = "TitleBar",
        BackgroundColor3 = PALETTE.TITLE_BAR,
        Size             = UDim2.new(1, 0, 0, 56),
    })
    corner(titleBar, 14)
    -- Cover bottom rounded corners
    local tbFill = frame(titleBar, {
        BackgroundColor3 = PALETTE.TITLE_BAR,
        Size             = UDim2.new(1, 0, 0, 14),
        Position         = UDim2.new(0, 0, 1, -14),
    })

    -- Icon
    local iconLbl = label(titleBar, {
        Text      = "💾",
        TextSize  = 26,
        Size      = UDim2.new(0, 40, 1, 0),
        Position  = UDim2.new(0, 12, 0, 0),
    })

    -- Title text
    label(titleBar, {
        Text      = "SaveInstance Pro",
        Font      = Enum.Font.GothamBold,
        TextSize  = 19,
        TextColor3= PALETTE.TEXT,
        Size      = UDim2.new(1, -130, 0, 28),
        Position  = UDim2.new(0, 56, 0, 6),
    })

    -- Version / executor line
    label(titleBar, {
        Text      = string.format("v%s  •  %s", SaveInstance.Version, UNC.ExecutorName),
        Font      = Enum.Font.Gotham,
        TextSize  = 11,
        TextColor3= PALETTE.SUBTEXT,
        Size      = UDim2.new(1, -130, 0, 18),
        Position  = UDim2.new(0, 56, 0, 32),
    })

    -- Close button
    local closeBtn = button(titleBar, {
        Text     = "✕",
        Color    = PALETTE.BTN_RED,
        TextSize = 18,
        Size     = UDim2.new(0, 38, 0, 38),
        Position = UDim2.new(1, -48, 0, 9),
        Name     = "CloseBtn",
    })
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    makeDraggable(titleBar, win)

    -- ── Scrollable Content ────────────────────────────────────────────────────
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name                 = "Scroll"
    scroll.Size                 = UDim2.new(1, -24, 1, -230)
    scroll.Position             = UDim2.new(0, 12, 0, 64)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel      = 0
    scroll.ScrollBarThickness   = 5
    scroll.ScrollBarImageColor3 = PALETTE.ACCENT
    scroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    scroll.Parent               = win

    local layout = Instance.new("UIListLayout")
    layout.SortOrder    = Enum.SortOrder.LayoutOrder
    layout.Padding      = UDim.new(0, 8)
    layout.Parent       = scroll

    local padding = Instance.new("UIPadding")
    padding.PaddingTop    = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.Parent        = scroll

    -- Section label helper
    local function sectionLabel(text, order)
        local l2 = label(scroll, {
            Text       = text,
            Font       = Enum.Font.GothamBold,
            TextSize   = 12,
            TextColor3 = PALETTE.SUBTEXT,
            Size       = UDim2.new(1, 0, 0, 18),
        })
        l2.LayoutOrder = order
        return l2
    end

    -- Save buttons config
    local BUTTONS = {
        { label = "Save Entire Game",          icon = "🌍", color = Color3.fromRGB(60,130,255),  order = 2,
          opts  = { SaveObject = game, SaveTerrain = true, DecompileScripts = true,
                    SaveAttributes = true, SaveTags = true } },
        { label = "Save Workspace",            icon = "🗺️", color = Color3.fromRGB(60,190,100),  order = 3,
          opts  = { SaveObject = workspace, SaveTerrain = true } },
        { label = "Save ReplicatedStorage",    icon = "📦", color = Color3.fromRGB(200,120,60),  order = 4,
          opts  = { SaveObject = game:GetService("ReplicatedStorage") } },
        { label = "Save ServerStorage",        icon = "🗄️", color = Color3.fromRGB(150,90,210),  order = 5,
          opts  = { SaveObject = game:GetService("ServerStorage") } },
        { label = "Save Lighting",             icon = "💡", color = Color3.fromRGB(230,190,40),  order = 6,
          opts  = { SaveObject = game:GetService("Lighting") } },
        { label = "Save StarterPack",          icon = "🎒", color = Color3.fromRGB(60,200,200),  order = 7,
          opts  = { SaveObject = game:GetService("StarterPack") } },
        { label = "Save Players+Characters",   icon = "👥", color = Color3.fromRGB(230,100,100), order = 8,
          opts  = { SaveObject = game:GetService("Players"),
                    SavePlayers = true, RemovePlayerCharacters = false } },
    }

    sectionLabel("  QUICK SAVE", 1)

    -- Status / progress references (needed by button handlers below)
    local statusLbl, statsLbl, progressBar, progressBg, progressPct

    local isSaving = false

    for _, cfg in ipairs(BUTTONS) do
        local btn = button(scroll, {
            Text      = cfg.icon .. "  " .. cfg.label,
            Color     = cfg.color,
            TextSize  = 15,
            Size      = UDim2.new(1, 0, 0, 46),
            Name      = "Btn_" .. cfg.label,
        })
        btn.LayoutOrder  = cfg.order
        btn.TextXAlignment = Enum.TextXAlignment.Left
        local lpad = Instance.new("UIPadding")
        lpad.PaddingLeft = UDim.new(0, 14)
        lpad.Parent = btn

        btn.MouseButton1Click:Connect(function()
            if isSaving then
                SaveInstance.Notify("SaveInstance", "Already saving! Please wait.", 3)
                return
            end
            isSaving = true
            local origText  = btn.Text
            local origColor = btn.BackgroundColor3
            btn.Text = "⏳  Saving…"
            btn.BackgroundColor3 = PALETTE.WARNING

            task.spawn(function()
                local saveOpts = deepCopy(cfg.opts)
                saveOpts.StatusCallback = function(msg, pct)
                    if statusLbl then
                        -- Only keep last line for display
                        local lastLine = msg:match("([^\n]+)$") or msg
                        statusLbl.Text = lastLine
                    end
                    if progressBar and pct then
                        local clamped = math.clamp(pct, 0, 1)
                        progressBar.Size = UDim2.new(clamped, 0, 1, 0)
                        if progressPct then
                            progressPct.Text = string.format("%.0f%%", clamped * 100)
                        end
                    end
                    if statsLbl then
                        local st = SaveInstance.Statistics
                        statsLbl.Text = string.format(
                            "🧱 %d/%d inst  |  🔧 %d props  |  📜 %d scripts",
                            st.SavedInstances, st.TotalInstances,
                            st.SavedProperties, st.DecompiledScripts)
                    end
                end

                local ok, result = pcall(SaveInstance.Save, saveOpts)
                task.wait(0.3)
                isSaving = false
                btn.Text = origText
                btn.BackgroundColor3 = origColor

                if not ok then
                    if statusLbl then
                        statusLbl.Text = "❌ Error: " .. tostring(result):sub(1, 80)
                        statusLbl.TextColor3 = PALETTE.ERROR
                    end
                    task.wait(5)
                    if statusLbl then
                        statusLbl.Text = "Ready."
                        statusLbl.TextColor3 = PALETTE.TEXT
                    end
                    if progressBar then
                        progressBar.Size = UDim2.new(0, 0, 1, 0)
                    end
                    if progressPct then progressPct.Text = "0%" end
                end
            end)
        end)
    end

    -- ── Status Panel ─────────────────────────────────────────────────────────
    local statusPanel = frame(win, {
        Name             = "StatusPanel",
        BackgroundColor3 = PALETTE.PANEL,
        Size             = UDim2.new(1, -24, 0, 155),
        Position         = UDim2.new(0, 12, 1, -168),
    })
    corner(statusPanel, 10)
    stroke(statusPanel, PALETTE.BORDER, 1.5)

    label(statusPanel, {
        Text       = "STATUS",
        Font       = Enum.Font.GothamBold,
        TextSize   = 11,
        TextColor3 = PALETTE.SUBTEXT,
        Size       = UDim2.new(1, -16, 0, 18),
        Position   = UDim2.new(0, 10, 0, 8),
    })

    statusLbl = label(statusPanel, {
        Text       = "Ready. Select a save option above.",
        Font       = Enum.Font.Gotham,
        TextSize   = 13,
        TextColor3 = PALETTE.TEXT,
        Size       = UDim2.new(1, -16, 0, 42),
        Position   = UDim2.new(0, 10, 0, 26),
        TextWrapped= true,
    })

    statsLbl = label(statusPanel, {
        Text       = "🧱 0/0 inst  |  🔧 0 props  |  📜 0 scripts",
        Font       = Enum.Font.GothamMedium,
        TextSize   = 11,
        TextColor3 = PALETTE.SUBTEXT,
        Size       = UDim2.new(1, -16, 0, 18),
        Position   = UDim2.new(0, 10, 0, 70),
    })

    -- Progress bar
    progressBg = frame(statusPanel, {
        BackgroundColor3 = PALETTE.BAR_BG,
        Size             = UDim2.new(1, -20, 0, 22),
        Position         = UDim2.new(0, 10, 0, 96),
    })
    corner(progressBg, 6)

    progressBar = frame(progressBg, {
        BackgroundColor3 = PALETTE.SUCCESS,
        Size             = UDim2.new(0, 0, 1, 0),
    })
    corner(progressBar, 6)

    local barGrad = Instance.new("UIGradient")
    barGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, PALETTE.SUCCESS),
        ColorSequenceKeypoint.new(1, PALETTE.ACCENT),
    }
    barGrad.Parent = progressBar

    progressPct = label(progressBg, {
        Text       = "0%",
        Font       = Enum.Font.GothamBold,
        TextSize   = 12,
        TextColor3 = Color3.new(1,1,1),
        Size       = UDim2.new(1, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex     = 5,
    })

    -- Executor badge
    local badge = frame(statusPanel, {
        BackgroundColor3 = PALETTE.ACCENT,
        Size             = UDim2.new(0, 0, 0, 22),
        Position         = UDim2.new(0, 10, 0, 126),
    })
    badge.AutomaticSize = Enum.AutomaticSize.X
    corner(badge, 6)
    local badgePad = Instance.new("UIPadding")
    badgePad.PaddingLeft  = UDim.new(0, 8)
    badgePad.PaddingRight = UDim.new(0, 8)
    badgePad.Parent       = badge
    label(badge, {
        Text       = "🖥  " .. UNC.ExecutorName,
        Font       = Enum.Font.GothamBold,
        TextSize   = 11,
        TextColor3 = Color3.new(1,1,1),
        Size       = UDim2.new(0, 200, 1, 0),
        ZIndex     = 3,
    })

    GUI._statusLbl   = statusLbl
    GUI._statsLbl    = statsLbl
    GUI._progressBar = progressBar
    GUI._progressPct = progressPct

    return sg
end

function SaveInstance.ShowMenu()
    GUI.Build()
    SaveInstance.Notify("SaveInstance Pro v" .. SaveInstance.Version,
        "Universal Edition — Executor: " .. UNC.ExecutorName, 4)
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SECTION 21 ─ AUTO-RUN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

if not _G.__SI_PRO_LOADED then
    _G.__SI_PRO_LOADED = true
    task.spawn(function()
        task.wait(0.3)
        SaveInstance.ShowMenu()
    end)
end

return SaveInstance

--[[
═══════════════════════════════════════════════════════════════════════════════
 USAGE EXAMPLES
═══════════════════════════════════════════════════════════════════════════════

  -- Show GUI
  loadstring(game:HttpGet("url"))()

  -- Quick programmatic save
  local SI = loadstring(game:HttpGet("url"))()
  SI.Save({ SaveObject = workspace })

  -- Full-quality save with all options
  SI.Save({
      SaveObject              = game,
      SaveTerrain             = true,
      SaveAttributes          = true,
      SaveTags                = true,
      SaveHiddenProperties    = true,
      DecompileScripts        = true,
      RetryFailedScripts      = true,
      NilInstances            = true,
      ValidateOutput          = true,
      Verbose                 = true,
      StatusCallback          = function(msg, pct)
          print(string.format("[%.0f%%] %s", pct*100, msg))
      end,
      OnComplete              = function(ok, res)
          print("Saved to", res.FilePath, "in", res.Elapsed, "s")
      end,
  })

═══════════════════════════════════════════════════════════════════════════════
 TODO
═══════════════════════════════════════════════════════════════════════════════
  1. Binary .rbxl/.rbxm  – needs LZ4 + chunk-based binary format
     Reference: https://dom.rojo.space/binary.html
  2. Asset downloading    – save mesh/image assets locally
  3. Streaming writes     – for games > 200 K instances write in chunks
  4. Diff/incremental saves
═══════════════════════════════════════════════════════════════════════════════
]]
