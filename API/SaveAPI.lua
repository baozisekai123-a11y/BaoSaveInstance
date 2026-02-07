--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              BaoSaveInstance - Save API (Core)               ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")

local Save = {}

--// Save modes
Save.Modes = {
    TERRAIN = "Terrain",
    SCRIPTS = "Scripts",
    MODEL = "Model",
    FULLMAP = "Full Map",
    ALL = "All",
}

--// Detect client
function Save.DetectClient()
    local info = {
        Name = "Unknown",
        Version = "Unknown",
        CanSave = false,
        CanBinary = false,
        CanDecompile = false,
    }
    
    if identifyexecutor then
        local name, version = identifyexecutor()
        info.Name = name or "Unknown"
        info.Version = version or "Unknown"
    end
    
    local lowerName = info.Name:lower()
    
    info.CanSave = saveinstance ~= nil or (syn and syn.saveinstance ~= nil)
    info.CanBinary = lowerName:find("synapse") ~= nil or lowerName:find("delta") ~= nil
    info.CanDecompile = decompile ~= nil or (syn and syn.decompile ~= nil)
    
    return info
end

--// Build save options
function Save.BuildOptions(mode, customOptions)
    local client = Save.DetectClient()
    
    local options = {
        Mode = mode,
        FilePath = "",
        FileName = "",
        Binary = client.CanBinary,
        
        Decompile = true,
        DecompileTimeout = 10,
        
        RemovePlayers = true,
        SavePlayers = false,
        NilInstances = false,
        IsolatePlayers = true,
        
        IgnoreDefaultPlayerScripts = true,
        SaveBytecode = false,
        
        ShowStatus = true,
        SaveCacheInterval = 0x1600,
        
        Ignore = {},
    }
    
    if customOptions then
        for k, v in pairs(customOptions) do
            options[k] = v
        end
    end
    
    return options
end

--// Main save function
function Save.Execute(mode, fileName, customOptions, callbacks)
    callbacks = callbacks or {}
    
    local client = Save.DetectClient()
    
    if not client.CanSave then
        if callbacks.onError then
            callbacks.onError("saveinstance not available")
        end
        return false, "saveinstance not available"
    end
    
    -- Create folder
    if makefolder then
        pcall(function()
            if not isfolder or not isfolder("BaoSaveInstance") then
                makefolder("BaoSaveInstance")
            end
        end)
    end
    
    -- Build options
    local options = Save.BuildOptions(mode, customOptions)
    
    -- Generate path
    local gameName = tostring(fileName ~= "" and fileName or game.Name):gsub("[^%w%-_]", "_"):sub(1, 50)
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local ext = options.Binary and "rbxl" or "rbxlx"
    local filePath = string.format("BaoSaveInstance/%s_%s.%s", gameName, timestamp, ext)
    
    options.FilePath = filePath
    options.FileName = filePath
    
    -- Handle modes
    if mode == "Terrain" then
        for _, child in ipairs(game.Workspace:GetChildren()) do
            if child ~= game.Workspace.Terrain then
                table.insert(options.Ignore, child)
            end
        end
        options.Decompile = false
        
    elseif mode == "Scripts" then
        options.Decompile = true
        options.DecompileTimeout = 30
        
    elseif mode == "Model" then
        if not customOptions or not customOptions.Object then
            if callbacks.onError then
                callbacks.onError("No model specified")
            end
            return false, "No model specified"
        end
        options.Object = customOptions.Object
    end
    
    -- Remove player characters
    if options.RemovePlayers then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                table.insert(options.Ignore, player.Character)
            end
        end
    end
    
    if callbacks.onStart then
        callbacks.onStart()
    end
    
    -- Progress callback
    options.Callback = function(data)
        if callbacks.onProgress and data then
            callbacks.onProgress(data.Percent or 0, data.Status or "Saving...")
        end
    end
    
    -- Execute save
    local saveFunc = saveinstance or (syn and syn.saveinstance)
    local success, err = pcall(function()
        saveFunc(options)
    end)
    
    if success then
        if callbacks.onComplete then
            callbacks.onComplete(filePath)
        end
        return true, filePath
    else
        if callbacks.onError then
            callbacks.onError(tostring(err))
        end
        return false, tostring(err)
    end
end

--// Quick save functions
function Save.All(fileName, options, callbacks)
    return Save.Execute("All", fileName, options, callbacks)
end

function Save.Terrain(fileName, options, callbacks)
    return Save.Execute("Terrain", fileName, options, callbacks)
end

function Save.Scripts(fileName, options, callbacks)
    return Save.Execute("Scripts", fileName, options, callbacks)
end

function Save.FullMap(fileName, options, callbacks)
    return Save.Execute("Full Map", fileName, options, callbacks)
end

function Save.Model(model, fileName, options, callbacks)
    options = options or {}
    options.Object = model
    return Save.Execute("Model", fileName or model.Name, options, callbacks)
end

return Save