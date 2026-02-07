--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              BaoSaveInstance - Serializer API                ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local Serializer = {}

--// Custom serializers storage
local CustomSerializers = {}

--// Built-in serializers
local BuiltInSerializers = {
    ["string"] = function(value)
        return tostring(value):gsub("[<>&\"']", {
            ["<"] = "&lt;",
            [">"] = "&gt;",
            ["&"] = "&amp;",
            ['"'] = "&quot;",
            ["'"] = "&apos;",
        })
    end,
    
    ["number"] = function(value)
        if value ~= value then return "0" end -- NaN
        if value == math.huge then return "INF" end
        if value == -math.huge then return "-INF" end
        return tostring(value)
    end,
    
    ["boolean"] = function(value)
        return value and "true" or "false"
    end,
    
    ["Vector3"] = function(value)
        return string.format("%s, %s, %s", value.X, value.Y, value.Z)
    end,
    
    ["Vector2"] = function(value)
        return string.format("%s, %s", value.X, value.Y)
    end,
    
    ["CFrame"] = function(value)
        return table.concat({value:GetComponents()}, ", ")
    end,
    
    ["Color3"] = function(value)
        return string.format("%s, %s, %s", value.R, value.G, value.B)
    end,
    
    ["BrickColor"] = function(value)
        return tostring(value.Number)
    end,
    
    ["UDim2"] = function(value)
        return string.format("%s, %s, %s, %s",
            value.X.Scale, value.X.Offset,
            value.Y.Scale, value.Y.Offset)
    end,
    
    ["UDim"] = function(value)
        return string.format("%s, %s", value.Scale, value.Offset)
    end,
    
    ["Rect"] = function(value)
        return string.format("%s, %s, %s, %s",
            value.Min.X, value.Min.Y,
            value.Max.X, value.Max.Y)
    end,
    
    ["Enum"] = function(value)
        return tostring(value)
    end,
    
    ["EnumItem"] = function(value)
        return tostring(value.Value)
    end,
    
    ["NumberRange"] = function(value)
        return string.format("%s, %s", value.Min, value.Max)
    end,
    
    ["NumberSequence"] = function(value)
        local points = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(points, string.format("%s %s %s", kp.Time, kp.Value, kp.Envelope))
        end
        return table.concat(points, " ")
    end,
    
    ["ColorSequence"] = function(value)
        local points = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(points, string.format("%s %s %s %s",
                kp.Time, kp.Value.R, kp.Value.G, kp.Value.B))
        end
        return table.concat(points, " ")
    end,
    
    ["Ray"] = function(value)
        return string.format("%s, %s, %s, %s, %s, %s",
            value.Origin.X, value.Origin.Y, value.Origin.Z,
            value.Direction.X, value.Direction.Y, value.Direction.Z)
    end,
    
    ["Faces"] = function(value)
        local faces = {}
        if value.Top then table.insert(faces, "Top") end
        if value.Bottom then table.insert(faces, "Bottom") end
        if value.Left then table.insert(faces, "Left") end
        if value.Right then table.insert(faces, "Right") end
        if value.Back then table.insert(faces, "Back") end
        if value.Front then table.insert(faces, "Front") end
        return table.concat(faces, ", ")
    end,
    
    ["Axes"] = function(value)
        local axes = {}
        if value.X then table.insert(axes, "X") end
        if value.Y then table.insert(axes, "Y") end
        if value.Z then table.insert(axes, "Z") end
        return table.concat(axes, ", ")
    end,
}

--// Register custom serializer
function Serializer.Register(typeName, serializer)
    if type(serializer) ~= "function" then
        return false, "Serializer must be a function"
    end
    
    CustomSerializers[typeName] = serializer
    return true
end

--// Unregister serializer
function Serializer.Unregister(typeName)
    CustomSerializers[typeName] = nil
    return true
end

--// Get serializer for type
function Serializer.Get(typeName)
    return CustomSerializers[typeName] or BuiltInSerializers[typeName]
end

--// Serialize value
function Serializer.Serialize(value)
    local valueType = typeof(value)
    local serializer = Serializer.Get(valueType)
    
    if serializer then
        local success, result = pcall(serializer, value)
        if success then
            return result, valueType
        end
    end
    
    return tostring(value), valueType
end

--// Serialize instance properties
function Serializer.SerializeInstance(instance, propertyList)
    local properties = {}
    
    propertyList = propertyList or Serializer.GetCommonProperties(instance)
    
    for _, propName in ipairs(propertyList) do
        local success, value = pcall(function()
            return instance[propName]
        end)
        
        if success and value ~= nil then
            local serialized, valueType = Serializer.Serialize(value)
            properties[propName] = {
                Value = serialized,
                Type = valueType,
            }
        end
    end
    
    return properties
end

--// Get common properties for instance
function Serializer.GetCommonProperties(instance)
    local properties = {"Name"}
    
    local classProps = {
        BasePart = {"Anchored", "CanCollide", "CFrame", "Size", "Color", "Material", "Transparency"},
        Model = {"PrimaryPart"},
        Script = {"Disabled"},
        LocalScript = {"Disabled"},
        ModuleScript = {},
        Humanoid = {"Health", "MaxHealth", "WalkSpeed", "JumpPower"},
        Sound = {"SoundId", "Volume", "Looped"},
        Decal = {"Texture", "Transparency", "Face"},
        PointLight = {"Enabled", "Brightness", "Color", "Range"},
        SpotLight = {"Enabled", "Brightness", "Color", "Range", "Angle"},
        SurfaceLight = {"Enabled", "Brightness", "Color", "Range", "Angle"},
        Attachment = {"CFrame", "Visible"},
        WeldConstraint = {"Enabled", "Part0", "Part1"},
        Motor6D = {"C0", "C1", "Part0", "Part1"},
        Weld = {"C0", "C1", "Part0", "Part1"},
    }
    
    for className, props in pairs(classProps) do
        local success = pcall(function()
            return instance:IsA(className)
        end)
        
        if success and instance:IsA(className) then
            for _, prop in ipairs(props) do
                table.insert(properties, prop)
            end
        end
    end
    
    return properties
end

--// List all serializers
function Serializer.List()
    local list = {}
    
    for typeName, _ in pairs(BuiltInSerializers) do
        table.insert(list, {Name = typeName, Custom = false})
    end
    
    for typeName, _ in pairs(CustomSerializers) do
        table.insert(list, {Name = typeName, Custom = true})
    end
    
    return list
end

--// Check if serializer exists
function Serializer.Exists(typeName)
    return CustomSerializers[typeName] ~= nil or BuiltInSerializers[typeName] ~= nil
end

return Serializer