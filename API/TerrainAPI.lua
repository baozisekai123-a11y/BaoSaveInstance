--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              BaoSaveInstance - Terrain API                   ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local Workspace = game:GetService("Workspace")

local Terrain = {}

--// Material mapping
Terrain.Materials = {
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
}

--// Reverse material mapping
Terrain.MaterialsReverse = {}
for material, id in pairs(Terrain.Materials) do
    Terrain.MaterialsReverse[id] = material
end

--// Check if terrain read is available
function Terrain.CanRead()
    local success = pcall(function()
        local terrain = Workspace.Terrain
        local region = Region3.new(Vector3.new(0, 0, 0), Vector3.new(4, 4, 4))
        terrain:ReadVoxels(region, 4)
    end)
    return success
end

--// Get terrain instance
function Terrain.Get()
    return Workspace.Terrain
end

--// Read terrain chunk
function Terrain.ReadChunk(position, size, resolution)
    resolution = resolution or 4
    size = size or 64
    
    local terrain = Workspace.Terrain
    local halfSize = size * resolution / 2
    
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
            Size = materials.Size,
            Resolution = resolution,
            Materials = materials,
            Occupancy = occupancy,
        }
    end
    
    return nil
end

--// Get terrain bounds (simplified)
function Terrain.GetBounds()
    return {
        Min = Vector3.new(-2048, -512, -2048),
        Max = Vector3.new(2048, 512, 2048),
        HasContent = true,
    }
end

--// Serialize chunk with RLE compression
function Terrain.SerializeChunk(chunk)
    if not chunk then return nil end
    
    local data = {
        Position = {chunk.Position.X, chunk.Position.Y, chunk.Position.Z},
        Size = {chunk.Size.X, chunk.Size.Y, chunk.Size.Z},
        Resolution = chunk.Resolution,
        Voxels = {},
    }
    
    local currentMat, currentOcc, runLen = nil, nil, 0
    
    for x = 1, chunk.Size.X do
        for y = 1, chunk.Size.Y do
            for z = 1, chunk.Size.Z do
                local mat = chunk.Materials[x][y][z]
                local occ = math.floor((chunk.Occupancy[x][y][z] or 0) * 255)
                local matID = Terrain.Materials[mat] or 0
                
                if matID == currentMat and occ == currentOcc then
                    runLen = runLen + 1
                else
                    if currentMat ~= nil then
                        table.insert(data.Voxels, {m = currentMat, o = currentOcc, l = runLen})
                    end
                    currentMat, currentOcc, runLen = matID, occ, 1
                end
            end
        end
    end
    
    -- Last run
    if currentMat ~= nil then
        table.insert(data.Voxels, {m = currentMat, o = currentOcc, l = runLen})
    end
    
    return data
end

--// Save full terrain
function Terrain.SaveFull(options, onProgress)
    options = options or {}
    local chunkSize = options.ChunkSize or 64
    local resolution = options.Resolution or 4
    
    if not Terrain.CanRead() then
        return nil, "Terrain reading not available"
    end
    
    local bounds = Terrain.GetBounds()
    local chunkWorld = chunkSize * resolution
    
    local chunks = {}
    local chunksX = math.ceil((bounds.Max.X - bounds.Min.X) / chunkWorld)
    local chunksY = math.ceil((bounds.Max.Y - bounds.Min.Y) / chunkWorld)
    local chunksZ = math.ceil((bounds.Max.Z - bounds.Min.Z) / chunkWorld)
    local total = chunksX * chunksY * chunksZ
    local current = 0
    
    for cx = 0, chunksX - 1 do
        for cy = 0, chunksY - 1 do
            for cz = 0, chunksZ - 1 do
                current = current + 1
                
                local pos = Vector3.new(
                    bounds.Min.X + (cx + 0.5) * chunkWorld,
                    bounds.Min.Y + (cy + 0.5) * chunkWorld,
                    bounds.Min.Z + (cz + 0.5) * chunkWorld
                )
                
                local chunk = Terrain.ReadChunk(pos, chunkSize, resolution)
                if chunk then
                    local serialized = Terrain.SerializeChunk(chunk)
                    if serialized then
                        table.insert(chunks, serialized)
                    end
                end
                
                if onProgress then
                    onProgress(current, total, math.floor(current / total * 100))
                end
                
                if current % 10 == 0 then
                    task.wait()
                end
            end
        end
    end
    
    return {
        Chunks = chunks,
        Bounds = {
            Min = {bounds.Min.X, bounds.Min.Y, bounds.Min.Z},
            Max = {bounds.Max.X, bounds.Max.Y, bounds.Max.Z},
        },
        Resolution = resolution,
        ChunkSize = chunkSize,
    }
end

--// Get terrain properties
function Terrain.GetProperties()
    local terrain = Workspace.Terrain
    local props = {}
    
    pcall(function() props.WaterColor = terrain.WaterColor end)
    pcall(function() props.WaterReflectance = terrain.WaterReflectance end)
    pcall(function() props.WaterTransparency = terrain.WaterTransparency end)
    pcall(function() props.WaterWaveSize = terrain.WaterWaveSize end)
    pcall(function() props.WaterWaveSpeed = terrain.WaterWaveSpeed end)
    
    return props
end

return Terrain