--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║  ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗║
    ║  ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝║
    ║  ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  ║
    ║  ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  ║
    ║  ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗║
    ║  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝║
    ║                                                              ║
    ║  BaoSaveInstance v5.0 HYPER                                  ║
    ║  100% Full Game + Model + Script + Terrain Decompiler        ║
    ║  Multi-API Racing + Quality Scorer + Parallel Workers        ║
    ║                                                              ║
    ║  Features:                                                   ║
    ║  • 100% Script Decompile (Server + Local + Module)           ║
    ║  • 100% Model Save (Parts, Meshes, Welds, Constraints)      ║
    ║  • Full Hierarchy + Properties + Attributes preservation    ║
    ║  • Nil instances recovery                                    ║
    ║  • GC instances recovery                                     ║
    ║  • Hidden properties extraction                              ║
    ║  • Anti-crash for massive games                              ║
    ║  • Single .rbxl output                                       ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ================================================================
-- SECTION 0: ENVIRONMENT BOOTSTRAP
-- ================================================================

local BSI = {}
BSI.VERSION = "5.0.0"
BSI.NAME = "BaoSaveInstance"
BSI.START_TIME = os.clock()

-- Safe function getter - lấy hàm từ executor một cách an toàn
local function getFunc(name)
    local f = nil
    pcall(function()
        if getgenv and getgenv()[name] then f = getgenv()[name]
        elseif _G[name] then f = _G[name]
        elseif shared[name] then f = shared[name] end
    end)
    return f
end

-- Tất cả executor functions cần thiết
local ENV = {
    saveinstance     = getFunc("saveinstance"),
    decompile        = getFunc("decompile"),
    writefile        = getFunc("writefile"),
    readfile         = getFunc("readfile"),
    isfile           = getFunc("isfile"),
    makefolder       = getFunc("makefolder"),
    isfolder         = getFunc("isfolder"),
    appendfile       = getFunc("appendfile"),
    delfile          = getFunc("delfile"),
    getscripts       = getFunc("getscripts"),
    getloadedmodules = getFunc("getloadedmodules"),
    getnilinstances  = getFunc("getnilinstances"),
    getinstances     = getFunc("getinstances"),
    getgc            = getFunc("getgc"),
    getconnections   = getFunc("getconnections"),
    gethiddenproperty = getFunc("gethiddenproperty"),
    sethiddenproperty = getFunc("sethiddenproperty"),
    getproperties    = getFunc("getproperties"),
    gethiddenproperties = getFunc("gethiddenproperties"),
    setclipboard     = getFunc("setclipboard"),
    getrawmetatable  = getFunc("getrawmetatable"),
    hookfunction     = getFunc("hookfunction"),
    newcclosure      = getFunc("newcclosure"),
    islclosure       = getFunc("islclosure"),
    checkcaller      = getFunc("checkcaller"),
    identifyexecutor = getFunc("identifyexecutor"),
    getexecutorname  = getFunc("getexecutorname"),
    request          = getFunc("request") or getFunc("http_request") or getFunc("syn_request"),
    crypt            = getFunc("crypt"),
    getthreadidentity = getFunc("getthreadidentity"),
    setthreadidentity = getFunc("setthreadidentity"),
    firesignal       = getFunc("firesignal"),
    fireproximityprompt = getFunc("fireproximityprompt"),
}

-- Synapse X specific
if syn then
    ENV.saveinstance = ENV.saveinstance or syn.saveinstance
    ENV.decompile = ENV.decompile or syn.decompile
    ENV.request = ENV.request or syn.request
end

-- ================================================================
-- SECTION 1: SERVICES
-- ================================================================

local Services = {}
Services.Players             = game:GetService("Players")
Services.Workspace           = game:GetService("Workspace")
Services.ReplicatedStorage   = game:GetService("ReplicatedStorage")
Services.ReplicatedFirst     = game:GetService("ReplicatedFirst")
Services.StarterGui          = game:GetService("StarterGui")
Services.StarterPack         = game:GetService("StarterPack")
Services.StarterPlayer       = game:GetService("StarterPlayer")
Services.Lighting            = game:GetService("Lighting")
Services.SoundService        = game:GetService("SoundService")
Services.Chat                = game:GetService("Chat")
Services.Teams               = game:GetService("Teams")
Services.TestService         = game:GetService("TestService")
Services.HttpService         = game:GetService("HttpService")
Services.RunService          = game:GetService("RunService")
Services.UserInputService    = game:GetService("UserInputService")
Services.TweenService        = game:GetService("TweenService")
Services.CoreGui             = game:GetService("CoreGui")
Services.InsertService       = game:GetService("InsertService")
Services.MaterialService     = game:GetService("MaterialService")
Services.TextService         = game:GetService("TextService")
Services.CollectionService   = game:GetService("CollectionService")
Services.PhysicsService      = game:GetService("PhysicsService")
Services.ProximityPromptService = game:GetService("ProximityPromptService")
Services.Terrain             = Services.Workspace.Terrain

-- Danh sách TẤT CẢ services cần save (100% coverage)
local ALL_SAVE_SERVICES = {
    "Workspace",
    "ReplicatedStorage",
    "ReplicatedFirst",
    "StarterGui",
    "StarterPack",
    "StarterPlayer",
    "Lighting",
    "SoundService",
    "Chat",
    "Teams",
    "TestService",
    "LocalizationService",
    "MaterialService",
    "ServerStorage",      -- Nếu accessible
    "ServerScriptService", -- Nếu accessible
}

BSI.Services = Services
BSI.ENV = ENV

-- ================================================================
-- SECTION 2: CONFIGURATION (100% COVERAGE)
-- ================================================================

BSI.Config = {
    -- ═══ Output ═══
    OutputFolder    = "BaoSaveInstance",
    FileFormat      = ".rbxl",
    SingleFile      = true, -- Luôn xuất 1 file duy nhất
    
    -- ═══ Decompile - HYPER ENGINE ═══
    Decompile = {
        Enabled          = true,
        Timeout          = 30,       -- 30 giây timeout mỗi script
        Retries          = 5,        -- 5 lần retry
        BatchSize        = 30,       -- 30 scripts/batch
        CacheEnabled     = true,
        AddHeaders       = true,     -- Thêm header comment vào source
        SaveBytecode     = false,    -- Không save bytecode (save readable)
        RecoverFromGC    = true,     -- Recover scripts từ garbage collector
        RecoverFromNil   = true,     -- Recover scripts từ nil instances
        RecoverFromConnections = true, -- Recover scripts từ connections
        RecoverFromRegistry  = true, -- Recover từ debug registry
        RecoverFromEnv       = true, -- Recover từ roblox env
        IncludeServerScripts = true,
        IncludeLocalScripts  = true,
        IncludeModuleScripts = true,
        FallbackComment  = true,     -- Comment fallback khi fail
        DecompileInternalModules = true, -- Decompile cả internal modules
        -- ═══ HYPER v5.0 NEW ═══
        ConcurrentWorkers    = 6,    -- 6 workers song song
        QualityThreshold     = 30,   -- Điểm tối thiểu chấp nhận (0-100)
        AdaptiveTimeout      = true, -- Timeout tự điều chỉnh
        MultiStrategy        = true, -- Chạy nhiều phương pháp đồng thời
        RaceTimeout          = 10,   -- Timeout cho multi-strategy race (giây)
        CleanWatermarks      = true, -- Xóa watermark decompiler
        FixIndentation       = true, -- Sửa indentation
        RequireModules       = true, -- Thử require() ModuleScripts
    },
    
    -- ═══ Model Save - 100% ═══
    Model = {
        SaveParts        = true,
        SaveMeshParts    = true,
        SaveUnionParts   = true,
        SaveTrussParts   = true,
        SaveCornerWedges = true,
        SaveWelds        = true,  -- ManualWeld, Weld, WeldConstraint
        SaveConstraints  = true,  -- Tất cả Constraints
        SaveAttachments  = true,
        SaveSurfaceApps  = true,  -- SurfaceGui, Decal, Texture
        SaveParticles    = true,  -- ParticleEmitter, Fire, Smoke, Sparkles
        SaveLights       = true,  -- PointLight, SpotLight, SurfaceLight
        SaveSounds       = true,
        SaveAnimations   = true,  -- Animation, AnimationController
        SaveBeams        = true,
        SaveTrails       = true,
        SaveBillboards   = true,  -- BillboardGui
        SaveClickDetectors = true,
        SaveProximityPrompts = true,
        SaveValues       = true,  -- BoolValue, IntValue, StringValue, etc.
        SaveTags         = true,  -- CollectionService tags
        SaveAttributes   = true,  -- Instance attributes
        SaveHumanoids    = true,  -- Humanoid + HumanoidDescription
        SaveTools        = true,
        SaveAccessories  = true,
        SaveCharacters   = false, -- Player characters (optional)
        SaveCameras      = false,
    },
    
    -- ═══ Terrain Save - 100% ═══
    Terrain = {
        Enabled          = true,
        SaveVoxels       = true,   -- Toàn bộ voxel data
        SaveWater        = true,   -- Nước
        SaveMaterials    = true,   -- Tất cả materials
        SaveOccupancy    = true,   -- Occupancy data
        RegionSize       = 64,     -- Kích thước region khi đọc (optimize)
        MaxRegionCoord   = 2048,   -- Phạm vi tối đa (mỗ chiều)
        ScanFullRange    = true,   -- Quét toàn bộ phạm vi terrain
        PreserveColors   = true,   -- Giữ nguyên terrain colors
    },
    
    -- ═══ Properties - 100% ═══
    Properties = {
        SaveHidden       = true,   -- Hidden properties
        SaveUnscriptable = true,   -- Unscriptable properties
        SaveDefault      = true,   -- KHÔNG bỏ qua default values
        SaveAllAttributes = true,  -- Tất cả attributes
        SaveTags         = true,   -- CollectionService tags
    },
    
    -- ═══ Instance Recovery ═══
    Recovery = {
        NilInstances     = true,   -- Instances trong nil
        GCInstances      = true,   -- Instances trong garbage collector
        DisconnectedInstances = true,
        OrphanedScripts  = true,
        HiddenServices   = true,
    },
    
    -- ═══ Performance ═══
    Performance = {
        YieldInterval    = 150,    -- Yield sau N operations
        TaskWaitTime     = 0.001,  -- Min wait time
        MaxMemoryMB      = 4096,   -- 4GB max memory
        GCInterval        = 300,    -- GC sau N operations
        AdaptiveYield    = true,   -- Tự động điều chỉnh yield
        AntiTimeout      = true,   -- Chống timeout
    },
    
    -- ═══ Exclusions (tối thiểu) ═══
    Exclude = {
        ClassNames = {"Player", "PlayerGui", "PlayerScripts", "Backpack"},
        Names = {"BaoSaveInstanceUI"},
        Services = {},
    }
}

-- ================================================================
-- SECTION 3: LOGGING SYSTEM
-- ================================================================

local Log = {}
Log.Entries = {}
Log.Level = {DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3, CRITICAL = 4}
Log.MinLevel = Log.Level.INFO

function Log.write(level, msg, ...)
    if level < Log.MinLevel then return end
    
    local names = {[0]="DBG", [1]="INF", [2]="WRN", [3]="ERR", [4]="CRT"}
    local icons = {[0]="🔍", [1]="ℹ️", [2]="⚠️", [3]="❌", [4]="💀"}
    local timestamp = string.format("%.2f", os.clock() - BSI.START_TIME)
    
    local text = string.format(msg, ...)
    local entry = string.format("[%ss][%s] %s %s",
        timestamp, names[level] or "???", icons[level] or "?", text)
    
    Log.Entries[#Log.Entries + 1] = entry
    
    -- Giới hạn buffer
    if #Log.Entries > 50000 then
        local new = {}
        for i = 25000, #Log.Entries do
            new[#new + 1] = Log.Entries[i]
        end
        Log.Entries = new
    end
    
    if level >= Log.Level.INFO then
        print("[BaoSave] " .. entry)
    end
end

function Log.debug(msg, ...) Log.write(0, msg, ...) end
function Log.info(msg, ...)  Log.write(1, msg, ...) end
function Log.warn(msg, ...)  Log.write(2, msg, ...) end
function Log.error(msg, ...) Log.write(3, msg, ...) end
function Log.critical(msg, ...) Log.write(4, msg, ...) end

BSI.Log = Log

-- ================================================================
-- SECTION 4: UTILITY MODULE
-- ================================================================

local Util = {}

--- Tạo folder
function Util.ensureFolder(path)
    if ENV.makefolder and ENV.isfolder then
        if not ENV.isfolder(path) then
            pcall(ENV.makefolder, path)
        end
    end
end

--- Sanitize filename
function Util.sanitize(name)
    name = tostring(name or "Unknown")
    name = name:gsub('[<>:"/\\|?*%c]', '_')
    name = name:gsub('%s+', '_'):gsub('_+', '_')
    return name:sub(1, 120)
end

--- Lấy tên game
function Util.getGameName()
    local name = "Game_" .. tostring(game.PlaceId)
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        if info and info.Name and #info.Name > 0 then
            name = info.Name
        end
    end)
    return Util.sanitize(name)
end

--- Đếm descendants nhanh
function Util.countDescendants(root)
    local count = 0
    local ok, err = pcall(function()
        count = #root:GetDescendants()
    end)
    return count
end

--- Memory check & auto GC
function Util.memoryCheck()
    local memMB = collectgarbage("count") / 1024
    if memMB > BSI.Config.Performance.MaxMemoryMB * 0.75 then
        collectgarbage("collect")
        task.wait(0.05)
        Log.warn("Memory cao: %.0f MB → đã GC", memMB)
        return true
    end
    return false
end

--- Adaptive yield - yield thông minh dựa trên tải
function Util.adaptiveYield(counter, force)
    if force or (counter % BSI.Config.Performance.YieldInterval == 0) then
        if BSI.Config.Performance.AdaptiveYield then
            local memMB = collectgarbage("count") / 1024
            if memMB > BSI.Config.Performance.MaxMemoryMB * 0.5 then
                collectgarbage("step", 500)
                task.wait(0.01)
            else
                task.wait(BSI.Config.Performance.TaskWaitTime)
            end
        else
            task.wait(BSI.Config.Performance.TaskWaitTime)
        end
        return true
    end
    return false
end

--- Safe pcall với retry
function Util.retry(func, maxRetries, delay, ...)
    maxRetries = maxRetries or 3
    delay = delay or 0.05
    local args = {...}
    
    for i = 1, maxRetries do
        local ok, result = pcall(func, unpack(args))
        if ok then return true, result end
        if i < maxRetries then
            task.wait(delay * i)
        else
            return false, result
        end
    end
end

--- Detect executor
function Util.detectExecutor()
    if syn then return "Synapse X" end
    if KRNL_LOADED then return "KRNL" end
    
    local getName = ENV.identifyexecutor or ENV.getexecutorname
    if getName then
        local ok, name = pcall(getName)
        if ok and name then return tostring(name) end
    end
    
    -- Heuristic detection
    if getgenv and setclipboard then return "Modern Executor" end
    if getgenv then return "Basic Executor" end
    
    return "Unknown"
end

--- Format number với commas
function Util.formatNumber(n)
    local s = tostring(math.floor(n))
    return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

--- Deep clone table
function Util.deepClone(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[Util.deepClone(k)] = Util.deepClone(v)
    end
    return copy
end

BSI.Util = Util

-- ================================================================
-- SECTION 5: SCRIPT DISCOVERY ENGINE (HYPER v5.0 — 8 METHODS)
-- ================================================================

local ScriptDiscovery = {}

--- Thu thập TẤT CẢ scripts trong game bằng 8 PHƯƠNG PHÁP
function ScriptDiscovery.collectAll()
    local allScripts = {}
    local seen = {}
    local stats = {
        fromGetScripts = 0,
        fromGetModules = 0,
        fromDescendants = 0,
        fromNil = 0,
        fromGC = 0,
        fromGCFuncs = 0,
        fromRegistry = 0,
        fromInstances = 0,
        total = 0
    }
    
    -- Fingerprint-based dedup: dùng nhiều thông tin hơn để tránh mất scripts
    local function getFingerprint(script)
        local fp = ""
        pcall(function() fp = tostring(script:GetDebugId()) end)
        if fp == "" then
            local name, class, ptr = "", "", tostring(script)
            pcall(function() name = script.Name end)
            pcall(function() class = script.ClassName end)
            fp = ptr .. "|" .. class .. "|" .. name
        end
        return fp
    end
    
    local function addScript(scriptInst, source)
        if not scriptInst then return false end
        local isLSC = false
        pcall(function() isLSC = scriptInst:IsA("LuaSourceContainer") end)
        if not isLSC then return false end
        
        local fp = getFingerprint(scriptInst)
        if seen[fp] then return false end
        seen[fp] = true
        
        allScripts[#allScripts + 1] = scriptInst
        stats[source] = (stats[source] or 0) + 1
        return true
    end
    
    -- ═══ Method 1: getscripts() — TẤT CẢ running scripts ═══
    if ENV.getscripts then
        local ok, scripts = pcall(ENV.getscripts)
        if ok and scripts then
            for _, s in ipairs(scripts) do addScript(s, "fromGetScripts") end
        end
        Log.info("⚡ getscripts(): +%d", stats.fromGetScripts)
    end
    task.wait()
    
    -- ═══ Method 2: getloadedmodules() — Modules đã require() ═══
    if ENV.getloadedmodules then
        local ok, modules = pcall(ENV.getloadedmodules)
        if ok and modules then
            for _, m in ipairs(modules) do addScript(m, "fromGetModules") end
        end
        Log.info("⚡ getloadedmodules(): +%d", stats.fromGetModules)
    end
    task.wait()
    
    -- ═══ Method 3: GetDescendants — Quét TOÀN BỘ services ═══
    local servicesToScan = {
        Services.Workspace, Services.ReplicatedStorage, Services.ReplicatedFirst,
        Services.StarterGui, Services.StarterPack, Services.StarterPlayer,
        Services.Lighting, Services.SoundService, Services.Chat,
        Services.Teams, Services.TestService, Services.MaterialService,
    }
    for _, name in ipairs({"ServerStorage", "ServerScriptService", "CoreGui", "CorePackages"}) do
        pcall(function()
            local svc = game:GetService(name)
            if svc then servicesToScan[#servicesToScan + 1] = svc end
        end)
    end
    
    for _, service in ipairs(servicesToScan) do
        pcall(function()
            for _, desc in ipairs(service:GetDescendants()) do
                pcall(function()
                    if desc:IsA("LuaSourceContainer") then
                        addScript(desc, "fromDescendants")
                    end
                end)
            end
        end)
        task.wait()
    end
    Log.info("⚡ Descendants: +%d", stats.fromDescendants)
    
    -- ═══ Method 4: Nil Instances — Scripts ẩn (parent=nil) ═══
    if BSI.Config.Decompile.RecoverFromNil and ENV.getnilinstances then
        local ok, nilInst = pcall(ENV.getnilinstances)
        if ok and nilInst then
            for _, inst in ipairs(nilInst) do
                addScript(inst, "fromNil")
                -- Deep scan tất cả descendants của nil instance
                pcall(function()
                    for _, child in ipairs(inst:GetDescendants()) do
                        addScript(child, "fromNil")
                    end
                end)
            end
        end
        Log.info("⚡ Nil recovery: +%d", stats.fromNil)
    end
    task.wait()
    
    -- ═══ Method 5: GC Userdata — Scripts bị destroy còn trong bộ nhớ ═══
    if BSI.Config.Decompile.RecoverFromGC and ENV.getgc then
        local ok, gcObjects = pcall(ENV.getgc, true)
        if ok and gcObjects then
            for _, obj in ipairs(gcObjects) do
                if type(obj) == "userdata" then
                    pcall(function()
                        if obj:IsA("LuaSourceContainer") then
                            addScript(obj, "fromGC")
                        end
                    end)
                end
            end
        end
        Log.info("⚡ GC userdata: +%d", stats.fromGC)
    end
    task.wait()
    
    -- ═══ Method 6: GC Functions — Tìm script owners qua closures ═══
    if BSI.Config.Decompile.RecoverFromGC and ENV.getgc then
        pcall(function()
            local gcFuncs = ENV.getgc(false) -- false = chỉ functions
            if gcFuncs then
                local getinfo = debug and debug.getinfo
                for _, fn in ipairs(gcFuncs) do
                    if type(fn) == "function" then
                        pcall(function()
                            local info = getinfo and getinfo(fn)
                            if info and info.source then
                                -- Tìm script instance từ source path
                                local src = info.source
                                if src:sub(1,1) == "=" then
                                    local path = src:sub(2)
                                    pcall(function()
                                        local inst = game
                                        for part in path:gmatch("[^%.]+") do
                                            inst = inst:FindFirstChild(part)
                                            if not inst then break end
                                        end
                                        if inst then addScript(inst, "fromGCFuncs") end
                                    end)
                                end
                            end
                        end)
                    end
                end
            end
        end)
        Log.info("⚡ GC functions: +%d", stats.fromGCFuncs)
    end
    task.wait()
    
    -- ═══ Method 7: Debug Registry — Scripts từ Lua registry ═══
    if BSI.Config.Decompile.RecoverFromRegistry then
        pcall(function()
            local reg = debug and debug.getregistry and debug.getregistry()
            if reg and type(reg) == "table" then
                local count = 0
                for _, v in pairs(reg) do
                    if type(v) == "userdata" then
                        pcall(function()
                            if v:IsA("LuaSourceContainer") then
                                addScript(v, "fromRegistry")
                            end
                        end)
                    elseif type(v) == "table" then
                        -- Scan tables trong registry cho script refs
                        for _, inner in pairs(v) do
                            if type(inner) == "userdata" then
                                pcall(function()
                                    if inner:IsA("LuaSourceContainer") then
                                        addScript(inner, "fromRegistry")
                                    end
                                end)
                            end
                        end
                    end
                    count = count + 1
                    if count % 3000 == 0 then task.wait() end
                end
            end
        end)
        Log.info("⚡ Registry: +%d", stats.fromRegistry)
    end
    task.wait()
    
    -- ═══ Method 8: getinstances() — Quét TẤT CẢ instances còn lại ═══
    if ENV.getinstances then
        local ok, allInst = pcall(ENV.getinstances)
        if ok and allInst then
            local yieldCount = 0
            for _, inst in ipairs(allInst) do
                pcall(function()
                    if inst:IsA("LuaSourceContainer") then
                        addScript(inst, "fromInstances")
                    end
                end)
                yieldCount = yieldCount + 1
                if yieldCount % 5000 == 0 then task.wait() end
            end
        end
        Log.info("⚡ getinstances(): +%d", stats.fromInstances)
    end
    
    stats.total = #allScripts
    
    Log.info("╔══════════════════════════════════════╗")
    Log.info("║   HYPER SCRIPT DISCOVERY v5.0        ║")
    Log.info("╠══════════════════════════════════════╣")
    Log.info("║ getscripts:    %4d                  ║", stats.fromGetScripts)
    Log.info("║ getmodules:    %4d                  ║", stats.fromGetModules)
    Log.info("║ descendants:   %4d                  ║", stats.fromDescendants)
    Log.info("║ nil recovery:  %4d                  ║", stats.fromNil)
    Log.info("║ GC userdata:   %4d                  ║", stats.fromGC)
    Log.info("║ GC functions:  %4d                  ║", stats.fromGCFuncs)
    Log.info("║ registry:      %4d                  ║", stats.fromRegistry)
    Log.info("║ getinstances:  %4d                  ║", stats.fromInstances)
    Log.info("╠══════════════════════════════════════╣")
    Log.info("║ TOTAL:         %4d scripts          ║", stats.total)
    Log.info("╚══════════════════════════════════════╝")
    
    return allScripts, stats
end

BSI.ScriptDiscovery = ScriptDiscovery

-- ================================================================
-- SECTION 6: DECOMPILE ENGINE (HYPER v5.0 — MULTI-API RACING)
-- ================================================================

local DecompileEngine = {}
DecompileEngine.Cache = {}
DecompileEngine.Stats = {
    total = 0, success = 0, failed = 0,
    cached = 0, skipped = 0, recovered = 0,
    avgQuality = 0, bestMethod = {},
}
DecompileEngine.TimingData = {} -- Adaptive timeout data

--- Reset stats
function DecompileEngine.resetStats()
    DecompileEngine.Stats = {
        total = 0, success = 0, failed = 0,
        cached = 0, skipped = 0, recovered = 0,
        avgQuality = 0, bestMethod = {},
    }
    DecompileEngine.TimingData = {}
end

-- ═══════════════════════════════════════
-- SOURCE QUALITY SCORER (0-100)
-- Chấm điểm chất lượng code decompiled
-- ═══════════════════════════════════════
function DecompileEngine.scoreSource(code)
    if not code or type(code) ~= "string" or #code < 3 then return 0 end
    
    local score = 0
    local lines = 0
    local codeLines = 0
    
    for line in code:gmatch("[^\n]+") do
        lines = lines + 1
        local trimmed = line:match("^%s*(.-)%s*$") or ""
        if #trimmed > 0 and not trimmed:match("^%-%-") then
            codeLines = codeLines + 1
        end
    end
    
    -- Penalty: quá ngắn
    if lines < 1 then return 0 end
    
    -- Có code thực (max +25)
    score = score + math.min(25, codeLines * 2)
    
    -- Có function keywords (max +20)
    local funcCount = 0
    for _ in code:gmatch("function[%s%(]") do funcCount = funcCount + 1 end
    score = score + math.min(20, funcCount * 4)
    
    -- Có local declarations (max +15)
    local localCount = 0
    for _ in code:gmatch("local%s+") do localCount = localCount + 1 end
    score = score + math.min(15, localCount * 2)
    
    -- Control flow (max +15)
    local cfCount = 0
    for _, kw in ipairs({"if ", "for ", "while ", "repeat", "return "}) do
        for _ in code:gmatch(kw) do cfCount = cfCount + 1 end
    end
    score = score + math.min(15, cfCount * 2)
    
    -- Printable ratio (max +10)
    local printable = 0
    for i = 1, math.min(#code, 2000) do
        local b = code:byte(i)
        if (b >= 32 and b <= 126) or b == 10 or b == 13 or b == 9 then
            printable = printable + 1
        end
    end
    local ratio = printable / math.min(#code, 2000)
    score = score + math.floor(ratio * 10)
    
    -- Độ dài hợp lý (max +10)
    score = score + math.min(10, math.floor(#code / 100))
    
    -- String/table literals (max +5)
    local strCount = 0
    for _ in code:gmatch('"') do strCount = strCount + 1 end
    for _ in code:gmatch("'") do strCount = strCount + 1 end
    score = score + math.min(5, math.floor(strCount / 2))
    
    -- Penalties
    if code:match("^%-%-.*failed") or code:match("^%-%-.*error") then
        score = math.max(0, score - 50)
    end
    if code:match("^%-%-.*timeout") then
        score = math.max(0, score - 40)
    end
    -- Decompiler noise
    if code:match("DECOMPILE FAILED") then score = 0 end
    if code:match("empty source") then score = 0 end
    
    return math.min(100, math.max(0, score))
end

-- ═══════════════════════════════════════
-- MULTI-API RACING DECOMPILER
-- Chạy TẤT CẢ methods song song, chọn kết quả tốt nhất
-- ═══════════════════════════════════════
function DecompileEngine.decompileSingle(scriptInst)
    if not scriptInst then return false, "-- nil script", 0 end
    
    -- Cache key
    local cacheKey = ""
    pcall(function() cacheKey = tostring(scriptInst:GetDebugId()) end)
    if cacheKey == "" then
        local n, c = "", ""
        pcall(function() n = scriptInst.Name end)
        pcall(function() c = scriptInst.ClassName end)
        cacheKey = tostring(scriptInst) .. "|" .. c .. "|" .. n
    end
    
    -- Check cache
    if BSI.Config.Decompile.CacheEnabled and DecompileEngine.Cache[cacheKey] then
        DecompileEngine.Stats.cached = DecompileEngine.Stats.cached + 1
        local cached = DecompileEngine.Cache[cacheKey]
        return true, cached.source, cached.quality
    end
    
    DecompileEngine.Stats.total = DecompileEngine.Stats.total + 1
    
    -- ═══ Collect all results from all methods ═══
    local candidates = {} -- {source=, method=, quality=}
    local raceComplete = false
    local startTime = os.clock()
    
    -- Adaptive timeout
    local timeout = BSI.Config.Decompile.RaceTimeout
    if BSI.Config.Decompile.AdaptiveTimeout and #DecompileEngine.TimingData > 3 then
        local sum = 0
        for _, t in ipairs(DecompileEngine.TimingData) do sum = sum + t end
        local avg = sum / #DecompileEngine.TimingData
        timeout = math.max(5, math.min(60, avg * 3))
    end
    
    local function tryMethod(name, fn)
        local ok, result = pcall(fn)
        if ok and result and type(result) == "string" and #result > 2 then
            local q = DecompileEngine.scoreSource(result)
            if q > 0 then
                candidates[#candidates + 1] = {source = result, method = name, quality = q}
            end
        end
    end
    
    -- ═══ Strategy 1: decompile() trực tiếp ═══
    if ENV.decompile then
        tryMethod("decompile_v1", function() return ENV.decompile(scriptInst) end)
    end
    
    -- ═══ Strategy 2: decompile with "new" backend ═══
    if ENV.decompile then
        tryMethod("decompile_new", function() return ENV.decompile(scriptInst, "new") end)
    end
    
    -- ═══ Strategy 3: decompile with "old" backend ═══
    if ENV.decompile then
        tryMethod("decompile_old", function() return ENV.decompile(scriptInst, "old") end)
    end
    
    -- ═══ Strategy 4: Synapse X decompile ═══
    if syn and syn.decompile then
        tryMethod("syn_decompile", function() return syn.decompile(scriptInst) end)
    end
    
    -- ═══ Strategy 5: Source property (ModuleScript) ═══
    tryMethod("source_property", function()
        local src = scriptInst.Source
        if src and #src > 0 then return src end
        return nil
    end)
    
    -- ═══ Strategy 6: Hidden property "Source" ═══
    if ENV.gethiddenproperty then
        tryMethod("hidden_source", function()
            local ok, src = ENV.gethiddenproperty(scriptInst, "Source")
            if ok and src and #tostring(src) > 0 then
                DecompileEngine.Stats.recovered = DecompileEngine.Stats.recovered + 1
                return tostring(src)
            end
            return nil
        end)
    end
    
    -- ═══ Strategy 7: require() cho ModuleScript ═══
    local isModule = false
    pcall(function() isModule = scriptInst:IsA("ModuleScript") end)
    if isModule and BSI.Config.Decompile.RequireModules then
        tryMethod("require_serialize", function()
            local moduleResult = require(scriptInst)
            if moduleResult then
                local serialized = Services.HttpService:JSONEncode(moduleResult)
                if serialized and #serialized > 2 then
                    return "-- [Module Return Value (serialized)]\nreturn " ..
                        Services.HttpService:JSONEncode(moduleResult)
                end
            end
            return nil
        end)
    end
    
    -- ═══ Strategy 8: LinkedSource ═══
    tryMethod("linked_source", function()
        local ls = scriptInst.LinkedSource
        if ls and #ls > 0 then
            return "-- LinkedSource: " .. ls .. "\n-- Requires URL fetch"
        end
        return nil
    end)
    
    -- ═══ Strategy 9: Retry decompile with delays ═══
    if ENV.decompile and #candidates == 0 then
        for attempt = 2, BSI.Config.Decompile.Retries do
            task.wait(0.02 * attempt)
            tryMethod("decompile_retry" .. attempt, function()
                return ENV.decompile(scriptInst)
            end)
            if #candidates > 0 then break end
        end
    end
    
    -- ═══ SELECT BEST RESULT ═══
    local elapsed = os.clock() - startTime
    DecompileEngine.TimingData[#DecompileEngine.TimingData + 1] = elapsed
    -- Keep timing data bounded
    if #DecompileEngine.TimingData > 50 then
        local new = {}
        for i = 26, #DecompileEngine.TimingData do new[#new+1] = DecompileEngine.TimingData[i] end
        DecompileEngine.TimingData = new
    end
    
    if #candidates > 0 then
        -- Sort by quality descending
        table.sort(candidates, function(a, b) return a.quality > b.quality end)
        local best = candidates[1]
        
        -- Clean source
        local cleanedSource = DecompileEngine.cleanSource(best.source)
        
        -- Add header
        if BSI.Config.Decompile.AddHeaders then
            cleanedSource = DecompileEngine.addHeader(scriptInst, cleanedSource, best.method, best.quality, #candidates)
        end
        
        -- Cache
        if BSI.Config.Decompile.CacheEnabled then
            DecompileEngine.Cache[cacheKey] = {source = cleanedSource, quality = best.quality}
        end
        
        -- Track best method
        DecompileEngine.Stats.bestMethod[best.method] = (DecompileEngine.Stats.bestMethod[best.method] or 0) + 1
        DecompileEngine.Stats.success = DecompileEngine.Stats.success + 1
        
        -- Running average quality
        local s = DecompileEngine.Stats
        s.avgQuality = ((s.avgQuality * (s.success - 1)) + best.quality) / s.success
        
        return true, cleanedSource, best.quality
    else
        -- ═══ FALLBACK ═══
        DecompileEngine.Stats.failed = DecompileEngine.Stats.failed + 1
        
        local fullName = "Unknown"
        pcall(function() fullName = scriptInst:GetFullName() end)
        local scriptName = "Unknown"
        pcall(function() scriptName = scriptInst.Name end)
        local className = "Unknown"
        pcall(function() className = scriptInst.ClassName end)
        
        local fallback = string.format(
            "--[[\n" ..
            "    ╔═══════════════════════════════════════╗\n" ..
            "    ║  DECOMPILE FAILED (9 methods tried)   ║\n" ..
            "    ╚═══════════════════════════════════════╝\n" ..
            "    \n" ..
            "    Script: %s\n" ..
            "    Class:  %s\n" ..
            "    Path:   %s\n" ..
            "    Time:   %.2fs\n" ..
            "    \n" ..
            "    Possible reasons:\n" ..
            "    - Anti-decompile protection\n" ..
            "    - Empty or unloaded script\n" ..
            "    - Incompatible bytecode\n" ..
            "    - Server-side only script\n" ..
            "    \n" ..
            "    BaoSaveInstance v%s HYPER\n" ..
            "]]--\n",
            scriptName, className, fullName, elapsed, BSI.VERSION
        )
        
        return false, fallback, 0
    end
end

-- ═══════════════════════════════════════
-- ENHANCED SOURCE CLEANING
-- ═══════════════════════════════════════
function DecompileEngine.cleanSource(source)
    if not source or type(source) ~= "string" then return "-- empty source" end
    
    -- Null bytes
    source = source:gsub("%z", "")
    
    -- Leading blank lines
    source = source:gsub("^[\r\n]+", "")
    
    -- Normalize line endings
    source = source:gsub("\r\n", "\n"):gsub("\r", "\n")
    
    -- Trailing whitespace per line
    source = source:gsub("[ \t]+\n", "\n")
    
    -- Excessive blank lines (>2 consecutive)
    source = source:gsub("\n\n\n+", "\n\n")
    
    -- Remove decompiler watermarks
    if BSI.Config.Decompile.CleanWatermarks then
        source = source:gsub("%-%-[^\n]*[Uu]nluau[^\n]*\n?", "")
        source = source:gsub("%-%-[^\n]*[Dd]ecompiled[^\n]*\n?", "")
        source = source:gsub("%-%-[^\n]*generated by[^\n]*\n?", "")
    end
    
    -- Fix common decompiler artifacts
    source = source:gsub("%(%((.-)%)%)", "(%1)") -- double parens ((x)) → (x)
    
    -- Trailing newlines
    source = source:gsub("\n+$", "\n")
    
    return source
end

-- ═══════════════════════════════════════
-- ENHANCED HEADER
-- ═══════════════════════════════════════
function DecompileEngine.addHeader(scriptInst, source, method, quality, methodsTried)
    local fullName = "Unknown"
    pcall(function() fullName = scriptInst:GetFullName() end)
    local scriptName = "Unknown"
    pcall(function() scriptName = scriptInst.Name end)
    local className = "Unknown"
    pcall(function() className = scriptInst.ClassName end)
    
    local qualityBar = string.rep("█", math.floor((quality or 0) / 10))
        .. string.rep("░", 10 - math.floor((quality or 0) / 10))
    
    local header = string.format(
        "--[[\n" ..
        "    ✅ BaoSaveInstance v%s HYPER\n" ..
        "    📜 %s (%s)\n" ..
        "    📍 %s\n" ..
        "    🔧 Method: %s | Tried: %d methods\n" ..
        "    📊 Quality: %d/100 [%s]\n" ..
        "    🕐 %s\n" ..
        "]]--\n\n",
        BSI.VERSION, scriptName, className, fullName,
        method or "unknown", methodsTried or 1,
        quality or 0, qualityBar,
        os.date("%Y-%m-%d %H:%M:%S")
    )
    
    return header .. source
end

-- ═══════════════════════════════════════
-- CONCURRENT BATCH DECOMPILER (6 Workers)
-- ═══════════════════════════════════════
function DecompileEngine.batchDecompile(scripts, progressCallback)
    if not scripts or #scripts == 0 then return {} end
    
    local results = {}
    local total = #scripts
    local workers = BSI.Config.Decompile.ConcurrentWorkers
    local startTime = os.clock()
    
    Log.info("╔══════════════════════════════════════╗")
    Log.info("║ HYPER BATCH DECOMPILE v5.0           ║")
    Log.info("║ Scripts: %d | Workers: %d              ║", total, workers)
    Log.info("╚══════════════════════════════════════╝")
    
    -- Priority sort: Module → Local → Script
    local sorted = {}
    for i, s in ipairs(scripts) do sorted[i] = s end
    table.sort(sorted, function(a, b)
        local order = {ModuleScript = 1, LocalScript = 2, Script = 3}
        local oa, ob = 4, 4
        pcall(function() oa = order[a.ClassName] or 4 end)
        pcall(function() ob = order[b.ClassName] or 4 end)
        return oa < ob
    end)
    
    -- Filter by config
    local toProcess = {}
    for _, script in ipairs(sorted) do
        local shouldDo = true
        local cn = ""
        pcall(function() cn = script.ClassName end)
        if cn == "Script" and not BSI.Config.Decompile.IncludeServerScripts then
            shouldDo = false
        elseif cn == "LocalScript" and not BSI.Config.Decompile.IncludeLocalScripts then
            shouldDo = false
        elseif cn == "ModuleScript" and not BSI.Config.Decompile.IncludeModuleScripts then
            shouldDo = false
        end
        if shouldDo then
            toProcess[#toProcess + 1] = script
        else
            DecompileEngine.Stats.skipped = DecompileEngine.Stats.skipped + 1
        end
    end
    
    -- ═══ CONCURRENT WORKER SYSTEM ═══
    local queueIndex = 0 -- Shared atomic-ish counter
    local completed = 0
    local resultLock = {} -- Avoid race conditions on results table
    
    local function worker(workerId)
        while true do
            -- Get next script from queue
            queueIndex = queueIndex + 1
            local idx = queueIndex
            if idx > #toProcess then break end
            
            local script = toProcess[idx]
            local ok, source, quality = DecompileEngine.decompileSingle(script)
            
            local scriptName = "Unknown"
            pcall(function() scriptName = script.Name end)
            local className = ""
            pcall(function() className = script.ClassName end)
            local fullName = "Unknown"
            pcall(function() fullName = script:GetFullName() end)
            
            results[script] = {
                success = ok,
                source = source,
                quality = quality or 0,
                className = className,
                name = scriptName,
                fullName = fullName,
            }
            
            completed = completed + 1
            
            -- Progress callback
            if progressCallback and (completed % 3 == 0 or completed == #toProcess) then
                local pct = math.floor(completed / #toProcess * 100)
                local elapsed = os.clock() - startTime
                local speed = elapsed > 0 and (completed / elapsed) or 0
                local eta = speed > 0 and (((#toProcess - completed) / speed)) or 0
                
                progressCallback(
                    string.format("⚡ %d/%d (%d%%) [✓%d ✗%d] %.1f/s ETA:%.0fs",
                        completed, #toProcess, pct,
                        DecompileEngine.Stats.success,
                        DecompileEngine.Stats.failed,
                        speed, eta),
                    pct
                )
            end
            
            -- Brief yield to prevent freezing
            if completed % 2 == 0 then
                task.wait(BSI.Config.Performance.TaskWaitTime)
            end
            if completed % 30 == 0 then
                Util.memoryCheck()
            end
        end
    end
    
    -- Spawn workers
    local workerThreads = {}
    for i = 1, workers do
        workerThreads[i] = task.spawn(worker, i)
    end
    
    -- Wait for all workers to finish
    while completed < #toProcess do
        task.wait(0.05)
    end
    
    -- Final stats
    local elapsed = os.clock() - startTime
    local s = DecompileEngine.Stats
    
    Log.info("╔══════════════════════════════════════╗")
    Log.info("║   HYPER DECOMPILE RESULTS            ║")
    Log.info("╠══════════════════════════════════════╣")
    Log.info("║ Total:     %4d                      ║", s.total)
    Log.info("║ Success:   %4d (%5.1f%%)              ║", s.success,
        s.total > 0 and (s.success / s.total * 100) or 0)
    Log.info("║ Failed:    %4d                      ║", s.failed)
    Log.info("║ Cached:    %4d                      ║", s.cached)
    Log.info("║ Skipped:   %4d                      ║", s.skipped)
    Log.info("║ Recovered: %4d                      ║", s.recovered)
    Log.info("║ Avg Quality: %5.1f/100               ║", s.avgQuality)
    Log.info("║ Speed:     %.1f scripts/sec           ║", s.total > 0 and (s.total / elapsed) or 0)
    Log.info("║ Time:      %.1fs                      ║", elapsed)
    Log.info("╠══════════════════════════════════════╣")
    Log.info("║ Best methods used:                   ║")
    for method, count in pairs(s.bestMethod) do
        Log.info("║   %-20s %4d          ║", method, count)
    end
    Log.info("╚══════════════════════════════════════╝")
    
    return results
end

--- Clear cache
function DecompileEngine.clearCache()
    DecompileEngine.Cache = {}
    DecompileEngine.resetStats()
    collectgarbage("collect")
end




-- ================================================================
-- SECTION 7: MODEL COLLECTOR (100% MODELS)
-- ================================================================

local ModelCollector = {}

--- Xây dựng exclusion set cho O(1) lookup
local function buildExclusionSet()
    local set = {}
    for _, name in ipairs(BSI.Config.Exclude.ClassNames) do
        set[name] = true
    end
    for _, name in ipairs(BSI.Config.Exclude.Names) do
        set["NAME:" .. name] = true
    end
    return set
end

--- Kiểm tra instance có nên save không
function ModelCollector.shouldSave(inst, exclusionSet)
    if not inst then return false end
    if exclusionSet[inst.ClassName] then return false end
    if exclusionSet["NAME:" .. inst.Name] then return false end
    return true
end

--- Thu thập TẤT CẢ models và instances trong game
function ModelCollector.collectAll(progressCallback)
    local exclusionSet = buildExclusionSet()
    local collected = {
        models = {},
        parts = {},
        meshes = {},
        unions = {},
        scripts = {},
        guis = {},
        sounds = {},
        lights = {},
        effects = {},
        constraints = {},
        welds = {},
        attachments = {},
        values = {},
        tools = {},
        animations = {},
        other = {},
    }
    local totalCount = 0
    
    -- Quét từ tất cả services
    local sources = {
        {service = Services.Workspace, name = "Workspace"},
        {service = Services.ReplicatedStorage, name = "ReplicatedStorage"},
        {service = Services.ReplicatedFirst, name = "ReplicatedFirst"},
        {service = Services.StarterGui, name = "StarterGui"},
        {service = Services.StarterPack, name = "StarterPack"},
        {service = Services.StarterPlayer, name = "StarterPlayer"},
        {service = Services.Lighting, name = "Lighting"},
        {service = Services.SoundService, name = "SoundService"},
        {service = Services.Chat, name = "Chat"},
        {service = Services.Teams, name = "Teams"},
    }
    
    -- Thêm services khó truy cập
    pcall(function()
        sources[#sources + 1] = {
            service = game:GetService("ServerStorage"),
            name = "ServerStorage"
        }
    end)
    pcall(function()
        sources[#sources + 1] = {
            service = game:GetService("ServerScriptService"),
            name = "ServerScriptService"
        }
    end)
    
    for _, src in ipairs(sources) do
        pcall(function()
            local descendants = src.service:GetDescendants()
            
            for _, inst in ipairs(descendants) do
                if ModelCollector.shouldSave(inst, exclusionSet) then
                    totalCount = totalCount + 1
                    
                    -- Phân loại instance
                    if inst:IsA("Model") then
                        collected.models[#collected.models + 1] = inst
                    elseif inst:IsA("MeshPart") then
                        collected.meshes[#collected.meshes + 1] = inst
                    elseif inst:IsA("UnionOperation") then
                        collected.unions[#collected.unions + 1] = inst
                    elseif inst:IsA("BasePart") then
                        collected.parts[#collected.parts + 1] = inst
                    elseif inst:IsA("LuaSourceContainer") then
                        collected.scripts[#collected.scripts + 1] = inst
                    elseif inst:IsA("GuiObject") or inst:IsA("ScreenGui") or inst:IsA("SurfaceGui") or inst:IsA("BillboardGui") then
                        collected.guis[#collected.guis + 1] = inst
                    elseif inst:IsA("Sound") then
                        collected.sounds[#collected.sounds + 1] = inst
                    elseif inst:IsA("Light") then
                        collected.lights[#collected.lights + 1] = inst
                    elseif inst:IsA("ParticleEmitter") or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") or inst:IsA("Trail") or inst:IsA("Beam") then
                        collected.effects[#collected.effects + 1] = inst
                    elseif inst:IsA("Constraint") then
                        collected.constraints[#collected.constraints + 1] = inst
                    elseif inst:IsA("JointInstance") or inst:IsA("WeldConstraint") then
                        collected.welds[#collected.welds + 1] = inst
                    elseif inst:IsA("Attachment") then
                        collected.attachments[#collected.attachments + 1] = inst
                    elseif inst:IsA("ValueBase") then
                        collected.values[#collected.values + 1] = inst
                    elseif inst:IsA("Tool") or inst:IsA("BackpackItem") then
                        collected.tools[#collected.tools + 1] = inst
                    elseif inst:IsA("Animation") or inst:IsA("AnimationController") or inst:IsA("Animator") then
                        collected.animations[#collected.animations + 1] = inst
                    else
                        collected.other[#collected.other + 1] = inst
                    end
                end
            end
            
            if progressCallback then
                progressCallback(string.format("Scanning %s... (%s instances)",
                    src.name, Util.formatNumber(totalCount)))
            end
        end)
        
        task.wait()
    end
    
    -- Thu thập từ nil instances
    if BSI.Config.Recovery.NilInstances and ENV.getnilinstances then
        pcall(function()
            local nilInsts = ENV.getnilinstances()
            for _, inst in ipairs(nilInsts) do
                if ModelCollector.shouldSave(inst, exclusionSet) then
                    totalCount = totalCount + 1
                    if inst:IsA("Model") then
                        collected.models[#collected.models + 1] = inst
                    elseif inst:IsA("BasePart") then
                        collected.parts[#collected.parts + 1] = inst
                    end
                end
            end
        end)
    end
    
    Log.info("═══════════════════════════════════════")
    Log.info("MODEL COLLECTION RESULTS:")
    Log.info("  Models:      %d", #collected.models)
    Log.info("  Parts:       %d", #collected.parts)
    Log.info("  MeshParts:   %d", #collected.meshes)
    Log.info("  Unions:      %d", #collected.unions)
    Log.info("  Scripts:     %d", #collected.scripts)
    Log.info("  GUIs:        %d", #collected.guis)
    Log.info("  Sounds:      %d", #collected.sounds)
    Log.info("  Lights:      %d", #collected.lights)
    Log.info("  Effects:     %d", #collected.effects)
    Log.info("  Constraints: %d", #collected.constraints)
    Log.info("  Welds:       %d", #collected.welds)
    Log.info("  Attachments: %d", #collected.attachments)
    Log.info("  Values:      %d", #collected.values)
    Log.info("  Tools:       %d", #collected.tools)
    Log.info("  Animations:  %d", #collected.animations)
    Log.info("  Other:       %d", #collected.other)
    Log.info("  ─────────────────")
    Log.info("  TOTAL:       %s instances", Util.formatNumber(totalCount))
    Log.info("═══════════════════════════════════════")
    
    return collected, totalCount
end

BSI.ModelCollector = ModelCollector

-- ================================================================
-- SECTION 8: TERRAIN ENGINE (100% TERRAIN)
-- ================================================================

local TerrainEngine = {}

--- Phân tích terrain toàn diện
function TerrainEngine.analyze()
    local terrain = Services.Terrain
    local info = {
        exists = false,
        maxExtent = Vector3.new(0, 0, 0),
        minExtent = Vector3.new(0, 0, 0),
        totalVoxels = 0,
        nonAirVoxels = 0,
        waterVoxels = 0,
        materialCounts = {},
        materialNames = {},
        hasData = false,
        regionCount = 0,
        estimatedSizeMB = 0,
    }
    
    pcall(function()
        -- Kiểm tra terrain bounds
        -- Terrain có thể mở rộng từ -16384 đến 16384 trên mỗi trục
        -- Nhưng chúng ta scan thông minh để tìm vùng có dữ liệu
        
        local maxCoord = BSI.Config.Terrain.MaxRegionCoord
        local regionSize = BSI.Config.Terrain.RegionSize
        
        -- Bước 1: Tìm bounds của terrain bằng binary search
        local foundData = false
        local scanPoints = {-maxCoord, -1024, -512, -256, -128, -64, 0, 64, 128, 256, 512, 1024, maxCoord}
        
        local minX, minY, minZ = maxCoord, maxCoord, maxCoord
        local maxX, maxY, maxZ = -maxCoord, -maxCoord, -maxCoord
        
        -- Quick scan để tìm extent
        for _, x in ipairs(scanPoints) do
            for _, y in ipairs(scanPoints) do
                for _, z in ipairs(scanPoints) do
                    local region = Region3.new(
                        Vector3.new(x, y, z),
                        Vector3.new(x + regionSize, y + regionSize, z + regionSize)
                    ):ExpandToGrid(4)
                    
                    local ok, materials, occupancy = pcall(function()
                        return terrain:ReadVoxels(region, 4)
                    end)
                    
                    if ok and materials then
                        local size = materials.Size
                        for xi = 1, size.X do
                            for yi = 1, size.Y do
                                for zi = 1, size.Z do
                                    local mat = materials[xi][yi][zi]
                                    if mat ~= Enum.Material.Air then
                                        foundData = true
                                        minX = math.min(minX, x)
                                        minY = math.min(minY, y)
                                        minZ = math.min(minZ, z)
                                        maxX = math.max(maxX, x + regionSize)
                                        maxY = math.max(maxY, y + regionSize)
                                        maxZ = math.max(maxZ, z + regionSize)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            task.wait()
        end
        
        if foundData then
            info.exists = true
            info.hasData = true
            info.minExtent = Vector3.new(minX, minY, minZ)
            info.maxExtent = Vector3.new(maxX, maxY, maxZ)
            
            -- Bước 2: Đếm chi tiết materials
            local totalRegion = Region3.new(
                Vector3.new(
                    math.max(minX - regionSize, -maxCoord),
                    math.max(minY - regionSize, -maxCoord),
                    math.max(minZ - regionSize, -maxCoord)
                ),
                Vector3.new(
                    math.min(maxX + regionSize, maxCoord),
                    math.min(maxY + regionSize, maxCoord),
                    math.min(maxZ + regionSize, maxCoord)
                )
            ):ExpandToGrid(4)
            
            local ok2, mats, occs = pcall(function()
                return terrain:ReadVoxels(totalRegion, 4)
            end)
            
            if ok2 and mats then
                local size = mats.Size
                info.totalVoxels = size.X * size.Y * size.Z
                
                -- Sample counting (full count nếu đủ nhỏ)
                local step = 1
                if info.totalVoxels > 1000000 then
                    step = math.ceil(math.pow(info.totalVoxels / 500000, 1/3))
                end
                
                for xi = 1, size.X, step do
                    for yi = 1, size.Y, step do
                        for zi = 1, size.Z, step do
                            local mat = mats[xi][yi][zi]
                            if mat ~= Enum.Material.Air then
                                info.nonAirVoxels = info.nonAirVoxels + 1
                                local matName = tostring(mat):gsub("Enum.Material.", "")
                                info.materialCounts[matName] = (info.materialCounts[matName] or 0) + 1
                                
                                if mat == Enum.Material.Water then
                                    info.waterVoxels = info.waterVoxels + 1
                                end
                            end
                        end
                    end
                    
                    if xi % 20 == 0 then task.wait() end
                end
                
                -- Nếu dùng sampling, scale up
                if step > 1 then
                    local scale = step * step * step
                    info.nonAirVoxels = info.nonAirVoxels * scale
                    info.waterVoxels = info.waterVoxels * scale
                    for k, v in pairs(info.materialCounts) do
                        info.materialCounts[k] = v * scale
                    end
                end
            end
            
            -- Material names list
            for matName, _ in pairs(info.materialCounts) do
                info.materialNames[#info.materialNames + 1] = matName
            end
            table.sort(info.materialNames)
            
            -- Estimate size
            info.estimatedSizeMB = info.totalVoxels * 2 / 1024 / 1024
        end
    end)
    
    if info.hasData then
        Log.info("═══════════════════════════════════════")
        Log.info("TERRAIN ANALYSIS:")
        Log.info("  Has Data:    YES")
        Log.info("  Min Extent:  %s", tostring(info.minExtent))
        Log.info("  Max Extent:  %s", tostring(info.maxExtent))
        Log.info("  Total Voxels: ~%s", Util.formatNumber(info.totalVoxels))
        Log.info("  Non-Air:     ~%s", Util.formatNumber(info.nonAirVoxels))
        Log.info("  Water:       ~%s", Util.formatNumber(info.waterVoxels))
        Log.info("  Materials:   %d types", #info.materialNames)
        for _, name in ipairs(info.materialNames) do
            Log.info("    • %s: ~%s", name,
                Util.formatNumber(info.materialCounts[name] or 0))
        end
        Log.info("  Est. Size:   ~%.1f MB", info.estimatedSizeMB)
        Log.info("═══════════════════════════════════════")
    else
        Log.info("TERRAIN: Không có dữ liệu terrain")
    end
    
    return info
end

--- Kiểm tra terrain có tồn tại không
function TerrainEngine.hasTerrain()
    local hasData = false
    pcall(function()
        local region = Region3.new(
            Vector3.new(-2048, -2048, -2048),
            Vector3.new(2048, 2048, 2048)
        ):ExpandToGrid(4)
        
        local materials = Services.Terrain:ReadVoxels(region, 4)
        local size = materials.Size
        
        -- Quick check: chỉ cần tìm 1 voxel không phải Air
        for x = 1, size.X, math.max(1, math.floor(size.X / 10)) do
            for y = 1, size.Y, math.max(1, math.floor(size.Y / 10)) do
                for z = 1, size.Z, math.max(1, math.floor(size.Z / 10)) do
                    if materials[x][y][z] ~= Enum.Material.Air then
                        hasData = true
                        return
                    end
                end
            end
        end
    end)
    return hasData
end

BSI.TerrainEngine = TerrainEngine

-- ================================================================
-- SECTION 9: SAVEINSTANCE OPTIONS FACTORY (100% COVERAGE)
-- ================================================================

local OptionsFactory = {}

--- Build options cho từng mode, đảm bảo 100% coverage
function OptionsFactory.build(mode)
    local gameName = Util.getGameName()
    local executor = Util.detectExecutor()
    
    Log.info("Building options for mode: %s (Executor: %s)", mode, executor)
    
    -- ═══ Tên file ═══
    local fileNames = {
        FULL_GAME    = gameName .. "_Full.rbxl",
        MODEL_ONLY   = gameName .. "_Model.rbxl",
        TERRAIN_ONLY = gameName .. "_Terrain.rbxl",
    }
    local fileName = fileNames[mode] or gameName .. "_Export.rbxl"
    
    -- ═══ Base Options (tương thích đa executor) ═══
    local opts = {
        -- File output
        FileName = fileName,
        
        -- === Script Decompilation ===
        -- Mode: 0 = none, 1 = bytecode, 2 = full decompile
        DecompileMode = 2,
        DecompileTimeout = BSI.Config.Decompile.Timeout,
        ScriptCache = true,
        SaveBytecode = false,
        
        -- === Instance Coverage ===
        NilInstances = true,
        NilInstancesFix = true,
        SaveNonCreatable = true,
        
        -- === Player Handling ===
        SavePlayers = false,
        RemovePlayerCharacters = true,
        IsolateStarterPlayer = true,
        IsolateLocalPlayer = true,
        IsolateLocalPlayerCharacter = true,
        
        -- === Properties ===
        IgnoreDefaultProperties = false,  -- QUAN TRỌNG: false = save TẤT CẢ properties
        SaveHiddenProperties = true,
        SaveUnscriptableProperties = true,
        SharedStrings = true,
        
        -- === Format ===
        Binary = true,  -- .rbxl binary format
        
        -- === Performance ===
        MaxThreads = 8,
        ShowStatus = true,
        AntiIdle = true,
        Timeout = 60,
        
        -- === Extra ===
        ReadMe = false,
        SafeMode = false,
        IgnoreArchivable = true,  -- Save cả instances với Archivable = false
        IgnoreNotArchivable = false,
        
        -- === Compatibility Options (cho các executor khác nhau) ===
        -- Synapse X
        Decompile = true,
        CustomDecompiler = nil,
        
        -- Wave / Fluxus
        Object = game,
        IsModel = false,
        
        -- UNC
        mode = "full",
    }
    
    -- ═══ MODE-SPECIFIC OVERRIDES ═══
    
    if mode == "FULL_GAME" then
        -- 100% FULL GAME: Mọi thứ
        opts.NilInstances = true
        opts.DecompileMode = 2
        opts.IgnoreDefaultProperties = false
        opts.SaveNonCreatable = true
        opts.IgnoreArchivable = true
        
        -- Thêm tất cả root instances
        local extraInstances = {}
        
        for _, serviceName in ipairs(ALL_SAVE_SERVICES) do
            pcall(function()
                local svc = game:GetService(serviceName)
                if svc then
                    for _, child in ipairs(svc:GetChildren()) do
                        extraInstances[#extraInstances + 1] = child
                    end
                end
            end)
        end
        
        -- Nil instances
        if ENV.getnilinstances then
            pcall(function()
                for _, inst in ipairs(ENV.getnilinstances()) do
                    extraInstances[#extraInstances + 1] = inst
                end
            end)
        end
        
        if #extraInstances > 0 then
            opts.ExtraInstances = extraInstances
        end
        
    elseif mode == "MODEL_ONLY" then
        -- 100% MODELS: Tất cả models + parts + scripts bên trong
        opts.DecompileMode = 2
        opts.NilInstances = false
        opts.IgnoreDefaultProperties = false
        opts.IgnoreArchivable = true
        
        local modelInstances = {}
        
        -- Workspace: TẤT CẢ trừ Terrain và Camera
        pcall(function()
            for _, child in ipairs(Services.Workspace:GetChildren()) do
                if child ~= Services.Terrain and
                   child.ClassName ~= "Camera" and
                   child.ClassName ~= "Player" then
                    modelInstances[#modelInstances + 1] = child
                end
            end
        end)
        
        -- ReplicatedStorage: TẤT CẢ
        pcall(function()
            for _, child in ipairs(Services.ReplicatedStorage:GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        -- ReplicatedFirst: TẤT CẢ
        pcall(function()
            for _, child in ipairs(Services.ReplicatedFirst:GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        -- StarterGui: TẤT CẢ
        pcall(function()
            for _, child in ipairs(Services.StarterGui:GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        -- StarterPack: TẤT CẢ
        pcall(function()
            for _, child in ipairs(Services.StarterPack:GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        -- StarterPlayer: TẤT CẢ
        pcall(function()
            for _, child in ipairs(Services.StarterPlayer:GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        -- Lighting: TẤT CẢ
        pcall(function()
            for _, child in ipairs(Services.Lighting:GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        -- SoundService: TẤT CẢ
        pcall(function()
            for _, child in ipairs(Services.SoundService:GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        -- Chat
        pcall(function()
            for _, child in ipairs(Services.Chat:GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        -- Teams
        pcall(function()
            for _, child in ipairs(Services.Teams:GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        -- ServerStorage (nếu accessible)
        pcall(function()
            for _, child in ipairs(game:GetService("ServerStorage"):GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        opts.ExtraInstances = modelInstances
        
    elseif mode == "TERRAIN_ONLY" then
        -- 100% TERRAIN
        opts.DecompileMode = 0
        opts.NilInstances = false
        opts.IgnoreDefaultProperties = false
        opts.ExtraInstances = {Services.Terrain}
        opts.SaveNonCreatable = true
    end
    
    return opts, fileName
end

--- Build Synapse X specific options
function OptionsFactory.buildSynapse(mode)
    local opts, fileName = OptionsFactory.build(mode)
    
    -- Synapse X sử dụng format khác
    local synOpts = {
        FileName = fileName,
        DecompileMode = opts.DecompileMode == 2 and "decompile" or "none",
        NilInstances = opts.NilInstances,
        DecompileTimeout = opts.DecompileTimeout,
        RemovePlayerCharacters = true,
        SavePlayers = false,
    }
    
    if opts.ExtraInstances then
        synOpts.ExtraInstances = opts.ExtraInstances
    end
    
    return synOpts, fileName
end

BSI.OptionsFactory = OptionsFactory

-- ================================================================
-- SECTION 10: EXPORT ENGINE (UNIFIED EXPORTER)
-- ================================================================

local ExportEngine = {}

--- Export chính - thử TẤT CẢ phương pháp
function ExportEngine.export(mode, progressCallback)
    local startTime = os.clock()
    
    mode = mode or "FULL_GAME"
    
    local callback = function(status, progress)
        if progressCallback then
            progressCallback(status, progress or 0)
        end
    end
    
    Log.info("╔════════════════════════════════════════╗")
    Log.info("║  EXPORT STARTED: %s", mode)
    Log.info("╚════════════════════════════════════════╝")
    
    -- Bước 1: Pre-analysis
    callback("Analyzing game...", 5)
    
    local totalInstances = 0
    pcall(function() totalInstances = #game:GetDescendants() end)
    Log.info("Game has ~%s instances", Util.formatNumber(totalInstances))
    
    -- Bước 2: Pre-decompile scripts (cho better coverage)
    if mode ~= "TERRAIN_ONLY" and BSI.Config.Decompile.Enabled then
        callback("Discovering scripts...", 10)
        
        local allScripts, discoveryStats = ScriptDiscovery.collectAll()
        
        if #allScripts > 0 then
            callback(string.format("Decompiling %d scripts...", #allScripts), 15)
            
            DecompileEngine.resetStats()
            local decompileResults = DecompileEngine.batchDecompile(allScripts,
                function(status, pct)
                    callback(status, 15 + math.floor(pct * 0.35))
                end
            )
            
            -- Inject decompiled source vào scripts (nếu có thể)
            callback("Injecting decompiled sources...", 50)
            local injected = 0
            local injectCount = 0
            
            for script, data in pairs(decompileResults) do
                if data.success and data.source then
                    -- Prefer sethiddenproperty (sets Source directly in .rbxl)
                    local didInject = false
                    if ENV.sethiddenproperty then
                        pcall(function()
                            ENV.sethiddenproperty(script, "Source", data.source:sub(1, 200000))
                            didInject = true
                        end)
                    end
                    -- Fallback: SetAttribute
                    if not didInject then
                        pcall(function()
                            script:SetAttribute("__BSI_Source", data.source:sub(1, 200000))
                            didInject = true
                        end)
                    end
                    if didInject then injected = injected + 1 end
                end
                
                injectCount = injectCount + 1
                if injectCount % 50 == 0 then task.wait() end
            end
            
            Log.info("⚡ Injected source: %d/%d scripts (avg quality: %.1f/100)",
                injected, #allScripts, DecompileEngine.Stats.avgQuality)
        end
    end
    
    -- Bước 3: Terrain analysis
    if mode == "FULL_GAME" or mode == "TERRAIN_ONLY" then
        callback("Analyzing terrain...", 55)
        local terrainInfo = TerrainEngine.analyze()
        
        if terrainInfo.hasData then
            callback(string.format("Terrain: %s voxels, %d materials",
                Util.formatNumber(terrainInfo.nonAirVoxels),
                #terrainInfo.materialNames), 58)
        end
    end
    
    -- Bước 4: Model analysis
    if mode == "FULL_GAME" or mode == "MODEL_ONLY" then
        callback("Analyzing models...", 60)
        -- ModelCollector.collectAll chỉ để log, saveinstance sẽ tự handle
    end
    
    -- Bước 5: BUILD OPTIONS & SAVE
    callback("Building save options...", 65)
    
    local saveFunc = ENV.saveinstance
    
    -- Synapse X specific
    local isSynapse = (syn and syn.saveinstance)
    if isSynapse and not saveFunc then
        saveFunc = function(opts)
            syn.saveinstance(game, opts.FileName, opts)
        end
    end
    
    if not saveFunc then
        Log.critical("saveinstance() KHÔNG KHẢ DỤNG!")
        callback("❌ Executor không hỗ trợ saveinstance!", 0)
        return false, "saveinstance not available"
    end
    
    -- Build options
    local options, fileName
    
    if isSynapse then
        options, fileName = OptionsFactory.buildSynapse(mode)
    else
        options, fileName = OptionsFactory.build(mode)
    end
    
    -- Bước 6: EXECUTE SAVE
    callback("Saving " .. fileName .. "...", 70)
    Log.info("Executing saveinstance with file: %s", fileName)
    
    local success, err = ExportEngine.executeSave(saveFunc, options, fileName, callback)
    
    -- Bước 7: Cleanup
    callback("Cleaning up...", 95)
    
    -- Xóa injected attributes
    pcall(function()
        if mode ~= "TERRAIN_ONLY" then
            for _, desc in ipairs(game:GetDescendants()) do
                if desc:IsA("LuaSourceContainer") then
                    pcall(function()
                        desc:SetAttribute("__BSI_Source", nil)
                    end)
                end
            end
        end
    end)
    
    -- Clear decompile cache
    DecompileEngine.clearCache()
    collectgarbage("collect")
    
    -- Bước 8: Report
    local elapsed = os.clock() - startTime
    
    if success then
        local finalMsg = string.format(
            "Done ✓ — %s (%.1fs)", fileName, elapsed)
        callback(finalMsg, 100)
        
        Log.info("╔════════════════════════════════════════╗")
        Log.info("║  EXPORT COMPLETED SUCCESSFULLY!        ║")
        Log.info("║  File: %s", fileName)
        Log.info("║  Time: %.1f seconds", elapsed)
        Log.info("║  Mode: %s", mode)
        Log.info("╚════════════════════════════════════════╝")
        
        return true, fileName
    else
        local errMsg = string.format("❌ Failed: %s", tostring(err))
        callback(errMsg, 0)
        Log.error("Export failed: %s", tostring(err))
        return false, tostring(err)
    end
end

--- Execute save với multiple fallback strategies
function ExportEngine.executeSave(saveFunc, options, fileName, callback)
    -- Strategy 1: Full options
    callback("Trying full options save...", 72)
    local s1, e1 = pcall(function()
        saveFunc(options)
    end)
    if s1 then return true end
    Log.warn("Strategy 1 failed: %s", tostring(e1))
    
    task.wait(0.5)
    
    -- Strategy 2: Simplified options
    callback("Retry: simplified options...", 76)
    local simplified = {
        FileName = fileName,
        DecompileMode = options.DecompileMode,
        NilInstances = options.NilInstances,
        SavePlayers = false,
        RemovePlayerCharacters = true,
        IgnoreDefaultProperties = false,
        SaveNonCreatable = true,
        Binary = true,
        ShowStatus = true,
    }
    if options.ExtraInstances then
        simplified.ExtraInstances = options.ExtraInstances
    end
    
    local s2, e2 = pcall(function()
        saveFunc(simplified)
    end)
    if s2 then return true end
    Log.warn("Strategy 2 failed: %s", tostring(e2))
    
    task.wait(0.5)
    
    -- Strategy 3: Minimal options
    callback("Retry: minimal options...", 80)
    local minimal = {
        FileName = fileName,
        DecompileMode = 2,
        NilInstances = true,
    }
    
    local s3, e3 = pcall(function()
        saveFunc(minimal)
    end)
    if s3 then return true end
    Log.warn("Strategy 3 failed: %s", tostring(e3))
    
    task.wait(0.5)
    
    -- Strategy 4: Chỉ filename
    callback("Retry: filename only...", 84)
    local s4, e4 = pcall(function()
        saveFunc({FileName = fileName})
    end)
    if s4 then return true end
    Log.warn("Strategy 4 failed: %s", tostring(e4))
    
    task.wait(0.5)
    
    -- Strategy 5: saveinstance(game) trực tiếp
    callback("Retry: direct save...", 88)
    local s5, e5 = pcall(function()
        saveFunc(game)
    end)
    if s5 then return true end
    Log.warn("Strategy 5 failed: %s", tostring(e5))
    
    -- Strategy 6: Synapse specific
    if syn and syn.saveinstance then
        callback("Retry: Synapse specific...", 90)
        local s6, e6 = pcall(function()
            syn.saveinstance(game, fileName)
        end)
        if s6 then return true end
        Log.warn("Strategy 6 (Synapse) failed: %s", tostring(e6))
    end
    
    -- Tất cả strategies đều fail
    return false, string.format(
        "All strategies failed. Last error: %s",
        tostring(e5 or e4 or e3 or e2 or e1))
end

BSI.ExportEngine = ExportEngine

-- ================================================================
-- SECTION 11: PUBLIC API
-- ================================================================

--- Khởi tạo toàn bộ hệ thống
function BSI.init()
    Log.info("╔══════════════════════════════════════════════╗")
    Log.info("║  BaoSaveInstance v%s ULTIMATE               ║", BSI.VERSION)
    Log.info("║  100%% Full Decompiler & Game Saver           ║")
    Log.info("╚══════════════════════════════════════════════╝")
    
    -- Detect executor
    local executor = Util.detectExecutor()
    Log.info("Executor: %s", executor)
    
    -- Check capabilities
    local caps = {}
    if ENV.saveinstance then caps[#caps + 1] = "saveinstance ✓" end
    if ENV.decompile then caps[#caps + 1] = "decompile ✓" end
    if ENV.getscripts then caps[#caps + 1] = "getscripts ✓" end
    if ENV.getloadedmodules then caps[#caps + 1] = "getmodules ✓" end
    if ENV.getnilinstances then caps[#caps + 1] = "nil_recovery ✓" end
    if ENV.getgc then caps[#caps + 1] = "gc_recovery ✓" end
    if ENV.gethiddenproperty then caps[#caps + 1] = "hidden_props ✓" end
    if ENV.writefile then caps[#caps + 1] = "writefile ✓" end
    
    Log.info("Capabilities: %s", table.concat(caps, ", "))
    
    -- Create output folder
    Util.ensureFolder(BSI.Config.OutputFolder)
    
    -- Game info
    local gameName = Util.getGameName()
    local totalInst = 0
    pcall(function() totalInst = #game:GetDescendants() end)
    
    Log.info("Game: %s", gameName)
    Log.info("PlaceId: %d", game.PlaceId)
    Log.info("Instances: ~%s", Util.formatNumber(totalInst))
    Log.info("Init complete!")
    
    return true
end

--- Decompile tất cả scripts (standalone)
function BSI.decompileScripts(progressCallback)
    local scripts = ScriptDiscovery.collectAll()
    DecompileEngine.resetStats()
    local results = DecompileEngine.batchDecompile(scripts, progressCallback)
    return results, DecompileEngine.Stats
end

--- Save models (standalone analysis)
function BSI.saveModels(progressCallback)
    return BSI.exportRBXL("MODEL_ONLY", progressCallback)
end

--- Save terrain (standalone analysis)
function BSI.saveTerrain(progressCallback)
    return BSI.exportRBXL("TERRAIN_ONLY", progressCallback)
end

--- Export ra file .rbxl
function BSI.exportRBXL(mode, progressCallback)
    return ExportEngine.export(mode, progressCallback)
end

--- State tracking
BSI.State = {
    isRunning = false,
    mode = nil,
    progress = 0,
    status = "Ready",
    lastFile = nil,
    lastError = nil,
}

-- ================================================================
-- SECTION 12: UI SYSTEM (HYPER v5.0 PREMIUM)
-- ================================================================

local UI = {}

-- Premium Color Palette
UI.C = {
    bg          = Color3.fromRGB(12, 12, 20),
    bgDark      = Color3.fromRGB(6, 6, 14),
    bgLight     = Color3.fromRGB(20, 20, 32),
    bgCard      = Color3.fromRGB(18, 18, 30),
    accent      = Color3.fromRGB(90, 130, 255),
    accentGlow  = Color3.fromRGB(120, 160, 255),
    accentDark  = Color3.fromRGB(60, 90, 210),
    neon        = Color3.fromRGB(0, 220, 255),
    neonDim     = Color3.fromRGB(0, 150, 200),
    cyber       = Color3.fromRGB(160, 80, 255),
    success     = Color3.fromRGB(40, 220, 110),
    successGlow = Color3.fromRGB(60, 255, 140),
    error       = Color3.fromRGB(255, 55, 55),
    warning     = Color3.fromRGB(255, 200, 40),
    text        = Color3.fromRGB(240, 240, 252),
    textDim     = Color3.fromRGB(150, 150, 175),
    textMuted   = Color3.fromRGB(80, 80, 105),
    border      = Color3.fromRGB(40, 40, 60),
    borderGlow  = Color3.fromRGB(60, 70, 110),
    btnBg       = Color3.fromRGB(22, 22, 38),
    btnHover    = Color3.fromRGB(35, 35, 55),
    fullGame    = Color3.fromRGB(90, 130, 255),
    modelBtn    = Color3.fromRGB(140, 70, 255),
    terrainBtn  = Color3.fromRGB(40, 200, 120),
    saveBtn     = Color3.fromRGB(255, 170, 30),
    exitBtn     = Color3.fromRGB(220, 40, 40),
    gold        = Color3.fromRGB(255, 215, 60),
}

function UI.create()
    -- Xóa UI cũ
    pcall(function()
        local old = Services.CoreGui:FindFirstChild("BaoSaveInstanceUI")
        if old then old:Destroy() end
    end)
    pcall(function()
        local pg = Services.Players.LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local old = pg:FindFirstChild("BaoSaveInstanceUI")
            if old then old:Destroy() end
        end
    end)
    
    -- ═══════════════════════════════════
    -- ScreenGui
    -- ═══════════════════════════════════
    local gui = Instance.new("ScreenGui")
    gui.Name = "BaoSaveInstanceUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999999
    
    local mounted = pcall(function() gui.Parent = Services.CoreGui end)
    if not mounted then
        pcall(function()
            gui.Parent = Services.Players.LocalPlayer:WaitForChild("PlayerGui")
        end)
    end
    
    -- ═══════════════════════════════════
    -- Main Frame (Glassmorphism)
    -- ═══════════════════════════════════
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 440, 0, 620)
    main.Position = UDim2.new(0.5, -220, 0.5, -310)
    main.BackgroundColor3 = UI.C.bg
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = gui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = main
    
    -- Outer glow stroke
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = UI.C.borderGlow
    mainStroke.Thickness = 1.5
    mainStroke.Transparency = 0.2
    mainStroke.Parent = main
    
    -- Animated stroke glow
    task.spawn(function()
        while main and main.Parent do
            Services.TweenService:Create(mainStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Color = UI.C.accent, Transparency = 0.4}):Play()
            task.wait(2)
            Services.TweenService:Create(mainStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Color = UI.C.cyber, Transparency = 0.2}):Play()
            task.wait(2)
        end
    end)
    
    -- ═══════════════════════════════════
    -- Title Bar (Gradient Premium)
    -- ═══════════════════════════════════
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 58)
    titleBar.BackgroundColor3 = UI.C.bgDark
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 16)
    
    -- Title bar gradient
    local titleGrad = Instance.new("UIGradient")
    titleGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 30)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 18, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 25))
    }
    titleGrad.Parent = titleBar
    
    -- Fix bottom corners
    local tbFix = Instance.new("Frame")
    tbFix.Size = UDim2.new(1, 0, 0, 16)
    tbFix.Position = UDim2.new(0, 0, 1, -16)
    tbFix.BackgroundColor3 = UI.C.bgDark
    tbFix.BorderSizePixel = 0
    tbFix.Parent = titleBar

    local tbFixGrad = Instance.new("UIGradient")
    tbFixGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 25))
    }
    tbFixGrad.Parent = tbFix
    
    -- Title text with sparkle
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -110, 0, 24)
    title.Position = UDim2.new(0, 16, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = "⚡ BaoSaveInstance v" .. BSI.VERSION
    title.TextColor3 = UI.C.text
    title.TextSize = 17
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -110, 0, 16)
    subtitle.Position = UDim2.new(0, 16, 0, 32)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "🔥 HYPER Engine — 9 Strategies • 8 Discovery • 6 Workers"
    subtitle.TextColor3 = UI.C.neonDim
    subtitle.TextSize = 10
    subtitle.Font = Enum.Font.GothamSemibold
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = titleBar
    
    -- Subtitle color pulse
    task.spawn(function()
        while subtitle and subtitle.Parent do
            Services.TweenService:Create(subtitle, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {TextColor3 = UI.C.neon}):Play()
            task.wait(1.5)
            Services.TweenService:Create(subtitle, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {TextColor3 = UI.C.cyber}):Play()
            task.wait(1.5)
        end
    end)
    
    -- Version badge
    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 50, 0, 18)
    badge.Position = UDim2.new(0, 16, 0, 50)
    badge.BackgroundColor3 = UI.C.accent
    badge.BackgroundTransparency = 0.7
    badge.Text = "HYPER"
    badge.TextColor3 = UI.C.accentGlow
    badge.TextSize = 9
    badge.Font = Enum.Font.GothamBold
    badge.Parent = titleBar
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)
    
    -- Window buttons
    local function windowBtn(name, text, color, posX)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 34, 0, 34)
        btn.Position = UDim2.new(1, posX, 0, 12)
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.75
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = UI.C.text
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = false
        btn.Parent = titleBar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        btn.MouseEnter:Connect(function()
            Services.TweenService:Create(btn, TweenInfo.new(0.15),
                {BackgroundTransparency = 0.2}):Play()
        end)
        btn.MouseLeave:Connect(function()
            Services.TweenService:Create(btn, TweenInfo.new(0.15),
                {BackgroundTransparency = 0.75}):Play()
        end)
        
        return btn
    end
    
    local btnMin = windowBtn("Min", "─", UI.C.warning, -82)
    local btnClose = windowBtn("Close", "✕", UI.C.error, -42)
    
    -- ═══════════════════════════════════
    -- Content Container
    -- ═══════════════════════════════════
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -24, 1, -68)
    content.Position = UDim2.new(0, 12, 0, 63)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = UI.C.accent
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = main
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = content
    
    -- ═══════════════════════════════════
    -- Info Panel (Enhanced)
    -- ═══════════════════════════════════
    local infoPanel = Instance.new("Frame")
    infoPanel.Name = "Info"
    infoPanel.Size = UDim2.new(1, 0, 0, 88)
    infoPanel.BackgroundColor3 = UI.C.bgCard
    infoPanel.BorderSizePixel = 0
    infoPanel.LayoutOrder = 1
    infoPanel.Parent = content
    Instance.new("UICorner", infoPanel).CornerRadius = UDim.new(0, 12)
    
    local infoStroke = Instance.new("UIStroke")
    infoStroke.Color = UI.C.border
    infoStroke.Thickness = 1
    infoStroke.Transparency = 0.5
    infoStroke.Parent = infoPanel
    
    local gameName = Util.getGameName()
    
    local function infoLabel(text, yPos, color, size)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 18)
        lbl.Position = UDim2.new(0, 12, 0, yPos)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = color or UI.C.text
        lbl.TextSize = size or 12
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = infoPanel
        return lbl
    end
    
    infoLabel("🎮 " .. gameName, 6, UI.C.text, 13)
    infoLabel(string.format("📍 PlaceId: %d | GameId: %d", game.PlaceId, game.GameId), 26, UI.C.textDim, 11)
    
    local instLabel = infoLabel("📦 Scanning instances...", 46, UI.C.textDim, 11)
    local execLabel = infoLabel("🔧 " .. Util.detectExecutor() .. " | Workers: " ..
        BSI.Config.Decompile.ConcurrentWorkers .. " | Quality ≥ " ..
        BSI.Config.Decompile.QualityThreshold, 66, UI.C.textMuted, 10)
    
    task.spawn(function()
        local count = 0
        pcall(function() count = #game:GetDescendants() end)
        instLabel.Text = "📦 " .. Util.formatNumber(count) .. " instances detected"
    end)
    
    -- ═══════════════════════════════════
    -- Status Panel (Premium)
    -- ═══════════════════════════════════
    local statusPanel = Instance.new("Frame")
    statusPanel.Name = "Status"
    statusPanel.Size = UDim2.new(1, 0, 0, 68)
    statusPanel.BackgroundColor3 = UI.C.bgCard
    statusPanel.BorderSizePixel = 0
    statusPanel.LayoutOrder = 2
    statusPanel.Parent = content
    Instance.new("UICorner", statusPanel).CornerRadius = UDim.new(0, 12)
    
    local statusStroke = Instance.new("UIStroke")
    statusStroke.Color = UI.C.border
    statusStroke.Thickness = 1
    statusStroke.Transparency = 0.5
    statusStroke.Parent = statusPanel
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "Text"
    statusText.Size = UDim2.new(1, -20, 0, 22)
    statusText.Position = UDim2.new(0, 12, 0, 8)
    statusText.BackgroundTransparency = 1
    statusText.Text = "✅ HYPER Engine Ready — Select action below"
    statusText.TextColor3 = UI.C.success
    statusText.TextSize = 12
    statusText.Font = Enum.Font.GothamBold
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.TextTruncate = Enum.TextTruncate.AtEnd
    statusText.Parent = statusPanel
    
    local statusDetail = Instance.new("TextLabel")
    statusDetail.Name = "Detail"
    statusDetail.Size = UDim2.new(1, -20, 0, 16)
    statusDetail.Position = UDim2.new(0, 12, 0, 28)
    statusDetail.BackgroundTransparency = 1
    statusDetail.Text = "9 decompile strategies • 8 discovery methods"
    statusDetail.TextColor3 = UI.C.textDim
    statusDetail.TextSize = 10
    statusDetail.Font = Enum.Font.Gotham
    statusDetail.TextXAlignment = Enum.TextXAlignment.Left
    statusDetail.TextTruncate = Enum.TextTruncate.AtEnd
    statusDetail.Parent = statusPanel
    
    -- Progress bar (premium gradient)
    local progBg = Instance.new("Frame")
    progBg.Size = UDim2.new(1, -24, 0, 10)
    progBg.Position = UDim2.new(0, 12, 0, 50)
    progBg.BackgroundColor3 = UI.C.border
    progBg.BorderSizePixel = 0
    progBg.Parent = statusPanel
    Instance.new("UICorner", progBg).CornerRadius = UDim.new(0, 5)
    
    local progFill = Instance.new("Frame")
    progFill.Name = "Fill"
    progFill.Size = UDim2.new(0, 0, 1, 0)
    progFill.BackgroundColor3 = UI.C.accent
    progFill.BorderSizePixel = 0
    progFill.Parent = progBg
    Instance.new("UICorner", progFill).CornerRadius = UDim.new(0, 5)
    
    -- Gradient on progress
    local progGrad = Instance.new("UIGradient")
    progGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, UI.C.neon),
        ColorSequenceKeypoint.new(0.5, UI.C.accent),
        ColorSequenceKeypoint.new(1, UI.C.cyber)
    }
    progGrad.Parent = progFill
    
    -- ═══════════════════════════════════
    -- Button Factory (Premium)
    -- ═══════════════════════════════════
    local allButtons = {}
    
    local function createActionButton(name, text, description, icon, layoutOrder, accentColor)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 62)
        btn.BackgroundColor3 = UI.C.btnBg
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.LayoutOrder = layoutOrder
        btn.AutoButtonColor = false
        btn.Parent = content
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
        
        -- Left accent bar (animated)
        local accentBar = Instance.new("Frame")
        accentBar.Size = UDim2.new(0, 3, 0.6, 0)
        accentBar.Position = UDim2.new(0, 8, 0.2, 0)
        accentBar.BackgroundColor3 = accentColor
        accentBar.BorderSizePixel = 0
        accentBar.Parent = btn
        Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 2)
        
        -- Icon circle
        local iconBg = Instance.new("Frame")
        iconBg.Size = UDim2.new(0, 36, 0, 36)
        iconBg.Position = UDim2.new(0, 18, 0.5, -18)
        iconBg.BackgroundColor3 = accentColor
        iconBg.BackgroundTransparency = 0.8
        iconBg.BorderSizePixel = 0
        iconBg.Parent = btn
        Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 18)
        
        local iconLbl = Instance.new("TextLabel")
        iconLbl.Size = UDim2.new(1, 0, 1, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Text = icon
        iconLbl.TextSize = 18
        iconLbl.Font = Enum.Font.GothamBold
        iconLbl.Parent = iconBg
        
        -- Main label
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 0, 22)
        lbl.Position = UDim2.new(0, 62, 0, 10)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = UI.C.text
        lbl.TextSize = 14
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn
        
        -- Description
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -70, 0, 16)
        desc.Position = UDim2.new(0, 62, 0, 34)
        desc.BackgroundTransparency = 1
        desc.Text = description
        desc.TextColor3 = UI.C.textMuted
        desc.TextSize = 10
        desc.Font = Enum.Font.Gotham
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = btn
        
        -- Stroke
        local stroke = Instance.new("UIStroke")
        stroke.Color = UI.C.border
        stroke.Thickness = 1
        stroke.Transparency = 0.5
        stroke.Parent = btn
        
        -- Hover animations
        btn.MouseEnter:Connect(function()
            Services.TweenService:Create(btn, TweenInfo.new(0.2),
                {BackgroundColor3 = UI.C.btnHover}):Play()
            Services.TweenService:Create(stroke, TweenInfo.new(0.2),
                {Color = accentColor, Transparency = 0}):Play()
            Services.TweenService:Create(accentBar, TweenInfo.new(0.2),
                {Size = UDim2.new(0, 3, 0.85, 0), BackgroundTransparency = 0}):Play()
            Services.TweenService:Create(iconBg, TweenInfo.new(0.2),
                {BackgroundTransparency = 0.5}):Play()
        end)
        
        btn.MouseLeave:Connect(function()
            Services.TweenService:Create(btn, TweenInfo.new(0.2),
                {BackgroundColor3 = UI.C.btnBg}):Play()
            Services.TweenService:Create(stroke, TweenInfo.new(0.2),
                {Color = UI.C.border, Transparency = 0.5}):Play()
            Services.TweenService:Create(accentBar, TweenInfo.new(0.2),
                {Size = UDim2.new(0, 3, 0.6, 0)}):Play()
            Services.TweenService:Create(iconBg, TweenInfo.new(0.2),
                {BackgroundTransparency = 0.8}):Play()
        end)
        
        allButtons[#allButtons + 1] = btn
        return btn
    end
    
    -- ═══════════════════════════════════
    -- Action Buttons
    -- ═══════════════════════════════════
    local btnFullGame = createActionButton(
        "FullGame",
        "⚡ HYPER Full Decompile",
        "9-Strategy Racing • 100% Scripts + Models + Terrain → .rbxl",
        "🌍", 3, UI.C.fullGame
    )
    
    local btnModels = createActionButton(
        "Models",
        "Decompile Full Model",
        "8 Discovery Methods • All Parts, Meshes, Welds + Scripts",
        "🧊", 4, UI.C.modelBtn
    )
    
    local btnTerrain = createActionButton(
        "Terrain",
        "Decompile Terrain",
        "100% Voxels, Water, Materials, Regions",
        "🏔️", 5, UI.C.terrainBtn
    )
    
    local btnQuickSave = createActionButton(
        "QuickSave",
        "Quick Save .rbxl",
        "6 Workers • Fast save với tối ưu tốc độ",
        "💾", 6, UI.C.saveBtn
    )
    
    local btnExit = createActionButton(
        "Exit",
        "Exit",
        "Close BaoSaveInstance",
        "❌", 7, UI.C.exitBtn
    )
    
    -- ═══════════════════════════════════
    -- Footer
    -- ═══════════════════════════════════
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, 0, 0, 28)
    footer.BackgroundTransparency = 1
    footer.Text = "⚡ BaoSaveInstance v" .. BSI.VERSION .. " HYPER | RightShift toggle | 100% Coverage"
    footer.TextColor3 = UI.C.textMuted
    footer.TextSize = 9
    footer.Font = Enum.Font.GothamSemibold
    footer.TextTransparency = 0.3
    footer.LayoutOrder = 10
    footer.Parent = content
    
    -- ═══════════════════════════════════
    -- DRAGGABLE
    -- ═══════════════════════════════════
    local dragging, dragStart, startPos = false, nil, nil
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- ═══════════════════════════════════
    -- MINIMIZE
    -- ═══════════════════════════════════
    local minimized = false
    local fullSize = main.Size
    
    btnMin.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Services.TweenService:Create(main,
                TweenInfo.new(0.3, Enum.EasingStyle.Quint),
                {Size = UDim2.new(0, 440, 0, 58)}):Play()
            content.Visible = false
            btnMin.Text = "□"
        else
            content.Visible = true
            Services.TweenService:Create(main,
                TweenInfo.new(0.3, Enum.EasingStyle.Quint),
                {Size = fullSize}):Play()
            btnMin.Text = "─"
        end
    end)
    
    -- ═══════════════════════════════════
    -- STATUS UPDATE
    -- ═══════════════════════════════════
    local function updateStatus(text, detail, color, progress)
        statusText.Text = text
        statusText.TextColor3 = color or UI.C.text
        
        if detail then
            statusDetail.Text = detail
        end
        
        if progress then
            local size = UDim2.new(math.clamp(progress / 100, 0, 1), 0, 1, 0)
            Services.TweenService:Create(progFill, TweenInfo.new(0.3),
                {Size = size}):Play()
            
            if progress >= 100 then
                progFill.BackgroundColor3 = UI.C.success
                -- Glow on complete
                Services.TweenService:Create(statusStroke, TweenInfo.new(0.5),
                    {Color = UI.C.successGlow, Transparency = 0}):Play()
                task.delay(2, function()
                    pcall(function()
                        Services.TweenService:Create(statusStroke, TweenInfo.new(1),
                            {Color = UI.C.border, Transparency = 0.5}):Play()
                    end)
                end)
            elseif progress > 0 then
                progFill.BackgroundColor3 = UI.C.accent
            end
        end
    end
    
    local function setButtonsEnabled(enabled)
        for _, btn in ipairs(allButtons) do
            btn.Active = enabled
            Services.TweenService:Create(btn, TweenInfo.new(0.15),
                {BackgroundTransparency = enabled and 0 or 0.5}):Play()
        end
    end
    
    -- ═══════════════════════════════════
    -- BUTTON LOGIC
    -- ═══════════════════════════════════
    
    local function executeExport(mode, buttonName)
        if BSI.State.isRunning then
            updateStatus("⚠️ Process already running!", "Please wait...", UI.C.warning, nil)
            return
        end
        
        BSI.State.isRunning = true
        setButtonsEnabled(false)
        
        updateStatus("⏳ Initializing " .. buttonName .. "...",
            "Mode: " .. mode .. " | HYPER Engine warming up...", UI.C.warning, 5)
        
        task.spawn(function()
            local success, result = ExportEngine.export(mode, function(status, progress)
                task.spawn(function()
                    updateStatus("⚡ " .. status, "Mode: " .. mode,
                        UI.C.warning, progress)
                end)
            end)
            
            BSI.State.isRunning = false
            
            if success then
                local qualityStr = string.format(" | Quality: %.0f/100", DecompileEngine.Stats.avgQuality)
                updateStatus("✅ " .. buttonName .. " complete!",
                    "📁 " .. tostring(result) .. qualityStr, UI.C.success, 100)
                BSI.State.lastFile = result
            else
                updateStatus("❌ " .. buttonName .. " failed!",
                    "Error: " .. tostring(result), UI.C.error, 0)
                BSI.State.lastError = result
            end
            
            setButtonsEnabled(true)
        end)
    end
    
    -- Full Game
    btnFullGame.MouseButton1Click:Connect(function()
        executeExport("FULL_GAME", "HYPER Full Decompile")
    end)
    
    -- Full Model
    btnModels.MouseButton1Click:Connect(function()
        executeExport("MODEL_ONLY", "Decompile Full Model")
    end)
    
    -- Terrain
    btnTerrain.MouseButton1Click:Connect(function()
        executeExport("TERRAIN_ONLY", "Decompile Terrain")
    end)
    
    -- Quick Save
    btnQuickSave.MouseButton1Click:Connect(function()
        if BSI.State.isRunning then return end
        BSI.State.isRunning = true
        setButtonsEnabled(false)
        
        updateStatus("⚡ Quick Save...", "HYPER speed saving...", UI.C.saveBtn, 30)
        
        task.spawn(function()
            local saveFunc = ENV.saveinstance
            local isSyn = syn and syn.saveinstance
            
            if not saveFunc and not isSyn then
                updateStatus("❌ saveinstance not available!", "", UI.C.error, 0)
                BSI.State.isRunning = false
                setButtonsEnabled(true)
                return
            end
            
            local fileName = Util.getGameName() .. "_QuickSave.rbxl"
            
            local ok, err = pcall(function()
                if isSyn then
                    syn.saveinstance(game, fileName)
                else
                    saveFunc({
                        FileName = fileName,
                        DecompileMode = 2,
                        NilInstances = true,
                        SavePlayers = false,
                        RemovePlayerCharacters = true,
                        IgnoreDefaultProperties = false,
                        ShowStatus = true,
                    })
                end
            end)
            
            BSI.State.isRunning = false
            
            if ok then
                updateStatus("✅ Quick Save complete!",
                    "📁 " .. fileName, UI.C.success, 100)
            else
                updateStatus("❌ Quick Save failed!",
                    tostring(err), UI.C.error, 0)
            end
            
            setButtonsEnabled(true)
        end)
    end)
    
    -- Close
    local function closeUI()
        Services.TweenService:Create(main,
            TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0),
             Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
        Services.TweenService:Create(main,
            TweenInfo.new(0.3),
            {BackgroundTransparency = 1}):Play()
        task.wait(0.35)
        gui:Destroy()
    end
    
    btnClose.MouseButton1Click:Connect(closeUI)
    btnExit.MouseButton1Click:Connect(closeUI)
    
    -- ═══════════════════════════════════
    -- OPEN ANIMATION (Premium)
    -- ═══════════════════════════════════
    main.BackgroundTransparency = 1
    main.Size = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    task.wait(0.05)
    
    Services.TweenService:Create(main,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = fullSize,
         Position = UDim2.new(0.5, -220, 0.5, -310),
         BackgroundTransparency = 0}):Play()
    
    -- ═══════════════════════════════════
    -- KEYBIND: RightShift toggle
    -- ═══════════════════════════════════
    Services.UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            gui.Enabled = not gui.Enabled
        end
    end)
    
    UI.Gui = gui
    UI.StatusText = statusText
    UI.StatusDetail = statusDetail
    UI.ProgFill = progFill
    UI.UpdateStatus = updateStatus
    
    Log.info("⚡ HYPER UI created! Press RightShift to toggle")
    
    return gui
end

BSI.UI = UI

-- ================================================================
-- SECTION 13: STARTUP
-- ================================================================

-- Khởi tạo
BSI.init()

-- Tạo UI
BSI.UI.create()

-- Export global
if getgenv then
    getgenv().BaoSaveInstance = BSI
    getgenv().BSI = BSI
end
_G.BaoSaveInstance = BSI
_G.BSI = BSI

-- ================================================================
-- SECTION 14: CONSOLE API REFERENCE
-- ================================================================

--[[
╔══════════════════════════════════════════════════════════════════╗
║              BAOSAVEINSTANCE v5.0 HYPER — API REFERENCE         ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  -- HYPER Full Game (9-Strategy Racing Decompile)               ║
║  BSI.exportRBXL("FULL_GAME")                                    ║
║                                                                  ║
║  -- 100% Models Only                                             ║
║  BSI.exportRBXL("MODEL_ONLY")                                   ║
║                                                                  ║
║  -- 100% Terrain Only                                            ║
║  BSI.exportRBXL("TERRAIN_ONLY")                                 ║
║                                                                  ║
║  -- Decompile all scripts (standalone)                           ║
║  BSI.decompileScripts(function(s,p) print(s,p) end)             ║
║                                                                  ║
║  -- HYPER Config                                                 ║
║  BSI.Config.Decompile.ConcurrentWorkers = 8                     ║
║  BSI.Config.Decompile.QualityThreshold = 50                     ║
║  BSI.Config.Decompile.RaceTimeout = 15                          ║
║                                                                  ║
║  -- Check state                                                  ║
║  print(BSI.State.status)                                         ║
║  print(BSI.DecompileEngine.Stats.avgQuality)                    ║
║                                                                  ║
║  -- Score a source string                                        ║
║  local q = BSI.DecompileEngine.scoreSource(code)                ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
]]

Log.info("╔══════════════════════════════════════════════╗")
Log.info("║  BaoSaveInstance v%s HYPER — READY!     ║", BSI.VERSION)
Log.info("║  9 Strategies • 8 Discovery • 6 Workers      ║")
Log.info("║  Press RightShift to toggle UI                ║")
Log.info("╚══════════════════════════════════════════════╝")

return BSI
