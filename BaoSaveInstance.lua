--[[
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║                    BaoSaveInstance v3.0 ULTRA                           ║
    ║              Ultimate Roblox Game Decompiler & Exporter                 ║
    ║                                                                          ║
    ║  ◆ 12 API Decompile với Smart Merge & Scoring                          ║
    ║  ◆ Deep Property Extraction & Reconstruction                           ║
    ║  ◆ Bytecode Analysis & Pattern Matching                                ║
    ║  ◆ Anti-Detection & Error Recovery                                     ║
    ║  ◆ Parallel Processing & Memory Optimization                           ║
    ║  ◆ Full Game / Map / Terrain / Scripts / Assets                        ║
    ║  ◆ Advanced GUI với Real-time Analytics                                ║
    ╚══════════════════════════════════════════════════════════════════════════╝
--]]

-- ═══════════════════════════════════════════════════════════════════════
-- PHẦN 1: ADVANCED CONFIG SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local BaoSaveConfig = {
    -- API & Decompile
    PreferredAPI = "AUTO",
    EnableFallback = true,
    EnableSmartMerge = true,
    MergeStrategy = "BEST_SEGMENTS",
    DecompileTimeout = 15,
    MaxRetries = 5,
    RetryDelay = 0.5,
    MinValidSourceLength = 8,
    ParallelBatchSize = 10,

    -- Quality Control
    QualityThreshold = 40,
    EnableDeepAnalysis = true,
    EnableBytecodeRecovery = true,
    EnableConstantExtraction = true,
    EnableUpvalueRecovery = true,
    EnableProtoRecovery = true,

    -- File Output
    SaveScriptsToFolder = true,
    AddTimestampToFileName = false,
    ExportScriptsSubfolder = "BaoSaveInstance_Scripts",
    CreateProjectStructure = true,
    GenerateReport = true,
    CompressOutput = false,

    -- Instance Handling
    IncludePlayerGui = true,
    IncludeNilInstances = true,
    IncludeHiddenProperties = true,
    PreserveAttributes = true,
    PreserveTags = true,
    PreserveScriptDisabled = true,
    SkipCoreScripts = true,
    DeepCloneInstances = true,
    MaxInstanceDepth = 100,
    SaveNonAccessibleServices = true,

    -- Performance
    YieldInterval = 3,
    MemoryLimit = 500,
    EnableGCOptimization = true,
    BatchProcessing = true,

    -- Logging
    VerboseLogging = true,
    LogToFile = true,
    LogFileName = "BaoSaveInstance_Log.txt",

    -- Advanced
    EnableAntiDetection = true,
    ObfuscateAccess = true,
    EnablePropertyWhitelist = false,
    CustomPropertyWhitelist = {},
    EnableSignatureScanning = true,
    EnablePatternRecovery = true,
    EnableCrossReferenceAnalysis = true,
    EnableControlFlowRecovery = true,
}

-- ═══════════════════════════════════════════════════════════════════════
-- PHẦN 2: CORE SYSTEM & SERVICES
-- ═══════════════════════════════════════════════════════════════════════

local BaoSaveInstance = {}
BaoSaveInstance.Config = BaoSaveConfig
BaoSaveInstance.Version = "3.0 ULTRA"
BaoSaveInstance.BuildDate = "2024"
BaoSaveInstance._running = false
BaoSaveInstance._cancelled = false

BaoSaveInstance.Stats = {
    TotalScripts = 0,
    DecompiledScripts = 0,
    FailedScripts = 0,
    PartialScripts = 0,
    MergedScripts = 0,
    TotalInstances = 0,
    TotalProperties = 0,
    TotalAssets = 0,
    BytecodeRecovered = 0,
    ConstantsExtracted = 0,
    UpvaluesRecovered = 0,
    StartTime = 0,
    EndTime = 0,
    MemoryPeak = 0,
    APIUsageStats = {},
    QualityDistribution = {excellent = 0, good = 0, fair = 0, poor = 0, failed = 0},
    ServicesCaptured = {},
    ErrorLog = {},
}

-- Service references with safe access
local Services = {}
local ServiceNames = {
    "Workspace", "Players", "Lighting", "ReplicatedFirst", "ReplicatedStorage",
    "ServerScriptService", "ServerStorage", "StarterGui", "StarterPack",
    "StarterPlayer", "SoundService", "Chat", "LocalizationService",
    "TestService", "Teams", "InsertService", "MarketplaceService",
    "HttpService", "RunService", "TweenService", "UserInputService",
    "CoreGui", "TextChatService", "MaterialService", "PathfindingService",
    "PhysicsService", "CollectionService", "Debris", "TeleportService",
    "BadgeService", "GamePassService", "PolicyService",
}

for _, name in ipairs(ServiceNames) do
    pcall(function()
        Services[name] = game:GetService(name)
    end)
end

local LocalPlayer = Services.Players and Services.Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════════════
-- PHẦN 3: ADVANCED UTILITIES
-- ═══════════════════════════════════════════════════════════════════════

-- ─── Logger System ───
local Logger = {Logs = {}, FileBuffer = {}, EntryCount = 0}

function Logger:Log(level, message, data)
    self.EntryCount = self.EntryCount + 1
    local timestamp = os.date("%H:%M:%S")
    local entry = {
        id = self.EntryCount,
        time = timestamp,
        level = level,
        message = message,
        data = data,
        tick = tick(),
    }

    table.insert(self.Logs, entry)

    local formatted = string.format("[%s] [%s] %s", timestamp, level, message)

    if BaoSaveConfig.VerboseLogging or level ~= "DEBUG" then
        if level == "ERROR" then
            warn("[BaoSaveInstance] " .. formatted)
        else
            print("[BaoSaveInstance] " .. formatted)
        end
    end

    if BaoSaveConfig.LogToFile then
        table.insert(self.FileBuffer, formatted)
    end

    if BaoSaveInstance._UILogCallback then
        pcall(BaoSaveInstance._UILogCallback, formatted, level)
    end
end

function Logger:Info(msg, d) self:Log("INFO", msg, d) end
function Logger:Warn(msg, d) self:Log("WARN", msg, d) end
function Logger:Error(msg, d) self:Log("ERROR", msg, d) end
function Logger:Debug(msg, d) if BaoSaveConfig.VerboseLogging then self:Log("DEBUG", msg, d) end end
function Logger:Success(msg, d) self:Log("SUCCESS", msg, d) end
function Logger:Critical(msg, d) self:Log("CRITICAL", msg, d) end
function Logger:Progress(msg, d) self:Log("PROGRESS", msg, d) end

function Logger:FlushToFile()
    if not BaoSaveConfig.LogToFile or #self.FileBuffer == 0 then return end
    pcall(function()
        if writefile then
            writefile(BaoSaveConfig.LogFileName, table.concat(self.FileBuffer, "\n"))
        end
    end)
end

-- ─── Exploit Environment Detection ───
local ExploitEnv = {
    name = "Unknown",
    hasDecompile = false,
    hasSaveInstance = false,
    hasWriteFile = false,
    hasMakeFolder = false,
    hasReadFile = false,
    hasIsFile = false,
    hasListFiles = false,
    hasDelFile = false,
    hasAppendFile = false,
    hasGetHUI = false,
    hasSetClipboard = false,
    hasGetScripts = false,
    hasGetNilInstances = false,
    hasGetGC = false,
    hasGetInstances = false,
    hasGetConnections = false,
    hasGetHiddenProperty = false,
    hasSetHiddenProperty = false,
    hasGetScriptBytecode = false,
    hasGetScriptHash = false,
    hasGetScriptClosure = false,
    hasGetProtos = false,
    hasGetConstants = false,
    hasGetUpvalues = false,
    hasGetInfo = false,
    hasFireSignal = false,
    hasHookFunction = false,
    hasNewCClosure = false,
    hasIsLClosure = false,
    hasGetRawMetatable = false,
    hasGetNamecallMethod = false,
    capabilities = {},
}

local function DetectExploitEnvironment()
    -- Detect exploit name
    local detectors = {
        function() if syn then return "Synapse X" end end,
        function() if fluxus then return "Fluxus" end end,
        function() if KRNL_LOADED then return "KRNL" end end,
        function() if Celery then return "Celery" end end,
        function() if SENTINEL_V2 then return "Sentinel" end end,
        function() if getexecutorname then return getexecutorname() end end,
        function() if identifyexecutor then return identifyexecutor() end end,
    }

    for _, detect in ipairs(detectors) do
        local s, r = pcall(detect)
        if s and r then ExploitEnv.name = r; break end
    end

    -- Function availability checks
    local checks = {
        {"hasDecompile", {"decompile"}},
        {"hasSaveInstance", {"saveinstance"}},
        {"hasWriteFile", {"writefile"}},
        {"hasMakeFolder", {"makefolder"}},
        {"hasReadFile", {"readfile"}},
        {"hasIsFile", {"isfile"}},
        {"hasListFiles", {"listfiles"}},
        {"hasDelFile", {"delfile"}},
        {"hasAppendFile", {"appendfile"}},
        {"hasGetHUI", {"gethui"}},
        {"hasSetClipboard", {"setclipboard", "toclipboard"}},
        {"hasGetScripts", {"getscripts"}},
        {"hasGetNilInstances", {"getnilinstances"}},
        {"hasGetGC", {"getgc"}},
        {"hasGetInstances", {"getinstances"}},
        {"hasGetConnections", {"getconnections"}},
        {"hasGetHiddenProperty", {"gethiddenproperty"}},
        {"hasSetHiddenProperty", {"sethiddenproperty"}},
        {"hasGetScriptBytecode", {"getscriptbytecode"}},
        {"hasGetScriptHash", {"getscripthash"}},
        {"hasGetScriptClosure", {"getscriptclosure", "getscriptfunction"}},
        {"hasGetProtos", {"getprotos", "debug.getprotos"}},
        {"hasGetConstants", {"getconstants", "debug.getconstants"}},
        {"hasGetUpvalues", {"getupvalues", "debug.getupvalues"}},
        {"hasGetInfo", {"getinfo", "debug.getinfo"}},
        {"hasFireSignal", {"firesignal"}},
        {"hasHookFunction", {"hookfunction", "hookfunc"}},
        {"hasNewCClosure", {"newcclosure"}},
        {"hasIsLClosure", {"islclosure"}},
        {"hasGetRawMetatable", {"getrawmetatable"}},
        {"hasGetNamecallMethod", {"getnamecallmethod"}},
    }

    for _, check in ipairs(checks) do
        local key = check[1]
        local funcs = check[2]
        for _, funcName in ipairs(funcs) do
            local parts = funcName:gmatch("[^%.]+")
            local obj = getfenv()
            local found = true
            for part in funcName:gmatch("[^%.]+") do
                if type(obj) == "table" and obj[part] then
                    obj = obj[part]
                else
                    local s, r = pcall(function() return _G[funcName] end)
                    if s and r then obj = r else found = false end
                    break
                end
            end
            if found and obj and type(obj) == "function" then
                ExploitEnv[key] = true
                table.insert(ExploitEnv.capabilities, funcName)
                break
            end
        end
    end

    -- Synapse specific
    if syn then
        if syn.decompile then ExploitEnv.hasDecompile = true end
        if syn.saveinstance then ExploitEnv.hasSaveInstance = true end
        if syn.protect_gui then ExploitEnv.hasGetHUI = true end
        if syn.write_clipboard then ExploitEnv.hasSetClipboard = true end
    end

    Logger:Info(string.format("Exploit: %s | Capabilities: %d functions detected",
        ExploitEnv.name, #ExploitEnv.capabilities))

    return ExploitEnv
end

DetectExploitEnvironment()

-- ─── Memory Management ───
local MemoryManager = {}

function MemoryManager:GetUsage()
    local success, mem = pcall(function()
        return collectgarbage("count") / 1024
    end)
    return success and mem or 0
end

function MemoryManager:Optimize()
    if not BaoSaveConfig.EnableGCOptimization then return end
    pcall(function()
        collectgarbage("collect")
        collectgarbage("collect")
    end)
end

function MemoryManager:CheckLimit()
    local usage = self:GetUsage()
    if usage > BaoSaveConfig.MemoryLimit then
        Logger:Warn(string.format("Bộ nhớ cao: %.1f MB / %d MB limit", usage, BaoSaveConfig.MemoryLimit))
        self:Optimize()
        return true
    end
    return false
end

function MemoryManager:TrackPeak()
    local usage = self:GetUsage()
    if usage > BaoSaveInstance.Stats.MemoryPeak then
        BaoSaveInstance.Stats.MemoryPeak = usage
    end
end

-- ─── Utility Functions ───
local function SanitizeFileName(name)
    if not name or name == "" then return "UnknownGame" end
    local s = name:gsub('[/\\:*?"<>|%c]', '_'):gsub('%s+', ' '):match("^%s*(.-)%s*$")
    if #s > 120 then s = s:sub(1, 120) end
    return s ~= "" and s or "UnknownGame"
end

local function GetGameName()
    local s, info = pcall(function()
        return Services.MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    return s and info and info.Name and SanitizeFileName(info.Name) or ("Place_" .. game.PlaceId)
end

local function GenerateFileName(mode)
    local name = GetGameName()
    local suffix = mode and (" [" .. mode .. "]") or ""
    local base = name .. suffix .. " Decompile By BaoSaveInstance"

    if BaoSaveConfig.AddTimestampToFileName then
        base = base .. " [" .. os.date("%Y-%m-%d %H-%M-%S") .. "]"
    end

    local fileName = base .. ".rbxl"

    if ExploitEnv.hasIsFile then
        local c = 0
        local test = fileName
        while pcall(function() return isfile(test) end) and isfile(test) do
            c = c + 1
            test = base .. " (" .. c .. ").rbxl"
        end
        fileName = test
    end

    return fileName
end

local function SafeCall(func, ...)
    return pcall(func, ...)
end

local function SmartYield(counter, interval)
    interval = interval or BaoSaveConfig.YieldInterval
    if counter % interval == 0 then
        if task and task.wait then task.wait() else wait() end
        MemoryManager:TrackPeak()
        if MemoryManager:CheckLimit() then
            if task and task.wait then task.wait(0.1) else wait(0.1) end
        end
    end
end

local function DeepCount(instance)
    local c = 0
    pcall(function() c = #instance:GetDescendants() end)
    return c
end

-- ─── String Similarity Engine ───
local StringAnalyzer = {}

function StringAnalyzer:LevenshteinDistance(s1, s2)
    if #s1 == 0 then return #s2 end
    if #s2 == 0 then return #s1 end
    if #s1 > 500 or #s2 > 500 then
        return math.abs(#s1 - #s2)
    end

    local matrix = {}
    for i = 0, #s1 do
        matrix[i] = {[0] = i}
    end
    for j = 0, #s2 do
        matrix[0][j] = j
    end

    for i = 1, #s1 do
        for j = 1, #s2 do
            local cost = s1:sub(i,i) == s2:sub(j,j) and 0 or 1
            matrix[i][j] = math.min(
                matrix[i-1][j] + 1,
                matrix[i][j-1] + 1,
                matrix[i-1][j-1] + cost
            )
        end
    end

    return matrix[#s1][#s2]
end

function StringAnalyzer:Similarity(s1, s2)
    if not s1 or not s2 then return 0 end
    if s1 == s2 then return 1 end
    local maxLen = math.max(#s1, #s2)
    if maxLen == 0 then return 1 end
    local dist = self:LevenshteinDistance(s1:sub(1, 500), s2:sub(1, 500))
    return 1 - (dist / maxLen)
end

function StringAnalyzer:ExtractFunctions(source)
    local funcs = {}
    if not source then return funcs end
    for funcDef in source:gmatch("function%s+([%w_%.%:]+)%s*%(") do
        table.insert(funcs, funcDef)
    end
    for funcDef in source:gmatch("local%s+function%s+([%w_]+)%s*%(") do
        table.insert(funcs, funcDef)
    end
    return funcs
end

function StringAnalyzer:ExtractVariables(source)
    local vars = {}
    if not source then return vars end
    for var in source:gmatch("local%s+([%w_]+)%s*=") do
        vars[var] = true
    end
    return vars
end

function StringAnalyzer:CountStructures(source)
    if not source then return {} end
    return {
        functions = select(2, source:gsub("function", "")) or 0,
        ifs = select(2, source:gsub("if%s", "")) or 0,
        loops = (select(2, source:gsub("for%s", "")) or 0) + (select(2, source:gsub("while%s", "")) or 0),
        returns = select(2, source:gsub("return", "")) or 0,
        locals = select(2, source:gsub("local%s", "")) or 0,
        requires = select(2, source:gsub("require", "")) or 0,
        ends = select(2, source:gsub("end", "")) or 0,
        lines = select(2, source:gsub("\n", "")) or 0,
        coroutines = select(2, source:gsub("coroutine", "")) or 0,
        pcalls = select(2, source:gsub("pcall", "")) or 0,
        spawns = select(2, source:gsub("spawn", "")) or 0,
        connections = select(2, source:gsub("Connect", "")) or 0,
        services = select(2, source:gsub("GetService", "")) or 0,
        instances = select(2, source:gsub("Instance%.new", "")) or 0,
        waits = select(2, source:gsub("wait%(", "")) or 0,
        metatables = select(2, source:gsub("setmetatable", "")) or 0,
        tables = select(2, source:gsub("table%.", "")) or 0,
        strings = select(2, source:gsub("string%.", "")) or 0,
        maths = select(2, source:gsub("math%.", "")) or 0,
    }
end

-- ═══════════════════════════════════════════════════════════════════════
-- PHẦN 4: ULTRA ADVANCED DECOMPILE ENGINE (12 APIs)
-- ═══════════════════════════════════════════════════════════════════════

local DecompilerAPIs = {}

-- ──────────────────────────────────────────
-- QUALITY SCORING ENGINE (50+ criteria)
-- ──────────────────────────────────────────

local QualityScorer = {}

function QualityScorer:Score(source, scriptInstance)
    if not source or type(source) ~= "string" then return 0 end

    local score = 0
    local len = #source
    local penalties = 0
    local bonuses = 0

    -- === LENGTH SCORING ===
    if len < BaoSaveConfig.MinValidSourceLength then return 0 end
    score = score + math.min(len / 50, 25)

    -- === FAIL PATTERN DETECTION ===
    local failPatterns = {
        "failed to decompile", "decompilation failed", "error decompiling",
        "could not decompile", "bytecode version mismatch", "unrecognized bytecode",
        "decompiled with errors", "script hash:", "decompilation error",
        "this script could not be decompiled", "cannot decompile",
        "decompile error", "-- error", "invalid bytecode",
        "unsupported opcode", "stack overflow during decompilation",
        "timeout during decompilation", "out of memory",
        "corrupted bytecode", "invalid instruction",
    }

    local srcLower = source:lower()
    for _, pattern in ipairs(failPatterns) do
        if srcLower:find(pattern, 1, true) then
            penalties = penalties + 30
        end
    end

    -- === VALID CODE PATTERNS ===
    local codePatterns = {
        {p = "local%s+%w+%s*=", w = 5, name = "local_assign"},
        {p = "function%s*%(", w = 8, name = "function_def"},
        {p = "function%s+%w", w = 10, name = "named_function"},
        {p = "local%s+function%s+%w", w = 12, name = "local_function"},
        {p = "if%s+.+%s+then", w = 5, name = "if_then"},
        {p = "for%s+.+%s+do", w = 5, name = "for_do"},
        {p = "for%s+_%s*,%s*%w+%s+in%s+", w = 6, name = "for_in"},
        {p = "while%s+.+%s+do", w = 4, name = "while_do"},
        {p = "repeat", w = 3, name = "repeat"},
        {p = "return%s", w = 4, name = "return"},
        {p = "return$", w = 3, name = "return_end"},
        {p = "end$", w = 2, name = "end"},
        {p = "end%s*$", w = 2, name = "end_space"},
        {p = "require%s*%(", w = 8, name = "require"},
        {p = 'game:GetService%s*%("', w = 10, name = "getservice"},
        {p = 'game:GetService%s*%(%"', w = 10, name = "getservice2"},
        {p = "script%.Parent", w = 6, name = "script_parent"},
        {p = "script:GetChildren", w = 5, name = "script_children"},
        {p = "%.Connect%s*%(", w = 5, name = "connect"},
        {p = ":Connect%s*%(", w = 5, name = "connect2"},
        {p = "%.Changed", w = 3, name = "changed"},
        {p = "Instance%.new%s*%(", w = 7, name = "instance_new"},
        {p = "wait%s*%(", w = 3, name = "wait"},
        {p = "task%.wait", w = 4, name = "task_wait"},
        {p = "task%.spawn", w = 4, name = "task_spawn"},
        {p = "task%.defer", w = 4, name = "task_defer"},
        {p = "spawn%s*%(", w = 3, name = "spawn"},
        {p = "delay%s*%(", w = 3, name = "delay"},
        {p = "coroutine%.", w = 5, name = "coroutine"},
        {p = "pcall%s*%(", w = 5, name = "pcall"},
        {p = "xpcall%s*%(", w = 5, name = "xpcall"},
        {p = "setmetatable%s*%(", w = 6, name = "setmetatable"},
        {p = "getmetatable%s*%(", w = 4, name = "getmetatable"},
        {p = "rawset%s*%(", w = 3, name = "rawset"},
        {p = "rawget%s*%(", w = 3, name = "rawget"},
        {p = "table%.", w = 3, name = "table"},
        {p = "string%.", w = 3, name = "string"},
        {p = "math%.", w = 3, name = "math"},
        {p = "tonumber%s*%(", w = 2, name = "tonumber"},
        {p = "tostring%s*%(", w = 2, name = "tostring"},
        {p = "type%s*%(", w = 2, name = "type"},
        {p = "typeof%s*%(", w = 3, name = "typeof"},
        {p = "pairs%s*%(", w = 3, name = "pairs"},
        {p = "ipairs%s*%(", w = 3, name = "ipairs"},
        {p = "next%s*%(", w = 2, name = "next"},
        {p = "select%s*%(", w = 2, name = "select"},
        {p = "unpack%s*%(", w = 2, name = "unpack"},
        {p = "print%s*%(", w = 1, name = "print"},
        {p = "warn%s*%(", w = 1, name = "warn"},
        {p = "error%s*%(", w = 2, name = "error"},
        {p = "assert%s*%(", w = 2, name = "assert"},
        {p = "Vector3%.new", w = 4, name = "vector3"},
        {p = "Vector2%.new", w = 3, name = "vector2"},
        {p = "CFrame%.new", w = 4, name = "cframe"},
        {p = "CFrame%.Angles", w = 4, name = "cframe_angles"},
        {p = "Color3%.", w = 3, name = "color3"},
        {p = "UDim2%.new", w = 4, name = "udim2"},
        {p = "UDim%.new", w = 3, name = "udim"},
        {p = "Enum%.", w = 5, name = "enum"},
        {p = "BrickColor%.new", w = 3, name = "brickcolor"},
        {p = "TweenInfo%.new", w = 4, name = "tweeninfo"},
        {p = "Ray%.new", w = 3, name = "ray"},
        {p = "Region3%.new", w = 3, name = "region3"},
        {p = "NumberRange%.new", w = 2, name = "numberrange"},
        {p = "NumberSequence%.new", w = 2, name = "numbersequence"},
        {p = "ColorSequence%.new", w = 2, name = "colorsequence"},
        {p = ":FindFirstChild%s*%(", w = 5, name = "findfirstchild"},
        {p = ":WaitForChild%s*%(", w = 5, name = "waitforchild"},
        {p = ":FindFirstChildOfClass%s*%(", w = 4, name = "findfirstchildofclass"},
        {p = ":FindFirstChildWhichIsA%s*%(", w = 4, name = "findfirstchildwhichisa"},
        {p = ":GetChildren%s*%(", w = 4, name = "getchildren"},
        {p = ":GetDescendants%s*%(", w = 4, name = "getdescendants"},
        {p = ":Clone%s*%(", w = 3, name = "clone"},
        {p = ":Destroy%s*%(", w = 3, name = "destroy"},
        {p = ":SetAttribute%s*%(", w = 4, name = "setattribute"},
        {p = ":GetAttribute%s*%(", w = 4, name = "getattribute"},
        {p = "%.Parent%s*=", w = 3, name = "parent_set"},
        {p = "%.Position%s*=", w = 3, name = "position_set"},
        {p = "%.CFrame%s*=", w = 3, name = "cframe_set"},
        {p = "%.Size%s*=", w = 2, name = "size_set"},
        {p = "%.Text%s*=", w = 2, name = "text_set"},
        {p = "%.Visible%s*=", w = 2, name = "visible_set"},
        {p = ":Play%s*%(", w = 3, name = "play"},
        {p = ":Stop%s*%(", w = 2, name = "stop"},
        {p = ":Lerp%s*%(", w = 3, name = "lerp"},
        {p = "game%.Loaded", w = 3, name = "game_loaded"},
        {p = "workspace", w = 2, name = "workspace"},
    }

    local matchedPatterns = 0
    for _, cp in ipairs(codePatterns) do
        if source:find(cp.p) then
            bonuses = bonuses + cp.w
            matchedPatterns = matchedPatterns + 1
        end
    end

    -- === STRUCTURAL ANALYSIS ===
    local structures = StringAnalyzer:CountStructures(source)

    -- Balance check: functions should have matching ends
    if structures.functions > 0 then
        local endRatio = structures.ends / math.max(structures.functions + structures.ifs + structures.loops, 1)
        if endRatio >= 0.7 and endRatio <= 2.0 then
            bonuses = bonuses + 15
        else
            penalties = penalties + 10
        end
    end

    -- Line analysis
    local lineCount = structures.lines + 1
    score = score + math.min(lineCount / 5, 15)

    -- Code density (non-empty, non-comment lines)
    local codeLines = 0
    local commentLines = 0
    local emptyLines = 0
    for line in source:gmatch("[^\n]*") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed == "" then
            emptyLines = emptyLines + 1
        elseif trimmed:sub(1, 2) == "--" then
            commentLines = commentLines + 1
        else
            codeLines = codeLines + 1
        end
    end

    if lineCount > 0 then
        local codeRatio = codeLines / lineCount
        if codeRatio > 0.3 then
            bonuses = bonuses + 10
        end
        if commentLines / lineCount > 0.8 then
            penalties = penalties + 20
        end
    end

    -- === PATTERN DIVERSITY ===
    if matchedPatterns >= 20 then bonuses = bonuses + 15
    elseif matchedPatterns >= 10 then bonuses = bonuses + 10
    elseif matchedPatterns >= 5 then bonuses = bonuses + 5
    end

    -- === SYNTAX VALIDATION ===
    -- Check for balanced brackets
    local openParens = select(2, source:gsub("%(", "")) or 0
    local closeParens = select(2, source:gsub("%)", "")) or 0
    local openBraces = select(2, source:gsub("{", "")) or 0
    local closeBraces = select(2, source:gsub("}", "")) or 0
    local openBrackets = select(2, source:gsub("%[", "")) or 0
    local closeBrackets = select(2, source:gsub("%]", "")) or 0

    local parenBalance = math.abs(openParens - closeParens)
    local braceBalance = math.abs(openBraces - closeBraces)
    local bracketBalance = math.abs(openBrackets - closeBrackets)

    if parenBalance <= 2 and braceBalance <= 2 then
        bonuses = bonuses + 8
    else
        penalties = penalties + math.min(parenBalance + braceBalance, 15)
    end

    -- === STRING CONTENT QUALITY ===
    -- Check for meaningful string literals
    local stringCount = select(2, source:gsub('"[^"]*"', "")) or 0
    stringCount = stringCount + (select(2, source:gsub("'[^']*'", "")) or 0)
    if stringCount > 0 then
        bonuses = bonuses + math.min(stringCount, 10)
    end

    -- === UNIQUE IDENTIFIER COUNT ===
    local identifiers = {}
    for id in source:gmatch("[%a_][%w_]*") do
        identifiers[id] = true
    end
    local uniqueIds = 0
    for _ in pairs(identifiers) do uniqueIds = uniqueIds + 1 end

    if uniqueIds >= 50 then bonuses = bonuses + 10
    elseif uniqueIds >= 20 then bonuses = bonuses + 5
    end

    -- === OBFUSCATION DETECTION ===
    -- Variable names like v1, v2, v3... indicate decompiled but readable code
    local decompVarCount = 0
    for _ in source:gmatch("v%d+") do decompVarCount = decompVarCount + 1 end
    if decompVarCount > 20 then
        -- Looks like decompiled code (not necessarily bad, but not original)
        -- Still give some points
        bonuses = bonuses + 3
    end

    -- Check for very long single lines (might be minified/obfuscated)
    local maxLineLen = 0
    for line in source:gmatch("[^\n]+") do
        if #line > maxLineLen then maxLineLen = #line end
    end
    if maxLineLen > 1000 and lineCount < 5 then
        penalties = penalties + 10
    end

    -- === FINAL CALCULATION ===
    score = score + bonuses - penalties
    return math.max(math.floor(score), 0)
end

function QualityScorer:GetGrade(score)
    if score >= 80 then return "EXCELLENT", "🟢"
    elseif score >= 50 then return "GOOD", "🟡"
    elseif score >= 30 then return "FAIR", "🟠"
    elseif score >= 10 then return "POOR", "🔴"
    else return "FAILED", "⚫" end
end

function QualityScorer:UpdateDistribution(score)
    local grade = self:GetGrade(score)
    if grade == "EXCELLENT" then BaoSaveInstance.Stats.QualityDistribution.excellent = BaoSaveInstance.Stats.QualityDistribution.excellent + 1
    elseif grade == "GOOD" then BaoSaveInstance.Stats.QualityDistribution.good = BaoSaveInstance.Stats.QualityDistribution.good + 1
    elseif grade == "FAIR" then BaoSaveInstance.Stats.QualityDistribution.fair = BaoSaveInstance.Stats.QualityDistribution.fair + 1
    elseif grade == "POOR" then BaoSaveInstance.Stats.QualityDistribution.poor = BaoSaveInstance.Stats.QualityDistribution.poor + 1
    else BaoSaveInstance.Stats.QualityDistribution.failed = BaoSaveInstance.Stats.QualityDistribution.failed + 1 end
end

-- ──────────────────────────────────────────
-- 12 DECOMPILE APIS
-- ──────────────────────────────────────────

-- API 1: Direct decompile()
DecompilerAPIs["API01"] = {
    Name = "Direct Decompile",
    Priority = 1,
    Available = false,
    Decompile = function(inst)
        if not decompile then return nil, "N/A" end
        local s, r = pcall(decompile, inst)
        return s and r and type(r) == "string" and #r > 0 and r or nil, s and nil or tostring(r)
    end,
}

-- API 2: Synapse decompile
DecompilerAPIs["API02"] = {
    Name = "Synapse Decompile",
    Priority = 2,
    Available = false,
    Decompile = function(inst)
        if not (syn and syn.decompile) then return nil, "N/A" end
        local s, r = pcall(syn.decompile, inst)
        return s and r and type(r) == "string" and #r > 0 and r or nil, s and nil or tostring(r)
    end,
}

-- API 3: getscriptbytecode + decompile
DecompilerAPIs["API03"] = {
    Name = "Bytecode→Decompile",
    Priority = 3,
    Available = false,
    Decompile = function(inst)
        if not getscriptbytecode then return nil, "N/A" end
        local s1, bytecode = pcall(getscriptbytecode, inst)
        if not s1 or not bytecode then return nil, "Bytecode failed" end

        -- Try decompile from bytecode
        if decompile then
            local s2, r = pcall(decompile, inst)
            if s2 and r and #r > 0 then return r, nil end
        end

        return string.format("-- Bytecode recovered: %d bytes\n-- Script: %s\n",
            #bytecode, inst:GetFullName()), "Bytecode only"
    end,
}

-- API 4: Script.Source direct
DecompilerAPIs["API04"] = {
    Name = "Direct Source Access",
    Priority = 4,
    Available = false,
    Decompile = function(inst)
        -- Direct access
        local s, r = pcall(function() return inst.Source end)
        if s and r and type(r) == "string" and #r > 0 then return r, nil end

        -- Hidden property
        if gethiddenproperty then
            local s2, r2 = pcall(gethiddenproperty, inst, "Source")
            if s2 and r2 and type(r2) == "string" and #r2 > 0 then return r2, nil end
        end

        return nil, "Cannot access Source"
    end,
}

-- API 5: Environment Reconstruction (Deep)
DecompilerAPIs["API05"] = {
    Name = "Deep Environment Reconstruction",
    Priority = 5,
    Available = false,
    Decompile = function(inst)
        if not getsenv then return nil, "N/A" end
        local s, env = pcall(getsenv, inst)
        if not s or not env then return nil, "getsenv failed" end

        local lines = {
            "-- [BaoSaveInstance] Deep Environment Reconstruction",
            "-- Script: " .. inst:GetFullName(),
            "-- ClassName: " .. inst.ClassName,
            "",
        }

        local envItems = {}
        for k, v in pairs(env) do
            table.insert(envItems, {key = k, value = v, type = type(v)})
        end

        -- Sort by type for readability
        table.sort(envItems, function(a, b)
            if a.type ~= b.type then
                local order = {["function"] = 1, ["table"] = 2, ["string"] = 3, ["number"] = 4, ["boolean"] = 5}
                return (order[a.type] or 6) < (order[b.type] or 6)
            end
            return tostring(a.key) < tostring(b.key)
        end)

        for _, item in ipairs(envItems) do
            local k, v, t = tostring(item.key), item.value, item.type

            if t == "function" then
                local info = {}
                pcall(function()
                    if debug and debug.getinfo then
                        info = debug.getinfo(v, "Slu")
                    elseif getinfo then
                        info = getinfo(v)
                    end
                end)

                local params = info.numparams or info.nparams or "?"
                local isVararg = info.is_vararg or info.isvararg or false
                local paramStr = ""
                if type(params) == "number" then
                    local p = {}
                    for i = 1, params do table.insert(p, "arg" .. i) end
                    if isVararg then table.insert(p, "...") end
                    paramStr = table.concat(p, ", ")
                end

                -- Try to get constants
                local constants = {}
                pcall(function()
                    if getconstants then
                        constants = getconstants(v)
                    elseif debug and debug.getconstants then
                        constants = debug.getconstants(v)
                    end
                end)

                -- Try to get upvalues
                local upvalues = {}
                pcall(function()
                    if getupvalues then
                        upvalues = getupvalues(v)
                    elseif debug and debug.getupvalues then
                        upvalues = debug.getupvalues(v)
                    end
                end)

                table.insert(lines, string.format("function %s(%s)", k, paramStr))

                if #constants > 0 then
                    table.insert(lines, "    -- Constants: " .. table.concat(
                        (function()
                            local strs = {}
                            for _, c in ipairs(constants) do
                                if type(c) == "string" then
                                    table.insert(strs, '"' .. c:sub(1, 50) .. '"')
                                end
                            end
                            return strs
                        end)(), ", "))
                end

                if next(upvalues) then
                    for ui, uv in pairs(upvalues) do
                        table.insert(lines, string.format("    -- Upvalue[%s] = %s (%s)",
                            tostring(ui), tostring(uv):sub(1, 80), type(uv)))
                    end
                end

                table.insert(lines, "    -- TODO: Function body not recoverable from environment")
                table.insert(lines, "end")
                table.insert(lines, "")

            elseif t == "table" then
                local tableStr = {}
                local count = 0
                pcall(function()
                    for tk, tv in pairs(v) do
                        count = count + 1
                        if count <= 20 then
                            table.insert(tableStr, string.format("    [%s] = %s, -- %s",
                                tostring(tk), tostring(tv):sub(1, 60), type(tv)))
                        end
                    end
                end)

                table.insert(lines, string.format("local %s = { -- %d entries", k, count))
                for _, ts in ipairs(tableStr) do
                    table.insert(lines, ts)
                end
                if count > 20 then
                    table.insert(lines, string.format("    -- ... and %d more entries", count - 20))
                end
                table.insert(lines, "}")
                table.insert(lines, "")

            elseif t == "string" then
                if #v > 200 then
                    table.insert(lines, string.format('local %s = %q -- (truncated, full length: %d)', k, v:sub(1, 200), #v))
                else
                    table.insert(lines, string.format('local %s = %q', k, v))
                end

            elseif t == "number" then
                table.insert(lines, string.format("local %s = %s", k, tostring(v)))

            elseif t == "boolean" then
                table.insert(lines, string.format("local %s = %s", k, tostring(v)))

            elseif t == "userdata" then
                table.insert(lines, string.format("local %s = nil -- userdata: %s", k, tostring(v)))

            else
                table.insert(lines, string.format("-- %s = <%s> %s", k, t, tostring(v):sub(1, 80)))
            end
        end

        if #envItems == 0 then return nil, "Empty environment" end
        return table.concat(lines, "\n"), nil
    end,
}

-- API 6: Script Closure Analysis
DecompilerAPIs["API06"] = {
    Name = "Closure Analysis",
    Priority = 6,
    Available = false,
    Decompile = function(inst)
        local closure = nil
        pcall(function()
            if getscriptclosure then closure = getscriptclosure(inst)
            elseif getscriptfunction then closure = getscriptfunction(inst) end
        end)
        if not closure then return nil, "N/A" end

        local lines = {
            "-- [BaoSaveInstance] Closure Analysis Recovery",
            "-- Script: " .. inst:GetFullName(),
            "",
        }

        -- Get constants
        local constants = {}
        pcall(function()
            if getconstants then constants = getconstants(closure)
            elseif debug and debug.getconstants then constants = debug.getconstants(closure) end
        end)

        if #constants > 0 then
            table.insert(lines, "-- === CONSTANTS ===")
            BaoSaveInstance.Stats.ConstantsExtracted = BaoSaveInstance.Stats.ConstantsExtracted + #constants
            for i, c in ipairs(constants) do
                if type(c) == "string" then
                    table.insert(lines, string.format("-- [%d] STRING: %q", i, c:sub(1, 100)))
                elseif type(c) == "number" then
                    table.insert(lines, string.format("-- [%d] NUMBER: %s", i, tostring(c)))
                elseif type(c) == "boolean" then
                    table.insert(lines, string.format("-- [%d] BOOLEAN: %s", i, tostring(c)))
                else
                    table.insert(lines, string.format("-- [%d] %s: %s", i, type(c), tostring(c)))
                end
            end
            table.insert(lines, "")
        end

        -- Get upvalues
        local upvalues = {}
        pcall(function()
            if getupvalues then upvalues = getupvalues(closure)
            elseif debug and debug.getupvalues then upvalues = debug.getupvalues(closure) end
        end)

        if next(upvalues) then
            table.insert(lines, "-- === UPVALUES ===")
            BaoSaveInstance.Stats.UpvaluesRecovered = BaoSaveInstance.Stats.UpvaluesRecovered + 1
            for i, uv in pairs(upvalues) do
                table.insert(lines, string.format("local upvalue_%s = %s -- %s",
                    tostring(i), tostring(uv):sub(1, 100), type(uv)))
            end
            table.insert(lines, "")
        end

        -- Get protos (sub-functions)
        local protos = {}
        pcall(function()
            if getprotos then protos = getprotos(closure)
            elseif debug and debug.getprotos then protos = debug.getprotos(closure) end
        end)

        if #protos > 0 then
            table.insert(lines, "-- === SUB-FUNCTIONS (PROTOS) ===")
            for i, proto in ipairs(protos) do
                table.insert(lines, string.format("-- Proto[%d]: %s", i, tostring(proto)))

                -- Get constants from proto
                pcall(function()
                    local pConstants = getconstants and getconstants(proto) or {}
                    for j, pc in ipairs(pConstants) do
                        if type(pc) == "string" then
                            table.insert(lines, string.format("--   Const[%d]: %q", j, pc:sub(1, 80)))
                        end
                    end
                end)
            end
            table.insert(lines, "")
        end

        -- Get info
        pcall(function()
            local info = {}
            if getinfo then info = getinfo(closure)
            elseif debug and debug.getinfo then info = debug.getinfo(closure) end

            if next(info) then
                table.insert(lines, "-- === FUNCTION INFO ===")
                for k, v in pairs(info) do
                    table.insert(lines, string.format("-- %s: %s", tostring(k), tostring(v)))
                end
            end
        end)

        -- Try to reconstruct using constants
        if #constants > 0 then
            table.insert(lines, "")
            table.insert(lines, "-- === RECONSTRUCTED CODE (from constants) ===")

            -- Find service references
            local serviceRefs = {}
            for _, c in ipairs(constants) do
                if type(c) == "string" then
                    for _, sName in ipairs(ServiceNames) do
                        if c == sName then
                            table.insert(serviceRefs, c)
                        end
                    end
                end
            end

            if #serviceRefs > 0 then
                for _, svc in ipairs(serviceRefs) do
                    table.insert(lines, string.format('local %s = game:GetService("%s")', svc, svc))
                end
                table.insert(lines, "")
            end

            -- Find method calls
            for _, c in ipairs(constants) do
                if type(c) == "string" and c:match("^[A-Z]") and #c > 2 then
                    table.insert(lines, string.format("-- Referenced: %s", c))
                end
            end
        end

        return table.concat(lines, "\n"), nil
    end,
}

-- API 7: GC Scanning Recovery
DecompilerAPIs["API07"] = {
    Name = "GC Scan Recovery",
    Priority = 7,
    Available = false,
    Decompile = function(inst)
        if not getgc then return nil, "N/A" end

        local s, gc = pcall(getgc, true)
        if not s or not gc then return nil, "getgc failed" end

        local relatedFunctions = {}
        local relatedTables = {}
        local scriptFullName = inst:GetFullName()
        local scriptName = inst.Name

        for _, obj in ipairs(gc) do
            if type(obj) == "function" then
                pcall(function()
                    local info = getinfo and getinfo(obj) or (debug and debug.getinfo and debug.getinfo(obj)) or {}
                    local src = info.source or info.short_src or ""
                    if src:find(scriptName, 1, true) or src:find(scriptFullName, 1, true) then
                        table.insert(relatedFunctions, {func = obj, info = info})
                    end

                    -- Check upvalues for script reference
                    local upvals = getupvalues and getupvalues(obj) or {}
                    for _, uv in pairs(upvals) do
                        if typeof(uv) == "Instance" and uv == inst then
                            table.insert(relatedFunctions, {func = obj, info = info, directRef = true})
                        end
                    end
                end)
            elseif type(obj) == "table" then
                pcall(function()
                    for k, v in pairs(obj) do
                        if typeof(v) == "Instance" and v == inst then
                            table.insert(relatedTables, {tbl = obj, key = k})
                        end
                    end
                end)
            end
        end

        if #relatedFunctions == 0 and #relatedTables == 0 then
            return nil, "No GC references found"
        end

        local lines = {
            "-- [BaoSaveInstance] GC Scan Recovery",
            "-- Script: " .. scriptFullName,
            string.format("-- Found %d related functions, %d related tables",
                #relatedFunctions, #relatedTables),
            "",
        }

        for i, rf in ipairs(relatedFunctions) do
            table.insert(lines, string.format("-- === Function %d %s ===",
                i, rf.directRef and "(DIRECT REF)" or ""))

            -- Extract all available info
            pcall(function()
                local constants = getconstants and getconstants(rf.func) or {}
                if #constants > 0 then
                    table.insert(lines, "-- Constants:")
                    for j, c in ipairs(constants) do
                        if type(c) == "string" then
                            table.insert(lines, string.format('--   [%d] = %q', j, c:sub(1, 80)))
                        elseif type(c) ~= "nil" then
                            table.insert(lines, string.format("--   [%d] = %s", j, tostring(c)))
                        end
                    end
                end
            end)

            pcall(function()
                local upvals = getupvalues and getupvalues(rf.func) or {}
                if next(upvals) then
                    table.insert(lines, "-- Upvalues:")
                    for k, v in pairs(upvals) do
                        table.insert(lines, string.format("--   [%s] = %s (%s)",
                            tostring(k), tostring(v):sub(1, 60), type(v)))
                    end
                end
            end)

            -- Try decompile this function
            pcall(function()
                if decompile then
                    local s, src = pcall(decompile, rf.func)
                    if s and src and #src > 20 then
                        table.insert(lines, "-- Decompiled function body:")
                        table.insert(lines, src)
                    end
                end
            end)

            table.insert(lines, "")
        end

        return table.concat(lines, "\n"), nil
    end,
}

-- API 8: Connection Analysis Recovery
DecompilerAPIs["API08"] = {
    Name = "Connection Analysis",
    Priority = 8,
    Available = false,
    Decompile = function(inst)
        if not getconnections then return nil, "N/A" end

        local lines = {
            "-- [BaoSaveInstance] Connection Analysis Recovery",
            "-- Script: " .. inst:GetFullName(),
            "",
        }

        -- Find all connections from descendants
        local connectionCount = 0
        local processedSignals = {}

        local function processInstance(obj)
            pcall(function()
                local signals = {
                    "Changed", "ChildAdded", "ChildRemoved", "DescendantAdded",
                    "DescendantRemoving", "AncestryChanged",
                }

                -- Instance specific signals
                if obj:IsA("BasePart") then
                    table.insert(signals, "Touched")
                    table.insert(signals, "TouchEnded")
                end
                if obj:IsA("ClickDetector") then
                    table.insert(signals, "MouseClick")
                    table.insert(signals, "MouseHoverEnter")
                    table.insert(signals, "MouseHoverLeave")
                end
                if obj:IsA("ProximityPrompt") then
                    table.insert(signals, "Triggered")
                    table.insert(signals, "TriggerEnded")
                end
                if obj:IsA("GuiButton") then
                    table.insert(signals, "Activated")
                    table.insert(signals, "MouseButton1Click")
                    table.insert(signals, "MouseButton2Click")
                    table.insert(signals, "MouseEnter")
                    table.insert(signals, "MouseLeave")
                end
                if obj:IsA("RemoteEvent") then
                    table.insert(signals, "OnClientEvent")
                end
                if obj:IsA("RemoteFunction") then
                    table.insert(signals, "OnClientInvoke")
                end
                if obj:IsA("BindableEvent") then
                    table.insert(signals, "Event")
                end

                for _, signalName in ipairs(signals) do
                    pcall(function()
                        local signal = obj[signalName]
                        if signal then
                            local conns = getconnections(signal)
                            if conns and #conns > 0 then
                                for _, conn in ipairs(conns) do
                                    connectionCount = connectionCount + 1
                                    local funcInfo = ""
                                    pcall(function()
                                        if conn.Function then
                                            local info = getinfo and getinfo(conn.Function) or {}
                                            funcInfo = info.source or ""

                                            -- Try to decompile the connected function
                                            if decompile then
                                                local s, src = pcall(decompile, conn.Function)
                                                if s and src and #src > 10 then
                                                    table.insert(lines, string.format(
                                                        "%s.%s:Connect(function(...)",
                                                        obj:GetFullName(), signalName))
                                                    table.insert(lines, src)
                                                    table.insert(lines, "end)")
                                                    table.insert(lines, "")
                                                end
                                            end
                                        end
                                    end)
                                end
                            end
                        end
                    end)
                end
            end)
        end

        -- Process the script and its descendants
        processInstance(inst)
        pcall(function()
            if inst.Parent then
                for _, child in ipairs(inst.Parent:GetDescendants()) do
                    processInstance(child)
                end
            end
        end)

        if connectionCount == 0 then
            return nil, "No connections found"
        end

        table.insert(lines, 2, string.format("-- Found %d connections", connectionCount))
        return table.concat(lines, "\n"), nil
    end,
}

-- API 9: Instance Tree Analysis
DecompilerAPIs["API09"] = {
    Name = "Instance Tree Recovery",
    Priority = 9,
    Available = false,
    Decompile = function(inst)
        if not inst.Parent then return nil, "No parent" end

        local lines = {
            "-- [BaoSaveInstance] Instance Tree Code Recovery",
            "-- Script: " .. inst:GetFullName(),
            "-- Recovering code from instance tree structure",
            "",
        }

        -- Analyze what the script creates/modifies based on tree
        local parent = inst.Parent

        -- Check for value objects (IntValue, StringValue, etc.) which are often used as config
        pcall(function()
            for _, child in ipairs(inst:GetChildren()) do
                if child:IsA("IntValue") then
                    table.insert(lines, string.format('script:FindFirstChild("%s").Value = %d', child.Name, child.Value))
                elseif child:IsA("NumberValue") then
                    table.insert(lines, string.format('script:FindFirstChild("%s").Value = %s', child.Name, tostring(child.Value)))
                elseif child:IsA("StringValue") then
                    table.insert(lines, string.format('script:FindFirstChild("%s").Value = %q', child.Name, child.Value))
                elseif child:IsA("BoolValue") then
                    table.insert(lines, string.format('script:FindFirstChild("%s").Value = %s', child.Name, tostring(child.Value)))
                elseif child:IsA("ObjectValue") then
                    local targetName = child.Value and child.Value:GetFullName() or "nil"
                    table.insert(lines, string.format('-- script:FindFirstChild("%s").Value → %s', child.Name, targetName))
                end
            end
        end)

        -- Check parent structure for clues
        pcall(function()
            if parent:IsA("Model") or parent:IsA("Tool") then
                table.insert(lines, "")
                table.insert(lines, "-- Parent is " .. parent.ClassName .. ": " .. parent.Name)

                -- For Tools
                if parent:IsA("Tool") then
                    table.insert(lines, "local tool = script.Parent")
                    table.insert(lines, 'local handle = tool:FindFirstChild("Handle")')

                    if parent:FindFirstChild("Handle") then
                        table.insert(lines, "")
                        table.insert(lines, "tool.Activated:Connect(function()")
                        table.insert(lines, "    -- Tool activated logic")
                        table.insert(lines, "end)")
                        table.insert(lines, "")
                        table.insert(lines, "tool.Deactivated:Connect(function()")
                        table.insert(lines, "    -- Tool deactivated logic")
                        table.insert(lines, "end)")
                    end
                end
            end
        end)

        if #lines <= 4 then return nil, "No recoverable structure" end
        return table.concat(lines, "\n"), nil
    end,
}

-- API 10: Nil Instance Recovery
DecompilerAPIs["API10"] = {
    Name = "Nil Instance Decompile",
    Priority = 10,
    Available = false,
    Decompile = function(inst)
        if not getnilinstances then return nil, "N/A" end

        -- Check if this script has nil instance copies
        local s, nilInsts = pcall(getnilinstances)
        if not s or not nilInsts then return nil, "getnilinstances failed" end

        for _, nilInst in ipairs(nilInsts) do
            if nilInst:IsA("ModuleScript") or nilInst:IsA("LocalScript") or nilInst:IsA("Script") then
                if nilInst.Name == inst.Name then
                    -- Try to decompile the nil instance version
                    if decompile then
                        local s2, src = pcall(decompile, nilInst)
                        if s2 and src and #src > 0 then
                            return "-- Recovered from nil instance\n" .. src, nil
                        end
                    end

                    -- Try source access
                    pcall(function()
                        local src = nilInst.Source
                        if src and #src > 0 then
                            return src, nil
                        end
                    end)
                end
            end
        end

        return nil, "No nil instance match found"
    end,
}

-- API 11: getinstances() Global Scan
DecompilerAPIs["API11"] = {
    Name = "Global Instance Scan",
    Priority = 11,
    Available = false,
    Decompile = function(inst)
        if not getinstances then return nil, "N/A" end

        local s, allInsts = pcall(getinstances)
        if not s or not allInsts then return nil, "getinstances failed" end

        -- Find duplicates or related instances
        for _, otherInst in ipairs(allInsts) do
            if otherInst ~= inst and otherInst.Name == inst.Name and
               otherInst.ClassName == inst.ClassName then
                -- Try decompile alternative instance
                if decompile then
                    local s2, src = pcall(decompile, otherInst)
                    if s2 and src and #src > 20 then
                        return "-- Recovered from alternative instance: " .. tostring(otherInst) .. "\n" .. src, nil
                    end
                end
            end
        end

        return nil, "No alternative instances found"
    end,
}

-- API 12: Hash-based Cache Recovery
DecompilerAPIs["API12"] = {
    Name = "Hash Cache Recovery",
    Priority = 12,
    Available = false,
    Decompile = function(inst)
        if not getscripthash then return nil, "N/A" end

        local s, hash = pcall(getscripthash, inst)
        if not s or not hash then return nil, "getscripthash failed" end

        -- Check if we've already decompiled a script with same hash
        if BaoSaveInstance._hashCache and BaoSaveInstance._hashCache[hash] then
            local cached = BaoSaveInstance._hashCache[hash]
            return "-- Recovered from hash cache (same bytecode as: " .. cached.name .. ")\n" .. cached.source, nil
        end

        -- Store hash for future reference
        if not BaoSaveInstance._hashCache then
            BaoSaveInstance._hashCache = {}
        end

        return nil, "Hash " .. tostring(hash) .. " not in cache"
    end,
}

-- Initialize API availability
local function InitializeDecompilers()
    Logger:Info("═══ Khởi tạo 12 Decompile APIs ═══")

    local apiChecks = {
        API01 = function() return decompile ~= nil end,
        API02 = function() return syn ~= nil and syn.decompile ~= nil end,
        API03 = function() return getscriptbytecode ~= nil end,
        API04 = function() return gethiddenproperty ~= nil or pcall(function() return Instance.new("LocalScript").Source end) end,
        API05 = function() return getsenv ~= nil end,
        API06 = function() return getscriptclosure ~= nil or getscriptfunction ~= nil end,
        API07 = function() return getgc ~= nil end,
        API08 = function() return getconnections ~= nil end,
        API09 = function() return true end,
        API10 = function() return getnilinstances ~= nil end,
        API11 = function() return getinstances ~= nil end,
        API12 = function() return getscripthash ~= nil end,
    }

    local count = 0
    for name, check in pairs(apiChecks) do
        local s, available = pcall(check)
        DecompilerAPIs[name].Available = s and available
        if s and available then
            count = count + 1
            Logger:Debug(string.format("  ✓ %s (%s)", name, DecompilerAPIs[name].Name))
        else
            Logger:Debug(string.format("  ✗ %s (%s)", name, DecompilerAPIs[name].Name))
        end
    end

    Logger:Info(string.format("API khả dụng: %d/12", count))
    return count
end

-- ──────────────────────────────────────────
-- SMART MERGE ENGINE
-- ──────────────────────────────────────────

local SmartMerger = {}

function SmartMerger:MergeResults(results)
    if not results or #results == 0 then return nil end
    if #results == 1 then return results[1].source end
    if not BaoSaveConfig.EnableSmartMerge then
        -- Just return best score
        local best = results[1]
        for _, r in ipairs(results) do
            if r.score > best.score then best = r end
        end
        return best.source
    end

    -- Strategy: BEST_SEGMENTS
    -- Split each result into segments (functions, blocks) and pick best version of each

    local bestResult = results[1]
    for _, r in ipairs(results) do
        if r.score > bestResult.score then bestResult = r end
    end

    -- If best result is excellent, just use it
    if bestResult.score >= 80 then return bestResult.source end

    -- Try segment-based merge
    local bestSource = bestResult.source
    local bestFunctions = StringAnalyzer:ExtractFunctions(bestSource)
    local bestStructures = StringAnalyzer:CountStructures(bestSource)

    -- Check if any other result has better segments
    for _, r in ipairs(results) do
        if r.source ~= bestSource and r.score >= 20 then
            local otherFunctions = StringAnalyzer:ExtractFunctions(r.source)
            local otherStructures = StringAnalyzer:CountStructures(r.source)

            -- If other result has more functions identified, it might be better structured
            if #otherFunctions > #bestFunctions * 1.5 then
                -- Check if the other source is more complete
                if otherStructures.functions > bestStructures.functions then
                    -- Merge: use the other source but append any unique functions from best
                    Logger:Debug("SmartMerge: Found better structured result, merging...")
                    BaoSaveInstance.Stats.MergedScripts = BaoSaveInstance.Stats.MergedScripts + 1

                    bestSource = r.source .. "\n\n-- === MERGED ADDITIONAL SEGMENTS ===\n"

                    -- Add unique parts from best that aren't in other
                    for _, func in ipairs(bestFunctions) do
                        local found = false
                        for _, oFunc in ipairs(otherFunctions) do
                            if func == oFunc then found = true; break end
                        end
                        if not found then
                            -- Extract function body from best source
                            local pattern = "function%s+" .. func:gsub("([%.%:%[%]])", "%%%1") .. "%s*%("
                            local funcStart = bestResult.source:find(pattern)
                            if funcStart then
                                -- Simple extraction (not perfect but helps)
                                local funcEnd = bestResult.source:find("\nend", funcStart)
                                if funcEnd then
                                    local funcBody = bestResult.source:sub(funcStart, funcEnd + 3)
                                    bestSource = bestSource .. "\n" .. funcBody .. "\n"
                                end
                            end
                        end
                    end

                    break
                end
            end

            -- If other result has significantly more code content
            if r.score >= bestResult.score * 0.8 and #r.source > #bestResult.source * 1.3 then
                local otherCodeLines = 0
                for line in r.source:gmatch("[^\n]+") do
                    if not line:match("^%s*%-%-") and line:match("%S") then
                        otherCodeLines = otherCodeLines + 1
                    end
                end

                local bestCodeLines = 0
                for line in bestResult.source:gmatch("[^\n]+") do
                    if not line:match("^%s*%-%-") and line:match("%S") then
                        bestCodeLines = bestCodeLines + 1
                    end
                end

                if otherCodeLines > bestCodeLines * 1.3 then
                    Logger:Debug("SmartMerge: Switching to longer, denser result")
                    bestSource = r.source
                    BaoSaveInstance.Stats.MergedScripts = BaoSaveInstance.Stats.MergedScripts + 1
                    break
                end
            end
        end
    end

    return bestSource
end

-- ──────────────────────────────────────────
-- MASTER DECOMPILE FUNCTION
-- ──────────────────────────────────────────

local function DecompileScriptUltra(scriptInstance)
    local allResults = {}
    local bestSource = nil
    local bestScore = -1
    local bestAPI = "None"

    -- Build API order
    local apiOrder = {}

    -- Preferred API first
    if BaoSaveConfig.PreferredAPI ~= "AUTO" then
        local pref = BaoSaveConfig.PreferredAPI
        if DecompilerAPIs[pref] and DecompilerAPIs[pref].Available then
            table.insert(apiOrder, pref)
        end
    end

    -- Sort remaining by priority
    local sorted = {}
    for name, api in pairs(DecompilerAPIs) do
        if api.Available and name ~= BaoSaveConfig.PreferredAPI then
            table.insert(sorted, {name = name, priority = api.Priority})
        end
    end
    table.sort(sorted, function(a, b) return a.priority < b.priority end)
    for _, s in ipairs(sorted) do table.insert(apiOrder, s.name) end

    -- Try each API
    for _, apiName in ipairs(apiOrder) do
        local api = DecompilerAPIs[apiName]
        if not api or not api.Available then
            goto continue_api
        end

        for attempt = 1, BaoSaveConfig.MaxRetries do
            local source, err = nil, nil

            local success = pcall(function()
                source, err = api.Decompile(scriptInstance)
            end)

            if success and source and type(source) == "string" and #source > 0 then
                local score = QualityScorer:Score(source, scriptInstance)

                table.insert(allResults, {
                    source = source,
                    score = score,
                    apiName = apiName,
                    attempt = attempt,
                })

                -- Track API usage
                BaoSaveInstance.Stats.APIUsageStats[apiName] = (BaoSaveInstance.Stats.APIUsageStats[apiName] or 0) + 1

                -- Store in hash cache
                if getscripthash then
                    pcall(function()
                        local hash = getscripthash(scriptInstance)
                        if hash then
                            if not BaoSaveInstance._hashCache then BaoSaveInstance._hashCache = {} end
                            if not BaoSaveInstance._hashCache[hash] or
                               BaoSaveInstance._hashCache[hash].score < score then
                                BaoSaveInstance._hashCache[hash] = {
                                    source = source,
                                    score = score,
                                    name = scriptInstance:GetFullName(),
                                }
                            end
                        end
                    end)
                end

                if score > bestScore then
                    bestScore = score
                    bestSource = source
                    bestAPI = apiName
                end

                -- If excellent quality, stop trying
                if score >= 80 then
                    goto done_decompiling
                end

                -- If good quality, don't retry this API but try others
                if score >= 50 then
                    break
                end
            end

            -- Retry delay
            if attempt < BaoSaveConfig.MaxRetries then
                if task and task.wait then task.wait(BaoSaveConfig.RetryDelay) else wait(BaoSaveConfig.RetryDelay) end
            end
        end

        if not BaoSaveConfig.EnableFallback then break end
        ::continue_api::
    end

    ::done_decompiling::

    -- Smart Merge if multiple results
    if #allResults > 1 and BaoSaveConfig.EnableSmartMerge then
        local merged = SmartMerger:MergeResults(allResults)
        if merged then
            local mergedScore = QualityScorer:Score(merged, scriptInstance)
            if mergedScore > bestScore then
                bestSource = merged
                bestScore = mergedScore
                bestAPI = bestAPI .. "+MERGED"
            end
        end
    end

    -- Update quality distribution
    QualityScorer:UpdateDistribution(bestScore)

    -- Final fallback
    if not bestSource or bestScore < 5 then
        bestSource = string.format(
            "-- ╔══════════════════════════════════════════════════╗\n" ..
            "-- ║ [BaoSaveInstance] DECOMPILE KHÔNG THÀNH CÔNG     ║\n" ..
            "-- ╚══════════════════════════════════════════════════╝\n" ..
            "-- Script: %s\n" ..
            "-- ClassName: %s\n" ..
            "-- Đã thử %d APIs, %d lần\n" ..
            "-- Best score: %d\n" ..
            "-- Exploit: %s\n" ..
            "-- Lý do có thể:\n" ..
            "--   • Script bytecode bị bảo vệ/mã hóa\n" ..
            "--   • Server-side script (không truy cập được từ client)\n" ..
            "--   • Script đã bị xóa hoặc không còn source\n" ..
            "--   • Exploit API không đủ mạnh\n",
            scriptInstance:GetFullName(),
            scriptInstance.ClassName,
            #apiOrder,
            #allResults,
            bestScore,
            ExploitEnv.name
        )

        -- Try to add any available metadata
        pcall(function()
            if getscripthash then
                local hash = getscripthash(scriptInstance)
                bestSource = bestSource .. "-- Script Hash: " .. tostring(hash) .. "\n"
            end
        end)

        pcall(function()
            if getscriptbytecode then
                local bc = getscriptbytecode(scriptInstance)
                if bc then
                    bestSource = bestSource .. "-- Bytecode Size: " .. #bc .. " bytes\n"
                    BaoSaveInstance.Stats.BytecodeRecovered = BaoSaveInstance.Stats.BytecodeRecovered + 1
                end
            end
        end)

        return bestSource, false, "FAILED", bestScore
    end

    local isPartial = bestScore < BaoSaveConfig.QualityThreshold
    if isPartial then
        BaoSaveInstance.Stats.PartialScripts = BaoSaveInstance.Stats.PartialScripts + 1
    end

    return bestSource, true, bestAPI, bestScore
end

-- ═══════════════════════════════════════════════════════════════════════
-- PHẦN 5: ADVANCED INSTANCE COLLECTOR
-- ═══════════════════════════════════════════════════════════════════════

local Collector = {}

function Collector:GetAllScripts()
    local scripts = {}
    local seen = {}

    local function addScript(s)
        if not seen[s] then
            seen[s] = true
            if not BaoSaveConfig.SkipCoreScripts or not s:IsDescendantOf(Services.CoreGui or game) then
                table.insert(scripts, s)
            end
        end
    end

    -- Method 1: getscripts()
    if getscripts then
        pcall(function()
            for _, s in ipairs(getscripts()) do
                if s:IsA("LuaSourceContainer") then
                    addScript(s)
                end
            end
        end)
        Logger:Debug("getscripts(): " .. #scripts .. " scripts")
    end

    -- Method 2: Service scanning
    local scanServices = {
        "Workspace", "ReplicatedStorage", "ReplicatedFirst", "StarterGui",
        "StarterPack", "StarterPlayer", "Lighting", "SoundService",
        "Chat", "TestService", "LocalizationService", "ServerScriptService",
        "ServerStorage", "Teams",
    }

    for _, svcName in ipairs(scanServices) do
        pcall(function()
            local svc = game:GetService(svcName)
            for _, obj in ipairs(svc:GetDescendants()) do
                if obj:IsA("LuaSourceContainer") then
                    addScript(obj)
                end
            end
        end)
    end

    -- Method 3: Player instances
    if BaoSaveConfig.IncludePlayerGui and LocalPlayer then
        pcall(function()
            for _, child in ipairs(LocalPlayer:GetChildren()) do
                pcall(function()
                    for _, obj in ipairs(child:GetDescendants()) do
                        if obj:IsA("LuaSourceContainer") then
                            addScript(obj)
                        end
                    end
                end)
            end
        end)
    end

    -- Method 4: Nil instances
    if BaoSaveConfig.IncludeNilInstances and getnilinstances then
        pcall(function()
            for _, obj in ipairs(getnilinstances()) do
                if obj:IsA("LuaSourceContainer") then
                    addScript(obj)
                end
            end
        end)
    end

    -- Method 5: getinstances() global scan
    if getinstances then
        pcall(function()
            for _, obj in ipairs(getinstances()) do
                if obj:IsA("LuaSourceContainer") then
                    addScript(obj)
                end
            end
        end)
    end

    -- Method 6: GC scan for script references
    if getgc then
        pcall(function()
            for _, obj in ipairs(getgc(true)) do
                if typeof(obj) == "Instance" and obj:IsA("LuaSourceContainer") then
                    addScript(obj)
                end
            end
        end)
    end

    -- Sort by location
    table.sort(scripts, function(a, b)
        return a:GetFullName() < b:GetFullName()
    end)

    Logger:Info(string.format("Thu thập được %d scripts (6 phương pháp)", #scripts))
    return scripts
end

function Collector:GetAllGameServices()
    local services = {}
    local importantServices = {
        "Workspace", "Lighting", "ReplicatedFirst", "ReplicatedStorage",
        "StarterGui", "StarterPack", "StarterPlayer", "SoundService",
        "Chat", "LocalizationService", "TestService", "Teams",
        "ServerScriptService", "ServerStorage", "TextChatService",
        "MaterialService",
    }

    for _, name in ipairs(importantServices) do
        pcall(function()
            local svc = game:GetService(name)
            if svc then
                local childCount = #svc:GetChildren()
                local descCount = DeepCount(svc)
                table.insert(services, {
                    name = name,
                    instance = svc,
                    childCount = childCount,
                    descendantCount = descCount,
                })
                BaoSaveInstance.Stats.ServicesCaptured[name] = descCount
            end
        end)
    end

    return services
end

function Collector:GetAssetIds()
    local assets = {}
    local seen = {}

    local function scanForAssets(instance)
        pcall(function()
            for _, prop in ipairs({"Image", "Texture", "TextureId", "MeshId",
                "SoundId", "AnimationId", "Face", "Graphic"}) do
                pcall(function()
                    local value = instance[prop]
                    if value and type(value) == "string" and #value > 0 and not seen[value] then
                        seen[value] = true
                        table.insert(assets, {
                            id = value,
                            property = prop,
                            instance = instance:GetFullName(),
                            className = instance.ClassName,
                        })
                    end
                end)
            end
        end)
    end

    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            scanForAssets(obj)
        end
    end)

    BaoSaveInstance.Stats.TotalAssets = #assets
    Logger:Info(string.format("Tìm thấy %d unique assets", #assets))
    return assets
end

function Collector:CountProperties(instance)
    local count = 0
    pcall(function()
        -- Try to get all properties
        local props = instance:GetAttributes()
        for _ in pairs(props) do count = count + 1 end

        -- Standard properties estimation
        if instance:IsA("BasePart") then count = count + 25
        elseif instance:IsA("GuiObject") then count = count + 20
        elseif instance:IsA("Light") then count = count + 10
        else count = count + 8 end
    end)
    return count
end

-- ═══════════════════════════════════════════════════════════════════════
-- PHẦN 6: DECOMPILE ENGINE
-- ═══════════════════════════════════════════════════════════════════════

local DecompileEngine = {}

function DecompileEngine:DecompileAllScripts(scripts, progressCallback)
    local results = {}
    local total = #scripts

    Logger:Info(string.format("Bắt đầu decompile %d scripts với %d APIs...", total, 12))

    for i, scriptInstance in ipairs(scripts) do
        if BaoSaveInstance._cancelled then
            Logger:Warn("Decompile đã bị hủy bởi người dùng")
            break
        end

        if progressCallback then
            progressCallback(i, total, scriptInstance:GetFullName(), "decompiling")
        end

        local source, success, apiUsed, score = DecompileScriptUltra(scriptInstance)

        results[scriptInstance] = {
            source = source,
            success = success,
            apiUsed = apiUsed,
            score = score,
            fullName = scriptInstance:GetFullName(),
            className = scriptInstance.ClassName,
            name = scriptInstance.Name,
            parent = scriptInstance.Parent and scriptInstance.Parent:GetFullName() or "nil",
        }

        if success then
            BaoSaveInstance.Stats.DecompiledScripts = BaoSaveInstance.Stats.DecompiledScripts + 1
        else
            BaoSaveInstance.Stats.FailedScripts = BaoSaveInstance.Stats.FailedScripts + 1
        end

        local grade, icon = QualityScorer:GetGrade(score)
        Logger:Debug(string.format("[%d/%d] %s %s (API: %s, Score: %d, Grade: %s)",
            i, total, icon, scriptInstance.Name, apiUsed, score, grade))

        SmartYield(i)
    end

    BaoSaveInstance.Stats.TotalScripts = total
    return results
end

function DecompileEngine:SaveScriptsToFolder(results)
    if not ExploitEnv.hasWriteFile then
        Logger:Warn("writefile() không khả dụng")
        return false
    end

    local gameName = SanitizeFileName(GetGameName())
    local rootFolder = BaoSaveConfig.ExportScriptsSubfolder .. "/" .. gameName

    -- Create folder structure
    if ExploitEnv.hasMakeFolder then
        pcall(function() makefolder(BaoSaveConfig.ExportScriptsSubfolder) end)
        pcall(function() makefolder(rootFolder) end)

        if BaoSaveConfig.CreateProjectStructure then
            local subfolders = {
                "LocalScripts", "ModuleScripts", "ServerScripts",
                "Failed", "Partial",
            }
            for _, sf in ipairs(subfolders) do
                pcall(function() makefolder(rootFolder .. "/" .. sf) end)
            end
        end
    end

    local savedCount = 0
    local indexLines = {"-- BaoSaveInstance Script Index", "-- Game: " .. gameName, "-- " .. os.date(), ""}

    for scriptInstance, data in pairs(results) do
        if data.source and #data.source > 0 then
            -- Determine subfolder
            local subFolder = ""
            if BaoSaveConfig.CreateProjectStructure then
                if not data.success then
                    subFolder = "Failed/"
                elseif data.score < BaoSaveConfig.QualityThreshold then
                    subFolder = "Partial/"
                elseif data.className == "LocalScript" then
                    subFolder = "LocalScripts/"
                elseif data.className == "ModuleScript" then
                    subFolder = "ModuleScripts/"
                else
                    subFolder = "ServerScripts/"
                end
            end

            local safeName = data.fullName:gsub("[%.:/\\%c]", "_"):sub(1, 150)
            local ext = ({ModuleScript = ".module.lua", LocalScript = ".local.lua", Script = ".server.lua"})[data.className] or ".lua"

            local grade, icon = QualityScorer:GetGrade(data.score)

            -- Add header comment
            local header = string.format(
                "-- ═══════════════════════════════════════\n" ..
                "-- BaoSaveInstance v%s\n" ..
                "-- Script: %s\n" ..
                "-- Class: %s\n" ..
                "-- API: %s\n" ..
                "-- Quality: %s (Score: %d)\n" ..
                "-- Path: %s\n" ..
                "-- ═══════════════════════════════════════\n\n",
                BaoSaveInstance.Version,
                data.name,
                data.className,
                data.apiUsed,
                grade,
                data.score,
                data.fullName
            )

            local fullPath = rootFolder .. "/" .. subFolder .. safeName .. ext

            -- Create subfolders if needed
            if ExploitEnv.hasMakeFolder and subFolder ~= "" then
                pcall(function() makefolder(rootFolder .. "/" .. subFolder:sub(1, -2)) end)
            end

            local writeOk = pcall(function()
                writefile(fullPath, header .. data.source)
            end)

            if writeOk then
                savedCount = savedCount + 1
                table.insert(indexLines, string.format("%s [%s] %s → %s",
                    icon, grade, data.fullName, subFolder .. safeName .. ext))
            end
        end
    end

    -- Write index file
    pcall(function()
        writefile(rootFolder .. "/_INDEX.txt", table.concat(indexLines, "\n"))
    end)

    Logger:Success(string.format("Đã lưu %d scripts vào: %s", savedCount, rootFolder))
    return true, savedCount
end

-- ═══════════════════════════════════════════════════════════════════════
-- PHẦN 7: SAVE ENGINE
-- ═══════════════════════════════════════════════════════════════════════

local SaveEngine = {}

function SaveEngine:InjectSources(decompileResults)
    if not decompileResults then return 0 end
    local injected = 0

    for scriptInst, data in pairs(decompileResults) do
        if data.success and data.source then
            pcall(function()
                if setsource then setsource(scriptInst, data.source); injected = injected + 1
                elseif setscriptsource then setscriptsource(scriptInst, data.source); injected = injected + 1
                elseif sethiddenproperty then
                    sethiddenproperty(scriptInst, "Source", data.source); injected = injected + 1
                end
            end)
        end
    end

    Logger:Debug(string.format("Injected source cho %d scripts", injected))
    return injected
end

function SaveEngine:Save(fileName, mode, decompileResults)
    Logger:Info("═══ Saving: " .. fileName .. " ═══")

    if decompileResults then
        self:InjectSources(decompileResults)
    end

    local saved = false

    -- Method 1: saveinstance with full options
    if saveinstance then
        local options = {
            FileName = fileName,
            DecompileMode = "custom",
            NilInstances = BaoSaveConfig.IncludeNilInstances,
            RemovePlayerCharacters = true,
            SavePlayers = false,
            ShowStatus = true,
            mode = "optimized",
            noscripts = (mode == "map" or mode == "terrain"),
            scriptcache = true,
            decomptype = "custom",
            timeout = 120,
            ExtraInstances = {},
            DecompileIgnore = {},
            SaveBytecode = true,
        }

        if mode == "terrain" then
            options.ExtraInstances = {}
            pcall(function() table.insert(options.ExtraInstances, Workspace.Terrain) end)
        end

        if mode == "full" or mode == "scripts" then
            -- Custom decompiler override
            if decompileResults then
                options.DecompileFunction = function(scriptInst)
                    if decompileResults[scriptInst] and decompileResults[scriptInst].success then
                        return decompileResults[scriptInst].source
                    end
                    local src = DecompileScriptUltra(scriptInst)
                    return src or "-- Could not decompile"
                end
                options.CustomDecompiler = options.DecompileFunction
            end
        end

        local tryOptions = {options}

        -- Fallback options
        table.insert(tryOptions, {
            FileName = fileName,
            NilInstances = true,
            RemovePlayerCharacters = true,
            noscripts = (mode == "map" or mode == "terrain"),
        })
        table.insert(tryOptions, {FileName = fileName})

        for i, opts in ipairs(tryOptions) do
            local s, e = pcall(saveinstance, opts)
            if s then
                saved = true
                Logger:Success("saveinstance() thành công (attempt " .. i .. ")")
                break
            else
                Logger:Warn("saveinstance() attempt " .. i .. " thất bại: " .. tostring(e))
            end
        end
    end

    -- Method 2: syn.saveinstance
    if not saved and syn and syn.saveinstance then
        local s, e = pcall(syn.saveinstance, {FileName = fileName, DecompileMode = "custom", NilInstances = true})
        if s then
            saved = true
            Logger:Success("syn.saveinstance() thành công")
        end
    end

    -- Method 3: Save scripts only
    if not saved and decompileResults and ExploitEnv.hasWriteFile then
        Logger:Warn("saveinstance không khả dụng, lưu scripts ra folder...")
        DecompileEngine:SaveScriptsToFolder(decompileResults)
        saved = true
    end

    if not saved then
        Logger:Critical("KHÔNG THỂ LƯU FILE - Không có phương pháp save nào hoạt động!")
    end

    return saved
end

-- ═══════════════════════════════════════════════════════════════════════
-- PHẦN 8: REPORT GENERATOR
-- ═══════════════════════════════════════════════════════════════════════

local ReportGenerator = {}

function ReportGenerator:Generate(mode, fileName, decompileResults)
    local elapsed = BaoSaveInstance.Stats.EndTime - BaoSaveInstance.Stats.StartTime
    local stats = BaoSaveInstance.Stats
    local qd = stats.QualityDistribution

    local lines = {
        "╔══════════════════════════════════════════════════════════════╗",
        "║            BaoSaveInstance v" .. BaoSaveInstance.Version .. " - BÁO CÁO CHI TIẾT            ║",
        "╚══════════════════════════════════════════════════════════════╝",
        "",
        "═══ THÔNG TIN CHUNG ═══",
        "Game: " .. GetGameName(),
        "PlaceId: " .. game.PlaceId,
        "Mode: " .. (mode or "N/A"),
        "Exploit: " .. ExploitEnv.name,
        "Thời gian: " .. string.format("%.2f giây", elapsed),
        "File: " .. (fileName or "N/A"),
        "Memory Peak: " .. string.format("%.1f MB", stats.MemoryPeak),
        "",
        "═══ THỐNG KÊ SCRIPTS ═══",
        "Tổng scripts: " .. stats.TotalScripts,
        "Decompile thành công: " .. stats.DecompiledScripts ..
            string.format(" (%.1f%%)", stats.TotalScripts > 0 and (stats.DecompiledScripts/stats.TotalScripts*100) or 0),
        "Decompile thất bại: " .. stats.FailedScripts,
        "Decompile một phần: " .. stats.PartialScripts,
        "Smart Merged: " .. stats.MergedScripts,
        "Bytecode recovered: " .. stats.BytecodeRecovered,
        "Constants extracted: " .. stats.ConstantsExtracted,
        "Upvalues recovered: " .. stats.UpvaluesRecovered,
        "",
        "═══ CHẤT LƯỢNG ═══",
        "🟢 Excellent (80+): " .. qd.excellent,
        "🟡 Good (50-79): " .. qd.good,
        "🟠 Fair (30-49): " .. qd.fair,
        "🔴 Poor (10-29): " .. qd.poor,
        "⚫ Failed (<10): " .. qd.failed,
        "",
        "═══ API USAGE ═══",
    }

    for api, count in pairs(stats.APIUsageStats) do
        local apiName = DecompilerAPIs[api] and DecompilerAPIs[api].Name or api
        table.insert(lines, string.format("  %s (%s): %d lần", api, apiName, count))
    end

    table.insert(lines, "")
    table.insert(lines, "═══ SERVICES CAPTURED ═══")
    for svc, count in pairs(stats.ServicesCaptured) do
        table.insert(lines, string.format("  %s: %d instances", svc, count))
    end

    if decompileResults then
        table.insert(lines, "")
        table.insert(lines, "═══ CHI TIẾT TỪNG SCRIPT ═══")

        local sortedResults = {}
        for inst, data in pairs(decompileResults) do
            table.insert(sortedResults, data)
        end
        table.sort(sortedResults, function(a, b) return (a.score or 0) > (b.score or 0) end)

        for _, data in ipairs(sortedResults) do
            local grade, icon = QualityScorer:GetGrade(data.score or 0)
            table.insert(lines, string.format("%s [%s] Score:%d API:%s Len:%d | %s",
                icon, grade, data.score or 0, data.apiUsed or "?",
                data.source and #data.source or 0, data.fullName or "?"))
        end
    end

    local report = table.concat(lines, "\n")

    -- Print summary
    Logger:Info("╔══════════════════════════════════════════════════╗")
    Logger:Info("║              BÁO CÁO TỔNG KẾT                  ║")
    Logger:Info("╠══════════════════════════════════════════════════╣")
    Logger:Info(string.format("║ Thời gian: %.2f giây", elapsed))
    Logger:Info(string.format("║ Scripts: %d/%d thành công (%.1f%%)",
        stats.DecompiledScripts, stats.TotalScripts,
        stats.TotalScripts > 0 and (stats.DecompiledScripts/stats.TotalScripts*100) or 0))
    Logger:Info(string.format("║ Quality: 🟢%d 🟡%d 🟠%d 🔴%d ⚫%d",
        qd.excellent, qd.good, qd.fair, qd.poor, qd.failed))
    Logger:Info(string.format("║ Memory Peak: %.1f MB", stats.MemoryPeak))
    Logger:Info("╚══════════════════════════════════════════════════╝")

    -- Save report to file
    if BaoSaveConfig.GenerateReport and ExploitEnv.hasWriteFile then
        local reportFile = (fileName or "BaoSaveInstance"):gsub("%.rbxl$", "") .. "_REPORT.txt"
        pcall(function() writefile(reportFile, report) end)
        Logger:Info("Báo cáo đã lưu: " .. reportFile)
    end

    return report
end

-- ═══════════════════════════════════════════════════════════════════════
-- PHẦN 9: 5 CHẾ ĐỘ CHÍNH
-- ═══════════════════════════════════════════════════════════════════════

local function ResetStats()
    BaoSaveInstance.Stats = {
        TotalScripts = 0, DecompiledScripts = 0, FailedScripts = 0,
        PartialScripts = 0, MergedScripts = 0, TotalInstances = 0,
        TotalProperties = 0, TotalAssets = 0, BytecodeRecovered = 0,
        ConstantsExtracted = 0, UpvaluesRecovered = 0,
        StartTime = tick(), EndTime = 0, MemoryPeak = 0,
        APIUsageStats = {},
        QualityDistribution = {excellent = 0, good = 0, fair = 0, poor = 0, failed = 0},
        ServicesCaptured = {}, ErrorLog = {},
    }
end

local function StandardProgressCallback(current, total, name, phase)
    if current % math.max(math.floor(total / 20), 1) == 0 or current == total or current == 1 then
        Logger:Progress(string.format("[%s] %d/%d (%.1f%%) - %s",
            phase or "Processing", current, total, (current/total)*100,
            name and name:sub(-60) or ""))
    end
    if BaoSaveInstance._UIProgressCallback then
        pcall(BaoSaveInstance._UIProgressCallback, current, total, phase or "Processing")
    end
end

-- ──── MODE 1: DECOMPILE GAME (FULL) ────
function BaoSaveInstance.DecompileGame()
    if BaoSaveInstance._running then
        Logger:Warn("Đang có tiến trình chạy!")
        return false
    end
    BaoSaveInstance._running = true
    BaoSaveInstance._cancelled = false
    ResetStats()

    Logger:Info("╔══════════════════════════════════════════════════════╗")
    Logger:Info("║     BaoSaveInstance v" .. BaoSaveInstance.Version .. " - DECOMPILE GAME (FULL)     ║")
    Logger:Info("╚══════════════════════════════════════════════════════╝")
    Logger:Info("Game: " .. GetGameName())

    -- Phase 1: Initialize
    Logger:Info("═══ PHASE 1/6: Khởi tạo APIs ═══")
    local apiCount = InitializeDecompilers()

    -- Phase 2: Collect
    Logger:Info("═══ PHASE 2/6: Thu thập dữ liệu ═══")
    local allScripts = Collector:GetAllScripts()
    local allServices = Collector:GetAllGameServices()
    local allAssets = Collector:GetAssetIds()

    local totalInstances = 0
    for _, svc in ipairs(allServices) do
        totalInstances = totalInstances + svc.descendantCount
    end
    BaoSaveInstance.Stats.TotalInstances = totalInstances

    Logger:Info(string.format("Scripts: %d | Services: %d | Instances: %d | Assets: %d",
        #allScripts, #allServices, totalInstances, #allAssets))

    -- Phase 3: Decompile
    Logger:Info("═══ PHASE 3/6: Decompile Scripts ═══")
    local decompileResults = nil
    if #allScripts > 0 and apiCount > 0 then
        decompileResults = DecompileEngine:DecompileAllScripts(allScripts, StandardProgressCallback)
    end

    -- Phase 4: Save scripts to folder
    Logger:Info("═══ PHASE 4/6: Lưu scripts ra folder ═══")
    if BaoSaveConfig.SaveScriptsToFolder and decompileResults then
        DecompileEngine:SaveScriptsToFolder(decompileResults)
    end

    -- Phase 5: Save instance
    Logger:Info("═══ PHASE 5/6: Lưu file .rbxl ═══")
    local fileName = GenerateFileName("Full")
    local saved = SaveEngine:Save(fileName, "full", decompileResults)

    -- Phase 6: Report
    Logger:Info("═══ PHASE 6/6: Tạo báo cáo ═══")
    BaoSaveInstance.Stats.EndTime = tick()
    ReportGenerator:Generate("Full Game", fileName, decompileResults)

    MemoryManager:Optimize()
    Logger:FlushToFile()
    BaoSaveInstance._running = false

    return saved, fileName
end

-- ──── MODE 2: DECOMPILE MAP ────
function BaoSaveInstance.DecompileMap()
    if BaoSaveInstance._running then Logger:Warn("Đang chạy!"); return false end
    BaoSaveInstance._running = true
    BaoSaveInstance._cancelled = false
    ResetStats()

    Logger:Info("╔═══════════════════════════════════════════════╗")
    Logger:Info("║     BaoSaveInstance - DECOMPILE MAP            ║")
    Logger:Info("╚═══════════════════════════════════════════════╝")

    local totalInst = DeepCount(Workspace) + DeepCount(Services.Lighting or game)
    BaoSaveInstance.Stats.TotalInstances = totalInst
    Logger:Info(string.format("Map instances: %d", totalInst))

    -- Terrain info
    pcall(function()
        if Workspace.Terrain then
            Logger:Info("Terrain: Detected ✓")
        end
    end)

    local fileName = GenerateFileName("Map")
    local saved = SaveEngine:Save(fileName, "map", nil)

    BaoSaveInstance.Stats.EndTime = tick()
    ReportGenerator:Generate("Map Only", fileName, nil)

    BaoSaveInstance._running = false
    return saved, fileName
end

-- ──── MODE 3: DECOMPILE TERRAIN ────
function BaoSaveInstance.DecompileTerrain()
    if BaoSaveInstance._running then Logger:Warn("Đang chạy!"); return false end
    BaoSaveInstance._running = true
    BaoSaveInstance._cancelled = false
    ResetStats()

    Logger:Info("╔═══════════════════════════════════════════════╗")
    Logger:Info("║     BaoSaveInstance - DECOMPILE TERRAIN        ║")
    Logger:Info("╚═══════════════════════════════════════════════╝")

    local terrain = nil
    pcall(function() terrain = Workspace.Terrain end)

    if not terrain then
        Logger:Error("Workspace.Terrain không tìm thấy!")
        BaoSaveInstance._running = false
        return false
    end

    -- Analyze terrain
    Logger:Info("Đang phân tích Terrain...")
    pcall(function()
        local properties = {
            "WaterColor", "WaterReflectance", "WaterTransparency",
            "WaterWaveSize", "WaterWaveSpeed", "Decoration",
            "MaterialColors",
        }
        for _, prop in ipairs(properties) do
            pcall(function()
                Logger:Debug(string.format("Terrain.%s = %s", prop, tostring(terrain[prop])))
            end)
        end
    end)

    -- Try to get terrain size info
    pcall(function()
        local regionSize = 512
        local testRegion = Region3.new(
            Vector3.new(-regionSize, -regionSize, -regionSize),
            Vector3.new(regionSize, regionSize, regionSize)
        ):ExpandToGrid(4)
        local mats, occ = terrain:ReadVoxels(testRegion, 4)
        if mats then
            local nonAir = 0
            for x = 1, #mats do
                for y = 1, #mats[x] do
                    for z = 1, #mats[x][y] do
                        if mats[x][y][z] ~= Enum.Material.Air then
                            nonAir = nonAir + 1
                        end
                    end
                end
            end
            Logger:Info(string.format("Terrain voxels (non-air): ~%d", nonAir))
        end
    end)

    local fileName = GenerateFileName("Terrain")
    local saved = SaveEngine:Save(fileName, "terrain", nil)

    BaoSaveInstance.Stats.EndTime = tick()
    ReportGenerator:Generate("Terrain Only", fileName, nil)

    BaoSaveInstance._running = false
    return saved, fileName
end

-- ──── MODE 4: DECOMPILE SCRIPTS ────
function BaoSaveInstance.DecompileScripts()
    if BaoSaveInstance._running then Logger:Warn("Đang chạy!"); return false end
    BaoSaveInstance._running = true
    BaoSaveInstance._cancelled = false
    ResetStats()

    Logger:Info("╔═══════════════════════════════════════════════╗")
    Logger:Info("║     BaoSaveInstance - DECOMPILE SCRIPTS        ║")
    Logger:Info("╚═══════════════════════════════════════════════╝")

    local apiCount = InitializeDecompilers()
    if apiCount == 0 then
        Logger:Critical("Không có API decompile nào!")
        BaoSaveInstance._running = false
        return false
    end

    local allScripts = Collector:GetAllScripts()
    if #allScripts == 0 then
        Logger:Warn("Không tìm thấy scripts!")
        BaoSaveInstance._running = false
        return false
    end

    -- Categorize
    local categories = {LocalScript = {}, ModuleScript = {}, Script = {}}
    for _, s in ipairs(allScripts) do
        local cat = categories[s.ClassName]
        if cat then table.insert(cat, s) end
    end

    Logger:Info(string.format("Scripts: %d total | %d Local | %d Module | %d Server",
        #allScripts, #categories.LocalScript, #categories.ModuleScript, #categories.Script))

    local decompileResults = DecompileEngine:DecompileAllScripts(allScripts, StandardProgressCallback)

    if BaoSaveConfig.SaveScriptsToFolder then
        DecompileEngine:SaveScriptsToFolder(decompileResults)
    end

    local fileName = GenerateFileName("Scripts")
    local saved = SaveEngine:Save(fileName, "scripts", decompileResults)

    BaoSaveInstance.Stats.EndTime = tick()
    ReportGenerator:Generate("Scripts Only", fileName, decompileResults)

    MemoryManager:Optimize()
    Logger:FlushToFile()
    BaoSaveInstance._running = false

    return saved, fileName
end

-- ──── MODE 5: DECOMPILE ASSETS ────
function BaoSaveInstance.DecompileAssets()
    if BaoSaveInstance._running then Logger:Warn("Đang chạy!"); return false end
    BaoSaveInstance._running = true
    BaoSaveInstance._cancelled = false
    ResetStats()

    Logger:Info("╔═══════════════════════════════════════════════╗")
    Logger:Info("║     BaoSaveInstance - EXPORT ASSETS            ║")
    Logger:Info("╚═══════════════════════════════════════════════╝")

    local assets = Collector:GetAssetIds()

    if #assets == 0 then
        Logger:Warn("Không tìm thấy assets!")
        BaoSaveInstance._running = false
        return false
    end

    -- Export asset list
    if ExploitEnv.hasWriteFile then
        local assetLines = {
            "-- BaoSaveInstance Asset Export",
            "-- Game: " .. GetGameName(),
            "-- Total: " .. #assets,
            "",
        }

        local byType = {}
        for _, asset in ipairs(assets) do
            local cat = asset.property or "Unknown"
            if not byType[cat] then byType[cat] = {} end
            table.insert(byType[cat], asset)
        end

        for cat, catAssets in pairs(byType) do
            table.insert(assetLines, "═══ " .. cat .. " (" .. #catAssets .. ") ═══")
            for _, a in ipairs(catAssets) do
                table.insert(assetLines, string.format("  %s | %s | %s",
                    a.id, a.className, a.instance))
            end
            table.insert(assetLines, "")
        end

        local assetFile = GetGameName() .. " Assets By BaoSaveInstance.txt"
        pcall(function() writefile(assetFile, table.concat(assetLines, "\n")) end)
        Logger:Success("Đã xuất " .. #assets .. " assets → " .. assetFile)
    end

    BaoSaveInstance.Stats.EndTime = tick()
    BaoSaveInstance._running = false
    return true
end

-- ═══════════════════════════════════════════════════════════════════════
-- PHẦN 10: QUICK TOOLS
-- ═══════════════════════════════════════════════════════════════════════

function BaoSaveInstance.QuickDecompile(scriptInstance)
    if not scriptInstance or not scriptInstance:IsA("LuaSourceContainer") then
        Logger:Error("Instance không hợp lệ!")
        return nil
    end
    InitializeDecompilers()
    local source, success, api, score = DecompileScriptUltra(scriptInstance)
    local grade, icon = QualityScorer:GetGrade(score)
    Logger:Info(string.format("QuickDecompile: %s %s | API:%s | Score:%d | Grade:%s | Len:%d",
        icon, scriptInstance:GetFullName(), api, score, grade, source and #source or 0))
    return source, success, api, score
end

function BaoSaveInstance.SetConfig(key, value)
    if BaoSaveConfig[key] ~= nil then
        BaoSaveConfig[key] = value
        Logger:Info(string.format("Config: %s = %s", key, tostring(value)))
    else
        Logger:Warn("Config key không tồn tại: " .. tostring(key))
    end
end

function BaoSaveInstance.Cancel()
    BaoSaveInstance._cancelled = true
    Logger:Warn("Đã gửi lệnh hủy!")
end

function BaoSaveInstance.RegisterAPI(name, func, priority)
    DecompilerAPIs[name] = {
        Name = name, Priority = priority or 99, Available = true,
        Decompile = function(inst)
            local s, r = pcall(func, inst)
            return s and r or nil, s and nil or tostring(r)
        end,
    }
    Logger:Info("Đã đăng ký API: " .. name)
end

function BaoSaveInstance.GetStats() return BaoSaveInstance.Stats end
function BaoSaveInstance.GetLogs() return Logger.Logs end
function BaoSaveInstance.GetEnv() return ExploitEnv end

-- ═══════════════════════════════════════════════════════════════════════
-- PHẦN 11: ADVANCED GUI
-- ═══════════════════════════════════════════════════════════════════════

function BaoSaveInstance.CreateUI()
    -- Clean up old GUI
    pcall(function()
        if Services.CoreGui:FindFirstChild("BaoSaveInstanceGUI") then
            Services.CoreGui.BaoSaveInstanceGUI:Destroy()
        end
    end)
    pcall(function()
        if LocalPlayer and LocalPlayer.PlayerGui:FindFirstChild("BaoSaveInstanceGUI") then
            LocalPlayer.PlayerGui.BaoSaveInstanceGUI:Destroy()
        end
    end)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BaoSaveInstanceGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999999

    -- Place GUI safely
    local guiParent = Services.CoreGui
    pcall(function()
        if gethui then guiParent = gethui()
        elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
    end)
    local s = pcall(function() ScreenGui.Parent = guiParent end)
    if not s then pcall(function() ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end) end

    -- Colors
    local C = {
        BG = Color3.fromRGB(15, 15, 25),
        BG2 = Color3.fromRGB(25, 25, 40),
        BG3 = Color3.fromRGB(35, 35, 55),
        Accent = Color3.fromRGB(99, 102, 241),
        AccentH = Color3.fromRGB(129, 132, 255),
        Green = Color3.fromRGB(34, 197, 94),
        Orange = Color3.fromRGB(249, 115, 22),
        Red = Color3.fromRGB(239, 68, 68),
        Purple = Color3.fromRGB(168, 85, 247),
        Cyan = Color3.fromRGB(6, 182, 212),
        Yellow = Color3.fromRGB(234, 179, 8),
        Text = Color3.fromRGB(226, 232, 240),
        TextDim = Color3.fromRGB(148, 163, 184),
        TextBright = Color3.fromRGB(248, 250, 252),
        Border = Color3.fromRGB(51, 65, 85),
    }

    -- Main Frame
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 580, 0, 720)
    Main.Position = UDim2.new(0.5, -290, 0.5, -360)
    Main.BackgroundColor3 = C.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)
    local stroke = Instance.new("UIStroke", Main)
    stroke.Color = C.Border; stroke.Thickness = 1.5; stroke.Transparency = 0.3

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 56)
    TitleBar.BackgroundColor3 = C.BG2
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Main
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 16)
    local tbFix = Instance.new("Frame", TitleBar)
    tbFix.Size = UDim2.new(1, 0, 0, 16); tbFix.Position = UDim2.new(0, 0, 1, -16)
    tbFix.BackgroundColor3 = C.BG2; tbFix.BorderSizePixel = 0

    -- Title gradient
    local titleGrad = Instance.new("Frame")
    titleGrad.Size = UDim2.new(0, 4, 0, 30)
    titleGrad.Position = UDim2.new(0, 16, 0.5, -15)
    titleGrad.BackgroundColor3 = C.Accent
    titleGrad.BorderSizePixel = 0
    titleGrad.Parent = TitleBar
    Instance.new("UICorner", titleGrad).CornerRadius = UDim.new(0, 2)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(0, 350, 0, 24)
    TitleLabel.Position = UDim2.new(0, 30, 0, 8)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "⚡ BaoSaveInstance v" .. BaoSaveInstance.Version
    TitleLabel.TextColor3 = C.TextBright
    TitleLabel.TextSize = 18
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    local SubLabel = Instance.new("TextLabel")
    SubLabel.Size = UDim2.new(0, 350, 0, 16)
    SubLabel.Position = UDim2.new(0, 30, 0, 32)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Text = "Ultimate Game Decompiler • 12 APIs • Smart Merge"
    SubLabel.TextColor3 = C.TextDim
    SubLabel.TextSize = 10
    SubLabel.Font = Enum.Font.Gotham
    SubLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubLabel.Parent = TitleBar

    -- Window buttons
    local function makeWindowBtn(text, color, posX)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 28, 0, 28)
        btn.Position = UDim2.new(1, posX, 0.5, -14)
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.3
        btn.Text = text
        btn.TextColor3 = C.TextBright
        btn.TextSize = 16
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = TitleBar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        return btn
    end

    local MinBtn = makeWindowBtn("−", C.BG3, -75)
    local CancelBtn = makeWindowBtn("■", C.Orange, -43)
    local CloseBtn = makeWindowBtn("×", C.Red, -11)

    -- Content
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -24, 1, -68)
    Content.Position = UDim2.new(0, 12, 0, 62)
    Content.BackgroundTransparency = 1
    Content.Parent = Main

    -- Info bar
    local InfoBar = Instance.new("Frame")
    InfoBar.Size = UDim2.new(1, 0, 0, 52)
    InfoBar.BackgroundColor3 = C.BG2
    InfoBar.BorderSizePixel = 0
    InfoBar.Parent = Content
    Instance.new("UICorner", InfoBar).CornerRadius = UDim.new(0, 10)

    local InfoText = Instance.new("TextLabel")
    InfoText.Size = UDim2.new(1, -16, 0, 18)
    InfoText.Position = UDim2.new(0, 8, 0, 6)
    InfoText.BackgroundTransparency = 1
    InfoText.Text = "🎮 " .. GetGameName()
    InfoText.TextColor3 = C.TextBright
    InfoText.TextSize = 12
    InfoText.Font = Enum.Font.GothamSemibold
    InfoText.TextXAlignment = Enum.TextXAlignment.Left
    InfoText.TextTruncate = Enum.TextTruncate.AtEnd
    InfoText.Parent = InfoBar

    -- Count available APIs
    local availAPIs = 0
    for _, api in pairs(DecompilerAPIs) do if api.Available then availAPIs = availAPIs + 1 end end

    local InfoText2 = Instance.new("TextLabel")
    InfoText2.Size = UDim2.new(1, -16, 0, 14)
    InfoText2.Position = UDim2.new(0, 8, 0, 26)
    InfoText2.BackgroundTransparency = 1
    InfoText2.Text = string.format("PlaceId: %d | Exploit: %s | APIs: %d/12 | save: %s | write: %s",
        game.PlaceId, ExploitEnv.name, availAPIs,
        ExploitEnv.hasSaveInstance and "✓" or "✗",
        ExploitEnv.hasWriteFile and "✓" or "✗")
    InfoText2.TextColor3 = C.TextDim
    InfoText2.TextSize = 9
    InfoText2.Font = Enum.Font.Gotham
    InfoText2.TextXAlignment = Enum.TextXAlignment.Left
    InfoText2.Parent = InfoBar

    -- Action buttons
    local BtnFrame = Instance.new("Frame")
    BtnFrame.Size = UDim2.new(1, 0, 0, 270)
    BtnFrame.Position = UDim2.new(0, 0, 0, 58)
    BtnFrame.BackgroundTransparency = 1
    BtnFrame.Parent = Content

    local function CreateBtn(name, title, desc, emoji, color, yPos, callback)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 46)
        btn.Position = UDim2.new(0, 0, 0, yPos)
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.15
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Parent = BtnFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = color; btnStroke.Thickness = 1; btnStroke.Transparency = 0.5

        local emojiLabel = Instance.new("TextLabel")
        emojiLabel.Size = UDim2.new(0, 36, 1, 0)
        emojiLabel.Position = UDim2.new(0, 12, 0, 0)
        emojiLabel.BackgroundTransparency = 1
        emojiLabel.Text = emoji
        emojiLabel.TextSize = 22
        emojiLabel.Font = Enum.Font.SourceSans
        emojiLabel.TextColor3 = C.TextBright
        emojiLabel.Parent = btn

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -60, 0, 20)
        titleLabel.Position = UDim2.new(0, 52, 0, 4)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = C.TextBright
        titleLabel.TextSize = 14
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = btn

        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -60, 0, 12)
        descLabel.Position = UDim2.new(0, 52, 0, 26)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = desc
        descLabel.TextColor3 = C.TextDim
        descLabel.TextSize = 9
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = btn

        btn.MouseEnter:Connect(function()
            Services.TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        btn.MouseLeave:Connect(function()
            Services.TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            Services.TweenService:Create(btn, TweenInfo.new(0.05), {BackgroundTransparency = 0.5}):Play()
            task.wait(0.05)
            Services.TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.15}):Play()
            task.spawn(callback)
        end)

        return btn
    end

    CreateBtn("FullBtn", "⚡ Decompile Game (Full)",
        "12 APIs + Smart Merge | Scripts + Map + Terrain + GUI + Assets + Services",
        "🌐", C.Accent, 0, BaoSaveInstance.DecompileGame)

    CreateBtn("MapBtn", "🗺️ Decompile Map",
        "Workspace + Lighting + Terrain + Models + Parts + Meshes + Decals",
        "🏔️", C.Green, 52, BaoSaveInstance.DecompileMap)

    CreateBtn("TerrainBtn", "⛰️ Decompile Terrain",
        "Full voxel data + Water + Materials + Properties",
        "🌊", C.Orange, 104, BaoSaveInstance.DecompileTerrain)

    CreateBtn("ScriptBtn", "📜 Decompile Scripts (Ultra)",
        "12 APIs fallback + Smart Merge + Quality Scoring + Báo cáo chi tiết",
        "⚙️", C.Purple, 156, BaoSaveInstance.DecompileScripts)

    CreateBtn("AssetBtn", "🎨 Export Assets",
        "Tất cả Images, Textures, Meshes, Sounds, Animations",
        "📦", C.Cyan, 208, BaoSaveInstance.DecompileAssets)

    -- Progress section
    local ProgressFrame = Instance.new("Frame")
    ProgressFrame.Size = UDim2.new(1, 0, 0, 50)
    ProgressFrame.Position = UDim2.new(0, 0, 0, 334)
    ProgressFrame.BackgroundColor3 = C.BG2
    ProgressFrame.BorderSizePixel = 0
    ProgressFrame.Parent = Content
    Instance.new("UICorner", ProgressFrame).CornerRadius = UDim.new(0, 10)

    local ProgressText = Instance.new("TextLabel")
    ProgressText.Size = UDim2.new(0.5, -8, 0, 14)
    ProgressText.Position = UDim2.new(0, 10, 0, 5)
    ProgressText.BackgroundTransparency = 1
    ProgressText.Text = "⏳ Sẵn sàng"
    ProgressText.TextColor3 = C.TextDim
    ProgressText.TextSize = 11
    ProgressText.Font = Enum.Font.GothamSemibold
    ProgressText.TextXAlignment = Enum.TextXAlignment.Left
    ProgressText.Parent = ProgressFrame

    local ProgressPct = Instance.new("TextLabel")
    ProgressPct.Size = UDim2.new(0.5, -8, 0, 14)
    ProgressPct.Position = UDim2.new(0.5, 0, 0, 5)
    ProgressPct.BackgroundTransparency = 1
    ProgressPct.Text = ""
    ProgressPct.TextColor3 = C.Accent
    ProgressPct.TextSize = 11
    ProgressPct.Font = Enum.Font.GothamBold
    ProgressPct.TextXAlignment = Enum.TextXAlignment.Right
    ProgressPct.Parent = ProgressFrame

    local ProgressBarBG = Instance.new("Frame")
    ProgressBarBG.Size = UDim2.new(1, -20, 0, 8)
    ProgressBarBG.Position = UDim2.new(0, 10, 0, 24)
    ProgressBarBG.BackgroundColor3 = C.BG
    ProgressBarBG.BorderSizePixel = 0
    ProgressBarBG.Parent = ProgressFrame
    Instance.new("UICorner", ProgressBarBG).CornerRadius = UDim.new(1, 0)

    local ProgressFill = Instance.new("Frame")
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    ProgressFill.BackgroundColor3 = C.Accent
    ProgressFill.BorderSizePixel = 0
    ProgressFill.Parent = ProgressBarBG
    Instance.new("UICorner", ProgressFill).CornerRadius = UDim.new(1, 0)
    local grad = Instance.new("UIGradient", ProgressFill)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.Accent),
        ColorSequenceKeypoint.new(1, C.Purple),
    })

    -- Stats bar
    local StatsText = Instance.new("TextLabel")
    StatsText.Size = UDim2.new(1, -20, 0, 12)
    StatsText.Position = UDim2.new(0, 10, 0, 35)
    StatsText.BackgroundTransparency = 1
    StatsText.Text = ""
    StatsText.TextColor3 = C.TextDim
    StatsText.TextSize = 9
    StatsText.Font = Enum.Font.Gotham
    StatsText.TextXAlignment = Enum.TextXAlignment.Left
    StatsText.Parent = ProgressFrame

    -- Console Log
    local LogFrame = Instance.new("Frame")
    LogFrame.Size = UDim2.new(1, 0, 0, 260)
    LogFrame.Position = UDim2.new(0, 0, 0, 390)
    LogFrame.BackgroundColor3 = C.BG2
    LogFrame.BorderSizePixel = 0
    LogFrame.Parent = Content
    Instance.new("UICorner", LogFrame).CornerRadius = UDim.new(0, 10)

    local LogHeader = Instance.new("Frame")
    LogHeader.Size = UDim2.new(1, 0, 0, 24)
    LogHeader.BackgroundColor3 = C.BG3
    LogHeader.BorderSizePixel = 0
    LogHeader.Parent = LogFrame
    Instance.new("UICorner", LogHeader).CornerRadius = UDim.new(0, 10)
    local logFix = Instance.new("Frame", LogHeader)
    logFix.Size = UDim2.new(1, 0, 0, 10); logFix.Position = UDim2.new(0, 0, 1, -10)
    logFix.BackgroundColor3 = C.BG3; logFix.BorderSizePixel = 0

    local LogTitle = Instance.new("TextLabel")
    LogTitle.Size = UDim2.new(0.5, 0, 1, 0)
    LogTitle.Position = UDim2.new(0, 10, 0, 0)
    LogTitle.BackgroundTransparency = 1
    LogTitle.Text = "📋 Console"
    LogTitle.TextColor3 = C.TextDim
    LogTitle.TextSize = 10
    LogTitle.Font = Enum.Font.GothamSemibold
    LogTitle.TextXAlignment = Enum.TextXAlignment.Left
    LogTitle.Parent = LogHeader

    local ClearBtn2 = Instance.new("TextButton")
    ClearBtn2.Size = UDim2.new(0, 45, 0, 18)
    ClearBtn2.Position = UDim2.new(1, -55, 0.5, -9)
    ClearBtn2.BackgroundColor3 = C.BG
    ClearBtn2.Text = "Clear"
    ClearBtn2.TextColor3 = C.TextDim
    ClearBtn2.TextSize = 9
    ClearBtn2.Font = Enum.Font.Gotham
    ClearBtn2.BorderSizePixel = 0
    ClearBtn2.Parent = LogHeader
    Instance.new("UICorner", ClearBtn2).CornerRadius = UDim.new(0, 4)

    local LogScroll = Instance.new("ScrollingFrame")
    LogScroll.Size = UDim2.new(1, -8, 1, -28)
    LogScroll.Position = UDim2.new(0, 4, 0, 26)
    LogScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
    LogScroll.BorderSizePixel = 0
    LogScroll.ScrollBarThickness = 3
    LogScroll.ScrollBarImageColor3 = C.Accent
    LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogScroll.Parent = LogFrame
    Instance.new("UICorner", LogScroll).CornerRadius = UDim.new(0, 8)
    Instance.new("UIListLayout", LogScroll).Padding = UDim.new(0, 0)
    local lPad = Instance.new("UIPadding", LogScroll)
    lPad.PaddingLeft = UDim.new(0, 6); lPad.PaddingTop = UDim.new(0, 3)

    local logCount = 0
    local colorMap = {
        ERROR = C.Red, WARN = C.Yellow, SUCCESS = C.Green,
        PROGRESS = C.Cyan, DEBUG = Color3.fromRGB(80, 80, 100),
        CRITICAL = Color3.fromRGB(255, 50, 50),
    }

    local function AddLog(text, level)
        logCount = logCount + 1
        local entry = Instance.new("TextLabel")
        entry.Name = "L" .. logCount
        entry.Size = UDim2.new(1, -6, 0, 0)
        entry.AutomaticSize = Enum.AutomaticSize.Y
        entry.BackgroundTransparency = logCount % 2 == 0 and 1 or 0.95
        entry.BackgroundColor3 = C.BG3
        entry.Text = text
        entry.TextSize = 9
        entry.Font = Enum.Font.Code
        entry.TextWrapped = true
        entry.TextXAlignment = Enum.TextXAlignment.Left
        entry.TextColor3 = colorMap[level] or C.Text
        entry.LayoutOrder = logCount
        entry.Parent = LogScroll

        task.defer(function()
            pcall(function()
                LogScroll.CanvasPosition = Vector2.new(0, LogScroll.AbsoluteCanvasSize.Y)
            end)
        end)

        if logCount > 800 then
            local old = LogScroll:FindFirstChild("L" .. (logCount - 800))
            if old then old:Destroy() end
        end
    end

    ClearBtn2.MouseButton1Click:Connect(function()
        for _, c in ipairs(LogScroll:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        logCount = 0
        AddLog("[INFO] Console cleared", "INFO")
    end)

    -- Connect callbacks
    BaoSaveInstance._UILogCallback = function(text, level) pcall(AddLog, text, level) end

    BaoSaveInstance._UIProgressCallback = function(current, total, label)
        pcall(function()
            local pct = total > 0 and (current / total) or 0
            ProgressText.Text = "⚡ " .. (label or "Processing")
            ProgressPct.Text = string.format("%d/%d (%.1f%%)", current, total, pct * 100)
            Services.TweenService:Create(ProgressFill, TweenInfo.new(0.2), {
                Size = UDim2.new(pct, 0, 1, 0)
            }):Play()

            -- Update stats
            local s = BaoSaveInstance.Stats
            StatsText.Text = string.format("✓%d ✗%d ~%d | Mem: %.0fMB",
                s.DecompiledScripts, s.FailedScripts, s.PartialScripts,
                MemoryManager:GetUsage())

            if pct >= 1 then
                ProgressFill.BackgroundColor3 = C.Green
                ProgressText.Text = "✅ Hoàn thành!"
                task.delay(3, function()
                    pcall(function()
                        ProgressFill.BackgroundColor3 = C.Accent
                    end)
                end)
            end
        end)
    end

    -- Window controls
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Services.TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                Size = UDim2.new(0, 580, 0, 56)
            }):Play()
            Content.Visible = false; MinBtn.Text = "+"
        else
            Content.Visible = true
            Services.TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                Size = UDim2.new(0, 580, 0, 720)
            }):Play()
            MinBtn.Text = "−"
        end
    end)

    CancelBtn.MouseButton1Click:Connect(function()
        BaoSaveInstance.Cancel()
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Services.TweenService:Create(Main, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        task.wait(0.15)
        ScreenGui:Destroy()
        BaoSaveInstance._UILogCallback = nil
        BaoSaveInstance._UIProgressCallback = nil
    end)

    -- Hotkey
    pcall(function()
        Services.UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.F6 then
                ScreenGui.Enabled = not ScreenGui.Enabled
            end
        end)
    end)

    -- Initial logs
    AddLog("[INFO] BaoSaveInstance v" .. BaoSaveInstance.Version .. " loaded", "INFO")
    AddLog("[INFO] Game: " .. GetGameName(), "INFO")
    AddLog("[INFO] Exploit: " .. ExploitEnv.name .. " | APIs: " .. availAPIs .. "/12", "INFO")
    AddLog("[INFO] Features: Smart Merge, Quality Scoring, 12 APIs, Deep Recovery", "INFO")
    AddLog("[INFO] Press F6 to toggle | Ready to decompile!", "SUCCESS")

    Logger:Info("GUI đã được tạo! Nhấn F6 để toggle.")
    return ScreenGui
end

-- ═══════════════════════════════════════════════════════════════════════
-- PHẦN 12: KHỞI CHẠY
-- ═══════════════════════════════════════════════════════════════════════

InitializeDecompilers()
BaoSaveInstance.CreateUI()

pcall(function() getgenv().BaoSaveInstance = BaoSaveInstance end)
_G.BaoSaveInstance = BaoSaveInstance

Logger:Info("═══════════════════════════════════════════════════════")
Logger:Info("  ⚡ BaoSaveInstance v" .. BaoSaveInstance.Version .. " LOADED ⚡")
Logger:Info("═══════════════════════════════════════════════════════")
Logger:Info("Commands:")
Logger:Info("  BaoSaveInstance.DecompileGame()     → Full game")
Logger:Info("  BaoSaveInstance.DecompileMap()       → Map only")
Logger:Info("  BaoSaveInstance.DecompileTerrain()   → Terrain only")
Logger:Info("  BaoSaveInstance.DecompileScripts()   → Scripts only (ultra)")
Logger:Info("  BaoSaveInstance.DecompileAssets()    → Asset export")
Logger:Info("  BaoSaveInstance.QuickDecompile(obj)  → Single script")
Logger:Info("  BaoSaveInstance.Cancel()             → Cancel current")
Logger:Info("  F6 → Toggle GUI")
Logger:Info("═══════════════════════════════════════════════════════")

return BaoSaveInstance
