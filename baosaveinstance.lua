--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                         BaoSaveInstance v1.0.0                               ║
║          Advanced Roblox Game Saving System - Exploit Side                   ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Supported Clients: Synapse X, Delta, Xeno, Solara, TNG                     ║
║  Features: Full Instance Tree, Terrain Voxels, Script Decompilation          ║
║  Output: .rbxlx, Lua Reconstruction, Metadata Report                         ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

--// Services
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local SoundService = game:GetService("SoundService")
local Chat = game:GetService("Chat")
local LocalizationService = game:GetService("LocalizationService")
local MaterialService = game:GetService("MaterialService")
local TestService = game:GetService("TestService")
local JointsService = game:GetService("JointsService")

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 1: CORE MODULE INITIALIZATION
--// ═══════════════════════════════════════════════════════════════════════════

local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance
BaoSaveInstance.Version = "1.0.0"
BaoSaveInstance.Author = "BaoSaveInstance Team"

--// Supported exploit clients
BaoSaveInstance.SupportedClients = {
    "Synapse X",
    "Delta", 
    "Xeno",
    "Solara",
    "TNG"
}

--// Client capability definitions
BaoSaveInstance.ClientCapabilities = {
    ["Synapse X"] = {
        FullScriptSource = true,
        TerrainVoxels = true,
        HiddenProperties = true,
        Decompile = true,
        SaveInstance = true,
        GetHiddenProperty = true,
        SetHiddenProperty = true,
        GetNilInstances = true,
        GetGC = true,
        GetConnections = true,
        FireSignal = false,
        ReadFile = true,
        WriteFile = true,
        AppendFile = true,
        MakeFolder = true,
        IsFolder = true,
        ListFiles = true,
        DelFile = true,
        HttpRequest = true,
        WebSocket = true,
        Crypt = true,
        Base64 = true,
        LZ4 = true,
        Priority = 1
    },
    ["Delta"] = {
        FullScriptSource = false,
        TerrainVoxels = true,
        HiddenProperties = true,
        Decompile = true,
        SaveInstance = true,
        GetHiddenProperty = true,
        SetHiddenProperty = false,
        GetNilInstances = true,
        GetGC = true,
        GetConnections = true,
        FireSignal = false,
        ReadFile = true,
        WriteFile = true,
        AppendFile = true,
        MakeFolder = true,
        IsFolder = true,
        ListFiles = true,
        DelFile = true,
        HttpRequest = true,
        WebSocket = false,
        Crypt = true,
        Base64 = true,
        LZ4 = false,
        Priority = 2
    },
    ["Xeno"] = {
        FullScriptSource = false,
        TerrainVoxels = false,
        HiddenProperties = false,
        Decompile = true,
        SaveInstance = true,
        GetHiddenProperty = false,
        SetHiddenProperty = false,
        GetNilInstances = true,
        GetGC = true,
        GetConnections = true,
        FireSignal = false,
        ReadFile = true,
        WriteFile = true,
        AppendFile = true,
        MakeFolder = true,
        IsFolder = true,
        ListFiles = true,
        DelFile = true,
        HttpRequest = true,
        WebSocket = true,
        Crypt = true,
        Base64 = true,
        LZ4 = false,
        Priority = 3
    },
    ["Solara"] = {
        FullScriptSource = false,
        TerrainVoxels = false,
        HiddenProperties = false,
        Decompile = true,
        SaveInstance = true,
        GetHiddenProperty = false,
        SetHiddenProperty = false,
        GetNilInstances = true,
        GetGC = false,
        GetConnections = true,
        FireSignal = false,
        ReadFile = true,
        WriteFile = true,
        AppendFile = true,
        MakeFolder = true,
        IsFolder = true,
        ListFiles = true,
        DelFile = true,
        HttpRequest = true,
        WebSocket = false,
        Crypt = false,
        Base64 = true,
        LZ4 = false,
        Priority = 4
    },
    ["TNG"] = {
        FullScriptSource = false,
        TerrainVoxels = false,
        HiddenProperties = false,
        Decompile = false,
        SaveInstance = false,
        GetHiddenProperty = false,
        SetHiddenProperty = false,
        GetNilInstances = false,
        GetGC = false,
        GetConnections = false,
        FireSignal = false,
        ReadFile = true,
        WriteFile = true,
        AppendFile = true,
        MakeFolder = true,
        IsFolder = false,
        ListFiles = true,
        DelFile = true,
        HttpRequest = true,
        WebSocket = false,
        Crypt = false,
        Base64 = true,
        LZ4 = false,
        Priority = 5
    }
}

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 2: CLIENT DETECTION SYSTEM
--// ═══════════════════════════════════════════════════════════════════════════

local ClientDetector = {}

--[[
    Detect which exploit client is currently running
    Uses multiple detection methods for accuracy
]]
function ClientDetector.Detect()
    local clientInfo = {
        Name = "Unknown",
        Version = "Unknown",
        Capabilities = {},
        IsSupported = false
    }
    
    --// Method 1: identifyexecutor() function
    if identifyexecutor then
        local name, version = identifyexecutor()
        if name then
            -- Normalize client name
            local normalizedName = ClientDetector.NormalizeName(name)
            if normalizedName then
                clientInfo.Name = normalizedName
                clientInfo.Version = version or "Unknown"
                clientInfo.IsSupported = true
            end
        end
    end
    
    --// Method 2: Check for specific globals (fallback)
    if not clientInfo.IsSupported then
        if syn and syn.crypt then
            clientInfo.Name = "Synapse X"
            clientInfo.IsSupported = true
        elseif XENO_UNIQUE or getexecutorname and getexecutorname():lower():find("xeno") then
            clientInfo.Name = "Xeno"
            clientInfo.IsSupported = true
        elseif delta or getexecutorname and getexecutorname():lower():find("delta") then
            clientInfo.Name = "Delta"
            clientInfo.IsSupported = true
        elseif Solara or getexecutorname and getexecutorname():lower():find("solara") then
            clientInfo.Name = "Solara"
            clientInfo.IsSupported = true
        elseif getexecutorname and getexecutorname():lower():find("tng") then
            clientInfo.Name = "TNG"
            clientInfo.IsSupported = true
        end
    end
    
    --// Load capabilities for detected client
    if clientInfo.IsSupported and BaoSaveInstance.ClientCapabilities[clientInfo.Name] then
        clientInfo.Capabilities = BaoSaveInstance.ClientCapabilities[clientInfo.Name]
    end
    
    --// Method 3: Runtime capability detection
    clientInfo.Capabilities = ClientDetector.DetectCapabilities(clientInfo.Capabilities)
    
    return clientInfo
end

--[[
    Normalize client name to match our capability table
]]
function ClientDetector.NormalizeName(rawName)
    local lower = rawName:lower()
    
    local nameMap = {
        ["synapse x"] = "Synapse X",
        ["synapse"] = "Synapse X",
        ["syn"] = "Synapse X",
        ["delta"] = "Delta",
        ["xeno"] = "Xeno",
        ["solara"] = "Solara",
        ["tng"] = "TNG",
        ["the new generation"] = "TNG"
    }
    
    for pattern, normalized in pairs(nameMap) do
        if lower:find(pattern) then
            return normalized
        end
    end
    
    return nil
end

--[[
    Runtime detection of actual capabilities
    Some exploits may have different features than expected
]]
function ClientDetector.DetectCapabilities(baseCapabilities)
    local caps = baseCapabilities or {}
    
    --// Test actual function availability
    local functionTests = {
        Decompile = {"decompile", "getscriptsource", "getscriptbytecode"},
        SaveInstance = {"saveinstance", "save_instance"},
        GetHiddenProperty = {"gethiddenproperty", "get_hidden_property"},
        SetHiddenProperty = {"sethiddenproperty", "set_hidden_property"},
        GetNilInstances = {"getnilinstances", "get_nil_instances"},
        GetGC = {"getgc", "get_gc"},
        GetConnections = {"getconnections", "get_connections"},
        ReadFile = {"readfile", "read_file"},
        WriteFile = {"writefile", "write_file"},
        AppendFile = {"appendfile", "append_file"},
        MakeFolder = {"makefolder", "make_folder", "mkdir"},
        IsFolder = {"isfolder", "is_folder"},
        ListFiles = {"listfiles", "list_files", "readdir"},
        DelFile = {"delfile", "del_file", "rmfile"},
        HttpRequest = {"request", "http_request", "syn.request"},
        Crypt = {"crypt", "syn.crypt"},
        Base64 = {"base64_encode", "base64.encode", "crypt.base64encode"}
    }
    
    for capName, funcNames in pairs(functionTests) do
        if caps[capName] == nil then
            caps[capName] = false
            for _, funcName in ipairs(funcNames) do
                local func = getfenv()[funcName]
                if func and type(func) == "function" then
                    caps[capName] = true
                    break
                end
            end
        end
    end
    
    return caps
end

BaoSaveInstance.ClientDetector = ClientDetector

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 3: UTILITY FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════

local Utilities = {}

--[[
    Safe function wrapper to handle pcall and errors
]]
function Utilities.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if success then
        return result, nil
    else
        return nil, result
    end
end

--[[
    Yield safely to prevent client freeze
    Uses task.wait() or RunService.Heartbeat
]]
function Utilities.SafeYield(duration)
    duration = duration or 0
    if task and task.wait then
        task.wait(duration)
    elseif wait then
        wait(duration)
    else
        RunService.Heartbeat:Wait()
    end
end

--[[
    Batch processor for large operations
    Yields every N iterations to prevent freezing
]]
function Utilities.BatchProcess(items, batchSize, processor, onProgress)
    batchSize = batchSize or 100
    local total = #items
    local processed = 0
    local results = {}
    
    for i, item in ipairs(items) do
        local success, result = pcall(processor, item, i)
        if success then
            table.insert(results, result)
        end
        
        processed = processed + 1
        
        --// Yield every batch
        if processed % batchSize == 0 then
            if onProgress then
                onProgress(processed, total, math.floor((processed / total) * 100))
            end
            Utilities.SafeYield()
        end
    end
    
    return results
end

--[[
    Generate unique identifier
]]
function Utilities.GenerateUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

--[[
    Get current timestamp in readable format
]]
function Utilities.GetTimestamp()
    local date = os.date("*t")
    return string.format("%04d-%02d-%02d_%02d-%02d-%02d", 
        date.year, date.month, date.day, 
        date.hour, date.min, date.sec)
end

--[[
    Deep clone a table
]]
function Utilities.DeepClone(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = Utilities.DeepClone(value)
        else
            copy[key] = value
        end
    end
    return copy
end

--[[
    Safe string escape for XML
]]
function Utilities.EscapeXML(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    
    local replacements = {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ['"'] = "&quot;",
        ["'"] = "&apos;",
        ["\0"] = "",  -- Remove null characters
    }
    
    for char, replacement in pairs(replacements) do
        str = str:gsub(char, replacement)
    end
    
    --// Remove other invalid XML characters
    str = str:gsub("[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]", "")
    
    return str
end

--[[
    Check if instance is valid and accessible
]]
function Utilities.IsValidInstance(instance)
    local success, result = pcall(function()
        return instance and instance.Parent ~= nil or instance == game
    end)
    return success and result
end

--[[
    Get all descendants with error handling
]]
function Utilities.GetDescendantsSafe(instance)
    local descendants = {}
    local success, err = pcall(function()
        descendants = instance:GetDescendants()
    end)
    
    if not success then
        --// Fallback: manual recursive collection
        local function collect(parent)
            local success2, children = pcall(function()
                return parent:GetChildren()
            end)
            
            if success2 then
                for _, child in ipairs(children) do
                    table.insert(descendants, child)
                    collect(child)
                end
            end
        end
        
        collect(instance)
    end
    
    return descendants
end

BaoSaveInstance.Utilities = Utilities

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 4: LOGGING SYSTEM
--// ═══════════════════════════════════════════════════════════════════════════

local Logger = {}
Logger.Logs = {}
Logger.Warnings = {}
Logger.Errors = {}
Logger.Stats = {
    InstancesSaved = 0,
    ScriptsSaved = 0,
    ScriptsEncrypted = 0,
    PropertiesSaved = 0,
    PropertiesFailed = 0,
    TerrainChunksSaved = 0
}

Logger.LogLevel = {
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4
}

Logger.CurrentLevel = Logger.LogLevel.INFO

function Logger.Log(level, category, message)
    local logEntry = {
        Time = os.time(),
        Level = level,
        Category = category,
        Message = message
    }
    
    table.insert(Logger.Logs, logEntry)
    
    if level >= Logger.CurrentLevel then
        local prefix = "[BaoSave]"
        if level == Logger.LogLevel.WARNING then
            prefix = "[BaoSave:WARN]"
            table.insert(Logger.Warnings, logEntry)
        elseif level == Logger.LogLevel.ERROR then
            prefix = "[BaoSave:ERROR]"
            table.insert(Logger.Errors, logEntry)
        end
        
        print(string.format("%s [%s] %s", prefix, category, message))
    end
end

function Logger.Debug(category, message)
    Logger.Log(Logger.LogLevel.DEBUG, category, message)
end

function Logger.Info(category, message)
    Logger.Log(Logger.LogLevel.INFO, category, message)
end

function Logger.Warn(category, message)
    Logger.Log(Logger.LogLevel.WARNING, category, message)
end

function Logger.Error(category, message)
    Logger.Log(Logger.LogLevel.ERROR, category, message)
end

function Logger.IncrementStat(statName, amount)
    amount = amount or 1
    if Logger.Stats[statName] then
        Logger.Stats[statName] = Logger.Stats[statName] + amount
    end
end

function Logger.GetReport()
    return {
        Logs = Logger.Logs,
        Warnings = Logger.Warnings,
        Errors = Logger.Errors,
        Stats = Logger.Stats,
        Summary = string.format(
            "Instances: %d | Scripts: %d (Encrypted: %d) | Properties: %d (Failed: %d) | Terrain Chunks: %d",
            Logger.Stats.InstancesSaved,
            Logger.Stats.ScriptsSaved,
            Logger.Stats.ScriptsEncrypted,
            Logger.Stats.PropertiesSaved,
            Logger.Stats.PropertiesFailed,
            Logger.Stats.TerrainChunksSaved
        )
    }
end

function Logger.Reset()
    Logger.Logs = {}
    Logger.Warnings = {}
    Logger.Errors = {}
    Logger.Stats = {
        InstancesSaved = 0,
        ScriptsSaved = 0,
        ScriptsEncrypted = 0,
        PropertiesSaved = 0,
        PropertiesFailed = 0,
        TerrainChunksSaved = 0
    }
end

BaoSaveInstance.Logger = Logger

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 5: PROPERTY SERIALIZER
--// ═══════════════════════════════════════════════════════════════════════════

local PropertySerializer = {}

--[[
    Property database with type information
    Used for serialization and hidden property detection
]]
PropertySerializer.PropertyDatabase = {
    --// BasePart properties
    BasePart = {
        "Anchored", "CanCollide", "CanTouch", "CanQuery", "CastShadow",
        "Color", "Material", "MaterialVariant", "Reflectance", "Transparency",
        "Size", "CFrame", "Position", "Orientation", "Rotation",
        "Velocity", "RotVelocity", "AssemblyLinearVelocity", "AssemblyAngularVelocity",
        "Massless", "RootPriority", "CollisionGroup", "Locked",
        "BrickColor", "TopSurface", "BottomSurface", "LeftSurface", 
        "RightSurface", "FrontSurface", "BackSurface"
    },
    
    --// MeshPart additional properties
    MeshPart = {
        "MeshId", "TextureID", "DoubleSided", "RenderFidelity", "CollisionFidelity"
    },
    
    --// Part additional properties
    Part = {
        "Shape"
    },
    
    --// UnionOperation properties
    UnionOperation = {
        "UsePartColor", "SmoothingAngle", "RenderFidelity", "CollisionFidelity"
    },
    
    --// Model properties
    Model = {
        "PrimaryPart", "WorldPivot", "ModelStreamingMode", "LevelOfDetail"
    },
    
    --// Script properties
    LuaSourceContainer = {
        "Disabled"
    },
    
    --// Lighting properties
    Lighting = {
        "Ambient", "Brightness", "ColorShift_Bottom", "ColorShift_Top",
        "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows",
        "OutdoorAmbient", "ShadowSoftness", "Technology", "ClockTime",
        "GeographicLatitude", "TimeOfDay", "ExposureCompensation", "FogColor",
        "FogEnd", "FogStart"
    },
    
    --// Camera properties
    Camera = {
        "CFrame", "Focus", "FieldOfView", "FieldOfViewMode", "CameraType",
        "HeadScale", "VRTiltAndRollEnabled", "DiagonalFieldOfView", "MaxAxisFieldOfView"
    },
    
    --// Humanoid properties
    Humanoid = {
        "DisplayDistanceType", "DisplayName", "Health", "HealthDisplayDistance",
        "HealthDisplayType", "HipHeight", "JumpHeight", "JumpPower", "MaxHealth",
        "MaxSlopeAngle", "NameDisplayDistance", "NameOcclusion", "RigType",
        "UseJumpPower", "WalkSpeed", "AutoRotate", "AutomaticScalingEnabled",
        "BreakJointsOnDeath", "EvaluateStateMachine", "RequiresNeck"
    },
    
    --// Attachment properties
    Attachment = {
        "CFrame", "Visible", "Axis", "SecondaryAxis", "WorldCFrame",
        "WorldAxis", "WorldSecondaryAxis", "Orientation", "Position",
        "WorldOrientation", "WorldPosition"
    },
    
    --// Constraint properties (common)
    Constraint = {
        "Enabled", "Visible", "Color", "Attachment0", "Attachment1"
    },
    
    --// WeldConstraint
    WeldConstraint = {
        "Enabled", "Part0", "Part1"
    },
    
    --// Motor6D / Weld
    JointInstance = {
        "C0", "C1", "Part0", "Part1", "Enabled"
    },
    
    --// Decal / Texture
    Decal = {
        "Color3", "Face", "LocalTransparencyModifier", "Texture", "Transparency", "ZIndex"
    },
    
    Texture = {
        "OffsetStudsU", "OffsetStudsV", "StudsPerTileU", "StudsPerTileV"
    },
    
    --// SurfaceAppearance
    SurfaceAppearance = {
        "AlphaMode", "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap", "TexturePack"
    },
    
    --// Sound
    Sound = {
        "EmitterSize", "Looped", "MaxDistance", "MinDistance", "Pitch",
        "PlayOnRemove", "PlaybackSpeed", "RollOffMaxDistance", "RollOffMinDistance",
        "RollOffMode", "SoundGroup", "SoundId", "TimePosition", "Volume", "Playing"
    },
    
    --// ParticleEmitter
    ParticleEmitter = {
        "Acceleration", "Brightness", "Color", "Drag", "EmissionDirection",
        "Enabled", "FlipbookFramerate", "FlipbookIncompatible", "FlipbookLayout",
        "FlipbookMode", "FlipbookStartRandom", "Lifetime", "LightEmission",
        "LightInfluence", "LockedToPart", "Orientation", "Rate", "RotSpeed",
        "Rotation", "Shape", "ShapeInOut", "ShapePartial", "ShapeStyle",
        "Size", "Speed", "SpreadAngle", "Squash", "Texture", "TimeScale",
        "Transparency", "VelocityInheritance", "WindAffectsDrag", "ZOffset"
    },
    
    --// BillboardGui
    BillboardGui = {
        "Active", "Adornee", "AlwaysOnTop", "Brightness", "ClipsDescendants",
        "CurrentDistance", "DistanceLowerLimit", "DistanceStep", "DistanceUpperLimit",
        "ExtentsOffset", "ExtentsOffsetWorldSpace", "LightInfluence", "MaxDistance",
        "PlayerToHideFrom", "Size", "SizeOffset", "StudsOffset", "StudsOffsetWorldSpace"
    },
    
    --// SurfaceGui
    SurfaceGui = {
        "Active", "Adornee", "AlwaysOnTop", "Brightness", "CanvasSize",
        "ClipsDescendants", "Face", "LightInfluence", "PixelsPerStud",
        "SizingMode", "ToolPunchThroughDistance", "ZOffset"
    },
    
    --// ScreenGui
    ScreenGui = {
        "DisplayOrder", "Enabled", "IgnoreGuiInset", "ResetOnSpawn",
        "ZIndexBehavior", "AutoLocalize", "ClipToDeviceSafeArea"
    },
    
    --// Frame / UI Elements
    GuiObject = {
        "Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3",
        "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel",
        "ClipsDescendants", "Interactable", "LayoutOrder", "Position",
        "Rotation", "Selectable", "SelectionGroup", "SelectionOrder",
        "Size", "SizeConstraint", "Visible", "ZIndex"
    },
    
    --// TextLabel / TextButton / TextBox
    TextObject = {
        "Font", "FontFace", "LineHeight", "MaxVisibleGraphemes", "RichText",
        "Text", "TextColor3", "TextDirection", "TextScaled", "TextSize",
        "TextStrokeColor3", "TextStrokeTransparency", "TextTransparency",
        "TextTruncate", "TextWrapped", "TextXAlignment", "TextYAlignment"
    },
    
    --// ImageLabel / ImageButton
    ImageObject = {
        "Image", "ImageColor3", "ImageRectOffset", "ImageRectSize", "ImageTransparency",
        "ResampleMode", "ScaleType", "SliceCenter", "SliceScale", "TileSize"
    },
    
    --// ValueObjects
    ValueObject = {
        "Value"
    },
    
    --// UIComponents
    UICorner = {"CornerRadius"},
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
    
    --// Beam
    Beam = {
        "Attachment0", "Attachment1", "Brightness", "Color", "CurveSize0",
        "CurveSize1", "Enabled", "FaceCamera", "LightEmission", "LightInfluence",
        "Segments", "Texture", "TextureLength", "TextureMode", "TextureSpeed",
        "Transparency", "Width0", "Width1", "ZOffset"
    },
    
    --// Trail
    Trail = {
        "Attachment0", "Attachment1", "Brightness", "Color", "Enabled",
        "FaceCamera", "Lifetime", "LightEmission", "LightInfluence",
        "MaxLength", "MinLength", "Texture", "TextureLength", "TextureMode",
        "Transparency", "WidthScale"
    },
    
    --// SpawnLocation
    SpawnLocation = {
        "AllowTeamChangeOnTouch", "Duration", "Enabled", "Neutral", "TeamColor"
    },
    
    --// Tool
    Tool = {
        "CanBeDropped", "Enabled", "Grip", "GripForward", "GripPos",
        "GripRight", "GripUp", "ManualActivationOnly", "RequiresHandle", "ToolTip"
    },
    
    --// Accessory
    Accessory = {
        "AccessoryType"
    },
    
    --// Pants / Shirt
    Clothing = {
        "Color3"
    },
    Pants = {"PantsTemplate"},
    Shirt = {"ShirtTemplate"},
    ShirtGraphic = {"Color3", "Graphic"},
    
    --// BodyColors
    BodyColors = {
        "HeadColor", "HeadColor3", "LeftArmColor", "LeftArmColor3",
        "LeftLegColor", "LeftLegColor3", "RightArmColor", "RightArmColor3",
        "RightLegColor", "RightLegColor3", "TorsoColor", "TorsoColor3"
    },
    
    --// CharacterMesh
    CharacterMesh = {
        "BaseTextureId", "BodyPart", "MeshId", "OverlayTextureId"
    },
    
    --// SpecialMesh
    SpecialMesh = {
        "MeshId", "MeshType", "Offset", "Scale", "TextureId", "VertexColor"
    },
    
    --// BlockMesh / CylinderMesh
    DataModelMesh = {
        "Offset", "Scale", "VertexColor"
    },
    
    --// Sky
    Sky = {
        "CelestialBodiesShown", "MoonAngularSize", "MoonTextureId", "SkyboxBk",
        "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp",
        "StarCount", "SunAngularSize", "SunTextureId"
    },
    
    --// Atmosphere
    Atmosphere = {
        "Color", "Decay", "Density", "Glare", "Haze", "Offset"
    },
    
    --// Clouds
    Clouds = {
        "Color", "Cover", "Density", "Enabled"
    },
    
    --// Post-processing effects
    BloomEffect = {"Enabled", "Intensity", "Size", "Threshold"},
    BlurEffect = {"Enabled", "Size"},
    ColorCorrectionEffect = {"Brightness", "Contrast", "Enabled", "Saturation", "TintColor"},
    DepthOfFieldEffect = {"Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"},
    SunRaysEffect = {"Enabled", "Intensity", "Spread"},
}

--[[
    Hidden properties that require special access
]]
PropertySerializer.HiddenProperties = {
    Part = {"FormFactor"},
    BasePart = {
        "PhysicalConfigData", "SpecificGravity", "Elasticity", 
        "ElasticityWeight", "Friction", "FrictionWeight"
    },
    Humanoid = {
        "InternalHeadScale", "InternalBodyScale"
    },
    LocalScript = {"LinkedSource"},
    ModuleScript = {"LinkedSource"},
    Script = {"LinkedSource"},
    Sound = {"IsLoaded"},
    MeshPart = {"InitialSize", "PhysicsData", "HasJointOffset", "HasSkinnedMesh"}
}

--[[
    Properties to ignore during serialization
]]
PropertySerializer.IgnoredProperties = {
    "Parent", "ClassName", "Archivable", "RobloxLocked", 
    "DataCost", "PropertyStatusStudio"
}

--[[
    Type serializers for different value types
]]
PropertySerializer.TypeSerializers = {
    ["string"] = function(value)
        return Utilities.EscapeXML(value)
    end,
    
    ["number"] = function(value)
        if value ~= value then -- NaN check
            return "0"
        elseif value == math.huge then
            return "INF"
        elseif value == -math.huge then
            return "-INF"
        else
            return tostring(value)
        end
    end,
    
    ["boolean"] = function(value)
        return value and "true" or "false"
    end,
    
    ["Vector3"] = function(value)
        return string.format("<X>%s</X><Y>%s</Y><Z>%s</Z>", 
            tostring(value.X), tostring(value.Y), tostring(value.Z))
    end,
    
    ["Vector2"] = function(value)
        return string.format("<X>%s</X><Y>%s</Y>", 
            tostring(value.X), tostring(value.Y))
    end,
    
    ["CFrame"] = function(value)
        local components = {value:GetComponents()}
        return table.concat(components, " ")
    end,
    
    ["Color3"] = function(value)
        return string.format("%s %s %s", 
            tostring(value.R), tostring(value.G), tostring(value.B))
    end,
    
    ["BrickColor"] = function(value)
        return tostring(value.Number)
    end,
    
    ["UDim"] = function(value)
        return string.format("<S>%s</S><O>%s</O>", 
            tostring(value.Scale), tostring(value.Offset))
    end,
    
    ["UDim2"] = function(value)
        return string.format(
            "<XS>%s</XS><XO>%s</XO><YS>%s</YS><YO>%s</YO>",
            tostring(value.X.Scale), tostring(value.X.Offset),
            tostring(value.Y.Scale), tostring(value.Y.Offset)
        )
    end,
    
    ["Rect"] = function(value)
        return string.format(
            "<min><X>%s</X><Y>%s</Y></min><max><X>%s</X><Y>%s</Y></max>",
            tostring(value.Min.X), tostring(value.Min.Y),
            tostring(value.Max.X), tostring(value.Max.Y)
        )
    end,
    
    ["NumberSequence"] = function(value)
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%s %s %s", 
                tostring(kp.Time), tostring(kp.Value), tostring(kp.Envelope)))
        end
        return table.concat(keypoints, " ")
    end,
    
    ["ColorSequence"] = function(value)
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%s %s %s %s", 
                tostring(kp.Time), tostring(kp.Value.R), 
                tostring(kp.Value.G), tostring(kp.Value.B)))
        end
        return table.concat(keypoints, " ")
    end,
    
    ["NumberRange"] = function(value)
        return string.format("%s %s", tostring(value.Min), tostring(value.Max))
    end,
    
    ["Enum"] = function(value)
        return tostring(value.Value)
    end,
    
    ["EnumItem"] = function(value)
        return tostring(value.Value)
    end,
    
    ["Font"] = function(value)
        return string.format(
            "<Family><url>%s</url></Family><Weight>%d</Weight><Style>%s</Style>",
            Utilities.EscapeXML(value.Family),
            value.Weight.Value,
            value.Style.Name
        )
    end,
    
    ["Instance"] = function(value, referenceMap)
        if referenceMap and referenceMap[value] then
            return referenceMap[value]
        end
        return "null"
    end,
    
    ["Ray"] = function(value)
        return string.format(
            "<origin><X>%s</X><Y>%s</Y><Z>%s</Z></origin><direction><X>%s</X><Y>%s</Y><Z>%s</Z></direction>",
            tostring(value.Origin.X), tostring(value.Origin.Y), tostring(value.Origin.Z),
            tostring(value.Direction.X), tostring(value.Direction.Y), tostring(value.Direction.Z)
        )
    end,
    
    ["Faces"] = function(value)
        local faces = {}
        if value.Top then table.insert(faces, "Top") end
        if value.Bottom then table.insert(faces, "Bottom") end
        if value.Left then table.insert(faces, "Left") end
        if value.Right then table.insert(faces, "Right") end
        if value.Back then table.insert(faces, "Back") end
        if value.Front then table.insert(faces, "Front") end
        return table.concat(faces, ", ")
    end,
    
    ["Axes"] = function(value)
        local axes = {}
        if value.X then table.insert(axes, "X") end
        if value.Y then table.insert(axes, "Y") end
        if value.Z then table.insert(axes, "Z") end
        return table.concat(axes, ", ")
    end,
    
    ["PhysicalProperties"] = function(value)
        if value then
            return string.format(
                "<CustomPhysics>true</CustomPhysics><Density>%s</Density><Friction>%s</Friction><Elasticity>%s</Elasticity><FrictionWeight>%s</FrictionWeight><ElasticityWeight>%s</ElasticityWeight>",
                tostring(value.Density), tostring(value.Friction),
                tostring(value.Elasticity), tostring(value.FrictionWeight),
                tostring(value.ElasticityWeight)
            )
        else
            return "<CustomPhysics>false</CustomPhysics>"
        end
    end,
    
    ["Content"] = function(value)
        return string.format("<url>%s</url>", Utilities.EscapeXML(tostring(value)))
    end,
}

--[[
    Get the serializer for a given type
]]
function PropertySerializer.GetSerializer(typeName)
    return PropertySerializer.TypeSerializers[typeName]
end

--[[
    Serialize a property value to XML format
]]
function PropertySerializer.SerializeValue(value, propertyName, referenceMap)
    local valueType = typeof(value)
    
    local serializer = PropertySerializer.TypeSerializers[valueType]
    if serializer then
        if valueType == "Instance" then
            return serializer(value, referenceMap)
        else
            return serializer(value)
        end
    end
    
    --// Fallback for unknown types
    return Utilities.EscapeXML(tostring(value))
end

--[[
    Get all properties for an instance class
]]
function PropertySerializer.GetPropertiesForClass(className)
    local properties = {}
    local checked = {}
    
    --// Add base properties
    local function addProperties(propTable)
        if propTable then
            for _, prop in ipairs(propTable) do
                if not checked[prop] then
                    table.insert(properties, prop)
                    checked[prop] = true
                end
            end
        end
    end
    
    --// Check class hierarchy
    local classHierarchy = {
        Part = {"BasePart", "Part"},
        MeshPart = {"BasePart", "MeshPart"},
        UnionOperation = {"BasePart", "UnionOperation"},
        WedgePart = {"BasePart"},
        CornerWedgePart = {"BasePart"},
        TrussPart = {"BasePart"},
        SpawnLocation = {"BasePart", "SpawnLocation"},
        Seat = {"BasePart"},
        VehicleSeat = {"BasePart"},
        SkateboardPlatform = {"BasePart"},
        Model = {"Model"},
        LocalScript = {"LuaSourceContainer"},
        Script = {"LuaSourceContainer"},
        ModuleScript = {"LuaSourceContainer"},
        TextLabel = {"GuiObject", "TextObject"},
        TextButton = {"GuiObject", "TextObject"},
        TextBox = {"GuiObject", "TextObject"},
        ImageLabel = {"GuiObject", "ImageObject"},
        ImageButton = {"GuiObject", "ImageObject"},
        Frame = {"GuiObject"},
        ScrollingFrame = {"GuiObject"},
        ViewportFrame = {"GuiObject"},
        CanvasGroup = {"GuiObject"},
        Weld = {"JointInstance"},
        Motor = {"JointInstance"},
        Motor6D = {"JointInstance"},
        Glue = {"JointInstance"},
        ManualWeld = {"JointInstance"},
        ManualGlue = {"JointInstance"},
        WeldConstraint = {"WeldConstraint"},
        Decal = {"Decal"},
        Texture = {"Decal", "Texture"},
        Humanoid = {"Humanoid"},
        Attachment = {"Attachment"},
        Accessory = {"Accessory"},
        Tool = {"Tool"},
        Pants = {"Clothing", "Pants"},
        Shirt = {"Clothing", "Shirt"},
        ShirtGraphic = {"ShirtGraphic"},
        SpecialMesh = {"DataModelMesh", "SpecialMesh"},
        BlockMesh = {"DataModelMesh"},
        CylinderMesh = {"DataModelMesh"},
        Sound = {"Sound"},
        ParticleEmitter = {"ParticleEmitter"},
        PointLight = {},
        SpotLight = {},
        SurfaceLight = {},
        Fire = {},
        Smoke = {},
        Sparkles = {},
        Beam = {"Beam"},
        Trail = {"Trail"},
        BillboardGui = {"BillboardGui"},
        SurfaceGui = {"SurfaceGui"},
        ScreenGui = {"ScreenGui"},
        SurfaceAppearance = {"SurfaceAppearance"},
        Camera = {"Camera"},
        Sky = {"Sky"},
        Atmosphere = {"Atmosphere"},
        Clouds = {"Clouds"},
        BloomEffect = {"BloomEffect"},
        BlurEffect = {"BlurEffect"},
        ColorCorrectionEffect = {"ColorCorrectionEffect"},
        DepthOfFieldEffect = {"DepthOfFieldEffect"},
        SunRaysEffect = {"SunRaysEffect"},
        BodyColors = {"BodyColors"},
        CharacterMesh = {"CharacterMesh"},
        StringValue = {"ValueObject"},
        NumberValue = {"ValueObject"},
        IntValue = {"ValueObject"},
        BoolValue = {"ValueObject"},
        ObjectValue = {"ValueObject"},
        Vector3Value = {"ValueObject"},
        CFrameValue = {"ValueObject"},
        Color3Value = {"ValueObject"},
        BrickColorValue = {"ValueObject"},
        RayValue = {"ValueObject"},
        UICorner = {"UICorner"},
        UIStroke = {"UIStroke"},
        UIPadding = {"UIPadding"},
        UIScale = {"UIScale"},
        UIAspectRatioConstraint = {"UIAspectRatioConstraint"},
        UISizeConstraint = {"UISizeConstraint"},
        UITextSizeConstraint = {"UITextSizeConstraint"},
        UIListLayout = {"UIListLayout"},
        UIGridLayout = {"UIGridLayout"},
        UIPageLayout = {"UIPageLayout"},
        UITableLayout = {"UITableLayout"},
    }
    
    local hierarchy = classHierarchy[className] or {}
    for _, parentClass in ipairs(hierarchy) do
        addProperties(PropertySerializer.PropertyDatabase[parentClass])
    end
    
    --// Always add Name
    if not checked["Name"] then
        table.insert(properties, "Name")
    end
    
    return properties
end

--[[
    Serialize all properties of an instance
]]
function PropertySerializer.SerializeInstance(instance, referenceMap, clientInfo)
    local properties = {}
    local className = instance.ClassName
    local propertiesToSerialize = PropertySerializer.GetPropertiesForClass(className)
    
    for _, propName in ipairs(propertiesToSerialize) do
        if table.find(PropertySerializer.IgnoredProperties, propName) then
            continue
        end
        
        local success, value = pcall(function()
            return instance[propName]
        end)
        
        if success and value ~= nil then
            local serializedValue = PropertySerializer.SerializeValue(value, propName, referenceMap)
            if serializedValue then
                properties[propName] = {
                    Value = serializedValue,
                    Type = typeof(value)
                }
                Logger.IncrementStat("PropertiesSaved")
            end
        else
            Logger.IncrementStat("PropertiesFailed")
        end
    end
    
    --// Try hidden properties if client supports it
    if clientInfo and clientInfo.Capabilities.GetHiddenProperty then
        local hiddenProps = PropertySerializer.HiddenProperties[className]
        if hiddenProps then
            for _, propName in ipairs(hiddenProps) do
                local success, value = pcall(function()
                    return gethiddenproperty(instance, propName)
                end)
                
                if success and value ~= nil then
                    local serializedValue = PropertySerializer.SerializeValue(value, propName, referenceMap)
                    if serializedValue then
                        properties[propName] = {
                            Value = serializedValue,
                            Type = typeof(value),
                            IsHidden = true
                        }
                        Logger.IncrementStat("PropertiesSaved")
                    end
                end
            end
        end
    end
    
    --// Serialize attributes
    local attributes = {}
    local success, attrs = pcall(function()
        return instance:GetAttributes()
    end)
    
    if success and attrs then
        for attrName, attrValue in pairs(attrs) do
            local serializedValue = PropertySerializer.SerializeValue(attrValue, attrName, referenceMap)
            if serializedValue then
                attributes[attrName] = {
                    Value = serializedValue,
                    Type = typeof(attrValue)
                }
            end
        end
    end
    
    return properties, attributes
end

BaoSaveInstance.PropertySerializer = PropertySerializer

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 6: SCRIPT HANDLER
--// ═══════════════════════════════════════════════════════════════════════════

local ScriptHandler = {}

ScriptHandler.EncryptedMarker = "--[[ SCRIPT SOURCE ENCRYPTED/PROTECTED ]]"
ScriptHandler.DecompileFailedMarker = "--[[ DECOMPILATION FAILED ]]"
ScriptHandler.NotAvailableMarker = "--[[ SOURCE NOT AVAILABLE - Client limitation ]]"

--[[
    Attempt to get script source using available methods
]]
function ScriptHandler.GetSource(script, clientInfo)
    local source = nil
    local status = "success"
    local method = "unknown"
    
    --// Method 1: Direct Source access (usually blocked)
    local success1, result1 = pcall(function()
        return script.Source
    end)
    
    if success1 and result1 and #result1 > 0 then
        source = result1
        method = "direct"
        Logger.Debug("Script", "Got source directly for: " .. script:GetFullName())
        return source, status, method
    end
    
    --// Method 2: decompile function
    if decompile then
        local success2, result2 = pcall(function()
            return decompile(script)
        end)
        
        if success2 and result2 and #result2 > 0 then
            source = result2
            method = "decompile"
            Logger.Debug("Script", "Decompiled: " .. script:GetFullName())
            return source, status, method
        else
            Logger.Warn("Script", "Decompile failed for: " .. script:GetFullName())
        end
    end
    
    --// Method 3: getscriptsource (some exploits)
    if getscriptsource then
        local success3, result3 = pcall(function()
            return getscriptsource(script)
        end)
        
        if success3 and result3 and #result3 > 0 then
            source = result3
            method = "getscriptsource"
            Logger.Debug("Script", "Got source via getscriptsource: " .. script:GetFullName())
            return source, status, method
        end
    end
    
    --// Method 4: Synapse-specific
    if syn and syn.decompile then
        local success4, result4 = pcall(function()
            return syn.decompile(script)
        end)
        
        if success4 and result4 and #result4 > 0 then
            source = result4
            method = "syn.decompile"
            Logger.Debug("Script", "Got source via syn.decompile: " .. script:GetFullName())
            return source, status, method
        end
    end
    
    --// All methods failed
    if clientInfo and clientInfo.Capabilities.Decompile then
        status = "decompile_failed"
        source = ScriptHandler.DecompileFailedMarker
    else
        status = "not_available"
        source = ScriptHandler.NotAvailableMarker
    end
    
    Logger.Warn("Script", "Could not get source for: " .. script:GetFullName() .. " (Status: " .. status .. ")")
    
    return source, status, method
end

--[[
    Process a script instance for saving
]]
function ScriptHandler.ProcessScript(script, clientInfo)
    local scriptData = {
        Name = script.Name,
        ClassName = script.ClassName,
        FullName = script:GetFullName(),
        Source = "",
        Status = "unknown",
        Method = "none",
        Disabled = false,
        IsEncrypted = false
    }
    
    --// Get disabled state
    local success, disabled = pcall(function()
        return script.Disabled
    end)
    scriptData.Disabled = success and disabled or false
    
    --// Get source
    scriptData.Source, scriptData.Status, scriptData.Method = ScriptHandler.GetSource(script, clientInfo)
    
    --// Check if source appears encrypted
    if scriptData.Source then
        local lowerSource = scriptData.Source:lower()
        if lowerSource:find("loadstring") and lowerSource:find("http") then
            scriptData.IsEncrypted = true
            Logger.Info("Script", "Script appears to use remote loading: " .. scriptData.FullName)
        end
    end
    
    --// Update stats
    Logger.IncrementStat("ScriptsSaved")
    if scriptData.Status ~= "success" then
        Logger.IncrementStat("ScriptsEncrypted")
    end
    
    return scriptData
end

--[[
    Format script source for output
]]
function ScriptHandler.FormatSource(scriptData)
    local header = string.format([[
--[[
    Script: %s
    ClassName: %s
    Path: %s
    Status: %s
    Method: %s
    Disabled: %s
    Encrypted: %s
    Saved by BaoSaveInstance v%s
]]

]], 
        scriptData.Name,
        scriptData.ClassName,
        scriptData.FullName,
        scriptData.Status,
        scriptData.Method,
        tostring(scriptData.Disabled),
        tostring(scriptData.IsEncrypted),
        BaoSaveInstance.Version
    )
    
    return header .. (scriptData.Source or "")
end

BaoSaveInstance.ScriptHandler = ScriptHandler

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 7: TERRAIN HANDLER (CORE FEATURE)
--// ═══════════════════════════════════════════════════════════════════════════

local TerrainHandler = {}

TerrainHandler.ChunkSize = 64 -- Voxels per chunk dimension
TerrainHandler.MaxRegionSize = Vector3.new(1024, 512, 1024)

--// Material enum mapping
TerrainHandler.MaterialMap = {
    [Enum.Material.Air] = 0,
    [Enum.Material.Water] = 1,
    [Enum.Material.Grass] = 2,
    [Enum.Material.Slate] = 3,
    [Enum.Material.Concrete] = 4,
    [Enum.Material.Brick] = 5,
    [Enum.Material.Sand] = 6,
    [Enum.Material.Rock] = 7,
    [Enum.Material.Glacier] = 8,
    [Enum.Material.Snow] = 9,
    [Enum.Material.Sandstone] = 10,
    [Enum.Material.Mud] = 11,
    [Enum.Material.Basalt] = 12,
    [Enum.Material.Ground] = 13,
    [Enum.Material.CrackedLava] = 14,
    [Enum.Material.Asphalt] = 15,
    [Enum.Material.Cobblestone] = 16,
    [Enum.Material.Ice] = 17,
    [Enum.Material.LeafyGrass] = 18,
    [Enum.Material.Salt] = 19,
    [Enum.Material.Limestone] = 20,
    [Enum.Material.Pavement] = 21,
    [Enum.Material.WoodPlanks] = 22,
}

TerrainHandler.ReverseMaterialMap = {}
for material, id in pairs(TerrainHandler.MaterialMap) do
    TerrainHandler.ReverseMaterialMap[id] = material
end

--[[
    Get terrain bounds
]]
function TerrainHandler.GetTerrainBounds()
    local terrain = Workspace.Terrain
    
    local success, result = pcall(function()
        local minPos = Vector3.new(-16384, -512, -16384)
        local maxPos = Vector3.new(16384, 512, 16384)
        
        --// Try to get actual terrain region
        local region = Region3.new(minPos, maxPos)
        local materials, occupancy = terrain:ReadVoxels(region, 4)
        
        --// Find actual bounds
        local actualMin = Vector3.new(math.huge, math.huge, math.huge)
        local actualMax = Vector3.new(-math.huge, -math.huge, -math.huge)
        local hasContent = false
        
        local size = materials.Size
        for x = 1, size.X do
            for y = 1, size.Y do
                for z = 1, size.Z do
                    if materials[x][y][z] ~= Enum.Material.Air and occupancy[x][y][z] > 0 then
                        hasContent = true
                        local worldPos = minPos + Vector3.new((x-1)*4, (y-1)*4, (z-1)*4)
                        actualMin = Vector3.new(
                            math.min(actualMin.X, worldPos.X),
                            math.min(actualMin.Y, worldPos.Y),
                            math.min(actualMin.Z, worldPos.Z)
                        )
                        actualMax = Vector3.new(
                            math.max(actualMax.X, worldPos.X),
                            math.max(actualMax.Y, worldPos.Y),
                            math.max(actualMax.Z, worldPos.Z)
                        )
                    end
                end
            end
            Utilities.SafeYield() -- Prevent freeze
        end
        
        if hasContent then
            return {Min = actualMin, Max = actualMax, HasContent = true}
        else
            return {Min = Vector3.new(0,0,0), Max = Vector3.new(0,0,0), HasContent = false}
        end
    end)
    
    if success then
        return result
    else
        Logger.Warn("Terrain", "Could not get terrain bounds: " .. tostring(result))
        return {Min = Vector3.new(0,0,0), Max = Vector3.new(0,0,0), HasContent = false}
    end
end

--[[
    Read terrain chunk at specified position
]]
function TerrainHandler.ReadChunk(position, chunkSize, resolution)
    resolution = resolution or 4
    chunkSize = chunkSize or TerrainHandler.ChunkSize
    
    local terrain = Workspace.Terrain
    local halfSize = chunkSize * resolution / 2
    
    local region = Region3.new(
        position - Vector3.new(halfSize, halfSize, halfSize),
        position + Vector3.new(halfSize, halfSize, halfSize)
    )
    
    local success, materials, occupancy = pcall(function()
        return terrain:ReadVoxels(region:ExpandToGrid(resolution), resolution)
    end)
    
    if success then
        return {
            Position = position,
            Region = region,
            Resolution = resolution,
            Materials = materials,
            Occupancy = occupancy,
            Size = materials.Size
        }
    else
        Logger.Warn("Terrain", "Failed to read chunk at " .. tostring(position))
        return nil
    end
end

--[[
    Serialize terrain chunk to data format
]]
function TerrainHandler.SerializeChunk(chunkData)
    if not chunkData then return nil end
    
    local serialized = {
        Position = {
            X = chunkData.Position.X,
            Y = chunkData.Position.Y,
            Z = chunkData.Position.Z
        },
        Resolution = chunkData.Resolution,
        Size = {
            X = chunkData.Size.X,
            Y = chunkData.Size.Y,
            Z = chunkData.Size.Z
        },
        Materials = {},
        Occupancy = {}
    }
    
    --// Serialize materials and occupancy
    for x = 1, chunkData.Size.X do
        serialized.Materials[x] = {}
        serialized.Occupancy[x] = {}
        
        for y = 1, chunkData.Size.Y do
            serialized.Materials[x][y] = {}
            serialized.Occupancy[x][y] = {}
            
            for z = 1, chunkData.Size.Z do
                local material = chunkData.Materials[x][y][z]
                local occupancy = chunkData.Occupancy[x][y][z]
                
                --// Only save non-air voxels to reduce size
                if material ~= Enum.Material.Air and occupancy > 0 then
                    serialized.Materials[x][y][z] = TerrainHandler.MaterialMap[material] or 0
                    serialized.Occupancy[x][y][z] = math.floor(occupancy * 255)
                end
            end
        end
    end
    
    return serialized
end

--[[
    Compress serialized terrain data
]]
function TerrainHandler.CompressChunk(serializedData)
    --// Simple RLE compression for terrain data
    local compressed = {
        Position = serializedData.Position,
        Resolution = serializedData.Resolution,
        Size = serializedData.Size,
        Data = {}
    }
    
    local currentMaterial = nil
    local currentOccupancy = nil
    local runLength = 0
    
    for x = 1, serializedData.Size.X do
        for y = 1, serializedData.Size.Y do
            for z = 1, serializedData.Size.Z do
                local mat = serializedData.Materials[x] and 
                           serializedData.Materials[x][y] and 
                           serializedData.Materials[x][y][z] or 0
                local occ = serializedData.Occupancy[x] and 
                           serializedData.Occupancy[x][y] and 
                           serializedData.Occupancy[x][y][z] or 0
                
                if mat == currentMaterial and occ == currentOccupancy then
                    runLength = runLength + 1
                else
                    if currentMaterial ~= nil then
                        table.insert(compressed.Data, {
                            m = currentMaterial,
                            o = currentOccupancy,
                            l = runLength
                        })
                    end
                    currentMaterial = mat
                    currentOccupancy = occ
                    runLength = 1
                end
            end
        end
    end
    
    --// Don't forget last run
    if currentMaterial ~= nil then
        table.insert(compressed.Data, {
            m = currentMaterial,
            o = currentOccupancy,
            l = runLength
        })
    end
    
    return compressed
end

--[[
    Save entire terrain to data structure
]]
function TerrainHandler.SaveTerrain(clientInfo, onProgress)
    local terrainData = {
        Version = "1.0",
        SavedAt = os.time(),
        Chunks = {},
        Bounds = nil,
        TotalVoxels = 0,
        WaterColor = nil,
        TerrainSettings = {}
    }
    
    --// Get terrain properties
    local terrain = Workspace.Terrain
    
    local success, waterColor = pcall(function()
        return terrain.WaterColor
    end)
    if success then
        terrainData.WaterColor = {
            R = waterColor.R,
            G = waterColor.G,
            B = waterColor.B
        }
    end
    
    --// Try to get other terrain settings
    local terrainProps = {"WaterWaveSize", "WaterWaveSpeed", "WaterReflectance", "WaterTransparency"}
    for _, prop in ipairs(terrainProps) do
        local success2, value = pcall(function()
            return terrain[prop]
        end)
        if success2 then
            terrainData.TerrainSettings[prop] = value
        end
    end
    
    --// Check if client supports full voxel read
    local canReadVoxels = true
    local testSuccess = pcall(function()
        local testRegion = Region3.new(Vector3.new(0,0,0), Vector3.new(4,4,4))
        terrain:ReadVoxels(testRegion, 4)
    end)
    
    if not testSuccess then
        Logger.Warn("Terrain", "Client does not support ReadVoxels - using fallback")
        canReadVoxels = false
    end
    
    if canReadVoxels then
        --// Get terrain bounds
        Logger.Info("Terrain", "Scanning terrain bounds...")
        terrainData.Bounds = TerrainHandler.GetTerrainBounds()
        
        if not terrainData.Bounds.HasContent then
            Logger.Info("Terrain", "No terrain content found")
            return terrainData
        end
        
        --// Calculate chunks needed
        local bounds = terrainData.Bounds
        local chunkSize = TerrainHandler.ChunkSize * 4 -- In studs
        
        local chunksX = math.ceil((bounds.Max.X - bounds.Min.X) / chunkSize)
        local chunksY = math.ceil((bounds.Max.Y - bounds.Min.Y) / chunkSize)
        local chunksZ = math.ceil((bounds.Max.Z - bounds.Min.Z) / chunkSize)
        local totalChunks = chunksX * chunksY * chunksZ
        
        Logger.Info("Terrain", string.format("Saving %d chunks (%dx%dx%d)", totalChunks, chunksX, chunksY, chunksZ))
        
        local chunkIndex = 0
        for cx = 0, chunksX - 1 do
            for cy = 0, chunksY - 1 do
                for cz = 0, chunksZ - 1 do
                    chunkIndex = chunkIndex + 1
                    
                    local chunkPos = Vector3.new(
                        bounds.Min.X + (cx + 0.5) * chunkSize,
                        bounds.Min.Y + (cy + 0.5) * chunkSize,
                        bounds.Min.Z + (cz + 0.5) * chunkSize
                    )
                    
                    local chunk = TerrainHandler.ReadChunk(chunkPos, TerrainHandler.ChunkSize, 4)
                    if chunk then
                        local serialized = TerrainHandler.SerializeChunk(chunk)
                        if serialized then
                            local compressed = TerrainHandler.CompressChunk(serialized)
                            table.insert(terrainData.Chunks, compressed)
                            Logger.IncrementStat("TerrainChunksSaved")
                        end
                    end
                    
                    --// Progress callback
                    if onProgress then
                        onProgress(chunkIndex, totalChunks, math.floor((chunkIndex / totalChunks) * 100))
                    end
                    
                    --// Yield to prevent freeze
                    if chunkIndex % 10 == 0 then
                        Utilities.SafeYield()
                    end
                end
            end
        end
        
        Logger.Info("Terrain", "Terrain save completed: " .. #terrainData.Chunks .. " chunks")
    else
        --// Fallback for clients without ReadVoxels
        Logger.Warn("Terrain", "Using serialized terrain fallback")
        terrainData.FallbackMode = true
        
        --// Try to serialize terrain using CopyRegion if available
        local success2, result = pcall(function()
            local region = Region3.new(
                Vector3.new(-2048, -512, -2048),
                Vector3.new(2048, 512, 2048)
            )
            return terrain:CopyRegion(region)
        end)
        
        if success2 and result then
            terrainData.TerrainRegion = result
            Logger.Info("Terrain", "Terrain saved using CopyRegion")
        else
            Logger.Warn("Terrain", "Could not save terrain - no compatible method available")
        end
    end
    
    return terrainData
end

--[[
    Generate Lua code to reconstruct terrain
]]
function TerrainHandler.GenerateReconstructCode(terrainData)
    local code = [[
--[[
    BaoSaveInstance Terrain Reconstruction
    Generated at: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[
    
    Total Chunks: ]] .. #terrainData.Chunks .. [[
    
]]

    code = code .. [[

local TerrainData = ]] .. HttpService:JSONEncode(terrainData) .. [[

local function ReconstructTerrain()
    local terrain = workspace.Terrain
    
    -- Apply terrain settings
    if TerrainData.WaterColor then
        terrain.WaterColor = Color3.new(
            TerrainData.WaterColor.R,
            TerrainData.WaterColor.G,
            TerrainData.WaterColor.B
        )
    end
    
    for prop, value in pairs(TerrainData.TerrainSettings or {}) do
        pcall(function()
            terrain[prop] = value
        end)
    end
    
    -- Material lookup
    local MaterialLookup = {
        [0] = Enum.Material.Air,
        [1] = Enum.Material.Water,
        [2] = Enum.Material.Grass,
        [3] = Enum.Material.Slate,
        [4] = Enum.Material.Concrete,
        [5] = Enum.Material.Brick,
        [6] = Enum.Material.Sand,
        [7] = Enum.Material.Rock,
        [8] = Enum.Material.Glacier,
        [9] = Enum.Material.Snow,
        [10] = Enum.Material.Sandstone,
        [11] = Enum.Material.Mud,
        [12] = Enum.Material.Basalt,
        [13] = Enum.Material.Ground,
        [14] = Enum.Material.CrackedLava,
        [15] = Enum.Material.Asphalt,
        [16] = Enum.Material.Cobblestone,
        [17] = Enum.Material.Ice,
        [18] = Enum.Material.LeafyGrass,
        [19] = Enum.Material.Salt,
        [20] = Enum.Material.Limestone,
        [21] = Enum.Material.Pavement,
        [22] = Enum.Material.WoodPlanks,
    }
    
    -- Decompress and write chunks
    for i, chunk in ipairs(TerrainData.Chunks) do
        local pos = Vector3.new(chunk.Position.X, chunk.Position.Y, chunk.Position.Z)
        local size = Vector3.new(chunk.Size.X, chunk.Size.Y, chunk.Size.Z)
        local resolution = chunk.Resolution
        
        -- Create material and occupancy arrays
        local materials = {}
        local occupancy = {}
        
        for x = 1, size.X do
            materials[x] = {}
            occupancy[x] = {}
            for y = 1, size.Y do
                materials[x][y] = {}
                occupancy[x][y] = {}
                for z = 1, size.Z do
                    materials[x][y][z] = Enum.Material.Air
                    occupancy[x][y][z] = 0
                end
            end
        end
        
        -- Decompress RLE data
        local index = 1
        for _, run in ipairs(chunk.Data) do
            for _ = 1, run.l do
                local z = ((index - 1) % size.Z) + 1
                local y = (math.floor((index - 1) / size.Z) % size.Y) + 1
                local x = math.floor((index - 1) / (size.Y * size.Z)) + 1
                
                if x <= size.X and y <= size.Y and z <= size.Z then
                    materials[x][y][z] = MaterialLookup[run.m] or Enum.Material.Air
                    occupancy[x][y][z] = run.o / 255
                end
                index = index + 1
            end
        end
        
        -- Write to terrain
        local halfSize = size.X * resolution / 2
        local region = Region3.new(
            pos - Vector3.new(halfSize, halfSize, halfSize),
            pos + Vector3.new(halfSize, halfSize, halfSize)
        )
        
        pcall(function()
            terrain:WriteVoxels(region:ExpandToGrid(resolution), resolution, materials, occupancy)
        end)
        
        if i % 10 == 0 then
            task.wait()
        end
    end
    
    print("Terrain reconstruction completed!")
end

return ReconstructTerrain
]]

    return code
end

BaoSaveInstance.TerrainHandler = TerrainHandler

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 8: RBXLX GENERATOR
--// ═══════════════════════════════════════════════════════════════════════════

local RBXLXGenerator = {}

RBXLXGenerator.CurrentReferent = 0
RBXLXGenerator.ReferentMap = {}

--[[
    Generate unique referent ID
]]
function RBXLXGenerator.GetReferent(instance)
    if not RBXLXGenerator.ReferentMap[instance] then
        RBXLXGenerator.CurrentReferent = RBXLXGenerator.CurrentReferent + 1
        RBXLXGenerator.ReferentMap[instance] = "RBX" .. tostring(RBXLXGenerator.CurrentReferent)
    end
    return RBXLXGenerator.ReferentMap[instance]
end

--[[
    Reset referent counter
]]
function RBXLXGenerator.Reset()
    RBXLXGenerator.CurrentReferent = 0
    RBXLXGenerator.ReferentMap = {}
end

--[[
    Generate XML header
]]
function RBXLXGenerator.GenerateHeader()
    return [[<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
    <Meta name="ExplicitAutoJoints">true</Meta>
    <External>null</External>
    <External>nil</External>
]]
end

--[[
    Generate XML footer
]]
function RBXLXGenerator.GenerateFooter()
    return [[</roblox>
]]
end

--[[
    Map property type to XML type name
]]
function RBXLXGenerator.GetXMLTypeName(valueType)
    local typeMap = {
        ["string"] = "string",
        ["number"] = "float",
        ["boolean"] = "bool",
        ["Vector3"] = "Vector3",
        ["Vector2"] = "Vector2",
        ["CFrame"] = "CoordinateFrame",
        ["Color3"] = "Color3",
        ["BrickColor"] = "BrickColor",
        ["UDim"] = "UDim",
        ["UDim2"] = "UDim2",
        ["Rect"] = "Rect",
        ["NumberSequence"] = "NumberSequence",
        ["ColorSequence"] = "ColorSequence",
        ["NumberRange"] = "NumberRange",
        ["EnumItem"] = "token",
        ["Font"] = "Font",
        ["Instance"] = "Ref",
        ["Ray"] = "Ray",
        ["Faces"] = "Faces",
        ["Axes"] = "Axes",
        ["PhysicalProperties"] = "PhysicalProperties",
        ["Content"] = "Content"
    }
    
    return typeMap[valueType] or "string"
end

--[[
    Generate property XML
]]
function RBXLXGenerator.GeneratePropertyXML(propName, propData)
    local xmlType = RBXLXGenerator.GetXMLTypeName(propData.Type)
    local value = propData.Value
    
    --// Special handling for certain types
    if propData.Type == "Content" or (propData.Type == "string" and 
        (propName:find("Id") or propName:find("Texture") or propName:find("Sound") or propName:find("Image"))) then
        return string.format('            <%s name="%s">%s</%s>\n', 
            "Content", propName, value, "Content")
    end
    
    return string.format('            <%s name="%s">%s</%s>\n', 
        xmlType, propName, value, xmlType)
end

--[[
    Generate instance XML (recursive)
]]
function RBXLXGenerator.GenerateInstanceXML(instance, clientInfo, depth)
    depth = depth or 0
    local indent = string.rep("    ", depth)
    local xml = ""
    
    --// Get referent
    local referent = RBXLXGenerator.GetReferent(instance)
    
    --// Start item tag
    xml = xml .. string.format('%s<Item class="%s" referent="%s">\n', 
        indent, instance.ClassName, referent)
    
    --// Properties
    xml = xml .. indent .. "    <Properties>\n"
    
    --// Serialize properties
    local properties, attributes = PropertySerializer.SerializeInstance(
        instance, 
        RBXLXGenerator.ReferentMap, 
        clientInfo
    )
    
    --// Add Name property first
    xml = xml .. string.format('            <string name="Name">%s</string>\n', 
        Utilities.EscapeXML(instance.Name))
    
    --// Add other properties
    for propName, propData in pairs(properties) do
        if propName ~= "Name" then
            xml = xml .. RBXLXGenerator.GeneratePropertyXML(propName, propData)
        end
    end
    
    --// Add script source if applicable
    if instance:IsA("LuaSourceContainer") then
        local scriptData = ScriptHandler.ProcessScript(instance, clientInfo)
        local escapedSource = Utilities.EscapeXML(scriptData.Source or "")
        xml = xml .. string.format('            <ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>\n', 
            scriptData.Source or "")
    end
    
    xml = xml .. indent .. "    </Properties>\n"
    
    --// Add attributes if any
    if attributes and next(attributes) then
        xml = xml .. indent .. "    <Attributes>\n"
        for attrName, attrData in pairs(attributes) do
            local xmlType = RBXLXGenerator.GetXMLTypeName(attrData.Type)
            xml = xml .. string.format('            <%s name="%s">%s</%s>\n',
                xmlType, Utilities.EscapeXML(attrName), attrData.Value, xmlType)
        end
        xml = xml .. indent .. "    </Attributes>\n"
    end
    
    Logger.IncrementStat("InstancesSaved")
    
    --// Process children
    local children = {}
    local success, childList = pcall(function()
        return instance:GetChildren()
    end)
    
    if success then
        children = childList
    end
    
    for _, child in ipairs(children) do
        --// Skip certain instances
        if not child:IsA("Player") and 
           not child:IsA("Terrain") and 
           child.Name ~= "RobloxLocked" then
            xml = xml .. RBXLXGenerator.GenerateInstanceXML(child, clientInfo, depth + 1)
        end
        
        --// Yield occasionally
        if Logger.Stats.InstancesSaved % 100 == 0 then
            Utilities.SafeYield()
        end
    end
    
    --// Close item tag
    xml = xml .. indent .. "</Item>\n"
    
    return xml
end

--[[
    Generate full RBXLX content
]]
function RBXLXGenerator.Generate(instances, clientInfo, options)
    options = options or {}
    
    RBXLXGenerator.Reset()
    
    local xml = RBXLXGenerator.GenerateHeader()
    
    for _, instance in ipairs(instances) do
        xml = xml .. RBXLXGenerator.GenerateInstanceXML(instance, clientInfo, 1)
    end
    
    xml = xml .. RBXLXGenerator.GenerateFooter()
    
    return xml
end

BaoSaveInstance.RBXLXGenerator = RBXLXGenerator

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 9: FILE HANDLER
--// ═══════════════════════════════════════════════════════════════════════════

local FileHandler = {}

FileHandler.DefaultFolder = "BaoSaveInstance"

--[[
    Ensure folder exists
]]
function FileHandler.EnsureFolder(folderPath)
    if makefolder then
        local success, err = pcall(function()
            if isfolder and not isfolder(folderPath) then
                makefolder(folderPath)
            elseif not isfolder then
                makefolder(folderPath)
            end
        end)
        return success
    end
    return false
end

--[[
    Write file with error handling
]]
function FileHandler.WriteFile(filePath, content)
    if writefile then
        local success, err = pcall(function()
            writefile(filePath, content)
        end)
        
        if success then
            Logger.Info("File", "Saved: " .. filePath)
            return true
        else
            Logger.Error("File", "Failed to save " .. filePath .. ": " .. tostring(err))
            return false
        end
    else
        Logger.Error("File", "writefile not available")
        return false
    end
end

--[[
    Append to file
]]
function FileHandler.AppendFile(filePath, content)
    if appendfile then
        local success, err = pcall(function()
            appendfile(filePath, content)
        end)
        return success
    elseif readfile and writefile then
        local success, err = pcall(function()
            local existing = ""
            pcall(function()
                existing = readfile(filePath)
            end)
            writefile(filePath, existing .. content)
        end)
        return success
    end
    return false
end

--[[
    Read file
]]
function FileHandler.ReadFile(filePath)
    if readfile then
        local success, content = pcall(function()
            return readfile(filePath)
        end)
        
        if success then
            return content
        end
    end
    return nil
end

--[[
    Check if file exists
]]
function FileHandler.FileExists(filePath)
    if isfile then
        local success, result = pcall(function()
            return isfile(filePath)
        end)
        return success and result
    end
    return false
end

--[[
    Generate save path
]]
function FileHandler.GenerateSavePath(gameName, extension)
    local timestamp = Utilities.GetTimestamp()
    local safeName = gameName:gsub("[^%w%-_]", "_")
    local fileName = string.format("%s_%s.%s", safeName, timestamp, extension)
    return FileHandler.DefaultFolder .. "/" .. fileName
end

BaoSaveInstance.FileHandler = FileHandler

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 10: MAIN SAVE FUNCTION
--// ═══════════════════════════════════════════════════════════════════════════

--[[
    Default save options
]]
BaoSaveInstance.DefaultOptions = {
    --// What to save
    SaveWorkspace = true,
    SaveTerrain = true,
    SaveLighting = true,
    SaveReplicatedStorage = true,
    SaveServerStorage = false,        -- Usually can't access
    SaveServerScriptService = false,  -- Usually can't access
    SaveStarterGui = true,
    SaveStarterPack = true,
    SaveStarterPlayer = true,
    SaveSoundService = true,
    SaveChat = false,
    SavePlayers = false,
    SaveCamera = true,
    
    --// Script handling
    DecompileScripts = true,
    IgnoreDefaultScripts = true,
    
    --// Output options
    OutputFormat = "rbxlx",  -- "rbxlx" or "lua"
    SaveTerrainSeparately = true,
    GenerateMetadata = true,
    
    --// Performance
    BatchSize = 100,
    YieldInterval = 0.01,
    
    --// File options
    OutputFolder = "BaoSaveInstance",
    CustomFileName = nil,
    
    --// Filters
    IgnoreList = {},
    IgnoreClasses = {"Player", "PlayerScripts", "PlayerGui"},
    MaxDepth = 100
}

--[[
    Validate and merge options
]]
function BaoSaveInstance.MergeOptions(userOptions)
    local options = Utilities.DeepClone(BaoSaveInstance.DefaultOptions)
    
    if userOptions then
        for key, value in pairs(userOptions) do
            if options[key] ~= nil then
                options[key] = value
            end
        end
    end
    
    return options
end

--[[
    Get instances to save based on options
]]
function BaoSaveInstance.GetInstancesToSave(options)
    local instances = {}
    
    local serviceMap = {
        {enabled = options.SaveWorkspace, service = Workspace},
        {enabled = options.SaveLighting, service = Lighting},
        {enabled = options.SaveReplicatedStorage, service = ReplicatedStorage},
        {enabled = options.SaveStarterGui, service = StarterGui},
        {enabled = options.SaveStarterPack, service = StarterPack},
        {enabled = options.SaveStarterPlayer, service = StarterPlayer},
        {enabled = options.SaveSoundService, service = SoundService},
        {enabled = options.SaveChat, service = Chat},
    }
    
    --// Try to access ServerStorage and ServerScriptService
    if options.SaveServerStorage then
        local success, service = pcall(function()
            return game:GetService("ServerStorage")
        end)
        if success and service then
            table.insert(serviceMap, {enabled = true, service = service})
        else
            Logger.Warn("Save", "Cannot access ServerStorage")
        end
    end
    
    if options.SaveServerScriptService then
        local success, service = pcall(function()
            return game:GetService("ServerScriptService")
        end)
        if success and service then
            table.insert(serviceMap, {enabled = true, service = service})
        else
            Logger.Warn("Save", "Cannot access ServerScriptService")
        end
    end
    
    for _, item in ipairs(serviceMap) do
        if item.enabled and item.service then
            table.insert(instances, item.service)
        end
    end
    
    return instances
end

--[[
    Main save function
]]
function BaoSaveInstance.Save(target, gameName, userOptions)
    --// Reset logger
    Logger.Reset()
    
    --// Start timing
    local startTime = os.clock()
    
    --// Merge options
    local options = BaoSaveInstance.MergeOptions(userOptions)
    
    --// Detect client
    Logger.Info("Init", "Detecting exploit client...")
    local clientInfo = ClientDetector.Detect()
    
    if not clientInfo.IsSupported then
        Logger.Error("Init", "Unsupported exploit client detected")
        return false, "Unsupported client"
    end
    
    Logger.Info("Init", string.format("Detected: %s (Version: %s)", 
        clientInfo.Name, clientInfo.Version))
    
    --// Display capability info
    Logger.Info("Init", "Capabilities:")
    Logger.Info("Init", "  - Script Decompile: " .. tostring(clientInfo.Capabilities.Decompile))
    Logger.Info("Init", "  - Hidden Properties: " .. tostring(clientInfo.Capabilities.GetHiddenProperty))
    Logger.Info("Init", "  - Terrain Voxels: " .. tostring(clientInfo.Capabilities.TerrainVoxels))
    
    --// Ensure output folder exists
    FileHandler.EnsureFolder(options.OutputFolder)
    
    --// Determine what to save
    local instances = {}
    
    if target == game then
        instances = BaoSaveInstance.GetInstancesToSave(options)
        gameName = gameName or game.Name
    elseif typeof(target) == "Instance" then
        table.insert(instances, target)
        gameName = gameName or target.Name
    elseif typeof(target) == "table" then
        for _, inst in ipairs(target) do
            if typeof(inst) == "Instance" then
                table.insert(instances, inst)
            end
        end
        gameName = gameName or "MultiInstance"
    else
        Logger.Error("Save", "Invalid target type")
        return false, "Invalid target"
    end
    
    Logger.Info("Save", string.format("Saving %d root instances as '%s'", #instances, gameName))
    
    --// Initialize results
    local results = {
        Success = true,
        GameName = gameName,
        Client = clientInfo,
        Files = {},
        Terrain = nil,
        Stats = nil,
        Report = nil,
        Duration = 0
    }
    
    --// Save terrain first if enabled
    if options.SaveTerrain then
        Logger.Info("Terrain", "Starting terrain save...")
        
        local terrainData = TerrainHandler.SaveTerrain(clientInfo, function(current, total, percent)
            Logger.Debug("Terrain", string.format("Progress: %d/%d (%d%%)", current, total, percent))
        end)
        
        results.Terrain = terrainData
        
        if options.SaveTerrainSeparately and terrainData and #terrainData.Chunks > 0 then
            --// Save terrain reconstruction code
            local terrainCode = TerrainHandler.GenerateReconstructCode(terrainData)
            local terrainPath = FileHandler.GenerateSavePath(gameName .. "_Terrain", "lua")
            FileHandler.WriteFile(terrainPath, terrainCode)
            table.insert(results.Files, terrainPath)
            
            --// Save raw terrain data as JSON
            local terrainJsonPath = FileHandler.GenerateSavePath(gameName .. "_TerrainData", "json")
            local success, json = pcall(function()
                return HttpService:JSONEncode(terrainData)
            end)
            if success then
                FileHandler.WriteFile(terrainJsonPath, json)
                table.insert(results.Files, terrainJsonPath)
            end
        end
    end
    
    --// Generate RBXLX or Lua based on format
    if options.OutputFormat == "rbxlx" then
        Logger.Info("Save", "Generating RBXLX...")
        
        local rbxlxContent = RBXLXGenerator.Generate(instances, clientInfo, options)
        local rbxlxPath = FileHandler.GenerateSavePath(gameName, "rbxlx")
        
        if FileHandler.WriteFile(rbxlxPath, rbxlxContent) then
            table.insert(results.Files, rbxlxPath)
        else
            results.Success = false
        end
        
    elseif options.OutputFormat == "lua" then
        Logger.Info("Save", "Generating Lua reconstruction code...")
        
        --// Generate Lua reconstruction code (simplified version)
        local luaCode = BaoSaveInstance.GenerateLuaReconstruction(instances, clientInfo, options)
        local luaPath = FileHandler.GenerateSavePath(gameName, "lua")
        
        if FileHandler.WriteFile(luaPath, luaCode) then
            table.insert(results.Files, luaPath)
        else
            results.Success = false
        end
    end
    
    --// Generate metadata
    if options.GenerateMetadata then
        local endTime = os.clock()
        results.Duration = endTime - startTime
        results.Stats = Logger.Stats
        results.Report = Logger.GetReport()
        
        local metadata = {
            Version = BaoSaveInstance.Version,
            SavedAt = os.date("%Y-%m-%d %H:%M:%S"),
            GameName = gameName,
            GameId = game.GameId,
            PlaceId = game.PlaceId,
            Client = {
                Name = clientInfo.Name,
                Version = clientInfo.Version
            },
            Stats = results.Stats,
            Duration = results.Duration,
            Files = results.Files,
            Warnings = #Logger.Warnings,
            Errors = #Logger.Errors
        }
        
        local metaPath = FileHandler.GenerateSavePath(gameName .. "_Metadata", "json")
        local success, json = pcall(function()
            return HttpService:JSONEncode(metadata)
        end)
        if success then
            FileHandler.WriteFile(metaPath, json)
            table.insert(results.Files, metaPath)
        end
    end
    
    --// Final summary
    Logger.Info("Save", "═══════════════════════════════════════")
    Logger.Info("Save", "         SAVE COMPLETE")
    Logger.Info("Save", "═══════════════════════════════════════")
    Logger.Info("Save", string.format("Duration: %.2f seconds", results.Duration))
    Logger.Info("Save", string.format("Instances: %d", Logger.Stats.InstancesSaved))
    Logger.Info("Save", string.format("Scripts: %d (Encrypted: %d)", 
        Logger.Stats.ScriptsSaved, Logger.Stats.ScriptsEncrypted))
    Logger.Info("Save", string.format("Properties: %d (Failed: %d)", 
        Logger.Stats.PropertiesSaved, Logger.Stats.PropertiesFailed))
    Logger.Info("Save", string.format("Terrain Chunks: %d", Logger.Stats.TerrainChunksSaved))
    Logger.Info("Save", string.format("Warnings: %d | Errors: %d", 
        #Logger.Warnings, #Logger.Errors))
    Logger.Info("Save", "Files saved:")
    for _, filePath in ipairs(results.Files) do
        Logger.Info("Save", "  - " .. filePath)
    end
    Logger.Info("Save", "═══════════════════════════════════════")
    
    return results.Success, results
end

--[[
    Generate Lua reconstruction code
]]
function BaoSaveInstance.GenerateLuaReconstruction(instances, clientInfo, options)
    local code = [[
--[[
    BaoSaveInstance Lua Reconstruction
    Generated at: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[

    
    This file contains the structure and properties of saved instances.
    Run this script to reconstruct the game structure.
]]

local Reconstructor = {}

-- Instance data
Reconstructor.Instances = {}

]]

    local function serializeInstance(inst, depth)
        depth = depth or 0
        if depth > (options.MaxDepth or 100) then
            return "nil -- Max depth reached"
        end
        
        local props, attrs = PropertySerializer.SerializeInstance(inst, {}, clientInfo)
        
        local str = "{\n"
        str = str .. string.rep("    ", depth + 1) .. string.format('ClassName = "%s",\n', inst.ClassName)
        str = str .. string.rep("    ", depth + 1) .. string.format('Name = "%s",\n', Utilities.EscapeXML(inst.Name))
        
        --// Properties
        str = str .. string.rep("    ", depth + 1) .. "Properties = {\n"
        for propName, propData in pairs(props) do
            if propName ~= "Name" then
                local valueStr = propData.Value
                if propData.Type == "string" then
                    valueStr = string.format('"%s"', valueStr:gsub('"', '\\"'))
                end
                str = str .. string.rep("    ", depth + 2) .. string.format('%s = %s,\n', propName, valueStr)
            end
        end
        str = str .. string.rep("    ", depth + 1) .. "},\n"
        
        --// Children
        local children = {}
        pcall(function()
            children = inst:GetChildren()
        end)
        
        if #children > 0 then
            str = str .. string.rep("    ", depth + 1) .. "Children = {\n"
            for _, child in ipairs(children) do
                str = str .. string.rep("    ", depth + 2) .. serializeInstance(child, depth + 2) .. ",\n"
                
                if Logger.Stats.InstancesSaved % 50 == 0 then
                    Utilities.SafeYield()
                end
            end
            str = str .. string.rep("    ", depth + 1) .. "},\n"
        end
        
        str = str .. string.rep("    ", depth) .. "}"
        
        Logger.IncrementStat("InstancesSaved")
        
        return str
    end
    
    for i, inst in ipairs(instances) do
        code = code .. string.format("Reconstructor.Instances[%d] = ", i)
        code = code .. serializeInstance(inst, 0) .. "\n\n"
    end
    
    code = code .. [[

-- Reconstruction function
function Reconstructor.Build(parent)
    parent = parent or workspace
    
    local function createInstance(data, parentInstance)
        local success, instance = pcall(function()
            return Instance.new(data.ClassName)
        end)
        
        if not success then
            warn("Failed to create: " .. data.ClassName)
            return nil
        end
        
        -- Set name first
        instance.Name = data.Name
        
        -- Apply properties
        for propName, propValue in pairs(data.Properties or {}) do
            pcall(function()
                instance[propName] = propValue
            end)
        end
        
        -- Create children
        for _, childData in ipairs(data.Children or {}) do
            createInstance(childData, instance)
        end
        
        -- Set parent last
        instance.Parent = parentInstance
        
        return instance
    end
    
    for _, instanceData in ipairs(Reconstructor.Instances) do
        createInstance(instanceData, parent)
    end
    
    print("Reconstruction completed!")
end

return Reconstructor
]]

    return code
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 11: QUICK ACCESS FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════

--[[
    Quick save entire game
]]
function BaoSaveInstance.SaveGame(gameName, options)
    return BaoSaveInstance.Save(game, gameName, options)
end

--[[
    Quick save workspace only
]]
function BaoSaveInstance.SaveWorkspace(gameName, options)
    options = options or {}
    options.SaveWorkspace = true
    options.SaveLighting = false
    options.SaveReplicatedStorage = false
    options.SaveStarterGui = false
    options.SaveStarterPack = false
    options.SaveStarterPlayer = false
    return BaoSaveInstance.Save(Workspace, gameName, options)
end

--[[
    Quick save specific model
]]
function BaoSaveInstance.SaveModel(model, fileName, options)
    return BaoSaveInstance.Save(model, fileName, options)
end

--[[
    Quick save terrain only
]]
function BaoSaveInstance.SaveTerrainOnly(fileName, options)
    Logger.Reset()
    local clientInfo = ClientDetector.Detect()
    
    if not clientInfo.IsSupported then
        return false, "Unsupported client"
    end
    
    FileHandler.EnsureFolder(FileHandler.DefaultFolder)
    
    local terrainData = TerrainHandler.SaveTerrain(clientInfo, function(current, total, percent)
        Logger.Info("Terrain", string.format("Progress: %d%%", percent))
    end)
    
    if terrainData and #terrainData.Chunks > 0 then
        local terrainCode = TerrainHandler.GenerateReconstructCode(terrainData)
        local terrainPath = FileHandler.GenerateSavePath(fileName or "Terrain", "lua")
        return FileHandler.WriteFile(terrainPath, terrainCode), terrainPath
    end
    
    return false, "No terrain data"
end

--[[
    Get client info
]]
function BaoSaveInstance.GetClientInfo()
    return ClientDetector.Detect()
end

--[[
    Check compatibility
]]
function BaoSaveInstance.CheckCompatibility()
    local clientInfo = ClientDetector.Detect()
    
    print("═══════════════════════════════════════")
    print("    BaoSaveInstance Compatibility Check")
    print("═══════════════════════════════════════")
    print("Client: " .. clientInfo.Name)
    print("Version: " .. clientInfo.Version)
    print("Supported: " .. tostring(clientInfo.IsSupported))
    print("")
    print("Capabilities:")
    
    for capName, capValue in pairs(clientInfo.Capabilities) do
        local status = capValue and "✓" or "✗"
        print(string.format("  %s %s", status, capName))
    end
    
    print("═══════════════════════════════════════")
    
    return clientInfo
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 12: RETURN MODULE
--// ═══════════════════════════════════════════════════════════════════════════

return BaoSaveInstance
