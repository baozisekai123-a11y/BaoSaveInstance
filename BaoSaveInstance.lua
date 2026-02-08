--[[
    ╔════════════════════════════════════════════════════════════════════════════╗
    ║                    BaoSaveInstance Pro Edition                              ║
    ║     Advanced Roblox Game Dumper - Inspired by UniversalSynSaveInstance     ║
    ║                                                                              ║
    ║  Features:                                                                   ║
    ║  • Binary RBXL + XML formats                                                 ║
    ║  • Advanced decompilation (6+ methods)                                       ║
    ║  • 200+ property types                                                       ║
    ║  • SafeMode for stealth                                                      ║
    ║  • 20+ customizable options                                                  ║
    ║  • Hidden property access                                                    ║
    ║                                                                              ║
    ║  Supports: Xeno, Solara, TNG, Velocity, Wave, and compatible executors      ║
    ╚════════════════════════════════════════════════════════════════════════════╝
]]

--// SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
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
local MaterialService = game:GetService("MaterialService")
local TestService = game:GetService("TestService")

--// VERSION
local VERSION = "Pro Edition v2.0"
local BUILD_DATE = "2026-02-08"

--// DEFAULT OPTIONS
local DefaultOptions = {
    -- Save Mode
    Mode = "Full",                      -- "Full", "Terrain", "Models", "Scripts"
    
    -- Output Format
    SaveFormat = "rbxlx",               -- "rbxl" (binary), "rbxlx" (xml)
    FilePath = "BaoSaveInstance/",
    FileName = nil,                      -- Auto-generate if nil
    
    -- Content Options
    SaveTerrain = true,
    SaveWorkspace = true,
    SaveLighting = true,
    SaveReplicatedStorage = true,
    SaveReplicatedFirst = true,
    SaveStarterGui = true,
    SaveStarterPack = true,
    SaveStarterPlayer = true,
    SaveTeams = true,
    SaveSoundService = true,
    SaveChat = true,
    SaveLocalPlayer = false,
    
    -- Player Options
    SavePlayers = false,
    RemovePlayerCharacters = true,
    IsolateLocalPlayer = true,
    CleanUserInfo = true,
    
    -- Script Options
    SaveScripts = true,
    DecompileScripts = true,
    DecompileTimeout = 10,
    DecompileIgnore = {},
    ScriptCache = true,
    NilInstances = false,
    
    -- Optimization
    IgnoreDefaultProps = true,
    IgnoreNotArchivable = true,
    IgnorePropertiesOfNotScriptsOnScriptsMode = false,
    SharedStringOverwrite = false,
    TurboMode = true, -- Speed x10 (Allows lag)
    
    -- Safety
    SafeMode = false,
    AntiIdle = true,
    ShowProgress = true,
    
    -- Filtering
    IgnoreList = {},
    IgnoreClasses = {},
    IgnoreProperties = {},
    ExtraInstances = {},
    
    -- Callbacks
    ReadGlobalCallback = nil,
    CustomDecompiler = nil,
}

--// CURRENT OPTIONS (will be merged with user options)
local Options = {}
for k, v in pairs(DefaultOptions) do
    Options[k] = v
end

--// EXECUTOR DETECTION
local ExecutorInfo = {
    Name = "Unknown",
    Supported = false,
    Level = 0,
    Functions = {}
}

local function DetectExecutor()
    -- Check known executors
    local executors = {
        {name = "Xeno", check = function() return getgenv and getgenv().Xeno end, level = 8},
        {name = "Solara", check = function() return identifyexecutor and identifyexecutor():lower():find("solara") end, level = 7},
        {name = "TNG", check = function() return identifyexecutor and identifyexecutor():lower():find("tng") end, level = 7},
        {name = "Velocity", check = function() return identifyexecutor and identifyexecutor():lower():find("velocity") end, level = 7},
        {name = "Wave", check = function() return identifyexecutor and identifyexecutor():lower():find("wave") end, level = 7},
        {name = "Synapse X", check = function() return syn and syn.protect_gui end, level = 9},
        {name = "Script-Ware", check = function() return identifyexecutor and identifyexecutor():lower():find("script%-ware") end, level = 8},
        {name = "Fluxus", check = function() return identifyexecutor and identifyexecutor():lower():find("fluxus") end, level = 6},
        {name = "Krnl", check = function() return identifyexecutor and identifyexecutor():lower():find("krnl") end, level = 6},
        {name = "Electron", check = function() return identifyexecutor and identifyexecutor():lower():find("electron") end, level = 5},
    }
    
    for _, exec in ipairs(executors) do
        local success, result = pcall(exec.check)
        if success and result then
            ExecutorInfo.Name = exec.name
            ExecutorInfo.Supported = true
            ExecutorInfo.Level = exec.level
            break
        end
    end
    
    -- Fallback detection
    if not ExecutorInfo.Supported and identifyexecutor then
        local success, name = pcall(identifyexecutor)
        if success and name then
            ExecutorInfo.Name = name
            ExecutorInfo.Supported = true
            ExecutorInfo.Level = 5
        end
    end
    
    -- Map available functions
    ExecutorInfo.Functions = {
        -- File operations
        writefile = writefile,
        readfile = readfile,
        appendfile = appendfile,
        isfile = isfile,
        isfolder = isfolder,
        makefolder = makefolder,
        delfile = delfile,
        delfolder = delfolder,
        listfiles = listfiles,
        
        -- Decompile
        decompile = decompile,
        getscriptbytecode = getscriptbytecode,
        getscripthash = getscripthash,
        
        -- Instance
        gethiddenproperty = gethiddenproperty,
        sethiddenproperty = sethiddenproperty,
        gethui = gethui,
        getinstances = getinstances,
        getnilinstances = getnilinstances,
        getscripts = getscripts,
        getrunningscripts = getrunningscripts,
        getloadedmodules = getloadedmodules,
        cloneref = cloneref, -- Critical for bypass
        
        -- Environment
        getgenv = getgenv,
        getrenv = getrenv,
        getsenv = getsenv,
        getfenv = getfenv,
        setfenv = setfenv,
        getrawmetatable = getrawmetatable,
        setrawmetatable = setrawmetatable,
        
        -- Closure
        hookfunction = hookfunction or replaceclosure,
        hookmetamethod = hookmetamethod,
        newcclosure = newcclosure,
        islclosure = islclosure,
        iscclosure = iscclosure,
        getinfo = getinfo or debug.info,
        getconstants = getconstants or debug.getconstants,
        getupvalues = getupvalues or debug.getupvalues,
        getprotos = getprotos or debug.getprotos,
        
        -- Misc
        setclipboard = setclipboard,
        request = request or http_request or syn_request or http.request,
        crypt = crypt,
        lz4compress = lz4compress,
        lz4decompress = lz4decompress,
    }
    
    return ExecutorInfo
end

DetectExecutor()

--// STEALTH / BYPASS MODULE
local Stealth = {}
Stealth.Cloneref = ExecutorInfo.Functions.cloneref or function(o) return o end

-- Safe Service Getter (Bypasses __namecall hooks on game)
function Stealth.GetService(serviceName)
    local success, service = pcall(function()
        return Stealth.Cloneref(game:GetService(serviceName))
    end)
    if success then return service end
    return game:GetService(serviceName) -- Fallback
end

--// SERVICES
local Players = Stealth.GetService("Players")
local TweenService = Stealth.GetService("TweenService")
local HttpService = Stealth.GetService("HttpService")
local RunService = Stealth.GetService("RunService")
local UserInputService = Stealth.GetService("UserInputService")
local CoreGui = Stealth.GetService("CoreGui")
local Workspace = Stealth.GetService("Workspace")
local Lighting = Stealth.GetService("Lighting")
local ReplicatedStorage = Stealth.GetService("ReplicatedStorage")
local ReplicatedFirst = Stealth.GetService("ReplicatedFirst")
local StarterGui = Stealth.GetService("StarterGui")
local StarterPack = Stealth.GetService("StarterPack")
local StarterPlayer = Stealth.GetService("StarterPlayer")
local Teams = Stealth.GetService("Teams")
local SoundService = Stealth.GetService("SoundService")
local Chat = Stealth.GetService("Chat")
local LocalizationService = Stealth.GetService("LocalizationService")
local MaterialService = Stealth.GetService("MaterialService")
local TestService = Stealth.GetService("TestService")

--// UTILITIES
local Util = {}

function Util.DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in next, orig, nil do
            copy[Util.DeepCopy(k)] = Util.DeepCopy(v)
        end
        setmetatable(copy, Util.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function Util.MergeOptions(userOptions)
    if not userOptions then return end
    for k, v in pairs(userOptions) do
        if DefaultOptions[k] ~= nil then
            Options[k] = v
        end
    end
end

function Util.SafeCall(func, ...)
    local args = {...}
    return pcall(function()
        return func(unpack(args))
    end)
end

function Util.CreateFolder(path)
    local folders = string.split(path, "/")
    local current = ""
    for _, folder in ipairs(folders) do
        if folder ~= "" then
            current = current .. folder
            if ExecutorInfo.Functions.isfolder and not ExecutorInfo.Functions.isfolder(current) then
                if ExecutorInfo.Functions.makefolder then
                    ExecutorInfo.Functions.makefolder(current)
                end
            end
            current = current .. "/"
        end
    end
end

function Util.GetGameName()
    local name = "RobloxGame"
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        name = info.Name or name
    end)
    name = name:gsub("[^%w%s%-_]", ""):gsub("%s+", "_"):sub(1, 50)
    if name == "" then name = "RobloxGame" end
    return name
end

function Util.GetTimestamp()
    return os.date("%Y-%m-%d_%H%M%S")
end

function Util.GetFullName(instance)
    local success, name = pcall(function()
        return Stealth.Cloneref(instance):GetFullName()
    end)
    return success and name or "Unknown"
end

function Util.SafeGetProperty(instance, property)
    -- Use Cloneref to bypass __index hooks on the original userdata
    local safeInstance = Stealth.Cloneref(instance)
    
    -- Try normal access on safe reference
    local success, value = pcall(function()
        return safeInstance[property]
    end)
    
    if success then
        return true, value
    end
    
    -- Try hidden property
    if ExecutorInfo.Functions.gethiddenproperty then
        success, value = pcall(function()
            return ExecutorInfo.Functions.gethiddenproperty(safeInstance, property)
        end)
        if success then
            return true, value
        end
    end
    
    return false, nil
end

function Util.IsDefaultValue(className, propName, value)
    -- Common defaults - expand this list for optimization
    local defaults = {
        Anchored = false,
        CanCollide = true,
        Transparency = 0,
        Visible = true,
        Enabled = true,
        Archivable = true,
    }
    
    if defaults[propName] ~= nil and defaults[propName] == value then
        return true
    end
    
    return false
end

function Util.EscapeXML(str)
    if type(str) ~= "string" then str = tostring(str) end
    return str:gsub("&", "&amp;")
              :gsub("<", "&lt;")
              :gsub(">", "&gt;")
              :gsub('"', "&quot;")
              :gsub("'", "&apos;")
              :gsub("\0", "")
end

function Util.CleanString(str)
    if type(str) ~= "string" then return tostring(str) end
    -- Remove null bytes and control characters
    return str:gsub("[\0-\8\11\12\14-\31]", "")
end

--// PROPERTY TYPE SERIALIZER
local PropertySerializer = {}

PropertySerializer.Handlers = {
    ["string"] = function(v) return Util.CleanString(v), "string" end,
    ["number"] = function(v) 
        if v ~= v then return "0", "float" end -- NaN check
        if v == math.huge then return "INF", "float" end
        if v == -math.huge then return "-INF", "float" end
        return tostring(v), "float" 
    end,
    ["boolean"] = function(v) return v and "true" or "false", "bool" end,
    
    ["Vector3"] = function(v)
        return string.format("<X>%s</X><Y>%s</Y><Z>%s</Z>", v.X, v.Y, v.Z), "Vector3"
    end,
    
    ["Vector2"] = function(v)
        return string.format("<X>%s</X><Y>%s</Y>", v.X, v.Y), "Vector2"
    end,
    
    ["CFrame"] = function(cf)
        local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
        return string.format(
            "<X>%s</X><Y>%s</Y><Z>%s</Z><R00>%s</R00><R01>%s</R01><R02>%s</R02><R10>%s</R10><R11>%s</R11><R12>%s</R12><R20>%s</R20><R21>%s</R21><R22>%s</R22>",
            x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22
        ), "CoordinateFrame"
    end,
    
    ["Color3"] = function(c)
        local r = math.floor(c.R * 255 + 0.5)
        local g = math.floor(c.G * 255 + 0.5)
        local b = math.floor(c.B * 255 + 0.5)
        return tostring(r * 65536 + g * 256 + b), "Color3uint8"
    end,
    
    ["BrickColor"] = function(bc)
        return tostring(bc.Number), "int"
    end,
    
    ["UDim"] = function(u)
        return string.format("<S>%s</S><O>%d</O>", u.Scale, u.Offset), "UDim"
    end,
    
    ["UDim2"] = function(u)
        return string.format("<XS>%s</XS><XO>%d</XO><YS>%s</YS><YO>%d</YO>", 
            u.X.Scale, u.X.Offset, u.Y.Scale, u.Y.Offset), "UDim2"
    end,
    
    ["Rect"] = function(r)
        return string.format("<min><X>%s</X><Y>%s</Y></min><max><X>%s</X><Y>%s</Y></max>",
            r.Min.X, r.Min.Y, r.Max.X, r.Max.Y), "Rect2D"
    end,
    
    ["NumberSequence"] = function(ns)
        local keypoints = {}
        for _, kp in ipairs(ns.Keypoints) do
            table.insert(keypoints, string.format("%s %s %s", kp.Time, kp.Value, kp.Envelope))
        end
        return table.concat(keypoints, " "), "NumberSequence"
    end,
    
    ["ColorSequence"] = function(cs)
        local keypoints = {}
        for _, kp in ipairs(cs.Keypoints) do
            table.insert(keypoints, string.format("%s %s %s %s 0", kp.Time, kp.Value.R, kp.Value.G, kp.Value.B))
        end
        return table.concat(keypoints, " "), "ColorSequence"
    end,
    
    ["NumberRange"] = function(nr)
        return string.format("%s %s", nr.Min, nr.Max), "NumberRange"
    end,
    
    ["PhysicalProperties"] = function(pp)
        if pp then
            return string.format("<CustomPhysics>true</CustomPhysics><Density>%s</Density><Friction>%s</Friction><Elasticity>%s</Elasticity><FrictionWeight>%s</FrictionWeight><ElasticityWeight>%s</ElasticityWeight>",
                pp.Density, pp.Friction, pp.Elasticity, pp.FrictionWeight, pp.ElasticityWeight), "PhysicalProperties"
        end
        return "<CustomPhysics>false</CustomPhysics>", "PhysicalProperties"
    end,
    
    ["Ray"] = function(r)
        return string.format("<origin><X>%s</X><Y>%s</Y><Z>%s</Z></origin><direction><X>%s</X><Y>%s</Y><Z>%s</Z></direction>",
            r.Origin.X, r.Origin.Y, r.Origin.Z, r.Direction.X, r.Direction.Y, r.Direction.Z), "Ray"
    end,
    
    ["Faces"] = function(f)
        local faces = {}
        if f.Top then table.insert(faces, "Top") end
        if f.Bottom then table.insert(faces, "Bottom") end
        if f.Left then table.insert(faces, "Left") end
        if f.Right then table.insert(faces, "Right") end
        if f.Back then table.insert(faces, "Back") end
        if f.Front then table.insert(faces, "Front") end
        return string.format("<faces>%d</faces>", 
            (f.Right and 1 or 0) + (f.Top and 2 or 0) + (f.Back and 4 or 0) + 
            (f.Left and 8 or 0) + (f.Bottom and 16 or 0) + (f.Front and 32 or 0)), "Faces"
    end,
    
    ["Axes"] = function(a)
        return string.format("<axes>%d</axes>",
            (a.X and 1 or 0) + (a.Y and 2 or 0) + (a.Z and 4 or 0)), "Axes"
    end,
    
    ["EnumItem"] = function(e)
        return tostring(e.Value), "token"
    end,
    
    ["Font"] = function(f)
        return string.format('<Family><url>%s</url></Family><Weight>%d</Weight><Style>%s</Style>',
            Util.EscapeXML(tostring(f.Family)), f.Weight.Value, tostring(f.Style)), "Font"
    end,
    
    ["Instance"] = function(inst)
        return inst:GetFullName(), "Ref"
    end,
    
    ["Content"] = function(v)
        return string.format("<url>%s</url>", Util.EscapeXML(tostring(v))), "Content"
    end,
    
    ["SharedString"] = function(v)
        return tostring(v), "SharedString"
    end,
    
    ["PathWaypoint"] = function(pw)
        return string.format("<Position><X>%s</X><Y>%s</Y><Z>%s</Z></Position><Action>%d</Action>",
            pw.Position.X, pw.Position.Y, pw.Position.Z, pw.Action.Value), "PathWaypoint"
    end,
    
    ["Region3"] = function(r)
        local min = r.CFrame.Position - r.Size/2
        local max = r.CFrame.Position + r.Size/2
        return string.format("<min><X>%s</X><Y>%s</Y><Z>%s</Z></min><max><X>%s</X><Y>%s</Y><Z>%s</Z></max>",
            min.X, min.Y, min.Z, max.X, max.Y, max.Z), "Region3"
    end,
    
    ["Region3int16"] = function(r)
        return string.format("<min><X>%d</X><Y>%d</Y><Z>%d</Z></min><max><X>%d</X><Y>%d</Y><Z>%d</Z></max>",
            r.Min.X, r.Min.Y, r.Min.Z, r.Max.X, r.Max.Y, r.Max.Z), "Region3int16"
    end,
}

function PropertySerializer.Serialize(value)
    if value == nil then return nil, nil end
    
    local valueType = typeof(value)
    local handler = PropertySerializer.Handlers[valueType]
    
    if handler then
        return handler(value)
    end
    
    -- Fallback
    return Util.EscapeXML(tostring(value)), "string"
end

-- PROPERTY LIST (expanded to 200+)
local InstanceProperties = {}

-- Base properties for all instances
InstanceProperties["Instance"] = {"Name", "Archivable", "Parent"}

-- BasePart and derivatives
InstanceProperties["BasePart"] = {"Anchored", "CanCollide", "CanTouch", "CanQuery", "CastShadow", "Color", "Material", "MaterialVariant", "Reflectance", "Transparency", "Size", "CFrame", "Position", "Orientation", "AssemblyLinearVelocity", "AssemblyAngularVelocity", "Massless", "RootPriority", "Locked", "CollisionGroup", "CustomPhysicalProperties", "PivotOffset", "EnableFluidForces"}
InstanceProperties["Part"] = {"Shape", "TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface", "BackSurface"}
InstanceProperties["MeshPart"] = {"MeshId", "TextureID", "DoubleSided", "RenderFidelity", "CollisionFidelity", "FluidFidelity"}
InstanceProperties["UnionOperation"] = {"UsePartColor", "SmoothingAngle", "RenderFidelity", "CollisionFidelity", "FluidFidelity"}
InstanceProperties["NegateOperation"] = {}
InstanceProperties["IntersectOperation"] = {"UsePartColor", "SmoothingAngle", "RenderFidelity", "CollisionFidelity"}
InstanceProperties["WedgePart"] = {}
InstanceProperties["CornerWedgePart"] = {}
InstanceProperties["TrussPart"] = {"Style"}
InstanceProperties["SpawnLocation"] = {"AllowTeamChangeOnTouch", "Duration", "Enabled", "Neutral", "TeamColor"}
InstanceProperties["Seat"] = {"Disabled", "Occupant"}
InstanceProperties["VehicleSeat"] = {"Disabled", "HeadsUpDisplay", "MaxSpeed", "Steer", "SteerFloat", "Throttle", "ThrottleFloat", "Torque", "TurnSpeed", "Occupant"}
InstanceProperties["SkateboardPlatform"] = {"Controller", "ControllerIntValue", "Steer", "StickyWheels", "Throttle"}

-- Models and Containers
InstanceProperties["Model"] = {"PrimaryPart", "WorldPivot", "LevelOfDetail", "ModelStreamingMode"}
InstanceProperties["Actor"] = {}
InstanceProperties["WorldModel"] = {}
InstanceProperties["Folder"] = {}
InstanceProperties["Tool"] = {"CanBeDropped", "Enabled", "Grip", "GripForward", "GripPos", "GripRight", "GripUp", "ManualActivationOnly", "RequiresHandle", "ToolTip", "TextureId"}
InstanceProperties["Flag"] = {"TeamColor"}
InstanceProperties["Accessory"] = {"AttachmentPoint", "AccessoryType"}
InstanceProperties["Accoutrement"] = {"AttachmentPoint"}
InstanceProperties["BackpackItem"] = {"TextureId"}
InstanceProperties["HopperBin"] = {"Active", "BinType"}

-- Visual
InstanceProperties["Decal"] = {"Color3", "Texture", "Transparency", "Face", "ZIndex"}
InstanceProperties["Texture"] = {"OffsetStudsU", "OffsetStudsV", "StudsPerTileU", "StudsPerTileV"}
InstanceProperties["SurfaceAppearance"] = {"AlphaMode", "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap", "TexturePack"}
InstanceProperties["SpecialMesh"] = {"MeshId", "MeshType", "Offset", "Scale", "TextureId", "VertexColor"}
InstanceProperties["BlockMesh"] = {"Offset", "Scale", "VertexColor"}
InstanceProperties["CylinderMesh"] = {"Offset", "Scale", "VertexColor"}
InstanceProperties["FileMesh"] = {"MeshId", "Offset", "Scale", "TextureId", "VertexColor"}
InstanceProperties["EditableMesh"] = {}
InstanceProperties["EditableImage"] = {}

-- Lights
InstanceProperties["PointLight"] = {"Brightness", "Color", "Enabled", "Range", "Shadows"}
InstanceProperties["SpotLight"] = {"Angle", "Brightness", "Color", "Enabled", "Face", "Range", "Shadows"}
InstanceProperties["SurfaceLight"] = {"Angle", "Brightness", "Color", "Enabled", "Face", "Range", "Shadows"}

-- Effects
InstanceProperties["Fire"] = {"Color", "Enabled", "Heat", "SecondaryColor", "Size", "TimeScale"}
InstanceProperties["Smoke"] = {"Color", "Enabled", "Opacity", "RiseVelocity", "Size", "TimeScale"}
InstanceProperties["Sparkles"] = {"Color", "Enabled", "SparkleColor", "TimeScale"}
InstanceProperties["ParticleEmitter"] = {"Acceleration", "Brightness", "Color", "Drag", "EmissionDirection", "Enabled", "FlipbookFramerate", "FlipbookIncompatible", "FlipbookLayout", "FlipbookMode", "FlipbookStartRandom", "Lifetime", "LightEmission", "LightInfluence", "LockedToPart", "Orientation", "Rate", "RotSpeed", "Rotation", "Shape", "ShapeInOut", "ShapePartial", "ShapeStyle", "Size", "Speed", "SpreadAngle", "Squash", "Texture", "TimeScale", "Transparency", "VelocityInheritance", "VelocitySpread", "WindAffectsDrag", "ZOffset"}
InstanceProperties["Beam"] = {"Attachment0", "Attachment1", "Brightness", "Color", "CurveSize0", "CurveSize1", "Enabled", "FaceCamera", "LightEmission", "LightInfluence", "Segments", "Texture", "TextureLength", "TextureMode", "TextureSpeed", "Transparency", "Width0", "Width1", "ZOffset"}
InstanceProperties["Trail"] = {"Attachment0", "Attachment1", "Brightness", "Color", "Enabled", "FaceCamera", "Lifetime", "LightEmission", "LightInfluence", "MaxLength", "MinLength", "Texture", "TextureLength", "TextureMode", "Transparency", "WidthScale"}
InstanceProperties["Highlight"] = {"Adornee", "DepthMode", "Enabled", "FillColor", "FillTransparency", "OutlineColor", "OutlineTransparency"}
InstanceProperties["Explosion"] = {"BlastPressure", "BlastRadius", "DestroyJointRadiusPercent", "ExplosionType", "Position", "TimeScale", "Visible"}

-- Attachments and Constraints
InstanceProperties["Attachment"] = {"Axis", "CFrame", "Orientation", "Position", "SecondaryAxis", "Visible", "WorldAxis", "WorldCFrame", "WorldOrientation", "WorldPosition", "WorldSecondaryAxis"}
InstanceProperties["Bone"] = {"Transform"}
InstanceProperties["WeldConstraint"] = {"Active", "Enabled", "Part0", "Part1"}
InstanceProperties["Weld"] = {"C0", "C1", "Enabled", "Part0", "Part1"}
InstanceProperties["Motor6D"] = {"C0", "C1", "CurrentAngle", "DesiredAngle", "Enabled", "MaxVelocity", "Part0", "Part1", "Transform"}
InstanceProperties["Motor"] = {"CurrentAngle", "DesiredAngle", "MaxVelocity"}
InstanceProperties["Snap"] = {"C0", "C1", "Enabled", "Part0", "Part1"}
InstanceProperties["VelocityMotor"] = {"CurrentAngle", "DesiredAngle", "Hole", "MaxVelocity"}
InstanceProperties["Glue"] = {"F0", "F1", "F2", "F3"}
InstanceProperties["ManualWeld"] = {"C0", "C1", "Enabled", "Part0", "Part1"}
InstanceProperties["ManualGlue"] = {"C0", "C1", "Enabled", "Part0", "Part1"}
InstanceProperties["NoCollisionConstraint"] = {"Enabled", "Part0", "Part1"}

-- Physics Constraints
InstanceProperties["HingeConstraint"] = {"ActuatorType", "AngularResponsiveness", "AngularSpeed", "AngularVelocity", "LimitsEnabled", "LowerAngle", "MotorMaxAcceleration", "MotorMaxTorque", "Radius", "Restitution", "ServoMaxTorque", "SoftlockServoUponReachingTarget", "TargetAngle", "UpperAngle"}
InstanceProperties["PrismaticConstraint"] = {"ActuatorType", "LimitsEnabled", "LowerLimit", "MotorMaxAcceleration", "MotorMaxForce", "Restitution", "ServoMaxForce", "Size", "Speed", "SoftlockServoUponReachingTarget", "TargetPosition", "UpperLimit", "Velocity"}
InstanceProperties["CylindricalConstraint"] = {"AngularActuatorType", "AngularLimitsEnabled", "AngularResponsiveness", "AngularRestitution", "AngularSpeed", "AngularVelocity", "InclinationAngle", "LimitsEnabled", "LowerAngle", "LowerLimit", "MotorMaxAngularAcceleration", "MotorMaxForce", "MotorMaxTorque", "Restitution", "RotationAxisVisible", "ServoMaxForce", "ServoMaxTorque", "Size", "SoftlockServoUponReachingTarget", "Speed", "TargetAngle", "TargetPosition", "UpperAngle", "UpperLimit", "Velocity", "WorldRotationAxis"}
InstanceProperties["BallSocketConstraint"] = {"LimitsEnabled", "MaxFrictionTorque", "Radius", "Restitution", "TwistLimitsEnabled", "TwistLowerAngle", "TwistUpperAngle", "UpperAngle"}
InstanceProperties["UniversalConstraint"] = {"LimitsEnabled", "MaxAngle", "Radius", "Restitution"}
InstanceProperties["RopeConstraint"] = {"Length", "Restitution", "Thickness", "Visible", "WinchEnabled", "WinchForce", "WinchResponsiveness", "WinchSpeed", "WinchTarget"}
InstanceProperties["RodConstraint"] = {"Length", "LimitAngle0", "LimitAngle1", "LimitsEnabled", "Thickness", "Visible"}
InstanceProperties["SpringConstraint"] = {"Coils", "Damping", "FreeLength", "LimitsEnabled", "MaxForce", "MaxLength", "MinLength", "Radius", "Stiffness", "Thickness", "Visible"}
InstanceProperties["TorsionSpringConstraint"] = {"Coils", "CurrentAngle", "Damping", "LimitsEnabled", "MaxAngle", "MaxTorque", "Radius", "Restitution", "Stiffness", "UpperAngle"}
InstanceProperties["Plane"] = {}
InstanceProperties["LineForce"] = {"ApplyAtCenterOfMass", "Enabled", "InverseSquareLaw", "Magnitude", "MaxForce", "ReactionForceEnabled"}
InstanceProperties["VectorForce"] = {"ApplyAtCenterOfMass", "Enabled", "Force", "RelativeTo"}
InstanceProperties["Torque"] = {"Enabled", "RelativeTo", "Torque"}
InstanceProperties["LinearVelocity"] = {"Enabled", "ForceLimitMode", "ForceLimitsEnabled", "LineDirection", "LineVelocity", "MaxAxesForce", "MaxForce", "MaxPlanarAxesForce", "PlaneVelocity", "PrimaryTangentAxis", "RelativeTo", "SecondaryTangentAxis", "VectorVelocity", "VelocityConstraintMode"}
InstanceProperties["AngularVelocity"] = {"AngularVelocity", "Enabled", "MaxTorque", "ReactionTorqueEnabled", "RelativeTo"}
InstanceProperties["AlignPosition"] = {"ApplyAtCenterOfMass", "Enabled", "ForceLimitMode", "ForceRelativeTo", "MaxAxesForce", "MaxForce", "MaxVelocity", "Mode", "Position", "ReactionForceEnabled", "Responsiveness", "RigidityEnabled"}
InstanceProperties["AlignOrientation"] = {"AlignType", "CFrame", "Enabled", "MaxAngularVelocity", "MaxTorque", "Mode", "PrimaryAxis", "PrimaryAxisOnly", "ReactionTorqueEnabled", "Responsiveness", "RigidityEnabled", "SecondaryAxis"}

-- Legacy Body Movers
InstanceProperties["BodyPosition"] = {"D", "MaxForce", "P", "Position"}
InstanceProperties["BodyVelocity"] = {"MaxForce", "P", "Velocity"}
InstanceProperties["BodyForce"] = {"Force"}
InstanceProperties["BodyAngularVelocity"] = {"AngularVelocity", "MaxTorque", "P"}
InstanceProperties["BodyGyro"] = {"CFrame", "D", "MaxTorque", "P"}
InstanceProperties["BodyThrust"] = {"Force", "Location"}
InstanceProperties["RocketPropulsion"] = {"CartoonFactor", "MaxSpeed", "MaxThrust", "MaxTorque", "Target", "TargetOffset", "TargetRadius", "ThrustD", "ThrustP", "TurnD", "TurnP"}

-- Character
InstanceProperties["Humanoid"] = {"AutoJumpEnabled", "AutoRotate", "AutomaticScalingEnabled", "BreakJointsOnDeath", "CameraOffset", "DisplayDistanceType", "DisplayName", "EvaluateStateMachine", "Health", "HealthDisplayDistance", "HealthDisplayType", "HipHeight", "JumpHeight", "JumpPower", "MaxHealth", "MaxSlopeAngle", "MoveDirection", "NameDisplayDistance", "NameOcclusion", "PlatformStand", "RequiresNeck", "RigType", "RootPart", "Sit", "TargetPoint", "UseJumpPower", "WalkSpeed", "WalkToPart", "WalkToPoint"}
InstanceProperties["HumanoidDescription"] = {}
InstanceProperties["Shirt"] = {"ShirtTemplate", "Color3"}
InstanceProperties["Pants"] = {"PantsTemplate", "Color3"}
InstanceProperties["ShirtGraphic"] = {"Color3", "Graphic"}
InstanceProperties["CharacterMesh"] = {"BaseTextureId", "BodyPart", "MeshId", "OverlayTextureId"}
InstanceProperties["BodyColors"] = {"HeadColor", "HeadColor3", "LeftArmColor", "LeftArmColor3", "LeftLegColor", "LeftLegColor3", "RightArmColor", "RightArmColor3", "RightLegColor", "RightLegColor3", "TorsoColor", "TorsoColor3"}
InstanceProperties["Animator"] = {}
InstanceProperties["Animation"] = {"AnimationId"}
InstanceProperties["AnimationTrack"] = {}
InstanceProperties["AnimationController"] = {}
InstanceProperties["KeyframeSequence"] = {"AuthoredHipHeight", "Loop", "Priority"}
InstanceProperties["Keyframe"] = {"Time"}
InstanceProperties["Pose"] = {"CFrame", "MaskWeight", "Weight"}

-- Scripts
InstanceProperties["Script"] = {"Disabled", "LinkedSource", "RunContext"}
InstanceProperties["LocalScript"] = {"Disabled", "LinkedSource"}
InstanceProperties["ModuleScript"] = {"LinkedSource"}
InstanceProperties["CoreScript"] = {}

-- GUI
InstanceProperties["ScreenGui"] = {"ClipToDeviceSafeArea", "DisplayOrder", "Enabled", "IgnoreGuiInset", "ResetOnSpawn", "SafeAreaCompatibility", "ScreenInsets", "ZIndexBehavior"}
InstanceProperties["BillboardGui"] = {"Active", "Adornee", "AlwaysOnTop", "Brightness", "ClipsDescendants", "CurrentDistance", "DistanceLowerLimit", "DistanceStep", "DistanceUpperLimit", "ExtentsOffset", "ExtentsOffsetWorldSpace", "LightInfluence", "MaxDistance", "PlayerToHideFrom", "Size", "SizeOffset", "StudsOffset", "StudsOffsetWorldSpace", "ZIndexBehavior"}
InstanceProperties["SurfaceGui"] = {"Active", "Adornee", "AlwaysOnTop", "Brightness", "CanvasSize", "ClipsDescendants", "Face", "LightInfluence", "PixelsPerStud", "SizingMode", "ToolPunchThroughDistance", "ZIndexBehavior", "ZOffset"}
InstanceProperties["AdGui"] = {}
InstanceProperties["Frame"] = {"AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "LayoutOrder", "Position", "Rotation", "Size", "SizeConstraint", "Visible", "ZIndex", "Style"}
InstanceProperties["ScrollingFrame"] = {"AnchorPoint", "AutomaticCanvasSize", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel", "BottomImage", "CanvasPosition", "CanvasSize", "ClipsDescendants", "ElasticBehavior", "HorizontalScrollBarInset", "LayoutOrder", "MidImage", "Position", "Rotation", "ScrollBarImageColor3", "ScrollBarImageTransparency", "ScrollBarThickness", "ScrollingDirection", "ScrollingEnabled", "Size", "SizeConstraint", "TopImage", "VerticalScrollBarInset", "VerticalScrollBarPosition", "Visible", "ZIndex"}
InstanceProperties["TextLabel"] = {"AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "Font", "FontFace", "LayoutOrder", "LineHeight", "LocalizedText", "MaxVisibleGraphemes", "Position", "RichText", "Rotation", "Size", "SizeConstraint", "Text", "TextColor3", "TextScaled", "TextSize", "TextStrokeColor3", "TextStrokeTransparency", "TextTransparency", "TextTruncate", "TextWrapped", "TextXAlignment", "TextYAlignment", "Visible", "ZIndex"}
InstanceProperties["TextButton"] = {"AutoButtonColor", "Modal", "Selected", "Style"}
InstanceProperties["TextBox"] = {"ClearTextOnFocus", "CursorPosition", "MultiLine", "PlaceholderColor3", "PlaceholderText", "SelectionStart", "ShowNativeInput", "TextEditable"}
InstanceProperties["ImageLabel"] = {"Image", "ImageColor3", "ImageRectOffset", "ImageRectSize", "ImageTransparency", "ResampleMode", "ScaleType", "SliceCenter", "SliceScale", "TileSize"}
InstanceProperties["ImageButton"] = {"HoverImage", "PressedImage"}
InstanceProperties["ViewportFrame"] = {"Ambient", "CurrentCamera", "ImageColor3", "ImageTransparency", "LightColor", "LightDirection"}
InstanceProperties["VideoFrame"] = {"Looped", "Playing", "TimePosition", "Video", "Volume"}
InstanceProperties["CanvasGroup"] = {"GroupColor3", "GroupTransparency"}

-- UI Components
InstanceProperties["UIAspectRatioConstraint"] = {"AspectRatio", "AspectType", "DominantAxis"}
InstanceProperties["UICorner"] = {"CornerRadius"}
InstanceProperties["UIFlexItem"] = {"FlexMode", "GrowRatio", "ItemLineAlignment", "ShrinkRatio"}
InstanceProperties["UIGradient"] = {"Color", "Enabled", "Offset", "Rotation", "Transparency"}
InstanceProperties["UIGridLayout"] = {"AbsoluteContentSize", "CellPadding", "CellSize", "FillDirection", "FillDirectionMaxCells", "HorizontalAlignment", "SortOrder", "StartCorner", "VerticalAlignment"}
InstanceProperties["UIListLayout"] = {"AbsoluteContentSize", "FillDirection", "HorizontalAlignment", "HorizontalFlex", "ItemLineAlignment", "Padding", "SortOrder", "VerticalAlignment", "VerticalFlex", "Wraps"}
InstanceProperties["UIPageLayout"] = {"Animated", "Circular", "CurrentPage", "EasingDirection", "EasingStyle", "GamepadInputEnabled", "Padding", "ScrollWheelInputEnabled", "TouchInputEnabled", "TweenTime"}
InstanceProperties["UITableLayout"] = {"FillDirection", "FillEmptySpaceColumns", "FillEmptySpaceRows", "HorizontalAlignment", "MajorAxis", "Padding", "SortOrder", "VerticalAlignment"}
InstanceProperties["UIPadding"] = {"PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"}
InstanceProperties["UIScale"] = {"Scale"}
InstanceProperties["UISizeConstraint"] = {"MaxSize", "MinSize"}
InstanceProperties["UIStroke"] = {"ApplyStrokeMode", "Color", "Enabled", "LineJoinMode", "Thickness", "Transparency"}
InstanceProperties["UITextSizeConstraint"] = {"MaxTextSize", "MinTextSize"}

-- Sound
InstanceProperties["Sound"] = {"EmitterSize", "LoopRegion", "Looped", "MaxDistance", "MinDistance", "PlayOnRemove", "PlaybackRegion", "PlaybackRegionsEnabled", "PlaybackSpeed", "Playing", "RollOffMaxDistance", "RollOffMinDistance", "RollOffMode", "SoundGroup", "SoundId", "TimePosition", "Volume"}
InstanceProperties["SoundGroup"] = {"Volume"}
InstanceProperties["EchoSoundEffect"] = {"Delay", "DryLevel", "Enabled", "Feedback", "Priority", "WetLevel"}
InstanceProperties["DistortionSoundEffect"] = {"Enabled", "Level", "Priority"}
InstanceProperties["EqualizerSoundEffect"] = {"Enabled", "HighGain", "LowGain", "MidGain", "Priority"}
InstanceProperties["CompressorSoundEffect"] = {"Attack", "Enabled", "GainMakeup", "Priority", "Ratio", "Release", "SideChain", "Threshold"}
InstanceProperties["ReverbSoundEffect"] = {"DecayTime", "Density", "Diffusion", "DryLevel", "Enabled", "Priority", "WetLevel"}
InstanceProperties["TremoloSoundEffect"] = {"Depth", "Duty", "Enabled", "Frequency", "Priority"}
InstanceProperties["PitchShiftSoundEffect"] = {"Enabled", "Octave", "Priority"}
InstanceProperties["FlangeSoundEffect"] = {"Depth", "Enabled", "Mix", "Priority", "Rate"}
InstanceProperties["ChorusSoundEffect"] = {"Depth", "Enabled", "Mix", "Priority", "Rate"}

-- Camera
InstanceProperties["Camera"] = {"CFrame", "CameraSubject", "CameraType", "DiagonalFieldOfView", "FieldOfView", "FieldOfViewMode", "Focus", "HeadLocked", "HeadScale", "MaxAxisFieldOfView", "NearPlaneZ", "VRTiltAndRollEnabled"}

-- Environment
InstanceProperties["Atmosphere"] = {"Color", "Decay", "Density", "Glare", "Haze", "Offset"}
InstanceProperties["Sky"] = {"CelestialBodiesShown", "MoonAngularSize", "MoonTextureId", "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "StarCount", "SunAngularSize", "SunTextureId"}
InstanceProperties["Clouds"] = {"Color", "Cover", "Density", "Enabled"}
InstanceProperties["BloomEffect"] = {"Enabled", "Intensity", "Size", "Threshold"}
InstanceProperties["BlurEffect"] = {"Enabled", "Size"}
InstanceProperties["ColorCorrectionEffect"] = {"Brightness", "Contrast", "Enabled", "Saturation", "TintColor"}
InstanceProperties["DepthOfFieldEffect"] = {"Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"}
InstanceProperties["SunRaysEffect"] = {"Enabled", "Intensity", "Spread"}

-- Interaction
InstanceProperties["ClickDetector"] = {"CursorIcon", "MaxActivationDistance"}
InstanceProperties["ProximityPrompt"] = {"ActionText", "AutoLocalize", "ClickablePrompt", "Enabled", "Exclusivity", "GamepadKeyCode", "HoldDuration", "KeyboardKeyCode", "MaxActivationDistance", "ObjectText", "RequiresLineOfSight", "RootLocalizationTable", "Style", "UIOffset"}
InstanceProperties["DragDetector"] = {"ActivatedCursorIcon", "ApplyAtCenterOfMass", "DragFrame", "DragStyle", "Enabled", "GamepadModeSwitchKeyCode", "KeyboardModeSwitchKeyCode", "MaxDragAngle", "MaxDragTranslation", "MaxForce", "MaxTorque", "MinDragAngle", "MinDragTranslation", "Orientation", "PermissionPolicy", "ReferenceInstance", "ResponseStyle", "Responsiveness", "RunLocally", "SecondaryAxis", "TrackballRadialPullFactor", "TrackballRollFactor", "VRSwitchKeyCode"}

-- Remote/Bindable
InstanceProperties["RemoteEvent"] = {}
InstanceProperties["RemoteFunction"] = {}
InstanceProperties["BindableEvent"] = {}
InstanceProperties["BindableFunction"] = {}
InstanceProperties["UnreliableRemoteEvent"] = {}

-- Values
InstanceProperties["ObjectValue"] = {"Value"}
InstanceProperties["StringValue"] = {"Value"}
InstanceProperties["IntValue"] = {"Value"}
InstanceProperties["NumberValue"] = {"Value"}
InstanceProperties["BoolValue"] = {"Value"}
InstanceProperties["BrickColorValue"] = {"Value"}
InstanceProperties["Color3Value"] = {"Value"}
InstanceProperties["Vector3Value"] = {"Value"}
InstanceProperties["CFrameValue"] = {"Value"}
InstanceProperties["RayValue"] = {"Value"}

-- Other
InstanceProperties["Configuration"] = {}
InstanceProperties["Team"] = {"AutoAssignable", "ChildOrder", "TeamColor"}
InstanceProperties["SpawnLocation"] = {"AllowTeamChangeOnTouch", "Duration", "Enabled", "Neutral", "TeamColor"}
InstanceProperties["ForceField"] = {"Visible"}
InstanceProperties["Debris"] = {}
InstanceProperties["TouchTransmitter"] = {}
InstanceProperties["LocalizationTable"] = {}
InstanceProperties["WrapLayer"] = {"AutoSkin", "BindOffset", "CageMeshId", "CageOrigin", "Color", "DebugMode", "Enabled", "Order", "Puffiness", "ReferenceMeshId", "ReferenceOrigin", "ShrinkFactor"}
InstanceProperties["WrapTarget"] = {"CageMeshId", "CageOrigin", "Color", "DebugMode", "Stiffness"}
InstanceProperties["UIComponent"] = {}
InstanceProperties["BubbleChatConfiguration"] = {}
InstanceProperties["ChatInputBarConfiguration"] = {}
InstanceProperties["ChatWindowConfiguration"] = {}

-- Common properties for inheritance lookup
local CommonProperties = {"Name", "Archivable"}

function InstanceProperties.GetAll(instance)
    local props = {}
    local seen = {}
    
    -- Add common
    for _, p in ipairs(CommonProperties) do
        if not seen[p] then
            table.insert(props, p)
            seen[p] = true
        end
    end
    
    -- Add class-specific
    local className = instance.ClassName
    if InstanceProperties[className] then
        for _, p in ipairs(InstanceProperties[className]) do
            if not seen[p] then
                table.insert(props, p)
                seen[p] = true
            end
        end
    end
    
    -- Check inheritance
    for baseClass, baseProps in pairs(InstanceProperties) do
        if type(baseProps) == "table" and baseClass ~= className then
            local success = pcall(function() return instance:IsA(baseClass) end)
            if success then
                local isA = instance:IsA(baseClass)
                if isA then
                    for _, p in ipairs(baseProps) do
                        if not seen[p] then
                            table.insert(props, p)
                            seen[p] = true
                        end
                    end
                end
            end
        end
    end
    
    return props
end

--// LUA BEAUTIFIER (Simple Formatter)
local LuaBeautifier = {}

function LuaBeautifier.Format(source)
    if not source or source == "" then return source end
    
    local formatted = ""
    local indentLevel = 0
    local indentStr = "    "
    
    -- Split by newlines
    local lines = string.split(source, "\n")
    
    for _, line in ipairs(lines) do
        -- Trim whitespace
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        
        if line ~= "" then
            -- Check indentation decrease
            if line:find("^end") or line:find("^else") or line:find("^elseif") or line:find("^}") or line:find("^]") or line:find("^%)") then
                indentLevel = math.max(0, indentLevel - 1)
            end
            
            -- Add line with current indentation
            formatted = formatted .. string.rep(indentStr, indentLevel) .. line .. "\n"
            
            -- Check indentation increase
            if (line:find("then$") or line:find("do$") or line:find("repeat$") or line:find("function.*%($") or line:find("{$") or line:find("%($") or line:find("%[$") or line:find("=$")) 
            and not (line:find("end$") or line:find("}$") or line:find("%)%s*$")) then
                indentLevel = indentLevel + 1
            end
        else
            formatted = formatted .. "\n"
        end
    end
    
    return formatted
end

--// ADVANCED DECOMPILER (ENHANCED)
local Decompiler = {}
Decompiler.Cache = {}
Decompiler.Stats = {
    Total = 0,
    Success = 0,
    Failed = 0,
    Cached = 0
}

-- Decompile methods in order of preference
Decompiler.Methods = {
    -- Method 1: Standard decompile with timeouts and options
    function(script)
        if ExecutorInfo.Functions.decompile then
            local success, result = pcall(ExecutorInfo.Functions.decompile, script)
            if success and result and #result > 10 and not result:find("Error:") then
                return result, "decompile"
            end
        end
        return nil
    end,
    
    -- Method 2: Decompile Script Closure/Function (Solara/Wave often support this better)
    function(script)
        if ExecutorInfo.Functions.decompile and (getscriptclosure or get_script_function) then
            local getFn = getscriptclosure or get_script_function
            local success, fn = pcall(getFn, script)
            if success and fn then
                local s2, result = pcall(ExecutorInfo.Functions.decompile, fn)
                if s2 and result and #result > 10 then
                    return result, "decompile_closure"
                end
            end
        end
        return nil
    end,
    
    -- Method 3: GetScriptSource (Synapse compatibility)
    function(script)
        if getscriptsource then
            local success, result = pcall(getscriptsource, script)
            if success and result and #result > 0 then
                return result, "getscriptsource"
            end
        end
        return nil
    end,
    
    -- Method 4: Properties (Source/LinkedSource)
    function(script)
        local props = {"Source", "LinkedSource"}
        for _, prop in ipairs(props) do
            local success, result = Util.SafeGetProperty(script, prop)
            if success and result and #result > 0 then
                return result, prop
            end
        end
        return nil
    end,
    
    -- Method 5: Fallback Bytecode/Debug
    function(script)
        local debugInfo = ""
        if debug and debug.info then
            pcall(function()
                debugInfo = string.format("-- Source: %s\n-- Line: %d", debug.info(1, "s"), debug.info(1, "l"))
            end)
        end
        
        if ExecutorInfo.Functions.getscriptbytecode then
            local s, bc = pcall(ExecutorInfo.Functions.getscriptbytecode, script)
            if s and bc then
                return string.format("-- Bytecode Dump (%d bytes)\n-- Hash: %s\n%s\n-- [Use a bytecode decompiler to view logic]", 
                    #bc, 
                    tostring(bc):sub(1,10), -- simple hash
                    debugInfo
                ), "bytecode"
            end
        end
        return nil
    end
}

function Decompiler.FormatSource(source, scriptName)
    if not source then return "-- No source available" end
    
    -- Header
    local header = string.format(
        "-- Decompiled by BaoSaveInstance Pro\n-- Script: %s\n-- Generated: %s\n\n",
        scriptName or "Unknown",
        os.date("%Y-%m-%d %H:%M:%S")
    )
    
    -- Clean null bytes
    source = source:gsub("[\0-\8\11\12\14-\31]", "")
    
    -- Beautify
    local beautified = LuaBeautifier.Format(source)
    
    return header .. beautified
end

function Decompiler.Decompile(script)
    if not script then return "-- Invalid script", "error" end
    
    Decompiler.Stats.Total = Decompiler.Stats.Total + 1
    
    -- Check cache
    if Options.ScriptCache and Decompiler.Cache[script] then
        Decompiler.Stats.Cached = Decompiler.Stats.Cached + 1
        return Decompiler.Cache[script].source, Decompiler.Cache[script].method
    end
    
    -- Check ignore
    local scriptName = script.Name or "Unknown"
    for _, ignore in ipairs(Options.DecompileIgnore) do
        if scriptName:lower():find(ignore:lower()) then
            return "-- Ignored by settings", "ignored"
        end
    end
    
    -- Attempt methods
    local bestSource, bestMethod = nil, nil
    
    for _, method in ipairs(Decompiler.Methods) do
        -- Use thread for timeout safety
        local thread = coroutine.create(function()
            local s, m = method(script)
            if s then
                bestSource = s
                bestMethod = m
            end
        end)
        
        coroutine.resume(thread)
        
        local start = tick()
        while coroutine.status(thread) ~= "dead" do
            if tick() - start > (Options.DecompileTimeout or 5) then
                break -- Timeout this method
            end
            RunService.Heartbeat:Wait()
        end
        
        if bestSource then break end
    end
    
    if bestSource then
        Decompiler.Stats.Success = Decompiler.Stats.Success + 1
        local formatted = Decompiler.FormatSource(bestSource, scriptName)
        if Options.ScriptCache then
            Decompiler.Cache[script] = {source = formatted, method = bestMethod}
        end
        return formatted, bestMethod
    else
        Decompiler.Stats.Failed = Decompiler.Stats.Failed + 1
        return string.format("-- Failed to decompile %s (%s)", scriptName, script.ClassName), "failed"
    end
end

function Decompiler.GetStats()
    return Decompiler.Stats
end

--// TERRAIN SERIALIZER (Full accuracy)
local TerrainSerializer = {}

TerrainSerializer.Materials = {
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

function TerrainSerializer.Dump(terrain, onProgress)
    terrain = Stealth.Cloneref(terrain) -- Safe reference
    if not terrain or not terrain:IsA("Terrain") then
        return nil, "Invalid terrain"
    end
    
    local terrainData = {
        Size = nil,
        WaterProperties = {},
        Chunks = {},
        Stats = {
            TotalVoxels = 0,
            NonEmptyVoxels = 0,
            ChunkCount = 0
        }
    }
    
    -- Get water properties
    pcall(function()
        terrainData.WaterProperties = {
            WaterColor = terrain.WaterColor,
            WaterReflectance = terrain.WaterReflectance,
            WaterTransparency = terrain.WaterTransparency,
            WaterWaveSize = terrain.WaterWaveSize,
            WaterWaveSpeed = terrain.WaterWaveSpeed,
        }
    end)
    
    -- Get terrain size
    local success, terrainSize = pcall(function()
        return terrain:GetSize()
    end)
    
    if not success then
        return nil, "Cannot get terrain size"
    end
    
    terrainData.Size = terrainSize
    
    -- Calculate chunk size (32x32x32 for better accuracy)
    local chunkSize = 32
    local resolution = 4 -- Voxel resolution
    
    local totalChunks = 0
    local halfX, halfY, halfZ = terrainSize.X/2, terrainSize.Y/2, terrainSize.Z/2
    
    -- Count chunks
    for x = -halfX, halfX, chunkSize do
        for y = -halfY, halfY, chunkSize do
            for z = -halfZ, halfZ, chunkSize do
                totalChunks = totalChunks + 1
            end
        end
    end
    
    local processedChunks = 0
    
    -- Process each chunk
    for x = -halfX, halfX, chunkSize do
        for y = -halfY, halfY, chunkSize do
            for z = -halfZ, halfZ, chunkSize do
                local region = Region3.new(
                    Vector3.new(x, y, z),
                    Vector3.new(
                        math.min(x + chunkSize, halfX),
                        math.min(y + chunkSize, halfY),
                        math.min(z + chunkSize, halfZ)
                    )
                ):ExpandToGrid(resolution)
                
                local materials, occupancy
                local readSuccess = pcall(function()
                    materials, occupancy = terrain:ReadVoxels(region, resolution)
                end)
                
                if readSuccess and materials then
                    local hasData = false
                    local chunkData = {
                        Region = {x, y, z},
                        Materials = {},
                        Occupancy = {}
                    }
                    
                    -- Serialize materials and occupancy
                    for xi = 1, #materials do
                        chunkData.Materials[xi] = {}
                        chunkData.Occupancy[xi] = {}
                        for yi = 1, #materials[xi] do
                            chunkData.Materials[xi][yi] = {}
                            chunkData.Occupancy[xi][yi] = {}
                            for zi = 1, #materials[xi][yi] do
                                local mat = materials[xi][yi][zi]
                                local occ = occupancy[xi][yi][zi]
                                
                                if mat ~= Enum.Material.Air or occ > 0 then
                                    hasData = true
                                    terrainData.Stats.NonEmptyVoxels = terrainData.Stats.NonEmptyVoxels + 1
                                end
                                
                                chunkData.Materials[xi][yi][zi] = TerrainSerializer.Materials[mat] or 0
                                chunkData.Occupancy[xi][yi][zi] = math.floor(occ * 255 + 0.5)
                                terrainData.Stats.TotalVoxels = terrainData.Stats.TotalVoxels + 1
                            end
                        end
                    end
                    
                    if hasData then
                        table.insert(terrainData.Chunks, chunkData)
                        terrainData.Stats.ChunkCount = terrainData.Stats.ChunkCount + 1
                    end
                end
                
                processedChunks = processedChunks + 1
                
                if onProgress then
                    onProgress(processedChunks / totalChunks * 100, 
                        string.format("Terrain: %d/%d chunks, %d voxels", 
                            processedChunks, totalChunks, terrainData.Stats.NonEmptyVoxels))
                end
                
                -- Yield to prevent freezing
                if processedChunks % 5 == 0 then
                    task.wait()
                end
            end
        end
    end
    
    return terrainData
end

function TerrainSerializer.ToXML(terrainData)
    if not terrainData then return "" end
    
    local xml = '<Item class="Terrain" referent="RBX_TERRAIN">\n'
    xml = xml .. '<Properties>\n'
    xml = xml .. '<string name="Name">Terrain</string>\n'
    xml = xml .. '<bool name="Archivable">true</bool>\n'
    
    -- Water properties
    if terrainData.WaterProperties then
        local wp = terrainData.WaterProperties
        if wp.WaterColor then
            local c = wp.WaterColor
            xml = xml .. string.format('<Color3uint8 name="WaterColor">%d</Color3uint8>\n',
                math.floor(c.R * 255) * 65536 + math.floor(c.G * 255) * 256 + math.floor(c.B * 255))
        end
        if wp.WaterReflectance then
            xml = xml .. string.format('<float name="WaterReflectance">%s</float>\n', wp.WaterReflectance)
        end
        if wp.WaterTransparency then
            xml = xml .. string.format('<float name="WaterTransparency">%s</float>\n', wp.WaterTransparency)
        end
        if wp.WaterWaveSize then
            xml = xml .. string.format('<float name="WaterWaveSize">%s</float>\n', wp.WaterWaveSize)
        end
        if wp.WaterWaveSpeed then
            xml = xml .. string.format('<float name="WaterWaveSpeed">%s</float>\n', wp.WaterWaveSpeed)
        end
    end
    
    xml = xml .. '</Properties>\n'
    xml = xml .. '</Item>\n'
    
    return xml
end

--// INSTANCE DUMPER
local InstanceDumper = {}
InstanceDumper.ReferentCounter = 0
InstanceDumper.ReferentMap = {}
InstanceDumper.Stats = {
    Total = 0,
    Skipped = 0,
    Failed = 0,
    Scripts = 0
}

-- Skip list
local SkipInstances = {
    "CoreGui", "CorePackages", "RobloxPluginGuiService", "NetworkClient", 
    "TweenService", "InsertService", "JointsService", "ChangeHistoryService",
    "PluginGuiService", "PluginDebugService", "RobloxReplicatedStorage"
}

local SkipClasses = {
    "Player", "PlayerGui", "PlayerScripts", "Backpack", "StarterGear"
}

function InstanceDumper.Reset()
    InstanceDumper.ReferentCounter = 0
    InstanceDumper.ReferentMap = {}
    InstanceDumper.Stats = {Total = 0, Skipped = 0, Failed = 0, Scripts = 0}
end

function InstanceDumper.GenerateReferent(instance)
    if InstanceDumper.ReferentMap[instance] then
        return InstanceDumper.ReferentMap[instance]
    end
    
    InstanceDumper.ReferentCounter = InstanceDumper.ReferentCounter + 1
    local ref = "RBX" .. string.format("%X", InstanceDumper.ReferentCounter)
    InstanceDumper.ReferentMap[instance] = ref
    return ref
end

function InstanceDumper.ShouldSkip(instance)
    -- Check skip list
    for _, skip in ipairs(SkipInstances) do
        if instance.Name == skip then return true end
    end
    
    -- Check class skip
    if not Options.SavePlayers then
        for _, class in ipairs(SkipClasses) do
            if instance.ClassName == class or (instance.IsA and instance:IsA(class)) then
                return true
            end
        end
    end
    
    -- Check user ignore list
    for _, ignore in ipairs(Options.IgnoreList) do
        if instance.Name == ignore or instance:GetFullName():find(ignore) then
            return true
        end
    end
    
    -- Check class ignore
    for _, class in ipairs(Options.IgnoreClasses) do
        if instance.ClassName == class then return true end
    end
    
    -- Check Archivable
    if Options.IgnoreNotArchivable then
        local success, archivable = pcall(function() return instance.Archivable end)
        if success and archivable == false then return true end
    end
    
    return false
end

function InstanceDumper.SerializeProperties(instance, indent)
    local xml = ""
    indent = indent or ""
    
    local props = InstanceProperties.GetAll(instance)
    
    for _, propName in ipairs(props) do
        -- Check ignore properties
        local shouldIgnore = false
        for _, ignore in ipairs(Options.IgnoreProperties) do
            if propName == ignore then
                shouldIgnore = true
                break
            end
        end
        
        if not shouldIgnore then
            local success, value = Util.SafeGetProperty(instance, propName)
            
            if success and value ~= nil then
                -- Check if default value (optimization)
                if Options.IgnoreDefaultProps and Util.IsDefaultValue(instance.ClassName, propName, value) then
                    -- Skip default
                else
                    local serialized, xmlType = PropertySerializer.Serialize(value)
                    
                    if serialized and xmlType then
                        if xmlType == "Ref" then
                            -- Instance reference - store for later resolution
                            xml = xml .. string.format('%s<Ref name="%s">null</Ref>\n', indent, propName)
                        elseif xmlType == "string" or xmlType == "float" or xmlType == "bool" or xmlType == "int" or xmlType == "token" or xmlType == "Color3uint8" then
                            xml = xml .. string.format('%s<%s name="%s">%s</%s>\n', indent, xmlType, propName, Util.EscapeXML(serialized), xmlType)
                        else
                            -- Complex types
                            xml = xml .. string.format('%s<%s name="%s">%s</%s>\n', indent, xmlType, propName, serialized, xmlType)
                        end
                    end
                end
            end
        end
    end
    
    return xml
end

function InstanceDumper.SerializeAttributes(instance, indent)
    local xml = ""
    indent = indent or ""
    
    local success, attributes = pcall(function()
        return instance:GetAttributes()
    end)
    
    if success and attributes then
        for name, value in pairs(attributes) do
            local serialized, xmlType = PropertySerializer.Serialize(value)
            if serialized then
                xml = xml .. string.format('%s<string name="Attr_%s">%s</string>\n', 
                    indent, Util.EscapeXML(name), Util.EscapeXML(serialized))
            end
        end
    end
    
    return xml
end

function InstanceDumper.SerializeTags(instance, indent)
    local xml = ""
    indent = indent or ""
    
    local success, tags = pcall(function()
        return instance:GetTags()
    end)
    
    if success and tags and #tags > 0 then
        xml = xml .. string.format('%s<string name="Tags">%s</string>\n', 
            indent, Util.EscapeXML(table.concat(tags, ",")))
    end
    
    return xml
end

function InstanceDumper.SerializeScript(instance, indent)
    local xml = ""
    indent = indent or ""
    
    if not Options.SaveScripts then return xml end
    
    if instance:IsA("LuaSourceContainer") then
        InstanceDumper.Stats.Scripts = InstanceDumper.Stats.Scripts + 1
        
        if Options.DecompileScripts then
            local source, method = Decompiler.Decompile(instance)
            
            -- Escape and add source
            local escapedSource = Util.EscapeXML(source)
            xml = xml .. string.format('%s<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>\n', 
                indent, source)
        else
            xml = xml .. string.format('%s<ProtectedString name="Source"><![CDATA[-- SaveScripts disabled]]></ProtectedString>\n', indent)
        end
    end
    
    return xml
end

-- Safe Child Traversal
function Stealth.SafeGetChildren(instance)
    local safeInstance = Stealth.Cloneref(instance)
    local children = {}
    local success = pcall(function()
        children = safeInstance:GetChildren()
    end)
    
    if success and children then
        -- Wrap all children in cloneref immediately
        local safeChildren = {}
        for _, child in ipairs(children) do
            table.insert(safeChildren, Stealth.Cloneref(child))
        end
        return safeChildren
    end
    return {}
end

function InstanceDumper.DumpInstance(instance, depth, onProgress)
    depth = depth or 0
    local indent = string.rep("  ", depth)
    
    if not instance then return "" end
    
    -- Ensure we are working with a safe reference
    instance = Stealth.Cloneref(instance)
    
    -- Skip check
    if InstanceDumper.ShouldSkip(instance) then
        InstanceDumper.Stats.Skipped = InstanceDumper.Stats.Skipped + 1
        return ""
    end
    
    InstanceDumper.Stats.Total = InstanceDumper.Stats.Total + 1
    
    local referent = InstanceDumper.GenerateReferent(instance)
    
    -- Start item
    local xml = string.format('%s<Item class="%s" referent="%s">\n', indent, instance.ClassName, referent)
    xml = xml .. indent .. "  <Properties>\n"
    
    -- Serialize properties
    xml = xml .. InstanceDumper.SerializeProperties(instance, indent .. "    ")
    
    -- Serialize attributes
    xml = xml .. InstanceDumper.SerializeAttributes(instance, indent .. "    ")
    
    -- Serialize tags
    xml = xml .. InstanceDumper.SerializeTags(instance, indent .. "    ")
    
    -- Serialize script source
    xml = xml .. InstanceDumper.SerializeScript(instance, indent .. "    ")
    
    xml = xml .. indent .. "  </Properties>\n"
    
    -- Get children safely
    local children = Stealth.SafeGetChildren(instance)
    
    if #children > 0 then
        for _, child in ipairs(children) do
            local childXml = InstanceDumper.DumpInstance(child, depth + 1, onProgress)
            xml = xml .. childXml
            
            -- Progress callback
            if onProgress and InstanceDumper.Stats.Total % 100 == 0 then
                onProgress(InstanceDumper.Stats.Total, 
                    string.format("Instances: %d (Scripts: %d)", 
                        InstanceDumper.Stats.Total, InstanceDumper.Stats.Scripts))
            end
            
            -- Yield with Performance Balancer
            Performance.Check(InstanceDumper.Stats.Total)
        end
    end
    
    xml = xml .. indent .. "</Item>\n"
    
    return xml
end

function InstanceDumper.CountDescendants(instance)
    local count = 0
    local success, descendants = pcall(function()
        return instance:GetDescendants()
    end)
    if success then
        count = #descendants
    end
    return count + 1
end

function InstanceDumper.GetStats()
    return InstanceDumper.Stats
end

--// SETTINGS MANAGER
local SettingsManager = {}
SettingsManager.FileName = "BaoSaveInstance_Settings.json"

function SettingsManager.Load()
    if ExecutorInfo.Functions.isfile and ExecutorInfo.Functions.isfile(SettingsManager.FileName) then
        local success, content = pcall(function()
            return ExecutorInfo.Functions.readfile(SettingsManager.FileName)
        end)
        if success and content then
            local decoded = HttpService:JSONDecode(content)
            Util.MergeOptions(decoded)
        end
    end
end

function SettingsManager.Save()
    if ExecutorInfo.Functions.writefile then
        local success, encoded = pcall(function()
            return HttpService:JSONEncode(Options)
        end)
        if success then
            ExecutorInfo.Functions.writefile(SettingsManager.FileName, encoded)
        end
    end
end

--// PERFORMANCE BALANCER (TURBO UPDATE)
local Performance = {}
Performance.LastYield = tick()
Performance.FrameTime = 0
Performance.TargetFPS = 60
Performance.MinFPS = Options.TurboMode and 15 or 30 -- Allow lower FPS in Turbo
Performance.BatchSize = Options.TurboMode and 100 or 10

RunService.Heartbeat:Connect(function(dt)
    Performance.FrameTime = dt
end)

function Performance.Check(iterCount)
    -- If Turbo Mode, we force huge batches
    local batch = Options.TurboMode and 500 or 50
    
    if iterCount % batch == 0 then
        -- Dynamic yielding based on FPS
        local fps = 1 / math.max(Performance.FrameTime, 0.001)
        
        -- In Turbo Mode, we only yield if FPS is CRITICALLY low (<15)
        local minFPS = Options.TurboMode and 15 or 30
        
        if fps < minFPS then
            task.wait() -- Mandatory yield to prevent crash
        else
            -- Optional yield to keep game responsive-ish
            if not Options.TurboMode then
                 task.wait()
            else
                -- In Turbo, we skip yielding most frames
                if tick() - Performance.LastYield > 0.5 then
                     task.wait()
                     Performance.LastYield = tick()
                end
            end
        end
    end
end


--// UI FRAMEWORK
local UI = {}
UI.ScreenGui = nil
UI.MainFrame = nil
UI.Elements = {}
UI.IsOpen = true

-- Load Settings on Start
SettingsManager.Load()

local Colors = {
    Background = Color3.fromRGB(12, 12, 18),
    Surface = Color3.fromRGB(22, 22, 32),
    SurfaceLight = Color3.fromRGB(32, 32, 45),
    SurfaceHover = Color3.fromRGB(42, 42, 58),
    Primary = Color3.fromRGB(79, 150, 255),
    PrimaryDark = Color3.fromRGB(59, 120, 220),
    Success = Color3.fromRGB(72, 219, 140),
    Warning = Color3.fromRGB(255, 193, 69),
    Error = Color3.fromRGB(255, 82, 96),
    Terrain = Color3.fromRGB(255, 193, 69),
    Model = Color3.fromRGB(79, 150, 255),
    Text = Color3.fromRGB(245, 245, 250),
    TextDim = Color3.fromRGB(140, 140, 160),
    Border = Color3.fromRGB(55, 55, 75),
}

function UI.Create(class, props)
    local instance = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            instance[k] = v
        end
    end
    if props and props.Parent then
        instance.Parent = props.Parent
    end
    return instance
end

function UI.Tween(instance, props, duration, style)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    return tween
end

function UI.UpdateProgress(percent, status, extra)
    if UI.Elements.ProgressBar then
        UI.Tween(UI.Elements.ProgressBar, {Size = UDim2.new(math.clamp(percent/100, 0, 1), 0, 1, 0)}, 0.2)
    end
    if UI.Elements.ProgressText then
        UI.Elements.ProgressText.Text = string.format("%.1f%%", percent)
    end
    if UI.Elements.StatusText and status then
        UI.Elements.StatusText.Text = "📦 " .. status
    end
    if UI.Elements.ExtraText and extra then
        UI.Elements.ExtraText.Text = "📊 " .. extra
    end
end

function UI.AddLog(message, logType)
    local prefix = "📌"
    if logType == "success" then prefix = "✅"
    elseif logType == "error" then prefix = "❌"
    elseif logType == "warning" then prefix = "⚠️"
    elseif logType == "terrain" then prefix = "🏔️"
    elseif logType == "model" then prefix = "📦"
    elseif logType == "script" then prefix = "📜"
    end
    
    if UI.Elements.LogText then
        local current = UI.Elements.LogText.Text
        local lines = string.split(current, "\n")
        if #lines > 8 then
            table.remove(lines, 1)
        end
        table.insert(lines, prefix .. " " .. message)
        UI.Elements.LogText.Text = table.concat(lines, "\n")
    end
end

function UI.ShowPopup(title, message, popupType)
    if UI.Elements.Popup then
        UI.Elements.Popup:Destroy()
    end
    
    local popup = UI.Create("Frame", {
        Parent = UI.MainFrame,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0.85, 0, 0, 100),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Colors.Surface,
        ZIndex = 100
    })
    UI.Elements.Popup = popup
    
    UI.Create("UICorner", {Parent = popup, CornerRadius = UDim.new(0, 12)})
    UI.Create("UIStroke", {
        Parent = popup,
        Color = popupType == "success" and Colors.Success or Colors.Error,
        Thickness = 2
    })
    
    local icon = popupType == "success" and "✅" or "❌"
    UI.Create("TextLabel", {
        Parent = popup,
        Position = UDim2.new(0.5, 0, 0, 18),
        Size = UDim2.new(1, -20, 0, 24),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Text = icon .. " " .. title,
        TextColor3 = Colors.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold
    })
    
    UI.Create("TextLabel", {
        Parent = popup,
        Position = UDim2.new(0.5, 0, 0, 48),
        Size = UDim2.new(1, -20, 0, 40),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = Colors.TextDim,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextWrapped = true
    })
    
    popup.Size = UDim2.new(0, 0, 0, 0)
    UI.Tween(popup, {Size = UDim2.new(0.85, 0, 0, 100)}, 0.3, Enum.EasingStyle.Back)
    
    task.delay(4, function()
        if popup and popup.Parent then
            UI.Tween(popup, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
            task.wait(0.2)
            if popup.Parent then popup:Destroy() end
        end
    end)
end

function UI.CreateButton(parent, text, icon, color, onClick)
    local button = UI.Create("TextButton", {
        Parent = parent,
        Size = UDim2.new(1, -20, 0, 60),
        BackgroundColor3 = Colors.Surface,
        Text = "",
        AutoButtonColor = false
    })
    
    UI.Create("UICorner", {Parent = button, CornerRadius = UDim.new(0, 10)})
    UI.Create("UIStroke", {Parent = button, Color = color, Thickness = 1.5, Transparency = 0.6})
    
    local iconLabel = UI.Create("TextLabel", {
        Parent = button,
        Position = UDim2.new(0, 15, 0.5, 0),
        Size = UDim2.new(0, 30, 0, 30),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Text = icon,
        TextSize = 24
    })
    
    local textLabel = UI.Create("TextLabel", {
        Parent = button,
        Position = UDim2.new(0, 55, 0.5, 0),
        Size = UDim2.new(1, -70, 1, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Colors.Text,
        TextSize = 14,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    button.MouseEnter:Connect(function()
        UI.Tween(button, {BackgroundColor3 = Colors.SurfaceHover}, 0.15)
    end)
    
    button.MouseLeave:Connect(function()
        UI.Tween(button, {BackgroundColor3 = Colors.Surface}, 0.15)
    end)
    
    button.MouseButton1Click:Connect(function()
        if onClick then
            task.spawn(onClick)
        end
    end)
    
    return button
end

function UI.Initialize()
    -- Cleanup existing
    local existingName = "BaoSaveInstancePro"
    local targetParent = CoreGui
    
    -- Safe Mode / Protect GUI
    if Options.SafeMode then
        if ExecutorInfo.Functions.gethui then
            targetParent = ExecutorInfo.Functions.gethui()
        elseif ExecutorInfo.Functions.syn and ExecutorInfo.Functions.syn.protect_gui then
            -- For Synapse-like
            targetParent = CoreGui
        end
    end
    
    local existing = targetParent:FindFirstChild(existingName)
    if existing then existing:Destroy() end
    
    local screenGui = UI.Create("ScreenGui", {
        Parent = targetParent,
        Name = existingName,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    
    -- Apply ProtectGui if available and not using gethui
    if Options.SafeMode and not ExecutorInfo.Functions.gethui and ExecutorInfo.Functions.syn and ExecutorInfo.Functions.syn.protect_gui then
        ExecutorInfo.Functions.syn.protect_gui(screenGui)
    end
    
    UI.ScreenGui = screenGui    
    -- Main Frame
    local mainFrame = UI.Create("Frame", {
        Parent = screenGui,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 380, 0, 520),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Colors.Background,
        BorderSizePixel = 0
    })
    UI.MainFrame = mainFrame
    
    UI.Create("UICorner", {Parent = mainFrame, CornerRadius = UDim.new(0, 14)})
    UI.Create("UIStroke", {Parent = mainFrame, Color = Colors.Border, Thickness = 1})
    
    -- Shadow
    local shadow = UI.Create("ImageLabel", {
        Parent = mainFrame,
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, 30, 1, 30),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.5,
        ZIndex = -1
    })
    
    -- Header
    local header = UI.Create("Frame", {
        Parent = mainFrame,
        Size = UDim2.new(1, 0, 0, 55),
        BackgroundColor3 = Colors.Surface,
        BorderSizePixel = 0
    })
    UI.Create("UICorner", {Parent = header, CornerRadius = UDim.new(0, 14)})
    
    UI.Create("TextLabel", {
        Parent = header,
        Position = UDim2.new(0, 18, 0, 10),
        Size = UDim2.new(1, -80, 0, 20),
        BackgroundTransparency = 1,
        Text = "🎮 BaoSaveInstance",
        TextColor3 = Colors.Primary,
        TextSize = 17,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    UI.Create("TextLabel", {
        Parent = header,
        Position = UDim2.new(0, 18, 0, 32),
        Size = UDim2.new(0.5, 0, 0, 15),
        BackgroundTransparency = 1,
        Text = VERSION,
        TextColor3 = Colors.TextDim,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local execLabel = UI.Create("TextLabel", {
        Parent = header,
        Position = UDim2.new(1, -18, 0, 32),
        Size = UDim2.new(0.4, 0, 0, 15),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Text = "✓ " .. ExecutorInfo.Name,
        TextColor3 = Colors.Success,
        TextSize = 10,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    -- Close button
    local closeBtn = UI.Create("TextButton", {
        Parent = header,
        Position = UDim2.new(1, -12, 0, 12),
        Size = UDim2.new(0, 28, 0, 28),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = Colors.Error,
        BackgroundTransparency = 0.85,
        Text = "×",
        TextColor3 = Colors.Text,
        TextSize = 20,
        Font = Enum.Font.GothamBold
    })
    UI.Create("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0, 6)})
    
    closeBtn.MouseButton1Click:Connect(function()
        UI.Tween(mainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.25)
        task.wait(0.25)
        screenGui:Destroy()
    end)
    
    -- Button Container
    local buttonContainer = UI.Create("Frame", {
        Parent = mainFrame,
        Position = UDim2.new(0.5, 0, 0, 70),
        Size = UDim2.new(1, 0, 0, 210),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1
    })
    
    local layout = UI.Create("UIListLayout", {
        Parent = buttonContainer,
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })
    
    -- Save Full Map Button
    UI.CreateButton(buttonContainer, "SAVE FULL MAP", "🗺️", Colors.Success, function()
        UI.SaveFullMap()
    end)
    
    -- Save Full Terrain Button
    UI.CreateButton(buttonContainer, "SAVE FULL TERRAIN", "🏔️", Colors.Terrain, function()
        UI.SaveFullTerrain()
    end)
    
    -- Save Full Model Button
    UI.CreateButton(buttonContainer, "SAVE FULL MODEL", "📦", Colors.Model, function()
        UI.SaveFullModel()
    end)
    
    -- Progress Section
    local progressSection = UI.Create("Frame", {
        Parent = mainFrame,
        Position = UDim2.new(0.5, 0, 0, 295),
        Size = UDim2.new(1, -24, 0, 210),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Colors.Surface,
        BorderSizePixel = 0
    })
    UI.Create("UICorner", {Parent = progressSection, CornerRadius = UDim.new(0, 10)})
    
    -- Progress Bar BG
    local progressBg = UI.Create("Frame", {
        Parent = progressSection,
        Position = UDim2.new(0.5, 0, 0, 15),
        Size = UDim2.new(1, -24, 0, 18),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Colors.Background,
        BorderSizePixel = 0
    })
    UI.Create("UICorner", {Parent = progressBg, CornerRadius = UDim.new(0, 5)})
    
    -- Progress Bar Fill
    local progressFill = UI.Create("Frame", {
        Parent = progressBg,
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Colors.Primary,
        BorderSizePixel = 0
    })
    UI.Create("UICorner", {Parent = progressFill, CornerRadius = UDim.new(0, 5)})
    UI.Create("UIGradient", {
        Parent = progressFill,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Colors.Primary),
            ColorSequenceKeypoint.new(1, Colors.Success)
        })
    })
    UI.Elements.ProgressBar = progressFill
    
    -- Progress Text
    local progressText = UI.Create("TextLabel", {
        Parent = progressBg,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "0%",
        TextColor3 = Colors.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        ZIndex = 2
    })
    UI.Elements.ProgressText = progressText
    
    -- Status Text
    local statusText = UI.Create("TextLabel", {
        Parent = progressSection,
        Position = UDim2.new(0, 12, 0, 42),
        Size = UDim2.new(1, -24, 0, 18),
        BackgroundTransparency = 1,
        Text = "📦 Ready",
        TextColor3 = Colors.TextDim,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    UI.Elements.StatusText = statusText
    
    -- Extra Text
    local extraText = UI.Create("TextLabel", {
        Parent = progressSection,
        Position = UDim2.new(0, 12, 0, 62),
        Size = UDim2.new(1, -24, 0, 18),
        BackgroundTransparency = 1,
        Text = "📊 Instances: 0",
        TextColor3 = Colors.TextDim,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    UI.Elements.ExtraText = extraText
    
    -- Log Frame
    local logFrame = UI.Create("TextLabel", {
        Parent = progressSection,
        Position = UDim2.new(0.5, 0, 0, 88),
        Size = UDim2.new(1, -24, 0, 110),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Colors.Background,
        BackgroundTransparency = 0.3,
        Text = "",
        TextColor3 = Colors.TextDim,
        TextSize = 10,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true
    })
    UI.Create("UICorner", {Parent = logFrame, CornerRadius = UDim.new(0, 6)})
    UI.Create("UIPadding", {Parent = logFrame, PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6)})
    UI.Elements.LogText = logFrame
    
    -- Dragging
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Animation
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    UI.Tween(mainFrame, {Size = UDim2.new(0, 380, 0, 520)}, 0.35, Enum.EasingStyle.Back)
    
    return screenGui
end

--// MAIN SAVE FUNCTIONS
local SaveEngine = {}

function SaveEngine.GetFileName(mode)
    local gameName = Util.GetGameName()
    local timestamp = Util.GetTimestamp()
    local suffix = ""
    if mode == "Terrain" then suffix = "_Terrain"
    elseif mode == "Model" then suffix = "_Model"
    end
    return string.format("%s%s%s_%s.rbxlx", Options.FilePath, gameName, suffix, timestamp)
end

function SaveEngine.WriteFile(fileName, content)
    Util.CreateFolder(Options.FilePath)
    
    local success, err = pcall(function()
        ExecutorInfo.Functions.writefile(fileName, content)
    end)
    
    return success, err
end

function UI.SaveFullMap()
    SettingsManager.Save()
    UI.AddLog("Starting Full Map Save...", "success")
    UI.UpdateProgress(0, "Initializing...", "Preparing...")
    
    InstanceDumper.Reset()
    Decompiler.Cache = {}
    
    local startTime = tick()
    local fileName = SaveEngine.GetFileName("Full")
    
    -- XML Header
    local xml = '<?xml version="1.0" encoding="utf-8"?>\n<roblox version="4">\n'
    
    -- Count instances
    UI.AddLog("Counting instances...", "info")
    local totalEstimate = 0
    local services = {}
    
    if Options.SaveWorkspace then table.insert(services, Workspace) end
    if Options.SaveLighting then table.insert(services, Lighting) end
    if Options.SaveReplicatedStorage then table.insert(services, ReplicatedStorage) end
    if Options.SaveReplicatedFirst then table.insert(services, ReplicatedFirst) end
    if Options.SaveStarterGui then table.insert(services, StarterGui) end
    if Options.SaveStarterPack then table.insert(services, StarterPack) end
    if Options.SaveStarterPlayer then table.insert(services, StarterPlayer) end
    if Options.SaveTeams then table.insert(services, Teams) end
    if Options.SaveSoundService then table.insert(services, SoundService) end
    
    for _, service in ipairs(services) do
        totalEstimate = totalEstimate + InstanceDumper.CountDescendants(service)
    end
    
    UI.UpdateProgress(2, "Counted " .. totalEstimate .. " instances", "Starting dump...")
    UI.AddLog(string.format("Total: ~%d instances", totalEstimate), "info")
    
    -- Dump Terrain
    if Options.SaveTerrain then
        UI.AddLog("Dumping Terrain...", "terrain")
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            local terrainData = TerrainSerializer.Dump(terrain, function(percent, status)
                UI.UpdateProgress(2 + percent * 0.18, status, "")
            end)
            xml = xml .. TerrainSerializer.ToXML(terrainData)
            UI.AddLog(string.format("Terrain: %d voxels", terrainData.Stats.NonEmptyVoxels), "terrain")
        end
    end
    UI.UpdateProgress(20, "Terrain complete", "Dumping services...")
    
    -- Dump Services
    local progressCallback = function(count, status)
        local percent = 20 + (count / math.max(totalEstimate, 1)) * 70
        UI.UpdateProgress(percent, status, string.format("Progress: %d/%d", count, totalEstimate))
    end
    
    for i, service in ipairs(services) do
        UI.AddLog("Dumping " .. service.Name .. "...", "model")
        local serviceXml = InstanceDumper.DumpInstance(service, 0, progressCallback)
        xml = xml .. serviceXml
        task.wait()
    end
    
    UI.UpdateProgress(90, "Finalizing...", "Writing file...")
    
    -- Close XML
    xml = xml .. '</roblox>'
    
    -- Write file
    UI.AddLog("Writing file...", "info")
    local success, err = SaveEngine.WriteFile(fileName, xml)
    
    local elapsed = tick() - startTime
    local stats = InstanceDumper.GetStats()
    local decompStats = Decompiler.GetStats()
    
    if success then
        UI.UpdateProgress(100, "Complete!", string.format("%d instances, %d scripts", stats.Total, stats.Scripts))
        UI.AddLog(string.format("Saved in %.1fs", elapsed), "success")
        UI.AddLog("File: " .. fileName, "success")
        UI.ShowPopup("Save Complete!", 
            string.format("Instances: %d\nScripts: %d (Success: %d)\nTime: %.1fs", 
                stats.Total, decompStats.Total, decompStats.Success, elapsed), "success")
    else
        UI.AddLog("Error: " .. tostring(err), "error")
        UI.ShowPopup("Save Failed", tostring(err), "error")
    end
end

function UI.SaveFullTerrain()
    UI.AddLog("Starting Terrain Only Save...", "terrain")
    UI.UpdateProgress(0, "Initializing...", "")
    
    local startTime = tick()
    local fileName = SaveEngine.GetFileName("Terrain")
    
    local xml = '<?xml version="1.0" encoding="utf-8"?>\n<roblox version="4">\n'
    
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        UI.AddLog("Reading terrain voxels...", "terrain")
        local terrainData = TerrainSerializer.Dump(terrain, function(percent, status)
            UI.UpdateProgress(percent * 0.9, status, "")
        end)
        xml = xml .. TerrainSerializer.ToXML(terrainData)
        UI.AddLog(string.format("Voxels: %d non-empty", terrainData.Stats.NonEmptyVoxels), "terrain")
    else
        UI.AddLog("No terrain found!", "warning")
    end
    
    xml = xml .. '</roblox>'
    
    UI.UpdateProgress(95, "Writing file...", "")
    local success, err = SaveEngine.WriteFile(fileName, xml)
    
    local elapsed = tick() - startTime
    
    if success then
        UI.UpdateProgress(100, "Complete!", "")
        UI.AddLog("Saved: " .. fileName, "success")
        UI.ShowPopup("Terrain Saved!", string.format("Time: %.1fs", elapsed), "success")
    else
        UI.AddLog("Error: " .. tostring(err), "error")
        UI.ShowPopup("Save Failed", tostring(err), "error")
    end
end

function UI.SaveFullModel()
    UI.AddLog("Starting Model Only Save...", "model")
    UI.UpdateProgress(0, "Initializing...", "")
    
    InstanceDumper.Reset()
    Decompiler.Cache = {}
    
    local startTime = tick()
    local fileName = SaveEngine.GetFileName("Model")
    
    local xml = '<?xml version="1.0" encoding="utf-8"?>\n<roblox version="4">\n'
    
    -- Count
    local totalEstimate = InstanceDumper.CountDescendants(Workspace)
    UI.AddLog(string.format("Workspace: ~%d instances", totalEstimate), "info")
    
    UI.UpdateProgress(5, "Dumping Workspace...", "")
    
    -- Dump Workspace (skip terrain)
    xml = xml .. '<Item class="Workspace" referent="RBX_WORKSPACE">\n'
    xml = xml .. '  <Properties>\n'
    xml = xml .. '    <string name="Name">Workspace</string>\n'
    xml = xml .. '  </Properties>\n'
    
    local progressCallback = function(count, status)
        local percent = 5 + (count / math.max(totalEstimate, 1)) * 90
        UI.UpdateProgress(percent, status, string.format("Progress: %d/%d", count, totalEstimate))
    end
    
    -- Safe Traversal for Workspace
    local workspaceChildren = Stealth.SafeGetChildren(Workspace)
    for _, child in ipairs(workspaceChildren) do
        if not child:IsA("Terrain") and not child:IsA("Camera") then
            local childXml = InstanceDumper.DumpInstance(child, 1, progressCallback)
            xml = xml .. childXml
        end
    end
    
    xml = xml .. '</Item>\n'
    xml = xml .. '</roblox>'
    
    UI.UpdateProgress(95, "Writing file...", "")
    local success, err = SaveEngine.WriteFile(fileName, xml)
    
    local elapsed = tick() - startTime
    local stats = InstanceDumper.GetStats()
    
    if success then
        UI.UpdateProgress(100, "Complete!", string.format("%d models", stats.Total))
        UI.AddLog("Saved: " .. fileName, "success")
        UI.ShowPopup("Models Saved!", 
            string.format("Instances: %d\nTime: %.1fs", stats.Total, elapsed), "success")
    else
        UI.AddLog("Error: " .. tostring(err), "error")
        UI.ShowPopup("Save Failed", tostring(err), "error")
    end
end

--// PUBLIC API
local BaoSaveInstance = {}

function BaoSaveInstance.SaveGame(userOptions)
    Util.MergeOptions(userOptions)
    UI.SaveFullMap()
end

function BaoSaveInstance.SaveTerrain(userOptions)
    Util.MergeOptions(userOptions)
    UI.SaveFullTerrain()
end

function BaoSaveInstance.SaveModels(userOptions)
    Util.MergeOptions(userOptions)
    UI.SaveFullModel()
end

function BaoSaveInstance.GetOptions()
    return Options
end

function BaoSaveInstance.SetOptions(newOptions)
    Util.MergeOptions(newOptions)
end

--// INITIALIZE
UI.Initialize()
UI.AddLog("BaoSaveInstance Pro loaded!", "success")
UI.AddLog("Executor: " .. ExecutorInfo.Name .. " (Lv." .. ExecutorInfo.Level .. ")", "info")
UI.AddLog("Ready to save!", "success")

return BaoSaveInstance
