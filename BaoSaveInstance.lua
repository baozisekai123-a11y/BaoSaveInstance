--[[
╔══════════════════════════════════════════════════════════════════╗
║                      BaoSaveInstance v1.0                        ║
║          Universal Save Instance Tool for Roblox                 ║
║                                                                  ║
║  Hỗ trợ: Xeno, Solara, TNG, Velocity, Wave, và tương thích      ║
║                                                                  ║
║  ⚠️ Chỉ sử dụng cho mục đích học tập và nghiên cứu              ║
╚══════════════════════════════════════════════════════════════════╝
]]

local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance
BaoSaveInstance.Version = "1.0.0"
BaoSaveInstance.Name = "BaoSaveInstance"

--=============================================================================
-- SERVICES
--=============================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local Teams = game:GetService("Teams")
local SoundService = game:GetService("SoundService")
local Chat = game:GetService("Chat")
local LocalizationService = game:GetService("LocalizationService")
local TestService = game:GetService("TestService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--=============================================================================
-- EXECUTOR COMPATIBILITY LAYER
--=============================================================================
local ExecutorSupport = {}

-- Detect executor và available functions
ExecutorSupport.Name = "Unknown"
ExecutorSupport.Functions = {}

local function detectExecutor()
    -- Check for common executor identifiers
    if KRNL_LOADED then
        ExecutorSupport.Name = "KRNL"
    elseif syn and syn.protect_gui then
        ExecutorSupport.Name = "Synapse X"
    elseif getexecutorname then
        ExecutorSupport.Name = getexecutorname()
    elseif identifyexecutor then
        ExecutorSupport.Name = identifyexecutor()
    elseif XENO_LOADED or (getgenv and getgenv().XENO_LOADED) then
        ExecutorSupport.Name = "Xeno"
    elseif SOLARA_LOADED or (getgenv and getgenv().SOLARA_LOADED) then
        ExecutorSupport.Name = "Solara"
    elseif wave then
        ExecutorSupport.Name = "Wave"
    elseif TNG_LOADED then
        ExecutorSupport.Name = "TNG"
    elseif VELOCITY_LOADED then
        ExecutorSupport.Name = "Velocity"
    end
    
    -- Detect available functions
    ExecutorSupport.Functions = {
        writefile = writefile ~= nil,
        readfile = readfile ~= nil,
        isfile = isfile ~= nil,
        makefolder = makefolder ~= nil,
        isfolder = isfolder ~= nil,
        getgenv = getgenv ~= nil,
        getrenv = getrenv ~= nil,
        getinstances = getinstances ~= nil,
        getnilinstances = getnilinstances ~= nil,
        gethiddenproperty = gethiddenproperty ~= nil,
        sethiddenproperty = sethiddenproperty ~= nil,
        getproperties = getproperties ~= nil,
        isscriptable = isscriptable ~= nil,
        setscriptable = setscriptable ~= nil,
        saveinstance = saveinstance ~= nil,
        getscriptbytecode = getscriptbytecode ~= nil,
        getscripthash = getscripthash ~= nil,
        decompile = decompile ~= nil,
        getscripts = getscripts ~= nil,
        getsenv = getsenv ~= nil,
        getconstants = getconstants ~= nil,
        getupvalues = getupvalues ~= nil,
        getprotos = getprotos ~= nil,
        setclipboard = setclipboard ~= nil,
        request = (request or http_request or syn and syn.request) ~= nil,
        hookfunction = (hookfunction or replaceclosure) ~= nil,
        newcclosure = newcclosure ~= nil,
        cloneref = cloneref ~= nil,
        compareinstances = compareinstances ~= nil,
        firetouchinterest = firetouchinterest ~= nil,
        fireproximityprompt = fireproximityprompt ~= nil,
    }
    
    return ExecutorSupport.Name
end

detectExecutor()

--=============================================================================
-- LOGGING SYSTEM
--=============================================================================
local Logger = {}
Logger.Logs = {}
Logger.Enabled = true

function Logger:Log(message, logType)
    logType = logType or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local logEntry = string.format("[%s] [%s] [%s] %s", timestamp, BaoSaveInstance.Name, logType, message)
    
    table.insert(self.Logs, logEntry)
    
    if self.Enabled then
        if logType == "ERROR" then
            warn(logEntry)
        else
            print(logEntry)
        end
    end
end

function Logger:Info(message)
    self:Log(message, "INFO")
end

function Logger:Success(message)
    self:Log(message, "SUCCESS")
end

function Logger:Warning(message)
    self:Log(message, "WARNING")
end

function Logger:Error(message)
    self:Log(message, "ERROR")
end

function Logger:Progress(message)
    self:Log(message, "PROGRESS")
end

--=============================================================================
-- UTILITY FUNCTIONS
--=============================================================================
local Utils = {}

function Utils.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    return success, result
end

function Utils.GetFullName(instance)
    local success, fullName = pcall(function()
        return instance:GetFullName()
    end)
    return success and fullName or "Unknown"
end

function Utils.IsValidInstance(instance)
    local success, _ = pcall(function()
        return instance.Parent
    end)
    return success
end

function Utils.CountDescendants(instance)
    local count = 0
    local success, _ = pcall(function()
        for _, child in pairs(instance:GetDescendants()) do
            count = count + 1
        end
    end)
    return count
end

function Utils.EscapeXml(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    
    str = str:gsub("&", "&amp;")
    str = str:gsub("<", "&lt;")
    str = str:gsub(">", "&gt;")
    str = str:gsub("\"", "&quot;")
    str = str:gsub("'", "&apos;")
    
    -- Remove invalid XML characters
    str = str:gsub("[\0-\8\11\12\14-\31]", "")
    
    return str
end

function Utils.Vector3ToString(v3)
    return string.format("%f, %f, %f", v3.X, v3.Y, v3.Z)
end

function Utils.CFrameToString(cf)
    local components = {cf:GetComponents()}
    local result = {}
    for _, v in ipairs(components) do
        table.insert(result, tostring(v))
    end
    return table.concat(result, ", ")
end

function Utils.Color3ToString(color)
    return string.format("%f, %f, %f", color.R, color.G, color.B)
end

function Utils.UDim2ToString(udim)
    return string.format("{%f, %d}, {%f, %d}", 
        udim.X.Scale, udim.X.Offset, 
        udim.Y.Scale, udim.Y.Offset)
end

function Utils.GenerateReferent()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local result = "RBX"
    for i = 1, 32 do
        local idx = math.random(1, #chars)
        result = result .. chars:sub(idx, idx)
    end
    return result
end

--=============================================================================
-- PROPERTY DEFINITIONS
--=============================================================================
local PropertyDatabase = {}

-- Base properties cho tất cả instances
PropertyDatabase.BaseProperties = {
    "Name", "Parent", "Archivable"
}

-- Properties theo class
PropertyDatabase.ClassProperties = {
    BasePart = {
        "Anchored", "BrickColor", "CanCollide", "CanTouch", "CanQuery",
        "CastShadow", "CFrame", "CollisionGroup", "Color", "CustomPhysicalProperties",
        "Locked", "Massless", "Material", "MaterialVariant", "PivotOffset",
        "Position", "Reflectance", "RootPriority", "Rotation", "Size",
        "Transparency", "Orientation"
    },
    
    Part = {
        "Shape"
    },
    
    MeshPart = {
        "MeshId", "TextureID", "CollisionFidelity", "RenderFidelity",
        "DoubleSided", "HasJointOffset", "HasSkinnedMesh", "JointOffset"
    },
    
    UnionOperation = {
        "AssetId", "CollisionFidelity", "RenderFidelity",
        "SmoothingAngle", "UsePartColor"
    },
    
    Model = {
        "LevelOfDetail", "PrimaryPart", "WorldPivot", "ModelStreamingMode"
    },
    
    Attachment = {
        "CFrame", "Visible", "Axis", "Orientation", "Position", "SecondaryAxis",
        "WorldAxis", "WorldCFrame", "WorldOrientation", "WorldPosition", "WorldSecondaryAxis"
    },
    
    Weld = {
        "C0", "C1", "Part0", "Part1", "Enabled"
    },
    
    WeldConstraint = {
        "Part0", "Part1", "Enabled"
    },
    
    Motor6D = {
        "C0", "C1", "Part0", "Part1", "CurrentAngle", "DesiredAngle",
        "MaxVelocity", "Enabled"
    },
    
    Decal = {
        "Color3", "Texture", "Transparency", "ZIndex", "Face"
    },
    
    Texture = {
        "Color3", "Texture", "Transparency", "ZIndex", "Face",
        "OffsetStudsU", "OffsetStudsV", "StudsPerTileU", "StudsPerTileV"
    },
    
    SurfaceAppearance = {
        "AlphaMode", "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap",
        "TexturePack"
    },
    
    SpecialMesh = {
        "MeshId", "MeshType", "Offset", "Scale", "TextureId", "VertexColor"
    },
    
    BlockMesh = {
        "Offset", "Scale", "VertexColor"
    },
    
    CylinderMesh = {
        "Offset", "Scale", "VertexColor"
    },
    
    SpawnLocation = {
        "AllowTeamChangeOnTouch", "Duration", "Enabled", "Neutral", "TeamColor"
    },
    
    Seat = {
        "Disabled", "Occupant"
    },
    
    VehicleSeat = {
        "Disabled", "HeadsUpDisplay", "MaxSpeed", "Steer", "SteerFloat",
        "Throttle", "ThrottleFloat", "Torque", "TurnSpeed"
    },
    
    PointLight = {
        "Brightness", "Color", "Enabled", "Range", "Shadows"
    },
    
    SpotLight = {
        "Brightness", "Color", "Enabled", "Range", "Shadows",
        "Angle", "Face"
    },
    
    SurfaceLight = {
        "Brightness", "Color", "Enabled", "Range", "Shadows",
        "Angle", "Face"
    },
    
    ParticleEmitter = {
        "Acceleration", "Brightness", "Color", "Drag", "EmissionDirection",
        "Enabled", "FlipbookFramerate", "FlipbookIncompatible", "FlipbookLayout",
        "FlipbookMode", "FlipbookStartRandom", "Lifetime", "LightEmission",
        "LightInfluence", "LockedToPart", "Orientation", "Rate", "RotSpeed",
        "Rotation", "Shape", "ShapeInOut", "ShapePartial", "ShapeStyle",
        "Size", "Speed", "SpreadAngle", "Squash", "Texture", "TimeScale",
        "Transparency", "VelocityInheritance", "WindAffectsDrag", "ZOffset"
    },
    
    Fire = {
        "Color", "Enabled", "Heat", "SecondaryColor", "Size", "TimeScale"
    },
    
    Smoke = {
        "Color", "Enabled", "Opacity", "RiseVelocity", "Size", "TimeScale"
    },
    
    Sparkles = {
        "Enabled", "SparkleColor", "TimeScale"
    },
    
    Sound = {
        "EmitterSize", "LoopRegion", "Looped", "MaxDistance",
        "PlayOnRemove", "PlaybackRegion", "PlaybackRegionsEnabled",
        "PlaybackSpeed", "Playing", "RollOffMaxDistance", "RollOffMinDistance",
        "RollOffMode", "SoundGroup", "SoundId", "TimePosition", "Volume"
    },
    
    Script = {
        "Disabled", "Source", "RunContext"
    },
    
    LocalScript = {
        "Disabled", "Source"
    },
    
    ModuleScript = {
        "Source"
    },
    
    Folder = {},
    
    Configuration = {},
    
    BoolValue = {
        "Value"
    },
    
    NumberValue = {
        "Value"
    },
    
    StringValue = {
        "Value"
    },
    
    IntValue = {
        "Value"
    },
    
    ObjectValue = {
        "Value"
    },
    
    Color3Value = {
        "Value"
    },
    
    Vector3Value = {
        "Value"
    },
    
    CFrameValue = {
        "Value"
    },
    
    BrickColorValue = {
        "Value"
    },
    
    RayValue = {
        "Value"
    },
    
    BindableEvent = {},
    
    BindableFunction = {},
    
    RemoteEvent = {},
    
    RemoteFunction = {},
    
    ClickDetector = {
        "CursorIcon", "MaxActivationDistance"
    },
    
    ProximityPrompt = {
        "ActionText", "AutoLocalize", "ClickablePrompt", "Enabled",
        "ExclusivityMode", "GamepadKeyCode", "HoldDuration", "KeyboardKeyCode",
        "MaxActivationDistance", "ObjectText", "RequiresLineOfSight",
        "RootLocalizationTable", "Style", "UIOffset"
    },
    
    Humanoid = {
        "AutoJumpEnabled", "AutoRotate", "AutomaticScalingEnabled",
        "BreakJointsOnDeath", "CameraOffset", "DisplayDistanceType",
        "DisplayName", "EvaluateStateMachine", "Health", "HealthDisplayDistance",
        "HealthDisplayType", "HipHeight", "JumpHeight", "JumpPower",
        "MaxHealth", "MaxSlopeAngle", "MoveDirection", "NameDisplayDistance",
        "NameOcclusion", "PlatformStand", "RequiresNeck", "RigType",
        "RootPart", "SeatPart", "Sit", "TargetPoint", "UseJumpPower",
        "WalkSpeed", "WalkToPart", "WalkToPoint"
    },
    
    Animator = {},
    
    Animation = {
        "AnimationId"
    },
    
    AnimationTrack = {},
    
    Tool = {
        "CanBeDropped", "Enabled", "Grip", "GripForward", "GripPos",
        "GripRight", "GripUp", "ManualActivationOnly", "RequiresHandle",
        "ToolTip"
    },
    
    Camera = {
        "CFrame", "CameraSubject", "CameraType", "DiagonalFieldOfView",
        "FieldOfView", "FieldOfViewMode", "Focus", "HeadLocked", "HeadScale",
        "MaxAxisFieldOfView", "NearPlaneZ", "ViewportSize"
    },
    
    Beam = {
        "Attachment0", "Attachment1", "Brightness", "Color", "CurveSize0",
        "CurveSize1", "Enabled", "FaceCamera", "LightEmission", "LightInfluence",
        "Segments", "Texture", "TextureLength", "TextureMode", "TextureSpeed",
        "Transparency", "Width0", "Width1", "ZOffset"
    },
    
    Trail = {
        "Attachment0", "Attachment1", "Brightness", "Color", "Enabled",
        "FaceCamera", "Lifetime", "LightEmission", "LightInfluence",
        "MaxLength", "MinLength", "Texture", "TextureLength", "TextureMode",
        "Transparency", "WidthScale"
    },
    
    BillboardGui = {
        "Active", "Adornee", "AlwaysOnTop", "Brightness", "ClipsDescendants",
        "CurrentDistance", "DistanceLowerLimit", "DistanceStep", "DistanceUpperLimit",
        "ExtentsOffset", "ExtentsOffsetWorldSpace", "LightInfluence", "MaxDistance",
        "PlayerToHideFrom", "Size", "SizeOffset", "StudsOffset", "StudsOffsetWorldSpace",
        "ZIndexBehavior"
    },
    
    SurfaceGui = {
        "Active", "Adornee", "AlwaysOnTop", "Brightness", "CanvasSize",
        "ClipsDescendants", "Face", "LightInfluence", "MaxDistance",
        "PixelsPerStud", "SizingMode", "ToolPunchThroughDistance",
        "ZIndexBehavior", "ZOffset"
    },
    
    ScreenGui = {
        "DisplayOrder", "Enabled", "IgnoreGuiInset", "ResetOnSpawn",
        "ZIndexBehavior", "ClipToDeviceSafeArea", "SafeAreaCompatibility",
        "ScreenInsets"
    },
    
    Frame = {
        "Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3",
        "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel",
        "ClipsDescendants", "Interactable", "LayoutOrder", "Position", "Rotation",
        "Selectable", "SelectionGroup", "SelectionImageObject", "Size", "SizeConstraint",
        "Style", "Visible", "ZIndex"
    },
    
    TextLabel = {
        "Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3",
        "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel",
        "ClipsDescendants", "Font", "FontFace", "Interactable", "LayoutOrder",
        "LineHeight", "MaxVisibleGraphemes", "Position", "RichText", "Rotation",
        "Selectable", "Size", "SizeConstraint", "Text", "TextBounds", "TextColor3",
        "TextFits", "TextScaled", "TextSize", "TextStrokeColor3", "TextStrokeTransparency",
        "TextTransparency", "TextTruncate", "TextWrapped", "TextXAlignment",
        "TextYAlignment", "Visible", "ZIndex"
    },
    
    TextButton = {
        "Active", "AnchorPoint", "AutoButtonColor", "AutomaticSize", "BackgroundColor3",
        "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel",
        "ClipsDescendants", "Font", "FontFace", "Interactable", "LayoutOrder",
        "LineHeight", "MaxVisibleGraphemes", "Modal", "Position", "RichText",
        "Rotation", "Selectable", "Selected", "Size", "SizeConstraint", "Style",
        "Text", "TextBounds", "TextColor3", "TextFits", "TextScaled", "TextSize",
        "TextStrokeColor3", "TextStrokeTransparency", "TextTransparency",
        "TextTruncate", "TextWrapped", "TextXAlignment", "TextYAlignment",
        "Visible", "ZIndex"
    },
    
    ImageLabel = {
        "Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3",
        "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel",
        "ClipsDescendants", "Image", "ImageColor3", "ImageRectOffset",
        "ImageRectSize", "ImageTransparency", "Interactable", "LayoutOrder",
        "Position", "ResampleMode", "Rotation", "ScaleType", "Selectable",
        "Size", "SizeConstraint", "SliceCenter", "SliceScale", "TileSize",
        "Visible", "ZIndex"
    },
    
    ImageButton = {
        "Active", "AnchorPoint", "AutoButtonColor", "AutomaticSize", "BackgroundColor3",
        "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel",
        "ClipsDescendants", "HoverImage", "Image", "ImageColor3", "ImageRectOffset",
        "ImageRectSize", "ImageTransparency", "Interactable", "LayoutOrder",
        "Modal", "Position", "PressedImage", "ResampleMode", "Rotation",
        "ScaleType", "Selectable", "Selected", "Size", "SizeConstraint",
        "SliceCenter", "SliceScale", "TileSize", "Visible", "ZIndex"
    },
    
    ScrollingFrame = {
        "Active", "AnchorPoint", "AutomaticCanvasSize", "AutomaticSize",
        "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode",
        "BorderSizePixel", "BottomImage", "CanvasPosition", "CanvasSize",
        "ClipsDescendants", "ElasticBehavior", "HorizontalScrollBarInset",
        "Interactable", "LayoutOrder", "MidImage", "Position", "Rotation",
        "ScrollBarImageColor3", "ScrollBarImageTransparency", "ScrollBarThickness",
        "Selectable", "Size", "SizeConstraint", "TopImage", "VerticalScrollBarInset",
        "VerticalScrollBarPosition", "Visible", "ZIndex"
    },
    
    UICorner = {
        "CornerRadius"
    },
    
    UIGradient = {
        "Color", "Enabled", "Offset", "Rotation", "Transparency"
    },
    
    UIStroke = {
        "ApplyStrokeMode", "Color", "Enabled", "LineJoinMode", "Thickness", "Transparency"
    },
    
    UIPadding = {
        "PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"
    },
    
    UIListLayout = {
        "FillDirection", "HorizontalAlignment", "Padding", "SortOrder",
        "VerticalAlignment", "Wraps"
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
        "HorizontalAlignment", "MajorAxis", "Padding", "SortOrder", "VerticalAlignment"
    },
    
    UIScale = {
        "Scale"
    },
    
    UIAspectRatioConstraint = {
        "AspectRatio", "AspectType", "DominantAxis"
    },
    
    UISizeConstraint = {
        "MaxSize", "MinSize"
    },
    
    UITextSizeConstraint = {
        "MaxTextSize", "MinTextSize"
    },
    
    Atmosphere = {
        "Color", "Decay", "Density", "Glare", "Haze", "Offset"
    },
    
    Sky = {
        "CelestialBodiesShown", "MoonAngularSize", "MoonTextureId",
        "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt",
        "SkyboxUp", "StarCount", "SunAngularSize", "SunTextureId"
    },
    
    BloomEffect = {
        "Enabled", "Intensity", "Size", "Threshold"
    },
    
    BlurEffect = {
        "Enabled", "Size"
    },
    
    ColorCorrectionEffect = {
        "Brightness", "Contrast", "Enabled", "Saturation", "TintColor"
    },
    
    DepthOfFieldEffect = {
        "Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"
    },
    
    SunRaysEffect = {
        "Enabled", "Intensity", "Spread"
    },
    
    Lighting = {
        "Ambient", "Brightness", "ColorShift_Bottom", "ColorShift_Top",
        "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ExposureCompensation",
        "FogColor", "FogEnd", "FogStart", "GeographicLatitude", "GlobalShadows",
        "OutdoorAmbient", "ShadowSoftness", "ClockTime", "TimeOfDay", "Technology"
    },
    
    Terrain = {
        "Decoration", "GrassLength", "MaterialColors", "WaterColor",
        "WaterReflectance", "WaterTransparency", "WaterWaveSize", "WaterWaveSpeed"
    },
    
    -- Constraint classes
    RopeConstraint = {
        "Attachment0", "Attachment1", "Color", "Enabled", "Length",
        "Restitution", "Thickness", "Visible", "WinchEnabled", "WinchForce",
        "WinchResponsiveness", "WinchSpeed", "WinchTarget"
    },
    
    RodConstraint = {
        "Attachment0", "Attachment1", "Color", "Enabled", "Length",
        "LimitAngle0", "LimitAngle1", "LimitsEnabled", "Thickness", "Visible"
    },
    
    SpringConstraint = {
        "Attachment0", "Attachment1", "Color", "Coils", "Damping",
        "Enabled", "FreeLength", "LimitsEnabled", "MaxForce", "MaxLength",
        "MinLength", "Radius", "Stiffness", "Thickness", "Visible"
    },
    
    HingeConstraint = {
        "Attachment0", "Attachment1", "ActuatorType", "AngularResponsiveness",
        "AngularSpeed", "AngularVelocity", "Enabled", "LimitsEnabled",
        "LowerAngle", "MotorMaxAcceleration", "MotorMaxTorque", "Radius",
        "Restitution", "ServoMaxTorque", "SoftlockServoUponReachingTarget",
        "TargetAngle", "UpperAngle"
    },
    
    BallSocketConstraint = {
        "Attachment0", "Attachment1", "Enabled", "LimitsEnabled",
        "MaxFrictionTorque", "Radius", "Restitution", "TwistLimitsEnabled",
        "TwistLowerAngle", "TwistUpperAngle", "UpperAngle"
    },
    
    PrismaticConstraint = {
        "Attachment0", "Attachment1", "ActuatorType", "Enabled",
        "LimitsEnabled", "LowerLimit", "MotorMaxAcceleration", "MotorMaxForce",
        "Restitution", "ServoMaxForce", "Size", "Speed", "SoftlockServoUponReachingTarget",
        "TargetPosition", "UpperLimit", "Velocity"
    },
    
    CylindricalConstraint = {
        "Attachment0", "Attachment1", "AngularActuatorType", "AngularLimitsEnabled",
        "AngularResponsiveness", "AngularRestitution", "AngularSpeed",
        "AngularVelocity", "Enabled", "InclinationAngle", "LimitsEnabled",
        "LowerAngle", "LowerLimit", "MotorMaxAcceleration", "MotorMaxAngularAcceleration",
        "MotorMaxForce", "MotorMaxTorque", "Restitution", "RotationAxisVisible",
        "ServoMaxForce", "ServoMaxTorque", "Size", "SoftlockServoUponReachingTarget",
        "Speed", "TargetAngle", "TargetPosition", "UpperAngle", "UpperLimit",
        "Velocity", "WorldRotationAxis"
    },
    
    AlignOrientation = {
        "Attachment0", "Attachment1", "AlignType", "CFrame", "Enabled",
        "MaxAngularVelocity", "MaxTorque", "Mode", "PrimaryAxis",
        "PrimaryAxisOnly", "ReactionTorqueEnabled", "Responsiveness",
        "RigidityEnabled", "SecondaryAxis"
    },
    
    AlignPosition = {
        "Attachment0", "Attachment1", "ApplyAtCenterOfMass", "Enabled",
        "ForceLimitMode", "ForceRelativeTo", "MaxAxesForce", "MaxForce",
        "MaxVelocity", "Mode", "Position", "ReactionForceEnabled",
        "Responsiveness", "RigidityEnabled"
    },
    
    VectorForce = {
        "Attachment0", "ApplyAtCenterOfMass", "Enabled", "Force",
        "RelativeTo"
    },
    
    BodyGyro = {
        "CFrame", "D", "MaxTorque", "P"
    },
    
    BodyVelocity = {
        "MaxForce", "P", "Velocity"
    },
    
    BodyPosition = {
        "D", "MaxForce", "P", "Position"
    },
    
    BodyForce = {
        "Force"
    },
    
    BodyAngularVelocity = {
        "AngularVelocity", "MaxTorque", "P"
    },
    
    BodyThrust = {
        "Force", "Location"
    },
    
    RocketPropulsion = {
        "CartoonFactor", "MaxSpeed", "MaxThrust", "MaxTorque",
        "Target", "TargetOffset", "TargetRadius", "ThrustD", "ThrustP",
        "TurnD", "TurnP"
    }
}

-- Get properties for a class
function PropertyDatabase.GetPropertiesForClass(className)
    local props = {}
    
    -- Add base properties
    for _, prop in ipairs(PropertyDatabase.BaseProperties) do
        table.insert(props, prop)
    end
    
    -- Add class-specific properties
    if PropertyDatabase.ClassProperties[className] then
        for _, prop in ipairs(PropertyDatabase.ClassProperties[className]) do
            table.insert(props, prop)
        end
    end
    
    -- Check for BasePart inheritance
    local basePartClasses = {
        "Part", "WedgePart", "CornerWedgePart", "TrussPart",
        "MeshPart", "UnionOperation", "NegateOperation",
        "SpawnLocation", "Seat", "VehicleSeat", "SkateboardPlatform"
    }
    
    for _, baseClass in ipairs(basePartClasses) do
        if className == baseClass then
            for _, prop in ipairs(PropertyDatabase.ClassProperties.BasePart or {}) do
                if not table.find(props, prop) then
                    table.insert(props, prop)
                end
            end
            break
        end
    end
    
    return props
end

--=============================================================================
-- XML SERIALIZER
--=============================================================================
local XMLSerializer = {}
XMLSerializer.ReferentMap = {}
XMLSerializer.ReferentCounter = 0

function XMLSerializer:Reset()
    self.ReferentMap = {}
    self.ReferentCounter = 0
end

function XMLSerializer:GetReferent(instance)
    if not self.ReferentMap[instance] then
        self.ReferentCounter = self.ReferentCounter + 1
        self.ReferentMap[instance] = "RBX" .. tostring(self.ReferentCounter)
    end
    return self.ReferentMap[instance]
end

function XMLSerializer:SerializeValue(value, propertyType)
    if value == nil then
        return nil
    end
    
    local valueType = typeof(value)
    
    if valueType == "string" then
        return '<string name="Value">' .. Utils.EscapeXml(value) .. '</string>'
    elseif valueType == "number" then
        if propertyType == "int" or propertyType == "Int32" then
            return '<int name="Value">' .. tostring(math.floor(value)) .. '</int>'
        elseif propertyType == "int64" or propertyType == "Int64" then
            return '<int64 name="Value">' .. tostring(math.floor(value)) .. '</int64>'
        elseif propertyType == "float" or propertyType == "Float" then
            return '<float name="Value">' .. tostring(value) .. '</float>'
        else
            return '<double name="Value">' .. tostring(value) .. '</double>'
        end
    elseif valueType == "boolean" then
        return '<bool name="Value">' .. tostring(value) .. '</bool>'
    elseif valueType == "Vector3" then
        return string.format([[<Vector3 name="Value">
            <X>%f</X>
            <Y>%f</Y>
            <Z>%f</Z>
        </Vector3>]], value.X, value.Y, value.Z)
    elseif valueType == "Vector2" then
        return string.format([[<Vector2 name="Value">
            <X>%f</X>
            <Y>%f</Y>
        </Vector2>]], value.X, value.Y)
    elseif valueType == "CFrame" then
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = value:GetComponents()
        return string.format([[<CoordinateFrame name="Value">
            <X>%f</X>
            <Y>%f</Y>
            <Z>%f</Z>
            <R00>%f</R00>
            <R01>%f</R01>
            <R02>%f</R02>
            <R10>%f</R10>
            <R11>%f</R11>
            <R12>%f</R12>
            <R20>%f</R20>
            <R21>%f</R21>
            <R22>%f</R22>
        </CoordinateFrame>]], x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22)
    elseif valueType == "Color3" then
        return string.format([[<Color3 name="Value">
            <R>%f</R>
            <G>%f</G>
            <B>%f</B>
        </Color3>]], value.R, value.G, value.B)
    elseif valueType == "BrickColor" then
        return '<int name="Value">' .. tostring(value.Number) .. '</int>'
    elseif valueType == "UDim" then
        return string.format([[<UDim name="Value">
            <S>%f</S>
            <O>%d</O>
        </UDim>]], value.Scale, value.Offset)
    elseif valueType == "UDim2" then
        return string.format([[<UDim2 name="Value">
            <XS>%f</XS>
            <XO>%d</XO>
            <YS>%f</YS>
            <YO>%d</YO>
        </UDim2>]], value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
    elseif valueType == "Rect" then
        return string.format([[<Rect2D name="Value">
            <min>
                <X>%f</X>
                <Y>%f</Y>
            </min>
            <max>
                <X>%f</X>
                <Y>%f</Y>
            </max>
        </Rect2D>]], value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)
    elseif valueType == "NumberRange" then
        return string.format([[<NumberRange name="Value">%f %f</NumberRange>]], value.Min, value.Max)
    elseif valueType == "NumberSequence" then
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%f %f %f", kp.Time, kp.Value, kp.Envelope))
        end
        return '<NumberSequence name="Value">' .. table.concat(keypoints, " ") .. '</NumberSequence>'
    elseif valueType == "ColorSequence" then
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%f %f %f %f 0", kp.Time, kp.Value.R, kp.Value.G, kp.Value.B))
        end
        return '<ColorSequence name="Value">' .. table.concat(keypoints, " ") .. '</ColorSequence>'
    elseif valueType == "EnumItem" then
        return '<token name="Value">' .. tostring(value.Value) .. '</token>'
    elseif valueType == "Instance" then
        if self.ReferentMap[value] then
            return '<Ref name="Value">' .. self:GetReferent(value) .. '</Ref>'
        else
            return '<Ref name="Value">null</Ref>'
        end
    elseif valueType == "Ray" then
        return string.format([[<Ray name="Value">
            <origin>
                <X>%f</X>
                <Y>%f</Y>
                <Z>%f</Z>
            </origin>
            <direction>
                <X>%f</X>
                <Y>%f</Y>
                <Z>%f</Z>
            </direction>
        </Ray>]], value.Origin.X, value.Origin.Y, value.Origin.Z,
                value.Direction.X, value.Direction.Y, value.Direction.Z)
    elseif valueType == "Faces" then
        local faces = {}
        if value.Top then table.insert(faces, "Top") end
        if value.Bottom then table.insert(faces, "Bottom") end
        if value.Left then table.insert(faces, "Left") end
        if value.Right then table.insert(faces, "Right") end
        if value.Back then table.insert(faces, "Back") end
        if value.Front then table.insert(faces, "Front") end
        return '<Faces name="Value">' .. table.concat(faces, ", ") .. '</Faces>'
    elseif valueType == "Axes" then
        local axes = {}
        if value.X then table.insert(axes, "X") end
        if value.Y then table.insert(axes, "Y") end
        if value.Z then table.insert(axes, "Z") end
        return '<Axes name="Value">' .. table.concat(axes, ", ") .. '</Axes>'
    elseif valueType == "PhysicalProperties" then
        if value then
            return string.format([[<PhysicalProperties name="Value">
                <CustomPhysics>true</CustomPhysics>
                <Density>%f</Density>
                <Friction>%f</Friction>
                <Elasticity>%f</Elasticity>
                <FrictionWeight>%f</FrictionWeight>
                <ElasticityWeight>%f</ElasticityWeight>
            </PhysicalProperties>]], 
                value.Density, value.Friction, value.Elasticity,
                value.FrictionWeight, value.ElasticityWeight)
        else
            return [[<PhysicalProperties name="Value">
                <CustomPhysics>false</CustomPhysics>
            </PhysicalProperties>]]
        end
    elseif valueType == "Font" then
        return string.format([[<Font name="Value">
            <Family><url>%s</url></Family>
            <Weight>%d</Weight>
            <Style>%s</Style>
        </Font>]], Utils.EscapeXml(value.Family), value.Weight.Value, value.Style.Name)
    end
    
    -- Fallback to string
    return '<string name="Value">' .. Utils.EscapeXml(tostring(value)) .. '</string>'
end

function XMLSerializer:SerializeProperty(instance, propertyName)
    local success, value = pcall(function()
        return instance[propertyName]
    end)
    
    if not success then
        -- Try hidden property
        if ExecutorSupport.Functions.gethiddenproperty then
            success, value = pcall(function()
                return gethiddenproperty(instance, propertyName)
            end)
        end
    end
    
    if not success or value == nil then
        return nil
    end
    
    local valueType = typeof(value)
    local xml = ""
    
    if valueType == "string" then
        xml = '<string name="' .. propertyName .. '">' .. Utils.EscapeXml(value) .. '</string>'
    elseif valueType == "number" then
        -- Determine if int or float based on property name patterns
        local isInt = propertyName:match("Index$") or 
                      propertyName:match("Count$") or 
                      propertyName:match("Offset$") and propertyName:match("Pixel") or
                      propertyName == "ZIndex" or
                      propertyName == "LayoutOrder"
        
        if isInt then
            xml = '<int name="' .. propertyName .. '">' .. tostring(math.floor(value)) .. '</int>'
        else
            xml = '<float name="' .. propertyName .. '">' .. tostring(value) .. '</float>'
        end
    elseif valueType == "boolean" then
        xml = '<bool name="' .. propertyName .. '">' .. tostring(value) .. '</bool>'
    elseif valueType == "Vector3" then
        xml = string.format('<Vector3 name="%s"><X>%f</X><Y>%f</Y><Z>%f</Z></Vector3>', 
            propertyName, value.X, value.Y, value.Z)
    elseif valueType == "Vector2" then
        xml = string.format('<Vector2 name="%s"><X>%f</X><Y>%f</Y></Vector2>',
            propertyName, value.X, value.Y)
    elseif valueType == "CFrame" then
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = value:GetComponents()
        xml = string.format([[<CoordinateFrame name="%s">
            <X>%f</X><Y>%f</Y><Z>%f</Z>
            <R00>%f</R00><R01>%f</R01><R02>%f</R02>
            <R10>%f</R10><R11>%f</R11><R12>%f</R12>
            <R20>%f</R20><R21>%f</R21><R22>%f</R22>
        </CoordinateFrame>]], 
            propertyName, x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22)
    elseif valueType == "Color3" then
        -- Use Color3uint8 format
        xml = string.format('<Color3uint8 name="%s">%d</Color3uint8>',
            propertyName,
            bit32.bor(
                bit32.lshift(math.floor(value.B * 255), 16),
                bit32.lshift(math.floor(value.G * 255), 8),
                math.floor(value.R * 255)
            ))
    elseif valueType == "BrickColor" then
        xml = '<int name="' .. propertyName .. '">' .. tostring(value.Number) .. '</int>'
    elseif valueType == "UDim" then
        xml = string.format('<UDim name="%s"><S>%f</S><O>%d</O></UDim>',
            propertyName, value.Scale, value.Offset)
    elseif valueType == "UDim2" then
        xml = string.format('<UDim2 name="%s"><XS>%f</XS><XO>%d</XO><YS>%f</YS><YO>%d</YO></UDim2>',
            propertyName, value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
    elseif valueType == "Rect" then
        xml = string.format([[<Rect2D name="%s">
            <min><X>%f</X><Y>%f</Y></min>
            <max><X>%f</X><Y>%f</Y></max>
        </Rect2D>]], propertyName, value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)
    elseif valueType == "NumberRange" then
        xml = string.format('<NumberRange name="%s">%f %f</NumberRange>', 
            propertyName, value.Min, value.Max)
    elseif valueType == "NumberSequence" then
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%f %f %f", kp.Time, kp.Value, kp.Envelope))
        end
        xml = '<NumberSequence name="' .. propertyName .. '">' .. table.concat(keypoints, " ") .. '</NumberSequence>'
    elseif valueType == "ColorSequence" then
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%f %f %f %f 0", kp.Time, kp.Value.R, kp.Value.G, kp.Value.B))
        end
        xml = '<ColorSequence name="' .. propertyName .. '">' .. table.concat(keypoints, " ") .. '</ColorSequence>'
    elseif valueType == "EnumItem" then
        xml = '<token name="' .. propertyName .. '">' .. tostring(value.Value) .. '</token>'
    elseif valueType == "Instance" then
        if self.ReferentMap[value] then
            xml = '<Ref name="' .. propertyName .. '">' .. self:GetReferent(value) .. '</Ref>'
        else
            xml = '<Ref name="' .. propertyName .. '">null</Ref>'
        end
    elseif valueType == "PhysicalProperties" then
        xml = string.format([[<PhysicalProperties name="%s">
            <CustomPhysics>true</CustomPhysics>
            <Density>%f</Density>
            <Friction>%f</Friction>
            <Elasticity>%f</Elasticity>
            <FrictionWeight>%f</FrictionWeight>
            <ElasticityWeight>%f</ElasticityWeight>
        </PhysicalProperties>]], 
            propertyName, value.Density, value.Friction, value.Elasticity,
            value.FrictionWeight, value.ElasticityWeight)
    elseif valueType == "Font" then
        xml = string.format([[<Font name="%s">
            <Family><url>%s</url></Family>
            <Weight>%d</Weight>
            <Style>%s</Style>
        </Font>]], propertyName, Utils.EscapeXml(value.Family), value.Weight.Value, value.Style.Name)
    else
        -- Try to serialize as string for unknown types
        xml = '<string name="' .. propertyName .. '">' .. Utils.EscapeXml(tostring(value)) .. '</string>'
    end
    
    return xml
end

function XMLSerializer:SerializeInstance(instance, depth)
    depth = depth or 0
    local indent = string.rep("\t", depth)
    
    if not Utils.IsValidInstance(instance) then
        return ""
    end
    
    local className = instance.ClassName
    local referent = self:GetReferent(instance)
    
    local xml = indent .. '<Item class="' .. className .. '" referent="' .. referent .. '">\n'
    xml = xml .. indent .. "\t<Properties>\n"
    
    -- Get properties for this class
    local properties = PropertyDatabase.GetPropertiesForClass(className)
    
    for _, propName in ipairs(properties) do
        if propName ~= "Parent" then -- Skip Parent property
            local propXml = self:SerializeProperty(instance, propName)
            if propXml then
                xml = xml .. indent .. "\t\t" .. propXml .. "\n"
            end
        end
    end
    
    xml = xml .. indent .. "\t</Properties>\n"
    
    -- Serialize children
    local children = {}
    pcall(function()
        children = instance:GetChildren()
    end)
    
    for _, child in ipairs(children) do
        xml = xml .. self:SerializeInstance(child, depth + 1)
    end
    
    xml = xml .. indent .. "</Item>\n"
    
    return xml
end

--=============================================================================
-- TERRAIN SERIALIZER
--=============================================================================
local TerrainSerializer = {}

function TerrainSerializer:SerializeTerrain(terrain)
    Logger:Info("Bắt đầu serialize Terrain...")
    
    local xml = '<Item class="Terrain" referent="' .. XMLSerializer:GetReferent(terrain) .. '">\n'
    xml = xml .. "\t<Properties>\n"
    
    -- Terrain properties
    local terrainProps = {
        "Decoration", "GrassLength", "WaterColor", "WaterReflectance",
        "WaterTransparency", "WaterWaveSize", "WaterWaveSpeed"
    }
    
    for _, propName in ipairs(terrainProps) do
        local propXml = XMLSerializer:SerializeProperty(terrain, propName)
        if propXml then
            xml = xml .. "\t\t" .. propXml .. "\n"
        end
    end
    
    -- Serialize MaterialColors
    pcall(function()
        local materialColors = terrain.MaterialColors
        if materialColors then
            xml = xml .. '\t\t<BinaryString name="MaterialColors">'
            -- Encode MaterialColors to base64
            local encoded = ""
            -- MaterialColors serialization is complex, use placeholder
            xml = xml .. '</BinaryString>\n'
        end
    end)
    
    -- Serialize terrain voxel data
    local terrainRegion = terrain:GetMaterialColor(Enum.Material.Grass)
    
    -- Get terrain bounds
    local success, err = pcall(function()
        -- Get terrain size
        local regionMin = Vector3.new(-32000, -32000, -32000)
        local regionMax = Vector3.new(32000, 32000, 32000)
        
        -- Try to get actual terrain bounds
        pcall(function()
            local size = terrain.MaxExtents
            regionMin = size.Min
            regionMax = size.Max
        end)
        
        -- Serialize SmoothGrid (terrain data)
        Logger:Progress("Đang đọc dữ liệu Terrain voxels...")
        
        local resolution = 4
        local chunkSize = 64
        
        local terrainData = {}
        local hasData = false
        
        -- Scan terrain in chunks
        for x = regionMin.X, regionMax.X, chunkSize * resolution do
            for y = regionMin.Y, regionMax.Y, chunkSize * resolution do
                for z = regionMin.Z, regionMax.Z, chunkSize * resolution do
                    local region = Region3.new(
                        Vector3.new(x, y, z),
                        Vector3.new(
                            math.min(x + chunkSize * resolution, regionMax.X),
                            math.min(y + chunkSize * resolution, regionMax.Y),
                            math.min(z + chunkSize * resolution, regionMax.Z)
                        )
                    )
                    
                    local success, materials, occupancies = pcall(function()
                        return terrain:ReadVoxels(region, resolution)
                    end)
                    
                    if success and materials then
                        local size = materials.Size
                        for xi = 1, size.X do
                            for yi = 1, size.Y do
                                for zi = 1, size.Z do
                                    local material = materials[xi][yi][zi]
                                    local occupancy = occupancies[xi][yi][zi]
                                    
                                    if material ~= Enum.Material.Air and occupancy > 0 then
                                        hasData = true
                                        table.insert(terrainData, {
                                            x = x + (xi - 1) * resolution,
                                            y = y + (yi - 1) * resolution,
                                            z = z + (zi - 1) * resolution,
                                            material = material.Value,
                                            occupancy = occupancy
                                        })
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Yield to prevent timeout
                    if #terrainData % 1000 == 0 then
                        task.wait()
                    end
                end
            end
        end
        
        if hasData then
            Logger:Info("Đã tìm thấy " .. #terrainData .. " terrain voxels")
            
            -- Encode terrain data
            local encodedData = HttpService:JSONEncode(terrainData)
            local base64Data = ""
            
            -- Base64 encode
            local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
            local data = encodedData
            
            for i = 1, #data, 3 do
                local a, b, c = data:byte(i, i + 2)
                a, b, c = a or 0, b or 0, c or 0
                
                local n = a * 65536 + b * 256 + c
                
                local c1 = bit32.rshift(n, 18) % 64
                local c2 = bit32.rshift(n, 12) % 64
                local c3 = bit32.rshift(n, 6) % 64
                local c4 = n % 64
                
                base64Data = base64Data .. b64chars:sub(c1 + 1, c1 + 1)
                base64Data = base64Data .. b64chars:sub(c2 + 1, c2 + 1)
                
                if i + 1 <= #data then
                    base64Data = base64Data .. b64chars:sub(c3 + 1, c3 + 1)
                else
                    base64Data = base64Data .. "="
                end
                
                if i + 2 <= #data then
                    base64Data = base64Data .. b64chars:sub(c4 + 1, c4 + 1)
                else
                    base64Data = base64Data .. "="
                end
            end
            
            xml = xml .. '\t\t<BinaryString name="SmoothGrid">' .. base64Data .. '</BinaryString>\n'
        end
    end)
    
    xml = xml .. "\t</Properties>\n"
    xml = xml .. "</Item>\n"
    
    Logger:Success("Terrain serialize hoàn tất!")
    return xml
end

--=============================================================================
-- SCRIPT SERIALIZER
--=============================================================================
local ScriptSerializer = {}

function ScriptSerializer:DecompileScript(script)
    local source = ""
    
    -- Try to get source
    local success = pcall(function()
        source = script.Source
    end)
    
    if success and source and source ~= "" then
        return source
    end
    
    -- Try decompile function if available
    if ExecutorSupport.Functions.decompile then
        success, source = pcall(function()
            return decompile(script)
        end)
        
        if success and source then
            return source
        end
    end
    
    -- Try getscriptbytecode
    if ExecutorSupport.Functions.getscriptbytecode then
        local bytecode
        success, bytecode = pcall(function()
            return getscriptbytecode(script)
        end)
        
        if success and bytecode then
            return "-- Bytecode available but decompilation not supported\n-- Script: " .. script:GetFullName()
        end
    end
    
    return "-- Could not retrieve script source\n-- Script: " .. script:GetFullName()
end

function ScriptSerializer:SerializeScript(script)
    local className = script.ClassName
    local referent = XMLSerializer:GetReferent(script)
    
    local xml = '<Item class="' .. className .. '" referent="' .. referent .. '">\n'
    xml = xml .. "\t<Properties>\n"
    
    -- Name
    xml = xml .. '\t\t<string name="Name">' .. Utils.EscapeXml(script.Name) .. '</string>\n'
    
    -- Disabled
    if className ~= "ModuleScript" then
        local disabled = false
        pcall(function()
            disabled = script.Disabled
        end)
        xml = xml .. '\t\t<bool name="Disabled">' .. tostring(disabled) .. '</bool>\n'
    end
    
    -- RunContext (for Scripts)
    if className == "Script" then
        local runContext = 0
        pcall(function()
            runContext = script.RunContext.Value
        end)
        xml = xml .. '\t\t<token name="RunContext">' .. tostring(runContext) .. '</token>\n'
    end
    
    -- Source
    local source = self:DecompileScript(script)
    xml = xml .. '\t\t<ProtectedString name="Source"><![CDATA[' .. source .. ']]></ProtectedString>\n'
    
    xml = xml .. "\t</Properties>\n"
    
    -- Serialize children
    local children = {}
    pcall(function()
        children = script:GetChildren()
    end)
    
    for _, child in ipairs(children) do
        xml = xml .. XMLSerializer:SerializeInstance(child, 1)
    end
    
    xml = xml .. "</Item>\n"
    
    return xml
end

--=============================================================================
-- MAIN SAVE FUNCTIONS
--=============================================================================
local SaveManager = {}
SaveManager.Options = {
    IncludeTerrain = true,
    IncludeModels = true,
    IncludeScripts = true,
    DecompileScripts = true,
    IgnoreDefaultProperties = true,
    SaveNilInstances = false,
    IgnoreSharedStrings = true,
    Timeout = 300
}

-- Instances to save
SaveManager.Containers = {
    game:GetService("Workspace"),
    game:GetService("Lighting"),
    game:GetService("ReplicatedFirst"),
    game:GetService("ReplicatedStorage"),
    game:GetService("StarterGui"),
    game:GetService("StarterPack"),
    game:GetService("StarterPlayer"),
    game:GetService("Teams"),
    game:GetService("SoundService"),
    game:GetService("Chat"),
    game:GetService("LocalizationService"),
    game:GetService("TestService")
}

function SaveManager:GenerateFileName(prefix)
    local gameId = game.PlaceId
    local gameName = "Unknown"
    
    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(gameId).Name
    end)
    
    gameName = gameName:gsub("[%p%c]", ""):gsub("%s+", "_")
    
    local timestamp = os.date("%Y%m%d_%H%M%S")
    
    return string.format("%s_%s_%s_%s.rbxl", prefix, gameName, gameId, timestamp)
end

function SaveManager:CreateRBXLHeader()
    return [[<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
    <Meta name="ExplicitAutoJoints">true</Meta>
    <External>null</External>
    <External>nil</External>
]]
end

function SaveManager:CreateRBXLFooter()
    return [[</roblox>]]
end

function SaveManager:SaveTerrain()
    Logger:Info("═══════════════════════════════════════")
    Logger:Info("    BaoSaveInstance - SAVE TERRAIN     ")
    Logger:Info("═══════════════════════════════════════")
    Logger:Info("Executor: " .. ExecutorSupport.Name)
    
    XMLSerializer:Reset()
    
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        Logger:Error("Không tìm thấy Terrain trong game!")
        return false
    end
    
    Logger:Info("Bắt đầu save Terrain...")
    
    local xml = self:CreateRBXLHeader()
    xml = xml .. TerrainSerializer:SerializeTerrain(terrain)
    xml = xml .. self:CreateRBXLFooter()
    
    local fileName = self:GenerateFileName("Terrain")
    
    Logger:Progress("Đang ghi file: " .. fileName)
    
    local success, err = pcall(function()
        writefile(fileName, xml)
    end)
    
    if success then
        Logger:Success("════════════════════════════════════")
        Logger:Success("    SAVE TERRAIN HOÀN TẤT!          ")
        Logger:Success("════════════════════════════════════")
        Logger:Success("File: " .. fileName)
        return true
    else
        Logger:Error("Lỗi khi ghi file: " .. tostring(err))
        return false
    end
end

function SaveManager:SaveAllModels()
    Logger:Info("═══════════════════════════════════════")
    Logger:Info("   BaoSaveInstance - SAVE ALL MODELS   ")
    Logger:Info("═══════════════════════════════════════")
    Logger:Info("Executor: " .. ExecutorSupport.Name)
    
    XMLSerializer:Reset()
    
    local startTime = tick()
    local totalInstances = 0
    
    -- First pass: assign referents to all instances
    Logger:Progress("Đang quét và đánh dấu tất cả instances...")
    
    for _, container in ipairs(self.Containers) do
        pcall(function()
            for _, instance in pairs(container:GetDescendants()) do
                if instance.ClassName ~= "Terrain" then
                    XMLSerializer:GetReferent(instance)
                    totalInstances = totalInstances + 1
                end
            end
        end)
    end
    
    Logger:Info("Tổng số instances: " .. totalInstances)
    Logger:Progress("Đang serialize tất cả models...")
    
    local xml = self:CreateRBXLHeader()
    
    local processedCount = 0
    
    for _, container in ipairs(self.Containers) do
        Logger:Progress("Đang xử lý: " .. container.Name)
        
        local containerXml = '<Item class="' .. container.ClassName .. '" referent="' .. XMLSerializer:GetReferent(container) .. '">\n'
        containerXml = containerXml .. "\t<Properties>\n"
        containerXml = containerXml .. '\t\t<string name="Name">' .. Utils.EscapeXml(container.Name) .. '</string>\n'
        containerXml = containerXml .. "\t</Properties>\n"
        
        pcall(function()
            for _, child in pairs(container:GetChildren()) do
                if child.ClassName ~= "Terrain" and 
                   child.ClassName ~= "Camera" and
                   not child:IsA("Player") and
                   not child:IsA("BaseScript") then
                    containerXml = containerXml .. XMLSerializer:SerializeInstance(child, 1)
                    processedCount = processedCount + 1
                    
                    if processedCount % 100 == 0 then
                        Logger:Progress("Đã xử lý: " .. processedCount .. " instances")
                        task.wait()
                    end
                end
            end
        end)
        
        containerXml = containerXml .. "</Item>\n"
        xml = xml .. containerXml
    end
    
    xml = xml .. self:CreateRBXLFooter()
    
    local fileName = self:GenerateFileName("Models")
    
    Logger:Progress("Đang ghi file: " .. fileName)
    
    local success, err = pcall(function()
        writefile(fileName, xml)
    end)
    
    local elapsed = tick() - startTime
    
    if success then
        Logger:Success("════════════════════════════════════")
        Logger:Success("   SAVE ALL MODELS HOÀN TẤT!       ")
        Logger:Success("════════════════════════════════════")
        Logger:Success("File: " .. fileName)
        Logger:Success("Tổng instances: " .. totalInstances)
        Logger:Success("Thời gian: " .. string.format("%.2f", elapsed) .. " giây")
        return true
    else
        Logger:Error("Lỗi khi ghi file: " .. tostring(err))
        return false
    end
end

function SaveManager:SaveAllScripts()
    Logger:Info("Đang save tất cả scripts...")
    
    local scripts = {}
    
    for _, container in ipairs(self.Containers) do
        pcall(function()
            for _, instance in pairs(container:GetDescendants()) do
                if instance:IsA("BaseScript") or instance:IsA("ModuleScript") then
                    table.insert(scripts, instance)
                end
            end
        end)
    end
    
    -- Also get nil instances if available
    if ExecutorSupport.Functions.getnilinstances then
        pcall(function()
            for _, instance in pairs(getnilinstances()) do
                if instance:IsA("BaseScript") or instance:IsA("ModuleScript") then
                    table.insert(scripts, instance)
                end
            end
        end)
    end
    
    -- Get all scripts if available
    if ExecutorSupport.Functions.getscripts then
        pcall(function()
            for _, script in pairs(getscripts()) do
                if not table.find(scripts, script) then
                    table.insert(scripts, script)
                end
            end
        end)
    end
    
    Logger:Info("Tìm thấy " .. #scripts .. " scripts")
    
    local xml = ""
    for i, script in ipairs(scripts) do
        xml = xml .. ScriptSerializer:SerializeScript(script)
        
        if i % 10 == 0 then
            Logger:Progress("Đã xử lý script: " .. i .. "/" .. #scripts)
            task.wait()
        end
    end
    
    return xml
end

function SaveManager:SaveGame()
    Logger:Info("═══════════════════════════════════════")
    Logger:Info("      BaoSaveInstance - SAVE GAME      ")
    Logger:Info("═══════════════════════════════════════")
    Logger:Info("Executor: " .. ExecutorSupport.Name)
    Logger:Info("Game ID: " .. game.PlaceId)
    
    -- Check if native saveinstance is available
    if ExecutorSupport.Functions.saveinstance then
        Logger:Info("Phát hiện saveinstance native, sử dụng phương pháp tối ưu...")
        
        local fileName = self:GenerateFileName("Game")
        
        local success, err = pcall(function()
            local options = {
                mode = "full",
                noscripts = false,
                scriptcache = true,
                timeout = 300,
                decompile = true,
                DecompileIgnore = {},
                IgnoreProperties = {},
                IgnoreClasses = {"Player", "PlayerScripts", "PlayerGui"},
                SaveBytecode = true,
                FilePath = fileName
            }
            
            -- Try different saveinstance signatures
            if syn and syn.saveinstance then
                syn.saveinstance(options)
            else
                saveinstance(options)
            end
        end)
        
        if success then
            Logger:Success("════════════════════════════════════")
            Logger:Success("      SAVE GAME HOÀN TẤT!          ")
            Logger:Success("════════════════════════════════════")
            Logger:Success("File: " .. fileName)
            return true
        else
            Logger:Warning("Native saveinstance thất bại, sử dụng phương pháp thủ công...")
            Logger:Warning("Lỗi: " .. tostring(err))
        end
    end
    
    -- Manual save
    XMLSerializer:Reset()
    
    local startTime = tick()
    local totalInstances = 0
    
    -- First pass: assign referents
    Logger:Progress("Đang quét tất cả instances...")
    
    for _, container in ipairs(self.Containers) do
        pcall(function()
            XMLSerializer:GetReferent(container)
            for _, instance in pairs(container:GetDescendants()) do
                XMLSerializer:GetReferent(instance)
                totalInstances = totalInstances + 1
            end
        end)
    end
    
    -- Add nil instances
    if ExecutorSupport.Functions.getnilinstances then
        pcall(function()
            for _, instance in pairs(getnilinstances()) do
                XMLSerializer:GetReferent(instance)
                totalInstances = totalInstances + 1
            end
        end)
    end
    
    Logger:Info("Tổng số instances: " .. totalInstances)
    
    -- Build XML
    local xml = self:CreateRBXLHeader()
    
    -- Save Terrain first
    Logger:Progress("Bước 1/3: Đang save Terrain...")
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        xml = xml .. TerrainSerializer:SerializeTerrain(terrain)
    end
    
    -- Save all containers
    Logger:Progress("Bước 2/3: Đang save tất cả Models...")
    local processedCount = 0
    
    for _, container in ipairs(self.Containers) do
        Logger:Progress("Đang xử lý: " .. container.Name)
        
        local containerXml = '<Item class="' .. container.ClassName .. '" referent="' .. XMLSerializer:GetReferent(container) .. '">\n'
        containerXml = containerXml .. "\t<Properties>\n"
        containerXml = containerXml .. '\t\t<string name="Name">' .. Utils.EscapeXml(container.Name) .. '</string>\n'
        containerXml = containerXml .. "\t</Properties>\n"
        
        pcall(function()
            for _, child in pairs(container:GetChildren()) do
                if child.ClassName ~= "Terrain" and
                   child.ClassName ~= "Camera" and
                   not child:IsA("Player") then
                    if child:IsA("BaseScript") or child:IsA("ModuleScript") then
                        containerXml = containerXml .. ScriptSerializer:SerializeScript(child)
                    else
                        containerXml = containerXml .. XMLSerializer:SerializeInstance(child, 1)
                    end
                    
                    processedCount = processedCount + 1
                    
                    if processedCount % 100 == 0 then
                        Logger:Progress("Đã xử lý: " .. processedCount .. " instances")
                        task.wait()
                    end
                end
            end
        end)
        
        containerXml = containerXml .. "</Item>\n"
        xml = xml .. containerXml
    end
    
    -- Save scripts from nil
    Logger:Progress("Bước 3/3: Đang save Scripts...")
    if ExecutorSupport.Functions.getnilinstances then
        pcall(function()
            for _, instance in pairs(getnilinstances()) do
                if instance:IsA("BaseScript") or instance:IsA("ModuleScript") then
                    xml = xml .. ScriptSerializer:SerializeScript(instance)
                end
            end
        end)
    end
    
    xml = xml .. self:CreateRBXLFooter()
    
    local fileName = self:GenerateFileName("Game")
    
    Logger:Progress("Đang ghi file: " .. fileName)
    Logger:Progress("Kích thước: " .. string.format("%.2f", #xml / 1024 / 1024) .. " MB")
    
    local success, err = pcall(function()
        writefile(fileName, xml)
    end)
    
    local elapsed = tick() - startTime
    
    if success then
        Logger:Success("════════════════════════════════════")
        Logger:Success("      SAVE GAME HOÀN TẤT!          ")
        Logger:Success("════════════════════════════════════")
        Logger:Success("File: " .. fileName)
        Logger:Success("Tổng instances: " .. totalInstances)
        Logger:Success("Kích thước: " .. string.format("%.2f", #xml / 1024 / 1024) .. " MB")
        Logger:Success("Thời gian: " .. string.format("%.2f", elapsed) .. " giây")
        return true
    else
        Logger:Error("Lỗi khi ghi file: " .. tostring(err))
        return false
    end
end

--=============================================================================
-- USER INTERFACE
--=============================================================================
local UI = {}

function UI:Create()
    -- Destroy existing GUI if present
    local existingGui = LocalPlayer:FindFirstChild("PlayerGui") and 
                        LocalPlayer.PlayerGui:FindFirstChild("BaoSaveInstanceUI")
    if existingGui then
        existingGui:Destroy()
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstanceUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Protect GUI if possible
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
    elseif gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    if not screenGui.Parent then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    -- Corner radius
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- Stroke
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(80, 80, 120)
    mainStroke.Thickness = 2
    mainStroke.Parent = mainFrame
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Fix bottom corners of title bar
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 15)
    titleFix.Position = UDim2.new(0, 0, 1, -15)
    titleFix.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
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
    titleText.TextSize = 18
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -40, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
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
    
    -- Info Label
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "Info"
    infoLabel.Size = UDim2.new(1, 0, 0, 40)
    infoLabel.Position = UDim2.new(0, 0, 0, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "Executor: " .. ExecutorSupport.Name .. "\nGame ID: " .. game.PlaceId
    infoLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    infoLabel.TextSize = 12
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.Parent = contentFrame
    
    -- Button creation function
    local function createButton(name, text, icon, color, yPos)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 55)
        btn.Position = UDim2.new(0, 0, 0, yPos)
        btn.BackgroundColor3 = color
        btn.Text = ""
        btn.Parent = contentFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = btn
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(
            math.min(color.R * 255 + 40, 255),
            math.min(color.G * 255 + 40, 255),
            math.min(color.B * 255 + 40, 255)
        )
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.5
        btnStroke.Parent = btn
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 40, 1, 0)
        iconLabel.Position = UDim2.new(0, 10, 0, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon
        iconLabel.TextSize = 24
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        iconLabel.Parent = btn
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -60, 0, 25)
        textLabel.Position = UDim2.new(0, 55, 0, 8)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextSize = 16
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = btn
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -60, 0, 15)
        descLabel.Position = UDim2.new(0, 55, 0, 32)
        descLabel.BackgroundTransparency = 1
        descLabel.TextSize = 11
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = btn
        
        -- Hover effects
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(
                    math.min(color.R * 255 + 20, 255),
                    math.min(color.G * 255 + 20, 255),
                    math.min(color.B * 255 + 20, 255)
                )
            }):Play()
        end)
        
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = color
            }):Play()
        end)
        
        return btn, descLabel
    end
    
    -- Save Game Button
    local saveGameBtn, saveGameDesc = createButton(
        "SaveGame",
        "Save Game",
        "🎮",
        Color3.fromRGB(60, 120, 60),
        50
    )
    saveGameDesc.Text = "Save toàn bộ: Terrain + Models + Scripts"
    
    saveGameBtn.MouseButton1Click:Connect(function()
        saveGameBtn.Text = "Đang save..."
        task.spawn(function()
            SaveManager:SaveGame()
            saveGameBtn.Text = ""
        end)
    end)
    
    -- Save Terrain Button
    local saveTerrainBtn, saveTerrainDesc = createButton(
        "SaveTerrain",
        "Save Terrain",
        "🏔️",
        Color3.fromRGB(60, 100, 140),
        115
    )
    saveTerrainDesc.Text = "Chỉ save địa hình, nước, vật liệu"
    
    saveTerrainBtn.MouseButton1Click:Connect(function()
        saveTerrainBtn.Text = "Đang save..."
        task.spawn(function()
            SaveManager:SaveTerrain()
            saveTerrainBtn.Text = ""
        end)
    end)
    
    -- Save All Models Button
    local saveModelsBtn, saveModelsDesc = createButton(
        "SaveModels",
        "Save All Models",
        "📦",
        Color3.fromRGB(140, 80, 60),
        180
    )
    saveModelsDesc.Text = "Save tất cả models, parts, meshes"
    
    saveModelsBtn.MouseButton1Click:Connect(function()
        saveModelsBtn.Text = "Đang save..."
        task.spawn(function()
            SaveManager:SaveAllModels()
            saveModelsBtn.Text = ""
        end)
    end)
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, 0, 0, 50)
    statusLabel.Position = UDim2.new(0, 0, 1, -55)
    statusLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    statusLabel.Text = "📁 Files sẽ được lưu vào thư mục workspace"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextWrapped = true
    statusLabel.Parent = contentFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusLabel
    
    Logger:Success("BaoSaveInstance UI đã được tạo thành công!")
    
    return screenGui
end

--=============================================================================
-- INITIALIZATION
--=============================================================================
function BaoSaveInstance.Init()
    Logger:Info("═══════════════════════════════════════")
    Logger:Info("       BaoSaveInstance Khởi động       ")
    Logger:Info("═══════════════════════════════════════")
    Logger:Info("Phiên bản: " .. BaoSaveInstance.Version)
    Logger:Info("Executor: " .. ExecutorSupport.Name)
    Logger:Info("")
    Logger:Info("Các tính năng hỗ trợ:")
    
    for funcName, supported in pairs(ExecutorSupport.Functions) do
        if supported then
            Logger:Info("  ✓ " .. funcName)
        end
    end
    
    Logger:Info("")
    Logger:Info("Đang tạo giao diện...")
    
    UI:Create()
    
    Logger:Success("BaoSaveInstance đã sẵn sàng!")
end

-- Export
BaoSaveInstance.SaveManager = SaveManager
BaoSaveInstance.XMLSerializer = XMLSerializer
BaoSaveInstance.TerrainSerializer = TerrainSerializer
BaoSaveInstance.ScriptSerializer = ScriptSerializer
BaoSaveInstance.Logger = Logger
BaoSaveInstance.Utils = Utils
BaoSaveInstance.ExecutorSupport = ExecutorSupport
BaoSaveInstance.UI = UI

-- Auto-run
BaoSaveInstance.Init()

return BaoSaveInstance
