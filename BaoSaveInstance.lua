--[[
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                                                                       ║
    ║              ██████╗  █████╗  ██████╗                                ║
    ║              ██╔══██╗██╔══██╗██╔═══██╗                               ║
    ║              ██████╔╝███████║██║   ██║                               ║
    ║              ██╔══██╗██╔══██║██║   ██║                               ║
    ║              ██████╔╝██║  ██║╚██████╔╝                               ║
    ║              ╚═════╝ ╚═╝  ╚═╝ ╚═════╝                               ║
    ║                                                                       ║
    ║              BaoSaveInstance v3.0 Ultimate                            ║
    ║              Advanced Game Decompiler & Exporter                     ║
    ║                                                                       ║
    ║  Features:                                                            ║
    ║  • Deep Decompile Engine with 5-layer API fallback                   ║
    ║  • Script Decompilation & Recovery                                    ║
    ║  • Asset Downloader (Meshes, Textures, Sounds, Animations)           ║
    ║  • Terrain Voxel Export (Materials, Water, Biomes)                    ║
    ║  • Property Scanner (Hidden + Security properties)                   ║
    ║  • Anti-Detection Stealth Mode                                        ║
    ║  • Memory-Optimized Chunk Processing                                  ║
    ║  • Real-time Progress with ETA                                        ║
    ║  • Beautiful Dark UI with Animations                                  ║
    ║  • Comprehensive Error Recovery                                       ║
    ║                                                                       ║
    ╚═══════════════════════════════════════════════════════════════════════╝
--]]

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 0: ENVIRONMENT DETECTION & COMPATIBILITY LAYER         ║
-- ╚══════════════════════════════════════════════════════════════╝

local ENV = {}

-- Detect executor environment
ENV.ExecutorName = (function()
    if syn and syn.protect_gui then return "Synapse X"
    elseif KRNL_LOADED then return "KRNL"
    elseif fluxus then return "Fluxus"
    elseif SENTINEL_V2 then return "Sentinel"
    elseif ScriptWare then return "Script-Ware"
    elseif Celery then return "Celery"
    elseif WRD_ENV then return "WeAreDevs"
    elseif Hydrogen then return "Hydrogen"
    elseif Arceus then return "Arceus X"
    elseif Delta then return "Delta"
    elseif Codex then return "Codex"
    else return "Unknown"
    end
end)()

-- Normalize executor functions
ENV.saveinstance = saveinstance or syn and syn.saveinstance or fluxus and fluxus.saveinstance or nil
ENV.writefile = writefile or nil
ENV.readfile = readfile or nil
ENV.isfile = isfile or nil
ENV.isfolder = isfolder or nil
ENV.makefolder = makefolder or nil
ENV.appendfile = appendfile or nil
ENV.delfile = delfile or nil
ENV.decompile = decompile or nil
ENV.getscriptbytecode = getscriptbytecode or nil
ENV.gethiddenproperty = gethiddenproperty or nil
ENV.sethiddenproperty = sethiddenproperty or nil
ENV.getnilinstances = getnilinstances or nil
ENV.getinstances = getinstances or nil
ENV.getscripts = getscripts or nil
ENV.getloadedmodules = getloadedmodules or nil
ENV.getconnections = getconnections or nil
ENV.hookfunction = hookfunction or nil
ENV.getcustomasset = getcustomasset or nil
ENV.crypt = crypt or syn and syn.crypt or nil
ENV.request = request or http_request or syn and syn.request or http and http.request or nil
ENV.setclipboard = setclipboard or setrbxclipboard or toclipboard or nil
ENV.getgenv = getgenv or function() return _G end
ENV.protect_gui = syn and syn.protect_gui or function(gui)
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
end
ENV.queue_on_teleport = syn and syn.queue_on_teleport or queue_on_teleport or
    fluxus and fluxus.queue_on_teleport or nil
ENV.gethui = gethui or nil
ENV.getrawmetatable = getrawmetatable or nil
ENV.setreadonly = setreadonly or nil
ENV.checkcaller = checkcaller or nil
ENV.islclosure = islclosure or nil
ENV.iscclosure = iscclosure or nil
ENV.newcclosure = newcclosure or function(f) return f end
ENV.getinfo = getinfo or debug and debug.getinfo or nil
ENV.getupvalue = getupvalue or debug and debug.getupvalue or nil
ENV.setupvalue = setupvalue or debug and debug.setupvalue or nil
ENV.getconstants = getconstants or debug and debug.getconstants or nil
ENV.getprotos = getprotos or debug and debug.getprotos or nil

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 1: CORE STRUCTURE & SERVICES                           ║
-- ╚══════════════════════════════════════════════════════════════╝

local BaoSaveInstance = {
    Version = "3.0",
    Build = "Ultimate",
    StartTime = os.clock(),
    
    -- Sub-modules
    Config = {},
    Logger = {},
    Utils = {},
    State = {},
    Scanner = {},
    Serializer = {},
    AssetHandler = {},
    ScriptHandler = {},
    TerrainHandler = {},
    PropertyHandler = {},
    API = {},
    Core = {},
    GUI = {},
    Stealth = {},
    Performance = {},
}

-- Services cache (tránh gọi GetService nhiều lần)
local Services = {}
local function GetService(name)
    if not Services[name] then
        local ok, svc = pcall(function()
            return game:GetService(name)
        end)
        if ok then
            Services[name] = svc
        end
    end
    return Services[name]
end

-- Pre-cache commonly used services
local Players = GetService("Players")
local RunService = GetService("RunService")
local TweenService = GetService("TweenService")
local UserInputService = GetService("UserInputService")
local MarketplaceService = GetService("MarketplaceService")
local Lighting = GetService("Lighting")
local ReplicatedStorage = GetService("ReplicatedStorage")
local ReplicatedFirst = GetService("ReplicatedFirst")
local StarterGui = GetService("StarterGui")
local StarterPlayer = GetService("StarterPlayer")
local StarterPack = GetService("StarterPack")
local SoundService = GetService("SoundService")
local CollectionService = GetService("CollectionService")
local TextService = GetService("TextService")
local HttpService = GetService("HttpService")
local InsertService = GetService("InsertService")
local ContentProvider = GetService("ContentProvider")
local MaterialService = GetService("MaterialService")
local Workspace = GetService("Workspace")
local CoreGui = GetService("CoreGui")
local Chat = GetService("Chat")
local Teams = GetService("Teams")
local TestService = GetService("TestService")
local LocalPlayer = Players.LocalPlayer

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 2: ADVANCED CONFIGURATION                              ║
-- ╚══════════════════════════════════════════════════════════════╝

BaoSaveInstance.Config = {
    -- === Export Settings ===
    ExportFormat = "rbxl",          -- Output format
    SingleFile = true,               -- Luôn xuất 1 file duy nhất
    OverwriteExisting = true,        -- Ghi đè file cũ
    
    -- === Decompile Settings ===
    DecompileScripts = true,         -- Decompile scripts
    DecompileTimeout = 10,           -- Timeout cho mỗi script (giây)
    DecompileMode = "deep",          -- "fast", "normal", "deep"
    IncludeComments = true,          -- Thêm comment vào script decompiled
    RecoverCorruptScripts = true,    -- Thử recover script lỗi
    
    -- === Service Include Settings ===
    IncludeWorkspace = true,
    IncludeTerrain = true,
    IncludeLighting = true,
    IncludeReplicatedStorage = true,
    IncludeReplicatedFirst = true,
    IncludeServerStorage = true,     -- Nếu có quyền
    IncludeServerScriptService = true,
    IncludeStarterGui = true,
    IncludeStarterPlayer = true,
    IncludeStarterPack = true,
    IncludeSoundService = true,
    IncludeChat = true,
    IncludeTeams = true,
    IncludeMaterialService = true,
    IncludeNilInstances = true,      -- Instances ở nil parent
    IncludePlayerGui = false,
    IncludePlayerBackpack = false,
    
    -- === Asset Settings ===
    SaveAssets = true,               -- Tải và lưu assets
    AssetTypes = {
        Meshes = true,
        Textures = true,
        Sounds = true,
        Animations = true,
        Particles = true,
    },
    MaxAssetSize = 50 * 1024 * 1024, -- 50MB max per asset
    AssetCacheEnabled = true,
    
    -- === Property Settings ===
    SaveHiddenProperties = true,     -- Lưu hidden properties
    SaveSecurityProperties = true,
    PropertyBlacklist = {            -- Properties to skip
        "DataCost",
        "className",
    },
    
    -- === Performance Settings ===
    AntiLagMode = true,
    ChunkSize = 100,                 -- Objects per chunk
    YieldInterval = 0.033,           -- ~30fps yield
    MaxMemoryMB = 2048,              -- Memory limit
    GCInterval = 500,                -- Run GC every N objects
    ParallelProcessing = true,       -- Process services in parallel
    
    -- === Safety Settings ===
    StealthMode = true,              -- Anti-detection
    MaxRetries = 5,
    ErrorRecovery = true,
    AutoSaveOnCrash = true,
    BackupEnabled = true,
    
    -- === GUI Settings ===
    Theme = "Blue",                  -- "Blue", "Red", "Purple", "Green"
    Themes = {
        Blue = {
            Primary = Color3.fromRGB(18, 18, 28),
            Secondary = Color3.fromRGB(28, 28, 42),
            Tertiary = Color3.fromRGB(38, 38, 56),
            Accent = Color3.fromRGB(0, 122, 255),
            AccentHover = Color3.fromRGB(30, 144, 255),
            AccentDark = Color3.fromRGB(0, 90, 200),
            AccentGlow = Color3.fromRGB(0, 150, 255),
            Red = Color3.fromRGB(255, 55, 55),
            RedHover = Color3.fromRGB(255, 85, 85),
            Green = Color3.fromRGB(0, 210, 106),
            GreenDark = Color3.fromRGB(0, 170, 85),
            Yellow = Color3.fromRGB(255, 193, 7),
            Orange = Color3.fromRGB(255, 152, 0),
            Purple = Color3.fromRGB(156, 39, 176),
            Text = Color3.fromRGB(235, 235, 245),
            TextSecondary = Color3.fromRGB(160, 160, 180),
            TextDim = Color3.fromRGB(100, 100, 120),
            Border = Color3.fromRGB(50, 50, 70),
            Shadow = Color3.fromRGB(0, 0, 0),
            ProgressBg = Color3.fromRGB(20, 20, 32),
            ProgressFill = Color3.fromRGB(0, 122, 255),
        },
        Red = {
            Primary = Color3.fromRGB(20, 14, 18),
            Secondary = Color3.fromRGB(35, 22, 28),
            Tertiary = Color3.fromRGB(50, 30, 38),
            Accent = Color3.fromRGB(220, 40, 60),
            AccentHover = Color3.fromRGB(240, 60, 80),
            AccentDark = Color3.fromRGB(180, 30, 50),
            AccentGlow = Color3.fromRGB(255, 70, 90),
            Red = Color3.fromRGB(255, 55, 55),
            RedHover = Color3.fromRGB(255, 85, 85),
            Green = Color3.fromRGB(0, 210, 106),
            GreenDark = Color3.fromRGB(0, 170, 85),
            Yellow = Color3.fromRGB(255, 193, 7),
            Orange = Color3.fromRGB(255, 152, 0),
            Purple = Color3.fromRGB(156, 39, 176),
            Text = Color3.fromRGB(235, 235, 245),
            TextSecondary = Color3.fromRGB(160, 160, 180),
            TextDim = Color3.fromRGB(100, 100, 120),
            Border = Color3.fromRGB(60, 40, 50),
            Shadow = Color3.fromRGB(0, 0, 0),
            ProgressBg = Color3.fromRGB(25, 15, 20),
            ProgressFill = Color3.fromRGB(220, 40, 60),
        },
        Purple = {
            Primary = Color3.fromRGB(16, 14, 24),
            Secondary = Color3.fromRGB(28, 24, 40),
            Tertiary = Color3.fromRGB(40, 34, 56),
            Accent = Color3.fromRGB(130, 50, 220),
            AccentHover = Color3.fromRGB(150, 70, 240),
            AccentDark = Color3.fromRGB(100, 30, 180),
            AccentGlow = Color3.fromRGB(170, 90, 255),
            Red = Color3.fromRGB(255, 55, 55),
            RedHover = Color3.fromRGB(255, 85, 85),
            Green = Color3.fromRGB(0, 210, 106),
            GreenDark = Color3.fromRGB(0, 170, 85),
            Yellow = Color3.fromRGB(255, 193, 7),
            Orange = Color3.fromRGB(255, 152, 0),
            Purple = Color3.fromRGB(156, 39, 176),
            Text = Color3.fromRGB(235, 235, 245),
            TextSecondary = Color3.fromRGB(160, 160, 180),
            TextDim = Color3.fromRGB(100, 100, 120),
            Border = Color3.fromRGB(50, 40, 70),
            Shadow = Color3.fromRGB(0, 0, 0),
            ProgressBg = Color3.fromRGB(20, 16, 30),
            ProgressFill = Color3.fromRGB(130, 50, 220),
        },
        Green = {
            Primary = Color3.fromRGB(12, 20, 16),
            Secondary = Color3.fromRGB(20, 32, 26),
            Tertiary = Color3.fromRGB(28, 44, 36),
            Accent = Color3.fromRGB(0, 180, 90),
            AccentHover = Color3.fromRGB(0, 210, 110),
            AccentDark = Color3.fromRGB(0, 140, 70),
            AccentGlow = Color3.fromRGB(0, 230, 130),
            Red = Color3.fromRGB(255, 55, 55),
            RedHover = Color3.fromRGB(255, 85, 85),
            Green = Color3.fromRGB(0, 210, 106),
            GreenDark = Color3.fromRGB(0, 170, 85),
            Yellow = Color3.fromRGB(255, 193, 7),
            Orange = Color3.fromRGB(255, 152, 0),
            Purple = Color3.fromRGB(156, 39, 176),
            Text = Color3.fromRGB(235, 235, 245),
            TextSecondary = Color3.fromRGB(160, 160, 180),
            TextDim = Color3.fromRGB(100, 100, 120),
            Border = Color3.fromRGB(30, 55, 40),
            Shadow = Color3.fromRGB(0, 0, 0),
            ProgressBg = Color3.fromRGB(14, 22, 18),
            ProgressFill = Color3.fromRGB(0, 180, 90),
        },
    },
}

-- Get current theme
function BaoSaveInstance.Config:GetTheme()
    return self.Themes[self.Theme] or self.Themes.Blue
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 3: ADVANCED LOGGER                                     ║
-- ╚══════════════════════════════════════════════════════════════╝

do
    local Logger = BaoSaveInstance.Logger
    Logger.Logs = {}
    Logger.MaxLogs = 2000
    Logger.LogLevel = 0 -- 0=ALL, 1=INFO+, 2=WARN+, 3=ERROR
    Logger.Callbacks = {} -- Callbacks khi có log mới
    
    local LOG_LEVELS = {
        DEBUG = 0,
        INFO = 1,
        WARN = 2,
        ERROR = 3,
        SUCCESS = 1,
        CRITICAL = 4,
        PERF = 0,
    }
    
    local LOG_ICONS = {
        DEBUG = "🔍",
        INFO = "ℹ️",
        WARN = "⚠️",
        ERROR = "❌",
        SUCCESS = "✅",
        CRITICAL = "🔥",
        PERF = "⚡",
    }
    
    function Logger:Add(level, message, details)
        if LOG_LEVELS[level] and LOG_LEVELS[level] < self.LogLevel then
            return
        end
        
        local entry = {
            Id = #self.Logs + 1,
            Time = os.clock(),
            Level = level,
            Message = tostring(message),
            Details = details,
            Timestamp = os.date("%H:%M:%S"),
            Memory = math.floor(collectgarbage("count")),
        }
        
        table.insert(self.Logs, entry)
        
        -- Trim old logs
        while #self.Logs > self.MaxLogs do
            table.remove(self.Logs, 1)
        end
        
        -- Console output
        local icon = LOG_ICONS[level] or "📋"
        local prefix = "[BaoSaveInstance]"
        local text = string.format("%s %s [%s] %s", prefix, icon, level, message)
        
        if level == "ERROR" or level == "CRITICAL" or level == "WARN" then
            warn(text)
        else
            print(text)
        end
        
        -- Trigger callbacks
        for _, cb in ipairs(self.Callbacks) do
            pcall(cb, entry)
        end
    end
    
    function Logger:Debug(msg, details) self:Add("DEBUG", msg, details) end
    function Logger:Info(msg, details) self:Add("INFO", msg, details) end
    function Logger:Warn(msg, details) self:Add("WARN", msg, details) end
    function Logger:Error(msg, details) self:Add("ERROR", msg, details) end
    function Logger:Success(msg, details) self:Add("SUCCESS", msg, details) end
    function Logger:Critical(msg, details) self:Add("CRITICAL", msg, details) end
    function Logger:Perf(msg, details) self:Add("PERF", msg, details) end
    
    function Logger:OnLog(callback)
        table.insert(self.Callbacks, callback)
    end
    
    function Logger:GetRecent(count)
        count = count or 50
        local result = {}
        local start = math.max(1, #self.Logs - count + 1)
        for i = start, #self.Logs do
            table.insert(result, self.Logs[i])
        end
        return result
    end
    
    function Logger:Clear()
        self.Logs = {}
    end
    
    function Logger:Export()
        local lines = {}
        for _, entry in ipairs(self.Logs) do
            table.insert(lines, string.format(
                "[%s] [%s] [%dKB] %s%s",
                entry.Timestamp,
                entry.Level,
                entry.Memory,
                entry.Message,
                entry.Details and (" | " .. tostring(entry.Details)) or ""
            ))
        end
        return table.concat(lines, "\n")
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 4: PERFORMANCE MONITOR                                  ║
-- ╚══════════════════════════════════════════════════════════════╝

do
    local Perf = BaoSaveInstance.Performance
    Perf.Timers = {}
    Perf.Counters = {}
    Perf.MemorySnapshots = {}
    
    function Perf:StartTimer(name)
        self.Timers[name] = os.clock()
    end
    
    function Perf:StopTimer(name)
        if self.Timers[name] then
            local elapsed = os.clock() - self.Timers[name]
            self.Timers[name] = nil
            BaoSaveInstance.Logger:Perf(string.format("%s: %.3fs", name, elapsed))
            return elapsed
        end
        return 0
    end
    
    function Perf:Increment(name, amount)
        self.Counters[name] = (self.Counters[name] or 0) + (amount or 1)
    end
    
    function Perf:GetCounter(name)
        return self.Counters[name] or 0
    end
    
    function Perf:SnapshotMemory(label)
        local mem = collectgarbage("count")
        table.insert(self.MemorySnapshots, {
            Label = label,
            Memory = mem,
            Time = os.clock(),
        })
        return mem
    end
    
    function Perf:GetMemoryMB()
        return math.floor(collectgarbage("count") / 1024 * 100) / 100
    end
    
    function Perf:SmartGC()
        local mem = collectgarbage("count") / 1024
        if mem > BaoSaveInstance.Config.MaxMemoryMB * 0.8 then
            collectgarbage("collect")
            BaoSaveInstance.Logger:Debug("GC triggered at " .. math.floor(mem) .. "MB")
        end
    end
    
    function Perf:Reset()
        self.Timers = {}
        self.Counters = {}
        self.MemorySnapshots = {}
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 5: UTILITY MODULE (EXPANDED)                           ║
-- ╚══════════════════════════════════════════════════════════════╝

do
    local Utils = BaoSaveInstance.Utils
    
    --- Lấy tên game an toàn với cache
    Utils._gameNameCache = nil
    function Utils:GetGameName()
        if self._gameNameCache then
            return self._gameNameCache
        end
        
        local name = "UnknownGame"
        
        -- Method 1: MarketplaceService
        pcall(function()
            local info = MarketplaceService:GetProductInfo(game.PlaceId)
            if info and info.Name and info.Name ~= "" then
                name = info.Name
            end
        end)
        
        -- Method 2: Fallback to PlaceId
        if name == "UnknownGame" then
            name = "Game_" .. tostring(game.PlaceId)
        end
        
        -- Sanitize filename
        name = name:gsub("[\\/:*?\"<>|%z]", "_")
        name = name:gsub("[%c]", "")
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        name = name:gsub("%s+", " ")
        name = name:sub(1, 100)
        
        if name == "" then
            name = "Game_" .. tostring(game.PlaceId)
        end
        
        self._gameNameCache = name
        return name
    end
    
    --- Tạo tên file export
    function Utils:GetExportFileName(suffix)
        local gameName = self:GetGameName()
        suffix = suffix or ""
        if suffix ~= "" then
            suffix = " " .. suffix
        end
        return gameName .. suffix .. " Decompile By BaoSaveInstance.rbxl"
    end
    
    --- Format bytes
    function Utils:FormatBytes(bytes)
        if not bytes or bytes < 0 then return "0 B" end
        local units = {"B", "KB", "MB", "GB", "TB"}
        local i = 1
        while bytes >= 1024 and i < #units do
            bytes = bytes / 1024
            i = i + 1
        end
        if i == 1 then
            return string.format("%d %s", bytes, units[i])
        end
        return string.format("%.2f %s", bytes, units[i])
    end
    
    --- Format thời gian
    function Utils:FormatTime(seconds)
        if not seconds or seconds < 0 then return "0s" end
        if seconds < 1 then
            return string.format("%dms", seconds * 1000)
        elseif seconds < 60 then
            return string.format("%.1fs", seconds)
        elseif seconds < 3600 then
            return string.format("%dm %ds", math.floor(seconds / 60), math.floor(seconds % 60))
        else
            return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
        end
    end
    
    --- Tính ETA
    function Utils:CalculateETA(processed, total, startTime)
        if processed <= 0 or total <= 0 then return "Calculating..." end
        local elapsed = os.clock() - startTime
        local rate = processed / elapsed
        local remaining = (total - processed) / rate
        return self:FormatTime(remaining)
    end
    
    --- Clone an toàn với retry
    function Utils:SafeClone(instance, retries)
        retries = retries or 3
        for i = 1, retries do
            local ok, result = pcall(function()
                return instance:Clone()
            end)
            if ok and result then
                return result
            end
            if i < retries then
                task.wait(0.01)
            end
        end
        return nil
    end
    
    --- Kiểm tra instance accessible
    function Utils:IsAccessible(instance)
        local ok = pcall(function()
            local _ = instance.Name
            local _ = instance.ClassName
        end)
        return ok
    end
    
    --- Kiểm tra archivable
    function Utils:IsArchivable(instance)
        local ok, archivable = pcall(function()
            return instance.Archivable
        end)
        return ok and archivable
    end
    
    --- Set archivable tạm thời
    function Utils:ForceArchivable(instance)
        local original
        pcall(function()
            original = instance.Archivable
            instance.Archivable = true
        end)
        return original
    end
    
    --- Restore archivable
    function Utils:RestoreArchivable(instance, original)
        if original ~= nil then
            pcall(function()
                instance.Archivable = original
            end)
        end
    end
    
    --- Đếm descendants an toàn
    function Utils:CountDescendants(instance)
        local count = 0
        pcall(function()
            count = #instance:GetDescendants()
        end)
        return count
    end
    
    --- Smart yield - yield thông minh dựa trên cấu hình
    function Utils:SmartYield(counter, threshold)
        threshold = threshold or BaoSaveInstance.Config.ChunkSize
        if counter % threshold == 0 then
            if BaoSaveInstance.Config.AntiLagMode then
                task.wait(BaoSaveInstance.Config.YieldInterval)
            else
                task.wait()
            end
            -- Check memory
            BaoSaveInstance.Performance:SmartGC()
        end
    end
    
    --- Tạo folder an toàn
    function Utils:EnsureFolder(path)
        if ENV.isfolder and ENV.makefolder then
            pcall(function()
                if not ENV.isfolder(path) then
                    ENV.makefolder(path)
                end
            end)
        end
    end
    
    --- Kiểm tra file tồn tại
    function Utils:FileExists(path)
        if ENV.isfile then
            local ok, result = pcall(function()
                return ENV.isfile(path)
            end)
            return ok and result
        end
        return false
    end
    
    --- Ghi file an toàn
    function Utils:WriteFile(path, content)
        if not ENV.writefile then
            return false, "writefile not available"
        end
        
        local ok, err = pcall(function()
            ENV.writefile(path, content)
        end)
        
        return ok, err
    end
    
    --- Deep copy table
    function Utils:DeepCopy(t)
        if type(t) ~= "table" then return t end
        local copy = {}
        for k, v in pairs(t) do
            copy[self:DeepCopy(k)] = self:DeepCopy(v)
        end
        return copy
    end
    
    --- Get full path of instance
    function Utils:GetFullPath(instance)
        local parts = {}
        local current = instance
        while current and current ~= game do
            local ok, name = pcall(function() return current.Name end)
            if ok then
                table.insert(parts, 1, name)
            else
                table.insert(parts, 1, "???")
            end
            pcall(function() current = current.Parent end)
        end
        return "game." .. table.concat(parts, ".")
    end
    
    --- Generate unique ID
    local _uidCounter = 0
    function Utils:GenerateUID()
        _uidCounter = _uidCounter + 1
        return string.format("BSI_%08X", _uidCounter)
    end
    
    --- Truncate string
    function Utils:Truncate(str, maxLen)
        maxLen = maxLen or 50
        if #str > maxLen then
            return str:sub(1, maxLen - 3) .. "..."
        end
        return str
    end
    
    --- Detect instance type category
    function Utils:GetInstanceCategory(instance)
        local ok, className = pcall(function() return instance.ClassName end)
        if not ok then return "Unknown" end
        
        if instance:IsA("BasePart") then return "Part"
        elseif instance:IsA("Model") then return "Model"
        elseif instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript") then return "Script"
        elseif instance:IsA("GuiObject") then return "GUI"
        elseif instance:IsA("Light") then return "Light"
        elseif instance:IsA("Sound") then return "Sound"
        elseif instance:IsA("ParticleEmitter") or instance:IsA("Fire") or instance:IsA("Smoke") or instance:IsA("Sparkles") then return "Effect"
        elseif instance:IsA("Decal") or instance:IsA("Texture") then return "Texture"
        elseif instance:IsA("SpecialMesh") or instance:IsA("MeshPart") then return "Mesh"
        elseif instance:IsA("Terrain") then return "Terrain"
        elseif instance:IsA("Camera") then return "Camera"
        elseif instance:IsA("Folder") then return "Folder"
        elseif instance:IsA("ValueBase") then return "Value"
        elseif instance:IsA("Constraint") then return "Constraint"
        elseif instance:IsA("Attachment") then return "Attachment"
        elseif instance:IsA("Animation") or instance:IsA("AnimationController") then return "Animation"
        else return "Other"
        end
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 6: STATE MANAGER                                       ║
-- ╚══════════════════════════════════════════════════════════════╝

do
    local State = BaoSaveInstance.State
    
    State.IsRunning = false
    State.IsPaused = false
    State.CancelRequested = false
    State.CurrentOperation = "Idle"
    State.CurrentPhase = ""
    State.Progress = 0
    State.TotalItems = 0
    State.ProcessedItems = 0
    State.CurrentAPI = "None"
    State.StartTime = 0
    State.Errors = 0
    State.Warnings = 0
    State.SkippedItems = 0
    State.StatusMessage = "Sẵn sàng"
    State.ETA = ""
    State.Speed = 0  -- items/sec
    State.OutputFile = ""
    
    -- Statistics
    State.Stats = {
        TotalParts = 0,
        TotalModels = 0,
        TotalScripts = 0,
        TotalGUIs = 0,
        TotalSounds = 0,
        TotalTextures = 0,
        TotalMeshes = 0,
        TotalAnimations = 0,
        TotalOther = 0,
        DecompiledScripts = 0,
        FailedScripts = 0,
        DownloadedAssets = 0,
        FailedAssets = 0,
    }
    
    function State:Reset()
        self.IsRunning = false
        self.IsPaused = false
        self.CancelRequested = false
        self.CurrentOperation = "Idle"
        self.CurrentPhase = ""
        self.Progress = 0
        self.TotalItems = 0
        self.ProcessedItems = 0
        self.CurrentAPI = "None"
        self.StartTime = 0
        self.Errors = 0
        self.Warnings = 0
        self.SkippedItems = 0
        self.StatusMessage = "Sẵn sàng"
        self.ETA = ""
        self.Speed = 0
        self.OutputFile = ""
        
        for k in pairs(self.Stats) do
            self.Stats[k] = 0
        end
    end
    
    function State:UpdateProgress(processed, total, message)
        self.ProcessedItems = processed
        self.TotalItems = total
        if total > 0 then
            self.Progress = math.clamp(processed / total, 0, 1)
        end
        
        -- Calculate speed
        local elapsed = os.clock() - self.StartTime
        if elapsed > 0 then
            self.Speed = math.floor(processed / elapsed)
        end
        
        -- Calculate ETA
        if processed > 0 and total > processed then
            self.ETA = BaoSaveInstance.Utils:CalculateETA(processed, total, self.StartTime)
        elseif processed >= total then
            self.ETA = "Done"
        end
        
        if message then
            self.StatusMessage = message
        end
        
        -- Update GUI
        if BaoSaveInstance.GUI.UpdateProgress then
            BaoSaveInstance.GUI.UpdateProgress(
                self.Progress,
                self.StatusMessage,
                self.ETA,
                self.Speed
            )
        end
    end
    
    function State:CheckCancel()
        if self.CancelRequested then
            BaoSaveInstance.Logger:Warn("Operation cancelled by user")
            return true
        end
        return false
    end
    
    function State:WaitIfPaused()
        while self.IsPaused and not self.CancelRequested do
            task.wait(0.1)
        end
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 7: STEALTH MODULE                                      ║
-- ╚══════════════════════════════════════════════════════════════╝

do
    local Stealth = BaoSaveInstance.Stealth
    
    function Stealth:Apply()
        if not BaoSaveInstance.Config.StealthMode then return end
        
        BaoSaveInstance.Logger:Debug("Applying stealth measures...")
        
        -- Spoof script context nếu có thể
        pcall(function()
            if ENV.getrawmetatable then
                -- Hook some anti-cheat checks
            end
        end)
        
        -- Protect GUI
        pcall(function()
            local gui = BaoSaveInstance.GUI.ScreenGui
            if gui and ENV.protect_gui then
                -- Một số executor hỗ trợ protect_gui
            end
        end)
        
        BaoSaveInstance.Logger:Debug("Stealth measures applied")
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 8: SCRIPT HANDLER - DECOMPILE SCRIPTS                  ║
-- ╚══════════════════════════════════════════════════════════════╝

do
    local ScriptHandler = BaoSaveInstance.ScriptHandler
    ScriptHandler.Cache = {}
    ScriptHandler.Stats = {
        Total = 0,
        Decompiled = 0,
        Failed = 0,
        Cached = 0,
        BytecodeRecovered = 0,
    }
    
    --- Decompile một script
    function ScriptHandler:Decompile(scriptInstance)
        if not scriptInstance then return nil end
        if not BaoSaveInstance.Config.DecompileScripts then return "-- Decompile disabled" end
        
        -- Check cache
        local cacheKey
        pcall(function()
            cacheKey = tostring(scriptInstance:GetDebugId())
        end)
        if not cacheKey then
            cacheKey = tostring(scriptInstance)
        end
        
        if self.Cache[cacheKey] then
            self.Stats.Cached = self.Stats.Cached + 1
            return self.Cache[cacheKey]
        end
        
        self.Stats.Total = self.Stats.Total + 1
        
        local source = nil
        local methods = {}
        
        -- Method 1: Direct decompile function
        if ENV.decompile then
            table.insert(methods, {
                Name = "decompile()",
                Fn = function()
                    return ENV.decompile(scriptInstance)
                end
            })
        end
        
        -- Method 2: Source property (ModuleScripts sometimes)
        table.insert(methods, {
            Name = "Source property",
            Fn = function()
                return scriptInstance.Source
            end
        })
        
        -- Method 3: getscriptbytecode + custom decompile
        if ENV.getscriptbytecode then
            table.insert(methods, {
                Name = "getscriptbytecode()",
                Fn = function()
                    local bytecode = ENV.getscriptbytecode(scriptInstance)
                    if bytecode and #bytecode > 0 then
                        self.Stats.BytecodeRecovered = self.Stats.BytecodeRecovered + 1
                        return "-- Bytecode recovered (" .. #bytecode .. " bytes)\n-- Decompilation not available for this method\n-- Script: " .. scriptInstance:GetFullName()
                    end
                    return nil
                end
            })
        end
        
        -- Method 4: Try through loaded modules
        if scriptInstance:IsA("ModuleScript") and ENV.getloadedmodules then
            table.insert(methods, {
                Name = "getloadedmodules()",
                Fn = function()
                    local modules = ENV.getloadedmodules()
                    for _, mod in ipairs(modules) do
                        if mod == scriptInstance then
                            if ENV.decompile then
                                return ENV.decompile(mod)
                            end
                        end
                    end
                    return nil
                end
            })
        end
        
        -- Try each method
        for _, method in ipairs(methods) do
            local ok, result = pcall(method.Fn)
            if ok and result and type(result) == "string" and #result > 0 then
                source = result
                BaoSaveInstance.Logger:Debug("Decompiled " .. scriptInstance.Name .. " via " .. method.Name)
                break
            end
        end
        
        -- Process decompiled source
        if source and #source > 0 then
            self.Stats.Decompiled = self.Stats.Decompiled + 1
            
            -- Add header comment
            if BaoSaveInstance.Config.IncludeComments then
                local header = string.format(
                    "-- Decompiled by BaoSaveInstance v%s\n" ..
                    "-- Script: %s\n" ..
                    "-- Type: %s\n" ..
                    "-- Path: %s\n" ..
                    "-- Date: %s\n\n",
                    BaoSaveInstance.Version,
                    scriptInstance.Name,
                    scriptInstance.ClassName,
                    BaoSaveInstance.Utils:GetFullPath(scriptInstance),
                    os.date("%Y-%m-%d %H:%M:%S")
                )
                source = header .. source
            end
        else
            self.Stats.Failed = self.Stats.Failed + 1
            
            -- Generate placeholder
            if BaoSaveInstance.Config.RecoverCorruptScripts then
                source = string.format(
                    "-- [BaoSaveInstance] Failed to decompile this script\n" ..
                    "-- Script: %s\n" ..
                    "-- Type: %s\n" ..
                    "-- Path: %s\n" ..
                    "-- This script could not be decompiled.\n" ..
                    "-- Possible reasons: obfuscated, native code, or access denied.\n",
                    scriptInstance.Name,
                    scriptInstance.ClassName,
                    pcall(function() return scriptInstance:GetFullName() end) and scriptInstance:GetFullName() or "Unknown"
                )
            else
                source = "-- Failed to decompile"
            end
        end
        
        -- Cache
        self.Cache[cacheKey] = source
        return source
    end
    
    --- Decompile tất cả scripts trong một instance
    function ScriptHandler:DecompileAll(rootInstance)
        if not rootInstance then return end
        
        local scripts = {}
        pcall(function()
            for _, desc in ipairs(rootInstance:GetDescendants()) do
                if desc:IsA("LuaSourceContainer") then
                    table.insert(scripts, desc)
                end
            end
        end)
        
        BaoSaveInstance.Logger:Info(string.format("Found %d scripts to decompile", #scripts))
        
        for i, script in ipairs(scripts) do
            if BaoSaveInstance.State:CheckCancel() then break end
            BaoSaveInstance.State:WaitIfPaused()
            
            pcall(function()
                self:Decompile(script)
            end)
            
            BaoSaveInstance.Utils:SmartYield(i, 10)
            
            if i % 10 == 0 then
                BaoSaveInstance.Logger:Debug(string.format(
                    "Script decompile progress: %d/%d (%.1f%%)",
                    i, #scripts, (i / #scripts) * 100
                ))
            end
        end
        
        BaoSaveInstance.Logger:Info(string.format(
            "Script decompile complete: %d/%d succeeded, %d failed, %d cached",
            self.Stats.Decompiled, self.Stats.Total, self.Stats.Failed, self.Stats.Cached
        ))
    end
    
    function ScriptHandler:ClearCache()
        self.Cache = {}
    end
    
    function ScriptHandler:ResetStats()
        for k in pairs(self.Stats) do
            self.Stats[k] = 0
        end
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 9: PROPERTY HANDLER - HIDDEN/SECURITY PROPERTIES       ║
-- ╚══════════════════════════════════════════════════════════════╝

do
    local PropHandler = BaoSaveInstance.PropertyHandler
    PropHandler.Cache = {}
    
    -- Known hidden properties that are important
    PropHandler.HiddenProperties = {
        BasePart = {
            "CollisionGroup",
            "CustomPhysicalProperties",
        },
        MeshPart = {
            "PhysicsData",
            "InitialSize",
        },
        UnionOperation = {
            "AssetId",
            "InitialSize",
            "PhysicsData",
            "ChildData",
            "MeshData",
            "FormFactor",
        },
        Terrain = {
            "SmoothGrid",
            "MaterialColors",
        },
        TriangleMeshPart = {
            "PhysicsData",
            "InitialSize",
        },
        FormFactorPart = {
            "FormFactor",
        },
        Humanoid = {
            "InternalHeadScale",
            "InternalBodyScale",
        },
    }
    
    --- Lấy hidden property
    function PropHandler:GetHiddenProperty(instance, propName)
        if not ENV.gethiddenproperty then
            return nil, false
        end
        
        local ok, value = pcall(function()
            return ENV.gethiddenproperty(instance, propName)
        end)
        
        return ok and value or nil, ok
    end
    
    --- Set hidden property
    function PropHandler:SetHiddenProperty(instance, propName, value)
        if not ENV.sethiddenproperty then
            return false
        end
        
        local ok = pcall(function()
            ENV.sethiddenproperty(instance, propName, value)
        end)
        
        return ok
    end
    
    --- Lấy tất cả hidden properties cho instance
    function PropHandler:GetAllHiddenProperties(instance)
        if not BaoSaveInstance.Config.SaveHiddenProperties then return {} end
        
        local results = {}
        local className
        pcall(function() className = instance.ClassName end)
        if not className then return results end
        
        -- Check exact class
        local props = self.HiddenProperties[className]
        if props then
            for _, propName in ipairs(props) do
                local value, success = self:GetHiddenProperty(instance, propName)
                if success then
                    results[propName] = value
                end
            end
        end
        
        -- Check parent classes
        for class, classProps in pairs(self.HiddenProperties) do
            if class ~= className then
                local isA = pcall(function()
                    return instance:IsA(class)
                end)
                if isA then
                    for _, propName in ipairs(classProps) do
                        if not results[propName] then
                            local value, success = self:GetHiddenProperty(instance, propName)
                            if success then
                                results[propName] = value
                            end
                        end
                    end
                end
            end
        end
        
        return results
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 10: TERRAIN HANDLER                                    ║
-- ╚══════════════════════════════════════════════════════════════╝

do
    local TerrainHandler = BaoSaveInstance.TerrainHandler
    
    --- Get terrain info
    function TerrainHandler:GetTerrainInfo()
        local info = {
            HasTerrain = false,
            Size = Vector3.new(0, 0, 0),
            VoxelCount = 0,
        }
        
        pcall(function()
            local terrain = Workspace.Terrain
            if terrain then
                info.HasTerrain = true
                
                -- Try to get terrain region
                local region = terrain:ReadVoxels(
                    Region3.new(Vector3.new(-4, -4, -4), Vector3.new(4, 4, 4)),
                    4
                )
                if region then
                    info.HasTerrain = true
                end
            end
        end)
        
        return info
    end
    
    --- Terrain data nằm trong saveinstance, 
    --- module này chủ yếu quản lý options liên quan terrain
    function TerrainHandler:GetTerrainOptions()
        return {
            IncludeTerrain = BaoSaveInstance.Config.IncludeTerrain,
        }
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 11: SCANNER - QUÉT & PHÂN TÍCH GAME                   ║
-- ╚══════════════════════════════════════════════════════════════╝

do
    local Scanner = BaoSaveInstance.Scanner
    Scanner.Results = {}
    
    --- Quét toàn bộ game
    function Scanner:ScanGame()
        BaoSaveInstance.Performance:StartTimer("GameScan")
        BaoSaveInstance.Logger:Info("Starting game scan...")
        
        local results = {
            TotalInstances = 0,
            Categories = {},
            Services = {},
            Scripts = { Total = 0, Scripts = 0, LocalScripts = 0, ModuleScripts = 0 },
            Assets = { Meshes = 0, Textures = 0, Sounds = 0, Animations = 0 },
            LargestModels = {},
            HasTerrain = false,
            TerrainSize = "N/A",
            EstimatedFileSize = 0,
        }
        
        -- Scan các services
        local servicesToScan = {
            { Name = "Workspace", Service = Workspace },
            { Name = "Lighting", Service = Lighting },
            { Name = "ReplicatedStorage", Service = ReplicatedStorage },
            { Name = "ReplicatedFirst", Service = ReplicatedFirst },
            { Name = "StarterGui", Service = StarterGui },
            { Name = "StarterPlayer", Service = StarterPlayer },
            { Name = "StarterPack", Service = StarterPack },
            { Name = "SoundService", Service = SoundService },
            { Name = "Chat", Service = Chat },
            { Name = "Teams", Service = Teams },
        }
        
        -- Try server services
        pcall(function()
            local ss = game:GetService("ServerStorage")
            table.insert(servicesToScan, { Name = "ServerStorage", Service = ss })
        end)
        pcall(function()
            local sss = game:GetService("ServerScriptService")
            table.insert(servicesToScan, { Name = "ServerScriptService", Service = sss })
        end)
        
        for _, svcInfo in ipairs(servicesToScan) do
            if svcInfo.Service then
                local svcResult = {
                    Name = svcInfo.Name,
                    InstanceCount = 0,
                    Accessible = true,
                }
                
                pcall(function()
                    local descendants = svcInfo.Service:GetDescendants()
                    svcResult.InstanceCount = #descendants
                    results.TotalInstances = results.TotalInstances + #descendants
                    
                    for _, desc in ipairs(descendants) do
                        -- Categorize
                        local cat = BaoSaveInstance.Utils:GetInstanceCategory(desc)
                        results.Categories[cat] = (results.Categories[cat] or 0) + 1
                        
                        -- Count scripts
                        pcall(function()
                            if desc:IsA("Script") then
                                results.Scripts.Scripts = results.Scripts.Scripts + 1
                                results.Scripts.Total = results.Scripts.Total + 1
                            elseif desc:IsA("LocalScript") then
                                results.Scripts.LocalScripts = results.Scripts.LocalScripts + 1
                                results.Scripts.Total = results.Scripts.Total + 1
                            elseif desc:IsA("ModuleScript") then
                                results.Scripts.ModuleScripts = results.Scripts.ModuleScripts + 1
                                results.Scripts.Total = results.Scripts.Total + 1
                            end
                        end)
                        
                        -- Count assets
                        pcall(function()
                            if desc:IsA("MeshPart") or desc:IsA("SpecialMesh") then
                                results.Assets.Meshes = results.Assets.Meshes + 1
                            elseif desc:IsA("Decal") or desc:IsA("Texture") then
                                results.Assets.Textures = results.Assets.Textures + 1
                            elseif desc:IsA("Sound") then
                                results.Assets.Sounds = results.Assets.Sounds + 1
                            elseif desc:IsA("Animation") then
                                results.Assets.Animations = results.Assets.Animations + 1
                            end
                        end)
                    end
                end)
                
                table.insert(results.Services, svcResult)
            end
        end
        
        -- Check terrain
        pcall(function()
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                results.HasTerrain = true
            end
        end)
        
        -- Estimate file size (rough)
        results.EstimatedFileSize = results.TotalInstances * 500 -- ~500 bytes per instance avg
        
        -- Nil instances
        if ENV.getnilinstances then
            pcall(function()
                local nilInst = ENV.getnilinstances()
                results.NilInstances = #nilInst
                results.TotalInstances = results.TotalInstances + #nilInst
            end)
        end
        
        self.Results = results
        
        local elapsed = BaoSaveInstance.Performance:StopTimer("GameScan")
        BaoSaveInstance.Logger:Info(string.format(
            "Game scan complete: %d instances, %d scripts, estimated %s",
            results.TotalInstances,
            results.Scripts.Total,
            BaoSaveInstance.Utils:FormatBytes(results.EstimatedFileSize)
        ))
        
        return results
    end
    
    --- Lấy summary string
    function Scanner:GetSummary()
        local r = self.Results
        if not r or not r.TotalInstances then
            return "No scan data"
        end
        
        local lines = {
            string.format("Total Instances: %d", r.TotalInstances),
            string.format("Scripts: %d (S:%d LS:%d MS:%d)",
                r.Scripts.Total, r.Scripts.Scripts,
                r.Scripts.LocalScripts, r.Scripts.ModuleScripts),
            string.format("Assets: M:%d T:%d S:%d A:%d",
                r.Assets.Meshes, r.Assets.Textures,
                r.Assets.Sounds, r.Assets.Animations),
            string.format("Terrain: %s", r.HasTerrain and "Yes" or "No"),
            string.format("Est. Size: %s", BaoSaveInstance.Utils:FormatBytes(r.EstimatedFileSize)),
        }
        
        return table.concat(lines, "\n")
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 12: API MODULE - 5 LAYER FALLBACK SYSTEM               ║
-- ╚══════════════════════════════════════════════════════════════╝

do
    local API = BaoSaveInstance.API
    API.Registry = {}
    API.CurrentName = "None"
    API.CurrentIndex = 0
    API.LastError = ""
    API.ExecutionHistory = {}
    
    --- Đăng ký API
    function API:Register(config)
        --[[
            config = {
                Name = "string",
                Priority = number,      -- lower = higher priority
                Description = "string",
                Check = function(),     -- returns bool
                Execute = function(options), -- returns bool, message
                Cleanup = function(),   -- optional cleanup
            }
        --]]
        table.insert(self.Registry, config)
        table.sort(self.Registry, function(a, b)
            return a.Priority < b.Priority
        end)
        BaoSaveInstance.Logger:Debug("API registered: " .. config.Name .. " (P:" .. config.Priority .. ")")
    end
    
    --- Kiểm tra API nào khả dụng
    function API:GetAvailableAPIs()
        local available = {}
        for i, api in ipairs(self.Registry) do
            local ok, result = pcall(api.Check)
            if ok and result then
                table.insert(available, { Index = i, API = api })
            end
        end
        return available
    end
    
    --- Thực thi với fallback
    function API:ExecuteWithFallback(options)
        local autoSwitch = BaoSaveInstance.Config.AutoAPISwitch ~= false
        
        BaoSaveInstance.Logger:Info("Starting API execution (AutoSwitch: " .. tostring(autoSwitch) .. ")")
        
        local attempts = {}
        
        for i, api in ipairs(self.Registry) do
            if BaoSaveInstance.State:CheckCancel() then
                return false, "Cancelled"
            end
            
            -- Check availability
            local checkOk, available = pcall(api.Check)
            if not checkOk or not available then
                BaoSaveInstance.Logger:Debug("API " .. api.Name .. " not available")
                table.insert(attempts, {
                    API = api.Name,
                    Status = "Unavailable",
                })
                if not autoSwitch then break end
                goto continue
            end
            
            -- Update state
            self.CurrentName = api.Name
            self.CurrentIndex = i
            BaoSaveInstance.State.CurrentAPI = api.Name
            BaoSaveInstance.Logger:Info("Executing API: " .. api.Name)
            
            if BaoSaveInstance.GUI.UpdateAPIStatus then
                BaoSaveInstance.GUI.UpdateAPIStatus(api.Name, "running")
            end
            
            -- Execute with timeout protection
            local execOk, execResult, execMsg
            
            execOk, execResult = pcall(function()
                return api.Execute(options)
            end)
            
            if execOk and execResult then
                -- Success!
                BaoSaveInstance.Logger:Success("API " .. api.Name .. " succeeded!")
                
                table.insert(attempts, {
                    API = api.Name,
                    Status = "Success",
                })
                
                if BaoSaveInstance.GUI.UpdateAPIStatus then
                    BaoSaveInstance.GUI.UpdateAPIStatus(api.Name, "success")
                end
                
                -- Record history
                table.insert(self.ExecutionHistory, {
                    Time = os.clock(),
                    API = api.Name,
                    Success = true,
                    Options = options.Mode,
                })
                
                return true, "Success with " .. api.Name
            else
                -- Failed
                local errMsg = execOk and "Returned false" or tostring(execResult)
                self.LastError = errMsg
                BaoSaveInstance.Logger:Warn("API " .. api.Name .. " failed: " .. errMsg)
                
                table.insert(attempts, {
                    API = api.Name,
                    Status = "Failed: " .. BaoSaveInstance.Utils:Truncate(errMsg, 50),
                })
                
                if BaoSaveInstance.GUI.UpdateAPIStatus then
                    BaoSaveInstance.GUI.UpdateAPIStatus(api.Name, "failed")
                end
                
                -- Cleanup
                if api.Cleanup then
                    pcall(api.Cleanup)
                end
                
                -- Record
                table.insert(self.ExecutionHistory, {
                    Time = os.clock(),
                    API = api.Name,
                    Success = false,
                    Error = errMsg,
                })
                
                if not autoSwitch then break end
            end
            
            ::continue::
        end
        
        -- All failed
        local summary = "All APIs failed:\n"
        for _, attempt in ipairs(attempts) do
            summary = summary .. "  " .. attempt.API .. ": " .. attempt.Status .. "\n"
        end
        
        BaoSaveInstance.Logger:Error(summary)
        return false, summary
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 12.1: ĐĂNG KÝ 5 API LAYERS                            ║
-- ╚══════════════════════════════════════════════════════════════╝

-- === API 1: Unified SaveInstance (Highest Priority) ===
BaoSaveInstance.API:Register({
    Name = "Unified SaveInstance",
    Priority = 1,
    Description = "Uses the executor's native saveinstance with maximum options",
    
    Check = function()
        return ENV.saveinstance ~= nil
    end,
    
    Execute = function(options)
        local Config = BaoSaveInstance.Config
        local fileName = options.FileName
        local mode = options.Mode
        
        BaoSaveInstance.Logger:Info("Unified SaveInstance - Mode: " .. mode)
        
        -- Build comprehensive save options
        local saveOpts = {
            -- File
            FileName = fileName,
            
            -- Mode
            mode = (mode == "full") and "full" or "optimized",
            
            -- Content options
            noscripts = not Config.DecompileScripts,
            scriptcache = true,
            decomptype = Config.DecompileMode == "deep" and "custom" or "default",
            
            -- Instance options
            NilInstances = Config.IncludeNilInstances,
            NilInstancesFixes = true,
            RemovePlayerCharacters = true,
            SavePlayers = false,
            IsolateStarterPlayer = true,
            IgnoreDefaultPlayerScripts = true,
            
            -- Property options  
            SaveHiddenProperties = Config.SaveHiddenProperties,
            IgnoreSharedStrings = false,
            SharedStringOverride = false,
            
            -- Performance
            ShowStatus = false,
            Timeout = Config.DecompileTimeout,
            MaxThreads = Config.ParallelProcessing and 4 or 1,
            
            -- Extra
            ExtraInstances = {},
            IgnoreList = {},
            
            -- Decompile
            DecompileTimeout = Config.DecompileTimeout,
            DecompileIgnore = {},
            
            -- Binary format
            Binary = true,
            Object = false,
        }
        
        -- Mode-specific configuration
        if mode == "full" then
            -- Include all possible services
            local extraInstances = {}
            
            local serviceList = {
                {Config.IncludeLighting, Lighting},
                {Config.IncludeReplicatedStorage, ReplicatedStorage},
                {Config.IncludeReplicatedFirst, ReplicatedFirst},
                {Config.IncludeStarterGui, StarterGui},
                {Config.IncludeStarterPlayer, StarterPlayer},
                {Config.IncludeStarterPack, StarterPack},
                {Config.IncludeSoundService, SoundService},
                {Config.IncludeChat, Chat},
                {Config.IncludeTeams, Teams},
                {Config.IncludeMaterialService, MaterialService},
            }
            
            for _, svc in ipairs(serviceList) do
                if svc[1] and svc[2] then
                    table.insert(extraInstances, svc[2])
                end
            end
            
            -- Server services
            if Config.IncludeServerStorage then
                pcall(function()
                    local ss = game:GetService("ServerStorage")
                    if ss then table.insert(extraInstances, ss) end
                end)
            end
            if Config.IncludeServerScriptService then
                pcall(function()
                    local sss = game:GetService("ServerScriptService")
                    if sss then table.insert(extraInstances, sss) end
                end)
            end
            
            saveOpts.ExtraInstances = extraInstances
            
        elseif mode == "model" then
            -- Only workspace models, no terrain
            saveOpts.mode = "optimized"
            -- Terrain is handled by saveinstance based on mode
            
            -- We specifically exclude terrain by adding to ignore
            pcall(function()
                if Workspace:FindFirstChildOfClass("Terrain") then
                    table.insert(saveOpts.IgnoreList, Workspace.Terrain)
                end
            end)
            
        elseif mode == "terrain" then
            -- Only terrain
            saveOpts.mode = "optimized"
            saveOpts.noscripts = true
            saveOpts.ExtraInstances = {}
            
            pcall(function()
                local terrain = Workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    saveOpts.ExtraInstances = {terrain}
                end
            end)
            
            -- Ignore everything except terrain
            pcall(function()
                for _, child in ipairs(Workspace:GetChildren()) do
                    if not child:IsA("Terrain") then
                        table.insert(saveOpts.IgnoreList, child)
                    end
                end
            end)
        end
        
        -- Pre-process: Make non-archivable instances archivable
        local archivableRestoreList = {}
        if mode == "full" or mode == "model" then
            pcall(function()
                for _, desc in ipairs(Workspace:GetDescendants()) do
                    pcall(function()
                        if not desc.Archivable then
                            table.insert(archivableRestoreList, {
                                Instance = desc,
                                Original = false
                            })
                            desc.Archivable = true
                        end
                    end)
                end
            end)
            BaoSaveInstance.Logger:Debug("Set " .. #archivableRestoreList .. " instances to Archivable")
        end
        
        -- Update progress
        BaoSaveInstance.State:UpdateProgress(0.1, 1, "Đang khởi tạo saveinstance...")
        
        -- Execute
        local ok, err = pcall(function()
            ENV.saveinstance(saveOpts)
        end)
        
        -- Restore archivable
        for _, entry in ipairs(archivableRestoreList) do
            pcall(function()
                entry.Instance.Archivable = entry.Original
            end)
        end
        
        if ok then
            BaoSaveInstance.State:UpdateProgress(1, 1, "Hoàn tất!")
            return true
        else
            BaoSaveInstance.Logger:Error("saveinstance error: " .. tostring(err))
            return false
        end
    end,
})

-- === API 2: Synapse Native ===
BaoSaveInstance.API:Register({
    Name = "Synapse Native",
    Priority = 2,
    Description = "Synapse X native saveinstance implementation",
    
    Check = function()
        return typeof(syn) == "table" and syn.saveinstance ~= nil
    end,
    
    Execute = function(options)
        BaoSaveInstance.Logger:Info("Synapse Native - Mode: " .. options.Mode)
        
        BaoSaveInstance.State:UpdateProgress(0.1, 1, "Synapse saveinstance...")
        
        local saveOpts = {
            FileName = options.FileName,
            ExtraInstances = {},
            RemovePlayerCharacters = true,
            SavePlayers = false,
            mode = options.Mode == "full" and "full" or "optimized",
            noscripts = not BaoSaveInstance.Config.DecompileScripts,
        }
        
        if options.Mode == "full" then
            for _, svc in ipairs({Lighting, ReplicatedStorage, StarterGui, StarterPlayer, SoundService}) do
                if svc then table.insert(saveOpts.ExtraInstances, svc) end
            end
        end
        
        local ok, err = pcall(function()
            syn.saveinstance(saveOpts)
        end)
        
        if ok then
            BaoSaveInstance.State:UpdateProgress(1, 1, "Hoàn tất!")
        end
        
        return ok
    end,
})

-- === API 3: Fluxus/Others Native ===
BaoSaveInstance.API:Register({
    Name = "Executor Native",
    Priority = 3,
    Description = "Other executor native saveinstance",
    
    Check = function()
        if typeof(fluxus) == "table" and fluxus.saveinstance then return true end
        if typeof(Hydrogen) == "table" then return true end
        if typeof(Delta) == "table" then return true end
        return false
    end,
    
    Execute = function(options)
        BaoSaveInstance.Logger:Info("Executor Native - Mode: " .. options.Mode)
        
        BaoSaveInstance.State:UpdateProgress(0.1, 1, "Executor saveinstance...")
        
        local saveOpts = {
            FileName = options.FileName,
            mode = options.Mode == "full" and "full" or "optimized",
            noscripts = not BaoSaveInstance.Config.DecompileScripts,
            RemovePlayerCharacters = true,
        }
        
        local ok, err
        
        if typeof(fluxus) == "table" and fluxus.saveinstance then
            ok, err = pcall(function() fluxus.saveinstance(saveOpts) end)
        else
            ok, err = pcall(function() saveinstance(saveOpts) end)
        end
        
        if ok then
            BaoSaveInstance.State:UpdateProgress(1, 1, "Hoàn tất!")
        end
        
        return ok
    end,
})

-- === API 4: Deep Clone + Custom Serializer ===
BaoSaveInstance.API:Register({
    Name = "Deep Clone Engine",
    Priority = 4,
    Description = "Custom deep clone with manual serialization",
    
    Check = function()
        return ENV.writefile ~= nil
    end,
    
    Execute = function(options)
        local fileName = options.FileName
        local mode = options.Mode
        
        BaoSaveInstance.Logger:Info("Deep Clone Engine - Mode: " .. mode)
        BaoSaveInstance.State:UpdateProgress(0, 1, "Deep Clone: Preparing...")
        
        -- Determine which services to clone
        local servicesToClone = {}
        
        if mode == "full" then
            servicesToClone = {
                {Service = Workspace, Name = "Workspace"},
                {Service = Lighting, Name = "Lighting"},
                {Service = ReplicatedStorage, Name = "ReplicatedStorage"},
                {Service = StarterGui, Name = "StarterGui"},
                {Service = StarterPlayer, Name = "StarterPlayer"},
                {Service = StarterPack, Name = "StarterPack"},
                {Service = SoundService, Name = "SoundService"},
            }
            
            if BaoSaveInstance.Config.IncludeReplicatedFirst and ReplicatedFirst then
                table.insert(servicesToClone, {Service = ReplicatedFirst, Name = "ReplicatedFirst"})
            end
            if BaoSaveInstance.Config.IncludeChat and Chat then
                table.insert(servicesToClone, {Service = Chat, Name = "Chat"})
            end
            if BaoSaveInstance.Config.IncludeTeams and Teams then
                table.insert(servicesToClone, {Service = Teams, Name = "Teams"})
            end
            
        elseif mode == "model" then
            servicesToClone = {{Service = Workspace, Name = "Workspace"}}
            
        elseif mode == "terrain" then
            servicesToClone = {{Service = Workspace, Name = "Workspace", OnlyTerrain = true}}
        end
        
        -- Build XML content
        local xmlParts = {}
        local refCounter = 0
        
        local function nextRef()
            refCounter = refCounter + 1
            return "RBX" .. string.format("%08X", refCounter)
        end
        
        local function escXML(s)
            if type(s) ~= "string" then s = tostring(s) end
            return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
        end
        
        local function serializeValue(propType, value)
            if propType == "string" then
                return escXML(tostring(value))
            elseif propType == "number" or propType == "float" or propType == "double" or propType == "int" then
                return tostring(value)
            elseif propType == "bool" then
                return tostring(value)
            elseif propType == "Vector3" then
                return string.format("<X>%s</X><Y>%s</Y><Z>%s</Z>", value.X, value.Y, value.Z)
            elseif propType == "CFrame" then
                local comp = {value:GetComponents()}
                local parts = {}
                for _, c in ipairs(comp) do
                    table.insert(parts, tostring(c))
                end
                return table.concat(parts, " ")
            elseif propType == "Color3" then
                return string.format("<R>%s</R><G>%s</G><B>%s</B>", value.R, value.G, value.B)
            elseif propType == "UDim2" then
                return string.format("<XS>%s</XS><XO>%s</XO><YS>%s</YS><YO>%s</YO>",
                    value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
            elseif propType == "Vector2" then
                return string.format("<X>%s</X><Y>%s</Y>", value.X, value.Y)
            elseif propType == "BrickColor" then
                return tostring(value.Number)
            elseif propType == "Enum" then
                return tostring(value.Value)
            end
            return escXML(tostring(value))
        end
        
        local function serializeInstance(inst, indent)
            if not BaoSaveInstance.Utils:IsAccessible(inst) then return end
            
            local className
            pcall(function() className = inst.ClassName end)
            if not className then return end
            
            -- Skip certain classes
            if className == "Player" or className == "PlayerScripts" then return end
            
            local ref = nextRef()
            table.insert(xmlParts, indent .. '<Item class="' .. escXML(className) .. '" referent="' .. ref .. '">')
            table.insert(xmlParts, indent .. '  <Properties>')
            
            -- Name
            pcall(function()
                table.insert(xmlParts, indent .. '    <string name="Name">' .. escXML(inst.Name) .. '</string>')
            end)
            
            -- Type-specific properties
            pcall(function()
                if inst:IsA("BasePart") then
                    local p = inst.Position
                    table.insert(xmlParts, indent .. '    <Vector3 name="Position">' .. serializeValue("Vector3", p) .. '</Vector3>')
                    local s = inst.Size
                    table.insert(xmlParts, indent .. '    <Vector3 name="Size">' .. serializeValue("Vector3", s) .. '</Vector3>')
                    
                    local cf = inst.CFrame
                    table.insert(xmlParts, indent .. '    <CoordinateFrame name="CFrame">' .. serializeValue("CFrame", cf) .. '</CoordinateFrame>')
                    
                    table.insert(xmlParts, indent .. '    <Color3 name="Color">' .. serializeValue("Color3", inst.Color) .. '</Color3>')
                    table.insert(xmlParts, indent .. '    <bool name="Anchored">' .. tostring(inst.Anchored) .. '</bool>')
                    table.insert(xmlParts, indent .. '    <bool name="CanCollide">' .. tostring(inst.CanCollide) .. '</bool>')
                    table.insert(xmlParts, indent .. '    <float name="Transparency">' .. inst.Transparency .. '</float>')
                    table.insert(xmlParts, indent .. '    <float name="Reflectance">' .. inst.Reflectance .. '</float>')
                    table.insert(xmlParts, indent .. '    <token name="Material">' .. inst.Material.Value .. '</token>')
                    table.insert(xmlParts, indent .. '    <token name="Shape">' .. (inst:IsA("Part") and inst.Shape.Value or 1) .. '</token>')
                    table.insert(xmlParts, indent .. '    <bool name="CastShadow">' .. tostring(inst.CastShadow) .. '</bool>')
                    table.insert(xmlParts, indent .. '    <bool name="Massless">' .. tostring(inst.Massless) .. '</bool>')
                end
                
                if inst:IsA("MeshPart") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <Content name="MeshId"><url>' .. escXML(inst.MeshId) .. '</url></Content>')
                        table.insert(xmlParts, indent .. '    <Content name="TextureID"><url>' .. escXML(inst.TextureID) .. '</url></Content>')
                    end)
                end
                
                if inst:IsA("Decal") or inst:IsA("Texture") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <Content name="Texture"><url>' .. escXML(inst.Texture) .. '</url></Content>')
                        table.insert(xmlParts, indent .. '    <float name="Transparency">' .. inst.Transparency .. '</float>')
                    end)
                end
                
                if inst:IsA("SpecialMesh") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <Content name="MeshId"><url>' .. escXML(inst.MeshId) .. '</url></Content>')
                        table.insert(xmlParts, indent .. '    <Content name="TextureId"><url>' .. escXML(inst.TextureId) .. '</url></Content>')
                        table.insert(xmlParts, indent .. '    <Vector3 name="Scale">' .. serializeValue("Vector3", inst.Scale) .. '</Vector3>')
                        table.insert(xmlParts, indent .. '    <Vector3 name="Offset">' .. serializeValue("Vector3", inst.Offset) .. '</Vector3>')
                        table.insert(xmlParts, indent .. '    <token name="MeshType">' .. inst.MeshType.Value .. '</token>')
                    end)
                end
                
                if inst:IsA("LuaSourceContainer") then
                    local source = BaoSaveInstance.ScriptHandler:Decompile(inst) or ""
                    table.insert(xmlParts, indent .. '    <ProtectedString name="Source"><![CDATA[' .. source .. ']]></ProtectedString>')
                    
                    if inst:IsA("Script") then
                        pcall(function()
                            table.insert(xmlParts, indent .. '    <bool name="Disabled">' .. tostring(inst.Disabled) .. '</bool>')
                        end)
                    end
                end
                
                if inst:IsA("Sound") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <Content name="SoundId"><url>' .. escXML(inst.SoundId) .. '</url></Content>')
                        table.insert(xmlParts, indent .. '    <float name="Volume">' .. inst.Volume .. '</float>')
                        table.insert(xmlParts, indent .. '    <float name="PlaybackSpeed">' .. inst.PlaybackSpeed .. '</float>')
                        table.insert(xmlParts, indent .. '    <bool name="Looped">' .. tostring(inst.Looped) .. '</bool>')
                    end)
                end
                
                if inst:IsA("Light") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <Color3 name="Color">' .. serializeValue("Color3", inst.Color) .. '</Color3>')
                        table.insert(xmlParts, indent .. '    <float name="Brightness">' .. inst.Brightness .. '</float>')
                        table.insert(xmlParts, indent .. '    <bool name="Enabled">' .. tostring(inst.Enabled) .. '</bool>')
                        table.insert(xmlParts, indent .. '    <bool name="Shadows">' .. tostring(inst.Shadows) .. '</bool>')
                        if inst:IsA("PointLight") or inst:IsA("SpotLight") then
                            table.insert(xmlParts, indent .. '    <float name="Range">' .. inst.Range .. '</float>')
                        end
                    end)
                end
                
                if inst:IsA("GuiObject") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <UDim2 name="Position">' .. serializeValue("UDim2", inst.Position) .. '</UDim2>')
                        table.insert(xmlParts, indent .. '    <UDim2 name="Size">' .. serializeValue("UDim2", inst.Size) .. '</UDim2>')
                        table.insert(xmlParts, indent .. '    <Color3 name="BackgroundColor3">' .. serializeValue("Color3", inst.BackgroundColor3) .. '</Color3>')
                        table.insert(xmlParts, indent .. '    <float name="BackgroundTransparency">' .. inst.BackgroundTransparency .. '</float>')
                        table.insert(xmlParts, indent .. '    <bool name="Visible">' .. tostring(inst.Visible) .. '</bool>')
                    end)
                end
                
                if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <string name="Text">' .. escXML(inst.Text) .. '</string>')
                        table.insert(xmlParts, indent .. '    <Color3 name="TextColor3">' .. serializeValue("Color3", inst.TextColor3) .. '</Color3>')
                        table.insert(xmlParts, indent .. '    <float name="TextSize">' .. inst.TextSize .. '</float>')
                        table.insert(xmlParts, indent .. '    <token name="Font">' .. inst.Font.Value .. '</token>')
                    end)
                end
                
                if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <Content name="Image"><url>' .. escXML(inst.Image) .. '</url></Content>')
                    end)
                end
                
                if inst:IsA("ParticleEmitter") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <Content name="Texture"><url>' .. escXML(inst.Texture) .. '</url></Content>')
                        table.insert(xmlParts, indent .. '    <float name="Rate">' .. inst.Rate .. '</float>')
                        table.insert(xmlParts, indent .. '    <float name="Speed">' .. inst.Speed.Min .. '</float>')
                        table.insert(xmlParts, indent .. '    <float name="Lifetime">' .. inst.Lifetime.Min .. '</float>')
                        table.insert(xmlParts, indent .. '    <bool name="Enabled">' .. tostring(inst.Enabled) .. '</bool>')
                    end)
                end
                
                if inst:IsA("Model") then
                    pcall(function()
                        if inst.PrimaryPart then
                            table.insert(xmlParts, indent .. '    <string name="PrimaryPart">' .. escXML(inst.PrimaryPart.Name) .. '</string>')
                        end
                    end)
                end
                
                -- Value instances
                if inst:IsA("StringValue") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <string name="Value">' .. escXML(inst.Value) .. '</string>')
                    end)
                elseif inst:IsA("IntValue") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <int name="Value">' .. inst.Value .. '</int>')
                    end)
                elseif inst:IsA("NumberValue") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <double name="Value">' .. inst.Value .. '</double>')
                    end)
                elseif inst:IsA("BoolValue") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <bool name="Value">' .. tostring(inst.Value) .. '</bool>')
                    end)
                elseif inst:IsA("ObjectValue") then
                    -- Skip object references in XML mode
                elseif inst:IsA("Color3Value") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <Color3 name="Value">' .. serializeValue("Color3", inst.Value) .. '</Color3>')
                    end)
                elseif inst:IsA("Vector3Value") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <Vector3 name="Value">' .. serializeValue("Vector3", inst.Value) .. '</Vector3>')
                    end)
                end
                
                -- Attachment
                if inst:IsA("Attachment") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <CFrame name="CFrame">' .. serializeValue("CFrame", inst.CFrame) .. '</CFrame>')
                        table.insert(xmlParts, indent .. '    <bool name="Visible">' .. tostring(inst.Visible) .. '</bool>')
                    end)
                end
                
                -- UICorner
                if inst:IsA("UICorner") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <UDim name="CornerRadius"><S>' .. inst.CornerRadius.Scale .. '</S><O>' .. inst.CornerRadius.Offset .. '</O></UDim>')
                    end)
                end
                
                -- UIStroke
                if inst:IsA("UIStroke") then
                    pcall(function()
                        table.insert(xmlParts, indent .. '    <Color3 name="Color">' .. serializeValue("Color3", inst.Color) .. '</Color3>')
                        table.insert(xmlParts, indent .. '    <float name="Thickness">' .. inst.Thickness .. '</float>')
                        table.insert(xmlParts, indent .. '    <float name="Transparency">' .. inst.Transparency .. '</float>')
                    end)
                end
            end)
            
            table.insert(xmlParts, indent .. '  </Properties>')
            
            -- Serialize children
            pcall(function()
                for _, child in ipairs(inst:GetChildren()) do
                    if BaoSaveInstance.Utils:IsAccessible(child) then
                        if not child:IsA("Player") and not child:IsA("Terrain") then
                            serializeInstance(child, indent .. "  ")
                        end
                    end
                    
                    refCounter = refCounter -- keep counter
                    if refCounter % 200 == 0 then
                        task.wait()
                    end
                end
            end)
            
            table.insert(xmlParts, indent .. '</Item>')
            
            BaoSaveInstance.Performance:Increment("SerializedInstances")
        end
        
        -- XML Header
        table.insert(xmlParts, 1, '<?xml version="1.0" encoding="utf-8"?>')
        table.insert(xmlParts, 2, '<roblox version="4">')
        table.insert(xmlParts, 3, '<!-- Decompiled by BaoSaveInstance v' .. BaoSaveInstance.Version .. ' -->')
        table.insert(xmlParts, 4, '<!-- Game: ' .. escXML(BaoSaveInstance.Utils:GetGameName()) .. ' -->')
        table.insert(xmlParts, 5, '<!-- PlaceId: ' .. tostring(game.PlaceId) .. ' -->')
        table.insert(xmlParts, 6, '<!-- Date: ' .. os.date("%Y-%m-%d %H:%M:%S") .. ' -->')
        table.insert(xmlParts, 7, '<!-- Executor: ' .. ENV.ExecutorName .. ' -->')
        
        -- Serialize services
        local totalSvc = #servicesToClone
        for svcIdx, svcInfo in ipairs(servicesToClone) do
            if BaoSaveInstance.State:CheckCancel() then return false end
            
            local progress = (svcIdx - 1) / totalSvc
            BaoSaveInstance.State:UpdateProgress(progress, 1, "Serializing: " .. svcInfo.Name)
            BaoSaveInstance.Logger:Info("Serializing service: " .. svcInfo.Name)
            
            pcall(function()
                if svcInfo.OnlyTerrain then
                    -- Terrain placeholder
                    table.insert(xmlParts, '  <Item class="Terrain" referent="' .. nextRef() .. '">')
                    table.insert(xmlParts, '    <Properties>')
                    table.insert(xmlParts, '      <string name="Name">Terrain</string>')
                    table.insert(xmlParts, '      <!-- Terrain voxel data requires native saveinstance -->')
                    table.insert(xmlParts, '    </Properties>')
                    table.insert(xmlParts, '  </Item>')
                else
                    local children = svcInfo.Service:GetChildren()
                    local totalChildren = #children
                    
                    -- Service container
                    table.insert(xmlParts, '  <Item class="Folder" referent="' .. nextRef() .. '">')
                    table.insert(xmlParts, '    <Properties>')
                    table.insert(xmlParts, '      <string name="Name">' .. escXML(svcInfo.Name) .. '</string>')
                    table.insert(xmlParts, '    </Properties>')
                    
                    for childIdx, child in ipairs(children) do
                        if BaoSaveInstance.State:CheckCancel() then break end
                        
                        if BaoSaveInstance.Utils:IsAccessible(child) then
                            if not child:IsA("Terrain") or BaoSaveInstance.Config.IncludeTerrain then
                                if not child:IsA("Player") then
                                    pcall(function()
                                        serializeInstance(child, "    ")
                                    end)
                                end
                            end
                        end
                        
                        BaoSaveInstance.Utils:SmartYield(childIdx, 50)
                        
                        local detailProgress = progress + (childIdx / totalChildren) * (1 / totalSvc)
                        if childIdx % 20 == 0 then
                            BaoSaveInstance.State:UpdateProgress(
                                detailProgress, 1,
                                string.format("%s: %d/%d", svcInfo.Name, childIdx, totalChildren)
                            )
                        end
                    end
                    
                    table.insert(xmlParts, '  </Item>')
                end
            end)
        end
        
        table.insert(xmlParts, '</roblox>')
        
        -- Write file
        BaoSaveInstance.State:UpdateProgress(0.95, 1, "Đang ghi file...")
        
        local content = table.concat(xmlParts, "\n")
        xmlParts = nil -- Free memory
        collectgarbage("collect")
        
        -- Change extension to .rbxlx for XML format
        local xmlFileName = fileName:gsub("%.rbxl$", ".rbxlx")
        local ok, err = BaoSaveInstance.Utils:WriteFile(xmlFileName, content)
        
        content = nil
        collectgarbage("collect")
        
        if ok then
            BaoSaveInstance.State:UpdateProgress(1, 1, "Hoàn tất! File: " .. xmlFileName)
            BaoSaveInstance.State.OutputFile = xmlFileName
            BaoSaveInstance.Logger:Success("File written: " .. xmlFileName)
            BaoSaveInstance.Logger:Info("Serialized instances: " .. BaoSaveInstance.Performance:GetCounter("SerializedInstances"))
            return true
        else
            BaoSaveInstance.Logger:Error("Failed to write file: " .. tostring(err))
            return false
        end
    end,
    
    Cleanup = function()
        collectgarbage("collect")
    end,
})

-- === API 5: Emergency Clone (Last Resort) ===
BaoSaveInstance.API:Register({
    Name = "Emergency Clone",
    Priority = 5,
    Description = "Last resort - clones workspace to a model file",
    
    Check = function()
        return ENV.writefile ~= nil
    end,
    
    Execute = function(options)
        BaoSaveInstance.Logger:Warn("Emergency Clone - This is a minimal fallback")
        BaoSaveInstance.State:UpdateProgress(0, 1, "Emergency Clone...")
        
        -- Extremely simplified - just create a basic RBXLX
        local lines = {
            '<?xml version="1.0" encoding="utf-8"?>',
            '<roblox version="4">',
            '<!-- Emergency Clone by BaoSaveInstance -->',
            '<!-- Game: ' .. BaoSaveInstance.Utils:GetGameName() .. ' -->',
        }
        
        local count = 0
        local maxItems = 5000 -- Limit for emergency mode
        
        pcall(function()
            for _, child in ipairs(Workspace:GetDescendants()) do
                if count >= maxItems then break end
                
                pcall(function()
                    if child:IsA("BasePart") then
                        local p = child.Position
                        local s = child.Size
                        table.insert(lines, string.format(
                            '  <Item class="%s"><Properties>' ..
                            '<string name="Name">%s</string>' ..
                            '<Vector3 name="Position"><X>%s</X><Y>%s</Y><Z>%s</Z></Vector3>' ..
                            '<Vector3 name="Size"><X>%s</X><Y>%s</Y><Z>%s</Z></Vector3>' ..
                            '<bool name="Anchored">%s</bool>' ..
                            '</Properties></Item>',
                            child.ClassName, child.Name,
                            p.X, p.Y, p.Z,
                            s.X, s.Y, s.Z,
                            tostring(child.Anchored)
                        ))
                        count = count + 1
                    end
                end)
                
                if count % 100 == 0 then
                    task.wait()
                    BaoSaveInstance.State:UpdateProgress(count / maxItems, 1, "Emergency: " .. count .. " parts")
                end
            end
        end)
        
        table.insert(lines, '</roblox>')
        
        local xmlFileName = options.FileName:gsub("%.rbxl$", ".rbxlx")
        local ok = BaoSaveInstance.Utils:WriteFile(xmlFileName, table.concat(lines, "\n"))
        
        if ok then
            BaoSaveInstance.State:UpdateProgress(1, 1, "Emergency clone: " .. count .. " parts saved")
            BaoSaveInstance.State.OutputFile = xmlFileName
            return true
        end
        
        return false
    end,
})

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 13: CORE ENGINE                                        ║
-- ╚══════════════════════════════════════════════════════════════╝

do
    local Core = BaoSaveInstance.Core
    
    --- Internal: Execute decompile operation
    function Core:_Execute(mode, suffix)
        if BaoSaveInstance.State.IsRunning then
            BaoSaveInstance.Logger:Warn("Operation already running!")
            if BaoSaveInstance.GUI.ShowNotification then
                BaoSaveInstance.GUI.ShowNotification("⚠ Warning", "An operation is already running!", "warning")
            end
            return false
        end
        
        -- Reset state
        BaoSaveInstance.State:Reset()
        BaoSaveInstance.State.IsRunning = true
        BaoSaveInstance.State.CurrentOperation = "Decompile " .. suffix
        BaoSaveInstance.State.StartTime = os.clock()
        
        BaoSaveInstance.Performance:Reset()
        BaoSaveInstance.Performance:StartTimer("TotalOperation")
        BaoSaveInstance.ScriptHandler:ResetStats()
        
        -- Watermark
        print("\n╔══════════════════════════════════════════╗")
        print("║      Decompiled by BaoSaveInstance       ║")
        print("║              v" .. BaoSaveInstance.Version .. " " .. BaoSaveInstance.Build .. "               ║")
        print("╚══════════════════════════════════════════╝\n")
        
        BaoSaveInstance.Logger:Info("═══════════════════════════════════════")
        BaoSaveInstance.Logger:Info("Starting: Decompile " .. suffix)
        BaoSaveInstance.Logger:Info("Game: " .. BaoSaveInstance.Utils:GetGameName())
        BaoSaveInstance.Logger:Info("PlaceId: " .. tostring(game.PlaceId))
        BaoSaveInstance.Logger:Info("Executor: " .. ENV.ExecutorName)
        BaoSaveInstance.Logger:Info("Mode: " .. mode)
        BaoSaveInstance.Logger:Info("Memory: " .. BaoSaveInstance.Performance:GetMemoryMB() .. " MB")
        BaoSaveInstance.Logger:Info("═══════════════════════════════════════")
        
        -- Update GUI
        if BaoSaveInstance.GUI.UpdateStatus then
            BaoSaveInstance.GUI.UpdateStatus("Đang decompile " .. suffix .. "...")
        end
        if BaoSaveInstance.GUI.SetButtonsEnabled then
            BaoSaveInstance.GUI.SetButtonsEnabled(false)
        end
        
        -- Pre-scan game
        BaoSaveInstance.State:UpdateProgress(0, 1, "Scanning game...")
        local scanResults = BaoSaveInstance.Scanner:ScanGame()
        BaoSaveInstance.Logger:Info("Scan results:\n" .. BaoSaveInstance.Scanner:GetSummary())
        
        -- Generate filename
        local fileName = BaoSaveInstance.Utils:GetExportFileName(suffix ~= "Full Game" and suffix or nil)
        BaoSaveInstance.State.OutputFile = fileName
        
        -- Check file exists
        if BaoSaveInstance.Utils:FileExists(fileName) then
            if BaoSaveInstance.Config.OverwriteExisting then
                BaoSaveInstance.Logger:Warn("File exists, will overwrite: " .. fileName)
            end
        end
        
        -- Execute API with fallback
        local options = {
            FileName = fileName,
            Mode = mode,
            ScanResults = scanResults,
        }
        
        local success, message = BaoSaveInstance.API:ExecuteWithFallback(options)
        
        -- Results
        local totalTime = BaoSaveInstance.Performance:StopTimer("TotalOperation")
        
        BaoSaveInstance.Logger:Info("═══════════════════════════════════════")
        if success then
            BaoSaveInstance.Logger:Success("Operation completed successfully!")
            BaoSaveInstance.Logger:Info("File: " .. (BaoSaveInstance.State.OutputFile or fileName))
            BaoSaveInstance.Logger:Info("Time: " .. BaoSaveInstance.Utils:FormatTime(totalTime))
            BaoSaveInstance.Logger:Info("Memory Peak: " .. BaoSaveInstance.Performance:GetMemoryMB() .. " MB")
            BaoSaveInstance.Logger:Info("Errors: " .. BaoSaveInstance.State.Errors)
            BaoSaveInstance.Logger:Info("Warnings: " .. BaoSaveInstance.State.Warnings)
            BaoSaveInstance.Logger:Info("Skipped: " .. BaoSaveInstance.State.SkippedItems)
            
            if BaoSaveInstance.Config.DecompileScripts then
                BaoSaveInstance.Logger:Info(string.format(
                    "Scripts: %d decompiled, %d failed, %d cached",
                    BaoSaveInstance.ScriptHandler.Stats.Decompiled,
                    BaoSaveInstance.ScriptHandler.Stats.Failed,
                    BaoSaveInstance.ScriptHandler.Stats.Cached
                ))
            end
            
            if BaoSaveInstance.GUI.UpdateStatus then
                BaoSaveInstance.GUI.UpdateStatus("✅ Hoàn tất! " .. BaoSaveInstance.Utils:FormatTime(totalTime))
            end
            if BaoSaveInstance.GUI.ShowNotification then
                BaoSaveInstance.GUI.ShowNotification(
                    "✅ Decompile Thành Công!",
                    string.format(
                        "File: %s\nThời gian: %s\nAPI: %s",
                        BaoSaveInstance.State.OutputFile or fileName,
                        BaoSaveInstance.Utils:FormatTime(totalTime),
                        BaoSaveInstance.API.CurrentName
                    ),
                    "success"
                )
            end
        else
            BaoSaveInstance.Logger:Error("Operation failed!")
            BaoSaveInstance.Logger:Error("Reason: " .. tostring(message))
            
            if BaoSaveInstance.GUI.UpdateStatus then
                BaoSaveInstance.GUI.UpdateStatus("❌ Thất bại!")
            end
            if BaoSaveInstance.GUI.ShowNotification then
                BaoSaveInstance.GUI.ShowNotification(
                    "❌ Decompile Thất Bại!",
                    BaoSaveInstance.Utils:Truncate(tostring(message), 200),
                    "error"
                )
            end
        end
        BaoSaveInstance.Logger:Info("═══════════════════════════════════════")
        
        -- Cleanup
        BaoSaveInstance.ScriptHandler:ClearCache()
        collectgarbage("collect")
        
        BaoSaveInstance.State.IsRunning = false
        if BaoSaveInstance.GUI.SetButtonsEnabled then
            BaoSaveInstance.GUI.SetButtonsEnabled(true)
        end
        
        return success
    end
    
    --- Public: Decompile Full Game
    function Core:DecompileFullGame()
        return self:_Execute("full", "Full Game")
    end
    
    --- Public: Decompile Full Model
    function Core:DecompileFullModel()
        return self:_Execute("model", "Model")
    end
    
    --- Public: Decompile Terrain
    function Core:DecompileTerrain()
        return self:_Execute("terrain", "Terrain")
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 14: GUI MODULE - ULTIMATE DARK UI                      ║
-- ╚══════════════════════════════════════════════════════════════╝

do
    local GUI = BaoSaveInstance.GUI
    GUI.Elements = {}
    
    function GUI:Create()
        local T = BaoSaveInstance.Config:GetTheme()
        
        -- Cleanup old GUI
        pcall(function()
            if CoreGui:FindFirstChild("BaoSaveInstanceGUI") then
                CoreGui.BaoSaveInstanceGUI:Destroy()
            end
        end)
        pcall(function()
            if ENV.gethui and ENV.gethui():FindFirstChild("BaoSaveInstanceGUI") then
                ENV.gethui().BaoSaveInstanceGUI:Destroy()
            end
        end)
        
        -- ═══ ScreenGui ═══
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "BaoSaveInstanceGUI"
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.ResetOnSpawn = false
        ScreenGui.DisplayOrder = 9999
        
        local guiParent
        pcall(function()
            if ENV.protect_gui then
                ENV.protect_gui(ScreenGui)
                ScreenGui.Parent = CoreGui
                guiParent = true
            end
        end)
        if not guiParent then
            pcall(function()
                if ENV.gethui then
                    ScreenGui.Parent = ENV.gethui()
                    guiParent = true
                end
            end)
        end
        if not guiParent then
            pcall(function()
                ScreenGui.Parent = CoreGui
                guiParent = true
            end)
        end
        if not guiParent then
            pcall(function()
                ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            end)
        end
        
        self.ScreenGui = ScreenGui
        
        -- ═══ Helper Functions ═══
        local function Create(className, properties)
            local inst = Instance.new(className)
            for k, v in pairs(properties) do
                if k ~= "Parent" then
                    pcall(function() inst[k] = v end)
                end
            end
            if properties.Parent then
                inst.Parent = properties.Parent
            end
            return inst
        end
        
        local function AddCorner(parent, radius)
            return Create("UICorner", {
                CornerRadius = UDim.new(0, radius or 8),
                Parent = parent,
            })
        end
        
        local function AddStroke(parent, color, thickness, transparency)
            return Create("UIStroke", {
                Color = color or T.Border,
                Thickness = thickness or 1,
                Transparency = transparency or 0,
                Parent = parent,
            })
        end
        
        local function AddPadding(parent, top, right, bottom, left)
            return Create("UIPadding", {
                PaddingTop = UDim.new(0, top or 0),
                PaddingRight = UDim.new(0, right or 0),
                PaddingBottom = UDim.new(0, bottom or 0),
                PaddingLeft = UDim.new(0, left or 0),
                Parent = parent,
            })
        end
        
        local function Tween(obj, time, props, style, direction)
            local ti = TweenInfo.new(
                time or 0.25,
                style or Enum.EasingStyle.Quart,
                direction or Enum.EasingDirection.Out
            )
            return TweenService:Create(obj, ti, props)
        end
        
        local function HoverEffect(btn, normalColor, hoverColor, clickColor)
            btn.MouseEnter:Connect(function()
                Tween(btn, 0.15, {BackgroundColor3 = hoverColor}):Play()
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, 0.15, {BackgroundColor3 = normalColor}):Play()
            end)
            if clickColor then
                btn.MouseButton1Down:Connect(function()
                    Tween(btn, 0.05, {BackgroundColor3 = clickColor}):Play()
                end)
                btn.MouseButton1Up:Connect(function()
                    Tween(btn, 0.1, {BackgroundColor3 = hoverColor}):Play()
                end)
            end
        end
        
        -- ═══ Main Frame ═══
        local MainFrame = Create("Frame", {
            Name = "MainFrame",
            Size = UDim2.new(0, 520, 0, 680),
            Position = UDim2.new(0.5, -260, 0.5, -340),
            BackgroundColor3 = T.Primary,
            BorderSizePixel = 0,
            Active = true,
            ClipsDescendants = true,
            Parent = ScreenGui,
        })
        AddCorner(MainFrame, 14)
        AddStroke(MainFrame, T.Border, 1.5, 0.3)
        self.Elements.MainFrame = MainFrame
        
        -- ═══ Title Bar ═══
        local TitleBar = Create("Frame", {
            Name = "TitleBar",
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundColor3 = T.Secondary,
            BorderSizePixel = 0,
            Parent = MainFrame,
        })
        -- Only round top corners
        AddCorner(TitleBar, 14)
        Create("Frame", {
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 1, -14),
            BackgroundColor3 = T.Secondary,
            BorderSizePixel = 0,
            Parent = TitleBar,
        })
        
        -- Gradient line under title
        local TitleLine = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = T.Accent,
            BorderSizePixel = 0,
            Parent = TitleBar,
        })
        Create("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, T.Accent),
                ColorSequenceKeypoint.new(0.5, T.AccentGlow),
                ColorSequenceKeypoint.new(1, T.Accent),
            },
            Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0.5),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(1, 0.5),
            },
            Parent = TitleLine,
        })
        
        -- Logo
        local Logo = Create("TextLabel", {
            Size = UDim2.new(0, 38, 0, 38),
            Position = UDim2.new(0, 10, 0.5, -19),
            BackgroundColor3 = T.Accent,
            Text = "B",
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBlack,
            TextSize = 20,
            Parent = TitleBar,
        })
        AddCorner(Logo, 10)
        
        -- Animated glow on logo
        task.spawn(function()
            while Logo and Logo.Parent do
                Tween(Logo, 1.5, {BackgroundColor3 = T.AccentGlow}):Play()
                task.wait(1.5)
                Tween(Logo, 1.5, {BackgroundColor3 = T.Accent}):Play()
                task.wait(1.5)
            end
        end)
        
        -- Title
        Create("TextLabel", {
            Size = UDim2.new(0, 300, 0, 22),
            Position = UDim2.new(0, 58, 0, 7),
            BackgroundTransparency = 1,
            Text = "BaoSaveInstance",
            TextColor3 = T.Text,
            Font = Enum.Font.GothamBlack,
            TextSize = 17,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TitleBar,
        })
        
        -- Subtitle
        Create("TextLabel", {
            Size = UDim2.new(0, 300, 0, 16),
            Position = UDim2.new(0, 58, 0, 30),
            BackgroundTransparency = 1,
            Text = "v" .. BaoSaveInstance.Version .. " " .. BaoSaveInstance.Build .. " | " .. ENV.ExecutorName,
            TextColor3 = T.TextDim,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TitleBar,
        })
        
        -- Window Controls
        local function CreateWindowBtn(name, text, color, hoverColor, posX)
            local btn = Create("TextButton", {
                Name = name,
                Size = UDim2.new(0, 28, 0, 28),
                Position = UDim2.new(1, posX, 0.5, -14),
                BackgroundColor3 = color,
                Text = text,
                TextColor3 = Color3.new(1, 1, 1),
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Parent = TitleBar,
            })
            AddCorner(btn, 6)
            HoverEffect(btn, color, hoverColor, color)
            return btn
        end
        
        local MinBtn = CreateWindowBtn("Min", "—", T.Yellow, Color3.fromRGB(255, 220, 30), -72)
        local MaxBtn = CreateWindowBtn("Max", "□", T.Green, T.GreenDark, -40)
        local CloseBtn = CreateWindowBtn("Close", "✕", T.Red, T.RedHover, -8)
        
        -- ═══ Content Area ═══
        local Content = Create("ScrollingFrame", {
            Name = "Content",
            Size = UDim2.new(1, -16, 1, -60),
            Position = UDim2.new(0, 8, 0, 56),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = T.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 760),
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            Parent = MainFrame,
        })
        
        local ContentLayout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = Content,
        })
        
        AddPadding(Content, 4, 4, 4, 4)
        
        -- ═══ Section: Game Info ═══
        local function CreateSection(name, layoutOrder)
            local section = Create("Frame", {
                Name = name,
                Size = UDim2.new(1, 0, 0, 0), -- Auto-size
                BackgroundColor3 = T.Secondary,
                BorderSizePixel = 0,
                LayoutOrder = layoutOrder,
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = Content,
            })
            AddCorner(section, 10)
            AddStroke(section, T.Border, 1, 0.5)
            AddPadding(section, 10, 12, 10, 12)
            return section
        end
        
        -- Game Info Section
        local GameInfoSection = CreateSection("GameInfo", 1)
        
        local GameInfoLayout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4),
            Parent = GameInfoSection,
        })
        
        local GameNameLabel = Create("TextLabel", {
            Name = "GameName",
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = "🎮 " .. BaoSaveInstance.Utils:GetGameName(),
            TextColor3 = T.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = 1,
            Parent = GameInfoSection,
        })
        
        local GameDetailsLabel = Create("TextLabel", {
            Name = "GameDetails",
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = string.format(
                "ID: %s | Objects: %s | Memory: %s MB",
                tostring(game.PlaceId),
                tostring(BaoSaveInstance.Utils:CountDescendants(Workspace)),
                tostring(BaoSaveInstance.Performance:GetMemoryMB())
            ),
            TextColor3 = T.TextDim,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            Parent = GameInfoSection,
        })
        
        -- ═══ Section: Action Buttons ═══
        local ButtonSection = CreateSection("Buttons", 2)
        
        local BtnLayout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            Parent = ButtonSection,
        })
        
        local function CreateActionButton(name, text, icon, color, hoverColor, layoutOrder, parent)
            local btn = Create("TextButton", {
                Name = name,
                Size = UDim2.new(1, 0, 0, 44),
                BackgroundColor3 = color,
                Text = "",
                BorderSizePixel = 0,
                AutoButtonColor = false,
                LayoutOrder = layoutOrder,
                Parent = parent,
            })
            AddCorner(btn, 8)
            HoverEffect(btn, color, hoverColor, Color3.new(
                math.max(0, color.R - 0.05),
                math.max(0, color.G - 0.05),
                math.max(0, color.B - 0.05)
            ))
            
            Create("TextLabel", {
                Size = UDim2.new(0, 28, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text = icon,
                TextColor3 = Color3.new(1, 1, 1),
                Font = Enum.Font.Gotham,
                TextSize = 18,
                Parent = btn,
            })
            
            local btnText = Create("TextLabel", {
                Name = "Label",
                Size = UDim2.new(1, -55, 1, 0),
                Position = UDim2.new(0, 48, 0, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Color3.new(1, 1, 1),
                Font = Enum.Font.GothamSemibold,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = btn,
            })
            
            -- Arrow indicator
            Create("TextLabel", {
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -28, 0, 0),
                BackgroundTransparency = 1,
                Text = "→",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextTransparency = 0.5,
                Font = Enum.Font.GothamBold,
                TextSize = 16,
                Parent = btn,
            })
            
            return btn
        end
        
        local FullGameBtn = CreateActionButton(
            "FullGame", "Decompile Full Game", "🌐",
            T.Accent, T.AccentHover, 1, ButtonSection
        )
        
        local FullModelBtn = CreateActionButton(
            "FullModel", "Decompile Full Model", "🏗",
            Color3.fromRGB(90, 60, 200), Color3.fromRGB(110, 80, 220), 2, ButtonSection
        )
        
        local TerrainBtn = CreateActionButton(
            "Terrain", "Decompile Terrain", "🏔",
            Color3.fromRGB(0, 150, 80), Color3.fromRGB(0, 180, 100), 3, ButtonSection
        )
        
        local ScanBtn = CreateActionButton(
            "Scan", "Scan Game Analysis", "🔍",
            Color3.fromRGB(200, 120, 0), Color3.fromRGB(220, 140, 20), 4, ButtonSection
        )
        
        -- ═══ Section: Progress ═══
        local ProgressSection = CreateSection("Progress", 3)
        
        local ProgLayout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            Parent = ProgressSection,
        })
        
        -- Progress header row
        local ProgHeader = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Parent = ProgressSection,
        })
        
        local ProgTitleLabel = Create("TextLabel", {
            Size = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "📊 Progress",
            TextColor3 = T.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = ProgHeader,
        })
        
        local ProgPercentLabel = Create("TextLabel", {
            Name = "Percent",
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "0%",
            TextColor3 = T.Accent,
            Font = Enum.Font.GothamBlack,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = ProgHeader,
        })
        self.Elements.ProgressPercent = ProgPercentLabel
        
        -- Progress Bar
        local ProgBarBg = Create("Frame", {
            Name = "ProgressBarBg",
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundColor3 = T.ProgressBg,
            BorderSizePixel = 0,
            LayoutOrder = 2,
            Parent = ProgressSection,
        })
        AddCorner(ProgBarBg, 8)
        
        local ProgBarFill = Create("Frame", {
            Name = "Fill",
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = T.ProgressFill,
            BorderSizePixel = 0,
            Parent = ProgBarBg,
        })
        AddCorner(ProgBarFill, 8)
        self.Elements.ProgressFill = ProgBarFill
        
        -- Shimmer effect on progress bar
        local ProgShimmer = Create("Frame", {
            Size = UDim2.new(0, 60, 1, 0),
            Position = UDim2.new(-0.2, 0, 0, 0),
            BackgroundTransparency = 0.7,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Parent = ProgBarFill,
        })
        AddCorner(ProgShimmer, 8)
        Create("UIGradient", {
            Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.3, 0.7),
                NumberSequenceKeypoint.new(0.7, 0.7),
                NumberSequenceKeypoint.new(1, 1),
            },
            Parent = ProgShimmer,
        })
        
        -- Animate shimmer
        task.spawn(function()
            while ProgShimmer and ProgShimmer.Parent do
                ProgShimmer.Position = UDim2.new(-0.3, 0, 0, 0)
                Tween(ProgShimmer, 1.5, {Position = UDim2.new(1.3, 0, 0, 0)}, Enum.EasingStyle.Linear):Play()
                task.wait(2)
            end
        end)
        
        -- Status row
        local StatusRow = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            LayoutOrder = 3,
            Parent = ProgressSection,
        })
        
        local StatusLabel = Create("TextLabel", {
            Name = "Status",
            Size = UDim2.new(0.65, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "Sẵn sàng",
            TextColor3 = T.TextSecondary,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = StatusRow,
        })
        self.Elements.StatusLabel = StatusLabel
        
        local ETALabel = Create("TextLabel", {
            Name = "ETA",
            Size = UDim2.new(0.35, 0, 1, 0),
            Position = UDim2.new(0.65, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = T.TextDim,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = StatusRow,
        })
        self.Elements.ETALabel = ETALabel
        
        -- ═══ Section: API & Stats ═══
        local StatsSection = CreateSection("Stats", 4)
        
        local StatsLayout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4),
            Parent = StatsSection,
        })
        
        local function CreateStatRow(label, value, layoutOrder)
            local row = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                LayoutOrder = layoutOrder,
                Parent = StatsSection,
            })
            Create("TextLabel", {
                Size = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = T.TextDim,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            local valueLabel = Create("TextLabel", {
                Name = "Value",
                Size = UDim2.new(0.5, 0, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = value,
                TextColor3 = T.Text,
                Font = Enum.Font.GothamSemibold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = row,
            })
            return valueLabel
        end
        
        local APIValueLabel = CreateStatRow("🔌 API Status", "Ready", 1)
        local SpeedValueLabel = CreateStatRow("⚡ Speed", "—", 2)
        local MemoryValueLabel = CreateStatRow("💾 Memory", BaoSaveInstance.Performance:GetMemoryMB() .. " MB", 3)
        local ErrorsValueLabel = CreateStatRow("❌ Errors", "0", 4)
        
        self.Elements.APIStatus = APIValueLabel
        self.Elements.SpeedLabel = SpeedValueLabel
        self.Elements.MemoryLabel = MemoryValueLabel
        self.Elements.ErrorsLabel = ErrorsValueLabel
        
        -- ═══ Section: Settings ═══
        local SettingsSection = CreateSection("Settings", 5)
        SettingsSection.Visible = false
        SettingsSection.ClipsDescendants = true
        
        local SettingsLayout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            Parent = SettingsSection,
        })
        
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            Text = "⚙ Settings",
            TextColor3 = T.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0,
            Parent = SettingsSection,
        })
        
        local function CreateToggle(name, text, configKey, layoutOrder)
            local toggleRow = Create("Frame", {
                Name = name,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                LayoutOrder = layoutOrder,
                Parent = SettingsSection,
            })
            
            Create("TextLabel", {
                Size = UDim2.new(1, -55, 1, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = T.TextSecondary,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = toggleRow,
            })
            
            local state = BaoSaveInstance.Config[configKey]
            
            local toggleBg = Create("TextButton", {
                Size = UDim2.new(0, 44, 0, 22),
                Position = UDim2.new(1, -44, 0.5, -11),
                BackgroundColor3 = state and T.Accent or Color3.fromRGB(55, 55, 70),
                Text = "",
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Parent = toggleRow,
            })
            AddCorner(toggleBg, 11)
            
            local knob = Create("Frame", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Parent = toggleBg,
            })
            AddCorner(knob, 9)
            
            toggleBg.MouseButton1Click:Connect(function()
                state = not state
                BaoSaveInstance.Config[configKey] = state
                
                Tween(knob, 0.2, {
                    Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
                }):Play()
                Tween(toggleBg, 0.2, {
                    BackgroundColor3 = state and T.Accent or Color3.fromRGB(55, 55, 70)
                }):Play()
                
                BaoSaveInstance.Logger:Info(configKey .. " = " .. tostring(state))
            end)
        end
        
        CreateToggle("AntiLag", "Anti Lag Mode", "AntiLagMode", 1)
        CreateToggle("AutoAPI", "Auto API Switch", "AutoAPISwitch", 2)
        CreateToggle("ServerStorage", "Include ServerStorage", "IncludeServerStorage", 3)
        CreateToggle("IncLighting", "Include Lighting", "IncludeLighting", 4)
        CreateToggle("IncTerrain", "Include Terrain", "IncludeTerrain", 5)
        CreateToggle("DecompScripts", "Decompile Scripts", "DecompileScripts", 6)
        CreateToggle("NilInstances", "Include Nil Instances", "IncludeNilInstances", 7)
        CreateToggle("HiddenProps", "Save Hidden Properties", "SaveHiddenProperties", 8)
        CreateToggle("StealthMode", "Stealth Mode", "StealthMode", 9)
        
        -- Theme selector
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = "🎨 Theme",
            TextColor3 = T.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 10,
            Parent = SettingsSection,
        })
        
        local ThemeRow = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            LayoutOrder = 11,
            Parent = SettingsSection,
        })
        
        local themeNames = {"Blue", "Red", "Purple", "Green"}
        local themeColors = {
            Color3.fromRGB(0, 122, 255),
            Color3.fromRGB(220, 40, 60),
            Color3.fromRGB(130, 50, 220),
            Color3.fromRGB(0, 180, 90),
        }
        
        for i, themeName in ipairs(themeNames) do
            local themeBtn = Create("TextButton", {
                Size = UDim2.new(0, 50, 0, 28),
                Position = UDim2.new(0, (i - 1) * 58, 0, 0),
                BackgroundColor3 = themeColors[i],
                Text = themeName,
                TextColor3 = Color3.new(1, 1, 1),
                Font = Enum.Font.GothamSemibold,
                TextSize = 10,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Parent = ThemeRow,
            })
            AddCorner(themeBtn, 6)
            
            themeBtn.MouseButton1Click:Connect(function()
                BaoSaveInstance.Config.Theme = themeName
                BaoSaveInstance.Logger:Info("Theme changed to " .. themeName .. " (restart GUI to apply)")
                if BaoSaveInstance.GUI.ShowNotification then
                    BaoSaveInstance.GUI.ShowNotification(
                        "🎨 Theme Changed",
                        "Theme set to " .. themeName .. ". Restart script to apply.",
                        "info"
                    )
                end
            end)
        end
        
        -- Settings toggle button
        local SettingsBtn = CreateActionButton(
            "SettingsToggle", "Settings", "⚙",
            T.Tertiary, Color3.fromRGB(
                math.min(255, T.Tertiary.R * 255 + 15),
                math.min(255, T.Tertiary.G * 255 + 15),
                math.min(255, T.Tertiary.B * 255 + 15)
            ),
            5, ButtonSection
        )
        
        -- ═══ Section: Log Console ═══
        local LogSection = CreateSection("Log", 6)
        LogSection.Visible = false
        
        local LogLayout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4),
            Parent = LogSection,
        })
        
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = "📋 Console Log",
            TextColor3 = T.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0,
            Parent = LogSection,
        })
        
        local LogScroll = Create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 0, 150),
            BackgroundColor3 = T.Primary,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = T.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            Parent = LogSection,
        })
        AddCorner(LogScroll, 6)
        
        local LogTextLayout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 1),
            Parent = LogScroll,
        })
        AddPadding(LogScroll, 4, 6, 4, 6)
        
        self.Elements.LogScroll = LogScroll
        
        local logBtn = CreateActionButton(
            "LogToggle", "Console Log", "📋",
            T.Tertiary, Color3.fromRGB(
                math.min(255, T.Tertiary.R * 255 + 15),
                math.min(255, T.Tertiary.G * 255 + 15),
                math.min(255, T.Tertiary.B * 255 + 15)
            ),
            6, ButtonSection
        )
        
        -- ═══ Notification System ═══
        local NotifContainer = Create("Frame", {
            Name = "Notifications",
            Size = UDim2.new(1, -16, 0, 80),
            Position = UDim2.new(0, 8, 1, 10),
            BackgroundColor3 = T.Secondary,
            BorderSizePixel = 0,
            Visible = false,
            ClipsDescendants = true,
            Parent = MainFrame,
        })
        AddCorner(NotifContainer, 10)
        AddStroke(NotifContainer, T.Border, 1, 0.5)
        
        local NotifAccent = Create("Frame", {
            Size = UDim2.new(0, 4, 1, -8),
            Position = UDim2.new(0, 4, 0, 4),
            BackgroundColor3 = T.Accent,
            BorderSizePixel = 0,
            Parent = NotifContainer,
        })
        AddCorner(NotifAccent, 2)
        
        local NotifTitle = Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -24, 0, 22),
            Position = UDim2.new(0, 16, 0, 10),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = T.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = NotifContainer,
        })
        
        local NotifMsg = Create("TextLabel", {
            Name = "Message",
            Size = UDim2.new(1, -24, 0, 40),
            Position = UDim2.new(0, 16, 0, 32),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = T.TextSecondary,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = NotifContainer,
        })
        
        -- ═══ GUI CALLBACK FUNCTIONS ═══
        
        BaoSaveInstance.GUI.UpdateProgress = function(progress, status, eta, speed)
            pcall(function()
                progress = math.clamp(progress or 0, 0, 1)
                local percent = math.floor(progress * 100)
                
                Tween(ProgBarFill, 0.3, {
                    Size = UDim2.new(progress, 0, 1, 0)
                }):Play()
                
                ProgPercentLabel.Text = percent .. "%"
                
                if progress >= 1 then
                    ProgBarFill.BackgroundColor3 = T.Green
                    ProgPercentLabel.TextColor3 = T.Green
                elseif progress > 0 then
                    ProgBarFill.BackgroundColor3 = T.ProgressFill
                    ProgPercentLabel.TextColor3 = T.Accent
                end
                
                if status then StatusLabel.Text = status end
                if eta then ETALabel.Text = "ETA: " .. eta end
                if speed then SpeedValueLabel.Text = speed .. " obj/s" end
            end)
        end
        
        BaoSaveInstance.GUI.UpdateStatus = function(text)
            pcall(function()
                StatusLabel.Text = text or ""
            end)
        end
        
        BaoSaveInstance.GUI.UpdateAPIStatus = function(name, status)
            pcall(function()
                APIValueLabel.Text = name or "None"
                if status == "running" then
                    APIValueLabel.TextColor3 = T.Yellow
                elseif status == "success" then
                    APIValueLabel.TextColor3 = T.Green
                elseif status == "failed" then
                    APIValueLabel.TextColor3 = T.Red
                else
                    APIValueLabel.TextColor3 = T.Text
                end
            end)
        end
        
        BaoSaveInstance.GUI.SetButtonsEnabled = function(enabled)
            pcall(function()
                for _, btnName in ipairs({"FullGame", "FullModel", "Terrain", "Scan"}) do
                    local btn = ButtonSection:FindFirstChild(btnName)
                    if btn then
                        btn.Active = enabled
                        local label = btn:FindFirstChild("Label")
                        if label then
                            label.TextTransparency = enabled and 0 or 0.4
                        end
                    end
                end
            end)
        end
        
        BaoSaveInstance.GUI.ShowNotification = function(title, message, notifType)
            pcall(function()
                NotifTitle.Text = title or ""
                NotifMsg.Text = message or ""
                
                local accentColor = T.Accent
                if notifType == "success" then accentColor = T.Green
                elseif notifType == "error" then accentColor = T.Red
                elseif notifType == "warning" then accentColor = T.Yellow
                end
                NotifAccent.BackgroundColor3 = accentColor
                
                NotifContainer.Visible = true
                NotifContainer.Position = UDim2.new(0, 8, 1, 10)
                
                Tween(NotifContainer, 0.4, {
                    Position = UDim2.new(0, 8, 1, -90)
                }):Play()
                
                task.delay(6, function()
                    pcall(function()
                        Tween(NotifContainer, 0.3, {
                            Position = UDim2.new(0, 8, 1, 10)
                        }):Play()
                        task.delay(0.35, function()
                            pcall(function() NotifContainer.Visible = false end)
                        end)
                    end)
                end)
            end)
        end
        
        BaoSaveInstance.GUI.ResetProgress = function()
            pcall(function()
                Tween(ProgBarFill, 0.3, {Size = UDim2.new(0, 0, 1, 0)}):Play()
                ProgPercentLabel.Text = "0%"
                ProgPercentLabel.TextColor3 = T.Accent
                ProgBarFill.BackgroundColor3 = T.ProgressFill
                StatusLabel.Text = "Sẵn sàng"
                ETALabel.Text = ""
                APIValueLabel.Text = "Ready"
                APIValueLabel.TextColor3 = T.Green
                SpeedValueLabel.Text = "—"
                ErrorsValueLabel.Text = "0"
            end)
        end
        
        local function AddLogEntry(entry)
            pcall(function()
                local colors = {
                    DEBUG = T.TextDim,
                    INFO = T.TextSecondary,
                    WARN = T.Yellow,
                    ERROR = T.Red,
                    SUCCESS = T.Green,
                    CRITICAL = T.Red,
                    PERF = T.Purple,
                }
                
                local logLine = Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 14),
                    BackgroundTransparency = 1,
                    Text = string.format("[%s] %s", entry.Level, entry.Message),
                    TextColor3 = colors[entry.Level] or T.TextDim,
                    Font = Enum.Font.Code,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = LogScroll,
                })
                
                -- Auto-scroll to bottom
                LogScroll.CanvasPosition = Vector2.new(0, LogScroll.AbsoluteCanvasSize.Y)
                
                -- Limit log entries in GUI
                local children = LogScroll:GetChildren()
                local textChildren = 0
                for _, c in ipairs(children) do
                    if c:IsA("TextLabel") then textChildren = textChildren + 1 end
                end
                if textChildren > 100 then
                    for _, c in ipairs(children) do
                        if c:IsA("TextLabel") then
                            c:Destroy()
                            break
                        end
                    end
                end
            end)
        end
        
        -- Connect logger to GUI
        BaoSaveInstance.Logger:OnLog(AddLogEntry)
        
        -- ═══ DRAGGING ═══
        local dragging, dragInput, dragStart, startPos
        
        TitleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or
               input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        TitleBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or
               input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        -- ═══ BUTTON EVENTS ═══
        
        FullGameBtn.MouseButton1Click:Connect(function()
            if BaoSaveInstance.State.IsRunning then
                BaoSaveInstance.GUI.ShowNotification("⚠ Đang chạy", "Vui lòng đợi...", "warning")
                return
            end
            BaoSaveInstance.GUI.ResetProgress()
            task.spawn(function()
                BaoSaveInstance.Core:DecompileFullGame()
            end)
        end)
        
        FullModelBtn.MouseButton1Click:Connect(function()
            if BaoSaveInstance.State.IsRunning then
                BaoSaveInstance.GUI.ShowNotification("⚠ Đang chạy", "Vui lòng đợi...", "warning")
                return
            end
            BaoSaveInstance.GUI.ResetProgress()
            task.spawn(function()
                BaoSaveInstance.Core:DecompileFullModel()
            end)
        end)
        
        TerrainBtn.MouseButton1Click:Connect(function()
            if BaoSaveInstance.State.IsRunning then
                BaoSaveInstance.GUI.ShowNotification("⚠ Đang chạy", "Vui lòng đợi...", "warning")
                return
            end
            BaoSaveInstance.GUI.ResetProgress()
            task.spawn(function()
                BaoSaveInstance.Core:DecompileTerrain()
            end)
        end)
        
        ScanBtn.MouseButton1Click:Connect(function()
            if BaoSaveInstance.State.IsRunning then return end
            
            task.spawn(function()
                BaoSaveInstance.GUI.UpdateStatus("Scanning game...")
                local results = BaoSaveInstance.Scanner:ScanGame()
                local summary = BaoSaveInstance.Scanner:GetSummary()
                BaoSaveInstance.GUI.ShowNotification(
                    "🔍 Scan Complete",
                    summary,
                    "info"
                )
                BaoSaveInstance.GUI.UpdateStatus("Scan complete")
            end)
        end)
        
        -- Settings toggle
        local settingsVisible = false
        SettingsBtn.MouseButton1Click:Connect(function()
            settingsVisible = not settingsVisible
            SettingsSection.Visible = settingsVisible
            
            -- Update canvas size
            task.wait(0.05)
            pcall(function()
                Content.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
            end)
        end)
        
        -- Log toggle
        local logVisible = false
        logBtn.MouseButton1Click:Connect(function()
            logVisible = not logVisible
            LogSection.Visible = logVisible
            
            task.wait(0.05)
            pcall(function()
                Content.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
            end)
        end)
        
        -- Minimize
        local minimized = false
        MinBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            if minimized then
                Tween(MainFrame, 0.3, {Size = UDim2.new(0, 520, 0, 52)}):Play()
                Content.Visible = false
                MinBtn.Text = "+"
            else
                Content.Visible = true
                Tween(MainFrame, 0.3, {Size = UDim2.new(0, 520, 0, 680)}):Play()
                MinBtn.Text = "—"
            end
        end)
        
        -- Maximize
        local maximized = false
        MaxBtn.MouseButton1Click:Connect(function()
            maximized = not maximized
            if maximized then
                Tween(MainFrame, 0.3, {
                    Size = UDim2.new(0, 700, 0, 900),
                    Position = UDim2.new(0.5, -350, 0.5, -450),
                }):Play()
            else
                Tween(MainFrame, 0.3, {
                    Size = UDim2.new(0, 520, 0, 680),
                    Position = UDim2.new(0.5, -260, 0.5, -340),
                }):Play()
            end
        end)
        
        -- Close
        CloseBtn.MouseButton1Click:Connect(function()
            BaoSaveInstance.State.CancelRequested = true
            
            Tween(MainFrame, 0.3, {
                Size = UDim2.new(0, 520, 0, 0),
                Position = UDim2.new(0.5, -260, 0.5, 0),
                BackgroundTransparency = 1,
            }, Enum.EasingStyle.Quart, Enum.EasingDirection.In):Play()
            
            task.delay(0.35, function()
                pcall(function() ScreenGui:Destroy() end)
            end)
        end)
        
        -- ═══ OPEN ANIMATION ═══
        MainFrame.Size = UDim2.new(0, 520, 0, 0)
        MainFrame.BackgroundTransparency = 1
        
        task.delay(0.05, function()
            Tween(MainFrame, 0.5, {
                Size = UDim2.new(0, 520, 0, 680),
                BackgroundTransparency = 0,
            }):Play()
        end)
        
        -- ═══ MEMORY UPDATER ═══
        task.spawn(function()
            while ScreenGui and ScreenGui.Parent do
                pcall(function()
                    MemoryValueLabel.Text = BaoSaveInstance.Performance:GetMemoryMB() .. " MB"
                    ErrorsValueLabel.Text = tostring(BaoSaveInstance.State.Errors)
                end)
                task.wait(2)
            end
        end)
        
        -- Update canvas size
        task.delay(0.1, function()
            pcall(function()
                Content.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
            end)
        end)
        
        BaoSaveInstance.Logger:Success("GUI created successfully!")
        return ScreenGui
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ PHẦN 15: INITIALIZATION                                     ║
-- ╚══════════════════════════════════════════════════════════════╝

local function Initialize()
    local banner = [[

    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║            BaoSaveInstance v3.0 Ultimate                  ║
    ║         Advanced Game Decompiler & Exporter               ║
    ║                                                           ║
    ║  ┌─────────────────────────────────────────────────┐     ║
    ║  │  🌐 Decompile Full Game (All Services)          │     ║
    ║  │  🏗  Decompile Full Model (Workspace Only)      │     ║
    ║  │  🏔  Decompile Terrain (Terrain Only)           │     ║
    ║  │  🔍 Game Scanner & Analyzer                     │     ║
    ║  └─────────────────────────────────────────────────┘     ║
    ║                                                           ║
    ║  ⚡ 5-Layer API Fallback System                           ║
    ║  🔧 Deep Script Decompilation                             ║
    ║  📊 Real-time Progress with ETA                           ║
    ║  🛡  Anti-Detection Stealth Mode                          ║
    ║  💾 Memory-Optimized Processing                           ║
    ║  🎨 Beautiful Animated Dark UI                            ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
    ]]
    
    print(banner)
    
    BaoSaveInstance.Logger:Info("Initializing BaoSaveInstance v" .. BaoSaveInstance.Version .. " " .. BaoSaveInstance.Build)
    BaoSaveInstance.Logger:Info("Executor: " .. ENV.ExecutorName)
    
    -- Check capabilities
    BaoSaveInstance.Logger:Info("=== Executor Capabilities ===")
    local capNames = {
        "saveinstance", "writefile", "readfile", "isfile", "isfolder", "makefolder",
        "decompile", "getscriptbytecode", "gethiddenproperty", "sethiddenproperty",
        "getnilinstances", "getinstances", "getscripts", "getloadedmodules",
        "request", "setclipboard", "queue_on_teleport",
    }
    for _, name in ipairs(capNames) do
        local available = ENV[name] ~= nil
        if available then
            BaoSaveInstance.Logger:Debug("  ✅ " .. name)
        end
    end
    
    -- Check APIs
    local availableAPIs = BaoSaveInstance.API:GetAvailableAPIs()
    BaoSaveInstance.Logger:Info("=== Available APIs ===")
    for _, apiInfo in ipairs(availableAPIs) do
        BaoSaveInstance.Logger:Info(string.format(
            "  ✅ %s (P:%d) - %s",
            apiInfo.API.Name,
            apiInfo.API.Priority,
            apiInfo.API.Description or ""
        ))
    end
    
    if #availableAPIs == 0 then
        BaoSaveInstance.Logger:Critical("No APIs available! Export may not work.")
    end
    
    -- Apply stealth
    BaoSaveInstance.Stealth:Apply()
    
    -- Create GUI
    BaoSaveInstance.GUI:Create()
    
    -- Done
    BaoSaveInstance.Logger:Success("BaoSaveInstance is ready!")
    BaoSaveInstance.Logger:Info("Game: " .. BaoSaveInstance.Utils:GetGameName())
    BaoSaveInstance.Logger:Info("PlaceId: " .. tostring(game.PlaceId))
    
    print("\n  Decompiled by BaoSaveInstance")
    print("  " .. BaoSaveInstance.Utils:GetGameName())
    print("")
end

-- Run with error protection
local initOk, initErr = pcall(Initialize)
if not initOk then
    warn("[BaoSaveInstance] CRITICAL INIT ERROR: " .. tostring(initErr))
    -- Try minimal GUI
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "BaoSaveInstance_Error"
        sg.Parent = game:GetService("CoreGui")
        
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, 400, 0, 100)
        f.Position = UDim2.new(0.5, -200, 0, 10)
        f.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
        f.Parent = sg
        
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -20, 1, -20)
        t.Position = UDim2.new(0, 10, 0, 10)
        t.BackgroundTransparency = 1
        t.Text = "BaoSaveInstance Error:\n" .. tostring(initErr)
        t.TextColor3 = Color3.new(1, 0.3, 0.3)
        t.Font = Enum.Font.Code
        t.TextSize = 12
        t.TextWrapped = true
        t.Parent = f
        
        task.delay(15, function() sg:Destroy() end)
    end)
end

-- Global access
pcall(function()
    ENV.getgenv().BaoSaveInstance = BaoSaveInstance
end)

--[[
╔══════════════════════════════════════════════════════════════════════╗
║                        HƯỚNG DẪN SỬ DỤNG                           ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  1. Copy toàn bộ script → Paste vào executor → Execute               ║
║  2. GUI hiện ra ở giữa màn hình                                      ║
║  3. Kéo thả bằng Title Bar                                           ║
║                                                                      ║
║  CHỨC NĂNG:                                                          ║
║  ┌──────────────────────────────────────────────────────────┐        ║
║  │ 🌐 Decompile Full Game                                    │        ║
║  │    → Export toàn bộ game (tất cả services)                │        ║
║  │    → Bao gồm: Workspace, Lighting, ReplicatedStorage,    │        ║
║  │       StarterGui, StarterPlayer, Terrain, Scripts...      │        ║
║  │                                                            │        ║
║  │ 🏗  Decompile Full Model                                   │        ║
║  │    → Chỉ export models trong Workspace                    │        ║
║  │    → Không bao gồm Terrain                                │        ║
║  │    → Giữ nguyên hierarchy, scripts, meshes, textures      │        ║
║  │                                                            │        ║
║  │ 🏔  Decompile Terrain                                      │        ║
║  │    → Chỉ export Terrain voxel data                         │        ║
║  │    → Materials, Water, Biomes                              │        ║
║  │                                                            │        ║
║  │ 🔍 Scan Game                                               │        ║
║  │    → Phân tích game trước khi decompile                    │        ║
║  │    → Đếm instances, scripts, assets                        │        ║
║  │    → Ước tính kích thước file                              │        ║
║  └──────────────────────────────────────────────────────────┘        ║
║                                                                      ║
║  SETTINGS:                                                           ║
║  • Anti Lag Mode: Yield thường xuyên để tránh lag                    ║
║  • Auto API Switch: Tự động chuyển API khi fail                      ║
║  • Include ServerStorage: Bao gồm ServerStorage                      ║
║  • Include Lighting: Bao gồm Lighting settings                       ║
║  • Include Terrain: Bao gồm Terrain data                             ║
║  • Decompile Scripts: Decompile tất cả scripts                       ║
║  • Include Nil Instances: Bao gồm nil-parented instances             ║
║  • Save Hidden Properties: Lưu hidden properties                     ║
║  • Stealth Mode: Anti-detection measures                              ║
║  • Theme: Blue, Red, Purple, Green                                    ║
║                                                                      ║
║  API FALLBACK SYSTEM (5 layers):                                     ║
║  1. Unified SaveInstance (executor native)                             ║
║  2. Synapse Native (syn.saveinstance)                                 ║
║  3. Executor Native (fluxus/others)                                   ║
║  4. Deep Clone Engine (custom XML serializer)                         ║
║  5. Emergency Clone (minimal fallback)                                ║
║                                                                      ║
║  OUTPUT:                                                              ║
║  → File .rbxl trong folder workspace của executor                     ║
║  → Tên: <GameName> Decompile By BaoSaveInstance.rbxl                 ║
║                                                                      ║
║  THÊM API MỚI:                                                       ║
║  BaoSaveInstance.API:Register({                                       ║
║      Name = "MyAPI",                                                  ║
║      Priority = 6,                                                    ║
║      Description = "Custom API",                                      ║
║      Check = function() return true end,                              ║
║      Execute = function(opts) return true end,                        ║
║      Cleanup = function() end,                                        ║
║  })                                                                   ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
--]]
