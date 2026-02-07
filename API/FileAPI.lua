--[[
    BaoSaveInstance API Framework
    File: API/FileAPI.lua
    Description: File System Operations
]]

local HttpService = game:GetService("HttpService")

local FileAPI = {}

--// ═══════════════════════════════════════════════════════════════════════════
--// CAPABILITY DETECTION
--// ═══════════════════════════════════════════════════════════════════════════

function FileAPI.GetCapabilities()
    return {
        Read = readfile ~= nil,
        Write = writefile ~= nil,
        Append = appendfile ~= nil,
        Delete = delfile ~= nil,
        List = listfiles ~= nil,
        IsFile = isfile ~= nil,
        IsFolder = isfolder ~= nil,
        MakeFolder = makefolder ~= nil,
        DeleteFolder = delfolder ~= nil,
    }
end

function FileAPI.HasCapability(capability)
    local caps = FileAPI.GetCapabilities()
    return caps[capability] or false
end

function FileAPI.IsAvailable()
    return writefile ~= nil and readfile ~= nil
end

--// ═══════════════════════════════════════════════════════════════════════════
--// BASIC FILE OPERATIONS
--// ═══════════════════════════════════════════════════════════════════════════

-- Read file
function FileAPI.Read(path)
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

-- Write file
function FileAPI.Write(path, content)
    if not writefile then
        return false, "writefile not available"
    end
    
    local success, err = pcall(writefile, path, tostring(content))
    return success, err
end

-- Append to file
function FileAPI.Append(path, content)
    if appendfile then
        local success, err = pcall(appendfile, path, tostring(content))
        return success, err
    elseif readfile and writefile then
        local existing = FileAPI.Read(path) or ""
        return FileAPI.Write(path, existing .. tostring(content))
    end
    return false, "append not available"
end

-- Delete file
function FileAPI.Delete(path)
    if not delfile then
        return false, "delfile not available"
    end
    
    local success, err = pcall(delfile, path)
    return success, err
end

-- Check if file exists
function FileAPI.Exists(path)
    if isfile then
        local success, result = pcall(isfile, path)
        return success and result
    end
    
    -- Fallback: try to read
    local content = FileAPI.Read(path)
    return content ~= nil
end

-- Get file size (approximate)
function FileAPI.GetSize(path)
    local content = FileAPI.Read(path)
    if content then
        return #content
    end
    return nil
end

--// ═══════════════════════════════════════════════════════════════════════════
--// FOLDER OPERATIONS
--// ═══════════════════════════════════════════════════════════════════════════

-- Check if folder exists
function FileAPI.FolderExists(path)
    if isfolder then
        local success, result = pcall(isfolder, path)
        return success and result
    end
    return false
end

-- Create folder
function FileAPI.CreateFolder(path)
    if not makefolder then
        return false, "makefolder not available"
    end
    
    if FileAPI.FolderExists(path) then
        return true, nil
    end
    
    local success, err = pcall(makefolder, path)
    return success, err
end

-- Create folder recursively
function FileAPI.CreateFolderRecursive(path)
    local parts = string.split(path, "/")
    local current = ""
    
    for _, part in ipairs(parts) do
        current = current == "" and part or (current .. "/" .. part)
        if not FileAPI.FolderExists(current) then
            local success, err = FileAPI.CreateFolder(current)
            if not success then
                return false, err
            end
        end
    end
    
    return true
end

-- Delete folder
function FileAPI.DeleteFolder(path)
    if not delfolder then
        return false, "delfolder not available"
    end
    
    local success, err = pcall(delfolder, path)
    return success, err
end

-- List files in folder
function FileAPI.List(path)
    if not listfiles then
        return {}, "listfiles not available"
    end
    
    local success, files = pcall(listfiles, path)
    if success then
        return files or {}, nil
    else
        return {}, files
    end
end

-- List files with filter
function FileAPI.ListFiltered(path, extension)
    local files, err = FileAPI.List(path)
    if err then
        return {}, err
    end
    
    if not extension then
        return files
    end
    
    local filtered = {}
    for _, file in ipairs(files) do
        if file:sub(-#extension) == extension then
            table.insert(filtered, file)
        end
    end
    
    return filtered
end

--// ═══════════════════════════════════════════════════════════════════════════
--// JSON OPERATIONS
--// ═══════════════════════════════════════════════════════════════════════════

-- Read JSON file
function FileAPI.ReadJSON(path)
    local content, err = FileAPI.Read(path)
    if not content then
        return nil, err
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    
    if success then
        return data, nil
    else
        return nil, "Invalid JSON: " .. tostring(data)
    end
end

-- Write JSON file
function FileAPI.WriteJSON(path, data, prettyPrint)
    local success, content = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if not success then
        return false, "Failed to encode JSON: " .. tostring(content)
    end
    
    return FileAPI.Write(path, content)
end

--// ═══════════════════════════════════════════════════════════════════════════
--// PATH UTILITIES
--// ═══════════════════════════════════════════════════════════════════════════

-- Get file name from path
function FileAPI.GetFileName(path)
    return path:match("([^/]+)$") or path
end

-- Get file extension
function FileAPI.GetExtension(path)
    return path:match("%.([^%.]+)$") or ""
end

-- Get directory from path
function FileAPI.GetDirectory(path)
    return path:match("(.+)/[^/]+$") or ""
end

-- Join paths
function FileAPI.JoinPath(...)
    local parts = {...}
    local result = {}
    
    for _, part in ipairs(parts) do
        -- Remove trailing slash
        part = part:gsub("/$", "")
        -- Remove leading slash (except first)
        if #result > 0 then
            part = part:gsub("^/", "")
        end
        if part ~= "" then
            table.insert(result, part)
        end
    end
    
    return table.concat(result, "/")
end

-- Normalize path
function FileAPI.NormalizePath(path)
    -- Replace backslashes
    path = path:gsub("\\", "/")
    -- Remove double slashes
    path = path:gsub("//+", "/")
    -- Remove trailing slash
    path = path:gsub("/$", "")
    return path
end

-- Generate unique file path
function FileAPI.GenerateUniquePath(basePath, name, extension)
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local sanitized = tostring(name):gsub("[^%w%-_]", "_"):sub(1, 50)
    
    return FileAPI.JoinPath(
        basePath,
        string.format("%s_%s.%s", sanitized, timestamp, extension)
    )
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SAVE INSTANCE PATH
--// ═══════════════════════════════════════════════════════════════════════════

-- Default save folder
FileAPI.DefaultFolder = "BaoSaveInstance"

-- Ensure save folder exists
function FileAPI.EnsureSaveFolder()
    return FileAPI.CreateFolderRecursive(FileAPI.DefaultFolder)
end

-- Generate save path for game
function FileAPI.GenerateSavePath(fileName, extension)
    extension = extension or "rbxl"
    fileName = fileName or game.Name
    
    FileAPI.EnsureSaveFolder()
    
    return FileAPI.GenerateUniquePath(FileAPI.DefaultFolder, fileName, extension)
end

--// ═══════════════════════════════════════════════════════════════════════════
--// COPY/MOVE OPERATIONS
--// ═══════════════════════════════════════════════════════════════════════════

-- Copy file
function FileAPI.Copy(sourcePath, destPath)
    local content, err = FileAPI.Read(sourcePath)
    if not content then
        return false, err
    end
    
    return FileAPI.Write(destPath, content)
end

-- Move file
function FileAPI.Move(sourcePath, destPath)
    local success, err = FileAPI.Copy(sourcePath, destPath)
    if not success then
        return false, err
    end
    
    return FileAPI.Delete(sourcePath)
end

-- Rename file
function FileAPI.Rename(oldPath, newPath)
    return FileAPI.Move(oldPath, newPath)
end

return FileAPI