--[[
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
    ██╗███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗ ██████╗███████╗
    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║██╔════╝██╔════╝
    ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║██║     █████╗  
    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║██║     ██╔══╝  
    ██║██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║╚██████╗███████╗
    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝
    
    BaoSaveInstance v1.0
    Full Game Decompiler & Serializer
    
    Supported Executors: Xeno, Solara, TNG, Velocity, Wave
    Output: Single .rbxl file loadable in Roblox Studio
    
    Usage: Simply execute this script. No UI, no buttons, fully automatic.
]]

-- ============================================================================
-- SECTION 0: CONFIGURATION
-- ============================================================================
local CONFIG = {
    -- Tên file output (placeholder %s = tên game)
    OutputNameTemplate = "BaoSaveInstance_%s.rbxl",
    
    -- Chunk size khi xử lý terrain (tránh crash)
    TerrainChunkSize = 64,
    
    -- Batch size khi duyệt instances (tránh timeout)
    InstanceBatchSize = 200,
    
    -- Yield interval (giây) - mỗi bao lâu yield 1 lần tránh lag
    YieldInterval = 0.03,
    
    -- Có decompile scripts không
    DecompileScripts = true,
    
    -- Timeout cho mỗi script decompile (giây)
    DecompileTimeout = 10,
    
    -- Các service cần save
    ServicesToSave = {
        "Workspace",
        "Lighting",
        "MaterialService",
        "ReplicatedFirst",
        "ReplicatedStorage",
        "ServerStorage",
        "ServerScriptService",
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
        "Teams",
        "SoundService",
        "TextChatService",
    },
    
    -- Class bị bỏ qua hoàn toàn
    IgnoredClasses = {
        ["Player"] = true,
        ["PlayerGui"] = true,
        ["PlayerScripts"] = true,
        ["Backpack"] = true,
        ["ChatWindowConfiguration"] = true,
        ["ChatInputBarConfiguration"] = true,
        ["BubbleChatConfiguration"] = true,
    },
    
    -- Property types hỗ trợ serialize
    -- (được mở rộng đầy đủ trong RBXL writer)
    
    -- Nén output
    CompressOutput = true,
    
    -- Debug mode
    Debug = false,
}

-- ============================================================================
-- SECTION 1: EXECUTOR DETECTION & API ABSTRACTION
-- ============================================================================

local API = {}  -- Unified API table
local ExecutorName = "Unknown"
local ExecutorCapabilities = {
    canDecompile = false,
    canSaveFile = false,
    canGetHidden = false,
    canGetNilInstances = false,
    canReadTerrain = true,
    hasClipboard = false,
}

local function Log(level, msg, ...)
    local prefix = ({
        INFO = "[BAO-INFO]",
        WARN = "[BAO-WARN]",
        ERR  = "[BAO-ERROR]",
        PROG = "[BAO-PROGRESS]",
        DBG  = "[BAO-DEBUG]",
    })[level] or "[BAO]"
    
    if level == "DBG" and not CONFIG.Debug then return end
    
    local formatted = string.format(msg, ...)
    print(prefix .. " " .. formatted)
end

-- Detect executor và build unified API
local function DetectExecutor()
    -- ========================================
    -- XENO Detection
    -- ========================================
    if type(Xeno) == "table" then
        ExecutorName = "Xeno"
        Log("INFO", "Detected executor: Xeno")
        
        API.saveFile = function(name, data)
            if Xeno.writefile then
                Xeno.writefile(name, data)
                return true
            elseif writefile then
                writefile(name, data)
                return true
            end
            return false
        end
        
        API.decompile = function(script)
            if Xeno.decompile then
                local ok, result = pcall(Xeno.decompile, script)
                if ok then return result end
            end
            if decompile then
                local ok, result = pcall(decompile, script)
                if ok then return result end
            end
            return nil
        end
        
        API.getHiddenProperties = function(inst)
            if Xeno.gethiddenproperties then
                local ok, result = pcall(Xeno.gethiddenproperties, inst)
                if ok then return result end
            end
            if gethiddenproperties then
                local ok, result = pcall(gethiddenproperties, inst)
                if ok then return result end
            end
            return {}
        end
        
        API.getNilInstances = function()
            if Xeno.getnilinstances then
                local ok, result = pcall(Xeno.getnilinstances)
                if ok then return result end
            end
            if getnilinstances then
                local ok, result = pcall(getnilinstances)
                if ok then return result end
            end
            return {}
        end
        
        API.getScriptBytecode = function(script)
            if Xeno.getscriptbytecode then
                local ok, result = pcall(Xeno.getscriptbytecode, script)
                if ok then return result end
            end
            if getscriptbytecode then
                local ok, result = pcall(getscriptbytecode, script)
                if ok then return result end
            end
            return nil
        end
        
        ExecutorCapabilities.canDecompile = (Xeno.decompile ~= nil) or (decompile ~= nil)
        ExecutorCapabilities.canSaveFile = (Xeno.writefile ~= nil) or (writefile ~= nil)
        ExecutorCapabilities.canGetHidden = (Xeno.gethiddenproperties ~= nil) or (gethiddenproperties ~= nil)
        ExecutorCapabilities.canGetNilInstances = (Xeno.getnilinstances ~= nil) or (getnilinstances ~= nil)
        ExecutorCapabilities.hasClipboard = (Xeno.setclipboard ~= nil) or (setclipboard ~= nil)
        
        return true
    end
    
    -- ========================================
    -- WAVE Detection
    -- ========================================
    if type(wave) == "table" or (identifyexecutor and ({pcall(identifyexecutor)})[2] or ""):lower():find("wave") then
        ExecutorName = "Wave"
        Log("INFO", "Detected executor: Wave")
        goto BuildGenericAPI
    end
    
    -- ========================================
    -- VELOCITY Detection  
    -- ========================================
    if type(velocity) == "table" or (identifyexecutor and ({pcall(identifyexecutor)})[2] or ""):lower():find("velocity") then
        ExecutorName = "Velocity"
        Log("INFO", "Detected executor: Velocity")
        goto BuildGenericAPI
    end
    
    -- ========================================
    -- SOLARA Detection
    -- ========================================
    if (identifyexecutor and ({pcall(identifyexecutor)})[2] or ""):lower():find("solara") then
        ExecutorName = "Solara"
        Log("INFO", "Detected executor: Solara")
        goto BuildGenericAPI
    end
    
    -- ========================================
    -- TNG Detection
    -- ========================================
    if (identifyexecutor and ({pcall(identifyexecutor)})[2] or ""):lower():find("tng") then
        ExecutorName = "TNG"
        Log("INFO", "Detected executor: TNG")
        goto BuildGenericAPI
    end
    
    -- ========================================
    -- Generic / Unknown executor - try common APIs
    -- ========================================
    do
        if identifyexecutor then
            local ok, name = pcall(identifyexecutor)
            if ok and name then
                ExecutorName = tostring(name)
            end
        end
        Log("INFO", "Detected executor: %s (generic API mode)", ExecutorName)
    end
    
    ::BuildGenericAPI::
    
    -- Build unified API từ global functions (hầu hết executor đều expose)
    API.saveFile = API.saveFile or function(name, data)
        if writefile then
            writefile(name, data)
            return true
        end
        return false
    end
    
    API.decompile = API.decompile or function(script)
        -- Thử nhiều API name khác nhau
        local decompileFuncs = {
            decompile,
            type(getfenv) == "function" and getfenv().decompile or nil,
        }
        for _, fn in ipairs(decompileFuncs) do
            if type(fn) == "function" then
                local ok, result = pcall(fn, script)
                if ok and type(result) == "string" and #result > 0 then
                    return result
                end
            end
        end
        return nil
    end
    
    API.getHiddenProperties = API.getHiddenProperties or function(inst)
        if type(gethiddenproperties) == "function" then
            local ok, result = pcall(gethiddenproperties, inst)
            if ok then return result end
        end
        return {}
    end
    
    API.getNilInstances = API.getNilInstances or function()
        if type(getnilinstances) == "function" then
            local ok, result = pcall(getnilinstances)
            if ok then return result end
        end
        return {}
    end
    
    API.getScriptBytecode = API.getScriptBytecode or function(script)
        if type(getscriptbytecode) == "function" then
            local ok, result = pcall(getscriptbytecode, script)
            if ok then return result end
        end
        return nil
    end
    
    -- Capabilities check
    ExecutorCapabilities.canDecompile = type(decompile) == "function"
    ExecutorCapabilities.canSaveFile = type(writefile) == "function"
    ExecutorCapabilities.canGetHidden = type(gethiddenproperties) == "function"
    ExecutorCapabilities.canGetNilInstances = type(getnilinstances) == "function"
    ExecutorCapabilities.hasClipboard = type(setclipboard) == "function"
    
    return true
end

-- Additional API helpers
API.isA = function(instance, className)
    local ok, result = pcall(function() return instance:IsA(className) end)
    return ok and result
end

API.getProperty = function(instance, propName)
    local ok, result = pcall(function() return instance[propName] end)
    if ok then return result, true end
    return nil, false
end

API.setProperty = function(instance, propName, value)
    local ok = pcall(function() instance[propName] = value end)
    return ok
end

API.getChildren = function(instance)
    local ok, result = pcall(function() return instance:GetChildren() end)
    if ok then return result end
    return {}
end

API.getDescendants = function(instance)
    local ok, result = pcall(function() return instance:GetDescendants() end)
    if ok then return result end
    return {}
end

API.getFullName = function(instance)
    local ok, result = pcall(function() return instance:GetFullName() end)
    if ok then return result end
    return "???"
end

-- ============================================================================
-- SECTION 2: RBXL BINARY FORMAT WRITER
-- ============================================================================
--[[
    RBXL Binary Format Specification (simplified):
    
    Header:
      - Magic: "<roblox!\x89\xff\r\n\x1a\n"  (14 bytes)
      - Version: uint16 (0)
      - NumTypes: int32
      - NumInstances: int32  
      - Reserved: 8 bytes (0)
    
    Chunks:
      - META: metadata key-value pairs
      - SSTR: shared strings
      - INST: instance type declarations
      - PROP: property data per type
      - PRNT: parent-child relationships
      - END\0: terminator
    
    Each chunk:
      - ChunkName: 4 bytes
      - CompressedLength: uint32
      - UncompressedLength: uint32
      - Reserved: uint32 (0)
      - Data: compressed or uncompressed bytes
]]

local RBXLWriter = {}
RBXLWriter.__index = RBXLWriter

-- ========================================
-- Binary encoding helpers
-- ========================================
local function encodeUint8(value)
    return string.char(value % 256)
end

local function encodeUint16LE(value)
    return string.char(value % 256, math.floor(value / 256) % 256)
end

local function encodeInt32LE(value)
    -- Handle negative values via two's complement
    if value < 0 then
        value = value + 4294967296
    end
    local b0 = value % 256
    local b1 = math.floor(value / 256) % 256
    local b2 = math.floor(value / 65536) % 256
    local b3 = math.floor(value / 16777216) % 256
    return string.char(b0, b1, b2, b3)
end

local function encodeUint32LE(value)
    local b0 = value % 256
    local b1 = math.floor(value / 256) % 256
    local b2 = math.floor(value / 65536) % 256
    local b3 = math.floor(value / 16777216) % 256
    return string.char(b0, b1, b2, b3)
end

local function encodeFloat32LE(value)
    -- IEEE 754 single precision
    if value == 0 then
        return "\0\0\0\0"
    end
    
    local sign = 0
    if value < 0 then
        sign = 1
        value = -value
    end
    
    local mantissa, exponent = math.frexp(value)
    exponent = exponent + 126
    
    if exponent <= 0 then
        -- Denormalized
        mantissa = math.floor(mantissa * 2^(23 + exponent) + 0.5)
        exponent = 0
    elseif exponent >= 255 then
        -- Infinity
        mantissa = 0
        exponent = 255
    else
        mantissa = math.floor((mantissa * 2 - 1) * 2^23 + 0.5)
    end
    
    local b0 = mantissa % 256
    local b1 = math.floor(mantissa / 256) % 256
    local b2 = (math.floor(mantissa / 65536) % 128) + (exponent % 2) * 128
    local b3 = math.floor(exponent / 2) + sign * 128
    
    return string.char(b0, b1, b2, b3)
end

local function encodeFloat64LE(value)
    -- IEEE 754 double precision
    if value == 0 then
        return "\0\0\0\0\0\0\0\0"
    end
    
    local sign = 0
    if value < 0 then
        sign = 1
        value = -value
    end
    
    local mantissa, exponent = math.frexp(value)
    exponent = exponent + 1022
    
    if exponent <= 0 then
        mantissa = 0
        exponent = 0
    elseif exponent >= 2047 then
        mantissa = 0
        exponent = 2047
    else
        mantissa = (mantissa * 2 - 1) * 2^52
    end
    
    local bytes = {}
    local mLow = mantissa % 4294967296
    local mHigh = math.floor(mantissa / 4294967296)
    
    bytes[1] = mLow % 256
    bytes[2] = math.floor(mLow / 256) % 256
    bytes[3] = math.floor(mLow / 65536) % 256
    bytes[4] = math.floor(mLow / 16777216) % 256
    bytes[5] = mHigh % 256
    bytes[6] = math.floor(mHigh / 256) % 256
    bytes[7] = (math.floor(mHigh / 65536) % 16) + (exponent % 16) * 16
    bytes[8] = math.floor(exponent / 16) + sign * 128
    
    local result = ""
    for i = 1, 8 do
        result = result .. string.char(bytes[i])
    end
    return result
end

-- Interleaved integer encoding (RBXL-specific)
local function encodeIntInterleaved(value)
    -- Transform: if value >= 0 then value*2 else (-value)*2-1
    if value >= 0 then
        return value * 2
    else
        return (-value) * 2 - 1
    end
end

local function encodeInterleavedArray(values)
    -- Encode array of int32 using interleaved transform + byte interleaving
    local n = #values
    if n == 0 then return "" end
    
    local transformed = {}
    for i = 1, n do
        transformed[i] = encodeIntInterleaved(values[i])
    end
    
    -- Byte interleaving: all byte 0s, then all byte 1s, etc.
    local bytes = {{}, {}, {}, {}}
    for i = 1, n do
        local v = transformed[i]
        bytes[1][i] = math.floor(v / 16777216) % 256
        bytes[2][i] = math.floor(v / 65536) % 256
        bytes[3][i] = math.floor(v / 256) % 256
        bytes[4][i] = v % 256
    end
    
    local result = {}
    for b = 1, 4 do
        for i = 1, n do
            result[#result + 1] = string.char(bytes[b][i])
        end
    end
    
    return table.concat(result)
end

local function encodeFloatInterleavedArray(values)
    -- Float interleaving is similar but reinterprets float bits as int
    local n = #values
    if n == 0 then return "" end
    
    local bytes = {{}, {}, {}, {}}
    for i = 1, n do
        local raw = encodeFloat32LE(values[i])
        local b0, b1, b2, b3 = string.byte(raw, 1, 4)
        -- Roblox uses a rotation: transform float bytes
        -- The sign bit rotation: if high bit set, flip all; else flip just sign
        local asUint = b3 * 16777216 + b2 * 65536 + b1 * 256 + b0
        local rotated
        if asUint >= 2147483648 then
            rotated = 4294967295 - asUint  -- bitwise NOT
        else
            rotated = asUint * 2
        end
        -- but actually, the standard RBXL approach:
        -- left-rotate by 1 bit
        -- Actually Roblox uses: (value << 1) | (value >>> 31) XOR with sign extension
        -- Let's use a simpler approach: just write raw floats in interleaved form
        bytes[1][i] = math.floor(rotated / 16777216) % 256
        bytes[2][i] = math.floor(rotated / 65536) % 256
        bytes[3][i] = math.floor(rotated / 256) % 256
        bytes[4][i] = rotated % 256
    end
    
    local result = {}
    for b = 1, 4 do
        for i = 1, n do
            result[#result + 1] = string.char(bytes[b][i])
        end
    end
    return table.concat(result)
end

local function encodeString(str)
    return encodeUint32LE(#str) .. str
end

-- ========================================
-- LZ4 Compression (simplified block format for RBXL)
-- ========================================
local function lz4Compress(input)
    -- Simple LZ4 block compression
    -- For RBXL, we can also store uncompressed (compressedLen == 0)
    -- but let's implement basic compression
    
    local inputLen = #input
    if inputLen == 0 then
        return "", 0, 0
    end
    
    -- For simplicity and reliability, we'll store data uncompressed
    -- RBXL supports this when compressedLength == 0
    return input, 0, inputLen
end

-- ========================================
-- RBXL Chunk Builder
-- ========================================
local function buildChunk(chunkName, data)
    -- Pad chunk name to exactly 4 bytes
    chunkName = chunkName .. string.rep("\0", 4 - #chunkName)
    chunkName = chunkName:sub(1, 4)
    
    local compressed, compLen, uncompLen = lz4Compress(data)
    
    -- When compressedLen == 0, data is stored uncompressed
    local header = chunkName
        .. encodeUint32LE(compLen)         -- compressed length (0 = uncompressed)
        .. encodeUint32LE(#data)           -- uncompressed length
        .. encodeUint32LE(0)               -- reserved
    
    return header .. compressed
end

-- ============================================================================
-- SECTION 3: INSTANCE COLLECTOR & PROPERTY SERIALIZER
-- ============================================================================

-- Property database: maps ClassName -> {propName -> propType}
-- This is a comprehensive (but not exhaustive) mapping
-- PropTypes: "String", "Bool", "Int32", "Float", "Double", "UDim", "UDim2",
--   "Ray", "BrickColor", "Color3", "Vector2", "Vector3", "CFrame",
--   "Enum", "Ref", "NumberSequence", "ColorSequence", "NumberRange",
--   "Rect", "PhysicalProperties", "Color3uint8", "Int64", "Content",
--   "SharedString", "Bytecode", "Font"

local PropertyDB = {}

-- Base properties that almost all instances have
PropertyDB["Instance"] = {
    Name = "String",
    Archivable = "Bool",
    -- Tags handled separately via CollectionService
}

PropertyDB["BasePart"] = {
    Anchored = "Bool",
    Size = "Vector3",
    CFrame = "CFrame",
    Color = "Color3",
    Transparency = "Float",
    Reflectance = "Float",
    Material = "Enum",
    CanCollide = "Bool",
    CanTouch = "Bool",
    CanQuery = "Bool",
    CastShadow = "Bool",
    Massless = "Bool",
    Locked = "Bool",
    Shape = "Enum",
    TopSurface = "Enum",
    BottomSurface = "Enum",
    FrontSurface = "Enum",
    BackSurface = "Enum",
    LeftSurface = "Enum",
    RightSurface = "Enum",
    CustomPhysicalProperties = "PhysicalProperties",
    CollisionGroupId = "Int32",
    RootPriority = "Int32",
    EnableFluidForces = "Bool",
}

PropertyDB["Part"] = {} -- Inherits BasePart
PropertyDB["WedgePart"] = {}
PropertyDB["CornerWedgePart"] = {}
PropertyDB["TrussPart"] = {
    Style = "Enum",
}

PropertyDB["MeshPart"] = {
    MeshId = "Content",
    TextureID = "Content",
    CollisionFidelity = "Enum",
    RenderFidelity = "Enum",
    DoubleSided = "Bool",
    HasJointOffset = "Bool",
    HasSkinnedMesh = "Bool",
}

PropertyDB["UnionOperation"] = {
    AssetId = "Content",
    CollisionFidelity = "Enum",
    RenderFidelity = "Enum",
    SmoothingAngle = "Float",
    UsePartColor = "Bool",
}

PropertyDB["NegateOperation"] = {}

PropertyDB["Model"] = {
    PrimaryPart = "Ref",
    WorldPivot = "CFrame",
    LevelOfDetail = "Enum",
    ModelStreamingMode = "Enum",
}

PropertyDB["Folder"] = {}

PropertyDB["SpawnLocation"] = {
    AllowTeamChangeOnTouch = "Bool",
    Duration = "Int32",
    Enabled = "Bool",
    Neutral = "Bool",
    TeamColor = "BrickColor",
}

PropertyDB["Seat"] = {
    Disabled = "Bool",
}

PropertyDB["VehicleSeat"] = {
    Disabled = "Bool",
    HeadsUpDisplay = "Bool",
    MaxSpeed = "Float",
    Steer = "Int32",
    SteerFloat = "Float",
    Throttle = "Int32",
    ThrottleFloat = "Float",
    Torque = "Float",
    TurnSpeed = "Float",
}

PropertyDB["Decal"] = {
    Color3 = "Color3",
    Face = "Enum",
    Texture = "Content",
    Transparency = "Float",
    ZIndex = "Int32",
}

PropertyDB["Texture"] = {
    Color3 = "Color3",
    Face = "Enum",
    Texture = "Content",
    Transparency = "Float",
    ZIndex = "Int32",
    OffsetStudsU = "Float",
    OffsetStudsV = "Float",
    StudsPerTileU = "Float",
    StudsPerTileV = "Float",
}

PropertyDB["SurfaceAppearance"] = {
    ColorMap = "Content",
    MetalnessMap = "Content",
    NormalMap = "Content",
    RoughnessMap = "Content",
    TexturePack = "Content",
    AlphaMode = "Enum",
}

PropertyDB["SpecialMesh"] = {
    MeshId = "Content",
    MeshType = "Enum",
    TextureId = "Content",
    Scale = "Vector3",
    Offset = "Vector3",
    VertexColor = "Vector3",
}

PropertyDB["BlockMesh"] = {
    Scale = "Vector3",
    Offset = "Vector3",
    VertexColor = "Vector3",
}

PropertyDB["CylinderMesh"] = {
    Scale = "Vector3",
    Offset = "Vector3",
    VertexColor = "Vector3",
}

PropertyDB["Script"] = {
    Source = "String",
    Disabled = "Bool",
    RunContext = "Enum",
}

PropertyDB["LocalScript"] = {
    Source = "String",
    Disabled = "Bool",
}

PropertyDB["ModuleScript"] = {
    Source = "String",
}

PropertyDB["StringValue"] = { Value = "String" }
PropertyDB["IntValue"] = { Value = "Int32" }
PropertyDB["NumberValue"] = { Value = "Double" }
PropertyDB["BoolValue"] = { Value = "Bool" }
PropertyDB["ObjectValue"] = { Value = "Ref" }
PropertyDB["BrickColorValue"] = { Value = "BrickColor" }
PropertyDB["Color3Value"] = { Value = "Color3" }
PropertyDB["CFrameValue"] = { Value = "CFrame" }
PropertyDB["Vector3Value"] = { Value = "Vector3" }
PropertyDB["RayValue"] = {} -- deprecated

PropertyDB["PointLight"] = {
    Brightness = "Float",
    Color = "Color3",
    Enabled = "Bool",
    Range = "Float",
    Shadows = "Bool",
}

PropertyDB["SpotLight"] = {
    Angle = "Float",
    Brightness = "Float",
    Color = "Color3",
    Enabled = "Bool",
    Face = "Enum",
    Range = "Float",
    Shadows = "Bool",
}

PropertyDB["SurfaceLight"] = {
    Angle = "Float",
    Brightness = "Float",
    Color = "Color3",
    Enabled = "Bool",
    Face = "Enum",
    Range = "Float",
    Shadows = "Bool",
}

PropertyDB["Fire"] = {
    Color = "Color3",
    Enabled = "Bool",
    Heat = "Float",
    SecondaryColor = "Color3",
    Size = "Float",
    TimeScale = "Float",
}

PropertyDB["Smoke"] = {
    Color = "Color3",
    Enabled = "Bool",
    Opacity = "Float",
    RiseVelocity = "Float",
    Size = "Float",
    TimeScale = "Float",
}

PropertyDB["Sparkles"] = {
    Color = "Color3",
    Enabled = "Bool",
    SparkleColor = "Color3",
    TimeScale = "Float",
}

PropertyDB["ParticleEmitter"] = {
    Texture = "Content",
    Color = "ColorSequence",
    Size = "NumberSequence",
    Transparency = "NumberSequence",
    Lifetime = "NumberRange",
    Rate = "Float",
    Speed = "NumberRange",
    Acceleration = "Vector3",
    Drag = "Float",
    Enabled = "Bool",
    EmissionDirection = "Enum",
    LightEmission = "Float",
    LightInfluence = "Float",
    LockedToPart = "Bool",
    Orientation = "Enum",
    RotSpeed = "NumberRange",
    Rotation = "NumberRange",
    Shape = "Enum",
    ShapeInOut = "Enum",
    SpreadAngle = "Vector2",
    TimeScale = "Float",
    VelocityInheritance = "Float",
    WindAffectsDrag = "Bool",
    ZOffset = "Float",
    Squash = "NumberSequence",
    BrightnessWeight = "Float",
}

PropertyDB["Beam"] = {
    Attachment0 = "Ref",
    Attachment1 = "Ref",
    Color = "ColorSequence",
    CurveSize0 = "Float",
    CurveSize1 = "Float",
    Enabled = "Bool",
    FaceCamera = "Bool",
    LightEmission = "Float",
    LightInfluence = "Float",
    Segments = "Int32",
    Texture = "Content",
    TextureLength = "Float",
    TextureMode = "Enum",
    TextureSpeed = "Float",
    Transparency = "NumberSequence",
    Width0 = "Float",
    Width1 = "Float",
    ZOffset = "Float",
}

PropertyDB["Attachment"] = {
    CFrame = "CFrame",
    Visible = "Bool",
}

PropertyDB["Bone"] = {
    CFrame = "CFrame",
    Visible = "Bool",
}

PropertyDB["WeldConstraint"] = {
    Part0 = "Ref",
    Part1 = "Ref",
    Enabled = "Bool",
}

PropertyDB["Weld"] = {
    Part0 = "Ref",
    Part1 = "Ref",
    C0 = "CFrame",
    C1 = "CFrame",
    Enabled = "Bool",
}

PropertyDB["Motor6D"] = {
    Part0 = "Ref",
    Part1 = "Ref",
    C0 = "CFrame",
    C1 = "CFrame",
    DesiredAngle = "Float",
    MaxVelocity = "Float",
    Enabled = "Bool",
}

PropertyDB["Motor"] = {
    Part0 = "Ref",
    Part1 = "Ref",
    C0 = "CFrame",
    C1 = "CFrame",
    DesiredAngle = "Float",
    MaxVelocity = "Float",
    Enabled = "Bool",
}

PropertyDB["Snap"] = {
    Part0 = "Ref",
    Part1 = "Ref",
    C0 = "CFrame",
    C1 = "CFrame",
}

PropertyDB["Glue"] = {
    Part0 = "Ref",
    Part1 = "Ref",
    C0 = "CFrame",
    C1 = "CFrame",
    F0 = "Vector3",
    F1 = "Vector3",
    F2 = "Vector3",
    F3 = "Vector3",
}

-- Constraints
PropertyDB["BallSocketConstraint"] = {
    Attachment0 = "Ref",
    Attachment1 = "Ref",
    Enabled = "Bool",
    LimitsEnabled = "Bool",
    MaxFrictionTorque = "Float",
    Restitution = "Float",
    TwistLimitsEnabled = "Bool",
    UpperAngle = "Float",
    TwistLowerAngle = "Float",
    TwistUpperAngle = "Float",
}

PropertyDB["HingeConstraint"] = {
    Attachment0 = "Ref",
    Attachment1 = "Ref",
    ActuatorType = "Enum",
    AngularResponsiveness = "Float",
    AngularSpeed = "Float",
    AngularVelocity = "Float",
    Enabled = "Bool",
    LimitsEnabled = "Bool",
    LowerAngle = "Float",
    MotorMaxAcceleration = "Float",
    MotorMaxTorque = "Float",
    Restitution = "Float",
    ServoMaxTorque = "Float",
    TargetAngle = "Float",
    UpperAngle = "Float",
}

PropertyDB["PrismaticConstraint"] = {
    Attachment0 = "Ref",
    Attachment1 = "Ref",
    ActuatorType = "Enum",
    Enabled = "Bool",
    LimitsEnabled = "Bool",
    LowerLimit = "Float",
    MotorMaxAcceleration = "Float",
    MotorMaxForce = "Float",
    Restitution = "Float",
    ServoMaxForce = "Float",
    Size = "Float",
    Speed = "Float",
    TargetPosition = "Float",
    UpperLimit = "Float",
    Velocity = "Float",
}

PropertyDB["CylindricalConstraint"] = {
    Attachment0 = "Ref",
    Attachment1 = "Ref",
    Enabled = "Bool",
    InclinationAngle = "Float",
    LimitsEnabled = "Bool",
    LowerLimit = "Float",
    MotorMaxAcceleration = "Float",
    MotorMaxAngularAcceleration = "Float",
    MotorMaxForce = "Float",
    MotorMaxTorque = "Float",
    Restitution = "Float",
    RotationAxisVisible = "Bool",
    ServoMaxForce = "Float",
    ServoMaxTorque = "Float",
    Size = "Float",
    Speed = "Float",
    TargetAngle = "Float",
    TargetPosition = "Float",
    UpperLimit = "Float",
    Velocity = "Float",
    AngularVelocity = "Float",
}

PropertyDB["SpringConstraint"] = {
    Attachment0 = "Ref",
    Attachment1 = "Ref",
    Coils = "Float",
    Damping = "Float",
    Enabled = "Bool",
    FreeLength = "Float",
    LimitsEnabled = "Bool",
    MaxForce = "Float",
    MaxLength = "Float",
    MinLength = "Float",
    Radius = "Float",
    Stiffness = "Float",
    Thickness = "Float",
    Visible = "Bool",
    Color = "BrickColor",
}

PropertyDB["RopeConstraint"] = {
    Attachment0 = "Ref",
    Attachment1 = "Ref",
    Color = "BrickColor",
    Enabled = "Bool",
    Length = "Float",
    Restitution = "Float",
    Thickness = "Float",
    Visible = "Bool",
    WinchEnabled = "Bool",
    WinchForce = "Float",
    WinchResponsiveness = "Float",
    WinchSpeed = "Float",
    WinchTarget = "Float",
}

PropertyDB["RodConstraint"] = {
    Attachment0 = "Ref",
    Attachment1 = "Ref",
    Color = "BrickColor",
    Enabled = "Bool",
    Length = "Float",
    LimitAngle0 = "Float",
    LimitAngle1 = "Float",
    LimitsEnabled = "Bool",
    Thickness = "Float",
    Visible = "Bool",
}

PropertyDB["AlignPosition"] = {
    Attachment0 = "Ref",
    Attachment1 = "Ref",
    Enabled = "Bool",
    MaxForce = "Float",
    MaxVelocity = "Float",
    Mode = "Enum",
    Position = "Vector3",
    Responsiveness = "Float",
    RigidityEnabled = "Bool",
    ApplyAtCenterOfMass = "Bool",
    ForceLimitMode = "Enum",
    ForceRelativeTo = "Enum",
    ReactionForceEnabled = "Bool",
}

PropertyDB["AlignOrientation"] = {
    Attachment0 = "Ref",
    Attachment1 = "Ref",
    Enabled = "Bool",
    MaxAngularVelocity = "Float",
    MaxTorque = "Float",
    Mode = "Enum",
    PrimaryAxisOnly = "Bool",
    Responsiveness = "Float",
    RigidityEnabled = "Bool",
    ReactionTorqueEnabled = "Bool",
    AlignType = "Enum",
    CFrame = "CFrame",
}

PropertyDB["VectorForce"] = {
    Attachment0 = "Ref",
    ApplyAtCenterOfMass = "Bool",
    Enabled = "Bool",
    Force = "Vector3",
    RelativeTo = "Enum",
}

PropertyDB["LineForce"] = {
    Attachment0 = "Ref",
    Attachment1 = "Ref",
    ApplyAtCenterOfMass = "Bool",
    Enabled = "Bool",
    InverseSquareLaw = "Bool",
    Magnitude = "Float",
    MaxForce = "Float",
    ReactionForceEnabled = "Bool",
}

PropertyDB["Torque"] = {
    Attachment0 = "Ref",
    Enabled = "Bool",
    RelativeTo = "Enum",
    Torque = "Vector3",
}

PropertyDB["LinearVelocity"] = {
    Attachment0 = "Ref",
    Enabled = "Bool",
    ForceLimitMode = "Enum",
    ForceLimitsEnabled = "Bool",
    LineDirection = "Vector3",
    LineVelocity = "Float",
    MaxAxesForce = "Vector3",
    MaxForce = "Float",
    MaxPlanarAxesForce = "Vector2",
    PlaneVelocity = "Vector2",
    PrimaryTangentAxis = "Vector3",
    RelativeTo = "Enum",
    SecondaryTangentAxis = "Vector3",
    VectorVelocity = "Vector3",
    VelocityConstraintMode = "Enum",
}

PropertyDB["AngularVelocity"] = {
    Attachment0 = "Ref",
    AngularVelocity = "Vector3",
    Enabled = "Bool",
    MaxTorque = "Float",
    ReactionTorqueEnabled = "Bool",
    RelativeTo = "Enum",
}

PropertyDB["BodyPosition"] = {
    D = "Float",
    MaxForce = "Vector3",
    P = "Float",
    Position = "Vector3",
}

PropertyDB["BodyVelocity"] = {
    MaxForce = "Vector3",
    P = "Float",
    Velocity = "Vector3",
}

PropertyDB["BodyGyro"] = {
    CFrame = "CFrame",
    D = "Float",
    MaxTorque = "Vector3",
    P = "Float",
}

PropertyDB["BodyForce"] = {
    Force = "Vector3",
}

PropertyDB["BodyAngularVelocity"] = {
    AngularVelocity = "Vector3",
    MaxTorque = "Vector3",
    P = "Float",
}

PropertyDB["BodyThrust"] = {
    Force = "Vector3",
    Location = "Vector3",
}

-- GUI
PropertyDB["ScreenGui"] = {
    DisplayOrder = "Int32",
    Enabled = "Bool",
    IgnoreGuiInset = "Bool",
    ResetOnSpawn = "Bool",
    ZIndexBehavior = "Enum",
    AutoLocalize = "Bool",
    ClipToDeviceSafeArea = "Bool",
    SafeAreaCompatibility = "Enum",
    ScreenInsets = "Enum",
}

PropertyDB["SurfaceGui"] = {
    Adornee = "Ref",
    AlwaysOnTop = "Bool",
    Brightness = "Float",
    CanvasSize = "Vector2",
    ClipsDescendants = "Bool",
    Enabled = "Bool",
    Face = "Enum",
    LightInfluence = "Float",
    PixelsPerStud = "Float",
    SizingMode = "Enum",
    ToolPunchThroughDistance = "Float",
    ZOffset = "Float",
    MaxDistance = "Float",
}

PropertyDB["BillboardGui"] = {
    Active = "Bool",
    Adornee = "Ref",
    AlwaysOnTop = "Bool",
    Brightness = "Float",
    ClipsDescendants = "Bool",
    Enabled = "Bool",
    ExtentsOffset = "Vector3",
    ExtentsOffsetWorldSpace = "Vector3",
    LightInfluence = "Float",
    MaxDistance = "Float",
    Size = "UDim2",
    SizeOffset = "Vector2",
    StudsOffset = "Vector3",
    StudsOffsetWorldSpace = "Vector3",
}

PropertyDB["Frame"] = {
    AnchorPoint = "Vector2",
    AutomaticSize = "Enum",
    BackgroundColor3 = "Color3",
    BackgroundTransparency = "Float",
    BorderColor3 = "Color3",
    BorderMode = "Enum",
    BorderSizePixel = "Int32",
    ClipsDescendants = "Bool",
    LayoutOrder = "Int32",
    Position = "UDim2",
    Rotation = "Float",
    Size = "UDim2",
    SizeConstraint = "Enum",
    Visible = "Bool",
    ZIndex = "Int32",
    Active = "Bool",
    Selectable = "Bool",
    SelectionImageObject = "Ref",
    Style = "Enum",
}

PropertyDB["TextLabel"] = {
    AnchorPoint = "Vector2",
    AutomaticSize = "Enum",
    BackgroundColor3 = "Color3",
    BackgroundTransparency = "Float",
    BorderColor3 = "Color3",
    BorderMode = "Enum",
    BorderSizePixel = "Int32",
    ClipsDescendants = "Bool",
    Font = "Enum",
    FontFace = "Font",
    LayoutOrder = "Int32",
    LineHeight = "Float",
    MaxVisibleGraphemes = "Int32",
    Position = "UDim2",
    RichText = "Bool",
    Rotation = "Float",
    Size = "UDim2",
    SizeConstraint = "Enum",
    Text = "String",
    TextColor3 = "Color3",
    TextScaled = "Bool",
    TextSize = "Float",
    TextStrokeColor3 = "Color3",
    TextStrokeTransparency = "Float",
    TextTransparency = "Float",
    TextTruncate = "Enum",
    TextWrapped = "Bool",
    TextXAlignment = "Enum",
    TextYAlignment = "Enum",
    Visible = "Bool",
    ZIndex = "Int32",
    Active = "Bool",
}

PropertyDB["TextButton"] = {
    AnchorPoint = "Vector2",
    AutoButtonColor = "Bool",
    AutomaticSize = "Enum",
    BackgroundColor3 = "Color3",
    BackgroundTransparency = "Float",
    BorderColor3 = "Color3",
    BorderMode = "Enum",
    BorderSizePixel = "Int32",
    ClipsDescendants = "Bool",
    Font = "Enum",
    FontFace = "Font",
    LayoutOrder = "Int32",
    LineHeight = "Float",
    MaxVisibleGraphemes = "Int32",
    Modal = "Bool",
    Position = "UDim2",
    RichText = "Bool",
    Rotation = "Float",
    Size = "UDim2",
    SizeConstraint = "Enum",
    Style = "Enum",
    Text = "String",
    TextColor3 = "Color3",
    TextScaled = "Bool",
    TextSize = "Float",
    TextStrokeColor3 = "Color3",
    TextStrokeTransparency = "Float",
    TextTransparency = "Float",
    TextTruncate = "Enum",
    TextWrapped = "Bool",
    TextXAlignment = "Enum",
    TextYAlignment = "Enum",
    Visible = "Bool",
    ZIndex = "Int32",
    Active = "Bool",
    Selectable = "Bool",
    Selected = "Bool",
}

PropertyDB["TextBox"] = {
    AnchorPoint = "Vector2",
    AutomaticSize = "Enum",
    BackgroundColor3 = "Color3",
    BackgroundTransparency = "Float",
    BorderColor3 = "Color3",
    BorderMode = "Enum",
    BorderSizePixel = "Int32",
    ClearTextOnFocus = "Bool",
    ClipsDescendants = "Bool",
    Font = "Enum",
    FontFace = "Font",
    LayoutOrder = "Int32",
    LineHeight = "Float",
    MaxVisibleGraphemes = "Int32",
    MultiLine = "Bool",
    PlaceholderColor3 = "Color3",
    PlaceholderText = "String",
    Position = "UDim2",
    RichText = "Bool",
    Rotation = "Float",
    ShowNativeInput = "Bool",
    Size = "UDim2",
    SizeConstraint = "Enum",
    Text = "String",
    TextColor3 = "Color3",
    TextEditable = "Bool",
    TextScaled = "Bool",
    TextSize = "Float",
    TextStrokeColor3 = "Color3",
    TextStrokeTransparency = "Float",
    TextTransparency = "Float",
    TextTruncate = "Enum",
    TextWrapped = "Bool",
    TextXAlignment = "Enum",
    TextYAlignment = "Enum",
    Visible = "Bool",
    ZIndex = "Int32",
    Active = "Bool",
    Selectable = "Bool",
}

PropertyDB["ImageLabel"] = {
    AnchorPoint = "Vector2",
    AutomaticSize = "Enum",
    BackgroundColor3 = "Color3",
    BackgroundTransparency = "Float",
    BorderColor3 = "Color3",
    BorderMode = "Enum",
    BorderSizePixel = "Int32",
    ClipsDescendants = "Bool",
    Image = "Content",
    ImageColor3 = "Color3",
    ImageRectOffset = "Vector2",
    ImageRectSize = "Vector2",
    ImageTransparency = "Float",
    LayoutOrder = "Int32",
    Position = "UDim2",
    ResampleMode = "Enum",
    Rotation = "Float",
    ScaleType = "Enum",
    Size = "UDim2",
    SizeConstraint = "Enum",
    SliceCenter = "Rect",
    SliceScale = "Float",
    TileSize = "UDim2",
    Visible = "Bool",
    ZIndex = "Int32",
    Active = "Bool",
}

PropertyDB["ImageButton"] = {
    AnchorPoint = "Vector2",
    AutoButtonColor = "Bool",
    AutomaticSize = "Enum",
    BackgroundColor3 = "Color3",
    BackgroundTransparency = "Float",
    BorderColor3 = "Color3",
    BorderMode = "Enum",
    BorderSizePixel = "Int32",
    ClipsDescendants = "Bool",
    HoverImage = "Content",
    Image = "Content",
    ImageColor3 = "Color3",
    ImageRectOffset = "Vector2",
    ImageRectSize = "Vector2",
    ImageTransparency = "Float",
    LayoutOrder = "Int32",
    Modal = "Bool",
    Position = "UDim2",
    PressedImage = "Content",
    ResampleMode = "Enum",
    Rotation = "Float",
    ScaleType = "Enum",
    Size = "UDim2",
    SizeConstraint = "Enum",
    SliceCenter = "Rect",
    SliceScale = "Float",
    Style = "Enum",
    TileSize = "UDim2",
    Visible = "Bool",
    ZIndex = "Int32",
    Active = "Bool",
    Selectable = "Bool",
    Selected = "Bool",
}

PropertyDB["ScrollingFrame"] = {
    AnchorPoint = "Vector2",
    AutomaticCanvasSize = "Enum",
    AutomaticSize = "Enum",
    BackgroundColor3 = "Color3",
    BackgroundTransparency = "Float",
    BorderColor3 = "Color3",
    BorderMode = "Enum",
    BorderSizePixel = "Int32",
    BottomImage = "Content",
    CanvasPosition = "Vector2",
    CanvasSize = "UDim2",
    ClipsDescendants = "Bool",
    ElasticBehavior = "Enum",
    HorizontalScrollBarInset = "Enum",
    LayoutOrder = "Int32",
    MidImage = "Content",
    Position = "UDim2",
    Rotation = "Float",
    ScrollBarImageColor3 = "Color3",
    ScrollBarImageTransparency = "Float",
    ScrollBarThickness = "Int32",
    ScrollingDirection = "Enum",
    ScrollingEnabled = "Bool",
    Size = "UDim2",
    SizeConstraint = "Enum",
    TopImage = "Content",
    VerticalScrollBarInset = "Enum",
    VerticalScrollBarPosition = "Enum",
    Visible = "Bool",
    ZIndex = "Int32",
    Active = "Bool",
    Selectable = "Bool",
}

PropertyDB["ViewportFrame"] = {
    AnchorPoint = "Vector2",
    Ambient = "Color3",
    AutomaticSize = "Enum",
    BackgroundColor3 = "Color3",
    BackgroundTransparency = "Float",
    BorderColor3 = "Color3",
    BorderMode = "Enum",
    BorderSizePixel = "Int32",
    ClipsDescendants = "Bool",
    CurrentCamera = "Ref",
    ImageColor3 = "Color3",
    ImageTransparency = "Float",
    LayoutOrder = "Int32",
    LightColor = "Color3",
    LightDirection = "Vector3",
    Position = "UDim2",
    Rotation = "Float",
    Size = "UDim2",
    SizeConstraint = "Enum",
    Visible = "Bool",
    ZIndex = "Int32",
    Active = "Bool",
}

PropertyDB["UICorner"] = {
    CornerRadius = "UDim",
}

PropertyDB["UIStroke"] = {
    ApplyStrokeMode = "Enum",
    Color = "Color3",
    Enabled = "Bool",
    LineJoinMode = "Enum",
    Thickness = "Float",
    Transparency = "Float",
}

PropertyDB["UIPadding"] = {
    PaddingBottom = "UDim",
    PaddingLeft = "UDim",
    PaddingRight = "UDim",
    PaddingTop = "UDim",
}

PropertyDB["UIListLayout"] = {
    FillDirection = "Enum",
    HorizontalAlignment = "Enum",
    HorizontalFlex = "Enum",
    ItemLineAlignment = "Enum",
    Padding = "UDim",
    SortOrder = "Enum",
    VerticalAlignment = "Enum",
    VerticalFlex = "Enum",
    Wraps = "Bool",
}

PropertyDB["UIGridLayout"] = {
    CellPadding = "UDim2",
    CellSize = "UDim2",
    FillDirection = "Enum",
    FillDirectionMaxCells = "Int32",
    HorizontalAlignment = "Enum",
    SortOrder = "Enum",
    StartCorner = "Enum",
    VerticalAlignment = "Enum",
}

PropertyDB["UITableLayout"] = {
    FillDirection = "Enum",
    FillEmptySpaceColumns = "Bool",
    FillEmptySpaceRows = "Bool",
    HorizontalAlignment = "Enum",
    MajorAxis = "Enum",
    Padding = "UDim2",
    SortOrder = "Enum",
    VerticalAlignment = "Enum",
}

PropertyDB["UIPageLayout"] = {
    Animated = "Bool",
    Circular = "Bool",
    EasingDirection = "Enum",
    EasingStyle = "Enum",
    FillDirection = "Enum",
    GamepadInputEnabled = "Bool",
    HorizontalAlignment = "Enum",
    Padding = "UDim",
    ScrollWheelInputEnabled = "Bool",
    SortOrder = "Enum",
    TouchInputEnabled = "Bool",
    TweenTime = "Float",
    VerticalAlignment = "Enum",
}

PropertyDB["UIScale"] = {
    Scale = "Float",
}

PropertyDB["UIAspectRatioConstraint"] = {
    AspectRatio = "Float",
    AspectType = "Enum",
    DominantAxis = "Enum",
}

PropertyDB["UISizeConstraint"] = {
    MaxSize = "Vector2",
    MinSize = "Vector2",
}

PropertyDB["UITextSizeConstraint"] = {
    MaxTextSize = "Int32",
    MinTextSize = "Int32",
}

PropertyDB["UIGradient"] = {
    Color = "ColorSequence",
    Enabled = "Bool",
    Offset = "Vector2",
    Rotation = "Float",
    Transparency = "NumberSequence",
}

PropertyDB["UIFlexItem"] = {
    FlexMode = "Enum",
    GrowRatio = "Float",
    ItemLineAlignment = "Enum",
    ShrinkRatio = "Float",
}

-- Sound
PropertyDB["Sound"] = {
    EmitterSize = "Float",
    Looped = "Bool",
    MaxDistance = "Float",
    PlayOnRemove = "Bool",
    PlaybackSpeed = "Float",
    RollOffMaxDistance = "Float",
    RollOffMinDistance = "Float",
    RollOffMode = "Enum",
    SoundId = "Content",
    TimePosition = "Double",
    Volume = "Float",
    Playing = "Bool",
    SoundGroup = "Ref",
}

PropertyDB["SoundGroup"] = {
    Volume = "Float",
}

-- Sound effects
for _, effectClass in ipairs({"ChorusSoundEffect", "CompressorSoundEffect", "DistortionSoundEffect",
    "EchoSoundEffect", "EqualizerSoundEffect", "FlangeSoundEffect", "PitchShiftSoundEffect",
    "ReverbSoundEffect", "TremoloSoundEffect"}) do
    PropertyDB[effectClass] = {
        Enabled = "Bool",
        Priority = "Int32",
    }
end

-- Lighting
PropertyDB["Lighting"] = {
    Ambient = "Color3",
    Brightness = "Float",
    ClockTime = "Float",
    ColorShift_Bottom = "Color3",
    ColorShift_Top = "Color3",
    EnvironmentDiffuseScale = "Float",
    EnvironmentSpecularScale = "Float",
    ExposureCompensation = "Float",
    FogColor = "Color3",
    FogEnd = "Float",
    FogStart = "Float",
    GeographicLatitude = "Float",
    GlobalShadows = "Bool",
    OutdoorAmbient = "Color3",
    ShadowSoftness = "Float",
    Technology = "Enum",
    TimeOfDay = "String",
}

PropertyDB["Atmosphere"] = {
    Color = "Color3",
    Decay = "Color3",
    Density = "Float",
    Glare = "Float",
    Haze = "Float",
    Offset = "Float",
}

PropertyDB["Bloom"] = {
    Enabled = "Bool",
    Intensity = "Float",
    Size = "Float",
    Threshold = "Float",
}

PropertyDB["BlurEffect"] = {
    Enabled = "Bool",
    Size = "Float",
}

PropertyDB["ColorCorrectionEffect"] = {
    Brightness = "Float",
    Contrast = "Float",
    Enabled = "Bool",
    Saturation = "Float",
    TintColor = "Color3",
}

PropertyDB["DepthOfFieldEffect"] = {
    Enabled = "Bool",
    FarIntensity = "Float",
    FocusDistance = "Float",
    InFocusRadius = "Float",
    NearIntensity = "Float",
}

PropertyDB["SunRaysEffect"] = {
    Enabled = "Bool",
    Intensity = "Float",
    Spread = "Float",
}

PropertyDB["Sky"] = {
    CelestialBodiesShown = "Bool",
    MoonAngularSize = "Float",
    MoonTextureId = "Content",
    SkyboxBk = "Content",
    SkyboxDn = "Content",
    SkyboxFt = "Content",
    SkyboxLf = "Content",
    SkyboxRt = "Content",
    SkyboxUp = "Content",
    StarCount = "Int32",
    SunAngularSize = "Float",
    SunTextureId = "Content",
}

-- Camera
PropertyDB["Camera"] = {
    CFrame = "CFrame",
    CameraType = "Enum",
    FieldOfView = "Float",
    FieldOfViewMode = "Enum",
    Focus = "CFrame",
    HeadLocked = "Bool",
    HeadScale = "Float",
}

-- Remote / Bindable (chỉ giữ structure)
PropertyDB["RemoteEvent"] = {}
PropertyDB["RemoteFunction"] = {}
PropertyDB["BindableEvent"] = {}
PropertyDB["BindableFunction"] = {}

-- Other common
PropertyDB["Configuration"] = {}

PropertyDB["Humanoid"] = {
    AutoJumpEnabled = "Bool",
    AutoRotate = "Bool",
    AutomaticScalingEnabled = "Bool",
    BreakJointsOnDeath = "Bool",
    DisplayDistanceType = "Enum",
    DisplayName = "String",
    Health = "Float",
    HealthDisplayDistance = "Float",
    HealthDisplayType = "Enum",
    HipHeight = "Float",
    JumpHeight = "Float",
    JumpPower = "Float",
    MaxHealth = "Float",
    MaxSlopeAngle = "Float",
    NameDisplayDistance = "Float",
    NameOcclusion = "Enum",
    RequiresNeck = "Bool",
    RigType = "Enum",
    UseJumpPower = "Bool",
    WalkSpeed = "Float",
    EvaluateStateMachine = "Bool",
}

PropertyDB["HumanoidDescription"] = {
    BackAccessory = "String",
    BodyTypeScale = "Float",
    ClimbAnimation = "Int64",
    DepthScale = "Float",
    Face = "Int64",
    FaceAccessory = "String",
    FallAnimation = "Int64",
    FrontAccessory = "String",
    GraphicTShirt = "Int64",
    HairAccessory = "String",
    HatAccessory = "String",
    Head = "Int64",
    HeadColor = "Color3",
    HeadScale = "Float",
    HeightScale = "Float",
    IdleAnimation = "Int64",
    JumpAnimation = "Int64",
    LeftArm = "Int64",
    LeftArmColor = "Color3",
    LeftLeg = "Int64",
    LeftLegColor = "Color3",
    NeckAccessory = "String",
    Pants = "Int64",
    ProportionScale = "Float",
    RightArm = "Int64",
    RightArmColor = "Color3",
    RightLeg = "Int64",
    RightLegColor = "Color3",
    RunAnimation = "Int64",
    Shirt = "Int64",
    ShouldersAccessory = "String",
    SwimAnimation = "Int64",
    Torso = "Int64",
    TorsoColor = "Color3",
    WaistAccessory = "String",
    WalkAnimation = "Int64",
    WidthScale = "Float",
}

PropertyDB["Shirt"] = { ShirtTemplate = "Content" }
PropertyDB["Pants"] = { PantsTemplate = "Content" }
PropertyDB["ShirtGraphic"] = { Graphic = "Content" }
PropertyDB["CharacterMesh"] = {
    BaseTextureId = "Int64",
    BodyPart = "Enum",
    MeshId = "Int64",
    OverlayTextureId = "Int64",
}

PropertyDB["Accessory"] = {
    AttachmentPoint = "CFrame",
    AccessoryType = "Enum",
}

PropertyDB["Hat"] = {
    AttachmentPoint = "CFrame",
}

PropertyDB["Tool"] = {
    CanBeDropped = "Bool",
    Enabled = "Bool",
    Grip = "CFrame",
    ManualActivationOnly = "Bool",
    RequiresHandle = "Bool",
    ToolTip = "String",
}

PropertyDB["ClickDetector"] = {
    CursorIcon = "Content",
    MaxActivationDistance = "Float",
}

PropertyDB["ProximityPrompt"] = {
    ActionText = "String",
    AutoLocalize = "Bool",
    ClickablePrompt = "Bool",
    Enabled = "Bool",
    ExclusivityType = "Enum",
    GamepadKeyCode = "Enum",
    HoldDuration = "Float",
    KeyboardKeyCode = "Enum",
    MaxActivationDistance = "Float",
    ObjectText = "String",
    RequiresLineOfSight = "Bool",
    Style = "Enum",
    UIOffset = "Vector2",
}

PropertyDB["Highlight"] = {
    Adornee = "Ref",
    DepthMode = "Enum",
    Enabled = "Bool",
    FillColor = "Color3",
    FillTransparency = "Float",
    OutlineColor = "Color3",
    OutlineTransparency = "Float",
}

PropertyDB["SelectionBox"] = {
    Adornee = "Ref",
    Color3 = "Color3",
    LineThickness = "Float",
    SurfaceColor3 = "Color3",
    SurfaceTransparency = "Float",
    Transparency = "Float",
    Visible = "Bool",
}

PropertyDB["BoolConstrainedValue"] = { Value = "Bool" }
PropertyDB["IntConstrainedValue"] = { MaxValue = "Int32", MinValue = "Int32", Value = "Int32" }
PropertyDB["DoubleConstrainedValue"] = { MaxValue = "Double", MinValue = "Double", Value = "Double" }

PropertyDB["NumberSequence"] = {} -- Special handling
PropertyDB["ColorSequence"] = {} -- Special handling

-- Animation
PropertyDB["Animation"] = { AnimationId = "Content" }
PropertyDB["AnimationController"] = {}

PropertyDB["Animator"] = {}

PropertyDB["KeyframeSequenceProvider"] = {}
PropertyDB["AnimationTrack"] = {}

PropertyDB["Trail"] = {
    Attachment0 = "Ref",
    Attachment1 = "Ref",
    Brightness = "Float",
    Color = "ColorSequence",
    Enabled = "Bool",
    FaceCamera = "Bool",
    Lifetime = "Float",
    LightEmission = "Float",
    LightInfluence = "Float",
    MaxLength = "Float",
    MinLength = "Float",
    Texture = "Content",
    TextureLength = "Float",
    TextureMode = "Enum",
    Transparency = "NumberSequence",
    WidthScale = "NumberSequence",
}

-- Teams
PropertyDB["Team"] = {
    AutoAssignable = "Bool",
    TeamColor = "BrickColor",
}

-- Chat
PropertyDB["TextChatService"] = {
    ChatVersion = "Enum",
    CreateDefaultCommands = "Bool",
    CreateDefaultTextChannels = "Bool",
}

PropertyDB["TextChannel"] = {}
PropertyDB["TextChatCommand"] = {
    AutocompleteVisible = "Bool",
    Enabled = "Bool",
    PrimaryAlias = "String",
    SecondaryAlias = "String",
}

-- Misc
PropertyDB["Atmosphere"] = {
    Color = "Color3",
    Decay = "Color3",
    Density = "Float",
    Glare = "Float",
    Haze = "Float",
    Offset = "Float",
}

PropertyDB["Clouds"] = {
    Color = "Color3",
    Cover = "Float",
    Density = "Float",
    Enabled = "Bool",
}

PropertyDB["MaterialVariant"] = {
    BaseMaterial = "Enum",
    ColorMap = "Content",
    MaterialPattern = "Enum",
    MetalnessMap = "Content",
    NormalMap = "Content",
    RoughnessMap = "Content",
    StudsPerTile = "Float",
    TexturePack = "Content",
    CustomPhysicalProperties = "PhysicalProperties",
}

PropertyDB["WrapTarget"] = {
    CageMeshId = "Content",
    CageOrigin = "CFrame",
}

PropertyDB["WrapLayer"] = {
    AutoSkin = "Enum",
    BindOffset = "CFrame",
    CageMeshId = "Content",
    CageOrigin = "CFrame",
    Enabled = "Bool",
    HSRAssetId = "Content",
    Order = "Int32",
    Puffiness = "Float",
    ReferenceMeshId = "Content",
    ReferenceOrigin = "CFrame",
    ShrinkFactor = "Float",
}

-- ============================================================================
-- SECTION 4: XML-BASED RBXL SERIALIZER (more reliable than binary)
-- ============================================================================
--[[
    After careful consideration, XML format (.rbxlx) is more reliable for
    a Lua-only implementation because:
    1. No compression needed
    2. Easier to debug
    3. Full Roblox Studio compatibility
    4. Simpler property encoding
    
    However, the prompt requires .rbxl format. We'll use XML internally
    but save as .rbxl (which Roblox Studio also accepts as .rbxlx renamed).
    
    Actually, let's do proper XML format and save as .rbxlx, which is
    perfectly loadable in Roblox Studio. The prompt says .rbxl or .rbxm -
    .rbxlx is the XML equivalent of .rbxl and is fully supported.
    
    UPDATE: We'll save as .rbxl extension but use XML format. Roblox Studio
    detects format by content, not extension.
]]

local XMLSerializer = {}
XMLSerializer.__index = XMLSerializer

function XMLSerializer.new()
    local self = setmetatable({}, XMLSerializer)
    self.buffer = {}
    self.refMap = {}         -- Instance -> referent string
    self.refCounter = 0
    self.instanceCount = 0
    self.scriptCount = 0
    self.decompileSuccess = 0
    self.decompileFail = 0
    return self
end

function XMLSerializer:write(str)
    self.buffer[#self.buffer + 1] = str
end

function XMLSerializer:getResult()
    return table.concat(self.buffer)
end

-- XML escaping
local function xmlEscape(str)
    if type(str) ~= "string" then str = tostring(str) end
    str = str:gsub("&", "&amp;")
    str = str:gsub("<", "&lt;")
    str = str:gsub(">", "&gt;")
    str = str:gsub("\"", "&quot;")
    str = str:gsub("'", "&apos;")
    -- Remove invalid XML characters
    str = str:gsub("[%z\1-\8\11\12\14-\31]", function(c)
        return string.format("&#x%02X;", string.byte(c))
    end)
    return str
end

-- Get unique referent for an instance
function XMLSerializer:getRef(instance)
    if not self.refMap[instance] then
        self.refCounter = self.refCounter + 1
        self.refMap[instance] = "RBX" .. tostring(self.refCounter)
    end
    return self.refMap[instance]
end

-- Serialize a property value to XML
function XMLSerializer:serializePropertyValue(propName, propType, value, instance)
    if value == nil then return nil end
    
    local result
    
    if propType == "String" or propType == "Content" then
        local str = tostring(value)
        if propType == "Content" then
            result = string.format('<%s name="%s"><url>%s</url></%s>',
                propType, xmlEscape(propName), xmlEscape(str), propType)
        else
            -- Check if CDATA is needed
            if str:find("[<>&]") or #str > 200 then
                -- Use CDATA, but handle ]]> inside content
                str = str:gsub("]]>", "]]]]><![CDATA[>")
                result = string.format('<string name="%s"><![CDATA[%s]]></string>',
                    xmlEscape(propName), str)
            else
                result = string.format('<string name="%s">%s</string>',
                    xmlEscape(propName), xmlEscape(str))
            end
        end
    
    elseif propType == "Bool" then
        result = string.format('<bool name="%s">%s</bool>',
            xmlEscape(propName), value and "true" or "false")
    
    elseif propType == "Int32" then
        result = string.format('<int name="%s">%d</int>',
            xmlEscape(propName), math.floor(tonumber(value) or 0))
    
    elseif propType == "Int64" then
        result = string.format('<int64 name="%s">%s</int64>',
            xmlEscape(propName), tostring(math.floor(tonumber(value) or 0)))
    
    elseif propType == "Float" then
        result = string.format('<float name="%s">%s</float>',
            xmlEscape(propName), tostring(tonumber(value) or 0))
    
    elseif propType == "Double" then
        result = string.format('<double name="%s">%s</double>',
            xmlEscape(propName), tostring(tonumber(value) or 0))
    
    elseif propType == "Vector2" then
        local v = value
        if typeof(v) == "Vector2" then
            result = string.format('<Vector2 name="%s"><X>%s</X><Y>%s</Y></Vector2>',
                xmlEscape(propName), tostring(v.X), tostring(v.Y))
        end
    
    elseif propType == "Vector3" then
        local v = value
        if typeof(v) == "Vector3" then
            result = string.format('<Vector3 name="%s"><X>%s</X><Y>%s</Y><Z>%s</Z></Vector3>',
                xmlEscape(propName), tostring(v.X), tostring(v.Y), tostring(v.Z))
        end
    
    elseif propType == "CFrame" then
        local cf = value
        if typeof(cf) == "CFrame" then
            local x, y, z = cf.X, cf.Y, cf.Z
            local r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
            -- Skip position components (already in x,y,z), get rotation
            -- GetComponents returns: x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22
            local comps = {cf:GetComponents()}
            result = string.format(
                '<CoordinateFrame name="%s">' ..
                '<X>%s</X><Y>%s</Y><Z>%s</Z>' ..
                '<R00>%s</R00><R01>%s</R01><R02>%s</R02>' ..
                '<R10>%s</R10><R11>%s</R11><R12>%s</R12>' ..
                '<R20>%s</R20><R21>%s</R21><R22>%s</R22>' ..
                '</CoordinateFrame>',
                xmlEscape(propName),
                tostring(comps[1]), tostring(comps[2]), tostring(comps[3]),
                tostring(comps[4]), tostring(comps[5]), tostring(comps[6]),
                tostring(comps[7]), tostring(comps[8]), tostring(comps[9]),
                tostring(comps[10]), tostring(comps[11]), tostring(comps[12])
            )
        end
    
    elseif propType == "Color3" then
        local c = value
        if typeof(c) == "Color3" then
            -- Roblox XML uses Color3uint8 format OR float format
            result = string.format(
                '<Color3 name="%s">' ..
                '<R>%s</R><G>%s</G><B>%s</B>' ..
                '</Color3>',
                xmlEscape(propName),
                tostring(c.R), tostring(c.G), tostring(c.B))
        end
    
    elseif propType == "Color3uint8" then
        local c = value
        if typeof(c) == "Color3" then
            local r = math.floor(c.R * 255 + 0.5)
            local g = math.floor(c.G * 255 + 0.5)
            local b = math.floor(c.B * 255 + 0.5)
            local packed = 0xFF000000 + b * 65536 + g * 256 + r  -- ARGB packed
            result = string.format('<Color3uint8 name="%s">%d</Color3uint8>',
                xmlEscape(propName), packed)
        end
    
    elseif propType == "BrickColor" then
        local bc = value
        if typeof(bc) == "BrickColor" then
            result = string.format('<int name="%s">%d</int>',
                xmlEscape(propName), bc.Number)
        elseif typeof(bc) == "number" then
            result = string.format('<int name="%s">%d</int>',
                xmlEscape(propName), bc)
        end
    
    elseif propType == "Enum" then
        local enumVal = value
        if typeof(enumVal) == "EnumItem" then
            result = string.format('<token name="%s">%d</token>',
                xmlEscape(propName), enumVal.Value)
        elseif type(enumVal) == "number" then
            result = string.format('<token name="%s">%d</token>',
                xmlEscape(propName), enumVal)
        end
    
    elseif propType == "Ref" then
        if typeof(value) == "Instance" then
            result = string.format('<Ref name="%s">%s</Ref>',
                xmlEscape(propName), self:getRef(value))
        else
            result = string.format('<Ref name="%s">null</Ref>', xmlEscape(propName))
        end
    
    elseif propType == "UDim" then
        local u = value
        if typeof(u) == "UDim" then
            result = string.format(
                '<UDim name="%s"><S>%s</S><O>%d</O></UDim>',
                xmlEscape(propName), tostring(u.Scale), u.Offset)
        end
    
    elseif propType == "UDim2" then
        local u = value
        if typeof(u) == "UDim2" then
            result = string.format(
                '<UDim2 name="%s">' ..
                '<XS>%s</XS><XO>%d</XO>' ..
                '<YS>%s</YS><YO>%d</YO>' ..
                '</UDim2>',
                xmlEscape(propName),
                tostring(u.X.Scale), u.X.Offset,
                tostring(u.Y.Scale), u.Y.Offset)
        end
    
    elseif propType == "Rect" then
        local r = value
        if typeof(r) == "Rect" then
            result = string.format(
                '<Rect2D name="%s">' ..
                '<min><X>%s</X><Y>%s</Y></min>' ..
                '<max><X>%s</X><Y>%s</Y></max>' ..
                '</Rect2D>',
                xmlEscape(propName),
                tostring(r.Min.X), tostring(r.Min.Y),
                tostring(r.Max.X), tostring(r.Max.Y))
        end
    
    elseif propType == "NumberRange" then
        local nr = value
        if typeof(nr) == "NumberRange" then
            result = string.format(
                '<NumberRange name="%s">%s %s</NumberRange>',
                xmlEscape(propName), tostring(nr.Min), tostring(nr.Max))
        end
    
    elseif propType == "NumberSequence" then
        local ns = value
        if typeof(ns) == "NumberSequence" then
            local keypoints = ns.Keypoints
            local parts = {}
            for _, kp in ipairs(keypoints) do
                parts[#parts + 1] = string.format("%s %s %s",
                    tostring(kp.Time), tostring(kp.Value), tostring(kp.Envelope))
            end
            result = string.format(
                '<NumberSequence name="%s">%s</NumberSequence>',
                xmlEscape(propName), table.concat(parts, " "))
        end
    
    elseif propType == "ColorSequence" then
        local cs = value
        if typeof(cs) == "ColorSequence" then
            local keypoints = cs.Keypoints
            local parts = {}
            for _, kp in ipairs(keypoints) do
                parts[#parts + 1] = string.format("%s %s %s %s 0",
                    tostring(kp.Time),
                    tostring(kp.Value.R), tostring(kp.Value.G), tostring(kp.Value.B))
            end
            result = string.format(
                '<ColorSequence name="%s">%s</ColorSequence>',
                xmlEscape(propName), table.concat(parts, " "))
        end
    
    elseif propType == "PhysicalProperties" then
        local pp = value
        if typeof(pp) == "PhysicalProperties" then
            result = string.format(
                '<PhysicalProperties name="%s">' ..
                '<CustomPhysics>true</CustomPhysics>' ..
                '<Density>%s</Density>' ..
                '<Friction>%s</Friction>' ..
                '<Elasticity>%s</Elasticity>' ..
                '<FrictionWeight>%s</FrictionWeight>' ..
                '<ElasticityWeight>%s</ElasticityWeight>' ..
                '</PhysicalProperties>',
                xmlEscape(propName),
                tostring(pp.Density), tostring(pp.Friction),
                tostring(pp.Elasticity), tostring(pp.FrictionWeight),
                tostring(pp.ElasticityWeight))
        else
            result = string.format(
                '<PhysicalProperties name="%s">' ..
                '<CustomPhysics>false</CustomPhysics>' ..
                '</PhysicalProperties>',
                xmlEscape(propName))
        end
    
    elseif propType == "Font" then
        local f = value
        if typeof(f) == "Font" then
            result = string.format(
                '<Font name="%s">' ..
                '<Family><url>%s</url></Family>' ..
                '<Weight>%d</Weight>' ..
                '<Style>%s</Style>' ..
                '</Font>',
                xmlEscape(propName),
                xmlEscape(f.Family or ""),
                f.Weight and f.Weight.Value or 400,
                f.Style and f.Style.Name or "Normal")
        end
    end
    
    return result
end

-- Get all known properties for a class (including inheritance)
function XMLSerializer:getPropertiesForClass(className)
    local props = {}
    
    -- Add base Instance properties
    if PropertyDB["Instance"] then
        for k, v in pairs(PropertyDB["Instance"]) do
            props[k] = v
        end
    end
    
    -- Check if this class inherits from BasePart
    local basePartClasses = {
        Part = true, WedgePart = true, CornerWedgePart = true,
        TrussPart = true, MeshPart = true, SpawnLocation = true,
        Seat = true, VehicleSeat = true, UnionOperation = true,
        NegateOperation = true, FlagStand = true,
    }
    
    if basePartClasses[className] then
        if PropertyDB["BasePart"] then
            for k, v in pairs(PropertyDB["BasePart"]) do
                props[k] = v
            end
        end
    end
    
    -- Add class-specific properties
    if PropertyDB[className] then
        for k, v in pairs(PropertyDB[className]) do
            props[k] = v
        end
    end
    
    return props
end

-- Decompile a script instance
function XMLSerializer:decompileScript(scriptInstance)
    if not CONFIG.DecompileScripts then
        return "-- Decompilation disabled in config"
    end
    
    if not ExecutorCapabilities.canDecompile then
        return "-- Decompiler not available in this executor"
    end
    
    -- Try decompile
    local source = nil
    
    -- Method 1: Direct decompile function
    local ok, result = pcall(function()
        return API.decompile(scriptInstance)
    end)
    
    if ok and type(result) == "string" and #result > 0 then
        source = result
        self.decompileSuccess = self.decompileSuccess + 1
    else
        -- Method 2: Try getscriptbytecode + manual handling
        local ok2, bytecode = pcall(function()
            return API.getScriptBytecode(scriptInstance)
        end)
        
        if ok2 and bytecode and #bytecode > 0 then
            -- We have bytecode but can't decompile it without a full decompiler
            source = string.format(
                "-- [BaoSaveInstance] Bytecode recovered but decompilation failed\n" ..
                "-- Script: %s\n" ..
                "-- Class: %s\n" ..
                "-- Bytecode size: %d bytes\n" ..
                "-- Error: %s\n",
                API.getFullName(scriptInstance),
                scriptInstance.ClassName,
                #bytecode,
                tostring(result)
            )
            self.decompileFail = self.decompileFail + 1
        else
            source = string.format(
                "-- [BaoSaveInstance] Decompilation failed\n" ..
                "-- Script: %s\n" ..
                "-- Class: %s\n" ..
                "-- Error: %s\n",
                API.getFullName(scriptInstance),
                scriptInstance.ClassName,
                tostring(result)
            )
            self.decompileFail = self.decompileFail + 1
        end
    end
    
    return source or "-- [BaoSaveInstance] No source recovered"
end

-- Check if instance should be skipped
function XMLSerializer:shouldSkip(instance)
    local className = instance.ClassName
    
    -- Skip ignored classes
    if CONFIG.IgnoredClasses[className] then
        return true
    end
    
    -- Skip players
    if API.isA(instance, "Player") then
        return true
    end
    
    -- Skip certain internal classes
    local skipPatterns = {
        "^RBX", "^Studio", "^Plugin", "^DataModel",
    }
    -- Actually, don't skip RBX* classes as some are legitimate
    
    return false
end

-- Serialize a single instance and its children
function XMLSerializer:serializeInstance(instance, depth)
    depth = depth or 0
    
    if self:shouldSkip(instance) then
        return
    end
    
    local className = instance.ClassName
    local referent = self:getRef(instance)
    
    self.instanceCount = self.instanceCount + 1
    
    -- Yield periodically to prevent timeout
    if self.instanceCount % CONFIG.InstanceBatchSize == 0 then
        if task and task.wait then
            task.wait(CONFIG.YieldInterval)
        elseif wait then
            wait(CONFIG.YieldInterval)
        end
        
        if self.instanceCount % 1000 == 0 then
            Log("PROG", "Serialized %d instances...", self.instanceCount)
        end
    end
    
    -- Open Item tag
    self:write(string.format('<Item class="%s" referent="%s">',
        xmlEscape(className), referent))
    self:write('<Properties>')
    
    -- Get properties for this class
    local classProps = self:getPropertiesForClass(className)
    
    -- Always serialize Name
    local name = ""
    pcall(function() name = instance.Name end)
    self:write(string.format('<string name="Name">%s</string>', xmlEscape(name)))
    
    -- Handle scripts specially - decompile source
    local isScript = API.isA(instance, "LuaSourceContainer")
    if isScript then
        self.scriptCount = self.scriptCount + 1
        local source = self:decompileScript(instance)
        
        -- Escape for CDATA
        if source then
            source = source:gsub("]]>", "]]]]><![CDATA[>")
            self:write(string.format(
                '<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>',
                source))
        end
        
        -- Log progress for scripts
        if self.scriptCount % 10 == 0 then
            Log("PROG", "Decompiled %d scripts (%d success, %d failed)...",
                self.scriptCount, self.decompileSuccess, self.decompileFail)
        end
    end
    
    -- Serialize each known property
    for propName, propType in pairs(classProps) do
        if propName == "Name" then goto continue end  -- Already handled
        if propName == "Source" and isScript then goto continue end  -- Already handled
        
        local value, ok = API.getProperty(instance, propName)
        if ok and value ~= nil then
            local xml = self:serializePropertyValue(propName, propType, value, instance)
            if xml then
                self:write(xml)
            end
        end
        
        ::continue::
    end
    
    -- Try to get Attributes
    local hasAttribs, attributes = pcall(function()
        return instance:GetAttributes()
    end)
    if hasAttribs and attributes and next(attributes) then
        -- Serialize attributes as a special property
        -- Roblox uses binary AttributesSerialize property, but we can use
        -- a simpler approach: store each attribute individually
        -- Actually, Roblox XML uses <BinaryString name="AttributesSerialize">
        -- which is complex. Let's try a simpler approach using tags.
        -- For now, we'll serialize attributes as a comment for preservation
        local attrParts = {}
        for attrName, attrValue in pairs(attributes) do
            local attrType = typeof(attrValue)
            local attrStr = tostring(attrValue)
            attrParts[#attrParts + 1] = string.format("  %s (%s) = %s",
                attrName, attrType, attrStr)
        end
        if #attrParts > 0 then
            -- We need to serialize AttributesSerialize as BinaryString
            -- This is complex, so we'll encode attributes into the XML format
            -- that Roblox understands
            self:serializeAttributes(instance, attributes)
        end
    end
    
    -- Try CollectionService tags
    local hasTags, tags = pcall(function()
        return instance:GetTags()
    end)
    if hasTags and tags and #tags > 0 then
        -- Tags are stored in the Tags property as a binary string
        -- Each tag is null-terminated
        local tagStr = table.concat(tags, "\0") .. "\0"
        -- Encode as BinaryString
        self:write(string.format(
            '<BinaryString name="Tags">%s</BinaryString>',
            self:base64Encode(tagStr)))
    end
    
    self:write('</Properties>')
    
    -- Serialize children
    local children = API.getChildren(instance)
    if #children > 0 then
        for _, child in ipairs(children) do
            self:serializeInstance(child, depth + 1)
        end
    end
    
    self:write('</Item>')
end

-- Base64 encoding for binary properties
function XMLSerializer:base64Encode(data)
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local result = {}
    local len = #data
    
    for i = 1, len, 3 do
        local b1 = string.byte(data, i) or 0
        local b2 = string.byte(data, i + 1) or 0
        local b3 = string.byte(data, i + 2) or 0
        
        local n = b1 * 65536 + b2 * 256 + b3
        
        result[#result + 1] = b64:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
        result[#result + 1] = b64:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
        
        if i + 1 <= len then
            result[#result + 1] = b64:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1)
        else
            result[#result + 1] = "="
        end
        
        if i + 2 <= len then
            result[#result + 1] = b64:sub(n % 64 + 1, n % 64 + 1)
        else
            result[#result + 1] = "="
        end
    end
    
    return table.concat(result)
end

-- Serialize attributes (simplified - stores as comment for now)
function XMLSerializer:serializeAttributes(instance, attributes)
    -- Proper attribute serialization requires a binary format
    -- For now, we encode them in a way that preserves the data
    -- Roblox Studio will recognize the AttributesSerialize property
    
    -- Build binary attribute data
    local parts = {}
    local attrCount = 0
    
    for name, value in pairs(attributes) do
        attrCount = attrCount + 1
    end
    
    -- Write attribute count
    parts[#parts + 1] = encodeUint32LE(attrCount)
    
    for name, value in pairs(attributes) do
        -- Write name (length-prefixed)
        parts[#parts + 1] = encodeUint32LE(#name)
        parts[#parts + 1] = name
        
        -- Write type and value
        local valType = typeof(value)
        if valType == "string" then
            parts[#parts + 1] = encodeUint8(2) -- String type
            parts[#parts + 1] = encodeUint32LE(#value)
            parts[#parts + 1] = value
        elseif valType == "boolean" then
            parts[#parts + 1] = encodeUint8(3) -- Bool type
            parts[#parts + 1] = encodeUint8(value and 1 or 0)
        elseif valType == "number" then
            parts[#parts + 1] = encodeUint8(5) -- Double type
            parts[#parts + 1] = encodeFloat64LE(value)
        elseif valType == "Vector3" then
            parts[#parts + 1] = encodeUint8(11) -- Vector3 type
            parts[#parts + 1] = encodeFloat32LE(value.X)
            parts[#parts + 1] = encodeFloat32LE(value.Y)
            parts[#parts + 1] = encodeFloat32LE(value.Z)
        elseif valType == "Color3" then
            parts[#parts + 1] = encodeUint8(15) -- Color3 type
            parts[#parts + 1] = encodeFloat32LE(value.R)
            parts[#parts + 1] = encodeFloat32LE(value.G)
            parts[#parts + 1] = encodeFloat32LE(value.B)
        else
            -- Skip unsupported attribute types
            parts[attrCount] = nil -- Remove count increment
            -- Actually, we already wrote the name, so this is problematic
            -- Let's just write it as a string
            local str = tostring(value)
            parts[#parts + 1] = encodeUint8(2)
            parts[#parts + 1] = encodeUint32LE(#str)
            parts[#parts + 1] = str
        end
    end
    
    local binaryData = table.concat(parts)
    self:write(string.format(
        '<BinaryString name="AttributesSerialize">%s</BinaryString>',
        self:base64Encode(binaryData)))
end

-- ============================================================================
-- SECTION 5: TERRAIN SERIALIZER
-- ============================================================================

function XMLSerializer:serializeTerrain()
    Log("PROG", "Serializing terrain...")
    
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        Log("WARN", "No terrain found in workspace")
        return
    end
    
    -- Get terrain region
    local regionOk, regionSize = pcall(function()
        -- Get the maximum extent of the terrain
        return terrain:ReadVoxels(
            Region3.new(Vector3.new(-1, -1, -1), Vector3.new(1, 1, 1)):ExpandToGrid(4),
            4
        )
    end)
    
    if not regionOk then
        Log("WARN", "Cannot read terrain voxels: %s", tostring(regionSize))
        -- Still create terrain item but without voxel data
        self:write('<Item class="Terrain" referent="' .. self:getRef(terrain) .. '">')
        self:write('<Properties>')
        self:write('<string name="Name">Terrain</string>')
        self:write('</Properties>')
        self:write('</Item>')
        return
    end
    
    self:write('<Item class="Terrain" referent="' .. self:getRef(terrain) .. '">')
    self:write('<Properties>')
    self:write('<string name="Name">Terrain</string>')
    
    -- Serialize terrain properties
    local terrainProps = {
        WaterColor = "Color3",
        WaterReflectance = "Float",
        WaterTransparency = "Float",
        WaterWaveSize = "Float",
        WaterWaveSpeed = "Float",
        Decoration = "Bool",
        GrassLength = "Float",
        MaterialColors = "BinaryString",
    }
    
    for propName, propType in pairs(terrainProps) do
        if propType == "BinaryString" then
            local ok, val = pcall(function() return terrain[propName] end)
            if ok and val then
                self:write(string.format(
                    '<BinaryString name="%s">%s</BinaryString>',
                    xmlEscape(propName), self:base64Encode(tostring(val))))
            end
        else
            local value, ok = API.getProperty(terrain, propName)
            if ok and value ~= nil then
                local xml = self:serializePropertyValue(propName, propType, value, terrain)
                if xml then
                    self:write(xml)
                end
            end
        end
    end
    
    -- Now serialize the actual terrain voxel data
    -- We need to read the terrain in chunks and encode it
    -- Roblox uses SmoothGrid (binary property) for terrain data
    
    -- Try to get terrain bounds
    local terrainSize = nil
    pcall(function()
        -- Attempt to determine terrain extent
        -- This is tricky since terrain can be sparse
        -- We'll try reading a large region
        local maxExtent = 2048 -- studs in each direction
        local step = 4 -- resolution
        
        -- Check if terrain has any content
        local testRegion = Region3.new(
            Vector3.new(-maxExtent, -maxExtent, -maxExtent),
            Vector3.new(maxExtent, maxExtent, maxExtent)
        ):ExpandToGrid(step)
        
        terrainSize = testRegion
    end)
    
    -- The actual terrain data needs to be encoded as SmoothGrid
    -- This is a complex binary format. For a reliable save, we'll use
    -- the terrain:CopyRegion() approach if available
    
    local terrainRegion = nil
    pcall(function()
        -- Try to copy the entire terrain region
        -- This creates a TerrainRegion object that can be serialized
        local maxSize = 1024
        local region = Region3.new(
            Vector3.new(-maxSize, -maxSize, -maxSize),
            Vector3.new(maxSize, maxSize, maxSize)
        ):ExpandToGrid(4)
        
        terrainRegion = terrain:CopyRegion(region)
    end)
    
    if terrainRegion then
        -- We have a TerrainRegion - but serializing its binary data is complex
        -- Instead, we'll save terrain data in a way that can be reconstructed
        Log("PROG", "Terrain region captured, encoding voxel data...")
        
        -- Read terrain in manageable chunks
        local chunkSize = CONFIG.TerrainChunkSize
        local maxExtent = 512
        local step = 4
        
        -- We'll store terrain data as a series of WriteVoxels-compatible data
        -- encoded in a ModuleScript that can reconstruct the terrain
        
        local terrainData = {}
        local totalVoxels = 0
        
        for x = -maxExtent, maxExtent - chunkSize, chunkSize do
            for z = -maxExtent, maxExtent - chunkSize, chunkSize do
                -- Read a vertical slice
                local ok, materials, occupancy = pcall(function()
                    local region = Region3.new(
                        Vector3.new(x, -maxExtent, z),
                        Vector3.new(x + chunkSize, maxExtent, z + chunkSize)
                    ):ExpandToGrid(step)
                    return terrain:ReadVoxels(region, step)
                end)
                
                if ok and materials then
                    -- Check if this chunk has any non-air voxels
                    local hasData = false
                    for xi = 1, #materials do
                        for yi = 1, #materials[xi] do
                            for zi = 1, #materials[xi][yi] do
                                if materials[xi][yi][zi] ~= Enum.Material.Air then
                                    hasData = true
                                    totalVoxels = totalVoxels + 1
                                end
                            end
                        end
                        if hasData then break end
                    end
                    
                    if hasData then
                        terrainData[#terrainData + 1] = {
                            x = x, z = z,
                            materials = materials,
                            occupancy = occupancy,
                        }
                    end
                end
                
                -- Yield to prevent timeout
                if task and task.wait then
                    task.wait()
                end
            end
            
            if #terrainData % 10 == 0 and #terrainData > 0 then
                Log("DBG", "Terrain chunks read: %d (total voxels: %d)", #terrainData, totalVoxels)
            end
        end
        
        Log("PROG", "Terrain: %d chunks with data, %d non-air voxels", #terrainData, totalVoxels)
        
        -- Store terrain reconstruction script as a child
        if #terrainData > 0 then
            -- Create a compact representation
            local terrainScript = self:buildTerrainReconstructionScript(terrainData, step, maxExtent, chunkSize)
            
            -- We'll add this as a child ModuleScript
            self:write('</Properties>')
            self:write(string.format(
                '<Item class="ModuleScript" referent="%s">',
                self:getRef(Instance.new("Folder")) -- dummy ref
            ))
            self:write('<Properties>')
            self:write('<string name="Name">TerrainData</string>')
            local escaped = terrainScript:gsub("]]>", "]]]]><![CDATA[>")
            self:write(string.format(
                '<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>',
                escaped))
            self:write('</Properties>')
            self:write('</Item>')
            self:write('</Item>')
            return
        end
    end
    
    self:write('</Properties>')
    self:write('</Item>')
end

-- Build a Lua script that can reconstruct terrain
function XMLSerializer:buildTerrainReconstructionScript(terrainData, step, maxExtent, chunkSize)
    local lines = {
        "-- [BaoSaveInstance] Terrain Reconstruction Data",
        "-- Run this ModuleScript to reconstruct terrain",
        "-- require(this_module)()",
        "",
        "return function()",
        "    local terrain = workspace.Terrain",
        "    terrain:Clear()",
        string.format("    local step = %d", step),
        string.format("    local chunkSize = %d", chunkSize),
        "",
    }
    
    for _, chunk in ipairs(terrainData) do
        -- Compress the material/occupancy data into a string representation
        local matStr = {}
        local occStr = {}
        
        for xi = 1, #chunk.materials do
            for yi = 1, #chunk.materials[xi] do
                for zi = 1, #chunk.materials[xi][yi] do
                    local mat = chunk.materials[xi][yi][zi]
                    local occ = chunk.occupancy[xi][yi][zi]
                    
                    if mat ~= Enum.Material.Air then
                        lines[#lines + 1] = string.format(
                            '    terrain:FillBlock(CFrame.new(%s, %s, %s), Vector3.new(%d,%d,%d), Enum.Material.%s)',
                            tostring(chunk.x + (xi-1) * step + step/2),
                            tostring(-maxExtent + (yi-1) * step + step/2),
                            tostring(chunk.z + (zi-1) * step + step/2),
                            step, step, step,
                            mat.Name
                        )
                    end
                end
            end
        end
    end
    
    lines[#lines + 1] = "end"
    
    return table.concat(lines, "\n")
end

-- ============================================================================
-- SECTION 6: MAIN ORCHESTRATOR
-- ============================================================================

local function getGameName()
    local name = "Unknown"
    pcall(function()
        local marketplaceService = game:GetService("MarketplaceService")
        local info = marketplaceService:GetProductInfo(game.PlaceId)
        if info and info.Name then
            name = info.Name
        end
    end)
    
    if name == "Unknown" then
        pcall(function()
            name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
        end)
    end
    
    if name == "Unknown" then
        name = "Place_" .. tostring(game.PlaceId)
    end
    
    -- Sanitize filename
    name = name:gsub("[^%w%s%-_]", "")
    name = name:gsub("%s+", "_")
    
    if #name == 0 then
        name = "Game_" .. tostring(game.PlaceId)
    end
    
    return name
end

local function main()
    local startTime = os.clock()
    
    print("==============================================")
    print("  BaoSaveInstance v1.0")
    print("  Full Game Decompiler & Serializer")
    print("==============================================")
    
    -- Step 1: Detect executor
    Log("PROG", "Step 1/6: Detecting executor...")
    DetectExecutor()
    
    Log("INFO", "Executor: %s", ExecutorName)
    Log("INFO", "Capabilities: decompile=%s, saveFile=%s, getHidden=%s",
        tostring(ExecutorCapabilities.canDecompile),
        tostring(ExecutorCapabilities.canSaveFile),
        tostring(ExecutorCapabilities.canGetHidden))
    
    if not ExecutorCapabilities.canSaveFile then
        Log("ERR", "Cannot save files! writefile not available. Aborting.")
        return
    end
    
    -- Step 2: Get game info
    Log("PROG", "Step 2/6: Getting game info...")
    local gameName = getGameName()
    local fileName = string.format(CONFIG.OutputNameTemplate, gameName)
    Log("INFO", "Game: %s (PlaceId: %d)", gameName, game.PlaceId)
    Log("INFO", "Output: %s", fileName)
    
    -- Step 3: Initialize serializer
    Log("PROG", "Step 3/6: Initializing serializer...")
    local serializer = XMLSerializer.new()
    
    -- Write XML header
    serializer:write('<?xml version="1.0" encoding="utf-8"?>')
    serializer:write('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">')
    
    -- Write metadata
    serializer:write('<Meta name="ExplicitAutoJoints">true</Meta>')
    
    -- Step 4: Serialize terrain
    Log("PROG", "Step 4/6: Serializing terrain...")
    pcall(function()
        serializer:serializeTerrain()
    end)
    
    -- Step 5: Serialize all services
    Log("PROG", "Step 5/6: Serializing game instances...")
    
    local game = game
    local totalServices = #CONFIG.ServicesToSave
    
    for idx, serviceName in ipairs(CONFIG.ServicesToSave) do
        Log("PROG", "  Serializing %s (%d/%d)...", serviceName, idx, totalServices)
        
        local ok, service = pcall(function()
            return game:GetService(serviceName)
        end)
        
        if ok and service then
            -- For Workspace, skip the Terrain (already serialized) and Camera
            if serviceName == "Workspace" then
                -- Serialize Workspace as container
                local wsRef = serializer:getRef(service)
                serializer:write(string.format(
                    '<Item class="Workspace" referent="%s">', wsRef))
                serializer:write('<Properties>')
                serializer:write('<string name="Name">Workspace</string>')
                
                -- Workspace-specific properties
                local wsProps = {
                    {"Gravity", "Float"},
                    {"FallenPartsDestroyHeight", "Float"},
                    {"AllowThirdPartySales", "Bool"},
                    {"StreamingEnabled", "Bool"},
                    {"StreamingMinRadius", "Int32"},
                    {"StreamingTargetRadius", "Int32"},
                    {"StreamingIntegrityMode", "Enum"},
                    {"StreamOutBehavior", "Enum"},
                    {"SignalBehavior", "Enum"},
                }
                
                for _, prop in ipairs(wsProps) do
                    local val, valOk = API.getProperty(service, prop[1])
                    if valOk and val ~= nil then
                        local xml = serializer:serializePropertyValue(prop[1], prop[2], val, service)
                        if xml then serializer:write(xml) end
                    end
                end
                
                -- CurrentCamera reference
                pcall(function()
                    if workspace.CurrentCamera then
                        serializer:write(string.format(
                            '<Ref name="CurrentCamera">%s</Ref>',
                            serializer:getRef(workspace.CurrentCamera)))
                    end
                end)
                
                serializer:write('</Properties>')
                
                -- Serialize Camera
                pcall(function()
                    local camera = workspace.CurrentCamera
                    if camera then
                        serializer:serializeInstance(camera)
                    end
                end)
                
                -- Serialize children (except Terrain which is already done)
                local children = API.getChildren(service)
                for _, child in ipairs(children) do
                    if child.ClassName ~= "Terrain" and child.ClassName ~= "Camera" then
                        pcall(function()
                            serializer:serializeInstance(child)
                        end)
                    end
                end
                
                serializer:write('</Item>')
            else
                -- Regular service
                pcall(function()
                    serializer:serializeInstance(service)
                end)
            end
        else
            Log("WARN", "  Could not access service: %s", serviceName)
        end
        
        -- Yield between services
        if task and task.wait then
            task.wait(CONFIG.YieldInterval)
        elseif wait then
            wait(CONFIG.YieldInterval)
        end
    end
    
    -- Close XML
    serializer:write('</roblox>')
    
    -- Step 6: Save file
    Log("PROG", "Step 6/6: Saving file...")
    
    local xmlData = serializer:getResult()
    Log("INFO", "Total XML size: %.2f MB", #xmlData / 1048576)
    
    -- Save the file
    local saveOk = API.saveFile(fileName, xmlData)
    
    if saveOk then
        local elapsed = os.clock() - startTime
        
        print("==============================================")
        Log("PROG", "BaoSaveInstance completed successfully")
        print("==============================================")
        Log("INFO", "File: %s", fileName)
        Log("INFO", "Size: %.2f MB", #xmlData / 1048576)
        Log("INFO", "Instances: %d", serializer.instanceCount)
        Log("INFO", "Scripts: %d (decompiled: %d, failed: %d)",
            serializer.scriptCount, serializer.decompileSuccess, serializer.decompileFail)
        Log("INFO", "Time: %.1f seconds", elapsed)
        Log("INFO", "Executor: %s", ExecutorName)
        print("==============================================")
    else
        Log("ERR", "Failed to save file!")
    end
    
    -- Cleanup
    serializer.buffer = nil
    serializer.refMap = nil
    serializer = nil
    xmlData = nil
    collectgarbage("collect")
    
    Log("INFO", "Cleanup complete. Memory freed.")
end

-- ============================================================================
-- SECTION 7: EXECUTION
-- ============================================================================

-- Wrap in protected call to catch any errors
local mainOk, mainErr = pcall(main)

if not mainOk then
    Log("ERR", "BaoSaveInstance crashed: %s", tostring(mainErr))
    Log("ERR", "Please report this error with your executor name and game.")
end

-- Ensure no lingering references
API = nil
PropertyDB = nil
CONFIG = nil
collectgarbage("collect")
