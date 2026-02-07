--[[
    BaoSaveInstance API Framework
    File: API/HookAPI.lua
    Description: Hook/Middleware System
]]

local HookAPI = {}

--// ═══════════════════════════════════════════════════════════════════════════
--// INTERNAL STATE
--// ═══════════════════════════════════════════════════════════════════════════

local Hooks = {}
local HookCounter = 0

--// ═══════════════════════════════════════════════════════════════════════════
--// HELPER FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════

local function GenerateID()
    HookCounter = HookCounter + 1
    return "hook_" .. os.time() .. "_" .. HookCounter
end

--// ═══════════════════════════════════════════════════════════════════════════
--// HOOK API
--// ═══════════════════════════════════════════════════════════════════════════

-- Register hook
function HookAPI.Register(hookName, callback, priority)
    if type(callback) ~= "function" then
        return nil, "Callback must be a function"
    end
    
    priority = priority or 0
    
    if not Hooks[hookName] then
        Hooks[hookName] = {}
    end
    
    local hook = {
        ID = GenerateID(),
        Callback = callback,
        Priority = priority,
        Enabled = true,
        CreatedAt = os.time(),
    }
    
    table.insert(Hooks[hookName], hook)
    
    -- Sort by priority (higher first)
    table.sort(Hooks[hookName], function(a, b)
        return a.Priority > b.Priority
    end)
    
    return hook.ID
end

-- Unregister hook
function HookAPI.Unregister(hookName, hookID)
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

-- Run hooks (pipeline style - each hook modifies data)
function HookAPI.Run(hookName, data)
    local hooks = Hooks[hookName]
    if not hooks then return data end
    
    local result = data
    
    for _, hook in ipairs(hooks) do
        if hook.Enabled then
            local success, newResult = pcall(hook.Callback, result)
            if success then
                if newResult ~= nil then
                    result = newResult
                end
            else
                warn("[HookAPI] Hook error in '" .. hookName .. "': " .. tostring(newResult))
            end
        end
    end
    
    return result
end

-- Run hooks (filter style - each hook can modify or skip)
function HookAPI.Filter(hookName, data)
    local hooks = Hooks[hookName]
    if not hooks then return data, true end
    
    local result = data
    local shouldContinue = true
    
    for _, hook in ipairs(hooks) do
        if hook.Enabled then
            local success, newResult, skip = pcall(hook.Callback, result)
            if success then
                if skip == true then
                    shouldContinue = false
                    break
                end
                if newResult ~= nil then
                    result = newResult
                end
            end
        end
    end
    
    return result, shouldContinue
end

-- Run hooks (parallel style - all hooks run independently)
function HookAPI.RunParallel(hookName, data)
    local hooks = Hooks[hookName]
    if not hooks then return {} end
    
    local results = {}
    
    for _, hook in ipairs(hooks) do
        if hook.Enabled then
            local success, result = pcall(hook.Callback, data)
            if success then
                table.insert(results, {
                    HookID = hook.ID,
                    Result = result,
                    Success = true,
                })
            else
                table.insert(results, {
                    HookID = hook.ID,
                    Error = result,
                    Success = false,
                })
            end
        end
    end
    
    return results
end

-- Enable/Disable hook
function HookAPI.SetEnabled(hookName, hookID, enabled)
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

-- Clear all hooks for name
function HookAPI.Clear(hookName)
    Hooks[hookName] = {}
    return true
end

-- Clear all hooks
function HookAPI.ClearAll()
    Hooks = {}
    HookCounter = 0
end

-- Get hooks for name
function HookAPI.Get(hookName)
    local hooks = Hooks[hookName]
    if not hooks then return {} end
    
    local list = {}
    for _, hook in ipairs(hooks) do
        table.insert(list, {
            ID = hook.ID,
            Priority = hook.Priority,
            Enabled = hook.Enabled,
            CreatedAt = hook.CreatedAt,
        })
    end
    
    return list
end

-- List all hook names
function HookAPI.List()
    local list = {}
    for name, hooks in pairs(Hooks) do
        table.insert(list, {
            Name = name,
            Count = #hooks,
        })
    end
    return list
end

-- Check if hook name exists
function HookAPI.Exists(hookName)
    return Hooks[hookName] ~= nil and #Hooks[hookName] > 0
end

-- Get hook count
function HookAPI.Count(hookName)
    local hooks = Hooks[hookName]
    return hooks and #hooks or 0
end

--// ═══════════════════════════════════════════════════════════════════════════
--// MIDDLEWARE API (Higher-level wrapper)
--// ═══════════════════════════════════════════════════════════════════════════

HookAPI.Middleware = {}

-- Use middleware
function HookAPI.Middleware.Use(name, handler, priority)
    return HookAPI.Register("middleware:" .. name, handler, priority)
end

-- Remove middleware
function HookAPI.Middleware.Remove(name, middlewareID)
    return HookAPI.Unregister("middleware:" .. name, middlewareID)
end

-- Execute middleware chain
function HookAPI.Middleware.Execute(name, data)
    return HookAPI.Run("middleware:" .. name, data)
end

-- List middleware
function HookAPI.Middleware.List(name)
    return HookAPI.Get("middleware:" .. name)
end

--// ═══════════════════════════════════════════════════════════════════════════
--// BUILT-IN HOOKS
--// ═══════════════════════════════════════════════════════════════════════════

-- Pre-define common hooks
Hooks["save:options"] = {}
Hooks["save:instance"] = {}
Hooks["save:complete"] = {}

Hooks["serialize:instance"] = {}
Hooks["serialize:property"] = {}
Hooks["serialize:script"] = {}

Hooks["decompile:before"] = {}
Hooks["decompile:after"] = {}

Hooks["terrain:chunk"] = {}

Hooks["middleware:save"] = {}
Hooks["middleware:serialize"] = {}

return HookAPI