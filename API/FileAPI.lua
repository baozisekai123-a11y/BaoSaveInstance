--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              BaoSaveInstance - File System API               ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local HttpService = game:GetService("HttpService")

local File = {}

--// Check capabilities
function File.HasCapability(capability)
    local caps = {
        read = readfile ~= nil,
        write = writefile ~= nil,
        append = appendfile ~= nil,
        delete = delfile ~= nil,
        list = listfiles ~= nil,
        isfile = isfile ~= nil,
        isfolder = isfolder ~= nil,
        makefolder = makefolder ~= nil,
    }
    return caps[capability] or false
end

--// Get all capabilities
function File.GetCapabilities()
    return {
        read = readfile ~= nil,
        write = writefile ~= nil,
        append = appendfile ~= nil,
        delete = delfile ~= nil,
        list = listfiles ~= nil,
        isfile = isfile ~= nil,
        isfolder = isfolder ~= nil,
        makefolder = makefolder ~= nil,
    }
end

--// Read file
function File.Read(path)
    if not readfile then
        return nil, "readfile not available"
    end
    
    local success, content = pcall(readfile, path)
    if success then
        return content, nil
    else
        return nil, content
    end
end

--// Write file
function File.Write(path, content)
    if not writefile then
        return false, "writefile not available"
    end
    
    local success, err = pcall(writefile, path, content)
    return success, err
end

--// Append to file
function File.Append(path, content)
    if appendfile then
        local success, err = pcall(appendfile, path, content)
        return success, err
    elseif readfile and writefile then
        local existing = File.Read(path) or ""
        return File.Write(path, existing .. content)
    end
    return false, "append not available"
end

--// Delete file
function File.Delete(path)
    if not delfile then
        return false, "delfile not available"
    end
    
    local success, err = pcall(delfile, path)
    return success, err
end

--// Check if file exists
function File.Exists(path)
    if isfile then
        local success, result = pcall(isfile, path)
        return success and result
    end
    return false
end

--// Check if folder exists
function File.FolderExists(path)
    if isfolder then
        local success, result = pcall(isfolder, path)
        return success and result
    end
    return false
end

--// Create folder
function File.CreateFolder(path)
    if not makefolder then
        return false, "makefolder not available"
    end
    
    if File.FolderExists(path) then
        return true
    end
    
    local success, err = pcall(makefolder, path)
    return success, err
end

--// List files in folder
function File.List(path)
    if not listfiles then
        return {}, "listfiles not available"
    end
    
    local success, files = pcall(listfiles, path)
    if success then
        return files, nil
    else
        return {}, files
    end
end

--// Read JSON file
function File.ReadJSON(path)
    local content, err = File.Read(path)
    if not content then
        return nil, err
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    
    if success then
        return data, nil
    else
        return nil, data
    end
end

--// Write JSON file
function File.WriteJSON(path, data, pretty)
    local success, content = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if not success then
        return false, content
    end
    
    return File.Write(path, content)
end

--// Generate save path
function File.GeneratePath(name, extension, basePath)
    basePath = basePath or "BaoSaveInstance"
    
    local sanitized = tostring(name or game.Name):gsub("[^%w%-_]", "_"):sub(1, 50)
    local timestamp = os.date("%Y%m%d_%H%M%S")
    extension = extension or "rbxl"
    
    return string.format("%s/%s_%s.%s", basePath, sanitized, timestamp, extension)
end

--// Ensure save folder exists
function File.EnsureSaveFolder(path)
    path = path or "BaoSaveInstance"
    return File.CreateFolder(path)
end

--// Get file extension
function File.GetExtension(path)
    return path:match("%.([^%.]+)$")
end

--// Get file name without extension
function File.GetName(path)
    local name = path:match("([^/\\]+)$") or path
    return name:match("(.+)%.[^%.]+$") or name
end

--// Get directory from path
function File.GetDirectory(path)
    return path:match("(.+)[/\\]") or ""
end

return File