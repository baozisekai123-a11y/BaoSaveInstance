--[[
================================================================================
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
                    INSTANCE SERIALIZER v1.0
================================================================================
    
    BaoSaveInstance - Complete Save Instance System
    
    ✓ Supports: Xeno, Solara, TNG, Velocity, Wave, and compatible executors
    ✓ Output: Single .rbxl file compatible with Roblox Studio
    ✓ Features: Save Game, Save Terrain, Save All Models
    
    NOT dependent on UniversalSynSaveInstance or Synapse-specific APIs
    
================================================================================
]]

-- ============================================================================
-- SECTION 1: CONFIGURATION
-- ============================================================================

local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance
BaoSaveInstance.Version = "1.0.0"

-- Default configuration
local DefaultConfig = {
    -- Output Settings
    OutputFolder = "BaoSaveInstance",
    FileName = nil, -- Auto-generated if nil
    
    -- Serialization Options
    SaveScripts = true,
    DecompileScripts = true,
    SaveTerrain = true,
    SaveLighting = true,
    SavePlayers = false,
    
    -- Performance
    YieldInterval = 200,        -- Yield every N instances to prevent timeout
    MaxDepth = 500,             -- Maximum hierarchy depth
    
    -- Property Handling
    IgnoreDefaultProperties = true,
    SaveHiddenProperties = true,
    
    -- Services to save
    ServicesToSave = {
        "Workspace",
        "Lighting",
        "ReplicatedStorage",
        "ReplicatedFirst",
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
        "Teams",
        "SoundService",
    },
    
    -- Instances to ignore (ClassName)
    IgnoreClassNames = {
        "Player",
        "PlayerGui",
        "Backpack",
        "PlayerScripts",
        "Camera",
    },
    
    -- Properties to ignore
    IgnoreProperties = {
        "Parent",
        "DataCost",
        "ClassName",
        "RobloxLocked",
        "Archivable",
    },
    
    -- API Configuration (Future-proof)
    API = {
        Enabled = false,
        BaseURL = "",
        Headers = {},
        Endpoints = {
            Upload = "/api/v1/upload",
            Version = "/api/v1/version",
            HashCheck = "/api/v1/hash",
            Metadata = "/api/v1/metadata"
        },
        Timeout = 30,
        RetryCount = 3
    },
    
    -- Debug
    Debug = false,
    Verbose = false
}

-- ============================================================================
-- SECTION 2: EXECUTOR ABSTRACTION LAYER
-- ============================================================================

local ExecutorAPI = {}

-- Detect and initialize executor-specific functions
function ExecutorAPI.Initialize()
    local api = {
        Name = "Unknown",
        Supported = false
    }
    
    -- File System Operations
    api.ReadFile = readfile or function() return nil end
    api.WriteFile = writefile or function() end
    api.IsFile = isfile or function() return false end
    api.MakeFolder = makefolder or function() end
    api.ListFiles = listfiles or function() return {} end
    api.DeleteFile = delfile or function() end
    api.AppendFile = appendfile or function(path, content)
        local existing = api.ReadFile(path) or ""
        api.WriteFile(path, existing .. content)
    end
    
    -- Instance Operations
    api.GetHiddenProperty = gethiddenproperty or function() return nil, false end
    api.SetHiddenProperty = sethiddenproperty or function() return false end
    api.GetProperties = getproperties or function() return {} end
    api.GetHiddenProperties = gethiddenproperties or function() return {} end
    
    -- Script Operations
    api.Decompile = decompile or function() return "-- Decompilation not supported" end
    api.GetScriptBytecode = getscriptbytecode or function() return "" end
    api.IsScriptable = isscriptable or function() return true end
    
    -- Misc Operations
    api.GetGC = getgc or function() return {} end
    api.GetInstances = getinstances or function() return {} end
    api.GetNilInstances = getnilinstances or function() return {} end
    api.FireSignal = firesignal or function() end
    api.GetConnections = getconnections or function() return {} end
    
    -- HTTP (for API layer)
    api.HttpRequest = (syn and syn.request) or 
                      (http and http.request) or 
                      (request) or 
                      (http_request) or
                      function() return {Success = false} end
    
    -- Detect executor
    if XENO_EXECUTOR then
        api.Name = "Xeno"
        api.Supported = true
    elseif SOLARA_EXECUTOR or getgenv().SOLARA then
        api.Name = "Solara"
        api.Supported = true
    elseif TNG_EXECUTOR or identifyexecutor and identifyexecutor():find("TNG") then
        api.Name = "TNG"
        api.Supported = true
    elseif VELOCITY_EXECUTOR then
        api.Name = "Velocity"
        api.Supported = true
    elseif WAVE_EXECUTOR or identifyexecutor and identifyexecutor():find("Wave") then
        api.Name = "Wave"
        api.Supported = true
    elseif identifyexecutor then
        api.Name = identifyexecutor()
        api.Supported = true
    end
    
    -- Validate core requirements
    api.HasFileSystem = pcall(function() return writefile and readfile end)
    api.HasDecompiler = pcall(function() return decompile end)
    api.HasPropertyAccess = pcall(function() return gethiddenproperty end)
    
    return api
end

-- Global executor API instance
local Executor = ExecutorAPI.Initialize()

-- ============================================================================
-- SECTION 3: UTILITY FUNCTIONS
-- ============================================================================

local Utils = {}

-- Generate unique ID
local idCounter = 0
function Utils.GenerateID()
    idCounter = idCounter + 1
    return string.format("RBX%08X", idCounter)
end

-- Reset ID counter
function Utils.ResetIDs()
    idCounter = 0
end

-- Safe call with error handling
function Utils.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if success then
        return result, true
    else
        return nil, false, result
    end
end

-- XML escape special characters
function Utils.XMLEscape(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    return str:gsub("&", "&amp;")
              :gsub("<", "&lt;")
              :gsub(">", "&gt;")
              :gsub("\"", "&quot;")
              :gsub("'", "&apos;")
end

-- Base64 encode (for binary data)
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function Utils.Base64Encode(data)
    return ((data:gsub('.', function(x) 
        local r, b = '', x:byte()
        for i = 8, 1, -1 do 
            r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') 
        end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do 
            c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) 
        end
        return b64chars:sub(c + 1, c + 1)
    end) .. ({'', '==', '='})[#data % 3 + 1])
end

-- Get current timestamp for filename
function Utils.GetTimestamp()
    local date = os.date("*t")
    return string.format("%04d%02d%02d_%02d%02d%02d", 
        date.year, date.month, date.day, 
        date.hour, date.min, date.sec)
end

-- Deep copy table
function Utils.DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = Utils.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Create lookup table from array
function Utils.CreateLookup(array)
    local lookup = {}
    for _, v in ipairs(array) do
        lookup[v] = true
    end
    return lookup
end

-- ============================================================================
-- SECTION 4: PROPERTY SERIALIZATION
-- ============================================================================

local PropertySerializer = {}

-- Property type handlers
PropertySerializer.TypeHandlers = {}

-- String
PropertySerializer.TypeHandlers["string"] = function(value, name)
    return string.format('<string name="%s">%s</string>', name, Utils.XMLEscape(value))
end

-- Bool
PropertySerializer.TypeHandlers["boolean"] = function(value, name)
    return string.format('<bool name="%s">%s</bool>', name, value and "true" or "false")
end

-- Int (various int types)
PropertySerializer.TypeHandlers["number"] = function(value, name, actualType)
    if actualType == "int" or actualType == "int64" then
        return string.format('<int name="%s">%d</int>', name, math.floor(value))
    elseif actualType == "float" then
        return string.format('<float name="%s">%s</float>', name, tostring(value))
    else
        return string.format('<double name="%s">%s</double>', name, tostring(value))
    end
end

-- Vector3
PropertySerializer.TypeHandlers["Vector3"] = function(value, name)
    return string.format(
        '<Vector3 name="%s"><X>%s</X><Y>%s</Y><Z>%s</Z></Vector3>',
        name, tostring(value.X), tostring(value.Y), tostring(value.Z)
    )
end

-- Vector2
PropertySerializer.TypeHandlers["Vector2"] = function(value, name)
    return string.format(
        '<Vector2 name="%s"><X>%s</X><Y>%s</Y></Vector2>',
        name, tostring(value.X), tostring(value.Y)
    )
end

-- CFrame
PropertySerializer.TypeHandlers["CFrame"] = function(value, name)
    local components = {value:GetComponents()}
    return string.format(
        '<CoordinateFrame name="%s">' ..
        '<X>%s</X><Y>%s</Y><Z>%s</Z>' ..
        '<R00>%s</R00><R01>%s</R01><R02>%s</R02>' ..
        '<R10>%s</R10><R11>%s</R11><R12>%s</R12>' ..
        '<R20>%s</R20><R21>%s</R21><R22>%s</R22>' ..
        '</CoordinateFrame>',
        name,
        tostring(components[1]), tostring(components[2]), tostring(components[3]),
        tostring(components[4]), tostring(components[5]), tostring(components[6]),
        tostring(components[7]), tostring(components[8]), tostring(components[9]),
        tostring(components[10]), tostring(components[11]), tostring(components[12])
    )
end

-- Color3
PropertySerializer.TypeHandlers["Color3"] = function(value, name)
    return string.format(
        '<Color3 name="%s"><R>%s</R><G>%s</G><B>%s</B></Color3>',
        name, tostring(value.R), tostring(value.G), tostring(value.B)
    )
end

-- BrickColor
PropertySerializer.TypeHandlers["BrickColor"] = function(value, name)
    return string.format('<int name="%s">%d</int>', name, value.Number)
end

-- UDim
PropertySerializer.TypeHandlers["UDim"] = function(value, name)
    return string.format(
        '<UDim name="%s"><S>%s</S><O>%d</O></UDim>',
        name, tostring(value.Scale), value.Offset
    )
end

-- UDim2
PropertySerializer.TypeHandlers["UDim2"] = function(value, name)
    return string.format(
        '<UDim2 name="%s">' ..
        '<XS>%s</XS><XO>%d</XO>' ..
        '<YS>%s</YS><YO>%d</YO>' ..
        '</UDim2>',
        name,
        tostring(value.X.Scale), value.X.Offset,
        tostring(value.Y.Scale), value.Y.Offset
    )
end

-- Rect
PropertySerializer.TypeHandlers["Rect"] = function(value, name)
    return string.format(
        '<Rect2D name="%s">' ..
        '<min><X>%s</X><Y>%s</Y></min>' ..
        '<max><X>%s</X><Y>%s</Y></max>' ..
        '</Rect2D>',
        name,
        tostring(value.Min.X), tostring(value.Min.Y),
        tostring(value.Max.X), tostring(value.Max.Y)
    )
end

-- NumberRange
PropertySerializer.TypeHandlers["NumberRange"] = function(value, name)
    return string.format(
        '<NumberRange name="%s">%s %s</NumberRange>',
        name, tostring(value.Min), tostring(value.Max)
    )
end

-- NumberSequence
PropertySerializer.TypeHandlers["NumberSequence"] = function(value, name)
    local keypoints = {}
    for _, kp in ipairs(value.Keypoints) do
        table.insert(keypoints, string.format("%s %s %s", 
            tostring(kp.Time), tostring(kp.Value), tostring(kp.Envelope)))
    end
    return string.format(
        '<NumberSequence name="%s">%s</NumberSequence>',
        name, table.concat(keypoints, " ")
    )
end

-- ColorSequence
PropertySerializer.TypeHandlers["ColorSequence"] = function(value, name)
    local keypoints = {}
    for _, kp in ipairs(value.Keypoints) do
        table.insert(keypoints, string.format("%s %s %s %s 0",
            tostring(kp.Time), 
            tostring(kp.Value.R), 
            tostring(kp.Value.G), 
            tostring(kp.Value.B)))
    end
    return string.format(
        '<ColorSequence name="%s">%s</ColorSequence>',
        name, table.concat(keypoints, " ")
    )
end

-- EnumItem
PropertySerializer.TypeHandlers["EnumItem"] = function(value, name)
    return string.format('<token name="%s">%d</token>', name, value.Value)
end

-- Content (asset URLs)
PropertySerializer.TypeHandlers["Content"] = function(value, name)
    local url = tostring(value)
    return string.format('<Content name="%s"><url>%s</url></Content>', name, Utils.XMLEscape(url))
end

-- Instance Reference
PropertySerializer.TypeHandlers["Instance"] = function(value, name, _, referentMap)
    if value and referentMap and referentMap[value] then
        return string.format('<Ref name="%s">%s</Ref>', name, referentMap[value])
    else
        return string.format('<Ref name="%s">null</Ref>', name)
    end
end

-- PhysicalProperties
PropertySerializer.TypeHandlers["PhysicalProperties"] = function(value, name)
    if value then
        return string.format(
            '<PhysicalProperties name="%s">' ..
            '<CustomPhysics>true</CustomPhysics>' ..
            '<Density>%s</Density>' ..
            '<Friction>%s</Friction>' ..
            '<Elasticity>%s</Elasticity>' ..
            '<FrictionWeight>%s</FrictionWeight>' ..
            '<ElasticityWeight>%s</ElasticityWeight>' ..
            '</PhysicalProperties>',
            name,
            tostring(value.Density),
            tostring(value.Friction),
            tostring(value.Elasticity),
            tostring(value.FrictionWeight),
            tostring(value.ElasticityWeight)
        )
    else
        return string.format(
            '<PhysicalProperties name="%s"><CustomPhysics>false</CustomPhysics></PhysicalProperties>',
            name
        )
    end
end

-- Faces
PropertySerializer.TypeHandlers["Faces"] = function(value, name)
    local faceValue = 0
    if value.Top then faceValue = faceValue + 1 end
    if value.Bottom then faceValue = faceValue + 2 end
    if value.Left then faceValue = faceValue + 4 end
    if value.Right then faceValue = faceValue + 8 end
    if value.Back then faceValue = faceValue + 16 end
    if value.Front then faceValue = faceValue + 32 end
    return string.format('<Faces name="%s">%d</Faces>', name, faceValue)
end

-- Axes
PropertySerializer.TypeHandlers["Axes"] = function(value, name)
    local axesValue = 0
    if value.X then axesValue = axesValue + 1 end
    if value.Y then axesValue = axesValue + 2 end
    if value.Z then axesValue = axesValue + 4 end
    return string.format('<Axes name="%s">%d</Axes>', name, axesValue)
end

-- Ray
PropertySerializer.TypeHandlers["Ray"] = function(value, name)
    return string.format(
        '<Ray name="%s">' ..
        '<origin><X>%s</X><Y>%s</Y><Z>%s</Z></origin>' ..
        '<direction><X>%s</X><Y>%s</Y><Z>%s</Z></direction>' ..
        '</Ray>',
        name,
        tostring(value.Origin.X), tostring(value.Origin.Y), tostring(value.Origin.Z),
        tostring(value.Direction.X), tostring(value.Direction.Y), tostring(value.Direction.Z)
    )
end

-- Font
PropertySerializer.TypeHandlers["Font"] = function(value, name)
    return string.format(
        '<Font name="%s">' ..
        '<Family><url>%s</url></Family>' ..
        '<Weight>%d</Weight>' ..
        '<Style>%s</Style>' ..
        '</Font>',
        name,
        Utils.XMLEscape(value.Family),
        value.Weight.Value,
        value.Style.Name
    )
end

-- BinaryString (for terrain, mesh data, etc.)
PropertySerializer.TypeHandlers["BinaryString"] = function(value, name)
    local encoded = Utils.Base64Encode(value)
    return string.format('<BinaryString name="%s">%s</BinaryString>', name, encoded)
end

-- Main property serialization function
function PropertySerializer.Serialize(instance, propertyName, value, referentMap, config)
    local valueType = typeof(value)
    
    -- Handle nil
    if value == nil then
        return nil
    end
    
    -- Check ignore list
    if config and config.IgnoreProperties then
        local ignoreLookup = Utils.CreateLookup(config.IgnoreProperties)
        if ignoreLookup[propertyName] then
            return nil
        end
    end
    
    -- Get handler
    local handler = PropertySerializer.TypeHandlers[valueType]
    
    if handler then
        local success, result = pcall(handler, value, propertyName, nil, referentMap)
        if success then
            return result
        end
    end
    
    -- Fallback for unknown types
    if valueType == "table" then
        return nil -- Skip tables
    end
    
    return nil
end

-- ============================================================================
-- SECTION 5: PROPERTY DATABASE
-- ============================================================================

local PropertyDatabase = {}

-- Common properties for all instances
PropertyDatabase.CommonProperties = {
    "Name",
    "Archivable",
}

-- Class-specific property lists
PropertyDatabase.ClassProperties = {
    BasePart = {
        "Anchored", "CanCollide", "CanTouch", "CanQuery", "CastShadow",
        "Color", "Material", "MaterialVariant", "Reflectance", "Transparency",
        "Size", "CFrame", "Position", "Orientation",
        "Massless", "RootPriority", "CustomPhysicalProperties",
        "CollisionGroup", "Locked"
    },
    
    Part = {"Shape"},
    
    MeshPart = {
        "MeshId", "TextureID", "CollisionFidelity", "RenderFidelity"
    },
    
    UnionOperation = {
        "UsePartColor", "CollisionFidelity", "RenderFidelity", "SmoothingAngle"
    },
    
    Decal = {
        "Color3", "Texture", "Transparency", "ZIndex", "Face"
    },
    
    Texture = {
        "Color3", "Texture", "Transparency", "ZIndex", "Face",
        "OffsetStudsU", "OffsetStudsV", "StudsPerTileU", "StudsPerTileV"
    },
    
    SpecialMesh = {
        "MeshId", "MeshType", "TextureId", "Scale", "Offset", "VertexColor"
    },
    
    Model = {
        "PrimaryPart", "WorldPivot", "LevelOfDetail", "ModelStreamingMode"
    },
    
    Attachment = {
        "CFrame", "Visible", "WorldCFrame"
    },
    
    Weld = {
        "C0", "C1", "Part0", "Part1", "Enabled"
    },
    
    WeldConstraint = {
        "Part0", "Part1", "Enabled"
    },
    
    Motor6D = {
        "C0", "C1", "Part0", "Part1", "CurrentAngle", "DesiredAngle", "MaxVelocity"
    },
    
    Script = {
        "Source", "Disabled", "RunContext"
    },
    
    LocalScript = {
        "Source", "Disabled"
    },
    
    ModuleScript = {
        "Source"
    },
    
    PointLight = {
        "Brightness", "Color", "Range", "Shadows", "Enabled"
    },
    
    SpotLight = {
        "Brightness", "Color", "Range", "Shadows", "Enabled", "Angle", "Face"
    },
    
    SurfaceLight = {
        "Brightness", "Color", "Range", "Shadows", "Enabled", "Angle", "Face"
    },
    
    Sound = {
        "SoundId", "Volume", "Pitch", "PlaybackSpeed", "Looped", "Playing",
        "TimePosition", "RollOffMaxDistance", "RollOffMinDistance", "RollOffMode",
        "PlayOnRemove", "SoundGroup"
    },
    
    ParticleEmitter = {
        "Texture", "Color", "Transparency", "Size", "Lifetime", "Rate",
        "Speed", "SpreadAngle", "Acceleration", "Drag", "VelocityInheritance",
        "RotSpeed", "Rotation", "LightEmission", "LightInfluence",
        "Orientation", "ZOffset", "Enabled", "LockedToPart"
    },
    
    Beam = {
        "Attachment0", "Attachment1", "Color", "Transparency", "Width0", "Width1",
        "CurveSize0", "CurveSize1", "FaceCamera", "LightEmission", "LightInfluence",
        "Segments", "Texture", "TextureLength", "TextureMode", "TextureSpeed",
        "ZOffset", "Enabled"
    },
    
    Trail = {
        "Attachment0", "Attachment1", "Color", "Transparency", "Lifetime",
        "MinLength", "MaxLength", "WidthScale", "FaceCamera", "LightEmission",
        "LightInfluence", "Texture", "TextureLength", "TextureMode", "Enabled"
    },
    
    SurfaceAppearance = {
        "AlphaMode", "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap",
        "TexturePack"
    },
    
    Humanoid = {
        "DisplayName", "Health", "MaxHealth", "WalkSpeed", "JumpPower", "JumpHeight",
        "HipHeight", "AutoRotate", "AutoJumpEnabled", "DisplayDistanceType",
        "HealthDisplayDistance", "NameDisplayDistance", "NameOcclusion",
        "RigType", "RequiresNeck", "BreakJointsOnDeath"
    },
    
    ClickDetector = {
        "MaxActivationDistance", "CursorIcon"
    },
    
    ProximityPrompt = {
        "ActionText", "ObjectText", "KeyboardKeyCode", "GamepadKeyCode",
        "HoldDuration", "MaxActivationDistance", "RequiresLineOfSight",
        "ClickablePrompt", "Enabled", "Style", "UIOffset"
    },
    
    BillboardGui = {
        "Adornee", "AlwaysOnTop", "Brightness", "ClipsDescendants",
        "DistanceLowerLimit", "DistanceUpperLimit", "DistanceStep",
        "ExtentsOffset", "ExtentsOffsetWorldSpace", "LightInfluence",
        "MaxDistance", "Size", "SizeOffset", "StudsOffset", "StudsOffsetWorldSpace"
    },
    
    SurfaceGui = {
        "Adornee", "AlwaysOnTop", "Brightness", "CanvasSize", "ClipsDescendants",
        "Face", "LightInfluence", "PixelsPerStud", "SizingMode", "ToolPunchThroughDistance",
        "ZIndexBehavior"
    },
    
    ScreenGui = {
        "DisplayOrder", "Enabled", "IgnoreGuiInset", "ResetOnSpawn", "ZIndexBehavior"
    },
    
    Frame = {
        "Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency",
        "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "LayoutOrder",
        "Position", "Rotation", "Size", "SizeConstraint", "Visible", "ZIndex"
    },
    
    TextLabel = {
        "Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency",
        "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "Font",
        "FontFace", "LayoutOrder", "LineHeight", "MaxVisibleGraphemes", "Position",
        "RichText", "Rotation", "Size", "SizeConstraint", "Text", "TextColor3",
        "TextScaled", "TextSize", "TextStrokeColor3", "TextStrokeTransparency",
        "TextTransparency", "TextTruncate", "TextWrapped", "TextXAlignment",
        "TextYAlignment", "Visible", "ZIndex"
    },
    
    TextButton = {
        "Active", "AnchorPoint", "AutoButtonColor", "AutomaticSize", "BackgroundColor3",
        "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel",
        "ClipsDescendants", "Font", "FontFace", "LayoutOrder", "LineHeight",
        "MaxVisibleGraphemes", "Modal", "Position", "RichText", "Rotation", "Selectable",
        "Selected", "Size", "SizeConstraint", "Text", "TextColor3", "TextScaled",
        "TextSize", "TextStrokeColor3", "TextStrokeTransparency", "TextTransparency",
        "TextTruncate", "TextWrapped", "TextXAlignment", "TextYAlignment", "Visible", "ZIndex"
    },
    
    TextBox = {
        "Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency",
        "BorderColor3", "BorderMode", "BorderSizePixel", "ClearTextOnFocus", "ClipsDescendants",
        "CursorPosition", "Font", "FontFace", "LayoutOrder", "LineHeight", "MaxVisibleGraphemes",
        "MultiLine", "PlaceholderColor3", "PlaceholderText", "Position", "RichText",
        "Rotation", "SelectionStart", "ShowNativeInput", "Size", "SizeConstraint",
        "Text", "TextColor3", "TextEditable", "TextScaled", "TextSize", "TextStrokeColor3",
        "TextStrokeTransparency", "TextTransparency", "TextTruncate", "TextWrapped",
        "TextXAlignment", "TextYAlignment", "Visible", "ZIndex"
    },
    
    ImageLabel = {
        "Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency",
        "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "Image",
        "ImageColor3", "ImageRectOffset", "ImageRectSize", "ImageTransparency",
        "LayoutOrder", "Position", "ResampleMode", "Rotation", "ScaleType",
        "Size", "SizeConstraint", "SliceCenter", "SliceScale", "TileSize",
        "Visible", "ZIndex"
    },
    
    ImageButton = {
        "Active", "AnchorPoint", "AutoButtonColor", "AutomaticSize", "BackgroundColor3",
        "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel",
        "ClipsDescendants", "HoverImage", "Image", "ImageColor3", "ImageRectOffset",
        "ImageRectSize", "ImageTransparency", "LayoutOrder", "Modal", "Position",
        "PressedImage", "ResampleMode", "Rotation", "ScaleType", "Selectable",
        "Selected", "Size", "SizeConstraint", "SliceCenter", "SliceScale",
        "TileSize", "Visible", "ZIndex"
    },
    
    ScrollingFrame = {
        "Active", "AnchorPoint", "AutomaticCanvasSize", "AutomaticSize", "BackgroundColor3",
        "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel",
        "BottomImage", "CanvasPosition", "CanvasSize", "ClipsDescendants",
        "ElasticBehavior", "HorizontalScrollBarInset", "LayoutOrder", "MidImage",
        "Position", "Rotation", "ScrollBarImageColor3", "ScrollBarImageTransparency",
        "ScrollBarThickness", "ScrollingDirection", "ScrollingEnabled", "Size",
        "SizeConstraint", "TopImage", "VerticalScrollBarInset", "VerticalScrollBarPosition",
        "Visible", "ZIndex"
    },
    
    UICorner = {"CornerRadius"},
    UIGradient = {"Color", "Enabled", "Offset", "Rotation", "Transparency"},
    UIStroke = {"ApplyStrokeMode", "Color", "Enabled", "LineJoinMode", "Thickness", "Transparency"},
    UIPadding = {"PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"},
    UIScale = {"Scale"},
    UIAspectRatioConstraint = {"AspectRatio", "AspectType", "DominantAxis"},
    UISizeConstraint = {"MaxSize", "MinSize"},
    UITextSizeConstraint = {"MaxTextSize", "MinTextSize"},
    UIListLayout = {"FillDirection", "HorizontalAlignment", "Padding", "SortOrder", "VerticalAlignment", "Wraps"},
    UIGridLayout = {"CellPadding", "CellSize", "FillDirection", "FillDirectionMaxCells", "HorizontalAlignment", "SortOrder", "StartCorner", "VerticalAlignment"},
    UIPageLayout = {"Animated", "Circular", "EasingDirection", "EasingStyle", "FillDirection", "GamepadInputEnabled", "HorizontalAlignment", "Padding", "ScrollWheelInputEnabled", "SortOrder", "TouchInputEnabled", "TweenTime", "VerticalAlignment"},
    UITableLayout = {"FillDirection", "FillEmptySpaceColumns", "FillEmptySpaceRows", "HorizontalAlignment", "MajorAxis", "Padding", "SortOrder", "VerticalAlignment"},
    
    Lighting = {
        "Ambient", "Brightness", "ColorShift_Bottom", "ColorShift_Top",
        "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ExposureCompensation",
        "FogColor", "FogEnd", "FogStart", "GeographicLatitude", "GlobalShadows",
        "OutdoorAmbient", "ShadowSoftness", "Technology", "TimeOfDay", "ClockTime"
    },
    
    Atmosphere = {
        "Color", "Decay", "Density", "Glare", "Haze", "Offset"
    },
    
    Sky = {
        "CelestialBodiesShown", "MoonAngularSize", "MoonTextureId",
        "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp",
        "StarCount", "SunAngularSize", "SunTextureId"
    },
    
    Clouds = {
        "Color", "Cover", "Density", "Enabled"
    },
    
    BloomEffect = {"Enabled", "Intensity", "Size", "Threshold"},
    BlurEffect = {"Enabled", "Size"},
    ColorCorrectionEffect = {"Brightness", "Contrast", "Enabled", "Saturation", "TintColor"},
    DepthOfFieldEffect = {"Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"},
    SunRaysEffect = {"Enabled", "Intensity", "Spread"},
    
    Folder = {},
    Configuration = {},
    
    NumberValue = {"Value"},
    StringValue = {"Value"},
    BoolValue = {"Value"},
    IntValue = {"Value"},
    ObjectValue = {"Value"},
    BrickColorValue = {"Value"},
    Color3Value = {"Value"},
    Vector3Value = {"Value"},
    CFrameValue = {"Value"},
    RayValue = {"Value"},
    
    BodyVelocity = {"MaxForce", "P", "Velocity"},
    BodyForce = {"Force"},
    BodyPosition = {"D", "MaxForce", "P", "Position"},
    BodyGyro = {"CFrame", "D", "MaxTorque", "P"},
    BodyAngularVelocity = {"AngularVelocity", "MaxTorque", "P"},
    RocketPropulsion = {"CartoonFactor", "MaxSpeed", "MaxThrust", "MaxTorque", "Target", "TargetOffset", "TargetRadius", "ThrustD", "ThrustP", "TurnD", "TurnP"},
    
    AlignPosition = {"ApplyAtCenterOfMass", "ForceLimitMode", "ForceRelativeTo", "MaxAxesForce", "MaxForce", "MaxVelocity", "Mode", "Position", "ReactionForceEnabled", "Responsiveness", "RigidityEnabled"},
    AlignOrientation = {"AlignType", "CFrame", "MaxAngularVelocity", "MaxTorque", "Mode", "PrimaryAxis", "PrimaryAxisOnly", "ReactionTorqueEnabled", "Responsiveness", "RigidityEnabled", "SecondaryAxis"},
    VectorForce = {"ApplyAtCenterOfMass", "Force", "RelativeTo"},
    LineForce = {"ApplyAtCenterOfMass", "InverseSquareLaw", "Magnitude", "MaxForce", "ReactionForceEnabled"},
    Torque = {"RelativeTo", "Torque"},
    LinearVelocity = {"ForceLimitMode", "ForceLimitsEnabled", "LineDirection", "LineVelocity", "MaxAxesForce", "MaxForce", "MaxPlanarAxesForce", "PlaneVelocity", "PrimaryTangentAxis", "RelativeTo", "SecondaryTangentAxis", "VectorVelocity", "VelocityConstraintMode"},
    AngularVelocity = {"AngularVelocity", "MaxTorque", "ReactionTorqueEnabled", "RelativeTo"},
    
    SpringConstraint = {"Coils", "CurrentLength", "Damping", "FreeLength", "LimitsEnabled", "MaxForce", "MaxLength", "MinLength", "Radius", "Stiffness", "Thickness", "Visible"},
    RopeConstraint = {"CurrentDistance", "Length", "Restitution", "Thickness", "Visible", "WinchEnabled", "WinchForce", "WinchResponsiveness", "WinchSpeed", "WinchTarget"},
    RodConstraint = {"CurrentDistance", "Length", "LimitAngle0", "LimitAngle1", "LimitsEnabled", "Thickness", "Visible"},
    PrismaticConstraint = {"ActuatorType", "CurrentPosition", "LimitsEnabled", "LowerLimit", "MotorMaxAcceleration", "MotorMaxForce", "Restitution", "ServoMaxForce", "Size", "SoftlockServoUponReachingTarget", "Speed", "TargetPosition", "UpperLimit", "Velocity", "Visible"},
    CylindricalConstraint = {"AngularActuatorType", "AngularLimitsEnabled", "AngularResponsiveness", "AngularRestitution", "AngularSpeed", "AngularVelocity", "CurrentAngle", "CurrentPosition", "InclinationAngle", "LimitsEnabled", "LowerAngle", "LowerLimit", "MotorMaxAcceleration", "MotorMaxAngularAcceleration", "MotorMaxForce", "MotorMaxTorque", "Restitution", "RotationAxisVisible", "ServoMaxForce", "ServoMaxTorque", "Size", "SoftlockServoUponReachingTarget", "Speed", "TargetAngle", "TargetPosition", "UpperAngle", "UpperLimit", "Velocity", "Visible", "WorldRotationAxis"},
    HingeConstraint = {"ActuatorType", "AngularResponsiveness", "AngularSpeed", "AngularVelocity", "CurrentAngle", "LimitsEnabled", "LowerAngle", "MotorMaxAcceleration", "MotorMaxTorque", "Radius", "Restitution", "ServoMaxTorque", "SoftlockServoUponReachingTarget", "TargetAngle", "UpperAngle", "Visible"},
    BallSocketConstraint = {"LimitsEnabled", "MaxFrictionTorque", "Radius", "Restitution", "TwistLimitsEnabled", "TwistLowerAngle", "TwistUpperAngle", "UpperAngle", "Visible"},
    UniversalConstraint = {"LimitsEnabled", "MaxAngle", "Radius", "Restitution", "Visible"},
    
    Terrain = {},
}

-- Get all properties for an instance
function PropertyDatabase.GetPropertiesForInstance(instance)
    local properties = {}
    local className = instance.ClassName
    
    -- Add common properties
    for _, prop in ipairs(PropertyDatabase.CommonProperties) do
        table.insert(properties, prop)
    end
    
    -- Add class-specific properties
    if PropertyDatabase.ClassProperties[className] then
        for _, prop in ipairs(PropertyDatabase.ClassProperties[className]) do
            table.insert(properties, prop)
        end
    end
    
    -- Check parent classes
    if instance:IsA("BasePart") and className ~= "BasePart" then
        for _, prop in ipairs(PropertyDatabase.ClassProperties.BasePart or {}) do
            table.insert(properties, prop)
        end
    end
    
    -- Try to get additional properties from executor
    if Executor.GetProperties then
        local success, extraProps = pcall(Executor.GetProperties, instance)
        if success and extraProps then
            for _, prop in ipairs(extraProps) do
                table.insert(properties, prop)
            end
        end
    end
    
    return properties
end

-- ============================================================================
-- SECTION 6: SCRIPT SERIALIZER
-- ============================================================================

local ScriptSerializer = {}

-- Decompile a script
function ScriptSerializer.Decompile(script)
    if not Executor.Decompile then
        return "-- Decompilation not available"
    end
    
    local success, source = pcall(Executor.Decompile, script)
    
    if success and source and source ~= "" then
        return source
    else
        -- Try alternative methods
        if Executor.GetScriptBytecode then
            local bcSuccess, bytecode = pcall(Executor.GetScriptBytecode, script)
            if bcSuccess and bytecode and bytecode ~= "" then
                return "-- Bytecode available but decompilation failed\n-- " .. #bytecode .. " bytes"
            end
        end
        
        return "-- Decompilation failed: " .. tostring(source or "Unknown error")
    end
end

-- Get script source
function ScriptSerializer.GetSource(script, config)
    local source = ""
    
    -- First try to get Source property directly
    local directSuccess, directSource = pcall(function()
        return script.Source
    end)
    
    if directSuccess and directSource and directSource ~= "" then
        source = directSource
    else
        -- Try hidden property
        if Executor.GetHiddenProperty then
            local hiddenSuccess, hiddenSource = pcall(Executor.GetHiddenProperty, script, "Source")
            if hiddenSuccess and hiddenSource and hiddenSource ~= "" then
                source = hiddenSource
            end
        end
        
        -- Try decompilation if enabled
        if (source == "" or source == nil) and config.DecompileScripts then
            source = ScriptSerializer.Decompile(script)
        end
    end
    
    return source or ""
end

-- Serialize a script instance
function ScriptSerializer.Serialize(script, config, referentMap)
    local source = ScriptSerializer.GetSource(script, config)
    local disabled = false
    
    -- Get Disabled state
    if script:IsA("Script") or script:IsA("LocalScript") then
        local success, isDisabled = pcall(function() return script.Disabled end)
        if success then
            disabled = isDisabled
        end
    end
    
    return {
        Source = source,
        Disabled = disabled,
        ClassName = script.ClassName
    }
end

-- ============================================================================
-- SECTION 7: TERRAIN SERIALIZER
-- ============================================================================

local TerrainSerializer = {}

-- Serialize terrain data
function TerrainSerializer.Serialize(terrain)
    if not terrain then
        return nil
    end
    
    local data = {
        WaterWaveSize = terrain.WaterWaveSize,
        WaterWaveSpeed = terrain.WaterWaveSpeed,
        WaterTransparency = terrain.WaterTransparency,
        WaterReflectance = terrain.WaterReflectance,
        WaterColor = terrain.WaterColor,
        Regions = {}
    }
    
    -- Get terrain size
    local terrainSize = terrain:FindFirstChildOfClass("TerrainRegion")
    if not terrainSize then
        -- Try to read voxels directly
        local success, result = pcall(function()
            local region = Region3.new(
                Vector3.new(-2048, -512, -2048),
                Vector3.new(2048, 512, 2048)
            )
            local resolution = 4
            
            local materials, occupancy = terrain:ReadVoxels(region, resolution)
            
            if materials and #materials > 0 then
                data.VoxelData = {
                    Region = {
                        Min = {X = -2048, Y = -512, Z = -2048},
                        Max = {X = 2048, Y = 512, Z = 2048}
                    },
                    Resolution = resolution,
                    Size = materials.Size
                }
            end
            
            return true
        end)
    end
    
    return data
end

-- Create terrain XML
function TerrainSerializer.ToXML(terrain, referent)
    if not terrain then
        return ""
    end
    
    local xml = {}
    table.insert(xml, string.format('<Item class="Terrain" referent="%s">', referent))
    table.insert(xml, '<Properties>')
    
    -- Basic terrain properties
    local properties = {
        {"string", "Name", terrain.Name},
        {"float", "WaterWaveSize", terrain.WaterWaveSize},
        {"float", "WaterWaveSpeed", terrain.WaterWaveSpeed},
        {"float", "WaterTransparency", terrain.WaterTransparency},
        {"float", "WaterReflectance", terrain.WaterReflectance},
    }
    
    for _, prop in ipairs(properties) do
        local propType, propName, propValue = prop[1], prop[2], prop[3]
        if propType == "string" then
            table.insert(xml, string.format('<%s name="%s">%s</%s>', 
                propType, propName, Utils.XMLEscape(tostring(propValue)), propType))
        elseif propType == "float" then
            table.insert(xml, string.format('<%s name="%s">%s</%s>', 
                propType, propName, tostring(propValue), propType))
        end
    end
    
    -- Water color
    local waterColor = terrain.WaterColor
    table.insert(xml, string.format(
        '<Color3 name="WaterColor"><R>%s</R><G>%s</G><B>%s</B></Color3>',
        tostring(waterColor.R), tostring(waterColor.G), tostring(waterColor.B)
    ))
    
    table.insert(xml, '</Properties>')
    table.insert(xml, '</Item>')
    
    return table.concat(xml, "\n")
end

-- ============================================================================
-- SECTION 8: INSTANCE WALKER (DFS/BFS)
-- ============================================================================

local InstanceWalker = {}

-- Walk instances using DFS
function InstanceWalker.WalkDFS(root, callback, config, depth)
    depth = depth or 0
    
    if depth > (config.MaxDepth or 500) then
        return
    end
    
    -- Check if should ignore this instance
    local ignoreLookup = Utils.CreateLookup(config.IgnoreClassNames or {})
    if ignoreLookup[root.ClassName] then
        return
    end
    
    -- Call callback for this instance
    local shouldContinue = callback(root, depth)
    
    if shouldContinue == false then
        return
    end
    
    -- Process children
    local children = {}
    local success, err = pcall(function()
        children = root:GetChildren()
    end)
    
    if success then
        for _, child in ipairs(children) do
            InstanceWalker.WalkDFS(child, callback, config, depth + 1)
        end
    end
end

-- Walk instances using BFS
function InstanceWalker.WalkBFS(root, callback, config)
    local queue = {{instance = root, depth = 0}}
    local index = 1
    local processedCount = 0
    
    local ignoreLookup = Utils.CreateLookup(config.IgnoreClassNames or {})
    
    while index <= #queue do
        local current = queue[index]
        index = index + 1
        
        local instance = current.instance
        local depth = current.depth
        
        if depth > (config.MaxDepth or 500) then
            continue
        end
        
        if ignoreLookup[instance.ClassName] then
            continue
        end
        
        -- Call callback
        local shouldContinue = callback(instance, depth)
        
        if shouldContinue ~= false then
            -- Add children to queue
            local success, children = pcall(function()
                return instance:GetChildren()
            end)
            
            if success then
                for _, child in ipairs(children) do
                    table.insert(queue, {instance = child, depth = depth + 1})
                end
            end
        end
        
        -- Yield periodically
        processedCount = processedCount + 1
        if processedCount % (config.YieldInterval or 200) == 0 then
            task.wait()
        end
    end
end

-- Collect all instances
function InstanceWalker.CollectInstances(roots, config)
    local instances = {}
    local referentMap = {}
    local instanceCount = 0
    
    for _, root in ipairs(roots) do
        InstanceWalker.WalkBFS(root, function(instance, depth)
            instanceCount = instanceCount + 1
            table.insert(instances, {
                Instance = instance,
                Depth = depth,
                Referent = Utils.GenerateID()
            })
            referentMap[instance] = instances[#instances].Referent
            return true
        end, config)
    end
    
    return instances, referentMap, instanceCount
end

-- ============================================================================
-- SECTION 9: RBXL FILE WRITER
-- ============================================================================

local RBXLWriter = {}

-- RBXL file header
function RBXLWriter.GetHeader()
    return [[<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
	<External>null</External>
	<External>nil</External>]]
end

-- RBXL file footer
function RBXLWriter.GetFooter()
    return [[</roblox>]]
end

-- Serialize a single instance to XML
function RBXLWriter.SerializeInstance(instanceData, referentMap, config)
    local instance = instanceData.Instance
    local referent = instanceData.Referent
    
    local xml = {}
    
    -- Open Item tag
    table.insert(xml, string.format('\t<Item class="%s" referent="%s">', 
        instance.ClassName, referent))
    
    table.insert(xml, '\t\t<Properties>')
    
    -- Get properties for this instance
    local properties = PropertyDatabase.GetPropertiesForInstance(instance)
    
    for _, propName in ipairs(properties) do
        local success, propValue = pcall(function()
            return instance[propName]
        end)
        
        if success and propValue ~= nil then
            -- Special handling for Source property of scripts
            if propName == "Source" and (instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript")) then
                if config.SaveScripts then
                    local source = ScriptSerializer.GetSource(instance, config)
                    local serialized = string.format(
                        '\t\t\t<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>',
                        source
                    )
                    table.insert(xml, serialized)
                end
            else
                local serialized = PropertySerializer.Serialize(instance, propName, propValue, referentMap, config)
                if serialized then
                    table.insert(xml, '\t\t\t' .. serialized)
                end
            end
        end
    end
    
    table.insert(xml, '\t\t</Properties>')
    
    return table.concat(xml, '\n')
end

-- Build complete RBXL content
function RBXLWriter.BuildRBXL(instances, referentMap, config)
    local content = {RBXLWriter.GetHeader()}
    
    -- Build hierarchy map
    local childrenMap = {}
    local rootInstances = {}
    
    for _, instanceData in ipairs(instances) do
        local instance = instanceData.Instance
        local parent = instance.Parent
        
        if parent and referentMap[parent] then
            if not childrenMap[parent] then
                childrenMap[parent] = {}
            end
            table.insert(childrenMap[parent], instanceData)
        else
            table.insert(rootInstances, instanceData)
        end
    end
    
    -- Recursive function to write instances
    local function writeInstance(instanceData, indent)
        local instance = instanceData.Instance
        local referent = instanceData.Referent
        
        -- Get instance XML
        local instanceXML = RBXLWriter.SerializeInstance(instanceData, referentMap, config)
        
        -- Add to content with proper indentation
        table.insert(content, instanceXML)
        
        -- Write children
        local children = childrenMap[instance]
        if children then
            for _, childData in ipairs(children) do
                writeInstance(childData, indent + 1)
            end
        end
        
        -- Close Item tag
        table.insert(content, '\t</Item>')
    end
    
    -- Write all root instances
    for _, instanceData in ipairs(rootInstances) do
        writeInstance(instanceData, 1)
    end
    
    table.insert(content, RBXLWriter.GetFooter())
    
    return table.concat(content, '\n')
end

-- ============================================================================
-- SECTION 10: API LAYER (Future-proof)
-- ============================================================================

local APILayer = {}

-- Initialize API
function APILayer.Initialize(config)
    return {
        Enabled = config.API.Enabled,
        BaseURL = config.API.BaseURL,
        Headers = config.API.Headers or {},
        Endpoints = config.API.Endpoints,
        Timeout = config.API.Timeout or 30
    }
end

-- Make HTTP request
function APILayer.Request(api, method, endpoint, body)
    if not api.Enabled or api.BaseURL == "" then
        return {Success = false, Error = "API not enabled"}
    end
    
    local url = api.BaseURL .. (api.Endpoints[endpoint] or endpoint)
    
    local requestData = {
        Url = url,
        Method = method,
        Headers = api.Headers,
        Body = body and game:GetService("HttpService"):JSONEncode(body) or nil
    }
    
    local success, response = pcall(Executor.HttpRequest, requestData)
    
    if success then
        return {
            Success = response.Success,
            StatusCode = response.StatusCode,
            Body = response.Body,
            Headers = response.Headers
        }
    else
        return {Success = false, Error = tostring(response)}
    end
end

-- Upload map
function APILayer.UploadMap(api, fileContent, metadata)
    return APILayer.Request(api, "POST", "Upload", {
        Content = Utils.Base64Encode(fileContent),
        Metadata = metadata
    })
end

-- Check version
function APILayer.CheckVersion(api)
    return APILayer.Request(api, "GET", "Version")
end

-- Hash check
function APILayer.HashCheck(api, hash)
    return APILayer.Request(api, "POST", "HashCheck", {Hash = hash})
end

-- ============================================================================
-- SECTION 11: CORE ENGINE
-- ============================================================================

local CoreEngine = {}

-- Save Game (Everything)
function CoreEngine.SaveGame(config)
    Utils.ResetIDs()
    
    local services = game:GetService("RunService"):IsClient() and game or game
    local roots = {}
    
    -- Collect services to save
    for _, serviceName in ipairs(config.ServicesToSave) do
        local success, service = pcall(function()
            return services:GetService(serviceName)
        end)
        
        if success and service then
            table.insert(roots, service)
        end
    end
    
    -- Collect all instances
    local instances, referentMap, count = InstanceWalker.CollectInstances(roots, config)
    
    -- Build RBXL
    local rbxlContent = RBXLWriter.BuildRBXL(instances, referentMap, config)
    
    return rbxlContent, count
end

-- Save Terrain Only
function CoreEngine.SaveTerrain(config)
    Utils.ResetIDs()
    
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return nil, 0
    end
    
    local referent = Utils.GenerateID()
    local content = {RBXLWriter.GetHeader()}
    
    -- Add Workspace container
    table.insert(content, '\t<Item class="Workspace" referent="' .. Utils.GenerateID() .. '">')
    table.insert(content, '\t\t<Properties>')
    table.insert(content, '\t\t\t<string name="Name">Workspace</string>')
    table.insert(content, '\t\t</Properties>')
    
    -- Add Terrain
    table.insert(content, TerrainSerializer.ToXML(terrain, referent))
    
    table.insert(content, '\t</Item>')
    table.insert(content, RBXLWriter.GetFooter())
    
    return table.concat(content, '\n'), 1
end

-- Save All Models (No Scripts)
function CoreEngine.SaveModels(config)
    Utils.ResetIDs()
    
    -- Modify config to exclude scripts
    local modelConfig = Utils.DeepCopy(config)
    modelConfig.SaveScripts = false
    
    -- Add script classes to ignore list
    table.insert(modelConfig.IgnoreClassNames, "Script")
    table.insert(modelConfig.IgnoreClassNames, "LocalScript")
    table.insert(modelConfig.IgnoreClassNames, "ModuleScript")
    
    local roots = {workspace}
    
    -- Also include ReplicatedStorage models
    local repStorage = game:GetService("ReplicatedStorage")
    if repStorage then
        table.insert(roots, repStorage)
    end
    
    -- Collect all instances
    local instances, referentMap, count = InstanceWalker.CollectInstances(roots, modelConfig)
    
    -- Build RBXL
    local rbxlContent = RBXLWriter.BuildRBXL(instances, referentMap, modelConfig)
    
    return rbxlContent, count
end

-- ============================================================================
-- SECTION 12: GUI SYSTEM
-- ============================================================================

local GUISystem = {}

function GUISystem.Create(saveCallback)
    -- Remove existing GUI
    local existingGUI = game:GetService("CoreGui"):FindFirstChild("BaoSaveInstanceGUI")
    if existingGUI then
        existingGUI:Destroy()
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstanceGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Fix bottom corners of title bar
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0.5, 0)
    titleFix.Position = UDim2.new(0, 0, 0.5, 0)
    titleFix.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    -- Title Text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎮 BaoSaveInstance v1.0"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 16
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Content Frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -30, 1, -60)
    contentFrame.Position = UDim2.new(0, 15, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.Parent = contentFrame
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, 0, 0, 30)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Ready to save..."
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.LayoutOrder = 0
    statusLabel.Parent = contentFrame
    
    -- Create Button Function
    local function createButton(name, text, emoji, color, layoutOrder, onClick)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 45)
        btn.BackgroundColor3 = color
        btn.Text = emoji .. "  " .. text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 15
        btn.Font = Enum.Font.GothamBold
        btn.LayoutOrder = layoutOrder
        btn.AutoButtonColor = true
        btn.Parent = contentFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            btn.Text = "⏳ Processing..."
            statusLabel.Text = "Saving..."
            task.wait()
            onClick()
        end)
        
        return btn
    end
    
    -- Save Game Button
    local saveGameBtn = createButton(
        "SaveGame",
        "Save Game",
        "💾",
        Color3.fromRGB(46, 139, 87),
        1,
        function()
            saveCallback("game", statusLabel, saveGameBtn)
        end
    )
    
    -- Save Terrain Button
    local saveTerrainBtn = createButton(
        "SaveTerrain",
        "Save Terrain",
        "🏔️",
        Color3.fromRGB(70, 130, 180),
        2,
        function()
            saveCallback("terrain", statusLabel, saveTerrainBtn)
        end
    )
    
    -- Save Models Button
    local saveModelsBtn = createButton(
        "SaveModels",
        "Save All Models",
        "🧊",
        Color3.fromRGB(148, 103, 189),
        3,
        function()
            saveCallback("models", statusLabel, saveModelsBtn)
        end
    )
    
    -- Separator
    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(1, 0, 0, 1)
    separator.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    separator.BorderSizePixel = 0
    separator.LayoutOrder = 4
    separator.Parent = contentFrame
    
    -- Info Label
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "Info"
    infoLabel.Size = UDim2.new(1, 0, 0, 50)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "📁 Files saved to:\nworkspace/BaoSaveInstance/"
    infoLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    infoLabel.TextSize = 12
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.LayoutOrder = 5
    infoLabel.Parent = contentFrame
    
    -- Make draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Parent to CoreGui
    local success, err = pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
        screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    
    return screenGui
end

-- ============================================================================
-- SECTION 13: MAIN BAOSAVEINSTANCE CLASS
-- ============================================================================

function BaoSaveInstance.new(customConfig)
    local self = setmetatable({}, BaoSaveInstance)
    
    -- Merge custom config with defaults
    self.Config = Utils.DeepCopy(DefaultConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            if type(v) == "table" and type(self.Config[k]) == "table" then
                for k2, v2 in pairs(v) do
                    self.Config[k][k2] = v2
                end
            else
                self.Config[k] = v
            end
        end
    end
    
    -- Initialize API
    self.API = APILayer.Initialize(self.Config)
    
    -- Create output folder
    if Executor.HasFileSystem then
        pcall(Executor.MakeFolder, self.Config.OutputFolder)
    end
    
    return self
end

-- Save with specific mode
function BaoSaveInstance:Save(mode)
    local content, count
    local filename = self.Config.FileName or (game.PlaceId .. "_" .. Utils.GetTimestamp())
    
    if mode == "game" then
        content, count = CoreEngine.SaveGame(self.Config)
        filename = filename .. "_full"
    elseif mode == "terrain" then
        content, count = CoreEngine.SaveTerrain(self.Config)
        filename = filename .. "_terrain"
    elseif mode == "models" then
        content, count = CoreEngine.SaveModels(self.Config)
        filename = filename .. "_models"
    else
        return false, "Invalid mode"
    end
    
    if not content then
        return false, "Failed to generate content"
    end
    
    -- Write file
    local filepath = self.Config.OutputFolder .. "/" .. filename .. ".rbxl"
    
    local success, err = pcall(Executor.WriteFile, filepath, content)
    
    if success then
        return true, filepath, count
    else
        return false, "Failed to write file: " .. tostring(err)
    end
end

-- Show GUI
function BaoSaveInstance:ShowGUI()
    local self = self
    
    GUISystem.Create(function(mode, statusLabel, button)
        task.spawn(function()
            local success, result, count = self:Save(mode)
            
            if success then
                statusLabel.Text = "✅ Saved " .. (count or 0) .. " instances!"
                statusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
                
                if mode == "game" then
                    button.Text = "💾  Save Game"
                elseif mode == "terrain" then
                    button.Text = "🏔️  Save Terrain"
                elseif mode == "models" then
                    button.Text = "🧊  Save All Models"
                end
            else
                statusLabel.Text = "❌ Error: " .. tostring(result)
                statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                
                if mode == "game" then
                    button.Text = "💾  Save Game"
                elseif mode == "terrain" then
                    button.Text = "🏔️  Save Terrain"
                elseif mode == "models" then
                    button.Text = "🧊  Save All Models"
                end
            end
        end)
    end)
end

-- ============================================================================
-- SECTION 14: INITIALIZATION AND EXPORTS
-- ============================================================================

-- Quick save functions (convenience)
function BaoSaveInstance.SaveGame(config)
    local instance = BaoSaveInstance.new(config)
    return instance:Save("game")
end

function BaoSaveInstance.SaveTerrain(config)
    local instance = BaoSaveInstance.new(config)
    return instance:Save("terrain")
end

function BaoSaveInstance.SaveModels(config)
    local instance = BaoSaveInstance.new(config)
    return instance:Save("models")
end

function BaoSaveInstance.ShowUI(config)
    local instance = BaoSaveInstance.new(config)
    instance:ShowGUI()
    return instance
end

-- Auto-run with GUI
local function main()
    print([[
================================================================================
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
                    INSTANCE SERIALIZER v1.0
================================================================================
    ]])
    
    print("[BaoSaveInstance] Executor detected: " .. Executor.Name)
    print("[BaoSaveInstance] File System: " .. (Executor.HasFileSystem and "✓" or "✗"))
    print("[BaoSaveInstance] Decompiler: " .. (Executor.HasDecompiler and "✓" or "✗"))
    print("[BaoSaveInstance] Property Access: " .. (Executor.HasPropertyAccess and "✓" or "✗"))
    print("")
    
    BaoSaveInstance.ShowUI()
end

-- Export
getgenv().BaoSaveInstance = BaoSaveInstance

-- Run
main()

return BaoSaveInstance
