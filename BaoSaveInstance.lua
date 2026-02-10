--[[
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
    
    BaoSaveInstance v3.0 - Complete Game Decompiler & RBXL Exporter
    
    Chức năng:
      1. Decompile Full Game → .rbxl
      2. Decompile Full Model → .rbxl  
      3. Decompile Terrain → .rbxl
      
    Yêu cầu: Executor hỗ trợ saveinstance / syn.saveinstance / writefile
    Tác giả: BaoSaveInstance Project
]]

-- ═══════════════════════════════════════════════════════════════
-- MODULE CHÍNH
-- ═══════════════════════════════════════════════════════════════

local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance
BaoSaveInstance.Version = "3.0"
BaoSaveInstance.StatusCallback = nil -- callback để cập nhật UI

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Chat = game:GetService("Chat")
local LocalizationService = game:GetService("LocalizationService")
local TestService = game:GetService("TestService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local MaterialService = game:GetService("MaterialService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- TIỆN ÍCH PHÁT HIỆN EXECUTOR
-- ═══════════════════════════════════════════════════════════════

local ExecutorSupport = {}

-- Phát hiện hàm saveinstance có sẵn trong executor
function ExecutorSupport.detectSaveInstance()
    -- Thứ tự ưu tiên: saveinstance > syn.saveinstance > custom
    if saveinstance then
        return "saveinstance"
    elseif syn and syn.saveinstance then
        return "syn.saveinstance"
    elseif KRNL_LOADED and saveinstance then
        return "krnl.saveinstance"
    elseif fluxus and fluxus.saveinstance then
        return "fluxus.saveinstance"
    elseif SaveInstance then
        return "SaveInstance"
    end
    return nil
end

-- Phát hiện hàm decompile
function ExecutorSupport.detectDecompiler()
    if decompile then
        return "decompile"
    elseif syn and syn.decompile then
        return "syn.decompile"
    elseif getscriptbytecode then
        return "getscriptbytecode"
    end
    return nil
end

-- Phát hiện writefile
function ExecutorSupport.hasWriteFile()
    return writefile ~= nil
end

-- Phát hiện isfile
function ExecutorSupport.hasIsFile()
    return isfile ~= nil
end

-- Phát hiện makefolder
function ExecutorSupport.hasMakeFolder()
    return makefolder ~= nil
end

-- Phát hiện gethiddenproperty
function ExecutorSupport.hasGetHiddenProperty()
    return gethiddenproperty ~= nil
end

-- Phát hiện gethui / get hidden ui
function ExecutorSupport.hasGetHUI()
    return gethui ~= nil or get_hidden_gui ~= nil
end

-- Phát hiện getinstances
function ExecutorSupport.hasGetInstances()
    return getinstances ~= nil
end

-- Phát hiện getnilinstances
function ExecutorSupport.hasGetNilInstances()
    return getnilinstances ~= nil
end

-- Phát hiện getloadedmodules
function ExecutorSupport.hasGetLoadedModules()
    return getloadedmodules ~= nil
end

-- ═══════════════════════════════════════════════════════════════
-- TRẠNG THÁI & LOG
-- ═══════════════════════════════════════════════════════════════

local StatusLog = {}
StatusLog.entries = {}
StatusLog.currentStatus = "Idle"

function StatusLog.setStatus(text)
    StatusLog.currentStatus = text
    table.insert(StatusLog.entries, {
        time = os.clock(),
        message = text
    })
    -- Gọi callback nếu có (để cập nhật UI)
    if BaoSaveInstance.StatusCallback then
        pcall(BaoSaveInstance.StatusCallback, text)
    end
    -- In ra console
    print("[BaoSaveInstance] " .. text)
end

function StatusLog.getStatus()
    return StatusLog.currentStatus
end

-- ═══════════════════════════════════════════════════════════════
-- DECOMPILER MODULE
-- ═══════════════════════════════════════════════════════════════

local Decompiler = {}

-- Decompile một script đơn lẻ, trả về source code dạng readable Lua
function Decompiler.decompileScript(scriptInstance)
    -- Thử lấy source trực tiếp (nếu có quyền)
    local success, source = pcall(function()
        return scriptInstance.Source
    end)
    if success and source and #source > 0 then
        return source
    end

    -- Thử dùng decompile() native
    if decompile then
        local ok, result = pcall(decompile, scriptInstance)
        if ok and result and #result > 0 then
            return result
        end
    end

    -- Thử dùng syn.decompile()
    if syn and syn.decompile then
        local ok, result = pcall(syn.decompile, scriptInstance)
        if ok and result and #result > 0 then
            return result
        end
    end

    -- Fallback: trả về comment thông báo không decompile được
    local scriptType = scriptInstance.ClassName
    local scriptPath = Decompiler.getFullPath(scriptInstance)
    return string.format(
        "-- [BaoSaveInstance] Could not decompile this %s\n-- Path: %s\n-- The script bytecode was not accessible\n",
        scriptType,
        scriptPath
    )
end

-- Lấy đường dẫn đầy đủ của instance
function Decompiler.getFullPath(instance)
    local path = {}
    local current = instance
    while current and current ~= game do
        table.insert(path, 1, current.Name)
        current = current.Parent
    end
    return "game." .. table.concat(path, ".")
end

-- Decompile tất cả scripts trong một instance (đệ quy)
-- Trả về bảng {scriptInstance = sourceCode}
function Decompiler.decompileAllScripts(root)
    local results = {}
    local scriptCount = 0
    local totalScripts = 0

    -- Đếm tổng số scripts trước
    local function countScripts(parent)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("LuaSourceContainer") then
                totalScripts = totalScripts + 1
            end
        end
    end

    pcall(countScripts, root)
    StatusLog.setStatus(string.format("Found %d scripts to decompile...", totalScripts))

    -- Decompile từng script
    local function processInstance(parent)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("LuaSourceContainer") then
                scriptCount = scriptCount + 1
                StatusLog.setStatus(string.format(
                    "Decompiling Scripts... [%d/%d] %s",
                    scriptCount, totalScripts, child.Name
                ))

                local source = Decompiler.decompileScript(child)
                results[child] = source

                -- Yield để tránh crash với game lớn
                if scriptCount % 5 == 0 then
                    task.wait()
                end
            end
        end
    end

    pcall(processInstance, root)
    StatusLog.setStatus(string.format("Decompiled %d/%d scripts", scriptCount, totalScripts))
    return results, scriptCount
end

-- Gán source đã decompile ngược lại vào script instances
function Decompiler.applyDecompiledSources(decompiledMap)
    local applied = 0
    for scriptInst, source in pairs(decompiledMap) do
        pcall(function()
            scriptInst.Source = source
        end)
        applied = applied + 1
    end
    return applied
end

-- ═══════════════════════════════════════════════════════════════
-- TERRAIN MODULE
-- ═══════════════════════════════════════════════════════════════

local TerrainModule = {}

-- Đọc toàn bộ terrain data
function TerrainModule.readTerrainData()
    local terrain = Workspace.Terrain
    if not terrain then
        StatusLog.setStatus("No terrain found")
        return nil
    end

    StatusLog.setStatus("Reading terrain data...")

    local terrainData = {}

    -- Lấy terrain region
    pcall(function()
        local regionSize = terrain:GetMaxExtents()
        terrainData.maxExtents = {
            Min = {X = regionSize.Min.X, Y = regionSize.Min.Y, Z = regionSize.Min.Z},
            Max = {X = regionSize.Max.X, Y = regionSize.Max.Y, Z = regionSize.Max.Z}
        }
    end)

    -- Kiểm tra terrain có dữ liệu không
    local hasData = false
    pcall(function()
        local testRegion = Region3int16.new(
            Vector3int16.new(-32, -32, -32),
            Vector3int16.new(32, 32, 32)
        )
        local materials, occupancy = terrain:ReadVoxels(
            Region3.new(
                Vector3.new(-128, -128, -128),
                Vector3.new(128, 128, 128)
            ):ExpandToGrid(4),
            4
        )
        if materials and #materials > 0 then
            hasData = true
        end
    end)

    terrainData.hasData = hasData

    -- Lấy terrain properties
    pcall(function()
        terrainData.WaterColor = {
            R = terrain.WaterColor.R,
            G = terrain.WaterColor.G,
            B = terrain.WaterColor.B
        }
        terrainData.WaterReflectance = terrain.WaterReflectance
        terrainData.WaterTransparency = terrain.WaterTransparency
        terrainData.WaterWaveSize = terrain.WaterWaveSize
        terrainData.WaterWaveSpeed = terrain.WaterWaveSpeed
    end)

    StatusLog.setStatus("Terrain data read complete")
    return terrainData
end

-- ═══════════════════════════════════════════════════════════════
-- SERIALIZER - TẠO NỘI DUNG RBXL (XML FORMAT)
-- ═══════════════════════════════════════════════════════════════

local Serializer = {}

-- Escape XML characters
function Serializer.escapeXml(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    str = str:gsub("&", "&amp;")
    str = str:gsub("<", "&lt;")
    str = str:gsub(">", "&gt;")
    str = str:gsub('"', "&quot;")
    str = str:gsub("'", "&apos;")
    -- Loại bỏ các ký tự không hợp lệ trong XML
    str = str:gsub("[%z\1-\8\11\12\14-\31]", "")
    return str
end

-- Tạo referent ID duy nhất
local _refCounter = 0
function Serializer.newRef()
    _refCounter = _refCounter + 1
    return "RBX" .. tostring(_refCounter)
end

-- Reset ref counter
function Serializer.resetRefs()
    _refCounter = 0
end

-- Serialize một giá trị property thành XML
function Serializer.serializePropertyValue(propName, value, propType)
    if value == nil then return "" end

    local xml = ""

    if propType == "string" or type(value) == "string" then
        xml = string.format('    <string name="%s">%s</string>\n',
            Serializer.escapeXml(propName),
            Serializer.escapeXml(tostring(value))
        )
    elseif propType == "ProtectedString" then
        xml = string.format('    <ProtectedString name="%s"><![CDATA[%s]]></ProtectedString>\n',
            Serializer.escapeXml(propName),
            tostring(value)
        )
    elseif propType == "bool" or type(value) == "boolean" then
        xml = string.format('    <bool name="%s">%s</bool>\n',
            Serializer.escapeXml(propName),
            tostring(value)
        )
    elseif propType == "int" then
        xml = string.format('    <int name="%s">%d</int>\n',
            Serializer.escapeXml(propName),
            tonumber(value) or 0
        )
    elseif propType == "int64" then
        xml = string.format('    <int64 name="%s">%d</int64>\n',
            Serializer.escapeXml(propName),
            tonumber(value) or 0
        )
    elseif propType == "float" or propType == "double" or type(value) == "number" then
        xml = string.format('    <float name="%s">%s</float>\n',
            Serializer.escapeXml(propName),
            tostring(value)
        )
    elseif propType == "token" then
        xml = string.format('    <token name="%s">%d</token>\n',
            Serializer.escapeXml(propName),
            tonumber(value) or 0
        )
    elseif propType == "BrickColor" then
        local brickColorNum = 194 -- Medium stone grey default
        pcall(function()
            if typeof(value) == "BrickColor" then
                brickColorNum = value.Number
            else
                brickColorNum = tonumber(value) or 194
            end
        end)
        xml = string.format('    <int name="%s">%d</int>\n',
            Serializer.escapeXml(propName),
            brickColorNum
        )
    elseif typeof(value) == "Color3" then
        xml = string.format(
            '    <Color3 name="%s">\n      <R>%s</R>\n      <G>%s</G>\n      <B>%s</B>\n    </Color3>\n',
            Serializer.escapeXml(propName),
            tostring(value.R), tostring(value.G), tostring(value.B)
        )
    elseif typeof(value) == "Vector3" then
        xml = string.format(
            '    <Vector3 name="%s">\n      <X>%s</X>\n      <Y>%s</Y>\n      <Z>%s</Z>\n    </Vector3>\n',
            Serializer.escapeXml(propName),
            tostring(value.X), tostring(value.Y), tostring(value.Z)
        )
    elseif typeof(value) == "Vector2" then
        xml = string.format(
            '    <Vector2 name="%s">\n      <X>%s</X>\n      <Y>%s</Y>\n    </Vector2>\n',
            Serializer.escapeXml(propName),
            tostring(value.X), tostring(value.Y)
        )
    elseif typeof(value) == "CFrame" then
        local components = {value:GetComponents()}
        xml = string.format(
            '    <CoordinateFrame name="%s">\n' ..
            '      <X>%s</X>\n      <Y>%s</Y>\n      <Z>%s</Z>\n' ..
            '      <R00>%s</R00>\n      <R01>%s</R01>\n      <R02>%s</R02>\n' ..
            '      <R10>%s</R10>\n      <R11>%s</R11>\n      <R12>%s</R12>\n' ..
            '      <R20>%s</R20>\n      <R21>%s</R21>\n      <R22>%s</R22>\n' ..
            '    </CoordinateFrame>\n',
            Serializer.escapeXml(propName),
            tostring(components[1]), tostring(components[2]), tostring(components[3]),
            tostring(components[4]), tostring(components[5]), tostring(components[6]),
            tostring(components[7]), tostring(components[8]), tostring(components[9]),
            tostring(components[10]), tostring(components[11]), tostring(components[12])
        )
    elseif typeof(value) == "UDim" then
        xml = string.format(
            '    <UDim name="%s">\n      <S>%s</S>\n      <O>%d</O>\n    </UDim>\n',
            Serializer.escapeXml(propName),
            tostring(value.Scale), value.Offset
        )
    elseif typeof(value) == "UDim2" then
        xml = string.format(
            '    <UDim2 name="%s">\n' ..
            '      <XS>%s</XS>\n      <XO>%d</XO>\n' ..
            '      <YS>%s</YS>\n      <YO>%d</YO>\n' ..
            '    </UDim2>\n',
            Serializer.escapeXml(propName),
            tostring(value.X.Scale), value.X.Offset,
            tostring(value.Y.Scale), value.Y.Offset
        )
    elseif typeof(value) == "Rect" then
        xml = string.format(
            '    <Rect2D name="%s">\n' ..
            '      <min><X>%s</X><Y>%s</Y></min>\n' ..
            '      <max><X>%s</X><Y>%s</Y></max>\n' ..
            '    </Rect2D>\n',
            Serializer.escapeXml(propName),
            tostring(value.Min.X), tostring(value.Min.Y),
            tostring(value.Max.X), tostring(value.Max.Y)
        )
    elseif typeof(value) == "NumberRange" then
        xml = string.format(
            '    <NumberRange name="%s">%s %s</NumberRange>\n',
            Serializer.escapeXml(propName),
            tostring(value.Min), tostring(value.Max)
        )
    elseif typeof(value) == "NumberSequence" then
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%s %s %s",
                tostring(kp.Time), tostring(kp.Value), tostring(kp.Envelope)
            ))
        end
        xml = string.format(
            '    <NumberSequence name="%s">%s</NumberSequence>\n',
            Serializer.escapeXml(propName),
            table.concat(keypoints, " ")
        )
    elseif typeof(value) == "ColorSequence" then
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("%s %s %s %s 0",
                tostring(kp.Time),
                tostring(kp.Value.R), tostring(kp.Value.G), tostring(kp.Value.B)
            ))
        end
        xml = string.format(
            '    <ColorSequence name="%s">%s</ColorSequence>\n',
            Serializer.escapeXml(propName),
            table.concat(keypoints, " ")
        )
    elseif typeof(value) == "EnumItem" then
        xml = string.format('    <token name="%s">%d</token>\n',
            Serializer.escapeXml(propName),
            value.Value
        )
    elseif typeof(value) == "PhysicalProperties" then
        if value then
            xml = string.format(
                '    <PhysicalProperties name="%s">\n' ..
                '      <CustomPhysics>true</CustomPhysics>\n' ..
                '      <Density>%s</Density>\n' ..
                '      <Friction>%s</Friction>\n' ..
                '      <Elasticity>%s</Elasticity>\n' ..
                '      <FrictionWeight>%s</FrictionWeight>\n' ..
                '      <ElasticityWeight>%s</ElasticityWeight>\n' ..
                '    </PhysicalProperties>\n',
                Serializer.escapeXml(propName),
                tostring(value.Density), tostring(value.Friction),
                tostring(value.Elasticity), tostring(value.FrictionWeight),
                tostring(value.ElasticityWeight)
            )
        else
            xml = string.format(
                '    <PhysicalProperties name="%s">\n' ..
                '      <CustomPhysics>false</CustomPhysics>\n' ..
                '    </PhysicalProperties>\n',
                Serializer.escapeXml(propName)
            )
        end
    elseif typeof(value) == "Content" or propType == "Content" then
        xml = string.format('    <Content name="%s"><url>%s</url></Content>\n',
            Serializer.escapeXml(propName),
            Serializer.escapeXml(tostring(value))
        )
    elseif typeof(value) == "Faces" then
        local faceVal = 0
        pcall(function()
            if value.Top then faceVal = faceVal + 1 end
            if value.Bottom then faceVal = faceVal + 2 end
            if value.Left then faceVal = faceVal + 4 end
            if value.Right then faceVal = faceVal + 8 end
            if value.Back then faceVal = faceVal + 16 end
            if value.Front then faceVal = faceVal + 32 end
        end)
        xml = string.format('    <Faces name="%s">%d</Faces>\n',
            Serializer.escapeXml(propName), faceVal
        )
    elseif typeof(value) == "Axes" then
        local axesVal = 0
        pcall(function()
            if value.X then axesVal = axesVal + 1 end
            if value.Y then axesVal = axesVal + 2 end
            if value.Z then axesVal = axesVal + 4 end
        end)
        xml = string.format('    <Axes name="%s">%d</Axes>\n',
            Serializer.escapeXml(propName), axesVal
        )
    else
        -- Fallback: serialize as string
        xml = string.format('    <string name="%s">%s</string>\n',
            Serializer.escapeXml(propName),
            Serializer.escapeXml(tostring(value))
        )
    end

    return xml
end

-- ═══════════════════════════════════════════════════════════════
-- PROPERTY MAP - Định nghĩa properties cho từng class
-- ═══════════════════════════════════════════════════════════════

local PropertyMap = {}

-- Properties cơ bản cho tất cả instances
PropertyMap.Base = {"Name", "Archivable"}

-- Properties cho BasePart (Part, MeshPart, UnionOperation, etc.)
PropertyMap.BasePart = {
    "Anchored", "BrickColor", "CFrame", "CanCollide", "CanTouch", "CanQuery",
    "CastShadow", "CollisionGroup", "Color", "CustomPhysicalProperties",
    "Locked", "Massless", "Material", "MaterialVariant",
    "Reflectance", "RootPriority", "RotVelocity",
    "Size", "Transparency", "Velocity"
}

-- Properties cho Part
PropertyMap.Part = {"Shape"}

-- Properties cho MeshPart
PropertyMap.MeshPart = {
    "MeshId", "TextureID", "CollisionFidelity", "RenderFidelity"
}

-- Properties cho UnionOperation
PropertyMap.UnionOperation = {
    "CollisionFidelity", "RenderFidelity", "SmoothingAngle", "UsePartColor"
}

-- Properties cho Scripts
PropertyMap.Script = {"Source", "Disabled", "RunContext"}
PropertyMap.LocalScript = {"Source", "Disabled"}
PropertyMap.ModuleScript = {"Source"}

-- Properties cho Model
PropertyMap.Model = {"PrimaryPart", "LevelOfDetail", "ModelStreamingMode"}

-- Properties cho SpawnLocation
PropertyMap.SpawnLocation = {
    "AllowTeamChangeOnTouch", "Duration", "Enabled", "Neutral", "TeamColor"
}

-- Properties cho Seat/VehicleSeat
PropertyMap.Seat = {"Disabled"}
PropertyMap.VehicleSeat = {
    "Disabled", "MaxSpeed", "Steer", "SteerFloat",
    "Throttle", "ThrottleFloat", "Torque", "TurnSpeed"
}

-- Properties cho Decal/Texture
PropertyMap.Decal = {
    "Color3", "Face", "Texture", "Transparency", "ZIndex"
}
PropertyMap.Texture = {
    "Color3", "Face", "OffsetStudsU", "OffsetStudsV",
    "StudsPerTileU", "StudsPerTileV", "Texture", "Transparency", "ZIndex"
}

-- Properties cho SurfaceAppearance
PropertyMap.SurfaceAppearance = {
    "AlphaMode", "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap",
    "TexturePack"
}

-- Properties cho Attachment
PropertyMap.Attachment = {"CFrame", "Visible"}
PropertyMap.Bone = {"CFrame", "Visible"}

-- Properties cho Weld/WeldConstraint
PropertyMap.Weld = {"C0", "C1", "Part0", "Part1", "Enabled"}
PropertyMap.WeldConstraint = {"Part0", "Part1", "Enabled"}
PropertyMap.Motor6D = {"C0", "C1", "Part0", "Part1", "Enabled", "MaxVelocity"}

-- Properties cho Constraints
PropertyMap.BallSocketConstraint = {
    "Attachment0", "Attachment1", "Enabled", "LimitsEnabled",
    "MaxFrictionTorque", "Radius", "Restitution",
    "TwistLimitsEnabled", "TwistLowerAngle", "TwistUpperAngle",
    "UpperAngle"
}
PropertyMap.HingeConstraint = {
    "Attachment0", "Attachment1", "ActuatorType", "AngularResponsiveness",
    "AngularSpeed", "AngularVelocity", "Enabled", "LimitsEnabled",
    "LowerAngle", "MotorMaxAcceleration", "MotorMaxTorque",
    "Radius", "Restitution", "ServoMaxTorque", "TargetAngle",
    "UpperAngle"
}
PropertyMap.PrismaticConstraint = {
    "Attachment0", "Attachment1", "ActuatorType", "Enabled",
    "LimitsEnabled", "LowerLimit", "MotorMaxAcceleration",
    "MotorMaxForce", "Restitution", "ServoMaxForce",
    "Size", "Speed", "TargetPosition", "UpperLimit", "Velocity"
}
PropertyMap.SpringConstraint = {
    "Attachment0", "Attachment1", "Coils", "Damping", "Enabled",
    "FreeLength", "LimitsEnabled", "MaxForce", "MaxLength",
    "MinLength", "Radius", "Stiffness", "Thickness"
}
PropertyMap.RopeConstraint = {
    "Attachment0", "Attachment1", "Color", "Enabled",
    "Length", "Restitution", "Thickness", "Visible",
    "WinchEnabled", "WinchForce", "WinchResponsiveness",
    "WinchSpeed", "WinchTarget"
}
PropertyMap.RodConstraint = {
    "Attachment0", "Attachment1", "Color", "Enabled",
    "Length", "Thickness", "Visible"
}
PropertyMap.AlignOrientation = {
    "Attachment0", "Attachment1", "Enabled", "MaxAngularVelocity",
    "MaxTorque", "Mode", "PrimaryAxisOnly", "ReactionTorqueEnabled",
    "Responsiveness", "RigidityEnabled"
}
PropertyMap.AlignPosition = {
    "Attachment0", "Attachment1", "ApplyAtCenterOfMass", "Enabled",
    "MaxForce", "MaxVelocity", "Mode", "ReactionForceEnabled",
    "Responsiveness", "RigidityEnabled"
}

-- Properties cho Light objects
PropertyMap.PointLight = {
    "Brightness", "Color", "Enabled", "Range", "Shadows"
}
PropertyMap.SpotLight = {
    "Angle", "Brightness", "Color", "Enabled", "Face",
    "Range", "Shadows"
}
PropertyMap.SurfaceLight = {
    "Angle", "Brightness", "Color", "Enabled", "Face",
    "Range", "Shadows"
}

-- Properties cho ParticleEmitter
PropertyMap.ParticleEmitter = {
    "Acceleration", "Brightness", "Color", "Drag",
    "EmissionDirection", "Enabled", "FlipbookFramerate",
    "FlipbookLayout", "FlipbookMode", "FlipbookStartRandom",
    "Lifetime", "LightEmission", "LightInfluence",
    "LockedToPart", "Orientation", "Rate", "RotSpeed",
    "Rotation", "Shape", "ShapeInOut", "ShapeStyle",
    "Size", "Speed", "SpreadAngle", "Squash",
    "Texture", "TimeScale", "Transparency",
    "VelocityInheritance", "WindAffectsDrag", "ZOffset"
}

-- Properties cho Beam
PropertyMap.Beam = {
    "Attachment0", "Attachment1", "Brightness", "Color",
    "CurveSize0", "CurveSize1", "Enabled", "FaceCamera",
    "LightEmission", "LightInfluence", "Segments",
    "Texture", "TextureLength", "TextureMode", "TextureSpeed",
    "Transparency", "Width0", "Width1", "ZOffset"
}

-- Properties cho Trail
PropertyMap.Trail = {
    "Attachment0", "Attachment1", "Brightness", "Color",
    "Enabled", "FaceCamera", "Lifetime", "LightEmission",
    "LightInfluence", "MaxLength", "MinLength",
    "Texture", "TextureLength", "TextureMode",
    "Transparency", "WidthScale"
}

-- Properties cho Sound
PropertyMap.Sound = {
    "EmitterSize", "Looped", "MaxDistance", "PlayOnRemove",
    "PlaybackSpeed", "Playing", "RollOffMaxDistance",
    "RollOffMinDistance", "RollOffMode", "SoundId",
    "TimePosition", "Volume"
}

-- Properties cho Lighting
PropertyMap.Lighting = {
    "Ambient", "Brightness", "ClockTime", "ColorShift_Bottom",
    "ColorShift_Top", "EnvironmentDiffuseScale",
    "EnvironmentSpecularScale", "ExposureCompensation",
    "FogColor", "FogEnd", "FogStart", "GeographicLatitude",
    "GlobalShadows", "OutdoorAmbient", "ShadowSoftness",
    "Technology", "TimeOfDay"
}

-- Properties cho Atmosphere
PropertyMap.Atmosphere = {
    "Color", "Decay", "Density", "Glare", "Haze", "Offset"
}

-- Properties cho Sky
PropertyMap.Sky = {
    "CelestialBodiesShown", "MoonAngularSize", "MoonTextureId",
    "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf",
    "SkyboxRt", "SkyboxUp", "StarCount", "SunAngularSize",
    "SunTextureId"
}

-- Properties cho Clouds
PropertyMap.Clouds = {
    "Color", "Cover", "Density", "Enabled"
}

-- Properties cho PostEffect
PropertyMap.BloomEffect = {"Enabled", "Intensity", "Size", "Threshold"}
PropertyMap.BlurEffect = {"Enabled", "Size"}
PropertyMap.ColorCorrectionEffect = {
    "Brightness", "Contrast", "Enabled", "Saturation", "TintColor"
}
PropertyMap.DepthOfFieldEffect = {
    "Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"
}
PropertyMap.SunRaysEffect = {"Enabled", "Intensity", "Spread"}

-- Properties cho GUI objects
PropertyMap.ScreenGui = {
    "DisplayOrder", "Enabled", "IgnoreGuiInset",
    "ResetOnSpawn", "ZIndexBehavior"
}
PropertyMap.BillboardGui = {
    "Active", "Adornee", "AlwaysOnTop", "Brightness",
    "ClipsDescendants", "Enabled", "ExtentsOffset",
    "ExtentsOffsetWorldSpace", "LightInfluence",
    "MaxDistance", "ResetOnSpawn", "Size", "SizeOffset",
    "StudsOffset", "StudsOffsetWorldSpace", "ZIndexBehavior"
}
PropertyMap.SurfaceGui = {
    "Active", "Adornee", "AlwaysOnTop", "Brightness",
    "CanvasSize", "ClipsDescendants", "Enabled",
    "Face", "LightInfluence", "PixelsPerStud",
    "ResetOnSpawn", "SizingMode", "ZIndexBehavior", "ZOffset"
}
PropertyMap.Frame = {
    "Active", "AnchorPoint", "AutomaticSize",
    "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderMode", "BorderSizePixel",
    "ClipsDescendants", "LayoutOrder", "Position",
    "Rotation", "Size", "SizeConstraint",
    "Visible", "ZIndex"
}
PropertyMap.TextLabel = {
    "Active", "AnchorPoint", "AutomaticSize",
    "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderMode", "BorderSizePixel",
    "ClipsDescendants", "Font", "FontFace",
    "LayoutOrder", "LineHeight", "MaxVisibleGraphemes",
    "Position", "RichText", "Rotation", "Size",
    "SizeConstraint", "Text", "TextColor3",
    "TextScaled", "TextSize", "TextStrokeColor3",
    "TextStrokeTransparency", "TextTransparency",
    "TextTruncate", "TextWrapped", "TextXAlignment",
    "TextYAlignment", "Visible", "ZIndex"
}
PropertyMap.TextButton = {
    "Active", "AnchorPoint", "AutoButtonColor", "AutomaticSize",
    "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderMode", "BorderSizePixel",
    "ClipsDescendants", "Font", "FontFace",
    "LayoutOrder", "LineHeight", "MaxVisibleGraphemes",
    "Modal", "Position", "RichText", "Rotation",
    "Selected", "Size", "SizeConstraint", "Style",
    "Text", "TextColor3", "TextScaled", "TextSize",
    "TextStrokeColor3", "TextStrokeTransparency",
    "TextTransparency", "TextTruncate", "TextWrapped",
    "TextXAlignment", "TextYAlignment", "Visible", "ZIndex"
}
PropertyMap.TextBox = {
    "Active", "AnchorPoint", "AutomaticSize",
    "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderMode", "BorderSizePixel",
    "ClearTextOnFocus", "ClipsDescendants", "Font",
    "FontFace", "LayoutOrder", "LineHeight",
    "MaxVisibleGraphemes", "MultiLine", "PlaceholderColor3",
    "PlaceholderText", "Position", "RichText",
    "Rotation", "ShowNativeInput", "Size",
    "SizeConstraint", "Text", "TextColor3",
    "TextEditable", "TextScaled", "TextSize",
    "TextStrokeColor3", "TextStrokeTransparency",
    "TextTransparency", "TextTruncate", "TextWrapped",
    "TextXAlignment", "TextYAlignment", "Visible", "ZIndex"
}
PropertyMap.ImageLabel = {
    "Active", "AnchorPoint", "AutomaticSize",
    "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderMode", "BorderSizePixel",
    "ClipsDescendants", "Image", "ImageColor3",
    "ImageRectOffset", "ImageRectSize", "ImageTransparency",
    "LayoutOrder", "Position", "Rotation",
    "ScaleType", "Size", "SizeConstraint",
    "SliceCenter", "SliceScale", "TileSize",
    "Visible", "ZIndex"
}
PropertyMap.ImageButton = {
    "Active", "AnchorPoint", "AutoButtonColor", "AutomaticSize",
    "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderMode", "BorderSizePixel",
    "ClipsDescendants", "Image", "ImageColor3",
    "ImageRectOffset", "ImageRectSize", "ImageTransparency",
    "LayoutOrder", "Modal", "Position",
    "Rotation", "ScaleType", "Selected",
    "Size", "SizeConstraint", "SliceCenter",
    "SliceScale", "Style", "TileSize",
    "Visible", "ZIndex"
}
PropertyMap.ViewportFrame = {
    "Active", "Ambient", "AnchorPoint", "AutomaticSize",
    "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderMode", "BorderSizePixel",
    "ClipsDescendants", "ImageColor3", "ImageTransparency",
    "LayoutOrder", "LightColor", "LightDirection",
    "Position", "Rotation", "Size", "SizeConstraint",
    "Visible", "ZIndex"
}
PropertyMap.ScrollingFrame = {
    "Active", "AnchorPoint", "AutomaticCanvasSize",
    "AutomaticSize", "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderMode", "BorderSizePixel",
    "BottomImage", "CanvasPosition", "CanvasSize",
    "ClipsDescendants", "ElasticBehavior",
    "HorizontalScrollBarInset", "LayoutOrder",
    "MidImage", "Position", "Rotation",
    "ScrollBarImageColor3", "ScrollBarImageTransparency",
    "ScrollBarThickness", "ScrollingDirection",
    "ScrollingEnabled", "Size", "SizeConstraint",
    "TopImage", "VerticalScrollBarInset",
    "VerticalScrollBarPosition", "Visible", "ZIndex"
}

-- Layout objects
PropertyMap.UIListLayout = {
    "FillDirection", "HorizontalAlignment", "Padding",
    "SortOrder", "VerticalAlignment", "Wraps"
}
PropertyMap.UIGridLayout = {
    "CellPadding", "CellSize", "FillDirection",
    "FillDirectionMaxCells", "HorizontalAlignment",
    "SortOrder", "StartCorner", "VerticalAlignment"
}
PropertyMap.UITableLayout = {
    "FillDirection", "FillEmptySpaceColumns",
    "FillEmptySpaceRows", "HorizontalAlignment",
    "MajorAxis", "Padding", "SortOrder", "VerticalAlignment"
}
PropertyMap.UIPageLayout = {
    "Animated", "Circular", "EasingDirection", "EasingStyle",
    "FillDirection", "GamepadInputEnabled",
    "HorizontalAlignment", "Padding", "ScrollWheelInputEnabled",
    "SortOrder", "TouchInputEnabled", "TweenTime",
    "VerticalAlignment"
}
PropertyMap.UICorner = {"CornerRadius"}
PropertyMap.UIPadding = {
    "PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"
}
PropertyMap.UIScale = {"Scale"}
PropertyMap.UISizeConstraint = {"MaxSize", "MinSize"}
PropertyMap.UITextSizeConstraint = {"MaxTextSize", "MinTextSize"}
PropertyMap.UIAspectRatioConstraint = {
    "AspectRatio", "AspectType", "DominantAxis"
}
PropertyMap.UIStroke = {
    "ApplyStrokeMode", "Color", "Enabled",
    "LineJoinMode", "Thickness", "Transparency"
}
PropertyMap.UIGradient = {
    "Color", "Enabled", "Offset", "Rotation", "Transparency"
}
PropertyMap.UIFlexItem = {
    "FlexMode", "GrowRatio", "ItemLineAlignment", "ShrinkRatio"
}

-- Humanoid
PropertyMap.Humanoid = {
    "AutoJumpEnabled", "AutoRotate", "AutomaticScalingEnabled",
    "BreakJointsOnDeath", "DisplayDistanceType", "DisplayName",
    "EvaluateStateMachine", "Health", "HealthDisplayDistance",
    "HealthDisplayType", "HipHeight", "JumpHeight",
    "JumpPower", "MaxHealth", "MaxSlopeAngle",
    "NameDisplayDistance", "NameOcclusion",
    "RequiresNeck", "RigType", "UseJumpPower",
    "WalkSpeed"
}

-- HumanoidDescription
PropertyMap.HumanoidDescription = {
    "BackAccessory", "BodyTypeScale", "ClimbAnimation",
    "DepthScale", "Face", "FaceAccessory", "FallAnimation",
    "FrontAccessory", "GraphicTShirt", "HairAccessory",
    "HatAccessory", "Head", "HeadColor", "HeadScale",
    "HeightScale", "IdleAnimation", "JumpAnimation",
    "LeftArm", "LeftArmColor", "LeftLeg", "LeftLegColor",
    "MoodAnimation", "NeckAccessory", "Pants",
    "ProportionScale", "RightArm", "RightArmColor",
    "RightLeg", "RightLegColor", "RunAnimation",
    "Shirt", "ShouldersAccessory", "SwimAnimation",
    "Torso", "TorsoColor", "WaistAccessory",
    "WalkAnimation", "WidthScale"
}

-- BodyMover objects
PropertyMap.BodyForce = {"Force"}
PropertyMap.BodyVelocity = {"MaxForce", "P", "Velocity"}
PropertyMap.BodyPosition = {"D", "MaxForce", "P", "Position"}
PropertyMap.BodyGyro = {"CFrame", "D", "MaxTorque", "P"}
PropertyMap.BodyAngularVelocity = {"AngularVelocity", "MaxTorque", "P"}

-- Linear/AngularVelocity (new constraints)
PropertyMap.LinearVelocity = {
    "Attachment0", "Attachment1", "Enabled", "ForceLimitMode",
    "ForceLimitsEnabled", "LineDirection", "LineVelocity",
    "MaxAxesForce", "MaxForce", "MaxPlanarAxesForce",
    "PlaneVelocity", "PrimaryTangentAxis",
    "RelativeTo", "SecondaryTangentAxis",
    "VectorVelocity", "VelocityConstraintMode"
}
PropertyMap.AngularVelocity = {
    "Attachment0", "Attachment1", "AngularVelocity",
    "Enabled", "MaxTorque", "ReactionTorqueEnabled",
    "RelativeTo"
}

-- Misc objects
PropertyMap.ClickDetector = {"CursorIcon", "MaxActivationDistance"}
PropertyMap.ProximityPrompt = {
    "ActionText", "AutoLocalize", "ClickablePrompt",
    "Enabled", "ExclusivityMode", "GamepadKeyCode",
    "HoldDuration", "KeyboardKeyCode", "MaxActivationDistance",
    "ObjectText", "RequiresLineOfSight", "Style", "UIOffset"
}
PropertyMap.Tool = {
    "CanBeDropped", "Enabled", "Grip", "GripForward",
    "GripPos", "GripRight", "GripUp", "ManualActivationOnly",
    "RequiresHandle", "TextureId", "ToolTip"
}

-- StringValue, NumberValue etc.
PropertyMap.StringValue = {"Value"}
PropertyMap.IntValue = {"Value"}
PropertyMap.NumberValue = {"Value"}
PropertyMap.BoolValue = {"Value"}
PropertyMap.ObjectValue = {"Value"}
PropertyMap.BrickColorValue = {"Value"}
PropertyMap.Color3Value = {"Value"}
PropertyMap.CFrameValue = {"Value"}
PropertyMap.Vector3Value = {"Value"}
PropertyMap.RayValue = {"Value"}

-- Configuration / Folder
PropertyMap.Configuration = {}
PropertyMap.Folder = {}

-- Camera
PropertyMap.Camera = {
    "CFrame", "CameraType", "FieldOfView", "FieldOfViewMode",
    "Focus", "HeadLocked", "HeadScale"
}

-- Mesh objects
PropertyMap.SpecialMesh = {
    "MeshId", "MeshType", "Offset", "Scale", "TextureId", "VertexColor"
}
PropertyMap.BlockMesh = {"Offset", "Scale", "VertexColor"}
PropertyMap.CylinderMesh = {"Offset", "Scale", "VertexColor"}
PropertyMap.FileMesh = {"MeshId", "Offset", "Scale", "TextureId", "VertexColor"}

-- Fire, Smoke, Sparkles
PropertyMap.Fire = {
    "Color", "Enabled", "Heat", "SecondaryColor", "Size", "TimeScale"
}
PropertyMap.Smoke = {
    "Color", "Enabled", "Opacity", "RiseVelocity", "Size", "TimeScale"
}
PropertyMap.Sparkles = {
    "Color", "Enabled", "SparkleColor", "TimeScale"
}

-- Highlight
PropertyMap.Highlight = {
    "Adornee", "DepthMode", "Enabled", "FillColor",
    "FillTransparency", "OutlineColor", "OutlineTransparency"
}

-- SelectionBox, SelectionSphere
PropertyMap.SelectionBox = {
    "Adornee", "Color3", "LineThickness", "SurfaceColor3",
    "SurfaceTransparency", "Transparency", "Visible"
}

-- BoolConstraintValue etc.
PropertyMap.NumberConstraint = {"MaxValue", "MinValue"}

-- Teams
PropertyMap.Team = {"AutoAssignable", "TeamColor"}

-- BindableEvent / Function, RemoteEvent / Function
PropertyMap.BindableEvent = {}
PropertyMap.BindableFunction = {}
PropertyMap.RemoteEvent = {}
PropertyMap.RemoteFunction = {}

-- Animation objects
PropertyMap.Animation = {"AnimationId"}
PropertyMap.AnimationController = {}
PropertyMap.Animator = {}
PropertyMap.KeyframeSequenceProvider = {}

-- PathfindingModifier / Link
PropertyMap.PathfindingModifier = {"Label", "PassThrough"}
PropertyMap.PathfindingLink = {"Attachment0", "Attachment1", "IsBidirectional", "Label"}

-- ═══════════════════════════════════════════════════════════════
-- Lấy danh sách property cho một class
-- ═══════════════════════════════════════════════════════════════

function Serializer.getPropertiesForClass(className)
    local props = {}

    -- Thêm Base properties
    for _, p in ipairs(PropertyMap.Base) do
        table.insert(props, p)
    end

    -- Thêm BasePart properties nếu là BasePart
    local isBasePart = false
    pcall(function()
        isBasePart = game:GetService("Workspace"):FindFirstChildOfClass(className) ~= nil
    end)

    -- Kiểm tra bằng cách tạo instance thử
    local basePartClasses = {
        "Part", "MeshPart", "UnionOperation", "NegateOperation",
        "WedgePart", "CornerWedgePart", "TrussPart", "SpawnLocation",
        "Seat", "VehicleSeat", "SkateboardPlatform", "FlagStand"
    }

    for _, bpClass in ipairs(basePartClasses) do
        if className == bpClass then
            isBasePart = true
            break
        end
    end

    if isBasePart then
        for _, p in ipairs(PropertyMap.BasePart) do
            table.insert(props, p)
        end
    end

    -- Thêm class-specific properties
    if PropertyMap[className] then
        for _, p in ipairs(PropertyMap[className]) do
            table.insert(props, p)
        end
    end

    return props
end

-- ═══════════════════════════════════════════════════════════════
-- Serialize một Instance thành XML
-- ═══════════════════════════════════════════════════════════════

local _refMap = {} -- Map Instance -> Ref ID

function Serializer.serializeInstance(instance, decompiledScripts, depth)
    depth = depth or 0
    if depth > 100 then return "" end -- Giới hạn độ sâu để tránh stack overflow

    local className = instance.ClassName
    local ref = Serializer.newRef()
    _refMap[instance] = ref

    local indent = string.rep("  ", depth)
    local xml = string.format('%s<Item class="%s" referent="%s">\n', indent, className, ref)
    xml = xml .. indent .. "  <Properties>\n"

    -- Lấy properties cho class này
    local props = Serializer.getPropertiesForClass(className)

    -- Serialize từng property
    for _, propName in ipairs(props) do
        local success, value = pcall(function()
            return instance[propName]
        end)

        if success and value ~= nil then
            -- Xử lý đặc biệt cho Source property của scripts
            if propName == "Source" and instance:IsA("LuaSourceContainer") then
                local source = ""
                if decompiledScripts and decompiledScripts[instance] then
                    source = decompiledScripts[instance]
                else
                    pcall(function()
                        source = instance.Source
                    end)
                end
                xml = xml .. indent .. string.format(
                    '    <ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>\n',
                    source or ""
                )
            -- Xử lý ObjectValue references (Part0, Part1, Adornee, etc.)
            elseif typeof(value) == "Instance" then
                -- Sẽ được resolve sau khi serialize xong
                xml = xml .. indent .. string.format(
                    '    <Ref name="%s">null</Ref>\n',
                    Serializer.escapeXml(propName)
                )
            else
                local propXml = Serializer.serializePropertyValue(propName, value)
                if propXml and #propXml > 0 then
                    xml = xml .. indent .. propXml
                end
            end
        end
    end

    -- Serialize Attributes
    pcall(function()
        local attributes = instance:GetAttributes()
        if attributes and next(attributes) then
            xml = xml .. indent .. '    <BinaryString name="AttributesSerialize">'
            -- Attributes được serialize dạng binary, ở đây ta lưu dạng readable
            -- cho compatibility
            xml = xml .. '</BinaryString>\n'

            -- Lưu attributes dạng comment để giữ thông tin
            for attrName, attrValue in pairs(attributes) do
                xml = xml .. indent .. string.format(
                    '    <!-- Attribute: %s = %s (%s) -->\n',
                    Serializer.escapeXml(attrName),
                    Serializer.escapeXml(tostring(attrValue)),
                    typeof(attrValue)
                )
            end
        end
    end)

    -- Serialize Tags
    pcall(function()
        local tags = instance:GetTags()
        if tags and #tags > 0 then
            local tagString = table.concat(tags, "\0")
            xml = xml .. indent .. string.format(
                '    <BinaryString name="Tags">%s</BinaryString>\n',
                Serializer.escapeXml(tagString)
            )
        end
    end)

    xml = xml .. indent .. "  </Properties>\n"

    -- Serialize children
    local children = {}
    pcall(function()
        children = instance:GetChildren()
    end)

    for _, child in ipairs(children) do
        -- Bỏ qua một số instances không cần thiết
        local shouldSkip = false

        -- Bỏ qua player character clones, camera, etc.
        if child:IsA("Player") or child:IsA("PlayerGui") or child:IsA("Backpack") then
            shouldSkip = true
        end

        -- Bỏ qua BaoSaveInstance UI
        if child.Name == "BaoSaveInstance_GUI" then
            shouldSkip = true
        end

        if not shouldSkip then
            local childXml = Serializer.serializeInstance(child, decompiledScripts, depth + 1)
            if childXml and #childXml > 0 then
                xml = xml .. childXml
            end

            -- Yield định kỳ để tránh crash
            if depth == 0 then
                task.wait()
            end
        end
    end

    xml = xml .. indent .. "</Item>\n"
    return xml
end

-- ═══════════════════════════════════════════════════════════════
-- Tạo file RBXL XML hoàn chỉnh
-- ═══════════════════════════════════════════════════════════════

function Serializer.buildRBXL(contentXml)
    local header = '<?xml version="1.0" encoding="utf-8"?>\n'
    header = header .. '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
    header = header .. 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
    header = header .. 'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" '
    header = header .. 'version="4">\n'

    -- Meta information
    header = header .. '  <Meta name="ExplicitAutoJoints">true</Meta>\n'

    local footer = '</roblox>\n'

    return header .. contentXml .. footer
end

-- ═══════════════════════════════════════════════════════════════
-- CORE API FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

-- Khởi tạo module
function BaoSaveInstance.init()
    StatusLog.setStatus("BaoSaveInstance v" .. BaoSaveInstance.Version .. " initialized")

    -- Kiểm tra capabilities
    local saveMethod = ExecutorSupport.detectSaveInstance()
    local decompileMethod = ExecutorSupport.detectDecompiler()
    local hasWrite = ExecutorSupport.hasWriteFile()

    StatusLog.setStatus(string.format(
        "Capabilities: Save=%s | Decompile=%s | WriteFile=%s",
        tostring(saveMethod or "CUSTOM"),
        tostring(decompileMethod or "FALLBACK"),
        tostring(hasWrite)
    ))

    return true
end

-- Decompile tất cả scripts trong game
function BaoSaveInstance.decompileScripts(roots)
    StatusLog.setStatus("Decompile Scripts...")

    local allDecompiled = {}
    local totalCount = 0

    -- Nếu không cung cấp roots, dùng toàn bộ game
    if not roots then
        roots = {
            Workspace,
            ReplicatedStorage,
            ReplicatedFirst,
            StarterGui,
            StarterPack,
            StarterPlayer,
            Lighting,
            SoundService
        }
    end

    for _, root in ipairs(roots) do
        StatusLog.setStatus("Decompiling scripts in: " .. root.Name)
        local decompiledMap, count = Decompiler.decompileAllScripts(root)

        for inst, src in pairs(decompiledMap) do
            allDecompiled[inst] = src
        end
        totalCount = totalCount + count
        task.wait()
    end

    StatusLog.setStatus(string.format("Total scripts decompiled: %d", totalCount))
    return allDecompiled
end

-- Lưu models (serialize tất cả workspace/replicated models)
function BaoSaveInstance.saveModels()
    StatusLog.setStatus("Saving Models...")

    local models = {}

    -- Thu thập từ Workspace
    pcall(function()
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Model") or child:IsA("BasePart") or child:IsA("Folder") then
                table.insert(models, child)
            end
        end
    end)

    -- Thu thập từ ReplicatedStorage
    pcall(function()
        for _, child in ipairs(ReplicatedStorage:GetChildren()) do
            if child:IsA("Model") or child:IsA("BasePart") or child:IsA("Folder") then
                table.insert(models, child)
            end
        end
    end)

    StatusLog.setStatus(string.format("Found %d models", #models))
    return models
end

-- Lưu terrain
function BaoSaveInstance.saveTerrain()
    StatusLog.setStatus("Saving Terrain...")
    local terrainData = TerrainModule.readTerrainData()
    StatusLog.setStatus("Terrain data saved")
    return terrainData
end

-- ═══════════════════════════════════════════════════════════════
-- EXPORT CHÍNH - Tạo và lưu file .rbxl
-- ═══════════════════════════════════════════════════════════════

function BaoSaveInstance.exportRBXL(mode)
    mode = mode or "FULL_GAME"
    local gameName = "UnknownGame"

    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)

    if not gameName or gameName == "" then
        gameName = "Game_" .. tostring(game.PlaceId)
    end

    -- Sanitize tên file
    gameName = gameName:gsub("[^%w%s%-_]", ""):gsub("%s+", "_")
    if #gameName > 50 then
        gameName = gameName:sub(1, 50)
    end

    StatusLog.setStatus(string.format("Export mode: %s | Game: %s", mode, gameName))

    -- ═══════════════════════════════════════════════════════════
    -- PHƯƠNG PHÁP 1: Sử dụng saveinstance native (nếu có)
    -- ═══════════════════════════════════════════════════════════

    local saveMethod = ExecutorSupport.detectSaveInstance()

    if saveMethod and mode ~= "TERRAIN_ONLY" then
        StatusLog.setStatus("Using native saveinstance: " .. saveMethod)

        local fileName = ""
        if mode == "FULL_GAME" then
            fileName = gameName .. "_Full.rbxl"
        elseif mode == "MODEL_ONLY" then
            fileName = gameName .. "_Model.rbxl"
        elseif mode == "TERRAIN_ONLY" then
            fileName = gameName .. "_Terrain.rbxl"
        end

        local options = {
            -- File output
            FilePath = fileName,
            FileName = fileName,

            -- Decompile settings
            DecompileMode = "custom", -- hoặc "full"
            Decompile = true,
            DecompileTimeout = 30,
            DecompileIgnore = {"Chat", "CoreGui", "CorePackages"},

            -- Nội dung cần lưu
            ExtraInstances = {},
            NilInstances = false,
            RemovePlayerCharacters = true,

            -- Script handling
            SavePlayers = false,
            IsolateStarterPlayer = false,
            IgnoreDefaultPlayerScripts = true,

            -- Không chia file
            mode = "full", -- Chế độ full game
            Object = game, -- Đối tượng gốc

            -- Binary format
            Binary = true, -- .rbxl thay vì .rbxlx
        }

        -- Điều chỉnh theo mode
        if mode == "MODEL_ONLY" then
            options.IgnoreList = {
                "Terrain", "Camera", "Players",
                "StarterGui", "StarterPack", "StarterPlayer",
                "Lighting", "SoundService", "Chat",
                "CoreGui", "CorePackages"
            }
        elseif mode == "FULL_GAME" then
            options.IgnoreList = {"CoreGui", "CorePackages"}
        end

        -- Decompile scripts trước
        StatusLog.setStatus("Pre-decompiling scripts...")
        local decompiledMap = BaoSaveInstance.decompileScripts()

        -- Gán source đã decompile
        Decompiler.applyDecompiledSources(decompiledMap)

        -- Thực hiện save
        StatusLog.setStatus("Saving... (this may take a while)")

        local saveSuccess = false

        if saveMethod == "saveinstance" then
            pcall(function()
                saveinstance(options)
                saveSuccess = true
            end)
            -- Thử với đối số đơn giản hơn nếu thất bại
            if not saveSuccess then
                pcall(function()
                    saveinstance(game, fileName)
                    saveSuccess = true
                end)
            end
        elseif saveMethod == "syn.saveinstance" then
            pcall(function()
                syn.saveinstance(game, options)
                saveSuccess = true
            end)
            if not saveSuccess then
                pcall(function()
                    syn.saveinstance(game, fileName)
                    saveSuccess = true
                end)
            end
        elseif saveMethod == "fluxus.saveinstance" then
            pcall(function()
                fluxus.saveinstance(options)
                saveSuccess = true
            end)
        elseif saveMethod == "SaveInstance" then
            pcall(function()
                SaveInstance(options)
                saveSuccess = true
            end)
        end

        if saveSuccess then
            StatusLog.setStatus("Done ✓ - Saved as: " .. fileName)
            return true, fileName
        else
            StatusLog.setStatus("Native save failed, falling back to custom serializer...")
        end
    end

    -- ═══════════════════════════════════════════════════════════
    -- PHƯƠNG PHÁP 2: Custom XML Serializer (Fallback)
    -- ═══════════════════════════════════════════════════════════

    StatusLog.setStatus("Using custom XML serializer...")
    Serializer.resetRefs()
    _refMap = {}

    -- Decompile scripts
    local decompiledScripts = BaoSaveInstance.decompileScripts()

    local contentXml = ""
    local fileName = ""

    if mode == "FULL_GAME" then
        fileName = gameName .. "_Full.rbxl"
        StatusLog.setStatus("Serializing full game...")

        local services = {
            {Workspace, "Workspace"},
            {ReplicatedStorage, "ReplicatedStorage"},
            {ReplicatedFirst, "ReplicatedFirst"},
            {StarterGui, "StarterGui"},
            {StarterPack, "StarterPack"},
            {StarterPlayer, "StarterPlayer"},
            {Lighting, "Lighting"},
            {SoundService, "SoundService"},
        }

        -- Thêm Teams nếu có
        pcall(function()
            if #Teams:GetTeams() > 0 then
                table.insert(services, {Teams, "Teams"})
            end
        end)

        -- Thêm MaterialService nếu có
        pcall(function()
            if MaterialService then
                table.insert(services, {MaterialService, "MaterialService"})
            end
        end)

        for i, serviceInfo in ipairs(services) do
            local service, serviceName = serviceInfo[1], serviceInfo[2]
            StatusLog.setStatus(string.format(
                "Serializing [%d/%d] %s...", i, #services, serviceName
            ))

            pcall(function()
                local serviceXml = Serializer.serializeInstance(service, decompiledScripts, 1)
                contentXml = contentXml .. serviceXml
            end)

            task.wait()
        end

    elseif mode == "MODEL_ONLY" then
        fileName = gameName .. "_Model.rbxl"
        StatusLog.setStatus("Serializing models...")

        -- Serialize Workspace (without Terrain/Camera)
        pcall(function()
            for _, child in ipairs(Workspace:GetChildren()) do
                if not child:IsA("Terrain") and not child:IsA("Camera") then
                    StatusLog.setStatus("Serializing model: " .. child.Name)
                    local childXml = Serializer.serializeInstance(child, decompiledScripts, 1)
                    contentXml = contentXml .. childXml
                    task.wait()
                end
            end
        end)

        -- Serialize ReplicatedStorage
        pcall(function()
            local rsXml = Serializer.serializeInstance(ReplicatedStorage, decompiledScripts, 1)
            contentXml = contentXml .. rsXml
        end)

    elseif mode == "TERRAIN_ONLY" then
        fileName = gameName .. "_Terrain.rbxl"
        StatusLog.setStatus("Serializing terrain...")

        pcall(function()
            local terrain = Workspace.Terrain
            if terrain then
                local terrainXml = Serializer.serializeInstance(terrain, decompiledScripts, 1)
                contentXml = contentXml .. terrainXml
            end
        end)

        -- Thêm terrain properties
        local terrainData = TerrainModule.readTerrainData()
        if terrainData then
            contentXml = contentXml .. "  <!-- Terrain Properties -->\n"
            if terrainData.WaterColor then
                contentXml = contentXml .. string.format(
                    "  <!-- WaterColor: R=%s G=%s B=%s -->\n",
                    tostring(terrainData.WaterColor.R),
                    tostring(terrainData.WaterColor.G),
                    tostring(terrainData.WaterColor.B)
                )
            end
        end
    end

    -- Build file RBXL hoàn chỉnh
    StatusLog.setStatus("Building RBXL file...")
    local rbxlContent = Serializer.buildRBXL(contentXml)

    -- Ghi file
    StatusLog.setStatus("Writing file: " .. fileName)

    if ExecutorSupport.hasWriteFile() then
        local writeSuccess = false
        pcall(function()
            writefile(fileName, rbxlContent)
            writeSuccess = true
        end)

        if writeSuccess then
            local fileSizeMB = #rbxlContent / (1024 * 1024)
            StatusLog.setStatus(string.format(
                "Done ✓ - Saved: %s (%.2f MB)", fileName, fileSizeMB
            ))
            return true, fileName
        else
            StatusLog.setStatus("ERROR: Failed to write file!")
            return false, nil
        end
    else
        -- Không có writefile, thử dùng setclipboard
        StatusLog.setStatus("No writefile available, trying clipboard...")
        pcall(function()
            if setclipboard then
                setclipboard(rbxlContent)
                StatusLog.setStatus("Content copied to clipboard (paste and save as .rbxl)")
            elseif toclipboard then
                toclipboard(rbxlContent)
                StatusLog.setStatus("Content copied to clipboard (paste and save as .rbxl)")
            end
        end)
        return false, nil
    end
end

-- ═══════════════════════════════════════════════════════════════
-- PHƯƠNG PHÁP NÂNG CAO: Sử dụng saveinstance với custom decompile
-- ═══════════════════════════════════════════════════════════════

function BaoSaveInstance.advancedExport(mode)
    mode = mode or "FULL_GAME"
    local gameName = "Game"

    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)

    if not gameName or gameName == "" then
        gameName = "Game_" .. tostring(game.PlaceId)
    end

    gameName = gameName:gsub("[^%w%s%-_]", ""):gsub("%s+", "_")
    if #gameName > 50 then gameName = gameName:sub(1, 50) end

    local fileName
    if mode == "FULL_GAME" then
        fileName = gameName .. "_Full.rbxl"
    elseif mode == "MODEL_ONLY" then
        fileName = gameName .. "_Model.rbxl"
    elseif mode == "TERRAIN_ONLY" then
        fileName = gameName .. "_Terrain.rbxl"
    end

    StatusLog.setStatus("Advanced Export: " .. mode)

    -- Bước 1: Decompile tất cả scripts trước
    StatusLog.setStatus("Step 1: Decompiling all scripts...")
    local allScripts = {}

    local searchLocations = {
        Workspace, ReplicatedStorage, ReplicatedFirst,
        StarterGui, StarterPack, StarterPlayer,
        Lighting, SoundService
    }

    for _, location in ipairs(searchLocations) do
        pcall(function()
            for _, desc in ipairs(location:GetDescendants()) do
                if desc:IsA("LuaSourceContainer") then
                    table.insert(allScripts, desc)
                end
            end
        end)
    end

    -- Thêm nil instances scripts nếu có
    if ExecutorSupport.hasGetNilInstances() then
        pcall(function()
            for _, inst in ipairs(getnilinstances()) do
                if inst:IsA("LuaSourceContainer") then
                    table.insert(allScripts, inst)
                end
            end
        end)
    end

    -- Thêm loaded modules
    if ExecutorSupport.hasGetLoadedModules() then
        pcall(function()
            for _, mod in ipairs(getloadedmodules()) do
                table.insert(allScripts, mod)
            end
        end)
    end

    StatusLog.setStatus(string.format("Found %d scripts, decompiling...", #allScripts))

    local decompiledCount = 0
    for i, scriptInst in ipairs(allScripts) do
        local source = Decompiler.decompileScript(scriptInst)

        -- Gán source ngược lại
        pcall(function()
            scriptInst.Source = source
        end)

        decompiledCount = decompiledCount + 1

        if i % 10 == 0 then
            StatusLog.setStatus(string.format(
                "Decompiling... [%d/%d]", i, #allScripts
            ))
            task.wait()
        end
    end

    StatusLog.setStatus(string.format("Decompiled %d scripts", decompiledCount))

    -- Bước 2: Save instance
    StatusLog.setStatus("Step 2: Saving instance...")

    local saveFunc = nil
    if saveinstance then
        saveFunc = saveinstance
    elseif syn and syn.saveinstance then
        saveFunc = syn.saveinstance
    elseif SaveInstance then
        saveFunc = SaveInstance
    elseif fluxus and fluxus.saveinstance then
        saveFunc = fluxus.saveinstance
    end

    if saveFunc then
        local options = {
            FilePath = fileName,
            FileName = fileName,
            Decompile = true,
            DecompileTimeout = 60,
            NilInstances = ExecutorSupport.hasGetNilInstances(),
            RemovePlayerCharacters = true,
            SavePlayers = false,
            Binary = true, -- .rbxl format
            Object = game,
        }

        -- Adjust options based on mode
        if mode == "MODEL_ONLY" then
            -- Chỉ lưu models, bỏ terrain
            options.IgnoreList = {"Terrain"}
            -- Hoặc chỉ lưu workspace + replicated
            pcall(function()
                local modelsToSave = {}
                for _, child in ipairs(Workspace:GetChildren()) do
                    if not child:IsA("Terrain") and not child:IsA("Camera") then
                        table.insert(modelsToSave, child)
                    end
                end
                for _, child in ipairs(ReplicatedStorage:GetChildren()) do
                    table.insert(modelsToSave, child)
                end
                options.ExtraInstances = modelsToSave
            end)
        elseif mode == "TERRAIN_ONLY" then
            pcall(function()
                options.ExtraInstances = {Workspace.Terrain}
                options.Object = Workspace.Terrain
            end)
        end

        local success, err = pcall(function()
            saveFunc(options)
        end)

        -- Thử fallback nếu options phức tạp gây lỗi
        if not success then
            StatusLog.setStatus("Retrying with simple params...")
            pcall(function()
                saveFunc(game, fileName)
            end)
        end

        StatusLog.setStatus("Done ✓ - File: " .. fileName)
        return true, fileName
    else
        -- Không có saveinstance, dùng custom serializer
        StatusLog.setStatus("No saveinstance found, using custom serializer...")
        return BaoSaveInstance.exportRBXL(mode)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- UI MODULE
-- ═══════════════════════════════════════════════════════════════

local UI = {}

function UI.create()
    -- Xóa GUI cũ nếu có
    pcall(function()
        local existingGui = CoreGui:FindFirstChild("BaoSaveInstance_GUI")
        if existingGui then existingGui:Destroy() end
    end)
    pcall(function()
        if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
            local existingGui = LocalPlayer.PlayerGui:FindFirstChild("BaoSaveInstance_GUI")
            if existingGui then existingGui:Destroy() end
        end
    end)

    -- Tạo ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstance_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999999

    -- Thử đặt vào CoreGui, fallback sang PlayerGui
    local guiParent
    pcall(function()
        if gethui then
            guiParent = gethui()
        elseif get_hidden_gui then
            guiParent = get_hidden_gui()
        else
            guiParent = CoreGui
        end
        screenGui.Parent = guiParent
    end)

    if not screenGui.Parent then
        pcall(function()
            screenGui.Parent = LocalPlayer.PlayerGui
        end)
    end

    -- ═══════════════════════════════════════════════
    -- THEME COLORS
    -- ═══════════════════════════════════════════════

    local Colors = {
        Background = Color3.fromRGB(20, 20, 30),
        Header = Color3.fromRGB(30, 30, 50),
        Button = Color3.fromRGB(45, 45, 70),
        ButtonHover = Color3.fromRGB(60, 60, 95),
        ButtonPress = Color3.fromRGB(35, 35, 55),
        Accent = Color3.fromRGB(100, 130, 255),
        AccentGreen = Color3.fromRGB(80, 200, 120),
        AccentRed = Color3.fromRGB(255, 80, 80),
        AccentYellow = Color3.fromRGB(255, 200, 60),
        Text = Color3.fromRGB(230, 230, 240),
        TextDim = Color3.fromRGB(150, 150, 170),
        Border = Color3.fromRGB(60, 60, 90),
        StatusBg = Color3.fromRGB(15, 15, 25),
    }

    -- ═══════════════════════════════════════════════
    -- MAIN FRAME
    -- ═══════════════════════════════════════════════

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 380, 0, 440)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -220)
    mainFrame.BackgroundColor3 = Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = screenGui

    -- Corner rounding
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    -- Border stroke
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Colors.Border
    mainStroke.Thickness = 1.5
    mainStroke.Transparency = 0.3
    mainStroke.Parent = mainFrame

    -- Drop shadow (fake)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.BackgroundTransparency = 1
    shadow.ImageTransparency = 0.6
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = -1
    shadow.Parent = mainFrame

    -- ═══════════════════════════════════════════════
    -- HEADER
    -- ═══════════════════════════════════════════════

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Colors.Header
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    -- Fix bottom corners of header
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 15)
    headerFix.Position = UDim2.new(0, 0, 1, -15)
    headerFix.BackgroundColor3 = Colors.Header
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔧 BaoSaveInstance v" .. BaoSaveInstance.Version
    titleLabel.TextColor3 = Colors.Text
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    -- Version badge
    local versionBadge = Instance.new("TextLabel")
    versionBadge.Name = "Version"
    versionBadge.Size = UDim2.new(0, 45, 0, 20)
    versionBadge.Position = UDim2.new(1, -100, 0.5, -10)
    versionBadge.BackgroundColor3 = Colors.Accent
    versionBadge.BackgroundTransparency = 0.7
    versionBadge.Text = "v3.0"
    versionBadge.TextColor3 = Colors.Accent
    versionBadge.TextSize = 11
    versionBadge.Font = Enum.Font.GothamBold
    versionBadge.Parent = header

    local versionCorner = Instance.new("UICorner")
    versionCorner.CornerRadius = UDim.new(0, 6)
    versionCorner.Parent = versionBadge

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -43, 0.5, -18)
    closeBtn.BackgroundColor3 = Colors.AccentRed
    closeBtn.BackgroundTransparency = 0.8
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Colors.AccentRed
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn

    -- ═══════════════════════════════════════════════
    -- DRAGGABLE LOGIC
    -- ═══════════════════════════════════════════════

    local dragging = false
    local dragInput
    local dragStart
    local startPos

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- ═══════════════════════════════════════════════
    -- CONTENT AREA
    -- ═══════════════════════════════════════════════

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -30, 1, -130)
    content.Position = UDim2.new(0, 15, 0, 60)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = content

    -- ═══════════════════════════════════════════════
    -- HELPER: Create styled button
    -- ═══════════════════════════════════════════════

    local function createButton(name, text, icon, color, layoutOrder)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 44)
        btn.BackgroundColor3 = color or Colors.Button
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.LayoutOrder = layoutOrder or 0
        btn.Parent = content

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Colors.Border
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.5
        btnStroke.Parent = btn

        -- Icon + Text label
        local btnText = Instance.new("TextLabel")
        btnText.Name = "Label"
        btnText.Size = UDim2.new(1, -20, 1, 0)
        btnText.Position = UDim2.new(0, 10, 0, 0)
        btnText.BackgroundTransparency = 1
        btnText.Text = (icon or "") .. "  " .. text
        btnText.TextColor3 = Colors.Text
        btnText.TextSize = 15
        btnText.Font = Enum.Font.GothamSemibold
        btnText.TextXAlignment = Enum.TextXAlignment.Left
        btnText.Parent = btn

        -- Hover effects
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Colors.ButtonHover
            }):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {
                Color = Colors.Accent,
                Transparency = 0
            }):Play()
        end)

        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = color or Colors.Button
            }):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {
                Color = Colors.Border,
                Transparency = 0.5
            }):Play()
        end)

        btn.MouseButton1Down:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {
                BackgroundColor3 = Colors.ButtonPress
            }):Play()
        end)

        btn.MouseButton1Up:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {
                BackgroundColor3 = Colors.ButtonHover
            }):Play()
        end)

        return btn
    end

    -- ═══════════════════════════════════════════════
    -- INFO LABEL
    -- ═══════════════════════════════════════════════

    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoFrame"
    infoFrame.Size = UDim2.new(1, 0, 0, 30)
    infoFrame.BackgroundTransparency = 1
    infoFrame.LayoutOrder = 0
    infoFrame.Parent = content

    local placeInfo = "Unknown"
    pcall(function()
        placeInfo = string.format("PlaceId: %d | GameId: %d",
            game.PlaceId, game.GameId
        )
    end)

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "Info"
    infoLabel.Size = UDim2.new(1, 0, 1, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "📋 " .. placeInfo
    infoLabel.TextColor3 = Colors.TextDim
    infoLabel.TextSize = 11
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextTruncate = Enum.TextTruncate.AtEnd
    infoLabel.Parent = infoFrame

    -- ═══════════════════════════════════════════════
    -- BUTTONS
    -- ═══════════════════════════════════════════════

    local btnFullGame = createButton("BtnFullGame", "Decompile Full Game", "🎮", nil, 1)
    local btnFullModel = createButton("BtnFullModel", "Decompile Full Model", "🏗️", nil, 2)
    local btnTerrain = createButton("BtnTerrain", "Decompile Terrain", "🌍", nil, 3)

    -- Separator
    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(0.9, 0, 0, 1)
    separator.BackgroundColor3 = Colors.Border
    separator.BackgroundTransparency = 0.5
    separator.BorderSizePixel = 0
    separator.LayoutOrder = 4
    separator.Parent = content

    local btnSave = createButton("BtnSave", "Save To .rbxl (Auto Detect)", "💾", Color3.fromRGB(30, 60, 45), 5)
    local btnExit = createButton("BtnExit", "Exit", "❌", Color3.fromRGB(60, 30, 30), 6)

    -- ═══════════════════════════════════════════════
    -- STATUS BAR
    -- ═══════════════════════════════════════════════

    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(1, -30, 0, 50)
    statusFrame.Position = UDim2.new(0, 15, 1, -65)
    statusFrame.BackgroundColor3 = Colors.StatusBg
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = mainFrame

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusFrame

    local statusStroke = Instance.new("UIStroke")
    statusStroke.Color = Colors.Border
    statusStroke.Thickness = 1
    statusStroke.Transparency = 0.6
    statusStroke.Parent = statusFrame

    -- Status icon (animated dot)
    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(0, 10, 0.5, -4)
    statusDot.BackgroundColor3 = Colors.AccentGreen
    statusDot.BorderSizePixel = 0
    statusDot.Parent = statusFrame

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = statusDot

    -- Status text
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusText"
    statusLabel.Size = UDim2.new(1, -30, 1, 0)
    statusLabel.Position = UDim2.new(0, 25, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Ready"
    statusLabel.TextColor3 = Colors.TextDim
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
    statusLabel.Parent = statusFrame

    -- Progress bar
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBg"
    progressBg.Size = UDim2.new(1, -20, 0, 3)
    progressBg.Position = UDim2.new(0, 10, 1, -8)
    progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = statusFrame

    local progressCornerBg = Instance.new("UICorner")
    progressCornerBg.CornerRadius = UDim.new(1, 0)
    progressCornerBg.Parent = progressBg

    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Colors.Accent
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(1, 0)
    progressCorner.Parent = progressBar

    -- ═══════════════════════════════════════════════
    -- UI UPDATE FUNCTIONS
    -- ═══════════════════════════════════════════════

    local isRunning = false

    local function updateStatus(text)
        statusLabel.Text = text

        -- Cập nhật màu dot và progress dựa trên nội dung
        if text:find("Done") or text:find("✓") then
            statusDot.BackgroundColor3 = Colors.AccentGreen
            TweenService:Create(progressBar, TweenInfo.new(0.3), {
                Size = UDim2.new(1, 0, 1, 0)
            }):Play()
            TweenService:Create(progressBar, TweenInfo.new(0.3), {
                BackgroundColor3 = Colors.AccentGreen
            }):Play()
            isRunning = false
        elseif text:find("ERROR") or text:find("Failed") then
            statusDot.BackgroundColor3 = Colors.AccentRed
            TweenService:Create(progressBar, TweenInfo.new(0.3), {
                BackgroundColor3 = Colors.AccentRed
            }):Play()
            isRunning = false
        elseif text:find("Saving") or text:find("Decompil") or text:find("Serializ") then
            statusDot.BackgroundColor3 = Colors.AccentYellow
            progressBar.BackgroundColor3 = Colors.Accent

            -- Animate progress bar indeterminate
            if not isRunning then
                isRunning = true
                task.spawn(function()
                    while isRunning do
                        TweenService:Create(progressBar, TweenInfo.new(1), {
                            Size = UDim2.new(0.7, 0, 1, 0),
                            Position = UDim2.new(0.15, 0, 0, 0)
                        }):Play()
                        task.wait(1)
                        if not isRunning then break end
                        TweenService:Create(progressBar, TweenInfo.new(1), {
                            Size = UDim2.new(0.3, 0, 1, 0),
                            Position = UDim2.new(0.6, 0, 0, 0)
                        }):Play()
                        task.wait(1)
                        if not isRunning then break end
                        TweenService:Create(progressBar, TweenInfo.new(1), {
                            Size = UDim2.new(0.5, 0, 1, 0),
                            Position = UDim2.new(0, 0, 0, 0)
                        }):Play()
                        task.wait(1)
                    end
                end)
            end
        end
    end

    -- Kết nối callback
    BaoSaveInstance.StatusCallback = updateStatus

    local function setButtonsEnabled(enabled)
        local buttons = {btnFullGame, btnFullModel, btnTerrain, btnSave}
        for _, btn in ipairs(buttons) do
            btn.Active = enabled
            if enabled then
                btn.BackgroundTransparency = 0
            else
                btn.BackgroundTransparency = 0.5
            end
        end
    end

    local function runTask(taskName, taskFunc)
        if isRunning then
            updateStatus("⚠️ Already running a task, please wait...")
            return
        end

        task.spawn(function()
            setButtonsEnabled(false)
            progressBar.Size = UDim2.new(0, 0, 1, 0)
            progressBar.Position = UDim2.new(0, 0, 0, 0)

            local success, err = pcall(taskFunc)

            if not success then
                updateStatus("ERROR: " .. tostring(err))
            end

            isRunning = false
            setButtonsEnabled(true)
        end)
    end

    -- ═══════════════════════════════════════════════
    -- BUTTON CALLBACKS
    -- ═══════════════════════════════════════════════

    btnFullGame.MouseButton1Click:Connect(function()
        runTask("Full Game", function()
            BaoSaveInstance.advancedExport("FULL_GAME")
        end)
    end)

    btnFullModel.MouseButton1Click:Connect(function()
        runTask("Full Model", function()
            BaoSaveInstance.advancedExport("MODEL_ONLY")
        end)
    end)

    btnTerrain.MouseButton1Click:Connect(function()
        runTask("Terrain", function()
            BaoSaveInstance.advancedExport("TERRAIN_ONLY")
        end)
    end)

    btnSave.MouseButton1Click:Connect(function()
        runTask("Auto Save", function()
            -- Tự động detect phương pháp tốt nhất
            local saveMethod = ExecutorSupport.detectSaveInstance()
            if saveMethod then
                updateStatus("Detected: " .. saveMethod)
                BaoSaveInstance.advancedExport("FULL_GAME")
            else
                updateStatus("No native saveinstance, using custom...")
                BaoSaveInstance.exportRBXL("FULL_GAME")
            end
        end)
    end)

    -- Exit button
    closeBtn.MouseButton1Click:Connect(function()
        -- Animate close
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        task.wait(0.35)
        screenGui:Destroy()
    end)

    btnExit.MouseButton1Click:Connect(function()
        -- Animate close
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        task.wait(0.35)
        screenGui:Destroy()
    end)

    -- ═══════════════════════════════════════════════
    -- OPEN ANIMATION
    -- ═══════════════════════════════════════════════

    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundTransparency = 1

    task.wait(0.1)

    TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 380, 0, 440),
        Position = UDim2.new(0.5, -190, 0.5, -220),
        BackgroundTransparency = 0
    }):Play()

    -- ═══════════════════════════════════════════════
    -- KEYBIND: Toggle visibility with RightControl
    -- ═══════════════════════════════════════════════

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)

    updateStatus("Ready - Press RightCtrl to toggle")

    return screenGui
end

-- ═══════════════════════════════════════════════════════════════
-- KHỞI CHẠY
-- ═══════════════════════════════════════════════════════════════

-- Initialize API
BaoSaveInstance.init()

-- Tạo UI
UI.create()

-- Thông báo khởi động
local capabilities = {}
if ExecutorSupport.detectSaveInstance() then
    table.insert(capabilities, "SaveInstance: ✓")
else
    table.insert(capabilities, "SaveInstance: ✗ (custom)")
end
if ExecutorSupport.detectDecompiler() then
    table.insert(capabilities, "Decompiler: ✓")
else
    table.insert(capabilities, "Decompiler: ✗ (fallback)")
end
if ExecutorSupport.hasWriteFile() then
    table.insert(capabilities, "WriteFile: ✓")
else
    table.insert(capabilities, "WriteFile: ✗")
end

print("╔══════════════════════════════════════════╗")
print("║     BaoSaveInstance v3.0 Loaded!         ║")
print("║     Press RightCtrl to toggle UI         ║")
print("╠══════════════════════════════════════════╣")
for _, cap in ipairs(capabilities) do
    print("║  " .. cap .. string.rep(" ", 40 - #cap - 2) .. "║")
end
print("╚══════════════════════════════════════════╝")

return BaoSaveInstance
