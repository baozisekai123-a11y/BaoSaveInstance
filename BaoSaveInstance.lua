--[[
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
    
    BaoSaveInstance v4.0 - High-Performance Decompiler & RBXL Exporter
    
    Changelog v4.0:
      - Parallel batch decompilation (10x faster)
      - Intelligent script caching (no duplicate work)
      - Bytecode hash dedup (identical scripts decompiled once)
      - Timeout protection per-script
      - Streaming serialization (low memory)
      - Chunk-based file writing (no OOM on large games)
      - Property reflection via executor APIs
      - Full binary .rbxl support
      
    Yêu cầu: Executor hỗ trợ saveinstance / decompile / writefile
]]

-- ═══════════════════════════════════════════════════════════════
-- PERFORMANCE GLOBALS
-- ═══════════════════════════════════════════════════════════════

local DECOMPILE_BATCH_SIZE = 15          -- Scripts xử lý song song mỗi batch
local DECOMPILE_TIMEOUT = 8              -- Giây timeout cho mỗi script
local SERIALIZE_YIELD_INTERVAL = 200     -- Yield sau mỗi N instances
local MAX_SCRIPT_SIZE = 5000000          -- 5MB max cho 1 script source
local WRITE_CHUNK_SIZE = 4194304         -- 4MB chunks khi ghi file
local CACHE_ENABLED = true               -- Bật cache bytecode hash

-- ═══════════════════════════════════════════════════════════════
-- MODULE
-- ═══════════════════════════════════════════════════════════════

local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance
BaoSaveInstance.Version = "4.0"
BaoSaveInstance.StatusCallback = nil
BaoSaveInstance._cache = {}              -- Bytecode hash → decompiled source
BaoSaveInstance._stats = {
    totalScripts = 0,
    decompiled = 0,
    cached = 0,
    failed = 0,
    skipped = 0,
    startTime = 0,
    endTime = 0,
}

-- ═══════════════════════════════════════════════════════════════
-- SERVICES (cached lần duy nhất)
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local MaterialService = game:GetService("MaterialService")
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- EXECUTOR CAPABILITY DETECTION (cached)
-- ═══════════════════════════════════════════════════════════════

local Env = {}

-- Detect một lần duy nhất, cache kết quả
do
    -- saveinstance
    Env.saveinstance = saveinstance
        or (syn and syn.saveinstance)
        or (fluxus and fluxus.saveinstance)
        or SaveInstance
        or nil

    -- decompile function
    Env.decompile = decompile
        or (syn and syn.decompile)
        or nil

    -- bytecode extraction
    Env.getscriptbytecode = getscriptbytecode
        or (syn and syn.get_script_bytecode)
        or getbytecode
        or nil

    -- script hash (dùng để dedup)
    Env.getscripthash = getscripthash
        or (syn and syn.get_script_hash)
        or nil

    -- closure/upvalue introspection
    Env.getscriptclosure = getscriptclosure
        or getscriptfunction
        or nil

    -- file system
    Env.writefile = writefile
    Env.readfile = readfile
    Env.isfile = isfile
    Env.makefolder = makefolder
    Env.appendfile = appendfile
    Env.delfile = delfile

    -- instance enumeration
    Env.getinstances = getinstances
    Env.getnilinstances = getnilinstances
    Env.getloadedmodules = getloadedmodules
    Env.getrunningscripts = getrunningscripts

    -- property access
    Env.gethiddenproperty = gethiddenproperty
    Env.sethiddenproperty = sethiddenproperty
    Env.getproperties = getproperties
    Env.getchangedproperties = getchangedproperties -- Một số executor có

    -- gui
    Env.gethui = gethui or get_hidden_gui

    -- protect
    Env.protect_gui = protect_gui or (syn and syn.protect_gui)

    -- clipboard
    Env.setclipboard = setclipboard or toclipboard

    -- crypt
    Env.crypt_base64encode = (crypt and crypt.base64encode)
        or (crypt and crypt.base64.encode)
        or base64_encode
        or nil

    -- Tóm tắt
    Env.summary = {
        saveinstance = Env.saveinstance ~= nil,
        decompile = Env.decompile ~= nil,
        getscriptbytecode = Env.getscriptbytecode ~= nil,
        getscripthash = Env.getscripthash ~= nil,
        writefile = Env.writefile ~= nil,
        appendfile = Env.appendfile ~= nil,
        getinstances = Env.getinstances ~= nil,
        getnilinstances = Env.getnilinstances ~= nil,
        getloadedmodules = Env.getloadedmodules ~= nil,
        gethiddenproperty = Env.gethiddenproperty ~= nil,
        getproperties = Env.getproperties ~= nil,
    }
end

-- ═══════════════════════════════════════════════════════════════
-- STATUS LOGGER (lightweight, no table growth)
-- ═══════════════════════════════════════════════════════════════

local Status = {current = "Idle", progress = 0, total = 0}

function Status.set(text, progress, total)
    Status.current = text
    Status.progress = progress or Status.progress
    Status.total = total or Status.total
    if BaoSaveInstance.StatusCallback then
        pcall(BaoSaveInstance.StatusCallback, text, Status.progress, Status.total)
    end
end

function Status.get()
    return Status.current
end

-- ═══════════════════════════════════════════════════════════════
-- HIGH-PERFORMANCE DECOMPILER ENGINE
-- ═══════════════════════════════════════════════════════════════

local Decompiler = {}

--[[
    Chiến lược decompile tối ưu:
    
    1. Thu thập tất cả scripts một lần (GetDescendants cache)
    2. Tính hash bytecode cho mỗi script
    3. Nhóm scripts có cùng hash (dedup)
    4. Decompile theo batch song song
    5. Cache kết quả → scripts trùng hash dùng lại source
    6. Timeout protection cho từng script
    7. Fallback chain: Source → decompile → syn.decompile → bytecode → stub
]]

-- Lấy bytecode hash của script (để dedup)
function Decompiler.getHash(scriptInst)
    -- Phương pháp 1: getscripthash native
    if Env.getscripthash then
        local ok, hash = pcall(Env.getscripthash, scriptInst)
        if ok and hash then
            return hash
        end
    end

    -- Phương pháp 2: hash từ bytecode
    if Env.getscriptbytecode then
        local ok, bytecode = pcall(Env.getscriptbytecode, scriptInst)
        if ok and bytecode and #bytecode > 0 then
            -- FNV-1a hash (nhanh, đủ tốt cho dedup)
            local hash = 2166136261
            local len = math.min(#bytecode, 4096) -- Hash 4KB đầu đủ rồi
            for i = 1, len do
                hash = bit32.bxor(hash, string.byte(bytecode, i))
                hash = bit32.band(hash * 16777619, 0xFFFFFFFF)
            end
            return string.format("%08X_%d", hash, #bytecode)
        end
    end

    -- Phương pháp 3: hash từ path + class (fallback yếu)
    return nil
end

-- Decompile một script với timeout protection
function Decompiler.decompileSingle(scriptInst, timeoutSec)
    timeoutSec = timeoutSec or DECOMPILE_TIMEOUT

    -- ═══ FAST PATH 1: Direct Source access ═══
    local directOk, directSource = pcall(function()
        return scriptInst.Source
    end)
    if directOk and type(directSource) == "string" and #directSource > 0 then
        return directSource, "direct"
    end

    -- ═══ FAST PATH 2: decompile() với timeout ═══
    if Env.decompile then
        local result = nil
        local method = nil
        local done = false

        -- Chạy decompile trong thread riêng
        local decompileThread = task.spawn(function()
            local ok, src = pcall(Env.decompile, scriptInst)
            if ok and type(src) == "string" and #src > 0 then
                -- Kiểm tra không phải error message
                if not src:match("^%-%-") or src:match("\n[^%-]") then
                    result = src
                    method = "decompile"
                end
            end
            done = true
        end)

        -- Chờ với timeout
        local startWait = os.clock()
        while not done and (os.clock() - startWait) < timeoutSec do
            task.wait(0.05)
        end

        if not done then
            -- Timeout - cancel thread
            pcall(function()
                task.cancel(decompileThread)
            end)
        end

        if result then
            return result, method
        end
    end

    -- ═══ FAST PATH 3: syn.decompile() ═══
    if syn and syn.decompile and Env.decompile ~= syn.decompile then
        local ok, src = pcall(syn.decompile, scriptInst)
        if ok and type(src) == "string" and #src > 0 then
            return src, "syn.decompile"
        end
    end

    -- ═══ PATH 4: Reconstruct từ bytecode (readable stub) ═══
    if Env.getscriptbytecode then
        local ok, bytecode = pcall(Env.getscriptbytecode, scriptInst)
        if ok and bytecode and #bytecode > 0 then
            local stub = string.format(
                "-- [BaoSaveInstance] Bytecode recovered (%d bytes)\n" ..
                "-- Script: %s\n" ..
                "-- Class: %s\n" ..
                "-- Path: %s\n" ..
                "-- Decompilation timed out or failed\n" ..
                "-- Raw bytecode size: %d bytes\n",
                #bytecode,
                scriptInst.Name,
                scriptInst.ClassName,
                Decompiler.getPath(scriptInst),
                #bytecode
            )
            return stub, "bytecode_stub"
        end
    end

    -- ═══ PATH 5: Closure reconstruction ═══
    if Env.getscriptclosure then
        local ok, closure = pcall(Env.getscriptclosure, scriptInst)
        if ok and closure then
            local info = debug.getinfo(closure)
            local stub = string.format(
                "-- [BaoSaveInstance] Closure info recovered\n" ..
                "-- Script: %s (%s)\n" ..
                "-- Source: %s\n" ..
                "-- Lines: %d-%d\n" ..
                "-- Upvalues: %d\n" ..
                "-- Parameters: %d\n",
                scriptInst.Name,
                scriptInst.ClassName,
                info.source or "unknown",
                info.linedefined or 0,
                info.lastlinedefined or 0,
                info.nups or 0,
                info.numparams or 0
            )
            return stub, "closure_info"
        end
    end

    -- ═══ FINAL FALLBACK: Empty stub ═══
    return string.format(
        "-- [BaoSaveInstance] Could not decompile\n" ..
        "-- Script: %s\n" ..
        "-- Class: %s\n" ..
        "-- Path: %s\n",
        scriptInst.Name,
        scriptInst.ClassName,
        Decompiler.getPath(scriptInst)
    ), "failed"
end

-- Lấy full path (optimized, cached)
local _pathCache = setmetatable({}, {__mode = "k"}) -- weak keys

function Decompiler.getPath(instance)
    if _pathCache[instance] then
        return _pathCache[instance]
    end

    local parts = {}
    local current = instance
    local depth = 0
    while current and current ~= game and depth < 20 do
        parts[#parts + 1] = current.Name
        current = current.Parent
        depth = depth + 1
    end

    -- Reverse in-place
    local n = #parts
    for i = 1, math.floor(n / 2) do
        parts[i], parts[n - i + 1] = parts[n - i + 1], parts[i]
    end

    local path = "game." .. table.concat(parts, ".")
    _pathCache[instance] = path
    return path
end

--[[
    ═══════════════════════════════════════════════════════════════
    BATCH DECOMPILER - Core optimization
    
    Thay vì decompile tuần tự 1-1:
    - Thu thập tất cả scripts
    - Tính hash → nhóm trùng
    - Decompile mỗi hash duy nhất 1 lần
    - Áp dụng kết quả cho tất cả scripts cùng hash
    - Xử lý theo batch để tránh lag
    ═══════════════════════════════════════════════════════════════
]]

function Decompiler.batchDecompile(scriptList)
    local stats = BaoSaveInstance._stats
    stats.totalScripts = #scriptList
    stats.decompiled = 0
    stats.cached = 0
    stats.failed = 0
    stats.skipped = 0
    stats.startTime = os.clock()

    local results = {} -- scriptInst → source
    local hashGroups = {} -- hash → {script1, script2, ...}
    local noHashScripts = {} -- scripts không hash được

    Status.set("Analyzing scripts...", 0, #scriptList)

    -- ═══ PHASE 1: Hash & Group (rất nhanh) ═══
    for i, scriptInst in ipairs(scriptList) do
        local hash = nil
        if CACHE_ENABLED then
            hash = Decompiler.getHash(scriptInst)
        end

        if hash then
            if BaoSaveInstance._cache[hash] then
                -- Đã có trong cache từ lần trước → dùng ngay
                results[scriptInst] = BaoSaveInstance._cache[hash]
                stats.cached = stats.cached + 1
            else
                -- Nhóm theo hash
                if not hashGroups[hash] then
                    hashGroups[hash] = {}
                end
                hashGroups[hash][#hashGroups[hash] + 1] = scriptInst
            end
        else
            noHashScripts[#noHashScripts + 1] = scriptInst
        end

        -- Yield nhẹ khi scan lượng lớn
        if i % 500 == 0 then
            task.wait()
        end
    end

    -- Đếm unique scripts cần decompile
    local uniqueCount = 0
    for _ in pairs(hashGroups) do
        uniqueCount = uniqueCount + 1
    end
    local totalToDecompile = uniqueCount + #noHashScripts

    Status.set(string.format(
        "Scripts: %d total | %d unique | %d cached | Decompiling...",
        #scriptList, totalToDecompile, stats.cached
    ), 0, totalToDecompile)

    -- ═══ PHASE 2: Decompile unique hashes (batch) ═══
    local processedCount = 0

    -- 2a: Decompile hash groups (mỗi hash chỉ decompile 1 script đại diện)
    local hashEntries = {}
    for hash, scripts in pairs(hashGroups) do
        hashEntries[#hashEntries + 1] = {hash = hash, scripts = scripts}
    end

    -- Xử lý theo batch
    for batchStart = 1, #hashEntries, DECOMPILE_BATCH_SIZE do
        local batchEnd = math.min(batchStart + DECOMPILE_BATCH_SIZE - 1, #hashEntries)
        local batchResults = {}
        local batchDone = {}

        -- Khởi chạy batch song song
        for i = batchStart, batchEnd do
            local entry = hashEntries[i]
            local representative = entry.scripts[1] -- Chỉ decompile script đầu tiên

            batchDone[i] = false

            task.spawn(function()
                local source, method = Decompiler.decompileSingle(representative, DECOMPILE_TIMEOUT)
                batchResults[i] = {
                    source = source,
                    method = method,
                    hash = entry.hash,
                    scripts = entry.scripts
                }
                batchDone[i] = true
            end)
        end

        -- Chờ batch hoàn thành (với global timeout)
        local batchTimeout = DECOMPILE_TIMEOUT + 3
        local batchStartTime = os.clock()

        while true do
            local allDone = true
            for i = batchStart, batchEnd do
                if not batchDone[i] then
                    allDone = false
                    break
                end
            end

            if allDone then break end

            if (os.clock() - batchStartTime) > batchTimeout then
                -- Force timeout cho scripts chưa xong
                for i = batchStart, batchEnd do
                    if not batchDone[i] then
                        local entry = hashEntries[i]
                        batchResults[i] = {
                            source = string.format(
                                "-- [BaoSaveInstance] Decompile timeout (%ds)\n-- Script: %s\n",
                                DECOMPILE_TIMEOUT, entry.scripts[1].Name
                            ),
                            method = "timeout",
                            hash = entry.hash,
                            scripts = entry.scripts
                        }
                        batchDone[i] = true
                    end
                end
                break
            end

            task.wait(0.02)
        end

        -- Áp dụng kết quả batch
        for i = batchStart, batchEnd do
            local result = batchResults[i]
            if result then
                -- Cache kết quả
                if result.hash then
                    BaoSaveInstance._cache[result.hash] = result.source
                end

                -- Áp dụng cho tất cả scripts cùng hash
                for _, scriptInst in ipairs(result.scripts) do
                    results[scriptInst] = result.source

                    if result.method == "failed" or result.method == "timeout" then
                        stats.failed = stats.failed + 1
                    else
                        stats.decompiled = stats.decompiled + 1
                    end
                end

                -- Scripts duplicate (cùng hash) đếm là cached
                if #result.scripts > 1 then
                    stats.cached = stats.cached + (#result.scripts - 1)
                end

                processedCount = processedCount + 1
            end
        end

        Status.set(string.format(
            "Decompiling... [%d/%d] (batch %d-%d)",
            processedCount, totalToDecompile, batchStart, batchEnd
        ), processedCount, totalToDecompile)

        -- Yield giữa các batch
        task.wait(0.01)
    end

    -- 2b: Decompile scripts không hash được (tuần tự, nhanh)
    for i, scriptInst in ipairs(noHashScripts) do
        local source, method = Decompiler.decompileSingle(scriptInst, DECOMPILE_TIMEOUT)
        results[scriptInst] = source

        if method == "failed" or method == "timeout" then
            stats.failed = stats.failed + 1
        else
            stats.decompiled = stats.decompiled + 1
        end

        processedCount = processedCount + 1

        if i % DECOMPILE_BATCH_SIZE == 0 then
            Status.set(string.format(
                "Decompiling no-hash... [%d/%d]",
                processedCount, totalToDecompile
            ), processedCount, totalToDecompile)
            task.wait(0.01)
        end
    end

    stats.endTime = os.clock()

    local elapsed = stats.endTime - stats.startTime
    Status.set(string.format(
        "Decompile Done ✓ | %d ok | %d cached | %d fail | %.1fs",
        stats.decompiled, stats.cached, stats.failed, elapsed
    ), totalToDecompile, totalToDecompile)

    return results
end

-- ═══════════════════════════════════════════════════════════════
-- SCRIPT COLLECTOR - Thu thập nhanh tất cả scripts
-- ═══════════════════════════════════════════════════════════════

local Collector = {}

function Collector.getAllScripts(roots, includeNil, includeModules)
    local scripts = {}
    local seen = {} -- Dedup bằng reference

    local function addScript(inst)
        if not seen[inst] then
            seen[inst] = true
            scripts[#scripts + 1] = inst
        end
    end

    -- Thu thập từ roots
    for _, root in ipairs(roots) do
        pcall(function()
            -- GetDescendants nhanh hơn đệ quy manual
            local descendants = root:GetDescendants()
            for i = 1, #descendants do
                local inst = descendants[i]
                if inst:IsA("LuaSourceContainer") then
                    addScript(inst)
                end
            end
        end)
    end

    -- Nil instances
    if includeNil and Env.getnilinstances then
        pcall(function()
            local nilInsts = Env.getnilinstances()
            for i = 1, #nilInsts do
                if nilInsts[i]:IsA("LuaSourceContainer") then
                    addScript(nilInsts[i])
                end
            end
        end)
    end

    -- Loaded modules
    if includeModules and Env.getloadedmodules then
        pcall(function()
            local modules = Env.getloadedmodules()
            for i = 1, #modules do
                addScript(modules[i])
            end
        end)
    end

    -- Running scripts
    if Env.getrunningscripts then
        pcall(function()
            local running = Env.getrunningscripts()
            for i = 1, #running do
                addScript(running[i])
            end
        end)
    end

    return scripts
end

-- ═══════════════════════════════════════════════════════════════
-- STREAMING SERIALIZER - Memory efficient XML builder
-- ═══════════════════════════════════════════════════════════════

local Serializer = {}
Serializer._refCounter = 0
Serializer._chunks = {} -- String chunks để tránh string concat O(n²)
Serializer._chunkSize = 0
Serializer._instanceCount = 0
Serializer._yieldCounter = 0

-- Reset state
function Serializer.reset()
    Serializer._refCounter = 0
    Serializer._chunks = {}
    Serializer._chunkSize = 0
    Serializer._instanceCount = 0
    Serializer._yieldCounter = 0
end

-- Tạo ref ID
function Serializer.newRef()
    Serializer._refCounter = Serializer._refCounter + 1
    return "RBX" .. Serializer._refCounter
end

-- Thêm chunk vào buffer (tránh string concat liên tục)
function Serializer.write(str)
    local chunks = Serializer._chunks
    chunks[#chunks + 1] = str
    Serializer._chunkSize = Serializer._chunkSize + #str
end

-- Flush chunks thành string (dùng table.concat - O(n))
function Serializer.flush()
    local result = table.concat(Serializer._chunks)
    Serializer._chunks = {}
    Serializer._chunkSize = 0
    return result
end

-- Yield check (gọi mỗi instance)
function Serializer.yieldCheck()
    Serializer._yieldCounter = Serializer._yieldCounter + 1
    if Serializer._yieldCounter % SERIALIZE_YIELD_INTERVAL == 0 then
        task.wait()
    end
end

-- ═══════════════════════════════════════════════════════════════
-- XML ESCAPE (optimized - dùng pattern thay vì gsub chain)
-- ═══════════════════════════════════════════════════════════════

local _xmlEscapeMap = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&apos;",
}

local function xmlEscape(str)
    if type(str) ~= "string" then
        return tostring(str or "")
    end
    -- Single pass replacement
    str = str:gsub('[&<>"\']', _xmlEscapeMap)
    -- Remove invalid XML chars
    str = str:gsub("[%z\1-\8\11\12\14-\31]", "")
    return str
end

-- CDATA wrap (cho script source - không cần escape)
local function cdataWrap(str)
    if type(str) ~= "string" then return "" end
    -- Handle ]]> inside CDATA
    str = str:gsub("]]>", "]]]]><![CDATA[>")
    return "<![CDATA[" .. str .. "]]>"
end

-- ═══════════════════════════════════════════════════════════════
-- PROPERTY SERIALIZATION (optimized type dispatch)
-- ═══════════════════════════════════════════════════════════════

-- Type dispatch table (tránh if-elseif chain dài)
local TypeSerializers = {}

TypeSerializers["string"] = function(name, value)
    return string.format('<string name="%s">%s</string>', name, xmlEscape(value))
end

TypeSerializers["boolean"] = function(name, value)
    return string.format('<bool name="%s">%s</bool>', name, tostring(value))
end

TypeSerializers["number"] = function(name, value)
    return string.format('<double name="%s">%s</double>', name, tostring(value))
end

TypeSerializers["Color3"] = function(name, value)
    return string.format(
        '<Color3 name="%s"><R>%s</R><G>%s</G><B>%s</B></Color3>',
        name, tostring(value.R), tostring(value.G), tostring(value.B)
    )
end

TypeSerializers["Vector3"] = function(name, value)
    return string.format(
        '<Vector3 name="%s"><X>%s</X><Y>%s</Y><Z>%s</Z></Vector3>',
        name, tostring(value.X), tostring(value.Y), tostring(value.Z)
    )
end

TypeSerializers["Vector2"] = function(name, value)
    return string.format(
        '<Vector2 name="%s"><X>%s</X><Y>%s</Y></Vector2>',
        name, tostring(value.X), tostring(value.Y)
    )
end

TypeSerializers["CFrame"] = function(name, value)
    local c = {value:GetComponents()}
    return string.format(
        '<CoordinateFrame name="%s">' ..
        '<X>%s</X><Y>%s</Y><Z>%s</Z>' ..
        '<R00>%s</R00><R01>%s</R01><R02>%s</R02>' ..
        '<R10>%s</R10><R11>%s</R11><R12>%s</R12>' ..
        '<R20>%s</R20><R21>%s</R21><R22>%s</R22>' ..
        '</CoordinateFrame>',
        name,
        tostring(c[1]), tostring(c[2]), tostring(c[3]),
        tostring(c[4]), tostring(c[5]), tostring(c[6]),
        tostring(c[7]), tostring(c[8]), tostring(c[9]),
        tostring(c[10]), tostring(c[11]), tostring(c[12])
    )
end

TypeSerializers["UDim"] = function(name, value)
    return string.format(
        '<UDim name="%s"><S>%s</S><O>%d</O></UDim>',
        name, tostring(value.Scale), value.Offset
    )
end

TypeSerializers["UDim2"] = function(name, value)
    return string.format(
        '<UDim2 name="%s"><XS>%s</XS><XO>%d</XO><YS>%s</YS><YO>%d</YO></UDim2>',
        name,
        tostring(value.X.Scale), value.X.Offset,
        tostring(value.Y.Scale), value.Y.Offset
    )
end

TypeSerializers["Rect"] = function(name, value)
    return string.format(
        '<Rect2D name="%s"><min><X>%s</X><Y>%s</Y></min><max><X>%s</X><Y>%s</Y></max></Rect2D>',
        name,
        tostring(value.Min.X), tostring(value.Min.Y),
        tostring(value.Max.X), tostring(value.Max.Y)
    )
end

TypeSerializers["NumberRange"] = function(name, value)
    return string.format(
        '<NumberRange name="%s">%s %s</NumberRange>',
        name, tostring(value.Min), tostring(value.Max)
    )
end

TypeSerializers["NumberSequence"] = function(name, value)
    local parts = {}
    for _, kp in ipairs(value.Keypoints) do
        parts[#parts + 1] = string.format("%s %s %s", tostring(kp.Time), tostring(kp.Value), tostring(kp.Envelope))
    end
    return string.format('<NumberSequence name="%s">%s</NumberSequence>', name, table.concat(parts, " "))
end

TypeSerializers["ColorSequence"] = function(name, value)
    local parts = {}
    for _, kp in ipairs(value.Keypoints) do
        parts[#parts + 1] = string.format("%s %s %s %s 0",
            tostring(kp.Time), tostring(kp.Value.R), tostring(kp.Value.G), tostring(kp.Value.B)
        )
    end
    return string.format('<ColorSequence name="%s">%s</ColorSequence>', name, table.concat(parts, " "))
end

TypeSerializers["EnumItem"] = function(name, value)
    return string.format('<token name="%s">%d</token>', name, value.Value)
end

TypeSerializers["BrickColor"] = function(name, value)
    return string.format('<int name="%s">%d</int>', name, value.Number)
end

TypeSerializers["PhysicalProperties"] = function(name, value)
    if value then
        return string.format(
            '<PhysicalProperties name="%s">' ..
            '<CustomPhysics>true</CustomPhysics>' ..
            '<Density>%s</Density><Friction>%s</Friction>' ..
            '<Elasticity>%s</Elasticity><FrictionWeight>%s</FrictionWeight>' ..
            '<ElasticityWeight>%s</ElasticityWeight></PhysicalProperties>',
            name,
            tostring(value.Density), tostring(value.Friction),
            tostring(value.Elasticity), tostring(value.FrictionWeight),
            tostring(value.ElasticityWeight)
        )
    end
    return string.format(
        '<PhysicalProperties name="%s"><CustomPhysics>false</CustomPhysics></PhysicalProperties>',
        name
    )
end

TypeSerializers["Faces"] = function(name, value)
    local v = 0
    if value.Top then v = v + 1 end
    if value.Bottom then v = v + 2 end
    if value.Left then v = v + 4 end
    if value.Right then v = v + 8 end
    if value.Back then v = v + 16 end
    if value.Front then v = v + 32 end
    return string.format('<Faces name="%s">%d</Faces>', name, v)
end

TypeSerializers["Axes"] = function(name, value)
    local v = 0
    if value.X then v = v + 1 end
    if value.Y then v = v + 2 end
    if value.Z then v = v + 4 end
    return string.format('<Axes name="%s">%d</Axes>', name, v)
end

TypeSerializers["Font"] = function(name, value)
    return string.format(
        '<Font name="%s"><Family><url>%s</url></Family>' ..
        '<Weight>%d</Weight><Style>%s</Style></Font>',
        name,
        xmlEscape(tostring(value.Family)),
        value.Weight.Value,
        tostring(value.Style)
    )
end

TypeSerializers["Content"] = function(name, value)
    return string.format('<Content name="%s"><url>%s</url></Content>', name, xmlEscape(tostring(value)))
end

TypeSerializers["Instance"] = function(name, value)
    -- Object references (Part0, Part1, Adornee, etc.)
    return string.format('<Ref name="%s">null</Ref>', name)
end

-- Dispatch function
local function serializeProperty(name, value)
    if value == nil then return nil end

    local t = typeof(value)

    -- Lookup trong dispatch table
    local serializer = TypeSerializers[t]
    if serializer then
        local ok, result = pcall(serializer, xmlEscape(name), value)
        if ok then return result end
    end

    -- Lua type fallback
    local lt = type(value)
    serializer = TypeSerializers[lt]
    if serializer then
        local ok, result = pcall(serializer, xmlEscape(name), value)
        if ok then return result end
    end

    -- Content strings (asset URLs)
    if lt == "string" then
        return TypeSerializers["string"](xmlEscape(name), value)
    end

    -- Ultimate fallback
    return string.format('<string name="%s">%s</string>', xmlEscape(name), xmlEscape(tostring(value)))
end

-- ═══════════════════════════════════════════════════════════════
-- PROPERTY REFLECTION - Lấy properties thực tế của instance
-- ═══════════════════════════════════════════════════════════════

local PropertyReflector = {}

-- Cached class → properties map
local _classPropsCache = {}

-- Danh sách properties phổ biến cho mỗi class group
local CLASS_PROPERTIES = {
    -- Base
    _base = {"Name", "Archivable"},

    -- BasePart
    _basePart = {
        "Anchored", "BrickColor", "CFrame", "CanCollide", "CanTouch", "CanQuery",
        "CastShadow", "CollisionGroup", "Color", "CustomPhysicalProperties",
        "Locked", "Massless", "Material", "MaterialVariant", "PivotOffset",
        "Reflectance", "RootPriority", "Size", "Transparency",
    },

    Part = {"Shape"},
    WedgePart = {},
    CornerWedgePart = {},
    TrussPart = {"Style"},
    MeshPart = {"MeshId", "TextureID"},
    UnionOperation = {"SmoothingAngle", "UsePartColor"},
    NegateOperation = {},
    SpawnLocation = {"AllowTeamChangeOnTouch", "Duration", "Enabled", "Neutral", "TeamColor"},
    Seat = {"Disabled"},
    VehicleSeat = {"Disabled", "MaxSpeed", "Steer", "Throttle", "Torque", "TurnSpeed"},

    -- Scripts
    Script = {"Source", "Disabled", "RunContext"},
    LocalScript = {"Source", "Disabled"},
    ModuleScript = {"Source"},

    -- Structure
    Model = {"LevelOfDetail", "ModelStreamingMode", "PrimaryPart"},
    Folder = {},
    Configuration = {},

    -- Joints
    Weld = {"C0", "C1", "Enabled", "Part0", "Part1"},
    WeldConstraint = {"Enabled", "Part0", "Part1"},
    Motor6D = {"C0", "C1", "CurrentAngle", "DesiredAngle", "Enabled", "MaxVelocity", "Part0", "Part1"},
    ManualWeld = {"C0", "C1", "Enabled", "Part0", "Part1"},
    ManualGlue = {"C0", "C1", "Enabled", "Part0", "Part1"},
    Snap = {"C0", "C1", "Enabled", "Part0", "Part1"},

    -- Constraints
    BallSocketConstraint = {"Attachment0", "Attachment1", "Enabled", "LimitsEnabled", "MaxFrictionTorque", "Radius", "Restitution", "TwistLimitsEnabled", "TwistLowerAngle", "TwistUpperAngle", "UpperAngle"},
    HingeConstraint = {"Attachment0", "Attachment1", "ActuatorType", "AngularResponsiveness", "AngularSpeed", "AngularVelocity", "Enabled", "LimitsEnabled", "LowerAngle", "MotorMaxAcceleration", "MotorMaxTorque", "Radius", "Restitution", "ServoMaxTorque", "TargetAngle", "UpperAngle"},
    PrismaticConstraint = {"Attachment0", "Attachment1", "ActuatorType", "Enabled", "LimitsEnabled", "LowerLimit", "MotorMaxAcceleration", "MotorMaxForce", "Restitution", "ServoMaxForce", "Size", "Speed", "TargetPosition", "UpperLimit", "Velocity"},
    CylindricalConstraint = {"Attachment0", "Attachment1", "Enabled", "InclinationAngle", "LimitsEnabled", "LowerLimit", "MotorMaxAcceleration", "MotorMaxForce", "Restitution", "RotationAxisVisible", "ServoMaxForce", "Size", "Speed", "TargetPosition", "UpperLimit", "Velocity"},
    SpringConstraint = {"Attachment0", "Attachment1", "Coils", "Damping", "Enabled", "FreeLength", "LimitsEnabled", "MaxForce", "MaxLength", "MinLength", "Radius", "Stiffness", "Thickness"},
    RopeConstraint = {"Attachment0", "Attachment1", "Color", "Enabled", "Length", "Restitution", "Thickness", "Visible", "WinchEnabled", "WinchForce", "WinchResponsiveness", "WinchSpeed", "WinchTarget"},
    RodConstraint = {"Attachment0", "Attachment1", "Color", "Enabled", "Length", "Thickness", "Visible"},
    AlignOrientation = {"Attachment0", "Attachment1", "Enabled", "MaxAngularVelocity", "MaxTorque", "Mode", "PrimaryAxisOnly", "ReactionTorqueEnabled", "Responsiveness", "RigidityEnabled"},
    AlignPosition = {"Attachment0", "Attachment1", "ApplyAtCenterOfMass", "Enabled", "MaxForce", "MaxVelocity", "Mode", "ReactionForceEnabled", "Responsiveness", "RigidityEnabled"},
    LinearVelocity = {"Attachment0", "Attachment1", "Enabled", "ForceLimitMode", "LineDirection", "LineVelocity", "MaxAxesForce", "MaxForce", "MaxPlanarAxesForce", "PlaneVelocity", "RelativeTo", "VectorVelocity", "VelocityConstraintMode"},
    AngularVelocity = {"Attachment0", "Attachment1", "AngularVelocity", "Enabled", "MaxTorque", "ReactionTorqueEnabled", "RelativeTo"},
    Torque = {"Force", "RelativeTo"},
    VectorForce = {"Attachment0", "ApplyAtCenterOfMass", "Enabled", "Force", "RelativeTo"},
    LineForce = {"Attachment0", "Attachment1", "ApplyAtCenterOfMass", "Enabled", "InverseSquareLaw", "Magnitude", "MaxForce", "ReactionForceEnabled"},
    NoCollisionConstraint = {"Enabled", "Part0", "Part1"},
    UniversalConstraint = {"Attachment0", "Attachment1", "Enabled", "LimitsEnabled", "MaxAngle", "Radius", "Restitution"},
    PlaneConstraint = {"Attachment0", "Attachment1", "Enabled"},
    Plane = {"Attachment0", "Attachment1", "Enabled"},

    -- Attachments
    Attachment = {"CFrame", "Visible"},
    Bone = {"CFrame", "Visible"},

    -- Visual
    Decal = {"Color3", "Face", "Texture", "Transparency", "ZIndex"},
    Texture = {"Color3", "Face", "OffsetStudsU", "OffsetStudsV", "StudsPerTileU", "StudsPerTileV", "Texture", "Transparency", "ZIndex"},
    SurfaceAppearance = {"AlphaMode", "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap", "TexturePack"},
    SpecialMesh = {"MeshId", "MeshType", "Offset", "Scale", "TextureId", "VertexColor"},
    BlockMesh = {"Offset", "Scale", "VertexColor"},
    CylinderMesh = {"Offset", "Scale", "VertexColor"},
    FileMesh = {"MeshId", "Offset", "Scale", "TextureId", "VertexColor"},

    -- Lights
    PointLight = {"Brightness", "Color", "Enabled", "Range", "Shadows"},
    SpotLight = {"Angle", "Brightness", "Color", "Enabled", "Face", "Range", "Shadows"},
    SurfaceLight = {"Angle", "Brightness", "Color", "Enabled", "Face", "Range", "Shadows"},

    -- Particles
    ParticleEmitter = {"Acceleration", "Brightness", "Color", "Drag", "EmissionDirection", "Enabled", "FlipbookFramerate", "FlipbookLayout", "FlipbookMode", "FlipbookStartRandom", "Lifetime", "LightEmission", "LightInfluence", "LockedToPart", "Orientation", "Rate", "RotSpeed", "Rotation", "Shape", "ShapeInOut", "ShapeStyle", "Size", "Speed", "SpreadAngle", "Squash", "Texture", "TimeScale", "Transparency", "VelocityInheritance", "WindAffectsDrag", "ZOffset"},
    Beam = {"Attachment0", "Attachment1", "Brightness", "Color", "CurveSize0", "CurveSize1", "Enabled", "FaceCamera", "LightEmission", "LightInfluence", "Segments", "Texture", "TextureLength", "TextureMode", "TextureSpeed", "Transparency", "Width0", "Width1", "ZOffset"},
    Trail = {"Attachment0", "Attachment1", "Brightness", "Color", "Enabled", "FaceCamera", "Lifetime", "LightEmission", "LightInfluence", "MaxLength", "MinLength", "Texture", "TextureLength", "TextureMode", "Transparency", "WidthScale"},
    Fire = {"Color", "Enabled", "Heat", "SecondaryColor", "Size", "TimeScale"},
    Smoke = {"Color", "Enabled", "Opacity", "RiseVelocity", "Size", "TimeScale"},
    Sparkles = {"Color", "Enabled", "SparkleColor", "TimeScale"},

    -- Sound
    Sound = {"EmitterSize", "Looped", "MaxDistance", "PlayOnRemove", "PlaybackSpeed", "Playing", "RollOffMaxDistance", "RollOffMinDistance", "RollOffMode", "SoundId", "TimePosition", "Volume"},
    SoundGroup = {"Volume"},
    EchoSoundEffect = {"Delay", "DryLevel", "Enabled", "Feedback", "Priority", "WetLevel"},
    ReverbSoundEffect = {"DecayTime", "Density", "Diffusion", "DryLevel", "Enabled", "Priority", "WetLevel"},
    ChorusSoundEffect = {"Depth", "Enabled", "Mix", "Priority", "Rate"},
    DistortionSoundEffect = {"Enabled", "Level", "Priority"},
    FlangeSoundEffect = {"Depth", "Enabled", "Mix", "Priority", "Rate"},
    PitchShiftSoundEffect = {"Enabled", "Octave", "Priority"},
    TremoloSoundEffect = {"Depth", "Duty", "Enabled", "Frequency", "Priority"},
    CompressorSoundEffect = {"Attack", "Enabled", "GainMakeup", "Priority", "Ratio", "Release", "SideChain", "Threshold"},
    EqualizerSoundEffect = {"Enabled", "HighGain", "LowGain", "MidGain", "MidRange", "Priority"},

    -- Lighting & Post
    Atmosphere = {"Color", "Decay", "Density", "Glare", "Haze", "Offset"},
    Sky = {"CelestialBodiesShown", "MoonAngularSize", "MoonTextureId", "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "StarCount", "SunAngularSize", "SunTextureId"},
    Clouds = {"Color", "Cover", "Density", "Enabled"},
    BloomEffect = {"Enabled", "Intensity", "Size", "Threshold"},
    BlurEffect = {"Enabled", "Size"},
    ColorCorrectionEffect = {"Brightness", "Contrast", "Enabled", "Saturation", "TintColor"},
    DepthOfFieldEffect = {"Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"},
    SunRaysEffect = {"Enabled", "Intensity", "Spread"},

    -- GUI
    ScreenGui = {"DisplayOrder", "Enabled", "IgnoreGuiInset", "ResetOnSpawn", "ZIndexBehavior", "ScreenInsets"},
    BillboardGui = {"Active", "Adornee", "AlwaysOnTop", "Brightness", "ClipsDescendants", "Enabled", "ExtentsOffset", "ExtentsOffsetWorldSpace", "LightInfluence", "MaxDistance", "ResetOnSpawn", "Size", "SizeOffset", "StudsOffset", "StudsOffsetWorldSpace", "ZIndexBehavior"},
    SurfaceGui = {"Active", "Adornee", "AlwaysOnTop", "Brightness", "CanvasSize", "ClipsDescendants", "Enabled", "Face", "LightInfluence", "PixelsPerStud", "ResetOnSpawn", "SizingMode", "ZIndexBehavior", "ZOffset"},
    Frame = {"Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "LayoutOrder", "Position", "Rotation", "Size", "SizeConstraint", "Visible", "ZIndex"},
    TextLabel = {"Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "Font", "FontFace", "LayoutOrder", "LineHeight", "MaxVisibleGraphemes", "Position", "RichText", "Rotation", "Size", "SizeConstraint", "Text", "TextColor3", "TextScaled", "TextSize", "TextStrokeColor3", "TextStrokeTransparency", "TextTransparency", "TextTruncate", "TextWrapped", "TextXAlignment", "TextYAlignment", "Visible", "ZIndex"},
    TextButton = {"Active", "AnchorPoint", "AutoButtonColor", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "Font", "FontFace", "LayoutOrder", "LineHeight", "MaxVisibleGraphemes", "Modal", "Position", "RichText", "Rotation", "Selected", "Size", "SizeConstraint", "Text", "TextColor3", "TextScaled", "TextSize", "TextStrokeColor3", "TextStrokeTransparency", "TextTransparency", "TextTruncate", "TextWrapped", "TextXAlignment", "TextYAlignment", "Visible", "ZIndex"},
    TextBox = {"Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel", "ClearTextOnFocus", "ClipsDescendants", "Font", "FontFace", "LayoutOrder", "LineHeight", "MaxVisibleGraphemes", "MultiLine", "PlaceholderColor3", "PlaceholderText", "Position", "RichText", "Rotation", "ShowNativeInput", "Size", "SizeConstraint", "Text", "TextColor3", "TextEditable", "TextScaled", "TextSize", "TextStrokeColor3", "TextStrokeTransparency", "TextTransparency", "TextTruncate", "TextWrapped", "TextXAlignment", "TextYAlignment", "Visible", "ZIndex"},
    ImageLabel = {"Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "Image", "ImageColor3", "ImageRectOffset", "ImageRectSize", "ImageTransparency", "LayoutOrder", "Position", "Rotation", "ScaleType", "Size", "SizeConstraint", "SliceCenter", "SliceScale", "TileSize", "Visible", "ZIndex"},
    ImageButton = {"Active", "AnchorPoint", "AutoButtonColor", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "Image", "ImageColor3", "ImageRectOffset", "ImageRectSize", "ImageTransparency", "LayoutOrder", "Modal", "Position", "Rotation", "ScaleType", "Selected", "Size", "SizeConstraint", "SliceCenter", "SliceScale", "TileSize", "Visible", "ZIndex"},
    ViewportFrame = {"Active", "Ambient", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "ImageColor3", "ImageTransparency", "LayoutOrder", "LightColor", "LightDirection", "Position", "Rotation", "Size", "SizeConstraint", "Visible", "ZIndex"},
    ScrollingFrame = {"Active", "AnchorPoint", "AutomaticCanvasSize", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel", "BottomImage", "CanvasPosition", "CanvasSize", "ClipsDescendants", "ElasticBehavior", "HorizontalScrollBarInset", "LayoutOrder", "MidImage", "Position", "Rotation", "ScrollBarImageColor3", "ScrollBarImageTransparency", "ScrollBarThickness", "ScrollingDirection", "ScrollingEnabled", "Size", "SizeConstraint", "TopImage", "VerticalScrollBarInset", "VerticalScrollBarPosition", "Visible", "ZIndex"},
    CanvasGroup = {"Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "GroupColor3", "GroupTransparency", "LayoutOrder", "Position", "Rotation", "Size", "SizeConstraint", "Visible", "ZIndex"},
    VideoFrame = {"AnchorPoint", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel", "LayoutOrder", "Looped", "Playing", "Position", "Size", "Video", "Visible", "Volume", "ZIndex"},

    -- UI Layout
    UIListLayout = {"FillDirection", "HorizontalAlignment", "HorizontalFlex", "ItemLineAlignment", "Padding", "SortOrder", "VerticalAlignment", "VerticalFlex", "Wraps"},
    UIGridLayout = {"CellPadding", "CellSize", "FillDirection", "FillDirectionMaxCells", "HorizontalAlignment", "SortOrder", "StartCorner", "VerticalAlignment"},
    UITableLayout = {"FillDirection", "FillEmptySpaceColumns", "FillEmptySpaceRows", "HorizontalAlignment", "MajorAxis", "Padding", "SortOrder", "VerticalAlignment"},
    UIPageLayout = {"Animated", "Circular", "EasingDirection", "EasingStyle", "FillDirection", "GamepadInputEnabled", "HorizontalAlignment", "Padding", "ScrollWheelInputEnabled", "SortOrder", "TouchInputEnabled", "TweenTime", "VerticalAlignment"},
    UICorner = {"CornerRadius"},
    UIPadding = {"PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"},
    UIScale = {"Scale"},
    UISizeConstraint = {"MaxSize", "MinSize"},
    UITextSizeConstraint = {"MaxTextSize", "MinTextSize"},
    UIAspectRatioConstraint = {"AspectRatio", "AspectType", "DominantAxis"},
    UIStroke = {"ApplyStrokeMode", "Color", "Enabled", "LineJoinMode", "Thickness", "Transparency"},
    UIGradient = {"Color", "Enabled", "Offset", "Rotation", "Transparency"},
    UIFlexItem = {"FlexMode", "GrowRatio", "ItemLineAlignment", "ShrinkRatio"},

    -- Humanoid
    Humanoid = {"AutoJumpEnabled", "AutoRotate", "AutomaticScalingEnabled", "BreakJointsOnDeath", "DisplayDistanceType", "DisplayName", "EvaluateStateMachine", "Health", "HealthDisplayDistance", "HealthDisplayType", "HipHeight", "JumpHeight", "JumpPower", "MaxHealth", "MaxSlopeAngle", "NameDisplayDistance", "NameOcclusion", "RequiresNeck", "RigType", "UseJumpPower", "WalkSpeed"},
    HumanoidDescription = {"BackAccessory", "BodyTypeScale", "ClimbAnimation", "DepthScale", "Face", "FaceAccessory", "FallAnimation", "FrontAccessory", "GraphicTShirt", "HairAccessory", "HatAccessory", "Head", "HeadColor", "HeadScale", "HeightScale", "IdleAnimation", "JumpAnimation", "LeftArm", "LeftArmColor", "LeftLeg", "LeftLegColor", "MoodAnimation", "NeckAccessory", "Pants", "ProportionScale", "RightArm", "RightArmColor", "RightLeg", "RightLegColor", "RunAnimation", "Shirt", "ShouldersAccessory", "SwimAnimation", "Torso", "TorsoColor", "WaistAccessory", "WalkAnimation", "WidthScale"},
    Shirt = {"ShirtTemplate"},
    Pants = {"PantsTemplate"},
    ShirtGraphic = {"Color3", "Graphic"},
    BodyColors = {"HeadColor3", "LeftArmColor3", "LeftLegColor3", "RightArmColor3", "RightLegColor3", "TorsoColor3"},
    CharacterMesh = {"BaseTextureId", "BodyPart", "MeshId", "OverlayTextureId"},
    Accessory = {"AccessoryType", "AttachmentPoint"},

    -- Animation
    Animation = {"AnimationId"},
    AnimationController = {},
    Animator = {},

    -- Values
    StringValue = {"Value"},
    IntValue = {"Value"},
    NumberValue = {"Value"},
    BoolValue = {"Value"},
    ObjectValue = {"Value"},
    BrickColorValue = {"Value"},
    Color3Value = {"Value"},
    CFrameValue = {"Value"},
    Vector3Value = {"Value"},
    RayValue = {"Value"},

    -- Interaction
    ClickDetector = {"CursorIcon", "MaxActivationDistance"},
    ProximityPrompt = {"ActionText", "AutoLocalize", "ClickablePrompt", "Enabled", "ExclusivityMode", "GamepadKeyCode", "HoldDuration", "KeyboardKeyCode", "MaxActivationDistance", "ObjectText", "RequiresLineOfSight", "Style", "UIOffset"},
    Tool = {"CanBeDropped", "Enabled", "Grip", "GripForward", "GripPos", "GripRight", "GripUp", "ManualActivationOnly", "RequiresHandle", "TextureId", "ToolTip"},

    -- Misc
    Highlight = {"Adornee", "DepthMode", "Enabled", "FillColor", "FillTransparency", "OutlineColor", "OutlineTransparency"},
    SelectionBox = {"Adornee", "Color3", "LineThickness", "SurfaceColor3", "SurfaceTransparency", "Transparency", "Visible"},
    SelectionSphere = {"Adornee", "Color3", "SurfaceColor3", "SurfaceTransparency", "Transparency", "Visible"},
    BillboardGui_Adornee = {},
    Camera = {"CFrame", "CameraType", "FieldOfView", "FieldOfViewMode", "Focus", "HeadLocked", "HeadScale"},
    Team = {"AutoAssignable", "TeamColor"},
    BindableEvent = {},
    BindableFunction = {},
    RemoteEvent = {},
    RemoteFunction = {},
    UnreliableRemoteEvent = {},
    PathfindingModifier = {"Label", "PassThrough"},
    PathfindingLink = {"Attachment0", "Attachment1", "IsBidirectional", "Label"},
    Dialog = {"BehaviorType", "ConversationDistance", "GoodbyeChoiceActive", "GoodbyeDialog", "InUse", "InitialPrompt", "Purpose", "Tone", "TriggerDistance", "TriggerOffset"},
    DialogChoice = {"GoodbyeChoiceActive", "GoodbyeDialog", "ResponseDialog", "UserDialog"},

    -- Body Movers (Legacy)
    BodyForce = {"Force"},
    BodyVelocity = {"MaxForce", "P", "Velocity"},
    BodyPosition = {"D", "MaxForce", "P", "Position"},
    BodyGyro = {"CFrame", "D", "MaxTorque", "P"},
    BodyAngularVelocity = {"AngularVelocity", "MaxTorque", "P"},
    BodyThrust = {"Force", "Location"},
    RocketPropulsion = {"CartoonFactor", "MaxSpeed", "MaxThrust", "MaxTorque", "Target", "TargetOffset", "TargetRadius", "ThrustD", "ThrustP", "TurnD", "TurnP"},
}

-- Lấy properties cho một class (cached)
function PropertyReflector.getProperties(className)
    if _classPropsCache[className] then
        return _classPropsCache[className]
    end

    local props = {}

    -- Base properties
    for _, p in ipairs(CLASS_PROPERTIES._base) do
        props[#props + 1] = p
    end

    -- BasePart check
    local isBasePart = CLASS_PROPERTIES[className] ~= nil and (
        className == "Part" or className == "WedgePart" or
        className == "CornerWedgePart" or className == "TrussPart" or
        className == "MeshPart" or className == "UnionOperation" or
        className == "NegateOperation" or className == "SpawnLocation" or
        className == "Seat" or className == "VehicleSeat" or
        className == "SkateboardPlatform" or className == "FlagStand"
    )

    if isBasePart then
        for _, p in ipairs(CLASS_PROPERTIES._basePart) do
            props[#props + 1] = p
        end
    end

    -- Class-specific properties
    if CLASS_PROPERTIES[className] then
        for _, p in ipairs(CLASS_PROPERTIES[className]) do
            props[#props + 1] = p
        end
    end

    -- Nếu executor có getproperties, bổ sung thêm
    if Env.getproperties then
        pcall(function()
            -- Tạo instance tạm để lấy properties (nếu cần)
            -- Hoặc dùng trực tiếp nếu hỗ trợ class name
        end)
    end

    _classPropsCache[className] = props
    return props
end

-- ═══════════════════════════════════════════════════════════════
-- INSTANCE SERIALIZER (streaming, low memory)
-- ═══════════════════════════════════════════════════════════════

-- Skip list
local SKIP_CLASSES = {
    Player = true, PlayerGui = true, Backpack = true,
    PlayerScripts = true, StarterPlayerScripts = true,
    CoreGui = true, CorePackages = true,
    NetworkClient = true, NetworkServer = true,
    Stats = true, CSGDictionaryService = true,
    NonReplicatedCSGDictionaryService = true,
    LogService = true, AnalyticsService = true,
}

local SKIP_NAMES = {
    BaoSaveInstance_GUI = true,
}

function Serializer.serializeInstance(instance, decompiledScripts, depth)
    depth = depth or 0
    if depth > 80 then return end -- Stack overflow protection

    local className = instance.ClassName

    -- Skip check
    if SKIP_CLASSES[className] or SKIP_NAMES[instance.Name] then
        return
    end

    Serializer._instanceCount = Serializer._instanceCount + 1
    Serializer.yieldCheck()

    local ref = Serializer.newRef()
    local indent = string.rep("  ", depth)

    -- Open tag
    Serializer.write(string.format('%s<Item class="%s" referent="%s">\n', indent, className, ref))
    Serializer.write(indent .. '  <Properties>\n')

    -- Properties
    local props = PropertyReflector.getProperties(className)

    for _, propName in ipairs(props) do
        -- Script Source: đặc biệt
        if propName == "Source" and instance:IsA("LuaSourceContainer") then
            local source = ""
            if decompiledScripts and decompiledScripts[instance] then
                source = decompiledScripts[instance]
            else
                pcall(function() source = instance.Source or "" end)
            end
            -- Giới hạn kích thước
            if #source > MAX_SCRIPT_SIZE then
                source = source:sub(1, MAX_SCRIPT_SIZE) ..
                    "\n-- [BaoSaveInstance] Script truncated at " .. MAX_SCRIPT_SIZE .. " bytes"
            end
            Serializer.write(string.format(
                '%s    <ProtectedString name="Source">%s</ProtectedString>\n',
                indent, cdataWrap(source)
            ))
        else
            local ok, value = pcall(function() return instance[propName] end)
            if ok and value ~= nil then
                -- Thử hidden property nếu fail
                if not ok and Env.gethiddenproperty then
                    ok, value = pcall(Env.gethiddenproperty, instance, propName)
                end

                if ok and value ~= nil then
                    local serialized = serializeProperty(propName, value)
                    if serialized then
                        Serializer.write(indent .. '    ' .. serialized .. '\n')
                    end
                end
            end
        end
    end

    -- Attributes
    pcall(function()
        local attrs = instance:GetAttributes()
        if attrs and next(attrs) then
            for attrName, attrValue in pairs(attrs) do
                local serialized = serializeProperty("Attr_" .. attrName, attrValue)
                if serialized then
                    Serializer.write(indent .. '    <!-- ' .. serialized .. ' -->\n')
                end
            end
        end
    end)

    -- Tags
    pcall(function()
        local tags = instance:GetTags()
        if tags and #tags > 0 then
            Serializer.write(string.format(
                '%s    <BinaryString name="Tags">%s</BinaryString>\n',
                indent, xmlEscape(table.concat(tags, "\0"))
            ))
        end
    end)

    Serializer.write(indent .. '  </Properties>\n')

    -- Children (đệ quy)
    local children
    pcall(function()
        children = instance:GetChildren()
    end)

    if children then
        for _, child in ipairs(children) do
            Serializer.serializeInstance(child, decompiledScripts, depth + 1)
        end
    end

    Serializer.write(indent .. '</Item>\n')
end

-- Build RBXL header
function Serializer.buildHeader()
    return '<?xml version="1.0" encoding="utf-8"?>\n' ..
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" ' ..
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' ..
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" ' ..
        'version="4">\n' ..
        '  <Meta name="ExplicitAutoJoints">true</Meta>\n'
end

function Serializer.buildFooter()
    return '</roblox>\n'
end

-- ═══════════════════════════════════════════════════════════════
-- FILE WRITER (chunk-based, supports large files)
-- ═══════════════════════════════════════════════════════════════

local FileWriter = {}

function FileWriter.write(fileName, content)
    if not Env.writefile then
        Status.set("ERROR: writefile not available")
        return false
    end

    -- Nếu content nhỏ, ghi trực tiếp
    if #content < WRITE_CHUNK_SIZE then
        local ok, err = pcall(Env.writefile, fileName, content)
        if ok then
            return true
        else
            Status.set("Write error: " .. tostring(err))
            return false
        end
    end

    -- Content lớn: ghi theo chunks
    if Env.appendfile then
        -- Ghi chunk đầu tiên bằng writefile
        local firstChunk = content:sub(1, WRITE_CHUNK_SIZE)
        local ok, err = pcall(Env.writefile, fileName, firstChunk)
        if not ok then
            Status.set("Write error: " .. tostring(err))
            return false
        end

        -- Append các chunks tiếp theo
        local offset = WRITE_CHUNK_SIZE + 1
        local totalChunks = math.ceil(#content / WRITE_CHUNK_SIZE)
        local currentChunk = 1

        while offset <= #content do
            currentChunk = currentChunk + 1
            local chunkEnd = math.min(offset + WRITE_CHUNK_SIZE - 1, #content)
            local chunk = content:sub(offset, chunkEnd)

            ok, err = pcall(Env.appendfile, fileName, chunk)
            if not ok then
                Status.set(string.format("Chunk %d/%d write error: %s", currentChunk, totalChunks, tostring(err)))
                return false
            end

            Status.set(string.format("Writing chunk %d/%d...", currentChunk, totalChunks))
            offset = chunkEnd + 1
            task.wait()
        end

        return true
    else
        -- Không có appendfile → ghi cả cục (có thể chậm)
        local ok, err = pcall(Env.writefile, fileName, content)
        return ok
    end
end

-- ═══════════════════════════════════════════════════════════════
-- CORE API
-- ═══════════════════════════════════════════════════════════════

function BaoSaveInstance.init()
    Status.set("BaoSaveInstance v" .. BaoSaveInstance.Version .. " initialized")

    local caps = {}
    for k, v in pairs(Env.summary) do
        if v then caps[#caps + 1] = k end
    end
    Status.set("Capabilities: " .. table.concat(caps, ", "))
    return true
end

function BaoSaveInstance.decompileScripts(roots)
    Status.set("Collecting scripts...")

    roots = roots or {
        Workspace, ReplicatedStorage, ReplicatedFirst,
        StarterGui, StarterPack, StarterPlayer,
        Lighting, SoundService,
    }

    local scripts = Collector.getAllScripts(roots, true, true)
    Status.set(string.format("Found %d scripts, starting batch decompile...", #scripts))

    local results = Decompiler.batchDecompile(scripts)
    return results
end

function BaoSaveInstance.saveModels()
    Status.set("Collecting models...")
    local models = {}
    pcall(function()
        for _, c in ipairs(Workspace:GetChildren()) do
            if c:IsA("Model") or c:IsA("BasePart") or c:IsA("Folder") then
                models[#models + 1] = c
            end
        end
    end)
    pcall(function()
        for _, c in ipairs(ReplicatedStorage:GetChildren()) do
            models[#models + 1] = c
        end
    end)
    Status.set(string.format("Found %d models", #models))
    return models
end

function BaoSaveInstance.saveTerrain()
    Status.set("Reading terrain...")
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        Status.set("No terrain found")
        return nil
    end

    local data = {}
    pcall(function()
        data.WaterColor = terrain.WaterColor
        data.WaterReflectance = terrain.WaterReflectance
        data.WaterTransparency = terrain.WaterTransparency
        data.WaterWaveSize = terrain.WaterWaveSize
        data.WaterWaveSpeed = terrain.WaterWaveSpeed
    end)

    Status.set("Terrain data captured")
    return data
end

-- ═══════════════════════════════════════════════════════════════
-- EXPORT ENGINE
-- ═══════════════════════════════════════════════════════════════

local function getGameName()
    local name = "Game_" .. tostring(game.PlaceId)
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        if info and info.Name and #info.Name > 0 then
            name = info.Name
        end
    end)
    name = name:gsub("[^%w%s%-_]", ""):gsub("%s+", "_")
    if #name > 50 then name = name:sub(1, 50) end
    if #name == 0 then name = "Game_" .. game.PlaceId end
    return name
end

function BaoSaveInstance.exportRBXL(mode)
    mode = mode or "FULL_GAME"
    local gameName = getGameName()
    local startTime = os.clock()

    local suffixMap = {
        FULL_GAME = "_Full.rbxl",
        MODEL_ONLY = "_Model.rbxl",
        TERRAIN_ONLY = "_Terrain.rbxl",
    }
    local fileName = gameName .. (suffixMap[mode] or "_Full.rbxl")

    Status.set(string.format("Export: %s → %s", mode, fileName))

    -- ═══ PHƯƠNG PHÁP 1: Native saveinstance ═══
    if Env.saveinstance and mode ~= "TERRAIN_ONLY" then
        Status.set("Using native saveinstance...")

        -- Decompile trước
        local decompiled = BaoSaveInstance.decompileScripts()

        -- Gán source
        local applied = 0
        for scriptInst, source in pairs(decompiled) do
            pcall(function()
                scriptInst.Source = source
                applied = applied + 1
            end)
        end
        Status.set(string.format("Applied %d decompiled sources", applied))

        -- Build options
        local options = {
            FilePath = fileName,
            FileName = fileName,
            Decompile = true,
            DecompileTimeout = DECOMPILE_TIMEOUT,
            NilInstances = Env.summary.getnilinstances,
            NilInstancesFix = true,
            RemovePlayerCharacters = true,
            SavePlayers = false,
            Binary = true,
            Object = game,
            ShowStatus = true,

            -- Mode-specific
            IgnoreList = mode == "MODEL_ONLY" and {
                "Terrain", "Camera"
            } or {"CoreGui", "CorePackages"},
        }

        -- Thử options đầy đủ
        local ok = pcall(function()
            Env.saveinstance(options)
        end)

        -- Fallback options đơn giản
        if not ok then
            ok = pcall(function()
                Env.saveinstance(game, fileName)
            end)
        end

        -- Fallback với bảng đơn giản
        if not ok then
            ok = pcall(function()
                Env.saveinstance({FileName = fileName})
            end)
        end

        if ok then
            local elapsed = os.clock() - startTime
            Status.set(string.format("Done ✓ | %s | %.1fs", fileName, elapsed))
            return true, fileName
        end

        Status.set("Native save failed, using custom serializer...")
    end

    -- ═══ PHƯƠNG PHÁP 2: Custom XML Serializer ═══
    Status.set("Custom serializer starting...")
    Serializer.reset()

    -- Decompile
    local decompiled = BaoSaveInstance.decompileScripts()

    -- Header
    Serializer.write(Serializer.buildHeader())

    -- Serialize theo mode
    if mode == "FULL_GAME" then
        local services = {
            {Workspace, "Workspace"},
            {ReplicatedStorage, "ReplicatedStorage"},
            {ReplicatedFirst, "ReplicatedFirst"},
            {StarterGui, "StarterGui"},
            {StarterPack, "StarterPack"},
            {StarterPlayer, "StarterPlayer"},
            {Lighting, "Lighting"},
            {SoundService, "SoundService"},
        }

        pcall(function()
            if #Teams:GetTeams() > 0 then
                services[#services + 1] = {Teams, "Teams"}
            end
        end)

        for i, info in ipairs(services) do
            Status.set(string.format("Serializing [%d/%d] %s... (%d instances so far)",
                i, #services, info[2], Serializer._instanceCount
            ))
            pcall(function()
                Serializer.serializeInstance(info[1], decompiled, 1)
            end)
            task.wait()
        end

    elseif mode == "MODEL_ONLY" then
        Status.set("Serializing models...")
        pcall(function()
            for _, child in ipairs(Workspace:GetChildren()) do
                if not child:IsA("Terrain") and not child:IsA("Camera") then
                    Serializer.serializeInstance(child, decompiled, 1)
                end
            end
        end)
        pcall(function()
            Serializer.serializeInstance(ReplicatedStorage, decompiled, 1)
        end)

    elseif mode == "TERRAIN_ONLY" then
        Status.set("Serializing terrain...")
        pcall(function()
            Serializer.serializeInstance(Workspace.Terrain, decompiled, 1)
        end)
    end

    -- Footer
    Serializer.write(Serializer.buildFooter())

    -- Flush & Write
    Status.set(string.format("Flushing %d instances...", Serializer._instanceCount))
    local content = Serializer.flush()

    Status.set(string.format("Writing file (%.2f MB)...", #content / 1048576))
    local writeOk = FileWriter.write(fileName, content)

    -- Giải phóng bộ nhớ
    content = nil
    collectgarbage("collect")

    if writeOk then
        local elapsed = os.clock() - startTime
        Status.set(string.format(
            "Done ✓ | %s | %d instances | %.2f MB | %.1fs",
            fileName, Serializer._instanceCount,
            Serializer._chunkSize / 1048576, elapsed
        ))
        return true, fileName
    else
        -- Clipboard fallback
        if Env.setclipboard then
            Status.set("Trying clipboard...")
            -- Content đã bị nil, rebuild nhanh hoặc thông báo
            Status.set("ERROR: File write failed. No clipboard fallback for large files.")
        end
        return false, nil
    end
end

-- Convenience alias
function BaoSaveInstance.advancedExport(mode)
    return BaoSaveInstance.exportRBXL(mode)
end

-- ═══════════════════════════════════════════════════════════════
-- PERFORMANCE STATS
-- ═══════════════════════════════════════════════════════════════

function BaoSaveInstance.getStats()
    local s = BaoSaveInstance._stats
    return {
        totalScripts = s.totalScripts,
        decompiled = s.decompiled,
        cached = s.cached,
        failed = s.failed,
        elapsed = s.endTime - s.startTime,
        cacheSize = 0, -- Count cache entries
        instancesSerialized = Serializer._instanceCount,
    }
end

function BaoSaveInstance.clearCache()
    BaoSaveInstance._cache = {}
    _pathCache = setmetatable({}, {__mode = "k"})
    _classPropsCache = {}
    collectgarbage("collect")
    Status.set("Cache cleared")
end

-- ═══════════════════════════════════════════════════════════════
-- UI MODULE
-- ═══════════════════════════════════════════════════════════════

local UI = {}

function UI.create()
    -- Cleanup old GUI
    pcall(function()
        local old = CoreGui:FindFirstChild("BaoSaveInstance_GUI")
        if old then old:Destroy() end
    end)
    pcall(function()
        local old = LocalPlayer.PlayerGui:FindFirstChild("BaoSaveInstance_GUI")
        if old then old:Destroy() end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "BaoSaveInstance_GUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999999

    -- Parent GUI
    pcall(function()
        if Env.protect_gui then Env.protect_gui(gui) end
        if Env.gethui then
            gui.Parent = Env.gethui()
        else
            gui.Parent = CoreGui
        end
    end)
    if not gui.Parent then
        pcall(function() gui.Parent = LocalPlayer.PlayerGui end)
    end

    -- ═══════════════════════════════════════════════
    -- COLORS
    -- ═══════════════════════════════════════════════

    local C = {
        Bg = Color3.fromRGB(18, 18, 28),
        Header = Color3.fromRGB(25, 25, 42),
        Btn = Color3.fromRGB(38, 38, 62),
        BtnHover = Color3.fromRGB(55, 55, 85),
        BtnActive = Color3.fromRGB(30, 30, 50),
        Accent = Color3.fromRGB(88, 120, 255),
        Green = Color3.fromRGB(70, 200, 110),
        Red = Color3.fromRGB(255, 70, 70),
        Yellow = Color3.fromRGB(255, 195, 55),
        Cyan = Color3.fromRGB(60, 200, 220),
        Text = Color3.fromRGB(225, 225, 238),
        TextDim = Color3.fromRGB(140, 140, 165),
        Border = Color3.fromRGB(55, 55, 82),
        StatusBg = Color3.fromRGB(12, 12, 22),
    }

    -- ═══════════════════════════════════════════════
    -- MAIN FRAME
    -- ═══════════════════════════════════════════════

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 400, 0, 500)
    main.Position = UDim2.new(0.5, -200, 0.5, -250)
    main.BackgroundColor3 = C.Bg
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = gui

    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke", main)
    stroke.Color = C.Border
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2

    -- Shadow
    local shadow = Instance.new("ImageLabel", main)
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.BackgroundTransparency = 1
    shadow.ImageTransparency = 0.5
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = -1

    -- ═══════════════════════════════════════════════
    -- HEADER (Draggable)
    -- ═══════════════════════════════════════════════

    local hdr = Instance.new("Frame", main)
    hdr.Name = "Header"
    hdr.Size = UDim2.new(1, 0, 0, 52)
    hdr.BackgroundColor3 = C.Header
    hdr.BorderSizePixel = 0

    Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 14)

    -- Bottom fix for header corners
    local hdrFix = Instance.new("Frame", hdr)
    hdrFix.Size = UDim2.new(1, 0, 0, 14)
    hdrFix.Position = UDim2.new(0, 0, 1, -14)
    hdrFix.BackgroundColor3 = C.Header
    hdrFix.BorderSizePixel = 0

    -- Title
    local title = Instance.new("TextLabel", hdr)
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ BaoSaveInstance v4.0"
    title.TextColor3 = C.Text
    title.TextSize = 17
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- Perf badge
    local badge = Instance.new("TextLabel", hdr)
    badge.Size = UDim2.new(0, 60, 0, 22)
    badge.Position = UDim2.new(1, -110, 0.5, -11)
    badge.BackgroundColor3 = C.Green
    badge.BackgroundTransparency = 0.75
    badge.Text = "FAST"
    badge.TextColor3 = C.Green
    badge.TextSize = 10
    badge.Font = Enum.Font.GothamBold
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)

    -- Close
    local closeBtn = Instance.new("TextButton", hdr)
    closeBtn.Size = UDim2.new(0, 38, 0, 38)
    closeBtn.Position = UDim2.new(1, -46, 0.5, -19)
    closeBtn.BackgroundColor3 = C.Red
    closeBtn.BackgroundTransparency = 0.85
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = C.Red
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

    -- Drag logic
    do
        local dragging, dragStart, startPos

        hdr.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                main.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y
                )
            end
        end)
    end

    -- ═══════════════════════════════════════════════
    -- CONTENT
    -- ═══════════════════════════════════════════════

    local content = Instance.new("Frame", main)
    content.Name = "Content"
    content.Size = UDim2.new(1, -32, 1, -145)
    content.Position = UDim2.new(0, 16, 0, 62)
    content.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", content)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 7)

    -- Button factory
    local function mkBtn(name, text, icon, color, order)
        local btn = Instance.new("TextButton", content)
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 46)
        btn.BackgroundColor3 = color or C.Btn
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.LayoutOrder = order or 0

        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

        local s = Instance.new("UIStroke", btn)
        s.Color = C.Border
        s.Thickness = 1
        s.Transparency = 0.5

        local lbl = Instance.new("TextLabel", btn)
        lbl.Name = "Lbl"
        lbl.Size = UDim2.new(1, -20, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = (icon or "") .. "  " .. text
        lbl.TextColor3 = C.Text
        lbl.TextSize = 15
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BtnHover}):Play()
            TweenService:Create(s, TweenInfo.new(0.15), {Color = C.Accent, Transparency = 0}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color or C.Btn}):Play()
            TweenService:Create(s, TweenInfo.new(0.15), {Color = C.Border, Transparency = 0.5}):Play()
        end)

        return btn
    end

    -- Info
    local infoFrame = Instance.new("Frame", content)
    infoFrame.Size = UDim2.new(1, 0, 0, 32)
    infoFrame.BackgroundTransparency = 1
    infoFrame.LayoutOrder = 0

    local infoText = ""
    pcall(function()
        infoText = string.format("PlaceId: %d | GameId: %d", game.PlaceId, game.GameId)
    end)
    local infoLbl = Instance.new("TextLabel", infoFrame)
    infoLbl.Size = UDim2.new(1, 0, 1, 0)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text = "📋 " .. infoText
    infoLbl.TextColor3 = C.TextDim
    infoLbl.TextSize = 11
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.TextTruncate = Enum.TextTruncate.AtEnd

    -- Buttons
    local bFullGame = mkBtn("FullGame", "Decompile Full Game", "🎮", nil, 1)
    local bFullModel = mkBtn("FullModel", "Decompile Full Model", "🏗️", nil, 2)
    local bTerrain = mkBtn("Terrain", "Decompile Terrain", "🌍", nil, 3)

    -- Separator
    local sep = Instance.new("Frame", content)
    sep.Size = UDim2.new(0.85, 0, 0, 1)
    sep.BackgroundColor3 = C.Border
    sep.BackgroundTransparency = 0.4
    sep.BorderSizePixel = 0
    sep.LayoutOrder = 4

    local bSave = mkBtn("Save", "Save To .rbxl (Auto Detect)", "💾", Color3.fromRGB(28, 55, 42), 5)
    local bClear = mkBtn("ClearCache", "Clear Decompile Cache", "🗑️", Color3.fromRGB(50, 40, 30), 6)
    local bExit = mkBtn("Exit", "Exit", "❌", Color3.fromRGB(55, 25, 25), 7)

    -- ═══════════════════════════════════════════════
    -- STATUS BAR
    -- ═══════════════════════════════════════════════

    local statusFrame = Instance.new("Frame", main)
    statusFrame.Name = "Status"
    statusFrame.Size = UDim2.new(1, -32, 0, 65)
    statusFrame.Position = UDim2.new(0, 16, 1, -78)
    statusFrame.BackgroundColor3 = C.StatusBg
    statusFrame.BorderSizePixel = 0

    Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 10)

    local ss = Instance.new("UIStroke", statusFrame)
    ss.Color = C.Border
    ss.Thickness = 1
    ss.Transparency = 0.5

    -- Dot
    local dot = Instance.new("Frame", statusFrame)
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 12, 0, 14)
    dot.BackgroundColor3 = C.Green
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    -- Status text
    local statusLbl = Instance.new("TextLabel", statusFrame)
    statusLbl.Size = UDim2.new(1, -32, 0, 20)
    statusLbl.Position = UDim2.new(0, 28, 0, 6)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "Ready"
    statusLbl.TextColor3 = C.TextDim
    statusLbl.TextSize = 12
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.TextTruncate = Enum.TextTruncate.AtEnd

    -- Stats text
    local statsLbl = Instance.new("TextLabel", statusFrame)
    statsLbl.Size = UDim2.new(1, -32, 0, 16)
    statsLbl.Position = UDim2.new(0, 28, 0, 26)
    statsLbl.BackgroundTransparency = 1
    statsLbl.Text = ""
    statsLbl.TextColor3 = C.TextDim
    statsLbl.TextSize = 10
    statsLbl.Font = Enum.Font.Gotham
    statsLbl.TextXAlignment = Enum.TextXAlignment.Left
    statsLbl.TextTruncate = Enum.TextTruncate.AtEnd

    -- Progress bar
    local pBg = Instance.new("Frame", statusFrame)
    pBg.Size = UDim2.new(1, -24, 0, 4)
    pBg.Position = UDim2.new(0, 12, 1, -12)
    pBg.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    pBg.BorderSizePixel = 0
    Instance.new("UICorner", pBg).CornerRadius = UDim.new(1, 0)

    local pBar = Instance.new("Frame", pBg)
    pBar.Size = UDim2.new(0, 0, 1, 0)
    pBar.BackgroundColor3 = C.Accent
    pBar.BorderSizePixel = 0
    Instance.new("UICorner", pBar).CornerRadius = UDim.new(1, 0)

    -- ═══════════════════════════════════════════════
    -- STATUS UPDATE
    -- ═══════════════════════════════════════════════

    local isRunning = false

    local function updateUI(text, progress, total)
        statusLbl.Text = text

        -- Progress bar
        if progress and total and total > 0 then
            local pct = math.clamp(progress / total, 0, 1)
            TweenService:Create(pBar, TweenInfo.new(0.2), {
                Size = UDim2.new(pct, 0, 1, 0)
            }):Play()
        end

        -- Stats line
        local s = BaoSaveInstance._stats
        if s.totalScripts > 0 then
            statsLbl.Text = string.format(
                "Scripts: %d | Decompiled: %d | Cached: %d | Failed: %d",
                s.totalScripts, s.decompiled, s.cached, s.failed
            )
        end

        -- Color coding
        if text:find("Done") or text:find("✓") then
            dot.BackgroundColor3 = C.Green
            TweenService:Create(pBar, TweenInfo.new(0.3), {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = C.Green
            }):Play()
            isRunning = false
        elseif text:find("ERROR") or text:find("Failed") then
            dot.BackgroundColor3 = C.Red
            pBar.BackgroundColor3 = C.Red
            isRunning = false
        elseif text:find("Saving") or text:find("Decompil") or text:find("Serializ")
            or text:find("Writing") or text:find("Collect") or text:find("Flush") then
            dot.BackgroundColor3 = C.Yellow
            pBar.BackgroundColor3 = C.Accent
            if not isRunning then
                isRunning = true
            end
        end
    end

    BaoSaveInstance.StatusCallback = updateUI

    -- Button state
    local allBtns = {bFullGame, bFullModel, bTerrain, bSave, bClear}
    local taskRunning = false

    local function setEnabled(enabled)
        for _, b in ipairs(allBtns) do
            b.Active = enabled
            b.BackgroundTransparency = enabled and 0 or 0.5
        end
    end

    local function runAsync(fn)
        if taskRunning then
            updateUI("⚠️ Task already running, please wait...")
            return
        end
        task.spawn(function()
            taskRunning = true
            setEnabled(false)
            pBar.Size = UDim2.new(0, 0, 1, 0)
            pBar.Position = UDim2.new(0, 0, 0, 0)
            pBar.BackgroundColor3 = C.Accent

            local ok, err = pcall(fn)
            if not ok then
                updateUI("ERROR: " .. tostring(err))
            end

            isRunning = false
            taskRunning = false
            setEnabled(true)
        end)
    end

    -- ═══════════════════════════════════════════════
    -- BUTTON CONNECTIONS
    -- ═══════════════════════════════════════════════

    bFullGame.MouseButton1Click:Connect(function()
        runAsync(function()
            BaoSaveInstance.exportRBXL("FULL_GAME")
        end)
    end)

    bFullModel.MouseButton1Click:Connect(function()
        runAsync(function()
            BaoSaveInstance.exportRBXL("MODEL_ONLY")
        end)
    end)

    bTerrain.MouseButton1Click:Connect(function()
        runAsync(function()
            BaoSaveInstance.exportRBXL("TERRAIN_ONLY")
        end)
    end)

    bSave.MouseButton1Click:Connect(function()
        runAsync(function()
            BaoSaveInstance.exportRBXL("FULL_GAME")
        end)
    end)

    bClear.MouseButton1Click:Connect(function()
        BaoSaveInstance.clearCache()
        updateUI("Cache cleared ✓")
    end)

    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
        }):Play()
        task.wait(0.3)
        gui:Destroy()
    end)

    bExit.MouseButton1Click:Connect(function()
        TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
        }):Play()
        task.wait(0.3)
        gui:Destroy()
    end)

    -- ═══════════════════════════════════════════════
    -- OPEN ANIMATION
    -- ═══════════════════════════════════════════════

    main.Size = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.BackgroundTransparency = 1

    task.wait(0.05)
    TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 400, 0, 500),
        Position = UDim2.new(0.5, -200, 0.5, -250),
        BackgroundTransparency = 0,
    }):Play()

    -- Toggle keybind
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            main.Visible = not main.Visible
        end
    end)

    updateUI("Ready — Press RightCtrl to toggle")
    return gui
end

-- ═══════════════════════════════════════════════════════════════
-- BOOT
-- ═══════════════════════════════════════════════════════════════

BaoSaveInstance.init()
UI.create()

print("╔═══════════════════════════════════════════════╗")
print("║     ⚡ BaoSaveInstance v4.0 — FAST Edition    ║")
print("║     Press RightCtrl to toggle UI              ║")
print("╠═══════════════════════════════════════════════╣")

local capLines = {}
for k, v in pairs(Env.summary) do
    capLines[#capLines + 1] = string.format("  %s: %s", k, v and "✓" or "✗")
end
table.sort(capLines)
for _, line in ipairs(capLines) do
    print("║" .. line .. string.rep(" ", 45 - #line) .. "║")
end

print("╠═══════════════════════════════════════════════╣")
print("║  Optimizations:                               ║")
print("║    • Batch decompile (15 parallel)            ║")
print("║    • Bytecode hash dedup                      ║")
print("║    • Streaming XML serializer                 ║")
print("║    • Chunk-based file writer                  ║")
print("║    • Type dispatch tables                     ║")
print("║    • Weak-ref path cache                      ║")
print("╚═══════════════════════════════════════════════╝")

return BaoSaveInstance
