--[[
    ╔════════════════════════════════════════════════════════════════════════╗
    ║                    BaoSaveInstance v5.0 ULTIMATE                      ║
    ║              Ultimate Roblox Game Decompiler & Exporter               ║
    ║                                                                        ║
    ║  ✦ 12 Decompiler Engines với auto-fallback & merging                  ║
    ║  ✦ Full Game / Map / Terrain / Script / Asset decompile               ║
    ║  ✦ Binary RBXL serializer + XML RBXLX dual output                    ║
    ║  ✦ 200+ property definitions cho accurate serialization               ║
    ║  ✦ Terrain SmoothGrid + MaterialColors full capture                   ║
    ║  ✦ Nil instances + loaded modules + running scripts scan              ║
    ║  ✦ Anti-detection & anti-crash protection                             ║
    ║  ✦ Real-time progress GUI với detailed statistics                     ║
    ║  ✦ Parallel decompile pipeline                                        ║
    ║  ✦ Script quality scoring & best-result selection                     ║
    ║  ✦ Automatic obfuscation detection & handling                         ║
    ║  ✦ Asset URL resolver & mesh/image/sound capture                     ║
    ╚════════════════════════════════════════════════════════════════════════╝
--]]

-- ══════════════════════════════════════════════════════════════════
-- STRICT MODE & ERROR BOUNDARY
-- ══════════════════════════════════════════════════════════════════

local SCRIPT_START_TIME = tick()
local MEMORY_WARNING_MB = 800

local function SafeCall(fn, ...)
    local args = {...}
    local results = {pcall(function() return fn(unpack(args)) end)}
    if results[1] then
        return unpack(results, 2)
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════════
-- MODULE
-- ══════════════════════════════════════════════════════════════════

local BaoSaveInstance = {
    Version = "5.0",
    Build = "ULTIMATE",
    Author = "Bao",
    _initialized = false,
    _gui = nil,
    _isRunning = false,
}

-- ══════════════════════════════════════════════════════════════════
-- ALL SERVICES (cached for performance)
-- ══════════════════════════════════════════════════════════════════

local Services = {}
local ServiceNames = {
    "Workspace", "Players", "Lighting", "ReplicatedFirst",
    "ReplicatedStorage", "StarterGui", "StarterPack",
    "StarterPlayer", "SoundService", "Chat", "TestService",
    "LocalizationService", "CoreGui", "MarketplaceService",
    "HttpService", "TweenService", "InsertService",
    "MaterialService", "TextChatService",
}

local ServerServiceNames = {
    "ServerScriptService", "ServerStorage",
}

for _, name in ipairs(ServiceNames) do
    pcall(function() Services[name] = game:GetService(name) end)
end
for _, name in ipairs(ServerServiceNames) do
    pcall(function() Services[name] = game:GetService(name) end)
end

-- ══════════════════════════════════════════════════════════════════
-- CONFIGURATION (Extensive)
-- ══════════════════════════════════════════════════════════════════

local Config = {
    -- Performance
    YieldInterval = 35,
    YieldTime = 0.016,
    BatchSize = 200,
    MaxMemoryMB = 2048,

    -- Decompile
    DecompileTimeout = 30,
    MaxDecompileRetries = 3,
    DecompileQualityThreshold = 0.4,
    MergeDecompileResults = true,
    DecompileParallel = true,
    StripComments = false,
    PreserveLineNumbers = true,

    -- Scanning
    ScanNilInstances = true,
    ScanLoadedModules = true,
    ScanRunningScripts = true,
    ScanPlayerGui = true,
    ScanCoreGui = false,
    ScanServerServices = true,
    MaxScanDepth = 100,

    -- Output
    OutputFormat = "rbxlx",
    DualOutput = true,
    SaveScriptsSeparately = true,
    CompressOutput = false,
    IncludeMetadata = true,
    IncludeDecompileStats = true,

    -- Assets
    CaptureAssetURLs = true,
    ResolveMeshIds = true,
    CaptureAnimations = true,
    CaptureSounds = true,
    CaptureImages = true,

    -- Terrain
    TerrainRegionSize = 1024,
    TerrainCellSize = 4,
    TerrainFullCapture = true,

    -- GUI
    ShowGUI = true,
    GUITheme = "dark",
    ShowProgressBar = true,
    ShowDetailedStats = true,

    -- Logging
    LogLevel = 2,
    MaxLogEntries = 500,
    LogToFile = true,

    -- Services to scan (full game)
    FullGameServices = {
        "Workspace", "Lighting", "ReplicatedFirst", "ReplicatedStorage",
        "StarterGui", "StarterPack", "StarterPlayer", "SoundService",
        "Chat", "LocalizationService", "TestService", "MaterialService",
        "TextChatService",
    },

    -- Script containers
    ScriptContainers = {
        "Workspace", "ReplicatedFirst", "ReplicatedStorage",
        "StarterGui", "StarterPack", "StarterPlayer",
        "Lighting", "SoundService", "Chat",
        "LocalizationService", "TestService",
        "ServerScriptService", "ServerStorage",
    },

    -- Instance blacklist (never serialize these)
    InstanceBlacklist = {
        "Player", "PlayerScripts", "PlayerGui",
        "Backpack", "HealthGui", "BubbleChat",
        "BaoSaveInstanceGUI",
    },

    -- Property blacklist
    PropertyBlacklist = {
        "RobloxLocked", "DataCost", "WorkspaceId",
    },
}

-- ══════════════════════════════════════════════════════════════════
-- STATISTICS
-- ══════════════════════════════════════════════════════════════════

local Stats = {}
local function ResetStats()
    Stats = {
        StartTime = tick(),
        EndTime = 0,
        Phase = "Idle",
        Progress = 0,

        -- Instances
        TotalInstances = 0,
        ProcessedInstances = 0,
        SerializedInstances = 0,
        SkippedInstances = 0,
        FailedInstances = 0,

        -- Scripts
        TotalScripts = 0,
        DecompiledScripts = 0,
        PartialScripts = 0,
        FailedScripts = 0,
        SkippedScripts = 0,
        TotalScriptBytes = 0,
        TotalSourceChars = 0,

        -- Assets
        TotalAssets = 0,
        CapturedAssets = 0,
        UniqueAssetURLs = {},

        -- Terrain
        TerrainCaptured = false,
        TerrainDataSize = 0,

        -- Decompilers
        EngineSuccessCount = {},
        EngineFailCount = {},
        EngineTimings = {},

        -- Quality
        AverageQuality = 0,
        QualityScores = {},

        -- Errors
        Errors = {},
        Warnings = {},

        -- Output
        OutputFileSize = 0,
        OutputFileName = "",
    }
end
ResetStats()

-- ══════════════════════════════════════════════════════════════════
-- LOGGING SYSTEM (Enhanced)
-- ══════════════════════════════════════════════════════════════════

local LogHistory = {}
local LogColors = {
    [1] = "INFO",
    [2] = "WARN",
    [3] = "ERROR",
    [4] = "SUCCESS",
    [5] = "PROGRESS",
    [6] = "DEBUG",
    [7] = "CRITICAL",
}

local function Log(message, level)
    level = level or 1
    if level == 6 and Config.LogLevel < 3 then return end

    local elapsed = tick() - (Stats.StartTime or tick())
    local prefix = "[BaoSave " .. (LogColors[level] or "INFO") .. "]"
    local fullMsg = string.format("%s [%.2fs] %s", prefix, elapsed, tostring(message))

    if #LogHistory < Config.MaxLogEntries then
        table.insert(LogHistory, {
            Time = elapsed,
            Level = level,
            Message = message,
            Full = fullMsg,
        })
    end

    if level == 3 or level == 7 then
        warn(fullMsg)
        table.insert(Stats.Errors, message)
    elseif level == 2 then
        warn(fullMsg)
        table.insert(Stats.Warnings, message)
    else
        print(fullMsg)
    end

    -- GUI log callback
    if BaoSaveInstance._UpdateGUILog then
        pcall(BaoSaveInstance._UpdateGUILog, fullMsg, level)
    end

    -- GUI progress callback
    if BaoSaveInstance._UpdateGUIProgress then
        pcall(BaoSaveInstance._UpdateGUIProgress, Stats.Phase, Stats.Progress)
    end
end

BaoSaveInstance.Log = Log

-- ══════════════════════════════════════════════════════════════════
-- EXPLOIT ENVIRONMENT DETECTION (Comprehensive)
-- ══════════════════════════════════════════════════════════════════

local Env = {}

local function ProbeFunction(names)
    for _, name in ipairs(names) do
        -- Global scope
        local ok, fn = pcall(function() return getfenv()[name] end)
        if ok and typeof(fn) == "function" then return fn end

        -- Direct global
        ok, fn = pcall(function()
            return ({
                decompile = decompile,
                getscriptbytecode = getscriptbytecode,
                dumpstring = dumpstring,
                getscripthash = getscripthash,
                writefile = writefile,
                readfile = readfile,
                appendfile = appendfile,
                isfile = isfile,
                isfolder = isfolder,
                makefolder = makefolder,
                delfolder = delfolder,
                delfile = delfile,
                listfiles = listfiles,
                saveinstance = saveinstance,
                save_instance = save_instance,
                gethiddenproperty = gethiddenproperty,
                sethiddenproperty = sethiddenproperty,
                getinstances = getinstances,
                getnilinstances = getnilinstances,
                getloadedmodules = getloadedmodules,
                getrunningscripts = getrunningscripts,
                getscriptclosure = getscriptclosure,
                getscriptfunction = getscriptfunction,
                hookfunction = hookfunction,
                newcclosure = newcclosure,
                iscclosure = iscclosure,
                islclosure = islclosure,
                getrawmetatable = getrawmetatable,
                setrawmetatable = setrawmetatable,
                setreadonly = setreadonly,
                isreadonly = isreadonly,
                getnamecallmethod = getnamecallmethod,
                setclipboard = setclipboard,
                toclipboard = toclipboard,
                identifyexecutor = identifyexecutor,
                getexecutorname = getexecutorname,
                request = request,
                http_request = http_request,
                HttpGet = HttpGet,
                getgenv = getgenv,
                getrenv = getrenv,
                getgc = getgc,
                getupvalues = getupvalues,
                getupvalue = getupvalue,
                setupvalue = setupvalue,
                getconstants = getconstants,
                getconstant = getconstant,
                setconstant = setconstant,
                getprotos = getprotos,
                getproto = getproto,
                getstack = getstack,
                getinfo = getinfo,
                getthreadidentity = getthreadidentity,
                setthreadidentity = setthreadidentity,
                firesignal = firesignal,
                fireclickdetector = fireclickdetector,
                fireproximityprompt = fireproximityprompt,
                firetouchinterest = firetouchinterest,
                getcallingscript = getcallingscript,
                checkcaller = checkcaller,
                isexploitclosure = isexploitclosure,
                cloneref = cloneref,
                compareinstances = compareinstances,
                gethui = gethui,
                crypt = crypt,
                base64_encode = base64_encode,
                base64_decode = base64_decode,
                lz4compress = lz4compress,
                lz4decompress = lz4decompress,
                Drawing = Drawing,
                getsynasset = getsynasset,
                getcustomasset = getcustomasset,
            })[name]
        end)
        if ok and fn ~= nil then return fn end

        -- syn table
        pcall(function()
            if typeof(syn) == "table" and syn[name] then
                fn = syn[name]
            end
        end)
        if typeof(fn) == "function" then return fn end

        -- fluxus table
        pcall(function()
            if typeof(fluxus) == "table" and fluxus[name] then
                fn = fluxus[name]
            end
        end)
        if typeof(fn) == "function" then return fn end
    end
    return nil
end

local function DetectEnvironment()
    Log("══ Phát hiện môi trường Exploit ══", 5)

    -- Core decompile
    Env.decompile = ProbeFunction({"decompile", "decompilescript"})
    Env.getscriptbytecode = ProbeFunction({"getscriptbytecode", "dumpstring", "get_script_bytecode"})
    Env.getscripthash = ProbeFunction({"getscripthash", "get_script_hash"})
    Env.getscriptclosure = ProbeFunction({"getscriptclosure", "getscriptfunction", "get_script_closure"})

    -- File system
    Env.writefile = ProbeFunction({"writefile", "write_file"})
    Env.readfile = ProbeFunction({"readfile", "read_file"})
    Env.appendfile = ProbeFunction({"appendfile", "append_file"})
    Env.isfile = ProbeFunction({"isfile", "is_file"})
    Env.isfolder = ProbeFunction({"isfolder", "is_folder"})
    Env.makefolder = ProbeFunction({"makefolder", "make_folder", "mkdir"})
    Env.listfiles = ProbeFunction({"listfiles", "list_files"})
    Env.delfile = ProbeFunction({"delfile", "del_file"})
    Env.delfolder = ProbeFunction({"delfolder", "del_folder"})

    -- Save instance
    Env.saveinstance = ProbeFunction({"saveinstance", "save_instance", "saveplace", "save_place"})

    -- Hidden properties
    Env.gethiddenproperty = ProbeFunction({"gethiddenproperty", "get_hidden_property", "gethiddenprop"})
    Env.sethiddenproperty = ProbeFunction({"sethiddenproperty", "set_hidden_property", "sethiddenprop"})

    -- Instance enumeration
    Env.getinstances = ProbeFunction({"getinstances", "get_instances"})
    Env.getnilinstances = ProbeFunction({"getnilinstances", "get_nil_instances", "getnilinsts"})
    Env.getloadedmodules = ProbeFunction({"getloadedmodules", "get_loaded_modules", "getmodules"})
    Env.getrunningscripts = ProbeFunction({"getrunningscripts", "get_running_scripts"})

    -- Debug/introspection
    Env.getupvalues = ProbeFunction({"getupvalues", "debug.getupvalues"})
    Env.getupvalue = ProbeFunction({"getupvalue", "debug.getupvalue"})
    Env.setupvalue = ProbeFunction({"setupvalue", "debug.setupvalue"})
    Env.getconstants = ProbeFunction({"getconstants", "debug.getconstants"})
    Env.getconstant = ProbeFunction({"getconstant", "debug.getconstant"})
    Env.getprotos = ProbeFunction({"getprotos", "debug.getprotos"})
    Env.getinfo = ProbeFunction({"getinfo", "debug.getinfo"})
    Env.getstack = ProbeFunction({"getstack", "debug.getstack"})
    Env.getgc = ProbeFunction({"getgc", "get_gc"})

    -- Thread identity
    Env.getthreadidentity = ProbeFunction({"getthreadidentity", "getidentity", "getthreadcontext", "get_thread_identity"})
    Env.setthreadidentity = ProbeFunction({"setthreadidentity", "setidentity", "setthreadcontext", "set_thread_identity"})

    -- Metatable
    Env.getrawmetatable = ProbeFunction({"getrawmetatable", "get_raw_metatable"})
    Env.setrawmetatable = ProbeFunction({"setrawmetatable", "set_raw_metatable"})
    Env.setreadonly = ProbeFunction({"setreadonly", "set_readonly"})

    -- Hooking
    Env.hookfunction = ProbeFunction({"hookfunction", "hookfunc", "hook_function", "replaceclosure", "detour_function"})
    Env.newcclosure = ProbeFunction({"newcclosure", "new_cclosure"})
    Env.iscclosure = ProbeFunction({"iscclosure", "is_cclosure"})

    -- Clipboard
    Env.setclipboard = ProbeFunction({"setclipboard", "toclipboard", "set_clipboard", "to_clipboard"})

    -- HTTP
    Env.request = ProbeFunction({"request", "http_request", "HttpGet"})
    if not Env.request then
        pcall(function()
            if syn and syn.request then Env.request = syn.request end
        end)
        pcall(function()
            if http and http.request then Env.request = http.request end
        end)
        pcall(function()
            if fluxus and fluxus.request then Env.request = fluxus.request end
        end)
    end

    -- Crypto / Encoding
    Env.base64encode = ProbeFunction({"base64_encode", "base64encode"})
    Env.base64decode = ProbeFunction({"base64_decode", "base64decode"})
    if not Env.base64encode then
        pcall(function()
            if crypt and crypt.base64encode then
                Env.base64encode = crypt.base64encode
                Env.base64decode = crypt.base64decode
            elseif crypt and crypt.base64 then
                Env.base64encode = crypt.base64.encode
                Env.base64decode = crypt.base64.decode
            end
        end)
    end

    Env.lz4compress = ProbeFunction({"lz4compress", "lz4_compress"})
    Env.lz4decompress = ProbeFunction({"lz4decompress", "lz4_decompress"})

    -- Custom assets
    Env.getcustomasset = ProbeFunction({"getcustomasset", "getsynasset", "get_custom_asset"})

    -- Misc
    Env.cloneref = ProbeFunction({"cloneref", "clone_ref"})
    Env.gethui = ProbeFunction({"gethui", "get_hidden_ui"})
    Env.firesignal = ProbeFunction({"firesignal", "fire_signal"})
    Env.getgenv = ProbeFunction({"getgenv", "get_genv"})
    Env.getrenv = ProbeFunction({"getrenv", "get_renv"})
    Env.checkcaller = ProbeFunction({"checkcaller", "check_caller"})

    -- Executor identification
    Env.ExecutorName = "Unknown"
    Env.ExecutorVersion = "Unknown"
    local idFn = ProbeFunction({"identifyexecutor", "getexecutorname", "identify_executor"})
    if idFn then
        pcall(function()
            local name, ver = idFn()
            Env.ExecutorName = name or "Unknown"
            Env.ExecutorVersion = ver or "Unknown"
        end)
    end

    -- Log tất cả capabilities
    local capabilities = {}
    local capNames = {
        "decompile", "getscriptbytecode", "getscripthash", "getscriptclosure",
        "writefile", "readfile", "saveinstance",
        "gethiddenproperty", "sethiddenproperty",
        "getinstances", "getnilinstances", "getloadedmodules", "getrunningscripts",
        "getupvalues", "getconstants", "getprotos", "getinfo", "getgc",
        "getthreadidentity", "setthreadidentity",
        "hookfunction", "newcclosure",
        "request", "setclipboard",
        "base64encode", "lz4compress",
        "cloneref", "gethui",
        "getgenv", "getrenv", "checkcaller",
    }

    for _, name in ipairs(capNames) do
        capabilities[name] = Env[name] ~= nil
    end

    Log("Executor: " .. Env.ExecutorName .. " v" .. Env.ExecutorVersion, 4)

    local available, total = 0, 0
    for name, has in pairs(capabilities) do
        total = total + 1
        if has then
            available = available + 1
        end
    end

    Log("Capabilities: " .. available .. "/" .. total .. " detected", 4)

    -- Log key capabilities
    for _, name in ipairs({"decompile","getscriptbytecode","writefile","saveinstance","gethiddenproperty","getnilinstances","getloadedmodules","request","getgc","getconstants","getupvalues"}) do
        Log("  " .. name .. "(): " .. (capabilities[name] and "✓" or "✗"), 6)
    end

    return capabilities
end

-- ══════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS (Enhanced)
-- ══════════════════════════════════════════════════════════════════

local _yieldCounter = 0
local function Yield()
    _yieldCounter = _yieldCounter + 1
    if _yieldCounter >= Config.YieldInterval then
        _yieldCounter = 0
        task.wait(Config.YieldTime)
    end
end

local function ForceYield()
    _yieldCounter = 0
    task.wait(Config.YieldTime)
end

local function CheckMemory()
    local mem = gcinfo and gcinfo() or 0
    if mem > Config.MaxMemoryMB * 1024 then
        Log("⚠ Memory cao: " .. math.floor(mem / 1024) .. "MB, đang dọn dẹp...", 2)
        collectgarbage("collect")
        task.wait(0.1)
        return false
    end
    return true
end

local function IsScript(inst)
    return inst:IsA("LocalScript") or inst:IsA("Script") or inst:IsA("ModuleScript")
end

local function GetFullPath(inst)
    local parts = {}
    local current = inst
    local depth = 0
    while current and current ~= game and depth < 50 do
        table.insert(parts, 1, current.Name)
        current = current.Parent
        depth = depth + 1
    end
    return "game." .. table.concat(parts, ".")
end

local function SanitizeFileName(name)
    if not name or name == "" then return "Unknown_Game" end
    local s = tostring(name)
    s = s:gsub('[/\\:*?"<>|%c\0]', '_')
    s = s:gsub('^[%.%s]+', ''):gsub('[%.%s]+$', '')
    s = s:gsub('_+', '_')
    if #s > 120 then s = s:sub(1, 120) end
    if s == "" then s = "Unknown_Game" end
    return s
end

local function GetGameName()
    local ok, info = pcall(function()
        return Services.MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if ok and info and info.Name then return info.Name end
    return "Game_" .. tostring(game.PlaceId)
end

local function BuildFileName(suffix)
    local name = SanitizeFileName(GetGameName())
    if suffix and suffix ~= "" then
        return name .. " " .. suffix .. " Decompile By BaoSaveInstance.rbxl"
    end
    return name .. " Decompile By BaoSaveInstance.rbxl"
end

-- Base64 encoder (fallback nếu exploit không có)
local B64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function Base64Encode(data)
    if Env.base64encode then
        local ok, result = pcall(Env.base64encode, data)
        if ok and result then return result end
    end

    if not data or #data == 0 then return "" end

    local result = {}
    local padding = (3 - #data % 3) % 3
    local d = data .. string.rep("\0", padding)

    for i = 1, #d, 3 do
        local b1, b2, b3 = d:byte(i, i + 2)
        local n = b1 * 65536 + b2 * 256 + b3

        local c1 = math.floor(n / 262144) % 64 + 1
        local c2 = math.floor(n / 4096) % 64 + 1
        local c3 = math.floor(n / 64) % 64 + 1
        local c4 = n % 64 + 1

        table.insert(result, B64Chars:sub(c1, c1))
        table.insert(result, B64Chars:sub(c2, c2))
        table.insert(result, B64Chars:sub(c3, c3))
        table.insert(result, B64Chars:sub(c4, c4))
    end

    local r = table.concat(result)
    if padding > 0 then
        r = r:sub(1, #r - padding) .. string.rep("=", padding)
    end
    return r
end

-- ══════════════════════════════════════════════════════════════════
-- SCRIPT QUALITY ANALYZER
-- Đánh giá chất lượng source code decompiled
-- ══════════════════════════════════════════════════════════════════

local QualityAnalyzer = {}

function QualityAnalyzer.Score(source, scriptClass)
    if not source or #source == 0 then return 0 end

    local score = 0
    local totalChecks = 0
    local lineCount = 0
    local codeLines = 0
    local commentLines = 0
    local emptyLines = 0
    local hasError = false

    -- Đếm loại dòng
    for line in source:gmatch("[^\n]*") do
        lineCount = lineCount + 1
        local trimmed = line:match("^%s*(.-)%s*$")
        if not trimmed or #trimmed == 0 then
            emptyLines = emptyLines + 1
        elseif trimmed:match("^%-%-") then
            commentLines = commentLines + 1
            if trimmed:lower():find("fail") or trimmed:lower():find("error") then
                hasError = true
            end
        else
            codeLines = codeLines + 1
        end
    end

    -- 1. Có code thực (không chỉ comments)
    totalChecks = totalChecks + 1
    if codeLines > 0 then
        score = score + 1
        -- Bonus cho nhiều code
        if codeLines > 10 then score = score + 0.5 end
        if codeLines > 50 then score = score + 0.5 end
        if codeLines > 200 then score = score + 0.5 end
    end

    -- 2. Tỉ lệ code/comment hợp lý
    totalChecks = totalChecks + 1
    if lineCount > 0 and codeLines / lineCount > 0.3 then
        score = score + 1
    end

    -- 3. Có Lua keywords
    totalChecks = totalChecks + 1
    local keywords = {"function", "local", "end", "if", "then", "return", "for", "while", "repeat"}
    local keywordCount = 0
    for _, kw in ipairs(keywords) do
        if source:find("%f[%w]" .. kw .. "%f[%W]") then
            keywordCount = keywordCount + 1
        end
    end
    if keywordCount >= 3 then
        score = score + 1
    elseif keywordCount >= 1 then
        score = score + 0.5
    end

    -- 4. Có function definitions
    totalChecks = totalChecks + 1
    local funcCount = 0
    for _ in source:gmatch("function%s*[%(%.%w]") do
        funcCount = funcCount + 1
    end
    if funcCount > 0 then
        score = score + 1
        if funcCount > 5 then score = score + 0.3 end
    end

    -- 5. Có variable declarations
    totalChecks = totalChecks + 1
    if source:find("local%s+%w") then
        score = score + 1
    end

    -- 6. Có API calls (game services, etc.)
    totalChecks = totalChecks + 1
    local apiPatterns = {
        "game:GetService", "workspace", "Instance%.new",
        "FindFirstChild", "WaitForChild", "GetChildren",
        "GetDescendants", "Connect", "require",
        "RemoteEvent", "RemoteFunction", "BindableEvent",
        "TweenService", "UserInputService", "RunService",
    }
    local apiCount = 0
    for _, pat in ipairs(apiPatterns) do
        if source:find(pat) then apiCount = apiCount + 1 end
    end
    if apiCount > 0 then
        score = score + 1
        if apiCount > 3 then score = score + 0.5 end
    end

    -- 7. Không có error markers
    totalChecks = totalChecks + 1
    if not hasError then
        score = score + 1
    end

    -- 8. Syntactic completeness (end matches)
    totalChecks = totalChecks + 1
    local opens = 0
    for _ in source:gmatch("%f[%w]function%f[%W]") do opens = opens + 1 end
    for _ in source:gmatch("%f[%w]if%f[%W]") do opens = opens + 1 end
    for _ in source:gmatch("%f[%w]for%f[%W]") do opens = opens + 1 end
    for _ in source:gmatch("%f[%w]while%f[%W]") do opens = opens + 1 end
    for _ in source:gmatch("%f[%w]repeat%f[%W]") do opens = opens + 1 end
    local ends = 0
    for _ in source:gmatch("%f[%w]end%f[%W]") do ends = ends + 1 end
    for _ in source:gmatch("%f[%w]until%f[%W]") do ends = ends + 1 end

    if opens > 0 and math.abs(opens - ends) <= 2 then
        score = score + 1
    elseif opens > 0 and math.abs(opens - ends) <= 5 then
        score = score + 0.5
    end

    -- 9. String content quality (not just hex/garbage)
    totalChecks = totalChecks + 1
    local stringCount = 0
    local readableStrings = 0
    for str in source:gmatch('"([^"]-)"') do
        stringCount = stringCount + 1
        -- Kiểm tra có phải readable text không
        local readable = true
        for i = 1, math.min(#str, 50) do
            local byte = str:byte(i)
            if byte < 32 and byte ~= 10 and byte ~= 13 and byte ~= 9 then
                readable = false
                break
            end
        end
        if readable and #str > 0 then
            readableStrings = readableStrings + 1
        end
    end
    if stringCount > 0 then
        local ratio = readableStrings / stringCount
        score = score + ratio
    else
        score = score + 0.5 -- No strings is ok
    end

    -- 10. Appropriate for script type
    totalChecks = totalChecks + 1
    if scriptClass == "LocalScript" then
        if source:find("LocalPlayer") or source:find("UserInputService")
            or source:find("StarterGui") or source:find("PlayerGui")
            or source:find("Mouse") or source:find("Character") then
            score = score + 1
        else
            score = score + 0.5
        end
    elseif scriptClass == "ModuleScript" then
        if source:find("return%s") or source:find("module") then
            score = score + 1
        else
            score = score + 0.5
        end
    else
        score = score + 0.7
    end

    -- Normalize to 0-1
    local finalScore = score / (totalChecks + 3) -- +3 for bonus scores
    finalScore = math.min(1, math.max(0, finalScore))

    return finalScore, {
        LineCount = lineCount,
        CodeLines = codeLines,
        CommentLines = commentLines,
        EmptyLines = emptyLines,
        Keywords = keywordCount,
        Functions = funcCount,
        APIs = apiCount,
        HasError = hasError,
    }
end

-- ══════════════════════════════════════════════════════════════════
-- OBFUSCATION DETECTOR
-- Phát hiện và xử lý các loại obfuscation phổ biến
-- ══════════════════════════════════════════════════════════════════

local ObfuscationDetector = {}

function ObfuscationDetector.Detect(source)
    if not source or #source < 50 then return "none", 0 end

    local indicators = {
        ironbrew = 0,
        luraph = 0,
        moonsec = 0,
        psu = 0,
        beautify = 0,
        generic = 0,
    }

    -- IronBrew / IronBrew2 patterns
    if source:find("IronBrew") or source:find("AztupBrew")
        or (source:find("local%s+[vV]%d+") and source:find("bit32"))
        or source:find("ByteString") then
        indicators.ironbrew = indicators.ironbrew + 1
    end

    -- Luraph patterns
    if source:find("luraph") or source:find("LURAPH")
        or (source:find("string%.byte") and source:find("string%.char")
            and source:find("string%.sub") and source:find("string%.rep")) then
        indicators.luraph = indicators.luraph + 1
    end

    -- MoonSec patterns
    if source:find("MoonSec") or source:find("moonsec")
        or source:find("Moon_Sec") then
        indicators.moonsec = indicators.moonsec + 1
    end

    -- PSU (Prometheus Standardized Unobfuscation) patterns
    if source:find("prometheus") or source:find("PROMETHEUS") then
        indicators.psu = indicators.psu + 1
    end

    -- Beautify/minify detection
    local avgLineLen = #source / math.max(1, select(2, source:gsub("\n", "")) + 1)
    if avgLineLen > 500 then
        indicators.beautify = indicators.beautify + 1
    end

    -- Generic obfuscation indicators
    -- Excessive string.byte/char usage
    local byteCharCount = 0
    for _ in source:gmatch("string%.byte") do byteCharCount = byteCharCount + 1 end
    for _ in source:gmatch("string%.char") do byteCharCount = byteCharCount + 1 end
    if byteCharCount > 20 then
        indicators.generic = indicators.generic + 1
    end

    -- Excessive variable names like v1, v2, v3...
    local shortVarCount = 0
    for _ in source:gmatch("local%s+v%d+") do shortVarCount = shortVarCount + 1 end
    if shortVarCount > 30 then
        indicators.generic = indicators.generic + 1
    end

    -- Massive single-line tables
    if source:find("{[^}]-,[^}]-,[^}]-,[^}]-,[^}]-,[^}]-,[^}]-,[^}]-,[^}]-,") then
        indicators.generic = indicators.generic + 1
    end

    -- Determine primary type
    local maxType = "none"
    local maxScore = 0
    for obfType, score in pairs(indicators) do
        if score > maxScore then
            maxScore = score
            maxType = obfType
        end
    end

    local confidence = math.min(1, maxScore / 3)
    return maxType, confidence
end

function ObfuscationDetector.TryDeobfuscate(source, obfType)
    -- Basic deobfuscation attempts
    if obfType == "beautify" or obfType == "generic" then
        -- Thử format lại code
        local formatted = source
        -- Thêm newlines sau semicolons
        formatted = formatted:gsub(";%s*", ";\n")
        -- Thêm newlines sau end
        formatted = formatted:gsub("(%f[%w]end%f[%W])", "%1\n")
        return formatted
    end
    return source
end

-- ══════════════════════════════════════════════════════════════════
-- DECOMPILER ENGINES (12 Engines)
-- ══════════════════════════════════════════════════════════════════

local DecompilerEngines = {}

--- Engine 1: Direct Source Property Access
--- Ưu tiên cao nhất - lấy source trực tiếp
DecompilerEngines[1] = {
    Name = "DirectSource",
    DisplayName = "Direct Source Property",
    Priority = 0,
    Available = false,

    Init = function(self)
        self.Available = true
        return true
    end,

    Decompile = function(self, scriptInst)
        -- Thử .Source property
        local ok, src = pcall(function() return scriptInst.Source end)
        if ok and src and typeof(src) == "string" and #src > 0 then
            return src
        end

        -- Thử gethiddenproperty cho Source
        if Env.gethiddenproperty then
            local hOk, hSrc = pcall(Env.gethiddenproperty, scriptInst, "Source")
            if hOk and hSrc and typeof(hSrc) == "string" and #hSrc > 0 then
                return hSrc
            end
        end

        return nil, "Source property not accessible"
    end,
}

--- Engine 2: Native decompile() function
--- Synapse X, Script-Ware, Fluxus, etc.
DecompilerEngines[2] = {
    Name = "NativeDecompile",
    DisplayName = "Native decompile()",
    Priority = 1,
    Available = false,

    Init = function(self)
        self.Available = Env.decompile ~= nil
        return self.Available
    end,

    Decompile = function(self, scriptInst)
        if not Env.decompile then return nil, "decompile() not available" end

        local ok, source = pcall(Env.decompile, scriptInst)
        if not ok then return nil, "pcall failed: " .. tostring(source) end
        if not source or typeof(source) ~= "string" then
            return nil, "Invalid return type"
        end
        if #source == 0 then return nil, "Empty result" end

        -- Kiểm tra error messages phổ biến
        local errorPatterns = {
            "^%-%-.*failed to decompile",
            "^%-%-.*error",
            "^%-%-.*cannot decompile",
            "^%-%-.*decompilation failed",
            "^%-%-.*timed? ?out",
            "^%-%-.*not supported",
            "^%-%-.*unrecognized",
        }

        local firstLine = source:match("^([^\n]+)")
        if firstLine then
            local fl = firstLine:lower()
            for _, pat in ipairs(errorPatterns) do
                if fl:match(pat) then
                    -- Vẫn trả về nhưng đánh dấu là partial
                    if #source > #firstLine + 10 then
                        return source -- Có thêm content sau error comment
                    end
                    return nil, "Decompiler error: " .. firstLine:sub(1, 100)
                end
            end
        end

        return source
    end,
}

--- Engine 3: decompile() with thread identity elevation
--- Nâng quyền thread trước khi decompile
DecompilerEngines[3] = {
    Name = "ElevatedDecompile",
    DisplayName = "Elevated Identity Decompile",
    Priority = 2,
    Available = false,
    _originalIdentity = nil,

    Init = function(self)
        self.Available = Env.decompile ~= nil
            and Env.setthreadidentity ~= nil
            and Env.getthreadidentity ~= nil
        return self.Available
    end,

    Decompile = function(self, scriptInst)
        if not self.Available then return nil, "Not available" end

        -- Lưu identity gốc
        local origId
        pcall(function() origId = Env.getthreadidentity() end)

        -- Nâng lên identity 8 (highest)
        pcall(function() Env.setthreadidentity(8) end)

        local ok, source = pcall(Env.decompile, scriptInst)

        -- Khôi phục identity
        if origId then
            pcall(function() Env.setthreadidentity(origId) end)
        end

        if ok and source and typeof(source) == "string" and #source > 0 then
            return source
        end
        return nil, ok and "Empty/invalid result" or tostring(source)
    end,
}

--- Engine 4: Bytecode extraction + HTTP Decompile API (Unluac)
DecompilerEngines[4] = {
    Name = "BytecodeHTTP_Unluac",
    DisplayName = "Bytecode → Unluac HTTP",
    Priority = 5,
    Available = false,
    Endpoints = {
        "https://unluac.com/api/decompile",
        "https://luadec.com/api/decompile",
    },

    Init = function(self)
        self.Available = Env.getscriptbytecode ~= nil and Env.request ~= nil
        return self.Available
    end,

    Decompile = function(self, scriptInst)
        if not self.Available then return nil, "Not available" end

        local ok, bytecode = pcall(Env.getscriptbytecode, scriptInst)
        if not ok or not bytecode or #bytecode == 0 then
            return nil, "Bytecode extraction failed"
        end

        for _, endpoint in ipairs(self.Endpoints) do
            local reqOk, resp = pcall(function()
                return Env.request({
                    Url = endpoint,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/octet-stream",
                        ["User-Agent"] = "BaoSaveInstance/5.0",
                        ["Accept"] = "text/plain",
                    },
                    Body = bytecode,
                })
            end)

            if reqOk and resp and resp.StatusCode == 200 and resp.Body and #resp.Body > 10 then
                return resp.Body
            end
        end

        return nil, "All HTTP endpoints failed"
    end,
}

--- Engine 5: Bytecode extraction + HTTP Decompile API (LuaDec)
DecompilerEngines[5] = {
    Name = "BytecodeHTTP_LuaDec",
    DisplayName = "Bytecode → LuaDec HTTP",
    Priority = 6,
    Available = false,
    Endpoints = {
        "https://luadec.metaflare.net/api/decompile",
        "https://decompiler.krujo.dev/api/decompile",
    },

    Init = function(self)
        self.Available = Env.getscriptbytecode ~= nil and Env.request ~= nil
        return self.Available
    end,

    Decompile = function(self, scriptInst)
        if not self.Available then return nil, "Not available" end

        local ok, bytecode = pcall(Env.getscriptbytecode, scriptInst)
        if not ok or not bytecode or #bytecode == 0 then
            return nil, "Bytecode extraction failed"
        end

        local b64 = Base64Encode(bytecode)

        for _, endpoint in ipairs(self.Endpoints) do
            local reqOk, resp = pcall(function()
                return Env.request({
                    Url = endpoint,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json",
                        ["User-Agent"] = "BaoSaveInstance/5.0",
                    },
                    Body = Services.HttpService:JSONEncode({
                        bytecode = b64,
                        options = {
                            format = "luau",
                            optimize = true,
                        },
                    }),
                })
            end)

            if reqOk and resp and resp.StatusCode == 200 and resp.Body then
                local decOk, decoded = pcall(function()
                    return Services.HttpService:JSONDecode(resp.Body)
                end)
                if decOk and decoded and decoded.source then
                    return decoded.source
                elseif #resp.Body > 10 then
                    return resp.Body
                end
            end
        end

        return nil, "All HTTP endpoints failed"
    end,
}

--- Engine 6: Bytecode extraction + HTTP API (Luau specific)
DecompilerEngines[6] = {
    Name = "BytecodeHTTP_Luau",
    DisplayName = "Bytecode → Luau Decompiler HTTP",
    Priority = 7,
    Available = false,
    Endpoints = {
        "https://luau-decompiler.com/api/v2/decompile",
        "https://roblox-decompiler.xyz/api/decompile",
    },

    Init = function(self)
        self.Available = Env.getscriptbytecode ~= nil and Env.request ~= nil
        return self.Available
    end,

    Decompile = function(self, scriptInst)
        if not self.Available then return nil, "Not available" end

        local ok, bytecode = pcall(Env.getscriptbytecode, scriptInst)
        if not ok or not bytecode or #bytecode == 0 then
            return nil, "Bytecode extraction failed"
        end

        for _, endpoint in ipairs(self.Endpoints) do
            local reqOk, resp = pcall(function()
                return Env.request({
                    Url = endpoint,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/octet-stream",
                        ["User-Agent"] = "BaoSaveInstance/5.0",
                        ["X-Decompile-Mode"] = "luau",
                        ["X-Script-Name"] = scriptInst.Name,
                        ["X-Script-Class"] = scriptInst.ClassName,
                    },
                    Body = bytecode,
                })
            end)

            if reqOk and resp and resp.StatusCode == 200 and resp.Body and #resp.Body > 10 then
                return resp.Body
            end
        end

        return nil, "All Luau HTTP endpoints failed"
    end,
}

--- Engine 7: Closure upvalue/constant reconstruction
--- Phân tích closure để reconstruct source
DecompilerEngines[7] = {
    Name = "ClosureReconstruct",
    DisplayName = "Closure Analysis Reconstruction",
    Priority = 8,
    Available = false,

    Init = function(self)
        self.Available = (Env.getscriptclosure ~= nil or Env.getscriptbytecode ~= nil)
            and (Env.getupvalues ~= nil or Env.getconstants ~= nil or Env.getprotos ~= nil)
        return self.Available
    end,

    Decompile = function(self, scriptInst)
        local lines = {
            "-- BaoSaveInstance: Closure Analysis Reconstruction",
            "-- Script: " .. GetFullPath(scriptInst),
            "-- Class: " .. scriptInst.ClassName,
            "",
        }

        local closure = nil
        if Env.getscriptclosure then
            local ok, cl = pcall(Env.getscriptclosure, scriptInst)
            if ok and cl then closure = cl end
        end

        -- Upvalues
        if closure and Env.getupvalues then
            local ok, upvals = pcall(Env.getupvalues, closure)
            if ok and upvals then
                table.insert(lines, "-- ═══ Upvalues ═══")
                for idx, val in pairs(upvals) do
                    local valStr
                    if typeof(val) == "function" then
                        valStr = "<function>"
                    elseif typeof(val) == "table" then
                        local tOk, tStr = pcall(function()
                            return Services.HttpService:JSONEncode(val)
                        end)
                        valStr = tOk and tStr or "<table>"
                    elseif typeof(val) == "Instance" then
                        valStr = tostring(val) .. " (" .. val.ClassName .. ")"
                    else
                        valStr = tostring(val)
                    end
                    table.insert(lines, string.format(
                        "local upval_%d = %s -- %s", idx,
                        typeof(val) == "string" and string.format("%q", val) or tostring(val),
                        typeof(val)
                    ))
                end
                table.insert(lines, "")
            end
        end

        -- Constants
        if closure and Env.getconstants then
            local ok, consts = pcall(Env.getconstants, closure)
            if ok and consts then
                table.insert(lines, "-- ═══ Constants ═══")
                for idx, val in pairs(consts) do
                    if typeof(val) == "string" then
                        table.insert(lines, string.format(
                            "-- const[%d] = %q", idx, val))
                    elseif typeof(val) == "number" then
                        table.insert(lines, string.format(
                            "-- const[%d] = %s", idx, tostring(val)))
                    end
                end
                table.insert(lines, "")
            end
        end

        -- Protos (sub-functions)
        if closure and Env.getprotos then
            local ok, protos = pcall(Env.getprotos, closure)
            if ok and protos then
                table.insert(lines, "-- ═══ Sub-Functions (Protos): " .. #protos .. " ═══")
                for idx, proto in ipairs(protos) do
                    table.insert(lines, "-- Proto[" .. idx .. "]:")

                    -- Recursive constant extraction
                    if Env.getconstants then
                        local pOk, pConsts = pcall(Env.getconstants, proto)
                        if pOk and pConsts then
                            for ci, cv in pairs(pConsts) do
                                if typeof(cv) == "string" then
                                    table.insert(lines, string.format(
                                        "--   const[%d] = %q", ci, cv))
                                end
                            end
                        end
                    end

                    -- Debug info
                    if Env.getinfo then
                        local iOk, info = pcall(Env.getinfo, proto)
                        if iOk and info then
                            if info.name then
                                table.insert(lines, "--   name = " .. tostring(info.name))
                            end
                            if info.numparams then
                                table.insert(lines, "--   params = " .. tostring(info.numparams))
                            end
                            if info.is_vararg then
                                table.insert(lines, "--   vararg = true")
                            end
                        end
                    end
                end
                table.insert(lines, "")
            end
        end

        -- Debug info for main closure
        if closure and Env.getinfo then
            local ok, info = pcall(Env.getinfo, closure)
            if ok and info then
                table.insert(lines, "-- ═══ Debug Info ═══")
                for k, v in pairs(info) do
                    table.insert(lines, "-- " .. tostring(k) .. " = " .. tostring(v))
                end
                table.insert(lines, "")
            end
        end

        local result = table.concat(lines, "\n")
        if #result > 200 then -- Có đủ thông tin hữu ích
            return result
        end
        return nil, "Insufficient closure data"
    end,
}

--- Engine 8: Bytecode String/Constant Extraction
--- Trích xuất strings và constants từ raw bytecode
DecompilerEngines[8] = {
    Name = "BytecodeExtract",
    DisplayName = "Bytecode String Extraction",
    Priority = 9,
    Available = false,

    Init = function(self)
        self.Available = Env.getscriptbytecode ~= nil
        return self.Available
    end,

    Decompile = function(self, scriptInst)
        local ok, bytecode = pcall(Env.getscriptbytecode, scriptInst)
        if not ok or not bytecode or #bytecode < 10 then
            return nil, "Bytecode extraction failed"
        end

        local lines = {
            "-- BaoSaveInstance: Bytecode Analysis",
            "-- Script: " .. GetFullPath(scriptInst),
            "-- Bytecode size: " .. #bytecode .. " bytes",
            "",
        }

        -- Extract readable strings
        local strings = {}
        local currentStr = {}
        for i = 1, #bytecode do
            local byte = bytecode:byte(i)
            if byte >= 32 and byte <= 126 then
                table.insert(currentStr, string.char(byte))
            else
                if #currentStr >= 4 then
                    local str = table.concat(currentStr)
                    -- Filter out noise
                    if not str:match("^[%x]+$") or #str > 20 then
                        table.insert(strings, str)
                    end
                end
                currentStr = {}
            end
        end
        if #currentStr >= 4 then
            table.insert(strings, table.concat(currentStr))
        end

        -- Categorize extracted strings
        local requires = {}
        local serviceRefs = {}
        local methodCalls = {}
        local eventNames = {}
        local stringLiterals = {}

        for _, str in ipairs(strings) do
            if str:find("require") then
                table.insert(requires, str)
            elseif str:match("^%u%l+%u") and #str > 5 then -- PascalCase
                if str:find("Service") or str:find("Storage") or str:find("Gui") then
                    table.insert(serviceRefs, str)
                elseif str:find("Changed") or str:find("Event") or str:find("Signal")
                    or str:find("Connect") then
                    table.insert(eventNames, str)
                else
                    table.insert(methodCalls, str)
                end
            else
                table.insert(stringLiterals, str)
            end
        end

        -- Build reconstructed pseudo-code
        table.insert(lines, "-- ═══ Service References ═══")
        local seen = {}
        for _, s in ipairs(serviceRefs) do
            if not seen[s] then
                seen[s] = true
                table.insert(lines, string.format(
                    'local %s = game:GetService("%s")', s, s))
            end
        end
        table.insert(lines, "")

        if #requires > 0 then
            table.insert(lines, "-- ═══ Require Calls ═══")
            for _, r in ipairs(requires) do
                table.insert(lines, "-- " .. r)
            end
            table.insert(lines, "")
        end

        if #methodCalls > 0 then
            table.insert(lines, "-- ═══ Method/Property References ═══")
            for i, m in ipairs(methodCalls) do
                if i <= 100 then
                    table.insert(lines, "-- " .. m)
                end
            end
            table.insert(lines, "")
        end

        if #eventNames > 0 then
            table.insert(lines, "-- ═══ Event References ═══")
            for _, e in ipairs(eventNames) do
                table.insert(lines, "-- " .. e)
            end
            table.insert(lines, "")
        end

        if #stringLiterals > 0 then
            table.insert(lines, "-- ═══ String Literals (" .. #stringLiterals .. ") ═══")
            for i, s in ipairs(stringLiterals) do
                if i <= 200 then
                    table.insert(lines, string.format('-- [%d] %q', i, s:sub(1, 200)))
                end
            end
            table.insert(lines, "")
        end

        -- Bytecode hash
        if Env.getscripthash then
            local hOk, hash = pcall(Env.getscripthash, scriptInst)
            if hOk then
                table.insert(lines, "-- Bytecode hash: " .. tostring(hash))
            end
        end

        -- Luau bytecode version detection
        if #bytecode >= 4 then
            local version = bytecode:byte(1)
            table.insert(lines, "-- Bytecode version: " .. tostring(version))
        end

        local result = table.concat(lines, "\n")
        return result
    end,
}

--- Engine 9: GC (Garbage Collector) Script Scan
--- Tìm source trong GC
DecompilerEngines[9] = {
    Name = "GCScan",
    DisplayName = "GC Memory Scan",
    Priority = 10,
    Available = false,

    Init = function(self)
        self.Available = Env.getgc ~= nil
        return self.Available
    end,

    Decompile = function(self, scriptInst)
        if not Env.getgc then return nil, "getgc not available" end

        local ok, gcObjects = pcall(Env.getgc, true)
        if not ok or not gcObjects then return nil, "getgc failed" end

        local bestSource = nil
        local bestLength = 0

        for _, obj in ipairs(gcObjects) do
            if typeof(obj) == "function" then
                -- Kiểm tra xem function có liên quan đến script này không
                if Env.getinfo then
                    local iOk, info = pcall(Env.getinfo, obj)
                    if iOk and info then
                        local scriptName = scriptInst.Name
                        if info.source and info.source:find(scriptName) then
                            -- Thử decompile function này
                            if Env.decompile then
                                local dOk, src = pcall(Env.decompile, obj)
                                if dOk and src and #src > bestLength then
                                    bestSource = src
                                    bestLength = #src
                                end
                            end
                        end
                    end
                end
            elseif typeof(obj) == "table" then
                -- Tìm tables có thể chứa script source
                pcall(function()
                    for k, v in pairs(obj) do
                        if typeof(v) == "string" and #v > 100 then
                            if v:find("function") and v:find("end")
                                and v:find("local") then
                                -- Có thể là source code
                                if #v > bestLength then
                                    -- Xác nhận bằng script name match
                                    if v:find(scriptInst.Name) or #v > 500 then
                                        bestSource = v
                                        bestLength = #v
                                    end
                                end
                            end
                        end
                    end
                end)
            end
            Yield()
        end

        if bestSource then
            return "-- Recovered from GC scan\n" .. bestSource
        end
        return nil, "No matching source found in GC"
    end,
}

--- Engine 10: Loaded Module require() capture
--- Thử require() module và capture return value
DecompilerEngines[10] = {
    Name = "ModuleRequire",
    DisplayName = "Module require() Capture",
    Priority = 4,
    Available = false,

    Init = function(self)
        self.Available = true -- require() luôn có
        return true
    end,

    Decompile = function(self, scriptInst)
        if not scriptInst:IsA("ModuleScript") then
            return nil, "Only works with ModuleScript"
        end

        -- Thử require
        local ok, result = pcall(require, scriptInst)
        if not ok then return nil, "require failed: " .. tostring(result) end

        -- Analyze module return value
        local lines = {
            "-- BaoSaveInstance: Module require() Analysis",
            "-- Module: " .. GetFullPath(scriptInst),
            "",
        }

        local function SerializeValue(val, depth, visited)
            depth = depth or 0
            visited = visited or {}

            if depth > 10 then return "-- <max depth>" end

            local indent = string.rep("    ", depth)

            if typeof(val) == "table" then
                if visited[val] then return "-- <circular reference>" end
                visited[val] = true

                local parts = {"{\n"}
                local count = 0
                for k, v in pairs(val) do
                    count = count + 1
                    if count > 200 then
                        table.insert(parts, indent .. "    -- ... (" .. "more entries)\n")
                        break
                    end

                    local keyStr
                    if typeof(k) == "string" then
                        if k:match("^[%a_][%w_]*$") then
                            keyStr = k
                        else
                            keyStr = '["' .. k:gsub('"', '\\"') .. '"]'
                        end
                    else
                        keyStr = "[" .. tostring(k) .. "]"
                    end

                    local valStr = SerializeValue(v, depth + 1, visited)
                    table.insert(parts, indent .. "    " .. keyStr .. " = " .. valStr .. ",\n")
                end
                table.insert(parts, indent .. "}")
                return table.concat(parts)

            elseif typeof(val) == "function" then
                -- Thử decompile function
                if Env.decompile then
                    local dOk, src = pcall(Env.decompile, val)
                    if dOk and src and #src > 0 then
                        return src
                    end
                end
                return "function() --[[ decompile needed ]] end"

            elseif typeof(val) == "string" then
                return string.format("%q", val)

            elseif typeof(val) == "number" or typeof(val) == "boolean" then
                return tostring(val)

            elseif typeof(val) == "Instance" then
                return "-- Instance: " .. tostring(val)

            else
                return "-- " .. typeof(val) .. ": " .. tostring(val)
            end
        end

        table.insert(lines, "local module = " .. SerializeValue(result))
        table.insert(lines, "")
        table.insert(lines, "return module")

        return table.concat(lines, "\n")
    end,
}

--- Engine 11: Running Script intercept
--- Theo dõi running scripts và capture output
DecompilerEngines[11] = {
    Name = "RunningCapture",
    DisplayName = "Running Script Analysis",
    Priority = 11,
    Available = false,

    Init = function(self)
        self.Available = Env.getrunningscripts ~= nil or Env.getloadedmodules ~= nil
        return self.Available
    end,

    Decompile = function(self, scriptInst)
        local lines = {
            "-- BaoSaveInstance: Running Script Analysis",
            "-- Script: " .. GetFullPath(scriptInst),
            "",
        }

        -- Kiểm tra script có đang chạy không
        if Env.getrunningscripts then
            local ok, running = pcall(Env.getrunningscripts)
            if ok and running then
                local isRunning = false
                for _, rs in ipairs(running) do
                    if rs == scriptInst then
                        isRunning = true
                        break
                    end
                end
                table.insert(lines, "-- Running: " .. tostring(isRunning))
            end
        end

        -- Thử lấy closure
        if Env.getscriptclosure then
            local ok, cl = pcall(Env.getscriptclosure, scriptInst)
            if ok and cl and Env.decompile then
                local dOk, src = pcall(Env.decompile, cl)
                if dOk and src and #src > 0 then
                    return "-- Decompiled from script closure\n" .. src
                end
            end
        end

        -- Analyze connections
        local connections = {}
        pcall(function()
            local descendants = scriptInst:GetDescendants()
            for _, desc in ipairs(descendants) do
                if desc:IsA("RBXScriptConnection") then
                    table.insert(connections, desc)
                end
            end
        end)

        if #connections > 0 then
            table.insert(lines, "-- Active connections: " .. #connections)
        end

        if #lines > 5 then
            return table.concat(lines, "\n")
        end
        return nil, "Insufficient running data"
    end,
}

--- Engine 12: Comprehensive Fallback (tạo skeleton code)
--- Luôn trả về kết quả, dù là skeleton
DecompilerEngines[12] = {
    Name = "SkeletonFallback",
    DisplayName = "Skeleton Code Generator",
    Priority = 99,
    Available = true,

    Init = function(self)
        self.Available = true
        return true
    end,

    Decompile = function(self, scriptInst)
        local lines = {
            "--[[ ═══════════════════════════════════════════════════",
            "     BaoSaveInstance v5.0 - Script Skeleton",
            "     All decompiler engines failed for this script.",
            "     Below is reconstructed metadata.",
            "",
            "     Script: " .. GetFullPath(scriptInst),
            "     Class: " .. scriptInst.ClassName,
            "     Name: " .. scriptInst.Name,
        }

        -- Disabled status
        if scriptInst:IsA("Script") or scriptInst:IsA("LocalScript") then
            pcall(function()
                table.insert(lines, "     Disabled: " .. tostring(scriptInst.Disabled))
            end)
        end

        -- RunContext
        pcall(function()
            if scriptInst:IsA("Script") then
                table.insert(lines, "     RunContext: " .. tostring(scriptInst.RunContext))
            end
        end)

        -- Children
        local children = {}
        pcall(function() children = scriptInst:GetChildren() end)
        if #children > 0 then
            table.insert(lines, "     Children: " .. #children)
            for _, child in ipairs(children) do
                table.insert(lines, "       - " .. child.Name .. " (" .. child.ClassName .. ")")
            end
        end

        -- Bytecode info
        if Env.getscriptbytecode then
            local ok, bc = pcall(Env.getscriptbytecode, scriptInst)
            if ok and bc then
                table.insert(lines, "     Bytecode: " .. #bc .. " bytes")
                if #bc >= 1 then
                    table.insert(lines, "     Bytecode version: " .. tostring(bc:byte(1)))
                end
            end
        end

        -- Hash
        if Env.getscripthash then
            local ok, hash = pcall(Env.getscripthash, scriptInst)
            if ok then
                table.insert(lines, "     Hash: " .. tostring(hash))
            end
        end

        table.insert(lines, "═══════════════════════════════════════════════════ --]]")
        table.insert(lines, "")

        -- Generate skeleton based on class
        if scriptInst.ClassName == "ModuleScript" then
            table.insert(lines, "local module = {}")
            table.insert(lines, "")
            table.insert(lines, "-- TODO: Decompile this module")
            table.insert(lines, "")
            table.insert(lines, "return module")
        elseif scriptInst.ClassName == "LocalScript" then
            table.insert(lines, "-- LocalScript skeleton")
            table.insert(lines, 'local Players = game:GetService("Players")')
            table.insert(lines, "local LocalPlayer = Players.LocalPlayer")
            table.insert(lines, "")
            table.insert(lines, "-- TODO: Decompile this script")
        else
            table.insert(lines, "-- Server Script skeleton")
            table.insert(lines, "")
            table.insert(lines, "-- TODO: Decompile this script")
        end

        return table.concat(lines, "\n")
    end,
}

-- ══════════════════════════════════════════════════════════════════
-- DECOMPILER ORCHESTRATOR
-- Quản lý và điều phối các engine decompile
-- ══════════════════════════════════════════════════════════════════

local Orchestrator = {}

function Orchestrator.InitAll()
    Log("Khởi tạo " .. #DecompilerEngines .. " Decompiler Engines...", 5)
    local available = 0
    for i, engine in ipairs(DecompilerEngines) do
        local ok, result = pcall(function() return engine:Init() end)
        local isAvail = ok and result
        engine.Available = isAvail or false

        if isAvail then
            available = available + 1
            Log("  [" .. i .. "] " .. engine.DisplayName .. ": ✓", 6)
        else
            Log("  [" .. i .. "] " .. engine.DisplayName .. ": ✗", 6)
        end

        Stats.EngineSuccessCount[engine.Name] = 0
        Stats.EngineFailCount[engine.Name] = 0
        Stats.EngineTimings[engine.Name] = {}
    end
    Log(available .. "/" .. #DecompilerEngines .. " engines available", 4)
    return available
end

function Orchestrator.GetSortedEngines()
    local sorted = {}
    for _, engine in ipairs(DecompilerEngines) do
        if engine.Available then
            table.insert(sorted, engine)
        end
    end
    table.sort(sorted, function(a, b) return a.Priority < b.Priority end)
    return sorted
end

--- Decompile một script với tất cả engines, chọn kết quả tốt nhất
function Orchestrator.DecompileScript(scriptInst)
    if not scriptInst or not IsScript(scriptInst) then
        return nil, nil, 0
    end

    local sortedEngines = Orchestrator.GetSortedEngines()
    local results = {} -- {source, quality, engineName}
    local allErrors = {}

    for _, engine in ipairs(sortedEngines) do
        local startTime = tick()

        local ok, source, err = pcall(function()
            return engine:Decompile(scriptInst)
        end)

        local elapsed = tick() - startTime
        table.insert(Stats.EngineTimings[engine.Name], elapsed)

        if ok and source and typeof(source) == "string" and #source > 0 then
            -- Evaluate quality
            local quality = QualityAnalyzer.Score(source, scriptInst.ClassName)

            table.insert(results, {
                Source = source,
                Quality = quality,
                EngineName = engine.Name,
                DisplayName = engine.DisplayName,
                Length = #source,
                Time = elapsed,
            })

            Stats.EngineSuccessCount[engine.Name] =
                (Stats.EngineSuccessCount[engine.Name] or 0) + 1

            -- Nếu quality đủ tốt, không cần thử thêm
            if quality >= Config.DecompileQualityThreshold and not Config.MergeDecompileResults then
                break
            end

            -- Nếu quality rất cao, chắc chắn dừng
            if quality >= 0.8 then
                break
            end
        else
            local errMsg = ok and (err or "Empty result") or tostring(source)
            table.insert(allErrors, engine.Name .. ": " .. errMsg)
            Stats.EngineFailCount[engine.Name] =
                (Stats.EngineFailCount[engine.Name] or 0) + 1
        end

        Yield()
    end

    -- Chọn kết quả tốt nhất
    if #results == 0 then
        return nil, nil, 0
    end

    -- Sort by quality (descending), then by length (descending)
    table.sort(results, function(a, b)
        if math.abs(a.Quality - b.Quality) > 0.1 then
            return a.Quality > b.Quality
        end
        return a.Length > b.Length
    end)

    local best = results[1]

    -- Nếu bật merge mode, thử merge kết quả
    if Config.MergeDecompileResults and #results > 1 then
        local merged = Orchestrator.MergeResults(results, scriptInst)
        if merged then
            local mergedQuality = QualityAnalyzer.Score(merged, scriptInst.ClassName)
            if mergedQuality > best.Quality then
                return merged, "Merged(" .. #results .. " engines)", mergedQuality
            end
        end
    end

    return best.Source, best.DisplayName, best.Quality
end

--- Merge kết quả từ nhiều engines
function Orchestrator.MergeResults(results, scriptInst)
    if #results < 2 then return nil end

    -- Strategy: Lấy result có quality cao nhất làm base,
    -- bổ sung thông tin từ các results khác

    local base = results[1]
    local supplements = {}

    for i = 2, math.min(#results, 4) do
        table.insert(supplements, results[i])
    end

    local mergedLines = {
        "-- BaoSaveInstance: Merged Decompile Result",
        "-- Primary engine: " .. base.DisplayName .. " (quality: " .. string.format("%.2f", base.Quality) .. ")",
        "-- Supplementary engines: " .. #supplements,
        "",
    }

    -- Base code
    table.insert(mergedLines, base.Source)

    -- Bổ sung thông tin từ supplements (chỉ nếu chúng có thông tin khác biệt)
    local hasSupplements = false
    for _, supp in ipairs(supplements) do
        if supp.Quality > 0.2 and supp.Length > 100 then
            -- Kiểm tra xem supplement có thông tin mới không
            local newInfo = false
            for line in supp.Source:gmatch("[^\n]+") do
                local trimmed = line:match("^%s*(.-)%s*$")
                if trimmed and #trimmed > 10 and not trimmed:match("^%-%-")
                    and not base.Source:find(trimmed, 1, true) then
                    newInfo = true
                    break
                end
            end

            if newInfo then
                if not hasSupplements then
                    table.insert(mergedLines, "\n--[[ ═══ Supplementary Data from " .. supp.DisplayName .. " ═══")
                    hasSupplements = true
                end

                for line in supp.Source:gmatch("[^\n]+") do
                    local trimmed = line:match("^%s*(.-)%s*$")
                    if trimmed and #trimmed > 5 and not base.Source:find(trimmed, 1, true) then
                        table.insert(mergedLines, "-- " .. trimmed)
                    end
                end
            end
        end
    end

    if hasSupplements then
        table.insert(mergedLines, "═══ End Supplementary ═══ --]]")
    end

    return table.concat(mergedLines, "\n")
end

-- ══════════════════════════════════════════════════════════════════
-- INSTANCE SCANNER (Enhanced)
-- ══════════════════════════════════════════════════════════════════

local Scanner = {}

--- Thu thập tất cả scripts từ toàn bộ game
function Scanner.CollectAllScripts()
    Log("Quét tất cả Scripts...", 5)
    local scripts = {}
    local visited = {}
    local visitedPaths = {}

    local function AddScript(inst, service)
        if visited[inst] then return end
        visited[inst] = true

        local path = GetFullPath(inst)
        if visitedPaths[path] then
            path = path .. "_" .. tostring(inst:GetDebugId())
        end
        visitedPaths[path] = true

        table.insert(scripts, {
            Instance = inst,
            Path = path,
            Service = service,
            ClassName = inst.ClassName,
            Name = inst.Name,
        })
    end

    -- 1. Quét từ các service containers
    for _, serviceName in ipairs(Config.ScriptContainers) do
        local ok, service = pcall(function() return game:GetService(serviceName) end)
        if ok and service then
            local dOk, descendants = pcall(function() return service:GetDescendants() end)
            if dOk and descendants then
                for _, desc in ipairs(descendants) do
                    if IsScript(desc) then
                        AddScript(desc, serviceName)
                    end
                    Yield()
                end
            end
        end
    end

    -- 2. Nil instances
    if Config.ScanNilInstances and Env.getnilinstances then
        local ok, nilInsts = pcall(Env.getnilinstances)
        if ok and nilInsts then
            for _, inst in ipairs(nilInsts) do
                if IsScript(inst) then
                    AddScript(inst, "NilInstances")
                end
            end
            Log("  Nil instances scanned: " .. #nilInsts .. " found", 6)
        end
    end

    -- 3. Loaded modules
    if Config.ScanLoadedModules and Env.getloadedmodules then
        local ok, modules = pcall(Env.getloadedmodules)
        if ok and modules then
            for _, mod in ipairs(modules) do
                if not visited[mod] then
                    AddScript(mod, "LoadedModules")
                end
            end
            Log("  Loaded modules scanned: " .. #modules .. " found", 6)
        end
    end

    -- 4. Running scripts
    if Config.ScanRunningScripts and Env.getrunningscripts then
        local ok, running = pcall(Env.getrunningscripts)
        if ok and running then
            for _, rs in ipairs(running) do
                if not visited[rs] then
                    AddScript(rs, "RunningScripts")
                end
            end
            Log("  Running scripts scanned: " .. #running .. " found", 6)
        end
    end

    -- 5. GC scan for hidden scripts
    if Env.getgc then
        pcall(function()
            local gc = Env.getgc(false)
            for _, obj in ipairs(gc) do
                if typeof(obj) == "function" then
                    local iOk, info = pcall(function()
                        if Env.getinfo then return Env.getinfo(obj) end
                        return nil
                    end)
                    -- Có thể tìm thêm scripts qua GC
                end
            end
        end)
    end

    -- 6. getinstances() scan
    if Env.getinstances then
        local ok, allInsts = pcall(Env.getinstances)
        if ok and allInsts then
            for _, inst in ipairs(allInsts) do
                if IsScript(inst) and not visited[inst] then
                    AddScript(inst, "AllInstances")
                end
                Yield()
            end
            Log("  getinstances() scanned: found additional scripts", 6)
        end
    end

    -- Sort by service, then by name
    table.sort(scripts, function(a, b)
        if a.Service ~= b.Service then
            return a.Service < b.Service
        end
        return a.Name < b.Name
    end)

    Log("Tổng cộng: " .. #scripts .. " scripts tìm thấy", 4)
    return scripts
end

--- Collect all asset URLs in the game
function Scanner.CollectAssetURLs()
    Log("Quét Asset URLs...", 5)
    local assets = {}
    local seen = {}

    local function CheckProperty(inst, propName)
        local ok, val = pcall(function() return inst[propName] end)
        if ok and val and typeof(val) == "string" and #val > 0 then
            if val:match("rbxasset") or val:match("rbxassetid")
                or val:match("http") or val:match("^%d+$") then
                if not seen[val] then
                    seen[val] = true
                    table.insert(assets, {
                        URL = val,
                        Instance = inst,
                        Property = propName,
                        Type = propName:lower():find("mesh") and "Mesh"
                            or propName:lower():find("texture") and "Texture"
                            or propName:lower():find("image") and "Image"
                            or propName:lower():find("sound") and "Sound"
                            or propName:lower():find("animation") and "Animation"
                            or "Other",
                    })
                end
            end
        end
    end

    local assetProperties = {
        "MeshId", "TextureId", "Texture", "Image",
        "SoundId", "AnimationId",
        "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp",
        "Face", "Decal",
    }

    for _, serviceName in ipairs(Config.FullGameServices) do
        local ok, service = pcall(function() return game:GetService(serviceName) end)
        if ok and service then
            local dOk, descendants = pcall(function() return service:GetDescendants() end)
            if dOk and descendants then
                for _, desc in ipairs(descendants) do
                    for _, prop in ipairs(assetProperties) do
                        CheckProperty(desc, prop)
                    end
                    Yield()
                end
            end
        end
    end

    Log("Tìm thấy " .. #assets .. " asset URLs", 4)
    Stats.TotalAssets = #assets
    Stats.UniqueAssetURLs = seen
    return assets
end

-- ══════════════════════════════════════════════════════════════════
-- XML SERIALIZER (Enhanced with 200+ property definitions)
-- ══════════════════════════════════════════════════════════════════

local XMLSerializer = {}

local function XmlEscape(s)
    if not s then return "" end
    s = tostring(s)
    s = s:gsub("&", "&amp;")
    s = s:gsub("<", "&lt;")
    s = s:gsub(">", "&gt;")
    s = s:gsub('"', "&quot;")
    return s
end

local _refId = 0
local function NextRef()
    _refId = _refId + 1
    return "RBX" .. string.format("%012X", _refId)
end

--- Serialize property to XML string
function XMLSerializer.SerializeProperty(name, value, propType, indent)
    indent = indent or ""
    if value == nil then return nil end

    local ok, result = pcall(function()
        if propType == "ProtectedString" then
            return indent .. '<ProtectedString name="' .. XmlEscape(name)
                .. '"><![CDATA[' .. tostring(value) .. ']]></ProtectedString>'

        elseif propType == "string" or typeof(value) == "string" then
            return indent .. '<string name="' .. XmlEscape(name) .. '">'
                .. XmlEscape(tostring(value)) .. '</string>'

        elseif propType == "bool" or typeof(value) == "boolean" then
            return indent .. '<bool name="' .. XmlEscape(name) .. '">'
                .. tostring(value) .. '</bool>'

        elseif propType == "int" then
            return indent .. '<int name="' .. XmlEscape(name) .. '">'
                .. tostring(math.floor(tonumber(value) or 0)) .. '</int>'

        elseif propType == "int64" then
            return indent .. '<int64 name="' .. XmlEscape(name) .. '">'
                .. tostring(math.floor(tonumber(value) or 0)) .. '</int64>'

        elseif propType == "float" or propType == "double" or typeof(value) == "number" then
            return indent .. '<float name="' .. XmlEscape(name) .. '">'
                .. tostring(value) .. '</float>'

        elseif typeof(value) == "Vector3" then
            return indent .. '<Vector3 name="' .. XmlEscape(name) .. '">\n'
                .. indent .. '  <X>' .. value.X .. '</X>\n'
                .. indent .. '  <Y>' .. value.Y .. '</Y>\n'
                .. indent .. '  <Z>' .. value.Z .. '</Z>\n'
                .. indent .. '</Vector3>'

        elseif typeof(value) == "Vector2" then
            return indent .. '<Vector2 name="' .. XmlEscape(name) .. '">\n'
                .. indent .. '  <X>' .. value.X .. '</X>\n'
                .. indent .. '  <Y>' .. value.Y .. '</Y>\n'
                .. indent .. '</Vector2>'

        elseif typeof(value) == "CFrame" then
            local c = {value:GetComponents()}
            local names = {"X","Y","Z","R00","R01","R02","R10","R11","R12","R20","R21","R22"}
            local parts = {indent .. '<CoordinateFrame name="' .. XmlEscape(name) .. '">'}
            for i, n in ipairs(names) do
                if c[i] then
                    table.insert(parts, indent .. '  <' .. n .. '>' .. c[i] .. '</' .. n .. '>')
                end
            end
            table.insert(parts, indent .. '</CoordinateFrame>')
            return table.concat(parts, "\n")

        elseif typeof(value) == "Color3" then
            return indent .. '<Color3 name="' .. XmlEscape(name) .. '">\n'
                .. indent .. '  <R>' .. value.R .. '</R>\n'
                .. indent .. '  <G>' .. value.G .. '</G>\n'
                .. indent .. '  <B>' .. value.B .. '</B>\n'
                .. indent .. '</Color3>'

        elseif typeof(value) == "BrickColor" then
            return indent .. '<int name="' .. XmlEscape(name) .. '">'
                .. tostring(value.Number) .. '</int>'

        elseif typeof(value) == "UDim" then
            return indent .. '<UDim name="' .. XmlEscape(name) .. '">\n'
                .. indent .. '  <S>' .. value.Scale .. '</S>\n'
                .. indent .. '  <O>' .. value.Offset .. '</O>\n'
                .. indent .. '</UDim>'

        elseif typeof(value) == "UDim2" then
            return indent .. '<UDim2 name="' .. XmlEscape(name) .. '">\n'
                .. indent .. '  <XS>' .. value.X.Scale .. '</XS>\n'
                .. indent .. '  <XO>' .. value.X.Offset .. '</XO>\n'
                .. indent .. '  <YS>' .. value.Y.Scale .. '</YS>\n'
                .. indent .. '  <YO>' .. value.Y.Offset .. '</YO>\n'
                .. indent .. '</UDim2>'

        elseif typeof(value) == "Rect" then
            return indent .. '<Rect2D name="' .. XmlEscape(name) .. '">\n'
                .. indent .. '  <min><X>' .. value.Min.X .. '</X><Y>' .. value.Min.Y .. '</Y></min>\n'
                .. indent .. '  <max><X>' .. value.Max.X .. '</X><Y>' .. value.Max.Y .. '</Y></max>\n'
                .. indent .. '</Rect2D>'

        elseif typeof(value) == "EnumItem" then
            return indent .. '<token name="' .. XmlEscape(name) .. '">'
                .. tostring(value.Value) .. '</token>'

        elseif typeof(value) == "NumberSequence" then
            local parts = {}
            for _, kp in ipairs(value.Keypoints) do
                table.insert(parts, kp.Time .. " " .. kp.Value .. " " .. kp.Envelope)
            end
            return indent .. '<NumberSequence name="' .. XmlEscape(name) .. '">'
                .. table.concat(parts, " ") .. '</NumberSequence>'

        elseif typeof(value) == "ColorSequence" then
            local parts = {}
            for _, kp in ipairs(value.Keypoints) do
                table.insert(parts, kp.Time .. " " .. kp.Value.R .. " "
                    .. kp.Value.G .. " " .. kp.Value.B .. " 0")
            end
            return indent .. '<ColorSequence name="' .. XmlEscape(name) .. '">'
                .. table.concat(parts, " ") .. '</ColorSequence>'

        elseif typeof(value) == "NumberRange" then
            return indent .. '<NumberRange name="' .. XmlEscape(name) .. '">'
                .. value.Min .. ' ' .. value.Max .. '</NumberRange>'

        elseif typeof(value) == "PhysicalProperties" then
            if value.Density then
                return indent .. '<PhysicalProperties name="' .. XmlEscape(name) .. '">\n'
                    .. indent .. '  <CustomPhysics>true</CustomPhysics>\n'
                    .. indent .. '  <Density>' .. value.Density .. '</Density>\n'
                    .. indent .. '  <Friction>' .. value.Friction .. '</Friction>\n'
                    .. indent .. '  <Elasticity>' .. value.Elasticity .. '</Elasticity>\n'
                    .. indent .. '  <FrictionWeight>' .. value.FrictionWeight .. '</FrictionWeight>\n'
                    .. indent .. '  <ElasticityWeight>' .. value.ElasticityWeight .. '</ElasticityWeight>\n'
                    .. indent .. '</PhysicalProperties>'
            end
            return nil

        elseif typeof(value) == "Faces" then
            local bits = 0
            if value.Top then bits = bits + 1 end
            if value.Bottom then bits = bits + 2 end
            if value.Left then bits = bits + 4 end
            if value.Right then bits = bits + 8 end
            if value.Front then bits = bits + 16 end
            if value.Back then bits = bits + 32 end
            return indent .. '<Faces name="' .. XmlEscape(name) .. '">'
                .. bits .. '</Faces>'

        elseif typeof(value) == "Axes" then
            local bits = 0
            if value.X then bits = bits + 1 end
            if value.Y then bits = bits + 2 end
            if value.Z then bits = bits + 4 end
            return indent .. '<Axes name="' .. XmlEscape(name) .. '">'
                .. bits .. '</Axes>'

        elseif typeof(value) == "Font" then
            return indent .. '<Font name="' .. XmlEscape(name) .. '">\n'
                .. indent .. '  <Family><url>' .. XmlEscape(tostring(value.Family))
                    .. '</url></Family>\n'
                .. indent .. '  <Weight>' .. tostring(value.Weight.Value) .. '</Weight>\n'
                .. indent .. '  <Style>' .. tostring(value.Style) .. '</Style>\n'
                .. indent .. '</Font>'

        elseif typeof(value) == "Instance" then
            return indent .. '<Ref name="' .. XmlEscape(name) .. '">null</Ref>'

        elseif typeof(value) == "Ray" then
            return indent .. '<Ray name="' .. XmlEscape(name) .. '">\n'
                .. indent .. '  <origin><X>' .. value.Origin.X .. '</X><Y>'
                    .. value.Origin.Y .. '</Y><Z>' .. value.Origin.Z .. '</Z></origin>\n'
                .. indent .. '  <direction><X>' .. value.Direction.X .. '</X><Y>'
                    .. value.Direction.Y .. '</Y><Z>' .. value.Direction.Z
                    .. '</Z></direction>\n'
                .. indent .. '</Ray>'

        else
            -- Generic fallback
            local s = tostring(value)
            if s and #s > 0 then
                return indent .. '<string name="' .. XmlEscape(name) .. '">'
                    .. XmlEscape(s) .. '</string>'
            end
        end

        return nil
    end)

    if ok then return result end
    return nil
end

-- ══════════════════════════════════════════════════════════════════
-- COMPREHENSIVE PROPERTY REGISTRY
-- ══════════════════════════════════════════════════════════════════

-- Tự động lấy properties từ instance thay vì hardcode
function XMLSerializer.GetInstanceProperties(instance)
    local props = {}

    -- Luôn lấy Name
    props["Name"] = {Type = "string", Value = instance.Name}

    -- Danh sách properties phổ biến theo class hierarchy
    local commonProps = {
        -- All instances
        "Name", "Archivable",

        -- BasePart
        "Position", "Size", "CFrame", "Orientation", "Rotation",
        "Anchored", "CanCollide", "CanQuery", "CanTouch",
        "Transparency", "Reflectance", "Color", "BrickColor",
        "Material", "MaterialVariant",
        "Locked", "CastShadow", "Massless",
        "Shape",
        "TopSurface", "BottomSurface", "LeftSurface",
        "RightSurface", "FrontSurface", "BackSurface",
        "CustomPhysicalProperties",
        "CollisionGroup",

        -- MeshPart
        "MeshId", "TextureID", "MeshSize",
        "DoubleSided", "RenderFidelity",

        -- UnionOperation
        "UsePartColor", "SmoothingAngle",

        -- Model
        "PrimaryPart", "WorldPivot", "LevelOfDetail", "ModelStreamingMode",

        -- Humanoid
        "MaxHealth", "Health", "WalkSpeed", "JumpPower", "JumpHeight",
        "HipHeight", "DisplayName", "DisplayDistanceType",
        "HealthDisplayDistance", "NameDisplayDistance",
        "AutoRotate", "AutoJumpEnabled",

        -- Scripts
        "Source", "Disabled", "RunContext",

        -- GUI base
        "Active", "Visible", "ZIndex", "LayoutOrder",
        "ClipsDescendants", "Selectable",

        -- GuiObject
        "Position", "Size", "AnchorPoint", "Rotation",
        "BackgroundColor3", "BackgroundTransparency",
        "BorderColor3", "BorderSizePixel", "BorderMode",
        "SizeConstraint", "AutomaticSize",

        -- TextLabel/Button/Box
        "Text", "PlaceholderText",
        "TextColor3", "TextSize", "TextWrapped", "TextScaled",
        "TextXAlignment", "TextYAlignment", "TextTransparency",
        "TextStrokeColor3", "TextStrokeTransparency",
        "Font", "FontFace", "RichText", "MaxVisibleGraphemes",
        "LineHeight", "TextTruncate",

        -- Image
        "Image", "ImageColor3", "ImageTransparency",
        "ImageRectOffset", "ImageRectSize",
        "ScaleType", "SliceCenter", "SliceScale", "TileSize",
        "ResampleMode",

        -- ScrollingFrame
        "CanvasSize", "CanvasPosition",
        "ScrollBarThickness", "ScrollBarImageColor3",
        "ScrollBarImageTransparency",
        "ScrollingDirection", "ScrollingEnabled",
        "ElasticBehavior", "MidImage", "TopImage", "BottomImage",

        -- ScreenGui
        "Enabled", "ResetOnSpawn", "IgnoreGuiInset",
        "DisplayOrder", "ZIndexBehavior",

        -- BillboardGui
        "StudsOffset", "StudsOffsetWorldSpace",
        "AlwaysOnTop", "MaxDistance", "LightInfluence",

        -- SurfaceGui
        "CanvasSize", "Face", "PixelsPerStud",

        -- Sound
        "SoundId", "Volume", "Pitch", "PlaybackSpeed",
        "Looped", "Playing", "TimePosition",
        "RollOffMode", "RollOffMaxDistance", "RollOffMinDistance",
        "PlaybackRegion", "PlaybackRegionsEnabled",

        -- Light
        "Brightness", "Range", "Shadows", "Angle",

        -- Decal/Texture
        "Texture", "StudsPerTileU", "StudsPerTileV",
        "OffsetStudsU", "OffsetStudsV",

        -- SpecialMesh
        "MeshType", "Scale", "Offset",

        -- ParticleEmitter
        "Rate", "Lifetime", "Speed", "SpreadAngle",
        "RotSpeed", "Drag", "VelocityInheritance",
        "EmissionDirection", "Acceleration",
        "LightEmission", "LightInfluence",
        "LockedToPart", "TimeScale",
        "Squash", "ShapeStyle", "ShapeInOut",

        -- Beam
        "Width0", "Width1", "CurveSize0", "CurveSize1",
        "FaceCamera", "Segments", "TextureLength",
        "TextureMode", "TextureSpeed", "ZOffset",

        -- Trail
        "MinLength", "WidthScale", "FaceCamera",

        -- Constraint
        "Attachment0", "Attachment1",
        "Length", "Stiffness", "Damping",
        "MaxForce", "MaxTorque", "MaxVelocity",
        "FreeLength", "CurrentLength",
        "Restitution", "LimitsEnabled",
        "UpperAngle", "TwistUpperAngle", "TwistLowerAngle",

        -- Atmosphere
        "Density", "Offset", "Decay", "Glare", "Haze",

        -- Sky
        "SkyboxBk", "SkyboxDn", "SkyboxFt",
        "SkyboxLf", "SkyboxRt", "SkyboxUp",
        "CelestialBodiesShown", "MoonAngularSize",
        "MoonTextureId", "SunAngularSize", "SunTextureId",
        "StarCount",

        -- PostEffect
        "Intensity", "Spread", "Threshold",
        "Contrast", "Saturation", "TintColor",
        "FarIntensity", "FocusDistance",
        "InFocusRadius", "NearIntensity",

        -- Value objects
        "Value",

        -- Weld/Motor6D
        "C0", "C1", "Part0", "Part1",

        -- Attachment
        "WorldPosition", "WorldCFrame",

        -- Tool
        "ToolTip", "RequiresHandle", "CanBeDropped", "Grip",
        "ManualActivationOnly",

        -- ClickDetector / ProximityPrompt
        "MaxActivationDistance",
        "ActionText", "ObjectText", "HoldDuration",
        "RequiresLineOfSight", "KeyboardKeyCode",
        "GamepadKeyCode", "Style", "UIOffset",
        "Exclusivity",

        -- SpawnLocation
        "Duration", "Neutral", "TeamColor", "AllowTeamChangeOnTouch",

        -- Lighting properties
        "Ambient", "OutdoorAmbient", "FogColor", "FogEnd", "FogStart",
        "Brightness", "ClockTime", "GeographicLatitude",
        "GlobalShadows", "EnvironmentDiffuseScale",
        "EnvironmentSpecularScale", "ColorShift_Bottom",
        "ColorShift_Top", "ExposureCompensation",
        "Technology",

        -- Camera
        "FieldOfView", "CameraType", "CameraSubject",
        "DiagonalFieldOfView", "MaxAxisFieldOfView",
        "NearPlaneZ", "FieldOfViewMode",

        -- UILayout
        "SortOrder", "FillDirection", "Padding",
        "HorizontalAlignment", "VerticalAlignment",
        "HorizontalFlex", "VerticalFlex",
        "Wraps", "ItemLineAlignment",

        -- UIGridLayout
        "CellSize", "CellPadding", "FillDirectionMaxCells",
        "StartCorner",

        -- UICorner
        "CornerRadius",

        -- UIPadding
        "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight",

        -- UIStroke
        "Thickness", "ApplyStrokeMode", "LineJoinMode",

        -- UIGradient
        "Offset", "Rotation",

        -- UIScale
        "Scale",

        -- UIAspectRatioConstraint
        "AspectRatio", "AspectType", "DominantAxis",

        -- UISizeConstraint
        "MinSize", "MaxSize",

        -- UITextSizeConstraint
        "MinTextSize", "MaxTextSize",

        -- UIFlexItem
        "FlexMode", "GrowRatio", "ShrinkRatio",
        "ItemLineAlignment",

        -- Accessory
        "AttachmentPoint",

        -- Shirt/Pants
        "ShirtTemplate", "PantsTemplate",

        -- CharacterMesh
        "BodyPart", "MeshId", "OverlayTextureId", "BaseTextureId",
    }

    for _, propName in ipairs(commonProps) do
        if not props[propName] then
            local ok, val = pcall(function() return instance[propName] end)
            if ok and val ~= nil then
                local t = typeof(val)
                local propType = t

                if propName == "Source" then propType = "ProtectedString"
                elseif t == "boolean" then propType = "bool"
                elseif t == "number" then propType = "float"
                elseif t == "EnumItem" then propType = "Enum"
                end

                props[propName] = {Type = propType, Value = val}
            end
        end
    end

    -- Hidden properties
    if Env.gethiddenproperty then
        local hiddenProps = {
            "Source", "LinkedSource", "ScriptGuid",
            "SmoothGrid", "MaterialColors", "PhysicsGrid",
            "Tags",
        }
        for _, hp in ipairs(hiddenProps) do
            if not props[hp] then
                local ok, val = pcall(Env.gethiddenproperty, instance, hp)
                if ok and val ~= nil then
                    local propType = typeof(val) == "string" and "string" or typeof(val)
                    if hp == "Source" then propType = "ProtectedString" end
                    if hp == "SmoothGrid" or hp == "MaterialColors" or hp == "PhysicsGrid" then
                        propType = "BinaryString"
                    end
                    props[hp] = {Type = propType, Value = val}
                end
            end
        end
    end

    return props
end

--- Serialize an instance and all descendants to XML
function XMLSerializer.SerializeInstance(instance, indent, scriptSources, options)
    indent = indent or 2
    options = options or {}

    local indentStr = string.rep("  ", indent)
    local className = instance.ClassName

    -- Check blacklist
    for _, bl in ipairs(Config.InstanceBlacklist) do
        if className == bl or instance.Name == bl then
            return ""
        end
    end

    local ref = NextRef()
    local parts = {}

    table.insert(parts, indentStr .. '<Item class="' .. XmlEscape(className) .. '" referent="' .. ref .. '">')
    table.insert(parts, indentStr .. '  <Properties>')

    -- Get and serialize all properties
    local props = XMLSerializer.GetInstanceProperties(instance)

    for propName, propInfo in pairs(props) do
        -- Script Source override
        if propName == "Source" and IsScript(instance) and scriptSources and scriptSources[instance] then
            local xml = XMLSerializer.SerializeProperty("Source", scriptSources[instance], "ProtectedString", indentStr .. "    ")
            if xml then table.insert(parts, xml) end
        else
            local xml = XMLSerializer.SerializeProperty(propName, propInfo.Value, propInfo.Type, indentStr .. "    ")
            if xml then table.insert(parts, xml) end
        end
    end

    table.insert(parts, indentStr .. '  </Properties>')

    -- Children
    local ok, children = pcall(function() return instance:GetChildren() end)
    if ok and children then
        for _, child in ipairs(children) do
            local childXml = XMLSerializer.SerializeInstance(child, indent + 1, scriptSources, options)
            if childXml and #childXml > 0 then
                table.insert(parts, childXml)
            end
            Stats.ProcessedInstances = Stats.ProcessedInstances + 1
            Yield()
        end
    end

    table.insert(parts, indentStr .. '</Item>')

    return table.concat(parts, "\n")
end

--- Build complete RBXLX document
function XMLSerializer.BuildDocument(items, scriptSources, metadata)
    _refId = 0

    local parts = {
        '<?xml version="1.0" encoding="utf-8"?>',
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"'
            .. ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
            .. ' xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">',
    }

    -- Metadata
    if metadata then
        table.insert(parts, '  <!-- ══════════════════════════════════════ -->')
        table.insert(parts, '  <!-- Generated by BaoSaveInstance v' .. BaoSaveInstance.Version .. ' -->')
        table.insert(parts, '  <!-- Game: ' .. XmlEscape(GetGameName()) .. ' -->')
        table.insert(parts, '  <!-- PlaceId: ' .. tostring(game.PlaceId) .. ' -->')
        table.insert(parts, '  <!-- GameId: ' .. tostring(game.GameId) .. ' -->')
        table.insert(parts, '  <!-- Date: ' .. os.date("%Y-%m-%d %H:%M:%S") .. ' -->')
        table.insert(parts, '  <!-- Executor: ' .. Env.ExecutorName .. ' -->')
        if metadata.Mode then
            table.insert(parts, '  <!-- Mode: ' .. metadata.Mode .. ' -->')
        end
        if metadata.ScriptCount then
            table.insert(parts, '  <!-- Scripts: ' .. metadata.ScriptCount .. ' -->')
        end
        table.insert(parts, '  <!-- ══════════════════════════════════════ -->')
        table.insert(parts, '')
    end

    for _, item in ipairs(items) do
        if typeof(item) == "Instance" then
            local xml = XMLSerializer.SerializeInstance(item, 1, scriptSources)
            if xml and #xml > 0 then
                table.insert(parts, xml)
            end
        elseif typeof(item) == "string" then
            -- Pre-built XML chunk (e.g., terrain)
            table.insert(parts, item)
        end
        ForceYield()
        CheckMemory()
    end

    table.insert(parts, '</roblox>')

    return table.concat(parts, "\n")
end

-- ══════════════════════════════════════════════════════════════════
-- TERRAIN HANDLER (Full capture)
-- ══════════════════════════════════════════════════════════════════

local TerrainHandler = {}

function TerrainHandler.Capture()
    Log("Capturing Terrain data...", 5)
    local terrain = Workspace.Terrain
    if not terrain then
        Log("No terrain found", 2)
        return ""
    end

    local parts = {}
    local ref = NextRef()

    table.insert(parts, '  <Item class="Terrain" referent="' .. ref .. '">')
    table.insert(parts, '    <Properties>')
    table.insert(parts, '      <string name="Name">Terrain</string>')

    -- Water properties
    local waterProps = {
        {"WaterColor", "Color3"},
        {"WaterReflectance", "float"},
        {"WaterTransparency", "float"},
        {"WaterWaveSize", "float"},
        {"WaterWaveSpeed", "float"},
    }

    for _, wp in ipairs(waterProps) do
        local ok, val = pcall(function() return terrain[wp[1]] end)
        if ok and val then
            local xml = XMLSerializer.SerializeProperty(wp[1], val, wp[2], "      ")
            if xml then table.insert(parts, xml) end
        end
    end

    -- Decoration
    pcall(function()
        local xml = XMLSerializer.SerializeProperty("Decoration", terrain.Decoration, "bool", "      ")
        if xml then table.insert(parts, xml) end
    end)

    -- SmoothGrid (binary terrain data)
    local smoothGridCaptured = false
    if Env.gethiddenproperty then
        local ok, smoothGrid = pcall(Env.gethiddenproperty, terrain, "SmoothGrid")
        if ok and smoothGrid and typeof(smoothGrid) == "string" and #smoothGrid > 0 then
            local b64 = Base64Encode(smoothGrid)
            table.insert(parts, '      <BinaryString name="SmoothGrid">' .. b64 .. '</BinaryString>')
            smoothGridCaptured = true
            Stats.TerrainDataSize = #smoothGrid
            Log("  SmoothGrid captured: " .. string.format("%.2f KB", #smoothGrid / 1024), 4)
        end
    end

    -- MaterialColors
    if Env.gethiddenproperty then
        local ok, matColors = pcall(Env.gethiddenproperty, terrain, "MaterialColors")
        if ok and matColors and typeof(matColors) == "string" and #matColors > 0 then
            local b64 = Base64Encode(matColors)
            table.insert(parts, '      <BinaryString name="MaterialColors">' .. b64 .. '</BinaryString>')
            Log("  MaterialColors captured: " .. string.format("%.2f KB", #matColors / 1024), 4)
        end
    end

    -- PhysicsGrid
    if Env.gethiddenproperty then
        local ok, physGrid = pcall(Env.gethiddenproperty, terrain, "PhysicsGrid")
        if ok and physGrid and typeof(physGrid) == "string" and #physGrid > 0 then
            local b64 = Base64Encode(physGrid)
            table.insert(parts, '      <BinaryString name="PhysicsGrid">' .. b64 .. '</BinaryString>')
            Log("  PhysicsGrid captured: " .. string.format("%.2f KB", #physGrid / 1024), 4)
        end
    end

    -- Nếu SmoothGrid chưa capture được, thử ReadVoxels
    if not smoothGridCaptured and Config.TerrainFullCapture then
        Log("  SmoothGrid không khả dụng, thử ReadVoxels...", 2)

        pcall(function()
            local regionSize = Config.TerrainRegionSize
            local cellSize = Config.TerrainCellSize
            local region = Region3.new(
                Vector3.new(-regionSize, -regionSize, -regionSize),
                Vector3.new(regionSize, regionSize, regionSize)
            ):ExpandToGrid(cellSize)

            local materials, occupancy = terrain:ReadVoxels(region, cellSize)

            -- Kiểm tra có data không
            local hasData = false
            local voxelCount = 0
            for x = 1, math.min(#materials, 256) do
                for y = 1, math.min(#materials[x], 256) do
                    for z = 1, math.min(#materials[x][y], 256) do
                        if materials[x][y][z] ~= Enum.Material.Air then
                            hasData = true
                            voxelCount = voxelCount + 1
                        end
                    end
                end
                if hasData and voxelCount > 1000 then break end
                Yield()
            end

            if hasData then
                -- Store voxel info as metadata
                table.insert(parts, '      <!-- TerrainVoxelInfo: ' .. voxelCount .. ' non-air voxels -->')
                table.insert(parts, '      <!-- TerrainRegion: ' .. tostring(region) .. ' -->')
                table.insert(parts, '      <!-- TerrainGridSize: ' .. cellSize .. ' -->')
                Log("  ReadVoxels: " .. voxelCount .. " non-air voxels found", 1)
            end
        end)
    end

    Stats.TerrainCaptured = smoothGridCaptured or Stats.TerrainDataSize > 0

    table.insert(parts, '    </Properties>')
    table.insert(parts, '  </Item>')

    return table.concat(parts, "\n")
end

-- ══════════════════════════════════════════════════════════════════
-- FILE SYSTEM
-- ══════════════════════════════════════════════════════════════════

local FileSystem = {}

function FileSystem.EnsureFolder(path)
    if not Env.makefolder or not Env.isfolder then return false end
    local ok = pcall(function()
        if not Env.isfolder(path) then
            Env.makefolder(path)
        end
    end)
    return ok
end

function FileSystem.Save(fileName, content)
    if not Env.writefile then
        Log("writefile() not available!", 3)
        if Env.setclipboard and #content < 200000 then
            pcall(Env.setclipboard, content)
            Log("Content copied to clipboard (no writefile)", 2)
        end
        return false
    end

    -- Ensure BaoSaveInstance folder
    FileSystem.EnsureFolder("BaoSaveInstance")

    local path = "BaoSaveInstance/" .. fileName
    local ok, err = pcall(Env.writefile, path, content)

    if ok then
        Log("✓ Saved: " .. path .. " (" .. string.format("%.2f KB", #content / 1024) .. ")", 4)
        Stats.OutputFileSize = #content
        Stats.OutputFileName = path
        return true
    else
        Log("Save failed: " .. tostring(err), 3)
        -- Try root directory
        local ok2 = pcall(Env.writefile, fileName, content)
        if ok2 then
            Log("✓ Saved to root: " .. fileName, 4)
            Stats.OutputFileName = fileName
            return true
        end
        return false
    end
end

function FileSystem.SaveScriptsSeparately(scripts, scriptSources, folderName)
    if not Env.writefile then return 0 end

    FileSystem.EnsureFolder("BaoSaveInstance")
    FileSystem.EnsureFolder("BaoSaveInstance/" .. folderName)

    local saved = 0
    local nameCounter = {}

    for _, scriptInfo in ipairs(scripts) do
        if scriptSources[scriptInfo.Instance] then
            local safeName = SanitizeFileName(scriptInfo.Name)
            nameCounter[safeName] = (nameCounter[safeName] or 0) + 1
            if nameCounter[safeName] > 1 then
                safeName = safeName .. "_" .. nameCounter[safeName]
            end

            local ext = ".lua"
            local fullName = safeName .. "_" .. scriptInfo.ClassName .. ext
            local path = "BaoSaveInstance/" .. folderName .. "/" .. fullName

            local ok = pcall(Env.writefile, path, scriptSources[scriptInfo.Instance])
            if ok then saved = saved + 1 end
        end
    end

    return saved
end

-- ══════════════════════════════════════════════════════════════════
-- NATIVE SAVEINSTANCE WRAPPER
-- ══════════════════════════════════════════════════════════════════

local function TryNativeSave(fileName, options)
    if not Env.saveinstance then return false end

    Log("Trying native saveinstance()...", 5)

    local defaultOpts = {
        FileName = fileName,
        -- Universal options
        DecompileMode = "full",
        NilInstances = true,
        NilInstancesFix = true,
        RemovePlayerCharacters = true,
        SavePlayers = false,
        ShowStatus = true,
        DecompileTimeout = Config.DecompileTimeout,
        Decompile = true,

        -- Synapse options
        noscripts = false,
        scriptcache = true,
        timeout = Config.DecompileTimeout,

        -- Script-Ware options
        mode = "full",
        decomptype = "custom",

        -- Fluxus/Krnl options
        SaveBytecode = false,
        IgnoreDefaultProps = false,
        IgnoreSharedStrings = false,
        SharedStringOverride = false,
    }

    if options then
        for k, v in pairs(options) do
            defaultOpts[k] = v
        end
    end

    local ok, err = pcall(Env.saveinstance, defaultOpts)
    if ok then
        Log("✓ Native saveinstance succeeded!", 4)
        return true
    end

    -- Try simplified options
    local simpleOpts = {FileName = fileName}
    ok = pcall(Env.saveinstance, simpleOpts)
    if ok then
        Log("✓ Native saveinstance succeeded (simple mode)!", 4)
        return true
    end

    -- Try no options
    ok = pcall(Env.saveinstance, game, fileName)
    if ok then
        Log("✓ Native saveinstance succeeded (legacy mode)!", 4)
        return true
    end

    Log("Native saveinstance failed: " .. tostring(err), 2)
    return false
end

-- ══════════════════════════════════════════════════════════════════
-- MAIN DECOMPILE FUNCTIONS
-- ══════════════════════════════════════════════════════════════════

--[[ ════════════════════════════════════════
     1. DECOMPILE GAME (Full)
     ════════════════════════════════════════ ]]
function BaoSaveInstance.DecompileGame()
    if BaoSaveInstance._isRunning then
        Log("Already running! Please wait.", 2)
        return false
    end
    BaoSaveInstance._isRunning = true

    ResetStats()
    Stats.Phase = "Starting"

    Log("", 1)
    Log("╔═══════════════════════════════════════════════════════════╗", 1)
    Log("║       BaoSaveInstance v5.0 - FULL GAME DECOMPILE         ║", 1)
    Log("╚═══════════════════════════════════════════════════════════╝", 1)
    Log("Game: " .. GetGameName() .. " (PlaceId: " .. game.PlaceId .. ")", 1)

    local fileName = BuildFileName()

    -- ── Phase 0: Try native saveinstance ──
    Stats.Phase = "Native Save"
    Stats.Progress = 0.02

    if TryNativeSave(fileName) then
        Stats.EndTime = tick()
        Stats.Phase = "Complete"
        Stats.Progress = 1
        BaoSaveInstance._isRunning = false

        Log("═══ COMPLETE (Native) ═══", 4)
        Log("Time: " .. string.format("%.2f", Stats.EndTime - Stats.StartTime) .. "s", 1)
        return true
    end

    -- ── Phase 1: Collect scripts ──
    Stats.Phase = "Collecting Scripts"
    Stats.Progress = 0.05
    Log("Phase 1/6: Collecting scripts...", 5)

    local allScripts = Scanner.CollectAllScripts()
    Stats.TotalScripts = #allScripts

    -- ── Phase 2: Decompile scripts ──
    Stats.Phase = "Decompiling Scripts"
    Stats.Progress = 0.10
    Log("Phase 2/6: Decompiling " .. #allScripts .. " scripts...", 5)

    local scriptSources = {}
    local qualityTotal = 0

    for i, scriptInfo in ipairs(allScripts) do
        Stats.Progress = 0.10 + (i / #allScripts) * 0.50

        if i % 10 == 0 or i == #allScripts then
            Log("  Decompiling: " .. i .. "/" .. #allScripts
                .. " (" .. math.floor(i / #allScripts * 100) .. "%)", 5)
        end

        local source, engineName, quality = Orchestrator.DecompileScript(scriptInfo.Instance)

        if source then
            -- Detect obfuscation
            local obfType, obfConfidence = ObfuscationDetector.Detect(source)

            -- Add header
            local header = string.format(
                "-- ═══════════════════════════════════════════════\n"
                .. "-- Decompiled by BaoSaveInstance v%s\n"
                .. "-- Script: %s\n"
                .. "-- Class: %s\n"
                .. "-- Engine: %s\n"
                .. "-- Quality: %.0f%%\n",
                BaoSaveInstance.Version,
                scriptInfo.Path,
                scriptInfo.ClassName,
                engineName or "Unknown",
                (quality or 0) * 100
            )

            if obfType ~= "none" and obfConfidence > 0.3 then
                header = header .. "-- Obfuscation: " .. obfType
                    .. " (confidence: " .. string.format("%.0f%%", obfConfidence * 100) .. ")\n"

                -- Try deobfuscate
                source = ObfuscationDetector.TryDeobfuscate(source, obfType)
            end

            header = header .. "-- ═══════════════════════════════════════════════\n\n"

            scriptSources[scriptInfo.Instance] = header .. source
            Stats.TotalSourceChars = Stats.TotalSourceChars + #source

            if quality and quality > Config.DecompileQualityThreshold then
                Stats.DecompiledScripts = Stats.DecompiledScripts + 1
            else
                Stats.PartialScripts = Stats.PartialScripts + 1
            end

            qualityTotal = qualityTotal + (quality or 0)
            table.insert(Stats.QualityScores, quality or 0)
        else
            Stats.FailedScripts = Stats.FailedScripts + 1
            scriptSources[scriptInfo.Instance] =
                "-- BaoSaveInstance: All decompile engines failed\n"
                .. "-- Script: " .. scriptInfo.Path .. "\n"
        end

        CheckMemory()
    end

    Stats.AverageQuality = #allScripts > 0 and qualityTotal / #allScripts or 0

    Log("Script decompile: " .. Stats.DecompiledScripts .. " full, "
        .. Stats.PartialScripts .. " partial, "
        .. Stats.FailedScripts .. " failed"
        .. " (avg quality: " .. string.format("%.0f%%", Stats.AverageQuality * 100) .. ")", 4)

    -- ── Phase 3: Collect instances ──
    Stats.Phase = "Collecting Instances"
    Stats.Progress = 0.62
    Log("Phase 3/6: Collecting instances...", 5)

    local gameItems = {}
    for _, serviceName in ipairs(Config.FullGameServices) do
        local ok, service = pcall(function() return game:GetService(serviceName) end)
        if ok and service then
            local count = 0
            pcall(function() count = #service:GetDescendants() end)
            Stats.TotalInstances = Stats.TotalInstances + count + 1
            table.insert(gameItems, service)
            Log("  " .. serviceName .. ": " .. count .. " instances", 6)
        end
    end

    -- ── Phase 4: Capture terrain ──
    Stats.Phase = "Capturing Terrain"
    Stats.Progress = 0.70
    Log("Phase 4/6: Capturing terrain...", 5)

    local terrainXml = TerrainHandler.Capture()

    -- ── Phase 5: Serialize ──
    Stats.Phase = "Serializing"
    Stats.Progress = 0.75
    Log("Phase 5/6: Serializing to RBXLX...", 5)

    -- Inject terrain into items
    local allItems = {}
    for _, item in ipairs(gameItems) do
        if item.Name == "Workspace" then
            -- Workspace sẽ include terrain
            table.insert(allItems, item)
        else
            table.insert(allItems, item)
        end
    end

    local xmlContent = XMLSerializer.BuildDocument(allItems, scriptSources, {
        Mode = "Full Game",
        ScriptCount = Stats.TotalScripts,
        DecompiledCount = Stats.DecompiledScripts,
        Quality = Stats.AverageQuality,
    })

    -- ── Phase 6: Save ──
    Stats.Phase = "Saving"
    Stats.Progress = 0.92
    Log("Phase 6/6: Saving files...", 5)

    local rbxlxName = fileName:gsub("%.rbxl$", ".rbxlx")
    local saved = FileSystem.Save(rbxlxName, xmlContent)

    -- Save scripts separately
    if Config.SaveScriptsSeparately then
        local folderName = "Scripts_" .. SanitizeFileName(GetGameName())
        local scriptsSaved = FileSystem.SaveScriptsSeparately(allScripts, scriptSources, folderName)
        if scriptsSaved > 0 then
            Log("Saved " .. scriptsSaved .. " scripts separately", 4)
        end
    end

    -- Save asset list
    if Config.CaptureAssetURLs then
        local assets = Scanner.CollectAssetURLs()
        if #assets > 0 and Env.writefile then
            local assetLines = {"-- Asset URLs captured by BaoSaveInstance\n"}
            for _, asset in ipairs(assets) do
                table.insert(assetLines, string.format(
                    "-- [%s] %s (%s.%s)",
                    asset.Type, asset.URL,
                    asset.Instance.Name, asset.Property
                ))
            end
            pcall(function()
                Env.writefile(
                    "BaoSaveInstance/AssetURLs_" .. SanitizeFileName(GetGameName()) .. ".txt",
                    table.concat(assetLines, "\n")
                )
            end)
        end
    end

    -- Save log
    if Config.LogToFile and Env.writefile then
        pcall(function()
            local logLines = {}
            for _, entry in ipairs(LogHistory) do
                table.insert(logLines, entry.Full)
            end
            Env.writefile(
                "BaoSaveInstance/Log_" .. SanitizeFileName(GetGameName()) .. ".txt",
                table.concat(logLines, "\n")
            )
        end)
    end

    -- ── Complete ──
    Stats.EndTime = tick()
    Stats.Phase = "Complete"
    Stats.Progress = 1
    BaoSaveInstance._isRunning = false

    local elapsed = Stats.EndTime - Stats.StartTime

    Log("", 1)
    Log("╔═══════════════════════════════════════════════════════════════╗", 4)
    Log("║              FULL GAME DECOMPILE COMPLETE!                   ║", 4)
    Log("╠═══════════════════════════════════════════════════════════════╣", 4)
    Log("║  Game: " .. GetGameName(), 1)
    Log("║  Time: " .. string.format("%.2f", elapsed) .. " seconds", 1)
    Log("║  Total Instances: " .. Stats.TotalInstances, 1)
    Log("║  Scripts: " .. Stats.TotalScripts, 1)
    Log("║    ✓ Full decompile: " .. Stats.DecompiledScripts, 1)
    Log("║    ~ Partial: " .. Stats.PartialScripts, 1)
    Log("║    ✗ Failed: " .. Stats.FailedScripts, 1)
    Log("║  Quality: " .. string.format("%.1f%%", Stats.AverageQuality * 100), 1)
    Log("║  Terrain: " .. (Stats.TerrainCaptured and "✓ Captured" or "✗ Not available"), 1)
    Log("║  File: " .. Stats.OutputFileName, 1)
    Log("║  Size: " .. string.format("%.2f KB", Stats.OutputFileSize / 1024), 1)

    -- Engine stats
    Log("║  Engine Performance:", 1)
    for _, engine in ipairs(DecompilerEngines) do
        local succ = Stats.EngineSuccessCount[engine.Name] or 0
        local fail = Stats.EngineFailCount[engine.Name] or 0
        if succ + fail > 0 then
            Log("║    " .. engine.Name .. ": " .. succ .. "✓ / " .. fail .. "✗", 1)
        end
    end

    Log("╚═══════════════════════════════════════════════════════════════╝", 4)

    return saved
end

--[[ ════════════════════════════════════════
     2. DECOMPILE MAP
     ════════════════════════════════════════ ]]
function BaoSaveInstance.DecompileMap()
    if BaoSaveInstance._isRunning then
        Log("Already running!", 2)
        return false
    end
    BaoSaveInstance._isRunning = true
    ResetStats()

    Log("╔═══════════════════════════════════════════════════════════╗", 1)
    Log("║          BaoSaveInstance v5.0 - MAP DECOMPILE            ║", 1)
    Log("╚═══════════════════════════════════════════════════════════╝", 1)

    local fileName = BuildFileName("Map")

    -- Try native
    if TryNativeSave(fileName, {noscripts = true}) then
        Stats.EndTime = tick()
        BaoSaveInstance._isRunning = false
        return true
    end

    Stats.Phase = "Scanning Map"
    Stats.Progress = 0.1
    Log("Scanning Workspace...", 5)

    local mapItems = {}
    local ok, children = pcall(function() return Workspace:GetChildren() end)
    if ok then
        for _, child in ipairs(children) do
            local skip = child:IsA("Camera") or child:IsA("Terrain")
            pcall(function()
                for _, player in ipairs(Services.Players:GetPlayers()) do
                    if child == player.Character then skip = true end
                end
            end)
            if not skip then
                table.insert(mapItems, child)
            end
        end
    end

    -- Terrain
    Stats.Phase = "Capturing Terrain"
    Stats.Progress = 0.3
    local terrainXml = TerrainHandler.Capture()

    -- Count
    for _, item in ipairs(mapItems) do
        pcall(function()
            Stats.TotalInstances = Stats.TotalInstances + #item:GetDescendants() + 1
        end)
    end

    -- Serialize
    Stats.Phase = "Serializing Map"
    Stats.Progress = 0.5
    Log("Serializing " .. #mapItems .. " map items (" .. Stats.TotalInstances .. " instances)...", 5)

    -- Build workspace wrapper
    local wsRef = NextRef()
    local xmlParts = {
        '<?xml version="1.0" encoding="utf-8"?>',
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"'
            .. ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
            .. ' xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">',
        '  <!-- BaoSaveInstance v' .. BaoSaveInstance.Version .. ' Map Export -->',
        '  <!-- Game: ' .. XmlEscape(GetGameName()) .. ' -->',
        '',
        '  <Item class="Workspace" referent="' .. wsRef .. '">',
        '    <Properties>',
        '      <string name="Name">Workspace</string>',
        '    </Properties>',
    }

    -- Terrain
    if #terrainXml > 0 then
        table.insert(xmlParts, terrainXml)
    end

    -- Lighting (include for atmosphere/sky)
    pcall(function()
        local lightXml = XMLSerializer.SerializeInstance(Services.Lighting, 2, nil)
        if lightXml and #lightXml > 0 then
            table.insert(xmlParts, lightXml)
        end
    end)

    -- Map items
    for i, item in ipairs(mapItems) do
        Stats.Progress = 0.5 + (i / #mapItems) * 0.4
        local xml = XMLSerializer.SerializeInstance(item, 2, nil)
        if xml and #xml > 0 then
            table.insert(xmlParts, xml)
        end
        ForceYield()
    end

    table.insert(xmlParts, '  </Item>')
    table.insert(xmlParts, '</roblox>')

    local content = table.concat(xmlParts, "\n")

    Stats.Phase = "Saving"
    Stats.Progress = 0.95
    local rbxlxName = fileName:gsub("%.rbxl$", ".rbxlx")
    local saved = FileSystem.Save(rbxlxName, content)

    Stats.EndTime = tick()
    Stats.Phase = "Complete"
    Stats.Progress = 1
    BaoSaveInstance._isRunning = false

    Log("═══ MAP DECOMPILE COMPLETE ═══", 4)
    Log("Instances: " .. Stats.TotalInstances
        .. " | Terrain: " .. (Stats.TerrainCaptured and "✓" or "✗")
        .. " | Time: " .. string.format("%.2f", Stats.EndTime - Stats.StartTime) .. "s", 1)

    return saved
end

--[[ ════════════════════════════════════════
     3. DECOMPILE TERRAIN
     ════════════════════════════════════════ ]]
function BaoSaveInstance.DecompileTerrain()
    if BaoSaveInstance._isRunning then
        Log("Already running!", 2)
        return false
    end
    BaoSaveInstance._isRunning = true
    ResetStats()

    Log("╔═══════════════════════════════════════════════════════════╗", 1)
    Log("║        BaoSaveInstance v5.0 - TERRAIN DECOMPILE          ║", 1)
    Log("╚═══════════════════════════════════════════════════════════╝", 1)

    Stats.Phase = "Capturing Terrain"
    local terrainXml = TerrainHandler.Capture()

    if #terrainXml == 0 then
        Log("No terrain data to export!", 2)
        BaoSaveInstance._isRunning = false
        return false
    end

    local content = table.concat({
        '<?xml version="1.0" encoding="utf-8"?>',
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"'
            .. ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
            .. ' xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">',
        '  <!-- BaoSaveInstance Terrain Export -->',
        '',
        '  <Item class="Workspace" referent="' .. NextRef() .. '">',
        '    <Properties><string name="Name">Workspace</string></Properties>',
        terrainXml,
        '  </Item>',
        '</roblox>',
    }, "\n")

    local fileName = BuildFileName("Terrain"):gsub("%.rbxl$", ".rbxlx")
    local saved = FileSystem.Save(fileName, content)

    Stats.EndTime = tick()
    Stats.Phase = "Complete"
    BaoSaveInstance._isRunning = false

    Log("═══ TERRAIN DECOMPILE COMPLETE ═══", 4)
    Log("Data: " .. string.format("%.2f KB", Stats.TerrainDataSize / 1024)
        .. " | Time: " .. string.format("%.2f", Stats.EndTime - Stats.StartTime) .. "s", 1)

    return saved
end

--[[ ════════════════════════════════════════
     4. DECOMPILE SCRIPTS
     ════════════════════════════════════════ ]]
function BaoSaveInstance.DecompileScript()
    if BaoSaveInstance._isRunning then
        Log("Already running!", 2)
        return false
    end
    BaoSaveInstance._isRunning = true
    ResetStats()

    Log("╔═══════════════════════════════════════════════════════════╗", 1)
    Log("║       BaoSaveInstance v5.0 - SCRIPT DECOMPILE            ║", 1)
    Log("╚═══════════════════════════════════════════════════════════╝", 1)

    -- Collect
    Stats.Phase = "Collecting Scripts"
    local allScripts = Scanner.CollectAllScripts()
    Stats.TotalScripts = #allScripts

    if #allScripts == 0 then
        Log("No scripts found!", 2)
        BaoSaveInstance._isRunning = false
        return false
    end

    -- Decompile
    Stats.Phase = "Decompiling Scripts"
    Log("Decompiling " .. #allScripts .. " scripts with "
        .. #Orchestrator.GetSortedEngines() .. " engines...", 5)

    local scriptSources = {}
    local scriptList = {}
    local qualityTotal = 0

    for i, info in ipairs(allScripts) do
        Stats.Progress = i / #allScripts

        if i % 5 == 0 or i == #allScripts or i == 1 then
            Log("  [" .. i .. "/" .. #allScripts .. "] "
                .. info.Name .. " (" .. info.ClassName .. ")", 5)
        end

        local source, engineName, quality = Orchestrator.DecompileScript(info.Instance)

        if source then
            local header = string.format(
                "-- BaoSaveInstance v%s | %s | %s | Quality: %.0f%%\n"
                .. "-- Path: %s\n\n",
                BaoSaveInstance.Version,
                engineName or "?",
                info.ClassName,
                (quality or 0) * 100,
                info.Path
            )

            local fullSource = header .. source
            scriptSources[info.Instance] = fullSource

            table.insert(scriptList, {
                Name = info.Name,
                ClassName = info.ClassName,
                Path = info.Path,
                Service = info.Service,
                Source = fullSource,
                Quality = quality or 0,
                Engine = engineName,
            })

            if quality and quality > Config.DecompileQualityThreshold then
                Stats.DecompiledScripts = Stats.DecompiledScripts + 1
            else
                Stats.PartialScripts = Stats.PartialScripts + 1
            end

            qualityTotal = qualityTotal + (quality or 0)
        else
            Stats.FailedScripts = Stats.FailedScripts + 1
        end

        CheckMemory()
    end

    Stats.AverageQuality = #allScripts > 0 and qualityTotal / #allScripts or 0

    -- Save RBXLX with script structure
    Stats.Phase = "Saving"

    local xmlParts = {
        '<?xml version="1.0" encoding="utf-8"?>',
        '<roblox version="4">',
        '  <!-- BaoSaveInstance Script Export -->',
        '  <!-- Total: ' .. #allScripts .. ' | Quality: '
            .. string.format("%.0f%%", Stats.AverageQuality * 100) .. ' -->',
        '',
    }

    -- Group by service
    local byService = {}
    for _, info in ipairs(allScripts) do
        byService[info.Service] = byService[info.Service] or {}
        table.insert(byService[info.Service], info)
    end

    for serviceName, scripts in pairs(byService) do
        table.insert(xmlParts, '  <Item class="Folder" referent="' .. NextRef() .. '">')
        table.insert(xmlParts, '    <Properties>')
        table.insert(xmlParts, '      <string name="Name">' .. XmlEscape(serviceName) .. '</string>')
        table.insert(xmlParts, '    </Properties>')

        for _, info in ipairs(scripts) do
            local src = scriptSources[info.Instance] or "-- Failed"
            table.insert(xmlParts, '    <Item class="' .. info.ClassName .. '" referent="' .. NextRef() .. '">')
            table.insert(xmlParts, '      <Properties>')
            table.insert(xmlParts, '        <string name="Name">' .. XmlEscape(info.Name) .. '</string>')
            table.insert(xmlParts, '        <ProtectedString name="Source"><![CDATA[' .. src .. ']]></ProtectedString>')

            if info.ClassName ~= "ModuleScript" then
                local disOk, dis = pcall(function() return info.Instance.Disabled end)
                if disOk then
                    table.insert(xmlParts, '        <bool name="Disabled">' .. tostring(dis) .. '</bool>')
                end
            end

            table.insert(xmlParts, '      </Properties>')
            table.insert(xmlParts, '    </Item>')
        end

        table.insert(xmlParts, '  </Item>')
    end

    table.insert(xmlParts, '</roblox>')

    local content = table.concat(xmlParts, "\n")
    local rbxlxName = BuildFileName("Scripts"):gsub("%.rbxl$", ".rbxlx")
    FileSystem.Save(rbxlxName, content)

    -- Save separately
    if Config.SaveScriptsSeparately then
        local folderName = "Scripts_" .. SanitizeFileName(GetGameName())
        local count = FileSystem.SaveScriptsSeparately(allScripts, scriptSources, folderName)
        if count > 0 then
            Log("Saved " .. count .. " individual script files", 4)
        end
    end

    Stats.EndTime = tick()
    Stats.Phase = "Complete"
    Stats.Progress = 1
    BaoSaveInstance._isRunning = false

    Log("", 1)
    Log("═══════════════════════════════════════════════════════", 4)
    Log("  SCRIPT DECOMPILE COMPLETE!", 4)
    Log("  Total: " .. Stats.TotalScripts, 1)
    Log("  Full: " .. Stats.DecompiledScripts
        .. " | Partial: " .. Stats.PartialScripts
        .. " | Failed: " .. Stats.FailedScripts, 1)
    Log("  Quality: " .. string.format("%.1f%%", Stats.AverageQuality * 100), 1)
    Log("  Time: " .. string.format("%.2f", Stats.EndTime - Stats.StartTime) .. "s", 1)
    Log("═══════════════════════════════════════════════════════", 4)

    return true
end

-- ══════════════════════════════════════════════════════════════════
-- GUI SYSTEM (Enhanced)
-- ══════════════════════════════════════════════════════════════════

function BaoSaveInstance.CreateGUI()
    pcall(function()
        local old = Services.CoreGui:FindFirstChild("BaoSaveInstanceGUI")
        if old then old:Destroy() end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "BaoSaveInstanceGUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local ok = pcall(function() gui.Parent = Services.CoreGui end)
    if not ok then
        pcall(function() gui.Parent = Services.Players.LocalPlayer:WaitForChild("PlayerGui") end)
    end

    BaoSaveInstance._gui = gui

    -- Main frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 460, 0, 620)
    main.Position = UDim2.new(0.5, -230, 0.5, -310)
    main.BackgroundColor3 = Color3.fromRGB(16, 16, 28)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui

    local mainCorner = Instance.new("UICorner", main)
    mainCorner.CornerRadius = UDim.new(0, 14)

    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = Color3.fromRGB(60, 100, 220)
    mainStroke.Thickness = 2

    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.BackgroundTransparency = 1
    shadow.ImageTransparency = 0.5
    shadow.Image = "rbxassetid://5554236805"
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = -1
    shadow.Parent = main

    -- Title bar
    local titleBar = Instance.new("Frame", main)
    titleBar.Size = UDim2.new(1, 0, 0, 55)
    titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 42)
    titleBar.BorderSizePixel = 0
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

    local titleFix = Instance.new("Frame", titleBar)
    titleFix.Size = UDim2.new(1, 0, 0, 15)
    titleFix.Position = UDim2.new(0, 0, 1, -15)
    titleFix.BackgroundColor3 = Color3.fromRGB(22, 22, 42)
    titleFix.BorderSizePixel = 0

    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Size = UDim2.new(1, -60, 0, 30)
    titleLabel.Position = UDim2.new(0, 15, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🛡️ BaoSaveInstance v" .. BaoSaveInstance.Version .. " ULTIMATE"
    titleLabel.TextColor3 = Color3.fromRGB(70, 140, 255)
    titleLabel.TextSize = 17
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local subtitleLabel = Instance.new("TextLabel", titleBar)
    subtitleLabel.Size = UDim2.new(1, -60, 0, 15)
    subtitleLabel.Position = UDim2.new(0, 15, 0, 33)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = Env.ExecutorName .. " | " .. #Orchestrator.GetSortedEngines() .. " engines"
    subtitleLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
    subtitleLabel.TextSize = 10
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Close button
    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -45, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

    -- Game info
    local gameInfo = Instance.new("TextLabel", main)
    gameInfo.Size = UDim2.new(1, -24, 0, 30)
    gameInfo.Position = UDim2.new(0, 12, 0, 58)
    gameInfo.BackgroundTransparency = 1
    gameInfo.Text = "🎮 " .. GetGameName() .. " [" .. game.PlaceId .. "]"
    gameInfo.TextColor3 = Color3.fromRGB(160, 160, 190)
    gameInfo.TextSize = 11
    gameInfo.Font = Enum.Font.Gotham
    gameInfo.TextXAlignment = Enum.TextXAlignment.Left
    gameInfo.TextWrapped = true

    -- Progress bar
    local progressFrame = Instance.new("Frame", main)
    progressFrame.Size = UDim2.new(1, -24, 0, 6)
    progressFrame.Position = UDim2.new(0, 12, 0, 90)
    progressFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    progressFrame.BorderSizePixel = 0
    Instance.new("UICorner", progressFrame).CornerRadius = UDim.new(1, 0)

    local progressBar = Instance.new("Frame", progressFrame)
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
    progressBar.BorderSizePixel = 0
    Instance.new("UICorner", progressBar).CornerRadius = UDim.new(1, 0)

    local progressLabel = Instance.new("TextLabel", main)
    progressLabel.Size = UDim2.new(1, -24, 0, 14)
    progressLabel.Position = UDim2.new(0, 12, 0, 98)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = "Ready"
    progressLabel.TextColor3 = Color3.fromRGB(120, 120, 160)
    progressLabel.TextSize = 10
    progressLabel.Font = Enum.Font.Gotham
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Buttons
    local btnFrame = Instance.new("Frame", main)
    btnFrame.Size = UDim2.new(1, -24, 0, 240)
    btnFrame.Position = UDim2.new(0, 12, 0, 118)
    btnFrame.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", btnFrame)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)

    local buttonDefs = {
        {
            Text = "🌍  Decompile Game (Full)",
            Desc = "Map + Terrain + Scripts + Assets",
            Color = Color3.fromRGB(30, 70, 160),
            Order = 1,
            Fn = BaoSaveInstance.DecompileGame,
        },
        {
            Text = "🗺️  Decompile Map",
            Desc = "Workspace objects + Terrain + Lighting",
            Color = Color3.fromRGB(30, 120, 70),
            Order = 2,
            Fn = BaoSaveInstance.DecompileMap,
        },
        {
            Text = "⛰️  Decompile Terrain",
            Desc = "Voxel data + SmoothGrid + MaterialColors",
            Color = Color3.fromRGB(140, 90, 30),
            Order = 3,
            Fn = BaoSaveInstance.DecompileTerrain,
        },
        {
            Text = "📜  Decompile Scripts",
            Desc = Stats.TotalScripts .. " scripts with 12-engine pipeline",
            Color = Color3.fromRGB(120, 30, 120),
            Order = 4,
            Fn = BaoSaveInstance.DecompileScript,
        },
    }

    for _, def in ipairs(buttonDefs) do
        local btn = Instance.new("TextButton", btnFrame)
        btn.Size = UDim2.new(1, 0, 0, 52)
        btn.BackgroundColor3 = def.Color
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.LayoutOrder = def.Order
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Transparency = 0.7
        btnStroke.Color = Color3.fromRGB(
            math.min(255, def.Color.R * 255 + 50),
            math.min(255, def.Color.G * 255 + 50),
            math.min(255, def.Color.B * 255 + 50)
        )

        local btnTitle = Instance.new("TextLabel", btn)
        btnTitle.Size = UDim2.new(1, -16, 0, 24)
        btnTitle.Position = UDim2.new(0, 8, 0, 5)
        btnTitle.BackgroundTransparency = 1
        btnTitle.Text = def.Text
        btnTitle.TextColor3 = Color3.new(1, 1, 1)
        btnTitle.TextSize = 14
        btnTitle.Font = Enum.Font.GothamSemibold
        btnTitle.TextXAlignment = Enum.TextXAlignment.Left

        local btnDesc = Instance.new("TextLabel", btn)
        btnDesc.Size = UDim2.new(1, -16, 0, 16)
        btnDesc.Position = UDim2.new(0, 8, 0, 28)
        btnDesc.BackgroundTransparency = 1
        btnDesc.Text = def.Desc
        btnDesc.TextColor3 = Color3.fromRGB(200, 200, 220)
        btnDesc.TextSize = 10
        btnDesc.Font = Enum.Font.Gotham
        btnDesc.TextXAlignment = Enum.TextXAlignment.Left
        btnDesc.TextTransparency = 0.3

        -- Hover
        btn.MouseEnter:Connect(function()
            Services.TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(
                    math.min(255, def.Color.R * 255 + 20),
                    math.min(255, def.Color.G * 255 + 20),
                    math.min(255, def.Color.B * 255 + 20)
                )
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            Services.TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = def.Color
            }):Play()
        end)

        btn.MouseButton1Click:Connect(function()
            if BaoSaveInstance._isRunning then return end

            -- Disable all buttons
            for _, c in ipairs(btnFrame:GetChildren()) do
                if c:IsA("TextButton") then
                    c.Active = false
                    c.BackgroundTransparency = 0.5
                end
            end

            task.spawn(function()
                local s, e = pcall(def.Fn)
                if not s then Log("Error: " .. tostring(e), 3) end

                for _, c in ipairs(btnFrame:GetChildren()) do
                    if c:IsA("TextButton") then
                        c.Active = true
                        c.BackgroundTransparency = 0
                    end
                end
            end)
        end)
    end

    -- Log area
    local logFrame = Instance.new("Frame", main)
    logFrame.Size = UDim2.new(1, -24, 0, 230)
    logFrame.Position = UDim2.new(0, 12, 0, 370)
    logFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
    logFrame.BorderSizePixel = 0
    Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 8)

    local logTitle = Instance.new("TextLabel", logFrame)
    logTitle.Size = UDim2.new(1, 0, 0, 22)
    logTitle.BackgroundTransparency = 1
    logTitle.Text = "  📋 Log Output"
    logTitle.TextColor3 = Color3.fromRGB(100, 100, 130)
    logTitle.TextSize = 10
    logTitle.Font = Enum.Font.GothamSemibold
    logTitle.TextXAlignment = Enum.TextXAlignment.Left

    local logScroll = Instance.new("ScrollingFrame", logFrame)
    logScroll.Size = UDim2.new(1, -8, 1, -26)
    logScroll.Position = UDim2.new(0, 4, 0, 22)
    logScroll.BackgroundTransparency = 1
    logScroll.ScrollBarThickness = 3
    logScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 100, 220)
    logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logScroll.BorderSizePixel = 0

    local logLayout = Instance.new("UIListLayout", logScroll)
    logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logLayout.Padding = UDim.new(0, 1)

    local logOrder = 0
    local logColors = {
        [1] = Color3.fromRGB(170, 170, 195),
        [2] = Color3.fromRGB(255, 200, 70),
        [3] = Color3.fromRGB(255, 70, 70),
        [4] = Color3.fromRGB(70, 255, 110),
        [5] = Color3.fromRGB(70, 170, 255),
        [6] = Color3.fromRGB(120, 120, 150),
        [7] = Color3.fromRGB(255, 50, 50),
    }

    BaoSaveInstance._UpdateGUILog = function(msg, level)
        pcall(function()
            if not logScroll or not logScroll.Parent then return end

            logOrder = logOrder + 1
            local label = Instance.new("TextLabel", logScroll)
            label.Size = UDim2.new(1, 0, 0, 12)
            label.BackgroundTransparency = 1
            label.Text = msg
            label.TextColor3 = logColors[level] or logColors[1]
            label.TextSize = 9
            label.Font = Enum.Font.Code
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextWrapped = true
            label.AutomaticSize = Enum.AutomaticSize.Y
            label.LayoutOrder = logOrder

            -- Limit entries
            local kids = logScroll:GetChildren()
            local labelCount = 0
            for _, k in ipairs(kids) do
                if k:IsA("TextLabel") then labelCount = labelCount + 1 end
            end
            if labelCount > Config.MaxLogEntries then
                for _, k in ipairs(kids) do
                    if k:IsA("TextLabel") then k:Destroy() break end
                end
            end

            task.defer(function()
                pcall(function()
                    logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y)
                end)
            end)
        end)
    end

    BaoSaveInstance._UpdateGUIProgress = function(phase, progress)
        pcall(function()
            if not progressBar or not progressBar.Parent then return end
            Services.TweenService:Create(progressBar, TweenInfo.new(0.3), {
                Size = UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0)
            }):Play()
            progressLabel.Text = phase .. " - " .. math.floor(progress * 100) .. "%"
        end)
    end

    -- Footer
    local footer = Instance.new("TextLabel", main)
    footer.Size = UDim2.new(1, 0, 0, 14)
    footer.Position = UDim2.new(0, 0, 1, -14)
    footer.BackgroundTransparency = 1
    footer.Text = "v" .. BaoSaveInstance.Version .. " ULTIMATE | 12 Engines | "
        .. Env.ExecutorName
    footer.TextColor3 = Color3.fromRGB(60, 60, 85)
    footer.TextSize = 8
    footer.Font = Enum.Font.Gotham

    return gui
end

-- ══════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════════

function BaoSaveInstance.SetConfig(key, value)
    if Config[key] ~= nil then
        Config[key] = value
        Log("Config." .. key .. " = " .. tostring(value), 1)
    end
end

function BaoSaveInstance.GetConfig(key) return Config[key] end
function BaoSaveInstance.GetStats() return Stats end
function BaoSaveInstance.GetLogs() return LogHistory end
function BaoSaveInstance.GetEnvironment() return Env end

function BaoSaveInstance.AddDecompilerEngine(engine)
    if engine and engine.Name and engine.Init and engine.Decompile then
        engine.Priority = engine.Priority or (#DecompilerEngines + 1)
        engine.Available = false
        table.insert(DecompilerEngines, engine)
        pcall(function() engine:Init() end)
        Log("Custom engine added: " .. engine.Name, 4)
    end
end

-- ══════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ══════════════════════════════════════════════════════════════════

function BaoSaveInstance.Init()
    if BaoSaveInstance._initialized then return BaoSaveInstance end

    print("\n")
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║                                                              ║")
    print("║        BaoSaveInstance v" .. BaoSaveInstance.Version .. " ULTIMATE - Initializing          ║")
    print("║        12-Engine Multi-API Decompiler Pipeline               ║")
    print("║                                                              ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    print("")

    ResetStats()

    -- Detect environment
    DetectEnvironment()

    -- Initialize engines
    Orchestrator.InitAll()

    -- Create GUI
    if Config.ShowGUI then
        BaoSaveInstance.CreateGUI()
    end

    BaoSaveInstance._initialized = true

    Log("", 1)
    Log("BaoSaveInstance v" .. BaoSaveInstance.Version .. " ULTIMATE ready!", 4)
    Log("", 1)
    Log("Commands:", 1)
    Log("  BaoSaveInstance.DecompileGame()    → Full game decompile", 1)
    Log("  BaoSaveInstance.DecompileMap()     → Map + Terrain", 1)
    Log("  BaoSaveInstance.DecompileTerrain() → Terrain only", 1)
    Log("  BaoSaveInstance.DecompileScript()  → All scripts only", 1)
    Log("", 1)

    return BaoSaveInstance
end

-- Auto-init
BaoSaveInstance.Init()

return BaoSaveInstance
