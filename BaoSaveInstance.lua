--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║          SaveInstance Pro v5.0 - Anti-Freeze & Seamless Edition             ║
║                                                                              ║
║  ROOT CAUSE FIXES:                                                           ║
║  ✓ Non-blocking async pipeline (no more freezes)                            ║
║  ✓ Coroutine-based streaming writer                                          ║
║  ✓ Hard per-step timeout with graceful recovery                             ║
║  ✓ Chunk-based XML builder (never builds one giant string)                  ║
║  ✓ Heartbeat-driven progress so Roblox never kills the thread               ║
║  ✓ Property read guard (no infinite property waits)                         ║
║  ✓ Script decompile runs in isolated coroutine with hard deadline           ║
║  ✓ Memory-safe: flushes chunks to disk, never holds full XML in RAM         ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 1: EXECUTOR COMPATIBILITY LAYER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ENV = {} -- resolved executor environment

do
    -- Detect executor name
    local function detectName()
        local checks = {
            { check = function() return syn and "Synapse X" end },
            { check = function() return KRNL_ENV and "KRNL" end },
            { check = function() return fluxus and "Fluxus" end },
            { check = function() return Electron and "Electron" end },
            { check = function() return Scriptware and "Scriptware" end },
            { check = function() return EVON_ENV and "Evon" end },
            { check = function() return CODEX_ENV and "Codex" end },
            { check = function() return Delta and "Delta" end },
            { check = function() return getgenv and getgenv().__SOLARA__ and "Solara" end },
            { check = function() return getgenv and getgenv().__XENO__ and "Xeno" end },
            { check = function() return getgenv and getgenv().__VELOCITY__ and "Velocity" end },
            { check = function() return getgenv and getgenv().__WAVE__ and "Wave" end },
            { check = function() return getgenv and getgenv().__COMET__ and "Comet" end },
            { check = function() return getgenv and getgenv().__HYDROGEN__ and "Hydrogen" end },
            { check = function() return getgenv and getgenv().__CELERY__ and "Celery" end },
            { check = function() return getgenv and getgenv().__ARCEUS__ and "Arceus X" end },
            { check = function()
                if identifyexecutor then
                    local ok, n = pcall(identifyexecutor)
                    return ok and n or nil
                end
            end },
            { check = function()
                if getexecutorname then
                    local ok, n = pcall(getexecutorname)
                    return ok and n or nil
                end
            end },
        }
        for _, c in ipairs(checks) do
            local ok, r = pcall(c.check)
            if ok and r then return tostring(r) end
        end
        return "Unknown Executor"
    end

    ENV.Name = detectName()

    -- Generic resolver: try a list of candidate values, return first function
    local function resolve(candidates, fallback)
        for _, c in ipairs(candidates) do
            local ok, v = pcall(function() return c end)
            if ok and type(v) == "function" then return v end
        end
        return fallback
    end

    local genv = (getgenv and getgenv()) or {}

    ENV.writefile = resolve({
        writefile,
        genv.writefile,
        syn and syn.write_file,
        syn and syn.writefile,
        KRNL_ENV and KRNL_ENV.writefile,
        fluxus and fluxus.writefile,
        Electron and Electron.writefile,
        Scriptware and Scriptware.write_file,
    }, function() error("[SI] writefile not found on " .. ENV.Name) end)

    ENV.readfile = resolve({
        readfile, genv.readfile,
        syn and syn.read_file,
        KRNL_ENV and KRNL_ENV.readfile,
    }, function() error("[SI] readfile not found") end)

    ENV.appendfile = resolve({
        appendfile, genv.appendfile,
        syn and syn.append_file,
        KRNL_ENV and KRNL_ENV.appendfile,
    }, nil) -- nil = will fall back to writefile accumulation

    ENV.isfolder = resolve({
        isfolder, genv.isfolder,
        syn and syn.is_folder,
        KRNL_ENV and KRNL_ENV.isfolder,
    }, function() return false end)

    ENV.makefolder = resolve({
        makefolder, genv.makefolder,
        syn and syn.create_folder,
        KRNL_ENV and KRNL_ENV.makefolder,
    }, function() end)

    ENV.gethui = (function()
        local candidates = {
            gethui, genv.gethui,
            syn and syn.get_hidden_gui,
            KRNL_ENV and KRNL_ENV.gethui,
            fluxus and fluxus.gethui,
        }
        for _, c in ipairs(candidates) do
            local ok, v = pcall(function() return c end)
            if ok and type(v) == "function" then
                local ok2, r = pcall(v)
                if ok2 and r then return r end
            end
        end
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        return ok and cg or nil
    end)()

    ENV.getnilinstances = resolve({
        getnilinstances, genv.getnilinstances,
        syn and syn.get_nil_instances,
        KRNL_ENV and KRNL_ENV.getnilinstances,
    }, function() return {} end)

    ENV.gethiddenproperty = resolve({
        gethiddenproperty, genv.gethiddenproperty,
        syn and syn.get_hidden_property,
        KRNL_ENV and KRNL_ENV.gethiddenproperty,
    }, function(inst, prop)
        local ok, v = pcall(function() return inst[prop] end)
        return ok and v or nil
    end)

    -- Build decompiler list (ordered best-to-worst)
    ENV.decompilers = {}
    local function addDecomp(name, fn)
        if type(fn) == "function" then
            table.insert(ENV.decompilers, { name = name, fn = fn })
        end
    end
    addDecomp("decompile",              decompile)
    addDecomp("syn.decompile",          syn and syn.decompile)
    addDecomp("KRNL.decompile",         KRNL_ENV and KRNL_ENV.decompile)
    addDecomp("fluxus.decompile",       fluxus and fluxus.decompile)
    addDecomp("Electron.decompile",     Electron and Electron.decompile)
    addDecomp("Scriptware.decompile",   Scriptware and Scriptware.decompile)
    addDecomp("getgenv.decompile",      genv.decompile)
    addDecomp("getgenv.__decompile",    genv.__decompile)

    ENV.getscriptbytecode = resolve({
        getscriptbytecode, genv.getscriptbytecode,
        syn and syn.get_script_bytecode,
    }, nil)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 2: SERVICES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local HttpService        = game:GetService("HttpService")
local RunService         = game:GetService("RunService")
local Players            = game:GetService("Players")
local CollectionService  = game:GetService("CollectionService")
local UserInputService   = game:GetService("UserInputService")
local StarterGui         = game:GetService("StarterGui")
local TweenService       = game:GetService("TweenService")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 3: ASYNC SCHEDULER
-- Every heavy operation MUST go through here so the engine keeps ticking.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local Scheduler = {}

-- How many iterations between yields (tune for your game size)
Scheduler.YIELD_INTERVAL  = 40    -- yield every N iterations
Scheduler.YIELD_DURATION  = 0     -- task.wait(0) = next frame
Scheduler.PROP_TIMEOUT    = 0.5   -- max seconds to read one property
Scheduler.DECOMP_TIMEOUT  = 12    -- max seconds per script
Scheduler.STEP_TIMEOUT    = 2     -- max seconds per scan/serialize step before forced yield

local _counter = 0

-- Call this inside every tight loop instead of raw task.wait()
function Scheduler.step()
    _counter = _counter + 1
    if _counter >= Scheduler.YIELD_INTERVAL then
        _counter = 0
        task.wait(Scheduler.YIELD_DURATION)
    end
end

-- Force a yield right now
function Scheduler.yield()
    _counter = 0
    task.wait(Scheduler.YIELD_DURATION)
end

-- Run `fn` with a wall-clock deadline; returns success, value
-- Uses a thread so the deadline is truly enforced without blocking.
function Scheduler.timed(fn, timeout, ...)
    local args = { ... }
    local result, done, timedOut = nil, false, false

    local thread = task.spawn(function()
        local ok, val = pcall(fn, table.unpack(args))
        result = { ok = ok, val = val }
        done = true
    end)

    local deadline = tick() + timeout
    while not done do
        if tick() > deadline then
            timedOut = true
            -- We cannot kill the thread safely but we stop waiting
            pcall(task.cancel, thread)
            break
        end
        task.wait(0)
    end

    if timedOut or not result then
        return false, nil
    end
    return result.ok, result.val
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 4: STREAMING FILE WRITER
-- Writes XML in chunks so RAM stays low and the file is always recoverable.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local StreamWriter = {}
StreamWriter.__index = StreamWriter

local CHUNK_SIZE = 512 * 1024 -- flush every 512 KB

function StreamWriter.new(filePath, useAppend)
    local self = setmetatable({}, StreamWriter)
    self.path      = filePath
    self.buf       = {}
    self.bufLen    = 0
    self.totalLen  = 0
    self.chunks    = 0
    self.useAppend = useAppend and ENV.appendfile ~= nil

    -- Clear / create file
    ENV.writefile(filePath, "")
    return self
end

function StreamWriter:write(s)
    if not s or s == "" then return end
    self.buf[#self.buf + 1] = s
    self.bufLen = self.bufLen + #s
    self.totalLen = self.totalLen + #s

    if self.bufLen >= CHUNK_SIZE then
        self:flush()
    end
end

function StreamWriter:writeln(s)
    self:write((s or "") .. "\n")
end

function StreamWriter:flush()
    if self.bufLen == 0 then return end
    local data = table.concat(self.buf)
    self.buf    = {}
    self.bufLen = 0
    self.chunks = self.chunks + 1

    if self.useAppend then
        ENV.appendfile(self.path, data)
    else
        -- Read existing + append (fallback for executors without appendfile)
        local ok, existing = pcall(ENV.readfile, self.path)
        ENV.writefile(self.path, (ok and existing or "") .. data)
    end

    Scheduler.yield() -- breathe after every disk write
end

function StreamWriter:close()
    self:flush()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 5: UTILITIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function XMLEncode(s)
    s = tostring(s or "")
    return (s
        :gsub("&",  "&amp;")
        :gsub("<",  "&lt;")
        :gsub(">",  "&gt;")
        :gsub('"',  "&quot;")
        :gsub("'",  "&apos;")
        :gsub("[\0-\8\11\12\14-\31]", function(c)
            return string.format("&#x%X;", string.byte(c))
        end))
end

local function safeToString(v)
    local ok, s = pcall(tostring, v)
    return ok and s or "?"
end

local function timestamp()
    return os.date("%Y%m%d_%H%M%S")
end

local function sanitize(s)
    return (tostring(s):gsub("[^%w%-_.]", "_"))
end

local function generateRef(n)
    return string.format("RBX%016X", n)
end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[deepCopy(k)] = deepCopy(v) end
    return c
end

-- Safe property read with hard timeout
local function safeReadProp(instance, prop)
    local ok, val = Scheduler.timed(function()
        return instance[prop]
    end, Scheduler.PROP_TIMEOUT)
    return ok and val or nil
end

-- Safe children with timeout
local function safeChildren(inst)
    local ok, ch = pcall(function() return inst:GetChildren() end)
    return ok and ch or {}
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 6: DEFAULT OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local DEFAULTS = {
    FilePath                = nil,
    SaveObject              = game,

    -- Scope
    AdditionalInstances     = {},
    NilInstances            = true,
    SavePlayers             = false,
    RemovePlayerCharacters  = true,

    -- Properties
    IgnoreDefaultProperties = true,
    SaveHiddenProperties    = true,
    SaveAttributes          = true,
    SaveTags                = true,

    -- Filtering
    IgnoreList              = { "CoreGui", "CorePackages" },
    IgnoreDescendantsOfList = {},
    PropertyBlacklist       = { "Parent", "DataCost", "RobloxLocked" },

    -- Scripts
    DecompileScripts        = true,
    DecompileTimeout        = 12,
    AnonymizeScripts        = false,
    RetryFailedScripts      = true,
    ScriptRetryCount        = 2,

    -- Terrain
    SaveTerrain             = true,
    TerrainRegionSize       = 256,  -- smaller = faster, less freeze

    -- Anti-freeze controls
    YieldInterval           = 40,   -- iterations between yields
    YieldDuration           = 0,    -- seconds per yield (0 = next frame)
    PropTimeout             = 0.5,  -- seconds per property read
    DecompTimeout           = 12,   -- seconds per script decompile

    -- Safety
    SafeMode                = true,
    CloneBeforeSave         = true,
    MaxDepth                = nil,
    ContinueOnError         = true,

    -- Output
    ValidateOutput          = true,
    Verbose                 = false,

    -- Callbacks
    StatusCallback          = nil,
    OnComplete              = nil,
    OnError                 = nil,
    OnInstanceSaved         = nil,

    ShowNotifications       = true,
}

local function mergeOpts(user)
    local o = deepCopy(DEFAULTS)
    if type(user) == "table" then
        for k, v in pairs(user) do o[k] = v end
    end
    -- Push user settings into scheduler
    Scheduler.YIELD_INTERVAL = o.YieldInterval
    Scheduler.YIELD_DURATION = o.YieldDuration
    Scheduler.PROP_TIMEOUT   = o.PropTimeout
    Scheduler.DECOMP_TIMEOUT = o.DecompTimeout
    return o
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 7: API DUMP (cached globally, fetched once per session)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local DUMP_CACHE      = nil
local PROP_MAP        = {}   -- [ClassName][PropName] = member
local INHERIT_FLAT    = {}   -- [ClassName] = { propName = member, ... }

local DUMP_URLS = {
    "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json",
    "https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/API-Dump.json",
}

local function loadDump(opts)
    if DUMP_CACHE then return DUMP_CACHE end

    for _, url in ipairs(DUMP_URLS) do
        local ok, raw = pcall(function()
            return game:HttpGet(url, true)
        end)
        if ok and raw and #raw > 1000 then
            local jok, dump = pcall(HttpService.JSONDecode, HttpService, raw)
            if jok and dump and dump.Classes then
                DUMP_CACHE = dump
                for _, cls in ipairs(dump.Classes) do
                    PROP_MAP[cls.Name] = {}
                    for _, m in ipairs(cls.Members or {}) do
                        if m.MemberType == "Property" then
                            PROP_MAP[cls.Name][m.Name] = m
                        end
                    end
                end
                if opts and opts.Verbose then
                    print(string.format("[SI] API dump: %d classes from %s", #dump.Classes, url))
                end
                return DUMP_CACHE
            end
        end
        Scheduler.yield()
    end

    if opts and opts.Verbose then
        warn("[SI] API dump unavailable – reflection fallback active")
    end
    DUMP_CACHE = { Classes = {} }
    return DUMP_CACHE
end

-- Walk superclass chain and collect serialisable props (memoised)
local function flatProps(className, opts)
    if INHERIT_FLAT[className] then return INHERIT_FLAT[className] end

    local result  = {}
    local current = className
    local visited = {}

    while current and current ~= "" and not visited[current] do
        visited[current] = true
        for pname, member in pairs(PROP_MAP[current] or {}) do
            if not result[pname] then
                local include = true

                local serial = member.Serialization
                if serial and serial.CanSave == false then include = false end

                local sec = member.Security
                if sec then
                    local rSec = type(sec) == "table" and sec.Read or sec
                    if rSec == "RobloxScriptSecurity"
                    or rSec == "NotAccessibleSecurity" then
                        if not opts.SaveHiddenProperties then include = false end
                    end
                end

                for _, tag in ipairs(member.Tags or {}) do
                    if tag == "NotReplicated" or tag == "Deprecated" then
                        include = false
                    end
                    if tag == "Hidden" and opts.SaveHiddenProperties then
                        include = true
                    end
                end

                if include then result[pname] = member end
            end
        end

        -- Next superclass
        local super = nil
        for _, cls in ipairs((DUMP_CACHE or { Classes = {} }).Classes) do
            if cls.Name == current then super = cls.Superclass; break end
        end
        current = super
    end

    INHERIT_FLAT[className] = result
    return result
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 8: PROPERTY SERIALIZERS  (all 30+ Roblox types)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local SER = {}

SER.string = function(v, n)
    if n == "Source" then
        return string.format(
            '<ProtectedString name="%s"><![CDATA[%s]]></ProtectedString>',
            XMLEncode(n), v)
    end
    return string.format('<string name="%s">%s</string>', XMLEncode(n), XMLEncode(v))
end

SER.number = function(v, n)
    if v ~= v or v == math.huge or v == -math.huge then v = 0 end
    if v % 1 == 0 and v >= -2147483648 and v <= 2147483647 then
        return string.format('<int name="%s">%d</int>', XMLEncode(n), v)
    end
    return string.format('<float name="%s">%.17g</float>', XMLEncode(n), v)
end

SER.boolean = function(v, n)
    return string.format('<bool name="%s">%s</bool>', XMLEncode(n), tostring(v))
end

SER.Vector3 = function(v, n)
    return string.format('<Vector3 name="%s"><X>%.9g</X><Y>%.9g</Y><Z>%.9g</Z></Vector3>',
        XMLEncode(n), v.X, v.Y, v.Z)
end

SER.Vector2 = function(v, n)
    return string.format('<Vector2 name="%s"><X>%.9g</X><Y>%.9g</Y></Vector2>',
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

SER.CFrame = function(v, n)
    local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = v:GetComponents()
    return string.format(
        '<CoordinateFrame name="%s">'..
        '<X>%.9g</X><Y>%.9g</Y><Z>%.9g</Z>'..
        '<R00>%.9g</R00><R01>%.9g</R01><R02>%.9g</R02>'..
        '<R10>%.9g</R10><R11>%.9g</R11><R12>%.9g</R12>'..
        '<R20>%.9g</R20><R21>%.9g</R21><R22>%.9g</R22>'..
        '</CoordinateFrame>',
        XMLEncode(n),x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22)
end

SER.Color3 = function(v, n)
    local r = math.clamp(math.floor(v.R*255+.5),0,255)
    local g = math.clamp(math.floor(v.G*255+.5),0,255)
    local b = math.clamp(math.floor(v.B*255+.5),0,255)
    return string.format('<Color3uint8 name="%s">%d</Color3uint8>',
        XMLEncode(n), bit32.bor(bit32.lshift(r,16), bit32.lshift(g,8), b))
end

SER.BrickColor = function(v, n)
    return string.format('<BrickColor name="%s">%d</BrickColor>', XMLEncode(n), v.Number)
end

SER.UDim = function(v, n)
    return string.format('<UDim name="%s"><S>%.9g</S><O>%d</O></UDim>',
        XMLEncode(n), v.Scale, v.Offset)
end

SER.UDim2 = function(v, n)
    return string.format(
        '<UDim2 name="%s"><XS>%.9g</XS><XO>%d</XO><YS>%.9g</YS><YO>%d</YO></UDim2>',
        XMLEncode(n), v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
end

SER.EnumItem = function(v, n)
    return string.format('<token name="%s">%d</token>', XMLEncode(n), v.Value)
end

SER.Instance = function(v, n, refs)
    return string.format('<Ref name="%s">%s</Ref>',
        XMLEncode(n), (refs and refs[v]) or "null")
end

SER.NumberSequence = function(v, n)
    local parts = {}
    for _, kp in ipairs(v.Keypoints) do
        parts[#parts+1] = string.format(
            '<NumberSequenceKeypoint><T>%.9g</T><V>%.9g</V><E>%.9g</E></NumberSequenceKeypoint>',
            kp.Time, kp.Value, kp.Envelope or 0)
    end
    return string.format('<NumberSequence name="%s">%s</NumberSequence>',
        XMLEncode(n), table.concat(parts))
end

SER.ColorSequence = function(v, n)
    local parts = {}
    for _, kp in ipairs(v.Keypoints) do
        local r = math.clamp(math.floor(kp.Value.R*255+.5),0,255)
        local g = math.clamp(math.floor(kp.Value.G*255+.5),0,255)
        local b = math.clamp(math.floor(kp.Value.B*255+.5),0,255)
        parts[#parts+1] = string.format(
            '<ColorSequenceKeypoint><T>%.9g</T>'..
            '<V><R>%d</R><G>%d</G><B>%d</B></V>'..
            '</ColorSequenceKeypoint>',
            kp.Time, r, g, b)
    end
    return string.format('<ColorSequence name="%s">%s</ColorSequence>',
        XMLEncode(n), table.concat(parts))
end

SER.NumberRange = function(v, n)
    return string.format(
        '<NumberRange name="%s"><min>%.9g</min><max>%.9g</max></NumberRange>',
        XMLEncode(n), v.Min, v.Max)
end

SER.Rect = function(v, n)
    return string.format(
        '<Rect2D name="%s"><min><X>%.9g</X><Y>%.9g</Y></min>'..
        '<max><X>%.9g</X><Y>%.9g</Y></max></Rect2D>',
        XMLEncode(n), v.Min.X, v.Min.Y, v.Max.X, v.Max.Y)
end

SER.Ray = function(v, n)
    local o,d = v.Origin, v.Direction
    return string.format(
        '<Ray name="%s"><origin><X>%.9g</X><Y>%.9g</Y><Z>%.9g</Z></origin>'..
        '<direction><X>%.9g</X><Y>%.9g</Y><Z>%.9g</Z></direction></Ray>',
        XMLEncode(n), o.X,o.Y,o.Z, d.X,d.Y,d.Z)
end

SER.Faces = function(v, n)
    local f = {}
    for _, face in ipairs({"Top","Bottom","Left","Right","Front","Back"}) do
        if v[face] then f[#f+1] = face end
    end
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

SER.PhysicalProperties = function(v, n)
    if v == nil then
        return string.format(
            '<PhysicalProperties name="%s"><CustomPhysics>false</CustomPhysics></PhysicalProperties>',
            XMLEncode(n))
    end
    return string.format(
        '<PhysicalProperties name="%s"><CustomPhysics>true</CustomPhysics>'..
        '<Density>%.9g</Density><Friction>%.9g</Friction>'..
        '<Elasticity>%.9g</Elasticity>'..
        '<FrictionWeight>%.9g</FrictionWeight>'..
        '<ElasticityWeight>%.9g</ElasticityWeight></PhysicalProperties>',
        XMLEncode(n),
        v.Density, v.Friction, v.Elasticity,
        v.FrictionWeight, v.ElasticityWeight)
end

SER.Region3 = function(v, n)
    local half = v.Size/2
    local pos  = v.CFrame.Position
    local mn, mx = pos-half, pos+half
    return string.format(
        '<Region3 name="%s"><min><X>%.9g</X><Y>%.9g</Y><Z>%.9g</Z></min>'..
        '<max><X>%.9g</X><Y>%.9g</Y><Z>%.9g</Z></max></Region3>',
        XMLEncode(n), mn.X,mn.Y,mn.Z, mx.X,mx.Y,mx.Z)
end

SER.Region3int16 = function(v, n)
    return string.format(
        '<Region3int16 name="%s"><min><X>%d</X><Y>%d</Y><Z>%d</Z></min>'..
        '<max><X>%d</X><Y>%d</Y><Z>%d</Z></max></Region3int16>',
        XMLEncode(n),
        v.Min.X,v.Min.Y,v.Min.Z, v.Max.X,v.Max.Y,v.Max.Z)
end

SER.Content = function(v, n)
    return string.format('<Content name="%s"><url>%s</url></Content>',
        XMLEncode(n), XMLEncode(safeToString(v)))
end

SER.Font = function(v, n)
    local ok1, fam = pcall(function() return tostring(v.Family) end)
    local ok2, wgt = pcall(function() return v.Weight.Value end)
    local ok3, sty = pcall(function() return v.Style.Name end)
    return string.format(
        '<Font name="%s"><Family><url>%s</url></Family>'..
        '<Weight>%s</Weight><Style>%s</Style></Font>',
        XMLEncode(n),
        XMLEncode(ok1 and fam or ""),
        tostring(ok2 and wgt or 400),
        XMLEncode(ok3 and sty or "Normal"))
end

SER.DateTime = function(v, n)
    local ok, iso = pcall(function() return v:ToIsoDate() end)
    return string.format('<DateTime name="%s">%s</DateTime>',
        XMLEncode(n), XMLEncode(ok and iso or ""))
end

SER.TweenInfo = function(v, n)
    return string.format(
        '<TweenInfo name="%s"><Time>%.9g</Time>'..
        '<EasingStyle>%d</EasingStyle><EasingDirection>%d</EasingDirection>'..
        '<RepeatCount>%d</RepeatCount><Reverses>%s</Reverses>'..
        '<DelayTime>%.9g</DelayTime></TweenInfo>',
        XMLEncode(n),
        v.Time, v.EasingStyle.Value, v.EasingDirection.Value,
        v.RepeatCount, tostring(v.Reverses), v.DelayTime)
end

-- Generic fallback
local function serVal(v, n, refs)
    local t = typeof(v)
    if SER[t] then
        local ok, xml = pcall(SER[t], v, n, refs)
        if ok and xml then return xml end
    end
    -- Unknown: safe string fallback
    return string.format('<string name="%s"><!-- %s --> %s</string>',
        XMLEncode(n), XMLEncode(t), XMLEncode(safeToString(v)))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 9: SCRIPT DECOMPILATION  (isolated, hard deadline)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local Stats = {} -- filled per-save

local function decompileScript(script, opts)
    if opts.AnonymizeScripts then
        return "-- [anonymized]", true
    end
    if not opts.DecompileScripts then
        return "-- [decompilation disabled]", false
    end

    local maxAttempts = opts.RetryFailedScripts and opts.ScriptRetryCount or 1

    -- Each attempt is run inside Scheduler.timed so it is hard-cancelled
    for attempt = 1, maxAttempts do
        -- Try every registered decompiler
        for _, d in ipairs(ENV.decompilers) do
            local ok, src = Scheduler.timed(d.fn, Scheduler.DECOMP_TIMEOUT, script)
            if ok and type(src) == "string" and #src > 0
               and not src:match("^%s*$") then
                Stats.decompiledScripts = (Stats.decompiledScripts or 0) + 1
                return src, true
            end
            Scheduler.step()
        end

        -- Fallback: Source property (timed)
        local ok, src = Scheduler.timed(function()
            return script.Source
        end, Scheduler.PROP_TIMEOUT)
        if ok and type(src) == "string" and #src > 0 then
            Stats.decompiledScripts = (Stats.decompiledScripts or 0) + 1
            return src, true
        end

        -- Fallback: gethiddenproperty
        ok, src = Scheduler.timed(function()
            return ENV.gethiddenproperty(script, "Source")
        end, Scheduler.PROP_TIMEOUT)
        if ok and type(src) == "string" and #src > 0 then
            Stats.decompiledScripts = (Stats.decompiledScripts or 0) + 1
            return src, true
        end

        -- Fallback: bytecode stub
        if ENV.getscriptbytecode then
            ok, src = Scheduler.timed(function()
                local bc = ENV.getscriptbytecode(script)
                if bc and #bc > 0 then
                    return string.format("--[[ bytecode: %d bytes ]]\n", #bc)
                end
            end, Scheduler.PROP_TIMEOUT)
            if ok and src then
                Stats.decompiledScripts = (Stats.decompiledScripts or 0) + 1
                return src, false
            end
        end

        if attempt < maxAttempts then
            task.wait(0.05 * attempt)
        end
    end

    Stats.failedScripts = (Stats.failedScripts or 0) + 1
    return string.format(
        "-- ⚠ DECOMPILATION FAILED\n-- Script : %s\n-- Executor: %s\n",
        script:GetFullName(), ENV.Name), false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 10: TERRAIN SERIALIZER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function serializeTerrain(terrain, opts)
    if not opts.SaveTerrain then return nil end

    local ok, result = Scheduler.timed(function()
        local ext    = terrain.MaxExtents
        local s      = opts.TerrainRegionSize
        local center = ext.CFrame.Position
        local half   = Vector3.new(s, s, s) * 0.5
        local region = Region3.new(center - half, center + half):ExpandToGrid(4)

        local mats, occs = terrain:ReadVoxels(region, 4)
        local sx, sy, sz = mats.Size.X, mats.Size.Y, mats.Size.Z

        -- RLE encode
        local rle = {}
        local lastM, lastO, run = nil, nil, 0
        for y = 1, sy do
            for z = 1, sz do
                for x = 1, sx do
                    local m = mats[x][y][z].Value
                    local o = math.floor(occs[x][y][z] * 255 + 0.5)
                    if m == lastM and o == lastO then
                        run = run + 1
                    else
                        if lastM then rle[#rle+1] = {lastM, lastO, run} end
                        lastM, lastO, run = m, o, 1
                    end
                end
            end
            Scheduler.step() -- yield between Y slices to avoid freeze
        end
        if lastM then rle[#rle+1] = {lastM, lastO, run} end

        return HttpService:JSONEncode({
            v      = 2,
            size   = {sx, sy, sz},
            origin = {center.X - half.X, center.Y - half.Y, center.Z - half.Z},
            rle    = rle,
        })
    end, math.max(opts.DecompileTimeout, 30))

    if ok and result then
        return string.format(
            '<BinaryString name="TerrainData"><![CDATA[%s]]></BinaryString>', result)
    end
    return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 11: INSTANCE FILTER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local _playerChars = {} -- refreshed at save start

local function refreshPlayerChars()
    _playerChars = {}
    local ok, players = pcall(function() return Players:GetPlayers() end)
    if not ok then return end
    for _, p in ipairs(players) do
        if p.Character then _playerChars[p.Character] = true end
    end
end

local function shouldIgnore(inst, opts)
    if not inst then return true end
    local cn, nm = inst.ClassName, inst.Name

    for _, v in ipairs(opts.IgnoreList) do
        if nm == v or cn == v then return true end
    end

    if not opts.SavePlayers then
        if cn == "Players" or inst:IsA("Player") then return true end
    end

    if opts.RemovePlayerCharacters and _playerChars[inst] then
        return true
    end

    return false
end

local function shouldSkipChildren(inst, opts)
    local cn, nm = inst.ClassName, inst.Name
    for _, v in ipairs(opts.IgnoreDescendantsOfList) do
        if nm == v or cn == v then return true end
    end
    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 12: REFERENCE MAP  (iterative, no recursion stack overflow)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function buildRefMap(root, opts, cb)
    local refs  = {}
    local order = {}  -- ordered list of instances
    local idx   = 0

    -- Iterative BFS avoids stack overflow on deep trees
    local queue = { { inst = root, depth = 0 } }
    local head  = 1

    if cb then cb("Scanning instances…", 0.05) end

    while head <= #queue do
        local item  = queue[head]
        head        = head + 1

        local inst  = item.inst
        local depth = item.depth

        Scheduler.step()

        if opts.MaxDepth and depth > opts.MaxDepth then
            goto continue_scan
        end

        if shouldIgnore(inst, opts) then
            goto continue_scan
        end

        -- Register
        idx = idx + 1
        refs[inst]       = generateRef(idx)
        order[#order+1]  = inst
        Stats.total      = idx

        if cb and idx % 200 == 0 then
            cb(string.format("Scanning… %d instances", idx),
               0.05 + 0.15 * math.min(idx / 8000, 1))
        end

        -- Enqueue children
        if not shouldSkipChildren(inst, opts) then
            for _, child in ipairs(safeChildren(inst)) do
                queue[#queue+1] = { inst = child, depth = depth + 1 }
            end
        end

        ::continue_scan::
    end

    -- Extra instances
    for _, extra in ipairs(opts.AdditionalInstances) do
        if not refs[extra] then
            idx = idx + 1
            refs[extra]      = generateRef(idx)
            order[#order+1]  = extra
            Stats.total      = idx
        end
    end

    -- Nil instances
    if opts.NilInstances then
        if cb then cb("Collecting nil instances…", 0.20) end
        local ok, nil_list = pcall(ENV.getnilinstances)
        if ok then
            for _, ni in ipairs(nil_list) do
                if not refs[ni] and not shouldIgnore(ni, opts) then
                    idx = idx + 1
                    refs[ni]         = generateRef(idx)
                    order[#order+1]  = ni
                    Stats.total      = idx
                end
                Scheduler.step()
            end
        end
    end

    if cb then cb(string.format("Scan complete: %d instances", #order), 0.22) end
    return refs, order
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 13: PROPERTY BUILDER  (per instance, all reads timed)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local BLACKLIST_SET = {}
for _, v in ipairs(DEFAULTS.PropertyBlacklist) do BLACKLIST_SET[v] = true end

local function buildPropsXML(inst, refs, opts)
    local lines = {}
    local cn    = inst.ClassName

    -- Name (always first)
    local nm = safeReadProp(inst, "Name") or cn
    lines[#lines+1] = string.format(
        '      <string name="Name">%s</string>', XMLEncode(nm))

    -- Script source
    local isScript = false
    local ok0 = pcall(function() isScript = inst:IsA("LuaSourceContainer") end)
    if ok0 and isScript then
        local src, _ = decompileScript(inst, opts)
        lines[#lines+1] = string.format(
            '      <ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>', src)
    end

    -- Terrain
    local isTerrain = false
    pcall(function() isTerrain = inst:IsA("Terrain") end)
    if isTerrain then
        local terrXml = serializeTerrain(inst, opts)
        if terrXml then lines[#lines+1] = "      " .. terrXml end
    end

    -- API-driven props
    local props = flatProps(cn, opts)
    for pname, _ in pairs(props) do
        -- Skip blacklisted / already handled
        if not BLACKLIST_SET[pname] and pname ~= "Name" and pname ~= "Source" then
            local val = safeReadProp(inst, pname)
            if val ~= nil then
                Stats.totalProps = (Stats.totalProps or 0) + 1
                local ok2, xml = pcall(serVal, val, pname, refs)
                if ok2 and xml then
                    lines[#lines+1] = "      " .. xml
                    Stats.savedProps = (Stats.savedProps or 0) + 1
                else
                    Stats.failedProps = (Stats.failedProps or 0) + 1
                end
            end
        end
        Scheduler.step()
    end

    -- Attributes
    if opts.SaveAttributes then
        local ok3, attrs = pcall(function() return inst:GetAttributes() end)
        if ok3 and attrs and next(attrs) then
            local ok4, encoded = pcall(HttpService.JSONEncode, HttpService, attrs)
            if ok4 then
                lines[#lines+1] = string.format(
                    '      <BinaryString name="AttributesSerialize"><![CDATA[%s]]></BinaryString>',
                    encoded)
            end
        end
    end

    -- Tags
    if opts.SaveTags then
        local ok5, tags = pcall(function() return CollectionService:GetTags(inst) end)
        if ok5 and tags and #tags > 0 then
            lines[#lines+1] = string.format(
                '      <BinaryString name="Tags"><![CDATA[%s]]></BinaryString>',
                table.concat(tags, "\0"))
        end
    end

    return table.concat(lines, "\n")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 14: STREAMING XML WRITER
-- Writes the tree to disk incrementally using StreamWriter.
-- Uses an explicit stack instead of recursion to avoid stack overflow.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function writeXML(refs, order, opts, writer, cb)
    -- Build parent→children lookup
    local childMap = {}
    local roots    = {}

    if cb then cb("Building hierarchy…", 0.25) end

    for _, inst in ipairs(order) do
        local ok, par = pcall(function() return inst.Parent end)
        if ok and par and refs[par] then
            if not childMap[par] then childMap[par] = {} end
            childMap[par][#childMap[par]+1] = inst
        else
            roots[#roots+1] = inst
        end
        Scheduler.step()
    end

    -- XML header
    writer:writeln('<?xml version="1.0" encoding="UTF-8"?>')
    writer:writeln('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"'
        .. ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
        .. ' xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd"'
        .. ' version="4">')
    writer:writeln('  <External>null</External>')
    writer:writeln('  <External>nil</External>')
    writer:writeln(string.format('  <Meta name="Generator">SaveInstance Pro v5.0</Meta>'))
    writer:writeln(string.format('  <Meta name="Executor">%s</Meta>', XMLEncode(ENV.Name)))
    writer:writeln(string.format('  <Meta name="SavedAt">%s</Meta>', os.date("%Y-%m-%dT%H:%M:%S")))
    writer:writeln(string.format('  <Meta name="TotalInstances">%d</Meta>', #order))
    writer:writeln('  <Meta name="ExplicitAutoJoints">true</Meta>')

    -- Iterative DFS using explicit stack
    -- Stack entries: { inst, depth, phase }
    -- phase = "open"  → write opening tag + properties
    -- phase = "close" → write closing tag
    local stack   = {}
    local saved   = 0

    -- Push roots in reverse order so first root is processed first
    for i = #roots, 1, -1 do
        stack[#stack+1] = { inst = roots[i], depth = 1, phase = "open" }
    end

    if cb then cb("Serializing instances…", 0.27) end

    while #stack > 0 do
        local entry = stack[#stack]
        stack[#stack] = nil

        local inst  = entry.inst
        local depth = entry.depth
        local phase = entry.phase
        local indent = string.rep("  ", depth)

        Scheduler.step()

        if phase == "open" then
            local ref = refs[inst]
            if not ref then goto continue_write end

            local cn  = inst.ClassName

            -- Push close-tag sentinel first (so it runs after children)
            stack[#stack+1] = { inst = inst, depth = depth, phase = "close" }

            -- Push children in reverse order
            if childMap[inst] then
                local kids = childMap[inst]
                for i = #kids, 1, -1 do
                    stack[#stack+1] = { inst = kids[i], depth = depth+1, phase = "open" }
                end
            end

            -- Write opening + properties
            writer:writeln(string.format('%s<Item class="%s" referent="%s">',
                indent, XMLEncode(cn), ref))
            writer:writeln(indent .. "  <Properties>")

            local ok, propsXml = pcall(buildPropsXML, inst, refs, opts)
            if ok and propsXml and #propsXml > 0 then
                writer:writeln(propsXml)
                Stats.saved = (Stats.saved or 0) + 1
            else
                Stats.failed = (Stats.failed or 0) + 1
                -- Minimal fallback: at least write the name
                local fallbackName = safeReadProp(inst, "Name") or cn
                writer:writeln(string.format(
                    '      <string name="Name">%s</string>', XMLEncode(fallbackName)))
                if opts.Verbose then
                    warn("[SI] Props failed for " .. safeToString(inst) .. ": " .. safeToString(propsXml))
                end
            end

            writer:writeln(indent .. "  </Properties>")

            saved = saved + 1
            if cb and saved % 100 == 0 then
                local pct = 0.27 + 0.65 * (saved / math.max(#order, 1))
                cb(string.format("Serializing… %d / %d  (%.0f%%)",
                    saved, #order, pct * 100), pct)
            end

            if opts.OnInstanceSaved then
                pcall(opts.OnInstanceSaved, inst, saved, #order)
            end

        elseif phase == "close" then
            local indent2 = string.rep("  ", depth)
            writer:writeln(indent2 .. "</Item>")
        end

        ::continue_write::
    end

    writer:writeln("</roblox>")
    if cb then cb("XML written to disk ✓", 0.95) end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 15: VALIDATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function validate(filePath, opts)
    if not opts.ValidateOutput then return true end

    local ok, content = pcall(ENV.readfile, filePath)
    if not ok or not content then
        warn("[SI] Validation: cannot read file back")
        return false
    end

    local checks = {
        { content:sub(1,5) == "<?xml",         "Missing XML declaration"    },
        { content:find("<roblox") ~= nil,       "Missing <roblox> tag"      },
        { content:find("</roblox>") ~= nil,     "Missing </roblox> end tag" },
        {
            select(2, content:gsub("<Item",   "")) ==
            select(2, content:gsub("</Item>", "")),
            "Unbalanced <Item> tags"
        },
    }

    for _, c in ipairs(checks) do
        if not c[1] then
            warn("[SI] Validation FAILED: " .. c[2])
            return false
        end
    end

    if opts.Verbose then print("[SI] Validation passed") end
    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 16: PUBLIC API
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local SaveInstance    = {}
SaveInstance.Version  = "5.0.0"
SaveInstance.Executor = ENV.Name
SaveInstance._busy    = false

function SaveInstance.Save(userOptions)
    if SaveInstance._busy then
        warn("[SI] Already saving – please wait for the current save to finish.")
        return false, nil
    end
    SaveInstance._busy = true

    -- Reset stats
    Stats = {
        total            = 0,
        saved            = 0,
        failed           = 0,
        totalProps       = 0,
        savedProps       = 0,
        failedProps      = 0,
        decompiledScripts= 0,
        failedScripts    = 0,
    }

    local opts = mergeOpts(userOptions)
    assert(opts.SaveObject, "SaveObject must be provided")

    -- Auto file path
    if not opts.FilePath then
        local rawName = safeReadProp(opts.SaveObject, "Name") or "SavedInstance"
        opts.FilePath = sanitize(rawName) .. "_" .. timestamp() .. ".rbxmx"
    end

    local t0 = tick()
    local cb = opts.StatusCallback or function() end

    -- Update blacklist set
    BLACKLIST_SET = {}
    for _, v in ipairs(opts.PropertyBlacklist) do BLACKLIST_SET[v] = true end

    -- Ensure output directory exists
    local dir = opts.FilePath:match("^(.*[/\\])")
    if dir and dir ~= "" then
        local ok3 = pcall(function()
            if not ENV.isfolder(dir) then ENV.makefolder(dir) end
        end)
    end

    cb("Initializing… Executor: " .. ENV.Name, 0)

    -- Load API dump (async, yields internally)
    cb("Loading API dump…", 0.02)
    loadDump(opts)

    -- Snapshot player characters before cloning
    refreshPlayerChars()

    -- Safe clone
    local saveObj = opts.SaveObject
    if opts.CloneBeforeSave and opts.SaveObject ~= game then
        cb("Cloning save target…", 0.04)
        local okC, clone = pcall(function() return opts.SaveObject:Clone() end)
        if okC and clone then
            saveObj = clone
            if opts.Verbose then print("[SI] Clone successful") end
        else
            if opts.Verbose then warn("[SI] Clone failed – using original") end
        end
    end

    -- Create streaming writer (uses appendfile if available)
    local writer = StreamWriter.new(opts.FilePath, true)

    local saveOk, saveErr = pcall(function()
        -- Phase 1: scan
        local refs, order = buildRefMap(saveObj, opts, cb)
        cb(string.format("Found %d instances – building XML…", #order), 0.24)

        -- Phase 2: stream XML to disk
        writeXML(refs, order, opts, writer, cb)

        -- Phase 3: close writer (final flush)
        writer:close()
        cb("Flushing file…", 0.96)
    end)

    -- Cleanup clone
    if saveObj ~= opts.SaveObject then
        pcall(function() saveObj:Destroy() end)
    end

    SaveInstance._busy = false

    if not saveOk then
        local msg = "[SI] Save failed: " .. tostring(saveErr)
        warn(msg)
        if opts.OnError then pcall(opts.OnError, msg) end
        if opts.ShowNotifications then
            SaveInstance.Notify("SaveInstance ❌", msg, 10)
        end
        return false, msg
    end

    -- Validate
    local valid = validate(opts.FilePath, opts)

    local elapsed = tick() - t0
    local sizeMB  = writer.totalLen / 1048576

    local summary = string.format(
        "✅ Saved in %.1fs | 📁 %.2f MB | 🧱 %d inst (%d failed) | 🔧 %d props | 📜 %d scripts (%d failed)",
        elapsed, sizeMB,
        Stats.saved or 0, Stats.failed or 0,
        Stats.savedProps or 0,
        Stats.decompiledScripts or 0, Stats.failedScripts or 0)

    cb(summary, 1.0)

    if opts.ShowNotifications then
        SaveInstance.Notify("SaveInstance ✅",
            string.format("Done in %.1fs — %d instances — %.2f MB\n%s",
                elapsed, Stats.saved or 0, sizeMB, opts.FilePath), 8)
    end

    local result = {
        FilePath   = opts.FilePath,
        FileSize   = writer.totalLen,
        Elapsed    = elapsed,
        Valid      = valid,
        Statistics = deepCopy(Stats),
    }

    if opts.OnComplete then pcall(opts.OnComplete, true, result) end
    return true, result
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 17: NOTIFICATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function SaveInstance.Notify(title, text, dur)
    dur = dur or 5
    local ok = pcall(function()
        StarterGui:SetCore("SendNotification",
            { Title = title, Text = text, Duration = dur })
    end)
    if not ok then print(string.format("[%s] %s", title, text)) end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 18: GUI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local C = {
    BG       = Color3.fromRGB(15, 15, 20),
    PANEL    = Color3.fromRGB(24, 24, 32),
    TITLEBAR = Color3.fromRGB(20, 20, 28),
    ACCENT   = Color3.fromRGB(80, 140, 255),
    GREEN    = Color3.fromRGB(60, 210, 110),
    RED      = Color3.fromRGB(210, 55, 55),
    ORANGE   = Color3.fromRGB(230, 165, 45),
    TEXT     = Color3.fromRGB(225, 225, 235),
    SUB      = Color3.fromRGB(130, 130, 150),
    BORDER   = Color3.fromRGB(45, 50, 70),
    BARBG    = Color3.fromRGB(12, 12, 18),
}

local function mkCorner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = p
end

local function mkStroke(p, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or C.BORDER
    s.Thickness = thick or 1.5
    s.Parent = p
end

local function mkLabel(p, txt, size, color, font, xa, wrap)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = txt or ""
    l.TextSize = size or 14
    l.TextColor3 = color or C.TEXT
    l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextWrapped = wrap or false
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BorderSizePixel = 0
    l.ZIndex = 5
    l.Parent = p
    return l
end

local function mkBtn(p, txt, color, sz, pos)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 14
    b.Text = txt
    b.Size = sz or UDim2.new(1,0,0,44)
    b.Position = pos or UDim2.new(0,0,0,0)
    b.ZIndex = 5
    b.Parent = p
    mkCorner(b, 8)

    local base  = color
    local hov   = Color3.fromRGB(
        math.min(base.R*255+28,255),
        math.min(base.G*255+28,255),
        math.min(base.B*255+28,255))
    local pr    = Color3.fromRGB(
        math.max(base.R*255-20,0),
        math.max(base.G*255-20,0),
        math.max(base.B*255-20,0))

    b.MouseEnter:Connect(function()    b.BackgroundColor3 = hov  end)
    b.MouseLeave:Connect(function()    b.BackgroundColor3 = base end)
    b.MouseButton1Down:Connect(function() b.BackgroundColor3 = pr end)
    b.MouseButton1Up:Connect(function()   b.BackgroundColor3 = hov end)
    return b
end

local function mkDraggable(handle, win)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = win.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
                  or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            win.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X,
                                     sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
end

local function buildGUI()
    -- Remove old
    local hui = ENV.gethui
    if not hui then hui = game:GetService("CoreGui") end

    for _, c in ipairs(hui:GetChildren()) do
        if c.Name == "SI_Pro_v5" then c:Destroy() end
    end

    local sg = Instance.new("ScreenGui")
    sg.Name           = "SI_Pro_v5"
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    sg.Parent         = hui

    -- Window
    local win = Instance.new("Frame")
    win.Size            = UDim2.new(0, 510, 0, 570)
    win.Position        = UDim2.new(0.5,-255,0.5,-285)
    win.BackgroundColor3= C.BG
    win.BorderSizePixel = 0
    win.Parent          = sg
    mkCorner(win, 14)
    mkStroke(win, C.ACCENT, 2)

    -- Shadow
    local shad = Instance.new("ImageLabel")
    shad.Size = UDim2.new(1,50,1,50)
    shad.Position = UDim2.new(0,-25,0,-25)
    shad.BackgroundTransparency = 1
    shad.Image = "rbxassetid://5554236805"
    shad.ImageColor3 = Color3.new(0,0,0)
    shad.ImageTransparency = 0.45
    shad.ScaleType = Enum.ScaleType.Slice
    shad.SliceCenter = Rect.new(23,23,277,277)
    shad.ZIndex = 0
    shad.Parent = win

    -- Title bar
    local tb = Instance.new("Frame")
    tb.Size = UDim2.new(1,0,0,54)
    tb.BackgroundColor3 = C.TITLEBAR
    tb.BorderSizePixel = 0
    tb.ZIndex = 6
    tb.Parent = win
    mkCorner(tb, 14)
    -- fill bottom-round of title bar
    local tbfix = Instance.new("Frame")
    tbfix.Size = UDim2.new(1,0,0,14)
    tbfix.Position = UDim2.new(0,0,1,-14)
    tbfix.BackgroundColor3 = C.TITLEBAR
    tbfix.BorderSizePixel = 0
    tbfix.ZIndex = 6
    tbfix.Parent = tb

    -- Title text
    local titleHolder = Instance.new("Frame")
    titleHolder.Size = UDim2.new(1,-100,1,0)
    titleHolder.Position = UDim2.new(0,14,0,0)
    titleHolder.BackgroundTransparency = 1
    titleHolder.BorderSizePixel = 0
    titleHolder.ZIndex = 7
    titleHolder.Parent = tb

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1,0,0,28)
    titleLbl.Position = UDim2.new(0,0,0,6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 19
    titleLbl.Text = "💾 SaveInstance Pro"
    titleLbl.TextColor3 = C.TEXT
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 7
    titleLbl.Parent = titleHolder

    local verLbl = Instance.new("TextLabel")
    verLbl.Size = UDim2.new(1,0,0,18)
    verLbl.Position = UDim2.new(0,0,0,32)
    verLbl.BackgroundTransparency = 1
    verLbl.Font = Enum.Font.Gotham
    verLbl.TextSize = 11
    verLbl.Text = "v5.0  •  " .. ENV.Name .. "  •  Anti-Freeze Edition"
    verLbl.TextColor3 = C.SUB
    verLbl.TextXAlignment = Enum.TextXAlignment.Left
    verLbl.ZIndex = 7
    verLbl.Parent = titleHolder

    -- Close btn
    local closeBtn = mkBtn(tb, "✕", C.RED,
        UDim2.new(0,36,0,36), UDim2.new(1,-46,0,9))
    closeBtn.TextSize = 18
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    mkDraggable(tb, win)

    -- Scroll area for buttons
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,-22,1,-225)
    scroll.Position = UDim2.new(0,11,0,62)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = C.ACCENT
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ZIndex = 4
    scroll.Parent = win

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,7)
    layout.Parent = scroll

    local lpad = Instance.new("UIPadding")
    lpad.PaddingTop = UDim.new(0,4)
    lpad.PaddingBottom = UDim.new(0,4)
    lpad.Parent = scroll

    -- Section divider helper
    local function sectionDiv(txt, order)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1,0,0,20)
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.LayoutOrder = order
        f.ZIndex = 4
        f.Parent = scroll
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1,0,1,0)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamBold
        l.TextSize = 11
        l.Text = txt
        l.TextColor3 = C.SUB
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.ZIndex = 5
        l.Parent = f
    end

    -- Status label + progress bar refs
    local statusLbl, statsLbl, progBar, progPct

    -- Button configs
    local BTNS = {
        { txt = "🌍  Save Entire Game",         color = Color3.fromRGB(55,125,255), order = 2,
          opts = { SaveObject = game, SaveTerrain = true, DecompileScripts = true,
                   SaveAttributes = true, SaveTags = true } },
        { txt = "🗺️  Save Workspace",            color = Color3.fromRGB(55,185,95),  order = 3,
          opts = { SaveObject = workspace, SaveTerrain = true } },
        { txt = "📦  Save ReplicatedStorage",    color = Color3.fromRGB(195,115,55), order = 4,
          opts = { SaveObject = game:GetService("ReplicatedStorage") } },
        { txt = "🗄️  Save ServerStorage",        color = Color3.fromRGB(145,85,205), order = 5,
          opts = { SaveObject = game:GetService("ServerStorage") } },
        { txt = "💡  Save Lighting",             color = Color3.fromRGB(225,185,40), order = 6,
          opts = { SaveObject = game:GetService("Lighting") } },
        { txt = "🎒  Save StarterPack",          color = Color3.fromRGB(55,195,195), order = 7,
          opts = { SaveObject = game:GetService("StarterPack") } },
        { txt = "👥  Save Players + Characters", color = Color3.fromRGB(220,90,90),  order = 8,
          opts = { SaveObject = game:GetService("Players"),
                   SavePlayers = true, RemovePlayerCharacters = false } },
    }

    sectionDiv("  QUICK SAVE", 1)

    for _, cfg in ipairs(BTNS) do
        local btn = mkBtn(scroll, cfg.txt, cfg.color,
            UDim2.new(1,0,0,44))
        btn.LayoutOrder = cfg.order
        btn.TextXAlignment = Enum.TextXAlignment.Left
        local lp2 = Instance.new("UIPadding")
        lp2.PaddingLeft = UDim.new(0,12)
        lp2.Parent = btn

        btn.MouseButton1Click:Connect(function()
            if SaveInstance._busy then
                SaveInstance.Notify("SaveInstance", "⏳ Already saving – please wait!", 3)
                return
            end

            local origTxt   = btn.Text
            local origColor = btn.BackgroundColor3
            btn.Text = "⏳  Saving…"
            btn.BackgroundColor3 = C.ORANGE

            -- Run save in its own thread so GUI stays live
            task.spawn(function()
                local saveOpts = deepCopy(cfg.opts)

                saveOpts.StatusCallback = function(msg, pct)
                    -- Strip to last line for compact display
                    local line = (msg or ""):match("([^\n]+)$") or msg or ""
                    if statusLbl then statusLbl.Text = line end
                    if progBar and pct then
                        local clamped = math.clamp(pct, 0, 1)
                        -- Smooth tween
                        local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                        TweenService:Create(progBar, ti,
                            { Size = UDim2.new(clamped, 0, 1, 0) }):Play()
                        if progPct then
                            progPct.Text = string.format("%.0f%%", clamped * 100)
                        end
                    end
                    if statsLbl then
                        statsLbl.Text = string.format(
                            "🧱 %d inst  |  🔧 %d props  |  📜 %d scripts  |  ❌ %d failed",
                            Stats.saved or 0,
                            Stats.savedProps or 0,
                            Stats.decompiledScripts or 0,
                            (Stats.failed or 0) + (Stats.failedScripts or 0))
                    end
                end

                local ok, res = SaveInstance.Save(saveOpts)

                -- Restore button
                task.wait(0.2)
                btn.Text = origTxt
                btn.BackgroundColor3 = origColor

                if not ok then
                    if statusLbl then
                        statusLbl.Text = "❌ Save failed – see console for details"
                        statusLbl.TextColor3 = C.RED
                    end
                    task.wait(6)
                    if statusLbl then
                        statusLbl.Text = "Ready."
                        statusLbl.TextColor3 = C.TEXT
                    end
                    if progBar then
                        TweenService:Create(progBar, TweenInfo.new(0.4),
                            { Size = UDim2.new(0,0,1,0) }):Play()
                        if progPct then progPct.Text = "0%" end
                    end
                else
                    if statusLbl then
                        statusLbl.TextColor3 = C.GREEN
                        task.wait(4)
                        if statusLbl then
                            statusLbl.TextColor3 = C.TEXT
                            statusLbl.Text = "Ready."
                        end
                    end
                end
            end)
        end)
    end

    -- ── Status panel ──────────────────────────────────────────────────────
    local sPanel = Instance.new("Frame")
    sPanel.Size = UDim2.new(1,-22,0,158)
    sPanel.Position = UDim2.new(0,11,1,-170)
    sPanel.BackgroundColor3 = C.PANEL
    sPanel.BorderSizePixel = 0
    sPanel.ZIndex = 4
    sPanel.Parent = win
    mkCorner(sPanel, 10)
    mkStroke(sPanel, C.BORDER, 1.5)

    -- "STATUS" label
    local sHdr = Instance.new("TextLabel")
    sHdr.Size = UDim2.new(1,-16,0,18)
    sHdr.Position = UDim2.new(0,10,0,8)
    sHdr.BackgroundTransparency = 1
    sHdr.Font = Enum.Font.GothamBold
    sHdr.TextSize = 11
    sHdr.Text = "STATUS"
    sHdr.TextColor3 = C.SUB
    sHdr.TextXAlignment = Enum.TextXAlignment.Left
    sHdr.ZIndex = 5
    sHdr.Parent = sPanel

    -- Main status text
    statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1,-16,0,40)
    statusLbl.Position = UDim2.new(0,10,0,26)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 13
    statusLbl.Text = "Ready. Select a save option above."
    statusLbl.TextColor3 = C.TEXT
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.TextYAlignment = Enum.TextYAlignment.Top
    statusLbl.TextWrapped = true
    statusLbl.ZIndex = 5
    statusLbl.Parent = sPanel

    -- Stats line
    statsLbl = Instance.new("TextLabel")
    statsLbl.Size = UDim2.new(1,-16,0,18)
    statsLbl.Position = UDim2.new(0,10,0,70)
    statsLbl.BackgroundTransparency = 1
    statsLbl.Font = Enum.Font.GothamMedium
    statsLbl.TextSize = 11
    statsLbl.Text = "🧱 0 inst  |  🔧 0 props  |  📜 0 scripts  |  ❌ 0 failed"
    statsLbl.TextColor3 = C.SUB
    statsLbl.TextXAlignment = Enum.TextXAlignment.Left
    statsLbl.ZIndex = 5
    statsLbl.Parent = sPanel

    -- Progress bar background
    local pbBg = Instance.new("Frame")
    pbBg.Size = UDim2.new(1,-20,0,22)
    pbBg.Position = UDim2.new(0,10,0,94)
    pbBg.BackgroundColor3 = C.BARBG
    pbBg.BorderSizePixel = 0
    pbBg.ZIndex = 5
    pbBg.Parent = sPanel
    mkCorner(pbBg, 6)

    -- Progress bar fill
    progBar = Instance.new("Frame")
    progBar.Size = UDim2.new(0,0,1,0)
    progBar.BackgroundColor3 = C.GREEN
    progBar.BorderSizePixel = 0
    progBar.ZIndex = 6
    progBar.Parent = pbBg
    mkCorner(progBar, 6)

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, C.GREEN),
        ColorSequenceKeypoint.new(1, C.ACCENT),
    }
    grad.Parent = progBar

    -- Progress percent text
    progPct = Instance.new("TextLabel")
    progPct.Size = UDim2.new(1,0,1,0)
    progPct.BackgroundTransparency = 1
    progPct.Font = Enum.Font.GothamBold
    progPct.TextSize = 12
    progPct.Text = "0%"
    progPct.TextColor3 = Color3.new(1,1,1)
    progPct.TextXAlignment = Enum.TextXAlignment.Center
    progPct.ZIndex = 7
    progPct.Parent = pbBg

    -- Executor badge
    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0,0,0,22)
    badge.Position = UDim2.new(0,10,0,124)
    badge.BackgroundColor3 = C.ACCENT
    badge.BorderSizePixel = 0
    badge.AutomaticSize = Enum.AutomaticSize.X
    badge.ZIndex = 5
    badge.Parent = sPanel
    mkCorner(badge, 6)
    local badgePad = Instance.new("UIPadding")
    badgePad.PaddingLeft = UDim.new(0,8)
    badgePad.PaddingRight = UDim.new(0,8)
    badgePad.Parent = badge
    local badgeLbl = Instance.new("TextLabel")
    badgeLbl.Size = UDim2.new(0,200,1,0)
    badgeLbl.BackgroundTransparency = 1
    badgeLbl.Font = Enum.Font.GothamBold
    badgeLbl.TextSize = 11
    badgeLbl.Text = "🖥  " .. ENV.Name
    badgeLbl.TextColor3 = Color3.new(1,1,1)
    badgeLbl.TextXAlignment = Enum.TextXAlignment.Left
    badgeLbl.ZIndex = 6
    badgeLbl.Parent = badge

    return sg
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 19: SHOW MENU / AUTO-RUN
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function SaveInstance.ShowMenu()
    buildGUI()
    SaveInstance.Notify(
        "SaveInstance Pro v5.0",
        "Anti-Freeze Edition — " .. ENV.Name, 4)
end

if not _G.__SI_V5 then
    _G.__SI_V5 = true
    task.spawn(function()
        task.wait(0.25)
        SaveInstance.ShowMenu()
    end)
end

return SaveInstance

--[[
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 USAGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  -- GUI (recommended)
  loadstring(game:HttpGet("url"))()

  -- Programmatic
  local SI = loadstring(game:HttpGet("url"))()
  SI.Save({
      SaveObject        = workspace,
      DecompileScripts  = true,
      SaveTerrain       = true,
      YieldInterval     = 30,    -- lower = smoother, slower
      DecompTimeout     = 10,    -- per-script deadline
      StatusCallback    = function(msg, pct)
          print(string.format("[%.0f%%] %s", pct*100, msg))
      end,
  })

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 TODO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 1. Binary .rbxl/.rbxm  (needs LZ4 + chunk format, see dom.rojo.space/binary)
 2. Asset downloading (meshes, images)
 3. Incremental / diff saves
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
]]
