--[[
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                       BaoSaveInstance API Framework v3.0                              ║
║                                   Main Entry Point                                    ║
╠══════════════════════════════════════════════════════════════════════════════════════╣
║  File: Main.lua                                                                      ║
║  Description: Entry point that loads and initializes all API modules                 ║
╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

--// ═══════════════════════════════════════════════════════════════════════════════════
--// MODULE LOADER
--// ═══════════════════════════════════════════════════════════════════════════════════

local BaoAPI = {
    _VERSION = "3.0.0",
    _NAME = "BaoSaveInstance",
    _AUTHOR = "BaoAPI Team",
    _LOADED = false,
}

--// Check if running in exploit environment
local function IsExploitEnvironment()
    return identifyexecutor ~= nil or syn ~= nil or getexecutorname ~= nil
end

if not IsExploitEnvironment() then
    warn("[BaoAPI] Warning: Not running in exploit environment. Some features may not work.")
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// LOAD MODULES
--// ═══════════════════════════════════════════════════════════════════════════════════

-- Module paths (adjust based on how you're loading)
local ModulePaths = {
    Services = "Core/Services",
    Utils = "Core/Utils",
    Config = "Core/Config",
    EventAPI = "API/EventAPI",
    HookAPI = "API/HookAPI",
    FileAPI = "API/FileAPI",
    LoggerAPI = "API/LoggerAPI",
    SerializerAPI = "API/SerializerAPI",
    ScriptAPI = "API/ScriptAPI",
    TerrainAPI = "API/TerrainAPI",
    SaveAPI = "API/SaveAPI",
    PluginManager = "Plugins/PluginManager",
    Interface = "GUI/Interface",
}

--[[
    Option 1: Load from separate files (if using file system)
    Option 2: Load embedded modules (all-in-one)
    
    For simplicity, we'll embed all modules in this Main.lua
]]

--// ═══════════════════════════════════════════════════════════════════════════════════
--// EMBEDDED: SERVICES
--// ═══════════════════════════════════════════════════════════════════════════════════

local Services = {}

Services.Players = game:GetService("Players")
Services.Workspace = game:GetService("Workspace")
Services.Lighting = game:GetService("Lighting")
Services.ReplicatedStorage = game:GetService("ReplicatedStorage")
Services.ReplicatedFirst = game:GetService("ReplicatedFirst")
Services.StarterGui = game:GetService("StarterGui")
Services.StarterPack = game:GetService("StarterPack")
Services.StarterPlayer = game:GetService("StarterPlayer")
Services.SoundService = game:GetService("SoundService")
Services.Chat = game:GetService("Chat")
Services.Teams = game:GetService("Teams")
Services.RunService = game:GetService("RunService")
Services.HttpService = game:GetService("HttpService")
Services.TweenService = game:GetService("TweenService")
Services.UserInputService = game:GetService("UserInputService")
Services.CoreGui = game:GetService("CoreGui")
Services.MaterialService = game:GetService("MaterialService")
Services.CollectionService = game:GetService("CollectionService")
Services.Debris = game:GetService("Debris")

Services.LocalPlayer = Services.Players.LocalPlayer

function Services.Get(name)
    if Services[name] then return Services[name] end
    local success, service = pcall(game.GetService, game, name)
    if success then
        Services[name] = service
        return service
    end
    return nil
end

BaoAPI.Services = Services

--// ═══════════════════════════════════════════════════════════════════════════════════
--// EMBEDDED: UTILS
--// ═══════════════════════════════════════════════════════════════════════════════════

local Utils = {}

function Utils.Try(func, ...)
    local args = {...}
    return pcall(function() return func(unpack(args)) end)
end

function Utils.TryOr(func, default, ...)
    local success, result = Utils.Try(func, ...)
    return success and result or default
end

function Utils.DeepClone(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[Utils.DeepClone(k)] = Utils.DeepClone(v)
    end
    return copy
end

function Utils.Merge(base, override)
    local result = Utils.DeepClone(base or {})
    for k, v in pairs(override or {}) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = Utils.Merge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

function Utils.GenerateID(prefix)
    prefix = prefix or "id"
    return string.format("%s_%s_%s", prefix, os.time(), math.random(10000, 99999))
end

function Utils.GetTimestamp(format)
    return os.date(format or "%Y%m%d_%H%M%S")
end

function Utils.Sanitize(str, maxLen)
    return tostring(str):gsub("[^%w%-_]", "_"):sub(1, maxLen or 50)
end

function Utils.EscapeXML(str)
    if type(str) ~= "string" then str = tostring(str) end
    return str:gsub("[<>&\"']", {["<"]="&lt;",[">"]="&gt;",["&"]="&amp;",['"']="&quot;",["'"]="&apos;"}):gsub("[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "")
end

function Utils.BatchProcess(items, batchSize, processor, onProgress)
    batchSize = batchSize or 100
    local results, total = {}, #items
    for i, item in ipairs(items) do
        local success, result = pcall(processor, item, i)
        if success then table.insert(results, result) end
        if i % batchSize == 0 then
            if onProgress then onProgress(i, total, math.floor(i/total*100)) end
            task.wait()
        end
    end
    return results
end

BaoAPI.Utils = Utils

--// ═══════════════════════════════════════════════════════════════════════════════════
--// EMBEDDED: CONFIG
--// ═══════════════════════════════════════════════════════════════════════════════════

local Config = {}
local DefaultConfig = {
    Save = { Mode = "All", FileName = "", FilePath = "BaoSaveInstance", Binary = true, Timeout = 60 },
    Decompile = { Enabled = true, Timeout = 10, IgnoreErrors = true },
    Instance = { RemovePlayers = true, SaveTerrain = true, SaveLighting = true, IgnoreList = {} },
    Script = { IgnoreDefaultScripts = true, MarkProtected = true },
    Terrain = { Resolution = 4, ChunkSize = 64 },
    Performance = { BatchSize = 100, CacheEnabled = true },
    GUI = { Enabled = true, Keybind = Enum.KeyCode.RightShift },
    Debug = { Enabled = false, LogLevel = "INFO" },
}
local CurrentConfig = Utils.DeepClone(DefaultConfig)

function Config.Get(path, default)
    if not path then return Utils.DeepClone(CurrentConfig) end
    local keys = string.split(path, ".")
    local value = CurrentConfig
    for _, key in ipairs(keys) do
        if type(value) ~= "table" then return default end
        value = value[key]
    end
    return value ~= nil and (type(value) == "table" and Utils.DeepClone(value) or value) or default
end

function Config.Set(path, value)
    local keys = string.split(path, ".")
    local current = CurrentConfig
    for i = 1, #keys - 1 do
        if type(current[keys[i]]) ~= "table" then current[keys[i]] = {} end
        current = current[keys[i]]
    end
    current[keys[#keys]] = value
    return true
end

function Config.Reset(path)
    if path then
        local keys = string.split(path, ".")
        local defValue = DefaultConfig
        for _, key in ipairs(keys) do defValue = defValue and defValue[key] end
        return Config.Set(path, Utils.DeepClone(defValue))
    end
    CurrentConfig = Utils.DeepClone(DefaultConfig)
    return true
end

function Config.Export() return Services.HttpService:JSONEncode(CurrentConfig) end
function Config.Import(json)
    local success, data = pcall(Services.HttpService.JSONDecode, Services.HttpService, json)
    if success then CurrentConfig = Utils.Merge(DefaultConfig, data) return true end
    return false
end

BaoAPI.Config = Config

--// ═══════════════════════════════════════════════════════════════════════════════════
--// EMBEDDED: EVENT API
--// ═══════════════════════════════════════════════════════════════════════════════════

local EventAPI = {}
local Events = {}

function EventAPI.Create(name)
    if not Events[name] then Events[name] = { Listeners = {}, Once = {} } end
    return Events[name]
end

function EventAPI.On(name, callback, priority)
    local event = Events[name] or EventAPI.Create(name)
    local id = Utils.GenerateID("evt")
    table.insert(event.Listeners, { ID = id, Callback = callback, Priority = priority or 0, Enabled = true })
    table.sort(event.Listeners, function(a,b) return a.Priority > b.Priority end)
    return id
end

function EventAPI.Once(name, callback)
    local event = Events[name] or EventAPI.Create(name)
    local id = Utils.GenerateID("once")
    table.insert(event.Once, { ID = id, Callback = callback })
    return id
end

function EventAPI.Off(name, id)
    local event = Events[name]
    if not event then return false end
    for i, l in ipairs(event.Listeners) do if l.ID == id then table.remove(event.Listeners, i) return true end end
    for i, l in ipairs(event.Once) do if l.ID == id then table.remove(event.Once, i) return true end end
    return false
end

function EventAPI.Emit(name, ...)
    local event = Events[name]
    if not event then return {} end
    local results = {}
    for _, l in ipairs(event.Listeners) do
        if l.Enabled then
            local ok, res = pcall(l.Callback, ...)
            if ok then table.insert(results, res) end
        end
    end
    for _, l in ipairs(event.Once) do
        local ok, res = pcall(l.Callback, ...)
        if ok then table.insert(results, res) end
    end
    event.Once = {}
    return results
end

function EventAPI.Clear(name) if Events[name] then Events[name] = { Listeners = {}, Once = {} } end end
function EventAPI.List()
    local list = {}
    for name, e in pairs(Events) do table.insert(list, { Name = name, Count = #e.Listeners + #e.Once }) end
    return list
end

-- Pre-create built-in events
for _, name in ipairs({"BeforeSave","AfterSave","SaveProgress","SaveError","ConfigChanged","PluginLoaded","GUICreated"}) do
    EventAPI.Create(name)
end

BaoAPI.Event = EventAPI

--// ═══════════════════════════════════════════════════════════════════════════════════
--// EMBEDDED: HOOK API
--// ═══════════════════════════════════════════════════════════════════════════════════

local HookAPI = {}
local Hooks = {}

function HookAPI.Register(name, callback, priority)
    if not Hooks[name] then Hooks[name] = {} end
    local id = Utils.GenerateID("hook")
    table.insert(Hooks[name], { ID = id, Callback = callback, Priority = priority or 0, Enabled = true })
    table.sort(Hooks[name], function(a,b) return a.Priority > b.Priority end)
    return id
end

function HookAPI.Unregister(name, id)
    if not Hooks[name] then return false end
    for i, h in ipairs(Hooks[name]) do if h.ID == id then table.remove(Hooks[name], i) return true end end
    return false
end

function HookAPI.Run(name, data)
    if not Hooks[name] then return data end
    local result = data
    for _, h in ipairs(Hooks[name]) do
        if h.Enabled then
            local ok, newResult = pcall(h.Callback, result)
            if ok and newResult ~= nil then result = newResult end
        end
    end
    return result
end

function HookAPI.Clear(name) Hooks[name] = {} end
function HookAPI.List() 
    local list = {} 
    for name, hooks in pairs(Hooks) do table.insert(list, { Name = name, Count = #hooks }) end 
    return list 
end

-- Middleware shortcuts
HookAPI.Middleware = {
    Use = function(name, handler, priority) return HookAPI.Register("mw:"..name, handler, priority) end,
    Execute = function(name, data) return HookAPI.Run("mw:"..name, data) end,
}

BaoAPI.Hook = HookAPI

--// ═══════════════════════════════════════════════════════════════════════════════════
--// EMBEDDED: FILE API
--// ═══════════════════════════════════════════════════════════════════════════════════

local FileAPI = {}

function FileAPI.HasCapability(cap)
    local caps = { Read = readfile, Write = writefile, Append = appendfile, Delete = delfile, List = listfiles, MakeFolder = makefolder, IsFile = isfile, IsFolder = isfolder }
    return caps[cap] ~= nil
end

function FileAPI.Read(path) if not readfile then return nil end local ok, c = pcall(readfile, path) return ok and c or nil end
function FileAPI.Write(path, content) if not writefile then return false end return pcall(writefile, path, content) end
function FileAPI.Append(path, content) if appendfile then return pcall(appendfile, path, content) elseif readfile and writefile then return FileAPI.Write(path, (FileAPI.Read(path) or "") .. content) end return false end
function FileAPI.Delete(path) if not delfile then return false end return pcall(delfile, path) end
function FileAPI.Exists(path) if isfile then local ok, r = pcall(isfile, path) return ok and r end return false end
function FileAPI.FolderExists(path) if isfolder then local ok, r = pcall(isfolder, path) return ok and r end return false end
function FileAPI.CreateFolder(path) if not makefolder then return false end if FileAPI.FolderExists(path) then return true end return pcall(makefolder, path) end
function FileAPI.List(path) if not listfiles then return {} end local ok, files = pcall(listfiles, path) return ok and files or {} end
function FileAPI.JoinPath(...) return table.concat({...}, "/"):gsub("//+", "/") end
function FileAPI.EnsureSaveFolder() return FileAPI.CreateFolder(Config.Get("Save.FilePath", "BaoSaveInstance")) end
function FileAPI.GenerateSavePath(name, ext)
    FileAPI.EnsureSaveFolder()
    return FileAPI.JoinPath(Config.Get("Save.FilePath"), Utils.Sanitize(name or game.Name) .. "_" .. Utils.GetTimestamp() .. "." .. (ext or "rbxl"))
end

BaoAPI.File = FileAPI

--// ═══════════════════════════════════════════════════════════════════════════════════
--// EMBEDDED: LOGGER API
--// ═══════════════════════════════════════════════════════════════════════════════════

local LoggerAPI = {}
local Logs = {}
local LogLevels = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
local LogConfig = { MinLevel = 2, MaxLogs = 500, PrintConsole = true }

function LoggerAPI.SetLevel(level) LogConfig.MinLevel = type(level) == "string" and LogLevels[level:upper()] or level end

function LoggerAPI.Log(level, message, source)
    if type(level) == "string" then level = LogLevels[level:upper()] or 2 end
    if level < LogConfig.MinLevel then return end
    local entry = { Time = os.time(), Level = level, Message = tostring(message), Source = source }
    table.insert(Logs, entry)
    if #Logs > LogConfig.MaxLogs then table.remove(Logs, 1) end
    if LogConfig.PrintConsole then
        local prefix = "[BaoAPI:" .. ({"DEBUG","INFO","WARN","ERROR"})[level] .. "]"
        if level >= 3 then warn(prefix, message) else print(prefix, message) end
    end
    return entry
end

function LoggerAPI.Debug(msg, src) return LoggerAPI.Log(1, msg, src) end
function LoggerAPI.Info(msg, src) return LoggerAPI.Log(2, msg, src) end
function LoggerAPI.Warn(msg, src) return LoggerAPI.Log(3, msg, src) end
function LoggerAPI.Error(msg, src) return LoggerAPI.Log(4, msg, src) end
function LoggerAPI.GetAll() return Logs end
function LoggerAPI.Clear() Logs = {} end
function LoggerAPI.Export() return Services.HttpService:JSONEncode(Logs) end
function LoggerAPI.CreateScope(name)
    return {
        Debug = function(m) return LoggerAPI.Debug(m, name) end,
        Info = function(m) return LoggerAPI.Info(m, name) end,
        Warn = function(m) return LoggerAPI.Warn(m, name) end,
        Error = function(m) return LoggerAPI.Error(m, name) end,
    }
end

BaoAPI.Logger = LoggerAPI

--// ═══════════════════════════════════════════════════════════════════════════════════
--// EMBEDDED: SAVE API
--// ═══════════════════════════════════════════════════════════════════════════════════

local SaveAPI = {}
SaveAPI.Modes = { TERRAIN = "Terrain", SCRIPTS = "Scripts", MODEL = "Model", FULLMAP = "Full Map", ALL = "All" }

function SaveAPI.DetectClient()
    local info = { Name = "Unknown", CanSave = false, CanBinary = false, CanDecompile = false }
    if identifyexecutor then
        local name = identifyexecutor()
        info.Name = name or "Unknown"
        local lower = (name or ""):lower()
        info.CanBinary = lower:find("synapse") or lower:find("delta") or lower:find("script%-ware")
    end
    info.CanSave = saveinstance ~= nil or (syn and syn.saveinstance)
    info.CanDecompile = decompile ~= nil
    return info
end

function SaveAPI.Execute(mode, fileName, customOptions, callbacks)
    callbacks = callbacks or {}
    
    -- Emit before save
    local eventResults = EventAPI.Emit("BeforeSave", { Mode = mode, FileName = fileName })
    for _, r in ipairs(eventResults) do if r == false then if callbacks.onError then callbacks.onError("Cancelled") end return false end end
    
    local client = SaveAPI.DetectClient()
    if not client.CanSave then if callbacks.onError then callbacks.onError("saveinstance not available") end return false end
    
    FileAPI.EnsureSaveFolder()
    
    local gameName = Utils.Sanitize(fileName ~= "" and fileName or game.Name)
    local ext = client.CanBinary and Config.Get("Save.Binary", true) and "rbxl" or "rbxlx"
    local filePath = FileAPI.GenerateSavePath(gameName, ext)
    
    local options = {
        FilePath = filePath, FileName = filePath, Binary = ext == "rbxl",
        Decompile = Config.Get("Decompile.Enabled", true),
        DecompileTimeout = Config.Get("Decompile.Timeout", 10),
        RemovePlayers = Config.Get("Instance.RemovePlayers", true),
        IgnoreDefaultPlayerScripts = Config.Get("Script.IgnoreDefaultScripts", true),
        ShowStatus = true, IsolatePlayers = true,
        Ignore = {},
    }
    
    -- Merge custom options
    if customOptions then for k, v in pairs(customOptions) do options[k] = v end end
    
    -- Handle modes
    if mode == "Terrain" then
        for _, child in ipairs(Services.Workspace:GetChildren()) do
            if child ~= Services.Workspace.Terrain then table.insert(options.Ignore, child) end
        end
        options.Decompile = false
    elseif mode == "Model" then
        if not customOptions or not customOptions.Object then
            if callbacks.onError then callbacks.onError("No model specified") end
            return false
        end
        options.Object = customOptions.Object
    elseif mode == "Scripts" then
        options.Decompile = true
        options.DecompileTimeout = 30
    end
    
    -- Add player characters to ignore
    if options.RemovePlayers then
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player.Character then table.insert(options.Ignore, player.Character) end
        end
    end
    
    -- Run hooks
    options = HookAPI.Run("save:options", options)
    
    if callbacks.onStart then callbacks.onStart() end
    
    options.Callback = function(data)
        if callbacks.onProgress and data then
            EventAPI.Emit("SaveProgress", data)
            callbacks.onProgress(data.Percent or 0, data.Status or "Saving...")
        end
    end
    
    -- Execute
    local saveFunc = saveinstance or (syn and syn.saveinstance)
    local success, err = pcall(saveFunc, options)
    
    if success then
        EventAPI.Emit("AfterSave", { Mode = mode, FilePath = filePath })
        if callbacks.onComplete then callbacks.onComplete(filePath) end
        LoggerAPI.Info("Saved: " .. filePath)
        return true, filePath
    else
        EventAPI.Emit("SaveError", { Mode = mode, Error = tostring(err) })
        if callbacks.onError then callbacks.onError(tostring(err)) end
        LoggerAPI.Error("Save failed: " .. tostring(err))
        return false, tostring(err)
    end
end

-- Quick functions
function SaveAPI.All(name, opts, cb) return SaveAPI.Execute("All", name, opts, cb) end
function SaveAPI.Terrain(name, opts, cb) return SaveAPI.Execute("Terrain", name, opts, cb) end
function SaveAPI.Scripts(name, opts, cb) return SaveAPI.Execute("Scripts", name, opts, cb) end
function SaveAPI.FullMap(name, opts, cb) return SaveAPI.Execute("Full Map", name, opts, cb) end
function SaveAPI.Model(model, name, opts, cb)
    opts = opts or {}
    opts.Object = model
    return SaveAPI.Execute("Model", name or model.Name, opts, cb)
end

BaoAPI.Save = SaveAPI

--// ═══════════════════════════════════════════════════════════════════════════════════
--// EMBEDDED: PLUGIN API
--// ═══════════════════════════════════════════════════════════════════════════════════

local PluginAPI = {}
local Plugins = {}

function PluginAPI.Register(plugin)
    if type(plugin) ~= "table" or not plugin.Name then return false, "Invalid plugin" end
    if Plugins[plugin.Name] then return false, "Already registered" end
    
    plugin.ID = Utils.GenerateID("plugin")
    plugin.Enabled = true
    Plugins[plugin.Name] = plugin
    
    if plugin.OnLoad then pcall(plugin.OnLoad, plugin, BaoAPI) end
    EventAPI.Emit("PluginLoaded", plugin)
    LoggerAPI.Info("Plugin loaded: " .. plugin.Name)
    
    return true, plugin.ID
end

function PluginAPI.Unregister(name)
    local plugin = Plugins[name]
    if not plugin then return false end
    if plugin.OnUnload then pcall(plugin.OnUnload, plugin, BaoAPI) end
    Plugins[name] = nil
    return true
end

function PluginAPI.Get(name) return Plugins[name] end
function PluginAPI.List()
    local list = {}
    for name, p in pairs(Plugins) do table.insert(list, { Name = name, Enabled = p.Enabled, ID = p.ID }) end
    return list
end

function PluginAPI.Call(name, method, ...)
    local plugin = Plugins[name]
    if plugin and plugin[method] then return pcall(plugin[method], plugin, BaoAPI, ...) end
    return false
end

function PluginAPI.Broadcast(method, ...)
    local results = {}
    for name, plugin in pairs(Plugins) do
        if plugin.Enabled and plugin[method] then
            results[name] = { pcall(plugin[method], plugin, BaoAPI, ...) }
        end
    end
    return results
end

BaoAPI.Plugin = PluginAPI

--// ═══════════════════════════════════════════════════════════════════════════════════
--// INITIALIZATION
--// ═══════════════════════════════════════════════════════════════════════════════════

function BaoAPI.Init(options)
    options = options or {}
    
    -- Merge config
    if options.Config then
        for path, value in pairs(options.Config) do
            Config.Set(path, value)
        end
    end
    
    -- Load plugins
    if options.Plugins then
        for _, plugin in ipairs(options.Plugins) do
            PluginAPI.Register(plugin)
        end
    end
    
    -- Setup keybind
    local keybind = Config.Get("GUI.Keybind", Enum.KeyCode.RightShift)
    Services.UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == keybind then
            if BaoAPI.GUI and BaoAPI.GUI.Toggle then
                BaoAPI.GUI.Toggle()
            end
        end
    end)
    
    BaoAPI._LOADED = true
    LoggerAPI.Info("BaoSaveInstance API v" .. BaoAPI._VERSION .. " initialized")
    
    return BaoAPI
end

-- Quick aliases
BaoAPI.save = SaveAPI.Execute
BaoAPI.saveAll = SaveAPI.All
BaoAPI.saveTerrain = SaveAPI.Terrain
BaoAPI.saveScripts = SaveAPI.Scripts
BaoAPI.saveModel = SaveAPI.Model

BaoAPI.on = EventAPI.On
BaoAPI.off = EventAPI.Off
BaoAPI.emit = EventAPI.Emit

BaoAPI.config = Config.Get
BaoAPI.setConfig = Config.Set

BaoAPI.log = LoggerAPI.Info
BaoAPI.warn = LoggerAPI.Warn
BaoAPI.error = LoggerAPI.Error

BaoAPI.GetVersion = function() return BaoAPI._VERSION end
BaoAPI.GetClient = SaveAPI.DetectClient

--// ═══════════════════════════════════════════════════════════════════════════════════
--// AUTO INIT
--// ═══════════════════════════════════════════════════════════════════════════════════

BaoAPI.Init()

print([[
╔══════════════════════════════════════════════════════════════╗
║           BaoSaveInstance API Framework v3.0                 ║
╠══════════════════════════════════════════════════════════════╣
║  Loaded successfully!                                        ║
║  Keybind: Right Shift (toggle GUI if enabled)               ║
║                                                              ║
║  Quick Commands:                                             ║
║    BaoAPI.saveAll("name")     - Save entire game            ║
║    BaoAPI.saveTerrain("name") - Save terrain only           ║
║    BaoAPI.saveScripts("name") - Save all scripts            ║
║    BaoAPI.saveModel(obj)      - Save specific model         ║
║                                                              ║
║  API Reference:                                              ║
║    BaoAPI.Save, BaoAPI.Event, BaoAPI.Hook                   ║
║    BaoAPI.Config, BaoAPI.File, BaoAPI.Logger                ║
║    BaoAPI.Plugin, BaoAPI.Utils                              ║
╚══════════════════════════════════════════════════════════════╝
]])

return BaoAPI