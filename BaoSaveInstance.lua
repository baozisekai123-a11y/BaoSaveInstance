--[[
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
    
    BaoSaveInstance v3.0 - Advanced Decompiler & Game Saver
    Tác giả: BaoSaveInstance Engine
    Chức năng: Decompile + Export full game ra .rbxl duy nhất
    
    Hỗ trợ:
      • Full Game Save (Models + Scripts + Terrain + Properties)
      • Model Only Save
      • Terrain Only Save
      • Script Decompilation (readable Lua)
      • Single .rbxl output
]]

-- ============================================================
-- PHẦN 0: KIỂM TRA MÔI TRƯỜNG EXECUTOR
-- ============================================================

local ENV_CHECK = {}

-- Kiểm tra các hàm cần thiết từ executor
ENV_CHECK.requiredFunctions = {
    "writefile", "readfile", "isfile", "makefolder", "isfolder",
    "getgenv", "getrenv", "getrawmetatable", "hookfunction",
    "getgc", "getinstances", "getnilinstances", "getscripts",
    "getloadedmodules", "firesignal", "decompile",
    "saveinstance", "getconnections", "islclosure",
    "checkcaller", "newcclosure", "setclipboard"
}

ENV_CHECK.available = {}
ENV_CHECK.missing = {}

for _, funcName in ipairs(ENV_CHECK.requiredFunctions) do
    if getgenv and getgenv()[funcName] then
        ENV_CHECK.available[funcName] = true
    elseif _G[funcName] then
        ENV_CHECK.available[funcName] = true
    elseif pcall(function() return getfenv()[funcName] end) then
        ENV_CHECK.available[funcName] = true
    else
        ENV_CHECK.missing[#ENV_CHECK.missing + 1] = funcName
    end
end

-- Hàm lấy function an toàn
local function safeGetFunc(name)
    if getgenv and getgenv()[name] then
        return getgenv()[name]
    elseif _G[name] then
        return _G[name]
    end
    return nil
end

-- ============================================================
-- PHẦN 1: CORE MODULE - BaoSaveInstance API
-- ============================================================

local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance
BaoSaveInstance.Version = "3.0.0"
BaoSaveInstance.Name = "BaoSaveInstance"

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Chat = game:GetService("Chat")
local LocalizationService = game:GetService("LocalizationService")
local TestService = game:GetService("TestService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Teams = game:GetService("Teams")
local InsertService = game:GetService("InsertService")
local MaterialService = game:GetService("MaterialService")
local Terrain = Workspace.Terrain

-- ============================================================
-- PHẦN 2: CONFIGURATION - CẤU HÌNH NÂNG CAO
-- ============================================================

BaoSaveInstance.Config = {
    -- === Output Settings ===
    OutputFolder = "BaoSaveInstance",
    FileFormat = ".rbxl",
    
    -- === Decompile Settings ===
    DecompileScripts = true,            -- Decompile scripts thành readable Lua
    DecompileTimeout = 15,              -- Timeout cho mỗi script (giây)
    DecompileRetries = 3,               -- Số lần retry nếu decompile fail
    ParallelDecompile = true,           -- Decompile song song (nhanh hơn)
    MaxParallelThreads = 8,             -- Số thread tối đa cho parallel decompile
    DecompileBatchSize = 50,            -- Số script mỗi batch
    CacheDecompiledScripts = true,      -- Cache kết quả decompile
    
    -- === Save Settings ===
    SavePlayers = false,                -- Không save player instances
    SaveCamera = false,                 -- Không save camera
    SaveTerrain = true,                 -- Save terrain
    SaveNilInstances = true,            -- Save instances trong nil
    SaveHiddenProperties = true,        -- Save hidden properties
    SaveUnscriptable = true,            -- Save unscriptable properties
    
    -- === Performance Settings ===
    YieldInterval = 100,                -- Yield sau mỗi N instances
    TaskWaitTime = 0.001,               -- Thời gian wait giữa các yield (tối thiểu)
    MaxMemoryMB = 2048,                 -- Giới hạn memory sử dụng
    GCInterval = 500,                   -- Garbage collect sau mỗi N operations
    UseFastMode = true,                 -- Bật fast mode (bỏ qua một số check)
    
    -- === Services to Save ===
    ServicesToSave = {
        "Workspace",
        "ReplicatedStorage",
        "ReplicatedFirst",
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
        "Lighting",
        "SoundService",
        "Chat",
        "Teams",
        "LocalizationService",
        "MaterialService",
        "TestService"
    },
    
    -- === Exclusions ===
    ExcludeClassNames = {
        "Player", "PlayerGui", "PlayerScripts", "Backpack",
        "Camera", "Humanoid", -- Humanoid sẽ được handle riêng
    },
    
    ExcludeNames = {},
    
    -- === Script Decompile Priority ===
    ScriptPriority = {
        "ModuleScript",     -- Decompile ModuleScript trước (thường nhỏ hơn)
        "LocalScript",      -- Sau đó LocalScript
        "Script"            -- Cuối cùng là ServerScript
    }
}

-- ============================================================
-- PHẦN 3: UTILITY FUNCTIONS
-- ============================================================

local Util = {}

-- Log levels
Util.LogLevel = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

Util.CurrentLogLevel = Util.LogLevel.INFO
Util.Logs = {}

--- Ghi log với timestamp
function Util.log(level, message, ...)
    if level < Util.CurrentLogLevel then return end
    
    local levelNames = {[1]="DEBUG", [2]="INFO", [3]="WARN", [4]="ERROR"}
    local timestamp = os.date("%H:%M:%S")
    local formatted = string.format("[%s][%s][BaoSave] %s",
        timestamp, levelNames[level] or "?", 
        string.format(message, ...))
    
    table.insert(Util.Logs, formatted)
    
    if level >= Util.LogLevel.INFO then
        print(formatted)
    end
    
    -- Giới hạn log buffer
    if #Util.Logs > 10000 then
        local newLogs = {}
        for i = 5000, #Util.Logs do
            newLogs[#newLogs + 1] = Util.Logs[i]
        end
        Util.Logs = newLogs
    end
end

--- Đếm nhanh số descendants với yield để không crash
function Util.fastCountDescendants(instance)
    local count = 0
    local stack = {instance}
    local yieldCounter = 0
    
    while #stack > 0 do
        local current = table.remove(stack)
        local children = current:GetChildren()
        count = count + #children
        
        for i = 1, #children do
            stack[#stack + 1] = children[i]
        end
        
        yieldCounter = yieldCounter + #children
        if yieldCounter >= 5000 then
            yieldCounter = 0
            task.wait()
        end
    end
    
    return count
end

--- Tạo folder an toàn
function Util.ensureFolder(path)
    local makefolder = safeGetFunc("makefolder")
    local isfolder = safeGetFunc("isfolder")
    
    if makefolder and isfolder then
        if not isfolder(path) then
            makefolder(path)
        end
        return true
    end
    return false
end

--- Sanitize tên file (loại bỏ ký tự đặc biệt)
function Util.sanitizeFileName(name)
    -- Loại bỏ các ký tự không hợp lệ trong tên file
    name = name:gsub('[<>:"/\\|?*]', '_')
    name = name:gsub('%s+', '_')
    name = name:gsub('_+', '_')
    name = name:sub(1, 100) -- Giới hạn độ dài
    return name
end

--- Lấy tên game
function Util.getGameName()
    local gameName = "UnknownGame"
    
    pcall(function()
        local marketInfo = game:GetService("MarketplaceService")
            :GetProductInfo(game.PlaceId)
        if marketInfo and marketInfo.Name then
            gameName = marketInfo.Name
        end
    end)
    
    if gameName == "UnknownGame" then
        pcall(function()
            gameName = game:GetService("MarketplaceService")
                :GetProductInfo(game.GameId).Name
        end)
    end
    
    return Util.sanitizeFileName(gameName)
end

--- Đo thời gian thực thi
function Util.measureTime(func, label)
    local start = os.clock()
    local results = {func()}
    local elapsed = os.clock() - start
    Util.log(2, "%s hoàn thành trong %.3f giây", label, elapsed)
    return elapsed, unpack(results)
end

--- Kiểm tra memory và GC nếu cần
function Util.checkMemory(config)
    local memMB = collectgarbage("count") / 1024
    if memMB > (config.MaxMemoryMB or 2048) * 0.8 then
        collectgarbage("collect")
        task.wait(0.01)
        Util.log(3, "Memory cao (%.1f MB), đã GC", memMB)
    end
    return memMB
end

--- Safe pcall với retry
function Util.safeCall(func, retries, ...)
    retries = retries or 1
    local args = {...}
    
    for attempt = 1, retries do
        local success, result = pcall(func, unpack(args))
        if success then
            return true, result
        end
        
        if attempt < retries then
            task.wait(0.01 * attempt)
        else
            return false, result
        end
    end
end

BaoSaveInstance.Util = Util

-- ============================================================
-- PHẦN 4: SCRIPT DECOMPILER ENGINE (CẢI TIẾN TỐC ĐỘ)
-- ============================================================

local ScriptDecompiler = {}
ScriptDecompiler.__index = ScriptDecompiler

-- Cache để tránh decompile lại cùng 1 script
ScriptDecompiler.Cache = {}
ScriptDecompiler.Stats = {
    total = 0,
    success = 0,
    failed = 0,
    cached = 0,
    skipped = 0
}

--- Khởi tạo decompiler
function ScriptDecompiler.new(config)
    local self = setmetatable({}, ScriptDecompiler)
    self.config = config or BaoSaveInstance.Config
    self.decompileFunc = safeGetFunc("decompile")
    self.getscriptsFunc = safeGetFunc("getscripts")
    self.getloadedmodulesFunc = safeGetFunc("getloadedmodules")
    self.isReady = self.decompileFunc ~= nil
    
    -- Reset stats
    ScriptDecompiler.Stats = {
        total = 0, success = 0, failed = 0, cached = 0, skipped = 0
    }
    
    return self
end

--- Decompile 1 script đơn lẻ với timeout và retry
function ScriptDecompiler:decompileScript(scriptInstance)
    if not self.isReady then
        return false, "-- Decompile function không khả dụng"
    end
    
    if not scriptInstance then
        return false, "-- Script instance nil"
    end
    
    -- Kiểm tra cache
    local cacheKey = tostring(scriptInstance:GetDebugId())
    if self.config.CacheDecompiledScripts and ScriptDecompiler.Cache[cacheKey] then
        ScriptDecompiler.Stats.cached = ScriptDecompiler.Stats.cached + 1
        return true, ScriptDecompiler.Cache[cacheKey]
    end
    
    ScriptDecompiler.Stats.total = ScriptDecompiler.Stats.total + 1
    
    local source = nil
    local success = false
    local retries = self.config.DecompileRetries or 3
    
    for attempt = 1, retries do
        local ok, result = pcall(function()
            return self.decompileFunc(scriptInstance)
        end)
        
        if ok and result and type(result) == "string" and #result > 0 then
            source = result
            success = true
            break
        end
        
        -- Retry với delay tăng dần
        if attempt < retries then
            task.wait(0.05 * attempt)
        end
    end
    
    if success and source then
        -- Post-process: làm sạch source code
        source = self:postProcessSource(source, scriptInstance)
        
        -- Cache kết quả
        if self.config.CacheDecompiledScripts then
            ScriptDecompiler.Cache[cacheKey] = source
        end
        
        ScriptDecompiler.Stats.success = ScriptDecompiler.Stats.success + 1
        return true, source
    else
        ScriptDecompiler.Stats.failed = ScriptDecompiler.Stats.failed + 1
        local fallback = string.format(
            "-- [BaoSaveInstance] Decompile failed cho: %s\n" ..
            "-- Class: %s\n" ..
            "-- Path: %s\n" ..
            "-- Lý do: Executor không thể decompile script này\n",
            scriptInstance.Name,
            scriptInstance.ClassName,
            scriptInstance:GetFullName()
        )
        return false, fallback
    end
end

--- Post-process source code (làm sạch, thêm header)
function ScriptDecompiler:postProcessSource(source, scriptInstance)
    -- Thêm header comment
    local header = string.format(
        "--[[\n" ..
        "    Decompiled bởi BaoSaveInstance v%s\n" ..
        "    Script: %s\n" ..
        "    Class: %s\n" ..
        "    Path: %s\n" ..
        "    Time: %s\n" ..
        "]]--\n\n",
        BaoSaveInstance.Version,
        scriptInstance.Name,
        scriptInstance.ClassName,
        scriptInstance:GetFullName(),
        os.date("%Y-%m-%d %H:%M:%S")
    )
    
    -- Loại bỏ các dòng thừa từ decompiler
    source = source:gsub("^%s*\n", "") -- Bỏ dòng trống đầu
    
    return header .. source
end

--- Decompile hàng loạt scripts (BATCH - TỐC ĐỘ CAO)
function ScriptDecompiler:batchDecompile(scripts, progressCallback)
    if not self.isReady then
        Util.log(4, "Decompile function không khả dụng!")
        return {}
    end
    
    local results = {}
    local total = #scripts
    local batchSize = self.config.DecompileBatchSize or 50
    local processed = 0
    
    Util.log(2, "Bắt đầu batch decompile %d scripts...", total)
    
    -- Sắp xếp theo priority (ModuleScript trước vì thường nhỏ)
    local priorityOrder = {}
    for i, className in ipairs(self.config.ScriptPriority) do
        priorityOrder[className] = i
    end
    
    table.sort(scripts, function(a, b)
        local pa = priorityOrder[a.ClassName] or 99
        local pb = priorityOrder[b.ClassName] or 99
        if pa == pb then
            -- Script nhỏ hơn decompile trước (heuristic)
            return a.Name < b.Name
        end
        return pa < pb
    end)
    
    -- Decompile theo batch
    for batchStart = 1, total, batchSize do
        local batchEnd = math.min(batchStart + batchSize - 1, total)
        
        for i = batchStart, batchEnd do
            local script = scripts[i]
            
            if script and script.Parent ~= nil or self.config.SaveNilInstances then
                local ok, source = self:decompileScript(script)
                results[script] = {
                    success = ok,
                    source = source,
                    className = script.ClassName,
                    fullName = pcall(function() return script:GetFullName() end) 
                        and script:GetFullName() or "Unknown"
                }
            else
                ScriptDecompiler.Stats.skipped = ScriptDecompiler.Stats.skipped + 1
            end
            
            processed = processed + 1
            
            -- Gọi callback cập nhật progress
            if progressCallback then
                progressCallback(processed, total, script)
            end
        end
        
        -- Yield giữa các batch để không crash
        task.wait(self.config.TaskWaitTime or 0.001)
        
        -- Kiểm tra memory
        if processed % (batchSize * 5) == 0 then
            Util.checkMemory(self.config)
        end
    end
    
    Util.log(2, "Batch decompile hoàn thành: %d/%d thành công, %d cached, %d failed, %d skipped",
        ScriptDecompiler.Stats.success,
        ScriptDecompiler.Stats.total,
        ScriptDecompiler.Stats.cached,
        ScriptDecompiler.Stats.failed,
        ScriptDecompiler.Stats.skipped)
    
    return results
end

--- Thu thập tất cả scripts trong game
function ScriptDecompiler:collectAllScripts()
    local allScripts = {}
    local seen = {}
    
    -- Phương pháp 1: Dùng getscripts() nếu có
    if self.getscriptsFunc then
        local ok, scripts = pcall(self.getscriptsFunc)
        if ok and scripts then
            for _, s in ipairs(scripts) do
                local id = tostring(s:GetDebugId())
                if not seen[id] then
                    seen[id] = true
                    allScripts[#allScripts + 1] = s
                end
            end
        end
    end
    
    -- Phương pháp 2: Dùng getloadedmodules() nếu có
    if self.getloadedmodulesFunc then
        local ok, modules = pcall(self.getloadedmodulesFunc)
        if ok and modules then
            for _, m in ipairs(modules) do
                local id = tostring(m:GetDebugId())
                if not seen[id] then
                    seen[id] = true
                    allScripts[#allScripts + 1] = m
                end
            end
        end
    end
    
    -- Phương pháp 3: Quét services thủ công (fallback)
    local servicesToScan = {
        Workspace, ReplicatedStorage, ReplicatedFirst,
        StarterGui, StarterPack, StarterPlayer,
        Lighting, SoundService, Chat, Teams
    }
    
    for _, service in ipairs(servicesToScan) do
        pcall(function()
            local stack = {service}
            local yieldCount = 0
            
            while #stack > 0 do
                local current = table.remove(stack)
                
                if current:IsA("LuaSourceContainer") then
                    local id = tostring(current:GetDebugId())
                    if not seen[id] then
                        seen[id] = true
                        allScripts[#allScripts + 1] = current
                    end
                end
                
                local childrenOk, children = pcall(function()
                    return current:GetChildren()
                end)
                
                if childrenOk and children then
                    for _, child in ipairs(children) do
                        stack[#stack + 1] = child
                    end
                end
                
                yieldCount = yieldCount + 1
                if yieldCount >= 2000 then
                    yieldCount = 0
                    task.wait()
                end
            end
        end)
    end
    
    -- Phương pháp 4: Nil instances
    if self.config.SaveNilInstances then
        local getNilFunc = safeGetFunc("getnilinstances")
        if getNilFunc then
            local ok, nilInstances = pcall(getNilFunc)
            if ok and nilInstances then
                for _, inst in ipairs(nilInstances) do
                    if inst:IsA("LuaSourceContainer") then
                        local id = tostring(inst:GetDebugId())
                        if not seen[id] then
                            seen[id] = true
                            allScripts[#allScripts + 1] = inst
                        end
                    end
                end
            end
        end
    end
    
    Util.log(2, "Thu thập được %d scripts tổng cộng", #allScripts)
    return allScripts
end

--- Xóa cache (giải phóng memory)
function ScriptDecompiler:clearCache()
    ScriptDecompiler.Cache = {}
    collectgarbage("collect")
end

BaoSaveInstance.ScriptDecompiler = ScriptDecompiler

-- ============================================================
-- PHẦN 5: TERRAIN SAVER ENGINE
-- ============================================================

local TerrainSaver = {}
TerrainSaver.__index = TerrainSaver

function TerrainSaver.new(config)
    local self = setmetatable({}, TerrainSaver)
    self.config = config or BaoSaveInstance.Config
    self.terrain = Workspace.Terrain
    return self
end

--- Lấy thông tin terrain
function TerrainSaver:getTerrainInfo()
    local info = {
        hasData = false,
        regionSize = Vector3.new(0, 0, 0),
        materialCount = 0,
        hasWater = false
    }
    
    pcall(function()
        -- Kiểm tra xem terrain có dữ liệu không
        local regionStart = self.terrain:CellCenterToWorld(-250, -250, -250)
        local regionEnd = self.terrain:CellCenterToWorld(250, 250, 250)
        
        local region = Region3.new(
            Vector3.new(-2044, -2044, -2044),
            Vector3.new(2044, 2044, 2044)
        )
        
        -- Align region to terrain grid
        region = region:ExpandToGrid(4)
        
        local materials, occupancy = self.terrain:ReadVoxels(region, 4)
        
        if materials and materials.Size then
            info.regionSize = materials.Size
            info.hasData = materials.Size.X > 0 and 
                          materials.Size.Y > 0 and 
                          materials.Size.Z > 0
            
            -- Đếm materials (sampling)
            local matSet = {}
            local size = materials.Size
            local step = math.max(1, math.floor(size.X / 20))
            
            for x = 1, size.X, step do
                for y = 1, size.Y, step do
                    for z = 1, size.Z, step do
                        local mat = materials[x][y][z]
                        if mat ~= Enum.Material.Air then
                            matSet[mat] = true
                            if mat == Enum.Material.Water then
                                info.hasWater = true
                            end
                        end
                    end
                end
            end
            
            for _ in pairs(matSet) do
                info.materialCount = info.materialCount + 1
            end
        end
    end)
    
    return info
end

--- Kiểm tra terrain có dữ liệu không
function TerrainSaver:hasTerrain()
    local info = self:getTerrainInfo()
    return info.hasData
end

BaoSaveInstance.TerrainSaver = TerrainSaver

-- ============================================================
-- PHẦN 6: INSTANCE COLLECTOR (THU THẬP NHANH)
-- ============================================================

local InstanceCollector = {}
InstanceCollector.__index = InstanceCollector

function InstanceCollector.new(config)
    local self = setmetatable({}, InstanceCollector)
    self.config = config or BaoSaveInstance.Config
    
    -- Build exclusion sets cho O(1) lookup
    self.excludeClassSet = {}
    for _, className in ipairs(config.ExcludeClassNames or {}) do
        self.excludeClassSet[className] = true
    end
    
    self.excludeNameSet = {}
    for _, name in ipairs(config.ExcludeNames or {}) do
        self.excludeNameSet[name] = true
    end
    
    return self
end

--- Kiểm tra instance có nên được save không
function InstanceCollector:shouldSave(instance)
    if not instance then return false end
    
    -- Kiểm tra class exclusion
    if self.excludeClassSet[instance.ClassName] then
        return false
    end
    
    -- Kiểm tra name exclusion
    if self.excludeNameSet[instance.Name] then
        return false
    end
    
    -- Không save BaoSaveInstance UI
    if instance.Name == "BaoSaveInstanceUI" then
        return false
    end
    
    return true
end

--- Thu thập instances từ 1 service
function InstanceCollector:collectFromService(service, progressCallback)
    local instances = {}
    local count = 0
    
    local ok, err = pcall(function()
        local stack = {}
        local children = service:GetChildren()
        
        for i = #children, 1, -1 do
            stack[#stack + 1] = children[i]
        end
        
        while #stack > 0 do
            local current = table.remove(stack)
            
            if self:shouldSave(current) then
                count = count + 1
                instances[#instances + 1] = current
                
                local childOk, childList = pcall(function()
                    return current:GetChildren()
                end)
                
                if childOk and childList then
                    for i = #childList, 1, -1 do
                        stack[#stack + 1] = childList[i]
                    end
                end
                
                -- Yield để không crash
                if count % self.config.YieldInterval == 0 then
                    task.wait(self.config.TaskWaitTime)
                    if progressCallback then
                        progressCallback(count)
                    end
                end
            end
        end
    end)
    
    if not ok then
        Util.log(3, "Lỗi khi quét service %s: %s",
            tostring(service), tostring(err))
    end
    
    return instances, count
end

--- Thu thập models từ workspace và replicated storage
function InstanceCollector:collectModels()
    local models = {}
    local sources = {Workspace, ReplicatedStorage}
    
    for _, source in ipairs(sources) do
        pcall(function()
            local children = source:GetChildren()
            for _, child in ipairs(children) do
                if child:IsA("Model") or child:IsA("Folder") then
                    if self:shouldSave(child) then
                        models[#models + 1] = child
                    end
                end
            end
        end)
    end
    
    Util.log(2, "Thu thập được %d models", #models)
    return models
end

BaoSaveInstance.InstanceCollector = InstanceCollector

-- ============================================================
-- PHẦN 7: RBXL EXPORTER ENGINE
-- ============================================================

local RBXLExporter = {}
RBXLExporter.__index = RBXLExporter

function RBXLExporter.new(config)
    local self = setmetatable({}, RBXLExporter)
    self.config = config or BaoSaveInstance.Config
    self.saveinstanceFunc = safeGetFunc("saveinstance")
    self.writefileFunc = safeGetFunc("writefile")
    return self
end

--- Xây dựng options cho saveinstance dựa trên mode
function RBXLExporter:buildOptions(mode)
    local options = {
        -- Output
        FileName = self:getFileName(mode),
        FilePath = self.config.OutputFolder,
        
        -- Features
        DecompileScripts = self.config.DecompileScripts,
        NilInstances = self.config.SaveNilInstances,
        RemovePlayerCharacters = not self.config.SavePlayers,
        SavePlayers = self.config.SavePlayers,
        
        -- Performance
        DecompileTimeout = self.config.DecompileTimeout,
        DecompileIgnore = {},
        
        -- Mode-specific
        Mode = mode
    }
    
    -- Cấu hình theo mode
    if mode == "FULL_GAME" then
        options.NilInstances = true
        options.DecompileScripts = true
        options.SaveTerrain = true
        
    elseif mode == "MODEL_ONLY" then
        options.NilInstances = false
        options.SaveTerrain = false
        -- Chỉ save Workspace + ReplicatedStorage models
        options.ExtraInstances = self:getModelInstances()
        
    elseif mode == "TERRAIN_ONLY" then
        options.NilInstances = false
        options.DecompileScripts = false
        options.SaveTerrain = true
        options.ExtraInstances = {Workspace.Terrain}
    end
    
    return options
end

--- Lấy tên file output
function RBXLExporter:getFileName(mode)
    local gameName = Util.getGameName()
    local suffix = {
        FULL_GAME = "_Full",
        MODEL_ONLY = "_Model",
        TERRAIN_ONLY = "_Terrain"
    }
    
    return gameName .. (suffix[mode] or "_Export") .. self.config.FileFormat
end

--- Lấy model instances cho MODEL_ONLY mode
function RBXLExporter:getModelInstances()
    local instances = {}
    
    pcall(function()
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Model") or child:IsA("Folder") or 
               child:IsA("Part") or child:IsA("MeshPart") then
                if child.Name ~= "Terrain" and child.Name ~= "Camera" then
                    instances[#instances + 1] = child
                end
            end
        end
    end)
    
    pcall(function()
        for _, child in ipairs(ReplicatedStorage:GetChildren()) do
            instances[#instances + 1] = child
        end
    end)
    
    return instances
end

--- Export chính - sử dụng saveinstance của executor
function RBXLExporter:export(mode, progressCallback)
    mode = mode or "FULL_GAME"
    
    -- Đảm bảo folder tồn tại
    Util.ensureFolder(self.config.OutputFolder)
    
    local fileName = self:getFileName(mode)
    local fullPath = self.config.OutputFolder .. "/" .. fileName
    
    Util.log(2, "Bắt đầu export mode: %s", mode)
    Util.log(2, "Output: %s", fullPath)
    
    if progressCallback then
        progressCallback("Đang chuẩn bị export...")
    end
    
    -- Phương pháp 1: Dùng saveinstance() native của executor (NHANH NHẤT)
    if self.saveinstanceFunc then
        return self:exportWithSaveInstance(mode, progressCallback)
    end
    
    -- Phương pháp 2: Manual export (fallback)
    return self:exportManual(mode, progressCallback)
end

--- Export sử dụng saveinstance() native
function RBXLExporter:exportWithSaveInstance(mode, progressCallback)
    local options = self:buildOptions(mode)
    
    if progressCallback then
        progressCallback("Đang save với executor saveinstance...")
    end
    
    local success, err = pcall(function()
        -- Các executor khác nhau có API khác nhau
        -- Synapse X style
        if syn and syn.saveinstance then
            syn.saveinstance(game, options.FileName, {
                DecompileMode = options.DecompileScripts and "decompile" or "none",
                NilInstances = options.NilInstances,
                RemovePlayerCharacters = options.RemovePlayerCharacters,
                DecompileTimeout = options.DecompileTimeout,
                FilePath = options.FilePath
            })
            return
        end
        
        -- Unified saveinstance API (Wave, Fluxus, etc.)
        local saveFunc = safeGetFunc("saveinstance")
        if saveFunc then
            -- Thử format mới trước
            local siOptions = {}
            
            -- Mode handling
            if mode == "FULL_GAME" then
                siOptions = {
                    FileName = options.FileName,
                    DecompileMode = 2, -- Full decompile
                    NilInstances = true,
                    DecompileTimeout = options.DecompileTimeout,
                    SavePlayers = false,
                    RemovePlayerCharacters = true,
                    SaveNonCreatable = true,
                    IsolateStarterPlayer = true,
                    IgnoreDefaultProperties = false,
                    SharedStrings = true,
                    ShowStatus = true,
                    Timeout = 30,
                    SaveBytecode = false,
                    NilInstancesFix = true
                }
            elseif mode == "MODEL_ONLY" then
                siOptions = {
                    FileName = options.FileName,
                    DecompileMode = 2,
                    NilInstances = false,
                    ExtraInstances = options.ExtraInstances or {},
                    SavePlayers = false,
                    RemovePlayerCharacters = true,
                    IgnoreDefaultProperties = false,
                    ShowStatus = true
                }
            elseif mode == "TERRAIN_ONLY" then
                siOptions = {
                    FileName = options.FileName,
                    DecompileMode = 0,
                    NilInstances = false,
                    ExtraInstances = {Workspace.Terrain},
                    SavePlayers = false,
                    ShowStatus = true
                }
            end
            
            saveFunc(siOptions)
            return
        end
    end)
    
    if success then
        local fileName = self:getFileName(mode)
        Util.log(2, "Export thành công: %s", fileName)
        if progressCallback then
            progressCallback("Done ✓ - " .. fileName)
        end
        return true, fileName
    else
        Util.log(4, "Export thất bại: %s", tostring(err))
        if progressCallback then
            progressCallback("Lỗi: " .. tostring(err))
        end
        return false, tostring(err)
    end
end

--- Manual export fallback (khi không có saveinstance)
function RBXLExporter:exportManual(mode, progressCallback)
    if progressCallback then
        progressCallback("Executor không hỗ trợ saveinstance!\nThử phương pháp thủ công...")
    end
    
    -- Phương pháp thủ công: serialize instances thành XML format
    local xmlBuilder = XMLBuilder.new()
    
    if mode == "FULL_GAME" or mode == "MODEL_ONLY" then
        -- Thu thập instances
        local collector = InstanceCollector.new(self.config)
        
        local services = {}
        if mode == "FULL_GAME" then
            for _, serviceName in ipairs(self.config.ServicesToSave) do
                pcall(function()
                    services[#services + 1] = game:GetService(serviceName)
                end)
            end
        else
            services = {Workspace, ReplicatedStorage}
        end
        
        -- Decompile scripts nếu cần
        if self.config.DecompileScripts then
            if progressCallback then
                progressCallback("Decompile Scripts...")
            end
            
            local decompiler = ScriptDecompiler.new(self.config)
            local allScripts = decompiler:collectAllScripts()
            local results = decompiler:batchDecompile(allScripts, function(done, total, script)
                if progressCallback and done % 10 == 0 then
                    progressCallback(string.format("Decompile Scripts... %d/%d", done, total))
                end
            end)
            
            -- Apply decompiled source vào scripts
            for script, data in pairs(results) do
                if data.success then
                    pcall(function()
                        -- Lưu source vào attribute để saveinstance lấy
                        script:SetAttribute("BaoDecompiledSource", data.source)
                    end)
                end
            end
            
            decompiler:clearCache()
        end
        
        if progressCallback then
            progressCallback("Đang serialize instances...")
        end
    end
    
    -- Ghi file
    local writeFunc = safeGetFunc("writefile")
    if writeFunc then
        local fileName = self:getFileName(mode)
        
        if progressCallback then
            progressCallback("Đang ghi file " .. fileName .. "...")
        end
        
        -- Thực tế, manual RBXL export rất phức tạp
        -- Khuyến nghị sử dụng executor có saveinstance
        Util.log(3, "Manual export cần executor hỗ trợ saveinstance để tạo .rbxl")
        
        if progressCallback then
            progressCallback("⚠ Cần executor hỗ trợ saveinstance!")
        end
        
        return false, "Executor không hỗ trợ saveinstance native"
    end
    
    return false, "Không có writefile function"
end

BaoSaveInstance.RBXLExporter = RBXLExporter

-- ============================================================
-- PHẦN 8: XML BUILDER (CHO MANUAL EXPORT)
-- ============================================================

local XMLBuilder = {}
XMLBuilder.__index = XMLBuilder

function XMLBuilder.new()
    local self = setmetatable({}, XMLBuilder)
    self.buffer = {}
    self.indent = 0
    return self
end

function XMLBuilder:addLine(line)
    local prefix = string.rep("  ", self.indent)
    self.buffer[#self.buffer + 1] = prefix .. line
end

function XMLBuilder:openTag(tag, attrs)
    local attrStr = ""
    if attrs then
        for k, v in pairs(attrs) do
            attrStr = attrStr .. string.format(' %s="%s"', k, tostring(v))
        end
    end
    self:addLine("<" .. tag .. attrStr .. ">")
    self.indent = self.indent + 1
end

function XMLBuilder:closeTag(tag)
    self.indent = self.indent - 1
    self:addLine("</" .. tag .. ">")
end

function XMLBuilder:addProperty(name, type, value)
    self:addLine(string.format('<%s name="%s">%s</%s>',
        type, name, tostring(value), type))
end

function XMLBuilder:build()
    return table.concat(self.buffer, "\n")
end

BaoSaveInstance.XMLBuilder = XMLBuilder

-- ============================================================
-- PHẦN 9: MAIN API FUNCTIONS
-- ============================================================

-- Trạng thái hiện tại
BaoSaveInstance.State = {
    isRunning = false,
    currentMode = nil,
    progress = 0,
    status = "Idle",
    startTime = 0,
    lastError = nil
}

--- Khởi tạo BaoSaveInstance
function BaoSaveInstance.init()
    Util.log(2, "═══════════════════════════════════════")
    Util.log(2, "BaoSaveInstance v%s đang khởi tạo...", BaoSaveInstance.Version)
    Util.log(2, "═══════════════════════════════════════")
    
    -- Kiểm tra môi trường
    local missingCount = #ENV_CHECK.missing
    if missingCount > 0 then
        Util.log(3, "Thiếu %d functions: %s",
            missingCount, table.concat(ENV_CHECK.missing, ", "))
    end
    
    -- Kiểm tra saveinstance
    local hasSaveInstance = safeGetFunc("saveinstance") ~= nil 
        or (syn and syn.saveinstance ~= nil)
    
    if hasSaveInstance then
        Util.log(2, "✓ saveinstance khả dụng - Sử dụng native export")
    else
        Util.log(3, "✗ saveinstance KHÔNG khả dụng - Chức năng giới hạn")
    end
    
    -- Kiểm tra decompile
    local hasDecompile = safeGetFunc("decompile") ~= nil
    if hasDecompile then
        Util.log(2, "✓ decompile khả dụng")
    else
        Util.log(3, "✗ decompile KHÔNG khả dụng")
    end
    
    -- Tạo output folder
    Util.ensureFolder(BaoSaveInstance.Config.OutputFolder)
    
    -- Lấy thông tin game
    local gameName = Util.getGameName()
    Util.log(2, "Game: %s (PlaceId: %d)", gameName, game.PlaceId)
    
    -- Thông tin nhanh
    local totalDesc = 0
    pcall(function()
        totalDesc = #game:GetDescendants()
    end)
    Util.log(2, "Tổng instances: ~%d", totalDesc)
    
    BaoSaveInstance.State.status = "Ready"
    Util.log(2, "Khởi tạo hoàn tất!")
    
    return true
end

--- Decompile tất cả scripts
function BaoSaveInstance.decompileScripts(progressCallback)
    BaoSaveInstance.State.isRunning = true
    BaoSaveInstance.State.status = "Decompile Scripts..."
    BaoSaveInstance.State.startTime = os.clock()
    
    local decompiler = ScriptDecompiler.new(BaoSaveInstance.Config)
    
    if not decompiler.isReady then
        BaoSaveInstance.State.isRunning = false
        BaoSaveInstance.State.status = "Error: No decompile function"
        return false, "Decompile function không khả dụng"
    end
    
    -- Thu thập scripts
    if progressCallback then progressCallback("Thu thập scripts...") end
    local allScripts = decompiler:collectAllScripts()
    
    -- Batch decompile
    local results = decompiler:batchDecompile(allScripts, function(done, total, script)
        local pct = math.floor(done / total * 100)
        BaoSaveInstance.State.progress = pct
        BaoSaveInstance.State.status = string.format(
            "Decompile: %d/%d (%d%%)", done, total, pct)
        
        if progressCallback then
            progressCallback(BaoSaveInstance.State.status)
        end
    end)
    
    local elapsed = os.clock() - BaoSaveInstance.State.startTime
    BaoSaveInstance.State.isRunning = false
    BaoSaveInstance.State.status = string.format(
        "Decompile Done ✓ (%.1fs) - %d/%d thành công",
        elapsed, ScriptDecompiler.Stats.success, ScriptDecompiler.Stats.total)
    
    Util.log(2, BaoSaveInstance.State.status)
    
    -- Cleanup
    decompiler:clearCache()
    
    return true, results
end

--- Save models
function BaoSaveInstance.saveModels(progressCallback)
    BaoSaveInstance.State.isRunning = true
    BaoSaveInstance.State.status = "Saving Models..."
    
    if progressCallback then progressCallback("Thu thập models...") end
    
    local collector = InstanceCollector.new(BaoSaveInstance.Config)
    local models = collector:collectModels()
    
    BaoSaveInstance.State.status = string.format("Tìm thấy %d models", #models)
    if progressCallback then progressCallback(BaoSaveInstance.State.status) end
    
    -- Export
    local exporter = RBXLExporter.new(BaoSaveInstance.Config)
    local success, result = exporter:export("MODEL_ONLY", progressCallback)
    
    BaoSaveInstance.State.isRunning = false
    return success, result
end

--- Save terrain
function BaoSaveInstance.saveTerrain(progressCallback)
    BaoSaveInstance.State.isRunning = true
    BaoSaveInstance.State.status = "Saving Terrain..."
    
    if progressCallback then progressCallback("Kiểm tra terrain...") end
    
    local terrainSaver = TerrainSaver.new(BaoSaveInstance.Config)
    local terrainInfo = terrainSaver:getTerrainInfo()
    
    if not terrainInfo.hasData then
        BaoSaveInstance.State.isRunning = false
        BaoSaveInstance.State.status = "Không tìm thấy terrain data"
        if progressCallback then progressCallback("⚠ Không có terrain data!") end
        return false, "No terrain data"
    end
    
    Util.log(2, "Terrain info: Size=%s, Materials=%d, Water=%s",
        tostring(terrainInfo.regionSize),
        terrainInfo.materialCount,
        tostring(terrainInfo.hasWater))
    
    if progressCallback then
        progressCallback(string.format("Terrain: %d materials, Water: %s",
            terrainInfo.materialCount, terrainInfo.hasWater and "Yes" or "No"))
    end
    
    -- Export
    local exporter = RBXLExporter.new(BaoSaveInstance.Config)
    local success, result = exporter:export("TERRAIN_ONLY", progressCallback)
    
    BaoSaveInstance.State.isRunning = false
    return success, result
end

--- Export ra file .rbxl
function BaoSaveInstance.exportRBXL(mode, progressCallback)
    if BaoSaveInstance.State.isRunning then
        return false, "Đang có tiến trình chạy!"
    end
    
    mode = mode or "FULL_GAME"
    
    BaoSaveInstance.State.isRunning = true
    BaoSaveInstance.State.currentMode = mode
    BaoSaveInstance.State.startTime = os.clock()
    BaoSaveInstance.State.progress = 0
    
    Util.log(2, "════════════════════════════════════")
    Util.log(2, "BẮT ĐẦU EXPORT: %s", mode)
    Util.log(2, "════════════════════════════════════")
    
    local exporter = RBXLExporter.new(BaoSaveInstance.Config)
    
    local statusCallback = function(status)
        BaoSaveInstance.State.status = status
        if progressCallback then
            progressCallback(status)
        end
    end
    
    -- Pre-decompile nếu cần
    if mode ~= "TERRAIN_ONLY" and BaoSaveInstance.Config.DecompileScripts then
        statusCallback("Decompile Scripts...")
        -- Decompile sẽ được xử lý bởi saveinstance native
        -- hoặc chạy riêng nếu cần
    end
    
    -- Export
    local success, result = exporter:export(mode, statusCallback)
    
    local elapsed = os.clock() - BaoSaveInstance.State.startTime
    
    BaoSaveInstance.State.isRunning = false
    BaoSaveInstance.State.progress = success and 100 or 0
    
    if success then
        BaoSaveInstance.State.status = string.format(
            "Done ✓ - %s (%.1fs)", result, elapsed)
        Util.log(2, "Export thành công: %s trong %.1f giây", result, elapsed)
    else
        BaoSaveInstance.State.status = "Error: " .. tostring(result)
        BaoSaveInstance.State.lastError = result
        Util.log(4, "Export thất bại: %s", tostring(result))
    end
    
    return success, result
end

-- ============================================================
-- PHẦN 10: CUSTOM SAVEINSTANCE (ENHANCED)
-- ============================================================

--[[
    Custom saveinstance wrapper với các tối ưu:
    1. Pre-decompile scripts trước khi save
    2. Cleanup instances không cần thiết
    3. Progress tracking
    4. Error handling tốt hơn
]]

local CustomSaveInstance = {}

function CustomSaveInstance.execute(mode, progressCallback)
    local saveFunc = safeGetFunc("saveinstance")
    
    if not saveFunc then
        return false, "saveinstance not available"
    end
    
    local gameName = Util.getGameName()
    local fileName
    
    -- Xác định filename
    if mode == "FULL_GAME" then
        fileName = gameName .. "_Full.rbxl"
    elseif mode == "MODEL_ONLY" then
        fileName = gameName .. "_Model.rbxl"
    elseif mode == "TERRAIN_ONLY" then
        fileName = gameName .. "_Terrain.rbxl"
    else
        fileName = gameName .. "_Export.rbxl"
    end
    
    -- Build save options tối ưu
    local options = {
        -- Tên file output
        FileName = fileName,
        
        -- ═══ Decompile Settings ═══
        -- Mode 0: Không decompile
        -- Mode 1: Decompile đơn giản
        -- Mode 2: Decompile đầy đủ
        DecompileMode = (mode ~= "TERRAIN_ONLY") and 2 or 0,
        DecompileTimeout = BaoSaveInstance.Config.DecompileTimeout,
        
        -- ═══ Instance Settings ═══
        NilInstances = (mode == "FULL_GAME"),
        NilInstancesFix = true,
        
        -- ═══ Player Settings ═══
        SavePlayers = false,
        RemovePlayerCharacters = true,
        IsolateStarterPlayer = true,
        IsolateLocalPlayer = true,
        IsolateLocalPlayerCharacter = true,
        
        -- ═══ Property Settings ═══
        IgnoreDefaultProperties = false,
        SaveNonCreatable = true,
        SharedStrings = true,
        Binary = true,  -- .rbxl format (binary)
        
        -- ═══ Script Settings ═══
        SaveBytecode = false,
        ScriptCache = true,
        
        -- ═══ Performance ═══
        MaxThreads = BaoSaveInstance.Config.MaxParallelThreads,
        ShowStatus = true,
        
        -- ═══ Extra ═══
        ReadMe = false,
        SafeMode = false,
        AntiIdle = true
    }
    
    -- Mode-specific overrides
    if mode == "MODEL_ONLY" then
        -- Thu thập model instances
        local modelInstances = {}
        
        pcall(function()
            for _, child in ipairs(Workspace:GetChildren()) do
                if child.Name ~= "Terrain" and child.ClassName ~= "Camera" 
                   and child.ClassName ~= "Player" then
                    modelInstances[#modelInstances + 1] = child
                end
            end
        end)
        
        pcall(function()
            for _, child in ipairs(ReplicatedStorage:GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        pcall(function()
            for _, child in ipairs(ReplicatedFirst:GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        pcall(function()
            for _, child in ipairs(StarterGui:GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        pcall(function()
            for _, child in ipairs(StarterPack:GetChildren()) do
                modelInstances[#modelInstances + 1] = child
            end
        end)
        
        options.ExtraInstances = modelInstances
        options.NilInstances = false
        
    elseif mode == "TERRAIN_ONLY" then
        options.ExtraInstances = {Workspace.Terrain}
        options.NilInstances = false
        options.DecompileMode = 0
        options.IgnoreDefaultProperties = true
    end
    
    -- Callback trước khi save
    if progressCallback then
        progressCallback("Saving... " .. fileName)
    end
    
    -- Thực hiện save
    local success, err = pcall(function()
        saveFunc(options)
    end)
    
    if not success then
        -- Thử lại với options đơn giản hơn
        Util.log(3, "Save thất bại với options đầy đủ, thử simplified...")
        
        local simpleOptions = {
            FileName = fileName,
            DecompileMode = (mode ~= "TERRAIN_ONLY") and 2 or 0,
            NilInstances = (mode == "FULL_GAME"),
            SavePlayers = false,
        }
        
        if mode == "MODEL_ONLY" then
            simpleOptions.ExtraInstances = options.ExtraInstances
        elseif mode == "TERRAIN_ONLY" then
            simpleOptions.ExtraInstances = {Workspace.Terrain}
        end
        
        success, err = pcall(function()
            saveFunc(simpleOptions)
        end)
        
        if not success then
            -- Thử lần cuối - chỉ filename
            success, err = pcall(function()
                saveFunc({FileName = fileName})
            end)
        end
    end
    
    return success, success and fileName or tostring(err)
end

BaoSaveInstance.CustomSaveInstance = CustomSaveInstance

-- ============================================================
-- PHẦN 11: UI SYSTEM
-- ============================================================

local UI = {}
UI.Colors = {
    Background = Color3.fromRGB(20, 20, 30),
    BackgroundDark = Color3.fromRGB(15, 15, 22),
    Accent = Color3.fromRGB(88, 130, 255),
    AccentHover = Color3.fromRGB(108, 150, 255),
    AccentDark = Color3.fromRGB(60, 90, 200),
    Success = Color3.fromRGB(80, 200, 120),
    Error = Color3.fromRGB(255, 80, 80),
    Warning = Color3.fromRGB(255, 200, 60),
    Text = Color3.fromRGB(230, 230, 240),
    TextDim = Color3.fromRGB(150, 150, 170),
    Border = Color3.fromRGB(50, 50, 70),
    ButtonBg = Color3.fromRGB(35, 35, 50),
    ButtonHover = Color3.fromRGB(45, 45, 65),
    Shadow = Color3.fromRGB(0, 0, 0)
}

--- Tạo toàn bộ UI
function UI.create()
    -- Xóa UI cũ nếu có
    local oldGui = CoreGui:FindFirstChild("BaoSaveInstanceUI")
    if oldGui then oldGui:Destroy() end
    
    pcall(function()
        local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local old = playerGui:FindFirstChild("BaoSaveInstanceUI")
            if old then old:Destroy() end
        end
    end)
    
    -- ═══ ScreenGui ═══
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstanceUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999999
    
    -- Thử mount vào CoreGui, fallback PlayerGui
    local mountSuccess = pcall(function()
        screenGui.Parent = CoreGui
    end)
    
    if not mountSuccess then
        pcall(function()
            screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end)
    end
    
    -- ═══ Main Frame ═══
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 380, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -260)
    mainFrame.BackgroundColor3 = UI.Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = screenGui
    
    -- Corner rounding
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- Shadow (fake)
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 8, 1, 8)
    shadow.Position = UDim2.new(0, -4, 0, -4)
    shadow.BackgroundColor3 = UI.Colors.Shadow
    shadow.BackgroundTransparency = 0.6
    shadow.BorderSizePixel = 0
    shadow.ZIndex = -1
    shadow.Parent = mainFrame
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 14)
    shadowCorner.Parent = shadow
    
    -- ═══ Title Bar ═══
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = UI.Colors.BackgroundDark
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Fix bottom corners of title bar
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 12)
    titleFix.Position = UDim2.new(0, 0, 1, -12)
    titleFix.BackgroundColor3 = UI.Colors.BackgroundDark
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔧 BaoSaveInstance v" .. BaoSaveInstance.Version
    titleLabel.TextColor3 = UI.Colors.Text
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- Minimize button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.Position = UDim2.new(1, -70, 0, 10)
    minimizeBtn.BackgroundColor3 = UI.Colors.ButtonBg
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Text = "─"
    minimizeBtn.TextColor3 = UI.Colors.TextDim
    minimizeBtn.TextSize = 14
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = titleBar
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = minimizeBtn
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 10)
    closeBtn.BackgroundColor3 = UI.Colors.Error
    closeBtn.BackgroundTransparency = 0.7
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = UI.Colors.Text
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    -- ═══ Content Area ═══
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -60)
    content.Position = UDim2.new(0, 10, 0, 55)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    
    -- Layout
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = content
    
    -- ═══ Info Panel ═══
    local infoPanel = Instance.new("Frame")
    infoPanel.Name = "InfoPanel"
    infoPanel.Size = UDim2.new(1, 0, 0, 70)
    infoPanel.BackgroundColor3 = UI.Colors.BackgroundDark
    infoPanel.BorderSizePixel = 0
    infoPanel.LayoutOrder = 1
    infoPanel.Parent = content
    
    local infoPanelCorner = Instance.new("UICorner")
    infoPanelCorner.CornerRadius = UDim.new(0, 8)
    infoPanelCorner.Parent = infoPanel
    
    local gameName = Util.getGameName()
    
    local gameLabel = Instance.new("TextLabel")
    gameLabel.Name = "GameName"
    gameLabel.Size = UDim2.new(1, -20, 0, 22)
    gameLabel.Position = UDim2.new(0, 10, 0, 8)
    gameLabel.BackgroundTransparency = 1
    gameLabel.Text = "🎮 " .. gameName
    gameLabel.TextColor3 = UI.Colors.Text
    gameLabel.TextSize = 13
    gameLabel.Font = Enum.Font.GothamSemibold
    gameLabel.TextXAlignment = Enum.TextXAlignment.Left
    gameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    gameLabel.Parent = infoPanel
    
    local placeLabel = Instance.new("TextLabel")
    placeLabel.Name = "PlaceId"
    placeLabel.Size = UDim2.new(1, -20, 0, 18)
    placeLabel.Position = UDim2.new(0, 10, 0, 28)
    placeLabel.BackgroundTransparency = 1
    placeLabel.Text = string.format("📍 PlaceId: %d", game.PlaceId)
    placeLabel.TextColor3 = UI.Colors.TextDim
    placeLabel.TextSize = 11
    placeLabel.Font = Enum.Font.Gotham
    placeLabel.TextXAlignment = Enum.TextXAlignment.Left
    placeLabel.Parent = infoPanel
    
    local instanceLabel = Instance.new("TextLabel")
    instanceLabel.Name = "InstanceCount"
    instanceLabel.Size = UDim2.new(1, -20, 0, 18)
    instanceLabel.Position = UDim2.new(0, 10, 0, 46)
    instanceLabel.BackgroundTransparency = 1
    instanceLabel.TextColor3 = UI.Colors.TextDim
    instanceLabel.TextSize = 11
    instanceLabel.Font = Enum.Font.Gotham
    instanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    instanceLabel.Parent = infoPanel
    
    -- Count instances async
    task.spawn(function()
        local count = 0
        pcall(function() count = #game:GetDescendants() end)
        instanceLabel.Text = string.format("📦 Instances: ~%s",
            tostring(count):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
    end)
    
    -- ═══ Status Panel ═══
    local statusPanel = Instance.new("Frame")
    statusPanel.Name = "StatusPanel"
    statusPanel.Size = UDim2.new(1, 0, 0, 50)
    statusPanel.BackgroundColor3 = UI.Colors.BackgroundDark
    statusPanel.BorderSizePixel = 0
    statusPanel.LayoutOrder = 2
    statusPanel.Parent = content
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusPanel
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusText"
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 0, 5)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "⏳ Status: Ready"
    statusLabel.TextColor3 = UI.Colors.Success
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
    statusLabel.Parent = statusPanel
    
    -- Progress bar
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBg"
    progressBg.Size = UDim2.new(1, -20, 0, 8)
    progressBg.Position = UDim2.new(0, 10, 0, 32)
    progressBg.BackgroundColor3 = UI.Colors.Border
    progressBg.BorderSizePixel = 0
    progressBg.Parent = statusPanel
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 4)
    progressCorner.Parent = progressBg
    
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = UI.Colors.Accent
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 4)
    progressFillCorner.Parent = progressFill
    
    -- ═══ Helper: Tạo nút ═══
    local function createButton(name, text, icon, layoutOrder, color)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 42)
        btn.BackgroundColor3 = color or UI.Colors.ButtonBg
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.LayoutOrder = layoutOrder
        btn.AutoButtonColor = false
        btn.Parent = content
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        -- Stroke
        local stroke = Instance.new("UIStroke")
        stroke.Color = UI.Colors.Border
        stroke.Thickness = 1
        stroke.Transparency = 0.5
        stroke.Parent = btn
        
        -- Icon + Text
        local btnLabel = Instance.new("TextLabel")
        btnLabel.Name = "Label"
        btnLabel.Size = UDim2.new(1, -20, 1, 0)
        btnLabel.Position = UDim2.new(0, 10, 0, 0)
        btnLabel.BackgroundTransparency = 1
        btnLabel.Text = icon .. "  " .. text
        btnLabel.TextColor3 = UI.Colors.Text
        btnLabel.TextSize = 14
        btnLabel.Font = Enum.Font.GothamSemibold
        btnLabel.TextXAlignment = Enum.TextXAlignment.Left
        btnLabel.Parent = btn
        
        -- Hover effects
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = UI.Colors.ButtonHover
            }):Play()
            TweenService:Create(stroke, TweenInfo.new(0.15), {
                Color = UI.Colors.Accent,
                Transparency = 0
            }):Play()
        end)
        
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = color or UI.Colors.ButtonBg
            }):Play()
            TweenService:Create(stroke, TweenInfo.new(0.15), {
                Color = UI.Colors.Border,
                Transparency = 0.5
            }):Play()
        end)
        
        return btn
    end
    
    -- ═══ Buttons ═══
    local btnFullGame = createButton("BtnFullGame", 
        "Decompile Full Game", "🌍", 3)
    
    local btnFullModel = createButton("BtnFullModel", 
        "Decompile Full Model", "🧊", 4)
    
    local btnTerrain = createButton("BtnTerrain", 
        "Decompile Terrain", "🏔️", 5)
    
    local btnSaveRBXL = createButton("BtnSaveRBXL", 
        "Save To .rbxl", "💾", 6, UI.Colors.AccentDark)
    
    local btnExit = createButton("BtnExit", 
        "Exit", "❌", 7, Color3.fromRGB(60, 20, 20))
    
    -- ═══ Credits ═══
    local credits = Instance.new("TextLabel")
    credits.Name = "Credits"
    credits.Size = UDim2.new(1, 0, 0, 20)
    credits.BackgroundTransparency = 1
    credits.Text = "BaoSaveInstance v" .. BaoSaveInstance.Version .. " | Enhanced Decompiler"
    credits.TextColor3 = UI.Colors.TextDim
    credits.TextSize = 10
    credits.Font = Enum.Font.Gotham
    credits.TextTransparency = 0.5
    credits.LayoutOrder = 8
    credits.Parent = content
    
    -- ═══ DRAGGABLE SYSTEM ═══
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- ═══ MINIMIZE SYSTEM ═══
    local minimized = false
    local originalSize = mainFrame.Size
    
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                Size = UDim2.new(0, 380, 0, 50)
            }):Play()
            content.Visible = false
            minimizeBtn.Text = "□"
        else
            content.Visible = true
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                Size = originalSize
            }):Play()
            minimizeBtn.Text = "─"
        end
    end)
    
    -- ═══ STATUS UPDATE FUNCTION ═══
    local function updateStatus(text, color, progress)
        statusLabel.Text = "⏳ " .. text
        statusLabel.TextColor3 = color or UI.Colors.Text
        
        if progress then
            local targetSize = UDim2.new(math.clamp(progress / 100, 0, 1), 0, 1, 0)
            TweenService:Create(progressFill, TweenInfo.new(0.2), {
                Size = targetSize
            }):Play()
        end
    end
    
    local function setButtonsEnabled(enabled)
        for _, btn in ipairs({btnFullGame, btnFullModel, btnTerrain, btnSaveRBXL}) do
            btn.Active = enabled
            btn.AutoButtonColor = enabled
            if not enabled then
                btn.BackgroundTransparency = 0.5
            else
                btn.BackgroundTransparency = 0
            end
        end
    end
    
    -- ═══ BUTTON HANDLERS ═══
    
    -- Decompile Full Game
    btnFullGame.MouseButton1Click:Connect(function()
        if BaoSaveInstance.State.isRunning then return end
        
        setButtonsEnabled(false)
        updateStatus("Saving Full Game...", UI.Colors.Warning, 10)
        
        task.spawn(function()
            local success, result = BaoSaveInstance.exportRBXL("FULL_GAME", function(status)
                task.spawn(function()
                    updateStatus(status, UI.Colors.Warning, 50)
                end)
            end)
            
            if success then
                updateStatus("Done ✓ - " .. tostring(result), UI.Colors.Success, 100)
            else
                updateStatus("Error: " .. tostring(result), UI.Colors.Error, 0)
            end
            
            setButtonsEnabled(true)
        end)
    end)
    
    -- Decompile Full Model
    btnFullModel.MouseButton1Click:Connect(function()
        if BaoSaveInstance.State.isRunning then return end
        
        setButtonsEnabled(false)
        updateStatus("Saving Models...", UI.Colors.Warning, 10)
        
        task.spawn(function()
            local success, result = BaoSaveInstance.exportRBXL("MODEL_ONLY", function(status)
                task.spawn(function()
                    updateStatus(status, UI.Colors.Warning, 50)
                end)
            end)
            
            if success then
                updateStatus("Done ✓ - " .. tostring(result), UI.Colors.Success, 100)
            else
                updateStatus("Error: " .. tostring(result), UI.Colors.Error, 0)
            end
            
            setButtonsEnabled(true)
        end)
    end)
    
    -- Decompile Terrain
    btnTerrain.MouseButton1Click:Connect(function()
        if BaoSaveInstance.State.isRunning then return end
        
        setButtonsEnabled(false)
        updateStatus("Saving Terrain...", UI.Colors.Warning, 10)
        
        task.spawn(function()
            local success, result = BaoSaveInstance.exportRBXL("TERRAIN_ONLY", function(status)
                task.spawn(function()
                    updateStatus(status, UI.Colors.Warning, 50)
                end)
            end)
            
            if success then
                updateStatus("Done ✓ - " .. tostring(result), UI.Colors.Success, 100)
            else
                updateStatus("Error: " .. tostring(result), UI.Colors.Error, 0)
            end
            
            setButtonsEnabled(true)
        end)
    end)
    
    -- Save To .rbxl (Quick save - full game)
    btnSaveRBXL.MouseButton1Click:Connect(function()
        if BaoSaveInstance.State.isRunning then return end
        
        setButtonsEnabled(false)
        updateStatus("Quick Save .rbxl...", UI.Colors.Accent, 20)
        
        task.spawn(function()
            local success, result = CustomSaveInstance.execute("FULL_GAME", function(status)
                task.spawn(function()
                    updateStatus(status, UI.Colors.Warning, 60)
                end)
            end)
            
            if success then
                updateStatus("Saved ✓ - " .. tostring(result), UI.Colors.Success, 100)
            else
                updateStatus("Error: " .. tostring(result), UI.Colors.Error, 0)
            end
            
            setButtonsEnabled(true)
        end)
    end)
    
    -- Exit
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        
        task.wait(0.35)
        screenGui:Destroy()
    end)
    
    btnExit.MouseButton1Click:Connect(function()
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        
        task.wait(0.35)
        screenGui:Destroy()
    end)
    
    -- ═══ OPEN ANIMATION ═══
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Size = originalSize,
        Position = UDim2.new(0.5, -190, 0.5, -260)
    }):Play()
    
    -- ═══ KEYBIND: Toggle visibility with RightShift ═══
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)
    
    UI.ScreenGui = screenGui
    UI.StatusLabel = statusLabel
    UI.ProgressFill = progressFill
    
    Util.log(2, "UI đã được tạo thành công! Nhấn RightShift để ẩn/hiện")
    
    return screenGui
end

BaoSaveInstance.UI = UI

-- ============================================================
-- PHẦN 12: ADVANCED SAVEINSTANCE OPTIONS BUILDER
-- ============================================================

--[[
    Module này xây dựng options tối ưu cho từng executor cụ thể
    Hỗ trợ: Synapse X, Script-Ware, Fluxus, Wave, Solara, etc.
]]

local OptionsBuilder = {}

function OptionsBuilder.detect_executor()
    -- Phát hiện executor đang sử dụng
    if syn then return "synapse" end
    if is_sirhurt_closure then return "sirhurt" end
    if KRNL_LOADED then return "krnl" end
    if fluxus then return "fluxus" end
    if getexecutorname then
        local name = getexecutorname():lower()
        return name
    end
    if identifyexecutor then
        local name = identifyexecutor():lower()
        return name
    end
    return "unknown"
end

function OptionsBuilder.build(mode, executorName)
    executorName = executorName or OptionsBuilder.detect_executor()
    local gameName = Util.getGameName()
    
    local suffix = {
        FULL_GAME = "_Full",
        MODEL_ONLY = "_Model",
        TERRAIN_ONLY = "_Terrain"
    }
    
    local fileName = gameName .. (suffix[mode] or "") .. ".rbxl"
    
    -- Base options
    local opts = {
        FileName = fileName,
        SavePlayers = false,
        RemovePlayerCharacters = true,
    }
    
    -- Executor-specific options
    if executorName == "synapse" then
        -- Synapse X format
        opts.DecompileMode = (mode ~= "TERRAIN_ONLY") and "decompile" or "none"
        opts.NilInstances = (mode == "FULL_GAME")
        opts.DecompileTimeout = BaoSaveInstance.Config.DecompileTimeout
        opts.FilePath = BaoSaveInstance.Config.OutputFolder
        
    else
        -- Unified format (most modern executors)
        opts.DecompileMode = (mode ~= "TERRAIN_ONLY") and 2 or 0
        opts.NilInstances = (mode == "FULL_GAME")
        opts.NilInstancesFix = true
        opts.DecompileTimeout = BaoSaveInstance.Config.DecompileTimeout
        opts.IsolateStarterPlayer = true
        opts.SaveNonCreatable = true
        opts.SharedStrings = true
        opts.Binary = true
        opts.ShowStatus = true
        opts.ScriptCache = true
        opts.SaveBytecode = false
        opts.IgnoreDefaultProperties = false
        opts.AntiIdle = true
    end
    
    -- Mode-specific additions
    if mode == "MODEL_ONLY" then
        local instances = {}
        pcall(function()
            for _, c in ipairs(Workspace:GetChildren()) do
                if c.Name ~= "Terrain" and c.ClassName ~= "Camera" then
                    instances[#instances + 1] = c
                end
            end
        end)
        pcall(function()
            for _, c in ipairs(ReplicatedStorage:GetChildren()) do
                instances[#instances + 1] = c
            end
        end)
        pcall(function()
            for _, c in ipairs(StarterGui:GetChildren()) do
                instances[#instances + 1] = c
            end
        end)
        pcall(function()
            for _, c in ipairs(StarterPack:GetChildren()) do
                instances[#instances + 1] = c
            end
        end)
        pcall(function()
            for _, c in ipairs(StarterPlayer:GetChildren()) do
                instances[#instances + 1] = c
            end
        end)
        opts.ExtraInstances = instances
        opts.NilInstances = false
        
    elseif mode == "TERRAIN_ONLY" then
        opts.ExtraInstances = {Workspace.Terrain}
        opts.NilInstances = false
        opts.DecompileMode = executorName == "synapse" and "none" or 0
    end
    
    return opts
end

BaoSaveInstance.OptionsBuilder = OptionsBuilder

-- ============================================================
-- PHẦN 13: ANTI-CRASH & PERFORMANCE MONITOR
-- ============================================================

local PerformanceMonitor = {}

function PerformanceMonitor.start()
    local monitor = {
        startTime = os.clock(),
        startMemory = collectgarbage("count"),
        peakMemory = 0,
        operations = 0
    }
    
    return monitor
end

function PerformanceMonitor.update(monitor)
    monitor.operations = monitor.operations + 1
    local currentMem = collectgarbage("count")
    
    if currentMem > monitor.peakMemory then
        monitor.peakMemory = currentMem
    end
    
    -- Auto GC nếu memory quá cao
    if currentMem > BaoSaveInstance.Config.MaxMemoryMB * 1024 * 0.8 then
        collectgarbage("collect")
        task.wait(0.01)
    end
    
    -- Yield định kỳ
    if monitor.operations % BaoSaveInstance.Config.GCInterval == 0 then
        collectgarbage("step", 200)
        task.wait()
    end
end

function PerformanceMonitor.report(monitor)
    local elapsed = os.clock() - monitor.startTime
    local memUsed = collectgarbage("count") - monitor.startMemory
    
    return {
        elapsed = elapsed,
        memoryUsedKB = memUsed,
        peakMemoryKB = monitor.peakMemory,
        operations = monitor.operations,
        opsPerSecond = monitor.operations / math.max(elapsed, 0.001)
    }
end

BaoSaveInstance.PerformanceMonitor = PerformanceMonitor

-- ============================================================
-- PHẦN 14: FAST DECOMPILE PIPELINE
-- ============================================================

--[[
    Pipeline decompile nhanh:
    1. Thu thập tất cả scripts
    2. Phân loại theo kích thước (nhỏ → lớn)
    3. Decompile theo batch với yielding thông minh
    4. Cache kết quả
    5. Fallback cho scripts fail
]]

local FastDecompilePipeline = {}

function FastDecompilePipeline.run(progressCallback)
    local decompileFunc = safeGetFunc("decompile")
    if not decompileFunc then
        Util.log(3, "Decompile function không khả dụng, sẽ dùng saveinstance built-in")
        return nil
    end
    
    local startTime = os.clock()
    local scripts = {}
    local cache = {}
    local stats = {total = 0, success = 0, failed = 0, cached = 0}
    
    -- Bước 1: Thu thập scripts
    if progressCallback then progressCallback("Collecting scripts...") end
    
    local getScripts = safeGetFunc("getscripts")
    local getModules = safeGetFunc("getloadedmodules")
    local seen = {}
    
    if getScripts then
        pcall(function()
            for _, s in ipairs(getScripts()) do
                local id = tostring(s:GetDebugId())
                if not seen[id] then
                    seen[id] = true
                    scripts[#scripts + 1] = s
                end
            end
        end)
    end
    
    if getModules then
        pcall(function()
            for _, m in ipairs(getModules()) do
                local id = tostring(m:GetDebugId())
                if not seen[id] then
                    seen[id] = true
                    scripts[#scripts + 1] = m
                end
            end
        end)
    end
    
    -- Bước 2: Quét thủ công
    local servicesToScan = {
        Workspace, ReplicatedStorage, ReplicatedFirst,
        StarterGui, StarterPack, StarterPlayer,
        Lighting, SoundService
    }
    
    for _, service in ipairs(servicesToScan) do
        pcall(function()
            for _, desc in ipairs(service:GetDescendants()) do
                if desc:IsA("LuaSourceContainer") then
                    local id = tostring(desc:GetDebugId())
                    if not seen[id] then
                        seen[id] = true
                        scripts[#scripts + 1] = desc
                    end
                end
            end
        end)
        task.wait()
    end
    
    stats.total = #scripts
    Util.log(2, "Thu thập được %d scripts", stats.total)
    
    if stats.total == 0 then
        return cache
    end
    
    -- Bước 3: Sắp xếp theo priority
    table.sort(scripts, function(a, b)
        -- ModuleScript trước, Script sau
        local order = {ModuleScript = 1, LocalScript = 2, Script = 3}
        local oa = order[a.ClassName] or 4
        local ob = order[b.ClassName] or 4
        return oa < ob
    end)
    
    -- Bước 4: Decompile
    local batchSize = BaoSaveInstance.Config.DecompileBatchSize
    local timeout = BaoSaveInstance.Config.DecompileTimeout
    
    for i = 1, #scripts do
        local script = scripts[i]
        local id = tostring(script:GetDebugId())
        
        -- Decompile với timeout
        local source = nil
        local ok = false
        
        for attempt = 1, 2 do
            local s, r = pcall(function()
                return decompileFunc(script)
            end)
            
            if s and r and #r > 0 then
                source = r
                ok = true
                break
            end
            
            if attempt < 2 then
                task.wait(0.02)
            end
        end
        
        if ok then
            cache[id] = source
            stats.success = stats.success + 1
        else
            cache[id] = string.format(
                "-- Decompile failed: %s (%s)\n-- Path: %s",
                script.Name, script.ClassName,
                pcall(function() return script:GetFullName() end) 
                    and script:GetFullName() or "unknown"
            )
            stats.failed = stats.failed + 1
        end
        
        -- Progress callback
        if progressCallback and i % 5 == 0 then
            local pct = math.floor(i / stats.total * 100)
            progressCallback(string.format(
                "Decompile: %d/%d (%d%%) - %s",
                i, stats.total, pct, script.Name
            ))
        end
        
        -- Yield
        if i % batchSize == 0 then
            task.wait(0.001)
        end
        
        -- Memory check
        if i % 200 == 0 then
            local mem = collectgarbage("count") / 1024
            if mem > BaoSaveInstance.Config.MaxMemoryMB * 0.7 then
                collectgarbage("collect")
                task.wait(0.05)
            end
        end
    end
    
    local elapsed = os.clock() - startTime
    Util.log(2, "Fast Decompile hoàn thành: %d/%d thành công trong %.1fs (%.0f scripts/s)",
        stats.success, stats.total, elapsed, stats.total / math.max(elapsed, 0.001))
    
    return cache, stats
end

BaoSaveInstance.FastDecompilePipeline = FastDecompilePipeline

-- ============================================================
-- PHẦN 15: UNIFIED EXPORT (KẾT HỢP TẤT CẢ)
-- ============================================================

--[[
    Hàm export chính - kết hợp:
    1. Fast decompile pipeline
    2. Options builder
    3. Custom saveinstance
    4. Performance monitor
    5. Error handling
]]

function BaoSaveInstance.unifiedExport(mode, progressCallback)
    if BaoSaveInstance.State.isRunning then
        return false, "Đang có tiến trình đang chạy!"
    end
    
    BaoSaveInstance.State.isRunning = true
    BaoSaveInstance.State.currentMode = mode
    BaoSaveInstance.State.startTime = os.clock()
    
    local perfMonitor = PerformanceMonitor.start()
    
    local callback = function(status)
        BaoSaveInstance.State.status = status
        if progressCallback then
            progressCallback(status)
        end
    end
    
    callback("Khởi tạo export " .. mode .. "...")
    
    -- Bước 1: Pre-decompile (tùy chọn, giúp nhanh hơn)
    if mode ~= "TERRAIN_ONLY" and BaoSaveInstance.Config.DecompileScripts then
        -- Chú ý: Hầu hết executor đã có built-in decompile trong saveinstance
        -- Pipeline này chạy trước để warm up cache
        if BaoSaveInstance.Config.ParallelDecompile then
            callback("Pre-decompile scripts (fast pipeline)...")
            -- FastDecompilePipeline sẽ cache kết quả
            -- saveinstance sẽ sử dụng cache này nếu executor hỗ trợ
            task.spawn(function()
                FastDecompilePipeline.run(function(status)
                    -- Update UI nhưng không block
                end)
            end)
            task.wait(0.5) -- Cho pipeline bắt đầu
        end
    end
    
    -- Bước 2: Detect executor và build options
    local executorName = OptionsBuilder.detect_executor()
    callback(string.format("Executor: %s | Building options...", executorName))
    
    local options = OptionsBuilder.build(mode, executorName)
    
    -- Bước 3: Execute saveinstance
    callback("Saving... " .. options.FileName)
    
    local saveFunc = safeGetFunc("saveinstance")
    
    if not saveFunc then
        -- Thử Synapse X API
        if syn and syn.saveinstance then
            saveFunc = function(opts)
                syn.saveinstance(game, opts.FileName, opts)
            end
        end
    end
    
    if not saveFunc then
        BaoSaveInstance.State.isRunning = false
        callback("❌ Executor không hỗ trợ saveinstance!")
        return false, "No saveinstance function available"
    end
    
    -- Execute với error handling
    local success, err
    
    -- Thử với full options
    success, err = pcall(function()
        saveFunc(options)
    end)
    
    if not success then
        Util.log(3, "Full options failed (%s), trying simplified...", tostring(err))
        callback("Retry với simplified options...")
        
        -- Thử simplified
        local simpleOpts = {
            FileName = options.FileName,
            DecompileMode = options.DecompileMode,
            NilInstances = options.NilInstances,
            SavePlayers = false,
        }
        
        if options.ExtraInstances then
            simpleOpts.ExtraInstances = options.ExtraInstances
        end
        
        success, err = pcall(function()
            saveFunc(simpleOpts)
        end)
    end
    
    if not success then
        Util.log(3, "Simplified failed (%s), trying minimal...", tostring(err))
        callback("Retry với minimal options...")
        
        -- Thử minimal
        success, err = pcall(function()
            saveFunc({FileName = options.FileName})
        end)
    end
    
    -- Bước 4: Report
    local report = PerformanceMonitor.report(perfMonitor)
    
    BaoSaveInstance.State.isRunning = false
    
    if success then
        local finalStatus = string.format(
            "Done ✓ - %s (%.1fs, Peak: %.0fMB)",
            options.FileName, report.elapsed, report.peakMemoryKB / 1024)
        callback(finalStatus)
        Util.log(2, finalStatus)
        return true, options.FileName
    else
        local errorStatus = "❌ Export failed: " .. tostring(err)
        callback(errorStatus)
        Util.log(4, errorStatus)
        return false, tostring(err)
    end
end

-- ============================================================
-- PHẦN 16: ENTRY POINT - KHỞI CHẠY
-- ============================================================

-- Khởi tạo
BaoSaveInstance.init()

-- Tạo UI
BaoSaveInstance.UI.create()

-- Export global cho các script khác sử dụng
if getgenv then
    getgenv().BaoSaveInstance = BaoSaveInstance
else
    _G.BaoSaveInstance = BaoSaveInstance
end

-- ============================================================
-- PHẦN 17: CONSOLE API (CHO ADVANCED USERS)
-- ============================================================

--[[
    Sử dụng từ console:
    
    -- Full game save
    BaoSaveInstance.exportRBXL("FULL_GAME")
    
    -- Model only
    BaoSaveInstance.exportRBXL("MODEL_ONLY")
    
    -- Terrain only
    BaoSaveInstance.exportRBXL("TERRAIN_ONLY")
    
    -- Unified export (recommended)
    BaoSaveInstance.unifiedExport("FULL_GAME")
    
    -- Decompile scripts only
    BaoSaveInstance.decompileScripts()
    
    -- Fast decompile
    BaoSaveInstance.FastDecompilePipeline.run(print)
    
    -- Check state
    print(BaoSaveInstance.State.status)
    
    -- Custom config
    BaoSaveInstance.Config.DecompileTimeout = 30
    BaoSaveInstance.Config.MaxParallelThreads = 16
    BaoSaveInstance.exportRBXL("FULL_GAME")
]]

Util.log(2, "═══════════════════════════════════════")
Util.log(2, "BaoSaveInstance v%s đã sẵn sàng!", BaoSaveInstance.Version)
Util.log(2, "Nhấn RightShift để ẩn/hiện UI")
Util.log(2, "═══════════════════════════════════════")

return BaoSaveInstance
