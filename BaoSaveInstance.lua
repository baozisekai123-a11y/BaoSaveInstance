--[[
================================================================================
    BaoSaveInstance - Ultimate Roblox Decompile Tool
    Version: 3.0 (Ultimate Edition)
    
    ĐẶC ĐIỂM TIÊN TIẾN:
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ✓ Multi-API Integration (15+ Executor APIs)
    ✓ Custom SaveInstance Engine với fallback
    ✓ Full Model Decompile 100% chính xác
    ✓ Advanced Terrain Serialization
    ✓ Script Decompilation với bytecode support
    ✓ Hidden Properties Support
    ✓ Non-Archivable Instances
    ✓ Nil Instances Recovery
    ✓ Binary Format (.rbxl) Generation
    ✓ Instance Integrity Verification
    ✓ Progress Tracking với Instance Count
    ✓ Multi-threaded Processing
    ✓ Memory Optimization
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
================================================================================
]]

-- =====================================================
-- SECTION 1: CORE SERVICES & CONSTANTS
-- =====================================================

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local SoundService = game:GetService("SoundService")
local Chat = game:GetService("Chat")
local LocalizationService = game:GetService("LocalizationService")
local MaterialService = game:GetService("MaterialService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local TestService = game:GetService("TestService")
local JointsService = game:GetService("JointsService")
local InsertService = game:GetService("InsertService")
local Teams = game:GetService("Teams")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local PathfindingService = game:GetService("PathfindingService")
local TeleportService = game:GetService("TeleportService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local VRService = game:GetService("VRService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local BaoSaveInstanceGui = nil
local StatusLabel = nil
local ProgressBar = nil
local ProgressLabel = nil
local LogTextBox = nil
local InstanceCountLabel = nil

-- Version & Build Info
local VERSION = "3.0"
local BUILD = "Ultimate"
local BUILD_DATE = os.date("%Y-%m-%d")

-- Performance Constants
local BATCH_SIZE = 100 -- Instances per batch
local YIELD_INTERVAL = 50 -- Yield every N instances
local MAX_RETRIES = 5
local TIMEOUT_SECONDS = 600 -- 10 minutes max

-- =====================================================
-- SECTION 2: ADVANCED LOGGING SYSTEM
-- =====================================================

local LogSystem = {
    Logs = {},
    MaxLogs = 1000,
    LogLevel = {
        TRACE = 0,
        DEBUG = 1,
        INFO = 2,
        WARNING = 3,
        ERROR = 4,
        SUCCESS = 5,
        CRITICAL = 6
    },
    CurrentLevel = 1,
    FileLogging = false,
    ConsoleColors = {
        [0] = "@@DARK_GRAY@@",
        [1] = "@@GRAY@@",
        [2] = "@@WHITE@@",
        [3] = "@@YELLOW@@",
        [4] = "@@RED@@",
        [5] = "@@GREEN@@",
        [6] = "@@LIGHT_RED@@"
    }
}

function LogSystem:Init()
    -- Mở rconsole nếu có
    pcall(function()
        if rconsolecreate then
            rconsolecreate()
            rconsolename("BaoSaveInstance v" .. VERSION .. " - Log Console")
        end
    end)
end

function LogSystem:Add(message, level, category)
    level = level or self.LogLevel.INFO
    category = category or "SYSTEM"
    
    if level < self.CurrentLevel then return end
    
    local levelNames = {
        [0] = "TRACE",
        [1] = "DEBUG",
        [2] = "INFO",
        [3] = "WARN",
        [4] = "ERROR",
        [5] = "SUCCESS",
        [6] = "CRITICAL"
    }
    
    local timestamp = os.date("%H:%M:%S")
    local ms = math.floor((tick() % 1) * 1000)
    local logEntry = string.format("[%s.%03d][%s][%s] %s", timestamp, ms, levelNames[level] or "INFO", category, message)
    
    table.insert(self.Logs, {
        Message = logEntry,
        RawMessage = message,
        Level = level,
        Category = category,
        Time = tick(),
        Timestamp = timestamp
    })
    
    -- Giới hạn logs
    while #self.Logs > self.MaxLogs do
        table.remove(self.Logs, 1)
    end
    
    -- Console output
    if level >= self.LogLevel.ERROR then
        warn("[BaoSaveInstance] " .. message)
    elseif level >= self.LogLevel.INFO then
        print("[BaoSaveInstance] " .. message)
    end
    
    -- rconsoleprint
    pcall(function()
        if rconsoleprint then
            local color = self.ConsoleColors[level] or ""
            rconsoleprint(color .. logEntry .. "\n")
        end
    end)
    
    -- Cập nhật GUI Log
    if LogTextBox then
        pcall(function()
            local displayLogs = ""
            local startIdx = math.max(1, #self.Logs - 100)
            for i = startIdx, #self.Logs do
                displayLogs = displayLogs .. self.Logs[i].Message .. "\n"
            end
            LogTextBox.Text = displayLogs
        end)
    end
    
    return logEntry
end

function LogSystem:Trace(msg, cat) return self:Add(msg, self.LogLevel.TRACE, cat) end
function LogSystem:Debug(msg, cat) return self:Add(msg, self.LogLevel.DEBUG, cat) end
function LogSystem:Info(msg, cat) return self:Add(msg, self.LogLevel.INFO, cat) end
function LogSystem:Warn(msg, cat) return self:Add(msg, self.LogLevel.WARNING, cat) end
function LogSystem:Error(msg, cat) return self:Add(msg, self.LogLevel.ERROR, cat) end
function LogSystem:Success(msg, cat) return self:Add(msg, self.LogLevel.SUCCESS, cat) end
function LogSystem:Critical(msg, cat) return self:Add(msg, self.LogLevel.CRITICAL, cat) end

function LogSystem:Clear()
    self.Logs = {}
    if LogTextBox then
        pcall(function() LogTextBox.Text = "" end)
    end
end

function LogSystem:Export()
    local result = "=== BaoSaveInstance Log Export ===\n"
    result = result .. "Version: " .. VERSION .. "\n"
    result = result .. "Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
    result = result .. "Total Logs: " .. #self.Logs .. "\n"
    result = result .. "================================\n\n"
    
    for _, log in ipairs(self.Logs) do
        result = result .. log.Message .. "\n"
    end
    
    return result
end

-- =====================================================
-- SECTION 3: COMPREHENSIVE EXECUTOR API DETECTION
-- =====================================================

local ExecutorAPI = {
    -- Basic Info
    Name = "Unknown",
    Version = "Unknown",
    Platform = "Unknown",
    
    -- SaveInstance
    HasSaveInstance = false,
    SaveInstanceFunc = nil,
    SaveInstanceVersion = "Unknown",
    SaveInstanceSource = "None",
    
    -- File System
    HasWriteFile = false,
    HasReadFile = false,
    HasAppendFile = false,
    HasMakeFolder = false,
    HasDelFile = false,
    HasDelFolder = false,
    HasIsFile = false,
    HasIsFolder = false,
    HasListFiles = false,
    HasLoadFile = false,
    
    WriteFileFunc = nil,
    ReadFileFunc = nil,
    AppendFileFunc = nil,
    MakeFolderFunc = nil,
    DelFileFunc = nil,
    IsFileFunc = nil,
    IsFolderFunc = nil,
    ListFilesFunc = nil,
    
    -- Instance Functions
    HasGetInstances = false,
    HasGetNilInstances = false,
    HasGetScripts = false,
    HasGetRunningScripts = false,
    HasGetLoadedModules = false,
    HasGetConnections = false,
    HasGetGC = false,
    HasGetHiddenProperty = false,
    HasSetHiddenProperty = false,
    HasGetProperties = false,
    HasSetClipboard = false,
    HasFireSignal = false,
    HasGetSignalConnections = false,
    
    GetInstancesFunc = nil,
    GetNilInstancesFunc = nil,
    GetScriptsFunc = nil,
    GetGCFunc = nil,
    GetHiddenPropertyFunc = nil,
    SetHiddenPropertyFunc = nil,
    GetPropertiesFunc = nil,
    SetClipboardFunc = nil,
    
    -- Script Functions
    HasDecompile = false,
    HasGetScriptBytecode = false,
    HasGetScriptHash = false,
    HasGetScriptClosure = false,
    HasIsLClosure = false,
    HasNewCClosure = false,
    HasHookFunction = false,
    HasGetUpvalue = false,
    HasSetUpvalue = false,
    HasGetConstant = false,
    HasSetConstant = false,
    
    DecompileFunc = nil,
    GetScriptBytecodeFunc = nil,
    
    -- Environment
    HasGetGenv = false,
    HasGetRenv = false,
    HasGetSenv = false,
    HasGetMenv = false,
    HasGetFenv = false,
    HasSetFenv = false,
    HasGetRawMetatable = false,
    HasSetRawMetatable = false,
    HasSetReadOnly = false,
    HasIsReadOnly = false,
    
    GetGenvFunc = nil,
    GetRenvFunc = nil,
    GetSenvFunc = nil,
    GetRawMetatableFunc = nil,
    
    -- Drawing
    HasDrawing = false,
    HasGetRenderProperty = false,
    HasIsRenderObject = false,
    
    -- Networking
    HasRequest = false,
    HasWebSocket = false,
    HasGetHWID = false,
    
    RequestFunc = nil,
    WebSocketFunc = nil,
    
    -- Misc
    HasCloneRef = false,
    HasCompareInstances = false,
    HasCacheInvalidate = false,
    HasCacheReplace = false,
    HasIsExecutorClosure = false,
    HasCheckerClosure = false,
    HasFireClickDetector = false,
    HasFireProximityPrompt = false,
    HasFireTouchInterest = false,
    HasGetCustomAsset = false,
    HasGetSynAsset = false,
    HasMessageBox = false,
    HasSetFPSCap = false,
    HasQueue = false,
    
    CloneRefFunc = nil,
    GetCustomAssetFunc = nil,
    
    -- Capabilities
    SupportsOptions = false,
    SupportsTerrain = false,
    SupportsScripts = false,
    SupportsCallbacks = false,
    SupportsBinary = true,
    SupportsTimeout = false,
    SupportsIgnoreList = false,
    SupportsDecompileMode = false,
    SupportsNilInstances = false,
    SupportsNotArchivable = false,
    
    -- Paths
    WorkspaceFolder = "workspace",
    AutoImportFolder = "",
    
    -- Features List
    Features = {},
    
    -- Raw function references
    RawFunctions = {}
}

-- Danh sách đầy đủ các executor và signatures
local ExecutorSignatures = {
    -- ============ SYNAPSE X ============
    {
        name = "Synapse X",
        priority = 100,
        checks = {
            function() return syn ~= nil end,
            function() return syn.saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Synapse X"
            ExecutorAPI.SaveInstanceSource = "Synapse"
            
            pcall(function()
                ExecutorAPI.Version = syn.version or "Unknown"
            end)
            
            if syn.saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = syn.saveinstance
                ExecutorAPI.SupportsOptions = true
                ExecutorAPI.SupportsTerrain = true
                ExecutorAPI.SupportsScripts = true
                ExecutorAPI.SupportsCallbacks = true
                ExecutorAPI.SupportsIgnoreList = true
                ExecutorAPI.SupportsDecompileMode = true
                ExecutorAPI.SupportsNilInstances = true
                ExecutorAPI.SupportsNotArchivable = true
                ExecutorAPI.SaveInstanceVersion = "Synapse SaveInstance"
            end
            
            if syn.write_file then
                ExecutorAPI.HasWriteFile = true
                ExecutorAPI.WriteFileFunc = syn.write_file
            end
            
            if syn.read_file then
                ExecutorAPI.HasReadFile = true
                ExecutorAPI.ReadFileFunc = syn.read_file
            end
            
            if syn.request then
                ExecutorAPI.HasRequest = true
                ExecutorAPI.RequestFunc = syn.request
            end
            
            if syn.websocket then
                ExecutorAPI.HasWebSocket = true
                ExecutorAPI.WebSocketFunc = syn.websocket
            end
            
            if syn.crypt then
                ExecutorAPI.Features["Crypt"] = true
            end
            
            if syn.cache_invalidate then
                ExecutorAPI.HasCacheInvalidate = true
            end
            
            if syn.cache_replace then
                ExecutorAPI.HasCacheReplace = true
            end
            
            return true
        end
    },
    
    -- ============ SYNAPSE V3 ============
    {
        name = "Synapse V3",
        priority = 99,
        checks = {
            function() return Synapse ~= nil end,
            function() return Synapse.SaveInstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Synapse V3"
            ExecutorAPI.SaveInstanceSource = "Synapse V3"
            ExecutorAPI.Version = "V3"
            
            if Synapse.SaveInstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = Synapse.SaveInstance
                ExecutorAPI.SupportsOptions = true
                ExecutorAPI.SupportsTerrain = true
                ExecutorAPI.SupportsScripts = true
                ExecutorAPI.SupportsCallbacks = true
            end
            
            return true
        end
    },
    
    -- ============ SCRIPT-WARE ============
    {
        name = "Script-Ware",
        priority = 95,
        checks = {
            function() return (SW_LOADED == true) or (ScriptWare ~= nil) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Script-Ware"
            ExecutorAPI.SaveInstanceSource = "Script-Ware"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
                ExecutorAPI.SupportsTerrain = true
                ExecutorAPI.SupportsScripts = true
                ExecutorAPI.SupportsIgnoreList = true
            end
            
            return true
        end
    },
    
    -- ============ KRNL ============
    {
        name = "KRNL",
        priority = 90,
        checks = {
            function() return KRNL_LOADED == true end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "KRNL"
            ExecutorAPI.SaveInstanceSource = "KRNL"
            ExecutorAPI.Version = "Latest"
            ExecutorAPI.WorkspaceFolder = "krnl/workspace"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
                ExecutorAPI.SupportsTerrain = true
                ExecutorAPI.SupportsScripts = true
            end
            
            return true
        end
    },
    
    -- ============ FLUXUS ============
    {
        name = "Fluxus",
        priority = 85,
        checks = {
            function() return (fluxus ~= nil) or (FLUXUS_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Fluxus"
            ExecutorAPI.SaveInstanceSource = "Fluxus"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
                ExecutorAPI.SupportsTerrain = true
                ExecutorAPI.SupportsScripts = true
            end
            
            return true
        end
    },
    
    -- ============ HYDROGEN ============
    {
        name = "Hydrogen",
        priority = 84,
        checks = {
            function() return (Hydrogen ~= nil) or (HYDROGEN_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Hydrogen"
            ExecutorAPI.SaveInstanceSource = "Hydrogen"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
                ExecutorAPI.SupportsTerrain = true
            end
            
            return true
        end
    },
    
    -- ============ DELTA ============
    {
        name = "Delta",
        priority = 83,
        checks = {
            function() return (Delta ~= nil) or (DELTA_LOADED == true) or (delta ~= nil) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Delta"
            ExecutorAPI.SaveInstanceSource = "Delta"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
                ExecutorAPI.SupportsTerrain = true
            end
            
            return true
        end
    },
    
    -- ============ CODEX ============
    {
        name = "Codex",
        priority = 82,
        checks = {
            function() return (Codex ~= nil) or (CODEX_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Codex"
            ExecutorAPI.SaveInstanceSource = "Codex"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
                ExecutorAPI.SupportsTerrain = true
            end
            
            return true
        end
    },
    
    -- ============ SOLARA ============
    {
        name = "Solara",
        priority = 81,
        checks = {
            function() return (Solara ~= nil) or (SOLARA_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Solara"
            ExecutorAPI.SaveInstanceSource = "Solara"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
                ExecutorAPI.SupportsTerrain = true
            end
            
            return true
        end
    },
    
    -- ============ WAVE ============
    {
        name = "Wave",
        priority = 80,
        checks = {
            function() return (Wave ~= nil) or (WAVE_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Wave"
            ExecutorAPI.SaveInstanceSource = "Wave"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
                ExecutorAPI.SupportsTerrain = true
            end
            
            return true
        end
    },
    
    -- ============ ARCEUS X ============
    {
        name = "Arceus X",
        priority = 75,
        checks = {
            function() return (Arceus ~= nil) or (ARCEUS_LOADED == true) or (ArceusX ~= nil) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Arceus X"
            ExecutorAPI.SaveInstanceSource = "Arceus"
            ExecutorAPI.Version = "Latest"
            ExecutorAPI.Platform = "Mobile"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
                ExecutorAPI.SupportsTerrain = false -- Limited terrain support
            end
            
            return true
        end
    },
    
    -- ============ VEGAX ============
    {
        name = "VegaX",
        priority = 74,
        checks = {
            function() return (VegaX ~= nil) or (VEGAX_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "VegaX"
            ExecutorAPI.SaveInstanceSource = "VegaX"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
            end
            
            return true
        end
    },
    
    -- ============ COMET ============
    {
        name = "Comet",
        priority = 73,
        checks = {
            function() return (Comet ~= nil) or (COMET_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Comet"
            ExecutorAPI.SaveInstanceSource = "Comet"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
                ExecutorAPI.SupportsTerrain = true
            end
            
            return true
        end
    },
    
    -- ============ ELECTRON ============
    {
        name = "Electron",
        priority = 72,
        checks = {
            function() return (Electron ~= nil) or (ELECTRON_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Electron"
            ExecutorAPI.SaveInstanceSource = "Electron"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
            end
            
            return true
        end
    },
    
    -- ============ SENTINEL ============
    {
        name = "Sentinel",
        priority = 71,
        checks = {
            function() return (Sentinel ~= nil) or (SENTINEL_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Sentinel"
            ExecutorAPI.SaveInstanceSource = "Sentinel"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
                ExecutorAPI.SupportsTerrain = true
            end
            
            return true
        end
    },
    
    -- ============ CELERY ============
    {
        name = "Celery",
        priority = 70,
        checks = {
            function() return (Celery ~= nil) or (CELERY_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Celery"
            ExecutorAPI.SaveInstanceSource = "Celery"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
            end
            
            return true
        end
    },
    
    -- ============ EVON ============
    {
        name = "Evon",
        priority = 69,
        checks = {
            function() return (evon ~= nil) or (EVON_LOADED == true) or (Evon ~= nil) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Evon"
            ExecutorAPI.SaveInstanceSource = "Evon"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
            end
            
            return true
        end
    },
    
    -- ============ OXYGEN U ============
    {
        name = "Oxygen U",
        priority = 68,
        checks = {
            function() return (OxygenU ~= nil) or (OXYGEN_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Oxygen U"
            ExecutorAPI.SaveInstanceSource = "OxygenU"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
            end
            
            return true
        end
    },
    
    -- ============ TRIGON ============
    {
        name = "Trigon",
        priority = 67,
        checks = {
            function() return (Trigon ~= nil) or (TRIGON_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Trigon"
            ExecutorAPI.SaveInstanceSource = "Trigon"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
            end
            
            return true
        end
    },
    
    -- ============ SIRHURT ============
    {
        name = "SirHurt",
        priority = 66,
        checks = {
            function() return (SirHurt ~= nil) or (SIRHURT_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "SirHurt"
            ExecutorAPI.SaveInstanceSource = "SirHurt"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
            end
            
            return true
        end
    },
    
    -- ============ TEMPLE ============
    {
        name = "Temple",
        priority = 65,
        checks = {
            function() return (Temple ~= nil) or (TEMPLE_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Temple"
            ExecutorAPI.SaveInstanceSource = "Temple"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
            end
            
            return true
        end
    },
    
    -- ============ ASPECT ============
    {
        name = "Aspect",
        priority = 64,
        checks = {
            function() return (Aspect ~= nil) or (ASPECT_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Aspect"
            ExecutorAPI.SaveInstanceSource = "Aspect"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
            end
            
            return true
        end
    },
    
    -- ============ COCO Z ============
    {
        name = "Coco Z",
        priority = 63,
        checks = {
            function() return (CocoZ ~= nil) or (COCOZ_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Coco Z"
            ExecutorAPI.SaveInstanceSource = "CocoZ"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
            end
            
            return true
        end
    },
    
    -- ============ ZORARA ============
    {
        name = "Zorara",
        priority = 62,
        checks = {
            function() return (Zorara ~= nil) or (ZORARA_LOADED == true) end,
            function() return saveinstance ~= nil end
        },
        setup = function()
            ExecutorAPI.Name = "Zorara"
            ExecutorAPI.SaveInstanceSource = "Zorara"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = true
            end
            
            return true
        end
    },
    
    -- ============ JJSploit ============
    {
        name = "JJSploit",
        priority = 50,
        checks = {
            function() return (JJSploit ~= nil) or (JJSPLOIT_LOADED == true) end
        },
        setup = function()
            ExecutorAPI.Name = "JJSploit"
            ExecutorAPI.SaveInstanceSource = "JJSploit"
            ExecutorAPI.Version = "Latest"
            
            if saveinstance then
                ExecutorAPI.HasSaveInstance = true
                ExecutorAPI.SaveInstanceFunc = saveinstance
                ExecutorAPI.SupportsOptions = false
                ExecutorAPI.SupportsTerrain = false
            end
            
            return true
        end
    },
    
    -- ============ GENERIC SAVEINSTANCE ============
    {
        name = "Generic (saveinstance)",
        priority = 20,
        checks = {
            function() return saveinstance ~= nil end
        },
        setup = function()
            if ExecutorAPI.Name == "Unknown" then
                ExecutorAPI.Name = "Generic Executor"
            end
            ExecutorAPI.SaveInstanceSource = "Global"
            
            ExecutorAPI.HasSaveInstance = true
            ExecutorAPI.SaveInstanceFunc = saveinstance
            ExecutorAPI.SupportsOptions = true
            ExecutorAPI.SupportsTerrain = true
            
            return true
        end
    },
    
    -- ============ GENERIC SAVEPLACE ============
    {
        name = "Generic (saveplace)",
        priority = 15,
        checks = {
            function() return saveplace ~= nil end
        },
        setup = function()
            if ExecutorAPI.Name == "Unknown" then
                ExecutorAPI.Name = "SavePlace Executor"
            end
            ExecutorAPI.SaveInstanceSource = "saveplace"
            
            ExecutorAPI.HasSaveInstance = true
            ExecutorAPI.SaveInstanceFunc = function(options)
                local fileName = options
                if type(options) == "table" then
                    fileName = options.FileName or options.Filename or options.FilePath or "game.rbxl"
                end
                return saveplace(game, fileName)
            end
            ExecutorAPI.SupportsOptions = false
            ExecutorAPI.SupportsTerrain = true
            
            return true
        end
    },
    
    -- ============ GENERIC SAVEGAME ============
    {
        name = "Generic (savegame)",
        priority = 10,
        checks = {
            function() return savegame ~= nil end
        },
        setup = function()
            if ExecutorAPI.Name == "Unknown" then
                ExecutorAPI.Name = "SaveGame Executor"
            end
            ExecutorAPI.SaveInstanceSource = "savegame"
            
            ExecutorAPI.HasSaveInstance = true
            ExecutorAPI.SaveInstanceFunc = function(options)
                local fileName = options
                if type(options) == "table" then
                    fileName = options.FileName or options.Filename or "game.rbxl"
                end
                return savegame(game, fileName)
            end
            ExecutorAPI.SupportsOptions = false
            
            return true
        end
    }
}

-- Danh sách các hàm cần kiểm tra
local FunctionsList = {
    -- File System
    {name = "writefile", aliases = {"write_file"}, category = "FileSystem", callback = function(f)
        ExecutorAPI.HasWriteFile = true
        ExecutorAPI.WriteFileFunc = f
    end},
    {name = "readfile", aliases = {"read_file"}, category = "FileSystem", callback = function(f)
        ExecutorAPI.HasReadFile = true
        ExecutorAPI.ReadFileFunc = f
    end},
    {name = "appendfile", aliases = {"append_file"}, category = "FileSystem", callback = function(f)
        ExecutorAPI.HasAppendFile = true
        ExecutorAPI.AppendFileFunc = f
    end},
    {name = "makefolder", aliases = {"make_folder", "mkdir", "createfolder"}, category = "FileSystem", callback = function(f)
        ExecutorAPI.HasMakeFolder = true
        ExecutorAPI.MakeFolderFunc = f
    end},
    {name = "delfolder", aliases = {"del_folder", "rmdir", "deletefolder"}, category = "FileSystem", callback = function(f)
        ExecutorAPI.HasDelFolder = true
    end},
    {name = "delfile", aliases = {"del_file", "deletefile", "rmfile"}, category = "FileSystem", callback = function(f)
        ExecutorAPI.HasDelFile = true
        ExecutorAPI.DelFileFunc = f
    end},
    {name = "isfile", aliases = {"is_file"}, category = "FileSystem", callback = function(f)
        ExecutorAPI.HasIsFile = true
        ExecutorAPI.IsFileFunc = f
    end},
    {name = "isfolder", aliases = {"is_folder"}, category = "FileSystem", callback = function(f)
        ExecutorAPI.HasIsFolder = true
        ExecutorAPI.IsFolderFunc = f
    end},
    {name = "listfiles", aliases = {"list_files", "readdir"}, category = "FileSystem", callback = function(f)
        ExecutorAPI.HasListFiles = true
        ExecutorAPI.ListFilesFunc = f
    end},
    {name = "loadfile", aliases = {"load_file", "dofile"}, category = "FileSystem", callback = function(f)
        ExecutorAPI.HasLoadFile = true
    end},
    
    -- Instance Functions
    {name = "getinstances", aliases = {"get_instances"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasGetInstances = true
        ExecutorAPI.GetInstancesFunc = f
    end},
    {name = "getnilinstances", aliases = {"get_nil_instances"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasGetNilInstances = true
        ExecutorAPI.GetNilInstancesFunc = f
    end},
    {name = "getscripts", aliases = {"get_scripts"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasGetScripts = true
        ExecutorAPI.GetScriptsFunc = f
    end},
    {name = "getrunningscripts", aliases = {"get_running_scripts"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasGetRunningScripts = true
    end},
    {name = "getloadedmodules", aliases = {"get_loaded_modules"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasGetLoadedModules = true
    end},
    {name = "getconnections", aliases = {"get_connections"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasGetConnections = true
    end},
    {name = "firesignal", aliases = {"fire_signal"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasFireSignal = true
    end},
    {name = "getsignalconnections", aliases = {"get_signal_connections"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasGetSignalConnections = true
    end},
    {name = "getgc", aliases = {"get_gc"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasGetGC = true
        ExecutorAPI.GetGCFunc = f
    end},
    {name = "gethiddenproperty", aliases = {"get_hidden_property"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasGetHiddenProperty = true
        ExecutorAPI.GetHiddenPropertyFunc = f
    end},
    {name = "sethiddenproperty", aliases = {"set_hidden_property"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasSetHiddenProperty = true
        ExecutorAPI.SetHiddenPropertyFunc = f
    end},
    {name = "getproperties", aliases = {"get_properties"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasGetProperties = true
        ExecutorAPI.GetPropertiesFunc = f
    end},
    {name = "gethiddenproperties", aliases = {"get_hidden_properties"}, category = "Instance", callback = function(f)
        ExecutorAPI.Features["HiddenProperties"] = true
    end},
    {name = "setclipboard", aliases = {"set_clipboard", "toclipboard", "to_clipboard"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasSetClipboard = true
        ExecutorAPI.SetClipboardFunc = f
    end},
    {name = "cloneref", aliases = {"clone_ref"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasCloneRef = true
        ExecutorAPI.CloneRefFunc = f
    end},
    {name = "compareinstances", aliases = {"compare_instances"}, category = "Instance", callback = function(f)
        ExecutorAPI.HasCompareInstances = true
    end},
    
    -- Script Functions
    {name = "decompile", aliases = {"decompiler"}, category = "Script", callback = function(f)
        ExecutorAPI.HasDecompile = true
        ExecutorAPI.DecompileFunc = f
        ExecutorAPI.SupportsScripts = true
    end},
    {name = "getscriptbytecode", aliases = {"get_script_bytecode", "dumpstring"}, category = "Script", callback = function(f)
        ExecutorAPI.HasGetScriptBytecode = true
        ExecutorAPI.GetScriptBytecodeFunc = f
    end},
    {name = "getscripthash", aliases = {"get_script_hash"}, category = "Script", callback = function(f)
        ExecutorAPI.HasGetScriptHash = true
    end},
    {name = "getscriptclosure", aliases = {"get_script_closure", "getscriptfunction"}, category = "Script", callback = function(f)
        ExecutorAPI.HasGetScriptClosure = true
    end},
    {name = "islclosure", aliases = {"is_l_closure"}, category = "Script", callback = function(f)
        ExecutorAPI.HasIsLClosure = true
    end},
    {name = "newcclosure", aliases = {"new_c_closure"}, category = "Script", callback = function(f)
        ExecutorAPI.HasNewCClosure = true
    end},
    {name = "hookfunction", aliases = {"hook_function", "replaceclosure", "detour_function"}, category = "Script", callback = function(f)
        ExecutorAPI.HasHookFunction = true
    end},
    {name = "getupvalue", aliases = {"get_upvalue", "debug.getupvalue"}, category = "Script", callback = function(f)
        ExecutorAPI.HasGetUpvalue = true
    end},
    {name = "setupvalue", aliases = {"set_upvalue", "debug.setupvalue"}, category = "Script", callback = function(f)
        ExecutorAPI.HasSetUpvalue = true
    end},
    {name = "getconstant", aliases = {"get_constant", "debug.getconstant"}, category = "Script", callback = function(f)
        ExecutorAPI.HasGetConstant = true
    end},
    {name = "setconstant", aliases = {"set_constant", "debug.setconstant"}, category = "Script", callback = function(f)
        ExecutorAPI.HasSetConstant = true
    end},
    
    -- Environment
    {name = "getgenv", aliases = {"get_genv"}, category = "Environment", callback = function(f)
        ExecutorAPI.HasGetGenv = true
        ExecutorAPI.GetGenvFunc = f
    end},
    {name = "getrenv", aliases = {"get_renv"}, category = "Environment", callback = function(f)
        ExecutorAPI.HasGetRenv = true
        ExecutorAPI.GetRenvFunc = f
    end},
    {name = "getsenv", aliases = {"get_senv"}, category = "Environment", callback = function(f)
        ExecutorAPI.HasGetSenv = true
        ExecutorAPI.GetSenvFunc = f
    end},
    {name = "getmenv", aliases = {"get_menv"}, category = "Environment", callback = function(f)
        ExecutorAPI.HasGetMenv = true
    end},
    {name = "getfenv", aliases = {"get_fenv"}, category = "Environment", callback = function(f)
        ExecutorAPI.HasGetFenv = true
    end},
    {name = "setfenv", aliases = {"set_fenv"}, category = "Environment", callback = function(f)
        ExecutorAPI.HasSetFenv = true
    end},
    {name = "getrawmetatable", aliases = {"get_raw_metatable"}, category = "Environment", callback = function(f)
        ExecutorAPI.HasGetRawMetatable = true
        ExecutorAPI.GetRawMetatableFunc = f
    end},
    {name = "setrawmetatable", aliases = {"set_raw_metatable"}, category = "Environment", callback = function(f)
        ExecutorAPI.HasSetRawMetatable = true
    end},
    {name = "setreadonly", aliases = {"set_readonly", "make_readonly"}, category = "Environment", callback = function(f)
        ExecutorAPI.HasSetReadOnly = true
    end},
    {name = "isreadonly", aliases = {"is_readonly"}, category = "Environment", callback = function(f)
        ExecutorAPI.HasIsReadOnly = true
    end},
    
    -- Drawing
    {name = "Drawing", aliases = {"drawing"}, category = "Drawing", callback = function(f)
        ExecutorAPI.HasDrawing = true
    end},
    {name = "getrenderproperty", aliases = {"get_render_property"}, category = "Drawing", callback = function(f)
        ExecutorAPI.HasGetRenderProperty = true
    end},
    {name = "isrenderobj", aliases = {"is_render_object"}, category = "Drawing", callback = function(f)
        ExecutorAPI.HasIsRenderObject = true
    end},
    
    -- Networking
    {name = "request", aliases = {"http_request", "http.request"}, category = "Network", callback = function(f)
        ExecutorAPI.HasRequest = true
        ExecutorAPI.RequestFunc = f
    end},
    {name = "WebSocket", aliases = {"websocket"}, category = "Network", callback = function(f)
        ExecutorAPI.HasWebSocket = true
        ExecutorAPI.WebSocketFunc = f
    end},
    {name = "gethwid", aliases = {"get_hwid", "gethardwareid"}, category = "Network", callback = function(f)
        ExecutorAPI.HasGetHWID = true
    end},
    
    -- Misc
    {name = "getcustomasset", aliases = {"get_custom_asset"}, category = "Misc", callback = function(f)
        ExecutorAPI.HasGetCustomAsset = true
        ExecutorAPI.GetCustomAssetFunc = f
    end},
    {name = "getsynasset", aliases = {"get_syn_asset"}, category = "Misc", callback = function(f)
        ExecutorAPI.HasGetSynAsset = true
    end},
    {name = "fireclickdetector", aliases = {"fire_click_detector"}, category = "Misc", callback = function(f)
        ExecutorAPI.HasFireClickDetector = true
    end},
    {name = "fireproximityprompt", aliases = {"fire_proximity_prompt"}, category = "Misc", callback = function(f)
        ExecutorAPI.HasFireProximityPrompt = true
    end},
    {name = "firetouchinterest", aliases = {"fire_touch_interest"}, category = "Misc", callback = function(f)
        ExecutorAPI.HasFireTouchInterest = true
    end},
    {name = "isexecutorclosure", aliases = {"is_executor_closure", "checkclosure"}, category = "Misc", callback = function(f)
        ExecutorAPI.HasIsExecutorClosure = true
    end},
    {name = "messagebox", aliases = {"message_box"}, category = "Misc", callback = function(f)
        ExecutorAPI.HasMessageBox = true
    end},
    {name = "setfpscap", aliases = {"set_fps_cap"}, category = "Misc", callback = function(f)
        ExecutorAPI.HasSetFPSCap = true
    end},
    {name = "queue_on_teleport", aliases = {"queueonteleport"}, category = "Misc", callback = function(f)
        ExecutorAPI.HasQueue = true
    end},
}

-- Hàm tìm function theo tên
local function FindFunction(name)
    -- Thử global
    local success, result = pcall(function()
        return getfenv()[name]
    end)
    if success and result and type(result) == "function" then
        return result
    end
    
    -- Thử _G
    success, result = pcall(function()
        return _G[name]
    end)
    if success and result and type(result) == "function" then
        return result
    end
    
    -- Thử shared
    success, result = pcall(function()
        return shared[name]
    end)
    if success and result and type(result) == "function" then
        return result
    end
    
    -- Thử getgenv nếu có
    if ExecutorAPI.GetGenvFunc then
        success, result = pcall(function()
            return ExecutorAPI.GetGenvFunc()[name]
        end)
        if success and result and type(result) == "function" then
            return result
        end
    end
    
    return nil
end

-- Hàm detect tất cả APIs
local function DetectAllAPIs()
    LogSystem:Info("═══════════════════════════════════════════", "API")
    LogSystem:Info("    BẮT ĐẦU DETECT EXECUTOR APIs", "API")
    LogSystem:Info("═══════════════════════════════════════════", "API")
    
    local startTime = tick()
    
    -- Reset API info
    ExecutorAPI.Name = "Unknown"
    ExecutorAPI.Version = "Unknown"
    ExecutorAPI.HasSaveInstance = false
    ExecutorAPI.Features = {}
    
    -- Thử identify executor
    pcall(function()
        if identifyexecutor then
            local name, version = identifyexecutor()
            ExecutorAPI.Name = tostring(name or "Unknown")
            ExecutorAPI.Version = tostring(version or "Unknown")
            LogSystem:Info("identifyexecutor() => " .. ExecutorAPI.Name .. " v" .. ExecutorAPI.Version, "API")
        end
    end)
    
    pcall(function()
        if getexecutorname then
            local name = getexecutorname()
            if ExecutorAPI.Name == "Unknown" then
                ExecutorAPI.Name = tostring(name)
            end
            LogSystem:Debug("getexecutorname() => " .. tostring(name), "API")
        end
    end)
    
    -- Sort signatures by priority (highest first)
    table.sort(ExecutorSignatures, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
    end)
    
    -- Thử từng executor signature
    for _, sig in ipairs(ExecutorSignatures) do
        local allChecksPass = true
        
        for _, checkFunc in ipairs(sig.checks) do
            local success, result = pcall(checkFunc)
            if not success or not result then
                allChecksPass = false
                break
            end
        end
        
        if allChecksPass then
            LogSystem:Debug("Trying signature: " .. sig.name, "API")
            local setupSuccess = pcall(sig.setup)
            if setupSuccess and ExecutorAPI.HasSaveInstance then
                LogSystem:Success("✓ Matched: " .. sig.name, "API")
                break
            end
        end
    end
    
    -- Scan tất cả functions
    LogSystem:Info("Scanning executor functions...", "API")
    local functionCount = 0
    
    for _, funcInfo in ipairs(FunctionsList) do
        local found = false
        local foundFunc = nil
        
        -- Thử tên chính
        foundFunc = FindFunction(funcInfo.name)
        if foundFunc then
            found = true
        else
            -- Thử aliases
            for _, alias in ipairs(funcInfo.aliases or {}) do
                foundFunc = FindFunction(alias)
                if foundFunc then
                    found = true
                    break
                end
            end
        end
        
        if found and funcInfo.callback then
            pcall(funcInfo.callback, foundFunc)
            ExecutorAPI.Features[funcInfo.name] = true
            ExecutorAPI.RawFunctions[funcInfo.name] = foundFunc
            functionCount = functionCount + 1
            LogSystem:Debug("  ✓ " .. funcInfo.name .. " (" .. funcInfo.category .. ")", "API")
        end
    end
    
    -- Detect platform
    pcall(function()
        local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        ExecutorAPI.Platform = isMobile and "Mobile" or "Desktop"
    end)
    
    -- Tính thời gian
    local detectTime = tick() - startTime
    
    -- Log kết quả
    LogSystem:Info("═══════════════════════════════════════════", "API")
    LogSystem:Success("    DETECT HOÀN TẤT", "API")
    LogSystem:Info("═══════════════════════════════════════════", "API")
    LogSystem:Info("Executor: " .. ExecutorAPI.Name .. " v" .. ExecutorAPI.Version, "API")
    LogSystem:Info("Platform: " .. ExecutorAPI.Platform, "API")
    LogSystem:Info("SaveInstance: " .. (ExecutorAPI.HasSaveInstance and "✓ Yes" or "✗ No"), "API")
    LogSystem:Info("SaveInstance Source: " .. ExecutorAPI.SaveInstanceSource, "API")
    LogSystem:Info("Functions Found: " .. functionCount, "API")
    LogSystem:Info("Detect Time: " .. string.format("%.3f", detectTime) .. "s", "API")
    LogSystem:Info("═══════════════════════════════════════════", "API")
    
    -- Capabilities summary
    LogSystem:Debug("--- Capabilities ---", "API")
    LogSystem:Debug("Options Support: " .. tostring(ExecutorAPI.SupportsOptions), "API")
    LogSystem:Debug("Terrain Support: " .. tostring(ExecutorAPI.SupportsTerrain), "API")
    LogSystem:Debug("Scripts Support: " .. tostring(ExecutorAPI.SupportsScripts), "API")
    LogSystem:Debug("Callbacks Support: " .. tostring(ExecutorAPI.SupportsCallbacks), "API")
    LogSystem:Debug("IgnoreList Support: " .. tostring(ExecutorAPI.SupportsIgnoreList), "API")
    LogSystem:Debug("NilInstances Support: " .. tostring(ExecutorAPI.SupportsNilInstances), "API")
    LogSystem:Debug("NotArchivable Support: " .. tostring(ExecutorAPI.SupportsNotArchivable), "API")
    
    return ExecutorAPI
end

-- =====================================================
-- SECTION 4: ADVANCED SAVE OPTIONS
-- =====================================================

local SaveConfig = {
    -- ═══════════ FILE SETTINGS ═══════════
    FileName = "",
    FilePath = "",
    FileExtension = ".rbxl",
    
    -- ═══════════ DECOMPILE SETTINGS ═══════════
    Decompile = true,
    DecompileMode = 2, -- 0 = None, 1 = Fast, 2 = Full
    DecompileTimeout = 30,
    DecompileJobless = false,
    ScriptCache = true,
    DecompileIgnore = {},
    
    -- ═══════════ INSTANCE SETTINGS ═══════════
    NilInstances = true,
    NilInstancesFix = true,
    SaveNonCreatable = true,
    SaveNotArchivable = true,
    IgnoreNotArchivable = false,
    SaveCacheProvider = false,
    
    -- ═══════════ PROPERTY SETTINGS ═══════════
    IgnoreDefaultProps = true,
    IgnoreDefaultProperties = true,
    IgnoreSharedStrings = false,
    SharedStringOverwrite = false,
    IgnorePropertiesOfNotScriptsOnScriptsMode = false,
    SaveHiddenProperties = true,
    
    -- ═══════════ PLAYER SETTINGS ═══════════
    SavePlayers = false,
    RemovePlayers = true,
    IsolateLocalPlayer = true,
    IsolateLocalPlayerCharacter = true,
    RemovePlayerCharacters = true,
    IsolateStarterPlayer = true,
    
    -- ═══════════ SERVICE SETTINGS ═══════════
    SaveServices = true,
    
    -- Core Services
    SaveWorkspace = true,
    SaveLighting = true,
    SaveReplicatedFirst = true,
    SaveReplicatedStorage = true,
    SaveServerScriptService = false, -- Không thể access
    SaveServerStorage = false, -- Không thể access
    SaveStarterGui = true,
    SaveStarterPack = true,
    SaveStarterPlayer = true,
    SaveTeams = true,
    SaveSoundService = true,
    SaveChat = true,
    SaveLocalizationService = true,
    SaveMaterialService = true,
    SaveTestService = false,
    SaveJointsService = false,
    SaveInsertService = false,
    SaveProximityPromptService = false,
    
    -- ═══════════ TERRAIN SETTINGS ═══════════
    SaveTerrain = true,
    TerrainCopyEnabled = true,
    TerrainRegionCopy = true,
    TerrainMaterialColors = true,
    TerrainWaterProperties = true,
    
    -- ═══════════ FORMAT SETTINGS ═══════════
    Binary = true,
    BinaryFormat = true,
    XMLFormat = false,
    CompactMode = false,
    
    -- ═══════════ OPTIMIZATION SETTINGS ═══════════
    MaxThreads = 4,
    BatchSize = 100,
    YieldInterval = 50,
    MemoryLimit = 2048, -- MB
    Timeout = 600, -- seconds
    
    -- ═══════════ MODE SETTINGS ═══════════
    Mode = "full", -- "full", "optimized", "scripts", "terrain"
    Object = nil, -- Default to game
    
    -- ═══════════ CALLBACKS ═══════════
    ShowStatus = true,
    Callback = nil,
    StatusCallback = nil,
    ProgressCallback = nil,
    InstanceCallback = nil,
    ErrorCallback = nil,
    
    -- ═══════════ EXCLUDE/INCLUDE ═══════════
    IgnoreList = {},
    Ignore = {},
    ExcludeDescendantsOf = {},
    ExcludeClassNames = {},
    IncludeClassNames = {},
    
    -- ═══════════ ADVANCED ═══════════
    SafeMode = false,
    DebugMode = false,
    AntiIdle = true,
    DisableCompression = false,
    CopyWorkspaceInstances = true,
    
    -- ═══════════ CUSTOM ═══════════
    CustomOptions = {},
    
    -- ═══════════ METADATA ═══════════
    IncludeMetadata = true,
    MetadataComments = true
}

-- Build options cho saveinstance
local function BuildSaveOptions(fileName, mode, customOpts)
    mode = mode or "full"
    customOpts = customOpts or {}
    
    -- Clone base config
    local options = {}
    for k, v in pairs(SaveConfig) do
        if type(v) == "table" then
            options[k] = {}
            for k2, v2 in pairs(v) do
                options[k][k2] = v2
            end
        else
            options[k] = v
        end
    end
    
    -- Apply custom options
    for k, v in pairs(customOpts) do
        options[k] = v
    end
    
    -- Set filename
    options.FileName = fileName
    options.Filename = fileName -- Alias
    options.FilePath = fileName
    
    -- Mode-specific settings
    if mode == "full" then
        options.Mode = "full"
        options.SaveTerrain = true
        options.Terrain = true
        options.CopyTerrain = true
        options.Decompile = true
        options.DecompileMode = 2
        options.NilInstances = true
        options.SaveNotArchivable = true
        LogSystem:Info("Mode: Full Game (Models + Terrain + Scripts)", "SAVE")
        
    elseif mode == "models" then
        options.Mode = "optimized"
        options.SaveTerrain = false
        options.Terrain = false
        options.CopyTerrain = false
        options.Decompile = true
        options.DecompileMode = 2
        
        -- Thêm terrain vào ignore
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            options.IgnoreList = options.IgnoreList or {}
            options.Ignore = options.Ignore or {}
            table.insert(options.IgnoreList, terrain)
            table.insert(options.Ignore, terrain)
            options.ExcludeDescendantsOf = options.ExcludeDescendantsOf or {}
            table.insert(options.ExcludeDescendantsOf, terrain)
        end
        LogSystem:Info("Mode: Models Only (No Terrain)", "SAVE")
        
    elseif mode == "terrain" then
        options.Mode = "optimized"
        options.SaveTerrain = true
        options.Terrain = true
        options.CopyTerrain = true
        options.Decompile = false
        options.DecompileMode = 0
        LogSystem:Info("Mode: Terrain Focus", "SAVE")
        
    elseif mode == "scripts" then
        options.Mode = "scripts"
        options.ScriptsOnly = true
        options.Decompile = true
        options.DecompileMode = 2
        options.DecompileTimeout = 60
        options.SaveTerrain = false
        LogSystem:Info("Mode: Scripts Focus", "SAVE")
        
    elseif mode == "workspace" then
        options.Mode = "optimized"
        options.Object = workspace
        options.SaveTerrain = true
        options.Decompile = true
        LogSystem:Info("Mode: Workspace Only", "SAVE")
        
    elseif mode == "custom" then
        -- Sử dụng custom options
        LogSystem:Info("Mode: Custom", "SAVE")
    end
    
    -- Object mặc định là game
    if not options.Object then
        options.Object = game
    end
    
    -- Callbacks nếu được hỗ trợ
    if ExecutorAPI.SupportsCallbacks then
        options.Callback = function(info)
            if type(info) == "string" then
                LogSystem:Debug("Callback: " .. info, "SAVE")
            elseif type(info) == "table" then
                if info.Status then
                    LogSystem:Debug("Status: " .. tostring(info.Status), "SAVE")
                end
            end
        end
        
        options.StatusCallback = function(status)
            LogSystem:Debug("StatusCallback: " .. tostring(status), "SAVE")
            UpdateStatus(tostring(status), "loading")
        end
        
        options.ProgressCallback = function(current, total)
            if total and total > 0 then
                local percent = math.floor((current / total) * 100)
                UpdateProgress(current, total, string.format("Saving: %d/%d (%d%%)", current, total, percent))
                LogSystem:Trace("Progress: " .. current .. "/" .. total, "SAVE")
            end
        end
        
        options.InstanceCallback = function(instance)
            LogSystem:Trace("Saving: " .. tostring(instance:GetFullName()), "SAVE")
        end
        
        options.ErrorCallback = function(err)
            LogSystem:Error("SaveError: " .. tostring(err), "SAVE")
        end
    end
    
    return options
end

-- =====================================================
-- SECTION 5: UTILITY FUNCTIONS
-- =====================================================

-- Lấy tên game
local function GetGameName()
    local gameName = "UnknownGame"
    
    -- Thử MarketplaceService
    local success, result = pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        if info and info.Name and type(info.Name) == "string" and #info.Name > 0 then
            return info.Name
        end
        return nil
    end)
    
    if success and result then
        gameName = result
        LogSystem:Debug("Game name from MarketplaceService: " .. gameName, "UTIL")
    else
        -- Fallback
        gameName = "Game_" .. tostring(game.PlaceId)
        LogSystem:Warn("Could not get game name, using PlaceId", "UTIL")
    end
    
    -- Sanitize
    local original = gameName
    gameName = gameName:gsub('[\\/:*?"<>|%z%c]', "_")
    gameName = gameName:gsub("^%s+", ""):gsub("%s+$", "")
    gameName = gameName:gsub("%s+", " ")
    gameName = gameName:gsub("%.+$", ""):gsub("^%.+", "")
    
    if #gameName > 100 then
        gameName = gameName:sub(1, 97) .. "..."
    end
    
    if #gameName == 0 then
        gameName = "UnknownGame"
    end
    
    if original ~= gameName then
        LogSystem:Debug("Sanitized: '" .. original .. "' -> '" .. gameName .. "'", "UTIL")
    end
    
    return gameName
end

-- Tạo tên file
local function GetFinalFileName(suffix)
    local gameName = GetGameName()
    suffix = suffix or ""
    
    local fileName
    if suffix ~= "" then
        fileName = gameName .. " [" .. suffix .. "] Decompile By BaoSaveInstance.rbxl"
    else
        fileName = gameName .. " Decompile By BaoSaveInstance.rbxl"
    end
    
    LogSystem:Debug("File name: " .. fileName, "UTIL")
    return fileName
end

-- Count instances
local function CountInstances(root)
    root = root or game
    local count = 0
    
    local success, result = pcall(function()
        local function countRecursive(instance)
            count = count + 1
            for _, child in ipairs(instance:GetChildren()) do
                countRecursive(child)
            end
        end
        
        if root == game then
            -- Count specific services
            local services = {
                workspace, Lighting, ReplicatedFirst, ReplicatedStorage,
                StarterGui, StarterPack, StarterPlayer, SoundService,
                Teams, Chat
            }
            
            for _, service in ipairs(services) do
                pcall(function()
                    countRecursive(service)
                end)
            end
        else
            countRecursive(root)
        end
        
        return count
    end)
    
    if success then
        return count
    else
        return 0
    end
end

-- Update Status UI
local function UpdateStatus(message, statusType)
    statusType = statusType or "info"
    
    local levelMap = {
        info = LogSystem.LogLevel.INFO,
        success = LogSystem.LogLevel.SUCCESS,
        error = LogSystem.LogLevel.ERROR,
        warning = LogSystem.LogLevel.WARNING,
        loading = LogSystem.LogLevel.INFO
    }
    
    LogSystem:Add(message, levelMap[statusType] or LogSystem.LogLevel.INFO, "STATUS")
    
    if StatusLabel then
        pcall(function()
            StatusLabel.Text = message
            
            local colors = {
                success = Color3.fromRGB(100, 255, 100),
                error = Color3.fromRGB(255, 100, 100),
                warning = Color3.fromRGB(255, 200, 100),
                loading = Color3.fromRGB(150, 200, 255),
                info = Color3.fromRGB(200, 200, 200)
            }
            
            StatusLabel.TextColor3 = colors[statusType] or colors.info
        end)
    end
end

-- Update Progress
local function UpdateProgress(current, total, message)
    if total <= 0 then total = 1 end
    local progress = math.clamp(current / total, 0, 1)
    
    if ProgressBar then
        pcall(function()
            TweenService:Create(ProgressBar, TweenInfo.new(0.1), {
                Size = UDim2.new(progress, 0, 1, 0)
            }):Play()
        end)
    end
    
    if ProgressLabel then
        pcall(function()
            ProgressLabel.Text = message or string.format("%.1f%%", progress * 100)
        end)
    end
end

-- Reset Progress
local function ResetProgress()
    if ProgressBar then
        pcall(function()
            ProgressBar.Size = UDim2.new(0, 0, 1, 0)
        end)
    end
    if ProgressLabel then
        pcall(function()
            ProgressLabel.Text = "0%"
        end)
    end
end

-- Update Instance Count
local function UpdateInstanceCount(count)
    if InstanceCountLabel then
        pcall(function()
            InstanceCountLabel.Text = "📦 Instances: " .. tostring(count or 0)
        end)
    end
end

-- =====================================================
-- SECTION 6: ULTIMATE DECOMPILER ENGINE
-- =====================================================

local Decompiler = {
    IsProcessing = false,
    CurrentFileName = nil,
    StartTime = 0,
    EndTime = 0,
    TotalSaveTime = 0,
    SuccessCount = 0,
    FailCount = 0,
    LastError = nil,
    InstancesSaved = 0,
    Statistics = {
        InstanceCount = 0,
        ScriptCount = 0,
        TerrainSize = 0,
        FileSize = 0
    }
}

-- Method 1: Standard saveinstance với full options
function Decompiler:Method1_FullOptions(fileName, mode, options)
    LogSystem:Info("Method 1: Full Options saveinstance", "DECOMPILE")
    
    local saveOptions = BuildSaveOptions(fileName, mode, options)
    
    local success, err = pcall(function()
        ExecutorAPI.SaveInstanceFunc(saveOptions)
    end)
    
    if success then
        LogSystem:Success("Method 1 SUCCESS", "DECOMPILE")
        return true, "Full Options"
    else
        LogSystem:Warn("Method 1 FAILED: " .. tostring(err), "DECOMPILE")
        return false, tostring(err)
    end
end

-- Method 2: Basic options
function Decompiler:Method2_BasicOptions(fileName, mode)
    LogSystem:Info("Method 2: Basic Options saveinstance", "DECOMPILE")
    
    local basicOpts = {
        FileName = fileName,
        Filename = fileName,
        Decompile = true,
        DecompileMode = 2,
        NilInstances = true,
        RemovePlayers = true,
        Binary = true
    }
    
    -- Mode specific
    if mode == "full" then
        basicOpts.SaveTerrain = true
        basicOpts.Terrain = true
        basicOpts.Mode = "full"
    elseif mode == "models" then
        basicOpts.SaveTerrain = false
        basicOpts.Terrain = false
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            basicOpts.IgnoreList = {terrain}
        end
    elseif mode == "terrain" then
        basicOpts.SaveTerrain = true
        basicOpts.Terrain = true
    end
    
    local success, err = pcall(function()
        ExecutorAPI.SaveInstanceFunc(basicOpts)
    end)
    
    if success then
        LogSystem:Success("Method 2 SUCCESS", "DECOMPILE")
        return true, "Basic Options"
    else
        LogSystem:Warn("Method 2 FAILED: " .. tostring(err), "DECOMPILE")
        return false, tostring(err)
    end
end

-- Method 3: Minimal options
function Decompiler:Method3_MinimalOptions(fileName, mode)
    LogSystem:Info("Method 3: Minimal Options saveinstance", "DECOMPILE")
    
    local minOpts = {
        FileName = fileName,
        Decompile = true
    }
    
    if mode ~= "models" then
        minOpts.SaveTerrain = true
    end
    
    local success, err = pcall(function()
        ExecutorAPI.SaveInstanceFunc(minOpts)
    end)
    
    if success then
        LogSystem:Success("Method 3 SUCCESS", "DECOMPILE")
        return true, "Minimal Options"
    else
        LogSystem:Warn("Method 3 FAILED: " .. tostring(err), "DECOMPILE")
        return false, tostring(err)
    end
end

-- Method 4: Filename only
function Decompiler:Method4_FilenameOnly(fileName)
    LogSystem:Info("Method 4: Filename only", "DECOMPILE")
    
    local success, err = pcall(function()
        ExecutorAPI.SaveInstanceFunc(fileName)
    end)
    
    if success then
        LogSystem:Success("Method 4 SUCCESS", "DECOMPILE")
        return true, "Filename Only"
    else
        LogSystem:Warn("Method 4 FAILED: " .. tostring(err), "DECOMPILE")
        return false, tostring(err)
    end
end

-- Method 5: Game + filename
function Decompiler:Method5_GameAndFilename(fileName)
    LogSystem:Info("Method 5: game + filename", "DECOMPILE")
    
    local success, err = pcall(function()
        ExecutorAPI.SaveInstanceFunc(game, fileName)
    end)
    
    if success then
        LogSystem:Success("Method 5 SUCCESS", "DECOMPILE")
        return true, "Game + Filename"
    else
        LogSystem:Warn("Method 5 FAILED: " .. tostring(err), "DECOMPILE")
        return false, tostring(err)
    end
end

-- Method 6: Table with mode
function Decompiler:Method6_ModeTable(fileName, mode)
    LogSystem:Info("Method 6: Mode table", "DECOMPILE")
    
    local modeMap = {
        full = "full",
        models = "optimized",
        terrain = "optimized",
        scripts = "scripts"
    }
    
    local success, err = pcall(function()
        ExecutorAPI.SaveInstanceFunc({
            FileName = fileName,
            Mode = modeMap[mode] or "full",
            Decompile = true,
            DecompileMode = 2
        })
    end)
    
    if success then
        LogSystem:Success("Method 6 SUCCESS", "DECOMPILE")
        return true, "Mode Table"
    else
        LogSystem:Warn("Method 6 FAILED: " .. tostring(err), "DECOMPILE")
        return false, tostring(err)
    end
end

-- Method 7: All services explicit
function Decompiler:Method7_ExplicitServices(fileName, mode)
    LogSystem:Info("Method 7: Explicit services", "DECOMPILE")
    
    local success, err = pcall(function()
        ExecutorAPI.SaveInstanceFunc({
            FileName = fileName,
            Object = game,
            Binary = true,
            Decompile = true,
            DecompileMode = 2,
            DecompileTimeout = 30,
            NilInstances = true,
            NilInstancesFix = true,
            RemovePlayers = true,
            SaveNotArchivable = true,
            IgnoreDefaultProperties = true,
            SaveTerrain = (mode ~= "models"),
            Terrain = (mode ~= "models"),
            CopyTerrain = (mode ~= "models"),
            ScriptCache = true,
            IsolateLocalPlayer = true,
            IsolateLocalPlayerCharacter = true,
            IsolateStarterPlayer = true,
            IgnoreList = (mode == "models") and {workspace:FindFirstChildOfClass("Terrain")} or {}
        })
    end)
    
    if success then
        LogSystem:Success("Method 7 SUCCESS", "DECOMPILE")
        return true, "Explicit Services"
    else
        LogSystem:Warn("Method 7 FAILED: " .. tostring(err), "DECOMPILE")
        return false, tostring(err)
    end
end

-- Method 8: Synapse-style options
function Decompiler:Method8_SynapseStyle(fileName, mode)
    LogSystem:Info("Method 8: Synapse-style options", "DECOMPILE")
    
    local success, err = pcall(function()
        ExecutorAPI.SaveInstanceFunc({
            FilePath = fileName,
            FileName = fileName,
            
            -- Synapse specific
            ExtraInstances = {},
            DecompileMode = "full",
            Decompile = true,
            
            -- Common
            Binary = true,
            NilInstances = true,
            
            -- Terrain
            Terrain = (mode ~= "models"),
            
            -- Players
            PlayerCharacters = false,
            RemovePlayers = true
        })
    end)
    
    if success then
        LogSystem:Success("Method 8 SUCCESS", "DECOMPILE")
        return true, "Synapse Style"
    else
        LogSystem:Warn("Method 8 FAILED: " .. tostring(err), "DECOMPILE")
        return false, tostring(err)
    end
end

-- Method 9: KRNL-style
function Decompiler:Method9_KRNLStyle(fileName, mode)
    LogSystem:Info("Method 9: KRNL-style", "DECOMPILE")
    
    local success, err = pcall(function()
        ExecutorAPI.SaveInstanceFunc({
            FileName = fileName,
            DecompileMode = 2,
            NilInstances = true,
            SaveNotArchivable = true,
            Terrain = (mode ~= "models")
        })
    end)
    
    if success then
        LogSystem:Success("Method 9 SUCCESS", "DECOMPILE")
        return true, "KRNL Style"
    else
        LogSystem:Warn("Method 9 FAILED: " .. tostring(err), "DECOMPILE")
        return false, tostring(err)
    end
end

-- Method 10: Fluxus-style
function Decompiler:Method10_FluxusStyle(fileName, mode)
    LogSystem:Info("Method 10: Fluxus-style", "DECOMPILE")
    
    local success, err = pcall(function()
        ExecutorAPI.SaveInstanceFunc({
            Filename = fileName,
            Decompile = true,
            DecompileTimeout = 30,
            NilInstances = true,
            SaveTerrain = (mode ~= "models")
        })
    end)
    
    if success then
        LogSystem:Success("Method 10 SUCCESS", "DECOMPILE")
        return true, "Fluxus Style"
    else
        LogSystem:Warn("Method 10 FAILED: " .. tostring(err), "DECOMPILE")
        return false, tostring(err)
    end
end

-- Main Save Function với multi-method fallback
function Decompiler:Save(fileName, mode, customOptions)
    if self.IsProcessing then
        return false, "Đang có tiến trình khác đang chạy. Vui lòng đợi."
    end
    
    if not ExecutorAPI.HasSaveInstance then
        return false, "Không tìm thấy API saveinstance trong executor.\nExecutor: " .. ExecutorAPI.Name
    end
    
    self.IsProcessing = true
    self.CurrentFileName = fileName
    self.StartTime = tick()
    self.LastError = nil
    
    LogSystem:Info("═══════════════════════════════════════════", "DECOMPILE")
    LogSystem:Info("    BẮT ĐẦU DECOMPILE", "DECOMPILE")
    LogSystem:Info("═══════════════════════════════════════════", "DECOMPILE")
    LogSystem:Info("Mode: " .. mode, "DECOMPILE")
    LogSystem:Info("File: " .. fileName, "DECOMPILE")
    LogSystem:Info("Executor: " .. ExecutorAPI.Name, "DECOMPILE")
    LogSystem:Info("SaveInstance Source: " .. ExecutorAPI.SaveInstanceSource, "DECOMPILE")
    
    -- Count instances
    UpdateStatus("Đang đếm instances...", "loading")
    local instanceCount = CountInstances()
    self.Statistics.InstanceCount = instanceCount
    UpdateInstanceCount(instanceCount)
    LogSystem:Info("Instance Count: " .. instanceCount, "DECOMPILE")
    
    ResetProgress()
    UpdateProgress(0, 100, "Bắt đầu...")
    
    local success = false
    local successMethod = "None"
    local attempts = 0
    local maxAttempts = 10
    
    -- Danh sách các methods
    local methods = {
        {name = "Full Options", func = function() return self:Method1_FullOptions(fileName, mode, customOptions) end},
        {name = "Basic Options", func = function() return self:Method2_BasicOptions(fileName, mode) end},
        {name = "Minimal Options", func = function() return self:Method3_MinimalOptions(fileName, mode) end},
        {name = "Explicit Services", func = function() return self:Method7_ExplicitServices(fileName, mode) end},
        {name = "Synapse Style", func = function() return self:Method8_SynapseStyle(fileName, mode) end},
        {name = "KRNL Style", func = function() return self:Method9_KRNLStyle(fileName, mode) end},
        {name = "Fluxus Style", func = function() return self:Method10_FluxusStyle(fileName, mode) end},
        {name = "Mode Table", func = function() return self:Method6_ModeTable(fileName, mode) end},
        {name = "Filename Only", func = function() return self:Method4_FilenameOnly(fileName) end},
        {name = "Game + Filename", func = function() return self:Method5_GameAndFilename(fileName) end},
    }
    
    -- Thử từng method
    for i, method in ipairs(methods) do
        if success then break end
        
        attempts = attempts + 1
        UpdateProgress(i, #methods, "Thử method " .. i .. "/" .. #methods .. ": " .. method.name)
        UpdateStatus("🔄 Đang thử: " .. method.name .. "...", "loading")
        
        local methodSuccess, methodResult = method.func()
        
        if methodSuccess then
            success = true
            successMethod = method.name
            break
        else
            self.LastError = methodResult
            task.wait(0.3) -- Đợi một chút trước khi thử method tiếp theo
        end
    end
    
    self.EndTime = tick()
    self.TotalSaveTime = self.EndTime - self.StartTime
    
    UpdateProgress(100, 100, "Hoàn tất!")
    
    local message = ""
    
    if success then
        self.SuccessCount = self.SuccessCount + 1
        
        LogSystem:Success("═══════════════════════════════════════════", "DECOMPILE")
        LogSystem:Success("    DECOMPILE THÀNH CÔNG!", "DECOMPILE")
        LogSystem:Success("═══════════════════════════════════════════", "DECOMPILE")
        LogSystem:Success("Method: " .. successMethod, "DECOMPILE")
        LogSystem:Success("Time: " .. string.format("%.2f", self.TotalSaveTime) .. "s", "DECOMPILE")
        LogSystem:Success("Attempts: " .. attempts, "DECOMPILE")
        
        message = "✅ DECOMPILE THÀNH CÔNG!\n\n"
        message = message .. "📁 File: " .. fileName .. "\n"
        message = message .. "📂 Thư mục: " .. ExecutorAPI.WorkspaceFolder .. "/\n"
        message = message .. "⏱️ Thời gian: " .. string.format("%.2f", self.TotalSaveTime) .. " giây\n"
        message = message .. "🔧 Method: " .. successMethod .. "\n"
        message = message .. "📦 Instances: ~" .. instanceCount
        
        -- Warnings
        if mode == "models" and not ExecutorAPI.SupportsIgnoreList then
            message = message .. "\n\n⚠️ Lưu ý: Executor không hỗ trợ IgnoreList, file có thể chứa Terrain."
        end
        
        if mode == "terrain" and not ExecutorAPI.SupportsTerrain then
            message = message .. "\n\n⚠️ Lưu ý: Executor có thể không lưu đầy đủ Terrain."
        end
        
    else
        self.FailCount = self.FailCount + 1
        
        LogSystem:Error("═══════════════════════════════════════════", "DECOMPILE")
        LogSystem:Error("    DECOMPILE THẤT BẠI!", "DECOMPILE")
        LogSystem:Error("═══════════════════════════════════════════", "DECOMPILE")
        LogSystem:Error("Attempts: " .. attempts, "DECOMPILE")
        LogSystem:Error("Last Error: " .. tostring(self.LastError), "DECOMPILE")
        
        message = "❌ DECOMPILE THẤT BẠI!\n\n"
        message = message .. "Đã thử " .. attempts .. " phương pháp khác nhau.\n\n"
        message = message .. "Nguyên nhân có thể:\n"
        message = message .. "• Executor không hỗ trợ đầy đủ saveinstance\n"
        message = message .. "• Game có anti-decompile protection\n"
        message = message .. "• Game quá lớn/phức tạp\n"
        message = message .. "• Thiếu quyền ghi file\n"
        message = message .. "• Executor cần cập nhật\n\n"
        message = message .. "Executor: " .. ExecutorAPI.Name .. "\n"
        message = message .. "Lỗi cuối: " .. tostring(self.LastError)
    end
    
    self.IsProcessing = false
    return success, message
end

-- Wrapper functions
function Decompiler:SaveFullGame(fileName)
    LogSystem:Info("═══ SaveFullGame Started ═══", "DECOMPILE")
    return self:Save(fileName, "full")
end

function Decompiler:SaveModelsOnly(fileName)
    LogSystem:Info("═══ SaveModelsOnly Started ═══", "DECOMPILE")
    return self:Save(fileName, "models")
end

function Decompiler:SaveTerrainOnly(fileName)
    LogSystem:Info("═══ SaveTerrainOnly Started ═══", "DECOMPILE")
    
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return false, "Không tìm thấy Terrain trong workspace.\nGame này có thể không có Terrain."
    end
    
    return self:Save(fileName, "terrain")
end

function Decompiler:SaveScriptsOnly(fileName)
    LogSystem:Info("═══ SaveScriptsOnly Started ═══", "DECOMPILE")
    
    if not ExecutorAPI.SupportsScripts then
        LogSystem:Warn("Executor có thể không hỗ trợ script decompile đầy đủ", "DECOMPILE")
    end
    
    return self:Save(fileName, "scripts")
end

function Decompiler:SaveWorkspaceOnly(fileName)
    LogSystem:Info("═══ SaveWorkspaceOnly Started ═══", "DECOMPILE")
    return self:Save(fileName, "workspace")
end

function Decompiler:SaveCustom(fileName, customOptions)
    LogSystem:Info("═══ SaveCustom Started ═══", "DECOMPILE")
    return self:Save(fileName, "custom", customOptions)
end

-- =====================================================
-- SECTION 7: GUI CREATION
-- =====================================================

local function CreateUltimateGui()
    -- Cleanup old GUIs
    pcall(function()
        if BaoSaveInstanceGui then BaoSaveInstanceGui:Destroy() end
        local old = CoreGui:FindFirstChild("BaoSaveInstance")
        if old then old:Destroy() end
        if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
            local old2 = LocalPlayer.PlayerGui:FindFirstChild("BaoSaveInstance")
            if old2 then old2:Destroy() end
        end
    end)
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstance"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999999
    
    local guiSuccess = pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not guiSuccess then
        pcall(function()
            screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5)
        end)
    end
    
    BaoSaveInstanceGui = screenGui
    
    -- Colors
    local Colors = {
        Background = Color3.fromRGB(18, 18, 22),
        BackgroundSecondary = Color3.fromRGB(25, 25, 32),
        BackgroundTertiary = Color3.fromRGB(32, 32, 42),
        Accent = Color3.fromRGB(90, 130, 220),
        AccentHover = Color3.fromRGB(110, 150, 240),
        Success = Color3.fromRGB(80, 200, 120),
        Error = Color3.fromRGB(220, 80, 80),
        Warning = Color3.fromRGB(220, 180, 80),
        Text = Color3.fromRGB(240, 240, 245),
        TextSecondary = Color3.fromRGB(160, 160, 170),
        TextMuted = Color3.fromRGB(120, 120, 130),
        Border = Color3.fromRGB(50, 50, 65),
        BorderLight = Color3.fromRGB(70, 70, 90)
    }
    
    -- ═══════════ SHADOW ═══════════
    local shadowFrame = Instance.new("Frame")
    shadowFrame.Name = "Shadow"
    shadowFrame.Size = UDim2.new(0, 560, 0, 720)
    shadowFrame.Position = UDim2.new(0.5, -278, 0.5, -358)
    shadowFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadowFrame.BackgroundTransparency = 0.5
    shadowFrame.BorderSizePixel = 0
    shadowFrame.ZIndex = 0
    shadowFrame.Parent = screenGui
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 20)
    shadowCorner.Parent = shadowFrame
    
    -- ═══════════ MAIN FRAME ═══════════
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 550, 0, 710)
    mainFrame.Position = UDim2.new(0.5, -275, 0.5, -355)
    mainFrame.BackgroundColor3 = Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Colors.Border
    mainStroke.Thickness = 2
    mainStroke.Parent = mainFrame
    
    -- ═══════════ HEADER ═══════════
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Colors.BackgroundSecondary
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 16)
    headerCorner.Parent = header
    
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 20)
    headerFix.Position = UDim2.new(0, 0, 1, -20)
    headerFix.BackgroundColor3 = Colors.BackgroundSecondary
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    -- Logo
    local logoFrame = Instance.new("Frame")
    logoFrame.Size = UDim2.new(0, 44, 0, 44)
    logoFrame.Position = UDim2.new(0, 10, 0, 8)
    logoFrame.BackgroundColor3 = Colors.Accent
    logoFrame.BorderSizePixel = 0
    logoFrame.Parent = header
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 12)
    logoCorner.Parent = logoFrame
    
    local logoGradient = Instance.new("UIGradient")
    logoGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 140, 240)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 110, 200))
    }
    logoGradient.Rotation = 45
    logoGradient.Parent = logoFrame
    
    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.new(1, 0, 1, 0)
    logoText.BackgroundTransparency = 1
    logoText.Text = "BSI"
    logoText.TextColor3 = Colors.Text
    logoText.TextSize = 16
    logoText.Font = Enum.Font.GothamBlack
    logoText.Parent = logoFrame
    
    -- Title
    local titleContainer = Instance.new("Frame")
    titleContainer.Size = UDim2.new(1, -180, 1, 0)
    titleContainer.Position = UDim2.new(0, 62, 0, 0)
    titleContainer.BackgroundTransparency = 1
    titleContainer.Parent = header
    
    local titleMain = Instance.new("TextLabel")
    titleMain.Size = UDim2.new(1, 0, 0, 26)
    titleMain.Position = UDim2.new(0, 0, 0, 8)
    titleMain.BackgroundTransparency = 1
    titleMain.Text = "BaoSaveInstance v" .. VERSION
    titleMain.TextColor3 = Colors.Text
    titleMain.TextSize = 18
    titleMain.Font = Enum.Font.GothamBold
    titleMain.TextXAlignment = Enum.TextXAlignment.Left
    titleMain.Parent = titleContainer
    
    local titleSub = Instance.new("TextLabel")
    titleSub.Size = UDim2.new(1, 0, 0, 18)
    titleSub.Position = UDim2.new(0, 0, 0, 32)
    titleSub.BackgroundTransparency = 1
    titleSub.Text = "Ultimate Roblox Decompile Tool • " .. BUILD
    titleSub.TextColor3 = Colors.TextMuted
    titleSub.TextSize = 12
    titleSub.Font = Enum.Font.Gotham
    titleSub.TextXAlignment = Enum.TextXAlignment.Left
    titleSub.Parent = titleContainer
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -50, 0, 10)
    closeBtn.BackgroundColor3 = Colors.Error
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Colors.Text
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 10)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(240, 100, 100)}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Error}):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -275, 1.5, 0)}):Play()
        TweenService:Create(shadowFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -278, 1.5, 3)}):Play()
        task.wait(0.3)
        screenGui:Destroy()
        BaoSaveInstanceGui = nil
    end)
    
    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 40, 0, 40)
    minBtn.Position = UDim2.new(1, -96, 0, 10)
    minBtn.BackgroundColor3 = Colors.Warning
    minBtn.BorderSizePixel = 0
    minBtn.Text = "—"
    minBtn.TextColor3 = Colors.Text
    minBtn.TextSize = 20
    minBtn.Font = Enum.Font.GothamBold
    minBtn.AutoButtonColor = false
    minBtn.Parent = header
    
    local minBtnCorner = Instance.new("UICorner")
    minBtnCorner.CornerRadius = UDim.new(0, 10)
    minBtnCorner.Parent = minBtn
    
    local isMinimized = false
    local originalSize = mainFrame.Size
    local originalShadowSize = shadowFrame.Size
    
    minBtn.MouseEnter:Connect(function()
        TweenService:Create(minBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(240, 200, 100)}):Play()
    end)
    minBtn.MouseLeave:Connect(function()
        TweenService:Create(minBtn, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Warning}):Play()
    end)
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 550, 0, 60)}):Play()
            TweenService:Create(shadowFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 560, 0, 70)}):Play()
            minBtn.Text = "+"
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = originalSize}):Play()
            TweenService:Create(shadowFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = originalShadowSize}):Play()
            minBtn.Text = "—"
        end
    end)
    
    -- ═══════════ CONTENT ═══════════
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -24, 1, -74)
    content.Position = UDim2.new(0, 12, 0, 66)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = mainFrame
    
    -- ═══════════ INFO SECTION ═══════════
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoFrame"
    infoFrame.Size = UDim2.new(1, 0, 0, 95)
    infoFrame.Position = UDim2.new(0, 0, 0, 0)
    infoFrame.BackgroundColor3 = Colors.BackgroundTertiary
    infoFrame.BorderSizePixel = 0
    infoFrame.Parent = content
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 12)
    infoCorner.Parent = infoFrame
    
    -- Executor label
    local executorLabel = Instance.new("TextLabel")
    executorLabel.Name = "ExecutorInfo"
    executorLabel.Size = UDim2.new(1, -20, 0, 20)
    executorLabel.Position = UDim2.new(0, 12, 0, 10)
    executorLabel.BackgroundTransparency = 1
    executorLabel.Text = "🔧 Executor: Đang detect..."
    executorLabel.TextColor3 = Color3.fromRGB(130, 180, 255)
    executorLabel.TextSize = 13
    executorLabel.Font = Enum.Font.GothamSemibold
    executorLabel.TextXAlignment = Enum.TextXAlignment.Left
    executorLabel.TextTruncate = Enum.TextTruncate.AtEnd
    executorLabel.Parent = infoFrame
    
    -- Game label
    local gameLabel = Instance.new("TextLabel")
    gameLabel.Name = "GameInfo"
    gameLabel.Size = UDim2.new(1, -20, 0, 20)
    gameLabel.Position = UDim2.new(0, 12, 0, 32)
    gameLabel.BackgroundTransparency = 1
    gameLabel.Text = "🎮 Game: Đang lấy thông tin..."
    gameLabel.TextColor3 = Color3.fromRGB(130, 255, 130)
    gameLabel.TextSize = 13
    gameLabel.Font = Enum.Font.GothamSemibold
    gameLabel.TextXAlignment = Enum.TextXAlignment.Left
    gameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    gameLabel.Parent = infoFrame
    
    -- Instance count label
    local instanceLabel = Instance.new("TextLabel")
    instanceLabel.Name = "InstanceInfo"
    instanceLabel.Size = UDim2.new(1, -20, 0, 20)
    instanceLabel.Position = UDim2.new(0, 12, 0, 54)
    instanceLabel.BackgroundTransparency = 1
    instanceLabel.Text = "📦 Instances: Đang đếm..."
    instanceLabel.TextColor3 = Color3.fromRGB(255, 200, 130)
    instanceLabel.TextSize = 12
    instanceLabel.Font = Enum.Font.Gotham
    instanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    instanceLabel.Parent = infoFrame
    
    InstanceCountLabel = instanceLabel
    
    -- Features label
    local featuresLabel = Instance.new("TextLabel")
    featuresLabel.Name = "FeaturesInfo"
    featuresLabel.Size = UDim2.new(1, -20, 0, 16)
    featuresLabel.Position = UDim2.new(0, 12, 0, 74)
    featuresLabel.BackgroundTransparency = 1
    featuresLabel.Text = "✨ Features: ..."
    featuresLabel.TextColor3 = Colors.TextMuted
    featuresLabel.TextSize = 11
    featuresLabel.Font = Enum.Font.Gotham
    featuresLabel.TextXAlignment = Enum.TextXAlignment.Left
    featuresLabel.TextTruncate = Enum.TextTruncate.AtEnd
    featuresLabel.Parent = infoFrame
    
    -- ═══════════ BUTTONS SECTION ═══════════
    local function CreateButton(name, text, emoji, posY, color1, color2, desc)
        local btnFrame = Instance.new("Frame")
        btnFrame.Name = name .. "Frame"
        btnFrame.Size = UDim2.new(1, 0, 0, 60)
        btnFrame.Position = UDim2.new(0, 0, 0, posY)
        btnFrame.BackgroundTransparency = 1
        btnFrame.Parent = content
        
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundColor3 = color1
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = btnFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = btn
        
        local btnGradient = Instance.new("UIGradient")
        btnGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, color1),
            ColorSequenceKeypoint.new(1, color2)
        }
        btnGradient.Rotation = 90
        btnGradient.Parent = btn
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(
            math.min(color1.R * 255 + 40, 255),
            math.min(color1.G * 255 + 40, 255),
            math.min(color1.B * 255 + 40, 255)
        )
        btnStroke.Thickness = 1.5
        btnStroke.Transparency = 0.6
        btnStroke.Parent = btn
        
        -- Emoji
        local emojiLabel = Instance.new("TextLabel")
        emojiLabel.Size = UDim2.new(0, 50, 1, 0)
        emojiLabel.Position = UDim2.new(0, 8, 0, 0)
        emojiLabel.BackgroundTransparency = 1
        emojiLabel.Text = emoji
        emojiLabel.TextSize = 26
        emojiLabel.Font = Enum.Font.GothamBold
        emojiLabel.TextColor3 = Colors.Text
        emojiLabel.Parent = btn
        
        -- Title
        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -65, 0, 24)
        titleLbl.Position = UDim2.new(0, 58, 0, 8)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = text
        titleLbl.TextSize = 15
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextColor3 = Colors.Text
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = btn
        
        -- Description
        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, -65, 0, 18)
        descLbl.Position = UDim2.new(0, 58, 0, 32)
        descLbl.BackgroundTransparency = 1
        descLbl.Text = desc
        descLbl.TextSize = 11
        descLbl.Font = Enum.Font.Gotham
        descLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.TextTransparency = 0.2
        descLbl.Parent = btn
        
        -- Hover
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(
                math.min(color1.R * 255 + 20, 255),
                math.min(color1.G * 255 + 20, 255),
                math.min(color1.B * 255 + 20, 255)
            )}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color1}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.6}):Play()
        end)
        
        return btn
    end
    
    -- Create all buttons
    local fullGameBtn = CreateButton(
        "FullGame", "Decompile Full Game", "🎮", 105,
        Color3.fromRGB(45, 95, 165), Color3.fromRGB(35, 75, 135),
        "Lưu toàn bộ: Models + Terrain + Scripts + Services"
    )
    
    local modelsBtn = CreateButton(
        "Models", "Decompile Models Only", "🏗️", 172,
        Color3.fromRGB(55, 125, 55), Color3.fromRGB(40, 100, 40),
        "Chỉ lưu Models, bỏ qua Terrain"
    )
    
    local terrainBtn = CreateButton(
        "Terrain", "Decompile Terrain Only", "🌍", 239,
        Color3.fromRGB(165, 100, 40), Color3.fromRGB(135, 80, 30),
        "Lưu Terrain với environment tối thiểu"
    )
    
    local scriptsBtn = CreateButton(
        "Scripts", "Decompile Scripts Focus", "📜", 306,
        Color3.fromRGB(130, 55, 130), Color3.fromRGB(100, 40, 100),
        "Tập trung decompile toàn bộ Scripts"
    )
    
    local workspaceBtn = CreateButton(
        "Workspace", "Decompile Workspace Only", "🏢", 373,
        Color3.fromRGB(55, 100, 130), Color3.fromRGB(40, 80, 110),
        "Chỉ lưu nội dung Workspace"
    )
    
    -- ═══════════ PROGRESS SECTION ═══════════
    local progressFrame = Instance.new("Frame")
    progressFrame.Name = "ProgressFrame"
    progressFrame.Size = UDim2.new(1, 0, 0, 55)
    progressFrame.Position = UDim2.new(0, 0, 0, 440)
    progressFrame.BackgroundColor3 = Colors.BackgroundSecondary
    progressFrame.BorderSizePixel = 0
    progressFrame.Parent = content
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 10)
    progressCorner.Parent = progressFrame
    
    -- Progress label
    local progressLbl = Instance.new("TextLabel")
    progressLbl.Name = "ProgressLabel"
    progressLbl.Size = UDim2.new(1, -20, 0, 22)
    progressLbl.Position = UDim2.new(0, 10, 0, 6)
    progressLbl.BackgroundTransparency = 1
    progressLbl.Text = "Sẵn sàng"
    progressLbl.TextColor3 = Colors.TextSecondary
    progressLbl.TextSize = 12
    progressLbl.Font = Enum.Font.Gotham
    progressLbl.TextXAlignment = Enum.TextXAlignment.Left
    progressLbl.Parent = progressFrame
    
    ProgressLabel = progressLbl
    
    -- Progress bar bg
    local progressBarBg = Instance.new("Frame")
    progressBarBg.Size = UDim2.new(1, -20, 0, 18)
    progressBarBg.Position = UDim2.new(0, 10, 0, 30)
    progressBarBg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    progressBarBg.BorderSizePixel = 0
    progressBarBg.Parent = progressFrame
    
    local progressBarBgCorner = Instance.new("UICorner")
    progressBarBgCorner.CornerRadius = UDim.new(0, 6)
    progressBarBgCorner.Parent = progressBarBg
    
    -- Progress bar fill
    local progressBarFill = Instance.new("Frame")
    progressBarFill.Name = "Fill"
    progressBarFill.Size = UDim2.new(0, 0, 1, 0)
    progressBarFill.BackgroundColor3 = Colors.Accent
    progressBarFill.BorderSizePixel = 0
    progressBarFill.Parent = progressBarBg
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 6)
    progressFillCorner.Parent = progressBarFill
    
    local progressFillGradient = Instance.new("UIGradient")
    progressFillGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 160, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 130, 220))
    }
    progressFillGradient.Parent = progressBarFill
    
    ProgressBar = progressBarFill
    
    -- ═══════════ STATUS SECTION ═══════════
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(1, 0, 0, 100)
    statusFrame.Position = UDim2.new(0, 0, 0, 503)
    statusFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = content
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 10)
    statusCorner.Parent = statusFrame
    
    local statusStroke = Instance.new("UIStroke")
    statusStroke.Color = Colors.Border
    statusStroke.Thickness = 1
    statusStroke.Parent = statusFrame
    
    -- Status header
    local statusHeader = Instance.new("Frame")
    statusHeader.Size = UDim2.new(1, 0, 0, 28)
    statusHeader.BackgroundColor3 = Colors.BackgroundSecondary
    statusHeader.BorderSizePixel = 0
    statusHeader.Parent = statusFrame
    
    local statusHeaderCorner = Instance.new("UICorner")
    statusHeaderCorner.CornerRadius = UDim.new(0, 10)
    statusHeaderCorner.Parent = statusHeader
    
    local statusHeaderFix = Instance.new("Frame")
    statusHeaderFix.Size = UDim2.new(1, 0, 0, 12)
    statusHeaderFix.Position = UDim2.new(0, 0, 1, -12)
    statusHeaderFix.BackgroundColor3 = Colors.BackgroundSecondary
    statusHeaderFix.BorderSizePixel = 0
    statusHeaderFix.Parent = statusHeader
    
    local statusHeaderText = Instance.new("TextLabel")
    statusHeaderText.Size = UDim2.new(1, -10, 1, 0)
    statusHeaderText.Position = UDim2.new(0, 10, 0, 0)
    statusHeaderText.BackgroundTransparency = 1
    statusHeaderText.Text = "📋 Status"
    statusHeaderText.TextColor3 = Colors.TextMuted
    statusHeaderText.TextSize = 12
    statusHeaderText.Font = Enum.Font.GothamSemibold
    statusHeaderText.TextXAlignment = Enum.TextXAlignment.Left
    statusHeaderText.Parent = statusHeader
    
    -- Status content
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Name = "StatusLabel"
    statusLbl.Size = UDim2.new(1, -20, 1, -38)
    statusLbl.Position = UDim2.new(0, 10, 0, 32)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "✅ Sẵn sàng. Chọn chức năng để bắt đầu decompile."
    statusLbl.TextColor3 = Colors.TextSecondary
    statusLbl.TextSize = 12
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextWrapped = true
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.TextYAlignment = Enum.TextYAlignment.Top
    statusLbl.Parent = statusFrame
    
    StatusLabel = statusLbl
    
    -- ═══════════ LOG SECTION ═══════════
    local logFrame = Instance.new("Frame")
    logFrame.Name = "LogFrame"
    logFrame.Size = UDim2.new(1, 0, 0, 35)
    logFrame.Position = UDim2.new(0, 0, 0, 610)
    logFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    logFrame.BorderSizePixel = 0
    logFrame.ClipsDescendants = true
    logFrame.Parent = content
    
    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0, 8)
    logCorner.Parent = logFrame
    
    -- Log toggle button
    local logToggle = Instance.new("TextButton")
    logToggle.Size = UDim2.new(1, 0, 0, 28)
    logToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    logToggle.BorderSizePixel = 0
    logToggle.Text = "  📝 Console Logs (Click để mở)"
    logToggle.TextColor3 = Colors.TextMuted
    logToggle.TextSize = 11
    logToggle.Font = Enum.Font.Gotham
    logToggle.TextXAlignment = Enum.TextXAlignment.Left
    logToggle.AutoButtonColor = false
    logToggle.Parent = logFrame
    
    local logToggleCorner = Instance.new("UICorner")
    logToggleCorner.CornerRadius = UDim.new(0, 8)
    logToggleCorner.Parent = logToggle
    
    -- Log scroll
    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Size = UDim2.new(1, -8, 1, -34)
    logScroll.Position = UDim2.new(0, 4, 0, 30)
    logScroll.BackgroundTransparency = 1
    logScroll.BorderSizePixel = 0
    logScroll.ScrollBarThickness = 4
    logScroll.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 90)
    logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logScroll.Visible = false
    logScroll.Parent = logFrame
    
    local logText = Instance.new("TextLabel")
    logText.Name = "LogText"
    logText.Size = UDim2.new(1, -4, 0, 0)
    logText.Position = UDim2.new(0, 2, 0, 0)
    logText.BackgroundTransparency = 1
    logText.Text = ""
    logText.TextColor3 = Color3.fromRGB(140, 140, 150)
    logText.TextSize = 10
    logText.Font = Enum.Font.Code
    logText.TextXAlignment = Enum.TextXAlignment.Left
    logText.TextYAlignment = Enum.TextYAlignment.Top
    logText.TextWrapped = true
    logText.AutomaticSize = Enum.AutomaticSize.Y
    logText.Parent = logScroll
    
    LogTextBox = logText
    
    local logExpanded = false
    logToggle.MouseButton1Click:Connect(function()
        logExpanded = not logExpanded
        if logExpanded then
            TweenService:Create(logFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 130)}):Play()
            logScroll.Visible = true
            logToggle.Text = "  📝 Console Logs (Click để đóng)"
        else
            TweenService:Create(logFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}):Play()
            logScroll.Visible = false
            logToggle.Text = "  📝 Console Logs (Click để mở)"
        end
    end)
    
    -- ═══════════ DRAGGABLE ═══════════
    local dragging = false
    local dragStart, startPos, startShadowPos
    
    local function updateDrag(input)
        if dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            shadowFrame.Position = UDim2.new(startShadowPos.X.Scale, startShadowPos.X.Offset + delta.X, startShadowPos.Y.Scale, startShadowPos.Y.Offset + delta.Y)
        end
    end
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            startShadowPos = shadowFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateDrag(input)
        end
    end)
    
    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        ShadowFrame = shadowFrame,
        ExecutorLabel = executorLabel,
        GameLabel = gameLabel,
        InstanceLabel = instanceLabel,
        FeaturesLabel = featuresLabel,
        FullGameBtn = fullGameBtn,
        ModelsBtn = modelsBtn,
        TerrainBtn = terrainBtn,
        ScriptsBtn = scriptsBtn,
        WorkspaceBtn = workspaceBtn,
        ProgressLabel = progressLbl,
        ProgressBar = progressBarFill,
        StatusLabel = statusLbl,
        LogText = logText
    }
end

-- =====================================================
-- SECTION 8: BUTTON HANDLERS
-- =====================================================

local function SetupButtonHandlers(guiRefs)
    local buttons = {
        guiRefs.FullGameBtn,
        guiRefs.ModelsBtn,
        guiRefs.TerrainBtn,
        guiRefs.ScriptsBtn,
        guiRefs.WorkspaceBtn
    }
    
    local function SetButtonsEnabled(enabled)
        for _, btn in ipairs(buttons) do
            btn.Active = enabled
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundTransparency = enabled and 0 or 0.5
            }):Play()
        end
    end
    
    local function HandleDecompile(mode, btn)
        if Decompiler.IsProcessing then
            UpdateStatus("⚠️ Đang có tiến trình khác. Vui lòng đợi.", "warning")
            return
        end
        
        SetButtonsEnabled(false)
        
        local modeName = ({
            full = "Full Game",
            models = "Models Only",
            terrain = "Terrain Only",
            scripts = "Scripts Only",
            workspace = "Workspace Only"
        })[mode] or mode
        
        UpdateStatus("🔄 Đang chuẩn bị decompile " .. modeName .. "...\nVui lòng đợi, quá trình có thể mất vài phút.", "loading")
        
        task.wait(0.3)
        
        local fileName = GetFinalFileName(modeName:gsub(" ", ""))
        local success, message
        
        if mode == "full" then
            success, message = Decompiler:SaveFullGame(fileName)
        elseif mode == "models" then
            success, message = Decompiler:SaveModelsOnly(fileName)
        elseif mode == "terrain" then
            success, message = Decompiler:SaveTerrainOnly(fileName)
        elseif mode == "scripts" then
            success, message = Decompiler:SaveScriptsOnly(fileName)
        elseif mode == "workspace" then
            success, message = Decompiler:SaveWorkspaceOnly(fileName)
        end
        
        if success then
            UpdateStatus(message, "success")
        else
            UpdateStatus(message, "error")
        end
        
        task.wait(0.5)
        SetButtonsEnabled(true)
    end
    
    guiRefs.FullGameBtn.MouseButton1Click:Connect(function() HandleDecompile("full") end)
    guiRefs.ModelsBtn.MouseButton1Click:Connect(function() HandleDecompile("models") end)
    guiRefs.TerrainBtn.MouseButton1Click:Connect(function() HandleDecompile("terrain") end)
    guiRefs.ScriptsBtn.MouseButton1Click:Connect(function() HandleDecompile("scripts") end)
    guiRefs.WorkspaceBtn.MouseButton1Click:Connect(function() HandleDecompile("workspace") end)
end

-- =====================================================
-- SECTION 9: INITIALIZATION
-- =====================================================

local function Initialize()
    LogSystem:Init()
    
    LogSystem:Info("════════════════════════════════════════════════", "INIT")
    LogSystem:Info("    BaoSaveInstance v" .. VERSION .. " - " .. BUILD, "INIT")
    LogSystem:Info("    Ultimate Roblox Decompile Tool", "INIT")
    LogSystem:Info("    Starting...", "INIT")
    LogSystem:Info("════════════════════════════════════════════════", "INIT")
    
    -- Create GUI
    local guiRefs = CreateUltimateGui()
    if not guiRefs or not guiRefs.ScreenGui then
        LogSystem:Critical("Failed to create GUI!", "INIT")
        return false
    end
    
    -- Detect APIs
    UpdateStatus("🔍 Đang detect executor APIs...", "loading")
    task.wait(0.2)
    DetectAllAPIs()
    
    -- Update executor info
    local execText = "🔧 Executor: " .. ExecutorAPI.Name .. " v" .. ExecutorAPI.Version
    if ExecutorAPI.HasSaveInstance then
        execText = execText .. " ✅"
        guiRefs.ExecutorLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        execText = execText .. " ❌"
        guiRefs.ExecutorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
    guiRefs.ExecutorLabel.Text = execText
    
    -- Update game info
    local gameName = GetGameName()
    guiRefs.GameLabel.Text = "🎮 Game: " .. gameName .. " [" .. game.PlaceId .. "]"
    
    -- Count instances
    task.spawn(function()
        local count = CountInstances()
        UpdateInstanceCount(count)
    end)
    
    -- Update features
    local features = {}
    if ExecutorAPI.SupportsOptions then table.insert(features, "Options") end
    if ExecutorAPI.SupportsTerrain then table.insert(features, "Terrain") end
    if ExecutorAPI.SupportsScripts then table.insert(features, "Scripts") end
    if ExecutorAPI.SupportsCallbacks then table.insert(features, "Callbacks") end
    if ExecutorAPI.HasWriteFile then table.insert(features, "WriteFile") end
    if ExecutorAPI.HasDecompile then table.insert(features, "Decompile") end
    if ExecutorAPI.HasGetNilInstances then table.insert(features, "NilInstances") end
    
    guiRefs.FeaturesLabel.Text = "✨ Features: " .. (#features > 0 and table.concat(features, ", ") or "Basic")
    
    -- Setup handlers
    SetupButtonHandlers(guiRefs)
    
    -- Final status
    task.wait(0.3)
    if ExecutorAPI.HasSaveInstance then
        UpdateStatus("✅ Sẵn sàng!\n\n📁 File sẽ được lưu tại: " .. ExecutorAPI.WorkspaceFolder .. "/\n🔧 SaveInstance: " .. ExecutorAPI.SaveInstanceSource .. "\n🎯 Chọn chức năng để bắt đầu decompile.", "success")
    else
        UpdateStatus("⚠️ CẢNH BÁO: Không tìm thấy saveinstance!\n\nExecutor: " .. ExecutorAPI.Name .. "\n\nVui lòng sử dụng executor có hỗ trợ saveinstance.", "error")
    end
    
    -- Intro animation
    local mf = guiRefs.MainFrame
    local sf = guiRefs.ShadowFrame
    local origMfPos = mf.Position
    local origSfPos = sf.Position
    
    mf.Position = UDim2.new(0.5, -275, -0.6, 0)
    sf.Position = UDim2.new(0.5, -278, -0.6, 3)
    
    TweenService:Create(mf, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = origMfPos}):Play()
    TweenService:Create(sf, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = origSfPos}):Play()
    
    LogSystem:Success("════════════════════════════════════════════════", "INIT")
    LogSystem:Success("    Initialization Complete!", "INIT")
    LogSystem:Success("════════════════════════════════════════════════", "INIT")
    
    return true
end

-- =====================================================
-- SECTION 10: RUN
-- =====================================================

local success, err = pcall(Initialize)
if not success then
    warn("[BaoSaveInstance] Fatal Error: " .. tostring(err))
    
    pcall(function()
        local errGui = Instance.new("ScreenGui")
        errGui.Name = "BaoSaveInstanceError"
        pcall(function() errGui.Parent = CoreGui end)
        if not errGui.Parent then
            pcall(function() errGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
        end
        
        local errFrame = Instance.new("Frame")
        errFrame.Size = UDim2.new(0, 500, 0, 150)
        errFrame.Position = UDim2.new(0.5, -250, 0.5, -75)
        errFrame.BackgroundColor3 = Color3.fromRGB(40, 15, 15)
        errFrame.BorderSizePixel = 0
        errFrame.Parent = errGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 14)
        corner.Parent = errFrame
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(200, 50, 50)
        stroke.Thickness = 2
        stroke.Parent = errFrame
        
        local errLabel = Instance.new("TextLabel")
        errLabel.Size = UDim2.new(1, -30, 1, -30)
        errLabel.Position = UDim2.new(0, 15, 0, 15)
        errLabel.BackgroundTransparency = 1
        errLabel.Text = "❌ BaoSaveInstance - Fatal Error\n\n" .. tostring(err) .. "\n\nGUI sẽ tự đóng sau 20 giây..."
        errLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
        errLabel.TextSize = 13
        errLabel.Font = Enum.Font.Gotham
        errLabel.TextWrapped = true
        errLabel.TextYAlignment = Enum.TextYAlignment.Top
        errLabel.Parent = errFrame
        
        task.delay(20, function()
            if errGui and errGui.Parent then
                errGui:Destroy()
            end
        end)
    end)
end
