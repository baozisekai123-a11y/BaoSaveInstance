local SaveInstanceCore = {}
SaveInstanceCore.__version = "3.9.0"

local Services = setmetatable({}, {
    __index = function(t, k)
        local ok, svc = pcall(game.GetService, game, k)
        if ok then t[k] = svc return svc end
    end
})

local function safeCall(f, ...) local ok, r = pcall(f, ...) return ok and r or nil end

local function getGuiParent()
    for _, f in ipairs({
        function() return gethui() end,
        function() return cloneref(Services.CoreGui) end,
        function() return Services.CoreGui end,
        function() return Services.Players.LocalPlayer:WaitForChild("PlayerGui") end,
    }) do local p = safeCall(f) if p then return p end end
    return Services.CoreGui
end

local env = {
    gethiddenproperty   = gethiddenproperty,
    sethiddenproperty   = sethiddenproperty,
    getscriptbytecode   = getscriptbytecode,
    decompile           = decompile,
    getinstances        = getinstances,
    getnilinstances     = getnilinstances,
    isscriptable        = isscriptable,
    getproperties       = getproperties,
    getconstants        = getconstants,
    getprotos           = getprotos,
    getupvalues         = getupvalues,
    cloneref            = cloneref,
    writefile           = writefile,
    readfile            = readfile,
    makefolder          = makefolder,
}

local function detectExecutor()
    if SOLARA_LOADED or solara then return "Solara"
    elseif Xeno or is_xeno_executor then return "Xeno"
    elseif WAVE_EXECUTOR then return "Wave"
    elseif syn or Synapse then return "Synapse"
    elseif KRNL_LOADED then return "KRNL"
    elseif getexecutorname then return getexecutorname()
    elseif identifyexecutor then return identifyexecutor()
    else return "Unknown" end
end

local SafeMode = {}
SafeMode.__index = SafeMode

function SafeMode.new()
    local self = setmetatable({}, SafeMode)
    self.active = false
    self.overlay = nil
    self.statusLabel = nil
    self.subLabel = nil
    self.savedLighting = {}
    return self
end

function SafeMode:enable(statusText)
    if self.active then
        if self.statusLabel then self.statusLabel.Text = statusText or "Processing..." end
        return
    end
    self.active = true

    local parent = getGuiParent()

    local ok, err = pcall(function()
        local screen = Instance.new("ScreenGui")
        screen.Name = "SafeModeOverlay_SIS"
        screen.DisplayOrder = 2147483647
        screen.IgnoreGuiInset = true
        screen.ResetOnSpawn = false
        screen.Enabled = true

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
        bg.BorderSizePixel = 0
        bg.Parent = screen

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 100, 0, 80)
        icon.Position = UDim2.new(0.5, -50, 0.5, -120)
        icon.BackgroundTransparency = 1
        icon.Text = "🛡️"
        icon.TextScaled = true
        icon.Font = Enum.Font.GothamBold
        icon.Parent = bg

        local mainLabel = Instance.new("TextLabel")
        mainLabel.Size = UDim2.new(0, 600, 0, 50)
        mainLabel.Position = UDim2.new(0.5, -300, 0.5, -30)
        mainLabel.BackgroundTransparency = 1
        mainLabel.Text = statusText or "Safe Mode Active"
        mainLabel.TextColor3 = Color3.fromRGB(40, 40, 40)
        mainLabel.TextSize = 24
        mainLabel.Font = Enum.Font.GothamBold
        mainLabel.Parent = bg
        self.statusLabel = mainLabel

        local subLabel = Instance.new("TextLabel")
        subLabel.Size = UDim2.new(0, 600, 0, 30)
        subLabel.Position = UDim2.new(0.5, -300, 0.5, 30)
        subLabel.BackgroundTransparency = 1
        subLabel.Text = "Please wait, do not close the game..."
        subLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        subLabel.TextSize = 15
        subLabel.Font = Enum.Font.Gotham
        subLabel.Parent = bg
        self.subLabel = subLabel

        local progressBg = Instance.new("Frame")
        progressBg.Size = UDim2.new(0, 500, 0, 8)
        progressBg.Position = UDim2.new(0.5, -250, 0.5, 80)
        progressBg.BackgroundColor3 = Color3.fromRGB(210, 210, 210)
        progressBg.BorderSizePixel = 0
        progressBg.Parent = bg
        Instance.new("UICorner", progressBg).CornerRadius = UDim.new(1, 0)

        local progressFill = Instance.new("Frame")
        progressFill.Size = UDim2.new(0, 0, 1, 0)
        progressFill.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        progressFill.BorderSizePixel = 0
        progressFill.Parent = progressBg
        Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)
        self.progressFill = progressFill

        local pctLabel = Instance.new("TextLabel")
        pctLabel.Size = UDim2.new(0, 500, 0, 25)
        pctLabel.Position = UDim2.new(0.5, -250, 0.5, 95)
        pctLabel.BackgroundTransparency = 1
        pctLabel.Text = "0%"
        pctLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
        pctLabel.TextSize = 13
        pctLabel.Font = Enum.Font.GothamMedium
        pctLabel.Parent = bg
        self.pctLabel = pctLabel

        screen.Parent = parent
        self.overlay = screen
    end)

    if not ok then warn("[SafeMode] Failed to create overlay:", err) end

    local lighting = Services.Lighting
    if lighting then
        self.savedLighting = {
            GlobalShadows = lighting.GlobalShadows,
            FogEnd       = lighting.FogEnd,
            FogColor     = lighting.FogColor,
            Brightness   = lighting.Brightness,
            Technology   = lighting.Technology
        }
        pcall(function()
            lighting.GlobalShadows = false
            lighting.FogEnd        = 0
            lighting.FogColor      = Color3.new(1, 1, 1)
            lighting.Brightness    = 0
            lighting.Technology    = Enum.Technology.Compatibility
        end)
    end
end

function SafeMode:setProgress(fraction, label, sublabel)
    if not self.active then return end
    fraction = math.clamp(fraction or 0, 0, 1)
    if self.progressFill then
        self.progressFill:TweenSize(UDim2.new(fraction, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    end
    if self.pctLabel then self.pctLabel.Text = string.format("%.0f%%", fraction * 100) end
    if self.statusLabel and label then self.statusLabel.Text = label end
    if self.subLabel and sublabel then self.subLabel.Text = sublabel end
end

function SafeMode:disable()
    if not self.active then return end
    self.active = false

    if self.overlay then
        self.overlay:Destroy()
        self.overlay = nil
        self.statusLabel = nil
        self.subLabel = nil
        self.progressFill = nil
        self.pctLabel = nil
    end

    local lighting = Services.Lighting
    if lighting and next(self.savedLighting) then
        pcall(function()
            for k, v in pairs(self.savedLighting) do
                pcall(function() lighting[k] = v end)
            end
        end)
        self.savedLighting = {}
    end
end

local Logger = {}
Logger.__index = Logger
function Logger.new()
    return setmetatable({logs = {}, callbacks = {}}, Logger)
end
function Logger:write(level, msg)
    local entry = {time = os.time(), level = level, message = msg}
    table.insert(self.logs, entry)
    for _, cb in ipairs(self.callbacks) do task.spawn(cb, entry) end
    if level == "ERROR" or level == "WARN" then warn(("[%s] %s"):format(level, msg))
    else print(("[%s] %s"):format(level, msg)) end
end
function Logger:onLog(cb) table.insert(self.callbacks, cb) end
function Logger:export()
    local lines = {}
    for _, e in ipairs(self.logs) do table.insert(lines, ("[%s][%s] %s"):format(os.date("%X", e.time), e.level, e.message)) end
    return table.concat(lines, "\n")
end

local PropertyExtractor = {}
PropertyExtractor.__index = PropertyExtractor
function PropertyExtractor.new()
    return setmetatable({cache = {}, blacklist = {"DataCost","UniqueId","HistoryId","RobloxLocked"}}, PropertyExtractor)
end
function PropertyExtractor:get(instance, prop)
    local key = tostring(instance) .. prop
    if self.cache[key] ~= nil then
        return self.cache[key] == false and nil or self.cache[key]
    end
    for _, b in ipairs(self.blacklist) do if prop == b then self.cache[key] = false return nil end end
    local val
    local ok = pcall(function()
        if env.isscriptable and env.gethiddenproperty and not env.isscriptable(instance, prop) then
            val = env.gethiddenproperty(instance, prop)
        else
            val = instance[prop]
        end
    end)
    if ok and val ~= nil then
        self.cache[key] = val
        return val
    end
    self.cache[key] = false
    return nil
end
function PropertyExtractor:getAll(instance)
    local props = {}
    local list
    if env.getproperties then
        local ok, r = pcall(env.getproperties, instance)
        if ok then list = r end
    end
    if not list then
        list = {"Name","ClassName","Parent","Archivable"}
        local extras = {
            BasePart          = {"Size","CFrame","Anchored","CanCollide","Transparency","Reflectance","Material","Color","BrickColor","CastShadow","Massless","Locked","CollisionGroupId"},
            Model             = {"PrimaryPart","WorldPivot"},
            LuaSourceContainer= {"Disabled"},
            Sound             = {"SoundId","Volume","Pitch","Looped","PlaybackSpeed","TimePosition"},
            Decal             = {"Texture","Transparency","Color3","Face"},
            Texture           = {"Texture","Transparency","StudsPerTileU","StudsPerTileV"},
            Light             = {"Brightness","Range","Shadows","Color"},
            ParticleEmitter   = {"Texture","Rate","Lifetime","Speed","Enabled"},
            SpecialMesh       = {"MeshType","MeshId","TextureId","Offset","Scale"},
            Humanoid          = {"MaxHealth","Health","WalkSpeed","JumpPower","AutoRotate"},
            SpawnLocation     = {"Duration","TeamColor","Neutral","AllowTeamChangeOnTouch"},
            Attachment        = {"CFrame","Visible"},
            Weld              = {"Part0","Part1","C0","C1"},
            Motor6D           = {"Part0","Part1","C0","C1","DesiredAngle","MaxVelocity"},
        }
        for cls, fields in pairs(extras) do
            if instance:IsA(cls) then
                for _, f in ipairs(fields) do
                    if not table.find(list, f) then table.insert(list, f) end
                end
            end
        end
    end
    for _, p in ipairs(list) do
        local v = self:get(instance, p)
        if v ~= nil then props[p] = {value = v, type = typeof(v)} end
    end
    return props
end

local Decompiler = {}
Decompiler.__index = Decompiler

function Decompiler.new(logger)
    local self = setmetatable({}, Decompiler)
    self.logger = logger
    self.cache = {}
    self.timeout = 6
    self.maxBytecodeSize = 512 * 1024
    self.stats = {total = 0, full = 0, partial = 0, failed = 0, skipped = 0}
    return self
end

function Decompiler:run(script)
    if not script:IsA("LuaSourceContainer") then return nil, "not_script" end
    local id = tostring(script)
    if self.cache[id] then return self.cache[id].src, self.cache[id].quality end

    self.stats.total = self.stats.total + 1

    local byteSize = 0
    if env.getscriptbytecode then
        local ok, bc = pcall(env.getscriptbytecode, script)
        if ok and bc then byteSize = #bc end
    end

    if byteSize > self.maxBytecodeSize then
        self.stats.skipped = self.stats.skipped + 1
        local s = ("-- Skipped: too large (%d KB)\n-- Path: %s"):format(byteSize / 1024, script:GetFullName())
        self.cache[id] = {src = s, quality = "skipped"}
        return s, "skipped"
    end

    local src, quality = self:attemptDecompile(script)

    if quality == "full" then self.stats.full = self.stats.full + 1
    elseif quality == "partial" then self.stats.partial = self.stats.partial + 1
    elseif quality == "failed" then self.stats.failed = self.stats.failed + 1 end

    self.cache[id] = {src = src, quality = quality}
    return src, quality
end

function Decompiler:attemptDecompile(script)
    local src, quality = nil, "failed"
    local done = false

    task.spawn(function()
        local ok, result, q = xpcall(function()
            return self:pipeline(script)
        end, debug.traceback)
        if ok and result then src, quality = result, q or "full"
        else src = ("-- Internal error\n-- %s"):format(tostring(result)) end
        done = true
    end)

    local t = tick()
    while not done and tick() - t < self.timeout do task.wait(0.05) end

    if not done then
        self.logger:write("WARN", "Decompile timeout: " .. script:GetFullName())
        return ("-- Timeout (>%ds)\n-- Path: %s"):format(self.timeout, script:GetFullName()), "failed"
    end

    return src, quality
end

function Decompiler:pipeline(script)
    do
        local src
        if env.gethiddenproperty then
            local ok, v = pcall(env.gethiddenproperty, script, "Source")
            if ok and type(v) == "string" and #v > 0 then src = v end
        end
        if not src then
            local ok, v = pcall(function() return script.Source end)
            if ok and type(v) == "string" and #v > 0 then src = v end
        end
        if src and not src:match("^%s*$") then
            return src, "full"
        end
    end

    if env.decompile then
        local ok, result = pcall(env.decompile, script)
        if ok and type(result) == "string" and #result > 10 then
            local clean = result:gsub("^%s+", ""):gsub("%s+$", "")
            if not clean:match("^%-%-") and #clean > 20 then
                return clean, "full"
            end
            if #clean > 5 then
                return result, "partial"
            end
        end
    end

    if env.getscriptbytecode then
        local ok, bytecode = pcall(env.getscriptbytecode, script)
        if ok and bytecode and #bytecode > 0 then
            return self:analyzeBytecode(script, bytecode), "partial"
        end
    end

    local constantSrc = self:constantFallback(script)
    if constantSrc then return constantSrc, "partial" end

    return ("-- Decompile failed\n-- Script: %s\n-- Class:  %s"):format(
        script:GetFullName(), script.ClassName
    ), "failed"
end

function Decompiler:analyzeBytecode(script, bytecode)
    local lines = {}
    table.insert(lines, ("-- [Partial] Bytecode analysis: %s"):format(script:GetFullName()))
    table.insert(lines, ("-- Bytecode size: %d bytes"):format(#bytecode))
    table.insert(lines, ("-- ClassName: %s"):format(script.ClassName))
    table.insert(lines, "")

    if env.getconstants then
        local ok, consts = pcall(env.getconstants, script)
        if ok and consts and #consts > 0 then
            table.insert(lines, "-- === Constants ===")
            for i, c in ipairs(consts) do
                if i > 200 then table.insert(lines, ("-- ... +%d more"):format(#consts - 200)) break end
                local t = type(c)
                if t == "string" then
                    table.insert(lines, ("local _K%d = %q"):format(i, c))
                elseif t == "number" then
                    table.insert(lines, ("local _K%d = %s"):format(i, tostring(c)))
                elseif t == "boolean" then
                    table.insert(lines, ("local _K%d = %s"):format(i, tostring(c)))
                end
            end
            table.insert(lines, "")
        end
    end

    if env.getupvalues then
        local ok, upvals = pcall(env.getupvalues, script)
        if ok and upvals and next(upvals) then
            table.insert(lines, "-- === Upvalues ===")
            for name, val in pairs(upvals) do
                table.insert(lines, ("-- %s = %s"):format(tostring(name), tostring(val)))
            end
            table.insert(lines, "")
        end
    end

    if env.getprotos then
        local ok, protos = pcall(env.getprotos, script)
        if ok and protos and #protos > 0 then
            table.insert(lines, ("-- === %d inner function(s) detected ==="):format(#protos))
            for i, proto in ipairs(protos) do
                table.insert(lines, ("-- function #%d"):format(i))
                if env.getconstants then
                    local ok2, pconsts = pcall(env.getconstants, proto)
                    if ok2 and pconsts then
                        for j, c in ipairs(pconsts) do
                            if j > 50 then break end
                            table.insert(lines, ("--   [%d] %q"):format(j, tostring(c)))
                        end
                    end
                end
            end
            table.insert(lines, "")
        end
    end

    local detected = {}
    local patterns = {
        "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction",
        "UserInputService", "TweenService", "RunService", "HttpService",
        "DataStoreService", "MarketplaceService", "TeleportService",
        "require", "loadstring", "getfenv", "setfenv", "newproxy"
    }
    for _, pat in ipairs(patterns) do
        if bytecode:find(pat, 1, true) then table.insert(detected, pat) end
    end
    if #detected > 0 then
        table.insert(lines, "-- === Detected References ===")
        for _, d in ipairs(detected) do table.insert(lines, ("-- %s"):format(d)) end
    end

    return table.concat(lines, "\n")
end

function Decompiler:constantFallback(script)
    if not env.getconstants then return nil end
    local ok, consts = pcall(env.getconstants, script)
    if not ok or not consts or #consts == 0 then return nil end
    local lines = {
        ("-- [Partial] Constant extraction: %s"):format(script:GetFullName()),
        ""
    }
    for i, c in ipairs(consts) do
        if i > 300 then table.insert(lines, "-- ... truncated") break end
        if type(c) == "string" then
            table.insert(lines, ("local _C%d = %q"):format(i, c))
        elseif type(c) == "number" then
            table.insert(lines, ("local _C%d = %s"):format(i, c))
        elseif c ~= nil then
            table.insert(lines, ("-- _C%d = %s"):format(i, tostring(c)))
        end
    end
    return table.concat(lines, "\n")
end

local Collector = {}
Collector.__index = Collector

function Collector.new(logger, extractor)
    local self = setmetatable({}, Collector)
    self.logger, self.extractor = logger, extractor
    self.instanceMap = {}
    self.idSeq = 0

    self.ignoreNames = {
        CoreGui                 = true,
        CorePackages            = true,
        HttpRbxApiService       = true,
        RobloxReplicatedStorage = true,
    }

    self.ignoreClasses = {
        Terrain      = true,
        StarterGear  = true,
        PackageLink  = true,
    }

    return self
end

function Collector:nextId() self.idSeq = self.idSeq + 1 return ("RBX%08X"):format(self.idSeq) end

function Collector:skip(inst)
    if inst == game then return true end
    if self.ignoreNames[inst.Name] then return true end
    if self.ignoreClasses[inst.ClassName] then return true end

    local okClass, isTerrain = pcall(inst.IsA, inst, "Terrain")
    if okClass and isTerrain then return true end

    local okParent = pcall(function() return inst.Parent end)
    if not okParent then return true end

    return false
end

function Collector:processOne(inst)
    local id = self:nextId()
    local d = {
        id         = id,
        instance   = inst,
        className  = inst.ClassName,
        name       = inst.Name,
        properties = self.extractor:getAll(inst),
        children   = {},
        parent     = inst.Parent
    }
    self.instanceMap[inst] = d
    return d
end

function Collector:fromRoot(root, onProgress)
    local out, desc = {}, root:GetDescendants()
    for i, inst in ipairs(desc) do
        if not self:skip(inst) then table.insert(out, self:processOne(inst)) end
        if i % 300 == 0 then task.wait() if onProgress then onProgress(i, #desc) end end
    end
    return out
end

function Collector:buildHierarchy()
    local roots = {}
    for _, d in pairs(self.instanceMap) do
        if d.parent and self.instanceMap[d.parent] then
            table.insert(self.instanceMap[d.parent].children, d)
        else
            table.insert(roots, d)
        end
    end
    return roots
end

function Collector:collectAll(options, onProgress)
    self.instanceMap = {}
    self.idSeq = 0
    local all = {}
    local containers = {
        {Services.Workspace, true},
        {Services.Lighting, true},
        {Services.ReplicatedStorage, true},
        {Services.ReplicatedFirst, true},
        {Services.StarterGui, true},
        {Services.StarterPack, true},
        {Services.StarterPlayer, true},
        {Services.Teams, true},
        {Services.SoundService, true},
        {Services.Chat, true},
        {Services.ServerScriptService, options.serverScripts},
        {Services.ServerStorage, options.serverScripts},
    }
    for _, c in ipairs(containers) do
        if c[1] and c[2] then
            for _, d in ipairs(self:fromRoot(c[1], onProgress)) do table.insert(all, d) end
        end
    end
    if options.nilInstances and env.getnilinstances then
        for _, inst in ipairs(env.getnilinstances()) do
            if not self:skip(inst) then
                local d = self:processOne(inst) d.isNil = true table.insert(all, d)
            end
        end
    end
    if options.players then
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p.Character then
                for _, d in ipairs(self:fromRoot(p.Character, nil)) do table.insert(all, d) end
            end
        end
    end
    self.logger:write("INFO", ("Collected %d instances"):format(#all))
    return all
end

local Serializer = {}
Serializer.__index = Serializer

function Serializer.new()
    return setmetatable({depth = 0, n = 0}, Serializer)
end

function Serializer:esc(s)
    return tostring(s):gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"):gsub('"',"&quot;"):gsub("'","&apos;")
end

function Serializer:val(v, t)
    t = t or typeof(v)
    if t == "string"   then return ("<string>%s</string>"):format(self:esc(v))
    elseif t == "number"   then return ("<double>%s</double>"):format(v)
    elseif t == "boolean"  then return ("<bool>%s</bool>"):format(v)
    elseif t == "Vector3"  then return ("<Vector3><X>%.9g</X><Y>%.9g</Y><Z>%.9g</Z></Vector3>"):format(v.X, v.Y, v.Z)
    elseif t == "Vector2"  then return ("<Vector2><X>%.9g</X><Y>%.9g</Y></Vector2>"):format(v.X, v.Y)
    elseif t == "CFrame"   then
        local c = {v:GetComponents()}
        return ("<CFrame><X>%.9g</X><Y>%.9g</Y><Z>%.9g</Z><R00>%.9g</R00><R01>%.9g</R01><R02>%.9g</R02><R10>%.9g</R10><R11>%.9g</R11><R12>%.9g</R12><R20>%.9g</R20><R21>%.9g</R21><R22>%.9g</R22></CFrame>"):format(table.unpack(c))
    elseif t == "Color3"    then return ("<Color3uint8>%d %d %d</Color3uint8>"):format(math.floor(v.R*255+0.5), math.floor(v.G*255+0.5), math.floor(v.B*255+0.5))
    elseif t == "BrickColor" then return ("<int>%d</int>"):format(v.Number)
    elseif t == "EnumItem"   then return ("<token>%d</token>"):format(v.Value)
    elseif t == "UDim"       then return ("<UDim><S>%.9g</S><O>%d</O></UDim>"):format(v.Scale, v.Offset)
    elseif t == "UDim2"      then return ("<UDim2><XS>%.9g</XS><XO>%d</XO><YS>%.9g</YS><YO>%d</YO></UDim2>"):format(v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
    elseif t == "Rect"       then return ("<Rect><min><X>%.9g</X><Y>%.9g</Y></min><max><X>%.9g</X><Y>%.9g</Y></max></Rect>"):format(v.Min.X, v.Min.Y, v.Max.X, v.Max.Y)
    else return ("<string>%s</string>"):format(self:esc(tostring(v))) end
end

function Serializer:item(d)
    self.n = self.n + 1
    if self.n % 150 == 0 then task.wait() end
    local pad = ("  "):rep(self.depth)
    local xml = ('%s<Item class="%s" referent="%s">\n%s  <Properties>\n'):format(pad, d.className, d.id, pad)
    xml = xml .. ('%s    <Property name="Name"><string>%s</string></Property>\n'):format(pad, self:esc(d.name))
    for pn, pd in pairs(d.properties) do
        if pn ~= "Name" and pn ~= "Parent" and pn ~= "ClassName" then
            pcall(function()
                xml = xml .. ('%s    <Property name="%s">%s</Property>\n'):format(pad, self:esc(pn), self:val(pd.value, pd.type))
            end)
        end
    end
    xml = xml .. pad .. "  </Properties>\n"
    self.depth = self.depth + 1
    for _, c in ipairs(d.children) do xml = xml .. self:item(c) end
    self.depth = self.depth - 1
    return xml .. pad .. "</Item>\n"
end

function Serializer:build(roots)
    self.depth, self.n = 0, 0
    local xml = '<?xml version="1.0" encoding="UTF-8"?>\n<roblox version="4">\n<Meta name="ExplicitAutoJoints">true</Meta>\n'
    for _, r in ipairs(roots) do xml = xml .. self:item(r) end
    return xml .. "</roblox>"
end

local FileIO = {}
FileIO.__index = FileIO

function FileIO.new(logger)
    local self = setmetatable({logger = logger, folder = "SaveInstance_Output"}, FileIO)
    if env.makefolder then pcall(env.makefolder, self.folder) end
    return self
end

function FileIO:name(ext)
    local ok, info = pcall(function() return Services.MarketplaceService:GetProductInfo(game.PlaceId) end)
    local n = (ok and info and info.Name) and info.Name:gsub("[^%w%-]","_") or "Unknown"
    return ("%s/%s_%s.%s"):format(self.folder, n, os.date("%Y%m%d_%H%M%S"), ext)
end

function FileIO:save(filename, content)
    if not env.writefile then return false end
    local ok, err = pcall(env.writefile, filename, content)
    if ok then self.logger:write("INFO", "Saved: " .. filename) return true, filename end
    self.logger:write("ERROR", "Write failed: " .. tostring(err)) return false, err
end

local GUI = {}
GUI.__index = GUI
function GUI.new() return setmetatable({}, GUI) end

function GUI:toggle(parent, text, default, yPos)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -30, 0, 38)
    row.Position = UDim2.new(0, 15, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(215, 215, 215)
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(0, 48, 0, 24)
    track.Position = UDim2.new(1, -48, 0.5, -12)
    track.BackgroundColor3 = default and Color3.fromRGB(67,181,129) or Color3.fromRGB(55,55,60)
    track.BorderSizePixel = 0
    track.Text = ""
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 18, 0, 18)
    thumb.Position = default and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.Parent = track
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    local state = default
    track.MouseButton1Click:Connect(function()
        state = not state
        track.BackgroundColor3 = state and Color3.fromRGB(67,181,129) or Color3.fromRGB(55,55,60)
        thumb:TweenPosition(state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
    end)
    return {get = function() return state end}
end

function GUI:showSetup(onStart)
    local parent = getGuiParent()

    local existing = parent:FindFirstChild("SIS_Setup")
    if existing then existing:Destroy() end

    local screen = Instance.new("ScreenGui")
    screen.Name = "SIS_Setup"
    screen.DisplayOrder = 999999
    screen.IgnoreGuiInset = true
    screen.ResetOnSpawn = false
    screen.Parent = parent

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 460, 0, 435)
    main.Position = UDim2.new(0.5, -230, 0.5, -217)
    main.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    main.Active = true
    main.Parent = screen
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 48)
    topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    topBar.BorderSizePixel = 0
    topBar.Parent = main
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)

    local topFix = Instance.new("Frame")
    topFix.Size = UDim2.new(1, 0, 0, 12)
    topFix.Position = UDim2.new(0, 0, 1, -12)
    topFix.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    topFix.BorderSizePixel = 0
    topFix.Parent = topBar

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 1, 0)
    titleLbl.Position = UDim2.new(0, 15, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "💾  SaveInstance Pro — Setup"
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.TextSize = 17
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = topBar

    local execLbl = Instance.new("TextLabel")
    execLbl.Size = UDim2.new(1, -20, 0, 22)
    execLbl.Position = UDim2.new(0, 15, 0, 55)
    execLbl.BackgroundTransparency = 1
    execLbl.Text = "Executor: " .. detectExecutor() .. "   |   v" .. SaveInstanceCore.__version
    execLbl.TextColor3 = Color3.fromRGB(120, 120, 130)
    execLbl.TextSize = 12
    execLbl.Font = Enum.Font.Gotham
    execLbl.TextXAlignment = Enum.TextXAlignment.Left
    execLbl.Parent = main

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -30, 0, 1)
    divider.Position = UDim2.new(0, 15, 0, 83)
    divider.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    divider.BorderSizePixel = 0
    divider.Parent = main

    local toggles = {
        safeMode     = self:toggle(main, "🛡️  Safe Mode  (white screen — anti-crash/ban)", true,  95),
        decompile    = self:toggle(main, "📜  Decompile Scripts  (slower, accurate)",      false, 143),
        nilInstances = self:toggle(main, "👻  Include Nil Instances",                       false, 191),
        players      = self:toggle(main, "👥  Include Player Characters",                   false, 239),
        serverScripts= self:toggle(main, "🗄️  Save Server Services",                       true,  287),
    }

    local note = Instance.new("TextLabel")
    note.Size = UDim2.new(1, -30, 0, 28)
    note.Position = UDim2.new(0, 15, 0, 337)
    note.BackgroundTransparency = 1
    note.Text = "ℹ️  Safe Mode auto-activates during decompile if enabled."
    note.TextColor3 = Color3.fromRGB(100, 150, 220)
    note.TextSize = 12
    note.Font = Enum.Font.GothamMedium
    note.TextXAlignment = Enum.TextXAlignment.Left
    note.TextWrapped = true
    note.Parent = main

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -30, 0, 48)
    btn.Position = UDim2.new(0, 15, 1, -63)
    btn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    btn.BorderSizePixel = 0
    btn.Text = "🚀  Start Save"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 16
    btn.Font = Enum.Font.GothamBold
    btn.Parent = main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(110, 125, 255) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(88, 101, 242) end)

    btn.MouseButton1Click:Connect(function()
        screen:Destroy()
        onStart({
            safeMode     = toggles.safeMode.get(),
            decompile    = toggles.decompile.get(),
            nilInstances = toggles.nilInstances.get(),
            players      = toggles.players.get(),
            serverScripts= toggles.serverScripts.get(),
        })
    end)

    self:makeDraggable(main, topBar)
end

function GUI:makeDraggable(frame, handle)
    local dragging, ds, dp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, ds, dp = true, i.Position, frame.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    Services.UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            frame.Position = UDim2.new(dp.X.Scale, dp.X.Offset+d.X, dp.Y.Scale, dp.Y.Offset+d.Y)
        end
    end)
end

local Core = {}
Core.__index = Core

function Core.new()
    local self = setmetatable({}, Core)
    self.logger     = Logger.new()
    self.extractor  = PropertyExtractor.new()
    self.collector  = Collector.new(self.logger, self.extractor)
    self.decompiler = Decompiler.new(self.logger)
    self.serializer = Serializer.new()
    self.fileio     = FileIO.new(self.logger)
    self.safeMode   = SafeMode.new()
    self.gui        = GUI.new()
    return self
end

function Core:start()
    self.gui:showSetup(function(options)
        task.spawn(function()
            local ok, err = xpcall(function() self:run(options) end, debug.traceback)
            if self.safeMode.active then self.safeMode:disable() end
            if ok then
                pcall(function()
                    Services.StarterGui:SetCore("SendNotification", {
                        Title = "✅ SaveInstance Complete",
                        Text = "File saved to SaveInstance_Output/",
                        Duration = 6
                    })
                end)
            else
                self.logger:write("ERROR", tostring(err))
                pcall(function()
                    Services.StarterGui:SetCore("SendNotification", {
                        Title = "❌ SaveInstance Failed",
                        Text = "Check F9 console for details.",
                        Duration = 6
                    })
                end)
            end
        end)
    end)
end

function Core:run(options)
    self.logger:write("INFO", ("Starting | safeMode=%s decompile=%s"):format(tostring(options.safeMode), tostring(options.decompile)))

    local instances = self.collector:collectAll(options, function(c, t)
        if options.safeMode then
            self.safeMode:setProgress(c/t * 0.35, "Collecting Instances", ("%d / %d"):format(c, t))
        end
    end)

    if options.decompile then
        if options.safeMode then
            self.safeMode:enable("Decompiling Scripts — Safe Mode Active")
            self.safeMode:setProgress(0.35, "Decompiling Scripts", "Starting...")
        end

        local scripts = {}
        for _, d in ipairs(instances) do
            if d.instance:IsA("LuaSourceContainer") then table.insert(scripts, d) end
        end

        self.logger:write("INFO", ("Found %d scripts to decompile"):format(#scripts))

        for i, sd in ipairs(scripts) do
            local src, quality = self.decompiler:run(sd.instance)
            sd.properties.Source = {value = src, type = "string"}

            local pct = 0.35 + (i / math.max(#scripts, 1)) * 0.45
            if options.safeMode then
                self.safeMode:setProgress(pct,
                    ("Decompiling Scripts (%d / %d)"):format(i, #scripts),
                    ("%s — %s"):format(quality, sd.instance:GetFullName():sub(1, 60))
                )
            end

            if i % 5 == 0 then task.wait(0.1) end
        end

        local s = self.decompiler.stats
        self.logger:write("INFO", ("Decompile done: full=%d partial=%d failed=%d skipped=%d"):format(s.full, s.partial, s.failed, s.skipped))
    else
        if options.safeMode then
            self.safeMode:setProgress(0.8, "Skipping Decompile", "Fast mode active")
            task.wait(0.2)
        end
    end

    if options.safeMode then self.safeMode:setProgress(0.82, "Building Hierarchy", "") end
    local roots = self.collector:buildHierarchy()

    if options.safeMode then self.safeMode:setProgress(0.88, "Serializing to XML", "") end
    task.wait(0.05)
    local xml = self.serializer:build(roots)

    if options.safeMode then self.safeMode:setProgress(0.96, "Writing File", "") end
    local fname = self.fileio:name("rbxlx")
    local ok, result = self.fileio:save(fname, xml)
    self.fileio:save(self.fileio:name("log"), self.logger:export())

    if options.safeMode then
        self.safeMode:setProgress(1, ok and "✅ Complete!" or "❌ Write Failed", ok and result or tostring(result))
        task.wait(1.5)
        self.safeMode:disable()
    end

    if not ok then error("File write failed: " .. tostring(result)) end
    self.logger:write("INFO", ("Done. File: %s"):format(result))
end

local app = Core.new()
app:start()
return SaveInstanceCore
