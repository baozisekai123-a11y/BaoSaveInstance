--[[
    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║                         BaoSaveInstance Ultimate v2.0                        ║
    ║              Advanced Game Decompiler & Exporter with Modern UI              ║
    ╠══════════════════════════════════════════════════════════════════════════════╣
    ║  Features:                                                                    ║
    ║    • Full Game Export with Scripts & Terrain                                 ║
    ║    • Model-Only Export                                                       ║
    ║    • Terrain-Only Export                                                     ║
    ║    • Custom Service Selection                                                ║
    ║    • Blacklist/Whitelist System                                              ║
    ║    • Real-time Progress Tracking                                             ║
    ║    • Beautiful Modern UI with Animations                                     ║
    ╚══════════════════════════════════════════════════════════════════════════════╝
]]

--------------------------------------------------------------------------------
-- SERVICES
--------------------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------

local Config = {
    -- UI Settings
    UI = {
        Title = "BaoSaveInstance",
        Version = "2.0 Ultimate",
        Author = "Bao",
        
        -- Colors
        Colors = {
            Primary = Color3.fromRGB(99, 102, 241),      -- Indigo
            PrimaryDark = Color3.fromRGB(79, 70, 229),   -- Darker Indigo
            PrimaryLight = Color3.fromRGB(129, 140, 248), -- Lighter Indigo
            
            Secondary = Color3.fromRGB(236, 72, 153),    -- Pink
            SecondaryDark = Color3.fromRGB(219, 39, 119),
            
            Accent = Color3.fromRGB(34, 211, 238),       -- Cyan
            AccentDark = Color3.fromRGB(6, 182, 212),
            
            Success = Color3.fromRGB(34, 197, 94),       -- Green
            Warning = Color3.fromRGB(250, 204, 21),      -- Yellow
            Error = Color3.fromRGB(239, 68, 68),         -- Red
            Info = Color3.fromRGB(59, 130, 246),         -- Blue
            
            Background = Color3.fromRGB(15, 15, 25),     -- Very Dark
            BackgroundSecondary = Color3.fromRGB(22, 22, 35),
            BackgroundTertiary = Color3.fromRGB(30, 30, 45),
            
            Surface = Color3.fromRGB(35, 35, 55),
            SurfaceHover = Color3.fromRGB(45, 45, 70),
            SurfaceActive = Color3.fromRGB(55, 55, 85),
            
            Border = Color3.fromRGB(55, 55, 80),
            BorderHover = Color3.fromRGB(99, 102, 241),
            
            Text = Color3.fromRGB(255, 255, 255),
            TextSecondary = Color3.fromRGB(156, 163, 175),
            TextMuted = Color3.fromRGB(107, 114, 128),
            
            Shadow = Color3.fromRGB(0, 0, 0),
        },
        
        -- Fonts
        Fonts = {
            Title = Enum.Font.GothamBold,
            Heading = Enum.Font.GothamSemibold,
            Body = Enum.Font.GothamMedium,
            Code = Enum.Font.Code,
        },
        
        -- Sizing
        WindowSize = UDim2.new(0, 700, 0, 550),
        CornerRadius = UDim.new(0, 12),
        Padding = 16,
        
        -- Animation
        TweenSpeed = 0.25,
        TweenStyle = Enum.EasingStyle.Quint,
        TweenDirection = Enum.EasingDirection.Out,
    },
    
    -- Export Settings
    Export = {
        OutputFormat = "rbxlx",
        OutputFolder = "BaoSaveInstance",
        DecompileScripts = true,
        DecompileTimeout = 10,
        IncludeTerrain = true,
        IncludeCamera = false,
        PreserveDisabled = true,
        MaxRetries = 3,
        YieldInterval = 50,
        
        ServicesToExport = {
            { Name = "Workspace", Enabled = true, Icon = "🌍" },
            { Name = "Lighting", Enabled = true, Icon = "💡" },
            { Name = "ReplicatedFirst", Enabled = true, Icon = "📦" },
            { Name = "ReplicatedStorage", Enabled = true, Icon = "📁" },
            { Name = "ServerScriptService", Enabled = true, Icon = "📜" },
            { Name = "ServerStorage", Enabled = true, Icon = "🗄️" },
            { Name = "StarterGui", Enabled = true, Icon = "🖼️" },
            { Name = "StarterPack", Enabled = true, Icon = "🎒" },
            { Name = "StarterPlayer", Enabled = true, Icon = "👤" },
            { Name = "SoundService", Enabled = true, Icon = "🔊" },
            { Name = "Chat", Enabled = false, Icon = "💬" },
            { Name = "Teams", Enabled = false, Icon = "👥" },
            { Name = "MaterialService", Enabled = true, Icon = "🎨" },
        },
        
        Blacklist = {
            ClassNames = {"Player", "PlayerGui", "PlayerScripts", "Backpack"},
            InstanceNames = {},
        },
    },
}

--------------------------------------------------------------------------------
-- STATE MANAGEMENT
--------------------------------------------------------------------------------

local State = {
    -- UI State
    IsOpen = true,
    IsDragging = false,
    DragStart = nil,
    StartPos = nil,
    CurrentTab = "Home",
    IsMinimized = false,
    
    -- Export State
    IsExporting = false,
    ExportMode = nil,
    Progress = 0,
    CurrentOperation = "",
    TotalInstances = 0,
    ProcessedInstances = 0,
    StartTime = 0,
    
    -- Logs
    Logs = {},
    MaxLogs = 100,
    
    -- Stats
    Stats = {
        TotalExports = 0,
        SuccessfulExports = 0,
        FailedExports = 0,
        TotalInstances = 0,
    }
}

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

local Utility = {}

function Utility.Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

function Utility.Tween(object, properties, duration, style, direction)
    duration = duration or Config.UI.TweenSpeed
    style = style or Config.UI.TweenStyle
    direction = direction or Config.UI.TweenDirection
    
    local tween = TweenService:Create(object, TweenInfo.new(duration, style, direction), properties)
    tween:Play()
    return tween
end

function Utility.AddCorner(parent, radius)
    return Utility.Create("UICorner", {
        CornerRadius = radius or Config.UI.CornerRadius,
        Parent = parent
    })
end

function Utility.AddStroke(parent, color, thickness, transparency)
    return Utility.Create("UIStroke", {
        Color = color or Config.UI.Colors.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        Parent = parent
    })
end

function Utility.AddPadding(parent, padding)
    padding = padding or Config.UI.Padding
    return Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, padding),
        PaddingBottom = UDim.new(0, padding),
        PaddingLeft = UDim.new(0, padding),
        PaddingRight = UDim.new(0, padding),
        Parent = parent
    })
end

function Utility.AddGradient(parent, colors, rotation)
    local colorSequence = {}
    for i, color in ipairs(colors) do
        table.insert(colorSequence, ColorSequenceKeypoint.new((i-1)/(#colors-1), color))
    end
    
    return Utility.Create("UIGradient", {
        Color = ColorSequence.new(colorSequence),
        Rotation = rotation or 45,
        Parent = parent
    })
end

function Utility.AddShadow(parent, size, transparency)
    local shadow = Utility.Create("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Config.UI.Colors.Shadow,
        ImageTransparency = transparency or 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Size = UDim2.new(1, size or 30, 1, size or 30),
        Position = UDim2.new(0, -(size or 30)/2, 0, -(size or 30)/2),
        ZIndex = parent.ZIndex - 1,
        Parent = parent
    })
    return shadow
end

function Utility.Ripple(button, x, y)
    local ripple = Utility.Create("Frame", {
        Name = "Ripple",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Position = UDim2.new(0, x - button.AbsolutePosition.X, 0, y - button.AbsolutePosition.Y),
        Size = UDim2.new(0, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = button.ZIndex + 1,
        Parent = button
    })
    
    Utility.AddCorner(ripple, UDim.new(1, 0))
    
    local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    
    Utility.Tween(ripple, {
        Size = UDim2.new(0, size, 0, size),
        BackgroundTransparency = 1
    }, 0.5)
    
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

function Utility.FormatTime(seconds)
    if seconds < 60 then
        return string.format("%.1fs", seconds)
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds/60), seconds % 60)
    else
        return string.format("%dh %dm", math.floor(seconds/3600), math.floor((seconds%3600)/60))
    end
end

function Utility.FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num/1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num/1000)
    else
        return tostring(num)
    end
end

function Utility.GetGameName()
    local success, result = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)
    
    if success and result then
        result = string.gsub(result, "[^%w%s%-_]", "")
        result = string.gsub(result, "%s+", "_")
        return result
    end
    
    return "Unknown_Game"
end

--------------------------------------------------------------------------------
-- LOGGING SYSTEM
--------------------------------------------------------------------------------

local Logger = {}

function Logger.Add(level, message, icon)
    local log = {
        Time = os.date("%H:%M:%S"),
        Level = level,
        Message = message,
        Icon = icon or "📝",
        Color = ({
            INFO = Config.UI.Colors.Info,
            SUCCESS = Config.UI.Colors.Success,
            WARNING = Config.UI.Colors.Warning,
            ERROR = Config.UI.Colors.Error,
            DEBUG = Config.UI.Colors.TextMuted,
            PROGRESS = Config.UI.Colors.Accent,
        })[level] or Config.UI.Colors.Text
    }
    
    table.insert(State.Logs, 1, log)
    
    if #State.Logs > State.MaxLogs then
        table.remove(State.Logs)
    end
    
    -- Update console if exists
    if Logger.OnLog then
        Logger.OnLog(log)
    end
end

function Logger.Info(message) Logger.Add("INFO", message, "ℹ️") end
function Logger.Success(message) Logger.Add("SUCCESS", message, "✅") end
function Logger.Warning(message) Logger.Add("WARNING", message, "⚠️") end
function Logger.Error(message) Logger.Add("ERROR", message, "❌") end
function Logger.Debug(message) Logger.Add("DEBUG", message, "🔧") end
function Logger.Progress(message) Logger.Add("PROGRESS", message, "⏳") end

function Logger.Clear()
    State.Logs = {}
    if Logger.OnClear then
        Logger.OnClear()
    end
end

--------------------------------------------------------------------------------
-- XML SERIALIZATION ENGINE
--------------------------------------------------------------------------------

local XMLSerializer = {}

local function EscapeXML(str)
    if type(str) ~= "string" then str = tostring(str) end
    str = string.gsub(str, "&", "&amp;")
    str = string.gsub(str, "<", "&lt;")
    str = string.gsub(str, ">", "&gt;")
    str = string.gsub(str, '"', "&quot;")
    str = string.gsub(str, "'", "&apos;")
    str = string.gsub(str, "[\x00-\x08\x0B\x0C\x0E-\x1F]", "")
    return str
end

local function EncodeBase64(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x) 
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
        return b:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

local PropertySerializers = {}

PropertySerializers["string"] = function(value)
    return string.format("<string>%s</string>", EscapeXML(value))
end

PropertySerializers["number"] = function(value)
    if value == math.huge then return "<float>INF</float>"
    elseif value == -math.huge then return "<float>-INF</float>"
    elseif value ~= value then return "<float>NAN</float>"
    else return string.format("<float>%s</float>", tostring(value)) end
end

PropertySerializers["boolean"] = function(value)
    return string.format("<bool>%s</bool>", value and "true" or "false")
end

PropertySerializers["Vector3"] = function(value)
    return string.format("<Vector3><X>%s</X><Y>%s</Y><Z>%s</Z></Vector3>", value.X, value.Y, value.Z)
end

PropertySerializers["Vector2"] = function(value)
    return string.format("<Vector2><X>%s</X><Y>%s</Y></Vector2>", value.X, value.Y)
end

PropertySerializers["CFrame"] = function(value)
    local c = {value:GetComponents()}
    return string.format("<CoordinateFrame><X>%s</X><Y>%s</Y><Z>%s</Z><R00>%s</R00><R01>%s</R01><R02>%s</R02><R10>%s</R10><R11>%s</R11><R12>%s</R12><R20>%s</R20><R21>%s</R21><R22>%s</R22></CoordinateFrame>", unpack(c))
end

PropertySerializers["Color3"] = function(value)
    return string.format("<Color3><R>%s</R><G>%s</G><B>%s</B></Color3>", value.R, value.G, value.B)
end

PropertySerializers["BrickColor"] = function(value)
    return string.format("<int>%d</int>", value.Number)
end

PropertySerializers["UDim"] = function(value)
    return string.format("<UDim><S>%s</S><O>%d</O></UDim>", value.Scale, value.Offset)
end

PropertySerializers["UDim2"] = function(value)
    return string.format("<UDim2><XS>%s</XS><XO>%d</XO><YS>%s</YS><YO>%d</YO></UDim2>", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
end

PropertySerializers["Rect"] = function(value)
    return string.format("<Rect2D><min><X>%s</X><Y>%s</Y></min><max><X>%s</X><Y>%s</Y></max></Rect2D>", value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)
end

PropertySerializers["NumberSequence"] = function(value)
    local kps = {}
    for _, kp in ipairs(value.Keypoints) do
        table.insert(kps, string.format("%s %s %s", kp.Time, kp.Value, kp.Envelope))
    end
    return string.format("<NumberSequence>%s</NumberSequence>", table.concat(kps, " "))
end

PropertySerializers["ColorSequence"] = function(value)
    local kps = {}
    for _, kp in ipairs(value.Keypoints) do
        table.insert(kps, string.format("%s %s %s %s 0", kp.Time, kp.Value.R, kp.Value.G, kp.Value.B))
    end
    return string.format("<ColorSequence>%s</ColorSequence>", table.concat(kps, " "))
end

PropertySerializers["NumberRange"] = function(value)
    return string.format("<NumberRange>%s %s</NumberRange>", value.Min, value.Max)
end

PropertySerializers["EnumItem"] = function(value)
    return string.format("<token>%d</token>", value.Value)
end

PropertySerializers["Instance"] = function(value, refMap)
    if value and refMap and refMap[value] then
        return string.format("<Ref>%s</Ref>", refMap[value])
    end
    return "<Ref>null</Ref>"
end

PropertySerializers["Content"] = function(value)
    return string.format("<Content><url>%s</url></Content>", EscapeXML(tostring(value)))
end

PropertySerializers["PhysicalProperties"] = function(value)
    if value then
        return string.format("<PhysicalProperties><CustomPhysics>true</CustomPhysics><Density>%s</Density><Friction>%s</Friction><Elasticity>%s</Elasticity><FrictionWeight>%s</FrictionWeight><ElasticityWeight>%s</ElasticityWeight></PhysicalProperties>", 
            value.Density, value.Friction, value.Elasticity, value.FrictionWeight, value.ElasticityWeight)
    end
    return "<PhysicalProperties><CustomPhysics>false</CustomPhysics></PhysicalProperties>"
end

function XMLSerializer.SerializeProperty(name, value, refMap)
    if value == nil then return nil end
    local valueType = typeof(value)
    local serializer = PropertySerializers[valueType]
    if serializer then
        if valueType == "Instance" then
            return string.format('<Item name="%s">%s</Item>', name, serializer(value, refMap))
        else
            return string.format('<Item name="%s">%s</Item>', name, serializer(value))
        end
    elseif valueType ~= "table" and valueType ~= "function" then
        return string.format('<Item name="%s"><string>%s</string></Item>', name, EscapeXML(tostring(value)))
    end
    return nil
end

--------------------------------------------------------------------------------
-- INSTANCE SERIALIZATION
--------------------------------------------------------------------------------

local InstanceSerializer = {}

local PropertiesToIgnore = {
    "Parent", "DataCost", "RobloxLocked", "Archivable", "ClassName", "className", "archivable"
}

local PropertiesToIgnoreSet = {}
for _, prop in ipairs(PropertiesToIgnore) do PropertiesToIgnoreSet[prop] = true end

local function GetInstanceProperties(instance)
    local properties = {}
    
    local success, props = pcall(function()
        if getproperties then return getproperties(instance)
        elseif gethiddenproperties then
            local visible = getproperties and getproperties(instance) or {}
            local hidden = gethiddenproperties(instance)
            for k, v in pairs(hidden) do visible[k] = v end
            return visible
        end
        return nil
    end)
    
    if success and props then
        for propName, propValue in pairs(props) do
            if not PropertiesToIgnoreSet[propName] then
                properties[propName] = propValue
            end
        end
    else
        local commonProps = {
            "Name", "Position", "Size", "CFrame", "Color", "BrickColor", "Material",
            "Transparency", "Reflectance", "Anchored", "CanCollide", "Shape",
            "TopSurface", "BottomSurface", "Velocity", "Locked", "Massless",
            "Text", "TextColor3", "TextSize", "Font", "TextScaled", "TextWrapped",
            "BackgroundColor3", "BackgroundTransparency", "BorderColor3",
            "Image", "ImageColor3", "ImageTransparency", "ScaleType",
            "SoundId", "Volume", "PlaybackSpeed", "Looped", "Playing",
            "MeshId", "TextureId", "Scale", "Offset", "VertexColor",
            "Brightness", "Range", "Shadows", "Enabled", "Face",
            "Source", "LinkedSource", "Disabled", "Value", "MaxValue", "MinValue",
            "C0", "C1", "Part0", "Part1", "Attachment0", "Attachment1"
        }
        
        for _, propName in ipairs(commonProps) do
            local propSuccess, propValue = pcall(function() return instance[propName] end)
            if propSuccess and propValue ~= nil then properties[propName] = propValue end
        end
    end
    
    return properties
end

local function CreateRefId()
    return "RBX" .. HttpService:GenerateGUID(false):gsub("-", "")
end

function InstanceSerializer.BuildRefMap(instances)
    local refMap = {}
    for _, instance in ipairs(instances) do
        refMap[instance] = CreateRefId()
    end
    return refMap
end

function InstanceSerializer.Serialize(instance, refMap, depth)
    depth = depth or 0
    local indent = string.rep("  ", depth)
    local className = instance.ClassName
    local refId = refMap[instance] or CreateRefId()
    
    local lines = {}
    table.insert(lines, string.format('%s<Item class="%s" referent="%s">', indent, className, refId))
    table.insert(lines, string.format('%s  <Properties>', indent))
    table.insert(lines, string.format('%s    <string name="Name">%s</string>', indent, EscapeXML(instance.Name)))
    
    local properties = GetInstanceProperties(instance)
    for propName, propValue in pairs(properties) do
        if propName ~= "Name" then
            local serialized = XMLSerializer.SerializeProperty(propName, propValue, refMap)
            if serialized then
                table.insert(lines, string.format('%s    %s', indent, serialized))
            end
        end
    end
    
    table.insert(lines, string.format('%s  </Properties>', indent))
    
    local children = instance:GetChildren()
    for i, child in ipairs(children) do
        local childXml = InstanceSerializer.Serialize(child, refMap, depth + 1)
        if childXml then table.insert(lines, childXml) end
        if i % Config.Export.YieldInterval == 0 then RunService.Heartbeat:Wait() end
    end
    
    table.insert(lines, string.format('%s</Item>', indent))
    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- TERRAIN SERIALIZATION
--------------------------------------------------------------------------------

local TerrainSerializer = {}

function TerrainSerializer.Serialize()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return nil end
    
    Logger.Progress("Serializing terrain data...")
    
    local success, terrainData = pcall(function()
        local data = {}
        data.WaterWaveSize = terrain.WaterWaveSize
        data.WaterWaveSpeed = terrain.WaterWaveSpeed
        data.WaterReflectance = terrain.WaterReflectance
        data.WaterTransparency = terrain.WaterTransparency
        data.WaterColor = {R = terrain.WaterColor.R, G = terrain.WaterColor.G, B = terrain.WaterColor.B}
        return data
    end)
    
    if not success then
        Logger.Error("Failed to read terrain: " .. tostring(terrainData))
        return nil
    end
    
    return terrainData
end

function TerrainSerializer.CreateXML(terrainData)
    if not terrainData then return "" end
    
    return string.format([[<Item class="Terrain" referent="RBXTerrain">
  <Properties>
    <string name="Name">Terrain</string>
    <float name="WaterWaveSize">%s</float>
    <float name="WaterWaveSpeed">%s</float>
    <float name="WaterReflectance">%s</float>
    <float name="WaterTransparency">%s</float>
    <Color3 name="WaterColor"><R>%s</R><G>%s</G><B>%s</B></Color3>
  </Properties>
</Item>]], 
        terrainData.WaterWaveSize or 0.15,
        terrainData.WaterWaveSpeed or 10,
        terrainData.WaterReflectance or 1,
        terrainData.WaterTransparency or 0.3,
        terrainData.WaterColor and terrainData.WaterColor.R or 0.35,
        terrainData.WaterColor and terrainData.WaterColor.G or 0.45,
        terrainData.WaterColor and terrainData.WaterColor.B or 0.55)
end

--------------------------------------------------------------------------------
-- EXPORT ENGINE
--------------------------------------------------------------------------------

local Exporter = {}

function Exporter.GenerateFileName(mode)
    local gameName = Utility.GetGameName()
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local prefix = ({
        FullGame = "FullGame",
        FullModel = "Models",
        Terrain = "Terrain"
    })[mode] or "Export"
    
    return string.format("%s/BaoSaveInstance_%s_%s_%s.%s", 
        Config.Export.OutputFolder, prefix, gameName, timestamp, Config.Export.OutputFormat)
end

function Exporter.ShouldInclude(instance, mode)
    -- Check blacklist
    for _, className in ipairs(Config.Export.Blacklist.ClassNames) do
        if instance:IsA(className) then return false end
    end
    
    for _, name in ipairs(Config.Export.Blacklist.InstanceNames) do
        if instance.Name == name then return false end
    end
    
    -- Mode specific
    if mode == "FullModel" then
        if instance:IsA("LuaSourceContainer") or instance:IsA("Terrain") then return false end
    elseif mode == "Terrain" then
        if not instance:IsA("Terrain") and instance ~= workspace then return false end
    end
    
    return true
end

function Exporter.CollectInstances(roots, mode)
    local instances = {}
    local counter = 0
    
    local function collect(instance)
        counter = counter + 1
        if counter % Config.Export.YieldInterval == 0 then RunService.Heartbeat:Wait() end
        if not Exporter.ShouldInclude(instance, mode) then return end
        table.insert(instances, instance)
        for _, child in ipairs(instance:GetChildren()) do collect(child) end
    end
    
    for _, root in ipairs(roots) do
        Logger.Info("Collecting from: " .. root:GetFullName())
        collect(root)
    end
    
    return instances
end

function Exporter.GenerateXML(content)
    return [[<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
    <Meta name="ExplicitAutoJoints">true</Meta>
]] .. content .. [[
</roblox>]]
end

function Exporter.WriteFile(content, fileName)
    local success, err = pcall(function()
        if makefolder and not isfolder(Config.Export.OutputFolder) then
            makefolder(Config.Export.OutputFolder)
        end
    end)
    
    local writeSuccess, writeErr = pcall(function()
        if writefile then
            writefile(fileName, content)
        else
            error("writefile not available")
        end
    end)
    
    return writeSuccess, writeErr
end

function Exporter.TryNativeSaveInstance(options)
    if not saveinstance then return false, "saveinstance not available" end
    
    local success, result = pcall(function()
        saveinstance(options)
    end)
    
    return success, result
end

function Exporter.Export(mode, progressCallback)
    State.IsExporting = true
    State.ExportMode = mode
    State.Progress = 0
    State.StartTime = tick()
    State.ProcessedInstances = 0
    
    local fileName = Exporter.GenerateFileName(mode)
    
    Logger.Info("Starting " .. mode .. " export...")
    Logger.Info("Output: " .. fileName)
    
    if progressCallback then progressCallback(0, "Initializing...") end
    
    -- Try native saveinstance first
    local nativeOptions = {
        FileName = fileName,
        DecompileMode = Config.Export.DecompileScripts and "decompile" or "ignore",
        DecompileTimeout = Config.Export.DecompileTimeout,
        NilInstances = false,
        RemovePlayerCharacters = true,
    }
    
    if mode == "FullModel" then
        nativeOptions.DecompileMode = "ignore"
    end
    
    local nativeSuccess, nativeResult = Exporter.TryNativeSaveInstance(nativeOptions)
    
    if nativeSuccess then
        Logger.Success("Export completed using native saveinstance!")
        State.IsExporting = false
        State.Stats.TotalExports = State.Stats.TotalExports + 1
        State.Stats.SuccessfulExports = State.Stats.SuccessfulExports + 1
        if progressCallback then progressCallback(100, "Complete!") end
        return true, fileName
    end
    
    Logger.Info("Using custom serialization...")
    if progressCallback then progressCallback(5, "Collecting instances...") end
    
    -- Custom serialization
    local xmlContent = {}
    local allInstances = {}
    
    if mode == "FullGame" then
        for _, serviceData in ipairs(Config.Export.ServicesToExport) do
            if serviceData.Enabled then
                local success, service = pcall(function()
                    return game:GetService(serviceData.Name)
                end)
                
                if success and service then
                    local instances = Exporter.CollectInstances({service}, mode)
                    for _, inst in ipairs(instances) do
                        table.insert(allInstances, inst)
                    end
                end
            end
        end
    elseif mode == "FullModel" then
        allInstances = Exporter.CollectInstances({workspace}, mode)
    elseif mode == "Terrain" then
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then table.insert(allInstances, terrain) end
    end
    
    State.TotalInstances = #allInstances
    Logger.Info("Collected " .. State.TotalInstances .. " instances")
    
    if progressCallback then progressCallback(20, "Building references...") end
    local refMap = InstanceSerializer.BuildRefMap(allInstances)
    
    if progressCallback then progressCallback(30, "Serializing...") end
    
    -- Serialize
    if mode == "FullGame" then
        for i, serviceData in ipairs(Config.Export.ServicesToExport) do
            if serviceData.Enabled then
                local success, service = pcall(function()
                    return game:GetService(serviceData.Name)
                end)
                
                if success and service then
                    Logger.Progress("Serializing " .. serviceData.Name .. "...")
                    
                    local serviceXml = {}
                    table.insert(serviceXml, string.format('<Item class="%s" referent="%s">', service.ClassName, CreateRefId()))
                    table.insert(serviceXml, '  <Properties>')
                    table.insert(serviceXml, string.format('    <string name="Name">%s</string>', service.ClassName))
                    table.insert(serviceXml, '  </Properties>')
                    
                    for _, child in ipairs(service:GetChildren()) do
                        if Exporter.ShouldInclude(child, mode) then
                            local childXml = InstanceSerializer.Serialize(child, refMap, 1)
                            if childXml then table.insert(serviceXml, childXml) end
                        end
                    end
                    
                    table.insert(serviceXml, '</Item>')
                    table.insert(xmlContent, table.concat(serviceXml, "\n"))
                end
                
                local progress = 30 + (i / #Config.Export.ServicesToExport) * 50
                if progressCallback then progressCallback(progress, "Serializing " .. serviceData.Name .. "...") end
            end
        end
        
    elseif mode == "FullModel" then
        table.insert(xmlContent, '<Item class="Workspace" referent="RBXWorkspace">')
        table.insert(xmlContent, '  <Properties><string name="Name">Workspace</string></Properties>')
        
        for i, instance in ipairs(allInstances) do
            if instance.Parent == workspace then
                local instanceXml = InstanceSerializer.Serialize(instance, refMap, 1)
                if instanceXml then table.insert(xmlContent, instanceXml) end
            end
            State.ProcessedInstances = i
            if i % 50 == 0 then
                local progress = 30 + (i / #allInstances) * 50
                if progressCallback then progressCallback(progress, "Serializing models...") end
            end
        end
        
        table.insert(xmlContent, '</Item>')
        
    elseif mode == "Terrain" then
        local terrainData = TerrainSerializer.Serialize()
        if terrainData then
            table.insert(xmlContent, '<Item class="Workspace" referent="RBXWorkspace">')
            table.insert(xmlContent, '  <Properties><string name="Name">Workspace</string></Properties>')
            table.insert(xmlContent, TerrainSerializer.CreateXML(terrainData))
            table.insert(xmlContent, '</Item>')
        end
    end
    
    if progressCallback then progressCallback(85, "Generating file...") end
    
    local finalXml = Exporter.GenerateXML(table.concat(xmlContent, "\n"))
    
    if progressCallback then progressCallback(90, "Writing file...") end
    
    local writeSuccess, writeErr = Exporter.WriteFile(finalXml, fileName)
    
    local elapsed = tick() - State.StartTime
    State.IsExporting = false
    State.Stats.TotalExports = State.Stats.TotalExports + 1
    
    if writeSuccess then
        State.Stats.SuccessfulExports = State.Stats.SuccessfulExports + 1
        State.Stats.TotalInstances = State.Stats.TotalInstances + State.TotalInstances
        Logger.Success(string.format("Export completed in %s!", Utility.FormatTime(elapsed)))
        if progressCallback then progressCallback(100, "Complete!") end
        return true, fileName
    else
        State.Stats.FailedExports = State.Stats.FailedExports + 1
        Logger.Error("Export failed: " .. tostring(writeErr))
        if progressCallback then progressCallback(100, "Failed!") end
        return false, writeErr
    end
end

--------------------------------------------------------------------------------
-- UI COMPONENTS
--------------------------------------------------------------------------------

local Components = {}

function Components.CreateButton(props)
    local button = Utility.Create("TextButton", {
        Name = props.Name or "Button",
        Size = props.Size or UDim2.new(0, 120, 0, 40),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = props.Color or Config.UI.Colors.Primary,
        BorderSizePixel = 0,
        Text = props.Text or "Button",
        TextColor3 = props.TextColor or Config.UI.Colors.Text,
        Font = props.Font or Config.UI.Fonts.Body,
        TextSize = props.TextSize or 14,
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = props.Parent
    })
    
    Utility.AddCorner(button, props.CornerRadius)
    
    if props.Gradient then
        Utility.AddGradient(button, {props.Color or Config.UI.Colors.Primary, props.GradientEnd or Config.UI.Colors.PrimaryDark}, props.GradientRotation or 45)
    end
    
    if props.Stroke then
        Utility.AddStroke(button, props.StrokeColor or Config.UI.Colors.Border)
    end
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        Utility.Tween(button, {BackgroundColor3 = props.HoverColor or Config.UI.Colors.PrimaryLight}, 0.15)
    end)
    
    button.MouseLeave:Connect(function()
        Utility.Tween(button, {BackgroundColor3 = props.Color or Config.UI.Colors.Primary}, 0.15)
    end)
    
    -- Click effect
    button.MouseButton1Down:Connect(function()
        Utility.Tween(button, {Size = props.Size and UDim2.new(props.Size.X.Scale * 0.95, props.Size.X.Offset * 0.95, props.Size.Y.Scale * 0.95, props.Size.Y.Offset * 0.95) or UDim2.new(0, 114, 0, 38)}, 0.1)
    end)
    
    button.MouseButton1Up:Connect(function()
        Utility.Tween(button, {Size = props.Size or UDim2.new(0, 120, 0, 40)}, 0.1)
    end)
    
    button.MouseButton1Click:Connect(function()
        Utility.Ripple(button, Mouse.X, Mouse.Y)
        if props.Callback then props.Callback() end
    end)
    
    return button
end

function Components.CreateToggle(props)
    local container = Utility.Create("Frame", {
        Name = props.Name or "Toggle",
        Size = props.Size or UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Config.UI.Colors.Surface,
        BorderSizePixel = 0,
        Parent = props.Parent
    })
    
    Utility.AddCorner(container, UDim.new(0, 8))
    
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = props.Text or "Toggle",
        TextColor3 = Config.UI.Colors.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Config.UI.Fonts.Body,
        TextSize = 14,
        Parent = container
    })
    
    local toggleBtn = Utility.Create("Frame", {
        Name = "ToggleButton",
        Size = UDim2.new(0, 44, 0, 24),
        Position = UDim2.new(1, -56, 0.5, -12),
        BackgroundColor3 = props.Value and Config.UI.Colors.Primary or Config.UI.Colors.BackgroundTertiary,
        BorderSizePixel = 0,
        Parent = container
    })
    
    Utility.AddCorner(toggleBtn, UDim.new(1, 0))
    
    local knob = Utility.Create("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 20, 0, 20),
        Position = props.Value and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = toggleBtn
    })
    
    Utility.AddCorner(knob, UDim.new(1, 0))
    
    local value = props.Value or false
    
    local function updateToggle()
        value = not value
        Utility.Tween(toggleBtn, {BackgroundColor3 = value and Config.UI.Colors.Primary or Config.UI.Colors.BackgroundTertiary}, 0.2)
        Utility.Tween(knob, {Position = value and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)}, 0.2)
        if props.Callback then props.Callback(value) end
    end
    
    local button = Utility.Create("TextButton", {
        Name = "ClickArea",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = container
    })
    
    button.MouseButton1Click:Connect(updateToggle)
    
    container.Value = value
    container.SetValue = function(v)
        if v ~= value then updateToggle() end
    end
    
    return container
end

function Components.CreateDropdown(props)
    local container = Utility.Create("Frame", {
        Name = props.Name or "Dropdown",
        Size = props.Size or UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Config.UI.Colors.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = props.Parent
    })
    
    Utility.AddCorner(container, UDim.new(0, 8))
    Utility.AddStroke(container, Config.UI.Colors.Border)
    
    local selected = Utility.Create("TextButton", {
        Name = "Selected",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Text = "",
        Parent = container
    })
    
    local selectedLabel = Utility.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = props.Default or props.Options[1] or "Select...",
        TextColor3 = Config.UI.Colors.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Config.UI.Fonts.Body,
        TextSize = 14,
        Parent = selected
    })
    
    local arrow = Utility.Create("TextLabel", {
        Name = "Arrow",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -30, 0, 0),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = Config.UI.Colors.TextSecondary,
        Font = Config.UI.Fonts.Body,
        TextSize = 12,
        Parent = selected
    })
    
    local optionsFrame = Utility.Create("Frame", {
        Name = "Options",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = Config.UI.Colors.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 100,
        Visible = false,
        Parent = container
    })
    
    Utility.AddCorner(optionsFrame, UDim.new(0, 8))
    Utility.AddStroke(optionsFrame, Config.UI.Colors.Border)
    
    local optionsList = Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = optionsFrame
    })
    
    Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = optionsFrame
    })
    
    local isOpen = false
    local currentValue = props.Default or props.Options[1]
    
    for i, option in ipairs(props.Options) do
        local optBtn = Utility.Create("TextButton", {
            Name = option,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Config.UI.Colors.SurfaceHover,
            BackgroundTransparency = 1,
            Text = option,
            TextColor3 = Config.UI.Colors.Text,
            Font = Config.UI.Fonts.Body,
            TextSize = 13,
            ZIndex = 101,
            LayoutOrder = i,
            Parent = optionsFrame
        })
        
        Utility.AddCorner(optBtn, UDim.new(0, 6))
        
        optBtn.MouseEnter:Connect(function()
            Utility.Tween(optBtn, {BackgroundTransparency = 0}, 0.1)
        end)
        
        optBtn.MouseLeave:Connect(function()
            Utility.Tween(optBtn, {BackgroundTransparency = 1}, 0.1)
        end)
        
        optBtn.MouseButton1Click:Connect(function()
            currentValue = option
            selectedLabel.Text = option
            isOpen = false
            Utility.Tween(optionsFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
            Utility.Tween(arrow, {Rotation = 0}, 0.2)
            task.delay(0.2, function() optionsFrame.Visible = false end)
            if props.Callback then props.Callback(option) end
        end)
    end
    
    selected.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            optionsFrame.Visible = true
            local height = math.min(#props.Options * 34 + 8, 200)
            Utility.Tween(optionsFrame, {Size = UDim2.new(1, 0, 0, height)}, 0.2)
            Utility.Tween(arrow, {Rotation = 180}, 0.2)
        else
            Utility.Tween(optionsFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
            Utility.Tween(arrow, {Rotation = 0}, 0.2)
            task.delay(0.2, function() optionsFrame.Visible = false end)
        end
    end)
    
    container.GetValue = function() return currentValue end
    
    return container
end

function Components.CreateProgressBar(props)
    local container = Utility.Create("Frame", {
        Name = props.Name or "ProgressBar",
        Size = props.Size or UDim2.new(1, 0, 0, 8),
        BackgroundColor3 = Config.UI.Colors.BackgroundTertiary,
        BorderSizePixel = 0,
        Parent = props.Parent
    })
    
    Utility.AddCorner(container, UDim.new(1, 0))
    
    local fill = Utility.Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = props.Color or Config.UI.Colors.Primary,
        BorderSizePixel = 0,
        Parent = container
    })
    
    Utility.AddCorner(fill, UDim.new(1, 0))
    
    if props.Gradient then
        Utility.AddGradient(fill, {props.Color or Config.UI.Colors.Primary, props.GradientEnd or Config.UI.Colors.Accent}, 0)
    end
    
    container.SetProgress = function(value)
        value = math.clamp(value, 0, 100)
        Utility.Tween(fill, {Size = UDim2.new(value/100, 0, 1, 0)}, 0.3)
    end
    
    container.SetProgress(props.Value or 0)
    
    return container
end

function Components.CreateCard(props)
    local card = Utility.Create("Frame", {
        Name = props.Name or "Card",
        Size = props.Size or UDim2.new(1, 0, 0, 100),
        BackgroundColor3 = props.Color or Config.UI.Colors.Surface,
        BorderSizePixel = 0,
        Parent = props.Parent
    })
    
    Utility.AddCorner(card, props.CornerRadius or UDim.new(0, 12))
    
    if props.Stroke then
        Utility.AddStroke(card, props.StrokeColor or Config.UI.Colors.Border)
    end
    
    if props.Shadow then
        Utility.AddShadow(card, 20, 0.7)
    end
    
    return card
end

function Components.CreateInput(props)
    local container = Utility.Create("Frame", {
        Name = props.Name or "Input",
        Size = props.Size or UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Config.UI.Colors.BackgroundTertiary,
        BorderSizePixel = 0,
        Parent = props.Parent
    })
    
    Utility.AddCorner(container, UDim.new(0, 8))
    
    local stroke = Utility.AddStroke(container, Config.UI.Colors.Border)
    
    local input = Utility.Create("TextBox", {
        Name = "TextBox",
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = props.Default or "",
        PlaceholderText = props.Placeholder or "Enter text...",
        PlaceholderColor3 = Config.UI.Colors.TextMuted,
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Body,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = container
    })
    
    input.Focused:Connect(function()
        Utility.Tween(stroke, {Color = Config.UI.Colors.Primary}, 0.2)
    end)
    
    input.FocusLost:Connect(function()
        Utility.Tween(stroke, {Color = Config.UI.Colors.Border}, 0.2)
        if props.Callback then props.Callback(input.Text) end
    end)
    
    container.GetValue = function() return input.Text end
    container.SetValue = function(v) input.Text = v end
    
    return container
end

function Components.CreateNotification(props)
    local colors = {
        success = Config.UI.Colors.Success,
        warning = Config.UI.Colors.Warning,
        error = Config.UI.Colors.Error,
        info = Config.UI.Colors.Info
    }
    
    local icons = {
        success = "✅",
        warning = "⚠️",
        error = "❌",
        info = "ℹ️"
    }
    
    local notif = Utility.Create("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, 300, 0, 60),
        Position = UDim2.new(1, 320, 1, -80),
        BackgroundColor3 = Config.UI.Colors.Surface,
        BorderSizePixel = 0,
        Parent = props.Parent
    })
    
    Utility.AddCorner(notif, UDim.new(0, 10))
    Utility.AddShadow(notif, 25, 0.5)
    
    local accent = Utility.Create("Frame", {
        Name = "Accent",
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = colors[props.Type] or colors.info,
        BorderSizePixel = 0,
        Parent = notif
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = accent
    })
    
    local icon = Utility.Create("TextLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(0, 15, 0.5, -15),
        BackgroundTransparency = 1,
        Text = icons[props.Type] or icons.info,
        TextSize = 20,
        Parent = notif
    })
    
    local title = Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.new(0, 50, 0, 10),
        BackgroundTransparency = 1,
        Text = props.Title or "Notification",
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Heading,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif
    })
    
    local message = Utility.Create("TextLabel", {
        Name = "Message",
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.new(0, 50, 0, 32),
        BackgroundTransparency = 1,
        Text = props.Message or "",
        TextColor3 = Config.UI.Colors.TextSecondary,
        Font = Config.UI.Fonts.Body,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = notif
    })
    
    -- Animate in
    Utility.Tween(notif, {Position = UDim2.new(1, -320, 1, -80)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    -- Auto dismiss
    task.delay(props.Duration or 4, function()
        Utility.Tween(notif, {Position = UDim2.new(1, 320, 1, -80)}, 0.3)
        task.delay(0.3, function()
            notif:Destroy()
        end)
    end)
    
    return notif
end

--------------------------------------------------------------------------------
-- MAIN UI CREATION
--------------------------------------------------------------------------------

local UI = {}

function UI.Create()
    -- Destroy existing
    if CoreGui:FindFirstChild("BaoSaveInstanceUI") then
        CoreGui:FindFirstChild("BaoSaveInstanceUI"):Destroy()
    end
    
    -- Create ScreenGui
    local screenGui = Utility.Create("ScreenGui", {
        Name = "BaoSaveInstanceUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        Parent = CoreGui
    })
    
    -- Main Window
    local mainWindow = Utility.Create("Frame", {
        Name = "MainWindow",
        Size = Config.UI.WindowSize,
        Position = UDim2.new(0.5, -350, 0.5, -275),
        BackgroundColor3 = Config.UI.Colors.Background,
        BorderSizePixel = 0,
        Parent = screenGui
    })
    
    Utility.AddCorner(mainWindow, UDim.new(0, 16))
    Utility.AddShadow(mainWindow, 40, 0.5)
    
    -- Border Gradient
    local borderFrame = Utility.Create("Frame", {
        Name = "Border",
        Size = UDim2.new(1, 4, 1, 4),
        Position = UDim2.new(0, -2, 0, -2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 0,
        Parent = mainWindow
    })
    
    Utility.AddCorner(borderFrame, UDim.new(0, 18))
    Utility.AddGradient(borderFrame, {Config.UI.Colors.Primary, Config.UI.Colors.Secondary, Config.UI.Colors.Accent}, 45)
    
    -- Inner Background (to cover gradient except border)
    local innerBg = Utility.Create("Frame", {
        Name = "InnerBackground",
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Config.UI.Colors.Background,
        BorderSizePixel = 0,
        Parent = mainWindow
    })
    
    Utility.AddCorner(innerBg, UDim.new(0, 15))
    
    -- Title Bar
    local titleBar = Utility.Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Config.UI.Colors.BackgroundSecondary,
        BorderSizePixel = 0,
        Parent = innerBg
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 14),
        Parent = titleBar
    })
    
    -- Fix bottom corners of title bar
    local titleBarFix = Utility.Create("Frame", {
        Name = "Fix",
        Size = UDim2.new(1, 0, 0, 15),
        Position = UDim2.new(0, 0, 1, -15),
        BackgroundColor3 = Config.UI.Colors.BackgroundSecondary,
        BorderSizePixel = 0,
        Parent = titleBar
    })
    
    -- Logo/Icon
    local logo = Utility.Create("TextLabel", {
        Name = "Logo",
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 12, 0.5, -20),
        BackgroundColor3 = Config.UI.Colors.Primary,
        Text = "🚀",
        TextSize = 20,
        Parent = titleBar
    })
    
    Utility.AddCorner(logo, UDim.new(0, 10))
    Utility.AddGradient(logo, {Config.UI.Colors.Primary, Config.UI.Colors.Secondary}, 135)
    
    -- Title Text
    local titleText = Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 200, 0, 20),
        Position = UDim2.new(0, 60, 0, 8),
        BackgroundTransparency = 1,
        Text = Config.UI.Title,
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Title,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })
    
    -- Version Badge
    local versionBadge = Utility.Create("TextLabel", {
        Name = "Version",
        Size = UDim2.new(0, 80, 0, 16),
        Position = UDim2.new(0, 60, 0, 30),
        BackgroundColor3 = Config.UI.Colors.Primary,
        BackgroundTransparency = 0.8,
        Text = "v" .. Config.UI.Version,
        TextColor3 = Config.UI.Colors.Primary,
        Font = Config.UI.Fonts.Body,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })
    
    Utility.AddCorner(versionBadge, UDim.new(1, 0))
    Utility.Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        Parent = versionBadge
    })
    
    -- Window Controls
    local controlsFrame = Utility.Create("Frame", {
        Name = "Controls",
        Size = UDim2.new(0, 90, 0, 30),
        Position = UDim2.new(1, -100, 0.5, -15),
        BackgroundTransparency = 1,
        Parent = titleBar
    })
    
    local controlsLayout = Utility.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        Parent = controlsFrame
    })
    
    -- Minimize Button
    local minimizeBtn = Utility.Create("TextButton", {
        Name = "Minimize",
        Size = UDim2.new(0, 26, 0, 26),
        BackgroundColor3 = Config.UI.Colors.Warning,
        Text = "─",
        TextColor3 = Color3.new(0, 0, 0),
        Font = Config.UI.Fonts.Body,
        TextSize = 14,
        Parent = controlsFrame
    })
    
    Utility.AddCorner(minimizeBtn, UDim.new(0, 8))
    
    -- Close Button
    local closeBtn = Utility.Create("TextButton", {
        Name = "Close",
        Size = UDim2.new(0, 26, 0, 26),
        BackgroundColor3 = Config.UI.Colors.Error,
        Text = "×",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Config.UI.Fonts.Body,
        TextSize = 18,
        Parent = controlsFrame
    })
    
    Utility.AddCorner(closeBtn, UDim.new(0, 8))
    
    -- Content Area
    local contentArea = Utility.Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -20, 1, -60),
        Position = UDim2.new(0, 10, 0, 55),
        BackgroundTransparency = 1,
        Parent = innerBg
    })
    
    -- Navigation Tabs
    local tabsFrame = Utility.Create("Frame", {
        Name = "Tabs",
        Size = UDim2.new(0, 150, 1, 0),
        BackgroundColor3 = Config.UI.Colors.BackgroundSecondary,
        BorderSizePixel = 0,
        Parent = contentArea
    })
    
    Utility.AddCorner(tabsFrame, UDim.new(0, 12))
    
    local tabsLayout = Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = tabsFrame
    })
    
    Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = tabsFrame
    })
    
    -- Tab Pages Container
    local pagesContainer = Utility.Create("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, -160, 1, 0),
        Position = UDim2.new(0, 160, 0, 0),
        BackgroundTransparency = 1,
        Parent = contentArea
    })
    
    -- Create Tabs
    local tabs = {
        { Name = "Home", Icon = "🏠", LayoutOrder = 1 },
        { Name = "Export", Icon = "📦", LayoutOrder = 2 },
        { Name = "Services", Icon = "⚙️", LayoutOrder = 3 },
        { Name = "Settings", Icon = "🔧", LayoutOrder = 4 },
        { Name = "Console", Icon = "📋", LayoutOrder = 5 },
        { Name = "About", Icon = "ℹ️", LayoutOrder = 6 },
    }
    
    local tabButtons = {}
    local tabPages = {}
    
    local function switchTab(tabName)
        State.CurrentTab = tabName
        
        for name, btn in pairs(tabButtons) do
            if name == tabName then
                Utility.Tween(btn, {BackgroundColor3 = Config.UI.Colors.Primary}, 0.2)
                Utility.Tween(btn:FindFirstChild("Label"), {TextColor3 = Config.UI.Colors.Text}, 0.2)
            else
                Utility.Tween(btn, {BackgroundColor3 = Config.UI.Colors.Surface}, 0.2)
                Utility.Tween(btn:FindFirstChild("Label"), {TextColor3 = Config.UI.Colors.TextSecondary}, 0.2)
            end
        end
        
        for name, page in pairs(tabPages) do
            page.Visible = (name == tabName)
        end
    end
    
    for _, tabData in ipairs(tabs) do
        local tabBtn = Utility.Create("TextButton", {
            Name = tabData.Name,
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = tabData.Name == "Home" and Config.UI.Colors.Primary or Config.UI.Colors.Surface,
            BorderSizePixel = 0,
            Text = "",
            LayoutOrder = tabData.LayoutOrder,
            Parent = tabsFrame
        })
        
        Utility.AddCorner(tabBtn, UDim.new(0, 8))
        
        local icon = Utility.Create("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 24, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = tabData.Icon,
            TextSize = 16,
            Parent = tabBtn
        })
        
        local label = Utility.Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -44, 1, 0),
            Position = UDim2.new(0, 38, 0, 0),
            BackgroundTransparency = 1,
            Text = tabData.Name,
            TextColor3 = tabData.Name == "Home" and Config.UI.Colors.Text or Config.UI.Colors.TextSecondary,
            Font = Config.UI.Fonts.Body,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = tabBtn
        })
        
        tabBtn.MouseEnter:Connect(function()
            if State.CurrentTab ~= tabData.Name then
                Utility.Tween(tabBtn, {BackgroundColor3 = Config.UI.Colors.SurfaceHover}, 0.15)
            end
        end)
        
        tabBtn.MouseLeave:Connect(function()
            if State.CurrentTab ~= tabData.Name then
                Utility.Tween(tabBtn, {BackgroundColor3 = Config.UI.Colors.Surface}, 0.15)
            end
        end)
        
        tabBtn.MouseButton1Click:Connect(function()
            switchTab(tabData.Name)
        end)
        
        tabButtons[tabData.Name] = tabBtn
        
        -- Create Page
        local page = Utility.Create("ScrollingFrame", {
            Name = tabData.Name .. "Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Config.UI.Colors.Primary,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = tabData.Name == "Home",
            Parent = pagesContainer
        })
        
        local pageLayout = Utility.Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 12),
            Parent = page
        })
        
        Utility.Create("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = page
        })
        
        tabPages[tabData.Name] = page
    end
    
    --------------------------------------------------------------------------------
    -- HOME PAGE
    --------------------------------------------------------------------------------
    
    local homePage = tabPages["Home"]
    
    -- Welcome Card
    local welcomeCard = Components.CreateCard({
        Name = "WelcomeCard",
        Size = UDim2.new(1, 0, 0, 120),
        Color = Config.UI.Colors.Surface,
        Parent = homePage
    })
    
    local welcomeGradient = Utility.Create("Frame", {
        Name = "Gradient",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = welcomeCard
    })
    
    Utility.AddCorner(welcomeGradient, UDim.new(0, 12))
    Utility.AddGradient(welcomeGradient, {Config.UI.Colors.Primary, Config.UI.Colors.Secondary}, 135)
    welcomeGradient.BackgroundTransparency = 0.85
    
    local welcomeTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -30, 0, 30),
        Position = UDim2.new(0, 15, 0, 15),
        BackgroundTransparency = 1,
        Text = "Welcome to BaoSaveInstance! 👋",
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Title,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = welcomeCard
    })
    
    local welcomeDesc = Utility.Create("TextLabel", {
        Name = "Description",
        Size = UDim2.new(1, -30, 0, 40),
        Position = UDim2.new(0, 15, 0, 45),
        BackgroundTransparency = 1,
        Text = "The most advanced game decompiler & exporter for Roblox.\nExport games, models, and terrain with ease.",
        TextColor3 = Config.UI.Colors.TextSecondary,
        Font = Config.UI.Fonts.Body,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = welcomeCard
    })
    
    -- Game Info
    local gameInfoLabel = Utility.Create("TextLabel", {
        Name = "GameInfo",
        Size = UDim2.new(1, -30, 0, 20),
        Position = UDim2.new(0, 15, 1, -30),
        BackgroundTransparency = 1,
        Text = "📍 Current Game: " .. (Utility.GetGameName() or "Unknown"),
        TextColor3 = Config.UI.Colors.Accent,
        Font = Config.UI.Fonts.Body,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = welcomeCard
    })
    
    -- Quick Actions Title
    local quickActionsTitle = Utility.Create("TextLabel", {
        Name = "QuickActionsTitle",
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = "⚡ Quick Actions",
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Heading,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        Parent = homePage
    })
    
    -- Quick Actions Grid
    local quickActionsGrid = Utility.Create("Frame", {
        Name = "QuickActionsGrid",
        Size = UDim2.new(1, 0, 0, 140),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Parent = homePage
    })
    
    local gridLayout = Utility.Create("UIGridLayout", {
        CellSize = UDim2.new(0.48, 0, 0, 60),
        CellPadding = UDim2.new(0.04, 0, 0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = quickActionsGrid
    })
    
    local quickActions = {
        { Name = "Full Game", Icon = "🎮", Desc = "Export everything", Mode = "FullGame", Color = Config.UI.Colors.Primary },
        { Name = "Models Only", Icon = "🏗️", Desc = "No scripts/terrain", Mode = "FullModel", Color = Config.UI.Colors.Secondary },
        { Name = "Terrain Only", Icon = "🏔️", Desc = "Landscape data", Mode = "Terrain", Color = Config.UI.Colors.Accent },
        { Name = "Custom Export", Icon = "⚙️", Desc = "Advanced options", Tab = "Export", Color = Config.UI.Colors.Success },
    }
    
    for i, action in ipairs(quickActions) do
        local actionCard = Components.CreateCard({
            Name = action.Name,
            Size = UDim2.new(0, 100, 0, 60),
            Color = Config.UI.Colors.Surface,
            Stroke = true,
            Parent = quickActionsGrid
        })
        actionCard.LayoutOrder = i
        
        local actionBtn = Utility.Create("TextButton", {
            Name = "Button",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Parent = actionCard
        })
        
        local iconBg = Utility.Create("Frame", {
            Name = "IconBg",
            Size = UDim2.new(0, 36, 0, 36),
            Position = UDim2.new(0, 12, 0.5, -18),
            BackgroundColor3 = action.Color,
            BackgroundTransparency = 0.85,
            BorderSizePixel = 0,
            Parent = actionCard
        })
        
        Utility.AddCorner(iconBg, UDim.new(0, 8))
        
        local icon = Utility.Create("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = action.Icon,
            TextSize = 18,
            Parent = iconBg
        })
        
        local name = Utility.Create("TextLabel", {
            Name = "Name",
            Size = UDim2.new(1, -60, 0, 18),
            Position = UDim2.new(0, 55, 0, 12),
            BackgroundTransparency = 1,
            Text = action.Name,
            TextColor3 = Config.UI.Colors.Text,
            Font = Config.UI.Fonts.Heading,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = actionCard
        })
        
        local desc = Utility.Create("TextLabel", {
            Name = "Desc",
            Size = UDim2.new(1, -60, 0, 14),
            Position = UDim2.new(0, 55, 0, 32),
            BackgroundTransparency = 1,
            Text = action.Desc,
            TextColor3 = Config.UI.Colors.TextMuted,
            Font = Config.UI.Fonts.Body,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = actionCard
        })
        
        actionBtn.MouseEnter:Connect(function()
            Utility.Tween(actionCard, {BackgroundColor3 = Config.UI.Colors.SurfaceHover}, 0.15)
        end)
        
        actionBtn.MouseLeave:Connect(function()
            Utility.Tween(actionCard, {BackgroundColor3 = Config.UI.Colors.Surface}, 0.15)
        end)
        
        actionBtn.MouseButton1Click:Connect(function()
            if action.Mode then
                switchTab("Export")
                -- Trigger export
                task.spawn(function()
                    UI.StartExport(action.Mode)
                end)
            elseif action.Tab then
                switchTab(action.Tab)
            end
        end)
    end
    
    -- Stats Title
    local statsTitle = Utility.Create("TextLabel", {
        Name = "StatsTitle",
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = "📊 Statistics",
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Heading,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 4,
        Parent = homePage
    })
    
    -- Stats Grid
    local statsGrid = Utility.Create("Frame", {
        Name = "StatsGrid",
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundTransparency = 1,
        LayoutOrder = 5,
        Parent = homePage
    })
    
    local statsLayout = Utility.Create("UIGridLayout", {
        CellSize = UDim2.new(0.32, 0, 0, 70),
        CellPadding = UDim2.new(0.02, 0, 0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = statsGrid
    })
    
    local statsData = {
        { Name = "Total Exports", Value = "0", Icon = "📦", Color = Config.UI.Colors.Primary, Key = "TotalExports" },
        { Name = "Success Rate", Value = "100%", Icon = "✅", Color = Config.UI.Colors.Success, Key = "SuccessRate" },
        { Name = "Instances", Value = "0", Icon = "🔢", Color = Config.UI.Colors.Accent, Key = "TotalInstances" },
    }
    
    local statLabels = {}
    
    for i, stat in ipairs(statsData) do
        local statCard = Components.CreateCard({
            Name = stat.Name,
            Size = UDim2.new(0, 100, 0, 70),
            Color = Config.UI.Colors.Surface,
            Parent = statsGrid
        })
        statCard.LayoutOrder = i
        
        local icon = Utility.Create("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0, 12, 0, 10),
            BackgroundColor3 = stat.Color,
            BackgroundTransparency = 0.85,
            Text = stat.Icon,
            TextSize = 14,
            Parent = statCard
        })
        
        Utility.AddCorner(icon, UDim.new(0, 6))
        
        local value = Utility.Create("TextLabel", {
            Name = "Value",
            Size = UDim2.new(1, -50, 0, 22),
            Position = UDim2.new(0, 48, 0, 10),
            BackgroundTransparency = 1,
            Text = stat.Value,
            TextColor3 = Config.UI.Colors.Text,
            Font = Config.UI.Fonts.Title,
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = statCard
        })
        
        statLabels[stat.Key] = value
        
        local name = Utility.Create("TextLabel", {
            Name = "Name",
            Size = UDim2.new(1, -20, 0, 16),
            Position = UDim2.new(0, 12, 0, 45),
            BackgroundTransparency = 1,
            Text = stat.Name,
            TextColor3 = Config.UI.Colors.TextMuted,
            Font = Config.UI.Fonts.Body,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = statCard
        })
    end
    
    -- Update stats function
    local function updateStats()
        if statLabels.TotalExports then
            statLabels.TotalExports.Text = tostring(State.Stats.TotalExports)
        end
        if statLabels.SuccessRate then
            local rate = State.Stats.TotalExports > 0 and math.floor((State.Stats.SuccessfulExports / State.Stats.TotalExports) * 100) or 100
            statLabels.SuccessRate.Text = rate .. "%"
        end
        if statLabels.TotalInstances then
            statLabels.TotalInstances.Text = Utility.FormatNumber(State.Stats.TotalInstances)
        end
    end
    
    --------------------------------------------------------------------------------
    -- EXPORT PAGE
    --------------------------------------------------------------------------------
    
    local exportPage = tabPages["Export"]
    
    -- Export Mode Card
    local exportModeCard = Components.CreateCard({
        Name = "ExportMode",
        Size = UDim2.new(1, 0, 0, 100),
        Color = Config.UI.Colors.Surface,
        Parent = exportPage
    })
    
    local exportModeTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 15, 0, 10),
        BackgroundTransparency = 1,
        Text = "📦 Export Mode",
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Heading,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = exportModeCard
    })
    
    local exportModeDropdown = Components.CreateDropdown({
        Name = "ModeDropdown",
        Size = UDim2.new(1, -30, 0, 40),
        Position = UDim2.new(0, 15, 0, 45),
        Options = {"Full Game", "Models Only", "Terrain Only"},
        Default = "Full Game",
        Parent = exportModeCard,
        Callback = function(value)
            Config.Export.CurrentMode = value
            Logger.Info("Export mode changed to: " .. value)
        end
    })
    
    exportModeDropdown.Position = UDim2.new(0, 15, 0, 45)
    
    -- Progress Card
    local progressCard = Components.CreateCard({
        Name = "Progress",
        Size = UDim2.new(1, 0, 0, 130),
        Color = Config.UI.Colors.Surface,
        LayoutOrder = 2,
        Parent = exportPage
    })
    
    local progressTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 15, 0, 10),
        BackgroundTransparency = 1,
        Text = "⏳ Export Progress",
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Heading,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = progressCard
    })
    
    local progressBar = Components.CreateProgressBar({
        Name = "ProgressBar",
        Size = UDim2.new(1, -30, 0, 12),
        Color = Config.UI.Colors.Primary,
        Gradient = true,
        GradientEnd = Config.UI.Colors.Accent,
        Value = 0,
        Parent = progressCard
    })
    
    progressBar.Position = UDim2.new(0, 15, 0, 45)
    
    local progressPercent = Utility.Create("TextLabel", {
        Name = "Percent",
        Size = UDim2.new(0, 50, 0, 20),
        Position = UDim2.new(1, -65, 0, 62),
        BackgroundTransparency = 1,
        Text = "0%",
        TextColor3 = Config.UI.Colors.Primary,
        Font = Config.UI.Fonts.Heading,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = progressCard
    })
    
    local progressStatus = Utility.Create("TextLabel", {
        Name = "Status",
        Size = UDim2.new(1, -70, 0, 20),
        Position = UDim2.new(0, 15, 0, 62),
        BackgroundTransparency = 1,
        Text = "Ready to export",
        TextColor3 = Config.UI.Colors.TextSecondary,
        Font = Config.UI.Fonts.Body,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = progressCard
    })
    
    local progressDetails = Utility.Create("TextLabel", {
        Name = "Details",
        Size = UDim2.new(1, -30, 0, 20),
        Position = UDim2.new(0, 15, 0, 90),
        BackgroundTransparency = 1,
        Text = "📁 Output: " .. Config.Export.OutputFolder,
        TextColor3 = Config.UI.Colors.TextMuted,
        Font = Config.UI.Fonts.Body,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = progressCard
    })
    
    -- Export Button
    local exportButtonContainer = Utility.Create("Frame", {
        Name = "ButtonContainer",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Parent = exportPage
    })
    
    local exportButton = Components.CreateButton({
        Name = "ExportButton",
        Size = UDim2.new(1, 0, 0, 50),
        Text = "🚀 Start Export",
        Color = Config.UI.Colors.Primary,
        Gradient = true,
        GradientEnd = Config.UI.Colors.PrimaryDark,
        TextSize = 16,
        Parent = exportButtonContainer,
        Callback = function()
            if not State.IsExporting then
                local modeMap = {
                    ["Full Game"] = "FullGame",
                    ["Models Only"] = "FullModel",
                    ["Terrain Only"] = "Terrain"
                }
                
                local mode = modeMap[exportModeDropdown.GetValue()] or "FullGame"
                UI.StartExport(mode)
            end
        end
    })
    
    -- Options Card
    local optionsCard = Components.CreateCard({
        Name = "Options",
        Size = UDim2.new(1, 0, 0, 180),
        Color = Config.UI.Colors.Surface,
        LayoutOrder = 4,
        Parent = exportPage
    })
    
    local optionsTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 15, 0, 10),
        BackgroundTransparency = 1,
        Text = "⚙️ Export Options",
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Heading,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = optionsCard
    })
    
    local optionsContainer = Utility.Create("Frame", {
        Name = "Container",
        Size = UDim2.new(1, -30, 0, 130),
        Position = UDim2.new(0, 15, 0, 40),
        BackgroundTransparency = 1,
        Parent = optionsCard
    })
    
    local optionsLayout = Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = optionsContainer
    })
    
    -- Toggle options
    local decompileToggle = Components.CreateToggle({
        Name = "DecompileScripts",
        Text = "📜 Decompile Scripts",
        Value = Config.Export.DecompileScripts,
        Parent = optionsContainer,
        Callback = function(value)
            Config.Export.DecompileScripts = value
            Logger.Info("Decompile scripts: " .. tostring(value))
        end
    })
    
    local terrainToggle = Components.CreateToggle({
        Name = "IncludeTerrain",
        Text = "🏔️ Include Terrain",
        Value = Config.Export.IncludeTerrain,
        Parent = optionsContainer,
        Callback = function(value)
            Config.Export.IncludeTerrain = value
            Logger.Info("Include terrain: " .. tostring(value))
        end
    })
    
    local preserveToggle = Components.CreateToggle({
        Name = "PreserveDisabled",
        Text = "🔒 Preserve Disabled Scripts",
        Value = Config.Export.PreserveDisabled,
        Parent = optionsContainer,
        Callback = function(value)
            Config.Export.PreserveDisabled = value
        end
    })
    
    -- Export function
    function UI.StartExport(mode)
        if State.IsExporting then
            Components.CreateNotification({
                Type = "warning",
                Title = "Already Exporting",
                Message = "Please wait for current export to finish",
                Parent = screenGui
            })
            return
        end
        
        Logger.Info("Starting export: " .. mode)
        
        Components.CreateNotification({
            Type = "info",
            Title = "Export Started",
            Message = "Exporting " .. mode .. "...",
            Parent = screenGui
        })
        
        exportButton.Text = "⏳ Exporting..."
        exportButton.BackgroundColor3 = Config.UI.Colors.TextMuted
        
        task.spawn(function()
            local success, result = Exporter.Export(mode, function(progress, status)
                progressBar.SetProgress(progress)
                progressPercent.Text = math.floor(progress) .. "%"
                progressStatus.Text = status
            end)
            
            exportButton.Text = "🚀 Start Export"
            exportButton.BackgroundColor3 = Config.UI.Colors.Primary
            
            updateStats()
            
            if success then
                Components.CreateNotification({
                    Type = "success",
                    Title = "Export Complete!",
                    Message = "Saved to: " .. tostring(result),
                    Duration = 6,
                    Parent = screenGui
                })
            else
                Components.CreateNotification({
                    Type = "error",
                    Title = "Export Failed",
                    Message = tostring(result),
                    Duration = 6,
                    Parent = screenGui
                })
            end
        end)
    end
    
    --------------------------------------------------------------------------------
    -- SERVICES PAGE
    --------------------------------------------------------------------------------
    
    local servicesPage = tabPages["Services"]
    
    local servicesTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = "🗂️ Select Services to Export",
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Heading,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = servicesPage
    })
    
    local servicesDesc = Utility.Create("TextLabel", {
        Name = "Desc",
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = "Toggle which services to include in Full Game export",
        TextColor3 = Config.UI.Colors.TextMuted,
        Font = Config.UI.Fonts.Body,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Parent = servicesPage
    })
    
    for i, serviceData in ipairs(Config.Export.ServicesToExport) do
        local serviceToggle = Components.CreateToggle({
            Name = serviceData.Name,
            Text = serviceData.Icon .. " " .. serviceData.Name,
            Value = serviceData.Enabled,
            Parent = servicesPage,
            Callback = function(value)
                Config.Export.ServicesToExport[i].Enabled = value
                Logger.Debug(serviceData.Name .. " export: " .. tostring(value))
            end
        })
        serviceToggle.LayoutOrder = i + 1
    end
    
    --------------------------------------------------------------------------------
    -- SETTINGS PAGE
    --------------------------------------------------------------------------------
    
    local settingsPage = tabPages["Settings"]
    
    -- Output Settings
    local outputCard = Components.CreateCard({
        Name = "OutputSettings",
        Size = UDim2.new(1, 0, 0, 140),
        Color = Config.UI.Colors.Surface,
        Parent = settingsPage
    })
    
    local outputTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 15, 0, 10),
        BackgroundTransparency = 1,
        Text = "📁 Output Settings",
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Heading,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = outputCard
    })
    
    -- Output Folder
    local folderLabel = Utility.Create("TextLabel", {
        Name = "FolderLabel",
        Size = UDim2.new(0, 100, 0, 20),
        Position = UDim2.new(0, 15, 0, 45),
        BackgroundTransparency = 1,
        Text = "Output Folder:",
        TextColor3 = Config.UI.Colors.TextSecondary,
        Font = Config.UI.Fonts.Body,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = outputCard
    })
    
    local folderInput = Components.CreateInput({
        Name = "FolderInput",
        Size = UDim2.new(1, -130, 0, 36),
        Default = Config.Export.OutputFolder,
        Placeholder = "Folder name...",
        Parent = outputCard,
        Callback = function(value)
            Config.Export.OutputFolder = value
            Logger.Info("Output folder changed to: " .. value)
        end
    })
    
    folderInput.Position = UDim2.new(0, 115, 0, 42)
    
    -- Output Format
    local formatLabel = Utility.Create("TextLabel", {
        Name = "FormatLabel",
        Size = UDim2.new(0, 100, 0, 20),
        Position = UDim2.new(0, 15, 0, 95),
        BackgroundTransparency = 1,
        Text = "File Format:",
        TextColor3 = Config.UI.Colors.TextSecondary,
        Font = Config.UI.Fonts.Body,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = outputCard
    })
    
    local formatDropdown = Components.CreateDropdown({
        Name = "FormatDropdown",
        Size = UDim2.new(1, -130, 0, 36),
        Options = {"rbxlx", "rbxl"},
        Default = Config.Export.OutputFormat,
        Parent = outputCard,
        Callback = function(value)
            Config.Export.OutputFormat = value
            Logger.Info("Output format changed to: " .. value)
        end
    })
    
    formatDropdown.Position = UDim2.new(0, 115, 0, 92)
    
    -- Performance Settings
    local perfCard = Components.CreateCard({
        Name = "PerformanceSettings",
        Size = UDim2.new(1, 0, 0, 130),
        Color = Config.UI.Colors.Surface,
        LayoutOrder = 2,
        Parent = settingsPage
    })
    
    local perfTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 15, 0, 10),
        BackgroundTransparency = 1,
        Text = "⚡ Performance",
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Heading,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = perfCard
    })
    
    -- Timeout
    local timeoutLabel = Utility.Create("TextLabel", {
        Name = "TimeoutLabel",
        Size = UDim2.new(0, 130, 0, 20),
        Position = UDim2.new(0, 15, 0, 45),
        BackgroundTransparency = 1,
        Text = "Decompile Timeout:",
        TextColor3 = Config.UI.Colors.TextSecondary,
        Font = Config.UI.Fonts.Body,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = perfCard
    })
    
    local timeoutInput = Components.CreateInput({
        Name = "TimeoutInput",
        Size = UDim2.new(0, 80, 0, 36),
        Default = tostring(Config.Export.DecompileTimeout),
        Placeholder = "10",
        Parent = perfCard,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                Config.Export.DecompileTimeout = num
                Logger.Info("Decompile timeout set to: " .. num .. "s")
            end
        end
    })
    
    timeoutInput.Position = UDim2.new(0, 145, 0, 42)
    
    local timeoutSuffix = Utility.Create("TextLabel", {
        Name = "Suffix",
        Size = UDim2.new(0, 40, 0, 36),
        Position = UDim2.new(0, 230, 0, 42),
        BackgroundTransparency = 1,
        Text = "seconds",
        TextColor3 = Config.UI.Colors.TextMuted,
        Font = Config.UI.Fonts.Body,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = perfCard
    })
    
    -- Yield Interval
    local yieldLabel = Utility.Create("TextLabel", {
        Name = "YieldLabel",
        Size = UDim2.new(0, 130, 0, 20),
        Position = UDim2.new(0, 15, 0, 90),
        BackgroundTransparency = 1,
        Text = "Yield Interval:",
        TextColor3 = Config.UI.Colors.TextSecondary,
        Font = Config.UI.Fonts.Body,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = perfCard
    })
    
    local yieldInput = Components.CreateInput({
        Name = "YieldInput",
        Size = UDim2.new(0, 80, 0, 36),
        Default = tostring(Config.Export.YieldInterval),
        Placeholder = "50",
        Parent = perfCard,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                Config.Export.YieldInterval = num
            end
        end
    })
    
    yieldInput.Position = UDim2.new(0, 145, 0, 87)
    
    local yieldSuffix = Utility.Create("TextLabel", {
        Name = "Suffix",
        Size = UDim2.new(0, 60, 0, 36),
        Position = UDim2.new(0, 230, 0, 87),
        BackgroundTransparency = 1,
        Text = "instances",
        TextColor3 = Config.UI.Colors.TextMuted,
        Font = Config.UI.Fonts.Body,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = perfCard
    })
    
    --------------------------------------------------------------------------------
    -- CONSOLE PAGE
    --------------------------------------------------------------------------------
    
    local consolePage = tabPages["Console"]
    
    -- Console Header
    local consoleHeader = Utility.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Config.UI.Colors.Surface,
        BorderSizePixel = 0,
        Parent = consolePage
    })
    
    Utility.AddCorner(consoleHeader, UDim.new(0, 8))
    
    local consoleTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 150, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "📋 Console Logs",
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Heading,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = consoleHeader
    })
    
    local clearBtn = Components.CreateButton({
        Name = "ClearBtn",
        Size = UDim2.new(0, 80, 0, 28),
        Position = UDim2.new(1, -90, 0.5, -14),
        Text = "🗑️ Clear",
        Color = Config.UI.Colors.Error,
        TextSize = 12,
        CornerRadius = UDim.new(0, 6),
        Parent = consoleHeader,
        Callback = function()
            Logger.Clear()
        end
    })
    
    clearBtn.Position = UDim2.new(1, -90, 0.5, -14)
    
    -- Console Output
    local consoleOutput = Utility.Create("ScrollingFrame", {
        Name = "Output",
        Size = UDim2.new(1, 0, 1, -52),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundColor3 = Config.UI.Colors.BackgroundSecondary,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Config.UI.Colors.Primary,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        Parent = consolePage
    })
    
    Utility.AddCorner(consoleOutput, UDim.new(0, 8))
    
    local consoleLayout = Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = consoleOutput
    })
    
    Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = consoleOutput
    })
    
    local logCounter = 0
    
    local function addLogEntry(log)
        logCounter = logCounter + 1
        
        local entry = Utility.Create("Frame", {
            Name = "Log_" .. logCounter,
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            LayoutOrder = logCounter,
            Parent = consoleOutput
        })
        
        local time = Utility.Create("TextLabel", {
            Name = "Time",
            Size = UDim2.new(0, 60, 1, 0),
            BackgroundTransparency = 1,
            Text = log.Time,
            TextColor3 = Config.UI.Colors.TextMuted,
            Font = Config.UI.Fonts.Code,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = entry
        })
        
        local icon = Utility.Create("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 1, 0),
            Position = UDim2.new(0, 60, 0, 0),
            BackgroundTransparency = 1,
            Text = log.Icon,
            TextSize = 12,
            Parent = entry
        })
        
        local message = Utility.Create("TextLabel", {
            Name = "Message",
            Size = UDim2.new(1, -85, 1, 0),
            Position = UDim2.new(0, 82, 0, 0),
            BackgroundTransparency = 1,
            Text = log.Message,
            TextColor3 = log.Color,
            Font = Config.UI.Fonts.Code,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = entry
        })
    end
    
    Logger.OnLog = addLogEntry
    
    Logger.OnClear = function()
        for _, child in ipairs(consoleOutput:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        logCounter = 0
    end
    
    --------------------------------------------------------------------------------
    -- ABOUT PAGE
    --------------------------------------------------------------------------------
    
    local aboutPage = tabPages["About"]
    
    -- About Card
    local aboutCard = Components.CreateCard({
        Name = "AboutCard",
        Size = UDim2.new(1, 0, 0, 180),
        Color = Config.UI.Colors.Surface,
        Parent = aboutPage
    })
    
    local aboutGradient = Utility.Create("Frame", {
        Name = "Gradient",
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = aboutCard
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = aboutGradient
    })
    
    Utility.AddGradient(aboutGradient, {Config.UI.Colors.Primary, Config.UI.Colors.Secondary, Config.UI.Colors.Accent}, 90)
    aboutGradient.BackgroundTransparency = 0.7
    
    local aboutLogo = Utility.Create("TextLabel", {
        Name = "Logo",
        Size = UDim2.new(0, 60, 0, 60),
        Position = UDim2.new(0.5, -30, 0, 10),
        BackgroundColor3 = Config.UI.Colors.Primary,
        Text = "🚀",
        TextSize = 30,
        Parent = aboutCard
    })
    
    Utility.AddCorner(aboutLogo, UDim.new(0, 16))
    Utility.AddGradient(aboutLogo, {Config.UI.Colors.Primary, Config.UI.Colors.PrimaryDark}, 135)
    Utility.AddShadow(aboutLogo, 20, 0.5)
    
    local aboutName = Utility.Create("TextLabel", {
        Name = "Name",
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 0, 0, 85),
        BackgroundTransparency = 1,
        Text = "BaoSaveInstance",
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Title,
        TextSize = 20,
        Parent = aboutCard
    })
    
    local aboutVersion = Utility.Create("TextLabel", {
        Name = "Version",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 108),
        BackgroundTransparency = 1,
        Text = "Version " .. Config.UI.Version,
        TextColor3 = Config.UI.Colors.TextSecondary,
        Font = Config.UI.Fonts.Body,
        TextSize = 13,
        Parent = aboutCard
    })
    
    local aboutDesc = Utility.Create("TextLabel", {
        Name = "Desc",
        Size = UDim2.new(1, -30, 0, 40),
        Position = UDim2.new(0, 15, 0, 135),
        BackgroundTransparency = 1,
        Text = "The most advanced game decompiler & exporter for Roblox.\nCreated with ❤️ by " .. Config.UI.Author,
        TextColor3 = Config.UI.Colors.TextMuted,
        Font = Config.UI.Fonts.Body,
        TextSize = 12,
        Parent = aboutCard
    })
    
    -- Features Card
    local featuresCard = Components.CreateCard({
        Name = "Features",
        Size = UDim2.new(1, 0, 0, 200),
        Color = Config.UI.Colors.Surface,
        LayoutOrder = 2,
        Parent = aboutPage
    })
    
    local featuresTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 15, 0, 10),
        BackgroundTransparency = 1,
        Text = "✨ Features",
        TextColor3 = Config.UI.Colors.Text,
        Font = Config.UI.Fonts.Heading,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = featuresCard
    })
    
    local features = {
        "🎮 Full Game Export with Scripts & Terrain",
        "🏗️ Model-Only Export Mode",
        "🏔️ Terrain-Only Export Mode",
        "📜 Script Decompilation Support",
        "⚙️ Customizable Service Selection",
        "🚫 Blacklist/Whitelist System",
        "📊 Real-time Progress Tracking",
        "🎨 Beautiful Modern UI"
    }
    
    for i, feature in ipairs(features) do
        local featureLabel = Utility.Create("TextLabel", {
            Name = "Feature_" .. i,
            Size = UDim2.new(1, -30, 0, 18),
            Position = UDim2.new(0, 15, 0, 35 + (i-1) * 20),
            BackgroundTransparency = 1,
            Text = feature,
            TextColor3 = Config.UI.Colors.TextSecondary,
            Font = Config.UI.Fonts.Body,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = featuresCard
        })
    end
    
    --------------------------------------------------------------------------------
    -- WINDOW CONTROLS & DRAGGING
    --------------------------------------------------------------------------------
    
    -- Close button
    closeBtn.MouseButton1Click:Connect(function()
        Utility.Tween(mainWindow, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }, 0.3)
        
        task.delay(0.3, function()
            screenGui:Destroy()
        end)
    end)
    
    -- Minimize button
    minimizeBtn.MouseButton1Click:Connect(function()
        State.IsMinimized = not State.IsMinimized
        
        if State.IsMinimized then
            Utility.Tween(mainWindow, {Size = UDim2.new(0, 250, 0, 50)}, 0.3)
            contentArea.Visible = false
        else
            Utility.Tween(mainWindow, {Size = Config.UI.WindowSize}, 0.3)
            task.delay(0.2, function()
                contentArea.Visible = true
            end)
        end
    end)
    
    -- Dragging
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            State.IsDragging = true
            State.DragStart = input.Position
            State.StartPos = mainWindow.Position
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            State.IsDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if State.IsDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - State.DragStart
            mainWindow.Position = UDim2.new(
                State.StartPos.X.Scale,
                State.StartPos.X.Offset + delta.X,
                State.StartPos.Y.Scale,
                State.StartPos.Y.Offset + delta.Y
            )
        end
    end)
    
    --------------------------------------------------------------------------------
    -- KEYBIND
    --------------------------------------------------------------------------------
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.RightControl then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)
    
    --------------------------------------------------------------------------------
    -- INITIALIZATION
    --------------------------------------------------------------------------------
    
    -- Opening animation
    mainWindow.Size = UDim2.new(0, 0, 0, 0)
    mainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    Utility.Tween(mainWindow, {
        Size = Config.UI.WindowSize,
        Position = UDim2.new(0.5, -350, 0.5, -275)
    }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    -- Welcome log
    task.delay(0.5, function()
        Logger.Info("BaoSaveInstance v" .. Config.UI.Version .. " loaded!")
        Logger.Info("Game: " .. Utility.GetGameName())
        Logger.Info("PlaceId: " .. game.PlaceId)
        Logger.Success("Ready to export!")
    end)
    
    -- Return reference
    UI.ScreenGui = screenGui
    UI.MainWindow = mainWindow
    UI.UpdateStats = updateStats
    
    return UI
end

--------------------------------------------------------------------------------
-- GLOBAL API
--------------------------------------------------------------------------------

local BaoSaveInstance = {}

BaoSaveInstance.Config = Config
BaoSaveInstance.State = State
BaoSaveInstance.Logger = Logger
BaoSaveInstance.Exporter = Exporter

function BaoSaveInstance.Show()
    return UI.Create()
end

function BaoSaveInstance.DecompileFullGame()
    return Exporter.Export("FullGame")
end

function BaoSaveInstance.DecompileFullModel()
    return Exporter.Export("FullModel")
end

function BaoSaveInstance.DecompileTerrain()
    return Exporter.Export("Terrain")
end

function BaoSaveInstance.Export(options)
    options = options or {}
    for key, value in pairs(options) do
        if Config.Export[key] ~= nil then
            Config.Export[key] = value
        end
    end
    return Exporter.Export(options.Mode or "FullGame")
end

--------------------------------------------------------------------------------
-- AUTO INITIALIZE
--------------------------------------------------------------------------------

if getgenv then
    getgenv().BaoSaveInstance = BaoSaveInstance
end

-- Auto show UI
BaoSaveInstance.Show()

Logger.Info("BaoSaveInstance initialized!")
Logger.Info("Press RightCtrl to toggle UI")

return BaoSaveInstance
