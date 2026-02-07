--[[
    BaoSaveInstance API Framework
    File: API/EventAPI.lua
    Description: Event System
]]

local EventAPI = {}

--// ═══════════════════════════════════════════════════════════════════════════
--// INTERNAL STATE
--// ═══════════════════════════════════════════════════════════════════════════

local Events = {}
local EventCounter = 0

--// ═══════════════════════════════════════════════════════════════════════════
--// HELPER FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════

local function GenerateID()
    EventCounter = EventCounter + 1
    return "evt_" .. os.time() .. "_" .. EventCounter
end

--// ═══════════════════════════════════════════════════════════════════════════
--// PUBLIC API
--// ═══════════════════════════════════════════════════════════════════════════

-- Create new event
function EventAPI.Create(eventName)
    if Events[eventName] then
        return Events[eventName]
    end
    
    local event = {
        Name = eventName,
        Listeners = {},
        OnceListeners = {},
        Enabled = true,
        CreatedAt = os.time(),
    }
    
    Events[eventName] = event
    return event
end

-- Register listener
function EventAPI.On(eventName, callback, priority)
    if type(callback) ~= "function" then
        return nil, "Callback must be a function"
    end
    
    priority = priority or 0
    
    local event = Events[eventName] or EventAPI.Create(eventName)
    
    local listener = {
        ID = GenerateID(),
        Callback = callback,
        Priority = priority,
        Enabled = true,
        CreatedAt = os.time(),
    }
    
    table.insert(event.Listeners, listener)
    
    -- Sort by priority (higher first)
    table.sort(event.Listeners, function(a, b)
        return a.Priority > b.Priority
    end)
    
    return listener.ID
end

-- Register one-time listener
function EventAPI.Once(eventName, callback, priority)
    if type(callback) ~= "function" then
        return nil, "Callback must be a function"
    end
    
    priority = priority or 0
    
    local event = Events[eventName] or EventAPI.Create(eventName)
    
    local listener = {
        ID = GenerateID(),
        Callback = callback,
        Priority = priority,
    }
    
    table.insert(event.OnceListeners, listener)
    
    -- Sort by priority
    table.sort(event.OnceListeners, function(a, b)
        return a.Priority > b.Priority
    end)
    
    return listener.ID
end

-- Remove listener
function EventAPI.Off(eventName, listenerID)
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
    for i, listener in ipairs(event.OnceListeners) do
        if listener.ID == listenerID then
            table.remove(event.OnceListeners, i)
            return true
        end
    end
    
    return false
end

-- Emit event
function EventAPI.Emit(eventName, ...)
    local event = Events[eventName]
    if not event or not event.Enabled then
        return {}
    end
    
    local args = {...}
    local results = {}
    
    -- Run regular listeners
    for _, listener in ipairs(event.Listeners) do
        if listener.Enabled then
            local success, result = pcall(listener.Callback, unpack(args))
            if success then
                table.insert(results, result)
            else
                -- Log error but continue
                warn("[EventAPI] Listener error: " .. tostring(result))
            end
        end
    end
    
    -- Run once listeners
    for _, listener in ipairs(event.OnceListeners) do
        local success, result = pcall(listener.Callback, unpack(args))
        if success then
            table.insert(results, result)
        end
    end
    
    -- Clear once listeners
    event.OnceListeners = {}
    
    return results
end

-- Emit async (doesn't wait for results)
function EventAPI.EmitAsync(eventName, ...)
    local args = {...}
    task.spawn(function()
        EventAPI.Emit(eventName, unpack(args))
    end)
end

-- Enable/Disable listener
function EventAPI.SetListenerEnabled(eventName, listenerID, enabled)
    local event = Events[eventName]
    if not event then return false end
    
    for _, listener in ipairs(event.Listeners) do
        if listener.ID == listenerID then
            listener.Enabled = enabled
            return true
        end
    end
    
    return false
end

-- Enable/Disable event
function EventAPI.SetEventEnabled(eventName, enabled)
    local event = Events[eventName]
    if event then
        event.Enabled = enabled
        return true
    end
    return false
end

-- Clear all listeners for event
function EventAPI.Clear(eventName)
    local event = Events[eventName]
    if event then
        event.Listeners = {}
        event.OnceListeners = {}
        return true
    end
    return false
end

-- Clear all events
function EventAPI.ClearAll()
    Events = {}
    EventCounter = 0
end

-- Get event info
function EventAPI.GetEvent(eventName)
    local event = Events[eventName]
    if not event then return nil end
    
    return {
        Name = event.Name,
        ListenerCount = #event.Listeners,
        OnceListenerCount = #event.OnceListeners,
        Enabled = event.Enabled,
        CreatedAt = event.CreatedAt,
    }
end

-- List all events
function EventAPI.List()
    local list = {}
    for name, event in pairs(Events) do
        table.insert(list, {
            Name = name,
            ListenerCount = #event.Listeners + #event.OnceListeners,
            Enabled = event.Enabled,
        })
    end
    return list
end

-- Get listener count for event
function EventAPI.GetListenerCount(eventName)
    local event = Events[eventName]
    if not event then return 0 end
    return #event.Listeners + #event.OnceListeners
end

-- Check if event exists
function EventAPI.Exists(eventName)
    return Events[eventName] ~= nil
end

-- Wait for event (yields until event is emitted)
function EventAPI.Wait(eventName, timeout)
    timeout = timeout or 30
    
    local result = nil
    local received = false
    
    local id = EventAPI.Once(eventName, function(...)
        result = {...}
        received = true
    end)
    
    local elapsed = 0
    while not received and elapsed < timeout do
        task.wait(0.1)
        elapsed = elapsed + 0.1
    end
    
    if not received then
        EventAPI.Off(eventName, id)
        return nil, "Timeout"
    end
    
    return unpack(result or {})
end

--// ═══════════════════════════════════════════════════════════════════════════
--// BUILT-IN EVENTS
--// ═══════════════════════════════════════════════════════════════════════════

-- Create built-in events
EventAPI.Create("BeforeSave")
EventAPI.Create("AfterSave")
EventAPI.Create("SaveProgress")
EventAPI.Create("SaveError")
EventAPI.Create("SaveCancelled")

EventAPI.Create("BeforeSerialize")
EventAPI.Create("AfterSerialize")

EventAPI.Create("BeforeDecompile")
EventAPI.Create("AfterDecompile")
EventAPI.Create("DecompileFailed")

EventAPI.Create("PluginLoaded")
EventAPI.Create("PluginUnloaded")
EventAPI.Create("PluginError")

EventAPI.Create("ConfigChanged")

EventAPI.Create("GUIOpened")
EventAPI.Create("GUIClosed")
EventAPI.Create("GUICreated")

EventAPI.Create("Error")
EventAPI.Create("Warning")
EventAPI.Create("Info")

return EventAPI
