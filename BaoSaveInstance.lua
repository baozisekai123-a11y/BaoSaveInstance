--[[
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                       BaoSaveInstance v3.0 - ALL IN ONE                               ║
║                    Advanced Roblox Game Saving System                                 ║
╠══════════════════════════════════════════════════════════════════════════════════════╣
║  Cách sử dụng:                                                                       ║
║    loadstring(game:HttpGet("YOUR_RAW_URL"))()                                        ║
║                                                                                      ║
║  Supported: Synapse X, Delta, Xeno, Solara, Fluxus, KRNL, Script-Ware               ║
╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

--// ═══════════════════════════════════════════════════════════════════════════════════
--// SERVICES
--// ═══════════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local SoundService = game:GetService("SoundService")
local Chat = game:GetService("Chat")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local MaterialService = game:GetService("MaterialService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// ═══════════════════════════════════════════════════════════════════════════════════
--// MAIN API MODULE
--// ═══════════════════════════════════════════════════════════════════════════════════

local BaoAPI = {
    _VERSION = "3.0.0",
    _NAME = "BaoSaveInstance",
    _LOADED = false,
}

--// ═══════════════════════════════════════════════════════════════════════════════════
--// UTILITIES
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

function Utils.Tween(object, properties, duration, style, direction)
    duration = duration or 0.25
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local tween = TweenService:Create(object, TweenInfo.new(duration, style, direction), properties)
    tween:Play()
    return tween
end

function Utils.Ripple(button, color)
    color = color or Color3.fromRGB(255, 255, 255)
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.BackgroundColor3 = color
    ripple.BackgroundTransparency = 0.7
    ripple.BorderSizePixel = 0
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.ZIndex = button.ZIndex + 1
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    local pos = button.AbsolutePosition
    local mousePos = UserInputService:GetMouseLocation()
    ripple.Position = UDim2.new(0, mousePos.X - pos.X, 0, mousePos.Y - pos.Y - 36)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Parent = button
    
    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
    Utils.Tween(ripple, {Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1}, 0.5)
    task.delay(0.5, function() if ripple and ripple.Parent then ripple:Destroy() end end)
end

BaoAPI.Utils = Utils

--// ═══════════════════════════════════════════════════════════════════════════════════
--// CONFIG
--// ═══════════════════════════════════════════════════════════════════════════════════

local Config = {}
local DefaultConfig = {
    Save = { Mode = "All", FileName = "", FilePath = "BaoSaveInstance", Binary = true, Timeout = 60 },
    Decompile = { Enabled = true, Timeout = 10, IgnoreErrors = true },
    Instance = { RemovePlayers = true, SaveTerrain = true, SaveLighting = true, IgnoreList = {} },
    Script = { IgnoreDefaultScripts = true, MarkProtected = true },
    GUI = { Enabled = true, Keybind = Enum.KeyCode.RightShift, Theme = "Dark" },
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

function Config.Reset() CurrentConfig = Utils.DeepClone(DefaultConfig) return true end

BaoAPI.Config = Config

--// ═══════════════════════════════════════════════════════════════════════════════════
--// EVENT SYSTEM
--// ═══════════════════════════════════════════════════════════════════════════════════

local Event = {}
local Events = {}

function Event.Create(name)
    if not Events[name] then Events[name] = { Listeners = {}, Once = {} } end
    return Events[name]
end

function Event.On(name, callback, priority)
    local event = Events[name] or Event.Create(name)
    local id = Utils.GenerateID("evt")
    table.insert(event.Listeners, { ID = id, Callback = callback, Priority = priority or 0 })
    table.sort(event.Listeners, function(a,b) return a.Priority > b.Priority end)
    return id
end

function Event.Once(name, callback)
    local event = Events[name] or Event.Create(name)
    local id = Utils.GenerateID("once")
    table.insert(event.Once, { ID = id, Callback = callback })
    return id
end

function Event.Off(name, id)
    local event = Events[name]
    if not event then return false end
    for i, l in ipairs(event.Listeners) do if l.ID == id then table.remove(event.Listeners, i) return true end end
    for i, l in ipairs(event.Once) do if l.ID == id then table.remove(event.Once, i) return true end end
    return false
end

function Event.Emit(name, ...)
    local event = Events[name]
    if not event then return {} end
    local results = {}
    for _, l in ipairs(event.Listeners) do
        local ok, res = pcall(l.Callback, ...)
        if ok then table.insert(results, res) end
    end
    for _, l in ipairs(event.Once) do
        local ok, res = pcall(l.Callback, ...)
        if ok then table.insert(results, res) end
    end
    event.Once = {}
    return results
end

function Event.Clear(name) if Events[name] then Events[name] = { Listeners = {}, Once = {} } end end

-- Built-in events
for _, name in ipairs({"BeforeSave","AfterSave","SaveProgress","SaveError","GUIOpened","GUIClosed"}) do
    Event.Create(name)
end

BaoAPI.Event = Event

--// ═══════════════════════════════════════════════════════════════════════════════════
--// FILE API
--// ═══════════════════════════════════════════════════════════════════════════════════

local File = {}

function File.HasCapability(cap)
    local caps = { Read = readfile, Write = writefile, MakeFolder = makefolder, IsFile = isfile, IsFolder = isfolder }
    return caps[cap] ~= nil
end

function File.Read(path) if not readfile then return nil end local ok, c = pcall(readfile, path) return ok and c or nil end
function File.Write(path, content) if not writefile then return false end return pcall(writefile, path, content) end
function File.Exists(path) if isfile then local ok, r = pcall(isfile, path) return ok and r end return false end
function File.FolderExists(path) if isfolder then local ok, r = pcall(isfolder, path) return ok and r end return false end
function File.CreateFolder(path) if not makefolder then return false end if File.FolderExists(path) then return true end return pcall(makefolder, path) end

function File.EnsureSaveFolder()
    return File.CreateFolder(Config.Get("Save.FilePath", "BaoSaveInstance"))
end

function File.GenerateSavePath(name, ext)
    File.EnsureSaveFolder()
    local gameName = Utils.Sanitize(name or game.Name)
    local timestamp = Utils.GetTimestamp()
    ext = ext or "rbxl"
    return Config.Get("Save.FilePath") .. "/" .. gameName .. "_" .. timestamp .. "." .. ext
end

BaoAPI.File = File

--// ═══════════════════════════════════════════════════════════════════════════════════
--// LOGGER
--// ═══════════════════════════════════════════════════════════════════════════════════

local Logger = {}
local Logs = {}
local LogLevels = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }

function Logger.Log(level, message)
    if type(level) == "string" then level = LogLevels[level:upper()] or 2 end
    table.insert(Logs, { Time = os.time(), Level = level, Message = tostring(message) })
    if #Logs > 500 then table.remove(Logs, 1) end
    local prefix = "[BaoAPI:" .. ({"DEBUG","INFO","WARN","ERROR"})[level] .. "]"
    if level >= 3 then warn(prefix, message) else print(prefix, message) end
end

function Logger.Debug(msg) Logger.Log(1, msg) end
function Logger.Info(msg) Logger.Log(2, msg) end
function Logger.Warn(msg) Logger.Log(3, msg) end
function Logger.Error(msg) Logger.Log(4, msg) end
function Logger.GetAll() return Logs end
function Logger.Clear() Logs = {} end

BaoAPI.Logger = Logger

--// ═══════════════════════════════════════════════════════════════════════════════════
--// CLIENT DETECTION
--// ═══════════════════════════════════════════════════════════════════════════════════

local function DetectClient()
    local info = { Name = "Unknown", Version = "Unknown", CanSave = false, CanBinary = false, CanDecompile = false }
    
    if identifyexecutor then
        local name, version = identifyexecutor()
        info.Name = name or "Unknown"
        info.Version = version or "Unknown"
        
        local lower = (name or ""):lower()
        info.CanBinary = lower:find("synapse") or lower:find("delta") or lower:find("script%-ware")
    end
    
    -- Fallback detection
    if info.Name == "Unknown" then
        if syn then info.Name = "Synapse X" info.CanBinary = true
        elseif XENO_UNIQUE then info.Name = "Xeno"
        elseif delta then info.Name = "Delta" info.CanBinary = true
        elseif Solara then info.Name = "Solara"
        elseif fluxus then info.Name = "Fluxus"
        elseif KRNL_LOADED then info.Name = "KRNL"
        end
    end
    
    info.CanSave = saveinstance ~= nil or (syn and syn.saveinstance ~= nil)
    info.CanDecompile = decompile ~= nil or (syn and syn.decompile ~= nil)
    
    return info
end

BaoAPI.DetectClient = DetectClient

--// ═══════════════════════════════════════════════════════════════════════════════════
--// SAVE SYSTEM
--// ═══════════════════════════════════════════════════════════════════════════════════

local Save = {}
Save.Modes = { TERRAIN = "Terrain", SCRIPTS = "Scripts", MODEL = "Model", FULLMAP = "Full Map", ALL = "All" }

function Save.Execute(mode, fileName, customOptions, callbacks)
    callbacks = callbacks or {}
    
    -- Emit before save
    local eventResults = Event.Emit("BeforeSave", { Mode = mode, FileName = fileName })
    for _, r in ipairs(eventResults) do 
        if r == false then 
            if callbacks.onError then callbacks.onError("Cancelled by event") end 
            return false 
        end 
    end
    
    local client = DetectClient()
    if not client.CanSave then
        if callbacks.onError then callbacks.onError("saveinstance not available") end
        return false
    end
    
    File.EnsureSaveFolder()
    
    local gameName = Utils.Sanitize(fileName ~= "" and fileName or game.Name)
    local ext = client.CanBinary and Config.Get("Save.Binary", true) and "rbxl" or "rbxlx"
    local filePath = File.GenerateSavePath(gameName, ext)
    
    local options = {
        FilePath = filePath,
        FileName = filePath,
        Binary = ext == "rbxl",
        Decompile = Config.Get("Decompile.Enabled", true),
        DecompileTimeout = Config.Get("Decompile.Timeout", 10),
        RemovePlayers = Config.Get("Instance.RemovePlayers", true),
        IgnoreDefaultPlayerScripts = Config.Get("Script.IgnoreDefaultScripts", true),
        ShowStatus = true,
        IsolatePlayers = true,
        NilInstances = false,
        Ignore = {},
    }
    
    -- Merge custom options
    if customOptions then 
        for k, v in pairs(customOptions) do 
            options[k] = v 
        end 
    end
    
    -- Handle modes
    if mode == "Terrain" then
        for _, child in ipairs(Workspace:GetChildren()) do
            if child ~= Workspace.Terrain then 
                table.insert(options.Ignore, child) 
            end
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
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then 
                table.insert(options.Ignore, player.Character) 
            end
        end
    end
    
    if callbacks.onStart then callbacks.onStart() end
    
    options.Callback = function(data)
        if callbacks.onProgress and data then
            Event.Emit("SaveProgress", data)
            callbacks.onProgress(data.Percent or 0, data.Status or "Saving...")
        end
    end
    
    -- Execute
    local saveFunc = saveinstance or (syn and syn.saveinstance)
    local success, err = pcall(saveFunc, options)
    
    if success then
        Event.Emit("AfterSave", { Mode = mode, FilePath = filePath })
        if callbacks.onComplete then callbacks.onComplete(filePath) end
        Logger.Info("Saved: " .. filePath)
        return true, filePath
    else
        Event.Emit("SaveError", { Mode = mode, Error = tostring(err) })
        if callbacks.onError then callbacks.onError(tostring(err)) end
        Logger.Error("Save failed: " .. tostring(err))
        return false, tostring(err)
    end
end

function Save.All(name, opts, cb) return Save.Execute("All", name, opts, cb) end
function Save.Terrain(name, opts, cb) return Save.Execute("Terrain", name, opts, cb) end
function Save.Scripts(name, opts, cb) return Save.Execute("Scripts", name, opts, cb) end
function Save.FullMap(name, opts, cb) return Save.Execute("Full Map", name, opts, cb) end
function Save.Model(model, name, opts, cb)
    opts = opts or {}
    opts.Object = model
    return Save.Execute("Model", name or model.Name, opts, cb)
end

BaoAPI.Save = Save

--// ═══════════════════════════════════════════════════════════════════════════════════
--// THEME
--// ═══════════════════════════════════════════════════════════════════════════════════

local Theme = {
    Primary = Color3.fromRGB(88, 101, 242),
    PrimaryHover = Color3.fromRGB(104, 117, 255),
    PrimaryActive = Color3.fromRGB(71, 82, 196),
    
    Background = Color3.fromRGB(30, 31, 34),
    BackgroundSecondary = Color3.fromRGB(43, 45, 49),
    BackgroundTertiary = Color3.fromRGB(54, 57, 63),
    
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(185, 187, 190),
    TextMuted = Color3.fromRGB(114, 118, 125),
    
    Success = Color3.fromRGB(87, 242, 135),
    Warning = Color3.fromRGB(254, 231, 92),
    Error = Color3.fromRGB(237, 66, 69),
    
    Terrain = Color3.fromRGB(46, 204, 113),
    Scripts = Color3.fromRGB(241, 196, 15),
    Model = Color3.fromRGB(155, 89, 182),
    FullMap = Color3.fromRGB(52, 152, 219),
    All = Color3.fromRGB(231, 76, 60),
    
    Border = Color3.fromRGB(60, 63, 68),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
}

--// ═══════════════════════════════════════════════════════════════════════════════════
--// GUI INTERFACE
--// ═══════════════════════════════════════════════════════════════════════════════════

local GUI = {}
GUI._instance = nil
GUI._isOpen = false
GUI._isMinimized = false
GUI._isSaving = false
GUI._selectedMode = "All"
GUI._selectedModel = nil
GUI._elements = {}
GUI._connections = {}

function GUI.Create()
    -- Clean up old
    if GUI._instance then GUI.Destroy() end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstance"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    local success = pcall(function() screenGui.Parent = CoreGui end)
    if not success then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    
    GUI._instance = screenGui
    
    --// MAIN FRAME
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 560)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -280)
    mainFrame.BackgroundColor3 = Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 60, 1, 60)
    shadow.Position = UDim2.new(0, -30, 0, -30)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.4
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = -1
    shadow.Parent = mainFrame
    
    GUI._elements.MainFrame = mainFrame
    
    --// TITLE BAR
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 55)
    titleBar.BackgroundColor3 = Theme.BackgroundSecondary
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 15)
    titleFix.Position = UDim2.new(0, 0, 1, -15)
    titleFix.BackgroundColor3 = Theme.BackgroundSecondary
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    -- Logo
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 40, 0, 40)
    logo.Position = UDim2.new(0, 12, 0.5, -20)
    logo.BackgroundColor3 = Theme.Primary
    logo.BorderSizePixel = 0
    logo.Text = "💾"
    logo.TextSize = 20
    logo.Parent = titleBar
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 10)
    logoCorner.Parent = logo
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 200, 0, 22)
    title.Position = UDim2.new(0, 62, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "BaoSaveInstance"
    title.TextColor3 = Theme.Text
    title.TextSize = 17
    title.Font = Theme.FontBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Version
    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(0, 150, 0, 16)
    version.Position = UDim2.new(0, 62, 0, 32)
    version.BackgroundTransparency = 1
    version.Text = "v" .. BaoAPI._VERSION .. " • Single File"
    version.TextColor3 = Theme.TextMuted
    version.TextSize = 11
    version.Font = Theme.Font
    version.TextXAlignment = Enum.TextXAlignment.Left
    version.Parent = titleBar
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -48, 0.5, -18)
    closeBtn.BackgroundColor3 = Theme.Error
    closeBtn.BackgroundTransparency = 1
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.TextSecondary
    closeBtn.TextSize = 16
    closeBtn.Font = Theme.FontBold
    closeBtn.Parent = titleBar
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseEnter:Connect(function()
        Utils.Tween(closeBtn, {BackgroundTransparency = 0, TextColor3 = Theme.Text}, 0.2)
    end)
    closeBtn.MouseLeave:Connect(function()
        Utils.Tween(closeBtn, {BackgroundTransparency = 1, TextColor3 = Theme.TextSecondary}, 0.2)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        Utils.Ripple(closeBtn)
        GUI.Close()
    end)
    
    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 36, 0, 36)
    minBtn.Position = UDim2.new(1, -90, 0.5, -18)
    minBtn.BackgroundColor3 = Theme.Warning
    minBtn.BackgroundTransparency = 1
    minBtn.BorderSizePixel = 0
    minBtn.Text = "─"
    minBtn.TextColor3 = Theme.TextSecondary
    minBtn.TextSize = 16
    minBtn.Font = Theme.FontBold
    minBtn.Parent = titleBar
    
    local minBtnCorner = Instance.new("UICorner")
    minBtnCorner.CornerRadius = UDim.new(0, 8)
    minBtnCorner.Parent = minBtn
    
    minBtn.MouseEnter:Connect(function()
        Utils.Tween(minBtn, {BackgroundTransparency = 0, TextColor3 = Theme.Background}, 0.2)
    end)
    minBtn.MouseLeave:Connect(function()
        Utils.Tween(minBtn, {BackgroundTransparency = 1, TextColor3 = Theme.TextSecondary}, 0.2)
    end)
    minBtn.MouseButton1Click:Connect(function()
        Utils.Ripple(minBtn)
        GUI.Minimize()
    end)
    
    GUI._elements.TitleBar = titleBar
    
    --// CONTENT
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -24, 1, -95)
    content.Position = UDim2.new(0, 12, 0, 60)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    
    GUI._elements.Content = content
    
    --// MODE SECTION
    local modeLabel = Instance.new("TextLabel")
    modeLabel.Size = UDim2.new(1, 0, 0, 22)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Text = "📁 CHỌN LOẠI SAVE"
    modeLabel.TextColor3 = Theme.Text
    modeLabel.TextSize = 13
    modeLabel.Font = Theme.FontBold
    modeLabel.TextXAlignment = Enum.TextXAlignment.Left
    modeLabel.Parent = content
    
    local modeGrid = Instance.new("Frame")
    modeGrid.Size = UDim2.new(1, 0, 0, 130)
    modeGrid.Position = UDim2.new(0, 0, 0, 28)
    modeGrid.BackgroundTransparency = 1
    modeGrid.Parent = content
    
    local modes = {
        {Name = "Terrain", Icon = "🌍", Color = Theme.Terrain, Desc = "Chỉ lưu địa hình", X = 0, Y = 0},
        {Name = "Scripts", Icon = "📜", Color = Theme.Scripts, Desc = "Toàn bộ scripts", X = 1, Y = 0},
        {Name = "Model", Icon = "📦", Color = Theme.Model, Desc = "1 Model cụ thể", X = 2, Y = 0},
        {Name = "Full Map", Icon = "🗺️", Color = Theme.FullMap, Desc = "Map đầy đủ", X = 0, Y = 1},
        {Name = "All", Icon = "⭐", Color = Theme.All, Desc = "Toàn bộ game", X = 1, Y = 1},
    }
    
    local modeButtons = {}
    local btnWidth = (476 - 20) / 3
    local btnHeight = 58
    
    for _, mode in ipairs(modes) do
        local btn = Instance.new("Frame")
        btn.Name = mode.Name
        btn.Size = UDim2.new(0, btnWidth, 0, btnHeight)
        btn.Position = UDim2.new(0, mode.X * (btnWidth + 10), 0, mode.Y * (btnHeight + 10))
        btn.BackgroundColor3 = Theme.BackgroundSecondary
        btn.BorderSizePixel = 0
        btn.Parent = modeGrid
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = btn
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Theme.Border
        btnStroke.Thickness = 1
        btnStroke.Parent = btn
        
        local clickArea = Instance.new("TextButton")
        clickArea.Size = UDim2.new(1, 0, 1, 0)
        clickArea.BackgroundTransparency = 1
        clickArea.Text = ""
        clickArea.Parent = btn
        
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 4, 0.6, 0)
        indicator.Position = UDim2.new(0, 0, 0.2, 0)
        indicator.BackgroundColor3 = mode.Color
        indicator.BackgroundTransparency = 1
        indicator.BorderSizePixel = 0
        indicator.Parent = btn
        
        local indCorner = Instance.new("UICorner")
        indCorner.CornerRadius = UDim.new(0, 2)
        indCorner.Parent = indicator
        
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 30, 1, 0)
        icon.Position = UDim2.new(0, 10, 0, 0)
        icon.BackgroundTransparency = 1
        icon.Text = mode.Icon
        icon.TextSize = 20
        icon.Parent = btn
        
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -50, 0, 18)
        name.Position = UDim2.new(0, 45, 0, 12)
        name.BackgroundTransparency = 1
        name.Text = mode.Name
        name.TextColor3 = Theme.Text
        name.TextSize = 13
        name.Font = Theme.FontBold
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = btn
        
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -50, 0, 14)
        desc.Position = UDim2.new(0, 45, 0, 32)
        desc.BackgroundTransparency = 1
        desc.Text = mode.Desc
        desc.TextColor3 = Theme.TextMuted
        desc.TextSize = 10
        desc.Font = Theme.Font
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = btn
        
        modeButtons[mode.Name] = {
            Button = btn,
            Indicator = indicator,
            Stroke = btnStroke,
            Color = mode.Color,
        }
        
        clickArea.MouseEnter:Connect(function()
            if GUI._selectedMode ~= mode.Name then
                Utils.Tween(btn, {BackgroundColor3 = Theme.BackgroundTertiary}, 0.15)
            end
        end)
        
        clickArea.MouseLeave:Connect(function()
            if GUI._selectedMode ~= mode.Name then
                Utils.Tween(btn, {BackgroundColor3 = Theme.BackgroundSecondary}, 0.15)
            end
        end)
        
        clickArea.MouseButton1Click:Connect(function()
            Utils.Ripple(btn)
            GUI.SelectMode(mode.Name)
        end)
    end
    
    GUI._elements.ModeButtons = modeButtons
    
    --// FILE NAME SECTION
    local fileSection = Instance.new("Frame")
    fileSection.Name = "FileSection"
    fileSection.Size = UDim2.new(1, 0, 0, 70)
    fileSection.Position = UDim2.new(0, 0, 0, 168)
    fileSection.BackgroundTransparency = 1
    fileSection.Parent = content
    
    local fileLabel = Instance.new("TextLabel")
    fileLabel.Size = UDim2.new(1, 0, 0, 20)
    fileLabel.BackgroundTransparency = 1
    fileLabel.Text = "📝 TÊN FILE (để trống = tên game)"
    fileLabel.TextColor3 = Theme.Text
    fileLabel.TextSize = 12
    fileLabel.Font = Theme.FontBold
    fileLabel.TextXAlignment = Enum.TextXAlignment.Left
    fileLabel.Parent = fileSection
    
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, 0, 0, 42)
    inputFrame.Position = UDim2.new(0, 0, 0, 24)
    inputFrame.BackgroundColor3 = Theme.BackgroundSecondary
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = fileSection
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = inputFrame
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Theme.Border
    inputStroke.Parent = inputFrame
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 1, 0)
    textBox.Position = UDim2.new(0, 10, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.Text = ""
    textBox.PlaceholderText = "Nhập tên file..."
    textBox.PlaceholderColor3 = Theme.TextMuted
    textBox.TextColor3 = Theme.Text
    textBox.TextSize = 14
    textBox.Font = Theme.Font
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    textBox.Parent = inputFrame
    
    textBox.Focused:Connect(function()
        Utils.Tween(inputStroke, {Color = Theme.Primary}, 0.2)
    end)
    textBox.FocusLost:Connect(function()
        Utils.Tween(inputStroke, {Color = Theme.Border}, 0.2)
    end)
    
    GUI._elements.FileSection = fileSection
    GUI._elements.FileInput = textBox
    
    --// MODEL SECTION (Hidden by default)
    local modelSection = Instance.new("Frame")
    modelSection.Name = "ModelSection"
    modelSection.Size = UDim2.new(1, 0, 0, 70)
    modelSection.Position = UDim2.new(0, 0, 0, 168)
    modelSection.BackgroundTransparency = 1
    modelSection.Visible = false
    modelSection.Parent = content
    
    local modelLabel = Instance.new("TextLabel")
    modelLabel.Size = UDim2.new(1, 0, 0, 20)
    modelLabel.BackgroundTransparency = 1
    modelLabel.Text = "📦 CHỌN MODEL (Click trong game)"
    modelLabel.TextColor3 = Theme.Text
    modelLabel.TextSize = 12
    modelLabel.Font = Theme.FontBold
    modelLabel.TextXAlignment = Enum.TextXAlignment.Left
    modelLabel.Parent = modelSection
    
    local modelFrame = Instance.new("Frame")
    modelFrame.Size = UDim2.new(1, 0, 0, 42)
    modelFrame.Position = UDim2.new(0, 0, 0, 24)
    modelFrame.BackgroundColor3 = Theme.BackgroundSecondary
    modelFrame.BorderSizePixel = 0
    modelFrame.Parent = modelSection
    
    local modelCorner = Instance.new("UICorner")
    modelCorner.CornerRadius = UDim.new(0, 8)
    modelCorner.Parent = modelFrame
    
    local modelStroke = Instance.new("UIStroke")
    modelStroke.Color = Theme.Border
    modelStroke.Parent = modelFrame
    
    local modelText = Instance.new("TextLabel")
    modelText.Size = UDim2.new(1, -85, 1, 0)
    modelText.Position = UDim2.new(0, 12, 0, 0)
    modelText.BackgroundTransparency = 1
    modelText.Text = "Chưa chọn model..."
    modelText.TextColor3 = Theme.TextMuted
    modelText.TextSize = 12
    modelText.Font = Theme.Font
    modelText.TextXAlignment = Enum.TextXAlignment.Left
    modelText.TextTruncate = Enum.TextTruncate.AtEnd
    modelText.Parent = modelFrame
    
    local pickBtn = Instance.new("TextButton")
    pickBtn.Size = UDim2.new(0, 65, 0, 32)
    pickBtn.Position = UDim2.new(1, -75, 0.5, -16)
    pickBtn.BackgroundColor3 = Theme.Primary
    pickBtn.BorderSizePixel = 0
    pickBtn.Text = "Chọn"
    pickBtn.TextColor3 = Theme.Text
    pickBtn.TextSize = 12
    pickBtn.Font = Theme.FontBold
    pickBtn.Parent = modelFrame
    
    local pickBtnCorner = Instance.new("UICorner")
    pickBtnCorner.CornerRadius = UDim.new(0, 6)
    pickBtnCorner.Parent = pickBtn
    
    pickBtn.MouseButton1Click:Connect(function()
        Utils.Ripple(pickBtn)
        GUI.StartModelPicker()
    end)
    
    GUI._elements.ModelSection = modelSection
    GUI._elements.ModelText = modelText
    GUI._elements.ModelStroke = modelStroke
    
    --// OPTIONS SECTION
    local optionsLabel = Instance.new("TextLabel")
    optionsLabel.Size = UDim2.new(1, 0, 0, 20)
    optionsLabel.Position = UDim2.new(0, 0, 0, 248)
    optionsLabel.BackgroundTransparency = 1
    optionsLabel.Text = "⚙️ TÙY CHỌN"
    optionsLabel.TextColor3 = Theme.Text
    optionsLabel.TextSize = 12
    optionsLabel.Font = Theme.FontBold
    optionsLabel.TextXAlignment = Enum.TextXAlignment.Left
    optionsLabel.Parent = content
    
    local optionsGrid = Instance.new("Frame")
    optionsGrid.Size = UDim2.new(1, 0, 0, 70)
    optionsGrid.Position = UDim2.new(0, 0, 0, 272)
    optionsGrid.BackgroundTransparency = 1
    optionsGrid.Parent = content
    
    local options = {
        {Key = "Decompile.Enabled", Label = "Decompile Scripts", X = 0, Y = 0, Default = true},
        {Key = "Instance.SaveTerrain", Label = "Save Terrain", X = 1, Y = 0, Default = true},
        {Key = "Instance.RemovePlayers", Label = "Remove Players", X = 0, Y = 1, Default = true},
        {Key = "Script.IgnoreDefaultScripts", Label = "Ignore Default Scripts", X = 1, Y = 1, Default = true},
    }
    
    GUI._elements.Options = {}
    
    for _, opt in ipairs(options) do
        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(0.48, 0, 0, 30)
        toggle.Position = UDim2.new(opt.X * 0.52, 0, 0, opt.Y * 35)
        toggle.BackgroundTransparency = 1
        toggle.Parent = optionsGrid
        
        local enabled = opt.Default
        
        local checkbox = Instance.new("TextButton")
        checkbox.Size = UDim2.new(0, 22, 0, 22)
        checkbox.Position = UDim2.new(0, 0, 0.5, -11)
        checkbox.BackgroundColor3 = enabled and Theme.Primary or Theme.BackgroundSecondary
        checkbox.BorderSizePixel = 0
        checkbox.Text = enabled and "✓" or ""
        checkbox.TextColor3 = Theme.Text
        checkbox.TextSize = 12
        checkbox.Font = Theme.FontBold
        checkbox.Parent = toggle
        
        local cbCorner = Instance.new("UICorner")
        cbCorner.CornerRadius = UDim.new(0, 6)
        cbCorner.Parent = checkbox
        
        local cbStroke = Instance.new("UIStroke")
        cbStroke.Color = enabled and Theme.Primary or Theme.Border
        cbStroke.Parent = checkbox
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -30, 1, 0)
        label.Position = UDim2.new(0, 28, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = opt.Label
        label.TextColor3 = Theme.TextSecondary
        label.TextSize = 11
        label.Font = Theme.Font
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = toggle
        
        checkbox.MouseButton1Click:Connect(function()
            enabled = not enabled
            Utils.Tween(checkbox, {BackgroundColor3 = enabled and Theme.Primary or Theme.BackgroundSecondary}, 0.2)
            Utils.Tween(cbStroke, {Color = enabled and Theme.Primary or Theme.Border}, 0.2)
            checkbox.Text = enabled and "✓" or ""
            Config.Set(opt.Key, enabled)
        end)
        
        GUI._elements.Options[opt.Key] = {Toggle = toggle, Checkbox = checkbox, Enabled = enabled}
    end
    
    --// PROGRESS SECTION
    local progressSection = Instance.new("Frame")
    progressSection.Name = "ProgressSection"
    progressSection.Size = UDim2.new(1, 0, 0, 50)
    progressSection.Position = UDim2.new(0, 0, 0, 355)
    progressSection.BackgroundTransparency = 1
    progressSection.Visible = false
    progressSection.Parent = content
    
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Size = UDim2.new(1, 0, 0, 18)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = "Đang lưu... 0%"
    progressLabel.TextColor3 = Theme.Text
    progressLabel.TextSize = 12
    progressLabel.Font = Theme.Font
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = progressSection
    
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, 0, 0, 12)
    progressBg.Position = UDim2.new(0, 0, 0, 24)
    progressBg.BackgroundColor3 = Theme.BackgroundSecondary
    progressBg.BorderSizePixel = 0
    progressBg.Parent = progressSection
    
    local progressBgCorner = Instance.new("UICorner")
    progressBgCorner.CornerRadius = UDim.new(0, 6)
    progressBgCorner.Parent = progressBg
    
    local progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Theme.Primary
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 6)
    progressFillCorner.Parent = progressFill
    
    GUI._elements.ProgressSection = progressSection
    GUI._elements.ProgressLabel = progressLabel
    GUI._elements.ProgressFill = progressFill
    
    --// SAVE BUTTON
    local saveBtn = Instance.new("TextButton")
    saveBtn.Name = "SaveButton"
    saveBtn.Size = UDim2.new(1, 0, 0, 52)
    saveBtn.Position = UDim2.new(0, 0, 1, -82)
    saveBtn.BackgroundColor3 = Theme.Primary
    saveBtn.BorderSizePixel = 0
    saveBtn.Text = ""
    saveBtn.ClipsDescendants = true
    saveBtn.Parent = content
    
    local saveBtnCorner = Instance.new("UICorner")
    saveBtnCorner.CornerRadius = UDim.new(0, 10)
    saveBtnCorner.Parent = saveBtn
    
    local saveGradient = Instance.new("UIGradient")
    saveGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Primary),
        ColorSequenceKeypoint.new(1, Theme.PrimaryActive),
    })
    saveGradient.Rotation = 45
    saveGradient.Parent = saveBtn
    
    local saveIcon = Instance.new("TextLabel")
    saveIcon.Size = UDim2.new(0, 30, 1, 0)
    saveIcon.Position = UDim2.new(0.5, -55, 0, 0)
    saveIcon.BackgroundTransparency = 1
    saveIcon.Text = "💾"
    saveIcon.TextSize = 22
    saveIcon.Parent = saveBtn
    
    local saveText = Instance.new("TextLabel")
    saveText.Size = UDim2.new(0, 80, 1, 0)
    saveText.Position = UDim2.new(0.5, -15, 0, 0)
    saveText.BackgroundTransparency = 1
    saveText.Text = "SAVE"
    saveText.TextColor3 = Theme.Text
    saveText.TextSize = 18
    saveText.Font = Theme.FontBold
    saveText.Parent = saveBtn
    
    saveBtn.MouseEnter:Connect(function()
        Utils.Tween(saveBtn, {BackgroundColor3 = Theme.PrimaryHover}, 0.15)
    end)
    saveBtn.MouseLeave:Connect(function()
        Utils.Tween(saveBtn, {BackgroundColor3 = Theme.Primary}, 0.15)
    end)
    saveBtn.MouseButton1Click:Connect(function()
        if not GUI._isSaving then
            Utils.Ripple(saveBtn)
            GUI.ExecuteSave()
        end
    end)
    
    GUI._elements.SaveButton = saveBtn
    GUI._elements.SaveText = saveText
    
    --// STATUS BAR
    local statusBar = Instance.new("Frame")
    statusBar.Size = UDim2.new(1, 0, 0, 30)
    statusBar.Position = UDim2.new(0, 0, 1, -30)
    statusBar.BackgroundColor3 = Theme.BackgroundSecondary
    statusBar.BorderSizePixel = 0
    statusBar.Parent = mainFrame
    
    local clientInfo = Instance.new("TextLabel")
    clientInfo.Size = UDim2.new(0.5, -5, 1, 0)
    clientInfo.Position = UDim2.new(0, 12, 0, 0)
    clientInfo.BackgroundTransparency = 1
    clientInfo.Text = "🔧 Detecting..."
    clientInfo.TextColor3 = Theme.TextMuted
    clientInfo.TextSize = 10
    clientInfo.Font = Theme.Font
    clientInfo.TextXAlignment = Enum.TextXAlignment.Left
    clientInfo.Parent = statusBar
    
    local gameInfo = Instance.new("TextLabel")
    gameInfo.Size = UDim2.new(0.5, -15, 1, 0)
    gameInfo.Position = UDim2.new(0.5, 0, 0, 0)
    gameInfo.BackgroundTransparency = 1
    gameInfo.Text = "🎮 " .. game.Name:sub(1, 25)
    gameInfo.TextColor3 = Theme.TextMuted
    gameInfo.TextSize = 10
    gameInfo.Font = Theme.Font
    gameInfo.TextXAlignment = Enum.TextXAlignment.Right
    gameInfo.TextTruncate = Enum.TextTruncate.AtEnd
    gameInfo.Parent = statusBar
    
    -- Update client info
    local client = DetectClient()
    clientInfo.Text = (client.CanSave and "✅ " or "❌ ") .. client.Name
    
    GUI._elements.ClientInfo = clientInfo
    
    --// DRAGGABLE
    GUI.MakeDraggable(mainFrame, titleBar)
    
    --// ANIMATION
    mainFrame.Position = UDim2.new(0.5, -250, -0.5, 0)
    mainFrame.BackgroundTransparency = 1
    Utils.Tween(mainFrame, {Position = UDim2.new(0.5, -250, 0.5, -280), BackgroundTransparency = 0}, 0.5, Enum.EasingStyle.Back)
    
    -- Set default mode
    GUI.SelectMode("All")
    GUI._isOpen = true
    
    Event.Emit("GUIOpened")
    
    return screenGui
end

function GUI.MakeDraggable(frame, handle)
    local dragging, dragStart, frameStart = false, nil, nil
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            frameStart = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
        end
    end)
end

function GUI.SelectMode(modeName)
    GUI._selectedMode = modeName
    
    for name, data in pairs(GUI._elements.ModeButtons) do
        local isSelected = name == modeName
        Utils.Tween(data.Button, {BackgroundColor3 = isSelected and Theme.BackgroundTertiary or Theme.BackgroundSecondary}, 0.2)
        Utils.Tween(data.Indicator, {BackgroundTransparency = isSelected and 0 or 1}, 0.2)
        Utils.Tween(data.Stroke, {Color = isSelected and data.Color or Theme.Border, Thickness = isSelected and 2 or 1}, 0.2)
    end
    
    local isModel = modeName == "Model"
    GUI._elements.FileSection.Visible = not isModel
    GUI._elements.ModelSection.Visible = isModel
end

function GUI.StartModelPicker()
    local modelText = GUI._elements.ModelText
    local modelStroke = GUI._elements.ModelStroke
    
    modelText.Text = "⏳ Click vào model trong game..."
    modelText.TextColor3 = Theme.Warning
    Utils.Tween(modelStroke, {Color = Theme.Warning}, 0.2)
    
    local connection
    connection = Mouse.Button1Down:Connect(function()
        local target = Mouse.Target
        if target and target:IsDescendantOf(Workspace) then
            local model = target:FindFirstAncestorOfClass("Model") or target
            GUI._selectedModel = model
            modelText.Text = "✅ " .. model.Name
            modelText.TextColor3 = Theme.Success
            Utils.Tween(modelStroke, {Color = Theme.Success}, 0.2)
            Logger.Info("Model selected: " .. model:GetFullName())
            connection:Disconnect()
        end
    end)
    
    task.delay(30, function()
        if connection and connection.Connected then
            connection:Disconnect()
            if not GUI._selectedModel then
                modelText.Text = "❌ Hết thời gian"
                modelText.TextColor3 = Theme.Error
                Utils.Tween(modelStroke, {Color = Theme.Error}, 0.2)
                task.wait(2)
                modelText.Text = "Chưa chọn model..."
                modelText.TextColor3 = Theme.TextMuted
                Utils.Tween(modelStroke, {Color = Theme.Border}, 0.2)
            end
        end
    end)
end

function GUI.ExecuteSave()
    if GUI._isSaving then return end
    
    local mode = GUI._selectedMode
    local fileName = GUI._elements.FileInput.Text
    
    if mode == "Model" and not GUI._selectedModel then
        GUI._elements.ModelText.Text = "❌ Chọn model trước!"
        GUI._elements.ModelText.TextColor3 = Theme.Error
        task.wait(2)
        GUI._elements.ModelText.Text = "Chưa chọn model..."
        GUI._elements.ModelText.TextColor3 = Theme.TextMuted
        return
    end
    
    GUI._isSaving = true
    GUI._elements.ProgressSection.Visible = true
    GUI._elements.SaveText.Text = "SAVING..."
    Utils.Tween(GUI._elements.SaveButton, {BackgroundColor3 = Theme.TextMuted}, 0.2)
    
    local options = {}
    if mode == "Model" then options.Object = GUI._selectedModel end
    
    Save.Execute(mode, fileName, options, {
        onStart = function()
            GUI._elements.ProgressLabel.Text = "Đang chuẩn bị..."
            GUI._elements.ProgressFill.Size = UDim2.new(0, 0, 1, 0)
        end,
        onProgress = function(percent, status)
            GUI._elements.ProgressLabel.Text = (status or "Đang lưu...") .. " " .. percent .. "%"
            Utils.Tween(GUI._elements.ProgressFill, {Size = UDim2.new(percent/100, 0, 1, 0)}, 0.1)
        end,
        onComplete = function(filePath)
            GUI._elements.ProgressLabel.Text = "✅ " .. filePath
            GUI._elements.ProgressLabel.TextColor3 = Theme.Success
            Utils.Tween(GUI._elements.ProgressFill, {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.Success}, 0.2)
            task.wait(3)
            GUI.ResetSaveUI()
        end,
        onError = function(err)
            GUI._elements.ProgressLabel.Text = "❌ " .. tostring(err)
            GUI._elements.ProgressLabel.TextColor3 = Theme.Error
            Utils.Tween(GUI._elements.ProgressFill, {BackgroundColor3 = Theme.Error}, 0.2)
            task.wait(3)
            GUI.ResetSaveUI()
        end
    })
end

function GUI.ResetSaveUI()
    GUI._isSaving = false
    GUI._elements.ProgressSection.Visible = false
    GUI._elements.ProgressLabel.TextColor3 = Theme.Text
    GUI._elements.ProgressFill.BackgroundColor3 = Theme.Primary
    GUI._elements.ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    GUI._elements.SaveText.Text = "SAVE"
    Utils.Tween(GUI._elements.SaveButton, {BackgroundColor3 = Theme.Primary}, 0.2)
end

function GUI.Show()
    if not GUI._instance then
        GUI.Create()
    else
        GUI._instance.Enabled = true
        local mainFrame = GUI._elements.MainFrame
        if mainFrame then
            mainFrame.Position = UDim2.new(0.5, -250, -0.5, 0)
            Utils.Tween(mainFrame, {Position = UDim2.new(0.5, -250, 0.5, -280)}, 0.4, Enum.EasingStyle.Back)
        end
    end
    GUI._isOpen = true
    Event.Emit("GUIOpened")
end

function GUI.Hide()
    if not GUI._instance then return end
    local mainFrame = GUI._elements.MainFrame
    if mainFrame then
        Utils.Tween(mainFrame, {Position = UDim2.new(0.5, -250, 1.5, 0)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.35)
        GUI._instance.Enabled = false
    end
    GUI._isOpen = false
    Event.Emit("GUIClosed")
end

function GUI.Close() GUI.Hide() end

function GUI.Toggle()
    if GUI._isOpen then GUI.Hide() else GUI.Show() end
end

function GUI.Minimize()
    local mainFrame = GUI._elements.MainFrame
    if not mainFrame then return end
    if GUI._isMinimized then
        Utils.Tween(mainFrame, {Size = UDim2.new(0, 500, 0, 560)}, 0.3)
        GUI._isMinimized = false
    else
        Utils.Tween(mainFrame, {Size = UDim2.new(0, 500, 0, 55)}, 0.3)
        GUI._isMinimized = true
    end
end

function GUI.Destroy()
    for _, conn in pairs(GUI._connections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    GUI._connections = {}
    if GUI._instance then GUI._instance:Destroy() GUI._instance = nil end
    GUI._isOpen = false
    GUI._elements = {}
end

function GUI.Notify(message, notifType, duration)
    notifType = notifType or "info"
    duration = duration or 3
    
    local colors = { info = Theme.Primary, success = Theme.Success, warning = Theme.Warning, error = Theme.Error }
    local icons = { info = "ℹ️", success = "✅", warning = "⚠️", error = "❌" }
    
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 300, 0, 50)
    toast.Position = UDim2.new(0.5, -150, 1, 60)
    toast.AnchorPoint = Vector2.new(0.5, 1)
    toast.BackgroundColor3 = Theme.BackgroundSecondary
    toast.BorderSizePixel = 0
    toast.ZIndex = 100
    toast.Parent = GUI._instance
    
    local toastCorner = Instance.new("UICorner")
    toastCorner.CornerRadius = UDim.new(0, 10)
    toastCorner.Parent = toast
    
    local toastStroke = Instance.new("UIStroke")
    toastStroke.Color = colors[notifType]
    toastStroke.Thickness = 2
    toastStroke.Parent = toast
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 1, 0)
    icon.Position = UDim2.new(0, 10, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = icons[notifType]
    icon.TextSize = 20
    icon.ZIndex = 101
    icon.Parent = toast
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -50, 1, 0)
    text.Position = UDim2.new(0, 45, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = message
    text.TextColor3 = Theme.Text
    text.TextSize = 13
    text.Font = Theme.Font
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextWrapped = true
    text.ZIndex = 101
    text.Parent = toast
    
    Utils.Tween(toast, {Position = UDim2.new(0.5, -150, 1, -20)}, 0.4, Enum.EasingStyle.Back)
    
    task.delay(duration, function()
        Utils.Tween(toast, {Position = UDim2.new(0.5, -150, 1, 60)}, 0.3)
        task.delay(0.3, function() if toast and toast.Parent then toast:Destroy() end end)
    end)
    
    return toast
end

BaoAPI.GUI = GUI

--// ═══════════════════════════════════════════════════════════════════════════════════
--// SHORTCUTS
--// ═══════════════════════════════════════════════════════════════════════════════════

BaoAPI.save = Save.Execute
BaoAPI.saveAll = Save.All
BaoAPI.saveTerrain = Save.Terrain
BaoAPI.saveScripts = Save.Scripts
BaoAPI.saveFullMap = Save.FullMap
BaoAPI.saveModel = Save.Model

BaoAPI.on = Event.On
BaoAPI.off = Event.Off
BaoAPI.emit = Event.Emit

BaoAPI.config = Config.Get
BaoAPI.setConfig = Config.Set

BaoAPI.log = Logger.Info
BaoAPI.warn = Logger.Warn
BaoAPI.error = Logger.Error

BaoAPI.showGUI = GUI.Show
BaoAPI.hideGUI = GUI.Hide
BaoAPI.toggleGUI = GUI.Toggle
BaoAPI.notify = GUI.Notify

BaoAPI.getVersion = function() return BaoAPI._VERSION end
BaoAPI.getClient = DetectClient
BaoAPI.isReady = function() return BaoAPI._LOADED end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// INITIALIZATION
--// ═══════════════════════════════════════════════════════════════════════════════════

local function Init()
    -- Create GUI
    GUI.Create()
    
    -- Setup keybind
    local keybind = Config.Get("GUI.Keybind", Enum.KeyCode.RightShift)
    local keyConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == keybind then
            GUI.Toggle()
        end
    end)
    table.insert(GUI._connections, keyConnection)
    
    BaoAPI._LOADED = true
    
    -- Store globally
    _G.BaoAPI = BaoAPI
    if getgenv then getgenv().BaoAPI = BaoAPI end
    
    Logger.Info("BaoSaveInstance v" .. BaoAPI._VERSION .. " loaded successfully!")
end

-- Auto init
Init()

-- Print usage
print([[
╔══════════════════════════════════════════════════════════════╗
║           BaoSaveInstance v3.0 Loaded!                       ║
╠══════════════════════════════════════════════════════════════╣
║  Keybind: Right Shift để toggle GUI                         ║
║                                                              ║
║  Commands:                                                   ║
║    BaoAPI.saveAll("name")     - Save toàn bộ game           ║
║    BaoAPI.saveTerrain("name") - Save terrain                ║
║    BaoAPI.saveScripts("name") - Save scripts                ║
║    BaoAPI.saveModel(obj)      - Save model                  ║
║    BaoAPI.toggleGUI()         - Toggle GUI                  ║
║    BaoAPI.notify("msg")       - Show notification           ║
╚══════════════════════════════════════════════════════════════╝
]])

return BaoAPI
