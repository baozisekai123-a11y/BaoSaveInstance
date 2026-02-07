--[[
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                            BaoSaveInstance v2.0                                       ║
║                    Advanced Roblox Game Saving System                                 ║
║                         With Professional GUI Menu                                    ║
╠══════════════════════════════════════════════════════════════════════════════════════╣
║  Supported: Synapse X, Delta, Xeno, Solara, TNG                                      ║
║  Features: Terrain, Scripts, Models, Full Map, All-in-One                            ║
║  Output: .rbxl / .rbxlx                                                              ║
╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

--// ═══════════════════════════════════════════════════════════════════════════════════
--// SERVICES
--// ═══════════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local MaterialService = game:GetService("MaterialService")
local Chat = game:GetService("Chat")
local Teams = game:GetService("Teams")

local Player = Players.LocalPlayer

--// ═══════════════════════════════════════════════════════════════════════════════════
--// MAIN MODULE
--// ═══════════════════════════════════════════════════════════════════════════════════

local BaoSaveInstance = {}
BaoSaveInstance.Version = "2.0.0"
BaoSaveInstance.GUI = nil
BaoSaveInstance.IsOpen = false
BaoSaveInstance.IsSaving = false
BaoSaveInstance.SelectedModel = nil

--// Save Modes
BaoSaveInstance.SaveModes = {
    TERRAIN = "Terrain",
    SCRIPTS = "Scripts",
    MODEL = "Model",
    FULLMAP = "Full Map",
    ALL = "All"
}

--// Current Settings
BaoSaveInstance.Settings = {
    Mode = "All",
    FileName = "",
    OutputFormat = "rbxlx", -- rbxl hoặc rbxlx
    DecompileScripts = true,
    SaveTerrain = true,
    SaveLighting = true,
    SavePlayers = false,
    RemovePlayerCharacters = true,
    SaveCameraInstances = false,
    IgnoreDefaultPlayerScripts = true,
    IsolatePlayers = false,
    NilInstances = false,
    SaveNonCreatable = false,
    RemoveUnreachable = true,
}

--// Supported Clients
BaoSaveInstance.SupportedClients = {
    "Synapse X", "Delta", "Xeno", "Solara", "TNG"
}

--// Client Capabilities
BaoSaveInstance.ClientCapabilities = {
    ["Synapse X"] = {
        Decompile = true, SaveInstance = true, GetHiddenProperty = true,
        TerrainVoxels = true, FullSource = true, Binary = true
    },
    ["Delta"] = {
        Decompile = true, SaveInstance = true, GetHiddenProperty = true,
        TerrainVoxels = true, FullSource = false, Binary = true
    },
    ["Xeno"] = {
        Decompile = true, SaveInstance = true, GetHiddenProperty = false,
        TerrainVoxels = false, FullSource = false, Binary = false
    },
    ["Solara"] = {
        Decompile = true, SaveInstance = true, GetHiddenProperty = false,
        TerrainVoxels = false, FullSource = false, Binary = false
    },
    ["TNG"] = {
        Decompile = false, SaveInstance = false, GetHiddenProperty = false,
        TerrainVoxels = false, FullSource = false, Binary = false
    }
}

--// ═══════════════════════════════════════════════════════════════════════════════════
--// UTILITY FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════════════

local Utils = {}

function Utils.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    return success and result or nil
end

function Utils.GetTimestamp()
    local date = os.date("*t")
    return string.format("%04d%02d%02d_%02d%02d%02d", 
        date.year, date.month, date.day, date.hour, date.min, date.sec)
end

function Utils.SanitizeFileName(name)
    return name:gsub("[^%w%-_]", "_"):sub(1, 50)
end

function Utils.Tween(object, properties, duration, style, direction)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

function Utils.CreateRipple(button)
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.7
    ripple.BorderSizePixel = 0
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    local mouse = Player:GetMouse()
    local buttonPos = button.AbsolutePosition
    local relativeX = mouse.X - buttonPos.X
    local relativeY = mouse.Y - buttonPos.Y
    
    ripple.Position = UDim2.new(0, relativeX, 0, relativeY)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Parent = button
    
    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
    
    Utils.Tween(ripple, {Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1}, 0.5)
    
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

BaoSaveInstance.Utils = Utils

--// ═══════════════════════════════════════════════════════════════════════════════════
--// CLIENT DETECTOR
--// ═══════════════════════════════════════════════════════════════════════════════════

local ClientDetector = {}

function ClientDetector.Detect()
    local info = {
        Name = "Unknown",
        Version = "Unknown",
        IsSupported = false,
        Capabilities = {}
    }
    
    -- Method 1: identifyexecutor
    if identifyexecutor then
        local name, version = identifyexecutor()
        if name then
            info.Version = version or "Unknown"
            local lower = name:lower()
            
            if lower:find("synapse") then
                info.Name = "Synapse X"
            elseif lower:find("delta") then
                info.Name = "Delta"
            elseif lower:find("xeno") then
                info.Name = "Xeno"
            elseif lower:find("solara") then
                info.Name = "Solara"
            elseif lower:find("tng") then
                info.Name = "TNG"
            end
        end
    end
    
    -- Method 2: Check globals
    if info.Name == "Unknown" then
        if syn and syn.crypt then
            info.Name = "Synapse X"
        elseif XENO_UNIQUE then
            info.Name = "Xeno"
        elseif delta then
            info.Name = "Delta"
        elseif Solara then
            info.Name = "Solara"
        end
    end
    
    -- Load capabilities
    if BaoSaveInstance.ClientCapabilities[info.Name] then
        info.Capabilities = BaoSaveInstance.ClientCapabilities[info.Name]
        info.IsSupported = true
    end
    
    -- Runtime detection
    info.Capabilities.HasSaveInstance = saveinstance ~= nil or syn and syn.saveinstance ~= nil
    info.Capabilities.HasDecompile = decompile ~= nil
    info.Capabilities.HasWriteFile = writefile ~= nil
    info.Capabilities.HasMakeFolder = makefolder ~= nil
    
    return info
end

BaoSaveInstance.ClientDetector = ClientDetector

--// ═══════════════════════════════════════════════════════════════════════════════════
--// LOGGER
--// ═══════════════════════════════════════════════════════════════════════════════════

local Logger = {
    Logs = {},
    Stats = {
        Instances = 0,
        Scripts = 0,
        Properties = 0,
        Terrain = 0,
        Errors = 0
    }
}

function Logger.Log(level, message)
    table.insert(Logger.Logs, {
        Time = os.time(),
        Level = level,
        Message = message
    })
    
    if level == "ERROR" then
        Logger.Stats.Errors = Logger.Stats.Errors + 1
        warn("[BaoSave:ERROR] " .. message)
    elseif level == "WARN" then
        warn("[BaoSave:WARN] " .. message)
    else
        print("[BaoSave] " .. message)
    end
end

function Logger.Info(msg) Logger.Log("INFO", msg) end
function Logger.Warn(msg) Logger.Log("WARN", msg) end
function Logger.Error(msg) Logger.Log("ERROR", msg) end

function Logger.Reset()
    Logger.Logs = {}
    Logger.Stats = {Instances = 0, Scripts = 0, Properties = 0, Terrain = 0, Errors = 0}
end

BaoSaveInstance.Logger = Logger

--// ═══════════════════════════════════════════════════════════════════════════════════
--// GUI THEME
--// ═══════════════════════════════════════════════════════════════════════════════════

local Theme = {
    -- Main Colors
    Primary = Color3.fromRGB(88, 101, 242),      -- Discord Blurple
    PrimaryDark = Color3.fromRGB(71, 82, 196),
    PrimaryLight = Color3.fromRGB(114, 127, 255),
    
    -- Background Colors
    Background = Color3.fromRGB(30, 31, 34),
    BackgroundSecondary = Color3.fromRGB(43, 45, 49),
    BackgroundTertiary = Color3.fromRGB(54, 57, 63),
    
    -- Text Colors
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(185, 187, 190),
    TextMuted = Color3.fromRGB(114, 118, 125),
    
    -- Accent Colors
    Success = Color3.fromRGB(87, 242, 135),
    Warning = Color3.fromRGB(254, 231, 92),
    Error = Color3.fromRGB(237, 66, 69),
    Info = Color3.fromRGB(88, 182, 242),
    
    -- Mode Colors
    TerrainColor = Color3.fromRGB(46, 204, 113),
    ScriptsColor = Color3.fromRGB(241, 196, 15),
    ModelColor = Color3.fromRGB(155, 89, 182),
    FullMapColor = Color3.fromRGB(52, 152, 219),
    AllColor = Color3.fromRGB(231, 76, 60),
    
    -- Misc
    Border = Color3.fromRGB(60, 63, 68),
    Shadow = Color3.fromRGB(0, 0, 0),
    
    -- Fonts
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    FontLight = Enum.Font.Gotham,
}

BaoSaveInstance.Theme = Theme

--// ═══════════════════════════════════════════════════════════════════════════════════
--// GUI BUILDER
--// ═══════════════════════════════════════════════════════════════════════════════════

local GUIBuilder = {}

function GUIBuilder.CreateScreenGui()
    -- Xóa GUI cũ nếu có
    local oldGui = CoreGui:FindFirstChild("BaoSaveInstance")
    if oldGui then oldGui:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstance"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    -- Thử parent vào CoreGui, nếu không được thì vào PlayerGui
    local success = pcall(function()
        screenGui.Parent = CoreGui
    end)
    
    if not success then
        screenGui.Parent = Player:WaitForChild("PlayerGui")
    end
    
    return screenGui
end

function GUIBuilder.CreateMainFrame(parent)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 520, 0, 580)
    mainFrame.Position = UDim2.new(0.5, -260, 0.5, -290)
    mainFrame.BackgroundColor3 = Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = parent
    
    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = -1
    shadow.Parent = mainFrame
    
    -- Make draggable
    GUIBuilder.MakeDraggable(mainFrame)
    
    return mainFrame
end

function GUIBuilder.CreateTitleBar(parent)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Theme.BackgroundSecondary
    titleBar.BorderSizePixel = 0
    titleBar.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = titleBar
    
    -- Fix bottom corners
    local fix = Instance.new("Frame")
    fix.Name = "CornerFix"
    fix.Size = UDim2.new(1, 0, 0, 15)
    fix.Position = UDim2.new(0, 0, 1, -15)
    fix.BackgroundColor3 = Theme.BackgroundSecondary
    fix.BorderSizePixel = 0
    fix.Parent = titleBar
    
    -- Logo
    local logo = Instance.new("TextLabel")
    logo.Name = "Logo"
    logo.Size = UDim2.new(0, 40, 0, 40)
    logo.Position = UDim2.new(0, 10, 0.5, -20)
    logo.BackgroundColor3 = Theme.Primary
    logo.BorderSizePixel = 0
    logo.Text = "BS"
    logo.TextColor3 = Theme.Text
    logo.TextSize = 16
    logo.Font = Theme.FontBold
    logo.Parent = titleBar
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 8)
    logoCorner.Parent = logo
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 200, 0, 24)
    title.Position = UDim2.new(0, 60, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "BaoSaveInstance"
    title.TextColor3 = Theme.Text
    title.TextSize = 18
    title.Font = Theme.FontBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Version
    local version = Instance.new("TextLabel")
    version.Name = "Version"
    version.Size = UDim2.new(0, 100, 0, 16)
    version.Position = UDim2.new(0, 60, 0, 30)
    version.BackgroundTransparency = 1
    version.Text = "v" .. BaoSaveInstance.Version
    version.TextColor3 = Theme.TextMuted
    version.TextSize = 12
    version.Font = Theme.FontLight
    version.TextXAlignment = Enum.TextXAlignment.Left
    version.Parent = titleBar
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -46, 0.5, -18)
    closeBtn.BackgroundColor3 = Theme.Error
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.TextSecondary
    closeBtn.TextSize = 18
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
        Utils.CreateRipple(closeBtn)
        BaoSaveInstance.Close()
    end)
    
    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinimizeButton"
    minBtn.Size = UDim2.new(0, 36, 0, 36)
    minBtn.Position = UDim2.new(1, -86, 0.5, -18)
    minBtn.BackgroundColor3 = Theme.Warning
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "─"
    minBtn.TextColor3 = Theme.TextSecondary
    minBtn.TextSize = 18
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
        Utils.CreateRipple(minBtn)
        BaoSaveInstance.Minimize()
    end)
    
    return titleBar
end

function GUIBuilder.CreateModeSelector(parent)
    local container = Instance.new("Frame")
    container.Name = "ModeSelector"
    container.Size = UDim2.new(1, -30, 0, 180)
    container.Position = UDim2.new(0, 15, 0, 60)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Section Title
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, 0, 0, 24)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "📁 Chọn Loại Save"
    sectionTitle.TextColor3 = Theme.Text
    sectionTitle.TextSize = 16
    sectionTitle.Font = Theme.FontBold
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = container
    
    -- Mode Buttons Container
    local modesContainer = Instance.new("Frame")
    modesContainer.Name = "ModesContainer"
    modesContainer.Size = UDim2.new(1, 0, 0, 140)
    modesContainer.Position = UDim2.new(0, 0, 0, 30)
    modesContainer.BackgroundTransparency = 1
    modesContainer.Parent = container
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 150, 0, 60)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = modesContainer
    
    -- Mode Definitions
    local modes = {
        {Name = "Terrain", Icon = "🌍", Color = Theme.TerrainColor, Desc = "Chỉ lưu địa hình"},
        {Name = "Scripts", Icon = "📜", Color = Theme.ScriptsColor, Desc = "Chỉ lưu scripts"},
        {Name = "Model", Icon = "📦", Color = Theme.ModelColor, Desc = "Lưu 1 model cụ thể"},
        {Name = "Full Map", Icon = "🗺️", Color = Theme.FullMapColor, Desc = "Map + Objects"},
        {Name = "All", Icon = "⭐", Color = Theme.AllColor, Desc = "Toàn bộ game"}
    }
    
    local modeButtons = {}
    
    for i, mode in ipairs(modes) do
        local btn = Instance.new("TextButton")
        btn.Name = mode.Name
        btn.Size = UDim2.new(0, 150, 0, 60)
        btn.BackgroundColor3 = Theme.BackgroundSecondary
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.LayoutOrder = i
        btn.ClipsDescendants = true
        btn.Parent = modesContainer
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = btn
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Theme.Border
        btnStroke.Thickness = 1
        btnStroke.Parent = btn
        
        -- Icon
        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 30, 0, 30)
        icon.Position = UDim2.new(0, 10, 0.5, -15)
        icon.BackgroundTransparency = 1
        icon.Text = mode.Icon
        icon.TextSize = 22
        icon.Parent = btn
        
        -- Mode Name
        local name = Instance.new("TextLabel")
        name.Name = "ModeName"
        name.Size = UDim2.new(1, -50, 0, 20)
        name.Position = UDim2.new(0, 45, 0, 10)
        name.BackgroundTransparency = 1
        name.Text = mode.Name
        name.TextColor3 = Theme.Text
        name.TextSize = 14
        name.Font = Theme.FontBold
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = btn
        
        -- Description
        local desc = Instance.new("TextLabel")
        desc.Name = "Desc"
        desc.Size = UDim2.new(1, -50, 0, 16)
        desc.Position = UDim2.new(0, 45, 0, 32)
        desc.BackgroundTransparency = 1
        desc.Text = mode.Desc
        desc.TextColor3 = Theme.TextMuted
        desc.TextSize = 10
        desc.Font = Theme.FontLight
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = btn
        
        -- Selection indicator
        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(0, 4, 0.6, 0)
        indicator.Position = UDim2.new(0, 0, 0.2, 0)
        indicator.BackgroundColor3 = mode.Color
        indicator.BorderSizePixel = 0
        indicator.BackgroundTransparency = 1
        indicator.Parent = btn
        
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(0, 2)
        indicatorCorner.Parent = indicator
        
        modeButtons[mode.Name] = {Button = btn, Indicator = indicator, Stroke = btnStroke, Color = mode.Color}
        
        btn.MouseEnter:Connect(function()
            if BaoSaveInstance.Settings.Mode ~= mode.Name then
                Utils.Tween(btn, {BackgroundColor3 = Theme.BackgroundTertiary}, 0.2)
            end
        end)
        
        btn.MouseLeave:Connect(function()
            if BaoSaveInstance.Settings.Mode ~= mode.Name then
                Utils.Tween(btn, {BackgroundColor3 = Theme.BackgroundSecondary}, 0.2)
            end
        end)
        
        btn.MouseButton1Click:Connect(function()
            Utils.CreateRipple(btn)
            BaoSaveInstance.SelectMode(mode.Name, modeButtons)
        end)
    end
    
    -- Set default selection
    task.defer(function()
        BaoSaveInstance.SelectMode("All", modeButtons)
    end)
    
    return container, modeButtons
end

function GUIBuilder.CreateFileNameInput(parent)
    local container = Instance.new("Frame")
    container.Name = "FileNameContainer"
    container.Size = UDim2.new(1, -30, 0, 70)
    container.Position = UDim2.new(0, 15, 0, 250)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = "📝 Tên File"
    label.TextColor3 = Theme.Text
    label.TextSize = 14
    label.Font = Theme.FontBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Input Box
    local inputFrame = Instance.new("Frame")
    inputFrame.Name = "InputFrame"
    inputFrame.Size = UDim2.new(1, 0, 0, 40)
    inputFrame.Position = UDim2.new(0, 0, 0, 25)
    inputFrame.BackgroundColor3 = Theme.BackgroundSecondary
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = container
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = inputFrame
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Theme.Border
    inputStroke.Thickness = 1
    inputStroke.Parent = inputFrame
    
    local textBox = Instance.new("TextBox")
    textBox.Name = "TextBox"
    textBox.Size = UDim2.new(1, -20, 1, 0)
    textBox.Position = UDim2.new(0, 10, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.Text = ""
    textBox.PlaceholderText = "Nhập tên file (để trống = tên game)"
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
        BaoSaveInstance.Settings.FileName = textBox.Text
    end)
    
    return container, textBox
end

function GUIBuilder.CreateModelSelector(parent)
    local container = Instance.new("Frame")
    container.Name = "ModelSelector"
    container.Size = UDim2.new(1, -30, 0, 70)
    container.Position = UDim2.new(0, 15, 0, 250)
    container.BackgroundTransparency = 1
    container.Visible = false
    container.Parent = parent
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = "📦 Chọn Model (Click vào model trong game)"
    label.TextColor3 = Theme.Text
    label.TextSize = 14
    label.Font = Theme.FontBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Selected Model Display
    local selectedFrame = Instance.new("Frame")
    selectedFrame.Name = "SelectedFrame"
    selectedFrame.Size = UDim2.new(1, 0, 0, 40)
    selectedFrame.Position = UDim2.new(0, 0, 0, 25)
    selectedFrame.BackgroundColor3 = Theme.BackgroundSecondary
    selectedFrame.BorderSizePixel = 0
    selectedFrame.Parent = container
    
    local selectedCorner = Instance.new("UICorner")
    selectedCorner.CornerRadius = UDim.new(0, 8)
    selectedCorner.Parent = selectedFrame
    
    local selectedStroke = Instance.new("UIStroke")
    selectedStroke.Color = Theme.Border
    selectedStroke.Thickness = 1
    selectedStroke.Parent = selectedFrame
    
    local selectedText = Instance.new("TextLabel")
    selectedText.Name = "SelectedText"
    selectedText.Size = UDim2.new(1, -80, 1, 0)
    selectedText.Position = UDim2.new(0, 10, 0, 0)
    selectedText.BackgroundTransparency = 1
    selectedText.Text = "Chưa chọn model..."
    selectedText.TextColor3 = Theme.TextMuted
    selectedText.TextSize = 13
    selectedText.Font = Theme.Font
    selectedText.TextXAlignment = Enum.TextXAlignment.Left
    selectedText.TextTruncate = Enum.TextTruncate.AtEnd
    selectedText.Parent = selectedFrame
    
    -- Pick Button
    local pickBtn = Instance.new("TextButton")
    pickBtn.Name = "PickButton"
    pickBtn.Size = UDim2.new(0, 60, 0, 30)
    pickBtn.Position = UDim2.new(1, -70, 0.5, -15)
    pickBtn.BackgroundColor3 = Theme.Primary
    pickBtn.BorderSizePixel = 0
    pickBtn.Text = "Chọn"
    pickBtn.TextColor3 = Theme.Text
    pickBtn.TextSize = 12
    pickBtn.Font = Theme.FontBold
    pickBtn.Parent = selectedFrame
    
    local pickBtnCorner = Instance.new("UICorner")
    pickBtnCorner.CornerRadius = UDim.new(0, 6)
    pickBtnCorner.Parent = pickBtn
    
    pickBtn.MouseButton1Click:Connect(function()
        Utils.CreateRipple(pickBtn)
        BaoSaveInstance.StartModelPicker(selectedText, selectedStroke)
    end)
    
    return container, selectedText
end

function GUIBuilder.CreateOptionsPanel(parent)
    local container = Instance.new("Frame")
    container.Name = "OptionsPanel"
    container.Size = UDim2.new(1, -30, 0, 130)
    container.Position = UDim2.new(0, 15, 0, 330)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Section Title
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, 0, 0, 20)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "⚙️ Tùy Chọn"
    sectionTitle.TextColor3 = Theme.Text
    sectionTitle.TextSize = 14
    sectionTitle.Font = Theme.FontBold
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = container
    
    -- Options Grid
    local optionsGrid = Instance.new("Frame")
    optionsGrid.Name = "OptionsGrid"
    optionsGrid.Size = UDim2.new(1, 0, 0, 100)
    optionsGrid.Position = UDim2.new(0, 0, 0, 25)
    optionsGrid.BackgroundTransparency = 1
    optionsGrid.Parent = container
    
    local options = {
        {Name = "DecompileScripts", Label = "Decompile Scripts", Default = true},
        {Name = "SaveLighting", Label = "Save Lighting", Default = true},
        {Name = "RemovePlayerCharacters", Label = "Remove Players", Default = true},
        {Name = "IgnoreDefaultPlayerScripts", Label = "Ignore Default Scripts", Default = true}
    }
    
    for i, option in ipairs(options) do
        local toggle = GUIBuilder.CreateToggle(optionsGrid, option.Label, option.Default)
        toggle.Position = UDim2.new((i-1) % 2 * 0.5, 5, math.floor((i-1) / 2) * 0.5, 5)
        toggle.Size = UDim2.new(0.5, -10, 0, 40)
        
        local checkbox = toggle:FindFirstChild("Checkbox", true)
        if checkbox then
            checkbox.MouseButton1Click:Connect(function()
                BaoSaveInstance.Settings[option.Name] = not BaoSaveInstance.Settings[option.Name]
                GUIBuilder.UpdateToggle(checkbox, BaoSaveInstance.Settings[option.Name])
            end)
        end
    end
    
    return container
end

function GUIBuilder.CreateToggle(parent, label, default)
    local container = Instance.new("Frame")
    container.Name = label:gsub(" ", "")
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local checkbox = Instance.new("TextButton")
    checkbox.Name = "Checkbox"
    checkbox.Size = UDim2.new(0, 24, 0, 24)
    checkbox.Position = UDim2.new(0, 0, 0.5, -12)
    checkbox.BackgroundColor3 = default and Theme.Primary or Theme.BackgroundSecondary
    checkbox.BorderSizePixel = 0
    checkbox.Text = default and "✓" or ""
    checkbox.TextColor3 = Theme.Text
    checkbox.TextSize = 14
    checkbox.Font = Theme.FontBold
    checkbox.Parent = container
    
    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 6)
    checkCorner.Parent = checkbox
    
    local checkStroke = Instance.new("UIStroke")
    checkStroke.Color = default and Theme.Primary or Theme.Border
    checkStroke.Thickness = 1
    checkStroke.Parent = checkbox
    
    local labelText = Instance.new("TextLabel")
    labelText.Name = "Label"
    labelText.Size = UDim2.new(1, -34, 1, 0)
    labelText.Position = UDim2.new(0, 30, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = Theme.TextSecondary
    labelText.TextSize = 12
    labelText.Font = Theme.Font
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = container
    
    return container
end

function GUIBuilder.UpdateToggle(checkbox, enabled)
    Utils.Tween(checkbox, {
        BackgroundColor3 = enabled and Theme.Primary or Theme.BackgroundSecondary
    }, 0.2)
    
    checkbox.Text = enabled and "✓" or ""
    
    local stroke = checkbox:FindFirstChildOfClass("UIStroke")
    if stroke then
        Utils.Tween(stroke, {Color = enabled and Theme.Primary or Theme.Border}, 0.2)
    end
end

function GUIBuilder.CreateProgressBar(parent)
    local container = Instance.new("Frame")
    container.Name = "ProgressContainer"
    container.Size = UDim2.new(1, -30, 0, 50)
    container.Position = UDim2.new(0, 15, 0, 465)
    container.BackgroundTransparency = 1
    container.Visible = false
    container.Parent = parent
    
    -- Progress Label
    local label = Instance.new("TextLabel")
    label.Name = "ProgressLabel"
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = "Đang lưu... 0%"
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Progress Bar Background
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBg"
    progressBg.Size = UDim2.new(1, 0, 0, 12)
    progressBg.Position = UDim2.new(0, 0, 0, 25)
    progressBg.BackgroundColor3 = Theme.BackgroundSecondary
    progressBg.BorderSizePixel = 0
    progressBg.Parent = container
    
    local progressBgCorner = Instance.new("UICorner")
    progressBgCorner.CornerRadius = UDim.new(0, 6)
    progressBgCorner.Parent = progressBg
    
    -- Progress Bar Fill
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Theme.Primary
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 6)
    progressFillCorner.Parent = progressFill
    
    -- Gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.Primary),
        ColorSequenceKeypoint.new(1, Theme.PrimaryLight)
    }
    gradient.Parent = progressFill
    
    return container, label, progressFill
end

function GUIBuilder.CreateSaveButton(parent)
    local btn = Instance.new("TextButton")
    btn.Name = "SaveButton"
    btn.Size = UDim2.new(1, -30, 0, 50)
    btn.Position = UDim2.new(0, 15, 1, -65)
    btn.BackgroundColor3 = Theme.Primary
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ClipsDescendants = true
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    
    -- Gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.Primary),
        ColorSequenceKeypoint.new(1, Theme.PrimaryDark)
    }
    gradient.Rotation = 45
    gradient.Parent = btn
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0.5, -60, 0.5, -15)
    icon.BackgroundTransparency = 1
    icon.Text = "💾"
    icon.TextSize = 22
    icon.Parent = btn
    
    -- Text
    local text = Instance.new("TextLabel")
    text.Name = "Text"
    text.Size = UDim2.new(0, 100, 0, 24)
    text.Position = UDim2.new(0.5, -25, 0.5, -12)
    text.BackgroundTransparency = 1
    text.Text = "SAVE"
    text.TextColor3 = Theme.Text
    text.TextSize = 18
    text.Font = Theme.FontBold
    text.Parent = btn
    
    btn.MouseEnter:Connect(function()
        Utils.Tween(btn, {BackgroundColor3 = Theme.PrimaryLight}, 0.2)
    end)
    
    btn.MouseLeave:Connect(function()
        Utils.Tween(btn, {BackgroundColor3 = Theme.Primary}, 0.2)
    end)
    
    btn.MouseButton1Click:Connect(function()
        Utils.CreateRipple(btn)
        if not BaoSaveInstance.IsSaving then
            BaoSaveInstance.ExecuteSave()
        end
    end)
    
    return btn
end

function GUIBuilder.CreateStatusBar(parent)
    local statusBar = Instance.new("Frame")
    statusBar.Name = "StatusBar"
    statusBar.Size = UDim2.new(1, 0, 0, 30)
    statusBar.Position = UDim2.new(0, 0, 1, -30)
    statusBar.BackgroundColor3 = Theme.BackgroundSecondary
    statusBar.BorderSizePixel = 0
    statusBar.Parent = parent
    
    -- Client Info
    local clientInfo = Instance.new("TextLabel")
    clientInfo.Name = "ClientInfo"
    clientInfo.Size = UDim2.new(0.5, -10, 1, 0)
    clientInfo.Position = UDim2.new(0, 15, 0, 0)
    clientInfo.BackgroundTransparency = 1
    clientInfo.Text = "🔧 Detecting..."
    clientInfo.TextColor3 = Theme.TextMuted
    clientInfo.TextSize = 11
    clientInfo.Font = Theme.Font
    clientInfo.TextXAlignment = Enum.TextXAlignment.Left
    clientInfo.Parent = statusBar
    
    -- Game Info
    local gameInfo = Instance.new("TextLabel")
    gameInfo.Name = "GameInfo"
    gameInfo.Size = UDim2.new(0.5, -10, 1, 0)
    gameInfo.Position = UDim2.new(0.5, 0, 0, 0)
    gameInfo.BackgroundTransparency = 1
    gameInfo.Text = "🎮 " .. game.Name:sub(1, 25)
    gameInfo.TextColor3 = Theme.TextMuted
    gameInfo.TextSize = 11
    gameInfo.Font = Theme.Font
    gameInfo.TextXAlignment = Enum.TextXAlignment.Right
    gameInfo.TextTruncate = Enum.TextTruncate.AtEnd
    gameInfo.Parent = statusBar
    
    return statusBar, clientInfo
end

function GUIBuilder.MakeDraggable(frame)
    local dragging = false
    local dragInput, mousePos, framePos
    
    local titleBar = frame:FindFirstChild("TitleBar")
    local dragArea = titleBar or frame
    
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale, framePos.X.Offset + delta.X,
                framePos.Y.Scale, framePos.Y.Offset + delta.Y
            )
        end
    end)
end

BaoSaveInstance.GUIBuilder = GUIBuilder

--// ═══════════════════════════════════════════════════════════════════════════════════
--// SAVE SYSTEM
--// ═══════════════════════════════════════════════════════════════════════════════════

local SaveSystem = {}

--[[
    Build saveinstance options based on current settings and mode
]]
function SaveSystem.BuildOptions(mode, settings)
    local options = {
        ReClassify = true,
        Decompile = settings.DecompileScripts,
        NilInstances = settings.NilInstances,
        RemovePlayers = settings.RemovePlayerCharacters,
        SaveCacheInterval = 0x1600,
        ShowStatus = true,
        mode = mode == "optimized" and "optimized" or "full",
        noscripts = false,
        timeout = 60,
    }
    
    -- Thêm các tùy chọn phổ biến cho các exploit
    options.DecompileTimeout = 60
    options.SaveBytecode = false
    options.IgnoreDefaultPlayerScripts = settings.IgnoreDefaultPlayerScripts
    options.IsolatePlayers = settings.IsolatePlayers or false
    options.SaveNonCreatable = settings.SaveNonCreatable or false
    
    -- Ignore list
    options.Ignore = options.Ignore or {}
    
    if settings.RemovePlayerCharacters then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                table.insert(options.Ignore, player.Character)
            end
        end
    end
    
    return options
end

--[[
    Save using native saveinstance
]]
function SaveSystem.SaveNative(fileName, options, onProgress)
    local saveFunc = saveinstance or syn and syn.saveinstance
    
    if not saveFunc then
        return false, "saveinstance không khả dụng"
    end
    
    local success, err = pcall(function()
        options.FilePath = fileName
        options.FileName = fileName
        saveFunc(options)
    end)
    
    return success, err
end

--[[
    Get instances to save based on mode
]]
function SaveSystem.GetSaveTargets(mode)
    local targets = {}
    
    if mode == "Terrain" then
        targets = {Workspace.Terrain}
        
    elseif mode == "Scripts" then
        -- Collect all scripts
        local function collectScripts(parent)
            for _, child in ipairs(parent:GetDescendants()) do
                if child:IsA("LocalScript") or child:IsA("ModuleScript") or child:IsA("Script") then
                    table.insert(targets, child)
                end
            end
        end
        
        collectScripts(game)
        
    elseif mode == "Model" then
        if BaoSaveInstance.SelectedModel then
            targets = {BaoSaveInstance.SelectedModel}
        end
        
    elseif mode == "Full Map" then
        targets = {
            Workspace,
            Lighting,
            ReplicatedStorage,
            StarterGui,
            StarterPack,
            StarterPlayer,
        }
        
    else -- All
        targets = {game}
    end
    
    return targets
end

--[[
    Main save execution
]]
function SaveSystem.Execute(mode, fileName, settings, callbacks)
    callbacks = callbacks or {}
    
    local clientInfo = ClientDetector.Detect()
    
    if not clientInfo.IsSupported then
        if callbacks.onError then
            callbacks.onError("Client không được hỗ trợ: " .. clientInfo.Name)
        end
        return false
    end
    
    Logger.Reset()
    Logger.Info("Bắt đầu save - Mode: " .. mode .. " | Client: " .. clientInfo.Name)
    
    if callbacks.onStart then
        callbacks.onStart()
    end
    
    -- Ensure folder exists
    if makefolder then
        pcall(function()
            if not isfolder or not isfolder("BaoSaveInstance") then
                makefolder("BaoSaveInstance")
            end
        end)
    end
    
    -- Generate file name
    local gameName = Utils.SanitizeFileName(fileName ~= "" and fileName or game.Name)
    local timestamp = Utils.GetTimestamp()
    local extension = settings.OutputFormat or "rbxlx"
    local fullFileName = string.format("BaoSaveInstance/%s_%s.%s", gameName, timestamp, extension)
    
    -- Check if we can use binary format
    if extension == "rbxl" and not clientInfo.Capabilities.Binary then
        extension = "rbxlx"
        fullFileName = string.format("BaoSaveInstance/%s_%s.%s", gameName, timestamp, extension)
        Logger.Warn("Client không hỗ trợ .rbxl, chuyển sang .rbxlx")
    end
    
    local success = false
    local errorMsg = nil
    
    -- Try native saveinstance first
    if clientInfo.Capabilities.HasSaveInstance then
        local options = SaveSystem.BuildOptions("full", settings)
        
        if mode == "Terrain" then
            options.noscripts = true
            options.Ignore = {}
            -- Only save terrain
            for _, child in ipairs(Workspace:GetChildren()) do
                if child ~= Workspace.Terrain then
                    table.insert(options.Ignore, child)
                end
            end
            
        elseif mode == "Scripts" then
            -- Scripts mode - save all but mark
            options.mode = "scripts"
            
        elseif mode == "Model" then
            if BaoSaveInstance.SelectedModel then
                local modelOptions = {
                    Object = BaoSaveInstance.SelectedModel,
                    FilePath = fullFileName,
                    FileName = fullFileName,
                    Decompile = settings.DecompileScripts,
                }
                
                local saveFunc = saveinstance or syn and syn.saveinstance
                if saveFunc then
                    success, errorMsg = pcall(function()
                        saveFunc(modelOptions)
                    end)
                end
            else
                errorMsg = "Chưa chọn model"
            end
            
        elseif mode == "Full Map" then
            options.mode = "optimized"
            success, errorMsg = SaveSystem.SaveNative(fullFileName, options)
            
        else -- All
            options.mode = "full"
            success, errorMsg = SaveSystem.SaveNative(fullFileName, options)
        end
        
        if mode ~= "Model" and mode ~= "Scripts" then
            success, errorMsg = SaveSystem.SaveNative(fullFileName, options)
        end
        
    else
        -- Fallback to custom save (for TNG and others)
        Logger.Warn("Sử dụng fallback save method")
        
        local targets = SaveSystem.GetSaveTargets(mode)
        
        if #targets > 0 then
            success, errorMsg = SaveSystem.FallbackSave(targets, fullFileName, settings, callbacks)
        else
            errorMsg = "Không có gì để save"
        end
    end
    
    if success then
        Logger.Info("Save thành công: " .. fullFileName)
        
        if callbacks.onComplete then
            callbacks.onComplete(fullFileName)
        end
    else
        Logger.Error("Save thất bại: " .. tostring(errorMsg))
        
        if callbacks.onError then
            callbacks.onError(errorMsg)
        end
    end
    
    return success, fullFileName
end

--[[
    Fallback save for unsupported clients
]]
function SaveSystem.FallbackSave(targets, fileName, settings, callbacks)
    if not writefile then
        return false, "writefile không khả dụng"
    end
    
    -- Simple XML structure
    local xml = '<?xml version="1.0" encoding="utf-8"?>\n'
    xml = xml .. '<roblox version="4">\n'
    
    local totalInstances = 0
    local processedInstances = 0
    
    -- Count total
    for _, target in ipairs(targets) do
        if typeof(target) == "Instance" then
            totalInstances = totalInstances + 1
            pcall(function()
                totalInstances = totalInstances + #target:GetDescendants()
            end)
        end
    end
    
    local function serializeInstance(instance, indent)
        processedInstances = processedInstances + 1
        
        if callbacks.onProgress then
            local percent = math.floor((processedInstances / totalInstances) * 100)
            callbacks.onProgress(percent, processedInstances, totalInstances)
        end
        
        if processedInstances % 100 == 0 then
            task.wait()
        end
        
        local indentStr = string.rep("    ", indent)
        local str = indentStr .. '<Item class="' .. instance.ClassName .. '">\n'
        str = str .. indentStr .. '    <Properties>\n'
        str = str .. indentStr .. '        <string name="Name">' .. instance.Name:gsub("[<>&]", {["<"]="&lt;", [">"]="&gt;", ["&"]="&amp;"}) .. '</string>\n'
        str = str .. indentStr .. '    </Properties>\n'
        
        -- Children
        local children = {}
        pcall(function()
            children = instance:GetChildren()
        end)
        
        for _, child in ipairs(children) do
            if not child:IsA("Player") then
                str = str .. serializeInstance(child, indent + 1)
            end
        end
        
        str = str .. indentStr .. '</Item>\n'
        return str
    end
    
    for _, target in ipairs(targets) do
        if typeof(target) == "Instance" then
            xml = xml .. serializeInstance(target, 1)
        end
    end
    
    xml = xml .. '</roblox>'
    
    local success, err = pcall(function()
        writefile(fileName, xml)
    end)
    
    return success, err
end

BaoSaveInstance.SaveSystem = SaveSystem

--// ═══════════════════════════════════════════════════════════════════════════════════
--// MAIN GUI FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════════════

function BaoSaveInstance.Init()
    -- Xóa GUI cũ
    if BaoSaveInstance.GUI then
        BaoSaveInstance.GUI:Destroy()
    end
    
    -- Detect client
    local clientInfo = ClientDetector.Detect()
    
    -- Create GUI
    local screenGui = GUIBuilder.CreateScreenGui()
    BaoSaveInstance.GUI = screenGui
    
    local mainFrame = GUIBuilder.CreateMainFrame(screenGui)
    local titleBar = GUIBuilder.CreateTitleBar(mainFrame)
    local modeSelector, modeButtons = GUIBuilder.CreateModeSelector(mainFrame)
    local fileNameContainer, fileNameInput = GUIBuilder.CreateFileNameInput(mainFrame)
    local modelSelector, modelSelectedText = GUIBuilder.CreateModelSelector(mainFrame)
    local optionsPanel = GUIBuilder.CreateOptionsPanel(mainFrame)
    local progressContainer, progressLabel, progressFill = GUIBuilder.CreateProgressBar(mainFrame)
    local saveButton = GUIBuilder.CreateSaveButton(mainFrame)
    local statusBar, clientInfoLabel = GUIBuilder.CreateStatusBar(mainFrame)
    
    -- Store references
    BaoSaveInstance.Elements = {
        MainFrame = mainFrame,
        ModeButtons = modeButtons,
        FileNameInput = fileNameInput,
        ModelSelector = modelSelector,
        ModelSelectedText = modelSelectedText,
        FileNameContainer = fileNameContainer,
        ProgressContainer = progressContainer,
        ProgressLabel = progressLabel,
        ProgressFill = progressFill,
        SaveButton = saveButton,
        ClientInfoLabel = clientInfoLabel
    }
    
    -- Update client info
    local statusIcon = clientInfo.IsSupported and "✅" or "❌"
    clientInfoLabel.Text = statusIcon .. " " .. clientInfo.Name .. " " .. clientInfo.Version
    
    -- Animate in
    mainFrame.Position = UDim2.new(0.5, -260, 0, -600)
    mainFrame.BackgroundTransparency = 1
    
    Utils.Tween(mainFrame, {
        Position = UDim2.new(0.5, -260, 0.5, -290),
        BackgroundTransparency = 0
    }, 0.5, Enum.EasingStyle.Back)
    
    BaoSaveInstance.IsOpen = true
    
    Logger.Info("BaoSaveInstance GUI initialized")
    
    return screenGui
end

function BaoSaveInstance.SelectMode(modeName, modeButtons)
    BaoSaveInstance.Settings.Mode = modeName
    
    -- Update all buttons
    for name, data in pairs(modeButtons) do
        local isSelected = name == modeName
        
        Utils.Tween(data.Button, {
            BackgroundColor3 = isSelected and Theme.BackgroundTertiary or Theme.BackgroundSecondary
        }, 0.2)
        
        Utils.Tween(data.Indicator, {
            BackgroundTransparency = isSelected and 0 or 1
        }, 0.2)
        
        Utils.Tween(data.Stroke, {
            Color = isSelected and data.Color or Theme.Border,
            Thickness = isSelected and 2 or 1
        }, 0.2)
    end
    
    -- Show/hide model selector vs filename input
    if BaoSaveInstance.Elements then
        local showModel = modeName == "Model"
        BaoSaveInstance.Elements.ModelSelector.Visible = showModel
        BaoSaveInstance.Elements.FileNameContainer.Visible = not showModel
    end
    
    Logger.Info("Mode selected: " .. modeName)
end

function BaoSaveInstance.StartModelPicker(selectedText, selectedStroke)
    Logger.Info("Bắt đầu chọn model - Click vào model trong game")
    
    selectedText.Text = "⏳ Click vào model trong game..."
    Utils.Tween(selectedStroke, {Color = Theme.Warning}, 0.2)
    
    local mouse = Player:GetMouse()
    local connection
    
    connection = mouse.Button1Down:Connect(function()
        local target = mouse.Target
        
        if target and target:IsDescendantOf(Workspace) then
            -- Tìm model cha hoặc sử dụng part
            local model = target:FindFirstAncestorOfClass("Model") or target
            
            BaoSaveInstance.SelectedModel = model
            selectedText.Text = "✅ " .. model.Name
            selectedText.TextColor3 = Theme.Success
            Utils.Tween(selectedStroke, {Color = Theme.Success}, 0.2)
            
            Logger.Info("Model đã chọn: " .. model:GetFullName())
            
            connection:Disconnect()
        end
    end)
    
    -- Timeout after 30 seconds
    task.delay(30, function()
        if connection.Connected then
            connection:Disconnect()
            selectedText.Text = "❌ Hết thời gian chọn"
            selectedText.TextColor3 = Theme.Error
            Utils.Tween(selectedStroke, {Color = Theme.Error}, 0.2)
            
            task.wait(2)
            if not BaoSaveInstance.SelectedModel then
                selectedText.Text = "Chưa chọn model..."
                selectedText.TextColor3 = Theme.TextMuted
                Utils.Tween(selectedStroke, {Color = Theme.Border}, 0.2)
            end
        end
    end)
end

function BaoSaveInstance.ExecuteSave()
    if BaoSaveInstance.IsSaving then
        Logger.Warn("Đang trong quá trình save")
        return
    end
    
    local elements = BaoSaveInstance.Elements
    local mode = BaoSaveInstance.Settings.Mode
    local fileName = BaoSaveInstance.Settings.FileName
    
    -- Validate model mode
    if mode == "Model" and not BaoSaveInstance.SelectedModel then
        Logger.Error("Chưa chọn model để save")
        
        -- Flash error
        Utils.Tween(elements.ModelSelector, {BackgroundColor3 = Theme.Error}, 0.1)
        task.wait(0.1)
        Utils.Tween(elements.ModelSelector, {BackgroundTransparency = 1}, 0.1)
        
        return
    end
    
    BaoSaveInstance.IsSaving = true
    
    -- Update UI
    elements.ProgressContainer.Visible = true
    elements.SaveButton.BackgroundColor3 = Theme.TextMuted
    
    local saveButtonText = elements.SaveButton:FindFirstChild("Text", true)
    if saveButtonText then
        saveButtonText.Text = "SAVING..."
    end
    
    -- Execute save
    SaveSystem.Execute(mode, fileName, BaoSaveInstance.Settings, {
        onStart = function()
            elements.ProgressLabel.Text = "Đang chuẩn bị..."
            elements.ProgressFill.Size = UDim2.new(0, 0, 1, 0)
        end,
        
        onProgress = function(percent, current, total)
            elements.ProgressLabel.Text = string.format("Đang lưu... %d%% (%d/%d)", percent, current, total)
            Utils.Tween(elements.ProgressFill, {Size = UDim2.new(percent/100, 0, 1, 0)}, 0.1)
        end,
        
        onComplete = function(filePath)
            elements.ProgressLabel.Text = "✅ Hoàn thành: " .. filePath
            elements.ProgressLabel.TextColor3 = Theme.Success
            Utils.Tween(elements.ProgressFill, {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Theme.Success
            }, 0.3)
            
            task.wait(3)
            BaoSaveInstance.ResetSaveUI()
        end,
        
        onError = function(err)
            elements.ProgressLabel.Text = "❌ Lỗi: " .. tostring(err)
            elements.ProgressLabel.TextColor3 = Theme.Error
            Utils.Tween(elements.ProgressFill, {BackgroundColor3 = Theme.Error}, 0.2)
            
            task.wait(3)
            BaoSaveInstance.ResetSaveUI()
        end
    })
end

function BaoSaveInstance.ResetSaveUI()
    local elements = BaoSaveInstance.Elements
    
    BaoSaveInstance.IsSaving = false
    
    elements.ProgressContainer.Visible = false
    elements.ProgressLabel.TextColor3 = Theme.Text
    elements.ProgressFill.BackgroundColor3 = Theme.Primary
    elements.ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    elements.SaveButton.BackgroundColor3 = Theme.Primary
    
    local saveButtonText = elements.SaveButton:FindFirstChild("Text", true)
    if saveButtonText then
        saveButtonText.Text = "SAVE"
    end
end

function BaoSaveInstance.Close()
    if not BaoSaveInstance.GUI then return end
    
    local mainFrame = BaoSaveInstance.Elements.MainFrame
    
    Utils.Tween(mainFrame, {
        Position = UDim2.new(0.5, -260, 0, -600),
        BackgroundTransparency = 1
    }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    
    task.wait(0.4)
    
    BaoSaveInstance.GUI:Destroy()
    BaoSaveInstance.GUI = nil
    BaoSaveInstance.IsOpen = false
    
    Logger.Info("GUI closed")
end

function BaoSaveInstance.Minimize()
    if not BaoSaveInstance.GUI then return end
    
    local mainFrame = BaoSaveInstance.Elements.MainFrame
    
    if BaoSaveInstance.IsMinimized then
        Utils.Tween(mainFrame, {
            Size = UDim2.new(0, 520, 0, 580),
        }, 0.3)
        BaoSaveInstance.IsMinimized = false
    else
        Utils.Tween(mainFrame, {
            Size = UDim2.new(0, 520, 0, 50),
        }, 0.3)
        BaoSaveInstance.IsMinimized = true
    end
end

function BaoSaveInstance.Toggle()
    if BaoSaveInstance.IsOpen then
        BaoSaveInstance.Close()
    else
        BaoSaveInstance.Init()
    end
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// QUICK FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════════════

function BaoSaveInstance.QuickSave(mode, fileName)
    mode = mode or "All"
    
    SaveSystem.Execute(mode, fileName or "", BaoSaveInstance.Settings, {
        onComplete = function(filePath)
            print("✅ [BaoSaveInstance] Saved: " .. filePath)
        end,
        onError = function(err)
            warn("❌ [BaoSaveInstance] Error: " .. tostring(err))
        end
    })
end

function BaoSaveInstance.SaveTerrain(fileName)
    BaoSaveInstance.QuickSave("Terrain", fileName)
end

function BaoSaveInstance.SaveScripts(fileName)
    BaoSaveInstance.QuickSave("Scripts", fileName)
end

function BaoSaveInstance.SaveFullMap(fileName)
    BaoSaveInstance.QuickSave("Full Map", fileName)
end

function BaoSaveInstance.SaveAll(fileName)
    BaoSaveInstance.QuickSave("All", fileName)
end

function BaoSaveInstance.SaveModel(model, fileName)
    if typeof(model) ~= "Instance" then
        warn("Model không hợp lệ")
        return
    end
    
    BaoSaveInstance.SelectedModel = model
    BaoSaveInstance.QuickSave("Model", fileName or model.Name)
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// INITIALIZATION
--// ═══════════════════════════════════════════════════════════════════════════════════

-- Auto-initialize GUI
BaoSaveInstance.Init()

-- Keybind to toggle (Right Shift)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.RightShift then
        BaoSaveInstance.Toggle()
    end
end)

print([[
╔══════════════════════════════════════════════════════════════╗
║              BaoSaveInstance v2.0 Loaded!                    ║
╠══════════════════════════════════════════════════════════════╣
║  Phím tắt: Right Shift để toggle GUI                        ║
║                                                              ║
║  Commands:                                                   ║
║    BaoSaveInstance.SaveAll("name")     - Save toàn bộ       ║
║    BaoSaveInstance.SaveTerrain("name") - Save terrain       ║
║    BaoSaveInstance.SaveScripts("name") - Save scripts       ║
║    BaoSaveInstance.SaveFullMap("name") - Save full map      ║
║    BaoSaveInstance.SaveModel(obj)      - Save model         ║
║    BaoSaveInstance.Toggle()            - Toggle GUI         ║
╚══════════════════════════════════════════════════════════════╝
]])

return BaoSaveInstance
