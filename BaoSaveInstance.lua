--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                         BaoSaveInstance v1.0.0                               ║
║              Universal Save Instance Tool for Roblox Exploits                ║
║                                                                              ║
║  Supports: Xeno, Solara, TNG, Velocity, Wave, and compatible executors       ║
║  Output: Single .rbxl file                                                   ║
║                                                                              ║
║  Features:                                                                   ║
║  - Save Game (Terrain + Models + Scripts)                                    ║
║  - Save Terrain Only                                                         ║
║  - Save All Models                                                           ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

--[[ ═══════════════════════════════════════════════════════════════════════════
     SERVICES & VARIABLES
═══════════════════════════════════════════════════════════════════════════ ]]--

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local SoundService = game:GetService("SoundService")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

--[[ ═══════════════════════════════════════════════════════════════════════════
     BAOSAVEINSTANCE MODULE
═══════════════════════════════════════════════════════════════════════════ ]]--

local BaoSaveInstance = {
    Version = "1.0.0",
    Name = "BaoSaveInstance",
    Author = "Bao",
    
    -- Statistics
    Stats = {
        InstancesSaved = 0,
        TotalSize = 0,
        StartTime = 0,
        EndTime = 0,
    },
    
    -- Configuration
    Config = {
        DecompileScripts = true,
        SaveNilInstances = true,
        IgnorePlayerCharacters = true,
        IgnoreDefaultPlayerScripts = true,
        RemovePlayerCharacters = true,
        SavePlayers = false,
        AntiIdle = true,
        ShowProgress = true,
        FilePath = "",
        MaxRetries = 3,
        YieldInterval = 100, -- Yield every N instances to prevent freeze
    },
    
    -- Internal state
    _referenceId = 0,
    _references = {},
    _instanceToRef = {},
    _processedInstances = {},
    _statusCallback = nil,
}

--[[ ═══════════════════════════════════════════════════════════════════════════
     EXECUTOR API LAYER - Universal compatibility
═══════════════════════════════════════════════════════════════════════════ ]]--

local ExecutorAPI = {}

-- Detect executor
function ExecutorAPI.GetExecutorName()
    local executorName = "Unknown"
    
    pcall(function()
        if identifyexecutor then
            executorName = identifyexecutor()
        elseif getexecutorname then
            executorName = getexecutorname()
        end
    end)
    
    -- Specific detection fallbacks
    if executorName == "Unknown" then
        if XENO_UNIQUE or xeno then executorName = "Xeno"
        elseif Solara then executorName = "Solara"
        elseif wave then executorName = "Wave"
        elseif Velocity then executorName = "Velocity"
        elseif TNG then executorName = "TNG"
        elseif syn then executorName = "Synapse"
        elseif fluxus then executorName = "Fluxus"
        elseif krnl then executorName = "KRNL"
        end
    end
    
    return executorName
end

-- File operations
function ExecutorAPI.WriteFile(path, content)
    if writefile then
        return writefile(path, content)
    end
    error("[BaoSaveInstance] writefile function not available!")
end

function ExecutorAPI.ReadFile(path)
    if readfile then
        return readfile(path)
    end
    return nil
end

function ExecutorAPI.AppendFile(path, content)
    if appendfile then
        return appendfile(path, content)
    else
        local existing = ExecutorAPI.ReadFile(path) or ""
        return ExecutorAPI.WriteFile(path, existing .. content)
    end
end

function ExecutorAPI.IsFile(path)
    if isfile then
        return isfile(path)
    end
    local success = pcall(function() readfile(path) end)
    return success
end

function ExecutorAPI.MakeFolder(path)
    if makefolder then
        pcall(function() makefolder(path) end)
    end
end

-- Instance operations
function ExecutorAPI.GetNilInstances()
    if getnilinstances then
        return getnilinstances()
    end
    return {}
end

function ExecutorAPI.GetScripts()
    if getscripts then
        return getscripts()
    end
    return {}
end

function ExecutorAPI.GetLoadedModules()
    if getloadedmodules then
        return getloadedmodules()
    end
    return {}
end

function ExecutorAPI.Decompile(script)
    if decompile then
        local success, result = pcall(decompile, script)
        if success then
            return result
        end
    end
    return "-- [BaoSaveInstance] Failed to decompile script"
end

function ExecutorAPI.GetHiddenProperty(instance, property)
    if gethiddenproperty then
        local success, value = pcall(gethiddenproperty, instance, property)
        if success then
            return value, true
        end
    end
    return nil, false
end

function ExecutorAPI.SetHiddenProperty(instance, property, value)
    if sethiddenproperty then
        pcall(sethiddenproperty, instance, property, value)
    end
end

function ExecutorAPI.GetProperties(instance)
    if getproperties then
        return getproperties(instance)
    end
    return {}
end

function ExecutorAPI.GetHiddenProperties(instance)
    if gethiddenproperties then
        return gethiddenproperties(instance)
    end
    return {}
end

function ExecutorAPI.IsScriptable(instance, property)
    if isscriptable then
        return isscriptable(instance, property)
    end
    return true
end

function ExecutorAPI.CloneRef(instance)
    if cloneref then
        return cloneref(instance)
    end
    return instance
end

function ExecutorAPI.GetRawMetatable(t)
    if getrawmetatable then
        return getrawmetatable(t)
    end
    return getmetatable(t)
end

-- Print executor info
local EXECUTOR_NAME = ExecutorAPI.GetExecutorName()

--[[ ═══════════════════════════════════════════════════════════════════════════
     UTILITY FUNCTIONS
═══════════════════════════════════════════════════════════════════════════ ]]--

local Utility = {}

-- Escape XML special characters
function Utility.EscapeXML(str)
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

-- Format number for XML
function Utility.FormatNumber(num)
    if num == math.huge then return "INF" end
    if num == -math.huge then return "-INF" end
    if num ~= num then return "NAN" end -- NaN check
    
    -- Check if integer
    if num == math.floor(num) and math.abs(num) < 2^31 then
        return string.format("%d", num)
    end
    
    return string.format("%.10g", num)
end

-- Deep clone table
function Utility.DeepClone(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = Utility.DeepClone(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Safe property access
function Utility.SafeGet(instance, property)
    local success, value = pcall(function()
        return instance[property]
    end)
    return success and value or nil
end

-- Log message
function Utility.Log(level, message)
    local prefix = "[BaoSaveInstance]"
    local timestamp = os.date("%H:%M:%S")
    
    if level == "INFO" then
        print(prefix, "[" .. timestamp .. "]", "ℹ️", message)
    elseif level == "WARN" then
        warn(prefix, "[" .. timestamp .. "]", "⚠️", message)
    elseif level == "ERROR" then
        warn(prefix, "[" .. timestamp .. "]", "❌", message)
    elseif level == "SUCCESS" then
        print(prefix, "[" .. timestamp .. "]", "✅", message)
    elseif level == "PROGRESS" then
        print(prefix, "[" .. timestamp .. "]", "⏳", message)
    end
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     PROPERTY SERIALIZER
═══════════════════════════════════════════════════════════════════════════ ]]--

local PropertySerializer = {}

-- Properties to exclude
PropertySerializer.ExcludedProperties = {
    "Parent", "ClassName", "Archivable", "DataCost", "RobloxLocked",
    "Mesh", "Head", "Face", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg",
}

-- Create lookup table for faster checking
PropertySerializer.ExcludedLookup = {}
for _, prop in ipairs(PropertySerializer.ExcludedProperties) do
    PropertySerializer.ExcludedLookup[prop] = true
end

-- Type serializers
PropertySerializer.TypeSerializers = {
    ["string"] = function(name, value)
        return string.format('<string name="%s">%s</string>', name, Utility.EscapeXML(value))
    end,
    
    ["boolean"] = function(name, value)
        return string.format('<bool name="%s">%s</bool>', name, value and "true" or "false")
    end,
    
    ["number"] = function(name, value)
        if value == math.floor(value) and math.abs(value) < 2^31 then
            return string.format('<int name="%s">%s</int>', name, Utility.FormatNumber(value))
        elseif value == math.floor(value) then
            return string.format('<int64 name="%s">%s</int64>', name, Utility.FormatNumber(value))
        else
            return string.format('<double name="%s">%s</double>', name, Utility.FormatNumber(value))
        end
    end,
    
    ["Color3"] = function(name, value)
        return string.format(
            '<Color3 name="%s"><R>%s</R><G>%s</G><B>%s</B></Color3>',
            name, Utility.FormatNumber(value.R), Utility.FormatNumber(value.G), Utility.FormatNumber(value.B)
        )
    end,
    
    ["Vector3"] = function(name, value)
        return string.format(
            '<Vector3 name="%s"><X>%s</X><Y>%s</Y><Z>%s</Z></Vector3>',
            name, Utility.FormatNumber(value.X), Utility.FormatNumber(value.Y), Utility.FormatNumber(value.Z)
        )
    end,
    
    ["Vector2"] = function(name, value)
        return string.format(
            '<Vector2 name="%s"><X>%s</X><Y>%s</Y></Vector2>',
            name, Utility.FormatNumber(value.X), Utility.FormatNumber(value.Y)
        )
    end,
    
    ["CFrame"] = function(name, value)
        local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()
        return string.format(
            '<CoordinateFrame name="%s"><X>%s</X><Y>%s</Y><Z>%s</Z><R00>%s</R00><R01>%s</R01><R02>%s</R02><R10>%s</R10><R11>%s</R11><R12>%s</R12><R20>%s</R20><R21>%s</R21><R22>%s</R22></CoordinateFrame>',
            name,
            Utility.FormatNumber(x), Utility.FormatNumber(y), Utility.FormatNumber(z),
            Utility.FormatNumber(r00), Utility.FormatNumber(r01), Utility.FormatNumber(r02),
            Utility.FormatNumber(r10), Utility.FormatNumber(r11), Utility.FormatNumber(r12),
            Utility.FormatNumber(r20), Utility.FormatNumber(r21), Utility.FormatNumber(r22)
        )
    end,
    
    ["UDim"] = function(name, value)
        return string.format(
            '<UDim name="%s"><S>%s</S><O>%d</O></UDim>',
            name, Utility.FormatNumber(value.Scale), value.Offset
        )
    end,
    
    ["UDim2"] = function(name, value)
        return string.format(
            '<UDim2 name="%s"><XS>%s</XS><XO>%d</XO><YS>%s</YS><YO>%d</YO></UDim2>',
            name,
            Utility.FormatNumber(value.X.Scale), value.X.Offset,
            Utility.FormatNumber(value.Y.Scale), value.Y.Offset
        )
    end,
    
    ["BrickColor"] = function(name, value)
        return string.format('<int name="%s">%d</int>', name, value.Number)
    end,
    
    ["EnumItem"] = function(name, value)
        return string.format('<token name="%s">%d</token>', name, value.Value)
    end,
    
    ["NumberSequence"] = function(name, value)
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%s %s %s", 
                Utility.FormatNumber(kp.Time), 
                Utility.FormatNumber(kp.Value), 
                Utility.FormatNumber(kp.Envelope)
            ))
        end
        return string.format('<NumberSequence name="%s">%s</NumberSequence>', name, table.concat(keypoints, " "))
    end,
    
    ["ColorSequence"] = function(name, value)
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%s %s %s %s 0", 
                Utility.FormatNumber(kp.Time),
                Utility.FormatNumber(kp.Value.R),
                Utility.FormatNumber(kp.Value.G),
                Utility.FormatNumber(kp.Value.B)
            ))
        end
        return string.format('<ColorSequence name="%s">%s</ColorSequence>', name, table.concat(keypoints, " "))
    end,
    
    ["NumberRange"] = function(name, value)
        return string.format('<NumberRange name="%s">%s %s</NumberRange>', 
            name, Utility.FormatNumber(value.Min), Utility.FormatNumber(value.Max)
        )
    end,
    
    ["Rect"] = function(name, value)
        return string.format(
            '<Rect name="%s"><min><X>%s</X><Y>%s</Y></min><max><X>%s</X><Y>%s</Y></max></Rect>',
            name,
            Utility.FormatNumber(value.Min.X), Utility.FormatNumber(value.Min.Y),
            Utility.FormatNumber(value.Max.X), Utility.FormatNumber(value.Max.Y)
        )
    end,
    
    ["PhysicalProperties"] = function(name, value)
        if value then
            return string.format(
                '<PhysicalProperties name="%s"><CustomPhysics>true</CustomPhysics><Density>%s</Density><Friction>%s</Friction><Elasticity>%s</Elasticity><FrictionWeight>%s</FrictionWeight><ElasticityWeight>%s</ElasticityWeight></PhysicalProperties>',
                name,
                Utility.FormatNumber(value.Density),
                Utility.FormatNumber(value.Friction),
                Utility.FormatNumber(value.Elasticity),
                Utility.FormatNumber(value.FrictionWeight),
                Utility.FormatNumber(value.ElasticityWeight)
            )
        else
            return string.format('<PhysicalProperties name="%s"><CustomPhysics>false</CustomPhysics></PhysicalProperties>', name)
        end
    end,
    
    ["Faces"] = function(name, value)
        local bits = 0
        if value.Top then bits = bits + 1 end
        if value.Bottom then bits = bits + 2 end
        if value.Left then bits = bits + 4 end
        if value.Right then bits = bits + 8 end
        if value.Back then bits = bits + 16 end
        if value.Front then bits = bits + 32 end
        return string.format('<Faces name="%s">%d</Faces>', name, bits)
    end,
    
    ["Axes"] = function(name, value)
        local bits = 0
        if value.X then bits = bits + 1 end
        if value.Y then bits = bits + 2 end
        if value.Z then bits = bits + 4 end
        return string.format('<Axes name="%s">%d</Axes>', name, bits)
    end,
    
    ["Ray"] = function(name, value)
        return string.format(
            '<Ray name="%s"><origin><X>%s</X><Y>%s</Y><Z>%s</Z></origin><direction><X>%s</X><Y>%s</Y><Z>%s</Z></direction></Ray>',
            name,
            Utility.FormatNumber(value.Origin.X), Utility.FormatNumber(value.Origin.Y), Utility.FormatNumber(value.Origin.Z),
            Utility.FormatNumber(value.Direction.X), Utility.FormatNumber(value.Direction.Y), Utility.FormatNumber(value.Direction.Z)
        )
    end,
    
    ["Font"] = function(name, value)
        return string.format(
            '<Font name="%s"><Family><url>%s</url></Family><Weight>%d</Weight><Style>%s</Style></Font>',
            name, Utility.EscapeXML(value.Family), value.Weight.Value, value.Style.Name
        )
    end,
    
    ["Content"] = function(name, value)
        return string.format('<Content name="%s"><url>%s</url></Content>', name, Utility.EscapeXML(tostring(value)))
    end,
}

-- Class property definitions
PropertySerializer.ClassProperties = {
    -- Base properties (inherited)
    Instance = {"Name", "Archivable"},
    
    -- Parts
    BasePart = {
        "Anchored", "BrickColor", "CFrame", "CanCollide", "CanTouch", "CanQuery",
        "CastShadow", "Color", "CustomPhysicalProperties", "Locked", "Massless",
        "Material", "MaterialVariant", "PivotOffset", "Reflectance", "RootPriority",
        "Size", "Transparency", "CollisionGroup"
    },
    Part = {"Shape"},
    WedgePart = {},
    CornerWedgePart = {},
    TrussPart = {"Style"},
    SpawnLocation = {"AllowTeamChangeOnTouch", "Duration", "Enabled", "Neutral", "TeamColor"},
    Seat = {"Disabled"},
    VehicleSeat = {"Disabled", "HeadsUpDisplay", "MaxSpeed", "Steer", "SteerFloat", "Throttle", "ThrottleFloat", "Torque", "TurnSpeed"},
    
    -- Mesh Parts
    MeshPart = {"MeshId", "TextureID", "CollisionFidelity", "RenderFidelity", "DoubleSided"},
    UnionOperation = {"CollisionFidelity", "RenderFidelity", "SmoothingAngle", "UsePartColor"},
    NegateOperation = {"CollisionFidelity", "RenderFidelity", "SmoothingAngle", "UsePartColor"},
    
    -- Models
    Model = {"LevelOfDetail", "ModelStreamingMode", "PrimaryPart", "WorldPivot"},
    Tool = {"CanBeDropped", "Enabled", "Grip", "ManualActivationOnly", "RequiresHandle", "ToolTip"},
    
    -- Scripts
    BaseScript = {"Disabled"},
    Script = {"Source", "RunContext"},
    LocalScript = {"Source"},
    ModuleScript = {"Source"},
    
    -- Meshes
    DataModelMesh = {"Offset", "Scale", "VertexColor"},
    FileMesh = {"MeshId", "TextureId"},
    SpecialMesh = {"MeshType"},
    BlockMesh = {},
    CylinderMesh = {},
    
    -- Decals & Textures
    Decal = {"Color3", "Face", "Texture", "Transparency", "ZIndex"},
    Texture = {"Face", "OffsetStudsU", "OffsetStudsV", "StudsPerTileU", "StudsPerTileV", "Texture", "Transparency", "ZIndex"},
    SurfaceAppearance = {"AlphaMode", "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap", "TexturePack"},
    
    -- Lights
    Light = {"Brightness", "Color", "Enabled", "Shadows"},
    PointLight = {"Range"},
    SpotLight = {"Angle", "Face", "Range"},
    SurfaceLight = {"Angle", "Face", "Range"},
    
    -- Effects
    Fire = {"Color", "Enabled", "Heat", "SecondaryColor", "Size", "TimeScale"},
    Smoke = {"Color", "Enabled", "Opacity", "RiseVelocity", "Size", "TimeScale"},
    Sparkles = {"Color", "Enabled", "SparkleColor", "TimeScale"},
    ParticleEmitter = {
        "Acceleration", "Brightness", "Color", "Drag", "EmissionDirection", "Enabled",
        "FlipbookFramerate", "FlipbookLayout", "FlipbookMode", "FlipbookStartRandom",
        "Lifetime", "LightEmission", "LightInfluence", "LockedToPart", "Orientation",
        "Rate", "RotSpeed", "Rotation", "Shape", "ShapeInOut", "ShapePartial",
        "ShapeStyle", "Size", "Speed", "SpreadAngle", "Squash", "Texture", "TimeScale",
        "Transparency", "VelocityInheritance", "WindAffectsDrag", "ZOffset"
    },
    Beam = {
        "Attachment0", "Attachment1", "Brightness", "Color", "CurveSize0", "CurveSize1",
        "Enabled", "FaceCamera", "LightEmission", "LightInfluence", "Segments", "Texture",
        "TextureLength", "TextureMode", "TextureSpeed", "Transparency", "Width0", "Width1", "ZOffset"
    },
    Trail = {
        "Attachment0", "Attachment1", "Brightness", "Color", "Enabled", "FaceCamera",
        "Lifetime", "LightEmission", "LightInfluence", "MaxLength", "MinLength",
        "Texture", "TextureLength", "TextureMode", "Transparency", "WidthScale"
    },
    
    -- Attachments & Constraints
    Attachment = {"Axis", "CFrame", "Orientation", "Position", "SecondaryAxis", "Visible"},
    Bone = {"Transform"},
    
    -- Joints
    JointInstance = {"C0", "C1", "Enabled", "Part0", "Part1"},
    Weld = {},
    Motor6D = {"CurrentAngle", "DesiredAngle", "MaxVelocity", "Transform"},
    WeldConstraint = {"Enabled", "Part0", "Part1"},
    
    -- Constraints
    Constraint = {"Attachment0", "Attachment1", "Color", "Enabled", "Visible"},
    BallSocketConstraint = {"LimitsEnabled", "MaxFrictionTorque", "Radius", "Restitution", "TwistLimitsEnabled", "TwistLowerAngle", "TwistUpperAngle", "UpperAngle"},
    HingeConstraint = {"ActuatorType", "AngularResponsiveness", "AngularSpeed", "AngularVelocity", "LimitsEnabled", "LowerAngle", "MotorMaxAcceleration", "MotorMaxTorque", "Radius", "Restitution", "ServoMaxTorque", "TargetAngle", "UpperAngle"},
    RopeConstraint = {"Length", "Restitution", "Thickness", "WinchEnabled", "WinchForce", "WinchResponsiveness", "WinchSpeed", "WinchTarget"},
    SpringConstraint = {"Coils", "Damping", "FreeLength", "LimitsEnabled", "MaxForce", "MaxLength", "MinLength", "Radius", "Stiffness", "Thickness"},
    RodConstraint = {"Length", "LimitAngle0", "LimitAngle1", "LimitsEnabled", "Thickness"},
    PrismaticConstraint = {"ActuatorType", "LimitsEnabled", "LowerLimit", "MotorMaxAcceleration", "MotorMaxForce", "Restitution", "ServoMaxForce", "Size", "Speed", "TargetPosition", "UpperLimit", "Velocity"},
    CylindricalConstraint = {"AngularActuatorType", "AngularLimitsEnabled", "AngularRestitution", "AngularResponsiveness", "AngularSpeed", "AngularVelocity", "InclinationAngle", "LimitsEnabled", "LowerAngle", "LowerLimit", "MotorMaxAngularAcceleration", "MotorMaxForce", "MotorMaxTorque", "Restitution", "RotationAxisVisible", "ServoMaxForce", "ServoMaxTorque", "Size", "Speed", "TargetAngle", "TargetPosition", "UpperAngle", "UpperLimit", "Velocity"},
    
    -- Values
    BoolValue = {"Value"},
    IntValue = {"Value"},
    NumberValue = {"Value"},
    StringValue = {"Value"},
    ObjectValue = {"Value"},
    Color3Value = {"Value"},
    Vector3Value = {"Value"},
    CFrameValue = {"Value"},
    BrickColorValue = {"Value"},
    RayValue = {"Value"},
    
    -- GUI
    LayerCollector = {"Enabled", "ResetOnSpawn", "ZIndexBehavior"},
    ScreenGui = {"DisplayOrder", "IgnoreGuiInset"},
    BillboardGui = {"Active", "Adornee", "AlwaysOnTop", "Brightness", "ClipsDescendants", "DistanceLowerLimit", "DistanceStep", "DistanceUpperLimit", "ExtentsOffset", "ExtentsOffsetWorldSpace", "LightInfluence", "MaxDistance", "PlayerToHideFrom", "Size", "SizeOffset", "StudsOffset", "StudsOffsetWorldSpace"},
    SurfaceGui = {"Active", "Adornee", "AlwaysOnTop", "Brightness", "CanvasSize", "ClipsDescendants", "Face", "LightInfluence", "MaxDistance", "PixelsPerStud", "SizingMode", "ToolPunchThroughDistance", "ZOffset"},
    
    GuiObject = {
        "Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency",
        "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "Interactable",
        "LayoutOrder", "Position", "Rotation", "Selectable", "SelectionGroup", "Size",
        "SizeConstraint", "Visible", "ZIndex"
    },
    Frame = {},
    ViewportFrame = {"Ambient", "CurrentCamera", "ImageColor3", "ImageTransparency", "LightColor", "LightDirection"},
    ScrollingFrame = {"AutomaticCanvasSize", "BottomImage", "CanvasPosition", "CanvasSize", "ElasticBehavior", "HorizontalScrollBarInset", "MidImage", "ScrollBarImageColor3", "ScrollBarImageTransparency", "ScrollBarThickness", "ScrollingDirection", "ScrollingEnabled", "TopImage", "VerticalScrollBarInset", "VerticalScrollBarPosition"},
    
    GuiLabel = {"ContentText", "Font", "FontFace", "LineHeight", "MaxVisibleGraphemes", "RichText", "Text", "TextColor3", "TextScaled", "TextSize", "TextStrokeColor3", "TextStrokeTransparency", "TextTransparency", "TextTruncate", "TextWrapped", "TextXAlignment", "TextYAlignment"},
    TextLabel = {},
    TextButton = {"AutoButtonColor", "Modal", "Selected", "Style"},
    TextBox = {"ClearTextOnFocus", "CursorPosition", "MultiLine", "PlaceholderColor3", "PlaceholderText", "SelectionStart", "ShowNativeInput", "TextEditable"},
    
    ImageLabel = {"Image", "ImageColor3", "ImageRectOffset", "ImageRectSize", "ImageTransparency", "ResampleMode", "ScaleType", "SliceCenter", "SliceScale", "TileSize"},
    ImageButton = {"AutoButtonColor", "HoverImage", "Image", "ImageColor3", "ImageRectOffset", "ImageRectSize", "ImageTransparency", "Modal", "PressedImage", "ResampleMode", "ScaleType", "Selected", "SliceCenter", "SliceScale", "Style", "TileSize"},
    
    -- UI Layouts
    UIListLayout = {"FillDirection", "HorizontalAlignment", "Padding", "SortOrder", "VerticalAlignment", "Wraps"},
    UIGridLayout = {"CellPadding", "CellSize", "FillDirection", "FillDirectionMaxCells", "HorizontalAlignment", "SortOrder", "StartCorner", "VerticalAlignment"},
    UITableLayout = {"FillDirection", "FillEmptySpaceColumns", "FillEmptySpaceRows", "HorizontalAlignment", "MajorAxis", "Padding", "SortOrder", "VerticalAlignment"},
    UIPageLayout = {"Animated", "Circular", "EasingDirection", "EasingStyle", "FillDirection", "GamepadInputEnabled", "HorizontalAlignment", "Padding", "ScrollWheelInputEnabled", "SortOrder", "TouchInputEnabled", "TweenTime", "VerticalAlignment"},
    
    UIPadding = {"PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"},
    UIScale = {"Scale"},
    UIAspectRatioConstraint = {"AspectRatio", "AspectType", "DominantAxis"},
    UISizeConstraint = {"MaxSize", "MinSize"},
    UITextSizeConstraint = {"MaxTextSize", "MinTextSize"},
    UICorner = {"CornerRadius"},
    UIStroke = {"ApplyStrokeMode", "Color", "Enabled", "LineJoinMode", "Thickness", "Transparency"},
    UIGradient = {"Color", "Enabled", "Offset", "Rotation", "Transparency"},
    
    -- Sounds
    Sound = {"EmitterSize", "LoopRegion", "Looped", "PlayOnRemove", "PlaybackRegion", "PlaybackRegionsEnabled", "PlaybackSpeed", "Playing", "RollOffMaxDistance", "RollOffMinDistance", "RollOffMode", "SoundGroup", "SoundId", "TimePosition", "Volume"},
    SoundGroup = {"Volume"},
    
    -- Humanoid
    Humanoid = {"AutoJumpEnabled", "AutoRotate", "AutomaticScalingEnabled", "BreakJointsOnDeath", "CameraOffset", "DisplayDistanceType", "DisplayName", "EvaluateStateMachine", "Health", "HealthDisplayDistance", "HealthDisplayType", "HipHeight", "JumpHeight", "JumpPower", "MaxHealth", "MaxSlopeAngle", "NameDisplayDistance", "NameOcclusion", "RequiresNeck", "RigType", "UseJumpPower", "WalkSpeed"},
    HumanoidDescription = {"BackAccessory", "BodyTypeScale", "ClimbAnimation", "DepthScale", "Face", "FaceAccessory", "FallAnimation", "FrontAccessory", "GraphicTShirt", "HairAccessory", "HatAccessory", "Head", "HeadColor", "HeadScale", "HeightScale", "IdleAnimation", "JumpAnimation", "LeftArm", "LeftArmColor", "LeftLeg", "LeftLegColor", "MoodAnimation", "NeckAccessory", "Pants", "ProportionScale", "RightArm", "RightArmColor", "RightLeg", "RightLegColor", "RunAnimation", "Shirt", "ShouldersAccessory", "SwimAnimation", "Torso", "TorsoColor", "WaistAccessory", "WalkAnimation", "WidthScale"},
    
    -- Services/Containers
    Folder = {},
    Configuration = {},
    Camera = {"CameraSubject", "CameraType", "DiagonalFieldOfView", "FieldOfView", "FieldOfViewMode", "Focus", "HeadLocked", "HeadScale", "MaxAxisFieldOfView", "VRTiltAndRollEnabled"},
    
    -- Lighting
    Lighting = {"Ambient", "Brightness", "ColorShift_Bottom", "ColorShift_Top", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ExposureCompensation", "FogColor", "FogEnd", "FogStart", "GeographicLatitude", "GlobalShadows", "OutdoorAmbient", "ShadowSoftness", "Technology", "TimeOfDay"},
    Sky = {"CelestialBodiesShown", "MoonAngularSize", "MoonTextureId", "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "StarCount", "SunAngularSize", "SunTextureId"},
    Atmosphere = {"Color", "Decay", "Density", "Glare", "Haze", "Offset"},
    Clouds = {"Color", "Cover", "Density", "Enabled"},
    BloomEffect = {"Enabled", "Intensity", "Size", "Threshold"},
    BlurEffect = {"Enabled", "Size"},
    ColorCorrectionEffect = {"Brightness", "Contrast", "Enabled", "Saturation", "TintColor"},
    DepthOfFieldEffect = {"Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"},
    SunRaysEffect = {"Enabled", "Intensity", "Spread"},
    
    -- Terrain
    Terrain = {"Decoration", "GrassLength", "MaterialColors", "WaterColor", "WaterReflectance", "WaterTransparency", "WaterWaveSize", "WaterWaveSpeed"},
}

-- Get all properties for an instance
function PropertySerializer.GetPropertiesForClass(className)
    local properties = {}
    local visited = {}
    
    local function addProperties(class)
        if visited[class] then return end
        visited[class] = true
        
        local props = PropertySerializer.ClassProperties[class]
        if props then
            for _, prop in ipairs(props) do
                if not PropertySerializer.ExcludedLookup[prop] then
                    table.insert(properties, prop)
                end
            end
        end
    end
    
    -- Add instance base properties
    addProperties("Instance")
    addProperties(className)
    
    -- Add parent class properties (simplified inheritance)
    local inheritanceMap = {
        Part = {"BasePart"},
        WedgePart = {"BasePart"},
        CornerWedgePart = {"BasePart"},
        TrussPart = {"BasePart"},
        SpawnLocation = {"BasePart"},
        Seat = {"BasePart"},
        VehicleSeat = {"BasePart", "Seat"},
        MeshPart = {"BasePart"},
        UnionOperation = {"BasePart"},
        NegateOperation = {"BasePart"},
        Script = {"BaseScript"},
        LocalScript = {"BaseScript"},
        SpecialMesh = {"DataModelMesh", "FileMesh"},
        BlockMesh = {"DataModelMesh"},
        CylinderMesh = {"DataModelMesh"},
        FileMesh = {"DataModelMesh"},
        PointLight = {"Light"},
        SpotLight = {"Light"},
        SurfaceLight = {"Light"},
        Weld = {"JointInstance"},
        Motor6D = {"JointInstance"},
        Frame = {"GuiObject"},
        ViewportFrame = {"GuiObject"},
        ScrollingFrame = {"GuiObject"},
        TextLabel = {"GuiObject", "GuiLabel"},
        TextButton = {"GuiObject", "GuiLabel"},
        TextBox = {"GuiObject", "GuiLabel"},
        ImageLabel = {"GuiObject"},
        ImageButton = {"GuiObject", "ImageLabel"},
        ScreenGui = {"LayerCollector"},
        BillboardGui = {"LayerCollector"},
        SurfaceGui = {"LayerCollector"},
        BallSocketConstraint = {"Constraint"},
        HingeConstraint = {"Constraint"},
        RopeConstraint = {"Constraint"},
        SpringConstraint = {"Constraint"},
        RodConstraint = {"Constraint"},
        PrismaticConstraint = {"Constraint"},
        CylindricalConstraint = {"Constraint"},
    }
    
    local parents = inheritanceMap[className]
    if parents then
        for _, parent in ipairs(parents) do
            addProperties(parent)
        end
    end
    
    return properties
end

-- Serialize a property value
function PropertySerializer.SerializeValue(name, value)
    if value == nil then return nil end
    
    local valueType = typeof(value)
    local serializer = PropertySerializer.TypeSerializers[valueType]
    
    if serializer then
        local success, result = pcall(serializer, name, value)
        if success then
            return result
        end
    end
    
    -- Handle Instance references (will be processed separately)
    if valueType == "Instance" then
        return nil -- Handled by reference system
    end
    
    return nil
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     TERRAIN SERIALIZER
═══════════════════════════════════════════════════════════════════════════ ]]--

local TerrainSerializer = {}

-- Material enum mapping
TerrainSerializer.MaterialMap = {
    [Enum.Material.Air] = 0,
    [Enum.Material.Water] = 1,
    [Enum.Material.Grass] = 2,
    [Enum.Material.Slate] = 3,
    [Enum.Material.Concrete] = 4,
    [Enum.Material.Brick] = 5,
    [Enum.Material.Sand] = 6,
    [Enum.Material.WoodPlanks] = 7,
    [Enum.Material.Rock] = 8,
    [Enum.Material.Glacier] = 9,
    [Enum.Material.Snow] = 10,
    [Enum.Material.Sandstone] = 11,
    [Enum.Material.Mud] = 12,
    [Enum.Material.Basalt] = 13,
    [Enum.Material.Ground] = 14,
    [Enum.Material.CrackedLava] = 15,
    [Enum.Material.Asphalt] = 16,
    [Enum.Material.Cobblestone] = 17,
    [Enum.Material.Ice] = 18,
    [Enum.Material.LeafyGrass] = 19,
    [Enum.Material.Salt] = 20,
    [Enum.Material.Limestone] = 21,
    [Enum.Material.Pavement] = 22,
}

-- Get terrain region bounds
function TerrainSerializer.GetTerrainBounds()
    local terrain = Workspace.Terrain
    
    -- Try to read a large region to find actual bounds
    local maxSize = 512
    local regionSize = 4
    
    local minBound = Vector3.new(math.huge, math.huge, math.huge)
    local maxBound = Vector3.new(-math.huge, -math.huge, -math.huge)
    
    local hasContent = false
    
    -- Sample the terrain to find occupied regions
    local step = 64
    for x = -maxSize, maxSize, step do
        for y = -maxSize, maxSize, step do
            for z = -maxSize, maxSize, step do
                local region = Region3.new(
                    Vector3.new(x, y, z),
                    Vector3.new(x + step, y + step, z + step)
                ):ExpandToGrid(4)
                
                local success, materials, occupancy = pcall(function()
                    return terrain:ReadVoxels(region, 4)
                end)
                
                if success and materials then
                    local size = materials.Size
                    for i = 1, size.X do
                        for j = 1, size.Y do
                            for k = 1, size.Z do
                                if materials[i][j][k] ~= Enum.Material.Air and occupancy[i][j][k] > 0 then
                                    hasContent = true
                                    minBound = Vector3.new(
                                        math.min(minBound.X, x),
                                        math.min(minBound.Y, y),
                                        math.min(minBound.Z, z)
                                    )
                                    maxBound = Vector3.new(
                                        math.max(maxBound.X, x + step),
                                        math.max(maxBound.Y, y + step),
                                        math.max(maxBound.Z, z + step)
                                    )
                                end
                            end
                        end
                    end
                end
            end
            task.wait()
        end
    end
    
    if not hasContent then
        return nil, nil
    end
    
    return minBound, maxBound
end

-- Serialize terrain to XML
function TerrainSerializer.SerializeTerrainItem()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return nil
    end
    
    Utility.Log("PROGRESS", "Serializing Terrain...")
    
    local xml = {}
    table.insert(xml, '    <Item class="Terrain" referent="RBXTERRAIN">')
    table.insert(xml, '      <Properties>')
    table.insert(xml, '        <string name="Name">Terrain</string>')
    
    -- Terrain properties
    local terrainProps = {
        {"bool", "Decoration", terrain.Decoration},
        {"float", "GrassLength", terrain.GrassLength},
    }
    
    -- Water properties
    pcall(function()
        table.insert(terrainProps, {"Color3", "WaterColor", terrain.WaterColor})
        table.insert(terrainProps, {"float", "WaterReflectance", terrain.WaterReflectance})
        table.insert(terrainProps, {"float", "WaterTransparency", terrain.WaterTransparency})
        table.insert(terrainProps, {"float", "WaterWaveSize", terrain.WaterWaveSize})
        table.insert(terrainProps, {"float", "WaterWaveSpeed", terrain.WaterWaveSpeed})
    end)
    
    for _, prop in ipairs(terrainProps) do
        local propType, propName, propValue = prop[1], prop[2], prop[3]
        if propValue ~= nil then
            local serialized = PropertySerializer.SerializeValue(propName, propValue)
            if serialized then
                table.insert(xml, '        ' .. serialized)
            end
        end
    end
    
    table.insert(xml, '      </Properties>')
    table.insert(xml, '    </Item>')
    
    Utility.Log("SUCCESS", "Terrain serialized!")
    
    return table.concat(xml, "\n")
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     INSTANCE SERIALIZER
═══════════════════════════════════════════════════════════════════════════ ]]--

local InstanceSerializer = {}

-- Reference tracking
InstanceSerializer.ReferenceCounter = 0
InstanceSerializer.InstanceToRef = {}
InstanceSerializer.RefToInstance = {}
InstanceSerializer.ProcessedCount = 0

-- Reset serializer state
function InstanceSerializer.Reset()
    InstanceSerializer.ReferenceCounter = 0
    InstanceSerializer.InstanceToRef = {}
    InstanceSerializer.RefToInstance = {}
    InstanceSerializer.ProcessedCount = 0
end

-- Get or create reference ID
function InstanceSerializer.GetReferenceId(instance)
    if InstanceSerializer.InstanceToRef[instance] then
        return InstanceSerializer.InstanceToRef[instance]
    end
    
    InstanceSerializer.ReferenceCounter = InstanceSerializer.ReferenceCounter + 1
    local refId = "RBX" .. tostring(InstanceSerializer.ReferenceCounter)
    
    InstanceSerializer.InstanceToRef[instance] = refId
    InstanceSerializer.RefToInstance[refId] = instance
    
    return refId
end

-- Check if instance should be saved
function InstanceSerializer.ShouldSaveInstance(instance)
    if not instance then return false end
    
    -- Skip player characters if configured
    if BaoSaveInstance.Config.IgnorePlayerCharacters then
        for _, player in ipairs(Players:GetPlayers()) do
            if instance == player.Character or instance:IsDescendantOf(player.Character or Instance.new("Folder")) then
                return false
            end
        end
    end
    
    -- Skip certain classes
    local skipClasses = {
        "Player", "PlayerScripts", "PlayerGui", "Backpack", "StarterGear",
    }
    
    for _, class in ipairs(skipClasses) do
        if instance.ClassName == class then
            return false
        end
    end
    
    return true
end

-- Serialize an instance and its children
function InstanceSerializer.SerializeInstance(instance, indent, includeScripts, statusCallback)
    if not InstanceSerializer.ShouldSaveInstance(instance) then
        return nil
    end
    
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    
    local className = instance.ClassName
    local refId = InstanceSerializer.GetReferenceId(instance)
    
    -- Start building XML
    local xml = {}
    table.insert(xml, string.format('%s<Item class="%s" referent="%s">', indentStr, className, refId))
    table.insert(xml, indentStr .. '  <Properties>')
    
    -- Always add Name property
    table.insert(xml, string.format('%s    <string name="Name">%s</string>', indentStr, Utility.EscapeXML(instance.Name)))
    
    -- Get and serialize properties
    local propertyNames = PropertySerializer.GetPropertiesForClass(className)
    
    for _, propName in ipairs(propertyNames) do
        if propName ~= "Name" then
            local success, value = pcall(function()
                return instance[propName]
            end)
            
            if success and value ~= nil then
                -- Handle Script Source specially
                if propName == "Source" and (instance:IsA("BaseScript") or instance:IsA("ModuleScript")) then
                    if includeScripts and BaoSaveInstance.Config.DecompileScripts then
                        local source = ExecutorAPI.Decompile(instance)
                        table.insert(xml, string.format('%s    <ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>', indentStr, source))
                    end
                else
                    local serialized = PropertySerializer.SerializeValue(propName, value)
                    if serialized then
                        table.insert(xml, indentStr .. '    ' .. serialized)
                    end
                end
            end
        end
    end
    
    table.insert(xml, indentStr .. '  </Properties>')
    
    -- Serialize children
    local children = instance:GetChildren()
    for i, child in ipairs(children) do
        local childXml = InstanceSerializer.SerializeInstance(child, indent + 1, includeScripts, statusCallback)
        if childXml then
            table.insert(xml, childXml)
        end
        
        -- Progress update and yield
        InstanceSerializer.ProcessedCount = InstanceSerializer.ProcessedCount + 1
        if InstanceSerializer.ProcessedCount % BaoSaveInstance.Config.YieldInterval == 0 then
            if statusCallback then
                statusCallback("Processing: " .. InstanceSerializer.ProcessedCount .. " instances...")
            end
            task.wait()
        end
    end
    
    table.insert(xml, indentStr .. '</Item>')
    
    return table.concat(xml, "\n")
end

-- Serialize multiple instances as a model
function InstanceSerializer.SerializeAsModel(instances, includeScripts, statusCallback)
    InstanceSerializer.Reset()
    
    local xml = {
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">',
        '  <Meta name="ExplicitAutoJoints">true</Meta>',
    }
    
    for _, instance in ipairs(instances) do
        local instanceXml = InstanceSerializer.SerializeInstance(instance, 1, includeScripts, statusCallback)
        if instanceXml then
            table.insert(xml, instanceXml)
        end
    end
    
    table.insert(xml, '</roblox>')
    
    return table.concat(xml, "\n")
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     SAVE FUNCTIONS
═══════════════════════════════════════════════════════════════════════════ ]]--

-- Generate filename
local function GenerateFileName(suffix)
    local gameId = game.PlaceId
    local gameName = game:GetService("MarketplaceService"):GetProductInfo(gameId).Name or "Game"
    gameName = gameName:gsub("[^%w%s]", ""):gsub("%s+", "_"):sub(1, 30)
    
    local timestamp = os.date("%Y%m%d_%H%M%S")
    
    return string.format("%s_%d_%s_%s", gameName, gameId, suffix, timestamp)
end

-- Save Game (Full)
function BaoSaveInstance.SaveGame(fileName, statusCallback)
    fileName = fileName or GenerateFileName("FullGame")
    local fullPath = fileName .. ".rbxl"
    
    Utility.Log("INFO", "═══════════════════════════════════════════════")
    Utility.Log("INFO", "BaoSaveInstance - SAVE GAME")
    Utility.Log("INFO", "═══════════════════════════════════════════════")
    Utility.Log("INFO", "Output file: " .. fullPath)
    Utility.Log("INFO", "Executor: " .. EXECUTOR_NAME)
    
    BaoSaveInstance.Stats.StartTime = os.clock()
    InstanceSerializer.Reset()
    
    -- Start XML
    local xml = {
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">',
        '  <Meta name="ExplicitAutoJoints">true</Meta>',
    }
    
    -- Step 1: Save Workspace (includes Terrain and Models)
    Utility.Log("PROGRESS", "Step 1/4: Saving Workspace...")
    if statusCallback then statusCallback("Saving Workspace...") end
    
    table.insert(xml, '  <Item class="Workspace" referent="RBXWORKSPACE">')
    table.insert(xml, '    <Properties>')
    table.insert(xml, '      <string name="Name">Workspace</string>')
    table.insert(xml, '    </Properties>')
    
    -- Add Terrain
    local terrainXml = TerrainSerializer.SerializeTerrainItem()
    if terrainXml then
        table.insert(xml, terrainXml)
    end
    
    -- Add all Workspace children (except Terrain, Camera, Players)
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.ClassName ~= "Terrain" and child.ClassName ~= "Camera" and not child:IsA("Player") then
            local childXml = InstanceSerializer.SerializeInstance(child, 2, true, statusCallback)
            if childXml then
                table.insert(xml, childXml)
            end
        end
    end
    
    table.insert(xml, '  </Item>')
    Utility.Log("SUCCESS", "Workspace saved!")
    
    -- Step 2: Save Lighting
    Utility.Log("PROGRESS", "Step 2/4: Saving Lighting...")
    if statusCallback then statusCallback("Saving Lighting...") end
    
    local lightingXml = InstanceSerializer.SerializeInstance(Lighting, 1, true, statusCallback)
    if lightingXml then
        table.insert(xml, lightingXml)
    end
    Utility.Log("SUCCESS", "Lighting saved!")
    
    -- Step 3: Save ReplicatedStorage & Other Services
    Utility.Log("PROGRESS", "Step 3/4: Saving ReplicatedStorage & Services...")
    if statusCallback then statusCallback("Saving Services...") end
    
    local servicesToSave = {
        ReplicatedStorage,
        ReplicatedFirst,
        StarterGui,
        StarterPack,
        StarterPlayer,
        SoundService,
        Teams,
    }
    
    for _, service in ipairs(servicesToSave) do
        local success, result = pcall(function()
            return InstanceSerializer.SerializeInstance(service, 1, true, statusCallback)
        end)
        if success and result then
            table.insert(xml, result)
        end
    end
    Utility.Log("SUCCESS", "Services saved!")
    
    -- Step 4: Save Nil Instances
    if BaoSaveInstance.Config.SaveNilInstances then
        Utility.Log("PROGRESS", "Step 4/4: Saving Nil Instances...")
        if statusCallback then statusCallback("Saving Nil Instances...") end
        
        local nilInstances = ExecutorAPI.GetNilInstances()
        if #nilInstances > 0 then
            table.insert(xml, '  <Item class="Folder" referent="RBXNILINSTANCES">')
            table.insert(xml, '    <Properties>')
            table.insert(xml, '      <string name="Name">NilInstances</string>')
            table.insert(xml, '    </Properties>')
            
            for _, nilInstance in ipairs(nilInstances) do
                local nilXml = InstanceSerializer.SerializeInstance(nilInstance, 2, true, statusCallback)
                if nilXml then
                    table.insert(xml, nilXml)
                end
            end
            
            table.insert(xml, '  </Item>')
        end
        Utility.Log("SUCCESS", "Nil Instances saved!")
    end
    
    -- Close XML
    table.insert(xml, '</roblox>')
    
    -- Write file
    Utility.Log("PROGRESS", "Writing file...")
    if statusCallback then statusCallback("Writing file...") end
    
    local finalContent = table.concat(xml, "\n")
    
    local writeSuccess, writeError = pcall(function()
        ExecutorAPI.WriteFile(fullPath, finalContent)
    end)
    
    BaoSaveInstance.Stats.EndTime = os.clock()
    
