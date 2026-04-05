--[[
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║    ██████╗  █████╗  ██████╗     ███████╗ █████╗ ██╗   ██╗███████╗   ║
║    ██╔══██╗██╔══██╗██╔═══██╗    ██╔════╝██╔══██╗██║   ██║██╔════╝   ║
║    ██████╔╝███████║██║   ██║    ███████╗███████║██║   ██║█████╗     ║
║    ██╔══██╗██╔══██║██║   ██║    ╚════██║██╔══██║╚██╗ ██╔╝██╔══╝     ║
║    ██████╔╝██║  ██║╚██████╔╝    ███████║██║  ██║ ╚████╔╝ ███████╗   ║
║    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝     ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝   ║
║                                                                       ║
║              INSTANCE v3.5 UNIVERSAL EDITION                         ║
║         Supports ALL Executors on ALL Platforms                     ║
║                                                                       ║
║  Platform Support:                                                   ║
║  ✓ PC (Windows/Mac/Linux)        ✓ Mobile (Android/iOS)            ║
║  ✓ Laptop                        ✓ Tablet                          ║
║                                                                       ║
║  Executor Support:                                                   ║
║  ✓ Synapse X      ✓ Script-Ware   ✓ KRNL        ✓ Fluxus          ║
║  ✓ Arceus X       ✓ Delta         ✓ Codex       ✓ Hydrogen        ║
║  ✓ Oxygen U       ✓ JJSploit      ✓ Trigon      ✓ Nezur          ║
║  ✓ Valyse         ✓ Electron      ✓ Temple      ✓ Evon           ║
║  ✓ And 50+ more executors...                                       ║
║                                                                       ║
║  Version: 3.5.0 UNIVERSAL                                           ║
║  Author: Bao                                                        ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
]]

-- ============================================================
--                    UNIVERSAL COMPATIBILITY LAYER
-- ============================================================

local UniversalCompat = {}

-- Platform Detection
UniversalCompat.Platform = {
    IsMobile = false,
    IsPC = false,
    IsTablet = false,
    DeviceType = "Unknown",
    ScreenSize = Vector2.new(0, 0),
    Orientation = "Landscape"
}

-- Detect platform
local function DetectPlatform()
    local UserInputService = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")
    
    UniversalCompat.Platform.IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    UniversalCompat.Platform.IsPC = UserInputService.MouseEnabled and UserInputService.KeyboardEnabled
    
    local viewportSize = workspace.CurrentCamera.ViewportSize
    UniversalCompat.Platform.ScreenSize = viewportSize
    
    -- Detect device type
    if UniversalCompat.Platform.IsMobile then
        if viewportSize.X > 1000 or viewportSize.Y > 1000 then
            UniversalCompat.Platform.DeviceType = "Tablet"
            UniversalCompat.Platform.IsTablet = true
        else
            UniversalCompat.Platform.DeviceType = "Phone"
        end
    else
        UniversalCompat.Platform.DeviceType = "PC"
    end
    
    -- Detect orientation
    if viewportSize.X > viewportSize.Y then
        UniversalCompat.Platform.Orientation = "Landscape"
    else
        UniversalCompat.Platform.Orientation = "Portrait"
    end
    
    return UniversalCompat.Platform
end

-- Executor Detection
UniversalCompat.Executor = {
    Name = "Unknown",
    Version = "Unknown",
    Features = {}
}

local function DetectExecutor()
    local executors = {
        {name = "Synapse X", check = function() return syn and syn.request end},
        {name = "Script-Ware", check = function() return SCRIPT_WARE_VERSION or SWHUB_VERSION end},
        {name = "KRNL", check = function() return KRNL_LOADED end},
        {name = "Fluxus", check = function() return FLUXUS_LOADED or Fluxus end},
        {name = "Arceus X", check = function() return ARCEUS_LOADED or getgenv().ARCEUS end},
        {name = "Delta", check = function() return DELTA_LOADED or Delta end},
        {name = "Codex", check = function() return CODEX_LOADED end},
        {name = "Hydrogen", check = function() return HYDROGEN_LOADED end},
        {name = "Oxygen U", check = function() return OXYGEN_LOADED end},
        {name = "JJSploit", check = function() return JJSPLOIT_LOADED end},
        {name = "Trigon", check = function() return TRIGON_LOADED end},
        {name = "Nezur", check = function() return NEZUR_LOADED end},
        {name = "Valyse", check = function() return VALYSE_LOADED end},
        {name = "Electron", check = function() return ELECTRON_LOADED end},
        {name = "Temple", check = function() return TEMPLE_LOADED end},
        {name = "Evon", check = function() return EVON_LOADED end},
        {name = "Coco Z", check = function() return COCO_LOADED end},
        {name = "Sentinel", check = function() return SENTINEL_LOADED end},
        {name = "ProtoSmasher", check = function() return PROTOSMASHER_LOADED end},
        {name = "Sirhurt", check = function() return SIRHURT_LOADED end},
        {name = "Furk Ultra", check = function() return FURK_LOADED end},
        {name = "Vega X", check = function() return VEGAX_LOADED end},
        {name = "Comet", check = function() return COMET_LOADED end},
    }
    
    for _, executor in ipairs(executors) do
        if executor.check() then
            UniversalCompat.Executor.Name = executor.name
            return executor.name
        end
    end
    
    -- Check for generic identifiers
    if getgenv then
        UniversalCompat.Executor.Name = "Generic Executor (getgenv)"
    elseif _G then
        UniversalCompat.Executor.Name = "Generic Executor (_G)"
    end
    
    return UniversalCompat.Executor.Name
end

-- Universal Functions with Fallbacks
UniversalCompat.Functions = {}

-- File System
UniversalCompat.Functions.writefile = writefile or function(path, content)
    warn("[BAO] writefile not supported on this executor")
    return false
end

UniversalCompat.Functions.readfile = readfile or function(path)
    warn("[BAO] readfile not supported on this executor")
    return nil
end

UniversalCompat.Functions.isfile = isfile or function(path)
    return false
end

UniversalCompat.Functions.isfolder = isfolder or function(path)
    return false
end

UniversalCompat.Functions.makefolder = makefolder or function(path)
    warn("[BAO] makefolder not supported on this executor")
end

UniversalCompat.Functions.delfolder = delfolder or function(path)
    warn("[BAO] delfolder not supported on this executor")
end

UniversalCompat.Functions.delfile = delfile or function(path)
    warn("[BAO] delfile not supported on this executor")
end

UniversalCompat.Functions.listfiles = listfiles or function(path)
    warn("[BAO] listfiles not supported on this executor")
    return {}
end

-- Clipboard
UniversalCompat.Functions.setclipboard = setclipboard or toclipboard or set_clipboard or function(text)
    warn("[BAO] setclipboard not supported on this executor")
    warn("[BAO] Content: " .. tostring(text))
end

-- HTTP
UniversalCompat.Functions.request = request or http_request or syn and syn.request or function(options)
    warn("[BAO] request not supported on this executor")
    return {Success = false}
end

-- Decompiler
UniversalCompat.Functions.decompile = decompile or syn and syn.decompile or function(script)
    warn("[BAO] decompile not supported on this executor")
    return "-- Decompiler not available"
end

-- Get Script Source
UniversalCompat.Functions.getsource = getsource or decompile or function(script)
    local success, source = pcall(function()
        return script.Source
    end)
    if success then return source end
    return "-- Protected Script"
end

-- Environment
UniversalCompat.Functions.getgenv = getgenv or function()
    return _G
end

UniversalCompat.Functions.getrenv = getrenv or function()
    return _G
end

-- Drawing (for PC)
UniversalCompat.Functions.Drawing = Drawing or {}

-- Console
UniversalCompat.Functions.rconsolecreate = rconsolecreate or function()
    warn("[BAO] rconsolecreate not supported")
end

UniversalCompat.Functions.rconsoleprint = rconsoleprint or function(text)
    print(text)
end

-- GUI Protection
UniversalCompat.Functions.protect_gui = syn and syn.protect_gui or gethui or function(gui)
    return gui
end

-- Get Hidden UI
UniversalCompat.Functions.gethui = gethui or function()
    return game:GetService("CoreGui")
end

-- ============================================================
--                    CORE SYSTEM
-- ============================================================

local BaoSaveInstance = {
    Version = "3.5.0 UNIVERSAL",
    Author = "Bao",
    Modules = {},
    Config = {},
    Data = {},
    Platform = {},
    Executor = {}
}

-- Services
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    ReplicatedFirst = game:GetService("ReplicatedFirst"),
    StarterGui = game:GetService("StarterGui"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    CoreGui = game:GetService("CoreGui"),
    Stats = game:GetService("Stats"),
    GuiService = game:GetService("GuiService")
}

-- Initialize Platform Detection
BaoSaveInstance.Platform = DetectPlatform()
BaoSaveInstance.Executor = DetectExecutor()

-- Configuration (Auto-adjust based on platform)
BaoSaveInstance.Config = {
    -- Performance
    MultiThreading = true,
    MaxThreads = BaoSaveInstance.Platform.IsMobile and 5 or 10,
    ChunkSize = BaoSaveInstance.Platform.IsMobile and 50 or 100,
    CacheEnabled = true,
    CompressionEnabled = true,
    
    -- Features
    AutoBackup = true,
    CloudSync = false,
    Encryption = false, -- Disabled on mobile for performance
    Analytics = true,
    
    -- UI (Auto-adjust for mobile)
    Theme = "Dark",
    AnimationSpeed = BaoSaveInstance.Platform.IsMobile and 0.2 or 0.3,
    ParticleEffects = not BaoSaveInstance.Platform.IsMobile, -- Disable on mobile
    SoundEffects = false,
    
    -- Mobile specific
    TouchFriendly = BaoSaveInstance.Platform.IsMobile,
    LargeButtons = BaoSaveInstance.Platform.IsMobile,
    SimplifiedUI = BaoSaveInstance.Platform.IsMobile,
    
    -- Export
    DefaultFormat = "JSON",
    ExportPath = "BaoSaveInstance/",
    AutoSave = true,
    VersionControl = not BaoSaveInstance.Platform.IsMobile
}

-- ============================================================
--                    UTILITY FUNCTIONS
-- ============================================================

local Util = {}

function Util.UUID()
    return Services.HttpService:GenerateGUID(false)
end

function Util.Timestamp()
    return os.time()
end

function Util.DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = Util.DeepCopy(v)
    end
    return copy
end

function Util.FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.2fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.2fK", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

function Util.FormatBytes(bytes)
    if bytes >= 1073741824 then
        return string.format("%.2f GB", bytes / 1073741824)
    elseif bytes >= 1048576 then
        return string.format("%.2f MB", bytes / 1048576)
    elseif bytes >= 1024 then
        return string.format("%.2f KB", bytes / 1024)
    else
        return bytes .. " B"
    end
end

-- ============================================================
--                    RESPONSIVE UI SYSTEM
-- ============================================================

BaoSaveInstance.Modules.UI = {}
local UI = BaoSaveInstance.Modules.UI

-- Color Palette
UI.Colors = {
    Primary = Color3.fromRGB(88, 101, 242),
    Secondary = Color3.fromRGB(114, 137, 218),
    Success = Color3.fromRGB(67, 181, 129),
    Warning = Color3.fromRGB(250, 166, 26),
    Error = Color3.fromRGB(240, 71, 71),
    Background = Color3.fromRGB(18, 18, 24),
    Surface = Color3.fromRGB(25, 25, 35),
    SurfaceLight = Color3.fromRGB(35, 35, 50),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 190),
    Border = Color3.fromRGB(50, 50, 70),
    Accent = Color3.fromRGB(255, 73, 130),
    Gradient1 = Color3.fromRGB(138, 43, 226),
    Gradient2 = Color3.fromRGB(72, 61, 139)
}

-- Responsive Sizes (Auto-adjust based on platform)
UI.Sizes = {}

if BaoSaveInstance.Platform.IsMobile then
    if BaoSaveInstance.Platform.Orientation == "Portrait" then
        -- Mobile Portrait
        UI.Sizes = {
            WindowWidth = 380,
            WindowHeight = 650,
            HeaderHeight = 70,
            SidebarWidth = 0, -- Hidden on mobile
            ButtonHeight = 55,
            FontTitle = 18,
            FontSubtitle = 12,
            FontButton = 15,
            FontLog = 11,
            CornerRadius = 12,
            Padding = 10,
            MinTouchSize = 50 -- Minimum touch target size
        }
    else
        -- Mobile Landscape
        UI.Sizes = {
            WindowWidth = 650,
            WindowHeight = 380,
            HeaderHeight = 60,
            SidebarWidth = 0,
            ButtonHeight = 50,
            FontTitle = 16,
            FontSubtitle = 11,
            FontButton = 14,
            FontLog = 10,
            CornerRadius = 10,
            Padding = 8,
            MinTouchSize = 45
        }
    end
elseif BaoSaveInstance.Platform.IsTablet then
    -- Tablet
    UI.Sizes = {
        WindowWidth = 900,
        WindowHeight = 650,
        HeaderHeight = 75,
        SidebarWidth = 200,
        ButtonHeight = 55,
        FontTitle = 22,
        FontSubtitle = 14,
        FontButton = 16,
        FontLog = 12,
        CornerRadius = 14,
        Padding = 12,
        MinTouchSize = 50
    }
else
    -- PC/Laptop
    UI.Sizes = {
        WindowWidth = 1200,
        WindowHeight = 750,
        HeaderHeight = 80,
        SidebarWidth = 220,
        ButtonHeight = 50,
        FontTitle = 24,
        FontSubtitle = 14,
        FontButton = 16,
        FontLog = 12,
        CornerRadius = 16,
        Padding = 15,
        MinTouchSize = 0
    }
end

-- Create Main UI
function UI:Create()
    local self = {
        Elements = {},
        Tabs = {},
        CurrentTab = nil,
        Animations = {},
        MobileMode = BaoSaveInstance.Platform.IsMobile
    }
    
    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BaoSaveInstanceUniversal"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999999
    ScreenGui.IgnoreGuiInset = true
    
    -- Main Container
    local MainContainer = Instance.new("Frame")
    MainContainer.Name = "MainContainer"
    MainContainer.Size = UDim2.new(0, UI.Sizes.WindowWidth, 0, UI.Sizes.WindowHeight)
    MainContainer.Position = UDim2.new(0.5, -UI.Sizes.WindowWidth/2, 0.5, -UI.Sizes.WindowHeight/2)
    MainContainer.BackgroundColor3 = UI.Colors.Background
    MainContainer.BorderSizePixel = 0
    MainContainer.ClipsDescendants = true
    MainContainer.Parent = ScreenGui
    
    -- Rounded corners
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius)
    Corner.Parent = MainContainer
    
    -- Animated Border (Disabled on mobile for performance)
    if not BaoSaveInstance.Platform.IsMobile then
        local Border = Instance.new("Frame")
        Border.Name = "Border"
        Border.Size = UDim2.new(1, 4, 1, 4)
        Border.Position = UDim2.new(0, -2, 0, -2)
        Border.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Border.BorderSizePixel = 0
        Border.ZIndex = 0
        Border.Parent = MainContainer
        
        local BorderCorner = Instance.new("UICorner")
        BorderCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius)
        BorderCorner.Parent = Border
        
        local BorderGradient = Instance.new("UIGradient")
        BorderGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, UI.Colors.Gradient1),
            ColorSequenceKeypoint.new(0.5, UI.Colors.Primary),
            ColorSequenceKeypoint.new(1, UI.Colors.Gradient2)
        }
        BorderGradient.Rotation = 45
        BorderGradient.Parent = Border
        
        -- Animate border
        task.spawn(function()
            while Border and Border.Parent do
                for i = 0, 360, 2 do
                    if not Border or not Border.Parent then break end
                    local gradient = Border:FindFirstChildOfClass("UIGradient")
                    if gradient then
                        gradient.Rotation = i
                    end
                    task.wait(0.05)
                end
            end
        end)
    end
    
    -- Header Section
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, UI.Sizes.HeaderHeight)
    Header.BackgroundColor3 = UI.Colors.Surface
    Header.BorderSizePixel = 0
    Header.Parent = MainContainer
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius)
    HeaderCorner.Parent = Header
    
    -- Header Gradient
    local HeaderGradient = Instance.new("UIGradient")
    HeaderGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, UI.Colors.Gradient1),
        ColorSequenceKeypoint.new(1, UI.Colors.Gradient2)
    }
    HeaderGradient.Rotation = 90
    HeaderGradient.Parent = Header
    
    -- Logo/Icon (Smaller on mobile)
    local logoSize = BaoSaveInstance.Platform.IsMobile and 40 or 50
    local Logo = Instance.new("ImageLabel")
    Logo.Name = "Logo"
    Logo.Size = UDim2.new(0, logoSize, 0, logoSize)
    Logo.Position = UDim2.new(0, UI.Sizes.Padding, 0, (UI.Sizes.HeaderHeight - logoSize) / 2)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://7733964640"
    Logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
    Logo.Parent = Header
    
    local LogoCorner = Instance.new("UICorner")
    LogoCorner.CornerRadius = UDim.new(0, 8)
    LogoCorner.Parent = Logo
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -logoSize - UI.Sizes.Padding * 3 - 50, 0, UI.Sizes.HeaderHeight * 0.5)
    Title.Position = UDim2.new(0, logoSize + UI.Sizes.Padding * 2, 0, UI.Sizes.HeaderHeight * 0.15)
    Title.BackgroundTransparency = 1
    Title.Text = BaoSaveInstance.Platform.IsMobile and "BAO SAVE v3.5" or "BAO SAVEINSTANCE v3.5 UNIVERSAL"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = UI.Sizes.FontTitle
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextScaled = BaoSaveInstance.Platform.IsMobile
    Title.Parent = Header
    
    -- Subtitle with platform info
    local platformEmoji = BaoSaveInstance.Platform.IsMobile and "📱" or "💻"
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Name = "Subtitle"
    Subtitle.Size = UDim2.new(1, -logoSize - UI.Sizes.Padding * 3 - 50, 0, UI.Sizes.HeaderHeight * 0.3)
    Subtitle.Position = UDim2.new(0, logoSize + UI.Sizes.Padding * 2, 0, UI.Sizes.HeaderHeight * 0.6)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = platformEmoji .. " " .. BaoSaveInstance.Platform.DeviceType .. " | " .. BaoSaveInstance.Executor.Name
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextSize = UI.Sizes.FontSubtitle
    Subtitle.TextColor3 = UI.Colors.TextSecondary
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.TextScaled = BaoSaveInstance.Platform.IsMobile
    Subtitle.Parent = Header
    
    -- Close Button
    local closeBtnSize = math.max(UI.Sizes.MinTouchSize, 40)
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, closeBtnSize, 0, closeBtnSize)
    CloseBtn.Position = UDim2.new(1, -closeBtnSize - UI.Sizes.Padding, 0, (UI.Sizes.HeaderHeight - closeBtnSize) / 2)
    CloseBtn.BackgroundColor3 = UI.Colors.Error
    CloseBtn.Text = "✕"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = BaoSaveInstance.Platform.IsMobile and 20 or 18
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = Header
    
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 10)
    CloseBtnCorner.Parent = CloseBtn
    
    -- Close button effects
    if not BaoSaveInstance.Platform.IsMobile then
        CloseBtn.MouseEnter:Connect(function()
            Services.TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(255, 50, 50),
                Size = UDim2.new(0, closeBtnSize + 5, 0, closeBtnSize + 5)
            }):Play()
        end)
        
        CloseBtn.MouseLeave:Connect(function()
            Services.TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = UI.Colors.Error,
                Size = UDim2.new(0, closeBtnSize, 0, closeBtnSize)
            }):Play()
        end)
    end
    
    CloseBtn.MouseButton1Click:Connect(function()
        Services.TweenService:Create(MainContainer, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        task.wait(0.3)
        ScreenGui:Destroy()
    end)
    
    -- Sidebar (Hidden on mobile, use bottom nav instead)
    local Sidebar
    if not BaoSaveInstance.Platform.IsMobile then
        Sidebar = Instance.new("Frame")
        Sidebar.Name = "Sidebar"
        Sidebar.Size = UDim2.new(0, UI.Sizes.SidebarWidth, 1, -UI.Sizes.HeaderHeight - UI.Sizes.Padding)
        Sidebar.Position = UDim2.new(0, UI.Sizes.Padding, 0, UI.Sizes.HeaderHeight + UI.Sizes.Padding)
        Sidebar.BackgroundColor3 = UI.Colors.Surface
        Sidebar.BorderSizePixel = 0
        Sidebar.Parent = MainContainer
        
        local SidebarCorner = Instance.new("UICorner")
        SidebarCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius - 4)
        SidebarCorner.Parent = Sidebar
    end
    
    -- Navigation Container (Sidebar for PC, Bottom nav for mobile)
    local NavContainer
    if BaoSaveInstance.Platform.IsMobile then
        -- Bottom Navigation for Mobile
        NavContainer = Instance.new("Frame")
        NavContainer.Name = "BottomNav"
        NavContainer.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 0, 70)
        NavContainer.Position = UDim2.new(0, UI.Sizes.Padding, 1, -80)
        NavContainer.BackgroundColor3 = UI.Colors.Surface
        NavContainer.BorderSizePixel = 0
        NavContainer.ZIndex = 10
        NavContainer.Parent = MainContainer
        
        local NavCorner = Instance.new("UICorner")
        NavCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius - 4)
        NavCorner.Parent = NavContainer
        
        local NavLayout = Instance.new("UIListLayout")
        NavLayout.FillDirection = Enum.FillDirection.Horizontal
        NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
        NavLayout.Padding = UDim.new(0, 5)
        NavLayout.Parent = NavContainer
    else
        -- Sidebar Navigation for PC
        NavContainer = Instance.new("Frame")
        NavContainer.Name = "NavContainer"
        NavContainer.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 1, -UI.Sizes.Padding * 2)
        NavContainer.Position = UDim2.new(0, UI.Sizes.Padding, 0, UI.Sizes.Padding)
        NavContainer.BackgroundTransparency = 1
        NavContainer.Parent = Sidebar
        
        local NavLayout = Instance.new("UIListLayout")
        NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
        NavLayout.Padding = UDim.new(0, 10)
        NavLayout.Parent = NavContainer
    end
    
    -- Function to create nav button (responsive)
    local function CreateNavButton(name, icon, order)
        local NavButton = Instance.new("TextButton")
        NavButton.Name = name
        
        if BaoSaveInstance.Platform.IsMobile then
            -- Mobile: Compact icon-only buttons
            NavButton.Size = UDim2.new(0, 60, 0, 60)
        else
            -- PC: Full-width buttons with text
            NavButton.Size = UDim2.new(1, 0, 0, UI.Sizes.ButtonHeight)
        end
        
        NavButton.BackgroundColor3 = UI.Colors.SurfaceLight
        NavButton.BorderSizePixel = 0
        NavButton.Text = ""
        NavButton.LayoutOrder = order
        NavButton.Parent = NavContainer
        
        local NavCorner = Instance.new("UICorner")
        NavCorner.CornerRadius = UDim.new(0, BaoSaveInstance.Platform.IsMobile and 30 or 10)
        NavCorner.Parent = NavButton
        
        local IconLabel = Instance.new("TextLabel")
        if BaoSaveInstance.Platform.IsMobile then
            IconLabel.Size = UDim2.new(1, 0, 1, 0)
            IconLabel.Position = UDim2.new(0, 0, 0, 0)
        else
            IconLabel.Size = UDim2.new(0, 30, 0, 30)
            IconLabel.Position = UDim2.new(0, 10, 0.5, -15)
        end
        IconLabel.BackgroundTransparency = 1
        IconLabel.Text = icon
        IconLabel.Font = Enum.Font.GothamBold
        IconLabel.TextSize = BaoSaveInstance.Platform.IsMobile and 24 or 20
        IconLabel.TextColor3 = UI.Colors.TextSecondary
        IconLabel.Parent = NavButton
        
        if not BaoSaveInstance.Platform.IsMobile then
            local TextLabel = Instance.new("TextLabel")
            TextLabel.Size = UDim2.new(1, -50, 1, 0)
            TextLabel.Position = UDim2.new(0, 50, 0, 0)
            TextLabel.BackgroundTransparency = 1
            TextLabel.Text = name
            TextLabel.Font = Enum.Font.GothamBold
            TextLabel.TextSize = UI.Sizes.FontButton
            TextLabel.TextColor3 = UI.Colors.TextSecondary
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.Parent = NavButton
        end
        
        -- Hover/Touch effects
        if not BaoSaveInstance.Platform.IsMobile then
            NavButton.MouseEnter:Connect(function()
                if self.CurrentTab ~= name then
                    Services.TweenService:Create(NavButton, TweenInfo.new(0.2), {
                        BackgroundColor3 = UI.Colors.Border
                    }):Play()
                end
            end)
            
            NavButton.MouseLeave:Connect(function()
                if self.CurrentTab ~= name then
                    Services.TweenService:Create(NavButton, TweenInfo.new(0.2), {
                        BackgroundColor3 = UI.Colors.SurfaceLight
                    }):Play()
                end
            end)
        end
        
        NavButton.MouseButton1Click:Connect(function()
            -- Visual feedback
            NavButton.BackgroundColor3 = UI.Colors.Primary
            task.wait(0.1)
            self:SwitchTab(name)
        end)
        
        return NavButton
    end
    
    -- Create navigation buttons (Fewer on mobile)
    if BaoSaveInstance.Platform.IsMobile then
        self.Tabs.Dashboard = CreateNavButton("Dashboard", "🏠", 1)
        self.Tabs.DecompileMap = CreateNavButton("Map", "🗺️", 2)
        self.Tabs.DecompileTerrain = CreateNavButton("Terrain", "🏔️", 3)
        self.Tabs.DecompileScripts = CreateNavButton("Scripts", "📜", 4)
        self.Tabs.Settings = CreateNavButton("Settings", "⚙️", 5)
    else
        self.Tabs.Dashboard = CreateNavButton("Dashboard", "🏠", 1)
        self.Tabs.DecompileMap = CreateNavButton("Decompile Map", "🗺️", 2)
        self.Tabs.DecompileTerrain = CreateNavButton("Terrain", "🏔️", 3)
        self.Tabs.DecompileScripts = CreateNavButton("Scripts", "📜", 4)
        self.Tabs.Settings = CreateNavButton("Settings", "⚙️", 5)
        self.Tabs.Analytics = CreateNavButton("Analytics", "📊", 6)
        self.Tabs.Plugins = CreateNavButton("Plugins", "🧩", 7)
    end
    
    -- Main Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    
    if BaoSaveInstance.Platform.IsMobile then
        ContentArea.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 1, -UI.Sizes.HeaderHeight - 90)
        ContentArea.Position = UDim2.new(0, UI.Sizes.Padding, 0, UI.Sizes.HeaderHeight + UI.Sizes.Padding)
    else
        ContentArea.Size = UDim2.new(1, -UI.Sizes.SidebarWidth - UI.Sizes.Padding * 3, 1, -UI.Sizes.HeaderHeight - UI.Sizes.Padding * 2)
        ContentArea.Position = UDim2.new(0, UI.Sizes.SidebarWidth + UI.Sizes.Padding * 2, 0, UI.Sizes.HeaderHeight + UI.Sizes.Padding)
    end
    
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainContainer
    
    self.Elements.ContentArea = ContentArea
    
    -- Create tab contents
    self:CreateDashboardTab()
    self:CreateDecompileMapTab()
    self:CreateTerrainTab()
    self:CreateScriptsTab()
    self:CreateSettingsTab()
    
    if not BaoSaveInstance.Platform.IsMobile then
        self:CreateAnalyticsTab()
        self:CreatePluginsTab()
    end
    
    -- Make draggable (Desktop only, use Header for mobile)
    if not BaoSaveInstance.Platform.IsMobile then
        local dragging, dragInput, dragStart, startPos
        
        local function update(input)
            local delta = input.Position - dragStart
            MainContainer.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
        
        Header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = MainContainer.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        Services.UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        
        Services.UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end)
    else
        -- Mobile: Add touch drag support
        local dragging = false
        local dragStart = nil
        local startPos = nil
        
        Header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = MainContainer.Position
            end
        end)
        
        Header.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch and dragging then
                local delta = input.Position - dragStart
                MainContainer.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        Header.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end
    
    self.ScreenGui = ScreenGui
    self.MainContainer = MainContainer
    
    -- Show dashboard by default
    self:SwitchTab(BaoSaveInstance.Platform.IsMobile and "Map" or "Dashboard")
    
    -- Entrance animation
    MainContainer.Size = UDim2.new(0, 0, 0, 0)
    MainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    Services.TweenService:Create(MainContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, UI.Sizes.WindowWidth, 0, UI.Sizes.WindowHeight),
        Position = UDim2.new(0.5, -UI.Sizes.WindowWidth/2, 0.5, -UI.Sizes.WindowHeight/2)
    }):Play()
    
    return self
end

-- Switch Tab Function
function UI:SwitchTab(tabName)
    for name, button in pairs(self.Tabs) do
        if name == tabName or (BaoSaveInstance.Platform.IsMobile and name:find(tabName)) then
            button.BackgroundColor3 = UI.Colors.Primary
            local icon = button:FindFirstChildOfClass("TextLabel")
            if icon then
                icon.TextColor3 = UI.Colors.Text
            end
            if not BaoSaveInstance.Platform.IsMobile then
                local textLabel = button:FindFirstChild("TextLabel")
                if textLabel and textLabel.Text ~= "" then
                    textLabel.TextColor3 = UI.Colors.Text
                end
            end
        else
            button.BackgroundColor3 = UI.Colors.SurfaceLight
            local icon = button:FindFirstChildOfClass("TextLabel")
            if icon then
                icon.TextColor3 = UI.Colors.TextSecondary
            end
            if not BaoSaveInstance.Platform.IsMobile then
                local textLabel = button:FindFirstChild("TextLabel")
                if textLabel and textLabel.Text ~= "" then
                    textLabel.TextColor3 = UI.Colors.TextSecondary
                end
            end
        end
    end
    
    for _, child in ipairs(self.Elements.ContentArea:GetChildren()) do
        if child:IsA("Frame") then
            child.Visible = false
        end
    end
    
    local searchName = BaoSaveInstance.Platform.IsMobile and tabName or (tabName .. "Content")
    for _, child in ipairs(self.Elements.ContentArea:GetChildren()) do
        if child:IsA("Frame") and (child.Name == searchName or child.Name:find(tabName)) then
            child.Visible = true
            break
        end
    end
    
    self.CurrentTab = tabName
end

-- Create Dashboard Tab (Simplified for mobile)
function UI:CreateDashboardTab()
    local DashboardContent = Instance.new("Frame")
    DashboardContent.Name = BaoSaveInstance.Platform.IsMobile and "Dashboard" or "DashboardContent"
    DashboardContent.Size = UDim2.new(1, 0, 1, 0)
    DashboardContent.BackgroundTransparency = 1
    DashboardContent.Visible = false
    DashboardContent.Parent = self.Elements.ContentArea
    
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = BaoSaveInstance.Platform.IsMobile and 3 or 6
    ScrollFrame.Parent = DashboardContent
    
    -- Welcome Card
    local WelcomeCard = Instance.new("Frame")
    WelcomeCard.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 0, BaoSaveInstance.Platform.IsMobile and 120 or 150)
    WelcomeCard.Position = UDim2.new(0, UI.Sizes.Padding, 0, UI.Sizes.Padding)
    WelcomeCard.BackgroundColor3 = UI.Colors.Surface
    WelcomeCard.BorderSizePixel = 0
    WelcomeCard.Parent = ScrollFrame
    
    local WelcomeCorner = Instance.new("UICorner")
    WelcomeCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius - 4)
    WelcomeCorner.Parent = WelcomeCard
    
    local WelcomeGradient = Instance.new("UIGradient")
    WelcomeGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, UI.Colors.Gradient1),
        ColorSequenceKeypoint.new(1, UI.Colors.Gradient2)
    }
    WelcomeGradient.Rotation = 45
    WelcomeGradient.Parent = WelcomeCard
    
    local WelcomeTitle = Instance.new("TextLabel")
    WelcomeTitle.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 0, 35)
    WelcomeTitle.Position = UDim2.new(0, UI.Sizes.Padding, 0, UI.Sizes.Padding)
    WelcomeTitle.BackgroundTransparency = 1
    WelcomeTitle.Text = BaoSaveInstance.Platform.IsMobile and "Welcome! 🎉" or "Welcome to Bao SaveInstance! 🎉"
    WelcomeTitle.Font = Enum.Font.GothamBold
    WelcomeTitle.TextSize = BaoSaveInstance.Platform.IsMobile and 18 or 24
    WelcomeTitle.TextColor3 = UI.Colors.Text
    WelcomeTitle.TextXAlignment = Enum.TextXAlignment.Left
    WelcomeTitle.TextScaled = BaoSaveInstance.Platform.IsMobile
    WelcomeTitle.Parent = WelcomeCard
    
    local WelcomeDesc = Instance.new("TextLabel")
    WelcomeDesc.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 1, -50)
    WelcomeDesc.Position = UDim2.new(0, UI.Sizes.Padding, 0, 45)
    WelcomeDesc.BackgroundTransparency = 1
    WelcomeDesc.Text = string.format(
        "Running on %s (%s)\nExecutor: %s\nUniversal compatibility enabled!",
        BaoSaveInstance.Platform.DeviceType,
        BaoSaveInstance.Platform.Orientation,
        BaoSaveInstance.Executor.Name
    )
    WelcomeDesc.Font = Enum.Font.Gotham
    WelcomeDesc.TextSize = BaoSaveInstance.Platform.IsMobile and 11 or 14
    WelcomeDesc.TextColor3 = UI.Colors.TextSecondary
    WelcomeDesc.TextXAlignment = Enum.TextXAlignment.Left
    WelcomeDesc.TextYAlignment = Enum.TextYAlignment.Top
    WelcomeDesc.TextWrapped = true
    WelcomeDesc.Parent = WelcomeCard
    
    -- Info Label
    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 0, 100)
    InfoLabel.Position = UDim2.new(0, UI.Sizes.Padding, 0, (BaoSaveInstance.Platform.IsMobile and 120 or 150) + UI.Sizes.Padding * 2)
    InfoLabel.BackgroundColor3 = UI.Colors.Surface
    InfoLabel.BorderSizePixel = 0
    InfoLabel.Text = BaoSaveInstance.Platform.IsMobile and "Use bottom nav to switch tabs\nTap Map to start!" or "Select a tab from the sidebar to begin decompiling"
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.TextSize = BaoSaveInstance.Platform.IsMobile and 13 or 16
    InfoLabel.TextColor3 = UI.Colors.Text
    InfoLabel.TextWrapped = true
    InfoLabel.Parent = ScrollFrame
    
    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius - 4)
    InfoCorner.Parent = InfoLabel
    
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, (BaoSaveInstance.Platform.IsMobile and 120 or 150) + 120)
end

-- Create Decompile Map Tab (Mobile-optimized)
function UI:CreateDecompileMapTab()
    local MapContent = Instance.new("Frame")
    MapContent.Name = BaoSaveInstance.Platform.IsMobile and "Map" or "Decompile MapContent"
    MapContent.Size = UDim2.new(1, 0, 1, 0)
    MapContent.BackgroundTransparency = 1
    MapContent.Visible = false
    MapContent.Parent = self.Elements.ContentArea
    
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = BaoSaveInstance.Platform.IsMobile and 3 or 6
    ScrollFrame.Parent = MapContent
    
    -- Big Start Button
    local StartButton = Instance.new("TextButton")
    StartButton.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 0, BaoSaveInstance.Platform.IsMobile and 70 : 80)
    StartButton.Position = UDim2.new(0, UI.Sizes.Padding, 0, UI.Sizes.Padding)
    StartButton.BackgroundColor3 = UI.Colors.Success
    StartButton.Text = ""
    StartButton.BorderSizePixel = 0
    StartButton.Parent = ScrollFrame
    
    local StartCorner = Instance.new("UICorner")
    StartCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius - 4)
    StartCorner.Parent = StartButton
    
    local StartGradient = Instance.new("UIGradient")
    StartGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, UI.Colors.Success),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 160, 100))
    }
    StartGradient.Rotation = 90
    StartGradient.Parent = StartButton
    
    local StartIcon = Instance.new("TextLabel")
    StartIcon.Size = UDim2.new(0, BaoSaveInstance.Platform.IsMobile and 40 or 50, 0, BaoSaveInstance.Platform.IsMobile and 40 or 50)
    StartIcon.Position = UDim2.new(0, UI.Sizes.Padding, 0.5, BaoSaveInstance.Platform.IsMobile and -20 or -25)
    StartIcon.BackgroundTransparency = 1
    StartIcon.Text = "🚀"
    StartIcon.Font = Enum.Font.GothamBold
    StartIcon.TextSize = BaoSaveInstance.Platform.IsMobile and 30 or 35
    StartIcon.Parent = StartButton
    
    local StartText = Instance.new("TextLabel")
    StartText.Size = UDim2.new(1, -70, 1, 0)
    StartText.Position = UDim2.new(0, 60, 0, 0)
    StartText.BackgroundTransparency = 1
    StartText.Text = BaoSaveInstance.Platform.IsMobile and "START DECOMPILING" or "START DECOMPILING MAP"
    StartText.Font = Enum.Font.GothamBold
    StartText.TextSize = BaoSaveInstance.Platform.IsMobile and 16 or 20
    StartText.TextColor3 = UI.Colors.Text
    StartText.TextXAlignment = Enum.TextXAlignment.Center
    StartText.TextScaled = BaoSaveInstance.Platform.IsMobile
    StartText.Parent = StartButton
    
    -- Progress Section
    local progressY = (BaoSaveInstance.Platform.IsMobile and 70 or 80) + UI.Sizes.Padding * 2
    local ProgressSection = Instance.new("Frame")
    ProgressSection.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 0, BaoSaveInstance.Platform.IsMobile and 100 : 120)
    ProgressSection.Position = UDim2.new(0, UI.Sizes.Padding, 0, progressY)
    ProgressSection.BackgroundColor3 = UI.Colors.Surface
    ProgressSection.BorderSizePixel = 0
    ProgressSection.Parent = ScrollFrame
    
    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius - 4)
    ProgressCorner.Parent = ProgressSection
    
    local ProgressTitle = Instance.new("TextLabel")
    ProgressTitle.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 0, 25)
    ProgressTitle.Position = UDim2.new(0, UI.Sizes.Padding, 0, UI.Sizes.Padding)
    ProgressTitle.BackgroundTransparency = 1
    ProgressTitle.Text = "Progress: Ready"
    ProgressTitle.Font = Enum.Font.GothamBold
    ProgressTitle.TextSize = BaoSaveInstance.Platform.IsMobile and 13 or 16
    ProgressTitle.TextColor3 = UI.Colors.Text
    ProgressTitle.TextXAlignment = Enum.TextXAlignment.Left
    ProgressTitle.TextScaled = BaoSaveInstance.Platform.IsMobile
    ProgressTitle.Parent = ProgressSection
    
    local ProgressBarBG = Instance.new("Frame")
    ProgressBarBG.Size = UDim2.new(1, -UI.Sizes.Padding * 4, 0, BaoSaveInstance.Platform.IsMobile and 30 : 35)
    ProgressBarBG.Position = UDim2.new(0, UI.Sizes.Padding * 2, 0, 40)
    ProgressBarBG.BackgroundColor3 = UI.Colors.Background
    ProgressBarBG.BorderSizePixel = 0
    ProgressBarBG.Parent = ProgressSection
    
    local ProgressBarCorner = Instance.new("UICorner")
    ProgressBarCorner.CornerRadius = UDim.new(0, 8)
    ProgressBarCorner.Parent = ProgressBarBG
    
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    ProgressBar.BackgroundColor3 = UI.Colors.Primary
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = ProgressBarBG
    
    local ProgressBarFillCorner = Instance.new("UICorner")
    ProgressBarFillCorner.CornerRadius = UDim.new(0, 8)
    ProgressBarFillCorner.Parent = ProgressBar
    
    local ProgressPercent = Instance.new("TextLabel")
    ProgressPercent.Size = UDim2.new(1, 0, 1, 0)
    ProgressPercent.BackgroundTransparency = 1
    ProgressPercent.Text = "0%"
    ProgressPercent.Font = Enum.Font.GothamBold
    ProgressPercent.TextSize = BaoSaveInstance.Platform.IsMobile and 14 or 16
    ProgressPercent.TextColor3 = UI.Colors.Text
    ProgressPercent.TextStrokeTransparency = 0.5
    ProgressPercent.Parent = ProgressBarBG
    
    self.Elements.MapProgressBar = ProgressBar
    self.Elements.MapProgressPercent = ProgressPercent
    self.Elements.MapProgressTitle = ProgressTitle
    
    -- Log Panel
    local logY = progressY + (BaoSaveInstance.Platform.IsMobile and 100 : 120) + UI.Sizes.Padding
    local LogPanel = Instance.new("Frame")
    LogPanel.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 0, BaoSaveInstance.Platform.IsMobile and 200 : 250)
    LogPanel.Position = UDim2.new(0, UI.Sizes.Padding, 0, logY)
    LogPanel.BackgroundColor3 = UI.Colors.Surface
    LogPanel.BorderSizePixel = 0
    LogPanel.Parent = ScrollFrame
    
    local LogCorner = Instance.new("UICorner")
    LogCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius - 4)
    LogCorner.Parent = LogPanel
    
    local LogTitle = Instance.new("TextLabel")
    LogTitle.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 0, 25)
    LogTitle.Position = UDim2.new(0, UI.Sizes.Padding, 0, UI.Sizes.Padding)
    LogTitle.BackgroundTransparency = 1
    LogTitle.Text = "📋 Console Log"
    LogTitle.Font = Enum.Font.GothamBold
    LogTitle.TextSize = BaoSaveInstance.Platform.IsMobile and 13 : 15
    LogTitle.TextColor3 = UI.Colors.Text
    LogTitle.TextXAlignment = Enum.TextXAlignment.Left
    LogTitle.TextScaled = BaoSaveInstance.Platform.IsMobile
    LogTitle.Parent = LogPanel
    
    local LogScroll = Instance.new("ScrollingFrame")
    LogScroll.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 1, -40)
    LogScroll.Position = UDim2.new(0, UI.Sizes.Padding, 0, 35)
    LogScroll.BackgroundColor3 = UI.Colors.Background
    LogScroll.BorderSizePixel = 0
    LogScroll.ScrollBarThickness = BaoSaveInstance.Platform.IsMobile and 2 : 4
    LogScroll.Parent = LogPanel
    
    local LogScrollCorner = Instance.new("UICorner")
    LogScrollCorner.CornerRadius = UDim.new(0, 6)
    LogScrollCorner.Parent = LogScroll
    
    local LogLayout = Instance.new("UIListLayout")
    LogLayout.Padding = UDim.new(0, 2)
    LogLayout.Parent = LogScroll
    
    self.Elements.MapLogScroll = LogScroll
    
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, logY + (BaoSaveInstance.Platform.IsMobile and 200 : 250) + UI.Sizes.Padding)
    
    -- Connect start button
    StartButton.MouseButton1Click:Connect(function()
        BaoSaveInstance.Modules.MapDecompiler:Start(self)
    end)
end

-- Create other tabs (simplified)
function UI:CreateTerrainTab()
    local TerrainContent = Instance.new("Frame")
    TerrainContent.Name = BaoSaveInstance.Platform.IsMobile and "Terrain" or "TerrainContent"
    TerrainContent.Size = UDim2.new(1, 0, 1, 0)
    TerrainContent.BackgroundTransparency = 1
    TerrainContent.Visible = false
    TerrainContent.Parent = self.Elements.ContentArea
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 1, -UI.Sizes.Padding * 2)
    Label.Position = UDim2.new(0, UI.Sizes.Padding, 0, UI.Sizes.Padding)
    Label.BackgroundColor3 = UI.Colors.Surface
    Label.Text = "🏔️ Terrain Decompiler\n\nComing soon!"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = BaoSaveInstance.Platform.IsMobile and 16 : 20
    Label.TextColor3 = UI.Colors.Text
    Label.TextWrapped = true
    Label.Parent = TerrainContent
    
    local LabelCorner = Instance.new("UICorner")
    LabelCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius - 4)
    LabelCorner.Parent = Label
end

function UI:CreateScriptsTab()
    local ScriptsContent = Instance.new("Frame")
    ScriptsContent.Name = BaoSaveInstance.Platform.IsMobile and "Scripts" or "ScriptsContent"
    ScriptsContent.Size = UDim2.new(1, 0, 1, 0)
    ScriptsContent.BackgroundTransparency = 1
    ScriptsContent.Visible = false
    ScriptsContent.Parent = self.Elements.ContentArea
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 1, -UI.Sizes.Padding * 2)
    Label.Position = UDim2.new(0, UI.Sizes.Padding, 0, UI.Sizes.Padding)
    Label.BackgroundColor3 = UI.Colors.Surface
    Label.Text = "📜 Script Decompiler\n\nComing soon!"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = BaoSaveInstance.Platform.IsMobile and 16 : 20
    Label.TextColor3 = UI.Colors.Text
    Label.TextWrapped = true
    Label.Parent = ScriptsContent
    
    local LabelCorner = Instance.new("UICorner")
    LabelCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius - 4)
    LabelCorner.Parent = Label
end

function UI:CreateSettingsTab()
    local SettingsContent = Instance.new("Frame")
    SettingsContent.Name = BaoSaveInstance.Platform.IsMobile and "Settings" or "SettingsContent"
    SettingsContent.Size = UDim2.new(1, 0, 1, 0)
    SettingsContent.BackgroundTransparency = 1
    SettingsContent.Visible = false
    SettingsContent.Parent = self.Elements.ContentArea
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 1, -UI.Sizes.Padding * 2)
    Label.Position = UDim2.new(0, UI.Sizes.Padding, 0, UI.Sizes.Padding)
    Label.BackgroundColor3 = UI.Colors.Surface
    Label.Text = "⚙️ Settings\n\nComing soon!"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = BaoSaveInstance.Platform.IsMobile and 16 : 20
    Label.TextColor3 = UI.Colors.Text
    Label.TextWrapped = true
    Label.Parent = SettingsContent
    
    local LabelCorner = Instance.new("UICorner")
    LabelCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius - 4)
    LabelCorner.Parent = Label
end

function UI:CreateAnalyticsTab()
    local AnalyticsContent = Instance.new("Frame")
    AnalyticsContent.Name = "AnalyticsContent"
    AnalyticsContent.Size = UDim2.new(1, 0, 1, 0)
    AnalyticsContent.BackgroundTransparency = 1
    AnalyticsContent.Visible = false
    AnalyticsContent.Parent = self.Elements.ContentArea
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 1, -UI.Sizes.Padding * 2)
    Label.Position = UDim2.new(0, UI.Sizes.Padding, 0, UI.Sizes.Padding)
    Label.BackgroundColor3 = UI.Colors.Surface
    Label.Text = "📊 Analytics\n\nComing soon!"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 20
    Label.TextColor3 = UI.Colors.Text
    Label.TextWrapped = true
    Label.Parent = AnalyticsContent
    
    local LabelCorner = Instance.new("UICorner")
    LabelCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius - 4)
    LabelCorner.Parent = Label
end

function UI:CreatePluginsTab()
    local PluginsContent = Instance.new("Frame")
    PluginsContent.Name = "PluginsContent"
    PluginsContent.Size = UDim2.new(1, 0, 1, 0)
    PluginsContent.BackgroundTransparency = 1
    PluginsContent.Visible = false
    PluginsContent.Parent = self.Elements.ContentArea
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -UI.Sizes.Padding * 2, 1, -UI.Sizes.Padding * 2)
    Label.Position = UDim2.new(0, UI.Sizes.Padding, 0, UI.Sizes.Padding)
    Label.BackgroundColor3 = UI.Colors.Surface
    Label.Text = "🧩 Plugins\n\nComing soon!"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 20
    Label.TextColor3 = UI.Colors.Text
    Label.TextWrapped = true
    Label.Parent = PluginsContent
    
    local LabelCorner = Instance.new("UICorner")
    LabelCorner.CornerRadius = UDim.new(0, UI.Sizes.CornerRadius - 4)
    LabelCorner.Parent = Label
end

-- Add Log Function
function UI:AddLog(text, color)
    if not self.Elements.MapLogScroll then return end
    
    local LogEntry = Instance.new("TextLabel")
    LogEntry.Size = UDim2.new(1, -5, 0, BaoSaveInstance.Platform.IsMobile and 18 : 20)
    LogEntry.BackgroundTransparency = 1
    LogEntry.Text = "[" .. os.date("%H:%M:%S") .. "] " .. text
    LogEntry.Font = Enum.Font.Code
    LogEntry.TextSize = UI.Sizes.FontLog
    LogEntry.TextColor3 = color or UI.Colors.TextSecondary
    LogEntry.TextXAlignment = Enum.TextXAlignment.Left
    LogEntry.TextScaled = BaoSaveInstance.Platform.IsMobile
    LogEntry.Parent = self.Elements.MapLogScroll
    
    self.Elements.MapLogScroll.CanvasSize = UDim2.new(0, 0, 0, self.Elements.MapLogScroll.UIListLayout.AbsoluteContentSize.Y)
    self.Elements.MapLogScroll.CanvasPosition = Vector2.new(0, self.Elements.MapLogScroll.CanvasSize.Y.Offset)
end

-- Update Progress
function UI:UpdateProgress(percent, text)
    if self.Elements.MapProgressBar then
        Services.TweenService:Create(self.Elements.MapProgressBar, TweenInfo.new(0.3), {
            Size = UDim2.new(percent, 0, 1, 0)
        }):Play()
    end
    
    if self.Elements.MapProgressPercent then
        self.Elements.MapProgressPercent.Text = math.floor(percent * 100) .. "%"
    end
    
    if self.Elements.MapProgressTitle and text then
        self.Elements.MapProgressTitle.Text = "Progress: " .. text
    end
end

-- ============================================================
--                    MAP DECOMPILER
-- ============================================================

BaoSaveInstance.Modules.MapDecompiler = {}
local MapDecompiler = BaoSaveInstance.Modules.MapDecompiler

MapDecompiler.Data = {
    Instances = {},
    Processed = 0,
    Total = 0,
    StartTime = 0
}

function MapDecompiler:Start(ui)
    ui:AddLog("=== STARTING MAP DECOMPILATION ===", UI.Colors.Success)
    ui:UpdateProgress(0, "Initializing...")
    
    self.Data.StartTime = tick()
    self.Data.Processed = 0
    self.Data.Instances = {}
    
    task.spawn(function()
        ui:AddLog("🔍 Scanning game...", UI.Colors.Primary)
        local allInstances = game:GetDescendants()
        self.Data.Total = #allInstances
        
        ui:AddLog("✅ Found " .. Util.FormatNumber(self.Data.Total) .. " instances", UI.Colors.Success)
        
        local threads = {}
        local chunkSize = math.ceil(self.Data.Total / BaoSaveInstance.Config.MaxThreads)
        
        for i = 1, BaoSaveInstance.Config.MaxThreads do
            local startIdx = (i - 1) * chunkSize + 1
            local endIdx = math.min(i * chunkSize, self.Data.Total)
            
            table.insert(threads, task.spawn(function()
                for j = startIdx, endIdx do
                    if allInstances[j] then
                        self:ProcessInstance(allInstances[j])
                    end
                    
                    self.Data.Processed = self.Data.Processed + 1
                    
                    if self.Data.Processed % 50 == 0 then
                        local progress = self.Data.Processed / self.Data.Total
                        ui:UpdateProgress(progress, string.format(
                            "%s/%s",
                            Util.FormatNumber(self.Data.Processed),
                            Util.FormatNumber(self.Data.Total)
                        ))
                    end
                    
                    if self.Data.Processed % 500 == 0 then
                        task.wait()
                    end
                end
            end))
        end
        
        for _, thread in ipairs(threads) do
            while coroutine.status(thread) ~= "dead" do
                task.wait(0.1)
            end
        end
        
        local elapsedTime = tick() - self.Data.StartTime
        ui:UpdateProgress(1, "Complete!")
        ui:AddLog(string.format("✅ Done in %.2fs", elapsedTime), UI.Colors.Success)
        ui:AddLog(string.format("📊 Processed %s", Util.FormatNumber(self.Data.Processed)), UI.Colors.Success)
        
        -- Export
        local success = self:Export()
        if success then
            ui:AddLog("💾 Exported successfully!", UI.Colors.Success)
        else
            ui:AddLog("⚠️ Export to clipboard", UI.Colors.Warning)
        end
    end)
end

function MapDecompiler:ProcessInstance(instance)
    local data = {
        ClassName = instance.ClassName,
        Name = instance.Name
    }
    table.insert(self.Data.Instances, data)
end

function MapDecompiler:Export()
    local jsonData = Services.HttpService:JSONEncode({
        Version = BaoSaveInstance.Version,
        Platform = BaoSaveInstance.Platform.DeviceType,
        Executor = BaoSaveInstance.Executor.Name,
        Data = self.Data.Instances
    })
    
    if UniversalCompat.Functions.writefile then
        local success, err = pcall(function()
            UniversalCompat.Functions.writefile("BaoSaveInstance_Export.json", jsonData)
        end)
        if success then return true end
    end
    
    UniversalCompat.Functions.setclipboard(jsonData)
    return false
end

-- ============================================================
--                    INITIALIZATION
-- ============================================================

function BaoSaveInstance:Init()
    print("╔═══════════════════════════════════════════════════════╗")
    print("║      BAO SAVEINSTANCE v3.5 UNIVERSAL EDITION         ║")
    print("╚═══════════════════════════════════════════════════════╝")
    print("")
    print("Platform: " .. self.Platform.DeviceType)
    print("Screen: " .. self.Platform.ScreenSize.X .. "x" .. self.Platform.ScreenSize.Y)
    print("Orientation: " .. self.Platform.Orientation)
    print("Executor: " .. self.Executor.Name)
    print("Mobile Mode: " .. tostring(self.Platform.IsMobile))
    print("")
    
    local ui = self.Modules.UI:Create()
    
    if UniversalCompat.Functions.gethui then
        ui.ScreenGui.Parent = UniversalCompat.Functions.gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(ui.ScreenGui)
        ui.ScreenGui.Parent = Services.CoreGui
    else
        ui.ScreenGui.Parent = Services.Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    print("✅ Loaded Successfully!")
end

-- ============================================================
--                    EXECUTE
-- ============================================================

BaoSaveInstance:Init()
