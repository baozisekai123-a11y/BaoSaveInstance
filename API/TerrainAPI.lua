--[[
    BaoSaveInstance API Framework
    File: API/TerrainAPI.lua
    Description: Terrain Reading, Serialization & Reconstruction
]]

local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local TerrainAPI = {}

--// ═══════════════════════════════════════════════════════════════════════════
--// CONFIGURATION
--// ═══════════════════════════════════════════════════════════════════════════

TerrainAPI.Config = {
    Resolution = 4,         -- Voxel resolution (1, 2, or 4)
    ChunkSize = 64,         -- Voxels per chunk dimension
    Compress = true,        -- Use RLE compression
    SaveWater = true,       -- Include water voxels
    MaxChunks = 10000,      -- Maximum chunks to process
}

--// ═══════════════════════════════════════════════════════════════════════════
--// MATERIAL MAPPING
--// ═══════════════════════════════════════════════════════════════════════════

TerrainAPI.MaterialMap = {
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

-- Reverse map for reconstruction
TerrainAPI.ReverseMaterialMap = {}
for material, id in pairs(TerrainAPI.MaterialMap) do
    TerrainAPI.ReverseMaterialMap[id] = material
end

--// ═══════════════════════════════════════════════════════════════════════════
--// CAPABILITY DETECTION
--// ═══════════════════════════════════════════════════════════════════════════

function TerrainAPI.CanRead()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return false, "No terrain found"
    end
    
    local success = pcall(function()
        local region = Region3.new(Vector3.new(0, 0, 0), Vector3.new(4, 4, 4))
        terrain:ReadVoxels(region, 4)
    end)
    
    return success, success and nil or "ReadVoxels not available"
end

function TerrainAPI.CanWrite()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return false, "No terrain found"
    end
    
    -- Just check if method exists
    return terrain.WriteVoxels ~= nil, nil
end

--// ═══════════════════════════════════════════════════════════════════════════
--// TERRAIN PROPERTIES
--// ═══════════════════════════════════════════════════════════════════════════

function TerrainAPI.GetProperties()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return nil
    end
    
    local props = {}
    
    local propNames = {
        "WaterColor", "WaterReflectance", "WaterTransparency",
        "WaterWaveSize", "WaterWaveSpeed", "Decoration",
        "MaterialColors",
    }
    
    for _, propName in ipairs(propNames) do
        pcall(function()
            props[propName] = terrain[propName]
        end)
    end
    
    return props
end

function TerrainAPI.SerializeProperties()
    local props = TerrainAPI.GetProperties()
    if not props then
        return nil
    end
    
    local serialized = {}
    
    if props.WaterColor then
        serialized.WaterColor = {
            R = props.WaterColor.R,
            G = props.WaterColor.G,
            B = props.WaterColor.B,
        }
    end
    
    serialized.WaterReflectance = props.WaterReflectance
    serialized.WaterTransparency = props.WaterTransparency
    serialized.WaterWaveSize = props.WaterWaveSize
    serialized.WaterWaveSpeed = props.WaterWaveSpeed
    serialized.Decoration = props.Decoration
    
    return serialized
end

--// ═══════════════════════════════════════════════════════════════════════════
--// BOUNDS DETECTION
--// ═══════════════════════════════════════════════════════════════════════════

function TerrainAPI.GetBounds()
    local canRead, err = TerrainAPI.CanRead()
    if not canRead then
        return nil, err
    end
    
    local terrain = Workspace.Terrain
    
    -- Default search area
    local searchMin = Vector3.new(-4096, -512, -4096)
    local searchMax = Vector3.new(4096, 512, 4096)
    
    local actualMin = Vector3.new(math.huge, math.huge, math.huge)
    local actualMax = Vector3.new(-math.huge, -math.huge, -math.huge)
    local hasContent = false
    
    local resolution = TerrainAPI.Config.Resolution
    local chunkWorld = 64 * resolution
    
    -- Scan in chunks
    for x = searchMin.X, searchMax.X, chunkWorld do
        for y = searchMin.Y, searchMax.Y, chunkWorld do
            for z = searchMin.Z, searchMax.Z, chunkWorld do
                local region = Region3.new(
                    Vector3.new(x, y, z),
                    Vector3.new(x + chunkWorld, y + chunkWorld, z + chunkWorld)
                )
                
                local success, materials, occupancy = pcall(function()
                    return terrain:ReadVoxels(region:ExpandToGrid(resolution), resolution)
                end)
                
                if success then
                    local size = materials.Size
                    for mx = 1, size.X do
                        for my = 1, size.Y do
                            for mz = 1, size.Z do
                                if materials[mx][my][mz] ~= Enum.Material.Air and occupancy[mx][my][mz] > 0 then
                                    hasContent = true
                                    local worldPos = Vector3.new(
                                        x + (mx - 1) * resolution,
                                        y + (my - 1) * resolution,
                                        z + (mz - 1) * resolution
                                    )
                                    actualMin = Vector3.new(
                                        math.min(actualMin.X, worldPos.X),
                                        math.min(actualMin.Y, worldPos.Y),
                                        math.min(actualMin.Z, worldPos.Z)
                                    )
                                    actualMax = Vector3.new(
                                        math.max(actualMax.X, worldPos.X),
                                        math.max(actualMax.Y, worldPos.Y),
                                        math.max(actualMax.Z, worldPos.Z)
                                    )
                                end
                            end
                        end
                    end
                end
                
                task.wait()
            end
        end
    end
    
    if hasContent then
        -- Add padding
        actualMin = actualMin - Vector3.new(resolution, resolution, resolution)
        actualMax = actualMax + Vector3.new(resolution, resolution, resolution)
        
        return {
            Min = actualMin,
            Max = actualMax,
            HasContent = true,
            Size = actualMax - actualMin,
        }
    end
    
    return {
        Min = Vector3.new(0, 0, 0),
        Max = Vector3.new(0, 0, 0),
        HasContent = false,
        Size = Vector3.new(0, 0, 0),
    }
end

-- Quick bounds check (faster, less accurate)
function TerrainAPI.GetQuickBounds()
    local canRead, err = TerrainAPI.CanRead()
    if not canRead then
        return nil, err
    end
    
    -- Return a reasonable default area
    return {
        Min = Vector3.new(-2048, -256, -2048),
        Max = Vector3.new(2048, 256, 2048),
        HasContent = true,
        Size = Vector3.new(4096, 512, 4096),
        IsEstimate = true,
    }
end

--// ═══════════════════════════════════════════════════════════════════════════
--// CHUNK OPERATIONS
--// ═══════════════════════════════════════════════════════════════════════════

-- Read single chunk
function TerrainAPI.ReadChunk(position, chunkSize, resolution)
    chunkSize = chunkSize or TerrainAPI.Config.ChunkSize
    resolution = resolution or TerrainAPI.Config.Resolution
    
    local terrain = Workspace.Terrain
    local halfSize = chunkSize * resolution / 2
    
    local region = Region3.new(
        position - Vector3.new(halfSize, halfSize, halfSize),
        position + Vector3.new(halfSize, halfSize, halfSize)
    )
    
    local success, materials, occupancy = pcall(function()
        return terrain:ReadVoxels(region:ExpandToGrid(resolution), resolution)
    end)
    
    if success then
        return {
            Position = position,
            Region = region,
            Resolution = resolution,
            ChunkSize = chunkSize,
            Materials = materials,
            Occupancy = occupancy,
            Size = materials.Size,
        }
    end
    
    return nil
end

-- Serialize chunk to data
function TerrainAPI.SerializeChunk(chunk)
    if not chunk then return nil end
    
    local data = {
        Position = {chunk.Position.X, chunk.Position.Y, chunk.Position.Z},
        Resolution = chunk.Resolution,
        ChunkSize = chunk.ChunkSize,
        Size = {chunk.Size.X, chunk.Size.Y, chunk.Size.Z},
    }
    
    if TerrainAPI.Config.Compress then
        -- RLE compression
        data.Compressed = true
        data.Voxels = {}
        
        local currentMat = nil
        local currentOcc = nil
        local runLength = 0
        
        for x = 1, chunk.Size.X do
            for y = 1, chunk.Size.Y do
                for z = 1, chunk.Size.Z do
                    local mat = chunk.Materials[x][y][z]
                    local occ = math.floor((chunk.Occupancy[x][y][z] or 0) * 255)
                    local matID = TerrainAPI.MaterialMap[mat] or 0
                    
                    if matID == currentMat and occ == currentOcc then
                        runLength = runLength + 1
                    else
                        if currentMat ~= nil then
                            table.insert(data.Voxels, {
                                m = currentMat,
                                o = currentOcc,
                                l = runLength
                            })
                        end
                        currentMat = matID
                        currentOcc = occ
                        runLength = 1
                    end
                end
            end
        end
        
        -- Don't forget last run
        if currentMat ~= nil then
            table.insert(data.Voxels, {
                m = currentMat,
                o = currentOcc,
                l = runLength
            })
        end
    else
        -- Uncompressed (larger but simpler)
        data.Compressed = false
        data.Materials = {}
        data.Occupancy = {}
        
        for x = 1, chunk.Size.X do
            data.Materials[x] = {}
            data.Occupancy[x] = {}
            for y = 1, chunk.Size.Y do
                data.Materials[x][y] = {}
                data.Occupancy[x][y] = {}
                for z = 1, chunk.Size.Z do
                    local mat = chunk.Materials[x][y][z]
                    local occ = chunk.Occupancy[x][y][z]
                    
                    if mat ~= Enum.Material.Air and occ > 0 then
                        data.Materials[x][y][z] = TerrainAPI.MaterialMap[mat] or 0
                        data.Occupancy[x][y][z] = math.floor(occ * 255)
                    end
                end
            end
        end
    end
    
    return data
end

--// ═══════════════════════════════════════════════════════════════════════════
--// FULL TERRAIN SAVE
--// ═══════════════════════════════════════════════════════════════════════════

function TerrainAPI.SaveFull(options, callbacks)
    options = options or {}
    callbacks = callbacks or {}
    
    local canRead, err = TerrainAPI.CanRead()
    if not canRead then
        if callbacks.OnError then callbacks.OnError(err) end
        return nil, err
    end
    
    local resolution = options.Resolution or TerrainAPI.Config.Resolution
    local chunkSize = options.ChunkSize or TerrainAPI.Config.ChunkSize
    local chunkWorld = chunkSize * resolution
    
    -- Get bounds
    local bounds = options.Bounds or TerrainAPI.GetQuickBounds()
    if not bounds or not bounds.HasContent then
        if callbacks.OnError then callbacks.OnError("No terrain content") end
        return nil, "No terrain content"
    end
    
    -- Calculate chunks needed
    local chunksX = math.ceil((bounds.Max.X - bounds.Min.X) / chunkWorld)
    local chunksY = math.ceil((bounds.Max.Y - bounds.Min.Y) / chunkWorld)
    local chunksZ = math.ceil((bounds.Max.Z - bounds.Min.Z) / chunkWorld)
    local totalChunks = chunksX * chunksY * chunksZ
    
    if totalChunks > TerrainAPI.Config.MaxChunks then
        if callbacks.OnError then 
            callbacks.OnError("Too many chunks: " .. totalChunks) 
        end
        return nil, "Too many chunks"
    end
    
    if callbacks.OnStart then
        callbacks.OnStart(totalChunks)
    end
    
    local terrainData = {
        Version = "1.0",
        SavedAt = os.time(),
        Resolution = resolution,
        ChunkSize = chunkSize,
        Bounds = {
            Min = {bounds.Min.X, bounds.Min.Y, bounds.Min.Z},
            Max = {bounds.Max.X, bounds.Max.Y, bounds.Max.Z},
        },
        Properties = TerrainAPI.SerializeProperties(),
        Chunks = {},
        Stats = {
            TotalChunks = totalChunks,
            SavedChunks = 0,
            EmptyChunks = 0,
        },
    }
    
    local chunkIndex = 0
    
    for cx = 0, chunksX - 1 do
        for cy = 0, chunksY - 1 do
            for cz = 0, chunksZ - 1 do
                chunkIndex = chunkIndex + 1
                
                local chunkPos = Vector3.new(
                    bounds.Min.X + (cx + 0.5) * chunkWorld,
                    bounds.Min.Y + (cy + 0.5) * chunkWorld,
                    bounds.Min.Z + (cz + 0.5) * chunkWorld
                )
                
                local chunk = TerrainAPI.ReadChunk(chunkPos, chunkSize, resolution)
                
                if chunk then
                    local serialized = TerrainAPI.SerializeChunk(chunk)
                    
                    if serialized and #(serialized.Voxels or {}) > 0 then
                        table.insert(terrainData.Chunks, serialized)
                        terrainData.Stats.SavedChunks = terrainData.Stats.SavedChunks + 1
                    else
                        terrainData.Stats.EmptyChunks = terrainData.Stats.EmptyChunks + 1
                    end
                end
                
                if callbacks.OnProgress then
                    callbacks.OnProgress(chunkIndex, totalChunks, math.floor(chunkIndex / totalChunks * 100))
                end
                
                -- Yield every 5 chunks
                if chunkIndex % 5 == 0 then
                    task.wait()
                end
            end
        end
    end
    
    if callbacks.OnComplete then
        callbacks.OnComplete(terrainData)
    end
    
    return terrainData
end

--// ═══════════════════════════════════════════════════════════════════════════
--// RECONSTRUCTION CODE GENERATION
--// ═══════════════════════════════════════════════════════════════════════════

function TerrainAPI.GenerateReconstructCode(terrainData)
    local code = [[
--[[
    BaoSaveInstance Terrain Reconstruction
    Generated: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[

    Chunks: ]] .. #terrainData.Chunks .. [[

    Resolution: ]] .. terrainData.Resolution .. [[

    
    Usage: require(this)()
--]]

local TerrainReconstructor = {}

-- Terrain data (embedded)
local TerrainData = ]] .. HttpService:JSONEncode(terrainData) .. [[


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

function TerrainReconstructor.Reconstruct(targetTerrain)
    targetTerrain = targetTerrain or workspace.Terrain
    
    -- Apply properties
    if TerrainData.Properties then
        local props = TerrainData.Properties
        
        if props.WaterColor then
            pcall(function()
                targetTerrain.WaterColor = Color3.new(
                    props.WaterColor.R,
                    props.WaterColor.G,
                    props.WaterColor.B
                )
            end)
        end
        
        for _, propName in ipairs({"WaterReflectance", "WaterTransparency", "WaterWaveSize", "WaterWaveSpeed"}) do
            if props[propName] then
                pcall(function()
                    targetTerrain[propName] = props[propName]
                end)
            end
        end
    end
    
    local resolution = TerrainData.Resolution
    local processedChunks = 0
    local totalChunks = #TerrainData.Chunks
    
    for _, chunk in ipairs(TerrainData.Chunks) do
        processedChunks = processedChunks + 1
        
        local pos = Vector3.new(chunk.Position[1], chunk.Position[2], chunk.Position[3])
        local size = Vector3.new(chunk.Size[1], chunk.Size[2], chunk.Size[3])
        
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
        
        -- Decompress RLE data
        if chunk.Compressed then
            local index = 1
            for _, run in ipairs(chunk.Voxels) do
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
        
        -- Write voxels
        local halfSize = chunk.ChunkSize * resolution / 2
        local region = Region3.new(
            pos - Vector3.new(halfSize, halfSize, halfSize),
            pos + Vector3.new(halfSize, halfSize, halfSize)
        )
        
        pcall(function()
            targetTerrain:WriteVoxels(region:ExpandToGrid(resolution), resolution, materials, occupancy)
        end)
        
        -- Yield periodically
        if processedChunks % 10 == 0 then
            task.wait()
            print(string.format("Terrain reconstruction: %d/%d chunks (%.1f%%)", 
                processedChunks, totalChunks, processedChunks/totalChunks*100))
        end
    end
    
    print("Terrain reconstruction completed!")
    return true
end

-- Allow calling module directly
setmetatable(TerrainReconstructor, {
    __call = function(self, ...)
        return self.Reconstruct(...)
    end
})

return TerrainReconstructor
]]

    return code
end

--// ═══════════════════════════════════════════════════════════════════════════
--// EXPORT
--// ═══════════════════════════════════════════════════════════════════════════

-- Export terrain data to JSON
function TerrainAPI.ExportJSON(terrainData)
    return HttpService:JSONEncode(terrainData)
end

-- Export terrain to reconstruction script
function TerrainAPI.ExportScript(terrainData)
    return TerrainAPI.GenerateReconstructCode(terrainData)
end

--// ═══════════════════════════════════════════════════════════════════════════
--// UTILITIES
--// ═══════════════════════════════════════════════════════════════════════════

-- Clear terrain
function TerrainAPI.Clear()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain:Clear()
        return true
    end
    return false
end

-- Get terrain info
function TerrainAPI.GetInfo()
    local canRead = TerrainAPI.CanRead()
    local bounds = canRead and TerrainAPI.GetQuickBounds() or nil
    
    return {
        CanRead = canRead,
        CanWrite = TerrainAPI.CanWrite(),
        HasContent = bounds and bounds.HasContent or false,
        Bounds = bounds,
        Properties = TerrainAPI.GetProperties(),
    }
end

-- Set config
function TerrainAPI.SetConfig(config)
    for key, value in pairs(config) do
        if TerrainAPI.Config[key] ~= nil then
            TerrainAPI.Config[key] = value
        end
    end
end

return TerrainAPI