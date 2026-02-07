--[[
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                       BaoSaveInstance API Framework v3.0                              ║
║                                   LOADER SCRIPT                                       ║
╠══════════════════════════════════════════════════════════════════════════════════════╣
║  Cách sử dụng:                                                                       ║
║    loadstring(game:HttpGet("URL/Loader.lua"))()                                      ║
║                                                                                      ║
║  Hoặc với options:                                                                   ║
║    loadstring(game:HttpGet("URL/Loader.lua"))()({                                   ║
║        AutoGUI = true,                                                               ║
║        Keybind = Enum.KeyCode.RightShift,                                           ║
║    })                                                                                ║
╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local Loader = {}
Loader._VERSION = "3.0.0"
Loader._LOADED = false

--// ═══════════════════════════════════════════════════════════════════════════════════
--// CONFIGURATION
--// ═══════════════════════════════════════════════════════════════════════════════════

local DefaultOptions = {
    -- Base URL cho các module (thay đổi theo hosting của bạn)
    BaseURL = "https://raw.githubusercontent.com/YourUsername/BaoSaveInstance/main/",
    
    -- Hoặc load từ local (nếu có)
    UseLocal = false,
    LocalPath = "BaoSaveInstance/",
    
    -- GUI Options
    AutoGUI = true,
    Keybind = Enum.KeyCode.RightShift,
    Theme = "Dark",
    
    -- Feature Options
    EnablePlugins = true,
    EnableTerrain = true,
    EnableScripts = true,
    
    -- Debug
    Debug = false,
    LogLevel = "INFO",
    
    -- Auto Update Check
    CheckUpdates = true,
}

--// ═══════════════════════════════════════════════════════════════════════════════════
--// MODULE PATHS
--// ═══════════════════════════════════════════════════════════════════════════════════

local ModulePaths = {
    -- Core modules
    {Name = "Services", Path = "Core/Services.lua", Required = true},
    {Name = "Utils", Path = "Core/Utils.lua", Required = true},
    {Name = "Config", Path = "Core/Config.lua", Required = true},
    
    -- API modules
    {Name = "EventAPI", Path = "API/EventAPI.lua", Required = true},
    {Name = "HookAPI", Path = "API/HookAPI.lua", Required = true},
    {Name = "FileAPI", Path = "API/FileAPI.lua", Required = true},
    {Name = "LoggerAPI", Path = "API/LoggerAPI.lua", Required = true},
    {Name = "SerializerAPI", Path = "API/SerializerAPI.lua", Required = true},
    {Name = "ScriptAPI", Path = "API/ScriptAPI.lua", Required = false},
    {Name = "TerrainAPI", Path = "API/TerrainAPI.lua", Required = false},
    {Name = "SaveAPI", Path = "API/SaveAPI.lua", Required = true},
    
    -- Plugin system
    {Name = "PluginManager", Path = "Plugins/PluginManager.lua", Required = false},
    
    -- GUI
    {Name = "Interface", Path = "GUI/Interface.lua", Required = false},
}

--// ═══════════════════════════════════════════════════════════════════════════════════
--// LOADER FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════════════

local function Log(level, message)
    local prefix = "[BaoLoader:" .. level .. "]"
    if level == "ERROR" then
        warn(prefix, message)
    else
        print(prefix, message)
    end
end

local function FetchModule(url)
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if success and result and #result > 0 then
        return result
    end
    
    return nil
end

local function LoadModule(code, moduleName)
    local success, result = pcall(function()
        local fn = loadstring(code)
        if fn then
            return fn()
        end
        return nil
    end)
    
    if success then
        return result
    else
        Log("ERROR", "Failed to load module '" .. moduleName .. "': " .. tostring(result))
        return nil
    end
end

local function LoadFromURL(baseURL, modulePath, moduleName)
    local url = baseURL .. modulePath
    Log("INFO", "Loading: " .. moduleName .. " from " .. url)
    
    local code = FetchModule(url)
    if code then
        return LoadModule(code, moduleName)
    else
        Log("ERROR", "Failed to fetch: " .. moduleName)
        return nil
    end
end

local function LoadFromLocal(basePath, modulePath, moduleName)
    if not readfile then
        Log("ERROR", "readfile not available for local loading")
        return nil
    end
    
    local path = basePath .. modulePath
    Log("INFO", "Loading: " .. moduleName .. " from " .. path)
    
    local success, code = pcall(readfile, path)
    if success and code then
        return LoadModule(code, moduleName)
    else
        Log("ERROR", "Failed to read: " .. moduleName)
        return nil
    end
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// MAIN LOADER
--// ═══════════════════════════════════════════════════════════════════════════════════

function Loader.Load(userOptions)
    if Loader._LOADED then
        Log("WARN", "BaoSaveInstance already loaded!")
        return _G.BaoAPI
    end
    
    -- Merge options
    local options = {}
    for k, v in pairs(DefaultOptions) do
        options[k] = v
    end
    for k, v in pairs(userOptions or {}) do
        options[k] = v
    end
    
    Log("INFO", "═══════════════════════════════════════════════════")
    Log("INFO", "    BaoSaveInstance API Framework v" .. Loader._VERSION)
    Log("INFO", "═══════════════════════════════════════════════════")
    
    -- Create main API object
    local BaoAPI = {
        _VERSION = Loader._VERSION,
        _NAME = "BaoSaveInstance",
        _LOADED_MODULES = {},
        _OPTIONS = options,
    }
    
    -- Load modules
    local loadedCount = 0
    local failedCount = 0
    
    for _, moduleInfo in ipairs(ModulePaths) do
        local module = nil
        
        -- Skip optional modules based on options
        if moduleInfo.Name == "Interface" and not options.AutoGUI then
            Log("INFO", "Skipping: " .. moduleInfo.Name .. " (disabled)")
            goto continue
        end
        
        if moduleInfo.Name == "TerrainAPI" and not options.EnableTerrain then
            Log("INFO", "Skipping: " .. moduleInfo.Name .. " (disabled)")
            goto continue
        end
        
        if moduleInfo.Name == "ScriptAPI" and not options.EnableScripts then
            Log("INFO", "Skipping: " .. moduleInfo.Name .. " (disabled)")
            goto continue
        end
        
        if moduleInfo.Name == "PluginManager" and not options.EnablePlugins then
            Log("INFO", "Skipping: " .. moduleInfo.Name .. " (disabled)")
            goto continue
        end
        
        -- Load module
        if options.UseLocal then
            module = LoadFromLocal(options.LocalPath, moduleInfo.Path, moduleInfo.Name)
        else
            module = LoadFromURL(options.BaseURL, moduleInfo.Path, moduleInfo.Name)
        end
        
        if module then
            BaoAPI._LOADED_MODULES[moduleInfo.Name] = module
            BaoAPI[moduleInfo.Name] = module
            loadedCount = loadedCount + 1
            Log("INFO", "✓ Loaded: " .. moduleInfo.Name)
        else
            failedCount = failedCount + 1
            if moduleInfo.Required then
                Log("ERROR", "✗ Required module failed: " .. moduleInfo.Name)
            else
                Log("WARN", "✗ Optional module failed: " .. moduleInfo.Name)
            end
        end
        
        ::continue::
    end
    
    Log("INFO", "───────────────────────────────────────────────────")
    Log("INFO", string.format("Loaded: %d modules | Failed: %d", loadedCount, failedCount))
    
    -- Setup shortcuts
    Loader.SetupShortcuts(BaoAPI)
    
    -- Initialize modules
    Loader.InitializeModules(BaoAPI, options)
    
    -- Store globally
    _G.BaoAPI = BaoAPI
    Loader._LOADED = true
    
    Log("INFO", "═══════════════════════════════════════════════════")
    Log("INFO", "    BaoSaveInstance loaded successfully!")
    Log("INFO", "    Keybind: " .. tostring(options.Keybind))
    Log("INFO", "═══════════════════════════════════════════════════")
    
    return BaoAPI
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// SHORTCUTS SETUP
--// ═══════════════════════════════════════════════════════════════════════════════════

function Loader.SetupShortcuts(BaoAPI)
    -- Save shortcuts
    BaoAPI.save = function(mode, name, opts, callbacks)
        if BaoAPI.SaveAPI then
            return BaoAPI.SaveAPI.Execute(mode, name, opts, callbacks)
        elseif BaoAPI.Save then
            return BaoAPI.Save.Execute(mode, name, opts, callbacks)
        end
    end
    
    BaoAPI.saveAll = function(name, opts, callbacks)
        return BaoAPI.save("All", name, opts, callbacks)
    end
    
    BaoAPI.saveTerrain = function(name, opts, callbacks)
        return BaoAPI.save("Terrain", name, opts, callbacks)
    end
    
    BaoAPI.saveScripts = function(name, opts, callbacks)
        return BaoAPI.save("Scripts", name, opts, callbacks)
    end
    
    BaoAPI.saveFullMap = function(name, opts, callbacks)
        return BaoAPI.save("Full Map", name, opts, callbacks)
    end
    
    BaoAPI.saveModel = function(model, name, opts, callbacks)
        opts = opts or {}
        opts.Object = model
        return BaoAPI.save("Model", name or (model and model.Name), opts, callbacks)
    end
    
    -- Event shortcuts
    BaoAPI.on = function(eventName, callback, priority)
        if BaoAPI.EventAPI then
            return BaoAPI.EventAPI.On(eventName, callback, priority)
        elseif BaoAPI.Event then
            return BaoAPI.Event.On(eventName, callback, priority)
        end
    end
    
    BaoAPI.off = function(eventName, listenerId)
        if BaoAPI.EventAPI then
            return BaoAPI.EventAPI.Off(eventName, listenerId)
        elseif BaoAPI.Event then
            return BaoAPI.Event.Off(eventName, listenerId)
        end
    end
    
    BaoAPI.emit = function(eventName, ...)
        if BaoAPI.EventAPI then
            return BaoAPI.EventAPI.Emit(eventName, ...)
        elseif BaoAPI.Event then
            return BaoAPI.Event.Emit(eventName, ...)
        end
    end
    
    -- Config shortcuts
    BaoAPI.config = function(path, default)
        if BaoAPI.Config then
            return BaoAPI.Config.Get(path, default)
        end
    end
    
    BaoAPI.setConfig = function(path, value)
        if BaoAPI.Config then
            return BaoAPI.Config.Set(path, value)
        end
    end
    
    -- Logger shortcuts
    BaoAPI.log = function(message, data)
        if BaoAPI.LoggerAPI then
            return BaoAPI.LoggerAPI.Info(message, data)
        elseif BaoAPI.Logger then
            return BaoAPI.Logger.Info(message, data)
        else
            print("[BaoAPI]", message)
        end
    end
    
    BaoAPI.warn = function(message, data)
        if BaoAPI.LoggerAPI then
            return BaoAPI.LoggerAPI.Warn(message, data)
        elseif BaoAPI.Logger then
            return BaoAPI.Logger.Warn(message, data)
        else
            warn("[BaoAPI]", message)
        end
    end
    
    BaoAPI.error = function(message, data)
        if BaoAPI.LoggerAPI then
            return BaoAPI.LoggerAPI.Error(message, data)
        elseif BaoAPI.Logger then
            return BaoAPI.Logger.Error(message, data)
        else
            warn("[BaoAPI:ERROR]", message)
        end
    end
    
    -- GUI shortcuts
    BaoAPI.showGUI = function()
        if BaoAPI.Interface then
            BaoAPI.Interface.Show()
        elseif BaoAPI.GUI then
            BaoAPI.GUI.Show()
        end
    end
    
    BaoAPI.hideGUI = function()
        if BaoAPI.Interface then
            BaoAPI.Interface.Hide()
        elseif BaoAPI.GUI then
            BaoAPI.GUI.Hide()
        end
    end
    
    BaoAPI.toggleGUI = function()
        if BaoAPI.Interface then
            BaoAPI.Interface.Toggle()
        elseif BaoAPI.GUI then
            BaoAPI.GUI.Toggle()
        end
    end
    
    -- Utility functions
    BaoAPI.getVersion = function()
        return BaoAPI._VERSION
    end
    
    BaoAPI.getClient = function()
        local info = {Name = "Unknown", CanSave = false}
        if identifyexecutor then
            info.Name = identifyexecutor() or "Unknown"
        end
        info.CanSave = saveinstance ~= nil or (syn and syn.saveinstance ~= nil)
        return info
    end
    
    BaoAPI.isReady = function()
        return BaoAPI._LOADED_MODULES ~= nil and next(BaoAPI._LOADED_MODULES) ~= nil
    end
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// MODULE INITIALIZATION
--// ═══════════════════════════════════════════════════════════════════════════════════

function Loader.InitializeModules(BaoAPI, options)
    -- Initialize Config
    if BaoAPI.Config and BaoAPI.Config.Set then
        BaoAPI.Config.Set("GUI.Enabled", options.AutoGUI)
        BaoAPI.Config.Set("GUI.Keybind", options.Keybind)
        BaoAPI.Config.Set("GUI.Theme", options.Theme)
        BaoAPI.Config.Set("Debug.Enabled", options.Debug)
        BaoAPI.Config.Set("Debug.LogLevel", options.LogLevel)
    end
    
    -- Initialize Interface
    if BaoAPI.Interface and BaoAPI.Interface.Init then
        BaoAPI.Interface.Init(BaoAPI)
    end
    
    -- Setup keybind
    local UserInputService = game:GetService("UserInputService")
    
    local keybindConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == options.Keybind then
            BaoAPI.toggleGUI()
        end
    end)
    
    -- Store connection for cleanup
    BaoAPI._connections = BaoAPI._connections or {}
    table.insert(BaoAPI._connections, keybindConnection)
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// AUTO EXECUTE
--// ═══════════════════════════════════════════════════════════════════════════════════

-- Return loader function
return function(options)
    return Loader.Load(options)
end