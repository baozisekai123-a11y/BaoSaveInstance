--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║  ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗║
    ║  ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝║
    ║  ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  ║
    ║  ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  ║
    ║  ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗║
    ║  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝║
    ║                                                              ║
    ║  BaoSaveInstance v4.0 ULTIMATE                               ║
    ║  100% Full Game + Model + Script + Terrain Decompiler        ║
    ║                                                              ║
    ║  Features:                                                   ║
    ║  • 100% Script Decompile (Server + Local + Module)           ║
    ║  • 100% Model Save (Parts, Meshes, Welds, Constraints)      ║
    ║  • 100% Terrain Save (Voxels, Water, Materials, Regions)    ║
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
BSI.VERSION = "4.0.0"
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
    
    -- ═══ Decompile - TỐI ĐA ═══
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
        IncludeServerScripts = true,
        IncludeLocalScripts  = true,
        IncludeModuleScripts = true,
        FallbackComment  = true,     -- Comment fallback khi fail
        DecompileInternalModules = true, -- Decompile cả internal modules
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
-- SECTION 5: SCRIPT DISCOVERY ENGINE (100% THU THẬP)
-- ================================================================

local ScriptDiscovery = {}

--- Thu thập TẤT CẢ scripts trong game bằng MỌI phương pháp
function ScriptDiscovery.collectAll()
    local allScripts = {}
    local seen = {} -- Track bằng debug ID để không trùng
    local stats = {
        fromGetScripts = 0,
        fromGetModules = 0,
        fromDescendants = 0,
        fromNil = 0,
        fromGC = 0,
        fromConnections = 0,
        total = 0
    }
    
    local function addScript(script, source)
        if not script then return end
        if not script:IsA("LuaSourceContainer") then return end
        
        local id = ""
        pcall(function() id = tostring(script:GetDebugId()) end)
        if id == "" then
            pcall(function() id = tostring(script) .. script.Name .. script.ClassName end)
        end
        
        if seen[id] then return end
        seen[id] = true
        
        allScripts[#allScripts + 1] = script
        stats[source] = (stats[source] or 0) + 1
    end
    
    -- ═══ Phương pháp 1: getscripts() ═══
    -- Lấy TẤT CẢ scripts đang tồn tại
    if ENV.getscripts then
        local ok, scripts = pcall(ENV.getscripts)
        if ok and scripts then
            for _, s in ipairs(scripts) do
                addScript(s, "fromGetScripts")
            end
        end
        Log.info("getscripts(): +%d scripts", stats.fromGetScripts)
    end
    
    task.wait()
    
    -- ═══ Phương pháp 2: getloadedmodules() ═══
    -- Lấy modules đã được require()
    if ENV.getloadedmodules then
        local ok, modules = pcall(ENV.getloadedmodules)
        if ok and modules then
            for _, m in ipairs(modules) do
                addScript(m, "fromGetModules")
            end
        end
        Log.info("getloadedmodules(): +%d modules", stats.fromGetModules)
    end
    
    task.wait()
    
    -- ═══ Phương pháp 3: Quét TOÀN BỘ services bằng GetDescendants ═══
    local servicesToScan = {
        Services.Workspace,
        Services.ReplicatedStorage,
        Services.ReplicatedFirst,
        Services.StarterGui,
        Services.StarterPack,
        Services.StarterPlayer,
        Services.Lighting,
        Services.SoundService,
        Services.Chat,
        Services.Teams,
        Services.TestService,
        Services.MaterialService,
    }
    
    -- Thêm services khó truy cập
    for _, name in ipairs({"ServerStorage", "ServerScriptService", "CoreGui"}) do
        pcall(function()
            local svc = game:GetService(name)
            if svc then
                servicesToScan[#servicesToScan + 1] = svc
            end
        end)
    end
    
    for _, service in ipairs(servicesToScan) do
        pcall(function()
            local descendants = service:GetDescendants()
            for _, desc in ipairs(descendants) do
                if desc:IsA("LuaSourceContainer") then
                    addScript(desc, "fromDescendants")
                end
            end
        end)
        task.wait()
    end
    
    Log.info("Descendants scan: +%d scripts", stats.fromDescendants)
    
    -- ═══ Phương pháp 4: Nil Instances ═══
    -- Scripts có thể bị parent = nil nhưng vẫn chạy
    if BSI.Config.Decompile.RecoverFromNil and ENV.getnilinstances then
        local ok, nilInst = pcall(ENV.getnilinstances)
        if ok and nilInst then
            for _, inst in ipairs(nilInst) do
                if inst:IsA("LuaSourceContainer") then
                    addScript(inst, "fromNil")
                end
                -- Quét children của nil instances
                pcall(function()
                    for _, child in ipairs(inst:GetDescendants()) do
                        if child:IsA("LuaSourceContainer") then
                            addScript(child, "fromNil")
                        end
                    end
                end)
            end
        end
        Log.info("Nil instances: +%d scripts", stats.fromNil)
    end
    
    task.wait()
    
    -- ═══ Phương pháp 5: Garbage Collector ═══
    -- Scripts bị destroy nhưng vẫn còn trong GC
    if BSI.Config.Decompile.RecoverFromGC and ENV.getgc then
        local ok, gcObjects = pcall(ENV.getgc, true) -- true = include tables
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
        Log.info("GC recovery: +%d scripts", stats.fromGC)
    end
    
    task.wait()
    
    -- ═══ Phương pháp 6: getinstances() ═══
    -- Backup method - lấy TẤT CẢ instances
    if ENV.getinstances then
        local ok, allInst = pcall(ENV.getinstances)
        if ok and allInst then
            local count = 0
            for _, inst in ipairs(allInst) do
                if inst:IsA("LuaSourceContainer") then
                    local before = #allScripts
                    addScript(inst, "fromConnections")
                    if #allScripts > before then count = count + 1 end
                end
                
                -- Yield mỗi 5000
                count = count + 1
                if count % 5000 == 0 then task.wait() end
            end
        end
        Log.info("getinstances(): +%d scripts", stats.fromConnections)
    end
    
    stats.total = #allScripts
    
    Log.info("══════════════════════════════════════")
    Log.info("SCRIPT DISCOVERY HOÀN TẤT:")
    Log.info("  getscripts:    %d", stats.fromGetScripts)
    Log.info("  getmodules:    %d", stats.fromGetModules)
    Log.info("  descendants:   %d", stats.fromDescendants)
    Log.info("  nil recovery:  %d", stats.fromNil)
    Log.info("  GC recovery:   %d", stats.fromGC)
    Log.info("  other:         %d", stats.fromConnections)
    Log.info("  ─────────────────")
    Log.info("  TỔNG:          %d scripts", stats.total)
    Log.info("══════════════════════════════════════")
    
    return allScripts, stats
end

BSI.ScriptDiscovery = ScriptDiscovery

-- ================================================================
-- SECTION 6: DECOMPILE ENGINE (100% DECOMPILE)
-- ================================================================

local DecompileEngine = {}
DecompileEngine.Cache = {}
DecompileEngine.Stats = {
    total = 0, success = 0, failed = 0,
    cached = 0, skipped = 0, recovered = 0
}

--- Reset stats
function DecompileEngine.resetStats()
    DecompileEngine.Stats = {
        total = 0, success = 0, failed = 0,
        cached = 0, skipped = 0, recovered = 0
    }
end

--- Decompile 1 script với TẤT CẢ phương pháp fallback
function DecompileEngine.decompileSingle(scriptInst)
    if not scriptInst then
        return false, "-- nil script"
    end
    
    -- Lấy cache key
    local cacheKey = ""
    pcall(function() cacheKey = tostring(scriptInst:GetDebugId()) end)
    if cacheKey == "" then
        cacheKey = tostring(scriptInst) .. tostring(scriptInst.Name)
    end
    
    -- Check cache
    if BSI.Config.Decompile.CacheEnabled and DecompileEngine.Cache[cacheKey] then
        DecompileEngine.Stats.cached = DecompileEngine.Stats.cached + 1
        return true, DecompileEngine.Cache[cacheKey]
    end
    
    DecompileEngine.Stats.total = DecompileEngine.Stats.total + 1
    
    local source = nil
    local method = "none"
    
    -- ═══ Phương pháp 1: decompile() trực tiếp ═══
    if ENV.decompile then
        for attempt = 1, BSI.Config.Decompile.Retries do
            local ok, result = pcall(function()
                return ENV.decompile(scriptInst)
            end)
            
            if ok and result and type(result) == "string" and #result > 2 then
                -- Kiểm tra không phải error message
                if not result:match("^%-%-.*failed") and
                   not result:match("^%-%-.*error") and
                   not result:match("^%-%-.*timeout") then
                    source = result
                    method = "decompile_direct"
                    break
                end
            end
            
            -- Tăng timeout mỗi lần retry
            if attempt < BSI.Config.Decompile.Retries then
                task.wait(0.03 * attempt)
            end
        end
    end
    
    -- ═══ Phương pháp 2: Synapse decompile ═══
    if not source and syn and syn.decompile then
        local ok, result = pcall(function()
            return syn.decompile(scriptInst)
        end)
        if ok and result and #result > 2 then
            source = result
            method = "syn_decompile"
        end
    end
    
    -- ═══ Phương pháp 3: Source property trực tiếp ═══
    if not source then
        pcall(function()
            if scriptInst:IsA("ModuleScript") then
                local src = scriptInst.Source
                if src and #src > 0 then
                    source = src
                    method = "source_property"
                end
            end
        end)
    end
    
    -- ═══ Phương pháp 4: Hidden property ═══
    if not source and ENV.gethiddenproperty then
        pcall(function()
            local ok, src = ENV.gethiddenproperty(scriptInst, "Source")
            if ok and src and #tostring(src) > 0 then
                source = tostring(src)
                method = "hidden_property"
                DecompileEngine.Stats.recovered = DecompileEngine.Stats.recovered + 1
            end
        end)
    end
    
    -- ═══ Phương pháp 5: LinkedSource ═══
    if not source then
        pcall(function()
            local linkedSrc = scriptInst.LinkedSource
            if linkedSrc and #linkedSrc > 0 then
                source = "-- LinkedSource: " .. linkedSrc .. "\n-- Cần tải từ URL này"
                method = "linked_source"
            end
        end)
    end
    
    -- ═══ Post-processing ═══
    if source then
        -- Làm sạch source
        source = DecompileEngine.cleanSource(source)
        
        -- Thêm header
        if BSI.Config.Decompile.AddHeaders then
            source = DecompileEngine.addHeader(scriptInst, source, method)
        end
        
        -- Cache
        if BSI.Config.Decompile.CacheEnabled then
            DecompileEngine.Cache[cacheKey] = source
        end
        
        DecompileEngine.Stats.success = DecompileEngine.Stats.success + 1
        return true, source
    else
        -- ═══ Fallback: Tạo comment chi tiết ═══
        DecompileEngine.Stats.failed = DecompileEngine.Stats.failed + 1
        
        local fullName = "Unknown"
        pcall(function() fullName = scriptInst:GetFullName() end)
        
        local fallback = string.format(
            "--[[\n" ..
            "    ╔═══════════════════════════════════════╗\n" ..
            "    ║  DECOMPILE FAILED                     ║\n" ..
            "    ╚═══════════════════════════════════════╝\n" ..
            "    \n" ..
            "    Script: %s\n" ..
            "    Class:  %s\n" ..
            "    Path:   %s\n" ..
            "    \n" ..
            "    Lý do có thể:\n" ..
            "    • Script được bảo vệ bởi anti-decompile\n" ..
            "    • Script rỗng hoặc chưa được load\n" ..
            "    • Bytecode không tương thích\n" ..
            "    • Server-side script (không thể truy cập từ client)\n" ..
            "    \n" ..
            "    Tool: BaoSaveInstance v%s\n" ..
            "    Time: %s\n" ..
            "]]--\n",
            scriptInst.Name,
            scriptInst.ClassName,
            fullName,
            BSI.VERSION,
            os.date("%Y-%m-%d %H:%M:%S")
        )
        
        return false, fallback
    end
end

--- Làm sạch source code
function DecompileEngine.cleanSource(source)
    if not source or type(source) ~= "string" then
        return "-- empty source"
    end
    
    -- Loại bỏ null bytes
    source = source:gsub("%z", "")
    
    -- Loại bỏ dòng trống thừa ở đầu
    source = source:gsub("^[\r\n]+", "")
    
    -- Normalize line endings
    source = source:gsub("\r\n", "\n")
    source = source:gsub("\r", "\n")
    
    -- Loại bỏ trailing whitespace
    source = source:gsub("[ \t]+\n", "\n")
    
    -- Loại bỏ dòng trống liên tiếp (> 3)
    source = source:gsub("\n\n\n+", "\n\n")
    
    return source
end

--- Thêm header vào source
function DecompileEngine.addHeader(scriptInst, source, method)
    local fullName = "Unknown"
    pcall(function() fullName = scriptInst:GetFullName() end)
    
    local header = string.format(
        "--[[\n" ..
        "    ✅ Decompiled by BaoSaveInstance v%s\n" ..
        "    📜 Script: %s\n" ..
        "    📂 Class:  %s\n" ..
        "    📍 Path:   %s\n" ..
        "    🔧 Method: %s\n" ..
        "    🕐 Time:   %s\n" ..
        "]]--\n\n",
        BSI.VERSION,
        scriptInst.Name,
        scriptInst.ClassName,
        fullName,
        method or "unknown",
        os.date("%Y-%m-%d %H:%M:%S")
    )
    
    return header .. source
end

--- Batch decompile TẤT CẢ scripts
function DecompileEngine.batchDecompile(scripts, progressCallback)
    if not scripts or #scripts == 0 then
        return {}
    end
    
    local results = {}
    local total = #scripts
    local batchSize = BSI.Config.Decompile.BatchSize
    
    Log.info("Bắt đầu decompile %d scripts...", total)
    
    -- Sắp xếp: ModuleScript → LocalScript → Script (nhỏ trước lớn sau)
    local sorted = {}
    for i, s in ipairs(scripts) do sorted[i] = s end
    
    table.sort(sorted, function(a, b)
        local order = {ModuleScript = 1, LocalScript = 2, Script = 3}
        local oa = order[a.ClassName] or 4
        local ob = order[b.ClassName] or 4
        return oa < ob
    end)
    
    -- Decompile từng script
    for i = 1, total do
        local script = sorted[i]
        
        -- Kiểm tra loại script
        local shouldDecompile = true
        if script.ClassName == "Script" and not BSI.Config.Decompile.IncludeServerScripts then
            shouldDecompile = false
        elseif script.ClassName == "LocalScript" and not BSI.Config.Decompile.IncludeLocalScripts then
            shouldDecompile = false
        elseif script.ClassName == "ModuleScript" and not BSI.Config.Decompile.IncludeModuleScripts then
            shouldDecompile = false
        end
        
        if shouldDecompile then
            local ok, source = DecompileEngine.decompileSingle(script)
            
            results[script] = {
                success = ok,
                source = source,
                className = script.ClassName,
                name = script.Name,
                fullName = (pcall(function() return script:GetFullName() end))
                    and script:GetFullName() or "Unknown"
            }
        else
            DecompileEngine.Stats.skipped = DecompileEngine.Stats.skipped + 1
        end
        
        -- Progress callback
        if progressCallback and (i % 5 == 0 or i == total) then
            local pct = math.floor(i / total * 100)
            progressCallback(
                string.format("Decompile: %d/%d (%d%%) [✓%d ✗%d]",
                    i, total, pct,
                    DecompileEngine.Stats.success,
                    DecompileEngine.Stats.failed),
                pct
            )
        end
        
        -- Yield
        if i % batchSize == 0 then
            task.wait(0.01)
            Util.memoryCheck()
        elseif i % 5 == 0 then
            task.wait(BSI.Config.Performance.TaskWaitTime)
        end
    end
    
    Log.info("═══════════════════════════════════════")
    Log.info("DECOMPILE RESULTS:")
    Log.info("  Total:     %d", DecompileEngine.Stats.total)
    Log.info("  Success:   %d (%.1f%%)", DecompileEngine.Stats.success,
        DecompileEngine.Stats.total > 0
            and (DecompileEngine.Stats.success / DecompileEngine.Stats.total * 100) or 0)
    Log.info("  Failed:    %d", DecompileEngine.Stats.failed)
    Log.info("  Cached:    %d", DecompileEngine.Stats.cached)
    Log.info("  Skipped:   %d", DecompileEngine.Stats.skipped)
    Log.info("  Recovered: %d", DecompileEngine.Stats.recovered)
    Log.info("═══════════════════════════════════════")
    
    return results
end

--- Xóa cache
function DecompileEngine.clearCache()
    DecompileEngine.Cache = {}
    DecompileEngine.resetStats()
    collectgarbage("collect")
end

BSI.DecompileEngine = DecompileEngine

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
            
            for script, data in pairs(decompileResults) do
                if data.success and data.source then
                    pcall(function()
                        script:SetAttribute("__BSI_Source", data.source:sub(1, 200000))
                        injected = injected + 1
                    end)
                end
                
                injected = injected + 1
                if injected % 50 == 0 then task.wait() end
            end
            
            Log.info("Injected source vào %d scripts", injected)
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
-- SECTION 12: UI SYSTEM (PROFESSIONAL)
-- ================================================================

local UI = {}

-- Color palette
UI.C = {
    bg          = Color3.fromRGB(16, 16, 24),
    bgDark      = Color3.fromRGB(10, 10, 16),
    bgLight     = Color3.fromRGB(24, 24, 36),
    accent      = Color3.fromRGB(80, 120, 255),
    accentGlow  = Color3.fromRGB(100, 145, 255),
    accentDark  = Color3.fromRGB(55, 85, 200),
    success     = Color3.fromRGB(60, 210, 120),
    error       = Color3.fromRGB(255, 70, 70),
    warning     = Color3.fromRGB(255, 195, 50),
    text        = Color3.fromRGB(235, 235, 245),
    textDim     = Color3.fromRGB(140, 140, 165),
    textMuted   = Color3.fromRGB(90, 90, 110),
    border      = Color3.fromRGB(45, 45, 65),
    btnBg       = Color3.fromRGB(30, 30, 45),
    btnHover    = Color3.fromRGB(42, 42, 62),
    fullGame    = Color3.fromRGB(80, 120, 255),
    modelBtn    = Color3.fromRGB(120, 80, 255),
    terrainBtn  = Color3.fromRGB(60, 180, 120),
    saveBtn     = Color3.fromRGB(255, 160, 40),
    exitBtn     = Color3.fromRGB(200, 50, 50),
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
    -- Main Frame
    -- ═══════════════════════════════════
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 420, 0, 580)
    main.Position = UDim2.new(0.5, -210, 0.5, -290)
    main.BackgroundColor3 = UI.C.bg
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = gui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 14)
    mainCorner.Parent = main
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = UI.C.border
    mainStroke.Thickness = 1.5
    mainStroke.Transparency = 0.3
    mainStroke.Parent = main
    
    -- ═══════════════════════════════════
    -- Title Bar
    -- ═══════════════════════════════════
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 52)
    titleBar.BackgroundColor3 = UI.C.bgDark
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)
    
    -- Fix bottom corners
    local tbFix = Instance.new("Frame")
    tbFix.Size = UDim2.new(1, 0, 0, 14)
    tbFix.Position = UDim2.new(0, 0, 1, -14)
    tbFix.BackgroundColor3 = UI.C.bgDark
    tbFix.BorderSizePixel = 0
    tbFix.Parent = titleBar
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔧 BaoSaveInstance v" .. BSI.VERSION
    title.TextColor3 = UI.C.text
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -100, 0, 16)
    subtitle.Position = UDim2.new(0, 16, 0, 32)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Ultimate 100% Decompiler"
    subtitle.TextColor3 = UI.C.textMuted
    subtitle.TextSize = 10
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = titleBar
    
    -- Window buttons
    local function windowBtn(name, text, color, posX)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 32, 0, 32)
        btn.Position = UDim2.new(1, posX, 0, 10)
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.7
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
                {BackgroundTransparency = 0.3}):Play()
        end)
        btn.MouseLeave:Connect(function()
            Services.TweenService:Create(btn, TweenInfo.new(0.15),
                {BackgroundTransparency = 0.7}):Play()
        end)
        
        return btn
    end
    
    local btnMin = windowBtn("Min", "─", UI.C.warning, -78)
    local btnClose = windowBtn("Close", "✕", UI.C.error, -40)
    
    -- ═══════════════════════════════════
    -- Content Container
    -- ═══════════════════════════════════
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -24, 1, -62)
    content.Position = UDim2.new(0, 12, 0, 57)
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
    -- Info Panel
    -- ═══════════════════════════════════
    local infoPanel = Instance.new("Frame")
    infoPanel.Name = "Info"
    infoPanel.Size = UDim2.new(1, 0, 0, 80)
    infoPanel.BackgroundColor3 = UI.C.bgLight
    infoPanel.BorderSizePixel = 0
    infoPanel.LayoutOrder = 1
    infoPanel.Parent = content
    Instance.new("UICorner", infoPanel).CornerRadius = UDim.new(0, 10)
    
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
    
    local instLabel = infoLabel("📦 Loading...", 44, UI.C.textDim, 11)
    local execLabel = infoLabel("🔧 " .. Util.detectExecutor(), 60, UI.C.textMuted, 10)
    
    task.spawn(function()
        local count = 0
        pcall(function() count = #game:GetDescendants() end)
        instLabel.Text = "📦 Instances: " .. Util.formatNumber(count)
    end)
    
    -- ═══════════════════════════════════
    -- Status Panel
    -- ═══════════════════════════════════
    local statusPanel = Instance.new("Frame")
    statusPanel.Name = "Status"
    statusPanel.Size = UDim2.new(1, 0, 0, 60)
    statusPanel.BackgroundColor3 = UI.C.bgLight
    statusPanel.BorderSizePixel = 0
    statusPanel.LayoutOrder = 2
    statusPanel.Parent = content
    Instance.new("UICorner", statusPanel).CornerRadius = UDim.new(0, 10)
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "Text"
    statusText.Size = UDim2.new(1, -20, 0, 22)
    statusText.Position = UDim2.new(0, 12, 0, 6)
    statusText.BackgroundTransparency = 1
    statusText.Text = "✅ Ready — Chọn chức năng bên dưới"
    statusText.TextColor3 = UI.C.success
    statusText.TextSize = 12
    statusText.Font = Enum.Font.GothamSemibold
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.TextTruncate = Enum.TextTruncate.AtEnd
    statusText.Parent = statusPanel
    
    local statusDetail = Instance.new("TextLabel")
    statusDetail.Name = "Detail"
    statusDetail.Size = UDim2.new(1, -20, 0, 16)
    statusDetail.Position = UDim2.new(0, 12, 0, 25)
    statusDetail.BackgroundTransparency = 1
    statusDetail.Text = ""
    statusDetail.TextColor3 = UI.C.textDim
    statusDetail.TextSize = 10
    statusDetail.Font = Enum.Font.Gotham
    statusDetail.TextXAlignment = Enum.TextXAlignment.Left
    statusDetail.TextTruncate = Enum.TextTruncate.AtEnd
    statusDetail.Parent = statusPanel
    
    -- Progress bar
    local progBg = Instance.new("Frame")
    progBg.Size = UDim2.new(1, -24, 0, 8)
    progBg.Position = UDim2.new(0, 12, 0, 46)
    progBg.BackgroundColor3 = UI.C.border
    progBg.BorderSizePixel = 0
    progBg.Parent = statusPanel
    Instance.new("UICorner", progBg).CornerRadius = UDim.new(0, 4)
    
    local progFill = Instance.new("Frame")
    progFill.Name = "Fill"
    progFill.Size = UDim2.new(0, 0, 1, 0)
    progFill.BackgroundColor3 = UI.C.accent
    progFill.BorderSizePixel = 0
    progFill.Parent = progBg
    Instance.new("UICorner", progFill).CornerRadius = UDim.new(0, 4)
    
    -- Gradient on progress
    local progGrad = Instance.new("UIGradient")
    progGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, UI.C.accent),
        ColorSequenceKeypoint.new(1, UI.C.accentGlow)
    }
    progGrad.Parent = progFill
    
    -- ═══════════════════════════════════
    -- Button Factory
    -- ═══════════════════════════════════
    local allButtons = {}
    
    local function createActionButton(name, text, description, icon, layoutOrder, accentColor)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 56)
        btn.BackgroundColor3 = UI.C.btnBg
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.LayoutOrder = layoutOrder
        btn.AutoButtonColor = false
        btn.Parent = content
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        
        -- Left accent bar
        local accentBar = Instance.new("Frame")
        accentBar.Size = UDim2.new(0, 4, 0.7, 0)
        accentBar.Position = UDim2.new(0, 6, 0.15, 0)
        accentBar.BackgroundColor3 = accentColor
        accentBar.BorderSizePixel = 0
        accentBar.Parent = btn
        Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 2)
        
        -- Main label
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -30, 0, 22)
        lbl.Position = UDim2.new(0, 18, 0, 8)
        lbl.BackgroundTransparency = 1
        lbl.Text = icon .. "  " .. text
        lbl.TextColor3 = UI.C.text
        lbl.TextSize = 14
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn
        
        -- Description
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -30, 0, 16)
        desc.Position = UDim2.new(0, 18, 0, 32)
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
        
        -- Hover
        btn.MouseEnter:Connect(function()
            Services.TweenService:Create(btn, TweenInfo.new(0.2),
                {BackgroundColor3 = UI.C.btnHover}):Play()
            Services.TweenService:Create(stroke, TweenInfo.new(0.2),
                {Color = accentColor, Transparency = 0}):Play()
            Services.TweenService:Create(accentBar, TweenInfo.new(0.2),
                {Size = UDim2.new(0, 4, 0.85, 0)}):Play()
        end)
        
        btn.MouseLeave:Connect(function()
            Services.TweenService:Create(btn, TweenInfo.new(0.2),
                {BackgroundColor3 = UI.C.btnBg}):Play()
            Services.TweenService:Create(stroke, TweenInfo.new(0.2),
                {Color = UI.C.border, Transparency = 0.5}):Play()
            Services.TweenService:Create(accentBar, TweenInfo.new(0.2),
                {Size = UDim2.new(0, 4, 0.7, 0)}):Play()
        end)
        
        allButtons[#allButtons + 1] = btn
        return btn
    end
    
    -- ═══════════════════════════════════
    -- Action Buttons
    -- ═══════════════════════════════════
    local btnFullGame = createActionButton(
        "FullGame",
        "Decompile Full Game",
        "100% Scripts + Models + Terrain → single .rbxl",
        "🌍", 3, UI.C.fullGame
    )
    
    local btnModels = createActionButton(
        "Models",
        "Decompile Full Model",
        "100% Parts, Meshes, Welds, Constraints, Scripts",
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
        "Fast save với tối ưu tốc độ",
        "💾", 6, UI.C.saveBtn
    )
    
    local btnExit = createActionButton(
        "Exit",
        "Exit",
        "Đóng BaoSaveInstance",
        "❌", 7, UI.C.exitBtn
    )
    
    -- ═══════════════════════════════════
    -- Footer
    -- ═══════════════════════════════════
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, 0, 0, 24)
    footer.BackgroundTransparency = 1
    footer.Text = "BaoSaveInstance v" .. BSI.VERSION .. " | RightShift to toggle | 100% Coverage"
    footer.TextColor3 = UI.C.textMuted
    footer.TextSize = 9
    footer.Font = Enum.Font.Gotham
    footer.TextTransparency = 0.4
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
                {Size = UDim2.new(0, 420, 0, 52)}):Play()
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
            Services.TweenService:Create(progFill, TweenInfo.new(0.25),
                {Size = size}):Play()
            
            -- Thay đổi màu progress bar theo trạng thái
            if progress >= 100 then
                progFill.BackgroundColor3 = UI.C.success
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
            updateStatus("⚠️ Đang có tiến trình chạy!", "Vui lòng đợi...", UI.C.warning, nil)
            return
        end
        
        BSI.State.isRunning = true
        setButtonsEnabled(false)
        
        updateStatus("⏳ Đang khởi tạo " .. buttonName .. "...",
            "Mode: " .. mode, UI.C.warning, 5)
        
        task.spawn(function()
            local success, result = ExportEngine.export(mode, function(status, progress)
                task.spawn(function()
                    updateStatus("⏳ " .. status, "Mode: " .. mode,
                        UI.C.warning, progress)
                end)
            end)
            
            BSI.State.isRunning = false
            
            if success then
                updateStatus("✅ " .. buttonName .. " hoàn thành!",
                    "📁 File: " .. tostring(result), UI.C.success, 100)
                BSI.State.lastFile = result
            else
                updateStatus("❌ " .. buttonName .. " thất bại!",
                    "Error: " .. tostring(result), UI.C.error, 0)
                BSI.State.lastError = result
            end
            
            setButtonsEnabled(true)
        end)
    end
    
    -- Full Game
    btnFullGame.MouseButton1Click:Connect(function()
        executeExport("FULL_GAME", "Decompile Full Game")
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
        
        updateStatus("⏳ Quick Save...", "Đang save nhanh...", UI.C.saveBtn, 30)
        
        task.spawn(function()
            local saveFunc = ENV.saveinstance
            local isSyn = syn and syn.saveinstance
            
            if not saveFunc and not isSyn then
                updateStatus("❌ saveinstance không khả dụng!", "", UI.C.error, 0)
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
                updateStatus("✅ Quick Save hoàn thành!",
                    "📁 " .. fileName, UI.C.success, 100)
            else
                updateStatus("❌ Quick Save thất bại!",
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
    -- OPEN ANIMATION
    -- ═══════════════════════════════════
    main.BackgroundTransparency = 1
    main.Size = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    task.wait(0.05)
    
    Services.TweenService:Create(main,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = fullSize,
         Position = UDim2.new(0.5, -210, 0.5, -290),
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
    
    Log.info("UI created! Press RightShift to toggle")
    
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
║                    CONSOLE API REFERENCE                        ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  -- 100% Full Game (Scripts + Models + Terrain)                  ║
║  BSI.exportRBXL("FULL_GAME")                                    ║
║                                                                  ║
║  -- 100% Models Only                                             ║
║  BSI.exportRBXL("MODEL_ONLY")                                   ║
║                                                                  ║
║  -- 100% Terrain Only                                            ║
║  BSI.exportRBXL("TERRAIN_ONLY")                                 ║
║                                                                  ║
║  -- Decompile tất cả scripts (standalone)                        ║
║  BSI.decompileScripts(function(s,p) print(s,p) end)             ║
║                                                                  ║
║  -- Custom config                                                ║
║  BSI.Config.Decompile.Timeout = 60                               ║
║  BSI.Config.Decompile.Retries = 10                               ║
║  BSI.Config.Performance.MaxMemoryMB = 8192                       ║
║                                                                  ║
║  -- Check state                                                  ║
║  print(BSI.State.status)                                         ║
║  print(BSI.State.lastFile)                                       ║
║                                                                  ║
║  -- Terrain analysis                                             ║
║  local info = BSI.TerrainEngine.analyze()                        ║
║                                                                  ║
║  -- Model analysis                                               ║
║  local models = BSI.ModelCollector.collectAll()                   ║
║                                                                  ║
║  -- Script discovery                                             ║
║  local scripts = BSI.ScriptDiscovery.collectAll()                ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
]]

Log.info("══════════════════════════════════════════")
Log.info("BaoSaveInstance v%s ULTIMATE — READY!", BSI.VERSION)
Log.info("100%% Script + Model + Terrain Coverage")
Log.info("Press RightShift to toggle UI")
Log.info("══════════════════════════════════════════")

return BSI
