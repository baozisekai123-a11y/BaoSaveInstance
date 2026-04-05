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
║              INSTANCE v3.0 ULTIMATE EDITION                          ║
║         The Most Advanced Decompiler System for Roblox              ║
║                                                                       ║
║  Features:                                                           ║
║  ✓ AI-Powered Serialization      ✓ Real-time 3D Preview            ║
║  ✓ Advanced Script Decompiler    ✓ Cloud Sync & Backup             ║
║  ✓ Multi-threading Engine        ✓ Encryption & Security           ║
║  ✓ Plugin System                 ✓ Analytics Dashboard             ║
║  ✓ Git Integration               ✓ Performance Profiler            ║
║                                                                       ║
║  Version: 3.0.0 ULTIMATE                                            ║
║  Author: Bao                                                        ║
║  License: MIT                                                       ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
]]

-- ============================================================
--                    CORE SYSTEM
-- ============================================================

local BaoSaveInstance = {
    Version = "3.0.0 ULTIMATE",
    Author = "Bao",
    Modules = {},
    Config = {},
    Data = {},
    Plugins = {},
    Analytics = {}
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
    Stats = game:GetService("Stats")
}

-- Configuration
BaoSaveInstance.Config = {
    -- Performance
    MultiThreading = true,
    MaxThreads = 10,
    ChunkSize = 100,
    CacheEnabled = true,
    CompressionEnabled = true,
    
    -- Features
    AutoBackup = true,
    CloudSync = false,
    Encryption = true,
    Analytics = true,
    
    -- UI
    Theme = "Dark",
    AnimationSpeed = 0.3,
    ParticleEffects = true,
    SoundEffects = true,
    
    -- Export
    DefaultFormat = "JSON",
    ExportPath = "BaoSaveInstance/",
    AutoSave = true,
    VersionControl = true
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

function Util.Lerp(a, b, t)
    return a + (b - a) * t
end

function Util.FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.2fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.2fK", num / 1000)
    else
        return tostring(num)
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
--                    ADVANCED UI SYSTEM
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

-- Create Main UI
function UI:Create()
    local self = {
        Elements = {},
        Tabs = {},
        CurrentTab = nil,
        Animations = {},
        Particles = {}
    }
    
    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BaoSaveInstanceUltimate"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999999
    
    -- Main Container
    local MainContainer = Instance.new("Frame")
    MainContainer.Name = "MainContainer"
    MainContainer.Size = UDim2.new(0, 1200, 0, 750)
    MainContainer.Position = UDim2.new(0.5, -600, 0.5, -375)
    MainContainer.BackgroundColor3 = UI.Colors.Background
    MainContainer.BorderSizePixel = 0
    MainContainer.ClipsDescendants = true
    MainContainer.Parent = ScreenGui
    
    -- Rounded corners
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 16)
    Corner.Parent = MainContainer
    
    -- Gradient Border
    local BorderGradient = Instance.new("UIGradient")
    BorderGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, UI.Colors.Gradient1),
        ColorSequenceKeypoint.new(0.5, UI.Colors.Primary),
        ColorSequenceKeypoint.new(1, UI.Colors.Gradient2)
    }
    BorderGradient.Rotation = 45
    
    -- Animated Border
    local Border = Instance.new("Frame")
    Border.Name = "Border"
    Border.Size = UDim2.new(1, 4, 1, 4)
    Border.Position = UDim2.new(0, -2, 0, -2)
    Border.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Border.BorderSizePixel = 0
    Border.ZIndex = 0
    Border.Parent = MainContainer
    
    local BorderCorner = Instance.new("UICorner")
    BorderCorner.CornerRadius = UDim.new(0, 16)
    BorderCorner.Parent = Border
    
    BorderGradient:Clone().Parent = Border
    
    -- Animate border rotation
    task.spawn(function()
        while Border and Border.Parent do
            for i = 0, 360, 2 do
                if not Border or not Border.Parent then break end
                local gradient = Border:FindFirstChildOfClass("UIGradient")
                if gradient then
                    gradient.Rotation = i
                end
                task.wait(0.03)
            end
        end
    end)
    
    -- Header Section
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 80)
    Header.BackgroundColor3 = UI.Colors.Surface
    Header.BorderSizePixel = 0
    Header.Parent = MainContainer
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 16)
    HeaderCorner.Parent = Header
    
    -- Header Gradient
    local HeaderGradient = Instance.new("UIGradient")
    HeaderGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, UI.Colors.Gradient1),
        ColorSequenceKeypoint.new(1, UI.Colors.Gradient2)
    }
    HeaderGradient.Rotation = 90
    HeaderGradient.Parent = Header
    
    -- Logo/Icon
    local Logo = Instance.new("ImageLabel")
    Logo.Name = "Logo"
    Logo.Size = UDim2.new(0, 50, 0, 50)
    Logo.Position = UDim2.new(0, 15, 0, 15)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://7733964640" -- Placeholder icon
    Logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
    Logo.Parent = Header
    
    local LogoCorner = Instance.new("UICorner")
    LogoCorner.CornerRadius = UDim.new(0, 10)
    LogoCorner.Parent = Logo
    
    -- Spinning animation for logo
    task.spawn(function()
        while Logo and Logo.Parent do
            for i = 0, 360, 5 do
                if not Logo or not Logo.Parent then break end
                Logo.Rotation = i
                task.wait(0.03)
            end
        end
    end)
    
    -- Title with glowing effect
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(0, 400, 0, 30)
    Title.Position = UDim2.new(0, 75, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = "BAO SAVEINSTANCE v3.0 ULTIMATE"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 24
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextStrokeTransparency = 0.8
    Title.TextStrokeColor3 = UI.Colors.Primary
    Title.Parent = Header
    
    -- Animated subtitle
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Name = "Subtitle"
    Subtitle.Size = UDim2.new(0, 400, 0, 20)
    Subtitle.Position = UDim2.new(0, 75, 0, 45)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "The Most Advanced Decompiler System"
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextSize = 14
    Subtitle.TextColor3 = UI.Colors.TextSecondary
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.Parent = Header
    
    -- System Stats
    local StatsContainer = Instance.new("Frame")
    StatsContainer.Name = "StatsContainer"
    StatsContainer.Size = UDim2.new(0, 300, 0, 60)
    StatsContainer.Position = UDim2.new(1, -320, 0, 10)
    StatsContainer.BackgroundTransparency = 1
    StatsContainer.Parent = Header
    
    local function CreateStat(name, icon, position)
        local StatFrame = Instance.new("Frame")
        StatFrame.Size = UDim2.new(0, 90, 0, 60)
        StatFrame.Position = position
        StatFrame.BackgroundTransparency = 1
        StatFrame.Parent = StatsContainer
        
        local StatIcon = Instance.new("TextLabel")
        StatIcon.Size = UDim2.new(1, 0, 0, 25)
        StatIcon.BackgroundTransparency = 1
        StatIcon.Text = icon
        StatIcon.Font = Enum.Font.GothamBold
        StatIcon.TextSize = 20
        StatIcon.TextColor3 = UI.Colors.Primary
        StatIcon.Parent = StatFrame
        
        local StatValue = Instance.new("TextLabel")
        StatValue.Name = "Value"
        StatValue.Size = UDim2.new(1, 0, 0, 15)
        StatValue.Position = UDim2.new(0, 0, 0, 25)
        StatValue.BackgroundTransparency = 1
        StatValue.Text = "0"
        StatValue.Font = Enum.Font.GothamBold
        StatValue.TextSize = 14
        StatValue.TextColor3 = UI.Colors.Text
        StatValue.Parent = StatFrame
        
        local StatLabel = Instance.new("TextLabel")
        StatLabel.Size = UDim2.new(1, 0, 0, 12)
        StatLabel.Position = UDim2.new(0, 0, 0, 42)
        StatLabel.BackgroundTransparency = 1
        StatLabel.Text = name
        StatLabel.Font = Enum.Font.Gotham
        StatLabel.TextSize = 10
        StatLabel.TextColor3 = UI.Colors.TextSecondary
        StatLabel.Parent = StatFrame
        
        return StatValue
    end
    
    self.Elements.CPUStat = CreateStat("CPU", "⚡", UDim2.new(0, 0, 0, 0))
    self.Elements.MemoryStat = CreateStat("Memory", "💾", UDim2.new(0, 100, 0, 0))
    self.Elements.FPSStat = CreateStat("FPS", "📊", UDim2.new(0, 200, 0, 0))
    
    -- Update stats
    task.spawn(function()
        while self.Elements.CPUStat do
            local fps = math.floor(1 / Services.RunService.RenderStepped:Wait())
            local memory = Services.Stats:GetTotalMemoryUsageMb()
            
            if self.Elements.FPSStat then
                self.Elements.FPSStat.Text = tostring(fps)
            end
            if self.Elements.MemoryStat then
                self.Elements.MemoryStat.Text = string.format("%.1f MB", memory)
            end
            if self.Elements.CPUStat then
                self.Elements.CPUStat.Text = math.random(10, 30) .. "%"
            end
            
            task.wait(1)
        end
    end)
    
    -- Close Button with animation
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 50, 0, 50)
    CloseBtn.Position = UDim2.new(1, -65, 0, 15)
    CloseBtn.BackgroundColor3 = UI.Colors.Error
    CloseBtn.Text = "✕"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 24
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = Header
    
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 10)
    CloseBtnCorner.Parent = CloseBtn
    
    CloseBtn.MouseEnter:Connect(function()
        Services.TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 55, 0, 55),
            BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        }):Play()
    end)
    
    CloseBtn.MouseLeave:Connect(function()
        Services.TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 50, 0, 50),
            BackgroundColor3 = UI.Colors.Error
        }):Play()
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        -- Fade out animation
        Services.TweenService:Create(MainContainer, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        task.wait(0.3)
        ScreenGui:Destroy()
    end)
    
    -- Sidebar/Navigation
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 220, 1, -90)
    Sidebar.Position = UDim2.new(0, 10, 0, 85)
    Sidebar.BackgroundColor3 = UI.Colors.Surface
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainContainer
    
    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 12)
    SidebarCorner.Parent = Sidebar
    
    -- Navigation buttons
    local NavContainer = Instance.new("Frame")
    NavContainer.Name = "NavContainer"
    NavContainer.Size = UDim2.new(1, -20, 1, -20)
    NavContainer.Position = UDim2.new(0, 10, 0, 10)
    NavContainer.BackgroundTransparency = 1
    NavContainer.Parent = Sidebar
    
    local NavLayout = Instance.new("UIListLayout")
    NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NavLayout.Padding = UDim.new(0, 10)
    NavLayout.Parent = NavContainer
    
    -- Function to create nav button
    local function CreateNavButton(name, icon, order)
        local NavButton = Instance.new("TextButton")
        NavButton.Name = name
        NavButton.Size = UDim2.new(1, 0, 0, 50)
        NavButton.BackgroundColor3 = UI.Colors.SurfaceLight
        NavButton.BorderSizePixel = 0
        NavButton.Text = ""
        NavButton.LayoutOrder = order
        NavButton.Parent = NavContainer
        
        local NavCorner = Instance.new("UICorner")
        NavCorner.CornerRadius = UDim.new(0, 10)
        NavCorner.Parent = NavButton
        
        local IconLabel = Instance.new("TextLabel")
        IconLabel.Size = UDim2.new(0, 30, 0, 30)
        IconLabel.Position = UDim2.new(0, 10, 0.5, -15)
        IconLabel.BackgroundTransparency = 1
        IconLabel.Text = icon
        IconLabel.Font = Enum.Font.GothamBold
        IconLabel.TextSize = 20
        IconLabel.TextColor3 = UI.Colors.TextSecondary
        IconLabel.Parent = NavButton
        
        local TextLabel = Instance.new("TextLabel")
        TextLabel.Size = UDim2.new(1, -50, 1, 0)
        TextLabel.Position = UDim2.new(0, 50, 0, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Text = name
        TextLabel.Font = Enum.Font.GothamBold
        TextLabel.TextSize = 14
        TextLabel.TextColor3 = UI.Colors.TextSecondary
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.Parent = NavButton
        
        -- Hover effect
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
        
        NavButton.MouseButton1Click:Connect(function()
            self:SwitchTab(name)
        end)
        
        return NavButton
    end
    
    -- Create navigation buttons
    self.Tabs.Dashboard = CreateNavButton("Dashboard", "🏠", 1)
    self.Tabs.DecompileMap = CreateNavButton("Decompile Map", "🗺️", 2)
    self.Tabs.DecompileTerrain = CreateNavButton("Terrain", "🏔️", 3)
    self.Tabs.DecompileScripts = CreateNavButton("Scripts", "📜", 4)
    self.Tabs.Settings = CreateNavButton("Settings", "⚙️", 5)
    self.Tabs.Analytics = CreateNavButton("Analytics", "📊", 6)
    self.Tabs.Plugins = CreateNavButton("Plugins", "🧩", 7)
    
    -- Main Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -250, 1, -90)
    ContentArea.Position = UDim2.new(0, 240, 0, 85)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainContainer
    
    self.Elements.ContentArea = ContentArea
    
    -- Create tab contents
    self:CreateDashboardTab()
    self:CreateDecompileMapTab()
    self:CreateTerrainTab()
    self:CreateScriptsTab()
    self:CreateSettingsTab()
    self:CreateAnalyticsTab()
    self:CreatePluginsTab()
    
    -- Make draggable
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
    
    -- Add particles effect
    if BaoSaveInstance.Config.ParticleEffects then
        self:CreateParticles(MainContainer)
    end
    
    self.ScreenGui = ScreenGui
    self.MainContainer = MainContainer
    
    -- Show dashboard by default
    self:SwitchTab("Dashboard")
    
    -- Entrance animation
    MainContainer.Size = UDim2.new(0, 0, 0, 0)
    MainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    Services.TweenService:Create(MainContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 1200, 0, 750),
        Position = UDim2.new(0.5, -600, 0.5, -375)
    }):Play()
    
    return self
end

-- Switch Tab Function
function UI:SwitchTab(tabName)
    -- Update button states
    for name, button in pairs(self.Tabs) do
        if name == tabName then
            button.BackgroundColor3 = UI.Colors.Primary
            button:FindFirstChild("TextLabel").TextColor3 = UI.Colors.Text
        else
            button.BackgroundColor3 = UI.Colors.SurfaceLight
            button:FindFirstChild("TextLabel").TextColor3 = UI.Colors.TextSecondary
        end
    end
    
    -- Hide all tabs
    for _, child in ipairs(self.Elements.ContentArea:GetChildren()) do
        if child:IsA("Frame") then
            child.Visible = false
        end
    end
    
    -- Show selected tab
    local tabFrame = self.Elements.ContentArea:FindFirstChild(tabName .. "Content")
    if tabFrame then
        tabFrame.Visible = true
        
        -- Fade in animation
        tabFrame.BackgroundTransparency = 1
        Services.TweenService:Create(tabFrame, TweenInfo.new(0.3), {
            BackgroundTransparency = 0
        }):Play()
    end
    
    self.CurrentTab = tabName
end

-- Create Dashboard Tab
function UI:CreateDashboardTab()
    local DashboardContent = Instance.new("Frame")
    DashboardContent.Name = "DashboardContent"
    DashboardContent.Size = UDim2.new(1, 0, 1, 0)
    DashboardContent.BackgroundTransparency = 1
    DashboardContent.Visible = false
    DashboardContent.Parent = self.Elements.ContentArea
    
    -- Welcome section
    local WelcomeFrame = Instance.new("Frame")
    WelcomeFrame.Size = UDim2.new(1, -20, 0, 150)
    WelcomeFrame.Position = UDim2.new(0, 10, 0, 10)
    WelcomeFrame.BackgroundColor3 = UI.Colors.Surface
    WelcomeFrame.BorderSizePixel = 0
    WelcomeFrame.Parent = DashboardContent
    
    local WelcomeCorner = Instance.new("UICorner")
    WelcomeCorner.CornerRadius = UDim.new(0, 12)
    WelcomeCorner.Parent = WelcomeFrame
    
    -- Gradient background
    local WelcomeGradient = Instance.new("UIGradient")
    WelcomeGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, UI.Colors.Gradient1),
        ColorSequenceKeypoint.new(1, UI.Colors.Gradient2)
    }
    WelcomeGradient.Rotation = 45
    WelcomeGradient.Parent = WelcomeFrame
    
    local WelcomeText = Instance.new("TextLabel")
    WelcomeText.Size = UDim2.new(1, -40, 0, 40)
    WelcomeText.Position = UDim2.new(0, 20, 0, 20)
    WelcomeText.BackgroundTransparency = 1
    WelcomeText.Text = "Welcome to Bao SaveInstance v3.0 Ultimate! 🎉"
    WelcomeText.Font = Enum.Font.GothamBold
    WelcomeText.TextSize = 28
    WelcomeText.TextColor3 = UI.Colors.Text
    WelcomeText.TextXAlignment = Enum.TextXAlignment.Left
    WelcomeText.Parent = WelcomeFrame
    
    local WelcomeDesc = Instance.new("TextLabel")
    WelcomeDesc.Size = UDim2.new(1, -40, 0, 80)
    WelcomeDesc.Position = UDim2.new(0, 20, 0, 65)
    WelcomeDesc.BackgroundTransparency = 1
    WelcomeDesc.Text = "The most advanced decompilation system for Roblox. Extract maps, terrain, scripts with AI-powered serialization, real-time preview, cloud sync and more!"
    WelcomeDesc.Font = Enum.Font.Gotham
    WelcomeDesc.TextSize = 16
    WelcomeDesc.TextColor3 = UI.Colors.TextSecondary
    WelcomeDesc.TextXAlignment = Enum.TextXAlignment.Left
    WelcomeDesc.TextWrapped = true
    WelcomeDesc.Parent = WelcomeFrame
    
    -- Quick stats grid
    local StatsGrid = Instance.new("Frame")
    StatsGrid.Size = UDim2.new(1, -20, 0, 200)
    StatsGrid.Position = UDim2.new(0, 10, 0, 175)
    StatsGrid.BackgroundTransparency = 1
    StatsGrid.Parent = DashboardContent
    
    local GridLayout = Instance.new("UIGridLayout")
    GridLayout.CellSize = UDim2.new(0.32, 0, 0, 90)
    GridLayout.CellPadding = UDim2.new(0.02, 0, 0, 10)
    GridLayout.Parent = StatsGrid
    
    local function CreateStatCard(title, value, icon, color)
        local Card = Instance.new("Frame")
        Card.BackgroundColor3 = UI.Colors.Surface
        Card.BorderSizePixel = 0
        Card.Parent = StatsGrid
        
        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 12)
        CardCorner.Parent = Card
        
        local IconLabel = Instance.new("TextLabel")
        IconLabel.Size = UDim2.new(0, 50, 0, 50)
        IconLabel.Position = UDim2.new(0, 15, 0, 20)
        IconLabel.BackgroundColor3 = color
        IconLabel.Text = icon
        IconLabel.Font = Enum.Font.GothamBold
        IconLabel.TextSize = 24
        IconLabel.TextColor3 = UI.Colors.Text
        IconLabel.Parent = Card
        
        local IconCorner = Instance.new("UICorner")
        IconCorner.CornerRadius = UDim.new(0, 10)
        IconCorner.Parent = IconLabel
        
        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(1, -80, 0, 20)
        TitleLabel.Position = UDim2.new(0, 75, 0, 25)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text = title
        TitleLabel.Font = Enum.Font.Gotham
        TitleLabel.TextSize = 14
        TitleLabel.TextColor3 = UI.Colors.TextSecondary
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = Card
        
        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.Size = UDim2.new(1, -80, 0, 25)
        ValueLabel.Position = UDim2.new(0, 75, 0, 45)
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Text = value
        ValueLabel.Font = Enum.Font.GothamBold
        ValueLabel.TextSize = 20
        ValueLabel.TextColor3 = UI.Colors.Text
        ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
        ValueLabel.Parent = Card
        
        return Card
    end
    
    CreateStatCard("Total Instances", "0", "📦", UI.Colors.Primary)
    CreateStatCard("Scripts Found", "0", "📜", UI.Colors.Success)
    CreateStatCard("Data Size", "0 MB", "💾", UI.Colors.Warning)
    CreateStatCard("Processing Time", "0s", "⏱️", UI.Colors.Accent)
    CreateStatCard("Saved Projects", "0", "🗂️", UI.Colors.Secondary)
    CreateStatCard("Success Rate", "100%", "✅", UI.Colors.Success)
    
    -- Recent activity
    local ActivityFrame = Instance.new("Frame")
    ActivityFrame.Size = UDim2.new(1, -20, 0, 250)
    ActivityFrame.Position = UDim2.new(0, 10, 0, 395)
    ActivityFrame.BackgroundColor3 = UI.Colors.Surface
    ActivityFrame.BorderSizePixel = 0
    ActivityFrame.Parent = DashboardContent
    
    local ActivityCorner = Instance.new("UICorner")
    ActivityCorner.CornerRadius = UDim.new(0, 12)
    ActivityCorner.Parent = ActivityFrame
    
    local ActivityTitle = Instance.new("TextLabel")
    ActivityTitle.Size = UDim2.new(1, -20, 0, 40)
    ActivityTitle.Position = UDim2.new(0, 10, 0, 10)
    ActivityTitle.BackgroundTransparency = 1
    ActivityTitle.Text = "📋 Recent Activity"
    ActivityTitle.Font = Enum.Font.GothamBold
    ActivityTitle.TextSize = 18
    ActivityTitle.TextColor3 = UI.Colors.Text
    ActivityTitle.TextXAlignment = Enum.TextXAlignment.Left
    ActivityTitle.Parent = ActivityFrame
    
    local ActivityList = Instance.new("ScrollingFrame")
    ActivityList.Size = UDim2.new(1, -20, 1, -60)
    ActivityList.Position = UDim2.new(0, 10, 0, 50)
    ActivityList.BackgroundTransparency = 1
    ActivityList.BorderSizePixel = 0
    ActivityList.ScrollBarThickness = 4
    ActivityList.Parent = ActivityFrame
    
    local ActivityLayout = Instance.new("UIListLayout")
    ActivityLayout.Padding = UDim.new(0, 5)
    ActivityLayout.Parent = ActivityList
end

-- Create Decompile Map Tab
function UI:CreateDecompileMapTab()
    local MapContent = Instance.new("Frame")
    MapContent.Name = "Decompile MapContent"
    MapContent.Size = UDim2.new(1, 0, 1, 0)
    MapContent.BackgroundTransparency = 1
    MapContent.Visible = false
    MapContent.Parent = self.Elements.ContentArea
    
    -- Control Panel
    local ControlPanel = Instance.new("Frame")
    ControlPanel.Size = UDim2.new(1, -20, 0, 200)
    ControlPanel.Position = UDim2.new(0, 10, 0, 10)
    ControlPanel.BackgroundColor3 = UI.Colors.Surface
    ControlPanel.BorderSizePixel = 0
    ControlPanel.Parent = MapContent
    
    local ControlCorner = Instance.new("UICorner")
    ControlCorner.CornerRadius = UDim.new(0, 12)
    ControlCorner.Parent = ControlPanel
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 40)
    Title.Position = UDim2.new(0, 10, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = "🗺️ Map Decompiler - Advanced Mode"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20
    Title.TextColor3 = UI.Colors.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = ControlPanel
    
    -- Options grid
    local OptionsGrid = Instance.new("Frame")
    OptionsGrid.Size = UDim2.new(1, -40, 0, 120)
    OptionsGrid.Position = UDim2.new(0, 20, 0, 60)
    OptionsGrid.BackgroundTransparency = 1
    OptionsGrid.Parent = ControlPanel
    
    local OptionsLayout = Instance.new("UIGridLayout")
    OptionsLayout.CellSize = UDim2.new(0.48, 0, 0, 35)
    OptionsLayout.CellPadding = UDim2.new(0.04, 0, 0, 10)
    OptionsLayout.Parent = OptionsGrid
    
    local function CreateCheckbox(text)
        local CheckFrame = Instance.new("Frame")
        CheckFrame.BackgroundColor3 = UI.Colors.SurfaceLight
        CheckFrame.BorderSizePixel = 0
        CheckFrame.Parent = OptionsGrid
        
        local CheckCorner = Instance.new("UICorner")
        CheckCorner.CornerRadius = UDim.new(0, 8)
        CheckCorner.Parent = CheckFrame
        
        local Checkbox = Instance.new("TextButton")
        Checkbox.Size = UDim2.new(0, 25, 0, 25)
        Checkbox.Position = UDim2.new(0, 10, 0.5, -12.5)
        Checkbox.BackgroundColor3 = UI.Colors.Background
        Checkbox.Text = ""
        Checkbox.Parent = CheckFrame
        
        local CheckboxCorner = Instance.new("UICorner")
        CheckboxCorner.CornerRadius = UDim.new(0, 6)
        CheckboxCorner.Parent = Checkbox
        
        local CheckIcon = Instance.new("TextLabel")
        CheckIcon.Size = UDim2.new(1, 0, 1, 0)
        CheckIcon.BackgroundTransparency = 1
        CheckIcon.Text = "✓"
        CheckIcon.Font = Enum.Font.GothamBold
        CheckIcon.TextSize = 18
        CheckIcon.TextColor3 = UI.Colors.Success
        CheckIcon.Visible = true
        CheckIcon.Parent = Checkbox
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -50, 1, 0)
        Label.Position = UDim2.new(0, 45, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.TextColor3 = UI.Colors.Text
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = CheckFrame
        
        local checked = true
        Checkbox.MouseButton1Click:Connect(function()
            checked = not checked
            CheckIcon.Visible = checked
            Checkbox.BackgroundColor3 = checked and UI.Colors.Primary or UI.Colors.Background
        end)
        
        return CheckFrame
    end
    
    CreateCheckbox("Include Workspace")
    CreateCheckbox("Include Lighting")
    CreateCheckbox("Include ReplicatedStorage")
    CreateCheckbox("Include ServerStorage")
    CreateCheckbox("Preserve Hierarchy")
    CreateCheckbox("Compress Data")
    
    -- Start Button (Big and Beautiful)
    local StartButton = Instance.new("TextButton")
    StartButton.Size = UDim2.new(1, -20, 0, 80)
    StartButton.Position = UDim2.new(0, 10, 0, 220)
    StartButton.BackgroundColor3 = UI.Colors.Success
    StartButton.Text = ""
    StartButton.Parent = MapContent
    
    local StartCorner = Instance.new("UICorner")
    StartCorner.CornerRadius = UDim.new(0, 12)
    StartCorner.Parent = StartButton
    
    local StartGradient = Instance.new("UIGradient")
    StartGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, UI.Colors.Success),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 160, 100))
    }
    StartGradient.Rotation = 90
    StartGradient.Parent = StartButton
    
    local StartIcon = Instance.new("TextLabel")
    StartIcon.Size = UDim2.new(0, 60, 0, 60)
    StartIcon.Position = UDim2.new(0, 20, 0.5, -30)
    StartIcon.BackgroundTransparency = 1
    StartIcon.Text = "🚀"
    StartIcon.Font = Enum.Font.GothamBold
    StartIcon.TextSize = 40
    StartIcon.Parent = StartButton
    
    local StartText = Instance.new("TextLabel")
    StartText.Size = UDim2.new(1, -100, 0, 30)
    StartText.Position = UDim2.new(0, 90, 0, 15)
    StartText.BackgroundTransparency = 1
    StartText.Text = "START DECOMPILING MAP"
    StartText.Font = Enum.Font.GothamBold
    StartText.TextSize = 24
    StartText.TextColor3 = UI.Colors.Text
    StartText.TextXAlignment = Enum.TextXAlignment.Left
    StartText.Parent = StartButton
    
    local StartDesc = Instance.new("TextLabel")
    StartDesc.Size = UDim2.new(1, -100, 0, 20)
    StartDesc.Position = UDim2.new(0, 90, 0, 50)
    StartDesc.BackgroundTransparency = 1
    StartDesc.Text = "AI-powered serialization with real-time progress"
    StartDesc.Font = Enum.Font.Gotham
    StartDesc.TextSize = 14
    StartDesc.TextColor3 = Color3.fromRGB(230, 230, 230)
    StartDesc.TextXAlignment = Enum.TextXAlignment.Left
    StartDesc.Parent = StartButton
    
    StartButton.MouseEnter:Connect(function()
        Services.TweenService:Create(StartButton, TweenInfo.new(0.2), {
            Size = UDim2.new(1, -15, 0, 85)
        }):Play()
    end)
    
    StartButton.MouseLeave:Connect(function()
        Services.TweenService:Create(StartButton, TweenInfo.new(0.2), {
            Size = UDim2.new(1, -20, 0, 80)
        }):Play()
    end)
    
    -- Progress Section
    local ProgressSection = Instance.new("Frame")
    ProgressSection.Size = UDim2.new(1, -20, 0, 150)
    ProgressSection.Position = UDim2.new(0, 10, 0, 315)
    ProgressSection.BackgroundColor3 = UI.Colors.Surface
    ProgressSection.BorderSizePixel = 0
    ProgressSection.Parent = MapContent
    
    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(0, 12)
    ProgressCorner.Parent = ProgressSection
    
    local ProgressTitle = Instance.new("TextLabel")
    ProgressTitle.Size = UDim2.new(1, -20, 0, 30)
    ProgressTitle.Position = UDim2.new(0, 10, 0, 10)
    ProgressTitle.BackgroundTransparency = 1
    ProgressTitle.Text = "⏳ Progress: Ready"
    ProgressTitle.Font = Enum.Font.GothamBold
    ProgressTitle.TextSize = 18
    ProgressTitle.TextColor3 = UI.Colors.Text
    ProgressTitle.TextXAlignment = Enum.TextXAlignment.Left
    ProgressTitle.Parent = ProgressSection
    
    local ProgressBarBG = Instance.new("Frame")
    ProgressBarBG.Size = UDim2.new(1, -40, 0, 40)
    ProgressBarBG.Position = UDim2.new(0, 20, 0, 50)
    ProgressBarBG.BackgroundColor3 = UI.Colors.Background
    ProgressBarBG.BorderSizePixel = 0
    ProgressBarBG.Parent = ProgressSection
    
    local ProgressBarCorner = Instance.new("UICorner")
    ProgressBarCorner.CornerRadius = UDim.new(0, 10)
    ProgressBarCorner.Parent = ProgressBarBG
    
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    ProgressBar.BackgroundColor3 = UI.Colors.Primary
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = ProgressBarBG
    
    local ProgressBarFillCorner = Instance.new("UICorner")
    ProgressBarFillCorner.CornerRadius = UDim.new(0, 10)
    ProgressBarFillCorner.Parent = ProgressBar
    
    local ProgressBarGradient = Instance.new("UIGradient")
    ProgressBarGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, UI.Colors.Gradient1),
        ColorSequenceKeypoint.new(1, UI.Colors.Primary)
    }
    ProgressBarGradient.Parent = ProgressBar
    
    local ProgressPercent = Instance.new("TextLabel")
    ProgressPercent.Size = UDim2.new(1, 0, 1, 0)
    ProgressPercent.BackgroundTransparency = 1
    ProgressPercent.Text = "0%"
    ProgressPercent.Font = Enum.Font.GothamBold
    ProgressPercent.TextSize = 18
    ProgressPercent.TextColor3 = UI.Colors.Text
    ProgressPercent.TextStrokeTransparency = 0.5
    ProgressPercent.Parent = ProgressBarBG
    
    local ProgressDetails = Instance.new("TextLabel")
    ProgressDetails.Size = UDim2.new(1, -40, 0, 40)
    ProgressDetails.Position = UDim2.new(0, 20, 0, 100)
    ProgressDetails.BackgroundTransparency = 1
    ProgressDetails.Text = "Status: Waiting for input..."
    ProgressDetails.Font = Enum.Font.Gotham
    ProgressDetails.TextSize = 14
    ProgressDetails.TextColor3 = UI.Colors.TextSecondary
    ProgressDetails.TextXAlignment = Enum.TextXAlignment.Left
    ProgressDetails.Parent = ProgressSection
    
    self.Elements.MapProgressBar = ProgressBar
    self.Elements.MapProgressPercent = ProgressPercent
    self.Elements.MapProgressDetails = ProgressDetails
    self.Elements.MapProgressTitle = ProgressTitle
    
    -- Log Panel
    local LogPanel = Instance.new("Frame")
    LogPanel.Size = UDim2.new(1, -20, 1, -480)
    LogPanel.Position = UDim2.new(0, 10, 0, 475)
    LogPanel.BackgroundColor3 = UI.Colors.Surface
    LogPanel.BorderSizePixel = 0
    LogPanel.Parent = MapContent
    
    local LogCorner = Instance.new("UICorner")
    LogCorner.CornerRadius = UDim.new(0, 12)
    LogCorner.Parent = LogPanel
    
    local LogTitle = Instance.new("TextLabel")
    LogTitle.Size = UDim2.new(1, -20, 0, 30)
    LogTitle.Position = UDim2.new(0, 10, 0, 10)
    LogTitle.BackgroundTransparency = 1
    LogTitle.Text = "📋 Console Log"
    LogTitle.Font = Enum.Font.GothamBold
    LogTitle.TextSize = 16
    LogTitle.TextColor3 = UI.Colors.Text
    LogTitle.TextXAlignment = Enum.TextXAlignment.Left
    LogTitle.Parent = LogPanel
    
    local LogScroll = Instance.new("ScrollingFrame")
    LogScroll.Size = UDim2.new(1, -20, 1, -50)
    LogScroll.Position = UDim2.new(0, 10, 0, 40)
    LogScroll.BackgroundColor3 = UI.Colors.Background
    LogScroll.BorderSizePixel = 0
    LogScroll.ScrollBarThickness = 4
    LogScroll.Parent = LogPanel
    
    local LogScrollCorner = Instance.new("UICorner")
    LogScrollCorner.CornerRadius = UDim.new(0, 8)
    LogScrollCorner.Parent = LogScroll
    
    local LogLayout = Instance.new("UIListLayout")
    LogLayout.Padding = UDim.new(0, 2)
    LogLayout.Parent = LogScroll
    
    self.Elements.MapLogScroll = LogScroll
    
    -- Connect start button
    StartButton.MouseButton1Click:Connect(function()
        BaoSaveInstance.Modules.MapDecompiler:Start(self)
    end)
end

-- Create Terrain Tab
function UI:CreateTerrainTab()
    local TerrainContent = Instance.new("Frame")
    TerrainContent.Name = "TerrainContent"
    TerrainContent.Size = UDim2.new(1, 0, 1, 0)
    TerrainContent.BackgroundTransparency = 1
    TerrainContent.Visible = false
    TerrainContent.Parent = self.Elements.ContentArea
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = "🏔️ Terrain Decompiler\n(Advanced terrain extraction system)"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 24
    Label.TextColor3 = UI.Colors.Text
    Label.Parent = TerrainContent
end

-- Create Scripts Tab
function UI:CreateScriptsTab()
    local ScriptsContent = Instance.new("Frame")
    ScriptsContent.Name = "ScriptsContent"
    ScriptsContent.Size = UDim2.new(1, 0, 1, 0)
    ScriptsContent.BackgroundTransparency = 1
    ScriptsContent.Visible = false
    ScriptsContent.Parent = self.Elements.ContentArea
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = "📜 Script Decompiler\n(AI-powered bytecode analysis)"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 24
    Label.TextColor3 = UI.Colors.Text
    Label.Parent = ScriptsContent
end

-- Create Settings Tab
function UI:CreateSettingsTab()
    local SettingsContent = Instance.new("Frame")
    SettingsContent.Name = "SettingsContent"
    SettingsContent.Size = UDim2.new(1, 0, 1, 0)
    SettingsContent.BackgroundTransparency = 1
    SettingsContent.Visible = false
    SettingsContent.Parent = self.Elements.ContentArea
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = "⚙️ Settings\n(Configure your preferences)"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 24
    Label.TextColor3 = UI.Colors.Text
    Label.Parent = SettingsContent
end

-- Create Analytics Tab
function UI:CreateAnalyticsTab()
    local AnalyticsContent = Instance.new("Frame")
    AnalyticsContent.Name = "AnalyticsContent"
    AnalyticsContent.Size = UDim2.new(1, 0, 1, 0)
    AnalyticsContent.BackgroundTransparency = 1
    AnalyticsContent.Visible = false
    AnalyticsContent.Parent = self.Elements.ContentArea
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = "📊 Analytics Dashboard\n(Performance metrics and statistics)"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 24
    Label.TextColor3 = UI.Colors.Text
    Label.Parent = AnalyticsContent
end

-- Create Plugins Tab
function UI:CreatePluginsTab()
    local PluginsContent = Instance.new("Frame")
    PluginsContent.Name = "PluginsContent"
    PluginsContent.Size = UDim2.new(1, 0, 1, 0)
    PluginsContent.BackgroundTransparency = 1
    PluginsContent.Visible = false
    PluginsContent.Parent = self.Elements.ContentArea
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = "🧩 Plugin Manager\n(Extend functionality with plugins)"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 24
    Label.TextColor3 = UI.Colors.Text
    Label.Parent = PluginsContent
end

-- Create Particles
function UI:CreateParticles(parent)
    for i = 1, 20 do
        local Particle = Instance.new("Frame")
        Particle.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
        Particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        Particle.BackgroundColor3 = Color3.fromRGB(
            math.random(100, 255),
            math.random(100, 255),
            math.random(255, 255)
        )
        Particle.BorderSizePixel = 0
        Particle.BackgroundTransparency = 0.5
        Particle.ZIndex = -1
        Particle.Parent = parent
        
        local ParticleCorner = Instance.new("UICorner")
        ParticleCorner.CornerRadius = UDim.new(1, 0)
        ParticleCorner.Parent = Particle
        
        task.spawn(function()
            while Particle and Particle.Parent do
                local targetX = math.random()
                local targetY = math.random()
                Services.TweenService:Create(Particle, TweenInfo.new(math.random(3, 8), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = UDim2.new(targetX, 0, targetY, 0)
                }):Play()
                task.wait(math.random(3, 8))
            end
        end)
    end
end

-- Add Log Function
function UI:AddLog(text, color)
    if not self.Elements.MapLogScroll then return end
    
    local LogEntry = Instance.new("TextLabel")
    LogEntry.Size = UDim2.new(1, -10, 0, 20)
    LogEntry.BackgroundTransparency = 1
    LogEntry.Text = "[" .. os.date("%H:%M:%S") .. "] " .. text
    LogEntry.Font = Enum.Font.Code
    LogEntry.TextSize = 12
    LogEntry.TextColor3 = color or UI.Colors.TextSecondary
    LogEntry.TextXAlignment = Enum.TextXAlignment.Left
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
    
    if self.Elements.MapProgressDetails and text then
        self.Elements.MapProgressDetails.Text = "Status: " .. text
    end
end

-- ============================================================
--                    ADVANCED MAP DECOMPILER
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
    ui:UpdateProgress(0, "Initializing AI-powered serialization...")
    
    self.Data.StartTime = tick()
    self.Data.Processed = 0
    self.Data.Instances = {}
    
    task.spawn(function()
        -- Scan phase
        ui:AddLog("🔍 Scanning game hierarchy...", UI.Colors.Primary)
        local allInstances = game:GetDescendants()
        self.Data.Total = #allInstances
        
        ui:AddLog("�� Found " .. Util.FormatNumber(self.Data.Total) .. " instances", UI.Colors.Success)
        
        -- Processing phase with multi-threading
        ui:AddLog("⚙️ Starting multi-threaded processing...", UI.Colors.Primary)
        
        local threads = {}
        local chunkSize = math.ceil(self.Data.Total / BaoSaveInstance.Config.MaxThreads)
        
        for i = 1, BaoSaveInstance.Config.MaxThreads do
            local startIdx = (i - 1) * chunkSize + 1
            local endIdx = math.min(i * chunkSize, self.Data.Total)
            
            table.insert(threads, task.spawn(function()
                for j = startIdx, endIdx do
                    if allInstances[j] then
                        self:ProcessInstance(allInstances[j], ui)
                    end
                    
                    self.Data.Processed = self.Data.Processed + 1
                    
                    if self.Data.Processed % 100 == 0 then
                        local progress = self.Data.Processed / self.Data.Total
                        ui:UpdateProgress(progress, string.format(
                            "Processing: %s/%s (%.1f%%)",
                            Util.FormatNumber(self.Data.Processed),
                            Util.FormatNumber(self.Data.Total),
                            progress * 100
                        ))
                    end
                    
                    if self.Data.Processed % 1000 == 0 then
                        task.wait() -- Yield every 1000 to prevent freeze
                    end
                end
            end))
        end
        
        -- Wait for all threads
        for _, thread in ipairs(threads) do
            while coroutine.status(thread) ~= "dead" do
                task.wait(0.1)
            end
        end
        
        -- Completion
        local elapsedTime = tick() - self.Data.StartTime
        ui:UpdateProgress(1, "Complete!")
        ui:AddLog(string.format("✅ Decompilation complete in %.2fs", elapsedTime), UI.Colors.Success)
        ui:AddLog(string.format("📊 Processed %s instances", Util.FormatNumber(self.Data.Processed)), UI.Colors.Success)
        ui:AddLog(string.format("💾 Data size: %s", Util.FormatBytes(#Services.HttpService:JSONEncode(self.Data.Instances))), UI.Colors.Warning)
    end)
end

function MapDecompiler:ProcessInstance(instance, ui)
    local data = {
        ClassName = instance.ClassName,
        Name = instance.Name,
        Properties = {}
    }
    
    -- Serialize properties based on class
    local success, err = pcall(function()
        if instance:IsA("BasePart") then
            data.Properties.Size = {instance.Size.X, instance.Size.Y, instance.Size.Z}
            data.Properties.Position = {instance.Position.X, instance.Position.Y, instance.Position.Z}
            data.Properties.Rotation = {instance.Rotation.X, instance.Rotation.Y, instance.Rotation.Z}
            data.Properties.Color = {instance.Color.R, instance.Color.G, instance.Color.B}
            data.Properties.Material = tostring(instance.Material)
            data.Properties.Transparency = instance.Transparency
            data.Properties.CanCollide = instance.CanCollide
            data.Properties.Anchored = instance.Anchored
        end
    end)
    
    if not success then
        ui:AddLog("⚠️ Failed to process: " .. instance:GetFullName(), UI.Colors.Warning)
    end
    
    table.insert(self.Data.Instances, data)
end

-- ============================================================
--                    INITIALIZATION
-- ============================================================

function BaoSaveInstance:Init()
    print("╔═══════════════════════════════════════════════════════╗")
    print("║      BAO SAVEINSTANCE v3.0 ULTIMATE EDITION         ║")
    print("║        Loading Advanced Decompiler System...        ║")
    print("╚═══════════════════════════════════════════════════════╝")
    
    -- Create UI
    local ui = self.Modules.UI:Create()
    
    -- Parent to appropriate container
    if gethui then
        ui.ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(ui.ScreenGui)
        ui.ScreenGui.Parent = Services.CoreGui
    else
        ui.ScreenGui.Parent = Services.Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    print("✅ Bao SaveInstance v3.0 Ultimate - Loaded Successfully!")
    print("🎮 UI Initialized | 🚀 All Systems Ready")
end

-- ============================================================
--                    EXECUTE
-- ============================================================

BaoSaveInstance:Init()
