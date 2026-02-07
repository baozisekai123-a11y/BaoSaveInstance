--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              BaoSaveInstance - Event API                     ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local Event = {}

--// Storage
local Events = {}

--// Create new event
function Event.Create(eventName)
    if Events[eventName] then
        return Events[eventName]
    end
    
    local event = {
        Name = eventName,
        Listeners = {},
        Once = {},
    }
    
    Events[eventName] = event
    return event
end

--// Register listener
function Event.On(eventName, callback, priority)
    priority = priority or 0
    
    local event = Events[eventName] or Event.Create(eventName)
    
    local id = string.format("listener_%s_%s", os.time(), math.random(10000, 99999))
    
    local listener = {
        Callback = callback,
        Priority = priority,
        ID = id,
    }
    
    table.insert(event.Listeners, listener)
    
    -- Sort by priority (higher first)
    table.sort(event.Listeners, function(a, b)
        return a.Priority > b.Priority
    end)
    
    return id
end

--// Register one-time listener
function Event.Once(eventName, callback, priority)
    priority = priority or 0
    
    local event = Events[eventName] or Event.Create(eventName)
    
    local id = string.format("once_%s_%s", os.time(), math.random(10000, 99999))
    
    local listener = {
        Callback = callback,
        Priority = priority,
        ID = id,
    }
    
    table.insert(event.Once, listener)
    
    -- Sort by priority
    table.sort(event.Once, function(a, b)
        return a.Priority > b.Priority
    end)
    
    return id
end

--// Remove listener
function Event.Off(eventName, listenerID)
    local event = Events[eventName]
    if not event then return false end
    
    -- Check regular listeners
    for i, listener in ipairs(event.Listeners) do
        if listener.ID == listenerID then
            table.remove(event.Listeners, i)
            return true
        end
    end
    
    -- Check once listeners
    for i, listener in ipairs(event.Once) do
        if listener.ID == listenerID then
            table.remove(event.Once, i)
            return true
        end
    end
    
    return false
end

--// Emit event
function Event.Emit(eventName, ...)
    local event = Events[eventName]
    if not event then return {} end
    
    local args = {...}
    local results = {}
    
    -- Run regular listeners
    for _, listener in ipairs(event.Listeners) do
        local success, result = pcall(listener.Callback, unpack(args))
        if success then
            table.insert(results, result)
        end
    end
    
    -- Run once listeners
    for _, listener in ipairs(event.Once) do
        local success, result = pcall(listener.Callback, unpack(args))
        if success then
            table.insert(results, result)
        end
    end
    
    -- Clear once listeners
    event.Once = {}
    
    return results
end

--// Clear all listeners for event
function Event.Clear(eventName)
    if Events[eventName] then
        Events[eventName].Listeners = {}
        Events[eventName].Once = {}
        return true
    end
    return false
end

--// Remove event entirely
function Event.Remove(eventName)
    if Events[eventName] then
        Events[eventName] = nil
        return true
    end
    return false
end

--// List all events
function Event.List()
    local list = {}
    for name, event in pairs(Events) do
        table.insert(list, {
            Name = name,
            ListenerCount = #event.Listeners,
            OnceCount = #event.Once,
        })
    end
    return list
end

--// Get listener count
function Event.GetListenerCount(eventName)
    local event = Events[eventName]
    if not event then return 0 end
    return #event.Listeners + #event.Once
end

--// Check if event exists
function Event.Exists(eventName)
    return Events[eventName] ~= nil
end

--// Create built-in events
Event.Create("BeforeSave")
Event.Create("AfterSave")
Event.Create("SaveProgress")
Event.Create("SaveError")
Event.Create("BeforeSerialize")
Event.Create("AfterSerialize")
Event.Create("PluginLoaded")
Event.Create("PluginUnloaded")
Event.Create("ConfigChanged")
Event.Create("GUICreated")
Event.Create("GUIDestroyed")

return Event
