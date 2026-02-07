--[[
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                       BaoSaveInstance API Framework v3.0                              ║
║                               API/TerrainAPI.lua                                      ║
╠══════════════════════════════════════════════════════════════════════════════════════╣
║  File: API/TerrainAPI.lua                                                            ║
║  Description: Terrain voxel reading, serialization, and reconstruction               ║
╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local TerrainAPI = {}

--// ═══════════════════════════════════════════════════════════════════════════════════
--// SERVICES
--// ═══════════════════════════════════════════════════════════════════════════════════

local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local Terrain = Workspace.Terrain

--// ═══════════════════════════════════════════════════════════════════════════════════
--// CONFIGURATION
--// ═══════════════════════════════════════════════════════════════════════════════════

local Config = {
    DefaultResolution = 4,
    DefaultChunkSize = 64,
    MaxRegionSize = 1024,
    CompressData = true,
    SaveWater = true,
    YieldInterval = 10,
}

function TerrainAPI.SetConfig(newConfig)
    for key, value in pairs(newConfig) do
        if Config[key] ~= nil then
            Config[key] = value
        end
    end
end

function TerrainAPI.GetConfig()
    local copy = {}
    for k, v in pairs(Config) do
        copy[k] = v
    end
    return copy
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// MATERIAL MAPPING
--// ═══════════════════════════════════════════════════════════════════════════════════

TerrainAPI.MaterialToID = {
    [Enum.Material.Air] = 0,
    [Enum.Material.Water] = 1,
    [Enum.Material.Grass] = 2,
    [Enum.Material.Slate] = 3,
    [Enum.Material.Concrete] = 4,
    [Enum.Material.Brick] = 5,
    [Enum.Material.Sand] = 6,
    [Enum.Material.Rock] = 7,
    [Enum.Material.Glacier] = 8,
    [Enum.Material.Snow] = 9,
    [Enum.Material.Sandstone] = 10,
    [Enum.Material.Mud] = 11,
    [Enum.Material.Basalt] = 12,
    [Enum.Material.Ground] = 13,
    [Enum.Material.CrackedLava] = 14,
    [Enum.Material.Asphalt] = 15,
    [Enum.Material.Cobblestone] = 16,
    [Enum.Material.Ice] = 17,
    [Enum.Material.LeafyGrass] = 18,
    [Enum.Material.Salt] = 19,
    [Enum.Material.Limestone] = 20,
    [Enum.Material.Pavement] = 21,
    [Enum.Material.WoodPlanks] = 22,
}

TerrainAPI.IDToMaterial = {}
for material, id in pairs(TerrainAPI.MaterialToID) do
    TerrainAPI.IDToMaterial[id] = material
end

TerrainAPI.MaterialNames = {}
for material, id in pairs(TerrainAPI.MaterialToID) do
    TerrainAPI.MaterialNames[id] = material.Name
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// CAPABILITY DETECTION
--// ═══════════════════════════════════════════════════════════════════════════════════

function TerrainAPI.CanRead()
    local success = pcall(function()
        local region = Region3.new(Vector3.new(0, 0, 0), Vector3.new(4, 4, 4))
        Terrain:ReadVoxels(region, 4)
    end)
    return success
end

function TerrainAPI.CanWrite()
    -- We can't actually test write without modifying terrain
    -- So we just check if the method exists
    return Terrain.WriteVoxels ~= nil
end

function TerrainAPI.GetCapabilities()
    return {
        Read = TerrainAPI.CanRead(),
        Write = TerrainAPI.CanWrite(),
        CopyRegion = Terrain.CopyRegion ~= nil,
        PasteRegion = Terrain.PasteRegion ~= nil,
        FillBlock = Terrain.FillBlock ~= nil,
        FillBall = Terrain.FillBall ~= nil,
        FillRegion = Terrain.FillRegion ~= nil,
        Clear = Terrain.Clear ~= nil,
    }
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// TERRAIN PROPERTIES
--// ═══════════════════════════════════════════════════════════════════════════════════

function TerrainAPI.GetProperties()
    local props = {}
    
    local propertiesToGet = {
        "WaterColor",
        "WaterReflectance",
        "WaterTransparency",
        "WaterWaveSize",
        "WaterWaveSpeed",
    }
    
    for _, propName in ipairs(propertiesToGet) do
        local success, value = pcall(function()
            return Terrain[propName]
        end)
        
        if success then
            if typeof(value) == "Color3" then
                props[propName] = {
                    R = value.R,
                    G = value.G,
                    B = value.B,
                }
            else
                props[propName] = value
            end
        end
    end
    
    return props
end

function TerrainAPI.ApplyProperties(props)
    for propName, value in pairs(props) do
        pcall(function()
            if type(value) == "table" and value.R then
                Terrain[propName] = Color3.new(value.R, value.G, value.B)
            else
                Terrain[propName] = value
            end
        end)
    end
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// BOUNDS DETECTION
--// ═══════════════════════════════════════════════════════════════════════════════════

function TerrainAPI.GetBounds()
    if not TerrainAPI.CanRead() then
        return nil, "Cannot read terrain"
    end
    
    -- Start with a large region and find actual bounds
    local scanSize = 2048
    local resolution = 16 -- Lower resolution for faster scanning
    
    local minBound = Vector3.new(math.huge, math.huge, math.huge)
    local maxBound = Vector3.new(-math.huge, -math.huge, -math.huge)
    local hasContent = false
    
    -- Scan in chunks
    local chunkSize = 256
    
    for x = -scanSize, scanSize, chunkSize do
        for z = -scanSize, scanSize, chunkSize do
            for y = -512, 512, chunkSize do
                local regionMin = Vector3.new(x, y, z)
                local regionMax = Vector3.new(x + chunkSize, y + chunkSize, z + chunkSize)
                local region = Region3.new(regionMin, regionMax)
                
                local success, materials, occupancy = pcall(function()
                    return Terrain:ReadVoxels(region:ExpandToGrid(resolution), resolution)
                end)
                
                if success then
                    local size = materials.Size
                    for mx = 1, size.X do
                        for my = 1, size.Y do
                            for mz = 1, size.Z do
                                local mat = materials[mx][my][mz]
                                local occ = occupancy[mx][my][mz]
                                
                                if mat ~= Enum.Material.Air and occ > 0 then
                                    hasContent = true
                                    
                                    local worldPos = regionMin + Vector3.new(
                                        (mx - 1) * resolution,
                                        (my - 1) * resolution,
                                        (mz - 1) * resolution
                                    )
                                    
                                    minBound = Vector3.new(
                                        math.min(minBound.X, worldPos.X),
                                        math.min(minBound.Y, worldPos.Y),
                                        math.min(minBound.Z, worldPos.Z)
                                    )
                                    
                                    maxBound = Vector3.new(
                                        math.max(maxBound.X, worldPos.X + resolution),
                                        math.max(maxBound.Y, worldPos.Y + resolution),
                                        math.max(maxBound.Z, worldPos.Z + resolution)
                                    )
                                end
                            end
                        end
                    end
                end
            end
            
            task.wait()
        end
    end
    
    if hasContent then
        return {
            Min = minBound,
            Max = maxBound,
            Size = maxBound - minBound,
            HasContent = true,
        }
    else
        return {
            Min = Vector3.new(0, 0, 0),
            Max = Vector3.new(0, 0, 0),
            Size = Vector3.new(0, 0, 0),
            HasContent = false,
        }
    end
end

-- Faster approximate bounds (less accurate but quicker)
function TerrainAPI.GetApproximateBounds()
    return {
        Min = Vector3.new(-2048, -512, -2048),
        Max = Vector3.new(2048, 512, 2048),
        Size = Vector3.new(4096, 1024, 4096),
        HasContent = true,
        Approximate = true,
    }
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// CHUNK OPERATIONS
--// ═══════════════════════════════════════════════════════════════════════════════════

function TerrainAPI.ReadChunk(centerPosition, chunkSize, resolution)
    chunkSize = chunkSize or Config.DefaultChunkSize
    resolution = resolution or Config.DefaultResolution
    
    if not TerrainAPI.CanRead() then
        return nil, "Cannot read terrain"
    end
    
    local halfSize = chunkSize * resolution / 2
    
    local regionMin = centerPosition - Vector3.new(halfSize, halfSize, halfSize)
    local regionMax = centerPosition + Vector3.new(halfSize, halfSize, halfSize)
    local region = Region3.new(regionMin, regionMax)
    
    local success, materials, occupancy = pcall(function()
        return Terrain:ReadVoxels(region:ExpandToGrid(resolution), resolution)
    end)
    
    if not success then
        return nil, "Failed to read voxels"
    end
    
    return {
        Position = centerPosition,
        RegionMin = regionMin,
        RegionMax = regionMax,
        Resolution = resolution,
        ChunkSize = chunkSize,
        Materials = materials,
        Occupancy = occupancy,
        Size = materials.Size,
    }
end

function TerrainAPI.WriteChunk(chunkData)
    if not chunkData or not chunkData.Materials or not chunkData.Occupancy then
        return false, "Invalid chunk data"
    end
    
    local region = Region3.new(chunkData.RegionMin, chunkData.RegionMax)
    
    local success, err = pcall(function()
        Terrain:WriteVoxels(
            region:ExpandToGrid(chunkData.Resolution),
            chunkData.Resolution,
            chunkData.Materials,
            chunkData.Occupancy
        )
    end)
    
    return success, err
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// SERIALIZATION
--// ═══════════════════════════════════════════════════════════════════════════════════

function TerrainAPI.SerializeChunk(chunkData)
    if not chunkData then
        return nil
    end
    
    local serialized = {
        Position = {
            X = chunkData.Position.X,
            Y = chunkData.Position.Y,
            Z = chunkData.Position.Z,
        },
        Resolution = chunkData.Resolution,
        ChunkSize = chunkData.ChunkSize,
        Size = {
            X = chunkData.Size.X,
            Y = chunkData.Size.Y,
            Z = chunkData.Size.Z,
        },
        Data = nil,
    }
    
    if Config.CompressData then
        -- RLE compression
        serialized.Data = TerrainAPI.CompressRLE(chunkData)
        serialized.Compressed = true
    else
        -- Raw data
        serialized.Materials = {}
        serialized.Occupancy = {}
        
        for x = 1, chunkData.Size.X do
            serialized.Materials[x] = {}
            serialized.Occupancy[x] = {}
            
            for y = 1, chunkData.Size.Y do
                serialized.Materials[x][y] = {}
                serialized.Occupancy[x][y] = {}
                
                for z = 1, chunkData.Size.Z do
                    local mat = chunkData.Materials[x][y][z]
                    local occ = chunkData.Occupancy[x][y][z]
                    
                    serialized.Materials[x][y][z] = TerrainAPI.MaterialToID[mat] or 0
                    serialized.Occupancy[x][y][z] = math.floor(occ * 255)
                end
            end
        end
        
        serialized.Compressed = false
    end
    
    return serialized
end

function TerrainAPI.DeserializeChunk(serialized)
    if not serialized then
        return nil
    end
    
    local size = Vector3.new(serialized.Size.X, serialized.Size.Y, serialized.Size.Z)
    
    -- Create material and occupancy arrays
    local materials = {}
    local occupancy = {}
    
    for x = 1, size.X do
        materials[x] = {}
        occupancy[x] = {}
        
        for y = 1, size.Y do
            materials[x][y] = {}
            occupancy[x][y] = {}
            
            for z = 1, size.Z do
                materials[x][y][z] = Enum.Material.Air
                occupancy[x][y][z] = 0
            end
        end
    end
    
    if serialized.Compressed and serialized.Data then
        -- Decompress RLE
        TerrainAPI.DecompressRLE(serialized.Data, size, materials, occupancy)
    elseif serialized.Materials and serialized.Occupancy then
        -- Raw data
        for x = 1, size.X do
            for y = 1, size.Y do
                for z = 1, size.Z do
                    local matID = serialized.Materials[x][y][z] or 0
                    local occValue = serialized.Occupancy[x][y][z] or 0
                    
                    materials[x][y][z] = TerrainAPI.IDToMaterial[matID] or Enum.Material.Air
                    occupancy[x][y][z] = occValue / 255
                end
            end
        end
    end
    
    local halfSize = serialized.ChunkSize * serialized.Resolution / 2
    local position = Vector3.new(serialized.Position.X, serialized.Position.Y, serialized.Position.Z)
    
    return {
        Position = position,
        RegionMin = position - Vector3.new(halfSize, halfSize, halfSize),
        RegionMax = position + Vector3.new(halfSize, halfSize, halfSize),
        Resolution = serialized.Resolution,
        ChunkSize = serialized.ChunkSize,
        Materials = materials,
        Occupancy = occupancy,
        Size = size,
    }
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// COMPRESSION
--// ═══════════════════════════════════════════════════════════════════════════════════

function TerrainAPI.CompressRLE(chunkData)
    local runs = {}
    
    local currentMat = nil
    local currentOcc = nil
    local runLength = 0
    
    local size = chunkData.Size
    
    for x = 1, size.X do
        for y = 1, size.Y do
            for z = 1, size.Z do
                local mat = chunkData.Materials[x][y][z]
                local occ = chunkData.Occupancy[x][y][z]
                
                local matID = TerrainAPI.MaterialToID[mat] or 0
                local occByte = math.floor(occ * 255)
                
                if matID == currentMat and occByte == currentOcc then
                    runLength = runLength + 1
                else
                    if currentMat ~= nil then
                        table.insert(runs, {
                            m = currentMat,
                            o = currentOcc,
                            l = runLength,
                        })
                    end
                    
                    currentMat = matID
                    currentOcc = occByte
                    runLength = 1
                end
            end
        end
    end
    
    -- Don't forget last run
    if currentMat ~= nil then
        table.insert(runs, {
            m = currentMat,
            o = currentOcc,
            l = runLength,
        })
    end
    
    return runs
end

function TerrainAPI.DecompressRLE(runs, size, materials, occupancy)
    local index = 1
    local totalVoxels = size.X * size.Y * size.Z
    
    for _, run in ipairs(runs) do
        local mat = TerrainAPI.IDToMaterial[run.m] or Enum.Material.Air
        local occ = run.o / 255
        
        for _ = 1, run.l do
            if index > totalVoxels then
                break
            end
            
            -- Convert linear index to 3D coordinates
            local z = ((index - 1) % size.Z) + 1
            local y = (math.floor((index - 1) / size.Z) % size.Y) + 1
            local x = math.floor((index - 1) / (size.Y * size.Z)) + 1
            
            if x <= size.X and y <= size.Y and z <= size.Z then
                materials[x][y][z] = mat
                occupancy[x][y][z] = occ
            end
            
            index = index + 1
        end
    end
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// FULL TERRAIN SAVE
--// ═══════════════════════════════════════════════════════════════════════════════════

function TerrainAPI.SaveFull(options, onProgress)
    options = options or {}
    
    if not TerrainAPI.CanRead() then
        return nil, "Cannot read terrain"
    end
    
    local bounds = options.Bounds or TerrainAPI.GetApproximateBounds()
    local resolution = options.Resolution or Config.DefaultResolution
    local chunkSize = options.ChunkSize or Config.DefaultChunkSize
    
    local chunkWorld = chunkSize * resolution
    
    local chunksX = math.ceil((bounds.Max.X - bounds.Min.X) / chunkWorld)
    local chunksY = math.ceil((bounds.Max.Y - bounds.Min.Y) / chunkWorld)
    local chunksZ = math.ceil((bounds.Max.Z - bounds.Min.Z) / chunkWorld)
    local totalChunks = chunksX * chunksY * chunksZ
    
    local terrainData = {
        Version = "1.0",
        SavedAt = os.time(),
        Properties = TerrainAPI.GetProperties(),
        Bounds = {
            Min = {X = bounds.Min.X, Y = bounds.Min.Y, Z = bounds.Min.Z},
            Max = {X = bounds.Max.X, Y = bounds.Max.Y, Z = bounds.Max.Z},
        },
        Resolution = resolution,
        ChunkSize = chunkSize,
        ChunkCount = {X = chunksX, Y = chunksY, Z = chunksZ},
        TotalChunks = totalChunks,
        Chunks = {},
    }
    
    local chunkIndex = 0
    local savedChunks = 0
    
    for cx = 0, chunksX - 1 do
        for cy = 0, chunksY - 1 do
            for cz = 0, chunksZ - 1 do
                chunkIndex = chunkIndex + 1
                
                local chunkPos = Vector3.new(
                    bounds.Min.X + (cx + 0.5) * chunkWorld,
                    bounds.Min.Y + (cy + 0.5) * chunkWorld,
                    bounds.Min.Z + (cz + 0.5) * chunkWorld
                )
                
                local chunkData = TerrainAPI.ReadChunk(chunkPos, chunkSize, resolution)
                
                if chunkData then
                    -- Check if chunk has any content
                    local hasContent = false
                    local size = chunkData.Size
                    
                    for x = 1, size.X do
                        for y = 1, size.Y do
                            for z = 1, size.Z do
                                if chunkData.Materials[x][y][z] ~= Enum.Material.Air and
                                   chunkData.Occupancy[x][y][z] > 0 then
                                    hasContent = true
                                    break
                                end
                            end
                            if hasContent then break end
                        end
                        if hasContent then break end
                    end
                    
                    if hasContent then
                        local serialized = TerrainAPI.SerializeChunk(chunkData)
                        if serialized then
                            table.insert(terrainData.Chunks, serialized)
                            savedChunks = savedChunks + 1
                        end
                    end
                end
                
                if onProgress then
                    onProgress(chunkIndex, totalChunks, math.floor(chunkIndex / totalChunks * 100))
                end
                
                if chunkIndex % Config.YieldInterval == 0 then
                    task.wait()
                end
            end
        end
    end
    
    terrainData.SavedChunks = savedChunks
    
    return terrainData
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// FULL TERRAIN LOAD
--// ═══════════════════════════════════════════════════════════════════════════════════

function TerrainAPI.LoadFull(terrainData, options, onProgress)
    options = options or {}
    
    if not terrainData or not terrainData.Chunks then
        return false, "Invalid terrain data"
    end
    
    -- Clear existing terrain if requested
    if options.ClearFirst then
        pcall(function()
            Terrain:Clear()
        end)
    end
    
    -- Apply terrain properties
    if terrainData.Properties then
        TerrainAPI.ApplyProperties(terrainData.Properties)
    end
    
    local totalChunks = #terrainData.Chunks
    local loadedChunks = 0
    local failedChunks = 0
    
    for i, serializedChunk in ipairs(terrainData.Chunks) do
        local chunkData = TerrainAPI.DeserializeChunk(serializedChunk)
        
        if chunkData then
            local success = TerrainAPI.WriteChunk(chunkData)
            if success then
                loadedChunks = loadedChunks + 1
            else
                failedChunks = failedChunks + 1
            end
        else
            failedChunks = failedChunks + 1
        end
        
        if onProgress then
            onProgress(i, totalChunks, math.floor(i / totalChunks * 100))
        end
        
        if i % Config.YieldInterval == 0 then
            task.wait()
        end
    end
    
    return true, {
        Total = totalChunks,
        Loaded = loadedChunks,
        Failed = failedChunks,
    }
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// EXPORT FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════════════

function TerrainAPI.ExportToJSON(terrainData)
    local success, json = pcall(function()
        return HttpService:JSONEncode(terrainData)
    end)
    
    return success and json or nil
end

function TerrainAPI.ImportFromJSON(jsonString)
    local success, data = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    
    return success and data or nil
end

function TerrainAPI.SaveToFile(terrainData, filePath)
    if not writefile then
        return false, "writefile not available"
    end
    
    local json = TerrainAPI.ExportToJSON(terrainData)
    if not json then
        return false, "Failed to encode terrain data"
    end
    
    local success, err = pcall(writefile, filePath, json)
    return success, err
end

function TerrainAPI.LoadFromFile(filePath)
    if not readfile then
        return nil, "readfile not available"
    end
    
    local success, content = pcall(readfile, filePath)
    if not success then
        return nil, "Failed to read file"
    end
    
    return TerrainAPI.ImportFromJSON(content)
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// LUA CODE GENERATION
--// ═══════════════════════════════════════════════════════════════════════════════════

function TerrainAPI.GenerateReconstructionCode(terrainData)
    local code = [[
--[[
    BaoSaveInstance Terrain Reconstruction Script
    Generated: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[
    
    Chunks: ]] .. #terrainData.Chunks .. [[
    
    Run this script to reconstruct the terrain.
]]

local HttpService = game:GetService("HttpService")
local Terrain = workspace.Terrain

-- Material lookup table
local Materials = {
    [0] = Enum.Material.Air,
    [1] = Enum.Material.Water,
    [2] = Enum.Material.Grass,
    [3] = Enum.Material.Slate,
    [4] = Enum.Material.Concrete,
    [5] = Enum.Material.Brick,
    [6] = Enum.Material.Sand,
    [7] = Enum.Material.Rock,
    [8] = Enum.Material.Glacier,
    [9] = Enum.Material.Snow,
    [10] = Enum.Material.Sandstone,
    [11] = Enum.Material.Mud,
    [12] = Enum.Material.Basalt,
    [13] = Enum.Material.Ground,
    [14] = Enum.Material.CrackedLava,
    [15] = Enum.Material.Asphalt,
    [16] = Enum.Material.Cobblestone,
    [17] = Enum.Material.Ice,
    [18] = Enum.Material.LeafyGrass,
    [19] = Enum.Material.Salt,
    [20] = Enum.Material.Limestone,
    [21] = Enum.Material.Pavement,
    [22] = Enum.Material.WoodPlanks,
}

-- Terrain data (compressed)
local TerrainData = ]] .. HttpService:JSONEncode(terrainData) .. [[


-- Decompression function
local function DecompressChunk(chunk)
    local size = Vector3.new(chunk.Size.X, chunk.Size.Y, chunk.Size.Z)
    local materials = {}
    local occupancy = {}
    
    for x = 1, size.X do
        materials[x] = {}
        occupancy[x] = {}
        for y = 1, size.Y do
            materials[x][y] = {}
            occupancy[x][y] = {}
            for z = 1, size.Z do
                materials[x][y][z] = Enum.Material.Air
                occupancy[x][y][z] = 0
            end
        end
    end
    
    if chunk.Data then
        local index = 1
        for _, run in ipairs(chunk.Data) do
            for _ = 1, run.l do
                local z = ((index - 1) % size.Z) + 1
                local y = (math.floor((index - 1) / size.Z) % size.Y) + 1
                local x = math.floor((index - 1) / (size.Y * size.Z)) + 1
                
                if x <= size.X and y <= size.Y and z <= size.Z then
                    materials[x][y][z] = Materials[run.m] or Enum.Material.Air
                    occupancy[x][y][z] = run.o / 255
                end
                
                index = index + 1
            end
        end
    end
    
    return {
        Position = Vector3.new(chunk.Position.X, chunk.Position.Y, chunk.Position.Z),
        Resolution = chunk.Resolution,
        ChunkSize = chunk.ChunkSize,
        Materials = materials,
        Occupancy = occupancy,
        Size = size,
    }
end

-- Main reconstruction function
local function Reconstruct()
    print("Starting terrain reconstruction...")
    
    -- Apply properties
    if TerrainData.Properties then
        if TerrainData.Properties.WaterColor then
            Terrain.WaterColor = Color3.new(
                TerrainData.Properties.WaterColor.R,
                TerrainData.Properties.WaterColor.G,
                TerrainData.Properties.WaterColor.B
            )
        end
        
        for prop, value in pairs(TerrainData.Properties) do
            if type(value) ~= "table" then
                pcall(function()
                    Terrain[prop] = value
                end)
            end
        end
    end
    
    local total = #TerrainData.Chunks
    local loaded = 0
    
    for i, chunk in ipairs(TerrainData.Chunks) do
        local chunkData = DecompressChunk(chunk)
        
        local halfSize = chunkData.ChunkSize * chunkData.Resolution / 2
        local regionMin = chunkData.Position - Vector3.new(halfSize, halfSize, halfSize)
        local regionMax = chunkData.Position + Vector3.new(halfSize, halfSize, halfSize)
        local region = Region3.new(regionMin, regionMax)
        
        pcall(function()
            Terrain:WriteVoxels(
                region:ExpandToGrid(chunkData.Resolution),
                chunkData.Resolution,
                chunkData.Materials,
                chunkData.Occupancy
            )
        end)
        
        loaded = loaded + 1
        
        if i % 10 == 0 then
            print(string.format("Progress: %d/%d (%d%%)", loaded, total, math.floor(loaded/total*100)))
            task.wait()
        end
    end
    
    print("Terrain reconstruction complete!")
    print(string.format("Loaded %d chunks", loaded))
end

return Reconstruct
]]
    
    return code
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// UTILITY FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════════════

function TerrainAPI.Clear()
    pcall(function()
        Terrain:Clear()
    end)
end

function TerrainAPI.GetVoxelAt(position)
    if not TerrainAPI.CanRead() then
        return nil
    end
    
    local region = Region3.new(
        position - Vector3.new(2, 2, 2),
        position + Vector3.new(2, 2, 2)
    )
    
    local success, materials, occupancy = pcall(function()
        return Terrain:ReadVoxels(region:ExpandToGrid(4), 4)
    end)
    
    if success then
        return {
            Material = materials[1][1][1],
            Occupancy = occupancy[1][1][1],
        }
    end
    
    return nil
end

function TerrainAPI.SetVoxelAt(position, material, occupancy)
    occupancy = occupancy or 1
    
    pcall(function()
        Terrain:FillBlock(
            CFrame.new(position),
            Vector3.new(4, 4, 4),
            material
        )
    end)
end

function TerrainAPI.GetStats(terrainData)
    if not terrainData then
        return nil
    end
    
    local stats = {
        TotalChunks = terrainData.TotalChunks or 0,
        SavedChunks = terrainData.SavedChunks or #terrainData.Chunks,
        Resolution = terrainData.Resolution,
        ChunkSize = terrainData.ChunkSize,
        VoxelsPerChunk = 0,
        TotalVoxels = 0,
        MaterialCounts = {},
    }
    
    if terrainData.ChunkSize and terrainData.Resolution then
        local voxelsPerDim = terrainData.ChunkSize
        stats.VoxelsPerChunk = voxelsPerDim ^ 3
        stats.TotalVoxels = stats.VoxelsPerChunk * stats.SavedChunks
    end
    
    return stats
end

--// ═══════════════════════════════════════════════════════════════════════════════════
--// RETURN MODULE
--// ═══════════════════════════════════════════════════════════════════════════════════

return TerrainAPI
