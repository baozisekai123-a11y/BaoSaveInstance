--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                      BaoSaveInstance v3.0                       ║
    ║           Ultimate Roblox Game Decompiler & Exporter            ║
    ║                                                                  ║
    ║  Chức năng:                                                      ║
    ║    • Decompile Game (Full Game - All in One)                      ║
    ║    • Decompile Map (Workspace objects only)                      ║
    ║    • Decompile Terrain (Voxel terrain data)                      ║
    ║    • Decompile Script (All scripts with multi-API fallback)      ║
    ║                                                                  ║
    ║  Xuất file: <TênGame> Decompile By BaoSaveInstance.rbxl          ║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

-- ═══════════════════════════════════════════════════════════════
-- MODULE DECLARATION
-- ═══════════════════════════════════════════════════════════════

local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance
BaoSaveInstance.Version = "3.0"
BaoSaveInstance.Author = "Bao"

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
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
local Chat = game:GetService("Chat")
local LocalizationService = game:GetService("LocalizationService")
local TestService = game:GetService("TestService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════════

local Config = {
    -- Yield interval: sau mỗi N instances sẽ task.wait() để tránh lag
    YieldInterval = 50,
    YieldTime = 0.03,

    -- Decompile timeout cho mỗi script (giây)
    DecompileTimeout = 10,

    -- Có hiển thị GUI không
    ShowGUI = true,

    -- Log level: 1 = minimal, 2 = normal, 3 = verbose
    LogLevel = 2,

    -- Services cần quét khi Decompile Game
    FullGameServices = {
        "Workspace",
        "Lighting",
        "ReplicatedFirst",
        "ReplicatedStorage",
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
        "SoundService",
        "Chat",
        "LocalizationService",
        "TestService",
    },

    -- Services có thể chứa script
    ScriptServices = {
        "Workspace",
        "ReplicatedFirst",
        "ReplicatedStorage",
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
        "Lighting",
        "SoundService",
        "Chat",
        "LocalizationService",
        "TestService",
    },

    -- Các class bị loại khi decompile Map (không phải part của map)
    MapExcludeClasses = {
        "Camera",
        "Player",
        "Humanoid",
        "ForceField",
        "SelectionBox",
        "SelectionSphere",
    },

    -- Tự động thử ServerScriptService và ServerStorage
    -- (thường không truy cập được từ client)
    TryServerServices = true,

    -- Nén/tối ưu output
    OptimizeOutput = true,
}

-- ═══════════════════════════════════════════════════════════════
-- STATISTICS TRACKER
-- ═══════════════════════════════════════════════════════════════

local Stats = {
    TotalInstances = 0,
    ProcessedInstances = 0,
    TotalScripts = 0,
    DecompiledScripts = 0,
    FailedScripts = 0,
    SkippedScripts = 0,
    TotalAssets = 0,
    StartTime = 0,
    EndTime = 0,
    Errors = {},
    Warnings = {},
}

local function ResetStats()
    Stats.TotalInstances = 0
    Stats.ProcessedInstances = 0
    Stats.TotalScripts = 0
    Stats.DecompiledScripts = 0
    Stats.FailedScripts = 0
    Stats.SkippedScripts = 0
    Stats.TotalAssets = 0
    Stats.StartTime = tick()
    Stats.EndTime = 0
    Stats.Errors = {}
    Stats.Warnings = {}
end

-- ═══════════════════════════════════════════════════════════════
-- LOGGING SYSTEM
-- ═══════════════════════════════════════════════════════════════

local LogHistory = {}

--- Ghi log với timestamp và level
--- @param message string
--- @param level number (1=INFO, 2=WARN, 3=ERROR, 4=SUCCESS)
function BaoSaveInstance.Log(message, level)
    level = level or 1
    local prefix = ({
        [1] = "[BaoSave INFO]",
        [2] = "[BaoSave WARN]",
        [3] = "[BaoSave ERROR]",
        [4] = "[BaoSave ✓]",
        [5] = "[BaoSave PROGRESS]",
    })[level] or "[BaoSave]"

    local timestamp = string.format("%.2f", tick() - (Stats.StartTime or tick()))
    local fullMsg = string.format("%s [%ss] %s", prefix, timestamp, message)

    table.insert(LogHistory, fullMsg)

    if level == 3 then
        warn(fullMsg)
        table.insert(Stats.Errors, message)
    elseif level == 2 then
        warn(fullMsg)
        table.insert(Stats.Warnings, message)
    else
        print(fullMsg)
    end

    -- Cập nhật GUI log nếu có
    if BaoSaveInstance._UpdateGUILog then
        pcall(BaoSaveInstance._UpdateGUILog, fullMsg, level)
    end
end

local Log = BaoSaveInstance.Log

-- ═══════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

--- Lấy tên game an toàn
function BaoSaveInstance.GetGameName()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)

    if success and info and info.Name then
        return info.Name
    end

    -- Fallback: dùng PlaceId
    Log("Không lấy được tên game từ MarketplaceService, dùng PlaceId", 2)
    return "Game_" .. tostring(game.PlaceId)
end

--- Loại bỏ ký tự không hợp lệ trong tên file
--- Thay thế / \ : * ? " < > | bằng _
function BaoSaveInstance.SanitizeFileName(name)
    if not name or name == "" then
        return "Unknown_Game"
    end

    -- Thay thế các ký tự không hợp lệ
    local sanitized = name:gsub('[/\\:*?"<>|%c]', '_')

    -- Loại bỏ khoảng trắng đầu/cuối
    sanitized = sanitized:match("^%s*(.-)%s*$")

    -- Giới hạn độ dài tên file (tránh lỗi filesystem)
    if #sanitized > 100 then
        sanitized = sanitized:sub(1, 100)
    end

    -- Nếu rỗng sau khi sanitize
    if sanitized == "" then
        sanitized = "Unknown_Game"
    end

    return sanitized
end

--- Tạo tên file output theo format yêu cầu
--- @param suffix string|nil Hậu tố thêm (ví dụ: "Map", "Terrain", "Script")
--- @return string
function BaoSaveInstance.BuildFileName(suffix)
    local gameName = BaoSaveInstance.SanitizeFileName(BaoSaveInstance.GetGameName())

    if suffix and suffix ~= "" then
        return gameName .. " " .. suffix .. " Decompile By BaoSaveInstance.rbxl"
    else
        return gameName .. " Decompile By BaoSaveInstance.rbxl"
    end
end

--- Đếm tổng số Instance trong một tree
local function CountDescendants(root)
    local count = 0
    local success, err = pcall(function()
        count = #root:GetDescendants()
    end)
    if not success then
        -- Fallback: đếm thủ công
        local function recurse(obj)
            count = count + 1
            local ok, children = pcall(function() return obj:GetChildren() end)
            if ok and children then
                for _, child in ipairs(children) do
                    recurse(child)
                end
            end
        end
        pcall(function() recurse(root) end)
    end
    return count
end

--- Yield an toàn để tránh block main thread
local yieldCounter = 0
local function SafeYield()
    yieldCounter = yieldCounter + 1
    if yieldCounter >= Config.YieldInterval then
        yieldCounter = 0
        task.wait(Config.YieldTime)
    end
end

--- Force yield
local function ForceYield()
    yieldCounter = 0
    task.wait(Config.YieldTime)
end

--- Kiểm tra một instance có phải script không
local function IsScript(instance)
    return instance:IsA("LocalScript")
        or instance:IsA("Script")
        or instance:IsA("ModuleScript")
end

--- Lấy full path của instance (để log)
local function GetFullPath(instance)
    local parts = {}
    local current = instance
    while current and current ~= game do
        table.insert(parts, 1, current.Name)
        current = current.Parent
    end
    return "game." .. table.concat(parts, ".")
end

-- ═══════════════════════════════════════════════════════════════
-- EXPLOIT ENVIRONMENT DETECTION
-- Phát hiện các hàm exploit có sẵn trong môi trường
-- ═══════════════════════════════════════════════════════════════

local ExploitEnv = {
    -- Các hàm decompile có thể có
    decompile = nil,
    getscripthash = nil,
    getscriptbytecode = nil,
    dumpstring = nil,

    -- Hàm lưu file
    writefile = nil,
    appendfile = nil,
    readfile = nil,
    isfile = nil,
    isfolder = nil,
    makefolder = nil,

    -- Hàm saveinstance
    saveinstance = nil,
    save_instance = nil,

    -- Hàm khác
    gethiddenproperty = nil,
    sethiddenproperty = nil,
    getinstances = nil,
    getnilinstances = nil,
    getloadedmodules = nil,
    getrunningscripts = nil,
    getscriptclosure = nil,
    hookfunction = nil,
    newcclosure = nil,
    iscclosure = nil,

    -- Clipboard
    setclipboard = nil,
    toclipboard = nil,

    -- HTTP
    request = nil,
    http_request = nil,
    syn_request = nil,

    -- Executor name
    identifyexecutor = nil,
    ExecutorName = "Unknown",
}

--- Phát hiện môi trường exploit
local function DetectEnvironment()
    Log("Đang phát hiện môi trường exploit...", 1)

    -- Decompile functions
    ExploitEnv.decompile = (typeof(decompile) == "function" and decompile)
        or (typeof(getfenv) == "function" and getfenv().decompile)
        or nil

    -- Bytecode functions
    if typeof(getscriptbytecode) == "function" then
        ExploitEnv.getscriptbytecode = getscriptbytecode
    elseif typeof(dumpstring) == "function" then
        ExploitEnv.getscriptbytecode = dumpstring
    end

    if typeof(getscripthash) == "function" then
        ExploitEnv.getscripthash = getscripthash
    end

    -- File functions
    ExploitEnv.writefile = typeof(writefile) == "function" and writefile or nil
    ExploitEnv.appendfile = typeof(appendfile) == "function" and appendfile or nil
    ExploitEnv.readfile = typeof(readfile) == "function" and readfile or nil
    ExploitEnv.isfile = typeof(isfile) == "function" and isfile or nil
    ExploitEnv.isfolder = typeof(isfolder) == "function" and isfolder or nil
    ExploitEnv.makefolder = typeof(makefolder) == "function" and makefolder or nil

    -- Saveinstance functions
    ExploitEnv.saveinstance = typeof(saveinstance) == "function" and saveinstance
        or typeof(save_instance) == "function" and save_instance
        or nil

    -- Hidden properties
    ExploitEnv.gethiddenproperty = typeof(gethiddenproperty) == "function"
        and gethiddenproperty or nil
    ExploitEnv.sethiddenproperty = typeof(sethiddenproperty) == "function"
        and sethiddenproperty or nil

    -- Instance enumeration
    ExploitEnv.getinstances = typeof(getinstances) == "function"
        and getinstances or nil
    ExploitEnv.getnilinstances = typeof(getnilinstances) == "function"
        and getnilinstances or nil
    ExploitEnv.getloadedmodules = typeof(getloadedmodules) == "function"
        and getloadedmodules or nil
    ExploitEnv.getrunningscripts = typeof(getrunningscripts) == "function"
        and getrunningscripts or nil

    -- Clipboard
    ExploitEnv.setclipboard = typeof(setclipboard) == "function" and setclipboard
        or typeof(toclipboard) == "function" and toclipboard
        or nil

    -- HTTP
    ExploitEnv.request = typeof(request) == "function" and request
        or typeof(http_request) == "function" and http_request
        or (typeof(syn) == "table" and typeof(syn.request) == "function" and syn.request)
        or (typeof(http) == "table" and typeof(http.request) == "function" and http.request)
        or nil

    -- Executor identification
    if typeof(identifyexecutor) == "function" then
        local ok, name = pcall(identifyexecutor)
        if ok then
            ExploitEnv.ExecutorName = name or "Unknown"
        end
    elseif typeof(getexecutorname) == "function" then
        local ok, name = pcall(getexecutorname)
        if ok then
            ExploitEnv.ExecutorName = name or "Unknown"
        end
    end

    -- Log kết quả phát hiện
    Log("Executor: " .. ExploitEnv.ExecutorName, 1)
    Log("decompile(): " .. (ExploitEnv.decompile and "✓" or "✗"), 1)
    Log("getscriptbytecode(): " .. (ExploitEnv.getscriptbytecode and "✓" or "✗"), 1)
    Log("writefile(): " .. (ExploitEnv.writefile and "✓" or "✗"), 1)
    Log("saveinstance(): " .. (ExploitEnv.saveinstance and "✓" or "✗"), 1)
    Log("gethiddenproperty(): " .. (ExploitEnv.gethiddenproperty and "✓" or "✗"), 1)
    Log("getnilinstances(): " .. (ExploitEnv.getnilinstances and "✓" or "✗"), 1)
    Log("getloadedmodules(): " .. (ExploitEnv.getloadedmodules and "✓" or "✗"), 1)
    Log("HTTP request(): " .. (ExploitEnv.request and "✓" or "✗"), 1)
end

-- ═══════════════════════════════════════════════════════════════
-- MULTI-API DECOMPILER ENGINE
-- Hệ thống decompile đa engine với fallback tự động
-- ═══════════════════════════════════════════════════════════════

local DecompilerEngines = {}

--- Engine 1: Direct decompile() function (Synapse X, Script-Ware, etc.)
DecompilerEngines[1] = {
    Name = "Direct Decompile",
    Priority = 1,
    Available = false,

    Init = function(self)
        self.Available = ExploitEnv.decompile ~= nil
        return self.Available
    end,

    Decompile = function(self, scriptInstance)
        if not self.Available then return nil, "Not available" end

        local ok, source = pcall(ExploitEnv.decompile, scriptInstance)
        if ok and source and typeof(source) == "string" and #source > 0 then
            -- Kiểm tra xem có phải là error message không
            if source:find("^%-%-") and source:find("failed") then
                return nil, "Decompile returned error: " .. source:sub(1, 100)
            end
            return source, nil
        end
        return nil, ok and "Empty result" or tostring(source)
    end,
}

--- Engine 2: Bytecode → HTTP API decompile
--- Gửi bytecode lên server decompile online (nếu có)
DecompilerEngines[2] = {
    Name = "Bytecode HTTP Decompile (Unluac)",
    Priority = 2,
    Available = false,
    Endpoints = {
        "https://unluac.com/api/decompile",
        "https://luadec.metaflare.net/api/decompile",
        "https://decompiler.baotools.dev/api/v1/decompile",
    },

    Init = function(self)
        self.Available = ExploitEnv.getscriptbytecode ~= nil
            and ExploitEnv.request ~= nil
        return self.Available
    end,

    Decompile = function(self, scriptInstance)
        if not self.Available then return nil, "Not available" end

        -- Lấy bytecode
        local ok, bytecode = pcall(ExploitEnv.getscriptbytecode, scriptInstance)
        if not ok or not bytecode or #bytecode == 0 then
            return nil, "Failed to get bytecode: " .. tostring(bytecode)
        end

        -- Thử từng endpoint
        for _, endpoint in ipairs(self.Endpoints) do
            local reqOk, response = pcall(function()
                return ExploitEnv.request({
                    Url = endpoint,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/octet-stream",
                        ["User-Agent"] = "BaoSaveInstance/3.0",
                        ["X-Script-Name"] = scriptInstance.Name,
                    },
                    Body = bytecode,
                    Timeout = Config.DecompileTimeout,
                })
            end)

            if reqOk and response and response.StatusCode == 200 then
                local body = response.Body
                if body and #body > 10 then
                    return body, nil
                end
            end
        end

        return nil, "All HTTP endpoints failed"
    end,
}

--- Engine 3: Bytecode → Local Luau decompile attempt
--- Cố gắng reconstruct basic structure từ bytecode
DecompilerEngines[3] = {
    Name = "Bytecode Local Reconstruct",
    Priority = 3,
    Available = false,

    Init = function(self)
        self.Available = ExploitEnv.getscriptbytecode ~= nil
        return self.Available
    end,

    Decompile = function(self, scriptInstance)
        if not self.Available then return nil, "Not available" end

        local ok, bytecode = pcall(ExploitEnv.getscriptbytecode, scriptInstance)
        if not ok or not bytecode or #bytecode == 0 then
            return nil, "Failed to get bytecode"
        end

        -- Cố gắng trích xuất string constants từ bytecode
        -- Đây là phương pháp cơ bản nhất - chỉ lấy được strings
        local strings = {}
        local requires = {}
        local functionCount = 0

        -- Tìm string patterns trong bytecode
        local i = 1
        while i <= #bytecode do
            -- Tìm chuỗi có thể đọc được
            local start = i
            local readable = {}
            while i <= #bytecode do
                local byte = bytecode:byte(i)
                if byte >= 32 and byte <= 126 then
                    table.insert(readable, string.char(byte))
                    i = i + 1
                else
                    break
                end
            end

            if #readable >= 4 then -- Chỉ lấy chuỗi từ 4 ký tự trở lên
                local str = table.concat(readable)
                table.insert(strings, str)

                -- Phát hiện require patterns
                if str:find("require") then
                    table.insert(requires, str)
                end
            end

            i = i + 1
        end

        -- Tạo pseudo-source với thông tin có được
        local lines = {
            "-- BaoSaveInstance: Bytecode Reconstruction (Partial)",
            "-- Script: " .. GetFullPath(scriptInstance),
            "-- Class: " .. scriptInstance.ClassName,
            "-- Bytecode size: " .. #bytecode .. " bytes",
            "-- Extracted " .. #strings .. " string constants",
            "",
            "--[[ String Constants Found:",
        }

        for idx, str in ipairs(strings) do
            if idx <= 200 then -- Giới hạn
                table.insert(lines, "--   [" .. idx .. "] = " .. string.format("%q", str))
            end
        end

        table.insert(lines, "--]]")
        table.insert(lines, "")

        if #requires > 0 then
            table.insert(lines, "-- Detected require() calls:")
            for _, req in ipairs(requires) do
                table.insert(lines, "-- " .. req)
            end
            table.insert(lines, "")
        end

        table.insert(lines, "-- Full decompilation requires a proper Luau decompiler")
        table.insert(lines, "-- Bytecode hash: " .. (
            ExploitEnv.getscripthash
            and (pcall(ExploitEnv.getscripthash, scriptInstance) and tostring(select(2, pcall(ExploitEnv.getscripthash, scriptInstance))) or "N/A")
            or "N/A"
        ))

        return table.concat(lines, "\n"), nil
    end,
}

--- Engine 4: getscriptclosure + debug library
DecompilerEngines[4] = {
    Name = "Closure Debug Decompile",
    Priority = 4,
    Available = false,

    Init = function(self)
        self.Available = typeof(debug) == "table"
            and typeof(debug.getinfo) == "function"
        return self.Available
    end,

    Decompile = function(self, scriptInstance)
        if not self.Available then return nil, "Not available" end

        -- Cố gắng lấy thông tin qua debug library
        local lines = {
            "-- BaoSaveInstance: Debug Info Reconstruction",
            "-- Script: " .. GetFullPath(scriptInstance),
            "-- Class: " .. scriptInstance.ClassName,
            "",
        }

        -- Thử lấy source từ property trực tiếp
        local srcOk, src = pcall(function()
            return scriptInstance.Source
        end)
        if srcOk and src and #src > 0 then
            return src, nil
        end

        -- Thử dùng gethiddenproperty
        if ExploitEnv.gethiddenproperty then
            local hOk, hSrc = pcall(ExploitEnv.gethiddenproperty, scriptInstance, "Source")
            if hOk and hSrc and typeof(hSrc) == "string" and #hSrc > 0 then
                return hSrc, nil
            end
        end

        return nil, "Could not extract source via debug methods"
    end,
}

--- Engine 5: Source property direct access (cho ModuleScript hoặc unprotected scripts)
DecompilerEngines[5] = {
    Name = "Direct Source Access",
    Priority = 0, -- Ưu tiên cao nhất
    Available = true,

    Init = function(self)
        self.Available = true
        return true
    end,

    Decompile = function(self, scriptInstance)
        -- Thử đọc .Source trực tiếp
        local ok, source = pcall(function()
            return scriptInstance.Source
        end)
        if ok and source and typeof(source) == "string" and #source > 0 then
            return source, nil
        end

        -- Thử gethiddenproperty
        if ExploitEnv.gethiddenproperty then
            local hOk, hSrc = pcall(
                ExploitEnv.gethiddenproperty, scriptInstance, "Source"
            )
            if hOk and hSrc and typeof(hSrc) == "string" and #hSrc > 0 then
                return hSrc, nil
            end
        end

        return nil, "Source property not accessible"
    end,
}

--- Khởi tạo tất cả engines
local function InitDecompilers()
    Log("Khởi tạo Decompiler Engines...", 1)
    local available = 0

    for i, engine in ipairs(DecompilerEngines) do
        local ok, result = pcall(function()
            return engine:Init()
        end)
        if ok and result then
            available = available + 1
            Log("  Engine " .. i .. " [" .. engine.Name .. "]: ✓ Available", 1)
        else
            Log("  Engine " .. i .. " [" .. engine.Name .. "]: ✗ Unavailable", 1)
        end
    end

    Log(available .. "/" .. #DecompilerEngines .. " decompiler engines available", 4)
    return available
end

--- Sắp xếp engines theo priority (số nhỏ = ưu tiên cao)
local function GetSortedEngines()
    local sorted = {}
    for _, engine in ipairs(DecompilerEngines) do
        if engine.Available then
            table.insert(sorted, engine)
        end
    end
    table.sort(sorted, function(a, b) return a.Priority < b.Priority end)
    return sorted
end

-- ═══════════════════════════════════════════════════════════════
-- SCRIPT DECOMPILER (Multi-API with Fallback)
-- ═══════════════════════════════════════════════════════════════

--- Thử decompile một script bằng nhiều engine
--- @param scriptInstance Instance (Script/LocalScript/ModuleScript)
--- @return string|nil source, string|nil engineUsed
function BaoSaveInstance.TryDecompileScript(scriptInstance)
    if not scriptInstance or not IsScript(scriptInstance) then
        return nil, nil
    end

    local sortedEngines = GetSortedEngines()
    local allErrors = {}
    local bestResult = nil
    local bestResultLength = 0
    local bestEngineName = nil

    for _, engine in ipairs(sortedEngines) do
        local ok, source, err = pcall(function()
            return engine:Decompile(scriptInstance)
        end)

        if ok and source and typeof(source) == "string" and #source > 0 then
            -- Kiểm tra chất lượng: source dài hơn = tốt hơn
            if #source > bestResultLength then
                bestResult = source
                bestResultLength = #source
                bestEngineName = engine.Name

                -- Nếu source đủ tốt (không chỉ là comments), dừng lại
                local nonCommentLines = 0
                for line in source:gmatch("[^\n]+") do
                    local trimmed = line:match("^%s*(.-)%s*$")
                    if trimmed and #trimmed > 0
                        and not trimmed:match("^%-%-") then
                        nonCommentLines = nonCommentLines + 1
                    end
                end

                if nonCommentLines >= 3 then
                    -- Source có ít nhất 3 dòng code thực, đủ tốt
                    if Config.LogLevel >= 3 then
                        Log("  Decompiled with " .. engine.Name
                            .. " (" .. #source .. " chars)", 1)
                    end
                    return bestResult, bestEngineName
                end
            end
        else
            local errMsg = (ok and err) or (not ok and tostring(source)) or "Unknown error"
            table.insert(allErrors, engine.Name .. ": " .. errMsg)
        end

        SafeYield()
    end

    -- Trả về kết quả tốt nhất có được (dù có thể chỉ là partial)
    if bestResult then
        return bestResult, bestEngineName
    end

    -- Tất cả engine đều thất bại - tạo placeholder
    local placeholder = string.format(
        "-- BaoSaveInstance: Decompile Failed\n"
        .. "-- Script: %s\n"
        .. "-- Class: %s\n"
        .. "-- Errors:\n",
        GetFullPath(scriptInstance),
        scriptInstance.ClassName
    )
    for _, errMsg in ipairs(allErrors) do
        placeholder = placeholder .. "--   " .. errMsg .. "\n"
    end
    placeholder = placeholder .. "\n-- Script could not be decompiled with any available engine.\n"

    return placeholder, "FAILED"
end

-- ═══════════════════════════════════════════════════════════════
-- INSTANCE SCANNER
-- Quét và thu thập instances từ game
-- ═══════════════════════════════════════════════════════════════

--- Thu thập tất cả script trong game
--- @return table scripts Danh sách {instance, path}
local function CollectAllScripts()
    Log("Đang quét tất cả Scripts trong game...", 5)
    local scripts = {}
    local visited = {}

    -- Quét từ các services
    for _, serviceName in ipairs(Config.ScriptServices) do
        local ok, service = pcall(function()
            return game:GetService(serviceName)
        end)
        if ok and service then
            local descendants = {}
            pcall(function()
                descendants = service:GetDescendants()
            end)

            for _, desc in ipairs(descendants) do
                if IsScript(desc) and not visited[desc] then
                    visited[desc] = true
                    table.insert(scripts, {
                        Instance = desc,
                        Path = GetFullPath(desc),
                        Service = serviceName,
                    })
                end
                SafeYield()
            end
        end
    end

    -- Thử quét ServerScriptService và ServerStorage
    if Config.TryServerServices then
        for _, sName in ipairs({"ServerScriptService", "ServerStorage"}) do
            local ok, service = pcall(function()
                return game:GetService(sName)
            end)
            if ok and service then
                local descendants = {}
                pcall(function()
                    descendants = service:GetDescendants()
                end)
                for _, desc in ipairs(descendants) do
                    if IsScript(desc) and not visited[desc] then
                        visited[desc] = true
                        table.insert(scripts, {
                            Instance = desc,
                            Path = GetFullPath(desc),
                            Service = sName,
                        })
                    end
                    SafeYield()
                end
            end
        end
    end

    -- Quét nil instances (nếu có)
    if ExploitEnv.getnilinstances then
        local ok, nilInstances = pcall(ExploitEnv.getnilinstances)
        if ok and nilInstances then
            for _, inst in ipairs(nilInstances) do
                if IsScript(inst) and not visited[inst] then
                    visited[inst] = true
                    table.insert(scripts, {
                        Instance = inst,
                        Path = "nil." .. inst.Name,
                        Service = "Nil",
                    })
                end
            end
        end
    end

    -- Quét loaded modules (nếu có)
    if ExploitEnv.getloadedmodules then
        local ok, modules = pcall(ExploitEnv.getloadedmodules)
        if ok and modules then
            for _, mod in ipairs(modules) do
                if not visited[mod] then
                    visited[mod] = true
                    table.insert(scripts, {
                        Instance = mod,
                        Path = GetFullPath(mod),
                        Service = "LoadedModules",
                    })
                end
            end
        end
    end

    Log("Tìm thấy " .. #scripts .. " scripts", 4)
    return scripts
end

-- ═══════════════════════════════════════════════════════════════
-- RBXL/RBXLX SERIALIZER
-- Tạo file .rbxlx (XML format) từ Instance tree
-- ═══════════════════════════════════════════════════════════════

local Serializer = {}

--- Escape XML special characters
local function XmlEscape(str)
    if not str then return "" end
    str = str:gsub("&", "&amp;")
    str = str:gsub("<", "&lt;")
    str = str:gsub(">", "&gt;")
    str = str:gsub('"', "&quot;")
    str = str:gsub("'", "&apos;")
    return str
end

--- Tạo unique referent ID
local _refCounter = 0
local function NextRef()
    _refCounter = _refCounter + 1
    return "RBX" .. string.format("%08X", _refCounter)
end

--- Serialize một property value thành XML
local function SerializeProperty(name, value, propType)
    if value == nil then return "" end

    local lines = {}

    if propType == "string" or typeof(value) == "string" then
        table.insert(lines, '<string name="' .. XmlEscape(name) .. '">'
            .. XmlEscape(tostring(value)) .. '</string>')

    elseif propType == "ProtectedString" then
        table.insert(lines, '<ProtectedString name="' .. XmlEscape(name) .. '">'
            .. '<![CDATA[' .. tostring(value) .. ']]>'
            .. '</ProtectedString>')

    elseif propType == "bool" or typeof(value) == "boolean" then
        table.insert(lines, '<bool name="' .. XmlEscape(name) .. '">'
            .. tostring(value) .. '</bool>')

    elseif propType == "int" or propType == "int64" then
        table.insert(lines, '<int name="' .. XmlEscape(name) .. '">'
            .. tostring(math.floor(tonumber(value) or 0)) .. '</int>')

    elseif propType == "float" or propType == "double"
        or typeof(value) == "number" then
        table.insert(lines, '<float name="' .. XmlEscape(name) .. '">'
            .. tostring(value) .. '</float>')

    elseif typeof(value) == "Vector3" then
        table.insert(lines, '<Vector3 name="' .. XmlEscape(name) .. '">')
        table.insert(lines, '  <X>' .. value.X .. '</X>')
        table.insert(lines, '  <Y>' .. value.Y .. '</Y>')
        table.insert(lines, '  <Z>' .. value.Z .. '</Z>')
        table.insert(lines, '</Vector3>')

    elseif typeof(value) == "CFrame" then
        local components = {value:GetComponents()}
        table.insert(lines, '<CoordinateFrame name="' .. XmlEscape(name) .. '">')
        local cNames = {"X","Y","Z","R00","R01","R02","R10","R11","R12","R20","R21","R22"}
        for i, cName in ipairs(cNames) do
            if components[i] then
                table.insert(lines, '  <' .. cName .. '>'
                    .. components[i] .. '</' .. cName .. '>')
            end
        end
        table.insert(lines, '</CoordinateFrame>')

    elseif typeof(value) == "Color3" then
        -- Encode as uint32
        local r = math.floor(value.R * 255)
        local g = math.floor(value.G * 255)
        local b = math.floor(value.B * 255)
        local encoded = 0xFF000000 + r * 0x10000 + g * 0x100 + b
        table.insert(lines, '<Color3uint8 name="' .. XmlEscape(name) .. '">'
            .. tostring(encoded) .. '</Color3uint8>')

    elseif typeof(value) == "BrickColor" then
        table.insert(lines, '<int name="' .. XmlEscape(name) .. '">'
            .. tostring(value.Number) .. '</int>')

    elseif typeof(value) == "UDim" then
        table.insert(lines, '<UDim name="' .. XmlEscape(name) .. '">')
        table.insert(lines, '  <S>' .. value.Scale .. '</S>')
        table.insert(lines, '  <O>' .. value.Offset .. '</O>')
        table.insert(lines, '</UDim>')

    elseif typeof(value) == "UDim2" then
        table.insert(lines, '<UDim2 name="' .. XmlEscape(name) .. '">')
        table.insert(lines, '  <XS>' .. value.X.Scale .. '</XS>')
        table.insert(lines, '  <XO>' .. value.X.Offset .. '</XO>')
        table.insert(lines, '  <YS>' .. value.Y.Scale .. '</YS>')
        table.insert(lines, '  <YO>' .. value.Y.Offset .. '</YO>')
        table.insert(lines, '</UDim2>')

    elseif typeof(value) == "Vector2" then
        table.insert(lines, '<Vector2 name="' .. XmlEscape(name) .. '">')
        table.insert(lines, '  <X>' .. value.X .. '</X>')
        table.insert(lines, '  <Y>' .. value.Y .. '</Y>')
        table.insert(lines, '</Vector2>')

    elseif typeof(value) == "Rect" then
        table.insert(lines, '<Rect2D name="' .. XmlEscape(name) .. '">')
        table.insert(lines, '  <min><X>' .. value.Min.X .. '</X><Y>'
            .. value.Min.Y .. '</Y></min>')
        table.insert(lines, '  <max><X>' .. value.Max.X .. '</X><Y>'
            .. value.Max.Y .. '</Y></max>')
        table.insert(lines, '</Rect2D>')

    elseif typeof(value) == "EnumItem" then
        table.insert(lines, '<token name="' .. XmlEscape(name) .. '">'
            .. tostring(value.Value) .. '</token>')

    elseif typeof(value) == "NumberSequence" then
        table.insert(lines, '<NumberSequence name="' .. XmlEscape(name) .. '">')
        for _, kp in ipairs(value.Keypoints) do
            table.insert(lines, kp.Time .. ' ' .. kp.Value .. ' ' .. kp.Envelope .. ' ')
        end
        table.insert(lines, '</NumberSequence>')

    elseif typeof(value) == "ColorSequence" then
        table.insert(lines, '<ColorSequence name="' .. XmlEscape(name) .. '">')
        for _, kp in ipairs(value.Keypoints) do
            table.insert(lines, kp.Time .. ' '
                .. kp.Value.R .. ' ' .. kp.Value.G .. ' ' .. kp.Value.B .. ' 0 ')
        end
        table.insert(lines, '</ColorSequence>')

    elseif typeof(value) == "Instance" then
        -- Reference to another instance
        table.insert(lines, '<Ref name="' .. XmlEscape(name) .. '">null</Ref>')

    else
        -- Fallback: convert to string
        local ok, str = pcall(tostring, value)
        if ok then
            table.insert(lines, '<string name="' .. XmlEscape(name) .. '">'
                .. XmlEscape(str) .. '</string>')
        end
    end

    return table.concat(lines, "\n")
end

--- Danh sách properties quan trọng theo ClassName
local ClassProperties = {
    -- BasePart properties
    BasePart = {
        {"Name", "string"},
        {"Position", "Vector3"},
        {"Size", "Vector3"},
        {"CFrame", "CFrame"},
        {"Anchored", "bool"},
        {"CanCollide", "bool"},
        {"Transparency", "float"},
        {"Color", "Color3"},
        {"Material", "Enum"},
        {"Reflectance", "float"},
        {"Locked", "bool"},
        {"Archivable", "bool"},
        {"CastShadow", "bool"},
        {"Massless", "bool"},
    },

    Part = "BasePart",
    WedgePart = "BasePart",
    CornerWedgePart = "BasePart",
    TrussPart = "BasePart",

    MeshPart = {
        {"Name", "string"},
        {"Position", "Vector3"},
        {"Size", "Vector3"},
        {"CFrame", "CFrame"},
        {"Anchored", "bool"},
        {"CanCollide", "bool"},
        {"Transparency", "float"},
        {"Color", "Color3"},
        {"Material", "Enum"},
        {"MeshId", "string"},
        {"TextureID", "string"},
        {"Locked", "bool"},
    },

    UnionOperation = {
        {"Name", "string"},
        {"Position", "Vector3"},
        {"Size", "Vector3"},
        {"CFrame", "CFrame"},
        {"Anchored", "bool"},
        {"CanCollide", "bool"},
        {"Transparency", "float"},
        {"Color", "Color3"},
        {"Material", "Enum"},
        {"UsePartColor", "bool"},
        {"Locked", "bool"},
    },

    Model = {
        {"Name", "string"},
    },

    Folder = {
        {"Name", "string"},
    },

    SpawnLocation = {
        {"Name", "string"},
        {"Position", "Vector3"},
        {"Size", "Vector3"},
        {"CFrame", "CFrame"},
        {"Anchored", "bool"},
        {"CanCollide", "bool"},
        {"Transparency", "float"},
        {"Color", "Color3"},
        {"Material", "Enum"},
        {"Duration", "float"},
        {"Enabled", "bool"},
        {"Neutral", "bool"},
        {"TeamColor", "BrickColor"},
    },

    Decal = {
        {"Name", "string"},
        {"Texture", "string"},
        {"Transparency", "float"},
        {"Face", "Enum"},
        {"Color3", "Color3"},
    },

    Texture = {
        {"Name", "string"},
        {"Texture", "string"},
        {"Transparency", "float"},
        {"Face", "Enum"},
        {"StudsPerTileU", "float"},
        {"StudsPerTileV", "float"},
    },

    SpecialMesh = {
        {"Name", "string"},
        {"MeshId", "string"},
        {"TextureId", "string"},
        {"Scale", "Vector3"},
        {"Offset", "Vector3"},
        {"MeshType", "Enum"},
    },

    PointLight = {
        {"Name", "string"},
        {"Color", "Color3"},
        {"Brightness", "float"},
        {"Range", "float"},
        {"Enabled", "bool"},
        {"Shadows", "bool"},
    },

    SpotLight = {
        {"Name", "string"},
        {"Color", "Color3"},
        {"Brightness", "float"},
        {"Range", "float"},
        {"Angle", "float"},
        {"Face", "Enum"},
        {"Enabled", "bool"},
        {"Shadows", "bool"},
    },

    SurfaceLight = {
        {"Name", "string"},
        {"Color", "Color3"},
        {"Brightness", "float"},
        {"Range", "float"},
        {"Angle", "float"},
        {"Face", "Enum"},
        {"Enabled", "bool"},
        {"Shadows", "bool"},
    },

    Fire = {
        {"Name", "string"},
        {"Color", "Color3"},
        {"SecondaryColor", "Color3"},
        {"Size", "float"},
        {"Heat", "float"},
        {"Enabled", "bool"},
    },

    Smoke = {
        {"Name", "string"},
        {"Color", "Color3"},
        {"Opacity", "float"},
        {"Size", "float"},
        {"RiseVelocity", "float"},
        {"Enabled", "bool"},
    },

    ParticleEmitter = {
        {"Name", "string"},
        {"Texture", "string"},
        {"Color", "ColorSequence"},
        {"Size", "NumberSequence"},
        {"Transparency", "NumberSequence"},
        {"Rate", "float"},
        {"Lifetime", "NumberRange"},
        {"Speed", "NumberRange"},
        {"Enabled", "bool"},
    },

    Sound = {
        {"Name", "string"},
        {"SoundId", "string"},
        {"Volume", "float"},
        {"Pitch", "float"},
        {"Looped", "bool"},
        {"Playing", "bool"},
        {"PlaybackSpeed", "float"},
    },

    Script = {
        {"Name", "string"},
        {"Source", "ProtectedString"},
        {"Disabled", "bool"},
    },

    LocalScript = {
        {"Name", "string"},
        {"Source", "ProtectedString"},
        {"Disabled", "bool"},
    },

    ModuleScript = {
        {"Name", "string"},
        {"Source", "ProtectedString"},
    },

    ScreenGui = {
        {"Name", "string"},
        {"Enabled", "bool"},
        {"ResetOnSpawn", "bool"},
        {"IgnoreGuiInset", "bool"},
        {"DisplayOrder", "int"},
        {"ZIndexBehavior", "Enum"},
    },

    Frame = {
        {"Name", "string"},
        {"Position", "UDim2"},
        {"Size", "UDim2"},
        {"AnchorPoint", "Vector2"},
        {"BackgroundColor3", "Color3"},
        {"BackgroundTransparency", "float"},
        {"BorderSizePixel", "int"},
        {"BorderColor3", "Color3"},
        {"Visible", "bool"},
        {"ZIndex", "int"},
        {"LayoutOrder", "int"},
        {"ClipsDescendants", "bool"},
    },

    TextLabel = {
        {"Name", "string"},
        {"Position", "UDim2"},
        {"Size", "UDim2"},
        {"AnchorPoint", "Vector2"},
        {"Text", "string"},
        {"TextColor3", "Color3"},
        {"TextSize", "float"},
        {"Font", "Enum"},
        {"BackgroundColor3", "Color3"},
        {"BackgroundTransparency", "float"},
        {"TextWrapped", "bool"},
        {"TextScaled", "bool"},
        {"Visible", "bool"},
        {"ZIndex", "int"},
    },

    TextButton = {
        {"Name", "string"},
        {"Position", "UDim2"},
        {"Size", "UDim2"},
        {"AnchorPoint", "Vector2"},
        {"Text", "string"},
        {"TextColor3", "Color3"},
        {"TextSize", "float"},
        {"Font", "Enum"},
        {"BackgroundColor3", "Color3"},
        {"BackgroundTransparency", "float"},
        {"Visible", "bool"},
        {"ZIndex", "int"},
        {"AutoButtonColor", "bool"},
    },

    TextBox = {
        {"Name", "string"},
        {"Position", "UDim2"},
        {"Size", "UDim2"},
        {"AnchorPoint", "Vector2"},
        {"Text", "string"},
        {"PlaceholderText", "string"},
        {"TextColor3", "Color3"},
        {"TextSize", "float"},
        {"Font", "Enum"},
        {"BackgroundColor3", "Color3"},
        {"BackgroundTransparency", "float"},
        {"Visible", "bool"},
        {"ZIndex", "int"},
        {"ClearTextOnFocus", "bool"},
        {"MultiLine", "bool"},
    },

    ImageLabel = {
        {"Name", "string"},
        {"Position", "UDim2"},
        {"Size", "UDim2"},
        {"AnchorPoint", "Vector2"},
        {"Image", "string"},
        {"ImageColor3", "Color3"},
        {"ImageTransparency", "float"},
        {"BackgroundColor3", "Color3"},
        {"BackgroundTransparency", "float"},
        {"Visible", "bool"},
        {"ZIndex", "int"},
        {"ScaleType", "Enum"},
    },

    ImageButton = {
        {"Name", "string"},
        {"Position", "UDim2"},
        {"Size", "UDim2"},
        {"AnchorPoint", "Vector2"},
        {"Image", "string"},
        {"ImageColor3", "Color3"},
        {"ImageTransparency", "float"},
        {"BackgroundColor3", "Color3"},
        {"BackgroundTransparency", "float"},
        {"Visible", "bool"},
        {"ZIndex", "int"},
        {"ScaleType", "Enum"},
        {"AutoButtonColor", "bool"},
    },

    ScrollingFrame = {
        {"Name", "string"},
        {"Position", "UDim2"},
        {"Size", "UDim2"},
        {"AnchorPoint", "Vector2"},
        {"CanvasSize", "UDim2"},
        {"CanvasPosition", "Vector2"},
        {"ScrollBarThickness", "int"},
        {"BackgroundColor3", "Color3"},
        {"BackgroundTransparency", "float"},
        {"Visible", "bool"},
        {"ZIndex", "int"},
        {"ScrollingDirection", "Enum"},
    },

    UIListLayout = {
        {"Name", "string"},
        {"SortOrder", "Enum"},
        {"FillDirection", "Enum"},
        {"Padding", "UDim"},
        {"HorizontalAlignment", "Enum"},
        {"VerticalAlignment", "Enum"},
    },

    UIGridLayout = {
        {"Name", "string"},
        {"SortOrder", "Enum"},
        {"CellSize", "UDim2"},
        {"CellPadding", "UDim2"},
        {"FillDirection", "Enum"},
    },

    UICorner = {
        {"Name", "string"},
        {"CornerRadius", "UDim"},
    },

    UIPadding = {
        {"Name", "string"},
        {"PaddingTop", "UDim"},
        {"PaddingBottom", "UDim"},
        {"PaddingLeft", "UDim"},
        {"PaddingRight", "UDim"},
    },

    UIStroke = {
        {"Name", "string"},
        {"Color", "Color3"},
        {"Thickness", "float"},
        {"Transparency", "float"},
        {"ApplyStrokeMode", "Enum"},
        {"LineJoinMode", "Enum"},
    },

    Weld = {
        {"Name", "string"},
        {"C0", "CFrame"},
        {"C1", "CFrame"},
    },

    WeldConstraint = {
        {"Name", "string"},
        {"Enabled", "bool"},
    },

    Motor6D = {
        {"Name", "string"},
        {"C0", "CFrame"},
        {"C1", "CFrame"},
    },

    Attachment = {
        {"Name", "string"},
        {"CFrame", "CFrame"},
        {"Visible", "bool"},
    },

    BillboardGui = {
        {"Name", "string"},
        {"Size", "UDim2"},
        {"StudsOffset", "Vector3"},
        {"Enabled", "bool"},
        {"AlwaysOnTop", "bool"},
        {"MaxDistance", "float"},
    },

    SurfaceGui = {
        {"Name", "string"},
        {"CanvasSize", "Vector2"},
        {"Enabled", "bool"},
        {"Face", "Enum"},
        {"AlwaysOnTop", "bool"},
    },

    Beam = {
        {"Name", "string"},
        {"Color", "ColorSequence"},
        {"Transparency", "NumberSequence"},
        {"Width0", "float"},
        {"Width1", "float"},
        {"Texture", "string"},
        {"Enabled", "bool"},
    },

    Trail = {
        {"Name", "string"},
        {"Color", "ColorSequence"},
        {"Transparency", "NumberSequence"},
        {"Lifetime", "float"},
        {"Texture", "string"},
        {"Enabled", "bool"},
    },

    Atmosphere = {
        {"Name", "string"},
        {"Density", "float"},
        {"Offset", "float"},
        {"Color", "Color3"},
        {"Decay", "Color3"},
        {"Glare", "float"},
        {"Haze", "float"},
    },

    Sky = {
        {"Name", "string"},
        {"SkyboxBk", "string"},
        {"SkyboxDn", "string"},
        {"SkyboxFt", "string"},
        {"SkyboxLf", "string"},
        {"SkyboxRt", "string"},
        {"SkyboxUp", "string"},
        {"SunAngularSize", "float"},
        {"MoonAngularSize", "float"},
        {"StarCount", "int"},
    },

    Bloom = {
        {"Name", "string"},
        {"Intensity", "float"},
        {"Size", "float"},
        {"Threshold", "float"},
    },

    BlurEffect = {
        {"Name", "string"},
        {"Size", "float"},
        {"Enabled", "bool"},
    },

    ColorCorrectionEffect = {
        {"Name", "string"},
        {"Brightness", "float"},
        {"Contrast", "float"},
        {"Saturation", "float"},
        {"TintColor", "Color3"},
    },

    SunRaysEffect = {
        {"Name", "string"},
        {"Intensity", "float"},
        {"Spread", "float"},
    },

    DepthOfFieldEffect = {
        {"Name", "string"},
        {"FarIntensity", "float"},
        {"FocusDistance", "float"},
        {"InFocusRadius", "float"},
        {"NearIntensity", "float"},
    },

    StringValue = {
        {"Name", "string"},
        {"Value", "string"},
    },

    IntValue = {
        {"Name", "string"},
        {"Value", "int"},
    },

    NumberValue = {
        {"Name", "string"},
        {"Value", "float"},
    },

    BoolValue = {
        {"Name", "string"},
        {"Value", "bool"},
    },

    ObjectValue = {
        {"Name", "string"},
    },

    Color3Value = {
        {"Name", "string"},
        {"Value", "Color3"},
    },

    Vector3Value = {
        {"Name", "string"},
        {"Value", "Vector3"},
    },

    CFrameValue = {
        {"Name", "string"},
        {"Value", "CFrame"},
    },

    Configuration = {
        {"Name", "string"},
    },

    RemoteEvent = {
        {"Name", "string"},
    },

    RemoteFunction = {
        {"Name", "string"},
    },

    BindableEvent = {
        {"Name", "string"},
    },

    BindableFunction = {
        {"Name", "string"},
    },

    Camera = {
        {"Name", "string"},
        {"CFrame", "CFrame"},
        {"FieldOfView", "float"},
        {"CameraType", "Enum"},
    },

    Humanoid = {
        {"Name", "string"},
        {"MaxHealth", "float"},
        {"Health", "float"},
        {"WalkSpeed", "float"},
        {"JumpPower", "float"},
        {"JumpHeight", "float"},
        {"HipHeight", "float"},
        {"DisplayName", "string"},
    },

    Accessory = {
        {"Name", "string"},
    },

    Tool = {
        {"Name", "string"},
        {"ToolTip", "string"},
        {"RequiresHandle", "bool"},
        {"CanBeDropped", "bool"},
        {"Enabled", "bool"},
        {"Grip", "CFrame"},
    },

    ClickDetector = {
        {"Name", "string"},
        {"MaxActivationDistance", "float"},
    },

    ProximityPrompt = {
        {"Name", "string"},
        {"ActionText", "string"},
        {"ObjectText", "string"},
        {"HoldDuration", "float"},
        {"MaxActivationDistance", "float"},
        {"RequiresLineOfSight", "bool"},
        {"Enabled", "bool"},
        {"KeyboardKeyCode", "Enum"},
        {"Style", "Enum"},
    },
}

--- Lấy danh sách properties cho một ClassName
local function GetPropertiesForClass(className)
    local props = ClassProperties[className]

    -- Nếu là string, tra cứu parent class
    if typeof(props) == "string" then
        props = ClassProperties[props]
    end

    -- Nếu không có definition, trả về basic properties
    if not props then
        return {{"Name", "string"}}
    end

    return props
end

--- Serialize một instance thành XML
--- @param instance Instance
--- @param indent number
--- @param decompileScripts boolean
--- @param scriptSources table {[Instance] = string}
--- @return string xml
local function SerializeInstance(instance, indent, decompileScripts, scriptSources)
    indent = indent or 2
    local indentStr = string.rep("  ", indent)
    local lines = {}

    -- Lấy className
    local className = instance.ClassName

    -- Tạo referent
    local ref = NextRef()

    table.insert(lines, indentStr .. '<Item class="'
        .. XmlEscape(className) .. '" referent="' .. ref .. '">')
    table.insert(lines, indentStr .. '  <Properties>')

    -- Serialize properties
    local props = GetPropertiesForClass(className)

    for _, propDef in ipairs(props) do
        local propName, propType = propDef[1], propDef[2]

        -- Special case: Script Source
        if propName == "Source" and IsScript(instance) then
            if decompileScripts and scriptSources and scriptSources[instance] then
                local source = scriptSources[instance]
                table.insert(lines, indentStr .. '    '
                    .. SerializeProperty("Source", source, "ProtectedString"))
            else
                -- Placeholder
                table.insert(lines, indentStr .. '    '
                    .. SerializeProperty("Source",
                    "-- Source not available", "ProtectedString"))
            end
        else
            -- Đọc property value
            local ok, value = pcall(function()
                return instance[propName]
            end)

            if ok and value ~= nil then
                local serialized = SerializeProperty(propName, value, propType)
                if serialized and #serialized > 0 then
                    -- Thêm indent cho mỗi dòng
                    for sLine in serialized:gmatch("[^\n]+") do
                        table.insert(lines, indentStr .. '    ' .. sLine)
                    end
                end
            end
        end
    end

    table.insert(lines, indentStr .. '  </Properties>')

    -- Serialize children
    local ok, children = pcall(function()
        return instance:GetChildren()
    end)

    if ok and children and #children > 0 then
        for _, child in ipairs(children) do
            -- Bỏ qua một số instance không cần thiết
            local skipClasses = {
                "Player", "PlayerScripts", "PlayerGui",
                "Backpack", "Camera"
            }
            local shouldSkip = false
            for _, skipClass in ipairs(skipClasses) do
                if child.ClassName == skipClass then
                    shouldSkip = true
                    break
                end
            end

            if not shouldSkip then
                local childXml = SerializeInstance(
                    child, indent + 1, decompileScripts, scriptSources
                )
                if childXml and #childXml > 0 then
                    table.insert(lines, childXml)
                end
            end

            Stats.ProcessedInstances = Stats.ProcessedInstances + 1
            SafeYield()
        end
    end

    table.insert(lines, indentStr .. '</Item>')

    return table.concat(lines, "\n")
end

--- Tạo RBXLX file content đầy đủ
--- @param items table danh sách {service = Instance, ...}
--- @param decompileScripts boolean
--- @param scriptSources table
--- @return string xmlContent
local function BuildRBXLX(items, decompileScripts, scriptSources)
    Log("Đang tạo RBXLX content...", 5)

    local lines = {
        '<?xml version="1.0" encoding="utf-8"?>',
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"'
            .. ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
            .. ' xsi:noNamespaceSchemaLocation='
            .. '"http://www.roblox.com/roblox.xsd" version="4">',
        '  <!-- Generated by BaoSaveInstance v'
            .. BaoSaveInstance.Version .. ' -->',
        '  <!-- Game: ' .. XmlEscape(BaoSaveInstance.GetGameName()) .. ' -->',
        '  <!-- PlaceId: ' .. tostring(game.PlaceId) .. ' -->',
        '  <!-- Date: ' .. os.date("%Y-%m-%d %H:%M:%S") .. ' -->',
        '',
    }

    for _, item in ipairs(items) do
        if typeof(item) == "Instance" then
            local xml = SerializeInstance(
                item, 1, decompileScripts, scriptSources
            )
            if xml and #xml > 0 then
                table.insert(lines, xml)
            end
            ForceYield()
        end
    end

    table.insert(lines, '</roblox>')

    return table.concat(lines, "\n")
end

-- ═══════════════════════════════════════════════════════════════
-- SAVE TO FILE
-- ═══════════════════════════════════════════════════════════════

--- Lưu content vào file
--- @param fileName string
--- @param content string
--- @return boolean success
function BaoSaveInstance.SaveToFile(fileName, content)
    if not ExploitEnv.writefile then
        Log("writefile() không khả dụng! Không thể lưu file.", 3)
        Log("Đang thử copy vào clipboard...", 2)

        if ExploitEnv.setclipboard and #content < 200000 then
            pcall(ExploitEnv.setclipboard, content)
            Log("Đã copy nội dung vào clipboard (do không có writefile)", 2)
        end

        return false
    end

    -- Tạo folder nếu cần
    if ExploitEnv.isfolder and ExploitEnv.makefolder then
        if not pcall(function()
            if not ExploitEnv.isfolder("BaoSaveInstance") then
                ExploitEnv.makefolder("BaoSaveInstance")
            end
        end) then
            -- Không sao, lưu ở root
        end
    end

    -- Xác định path
    local filePath = fileName
    if ExploitEnv.isfolder then
        local ok, exists = pcall(ExploitEnv.isfolder, "BaoSaveInstance")
        if ok and exists then
            filePath = "BaoSaveInstance/" .. fileName
        end
    end

    -- Lưu file
    local ok, err = pcall(ExploitEnv.writefile, filePath, content)
    if ok then
        Log("✓ File đã lưu: " .. filePath, 4)
        Log("  Kích thước: " .. string.format("%.2f KB", #content / 1024), 1)
        return true
    else
        Log("Lỗi lưu file: " .. tostring(err), 3)

        -- Thử lưu với tên ngắn hơn
        local shortName = "BaoSave_" .. game.PlaceId .. ".rbxlx"
        local ok2, err2 = pcall(ExploitEnv.writefile, shortName, content)
        if ok2 then
            Log("✓ File đã lưu với tên thay thế: " .. shortName, 4)
            return true
        else
            Log("Lỗi lưu file (retry): " .. tostring(err2), 3)
            return false
        end
    end
end

--- Sử dụng saveinstance native nếu có
--- @param options table
--- @param fileName string
--- @return boolean success
local function TryNativeSaveInstance(options, fileName)
    if not ExploitEnv.saveinstance then
        return false
    end

    Log("Đang thử saveinstance() native...", 1)

    local defaultOptions = {
        -- Các option phổ biến cho saveinstance
        FileName = fileName or BaoSaveInstance.BuildFileName(),
        DecompileMode = "full",
        NilInstances = true,
        RemovePlayerCharacters = true,
        SavePlayers = false,
        ExtraInstances = {},
        ShowStatus = true,
        DecompileTimeout = Config.DecompileTimeout,
        DecompileIgnore = {},
        SaveBytecode = false,

        -- Synapse X specific
        noscripts = false,
        scriptcache = true,
        timeout = Config.DecompileTimeout,

        -- UWP/Fluxus specific
        mode = "full",
        decomptype = "custom",
    }

    -- Merge options
    if options then
        for k, v in pairs(options) do
            defaultOptions[k] = v
        end
    end

    local ok, err = pcall(ExploitEnv.saveinstance, defaultOptions)
    if ok then
        Log("✓ saveinstance() native thành công!", 4)
        return true
    else
        Log("saveinstance() native thất bại: " .. tostring(err), 2)
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- TERRAIN HANDLER
-- Xử lý và serialize Terrain data
-- ═══════════════════════════════════════════════════════════════

local TerrainHandler = {}

--- Đọc và serialize terrain voxel data
--- @return string terrainXml
function TerrainHandler.SerializeTerrain()
    Log("Đang xử lý Terrain...", 5)

    local terrain = Workspace.Terrain
    if not terrain then
        Log("Không tìm thấy Terrain!", 2)
        return ""
    end

    local lines = {}
    local ref = NextRef()

    table.insert(lines, '  <Item class="Terrain" referent="' .. ref .. '">')
    table.insert(lines, '    <Properties>')
    table.insert(lines, '      <string name="Name">Terrain</string>')

    -- Serialize terrain colors
    local ok1, waterColor = pcall(function() return terrain.WaterColor end)
    if ok1 and waterColor then
        table.insert(lines, '      '
            .. SerializeProperty("WaterColor", waterColor, "Color3"))
    end

    local ok2, waterTransparency = pcall(function()
        return terrain.WaterTransparency
    end)
    if ok2 then
        table.insert(lines, '      '
            .. SerializeProperty("WaterTransparency",
            waterTransparency, "float"))
    end

    local ok3, waterWaveSize = pcall(function()
        return terrain.WaterWaveSize
    end)
    if ok3 then
        table.insert(lines, '      '
            .. SerializeProperty("WaterWaveSize", waterWaveSize, "float"))
    end

    local ok4, waterWaveSpeed = pcall(function()
        return terrain.WaterWaveSpeed
    end)
    if ok4 then
        table.insert(lines, '      '
            .. SerializeProperty("WaterWaveSpeed", waterWaveSpeed, "float"))
    end

    local ok5, waterReflectance = pcall(function()
        return terrain.WaterReflectance
    end)
    if ok5 then
        table.insert(lines, '      '
            .. SerializeProperty("WaterReflectance",
            waterReflectance, "float"))
    end

    -- Thử đọc terrain voxel data
    -- Sử dụng ReadVoxels nếu có
    local hasVoxelData = false
    local voxelDataStr = ""

    pcall(function()
        -- Xác định kích thước terrain
        local regionSize = 512
        local cellSize = 4

        -- Đọc terrain region
        local region = Region3.new(
            Vector3.new(-regionSize, -regionSize, -regionSize),
            Vector3.new(regionSize, regionSize, regionSize)
        )

        -- Align to grid
        region = region:ExpandToGrid(cellSize)

        local materials, occupancy = terrain:ReadVoxels(region, cellSize)

        -- Kiểm tra xem có dữ liệu không
        local hasData = false
        for x = 1, #materials do
            for y = 1, #materials[x] do
                for z = 1, #materials[x][y] do
                    if materials[x][y][z] ~= Enum.Material.Air then
                        hasData = true
                        break
                    end
                end
                if hasData then break end
            end
            if hasData then break end
        end

        if hasData then
            hasVoxelData = true
            Log("Terrain có dữ liệu voxel, đang serialize...", 1)

            -- Encode voxel data dưới dạng comment (cho tham khảo)
            -- Actual terrain data phải dùng binary format
            local voxelInfo = {
                "-- Terrain Voxel Data Info:",
                "-- Region: " .. tostring(region),
                "-- Grid Size: " .. cellSize,
                "-- Dimensions: "
                    .. #materials .. "x"
                    .. #materials[1] .. "x"
                    .. #materials[1][1],
            }
            voxelDataStr = table.concat(voxelInfo, "\n")
        end
    end)

    -- Nếu có gethiddenproperty, thử lấy SmoothGrid data
    if ExploitEnv.gethiddenproperty then
        local sgOk, smoothGrid = pcall(
            ExploitEnv.gethiddenproperty, terrain, "SmoothGrid"
        )
        if sgOk and smoothGrid then
            -- SmoothGrid chứa binary terrain data
            -- Trong .rbxlx format, nó được encode dưới dạng base64
            local b64Ok, b64Data = pcall(function()
                -- Cố gắng base64 encode
                local b64 = ""
                local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

                if typeof(smoothGrid) == "string" then
                    local bytes = {string.byte(smoothGrid, 1, #smoothGrid)}
                    local i = 1
                    while i <= #bytes do
                        local b1 = bytes[i] or 0
                        local b2 = bytes[i + 1] or 0
                        local b3 = bytes[i + 2] or 0

                        local n = b1 * 65536 + b2 * 256 + b3

                        local c1 = math.floor(n / 262144) % 64
                        local c2 = math.floor(n / 4096) % 64
                        local c3 = math.floor(n / 64) % 64
                        local c4 = n % 64

                        b64 = b64
                            .. chars:sub(c1 + 1, c1 + 1)
                            .. chars:sub(c2 + 1, c2 + 1)

                        if i + 1 <= #bytes then
                            b64 = b64 .. chars:sub(c3 + 1, c3 + 1)
                        else
                            b64 = b64 .. "="
                        end

                        if i + 2 <= #bytes then
                            b64 = b64 .. chars:sub(c4 + 1, c4 + 1)
                        else
                            b64 = b64 .. "="
                        end

                        i = i + 3
                    end
                    return b64
                end
                return nil
            end)

            if b64Ok and b64Data and #b64Data > 0 then
                table.insert(lines, '      <BinaryString name="SmoothGrid">'
                    .. b64Data .. '</BinaryString>')
                hasVoxelData = true
                Log("Terrain SmoothGrid data captured ("
                    .. string.format("%.2f KB", #b64Data / 1024) .. ")", 4)
            end
        end

        -- Cũng thử MaterialColors
        local mcOk, matColors = pcall(
            ExploitEnv.gethiddenproperty, terrain, "MaterialColors"
        )
        if mcOk and matColors and typeof(matColors) == "string" then
            local b64Ok2, b64Data2 = pcall(function()
                -- Simple base64 encode cho MaterialColors
                local b64 = ""
                local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
                local bytes = {string.byte(matColors, 1, #matColors)}
                local i = 1
                while i <= #bytes do
                    local b1 = bytes[i] or 0
                    local b2 = bytes[i + 1] or 0
                    local b3 = bytes[i + 2] or 0
                    local n = b1 * 65536 + b2 * 256 + b3
                    b64 = b64
                        .. chars:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
                        .. chars:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
                    if i + 1 <= #bytes then
                        b64 = b64 .. chars:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1)
                    else
                        b64 = b64 .. "="
                    end
                    if i + 2 <= #bytes then
                        b64 = b64 .. chars:sub(n % 64 + 1, n % 64 + 1)
                    else
                        b64 = b64 .. "="
                    end
                    i = i + 3
                end
                return b64
            end)

            if b64Ok2 and b64Data2 then
                table.insert(lines, '      <BinaryString name="MaterialColors">'
                    .. b64Data2 .. '</BinaryString>')
            end
        end
    end

    if not hasVoxelData then
        Log("Không có dữ liệu Terrain voxel hoặc terrain trống", 2)
    end

    table.insert(lines, '    </Properties>')
    table.insert(lines, '  </Item>')

    return table.concat(lines, "\n")
end

-- ═══════════════════════════════════════════════════════════════
-- CORE DECOMPILE FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

--- ═══════════════════════════════════════════════════
--- 1. DECOMPILE GAME (Full Game - All in One)
--- ═══════════════════════════════════════════════════
function BaoSaveInstance.DecompileGame()
    ResetStats()
    Log("", 1)
    Log("╔══════════════════════════════════════════════════════╗", 1)
    Log("║      BaoSaveInstance - DECOMPILE GAME (FULL)        ║", 1)
    Log("╚══════════════════════════════════════════════════════╝", 1)
    Log("Game: " .. BaoSaveInstance.GetGameName(), 1)
    Log("PlaceId: " .. tostring(game.PlaceId), 1)
    Log("", 1)

    local fileName = BaoSaveInstance.BuildFileName()

    -- ── Bước 0: Thử native saveinstance trước ──
    Log("Bước 0/5: Thử saveinstance() native...", 5)
    local nativeSuccess = TryNativeSaveInstance({
        FileName = fileName,
        NilInstances = true,
        DecompileMode = "full",
    }, fileName)

    if nativeSuccess then
        Stats.EndTime = tick()
        Log("", 1)
        Log("═══════════════════════════════════════════════════", 1)
        Log("HOÀN TẤT bằng native saveinstance!", 4)
        Log("Thời gian: " .. string.format("%.2f", Stats.EndTime - Stats.StartTime) .. "s", 1)
        Log("File: " .. fileName, 1)
        Log("═══════════════════════════════════════════════════", 1)
        return true
    end

    Log("Native saveinstance không khả dụng, chuyển sang custom serializer", 2)

    -- ── Bước 1: Thu thập tất cả scripts ──
    Log("Bước 1/5: Thu thập Scripts...", 5)
    local allScripts = CollectAllScripts()
    Stats.TotalScripts = #allScripts

    -- ── Bước 2: Decompile tất cả scripts ──
    Log("Bước 2/5: Decompile " .. #allScripts .. " Scripts...", 5)
    local scriptSources = {}

    for i, scriptInfo in ipairs(allScripts) do
        local scriptInstance = scriptInfo.Instance

        if Config.LogLevel >= 3 then
            Log("  [" .. i .. "/" .. #allScripts .. "] "
                .. scriptInfo.Path, 1)
        elseif i % 10 == 0 or i == #allScripts then
            Log("  Đang decompile: " .. i .. "/" .. #allScripts
                .. " (" .. math.floor(i / #allScripts * 100) .. "%)", 5)
        end

        local source, engineName = BaoSaveInstance.TryDecompileScript(scriptInstance)

        if source then
            -- Thêm header comment
            local header = string.format(
                "-- Decompiled by BaoSaveInstance v%s\n"
                .. "-- Script: %s\n"
                .. "-- Class: %s\n"
                .. "-- Engine: %s\n"
                .. "-- Date: %s\n\n",
                BaoSaveInstance.Version,
                scriptInfo.Path,
                scriptInstance.ClassName,
                engineName or "Unknown",
                os.date("%Y-%m-%d %H:%M:%S")
            )

            scriptSources[scriptInstance] = header .. source

            if engineName ~= "FAILED" then
                Stats.DecompiledScripts = Stats.DecompiledScripts + 1
            else
                Stats.FailedScripts = Stats.FailedScripts + 1
            end
        else
            Stats.FailedScripts = Stats.FailedScripts + 1
            scriptSources[scriptInstance] =
                "-- BaoSaveInstance: Failed to decompile\n"
                .. "-- Script: " .. scriptInfo.Path .. "\n"
        end

        SafeYield()
    end

    Log("Decompile hoàn tất: "
        .. Stats.DecompiledScripts .. " thành công, "
        .. Stats.FailedScripts .. " thất bại", 4)

    -- ── Bước 3: Thu thập tất cả instances ──
    Log("Bước 3/5: Thu thập Instances từ các Services...", 5)
    local allItems = {}

    for _, serviceName in ipairs(Config.FullGameServices) do
        local ok, service = pcall(function()
            return game:GetService(serviceName)
        end)
        if ok and service then
            table.insert(allItems, service)
            local count = CountDescendants(service)
            Stats.TotalInstances = Stats.TotalInstances + count
            Log("  " .. serviceName .. ": " .. count .. " instances", 1)
            ForceYield()
        end
    end

    -- Thêm nil instances
    if ExploitEnv.getnilinstances then
        local ok, nilInsts = pcall(ExploitEnv.getnilinstances)
        if ok and nilInsts and #nilInsts > 0 then
            -- Tạo một folder giả để chứa nil instances
            Log("  Nil Instances: " .. #nilInsts, 1)
        end
    end

    -- ── Bước 4: Serialize thành RBXLX ──
    Log("Bước 4/5: Serializing thành RBXLX...", 5)
    Log("  Tổng instances: " .. Stats.TotalInstances, 1)

    local xmlContent = BuildRBXLX(allItems, true, scriptSources)

    Log("  RBXLX size: " .. string.format("%.2f KB", #xmlContent / 1024), 1)

    -- ── Bước 5: Lưu file ──
    Log("Bước 5/5: Lưu file...", 5)

    -- Lưu .rbxlx (XML format - tương thích tốt)
    local rbxlxName = fileName:gsub("%.rbxl$", ".rbxlx")
    local saveSuccess = BaoSaveInstance.SaveToFile(rbxlxName, xmlContent)

    -- Cũng thử lưu scripts riêng nếu writefile khả dụng
    if ExploitEnv.writefile and ExploitEnv.makefolder then
        pcall(function()
            local folderName = "BaoSaveInstance/Scripts_"
                .. BaoSaveInstance.SanitizeFileName(BaoSaveInstance.GetGameName())

            if ExploitEnv.isfolder and not ExploitEnv.isfolder(folderName) then
                ExploitEnv.makefolder(folderName)
            end

            local savedCount = 0
            for _, scriptInfo in ipairs(allScripts) do
                if scriptSources[scriptInfo.Instance] then
                    local scriptFileName = scriptInfo.Instance.Name:gsub('[/\\:*?"<>|%c]', '_')
                    scriptFileName = scriptFileName .. "_"
                        .. scriptInfo.Instance.ClassName .. ".lua"

                    pcall(function()
                        ExploitEnv.writefile(
                            folderName .. "/" .. scriptFileName,
                            scriptSources[scriptInfo.Instance]
                        )
                        savedCount = savedCount + 1
                    end)
                end
            end

            if savedCount > 0 then
                Log("  Đã lưu " .. savedCount
                    .. " scripts riêng lẻ vào " .. folderName, 4)
            end
        end)
    end

    -- ── Kết quả ──
    Stats.EndTime = tick()
    local elapsed = Stats.EndTime - Stats.StartTime

    Log("", 1)
    Log("═══════════════════════════════════════════════════════════", 1)
    Log("           DECOMPILE GAME HOÀN TẤT!", 4)
    Log("═══════════════════════════════════════════════════════════", 1)
    Log("  Game: " .. BaoSaveInstance.GetGameName(), 1)
    Log("  Thời gian: " .. string.format("%.2f", elapsed) .. " giây", 1)
    Log("  Tổng Instances: " .. Stats.TotalInstances, 1)
    Log("  Scripts: " .. Stats.TotalScripts
        .. " (Thành công: " .. Stats.DecompiledScripts
        .. ", Thất bại: " .. Stats.FailedScripts .. ")", 1)
    Log("  File: " .. rbxlxName, 1)
    Log("  Kích thước: "
        .. string.format("%.2f KB", #xmlContent / 1024), 1)

    if #Stats.Errors > 0 then
        Log("  Lỗi: " .. #Stats.Errors, 2)
    end

    Log("═══════════════════════════════════════════════════════════", 1)

    return saveSuccess
end

--- ═══════════════════════════════════════════════════
--- 2. DECOMPILE MAP
--- ═══════════════════════════════════════════════════
function BaoSaveInstance.DecompileMap()
    ResetStats()
    Log("", 1)
    Log("╔══════════════════════════════════════════════════════╗", 1)
    Log("║       BaoSaveInstance - DECOMPILE MAP               ║", 1)
    Log("╚══════════════════════════════════════════════════════╝", 1)

    local fileName = BaoSaveInstance.BuildFileName("Map")

    -- Thử native saveinstance với chế độ map only
    local nativeSuccess = TryNativeSaveInstance({
        FileName = fileName,
        NilInstances = false,
        DecompileMode = "full",
        noscripts = true,
    }, fileName)

    if nativeSuccess then
        Stats.EndTime = tick()
        Log("HOÀN TẤT bằng native saveinstance!", 4)
        return true
    end

    -- Custom serializer cho Map
    Log("Đang quét Map (Workspace)...", 5)

    local mapItems = {}
    local ok, children = pcall(function()
        return Workspace:GetChildren()
    end)

    if ok and children then
        for _, child in ipairs(children) do
            -- Bỏ qua Camera, Terrain (riêng), Players
            local skip = child:IsA("Camera")
                or child:IsA("Terrain")
                or child.Name == "Camera"

            -- Bỏ qua Player characters
            pcall(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if child == player.Character then
                        skip = true
                    end
                end
            end)

            if not skip then
                table.insert(mapItems, child)
                Stats.TotalInstances = Stats.TotalInstances
                    + CountDescendants(child) + 1
            end
        end
    end

    -- Bao gồm Terrain
    table.insert(mapItems, Workspace.Terrain)

    Log("Tìm thấy " .. #mapItems
        .. " root items, " .. Stats.TotalInstances .. " instances", 1)

    -- Serialize
    Log("Đang serialize Map...", 5)

    local lines = {
        '<?xml version="1.0" encoding="utf-8"?>',
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"'
            .. ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
            .. ' xsi:noNamespaceSchemaLocation='
            .. '"http://www.roblox.com/roblox.xsd" version="4">',
        '  <!-- BaoSaveInstance Map Export -->',
        '  <!-- Game: '
            .. XmlEscape(BaoSaveInstance.GetGameName()) .. ' -->',
        '',
        '  <Item class="Workspace" referent="' .. NextRef() .. '">',
        '    <Properties>',
        '      <string name="Name">Workspace</string>',
        '    </Properties>',
    }

    -- Terrain
    local terrainXml = TerrainHandler.SerializeTerrain()
    if #terrainXml > 0 then
        table.insert(lines, terrainXml)
    end

    -- Map items
    for _, item in ipairs(mapItems) do
        if not item:IsA("Terrain") then
            local xml = SerializeInstance(item, 2, false, nil)
            if xml and #xml > 0 then
                table.insert(lines, xml)
            end
            ForceYield()
        end
    end

    table.insert(lines, '  </Item>')
    table.insert(lines, '</roblox>')

    local xmlContent = table.concat(lines, "\n")

    -- Lưu file
    local rbxlxName = fileName:gsub("%.rbxl$", ".rbxlx")
    local saveSuccess = BaoSaveInstance.SaveToFile(rbxlxName, xmlContent)

    Stats.EndTime = tick()
    Log("", 1)
    Log("═══════════════════════════════════════════════════════", 1)
    Log("  DECOMPILE MAP HOÀN TẤT!", 4)
    Log("  Instances: " .. Stats.TotalInstances, 1)
    Log("  File: " .. rbxlxName, 1)
    Log("  Kích thước: "
        .. string.format("%.2f KB", #xmlContent / 1024), 1)
    Log("  Thời gian: "
        .. string.format("%.2f", Stats.EndTime - Stats.StartTime) .. "s", 1)
    Log("═══════════════════════════════════════════════════════", 1)

    return saveSuccess
end

--- ═══════════════════════════════════════════════════
--- 3. DECOMPILE TERRAIN
--- ═══════════════════════════════════════════════════
function BaoSaveInstance.DecompileTerrain()
    ResetStats()
    Log("", 1)
    Log("╔══════════════════════════════════════════════════════╗", 1)
    Log("║      BaoSaveInstance - DECOMPILE TERRAIN            ║", 1)
    Log("╚══════════════════════════════════════════════════════╝", 1)

    local fileName = BaoSaveInstance.BuildFileName("Terrain")

    -- Serialize terrain
    Log("Đang xử lý Terrain...", 5)

    local lines = {
        '<?xml version="1.0" encoding="utf-8"?>',
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"'
            .. ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
            .. ' xsi:noNamespaceSchemaLocation='
            .. '"http://www.roblox.com/roblox.xsd" version="4">',
        '  <!-- BaoSaveInstance Terrain Export -->',
        '  <!-- Game: '
            .. XmlEscape(BaoSaveInstance.GetGameName()) .. ' -->',
        '',
        '  <Item class="Workspace" referent="' .. NextRef() .. '">',
        '    <Properties>',
        '      <string name="Name">Workspace</string>',
        '    </Properties>',
    }

    local terrainXml = TerrainHandler.SerializeTerrain()
    if #terrainXml > 0 then
        table.insert(lines, terrainXml)
        Log("Terrain data serialized thành công", 4)
    else
        Log("Không có dữ liệu Terrain để export", 2)
    end

    table.insert(lines, '  </Item>')
    table.insert(lines, '</roblox>')

    local xmlContent = table.concat(lines, "\n")

    -- Lưu file
    local rbxlxName = fileName:gsub("%.rbxl$", ".rbxlx")
    local saveSuccess = BaoSaveInstance.SaveToFile(rbxlxName, xmlContent)

    Stats.EndTime = tick()
    Log("", 1)
    Log("═══════════════════════════════════════════════════════", 1)
    Log("  DECOMPILE TERRAIN HOÀN TẤT!", 4)
    Log("  File: " .. rbxlxName, 1)
    Log("  Kích thước: "
        .. string.format("%.2f KB", #xmlContent / 1024), 1)
    Log("  Thời gian: "
        .. string.format("%.2f", Stats.EndTime - Stats.StartTime) .. "s", 1)
    Log("═══════════════════════════════════════════════════════", 1)

    return saveSuccess
end

--- ═══════════════════════════════════════════════════
--- 4. DECOMPILE SCRIPT (All Scripts Only)
--- ═══════════════════════════════════════════════════
function BaoSaveInstance.DecompileScript()
    ResetStats()
    Log("", 1)
    Log("╔══════════════════════════════════════════════════════╗", 1)
    Log("║      BaoSaveInstance - DECOMPILE SCRIPTS            ║", 1)
    Log("╚══════════════════════════════════════════════════════╝", 1)

    local fileName = BaoSaveInstance.BuildFileName("Scripts")

    -- Thu thập scripts
    Log("Bước 1/3: Thu thập Scripts...", 5)
    local allScripts = CollectAllScripts()
    Stats.TotalScripts = #allScripts

    if #allScripts == 0 then
        Log("Không tìm thấy Script nào!", 2)
        return false
    end

    -- Decompile
    Log("Bước 2/3: Decompile " .. #allScripts .. " Scripts...", 5)
    local scriptSources = {}
    local scriptList = {} -- Để lưu file riêng

    for i, scriptInfo in ipairs(allScripts) do
        local scriptInstance = scriptInfo.Instance

        if i % 5 == 0 or i == #allScripts then
            Log("  Đang decompile: " .. i .. "/" .. #allScripts
                .. " (" .. math.floor(i / #allScripts * 100) .. "%)", 5)
        end

        local source, engineName = BaoSaveInstance.TryDecompileScript(scriptInstance)

        if source then
            local header = string.format(
                "-- Decompiled by BaoSaveInstance v%s\n"
                .. "-- Script: %s\n"
                .. "-- Class: %s\n"
                .. "-- Engine: %s\n\n",
                BaoSaveInstance.Version,
                scriptInfo.Path,
                scriptInstance.ClassName,
                engineName or "Unknown"
            )

            local fullSource = header .. source
            scriptSources[scriptInstance] = fullSource

            table.insert(scriptList, {
                Name = scriptInstance.Name,
                ClassName = scriptInstance.ClassName,
                Path = scriptInfo.Path,
                Service = scriptInfo.Service,
                Source = fullSource,
                Engine = engineName,
            })

            if engineName ~= "FAILED" then
                Stats.DecompiledScripts = Stats.DecompiledScripts + 1
            else
                Stats.FailedScripts = Stats.FailedScripts + 1
            end
        else
            Stats.FailedScripts = Stats.FailedScripts + 1
        end

        SafeYield()
    end

    -- Lưu
    Log("Bước 3/3: Lưu kết quả...", 5)

    -- A) Tạo RBXLX với scripts giữ nguyên cấu trúc
    local rbxlxLines = {
        '<?xml version="1.0" encoding="utf-8"?>',
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"'
            .. ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
            .. ' xsi:noNamespaceSchemaLocation='
            .. '"http://www.roblox.com/roblox.xsd" version="4">',
        '  <!-- BaoSaveInstance Scripts Export -->',
        '  <!-- Game: '
            .. XmlEscape(BaoSaveInstance.GetGameName()) .. ' -->',
        '  <!-- Total Scripts: ' .. #allScripts .. ' -->',
        '',
    }

    -- Nhóm scripts theo Service
    local byService = {}
    for _, scriptInfo in ipairs(allScripts) do
        if not byService[scriptInfo.Service] then
            byService[scriptInfo.Service] = {}
        end
        table.insert(byService[scriptInfo.Service], scriptInfo)
    end

    for serviceName, scripts in pairs(byService) do
        local serviceRef = NextRef()
        table.insert(rbxlxLines, '  <Item class="Folder" referent="'
            .. serviceRef .. '">')
        table.insert(rbxlxLines, '    <Properties>')
        table.insert(rbxlxLines, '      <string name="Name">'
            .. XmlEscape(serviceName) .. '</string>')
        table.insert(rbxlxLines, '    </Properties>')

        for _, scriptInfo in ipairs(scripts) do
            local inst = scriptInfo.Instance
            local src = scriptSources[inst] or "-- Failed to decompile"
            local scriptRef = NextRef()

            table.insert(rbxlxLines, '    <Item class="'
                .. inst.ClassName .. '" referent="' .. scriptRef .. '">')
            table.insert(rbxlxLines, '      <Properties>')
            table.insert(rbxlxLines, '        <string name="Name">'
                .. XmlEscape(inst.Name) .. '</string>')
            table.insert(rbxlxLines,
                '        <ProtectedString name="Source"><![CDATA['
                .. src .. ']]></ProtectedString>')

            if inst:IsA("Script") or inst:IsA("LocalScript") then
                local disOk, disabled = pcall(function()
                    return inst.Disabled
                end)
                if disOk then
                    table.insert(rbxlxLines,
                        '        <bool name="Disabled">'
                        .. tostring(disabled) .. '</bool>')
                end
            end

            table.insert(rbxlxLines, '      </Properties>')
            table.insert(rbxlxLines, '    </Item>')
        end

        table.insert(rbxlxLines, '  </Item>')
    end

    table.insert(rbxlxLines, '</roblox>')

    local xmlContent = table.concat(rbxlxLines, "\n")
    local rbxlxName = fileName:gsub("%.rbxl$", ".rbxlx")
    BaoSaveInstance.SaveToFile(rbxlxName, xmlContent)

    -- B) Lưu scripts riêng lẻ nếu có writefile
    if ExploitEnv.writefile and ExploitEnv.makefolder then
        pcall(function()
            local baseFolderName = "BaoSaveInstance"
            local folderName = baseFolderName .. "/Scripts_"
                .. BaoSaveInstance.SanitizeFileName(
                    BaoSaveInstance.GetGameName()
                )

            if ExploitEnv.isfolder then
                if not ExploitEnv.isfolder(baseFolderName) then
                    ExploitEnv.makefolder(baseFolderName)
                end
                if not ExploitEnv.isfolder(folderName) then
                    ExploitEnv.makefolder(folderName)
                end
            end

            local savedCount = 0
            local usedNames = {}

            for _, info in ipairs(scriptList) do
                local safeName = info.Name:gsub('[/\\:*?"<>|%c]', '_')
                -- Tránh trùng tên
                if usedNames[safeName] then
                    usedNames[safeName] = usedNames[safeName] + 1
                    safeName = safeName .. "_" .. usedNames[safeName]
                else
                    usedNames[safeName] = 1
                end

                local scriptFileName = safeName
                    .. "_" .. info.ClassName .. ".lua"

                pcall(function()
                    ExploitEnv.writefile(
                        folderName .. "/" .. scriptFileName, info.Source
                    )
                    savedCount = savedCount + 1
                end)
            end

            if savedCount > 0 then
                Log("  Đã lưu " .. savedCount
                    .. " scripts riêng lẻ vào " .. folderName, 4)
            end
        end)
    end

    -- Kết quả
    Stats.EndTime = tick()
    local elapsed = Stats.EndTime - Stats.StartTime

    Log("", 1)
    Log("═══════════════════════════════════════════════════════", 1)
    Log("      DECOMPILE SCRIPTS HOÀN TẤT!", 4)
    Log("═══════════════════════════════════════════════════════", 1)
    Log("  Tổng Scripts: " .. Stats.TotalScripts, 1)
    Log("  Thành công: " .. Stats.DecompiledScripts, 1)
    Log("  Thất bại: " .. Stats.FailedScripts, 1)
    Log("  Tỉ lệ: "
        .. (Stats.TotalScripts > 0
            and string.format("%.1f%%",
                Stats.DecompiledScripts / Stats.TotalScripts * 100)
            or "N/A"), 1)
    Log("  File: " .. rbxlxName, 1)
    Log("  Thời gian: " .. string.format("%.2f", elapsed) .. " giây", 1)
    Log("═══════════════════════════════════════════════════════", 1)

    return true
end

-- ═══════════════════════════════════════════════════════════════
-- GUI (In-Game User Interface)
-- ═══════════════════════════════════════════════════════════════

function BaoSaveInstance.CreateGUI()
    -- Xoá GUI cũ nếu có
    pcall(function()
        local old = CoreGui:FindFirstChild("BaoSaveInstanceGUI")
        if old then old:Destroy() end
    end)

    -- Tạo ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstanceGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Thử đặt vào CoreGui, nếu không được thì PlayerGui
    local guiParent = CoreGui
    local ok = pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not ok then
        pcall(function()
            screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end)
    end

    -- ── Main Frame ──
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 420, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -260)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- Stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 120, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = mainFrame

    -- ── Title Bar ──
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    -- Fix bottom corners of title bar
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 15)
    titleFix.Position = UDim2.new(0, 0, 1, -15)
    titleFix.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🛡️ BaoSaveInstance v" .. BaoSaveInstance.Version
    titleLabel.TextColor3 = Color3.fromRGB(80, 160, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -42, 0, 7)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- ── Game Info ──
    local gameInfo = Instance.new("TextLabel")
    gameInfo.Size = UDim2.new(1, -20, 0, 35)
    gameInfo.Position = UDim2.new(0, 10, 0, 55)
    gameInfo.BackgroundTransparency = 1
    gameInfo.Text = "🎮 " .. BaoSaveInstance.GetGameName()
        .. " (ID: " .. game.PlaceId .. ")"
    gameInfo.TextColor3 = Color3.fromRGB(180, 180, 200)
    gameInfo.TextSize = 12
    gameInfo.Font = Enum.Font.Gotham
    gameInfo.TextXAlignment = Enum.TextXAlignment.Left
    gameInfo.TextWrapped = true
    gameInfo.Parent = mainFrame

    -- ── Buttons Container ──
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Size = UDim2.new(1, -20, 0, 220)
    buttonsFrame.Position = UDim2.new(0, 10, 0, 95)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = buttonsFrame

    -- Button factory
    local function CreateButton(text, icon, color, layoutOrder, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 48)
        btn.BackgroundColor3 = color
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.LayoutOrder = layoutOrder
        btn.Parent = buttonsFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(
            math.min(255, color.R * 255 + 40),
            math.min(255, color.G * 255 + 40),
            math.min(255, color.B * 255 + 40)
        )
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.5
        btnStroke.Parent = btn

        local btnLabel = Instance.new("TextLabel")
        btnLabel.Size = UDim2.new(1, -20, 1, 0)
        btnLabel.Position = UDim2.new(0, 10, 0, 0)
        btnLabel.BackgroundTransparency = 1
        btnLabel.Text = icon .. "  " .. text
        btnLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnLabel.TextSize = 15
        btnLabel.Font = Enum.Font.GothamSemibold
        btnLabel.TextXAlignment = Enum.TextXAlignment.Left
        btnLabel.Parent = btn

        -- Hover effects
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(
                    math.min(255, color.R * 255 + 25),
                    math.min(255, color.G * 255 + 25),
                    math.min(255, color.B * 255 + 25)
                )
            }):Play()
        end)

        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = color
            }):Play()
        end)

        btn.MouseButton1Click:Connect(function()
            -- Disable tất cả buttons
            for _, child in ipairs(buttonsFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child.Active = false
                    child.BackgroundTransparency = 0.5
                end
            end

            btnLabel.Text = "⏳ Đang xử lý..."

            task.spawn(function()
                local success, err = pcall(callback)
                if not success then
                    Log("Lỗi: " .. tostring(err), 3)
                end

                -- Re-enable buttons
                for _, child in ipairs(buttonsFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        child.Active = true
                        child.BackgroundTransparency = 0
                    end
                end
                btnLabel.Text = icon .. "  " .. text
            end)
        end)

        return btn
    end

    -- Tạo 4 buttons
    CreateButton(
        "Decompile Game (Full)",
        "🌍",
        Color3.fromRGB(40, 80, 160),
        1,
        BaoSaveInstance.DecompileGame
    )

    CreateButton(
        "Decompile Map",
        "🗺️",
        Color3.fromRGB(40, 130, 80),
        2,
        BaoSaveInstance.DecompileMap
    )

    CreateButton(
        "Decompile Terrain",
        "⛰️",
        Color3.fromRGB(140, 100, 40),
        3,
        BaoSaveInstance.DecompileTerrain
    )

    CreateButton(
        "Decompile Scripts",
        "📜",
        Color3.fromRGB(130, 40, 120),
        4,
        BaoSaveInstance.DecompileScript
    )

    -- ── Log/Output Area ──
    local logFrame = Instance.new("Frame")
    logFrame.Size = UDim2.new(1, -20, 0, 180)
    logFrame.Position = UDim2.new(0, 10, 0, 325)
    logFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    logFrame.BorderSizePixel = 0
    logFrame.Parent = mainFrame

    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0, 8)
    logCorner.Parent = logFrame

    local logTitle = Instance.new("TextLabel")
    logTitle.Size = UDim2.new(1, 0, 0, 25)
    logTitle.BackgroundTransparency = 1
    logTitle.Text = "  📋 Log Output"
    logTitle.TextColor3 = Color3.fromRGB(120, 120, 150)
    logTitle.TextSize = 11
    logTitle.Font = Enum.Font.GothamSemibold
    logTitle.TextXAlignment = Enum.TextXAlignment.Left
    logTitle.Parent = logFrame

    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Size = UDim2.new(1, -10, 1, -30)
    logScroll.Position = UDim2.new(0, 5, 0, 25)
    logScroll.BackgroundTransparency = 1
    logScroll.ScrollBarThickness = 4
    logScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 255)
    logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logScroll.Parent = logFrame

    local logListLayout = Instance.new("UIListLayout")
    logListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logListLayout.Padding = UDim.new(0, 2)
    logListLayout.Parent = logScroll

    local logOrder = 0

    -- Hàm cập nhật GUI log
    BaoSaveInstance._UpdateGUILog = function(message, level)
        pcall(function()
            if not logScroll or not logScroll.Parent then return end

            logOrder = logOrder + 1

            local color = ({
                [1] = Color3.fromRGB(180, 180, 200),  -- INFO
                [2] = Color3.fromRGB(255, 200, 80),   -- WARN
                [3] = Color3.fromRGB(255, 80, 80),    -- ERROR
                [4] = Color3.fromRGB(80, 255, 120),   -- SUCCESS
                [5] = Color3.fromRGB(80, 180, 255),   -- PROGRESS
            })[level] or Color3.fromRGB(180, 180, 200)

            local logLabel = Instance.new("TextLabel")
            logLabel.Size = UDim2.new(1, 0, 0, 14)
            logLabel.BackgroundTransparency = 1
            logLabel.Text = message
            logLabel.TextColor3 = color
            logLabel.TextSize = 10
            logLabel.Font = Enum.Font.Code
            logLabel.TextXAlignment = Enum.TextXAlignment.Left
            logLabel.TextWrapped = true
            logLabel.AutomaticSize = Enum.AutomaticSize.Y
            logLabel.LayoutOrder = logOrder
            logLabel.Parent = logScroll

            -- Giới hạn số lượng log entries
            local children = logScroll:GetChildren()
            local labelCount = 0
            for _, child in ipairs(children) do
                if child:IsA("TextLabel") then
                    labelCount = labelCount + 1
                end
            end
            if labelCount > 100 then
                for _, child in ipairs(children) do
                    if child:IsA("TextLabel") then
                        child:Destroy()
                        break
                    end
                end
            end

            -- Auto-scroll to bottom
            task.defer(function()
                pcall(function()
                    logScroll.CanvasPosition = Vector2.new(
                        0, logScroll.AbsoluteCanvasSize.Y
                    )
                end)
            end)
        end)
    end

    -- ── Footer ──
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, 0, 0, 15)
    footer.Position = UDim2.new(0, 0, 1, -15)
    footer.BackgroundTransparency = 1
    footer.Text = "Executor: " .. ExploitEnv.ExecutorName
        .. " | BaoSaveInstance v" .. BaoSaveInstance.Version
    footer.TextColor3 = Color3.fromRGB(80, 80, 100)
    footer.TextSize = 9
    footer.Font = Enum.Font.Gotham
    footer.Parent = mainFrame

    Log("GUI đã được tạo thành công", 4)
    return screenGui
end

-- ═══════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════

function BaoSaveInstance.Init()
    print("")
    print("╔══════════════════════════════════════════════════════════╗")
    print("║                                                          ║")
    print("║            BaoSaveInstance v" .. BaoSaveInstance.Version
        .. " - Initializing            ║")
    print("║         Ultimate Roblox Game Decompiler                  ║")
    print("║                                                          ║")
    print("╚══════════════════════════════════════════════════════════╝")
    print("")

    ResetStats()

    -- Phát hiện môi trường
    DetectEnvironment()

    -- Khởi tạo decompiler engines
    InitDecompilers()

    -- Tạo GUI nếu được bật
    if Config.ShowGUI then
        BaoSaveInstance.CreateGUI()
    end

    print("")
    Log("BaoSaveInstance đã sẵn sàng!", 4)
    Log("", 1)
    Log("Sử dụng:", 1)
    Log("  BaoSaveInstance.DecompileGame()    -- Decompile toàn bộ game", 1)
    Log("  BaoSaveInstance.DecompileMap()     -- Decompile map", 1)
    Log("  BaoSaveInstance.DecompileTerrain() -- Decompile terrain", 1)
    Log("  BaoSaveInstance.DecompileScript()  -- Decompile tất cả scripts", 1)
    Log("", 1)

    return BaoSaveInstance
end

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION API
-- ═══════════════════════════════════════════════════════════════

--- Thay đổi cấu hình
function BaoSaveInstance.SetConfig(key, value)
    if Config[key] ~= nil then
        Config[key] = value
        Log("Config." .. key .. " = " .. tostring(value), 1)
    else
        Log("Config key không tồn tại: " .. tostring(key), 2)
    end
end

--- Lấy cấu hình
function BaoSaveInstance.GetConfig(key)
    return Config[key]
end

--- Lấy statistics
function BaoSaveInstance.GetStats()
    return Stats
end

--- Lấy log history
function BaoSaveInstance.GetLogHistory()
    return LogHistory
end

--- Thêm custom decompiler engine
function BaoSaveInstance.AddDecompilerEngine(engine)
    if engine and engine.Name and engine.Init and engine.Decompile then
        table.insert(DecompilerEngines, engine)
        Log("Đã thêm custom decompiler: " .. engine.Name, 4)
    else
        Log("Engine không hợp lệ (cần Name, Init, Decompile)", 3)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO-INITIALIZE
-- ═══════════════════════════════════════════════════════════════

BaoSaveInstance.Init()

return BaoSaveInstance
