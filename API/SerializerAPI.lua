--[[
    BaoSaveInstance API Framework
    File: API/SerializerAPI.lua
    Description: Property & Instance Serialization System
]]

local HttpService = game:GetService("HttpService")

local SerializerAPI = {}

--// ═══════════════════════════════════════════════════════════════════════════
--// INTERNAL STATE
--// ═══════════════════════════════════════════════════════════════════════════

local CustomSerializers = {}
local PropertyCache = {}
local ReferentCounter = 0
local ReferentMap = {}

--// ═══════════════════════════════════════════════════════════════════════════
--// BUILT-IN TYPE SERIALIZERS
--// ═══════════════════════════════════════════════════════════════════════════

local BuiltInSerializers = {
    ["string"] = function(value)
        return tostring(value):gsub("[<>&\"']", {
            ["<"] = "&lt;",
            [">"] = "&gt;",
            ["&"] = "&amp;",
            ['"'] = "&quot;",
            ["'"] = "&apos;"
        }):gsub("[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "")
    end,
    
    ["number"] = function(value)
        if value ~= value then return "NAN" end
        if value == math.huge then return "INF" end
        if value == -math.huge then return "-INF" end
        return tostring(value)
    end,
    
    ["boolean"] = function(value)
        return value and "true" or "false"
    end,
    
    ["nil"] = function()
        return "null"
    end,
    
    ["Vector3"] = function(value)
        return string.format("<X>%.6f</X><Y>%.6f</Y><Z>%.6f</Z>", 
            value.X, value.Y, value.Z)
    end,
    
    ["Vector2"] = function(value)
        return string.format("<X>%.6f</X><Y>%.6f</Y>", value.X, value.Y)
    end,
    
    ["CFrame"] = function(value)
        local components = {value:GetComponents()}
        local formatted = {}
        for _, c in ipairs(components) do
            table.insert(formatted, string.format("%.6f", c))
        end
        return table.concat(formatted, " ")
    end,
    
    ["Color3"] = function(value)
        return string.format("%.6f %.6f %.6f", value.R, value.G, value.B)
    end,
    
    ["BrickColor"] = function(value)
        return tostring(value.Number)
    end,
    
    ["UDim"] = function(value)
        return string.format("<S>%.6f</S><O>%d</O>", value.Scale, value.Offset)
    end,
    
    ["UDim2"] = function(value)
        return string.format(
            "<XS>%.6f</XS><XO>%d</XO><YS>%.6f</YS><YO>%d</YO>",
            value.X.Scale, value.X.Offset,
            value.Y.Scale, value.Y.Offset
        )
    end,
    
    ["Rect"] = function(value)
        return string.format(
            "<min><X>%.6f</X><Y>%.6f</Y></min><max><X>%.6f</X><Y>%.6f</Y></max>",
            value.Min.X, value.Min.Y,
            value.Max.X, value.Max.Y
        )
    end,
    
    ["NumberSequence"] = function(value)
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%.6f %.6f %.6f", 
                kp.Time, kp.Value, kp.Envelope))
        end
        return table.concat(keypoints, " ")
    end,
    
    ["ColorSequence"] = function(value)
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%.6f %.6f %.6f %.6f", 
                kp.Time, kp.Value.R, kp.Value.G, kp.Value.B))
        end
        return table.concat(keypoints, " ")
    end,
    
    ["NumberRange"] = function(value)
        return string.format("%.6f %.6f", value.Min, value.Max)
    end,
    
    ["Ray"] = function(value)
        return string.format(
            "<origin><X>%.6f</X><Y>%.6f</Y><Z>%.6f</Z></origin>" ..
            "<direction><X>%.6f</X><Y>%.6f</Y><Z>%.6f</Z></direction>",
            value.Origin.X, value.Origin.Y, value.Origin.Z,
            value.Direction.X, value.Direction.Y, value.Direction.Z
        )
    end,
    
    ["Region3"] = function(value)
        local cf = value.CFrame
        local size = value.Size
        return string.format(
            "<CFrame>%s</CFrame><Size><X>%.6f</X><Y>%.6f</Y><Z>%.6f</Z></Size>",
            BuiltInSerializers.CFrame(cf), size.X, size.Y, size.Z
        )
    end,
    
    ["Faces"] = function(value)
        local faces = {}
        if value.Top then table.insert(faces, "Top") end
        if value.Bottom then table.insert(faces, "Bottom") end
        if value.Left then table.insert(faces, "Left") end
        if value.Right then table.insert(faces, "Right") end
        if value.Front then table.insert(faces, "Front") end
        if value.Back then table.insert(faces, "Back") end
        return table.concat(faces, ",")
    end,
    
    ["Axes"] = function(value)
        local axes = {}
        if value.X then table.insert(axes, "X") end
        if value.Y then table.insert(axes, "Y") end
        if value.Z then table.insert(axes, "Z") end
        return table.concat(axes, ",")
    end,
    
    ["EnumItem"] = function(value)
        return tostring(value.Value)
    end,
    
    ["Enum"] = function(value)
        return tostring(value)
    end,
    
    ["PhysicalProperties"] = function(value)
        if value then
            return string.format(
                "<CustomPhysics>true</CustomPhysics>" ..
                "<Density>%.6f</Density><Friction>%.6f</Friction>" ..
                "<Elasticity>%.6f</Elasticity><FrictionWeight>%.6f</FrictionWeight>" ..
                "<ElasticityWeight>%.6f</ElasticityWeight>",
                value.Density, value.Friction, value.Elasticity,
                value.FrictionWeight, value.ElasticityWeight
            )
        end
        return "<CustomPhysics>false</CustomPhysics>"
    end,
    
    ["Font"] = function(value)
        return string.format(
            "<Family><url>%s</url></Family><Weight>%d</Weight><Style>%s</Style>",
            value.Family, value.Weight.Value, value.Style.Name
        )
    end,
    
    ["Instance"] = function(value, referentMap)
        if referentMap and referentMap[value] then
            return referentMap[value]
        end
        return "null"
    end,
    
    ["Content"] = function(value)
        return string.format("<url>%s</url>", tostring(value):gsub("[<>&]", {
            ["<"] = "&lt;", [">"] = "&gt;", ["&"] = "&amp;"
        }))
    end,
    
    ["SharedString"] = function(value)
        return tostring(value)
    end,
    
    ["TweenInfo"] = function(value)
        return string.format(
            "<Time>%.6f</Time><EasingStyle>%d</EasingStyle><EasingDirection>%d</EasingDirection>" ..
            "<RepeatCount>%d</RepeatCount><Reverses>%s</Reverses><DelayTime>%.6f</DelayTime>",
            value.Time, value.EasingStyle.Value, value.EasingDirection.Value,
            value.RepeatCount, value.Reverses and "true" or "false", value.DelayTime
        )
    end,
    
    ["DateTime"] = function(value)
        return tostring(value.UnixTimestampMillis)
    end,
    
    ["PathWaypoint"] = function(value)
        return string.format(
            "<Position><X>%.6f</X><Y>%.6f</Y><Z>%.6f</Z></Position><Action>%d</Action>",
            value.Position.X, value.Position.Y, value.Position.Z,
            value.Action.Value
        )
    end,
    
    ["OverlapParams"] = function(value)
        return string.format(
            "<FilterType>%d</FilterType><MaxParts>%d</MaxParts>",
            value.FilterType.Value, value.MaxParts
        )
    end,
    
    ["RaycastParams"] = function(value)
        return string.format(
            "<FilterType>%d</FilterType><IgnoreWater>%s</IgnoreWater>",
            value.FilterType.Value, value.IgnoreWater and "true" or "false"
        )
    end,
}

--// ═══════════════════════════════════════════════════════════════════════════
--// PROPERTY DATABASE
--// ═══════════════════════════════════════════════════════════════════════════

SerializerAPI.PropertyDatabase = {
    -- BasePart
    BasePart = {
        "Name", "Anchored", "CanCollide", "CanTouch", "CanQuery", "CastShadow",
        "Color", "Material", "MaterialVariant", "Reflectance", "Transparency",
        "Size", "CFrame", "Position", "Orientation", "Massless", "RootPriority",
        "CollisionGroup", "Locked", "BrickColor", "CustomPhysicalProperties",
        "TopSurface", "BottomSurface", "LeftSurface", "RightSurface", 
        "FrontSurface", "BackSurface", "AssemblyLinearVelocity", "AssemblyAngularVelocity"
    },
    
    -- Part
    Part = {"Shape"},
    
    -- MeshPart
    MeshPart = {"MeshId", "TextureID", "DoubleSided", "RenderFidelity", "CollisionFidelity"},
    
    -- UnionOperation
    UnionOperation = {"UsePartColor", "SmoothingAngle", "RenderFidelity", "CollisionFidelity"},
    
    -- Model
    Model = {"Name", "PrimaryPart", "WorldPivot", "ModelStreamingMode", "LevelOfDetail"},
    
    -- Folder
    Folder = {"Name"},
    
    -- Scripts
    Script = {"Name", "Disabled", "Source"},
    LocalScript = {"Name", "Disabled", "Source"},
    ModuleScript = {"Name", "Source"},
    
    -- Humanoid
    Humanoid = {
        "Name", "DisplayDistanceType", "DisplayName", "Health", "HealthDisplayDistance",
        "HealthDisplayType", "HipHeight", "JumpHeight", "JumpPower", "MaxHealth",
        "MaxSlopeAngle", "NameDisplayDistance", "NameOcclusion", "RigType",
        "UseJumpPower", "WalkSpeed", "AutoRotate", "AutomaticScalingEnabled",
        "BreakJointsOnDeath", "RequiresNeck"
    },
    
    -- Attachment
    Attachment = {"Name", "CFrame", "Visible"},
    
    -- Constraints
    WeldConstraint = {"Name", "Enabled", "Part0", "Part1"},
    Weld = {"Name", "C0", "C1", "Part0", "Part1", "Enabled"},
    Motor6D = {"Name", "C0", "C1", "Part0", "Part1", "Enabled", "CurrentAngle", "DesiredAngle", "MaxVelocity"},
    
    -- Decal/Texture
    Decal = {"Name", "Color3", "Face", "Texture", "Transparency", "ZIndex"},
    Texture = {"Name", "Color3", "Face", "Texture", "Transparency", "ZIndex", 
               "OffsetStudsU", "OffsetStudsV", "StudsPerTileU", "StudsPerTileV"},
    
    -- SurfaceAppearance
    SurfaceAppearance = {"Name", "AlphaMode", "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap"},
    
    -- Sound
    Sound = {
        "Name", "SoundId", "Volume", "Looped", "PlaybackSpeed", "Playing",
        "RollOffMaxDistance", "RollOffMinDistance", "RollOffMode", "SoundGroup",
        "TimePosition", "PlayOnRemove", "EmitterSize"
    },
    
    -- ParticleEmitter
    ParticleEmitter = {
        "Name", "Enabled", "Texture", "Color", "Size", "Transparency", "Lifetime",
        "Rate", "Speed", "SpreadAngle", "Rotation", "RotSpeed", "Acceleration",
        "Drag", "LightEmission", "LightInfluence", "LockedToPart", "Orientation",
        "ZOffset", "EmissionDirection", "Shape", "ShapeInOut", "ShapeStyle"
    },
    
    -- Lights
    PointLight = {"Name", "Enabled", "Brightness", "Color", "Range", "Shadows"},
    SpotLight = {"Name", "Enabled", "Brightness", "Color", "Range", "Shadows", "Angle", "Face"},
    SurfaceLight = {"Name", "Enabled", "Brightness", "Color", "Range", "Shadows", "Angle", "Face"},
    
    -- GUI
    ScreenGui = {"Name", "DisplayOrder", "Enabled", "IgnoreGuiInset", "ResetOnSpawn", "ZIndexBehavior"},
    BillboardGui = {"Name", "Adornee", "AlwaysOnTop", "Size", "SizeOffset", "StudsOffset", "LightInfluence", "MaxDistance"},
    SurfaceGui = {"Name", "Adornee", "AlwaysOnTop", "CanvasSize", "Face", "LightInfluence", "PixelsPerStud", "SizingMode"},
    
    Frame = {
        "Name", "Active", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency",
        "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants",
        "LayoutOrder", "Position", "Rotation", "Size", "SizeConstraint", "Visible", "ZIndex"
    },
    
    TextLabel = {
        "Name", "Active", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency",
        "BorderColor3", "BorderSizePixel", "Position", "Size", "Visible", "ZIndex",
        "Font", "Text", "TextColor3", "TextScaled", "TextSize", "TextTransparency",
        "TextWrapped", "TextXAlignment", "TextYAlignment", "RichText"
    },
    
    TextButton = {
        "Name", "Active", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency",
        "Position", "Size", "Visible", "ZIndex", "AutoButtonColor",
        "Font", "Text", "TextColor3", "TextScaled", "TextSize"
    },
    
    TextBox = {
        "Name", "Active", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency",
        "Position", "Size", "Visible", "ZIndex", "ClearTextOnFocus", "MultiLine",
        "Font", "Text", "TextColor3", "TextScaled", "TextSize", "PlaceholderText", "PlaceholderColor3"
    },
    
    ImageLabel = {
        "Name", "Active", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency",
        "Position", "Size", "Visible", "ZIndex", "Image", "ImageColor3",
        "ImageRectOffset", "ImageRectSize", "ImageTransparency", "ScaleType", "SliceCenter"
    },
    
    ImageButton = {
        "Name", "Active", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency",
        "Position", "Size", "Visible", "ZIndex", "Image", "ImageColor3",
        "ImageTransparency", "AutoButtonColor", "HoverImage", "PressedImage"
    },
    
    -- UI Components
    UICorner = {"Name", "CornerRadius"},
    UIStroke = {"Name", "Color", "Thickness", "Transparency", "Enabled", "ApplyStrokeMode", "LineJoinMode"},
    UIPadding = {"Name", "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight"},
    UIScale = {"Name", "Scale"},
    UIListLayout = {"Name", "Padding", "FillDirection", "HorizontalAlignment", "SortOrder", "VerticalAlignment", "Wraps"},
    UIGridLayout = {"Name", "CellPadding", "CellSize", "FillDirection", "HorizontalAlignment", "SortOrder", "VerticalAlignment", "StartCorner"},
    UIAspectRatioConstraint = {"Name", "AspectRatio", "AspectType", "DominantAxis"},
    UISizeConstraint = {"Name", "MaxSize", "MinSize"},
    UITextSizeConstraint = {"Name", "MaxTextSize", "MinTextSize"},
    UIGradient = {"Name", "Color", "Transparency", "Offset", "Rotation", "Enabled"},
    
    -- Lighting
    Lighting = {
        "Ambient", "Brightness", "ColorShift_Bottom", "ColorShift_Top",
        "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows",
        "OutdoorAmbient", "ShadowSoftness", "Technology", "ClockTime",
        "GeographicLatitude", "TimeOfDay", "ExposureCompensation", "FogColor",
        "FogEnd", "FogStart"
    },
    
    -- Sky/Atmosphere
    Sky = {
        "Name", "CelestialBodiesShown", "MoonAngularSize", "MoonTextureId",
        "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp",
        "StarCount", "SunAngularSize", "SunTextureId"
    },
    
    Atmosphere = {"Name", "Color", "Decay", "Density", "Glare", "Haze", "Offset"},
    Clouds = {"Name", "Color", "Cover", "Density", "Enabled"},
    
    -- Post-processing
    BloomEffect = {"Name", "Enabled", "Intensity", "Size", "Threshold"},
    BlurEffect = {"Name", "Enabled", "Size"},
    ColorCorrectionEffect = {"Name", "Enabled", "Brightness", "Contrast", "Saturation", "TintColor"},
    DepthOfFieldEffect = {"Name", "Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"},
    SunRaysEffect = {"Name", "Enabled", "Intensity", "Spread"},
    
    -- Camera
    Camera = {"Name", "CFrame", "FieldOfView", "FieldOfViewMode", "CameraType", "Focus"},
    
    -- Tools
    Tool = {"Name", "CanBeDropped", "Enabled", "Grip", "GripForward", "GripPos", "GripRight", "GripUp", "ManualActivationOnly", "RequiresHandle", "ToolTip"},
    
    -- Accessory
    Accessory = {"Name", "AccessoryType", "AttachmentPoint"},
    
    -- Clothing
    Shirt = {"Name", "ShirtTemplate", "Color3"},
    Pants = {"Name", "PantsTemplate", "Color3"},
    ShirtGraphic = {"Name", "Graphic", "Color3"},
    
    -- BodyColors
    BodyColors = {
        "Name", "HeadColor", "HeadColor3", "LeftArmColor", "LeftArmColor3",
        "LeftLegColor", "LeftLegColor3", "RightArmColor", "RightArmColor3",
        "RightLegColor", "RightLegColor3", "TorsoColor", "TorsoColor3"
    },
    
    -- Mesh
    SpecialMesh = {"Name", "MeshId", "MeshType", "Offset", "Scale", "TextureId", "VertexColor"},
    BlockMesh = {"Name", "Offset", "Scale", "VertexColor"},
    CylinderMesh = {"Name", "Offset", "Scale", "VertexColor"},
    
    -- Beam/Trail
    Beam = {
        "Name", "Attachment0", "Attachment1", "Enabled", "Color", "Transparency",
        "Brightness", "LightEmission", "LightInfluence", "Texture", "TextureLength",
        "TextureMode", "TextureSpeed", "Width0", "Width1", "CurveSize0", "CurveSize1",
        "FaceCamera", "Segments", "ZOffset"
    },
    
    Trail = {
        "Name", "Attachment0", "Attachment1", "Enabled", "Color", "Transparency",
        "Brightness", "LightEmission", "LightInfluence", "Texture", "TextureLength",
        "TextureMode", "Lifetime", "MinLength", "MaxLength", "WidthScale", "FaceCamera"
    },
    
    -- Value Objects
    StringValue = {"Name", "Value"},
    NumberValue = {"Name", "Value"},
    IntValue = {"Name", "Value"},
    BoolValue = {"Name", "Value"},
    ObjectValue = {"Name", "Value"},
    Vector3Value = {"Name", "Value"},
    CFrameValue = {"Name", "Value"},
    Color3Value = {"Name", "Value"},
    BrickColorValue = {"Name", "Value"},
    RayValue = {"Name", "Value"},
    
    -- SpawnLocation
    SpawnLocation = {"Name", "AllowTeamChangeOnTouch", "Duration", "Enabled", "Neutral", "TeamColor"},
    
    -- Misc
    Fire = {"Name", "Enabled", "Color", "SecondaryColor", "Heat", "Size", "TimeScale"},
    Smoke = {"Name", "Enabled", "Color", "Opacity", "RiseVelocity", "Size", "TimeScale"},
    Sparkles = {"Name", "Enabled", "SparkleColor", "TimeScale"},
    Explosion = {"Name", "BlastPressure", "BlastRadius", "DestroyJointRadiusPercent", "Position", "Visible"},
}

--// ═══════════════════════════════════════════════════════════════════════════
--// HIDDEN PROPERTIES
--// ═══════════════════════════════════════════════════════════════════════════

SerializerAPI.HiddenProperties = {
    BasePart = {"PhysicalConfigData"},
    MeshPart = {"InitialSize", "PhysicsData"},
    Part = {"FormFactor"},
    Humanoid = {"InternalHeadScale", "InternalBodyScale"},
    Sound = {"IsLoaded"},
    LocalScript = {"LinkedSource"},
    ModuleScript = {"LinkedSource"},
    Script = {"LinkedSource"},
}

--// ═══════════════════════════════════════════════════════════════════════════
--// IGNORED PROPERTIES
--// ═══════════════════════════════════════════════════════════════════════════

SerializerAPI.IgnoredProperties = {
    "Parent", "ClassName", "Archivable", "RobloxLocked",
    "DataCost", "PropertyStatusStudio", "Tags"
}

--// ═══════════════════════════════════════════════════════════════════════════
--// PUBLIC API
--// ═══════════════════════════════════════════════════════════════════════════

-- Register custom serializer
function SerializerAPI.Register(typeName, serializer)
    if type(serializer) ~= "function" then
        return false, "Serializer must be a function"
    end
    CustomSerializers[typeName] = serializer
    return true
end

-- Unregister custom serializer
function SerializerAPI.Unregister(typeName)
    CustomSerializers[typeName] = nil
    return true
end

-- Get serializer for type
function SerializerAPI.GetSerializer(typeName)
    return CustomSerializers[typeName] or BuiltInSerializers[typeName]
end

-- Serialize single value
function SerializerAPI.SerializeValue(value, referentMap)
    local valueType = typeof(value)
    local serializer = SerializerAPI.GetSerializer(valueType)
    
    if serializer then
        local success, result = pcall(function()
            if valueType == "Instance" then
                return serializer(value, referentMap)
            else
                return serializer(value)
            end
        end)
        
        if success then
            return result, valueType
        end
    end
    
    -- Fallback
    return tostring(value), valueType
end

-- Get properties for class
function SerializerAPI.GetPropertiesForClass(className)
    local properties = {}
    local added = {}
    
    local function addProps(propList)
        if propList then
            for _, prop in ipairs(propList) do
                if not added[prop] then
                    table.insert(properties, prop)
                    added[prop] = true
                end
            end
        end
    end
    
    -- Class inheritance map
    local inheritance = {
        Part = {"BasePart", "Part"},
        MeshPart = {"BasePart", "MeshPart"},
        UnionOperation = {"BasePart", "UnionOperation"},
        WedgePart = {"BasePart"},
        CornerWedgePart = {"BasePart"},
        TrussPart = {"BasePart"},
        SpawnLocation = {"BasePart", "SpawnLocation"},
        Seat = {"BasePart"},
        VehicleSeat = {"BasePart"},
        TextLabel = {"Frame", "TextLabel"},
        TextButton = {"Frame", "TextButton"},
        TextBox = {"Frame", "TextBox"},
        ImageLabel = {"Frame", "ImageLabel"},
        ImageButton = {"Frame", "ImageButton"},
        ScrollingFrame = {"Frame"},
        ViewportFrame = {"Frame"},
        CanvasGroup = {"Frame"},
    }
    
    local classes = inheritance[className] or {className}
    for _, class in ipairs(classes) do
        addProps(SerializerAPI.PropertyDatabase[class])
    end
    
    -- Always add Name if not present
    if not added["Name"] then
        table.insert(properties, 1, "Name")
    end
    
    return properties
end

-- Serialize instance properties
function SerializerAPI.SerializeInstance(instance, referentMap, options)
    options = options or {}
    
    local className = instance.ClassName
    local properties = {}
    local propsToSerialize = options.Properties or SerializerAPI.GetPropertiesForClass(className)
    
    for _, propName in ipairs(propsToSerialize) do
        -- Skip ignored properties
        local ignored = false
        for _, ignoredProp in ipairs(SerializerAPI.IgnoredProperties) do
            if propName == ignoredProp then
                ignored = true
                break
            end
        end
        
        if not ignored then
            local success, value = pcall(function()
                return instance[propName]
            end)
            
            if success and value ~= nil then
                local serialized, valueType = SerializerAPI.SerializeValue(value, referentMap)
                if serialized then
                    properties[propName] = {
                        Value = serialized,
                        Type = valueType,
                    }
                end
            end
        end
    end
    
    -- Try hidden properties if gethiddenproperty available
    if gethiddenproperty and options.IncludeHidden ~= false then
        local hiddenProps = SerializerAPI.HiddenProperties[className]
        if hiddenProps then
            for _, propName in ipairs(hiddenProps) do
                local success, value = pcall(function()
                    return gethiddenproperty(instance, propName)
                end)
                
                if success and value ~= nil then
                    local serialized, valueType = SerializerAPI.SerializeValue(value, referentMap)
                    if serialized then
                        properties[propName] = {
                            Value = serialized,
                            Type = valueType,
                            Hidden = true,
                        }
                    end
                end
            end
        end
    end
    
    return properties
end

-- Serialize attributes
function SerializerAPI.SerializeAttributes(instance, referentMap)
    local attributes = {}
    
    local success, attrs = pcall(function()
        return instance:GetAttributes()
    end)
    
    if success and attrs then
        for attrName, attrValue in pairs(attrs) do
            local serialized, valueType = SerializerAPI.SerializeValue(attrValue, referentMap)
            if serialized then
                attributes[attrName] = {
                    Value = serialized,
                    Type = valueType,
                }
            end
        end
    end
    
    return attributes
end

-- Generate referent ID
function SerializerAPI.GetReferent(instance)
    if not ReferentMap[instance] then
        ReferentCounter = ReferentCounter + 1
        ReferentMap[instance] = "RBX" .. tostring(ReferentCounter)
    end
    return ReferentMap[instance]
end

-- Reset referent counter
function SerializerAPI.ResetReferents()
    ReferentCounter = 0
    ReferentMap = {}
end

-- Get referent map
function SerializerAPI.GetReferentMap()
    return ReferentMap
end

-- List registered serializers
function SerializerAPI.ListSerializers()
    local list = {}
    
    for typeName, _ in pairs(BuiltInSerializers) do
        table.insert(list, {Name = typeName, Custom = false})
    end
    
    for typeName, _ in pairs(CustomSerializers) do
        table.insert(list, {Name = typeName, Custom = true})
    end
    
    return list
end

-- Map value type to XML type name
function SerializerAPI.GetXMLTypeName(valueType)
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
        ["Content"] = "Content",
    }
    
    return typeMap[valueType] or "string"
end

-- Serialize to JSON
function SerializerAPI.ToJSON(instance, options)
    options = options or {}
    
    local data = {
        ClassName = instance.ClassName,
        Name = instance.Name,
        Properties = SerializerAPI.SerializeInstance(instance, nil, options),
        Attributes = SerializerAPI.SerializeAttributes(instance),
        Children = {},
    }
    
    if options.IncludeChildren ~= false then
        local success, children = pcall(function()
            return instance:GetChildren()
        end)
        
        if success then
            for _, child in ipairs(children) do
                local childData = SerializerAPI.ToJSON(child, options)
                table.insert(data.Children, childData)
            end
        end
    end
    
    return data
end

-- Clear cache
function SerializerAPI.ClearCache()
    PropertyCache = {}
    SerializerAPI.ResetReferents()
end

return SerializerAPI