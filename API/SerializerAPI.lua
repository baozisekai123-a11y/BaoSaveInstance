--[[
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                       BaoSaveInstance API Framework v3.0                              ║
║                              API/SerializerAPI.lua                                    ║
╠══════════════════════════════════════════════════════════════════════════════════════╣
║  File: API/SerializerAPI.lua                                                         ║
║  Description: Property serialization system for all Roblox types                     ║
╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local SerializerAPI = {}

--// ═══════════════════════════════════════════════════════════════════════════════════
--// SERVICES
--// ═══════════════════════════════════════════════════════════════════════════════════

local HttpService = game:GetService("HttpService")

--// ═══════════════════════════════════════════════════════════════════════════════════
--// INTERNAL STATE
--// ═══════════════════════════════════════════════════════════════════════════════════

local CustomSerializers = {}
local CustomDeserializers = {}
local ReferenceMap = {}
local ReferenceCounter = 0

--// ═══════════════════════════════════════════════════════════════════════════════════
--// UTILITY FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════════════

local function EscapeXML(str)
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
    
    for char, replacement in pairs(replacements) do
        str = str:gsub(char, replacement)
    end
    
    -- Remove invalid XML characters
    str = str:gsub("[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "")
    
    return str
end

local function SafeToString(value)
    local success, result = pcall(tostring, value)
    return success and result or "???"
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// BUILT-IN TYPE SERIALIZERS
--// ═══════════════════════════════════════════════════════════════════════════════════

local BuiltInSerializers = {
    --// Primitive Types
    ["string"] = function(value)
        return {
            Type = "string",
            Value = EscapeXML(value),
            Raw = value,
        }
    end,
    
    ["number"] = function(value)
        local strValue
        if value ~= value then -- NaN
            strValue = "NAN"
        elseif value == math.huge then
            strValue = "INF"
        elseif value == -math.huge then
            strValue = "-INF"
        else
            strValue = tostring(value)
        end
        
        return {
            Type = "number",
            Value = strValue,
            Raw = value,
        }
    end,
    
    ["boolean"] = function(value)
        return {
            Type = "bool",
            Value = value and "true" or "false",
            Raw = value,
        }
    end,
    
    ["nil"] = function(value)
        return {
            Type = "null",
            Value = "null",
            Raw = nil,
        }
    end,
    
    --// Vector Types
    ["Vector3"] = function(value)
        return {
            Type = "Vector3",
            Value = string.format("<X>%s</X><Y>%s</Y><Z>%s</Z>", 
                tostring(value.X), tostring(value.Y), tostring(value.Z)),
            Components = {X = value.X, Y = value.Y, Z = value.Z},
            Raw = value,
        }
    end,
    
    ["Vector2"] = function(value)
        return {
            Type = "Vector2",
            Value = string.format("<X>%s</X><Y>%s</Y>", 
                tostring(value.X), tostring(value.Y)),
            Components = {X = value.X, Y = value.Y},
            Raw = value,
        }
    end,
    
    ["Vector3int16"] = function(value)
        return {
            Type = "Vector3int16",
            Value = string.format("<X>%d</X><Y>%d</Y><Z>%d</Z>", 
                value.X, value.Y, value.Z),
            Components = {X = value.X, Y = value.Y, Z = value.Z},
            Raw = value,
        }
    end,
    
    ["Vector2int16"] = function(value)
        return {
            Type = "Vector2int16",
            Value = string.format("<X>%d</X><Y>%d</Y>", value.X, value.Y),
            Components = {X = value.X, Y = value.Y},
            Raw = value,
        }
    end,
    
    --// CFrame
    ["CFrame"] = function(value)
        local components = {value:GetComponents()}
        return {
            Type = "CoordinateFrame",
            Value = table.concat(components, " "),
            Components = components,
            Raw = value,
        }
    end,
    
    --// Color Types
    ["Color3"] = function(value)
        return {
            Type = "Color3",
            Value = string.format("<R>%s</R><G>%s</G><B>%s</B>",
                tostring(value.R), tostring(value.G), tostring(value.B)),
            Components = {R = value.R, G = value.G, B = value.B},
            Hex = string.format("#%02X%02X%02X", 
                math.floor(value.R * 255), 
                math.floor(value.G * 255), 
                math.floor(value.B * 255)),
            Raw = value,
        }
    end,
    
    ["BrickColor"] = function(value)
        return {
            Type = "BrickColor",
            Value = tostring(value.Number),
            Name = value.Name,
            Number = value.Number,
            Raw = value,
        }
    end,
    
    --// UDim Types
    ["UDim"] = function(value)
        return {
            Type = "UDim",
            Value = string.format("<S>%s</S><O>%d</O>", 
                tostring(value.Scale), value.Offset),
            Components = {Scale = value.Scale, Offset = value.Offset},
            Raw = value,
        }
    end,
    
    ["UDim2"] = function(value)
        return {
            Type = "UDim2",
            Value = string.format(
                "<XS>%s</XS><XO>%d</XO><YS>%s</YS><YO>%d</YO>",
                tostring(value.X.Scale), value.X.Offset,
                tostring(value.Y.Scale), value.Y.Offset
            ),
            Components = {
                X = {Scale = value.X.Scale, Offset = value.X.Offset},
                Y = {Scale = value.Y.Scale, Offset = value.Y.Offset},
            },
            Raw = value,
        }
    end,
    
    --// Rect
    ["Rect"] = function(value)
        return {
            Type = "Rect",
            Value = string.format(
                "<min><X>%s</X><Y>%s</Y></min><max><X>%s</X><Y>%s</Y></max>",
                tostring(value.Min.X), tostring(value.Min.Y),
                tostring(value.Max.X), tostring(value.Max.Y)
            ),
            Components = {
                Min = {X = value.Min.X, Y = value.Min.Y},
                Max = {X = value.Max.X, Y = value.Max.Y},
            },
            Raw = value,
        }
    end,
    
    --// Sequences
    ["NumberSequence"] = function(value)
        local keypoints = {}
        local xmlParts = {}
        
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, {
                Time = kp.Time,
                Value = kp.Value,
                Envelope = kp.Envelope,
            })
            table.insert(xmlParts, string.format("%s %s %s",
                tostring(kp.Time), tostring(kp.Value), tostring(kp.Envelope)))
        end
        
        return {
            Type = "NumberSequence",
            Value = table.concat(xmlParts, " "),
            Keypoints = keypoints,
            Raw = value,
        }
    end,
    
    ["ColorSequence"] = function(value)
        local keypoints = {}
        local xmlParts = {}
        
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, {
                Time = kp.Time,
                Color = {R = kp.Value.R, G = kp.Value.G, B = kp.Value.B},
            })
            table.insert(xmlParts, string.format("%s %s %s %s",
                tostring(kp.Time),
                tostring(kp.Value.R),
                tostring(kp.Value.G),
                tostring(kp.Value.B)))
        end
        
        return {
            Type = "ColorSequence",
            Value = table.concat(xmlParts, " "),
            Keypoints = keypoints,
            Raw = value,
        }
    end,
    
    --// NumberRange
    ["NumberRange"] = function(value)
        return {
            Type = "NumberRange",
            Value = string.format("%s %s", tostring(value.Min), tostring(value.Max)),
            Components = {Min = value.Min, Max = value.Max},
            Raw = value,
        }
    end,
    
    --// Enum Types
    ["Enum"] = function(value)
        return {
            Type = "Enum",
            Value = tostring(value),
            Raw = value,
        }
    end,
    
    ["EnumItem"] = function(value)
        return {
            Type = "token",
            Value = tostring(value.Value),
            Name = value.Name,
            EnumType = tostring(value.EnumType),
            Raw = value,
        }
    end,
    
    --// Font
    ["Font"] = function(value)
        return {
            Type = "Font",
            Value = string.format(
                "<Family><url>%s</url></Family><Weight>%d</Weight><Style>%s</Style>",
                EscapeXML(value.Family),
                value.Weight.Value,
                value.Style.Name
            ),
            Components = {
                Family = value.Family,
                Weight = value.Weight.Value,
                Style = value.Style.Name,
            },
            Raw = value,
        }
    end,
    
    --// Faces & Axes
    ["Faces"] = function(value)
        local faces = {}
        if value.Top then table.insert(faces, "Top") end
        if value.Bottom then table.insert(faces, "Bottom") end
        if value.Left then table.insert(faces, "Left") end
        if value.Right then table.insert(faces, "Right") end
        if value.Back then table.insert(faces, "Back") end
        if value.Front then table.insert(faces, "Front") end
        
        return {
            Type = "Faces",
            Value = table.concat(faces, ", "),
            Faces = faces,
            Raw = value,
        }
    end,
    
    ["Axes"] = function(value)
        local axes = {}
        if value.X then table.insert(axes, "X") end
        if value.Y then table.insert(axes, "Y") end
        if value.Z then table.insert(axes, "Z") end
        
        return {
            Type = "Axes",
            Value = table.concat(axes, ", "),
            Axes = axes,
            Raw = value,
        }
    end,
    
    --// Ray
    ["Ray"] = function(value)
        return {
            Type = "Ray",
            Value = string.format(
                "<origin><X>%s</X><Y>%s</Y><Z>%s</Z></origin><direction><X>%s</X><Y>%s</Y><Z>%s</Z></direction>",
                tostring(value.Origin.X), tostring(value.Origin.Y), tostring(value.Origin.Z),
                tostring(value.Direction.X), tostring(value.Direction.Y), tostring(value.Direction.Z)
            ),
            Components = {
                Origin = {X = value.Origin.X, Y = value.Origin.Y, Z = value.Origin.Z},
                Direction = {X = value.Direction.X, Y = value.Direction.Y, Z = value.Direction.Z},
            },
            Raw = value,
        }
    end,
    
    --// Region3
    ["Region3"] = function(value)
        local cf = value.CFrame
        local size = value.Size
        
        return {
            Type = "Region3",
            Value = string.format(
                "<CFrame>%s</CFrame><Size><X>%s</X><Y>%s</Y><Z>%s</Z></Size>",
                table.concat({cf:GetComponents()}, " "),
                tostring(size.X), tostring(size.Y), tostring(size.Z)
            ),
            Components = {
                CFrame = {cf:GetComponents()},
                Size = {X = size.X, Y = size.Y, Z = size.Z},
            },
            Raw = value,
        }
    end,
    
    --// PhysicalProperties
    ["PhysicalProperties"] = function(value)
        if value then
            return {
                Type = "PhysicalProperties",
                Value = string.format(
                    "<CustomPhysics>true</CustomPhysics><Density>%s</Density><Friction>%s</Friction><Elasticity>%s</Elasticity><FrictionWeight>%s</FrictionWeight><ElasticityWeight>%s</ElasticityWeight>",
                    tostring(value.Density),
                    tostring(value.Friction),
                    tostring(value.Elasticity),
                    tostring(value.FrictionWeight),
                    tostring(value.ElasticityWeight)
                ),
                Components = {
                    Density = value.Density,
                    Friction = value.Friction,
                    Elasticity = value.Elasticity,
                    FrictionWeight = value.FrictionWeight,
                    ElasticityWeight = value.ElasticityWeight,
                },
                Raw = value,
            }
        else
            return {
                Type = "PhysicalProperties",
                Value = "<CustomPhysics>false</CustomPhysics>",
                Components = nil,
                Raw = nil,
            }
        end
    end,
    
    --// Content (Asset URLs)
    ["Content"] = function(value)
        return {
            Type = "Content",
            Value = string.format("<url>%s</url>", EscapeXML(tostring(value))),
            URL = tostring(value),
            Raw = value,
        }
    end,
    
    --// Instance Reference
    ["Instance"] = function(value, referenceMap)
        if not value then
            return {
                Type = "Ref",
                Value = "null",
                Raw = nil,
            }
        end
        
        local ref = "null"
        if referenceMap and referenceMap[value] then
            ref = referenceMap[value]
        end
        
        return {
            Type = "Ref",
            Value = ref,
            InstanceName = value.Name,
            ClassName = value.ClassName,
            Raw = value,
        }
    end,
    
    --// TweenInfo
    ["TweenInfo"] = function(value)
        return {
            Type = "TweenInfo",
            Value = string.format("%s %s %s %s %s %s",
                tostring(value.Time),
                tostring(value.EasingStyle.Value),
                tostring(value.EasingDirection.Value),
                tostring(value.RepeatCount),
                tostring(value.Reverses),
                tostring(value.DelayTime)
            ),
            Components = {
                Time = value.Time,
                EasingStyle = value.EasingStyle.Name,
                EasingDirection = value.EasingDirection.Name,
                RepeatCount = value.RepeatCount,
                Reverses = value.Reverses,
                DelayTime = value.DelayTime,
            },
            Raw = value,
        }
    end,
    
    --// PathWaypoint
    ["PathWaypoint"] = function(value)
        return {
            Type = "PathWaypoint",
            Value = string.format("<Position><X>%s</X><Y>%s</Y><Z>%s</Z></Position><Action>%d</Action>",
                tostring(value.Position.X),
                tostring(value.Position.Y),
                tostring(value.Position.Z),
                value.Action.Value
            ),
            Components = {
                Position = {X = value.Position.X, Y = value.Position.Y, Z = value.Position.Z},
                Action = value.Action.Name,
            },
            Raw = value,
        }
    end,
    
    --// DateTime
    ["DateTime"] = function(value)
        return {
            Type = "DateTime",
            Value = tostring(value.UnixTimestampMillis),
            UnixTimestamp = value.UnixTimestamp,
            UnixTimestampMillis = value.UnixTimestampMillis,
            ISO = value:ToIsoDate(),
            Raw = value,
        }
    end,
    
    --// Table (for attributes)
    ["table"] = function(value)
        local success, json = pcall(function()
            return HttpService:JSONEncode(value)
        end)
        
        return {
            Type = "table",
            Value = success and json or "{}",
            Raw = value,
        }
    end,
    
    --// CatalogSearchParams
    ["CatalogSearchParams"] = function(value)
        return {
            Type = "CatalogSearchParams",
            Value = "CatalogSearchParams",
            Raw = value,
        }
    end,
    
    --// OverlapParams
    ["OverlapParams"] = function(value)
        return {
            Type = "OverlapParams",
            Value = "OverlapParams",
            Raw = value,
        }
    end,
    
    --// RaycastParams
    ["RaycastParams"] = function(value)
        return {
            Type = "RaycastParams",
            Value = "RaycastParams",
            FilterType = value.FilterType.Name,
            IgnoreWater = value.IgnoreWater,
            CollisionGroup = value.CollisionGroup,
            Raw = value,
        }
    end,
}

--// ═══════════════════════════════════════════════════════════════════════════════════
--// PROPERTY DATABASE
--// ═══════════════════════════════════════════════════════════════════════════════════

SerializerAPI.PropertyDatabase = {
    --// Common properties for all instances
    Common = {"Name", "Archivable"},
    
    --// BasePart
    BasePart = {
        "Anchored", "CanCollide", "CanQuery", "CanTouch", "CastShadow",
        "CFrame", "CollisionGroup", "Color", "Material", "MaterialVariant",
        "Massless", "Position", "Orientation", "Rotation", "Size",
        "Transparency", "Reflectance", "Locked", "RootPriority",
        "TopSurface", "BottomSurface", "LeftSurface", "RightSurface",
        "FrontSurface", "BackSurface", "BrickColor",
        "AssemblyLinearVelocity", "AssemblyAngularVelocity",
        "CustomPhysicalProperties",
    },
    
    --// Part
    Part = {"Shape"},
    
    --// MeshPart
    MeshPart = {
        "MeshId", "TextureID", "DoubleSided",
        "RenderFidelity", "CollisionFidelity",
    },
    
    --// UnionOperation
    UnionOperation = {
        "UsePartColor", "SmoothingAngle",
        "RenderFidelity", "CollisionFidelity",
    },
    
    --// Model
    Model = {
        "PrimaryPart", "WorldPivot", "ModelStreamingMode", "LevelOfDetail",
    },
    
    --// Scripts
    LuaSourceContainer = {"Disabled"},
    Script = {"RunContext"},
    LocalScript = {},
    ModuleScript = {},
    
    --// Humanoid
    Humanoid = {
        "DisplayDistanceType", "DisplayName", "Health", "MaxHealth",
        "HealthDisplayDistance", "HealthDisplayType", "HipHeight",
        "JumpHeight", "JumpPower", "MaxSlopeAngle", "NameDisplayDistance",
        "NameOcclusion", "RigType", "UseJumpPower", "WalkSpeed",
        "AutoRotate", "AutomaticScalingEnabled", "BreakJointsOnDeath",
        "RequiresNeck", "EvaluateStateMachine",
    },
    
    --// Camera
    Camera = {
        "CFrame", "Focus", "FieldOfView", "FieldOfViewMode", "CameraType",
        "HeadScale", "DiagonalFieldOfView", "MaxAxisFieldOfView",
        "VRTiltAndRollEnabled",
    },
    
    --// Lighting
    Lighting = {
        "Ambient", "Brightness", "ColorShift_Bottom", "ColorShift_Top",
        "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows",
        "OutdoorAmbient", "ShadowSoftness", "Technology", "ClockTime",
        "GeographicLatitude", "TimeOfDay", "ExposureCompensation",
        "FogColor", "FogEnd", "FogStart",
    },
    
    --// Attachment
    Attachment = {
        "CFrame", "Visible", "Axis", "SecondaryAxis", "Orientation", "Position",
    },
    
    --// Constraints
    Constraint = {"Enabled", "Visible", "Color", "Attachment0", "Attachment1"},
    WeldConstraint = {"Enabled", "Part0", "Part1"},
    
    --// Joints
    JointInstance = {"C0", "C1", "Part0", "Part1", "Enabled"},
    Motor6D = {"DesiredAngle", "MaxVelocity", "CurrentAngle"},
    
    --// Decals & Textures
    Decal = {"Color3", "Face", "LocalTransparencyModifier", "Texture", "Transparency", "ZIndex"},
    Texture = {"OffsetStudsU", "OffsetStudsV", "StudsPerTileU", "StudsPerTileV"},
    
    --// SurfaceAppearance
    SurfaceAppearance = {
        "AlphaMode", "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap",
    },
    
    --// Sound
    Sound = {
        "EmitterSize", "Looped", "MaxDistance", "MinDistance", "Pitch",
        "PlayOnRemove", "PlaybackSpeed", "RollOffMaxDistance", "RollOffMinDistance",
        "RollOffMode", "SoundId", "TimePosition", "Volume", "Playing",
    },
    
    --// GUI Objects
    GuiObject = {
        "Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3",
        "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel",
        "ClipsDescendants", "LayoutOrder", "Position", "Rotation",
        "Selectable", "Size", "SizeConstraint", "Visible", "ZIndex",
    },
    
    --// Text Objects
    TextLabel = {
        "Font", "FontFace", "LineHeight", "MaxVisibleGraphemes", "RichText",
        "Text", "TextColor3", "TextScaled", "TextSize", "TextStrokeColor3",
        "TextStrokeTransparency", "TextTransparency", "TextTruncate",
        "TextWrapped", "TextXAlignment", "TextYAlignment",
    },
    
    --// Image Objects
    ImageLabel = {
        "Image", "ImageColor3", "ImageRectOffset", "ImageRectSize",
        "ImageTransparency", "ResampleMode", "ScaleType", "SliceCenter",
        "SliceScale", "TileSize",
    },
    
    --// ScreenGui
    ScreenGui = {
        "DisplayOrder", "Enabled", "IgnoreGuiInset", "ResetOnSpawn",
        "ZIndexBehavior", "ClipToDeviceSafeArea",
    },
    
    --// BillboardGui
    BillboardGui = {
        "Active", "Adornee", "AlwaysOnTop", "Brightness", "ClipsDescendants",
        "DistanceLowerLimit", "DistanceStep", "DistanceUpperLimit",
        "ExtentsOffset", "LightInfluence", "MaxDistance", "Size",
        "SizeOffset", "StudsOffset",
    },
    
    --// SurfaceGui
    SurfaceGui = {
        "Active", "Adornee", "AlwaysOnTop", "Brightness", "CanvasSize",
        "ClipsDescendants", "Face", "LightInfluence", "PixelsPerStud",
        "SizingMode", "ZOffset",
    },
    
    --// UI Components
    UICorner = {"CornerRadius"},
    UIStroke = {"ApplyStrokeMode", "Color", "Enabled", "LineJoinMode", "Thickness", "Transparency"},
    UIPadding = {"PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"},
    UIScale = {"Scale"},
    UIAspectRatioConstraint = {"AspectRatio", "AspectType", "DominantAxis"},
    UISizeConstraint = {"MaxSize", "MinSize"},
    UIListLayout = {"FillDirection", "HorizontalAlignment", "Padding", "SortOrder", "VerticalAlignment", "Wraps"},
    UIGridLayout = {"CellPadding", "CellSize", "FillDirection", "FillDirectionMaxCells", "HorizontalAlignment", "SortOrder", "StartCorner", "VerticalAlignment"},
    
    --// Particles & Effects
    ParticleEmitter = {
        "Acceleration", "Brightness", "Color", "Drag", "EmissionDirection",
        "Enabled", "Lifetime", "LightEmission", "LightInfluence", "LockedToPart",
        "Orientation", "Rate", "RotSpeed", "Rotation", "Shape", "ShapeInOut",
        "ShapePartial", "ShapeStyle", "Size", "Speed", "SpreadAngle", "Squash",
        "Texture", "TimeScale", "Transparency", "VelocityInheritance", "ZOffset",
    },
    
    Beam = {
        "Attachment0", "Attachment1", "Brightness", "Color", "CurveSize0",
        "CurveSize1", "Enabled", "FaceCamera", "LightEmission", "LightInfluence",
        "Segments", "Texture", "TextureLength", "TextureMode", "TextureSpeed",
        "Transparency", "Width0", "Width1", "ZOffset",
    },
    
    Trail = {
        "Attachment0", "Attachment1", "Brightness", "Color", "Enabled",
        "FaceCamera", "Lifetime", "LightEmission", "LightInfluence",
        "MaxLength", "MinLength", "Texture", "TextureLength", "TextureMode",
        "Transparency", "WidthScale",
    },
    
    Fire = {"Color", "Enabled", "Heat", "SecondaryColor", "Size", "TimeScale"},
    Smoke = {"Color", "Enabled", "Opacity", "RiseVelocity", "Size", "TimeScale"},
    Sparkles = {"Color", "Enabled", "SparkleColor", "TimeScale"},
    
    --// Lights
    PointLight = {"Brightness", "Color", "Enabled", "Range", "Shadows"},
    SpotLight = {"Angle", "Brightness", "Color", "Enabled", "Face", "Range", "Shadows"},
    SurfaceLight = {"Angle", "Brightness", "Color", "Enabled", "Face", "Range", "Shadows"},
    
    --// Sky & Atmosphere
    Sky = {
        "CelestialBodiesShown", "MoonAngularSize", "MoonTextureId",
        "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp",
        "StarCount", "SunAngularSize", "SunTextureId",
    },
    
    Atmosphere = {"Color", "Decay", "Density", "Glare", "Haze", "Offset"},
    Clouds = {"Color", "Cover", "Density", "Enabled"},
    
    --// Post-processing
    BloomEffect = {"Enabled", "Intensity", "Size", "Threshold"},
    BlurEffect = {"Enabled", "Size"},
    ColorCorrectionEffect = {"Brightness", "Contrast", "Enabled", "Saturation", "TintColor"},
    DepthOfFieldEffect = {"Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"},
    SunRaysEffect = {"Enabled", "Intensity", "Spread"},
    
    --// Tool & Accessories
    Tool = {
        "CanBeDropped", "Enabled", "Grip", "GripForward", "GripPos",
        "GripRight", "GripUp", "ManualActivationOnly", "RequiresHandle", "ToolTip",
    },
    
    Accessory = {"AccessoryType"},
    
    --// Clothing
    Pants = {"PantsTemplate", "Color3"},
    Shirt = {"ShirtTemplate", "Color3"},
    ShirtGraphic = {"Color3", "Graphic"},
    
    --// BodyColors
    BodyColors = {
        "HeadColor", "HeadColor3", "LeftArmColor", "LeftArmColor3",
        "LeftLegColor", "LeftLegColor3", "RightArmColor", "RightArmColor3",
        "RightLegColor", "RightLegColor3", "TorsoColor", "TorsoColor3",
    },
    
    --// Mesh
    SpecialMesh = {"MeshId", "MeshType", "Offset", "Scale", "TextureId", "VertexColor"},
    DataModelMesh = {"Offset", "Scale", "VertexColor"},
    
    --// Value Objects
    StringValue = {"Value"},
    NumberValue = {"Value"},
    IntValue = {"Value"},
    BoolValue = {"Value"},
    ObjectValue = {"Value"},
    Vector3Value = {"Value"},
    CFrameValue = {"Value"},
    Color3Value = {"Value"},
    BrickColorValue = {"Value"},
    RayValue = {"Value"},
    
    --// SpawnLocation
    SpawnLocation = {
        "AllowTeamChangeOnTouch", "Duration", "Enabled", "Neutral", "TeamColor",
    },
    
    --// Team
    Team = {"AutoAssignable", "TeamColor"},
}

--// Hidden properties (require special access)
SerializerAPI.HiddenProperties = {
    BasePart = {"PhysicalConfigData", "SpecificGravity"},
    Part = {"FormFactor"},
    Humanoid = {"InternalHeadScale", "InternalBodyScale"},
    LocalScript = {"LinkedSource"},
    ModuleScript = {"LinkedSource"},
    Script = {"LinkedSource"},
    Sound = {"IsLoaded"},
    MeshPart = {"InitialSize", "PhysicsData", "HasJointOffset", "HasSkinnedMesh"},
}

--// Properties to ignore
SerializerAPI.IgnoredProperties = {
    "Parent", "ClassName", "DataCost", "RobloxLocked",
    "PropertyStatusStudio", "SourceAssetId",
}

--// ═══════════════════════════════════════════════════════════════════════════════════
--// PUBLIC API
--// ═══════════════════════════════════════════════════════════════════════════════════

-- Register custom serializer
function SerializerAPI.Register(typeName, serializer, deserializer)
    if type(serializer) ~= "function" then
        return false, "Serializer must be a function"
    end
    
    CustomSerializers[typeName] = serializer
    
    if deserializer then
        CustomDeserializers[typeName] = deserializer
    end
    
    return true
end

-- Unregister serializer
function SerializerAPI.Unregister(typeName)
    CustomSerializers[typeName] = nil
    CustomDeserializers[typeName] = nil
    return true
end

-- Get serializer for type
function SerializerAPI.GetSerializer(typeName)
    return CustomSerializers[typeName] or BuiltInSerializers[typeName]
end

-- Serialize a value
function SerializerAPI.Serialize(value, referenceMap)
    if value == nil then
        return BuiltInSerializers["nil"](value)
    end
    
    local valueType = typeof(value)
    
    -- Check custom serializers first
    local customSerializer = CustomSerializers[valueType]
    if customSerializer then
        local success, result = pcall(customSerializer, value, referenceMap)
        if success then
            return result
        end
    end
    
    -- Use built-in serializer
    local builtInSerializer = BuiltInSerializers[valueType]
    if builtInSerializer then
        local success, result = pcall(builtInSerializer, value, referenceMap)
        if success then
            return result
        end
    end
    
    -- Fallback
    return {
        Type = valueType,
        Value = SafeToString(value),
        Raw = value,
    }
end

-- Serialize value to XML string
function SerializerAPI.SerializeToXML(propName, value, referenceMap)
    local serialized = SerializerAPI.Serialize(value, referenceMap)
    
    if not serialized then
        return nil
    end
    
    return string.format('<%s name="%s">%s</%s>',
        serialized.Type,
        EscapeXML(propName),
        serialized.Value,
        serialized.Type
    )
end

-- Get properties for class
function SerializerAPI.GetPropertiesForClass(className)
    local properties = {}
    local added = {}
    
    -- Add common properties
    for _, prop in ipairs(SerializerAPI.PropertyDatabase.Common or {}) do
        if not added[prop] then
            table.insert(properties, prop)
            added[prop] = true
        end
    end
    
    -- Add class-specific properties
    local classProps = SerializerAPI.PropertyDatabase[className]
    if classProps then
        for _, prop in ipairs(classProps) do
            if not added[prop] then
                table.insert(properties, prop)
                added[prop] = true
            end
        end
    end
    
    -- Check parent classes
    local classHierarchy = {
        Part = {"BasePart"},
        MeshPart = {"BasePart"},
        UnionOperation = {"BasePart"},
        WedgePart = {"BasePart"},
        CornerWedgePart = {"BasePart"},
        TrussPart = {"BasePart"},
        SpawnLocation = {"BasePart"},
        Seat = {"BasePart"},
        VehicleSeat = {"BasePart"},
        Script = {"LuaSourceContainer"},
        LocalScript = {"LuaSourceContainer"},
        ModuleScript = {"LuaSourceContainer"},
        TextLabel = {"GuiObject"},
        TextButton = {"GuiObject", "TextLabel"},
        TextBox = {"GuiObject", "TextLabel"},
        ImageLabel = {"GuiObject"},
        ImageButton = {"GuiObject", "ImageLabel"},
        Frame = {"GuiObject"},
        ScrollingFrame = {"GuiObject"},
        ViewportFrame = {"GuiObject"},
        CanvasGroup = {"GuiObject"},
        VideoFrame = {"GuiObject"},
        Weld = {"JointInstance"},
        Motor = {"JointInstance"},
        Motor6D = {"JointInstance"},
        PointLight = {},
        SpotLight = {},
        SurfaceLight = {},
        SpecialMesh = {"DataModelMesh"},
        BlockMesh = {"DataModelMesh"},
        CylinderMesh = {"DataModelMesh"},
    }
    
    local parents = classHierarchy[className]
    if parents then
        for _, parentClass in ipairs(parents) do
            local parentProps = SerializerAPI.PropertyDatabase[parentClass]
            if parentProps then
                for _, prop in ipairs(parentProps) do
                    if not added[prop] then
                        table.insert(properties, prop)
                        added[prop] = true
                    end
                end
            end
        end
    end
    
    return properties
end

-- Serialize instance properties
function SerializerAPI.SerializeInstance(instance, referenceMap, options)
    options = options or {}
    
    local properties = {}
    local attributes = {}
    local className = instance.ClassName
    
    -- Get properties to serialize
    local propsToSerialize = options.Properties or SerializerAPI.GetPropertiesForClass(className)
    
    -- Serialize each property
    for _, propName in ipairs(propsToSerialize) do
        -- Skip ignored properties
        local isIgnored = false
        for _, ignored in ipairs(SerializerAPI.IgnoredProperties) do
            if propName == ignored then
                isIgnored = true
                break
            end
        end
        
        if not isIgnored then
            local success, value = pcall(function()
                return instance[propName]
            end)
            
            if success and value ~= nil then
                local serialized = SerializerAPI.Serialize(value, referenceMap)
                if serialized then
                    properties[propName] = serialized
                end
            end
        end
    end
    
    -- Try hidden properties if supported
    if options.IncludeHidden and gethiddenproperty then
        local hiddenProps = SerializerAPI.HiddenProperties[className]
        if hiddenProps then
            for _, propName in ipairs(hiddenProps) do
                local success, value = pcall(function()
                    return gethiddenproperty(instance, propName)
                end)
                
                if success and value ~= nil then
                    local serialized = SerializerAPI.Serialize(value, referenceMap)
                    if serialized then
                        serialized.IsHidden = true
                        properties[propName] = serialized
                    end
                end
            end
        end
    end
    
    -- Serialize attributes
    local success, attrs = pcall(function()
        return instance:GetAttributes()
    end)
    
    if success and attrs then
        for attrName, attrValue in pairs(attrs) do
            local serialized = SerializerAPI.Serialize(attrValue, referenceMap)
            if serialized then
                attributes[attrName] = serialized
            end
        end
    end
    
    return {
        Name = instance.Name,
        ClassName = className,
        Properties = properties,
        Attributes = attributes,
        FullName = pcall(function() return instance:GetFullName() end) and instance:GetFullName() or "???",
    }
end

-- Generate reference ID for instance
function SerializerAPI.GenerateReferenceID(instance, referenceMap)
    if not referenceMap then
        referenceMap = ReferenceMap
    end
    
    if referenceMap[instance] then
        return referenceMap[instance]
    end
    
    ReferenceCounter = ReferenceCounter + 1
    local refID = "RBX" .. tostring(ReferenceCounter)
    referenceMap[instance] = refID
    
    return refID
end

-- Reset reference map
function SerializerAPI.ResetReferences()
    ReferenceMap = {}
    ReferenceCounter = 0
end

-- Get reference map
function SerializerAPI.GetReferenceMap()
    return ReferenceMap
end

-- List all registered serializers
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

-- Convert serialized data to JSON
function SerializerAPI.ToJSON(data)
    -- Remove Raw values (can't be JSON encoded)
    local function cleanForJSON(tbl)
        if type(tbl) ~= "table" then
            return tbl
        end
        
        local clean = {}
        for k, v in pairs(tbl) do
            if k ~= "Raw" then
                clean[k] = cleanForJSON(v)
            end
        end
        return clean
    end
    
    local cleaned = cleanForJSON(data)
    
    local success, json = pcall(function()
        return HttpService:JSONEncode(cleaned)
    end)
    
    return success and json or nil
end

-- Convert serialized data to Lua code
function SerializerAPI.ToLuaCode(data)
    local function toLua(value, indent)
        indent = indent or 0
        local indentStr = string.rep("    ", indent)
        
        if type(value) ~= "table" then
            if type(value) == "string" then
                return string.format('"%s"', value:gsub('"', '\\"'))
            else
                return tostring(value)
            end
        end
        
        local lines = {"{"}
        for k, v in pairs(value) do
            if k ~= "Raw" then
                local keyStr
                if type(k) == "string" then
                    if k:match("^[%a_][%w_]*$") then
                        keyStr = k
                    else
                        keyStr = string.format('["%s"]', k)
                    end
                else
                    keyStr = string.format("[%s]", tostring(k))
                end
                
                table.insert(lines, string.format(
                    "%s    %s = %s,",
                    indentStr,
                    keyStr,
                    toLua(v, indent + 1)
                ))
            end
        end
        table.insert(lines, indentStr .. "}")
        
        return table.concat(lines, "\n")
    end
    
    return toLua(data)
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// RETURN MODULE
--// ═══════════════════════════════════════════════════════════════════════════════════

return SerializerAPI
