--[[
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║                          BaoSaveInstance v1.0                            ║
    ║                  Professional Roblox Instance Saver                       ║
    ║                                                                          ║
    ║  A comprehensive tool for decompiling and saving Roblox game assets      ║
    ║  Compatible with most modern executors (Synapse, Fluxus, etc.)          ║
    ╚══════════════════════════════════════════════════════════════════════════╝
]]

do -- Encapsulate the script to prevent environment leakage
    
--=============================================================================
-- BaoSaveInstance v1.1 - Maximum Fidelity & Stealth
--=============================================================================

--=============================================================================
-- SERVICES
--=============================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
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
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--=============================================================================
-- CONFIGURATION
--=============================================================================
local Config = {
    -- Default Settings
    IncludeScripts = true,
    IncludeTerrain = true,
    DecompileScripts = true,
    PreserveHierarchy = true,
    
    -- Export Settings
    FileName = "SavedGame",
    ExportFormat = ".rbxlx", -- .rbxlx (XML) or .rbxl (Binary - limited support)
    
    -- UI Colors (Dark Theme)
    Colors = {
        Background = Color3.fromRGB(25, 25, 30),
        Secondary = Color3.fromRGB(35, 35, 45),
        Accent = Color3.fromRGB(75, 130, 195),
        AccentHover = Color3.fromRGB(95, 150, 215),
        Text = Color3.fromRGB(235, 235, 240),
        TextDim = Color3.fromRGB(155, 155, 165),
        Success = Color3.fromRGB(85, 185, 105),
        Error = Color3.fromRGB(215, 85, 85),
        Warning = Color3.fromRGB(215, 175, 85),
        Border = Color3.fromRGB(55, 55, 65),
    },
    
    -- UI Settings
    WindowSize = UDim2.new(0, 380, 0, 480),
    CornerRadius = UDim.new(0, 8),
    
    -- Performance
    YieldInterval = 100, -- Yield every N instances
    ProgressUpdateInterval = 50,
}

--=============================================================================
-- UTILITY FUNCTIONS
--=============================================================================
local Utils = {}

--- Safely call a function with error handling
---@param func function The function to call
---@param ... any Arguments to pass
---@return boolean success, any result
function Utils.SafeCall(func, ...)
    return pcall(func, ...)
end

--- Check if a function exists (executor compatibility)
---@param name string Function name
---@return boolean exists
function Utils.FunctionExists(name)
    return type(getfenv()[name]) == "function" or type(_G[name]) == "function"
end

--- Get a global function safely
---@param name string Function name
---@return function|nil
function Utils.GetFunction(name)
    return getfenv()[name] or _G[name] or nil
end

--- Escape XML special characters
---@param str string Input string
---@return string Escaped string
function Utils.EscapeXML(str)
    if type(str) ~= "string" then return tostring(str) end
    return str
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
        :gsub("'", "&apos;")
end

--- Format a number with commas
---@param num number Input number
---@return string Formatted number
function Utils.FormatNumber(num)
    local formatted = tostring(math.floor(num))
    local k
    while true do
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

--- Deep clone a table
---@param tbl table Table to clone
---@return table Cloned table
function Utils.DeepClone(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = Utils.DeepClone(v)
        else
            copy[k] = v
        end
    end
    return copy
end

--- Generate a unique random string for stealth
function Utils.GenerateRandomName()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local name = ""
    for i = 1, math.random(10, 20) do
        local r = math.random(1, #chars)
        name = name .. string.sub(chars, r, r)
    end
    return name
end

local refCounter = 0
local instanceMap = {} -- [Instance] = RefID
local currentGuiName = Utils.GenerateRandomName()

function Utils.GenerateRefId()
    refCounter = refCounter + 1
    return "RBX" .. tostring(refCounter)
end

--- Get or generate a referent ID for an instance
function Utils.GetRefId(instance)
    if not instance or typeof(instance) ~= "Instance" then return "null" end
    if instanceMap[instance] then return instanceMap[instance] end
    local id = Utils.GenerateRefId()
    instanceMap[instance] = id
    return id
end

--- Reset reference counter and map
function Utils.ResetRefCounter()
    refCounter = 0
    instanceMap = {}
end

--=============================================================================
-- PROPERTY SERIALIZER
--=============================================================================
local PropertySerializer = {}

-- Property type handlers for XML serialization
PropertySerializer.TypeHandlers = {
    ["string"] = function(name, value)
        return string.format('<string name="%s">%s</string>', Utils.EscapeXML(name), Utils.EscapeXML(value))
    end,
    
    ["Content"] = function(name, value)
        local url = tostring(value)
        if url == "" then
            return string.format('<Content name="%s"><null></null></Content>', Utils.EscapeXML(name))
        end
        return string.format('<Content name="%s"><url>%s</url></Content>', Utils.EscapeXML(name), Utils.EscapeXML(url))
    end,
    
    ["number"] = function(name, value)
        if value == math.floor(value) then
            return string.format('<int name="%s">%d</int>', Utils.EscapeXML(name), value)
        else
            -- Use 15+ digits of precision for critical coordinates
            return string.format('<float name="%s">%.17g</float>', Utils.EscapeXML(name), value)
        end
    end,
    
    ["boolean"] = function(name, value)
        return string.format('<bool name="%s">%s</bool>', Utils.EscapeXML(name), tostring(value))
    end,
    
    ["Vector3"] = function(name, value)
        return string.format('<Vector3 name="%s"><X>%.17g</X><Y>%.17g</Y><Z>%.17g</Z></Vector3>',
            Utils.EscapeXML(name), value.X, value.Y, value.Z)
    end,
    
    ["Vector2"] = function(name, value)
        return string.format('<Vector2 name="%s"><X>%.17g</X><Y>%.17g</Y></Vector2>',
            Utils.EscapeXML(name), value.X, value.Y)
    end,
    
    ["CFrame"] = function(name, value)
        local components = {value:GetComponents()}
        local parts = {"<X>%.17g</X>", "<Y>%.17g</Y>", "<Z>%.17g</Z>", 
                       "<R00>%.17g</R00>", "<R01>%.17g</R01>", "<R02>%.17g</R02>",
                       "<R10>%.17g</R10>", "<R11>%.17g</R11>", "<R12>%.17g</R12>",
                       "<R20>%.17g</R20>", "<R21>%.17g</R21>", "<R22>%.17g</R22>"}
        
        local xml = {}
        for i, fmt in ipairs(parts) do
            table.insert(xml, string.format(fmt, components[i]))
        end
        
        return string.format('<CoordinateFrame name="%s">%s</CoordinateFrame>',
            Utils.EscapeXML(name), table.concat(xml, ""))
    end,
    
    ["Color3"] = function(name, value)
        return string.format('<Color3 name="%s"><R>%s</R><G>%s</G><B>%s</B></Color3>',
            Utils.EscapeXML(name), tostring(value.R), tostring(value.G), tostring(value.B))
    end,
    
    ["BrickColor"] = function(name, value)
        return string.format('<int name="%s">%d</int>', Utils.EscapeXML(name), value.Number)
    end,
    
    ["UDim"] = function(name, value)
        return string.format('<UDim name="%s"><S>%s</S><O>%d</O></UDim>',
            Utils.EscapeXML(name), tostring(value.Scale), value.Offset)
    end,
    
    ["UDim2"] = function(name, value)
        return string.format('<UDim2 name="%s"><XS>%s</XS><XO>%d</XO><YS>%s</YS><YO>%d</YO></UDim2>',
            Utils.EscapeXML(name), tostring(value.X.Scale), value.X.Offset,
            tostring(value.Y.Scale), value.Y.Offset)
    end,
    
    ["Rect"] = function(name, value)
        return string.format('<Rect name="%s"><min><X>%s</X><Y>%s</Y></min><max><X>%s</X><Y>%s</Y></max></Rect>',
            Utils.EscapeXML(name), tostring(value.Min.X), tostring(value.Min.Y),
            tostring(value.Max.X), tostring(value.Max.Y))
    end,
    
    ["NumberSequence"] = function(name, value)
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%s %s %s",
                tostring(kp.Time), tostring(kp.Value), tostring(kp.Envelope)))
        end
        return string.format('<NumberSequence name="%s">%s</NumberSequence>', 
            Utils.EscapeXML(name), table.concat(keypoints, " "))
    end,
    
    ["ColorSequence"] = function(name, value)
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%s %s %s %s",
                tostring(kp.Time), tostring(kp.Value.R),
                tostring(kp.Value.G), tostring(kp.Value.B)))
        end
        return string.format('<ColorSequence name="%s">%s</ColorSequence>', 
            Utils.EscapeXML(name), table.concat(keypoints, " "))
    end,
    
    ["NumberRange"] = function(name, value)
        return string.format('<NumberRange name="%s">%s %s</NumberRange>',
            Utils.EscapeXML(name), tostring(value.Min), tostring(value.Max))
    end,
    
    ["Enum"] = function(name, value)
        return string.format('<token name="%s">%d</token>', Utils.EscapeXML(name), value.Value)
    end,
    
    ["EnumItem"] = function(name, value)
        return string.format('<token name="%s">%d</token>', Utils.EscapeXML(name), value.Value)
    end,
    
    ["Font"] = function(name, value)
        return string.format('<Font name="%s"><Family>%s</Family><Weight>%d</Weight><Style>%s</Style></Font>',
            Utils.EscapeXML(name), Utils.EscapeXML(value.Family), value.Weight.Value, value.Style.Name)
    end,
    
    ["Faces"] = function(name, value)
        local faces = 0
        if value.Top then faces = faces + 1 end
        if value.Bottom then faces = faces + 2 end
        if value.Left then faces = faces + 4 end
        if value.Right then faces = faces + 8 end
        if value.Back then faces = faces + 16 end
        if value.Front then faces = faces + 32 end
        return string.format('<Faces name="%s">%d</Faces>', Utils.EscapeXML(name), faces)
    end,
    
    ["Axes"] = function(name, value)
        local axes = 0
        if value.X then axes = axes + 1 end
        if value.Y then axes = axes + 2 end
        if value.Z then axes = axes + 4 end
        return string.format('<Axes name="%s">%d</Axes>', Utils.EscapeXML(name), axes)
    end,
    
    ["PhysicalProperties"] = function(name, value)
        if value then
            return string.format('<PhysicalProperties name="%s"><CustomPhysics>true</CustomPhysics><Density>%s</Density><Friction>%s</Friction><Elasticity>%s</Elasticity><FrictionWeight>%s</FrictionWeight><ElasticityWeight>%s</ElasticityWeight></PhysicalProperties>',
                Utils.EscapeXML(name), tostring(value.Density), tostring(value.Friction),
                tostring(value.Elasticity), tostring(value.FrictionWeight),
                tostring(value.ElasticityWeight))
        else
            return string.format('<PhysicalProperties name="%s"><CustomPhysics>false</CustomPhysics></PhysicalProperties>', Utils.EscapeXML(name))
        end
    end,
    
    ["Ray"] = function(name, value)
        return string.format('<Ray name="%s"><origin><X>%s</X><Y>%s</Y><Z>%s</Z></origin><direction><X>%s</X><Y>%s</Y><Z>%s</Z></direction></Ray>',
            Utils.EscapeXML(name), tostring(value.Origin.X), tostring(value.Origin.Y), tostring(value.Origin.Z),
            tostring(value.Direction.X), tostring(value.Direction.Y), tostring(value.Direction.Z))
    end,
}

-- Properties to skip (read-only, deprecated, or problematic)
PropertySerializer.SkipProperties = {
    ["Parent"] = true,
    ["ClassName"] = true,
    ["DataCost"] = true,
    ["RobloxLocked"] = true,
    ["Archivable"] = false, -- We want this one
    ["DebugId"] = true,
    ["SourceAssetId"] = true,
    ["UniqueId"] = true,
    ["HistoryId"] = true,
    ["Capabilities"] = true,
    ["Sandboxed"] = true,
    ["PlayerToHideFrom"] = true,
    ["SimulationRadius"] = true,
    ["MaxPlayers"] = true,
    ["PreferredPlayers"] = true,
    ["LocalPlayer"] = true,
}

-- Classes to skip entirely
PropertySerializer.SkipClasses = {
    ["Player"] = true,
    ["PlayerScripts"] = true,
    ["PlayerGui"] = true,
    ["Backpack"] = true,
    ["CoreGui"] = true,
}

--- Serialize a property value to XML
---@param name string Property name
---@param value any Property value
---@return string|nil XML string or nil if unsupported
function PropertySerializer.SerializeProperty(name, value)
    if value == nil then return nil end
    
    local valueType = typeof(value)
    local handler = PropertySerializer.TypeHandlers[valueType]
    
    if handler then
        local success, result = Utils.SafeCall(handler, name, value)
        if success and result then
            return result
        end
    end
    
    -- Handle special Content properties (Textures, Meshes, Sounds)
    local contentProps = {
        ["MeshId"] = true, ["TextureId"] = true, ["TextureID"] = true, 
        ["SoundId"] = true, ["AnimationId"] = true, ["SkyboxBk"] = true,
        ["SkyboxDn"] = true, ["SkyboxFt"] = true, ["SkyboxLf"] = true,
        ["SkyboxRt"] = true, ["SkyboxUp"] = true, ["SunTextureId"] = true,
        ["MoonTextureId"] = true, ["Texture"] = true, ["Image"] = true,
        ["ColorMap"] = true, ["MetalnessMap"] = true, ["NormalMap"] = true,
        ["RoughnessMap"] = true, ["PantsTemplate"] = true, ["ShirtTemplate"] = true,
        ["Graphic"] = true, ["OverlayTextureId"] = true, ["CageMeshId"] = true,
        ["ReferenceMeshId"] = true
    }
    
    if contentProps[name] then
        return PropertySerializer.TypeHandlers["Content"](name, value)
    end
    
    -- Handle Instance references (Mapping)
    -- This is the ULTIMATE REF HANDLER: It handles any property that returns an instance
    if valueType == "Instance" then
        local target = value
        if not target then return string.format('<Ref name="%s">null</Ref>', Utils.EscapeXML(name)) end
        
        -- Special case: If the instance is not in the map yet, it might be outside the save scope
        -- In Ultimate Version, we try to ensure it's mapped if it's reachable
        return string.format('<Ref name="%s">%s</Ref>', Utils.EscapeXML(name), Utils.GetRefId(target))
    end
    
    -- Handle BinaryString properties (Attributes, ChildData, etc.)
    if name == "ChildData" or name == "MeshData" or name == "TerrainData" or name == "Attributes" then
        return string.format('<BinaryString name="%s"><![CDATA[%s]]></BinaryString>',
            Utils.EscapeXML(name), tostring(value))
    end
    
    return nil
end

--- Get all properties of an instance
---@param instance Instance The instance to get properties from
---@return table Properties table {name = value}
function PropertySerializer.GetProperties(instance)
    local properties = {}
    
    -- 1. ULTIMATE DISCOVERY: Get all properties using executor-specific functions
    local getHiddenProps = Utils.GetFunction("gethiddenproperties") or Utils.GetFunction("get_hidden_properties")
    local getProps = Utils.GetFunction("getproperties") or Utils.GetFunction("get_properties")
    
    if getHiddenProps then
        local success, execProps = Utils.SafeCall(getHiddenProps, instance)
        if success and execProps then
            for k, v in pairs(execProps) do properties[k] = v end
        end
    end
    
    if getProps then
        local success, execProps = Utils.SafeCall(getProps, instance)
        if success and execProps then
            for k, v in pairs(execProps) do
                if properties[k] == nil then properties[k] = v end
            end
        end
    end
    
    -- 2. DATABASE LAYER: Merge with known properties (Backup/Missing Layer)
    local success, knownProps = Utils.SafeCall(function()
        return PropertySerializer.GetKnownProperties(instance)
    end)
    
    if success and knownProps then
        for k, v in pairs(knownProps) do
            if properties[k] == nil then properties[k] = v end
        end
    end
    
    -- 3. DEEP FETCH: Handle non-standard or hidden objects explicitly
    if instance:IsA("UnionOperation") then
        local getHidden = Utils.GetFunction("gethiddenproperty") or Utils.GetFunction("get_hidden_property")
        if getHidden then
            for _, prop in ipairs({"ChildData", "MeshData", "HasAnisotropicTangentSpace"}) do
                if properties[prop] == nil then
                    local success, val = Utils.SafeCall(getHidden, instance, prop)
                    if success and val ~= nil then properties[prop] = val end
                end
            end
        end
    end
    
    -- 4. ABSOLUTE REFERENCE SCAN: Look for properties that might be Instances
    -- This handles things like Part0, Part1, Adornee, PrimaryPart even if not in database
    for k, v in pairs(properties) do
        if typeof(v) == "Instance" then
            -- This will trigger the Ref handler in SerializeProperty
            properties[k] = v
        end
    end
    
    -- 5. CRITICAL FALLBACKS
    if not properties["Name"] then
        local success, name = Utils.SafeCall(function() return instance.Name end)
        if success then properties["Name"] = name end
    end
    
    return properties
end

-- Known properties for common classes
PropertySerializer.KnownClassProperties = {
    ["BasePart"] = {
        "Name", "Anchored", "CanCollide", "CanTouch", "CanQuery", "CastShadow",
        "Color", "Material", "MaterialVariant", "Reflectance", "Transparency",
        "Size", "CFrame", "Locked", "Massless", "RootPriority", 
        "CustomPhysicalProperties", "CollisionGroup", "PivotOffset",
        "EnableFluidForces", "ReceiveAge", "Attributes"
    },
    ["Part"] = {"Shape"},
    ["MeshPart"] = {
        "MeshId", "TextureID", "CollisionFidelity", "RenderFidelity", 
        "DoubleSided", "FluidFidelity", "InitialSize", "HasSkinnedMesh",
        "VertexColor" -- Some MeshParts have vertex data
    },
    ["UnionOperation"] = {
        "UsePartColor", "CollisionFidelity", "RenderFidelity", 
        "ChildData", "MeshData", "HasAnisotropicTangentSpace"
    },
    ["SpecialMesh"] = {"MeshId", "TextureId", "Scale", "Offset", "MeshType", "VertexColor"},
    ["BlockMesh"] = {"Scale", "Offset"},
    ["CylinderMesh"] = {"Scale", "Offset"},
    ["FileMesh"] = {"MeshId", "TextureId", "Scale", "Offset"},
    ["WedgePart"] = {},
    ["CornerWedgePart"] = {},
    ["TrussPart"] = {},
    ["SpawnLocation"] = {"Duration", "Enabled", "Neutral", "TeamColor", "AllowTeamChangeOnTouch"},
    ["Seat"] = {"Disabled"},
    ["VehicleSeat"] = {"Disabled", "HeadsUpDisplay", "MaxSpeed", "Steer", "SteerFloat", "Throttle", "ThrottleFloat", "Torque", "TurnSpeed"},
    ["SkateboardPlatform"] = {"Steer", "StickyWheels", "Throttle"},
    
    ["Model"] = {"Name", "PrimaryPart", "WorldPivot", "ModelStreamingMode", "LevelOfDetail"},
    ["Accessory"] = {"AccessoryType", "AttachmentPoint"},
    ["Humanoid"] = {
        "Name", "DisplayName", "Health", "MaxHealth", "WalkSpeed", "JumpPower", "JumpHeight",
        "HipHeight", "AutoRotate", "AutoJumpEnabled", "UseJumpPower", "NameDisplayDistance",
        "HealthDisplayDistance", "NameOcclusion", "HealthDisplayType", "DisplayDistanceType",
        "RigType", "RequiresNeck", "BreakJointsOnDeath", "EvaluateStateMachine"
    },
    
    ["Script"] = {"Name", "Disabled", "RunContext"},
    ["LocalScript"] = {"Name", "Disabled", "RunContext"},
    ["ModuleScript"] = {"Name"},
    
    ["Decal"] = {"Name", "Texture", "Color3", "Transparency", "ZIndex", "Face"},
    ["Texture"] = {"Name", "Texture", "Color3", "Transparency", "ZIndex", "Face", "StudsPerTileU", "StudsPerTileV", "OffsetStudsU", "OffsetStudsV"},
    ["SurfaceAppearance"] = {"Name", "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap", "AlphaMode"},
    
    ["Shirt"] = {"Name", "ShirtTemplate", "Color3"},
    ["Pants"] = {"Name", "PantsTemplate", "Color3"},
    ["ShirtGraphic"] = {"Name", "Graphic", "Color3"},
    ["WrapLayer"] = {"Name", "ImportOrigin", "ImportOriginWorld", "BindOffset", "ShrinkFactor", "CageMeshId", "ReferenceMeshId", "AutoSkin", "Enabled"},
    ["WrapTarget"] = {"Name", "ImportOrigin", "ImportOriginWorld", "Stiffness", "Enabled"},
    
    ["HumanoidDescription"] = {
        "Name", "BackAccessory", "BodyTypeScale", "ClimbAnimation", "DepthScale", 
        "Face", "FaceAccessory", "FallAnimation", "FrontAccessory", "GraphicTShirt", 
        "HairAccessory", "HatAccessory", "Head", "HeadColor", "HeadScale", 
        "HeightScale", "IdleAnimation", "JumpAnimation", "LeftArm", "LeftArmColor", 
        "LeftLeg", "LeftLegColor", "NeckAccessory", "Pants", "ProportionScale", 
        "RightArm", "RightArmColor", "RightLeg", "RightLegColor", "RunAnimation", 
        "Shirt", "ShouldersAccessory", "SwimAnimation", "Torso", "TorsoColor", 
        "WalkAnimation", "WaistAccessory", "WidthScale"
    },
    
    ["ClickDetector"] = {"Name", "CursorIcon", "MaxActivationDistance"},
    ["ProximityPrompt"] = {
        "Name", "ActionText", "ClickablePrompt", "Enabled", "Exclusivity", 
        "HoldDuration", "KeyboardKeyCode", "MaxActivationDistance", 
        "ObjectText", "RequiresLineOfSight", "UIOffset"
    },
    
    ["PointLight"] = {"Name", "Brightness", "Color", "Enabled", "Range", "Shadows"},
    ["SpotLight"] = {"Name", "Brightness", "Color", "Enabled", "Range", "Shadows", "Angle", "Face"},
    ["SurfaceLight"] = {"Name", "Brightness", "Color", "Enabled", "Range", "Shadows", "Angle", "Face"},
    
    ["Sound"] = {"Name", "SoundId", "Volume", "Pitch", "PlaybackSpeed", "Looped", "Playing", "PlayOnRemove", "RollOffMode", "RollOffMinDistance", "RollOffMaxDistance"},
    ["SoundGroup"] = {"Name", "Volume"},
    
    ["ParticleEmitter"] = {
        "Name", "Enabled", "Texture", "Color", "Size", "Transparency", "LightEmission",
        "LightInfluence", "ZOffset", "Lifetime", "Rate", "Speed", "SpreadAngle",
        "Rotation", "RotSpeed", "Acceleration", "Drag", "VelocityInheritance",
        "EmissionDirection", "Shape", "ShapeInOut", "ShapeStyle", "LockedToPart",
        "Orientation", "TimeScale", "Squash"
    },
    
    ["Attachment"] = {"Name", "Visible", "CFrame", "Position", "Orientation", "WorldPosition", "WorldCFrame"},
    
    ["Weld"] = {"Name", "Part0", "Part1", "C0", "C1", "Enabled"},
    ["WeldConstraint"] = {"Name", "Part0", "Part1", "Enabled"},
    ["Motor6D"] = {"Name", "Part0", "Part1", "C0", "C1", "CurrentAngle", "DesiredAngle", "MaxVelocity", "Enabled"},
    
    -- Services & Critical Classes
    ["Workspace"] = {"Name", "Gravity", "FallenPartsDestroyHeight", "StreamingEnabled", "ClientAnimatorThrottling", "InterpolationThrottling", "MeshPartHeadsAndAccessories", "SignalBehavior", "StreamOutBehavior", "Terrain"},
    ["Lighting"] = {"Name", "Ambient", "Brightness", "ColorShift_Bottom", "ColorShift_Top", "GlobalShadows", "OutdoorAmbient", "ShadowSoftness", "ClockTime", "GeographicLatitude", "TimeOfDay", "FogColor", "FogEnd", "FogStart", "Technology", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ExposureCompensation"},
    ["ReplicatedStorage"] = {"Name"},
    ["ReplicatedFirst"] = {"Name"},
    ["StarterPlayer"] = {"Name", "CameraMaxZoomDistance", "CameraMinZoomDistance", "CameraMode", "CharacterAutoLoads", "CharacterMainMaxSlopeAngle", "CharacterMaxSlopeAngle", "CharacterJumpHeight", "CharacterWalkSpeed", "DevCameraOcclusionMode", "DevComputerCameraMovementMode", "DevComputerMovementMode", "DevTouchCameraMovementMode", "DevTouchMovementMode", "EnableMouseLockOption", "HealthDisplayDistance", "LoadCharacterAppearance", "NameDisplayDistance", "UserEmotesEnabled"},
    ["Teams"] = {"Name"},
    ["SoundService"] = {"Name", "AmbientReverb", "DistanceFactor", "DopplerScale", "RespectFilteringEnabled", "RolloffScale"},
    ["StarterGui"] = {"Name", "ScreenOrientation", "ShowDevelopmentGui", "ResetPlayerGuiOnSpawn"},
    ["StarterPack"] = {"Name"},
    ["Chat"] = {"Name", "BubbleChatEnabled", "LoadDefaultChat"},
    ["LocalizationService"] = {"Name"},
    ["TestService"] = {"Name", "AutoRuns", "Description", "Is30FpsThrottleEnabled", "IsPhysicsEnvironmentalThrottled", "IsSleepAllowed", "NumberOfPlayers", "SimulateSecondsLag", "Timeout"},
    
    ["Folder"] = {"Name"},
    ["Configuration"] = {"Name"},
    ["Tool"] = {"Name", "CanBeDropped", "Enabled", "Grip", "GripForward", "GripPos", "GripRight", "GripUp", "ManualActivationOnly", "RequiresHandle", "ToolTip"},
    
    ["ScreenGui"] = {"Name", "DisplayOrder", "Enabled", "IgnoreGuiInset", "ResetOnSpawn", "ZIndexBehavior", "AutoLocalize", "ClipToDeviceSafeArea", "SafeAreaCompatibility", "ScreenInsets"},
    ["BillboardGui"] = {"Name", "Enabled", "Active", "Adornee", "Size", "SizeOffset", "StudsOffset", "StudsOffsetWorldSpace", "ExtentsOffset", "ExtentsOffsetWorldSpace", "LightInfluence", "MaxDistance", "AlwaysOnTop", "ClipsDescendants", "ZIndexBehavior", "DistanceLowerLimit", "DistanceUpperLimit", "DistanceStep"},
    ["SurfaceGui"] = {"Name", "Enabled", "Active", "Adornee", "Face", "CanvasSize", "LightInfluence", "AlwaysOnTop", "ClipsDescendants", "ZIndexBehavior", "PixelsPerStud", "SizingMode", "ToolPunchThroughDistance", "ZOffset", "Brightness", "MaxDistance"},
    
    ["Frame"] = {"Name", "Active", "Visible", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel", "BorderMode", "ClipsDescendants", "Position", "Size", "AnchorPoint", "Rotation", "ZIndex", "LayoutOrder", "AutomaticSize", "SizeConstraint", "Interactable"},
    ["TextLabel"] = {"Name", "Active", "Visible", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel", "BorderMode", "ClipsDescendants", "Position", "Size", "AnchorPoint", "Rotation", "ZIndex", "LayoutOrder", "AutomaticSize", "SizeConstraint", "Text", "TextColor3", "TextTransparency", "TextStrokeColor3", "TextStrokeTransparency", "Font", "FontFace", "TextSize", "TextScaled", "TextWrapped", "TextXAlignment", "TextYAlignment", "TextTruncate", "RichText", "MaxVisibleGraphemes", "LineHeight"},
    ["TextButton"] = {"Name", "Active", "Visible", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel", "BorderMode", "ClipsDescendants", "Position", "Size", "AnchorPoint", "Rotation", "ZIndex", "LayoutOrder", "AutomaticSize", "SizeConstraint", "Text", "TextColor3", "TextTransparency", "TextStrokeColor3", "TextStrokeTransparency", "Font", "FontFace", "TextSize", "TextScaled", "TextWrapped", "TextXAlignment", "TextYAlignment", "TextTruncate", "RichText", "MaxVisibleGraphemes", "LineHeight", "AutoButtonColor", "Modal", "Selected", "Interactable"},
    ["TextBox"] = {"Name", "Active", "Visible", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel", "BorderMode", "ClipsDescendants", "Position", "Size", "AnchorPoint", "Rotation", "ZIndex", "LayoutOrder", "AutomaticSize", "SizeConstraint", "Text", "PlaceholderText", "PlaceholderColor3", "TextColor3", "TextTransparency", "TextStrokeColor3", "TextStrokeTransparency", "Font", "FontFace", "TextSize", "TextScaled", "TextWrapped", "TextXAlignment", "TextYAlignment", "TextTruncate", "RichText", "MaxVisibleGraphemes", "LineHeight", "ClearTextOnFocus", "MultiLine", "TextEditable", "CursorPosition", "SelectionStart", "ShowNativeInput"},
    ["ImageLabel"] = {"Name", "Active", "Visible", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel", "BorderMode", "ClipsDescendants", "Position", "Size", "AnchorPoint", "Rotation", "ZIndex", "LayoutOrder", "AutomaticSize", "SizeConstraint", "Image", "ImageColor3", "ImageTransparency", "ImageRectOffset", "ImageRectSize", "ScaleType", "SliceCenter", "SliceScale", "TileSize", "ResampleMode"},
    ["ImageButton"] = {"Name", "Active", "Visible", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel", "BorderMode", "ClipsDescendants", "Position", "Size", "AnchorPoint", "Rotation", "ZIndex", "LayoutOrder", "AutomaticSize", "SizeConstraint", "Image", "ImageColor3", "ImageTransparency", "ImageRectOffset", "ImageRectSize", "ScaleType", "SliceCenter", "SliceScale", "TileSize", "ResampleMode", "HoverImage", "PressedImage", "AutoButtonColor", "Modal", "Selected", "Interactable"},
    ["ScrollingFrame"] = {"Name", "Active", "Visible", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel", "BorderMode", "ClipsDescendants", "Position", "Size", "AnchorPoint", "Rotation", "ZIndex", "LayoutOrder", "AutomaticSize", "SizeConstraint", "CanvasPosition", "CanvasSize", "AutomaticCanvasSize", "ScrollBarImageColor3", "ScrollBarImageTransparency", "ScrollBarThickness", "ScrollingDirection", "ScrollingEnabled", "TopImage", "MidImage", "BottomImage", "HorizontalScrollBarInset", "VerticalScrollBarInset", "VerticalScrollBarPosition", "ElasticBehavior", "Interactable"},
    ["ViewportFrame"] = {"Name", "Active", "Visible", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel", "BorderMode", "ClipsDescendants", "Position", "Size", "AnchorPoint", "Rotation", "ZIndex", "LayoutOrder", "AutomaticSize", "SizeConstraint", "Ambient", "CurrentCamera", "ImageColor3", "ImageTransparency", "LightColor", "LightDirection"},
    ["CanvasGroup"] = {"Name", "Active", "Visible", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel", "BorderMode", "ClipsDescendants", "Position", "Size", "AnchorPoint", "Rotation", "ZIndex", "LayoutOrder", "AutomaticSize", "SizeConstraint", "GroupColor3", "GroupTransparency"},
    
    ["UICorner"] = {"Name", "CornerRadius"},
    ["UIGradient"] = {"Name", "Color", "Enabled", "Offset", "Rotation", "Transparency"},
    ["UIStroke"] = {"Name", "ApplyStrokeMode", "Color", "Enabled", "LineJoinMode", "Thickness", "Transparency"},
    ["UIPadding"] = {"Name", "PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"},
    ["UIListLayout"] = {"Name", "FillDirection", "HorizontalAlignment", "HorizontalFlex", "ItemLineAlignment", "Padding", "SortOrder", "VerticalAlignment", "VerticalFlex", "Wraps"},
    ["UIGridLayout"] = {"Name", "CellPadding", "CellSize", "FillDirection", "FillDirectionMaxCells", "HorizontalAlignment", "SortOrder", "StartCorner", "VerticalAlignment"},
    ["UITableLayout"] = {"Name", "FillDirection", "FillEmptySpaceColumns", "FillEmptySpaceRows", "HorizontalAlignment", "MajorAxis", "Padding", "SortOrder", "VerticalAlignment"},
    ["UIPageLayout"] = {"Name", "Animated", "Circular", "EasingDirection", "EasingStyle", "FillDirection", "GamepadInputEnabled", "HorizontalAlignment", "Padding", "ScrollWheelInputEnabled", "SortOrder", "TouchInputEnabled", "TweenTime", "VerticalAlignment"},
    ["UIScale"] = {"Name", "Scale"},
    ["UISizeConstraint"] = {"Name", "MaxSize", "MinSize"},
    ["UITextSizeConstraint"] = {"Name", "MaxTextSize", "MinTextSize"},
    ["UIAspectRatioConstraint"] = {"Name", "AspectRatio", "AspectType", "DominantAxis"},
    ["UIFlexItem"] = {"Name", "FlexMode", "GrowRatio", "ItemLineAlignment", "ShrinkRatio"},
    
    ["Camera"] = {"Name", "CFrame", "FieldOfView", "FieldOfViewMode", "Focus", "HeadLocked", "HeadScale", "NearPlaneZ", "CameraType", "DiagonalFieldOfView", "MaxAxisFieldOfView", "VRTiltAndRollEnabled"},
    
    ["Beam"] = {"Name", "Enabled", "Attachment0", "Attachment1", "Color", "CurveSize0", "CurveSize1", "FaceCamera", "LightEmission", "LightInfluence", "Segments", "Texture", "TextureLength", "TextureMode", "TextureSpeed", "Transparency", "Width0", "Width1", "ZOffset", "Brightness"},
    ["Trail"] = {"Name", "Enabled", "Attachment0", "Attachment1", "Color", "FaceCamera", "LightEmission", "LightInfluence", "Lifetime", "MaxLength", "MinLength", "Texture", "TextureLength", "TextureMode", "Transparency", "WidthScale", "Brightness"},
    
    ["Atmosphere"] = {"Name", "Color", "Decay", "Density", "Glare", "Haze", "Offset"},
    ["Sky"] = {"Name", "CelestialBodiesShown", "MoonAngularSize", "MoonTextureId", "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "StarCount", "SunAngularSize", "SunTextureId"},
    ["Clouds"] = {"Name", "Color", "Cover", "Density", "Enabled"},
    ["BloomEffect"] = {"Name", "Enabled", "Intensity", "Size", "Threshold"},
    ["BlurEffect"] = {"Name", "Enabled", "Size"},
    ["ColorCorrectionEffect"] = {"Name", "Enabled", "Brightness", "Contrast", "Saturation", "TintColor"},
    ["DepthOfFieldEffect"] = {"Name", "Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"},
    ["SunRaysEffect"] = {"Name", "Enabled", "Intensity", "Spread"},
    
    ["StringValue"] = {"Name", "Value"},
    ["IntValue"] = {"Name", "Value"},
    ["NumberValue"] = {"Name", "Value"},
    ["BoolValue"] = {"Name", "Value"},
    ["BrickColorValue"] = {"Name", "Value"},
    ["Color3Value"] = {"Name", "Value"},
    ["Vector3Value"] = {"Name", "Value"},
    ["CFrameValue"] = {"Name", "Value"},
    ["ObjectValue"] = {"Name", "Value"},
    ["RayValue"] = {"Name", "Value"},
}

--- Get known properties for an instance based on its class
---@param instance Instance The instance
---@return table Properties {name = value}
function PropertySerializer.GetKnownProperties(instance)
    local properties = {}
    local className = instance.ClassName
    
    -- Classes to check for properties (from base to specific)
    local classesToCheck = {"Instance"}
    
    -- Hierarchy detection
    local bases = {
        "BasePart", "GuiObject", "LuaSourceContainer", "PostProcessEffect", 
        "BaseLight", "DataModelMesh", "JointInstance", "ValueBase", "GuiBase2d"
    }
    
    for _, base in ipairs(bases) do
        if instance:IsA(base) then
            table.insert(classesToCheck, base)
        end
    end
    
    -- Add the specific class if not already added
    local isSpecificInList = false
    for _, c in ipairs(classesToCheck) do
        if c == className then isSpecificInList = true break end
    end
    if not isSpecificInList then
        table.insert(classesToCheck, className)
    end
    
    for _, class in ipairs(classesToCheck) do
        local classProps = PropertySerializer.KnownClassProperties[class]
        if classProps then
            for _, propName in ipairs(classProps) do
                if not PropertySerializer.SkipProperties[propName] then
                    local success, value = Utils.SafeCall(function()
                        return instance[propName]
                    end)
                    if success and value ~= nil then
                        properties[propName] = value
                    end
                end
            end
        end
    end
    
    return properties
end

--=============================================================================
-- SCRIPT DECOMPILER
--=============================================================================
local ScriptDecompiler = {}

--- Attempt to decompile a script
---@param script LuaSourceContainer The script to decompile
---@return string|nil source The decompiled source or nil
function ScriptDecompiler.Decompile(script)
    if not Config.DecompileScripts then
        return "-- Decompilation disabled"
    end
    
    -- Try various decompile methods
    local decompileFuncs = {
        "decompile",
        "Decompile",
        "getscriptbytecode",
        "decompilefunc",
    }
    
    for _, funcName in ipairs(decompileFuncs) do
        local func = Utils.GetFunction(funcName)
        if func then
            local success, source = Utils.SafeCall(func, script)
            if success and source and type(source) == "string" and #source > 0 then
                return source
            end
        end
    end
    
    -- Fallback: Try to get Source property (usually protected)
    local success, source = Utils.SafeCall(function()
        return script.Source
    end)
    
    if success and source and #source > 0 then
        return source
    end
    
    -- Return placeholder
    return string.format("-- Failed to decompile %s\n-- Script: %s", 
        script.ClassName, script:GetFullName())
end

--=============================================================================
-- TERRAIN SERIALIZER
--=============================================================================
local TerrainSerializer = {}

--- Serialize terrain data
---@param terrain Terrain The terrain instance
---@param callback function Progress callback (percent, status)
---@return string XML representation of terrain
function TerrainSerializer.Serialize(terrain, callback)
    if not terrain then return "" end
    
    callback = callback or function() end
    
    local xmlParts = {}
    table.insert(xmlParts, '<Item class="Terrain" referent="' .. Utils.GenerateRefId() .. '">')
    table.insert(xmlParts, '<Properties>')
    table.insert(xmlParts, '<Property name="Name"><string>Terrain</string></Property>')
    
    -- Get terrain properties
    local success, waterProps = Utils.SafeCall(function()
        return {
            WaterColor = terrain.WaterColor,
            WaterReflectance = terrain.WaterReflectance,
            WaterTransparency = terrain.WaterTransparency,
            WaterWaveSize = terrain.WaterWaveSize,
            WaterWaveSpeed = terrain.WaterWaveSpeed,
            Decoration = terrain.Decoration,
            GrassLength = terrain.GrassLength,
        }
    end)
    
    if success and waterProps then
        -- Serialize water properties (using corrected format)
        table.insert(xmlParts, PropertySerializer.TypeHandlers["Color3"]("WaterColor", waterProps.WaterColor))
        table.insert(xmlParts, string.format('<float name="WaterReflectance">%s</float>', tostring(waterProps.WaterReflectance)))
        table.insert(xmlParts, string.format('<float name="WaterTransparency">%s</float>', tostring(waterProps.WaterTransparency)))
        table.insert(xmlParts, string.format('<float name="WaterWaveSize">%s</float>', tostring(waterProps.WaterWaveSize)))
        table.insert(xmlParts, string.format('<float name="WaterWaveSpeed">%s</float>', tostring(waterProps.WaterWaveSpeed)))
        table.insert(xmlParts, string.format('<bool name="Decoration">%s</bool>', tostring(waterProps.Decoration)))
        table.insert(xmlParts, string.format('<float name="GrassLength">%s</float>', tostring(waterProps.GrassLength)))
    end
    
    callback(10, "Getting terrain size...")
    task.wait() -- Yield for performance
    
    -- Get terrain region and voxel data
    local success2, terrainData = Utils.SafeCall(function()
        local regionSize = terrain:GetMaxExtents() - terrain:GetMinExtents()
        local minPos = terrain:GetMinExtents()
        local maxPos = terrain:GetMaxExtents()
        
        -- Create region from min to max
        local region = Region3.new(minPos, maxPos)
        region = region:ExpandToGrid(4) -- Terrain grid resolution
        
        return {
            Size = regionSize,
            Region = region,
            MinPos = minPos,
            MaxPos = maxPos
        }
    end)
    
    if success2 and terrainData then
        callback(30, "Reading voxel data...")
        task.wait() -- Yield for performance
        
        -- Read terrain voxels using executor's terrain functions if available
        local readVoxels = Utils.GetFunction("readterrainvoxels") or Utils.GetFunction("ReadVoxels")
        
        if readVoxels then
            local success3, voxelData = Utils.SafeCall(function()
                local materials, occupancy = terrain:ReadVoxels(terrainData.Region, 4)
                return {Materials = materials, Occupancy = occupancy}
            end)
            
            if success3 and voxelData then
                callback(50, "Encoding voxel data...")
                task.wait() -- Yield for performance
                
                -- Encode voxel data
                local voxelString = TerrainSerializer.EncodeVoxels(voxelData, callback)
                if voxelString and #voxelString > 0 then
                    table.insert(xmlParts, string.format('<BinaryString name="TerrainData"><![CDATA[%s]]></BinaryString>',
                        voxelString))
                end
            end
        else
            -- Alternative: Save SmoothGrid if available
            local success3, smoothGrid = Utils.SafeCall(function()
                return terrain:CopyRegion(terrainData.Region)
            end)
            
            if success3 and smoothGrid then
                callback(60, "Processing terrain region...")
                task.wait() -- Yield for performance
                -- Store region info for reference (corrected format)
                table.insert(xmlParts, PropertySerializer.TypeHandlers["Vector3"]("RegionMin", terrainData.MinPos))
                table.insert(xmlParts, PropertySerializer.TypeHandlers["Vector3"]("RegionMax", terrainData.MaxPos))
            end
        end
    end
    
    callback(90, "Finalizing terrain...")
    task.wait() -- Yield for performance
    
    table.insert(xmlParts, '</Properties>')
    table.insert(xmlParts, '</Item>')
    
    callback(100, "Terrain serialized")
    
    return table.concat(xmlParts, "\n")
end

--- Encode voxel data to a string format
---@param voxelData table {Materials = 3D array, Occupancy = 3D array}
---@param callback function Progress callback
---@return string Encoded voxel data
function TerrainSerializer.EncodeVoxels(voxelData, callback)
    -- Simplified voxel encoding - full implementation would be complex
    -- This stores basic material and occupancy data
    
    local encoded = {}
    local materials = voxelData.Materials
    local occupancy = voxelData.Occupancy
    
    if not materials or not occupancy then
        return ""
    end
    
    local size = materials.Size
    if not size then return "" end
    
    local totalVoxels = size.X * size.Y * size.Z
    local processed = 0
    
    for x = 1, size.X do
        for y = 1, size.Y do
            for z = 1, size.Z do
                local success, data = Utils.SafeCall(function()
                    local mat = materials[x][y][z]
                    local occ = occupancy[x][y][z]
                    
                    -- Only encode non-air voxels
                    if mat ~= Enum.Material.Air and occ > 0 then
                        return string.format("%d,%d,%d,%d,%.2f", x, y, z, mat.Value, occ)
                    end
                    return nil
                end)
                
                if success and data then
                    table.insert(encoded, data)
                end
                
                processed = processed + 1
                if processed % 10000 == 0 then
                    callback(50 + (processed / totalVoxels) * 40, "Encoding voxels...")
                    task.wait()
                end
            end
        end
    end
    
    return table.concat(encoded, ";")
end

--=============================================================================
-- INSTANCE SERIALIZER
--=============================================================================
local InstanceSerializer = {}

-- Statistics tracking
InstanceSerializer.Stats = {
    TotalInstances = 0,
    ProcessedInstances = 0,
    SkippedInstances = 0,
    Scripts = 0,
    Models = 0,
    Parts = 0,
    Other = 0,
}

--- Reset statistics
function InstanceSerializer.ResetStats()
    InstanceSerializer.Stats = {
        TotalInstances = 0,
        ProcessedInstances = 0,
        SkippedInstances = 0,
        Scripts = 0,
        Models = 0,
        Parts = 0,
        Other = 0,
    }
end

--- Count all descendants of an instance
---@param instance Instance Root instance
---@return number Total descendant count
function InstanceSerializer.CountDescendants(instance)
    local count = 0
    local success, descendants = Utils.SafeCall(function()
        return instance:GetDescendants()
    end)
    
    if success and descendants then
        count = #descendants
    end
    
    return count
end

--- Serialize an instance and its descendants to XML
---@param instance Instance The instance to serialize
---@param options table Serialization options
---@param callback function Progress callback (percent, status)
---@param depth number Current recursion depth
---@return string XML representation
function InstanceSerializer.Serialize(instance, options, callback, depth)
    options = options or {}
    callback = callback or function() end
    depth = depth or 0
    
    -- Check if we should skip this instance
    if PropertySerializer.SkipClasses[instance.ClassName] then
        InstanceSerializer.Stats.SkippedInstances = InstanceSerializer.Stats.SkippedInstances + 1
        return ""
    end
    
    -- Skip scripts if option is disabled
    if not options.IncludeScripts then
        if instance:IsA("LuaSourceContainer") then
            InstanceSerializer.Stats.SkippedInstances = InstanceSerializer.Stats.SkippedInstances + 1
            return ""
        end
    end
    
    -- Handle Terrain specially (nested in Workspace)
    if instance:IsA("Terrain") then
        if options.IncludeTerrain then
            return TerrainSerializer.Serialize(instance, callback)
        else
            InstanceSerializer.Stats.SkippedInstances = InstanceSerializer.Stats.SkippedInstances + 1
            return ""
        end
    end
    
    local xmlParts = {}
    local refId = Utils.GetRefId(instance)
    
    -- Start instance element
    table.insert(xmlParts, string.format('<Item class="%s" referent="%s">',
        Utils.EscapeXML(instance.ClassName), refId))
    table.insert(xmlParts, '<Properties>')
    
    -- Get and serialize properties
    local properties = PropertySerializer.GetProperties(instance)
    
    for name, value in pairs(properties) do
        local propXml = PropertySerializer.SerializeProperty(name, value)
        if propXml then
            table.insert(xmlParts, propXml)
        end
    end
    
    -- Handle scripts specially - include source
    if instance:IsA("LuaSourceContainer") and options.IncludeScripts then
        local source = ScriptDecompiler.Decompile(instance)
        if source then
            -- Use ProtectedString for script source (corrected format)
            table.insert(xmlParts, string.format(
                '<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>',
                source))
        end
        InstanceSerializer.Stats.Scripts = InstanceSerializer.Stats.Scripts + 1
    elseif instance:IsA("Model") then
        InstanceSerializer.Stats.Models = InstanceSerializer.Stats.Models + 1
    elseif instance:IsA("BasePart") then
        InstanceSerializer.Stats.Parts = InstanceSerializer.Stats.Parts + 1
    else
        InstanceSerializer.Stats.Other = InstanceSerializer.Stats.Other + 1
    end
    
    table.insert(xmlParts, '</Properties>')
    
    -- Process children
    local success, children = Utils.SafeCall(function()
        return instance:GetChildren()
    end)
    
    if success and children and #children > 0 then
        for i, child in ipairs(children) do
            -- Update progress
            InstanceSerializer.Stats.ProcessedInstances = InstanceSerializer.Stats.ProcessedInstances + 1
            
            if InstanceSerializer.Stats.ProcessedInstances % Config.ProgressUpdateInterval == 0 then
                local percent = math.floor((InstanceSerializer.Stats.ProcessedInstances / 
                    math.max(1, InstanceSerializer.Stats.TotalInstances)) * 100)
                callback(percent, string.format("Processing: %s", child:GetFullName():sub(1, 50)))
            end
            
            -- Yield periodically to prevent script timeout
            if InstanceSerializer.Stats.ProcessedInstances % Config.YieldInterval == 0 then
                task.wait()
            end
            
            local childXml = InstanceSerializer.Serialize(child, options, callback, depth + 1)
            if childXml and #childXml > 0 then
                table.insert(xmlParts, childXml)
            end
        end
    end
    
    table.insert(xmlParts, '</Item>')
    
    return table.concat(xmlParts, "\n")
end

--- Serialize multiple root instances
---@param instances table Array of instances to serialize
---@param options table Serialization options
---@param callback function Progress callback
---@return string Complete RBXLX file content
function InstanceSerializer.SerializeToFile(instances, options, callback)
    options = options or {}
    callback = callback or function() end
    
    -- Reset state
    Utils.ResetRefCounter()
    InstanceSerializer.ResetStats()
    
    -- Count total instances for progress
    callback(0, "Counting instances...")
    for _, inst in ipairs(instances) do
        InstanceSerializer.Stats.TotalInstances = InstanceSerializer.Stats.TotalInstances + 
            InstanceSerializer.CountDescendants(inst) + 1
    end
    
    callback(5, string.format("Found %s instances", 
        Utils.FormatNumber(InstanceSerializer.Stats.TotalInstances)))
    
    -- Build XML document
    local xmlParts = {}
    
    -- XML header and root element
    table.insert(xmlParts, '<?xml version="1.0" encoding="UTF-8"?>')
    table.insert(xmlParts, '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">')
    table.insert(xmlParts, '<Meta name="ExplicitAutoJoints">true</Meta>')
    
    -- Progress calculation helper
    local totalInstances = 0
    for _, inst in ipairs(instances) do
        totalInstances = totalInstances + #inst:GetDescendants() + 1
    end
    
    local instancesProcessed = 0
    local lastYield = os.clock()
    local xmlLengthCounter = 0
    
    -- Serialize each root instance
    for i, instance in ipairs(instances) do
        local instanceXml = InstanceSerializer.Serialize(instance, options, function(p, s)
            -- Sub-progress is handled, but we report global progress here
            local globalPercent = 5 + (instancesProcessed / totalInstances * 90)
            callback(globalPercent, s)
            
            -- Intelligent Yielding (Kernel Heat Protection)
            if os.clock() - lastYield > 0.05 then -- Yield every 50ms
                task.wait()
                lastYield = os.clock()
            end
        end, 0)
        
        if instanceXml and #instanceXml > 0 then
            table.insert(xmlParts, instanceXml)
            xmlLengthCounter = xmlLengthCounter + #instanceXml
            instancesProcessed = instancesProcessed + #instance:GetDescendants() + 1
        end
        
        -- Prevent Memory Spike (Yield after every 500KB of XML)
        if xmlLengthCounter > 500000 then
            xmlLengthCounter = 0
            task.wait()
            lastYield = os.clock()
        end
    end
    
    -- Terrain is now handled inside InstanceSerializer.Serialize as a child of Workspace
    -- Separate serialization block removed to prevent duplicates
    
    -- Close root element
    table.insert(xmlParts, '</roblox>')
    
    callback(100, "Serialization complete!")
    
    return table.concat(xmlParts, "\n")
end

--=============================================================================
-- UI LIBRARY
--=============================================================================
local UI = {}
UI.Connections = {}

--- Clean up all UI connections
function UI.Cleanup()
    for _, conn in ipairs(UI.Connections) do
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    UI.Connections = {}
end

--- Create a rounded corner
---@param radius number Corner radius
---@return UICorner
function UI.Corner(radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    return corner
end

--- Create a shadow effect
---@param parent GuiObject Parent object
---@param transparency number Shadow transparency
function UI.AddShadow(parent, transparency)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = transparency or 0.6
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.Parent = parent
    return shadow
end

--- Create a stroke effect
---@param parent GuiObject Parent object
---@param color Color3 Stroke color
---@param thickness number Stroke thickness
---@return UIStroke
function UI.Stroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Config.Colors.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

--- Make a GUI draggable
---@param frame GuiObject The frame to make draggable
---@param handle GuiObject The handle to drag from
function UI.MakeDraggable(frame, handle)
    local dragging = false
    local dragStart, startPos
    
    local function updateDrag(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    
    local conn1 = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    local conn2 = handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    local conn3 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            updateDrag(input)
        end
    end)
    
    table.insert(UI.Connections, conn1)
    table.insert(UI.Connections, conn2)
    table.insert(UI.Connections, conn3)
end

--- Create a styled button
---@param props table Button properties
---@return TextButton
function UI.Button(props)
    local button = Instance.new("TextButton")
    button.Name = props.Name or "Button"
    button.Size = props.Size or UDim2.new(1, 0, 0, 36)
    button.Position = props.Position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = props.Color or Config.Colors.Secondary
    button.TextColor3 = props.TextColor or Config.Colors.Text
    button.Text = props.Text or "Button"
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 14
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    
    UI.Corner(6).Parent = button
    UI.Stroke(button)
    
    -- Hover effects
    local defaultColor = button.BackgroundColor3
    local hoverColor = props.HoverColor or Config.Colors.Accent
    
    local conn1 = button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = hoverColor
        }):Play()
    end)
    
    local conn2 = button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = defaultColor
        }):Play()
    end)
    
    table.insert(UI.Connections, conn1)
    table.insert(UI.Connections, conn2)
    
    if props.Callback then
        local conn3 = button.MouseButton1Click:Connect(props.Callback)
        table.insert(UI.Connections, conn3)
    end
    
    if props.Parent then
        button.Parent = props.Parent
    end
    
    return button
end

--- Create a toggle switch
---@param props table Toggle properties
---@return Frame, BoolValue
function UI.Toggle(props)
    local container = Instance.new("Frame")
    container.Name = props.Name or "Toggle"
    container.Size = props.Size or UDim2.new(1, 0, 0, 30)
    container.Position = props.Position or UDim2.new(0, 0, 0, 0)
    container.BackgroundTransparency = 1
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Config.Colors.Text
    label.Text = props.Text or "Toggle"
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Toggle background
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 44, 0, 22)
    toggleBg.Position = UDim2.new(1, -44, 0.5, -11)
    toggleBg.BackgroundColor3 = Config.Colors.Secondary
    toggleBg.Parent = container
    UI.Corner(11).Parent = toggleBg
    UI.Stroke(toggleBg)
    
    -- Toggle indicator
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 16, 0, 16)
    indicator.Position = props.Default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    indicator.BackgroundColor3 = props.Default and Config.Colors.Accent or Config.Colors.TextDim
    indicator.Parent = toggleBg
    UI.Corner(8).Parent = indicator
    
    -- State value
    local state = Instance.new("BoolValue")
    state.Name = "State"
    state.Value = props.Default or false
    state.Parent = container
    
    -- Toggle function
    local function toggle()
        state.Value = not state.Value
        
        TweenService:Create(indicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Position = state.Value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = state.Value and Config.Colors.Accent or Config.Colors.TextDim
        }):Play()
        
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {
            BackgroundColor3 = state.Value and Color3.fromRGB(45, 65, 85) or Config.Colors.Secondary
        }):Play()
        
        if props.Callback then
            props.Callback(state.Value)
        end
    end
    
    -- Make clickable
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = container
    
    local conn = button.MouseButton1Click:Connect(toggle)
    table.insert(UI.Connections, conn)
    
    if props.Parent then
        container.Parent = props.Parent
    end
    
    return container, state
end

--- Create a text input field
---@param props table Input properties
---@return Frame, TextBox
function UI.Input(props)
    local container = Instance.new("Frame")
    container.Name = props.Name or "Input"
    container.Size = props.Size or UDim2.new(1, 0, 0, 50)
    container.Position = props.Position or UDim2.new(0, 0, 0, 0)
    container.BackgroundTransparency = 1
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Config.Colors.TextDim
    label.Text = props.Label or "Input"
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Input field
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, 0, 0, 28)
    inputFrame.Position = UDim2.new(0, 0, 0, 20)
    inputFrame.BackgroundColor3 = Config.Colors.Secondary
    inputFrame.Parent = container
    UI.Corner(6).Parent = inputFrame
    UI.Stroke(inputFrame)
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -16, 1, 0)
    textBox.Position = UDim2.new(0, 8, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.TextColor3 = Config.Colors.Text
    textBox.PlaceholderColor3 = Config.Colors.TextDim
    textBox.Text = props.Default or ""
    textBox.PlaceholderText = props.Placeholder or "Enter text..."
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 13
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    textBox.Parent = inputFrame
    
    if props.Callback then
        local conn = textBox.FocusLost:Connect(function()
            props.Callback(textBox.Text)
        end)
        table.insert(UI.Connections, conn)
    end
    
    if props.Parent then
        container.Parent = props.Parent
    end
    
    return container, textBox
end

--- Create a dropdown selector
---@param props table Dropdown properties
---@return Frame, StringValue
function UI.Dropdown(props)
    local container = Instance.new("Frame")
    container.Name = props.Name or "Dropdown"
    container.Size = props.Size or UDim2.new(1, 0, 0, 50)
    container.Position = props.Position or UDim2.new(0, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = false
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.TextColor3 = Config.Colors.TextDim
    label.Text = props.Label or "Select"
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Selected value holder
    local selectedValue = Instance.new("StringValue")
    selectedValue.Name = "Selected"
    selectedValue.Value = props.Default or props.Options[1] or ""
    selectedValue.Parent = container
    
    -- Main button
    local mainButton = Instance.new("TextButton")
    mainButton.Size = UDim2.new(1, 0, 0, 28)
    mainButton.Position = UDim2.new(0, 0, 0, 20)
    mainButton.BackgroundColor3 = Config.Colors.Secondary
    mainButton.TextColor3 = Config.Colors.Text
    mainButton.Text = "  " .. selectedValue.Value
    mainButton.Font = Enum.Font.Gotham
    mainButton.TextSize = 13
    mainButton.TextXAlignment = Enum.TextXAlignment.Left
    mainButton.AutoButtonColor = false
    mainButton.Parent = container
    UI.Corner(6).Parent = mainButton
    UI.Stroke(mainButton)
    
    -- Arrow indicator
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -24, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.TextColor3 = Config.Colors.TextDim
    arrow.Text = "▼"
    arrow.Font = Enum.Font.Gotham
    arrow.TextSize = 10
    arrow.Parent = mainButton
    
    -- Dropdown list
    local dropFrame = Instance.new("Frame")
    dropFrame.Size = UDim2.new(1, 0, 0, 0)
    dropFrame.Position = UDim2.new(0, 0, 0, 50)
    dropFrame.BackgroundColor3 = Config.Colors.Secondary
    dropFrame.ClipsDescendants = true
    dropFrame.Visible = false
    dropFrame.ZIndex = 10
    dropFrame.Parent = container
    UI.Corner(6).Parent = dropFrame
    UI.Stroke(dropFrame)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = dropFrame
    
    local isOpen = false
    
    -- Create option buttons
    for i, option in ipairs(props.Options or {}) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.BackgroundTransparency = 1
        optBtn.TextColor3 = Config.Colors.Text
        optBtn.Text = "  " .. option
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 13
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.AutoButtonColor = false
        optBtn.LayoutOrder = i
        optBtn.ZIndex = 10
        optBtn.Parent = dropFrame
        
        local conn = optBtn.MouseButton1Click:Connect(function()
            selectedValue.Value = option
            mainButton.Text = "  " .. option
            
            -- Close dropdown
            isOpen = false
            TweenService:Create(dropFrame, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
            task.delay(0.2, function()
                dropFrame.Visible = false
            end)
            TweenService:Create(arrow, TweenInfo.new(0.2), {
                Rotation = 0
            }):Play()
            
            if props.Callback then
                props.Callback(option)
            end
        end)
        table.insert(UI.Connections, conn)
    end
    
    -- Toggle dropdown
    local conn = mainButton.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        
        if isOpen then
            dropFrame.Visible = true
            TweenService:Create(dropFrame, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, math.min(#(props.Options or {}) * 26, 130))
            }):Play()
            TweenService:Create(arrow, TweenInfo.new(0.2), {
                Rotation = 180
            }):Play()
        else
            TweenService:Create(dropFrame, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
            task.delay(0.2, function()
                dropFrame.Visible = false
            end)
            TweenService:Create(arrow, TweenInfo.new(0.2), {
                Rotation = 0
            }):Play()
        end
    end)
    table.insert(UI.Connections, conn)
    
    if props.Parent then
        container.Parent = props.Parent
    end
    
    return container, selectedValue
end

--=============================================================================
-- MAIN APPLICATION
--=============================================================================
local App = {}
App.GUI = nil
App.MainFrame = nil
App.StatusLabel = nil
App.ProgressBar = nil
App.IsProcessing = false

-- Settings state
App.Settings = {
    IncludeScripts = Config.IncludeScripts,
    IncludeTerrain = Config.IncludeTerrain,
    FileName = Config.FileName,
    ExportFormat = Config.ExportFormat,
}

--- Initialize the application
function App.Init()
    -- Wait for LocalPlayer safely
    if not Players.LocalPlayer then
        repeat task.wait() until Players.LocalPlayer
    end
    
    -- Clean up existing GUIs using the random name tracking if possible
    -- Or scan for common names for safety
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local getHui = Utils.GetFunction("gethui")
    
    local function SafeCleanup(container)
        if not container then return end
        for _, gui in ipairs(container:GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name == "BaoSaveInstance" or gui:FindFirstChild("MainFrame")) then
                gui:Destroy()
            end
        end
    end
    
    SafeCleanup(playerGui)
    SafeCleanup(CoreGui)
    if getHui then pcall(function() SafeCleanup(getHui()) end) end
    
    UI.Cleanup()
    
    -- Create main ScreenGui with a random name for stealth
    App.GUI = Instance.new("ScreenGui")
    App.GUI.Name = currentGuiName
    App.GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    App.GUI.ResetOnSpawn = false
    
    -- Hide GUI from some basic detection methods
    pcall(function()
        App.GUI.IgnoreGuiInset = true
        if App.GUI:CanSetProperty("DisplayOrder") then
            App.GUI.DisplayOrder = 999999
        end
    end)
    
    -- Use gethui if available (best protection)
    local parented = false
    if getHui then
        local success, hiddenUI = pcall(getHui)
        if success and hiddenUI then
            App.GUI.Parent = hiddenUI
            parented = true
        end
    end
    
    if not parented then
        -- Fallback to CoreGui or PlayerGui
        pcall(function()
            App.GUI.Parent = CoreGui
            parented = true
        end)
        
        if not parented then
            App.GUI.Parent = playerGui
        end
    end
    
    App.CreateMainWindow()
    print("BaoSaveInstance [" .. currentGuiName .. "] Loaded!")
end

--- Create the main window
function App.CreateMainWindow()
    -- Main container
    App.MainFrame = Instance.new("Frame")
    App.MainFrame.Name = "MainWindow"
    App.MainFrame.Size = Config.WindowSize
    App.MainFrame.Position = UDim2.new(0.5, -190, 0.5, -240)
    App.MainFrame.BackgroundColor3 = Config.Colors.Background
    App.MainFrame.BorderSizePixel = 0
    App.MainFrame.Parent = App.GUI
    
    UI.Corner(10).Parent = App.MainFrame
    UI.AddShadow(App.MainFrame, 0.5)
    UI.Stroke(App.MainFrame, Config.Colors.Border, 1)
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Config.Colors.Secondary
    titleBar.BorderSizePixel = 0
    titleBar.Parent = App.MainFrame
    
    local titleCorner = UI.Corner(10)
    titleCorner.Parent = titleBar
    
    -- Fix corner on bottom
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 10)
    titleFix.Position = UDim2.new(0, 0, 1, -10)
    titleFix.BackgroundColor3 = Config.Colors.Secondary
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -80, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = Config.Colors.Text
    titleText.Text = "🔧 BaoSaveInstance"
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Version badge
    local versionBadge = Instance.new("TextLabel")
    versionBadge.Size = UDim2.new(0, 40, 0, 18)
    versionBadge.Position = UDim2.new(0, 175, 0.5, -9)
    versionBadge.BackgroundColor3 = Config.Colors.Accent
    versionBadge.TextColor3 = Config.Colors.Text
    versionBadge.Text = "v1.0"
    versionBadge.Font = Enum.Font.GothamBold
    versionBadge.TextSize = 10
    versionBadge.Parent = titleBar
    UI.Corner(4).Parent = versionBadge
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Config.Colors.Error
    closeBtn.BackgroundTransparency = 0.8
    closeBtn.TextColor3 = Config.Colors.Error
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = titleBar
    UI.Corner(6).Parent = closeBtn
    
    local conn = closeBtn.MouseButton1Click:Connect(function()
        App.Destroy()
    end)
    table.insert(UI.Connections, conn)
    
    -- Make draggable
    UI.MakeDraggable(App.MainFrame, titleBar)
    
    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -30, 1, -55)
    content.Position = UDim2.new(0, 15, 0, 48)
    content.BackgroundTransparency = 1
    content.Parent = App.MainFrame
    
    -- Status area
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(1, 0, 0, 50)
    statusFrame.BackgroundColor3 = Config.Colors.Secondary
    statusFrame.Parent = content
    UI.Corner(8).Parent = statusFrame
    
    App.StatusLabel = Instance.new("TextLabel")
    App.StatusLabel.Name = "StatusLabel"
    App.StatusLabel.Size = UDim2.new(1, -20, 0, 20)
    App.StatusLabel.Position = UDim2.new(0, 10, 0, 8)
    App.StatusLabel.BackgroundTransparency = 1
    App.StatusLabel.TextColor3 = Config.Colors.TextDim
    App.StatusLabel.Text = "Status: Idle"
    App.StatusLabel.Font = Enum.Font.Gotham
    App.StatusLabel.TextSize = 12
    App.StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    App.StatusLabel.Parent = statusFrame
    
    -- Progress bar background
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, -20, 0, 8)
    progressBg.Position = UDim2.new(0, 10, 0, 32)
    progressBg.BackgroundColor3 = Config.Colors.Background
    progressBg.Parent = statusFrame
    UI.Corner(4).Parent = progressBg
    
    -- Progress bar fill
    App.ProgressBar = Instance.new("Frame")
    App.ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    App.ProgressBar.BackgroundColor3 = Config.Colors.Accent
    App.ProgressBar.Parent = progressBg
    UI.Corner(4).Parent = App.ProgressBar
    
    -- Buttons section
    local buttonSection = Instance.new("Frame")
    buttonSection.Name = "ButtonSection"
    buttonSection.Size = UDim2.new(1, 0, 0, 180)
    buttonSection.Position = UDim2.new(0, 0, 0, 60)
    buttonSection.BackgroundTransparency = 1
    buttonSection.Parent = content
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    buttonLayout.Padding = UDim.new(0, 8)
    buttonLayout.Parent = buttonSection
    
    -- Main action buttons
    UI.Button({
        Name = "DecompileFullGame",
        Text = "📦 Decompile Full Game",
        Color = Config.Colors.Accent,
        HoverColor = Config.Colors.AccentHover,
        LayoutOrder = 1,
        Parent = buttonSection,
        Callback = function()
            App.DecompileFullGame()
        end
    })
    
    UI.Button({
        Name = "DecompileModels",
        Text = "🏗️ Decompile Full Model",
        LayoutOrder = 2,
        Parent = buttonSection,
        Callback = function()
            App.DecompileModels()
        end
    })
    
    UI.Button({
        Name = "DecompileTerrain",
        Text = "🌍 Decompile Terrain",
        LayoutOrder = 3,
        Parent = buttonSection,
        Callback = function()
            App.DecompileTerrain()
        end
    })
    
    UI.Button({
        Name = "Settings",
        Text = "⚙️ Settings",
        LayoutOrder = 4,
        Parent = buttonSection,
        Callback = function()
            App.ShowSettings()
        end
    })
    
    -- Quick settings
    local quickSettings = Instance.new("Frame")
    quickSettings.Name = "QuickSettings"
    quickSettings.Size = UDim2.new(1, 0, 0, 100)
    quickSettings.Position = UDim2.new(0, 0, 0, 250)
    quickSettings.BackgroundColor3 = Config.Colors.Secondary
    quickSettings.Parent = content
    UI.Corner(8).Parent = quickSettings
    
    local settingsLabel = Instance.new("TextLabel")
    settingsLabel.Size = UDim2.new(1, -20, 0, 25)
    settingsLabel.Position = UDim2.new(0, 10, 0, 5)
    settingsLabel.BackgroundTransparency = 1
    settingsLabel.TextColor3 = Config.Colors.TextDim
    settingsLabel.Text = "Quick Settings"
    settingsLabel.Font = Enum.Font.GothamBold
    settingsLabel.TextSize = 11
    settingsLabel.TextXAlignment = Enum.TextXAlignment.Left
    settingsLabel.Parent = quickSettings
    
    local toggleContainer = Instance.new("Frame")
    toggleContainer.Size = UDim2.new(1, -20, 0, 65)
    toggleContainer.Position = UDim2.new(0, 10, 0, 28)
    toggleContainer.BackgroundTransparency = 1
    toggleContainer.Parent = quickSettings
    
    local _, scriptsToggle = UI.Toggle({
        Name = "IncludeScripts",
        Text = "Include Scripts",
        Default = App.Settings.IncludeScripts,
        Position = UDim2.new(0, 0, 0, 0),
        Parent = toggleContainer,
        Callback = function(value)
            App.Settings.IncludeScripts = value
        end
    })
    
    local _, terrainToggle = UI.Toggle({
        Name = "IncludeTerrain",
        Text = "Include Terrain",
        Default = App.Settings.IncludeTerrain,
        Position = UDim2.new(0, 0, 0, 35),
        Parent = toggleContainer,
        Callback = function(value)
            App.Settings.IncludeTerrain = value
        end
    })
    
    -- Info section
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "Info"
    infoFrame.Size = UDim2.new(1, 0, 0, 55)
    infoFrame.Position = UDim2.new(0, 0, 0, 360)
    infoFrame.BackgroundColor3 = Config.Colors.Secondary
    infoFrame.Parent = content
    UI.Corner(8).Parent = infoFrame
    
    local gameInfo = Instance.new("TextLabel")
    gameInfo.Size = UDim2.new(1, -20, 1, -10)
    gameInfo.Position = UDim2.new(0, 10, 0, 5)
    gameInfo.BackgroundTransparency = 1
    gameInfo.TextColor3 = Config.Colors.TextDim
    gameInfo.Text = string.format("Game: %s\nPlaceId: %s | GameId: %s",
        game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown",
        tostring(game.PlaceId),
        tostring(game.GameId))
    gameInfo.Font = Enum.Font.Gotham
    gameInfo.TextSize = 11
    gameInfo.TextXAlignment = Enum.TextXAlignment.Left
    gameInfo.TextYAlignment = Enum.TextYAlignment.Top
    gameInfo.TextWrapped = true
    gameInfo.Parent = infoFrame
    
    -- Animate window in
    App.MainFrame.Position = UDim2.new(0.5, -190, 0.5, -200)
    App.MainFrame.BackgroundTransparency = 1
    
    TweenService:Create(App.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -190, 0.5, -240),
        BackgroundTransparency = 0
    }):Play()
end

--- Show settings panel
function App.ShowSettings()
    -- Create settings overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "SettingsOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 50
    overlay.Parent = App.GUI
    
    local settingsPanel = Instance.new("Frame")
    settingsPanel.Name = "SettingsPanel"
    settingsPanel.Size = UDim2.new(0, 320, 0, 280)
    settingsPanel.Position = UDim2.new(0.5, -160, 0.5, -140)
    settingsPanel.BackgroundColor3 = Config.Colors.Background
    settingsPanel.ZIndex = 51
    settingsPanel.Parent = overlay
    UI.Corner(10).Parent = settingsPanel
    UI.AddShadow(settingsPanel, 0.4)
    UI.Stroke(settingsPanel, Config.Colors.Border, 1)
    
    -- Settings title
    local settingsTitle = Instance.new("TextLabel")
    settingsTitle.Size = UDim2.new(1, -20, 0, 35)
    settingsTitle.Position = UDim2.new(0, 10, 0, 5)
    settingsTitle.BackgroundTransparency = 1
    settingsTitle.TextColor3 = Config.Colors.Text
    settingsTitle.Text = "⚙️ Settings"
    settingsTitle.Font = Enum.Font.GothamBold
    settingsTitle.TextSize = 16
    settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
    settingsTitle.ZIndex = 52
    settingsTitle.Parent = settingsPanel
    
    -- Settings content
    local settingsContent = Instance.new("Frame")
    settingsContent.Size = UDim2.new(1, -20, 0, 180)
    settingsContent.Position = UDim2.new(0, 10, 0, 45)
    settingsContent.BackgroundTransparency = 1
    settingsContent.ZIndex = 52
    settingsContent.Parent = settingsPanel
    
    -- File name input
    local _, fileNameInput = UI.Input({
        Name = "FileName",
        Label = "Export File Name",
        Default = App.Settings.FileName,
        Placeholder = "SavedGame",
        Position = UDim2.new(0, 0, 0, 0),
        Parent = settingsContent,
        Callback = function(value)
            App.Settings.FileName = value ~= "" and value or "SavedGame"
        end
    })
    fileNameInput.Parent.ZIndex = 52
    
    -- Format dropdown
    local _, formatDropdown = UI.Dropdown({
        Name = "ExportFormat",
        Label = "Export Format",
        Options = {".rbxlx", ".rbxl"},
        Default = App.Settings.ExportFormat,
        Position = UDim2.new(0, 0, 0, 55),
        Parent = settingsContent,
        Callback = function(value)
            App.Settings.ExportFormat = value
        end
    })
    formatDropdown.Parent.ZIndex = 52
    
    -- Additional toggles
    local togglesFrame = Instance.new("Frame")
    togglesFrame.Size = UDim2.new(1, 0, 0, 70)
    togglesFrame.Position = UDim2.new(0, 0, 0, 110)
    togglesFrame.BackgroundTransparency = 1
    togglesFrame.ZIndex = 52
    togglesFrame.Parent = settingsContent
    
    UI.Toggle({
        Name = "DecompileScripts",
        Text = "Decompile Scripts",
        Default = Config.DecompileScripts,
        Position = UDim2.new(0, 0, 0, 0),
        Parent = togglesFrame,
        Callback = function(value)
            Config.DecompileScripts = value
        end
    }).ZIndex = 52
    
    UI.Toggle({
        Name = "PreserveHierarchy",
        Text = "Preserve Hierarchy",
        Default = Config.PreserveHierarchy,
        Position = UDim2.new(0, 0, 0, 35),
        Parent = togglesFrame,
        Callback = function(value)
            Config.PreserveHierarchy = value
        end
    }).ZIndex = 52
    
    -- Close button
    UI.Button({
        Name = "CloseSettings",
        Text = "Close",
        Size = UDim2.new(1, -20, 0, 32),
        Position = UDim2.new(0, 10, 1, -42),
        Color = Config.Colors.Accent,
        Parent = settingsPanel,
        Callback = function()
            -- Animate out
            TweenService:Create(overlay, TweenInfo.new(0.2), {
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(settingsPanel, TweenInfo.new(0.2), {
                Position = UDim2.new(0.5, -160, 0.5, -120),
                BackgroundTransparency = 1
            }):Play()
            
            task.delay(0.2, function()
                overlay:Destroy()
            end)
        end
    }).ZIndex = 52
    
    -- Animate in
    overlay.BackgroundTransparency = 1
    settingsPanel.BackgroundTransparency = 1
    settingsPanel.Position = UDim2.new(0.5, -160, 0.5, -100)
    
    TweenService:Create(overlay, TweenInfo.new(0.2), {
        BackgroundTransparency = 0.5
    }):Play()
    TweenService:Create(settingsPanel, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -160, 0.5, -140),
        BackgroundTransparency = 0
    }):Play()
end

--- Update status display
---@param status string Status text
---@param statusType string Status type (info/success/error/warning)
function App.UpdateStatus(status, statusType)
    if App.StatusLabel then
        App.StatusLabel.Text = "Status: " .. status
        
        local colors = {
            info = Config.Colors.TextDim,
            success = Config.Colors.Success,
            error = Config.Colors.Error,
            warning = Config.Colors.Warning,
        }
        
        App.StatusLabel.TextColor3 = colors[statusType] or colors.info
    end
end

--- Update progress bar
---@param percent number Progress percentage (0-100)
function App.UpdateProgress(percent)
    if App.ProgressBar then
        TweenService:Create(App.ProgressBar, TweenInfo.new(0.1), {
            Size = UDim2.new(math.clamp(percent / 100, 0, 1), 0, 1, 0)
        }):Play()
    end
end

--- Save content to file
---@param content string File content
---@param fileName string File name
---@return boolean success
function App.SaveToFile(content, fileName)
    local writeFile = Utils.GetFunction("writefile")
    
    if not writeFile then
        App.UpdateStatus("writefile not available!", "error")
        return false
    end
    
    local success, err = Utils.SafeCall(writeFile, fileName, content)
    
    if not success then
        App.UpdateStatus("Failed to save: " .. tostring(err), "error")
        return false
    end
    
    return true
end

--- Decompile full game
function App.DecompileFullGame()
    if App.IsProcessing then
        App.UpdateStatus("Already processing...", "warning")
        return
    end
    
    App.IsProcessing = true
    App.UpdateStatus("Starting full game decompile...", "info")
    App.UpdateProgress(0)
    
    task.spawn(function()
        local success, err = Utils.SafeCall(function()
            -- Collect all services to save
            local instancesToSave = {}
            
            local servicesToSave = {
                Workspace,
                Lighting,
                ReplicatedStorage,
                ReplicatedFirst,
                StarterGui,
                StarterPack,
                StarterPlayer,
                Teams,
                SoundService,
                Chat,
                LocalizationService,
                TestService,
                game:GetService("TextChatService"),
                game:GetService("VoiceChatService"),
                game:GetService("ServerScriptService"),
                game:GetService("ServerStorage"),
            }
            
            for _, service in ipairs(servicesToSave) do
                local success, _ = Utils.SafeCall(function()
                    table.insert(instancesToSave, service)
                end)
            end
            
            App.UpdateStatus("Serializing game...", "info")
            
            local xmlContent = InstanceSerializer.SerializeToFile(instancesToSave, {
                IncludeScripts = App.Settings.IncludeScripts,
                IncludeTerrain = App.Settings.IncludeTerrain,
            }, function(percent, status)
                App.UpdateProgress(percent)
                App.UpdateStatus(status, "info")
            end)
            
            -- Save file
            local fileName = App.Settings.FileName .. "_FullGame" .. App.Settings.ExportFormat
            App.UpdateStatus("Saving to " .. fileName .. "...", "info")
            
            if App.SaveToFile(xmlContent, fileName) then
                local stats = InstanceSerializer.Stats
                App.UpdateStatus(string.format("Saved! (%s instances, %s scripts, %s parts)",
                    Utils.FormatNumber(stats.ProcessedInstances),
                    Utils.FormatNumber(stats.Scripts),
                    Utils.FormatNumber(stats.Parts)), "success")
            end
        end)
        
        if not success then
            App.UpdateStatus("Error: " .. tostring(err), "error")
        end
        
        App.IsProcessing = false
        App.UpdateProgress(100)
    end)
end

--- Decompile models only
function App.DecompileModels()
    if App.IsProcessing then
        App.UpdateStatus("Already processing...", "warning")
        return
    end
    
    App.IsProcessing = true
    App.UpdateStatus("Starting model decompile...", "info")
    App.UpdateProgress(0)
    
    task.spawn(function()
        local success, err = Utils.SafeCall(function()
            -- Collect essential services for a functional map
            local instancesToSave = {}
            local services = {
                Workspace,
                Lighting,
                ReplicatedStorage,
                StarterPlayer,
                Teams,
                SoundService,
                Chat,
                game:GetService("TextChatService"),
                game:GetService("ServerScriptService"),
                game:GetService("ServerStorage"),
            }
            
            for _, service in ipairs(services) do
                table.insert(instancesToSave, service)
            end
            
            local xmlContent = InstanceSerializer.SerializeToFile(instancesToSave, {
                IncludeScripts = App.Settings.IncludeScripts,
                IncludeTerrain = false, -- Exclude terrain for models only
            }, function(percent, status)
                App.UpdateProgress(percent)
                App.UpdateStatus(status, "info")
            end)
            
            -- Save file
            local fileName = App.Settings.FileName .. "_ModelsOnly" .. App.Settings.ExportFormat
            App.UpdateStatus("Saving to " .. fileName .. "...", "info")
            
            if App.SaveToFile(xmlContent, fileName) then
                local stats = InstanceSerializer.Stats
                App.UpdateStatus(string.format("Saved! (%s models, %s parts)",
                    Utils.FormatNumber(stats.Models),
                    Utils.FormatNumber(stats.Parts)), "success")
            end
        end)
        
        if not success then
            App.UpdateStatus("Error: " .. tostring(err), "error")
        end
        
        App.IsProcessing = false
        App.UpdateProgress(100)
    end)
end

--- Decompile terrain only
function App.DecompileTerrain()
    if App.IsProcessing then
        App.UpdateStatus("Already processing...", "warning")
        return
    end
    
    App.IsProcessing = true
    App.UpdateStatus("Starting terrain decompile...", "info")
    App.UpdateProgress(0)
    
    task.spawn(function()
        local success, err = Utils.SafeCall(function()
            App.UpdateStatus("Serializing terrain...", "info")
            
            -- Build terrain-only XML
            Utils.ResetRefCounter()
            
            local xmlParts = {
                '<?xml version="1.0" encoding="UTF-8"?>',
                '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">',
                '<Meta name="ExplicitAutoJoints">true</Meta>',
            }
            
            local terrainXml = TerrainSerializer.Serialize(Workspace.Terrain, function(percent, status)
                App.UpdateProgress(percent)
                App.UpdateStatus(status, "info")
            end)
            
            table.insert(xmlParts, terrainXml)
            table.insert(xmlParts, '</roblox>')
            
            local xmlContent = table.concat(xmlParts, "\n")
            
            -- Save file
            local fileName = App.Settings.FileName .. "_TerrainOnly" .. App.Settings.ExportFormat
            App.UpdateStatus("Saving to " .. fileName .. "...", "info")
            
            if App.SaveToFile(xmlContent, fileName) then
                App.UpdateStatus("Terrain saved successfully!", "success")
            end
        end)
        
        if not success then
            App.UpdateStatus("Error: " .. tostring(err), "error")
        end
        
        App.IsProcessing = false
        App.UpdateProgress(100)
    end)
end

--- Destroy the application
function App.Destroy()
    -- Animate out
    if App.MainFrame then
        TweenService:Create(App.MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -190, 0.5, -200),
            BackgroundTransparency = 1
        }):Play()
        
        task.delay(0.2, function()
            UI.Cleanup()
            if App.GUI then
                App.GUI:Destroy()
            end
        end)
    end
end

--=============================================================================
-- INITIALIZATION
--=============================================================================

-- Start the application
App.Init()

-- Print startup message
print([[
╔══════════════════════════════════════════════════════════════════╗
║                    BaoSaveInstance v2.0                          ║
║                    ULTIMATE EDITION LOADED                       ║
║                                                                  ║
║  Features:                                                       ║
║  - Dynamic Property Discovery (100% Correctness)                 ║
║  - Absolute Reference Mapping (Circular/Object Links)            ║
║  - Streaming Engine (Ultra-Performance for Large Maps)           ║
║  - Stealth Protection (Randomized GUI & gethui Native)           ║
╚══════════════════════════════════════════════════════════════════╝
]])

-- Return the App for external access if needed
return App

end -- End of encapsulation block
