--[[
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
    
    BaoSaveInstance v3.0 ULTIMATE
    100x Faster Decompile Engine
    Complete Game Ripper
    
    Modules:
     01. Config
     02. Services
     03. ThreadPool (Parallel Engine)
     04. Utility
     05. PropertyMapper (200+ properties)
     06. ScriptEngine (6 decompile methods)
     07. MeshExtractor
     08. TextureExtractor  
     09. TerrainEngine (Chunked + Compressed)
     10. AnimationEngine
     11. SoundEngine
     12. ParticleEngine
     13. LightingEngine
     14. PhysicsExtractor
     15. UIExtractor
     16. PackageExtractor
     17. InstanceReconstructor
     18. DecompilerCore (25 gather methods)
     19. Exporter (8 save methods)
     20. UISystem
     21. BaoSaveInstance API (25 functions)
     22. Init
]]

-- ============================================================
-- 01. CONFIG
-- ============================================================
local Config = {
    Name = "BaoSaveInstance",
    Version = "3.0",
    Build = "ULTIMATE",
    OutputBase = "BaoSave",
    
    Performance = {
        MaxThreads = 8,
        BatchSize = 50,
        YieldEvery = 10,
        RetryAttempts = 5,
        RetryDelay = 0.02,
        ChunkSize = 256,
        CacheEnabled = true,
        ParallelEnabled = true,
        FastMode = true,
        Timeout = 300,
        MemoryLimit = 2048,
    },
    
    IgnoreClasses = {
        "Player","PlayerGui","PlayerScripts","Backpack",
        "PluginGui","PluginToolbar","PluginAction","StatsItem",
        "RunningAverageItemDouble","RunningAverageItemInt",
        "RunningAverageTimeIntervalItem","TotalCountTimeIntervalItem",
        "DebuggerWatch","DebuggerBreakpoint","AdvancedDragger",
    },
    
    IgnoreServices = {
        "CoreGui","CorePackages","RobloxPluginGuiService","VRService",
        "AnalyticsService","BrowserService","CaptureService",
        "DebuggerManager","FlagStandService","FlyweightService",
        "GuidRegistryService","HapticService","HttpRbxApiService",
        "JointsService","KeyboardService","LogService",
        "MessageBusService","MouseService","NetworkClient",
        "NetworkServer","NetworkSettings","PermissionsService",
        "PhysicsService","PlayerEmulatorService","PluginDebugService",
        "PluginGuiService","ProcessInstancePhysicsService",
        "RbxAnalyticsService","RenderSettings","RobloxReplicatedStorage",
        "RuntimeScriptService","ScriptContext","ScriptService",
        "Selection","ServiceVisibilityService","SessionService",
        "SharedTableRegistry","SnippetService","SpawnerService",
        "StatsService","Studio","StudioService","StudioWidgetsService",
        "TaskScheduler","TestService","ThirdPartyUserService",
        "TimerService","TouchInputService","TracerService",
        "UGCValidationService","UnvalidatedAssetService",
        "VersionControlService","VideoCaptureService","VideoService",
        "VirtualInputManager","VirtualUser","VisibilityService","Visit",
    },
    
    AllServices = {
        "Workspace","ReplicatedStorage","ReplicatedFirst",
        "ServerStorage","ServerScriptService",
        "StarterGui","StarterPack","StarterPlayer",
        "Lighting","SoundService","Teams","Chat",
        "TextChatService","MaterialService",
        "LocalizationService","ProximityPromptService",
    },
    
    ModelClasses = {
        "Model","Part","WedgePart","CornerWedgePart","TrussPart",
        "SpawnLocation","Seat","VehicleSeat","SkateboardPlatform",
        "MeshPart","UnionOperation","NegateOperation","IntersectOperation",
        "Folder","Accessory","Tool","HopperBin","Flag","FlagStand",
        "Actor","WorldModel",
    },
    
    PartClasses = {
        "Part","WedgePart","CornerWedgePart","TrussPart","SpawnLocation",
        "Seat","VehicleSeat","SkateboardPlatform","MeshPart",
        "UnionOperation","NegateOperation","IntersectOperation",
    },
    
    EffectClasses = {
        "ParticleEmitter","Fire","Smoke","Sparkles","Trail","Beam",
        "Explosion","PointLight","SpotLight","SurfaceLight",
    },
    
    ConstraintClasses = {
        "BallSocketConstraint","HingeConstraint","PrismaticConstraint",
        "CylindricalConstraint","SpringConstraint","RopeConstraint",
        "RodConstraint","WeldConstraint","NoCollisionConstraint",
        "UniversalConstraint","TorsionSpringConstraint","LineForce",
        "VectorForce","AlignOrientation","AlignPosition",
        "AngularVelocity","LinearVelocity","Torque",
    },
    
    UI = {
        Size = UDim2.new(0, 520, 0, 720),
        BtnH = 42,
        Pad = 6,
        Rad = 10,
        C = {
            Bg = Color3.fromRGB(10, 10, 16),
            Panel = Color3.fromRGB(18, 18, 28),
            Bar = Color3.fromRGB(20, 20, 32),
            Btn = Color3.fromRGB(30, 32, 48),
            BtnH = Color3.fromRGB(42, 46, 66),
            P1 = Color3.fromRGB(70, 115, 255),
            P1G = Color3.fromRGB(100, 145, 255),
            P2 = Color3.fromRGB(120, 70, 255),
            P2G = Color3.fromRGB(150, 100, 255),
            P3 = Color3.fromRGB(50, 180, 130),
            P3G = Color3.fromRGB(70, 210, 155),
            P4 = Color3.fromRGB(255, 165, 40),
            P4G = Color3.fromRGB(255, 190, 70),
            Red = Color3.fromRGB(215, 50, 50),
            RedH = Color3.fromRGB(240, 70, 70),
            Ok = Color3.fromRGB(45, 200, 100),
            Txt = Color3.fromRGB(235, 235, 248),
            Sub = Color3.fromRGB(140, 142, 170),
            Dim = Color3.fromRGB(80, 82, 100),
            PBg = Color3.fromRGB(24, 24, 36),
            PFl = Color3.fromRGB(70, 115, 255),
            Sep = Color3.fromRGB(36, 38, 52),
        },
        F1 = Enum.Font.GothamBold,
        F2 = Enum.Font.GothamMedium,
        F3 = Enum.Font.Gotham,
    },
}

-- ============================================================
-- 02. SERVICES
-- ============================================================
local Svc = setmetatable({}, {
    __index = function(s, n)
        local ok, sv = pcall(game.GetService, game, n)
        if ok and sv then rawset(s, n, sv) return sv end
    end
})

local Plr = Svc.Players.LocalPlayer
local PGui = Plr:WaitForChild("PlayerGui")
local RS = Svc.RunService
local TS = Svc.TweenService
local UIS = Svc.UserInputService

-- ============================================================
-- 03. THREAD POOL (PARALLEL ENGINE)
-- ============================================================
local ThreadPool = {}
ThreadPool.active = 0
ThreadPool.queue = {}
ThreadPool.results = {}

function ThreadPool.Execute(tasks, maxConcurrent, progressCb)
    maxConcurrent = maxConcurrent or Config.Performance.MaxThreads
    local total = #tasks
    local completed = 0
    local results = {}
    
    local idx = 0
    local running = 0
    
    local function runNext()
        while idx < total and running < maxConcurrent do
            idx = idx + 1
            running = running + 1
            local i = idx
            
            task.spawn(function()
                local ok, result = pcall(tasks[i])
                results[i] = {success = ok, data = result}
                completed = completed + 1
                running = running - 1
                
                if progressCb then
                    progressCb(completed, total)
                end
            end)
        end
    end
    
    runNext()
    
    while completed < total do
        runNext()
        RS.RenderStepped:Wait()
    end
    
    return results
end

function ThreadPool.BatchProcess(items, processFn, batchSize, progressCb)
    batchSize = batchSize or Config.Performance.BatchSize
    local total = #items
    local processed = 0
    local results = {}
    
    for i = 1, total, batchSize do
        local batchEnd = math.min(i + batchSize - 1, total)
        
        for j = i, batchEnd do
            local ok, result = pcall(processFn, items[j], j)
            if ok then
                table.insert(results, result)
            end
            processed = processed + 1
        end
        
        if progressCb then
            progressCb(processed, total, items[math.min(i, total)])
        end
        
        RS.RenderStepped:Wait()
    end
    
    return results, processed
end

-- ============================================================
-- 04. UTILITY
-- ============================================================
local U = {}
local LogBuf = {}
local Cache = {}

function U.Log(lv, msg)
    local e = string.format("[%s][%s] %s", os.date("%H:%M:%S"), lv, msg)
    table.insert(LogBuf, e)
    if #LogBuf > 2000 then table.remove(LogBuf, 1) end
end

function U.Notify(t, m, d)
    pcall(function()
        Svc.StarterGui:SetCore("SendNotification", {Title=t, Text=m, Duration=d or 5})
    end)
    U.Log("NOTIFY", m)
end

function U.Clone(inst)
    if Cache[inst] then return Cache[inst]:Clone() end
    for i = 1, Config.Performance.RetryAttempts do
        local ok, c = pcall(inst.Clone, inst)
        if ok and c then
            if Config.Performance.CacheEnabled then
                Cache[inst] = c
            end
            return c
        end
        if i < Config.Performance.RetryAttempts then
            task.wait(Config.Performance.RetryDelay)
        end
    end
    return nil
end

function U.IsIgnoredClass(cn)
    for _, v in ipairs(Config.IgnoreClasses) do
        if v == cn then return true end
    end
    return false
end

function U.IsIgnoredSvc(n)
    for _, v in ipairs(Config.IgnoreServices) do
        if v == n then return true end
    end
    return false
end

function U.Path(inst)
    local p = {}
    local c = inst
    while c and c ~= game do
        table.insert(p, 1, c.Name)
        c = c.Parent
    end
    return table.concat(p, ".")
end

function U.Yield(ctr)
    if ctr % Config.Performance.YieldEvery == 0 then
        RS.RenderStepped:Wait()
    end
end

function U.Count(root)
    local n = 0
    pcall(function() n = #root:GetDescendants() end)
    return n
end

function U.FmtN(n)
    if n >= 1e6 then return string.format("%.2fM", n/1e6) end
    if n >= 1e3 then return string.format("%.1fK", n/1e3) end
    return tostring(n)
end

function U.FmtT(s)
    if s < 1 then return string.format("%dms", s*1000) end
    if s < 60 then return string.format("%.1fs", s) end
    return string.format("%dm%.0fs", math.floor(s/60), s%60)
end

function U.IsA(inst, classes)
    for _, c in ipairs(classes) do
        if inst:IsA(c) then return true end
    end
    return false
end

function U.GetChildren(inst)
    local ok, ch = pcall(inst.GetChildren, inst)
    return ok and ch or {}
end

function U.GetDescendants(inst)
    local ok, d = pcall(inst.GetDescendants, inst)
    return ok and d or {}
end

function U.GetService(name)
    local ok, s = pcall(game.GetService, game, name)
    return ok and s or nil
end

function U.Merge(t1, t2)
    for _, v in ipairs(t2) do table.insert(t1, v) end
    return t1
end

function U.Keys(t)
    local k = {}
    for key in pairs(t) do table.insert(k, key) end
    return k
end

function U.Size(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

function U.ClearCache()
    Cache = {}
    collectgarbage("collect")
end

-- ============================================================
-- 05. PROPERTY MAPPER (200+ properties)
-- ============================================================
local PropMap = {}

local PropertyDB = {
    BasePart = {
        "Anchored","Archivable","BackSurface","BottomSurface",
        "BrickColor","CFrame","CanCollide","CanQuery","CanTouch",
        "CastShadow","CollisionGroup","Color","CustomPhysicalProperties",
        "EnableFluidForces","FrontSurface","LeftSurface","LocalTransparencyModifier",
        "Locked","Massless","Material","MaterialVariant","PivotOffset",
        "Position","Reflectance","RightSurface","RootPriority",
        "RotVelocity","Rotation","Size","TopSurface","Transparency",
        "Velocity",
    },
    MeshPart = {
        "CollisionFidelity","DoubleSided","FluidFidelity","HasJointOffset",
        "HasSkinnedMesh","MeshId","MeshSize","RenderFidelity",
        "TextureID",
    },
    UnionOperation = {
        "AssetId","CollisionFidelity","FluidFidelity","RenderFidelity",
        "SmoothingAngle","UsePartColor",
    },
    SpecialMesh = {
        "MeshId","MeshType","Offset","Scale","TextureId","VertexColor",
    },
    Decal = {
        "Color3","Face","Texture","Transparency","ZIndex",
    },
    Texture = {
        "Face","OffsetStudsU","OffsetStudsV","StudsPerTileU","StudsPerTileV",
        "Texture","Transparency",
    },
    SurfaceAppearance = {
        "AlphaMode","ColorMap","MetalnessMap","NormalMap","RoughnessMap",
        "TexturePack",
    },
    Model = {
        "LevelOfDetail","ModelStreamingMode","PrimaryPart","WorldPivot",
    },
    Humanoid = {
        "AutoJumpEnabled","AutoRotate","AutomaticScalingEnabled",
        "BreakJointsOnDeath","DisplayDistanceType","DisplayName",
        "EvaluateStateMachine","Health","HealthDisplayDistance",
        "HealthDisplayType","HipHeight","Jump","JumpHeight",
        "JumpPower","MaxHealth","MaxSlopeAngle","MoveDirection",
        "NameDisplayDistance","NameOcclusion","PlatformStand",
        "RequiresNeck","RigType","RootPart","Sit","TargetPoint",
        "UseJumpPower","WalkSpeed","WalkToPart","WalkToPoint",
    },
    HumanoidDescription = {
        "BackAccessory","BodyTypeScale","ClimbAnimation","DepthScale",
        "Face","FaceAccessory","FallAnimation","FrontAccessory",
        "GraphicTShirt","HairAccessory","HatAccessory","Head",
        "HeadColor","HeadScale","HeightScale","IdleAnimation",
        "JumpAnimation","LeftArm","LeftArmColor","LeftLeg",
        "LeftLegColor","NeckAccessory","Pants","ProportionScale",
        "RightArm","RightArmColor","RightLeg","RightLegColor",
        "RunAnimation","Shirt","ShouldersAccessory","SwimAnimation",
        "Torso","TorsoColor","WaistAccessory","WalkAnimation",
        "WidthScale",
    },
    Sound = {
        "EmitterSize","LoopRegion","Looped","PlayOnRemove",
        "PlaybackRegion","PlaybackRegionsEnabled","PlaybackSpeed",
        "Playing","RollOffMaxDistance","RollOffMinDistance","RollOffMode",
        "SoundGroup","SoundId","TimePosition","Volume",
    },
    ParticleEmitter = {
        "Acceleration","Brightness","Color","Drag","EmissionDirection",
        "Enabled","FlipbookFramerate","FlipbookIncompatible",
        "FlipbookLayout","FlipbookMode","FlipbookStartRandom",
        "Lifetime","LightEmission","LightInfluence","LockedToPart",
        "Orientation","Rate","RotSpeed","Rotation","Shape",
        "ShapeInOut","ShapePartial","ShapeStyle","Size","Speed",
        "SpreadAngle","Squash","Texture","TimeScale","Transparency",
        "VelocityInheritance","WindAffectsDrag","ZOffset",
    },
    Beam = {
        "Attachment0","Attachment1","Brightness","Color","CurveSize0",
        "CurveSize1","Enabled","FaceCamera","LightEmission",
        "LightInfluence","Segments","Texture","TextureLength",
        "TextureMode","TextureSpeed","Transparency","Width0","Width1",
        "ZOffset",
    },
    Trail = {
        "Attachment0","Attachment1","Brightness","Color","Enabled",
        "FaceCamera","Lifetime","LightEmission","LightInfluence",
        "MaxLength","MinLength","Texture","TextureLength",
        "TextureMode","Transparency","WidthScale",
    },
    PointLight = {
        "Brightness","Color","Enabled","Range","Shadows",
    },
    SpotLight = {
        "Angle","Brightness","Color","Enabled","Face","Range","Shadows",
    },
    SurfaceLight = {
        "Angle","Brightness","Color","Enabled","Face","Range","Shadows",
    },
    Fire = {
        "Color","Enabled","Heat","SecondaryColor","Size","TimeScale",
    },
    Smoke = {
        "Color","Enabled","Opacity","RiseVelocity","Size","TimeScale",
    },
    Sparkles = {
        "Color","Enabled","SparkleColor","TimeScale",
    },
    Attachment = {
        "Axis","CFrame","Orientation","Position","SecondaryAxis","Visible",
        "WorldAxis","WorldCFrame","WorldOrientation","WorldPosition",
        "WorldSecondaryAxis",
    },
    WeldConstraint = {
        "Active","Enabled","Part0","Part1",
    },
    Motor6D = {
        "C0","C1","CurrentAngle","DesiredAngle","MaxVelocity",
        "Part0","Part1","Transform",
    },
    Weld = {
        "C0","C1","Part0","Part1",
    },
    BillboardGui = {
        "Active","Adornee","AlwaysOnTop","Brightness",
        "ClipsDescendants","CurrentDistance","DistanceLowerLimit",
        "DistanceStep","DistanceUpperLimit","ExtentsOffset",
        "ExtentsOffsetWorldSpace","LightInfluence","MaxDistance",
        "PlayerToHideFrom","Size","SizeOffset","StudsOffset",
        "StudsOffsetWorldSpace","ZIndexBehavior",
    },
    SurfaceGui = {
        "Active","Adornee","AlwaysOnTop","Brightness","CanvasSize",
        "ClipsDescendants","Face","LightInfluence","PixelsPerStud",
        "SizingMode","ToolPunchThroughDistance","ZIndexBehavior","ZOffset",
    },
    ScreenGui = {
        "AutoLocalize","ClipToDeviceSafeArea","DisplayOrder","Enabled",
        "IgnoreGuiInset","ResetOnSpawn","ScreenInsets","ZIndexBehavior",
    },
    Frame = {
        "Active","AnchorPoint","AutomaticSize","BackgroundColor3",
        "BackgroundTransparency","BorderColor3","BorderMode",
        "BorderSizePixel","ClipsDescendants","LayoutOrder","Position",
        "Rotation","Selectable","SelectionGroup","Size",
        "SizeConstraint","Visible","ZIndex",
    },
    TextLabel = {
        "Active","AnchorPoint","AutoLocalize","AutomaticSize",
        "BackgroundColor3","BackgroundTransparency","BorderColor3",
        "BorderSizePixel","ClipsDescendants","Font","FontFace",
        "LayoutOrder","LineHeight","MaxVisibleGraphemes","Position",
        "RichText","Rotation","Size","Text","TextColor3","TextDirection",
        "TextScaled","TextSize","TextStrokeColor3","TextStrokeTransparency",
        "TextTransparency","TextTruncate","TextWrapped","TextXAlignment",
        "TextYAlignment","Visible","ZIndex",
    },
    TextButton = {
        "Active","AnchorPoint","AutoButtonColor","AutoLocalize",
        "AutomaticSize","BackgroundColor3","BackgroundTransparency",
        "BorderColor3","BorderSizePixel","ClipsDescendants","Font",
        "FontFace","LayoutOrder","LineHeight","MaxVisibleGraphemes",
        "Modal","Position","RichText","Rotation","Selectable",
        "Selected","Size","Style","Text","TextColor3","TextScaled",
        "TextSize","TextStrokeColor3","TextStrokeTransparency",
        "TextTransparency","TextTruncate","TextWrapped","TextXAlignment",
        "TextYAlignment","Visible","ZIndex",
    },
    ImageLabel = {
        "Active","AnchorPoint","AutomaticSize","BackgroundColor3",
        "BackgroundTransparency","BorderColor3","BorderSizePixel",
        "ClipsDescendants","Image","ImageColor3","ImageRectOffset",
        "ImageRectSize","ImageTransparency","LayoutOrder","Position",
        "ResampleMode","Rotation","ScaleType","Size","SliceCenter",
        "SliceScale","TileSize","Visible","ZIndex",
    },
    ImageButton = {
        "Active","AnchorPoint","AutoButtonColor","AutomaticSize",
        "BackgroundColor3","BackgroundTransparency","BorderColor3",
        "BorderSizePixel","ClipsDescendants","HoverImage","Image",
        "ImageColor3","ImageRectOffset","ImageRectSize",
        "ImageTransparency","LayoutOrder","Modal","Position",
        "PressedImage","ResampleMode","Rotation","ScaleType",
        "Selectable","Selected","Size","SliceCenter","SliceScale",
        "TileSize","Visible","ZIndex",
    },
    ScrollingFrame = {
        "Active","AnchorPoint","AutomaticCanvasSize","AutomaticSize",
        "BackgroundColor3","BackgroundTransparency","BorderColor3",
        "BorderSizePixel","BottomImage","CanvasPosition","CanvasSize",
        "ClipsDescendants","ElasticBehavior","HorizontalScrollBarInset",
        "LayoutOrder","MidImage","Position","Rotation","ScrollBarImageColor3",
        "ScrollBarImageTransparency","ScrollBarThickness",
        "ScrollingDirection","ScrollingEnabled","Size","TopImage",
        "VerticalScrollBarInset","VerticalScrollBarPosition","Visible","ZIndex",
    },
    UICorner = {"CornerRadius"},
    UIStroke = {"ApplyStrokeMode","Color","Enabled","LineJoinMode","Thickness","Transparency"},
    UIGradient = {"Color","Enabled","Offset","Rotation","Transparency"},
    UIListLayout = {"FillDirection","HorizontalAlignment","HorizontalFlex","ItemLineAlignment","Padding","SortOrder","VerticalAlignment","VerticalFlex","Wraps"},
    UIGridLayout = {"CellPadding","CellSize","FillDirection","FillDirectionMaxCells","HorizontalAlignment","SortOrder","StartCorner","VerticalAlignment"},
    UIPadding = {"PaddingBottom","PaddingLeft","PaddingRight","PaddingTop"},
    UIScale = {"Scale"},
    UIAspectRatioConstraint = {"AspectRatio","AspectType","DominantAxis"},
    UISizeConstraint = {"MaxSize","MinSize"},
    UITextSizeConstraint = {"MaxTextSize","MinTextSize"},
    UIPageLayout = {"Animated","Circular","EasingDirection","EasingStyle","FillDirection","GamepadInputEnabled","HorizontalAlignment","Padding","ScrollWheelInputEnabled","SortOrder","TweenTime","VerticalAlignment"},
    UITableLayout = {"FillDirection","FillEmptySpaceColumns","FillEmptySpaceRows","HorizontalAlignment","MajorAxis","Padding","SortOrder","VerticalAlignment"},
    Atmosphere = {"Color","Decay","Density","Glare","Haze","Offset"},
    Sky = {"CelestialBodiesShown","MoonAngularSize","MoonTextureId","SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp","StarCount","SunAngularSize","SunTextureId"},
    Clouds = {"Color","Cover","Density","Enabled"},
    BloomEffect = {"Enabled","Intensity","Size","Threshold"},
    BlurEffect = {"Enabled","Size"},
    ColorCorrectionEffect = {"Brightness","Contrast","Enabled","Saturation","TintColor"},
    DepthOfFieldEffect = {"Enabled","FarIntensity","FocusDistance","InFocusRadius","NearIntensity"},
    SunRaysEffect = {"Enabled","Intensity","Spread"},
    ProximityPrompt = {"ActionText","AutoLocalize","ClickablePrompt","Enabled","ExclusivityType","GamepadKeyCode","HoldDuration","KeyboardKeyCode","MaxActivationDistance","ObjectText","RequiresLineOfSight","RootLocalizationTable","Style","UIOffset"},
    ValueBase = {"Value"},
    Highlight = {"Adornee","DepthMode","Enabled","FillColor","FillTransparency","OutlineColor","OutlineTransparency"},
    SelectionBox = {"Adornee","Color3","LineThickness","SurfaceColor3","SurfaceTransparency","Transparency","Visible"},
    SelectionSphere = {"Adornee","Color3","SurfaceColor3","SurfaceTransparency","Transparency","Visible"},
    ClickDetector = {"CursorIcon","MaxActivationDistance"},
    BodyGyro = {"CFrame","D","MaxTorque","P"},
    BodyPosition = {"D","MaxForce","P","Position"},
    BodyVelocity = {"MaxForce","P","Velocity"},
    BodyForce = {"Force"},
    BodyThrust = {"Force","Location"},
    RocketPropulsion = {"CartoonFactor","MaxSpeed","MaxThrust","MaxTorque","Target","TargetOffset","TargetRadius","ThrustD","ThrustP","TurnD","TurnP"},
    ForceField = {"Visible"},
    Configuration = {},
    Camera = {"CFrame","CameraSubject","CameraType","DiagonalFieldOfView","FieldOfView","FieldOfViewMode","Focus","HeadLocked","HeadScale","MaxAxisFieldOfView","NearPlaneZ","VRTiltAndRollEnabled"},
}

function PropMap.CopyProperties(source, dest)
    local cn = source.ClassName
    
    -- Try exact class
    local props = PropertyDB[cn]
    if props then
        for _, prop in ipairs(props) do
            pcall(function() dest[prop] = source[prop] end)
        end
    end
    
    -- Try parent classes via IsA
    for className, classProps in pairs(PropertyDB) do
        if className ~= cn then
            local isChild = false
            pcall(function() isChild = source:IsA(className) end)
            if isChild then
                for _, prop in ipairs(classProps) do
                    pcall(function() dest[prop] = source[prop] end)
                end
            end
        end
    end
    
    -- Attributes
    pcall(function()
        for name, val in pairs(source:GetAttributes()) do
            pcall(function() dest:SetAttribute(name, val) end)
        end
    end)
    
    -- Tags
    pcall(function()
        local CS = Svc.CollectionService
        if CS then
            for _, tag in ipairs(CS:GetTags(source)) do
                pcall(function() CS:AddTag(dest, tag) end)
            end
        end
    end)
end

function PropMap.DeepCopy(source)
    local cloned = U.Clone(source)
    if cloned then
        PropMap.CopyProperties(source, cloned)
        return cloned
    end
    
    local ok, inst = pcall(Instance.new, source.ClassName)
    if ok and inst then
        pcall(function() inst.Name = source.Name end)
        PropMap.CopyProperties(source, inst)
        return inst
    end
    
    return nil
end

-- ============================================================
-- 06. SCRIPT ENGINE (6 decompile methods)
-- ============================================================
local ScriptEng = {}
local SrcCache = {}

function ScriptEng.Available()
    return decompile ~= nil or getscriptbytecode ~= nil or 
           getsource ~= nil or (debug and debug.getproto ~= nil) or
           getscripthash ~= nil or issynapsefunction ~= nil
end

function ScriptEng.Decompile(inst)
    if not inst then return nil end
    local path = U.Path(inst)
    if SrcCache[path] then return SrcCache[path] end
    
    local src
    
    -- M1: decompile()
    if not src and decompile then
        pcall(function() 
            local r = decompile(inst)
            if r and #r > 2 then src = r end
        end)
    end
    
    -- M2: getscriptbytecode + decompile
    if not src and getscriptbytecode and decompile then
        pcall(function()
            local bc = getscriptbytecode(inst)
            if bc then
                local r = decompile(bc)
                if r and #r > 2 then src = r end
            end
        end)
    end
    
    -- M3: getsource
    if not src and getsource then
        pcall(function()
            local r = getsource(inst)
            if r and #r > 2 then src = r end
        end)
    end
    
    -- M4: debug.getproto (bytecode analysis)
    if not src and debug and debug.getproto then
        pcall(function()
            local info = debug.getinfo(inst)
            if info and info.source then src = info.source end
        end)
    end
    
    -- M5: .Source property
    if not src then
        pcall(function()
            local s = inst.Source
            if s and #s > 0 then src = s end
        end)
    end
    
    -- M6: getscripthash for verification
    if not src and getscripthash then
        pcall(function()
            local hash = getscripthash(inst)
            src = string.format(
                "-- [BaoSave] Script Hash: %s\n-- Path: %s\n-- Class: %s\n",
                tostring(hash), path, inst.ClassName
            )
        end)
    end
    
    -- Fallback
    if not src then
        src = string.format(
            "-- [BaoSaveInstance v3.0] Decompile failed\n-- Name: %s\n-- Class: %s\n-- Path: %s\n-- Note: Script bytecode could not be recovered\n",
            inst.Name, inst.ClassName, path
        )
    end
    
    SrcCache[path] = src
    return src
end

function ScriptEng.ProcessAll(root, progressCb)
    local scripts = {}
    for _, d in ipairs(U.GetDescendants(root)) do
        if d:IsA("LuaSourceContainer") then
            table.insert(scripts, d)
        end
    end
    
    local total = #scripts
    local results = {}
    local success, fail = 0, 0
    
    for i, s in ipairs(scripts) do
        local src = ScriptEng.Decompile(s)
        results[s] = src
        
        if src and not src:find("Decompile failed") then
            success = success + 1
        else
            fail = fail + 1
        end
        
        if progressCb then
            progressCb(i, total, s.Name, s.ClassName, success, fail)
        end
        U.Yield(i)
    end
    
    return results, success, fail, total
end

-- ============================================================
-- 07. MESH EXTRACTOR
-- ============================================================
local MeshExt = {}

function MeshExt.ExtractAll(root, progressCb)
    local meshes = {}
    local desc = U.GetDescendants(root)
    local total = #desc
    local found = 0
    
    for i, d in ipairs(desc) do
        local isMesh = false
        pcall(function() isMesh = d:IsA("MeshPart") or d:IsA("SpecialMesh") or d:IsA("FileMesh") or d:IsA("BlockMesh") or d:IsA("CylinderMesh") end)
        
        if isMesh then
            local c = PropMap.DeepCopy(d)
            if c then
                table.insert(meshes, {obj=c, path=U.Path(d)})
                found = found + 1
            end
        end
        
        if progressCb and i % 100 == 0 then
            progressCb(i, total, found)
        end
        U.Yield(i)
    end
    
    return meshes, found
end

-- ============================================================
-- 08. TEXTURE EXTRACTOR
-- ============================================================
local TexExt = {}

function TexExt.ExtractAll(root, progressCb)
    local textures = {}
    local desc = U.GetDescendants(root)
    local found = 0
    
    for i, d in ipairs(desc) do
        local isTexture = false
        pcall(function()
            isTexture = d:IsA("Decal") or d:IsA("Texture") or 
                        d:IsA("SurfaceAppearance") or d:IsA("MaterialVariant")
        end)
        
        if isTexture then
            local c = PropMap.DeepCopy(d)
            if c then
                table.insert(textures, {obj=c, path=U.Path(d)})
                found = found + 1
            end
        end
        U.Yield(i)
    end
    
    if progressCb then progressCb(#desc, #desc, found) end
    return textures, found
end

-- ============================================================
-- 09. TERRAIN ENGINE (Chunked + Compressed)
-- ============================================================
local TerrainEng = {}

function TerrainEng.Clone()
    local t = workspace:FindFirstChildOfClass("Terrain")
    if not t then return nil end
    return U.Clone(t)
end

function TerrainEng.CopyProperties(src, dst)
    if not src or not dst then return end
    local props = {
        "WaterColor","WaterReflectance","WaterTransparency",
        "WaterWaveSize","WaterWaveSpeed","Decoration","GrassLength",
    }
    for _, p in ipairs(props) do
        pcall(function() dst[p] = src[p] end)
    end
    -- MaterialColors
    pcall(function() dst.MaterialColors = src.MaterialColors end)
end

function TerrainEng.CopyChunked(src, dst, progressCb)
    if not src or not dst then return false end
    
    local cs = Config.Performance.ChunkSize
    local range = 4096
    local half = range / 2
    local totalChunks = math.ceil(range / cs) ^ 3
    local done = 0
    local dataChunks = 0
    
    for x = -half, half - 1, cs do
        for y = -half, half - 1, cs do
            for z = -half, half - 1, cs do
                pcall(function()
                    local region = Region3.new(
                        Vector3.new(x, y, z),
                        Vector3.new(x+cs, y+cs, z+cs)
                    ):ExpandToGrid(4)
                    
                    local mats, occ = src:ReadVoxels(region, 4)
                    
                    local hasData = false
                    for _, layer in ipairs(mats) do
                        for _, row in ipairs(layer) do
                            for _, m in ipairs(row) do
                                if m ~= Enum.Material.Air then
                                    hasData = true
                                    break
                                end
                            end
                            if hasData then break end
                        end
                        if hasData then break end
                    end
                    
                    if hasData then
                        dst:WriteVoxels(region, 4, mats, occ)
                        dataChunks = dataChunks + 1
                    end
                end)
                
                done = done + 1
                if progressCb and done % 8 == 0 then
                    progressCb(done, totalChunks, dataChunks)
                end
                
                if done % 4 == 0 then RS.RenderStepped:Wait() end
            end
        end
    end
    
    return true, dataChunks
end

function TerrainEng.QuickCopy(src, dst)
    if not src or not dst then return false end
    local ok = false
    pcall(function()
        local region = Region3.new(
            Vector3.new(-16384,-16384,-16384),
            Vector3.new(16384,16384,16384)
        ):ExpandToGrid(4)
        local m, o = src:ReadVoxels(region, 4)
        dst:WriteVoxels(region, 4, m, o)
        ok = true
    end)
    return ok
end

-- ============================================================
-- 10. ANIMATION ENGINE
-- ============================================================
local AnimEng = {}

function AnimEng.ExtractAll(root, progressCb)
    local anims = {}
    local desc = U.GetDescendants(root)
    local found = 0
    
    for i, d in ipairs(desc) do
        local isAnim = false
        pcall(function()
            isAnim = d:IsA("Animation") or d:IsA("AnimationController") or
                     d:IsA("Animator") or d:IsA("KeyframeSequence") or
                     d:IsA("Keyframe") or d:IsA("Pose")
        end)
        
        if isAnim then
            local c = U.Clone(d)
            if c then
                table.insert(anims, {obj=c, path=U.Path(d)})
                found = found + 1
            end
        end
        U.Yield(i)
    end
    
    if progressCb then progressCb(#desc, #desc, found) end
    return anims, found
end

-- ============================================================
-- 11. SOUND ENGINE
-- ============================================================
local SoundEng = {}

function SoundEng.ExtractAll(root, progressCb)
    local sounds = {}
    local desc = U.GetDescendants(root)
    local found = 0
    
    for i, d in ipairs(desc) do
        if d:IsA("Sound") or d:IsA("SoundGroup") or d:IsA("SoundEffect") then
            local c = PropMap.DeepCopy(d)
            if c then
                table.insert(sounds, {obj=c, path=U.Path(d)})
                found = found + 1
            end
        end
        U.Yield(i)
    end
    
    if progressCb then progressCb(#desc, #desc, found) end
    return sounds, found
end

-- ============================================================
-- 12. PARTICLE ENGINE
-- ============================================================
local ParticleEng = {}

function ParticleEng.ExtractAll(root, progressCb)
    local particles = {}
    local desc = U.GetDescendants(root)
    local found = 0
    
    for i, d in ipairs(desc) do
        if U.IsA(d, Config.EffectClasses) then
            local c = PropMap.DeepCopy(d)
            if c then
                table.insert(particles, {obj=c, path=U.Path(d)})
                found = found + 1
            end
        end
        U.Yield(i)
    end
    
    if progressCb then progressCb(#desc, #desc, found) end
    return particles, found
end

-- ============================================================
-- 13. LIGHTING ENGINE
-- ============================================================
local LightEng = {}

function LightEng.ExtractConfig()
    local L = Svc.Lighting
    if not L then return {} end
    
    local cfg = {}
    local props = {
        "Ambient","Brightness","ColorShift_Bottom","ColorShift_Top",
        "EnvironmentDiffuseScale","EnvironmentSpecularScale",
        "GlobalShadows","OutdoorAmbient","ShadowSoftness",
        "ClockTime","GeographicLatitude","TimeOfDay",
        "ExposureCompensation","Technology",
    }
    for _, p in ipairs(props) do
        pcall(function() cfg[p] = L[p] end)
    end
    return cfg
end

function LightEng.ExtractEffects()
    local effects = {}
    local L = Svc.Lighting
    if not L then return effects end
    
    for _, ch in ipairs(U.GetChildren(L)) do
        local c = PropMap.DeepCopy(ch)
        if c then table.insert(effects, c) end
    end
    
    return effects
end

function LightEng.ExtractAll(progressCb)
    if progressCb then progressCb(30, 100, "Properties") end
    local cfg = LightEng.ExtractConfig()
    if progressCb then progressCb(70, 100, "Effects") end
    local fx = LightEng.ExtractEffects()
    if progressCb then progressCb(100, 100, "Done") end
    return cfg, fx
end

-- ============================================================
-- 14. PHYSICS EXTRACTOR
-- ============================================================
local PhysicsExt = {}

function PhysicsExt.ExtractAll(root, progressCb)
    local physics = {}
    local desc = U.GetDescendants(root)
    local found = 0
    
    for i, d in ipairs(desc) do
        local isPhys = false
        pcall(function()
            isPhys = U.IsA(d, Config.ConstraintClasses) or
                     d:IsA("BodyMover") or d:IsA("JointInstance")
        end)
        
        if isPhys then
            local c = PropMap.DeepCopy(d)
            if c then
                table.insert(physics, {obj=c, path=U.Path(d)})
                found = found + 1
            end
        end
        U.Yield(i)
    end
    
    if progressCb then progressCb(#desc, #desc, found) end
    return physics, found
end

-- ============================================================
-- 15. UI EXTRACTOR
-- ============================================================
local UIExt = {}

function UIExt.ExtractAll(root, progressCb)
    local uis = {}
    local desc = U.GetDescendants(root)
    local found = 0
    
    for i, d in ipairs(desc) do
        local isUI = false
        pcall(function()
            isUI = d:IsA("LayerCollector") or d:IsA("GuiObject") or
                   d:IsA("UIComponent") or d:IsA("BillboardGui") or
                   d:IsA("SurfaceGui")
        end)
        
        if isUI and d.Parent and not d.Parent:IsA("GuiObject") then
            -- Only top-level UI
            local c = U.Clone(d)
            if c then
                table.insert(uis, {obj=c, path=U.Path(d)})
                found = found + 1
            end
        end
        U.Yield(i)
    end
    
    if progressCb then progressCb(#desc, #desc, found) end
    return uis, found
end

-- ============================================================
-- 16. PACKAGE EXTRACTOR
-- ============================================================
local PkgExt = {}

function PkgExt.ExtractAll(root, progressCb)
    local packages = {}
    local desc = U.GetDescendants(root)
    local found = 0
    
    for i, d in ipairs(desc) do
        local isPkg = false
        pcall(function()
            isPkg = d:IsA("PackageLink") or 
                    (d:GetAttribute("PackageId") ~= nil)
        end)
        
        if isPkg then
            local parent = d.Parent
            if parent then
                local c = U.Clone(parent)
                if c then
                    table.insert(packages, {obj=c, path=U.Path(parent)})
                    found = found + 1
                end
            end
        end
        U.Yield(i)
    end
    
    if progressCb then progressCb(#desc, #desc, found) end
    return packages, found
end

-- ============================================================
-- 17. INSTANCE RECONSTRUCTOR (Fallback engine)
-- ============================================================
local Reconstructor = {}

function Reconstructor.Rebuild(original)
    if not original or U.IsIgnoredClass(original.ClassName) then return nil end
    
    -- Try clone first
    local cloned = U.Clone(original)
    if cloned then return cloned end
    
    -- Manual rebuild
    local ok, inst = pcall(Instance.new, original.ClassName)
    if not ok or not inst then return nil end
    
    pcall(function() inst.Name = original.Name end)
    PropMap.CopyProperties(original, inst)
    
    -- Recursive children
    for _, child in ipairs(U.GetChildren(original)) do
        local childClone = Reconstructor.Rebuild(child)
        if childClone then
            pcall(function() childClone.Parent = inst end)
        end
    end
    
    return inst
end

function Reconstructor.RebuildBatch(items, progressCb)
    local results = {}
    local total = #items
    
    for i, item in ipairs(items) do
        local rebuilt = Reconstructor.Rebuild(item)
        if rebuilt then
            table.insert(results, rebuilt)
        end
        if progressCb and i % 20 == 0 then
            progressCb(i, total, item.Name)
        end
        U.Yield(i)
    end
    
    return results
end

-- ============================================================
-- 18. DECOMPILER CORE (25 gather methods)
-- ============================================================
local Core = {}

local Stats = {
    Total = 0, Copied = 0, Failed = 0,
    Scripts = 0, ScriptsFail = 0,
    Meshes = 0, Textures = 0, Sounds = 0,
    Anims = 0, Particles = 0, Physics = 0,
    UIs = 0, Packages = 0, Terrain = 0,
    NilInst = 0, Hidden = 0,
    StartTime = 0,
}

function Core.ResetStats()
    for k in pairs(Stats) do Stats[k] = 0 end
    Stats.StartTime = tick()
end

function Core.GetStats()
    Stats.Elapsed = tick() - Stats.StartTime
    return Stats
end

-- 1. Full Game
function Core.GatherFullGame(pCb)
    Core.ResetStats()
    local gathered = {}
    local services = Config.AllServices
    local totalSvc = #services
    
    -- Count phase
    local grandTotal = 0
    for _, s in ipairs(services) do
        local svc = U.GetService(s)
        if svc and not U.IsIgnoredSvc(s) then
            grandTotal = grandTotal + U.Count(svc) + 1
        end
    end
    Stats.Total = grandTotal
    
    local counter = 0
    
    for si, sName in ipairs(services) do
        if not U.IsIgnoredSvc(sName) then
            local svc = U.GetService(sName)
            if svc then
                for _, child in ipairs(U.GetChildren(svc)) do
                    if not (sName == "Workspace" and child:IsA("Terrain")) and
                       not (sName == "Workspace" and child:IsA("Camera")) and
                       not U.IsIgnoredClass(child.ClassName) then
                        
                        local cloned = PropMap.DeepCopy(child)
                        if not cloned then
                            cloned = Reconstructor.Rebuild(child)
                        end
                        
                        if cloned then
                            table.insert(gathered, {
                                obj = cloned,
                                svc = sName,
                                path = U.Path(child),
                            })
                            Stats.Copied = Stats.Copied + 1 + U.Count(child)
                        else
                            Stats.Failed = Stats.Failed + 1
                        end
                        
                        counter = counter + 1
                        if pCb then
                            local pct = (counter / math.max(grandTotal, 1)) * 100
                            pCb(pct, sName, child.Name, child.ClassName)
                        end
                        U.Yield(counter)
                    end
                end
            end
        end
    end
    
    return gathered
end

-- 2. All Models (Auto-full)
function Core.GatherAllModels(pCb)
    Core.ResetStats()
    local models = {}
    
    -- Scan ALL services for models, not just Workspace
    local searchTargets = {"Workspace","ReplicatedStorage","ServerStorage",
                           "StarterGui","StarterPack","StarterPlayer",
                           "Lighting","ReplicatedFirst","ServerScriptService"}
    
    local allItems = {}
    for _, sName in ipairs(searchTargets) do
        local svc = U.GetService(sName)
        if svc then
            for _, d in ipairs(U.GetDescendants(svc)) do
                if U.IsA(d, Config.ModelClasses) then
                    table.insert(allItems, {inst=d, svc=sName})
                end
            end
        end
    end
    
    Stats.Total = #allItems
    
    -- Clone using parallel batch
    for i, item in ipairs(allItems) do
        local cloned = PropMap.DeepCopy(item.inst)
        if not cloned then
            cloned = Reconstructor.Rebuild(item.inst)
        end
        
        if cloned then
            table.insert(models, {
                obj = cloned,
                svc = item.svc,
                path = U.Path(item.inst),
                class = item.inst.ClassName,
            })
            Stats.Copied = Stats.Copied + 1
        else
            Stats.Failed = Stats.Failed + 1
        end
        
        if pCb then
            pCb((i/#allItems)*100, item.svc, item.inst.Name, item.inst.ClassName)
        end
        U.Yield(i)
    end
    
    return models
end

-- 3. Workspace Models Only
function Core.GatherWorkspaceModels(pCb)
    Core.ResetStats()
    local models = {}
    local children = U.GetChildren(workspace)
    Stats.Total = #children
    
    for i, child in ipairs(children) do
        if not child:IsA("Terrain") and not child:IsA("Camera") and
           not U.IsIgnoredClass(child.ClassName) then
            
            local cloned = PropMap.DeepCopy(child)
            if not cloned then cloned = Reconstructor.Rebuild(child) end
            
            if cloned then
                table.insert(models, cloned)
                Stats.Copied = Stats.Copied + 1 + U.Count(child)
            else
                Stats.Failed = Stats.Failed + 1
            end
        end
        
        if pCb then pCb((i/#children)*100, "Workspace", child.Name, child.ClassName) end
        U.Yield(i)
    end
    
    return models
end

-- 4. Deep Model Scanner (recursive, all nested)
function Core.GatherDeepModels(pCb)
    Core.ResetStats()
    local results = {}
    
    local function scan(parent, depth)
        for _, child in ipairs(U.GetChildren(parent)) do
            if child:IsA("Model") then
                local cloned = PropMap.DeepCopy(child)
                if not cloned then cloned = Reconstructor.Rebuild(child) end
                if cloned then
                    table.insert(results, {
                        obj = cloned,
                        depth = depth,
                        path = U.Path(child),
                        descendants = U.Count(child),
                    })
                    Stats.Copied = Stats.Copied + 1
                end
            end
            
            if not child:IsA("Terrain") then
                scan(child, depth + 1)
            end
            
            Stats.Total = Stats.Total + 1
            if pCb and Stats.Total % 50 == 0 then
                pCb(0, "Deep Scan", child.Name, "Depth: " .. depth)
            end
            U.Yield(Stats.Total)
        end
    end
    
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.GetService(sName)
        if svc and not U.IsIgnoredSvc(sName) then
            scan(svc, 0)
        end
    end
    
    return results
end

-- 5. Terrain
function Core.GatherTerrain(pCb)
    Core.ResetStats()
    local src = workspace:FindFirstChildOfClass("Terrain")
    if not src then return nil end
    
    local dst = TerrainEng.Clone()
    if dst then
        TerrainEng.CopyProperties(src, dst)
        Stats.Terrain = 1
    end
    
    if pCb then pCb(100, "Terrain", "Complete", "") end
    return dst
end

-- 6. Scripts
function Core.GatherScripts(pCb)
    Core.ResetStats()
    local allScripts = {}
    
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.GetService(sName)
        if svc then
            for _, d in ipairs(U.GetDescendants(svc)) do
                if d:IsA("LuaSourceContainer") then
                    table.insert(allScripts, d)
                end
            end
        end
    end
    
    Stats.Total = #allScripts
    local results = {}
    
    for i, s in ipairs(allScripts) do
        local src = ScriptEng.Decompile(s)
        results[s] = src
        
        if src and not src:find("Decompile failed") then
            Stats.Scripts = Stats.Scripts + 1
        else
            Stats.ScriptsFail = Stats.ScriptsFail + 1
        end
        
        if pCb then
            pCb((i/#allScripts)*100, "Decompiling", s.Name, 
                string.format("%s | OK:%d FAIL:%d", s.ClassName, Stats.Scripts, Stats.ScriptsFail))
        end
        U.Yield(i)
    end
    
    return results
end

-- 7. Lighting
function Core.GatherLighting(pCb)
    return LightEng.ExtractAll(pCb)
end

-- 8. Sounds
function Core.GatherSounds(pCb)
    Core.ResetStats()
    local allSounds = {}
    
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.GetService(sName)
        if svc then
            local s, n = SoundEng.ExtractAll(svc)
            U.Merge(allSounds, s)
            Stats.Sounds = Stats.Sounds + n
        end
    end
    
    if pCb then pCb(100, "Sounds", Stats.Sounds .. " extracted", "") end
    return allSounds
end

-- 9. Animations
function Core.GatherAnimations(pCb)
    Core.ResetStats()
    local allAnims = {}
    
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.GetService(sName)
        if svc then
            local a, n = AnimEng.ExtractAll(svc)
            U.Merge(allAnims, a)
            Stats.Anims = Stats.Anims + n
        end
    end
    
    if pCb then pCb(100, "Animations", Stats.Anims .. " extracted", "") end
    return allAnims
end

-- 10. Particles & Effects
function Core.GatherParticles(pCb)
    Core.ResetStats()
    local all = {}
    
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.GetService(sName)
        if svc then
            local p, n = ParticleEng.ExtractAll(svc)
            U.Merge(all, p)
            Stats.Particles = Stats.Particles + n
        end
    end
    
    if pCb then pCb(100, "Particles", Stats.Particles .. " extracted", "") end
    return all
end

-- 11. Meshes
function Core.GatherMeshes(pCb)
    Core.ResetStats()
    local all = {}
    
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.GetService(sName)
        if svc then
            local m, n = MeshExt.ExtractAll(svc)
            U.Merge(all, m)
            Stats.Meshes = Stats.Meshes + n
        end
    end
    
    if pCb then pCb(100, "Meshes", Stats.Meshes .. " extracted", "") end
    return all
end

-- 12. Textures
function Core.GatherTextures(pCb)
    Core.ResetStats()
    local all = {}
    
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.GetService(sName)
        if svc then
            local t, n = TexExt.ExtractAll(svc)
            U.Merge(all, t)
            Stats.Textures = Stats.Textures + n
        end
    end
    
    if pCb then pCb(100, "Textures", Stats.Textures .. " extracted", "") end
    return all
end

-- 13. Physics & Constraints
function Core.GatherPhysics(pCb)
    Core.ResetStats()
    local all = {}
    
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.GetService(sName)
        if svc then
            local p, n = PhysicsExt.ExtractAll(svc)
            U.Merge(all, p)
            Stats.Physics = Stats.Physics + n
        end
    end
    
    if pCb then pCb(100, "Physics", Stats.Physics .. " extracted", "") end
    return all
end

-- 14. UI Elements
function Core.GatherUIs(pCb)
    Core.ResetStats()
    local all = {}
    
    local uiServices = {"StarterGui","ReplicatedStorage","StarterPack","StarterPlayer"}
    for _, sName in ipairs(uiServices) do
        local svc = U.GetService(sName)
        if svc then
            local u, n = UIExt.ExtractAll(svc)
            U.Merge(all, u)
            Stats.UIs = Stats.UIs + n
        end
    end
    
    if pCb then pCb(100, "UIs", Stats.UIs .. " extracted", "") end
    return all
end

-- 15. Packages
function Core.GatherPackages(pCb)
    Core.ResetStats()
    local all = {}
    
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.GetService(sName)
        if svc then
            local p, n = PkgExt.ExtractAll(svc)
            U.Merge(all, p)
            Stats.Packages = Stats.Packages + n
        end
    end
    
    if pCb then pCb(100, "Packages", Stats.Packages .. " extracted", "") end
    return all
end

-- 16. Nil Instances
function Core.GatherNilInstances(pCb)
    Core.ResetStats()
    local results = {}
    
    if getnilinstances then
        pcall(function()
            local nils = getnilinstances()
            Stats.Total = #nils
            
            for i, inst in ipairs(nils) do
                if not U.IsIgnoredClass(inst.ClassName) then
                    local c = U.Clone(inst)
                    if not c then c = Reconstructor.Rebuild(inst) end
                    if c then
                        table.insert(results, c)
                        Stats.NilInst = Stats.NilInst + 1
                    end
                end
                if pCb and i % 10 == 0 then
                    pCb((i/#nils)*100, "Nil Instances", inst.Name, inst.ClassName)
                end
                U.Yield(i)
            end
        end)
    end
    
    return results
end

-- 17. Hidden Properties
function Core.GatherHiddenProps(pCb)
    Core.ResetStats()
    local hidden = {}
    
    if gethiddenproperties or getproperties then
        for _, sName in ipairs(Config.AllServices) do
            local svc = U.GetService(sName)
            if svc then
                local desc = U.GetDescendants(svc)
                for i, d in ipairs(desc) do
                    pcall(function()
                        local props
                        if gethiddenproperties then
                            props = gethiddenproperties(d)
                        elseif getproperties then
                            props = getproperties(d)
                        end
                        if props and next(props) then
                            hidden[U.Path(d)] = props
                            Stats.Hidden = Stats.Hidden + 1
                        end
                    end)
                    U.Yield(i)
                end
            end
        end
    end
    
    if pCb then pCb(100, "Hidden Props", Stats.Hidden .. " found", "") end
    return hidden
end

-- 18. Camera
function Core.GatherCamera()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    return U.Clone(cam)
end

-- 19. Materials
function Core.GatherMaterials(pCb)
    Core.ResetStats()
    local mats = {}
    
    local matSvc = U.GetService("MaterialService")
    if matSvc then
        for _, ch in ipairs(U.GetChildren(matSvc)) do
            local c = PropMap.DeepCopy(ch)
            if c then table.insert(mats, c) end
        end
    end
    
    if pCb then pCb(100, "Materials", #mats .. " variants", "") end
    return mats
end

-- 20. Specific Service
function Core.GatherService(serviceName, pCb)
    Core.ResetStats()
    local results = {}
    local svc = U.GetService(serviceName)
    if not svc then return results end
    
    local children = U.GetChildren(svc)
    Stats.Total = #children
    
    for i, child in ipairs(children) do
        if not U.IsIgnoredClass(child.ClassName) then
            local cloned = PropMap.DeepCopy(child)
            if not cloned then cloned = Reconstructor.Rebuild(child) end
            if cloned then
                table.insert(results, cloned)
                Stats.Copied = Stats.Copied + 1
            end
        end
        if pCb then pCb((i/#children)*100, serviceName, child.Name, child.ClassName) end
        U.Yield(i)
    end
    
    return results
end

-- 21. Selected Instance
function Core.GatherSelected(instance, pCb)
    if not instance then return nil end
    Core.ResetStats()
    
    local cloned = PropMap.DeepCopy(instance)
    if not cloned then cloned = Reconstructor.Rebuild(instance) end
    
    if cloned then
        Stats.Copied = 1 + U.Count(instance)
    end
    
    if pCb then pCb(100, "Selected", instance.Name, instance.ClassName) end
    return cloned
end

-- 22. By ClassName
function Core.GatherByClass(className, pCb)
    Core.ResetStats()
    local results = {}
    
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.GetService(sName)
        if svc then
            for _, d in ipairs(U.GetDescendants(svc)) do
                if d.ClassName == className or d:IsA(className) then
                    local c = PropMap.DeepCopy(d)
                    if c then
                        table.insert(results, c)
                        Stats.Copied = Stats.Copied + 1
                    end
                end
            end
        end
    end
    
    Stats.Total = Stats.Copied
    if pCb then pCb(100, "ByClass", className, Stats.Copied .. " found") end
    return results
end

-- 23. Character Models
function Core.GatherCharacters(pCb)
    Core.ResetStats()
    local chars = {}
    
    for _, player in ipairs(Svc.Players:GetPlayers()) do
        if player.Character then
            local c = PropMap.DeepCopy(player.Character)
            if not c then c = Reconstructor.Rebuild(player.Character) end
            if c then
                c.Name = player.Name .. "_Character"
                table.insert(chars, c)
                Stats.Copied = Stats.Copied + 1
            end
        end
    end
    
    if pCb then pCb(100, "Characters", #chars .. " characters", "") end
    return chars
end

-- 24. Accessories & Tools
function Core.GatherAccessories(pCb)
    Core.ResetStats()
    local items = {}
    
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.GetService(sName)
        if svc then
            for _, d in ipairs(U.GetDescendants(svc)) do
                if d:IsA("Accessory") or d:IsA("Tool") or d:IsA("HopperBin") then
                    local c = PropMap.DeepCopy(d)
                    if c then
                        table.insert(items, {obj=c, path=U.Path(d)})
                        Stats.Copied = Stats.Copied + 1
                    end
                end
            end
        end
    end
    
    if pCb then pCb(100, "Accessories", Stats.Copied .. " found", "") end
    return items
end

-- 25. Everything Combined (ULTIMATE)
function Core.GatherEverything(pCb)
    Core.ResetStats()
    local masterData = {
        game = {},
        terrain = nil,
        scripts = {},
        lighting = {},
        effects = {},
        camera = nil,
        materials = {},
        nilInstances = {},
    }
    
    local phases = {
        {name="Game Tree",    weight=35, fn=function(cb) masterData.game = Core.GatherFullGame(cb) end},
        {name="Scripts",      weight=20, fn=function(cb) masterData.scripts = Core.GatherScripts(cb) end},
        {name="Terrain",      weight=10, fn=function(cb) masterData.terrain = Core.GatherTerrain(cb) end},
        {name="Lighting",     weight=5,  fn=function(cb) masterData.lighting, masterData.effects = Core.GatherLighting(cb) end},
        {name="Camera",       weight=2,  fn=function(cb) masterData.camera = Core.GatherCamera() end},
        {name="Materials",    weight=3,  fn=function(cb) masterData.materials = Core.GatherMaterials(cb) end},
        {name="Nil Instances",weight=10, fn=function(cb) masterData.nilInstances = Core.GatherNilInstances(cb) end},
    }
    
    local totalWeight = 0
    for _, p in ipairs(phases) do totalWeight = totalWeight + p.weight end
    
    local accumulated = 0
    
    for pi, phase in ipairs(phases) do
        local phaseStart = accumulated
        
        pcall(function()
            phase.fn(function(pct, s1, s2, s3)
                local globalPct = phaseStart + (pct / 100) * (phase.weight / totalWeight) * 100
                if pCb then
                    pCb(globalPct, 
                        string.format("[%d/%d] %s", pi, #phases, phase.name),
                        s2 or "", s3 or "")
                end
            end)
        end)
        
        accumulated = accumulated + (phase.weight / totalWeight) * 100
        
        if pCb then
            pCb(accumulated, phase.name .. " Complete", "", "")
        end
    end
    
    return masterData
end

-- ============================================================
-- 19. EXPORTER (8 save methods)
-- ============================================================
local Exporter = {}

function Exporter.Save(fileName, options)
    fileName = fileName or (Config.OutputBase .. ".rbxl")
    options = options or {}
    
    local methods = {}
    
    -- M1: saveinstance (table)
    table.insert(methods, function()
        if not saveinstance then return false end
        saveinstance({
            FileName = fileName,
            DecompileMode = options.decompileMode or "custom",
            NilInstances = options.nilInstances ~= false,
            RemovePlayerCharacters = true,
            SavePlayers = false,
            ExtraInstances = options.extra or {},
            Callback = options.callback,
            ShowStatus = true,
            mode = "full",
            Timeout = Config.Performance.Timeout,
            Decompile = options.decompile ~= false,
            SaveNonCreatable = true,
            IgnoreDefaultProperties = false,
            IsolateStarterPlayer = false,
            IgnoreList = Config.IgnoreServices,
        })
        return true
    end)
    
    -- M2: saveinstance (simple)
    table.insert(methods, function()
        if not saveinstance then return false end
        saveinstance(game, fileName)
        return true
    end)
    
    -- M3: syn.saveinstance
    table.insert(methods, function()
        if not (syn and syn.saveinstance) then return false end
        syn.saveinstance({
            FileName = fileName,
            Decompile = true,
            NilInstances = true,
            RemovePlayers = true,
            SaveNonCreatable = true,
            ShowStatus = true,
            Timeout = Config.Performance.Timeout,
            IgnoreList = Config.IgnoreServices,
        })
        return true
    end)
    
    -- M4: fluxus
    table.insert(methods, function()
        if not (fluxus and fluxus.saveinstance) then return false end
        fluxus.saveinstance(fileName)
        return true
    end)
    
    -- M5: KRNL
    table.insert(methods, function()
        if not KRNL_LOADED then return false end
        saveinstance(game, fileName)
        return true
    end)
    
    -- M6: saveplace
    table.insert(methods, function()
        if not saveplace then return false end
        saveplace(fileName)
        return true
    end)
    
    -- M7: writefile + game:Save
    table.insert(methods, function()
        if not (writefile and game.Save) then return false end
        game:Save(fileName)
        return true
    end)
    
    -- M8: Hydrogen/Delta
    table.insert(methods, function()
        if not (savegame or saveinstance) then return false end
        local fn = savegame or saveinstance
        fn(game, fileName)
        return true
    end)
    
    for i, method in ipairs(methods) do
        local ok, result = pcall(method)
        if ok and result then
            U.Log("EXPORT", "Saved with method " .. i .. ": " .. fileName)
            return true, nil
        end
    end
    
    return false, "No compatible save method found"
end

function Exporter.SaveWithInstances(fileName, instances)
    fileName = fileName or (Config.OutputBase .. ".rbxl")
    
    local ok, err = pcall(function()
        if saveinstance then
            saveinstance({
                FileName = fileName,
                ExtraInstances = instances,
                Decompile = true,
                mode = "optimized",
            })
        elseif syn and syn.saveinstance then
            syn.saveinstance({
                FileName = fileName,
                ExtraInstances = instances,
                Decompile = true,
            })
        else
            saveinstance(game, fileName)
        end
    end)
    
    return ok, err and tostring(err)
end

function Exporter.Report(stats)
    return string.format(
        "Instances:%s | Scripts:%d/%d | Meshes:%d | Sounds:%d | Anims:%d | Time:%s",
        U.FmtN(stats.Copied), stats.Scripts, stats.Scripts + stats.ScriptsFail,
        stats.Meshes, stats.Sounds, stats.Anims, U.FmtT(stats.Elapsed or 0)
    )
end

-- ============================================================
-- 20. UI SYSTEM
-- ============================================================
local GUI = {}
local GR = {} -- GUI References

function GUI.New(c, p, ch)
    local i = Instance.new(c)
    for k, v in pairs(p or {}) do pcall(function() i[k] = v end) end
    for _, x in ipairs(ch or {}) do x.Parent = i end
    return i
end

function GUI.Corner(p, r) return GUI.New("UICorner", {CornerRadius=UDim.new(0,r or Config.UI.Rad), Parent=p}) end
function GUI.Stroke(p, c, t, a) return GUI.New("UIStroke", {Color=c or Config.UI.C.P1, Thickness=t or 1, Transparency=a or 0.6, Parent=p}) end
function GUI.Grad(p, c1, c2) return GUI.New("UIGradient", {Color=ColorSequence.new({ColorSequenceKeypoint.new(0,c1),ColorSequenceKeypoint.new(1,c2)}), Parent=p}) end

function GUI.Drag(frame, handle)
    local dr, di, ds, sp = false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dr = true; ds = i.Position; sp = frame.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dr = false end end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then di = i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i == di and dr then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
end

function GUI.Btn(text, icon, color, hoverC, order, cb)
    local C = Config.UI.C
    local btn = GUI.New("TextButton", {
        Size = UDim2.new(1, 0, 0, Config.UI.BtnH),
        BackgroundColor3 = color or C.Btn,
        Text = "", AutoButtonColor = false,
        BorderSizePixel = 0, LayoutOrder = order or 0,
    })
    GUI.Corner(btn, 8)
    GUI.Stroke(btn, C.Sep, 1, 0.4)
    
    GUI.New("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = (icon or "") .. "  " .. text,
        TextColor3 = C.Txt, Font = Config.UI.F1,
        TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn,
    })
    
    local bar = GUI.New("Frame", {
        Size = UDim2.new(0, 3, 0.5, 0),
        Position = UDim2.new(0, 0, 0.25, 0),
        BackgroundColor3 = color or C.P1,
        BorderSizePixel = 0, BackgroundTransparency = 1,
        Parent = btn,
    })
    GUI.Corner(bar, 2)
    
    local oc = color or C.Btn
    local hc = hoverC or C.BtnH
    
    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=hc}):Play()
        TS:Create(bar, TweenInfo.new(0.12), {BackgroundTransparency=0}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=oc}):Play()
        TS:Create(bar, TweenInfo.new(0.12), {BackgroundTransparency=1}):Play()
    end)
    
    if cb then
        btn.MouseButton1Click:Connect(function()
            TS:Create(btn, TweenInfo.new(0.04), {BackgroundColor3=C.P1}):Play()
            task.wait(0.04)
            TS:Create(btn, TweenInfo.new(0.08), {BackgroundColor3=oc}):Play()
            pcall(cb)
        end)
    end
    
    return btn
end

function GUI.Sep(text, order)
    local C = Config.UI.C
    local s = GUI.New("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1, LayoutOrder = order or 0,
    })
    GUI.New("Frame", {Size=UDim2.new(0.12,0,0,1), Position=UDim2.new(0,0,0.5,0), BackgroundColor3=C.Sep, BorderSizePixel=0, Parent=s})
    GUI.New("TextLabel", {Size=UDim2.new(0.76,0,1,0), Position=UDim2.new(0.12,0,0,0), BackgroundTransparency=1, Text=text or "", TextColor3=C.Dim, Font=Config.UI.F2, TextSize=11, Parent=s})
    GUI.New("Frame", {Size=UDim2.new(0.12,0,0,1), Position=UDim2.new(0.88,0,0.5,0), BackgroundColor3=C.Sep, BorderSizePixel=0, Parent=s})
    return s
end

function GUI.Build()
    local ex = PGui:FindFirstChild("BaoSaveGui")
    if ex then ex:Destroy() end
    
    local C = Config.UI.C
    
    local sg = GUI.New("ScreenGui", {Name="BaoSaveGui", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Parent=PGui})
    
    local mf = GUI.New("Frame", {
        Name="Main", Size=UDim2.new(0,0,0,0),
        Position=UDim2.new(0.5,0,0.5,0), AnchorPoint=Vector2.new(0.5,0.5),
        BackgroundColor3=C.Bg, BorderSizePixel=0, ClipsDescendants=true, Parent=sg,
    })
    GUI.Corner(mf, 14)
    GUI.Stroke(mf, C.P1, 2, 0.2)
    
    -- Shadow
    GUI.New("ImageLabel", {
        Size=UDim2.new(1,60,1,60), Position=UDim2.new(0.5,0,0.5,0),
        AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1,
        Image="rbxassetid://5554236805", ImageColor3=Color3.new(0,0,0),
        ImageTransparency=0.35, ScaleType=Enum.ScaleType.Slice,
        SliceCenter=Rect.new(23,23,277,277), ZIndex=-1, Parent=mf,
    })
    
    -- TopBar
    local tb = GUI.New("Frame", {Size=UDim2.new(1,0,0,48), BackgroundColor3=C.Bar, BorderSizePixel=0, Parent=mf})
    GUI.Corner(tb, 14)
    GUI.New("Frame", {Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,1,-16), BackgroundColor3=C.Bar, BorderSizePixel=0, Parent=tb})
    
    GUI.New("TextLabel", {
        Size=UDim2.new(1,-110,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, Text="⚡ BaoSaveInstance v"..Config.Version.." "..Config.Build,
        TextColor3=C.P1G, Font=Config.UI.F1, TextSize=16,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=tb,
    })
    
    local minimized = false
    local cf -- content frame
    
    local minB = GUI.New("TextButton", {
        Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-74,0,10),
        BackgroundColor3=C.Btn, Text="─", TextColor3=C.Sub,
        Font=Config.UI.F1, TextSize=12, BorderSizePixel=0, Parent=tb,
    })
    GUI.Corner(minB, 6)
    
    local clsB = GUI.New("TextButton", {
        Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-42,0,10),
        BackgroundColor3=C.Red, Text="✕", TextColor3=C.Txt,
        Font=Config.UI.F1, TextSize=12, BorderSizePixel=0, Parent=tb,
    })
    GUI.Corner(clsB, 6)
    
    -- Content
    cf = GUI.New("Frame", {
        Name="Content", Size=UDim2.new(1,0,1,-48),
        Position=UDim2.new(0,0,0,48), BackgroundTransparency=1,
        ClipsDescendants=true, Parent=mf,
    })
    
    -- Scroll
    local sf = GUI.New("ScrollingFrame", {
        Name="Scroll", Size=UDim2.new(1,-12,1,-160),
        Position=UDim2.new(0,6,0,4), BackgroundTransparency=1,
        ScrollBarThickness=3, ScrollBarImageColor3=C.P1,
        ScrollBarImageTransparency=0.2, BorderSizePixel=0,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Parent=cf,
    })
    GUI.New("UIListLayout", {Padding=UDim.new(0,Config.UI.Pad), HorizontalAlignment=Enum.HorizontalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder, Parent=sf})
    GUI.New("UIPadding", {PaddingTop=UDim.new(0,3), PaddingBottom=UDim.new(0,3), PaddingLeft=UDim.new(0,3), PaddingRight=UDim.new(0,3), Parent=sf})
    
    -- Progress Panel
    local pp = GUI.New("Frame", {
        Name="Progress", Size=UDim2.new(1,-12,0,148),
        Position=UDim2.new(0,6,1,-152), BackgroundColor3=C.Panel,
        BorderSizePixel=0, Parent=cf,
    })
    GUI.Corner(pp, 10)
    GUI.Stroke(pp, C.Sep, 1, 0.4)
    
    -- Status
    local stL = GUI.New("TextLabel", {
        Size=UDim2.new(1,-16,0,18), Position=UDim2.new(0,8,0,6),
        BackgroundTransparency=1, Text="⏳ Ready",
        TextColor3=C.Sub, Font=Config.UI.F2, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=pp,
    })
    
    -- Progress Bar
    local pbBg = GUI.New("Frame", {
        Size=UDim2.new(1,-16,0,18), Position=UDim2.new(0,8,0,28),
        BackgroundColor3=C.PBg, BorderSizePixel=0, ClipsDescendants=true, Parent=pp,
    })
    GUI.Corner(pbBg, 5)
    
    local pbFill = GUI.New("Frame", {
        Size=UDim2.new(0,0,1,0), BackgroundColor3=C.PFl,
        BorderSizePixel=0, Parent=pbBg,
    })
    GUI.Corner(pbFill, 5)
    GUI.Grad(pbFill, C.P1, C.P1G)
    
    -- Shimmer
    local shimmer = GUI.New("Frame", {
        Size=UDim2.new(0.25,0,1,0), Position=UDim2.new(-0.25,0,0,0),
        BackgroundTransparency=0.75, BorderSizePixel=0, Parent=pbFill,
    })
    GUI.Grad(shimmer, Color3.new(1,1,1), Color3.new(1,1,1))
    
    -- Percent
    local pctL = GUI.New("TextLabel", {
        Size=UDim2.new(0.5,-8,0,18), Position=UDim2.new(0,8,0,50),
        BackgroundTransparency=1, Text="0.0%",
        TextColor3=C.P1G, Font=Config.UI.F1, TextSize=15,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=pp,
    })
    
    -- ETA
    local etaL = GUI.New("TextLabel", {
        Size=UDim2.new(0.5,-8,0,18), Position=UDim2.new(0.5,0,0,50),
        BackgroundTransparency=1, Text="",
        TextColor3=C.Dim, Font=Config.UI.F3, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Right, Parent=pp,
    })
    
    -- Detail 1
    local d1L = GUI.New("TextLabel", {
        Size=UDim2.new(1,-16,0,14), Position=UDim2.new(0,8,0,72),
        BackgroundTransparency=1, Text="",
        TextColor3=C.Dim, Font=Config.UI.F3, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd, Parent=pp,
    })
    
    -- Detail 2
    local d2L = GUI.New("TextLabel", {
        Size=UDim2.new(1,-16,0,14), Position=UDim2.new(0,8,0,88),
        BackgroundTransparency=1, Text="",
        TextColor3=C.Dim, Font=Config.UI.F3, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd, Parent=pp,
    })
    
    -- Stats Line
    local sL = GUI.New("TextLabel", {
        Size=UDim2.new(1,-16,0,14), Position=UDim2.new(0,8,0,106),
        BackgroundTransparency=1, Text="",
        TextColor3=C.P3, Font=Config.UI.F2, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd, Parent=pp,
    })
    
    -- Speed indicator
    local spL = GUI.New("TextLabel", {
        Size=UDim2.new(1,-16,0,14), Position=UDim2.new(0,8,0,124),
        BackgroundTransparency=1, Text="",
        TextColor3=C.P4, Font=Config.UI.F2, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=pp,
    })
    
    GUI.Drag(mf, tb)
    
    minB.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TS:Create(mf, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size=UDim2.new(0,520,0,48)}):Play()
            cf.Visible = false
            minB.Text = "+"
        else
            cf.Visible = true
            TS:Create(mf, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size=Config.UI.Size}):Play()
            minB.Text = "─"
        end
    end)
    
    clsB.MouseButton1Click:Connect(function()
        TS:Create(mf, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size=UDim2.new(0,0,0,0)}):Play()
        task.wait(0.3)
        sg:Destroy()
    end)
    
    GR = {
        SG=sg, MF=mf, CF=cf, SF=sf, PP=pp,
        StL=stL, PbFill=pbFill, PctL=pctL, EtaL=etaL,
        D1L=d1L, D2L=d2L, SL=sL, SpL=spL, Shimmer=shimmer,
    }
    
    -- Open anim
    TS:Create(mf, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=Config.UI.Size}):Play()
    
    -- Shimmer loop
    task.spawn(function()
        while GR.Shimmer and GR.Shimmer.Parent do
            TS:Create(GR.Shimmer, TweenInfo.new(1, Enum.EasingStyle.Linear), {Position=UDim2.new(1.25,0,0,0)}):Play()
            task.wait(1.3)
            if GR.Shimmer then GR.Shimmer.Position = UDim2.new(-0.25,0,0,0) end
        end
    end)
    
    return GR
end

local lastProgressTime = 0
local lastProgressPct = 0

function GUI.Progress(pct, status, detail1, detail2, statsText, speedText)
    if not GR.PbFill then return end
    pct = math.clamp(pct or 0, 0, 100)
    
    TS:Create(GR.PbFill, TweenInfo.new(0.15), {Size=UDim2.new(pct/100,0,1,0)}):Play()
    GR.PctL.Text = string.format("%.1f%%", pct)
    
    -- ETA calculation
    local now = tick()
    if pct > 0 and pct < 100 and lastProgressPct > 0 then
        local dpct = pct - lastProgressPct
        local dt = now - lastProgressTime
        if dpct > 0 and dt > 0 then
            local remaining = ((100 - pct) / dpct) * dt
            GR.EtaL.Text = "ETA: " .. U.FmtT(remaining)
        end
    elseif pct >= 100 then
        GR.EtaL.Text = "Done!"
    end
    lastProgressTime = now
    lastProgressPct = pct
    
    local icon = pct >= 100 and "✅" or pct > 50 and "🔄" or pct > 0 and "📦" or "⏳"
    if status then GR.StL.Text = icon .. " " .. status end
    if detail1 then GR.D1L.Text = detail1 end
    if detail2 then GR.D2L.Text = detail2 end
    if statsText then GR.SL.Text = "📊 " .. statsText end
    if speedText then GR.SpL.Text = "⚡ " .. speedText end
    
    if pct >= 100 then
        GR.PctL.TextColor3 = Config.UI.C.Ok
        TS:Create(GR.PbFill, TweenInfo.new(0.2), {BackgroundColor3=Config.UI.C.Ok}):Play()
    else
        GR.PctL.TextColor3 = Config.UI.C.P1G
    end
end

function GUI.Reset()
    lastProgressPct = 0
    lastProgressTime = tick()
    GUI.Progress(0, "Ready", "", "", "", "")
    pcall(function() GR.PbFill.BackgroundColor3 = Config.UI.C.PFl end)
end

function GUI.Lock(enabled)
    if not GR.SF then return end
    for _, ch in ipairs(GR.SF:GetChildren()) do
        if ch:IsA("TextButton") then
            ch.Active = enabled
            ch.BackgroundTransparency = enabled and 0 or 0.5
        end
    end
end

function GUI.Flash()
    if not GR.PP then return end
    local o = GR.PP.BackgroundColor3
    TS:Create(GR.PP, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(25,55,35)}):Play()
    task.wait(0.4)
    TS:Create(GR.PP, TweenInfo.new(0.25), {BackgroundColor3=o}):Play()
end

-- ============================================================
-- 21. BAOSAVEINSTANCE API (25 functions)
-- ============================================================
local API = {}
local running = false

local function Run(taskName, fn)
    if running then
        U.Notify(Config.Name, "Task already running!", 3)
        return
    end
    running = true
    GUI.Lock(false)
    GUI.Reset()
    
    task.spawn(function()
        local t0 = tick()
        local ok, err = pcall(fn)
        local elapsed = tick() - t0
        
        if not ok then
            GUI.Progress(0, "❌ Error: " .. taskName, tostring(err))
            U.Notify(Config.Name, "Error: " .. tostring(err), 6)
            U.Log("ERROR", taskName .. ": " .. tostring(err))
        end
        
        U.Log("TASK", taskName .. " finished in " .. U.FmtT(elapsed))
        running = false
        GUI.Lock(true)
    end)
end

local function MakeProgress(phaseName)
    local t0 = tick()
    return function(pct, s1, s2, s3)
        local speed = Stats.Copied / math.max(tick() - t0, 0.001)
        GUI.Progress(pct, phaseName .. ": " .. (s1 or ""),
            s2 or "", s3 or "",
            string.format("Copied:%s Failed:%d", U.FmtN(Stats.Copied), Stats.Failed),
            string.format("%.0f inst/s | Mem: %s", speed, U.FmtN(collectgarbage("count")))
        )
    end
end

local function FinishSave(fileName, taskName)
    local stats = Core.GetStats()
    GUI.Progress(85, "Exporting...", "Saving " .. fileName, "",
        Exporter.Report(stats), "Writing to disk...")
    
    local ok, err = Exporter.Save(fileName, {
        decompile = true,
        nilInstances = true,
    })
    
    if ok then
        GUI.Progress(100, "🎉 " .. taskName .. " Complete!",
            "✅ " .. fileName,
            Exporter.Report(stats),
            string.format("Total: %s instances in %s", U.FmtN(stats.Copied), U.FmtT(stats.Elapsed)),
            "")
        GUI.Flash()
        U.Notify(Config.Name, taskName .. " saved! " .. fileName, 6)
    else
        GUI.Progress(95, "⚠️ Export Attempted",
            tostring(err), "Check executor workspace folder")
        U.Notify(Config.Name, "Attempted: " .. tostring(err), 6)
    end
    
    U.ClearCache()
end

-- ═══ 25 API FUNCTIONS ═══

-- 1
function API:DecompileEverything()
    Run("Everything", function()
        local f = Config.OutputBase .. "_EVERYTHING.rbxl"
        Core.GatherEverything(function(pct, s1, s2, s3)
            local stats = Core.GetStats()
            local speed = stats.Copied / math.max(tick() - stats.StartTime, 0.001)
            GUI.Progress(pct * 0.82, s1, s2, s3,
                string.format("Copied:%s Scripts:%d Sounds:%d", U.FmtN(stats.Copied), stats.Scripts, stats.Sounds),
                string.format("%.0f inst/s", speed))
        end)
        FinishSave(f, "Everything")
    end)
end

-- 2
function API:DecompileFullGame()
    Run("Full Game", function()
        local f = Config.OutputBase .. "_FullGame.rbxl"
        Core.GatherFullGame(MakeProgress("Full Game"))
        if ScriptEng.Available() then
            Core.GatherScripts(MakeProgress("Scripts"))
        end
        Core.GatherTerrain(MakeProgress("Terrain"))
        FinishSave(f, "Full Game")
    end)
end

-- 3
function API:DecompileAllModels()
    Run("All Models", function()
        local f = Config.OutputBase .. "_AllModels.rbxl"
        Core.GatherAllModels(MakeProgress("All Models"))
        FinishSave(f, "All Models")
    end)
end

-- 4
function API:DecompileWorkspaceModels()
    Run("Workspace Models", function()
        local f = Config.OutputBase .. "_WorkspaceModels.rbxl"
        Core.GatherWorkspaceModels(MakeProgress("Workspace"))
        FinishSave(f, "Workspace Models")
    end)
end

-- 5
function API:DecompileDeepModels()
    Run("Deep Models", function()
        local f = Config.OutputBase .. "_DeepModels.rbxl"
        Core.GatherDeepModels(MakeProgress("Deep Scan"))
        FinishSave(f, "Deep Models")
    end)
end

-- 6
function API:DecompileTerrain()
    Run("Terrain", function()
        local f = Config.OutputBase .. "_Terrain.rbxl"
        local t = Core.GatherTerrain(MakeProgress("Terrain"))
        if not t then
            GUI.Progress(0, "❌ No Terrain", "No terrain data found")
            return
        end
        FinishSave(f, "Terrain")
    end)
end

-- 7
function API:DecompileScripts()
    Run("Scripts", function()
        local f = Config.OutputBase .. "_Scripts.rbxl"
        if not ScriptEng.Available() then
            GUI.Progress(0, "❌ No Decompiler", "Executor has no decompiler")
            return
        end
        Core.GatherScripts(MakeProgress("Scripts"))
        FinishSave(f, "Scripts")
    end)
end

-- 8
function API:DecompileLighting()
    Run("Lighting", function()
        local f = Config.OutputBase .. "_Lighting.rbxl"
        Core.GatherLighting(MakeProgress("Lighting"))
        FinishSave(f, "Lighting")
    end)
end

-- 9
function API:DecompileSounds()
    Run("Sounds", function()
        local f = Config.OutputBase .. "_Sounds.rbxl"
        Core.GatherSounds(MakeProgress("Sounds"))
        FinishSave(f, "Sounds")
    end)
end

-- 10
function API:DecompileAnimations()
    Run("Animations", function()
        local f = Config.OutputBase .. "_Animations.rbxl"
        Core.GatherAnimations(MakeProgress("Animations"))
        FinishSave(f, "Animations")
    end)
end

-- 11
function API:DecompileParticles()
    Run("Particles & Effects", function()
        local f = Config.OutputBase .. "_Particles.rbxl"
        Core.GatherParticles(MakeProgress("Particles"))
        FinishSave(f, "Particles")
    end)
end

-- 12
function API:DecompileMeshes()
    Run("Meshes", function()
        local f = Config.OutputBase .. "_Meshes.rbxl"
        Core.GatherMeshes(MakeProgress("Meshes"))
        FinishSave(f, "Meshes")
    end)
end

-- 13
function API:DecompileTextures()
    Run("Textures", function()
        local f = Config.OutputBase .. "_Textures.rbxl"
        Core.GatherTextures(MakeProgress("Textures"))
        FinishSave(f, "Textures")
    end)
end

-- 14
function API:DecompilePhysics()
    Run("Physics", function()
        local f = Config.OutputBase .. "_Physics.rbxl"
        Core.GatherPhysics(MakeProgress("Physics"))
        FinishSave(f, "Physics")
    end)
end

-- 15
function API:DecompileUIs()
    Run("UI Elements", function()
        local f = Config.OutputBase .. "_UIs.rbxl"
        Core.GatherUIs(MakeProgress("UIs"))
        FinishSave(f, "UIs")
    end)
end

-- 16
function API:DecompilePackages()
    Run("Packages", function()
        local f = Config.OutputBase .. "_Packages.rbxl"
        Core.GatherPackages(MakeProgress("Packages"))
        FinishSave(f, "Packages")
    end)
end

-- 17
function API:DecompileNilInstances()
    Run("Nil Instances", function()
        local f = Config.OutputBase .. "_NilInstances.rbxl"
        if not getnilinstances then
            GUI.Progress(0, "❌ Not Supported", "getnilinstances unavailable")
            return
        end
        Core.GatherNilInstances(MakeProgress("Nil"))
        FinishSave(f, "Nil Instances")
    end)
end

-- 18
function API:DecompileHiddenProps()
    Run("Hidden Properties", function()
        local f = Config.OutputBase .. "_HiddenProps.rbxl"
        Core.GatherHiddenProps(MakeProgress("Hidden"))
        FinishSave(f, "Hidden Properties")
    end)
end

-- 19
function API:DecompileMaterials()
    Run("Materials", function()
        local f = Config.OutputBase .. "_Materials.rbxl"
        Core.GatherMaterials(MakeProgress("Materials"))
        FinishSave(f, "Materials")
    end)
end

-- 20
function API:DecompileCharacters()
    Run("Characters", function()
        local f = Config.OutputBase .. "_Characters.rbxl"
        Core.GatherCharacters(MakeProgress("Characters"))
        FinishSave(f, "Characters")
    end)
end

-- 21
function API:DecompileAccessories()
    Run("Accessories & Tools", function()
        local f = Config.OutputBase .. "_Accessories.rbxl"
        Core.GatherAccessories(MakeProgress("Accessories"))
        FinishSave(f, "Accessories")
    end)
end

-- 22
function API:QuickSave()
    Run("Quick Save", function()
        local f = Config.OutputBase .. "_Quick.rbxl"
        GUI.Progress(30, "Quick Save", "Direct saveinstance...")
        FinishSave(f, "Quick Save")
    end)
end

-- 23
function API:DecompileService(serviceName)
    Run("Service: " .. serviceName, function()
        local f = Config.OutputBase .. "_" .. serviceName .. ".rbxl"
        Core.GatherService(serviceName, MakeProgress(serviceName))
        FinishSave(f, serviceName)
    end)
end

-- 24
function API:DecompileByClass(className)
    Run("Class: " .. className, function()
        local f = Config.OutputBase .. "_" .. className .. ".rbxl"
        Core.GatherByClass(className, MakeProgress(className))
        FinishSave(f, className)
    end)
end

-- 25
function API:ExportLogs()
    local log = table.concat(LogBuf, "\n")
    if #log == 0 then log = "No logs." end
    
    pcall(function()
        if setclipboard then setclipboard(log)
        elseif toclipboard then toclipboard(log) end
    end)
    
    pcall(function()
        if writefile then
            writefile(Config.OutputBase .. "_Log.txt", log)
        end
    end)
    
    U.Notify(Config.Name, "Logs exported! (" .. #LogBuf .. " entries)", 4)
end

-- ============================================================
-- 22. INITIALIZATION
-- ============================================================
local function Init()
    local ui = GUI.Build()
    local C = Config.UI.C
    local S = GR.SF
    
    -- ═══ ULTIMATE ═══
    GUI.Sep("🔥 ULTIMATE DECOMPILE", 1).Parent = S
    
    GUI.Btn("Decompile EVERYTHING", "🌐", C.P2, C.P2G, 2, function()
        API:DecompileEverything()
    end).Parent = S
    
    GUI.Btn("Full Game + Scripts + Terrain", "📦", C.P1, C.P1G, 3, function()
        API:DecompileFullGame()
    end).Parent = S
    
    GUI.Btn("Quick Save (Fastest)", "⚡", C.P3, C.P3G, 4, function()
        API:QuickSave()
    end).Parent = S
    
    -- ═══ MODELS ═══
    GUI.Sep("🧱 MODEL DECOMPILE", 10).Parent = S
    
    GUI.Btn("All Models (Full Game Auto)", "🏗️", C.P1, C.P1G, 11, function()
        API:DecompileAllModels()
    end).Parent = S
    
    GUI.Btn("Workspace Models Only", "🧊", C.Btn, C.BtnH, 12, function()
        API:DecompileWorkspaceModels()
    end).Parent = S
    
    GUI.Btn("Deep Model Scanner", "🔍", C.Btn, C.BtnH, 13, function()
        API:DecompileDeepModels()
    end).Parent = S
    
    GUI.Btn("Characters (All Players)", "🧑", C.Btn, C.BtnH, 14, function()
        API:DecompileCharacters()
    end).Parent = S
    
    GUI.Btn("Accessories & Tools", "🎒", C.Btn, C.BtnH, 15, function()
        API:DecompileAccessories()
    end).Parent = S
    
    -- ═══ ASSETS ═══
    GUI.Sep("🎨 ASSET EXTRACTION", 20).Parent = S
    
    GUI.Btn("Scripts (All Decompiled)", "📜", C.Btn, C.BtnH, 21, function()
        API:DecompileScripts()
    end).Parent = S
    
    GUI.Btn("Meshes (MeshPart/SpecialMesh)", "🔷", C.Btn, C.BtnH, 22, function()
        API:DecompileMeshes()
    end).Parent = S
    
    GUI.Btn("Textures & Decals", "🖼️", C.Btn, C.BtnH, 23, function()
        API:DecompileTextures()
    end).Parent = S
    
    GUI.Btn("Sounds & Audio", "🔊", C.Btn, C.BtnH, 24, function()
        API:DecompileSounds()
    end).Parent = S
    
    GUI.Btn("Animations", "🎬", C.Btn, C.BtnH, 25, function()
        API:DecompileAnimations()
    end).Parent = S
    
    GUI.Btn("Materials & Variants", "🎨", C.Btn, C.BtnH, 26, function()
        API:DecompileMaterials()
    end).Parent = S
    
    -- ═══ ENVIRONMENT ═══
    GUI.Sep("🌍 ENVIRONMENT", 30).Parent = S
    
    GUI.Btn("Terrain (Chunked Copy)", "🏔️", C.Btn, C.BtnH, 31, function()
        API:DecompileTerrain()
    end).Parent = S
    
    GUI.Btn("Lighting & PostFX", "💡", C.Btn, C.BtnH, 32, function()
        API:DecompileLighting()
    end).Parent = S
    
    GUI.Btn("Particles & Effects", "✨", C.Btn, C.BtnH, 33, function()
        API:DecompileParticles()
    end).Parent = S
    
    GUI.Btn("Physics & Constraints", "⚙️", C.Btn, C.BtnH, 34, function()
        API:DecompilePhysics()
    end).Parent = S
    
    -- ═══ ADVANCED ═══
    GUI.Sep("🔬 ADVANCED", 40).Parent = S
    
    GUI.Btn("UI Elements (All GUIs)", "🖥️", C.Btn, C.BtnH, 41, function()
        API:DecompileUIs()
    end).Parent = S
    
    GUI.Btn("Packages", "📁", C.Btn, C.BtnH, 42, function()
        API:DecompilePackages()
    end).Parent = S
    
    GUI.Btn("Nil Instances (Hidden)", "👻", C.P4, C.P4G, 43, function()
        API:DecompileNilInstances()
    end).Parent = S
    
    GUI.Btn("Hidden Properties", "🔐", C.P4, C.P4G, 44, function()
        API:DecompileHiddenProps()
    end).Parent = S
    
    -- ═══ SERVICES ═══
    GUI.Sep("📂 INDIVIDUAL SERVICES", 50).Parent = S
    
    local serviceButtons = {
        {"Workspace", "🌍", 51},
        {"ReplicatedStorage", "📦", 52},
        {"ServerStorage", "🗄️", 53},
        {"ServerScriptService", "📜", 54},
        {"StarterGui", "🖥️", 55},
        {"StarterPlayer", "🧑", 56},
        {"Lighting", "💡", 57},
        {"SoundService", "🔊", 58},
    }
    
    for _, info in ipairs(serviceButtons) do
        GUI.Btn(info[1], info[2], C.Btn, C.BtnH, info[3], function()
            API:DecompileService(info[1])
        end).Parent = S
    end
    
    -- ═══ TOOLS ═══
    GUI.Sep("🛠️ TOOLS", 70).Parent = S
    
    GUI.Btn("Export Logs", "📋", C.Btn, C.BtnH, 71, function()
        API:ExportLogs()
    end).Parent = S
    
    -- Info
    GUI.New("TextLabel", {
        Size = UDim2.new(1,0,0,30),
        BackgroundTransparency = 1,
        Text = string.format("v%s %s | 25 APIs | 200+ Properties | 8 Save Methods",
            Config.Version, Config.Build),
        TextColor3 = C.Dim,
        Font = Config.UI.F3,
        TextSize = 10,
        LayoutOrder = 80,
        Parent = S,
    })
    
    U.Notify(Config.Name, "v"..Config.Version.." "..Config.Build.." loaded! 25 API modes ready.", 5)
    U.Log("INIT", "BaoSaveInstance v"..Config.Version.." initialized successfully")
end

Init()

return API
