--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                    BaoSaveInstance v2.0                      ║
    ║         Advanced Roblox Game Decompiler & Exporter          ║
    ║                                                              ║
    ║  Features:                                                   ║
    ║  • Full Game Decompile → single .rbxl                       ║
    ║  • Full Model Decompile → single .rbxl                      ║
    ║  • Terrain Export → single .rbxl                            ║
    ║  • Draggable UI with status indicators                      ║
    ║  • Modular API architecture                                  ║
    ╚══════════════════════════════════════════════════════════════╝
--]]

-- ============================================================
-- SECTION 0: ENVIRONMENT CHECK & POLYFILLS
-- ============================================================

-- Kiểm tra executor environment
local function checkEnvironment()
    local required = {
        "writefile", "readfile", "isfile", "game"
    }
    local missing = {}
    for _, fn in ipairs(required) do
        if not getfenv()[fn] and not getgenv()[fn] and not _G[fn] then
            table.insert(missing, fn)
        end
    end
    return #missing == 0, missing
end

-- ============================================================
-- SECTION 1: BaoSaveInstance MODULE / API
-- ============================================================

local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance
BaoSaveInstance._VERSION = "2.0.0"
BaoSaveInstance._NAME = "BaoSaveInstance"

-- Trạng thái nội bộ
BaoSaveInstance._state = {
    initialized = false,
    busy = false,
    currentMode = nil,
    progress = 0,
    statusText = "Idle",
    scriptCache = {},       -- Cache decompiled scripts
    errorLog = {},          -- Log lỗi
    stats = {
        totalInstances = 0,
        scriptsDecompiled = 0,
        modelsProcessed = 0,
        terrainRegions = 0,
        fileSize = 0
    }
}

-- Cấu hình mặc định
BaoSaveInstance._config = {
    -- Decompile settings
    decompileScripts = true,         -- Có decompile scripts không
    decompileTimeout = 10,           -- Timeout cho mỗi script (giây)
    preserveDisabled = true,         -- Giữ scripts đã disabled
    
    -- Save settings
    savePlayers = false,             -- Không lưu player instances
    saveCamera = false,              -- Không lưu camera
    removePlayerCharacters = true,   -- Xóa character khỏi workspace khi save
    
    -- Terrain settings
    terrainChunkSize = 64,           -- Kích thước chunk khi đọc terrain
    saveTerrainColors = true,        -- Lưu màu terrain custom
    
    -- Performance
    yieldInterval = 50,              -- Yield sau mỗi N instances
    maxRetries = 3,                  -- Số lần retry khi lỗi
    
    -- Output
    outputFolder = "BaoSaveInstance", -- Thư mục output
    fileExtension = ".rbxl",          -- Extension file
    
    -- Services to save (Full Game mode)
    fullGameServices = {
        "Workspace",
        "Lighting",
        "ReplicatedFirst",
        "ReplicatedStorage",
        "ServerStorage",        -- Có thể không truy cập được từ client
        "ServerScriptService",  -- Có thể không truy cập được từ client
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
        "SoundService",
        "Chat",
        "LocalizationService",
        "TestService",
        "Teams"
    },
    
    -- Services cho Model mode
    modelServices = {
        "Workspace",
        "ReplicatedStorage",
        "ReplicatedFirst",
        "Lighting"
    },
    
    -- Class bị loại trừ
    excludedClasses = {
        "Player",
        "PlayerGui",
        "Backpack",
        "PlayerScripts",
        "StatsItem"
    },
    
    -- Instance bị loại trừ theo tên
    excludedNames = {
        "BaoSaveInstance_GUI"  -- Không lưu chính UI tool
    }
}

-- Roblox Services cache
local Services = {}

-- ============================================================
-- SECTION 2: UTILITY FUNCTIONS
-- ============================================================

local Util = {}

--- Lấy service an toàn, không error nếu không tồn tại
function Util.getService(serviceName)
    if Services[serviceName] then
        return Services[serviceName]
    end
    local ok, service = pcall(function()
        return game:GetService(serviceName)
    end)
    if ok and service then
        Services[serviceName] = service
        return service
    end
    return nil
end

--- Sanitize tên file (loại bỏ ký tự không hợp lệ)
function Util.sanitizeFileName(name)
    if not name or name == "" then
        return "Unknown"
    end
    -- Loại bỏ ký tự không hợp lệ cho tên file
    local sanitized = name:gsub("[^%w%s%-_%.%(%)%[%]]", "")
    sanitized = sanitized:gsub("%s+", "_")
    if #sanitized == 0 then
        sanitized = "Unknown"
    end
    -- Giới hạn độ dài
    if #sanitized > 100 then
        sanitized = sanitized:sub(1, 100)
    end
    return sanitized
end

--- Lấy tên game hiện tại
function Util.getGameName()
    local marketplaceService = Util.getService("MarketplaceService")
    local placeId = game.PlaceId
    
    local gameName = "UnknownGame"
    
    -- Thử lấy tên từ MarketplaceService
    local ok, info = pcall(function()
        return marketplaceService:GetProductInfo(placeId)
    end)
    
    if ok and info and info.Name then
        gameName = info.Name
    else
        -- Fallback: dùng PlaceId
        gameName = "Game_" .. tostring(placeId)
    end
    
    return Util.sanitizeFileName(gameName)
end

--- Format số byte thành dạng đọc được
function Util.formatBytes(bytes)
    if bytes < 1024 then
        return string.format("%d B", bytes)
    elseif bytes < 1024 * 1024 then
        return string.format("%.1f KB", bytes / 1024)
    elseif bytes < 1024 * 1024 * 1024 then
        return string.format("%.1f MB", bytes / (1024 * 1024))
    else
        return string.format("%.2f GB", bytes / (1024 * 1024 * 1024))
    end
end

--- Yield thông minh - tránh crash khi xử lý nhiều instance
function Util.smartYield(counter, interval)
    if counter % (interval or BaoSaveInstance._config.yieldInterval) == 0 then
        task.wait()
        -- Kiểm tra heartbeat để đảm bảo không freeze
        if game:GetService("RunService").Heartbeat then
            game:GetService("RunService").Heartbeat:Wait()
        end
    end
end

--- Deep clone table
function Util.deepClone(original)
    local clone = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            clone[key] = Util.deepClone(value)
        else
            clone[key] = value
        end
    end
    return clone
end

--- Log error an toàn
function Util.logError(context, err)
    local entry = {
        time = os.time(),
        context = context,
        message = tostring(err)
    }
    table.insert(BaoSaveInstance._state.errorLog, entry)
    warn("[BaoSaveInstance ERROR] [" .. context .. "] " .. tostring(err))
end

--- Log info
function Util.logInfo(msg)
    print("[BaoSaveInstance] " .. tostring(msg))
end

--- Kiểm tra instance có bị loại trừ không
function Util.isExcluded(instance)
    if not instance then return true end
    
    -- Kiểm tra class
    for _, className in ipairs(BaoSaveInstance._config.excludedClasses) do
        if instance:IsA(className) then
            return true
        end
    end
    
    -- Kiểm tra tên
    for _, name in ipairs(BaoSaveInstance._config.excludedNames) do
        if instance.Name == name then
            return true
        end
    end
    
    return false
end

--- Đếm tất cả descendants
function Util.countDescendants(instance)
    local count = 0
    local ok, descendants = pcall(function()
        return instance:GetDescendants()
    end)
    if ok and descendants then
        count = #descendants
    end
    return count
end

-- ============================================================
-- SECTION 3: XML/RBXL SERIALIZER ENGINE
-- ============================================================

local Serializer = {}

--- Bảng ánh xạ Roblox type → XML type name
Serializer.typeMap = {
    ["string"] = "string",
    ["boolean"] = "bool",
    ["number"] = "double",
    ["BrickColor"] = "BrickColor",
    ["Color3"] = "Color3",
    ["Vector3"] = "Vector3",
    ["Vector2"] = "Vector2",
    ["CFrame"] = "CoordinateFrame",
    ["UDim"] = "UDim",
    ["UDim2"] = "UDim2",
    ["Rect"] = "Rect2D",
    ["PhysicalProperties"] = "PhysicalProperties",
    ["NumberSequence"] = "NumberSequence",
    ["ColorSequence"] = "ColorSequence",
    ["NumberRange"] = "NumberRange",
    ["Faces"] = "Faces",
    ["Axes"] = "Axes",
    ["Ray"] = "Ray",
    ["Enum"] = "token",
    ["Instance"] = "Ref",
    ["Font"] = "Font",
    ["Content"] = "Content"
}

--- ID counter cho referent
Serializer._refCounter = 0
Serializer._refMap = {}   -- Instance → referent ID

--- Lấy hoặc tạo referent ID cho instance
function Serializer.getRef(instance)
    if Serializer._refMap[instance] then
        return Serializer._refMap[instance]
    end
    Serializer._refCounter = Serializer._refCounter + 1
    local ref = "RBX" .. tostring(Serializer._refCounter)
    Serializer._refMap[instance] = ref
    return ref
end

--- Reset serializer state
function Serializer.reset()
    Serializer._refCounter = 0
    Serializer._refMap = {}
end

--- Escape XML special characters
function Serializer.escapeXml(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    str = str:gsub("&", "&amp;")
    str = str:gsub("<", "&lt;")
    str = str:gsub(">", "&gt;")
    str = str:gsub('"', "&quot;")
    str = str:gsub("'", "&apos;")
    -- Xóa ký tự control không hợp lệ trong XML
    str = str:gsub("[\0-\8\11\12\14-\31]", "")
    return str
end

--- Serialize Color3 thành XML
function Serializer.serializeColor3(color)
    return string.format(
        "<R>%f</R><G>%f</G><B>%f</B>",
        color.R, color.G, color.B
    )
end

--- Serialize Vector3 thành XML
function Serializer.serializeVector3(vec)
    return string.format(
        "<X>%f</X><Y>%f</Y><Z>%f</Z>",
        vec.X, vec.Y, vec.Z
    )
end

--- Serialize Vector2 thành XML
function Serializer.serializeVector2(vec)
    return string.format(
        "<X>%f</X><Y>%f</Y>",
        vec.X, vec.Y
    )
end

--- Serialize CFrame thành XML
function Serializer.serializeCFrame(cf)
    local components = {cf:GetComponents()} -- x,y,z, R00,R01,R02, R10,R11,R12, R20,R21,R22
    local xml = {}
    table.insert(xml, string.format("<X>%f</X>", components[1]))
    table.insert(xml, string.format("<Y>%f</Y>", components[2]))
    table.insert(xml, string.format("<Z>%f</Z>", components[3]))
    table.insert(xml, string.format("<R00>%f</R00>", components[4]))
    table.insert(xml, string.format("<R01>%f</R01>", components[5]))
    table.insert(xml, string.format("<R02>%f</R02>", components[6]))
    table.insert(xml, string.format("<R10>%f</R10>", components[7]))
    table.insert(xml, string.format("<R11>%f</R11>", components[8]))
    table.insert(xml, string.format("<R12>%f</R12>", components[9]))
    table.insert(xml, string.format("<R20>%f</R20>", components[10]))
    table.insert(xml, string.format("<R21>%f</R21>", components[11]))
    table.insert(xml, string.format("<R22>%f</R22>", components[12]))
    return table.concat(xml, "")
end

--- Serialize UDim2 thành XML  
function Serializer.serializeUDim2(udim2)
    return string.format(
        "<XS>%f</XS><XO>%d</XO><YS>%f</YS><YO>%d</YO>",
        udim2.X.Scale, udim2.X.Offset, udim2.Y.Scale, udim2.Y.Offset
    )
end

--- Serialize UDim thành XML
function Serializer.serializeUDim(udim)
    return string.format(
        "<S>%f</S><O>%d</O>",
        udim.Scale, udim.Offset
    )
end

--- Serialize NumberSequence thành XML
function Serializer.serializeNumberSequence(ns)
    local parts = {}
    for _, keypoint in ipairs(ns.Keypoints) do
        table.insert(parts, string.format("%f %f %f", keypoint.Time, keypoint.Value, keypoint.Envelope))
    end
    return table.concat(parts, " ")
end

--- Serialize ColorSequence thành XML
function Serializer.serializeColorSequence(cs)
    local parts = {}
    for _, keypoint in ipairs(cs.Keypoints) do
        table.insert(parts, string.format(
            "%f %f %f %f 0",
            keypoint.Time, keypoint.Value.R, keypoint.Value.G, keypoint.Value.B
        ))
    end
    return table.concat(parts, " ")
end

--- Serialize NumberRange thành XML
function Serializer.serializeNumberRange(nr)
    return string.format("%f %f", nr.Min, nr.Max)
end

--- Serialize Rect thành XML
function Serializer.serializeRect(rect)
    return string.format(
        "<min><X>%f</X><Y>%f</Y></min><max><X>%f</X><Y>%f</Y></max>",
        rect.Min.X, rect.Min.Y, rect.Max.X, rect.Max.Y
    )
end

--- Serialize PhysicalProperties thành XML
function Serializer.serializePhysicalProperties(pp)
    if pp then
        return string.format(
            "<CustomPhysics>true</CustomPhysics><Density>%f</Density><Friction>%f</Friction><Elasticity>%f</Elasticity><FrictionWeight>%f</FrictionWeight><ElasticityWeight>%f</ElasticityWeight>",
            pp.Density, pp.Friction, pp.Elasticity, pp.FrictionWeight, pp.ElasticityWeight
        )
    else
        return "<CustomPhysics>false</CustomPhysics>"
    end
end

--- Serialize Faces thành XML
function Serializer.serializeFaces(faces)
    local val = 0
    if faces.Top then val = val + 1 end
    if faces.Bottom then val = val + 2 end
    if faces.Left then val = val + 4 end
    if faces.Right then val = val + 8 end
    if faces.Back then val = val + 16 end
    if faces.Front then val = val + 32 end
    return tostring(val)
end

--- Serialize Axes thành XML
function Serializer.serializeAxes(axes)
    local val = 0
    if axes.X then val = val + 1 end
    if axes.Y then val = val + 2 end
    if axes.Z then val = val + 4 end
    return tostring(val)
end

--- Serialize Font thành XML
function Serializer.serializeFont(font)
    return string.format(
        "<Family><url>%s</url></Family><Weight>%d</Weight><Style>%s</Style>",
        Serializer.escapeXml(tostring(font.Family)),
        font.Weight.Value,
        tostring(font.Style)
    )
end

--- Serialize một property value bất kỳ thành XML string
function Serializer.serializePropertyValue(propName, value, propType)
    if value == nil then return nil end
    
    local valueType = typeof(value)
    local xml = {}
    
    -- Xử lý theo type
    if valueType == "string" then
        table.insert(xml, string.format('<string name="%s">%s</string>', propName, Serializer.escapeXml(value)))
        
    elseif valueType == "boolean" then
        table.insert(xml, string.format('<bool name="%s">%s</bool>', propName, tostring(value)))
        
    elseif valueType == "number" then
        -- Phân biệt int vs float
        if value == math.floor(value) and math.abs(value) < 2147483647 then
            table.insert(xml, string.format('<int name="%s">%d</int>', propName, value))
        else
            table.insert(xml, string.format('<double name="%s">%f</double>', propName, value))
        end
        
    elseif valueType == "float" then
        table.insert(xml, string.format('<float name="%s">%f</float>', propName, value))
        
    elseif valueType == "BrickColor" then
        table.insert(xml, string.format('<int name="%s">%d</int>', propName, value.Number))
        
    elseif valueType == "Color3" then
        table.insert(xml, string.format('<Color3 name="%s">%s</Color3>', propName, Serializer.serializeColor3(value)))
        
    elseif valueType == "Vector3" then
        table.insert(xml, string.format('<Vector3 name="%s">%s</Vector3>', propName, Serializer.serializeVector3(value)))
        
    elseif valueType == "Vector2" then
        table.insert(xml, string.format('<Vector2 name="%s">%s</Vector2>', propName, Serializer.serializeVector2(value)))
        
    elseif valueType == "CFrame" then
        table.insert(xml, string.format('<CoordinateFrame name="%s">%s</CoordinateFrame>', propName, Serializer.serializeCFrame(value)))
        
    elseif valueType == "UDim2" then
        table.insert(xml, string.format('<UDim2 name="%s">%s</UDim2>', propName, Serializer.serializeUDim2(value)))
        
    elseif valueType == "UDim" then
        table.insert(xml, string.format('<UDim name="%s">%s</UDim>', propName, Serializer.serializeUDim(value)))
        
    elseif valueType == "Rect" then
        table.insert(xml, string.format('<Rect2D name="%s">%s</Rect2D>', propName, Serializer.serializeRect(value)))
        
    elseif valueType == "NumberSequence" then
        table.insert(xml, string.format('<NumberSequence name="%s">%s</NumberSequence>', propName, Serializer.serializeNumberSequence(value)))
        
    elseif valueType == "ColorSequence" then
        table.insert(xml, string.format('<ColorSequence name="%s">%s</ColorSequence>', propName, Serializer.serializeColorSequence(value)))
        
    elseif valueType == "NumberRange" then
        table.insert(xml, string.format('<NumberRange name="%s">%s</NumberRange>', propName, Serializer.serializeNumberRange(value)))
        
    elseif valueType == "PhysicalProperties" then
        table.insert(xml, string.format('<PhysicalProperties name="%s">%s</PhysicalProperties>', propName, Serializer.serializePhysicalProperties(value)))
        
    elseif valueType == "Faces" then
        table.insert(xml, string.format('<Faces name="%s">%s</Faces>', propName, Serializer.serializeFaces(value)))
        
    elseif valueType == "Axes" then
        table.insert(xml, string.format('<Axes name="%s">%s</Axes>', propName, Serializer.serializeAxes(value)))
        
    elseif valueType == "EnumItem" then
        table.insert(xml, string.format('<token name="%s">%d</token>', propName, value.Value))
        
    elseif valueType == "Instance" then
        -- Reference đến instance khác
        local ref = Serializer.getRef(value)
        table.insert(xml, string.format('<Ref name="%s">%s</Ref>', propName, ref))
        
    elseif valueType == "Font" then
        table.insert(xml, string.format('<Font name="%s">%s</Font>', propName, Serializer.serializeFont(value)))
        
    elseif valueType == "Content" or valueType == "string" then
        table.insert(xml, string.format('<Content name="%s"><url>%s</url></Content>', propName, Serializer.escapeXml(tostring(value))))
        
    else
        -- Fallback: serialize as string
        local strVal = tostring(value)
        if strVal and strVal ~= "" then
            table.insert(xml, string.format('<string name="%s">%s</string>', propName, Serializer.escapeXml(strVal)))
        end
    end
    
    if #xml > 0 then
        return table.concat(xml, "")
    end
    return nil
end

-- ============================================================
-- SECTION 4: PROPERTY DATABASE
-- Danh sách properties cho các class phổ biến
-- ============================================================

local PropertyDB = {}

-- Base properties cho mọi Instance
PropertyDB.Instance = {
    "Name", "Archivable"
}

-- BasePart properties
PropertyDB.BasePart = {
    "Name", "Anchored", "BrickColor", "CanCollide", "CanTouch", "CanQuery",
    "CastShadow", "Color", "CustomPhysicalProperties",
    "CFrame", "Size", "Position", "Orientation", "Rotation",
    "Material", "MaterialVariant", "Reflectance", "Transparency",
    "Shape", "TopSurface", "BottomSurface", "LeftSurface", "RightSurface",
    "FrontSurface", "BackSurface", "Locked", "Massless",
    "RootPriority", "CollisionGroup"
}

-- MeshPart specific
PropertyDB.MeshPart = {
    "MeshId", "TextureID", "CollisionFidelity", "RenderFidelity",
    "DoubleSided"
}

-- Part specific
PropertyDB.Part = {
    "Shape"
}

-- UnionOperation
PropertyDB.UnionOperation = {
    "UsePartColor", "CollisionFidelity", "RenderFidelity",
    "SmoothingAngle"
}

-- Model
PropertyDB.Model = {
    "Name", "PrimaryPart", "WorldPivot", "LevelOfDetail",
    "ModelStreamingMode"
}

-- Script types
PropertyDB.LuaSourceContainer = {
    "Name", "Disabled", "LinkedSource"
}

-- SpawnLocation
PropertyDB.SpawnLocation = {
    "AllowTeamChangeOnTouch", "Duration", "Enabled", "Neutral", "TeamColor"
}

-- Decal / Texture
PropertyDB.Decal = {
    "Name", "Color3", "Face", "Texture", "Transparency", "ZIndex"
}

PropertyDB.Texture = {
    "Name", "Color3", "Face", "Texture", "Transparency", "ZIndex",
    "OffsetStudsU", "OffsetStudsV", "StudsPerTileU", "StudsPerTileV"
}

-- Light types
PropertyDB.Light = {
    "Name", "Brightness", "Color", "Enabled", "Shadows"
}

PropertyDB.PointLight = {
    "Range"
}

PropertyDB.SpotLight = {
    "Angle", "Face", "Range"
}

PropertyDB.SurfaceLight = {
    "Angle", "Face", "Range"
}

-- Attachment
PropertyDB.Attachment = {
    "Name", "CFrame", "Visible", "WorldCFrame"
}

-- Constraints
PropertyDB.Constraint = {
    "Name", "Attachment0", "Attachment1", "Color", "Enabled", "Visible"
}

-- Weld
PropertyDB.Weld = {
    "Name", "Part0", "Part1", "C0", "C1", "Enabled"
}

-- WeldConstraint
PropertyDB.WeldConstraint = {
    "Name", "Part0", "Part1", "Enabled"
}

-- Motor6D
PropertyDB.Motor6D = {
    "Name", "Part0", "Part1", "C0", "C1", "Enabled",
    "CurrentAngle", "DesiredAngle", "MaxVelocity"
}

-- GUI elements
PropertyDB.ScreenGui = {
    "Name", "DisplayOrder", "Enabled", "IgnoreGuiInset", "ResetOnSpawn",
    "ZIndexBehavior"
}

PropertyDB.Frame = {
    "Name", "Active", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants",
    "LayoutOrder", "Position", "Rotation", "Size", "SizeConstraint",
    "Visible", "ZIndex"
}

PropertyDB.TextLabel = {
    "Name", "Active", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderSizePixel", "Font", "FontFace",
    "LayoutOrder", "Position", "RichText", "Rotation", "Size",
    "Text", "TextColor3", "TextScaled", "TextSize",
    "TextStrokeColor3", "TextStrokeTransparency", "TextTransparency",
    "TextWrapped", "TextXAlignment", "TextYAlignment",
    "Visible", "ZIndex"
}

PropertyDB.TextButton = {
    "Name", "Active", "AnchorPoint", "AutoButtonColor",
    "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderSizePixel", "Font", "FontFace",
    "LayoutOrder", "Position", "RichText", "Rotation", "Size",
    "Text", "TextColor3", "TextScaled", "TextSize",
    "TextStrokeColor3", "TextStrokeTransparency", "TextTransparency",
    "TextWrapped", "TextXAlignment", "TextYAlignment",
    "Visible", "ZIndex"
}

PropertyDB.ImageLabel = {
    "Name", "Active", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderSizePixel", "Image", "ImageColor3",
    "ImageRectOffset", "ImageRectSize", "ImageTransparency",
    "LayoutOrder", "Position", "Rotation", "ScaleType", "Size",
    "SliceCenter", "SliceScale", "TileSize",
    "Visible", "ZIndex"
}

PropertyDB.ImageButton = {
    "Name", "Active", "AnchorPoint", "AutoButtonColor",
    "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderSizePixel", "Image", "ImageColor3",
    "ImageRectOffset", "ImageRectSize", "ImageTransparency",
    "LayoutOrder", "Position", "Rotation", "ScaleType", "Size",
    "SliceCenter", "SliceScale", "TileSize",
    "Visible", "ZIndex"
}

PropertyDB.ScrollingFrame = {
    "Name", "Active", "AnchorPoint", "AutomaticCanvasSize",
    "BackgroundColor3", "BackgroundTransparency",
    "BorderColor3", "BorderSizePixel", "BottomImage",
    "CanvasPosition", "CanvasSize", "ClipsDescendants",
    "ElasticBehavior", "HorizontalScrollBarInset",
    "LayoutOrder", "MidImage", "Position", "Rotation",
    "ScrollBarImageColor3", "ScrollBarImageTransparency",
    "ScrollBarThickness", "ScrollingDirection", "ScrollingEnabled",
    "Size", "TopImage", "VerticalScrollBarInset",
    "VerticalScrollBarPosition", "Visible", "ZIndex"
}

-- UILayout elements
PropertyDB.UIListLayout = {
    "Name", "FillDirection", "HorizontalAlignment", "Padding",
    "SortOrder", "VerticalAlignment", "Wraps"
}

PropertyDB.UIGridLayout = {
    "Name", "CellPadding", "CellSize", "FillDirection",
    "FillDirectionMaxCells", "HorizontalAlignment",
    "SortOrder", "StartCorner", "VerticalAlignment"
}

PropertyDB.UIPadding = {
    "Name", "PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"
}

PropertyDB.UICorner = {
    "Name", "CornerRadius"
}

PropertyDB.UIStroke = {
    "Name", "ApplyStrokeMode", "Color", "Enabled",
    "LineJoinMode", "Thickness", "Transparency"
}

PropertyDB.UIScale = {
    "Name", "Scale"
}

PropertyDB.UIAspectRatioConstraint = {
    "Name", "AspectRatio", "AspectType", "DominantAxis"
}

PropertyDB.UISizeConstraint = {
    "Name", "MaxSize", "MinSize"
}

PropertyDB.UITextSizeConstraint = {
    "Name", "MaxTextSize", "MinTextSize"
}

-- Sound
PropertyDB.Sound = {
    "Name", "Looped", "PlayOnRemove", "PlaybackSpeed",
    "Playing", "RollOffMaxDistance", "RollOffMinDistance",
    "RollOffMode", "SoundId", "TimePosition", "Volume"
}

-- ParticleEmitter
PropertyDB.ParticleEmitter = {
    "Name", "Acceleration", "Brightness", "Color",
    "Drag", "EmissionDirection", "Enabled",
    "FlipbookFramerate", "FlipbookIncompatible", "FlipbookLayout",
    "FlipbookMode", "FlipbookStartRandom",
    "Lifetime", "LightEmission", "LightInfluence",
    "LockedToPart", "Orientation", "Rate", "RotSpeed",
    "Rotation", "Shape", "ShapeInOut", "ShapeStyle",
    "Size", "Speed", "SpreadAngle", "Squash",
    "Texture", "TimeScale", "Transparency",
    "VelocityInheritance", "WindAffectsDrag", "ZOffset"
}

-- Beam
PropertyDB.Beam = {
    "Name", "Attachment0", "Attachment1", "Brightness",
    "Color", "CurveSize0", "CurveSize1", "Enabled",
    "FaceCamera", "LightEmission", "LightInfluence",
    "Segments", "Texture", "TextureLength", "TextureMode",
    "TextureSpeed", "Transparency", "Width0", "Width1",
    "ZOffset"
}

-- Trail
PropertyDB.Trail = {
    "Name", "Attachment0", "Attachment1", "Brightness",
    "Color", "Enabled", "FaceCamera", "Lifetime",
    "LightEmission", "LightInfluence", "MaxLength",
    "MinLength", "Texture", "TextureLength", "TextureMode",
    "Transparency", "WidthScale"
}

-- Lighting
PropertyDB.Lighting = {
    "Ambient", "Brightness", "ColorShift_Bottom", "ColorShift_Top",
    "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
    "ExposureCompensation", "FogColor", "FogEnd", "FogStart",
    "GeographicLatitude", "GlobalShadows", "OutdoorAmbient",
    "ShadowSoftness", "Technology", "ClockTime", "TimeOfDay"
}

-- Atmosphere
PropertyDB.Atmosphere = {
    "Name", "Color", "Decay", "Density", "Glare", "Haze", "Offset"
}

-- Sky
PropertyDB.Sky = {
    "Name", "CelestialBodiesShown", "MoonAngularSize",
    "MoonTextureId", "SkyboxBk", "SkyboxDn", "SkyboxFt",
    "SkyboxLf", "SkyboxRt", "SkyboxUp",
    "StarCount", "SunAngularSize", "SunTextureId"
}

-- Camera
PropertyDB.Camera = {
    "Name", "CFrame", "CameraSubject", "CameraType",
    "DiagonalFieldOfView", "FieldOfView", "FieldOfViewMode",
    "Focus", "HeadLocked", "HeadScale",
    "MaxAxisFieldOfView", "NearPlaneZ", "VRTiltAndRollEnabled"
}

-- Humanoid
PropertyDB.Humanoid = {
    "Name", "AutoJumpEnabled", "AutoRotate",
    "AutomaticScalingEnabled", "BreakJointsOnDeath",
    "DisplayDistanceType", "DisplayName",
    "HealthDisplayDistance", "HealthDisplayType",
    "HipHeight", "JumpHeight", "JumpPower",
    "MaxHealth", "Health", "MaxSlopeAngle",
    "NameDisplayDistance", "NameOcclusion",
    "RequiresNeck", "RigType", "UseJumpPower", "WalkSpeed"
}

-- Folder / Configuration
PropertyDB.Folder = {
    "Name"
}

PropertyDB.Configuration = {
    "Name"
}

-- ValueObjects
PropertyDB.ValueObject = {
    "Name", "Value"
}

-- SurfaceAppearance
PropertyDB.SurfaceAppearance = {
    "Name", "AlphaMode", "ColorMap", "MetalnessMap",
    "NormalMap", "RoughnessMap", "TexturePack"
}

-- SpecialMesh
PropertyDB.SpecialMesh = {
    "Name", "MeshId", "MeshType", "Offset", "Scale", "TextureId",
    "VertexColor"
}

-- BillboardGui
PropertyDB.BillboardGui = {
    "Name", "Active", "Adornee", "AlwaysOnTop",
    "Brightness", "ClipsDescendants", "CurrentDistance",
    "DistanceLowerLimit", "DistanceStep", "DistanceUpperLimit",
    "Enabled", "ExtentsOffset", "ExtentsOffsetWorldSpace",
    "LightInfluence", "MaxDistance", "PlayerToHideFrom",
    "Size", "SizeOffset", "StudsOffset", "StudsOffsetWorldSpace",
    "ZIndexBehavior"
}

-- SurfaceGui
PropertyDB.SurfaceGui = {
    "Name", "Active", "Adornee", "AlwaysOnTop",
    "Brightness", "CanvasSize", "ClipsDescendants",
    "Enabled", "Face", "LightInfluence", "PixelsPerStud",
    "SizingMode", "ToolPunchThroughDistance",
    "ZIndexBehavior", "ZOffset"
}

--- Lấy danh sách properties cho một class
function PropertyDB.getPropertiesForClass(className)
    local props = {}
    
    -- Thêm base Instance properties
    for _, p in ipairs(PropertyDB.Instance or {}) do
        table.insert(props, p)
    end
    
    -- Kiểm tra class cụ thể
    if PropertyDB[className] then
        for _, p in ipairs(PropertyDB[className]) do
            if not table.find(props, p) then
                table.insert(props, p)
            end
        end
    end
    
    -- Kiểm tra class kế thừa
    -- BasePart hierarchy
    local basePartClasses = {
        "Part", "MeshPart", "UnionOperation", "NegateOperation",
        "WedgePart", "CornerWedgePart", "TrussPart", "SpawnLocation",
        "Seat", "VehicleSeat", "SkateboardPlatform"
    }
    
    for _, bpClass in ipairs(basePartClasses) do
        if className == bpClass then
            for _, p in ipairs(PropertyDB.BasePart) do
                if not table.find(props, p) then
                    table.insert(props, p)
                end
            end
            break
        end
    end
    
    -- Light hierarchy
    local lightClasses = {"PointLight", "SpotLight", "SurfaceLight"}
    for _, lClass in ipairs(lightClasses) do
        if className == lClass then
            for _, p in ipairs(PropertyDB.Light) do
                if not table.find(props, p) then
                    table.insert(props, p)
                end
            end
            break
        end
    end
    
    -- ValueObject hierarchy
    local valueClasses = {
        "BoolValue", "BrickColorValue", "CFrameValue",
        "Color3Value", "IntValue", "NumberValue",
        "ObjectValue", "RayValue", "StringValue", "Vector3Value"
    }
    for _, vClass in ipairs(valueClasses) do
        if className == vClass then
            for _, p in ipairs(PropertyDB.ValueObject) do
                if not table.find(props, p) then
                    table.insert(props, p)
                end
            end
            break
        end
    end
    
    return props
end

-- ============================================================
-- SECTION 5: SCRIPT DECOMPILER WRAPPER
-- ============================================================

local ScriptDecompiler = {}

--- Decompile một script instance, trả về source code string
function ScriptDecompiler.decompile(scriptInstance)
    if not scriptInstance then
        return "-- [BaoSaveInstance] nil script instance"
    end
    
    -- Kiểm tra cache
    if BaoSaveInstance._state.scriptCache[scriptInstance] then
        return BaoSaveInstance._state.scriptCache[scriptInstance]
    end
    
    local source = nil
    
    -- Phương pháp 1: Thử dùng hàm decompile của executor
    if decompile then
        local ok, result = pcall(function()
            return decompile(scriptInstance)
        end)
        if ok and result and type(result) == "string" and #result > 0 then
            source = result
        end
    end
    
    -- Phương pháp 2: Thử dùng getscriptbytecode + decompile
    if not source and getscriptbytecode then
        local ok, bytecode = pcall(function()
            return getscriptbytecode(scriptInstance)
        end)
        if ok and bytecode then
            -- Một số executor cung cấp decompile từ bytecode
            if decompile then
                local ok2, result = pcall(function()
                    return decompile(bytecode)
                end)
                if ok2 and result then
                    source = result
                end
            end
        end
    end
    
    -- Phương pháp 3: Thử đọc Source property trực tiếp
    if not source then
        local ok, result = pcall(function()
            return scriptInstance.Source
        end)
        if ok and result and type(result) == "string" and #result > 0 then
            source = result
        end
    end
    
    -- Phương pháp 4: Thử gethiddenproperty
    if not source and gethiddenproperty then
        local ok, result = pcall(function()
            return gethiddenproperty(scriptInstance, "Source")
        end)
        if ok and result and type(result) == "string" and #result > 0 then
            source = result
        end
    end
    
    -- Fallback: không decompile được
    if not source or source == "" then
        local className = scriptInstance.ClassName or "Unknown"
        local name = scriptInstance.Name or "Unknown"
        source = string.format(
            "-- [BaoSaveInstance] Could not decompile this %s: %s\n" ..
            "-- This may be a server-side script or protected script.\n" ..
            "-- ClassName: %s\n" ..
            "-- Full Path: %s\n",
            className, name, className,
            scriptInstance:GetFullName()
        )
    end
    
    -- Clean up source
    source = ScriptDecompiler.cleanSource(source)
    
    -- Cache kết quả
    BaoSaveInstance._state.scriptCache[scriptInstance] = source
    BaoSaveInstance._state.stats.scriptsDecompiled = BaoSaveInstance._state.stats.scriptsDecompiled + 1
    
    return source
end

--- Clean up decompiled source code
function ScriptDecompiler.cleanSource(source)
    if not source or type(source) ~= "string" then
        return "-- [BaoSaveInstance] Invalid source"
    end
    
    -- Loại bỏ null bytes
    source = source:gsub("\0", "")
    
    -- Đảm bảo kết thúc bằng newline
    if source:sub(-1) ~= "\n" then
        source = source .. "\n"
    end
    
    return source
end

--- Decompile tất cả scripts trong một container
function ScriptDecompiler.decompileAll(container, statusCallback)
    local scripts = {}
    local count = 0
    
    local ok, descendants = pcall(function()
        return container:GetDescendants()
    end)
    
    if not ok or not descendants then
        return scripts
    end
    
    for i, inst in ipairs(descendants) do
        if inst:IsA("LuaSourceContainer") then
            -- Script, LocalScript, ModuleScript
            local source = ScriptDecompiler.decompile(inst)
            scripts[inst] = source
            count = count + 1
            
            if statusCallback then
                statusCallback(string.format("Decompiling scripts... %d found", count))
            end
            
            -- Yield để tránh freeze
            Util.smartYield(i, 5) -- Yield thường xuyên hơn vì decompile tốn thời gian
        end
    end
    
    Util.logInfo(string.format("Decompiled %d scripts total", count))
    return scripts
end

-- ============================================================
-- SECTION 6: INSTANCE SERIALIZER (Instance → XML)
-- ============================================================

local InstanceSerializer = {}

--- Serialize một instance và tất cả children thành XML
--- Trả về table of XML string chunks (để tối ưu memory)
function InstanceSerializer.serialize(instance, depth, chunks, counter, statusCallback)
    if not instance then return counter end
    if Util.isExcluded(instance) then return counter end
    
    depth = depth or 0
    chunks = chunks or {}
    counter = counter or {count = 0}
    
    local className = instance.ClassName
    local ref = Serializer.getRef(instance)
    local indent = string.rep("  ", depth)
    
    -- Mở tag Item
    table.insert(chunks, string.format(
        '%s<Item class="%s" referent="%s">',
        indent, Serializer.escapeXml(className), ref
    ))
    table.insert(chunks, indent .. "  <Properties>")
    
    -- Serialize properties
    local props = PropertyDB.getPropertiesForClass(className)
    
    for _, propName in ipairs(props) do
        local ok, value = pcall(function()
            return instance[propName]
        end)
        
        if ok and value ~= nil then
            local xmlProp = Serializer.serializePropertyValue(propName, value)
            if xmlProp then
                table.insert(chunks, indent .. "    " .. xmlProp)
            end
        end
    end
    
    -- Serialize Source cho script types
    if instance:IsA("LuaSourceContainer") and BaoSaveInstance._config.decompileScripts then
        local source = ScriptDecompiler.decompile(instance)
        if source then
            local escapedSource = Serializer.escapeXml(source)
            table.insert(chunks, string.format(
                '%s    <ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>',
                indent, source  -- CDATA không cần escape
            ))
        end
    end
    
    -- Serialize Attributes
    local attrOk, attributes = pcall(function()
        return instance:GetAttributes()
    end)
    if attrOk and attributes and next(attributes) then
        InstanceSerializer.serializeAttributes(instance, attributes, chunks, indent .. "    ")
    end
    
    -- Serialize Tags
    local tagOk, tags = pcall(function()
        return instance:GetTags()
    end)
    if tagOk and tags and #tags > 0 then
        local tagStr = table.concat(tags, "\n")
        table.insert(chunks, string.format(
            '%s    <string name="Tags">%s</string>',
            indent, Serializer.escapeXml(tagStr)
        ))
    end
    
    table.insert(chunks, indent .. "  </Properties>")
    
    -- Counter và yield
    counter.count = counter.count + 1
    if counter.count % BaoSaveInstance._config.yieldInterval == 0 then
        task.wait()
        if statusCallback then
            statusCallback(string.format("Serializing... %d instances processed", counter.count))
        end
    end
    
    -- Serialize children recursively
    local childOk, children = pcall(function()
        return instance:GetChildren()
    end)
    
    if childOk and children then
        for _, child in ipairs(children) do
            InstanceSerializer.serialize(child, depth + 1, chunks, counter, statusCallback)
        end
    end
    
    -- Đóng tag Item
    table.insert(chunks, indent .. "</Item>")
    
    return counter
end

--- Serialize attributes thành XML binary format
function InstanceSerializer.serializeAttributes(instance, attributes, chunks, indent)
    -- Roblox attributes được lưu dưới dạng binary blob trong RBXL
    -- Nhưng trong XML format, ta có thể serialize từng attribute
    for attrName, attrValue in pairs(attributes) do
        local xmlProp = Serializer.serializePropertyValue(
            "Attribute_" .. attrName, attrValue
        )
        if xmlProp then
            table.insert(chunks, indent .. xmlProp)
        end
    end
end

--- Serialize một service container (Workspace, ReplicatedStorage, etc.)
function InstanceSerializer.serializeService(service, chunks, counter, statusCallback)
    if not service then return counter end
    
    local className = service.ClassName
    local ref = Serializer.getRef(service)
    
    table.insert(chunks, string.format(
        '  <Item class="%s" referent="%s">',
        Serializer.escapeXml(className), ref
    ))
    table.insert(chunks, '    <Properties>')
    table.insert(chunks, string.format(
        '      <string name="Name">%s</string>',
        Serializer.escapeXml(service.Name)
    ))
    table.insert(chunks, '    </Properties>')
    
    -- Serialize children
    local childOk, children = pcall(function()
        return service:GetChildren()
    end)
    
    if childOk and children then
        for _, child in ipairs(children) do
            if not Util.isExcluded(child) then
                InstanceSerializer.serialize(child, 2, chunks, counter, statusCallback)
            end
        end
    end
    
    table.insert(chunks, '  </Item>')
    
    return counter
end

-- ============================================================
-- SECTION 7: TERRAIN SERIALIZER
-- ============================================================

local TerrainSerializer = {}

--- Serialize Terrain voxel data
--- Roblox Terrain sử dụng Region3 based voxel system
function TerrainSerializer.serialize(statusCallback)
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        Util.logInfo("No terrain found in workspace")
        return nil
    end
    
    if statusCallback then
        statusCallback("Reading terrain data...")
    end
    
    local chunks = {}
    local ref = Serializer.getRef(terrain)
    
    table.insert(chunks, string.format(
        '  <Item class="Terrain" referent="%s">', ref
    ))
    table.insert(chunks, '    <Properties>')
    table.insert(chunks, '      <string name="Name">Terrain</string>')
    
    -- Serialize terrain properties
    local terrainProps = {
        {"WaterColor", terrain.WaterColor},
        {"WaterReflectance", terrain.WaterReflectance},
        {"WaterTransparency", terrain.WaterTransparency},
        {"WaterWaveSize", terrain.WaterWaveSize},
        {"WaterWaveSpeed", terrain.WaterWaveSpeed},
        {"Decoration", terrain.Decoration}
    }
    
    for _, propData in ipairs(terrainProps) do
        local propName, propValue = propData[1], propData[2]
        local ok, xmlProp = pcall(function()
            return Serializer.serializePropertyValue(propName, propValue)
        end)
        if ok and xmlProp then
            table.insert(chunks, '      ' .. xmlProp)
        end
    end
    
    -- Serialize MaterialColors nếu có
    local ok, matColors = pcall(function()
        return terrain.MaterialColors
    end)
    if ok and matColors then
        table.insert(chunks, string.format(
            '      <BinaryString name="MaterialColors">%s</BinaryString>',
            Serializer.escapeXml(tostring(matColors))
        ))
    end
    
    -- Serialize SmoothGrid (voxel data) 
    -- Đây là phần phức tạp nhất - terrain voxel data
    if statusCallback then
        statusCallback("Encoding terrain voxel data...")
    end
    
    local terrainData = TerrainSerializer.readTerrainVoxels(terrain, statusCallback)
    if terrainData then
        -- SmoothGrid chứa material + occupancy data
        table.insert(chunks, string.format(
            '      <BinaryString name="SmoothGrid">%s</BinaryString>',
            terrainData
        ))
    end
    
    -- PhysicsGrid
    local physOk, physData = pcall(function()
        return TerrainSerializer.readPhysicsGrid(terrain)
    end)
    if physOk and physData then
        table.insert(chunks, string.format(
            '      <BinaryString name="PhysicsGrid">%s</BinaryString>',
            physData
        ))
    end
    
    table.insert(chunks, '    </Properties>')
    table.insert(chunks, '  </Item>')
    
    if statusCallback then
        statusCallback("Terrain serialization complete")
    end
    
    return table.concat(chunks, "\n")
end

--- Đọc terrain voxel data bằng ReadVoxels
function TerrainSerializer.readTerrainVoxels(terrain, statusCallback)
    -- Lấy bounding box của terrain
    local regionOk, regionSize = pcall(function()
        -- Đọc MaxExtents từ terrain
        local maxExt = terrain.MaxExtents
        return maxExt
    end)
    
    -- Sử dụng phương pháp đọc từng chunk
    local chunkSize = BaoSaveInstance._config.terrainChunkSize
    local resolution = 4 -- Roblox terrain resolution = 4 studs
    
    -- Tìm bounds của terrain có data
    local minBound = Vector3.new(-2048, -512, -2048)
    local maxBound = Vector3.new(2048, 512, 2048)
    
    -- Thử thu nhỏ bounds bằng cách tìm terrain thực tế
    local boundsOk, actualBounds = pcall(function()
        return TerrainSerializer.findTerrainBounds(terrain, resolution)
    end)
    
    if boundsOk and actualBounds then
        minBound = actualBounds.min
        maxBound = actualBounds.max
    end
    
    -- Encode terrain data dưới dạng base64 chunks
    local encodedChunks = {}
    local chunkCount = 0
    
    for x = minBound.X, maxBound.X, chunkSize * resolution do
        for y = minBound.Y, maxBound.Y, chunkSize * resolution do
            for z = minBound.Z, maxBound.Z, chunkSize * resolution do
                local regionStart = Vector3.new(x, y, z)
                local regionEnd = Vector3.new(
                    math.min(x + chunkSize * resolution, maxBound.X),
                    math.min(y + chunkSize * resolution, maxBound.Y),
                    math.min(z + chunkSize * resolution, maxBound.Z)
                )
                
                local region = Region3.new(regionStart, regionEnd)
                region = region:ExpandToGrid(resolution)
                
                local readOk, materials, occupancy = pcall(function()
                    return terrain:ReadVoxels(region, resolution)
                end)
                
                if readOk and materials and occupancy then
                    -- Kiểm tra xem chunk có data không (không phải toàn Air)
                    local hasData = false
                    for xi = 1, #materials do
                        for yi = 1, #materials[xi] do
                            for zi = 1, #materials[xi][yi] do
                                if materials[xi][yi][zi] ~= Enum.Material.Air then
                                    hasData = true
                                    break
                                end
                            end
                            if hasData then break end
                        end
                        if hasData then break end
                    end
                    
                    if hasData then
                        local chunkData = TerrainSerializer.encodeVoxelChunk(
                            regionStart, regionEnd, materials, occupancy, resolution
                        )
                        if chunkData then
                            table.insert(encodedChunks, chunkData)
                            chunkCount = chunkCount + 1
                            
                            BaoSaveInstance._state.stats.terrainRegions = chunkCount
                        end
                    end
                end
                
                -- Yield periodically
                Util.smartYield(chunkCount, 10)
                
                if statusCallback and chunkCount % 5 == 0 then
                    statusCallback(string.format("Reading terrain... %d chunks", chunkCount))
                end
            end
        end
    end
    
    Util.logInfo(string.format("Terrain: %d non-empty chunks encoded", chunkCount))
    
    if #encodedChunks == 0 then
        return nil
    end
    
    -- Combine tất cả chunks
    return table.concat(encodedChunks, "|")
end

--- Tìm bounding box thực tế của terrain (tránh scan vùng trống)
function TerrainSerializer.findTerrainBounds(terrain, resolution)
    local testSize = 512
    local step = 64
    
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    local found = false
    
    for x = -testSize, testSize, step do
        for y = -testSize, testSize, step do
            for z = -testSize, testSize, step do
                local region = Region3.new(
                    Vector3.new(x, y, z),
                    Vector3.new(x + step, y + step, z + step)
                ):ExpandToGrid(resolution)
                
                local ok, mats = pcall(function()
                    return terrain:ReadVoxels(region, resolution)
                end)
                
                if ok and mats then
                    for xi = 1, #mats do
                        for yi = 1, #mats[xi] do
                            for zi = 1, #mats[xi][yi] do
                                if mats[xi][yi][zi] ~= Enum.Material.Air then
                                    found = true
                                    minX = math.min(minX, x)
                                    minY = math.min(minY, y)
                                    minZ = math.min(minZ, z)
                                    maxX = math.max(maxX, x + step)
                                    maxY = math.max(maxY, y + step)
                                    maxZ = math.max(maxZ, z + step)
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait()
    end
    
    if not found then
        return {
            min = Vector3.new(-256, -256, -256),
            max = Vector3.new(256, 256, 256)
        }
    end
    
    -- Thêm padding
    local padding = 32
    return {
        min = Vector3.new(minX - padding, minY - padding, minZ - padding),
        max = Vector3.new(maxX + padding, maxY + padding, maxZ + padding)
    }
end

--- Encode một voxel chunk thành string data
function TerrainSerializer.encodeVoxelChunk(regionStart, regionEnd, materials, occupancy, resolution)
    local data = {}
    
    -- Header: region bounds
    table.insert(data, string.format(
        "%f,%f,%f,%f,%f,%f,%d",
        regionStart.X, regionStart.Y, regionStart.Z,
        regionEnd.X, regionEnd.Y, regionEnd.Z,
        resolution
    ))
    
    -- Material + occupancy data
    local voxelData = {}
    for x = 1, #materials do
        for y = 1, #materials[x] do
            for z = 1, #materials[x][y] do
                local mat = materials[x][y][z]
                local occ = occupancy[x][y][z]
                
                if mat ~= Enum.Material.Air or occ > 0 then
                    -- Format: x,y,z,materialValue,occupancy
                    table.insert(voxelData, string.format(
                        "%d,%d,%d,%d,%.4f",
                        x, y, z, mat.Value, occ
                    ))
                end
            end
        end
    end
    
    if #voxelData == 0 then
        return nil
    end
    
    table.insert(data, table.concat(voxelData, ";"))
    
    return table.concat(data, ":")
end

--- Đọc PhysicsGrid data
function TerrainSerializer.readPhysicsGrid(terrain)
    -- PhysicsGrid thường được handle tự động bởi engine
    -- Trong context save, nó ít quan trọng hơn SmoothGrid
    return ""
end

-- ============================================================
-- SECTION 8: RBXL FILE BUILDER
-- ============================================================

local RBXLBuilder = {}

--- Tạo XML header cho file RBXL
function RBXLBuilder.createHeader()
    return table.concat({
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"',
        ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
        ' xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd"',
        ' version="4">',
        '',
        '<!-- Generated by BaoSaveInstance v' .. BaoSaveInstance._VERSION .. ' -->',
        '<!-- Date: ' .. os.date("%Y-%m-%d %H:%M:%S") .. ' -->',
        '<!-- Game PlaceId: ' .. tostring(game.PlaceId) .. ' -->',
        ''
    }, "\n")
end

--- Tạo XML footer
function RBXLBuilder.createFooter()
    return "\n</roblox>"
end

--- Tạo External elements (SharedStrings, etc.)
function RBXLBuilder.createExternals()
    return '<External>null</External>\n<External>nil</External>\n'
end

--- Build complete RBXL file content cho Full Game
function RBXLBuilder.buildFullGame(statusCallback)
    if statusCallback then statusCallback("Building full game RBXL...") end
    
    Serializer.reset()
    local chunks = {}
    local counter = {count = 0}
    
    -- Header
    table.insert(chunks, RBXLBuilder.createHeader())
    table.insert(chunks, RBXLBuilder.createExternals())
    
    -- Serialize từng service
    for _, serviceName in ipairs(BaoSaveInstance._config.fullGameServices) do
        local service = Util.getService(serviceName)
        if service then
            if statusCallback then
                statusCallback(string.format("Serializing %s...", serviceName))
            end
            Util.logInfo("Serializing service: " .. serviceName)
            
            local ok, err = pcall(function()
                InstanceSerializer.serializeService(service, chunks, counter, statusCallback)
            end)
            
            if not ok then
                Util.logError("SerializeService:" .. serviceName, err)
                -- Thêm comment về lỗi
                table.insert(chunks, string.format(
                    '  <!-- Error serializing %s: %s -->',
                    serviceName, Serializer.escapeXml(tostring(err))
                ))
            end
            
            task.wait() -- Yield giữa các service
        else
            Util.logInfo("Service not accessible: " .. serviceName)
        end
    end
    
    -- Serialize Terrain riêng
    if statusCallback then statusCallback("Serializing terrain...") end
    local terrainXml = TerrainSerializer.serialize(statusCallback)
    if terrainXml then
        table.insert(chunks, terrainXml)
    end
    
    -- Footer
    table.insert(chunks, RBXLBuilder.createFooter())
    
    BaoSaveInstance._state.stats.totalInstances = counter.count
    
    if statusCallback then
        statusCallback(string.format("Build complete! %d instances", counter.count))
    end
    
    return table.concat(chunks, "\n")
end

--- Build RBXL cho Models only
function RBXLBuilder.buildModelsOnly(statusCallback)
    if statusCallback then statusCallback("Building models RBXL...") end
    
    Serializer.reset()
    local chunks = {}
    local counter = {count = 0}
    
    table.insert(chunks, RBXLBuilder.createHeader())
    table.insert(chunks, RBXLBuilder.createExternals())
    
    for _, serviceName in ipairs(BaoSaveInstance._config.modelServices) do
        local service = Util.getService(serviceName)
        if service then
            if statusCallback then
                statusCallback(string.format("Serializing models in %s...", serviceName))
            end
            
            local ok, err = pcall(function()
                -- Chỉ serialize Models, Parts, và các instance non-terrain
                local children = service:GetChildren()
                for _, child in ipairs(children) do
                    if not child:IsA("Terrain") and not Util.isExcluded(child) then
                        InstanceSerializer.serialize(child, 1, chunks, counter, statusCallback)
                    end
                end
            end)
            
            if not ok then
                Util.logError("SerializeModels:" .. serviceName, err)
            end
            
            task.wait()
        end
    end
    
    table.insert(chunks, RBXLBuilder.createFooter())
    
    BaoSaveInstance._state.stats.totalInstances = counter.count
    BaoSaveInstance._state.stats.modelsProcessed = counter.count
    
    return table.concat(chunks, "\n")
end

--- Build RBXL cho Terrain only
function RBXLBuilder.buildTerrainOnly(statusCallback)
    if statusCallback then statusCallback("Building terrain RBXL...") end
    
    Serializer.reset()
    local chunks = {}
    
    table.insert(chunks, RBXLBuilder.createHeader())
    table.insert(chunks, RBXLBuilder.createExternals())
    
    -- Chỉ serialize Workspace container + Terrain
    table.insert(chunks, '  <Item class="Workspace" referent="RBX_WS">')
    table.insert(chunks, '    <Properties>')
    table.insert(chunks, '      <string name="Name">Workspace</string>')
    table.insert(chunks, '    </Properties>')
    
    local terrainXml = TerrainSerializer.serialize(statusCallback)
    if terrainXml then
        table.insert(chunks, terrainXml)
    end
    
    table.insert(chunks, '  </Item>')
    table.insert(chunks, RBXLBuilder.createFooter())
    
    return table.concat(chunks, "\n")
end

-- ============================================================
-- SECTION 9: FILE WRITER
-- ============================================================

local FileWriter = {}

--- Ghi nội dung ra file, xử lý file lớn
function FileWriter.write(fileName, content, statusCallback)
    if not content or #content == 0 then
        Util.logError("FileWriter", "No content to write")
        return false, "No content to write"
    end
    
    local fullPath = BaoSaveInstance._config.outputFolder .. "/" .. fileName
    
    if statusCallback then
        statusCallback(string.format("Writing file: %s (%s)", fileName, Util.formatBytes(#content)))
    end
    
    -- Tạo folder nếu chưa có
    local folderOk, folderErr = pcall(function()
        if makefolder then
            makefolder(BaoSaveInstance._config.outputFolder)
        end
    end)
    
    -- Ghi file
    local ok, err = pcall(function()
        writefile(fullPath, content)
    end)
    
    if ok then
        BaoSaveInstance._state.stats.fileSize = #content
        Util.logInfo(string.format(
            "File written successfully: %s (%s)",
            fullPath, Util.formatBytes(#content)
        ))
        
        if statusCallback then
            statusCallback(string.format("✓ Saved: %s (%s)", fileName, Util.formatBytes(#content)))
        end
        
        return true, fullPath
    else
        Util.logError("FileWriter", err)
        if statusCallback then
            statusCallback("✗ Error writing file: " .. tostring(err))
        end
        return false, tostring(err)
    end
end

-- ============================================================
-- SECTION 10: EXECUTOR SAVEINSTANCE INTEGRATION
-- Sử dụng saveinstance() native của executor nếu có
-- ============================================================

local NativeSaver = {}

--- Kiểm tra executor có hỗ trợ saveinstance native không
function NativeSaver.isAvailable()
    return (saveinstance ~= nil) or (syn and syn.saveinstance ~= nil)
end

--- Sử dụng native saveinstance với custom options
function NativeSaver.save(mode, fileName, statusCallback)
    local options = {}
    
    if mode == "FULL_GAME" then
        options = {
            FileName = fileName,
            DecompileMode = "full",
            NilInstances = true,
            RemovePlayerCharacters = BaoSaveInstance._config.removePlayerCharacters,
            SavePlayers = BaoSaveInstance._config.savePlayers,
            ExtraInstances = {},
            ShowStatus = true,
            mode = "optimized",
            Timeout = BaoSaveInstance._config.decompileTimeout,
            -- Đảm bảo output là .rbxl
            FilePath = BaoSaveInstance._config.outputFolder .. "/" .. fileName
        }
    elseif mode == "MODEL_ONLY" then
        options = {
            FileName = fileName,
            DecompileMode = "full",
            NilInstances = false,
            RemovePlayerCharacters = true,
            SavePlayers = false,
            -- Chỉ save certain services
            ExtraInstances = {},
            ShowStatus = true,
            Timeout = BaoSaveInstance._config.decompileTimeout,
            FilePath = BaoSaveInstance._config.outputFolder .. "/" .. fileName
        }
    elseif mode == "TERRAIN_ONLY" then
        options = {
            FileName = fileName,
            DecompileMode = "none",
            NilInstances = false,
            RemovePlayerCharacters = true,
            SavePlayers = false,
            ShowStatus = true,
            FilePath = BaoSaveInstance._config.outputFolder .. "/" .. fileName
        }
    end
    
    if statusCallback then
        statusCallback("Using native saveinstance...")
    end
    
    local ok, err
    
    if syn and syn.saveinstance then
        ok, err = pcall(function()
            syn.saveinstance(options)
        end)
    elseif saveinstance then
        ok, err = pcall(function()
            saveinstance(options)
        end)
    else
        return false, "No native saveinstance available"
    end
    
    if ok then
        if statusCallback then
            statusCallback("✓ Native save complete: " .. fileName)
        end
        return true, fileName
    else
        if statusCallback then
            statusCallback("Native save failed, falling back to custom serializer...")
        end
        return false, tostring(err)
    end
end

-- ============================================================
-- SECTION 11: MAIN API FUNCTIONS
-- ============================================================

--- Khởi tạo BaoSaveInstance
function BaoSaveInstance.init(customConfig)
    if BaoSaveInstance._state.initialized then
        Util.logInfo("Already initialized")
        return true
    end
    
    Util.logInfo("Initializing BaoSaveInstance v" .. BaoSaveInstance._VERSION)
    
    -- Apply custom config nếu có
    if customConfig and type(customConfig) == "table" then
        for key, value in pairs(customConfig) do
            if BaoSaveInstance._config[key] ~= nil then
                BaoSaveInstance._config[key] = value
            end
        end
    end
    
    -- Check environment
    local envOk, missing = checkEnvironment()
    if not envOk then
        Util.logError("Init", "Missing functions: " .. table.concat(missing, ", "))
        -- Tiếp tục nhưng cảnh báo
    end
    
    -- Reset state
    BaoSaveInstance._state.scriptCache = {}
    BaoSaveInstance._state.errorLog = {}
    BaoSaveInstance._state.stats = {
        totalInstances = 0,
        scriptsDecompiled = 0,
        modelsProcessed = 0,
        terrainRegions = 0,
        fileSize = 0
    }
    
    -- Cache services
    for _, serviceName in ipairs(BaoSaveInstance._config.fullGameServices) do
        Util.getService(serviceName)
    end
    
    BaoSaveInstance._state.initialized = true
    Util.logInfo("Initialization complete")
    
    return true
end

--- Decompile tất cả scripts trong game
function BaoSaveInstance.decompileScripts(statusCallback)
    if BaoSaveInstance._state.busy then
        return nil, "System is busy"
    end
    
    BaoSaveInstance._state.busy = true
    BaoSaveInstance._state.statusText = "Decompiling scripts..."
    
    if statusCallback then statusCallback("Starting script decompilation...") end
    
    local allScripts = {}
    
    for _, serviceName in ipairs(BaoSaveInstance._config.fullGameServices) do
        local service = Util.getService(serviceName)
        if service then
            if statusCallback then
                statusCallback(string.format("Decompiling scripts in %s...", serviceName))
            end
            
            local scripts = ScriptDecompiler.decompileAll(service, statusCallback)
            for inst, source in pairs(scripts) do
                allScripts[inst] = source
            end
            
            task.wait()
        end
    end
    
    BaoSaveInstance._state.busy = false
    BaoSaveInstance._state.statusText = "Script decompilation complete"
    
    local count = 0
    for _ in pairs(allScripts) do count = count + 1 end
    
    if statusCallback then
        statusCallback(string.format("✓ Decompiled %d scripts", count))
    end
    
    Util.logInfo(string.format("Total scripts decompiled: %d", count))
    
    return allScripts
end

--- Lưu tất cả models
function BaoSaveInstance.saveModels(statusCallback)
    if BaoSaveInstance._state.busy then
        return nil, "System is busy"
    end
    
    BaoSaveInstance._state.busy = true
    BaoSaveInstance._state.statusText = "Saving models..."
    
    local content = RBXLBuilder.buildModelsOnly(statusCallback)
    
    BaoSaveInstance._state.busy = false
    return content
end

--- Lưu terrain
function BaoSaveInstance.saveTerrain(statusCallback)
    if BaoSaveInstance._state.busy then
        return nil, "System is busy"
    end
    
    BaoSaveInstance._state.busy = true
    BaoSaveInstance._state.statusText = "Saving terrain..."
    
    local content = RBXLBuilder.buildTerrainOnly(statusCallback)
    
    BaoSaveInstance._state.busy = false
    return content
end

--- Export ra file RBXL
--- mode: "FULL_GAME", "MODEL_ONLY", "TERRAIN_ONLY"
function BaoSaveInstance.exportRBXL(mode, statusCallback)
    if BaoSaveInstance._state.busy then
        if statusCallback then statusCallback("System is busy, please wait...") end
        return false, "System is busy"
    end
    
    -- Đảm bảo đã init
    if not BaoSaveInstance._state.initialized then
        BaoSaveInstance.init()
    end
    
    BaoSaveInstance._state.busy = true
    BaoSaveInstance._state.currentMode = mode
    BaoSaveInstance._state.statusText = "Starting export..."
    
    local gameName = Util.getGameName()
    local fileName
    local content
    local success = false
    
    -- Xác định tên file theo mode
    if mode == "FULL_GAME" then
        fileName = gameName .. "_Full" .. BaoSaveInstance._config.fileExtension
    elseif mode == "MODEL_ONLY" then
        fileName = gameName .. "_Model" .. BaoSaveInstance._config.fileExtension
    elseif mode == "TERRAIN_ONLY" then
        fileName = gameName .. "_Terrain" .. BaoSaveInstance._config.fileExtension
    else
        BaoSaveInstance._state.busy = false
        return false, "Invalid mode: " .. tostring(mode)
    end
    
    -- Thử native saveinstance trước (nhanh hơn và chính xác hơn)
    if NativeSaver.isAvailable() and mode ~= "TERRAIN_ONLY" then
        if statusCallback then
            statusCallback("Trying native saveinstance...")
        end
        
        local nativeOk, nativeResult = NativeSaver.save(mode, fileName, statusCallback)
        if nativeOk then
            BaoSaveInstance._state.busy = false
            BaoSaveInstance._state.statusText = "Done ✓"
            return true, nativeResult
        else
            if statusCallback then
                statusCallback("Native save failed, using custom serializer...")
            end
        end
    end
    
    -- Fallback: custom XML serializer
    local buildOk, buildResult = pcall(function()
        if mode == "FULL_GAME" then
            return RBXLBuilder.buildFullGame(statusCallback)
        elseif mode == "MODEL_ONLY" then
            return RBXLBuilder.buildModelsOnly(statusCallback)
        elseif mode == "TERRAIN_ONLY" then
            return RBXLBuilder.buildTerrainOnly(statusCallback)
        end
    end)
    
    if buildOk and buildResult then
        content = buildResult
    else
        BaoSaveInstance._state.busy = false
        BaoSaveInstance._state.statusText = "Build failed"
        Util.logError("Build", buildResult)
        if statusCallback then
            statusCallback("✗ Build failed: " .. tostring(buildResult))
        end
        return false, tostring(buildResult)
    end
    
    -- Ghi file
    local writeOk, writePath = FileWriter.write(fileName, content, statusCallback)
    
    BaoSaveInstance._state.busy = false
    
    if writeOk then
        BaoSaveInstance._state.statusText = "Done ✓"
        return true, writePath
    else
        BaoSaveInstance._state.statusText = "Write failed"
        return false, writePath
    end
end

--- Lấy trạng thái hiện tại
function BaoSaveInstance.getStatus()
    return {
        busy = BaoSaveInstance._state.busy,
        statusText = BaoSaveInstance._state.statusText,
        stats = Util.deepClone(BaoSaveInstance._state.stats),
        errors = #BaoSaveInstance._state.errorLog
    }
end

--- Lấy error log
function BaoSaveInstance.getErrorLog()
    return Util.deepClone(BaoSaveInstance._state.errorLog)
end

--- Reset toàn bộ state
function BaoSaveInstance.reset()
    BaoSaveInstance._state.initialized = false
    BaoSaveInstance._state.busy = false
    BaoSaveInstance._state.currentMode = nil
    BaoSaveInstance._state.progress = 0
    BaoSaveInstance._state.statusText = "Idle"
    BaoSaveInstance._state.scriptCache = {}
    BaoSaveInstance._state.errorLog = {}
    BaoSaveInstance._state.stats = {
        totalInstances = 0,
        scriptsDecompiled = 0,
        modelsProcessed = 0,
        terrainRegions = 0,
        fileSize = 0
    }
    Serializer.reset()
    Util.logInfo("State reset complete")
end

-- ============================================================
-- SECTION 12: GUI / UI
-- ============================================================

local UI = {}

--- Tạo toàn bộ GUI
function UI.create()
    -- Xóa GUI cũ nếu có
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local existingGui = playerGui:FindFirstChild("BaoSaveInstance_GUI")
    if existingGui then
        existingGui:Destroy()
    end
    
    -- ScreenGui chính
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstance_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    
    -- Protect GUI khỏi bị xóa bởi game scripts
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
    elseif protect_gui then
        protect_gui(screenGui)
    end
    
    -- ==========================================
    -- Main Frame
    -- ==========================================
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 340, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -170, 0.5, -210)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = screenGui
    
    -- Corner radius
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- Drop shadow effect (using stroke)
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(80, 80, 120)
    mainStroke.Thickness = 1.5
    mainStroke.Transparency = 0.3
    mainStroke.Parent = mainFrame
    
    -- ==========================================
    -- Title Bar (Draggable)
    -- ==========================================
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Fix bottom corners of title bar
    local titleFix = Instance.new("Frame")
    titleFix.Name = "CornerFix"
    titleFix.Size = UDim2.new(1, 0, 0, 15)
    titleFix.Position = UDim2.new(0, 0, 1, -15)
    titleFix.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🔧 BaoSaveInstance v" .. BaoSaveInstance._VERSION
    titleText.TextColor3 = Color3.fromRGB(220, 220, 255)
    titleText.TextSize = 16
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Minimize button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.Position = UDim2.new(1, -40, 0.5, -15)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Text = "—"
    minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
    minimizeBtn.TextSize = 18
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = titleBar
    
    local minBtnCorner = Instance.new("UICorner")
    minBtnCorner.CornerRadius = UDim.new(0, 6)
    minBtnCorner.Parent = minimizeBtn
    
    -- ==========================================
    -- Content Area
    -- ==========================================
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -20, 1, -55)
    contentFrame.Position = UDim2.new(0, 10, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentFrame
    
    -- ==========================================
    -- Status Display
    -- ==========================================
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(1, 0, 0, 60)
    statusFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    statusFrame.BorderSizePixel = 0
    statusFrame.LayoutOrder = 0
    statusFrame.Parent = contentFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusFrame
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -16, 0, 20)
    statusLabel.Position = UDim2.new(0, 8, 0, 5)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status:"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = statusFrame
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -16, 0, 30)
    statusText.Position = UDim2.new(0, 8, 0, 25)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Ready - Waiting for action"
    statusText.TextColor3 = Color3.fromRGB(100, 255, 150)
    statusText.TextSize = 13
    statusText.Font = Enum.Font.GothamSemibold
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.TextWrapped = true
    statusText.Parent = statusFrame
    
    -- ==========================================
    -- Progress Bar
    -- ==========================================
    local progressFrame = Instance.new("Frame")
    progressFrame.Name = "ProgressFrame"
    progressFrame.Size = UDim2.new(1, 0, 0, 8)
    progressFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    progressFrame.BorderSizePixel = 0
    progressFrame.LayoutOrder = 1
    progressFrame.Parent = contentFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 4)
    progressCorner.Parent = progressFrame
    
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressFrame
    
    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(0, 4)
    progressBarCorner.Parent = progressBar
    
    -- Gradient cho progress bar
    local progressGradient = Instance.new("UIGradient")
    progressGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 160, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 80, 255))
    })
    progressGradient.Parent = progressBar
    
    -- ==========================================
    -- Separator
    -- ==========================================
    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(0.9, 0, 0, 1)
    separator.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    separator.BorderSizePixel = 0
    separator.LayoutOrder = 2
    separator.Parent = contentFrame
    
    -- ==========================================
    -- Button Factory
    -- ==========================================
    local function createButton(name, text, icon, layoutOrder, color)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 42)
        btn.BackgroundColor3 = color or Color3.fromRGB(35, 35, 55)
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.LayoutOrder = layoutOrder
        btn.Parent = contentFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(60, 60, 90)
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.5
        btnStroke.Parent = btn
        
        local btnIcon = Instance.new("TextLabel")
        btnIcon.Name = "Icon"
        btnIcon.Size = UDim2.new(0, 30, 1, 0)
        btnIcon.Position = UDim2.new(0, 10, 0, 0)
        btnIcon.BackgroundTransparency = 1
        btnIcon.Text = icon
        btnIcon.TextSize = 18
        btnIcon.Font = Enum.Font.GothamBold
        btnIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnIcon.Parent = btn
        
        local btnText = Instance.new("TextLabel")
        btnText.Name = "Label"
        btnText.Size = UDim2.new(1, -50, 1, 0)
        btnText.Position = UDim2.new(0, 45, 0, 0)
        btnText.BackgroundTransparency = 1
        btnText.Text = text
        btnText.TextColor3 = Color3.fromRGB(220, 220, 240)
        btnText.TextSize = 14
        btnText.Font = Enum.Font.GothamSemibold
        btnText.TextXAlignment = Enum.TextXAlignment.Left
        btnText.Parent = btn
        
        -- Hover effects
        btn.MouseEnter:Connect(function()
            game:GetService("TweenService"):Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(50, 50, 80)
            }):Play()
            game:GetService("TweenService"):Create(btnStroke, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(100, 100, 180),
                Transparency = 0
            }):Play()
        end)
        
        btn.MouseLeave:Connect(function()
            game:GetService("TweenService"):Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = color or Color3.fromRGB(35, 35, 55)
            }):Play()
            game:GetService("TweenService"):Create(btnStroke, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(60, 60, 90),
                Transparency = 0.5
            }):Play()
        end)
        
        return btn
    end
    
    -- ==========================================
    -- Create Action Buttons
    -- ==========================================
    local btnFullGame = createButton(
        "BtnFullGame", "Decompile Full Game", "🎮", 3,
        Color3.fromRGB(25, 40, 60)
    )
    
    local btnFullModel = createButton(
        "BtnFullModel", "Decompile Full Model", "🏗️", 4,
        Color3.fromRGB(25, 45, 35)
    )
    
    local btnTerrain = createButton(
        "BtnTerrain", "Decompile Terrain", "🌍", 5,
        Color3.fromRGB(45, 35, 25)
    )
    
    local btnSave = createButton(
        "BtnSave", "Save To .rbxl", "💾", 6,
        Color3.fromRGB(20, 50, 30)
    )
    
    -- Separator 2
    local separator2 = Instance.new("Frame")
    separator2.Name = "Separator2"
    separator2.Size = UDim2.new(0.9, 0, 0, 1)
    separator2.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    separator2.BorderSizePixel = 0
    separator2.LayoutOrder = 7
    separator2.Parent = contentFrame
    
    local btnExit = createButton(
        "BtnExit", "Exit", "❌", 8,
        Color3.fromRGB(60, 25, 25)
    )
    
    -- ==========================================
    -- Stats Display
    -- ==========================================
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "Stats"
    statsLabel.Size = UDim2.new(1, 0, 0, 20)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "PlaceId: " .. tostring(game.PlaceId)
    statsLabel.TextColor3 = Color3.fromRGB(100, 100, 130)
    statsLabel.TextSize = 11
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.LayoutOrder = 9
    statsLabel.Parent = contentFrame
    
    -- ==========================================
    -- DRAGGABLE FUNCTIONALITY
    -- ==========================================
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local userInputService = game:GetService("UserInputService")
    
    titleBar.InputBegan:Connect(function(input)
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
    
    userInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- ==========================================
    -- MINIMIZE FUNCTIONALITY
    -- ==========================================
    local minimized = false
    local originalSize = mainFrame.Size
    
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        
        if minimized then
            game:GetService("TweenService"):Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Size = UDim2.new(0, 340, 0, 45)
            }):Play()
            contentFrame.Visible = false
            minimizeBtn.Text = "+"
        else
            contentFrame.Visible = true
            game:GetService("TweenService"):Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Size = originalSize
            }):Play()
            minimizeBtn.Text = "—"
        end
    end)
    
    -- ==========================================
    -- Store references for event binding
    -- ==========================================
    local guiRefs = {
        screenGui = screenGui,
        mainFrame = mainFrame,
        statusText = statusText,
        progressBar = progressBar,
        statsLabel = statsLabel,
        buttons = {
            fullGame = btnFullGame,
            fullModel = btnFullModel,
            terrain = btnTerrain,
            save = btnSave,
            exit = btnExit
        }
    }
    
    -- Parent the GUI
    screenGui.Parent = playerGui
    
    return guiRefs
end

--- Cập nhật status text trên UI
function UI.updateStatus(guiRefs, text, color)
    if guiRefs and guiRefs.statusText then
        guiRefs.statusText.Text = text or ""
        if color then
            guiRefs.statusText.TextColor3 = color
        end
    end
end

--- Cập nhật progress bar
function UI.updateProgress(guiRefs, progress)
    if guiRefs and guiRefs.progressBar then
        local targetSize = UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0)
        game:GetService("TweenService"):Create(
            guiRefs.progressBar,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad),
            {Size = targetSize}
        ):Play()
    end
end

--- Cập nhật stats label
function UI.updateStats(guiRefs)
    if guiRefs and guiRefs.statsLabel then
        local stats = BaoSaveInstance._state.stats
        guiRefs.statsLabel.Text = string.format(
            "Instances: %d | Scripts: %d | File: %s",
            stats.totalInstances,
            stats.scriptsDecompiled,
            Util.formatBytes(stats.fileSize)
        )
    end
end

--- Disable/Enable tất cả buttons
function UI.setButtonsEnabled(guiRefs, enabled)
    if guiRefs and guiRefs.buttons then
        for _, btn in pairs(guiRefs.buttons) do
            btn.Active = enabled
            if not enabled then
                btn.BackgroundTransparency = 0.5
            else
                btn.BackgroundTransparency = 0
            end
        end
    end
end

--- Animate loading trên progress bar
function UI.startLoadingAnimation(guiRefs)
    local animating = true
    
    task.spawn(function()
        while animating and guiRefs and guiRefs.progressBar do
            -- Pulse animation
            game:GetService("TweenService"):Create(
                guiRefs.progressBar,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundColor3 = Color3.fromRGB(120, 180, 255)}
            ):Play()
            task.wait(0.8)
            
            if not animating then break end
            
            game:GetService("TweenService"):Create(
                guiRefs.progressBar,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundColor3 = Color3.fromRGB(80, 120, 255)}
            ):Play()
            task.wait(0.8)
        end
    end)
    
    return function()
        animating = false
    end
end

-- ============================================================
-- SECTION 13: EVENT BINDING & MAIN CONTROLLER
-- ============================================================

local Controller = {}

--- Tạo status callback function bound đến UI
function Controller.createStatusCallback(guiRefs)
    return function(text)
        UI.updateStatus(guiRefs, text, Color3.fromRGB(100, 200, 255))
        BaoSaveInstance._state.statusText = text
    end
end

--- Handle Decompile Full Game button
function Controller.handleFullGame(guiRefs)
    if BaoSaveInstance._state.busy then
        UI.updateStatus(guiRefs, "⚠ Please wait, system is busy...", Color3.fromRGB(255, 200, 100))
        return
    end
    
    UI.setButtonsEnabled(guiRefs, false)
    UI.updateStatus(guiRefs, "🔄 Starting Full Game Decompile...", Color3.fromRGB(100, 200, 255))
    UI.updateProgress(guiRefs, 0)
    
    local stopAnim = UI.startLoadingAnimation(guiRefs)
    
    task.spawn(function()
        local statusCb = function(text)
            UI.updateStatus(guiRefs, text, Color3.fromRGB(100, 200, 255))
        end
        
        statusCb("Saving... Initializing...")
        UI.updateProgress(guiRefs, 0.05)
        
        -- Init
        BaoSaveInstance.init()
        UI.updateProgress(guiRefs, 0.1)
        
        -- Decompile scripts first
        statusCb("Decompile Scripts...")
        UI.updateProgress(guiRefs, 0.15)
        BaoSaveInstance.decompileScripts(statusCb)
        UI.updateProgress(guiRefs, 0.4)
        
        -- Export
        statusCb("Saving... Building RBXL...")
        UI.updateProgress(guiRefs, 0.5)
        
        local success, result = BaoSaveInstance.exportRBXL("FULL_GAME", statusCb)
        
        UI.updateProgress(guiRefs, 1)
        stopAnim()
        
        if success then
            UI.updateStatus(guiRefs, "Done ✓ Saved: " .. tostring(result), Color3.fromRGB(100, 255, 150))
            UI.updateStats(guiRefs)
        else
            UI.updateStatus(guiRefs, "✗ Failed: " .. tostring(result), Color3.fromRGB(255, 100, 100))
        end
        
        UI.setButtonsEnabled(guiRefs, true)
        
        -- Reset progress bar after 3 seconds
        task.wait(3)
        UI.updateProgress(guiRefs, 0)
    end)
end

--- Handle Decompile Full Model button
function Controller.handleFullModel(guiRefs)
    if BaoSaveInstance._state.busy then
        UI.updateStatus(guiRefs, "⚠ Please wait, system is busy...", Color3.fromRGB(255, 200, 100))
        return
    end
    
    UI.setButtonsEnabled(guiRefs, false)
    UI.updateStatus(guiRefs, "🔄 Starting Model Decompile...", Color3.fromRGB(100, 200, 255))
    UI.updateProgress(guiRefs, 0)
    
    local stopAnim = UI.startLoadingAnimation(guiRefs)
    
    task.spawn(function()
        local statusCb = function(text)
            UI.updateStatus(guiRefs, text, Color3.fromRGB(100, 200, 255))
        end
        
        BaoSaveInstance.init()
        UI.updateProgress(guiRefs, 0.1)
        
        statusCb("Decompile Scripts in models...")
        BaoSaveInstance.decompileScripts(statusCb)
        UI.updateProgress(guiRefs, 0.4)
        
        statusCb("Saving... Building Model RBXL...")
        UI.updateProgress(guiRefs, 0.5)
        
        local success, result = BaoSaveInstance.exportRBXL("MODEL_ONLY", statusCb)
        
        UI.updateProgress(guiRefs, 1)
        stopAnim()
        
        if success then
            UI.updateStatus(guiRefs, "Done ✓ Saved: " .. tostring(result), Color3.fromRGB(100, 255, 150))
            UI.updateStats(guiRefs)
        else
            UI.updateStatus(guiRefs, "✗ Failed: " .. tostring(result), Color3.fromRGB(255, 100, 100))
        end
        
        UI.setButtonsEnabled(guiRefs, true)
        task.wait(3)
        UI.updateProgress(guiRefs, 0)
    end)
end

--- Handle Decompile Terrain button
function Controller.handleTerrain(guiRefs)
    if BaoSaveInstance._state.busy then
        UI.updateStatus(guiRefs, "⚠ Please wait, system is busy...", Color3.fromRGB(255, 200, 100))
        return
    end
    
    UI.setButtonsEnabled(guiRefs, false)
    UI.updateStatus(guiRefs, "🔄 Starting Terrain Decompile...", Color3.fromRGB(100, 200, 255))
    UI.updateProgress(guiRefs, 0)
    
    local stopAnim = UI.startLoadingAnimation(guiRefs)
    
    task.spawn(function()
        local statusCb = function(text)
            UI.updateStatus(guiRefs, text, Color3.fromRGB(100, 200, 255))
        end
        
        BaoSaveInstance.init()
        UI.updateProgress(guiRefs, 0.1)
        
        statusCb("Saving... Reading terrain data...")
        UI.updateProgress(guiRefs, 0.2)
        
        local success, result = BaoSaveInstance.exportRBXL("TERRAIN_ONLY", statusCb)
        
        UI.updateProgress(guiRefs, 1)
        stopAnim()
        
        if success then
            UI.updateStatus(guiRefs, "Done ✓ Saved: " .. tostring(result), Color3.fromRGB(100, 255, 150))
            UI.updateStats(guiRefs)
        else
            UI.updateStatus(guiRefs, "✗ Failed: " .. tostring(result), Color3.fromRGB(255, 100, 100))
        end
        
        UI.setButtonsEnabled(guiRefs, true)
        task.wait(3)
        UI.updateProgress(guiRefs, 0)
    end)
end

--- Handle Save To .rbxl button (quick save with last/default mode)
function Controller.handleSave(guiRefs)
    if BaoSaveInstance._state.busy then
        UI.updateStatus(guiRefs, "⚠ Please wait, system is busy...", Color3.fromRGB(255, 200, 100))
        return
    end
    
    -- Default to FULL_GAME nếu chưa có mode
    local mode = BaoSaveInstance._state.currentMode or "FULL_GAME"
    
    UI.setButtonsEnabled(guiRefs, false)
    UI.updateStatus(guiRefs, "🔄 Quick Save (" .. mode .. ")...", Color3.fromRGB(100, 200, 255))
    UI.updateProgress(guiRefs, 0)
    
    local stopAnim = UI.startLoadingAnimation(guiRefs)
    
    task.spawn(function()
        local statusCb = function(text)
            UI.updateStatus(guiRefs, text, Color3.fromRGB(100, 200, 255))
        end
        
        BaoSaveInstance.init()
        
        -- Nếu có native saveinstance, dùng luôn
        if NativeSaver.isAvailable() then
            local gameName = Util.getGameName()
            local fileName = gameName .. "_Full" .. BaoSaveInstance._config.fileExtension
            
            statusCb("Saving... Using native saveinstance...")
            UI.updateProgress(guiRefs, 0.3)
            
            local success, result = NativeSaver.save("FULL_GAME", fileName, statusCb)
            
            UI.updateProgress(guiRefs, 1)
            stopAnim()
            
            if success then
                UI.updateStatus(guiRefs, "Done ✓ " .. fileName, Color3.fromRGB(100, 255, 150))
            else
                -- Fallback to custom
                statusCb("Native failed, using custom serializer...")
                local ok2, res2 = BaoSaveInstance.exportRBXL(mode, statusCb)
                if ok2 then
                    UI.updateStatus(guiRefs, "Done ✓ " .. tostring(res2), Color3.fromRGB(100, 255, 150))
                else
                    UI.updateStatus(guiRefs, "✗ Failed: " .. tostring(res2), Color3.fromRGB(255, 100, 100))
                end
            end
        else
            -- Custom serializer
            local success, result = BaoSaveInstance.exportRBXL(mode, statusCb)
            
            UI.updateProgress(guiRefs, 1)
            stopAnim()
            
            if success then
                UI.updateStatus(guiRefs, "Done ✓ " .. tostring(result), Color3.fromRGB(100, 255, 150))
            else
                UI.updateStatus(guiRefs, "✗ Failed: " .. tostring(result), Color3.fromRGB(255, 100, 100))
            end
        end
        
        UI.updateStats(guiRefs)
        UI.setButtonsEnabled(guiRefs, true)
        task.wait(3)
        UI.updateProgress(guiRefs, 0)
    end)
end

--- Handle Exit button
function Controller.handleExit(guiRefs)
    if guiRefs and guiRefs.screenGui then
        -- Animate out
        game:GetService("TweenService"):Create(
            guiRefs.mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }
        ):Play()
        
        task.wait(0.35)
        guiRefs.screenGui:Destroy()
        
        -- Cleanup
        BaoSaveInstance.reset()
    end
end

--- Bind tất cả events
function Controller.bindEvents(guiRefs)
    local buttons = guiRefs.buttons
    
    buttons.fullGame.MouseButton1Click:Connect(function()
        Controller.handleFullGame(guiRefs)
    end)
    
    buttons.fullModel.MouseButton1Click:Connect(function()
        Controller.handleFullModel(guiRefs)
    end)
    
    buttons.terrain.MouseButton1Click:Connect(function()
        Controller.handleTerrain(guiRefs)
    end)
    
    buttons.save.MouseButton1Click:Connect(function()
        Controller.handleSave(guiRefs)
    end)
    
    buttons.exit.MouseButton1Click:Connect(function()
        Controller.handleExit(guiRefs)
    end)
end

-- ============================================================
-- SECTION 14: ENHANCED SAVEINSTANCE USING EXECUTOR NATIVES
-- Override exportRBXL to prefer executor's saveinstance
-- ============================================================

--- Enhanced export sử dụng tối ưu executor functions
function BaoSaveInstance.enhancedExport(mode, statusCallback)
    -- Kiểm tra các hàm executor phổ biến
    local hasSaveInstance = saveinstance ~= nil
    local hasSynSave = syn ~= nil and syn.saveinstance ~= nil
    local hasUnifiedSave = (unified ~= nil and unified.saveinstance ~= nil)
    
    local gameName = Util.getGameName()
    
    if mode == "FULL_GAME" then
        local fileName = gameName .. "_Full.rbxl"
        local options = {
            -- Unified SaveInstance format (tương thích nhiều executor)
            FileName = fileName,
            Object = game,
            
            -- Decompile options
            Decompile = true,
            DecompileTimeout = BaoSaveInstance._config.decompileTimeout,
            DecompileIgnore = {"Chat", "CoreGui", "CorePackages"},
            
            -- What to save
            NilInstances = true,
            NilInstancesFixes = true,
            
            -- Removal options
            RemovePlayerCharacters = true,
            SavePlayers = false,
            RemovePlayers = true,
            
            -- Isolated container handling
            IsolateStarterPlayer = true,
            IsolateLocalPlayer = false,
            IsolateLocalPlayerCharacter = true,
            
            -- Script handling
            SaveNonCreatable = false,
            IgnoreDefaultProperties = true,
            IgnoreNotAccessible = true,
            IgnorePropertiesOfNotScriptable = false,
            
            -- Binary format for smaller file
            Binary = false,  -- XML format cho compatibility
            
            -- Callback
            ShowStatus = true,
            StatusCallback = statusCallback,
            
            -- Ensure .rbxl output
            Mode = "optimized",
            FilePath = BaoSaveInstance._config.outputFolder .. "/" .. fileName
        }
        
        -- Try different executor APIs
        if hasSynSave then
            if statusCallback then statusCallback("Using Synapse saveinstance...") end
            local ok, err = pcall(syn.saveinstance, options)
            if ok then return true, fileName end
        end
        
        if hasSaveInstance then
            if statusCallback then statusCallback("Using saveinstance...") end
            local ok, err = pcall(saveinstance, options)
            if ok then return true, fileName end
        end
        
        if hasUnifiedSave then
            if statusCallback then statusCallback("Using unified saveinstance...") end
            local ok, err = pcall(unified.saveinstance, options)
            if ok then return true, fileName end
        end
    end
    
    -- Nếu không có native, dùng custom
    return BaoSaveInstance.exportRBXL(mode, statusCallback)
end

-- ============================================================
-- SECTION 15: STARTUP / MAIN ENTRY POINT
-- ============================================================

local function main()
    print("╔══════════════════════════════════════════╗")
    print("║     BaoSaveInstance v" .. BaoSaveInstance._VERSION .. " Loading...     ║")
    print("╚══════════════════════════════════════════╝")
    
    -- Initialize
    BaoSaveInstance.init()
    
    -- Create UI
    local guiRefs = UI.create()
    
    if not guiRefs then
        warn("[BaoSaveInstance] Failed to create UI!")
        return
    end
    
    -- Bind events
    Controller.bindEvents(guiRefs)
    
    -- Show welcome
    UI.updateStatus(guiRefs, "✓ Ready! Select an action below.", Color3.fromRGB(100, 255, 150))
    
    print("[BaoSaveInstance] Successfully loaded!")
    print("[BaoSaveInstance] Game: " .. Util.getGameName())
    print("[BaoSaveInstance] PlaceId: " .. tostring(game.PlaceId))
    
    -- Export API to global
    getgenv().BaoSaveInstance = BaoSaveInstance
    
    return BaoSaveInstance
end

-- ============================================================
-- SECTION 16: EXPORT MODULE + RUN
-- ============================================================

-- Module export cho external use
BaoSaveInstance.UI = UI
BaoSaveInstance.Util = Util
BaoSaveInstance.Serializer = Serializer
BaoSaveInstance.ScriptDecompiler = ScriptDecompiler
BaoSaveInstance.TerrainSerializer = TerrainSerializer
BaoSaveInstance.RBXLBuilder = RBXLBuilder
BaoSaveInstance.FileWriter = FileWriter
BaoSaveInstance.NativeSaver = NativeSaver
BaoSaveInstance.PropertyDB = PropertyDB
BaoSaveInstance.Controller = Controller

-- Auto-run
main()

return BaoSaveInstance
