--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                      BaoSaveInstance v1.0                        ║
    ║         Advanced Roblox Place/Model Decompiler & Exporter        ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║  Modes:                                                          ║
    ║    1. DecompileFullGame()  - Full game with scripts & terrain    ║
    ║    2. DecompileFullModel() - Models only (no scripts/terrain)    ║
    ║    3. DecompileTerrain()   - Terrain data only                   ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------

BaoSaveInstance.Config = {
    -- Output Settings
    OutputFormat = "rbxlx",
    OutputFolder = "BaoSaveInstance",
    AutoCreateFolder = true,
    
    -- Decompilation Settings
    DecompileScripts = true,
    DecompileTimeout = 10,
    MaxRetries = 3,
    
    -- Export Settings
    PreserveDisabled = true,
    IncludePlayerScripts = false,
    IncludeTerrain = true,
    IncludeCamera = false,
    
    -- Performance Settings
    YieldInterval = 100,
    MaxInstancesPerCycle = 500,
    
    -- Debug Settings
    DebugMode = false,
    ProgressLogging = true,
    
    -- Services to export in full game mode
    ServicesToExport = {
        "Workspace",
        "Lighting",
        "MaterialService",
        "ReplicatedFirst",
        "ReplicatedStorage",
        "ServerScriptService",
        "ServerStorage",
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
        "SoundService",
        "Chat",
        "LocalizationService",
        "Teams",
        "TestService"
    },
    
    -- Blacklist Configuration
    Blacklist = {
        ClassNames = {
            "Player",
            "PlayerGui",
            "PlayerScripts",
            "Backpack",
            "CoreGui",
            "CorePackages",
            "RobloxPluginGuiService"
        },
        InstanceNames = {},
        Paths = {}
    },
    
    -- Whitelist (if enabled, only these will be exported)
    Whitelist = {
        Enabled = false,
        ClassNames = {},
        InstanceNames = {},
        Paths = {}
    }
}

--------------------------------------------------------------------------------
-- INTERNAL STATE
--------------------------------------------------------------------------------

local State = {
    TotalInstances = 0,
    ProcessedInstances = 0,
    Errors = {},
    Warnings = {},
    StartTime = 0,
    CurrentMode = nil
}

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local function Log(level, message)
    if not BaoSaveInstance.Config.DebugMode and level == "DEBUG" then
        return
    end
    
    local prefix = {
        DEBUG = "[DEBUG]",
        INFO = "[INFO]",
        WARN = "[WARN]",
        ERROR = "[ERROR]",
        PROGRESS = "[PROGRESS]"
    }
    
    print(string.format("%s BaoSaveInstance: %s", prefix[level] or "[LOG]", tostring(message)))
end

local function LogProgress(current, total, operation)
    if not BaoSaveInstance.Config.ProgressLogging then return end
    
    local percentage = math.floor((current / total) * 100)
    Log("PROGRESS", string.format("%s: %d%% (%d/%d)", operation, percentage, current, total))
end

local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        table.insert(State.Errors, tostring(result))
        Log("ERROR", result)
        return nil, result
    end
    return result
end

local function YieldIfNeeded(counter)
    if counter % BaoSaveInstance.Config.YieldInterval == 0 then
        RunService.Heartbeat:Wait()
    end
end

local function EnsureFolder(path)
    if not BaoSaveInstance.Config.AutoCreateFolder then return true end
    
    local success, err = pcall(function()
        if isfolder and not isfolder(path) then
            makefolder(path)
        end
    end)
    
    return success
end

local function GetGameName()
    local name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown"
    name = string.gsub(name, "[^%w%s%-_]", "")
    name = string.gsub(name, "%s+", "_")
    return name
end

local function GenerateFileName(mode)
    local gameName = SafeCall(GetGameName) or "Game"
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local format = BaoSaveInstance.Config.OutputFormat
    
    local prefix = {
        FullGame = "BaoSaveInstance_FullGame",
        FullModel = "BaoSaveInstance_Models",
        Terrain = "BaoSaveInstance_Terrain"
    }
    
    return string.format("%s/%s_%s_%s.%s", 
        BaoSaveInstance.Config.OutputFolder,
        prefix[mode] or "BaoSaveInstance",
        gameName,
        timestamp,
        format
    )
end

--------------------------------------------------------------------------------
-- XML SERIALIZATION ENGINE
--------------------------------------------------------------------------------

local XMLSerializer = {}

local function EscapeXML(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    
    str = string.gsub(str, "&", "&amp;")
    str = string.gsub(str, "<", "&lt;")
    str = string.gsub(str, ">", "&gt;")
    str = string.gsub(str, '"', "&quot;")
    str = string.gsub(str, "'", "&apos;")
    
    -- Remove invalid XML characters
    str = string.gsub(str, "[\x00-\x08\x0B\x0C\x0E-\x1F]", "")
    
    return str
end

local function EncodeBase64(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x) 
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
        return b:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

local PropertySerializers = {}

PropertySerializers["string"] = function(value)
    return string.format("<string>%s</string>", EscapeXML(value))
end

PropertySerializers["number"] = function(value)
    if value == math.huge then
        return "<float>INF</float>"
    elseif value == -math.huge then
        return "<float>-INF</float>"
    elseif value ~= value then
        return "<float>NAN</float>"
    else
        return string.format("<float>%s</float>", tostring(value))
    end
end

PropertySerializers["boolean"] = function(value)
    return string.format("<bool>%s</bool>", value and "true" or "false")
end

PropertySerializers["Vector3"] = function(value)
    return string.format([[<Vector3>
        <X>%s</X>
        <Y>%s</Y>
        <Z>%s</Z>
    </Vector3>]], value.X, value.Y, value.Z)
end

PropertySerializers["Vector2"] = function(value)
    return string.format([[<Vector2>
        <X>%s</X>
        <Y>%s</Y>
    </Vector2>]], value.X, value.Y)
end

PropertySerializers["CFrame"] = function(value)
    local components = {value:GetComponents()}
    return string.format([[<CoordinateFrame>
        <X>%s</X><Y>%s</Y><Z>%s</Z>
        <R00>%s</R00><R01>%s</R01><R02>%s</R02>
        <R10>%s</R10><R11>%s</R11><R12>%s</R12>
        <R20>%s</R20><R21>%s</R21><R22>%s</R22>
    </CoordinateFrame>]], unpack(components))
end

PropertySerializers["Color3"] = function(value)
    return string.format([[<Color3>
        <R>%s</R>
        <G>%s</G>
        <B>%s</B>
    </Color3>]], value.R, value.G, value.B)
end

PropertySerializers["BrickColor"] = function(value)
    return string.format("<int>%d</int>", value.Number)
end

PropertySerializers["UDim"] = function(value)
    return string.format([[<UDim>
        <S>%s</S>
        <O>%d</O>
    </UDim>]], value.Scale, value.Offset)
end

PropertySerializers["UDim2"] = function(value)
    return string.format([[<UDim2>
        <XS>%s</XS><XO>%d</XO>
        <YS>%s</YS><YO>%d</YO>
    </UDim2>]], value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
end

PropertySerializers["Rect"] = function(value)
    return string.format([[<Rect2D>
        <min><X>%s</X><Y>%s</Y></min>
        <max><X>%s</X><Y>%s</Y></max>
    </Rect2D>]], value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)
end

PropertySerializers["NumberSequence"] = function(value)
    local keypoints = {}
    for _, kp in ipairs(value.Keypoints) do
        table.insert(keypoints, string.format("%s %s %s", kp.Time, kp.Value, kp.Envelope))
    end
    return string.format("<NumberSequence>%s</NumberSequence>", table.concat(keypoints, " "))
end

PropertySerializers["ColorSequence"] = function(value)
    local keypoints = {}
    for _, kp in ipairs(value.Keypoints) do
        table.insert(keypoints, string.format("%s %s %s %s 0", 
            kp.Time, kp.Value.R, kp.Value.G, kp.Value.B))
    end
    return string.format("<ColorSequence>%s</ColorSequence>", table.concat(keypoints, " "))
end

PropertySerializers["NumberRange"] = function(value)
    return string.format("<NumberRange>%s %s</NumberRange>", value.Min, value.Max)
end

PropertySerializers["Ray"] = function(value)
    return string.format([[<Ray>
        <origin><X>%s</X><Y>%s</Y><Z>%s</Z></origin>
        <direction><X>%s</X><Y>%s</Y><Z>%s</Z></direction>
    </Ray>]], value.Origin.X, value.Origin.Y, value.Origin.Z,
        value.Direction.X, value.Direction.Y, value.Direction.Z)
end

PropertySerializers["Faces"] = function(value)
    local faces = 0
    if value.Top then faces = faces + 1 end
    if value.Bottom then faces = faces + 2 end
    if value.Left then faces = faces + 4 end
    if value.Right then faces = faces + 8 end
    if value.Back then faces = faces + 16 end
    if value.Front then faces = faces + 32 end
    return string.format("<Faces>%d</Faces>", faces)
end

PropertySerializers["Axes"] = function(value)
    local axes = 0
    if value.X then axes = axes + 1 end
    if value.Y then axes = axes + 2 end
    if value.Z then axes = axes + 4 end
    return string.format("<Axes>%d</Axes>", axes)
end

PropertySerializers["PhysicalProperties"] = function(value)
    if value then
        return string.format([[<PhysicalProperties>
            <CustomPhysics>true</CustomPhysics>
            <Density>%s</Density>
            <Friction>%s</Friction>
            <Elasticity>%s</Elasticity>
            <FrictionWeight>%s</FrictionWeight>
            <ElasticityWeight>%s</ElasticityWeight>
        </PhysicalProperties>]], 
            value.Density, value.Friction, value.Elasticity,
            value.FrictionWeight, value.ElasticityWeight)
    else
        return [[<PhysicalProperties><CustomPhysics>false</CustomPhysics></PhysicalProperties>]]
    end
end

PropertySerializers["EnumItem"] = function(value)
    return string.format("<token>%d</token>", value.Value)
end

PropertySerializers["Instance"] = function(value, refMap)
    if value and refMap[value] then
        return string.format("<Ref>%s</Ref>", refMap[value])
    else
        return "<Ref>null</Ref>"
    end
end

PropertySerializers["Content"] = function(value)
    return string.format("<Content><url>%s</url></Content>", EscapeXML(tostring(value)))
end

local function SerializeProperty(name, value, refMap)
    if value == nil then return nil end
    
    local valueType = typeof(value)
    local serializer = PropertySerializers[valueType]
    
    if serializer then
        if valueType == "Instance" then
            return string.format('<Item name="%s">%s</Item>', name, serializer(value, refMap))
        else
            return string.format('<Item name="%s">%s</Item>', name, serializer(value))
        end
    elseif valueType == "table" then
        return nil
    else
        return string.format('<Item name="%s"><string>%s</string></Item>', name, EscapeXML(tostring(value)))
    end
end

--------------------------------------------------------------------------------
-- INSTANCE SERIALIZATION
--------------------------------------------------------------------------------

local InstanceSerializer = {}

local PropertiesToIgnore = {
    "Parent", "DataCost", "RobloxLocked", "Archivable", "ClassName",
    "className", "archivable", "RobloxLocked"
}

local PropertiesToIgnoreSet = {}
for _, prop in ipairs(PropertiesToIgnore) do
    PropertiesToIgnoreSet[prop] = true
end

local function GetInstanceProperties(instance)
    local properties = {}
    
    local success, props = pcall(function()
        if getproperties then
            return getproperties(instance)
        elseif gethiddenproperties and getproperties then
            local visible = getproperties(instance)
            local hidden = gethiddenproperties(instance)
            for k, v in pairs(hidden) do
                visible[k] = v
            end
            return visible
        end
        return nil
    end)
    
    if success and props then
        for propName, propValue in pairs(props) do
            if not PropertiesToIgnoreSet[propName] then
                properties[propName] = propValue
            end
        end
    else
        -- Fallback: Try common properties
        local commonProps = {
            "Name", "Position", "Size", "CFrame", "Color", "BrickColor",
            "Material", "Transparency", "Reflectance", "Anchored", "CanCollide",
            "Shape", "FormFactor", "TopSurface", "BottomSurface", "LeftSurface",
            "RightSurface", "FrontSurface", "BackSurface", "Velocity", "RotVelocity",
            "Locked", "Massless", "RootPriority", "CustomPhysicalProperties",
            "Text", "TextColor3", "TextSize", "Font", "TextScaled", "TextWrapped",
            "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel",
            "Image", "ImageColor3", "ImageTransparency", "ScaleType", "SliceCenter",
            "SoundId", "Volume", "PlaybackSpeed", "Looped", "Playing",
            "MeshId", "TextureId", "Scale", "Offset", "VertexColor",
            "Brightness", "Range", "Shadows", "Enabled", "Face",
            "Adornee", "AlwaysOnTop", "ExtentsOffset", "ExtentsOffsetWorldSpace",
            "MaxDistance", "StudsOffset", "StudsOffsetWorldSpace",
            "Source", "LinkedSource", "Disabled",
            "Animation", "Priority", "Looped",
            "Attachment0", "Attachment1", "Visible",
            "C0", "C1", "Part0", "Part1",
            "MaxForce", "MaxTorque", "P", "D",
            "DesiredAngle", "MaxVelocity",
            "Value", "MaxValue", "MinValue"
        }
        
        for _, propName in ipairs(commonProps) do
            local propSuccess, propValue = pcall(function()
                return instance[propName]
            end)
            if propSuccess and propValue ~= nil then
                properties[propName] = propValue
            end
        end
    end
    
    return properties
end

local function CreateRefId()
    return HttpService:GenerateGUID(false):gsub("-", "")
end

local function BuildRefMap(instances)
    local refMap = {}
    for _, instance in ipairs(instances) do
        refMap[instance] = "RBX" .. CreateRefId()
    end
    return refMap
end

function InstanceSerializer.SerializeInstance(instance, refMap, depth)
    depth = depth or 0
    local indent = string.rep("  ", depth)
    
    local className = instance.ClassName
    local refId = refMap[instance] or ("RBX" .. CreateRefId())
    
    local lines = {}
    table.insert(lines, string.format('%s<Item class="%s" referent="%s">', indent, className, refId))
    table.insert(lines, string.format('%s  <Properties>', indent))
    
    -- Name property
    table.insert(lines, string.format('%s    <string name="Name">%s</string>', indent, EscapeXML(instance.Name)))
    
    -- Get and serialize properties
    local properties = GetInstanceProperties(instance)
    for propName, propValue in pairs(properties) do
        if propName ~= "Name" then
            local serialized = SerializeProperty(propName, propValue, refMap)
            if serialized then
                table.insert(lines, string.format('%s    %s', indent, serialized))
            end
        end
    end
    
    table.insert(lines, string.format('%s  </Properties>', indent))
    
    -- Serialize children
    local children = instance:GetChildren()
    if #children > 0 then
        for i, child in ipairs(children) do
            local childXml = InstanceSerializer.SerializeInstance(child, refMap, depth + 1)
            if childXml then
                table.insert(lines, childXml)
            end
            YieldIfNeeded(i)
        end
    end
    
    table.insert(lines, string.format('%s</Item>', indent))
    
    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- SCRIPT DECOMPILATION
--------------------------------------------------------------------------------

local ScriptHandler = {}

function ScriptHandler.DecompileScript(script)
    if not BaoSaveInstance.Config.DecompileScripts then
        return "-- Decompilation disabled"
    end
    
    local source = nil
    
    -- Try to get source directly
    local success, result = pcall(function()
        return script.Source
    end)
    
    if success and result and #result > 0 then
        source = result
    else
        -- Try decompile function
        for _, attempt in ipairs({
            function() return decompile(script) end,
            function() return getscriptbytecode and getscriptbytecode(script) end,
            function() return debug.getinfo and debug.getinfo(script).source end
        }) do
            local decompileSuccess, decompileResult = pcall(attempt)
            if decompileSuccess and decompileResult and #tostring(decompileResult) > 0 then
                source = decompileResult
                break
            end
        end
    end
    
    if not source or #source == 0 then
        source = string.format("-- Failed to decompile %s: %s", script.ClassName, script:GetFullName())
        table.insert(State.Warnings, "Failed to decompile: " .. script:GetFullName())
    end
    
    return source
end

function ScriptHandler.GetAllScripts(root)
    local scripts = {}
    
    local function search(instance)
        if instance:IsA("LuaSourceContainer") then
            table.insert(scripts, instance)
        end
        for _, child in ipairs(instance:GetChildren()) do
            search(child)
        end
    end
    
    if type(root) == "table" then
        for _, r in ipairs(root) do
            search(r)
        end
    else
        search(root)
    end
    
    return scripts
end

--------------------------------------------------------------------------------
-- TERRAIN SERIALIZATION
--------------------------------------------------------------------------------

local TerrainSerializer = {}

function TerrainSerializer.SerializeTerrain()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        Log("WARN", "No terrain found in workspace")
        return nil
    end
    
    Log("INFO", "Serializing terrain data...")
    
    local terrainData = {}
    
    -- Get terrain region
    local success, result = pcall(function()
        local regionStart = Vector3.new(-2048, -512, -2048)
        local regionEnd = Vector3.new(2048, 512, 2048)
        local region = Region3.new(regionStart, regionEnd)
        
        local materials, occupancies = terrain:ReadVoxels(region, 4)
        
        terrainData.RegionStart = regionStart
        terrainData.RegionEnd = regionEnd
        terrainData.Resolution = 4
        terrainData.Size = materials.Size
        
        -- Encode terrain data
        local materialData = {}
        local occupancyData = {}
        
        for x = 1, materials.Size.X do
            for y = 1, materials.Size.Y do
                for z = 1, materials.Size.Z do
                    local material = materials[x][y][z]
                    local occupancy = occupancies[x][y][z]
                    
                    if material ~= Enum.Material.Air and occupancy > 0 then
                        table.insert(materialData, {x, y, z, material.Value, occupancy})
                    end
                end
                YieldIfNeeded(y)
            end
            LogProgress(x, materials.Size.X, "Reading terrain voxels")
        end
        
        terrainData.VoxelData = materialData
        
        -- Get water properties
        terrainData.WaterWaveSize = terrain.WaterWaveSize
        terrainData.WaterWaveSpeed = terrain.WaterWaveSpeed
        terrainData.WaterReflectance = terrain.WaterReflectance
        terrainData.WaterTransparency = terrain.WaterTransparency
        terrainData.WaterColor = {
            R = terrain.WaterColor.R,
            G = terrain.WaterColor.G,
            B = terrain.WaterColor.B
        }
        
        return terrainData
    end)
    
    if not success then
        Log("ERROR", "Failed to read terrain: " .. tostring(result))
        return nil
    end
    
    return terrainData
end

function TerrainSerializer.CreateTerrainXML(terrainData)
    if not terrainData then return "" end
    
    local lines = {}
    table.insert(lines, '<Item class="Terrain" referent="RBXTerrain">')
    table.insert(lines, '  <Properties>')
    table.insert(lines, '    <string name="Name">Terrain</string>')
    table.insert(lines, string.format('    <float name="WaterWaveSize">%s</float>', terrainData.WaterWaveSize or 0.15))
    table.insert(lines, string.format('    <float name="WaterWaveSpeed">%s</float>', terrainData.WaterWaveSpeed or 10))
    table.insert(lines, string.format('    <float name="WaterReflectance">%s</float>', terrainData.WaterReflectance or 1))
    table.insert(lines, string.format('    <float name="WaterTransparency">%s</float>', terrainData.WaterTransparency or 0.3))
    
    if terrainData.WaterColor then
        table.insert(lines, string.format([[    <Color3 name="WaterColor">
        <R>%s</R>
        <G>%s</G>
        <B>%s</B>
    </Color3>]], terrainData.WaterColor.R, terrainData.WaterColor.G, terrainData.WaterColor.B))
    end
    
    -- Encode voxel data as base64 (simplified)
    if terrainData.VoxelData and #terrainData.VoxelData > 0 then
        local encodedData = HttpService:JSONEncode(terrainData.VoxelData)
        local base64Data = EncodeBase64(encodedData)
        table.insert(lines, string.format('    <BinaryString name="SmoothGrid">%s</BinaryString>', base64Data))
    end
    
    table.insert(lines, '  </Properties>')
    table.insert(lines, '</Item>')
    
    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- FILTERING FUNCTIONS
--------------------------------------------------------------------------------

local Filter = {}

function Filter.ShouldInclude(instance, mode)
    local config = BaoSaveInstance.Config
    
    -- Check blacklist
    if config.Blacklist.ClassNames then
        for _, className in ipairs(config.Blacklist.ClassNames) do
            if instance:IsA(className) then
                return false
            end
        end
    end
    
    if config.Blacklist.InstanceNames then
        for _, name in ipairs(config.Blacklist.InstanceNames) do
            if instance.Name == name then
                return false
            end
        end
    end
    
    -- Mode-specific filtering
    if mode == "FullModel" then
        -- Exclude scripts and terrain
        if instance:IsA("LuaSourceContainer") then
            return false
        end
        if instance:IsA("Terrain") then
            return false
        end
    elseif mode == "Terrain" then
        -- Only include terrain
        if not instance:IsA("Terrain") and instance ~= workspace then
            return false
        end
    end
    
    -- Check whitelist if enabled
    if config.Whitelist.Enabled then
        local whitelisted = false
        
        if config.Whitelist.ClassNames then
            for _, className in ipairs(config.Whitelist.ClassNames) do
                if instance:IsA(className) then
                    whitelisted = true
                    break
                end
            end
        end
        
        if not whitelisted and config.Whitelist.InstanceNames then
            for _, name in ipairs(config.Whitelist.InstanceNames) do
                if instance.Name == name then
                    whitelisted = true
                    break
                end
            end
        end
        
        if not whitelisted then
            return false
        end
    end
    
    return true
end

function Filter.CollectInstances(roots, mode)
    local instances = {}
    local counter = 0
    
    local function collect(instance, depth)
        counter = counter + 1
        YieldIfNeeded(counter)
        
        if not Filter.ShouldInclude(instance, mode) then
            return
        end
        
        table.insert(instances, instance)
        
        for _, child in ipairs(instance:GetChildren()) do
            collect(child, depth + 1)
        end
    end
    
    for _, root in ipairs(roots) do
        Log("INFO", "Collecting from: " .. root:GetFullName())
        collect(root, 0)
    end
    
    Log("INFO", string.format("Collected %d instances", #instances))
    return instances
end

--------------------------------------------------------------------------------
-- XML DOCUMENT GENERATION
--------------------------------------------------------------------------------

local function GenerateXMLDocument(content)
    return [[<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
    <Meta name="ExplicitAutoJoints">true</Meta>
]] .. content .. [[
</roblox>]]
end

local function SerializeServiceContainer(service, refMap, mode)
    local lines = {}
    
    local serviceName = service.ClassName
    local refId = refMap[service] or ("RBX" .. CreateRefId())
    
    table.insert(lines, string.format('<Item class="%s" referent="%s">', serviceName, refId))
    table.insert(lines, '  <Properties>')
    table.insert(lines, string.format('    <string name="Name">%s</string>', serviceName))
    table.insert(lines, '  </Properties>')
    
    -- Serialize children
    local children = service:GetChildren()
    local processedCount = 0
    
    for i, child in ipairs(children) do
        if Filter.ShouldInclude(child, mode) then
            local childXml = InstanceSerializer.SerializeInstance(child, refMap, 1)
            if childXml then
                table.insert(lines, childXml)
                processedCount = processedCount + 1
            end
        end
        YieldIfNeeded(i)
        LogProgress(i, #children, "Serializing " .. serviceName)
    end
    
    table.insert(lines, '</Item>')
    
    Log("INFO", string.format("Serialized %s: %d instances", serviceName, processedCount))
    
    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- NATIVE SAVEINSTANCE WRAPPER
--------------------------------------------------------------------------------

local function TryNativeSaveInstance(options)
    if not saveinstance then
        return false, "saveinstance not available"
    end
    
    local success, result = pcall(function()
        saveinstance(options)
    end)
    
    return success, result
end

local function BuildNativeOptions(mode, fileName)
    local options = {
        FileName = fileName,
        
        -- Decompilation
        DecompileMode = BaoSaveInstance.Config.DecompileScripts and "decompile" or "ignore",
        DecompileTimeout = BaoSaveInstance.Config.DecompileTimeout,
        
        -- Behavior
        ExtraInstances = {},
        NilInstances = false,
        RemovePlayerCharacters = true,
        
        -- Timeout
        Timeout = 60,
        
        -- Callbacks
        IgnoreList = {},
    }
    
    if mode == "FullGame" then
        options.Mode = "full"
        options.SavePlayers = false
        
        for _, className in ipairs(BaoSaveInstance.Config.Blacklist.ClassNames or {}) do
            table.insert(options.IgnoreList, className)
        end
        
    elseif mode == "FullModel" then
        options.Mode = "scripts"
        options.DecompileMode = "ignore"
        
        table.insert(options.IgnoreList, "Terrain")
        table.insert(options.IgnoreList, "Script")
        table.insert(options.IgnoreList, "LocalScript")
        table.insert(options.IgnoreList, "ModuleScript")
        
    elseif mode == "Terrain" then
        options.Mode = "optimized"
        options.ExtraInstances = {workspace:FindFirstChildOfClass("Terrain")}
    end
    
    return options
end

--------------------------------------------------------------------------------
-- MAIN EXPORT FUNCTIONS
--------------------------------------------------------------------------------

local function ExportToFile(content, fileName)
    Log("INFO", "Exporting to: " .. fileName)
    
    -- Ensure output folder exists
    EnsureFolder(BaoSaveInstance.Config.OutputFolder)
    
    local success, err = pcall(function()
        if writefile then
            writefile(fileName, content)
        else
            error("writefile function not available")
        end
    end)
    
    if success then
        Log("INFO", "Successfully exported: " .. fileName)
    else
        Log("ERROR", "Export failed: " .. tostring(err))
    end
    
    return success, err
end

local function PerformExport(mode)
    State.StartTime = tick()
    State.CurrentMode = mode
    State.Errors = {}
    State.Warnings = {}
    State.ProcessedInstances = 0
    
    local fileName = GenerateFileName(mode)
    
    Log("INFO", string.format("Starting %s export...", mode))
    Log("INFO", "Output file: " .. fileName)
    
    -- Try native saveinstance first
    local nativeOptions = BuildNativeOptions(mode, fileName)
    local nativeSuccess, nativeResult = TryNativeSaveInstance(nativeOptions)
    
    if nativeSuccess then
        Log("INFO", "Export completed using native saveinstance")
        local elapsed = tick() - State.StartTime
        Log("INFO", string.format("Total time: %.2f seconds", elapsed))
        return true, fileName
    end
    
    Log("INFO", "Native saveinstance unavailable, using custom serialization...")
    
    -- Custom serialization fallback
    local xmlContent = {}
    local allInstances = {}
    
    if mode == "FullGame" then
        -- Collect from all services
        for _, serviceName in ipairs(BaoSaveInstance.Config.ServicesToExport) do
            local success, service = pcall(function()
                return game:GetService(serviceName)
            end)
            
            if success and service then
                local instances = Filter.CollectInstances({service}, mode)
                for _, inst in ipairs(instances) do
                    table.insert(allInstances, inst)
                end
            end
        end
        
    elseif mode == "FullModel" then
        -- Collect models from Workspace only
        allInstances = Filter.CollectInstances({workspace}, mode)
        
    elseif mode == "Terrain" then
        -- Terrain only
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            table.insert(allInstances, terrain)
        end
    end
    
    State.TotalInstances = #allInstances
    Log("INFO", string.format("Total instances to serialize: %d", State.TotalInstances))
    
    -- Build reference map
    local refMap = BuildRefMap(allInstances)
    
    -- Serialize based on mode
    if mode == "FullGame" then
        for _, serviceName in ipairs(BaoSaveInstance.Config.ServicesToExport) do
            local success, service = pcall(function()
                return game:GetService(serviceName)
            end)
            
            if success and service then
                local serviceXml = SerializeServiceContainer(service, refMap, mode)
                table.insert(xmlContent, serviceXml)
            end
        end
        
    elseif mode == "FullModel" then
        -- Create a virtual Workspace container
        table.insert(xmlContent, '<Item class="Workspace" referent="RBXWorkspace">')
        table.insert(xmlContent, '  <Properties>')
        table.insert(xmlContent, '    <string name="Name">Workspace</string>')
        table.insert(xmlContent, '  </Properties>')
        
        for i, instance in ipairs(allInstances) do
            if instance.Parent == workspace then
                local instanceXml = InstanceSerializer.SerializeInstance(instance, refMap, 1)
                if instanceXml then
                    table.insert(xmlContent, instanceXml)
                end
            end
            State.ProcessedInstances = i
            LogProgress(i, #allInstances, "Serializing models")
        end
        
        table.insert(xmlContent, '</Item>')
        
    elseif mode == "Terrain" then
        local terrainData = TerrainSerializer.SerializeTerrain()
        if terrainData then
            table.insert(xmlContent, '<Item class="Workspace" referent="RBXWorkspace">')
            table.insert(xmlContent, '  <Properties>')
            table.insert(xmlContent, '    <string name="Name">Workspace</string>')
            table.insert(xmlContent, '  </Properties>')
            table.insert(xmlContent, TerrainSerializer.CreateTerrainXML(terrainData))
            table.insert(xmlContent, '</Item>')
        end
    end
    
    -- Generate final XML
    local finalXml = GenerateXMLDocument(table.concat(xmlContent, "\n"))
    
    -- Export
    local exportSuccess, exportErr = ExportToFile(finalXml, fileName)
    
    -- Report
    local elapsed = tick() - State.StartTime
    Log("INFO", string.format("Export completed in %.2f seconds", elapsed))
    Log("INFO", string.format("Processed %d instances", State.ProcessedInstances))
    
    if #State.Warnings > 0 then
        Log("WARN", string.format("%d warnings during export", #State.Warnings))
    end
    
    if #State.Errors > 0 then
        Log("ERROR", string.format("%d errors during export", #State.Errors))
    end
    
    return exportSuccess, exportSuccess and fileName or exportErr
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function BaoSaveInstance.DecompileFullGame()
    Log("INFO", "=== DECOMPILE FULL GAME ===")
    return PerformExport("FullGame")
end

function BaoSaveInstance.DecompileFullModel()
    Log("INFO", "=== DECOMPILE FULL MODEL ===")
    return PerformExport("FullModel")
end

function BaoSaveInstance.DecompileTerrain()
    Log("INFO", "=== DECOMPILE TERRAIN ===")
    return PerformExport("Terrain")
end

-- Advanced export with custom options
function BaoSaveInstance.Export(options)
    options = options or {}
    
    -- Merge options with config
    for key, value in pairs(options) do
        if BaoSaveInstance.Config[key] ~= nil then
            BaoSaveInstance.Config[key] = value
        end
    end
    
    local mode = options.Mode or "FullGame"
    
    if mode == "FullGame" then
        return BaoSaveInstance.DecompileFullGame()
    elseif mode == "FullModel" then
        return BaoSaveInstance.DecompileFullModel()
    elseif mode == "Terrain" then
        return BaoSaveInstance.DecompileTerrain()
    else
        Log("ERROR", "Unknown export mode: " .. tostring(mode))
        return false, "Unknown mode"
    end
end

-- Get export status
function BaoSaveInstance.GetStatus()
    return {
        CurrentMode = State.CurrentMode,
        TotalInstances = State.TotalInstances,
        ProcessedInstances = State.ProcessedInstances,
        Progress = State.TotalInstances > 0 and (State.ProcessedInstances / State.TotalInstances * 100) or 0,
        Errors = State.Errors,
        Warnings = State.Warnings,
        ElapsedTime = State.StartTime > 0 and (tick() - State.StartTime) or 0
    }
end

-- Set configuration
function BaoSaveInstance.SetConfig(key, value)
    if BaoSaveInstance.Config[key] ~= nil then
        BaoSaveInstance.Config[key] = value
        Log("INFO", string.format("Config updated: %s = %s", key, tostring(value)))
        return true
    end
    Log("WARN", "Unknown config key: " .. tostring(key))
    return false
end

-- Add to blacklist
function BaoSaveInstance.AddToBlacklist(category, value)
    if category == "ClassName" then
        table.insert(BaoSaveInstance.Config.Blacklist.ClassNames, value)
    elseif category == "InstanceName" then
        table.insert(BaoSaveInstance.Config.Blacklist.InstanceNames, value)
    elseif category == "Path" then
        table.insert(BaoSaveInstance.Config.Blacklist.Paths, value)
    end
end

-- Add to whitelist
function BaoSaveInstance.AddToWhitelist(category, value)
    if category == "ClassName" then
        table.insert(BaoSaveInstance.Config.Whitelist.ClassNames, value)
    elseif category == "InstanceName" then
        table.insert(BaoSaveInstance.Config.Whitelist.InstanceNames, value)
    elseif category == "Path" then
        table.insert(BaoSaveInstance.Config.Whitelist.Paths, value)
    end
end

-- Quick export functions
function BaoSaveInstance.QuickSaveGame()
    BaoSaveInstance.Config.DecompileScripts = true
    BaoSaveInstance.Config.IncludeTerrain = true
    return BaoSaveInstance.DecompileFullGame()
end

function BaoSaveInstance.QuickSaveModels()
    return BaoSaveInstance.DecompileFullModel()
end

function BaoSaveInstance.QuickSaveTerrain()
    return BaoSaveInstance.DecompileTerrain()
end

--------------------------------------------------------------------------------
-- REGISTER GLOBAL
--------------------------------------------------------------------------------

if getgenv then
    getgenv().BaoSaveInstance = BaoSaveInstance
end

Log("INFO", "BaoSaveInstance loaded successfully")
Log("INFO", "Available modes: DecompileFullGame(), DecompileFullModel(), DecompileTerrain()")

return BaoSaveInstance
