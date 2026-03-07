--[[
================================================================================
    BaoSaveInstance - Advanced Roblox Decompile Tool
    Version: 2.0 (Enhanced Edition)
    
    Chức năng nâng cao:
    - Decompile Full Game (Model + Terrain + Scripts)
    - Decompile Full Model (không Terrain)
    - Decompile Terrain Only
    - Decompile Scripts Only
    - Custom Options Panel
    - Progress Tracking
    - Multi-API Support với fallback
    - Advanced Error Handling
    - Detailed Logging
================================================================================
]]

-- =====================================================
-- SECTION 1: SERVICES & CORE VARIABLES
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

local LocalPlayer = Players.LocalPlayer
local BaoSaveInstanceGui = nil
local StatusLabel = nil
local ProgressBar = nil
local ProgressLabel = nil
local LogTextBox = nil

-- Version info
local VERSION = "2.0"
local BUILD_DATE = "2024"

-- =====================================================
-- SECTION 2: LOGGING SYSTEM
-- =====================================================

local LogSystem = {
    Logs = {},
    MaxLogs = 500,
    LogLevel = {
        DEBUG = 1,
        INFO = 2,
        WARNING = 3,
        ERROR = 4,
        SUCCESS = 5
    },
    CurrentLevel = 1 -- Show all logs
}

function LogSystem:Add(message, level)
    level = level or self.LogLevel.INFO
    
    local levelNames = {
        [1] = "DEBUG",
        [2] = "INFO",
        [3] = "WARNING",
        [4] = "ERROR",
        [5] = "SUCCESS"
    }
    
    local timestamp = os.date("%H:%M:%S")
    local logEntry = string.format("[%s][%s] %s", timestamp, levelNames[level] or "INFO", message)
    
    table.insert(self.Logs, {
        Message = logEntry,
        Level = level,
        Time = tick()
    })
    
    -- Giới hạn số logs
    while #self.Logs > self.MaxLogs do
        table.remove(self.Logs, 1)
    end
    
    -- In ra console
    if level == self.LogLevel.ERROR then
        warn("[BaoSaveInstance] " .. message)
    else
        print("[BaoSaveInstance] " .. message)
    end
    
    -- rconsoleprint nếu có
    pcall(function()
        if rconsoleprint then
            local colors = {
                [1] = "@@GRAY@@",
                [2] = "@@WHITE@@",
                [3] = "@@YELLOW@@",
                [4] = "@@RED@@",
                [5] = "@@GREEN@@"
            }
            rconsoleprint((colors[level] or "") .. logEntry .. "\n")
        end
    end)
    
    -- Cập nhật Log TextBox nếu có
    if LogTextBox then
        pcall(function()
            local allLogs = ""
            for i = math.max(1, #self.Logs - 50), #self.Logs do
                allLogs = allLogs .. self.Logs[i].Message .. "\n"
            end
            LogTextBox.Text = allLogs
            -- Auto scroll to bottom
            LogTextBox.CanvasPosition = Vector2.new(0, LogTextBox.AbsoluteCanvasSize.Y)
        end)
    end
    
    return logEntry
end

function LogSystem:Clear()
    self.Logs = {}
    if LogTextBox then
        LogTextBox.Text = ""
    end
end

function LogSystem:GetAll()
    local result = ""
    for _, log in ipairs(self.Logs) do
        result = result .. log.Message .. "\n"
    end
    return result
end

-- =====================================================
-- SECTION 3: ADVANCED EXECUTOR API DETECTION
-- =====================================================

local ExecutorInfo = {
    Name = "Unknown",
    Version = "Unknown",
    HasSaveInstance = false,
    HasWriteFile = false,
    HasReadFile = false,
    HasMakeFolder = false,
    HasIsFile = false,
    HasAppendFile = false,
    HasDelFile = false,
    HasListFiles = false,
    HasGetCustomAsset = false,
    HasRequest = false,
    HasWebSocket = false,
    HasClipboard = false,
    HasCrypt = false,
    HasDrawing = false,
    SaveInstanceFunc = nil,
    SaveInstanceVersion = "Unknown",
    WriteFileFunc = nil,
    ReadFileFunc = nil,
    SupportsTerrainSave = false,
    SupportsOptions = false,
    SupportsDecompile = true,
    SupportsScriptDecompile = false,
    SupportsCallbacks = false,
    SupportsBinaryFormat = true,
    MaxFileSize = math.huge,
    WorkspaceFolder = "workspace",
    Features = {}
}

-- Chi tiết các hàm cần kiểm tra
local FunctionChecks = {
    -- SaveInstance variants
    {name = "saveinstance", global = "saveinstance", feature = "SaveInstance"},
    {name = "save_instance", global = "save_instance", feature = "SaveInstance"},
    {name = "saveplace", global = "saveplace", feature = "SavePlace"},
    {name = "save_place", global = "save_place", feature = "SavePlace"},
    {name = "savegame", global = "savegame", feature = "SaveGame"},
    
    -- File system
    {name = "writefile", global = "writefile", feature = "WriteFile"},
    {name = "write_file", global = "write_file", feature = "WriteFile"},
    {name = "readfile", global = "readfile", feature = "ReadFile"},
    {name = "read_file", global = "read_file", feature = "ReadFile"},
    {name = "appendfile", global = "appendfile", feature = "AppendFile"},
    {name = "makefolder", global = "makefolder", feature = "MakeFolder"},
    {name = "make_folder", global = "make_folder", feature = "MakeFolder"},
    {name = "isfolder", global = "isfolder", feature = "IsFolder"},
    {name = "is_folder", global = "is_folder", feature = "IsFolder"},
    {name = "isfile", global = "isfile", feature = "IsFile"},
    {name = "is_file", global = "is_file", feature = "IsFile"},
    {name = "delfile", global = "delfile", feature = "DelFile"},
    {name = "del_file", global = "del_file", feature = "DelFile"},
    {name = "delfolder", global = "delfolder", feature = "DelFolder"},
    {name = "listfiles", global = "listfiles", feature = "ListFiles"},
    {name = "list_files", global = "list_files", feature = "ListFiles"},
    
    -- Script related
    {name = "decompile", global = "decompile", feature = "Decompile"},
    {name = "getscriptbytecode", global = "getscriptbytecode", feature = "GetBytecode"},
    {name = "getscripthash", global = "getscripthash", feature = "GetScriptHash"},
    {name = "getscripts", global = "getscripts", feature = "GetScripts"},
    {name = "getsenv", global = "getsenv", feature = "GetSenv"},
    {name = "getgenv", global = "getgenv", feature = "GetGenv"},
    {name = "getrenv", global = "getrenv", feature = "GetRenv"},
    {name = "getgc", global = "getgc", feature = "GetGC"},
    {name = "getinstances", global = "getinstances", feature = "GetInstances"},
    {name = "getnilinstances", global = "getnilinstances", feature = "GetNilInstances"},
    
    -- Instance related
    {name = "getrawmetatable", global = "getrawmetatable", feature = "GetRawMetatable"},
    {name = "setrawmetatable", global = "setrawmetatable", feature = "SetRawMetatable"},
    {name = "gethiddenproperty", global = "gethiddenproperty", feature = "GetHiddenProperty"},
    {name = "sethiddenproperty", global = "sethiddenproperty", feature = "SetHiddenProperty"},
    {name = "getproperties", global = "getproperties", feature = "GetProperties"},
    {name = "gethiddenproperties", global = "gethiddenproperties", feature = "GetHiddenProperties"},
    {name = "setscriptable", global = "setscriptable", feature = "SetScriptable"},
    {name = "isscriptable", global = "isscriptable", feature = "IsScriptable"},
    {name = "cloneref", global = "cloneref", feature = "CloneRef"},
    {name = "compareinstances", global = "compareinstances", feature = "CompareInstances"},
    
    -- Misc
    {name = "getcustomasset", global = "getcustomasset", feature = "GetCustomAsset"},
    {name = "getsynasset", global = "getsynasset", feature = "GetSynAsset"},
    {name = "request", global = "request", feature = "Request"},
    {name = "http_request", global = "http_request", feature = "HttpRequest"},
    {name = "syn_request", global = "syn.request", feature = "SynRequest"},
    {name = "setclipboard", global = "setclipboard", feature = "SetClipboard"},
    {name = "toclipboard", global = "toclipboard", feature = "ToClipboard"},
}

-- Executor signatures
local ExecutorSignatures = {
    {
        check = function() return syn and syn.saveinstance end,
        name = "Synapse X",
        version = function() return syn and syn.version or "Unknown" end,
        saveFunc = function() return syn.saveinstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = true,
        supportsScriptDecompile = true,
        workspaceFolder = "workspace"
    },
    {
        check = function() return Synapse and Synapse.SaveInstance end,
        name = "Synapse V3",
        version = function() return "V3" end,
        saveFunc = function() return Synapse.SaveInstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = true,
        supportsScriptDecompile = true,
        workspaceFolder = "workspace"
    },
    {
        check = function() return KRNL_LOADED and saveinstance end,
        name = "KRNL",
        version = function() return "Latest" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = false,
        supportsScriptDecompile = true,
        workspaceFolder = "krnl/workspace"
    },
    {
        check = function() return (fluxus or FLUXUS_LOADED) and saveinstance end,
        name = "Fluxus",
        version = function() return "Latest" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = false,
        supportsScriptDecompile = true,
        workspaceFolder = "workspace"
    },
    {
        check = function() return (SW_LOADED or ScriptWare) and saveinstance end,
        name = "Script-Ware",
        version = function() return "Latest" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = false,
        supportsScriptDecompile = true,
        workspaceFolder = "workspace"
    },
    {
        check = function() return (Sentinel or SENTINEL_LOADED) and saveinstance end,
        name = "Sentinel",
        version = function() return "Latest" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = false,
        supportsScriptDecompile = true,
        workspaceFolder = "workspace"
    },
    {
        check = function() return (Electron or ELECTRON_LOADED) and saveinstance end,
        name = "Electron",
        version = function() return "Latest" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = false,
        supportsScriptDecompile = false,
        workspaceFolder = "workspace"
    },
    {
        check = function() return (Arceus or ARCEUS_LOADED) and saveinstance end,
        name = "Arceus X",
        version = function() return "Latest" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = true,
        supportsTerrain = false,
        supportsCallbacks = false,
        supportsScriptDecompile = false,
        workspaceFolder = "workspace"
    },
    {
        check = function() return (Comet or COMET_LOADED) and saveinstance end,
        name = "Comet",
        version = function() return "Latest" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = false,
        supportsScriptDecompile = true,
        workspaceFolder = "workspace"
    },
    {
        check = function() return (Hydrogen or HYDROGEN_LOADED) and saveinstance end,
        name = "Hydrogen",
        version = function() return "Latest" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = false,
        supportsScriptDecompile = true,
        workspaceFolder = "workspace"
    },
    {
        check = function() return (Celery or CELERY_LOADED) and saveinstance end,
        name = "Celery",
        version = function() return "Latest" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = false,
        supportsScriptDecompile = false,
        workspaceFolder = "workspace"
    },
    {
        check = function() return (evon or EVON_LOADED) and saveinstance end,
        name = "Evon",
        version = function() return "Latest" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = false,
        supportsScriptDecompile = false,
        workspaceFolder = "workspace"
    },
    {
        check = function() return (Delta or DELTA_LOADED) and saveinstance end,
        name = "Delta",
        version = function() return "Latest" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = false,
        supportsScriptDecompile = false,
        workspaceFolder = "workspace"
    },
    {
        check = function() return (Codex or CODEX_LOADED) and saveinstance end,
        name = "Codex",
        version = function() return "Latest" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = false,
        supportsScriptDecompile = false,
        workspaceFolder = "workspace"
    },
    {
        check = function() return (JJSploit or JJSPLOIT_LOADED) and saveinstance end,
        name = "JJSploit",
        version = function() return "Latest" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = false,
        supportsTerrain = false,
        supportsCallbacks = false,
        supportsScriptDecompile = false,
        workspaceFolder = "workspace"
    },
    -- Generic fallback
    {
        check = function() return saveinstance ~= nil end,
        name = "Generic Executor",
        version = function() return "Unknown" end,
        saveFunc = function() return saveinstance end,
        supportsOptions = true,
        supportsTerrain = true,
        supportsCallbacks = false,
        supportsScriptDecompile = false,
        workspaceFolder = "workspace"
    },
    {
        check = function() return saveplace ~= nil end,
        name = "SavePlace Executor",
        version = function() return "Unknown" end,
        saveFunc = function() 
            return function(options)
                local fileName = type(options) == "table" and (options.FileName or options.Filename) or options
                return saveplace(game, fileName)
            end
        end,
        supportsOptions = false,
        supportsTerrain = true,
        supportsCallbacks = false,
        supportsScriptDecompile = false,
        workspaceFolder = "workspace"
    }
}

-- Hàm detect APIs chi tiết
local function DetectApis()
    LogSystem:Add("Bắt đầu detect executor APIs...", LogSystem.LogLevel.INFO)
    
    -- Reset info
    ExecutorInfo = {
        Name = "Unknown",
        Version = "Unknown",
        HasSaveInstance = false,
        HasWriteFile = false,
        HasReadFile = false,
        HasMakeFolder = false,
        HasIsFile = false,
        HasAppendFile = false,
        HasDelFile = false,
        HasListFiles = false,
        HasGetCustomAsset = false,
        HasRequest = false,
        HasWebSocket = false,
        HasClipboard = false,
        HasCrypt = false,
        HasDrawing = false,
        SaveInstanceFunc = nil,
        SaveInstanceVersion = "Unknown",
        WriteFileFunc = nil,
        ReadFileFunc = nil,
        SupportsTerrainSave = false,
        SupportsOptions = false,
        SupportsDecompile = true,
        SupportsScriptDecompile = false,
        SupportsCallbacks = false,
        SupportsBinaryFormat = true,
        MaxFileSize = math.huge,
        WorkspaceFolder = "workspace",
        Features = {}
    }
    
    -- Thử identify executor
    local executorName = "Unknown"
    pcall(function()
        if identifyexecutor then
            local name, version = identifyexecutor()
            executorName = tostring(name)
            ExecutorInfo.Version = tostring(version or "Unknown")
            LogSystem:Add("identifyexecutor() => " .. executorName .. " v" .. ExecutorInfo.Version, LogSystem.LogLevel.DEBUG)
        end
    end)
    
    pcall(function()
        if getexecutorname then
            executorName = tostring(getexecutorname())
            LogSystem:Add("getexecutorname() => " .. executorName, LogSystem.LogLevel.DEBUG)
        end
    end)
    
    -- Kiểm tra từng executor signature
    for _, sig in ipairs(ExecutorSignatures) do
        local success, result = pcall(sig.check)
        if success and result then
            ExecutorInfo.Name = sig.name
            pcall(function()
                ExecutorInfo.Version = sig.version()
            end)
            
            local saveSuccess, saveFunc = pcall(sig.saveFunc)
            if saveSuccess and saveFunc then
                ExecutorInfo.HasSaveInstance = true
                ExecutorInfo.SaveInstanceFunc = saveFunc
                ExecutorInfo.SupportsOptions = sig.supportsOptions
                ExecutorInfo.SupportsTerrainSave = sig.supportsTerrain
                ExecutorInfo.SupportsCallbacks = sig.supportsCallbacks
                ExecutorInfo.SupportsScriptDecompile = sig.supportsScriptDecompile
                ExecutorInfo.WorkspaceFolder = sig.workspaceFolder
                
                LogSystem:Add("Detected: " .. sig.name .. " với saveinstance support", LogSystem.LogLevel.SUCCESS)
                break
            end
        end
    end
    
    -- Fallback: nếu identifyexecutor cho tên nhưng không match signature
    if ExecutorInfo.Name == "Unknown" and executorName ~= "Unknown" then
        ExecutorInfo.Name = executorName
    end
    
    -- Kiểm tra các hàm cụ thể
    for _, check in ipairs(FunctionChecks) do
        local success, exists = pcall(function()
            local parts = check.global:split(".")
            local obj = _G
            for _, part in ipairs(parts) do
                obj = obj[part]
                if not obj then return false end
            end
            return obj ~= nil
        end)
        
        if not success or not exists then
            success, exists = pcall(function()
                return getfenv()[check.name] ~= nil
            end)
        end
        
        if success and exists then
            ExecutorInfo.Features[check.feature] = true
            LogSystem:Add("Feature detected: " .. check.feature, LogSystem.LogLevel.DEBUG)
        end
    end
    
    -- Cập nhật các flag dựa trên features
    ExecutorInfo.HasWriteFile = ExecutorInfo.Features["WriteFile"] or false
    ExecutorInfo.HasReadFile = ExecutorInfo.Features["ReadFile"] or false
    ExecutorInfo.HasMakeFolder = ExecutorInfo.Features["MakeFolder"] or false
    ExecutorInfo.HasIsFile = ExecutorInfo.Features["IsFile"] or false
    ExecutorInfo.HasAppendFile = ExecutorInfo.Features["AppendFile"] or false
    ExecutorInfo.HasDelFile = ExecutorInfo.Features["DelFile"] or false
    ExecutorInfo.HasListFiles = ExecutorInfo.Features["ListFiles"] or false
    ExecutorInfo.HasGetCustomAsset = ExecutorInfo.Features["GetCustomAsset"] or ExecutorInfo.Features["GetSynAsset"] or false
    ExecutorInfo.HasRequest = ExecutorInfo.Features["Request"] or ExecutorInfo.Features["HttpRequest"] or ExecutorInfo.Features["SynRequest"] or false
    ExecutorInfo.HasClipboard = ExecutorInfo.Features["SetClipboard"] or ExecutorInfo.Features["ToClipboard"] or false
    ExecutorInfo.SupportsScriptDecompile = ExecutorInfo.Features["Decompile"] or false
    
    -- Lấy writefile function
    pcall(function()
        if writefile then
            ExecutorInfo.WriteFileFunc = writefile
        elseif write_file then
            ExecutorInfo.WriteFileFunc = write_file
        end
    end)
    
    -- Lấy readfile function
    pcall(function()
        if readfile then
            ExecutorInfo.ReadFileFunc = readfile
        elseif read_file then
            ExecutorInfo.ReadFileFunc = read_file
        end
    end)
    
    -- Log kết quả
    LogSystem:Add("=== Executor Detection Results ===", LogSystem.LogLevel.INFO)
    LogSystem:Add("Name: " .. ExecutorInfo.Name, LogSystem.LogLevel.INFO)
    LogSystem:Add("Version: " .. ExecutorInfo.Version, LogSystem.LogLevel.INFO)
    LogSystem:Add("SaveInstance: " .. tostring(ExecutorInfo.HasSaveInstance), LogSystem.LogLevel.INFO)
    LogSystem:Add("SupportsOptions: " .. tostring(ExecutorInfo.SupportsOptions), LogSystem.LogLevel.INFO)
    LogSystem:Add("SupportsTerrain: " .. tostring(ExecutorInfo.SupportsTerrainSave), LogSystem.LogLevel.INFO)
    LogSystem:Add("SupportsCallbacks: " .. tostring(ExecutorInfo.SupportsCallbacks), LogSystem.LogLevel.INFO)
    LogSystem:Add("ScriptDecompile: " .. tostring(ExecutorInfo.SupportsScriptDecompile), LogSystem.LogLevel.INFO)
    LogSystem:Add("WriteFile: " .. tostring(ExecutorInfo.HasWriteFile), LogSystem.LogLevel.INFO)
    LogSystem:Add("================================", LogSystem.LogLevel.INFO)
    
    return ExecutorInfo
end

-- =====================================================
-- SECTION 4: SAVE OPTIONS CONFIGURATION
-- =====================================================

local SaveOptions = {
    -- Decompile settings
    DecompileScripts = true,
    DecompileTimeout = 30,
    DecompileMode = 2, -- 1 = Fast, 2 = Full
    
    -- Instance settings
    SaveNilInstances = true,
    NilInstancesFix = true,
    SaveNonCreatable = true,
    IgnoreDefaultProperties = true,
    IgnoreNotArchivable = false,
    
    -- Player settings
    SavePlayers = false,
    RemovePlayerCharacters = true,
    IsolateLocalPlayer = true,
    IsolateLocalPlayerCharacter = true,
    IsolateStarterPlayer = true,
    
    -- Services to save
    SaveWorkspace = true,
    SaveLighting = true,
    SaveReplicatedFirst = true,
    SaveReplicatedStorage = true,
    SaveStarterGui = true,
    SaveStarterPack = true,
    SaveStarterPlayer = true,
    SaveSoundService = true,
    SaveChat = true,
    SaveLocalizationService = true,
    SaveMaterialService = true,
    
    -- Terrain
    SaveTerrain = true,
    
    -- Format
    Binary = true,
    
    -- Extra
    ShowStatus = true,
    SafeMode = false,
    Timeout = 300, -- 5 phút timeout tổng
    
    -- Exclude
    ExcludeList = {},
    
    -- Custom
    CustomFileName = ""
}

-- Hàm tạo options cho saveinstance
local function BuildSaveInstanceOptions(fileName, mode, customOptions)
    -- mode: "full", "models", "terrain", "scripts"
    customOptions = customOptions or {}
    
    -- Merge options
    local opts = {}
    for k, v in pairs(SaveOptions) do
        opts[k] = v
    end
    for k, v in pairs(customOptions) do
        opts[k] = v
    end
    
    -- Base options
    local saveOptions = {
        -- File
        FileName = fileName,
        Filename = fileName, -- Backup key
        FilePath = fileName, -- Alternative key
        
        -- Decompile
        Decompile = opts.DecompileScripts,
        DecompileMode = opts.DecompileMode,
        DecompileTimeout = opts.DecompileTimeout,
        DecompileIgnore = {},
        ScriptCache = true,
        
        -- Instances
        NilInstances = opts.SaveNilInstances,
        NilInstancesFix = opts.NilInstancesFix,
        SaveNonCreatable = opts.SaveNonCreatable,
        
        -- Properties
        IgnoreDefaultProps = opts.IgnoreDefaultProperties,
        IgnoreDefaultProperties = opts.IgnoreDefaultProperties,
        IgnoreNotArchivable = opts.IgnoreNotArchivable,
        IgnorePropertiesOfNotScriptsOnScriptsMode = false,
        SaveNotArchivable = not opts.IgnoreNotArchivable,
        
        -- Players
        SavePlayers = opts.SavePlayers,
        RemovePlayers = not opts.SavePlayers,
        RemovePlayerCharacters = opts.RemovePlayerCharacters,
        IsolateLocalPlayer = opts.IsolateLocalPlayer,
        IsolateLocalPlayerCharacter = opts.IsolateLocalPlayerCharacter,
        IsolateStarterPlayer = opts.IsolateStarterPlayer,
        PlayerCharacters = not opts.RemovePlayerCharacters,
        
        -- Format
        Binary = opts.Binary,
        
        -- Object (mặc định là game)
        Object = game,
        
        -- Mode
        Mode = "optimized",
        
        -- Status
        ShowStatus = opts.ShowStatus,
        
        -- Timeout
        Timeout = opts.Timeout,
        
        -- Terrain
        Terrain = opts.SaveTerrain,
        SaveTerrain = opts.SaveTerrain,
        CopyTerrain = opts.SaveTerrain,
    }
    
    -- Mode-specific options
    if mode == "full" then
        saveOptions.Mode = "full"
        saveOptions.Terrain = true
        saveOptions.SaveTerrain = true
        saveOptions.CopyTerrain = true
        LogSystem:Add("Mode: Full Game (Models + Terrain + Scripts)", LogSystem.LogLevel.INFO)
        
    elseif mode == "models" then
        saveOptions.Mode = "optimized"
        saveOptions.Terrain = false
        saveOptions.SaveTerrain = false
        saveOptions.CopyTerrain = false
        
        -- Thêm Terrain vào ignore list
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            saveOptions.IgnoreList = {terrain}
            saveOptions.Ignore = {terrain}
            saveOptions.ExcludeDescendantsOf = {terrain}
        end
        LogSystem:Add("Mode: Models Only (No Terrain)", LogSystem.LogLevel.INFO)
        
    elseif mode == "terrain" then
        saveOptions.Mode = "optimized"
        saveOptions.Terrain = true
        saveOptions.SaveTerrain = true
        saveOptions.CopyTerrain = true
        -- Terrain mode vẫn lưu full nhưng focus terrain
        LogSystem:Add("Mode: Terrain Focus", LogSystem.LogLevel.INFO)
        
    elseif mode == "scripts" then
        saveOptions.Mode = "scripts"
        saveOptions.Decompile = true
        saveOptions.DecompileMode = 2
        saveOptions.ScriptsOnly = true
        LogSystem:Add("Mode: Scripts Only", LogSystem.LogLevel.INFO)
    end
    
    -- Thêm exclude list
    if opts.ExcludeList and #opts.ExcludeList > 0 then
        saveOptions.IgnoreList = saveOptions.IgnoreList or {}
        for _, item in ipairs(opts.ExcludeList) do
            table.insert(saveOptions.IgnoreList, item)
        end
    end
    
    -- Callbacks nếu được hỗ trợ
    if ExecutorInfo.SupportsCallbacks then
        saveOptions.Callback = function(status)
            if ProgressLabel then
                pcall(function()
                    ProgressLabel.Text = tostring(status)
                end)
            end
            LogSystem:Add("Progress: " .. tostring(status), LogSystem.LogLevel.DEBUG)
        end
        
        saveOptions.ProgressCallback = function(current, total)
            if ProgressBar then
                pcall(function()
                    local progress = total > 0 and (current / total) or 0
                    TweenService:Create(ProgressBar, TweenInfo.new(0.1), {
                        Size = UDim2.new(progress, 0, 1, 0)
                    }):Play()
                end)
            end
            if ProgressLabel then
                pcall(function()
                    ProgressLabel.Text = string.format("Saving: %d / %d", current, total)
                end)
            end
        end
        
        saveOptions.StatusCallback = function(message)
            LogSystem:Add(message, LogSystem.LogLevel.DEBUG)
        end
    end
    
    return saveOptions
end

-- =====================================================
-- SECTION 5: UTILITY FUNCTIONS
-- =====================================================

-- Lấy tên game an toàn
local function GetGameName()
    local gameName = "UnknownGame"
    
    -- Thử nhiều cách lấy tên
    local success, result = pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        if info and info.Name and type(info.Name) == "string" and #info.Name > 0 then
            return info.Name
        end
        return nil
    end)
    
    if success and result then
        gameName = result
        LogSystem:Add("Lấy tên game từ MarketplaceService: " .. gameName, LogSystem.LogLevel.DEBUG)
    else
        -- Thử lấy từ các nguồn khác
        pcall(function()
            if game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) then
                gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or ("Game_" .. game.PlaceId)
            end
        end)
        
        if gameName == "UnknownGame" then
            gameName = "Game_" .. tostring(game.PlaceId)
            LogSystem:Add("Không thể lấy tên game, sử dụng PlaceId", LogSystem.LogLevel.WARNING)
        end
    end
    
    -- Làm sạch tên file (loại bỏ ký tự không hợp lệ)
    -- Windows forbidden: \ / : * ? " < > |
    -- Mac/Linux issues: / and null
    local originalName = gameName
    gameName = gameName:gsub('[\\/:*?"<>|%z]', "_")
    gameName = gameName:gsub("[%c]", "") -- Control characters
    gameName = gameName:gsub("^%s+", ""):gsub("%s+$", "") -- Trim
    gameName = gameName:gsub("%s+", " ") -- Normalize spaces
    gameName = gameName:gsub("%.+$", "") -- Remove trailing dots
    gameName = gameName:gsub("^%.+", "") -- Remove leading dots
    
    -- Giới hạn độ dài (để tránh path quá dài)
    if #gameName > 80 then
        gameName = gameName:sub(1, 77) .. "..."
    end
    
    -- Đảm bảo không rỗng
    if #gameName == 0 then
        gameName = "UnknownGame"
    end
    
    if originalName ~= gameName then
        LogSystem:Add("Đã làm sạch tên game: '" .. originalName .. "' -> '" .. gameName .. "'", LogSystem.LogLevel.DEBUG)
    end
    
    return gameName
end

-- Tạo tên file
local function GetFinalFileName(suffix)
    local gameName = GetGameName()
    suffix = suffix or ""
    
    local fileName
    if SaveOptions.CustomFileName and #SaveOptions.CustomFileName > 0 then
        fileName = SaveOptions.CustomFileName
        if not fileName:match("%.rbxl$") then
            fileName = fileName .. ".rbxl"
        end
    else
        if suffix ~= "" then
            fileName = gameName .. " [" .. suffix .. "] Decompile By BaoSaveInstance.rbxl"
        else
            fileName = gameName .. " Decompile By BaoSaveInstance.rbxl"
        end
    end
    
    LogSystem:Add("File name: " .. fileName, LogSystem.LogLevel.DEBUG)
    return fileName
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
    
    LogSystem:Add(message, levelMap[statusType] or LogSystem.LogLevel.INFO)
    
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
            TweenService:Create(ProgressBar, TweenInfo.new(0.15), {
                Size = UDim2.new(progress, 0, 1, 0)
            }):Play()
        end)
    end
    
    if ProgressLabel then
        pcall(function()
            if message then
                ProgressLabel.Text = message
            else
                ProgressLabel.Text = string.format("%.1f%%", progress * 100)
            end
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

-- =====================================================
-- SECTION 6: DECOMPILER MODULE (ADVANCED)
-- =====================================================

local Decompiler = {
    IsProcessing = false,
    LastError = nil,
    LastFileName = nil,
    TotalSaveTime = 0,
    SuccessCount = 0,
    FailCount = 0
}

-- Hàm save chính với nhiều fallback
function Decompiler:Save(fileName, mode, customOptions)
    if self.IsProcessing then
        return false, "Đang có tiến trình khác chạy. Vui lòng đợi."
    end
    
    if not ExecutorInfo.HasSaveInstance then
        self.LastError = "Không tìm thấy API saveinstance trong executor."
        return false, self.LastError
    end
    
    self.IsProcessing = true
    self.LastFileName = fileName
    local startTime = tick()
    
    LogSystem:Add("===== BẮT ĐẦU DECOMPILE =====", LogSystem.LogLevel.INFO)
    LogSystem:Add("Mode: " .. tostring(mode), LogSystem.LogLevel.INFO)
    LogSystem:Add("File: " .. fileName, LogSystem.LogLevel.INFO)
    
    ResetProgress()
    UpdateProgress(0, 100, "Chuẩn bị...")
    
    local success = false
    local message = ""
    local attempts = 0
    local maxAttempts = 3
    
    while attempts < maxAttempts and not success do
        attempts = attempts + 1
        LogSystem:Add("Attempt " .. attempts .. "/" .. maxAttempts, LogSystem.LogLevel.INFO)
        
        -- Phương pháp 1: SaveInstance với full options
        if ExecutorInfo.SupportsOptions then
            UpdateProgress(10, 100, "Đang cấu hình options...")
            
            local options = BuildSaveInstanceOptions(fileName, mode, customOptions)
            
            UpdateProgress(20, 100, "Đang save instance...")
            
            local saveSuccess, saveErr = pcall(function()
                ExecutorInfo.SaveInstanceFunc(options)
            end)
            
            if saveSuccess then
                success = true
                message = "Lưu thành công với full options!"
                LogSystem:Add("Method 1 (Full Options) thành công!", LogSystem.LogLevel.SUCCESS)
                break
            else
                LogSystem:Add("Method 1 failed: " .. tostring(saveErr), LogSystem.LogLevel.WARNING)
            end
        end
        
        -- Phương pháp 2: SaveInstance với options cơ bản
        if not success then
            UpdateProgress(30, 100, "Thử phương pháp 2...")
            
            local basicOptions = {
                FileName = fileName,
                Filename = fileName,
                Decompile = SaveOptions.DecompileScripts,
                DecompileMode = 2,
                NilInstances = true,
                RemovePlayers = true,
                SaveTerrain = (mode ~= "models"),
                Terrain = (mode ~= "models"),
                Binary = true,
                Mode = mode == "full" and "full" or "optimized"
            }
            
            -- Thêm ignore terrain nếu mode là models
            if mode == "models" then
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    basicOptions.IgnoreList = {terrain}
                end
            end
            
            local saveSuccess, saveErr = pcall(function()
                ExecutorInfo.SaveInstanceFunc(basicOptions)
            end)
            
            if saveSuccess then
                success = true
                message = "Lưu thành công với options cơ bản!"
                LogSystem:Add("Method 2 (Basic Options) thành công!", LogSystem.LogLevel.SUCCESS)
                break
            else
                LogSystem:Add("Method 2 failed: " .. tostring(saveErr), LogSystem.LogLevel.WARNING)
            end
        end
        
        -- Phương pháp 3: SaveInstance với options tối thiểu
        if not success then
            UpdateProgress(50, 100, "Thử phương pháp 3...")
            
            local minimalOptions = {
                FileName = fileName,
                Decompile = true
            }
            
            local saveSuccess, saveErr = pcall(function()
                ExecutorInfo.SaveInstanceFunc(minimalOptions)
            end)
            
            if saveSuccess then
                success = true
                message = "Lưu thành công với options tối thiểu!"
                LogSystem:Add("Method 3 (Minimal Options) thành công!", LogSystem.LogLevel.SUCCESS)
                break
            else
                LogSystem:Add("Method 3 failed: " .. tostring(saveErr), LogSystem.LogLevel.WARNING)
            end
        end
        
        -- Phương pháp 4: SaveInstance chỉ với filename
        if not success then
            UpdateProgress(70, 100, "Thử phương pháp 4...")
            
            local saveSuccess, saveErr = pcall(function()
                ExecutorInfo.SaveInstanceFunc(fileName)
            end)
            
            if saveSuccess then
                success = true
                message = "Lưu thành công chỉ với filename!"
                LogSystem:Add("Method 4 (Filename Only) thành công!", LogSystem.LogLevel.SUCCESS)
                break
            else
                LogSystem:Add("Method 4 failed: " .. tostring(saveErr), LogSystem.LogLevel.WARNING)
            end
        end
        
        -- Phương pháp 5: saveinstance(game, filename)
        if not success then
            UpdateProgress(85, 100, "Thử phương pháp 5...")
            
            local saveSuccess, saveErr = pcall(function()
                ExecutorInfo.SaveInstanceFunc(game, fileName)
            end)
            
            if saveSuccess then
                success = true
                message = "Lưu thành công với game object!"
                LogSystem:Add("Method 5 (Game Object) thành công!", LogSystem.LogLevel.SUCCESS)
                break
            else
                LogSystem:Add("Method 5 failed: " .. tostring(saveErr), LogSystem.LogLevel.WARNING)
                self.LastError = tostring(saveErr)
            end
        end
        
        -- Đợi trước khi retry
        if not success and attempts < maxAttempts then
            LogSystem:Add("Đợi 1 giây trước khi retry...", LogSystem.LogLevel.INFO)
            task.wait(1)
        end
    end
    
    local endTime = tick()
    self.TotalSaveTime = endTime - startTime
    
    UpdateProgress(100, 100, "Hoàn tất!")
    
    if success then
        self.SuccessCount = self.SuccessCount + 1
        message = message .. "\n\n📁 File: " .. fileName
        message = message .. "\n📂 Thư mục: " .. ExecutorInfo.WorkspaceFolder .. "/"
        message = message .. "\n⏱️ Thời gian: " .. string.format("%.2f", self.TotalSaveTime) .. " giây"
        
        -- Cảnh báo nếu mode có hạn chế
        if mode == "models" and not ExecutorInfo.SupportsOptions then
            message = message .. "\n\n⚠️ Lưu ý: Executor không hỗ trợ loại bỏ Terrain, file có thể chứa Terrain."
        end
        
        if mode == "terrain" and not ExecutorInfo.SupportsOptions then
            message = message .. "\n\n⚠️ Lưu ý: Executor không hỗ trợ tách riêng Terrain, đã lưu full game."
        end
        
        LogSystem:Add("===== DECOMPILE THÀNH CÔNG =====", LogSystem.LogLevel.SUCCESS)
    else
        self.FailCount = self.FailCount + 1
        message = "❌ Không thể lưu game sau " .. maxAttempts .. " lần thử.\n\n"
        message = message .. "Nguyên nhân có thể:\n"
        message = message .. "• Executor không hỗ trợ đầy đủ saveinstance\n"
        message = message .. "• Game quá lớn hoặc có protection\n"
        message = message .. "• Thiếu quyền ghi file\n\n"
        message = message .. "Lỗi cuối: " .. tostring(self.LastError)
        
        LogSystem:Add("===== DECOMPILE THẤT BẠI =====", LogSystem.LogLevel.ERROR)
        LogSystem:Add("Last error: " .. tostring(self.LastError), LogSystem.LogLevel.ERROR)
    end
    
    self.IsProcessing = false
    return success, message
end

-- Decompile Full Game
function Decompiler:SaveFullGame(fileName)
    LogSystem:Add("Starting SaveFullGame...", LogSystem.LogLevel.INFO)
    return self:Save(fileName, "full")
end

-- Decompile Models Only
function Decompiler:SaveModelsOnly(fileName)
    LogSystem:Add("Starting SaveModelsOnly...", LogSystem.LogLevel.INFO)
    return self:Save(fileName, "models")
end

-- Decompile Terrain Only
function Decompiler:SaveTerrainOnly(fileName)
    LogSystem:Add("Starting SaveTerrainOnly...", LogSystem.LogLevel.INFO)
    
    -- Kiểm tra terrain tồn tại
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return false, "Không tìm thấy Terrain trong workspace.\nGame này có thể không có Terrain."
    end
    
    return self:Save(fileName, "terrain")
end

-- Decompile Scripts Only
function Decompiler:SaveScriptsOnly(fileName)
    LogSystem:Add("Starting SaveScriptsOnly...", LogSystem.LogLevel.INFO)
    
    if not ExecutorInfo.SupportsScriptDecompile then
        LogSystem:Add("Executor không hỗ trợ script decompile, sẽ lưu với scripts enabled", LogSystem.LogLevel.WARNING)
    end
    
    return self:Save(fileName, "scripts", {
        DecompileScripts = true,
        DecompileMode = 2,
        DecompileTimeout = 60
    })
end

-- =====================================================
-- SECTION 7: ADVANCED GUI CREATION
-- =====================================================

local function CreateAdvancedGui()
    -- Cleanup GUI cũ
    pcall(function()
        if BaoSaveInstanceGui then
            BaoSaveInstanceGui:Destroy()
        end
        local oldGui = CoreGui:FindFirstChild("BaoSaveInstance")
        if oldGui then oldGui:Destroy() end
        if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
            local oldGui2 = LocalPlayer.PlayerGui:FindFirstChild("BaoSaveInstance")
            if oldGui2 then oldGui2:Destroy() end
        end
    end)
    
    -- Tạo ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstance"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999999
    
    -- Parent
    local guiSuccess = pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not guiSuccess then
        pcall(function()
            screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5)
        end)
    end
    
    BaoSaveInstanceGui = screenGui
    
    -- ========== SHADOW LAYER ==========
    local shadowFrame = Instance.new("Frame")
    shadowFrame.Name = "Shadow"
    shadowFrame.Size = UDim2.new(0, 520, 0, 620)
    shadowFrame.Position = UDim2.new(0.5, -258, 0.5, -308)
    shadowFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadowFrame.BackgroundTransparency = 0.6
    shadowFrame.BorderSizePixel = 0
    shadowFrame.ZIndex = 0
    shadowFrame.Parent = screenGui
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 18)
    shadowCorner.Parent = shadowFrame
    
    -- ========== MAIN FRAME ==========
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 510, 0, 610)
    mainFrame.Position = UDim2.new(0.5, -255, 0.5, -305)
    mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 14)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(70, 70, 90)
    mainStroke.Thickness = 2
    mainStroke.Parent = mainFrame
    
    -- ========== TITLE BAR ==========
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 14)
    titleCorner.Parent = titleBar
    
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 18)
    titleFix.Position = UDim2.new(0, 0, 1, -18)
    titleFix.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    -- Icon
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(0, 38, 0, 38)
    iconFrame.Position = UDim2.new(0, 8, 0, 6)
    iconFrame.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = titleBar
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 10)
    iconCorner.Parent = iconFrame
    
    local iconGradient = Instance.new("UIGradient")
    iconGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 100, 200))
    }
    iconGradient.Rotation = 45
    iconGradient.Parent = iconFrame
    
    local iconText = Instance.new("TextLabel")
    iconText.Size = UDim2.new(1, 0, 1, 0)
    iconText.BackgroundTransparency = 1
    iconText.Text = "BSI"
    iconText.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconText.TextSize = 14
    iconText.Font = Enum.Font.GothamBlack
    iconText.Parent = iconFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -160, 0, 24)
    titleLabel.Position = UDim2.new(0, 55, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "BaoSaveInstance v" .. VERSION
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 17
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- Subtitle
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, -160, 0, 16)
    subtitleLabel.Position = UDim2.new(0, 55, 0, 28)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Advanced Roblox Decompile Tool"
    subtitleLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    subtitleLabel.TextSize = 11
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.Parent = titleBar
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -46, 0, 7)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = titleBar
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 10)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(230, 80, 80)}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 60, 60)}):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(mainFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, -255, 1.5, 0)}):Play()
        TweenService:Create(shadowFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, -258, 1.5, 3)}):Play()
        task.wait(0.25)
        screenGui:Destroy()
        BaoSaveInstanceGui = nil
    end)
    
    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinimizeButton"
    minBtn.Size = UDim2.new(0, 36, 0, 36)
    minBtn.Position = UDim2.new(1, -88, 0, 7)
    minBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 50)
    minBtn.BorderSizePixel = 0
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.TextSize = 20
    minBtn.Font = Enum.Font.GothamBold
    minBtn.AutoButtonColor = false
    minBtn.Parent = titleBar
    
    local minBtnCorner = Instance.new("UICorner")
    minBtnCorner.CornerRadius = UDim.new(0, 10)
    minBtnCorner.Parent = minBtn
    
    local isMinimized = false
    local originalSize = mainFrame.Size
    local originalShadowSize = shadowFrame.Size
    
    minBtn.MouseEnter:Connect(function()
        TweenService:Create(minBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 160, 70)}):Play()
    end)
    minBtn.MouseLeave:Connect(function()
        TweenService:Create(minBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 140, 50)}):Play()
    end)
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 510, 0, 50)}):Play()
            TweenService:Create(shadowFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 520, 0, 60)}):Play()
            minBtn.Text = "+"
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = originalSize}):Play()
            TweenService:Create(shadowFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = originalShadowSize}):Play()
            minBtn.Text = "—"
        end
    end)
    
    -- ========== CONTENT FRAME ==========
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -24, 1, -62)
    contentFrame.Position = UDim2.new(0, 12, 0, 56)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ClipsDescendants = true
    contentFrame.Parent = mainFrame
    
    -- ========== INFO SECTION ==========
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoFrame"
    infoFrame.Size = UDim2.new(1, 0, 0, 75)
    infoFrame.Position = UDim2.new(0, 0, 0, 0)
    infoFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
    infoFrame.BorderSizePixel = 0
    infoFrame.Parent = contentFrame
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 10)
    infoCorner.Parent = infoFrame
    
    local infoGradient = Instance.new("UIGradient")
    infoGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 38))
    }
    infoGradient.Rotation = 90
    infoGradient.Parent = infoFrame
    
    -- Executor info
    local executorLabel = Instance.new("TextLabel")
    executorLabel.Name = "ExecutorInfo"
    executorLabel.Size = UDim2.new(1, -20, 0, 20)
    executorLabel.Position = UDim2.new(0, 12, 0, 8)
    executorLabel.BackgroundTransparency = 1
    executorLabel.Text = "🔧 Executor: Đang detect..."
    executorLabel.TextColor3 = Color3.fromRGB(130, 180, 255)
    executorLabel.TextSize = 13
    executorLabel.Font = Enum.Font.GothamSemibold
    executorLabel.TextXAlignment = Enum.TextXAlignment.Left
    executorLabel.TextTruncate = Enum.TextTruncate.AtEnd
    executorLabel.Parent = infoFrame
    
    -- Game name
    local gameNameLabel = Instance.new("TextLabel")
    gameNameLabel.Name = "GameName"
    gameNameLabel.Size = UDim2.new(1, -20, 0, 20)
    gameNameLabel.Position = UDim2.new(0, 12, 0, 28)
    gameNameLabel.BackgroundTransparency = 1
    gameNameLabel.Text = "🎮 Game: Đang lấy thông tin..."
    gameNameLabel.TextColor3 = Color3.fromRGB(130, 255, 130)
    gameNameLabel.TextSize = 13
    gameNameLabel.Font = Enum.Font.GothamSemibold
    gameNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    gameNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    gameNameLabel.Parent = infoFrame
    
    -- Features info
    local featuresLabel = Instance.new("TextLabel")
    featuresLabel.Name = "FeaturesInfo"
    featuresLabel.Size = UDim2.new(1, -20, 0, 20)
    featuresLabel.Position = UDim2.new(0, 12, 0, 48)
    featuresLabel.BackgroundTransparency = 1
    featuresLabel.Text = "📋 Features: Đang kiểm tra..."
    featuresLabel.TextColor3 = Color3.fromRGB(255, 200, 130)
    featuresLabel.TextSize = 12
    featuresLabel.Font = Enum.Font.Gotham
    featuresLabel.TextXAlignment = Enum.TextXAlignment.Left
    featuresLabel.TextTruncate = Enum.TextTruncate.AtEnd
    featuresLabel.Parent = infoFrame
    
    -- ========== BUTTONS SECTION ==========
    local function CreateDecompileButton(name, text, emoji, posY, color1, color2, description)
        local btnContainer = Instance.new("Frame")
        btnContainer.Name = name .. "Container"
        btnContainer.Size = UDim2.new(1, 0, 0, 58)
        btnContainer.Position = UDim2.new(0, 0, 0, posY)
        btnContainer.BackgroundTransparency = 1
        btnContainer.Parent = contentFrame
        
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundColor3 = color1
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = btnContainer
        
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
            math.min(color1.R * 255 + 30, 255),
            math.min(color1.G * 255 + 30, 255),
            math.min(color1.B * 255 + 30, 255)
        )
        btnStroke.Thickness = 1.5
        btnStroke.Transparency = 0.5
        btnStroke.Parent = btn
        
        -- Emoji
        local emojiLabel = Instance.new("TextLabel")
        emojiLabel.Size = UDim2.new(0, 50, 1, 0)
        emojiLabel.Position = UDim2.new(0, 5, 0, 0)
        emojiLabel.BackgroundTransparency = 1
        emojiLabel.Text = emoji
        emojiLabel.TextSize = 26
        emojiLabel.Font = Enum.Font.GothamBold
        emojiLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        emojiLabel.Parent = btn
        
        -- Main text
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -65, 0, 22)
        textLabel.Position = UDim2.new(0, 55, 0, 8)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextSize = 15
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = btn
        
        -- Description
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -65, 0, 18)
        descLabel.Position = UDim2.new(0, 55, 0, 30)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = description
        descLabel.TextSize = 11
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextTransparency = 0.3
        descLabel.Parent = btn
        
        -- Hover effects
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(
                math.min(color1.R * 255 + 15, 255),
                math.min(color1.G * 255 + 15, 255),
                math.min(color1.B * 255 + 15, 255)
            )}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color1}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
        end)
        
        return btn
    end
    
    -- Main Buttons
    local fullGameBtn = CreateDecompileButton(
        "FullGameButton",
        "Decompile Full Game",
        "🎮",
        85,
        Color3.fromRGB(50, 100, 170),
        Color3.fromRGB(35, 75, 130),
        "Lưu toàn bộ game bao gồm Models, Terrain và Scripts"
    )
    
    local fullModelBtn = CreateDecompileButton(
        "FullModelButton",
        "Decompile Models Only",
        "🏗️",
        150,
        Color3.fromRGB(60, 130, 60),
        Color3.fromRGB(45, 100, 45),
        "Lưu tất cả Models, bỏ qua Terrain"
    )
    
    local terrainBtn = CreateDecompileButton(
        "TerrainButton",
        "Decompile Terrain Only",
        "🌍",
        215,
        Color3.fromRGB(170, 100, 40),
        Color3.fromRGB(130, 75, 30),
        "Lưu Terrain với environment tối thiểu"
    )
    
    local scriptsBtn = CreateDecompileButton(
        "ScriptsButton",
        "Decompile Scripts Focus",
        "📜",
        280,
        Color3.fromRGB(140, 60, 140),
        Color3.fromRGB(100, 45, 100),
        "Tập trung decompile Scripts, giữ cấu trúc game"
    )
    
    -- ========== PROGRESS SECTION ==========
    local progressFrame = Instance.new("Frame")
    progressFrame.Name = "ProgressFrame"
    progressFrame.Size = UDim2.new(1, 0, 0, 50)
    progressFrame.Position = UDim2.new(0, 0, 0, 350)
    progressFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    progressFrame.BorderSizePixel = 0
    progressFrame.Parent = contentFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 10)
    progressCorner.Parent = progressFrame
    
    -- Progress label
    local progressLbl = Instance.new("TextLabel")
    progressLbl.Name = "ProgressLabel"
    progressLbl.Size = UDim2.new(1, -20, 0, 20)
    progressLbl.Position = UDim2.new(0, 10, 0, 5)
    progressLbl.BackgroundTransparency = 1
    progressLbl.Text = "Sẵn sàng"
    progressLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    progressLbl.TextSize = 12
    progressLbl.Font = Enum.Font.Gotham
    progressLbl.TextXAlignment = Enum.TextXAlignment.Left
    progressLbl.Parent = progressFrame
    
    ProgressLabel = progressLbl
    
    -- Progress bar background
    local progressBarBg = Instance.new("Frame")
    progressBarBg.Name = "ProgressBarBg"
    progressBarBg.Size = UDim2.new(1, -20, 0, 16)
    progressBarBg.Position = UDim2.new(0, 10, 0, 28)
    progressBarBg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    progressBarBg.BorderSizePixel = 0
    progressBarBg.Parent = progressFrame
    
    local progressBarBgCorner = Instance.new("UICorner")
    progressBarBgCorner.CornerRadius = UDim.new(0, 6)
    progressBarBgCorner.Parent = progressBarBg
    
    -- Progress bar fill
    local progressBarFill = Instance.new("Frame")
    progressBarFill.Name = "ProgressBarFill"
    progressBarFill.Size = UDim2.new(0, 0, 1, 0)
    progressBarFill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
    progressBarFill.BorderSizePixel = 0
    progressBarFill.Parent = progressBarBg
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 6)
    progressFillCorner.Parent = progressBarFill
    
    local progressFillGradient = Instance.new("UIGradient")
    progressFillGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 180, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 140, 220))
    }
    progressFillGradient.Parent = progressBarFill
    
    ProgressBar = progressBarFill
    
    -- ========== STATUS SECTION ==========
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(1, 0, 0, 90)
    statusFrame.Position = UDim2.new(0, 0, 0, 408)
    statusFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = contentFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 10)
    statusCorner.Parent = statusFrame
    
    local statusStroke = Instance.new("UIStroke")
    statusStroke.Color = Color3.fromRGB(45, 45, 55)
    statusStroke.Thickness = 1
    statusStroke.Parent = statusFrame
    
    -- Status header
    local statusHeader = Instance.new("Frame")
    statusHeader.Size = UDim2.new(1, 0, 0, 26)
    statusHeader.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    statusHeader.BorderSizePixel = 0
    statusHeader.Parent = statusFrame
    
    local statusHeaderCorner = Instance.new("UICorner")
    statusHeaderCorner.CornerRadius = UDim.new(0, 10)
    statusHeaderCorner.Parent = statusHeader
    
    local statusHeaderFix = Instance.new("Frame")
    statusHeaderFix.Size = UDim2.new(1, 0, 0, 10)
    statusHeaderFix.Position = UDim2.new(0, 0, 1, -10)
    statusHeaderFix.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    statusHeaderFix.BorderSizePixel = 0
    statusHeaderFix.Parent = statusHeader
    
    local statusHeaderText = Instance.new("TextLabel")
    statusHeaderText.Size = UDim2.new(1, -10, 1, 0)
    statusHeaderText.Position = UDim2.new(0, 10, 0, 0)
    statusHeaderText.BackgroundTransparency = 1
    statusHeaderText.Text = "📋 Status"
    statusHeaderText.TextColor3 = Color3.fromRGB(150, 150, 160)
    statusHeaderText.TextSize = 12
    statusHeaderText.Font = Enum.Font.GothamSemibold
    statusHeaderText.TextXAlignment = Enum.TextXAlignment.Left
    statusHeaderText.Parent = statusHeader
    
    -- Status content
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Name = "StatusLabel"
    statusLbl.Size = UDim2.new(1, -20, 1, -36)
    statusLbl.Position = UDim2.new(0, 10, 0, 30)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "✅ Sẵn sàng. Chọn chức năng để bắt đầu decompile."
    statusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLbl.TextSize = 12
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextWrapped = true
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.TextYAlignment = Enum.TextYAlignment.Top
    statusLbl.Parent = statusFrame
    
    StatusLabel = statusLbl
    
    -- ========== LOG SECTION (Scrolling) ==========
    local logFrame = Instance.new("Frame")
    logFrame.Name = "LogFrame"
    logFrame.Size = UDim2.new(1, 0, 0, 50)
    logFrame.Position = UDim2.new(0, 0, 0, 505)
    logFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    logFrame.BorderSizePixel = 0
    logFrame.ClipsDescendants = true
    logFrame.Parent = contentFrame
    
    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0, 8)
    logCorner.Parent = logFrame
    
    -- Log header với toggle
    local logHeader = Instance.new("TextButton")
    logHeader.Size = UDim2.new(1, 0, 0, 24)
    logHeader.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    logHeader.BorderSizePixel = 0
    logHeader.Text = "  📝 Logs (Click để mở rộng)"
    logHeader.TextColor3 = Color3.fromRGB(130, 130, 140)
    logHeader.TextSize = 11
    logHeader.Font = Enum.Font.Gotham
    logHeader.TextXAlignment = Enum.TextXAlignment.Left
    logHeader.AutoButtonColor = false
    logHeader.Parent = logFrame
    
    local logHeaderCorner = Instance.new("UICorner")
    logHeaderCorner.CornerRadius = UDim.new(0, 8)
    logHeaderCorner.Parent = logHeader
    
    -- Log scroll
    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Name = "LogScroll"
    logScroll.Size = UDim2.new(1, -10, 1, -30)
    logScroll.Position = UDim2.new(0, 5, 0, 26)
    logScroll.BackgroundTransparency = 1
    logScroll.BorderSizePixel = 0
    logScroll.ScrollBarThickness = 4
    logScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
    logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logScroll.Visible = false
    logScroll.Parent = logFrame
    
    local logText = Instance.new("TextLabel")
    logText.Name = "LogText"
    logText.Size = UDim2.new(1, -8, 0, 0)
    logText.Position = UDim2.new(0, 4, 0, 0)
    logText.BackgroundTransparency = 1
    logText.Text = ""
    logText.TextColor3 = Color3.fromRGB(150, 150, 150)
    logText.TextSize = 10
    logText.Font = Enum.Font.Code
    logText.TextXAlignment = Enum.TextXAlignment.Left
    logText.TextYAlignment = Enum.TextYAlignment.Top
    logText.TextWrapped = true
    logText.AutomaticSize = Enum.AutomaticSize.Y
    logText.Parent = logScroll
    
    LogTextBox = logScroll
    
    local logExpanded = false
    logHeader.MouseButton1Click:Connect(function()
        logExpanded = not logExpanded
        if logExpanded then
            TweenService:Create(logFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 120)}):Play()
            logScroll.Visible = true
            logHeader.Text = "  📝 Logs (Click để thu gọn)"
        else
            TweenService:Create(logFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 50)}):Play()
            logScroll.Visible = false
            logHeader.Text = "  📝 Logs (Click để mở rộng)"
        end
    end)
    
    -- Update LogTextBox reference
    LogTextBox = logText
    
    -- ========== DRAGGABLE ==========
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local startShadowPos = nil
    
    local function updateDrag(input)
        if dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            shadowFrame.Position = UDim2.new(
                startShadowPos.X.Scale,
                startShadowPos.X.Offset + delta.X,
                startShadowPos.Y.Scale,
                startShadowPos.Y.Offset + delta.Y
            )
        end
    end
    
    titleBar.InputBegan:Connect(function(input)
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
    
    -- Return references
    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        ShadowFrame = shadowFrame,
        ExecutorLabel = executorLabel,
        GameNameLabel = gameNameLabel,
        FeaturesLabel = featuresLabel,
        FullGameBtn = fullGameBtn,
        FullModelBtn = fullModelBtn,
        TerrainBtn = terrainBtn,
        ScriptsBtn = scriptsBtn,
        ProgressBar = progressBarFill,
        ProgressLabel = progressLbl,
        StatusLabel = statusLbl,
        LogText = logText
    }
end

-- =====================================================
-- SECTION 8: BUTTON HANDLERS
-- =====================================================

local function SetupButtonHandlers(guiRefs)
    local buttons = {guiRefs.FullGameBtn, guiRefs.FullModelBtn, guiRefs.TerrainBtn, guiRefs.ScriptsBtn}
    
    local function SetButtonsEnabled(enabled)
        for _, btn in ipairs(buttons) do
            btn.Active = enabled
            if enabled then
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            else
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play()
            end
        end
    end
    
    -- Full Game
    guiRefs.FullGameBtn.MouseButton1Click:Connect(function()
        if Decompiler.IsProcessing then return end
        SetButtonsEnabled(false)
        
        UpdateStatus("🔄 Đang chuẩn bị decompile full game...\nVui lòng đợi, quá trình có thể mất vài phút.", "loading")
        
        task.wait(0.3)
        
        local fileName = GetFinalFileName("Full")
        local success, message = Decompiler:SaveFullGame(fileName)
        
        if success then
            UpdateStatus("✅ " .. message, "success")
        else
            UpdateStatus("❌ " .. message, "error")
        end
        
        task.wait(0.5)
        SetButtonsEnabled(true)
    end)
    
    -- Full Model
    guiRefs.FullModelBtn.MouseButton1Click:Connect(function()
        if Decompiler.IsProcessing then return end
        SetButtonsEnabled(false)
        
        UpdateStatus("🔄 Đang chuẩn bị decompile models...\nVui lòng đợi.", "loading")
        
        task.wait(0.3)
        
        local fileName = GetFinalFileName("Models")
        local success, message = Decompiler:SaveModelsOnly(fileName)
        
        if success then
            UpdateStatus("✅ " .. message, "success")
        else
            UpdateStatus("❌ " .. message, "error")
        end
        
        task.wait(0.5)
        SetButtonsEnabled(true)
    end)
    
    -- Terrain
    guiRefs.TerrainBtn.MouseButton1Click:Connect(function()
        if Decompiler.IsProcessing then return end
        SetButtonsEnabled(false)
        
        UpdateStatus("🔄 Đang chuẩn bị decompile terrain...\nVui lòng đợi.", "loading")
        
        task.wait(0.3)
        
        local fileName = GetFinalFileName("Terrain")
        local success, message = Decompiler:SaveTerrainOnly(fileName)
        
        if success then
            UpdateStatus("✅ " .. message, "success")
        else
            UpdateStatus("❌ " .. message, "error")
        end
        
        task.wait(0.5)
        SetButtonsEnabled(true)
    end)
    
    -- Scripts
    guiRefs.ScriptsBtn.MouseButton1Click:Connect(function()
        if Decompiler.IsProcessing then return end
        SetButtonsEnabled(false)
        
        UpdateStatus("🔄 Đang chuẩn bị decompile scripts...\nVui lòng đợi.", "loading")
        
        task.wait(0.3)
        
        local fileName = GetFinalFileName("Scripts")
        local success, message = Decompiler:SaveScriptsOnly(fileName)
        
        if success then
            UpdateStatus("✅ " .. message, "success")
        else
            UpdateStatus("❌ " .. message, "error")
        end
        
        task.wait(0.5)
        SetButtonsEnabled(true)
    end)
end

-- =====================================================
-- SECTION 9: INITIALIZATION
-- =====================================================

local function Initialize()
    LogSystem:Add("========================================", LogSystem.LogLevel.INFO)
    LogSystem:Add("  BaoSaveInstance v" .. VERSION, LogSystem.LogLevel.INFO)
    LogSystem:Add("  Advanced Roblox Decompile Tool", LogSystem.LogLevel.INFO)
    LogSystem:Add("  Initializing...", LogSystem.LogLevel.INFO)
    LogSystem:Add("========================================", LogSystem.LogLevel.INFO)
    
    -- Tạo GUI
    local guiRefs = CreateAdvancedGui()
    
    if not guiRefs or not guiRefs.ScreenGui then
        warn("[BaoSaveInstance] Không thể tạo GUI!")
        return false
    end
    
    -- Detect APIs
    UpdateStatus("🔍 Đang detect executor APIs...", "loading")
    task.wait(0.2)
    DetectApis()
    
    -- Cập nhật thông tin executor
    local executorText = "🔧 Executor: " .. ExecutorInfo.Name .. " v" .. ExecutorInfo.Version
    if ExecutorInfo.HasSaveInstance then
        executorText = executorText .. " ✅"
        guiRefs.ExecutorLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        executorText = executorText .. " ❌ (Không hỗ trợ)"
        guiRefs.ExecutorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
    guiRefs.ExecutorLabel.Text = executorText
    
    -- Cập nhật tên game
    local gameName = GetGameName()
    guiRefs.GameNameLabel.Text = "🎮 Game: " .. gameName .. " [" .. game.PlaceId .. "]"
    
    -- Cập nhật features
    local features = {}
    if ExecutorInfo.SupportsOptions then table.insert(features, "Options") end
    if ExecutorInfo.SupportsTerrainSave then table.insert(features, "Terrain") end
    if ExecutorInfo.SupportsScriptDecompile then table.insert(features, "Decompile") end
    if ExecutorInfo.SupportsCallbacks then table.insert(features, "Callbacks") end
    if ExecutorInfo.HasWriteFile then table.insert(features, "WriteFile") end
    
    local featuresText = "📋 Features: "
    if #features > 0 then
        featuresText = featuresText .. table.concat(features, ", ")
    else
        featuresText = featuresText .. "Không xác định"
    end
    guiRefs.FeaturesLabel.Text = featuresText
    
    -- Setup button handlers
    SetupButtonHandlers(guiRefs)
    
    -- Status cuối cùng
    task.wait(0.3)
    if ExecutorInfo.HasSaveInstance then
        UpdateStatus("✅ Sẵn sàng! Đã phát hiện API saveinstance.\n\n📁 File sẽ được lưu tại: " .. ExecutorInfo.WorkspaceFolder .. "/\n🎯 Chọn chức năng để bắt đầu decompile.", "success")
    else
        UpdateStatus("⚠️ CẢNH BÁO: Không tìm thấy API saveinstance!\n\nExecutor hiện tại có thể không hỗ trợ lưu game.\nVui lòng sử dụng executor có hỗ trợ saveinstance.", "error")
    end
    
    -- Intro animation
    local mainFrame = guiRefs.MainFrame
    local shadowFrame = guiRefs.ShadowFrame
    local originalMainPos = mainFrame.Position
    local originalShadowPos = shadowFrame.Position
    
    mainFrame.Position = UDim2.new(0.5, -255, -0.5, 0)
    shadowFrame.Position = UDim2.new(0.5, -258, -0.5, 3)
    
    TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = originalMainPos}):Play()
    TweenService:Create(shadowFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = originalShadowPos}):Play()
    
    LogSystem:Add("========================================", LogSystem.LogLevel.SUCCESS)
    LogSystem:Add("  BaoSaveInstance initialized!", LogSystem.LogLevel.SUCCESS)
    LogSystem:Add("  Executor: " .. ExecutorInfo.Name, LogSystem.LogLevel.SUCCESS)
    LogSystem:Add("  SaveInstance: " .. tostring(ExecutorInfo.HasSaveInstance), LogSystem.LogLevel.SUCCESS)
    LogSystem:Add("  Game: " .. gameName, LogSystem.LogLevel.SUCCESS)
    LogSystem:Add("========================================", LogSystem.LogLevel.SUCCESS)
    
    return true
end

-- =====================================================
-- SECTION 10: RUN SCRIPT
-- =====================================================

-- Chạy trong protected call
local success, err = pcall(Initialize)
if not success then
    warn("[BaoSaveInstance] Lỗi khởi tạo: " .. tostring(err))
    
    -- Error GUI
    pcall(function()
        local errorGui = Instance.new("ScreenGui")
        errorGui.Name = "BaoSaveInstanceError"
        
        pcall(function() errorGui.Parent = CoreGui end)
        if not errorGui.Parent then
            pcall(function() errorGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
        end
        
        local errorFrame = Instance.new("Frame")
        errorFrame.Size = UDim2.new(0, 450, 0, 130)
        errorFrame.Position = UDim2.new(0.5, -225, 0.5, -65)
        errorFrame.BackgroundColor3 = Color3.fromRGB(45, 20, 20)
        errorFrame.BorderSizePixel = 0
        errorFrame.Parent = errorGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = errorFrame
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(200, 60, 60)
        stroke.Thickness = 2
        stroke.Parent = errorFrame
        
        local errorLabel = Instance.new("TextLabel")
        errorLabel.Size = UDim2.new(1, -30, 1, -30)
        errorLabel.Position = UDim2.new(0, 15, 0, 15)
        errorLabel.BackgroundTransparency = 1
        errorLabel.Text = "❌ BaoSaveInstance - Lỗi khởi tạo\n\n" .. tostring(err) .. "\n\nGUI sẽ tự đóng sau 15 giây..."
        errorLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
        errorLabel.TextSize = 13
        errorLabel.Font = Enum.Font.Gotham
        errorLabel.TextWrapped = true
        errorLabel.TextYAlignment = Enum.TextYAlignment.Top
        errorLabel.Parent = errorFrame
        
        task.delay(15, function()
            if errorGui and errorGui.Parent then
                errorGui:Destroy()
            end
        end)
    end)
end
