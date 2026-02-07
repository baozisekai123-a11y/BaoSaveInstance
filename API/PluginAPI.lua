--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              BaoSaveInstance - Plugin API                    ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local Plugin = {}

--// Storage
local Plugins = {}

--// Plugin template
local PluginTemplate = {
    Name = "Unnamed Plugin",
    Version = "1.0.0",
    Author = "Unknown",
    Description = "",
    Enabled = true,
    
    OnLoad = function(self, api) end,
    OnUnload = function(self, api) end,
    OnSave = function(self, api, data) end,
    OnError = function(self, api, error) end,
}

--// Register plugin
function Plugin.Register(plugin)
    if type(plugin) ~= "table" then
        return false, "Plugin must be a table"
    end
    
    if not plugin.Name then
        return false, "Plugin must have a Name"
    end
    
    if Plugins[plugin.Name] then
        return false, "Plugin already exists: " .. plugin.Name
    end
    
    -- Apply template defaults
    for key, value in pairs(PluginTemplate) do
        if plugin[key] == nil then
            plugin[key] = value
        end
    end
    
    -- Generate ID
    plugin.ID = string.format("plugin_%s_%s", os.time(), math.random(10000, 99999))
    plugin.LoadedAt = os.time()
    
    Plugins[plugin.Name] = plugin
    
    -- Call OnLoad
    local success, err = pcall(plugin.OnLoad, plugin, _G.BaoAPI)
    if not success then
        warn("[BaoAPI] Plugin load error: " .. tostring(err))
    end
    
    return true, plugin.ID
end

--// Unregister plugin
function Plugin.Unregister(pluginName)
    local plugin = Plugins[pluginName]
    if not plugin then
        return false, "Plugin not found"
    end
    
    -- Call OnUnload
    pcall(plugin.OnUnload, plugin, _G.BaoAPI)
    
    Plugins[pluginName] = nil
    
    return true
end

--// Get plugin
function Plugin.Get(pluginName)
    return Plugins[pluginName]
end

--// List all plugins
function Plugin.List()
    local list = {}
    for name, plugin in pairs(Plugins) do
        table.insert(list, {
            Name = name,
            Version = plugin.Version,
            Author = plugin.Author,
            Enabled = plugin.Enabled,
            ID = plugin.ID,
        })
    end
    return list
end

--// Enable/Disable plugin
function Plugin.SetEnabled(pluginName, enabled)
    local plugin = Plugins[pluginName]
    if plugin then
        plugin.Enabled = enabled
        return true
    end
    return false
end

--// Call plugin method
function Plugin.Call(pluginName, methodName, ...)
    local plugin = Plugins[pluginName]
    if plugin and plugin.Enabled and type(plugin[methodName]) == "function" then
        return pcall(plugin[methodName], plugin, _G.BaoAPI, ...)
    end
    return false, "Plugin or method not found"
end

--// Broadcast to all plugins
function Plugin.Broadcast(methodName, ...)
    local results = {}
    for name, plugin in pairs(Plugins) do
        if plugin.Enabled and type(plugin[methodName]) == "function" then
            local success, result = pcall(plugin[methodName], plugin, _G.BaoAPI, ...)
            results[name] = {Success = success, Result = result}
        end
    end
    return results
end

--// Count plugins
function Plugin.Count()
    local count = 0
    for _ in pairs(Plugins) do
        count = count + 1
    end
    return count
end

--// Check if plugin exists
function Plugin.Exists(pluginName)
    return Plugins[pluginName] ~= nil
end

return Plugin