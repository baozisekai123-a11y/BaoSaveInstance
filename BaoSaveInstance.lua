local SaveInstanceCore = {}
SaveInstanceCore.__version = "3.5.1"

local Services = setmetatable({}, {
    __index = function(t, k)
        local success, service = pcall(game.GetService, game, k)
        if success then
            t[k] = service
            return service
        end
        return nil
    end
})

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    return success and result or nil
end

local function getGuiParent()
    local attempts = {
        function() return gethui() end,
        function() return cloneref(Services.CoreGui) end,
        function() return Services.CoreGui end,
        function() return Services.Players.LocalPlayer:WaitForChild("PlayerGui") end,
    }
    
    for _, attempt in ipairs(attempts) do
        local parent = safeCall(attempt)
        if parent then
            print("[SaveInstance] GUI Parent found:", parent:GetFullName())
            return parent
        end
    end
    
    warn("[SaveInstance] Could not find GUI parent, using CoreGui")
    return Services.CoreGui
end

local APIs = {
    saveinstance = saveinstance,
    getinstances = getinstances,
    getnilinstances = getnilinstances,
    gethiddenproperty = gethiddenproperty,
    sethiddenproperty = sethiddenproperty,
    getscriptbytecode = getscriptbytecode,
    decompile = decompile,
    cloneref = cloneref,
    isscriptable = isscriptable,
    getproperties = getproperties,
    writefile = writefile,
    readfile = readfile,
    makefolder = makefolder,
    isfolder = isfolder,
    isfile = isfile,
    getconstants = getconstants,
    getprotos = getprotos,
    getupvalues = getupvalues,
    getinfo = getinfo or debug.getinfo
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

local Logger = {}
Logger.__index = Logger

function Logger.new()
    local self = setmetatable({}, Logger)
    self.logs = {}
    self.callbacks = {}
    return self
end

function Logger:log(level, message, data)
    local entry = {
        time = os.time(),
        level = level,
        message = message,
        data = data
    }
    table.insert(self.logs, entry)
    
    for _, callback in ipairs(self.callbacks) do
        task.spawn(callback, entry)
    end
    
    if level == "ERROR" or level == "CRITICAL" then
        warn(string.format("[%s] %s", level, message))
    else
        print(string.format("[%s] %s", level, message))
    end
end

function Logger:onLog(callback)
    table.insert(self.callbacks, callback)
end

function Logger:export()
    local output = {}
    for _, log in ipairs(self.logs) do
        table.insert(output, string.format("[%s][%s] %s", os.date("%X", log.time), log.level, log.message))
    end
    return table.concat(output, "\n")
end

local PropertyExtractor = {}
PropertyExtractor.__index = PropertyExtractor

function PropertyExtractor.new()
    local self = setmetatable({}, PropertyExtractor)
    self.cache = {}
    self.blacklist = {
        "DataCost", "DataModel", "Terrain", "Terrain.Decoration",
        "RobloxLocked", "archivable", "UniqueId", "HistoryId"
    }
    return self
end

function PropertyExtractor:getProperty(instance, propertyName)
    local key = tostring(instance) .. "." .. propertyName
    if self.cache[key] ~= nil then
        return self.cache[key]
    end
    
    for _, blacklisted in ipairs(self.blacklist) do
        if propertyName == blacklisted then
            self.cache[key] = nil
            return nil
        end
    end
    
    local value
    local success = pcall(function()
        if APIs.gethiddenproperty and APIs.isscriptable then
            if not APIs.isscriptable(instance, propertyName) then
                value = APIs.gethiddenproperty(instance, propertyName)
            else
                value = instance[propertyName]
            end
        else
            value = instance[propertyName]
        end
    end)
    
    if success and value ~= nil then
        self.cache[key] = value
        return value
    end
    
    self.cache[key] = nil
    return nil
end

function PropertyExtractor:getAllProperties(instance)
    local properties = {}
    local propertyList
    
    if APIs.getproperties then
        propertyList = APIs.getproperties(instance)
    else
        propertyList = self:getDefaultProperties(instance)
    end
    
    for _, propName in ipairs(propertyList) do
        local value = self:getProperty(instance, propName)
        if value ~= nil then
            properties[propName] = {
                value = value,
                type = typeof(value)
            }
        end
    end
    
    return properties
end

function PropertyExtractor:getDefaultProperties(instance)
    local baseProps = {"Name", "ClassName", "Parent", "Archivable"}
    
    local classProps = {
        BasePart = {"Size", "CFrame", "Position", "Orientation", "Rotation", "Anchored", "CanCollide", "Transparency", "Reflectance", "Material", "Color", "BrickColor", "CastShadow", "CollisionGroupId", "Massless", "Locked"},
        Model = {"PrimaryPart", "WorldPivot"},
        LuaSourceContainer = {"Source", "Disabled"},
        Light = {"Brightness", "Range", "Shadows", "Color"},
        Sound = {"SoundId", "Volume", "Pitch", "Looped", "PlaybackSpeed", "TimePosition"},
        Attachment = {"CFrame", "Visible", "Axis", "SecondaryAxis", "WorldCFrame", "WorldAxis", "WorldSecondaryAxis", "WorldPosition"},
        Decal = {"Texture", "Transparency", "Color3", "Face", "ZIndex"},
        Texture = {"Texture", "Transparency", "Color3", "Face", "ZIndex", "StudsPerTileU", "StudsPerTileV", "OffsetStudsU", "OffsetStudsV"},
        SurfaceGui = {"Face", "CanvasSize", "LightInfluence", "Brightness", "SizingMode", "ZOffset", "ClipsDescendants"},
        BillboardGui = {"Size", "StudsOffset", "StudsOffsetWorldSpace", "ExtentsOffset", "ExtentsOffsetWorldSpace", "LightInfluence", "Brightness", "ClipsDescendants", "AlwaysOnTop", "PlayerToHideFrom"},
        ParticleEmitter = {"Enabled", "Rate", "Lifetime", "Speed", "Acceleration", "Drag", "VelocityInheritance", "Color", "Size", "Transparency", "Texture", "ZOffset", "LightEmission", "LightInfluence", "Rotation", "RotSpeed"},
    }
    
    local props = {table.unpack(baseProps)}
    
    for className, classSpecificProps in pairs(classProps) do
        if instance:IsA(className) then
            for _, prop in ipairs(classSpecificProps) do
                if not table.find(props, prop) then
                    table.insert(props, prop)
                end
            end
        end
    end
    
    return props
end

local ScriptDecompiler = {}
ScriptDecompiler.__index = ScriptDecompiler

function ScriptDecompiler.new(logger)
    local self = setmetatable({}, ScriptDecompiler)
    self.logger = logger
    self.cache = {}
    self.stats = {total = 0, success = 0, partial = 0, failed = 0}
    return self
end

function ScriptDecompiler:decompile(script)
    if not script:IsA("LuaSourceContainer") then
        return nil, "Not a script"
    end
    
    local scriptId = tostring(script)
    if self.cache[scriptId] then
        return self.cache[scriptId], "cached"
    end
    
    self.stats.total = self.stats.total + 1
    
    local methods = {
        self.directSource,
        self.nativeDecompile,
        self.customDecompile,
        self.bytecodeExtract,
        self.constantAnalysis,
        self.fallbackPlaceholder
    }
    
    for i, method in ipairs(methods) do
        local success, source, quality = pcall(method, self, script)
        if success and source then
            self.cache[scriptId] = source
            if quality == "full" then
                self.stats.success = self.stats.success + 1
            elseif quality == "partial" then
                self.stats.partial = self.stats.partial + 1
            else
                self.stats.failed = self.stats.failed + 1
            end
            return source, quality
        end
    end
    
    self.stats.failed = self.stats.failed + 1
    return "-- Decompilation completely failed", "failed"
end

function ScriptDecompiler:directSource(script)
    local source
    if APIs.gethiddenproperty then
        source = APIs.gethiddenproperty(script, "Source")
    else
        source = script.Source
    end
    
    if source and #source > 0 and not source:match("^%s*$") then
        return source, "full"
    end
    return nil
end

function ScriptDecompiler:nativeDecompile(script)
    if not APIs.decompile then return nil end
    
    local source = APIs.decompile(script)
    if source and #source > 10 and not source:match("^%s*%-%-") then
        return source, "full"
    end
    return nil
end

function ScriptDecompiler:customDecompile(script)
    if not APIs.getscriptbytecode then return nil end
    
    local bytecode = APIs.getscriptbytecode(script)
    if not bytecode or #bytecode == 0 then return nil end
    
    local decompiled = self:analyzeBytecode(bytecode, script)
    if decompiled and #decompiled > 50 then
        return decompiled, "partial"
    end
    
    return nil
end

function ScriptDecompiler:analyzeBytecode(bytecode, script)
    local analysis = {}
    table.insert(analysis, "-- Advanced Decompilation Analysis")
    table.insert(analysis, string.format("-- Script: %s", script:GetFullName()))
    table.insert(analysis, string.format("-- Bytecode Size: %d bytes\n", #bytecode))
    
    if APIs.getconstants then
        local constants = APIs.getconstants(script)
        if constants and #constants > 0 then
            table.insert(analysis, "-- Constants:")
            for i, const in ipairs(constants) do
                if i <= 50 then
                    table.insert(analysis, string.format("--   [%d] = %s", i, self:formatValue(const)))
                end
            end
            table.insert(analysis, "")
        end
    end
    
    if APIs.getprotos then
        local protos = APIs.getprotos(script)
        if protos and #protos > 0 then
            table.insert(analysis, string.format("-- Detected %d function prototypes", #protos))
        end
    end
    
    if APIs.getupvalues then
        local upvalues = APIs.getupvalues(script)
        if upvalues and type(upvalues) == "table" then
            table.insert(analysis, "\n-- Upvalues:")
            for name, value in pairs(upvalues) do
                table.insert(analysis, string.format("--   %s = %s", tostring(name), self:formatValue(value)))
            end
        end
    end
    
    local patterns = self:detectPatterns(bytecode)
    if #patterns > 0 then
        table.insert(analysis, "\n-- Detected Patterns:")
        for _, pattern in ipairs(patterns) do
            table.insert(analysis, "--   " .. pattern)
        end
    end
    
    return table.concat(analysis, "\n")
end

function ScriptDecompiler:detectPatterns(bytecode)
    local patterns = {}
    
    if bytecode:match("require") then
        table.insert(patterns, "ModuleScript dependencies detected")
    end
    
    if bytecode:match("RemoteEvent") or bytecode:match("RemoteFunction") then
        table.insert(patterns, "Network communication detected")
    end
    
    if bytecode:match("BindableEvent") or bytecode:match("BindableFunction") then
        table.insert(patterns, "Internal event system detected")
    end
    
    if bytecode:match("UserInputService") or bytecode:match("ContextActionService") then
        table.insert(patterns, "Input handling detected")
    end
    
    if bytecode:match("TweenService") or bytecode:match("RunService") then
        table.insert(patterns, "Animation/Runtime logic detected")
    end
    
    local loops = 0
    for _ in bytecode:gmatch("while") do loops = loops + 1 end
    for _ in bytecode:gmatch("for") do loops = loops + 1 end
    if loops > 0 then
        table.insert(patterns, string.format("Loop structures: ~%d", loops))
    end
    
    return patterns
end

function ScriptDecompiler:formatValue(value)
    local t = type(value)
    if t == "string" then
        return string.format('"%s"', value:gsub('"', '\\"'):sub(1, 100))
    elseif t == "table" then
        return "{ ... }"
    elseif t == "function" then
        return "function"
    else
        return tostring(value)
    end
end

function ScriptDecompiler:bytecodeExtract(script)
    if not APIs.getscriptbytecode then return nil end
    
    local bytecode = APIs.getscriptbytecode(script)
    if not bytecode or #bytecode == 0 then return nil end
    
    local output = string.format("-- Bytecode Dump (%d bytes)\n", #bytecode)
    output = output .. string.format("-- Script: %s\n\n", script:GetFullName())
    output = output .. "--[[\n" .. bytecode .. "\n--]]"
    
    return output, "partial"
end

function ScriptDecompiler:constantAnalysis(script)
    if not APIs.getconstants then return nil end
    
    local constants = APIs.getconstants(script)
    if not constants or #constants == 0 then return nil end
    
    local output = string.format("-- Constant Extraction (%d constants)\n", #constants)
    output = output .. string.format("-- Script: %s\n\n", script:GetFullName())
    
    for i, const in ipairs(constants) do
        output = output .. string.format("local CONST_%d = %s\n", i, self:formatValue(const))
    end
    
    return output, "partial"
end

function ScriptDecompiler:fallbackPlaceholder(script)
    local output = string.format("-- Failed to decompile: %s\n", script:GetFullName())
    output = output .. string.format("-- ClassName: %s\n", script.ClassName)
    
    if script.Parent then
        output = output .. string.format("-- Parent: %s\n", script.Parent:GetFullName())
    end
    
    output = output .. "\n-- No decompilation method succeeded"
    return output, "failed"
end

local InstanceCollector = {}
InstanceCollector.__index = InstanceCollector

function InstanceCollector.new(logger, propertyExtractor)
    local self = setmetatable({}, InstanceCollector)
    self.logger = logger
    self.propertyExtractor = propertyExtractor
    self.instances = {}
    self.instanceMap = {}
    self.idCounter = 0
    self.ignoreList = {
        "CoreGui", "CorePackages", "HttpRbxApiService", 
        "RobloxReplicatedStorage", "CSGDictionaryService"
    }
    return self
end

function InstanceCollector:generateId()
    self.idCounter = self.idCounter + 1
    return string.format("RBX%08X", self.idCounter)
end

function InstanceCollector:shouldIgnore(instance)
    if instance == game then return true end
    
    for _, name in ipairs(self.ignoreList) do
        if instance.Name == name or instance.ClassName == name then
            return true
        end
    end
    
    local success, parent = pcall(function() return instance.Parent end)
    if not success then return true end
    
    return false
end

function InstanceCollector:collectFromRoot(root, options)
    options = options or {}
    local collected = {}
    local descendants = root:GetDescendants()
    
    self.logger:log("INFO", string.format("Collecting from %s (%d descendants)", root.Name, #descendants))
    
    for i, instance in ipairs(descendants) do
        if not self:shouldIgnore(instance) then
            local data = self:processInstance(instance)
            if data then
                table.insert(collected, data)
            end
        end
        
        if i % 500 == 0 then
            task.wait()
            if options.onProgress then
                options.onProgress(i, #descendants)
            end
        end
    end
    
    return collected
end

function InstanceCollector:processInstance(instance)
    local id = self:generateId()
    
    local data = {
        id = id,
        instance = instance,
        className = instance.ClassName,
        name = instance.Name,
        properties = {},
        children = {},
        parent = instance.Parent
    }
    
    data.properties = self.propertyExtractor:getAllProperties(instance)
    
    self.instanceMap[instance] = data
    self.instances[id] = data
    
    return data
end

function InstanceCollector:collectNilInstances()
    if not APIs.getnilinstances then
        self.logger:log("WARN", "getnilinstances not available")
        return {}
    end
    
    local nilInsts = APIs.getnilinstances()
    local collected = {}
    
    self.logger:log("INFO", string.format("Found %d nil instances", #nilInsts))
    
    for _, instance in ipairs(nilInsts) do
        if not self:shouldIgnore(instance) then
            local data = self:processInstance(instance)
            if data then
                data.isNil = true
                table.insert(collected, data)
            end
        end
    end
    
    return collected
end

function InstanceCollector:buildHierarchy()
    local roots = {}
    
    for _, data in pairs(self.instanceMap) do
        if data.parent and self.instanceMap[data.parent] then
            local parentData = self.instanceMap[data.parent]
            table.insert(parentData.children, data)
        else
            table.insert(roots, data)
        end
    end
    
    return roots
end

function InstanceCollector:collectAll(options)
    options = options or {}
    self.instances = {}
    self.instanceMap = {}
    self.idCounter = 0
    
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
        {Services.ServerScriptService, options.serverScripts ~= false},
        {Services.ServerStorage, options.serverStorage ~= false},
    }
    
    local allCollected = {}
    
    for _, containerData in ipairs(containers) do
        local container, enabled = containerData[1], containerData[2]
        if enabled and container then
            local collected = self:collectFromRoot(container, options)
            for _, inst in ipairs(collected) do
                table.insert(allCollected, inst)
            end
        end
    end
    
    if options.nilInstances then
        local nilInsts = self:collectNilInstances()
        for _, inst in ipairs(nilInsts) do
            table.insert(allCollected, inst)
        end
    end
    
    if options.players then
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player.Character then
                local charData = self:collectFromRoot(player.Character, options)
                for _, inst in ipairs(charData) do
                    table.insert(allCollected, inst)
                end
            end
        end
    end
    
    self:buildHierarchy()
    
    self.logger:log("INFO", string.format("Collection complete: %d instances", #allCollected))
    return allCollected
end

local XMLSerializer = {}
XMLSerializer.__index = XMLSerializer

function XMLSerializer.new()
    local self = setmetatable({}, XMLSerializer)
    self.indent = 0
    return self
end

function XMLSerializer:escape(str)
    return tostring(str)
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
        :gsub("'", "&apos;")
end

function XMLSerializer:getIndent()
    return string.rep("  ", self.indent)
end

function XMLSerializer:serializeValue(value, valueType)
    valueType = valueType or typeof(value)
    
    local serializers = {
        string = function(v) return string.format('<string>%s</string>', self:escape(v)) end,
        number = function(v) return string.format('<double>%s</double>', v) end,
        boolean = function(v) return string.format('<bool>%s</bool>', v) end,
        
        Vector3 = function(v)
            return string.format('<Vector3><X>%.9g</X><Y>%.9g</Y><Z>%.9g</Z></Vector3>', v.X, v.Y, v.Z)
        end,
        
        Vector2 = function(v)
            return string.format('<Vector2><X>%.9g</X><Y>%.9g</Y></Vector2>', v.X, v.Y)
        end,
        
        CFrame = function(v)
            local components = {v:GetComponents()}
            local tags = {"X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"}
            local parts = {}
            for i, tag in ipairs(tags) do
                table.insert(parts, string.format('<%s>%.9g</%s>', tag, components[i], tag))
            end
            return '<CFrame>' .. table.concat(parts) .. '</CFrame>'
        end,
        
        Color3 = function(v)
            return string.format('<Color3uint8>%d %d %d</Color3uint8>',
                math.floor(v.R * 255 + 0.5),
                math.floor(v.G * 255 + 0.5),
                math.floor(v.B * 255 + 0.5))
        end,
        
        BrickColor = function(v)
            return string.format('<int>%d</int>', v.Number)
        end,
        
        EnumItem = function(v)
            return string.format('<token>%d</token>', v.Value)
        end,
    }
    
    local serializer = serializers[valueType]
    if serializer then
        return serializer(value)
    end
    
    return string.format('<string>%s</string>', self:escape(tostring(value)))
end

function XMLSerializer:serializeProperty(name, propData)
    local xml = self:getIndent()
    xml = xml .. string.format('<Property name="%s">', self:escape(name))
    xml = xml .. self:serializeValue(propData.value, propData.type)
    xml = xml .. '</Property>\n'
    return xml
end

function XMLSerializer:serializeInstance(instanceData)
    local xml = self:getIndent()
    xml = xml .. string.format('<Item class="%s" referent="%s">\n', instanceData.className, instanceData.id)
    
    self.indent = self.indent + 1
    
    xml = xml .. self:getIndent() .. '<Properties>\n'
    self.indent = self.indent + 1
    
    xml = xml .. self:getIndent()
    xml = xml .. string.format('<Property name="Name"><string>%s</string></Property>\n', self:escape(instanceData.name))
    
    for propName, propData in pairs(instanceData.properties) do
        if propName ~= "Name" and propName ~= "Parent" then
            local success, result = pcall(self.serializeProperty, self, propName, propData)
            if success then
                xml = xml .. result
            end
        end
    end
    
    self.indent = self.indent - 1
    xml = xml .. self:getIndent() .. '</Properties>\n'
    
    for _, child in ipairs(instanceData.children) do
        xml = xml .. self:serializeInstance(child)
    end
    
    self.indent = self.indent - 1
    xml = xml .. self:getIndent() .. '</Item>\n'
    
    return xml
end

function XMLSerializer:serialize(rootInstances)
    local xml = '<?xml version="1.0" encoding="UTF-8"?>\n<roblox version="4">\n'
    xml = xml .. '<Meta name="ExplicitAutoJoints">true</Meta>\n'
    
    for _, inst in ipairs(rootInstances) do
        xml = xml .. self:serializeInstance(inst)
    end
    
    xml = xml .. '</roblox>'
    return xml
end

local FileManager = {}
FileManager.__index = FileManager

function FileManager.new(logger)
    local self = setmetatable({}, FileManager)
    self.logger = logger
    self.folder = "SaveInstance_Output"
    
    if APIs.makefolder then
        APIs.makefolder(self.folder)
    end
    
    return self
end

function FileManager:generateFilename(extension)
    local success, gameInfo = pcall(function()
        return Services.MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    
    local gameName = "UnknownGame"
    if success and gameInfo and gameInfo.Name then
        gameName = gameInfo.Name:gsub("[^%w%-]", "_")
    end
    
    local timestamp = os.date("%Y%m%d_%H%M%S")
    return string.format("%s/%s_%s.%s", self.folder, gameName, timestamp, extension)
end

function FileManager:write(filename, content)
    if not APIs.writefile then
        self.logger:log("ERROR", "writefile not available")
        return false
    end
    
    local success, err = pcall(APIs.writefile, filename, content)
    if success then
        self.logger:log("INFO", "File written: " .. filename)
        return true, filename
    else
        self.logger:log("ERROR", "Failed to write file: " .. tostring(err))
        return false, err
    end
end

local GUI = {}
GUI.__index = GUI

function GUI.new()
    local self = setmetatable({}, GUI)
    self.enabled = true
    self.visible = false
    return self
end

function GUI:create()
    print("[SaveInstance] Creating GUI...")
    
    local success, err = pcall(function()
        local parent = getGuiParent()
        
        if not parent then
            error("No valid GUI parent found")
        end
        
        local existing = parent:FindFirstChild("SaveInstanceUI")
        if existing then
            existing:Destroy()
            wait(0.1)
        end
        
        self.screen = Instance.new("ScreenGui")
        self.screen.Name = "SaveInstanceUI"
        self.screen.ResetOnSpawn = false
        self.screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        self.screen.DisplayOrder = 999999999
        self.screen.IgnoreGuiInset = true
        self.screen.Enabled = true
        
        local main = Instance.new("Frame")
        main.Name = "Main"
        main.Size = UDim2.new(0, 520, 0, 420)
        main.Position = UDim2.new(0.5, -260, 0.5, -210)
        main.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
        main.BorderSizePixel = 0
        main.Visible = true
        main.Active = true
        main.Parent = self.screen
        
        local shadow = Instance.new("ImageLabel")
        shadow.Name = "Shadow"
        shadow.BackgroundTransparency = 1
        shadow.Position = UDim2.new(0, -15, 0, -15)
        shadow.Size = UDim2.new(1, 30, 1, 30)
        shadow.ZIndex = 0
        shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        shadow.ImageTransparency = 0.5
        shadow.ScaleType = Enum.ScaleType.Slice
        shadow.SliceCenter = Rect.new(10, 10, 118, 118)
        shadow.Parent = main
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = main
        
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, 45)
        titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        titleBar.BorderSizePixel = 0
        titleBar.Parent = main
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 12)
        titleCorner.Parent = titleBar
        
        local titleCover = Instance.new("Frame")
        titleCover.Size = UDim2.new(1, 0, 0, 12)
        titleCover.Position = UDim2.new(0, 0, 1, -12)
        titleCover.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        titleCover.BorderSizePixel = 0
        titleCover.Parent = titleBar
        
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -60, 1, 0)
        title.Position = UDim2.new(0, 15, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "💾 SaveInstance Pro"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 18
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = titleBar
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "CloseBtn"
        closeBtn.Size = UDim2.new(0, 35, 0, 35)
        closeBtn.Position = UDim2.new(1, -40, 0, 5)
        closeBtn.BackgroundColor3 = Color3.fromRGB(237, 66, 69)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "×"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.TextSize = 24
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = titleBar
        
        local closeBtnCorner = Instance.new("UICorner")
        closeBtnCorner.CornerRadius = UDim.new(0, 8)
        closeBtnCorner.Parent = closeBtn
        
        local status = Instance.new("TextLabel")
        status.Name = "Status"
        status.Size = UDim2.new(1, -30, 0, 25)
        status.Position = UDim2.new(0, 15, 0, 55)
        status.BackgroundTransparency = 1
        status.Text = "✓ Ready to save"
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
        status.TextSize = 14
        status.Font = Enum.Font.GothamMedium
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Parent = main
        self.status = status
        
        local progressBg = Instance.new("Frame")
        progressBg.Name = "ProgressBg"
        progressBg.Size = UDim2.new(1, -30, 0, 35)
        progressBg.Position = UDim2.new(0, 15, 0, 90)
        progressBg.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
        progressBg.BorderSizePixel = 0
        progressBg.Parent = main
        
        local progressBgCorner = Instance.new("UICorner")
        progressBgCorner.CornerRadius = UDim.new(0, 8)
        progressBgCorner.Parent = progressBg
        
        local progress = Instance.new("Frame")
        progress.Name = "Progress"
        progress.Size = UDim2.new(0, 0, 1, 0)
        progress.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        progress.BorderSizePixel = 0
        progress.Parent = progressBg
        self.progress = progress
        
        local progressCorner = Instance.new("UICorner")
        progressCorner.CornerRadius = UDim.new(0, 8)
        progressCorner.Parent = progress
        
        local progressText = Instance.new("TextLabel")
        progressText.Name = "ProgressText"
        progressText.Size = UDim2.new(1, 0, 1, 0)
        progressText.BackgroundTransparency = 1
        progressText.Text = "0%"
        progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
        progressText.TextSize = 14
        progressText.Font = Enum.Font.GothamBold
        progressText.ZIndex = 2
        progressText.Parent = progressBg
        self.progressText = progressText
        
        local log = Instance.new("ScrollingFrame")
        log.Name = "Log"
        log.Size = UDim2.new(1, -30, 0, 185)
        log.Position = UDim2.new(0, 15, 0, 135)
        log.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
        log.BorderSizePixel = 0
        log.ScrollBarThickness = 6
        log.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
        log.CanvasSize = UDim2.new(0, 0, 0, 0)
        log.Parent = main
        
        local logCorner = Instance.new("UICorner")
        logCorner.CornerRadius = UDim.new(0, 8)
        logCorner.Parent = log
        
        local logPadding = Instance.new("UIPadding")
        logPadding.PaddingLeft = UDim.new(0, 8)
        logPadding.PaddingRight = UDim.new(0, 8)
        logPadding.PaddingTop = UDim.new(0, 8)
        logPadding.PaddingBottom = UDim.new(0, 8)
        logPadding.Parent = log
        
        local logLayout = Instance.new("UIListLayout")
        logLayout.Padding = UDim.new(0, 3)
        logLayout.SortOrder = Enum.SortOrder.LayoutOrder
        logLayout.Parent = log
        self.log = log
        self.logLayout = logLayout
        
        local buttonFrame = Instance.new("Frame")
        buttonFrame.Name = "ButtonFrame"
        buttonFrame.Size = UDim2.new(1, -30, 0, 55)
        buttonFrame.Position = UDim2.new(0, 15, 1, -70)
        buttonFrame.BackgroundTransparency = 1
        buttonFrame.Parent = main
        
        self.buttons = {}
        local buttonConfigs = {
            {name = "Quick", text = "⚡ Quick Save", color = Color3.fromRGB(88, 101, 242), pos = 0},
            {name = "Advanced", text = "⚙️ Advanced", color = Color3.fromRGB(67, 181, 129), pos = 0.33},
            {name = "Players", text = "👥 + Players", color = Color3.fromRGB(255, 170, 51), pos = 0.66}
        }
        
        for _, config in ipairs(buttonConfigs) do
            local btn = Instance.new("TextButton")
            btn.Name = config.name
            btn.Size = UDim2.new(0.31, 0, 1, 0)
            btn.Position = UDim2.new(config.pos, config.pos > 0 and 10 or 0, 0, 0)
            btn.BackgroundColor3 = config.color
            btn.BorderSizePixel = 0
            btn.Text = config.text
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 15
            btn.Font = Enum.Font.GothamBold
            btn.AutoButtonColor = true
            btn.Parent = buttonFrame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = btn
            
            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(
                    math.min(config.color.R * 255 + 20, 255),
                    math.min(config.color.G * 255 + 20, 255),
                    math.min(config.color.B * 255 + 20, 255)
                )
            end)
            
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = config.color
            end)
            
            self.buttons[config.name] = btn
        end
        
        closeBtn.MouseButton1Click:Connect(function()
            self:destroy()
        end)
        
        self:makeDraggable(main, titleBar)
        
        self.screen.Parent = parent
        self.visible = true
        
        print("[SaveInstance] GUI created successfully!")
        print("[SaveInstance] Parent:", parent:GetFullName())
        print("[SaveInstance] Visible:", self.screen.Enabled)
        
        self:addLog("GUI initialized", Color3.fromRGB(100, 255, 100))
        self:addLog("Executor: " .. detectExecutor(), Color3.fromRGB(150, 150, 255))
        self:addLog("Ready to save!", Color3.fromRGB(100, 255, 100))
    end)
    
    if not success then
        warn("[SaveInstance] GUI creation failed:", err)
        warn("[SaveInstance] Falling back to notification system")
        self:createFallbackNotification()
        return false
    end
    
    return true
end

function GUI:createFallbackNotification()
    local function notify(msg)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "SaveInstance Pro",
            Text = msg,
            Duration = 5
        })
    end
    
    notify("SaveInstance loaded! Check console for commands.")
    print("\n" .. string.rep("=", 50))
    print("SAVEINSTANCE PRO - Console Mode")
    print(string.rep("=", 50))
    print("GUI failed to load. Use these commands:")
    print("  _G.SaveInstance.quickSave()")
    print("  _G.SaveInstance.advancedSave()")
    print("  _G.SaveInstance.showGUI()")
    print(string.rep("=", 50) .. "\n")
end

function GUI:makeDraggable(frame, handle)
    local dragging = false
    local dragInput, dragStart, startPos
    
    local function update(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    Services.UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

function GUI:setProgress(value, text)
    if not self.progress then return end
    
    value = math.clamp(value, 0, 1)
    
    self.progress:TweenSize(
        UDim2.new(value, 0, 1, 0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.25,
        true
    )
    
    if text then
        self.progressText.Text = text
    else
        self.progressText.Text = string.format("%d%%", math.floor(value * 100))
    end
end

function GUI:setStatus(text, color)
    if not self.status then return end
    
    self.status.Text = text
    if color then
        self.status.TextColor3 = color
    end
end

function GUI:addLog(message, color)
    if not self.log then 
        print("[SaveInstance Log]", message)
        return 
    end
    
    local entry = Instance.new("TextLabel")
    entry.Size = UDim2.new(1, -10, 0, 18)
    entry.BackgroundTransparency = 1
    entry.Text = string.format("[%s] %s", os.date("%H:%M:%S"), message)
    entry.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    entry.TextSize = 12
    entry.Font = Enum.Font.Code
    entry.TextXAlignment = Enum.TextXAlignment.Left
    entry.TextTruncate = Enum.TextTruncate.AtEnd
    entry.TextWrapped = false
    entry.Parent = self.log
    
    self.log.CanvasSize = UDim2.new(0, 0, 0, self.logLayout.AbsoluteContentSize.Y + 10)
    self.log.CanvasPosition = Vector2.new(0, self.logLayout.AbsoluteContentSize.Y)
end

function GUI:destroy()
    if self.screen then
        self.screen:Destroy()
        self.screen = nil
        self.visible = false
        print("[SaveInstance] GUI destroyed")
    end
end

function GUI:toggle()
    if self.screen then
        self.screen.Enabled = not self.screen.Enabled
        self.visible = self.screen.Enabled
        print("[SaveInstance] GUI toggled:", self.visible and "Visible" or "Hidden")
    else
        print("[SaveInstance] GUI not created yet")
        self:create()
    end
end

local Core = {}
Core.__index = Core

function Core.new()
    local self = setmetatable({}, Core)
    
    self.logger = Logger.new()
    self.propertyExtractor = PropertyExtractor.new()
    self.collector = InstanceCollector.new(self.logger, self.propertyExtractor)
    self.decompiler = ScriptDecompiler.new(self.logger)
    self.serializer = XMLSerializer.new()
    self.fileManager = FileManager.new(self.logger)
    self.gui = GUI.new()
    
    self.executor = detectExecutor()
    self.logger:log("INFO", "Executor: " .. self.executor)
    
    return self
end

function Core:initialize()
    print("[SaveInstance] Initializing...")
    
    local guiCreated = self.gui:create()
    
    if guiCreated then
        self.logger:onLog(function(entry)
            local colors = {
                INFO = Color3.fromRGB(100, 200, 255),
                WARN = Color3.fromRGB(255, 200, 100),
                ERROR = Color3.fromRGB(255, 100, 100),
                CRITICAL = Color3.fromRGB(255, 50, 50)
            }
            self.gui:addLog(entry.message, colors[entry.level])
        end)
        
        if self.gui.buttons.Quick then
            self.gui.buttons.Quick.MouseButton1Click:Connect(function()
                task.spawn(function() self:quickSave() end)
            end)
        end
        
        if self.gui.buttons.Advanced then
            self.gui.buttons.Advanced.MouseButton1Click:Connect(function()
                task.spawn(function() self:advancedSave() end)
            end)
        end
        
        if self.gui.buttons.Players then
            self.gui.buttons.Players.MouseButton1Click:Connect(function()
                task.spawn(function() self:saveWithPlayers() end)
            end)
        end
    end
    
    _G.SaveInstance = {
        quickSave = function() return self:quickSave() end,
        advancedSave = function() return self:advancedSave() end,
        saveWithPlayers = function() return self:saveWithPlayers() end,
        showGUI = function() self.gui:toggle() end,
        core = self
    }
    
    self.logger:log("INFO", "System ready")
    
    print("\n" .. string.rep("=", 60))
    print("SaveInstance Pro Loaded Successfully!")
    print(string.rep("=", 60))
    print("Executor:", self.executor)
    print("GUI:", guiCreated and "✓ Visible" or "✗ Failed (using console mode)")
    print("\nConsole Commands:")
    print("  _G.SaveInstance.quickSave()")
    print("  _G.SaveInstance.advancedSave()")
    print("  _G.SaveInstance.saveWithPlayers()")
    print("  _G.SaveInstance.showGUI()")
    print(string.rep("=", 60) .. "\n")
end

function Core:quickSave()
    local options = {
        serverScripts = false,
        serverStorage = false,
        nilInstances = false,
        players = false
    }
    
    return self:execute(options)
end

function Core:advancedSave()
    local options = {
        serverScripts = true,
        serverStorage = true,
        nilInstances = true,
        players = false
    }
    
    return self:execute(options)
end

function Core:saveWithPlayers()
    local options = {
        serverScripts = true,
        serverStorage = true,
        nilInstances = true,
        players = true
    }
    
    return self:execute(options)
end

function Core:execute(options)
    local startTime = tick()
    
    self.logger:log("INFO", "Starting save operation")
    self.gui:setStatus("⏳ Collecting instances...", Color3.fromRGB(255, 200, 100))
    self.gui:setProgress(0)
    
    options.onProgress = function(current, total)
        local progress = current / total
        self.gui:setProgress(progress * 0.3, string.format("Collecting %d/%d", current, total))
    end
    
    local instances = self.collector:collectAll(options)
    self.gui:setProgress(0.3)
    
    self.logger:log("INFO", string.format("Collected %d instances", #instances))
    self.gui:setStatus("🔧 Decompiling scripts...", Color3.fromRGB(255, 200, 100))
    
    local scriptCount = 0
    for _, data in ipairs(instances) do
        if data.instance:IsA("LuaSourceContainer") then
            scriptCount = scriptCount + 1
            local source, quality = self.decompiler:decompile(data.instance)
            
            if not data.properties then
                data.properties = {}
            end
            
            data.properties.Source = {
                value = source,
                type = "string",
                quality = quality
            }
        end
        
        if scriptCount % 10 == 0 then
            local progress = 0.3 + (scriptCount / #instances) * 0.4
            self.gui:setProgress(progress, string.format("Decompiling %d scripts", scriptCount))
            task.wait()
        end
    end
    
    self.gui:setProgress(0.7)
    self.logger:log("INFO", string.format("Decompiled %d scripts", scriptCount))
    
    self.gui:setStatus("🔨 Building hierarchy...", Color3.fromRGB(255, 200, 100))
    local roots = self.collector:buildHierarchy()
    self.gui:setProgress(0.8)
    
    self.gui:setStatus("📝 Generating XML...", Color3.fromRGB(255, 200, 100))
    local xml = self.serializer:serialize(roots)
    self.gui:setProgress(0.9)
    
    self.gui:setStatus("💾 Writing file...", Color3.fromRGB(255, 200, 100))
    local filename = self.fileManager:generateFilename("rbxlx")
    local success, result = self.fileManager:write(filename, xml)
    
    local logFilename = self.fileManager:generateFilename("log")
    self.fileManager:write(logFilename, self.logger:export())
    
    self.gui:setProgress(1, "100%")
    
    local duration = tick() - startTime
    
    if success then
        self.logger:log("INFO", string.format("Save complete in %.2fs", duration))
        self.logger:log("INFO", "File: " .. result)
        self.gui:setStatus(string.format("✓ Complete! (%d instances, %.2fs)", #instances, duration), Color3.fromRGB(100, 255, 100))
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "SaveInstance Complete!",
            Text = string.format("%d instances saved in %.2fs", #instances, duration),
            Duration = 5
        })
    else
        self.logger:log("ERROR", "Save failed: " .. tostring(result))
        self.gui:setStatus("❌ Save failed!", Color3.fromRGB(255, 100, 100))
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "SaveInstance Failed",
            Text = "Check console for details",
            Duration = 5
        })
    end
    
    return {
        success = success,
        instances = #instances,
        scripts = scriptCount,
        duration = duration,
        file = result
    }
end

local mainCore = Core.new()
mainCore:initialize()

return SaveInstanceCore
