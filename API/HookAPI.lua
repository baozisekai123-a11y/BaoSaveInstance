--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              BaoSaveInstance - Hook/Middleware API           ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local Hook = {}
local Middleware = {}

--// Storage
local Hooks = {}

--// Register hook
function Hook.Register(hookName, callback, priority)
    priority = priority or 0
    
    if not Hooks[hookName] then
        Hooks[hookName] = {}
    end
    
    local id = string.format("hook_%s_%s", os.time(), math.random(10000, 99999))
    
    local hook = {
        Callback = callback,
        Priority = priority,
        ID = id,
        Enabled = true,
    }
    
    table.insert(Hooks[hookName], hook)
    
    -- Sort by priority (higher first)
    table.sort(Hooks[hookName], function(a, b)
        return a.Priority > b.Priority
    end)
    
    return id
end

--// Unregister hook
function Hook.Unregister(hookName, hookID)
    local hooks = Hooks[hookName]
    if not hooks then return false end
    
    for i, hook in ipairs(hooks) do
        if hook.ID == hookID then
            table.remove(hooks, i)
            return true
        end
    end
    
    return false
end

--// Run hooks (pipeline style - each hook can modify data)
function Hook.Run(hookName, data)
    local hooks = Hooks[hookName]
    if not hooks then return data end
    
    local result = data
    
    for _, hook in ipairs(hooks) do
        if hook.Enabled then
            local success, newResult = pcall(hook.Callback, result)
            if success and newResult ~= nil then
                result = newResult
            end
        end
    end
    
    return result
end

--// Enable/Disable hook
function Hook.SetEnabled(hookName, hookID, enabled)
    local hooks = Hooks[hookName]
    if not hooks then return false end
    
    for _, hook in ipairs(hooks) do
        if hook.ID == hookID then
            hook.Enabled = enabled
            return true
        end
    end
    
    return false
end

--// Get hook count
function Hook.Count(hookName)
    local hooks = Hooks[hookName]
    return hooks and #hooks or 0
end

--// List hooks
function Hook.List(hookName)
    if hookName then
        return Hooks[hookName] or {}
    end
    
    local list = {}
    for name, hooks in pairs(Hooks) do
        list[name] = #hooks
    end
    return list
end

--// Clear hooks
function Hook.Clear(hookName)
    if hookName then
        Hooks[hookName] = {}
    else
        Hooks = {}
    end
    return true
end

--// ═══════════════════════════════════════════════════════════════
--// MIDDLEWARE (wrapper for hooks with "middleware:" prefix)
--// ═══════════════════════════════════════════════════════════════

function Middleware.Use(name, handler, priority)
    return Hook.Register("middleware:" .. name, handler, priority)
end

function Middleware.Remove(name, middlewareID)
    return Hook.Unregister("middleware:" .. name, middlewareID)
end

function Middleware.Execute(name, data)
    return Hook.Run("middleware:" .. name, data)
end

function Middleware.List()
    local list = {}
    for hookName, hooks in pairs(Hooks) do
        if hookName:sub(1, 11) == "middleware:" then
            local name = hookName:sub(12)
            list[name] = #hooks
        end
    end
    return list
end

return {
    Hook = Hook,
    Middleware = Middleware,
}