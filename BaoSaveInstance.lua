--[[
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝

    BaoSaveInstance v5.0 OMEGA
    Maximum Power Decompiler
    
    Core Architecture:
      01. Config
      02. Services
      03. Executor Detection Engine
      04. Webhook System
      05. Memory Manager
      06. Thread Scheduler
      07. Utility
      08. Signal System
      09. Property Database (350+)
      10. Reference Resolver
      11. Script Decompiler (12 methods)
      12. Bytecode Analyzer
      13. Closure Scanner
      14. Upvalue Extractor
      15. Environment Capturer
      16. Mesh Reconstructor
      17. Texture Pipeline
      18. Terrain Voxel Engine
      19. Animation Ripper
      20. Sound Pipeline
      21. Particle Cloner
      22. Lighting Capturer
      23. Physics Snapshot
      24. UI Tree Walker
      25. Package Scanner
      26. Instance Forge
      27. Hierarchy Validator
      28. DecompilerCore (35 methods)
      29. Exporter (12 methods)
      30. UI System
      31. API (35 functions)
      32. Init
]]

-- ============================================================
-- 01. CONFIG
-- ============================================================
local Config = {
    Name = "BaoSaveInstance",
    Version = "5.0",
    Build = "OMEGA",
    Out = "BaoSave",

    Webhook = {
        On = true,
        Url = "https://discord.com/api/webhooks/1474612601391415417/xF2FuZb5A3Zx527tYJbM-czA6sBBwtemqIbFRa2VMSrUqgz7DQ9achRUADwbhu3TNoh4",
    },

    Perf = {
        Threads = 12,
        Batch = 80,
        YieldEvery = 6,
        Retries = 8,
        RetryDelay = 0.01,
        Chunk = 128,
        AdaptiveChunk = true,
        Cache = true,
        DeepClone = true,
        Timeout = 600,
        MaxMemMB = 3072,
        GCInterval = 500,
        ParallelScripts = true,
        FastProperties = true,
        BruteForceProps = true,
        ResolveRefs = true,
        CaptureEnvs = true,
        SaveBytecode = true,
        RebuildFailed = true,
    },

    IgnoreClasses = {
        "Player","PlayerGui","PlayerScripts","Backpack",
        "PluginGui","PluginToolbar","PluginAction","StatsItem",
        "RunningAverageItemDouble","RunningAverageItemInt",
        "RunningAverageTimeIntervalItem","TotalCountTimeIntervalItem",
        "DebuggerWatch","DebuggerBreakpoint","AdvancedDragger",
        "ScriptDebugger","DebuggerManager",
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

    Theme = {
        Size = UDim2.new(0, 560, 0, 780),
        BtnH = 38,
        Pad = 4,
        Rad = 12,
        C = {
            Bg        = Color3.fromRGB(6, 6, 12),
            Bg2       = Color3.fromRGB(10, 10, 18),
            Panel     = Color3.fromRGB(13, 13, 22),
            Bar       = Color3.fromRGB(11, 11, 20),
            Btn       = Color3.fromRGB(20, 22, 36),
            BtnH      = Color3.fromRGB(30, 34, 52),
            A1        = Color3.fromRGB(99, 102, 241),
            A1G       = Color3.fromRGB(129, 140, 248),
            A2        = Color3.fromRGB(139, 92, 246),
            A2G       = Color3.fromRGB(167, 139, 250),
            A3        = Color3.fromRGB(16, 185, 129),
            A3G       = Color3.fromRGB(52, 211, 153),
            A4        = Color3.fromRGB(245, 158, 11),
            A4G       = Color3.fromRGB(251, 191, 36),
            A5        = Color3.fromRGB(236, 72, 153),
            A5G       = Color3.fromRGB(244, 114, 182),
            Red       = Color3.fromRGB(239, 68, 68),
            RedH      = Color3.fromRGB(248, 113, 113),
            Ok        = Color3.fromRGB(34, 197, 94),
            Cyan      = Color3.fromRGB(6, 182, 212),
            CyanG     = Color3.fromRGB(34, 211, 238),
            Txt       = Color3.fromRGB(241, 245, 249),
            Txt2      = Color3.fromRGB(203, 213, 225),
            Sub       = Color3.fromRGB(148, 163, 184),
            Dim       = Color3.fromRGB(71, 85, 105),
            Dim2      = Color3.fromRGB(51, 65, 85),
            PBg       = Color3.fromRGB(15, 23, 42),
            PFl       = Color3.fromRGB(99, 102, 241),
            Sep       = Color3.fromRGB(30, 41, 59),
            Border    = Color3.fromRGB(51, 65, 85),
            Glass     = Color3.fromRGB(15, 23, 42),
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
local HS = Svc.HttpService

-- ============================================================
-- 03. EXECUTOR DETECTION ENGINE
-- ============================================================
local ExecDetect = {}

ExecDetect.Capabilities = {
    decompile = false,
    getscriptbytecode = false,
    getsource = false,
    getscriptclosure = false,
    getscripthash = false,
    getnilinstances = false,
    gethiddenproperties = false,
    getproperties = false,
    getloadedmodules = false,
    getconnections = false,
    getgc = false,
    getupvalues = false,
    getconstants = false,
    getprotos = false,
    getinfo = false,
    hookfunction = false,
    newcclosure = false,
    saveinstance = false,
    writefile = false,
    readfile = false,
    http_request = false,
    setclipboard = false,
    firesignal = false,
    getrawmetatable = false,
    iscclosure = false,
    islclosure = false,
    clonefunction = false,
    checkcaller = false,
    getreg = false,
    getgenv = false,
    getrenv = false,
    getsenv = false,
    getmenv = false,
    isexecutorclosure = false,
    getthreadidentity = false,
    setthreadidentity = false,
    request = false,
    queue_on_teleport = false,
    isreadonly = false,
    setreadonly = false,
    getnamecallmethod = false,
    Drawing = false,
    crypt = false,
    base64 = false,
    cache = false,
    debug_lib = false,
}

function ExecDetect.Scan()
    local caps = ExecDetect.Capabilities
    caps.decompile = decompile ~= nil
    caps.getscriptbytecode = getscriptbytecode ~= nil
    caps.getsource = getsource ~= nil
    caps.getscriptclosure = getscriptclosure ~= nil
    caps.getscripthash = getscripthash ~= nil
    caps.getnilinstances = getnilinstances ~= nil
    caps.gethiddenproperties = gethiddenproperties ~= nil or gethiddenproperty ~= nil
    caps.getproperties = getproperties ~= nil
    caps.getloadedmodules = getloadedmodules ~= nil
    caps.getconnections = getconnections ~= nil
    caps.getgc = getgc ~= nil
    caps.saveinstance = saveinstance ~= nil
    caps.writefile = writefile ~= nil
    caps.readfile = readfile ~= nil
    caps.setclipboard = setclipboard ~= nil or toclipboard ~= nil
    caps.firesignal = firesignal ~= nil or firesignalraw ~= nil
    caps.getrawmetatable = getrawmetatable ~= nil
    caps.iscclosure = iscclosure ~= nil
    caps.islclosure = islclosure ~= nil
    caps.clonefunction = clonefunction ~= nil
    caps.checkcaller = checkcaller ~= nil
    caps.getreg = getreg ~= nil
    caps.getgenv = getgenv ~= nil
    caps.getrenv = getrenv ~= nil
    caps.getsenv = getsenv ~= nil
    caps.getmenv = getmenv ~= nil
    caps.isexecutorclosure = isexecutorclosure ~= nil
    caps.getthreadidentity = getthreadidentity ~= nil or getidentity ~= nil
    caps.setthreadidentity = setthreadidentity ~= nil or setidentity ~= nil
    caps.queue_on_teleport = queue_on_teleport ~= nil or queueonteleport ~= nil
    caps.isreadonly = isreadonly ~= nil
    caps.setreadonly = setreadonly ~= nil
    caps.getnamecallmethod = getnamecallmethod ~= nil
    caps.Drawing = Drawing ~= nil
    caps.cache = cache ~= nil and cache.invalidate ~= nil

    pcall(function()
        caps.http_request = http_request ~= nil or request ~= nil or
            (syn and syn.request ~= nil) or (http and http.request ~= nil)
    end)

    pcall(function()
        if debug then
            caps.getupvalues = debug.getupvalues ~= nil or getupvalues ~= nil
            caps.getconstants = debug.getconstants ~= nil or getconstants ~= nil
            caps.getprotos = debug.getprotos ~= nil or getprotos ~= nil
            caps.getinfo = debug.getinfo ~= nil or getinfo ~= nil
            caps.debug_lib = true
        end
    end)

    pcall(function()
        if crypt or base64_encode or base64encode then
            caps.crypt = true
            caps.base64 = true
        end
    end)

    return caps
end

function ExecDetect.Name()
    local n = "Unknown"
    pcall(function()
        if identifyexecutor then
            local name, ver = identifyexecutor()
            n = name .. (ver and (" " .. ver) or "")
        elseif getexecutorname then n = getexecutorname()
        elseif syn then n = "Synapse X"
        elseif fluxus then n = "Fluxus"
        elseif KRNL_LOADED then n = "KRNL"
        elseif is_sirhurt_closure then n = "SirHurt"
        elseif pebc_execute then n = "Electron"
        elseif Hydrogen then n = "Hydrogen"
        elseif getgenv and getgenv().Delta then n = "Delta"
        elseif getgenv and getgenv().Celery then n = "Celery"
        elseif wave then n = "Wave"
        elseif ScriptWare then n = "ScriptWare"
        elseif Arceus then n = "Arceus X"
        elseif codex then n = "Codex"
        end
    end)
    return n
end

function ExecDetect.PowerLevel()
    local caps = ExecDetect.Capabilities
    local score = 0
    for _, v in pairs(caps) do
        if v then score = score + 1 end
    end
    if score >= 30 then return "OMEGA", score end
    if score >= 22 then return "HIGH", score end
    if score >= 14 then return "MEDIUM", score end
    return "LOW", score
end

function ExecDetect.BestDecompileMethod()
    local caps = ExecDetect.Capabilities
    local methods = {}
    if caps.decompile then table.insert(methods, "decompile") end
    if caps.getscriptbytecode then table.insert(methods, "bytecode") end
    if caps.getsource then table.insert(methods, "getsource") end
    if caps.getscriptclosure then table.insert(methods, "closure") end
    if caps.getupvalues then table.insert(methods, "upvalues") end
    if caps.getconstants then table.insert(methods, "constants") end
    if caps.getprotos then table.insert(methods, "protos") end
    if caps.getscripthash then table.insert(methods, "hash") end
    if caps.getgc then table.insert(methods, "gc_scan") end
    if caps.getreg then table.insert(methods, "registry") end
    if caps.getsenv then table.insert(methods, "senv") end
    if caps.getloadedmodules then table.insert(methods, "modules") end
    return methods
end

-- ============================================================
-- 04. WEBHOOK SYSTEM
-- ============================================================
local WH = {}

function WH.PlayerInfo()
    local i = {Name="?", UserId=0, AccountAge=0, DisplayName="?"}
    pcall(function()
        i.Name = Plr.Name
        i.UserId = Plr.UserId
        i.AccountAge = Plr.AccountAge
        i.DisplayName = Plr.DisplayName
    end)
    return i
end

function WH.GameInfo()
    local i = {Name="?", PlaceId=0, GameId=0, JobId=""}
    pcall(function() i.PlaceId = game.PlaceId i.GameId = game.GameId i.JobId = game.JobId end)
    pcall(function()
        local pi = Svc.MarketplaceService:GetProductInfo(game.PlaceId)
        if pi then i.Name = pi.Name or "?" end
    end)
    return i
end

function WH.Timestamp()
    local t = os.date("*t")
    return string.format("%04d/%02d/%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

function WH.Send(taskName, stats)
    if not Config.Webhook.On or Config.Webhook.Url == "https://discord.com/api/webhooks/1474612601391415417/xF2FuZb5A3Zx527tYJbM-czA6sBBwtemqIbFRa2VMSrUqgz7DQ9achRUADwbhu3TNoh4" then return end

    local p = WH.PlayerInfo()
    local g = WH.GameInfo()
    local exec = ExecDetect.Name()
    local lvl, score = ExecDetect.PowerLevel()
    local ts = WH.Timestamp()

    local statsLines = "N/A"
    if stats then
        statsLines = string.format(
            "Instances Copied: %s\nInstances Failed: %d\nScripts Decompiled: %d / %d\nMeshes: %d\nSounds: %d\nAnimations: %d\nTerrain Chunks: %d\nNil Instances: %d\nHidden Props: %d\nTime: %s\nPeak Memory: %sKB",
            tostring(stats.Copied or 0), stats.Failed or 0,
            stats.Scripts or 0, (stats.Scripts or 0) + (stats.ScriptsFail or 0),
            stats.Meshes or 0, stats.Sounds or 0, stats.Anims or 0,
            stats.Terrain or 0, stats.NilInst or 0, stats.Hidden or 0,
            stats.Elapsed and string.format("%.2fs", stats.Elapsed) or "?",
            tostring(math.floor(stats.PeakMem or collectgarbage("count")))
        )
    end

    local embed = {{
        title = "⚡ BaoSaveInstance v" .. Config.Version .. " " .. Config.Build,
        description = "Decompile task completed successfully.",
        color = 6366961,
        thumbnail = {url = "https://discord.com/api/webhooks/1474612601391415417/xF2FuZb5A3Zx527tYJbM-czA6sBBwtemqIbFRa2VMSrUqgz7DQ9achRUADwbhu3TNoh4"},
        fields = {
            {name="👤 Player Name", value="```"..p.Name.."```", inline=true},
            {name="🆔 User ID", value="```"..tostring(p.UserId).."```", inline=true},
            {name="📛 Display Name", value="```"..p.DisplayName.."```", inline=true},
            {name="📅 Account Age", value="```"..tostring(p.AccountAge).." days```", inline=true},
            {name="🔧 Executor", value="```"..exec.."```", inline=true},
            {name="💪 Power Level", value="```"..lvl.." ("..score.."/35)```", inline=true},
            {name="🎮 Game Name", value="```"..g.Name.."```", inline=true},
            {name="🏷️ Place ID", value="```"..tostring(g.PlaceId).."```", inline=true},
            {name="🌐 Game ID", value="```"..tostring(g.GameId).."```", inline=true},
            {name="📋 Task Completed", value="```"..taskName.."```", inline=false},
            {name="📊 Detailed Stats", value="```\n"..statsLines.."\n```", inline=false},
        },
        footer = {text="BaoSaveInstance Logging System | "..ts},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }}

    local json
    pcall(function() json = HS:JSONEncode({embeds=embed, username="BaoSave v"..Config.Version}) end)
    if not json then return end

    local sendMethods = {
        function() if http_request then http_request({Url=Config.Webhook.Url,Method="POST",Headers={["Content-Type"]="application/json"},Body=json}) return true end end,
        function() if request then request({Url=Config.Webhook.Url,Method="POST",Headers={["Content-Type"]="application/json"},Body=json}) return true end end,
        function() if syn and syn.request then syn.request({Url=Config.Webhook.Url,Method="POST",Headers={["Content-Type"]="application/json"},Body=json}) return true end end,
        function() if http and http.request then http.request({Url=Config.Webhook.Url,Method="POST",Headers={["Content-Type"]="application/json"},Body=json}) return true end end,
        function() HS:PostAsync(Config.Webhook.Url, json) return true end,
    }

    for _, m in ipairs(sendMethods) do
        local ok = pcall(m)
        if ok then return end
    end
end

-- ============================================================
-- 05. MEMORY MANAGER
-- ============================================================
local Mem = {}
Mem.peakKB = 0
Mem.gcCounter = 0

function Mem.Check()
    local kb = collectgarbage("count")
    if kb > Mem.peakKB then Mem.peakKB = kb end
    Mem.gcCounter = Mem.gcCounter + 1
    if Mem.gcCounter % Config.Perf.GCInterval == 0 then
        if kb > Config.Perf.MaxMemMB * 1024 * 0.8 then
            collectgarbage("collect")
        end
    end
    return kb
end

function Mem.ForceGC()
    collectgarbage("collect")
    collectgarbage("collect")
    task.wait(0.05)
end

function Mem.Peak() return Mem.peakKB end

-- ============================================================
-- 06. THREAD SCHEDULER
-- ============================================================
local Sched = {}

function Sched.Batch(items, fn, bSz, pCb)
    bSz = bSz or Config.Perf.Batch
    local t, d, res = #items, 0, {}
    for i = 1, t, bSz do
        local e = math.min(i+bSz-1, t)
        for j = i, e do
            local ok, r = pcall(fn, items[j], j)
            if ok and r ~= nil then table.insert(res, r) end
            d = d + 1
            Mem.Check()
        end
        if pCb then pCb(d, t, items[math.min(i,t)]) end
        RS.RenderStepped:Wait()
    end
    return res, d
end

function Sched.ParallelBatch(items, fn, maxConcurrent, pCb)
    maxConcurrent = maxConcurrent or Config.Perf.Threads
    local t = #items
    local completed, idx, running = 0, 0, 0
    local results = {}

    while completed < t do
        while idx < t and running < maxConcurrent do
            idx = idx + 1
            running = running + 1
            local i = idx
            task.spawn(function()
                local ok, r = pcall(fn, items[i], i)
                if ok and r ~= nil then results[i] = r end
                completed = completed + 1
                running = running - 1
                if pCb and completed % 10 == 0 then pCb(completed, t) end
            end)
        end
        RS.RenderStepped:Wait()
    end

    local ordered = {}
    for i = 1, t do
        if results[i] then table.insert(ordered, results[i]) end
    end
    return ordered
end

-- ============================================================
-- 07. UTILITY
-- ============================================================
local U = {}
local LogBuf = {}
local InstCache = {}

function U.Log(lv, m) table.insert(LogBuf, string.format("[%s][%s] %s", os.date("%H:%M:%S"), lv, m)) if #LogBuf > 5000 then table.remove(LogBuf, 1) end end
function U.Notify(t, m, d) pcall(function() Svc.StarterGui:SetCore("SendNotification", {Title=t,Text=m,Duration=d or 5}) end) U.Log("NOTIFY", m) end

function U.Clone(inst)
    if not inst then return nil end
    if InstCache[inst] then
        local ok, c = pcall(InstCache[inst].Clone, InstCache[inst])
        if ok and c then return c end
    end
    for i = 1, Config.Perf.Retries do
        local ok, c = pcall(inst.Clone, inst)
        if ok and c then
            if Config.Perf.Cache then InstCache[inst] = c end
            return c
        end
        if i < Config.Perf.Retries then task.wait(Config.Perf.RetryDelay) end
    end
    return nil
end

function U.IsIgnC(cn) for _, v in ipairs(Config.IgnoreClasses) do if v == cn then return true end end return false end
function U.IsIgnS(n) for _, v in ipairs(Config.IgnoreServices) do if v == n then return true end end return false end
function U.Path(i) local p,c = {},i while c and c ~= game do table.insert(p,1,c.Name) c = c.Parent end return table.concat(p,".") end
function U.Yield(c) if c % Config.Perf.YieldEvery == 0 then RS.RenderStepped:Wait() end end
function U.Count(r) local n = 0 pcall(function() n = #r:GetDescendants() end) return n end
function U.FmtN(n) if n>=1e6 then return string.format("%.2fM",n/1e6) end if n>=1e3 then return string.format("%.1fK",n/1e3) end return tostring(n) end
function U.FmtT(s) if s<1 then return string.format("%dms",s*1000) end if s<60 then return string.format("%.1fs",s) end return string.format("%dm%.0fs",math.floor(s/60),s%60) end
function U.IsA(i, cls) for _, c in ipairs(cls) do if i:IsA(c) then return true end end return false end
function U.Ch(i) local ok, ch = pcall(i.GetChildren, i) return ok and ch or {} end
function U.Desc(i) local ok, d = pcall(i.GetDescendants, i) return ok and d or {} end
function U.Svc(n) local ok, s = pcall(game.GetService, game, n) return ok and s or nil end
function U.Merge(a, b) for _, v in ipairs(b) do table.insert(a, v) end return a end
function U.ClearCache() InstCache = {} collectgarbage("collect") end

-- ============================================================
-- 08. SIGNAL SYSTEM
-- ============================================================
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({_handlers = {}}, Signal)
end

function Signal:Connect(fn)
    table.insert(self._handlers, fn)
    return {Disconnect = function()
        for i, h in ipairs(self._handlers) do
            if h == fn then table.remove(self._handlers, i) return end
        end
    end}
end

function Signal:Fire(...)
    for _, h in ipairs(self._handlers) do
        task.spawn(h, ...)
    end
end

-- Global signals
local Signals = {
    OnProgress = Signal.new(),
    OnPhaseStart = Signal.new(),
    OnPhaseEnd = Signal.new(),
    OnError = Signal.new(),
    OnComplete = Signal.new(),
    OnInstanceCopied = Signal.new(),
    OnScriptDecompiled = Signal.new(),
}

-- ============================================================
-- 09. PROPERTY DATABASE (350+ properties)
-- ============================================================
local PDB = {}

PDB.Props = {
    BasePart = {"Anchored","BackSurface","BottomSurface","BrickColor","CFrame","CanCollide","CanQuery","CanTouch","CastShadow","CollisionGroup","Color","CustomPhysicalProperties","EnableFluidForces","FrontSurface","LeftSurface","LocalTransparencyModifier","Locked","Massless","Material","MaterialVariant","PivotOffset","Position","Reflectance","RightSurface","RootPriority","RotVelocity","Rotation","Size","TopSurface","Transparency","Velocity"},
    MeshPart = {"CollisionFidelity","DoubleSided","FluidFidelity","HasJointOffset","HasSkinnedMesh","MeshId","MeshSize","RenderFidelity","TextureID"},
    UnionOperation = {"AssetId","CollisionFidelity","FluidFidelity","RenderFidelity","SmoothingAngle","UsePartColor"},
    SpecialMesh = {"MeshId","MeshType","Offset","Scale","TextureId","VertexColor"},
    Decal = {"Color3","Face","Texture","Transparency","ZIndex"},
    Texture = {"Face","OffsetStudsU","OffsetStudsV","StudsPerTileU","StudsPerTileV","Texture","Transparency"},
    SurfaceAppearance = {"AlphaMode","ColorMap","MetalnessMap","NormalMap","RoughnessMap","TexturePack"},
    Model = {"LevelOfDetail","ModelStreamingMode","PrimaryPart","WorldPivot","ScaleTo"},
    Humanoid = {"AutoJumpEnabled","AutoRotate","AutomaticScalingEnabled","BreakJointsOnDeath","DisplayDistanceType","DisplayName","EvaluateStateMachine","Health","HealthDisplayDistance","HealthDisplayType","HipHeight","Jump","JumpHeight","JumpPower","MaxHealth","MaxSlopeAngle","MoveDirection","NameDisplayDistance","NameOcclusion","PlatformStand","RequiresNeck","RigType","RootPart","Sit","TargetPoint","UseJumpPower","WalkSpeed","WalkToPart","WalkToPoint"},
    HumanoidDescription = {"BackAccessory","BodyTypeScale","ClimbAnimation","DepthScale","Face","FaceAccessory","FallAnimation","FrontAccessory","GraphicTShirt","HairAccessory","HatAccessory","Head","HeadColor","HeadScale","HeightScale","IdleAnimation","JumpAnimation","LeftArm","LeftArmColor","LeftLeg","LeftLegColor","NeckAccessory","Pants","ProportionScale","RightArm","RightArmColor","RightLeg","RightLegColor","RunAnimation","Shirt","ShouldersAccessory","SwimAnimation","Torso","TorsoColor","WaistAccessory","WalkAnimation","WidthScale"},
    Sound = {"EmitterSize","LoopRegion","Looped","PlayOnRemove","PlaybackRegion","PlaybackRegionsEnabled","PlaybackSpeed","Playing","RollOffMaxDistance","RollOffMinDistance","RollOffMode","SoundGroup","SoundId","TimePosition","Volume"},
    ParticleEmitter = {"Acceleration","Brightness","Color","Drag","EmissionDirection","Enabled","FlipbookFramerate","FlipbookIncompatible","FlipbookLayout","FlipbookMode","FlipbookStartRandom","Lifetime","LightEmission","LightInfluence","LockedToPart","Orientation","Rate","RotSpeed","Rotation","Shape","ShapeInOut","ShapePartial","ShapeStyle","Size","Speed","SpreadAngle","Squash","Texture","TimeScale","Transparency","VelocityInheritance","WindAffectsDrag","ZOffset"},
    Beam = {"Attachment0","Attachment1","Brightness","Color","CurveSize0","CurveSize1","Enabled","FaceCamera","LightEmission","LightInfluence","Segments","Texture","TextureLength","TextureMode","TextureSpeed","Transparency","Width0","Width1","ZOffset"},
    Trail = {"Attachment0","Attachment1","Brightness","Color","Enabled","FaceCamera","Lifetime","LightEmission","LightInfluence","MaxLength","MinLength","Texture","TextureLength","TextureMode","Transparency","WidthScale"},
    PointLight = {"Brightness","Color","Enabled","Range","Shadows"},
    SpotLight = {"Angle","Brightness","Color","Enabled","Face","Range","Shadows"},
    SurfaceLight = {"Angle","Brightness","Color","Enabled","Face","Range","Shadows"},
    Fire = {"Color","Enabled","Heat","SecondaryColor","Size","TimeScale"},
    Smoke = {"Color","Enabled","Opacity","RiseVelocity","Size","TimeScale"},
    Sparkles = {"Color","Enabled","SparkleColor","TimeScale"},
    Explosion = {"BlastPressure","BlastRadius","DestroyJointRadiusPercent","ExplosionType","Position","TimeScale","Visible"},
    Attachment = {"Axis","CFrame","Orientation","Position","SecondaryAxis","Visible","WorldAxis","WorldCFrame","WorldOrientation","WorldPosition","WorldSecondaryAxis"},
    Bone = {"CFrame","Orientation","Position","Transform","TransformedCFrame","TransformedWorldCFrame","Visible"},
    WeldConstraint = {"Active","Enabled","Part0","Part1"},
    Motor6D = {"C0","C1","CurrentAngle","DesiredAngle","MaxVelocity","Part0","Part1","Transform"},
    Weld = {"C0","C1","Part0","Part1"},
    BallSocketConstraint = {"Enabled","LimitsEnabled","MaxAngle","Radius","Restitution","TwistLimitsEnabled","TwistLowerAngle","TwistUpperAngle","UpperAngle"},
    HingeConstraint = {"ActuatorType","AngularResponsiveness","AngularSpeed","AngularVelocity","Enabled","LimitsEnabled","LowerAngle","MotorMaxAcceleration","MotorMaxTorque","Radius","Restitution","ServoMaxTorque","SoftlockServoUponReachingTarget","TargetAngle","UpperAngle"},
    RopeConstraint = {"Enabled","Length","Restitution","Thickness","Visible","WinchEnabled","WinchForce","WinchResponsiveness","WinchSpeed","WinchTarget"},
    SpringConstraint = {"Coils","Damping","Enabled","FreeLength","LimitsEnabled","MaxForce","MaxLength","MinLength","Radius","Stiffness","Thickness","Visible"},
    BillboardGui = {"Active","Adornee","AlwaysOnTop","Brightness","ClipsDescendants","CurrentDistance","DistanceLowerLimit","DistanceStep","DistanceUpperLimit","ExtentsOffset","ExtentsOffsetWorldSpace","LightInfluence","MaxDistance","PlayerToHideFrom","Size","SizeOffset","StudsOffset","StudsOffsetWorldSpace","ZIndexBehavior"},
    SurfaceGui = {"Active","Adornee","AlwaysOnTop","Brightness","CanvasSize","ClipsDescendants","Face","LightInfluence","PixelsPerStud","SizingMode","ToolPunchThroughDistance","ZIndexBehavior","ZOffset"},
    ScreenGui = {"AutoLocalize","ClipToDeviceSafeArea","DisplayOrder","Enabled","IgnoreGuiInset","ResetOnSpawn","ScreenInsets","ZIndexBehavior"},
    Frame = {"Active","AnchorPoint","AutomaticSize","BackgroundColor3","BackgroundTransparency","BorderColor3","BorderMode","BorderSizePixel","ClipsDescendants","LayoutOrder","Position","Rotation","Selectable","SelectionGroup","Size","SizeConstraint","Visible","ZIndex"},
    TextLabel = {"Active","AnchorPoint","AutoLocalize","AutomaticSize","BackgroundColor3","BackgroundTransparency","BorderColor3","BorderSizePixel","ClipsDescendants","Font","FontFace","LayoutOrder","LineHeight","MaxVisibleGraphemes","Position","RichText","Rotation","Size","Text","TextColor3","TextDirection","TextScaled","TextSize","TextStrokeColor3","TextStrokeTransparency","TextTransparency","TextTruncate","TextWrapped","TextXAlignment","TextYAlignment","Visible","ZIndex"},
    TextButton = {"Active","AnchorPoint","AutoButtonColor","AutoLocalize","AutomaticSize","BackgroundColor3","BackgroundTransparency","BorderColor3","BorderSizePixel","ClipsDescendants","Font","FontFace","LayoutOrder","LineHeight","MaxVisibleGraphemes","Modal","Position","RichText","Rotation","Selectable","Selected","Size","Style","Text","TextColor3","TextScaled","TextSize","TextStrokeColor3","TextStrokeTransparency","TextTransparency","TextTruncate","TextWrapped","TextXAlignment","TextYAlignment","Visible","ZIndex"},
    TextBox = {"Active","AnchorPoint","AutomaticSize","BackgroundColor3","BackgroundTransparency","BorderColor3","BorderSizePixel","ClearTextOnFocus","ClipsDescendants","CursorPosition","Font","FontFace","LayoutOrder","LineHeight","MaxVisibleGraphemes","MultiLine","PlaceholderColor3","PlaceholderText","Position","RichText","Rotation","SelectionStart","ShowNativeInput","Size","Text","TextColor3","TextDirection","TextEditable","TextScaled","TextSize","TextStrokeColor3","TextStrokeTransparency","TextTransparency","TextTruncate","TextWrapped","TextXAlignment","TextYAlignment","Visible","ZIndex"},
    ImageLabel = {"Active","AnchorPoint","AutomaticSize","BackgroundColor3","BackgroundTransparency","BorderColor3","BorderSizePixel","ClipsDescendants","Image","ImageColor3","ImageRectOffset","ImageRectSize","ImageTransparency","LayoutOrder","Position","ResampleMode","Rotation","ScaleType","Size","SliceCenter","SliceScale","TileSize","Visible","ZIndex"},
    ImageButton = {"Active","AnchorPoint","AutoButtonColor","AutomaticSize","BackgroundColor3","BackgroundTransparency","BorderColor3","BorderSizePixel","ClipsDescendants","HoverImage","Image","ImageColor3","ImageRectOffset","ImageRectSize","ImageTransparency","LayoutOrder","Modal","Position","PressedImage","ResampleMode","Rotation","ScaleType","Selectable","Selected","Size","SliceCenter","SliceScale","TileSize","Visible","ZIndex"},
    ScrollingFrame = {"Active","AnchorPoint","AutomaticCanvasSize","AutomaticSize","BackgroundColor3","BackgroundTransparency","BorderColor3","BorderSizePixel","BottomImage","CanvasPosition","CanvasSize","ClipsDescendants","ElasticBehavior","HorizontalScrollBarInset","LayoutOrder","MidImage","Position","Rotation","ScrollBarImageColor3","ScrollBarImageTransparency","ScrollBarThickness","ScrollingDirection","ScrollingEnabled","Size","TopImage","VerticalScrollBarInset","VerticalScrollBarPosition","Visible","ZIndex"},
    ViewportFrame = {"Ambient","BackgroundColor3","BackgroundTransparency","BorderColor3","BorderSizePixel","CurrentCamera","ImageColor3","ImageTransparency","LayoutOrder","LightColor","LightDirection","Position","Size","Visible","ZIndex"},
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
    UIFlexItem = {"FlexMode","GrowRatio","ItemLineAlignment","ShrinkRatio"},
    Atmosphere = {"Color","Decay","Density","Glare","Haze","Offset"},
    Sky = {"CelestialBodiesShown","MoonAngularSize","MoonTextureId","SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp","StarCount","SunAngularSize","SunTextureId"},
    Clouds = {"Color","Cover","Density","Enabled"},
    BloomEffect = {"Enabled","Intensity","Size","Threshold"},
    BlurEffect = {"Enabled","Size"},
    ColorCorrectionEffect = {"Brightness","Contrast","Enabled","Saturation","TintColor"},
    DepthOfFieldEffect = {"Enabled","FarIntensity","FocusDistance","InFocusRadius","NearIntensity"},
    SunRaysEffect = {"Enabled","Intensity","Spread"},
    ProximityPrompt = {"ActionText","AutoLocalize","ClickablePrompt","Enabled","ExclusivityType","GamepadKeyCode","HoldDuration","KeyboardKeyCode","MaxActivationDistance","ObjectText","RequiresLineOfSight","Style","UIOffset"},
    Highlight = {"Adornee","DepthMode","Enabled","FillColor","FillTransparency","OutlineColor","OutlineTransparency"},
    ClickDetector = {"CursorIcon","MaxActivationDistance"},
    Camera = {"CFrame","CameraSubject","CameraType","DiagonalFieldOfView","FieldOfView","FieldOfViewMode","Focus","HeadLocked","HeadScale","MaxAxisFieldOfView","NearPlaneZ"},
    ValueBase = {"Value"},
    ForceField = {"Visible"},
    Tool = {"CanBeDropped","Enabled","Grip","GripForward","GripPos","GripRight","GripUp","ManualActivationOnly","RequiresHandle","ToolTip"},
    Accessory = {"AccessoryType","AttachmentForward","AttachmentPoint","AttachmentPos","AttachmentRight","AttachmentUp"},
    Shirt = {"ShirtTemplate"}, Pants = {"PantsTemplate"}, ShirtGraphic = {"Graphic"},
    BodyColors = {"HeadColor3","LeftArmColor3","LeftLegColor3","RightArmColor3","RightLegColor3","TorsoColor3"},
    CharacterMesh = {"BaseTextureId","BodyPart","MeshId","OverlayTextureId"},
    BodyGyro = {"CFrame","D","MaxTorque","P"},
    BodyPosition = {"D","MaxForce","P","Position"},
    BodyVelocity = {"MaxForce","P","Velocity"},
    BodyForce = {"Force"}, BodyThrust = {"Force","Location"},
    NumberValue = {"Value"}, StringValue = {"Value"}, BoolValue = {"Value"},
    IntValue = {"Value"}, ObjectValue = {"Value"}, CFrameValue = {"Value"},
    Color3Value = {"Value"}, Vector3Value = {"Value"}, RayValue = {"Value"},
    BrickColorValue = {"Value"},
    BindableEvent = {}, BindableFunction = {},
    RemoteEvent = {}, RemoteFunction = {},
    Configuration = {},
    SelectionBox = {"Adornee","Color3","LineThickness","SurfaceColor3","SurfaceTransparency","Transparency","Visible"},
    SelectionSphere = {"Adornee","Color3","SurfaceColor3","SurfaceTransparency","Transparency","Visible"},
    BoxHandleAdornment = {"AlwaysOnTop","Adornee","CFrame","Color3","Size","SizeRelativeOffset","Transparency","Visible","ZIndex"},
    SphereHandleAdornment = {"AlwaysOnTop","Adornee","CFrame","Color3","Radius","SizeRelativeOffset","Transparency","Visible","ZIndex"},
    CylinderHandleAdornment = {"AlwaysOnTop","Adornee","Angle","CFrame","Color3","Height","InnerRadius","Radius","SizeRelativeOffset","Transparency","Visible","ZIndex"},
    WrapTarget = {"CageMeshId","CageOrigin","Stiffness"},
    WrapLayer = {"AutoSkin","BindOffset","CageMeshId","CageOrigin","Color","Enabled","Order","Puffiness","ReferenceMeshId","ReferenceOrigin","ShrinkFactor"},
    MeshPart_Extra = {"FluidFidelity","RenderFidelity"},
}

function PDB.BruteForceProps(src, dst)
    if not Config.Perf.BruteForceProps then return end
    pcall(function()
        if gethiddenproperties then
            local hidden = gethiddenproperties(src)
            for prop, val in pairs(hidden) do
                pcall(function() dst[prop] = val end)
            end
        end
    end)
    pcall(function()
        if getproperties then
            local props = getproperties(src)
            for _, prop in ipairs(props) do
                pcall(function() dst[prop] = src[prop] end)
            end
        end
    end)
end

function PDB.Copy(src, dst)
    local cn = src.ClassName
    local props = PDB.Props[cn]
    if props then
        for _, p in ipairs(props) do pcall(function() dst[p] = src[p] end) end
    end
    for className, classProps in pairs(PDB.Props) do
        if className ~= cn then
            local ok = false
            pcall(function() ok = src:IsA(className) end)
            if ok then
                for _, p in ipairs(classProps) do pcall(function() dst[p] = src[p] end) end
            end
        end
    end
    pcall(function()
        for n, v in pairs(src:GetAttributes()) do
            pcall(function() dst:SetAttribute(n, v) end)
        end
    end)
    pcall(function()
        local CS = Svc.CollectionService
        if CS then for _, tag in ipairs(CS:GetTags(src)) do pcall(function() CS:AddTag(dst, tag) end) end end
    end)
    PDB.BruteForceProps(src, dst)
end

function PDB.Deep(src)
    local c = U.Clone(src)
    if c then PDB.Copy(src, c) return c end
    local ok, inst = pcall(Instance.new, src.ClassName)
    if ok and inst then
        pcall(function() inst.Name = src.Name end)
        PDB.Copy(src, inst)
        return inst
    end
    return nil
end

-- ============================================================
-- 10. REFERENCE RESOLVER
-- ============================================================
local RefResolver = {}

function RefResolver.ResolveObjectValues(root)
    if not Config.Perf.ResolveRefs then return end
    pcall(function()
        for _, d in ipairs(U.Desc(root)) do
            if d:IsA("ObjectValue") then
                pcall(function()
                    local target = d.Value
                    if target then
                        local targetPath = U.Path(target)
                        local found = root:FindFirstChild(target.Name, true)
                        if found then d.Value = found end
                    end
                end)
            end
        end
    end)
end

function RefResolver.ResolveWelds(root)
    pcall(function()
        for _, d in ipairs(U.Desc(root)) do
            if d:IsA("JointInstance") then
                pcall(function()
                    if d.Part0 then
                        local f = root:FindFirstChild(d.Part0.Name, true)
                        if f and f:IsA("BasePart") then d.Part0 = f end
                    end
                    if d.Part1 then
                        local f = root:FindFirstChild(d.Part1.Name, true)
                        if f and f:IsA("BasePart") then d.Part1 = f end
                    end
                end)
            end
        end
    end)
end

function RefResolver.ResolvePrimaryParts(root)
    pcall(function()
        for _, d in ipairs(U.Desc(root)) do
            if d:IsA("Model") and d.PrimaryPart == nil then
                pcall(function()
                    local pp = d:FindFirstChildWhichIsA("BasePart")
                    if pp then d.PrimaryPart = pp end
                end)
            end
        end
    end)
end

function RefResolver.ResolveAll(root)
    RefResolver.ResolveObjectValues(root)
    RefResolver.ResolveWelds(root)
    RefResolver.ResolvePrimaryParts(root)
end

-- ============================================================
-- 11. SCRIPT DECOMPILER (12 methods)
-- ============================================================
local SE = {}
local SrcCache = {}
local BytecodeCache = {}

function SE.Has()
    local caps = ExecDetect.Capabilities
    return caps.decompile or caps.getscriptbytecode or caps.getsource or
           caps.getscriptclosure or caps.getscripthash or caps.getgc or
           caps.getreg or caps.getsenv or caps.getloadedmodules or
           caps.getupvalues or caps.getconstants or caps.getprotos
end

function SE.Decompile(inst)
    if not inst then return nil, "nil" end
    local path = U.Path(inst)
    if SrcCache[path] then return SrcCache[path], "cache" end

    local src, method

    -- M1: decompile()
    if not src and decompile then
        pcall(function()
            local r = decompile(inst)
            if r and #r > 2 then src = r method = "decompile" end
        end)
    end

    -- M2: getscriptbytecode + decompile
    if not src and getscriptbytecode and decompile then
        pcall(function()
            local bc = getscriptbytecode(inst)
            if bc then
                BytecodeCache[path] = bc
                local r = decompile(bc)
                if r and #r > 2 then src = r method = "bytecode+decompile" end
            end
        end)
    end

    -- M3: getsource
    if not src and getsource then
        pcall(function()
            local r = getsource(inst)
            if r and #r > 2 then src = r method = "getsource" end
        end)
    end

    -- M4: getscriptclosure + decompile
    if not src and getscriptclosure then
        pcall(function()
            local cl = getscriptclosure(inst)
            if cl then
                if decompile then
                    local r = decompile(cl)
                    if r and #r > 2 then src = r method = "closure+decompile" end
                end
            end
        end)
    end

    -- M5: .Source property
    if not src then
        pcall(function()
            local s = inst.Source
            if s and #s > 0 then src = s method = "Source" end
        end)
    end

    -- M6: getsenv (script environment)
    if not src and getsenv then
        pcall(function()
            local env = getsenv(inst)
            if env then
                local info = {}
                for k, v in pairs(env) do
                    table.insert(info, string.format("-- ENV: %s = %s (%s)", tostring(k), tostring(v), type(v)))
                end
                if #info > 0 then
                    src = "-- [BaoSave] Script Environment Dump\n" .. table.concat(info, "\n")
                    method = "senv"
                end
            end
        end)
    end

    -- M7: getupvalues
    if not src and (getupvalues or (debug and debug.getupvalues)) then
        pcall(function()
            local fn
            if getscriptclosure then fn = getscriptclosure(inst) end
            if fn then
                local gupv = getupvalues or debug.getupvalues
                local upvals = gupv(fn)
                if upvals and next(upvals) then
                    local lines = {"-- [BaoSave] Upvalue Recovery"}
                    for idx, val in pairs(upvals) do
                        table.insert(lines, string.format("-- UV[%s] = %s (%s)", tostring(idx), tostring(val), type(val)))
                    end
                    src = table.concat(lines, "\n")
                    method = "upvalues"
                end
            end
        end)
    end

    -- M8: getconstants
    if not src and (getconstants or (debug and debug.getconstants)) then
        pcall(function()
            local fn
            if getscriptclosure then fn = getscriptclosure(inst) end
            if fn then
                local gcon = getconstants or debug.getconstants
                local consts = gcon(fn)
                if consts and #consts > 0 then
                    local lines = {"-- [BaoSave] Constants Recovery"}
                    for i, c in ipairs(consts) do
                        table.insert(lines, string.format("-- CONST[%d] = %s (%s)", i, tostring(c), type(c)))
                    end
                    src = table.concat(lines, "\n")
                    method = "constants"
                end
            end
        end)
    end

    -- M9: getprotos
    if not src and (getprotos or (debug and debug.getprotos)) then
        pcall(function()
            local fn
            if getscriptclosure then fn = getscriptclosure(inst) end
            if fn then
                local gp = getprotos or debug.getprotos
                local protos = gp(fn)
                if protos and #protos > 0 then
                    local lines = {"-- [BaoSave] Proto Recovery (" .. #protos .. " protos)"}
                    for i, proto in ipairs(protos) do
                        if decompile then
                            pcall(function()
                                local psrc = decompile(proto)
                                if psrc then
                                    table.insert(lines, "-- === Proto " .. i .. " ===")
                                    table.insert(lines, psrc)
                                end
                            end)
                        else
                            table.insert(lines, string.format("-- PROTO[%d] = %s", i, tostring(proto)))
                        end
                    end
                    src = table.concat(lines, "\n")
                    method = "protos"
                end
            end
        end)
    end

    -- M10: getgc scan
    if not src and getgc then
        pcall(function()
            local gc = getgc(true)
            for _, obj in ipairs(gc) do
                if type(obj) == "function" then
                    pcall(function()
                        local info = debug.getinfo(obj)
                        if info and info.source and info.source:find(inst.Name) then
                            if decompile then
                                local r = decompile(obj)
                                if r and #r > 2 then src = r method = "gc_scan" end
                            end
                        end
                    end)
                end
                if src then break end
            end
        end)
    end

    -- M11: getreg scan
    if not src and getreg then
        pcall(function()
            local reg = getreg()
            for _, obj in ipairs(reg) do
                if type(obj) == "function" then
                    pcall(function()
                        local info = debug.getinfo(obj)
                        if info and info.source and info.source:find(inst.Name) then
                            if decompile then
                                local r = decompile(obj)
                                if r and #r > 2 then src = r method = "registry" end
                            end
                        end
                    end)
                end
                if src then break end
            end
        end)
    end

    -- M12: getloadedmodules
    if not src and getloadedmodules and inst:IsA("ModuleScript") then
        pcall(function()
            local modules = getloadedmodules()
            for _, mod in ipairs(modules) do
                if mod == inst or mod.Name == inst.Name then
                    if decompile then
                        local r = decompile(mod)
                        if r and #r > 2 then src = r method = "loadedmodules" end
                    end
                    break
                end
            end
        end)
    end

    -- M-bytecode: Save raw bytecode if available
    if not src and getscriptbytecode and Config.Perf.SaveBytecode then
        pcall(function()
            local bc = getscriptbytecode(inst)
            if bc and #bc > 0 then
                BytecodeCache[path] = bc
                src = string.format(
                    "-- [BaoSave OMEGA] Raw Bytecode Preserved\n-- Size: %d bytes\n-- Path: %s\n-- Class: %s\n-- Hash: %s\n-- Note: Bytecode saved for offline decompilation\n",
                    #bc, path, inst.ClassName,
                    getscripthash and tostring(pcall(getscripthash, inst) and getscripthash(inst)) or "N/A"
                )
                method = "bytecode_raw"
            end
        end)
    end

    -- M-hash: Identifier
    if not src and getscripthash then
        pcall(function()
            local h = getscripthash(inst)
            src = string.format("-- [BaoSave] Hash: %s\n-- Path: %s\n-- Class: %s\n", tostring(h), path, inst.ClassName)
            method = "hash"
        end)
    end

    -- Fallback
    if not src then
        src = string.format(
            "-- [BaoSaveInstance v5.0 OMEGA] All %d decompile methods exhausted\n-- Name: %s\n-- Class: %s\n-- Path: %s\n-- Executor: %s\n-- Available Methods: %s\n",
            12, inst.Name, inst.ClassName, path,
            ExecDetect.Name(),
            table.concat(ExecDetect.BestDecompileMethod(), ", ")
        )
        method = "failed"
    end

    SrcCache[path] = src
    Signals.OnScriptDecompiled:Fire(inst, method, src)
    return src, method
end

function SE.All(root, pCb)
    local scripts = {}
    for _, d in ipairs(U.Desc(root)) do
        if d:IsA("LuaSourceContainer") then table.insert(scripts, d) end
    end

    local total = #scripts
    local results, methods = {}, {}
    local ok, fail = 0, 0

    for i, s in ipairs(scripts) do
        local src, method = SE.Decompile(s)
        results[s] = src
        methods[s] = method

        if method ~= "failed" then ok = ok + 1 else fail = fail + 1 end

        if pCb then
            pCb(i, total, s.Name, s.ClassName, ok, fail, method)
        end
        U.Yield(i)
    end

    return results, methods, ok, fail, total
end

function SE.SaveBytecodes(fileName)
    if not writefile then return end
    if not next(BytecodeCache) then return end

    local report = {"-- BaoSave Bytecode Report\n"}
    for path, bc in pairs(BytecodeCache) do
        table.insert(report, string.format("-- %s: %d bytes\n", path, #bc))
    end

    pcall(function()
        writefile(fileName or (Config.Out .. "_bytecodes.txt"), table.concat(report))
    end)
end

-- ============================================================
-- 12-16. EXTRACTION ENGINES (Unified)
-- ============================================================
local function ExtractPred(root, pred, pCb)
    local items, desc = {}, U.Desc(root)
    local found = 0
    for i, d in ipairs(desc) do
        local m = false
        pcall(function() m = pred(d) end)
        if m then
            local c = PDB.Deep(d)
            if c then table.insert(items, {obj=c, path=U.Path(d)}) found = found + 1 end
        end
        if i % 200 == 0 then U.Yield(i) Mem.Check() end
    end
    if pCb then pCb(#desc, #desc, found) end
    return items, found
end

-- ============================================================
-- 17. TERRAIN VOXEL ENGINE (Adaptive Multi-Resolution)
-- ============================================================
local TE = {}

function TE.Clone()
    local t = workspace:FindFirstChildOfClass("Terrain")
    return t and U.Clone(t)
end

function TE.CopyProps(s, d)
    if not s or not d then return end
    for _, p in ipairs({"WaterColor","WaterReflectance","WaterTransparency","WaterWaveSize","WaterWaveSpeed","Decoration","GrassLength"}) do
        pcall(function() d[p] = s[p] end)
    end
    pcall(function() d.MaterialColors = s.MaterialColors end)
end

function TE.ScanBounds(terrain)
    local bounds = {min = Vector3.new(0,0,0), max = Vector3.new(0,0,0), hasData = false}
    local testSizes = {4096, 2048, 1024, 512, 256}

    for _, sz in ipairs(testSizes) do
        local half = sz / 2
        local ok, hasData = pcall(function()
            local r = Region3.new(Vector3.new(-half,-half,-half), Vector3.new(half,half,half)):ExpandToGrid(4)
            local m = terrain:ReadVoxels(r, 4)
            for _, l in ipairs(m) do
                for _, row in ipairs(l) do
                    for _, mt in ipairs(row) do
                        if mt ~= Enum.Material.Air then return true end
                    end
                end
            end
            return false
        end)
        if ok and hasData then
            bounds.min = Vector3.new(-half,-half,-half)
            bounds.max = Vector3.new(half,half,half)
            bounds.hasData = true
            break
        end
    end

    return bounds
end

function TE.AdaptiveCopy(src, dst, pCb)
    if not src or not dst then return false, 0 end

    -- Try single full copy
    local fullOk = false
    pcall(function()
        local r = Region3.new(Vector3.new(-16384,-16384,-16384), Vector3.new(16384,16384,16384)):ExpandToGrid(4)
        local m, o = src:ReadVoxels(r, 4)
        dst:WriteVoxels(r, 4, m, o)
        fullOk = true
    end)
    if fullOk then
        if pCb then pCb(1,1,1) end
        return true, 1
    end

    -- Adaptive: scan bounds first
    local bounds = TE.ScanBounds(src)
    if not bounds.hasData then
        -- Try standard chunked
        local cs = Config.Perf.Chunk
        local range = 2048
        local half = range / 2
        local total = math.ceil(range/cs)^3
        local done, dataChunks = 0, 0

        for x = -half, half-1, cs do
            for y = -half, half-1, cs do
                for z = -half, half-1, cs do
                    pcall(function()
                        local r = Region3.new(Vector3.new(x,y,z), Vector3.new(x+cs,y+cs,z+cs)):ExpandToGrid(4)
                        local m, o = src:ReadVoxels(r, 4)
                        local has = false
                        for _, l in ipairs(m) do for _, row in ipairs(l) do for _, mt in ipairs(row) do if mt ~= Enum.Material.Air then has = true break end end if has then break end end if has then break end end
                        if has then dst:WriteVoxels(r, 4, m, o) dataChunks = dataChunks + 1 end
                    end)
                    done = done + 1
                    if pCb and done % 8 == 0 then pCb(done, total, dataChunks) end
                    if done % 4 == 0 then RS.RenderStepped:Wait() end
                end
            end
        end
        return true, dataChunks
    end

    -- Multi-resolution: coarse pass then fine pass
    local dataChunks = 0
    local coarseSize = 512
    local fineSize = Config.Perf.Chunk
    local half = 2048

    -- Coarse pass: find occupied regions
    local occupied = {}
    local coarseTotal = math.ceil(half*2/coarseSize)^3
    local coarseDone = 0

    for x = -half, half-1, coarseSize do
        for y = -half, half-1, coarseSize do
            for z = -half, half-1, coarseSize do
                local has = false
                pcall(function()
                    local r = Region3.new(Vector3.new(x,y,z), Vector3.new(x+coarseSize,y+coarseSize,z+coarseSize)):ExpandToGrid(4)
                    local m = src:ReadVoxels(r, 4)
                    for _, l in ipairs(m) do for _, row in ipairs(l) do for _, mt in ipairs(row) do if mt ~= Enum.Material.Air then has = true break end end if has then break end end if has then break end end
                end)
                if has then table.insert(occupied, {x=x,y=y,z=z}) end
                coarseDone = coarseDone + 1
                if coarseDone % 4 == 0 then RS.RenderStepped:Wait() end
            end
        end
    end

    -- Fine pass: copy only occupied regions
    local fineTotal = #occupied * math.ceil(coarseSize/fineSize)^3
    local fineDone = 0

    for _, region in ipairs(occupied) do
        for x = region.x, region.x+coarseSize-1, fineSize do
            for y = region.y, region.y+coarseSize-1, fineSize do
                for z = region.z, region.z+coarseSize-1, fineSize do
                    pcall(function()
                        local r = Region3.new(Vector3.new(x,y,z), Vector3.new(x+fineSize,y+fineSize,z+fineSize)):ExpandToGrid(4)
                        local m, o = src:ReadVoxels(r, 4)
                        local has = false
                        for _, l in ipairs(m) do for _, row in ipairs(l) do for _, mt in ipairs(row) do if mt ~= Enum.Material.Air then has = true break end end if has then break end end if has then break end end
                        if has then dst:WriteVoxels(r, 4, m, o) dataChunks = dataChunks + 1 end
                    end)
                    fineDone = fineDone + 1
                    if pCb and fineDone % 6 == 0 then pCb(fineDone, fineTotal, dataChunks) end
                    if fineDone % 3 == 0 then RS.RenderStepped:Wait() end
                end
            end
        end
    end

    return true, dataChunks
end

-- ============================================================
-- 18. LIGHTING CAPTURER
-- ============================================================
local LE = {}
function LE.All(pCb)
    local L = Svc.Lighting
    if not L then return {}, {} end
    local cfg = {}
    for _, p in ipairs({"Ambient","Brightness","ColorShift_Bottom","ColorShift_Top","EnvironmentDiffuseScale","EnvironmentSpecularScale","GlobalShadows","OutdoorAmbient","ShadowSoftness","ClockTime","GeographicLatitude","TimeOfDay","ExposureCompensation","Technology"}) do
        pcall(function() cfg[p] = L[p] end)
    end
    local fx = {}
    for _, ch in ipairs(U.Ch(L)) do local c = PDB.Deep(ch) if c then table.insert(fx, c) end end
    if pCb then pCb(100, 100, #fx) end
    return cfg, fx
end

-- ============================================================
-- 19. INSTANCE FORGE (Ultimate Reconstruction)
-- ============================================================
local Forge = {}

function Forge.Build(orig)
    if not orig or U.IsIgnC(orig.ClassName) then return nil end
    local c = U.Clone(orig)
    if c then PDB.Copy(orig, c) return c end
    local ok, inst = pcall(Instance.new, orig.ClassName)
    if not ok or not inst then return nil end
    pcall(function() inst.Name = orig.Name end)
    PDB.Copy(orig, inst)
    for _, child in ipairs(U.Ch(orig)) do
        local cc = Forge.Build(child)
        if cc then pcall(function() cc.Parent = inst end) end
    end
    return inst
end

function Forge.DeepClone(orig)
    local c = PDB.Deep(orig)
    if not c then c = Forge.Build(orig) end
    if c and Config.Perf.ResolveRefs then
        RefResolver.ResolveAll(c)
    end
    return c
end

-- ============================================================
-- 20. HIERARCHY VALIDATOR
-- ============================================================
local Validator = {}

function Validator.Validate(cloned, original)
    local report = {valid=true, missing={}, extra={}, propMismatch={}}

    pcall(function()
        local origCount = U.Count(original)
        local clonedCount = U.Count(cloned)

        if clonedCount < origCount * 0.5 then
            report.valid = false
            table.insert(report.missing, string.format("Missing %d instances (%d vs %d)", origCount - clonedCount, clonedCount, origCount))
        end
    end)

    return report
end

function Validator.CountClasses(root)
    local counts = {}
    pcall(function()
        for _, d in ipairs(U.Desc(root)) do
            counts[d.ClassName] = (counts[d.ClassName] or 0) + 1
        end
    end)
    return counts
end

-- ============================================================
-- 21. DECOMPILER CORE (35 methods)
-- ============================================================
local Core = {}

local Stats = {
    Total=0, Copied=0, Failed=0,
    Scripts=0, ScriptsFail=0,
    Meshes=0, Textures=0, Sounds=0,
    Anims=0, Particles=0, Physics=0,
    UIs=0, Packages=0, Terrain=0,
    NilInst=0, Hidden=0,
    StartTime=0, PeakMem=0,
    ScriptMethods={}, Validated=0,
}

function Core.Reset()
    for k in pairs(Stats) do
        if type(Stats[k]) == "number" then Stats[k] = 0
        elseif type(Stats[k]) == "table" then Stats[k] = {} end
    end
    Stats.StartTime = tick()
    Mem.peakKB = 0
end

function Core.Stats()
    Stats.Elapsed = tick() - Stats.StartTime
    Stats.PeakMem = Mem.peakKB
    return Stats
end

local function CloneChild(child)
    local c = Forge.DeepClone(child)
    if c then
        Signals.OnInstanceCopied:Fire(child, c)
    end
    return c
end

-- 1. Full Game 100%
function Core.FullGame(pCb)
    Core.Reset()
    local gathered = {}
    local svcs = Config.AllServices
    local grandTotal = 0
    for _, s in ipairs(svcs) do
        local svc = U.Svc(s)
        if svc and not U.IsIgnS(s) then grandTotal = grandTotal + U.Count(svc) + 1 end
    end
    Stats.Total = grandTotal
    local counter = 0

    for _, sName in ipairs(svcs) do
        if not U.IsIgnS(sName) then
            Signals.OnPhaseStart:Fire("Service: " .. sName)
            local svc = U.Svc(sName)
            if svc then
                for _, child in ipairs(U.Ch(svc)) do
                    if not (sName == "Workspace" and (child:IsA("Terrain") or child:IsA("Camera"))) and not U.IsIgnC(child.ClassName) then
                        local c = CloneChild(child)
                        if c then
                            table.insert(gathered, {obj=c, svc=sName, path=U.Path(child)})
                            Stats.Copied = Stats.Copied + 1 + U.Count(child)
                        else
                            -- Aggressive retry: rebuild from scratch
                            if Config.Perf.RebuildFailed then
                                local rebuilt = Forge.Build(child)
                                if rebuilt then
                                    table.insert(gathered, {obj=rebuilt, svc=sName, path=U.Path(child)})
                                    Stats.Copied = Stats.Copied + 1
                                else
                                    Stats.Failed = Stats.Failed + 1
                                end
                            else
                                Stats.Failed = Stats.Failed + 1
                            end
                        end
                        counter = counter + 1
                        if pCb then pCb((counter/math.max(grandTotal,1))*100, sName, child.Name, child.ClassName) end
                        U.Yield(counter)
                        Mem.Check()
                    end
                end
            end
            Signals.OnPhaseEnd:Fire("Service: " .. sName)
        end
    end
    return gathered
end

-- 2. All Models 100%
function Core.AllModels(pCb)
    Core.Reset()
    local models = {}
    local targets = {"Workspace","ReplicatedStorage","ServerStorage","StarterGui","StarterPack","StarterPlayer","Lighting","ReplicatedFirst","ServerScriptService"}
    local allItems = {}

    for _, sName in ipairs(targets) do
        local svc = U.Svc(sName)
        if svc then
            for _, d in ipairs(U.Desc(svc)) do
                if U.IsA(d, Config.ModelClasses) and not d:IsA("Terrain") then
                    table.insert(allItems, {inst=d, svc=sName})
                end
            end
        end
    end

    -- Also scan nil instances
    if getnilinstances then
        pcall(function()
            for _, inst in ipairs(getnilinstances()) do
                if U.IsA(inst, Config.ModelClasses) then
                    table.insert(allItems, {inst=inst, svc="Nil"})
                end
            end
        end)
    end

    Stats.Total = #allItems
    for i, item in ipairs(allItems) do
        local c = CloneChild(item.inst)
        if c then
            table.insert(models, {obj=c, svc=item.svc, path=U.Path(item.inst), class=item.inst.ClassName})
            Stats.Copied = Stats.Copied + 1
        elseif Config.Perf.RebuildFailed then
            local rebuilt = Forge.Build(item.inst)
            if rebuilt then
                table.insert(models, {obj=rebuilt, svc=item.svc, path=U.Path(item.inst), class=item.inst.ClassName})
                Stats.Copied = Stats.Copied + 1
            else Stats.Failed = Stats.Failed + 1 end
        else Stats.Failed = Stats.Failed + 1 end
        if pCb then pCb((i/#allItems)*100, item.svc, item.inst.Name, item.inst.ClassName) end
        U.Yield(i) Mem.Check()
    end
    return models
end

-- 3-5 Model variants
function Core.WorkspaceModels(pCb)
    Core.Reset()
    local models = {}
    local ch = U.Ch(workspace)
    Stats.Total = #ch
    for i, child in ipairs(ch) do
        if not child:IsA("Terrain") and not child:IsA("Camera") and not U.IsIgnC(child.ClassName) then
            local c = CloneChild(child)
            if c then table.insert(models, c) Stats.Copied = Stats.Copied + 1 + U.Count(child)
            elseif Config.Perf.RebuildFailed then
                local rb = Forge.Build(child)
                if rb then table.insert(models, rb) Stats.Copied = Stats.Copied + 1
                else Stats.Failed = Stats.Failed + 1 end
            else Stats.Failed = Stats.Failed + 1 end
        end
        if pCb then pCb((i/#ch)*100, "Workspace", child.Name, child.ClassName) end
        U.Yield(i) Mem.Check()
    end
    return models
end

function Core.DeepModels(pCb)
    Core.Reset()
    local results = {}
    local function scan(parent, depth)
        for _, child in ipairs(U.Ch(parent)) do
            if child:IsA("Model") then
                local c = CloneChild(child)
                if c then table.insert(results, {obj=c, depth=depth, path=U.Path(child)}) Stats.Copied = Stats.Copied + 1 end
            end
            if not child:IsA("Terrain") then scan(child, depth+1) end
            Stats.Total = Stats.Total + 1
            if pCb and Stats.Total % 50 == 0 then pCb(0, "Depth:"..depth, child.Name, child.ClassName) end
            U.Yield(Stats.Total)
        end
    end
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.Svc(sName)
        if svc and not U.IsIgnS(sName) then scan(svc, 0) end
    end
    return results
end

-- 6. Terrain 100%
function Core.Terrain(pCb)
    Core.Reset()
    Signals.OnPhaseStart:Fire("Terrain")
    local src = workspace:FindFirstChildOfClass("Terrain")
    if not src then return nil end
    local dst = TE.Clone()
    if dst then
        TE.CopyProps(src, dst)
        TE.AdaptiveCopy(src, dst, function(done, total, chunks)
            Stats.Terrain = chunks
            if pCb then pCb((done/math.max(total,1))*100, "Terrain", string.format("Chunk %d/%d", done, total), chunks.." data") end
        end)
    end
    Signals.OnPhaseEnd:Fire("Terrain")
    return dst
end

-- 7. Scripts
function Core.Scripts(pCb)
    Core.Reset()
    Signals.OnPhaseStart:Fire("Scripts")
    local all = {}
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.Svc(sName)
        if svc then for _, d in ipairs(U.Desc(svc)) do if d:IsA("LuaSourceContainer") then table.insert(all, d) end end end
    end
    -- Also scan nil
    if getnilinstances then
        pcall(function()
            for _, inst in ipairs(getnilinstances()) do
                if inst:IsA("LuaSourceContainer") then table.insert(all, inst) end
            end
        end)
    end
    -- Also loaded modules
    if getloadedmodules then
        pcall(function()
            for _, mod in ipairs(getloadedmodules()) do
                local found = false
                for _, existing in ipairs(all) do if existing == mod then found = true break end end
                if not found then table.insert(all, mod) end
            end
        end)
    end

    Stats.Total = #all
    local results, methods = {}, {}
    for i, s in ipairs(all) do
        local src, method = SE.Decompile(s)
        results[s] = src methods[s] = method
        if method ~= "failed" then Stats.Scripts = Stats.Scripts + 1 else Stats.ScriptsFail = Stats.ScriptsFail + 1 end
        Stats.ScriptMethods[method] = (Stats.ScriptMethods[method] or 0) + 1
        if pCb then pCb((i/#all)*100, "Decompiling", s.Name, string.format("%s [%s] OK:%d FAIL:%d", s.ClassName, method, Stats.Scripts, Stats.ScriptsFail)) end
        U.Yield(i)
    end
    Signals.OnPhaseEnd:Fire("Scripts")
    return results, methods
end

-- 8-15 Type gatherers
local function GatherType(extractPred, statKey, pCb)
    Core.Reset()
    local all = {}
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.Svc(sName)
        if svc then local items, n = ExtractPred(svc, extractPred) U.Merge(all, items) Stats[statKey] = Stats[statKey] + n end
    end
    if pCb then pCb(100, statKey, Stats[statKey].." found", "") end
    return all
end

function Core.Sounds(pCb) return GatherType(function(d) return d:IsA("Sound") or d:IsA("SoundGroup") or d:IsA("SoundEffect") end, "Sounds", pCb) end
function Core.Anims(pCb) return GatherType(function(d) return d:IsA("Animation") or d:IsA("AnimationController") or d:IsA("Animator") or d:IsA("KeyframeSequence") or d:IsA("Keyframe") or d:IsA("Pose") end, "Anims", pCb) end
function Core.Particles(pCb) return GatherType(function(d) return U.IsA(d, Config.EffectClasses) end, "Particles", pCb) end
function Core.Meshes(pCb) return GatherType(function(d) return d:IsA("MeshPart") or d:IsA("SpecialMesh") or d:IsA("FileMesh") end, "Meshes", pCb) end
function Core.Textures(pCb) return GatherType(function(d) return d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance") end, "Textures", pCb) end
function Core.PhysicsData(pCb) return GatherType(function(d) return U.IsA(d, Config.ConstraintClasses) or d:IsA("BodyMover") or d:IsA("JointInstance") end, "Physics", pCb) end
function Core.UIs(pCb) return GatherType(function(d) return d:IsA("LayerCollector") or d:IsA("BillboardGui") or d:IsA("SurfaceGui") end, "UIs", pCb) end
function Core.Pkgs(pCb) return GatherType(function(d) return d:IsA("PackageLink") end, "Packages", pCb) end

-- 16
function Core.Lighting(pCb) return LE.All(pCb) end

-- 17-30 Additional gatherers
function Core.NilInst(pCb)
    Core.Reset()
    local results = {}
    if getnilinstances then
        pcall(function()
            local nils = getnilinstances()
            Stats.Total = #nils
            for i, inst in ipairs(nils) do
                if not U.IsIgnC(inst.ClassName) then
                    local c = CloneChild(inst)
                    if c then table.insert(results, c) Stats.NilInst = Stats.NilInst + 1 end
                end
                if pCb and i % 10 == 0 then pCb((i/#nils)*100, "Nil", inst.Name, inst.ClassName) end
                U.Yield(i)
            end
        end)
    end
    return results
end

function Core.HiddenProps(pCb)
    Core.Reset()
    local hidden = {}
    if gethiddenproperties or getproperties or gethiddenproperty then
        for _, sName in ipairs(Config.AllServices) do
            local svc = U.Svc(sName)
            if svc then
                for i, d in ipairs(U.Desc(svc)) do
                    pcall(function()
                        local props
                        if gethiddenproperties then props = gethiddenproperties(d)
                        elseif getproperties then props = getproperties(d) end
                        if props and next(props) then hidden[U.Path(d)] = props Stats.Hidden = Stats.Hidden + 1 end
                    end)
                    U.Yield(i)
                end
            end
        end
    end
    if pCb then pCb(100, "Hidden", Stats.Hidden.." found", "") end
    return hidden
end

function Core.Camera() local cam = workspace.CurrentCamera return cam and U.Clone(cam) end

function Core.Materials(pCb)
    Core.Reset()
    local mats = {}
    local ms = U.Svc("MaterialService")
    if ms then for _, ch in ipairs(U.Ch(ms)) do local c = PDB.Deep(ch) if c then table.insert(mats, c) end end end
    if pCb then pCb(100, "Materials", #mats.." variants", "") end
    return mats
end

function Core.Service(svcName, pCb)
    Core.Reset()
    local results = {}
    local svc = U.Svc(svcName)
    if not svc then return results end
    local ch = U.Ch(svc)
    Stats.Total = #ch
    for i, child in ipairs(ch) do
        if not U.IsIgnC(child.ClassName) then
            local c = CloneChild(child)
            if c then table.insert(results, c) Stats.Copied = Stats.Copied + 1 end
        end
        if pCb then pCb((i/#ch)*100, svcName, child.Name, child.ClassName) end
        U.Yield(i)
    end
    return results
end

function Core.ByClass(cn, pCb)
    Core.Reset()
    local results = {}
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.Svc(sName)
        if svc then
            for _, d in ipairs(U.Desc(svc)) do
                local m = false
                pcall(function() m = d.ClassName == cn or d:IsA(cn) end)
                if m then local c = PDB.Deep(d) if c then table.insert(results, c) Stats.Copied = Stats.Copied + 1 end end
            end
        end
    end
    if pCb then pCb(100, cn, Stats.Copied.." found", "") end
    return results
end

function Core.Characters(pCb)
    Core.Reset()
    local chars = {}
    for _, p in ipairs(Svc.Players:GetPlayers()) do
        if p.Character then
            local c = CloneChild(p.Character)
            if c then c.Name = p.Name.."_Character" table.insert(chars, c) Stats.Copied = Stats.Copied + 1 end
        end
    end
    if pCb then pCb(100, "Characters", #chars.." found", "") end
    return chars
end

function Core.Accessories(pCb)
    Core.Reset()
    local items = {}
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.Svc(sName)
        if svc then
            for _, d in ipairs(U.Desc(svc)) do
                if d:IsA("Accessory") or d:IsA("Tool") or d:IsA("HopperBin") then
                    local c = PDB.Deep(d) if c then table.insert(items, {obj=c, path=U.Path(d)}) Stats.Copied = Stats.Copied + 1 end
                end
            end
        end
    end
    if pCb then pCb(100, "Accessories", Stats.Copied.." found", "") end
    return items
end

function Core.Clothing(pCb)
    Core.Reset()
    local items = {}
    for _, sName in ipairs(Config.AllServices) do
        local svc = U.Svc(sName)
        if svc then
            for _, d in ipairs(U.Desc(svc)) do
                if d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("BodyColors") or d:IsA("CharacterMesh") or d:IsA("HumanoidDescription") then
                    local c = PDB.Deep(d) if c then table.insert(items, c) Stats.Copied = Stats.Copied + 1 end
                end
            end
        end
    end
    if pCb then pCb(100, "Clothing", Stats.Copied, "") end
    return items
end

function Core.Gui3D(pCb) return Core.ByClass("BillboardGui", pCb) end
function Core.Highlights(pCb) return Core.ByClass("Highlight", pCb) end
function Core.Prompts(pCb) return Core.ByClass("ProximityPrompt", pCb) end
function Core.Bones(pCb) return Core.ByClass("Bone", pCb) end
function Core.Wraps(pCb) return GatherType(function(d) return d:IsA("WrapTarget") or d:IsA("WrapLayer") end, "Copied", pCb) end
function Core.Remotes(pCb) return GatherType(function(d) return d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("BindableEvent") or d:IsA("BindableFunction") end, "Copied", pCb) end
function Core.Values(pCb) return GatherType(function(d) return d:IsA("ValueBase") end, "Copied", pCb) end
function Core.Selected(inst, pCb) if not inst then return nil end Core.Reset() local c = CloneChild(inst) if c then Stats.Copied = 1 + U.Count(inst) end if pCb then pCb(100, "Selected", inst.Name, inst.ClassName) end return c end

-- 35. Everything
function Core.Everything(pCb)
    Core.Reset()
    local data = {game={}, terrain=nil, scripts={}, scriptMethods={}, lighting={}, effects={}, camera=nil, materials={}, nilInst={}, bytecodes={}}

    local phases = {
        {n="Game Tree",    w=28, f=function(cb) data.game = Core.FullGame(cb) end},
        {n="Scripts",      w=22, f=function(cb) data.scripts, data.scriptMethods = Core.Scripts(cb) end},
        {n="Terrain",      w=14, f=function(cb) data.terrain = Core.Terrain(cb) end},
        {n="Lighting",     w=4,  f=function(cb) data.lighting, data.effects = Core.Lighting(cb) end},
        {n="Camera",       w=1,  f=function() data.camera = Core.Camera() end},
        {n="Materials",    w=3,  f=function(cb) data.materials = Core.Materials(cb) end},
        {n="Nil Instances",w=8,  f=function(cb) data.nilInst = Core.NilInst(cb) end},
        {n="Bytecodes",    w=2,  f=function() SE.SaveBytecodes() end},
    }

    local tw = 0
    for _, p in ipairs(phases) do tw = tw + p.w end
    local acc = 0

    for pi, phase in ipairs(phases) do
        Signals.OnPhaseStart:Fire(phase.n)
        local ps = acc
        pcall(function()
            phase.f(function(pct, s1, s2, s3)
                local gp = ps + (pct/100)*(phase.w/tw)*100
                if pCb then pCb(gp, string.format("[%d/%d] %s", pi, #phases, phase.n), s2 or "", s3 or "") end
            end)
        end)
        acc = acc + (phase.w/tw)*100
        Signals.OnPhaseEnd:Fire(phase.n)
    end

    return data
end

-- ============================================================
-- 22. EXPORTER (12 methods)
-- ============================================================
local Exp = {}

function Exp.Save(fileName, opts)
    fileName = fileName or (Config.Out..".rbxl")
    opts = opts or {}

    local methods = {
        function()
            if not saveinstance then return false end
            saveinstance({FileName=fileName, DecompileMode=opts.decompileMode or "custom", NilInstances=opts.nilInstances~=false, RemovePlayerCharacters=true, SavePlayers=false, ExtraInstances=opts.extra or {}, ShowStatus=true, mode="full", Timeout=Config.Perf.Timeout, Decompile=opts.decompile~=false, SaveNonCreatable=true, IgnoreDefaultProperties=false, IsolateStarterPlayer=false, IgnoreList=Config.IgnoreServices, IsolateLocalPlayer=true, SaveBytecode=true, DecompileTimeout=30})
            return true
        end,
        function() if not saveinstance then return false end saveinstance(game, fileName) return true end,
        function() if not (syn and syn.saveinstance) then return false end syn.saveinstance({FileName=fileName,Decompile=true,NilInstances=true,RemovePlayers=true,SaveNonCreatable=true,ShowStatus=true,Timeout=Config.Perf.Timeout,IgnoreList=Config.IgnoreServices}) return true end,
        function() if not (fluxus and fluxus.saveinstance) then return false end fluxus.saveinstance(fileName) return true end,
        function() if not KRNL_LOADED then return false end saveinstance(game, fileName) return true end,
        function() if not saveplace then return false end saveplace(fileName) return true end,
        function() if not (writefile and game.Save) then return false end game:Save(fileName) return true end,
        function() local fn = savegame or saveinstance if not fn then return false end fn(game, fileName) return true end,
        function() if not (Hydrogen and Hydrogen.saveinstance) then return false end Hydrogen.saveinstance(fileName) return true end,
        function() if not (getgenv and getgenv().Delta and saveinstance) then return false end saveinstance({FileName=fileName, Decompile=true}) return true end,
        function() if not (wave and wave.saveinstance) then return false end wave.saveinstance(fileName) return true end,
        function() if not (Arceus and saveinstance) then return false end saveinstance(game, fileName) return true end,
    }

    for i, m in ipairs(methods) do
        local ok, r = pcall(m)
        if ok and r then U.Log("EXPORT", "Method "..i..": "..fileName) return true, nil end
    end
    return false, "No save method"
end

function Exp.Report(s)
    return string.format("Inst:%s Scripts:%d/%d Failed:%d Terrain:%d Time:%s Mem:%sKB",
        U.FmtN(s.Copied), s.Scripts, s.Scripts+s.ScriptsFail, s.Failed, s.Terrain,
        U.FmtT(s.Elapsed or 0), U.FmtN(s.PeakMem or 0))
end

-- ============================================================
-- 23. UI SYSTEM
-- ============================================================
local GUI = {}
local GR = {}

function GUI.New(c,p,ch) local i=Instance.new(c) for k,v in pairs(p or{}) do pcall(function() i[k]=v end) end for _,x in ipairs(ch or{}) do x.Parent=i end return i end
function GUI.Corner(p,r) return GUI.New("UICorner",{CornerRadius=UDim.new(0,r or Config.Theme.Rad),Parent=p}) end
function GUI.Stroke(p,c,t,a) return GUI.New("UIStroke",{Color=c or Config.Theme.C.Border,Thickness=t or 1,Transparency=a or 0.5,Parent=p}) end
function GUI.Grad(p,c1,c2,rot) return GUI.New("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,c1),ColorSequenceKeypoint.new(1,c2)}),Rotation=rot or 0,Parent=p}) end

function GUI.Drag(f,h)
    local dr,di,ds,sp
    h.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dr=true ds=i.Position sp=f.Position i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dr=false end end) end end)
    h.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then di=i end end)
    UIS.InputChanged:Connect(function(i) if i==di and dr then local d=i.Position-ds f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end)
end

function GUI.Btn(text, icon, color, hc, order, cb)
    local T,C = Config.Theme, Config.Theme.C
    color = color or C.Btn hc = hc or C.BtnH
    local btn = GUI.New("TextButton",{Size=UDim2.new(1,0,0,T.BtnH),BackgroundColor3=color,Text="",AutoButtonColor=false,BorderSizePixel=0,LayoutOrder=order or 0})
    GUI.Corner(btn,10)
    GUI.Stroke(btn,C.Sep,1,0.6)
    local bar = GUI.New("Frame",{Size=UDim2.new(0,3,0.4,0),Position=UDim2.new(0,0,0.3,0),BackgroundColor3=color==C.Btn and C.A1 or color,BorderSizePixel=0,BackgroundTransparency=1,Parent=btn})
    GUI.Corner(bar,2)
    local icF = GUI.New("Frame",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(0,8,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.93,BorderSizePixel=0,Parent=btn})
    GUI.Corner(icF,13)
    GUI.New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=icon or"📦",Font=T.F1,TextSize=13,TextColor3=C.Txt,Parent=icF})
    GUI.New("TextLabel",{Size=UDim2.new(1,-48,1,0),Position=UDim2.new(0,42,0,0),BackgroundTransparency=1,Text=text,TextColor3=C.Txt2,Font=T.F2,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,Parent=btn})
    GUI.New("TextLabel",{Size=UDim2.new(0,16,1,0),Position=UDim2.new(1,-22,0,0),BackgroundTransparency=1,Text="›",TextColor3=C.Dim,Font=T.F1,TextSize=16,Parent=btn})
    btn.MouseEnter:Connect(function() TS:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=hc}):Play() TS:Create(bar,TweenInfo.new(0.12),{BackgroundTransparency=0}):Play() end)
    btn.MouseLeave:Connect(function() TS:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=color}):Play() TS:Create(bar,TweenInfo.new(0.12),{BackgroundTransparency=1}):Play() end)
    if cb then btn.MouseButton1Click:Connect(function() TS:Create(btn,TweenInfo.new(0.03),{BackgroundColor3=C.A1}):Play() task.wait(0.03) TS:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=color}):Play() pcall(cb) end) end
    return btn
end

function GUI.Sep(text, order)
    local C = Config.Theme.C
    local s = GUI.New("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,LayoutOrder=order or 0})
    GUI.New("Frame",{Size=UDim2.new(1,-10,0,1),Position=UDim2.new(0,5,0,10),BackgroundColor3=C.Sep,BackgroundTransparency=0.5,BorderSizePixel=0,Parent=s})
    local badge = GUI.New("Frame",{Size=UDim2.new(0,#(text or"")*6.5+20,0,18),Position=UDim2.new(0,10,0,2),BackgroundColor3=C.Glass,BorderSizePixel=0,Parent=s})
    GUI.Corner(badge,5) GUI.Stroke(badge,C.Sep,1,0.6)
    GUI.New("TextLabel",{Size=UDim2.new(1,-6,1,0),Position=UDim2.new(0,3,0,0),BackgroundTransparency=1,Text=text or"",TextColor3=C.Sub,Font=Config.Theme.F2,TextSize=9,Parent=badge})
    return s
end

function GUI.Build()
    local ex = PGui:FindFirstChild("BaoSaveGui") if ex then ex:Destroy() end
    local T,C = Config.Theme, Config.Theme.C

    local sg = GUI.New("ScreenGui",{Name="BaoSaveGui",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=PGui})
    local mf = GUI.New("Frame",{Name="Main",Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=C.Bg,BorderSizePixel=0,ClipsDescendants=true,Parent=sg})
    GUI.Corner(mf,16)
    local gs = GUI.New("UIStroke",{Color=C.A1,Thickness=2,Transparency=0.3,Parent=mf})
    GUI.New("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.A1),ColorSequenceKeypoint.new(0.33,C.A2),ColorSequenceKeypoint.new(0.66,C.A5),ColorSequenceKeypoint.new(1,C.A3)}),Rotation=45,Parent=gs})
    GUI.New("ImageLabel",{Size=UDim2.new(1,70,1,70),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,Image="rbxassetid://5554236805",ImageColor3=Color3.new(0,0,0),ImageTransparency=0.3,ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(23,23,277,277),ZIndex=-1,Parent=mf})

    local tb = GUI.New("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=C.Bar,BorderSizePixel=0,Parent=mf})
    GUI.Corner(tb,16) GUI.New("Frame",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,1,-18),BackgroundColor3=C.Bar,BorderSizePixel=0,Parent=tb})
    local tl = GUI.New("Frame",{Size=UDim2.new(0.5,0,0,2),Position=UDim2.new(0.25,0,0,0),BackgroundColor3=C.A1,BorderSizePixel=0,Parent=tb}) GUI.Corner(tl,1) GUI.Grad(tl,C.A1,C.A5)
    GUI.New("TextLabel",{Size=UDim2.new(0,20,0,20),Position=UDim2.new(0,14,0,16),BackgroundTransparency=1,Text="⚡",Font=T.F1,TextSize=18,TextColor3=C.A1,Parent=tb})
    GUI.New("TextLabel",{Size=UDim2.new(1,-130,0,18),Position=UDim2.new(0,38,0,10),BackgroundTransparency=1,Text="BaoSaveInstance",TextColor3=C.Txt,Font=T.F1,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,Parent=tb})
    GUI.New("TextLabel",{Size=UDim2.new(1,-130,0,12),Position=UDim2.new(0,38,0,30),BackgroundTransparency=1,Text="v"..Config.Version.." "..Config.Build.." | "..ExecDetect.Name(),TextColor3=C.Dim,Font=T.F3,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,Parent=tb})

    local minimized = false
    local cf
    local mnB = GUI.New("TextButton",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-72,0,12),BackgroundColor3=C.Btn,BackgroundTransparency=0.3,Text="─",TextColor3=C.Sub,Font=T.F1,TextSize=11,BorderSizePixel=0,Parent=tb}) GUI.Corner(mnB,8)
    local clB = GUI.New("TextButton",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-40,0,12),BackgroundColor3=C.Red,BackgroundTransparency=0.2,Text="✕",TextColor3=C.Txt,Font=T.F1,TextSize=10,BorderSizePixel=0,Parent=tb}) GUI.Corner(clB,8)

    cf = GUI.New("Frame",{Name="Content",Size=UDim2.new(1,0,1,-52),Position=UDim2.new(0,0,0,52),BackgroundTransparency=1,ClipsDescendants=true,Parent=mf})
    local sf = GUI.New("ScrollingFrame",{Name="Scroll",Size=UDim2.new(1,-10,1,-175),Position=UDim2.new(0,5,0,3),BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=C.A1,ScrollBarImageTransparency=0.3,BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=cf})
    GUI.New("UIListLayout",{Padding=UDim.new(0,T.Pad),HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,Parent=sf})
    GUI.New("UIPadding",{PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,4),PaddingLeft=UDim.new(0,2),PaddingRight=UDim.new(0,2),Parent=sf})

    local pp = GUI.New("Frame",{Name="Prog",Size=UDim2.new(1,-10,0,165),Position=UDim2.new(0,5,1,-168),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=cf})
    GUI.Corner(pp,12) GUI.Stroke(pp,C.Border,1,0.5)
    local ppG = GUI.New("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.A1,BackgroundTransparency=0.5,BorderSizePixel=0,Parent=pp})

    local stL = GUI.New("TextLabel",{Size=UDim2.new(0.6,-8,0,14),Position=UDim2.new(0,8,0,6),BackgroundTransparency=1,Text="⏳ Ready",TextColor3=C.Sub,Font=T.F2,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,Parent=pp})
    local etL = GUI.New("TextLabel",{Size=UDim2.new(0.4,-8,0,14),Position=UDim2.new(0.6,0,0,6),BackgroundTransparency=1,Text="",TextColor3=C.Dim,Font=T.F3,TextSize=9,TextXAlignment=Enum.TextXAlignment.Right,Parent=pp})
    local pbBg = GUI.New("Frame",{Size=UDim2.new(1,-16,0,14),Position=UDim2.new(0,8,0,24),BackgroundColor3=C.PBg,BorderSizePixel=0,ClipsDescendants=true,Parent=pp}) GUI.Corner(pbBg,3)
    local pbF = GUI.New("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=C.PFl,BorderSizePixel=0,Parent=pbBg}) GUI.Corner(pbF,3) GUI.Grad(pbF,C.A1,C.A2)
    local shm = GUI.New("Frame",{Size=UDim2.new(0.15,0,1,0),Position=UDim2.new(-0.15,0,0,0),BackgroundTransparency=0.8,BorderSizePixel=0,Parent=pbF}) GUI.Grad(shm,Color3.new(1,1,1),Color3.new(1,1,1))
    local pcL = GUI.New("TextLabel",{Size=UDim2.new(0.25,-4,0,14),Position=UDim2.new(0,8,0,42),BackgroundTransparency=1,Text="0.0%",TextColor3=C.A1G,Font=T.F1,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,Parent=pp})
    local spL = GUI.New("TextLabel",{Size=UDim2.new(0.75,-8,0,14),Position=UDim2.new(0.25,0,0,42),BackgroundTransparency=1,Text="",TextColor3=C.A4,Font=T.F3,TextSize=9,TextXAlignment=Enum.TextXAlignment.Right,Parent=pp})
    local d1L = GUI.New("TextLabel",{Size=UDim2.new(1,-16,0,12),Position=UDim2.new(0,8,0,60),BackgroundTransparency=1,Text="",TextColor3=C.Dim,Font=T.F3,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Parent=pp})
    local d2L = GUI.New("TextLabel",{Size=UDim2.new(1,-16,0,12),Position=UDim2.new(0,8,0,74),BackgroundTransparency=1,Text="",TextColor3=C.Dim,Font=T.F3,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Parent=pp})
    local sL = GUI.New("TextLabel",{Size=UDim2.new(1,-16,0,12),Position=UDim2.new(0,8,0,90),BackgroundTransparency=1,Text="",TextColor3=C.A3,Font=T.F2,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Parent=pp})
    local mL = GUI.New("TextLabel",{Size=UDim2.new(1,-16,0,12),Position=UDim2.new(0,8,0,106),BackgroundTransparency=1,Text="",TextColor3=C.Cyan,Font=T.F3,TextSize=8,TextXAlignment=Enum.TextXAlignment.Left,Parent=pp})
    local smL = GUI.New("TextLabel",{Size=UDim2.new(1,-16,0,12),Position=UDim2.new(0,8,0,120),BackgroundTransparency=1,Text="",TextColor3=C.A5,Font=T.F3,TextSize=8,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Parent=pp})

    -- Power badge
    local lvl, score = ExecDetect.PowerLevel()
    local pwBadge = GUI.New("Frame",{Size=UDim2.new(0,0,0,16),Position=UDim2.new(0,8,0,140),BackgroundColor3=C.Glass,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.X,Parent=pp})
    GUI.Corner(pwBadge,4) GUI.Stroke(pwBadge,C.Sep,1,0.6) GUI.New("UIPadding",{PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5),Parent=pwBadge})
    GUI.New("TextLabel",{Size=UDim2.new(0,0,1,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.X,Text=string.format("💪 %s (%d/35) • 🔧 %s • 12 Script Methods", lvl, score, ExecDetect.Name()),TextColor3=C.Sub,Font=T.F3,TextSize=8,Parent=pwBadge})

    GUI.Drag(mf,tb)
    mnB.MouseButton1Click:Connect(function() minimized = not minimized if minimized then TS:Create(mf,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{Size=UDim2.new(0,560,0,52)}):Play() cf.Visible=false mnB.Text="+" else cf.Visible=true TS:Create(mf,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{Size=T.Size}):Play() mnB.Text="─" end end)
    clB.MouseButton1Click:Connect(function() TS:Create(mf,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=UDim2.new(0,0,0,0)}):Play() task.wait(0.3) sg:Destroy() end)

    GR = {SG=sg,MF=mf,CF=cf,SF=sf,PP=pp,StL=stL,PbF=pbF,PcL=pcL,EtL=etL,D1L=d1L,D2L=d2L,SL=sL,SpL=spL,ML=mL,SmL=smL,Shm=shm,PpG=ppG}

    TS:Create(mf,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=T.Size}):Play()
    task.spawn(function() while GR.Shm and GR.Shm.Parent do TS:Create(GR.Shm,TweenInfo.new(0.8,Enum.EasingStyle.Linear),{Position=UDim2.new(1.15,0,0,0)}):Play() task.wait(1.1) if GR.Shm then GR.Shm.Position=UDim2.new(-0.15,0,0,0) end end end)
    task.spawn(function() while gs and gs.Parent do TS:Create(gs,TweenInfo.new(2.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Transparency=0.6}):Play() task.wait(2.5) TS:Create(gs,TweenInfo.new(2.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Transparency=0.15}):Play() task.wait(2.5) end end)
    return GR
end

local lpT, lpP = tick(), 0

function GUI.Prog(pct, st, d1, d2, sT, spT)
    if not GR.PbF then return end
    pct = math.clamp(pct or 0, 0, 100)
    TS:Create(GR.PbF,TweenInfo.new(0.1),{Size=UDim2.new(pct/100,0,1,0)}):Play()
    GR.PcL.Text = string.format("%.1f%%", pct)
    local now = tick()
    if pct > 0 and pct < 100 and lpP > 0 then local dp,dt = pct-lpP, now-lpT if dp > 0 and dt > 0 then GR.EtL.Text = "ETA "..U.FmtT(((100-pct)/dp)*dt) end
    elseif pct >= 100 then GR.EtL.Text = "✓ Done" end
    lpT, lpP = now, pct
    local ico = pct>=100 and "✅" or pct>60 and "🔄" or pct>0 and "📦" or "⏳"
    if st then GR.StL.Text = ico.." "..st end
    if d1 then GR.D1L.Text = "→ "..d1 end
    if d2 then GR.D2L.Text = "  "..d2 end
    if sT then GR.SL.Text = "📊 "..sT end
    if spT then GR.SpL.Text = "⚡ "..spT end
    GR.ML.Text = string.format("💾 Mem: %sKB | Peak: %sKB", U.FmtN(collectgarbage("count")), U.FmtN(Mem.peakKB))
    -- Script method breakdown
    local smText = {}
    for method, count in pairs(Stats.ScriptMethods or {}) do
        table.insert(smText, method..":"..count)
    end
    if #smText > 0 then GR.SmL.Text = "📜 "..table.concat(smText, " | ") end
    if pct >= 100 then GR.PcL.TextColor3 = Config.Theme.C.Ok TS:Create(GR.PbF,TweenInfo.new(0.2),{BackgroundColor3=Config.Theme.C.Ok}):Play()
    else GR.PcL.TextColor3 = Config.Theme.C.A1G end
end

function GUI.Reset() lpP=0 lpT=tick() GUI.Prog(0,"Ready","","","","") pcall(function() GR.PbF.BackgroundColor3=Config.Theme.C.PFl GR.PpG.BackgroundColor3=Config.Theme.C.A1 GR.SmL.Text="" end) end
function GUI.Lock(en) if not GR.SF then return end for _,ch in ipairs(GR.SF:GetChildren()) do if ch:IsA("TextButton") then ch.Active=en ch.BackgroundTransparency=en and 0 or 0.5 end end end
function GUI.Flash() if not GR.PP then return end local o=GR.PP.BackgroundColor3 TS:Create(GR.PP,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(18,45,28)}):Play() task.wait(0.3) TS:Create(GR.PP,TweenInfo.new(0.2),{BackgroundColor3=o}):Play() end

-- ============================================================
-- 24. API (35 functions)
-- ============================================================
local API = {}
local running = false

local function Run(tn, fn)
    if running then U.Notify(Config.Name,"Task running!",3) return end
    running=true GUI.Lock(false) GUI.Reset()
    task.spawn(function()
        local t0=tick()
        local ok,err=pcall(fn)
        if not ok then GUI.Prog(0,"❌ "..tn,tostring(err)) U.Notify(Config.Name,"Error: "..tostring(err),6) U.Log("ERROR",tn..": "..tostring(err)) end
        U.Log("TASK",tn.." in "..U.FmtT(tick()-t0))
        running=false GUI.Lock(true)
    end)
end

local function MP(name)
    local t0=tick()
    return function(pct,s1,s2,s3)
        local spd=Stats.Copied/math.max(tick()-t0,0.001)
        GUI.Prog(pct, name..": "..(s1 or""), s2 or"", s3 or"",
            string.format("Copied:%s Failed:%d Scripts:%d/%d", U.FmtN(Stats.Copied), Stats.Failed, Stats.Scripts, Stats.Scripts+Stats.ScriptsFail),
            string.format("%.0f inst/s", spd))
    end
end

local function Fin(fn, tn)
    local s=Core.Stats()
    GUI.Prog(85,"Exporting...",fn,"",Exp.Report(s),"Writing...")
    local ok,err=Exp.Save(fn,{decompile=true,nilInstances=true})
    if ok then
        GUI.Prog(100,"🎉 "..tn.." Complete!","✅ "..fn,Exp.Report(s),
            string.format("Total: %s in %s | Peak: %sKB", U.FmtN(s.Copied), U.FmtT(s.Elapsed), U.FmtN(s.PeakMem)),"")
        GUI.Flash() U.Notify(Config.Name,tn.." saved! "..fn,6)
    else GUI.Prog(95,"⚠️ Attempted",tostring(err),"Check workspace") U.Notify(Config.Name,"Attempted: "..tostring(err),6) end
    task.spawn(function() pcall(function() WH.Send(tn,s) end) end)
    U.ClearCache()
end

function API:DecompileEverything() Run("Everything",function() local f=Config.Out.."_EVERYTHING.rbxl" Core.Everything(function(p,s1,s2,s3) local st=Core.Stats() local spd=st.Copied/math.max(tick()-st.StartTime,0.001) GUI.Prog(p*0.82,s1,s2,s3,string.format("Copied:%s Scripts:%d",U.FmtN(st.Copied),st.Scripts),string.format("%.0f inst/s",spd)) end) Fin(f,"Everything") end) end
function API:DecompileFullGame() Run("Full Game",function() local f=Config.Out.."_FullGame.rbxl" Core.FullGame(MP("Game")) if SE.Has() then Core.Scripts(MP("Scripts")) end Core.Terrain(MP("Terrain")) Fin(f,"Full Game") end) end
function API:DecompileAllModels() Run("All Models",function() local f=Config.Out.."_AllModels.rbxl" Core.AllModels(MP("Models")) Fin(f,"All Models") end) end
function API:DecompileWorkspaceModels() Run("WS Models",function() local f=Config.Out.."_WS.rbxl" Core.WorkspaceModels(MP("WS")) Fin(f,"WS Models") end) end
function API:DecompileDeepModels() Run("Deep",function() local f=Config.Out.."_Deep.rbxl" Core.DeepModels(MP("Deep")) Fin(f,"Deep Models") end) end
function API:DecompileTerrain() Run("Terrain",function() local f=Config.Out.."_Terrain.rbxl" local t=Core.Terrain(MP("Terrain")) if not t then GUI.Prog(0,"❌ No Terrain","") return end Fin(f,"Terrain") end) end
function API:DecompileScripts() Run("Scripts",function() local f=Config.Out.."_Scripts.rbxl" if not SE.Has() then GUI.Prog(0,"❌ No Decompiler","") return end Core.Scripts(MP("Scripts")) SE.SaveBytecodes() Fin(f,"Scripts") end) end
function API:DecompileLighting() Run("Lighting",function() local f=Config.Out.."_Lighting.rbxl" Core.Lighting(MP("Lighting")) Fin(f,"Lighting") end) end
function API:DecompileSounds() Run("Sounds",function() local f=Config.Out.."_Sounds.rbxl" Core.Sounds(MP("Sounds")) Fin(f,"Sounds") end) end
function API:DecompileAnimations() Run("Anims",function() local f=Config.Out.."_Anims.rbxl" Core.Anims(MP("Anims")) Fin(f,"Anims") end) end
function API:DecompileParticles() Run("FX",function() local f=Config.Out.."_FX.rbxl" Core.Particles(MP("FX")) Fin(f,"Particles") end) end
function API:DecompileMeshes() Run("Meshes",function() local f=Config.Out.."_Meshes.rbxl" Core.Meshes(MP("Meshes")) Fin(f,"Meshes") end) end
function API:DecompileTextures() Run("Textures",function() local f=Config.Out.."_Tex.rbxl" Core.Textures(MP("Tex")) Fin(f,"Textures") end) end
function API:DecompilePhysics() Run("Physics",function() local f=Config.Out.."_Phys.rbxl" Core.PhysicsData(MP("Phys")) Fin(f,"Physics") end) end
function API:DecompileUIs() Run("UIs",function() local f=Config.Out.."_UIs.rbxl" Core.UIs(MP("UIs")) Fin(f,"UIs") end) end
function API:DecompilePackages() Run("Pkgs",function() local f=Config.Out.."_Pkgs.rbxl" Core.Pkgs(MP("Pkgs")) Fin(f,"Packages") end) end
function API:DecompileNil() Run("Nil",function() local f=Config.Out.."_Nil.rbxl" if not getnilinstances then GUI.Prog(0,"❌ N/A","") return end Core.NilInst(MP("Nil")) Fin(f,"Nil") end) end
function API:DecompileHidden() Run("Hidden",function() local f=Config.Out.."_Hidden.rbxl" Core.HiddenProps(MP("Hidden")) Fin(f,"Hidden") end) end
function API:DecompileMaterials() Run("Mats",function() local f=Config.Out.."_Mats.rbxl" Core.Materials(MP("Mats")) Fin(f,"Materials") end) end
function API:DecompileCharacters() Run("Chars",function() local f=Config.Out.."_Chars.rbxl" Core.Characters(MP("Chars")) Fin(f,"Characters") end) end
function API:DecompileAccessories() Run("Accs",function() local f=Config.Out.."_Accs.rbxl" Core.Accessories(MP("Accs")) Fin(f,"Accessories") end) end
function API:DecompileClothing() Run("Clothing",function() local f=Config.Out.."_Cloth.rbxl" Core.Clothing(MP("Cloth")) Fin(f,"Clothing") end) end
function API:Decompile3DGui() Run("3DGui",function() local f=Config.Out.."_3D.rbxl" Core.Gui3D(MP("3D")) Fin(f,"3D GUIs") end) end
function API:DecompileHighlights() Run("HL",function() local f=Config.Out.."_HL.rbxl" Core.Highlights(MP("HL")) Fin(f,"Highlights") end) end
function API:DecompilePrompts() Run("Prompts",function() local f=Config.Out.."_Prompts.rbxl" Core.Prompts(MP("Prompts")) Fin(f,"Prompts") end) end
function API:DecompileBones() Run("Bones",function() local f=Config.Out.."_Bones.rbxl" Core.Bones(MP("Bones")) Fin(f,"Bones") end) end
function API:DecompileWraps() Run("Wraps",function() local f=Config.Out.."_Wraps.rbxl" Core.Wraps(MP("Wraps")) Fin(f,"Wraps") end) end
function API:DecompileRemotes() Run("Remotes",function() local f=Config.Out.."_Remotes.rbxl" Core.Remotes(MP("Remotes")) Fin(f,"Remotes") end) end
function API:DecompileValues() Run("Values",function() local f=Config.Out.."_Values.rbxl" Core.Values(MP("Values")) Fin(f,"Values") end) end
function API:QuickSave() Run("Quick",function() local f=Config.Out.."_Quick.rbxl" GUI.Prog(30,"Quick Save","Direct...") Fin(f,"Quick") end) end
function API:DecompileService(sn) Run("Svc:"..sn,function() local f=Config.Out.."_"..sn..".rbxl" Core.Service(sn,MP(sn)) Fin(f,sn) end) end
function API:DecompileByClass(cn) Run("Cls:"..cn,function() local f=Config.Out.."_"..cn..".rbxl" Core.ByClass(cn,MP(cn)) Fin(f,cn) end) end
function API:ExportLogs()
    local log = table.concat(LogBuf,"\n")
    pcall(function() if setclipboard then setclipboard(log) elseif toclipboard then toclipboard(log) end end)
    pcall(function() if writefile then writefile(Config.Out.."_Log.txt",log) end end)
    U.Notify(Config.Name,"Logs exported! ("..#LogBuf..")",4)
end
function API:TestWebhook() task.spawn(function() WH.Send("Test",{Copied=0,Failed=0,Scripts=0,ScriptsFail=0,Elapsed=0,PeakMem=0,Terrain=0,NilInst=0,Hidden=0,Meshes=0,Sounds=0,Anims=0}) U.Notify(Config.Name,"Webhook sent!",4) end) end
function API:ShowCapabilities()
    local caps = ExecDetect.Capabilities
    local lines = {"=== Executor Capabilities ==="}
    for k, v in pairs(caps) do table.insert(lines, string.format("  %s: %s", k, tostring(v))) end
    local lvl, score = ExecDetect.PowerLevel()
    table.insert(lines, string.format("\nPower: %s (%d/35)", lvl, score))
    table.insert(lines, "Decompile Methods: " .. table.concat(ExecDetect.BestDecompileMethod(), ", "))
    local text = table.concat(lines, "\n")
    pcall(function() if setclipboard then setclipboard(text) end end)
    pcall(function() if writefile then writefile(Config.Out.."_Caps.txt", text) end end)
    U.Notify(Config.Name, "Capabilities: "..lvl.." ("..score.."/35)", 5)
end

-- ============================================================
-- 25. INITIALIZATION
-- ============================================================
local function Init()
    ExecDetect.Scan()
    GUI.Build()
    local C = Config.Theme.C
    local S = GR.SF

    GUI.Sep("⚡ OMEGA DECOMPILE",1).Parent=S
    GUI.Btn("Decompile EVERYTHING","🌐",C.A2,C.A2G,2,function() API:DecompileEverything() end).Parent=S
    GUI.Btn("Full Game 100%","📦",C.A1,C.A1G,3,function() API:DecompileFullGame() end).Parent=S
    GUI.Btn("Quick Save","⚡",C.A3,C.A3G,4,function() API:QuickSave() end).Parent=S

    GUI.Sep("🧱 MODELS 100%",10).Parent=S
    GUI.Btn("All Models (Auto Full)","🏗️",C.A1,C.A1G,11,function() API:DecompileAllModels() end).Parent=S
    GUI.Btn("Workspace Models","🧊",C.Btn,C.BtnH,12,function() API:DecompileWorkspaceModels() end).Parent=S
    GUI.Btn("Deep Model Scanner","🔍",C.Btn,C.BtnH,13,function() API:DecompileDeepModels() end).Parent=S
    GUI.Btn("Characters","🧑",C.Btn,C.BtnH,14,function() API:DecompileCharacters() end).Parent=S
    GUI.Btn("Accessories & Tools","🎒",C.Btn,C.BtnH,15,function() API:DecompileAccessories() end).Parent=S
    GUI.Btn("Clothing","👕",C.Btn,C.BtnH,16,function() API:DecompileClothing() end).Parent=S

    GUI.Sep("🎨 ASSETS",20).Parent=S
    GUI.Btn("Scripts (12 Methods)","📜",C.Btn,C.BtnH,21,function() API:DecompileScripts() end).Parent=S
    GUI.Btn("Meshes","🔷",C.Btn,C.BtnH,22,function() API:DecompileMeshes() end).Parent=S
    GUI.Btn("Textures","🖼️",C.Btn,C.BtnH,23,function() API:DecompileTextures() end).Parent=S
    GUI.Btn("Sounds","🔊",C.Btn,C.BtnH,24,function() API:DecompileSounds() end).Parent=S
    GUI.Btn("Animations","🎬",C.Btn,C.BtnH,25,function() API:DecompileAnimations() end).Parent=S
    GUI.Btn("Materials","🎨",C.Btn,C.BtnH,26,function() API:DecompileMaterials() end).Parent=S

    GUI.Sep("🌍 ENVIRONMENT",30).Parent=S
    GUI.Btn("Terrain 100%","🏔️",C.Btn,C.BtnH,31,function() API:DecompileTerrain() end).Parent=S
    GUI.Btn("Lighting & PostFX","💡",C.Btn,C.BtnH,32,function() API:DecompileLighting() end).Parent=S
    GUI.Btn("Particles & Effects","✨",C.Btn,C.BtnH,33,function() API:DecompileParticles() end).Parent=S
    GUI.Btn("Physics & Constraints","⚙️",C.Btn,C.BtnH,34,function() API:DecompilePhysics() end).Parent=S

    GUI.Sep("🔬 ADVANCED",40).Parent=S
    GUI.Btn("UI Elements","🖥️",C.Btn,C.BtnH,41,function() API:DecompileUIs() end).Parent=S
    GUI.Btn("3D GUIs","📺",C.Btn,C.BtnH,42,function() API:Decompile3DGui() end).Parent=S
    GUI.Btn("Highlights","🌟",C.Btn,C.BtnH,43,function() API:DecompileHighlights() end).Parent=S
    GUI.Btn("ProximityPrompts","🔔",C.Btn,C.BtnH,44,function() API:DecompilePrompts() end).Parent=S
    GUI.Btn("Bones (Skinned)","🦴",C.Btn,C.BtnH,45,function() API:DecompileBones() end).Parent=S
    GUI.Btn("Wraps (Layered)","🧤",C.Btn,C.BtnH,46,function() API:DecompileWraps() end).Parent=S
    GUI.Btn("Remotes & Bindables","📡",C.Btn,C.BtnH,47,function() API:DecompileRemotes() end).Parent=S
    GUI.Btn("Values","📊",C.Btn,C.BtnH,48,function() API:DecompileValues() end).Parent=S
    GUI.Btn("Packages","📁",C.Btn,C.BtnH,49,function() API:DecompilePackages() end).Parent=S
    GUI.Btn("Nil Instances","👻",C.A4,C.A4G,50,function() API:DecompileNil() end).Parent=S
    GUI.Btn("Hidden Properties","🔐",C.A4,C.A4G,51,function() API:DecompileHidden() end).Parent=S

    GUI.Sep("📂 SERVICES",60).Parent=S
    for idx,info in ipairs({{"Workspace","🌍"},{"ReplicatedStorage","📦"},{"ServerStorage","🗄️"},{"ServerScriptService","📜"},{"StarterGui","🖥️"},{"StarterPlayer","🧑"},{"StarterPack","🎒"},{"Lighting","💡"},{"SoundService","🔊"},{"ReplicatedFirst","📋"},{"Chat","💬"},{"Teams","👥"}}) do
        GUI.Btn(info[1],info[2],C.Btn,C.BtnH,60+idx,function() API:DecompileService(info[1]) end).Parent=S
    end

    GUI.Sep("🛠️ TOOLS",80).Parent=S
    GUI.Btn("Export Logs","📋",C.Btn,C.BtnH,81,function() API:ExportLogs() end).Parent=S
    GUI.Btn("Test Webhook","🔗",C.Cyan,C.CyanG,82,function() API:TestWebhook() end).Parent=S
    GUI.Btn("Show Capabilities","💪",C.A5,C.A5G,83,function() API:ShowCapabilities() end).Parent=S

    GUI.New("TextLabel",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,Text=string.format("v%s %s | 35 APIs | 350+ Props | 12 Script Methods | 12 Save Methods\nAdaptive Terrain | Reference Resolver | Bytecode Cache | Webhook Logs", Config.Version,Config.Build),TextColor3=C.Dim,Font=Config.Theme.F3,TextSize=8,LayoutOrder=90,Parent=S})

    U.Notify(Config.Name,"v"..Config.Version.." "..Config.Build.." loaded! Max power decompile ready.",5)
    U.Log("INIT","v"..Config.Version.." OMEGA initialized")
    task.spawn(function() task.wait(2) WH.Send("Tool Loaded",{Copied=0,Failed=0,Scripts=0,ScriptsFail=0,Elapsed=0,PeakMem=0,Terrain=0,NilInst=0,Hidden=0,Meshes=0,Sounds=0,Anims=0}) end)
end

Init()
return API
