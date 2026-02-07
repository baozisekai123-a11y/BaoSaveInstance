--[[
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                       BaoSaveInstance API Framework v3.0                              ║
║                              GUI/Interface.lua                                        ║
╠══════════════════════════════════════════════════════════════════════════════════════╣
║  File: GUI/Interface.lua                                                             ║
║  Description: Modern GUI interface with animations, theming, and full integration    ║
╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local Interface = {}

--// ═══════════════════════════════════════════════════════════════════════════════════
--// SERVICES
--// ═══════════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// ═══════════════════════════════════════════════════════════════════════════════════
--// INTERNAL STATE
--// ═══════════════════════════════════════════════════════════════════════════════════

Interface._instance = nil
Interface._isOpen = false
Interface._isMinimized = false
Interface._isSaving = false
Interface._isDragging = false
Interface._elements = {}
Interface._connections = {}
Interface._selectedMode = "All"
Interface._selectedModel = nil
Interface._api = nil  -- Will be set during Init

--// ═══════════════════════════════════════════════════════════════════════════════════
--// THEME SYSTEM
--// ═══════════════════════════════════════════════════════════════════════════════════

Interface.Themes = {
    Dark = {
        Name = "Dark",
        
        -- Primary colors
        Primary = Color3.fromRGB(88, 101, 242),
        PrimaryHover = Color3.fromRGB(104, 117, 255),
        PrimaryActive = Color3.fromRGB(71, 82, 196),
        
        -- Background colors
        Background = Color3.fromRGB(30, 31, 34),
        BackgroundSecondary = Color3.fromRGB(43, 45, 49),
        BackgroundTertiary = Color3.fromRGB(54, 57, 63),
        BackgroundFloating = Color3.fromRGB(35, 36, 40),
        
        -- Text colors
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(185, 187, 190),
        TextMuted = Color3.fromRGB(114, 118, 125),
        TextLink = Color3.fromRGB(0, 168, 252),
        
        -- Status colors
        Success = Color3.fromRGB(87, 242, 135),
        Warning = Color3.fromRGB(254, 231, 92),
        Error = Color3.fromRGB(237, 66, 69),
        Info = Color3.fromRGB(88, 182, 242),
        
        -- Mode colors
        Terrain = Color3.fromRGB(46, 204, 113),
        Scripts = Color3.fromRGB(241, 196, 15),
        Model = Color3.fromRGB(155, 89, 182),
        FullMap = Color3.fromRGB(52, 152, 219),
        All = Color3.fromRGB(231, 76, 60),
        
        -- Border & Shadow
        Border = Color3.fromRGB(60, 63, 68),
        BorderFocused = Color3.fromRGB(88, 101, 242),
        Shadow = Color3.fromRGB(0, 0, 0),
        
        -- Fonts
        FontRegular = Enum.Font.GothamMedium,
        FontBold = Enum.Font.GothamBold,
        FontLight = Enum.Font.Gotham,
        FontMono = Enum.Font.RobotoMono,
    },
    
    Light = {
        Name = "Light",
        
        Primary = Color3.fromRGB(88, 101, 242),
        PrimaryHover = Color3.fromRGB(71, 82, 196),
        PrimaryActive = Color3.fromRGB(57, 66, 157),
        
        Background = Color3.fromRGB(255, 255, 255),
        BackgroundSecondary = Color3.fromRGB(242, 243, 245),
        BackgroundTertiary = Color3.fromRGB(227, 229, 232),
        BackgroundFloating = Color3.fromRGB(255, 255, 255),
        
        Text = Color3.fromRGB(6, 6, 7),
        TextSecondary = Color3.fromRGB(79, 84, 92),
        TextMuted = Color3.fromRGB(116, 124, 137),
        TextLink = Color3.fromRGB(0, 103, 224),
        
        Success = Color3.fromRGB(35, 165, 89),
        Warning = Color3.fromRGB(218, 165, 32),
        Error = Color3.fromRGB(218, 55, 60),
        Info = Color3.fromRGB(59, 130, 246),
        
        Terrain = Color3.fromRGB(34, 153, 84),
        Scripts = Color3.fromRGB(196, 160, 0),
        Model = Color3.fromRGB(128, 57, 153),
        FullMap = Color3.fromRGB(41, 121, 175),
        All = Color3.fromRGB(192, 57, 43),
        
        Border = Color3.fromRGB(218, 220, 224),
        BorderFocused = Color3.fromRGB(88, 101, 242),
        Shadow = Color3.fromRGB(0, 0, 0),
        
        FontRegular = Enum.Font.GothamMedium,
        FontBold = Enum.Font.GothamBold,
        FontLight = Enum.Font.Gotham,
        FontMono = Enum.Font.RobotoMono,
    },
    
    Midnight = {
        Name = "Midnight",
        
        Primary = Color3.fromRGB(114, 137, 218),
        PrimaryHover = Color3.fromRGB(130, 153, 234),
        PrimaryActive = Color3.fromRGB(98, 121, 202),
        
        Background = Color3.fromRGB(18, 19, 22),
        BackgroundSecondary = Color3.fromRGB(26, 27, 31),
        BackgroundTertiary = Color3.fromRGB(35, 37, 42),
        BackgroundFloating = Color3.fromRGB(22, 23, 27),
        
        Text = Color3.fromRGB(220, 221, 222),
        TextSecondary = Color3.fromRGB(163, 166, 170),
        TextMuted = Color3.fromRGB(96, 99, 106),
        TextLink = Color3.fromRGB(114, 137, 218),
        
        Success = Color3.fromRGB(67, 181, 129),
        Warning = Color3.fromRGB(250, 166, 26),
        Error = Color3.fromRGB(240, 71, 71),
        Info = Color3.fromRGB(114, 137, 218),
        
        Terrain = Color3.fromRGB(67, 181, 129),
        Scripts = Color3.fromRGB(250, 166, 26),
        Model = Color3.fromRGB(181, 103, 218),
        FullMap = Color3.fromRGB(114, 137, 218),
        All = Color3.fromRGB(240, 71, 71),
        
        Border = Color3.fromRGB(47, 49, 55),
        BorderFocused = Color3.fromRGB(114, 137, 218),
        Shadow = Color3.fromRGB(0, 0, 0),
        
        FontRegular = Enum.Font.GothamMedium,
        FontBold = Enum.Font.GothamBold,
        FontLight = Enum.Font.Gotham,
        FontMono = Enum.Font.RobotoMono,
    },
}

Interface.CurrentTheme = Interface.Themes.Dark

-- Set theme
function Interface.SetTheme(themeName)
    local theme = Interface.Themes[themeName]
    if theme then
        Interface.CurrentTheme = theme
        if Interface._instance then
            Interface.ApplyTheme()
        end
        return true
    end
    return false
end

-- Get current theme
function Interface.GetTheme()
    return Interface.CurrentTheme
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// ANIMATION UTILITIES
--// ═══════════════════════════════════════════════════════════════════════════════════

local Animations = {}

function Animations.Tween(object, properties, duration, style, direction)
    duration = duration or 0.25
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration, style, direction),
        properties
    )
    tween:Play()
    return tween
end

function Animations.TweenSequence(tweens)
    local index = 1
    local function playNext()
        if index <= #tweens then
            local tweenData = tweens[index]
            local tween = Animations.Tween(
                tweenData.Object,
                tweenData.Properties,
                tweenData.Duration,
                tweenData.Style,
                tweenData.Direction
            )
            tween.Completed:Connect(function()
                index = index + 1
                playNext()
            end)
        end
    end
    playNext()
end

function Animations.Ripple(button, color)
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
    
    local buttonPos = button.AbsolutePosition
    local mousePos = UserInputService:GetMouseLocation()
    
    ripple.Position = UDim2.new(0, mousePos.X - buttonPos.X, 0, mousePos.Y - buttonPos.Y - 36)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Parent = button
    
    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
    
    Animations.Tween(ripple, {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    }, 0.5)
    
    task.delay(0.5, function()
        if ripple and ripple.Parent then
            ripple:Destroy()
        end
    end)
end

function Animations.Shake(object, intensity, duration)
    intensity = intensity or 5
    duration = duration or 0.3
    
    local originalPosition = object.Position
    local startTime = tick()
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= duration then
            object.Position = originalPosition
            connection:Disconnect()
            return
        end
        
        local progress = elapsed / duration
        local currentIntensity = intensity * (1 - progress)
        
        local offsetX = math.random(-currentIntensity, currentIntensity)
        local offsetY = math.random(-currentIntensity, currentIntensity)
        
        object.Position = UDim2.new(
            originalPosition.X.Scale,
            originalPosition.X.Offset + offsetX,
            originalPosition.Y.Scale,
            originalPosition.Y.Offset + offsetY
        )
    end)
end

function Animations.Pulse(object, scale, duration)
    scale = scale or 1.05
    duration = duration or 0.15
    
    local originalSize = object.Size
    
    Animations.Tween(object, {
        Size = UDim2.new(
            originalSize.X.Scale * scale,
            originalSize.X.Offset * scale,
            originalSize.Y.Scale * scale,
            originalSize.Y.Offset * scale
        )
    }, duration / 2)
    
    task.delay(duration / 2, function()
        Animations.Tween(object, {Size = originalSize}, duration / 2)
    end)
end

function Animations.FadeIn(object, duration)
    duration = duration or 0.3
    
    if object:IsA("Frame") or object:IsA("TextButton") or object:IsA("TextLabel") then
        object.BackgroundTransparency = 1
        Animations.Tween(object, {BackgroundTransparency = 0}, duration)
    end
    
    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
        object.TextTransparency = 1
        Animations.Tween(object, {TextTransparency = 0}, duration)
    end
end

function Animations.FadeOut(object, duration)
    duration = duration or 0.3
    
    if object:IsA("Frame") or object:IsA("TextButton") or object:IsA("TextLabel") then
        Animations.Tween(object, {BackgroundTransparency = 1}, duration)
    end
    
    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
        Animations.Tween(object, {TextTransparency = 1}, duration)
    end
end

function Animations.SlideIn(object, direction, duration)
    direction = direction or "Right"
    duration = duration or 0.4
    
    local originalPosition = object.Position
    local startPosition
    
    if direction == "Right" then
        startPosition = UDim2.new(1.5, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
    elseif direction == "Left" then
        startPosition = UDim2.new(-0.5, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
    elseif direction == "Top" then
        startPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, -0.5, 0)
    elseif direction == "Bottom" then
        startPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1.5, 0)
    end
    
    object.Position = startPosition
    Animations.Tween(object, {Position = originalPosition}, duration, Enum.EasingStyle.Back)
end

function Animations.SlideOut(object, direction, duration)
    direction = direction or "Right"
    duration = duration or 0.4
    
    local originalPosition = object.Position
    local endPosition
    
    if direction == "Right" then
        endPosition = UDim2.new(1.5, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
    elseif direction == "Left" then
        endPosition = UDim2.new(-0.5, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
    elseif direction == "Top" then
        endPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, -0.5, 0)
    elseif direction == "Bottom" then
        endPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1.5, 0)
    end
    
    Animations.Tween(object, {Position = endPosition}, duration, Enum.EasingStyle.Back, Enum.EasingDirection.In)
end

Interface.Animations = Animations

--// ═══════════════════════════════════════════════════════════════════════════════════
--// UI COMPONENT BUILDERS
--// ═══════════════════════════════════════════════════════════════════════════════════

local Components = {}

-- Create basic frame
function Components.Frame(props)
    props = props or {}
    local theme = Interface.CurrentTheme
    
    local frame = Instance.new("Frame")
    frame.Name = props.Name or "Frame"
    frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = props.BackgroundColor3 or theme.Background
    frame.BackgroundTransparency = props.BackgroundTransparency or 0
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = props.ClipsDescendants or false
    frame.ZIndex = props.ZIndex or 1
    
    if props.AnchorPoint then
        frame.AnchorPoint = props.AnchorPoint
    end
    
    if props.CornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = props.CornerRadius
        corner.Parent = frame
    end
    
    if props.Stroke then
        local stroke = Instance.new("UIStroke")
        stroke.Color = props.Stroke.Color or theme.Border
        stroke.Thickness = props.Stroke.Thickness or 1
        stroke.Transparency = props.Stroke.Transparency or 0
        stroke.Parent = frame
    end
    
    if props.Parent then
        frame.Parent = props.Parent
    end
    
    return frame
end

-- Create text label
function Components.Label(props)
    props = props or {}
    local theme = Interface.CurrentTheme
    
    local label = Instance.new("TextLabel")
    label.Name = props.Name or "Label"
    label.Size = props.Size or UDim2.new(1, 0, 0, 20)
    label.Position = props.Position or UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = props.BackgroundTransparency or 1
    label.BackgroundColor3 = props.BackgroundColor3 or theme.Background
    label.Text = props.Text or ""
    label.TextColor3 = props.TextColor3 or theme.Text
    label.TextSize = props.TextSize or 14
    label.Font = props.Font or theme.FontRegular
    label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    label.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    label.TextWrapped = props.TextWrapped or false
    label.TextTruncate = props.TextTruncate or Enum.TextTruncate.None
    label.RichText = props.RichText or false
    label.ZIndex = props.ZIndex or 1
    label.BorderSizePixel = 0
    
    if props.AnchorPoint then
        label.AnchorPoint = props.AnchorPoint
    end
    
    if props.Parent then
        label.Parent = props.Parent
    end
    
    return label
end

-- Create button
function Components.Button(props)
    props = props or {}
    local theme = Interface.CurrentTheme
    
    local button = Instance.new("TextButton")
    button.Name = props.Name or "Button"
    button.Size = props.Size or UDim2.new(0, 100, 0, 36)
    button.Position = props.Position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = props.BackgroundColor3 or theme.Primary
    button.BackgroundTransparency = props.BackgroundTransparency or 0
    button.Text = props.Text or ""
    button.TextColor3 = props.TextColor3 or theme.Text
    button.TextSize = props.TextSize or 14
    button.Font = props.Font or theme.FontBold
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    button.ClipsDescendants = true
    button.ZIndex = props.ZIndex or 1
    
    if props.AnchorPoint then
        button.AnchorPoint = props.AnchorPoint
    end
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = props.CornerRadius or UDim.new(0, 8)
    corner.Parent = button
    
    if props.Stroke then
        local stroke = Instance.new("UIStroke")
        stroke.Name = "Stroke"
        stroke.Color = props.Stroke.Color or theme.Border
        stroke.Thickness = props.Stroke.Thickness or 1
        stroke.Parent = button
    end
    
    -- Hover effects
    local originalColor = button.BackgroundColor3
    local hoverColor = props.HoverColor or theme.PrimaryHover
    
    button.MouseEnter:Connect(function()
        Animations.Tween(button, {BackgroundColor3 = hoverColor}, 0.15)
    end)
    
    button.MouseLeave:Connect(function()
        Animations.Tween(button, {BackgroundColor3 = originalColor}, 0.15)
    end)
    
    -- Click effect
    if props.Ripple ~= false then
        button.MouseButton1Click:Connect(function()
            Animations.Ripple(button)
        end)
    end
    
    if props.OnClick then
        button.MouseButton1Click:Connect(props.OnClick)
    end
    
    if props.Parent then
        button.Parent = props.Parent
    end
    
    return button
end

-- Create text input
function Components.Input(props)
    props = props or {}
    local theme = Interface.CurrentTheme
    
    local container = Components.Frame({
        Name = props.Name or "InputContainer",
        Size = props.Size or UDim2.new(1, 0, 0, 40),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = props.BackgroundColor3 or theme.BackgroundSecondary,
        CornerRadius = UDim.new(0, 8),
        Stroke = {Color = theme.Border, Thickness = 1},
        Parent = props.Parent,
    })
    
    local textBox = Instance.new("TextBox")
    textBox.Name = "TextBox"
    textBox.Size = UDim2.new(1, -20, 1, 0)
    textBox.Position = UDim2.new(0, 10, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.Text = props.Text or ""
    textBox.PlaceholderText = props.Placeholder or ""
    textBox.PlaceholderColor3 = theme.TextMuted
    textBox.TextColor3 = theme.Text
    textBox.TextSize = props.TextSize or 14
    textBox.Font = theme.FontRegular
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = props.ClearOnFocus or false
    textBox.Parent = container
    
    local stroke = container:FindFirstChildOfClass("UIStroke")
    
    textBox.Focused:Connect(function()
        if stroke then
            Animations.Tween(stroke, {Color = theme.BorderFocused}, 0.2)
        end
    end)
    
    textBox.FocusLost:Connect(function()
        if stroke then
            Animations.Tween(stroke, {Color = theme.Border}, 0.2)
        end
        if props.OnFocusLost then
            props.OnFocusLost(textBox.Text)
        end
    end)
    
    if props.OnChanged then
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            props.OnChanged(textBox.Text)
        end)
    end
    
    return container, textBox
end

-- Create toggle/checkbox
function Components.Toggle(props)
    props = props or {}
    local theme = Interface.CurrentTheme
    local enabled = props.Default or false
    
    local container = Components.Frame({
        Name = props.Name or "Toggle",
        Size = props.Size or UDim2.new(1, 0, 0, 36),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = props.Parent,
    })
    
    local checkbox = Instance.new("TextButton")
    checkbox.Name = "Checkbox"
    checkbox.Size = UDim2.new(0, 24, 0, 24)
    checkbox.Position = UDim2.new(0, 0, 0.5, -12)
    checkbox.BackgroundColor3 = enabled and theme.Primary or theme.BackgroundSecondary
    checkbox.Text = enabled and "✓" or ""
    checkbox.TextColor3 = theme.Text
    checkbox.TextSize = 14
    checkbox.Font = theme.FontBold
    checkbox.AutoButtonColor = false
    checkbox.BorderSizePixel = 0
    checkbox.Parent = container
    
    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 6)
    checkCorner.Parent = checkbox
    
    local checkStroke = Instance.new("UIStroke")
    checkStroke.Color = enabled and theme.Primary or theme.Border
    checkStroke.Thickness = 1
    checkStroke.Parent = checkbox
    
    local label = Components.Label({
        Name = "Label",
        Size = UDim2.new(1, -34, 1, 0),
        Position = UDim2.new(0, 32, 0, 0),
        Text = props.Label or "",
        TextColor3 = theme.TextSecondary,
        TextSize = 13,
        Parent = container,
    })
    
    local function updateState(newState)
        enabled = newState
        Animations.Tween(checkbox, {
            BackgroundColor3 = enabled and theme.Primary or theme.BackgroundSecondary
        }, 0.2)
        Animations.Tween(checkStroke, {
            Color = enabled and theme.Primary or theme.Border
        }, 0.2)
        checkbox.Text = enabled and "✓" or ""
    end
    
    checkbox.MouseButton1Click:Connect(function()
        Animations.Pulse(checkbox, 1.1, 0.1)
        updateState(not enabled)
        if props.OnChanged then
            props.OnChanged(enabled)
        end
    end)
    
    -- Return control functions
    container.GetValue = function() return enabled end
    container.SetValue = function(value) updateState(value) end
    
    return container
end

-- Create dropdown
function Components.Dropdown(props)
    props = props or {}
    local theme = Interface.CurrentTheme
    local isOpen = false
    local selectedIndex = props.Default or 1
    local options = props.Options or {}
    
    local container = Components.Frame({
        Name = props.Name or "Dropdown",
        Size = props.Size or UDim2.new(1, 0, 0, 40),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.BackgroundSecondary,
        CornerRadius = UDim.new(0, 8),
        Stroke = {Color = theme.Border},
        ClipsDescendants = true,
        Parent = props.Parent,
    })
    
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundTransparency = 1
    header.Text = ""
    header.Parent = container
    
    local selectedLabel = Components.Label({
        Name = "Selected",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        Text = options[selectedIndex] or "Select...",
        TextColor3 = theme.Text,
        TextSize = 13,
        Parent = header,
    })
    
    local arrow = Components.Label({
        Name = "Arrow",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -30, 0, 0),
        Text = "▼",
        TextColor3 = theme.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = header,
    })
    
    local optionsList = Components.Frame({
        Name = "Options",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = theme.BackgroundTertiary,
        Parent = container,
    })
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = optionsList
    
    local function toggleDropdown()
        isOpen = not isOpen
        
        local targetHeight = isOpen and (40 + #options * 32) or 40
        Animations.Tween(container, {Size = UDim2.new(props.Size and props.Size.X.Scale or 1, props.Size and props.Size.X.Offset or 0, 0, targetHeight)}, 0.25)
        Animations.Tween(optionsList, {Size = UDim2.new(1, 0, 0, isOpen and #options * 32 or 0)}, 0.25)
        Animations.Tween(arrow, {Rotation = isOpen and 180 or 0}, 0.25)
    end
    
    local function selectOption(index)
        selectedIndex = index
        selectedLabel.Text = options[index]
        toggleDropdown()
        if props.OnChanged then
            props.OnChanged(index, options[index])
        end
    end
    
    header.MouseButton1Click:Connect(toggleDropdown)
    
    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Name = "Option_" .. i
        optBtn.Size = UDim2.new(1, 0, 0, 32)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = option
        optBtn.TextColor3 = theme.TextSecondary
        optBtn.TextSize = 12
        optBtn.Font = theme.FontRegular
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.AutoButtonColor = false
        optBtn.LayoutOrder = i
        optBtn.Parent = optionsList
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12)
        padding.Parent = optBtn
        
        optBtn.MouseEnter:Connect(function()
            Animations.Tween(optBtn, {BackgroundTransparency = 0.8, TextColor3 = theme.Text}, 0.1)
        end)
        
        optBtn.MouseLeave:Connect(function()
            Animations.Tween(optBtn, {BackgroundTransparency = 1, TextColor3 = theme.TextSecondary}, 0.1)
        end)
        
        optBtn.MouseButton1Click:Connect(function()
            selectOption(i)
        end)
    end
    
    container.GetValue = function() return selectedIndex, options[selectedIndex] end
    container.SetValue = function(index) selectOption(index) end
    
    return container
end

-- Create progress bar
function Components.ProgressBar(props)
    props = props or {}
    local theme = Interface.CurrentTheme
    
    local container = Components.Frame({
        Name = props.Name or "ProgressBar",
        Size = props.Size or UDim2.new(1, 0, 0, 12),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.BackgroundSecondary,
        CornerRadius = UDim.new(0, 6),
        Parent = props.Parent,
    })
    
    local fill = Components.Frame({
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = props.Color or theme.Primary,
        CornerRadius = UDim.new(0, 6),
        Parent = container,
    })
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, props.Color or theme.Primary),
        ColorSequenceKeypoint.new(1, props.GradientColor or theme.PrimaryHover),
    })
    gradient.Parent = fill
    
    local function setProgress(percent, animate)
        percent = math.clamp(percent, 0, 100)
        if animate ~= false then
            Animations.Tween(fill, {Size = UDim2.new(percent / 100, 0, 1, 0)}, 0.3)
        else
            fill.Size = UDim2.new(percent / 100, 0, 1, 0)
        end
    end
    
    container.SetProgress = setProgress
    container.GetProgress = function() return fill.Size.X.Scale * 100 end
    
    if props.Value then
        setProgress(props.Value, false)
    end
    
    return container
end

-- Create notification toast
function Components.Toast(message, type, duration)
    type = type or "info"
    duration = duration or 3
    local theme = Interface.CurrentTheme
    
    local colors = {
        info = theme.Info,
        success = theme.Success,
        warning = theme.Warning,
        error = theme.Error,
    }
    
    local icons = {
        info = "ℹ️",
        success = "✅",
        warning = "⚠️",
        error = "❌",
    }
    
    local toast = Components.Frame({
        Name = "Toast",
        Size = UDim2.new(0, 300, 0, 50),
        Position = UDim2.new(0.5, -150, 1, 60),
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = theme.BackgroundFloating,
        CornerRadius = UDim.new(0, 10),
        Stroke = {Color = colors[type], Thickness = 2},
        Parent = Interface._instance,
    })
    toast.ZIndex = 100
    
    local icon = Components.Label({
        Name = "Icon",
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = icons[type] or "ℹ️",
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = toast,
    })
    icon.ZIndex = 101
    
    local text = Components.Label({
        Name = "Text",
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 45, 0, 0),
        Text = message,
        TextColor3 = theme.Text,
        TextSize = 13,
        TextWrapped = true,
        Parent = toast,
    })
    text.ZIndex = 101
    
    -- Animate in
    Animations.Tween(toast, {Position = UDim2.new(0.5, -150, 1, -20)}, 0.4, Enum.EasingStyle.Back)
    
    -- Auto hide
    task.delay(duration, function()
        Animations.Tween(toast, {Position = UDim2.new(0.5, -150, 1, 60)}, 0.3)
        task.delay(0.3, function()
            if toast and toast.Parent then
                toast:Destroy()
            end
        end)
    end)
    
    return toast
end

Interface.Components = Components

--// ═══════════════════════════════════════════════════════════════════════════════════
--// MAIN GUI BUILDER
--// ═══════════════════════════════════════════════════════════════════════════════════

function Interface.Create()
    -- Clean up old instance
    if Interface._instance then
        Interface.Destroy()
    end
    
    local theme = Interface.CurrentTheme
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstance"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    local success = pcall(function()
        screenGui.Parent = CoreGui
    end)
    
    if not success then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    Interface._instance = screenGui
    
    --// ═══════════════════════════════════════════════════════════════════════════
    --// MAIN FRAME
    --// ═══════════════════════════════════════════════════════════════════════════
    
    local mainFrame = Components.Frame({
        Name = "MainFrame",
        Size = UDim2.new(0, 500, 0, 560),
        Position = UDim2.new(0.5, -250, 0.5, -280),
        BackgroundColor3 = theme.Background,
        CornerRadius = UDim.new(0, 12),
        ClipsDescendants = true,
        Parent = screenGui,
    })
    
    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 60, 1, 60)
    shadow.Position = UDim2.new(0, -30, 0, -30)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = theme.Shadow
    shadow.ImageTransparency = 0.4
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = -1
    shadow.Parent = mainFrame
    
    Interface._elements.MainFrame = mainFrame
    
    --// ═══════════════════════════════════════════════════════════════════════════
    --// TITLE BAR
    --// ═══════════════════════════════════════════════════════════════════════════
    
    local titleBar = Components.Frame({
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 55),
        BackgroundColor3 = theme.BackgroundSecondary,
        Parent = mainFrame,
    })
    
    -- Title bar bottom fix
    local titleBarFix = Components.Frame({
        Name = "Fix",
        Size = UDim2.new(1, 0, 0, 15),
        Position = UDim2.new(0, 0, 1, -15),
        BackgroundColor3 = theme.BackgroundSecondary,
        Parent = titleBar,
    })
    
    -- Logo
    local logo = Components.Label({
        Name = "Logo",
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 12, 0.5, -20),
        BackgroundTransparency = 0,
        BackgroundColor3 = theme.Primary,
        Text = "💾",
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = titleBar,
    })
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 10)
    logoCorner.Parent = logo
    
    -- Title
    local title = Components.Label({
        Name = "Title",
        Size = UDim2.new(0, 200, 0, 22),
        Position = UDim2.new(0, 62, 0, 10),
        Text = "BaoSaveInstance",
        TextColor3 = theme.Text,
        TextSize = 17,
        Font = theme.FontBold,
        Parent = titleBar,
    })
    
    -- Version
    local version = Components.Label({
        Name = "Version",
        Size = UDim2.new(0, 150, 0, 16),
        Position = UDim2.new(0, 62, 0, 32),
        Text = "v3.0.0 • API Framework",
        TextColor3 = theme.TextMuted,
        TextSize = 11,
        Font = theme.FontLight,
        Parent = titleBar,
    })
    
    -- Close button
    local closeBtn = Components.Button({
        Name = "CloseButton",
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(1, -48, 0.5, -18),
        BackgroundColor3 = theme.Error,
        BackgroundTransparency = 1,
        Text = "✕",
        TextColor3 = theme.TextSecondary,
        TextSize = 16,
        Font = theme.FontBold,
        HoverColor = theme.Error,
        CornerRadius = UDim.new(0, 8),
        Ripple = false,
        OnClick = function()
            Interface.Close()
        end,
        Parent = titleBar,
    })
    
    closeBtn.MouseEnter:Connect(function()
        Animations.Tween(closeBtn, {BackgroundTransparency = 0, TextColor3 = theme.Text}, 0.2)
    end)
    
    closeBtn.MouseLeave:Connect(function()
        Animations.Tween(closeBtn, {BackgroundTransparency = 1, TextColor3 = theme.TextSecondary}, 0.2)
    end)
    
    -- Minimize button
    local minBtn = Components.Button({
        Name = "MinimizeButton",
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(1, -90, 0.5, -18),
        BackgroundColor3 = theme.Warning,
        BackgroundTransparency = 1,
        Text = "─",
        TextColor3 = theme.TextSecondary,
        TextSize = 16,
        Font = theme.FontBold,
        CornerRadius = UDim.new(0, 8),
        Ripple = false,
        OnClick = function()
            Interface.Minimize()
        end,
        Parent = titleBar,
    })
    
    minBtn.MouseEnter:Connect(function()
        Animations.Tween(minBtn, {BackgroundTransparency = 0, TextColor3 = theme.Background}, 0.2)
    end)
    
    minBtn.MouseLeave:Connect(function()
        Animations.Tween(minBtn, {BackgroundTransparency = 1, TextColor3 = theme.TextSecondary}, 0.2)
    end)
    
    Interface._elements.TitleBar = titleBar
    
    --// ═══════════════════════════════════════════════════════════════════════════
    --// CONTENT AREA
    --// ═══════════════════════════════════════════════════════════════════════════
    
    local content = Components.Frame({
        Name = "Content",
        Size = UDim2.new(1, -24, 1, -95),
        Position = UDim2.new(0, 12, 0, 60),
        BackgroundTransparency = 1,
        Parent = mainFrame,
    })
    
    Interface._elements.Content = content
    
    --// ═══════════════════════════════════════════════════════════════════════════
    --// MODE SELECTOR SECTION
    --// ═══════════════════════════════════════════════════════════════════════════
    
    local modeSection = Components.Frame({
        Name = "ModeSection",
        Size = UDim2.new(1, 0, 0, 165),
        BackgroundTransparency = 1,
        Parent = content,
    })
    
    local modeLabel = Components.Label({
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 22),
        Text = "📁 CHỌN LOẠI SAVE",
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = theme.FontBold,
        Parent = modeSection,
    })
    
    local modeGrid = Components.Frame({
        Name = "Grid",
        Size = UDim2.new(1, 0, 0, 130),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = modeSection,
    })
    
    local modes = {
        {Name = "Terrain", Icon = "🌍", Color = theme.Terrain, Desc = "Chỉ lưu địa hình", X = 0, Y = 0},
        {Name = "Scripts", Icon = "📜", Color = theme.Scripts, Desc = "Toàn bộ scripts", X = 1, Y = 0},
        {Name = "Model", Icon = "📦", Color = theme.Model, Desc = "1 Model cụ thể", X = 2, Y = 0},
        {Name = "Full Map", Icon = "🗺️", Color = theme.FullMap, Desc = "Map đầy đủ", X = 0, Y = 1},
        {Name = "All", Icon = "⭐", Color = theme.All, Desc = "Toàn bộ game", X = 1, Y = 1},
    }
    
    local modeButtons = {}
    local btnWidth = (476 - 20) / 3
    local btnHeight = 58
    
    for _, mode in ipairs(modes) do
        local btn = Components.Frame({
            Name = mode.Name,
            Size = UDim2.new(0, btnWidth, 0, btnHeight),
            Position = UDim2.new(0, mode.X * (btnWidth + 10), 0, mode.Y * (btnHeight + 10)),
            BackgroundColor3 = theme.BackgroundSecondary,
            CornerRadius = UDim.new(0, 10),
            Stroke = {Color = theme.Border, Thickness = 1},
            Parent = modeGrid,
        })
        
        -- Make clickable
        local clickArea = Instance.new("TextButton")
        clickArea.Name = "ClickArea"
        clickArea.Size = UDim2.new(1, 0, 1, 0)
        clickArea.BackgroundTransparency = 1
        clickArea.Text = ""
        clickArea.Parent = btn
        
        local indicator = Components.Frame({
            Name = "Indicator",
            Size = UDim2.new(0, 4, 0.6, 0),
            Position = UDim2.new(0, 0, 0.2, 0),
            BackgroundColor3 = mode.Color,
            BackgroundTransparency = 1,
            CornerRadius = UDim.new(0, 2),
            Parent = btn,
        })
        
        local icon = Components.Label({
            Name = "Icon",
            Size = UDim2.new(0, 30, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            Text = mode.Icon,
            TextSize = 20,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = btn,
        })
        
        local name = Components.Label({
            Name = "Name",
            Size = UDim2.new(1, -50, 0, 18),
            Position = UDim2.new(0, 45, 0, 12),
            Text = mode.Name,
            TextColor3 = theme.Text,
            TextSize = 13,
            Font = theme.FontBold,
            Parent = btn,
        })
        
        local desc = Components.Label({
            Name = "Desc",
            Size = UDim2.new(1, -50, 0, 14),
            Position = UDim2.new(0, 45, 0, 32),
            Text = mode.Desc,
            TextColor3 = theme.TextMuted,
            TextSize = 10,
            Font = theme.FontLight,
            Parent = btn,
        })
        
        modeButtons[mode.Name] = {
            Button = btn,
            Indicator = indicator,
            Stroke = btn:FindFirstChildOfClass("UIStroke"),
            Color = mode.Color,
        }
        
        clickArea.MouseEnter:Connect(function()
            if Interface._selectedMode ~= mode.Name then
                Animations.Tween(btn, {BackgroundColor3 = theme.BackgroundTertiary}, 0.15)
            end
        end)
        
        clickArea.MouseLeave:Connect(function()
            if Interface._selectedMode ~= mode.Name then
                Animations.Tween(btn, {BackgroundColor3 = theme.BackgroundSecondary}, 0.15)
            end
        end)
        
        clickArea.MouseButton1Click:Connect(function()
            Animations.Ripple(btn)
            Interface.SelectMode(mode.Name)
        end)
    end
    
    Interface._elements.ModeButtons = modeButtons
    
    --// ═══════════════════════════════════════════════════════════════════════════
    --// FILE NAME SECTION
    --// ═══════════════════════════════════════════════════════════════════════════
    
    local fileSection = Components.Frame({
        Name = "FileSection",
        Size = UDim2.new(1, 0, 0, 70),
        Position = UDim2.new(0, 0, 0, 175),
        BackgroundTransparency = 1,
        Parent = content,
    })
    
    local fileLabel = Components.Label({
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 20),
        Text = "📝 TÊN FILE (để trống = tên game)",
        TextColor3 = theme.Text,
        TextSize = 12,
        Font = theme.FontBold,
        Parent = fileSection,
    })
    
    local fileInputContainer, fileInput = Components.Input({
        Name = "FileInput",
        Size = UDim2.new(1, 0, 0, 42),
        Position = UDim2.new(0, 0, 0, 24),
        Placeholder = "Nhập tên file...",
        Parent = fileSection,
    })
    
    Interface._elements.FileSection = fileSection
    Interface._elements.FileInput = fileInput
    
    --// ═══════════════════════════════════════════════════════════════════════════
    --// MODEL SELECTOR SECTION (Hidden by default)
    --// ═══════════════════════════════════════════════════════════════════════════
    
    local modelSection = Components.Frame({
        Name = "ModelSection",
        Size = UDim2.new(1, 0, 0, 70),
        Position = UDim2.new(0, 0, 0, 175),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = content,
    })
    
    local modelLabel = Components.Label({
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 20),
        Text = "📦 CHỌN MODEL (Click trong game)",
        TextColor3 = theme.Text,
        TextSize = 12,
        Font = theme.FontBold,
        Parent = modelSection,
    })
    
    local modelFrame = Components.Frame({
        Name = "ModelFrame",
        Size = UDim2.new(1, 0, 0, 42),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = theme.BackgroundSecondary,
        CornerRadius = UDim.new(0, 8),
        Stroke = {Color = theme.Border},
        Parent = modelSection,
    })
    
    local modelText = Components.Label({
        Name = "ModelText",
        Size = UDim2.new(1, -85, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        Text = "Chưa chọn model...",
        TextColor3 = theme.TextMuted,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = modelFrame,
    })
    
    local pickModelBtn = Components.Button({
        Name = "PickButton",
        Size = UDim2.new(0, 65, 0, 32),
        Position = UDim2.new(1, -75, 0.5, -16),
        BackgroundColor3 = theme.Primary,
        Text = "Chọn",
        TextSize = 12,
        CornerRadius = UDim.new(0, 6),
        OnClick = function()
            Interface.StartModelPicker()
        end,
        Parent = modelFrame,
    })
    
    Interface._elements.ModelSection = modelSection
    Interface._elements.ModelText = modelText
    Interface._elements.ModelStroke = modelFrame:FindFirstChildOfClass("UIStroke")
    
    --// ═══════════════════════════════════════════════════════════════════════════
    --// OPTIONS SECTION
    --// ═══════════════════════════════════════════════════════════════════════════
    
    local optionsSection = Components.Frame({
        Name = "OptionsSection",
        Size = UDim2.new(1, 0, 0, 95),
        Position = UDim2.new(0, 0, 0, 255),
        BackgroundTransparency = 1,
        Parent = content,
    })
    
    local optionsLabel = Components.Label({
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 20),
        Text = "⚙️ TÙY CHỌN",
        TextColor3 = theme.Text,
        TextSize = 12,
        Font = theme.FontBold,
        Parent = optionsSection,
    })
    
    local optionsGrid = Components.Frame({
        Name = "Grid",
        Size = UDim2.new(1, 0, 0, 70),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundTransparency = 1,
        Parent = optionsSection,
    })
    
    local options = {
        {Key = "Decompile.Enabled", Label = "Decompile Scripts", X = 0, Y = 0, Default = true},
        {Key = "Instance.SaveTerrain", Label = "Save Terrain", X = 1, Y = 0, Default = true},
        {Key = "Instance.RemovePlayers", Label = "Remove Players", X = 0, Y = 1, Default = true},
        {Key = "Script.IgnoreDefaultScripts", Label = "Ignore Default Scripts", X = 1, Y = 1, Default = true},
    }
    
    Interface._elements.Options = {}
    
    for _, opt in ipairs(options) do
        local toggle = Components.Toggle({
            Name = opt.Key,
            Size = UDim2.new(0.48, 0, 0, 30),
            Position = UDim2.new(opt.X * 0.52, 0, 0, opt.Y * 35),
            Label = opt.Label,
            Default = opt.Default,
            OnChanged = function(enabled)
                if Interface._api and Interface._api.Config then
                    Interface._api.Config.Set(opt.Key, enabled)
                end
            end,
            Parent = optionsGrid,
        })
        
        Interface._elements.Options[opt.Key] = toggle
    end
    
    --// ═══════════════════════════════════════════════════════════════════════════
    --// PROGRESS SECTION
    --// ═══════════════════════════════════════════════════════════════════════════
    
    local progressSection = Components.Frame({
        Name = "ProgressSection",
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, 360),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = content,
    })
    
    local progressLabel = Components.Label({
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 18),
        Text = "Đang lưu... 0%",
        TextColor3 = theme.Text,
        TextSize = 12,
        Parent = progressSection,
    })
    
    local progressBar = Components.ProgressBar({
        Name = "Bar",
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 24),
        Color = theme.Primary,
        Parent = progressSection,
    })
    
    Interface._elements.ProgressSection = progressSection
    Interface._elements.ProgressLabel = progressLabel
    Interface._elements.ProgressBar = progressBar
    
    --// ═══════════════════════════════════════════════════════════════════════════
    --// SAVE BUTTON
    --// ═══════════════════════════════════════════════════════════════════════════
    
    local saveBtn = Components.Button({
        Name = "SaveButton",
        Size = UDim2.new(1, 0, 0, 52),
        Position = UDim2.new(0, 0, 1, -52),
        BackgroundColor3 = theme.Primary,
        Text = "",
        CornerRadius = UDim.new(0, 10),
        Parent = content,
    })
    
    local saveIcon = Components.Label({
        Name = "Icon",
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(0.5, -55, 0, 0),
        Text = "💾",
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = saveBtn,
    })
    
    local saveText = Components.Label({
        Name = "Text",
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(0.5, -15, 0, 0),
        Text = "SAVE",
        TextColor3 = theme.Text,
        TextSize = 18,
        Font = theme.FontBold,
        Parent = saveBtn,
    })
    
    -- Gradient
    local saveGradient = Instance.new("UIGradient")
    saveGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.Primary),
        ColorSequenceKeypoint.new(1, theme.PrimaryActive),
    })
    saveGradient.Rotation = 45
    saveGradient.Parent = saveBtn
    
    saveBtn.MouseButton1Click:Connect(function()
        if not Interface._isSaving then
            Animations.Ripple(saveBtn)
            Interface.ExecuteSave()
        end
    end)
    
    Interface._elements.SaveButton = saveBtn
    Interface._elements.SaveText = saveText
    Interface._elements.SaveIcon = saveIcon
    
    --// ═══════════════════════════════════════════════════════════════════════════
    --// STATUS BAR
    --// ═══════════════════════════════════════════════════════════════════════════
    
    local statusBar = Components.Frame({
        Name = "StatusBar",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 1, -30),
        BackgroundColor3 = theme.BackgroundSecondary,
        Parent = mainFrame,
    })
    
    local clientInfo = Components.Label({
        Name = "ClientInfo",
        Size = UDim2.new(0.5, -5, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        Text = "🔧 Detecting...",
        TextColor3 = theme.TextMuted,
        TextSize = 10,
        Parent = statusBar,
    })
    
    local gameInfo = Components.Label({
        Name = "GameInfo",
        Size = UDim2.new(0.5, -15, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Text = "🎮 " .. game.Name:sub(1, 25),
        TextColor3 = theme.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = statusBar,
    })
    
    Interface._elements.StatusBar = statusBar
    Interface._elements.ClientInfo = clientInfo
    Interface._elements.GameInfo = gameInfo
    
    --// ═══════════════════════════════════════════════════════════════════════════
    --// DRAGGABLE
    --// ═══════════════════════════════════════════════════════════════════════════
    
    Interface.MakeDraggable(mainFrame, titleBar)
    
    --// ═══════════════════════════════════════════════════════════════════════════
    --// ANIMATIONS
    --// ═══════════════════════════════════════════════════════════════════════════
    
    -- Initial animation
    mainFrame.Position = UDim2.new(0.5, -250, -0.5, 0)
    mainFrame.BackgroundTransparency = 1
    
    Animations.Tween(mainFrame, {
        Position = UDim2.new(0.5, -250, 0.5, -280),
        BackgroundTransparency = 0
    }, 0.5, Enum.EasingStyle.Back)
    
    -- Set default mode
    Interface.SelectMode("All")
    
    -- Update client info
    Interface.UpdateClientInfo()
    
    Interface._isOpen = true
    
    -- Emit event
    if Interface._api and Interface._api.Event then
        Interface._api.Event.Emit("GUICreated", screenGui, mainFrame)
    end
    
    return screenGui
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// DRAG FUNCTIONALITY
--// ═══════════════════════════════════════════════════════════════════════════════════

function Interface.MakeDraggable(frame, handle)
    handle = handle or frame
    
    local dragging = false
    local dragStart, frameStart
    
    local function update(input)
        if dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                frameStart.X.Scale,
                frameStart.X.Offset + delta.X,
                frameStart.Y.Scale,
                frameStart.Y.Offset + delta.Y
            )
        end
    end
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            frameStart = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            update(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            update(input)
        end
    end)
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// MODE SELECTION
--// ═══════════════════════════════════════════════════════════════════════════════════

function Interface.SelectMode(modeName)
    local theme = Interface.CurrentTheme
    Interface._selectedMode = modeName
    
    -- Update button states
    for name, data in pairs(Interface._elements.ModeButtons) do
        local isSelected = name == modeName
        
        Animations.Tween(data.Button, {
            BackgroundColor3 = isSelected and theme.BackgroundTertiary or theme.BackgroundSecondary
        }, 0.2)
        
        Animations.Tween(data.Indicator, {
            BackgroundTransparency = isSelected and 0 or 1
        }, 0.2)
        
        if data.Stroke then
            Animations.Tween(data.Stroke, {
                Color = isSelected and data.Color or theme.Border,
                Thickness = isSelected and 2 or 1
            }, 0.2)
        end
    end
    
    -- Show/hide model selector
    local isModel = modeName == "Model"
    Interface._elements.FileSection.Visible = not isModel
    Interface._elements.ModelSection.Visible = isModel
    
    -- Emit event
    if Interface._api and Interface._api.Event then
        Interface._api.Event.Emit("ModeChanged", modeName)
    end
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// MODEL PICKER
--// ═══════════════════════════════════════════════════════════════════════════════════

function Interface.StartModelPicker()
    local theme = Interface.CurrentTheme
    local modelText = Interface._elements.ModelText
    local modelStroke = Interface._elements.ModelStroke
    
    modelText.Text = "⏳ Click vào model trong game..."
    modelText.TextColor3 = theme.Warning
    Animations.Tween(modelStroke, {Color = theme.Warning}, 0.2)
    
    local connection
    connection = Mouse.Button1Down:Connect(function()
        local target = Mouse.Target
        
        if target and target:IsDescendantOf(game.Workspace) then
            local model = target:FindFirstAncestorOfClass("Model") or target
            
            Interface._selectedModel = model
            modelText.Text = "✅ " .. model.Name
            modelText.TextColor3 = theme.Success
            Animations.Tween(modelStroke, {Color = theme.Success}, 0.2)
            
            if Interface._api and Interface._api.Logger then
                Interface._api.Logger.Info("Model selected: " .. model:GetFullName())
            end
            
            connection:Disconnect()
        end
    end)
    
    -- Timeout
    task.delay(30, function()
        if connection and connection.Connected then
            connection:Disconnect()
            
            if not Interface._selectedModel then
                modelText.Text = "❌ Hết thời gian"
                modelText.TextColor3 = theme.Error
                Animations.Tween(modelStroke, {Color = theme.Error}, 0.2)
                
                task.wait(2)
                modelText.Text = "Chưa chọn model..."
                modelText.TextColor3 = theme.TextMuted
                Animations.Tween(modelStroke, {Color = theme.Border}, 0.2)
            end
        end
    end)
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// SAVE EXECUTION
--// ═══════════════════════════════════════════════════════════════════════════════════

function Interface.ExecuteSave()
    if Interface._isSaving then return end
    
    local theme = Interface.CurrentTheme
    local mode = Interface._selectedMode
    local fileName = Interface._elements.FileInput.Text
    
    -- Validate model mode
    if mode == "Model" and not Interface._selectedModel then
        Interface._elements.ModelText.Text = "❌ Chọn model trước!"
        Interface._elements.ModelText.TextColor3 = theme.Error
        Animations.Shake(Interface._elements.ModelSection, 5, 0.3)
        
        task.wait(2)
        Interface._elements.ModelText.Text = "Chưa chọn model..."
        Interface._elements.ModelText.TextColor3 = theme.TextMuted
        return
    end
    
    Interface._isSaving = true
    
    -- Update UI
    Interface._elements.ProgressSection.Visible = true
    Interface._elements.SaveText.Text = "SAVING..."
    Animations.Tween(Interface._elements.SaveButton, {BackgroundColor3 = theme.TextMuted}, 0.2)
    
    -- Prepare options
    local options = {}
    if mode == "Model" then
        options.Object = Interface._selectedModel
    end
    
    -- Execute save via API
    if Interface._api and Interface._api.Save then
        Interface._api.Save.Execute(mode, fileName, options, {
            onStart = function()
                Interface._elements.ProgressLabel.Text = "Đang chuẩn bị..."
                Interface._elements.ProgressBar.SetProgress(0)
            end,
            
            onProgress = function(percent, status)
                Interface._elements.ProgressLabel.Text = (status or "Đang lưu...") .. " " .. percent .. "%"
                Interface._elements.ProgressBar.SetProgress(percent)
            end,
            
            onComplete = function(filePath)
                Interface._elements.ProgressLabel.Text = "✅ " .. filePath
                Interface._elements.ProgressLabel.TextColor3 = theme.Success
                Interface._elements.ProgressBar.SetProgress(100)
                
                Components.Toast("Đã lưu thành công!", "success")
                
                task.wait(3)
                Interface.ResetSaveUI()
            end,
            
            onError = function(err)
                Interface._elements.ProgressLabel.Text = "❌ " .. tostring(err)
                Interface._elements.ProgressLabel.TextColor3 = theme.Error
                
                Components.Toast("Lỗi: " .. tostring(err), "error")
                
                task.wait(3)
                Interface.ResetSaveUI()
            end
        })
    else
        -- Fallback if no API
        Interface._elements.ProgressLabel.Text = "❌ API not initialized"
        Interface._elements.ProgressLabel.TextColor3 = theme.Error
        
        task.wait(2)
        Interface.ResetSaveUI()
    end
end

function Interface.ResetSaveUI()
    local theme = Interface.CurrentTheme
    
    Interface._isSaving = false
    Interface._elements.ProgressSection.Visible = false
    Interface._elements.ProgressLabel.TextColor3 = theme.Text
    Interface._elements.ProgressBar.SetProgress(0, false)
    Interface._elements.SaveText.Text = "SAVE"
    Animations.Tween(Interface._elements.SaveButton, {BackgroundColor3 = theme.Primary}, 0.2)
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// CLIENT INFO
--// ═══════════════════════════════════════════════════════════════════════════════════

function Interface.UpdateClientInfo()
    local clientInfo = Interface._elements.ClientInfo
    if not clientInfo then return end
    
    local info = {Name = "Unknown", CanSave = false}
    
    if Interface._api and Interface._api.Save then
        info = Interface._api.Save.DetectClient()
    elseif identifyexecutor then
        info.Name = identifyexecutor() or "Unknown"
        info.CanSave = saveinstance ~= nil
    end
    
    local status = info.CanSave and "✅" or "❌"
    clientInfo.Text = status .. " " .. info.Name
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// GUI CONTROL
--// ═══════════════════════════════════════════════════════════════════════════════════

function Interface.Show()
    if not Interface._instance then
        Interface.Create()
    else
        Interface._instance.Enabled = true
        
        local mainFrame = Interface._elements.MainFrame
        if mainFrame then
            mainFrame.Position = UDim2.new(0.5, -250, -0.5, 0)
            Animations.Tween(mainFrame, {
                Position = UDim2.new(0.5, -250, 0.5, -280)
            }, 0.4, Enum.EasingStyle.Back)
        end
    end
    
    Interface._isOpen = true
    
    if Interface._api and Interface._api.Event then
        Interface._api.Event.Emit("GUIOpened")
    end
end

function Interface.Hide()
    if not Interface._instance then return end
    
    local mainFrame = Interface._elements.MainFrame
    if mainFrame then
        Animations.Tween(mainFrame, {
            Position = UDim2.new(0.5, -250, 1.5, 0)
        }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        
        task.wait(0.35)
        Interface._instance.Enabled = false
    end
    
    Interface._isOpen = false
    
    if Interface._api and Interface._api.Event then
        Interface._api.Event.Emit("GUIClosed")
    end
end

function Interface.Close()
    Interface.Hide()
end

function Interface.Toggle()
    if Interface._isOpen then
        Interface.Hide()
    else
        Interface.Show()
    end
end

function Interface.Minimize()
    local mainFrame = Interface._elements.MainFrame
    if not mainFrame then return end
    
    if Interface._isMinimized then
        Animations.Tween(mainFrame, {Size = UDim2.new(0, 500, 0, 560)}, 0.3)
        Interface._isMinimized = false
    else
        Animations.Tween(mainFrame, {Size = UDim2.new(0, 500, 0, 55)}, 0.3)
        Interface._isMinimized = true
    end
end

function Interface.Destroy()
    -- Disconnect all connections
    for _, connection in pairs(Interface._connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    Interface._connections = {}
    
    -- Destroy GUI
    if Interface._instance then
        Interface._instance:Destroy()
        Interface._instance = nil
    end
    
    Interface._isOpen = false
    Interface._elements = {}
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// THEME APPLICATION
--// ═══════════════════════════════════════════════════════════════════════════════════

function Interface.ApplyTheme()
    -- Re-create GUI with new theme
    if Interface._isOpen then
        Interface.Destroy()
        Interface.Create()
    end
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// INITIALIZATION
--// ═══════════════════════════════════════════════════════════════════════════════════

function Interface.Init(api)
    Interface._api = api
    
    -- Setup keybind
    local keybind = Enum.KeyCode.RightShift
    if api and api.Config then
        keybind = api.Config.Get("GUI.Keybind", Enum.KeyCode.RightShift)
    end
    
    local keyConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == keybind then
            Interface.Toggle()
        end
    end)
    
    table.insert(Interface._connections, keyConnection)
    
    -- Create GUI if enabled
    local guiEnabled = true
    if api and api.Config then
        guiEnabled = api.Config.Get("GUI.Enabled", true)
    end
    
    if guiEnabled then
        Interface.Create()
    end
    
    return Interface
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// UTILITY FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════════════

function Interface.GetElement(name)
    return Interface._elements[name]
end

function Interface.IsOpen()
    return Interface._isOpen
end

function Interface.IsSaving()
    return Interface._isSaving
end

function Interface.GetSelectedMode()
    return Interface._selectedMode
end

function Interface.GetSelectedModel()
    return Interface._selectedModel
end

function Interface.Notify(message, type, duration)
    return Components.Toast(message, type, duration)
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// RETURN MODULE
--// ═══════════════════════════════════════════════════════════════════════════════════

return Interface
