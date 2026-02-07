--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              BaoSaveInstance - Script Handler API            ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local Script = {}

--// Markers
Script.Markers = {
    Protected = "--[[ PROTECTED/ENCRYPTED - Source unavailable ]]",
    Failed = "--[[ DECOMPILATION FAILED ]]",
    Unavailable = "--[[ SOURCE NOT AVAILABLE ]]",
}

--// Check decompile capability
function Script.CanDecompile()
    return decompile ~= nil or (syn and syn.decompile ~= nil) or getscriptsource ~= nil
end

--// Decompile script
function Script.Decompile(script)
    local source = nil
    local method = "none"
    local status = "failed"
    
    -- Method 1: Direct Source access
    local success1, result1 = pcall(function()
        return script.Source
    end)
    
    if success1 and result1 and #result1 > 0 then
        return result1, "direct", "success"
    end
    
    -- Method 2: decompile function
    if decompile then
        local success2, result2 = pcall(function()
            return decompile(script)
        end)
        
        if success2 and result2 and #result2 > 0 then
            return result2, "decompile", "success"
        end
    end
    
    -- Method 3: syn.decompile
    if syn and syn.decompile then
        local success3, result3 = pcall(function()
            return syn.decompile(script)
        end)
        
        if success3 and result3 and #result3 > 0 then
            return result3, "syn.decompile", "success"
        end
    end
    
    -- Method 4: getscriptsource
    if getscriptsource then
        local success4, result4 = pcall(function()
            return getscriptsource(script)
        end)
        
        if success4 and result4 and #result4 > 0 then
            return result4, "getscriptsource", "success"
        end
    end
    
    -- All methods failed
    return Script.Markers.Protected, method, status
end

--// Get script info
function Script.GetInfo(script)
    local source, method, status = Script.Decompile(script)
    
    local disabled = false
    pcall(function()
        disabled = script.Disabled
    end)
    
    return {
        Name = script.Name,
        ClassName = script.ClassName,
        FullName = script:GetFullName(),
        Source = source,
        Method = method,
        Status = status,
        Disabled = disabled,
        LineCount = source and select(2, source:gsub("\n", "\n")) + 1 or 0,
    }
end

--// Collect all scripts from instance
function Script.CollectAll(root, filter)
    root = root or game
    
    local scripts = {}
    local descendants = {}
    
    pcall(function()
        descendants = root:GetDescendants()
    end)
    
    for _, desc in ipairs(descendants) do
        local isScript = false
        pcall(function()
            isScript = desc:IsA("LuaSourceContainer")
        end)
        
        if isScript then
            local include = true
            
            if filter and type(filter) == "function" then
                include = filter(desc)
            end
            
            if include then
                table.insert(scripts, desc)
            end
        end
    end
    
    return scripts
end

--// Process scripts in batch
function Script.ProcessBatch(scripts, onProgress)
    local results = {}
    local total = #scripts
    
    for i, script in ipairs(scripts) do
        local info = Script.GetInfo(script)
        table.insert(results, info)
        
        if onProgress then
            onProgress(i, total, info)
        end
        
        if i % 10 == 0 then
            task.wait()
        end
    end
    
    return results
end

--// Check if script is default Roblox script
function Script.IsDefaultScript(script)
    local defaultPaths = {
        "PlayerScripts",
        "PlayerModule",
        "RbxCharacterSounds",
        "ChatScript",
        "BubbleChat",
        "ControlScript",
        "CameraScript",
    }
    
    local fullName = script:GetFullName()
    
    for _, path in ipairs(defaultPaths) do
        if fullName:find(path) then
            return true
        end
    end
    
    return false
end

--// Filter out default scripts
function Script.FilterDefaults(scripts)
    local filtered = {}
    
    for _, script in ipairs(scripts) do
        if not Script.IsDefaultScript(script) then
            table.insert(filtered, script)
        end
    end
    
    return filtered
end

--// Get script statistics
function Script.GetStats(scripts)
    local stats = {
        Total = #scripts,
        LocalScripts = 0,
        ModuleScripts = 0,
        Scripts = 0,
        Decompiled = 0,
        Failed = 0,
        TotalLines = 0,
    }
    
    for _, script in ipairs(scripts) do
        if script.ClassName == "LocalScript" then
            stats.LocalScripts = stats.LocalScripts + 1
        elseif script.ClassName == "ModuleScript" then
            stats.ModuleScripts = stats.ModuleScripts + 1
        elseif script.ClassName == "Script" then
            stats.Scripts = stats.Scripts + 1
        end
    end
    
    return stats
end

return Script