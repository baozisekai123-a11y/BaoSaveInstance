--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║              BaoSaveInstance - Advanced Edition                   ║
    ║                    Version 2.0 Professional                       ║
    ║                                                                   ║
    ║  Hỗ trợ: Xeno, Solara, TNG, Velocity, Wave                       ║
    ║  Không sử dụng: Synapse API, UniversalSynSaveInstance            ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 1: CONFIGURATION & INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════

local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance

-- Version Info
local VERSION = "2.0 Advanced"
local BUILD_DATE = "2024"

-- Configuration
local Config = {
    -- Save Settings
    SaveTerrain = true,
    SaveModels = true,
    SaveScripts = true,
    DecompileScripts = true,
    
    -- Performance
    YieldInterval = 100,
    MaxRetries = 3,
    ChunkSize = 1000,
    
    -- Output
    OutputFormat = "rbxl",
    CompressTerrain = false,
    
    -- UI
    EnableUI = true,
    AnimationSpeed = 0.3,
    Theme = "Dark",
    
    -- Advanced
    SaveHiddenInstances = true,
    SaveAttributes = true,
    SaveTags = true,
    PreserveHierarchy = true,
}

-- Services
local Services = {
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    ReplicatedFirst = game:GetService("ReplicatedFirst"),
    StarterGui = game:GetService("StarterGui"),
    StarterPack = game:GetService("StarterPack"),
    StarterPlayer = game:GetService("StarterPlayer"),
    Teams = game:GetService("Teams"),
    SoundService = game:GetService("SoundService"),
    Chat = game:GetService("Chat"),
    LocalizationService = game:GetService("LocalizationService"),
    TestService = game:GetService("TestService"),
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    UserInputService = game:GetService("UserInputService"),
    CoreGui = game:GetService("CoreGui"),
    TextService = game:GetService("TextService"),
}

-- Executor Detection
local ExecutorInfo = {
    Name = "Unknown",
    Version = "Unknown",
    Supported = false,
}

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 2: EXECUTOR COMPATIBILITY LAYER
-- ═══════════════════════════════════════════════════════════════════

local ExecutorFunctions = {}

-- Detect current executor
local function DetectExecutor()
    local executors = {
        {name = "Xeno", check = function() return Xeno ~= nil end},
        {name = "Solara", check = function() return Solara ~= nil or (identifyexecutor and identifyexecutor():lower():find("solara")) end},
        {name = "TNG", check = function() return TNG ~= nil or (identifyexecutor and identifyexecutor():lower():find("tng")) end},
        {name = "Velocity", check = function() return Velocity ~= nil or (identifyexecutor and identifyexecutor():lower():find("velocity")) end},
        {name = "Wave", check = function() return Wave ~= nil or (identifyexecutor and identifyexecutor():lower():find("wave")) end},
    }
    
    for _, exec in ipairs(executors) do
        local success, result = pcall(exec.check)
        if success and result then
            ExecutorInfo.Name = exec.name
            ExecutorInfo.Supported = true
            break
        end
    end
    
    -- Try to get version
    if identifyexecutor then
        local success, result = pcall(identifyexecutor)
        if success then
            ExecutorInfo.Version = result
        end
    end
    
    return ExecutorInfo
end

-- Initialize executor functions
local function InitExecutorFunctions()
    -- writefile
    ExecutorFunctions.writefile = writefile or function(path, content)
        error("writefile not supported")
    end
    
    -- readfile
    ExecutorFunctions.readfile = readfile or function(path)
        error("readfile not supported")
    end
    
    -- isfile
    ExecutorFunctions.isfile = isfile or function(path)
        return false
    end
    
    -- makefolder
    ExecutorFunctions.makefolder = makefolder or function(path)
        -- Optional
    end
    
    -- isfolder
    ExecutorFunctions.isfolder = isfolder or function(path)
        return false
    end
    
    -- getgenv
    ExecutorFunctions.getgenv = getgenv or function()
        return _G
    end
    
    -- gethiddenproperty
    ExecutorFunctions.gethiddenproperty = gethiddenproperty or function(instance, property)
        local success, value = pcall(function()
            return instance[property]
        end)
        return success and value or nil, success
    end
    
    -- sethiddenproperty
    ExecutorFunctions.sethiddenproperty = sethiddenproperty or function(instance, property, value)
        pcall(function()
            instance[property] = value
        end)
    end
    
    -- getproperties (custom implementation if not available)
    ExecutorFunctions.getproperties = getproperties or function(instance)
        return {}
    end
    
    -- gethiddenproperties
    ExecutorFunctions.gethiddenproperties = gethiddenproperties or function(instance)
        return {}
    end
    
    -- decompile
    ExecutorFunctions.decompile = decompile or function(script)
        return "-- Decompilation not supported by this executor"
    end
    
    -- getscriptbytecode
    ExecutorFunctions.getscriptbytecode = getscriptbytecode or function(script)
        return nil
    end
    
    -- getnilinstances
    ExecutorFunctions.getnilinstances = getnilinstances or function()
        return {}
    end
    
    -- getinstances
    ExecutorFunctions.getinstances = getinstances or function()
        return {}
    end
    
    -- getgc
    ExecutorFunctions.getgc = getgc or function()
        return {}
    end
    
    -- getloadedmodules
    ExecutorFunctions.getloadedmodules = getloadedmodules or function()
        return {}
    end
    
    -- isreadonly
    ExecutorFunctions.isreadonly = isreadonly or function(t)
        return false
    end
    
    -- setreadonly
    ExecutorFunctions.setreadonly = setreadonly or function(t, value)
        -- Optional
    end
    
    -- hookfunction
    ExecutorFunctions.hookfunction = hookfunction or function(old, new)
        return old
    end
    
    -- cloneref
    ExecutorFunctions.cloneref = cloneref or function(instance)
        return instance
    end
    
    -- getsenv
    ExecutorFunctions.getsenv = getsenv or function(script)
        return {}
    end
    
    -- getrawmetatable
    ExecutorFunctions.getrawmetatable = getrawmetatable or getmetatable
    
    -- setrawmetatable
    ExecutorFunctions.setrawmetatable = setrawmetatable or setmetatable
end

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 3: UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════

local Utils = {}

-- Safe call with retry
function Utils.SafeCall(func, maxRetries, ...)
    maxRetries = maxRetries or Config.MaxRetries
    local args = {...}
    
    for i = 1, maxRetries do
        local success, result = pcall(function()
            return func(unpack(args))
        end)
        
        if success then
            return true, result
        end
        
        if i < maxRetries then
            task.wait(0.1 * i)
        end
    end
    
    return false, nil
end

-- Escape XML special characters
function Utils.EscapeXML(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    
    local replacements = {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ['"'] = "&quot;",
        ["'"] = "&apos;",
    }
    
    for char, escape in pairs(replacements) do
        str = str:gsub(char, escape)
    end
    
    -- Remove invalid XML characters
    str = str:gsub("[\0-\8\11\12\14-\31]", "")
    
    return str
end

-- Generate unique ID
local idCounter = 0
function Utils.GenerateID()
    idCounter = idCounter + 1
    return "RBX" .. tostring(idCounter)
end

-- Reset ID counter
function Utils.ResetIDCounter()
    idCounter = 0
end

-- Format time
function Utils.FormatTime(seconds)
    if seconds < 60 then
        return string.format("%.1fs", seconds)
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), seconds % 60)
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

-- Format number
function Utils.FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.2fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.2fK", num / 1000)
    else
        return tostring(num)
    end
end

-- Deep clone table
function Utils.DeepClone(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = Utils.DeepClone(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Get game name
function Utils.GetGameName()
    local name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    -- Clean name for filename
    name = name:gsub("[^%w%s%-_]", ""):gsub("%s+", "_")
    if #name > 50 then
        name = name:sub(1, 50)
    end
    return name
end

-- Yield periodically to prevent freezing
local yieldCounter = 0
function Utils.Yield()
    yieldCounter = yieldCounter + 1
    if yieldCounter >= Config.YieldInterval then
        yieldCounter = 0
        task.wait()
    end
end

-- Force yield
function Utils.ForceYield()
    yieldCounter = 0
    task.wait()
end

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 4: PROPERTY DATABASE
-- ═══════════════════════════════════════════════════════════════════

local PropertyDatabase = {}

-- Default properties that should be saved for each class
PropertyDatabase.ClassProperties = {
    -- BasePart properties
    BasePart = {
        "Anchored", "CanCollide", "CanQuery", "CanTouch", "CastShadow",
        "Color", "Material", "MaterialVariant", "Reflectance", "Transparency",
        "Size", "CFrame", "Massless", "RootPriority", "CustomPhysicalProperties",
        "CollisionGroup", "Locked"
    },
    
    Part = {
        "Shape"
    },
    
    MeshPart = {
        "MeshId", "TextureID", "CollisionFidelity", "RenderFidelity",
        "DoubleSided"
    },
    
    UnionOperation = {
        "AssetId", "CollisionFidelity", "RenderFidelity", "SmoothingAngle",
        "UsePartColor"
    },
    
    TrussPart = {
        "Style"
    },
    
    WedgePart = {},
    
    CornerWedgePart = {},
    
    -- Light properties
    Light = {
        "Brightness", "Color", "Enabled", "Shadows"
    },
    
    PointLight = {
        "Range"
    },
    
    SpotLight = {
        "Angle", "Face", "Range"
    },
    
    SurfaceLight = {
        "Angle", "Face", "Range"
    },
    
    -- Decal/Texture
    Decal = {
        "Color3", "Face", "Texture", "Transparency", "ZIndex"
    },
    
    Texture = {
        "OffsetStudsU", "OffsetStudsV", "StudsPerTileU", "StudsPerTileV"
    },
    
    -- GUI
    GuiObject = {
        "Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3",
        "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel",
        "ClipsDescendants", "LayoutOrder", "Position", "Rotation",
        "Selectable", "Size", "SizeConstraint", "Visible", "ZIndex"
    },
    
    Frame = {},
    
    TextLabel = {
        "Font", "FontFace", "LineHeight", "MaxVisibleGraphemes",
        "RichText", "Text", "TextColor3", "TextScaled", "TextSize",
        "TextStrokeColor3", "TextStrokeTransparency", "TextTransparency",
        "TextTruncate", "TextWrapped", "TextXAlignment", "TextYAlignment"
    },
    
    TextButton = {
        "AutoButtonColor", "Modal"
    },
    
    TextBox = {
        "ClearTextOnFocus", "MultiLine", "PlaceholderColor3", "PlaceholderText",
        "ShowNativeInput", "TextEditable"
    },
    
    ImageLabel = {
        "Image", "ImageColor3", "ImageRectOffset", "ImageRectSize",
        "ImageTransparency", "ResampleMode", "ScaleType", "SliceCenter",
        "SliceScale", "TileSize"
    },
    
    ImageButton = {
        "HoverImage", "PressedImage"
    },
    
    ScrollingFrame = {
        "AutomaticCanvasSize", "BottomImage", "CanvasPosition", "CanvasSize",
        "ElasticBehavior", "HorizontalScrollBarInset", "MidImage",
        "ScrollBarImageColor3", "ScrollBarImageTransparency", "ScrollBarThickness",
        "ScrollingDirection", "ScrollingEnabled", "TopImage",
        "VerticalScrollBarInset", "VerticalScrollBarPosition"
    },
    
    ViewportFrame = {
        "Ambient", "CurrentCamera", "ImageColor3", "ImageTransparency",
        "LightColor", "LightDirection"
    },
    
    BillboardGui = {
        "Active", "Adornee", "AlwaysOnTop", "Brightness", "ClipsDescendants",
        "DistanceLowerLimit", "DistanceStep", "DistanceUpperLimit",
        "ExtentsOffset", "ExtentsOffsetWorldSpace", "LightInfluence",
        "MaxDistance", "PlayerToHideFrom", "Size", "SizeOffset", "StudsOffset",
        "StudsOffsetWorldSpace"
    },
    
    SurfaceGui = {
        "Active", "Adornee", "AlwaysOnTop", "Brightness", "CanvasSize",
        "ClipsDescendants", "Face", "LightInfluence", "PixelsPerStud",
        "SizingMode", "ToolPunchThroughDistance", "ZOffset"
    },
    
    ScreenGui = {
        "DisplayOrder", "Enabled", "IgnoreGuiInset", "ResetOnSpawn",
        "ZIndexBehavior"
    },
    
    -- Constraint
    Constraint = {
        "Attachment0", "Attachment1", "Color", "Enabled", "Visible"
    },
    
    AlignOrientation = {
        "AlignType", "CFrame", "MaxAngularVelocity", "MaxTorque",
        "Mode", "PrimaryAxisOnly", "ReactionTorqueEnabled", "Responsiveness",
        "RigidityEnabled"
    },
    
    AlignPosition = {
        "ApplyAtCenterOfMass", "ForceLimitMode", "ForceRelativeTo",
        "MaxAxesForce", "MaxForce", "MaxVelocity", "Mode", "Position",
        "ReactionForceEnabled", "Responsiveness", "RigidityEnabled"
    },
    
    BallSocketConstraint = {
        "LimitsEnabled", "MaxFrictionTorque", "Radius", "Restitution",
        "TwistLimitsEnabled", "TwistLowerAngle", "TwistUpperAngle",
        "UpperAngle"
    },
    
    HingeConstraint = {
        "ActuatorType", "AngularResponsiveness", "AngularSpeed",
        "AngularVelocity", "LimitsEnabled", "LowerAngle", "MotorMaxAcceleration",
        "MotorMaxTorque", "Radius", "Restitution", "ServoMaxTorque",
        "SoftlockServoUponReachingTarget", "TargetAngle", "UpperAngle"
    },
    
    PrismaticConstraint = {
        "ActuatorType", "LimitsEnabled", "LowerLimit", "MotorMaxAcceleration",
        "MotorMaxForce", "Restitution", "ServoMaxForce", "Size", "Speed",
        "SoftlockServoUponReachingTarget", "TargetPosition", "UpperLimit",
        "Velocity"
    },
    
    CylindricalConstraint = {
        "AngularActuatorType", "AngularLimitsEnabled", "AngularResponsiveness",
        "AngularRestitution", "AngularSpeed", "AngularVelocity",
        "InclinationAngle", "LimitsEnabled", "LowerAngle", "LowerLimit",
        "MotorMaxAngularAcceleration", "MotorMaxForce", "MotorMaxTorque",
        "Restitution", "RotationAxisVisible", "ServoMaxForce", "ServoMaxTorque",
        "Size", "SoftlockServoUponReachingTarget", "Speed", "TargetAngle",
        "TargetPosition", "UpperAngle", "UpperLimit", "Velocity",
        "WorldRotationAxis"
    },
    
    RopeConstraint = {
        "Length", "Restitution", "Thickness", "WinchEnabled", "WinchForce",
        "WinchResponsiveness", "WinchSpeed", "WinchTarget"
    },
    
    RodConstraint = {
        "Length", "LimitAngle0", "LimitAngle1", "LimitsEnabled", "Thickness"
    },
    
    SpringConstraint = {
        "Coils", "Damping", "FreeLength", "LimitsEnabled", "MaxForce",
        "MaxLength", "MinLength", "Radius", "Stiffness", "Thickness"
    },
    
    WeldConstraint = {
        "Enabled", "Part0", "Part1"
    },
    
    Weld = {
        "C0", "C1", "Enabled", "Part0", "Part1"
    },
    
    Motor6D = {
        "C0", "C1", "CurrentAngle", "DesiredAngle", "Enabled",
        "MaxVelocity", "Part0", "Part1"
    },
    
    -- Attachment
    Attachment = {
        "CFrame", "Visible", "WorldCFrame"
    },
    
    -- Model
    Model = {
        "LevelOfDetail", "PrimaryPart", "WorldPivot"
    },
    
    -- Sound
    Sound = {
        "EmitterSize", "LoopRegion", "Looped", "MaxDistance", "PlayOnRemove",
        "PlaybackRegion", "PlaybackRegionsEnabled", "PlaybackSpeed",
        "Playing", "RollOffMaxDistance", "RollOffMinDistance", "RollOffMode",
        "SoundGroup", "SoundId", "TimePosition", "Volume"
    },
    
    -- ParticleEmitter
    ParticleEmitter = {
        "Acceleration", "Brightness", "Color", "Drag", "EmissionDirection",
        "Enabled", "FlipbookFramerate", "FlipbookIncompatible", "FlipbookLayout",
        "FlipbookMode", "FlipbookStartRandom", "Lifetime", "LightEmission",
        "LightInfluence", "LockedToPart", "Orientation", "Rate", "RotSpeed",
        "Rotation", "Shape", "ShapeInOut", "ShapePartial", "ShapeStyle",
        "Size", "Speed", "SpreadAngle", "Squash", "Texture", "TimeScale",
        "Transparency", "VelocityInheritance", "WindAffectsDrag", "ZOffset"
    },
    
    -- Beam
    Beam = {
        "Attachment0", "Attachment1", "Brightness", "Color", "CurveSize0",
        "CurveSize1", "Enabled", "FaceCamera", "LightEmission", "LightInfluence",
        "Segments", "Texture", "TextureLength", "TextureMode", "TextureSpeed",
        "Transparency", "Width0", "Width1", "ZOffset"
    },
    
    -- Trail
    Trail = {
        "Attachment0", "Attachment1", "Brightness", "Color", "Enabled",
        "FaceCamera", "Lifetime", "LightEmission", "LightInfluence",
        "MaxLength", "MinLength", "Texture", "TextureLength", "TextureMode",
        "Transparency", "WidthScale"
    },
    
    -- Humanoid
    Humanoid = {
        "AutoJumpEnabled", "AutoRotate", "AutomaticScalingEnabled",
        "BreakJointsOnDeath", "CameraOffset", "DisplayDistanceType",
        "DisplayName", "EvaluateStateMachine", "HealthDisplayDistance",
        "HealthDisplayType", "HipHeight", "JumpHeight", "JumpPower",
        "MaxHealth", "MaxSlopeAngle", "MoveDirection", "NameDisplayDistance",
        "NameOcclusion", "PlatformStand", "RequiresNeck", "RigType",
        "RootPart", "SeatPart", "Sit", "TargetPoint", "UseJumpPower",
        "WalkSpeed", "WalkToPart", "WalkToPoint"
    },
    
    -- Camera
    Camera = {
        "CFrame", "CameraSubject", "CameraType", "DiagonalFieldOfView",
        "FieldOfView", "FieldOfViewMode", "Focus", "HeadLocked", "HeadScale",
        "MaxAxisFieldOfView", "NearPlaneZ", "VRTiltAndRollEnabled"
    },
    
    -- Atmosphere
    Atmosphere = {
        "Color", "Decay", "Density", "Glare", "Haze", "Offset"
    },
    
    -- Sky
    Sky = {
        "CelestialBodiesShown", "MoonAngularSize", "MoonTextureId",
        "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt",
        "SkyboxUp", "StarCount", "SunAngularSize", "SunTextureId"
    },
    
    -- Clouds
    Clouds = {
        "Color", "Cover", "Density", "Enabled"
    },
    
    -- ColorCorrection
    ColorCorrectionEffect = {
        "Brightness", "Contrast", "Enabled", "Saturation", "TintColor"
    },
    
    -- BloomEffect
    BloomEffect = {
        "Enabled", "Intensity", "Size", "Threshold"
    },
    
    -- BlurEffect
    BlurEffect = {
        "Enabled", "Size"
    },
    
    -- DepthOfFieldEffect
    DepthOfFieldEffect = {
        "Enabled", "FarIntensity", "FocusDistance", "InFocusRadius",
        "NearIntensity"
    },
    
    -- SunRaysEffect
    SunRaysEffect = {
        "Enabled", "Intensity", "Spread"
    },
    
    -- Script types
    Script = {
        "Disabled", "LinkedSource"
    },
    
    LocalScript = {
        "Disabled", "LinkedSource"
    },
    
    ModuleScript = {
        "LinkedSource"
    },
    
    -- Value types
    BoolValue = {"Value"},
    BrickColorValue = {"Value"},
    CFrameValue = {"Value"},
    Color3Value = {"Value"},
    IntValue = {"Value"},
    NumberValue = {"Value"},
    ObjectValue = {"Value"},
    RayValue = {"Value"},
    StringValue = {"Value"},
    Vector3Value = {"Value"},
    
    -- Configuration
    Configuration = {},
    
    -- Folder
    Folder = {},
    
    -- Tool
    Tool = {
        "CanBeDropped", "Enabled", "Grip", "GripForward", "GripPos",
        "GripRight", "GripUp", "ManualActivationOnly", "RequiresHandle",
        "ToolTip"
    },
    
    -- Accessory
    Accessory = {
        "AccessoryType", "AttachmentPoint"
    },
    
    -- SpecialMesh
    SpecialMesh = {
        "MeshId", "MeshType", "Offset", "Scale", "TextureId", "VertexColor"
    },
    
    BlockMesh = {
        "Offset", "Scale", "VertexColor"
    },
    
    CylinderMesh = {
        "Offset", "Scale", "VertexColor"
    },
    
    -- SurfaceAppearance
    SurfaceAppearance = {
        "AlphaMode", "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap",
        "TexturePack"
    },
    
    -- MaterialVariant
    MaterialVariant = {
        "BaseMaterial", "ColorMap", "CustomPhysicalProperties", "MetalnessMap",
        "NormalMap", "RoughnessMap", "StudsPerTile"
    },
    
    -- ProximityPrompt
    ProximityPrompt = {
        "ActionText", "AutoLocalize", "ClickablePrompt", "Enabled",
        "ExclusivityMode", "GamepadKeyCode", "HoldDuration", "KeyboardKeyCode",
        "MaxActivationDistance", "ObjectText", "RequiresLineOfSight",
        "RootLocalizationTable", "Style", "UIOffset"
    },
    
    -- ClickDetector
    ClickDetector = {
        "CursorIcon", "MaxActivationDistance"
    },
    
    -- TouchTransmitter
    TouchTransmitter = {},
    
    -- ForceField
    ForceField = {
        "Visible"
    },
    
    -- Explosion
    Explosion = {
        "BlastPressure", "BlastRadius", "DestroyJointRadiusPercent",
        "ExplosionType", "Position", "TimeScale", "Visible"
    },
    
    -- Fire
    Fire = {
        "Color", "Enabled", "Heat", "SecondaryColor", "Size", "TimeScale"
    },
    
    -- Smoke
    Smoke = {
        "Color", "Enabled", "Opacity", "RiseVelocity", "Size", "TimeScale"
    },
    
    -- Sparkles
    Sparkles = {
        "Enabled", "SparkleColor", "TimeScale"
    },
    
    -- Highlight
    Highlight = {
        "Adornee", "DepthMode", "Enabled", "FillColor", "FillTransparency",
        "OutlineColor", "OutlineTransparency"
    },
    
    -- SelectionBox
    SelectionBox = {
        "Adornee", "Color3", "LineThickness", "SurfaceColor3",
        "SurfaceTransparency", "Transparency", "Visible"
    },
    
    -- NumberSequence related
    UIGradient = {
        "Color", "Enabled", "Offset", "Rotation", "Transparency"
    },
    
    -- UI Layout
    UIListLayout = {
        "FillDirection", "HorizontalAlignment", "ItemLineAlignment",
        "Padding", "SortOrder", "VerticalAlignment", "Wraps"
    },
    
    UIGridLayout = {
        "CellPadding", "CellSize", "FillDirection", "FillDirectionMaxCells",
        "HorizontalAlignment", "SortOrder", "StartCorner", "VerticalAlignment"
    },
    
    UIPageLayout = {
        "Animated", "Circular", "EasingDirection", "EasingStyle",
        "FillDirection", "GamepadInputEnabled", "HorizontalAlignment",
        "Padding", "ScrollWheelInputEnabled", "SortOrder", "TouchInputEnabled",
        "TweenTime", "VerticalAlignment"
    },
    
    UITableLayout = {
        "FillDirection", "FillEmptySpaceColumns", "FillEmptySpaceRows",
        "HorizontalAlignment", "MajorAxis", "Padding", "SortOrder",
        "VerticalAlignment"
    },
    
    UICorner = {
        "CornerRadius"
    },
    
    UIPadding = {
        "PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"
    },
    
    UIScale = {
        "Scale"
    },
    
    UISizeConstraint = {
        "MaxSize", "MinSize"
    },
    
    UITextSizeConstraint = {
        "MaxTextSize", "MinTextSize"
    },
    
    UIAspectRatioConstraint = {
        "AspectRatio", "AspectType", "DominantAxis"
    },
    
    UIStroke = {
        "ApplyStrokeMode", "Color", "Enabled", "LineJoinMode", "Thickness",
        "Transparency"
    },
}

-- Properties that reference other instances
PropertyDatabase.ReferenceProperties = {
    "Adornee", "Attachment0", "Attachment1", "CurrentCamera", "Part0", "Part1",
    "PrimaryPart", "RootPart", "SeatPart", "WalkToPart", "SoundGroup",
    "LinkedSource", "CameraSubject", "PlayerToHideFrom", "Value"
}

-- Properties that should be ignored
PropertyDatabase.IgnoreProperties = {
    "Parent", "DataCost", "RobloxLocked", "Archivable", "className",
    "ClassName"
}

-- Classes that should be skipped entirely
PropertyDatabase.SkipClasses = {
    "Player", "PlayerGui", "PlayerScripts", "Backpack", "StarterGear"
}

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 5: PROPERTY SERIALIZER
-- ═══════════════════════════════════════════════════════════════════

local PropertySerializer = {}

-- Serialize a value to XML format
function PropertySerializer.SerializeValue(value, propertyName)
    local valueType = typeof(value)
    
    if valueType == "string" then
        return string.format('<string name="%s">%s</string>', propertyName, Utils.EscapeXML(value))
        
    elseif valueType == "number" then
        if value == math.floor(value) and math.abs(value) < 2^31 then
            return string.format('<int name="%s">%d</int>', propertyName, value)
        else
            return string.format('<double name="%s">%s</double>', propertyName, tostring(value))
        end
        
    elseif valueType == "boolean" then
        return string.format('<bool name="%s">%s</bool>', propertyName, tostring(value))
        
    elseif valueType == "Vector3" then
        return string.format([[<Vector3 name="%s">
    <X>%s</X>
    <Y>%s</Y>
    <Z>%s</Z>
</Vector3>]], propertyName, value.X, value.Y, value.Z)
        
    elseif valueType == "Vector2" then
        return string.format([[<Vector2 name="%s">
    <X>%s</X>
    <Y>%s</Y>
</Vector2>]], propertyName, value.X, value.Y)
        
    elseif valueType == "CFrame" then
        local pos = value.Position
        local rx, ry, rz = value:ToEulerAnglesXYZ()
        local components = {value:GetComponents()}
        return string.format([[<CoordinateFrame name="%s">
    <X>%s</X>
    <Y>%s</Y>
    <Z>%s</Z>
    <R00>%s</R00>
    <R01>%s</R01>
    <R02>%s</R02>
    <R10>%s</R10>
    <R11>%s</R11>
    <R12>%s</R12>
    <R20>%s</R20>
    <R21>%s</R21>
    <R22>%s</R22>
</CoordinateFrame>]], propertyName, 
            components[1], components[2], components[3],
            components[4], components[5], components[6],
            components[7], components[8], components[9],
            components[10], components[11], components[12])
        
    elseif valueType == "Color3" then
        return string.format([[<Color3 name="%s">
    <R>%s</R>
    <G>%s</G>
    <B>%s</B>
</Color3>]], propertyName, value.R, value.G, value.B)
        
    elseif valueType == "BrickColor" then
        return string.format('<int name="%s">%d</int>', propertyName, value.Number)
        
    elseif valueType == "UDim" then
        return string.format([[<UDim name="%s">
    <S>%s</S>
    <O>%d</O>
</UDim>]], propertyName, value.Scale, value.Offset)
        
    elseif valueType == "UDim2" then
        return string.format([[<UDim2 name="%s">
    <XS>%s</XS>
    <XO>%d</XO>
    <YS>%s</YS>
    <YO>%d</YO>
</UDim2>]], propertyName, value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
        
    elseif valueType == "Rect" then
        return string.format([[<Rect2D name="%s">
    <min>
        <X>%s</X>
        <Y>%s</Y>
    </min>
    <max>
        <X>%s</X>
        <Y>%s</Y>
    </max>
</Rect2D>]], propertyName, value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)
        
    elseif valueType == "EnumItem" then
        return string.format('<token name="%s">%d</token>', propertyName, value.Value)
        
    elseif valueType == "NumberSequence" then
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%s %s %s", kp.Time, kp.Value, kp.Envelope))
        end
        return string.format('<NumberSequence name="%s">%s</NumberSequence>', 
            propertyName, table.concat(keypoints, " "))
        
    elseif valueType == "ColorSequence" then
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%s %s %s %s 0", 
                kp.Time, kp.Value.R, kp.Value.G, kp.Value.B))
        end
        return string.format('<ColorSequence name="%s">%s</ColorSequence>', 
            propertyName, table.concat(keypoints, " "))
        
    elseif valueType == "NumberRange" then
        return string.format([[<NumberRange name="%s">%s %s</NumberRange>]], 
            propertyName, value.Min, value.Max)
        
    elseif valueType == "PhysicalProperties" then
        if value then
            return string.format([[<PhysicalProperties name="%s">
    <CustomPhysics>true</CustomPhysics>
    <Density>%s</Density>
    <Friction>%s</Friction>
    <Elasticity>%s</Elasticity>
    <FrictionWeight>%s</FrictionWeight>
    <ElasticityWeight>%s</ElasticityWeight>
</PhysicalProperties>]], propertyName, 
                value.Density, value.Friction, value.Elasticity, 
                value.FrictionWeight, value.ElasticityWeight)
        else
            return string.format([[<PhysicalProperties name="%s">
    <CustomPhysics>false</CustomPhysics>
</PhysicalProperties>]], propertyName)
        end
        
    elseif valueType == "Ray" then
        return string.format([[<Ray name="%s">
    <origin>
        <X>%s</X>
        <Y>%s</Y>
        <Z>%s</Z>
    </origin>
    <direction>
        <X>%s</X>
        <Y>%s</Y>
        <Z>%s</Z>
    </direction>
</Ray>]], propertyName, 
            value.Origin.X, value.Origin.Y, value.Origin.Z,
            value.Direction.X, value.Direction.Y, value.Direction.Z)
        
    elseif valueType == "Faces" then
        local faces = {}
        if value.Top then table.insert(faces, "Top") end
        if value.Bottom then table.insert(faces, "Bottom") end
        if value.Left then table.insert(faces, "Left") end
        if value.Right then table.insert(faces, "Right") end
        if value.Back then table.insert(faces, "Back") end
        if value.Front then table.insert(faces, "Front") end
        return string.format('<Faces name="%s">%s</Faces>', propertyName, table.concat(faces, ", "))
        
    elseif valueType == "Axes" then
        local axes = {}
        if value.X then table.insert(axes, "X") end
        if value.Y then table.insert(axes, "Y") end
        if value.Z then table.insert(axes, "Z") end
        return string.format('<Axes name="%s">%s</Axes>', propertyName, table.concat(axes, ", "))
        
    elseif valueType == "Font" then
        return string.format([[<Font name="%s">
    <Family><url>%s</url></Family>
    <Weight>%d</Weight>
    <Style>%s</Style>
</Font>]], propertyName, 
            Utils.EscapeXML(value.Family), value.Weight.Value, value.Style.Name)
        
    elseif valueType == "Instance" then
        -- Reference to another instance, will be handled separately
        return nil
        
    elseif valueType == "nil" then
        return string.format('<null name="%s"/>', propertyName)
        
    else
        -- Unknown type, try to convert to string
        local success, str = pcall(tostring, value)
        if success then
            return string.format('<string name="%s">%s</string>', propertyName, Utils.EscapeXML(str))
        end
        return nil
    end
end

-- Get all properties of an instance
function PropertySerializer.GetProperties(instance)
    local properties = {}
    local className = instance.ClassName
    
    -- Collect property names from database
    local propNames = {}
    
    -- Add properties from class hierarchy
    local function addClassProperties(class)
        if PropertyDatabase.ClassProperties[class] then
            for _, prop in ipairs(PropertyDatabase.ClassProperties[class]) do
                propNames[prop] = true
            end
        end
    end
    
    -- Check current class and parent classes
    addClassProperties(className)
    
    -- Common parent classes
    local parentClasses = {
        Part = {"BasePart"},
        MeshPart = {"BasePart"},
        UnionOperation = {"BasePart"},
        WedgePart = {"BasePart"},
        CornerWedgePart = {"BasePart"},
        TrussPart = {"BasePart"},
        SpawnLocation = {"BasePart"},
        Seat = {"BasePart"},
        VehicleSeat = {"BasePart"},
        PointLight = {"Light"},
        SpotLight = {"Light"},
        SurfaceLight = {"Light"},
        Texture = {"Decal"},
        TextButton = {"TextLabel", "GuiObject"},
        TextBox = {"TextLabel", "GuiObject"},
        TextLabel = {"GuiObject"},
        ImageButton = {"ImageLabel", "GuiObject"},
        ImageLabel = {"GuiObject"},
        Frame = {"GuiObject"},
        ScrollingFrame = {"GuiObject"},
        ViewportFrame = {"GuiObject"},
        CanvasGroup = {"GuiObject"},
    }
    
    if parentClasses[className] then
        for _, parent in ipairs(parentClasses[className]) do
            addClassProperties(parent)
        end
    end
    
    -- Try to get properties
    for propName in pairs(propNames) do
        if not PropertyDatabase.IgnoreProperties[propName] then
            local success, value = pcall(function()
                return instance[propName]
            end)
            
            if success and value ~= nil then
                properties[propName] = value
            end
        end
    end
    
    -- Try to get hidden properties if available
    if ExecutorFunctions.gethiddenproperties then
        local success, hiddenProps = pcall(ExecutorFunctions.gethiddenproperties, instance)
        if success and hiddenProps then
            for propName, value in pairs(hiddenProps) do
                if not PropertyDatabase.IgnoreProperties[propName] then
                    properties[propName] = value
                end
            end
        end
    end
    
    return properties
end

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 6: SCRIPT HANDLER
-- ═══════════════════════════════════════════════════════════════════

local ScriptHandler = {}

-- Decompile a script
function ScriptHandler.Decompile(script)
    if not Config.DecompileScripts then
        return "-- Decompilation disabled"
    end
    
    local source = nil
    
    -- Try to get source directly (for LocalScripts that haven't run)
    local success, directSource = pcall(function()
        return script.Source
    end)
    
    if success and directSource and #directSource > 0 then
        source = directSource
    else
        -- Try decompiler
        for i = 1, Config.MaxRetries do
            local decompileSuccess, result = pcall(function()
                return ExecutorFunctions.decompile(script)
            end)
            
            if decompileSuccess and result and #result > 0 then
                source = result
                break
            end
            
            task.wait(0.1)
        end
    end
    
    if not source or #source == 0 then
        source = string.format([[
-- Failed to decompile script
-- Script Name: %s
-- Script Type: %s
-- Parent: %s
]], script.Name, script.ClassName, script.Parent and script.Parent:GetFullName() or "nil")
    end
    
    -- Clean and format source
    source = ScriptHandler.CleanSource(source)
    
    return source
end

-- Clean and format script source
function ScriptHandler.CleanSource(source)
    -- Remove common obfuscation patterns
    -- (Basic cleaning - advanced deobfuscation would require more complex logic)
    
    -- Remove unnecessary whitespace at line ends
    source = source:gsub("[ \t]+\n", "\n")
    
    -- Remove multiple empty lines
    source = source:gsub("\n\n\n+", "\n\n")
    
    -- Trim leading/trailing whitespace
    source = source:match("^%s*(.-)%s*$") or source
    
    return source
end

-- Serialize script source for XML
function ScriptHandler.SerializeSource(source)
    -- Encode in ProtectedString format
    return string.format('<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>', source)
end

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 7: TERRAIN HANDLER
-- ═══════════════════════════════════════════════════════════════════

local TerrainHandler = {}

-- Get terrain data
function TerrainHandler.GetTerrainData()
    local terrain = workspace.Terrain
    
    if not terrain then
        return nil, "Terrain not found"
    end
    
    -- Get terrain region
    local minPos = terrain:GetMaterialColor(Enum.Material.Grass) -- Dummy call to check terrain exists
    
    -- Get terrain size
    local size = terrain.MaxExtents.Max - terrain.MaxExtents.Min
    
    -- Read terrain in chunks
    local terrainData = {
        Materials = {},
        Occupancy = {},
        Region = {
            Min = terrain.MaxExtents.Min,
            Max = terrain.MaxExtents.Max
        }
    }
    
    return terrainData
end

-- Serialize terrain to XML format
function TerrainHandler.SerializeTerrain(progressCallback)
    local terrain = workspace.Terrain
    
    if not terrain then
        return ""
    end
    
    local output = {}
    table.insert(output, '<Item class="Terrain" referent="Terrain">')
    table.insert(output, '<Properties>')
    
    -- Serialize terrain properties
    local terrainProps = {
        "Decoration",
        "GrassLength",
        "MaterialColors",
        "WaterColor",
        "WaterReflectance", 
        "WaterTransparency",
        "WaterWaveSize",
        "WaterWaveSpeed"
    }
    
    for _, propName in ipairs(terrainProps) do
        local success, value = pcall(function()
            return terrain[propName]
        end)
        
        if success and value ~= nil then
            local serialized = PropertySerializer.SerializeValue(value, propName)
            if serialized then
                table.insert(output, serialized)
            end
        end
    end
    
    -- Serialize terrain data using ReadVoxels
    local terrainRegion = terrain:FindFirstChild("TerrainRegion")
    
    -- Get the actual terrain data
    local minExtents = terrain.MaxExtents.Min
    local maxExtents = terrain.MaxExtents.Max
    
    -- Check if terrain has any data
    local regionSize = maxExtents - minExtents
    if regionSize.Magnitude > 0 then
        -- Read terrain voxels in chunks
        local chunkSize = 64 -- Voxels per chunk
        local resolution = 4 -- Roblox terrain resolution
        
        local terrainDataStr = TerrainHandler.ReadTerrainVoxels(terrain, progressCallback)
        
        if terrainDataStr and #terrainDataStr > 0 then
            table.insert(output, string.format('<BinaryString name="PhysicsGrid">%s</BinaryString>', terrainDataStr))
        end
    end
    
    table.insert(output, '</Properties>')
    table.insert(output, '</Item>')
    
    return table.concat(output, "\n")
end

-- Read terrain voxels and convert to binary string
function TerrainHandler.ReadTerrainVoxels(terrain, progressCallback)
    local minExtents = terrain.MaxExtents.Min
    local maxExtents = terrain.MaxExtents.Max
    
    local regionSize = maxExtents - minExtents
    
    -- If terrain is empty or too small
    if regionSize.Magnitude < 4 then
        return ""
    end
    
    local resolution = 4
    local chunkSize = 32 * resolution -- 32 voxels at a time
    
    local allMaterials = {}
    local allOccupancy = {}
    
    local totalChunks = math.ceil(regionSize.X / chunkSize) * math.ceil(regionSize.Y / chunkSize) * math.ceil(regionSize.Z / chunkSize)
    local processedChunks = 0
    
    -- Read in chunks
    for x = minExtents.X, maxExtents.X, chunkSize do
        for y = minExtents.Y, maxExtents.Y, chunkSize do
            for z = minExtents.Z, maxExtents.Z, chunkSize do
                local regionMin = Vector3.new(x, y, z)
                local regionMax = Vector3.new(
                    math.min(x + chunkSize, maxExtents.X),
                    math.min(y + chunkSize, maxExtents.Y),
                    math.min(z + chunkSize, maxExtents.Z)
                )
                
                local region = Region3.new(regionMin, regionMax):ExpandToGrid(resolution)
                
                local success, materials, occupancy = pcall(function()
                    return terrain:ReadVoxels(region, resolution)
                end)
                
                if success then
                    -- Store the data
                    for xi = 1, #materials do
                        for yi = 1, #materials[xi] do
                            for zi = 1, #materials[xi][yi] do
                                local mat = materials[xi][yi][zi]
                                local occ = occupancy[xi][yi][zi]
                                
                                if mat ~= Enum.Material.Air and occ > 0 then
                                    table.insert(allMaterials, {
                                        x = x + (xi - 1) * resolution,
                                        y = y + (yi - 1) * resolution,
                                        z = z + (zi - 1) * resolution,
                                        material = mat,
                                        occupancy = occ
                                    })
                                end
                            end
                        end
                    end
                end
                
                processedChunks = processedChunks + 1
                
                if progressCallback then
                    progressCallback(processedChunks / totalChunks, "Reading terrain voxels...")
                end
                
                Utils.Yield()
            end
        end
    end
    
    -- Encode terrain data
    return TerrainHandler.EncodeTerrainData(allMaterials)
end

-- Encode terrain data to base64 string
function TerrainHandler.EncodeTerrainData(voxelData)
    if #voxelData == 0 then
        return ""
    end
    
    -- Create a simple encoding of the voxel data
    local bytes = {}
    
    -- Header: version, count
    table.insert(bytes, 1) -- Version
    
    -- Encode count as 4 bytes
    local count = #voxelData
    table.insert(bytes, bit32.band(count, 0xFF))
    table.insert(bytes, bit32.band(bit32.rshift(count, 8), 0xFF))
    table.insert(bytes, bit32.band(bit32.rshift(count, 16), 0xFF))
    table.insert(bytes, bit32.band(bit32.rshift(count, 24), 0xFF))
    
    -- Encode each voxel
    for _, voxel in ipairs(voxelData) do
        -- Position (3 floats = 12 bytes each compressed to 2 bytes for offset)
        local x = math.floor(voxel.x / 4)
        local y = math.floor(voxel.y / 4)
        local z = math.floor(voxel.z / 4)
        
        table.insert(bytes, bit32.band(x, 0xFF))
        table.insert(bytes, bit32.band(bit32.rshift(x, 8), 0xFF))
        table.insert(bytes, bit32.band(y, 0xFF))
        table.insert(bytes, bit32.band(bit32.rshift(y, 8), 0xFF))
        table.insert(bytes, bit32.band(z, 0xFF))
        table.insert(bytes, bit32.band(bit32.rshift(z, 8), 0xFF))
        
        -- Material (1 byte)
        table.insert(bytes, voxel.material.Value)
        
        -- Occupancy (1 byte, scaled 0-255)
        table.insert(bytes, math.floor(voxel.occupancy * 255))
    end
    
    -- Convert to base64
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local result = {}
    
    for i = 1, #bytes, 3 do
        local b1 = bytes[i] or 0
        local b2 = bytes[i + 1] or 0
        local b3 = bytes[i + 2] or 0
        
        local n = b1 * 65536 + b2 * 256 + b3
        
        table.insert(result, charset:sub(bit32.rshift(n, 18) % 64 + 1, bit32.rshift(n, 18) % 64 + 1))
        table.insert(result, charset:sub(bit32.rshift(n, 12) % 64 + 1, bit32.rshift(n, 12) % 64 + 1))
        
        if bytes[i + 1] then
            table.insert(result, charset:sub(bit32.rshift(n, 6) % 64 + 1, bit32.rshift(n, 6) % 64 + 1))
        else
            table.insert(result, "=")
        end
        
        if bytes[i + 2] then
            table.insert(result, charset:sub(n % 64 + 1, n % 64 + 1))
        else
            table.insert(result, "=")
        end
    end
    
    return table.concat(result)
end

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 8: INSTANCE SERIALIZER
-- ═══════════════════════════════════════════════════════════════════

local InstanceSerializer = {}

-- Instance reference map
InstanceSerializer.ReferenceMap = {}
InstanceSerializer.ReferenceCounter = 0

-- Generate unique referent ID
function InstanceSerializer.GenerateReferent()
    InstanceSerializer.ReferenceCounter = InstanceSerializer.ReferenceCounter + 1
    return "RBX" .. InstanceSerializer.ReferenceCounter
end

-- Reset reference map
function InstanceSerializer.Reset()
    InstanceSerializer.ReferenceMap = {}
    InstanceSerializer.ReferenceCounter = 0
end

-- Get or create referent for instance
function InstanceSerializer.GetReferent(instance)
    if InstanceSerializer.ReferenceMap[instance] then
        return InstanceSerializer.ReferenceMap[instance]
    end
    
    local referent = InstanceSerializer.GenerateReferent()
    InstanceSerializer.ReferenceMap[instance] = referent
    return referent
end

-- Check if class should be skipped
function InstanceSerializer.ShouldSkip(instance)
    local className = instance.ClassName
    
    -- Skip certain classes
    for _, skipClass in ipairs(PropertyDatabase.SkipClasses) do
        if className == skipClass then
            return true
        end
    end
    
    -- Skip if not archivable (unless configured otherwise)
    if not instance.Archivable and not Config.SaveHiddenInstances then
        return true
    end
    
    return false
end

-- Serialize a single instance
function InstanceSerializer.SerializeInstance(instance, depth, progressCallback, stats)
    depth = depth or 0
    stats = stats or {count = 0, scripts = 0}
    
    if InstanceSerializer.ShouldSkip(instance) then
        return ""
    end
    
    local output = {}
    local className = instance.ClassName
    local referent = InstanceSerializer.GetReferent(instance)
    
    -- Start Item tag
    table.insert(output, string.format('<Item class="%s" referent="%s">', 
        Utils.EscapeXML(className), referent))
    
    -- Properties
    table.insert(output, '<Properties>')
    
    -- Always save Name
    table.insert(output, string.format('<string name="Name">%s</string>', 
        Utils.EscapeXML(instance.Name)))
    
    -- Get and serialize properties
    local properties = PropertySerializer.GetProperties(instance)
    
    for propName, propValue in pairs(properties) do
        -- Handle reference properties separately
        local isRef = false
        for _, refProp in ipairs(PropertyDatabase.ReferenceProperties) do
            if propName == refProp then
                isRef = true
                break
            end
        end
        
        if isRef and typeof(propValue) == "Instance" then
            local targetRef = InstanceSerializer.GetReferent(propValue)
            table.insert(output, string.format('<Ref name="%s">%s</Ref>', propName, targetRef))
        else
            local serialized = PropertySerializer.SerializeValue(propValue, propName)
            if serialized then
                table.insert(output, serialized)
            end
        end
    end
    
    -- Handle scripts
    if className == "Script" or className == "LocalScript" or className == "ModuleScript" then
        if Config.SaveScripts then
            local source = ScriptHandler.Decompile(instance)
            table.insert(output, ScriptHandler.SerializeSource(source))
            stats.scripts = stats.scripts + 1
        end
    end
    
    -- Save attributes
    if Config.SaveAttributes then
        local success, attributes = pcall(function()
            return instance:GetAttributes()
        end)
        
        if success and attributes and next(attributes) then
            -- Serialize attributes
            for attrName, attrValue in pairs(attributes) do
                local serialized = PropertySerializer.SerializeValue(attrValue, "Attribute_" .. attrName)
                if serialized then
                    table.insert(output, serialized)
                end
            end
        end
    end
    
    -- Save tags
    if Config.SaveTags then
        local success, tags = pcall(function()
            return instance:GetTags()
        end)
        
        if success and tags and #tags > 0 then
            table.insert(output, string.format('<string name="Tags">%s</string>', 
                Utils.EscapeXML(table.concat(tags, ","))))
        end
    end
    
    table.insert(output, '</Properties>')
    
    stats.count = stats.count + 1
    
    -- Update progress
    if progressCallback and stats.count % 50 == 0 then
        progressCallback(nil, string.format("Serializing: %s (%d instances)", 
            instance.Name, stats.count))
    end
    
    Utils.Yield()
    
    -- Serialize children
    local children = instance:GetChildren()
    if #children > 0 then
        for _, child in ipairs(children) do
            local childXml = InstanceSerializer.SerializeInstance(child, depth + 1, progressCallback, stats)
            if childXml and #childXml > 0 then
                table.insert(output, childXml)
            end
        end
    end
    
    table.insert(output, '</Item>')
    
    return table.concat(output, "\n")
end

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 9: RBXL GENERATOR
-- ═══════════════════════════════════════════════════════════════════

local RBXLGenerator = {}

-- Generate RBXL XML header
function RBXLGenerator.GetHeader()
    return [[<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
    <Meta name="ExplicitAutoJoints">true</Meta>
    <External>null</External>
    <External>nil</External>
]]
end

-- Generate RBXL XML footer
function RBXLGenerator.GetFooter()
    return [[
</roblox>]]
end

-- Generate complete RBXL file
function RBXLGenerator.Generate(options, progressCallback)
    options = options or {}
    options.saveTerrain = options.saveTerrain ~= false
    options.saveModels = options.saveModels ~= false
    options.saveScripts = options.saveScripts ~= false
    
    -- Reset serializer
    InstanceSerializer.Reset()
    
    local output = {}
    local stats = {
        instances = 0,
        scripts = 0,
        startTime = os.clock(),
    }
    
    -- Add header
    table.insert(output, RBXLGenerator.GetHeader())
    
    -- Progress: 0%
    if progressCallback then
        progressCallback(0, "Starting save...")
    end
    
    -- Services to save
    local servicesToSave = {
        {service = workspace, name = "Workspace", weight = 0.5},
        {service = Services.Lighting, name = "Lighting", weight = 0.1},
        {service = Services.ReplicatedStorage, name = "ReplicatedStorage", weight = 0.15},
        {service = Services.ReplicatedFirst, name = "ReplicatedFirst", weight = 0.05},
        {service = Services.StarterGui, name = "StarterGui", weight = 0.05},
        {service = Services.StarterPack, name = "StarterPack", weight = 0.05},
        {service = Services.StarterPlayer, name = "StarterPlayer", weight = 0.05},
        {service = Services.Teams, name = "Teams", weight = 0.02},
        {service = Services.SoundService, name = "SoundService", weight = 0.03},
    }
    
    local currentProgress = 0
    
    for i, serviceInfo in ipairs(servicesToSave) do
        local service = serviceInfo.service
        local serviceName = serviceInfo.name
        
        if progressCallback then
            progressCallback(currentProgress, "Saving " .. serviceName .. "...")
        end
        
        -- Special handling for Workspace
        if serviceName == "Workspace" then
            -- Start Workspace item
            local workspaceRef = InstanceSerializer.GetReferent(workspace)
            table.insert(output, string.format('<Item class="Workspace" referent="%s">', workspaceRef))
            table.insert(output, '<Properties>')
            table.insert(output, '<string name="Name">Workspace</string>')
            
            -- Workspace properties
            local workspaceProps = {
                "AllowThirdPartySales", "CurrentCamera", "DistributedGameTime",
                "FallenPartsDestroyHeight", "GlobalWind", "Gravity",
                "StreamingEnabled", "StreamingMinRadius", "StreamingTargetRadius",
                "StreamOutBehavior"
            }
            
            for _, propName in ipairs(workspaceProps) do
                local success, value = pcall(function()
                    return workspace[propName]
                end)
                
                if success and value ~= nil then
                    local serialized = PropertySerializer.SerializeValue(value, propName)
                    if serialized then
                        table.insert(output, serialized)
                    end
                end
            end
            
            table.insert(output, '</Properties>')
            
            -- Save Terrain
            if options.saveTerrain then
                if progressCallback then
                    progressCallback(currentProgress, "Saving Terrain...")
                end
                
                local terrainXml = TerrainHandler.SerializeTerrain(function(p, msg)
                    if progressCallback then
                        progressCallback(currentProgress + p * 0.1, msg)
                    end
                end)
                
                if terrainXml and #terrainXml > 0 then
                    table.insert(output, terrainXml)
                end
            end
            
            -- Save Workspace children (models)
            if options.saveModels then
                for _, child in ipairs(workspace:GetChildren()) do
                    if child.ClassName ~= "Terrain" and child.ClassName ~= "Camera" then
                        local childStats = {count = 0, scripts = 0}
                        local childXml = InstanceSerializer.SerializeInstance(child, 0, function(p, msg)
                            if progressCallback then
                                progressCallback(currentProgress + 0.1 + (p or 0) * (serviceInfo.weight - 0.1), msg)
                            end
                        end, childStats)
                        
                        if childXml and #childXml > 0 then
                            table.insert(output, childXml)
                        end
                        
                        stats.instances = stats.instances + childStats.count
                        stats.scripts = stats.scripts + childStats.scripts
                    end
                end
            end
            
            table.insert(output, '</Item>')
        else
            -- Other services
            local serviceStats = {count = 0, scripts = 0}
            local serviceXml = InstanceSerializer.SerializeInstance(service, 0, function(p, msg)
                if progressCallback then
                    progressCallback(currentProgress + (p or 0) * serviceInfo.weight, msg)
                end
            end, serviceStats)
            
            if serviceXml and #serviceXml > 0 then
                table.insert(output, serviceXml)
            end
            
            stats.instances = stats.instances + serviceStats.count
            stats.scripts = stats.scripts + serviceStats.scripts
        end
        
        currentProgress = currentProgress + serviceInfo.weight
        
        Utils.ForceYield()
    end
    
    -- Add footer
    table.insert(output, RBXLGenerator.GetFooter())
    
    -- Final stats
    stats.endTime = os.clock()
    stats.duration = stats.endTime - stats.startTime
    
    if progressCallback then
        progressCallback(1, string.format("Complete! %d instances, %d scripts in %s", 
            stats.instances, stats.scripts, Utils.FormatTime(stats.duration)))
    end
    
    return table.concat(output, "\n"), stats
end

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 10: UI SYSTEM
-- ═══════════════════════════════════════════════════════════════════

local UISystem = {}

-- Theme colors
UISystem.Theme = {
    Dark = {
        Background = Color3.fromRGB(20, 20, 25),
        BackgroundSecondary = Color3.fromRGB(30, 30, 38),
        BackgroundTertiary = Color3.fromRGB(40, 40, 50),
        Accent = Color3.fromRGB(88, 101, 242),
        AccentHover = Color3.fromRGB(108, 121, 255),
        AccentActive = Color3.fromRGB(68, 81, 222),
        Success = Color3.fromRGB(87, 242, 135),
        Warning = Color3.fromRGB(254, 231, 92),
        Error = Color3.fromRGB(237, 66, 69),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(185, 185, 195),
        TextMuted = Color3.fromRGB(120, 120, 130),
        Border = Color3.fromRGB(50, 50, 60),
        Shadow = Color3.fromRGB(0, 0, 0),
        Glass = Color3.fromRGB(255, 255, 255),
        GlassOpacity = 0.05,
    }
}

-- Current theme
UISystem.CurrentTheme = UISystem.Theme.Dark

-- UI Elements
UISystem.ScreenGui = nil
UISystem.MainFrame = nil
UISystem.ProgressBar = nil
UISystem.LogBox = nil
UISystem.StatusLabel = nil

-- Animation helper
function UISystem.Tween(object, properties, duration, style, direction)
    duration = duration or Config.AnimationSpeed
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    
    local tweenInfo = TweenInfo.new(duration, style, direction)
    local tween = Services.TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Create corner radius
function UISystem.CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

-- Create stroke
function UISystem.CreateStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or UISystem.CurrentTheme.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.5
    stroke.Parent = parent
    return stroke
end

-- Create shadow
function UISystem.CreateShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.ZIndex = -1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = UISystem.CurrentTheme.Shadow
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Parent = parent
    return shadow
end

-- Create gradient
function UISystem.CreateGradient(parent, color1, color2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(color1 or UISystem.CurrentTheme.BackgroundSecondary, 
                                        color2 or UISystem.CurrentTheme.Background)
    gradient.Rotation = rotation or 90
    gradient.Parent = parent
    return gradient
end

-- Create glass effect
function UISystem.CreateGlass(parent)
    local glass = Instance.new("Frame")
    glass.Name = "GlassEffect"
    glass.BackgroundColor3 = UISystem.CurrentTheme.Glass
    glass.BackgroundTransparency = 1 - UISystem.CurrentTheme.GlassOpacity
    glass.BorderSizePixel = 0
    glass.Size = UDim2.new(1, 0, 1, 0)
    glass.ZIndex = parent.ZIndex + 1
    
    UISystem.CreateCorner(glass, 12)
    glass.Parent = parent
    
    return glass
end

-- Create the main UI
function UISystem.Create()
    -- Clean up existing UI
    UISystem.Destroy()
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstance"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    -- Try to parent to CoreGui, fallback to PlayerGui
    local success = pcall(function()
        screenGui.Parent = Services.CoreGui
    end)
    
    if not success then
        screenGui.Parent = Services.Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    UISystem.ScreenGui = screenGui
    
    -- Main Container
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.BackgroundColor3 = UISystem.CurrentTheme.Background
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Size = UDim2.new(0, 450, 0, 550)
    mainFrame.ClipsDescendants = true
    
    UISystem.CreateCorner(mainFrame, 16)
    UISystem.CreateStroke(mainFrame, UISystem.CurrentTheme.Border, 1.5, 0.3)
    UISystem.CreateShadow(mainFrame)
    
    -- Initial state (for animation)
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = screenGui
    
    UISystem.MainFrame = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundColor3 = UISystem.CurrentTheme.BackgroundSecondary
    header.BackgroundTransparency = 0.3
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 70)
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 16)
    headerCorner.Parent = header
    
    -- Fix bottom corners
    local headerFix = Instance.new("Frame")
    headerFix.Name = "HeaderFix"
    headerFix.BackgroundColor3 = UISystem.CurrentTheme.BackgroundSecondary
    headerFix.BackgroundTransparency = 0.3
    headerFix.BorderSizePixel = 0
    headerFix.Position = UDim2.new(0, 0, 1, -20)
    headerFix.Size = UDim2.new(1, 0, 0, 20)
    headerFix.Parent = header
    
    header.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 20, 0, 10)
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Font = Enum.Font.GothamBlack
    title.Text = "BaoSaveInstance"
    title.TextColor3 = UISystem.CurrentTheme.Text
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.new(0, 20, 0, 38)
    subtitle.Size = UDim2.new(1, -40, 0, 20)
    subtitle.Font = Enum.Font.Gotham
    subtitle.Text = "Advanced Edition v" .. VERSION .. " | " .. ExecutorInfo.Name
    subtitle.TextColor3 = UISystem.CurrentTheme.TextSecondary
    subtitle.TextSize = 12
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.BackgroundColor3 = UISystem.CurrentTheme.Error
    closeBtn.BackgroundTransparency = 0.8
    closeBtn.BorderSizePixel = 0
    closeBtn.Position = UDim2.new(1, -45, 0, 15)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "×"
    closeBtn.TextColor3 = UISystem.CurrentTheme.Error
    closeBtn.TextSize = 20
    closeBtn.AutoButtonColor = false
    
    UISystem.CreateCorner(closeBtn, 8)
    closeBtn.Parent = header
    
    closeBtn.MouseEnter:Connect(function()
        UISystem.Tween(closeBtn, {BackgroundTransparency = 0.5}, 0.2)
    end)
    
    closeBtn.MouseLeave:Connect(function()
        UISystem.Tween(closeBtn, {BackgroundTransparency = 0.8}, 0.2)
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        UISystem.Hide()
    end)
    
    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0, 20, 0, 85)
    content.Size = UDim2.new(1, -40, 1, -105)
    content.Parent = mainFrame
    
    -- Buttons container
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Name = "Buttons"
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.Size = UDim2.new(1, 0, 0, 180)
    buttonsFrame.Parent = content
    
    local buttonsLayout = Instance.new("UIListLayout")
    buttonsLayout.FillDirection = Enum.FillDirection.Vertical
    buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    buttonsLayout.Padding = UDim.new(0, 10)
    buttonsLayout.Parent = buttonsFrame
    
    -- Create action buttons
    local buttons = {
        {
            name = "SaveGame",
            text = "🟢 Save Game (Full)",
            description = "Terrain + Models + Scripts",
            color = UISystem.CurrentTheme.Success,
            callback = function()
                UISystem.ExecuteSave({saveTerrain = true, saveModels = true, saveScripts = true})
            end
        },
        {
            name = "SaveTerrain",
            text = "🟡 Save Terrain Only",
            description = "Only terrain voxels",
            color = UISystem.CurrentTheme.Warning,
            callback = function()
                UISystem.ExecuteSave({saveTerrain = true, saveModels = false, saveScripts = false})
            end
        },
        {
            name = "SaveModels",
            text = "🔵 Save All Models",
            description = "Models + Scripts (No terrain)",
            color = UISystem.CurrentTheme.Accent,
            callback = function()
                UISystem.ExecuteSave({saveTerrain = false, saveModels = true, saveScripts = true})
            end
        }
    }
    
    for _, btnInfo in ipairs(buttons) do
        local btnFrame = Instance.new("Frame")
        btnFrame.Name = btnInfo.name
        btnFrame.BackgroundColor3 = UISystem.CurrentTheme.BackgroundSecondary
        btnFrame.BorderSizePixel = 0
        btnFrame.Size = UDim2.new(1, 0, 0, 52)
        
        UISystem.CreateCorner(btnFrame, 10)
        UISystem.CreateStroke(btnFrame, btnInfo.color, 1.5, 0.6)
        
        local btn = Instance.new("TextButton")
        btn.Name = "Button"
        btn.BackgroundTransparency = 1
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.Font = Enum.Font.GothamBold
        btn.Text = ""
        btn.Parent = btnFrame
        
        local btnText = Instance.new("TextLabel")
        btnText.Name = "Text"
        btnText.BackgroundTransparency = 1
        btnText.Position = UDim2.new(0, 15, 0, 8)
        btnText.Size = UDim2.new(1, -30, 0, 20)
        btnText.Font = Enum.Font.GothamBold
        btnText.Text = btnInfo.text
        btnText.TextColor3 = UISystem.CurrentTheme.Text
        btnText.TextSize = 14
        btnText.TextXAlignment = Enum.TextXAlignment.Left
        btnText.Parent = btnFrame
        
        local btnDesc = Instance.new("TextLabel")
        btnDesc.Name = "Description"
        btnDesc.BackgroundTransparency = 1
        btnDesc.Position = UDim2.new(0, 15, 0, 28)
        btnDesc.Size = UDim2.new(1, -30, 0, 16)
        btnDesc.Font = Enum.Font.Gotham
        btnDesc.Text = btnInfo.description
        btnDesc.TextColor3 = UISystem.CurrentTheme.TextMuted
        btnDesc.TextSize = 11
        btnDesc.TextXAlignment = Enum.TextXAlignment.Left
        btnDesc.Parent = btnFrame
        
        btn.MouseEnter:Connect(function()
            UISystem.Tween(btnFrame, {BackgroundColor3 = UISystem.CurrentTheme.BackgroundTertiary}, 0.2)
        end)
        
        btn.MouseLeave:Connect(function()
            UISystem.Tween(btnFrame, {BackgroundColor3 = UISystem.CurrentTheme.BackgroundSecondary}, 0.2)
        end)
        
        btn.MouseButton1Click:Connect(btnInfo.callback)
        
        btnFrame.Parent = buttonsFrame
    end
    
    -- Progress section
    local progressSection = Instance.new("Frame")
    progressSection.Name = "ProgressSection"
    progressSection.BackgroundTransparency = 1
    progressSection.Position = UDim2.new(0, 0, 0, 200)
    progressSection.Size = UDim2.new(1, 0, 0, 60)
    progressSection.Parent = content
    
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "ProgressLabel"
    progressLabel.BackgroundTransparency = 1
    progressLabel.Size = UDim2.new(1, 0, 0, 20)
    progressLabel.Font = Enum.Font.GothamBold
    progressLabel.Text = "Ready"
    progressLabel.TextColor3 = UISystem.CurrentTheme.Text
    progressLabel.TextSize = 12
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = progressSection
    
    UISystem.StatusLabel = progressLabel
    
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBackground"
    progressBg.BackgroundColor3 = UISystem.CurrentTheme.BackgroundSecondary
    progressBg.BorderSizePixel = 0
    progressBg.Position = UDim2.new(0, 0, 0, 25)
    progressBg.Size = UDim2.new(1, 0, 0, 12)
    
    UISystem.CreateCorner(progressBg, 6)
    progressBg.Parent = progressSection
    
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.BackgroundColor3 = UISystem.CurrentTheme.Accent
    progressFill.BorderSizePixel = 0
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    
    UISystem.CreateCorner(progressFill, 6)
    
    local progressGradient = Instance.new("UIGradient")
    progressGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, UISystem.CurrentTheme.Accent),
        ColorSequenceKeypoint.new(1, UISystem.CurrentTheme.AccentHover)
    })
    progressGradient.Parent = progressFill
    
    progressFill.Parent = progressBg
    UISystem.ProgressBar = progressFill
    
    local progressPercent = Instance.new("TextLabel")
    progressPercent.Name = "ProgressPercent"
    progressPercent.BackgroundTransparency = 1
    progressPercent.Position = UDim2.new(1, -40, 0, 0)
    progressPercent.Size = UDim2.new(0, 40, 0, 20)
    progressPercent.Font = Enum.Font.GothamBold
    progressPercent.Text = "0%"
    progressPercent.TextColor3 = UISystem.CurrentTheme.TextSecondary
    progressPercent.TextSize = 11
    progressPercent.TextXAlignment = Enum.TextXAlignment.Right
    progressPercent.Parent = progressSection
    
    -- Log section
    local logSection = Instance.new("Frame")
    logSection.Name = "LogSection"
    logSection.BackgroundColor3 = UISystem.CurrentTheme.BackgroundSecondary
    logSection.BackgroundTransparency = 0.5
    logSection.BorderSizePixel = 0
    logSection.Position = UDim2.new(0, 0, 0, 275)
    logSection.Size = UDim2.new(1, 0, 1, -275)
    
    UISystem.CreateCorner(logSection, 10)
    logSection.Parent = content
    
    local logTitle = Instance.new("TextLabel")
    logTitle.Name = "LogTitle"
    logTitle.BackgroundTransparency = 1
    logTitle.Position = UDim2.new(0, 12, 0, 8)
    logTitle.Size = UDim2.new(1, -24, 0, 20)
    logTitle.Font = Enum.Font.GothamBold
    logTitle.Text = "📋 Activity Log"
    logTitle.TextColor3 = UISystem.CurrentTheme.Text
    logTitle.TextSize = 12
    logTitle.TextXAlignment = Enum.TextXAlignment.Left
    logTitle.Parent = logSection
    
    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Name = "LogScroll"
    logScroll.BackgroundTransparency = 1
    logScroll.BorderSizePixel = 0
    logScroll.Position = UDim2.new(0, 10, 0, 32)
    logScroll.Size = UDim2.new(1, -20, 1, -42)
    logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    logScroll.ScrollBarThickness = 4
    logScroll.ScrollBarImageColor3 = UISystem.CurrentTheme.Accent
    logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logScroll.Parent = logSection
    
    local logLayout = Instance.new("UIListLayout")
    logLayout.FillDirection = Enum.FillDirection.Vertical
    logLayout.Padding = UDim.new(0, 4)
    logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logLayout.Parent = logScroll
    
    UISystem.LogBox = logScroll
    
    -- Animate in
    UISystem.Tween(mainFrame, {
        Size = UDim2.new(0, 450, 0, 550),
        BackgroundTransparency = 0.05
    }, 0.4, Enum.EasingStyle.Back)
    
    -- Add initial log
    UISystem.Log("info", "BaoSaveInstance initialized")
    UISystem.Log("info", "Executor: " .. ExecutorInfo.Name)
    UISystem.Log("info", "Ready to save!")
    
    -- Make draggable
    UISystem.MakeDraggable(mainFrame, header)
    
    return screenGui
end

-- Make frame draggable
function UISystem.MakeDraggable(frame, handle)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Add log entry
function UISystem.Log(logType, message)
    if not UISystem.LogBox then return end
    
    local colors = {
        info = UISystem.CurrentTheme.TextSecondary,
        success = UISystem.CurrentTheme.Success,
        warning = UISystem.CurrentTheme.Warning,
        error = UISystem.CurrentTheme.Error,
    }
    
    local icons = {
        info = "ℹ️",
        success = "✅",
        warning = "⚠️",
        error = "❌",
    }
    
    local entry = Instance.new("TextLabel")
    entry.Name = "LogEntry"
    entry.BackgroundTransparency = 1
    entry.Size = UDim2.new(1, 0, 0, 16)
    entry.Font = Enum.Font.Gotham
    entry.Text = string.format("[%s] %s %s", os.date("%H:%M:%S"), icons[logType] or "•", message)
    entry.TextColor3 = colors[logType] or colors.info
    entry.TextSize = 11
    entry.TextXAlignment = Enum.TextXAlignment.Left
    entry.TextTruncate = Enum.TextTruncate.AtEnd
    entry.LayoutOrder = #UISystem.LogBox:GetChildren()
    entry.Parent = UISystem.LogBox
    
    -- Auto-scroll to bottom
    UISystem.LogBox.CanvasPosition = Vector2.new(0, UISystem.LogBox.AbsoluteCanvasSize.Y)
end

-- Update progress
function UISystem.UpdateProgress(progress, message)
    if UISystem.ProgressBar then
        UISystem.Tween(UISystem.ProgressBar, {Size = UDim2.new(progress, 0, 1, 0)}, 0.2)
    end
    
    if UISystem.StatusLabel and message then
        UISystem.StatusLabel.Text = message
    end
    
    -- Update percentage
    local percentLabel = UISystem.MainFrame and UISystem.MainFrame:FindFirstChild("Content") and 
                         UISystem.MainFrame.Content:FindFirstChild("ProgressSection") and
                         UISystem.MainFrame.Content.ProgressSection:FindFirstChild("ProgressPercent")
    
    if percentLabel then
        percentLabel.Text = string.format("%.0f%%", progress * 100)
    end
end

-- Execute save
function UISystem.ExecuteSave(options)
    UISystem.Log("info", "Starting save operation...")
    UISystem.UpdateProgress(0, "Initializing...")
    
    -- Disable buttons during save
    local buttonsFrame = UISystem.MainFrame and UISystem.MainFrame:FindFirstChild("Content") and
                         UISystem.MainFrame.Content:FindFirstChild("Buttons")
    
    if buttonsFrame then
        for _, btn in ipairs(buttonsFrame:GetChildren()) do
            if btn:IsA("Frame") then
                local button = btn:FindFirstChild("Button")
                if button then
                    button.Active = false
                end
            end
        end
    end
    
    -- Run save in coroutine
    coroutine.wrap(function()
        local success, result, stats = pcall(function()
            return RBXLGenerator.Generate(options, function(progress, message)
                UISystem.UpdateProgress(progress, message)
                if message then
                    UISystem.Log("info", message)
                end
            end)
        end)
        
        if success and result then
            -- Get filename
            local gameName = Utils.GetGameName()
            local filename = gameName .. "_" .. os.date("%Y%m%d_%H%M%S") .. ".rbxl"
            
            UISystem.Log("info", "Writing file: " .. filename)
            
            -- Save file
            local writeSuccess, writeError = pcall(function()
                ExecutorFunctions.writefile(filename, result)
            end)
            
            if writeSuccess then
                UISystem.UpdateProgress(1, "Save complete!")
                UISystem.Log("success", "File saved: " .. filename)
                UISystem.Log("success", string.format("Stats: %d instances, %d scripts", 
                    stats.instances, stats.scripts))
                UISystem.Log("success", string.format("Time: %s", Utils.FormatTime(stats.duration)))
                
                -- Show success popup
                UISystem.ShowPopup("success", "Save Successful!", 
                    "File: " .. filename .. "\nInstances: " .. stats.instances)
            else
                UISystem.UpdateProgress(0, "Save failed!")
                UISystem.Log("error", "Failed to write file: " .. tostring(writeError))
                UISystem.ShowPopup("error", "Save Failed", tostring(writeError))
            end
        else
            UISystem.UpdateProgress(0, "Save failed!")
            UISystem.Log("error", "Save error: " .. tostring(result))
            UISystem.ShowPopup("error", "Save Failed", tostring(result))
        end
        
        -- Re-enable buttons
        if buttonsFrame then
            for _, btn in ipairs(buttonsFrame:GetChildren()) do
                if btn:IsA("Frame") then
                    local button = btn:FindFirstChild("Button")
                    if button then
                        button.Active = true
                    end
                end
            end
        end
    end)()
end

-- Show popup notification
function UISystem.ShowPopup(popupType, title, message)
    if not UISystem.ScreenGui then return end
    
    local colors = {
        success = UISystem.CurrentTheme.Success,
        error = UISystem.CurrentTheme.Error,
        warning = UISystem.CurrentTheme.Warning,
        info = UISystem.CurrentTheme.Accent,
    }
    
    local popup = Instance.new("Frame")
    popup.Name = "Popup"
    popup.BackgroundColor3 = UISystem.CurrentTheme.BackgroundSecondary
    popup.BorderSizePixel = 0
    popup.Position = UDim2.new(0.5, 0, 0, -100)
    popup.AnchorPoint = Vector2.new(0.5, 0)
    popup.Size = UDim2.new(0, 300, 0, 80)
    
    UISystem.CreateCorner(popup, 12)
    UISystem.CreateStroke(popup, colors[popupType], 2, 0.3)
    UISystem.CreateShadow(popup)
    
    popup.Parent = UISystem.ScreenGui
    
    local popupTitle = Instance.new("TextLabel")
    popupTitle.BackgroundTransparency = 1
    popupTitle.Position = UDim2.new(0, 15, 0, 12)
    popupTitle.Size = UDim2.new(1, -30, 0, 22)
    popupTitle.Font = Enum.Font.GothamBold
    popupTitle.Text = title
    popupTitle.TextColor3 = colors[popupType]
    popupTitle.TextSize = 14
    popupTitle.TextXAlignment = Enum.TextXAlignment.Left
    popupTitle.Parent = popup
    
    local popupMessage = Instance.new("TextLabel")
    popupMessage.BackgroundTransparency = 1
    popupMessage.Position = UDim2.new(0, 15, 0, 36)
    popupMessage.Size = UDim2.new(1, -30, 0, 36)
    popupMessage.Font = Enum.Font.Gotham
    popupMessage.Text = message
    popupMessage.TextColor3 = UISystem.CurrentTheme.TextSecondary
    popupMessage.TextSize = 11
    popupMessage.TextXAlignment = Enum.TextXAlignment.Left
    popupMessage.TextYAlignment = Enum.TextYAlignment.Top
    popupMessage.TextWrapped = true
    popupMessage.Parent = popup
    
    -- Animate in
    UISystem.Tween(popup, {Position = UDim2.new(0.5, 0, 0, 20)}, 0.4, Enum.EasingStyle.Back)
    
    -- Auto-dismiss
    task.delay(4, function()
        if popup and popup.Parent then
            UISystem.Tween(popup, {Position = UDim2.new(0.5, 0, 0, -100)}, 0.3)
            task.delay(0.3, function()
                if popup then
                    popup:Destroy()
                end
            end)
        end
    end)
end

-- Hide UI with animation
function UISystem.Hide()
    if UISystem.MainFrame then
        UISystem.Tween(UISystem.MainFrame, {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }, 0.3)
        
        task.delay(0.3, function()
            UISystem.Destroy()
        end)
    end
end

-- Show UI
function UISystem.Show()
    if not UISystem.ScreenGui then
        UISystem.Create()
    end
end

-- Destroy UI
function UISystem.Destroy()
    if UISystem.ScreenGui then
        UISystem.ScreenGui:Destroy()
        UISystem.ScreenGui = nil
        UISystem.MainFrame = nil
        UISystem.ProgressBar = nil
        UISystem.LogBox = nil
        UISystem.StatusLabel = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 11: MAIN INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════

local function Initialize()
    print([[
    ╔══════════════════════════════════════════════════════════════════╗
    ║              BaoSaveInstance - Advanced Edition                   ║
    ║                    Version ]] .. VERSION .. [[                              ║
    ╚══════════════════════════════════════════════════════════════════╝
    ]])
    
    -- Detect executor
    DetectExecutor()
    print("[BaoSaveInstance] Detected executor: " .. ExecutorInfo.Name)
    
    -- Initialize executor functions
    InitExecutorFunctions()
    print("[BaoSaveInstance] Executor functions initialized")
    
    -- Check required functions
    local requiredFunctions = {"writefile", "decompile"}
    local missingFunctions = {}
    
    for _, funcName in ipairs(requiredFunctions) do
        if not ExecutorFunctions[funcName] or ExecutorFunctions[funcName] == nil then
            table.insert(missingFunctions, funcName)
        end
    end
    
    if #missingFunctions > 0 then
        warn("[BaoSaveInstance] Warning: Some functions may not be available: " .. table.concat(missingFunctions, ", "))
    end
    
    -- Create UI
    if Config.EnableUI then
        UISystem.Create()
        print("[BaoSaveInstance] UI created successfully")
    end
    
    print("[BaoSaveInstance] Initialization complete!")
    
    return BaoSaveInstance
end

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 12: PUBLIC API
-- ═══════════════════════════════════════════════════════════════════

-- Save game programmatically
function BaoSaveInstance.SaveGame(options)
    options = options or {}
    options.saveTerrain = options.saveTerrain ~= false
    options.saveModels = options.saveModels ~= false
    options.saveScripts = options.saveScripts ~= false
    
    local result, stats = RBXLGenerator.Generate(options, function(progress, message)
        print(string.format("[BaoSaveInstance] %.0f%% - %s", progress * 100, message or ""))
    end)
    
    if result then
        local gameName = Utils.GetGameName()
        local filename = gameName .. "_" .. os.date("%Y%m%d_%H%M%S") .. ".rbxl"
        
        local success, err = pcall(function()
            ExecutorFunctions.writefile(filename, result)
        end)
        
        if success then
            print("[BaoSaveInstance] Saved: " .. filename)
            return true, filename, stats
        else
            warn("[BaoSaveInstance] Failed to write file: " .. tostring(err))
            return false, err
        end
    end
    
    return false, "Generation failed"
end

-- Save terrain only
function BaoSaveInstance.SaveTerrain()
    return BaoSaveInstance.SaveGame({saveTerrain = true, saveModels = false, saveScripts = false})
end

-- Save models only
function BaoSaveInstance.SaveModels()
    return BaoSaveInstance.SaveGame({saveTerrain = false, saveModels = true, saveScripts = true})
end

-- Show/hide UI
function BaoSaveInstance.ShowUI()
    UISystem.Show()
end

function BaoSaveInstance.HideUI()
    UISystem.Hide()
end

-- Toggle UI
function BaoSaveInstance.ToggleUI()
    if UISystem.ScreenGui then
        UISystem.Hide()
    else
        UISystem.Show()
    end
end

-- Get configuration
function BaoSaveInstance.GetConfig()
    return Utils.DeepClone(Config)
end

-- Set configuration
function BaoSaveInstance.SetConfig(newConfig)
    for key, value in pairs(newConfig) do
        if Config[key] ~= nil then
            Config[key] = value
        end
    end
end

-- Get executor info
function BaoSaveInstance.GetExecutorInfo()
    return Utils.DeepClone(ExecutorInfo)
end

-- Export to global
if getgenv then
    getgenv().BaoSaveInstance = BaoSaveInstance
else
    _G.BaoSaveInstance = BaoSaveInstance
end

-- Initialize
Initialize()

return BaoSaveInstance
