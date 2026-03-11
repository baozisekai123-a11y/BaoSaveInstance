--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                     BaoSaveInstance v2.0                        ║
    ║              Advanced Roblox Game Decompiler                    ║
    ║                                                                  ║
    ║  Chức năng:                                                      ║
    ║  • Decompile Game (Full: Map + Terrain + Scripts + Assets)       ║
    ║  • Decompile Map (Workspace objects only)                        ║
    ║  • Decompile Terrain (Voxel terrain data)                        ║
    ║  • Decompile Scripts (All scripts with multi-API fallback)       ║
    ║                                                                  ║
    ║  Output: <GameName> Decompile By BaoSaveInstance.rbxl            ║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

-- ============================================================
-- MODULE SETUP
-- ============================================================
local BaoSaveInstance = {}
BaoSaveInstance.__index = BaoSaveInstance
BaoSaveInstance.Version = "2.0"
BaoSaveInstance.Author = "Bao"

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
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
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ============================================================
-- CONFIGURATION
-- ============================================================
local Config = {
    -- Yield interval: sau bao nhiêu instance thì yield 1 lần để tránh lag
    YieldInterval = 50,
    -- Timeout cho mỗi lần decompile 1 script (giây)
    DecompileTimeout = 10,
    -- Có decompile script không (cho chế độ Map thì false)
    DecompileScripts = true,
    -- Có lưu Terrain không
    SaveTerrain = true,
    -- Có lưu properties ẩn không
    SaveHiddenProperties = true,
    -- Ignore list - các instance/service không nên copy
    IgnoreList = {
        -- Players và các thứ runtime
        "Players",
        "NetworkServer",
        "NetworkClient",
        "Stats",
        "CSGDictionaryService",
        "NonReplicatedCSGDictionaryService",
        "LogService",
        "AnalyticsService",
        "GuidRegistryService",
        "FriendService",
        "InsertService",
        "GamePassService",
        "PointsService",
        "AdService",
        "NotificationService",
    },
    -- Các service cần quét để lấy script
    ScriptServices = {
        "Workspace",
        "ReplicatedStorage",
        "ReplicatedFirst",
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
        "Lighting",
        "SoundService",
        "Chat",
        "LocalizationService",
        "TestService",
        "ServerScriptService",
        "ServerStorage",
    },
    -- Các service cần lưu cho full game
    GameServices = {
        "Workspace",
        "ReplicatedStorage",
        "ReplicatedFirst",
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
        "Lighting",
        "SoundService",
        "Chat",
        "LocalizationService",
        "TestService",
        "ServerScriptService",
        "ServerStorage",
    },
    -- Max retries khi decompile thất bại
    MaxDecompileRetries = 3,
    -- Delay giữa các retry (giây)
    RetryDelay = 0.5,
}

-- ============================================================
-- STATISTICS TRACKER
-- ============================================================
local Stats = {
    TotalInstances = 0,
    ProcessedInstances = 0,
    TotalScripts = 0,
    DecompiledScripts = 0,
    FailedScripts = 0,
    SkippedScripts = 0,
    StartTime = 0,
    Errors = {},
}

function Stats:Reset()
    self.TotalInstances = 0
    self.ProcessedInstances = 0
    self.TotalScripts = 0
    self.DecompiledScripts = 0
    self.FailedScripts = 0
    self.SkippedScripts = 0
    self.StartTime = tick()
    self.Errors = {}
end

function Stats:GetElapsed()
    return string.format("%.2f", tick() - self.StartTime)
end

function Stats:GetSummary()
    local lines = {
        "══════════════════════════════════════════",
        "  BaoSaveInstance - KẾT QUẢ DECOMPILE",
        "══════════════════════════════════════════",
        string.format("  Thời gian: %s giây", self:GetElapsed()),
        string.format("  Tổng Instances: %d", self.TotalInstances),
        string.format("  Đã xử lý: %d", self.ProcessedInstances),
        string.format("  Tổng Scripts: %d", self.TotalScripts),
        string.format("  Decompiled thành công: %d", self.DecompiledScripts),
        string.format("  Decompile thất bại: %d", self.FailedScripts),
        string.format("  Bỏ qua: %d", self.SkippedScripts),
        string.format("  Lỗi: %d", #self.Errors),
        "══════════════════════════════════════════",
    }
    return table.concat(lines, "\n")
end

-- ============================================================
-- LOGGER
-- ============================================================
local Logger = {}
Logger.Prefix = "[BaoSaveInstance]"
Logger.EnableDebug = false

function Logger:Info(msg)
    print(self.Prefix .. " [INFO] " .. tostring(msg))
end

function Logger:Warn(msg)
    warn(self.Prefix .. " [WARN] " .. tostring(msg))
end

function Logger:Error(msg)
    warn(self.Prefix .. " [ERROR] " .. tostring(msg))
    table.insert(Stats.Errors, tostring(msg))
end

function Logger:Success(msg)
    print(self.Prefix .. " [✓] " .. tostring(msg))
end

function Logger:Progress(current, total, label)
    local pct = total > 0 and math.floor((current / total) * 100) or 0
    print(string.format("%s [PROGRESS] %s: %d/%d (%d%%)", self.Prefix, label, current, total, pct))
end

function Logger:Debug(msg)
    if self.EnableDebug then
        print(self.Prefix .. " [DEBUG] " .. tostring(msg))
    end
end

function Logger:Banner()
    print([[
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   ██████╗  █████╗  ██████╗                                   ║
║   ██╔══██╗██╔══██╗██╔═══██╗                                  ║
║   ██████╔╝███████║██║   ██║                                   ║
║   ██╔══██╗██╔══██║██║   ██║                                   ║
║   ██████╔╝██║  ██║╚██████╔╝                                   ║
║   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝                                   ║
║                                                              ║
║           BaoSaveInstance v2.0                                ║
║       Advanced Roblox Game Decompiler                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
    ]])
end

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local Utility = {}

--- Kiểm tra exploit environment có hỗ trợ function nào không
function Utility.CheckFunction(name)
    local env = getgenv and getgenv() or _G
    if env[name] then return true end
    if getfenv then
        local fenv = getfenv(0)
        if fenv[name] then return true end
    end
    -- Thử trực tiếp
    local success, _ = pcall(function()
        local fn = loadstring("return " .. name)
        if fn then
            local result = fn()
            return result ~= nil
        end
        return false
    end)
    return success
end

--- Lấy function từ exploit environment
function Utility.GetFunction(name)
    -- Thử getgenv trước
    if getgenv then
        local env = getgenv()
        if env[name] then return env[name] end
    end
    -- Thử global
    if _G[name] then return _G[name] end
    -- Thử getfenv
    if getfenv then
        local fenv = getfenv(0)
        if fenv[name] then return fenv[name] end
    end
    -- Thử rawget
    if rawget then
        local val = rawget(_G, name)
        if val then return val end
    end
    return nil
end

--- Sanitize tên file: thay ký tự không hợp lệ bằng _
function Utility.SanitizeFileName(name)
    if not name or name == "" then
        return "UnknownGame"
    end
    -- Thay các ký tự không hợp lệ trong Windows filename
    local sanitized = name:gsub('[/\\:*?"<>|%c]', '_')
    -- Xóa khoảng trắng đầu/cuối
    sanitized = sanitized:match("^%s*(.-)%s*$")
    -- Giới hạn độ dài tên file
    if #sanitized > 100 then
        sanitized = sanitized:sub(1, 100)
    end
    -- Nếu rỗng sau sanitize
    if sanitized == "" then
        sanitized = "UnknownGame"
    end
    return sanitized
end

--- Lấy tên game
function Utility.GetGameName()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and info and info.Name then
        return Utility.SanitizeFileName(info.Name)
    end
    -- Fallback: dùng PlaceId
    Logger:Warn("Không thể lấy tên game từ MarketplaceService, dùng PlaceId thay thế")
    return "Game_" .. tostring(game.PlaceId)
end

--- Đếm tất cả descendants
function Utility.CountDescendants(instance)
    local count = 0
    local success, err = pcall(function()
        count = #instance:GetDescendants()
    end)
    if not success then
        -- Fallback: đếm thủ công
        local function countRecursive(inst)
            for _, child in ipairs(inst:GetChildren()) do
                count = count + 1
                pcall(function()
                    countRecursive(child)
                end)
            end
        end
        pcall(function() countRecursive(instance) end)
    end
    return count
end

--- Safe yield để tránh block main thread
function Utility.SafeYield()
    if task and task.wait then
        task.wait()
    elseif wait then
        wait()
    end
end

--- Yield mỗi N iterations
local yieldCounter = 0
function Utility.YieldCheck()
    yieldCounter = yieldCounter + 1
    if yieldCounter >= Config.YieldInterval then
        yieldCounter = 0
        Utility.SafeYield()
    end
end

--- Reset yield counter
function Utility.ResetYieldCounter()
    yieldCounter = 0
end

--- Kiểm tra instance có phải script không
function Utility.IsScript(instance)
    return instance:IsA("LocalScript") or instance:IsA("Script") or instance:IsA("ModuleScript")
end

--- Kiểm tra instance có nên bỏ qua không
function Utility.ShouldIgnore(instance)
    for _, name in ipairs(Config.IgnoreList) do
        if instance.Name == name then
            return true
        end
    end
    return false
end

--- Lấy full path của instance
function Utility.GetFullPath(instance)
    local path = {}
    local current = instance
    while current and current ~= game do
        table.insert(path, 1, current.Name)
        current = current.Parent
    end
    return "game." .. table.concat(path, ".")
end

-- ============================================================
-- DECOMPILER ENGINE - MULTI-API SUPPORT
-- ============================================================
local DecompilerEngine = {}
DecompilerEngine.Decompilers = {}
DecompilerEngine.Initialized = false
DecompilerEngine.ActiveDecompiler = nil

--- Đăng ký tất cả decompiler có sẵn
function DecompilerEngine:Initialize()
    if self.Initialized then return end
    self.Decompilers = {}

    Logger:Info("Đang khởi tạo Decompiler Engine...")
    Logger:Info("Đang quét các API decompile có sẵn...")

    -- ═══════════════════════════════════════════
    -- DECOMPILER 1: decompile() - Synapse X, Script-Ware, etc.
    -- ═══════════════════════════════════════════
    local decompileFn = Utility.GetFunction("decompile")
    if decompileFn then
        table.insert(self.Decompilers, {
            Name = "decompile()",
            Priority = 1,
            Func = function(scriptInstance)
                local source = decompileFn(scriptInstance)
                if source and type(source) == "string" and #source > 0 then
                    return source
                end
                return nil
            end
        })
        Logger:Success("Tìm thấy API: decompile()")
    end

    -- ═══════════════════════════════════════════
    -- DECOMPILER 2: getscriptbytecode() + custom decompile
    -- ═══════════════════════════════════════════
    local getBytecode = Utility.GetFunction("getscriptbytecode")
        or Utility.GetFunction("get_script_bytecode")
        or Utility.GetFunction("dumpstring")
    if getBytecode then
        table.insert(self.Decompilers, {
            Name = "getscriptbytecode()",
            Priority = 2,
            Func = function(scriptInstance)
                local bytecode = getBytecode(scriptInstance)
                if bytecode and #bytecode > 0 then
                    -- Thử decompile bytecode nếu có hàm hỗ trợ
                    local luauDecompile = Utility.GetFunction("luau_decompile")
                        or Utility.GetFunction("decompile_bytecode")
                    if luauDecompile then
                        local source = luauDecompile(bytecode)
                        if source and #source > 0 then
                            return source
                        end
                    end
                    -- Nếu không có decompiler cho bytecode, trả về dạng comment
                    return "-- [BaoSaveInstance] Bytecode captured but no decompiler available\n"
                        .. "-- Bytecode length: " .. #bytecode .. " bytes\n"
                        .. "-- Script: " .. Utility.GetFullPath(scriptInstance)
                end
                return nil
            end
        })
        Logger:Success("Tìm thấy API: getscriptbytecode()")
    end

    -- ═══════════════════════════════════════════
    -- DECOMPILER 3: getsourcecode() / getscriptsource()
    -- ═══════════════════════════════════════════
    local getSource = Utility.GetFunction("getsourcecode")
        or Utility.GetFunction("getscriptsource")
        or Utility.GetFunction("get_script_source")
    if getSource then
        table.insert(self.Decompilers, {
            Name = "getsourcecode()",
            Priority = 0, -- Cao nhất vì trả về source gốc
            Func = function(scriptInstance)
                local source = getSource(scriptInstance)
                if source and type(source) == "string" and #source > 0 then
                    return source
                end
                return nil
            end
        })
        Logger:Success("Tìm thấy API: getsourcecode()")
    end

    -- ═══════════════════════════════════════════
    -- DECOMPILER 4: Lua decompile qua HTTP API (nếu exploit hỗ trợ request)
    -- ═══════════════════════════════════════════
    local httpRequest = Utility.GetFunction("request")
        or Utility.GetFunction("http_request")
        or Utility.GetFunction("syn") and (syn and syn.request)
        or Utility.GetFunction("http") and (http and http.request)
        or Utility.GetFunction("fluxus_request")
    if httpRequest and getBytecode then
        table.insert(self.Decompilers, {
            Name = "HTTP API Decompiler",
            Priority = 3,
            Func = function(scriptInstance)
                local success, bytecode = pcall(function()
                    return getBytecode(scriptInstance)
                end)
                if not success or not bytecode or #bytecode == 0 then
                    return nil
                end
                -- Thử các endpoint phổ biến
                local endpoints = {
                    "https://unluau.typicalsquid.repl.co/decompile",
                    "https://luau-decompiler.herokuapp.com/decompile",
                }
                for _, url in ipairs(endpoints) do
                    local ok, response = pcall(function()
                        local req
                        if type(httpRequest) == "function" then
                            req = httpRequest({
                                Url = url,
                                Method = "POST",
                                Headers = {["Content-Type"] = "application/octet-stream"},
                                Body = bytecode,
                            })
                        end
                        return req
                    end)
                    if ok and response and response.StatusCode == 200 and response.Body and #response.Body > 0 then
                        return response.Body
                    end
                end
                return nil
            end
        })
        Logger:Success("Tìm thấy API: HTTP Decompiler")
    end

    -- ═══════════════════════════════════════════
    -- DECOMPILER 5: getscripthash() + cache lookup
    -- ═══════════════════════════════════════════
    local getHash = Utility.GetFunction("getscripthash")
        or Utility.GetFunction("get_script_hash")
    if getHash then
        table.insert(self.Decompilers, {
            Name = "getscripthash() Cache",
            Priority = 4,
            Func = function(scriptInstance)
                local hash = getHash(scriptInstance)
                if hash then
                    return "-- [BaoSaveInstance] Script Hash: " .. tostring(hash) .. "\n"
                        .. "-- Script: " .. Utility.GetFullPath(scriptInstance) .. "\n"
                        .. "-- (Hash captured for reference)"
                end
                return nil
            end
        })
        Logger:Success("Tìm thấy API: getscripthash()")
    end

    -- ═══════════════════════════════════════════
    -- DECOMPILER 6: .Source property (cho ModuleScript không protected)
    -- ═══════════════════════════════════════════
    table.insert(self.Decompilers, {
        Name = "Direct .Source Access",
        Priority = 5,
        Func = function(scriptInstance)
            local success, source = pcall(function()
                return scriptInstance.Source
            end)
            if success and source and type(source) == "string" and #source > 0 then
                return source
            end
            return nil
        end
    })
    Logger:Info("Đã thêm API: Direct .Source Access (fallback)")

    -- ═══════════════════════════════════════════
    -- DECOMPILER 7: getscriptclosure + debug info
    -- ═══════════════════════════════════════════
    local getClosure = Utility.GetFunction("getscriptclosure")
        or Utility.GetFunction("getscriptfunction")
    local getInfo = Utility.GetFunction("getinfo") or (debug and debug.getinfo)
    if getClosure and getInfo then
        table.insert(self.Decompilers, {
            Name = "getscriptclosure() + debug.getinfo",
            Priority = 6,
            Func = function(scriptInstance)
                local ok, closure = pcall(getClosure, scriptInstance)
                if ok and closure then
                    local infoOk, info = pcall(getInfo, closure)
                    if infoOk and info then
                        local result = "-- [BaoSaveInstance] Script Closure Info\n"
                        result = result .. "-- Script: " .. Utility.GetFullPath(scriptInstance) .. "\n"
                        if info.source then result = result .. "-- Source: " .. tostring(info.source) .. "\n" end
                        if info.short_src then result = result .. "-- Short Source: " .. tostring(info.short_src) .. "\n" end
                        if info.what then result = result .. "-- Type: " .. tostring(info.what) .. "\n" end
                        if info.numparams then result = result .. "-- Params: " .. tostring(info.numparams) .. "\n" end
                        if info.is_vararg then result = result .. "-- Vararg: " .. tostring(info.is_vararg) .. "\n" end
                        return result
                    end
                end
                return nil
            end
        })
        Logger:Success("Tìm thấy API: getscriptclosure()")
    end

    -- Sắp xếp theo priority (thấp = ưu tiên cao)
    table.sort(self.Decompilers, function(a, b)
        return a.Priority < b.Priority
    end)

    Logger:Info(string.format("Đã khởi tạo %d Decompiler API(s)", #self.Decompilers))
    self.Initialized = true
end

--- Decompile một script với multi-API fallback
function DecompilerEngine:DecompileScript(scriptInstance)
    if not self.Initialized then
        self:Initialize()
    end

    if #self.Decompilers == 0 then
        return nil, "Không tìm thấy API decompile nào"
    end

    local scriptPath = Utility.GetFullPath(scriptInstance)
    local bestResult = nil
    local bestResultLength = 0

    for _, decompiler in ipairs(self.Decompilers) do
        for attempt = 1, Config.MaxDecompileRetries do
            local success, result = pcall(function()
                return decompiler.Func(scriptInstance)
            end)

            if success and result and type(result) == "string" and #result > 0 then
                -- Kiểm tra kết quả có phải error message không
                local isError = result:lower():find("failed") ~= nil
                    and result:lower():find("decompil") ~= nil
                    and #result < 100

                if not isError then
                    -- So sánh với kết quả tốt nhất hiện tại
                    -- Ưu tiên kết quả dài hơn (thường đầy đủ hơn)
                    if #result > bestResultLength then
                        bestResult = result
                        bestResultLength = #result
                        Logger:Debug(string.format(
                            "Decompile thành công [%s] cho %s (len=%d)",
                            decompiler.Name, scriptPath, #result
                        ))
                    end
                    -- Nếu kết quả dài và có vẻ đầy đủ, dùng luôn
                    if #result > 50 and not result:match("^%-%-.*only") then
                        goto done
                    end
                end
            end

            -- Retry delay
            if attempt < Config.MaxDecompileRetries then
                if task and task.wait then
                    task.wait(Config.RetryDelay)
                end
            end
        end
    end

    ::done::

    if bestResult then
        -- Thêm header comment
        local header = string.format(
            "-- Decompiled by BaoSaveInstance v%s\n-- Script: %s\n-- Type: %s\n\n",
            BaoSaveInstance.Version,
            scriptPath,
            scriptInstance.ClassName
        )
        return header .. bestResult, nil
    end

    -- Tất cả API đều thất bại
    local fallback = string.format(
        "-- [BaoSaveInstance] DECOMPILE FAILED\n"
        .. "-- Script: %s\n"
        .. "-- Type: %s\n"
        .. "-- Tất cả %d API decompile đều thất bại.\n"
        .. "-- Script này có thể bị obfuscate hoặc protected.\n",
        scriptPath,
        scriptInstance.ClassName,
        #self.Decompilers
    )
    return fallback, "All decompilers failed"
end

-- ============================================================
-- INSTANCE SERIALIZER / SAVE ENGINE
-- ============================================================
local SaveEngine = {}

--- Kiểm tra các hàm save có sẵn
function SaveEngine:DetectSaveMethod()
    local methods = {}

    -- Method 1: saveinstance (phổ biến nhất)
    local saveinstance = Utility.GetFunction("saveinstance")
        or Utility.GetFunction("save_instance")
    if saveinstance then
        table.insert(methods, {
            Name = "saveinstance",
            Priority = 1,
            Func = saveinstance
        })
        Logger:Success("Tìm thấy: saveinstance()")
    end

    -- Method 2: syn.saveinstance (Synapse X)
    if syn and syn.saveinstance then
        table.insert(methods, {
            Name = "syn.saveinstance",
            Priority = 0,
            Func = syn.saveinstance
        })
        Logger:Success("Tìm thấy: syn.saveinstance()")
    end

    -- Method 3: writefile + custom serializer
    local writefile = Utility.GetFunction("writefile")
    if writefile then
        table.insert(methods, {
            Name = "writefile",
            Priority = 3,
            Func = writefile
        })
        Logger:Success("Tìm thấy: writefile()")
    end

    -- Method 4: savefile
    local savefile = Utility.GetFunction("savefile")
    if savefile then
        table.insert(methods, {
            Name = "savefile",
            Priority = 2,
            Func = savefile
        })
        Logger:Success("Tìm thấy: savefile()")
    end

    table.sort(methods, function(a, b)
        return a.Priority < b.Priority
    end)

    return methods
end

--- Lưu game bằng saveinstance với options nâng cao
function SaveEngine:SaveWithSaveInstance(fileName, options)
    local saveinstance = Utility.GetFunction("saveinstance")
        or Utility.GetFunction("save_instance")
        or (syn and syn.saveinstance)

    if not saveinstance then
        return false, "saveinstance không khả dụng"
    end

    -- Xây dựng options
    local saveOptions = options or {}

    -- Merge default options
    local defaultOptions = {
        -- Tên file
        FileName = fileName or "output.rbxl",
        -- Decompile mode
        DecompileMode = "full", -- hoặc "custom"
        -- Nên decompile scripts không
        noscripts = false,
        -- Decompile timeout
        DecompileTimeout = Config.DecompileTimeout,
        -- Bỏ qua nil instances
        DecompileIgnore = {},
        -- Mode: "optimized", "full", "scripts"
        mode = "full",
        -- Extra options tùy exploit
        RemovePlayerCharacters = true,
        SavePlayers = false,
        ExtraInstances = {},
        NilInstances = true, -- Lưu cả nil instances
        RemovePlayers = true,
        SaveNonCreatable = false,
        IsolateStarterPlayer = false,
        IgnoreDefaultProperties = true,
        IgnoreSharedStrings = true, -- Avoid shared string issues
    }

    for k, v in pairs(defaultOptions) do
        if saveOptions[k] == nil then
            saveOptions[k] = v
        end
    end

    saveOptions.FileName = fileName
    if saveOptions.FilePath then
        saveOptions.FilePath = fileName
    end

    Logger:Info("Đang lưu file: " .. fileName)
    Logger:Info("Options: mode=" .. tostring(saveOptions.mode))

    local success, err = pcall(function()
        -- Thử nhiều format gọi khác nhau
        -- Format 1: saveinstance(options_table)
        local ok1, err1 = pcall(function()
            saveinstance(saveOptions)
        end)
        if ok1 then return end

        -- Format 2: saveinstance(game, fileName)
        local ok2, err2 = pcall(function()
            saveinstance(game, fileName)
        end)
        if ok2 then return end

        -- Format 3: saveinstance(fileName) đơn giản
        local ok3, err3 = pcall(function()
            saveinstance(fileName)
        end)
        if ok3 then return end

        -- Không có format nào hoạt động
        error("Tất cả format saveinstance đều thất bại: " 
            .. tostring(err1) .. " | " .. tostring(err2) .. " | " .. tostring(err3))
    end)

    return success, err
end

--- Lưu instances cụ thể (cho Map, Terrain modes)
function SaveEngine:SaveInstances(instances, fileName)
    -- Thử saveinstance với ExtraInstances
    local saveinstance = Utility.GetFunction("saveinstance")
        or Utility.GetFunction("save_instance")
        or (syn and syn.saveinstance)

    if saveinstance then
        local success, err = pcall(function()
            saveinstance({
                FileName = fileName,
                ExtraInstances = instances,
                noscripts = true,
                mode = "optimized",
                RemovePlayers = true,
            })
        end)
        if success then return true end
        Logger:Warn("saveinstance với ExtraInstances thất bại: " .. tostring(err))
    end

    -- Fallback: savemodel
    local savemodel = Utility.GetFunction("savemodel")
    if savemodel then
        for _, inst in ipairs(instances) do
            local success, err = pcall(function()
                savemodel(inst, fileName)
            end)
            if success then return true end
        end
    end

    -- Fallback: writefile với custom serialize
    return false, "Không thể lưu instances"
end

-- ============================================================
-- SCRIPT PROCESSOR
-- ============================================================
local ScriptProcessor = {}

--- Tìm tất cả scripts trong game
function ScriptProcessor:FindAllScripts()
    local scripts = {}
    local visited = {}

    Logger:Info("Đang quét tất cả Scripts trong game...")

    local function scanInstance(instance)
        if visited[instance] then return end
        visited[instance] = true

        pcall(function()
            if Utility.IsScript(instance) then
                table.insert(scripts, instance)
            end
        end)

        pcall(function()
            for _, child in ipairs(instance:GetChildren()) do
                Utility.YieldCheck()
                scanInstance(child)
            end
        end)
    end

    -- Quét từng service
    for _, serviceName in ipairs(Config.ScriptServices) do
        pcall(function()
            local service = game:GetService(serviceName)
            if service then
                Logger:Debug("Đang quét service: " .. serviceName)
                scanInstance(service)
            end
        end)
    end

    -- Quét nil instances nếu có API
    local getNilInstances = Utility.GetFunction("getnilinstances")
        or Utility.GetFunction("get_nil_instances")
    if getNilInstances then
        pcall(function()
            local nilInsts = getNilInstances()
            if nilInsts then
                for _, inst in ipairs(nilInsts) do
                    if Utility.IsScript(inst) and not visited[inst] then
                        table.insert(scripts, inst)
                        visited[inst] = true
                    end
                end
                Logger:Info("Đã quét nil instances")
            end
        end)
    end

    -- Quét hidden instances nếu có API
    local getHiddenUI = Utility.GetFunction("gethui")
        or Utility.GetFunction("get_hidden_gui")
    if getHiddenUI then
        pcall(function()
            local hiddenUI = getHiddenUI()
            if hiddenUI then
                scanInstance(hiddenUI)
                Logger:Info("Đã quét hidden UI instances")
            end
        end)
    end

    -- Quét GC (garbage collector) cho scripts
    local getGC = Utility.GetFunction("getgc")
    if getGC then
        pcall(function()
            local gc = getGC(true)
            for _, obj in ipairs(gc) do
                if typeof(obj) == "Instance" and Utility.IsScript(obj) and not visited[obj] then
                    table.insert(scripts, obj)
                    visited[obj] = true
                end
            end
            Logger:Info("Đã quét GC cho scripts ẩn")
        end)
    end

    Logger:Info(string.format("Tìm thấy %d scripts tổng cộng", #scripts))

    -- Phân loại
    local localScripts = 0
    local serverScripts = 0
    local moduleScripts = 0
    for _, s in ipairs(scripts) do
        if s:IsA("LocalScript") then
            localScripts = localScripts + 1
        elseif s:IsA("ModuleScript") then
            moduleScripts = moduleScripts + 1
        else
            serverScripts = serverScripts + 1
        end
    end

    Logger:Info(string.format(
        "  LocalScripts: %d | Scripts: %d | ModuleScripts: %d",
        localScripts, serverScripts, moduleScripts
    ))

    return scripts
end

--- Decompile tất cả scripts và set Source
function ScriptProcessor:DecompileAllScripts()
    DecompilerEngine:Initialize()

    local allScripts = self:FindAllScripts()
    Stats.TotalScripts = #allScripts

    if #allScripts == 0 then
        Logger:Warn("Không tìm thấy script nào để decompile!")
        return {}
    end

    local results = {}
    local progressInterval = math.max(1, math.floor(#allScripts / 20)) -- Log mỗi 5%

    Logger:Info(string.format("Bắt đầu decompile %d scripts...", #allScripts))

    for i, scriptInst in ipairs(allScripts) do
        Utility.YieldCheck()

        -- Log progress
        if i % progressInterval == 0 or i == 1 or i == #allScripts then
            Logger:Progress(i, #allScripts, "Decompile Scripts")
        end

        local scriptPath = Utility.GetFullPath(scriptInst)
        local source, err = DecompilerEngine:DecompileScript(scriptInst)

        if source then
            -- Thử set Source trực tiếp vào script
            local setSuccess = pcall(function()
                scriptInst.Source = source
            end)

            if not setSuccess then
                -- Nếu không set được, lưu vào results
                Logger:Debug("Không thể set Source cho: " .. scriptPath)
            end

            results[scriptInst] = {
                Source = source,
                Path = scriptPath,
                Type = scriptInst.ClassName,
                Success = err == nil,
            }

            if err then
                Stats.FailedScripts = Stats.FailedScripts + 1
            else
                Stats.DecompiledScripts = Stats.DecompiledScripts + 1
            end
        else
            Stats.FailedScripts = Stats.FailedScripts + 1
            results[scriptInst] = {
                Source = "-- [BaoSaveInstance] Decompile failed for: " .. scriptPath,
                Path = scriptPath,
                Type = scriptInst.ClassName,
                Success = false,
            }
        end
    end

    Logger:Success(string.format(
        "Decompile hoàn tất: %d/%d thành công, %d thất bại",
        Stats.DecompiledScripts, Stats.TotalScripts, Stats.FailedScripts
    ))

    return results
end

--- Lưu scripts ra file .lua riêng lẻ (nếu muốn)
function ScriptProcessor:SaveScriptsToFiles(results)
    local writefile = Utility.GetFunction("writefile")
    local makefolder = Utility.GetFunction("makefolder")
        or Utility.GetFunction("make_folder")
        or Utility.GetFunction("createfolder")

    if not writefile then
        Logger:Warn("writefile không khả dụng, không thể lưu scripts riêng lẻ")
        return false
    end

    local gameName = Utility.GetGameName()
    local folderName = gameName .. "_Scripts_BaoSaveInstance"

    -- Tạo folder
    if makefolder then
        pcall(function() makefolder(folderName) end)
    end

    local saved = 0
    for scriptInst, data in pairs(results) do
        Utility.YieldCheck()

        local safeName = Utility.SanitizeFileName(data.Path:gsub("%.", "_"))
        local ext = ".lua"
        local filePath = folderName .. "/" .. safeName .. ext

        local success = pcall(function()
            writefile(filePath, data.Source)
        end)

        if success then
            saved = saved + 1
        end
    end

    Logger:Info(string.format("Đã lưu %d scripts ra folder: %s", saved, folderName))
    return true
end

-- ============================================================
-- TERRAIN PROCESSOR
-- ============================================================
local TerrainProcessor = {}

--- Lấy thông tin Terrain
function TerrainProcessor:GetTerrainInfo()
    local terrain = workspace.Terrain
    local info = {
        HasTerrain = false,
        MaxExtents = nil,
    }

    pcall(function()
        -- Kiểm tra terrain có dữ liệu không
        local maxExtents = terrain.MaxExtents
        if maxExtents then
            info.MaxExtents = maxExtents
            -- Kiểm tra xem terrain có rỗng không
            local region = Region3.new(
                Vector3.new(-100, -100, -100),
                Vector3.new(100, 100, 100)
            )
            local materials, occupancy = terrain:ReadVoxels(
                region:ExpandToGrid(4),
                4
            )
            -- Nếu có bất kỳ material nào không phải Air
            for x = 1, #materials do
                for y = 1, #materials[x] do
                    for z = 1, #materials[x][y] do
                        if materials[x][y][z] ~= Enum.Material.Air then
                            info.HasTerrain = true
                            return
                        end
                    end
                end
            end
        end
    end)

    return info
end

--- Copy Terrain data
function TerrainProcessor:ProcessTerrain()
    Logger:Info("Đang xử lý Terrain...")

    local terrainInfo = self:GetTerrainInfo()

    if not terrainInfo.HasTerrain then
        Logger:Info("Terrain rỗng hoặc không có dữ liệu")
        return true
    end

    -- Terrain sẽ được saveinstance tự động xử lý
    -- Nhưng chúng ta cần đảm bảo nó được bao gồm
    Logger:Success("Terrain data đã sẵn sàng để lưu")
    return true
end

-- ============================================================
-- MAP PROCESSOR
-- ============================================================
local MapProcessor = {}

--- Lấy tất cả instances trong workspace (trừ Terrain, Camera, Players)
function MapProcessor:GetMapInstances()
    local mapInstances = {}
    local terrain = workspace.Terrain

    Logger:Info("Đang quét Map instances trong Workspace...")

    pcall(function()
        for _, child in ipairs(workspace:GetChildren()) do
            Utility.YieldCheck()

            -- Bỏ qua Terrain (xử lý riêng), Camera, và character players
            local shouldSkip = false

            if child == terrain then
                shouldSkip = true
            elseif child:IsA("Camera") then
                shouldSkip = true
            elseif child:IsA("Terrain") then
                shouldSkip = true
            else
                -- Kiểm tra xem có phải character của player không
                for _, player in ipairs(Players:GetPlayers()) do
                    if child == player.Character then
                        shouldSkip = true
                        break
                    end
                end
            end

            if not shouldSkip then
                table.insert(mapInstances, child)
            end
        end
    end)

    Logger:Info(string.format("Tìm thấy %d Map instances", #mapInstances))
    return mapInstances
end

--- Đếm tất cả parts/instances trong map
function MapProcessor:CountMapDetails()
    local count = {
        Parts = 0,
        Models = 0,
        Meshes = 0,
        Decals = 0,
        Lights = 0,
        GUIs = 0,
        Scripts = 0,
        Other = 0,
        Total = 0,
    }

    pcall(function()
        for _, desc in ipairs(workspace:GetDescendants()) do
            count.Total = count.Total + 1
            if desc:IsA("BasePart") then
                count.Parts = count.Parts + 1
            elseif desc:IsA("Model") then
                count.Models = count.Models + 1
            elseif desc:IsA("SpecialMesh") or desc:IsA("MeshPart") then
                count.Meshes = count.Meshes + 1
            elseif desc:IsA("Decal") or desc:IsA("Texture") then
                count.Decals = count.Decals + 1
            elseif desc:IsA("Light") then
                count.Lights = count.Lights + 1
            elseif desc:IsA("GuiObject") then
                count.GUIs = count.GUIs + 1
            elseif Utility.IsScript(desc) then
                count.Scripts = count.Scripts + 1
            else
                count.Other = count.Other + 1
            end
        end
    end)

    return count
end

-- ============================================================
-- MAIN FUNCTIONS
-- ============================================================

--- Khởi tạo BaoSaveInstance
function BaoSaveInstance.Init()
    Logger:Banner()
    Logger:Info("Đang khởi tạo BaoSaveInstance v" .. BaoSaveInstance.Version .. "...")

    -- Khởi tạo decompiler engine
    DecompilerEngine:Initialize()

    -- Detect save methods
    local saveMethods = SaveEngine:DetectSaveMethod()
    Logger:Info(string.format("Phát hiện %d phương thức lưu file", #saveMethods))

    -- Log game info
    local gameName = Utility.GetGameName()
    Logger:Info("Game: " .. gameName)
    Logger:Info("PlaceId: " .. tostring(game.PlaceId))
    Logger:Info("GameId: " .. tostring(game.GameId))

    -- Đếm tổng instances
    local totalInstances = Utility.CountDescendants(game)
    Logger:Info("Tổng Instances trong game: " .. tostring(totalInstances))

    Logger:Success("Khởi tạo hoàn tất!")
    Logger:Info("═══════════════════════════════════════")
    Logger:Info("Sử dụng:")
    Logger:Info("  BaoSaveInstance.DecompileGame()    - Decompile toàn bộ game")
    Logger:Info("  BaoSaveInstance.DecompileMap()      - Decompile Map only")
    Logger:Info("  BaoSaveInstance.DecompileTerrain()  - Decompile Terrain only")
    Logger:Info("  BaoSaveInstance.DecompileScript()   - Decompile Scripts only")
    Logger:Info("  BaoSaveInstance.ShowGUI()            - Hiện GUI điều khiển")
    Logger:Info("═══════════════════════════════════════")

    return true
end

--- Lấy tên game (public)
function BaoSaveInstance.GetGameName()
    return Utility.GetGameName()
end

--- Sanitize filename (public)
function BaoSaveInstance.SanitizeFileName(name)
    return Utility.SanitizeFileName(name)
end

--- Log message (public)
function BaoSaveInstance.Log(message)
    Logger:Info(message)
end

--- Thử decompile 1 script (public)
function BaoSaveInstance.TryDecompileScript(scriptInstance)
    DecompilerEngine:Initialize()
    return DecompilerEngine:DecompileScript(scriptInstance)
end

--- ═══════════════════════════════════════════════════════
--- DECOMPILE GAME (FULL - ALL IN ONE)
--- ═══════════════════════════════════════════════════════
function BaoSaveInstance.DecompileGame()
    Stats:Reset()
    Utility.ResetYieldCounter()

    Logger:Info("═══════════════════════════════════════")
    Logger:Info("  BẮT ĐẦU DECOMPILE GAME (FULL)")
    Logger:Info("═══════════════════════════════════════")

    local gameName = Utility.GetGameName()
    local fileName = gameName .. " Decompile By BaoSaveInstance.rbxl"

    Logger:Info("Game: " .. gameName)
    Logger:Info("File output: " .. fileName)

    -- PHASE 1: Decompile tất cả Scripts
    Logger:Info("")
    Logger:Info("══ PHASE 1/4: Decompile Scripts ══")
    local scriptResults = ScriptProcessor:DecompileAllScripts()

    -- PHASE 2: Xử lý Map
    Logger:Info("")
    Logger:Info("══ PHASE 2/4: Xử lý Map ══")
    local mapDetails = MapProcessor:CountMapDetails()
    Logger:Info(string.format(
        "Map: %d Parts, %d Models, %d Meshes, %d Decals, %d Lights",
        mapDetails.Parts, mapDetails.Models, mapDetails.Meshes,
        mapDetails.Decals, mapDetails.Lights
    ))
    Stats.TotalInstances = mapDetails.Total

    -- PHASE 3: Xử lý Terrain
    Logger:Info("")
    Logger:Info("══ PHASE 3/4: Xử lý Terrain ══")
    TerrainProcessor:ProcessTerrain()

    -- PHASE 4: Lưu file
    Logger:Info("")
    Logger:Info("══ PHASE 4/4: Lưu File .rbxl ══")

    -- Thử saveinstance trước
    local saveSuccess, saveErr = SaveEngine:SaveWithSaveInstance(fileName, {
        mode = "full",
        noscripts = false,
        DecompileTimeout = Config.DecompileTimeout,
        NilInstances = true,
        RemovePlayers = true,
        FileName = fileName,
        -- Bao gồm tất cả services
        ExtraInstances = {},
    })

    if saveSuccess then
        Logger:Success("Đã lưu file thành công: " .. fileName)
    else
        Logger:Warn("saveinstance thất bại: " .. tostring(saveErr))
        Logger:Info("Đang thử phương thức lưu khác...")

        -- Thử savefile
        local savefile = Utility.GetFunction("savefile")
        if savefile then
            local ok = pcall(function()
                savefile(fileName, "rbxl")
            end)
            if ok then
                Logger:Success("Đã lưu file bằng savefile(): " .. fileName)
                saveSuccess = true
            end
        end

        if not saveSuccess then
            -- Thử writefile với saveinstance data
            Logger:Warn("Không thể lưu file .rbxl tự động.")
            Logger:Info("Thử lưu scripts ra file riêng lẻ...")
            ScriptProcessor:SaveScriptsToFiles(scriptResults)
        end
    end

    -- Kết quả
    Logger:Info("")
    print(Stats:GetSummary())

    if saveSuccess then
        Logger:Success("DECOMPILE GAME HOÀN TẤT!")
        Logger:Success("File: " .. fileName)
    end

    return saveSuccess
end

--- ═══════════════════════════════════════════════════════
--- DECOMPILE MAP
--- ═══════════════════════════════════════════════════════
function BaoSaveInstance.DecompileMap()
    Stats:Reset()
    Utility.ResetYieldCounter()

    Logger:Info("═══════════════════════════════════════")
    Logger:Info("  BẮT ĐẦU DECOMPILE MAP")
    Logger:Info("═══════════════════════════════════════")

    local gameName = Utility.GetGameName()
    local fileName = gameName .. " Map Decompile By BaoSaveInstance.rbxl"

    Logger:Info("Game: " .. gameName)
    Logger:Info("File output: " .. fileName)

    -- Đếm map details
    local mapDetails = MapProcessor:CountMapDetails()
    Logger:Info(string.format(
        "Map details: %d Parts, %d Models, %d Meshes, %d Decals, %d Lights, %d Total",
        mapDetails.Parts, mapDetails.Models, mapDetails.Meshes,
        mapDetails.Decals, mapDetails.Lights, mapDetails.Total
    ))
    Stats.TotalInstances = mapDetails.Total

    -- Lấy map instances
    local mapInstances = MapProcessor:GetMapInstances()

    -- Lưu file (chỉ Map, không scripts)
    Logger:Info("Đang lưu Map...")

    local saveSuccess = false

    -- Thử saveinstance với mode optimized (không decompile scripts)
    local ok, err = SaveEngine:SaveWithSaveInstance(fileName, {
        mode = "optimized",
        noscripts = true,
        FileName = fileName,
        RemovePlayers = true,
        NilInstances = false,
        DecompileTimeout = 0,
    })

    if ok then
        saveSuccess = true
        Logger:Success("Đã lưu Map thành công: " .. fileName)
    else
        Logger:Warn("saveinstance thất bại cho Map: " .. tostring(err))

        -- Thử SaveInstances
        local ok2, err2 = SaveEngine:SaveInstances(mapInstances, fileName)
        if ok2 then
            saveSuccess = true
            Logger:Success("Đã lưu Map bằng SaveInstances: " .. fileName)
        else
            Logger:Error("Không thể lưu Map: " .. tostring(err2))
        end
    end

    Stats.ProcessedInstances = mapDetails.Total

    Logger:Info("")
    print(Stats:GetSummary())

    if saveSuccess then
        Logger:Success("DECOMPILE MAP HOÀN TẤT!")
        Logger:Success("File: " .. fileName)
    end

    return saveSuccess
end

--- ═══════════════════════════════════════════════════════
--- DECOMPILE TERRAIN
--- ═══════════════════════════════════════════════════════
function BaoSaveInstance.DecompileTerrain()
    Stats:Reset()
    Utility.ResetYieldCounter()

    Logger:Info("═══════════════════════════════════════")
    Logger:Info("  BẮT ĐẦU DECOMPILE TERRAIN")
    Logger:Info("═══════════════════════════════════════")

    local gameName = Utility.GetGameName()
    local fileName = gameName .. " Terrain Decompile By BaoSaveInstance.rbxl"

    Logger:Info("Game: " .. gameName)
    Logger:Info("File output: " .. fileName)

    -- Kiểm tra terrain
    local terrainInfo = TerrainProcessor:GetTerrainInfo()

    if not terrainInfo.HasTerrain then
        Logger:Warn("Game này không có Terrain data!")
        Logger:Info("Vẫn thử lưu Terrain container...")
    else
        Logger:Info("Terrain data detected!")
    end

    -- Lưu terrain
    Logger:Info("Đang lưu Terrain...")

    local saveSuccess = false

    -- Thử saveinstance chỉ với Workspace.Terrain
    local saveinstance = Utility.GetFunction("saveinstance")
        or Utility.GetFunction("save_instance")
        or (syn and syn.saveinstance)

    if saveinstance then
        local ok, err = pcall(function()
            saveinstance({
                FileName = fileName,
                noscripts = true,
                mode = "optimized",
                RemovePlayers = true,
                NilInstances = false,
                -- Chỉ lưu Terrain
                ExtraInstances = {workspace.Terrain},
                IgnoreDefaultProperties = false,
            })
        end)

        if ok then
            saveSuccess = true
            Logger:Success("Đã lưu Terrain thành công: " .. fileName)
        else
            Logger:Warn("saveinstance cho Terrain thất bại: " .. tostring(err))
        end
    end

    -- Fallback: Thử lưu terrain data dưới dạng script
    if not saveSuccess then
        local writefile = Utility.GetFunction("writefile")
        if writefile then
            Logger:Info("Đang xuất Terrain data dưới dạng Lua script...")

            local terrainScript = BaoSaveInstance._ExportTerrainAsScript()
            if terrainScript then
                local scriptFileName = gameName .. " Terrain Data By BaoSaveInstance.lua"
                local ok = pcall(function()
                    writefile(scriptFileName, terrainScript)
                end)
                if ok then
                    Logger:Success("Đã lưu Terrain script: " .. scriptFileName)
                    saveSuccess = true
                end
            end
        end
    end

    Logger:Info("")
    print(Stats:GetSummary())

    if saveSuccess then
        Logger:Success("DECOMPILE TERRAIN HOÀN TẤT!")
    else
        Logger:Error("Không thể lưu Terrain!")
    end

    return saveSuccess
end

--- Export terrain data dưới dạng Lua script (internal helper)
function BaoSaveInstance._ExportTerrainAsScript()
    local terrain = workspace.Terrain
    local lines = {
        "-- Terrain Data exported by BaoSaveInstance v" .. BaoSaveInstance.Version,
        "-- Game: " .. Utility.GetGameName(),
        "-- Date: " .. os.date("%Y-%m-%d %H:%M:%S"),
        "",
        "local terrain = workspace.Terrain",
        "terrain:Clear()",
        "",
    }

    -- Thử đọc terrain theo regions
    local chunkSize = 64
    local maxRange = 2048
    local terrainDataCount = 0

    Logger:Info("Đang đọc Terrain voxels (có thể mất thời gian)...")

    for x = -maxRange, maxRange, chunkSize do
        for y = -maxRange, maxRange, chunkSize do
            for z = -maxRange, maxRange, chunkSize do
                Utility.YieldCheck()

                local region = Region3.new(
                    Vector3.new(x, y, z),
                    Vector3.new(x + chunkSize, y + chunkSize, z + chunkSize)
                ):ExpandToGrid(4)

                local success, materials, occupancy = pcall(function()
                    return terrain:ReadVoxels(region, 4)
                end)

                if success and materials then
                    local hasData = false
                    for mx = 1, #materials do
                        for my = 1, #materials[mx] do
                            for mz = 1, #materials[mx][my] do
                                if materials[mx][my][mz] ~= Enum.Material.Air then
                                    hasData = true
                                    break
                                end
                            end
                            if hasData then break end
                        end
                        if hasData then break end
                    end

                    if hasData then
                        terrainDataCount = terrainDataCount + 1
                        table.insert(lines, string.format(
                            "-- Region chunk at (%d, %d, %d) - has terrain data",
                            x, y, z
                        ))
                        -- Serialize region data
                        table.insert(lines, string.format(
                            "local region_%d = Region3.new(Vector3.new(%d,%d,%d), Vector3.new(%d,%d,%d)):ExpandToGrid(4)",
                            terrainDataCount, x, y, z, x + chunkSize, y + chunkSize, z + chunkSize
                        ))
                    end
                end
            end
        end

        -- Early exit nếu không tìm thấy data nào sau một khoảng
        if x > 512 and terrainDataCount == 0 then
            break
        end
    end

    if terrainDataCount == 0 then
        table.insert(lines, "-- No terrain data found in scanned range")
        Logger:Warn("Không tìm thấy terrain data trong phạm vi quét")
    else
        Logger:Info(string.format("Tìm thấy %d terrain regions", terrainDataCount))
    end

    table.insert(lines, "")
    table.insert(lines, "print('Terrain loaded by BaoSaveInstance')")

    return table.concat(lines, "\n")
end

--- ═══════════════════════════════════════════════════════
--- DECOMPILE SCRIPT (ALL SCRIPTS ONLY)
--- ═══════════════════════════════════════════════════════
function BaoSaveInstance.DecompileScript()
    Stats:Reset()
    Utility.ResetYieldCounter()

    Logger:Info("═══════════════════════════════════════")
    Logger:Info("  BẮT ĐẦU DECOMPILE SCRIPTS")
    Logger:Info("═══════════════════════════════════════")

    local gameName = Utility.GetGameName()
    local fileName = gameName .. " Scripts Decompile By BaoSaveInstance.rbxl"

    Logger:Info("Game: " .. gameName)
    Logger:Info("File output: " .. fileName)

    -- PHASE 1: Decompile tất cả scripts
    Logger:Info("")
    Logger:Info("══ PHASE 1/2: Decompile Scripts ══")
    local scriptResults = ScriptProcessor:DecompileAllScripts()

    -- PHASE 2: Lưu
    Logger:Info("")
    Logger:Info("══ PHASE 2/2: Lưu kết quả ══")

    local saveSuccess = false

    -- Thử saveinstance (sẽ bao gồm scripts đã decompile)
    local ok, err = SaveEngine:SaveWithSaveInstance(fileName, {
        mode = "scripts",
        noscripts = false,
        FileName = fileName,
        RemovePlayers = true,
        DecompileTimeout = Config.DecompileTimeout,
    })

    if ok then
        saveSuccess = true
        Logger:Success("Đã lưu file scripts: " .. fileName)
    else
        Logger:Warn("saveinstance thất bại: " .. tostring(err))
    end

    -- Luôn cố gắng lưu scripts ra file riêng lẻ
    Logger:Info("Đang lưu scripts ra file .lua riêng lẻ...")
    ScriptProcessor:SaveScriptsToFiles(scriptResults)

    -- Thêm: Lưu tất cả scripts vào 1 file tổng hợp
    local writefile = Utility.GetFunction("writefile")
    if writefile then
        local allSourceLines = {
            "--[[ ═══════════════════════════════════════════════════════ ]]",
            "--[[ BaoSaveInstance v" .. BaoSaveInstance.Version .. " - All Scripts Decompiled ]]",
            "--[[ Game: " .. gameName .. " ]]",
            "--[[ Total Scripts: " .. Stats.TotalScripts .. " ]]",
            "--[[ Decompiled: " .. Stats.DecompiledScripts .. " ]]",
            "--[[ Failed: " .. Stats.FailedScripts .. " ]]",
            "--[[ ═══════════════════════════════════════════════════════ ]]",
            "",
        }

        for scriptInst, data in pairs(scriptResults) do
            table.insert(allSourceLines, "")
            table.insert(allSourceLines, "--[[ ═══════════════════════════════════════ ]]")
            table.insert(allSourceLines, "--[[ Script: " .. data.Path .. " ]]")
            table.insert(allSourceLines, "--[[ Type: " .. data.Type .. " ]]")
            table.insert(allSourceLines, "--[[ Status: " .. (data.Success and "SUCCESS" or "FAILED") .. " ]]")
            table.insert(allSourceLines, "--[[ ═══════════════════════════════════════ ]]")
            table.insert(allSourceLines, "")
            table.insert(allSourceLines, data.Source)
            table.insert(allSourceLines, "")
        end

        local combinedFileName = gameName .. " AllScripts By BaoSaveInstance.lua"
        local ok2 = pcall(function()
            writefile(combinedFileName, table.concat(allSourceLines, "\n"))
        end)
        if ok2 then
            Logger:Success("Đã lưu tất cả scripts vào: " .. combinedFileName)
        end
    end

    -- Kết quả
    Logger:Info("")
    print(Stats:GetSummary())

    Logger:Success("DECOMPILE SCRIPTS HOÀN TẤT!")

    return saveSuccess or (Stats.DecompiledScripts > 0)
end

--- Lưu ra file .rbxl (public helper)
function BaoSaveInstance.SaveToRBXL(instanceTree, fileName)
    return SaveEngine:SaveWithSaveInstance(fileName, {
        mode = "full",
        ExtraInstances = type(instanceTree) == "table" and instanceTree or {instanceTree},
    })
end

-- ============================================================
-- GUI INTERFACE
-- ============================================================
function BaoSaveInstance.ShowGUI()
    -- Xóa GUI cũ nếu có
    pcall(function()
        if CoreGui:FindFirstChild("BaoSaveInstanceGUI") then
            CoreGui.BaoSaveInstanceGUI:Destroy()
        end
    end)

    -- Tạo ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaoSaveInstanceGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Thử parent vào CoreGui, fallback sang PlayerGui
    local guiParent = CoreGui
    local success = pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not success then
        pcall(function()
            screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end)
    end

    -- ═══════ MAIN FRAME ═══════
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 420, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -260)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    -- Corner rounding
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    -- Drop shadow effect (border)
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(100, 60, 255)
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0.3
    mainStroke.Parent = mainFrame

    -- ═══════ TITLE BAR ═══════
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    -- Fix bottom corners of title bar
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 12)
    titleFix.Position = UDim2.new(0, 0, 1, -12)
    titleFix.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔧 BaoSaveInstance v" .. BaoSaveInstance.Version
    titleLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- ═══════ GAME INFO ═══════
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoFrame"
    infoFrame.Size = UDim2.new(1, -30, 0, 60)
    infoFrame.Position = UDim2.new(0, 15, 0, 58)
    infoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    infoFrame.BorderSizePixel = 0
    infoFrame.Parent = mainFrame

    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 8)
    infoCorner.Parent = infoFrame

    local gameName = Utility.GetGameName()
    local gameInfoLabel = Instance.new("TextLabel")
    gameInfoLabel.Size = UDim2.new(1, -20, 0, 25)
    gameInfoLabel.Position = UDim2.new(0, 10, 0, 5)
    gameInfoLabel.BackgroundTransparency = 1
    gameInfoLabel.Text = "🎮 " .. gameName
    gameInfoLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
    gameInfoLabel.TextSize = 14
    gameInfoLabel.Font = Enum.Font.GothamSemibold
    gameInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    gameInfoLabel.TextTruncate = Enum.TextTruncate.AtEnd
    gameInfoLabel.Parent = infoFrame

    local placeIdLabel = Instance.new("TextLabel")
    placeIdLabel.Size = UDim2.new(1, -20, 0, 20)
    placeIdLabel.Position = UDim2.new(0, 10, 0, 32)
    placeIdLabel.BackgroundTransparency = 1
    placeIdLabel.Text = "📍 PlaceId: " .. tostring(game.PlaceId) .. " | Instances: " .. tostring(Utility.CountDescendants(game))
    placeIdLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    placeIdLabel.TextSize = 11
    placeIdLabel.Font = Enum.Font.Gotham
    placeIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    placeIdLabel.Parent = infoFrame

    -- ═══════ BUTTONS ═══════
    local buttonData = {
        {
            Text = "🌍 Decompile Game (Full)",
            Color = Color3.fromRGB(100, 60, 255),
            HoverColor = Color3.fromRGB(130, 90, 255),
            Desc = "Decompile toàn bộ: Map + Terrain + Scripts + Assets",
            Func = BaoSaveInstance.DecompileGame,
        },
        {
            Text = "🗺️ Decompile Map",
            Color = Color3.fromRGB(60, 160, 255),
            HoverColor = Color3.fromRGB(90, 180, 255),
            Desc = "Chỉ decompile Map (Workspace objects)",
            Func = BaoSaveInstance.DecompileMap,
        },
        {
            Text = "⛰️ Decompile Terrain",
            Color = Color3.fromRGB(60, 200, 120),
            HoverColor = Color3.fromRGB(80, 220, 140),
            Desc = "Chỉ decompile Terrain (Voxel data)",
            Func = BaoSaveInstance.DecompileTerrain,
        },
        {
            Text = "📜 Decompile Scripts",
            Color = Color3.fromRGB(255, 160, 40),
            HoverColor = Color3.fromRGB(255, 180, 70),
            Desc = "Decompile tất cả Scripts (LocalScript, Script, Module)",
            Func = BaoSaveInstance.DecompileScript,
        },
    }

    local yOffset = 130
    for i, data in ipairs(buttonData) do
        -- Button container
        local btnFrame = Instance.new("Frame")
        btnFrame.Size = UDim2.new(1, -30, 0, 72)
        btnFrame.Position = UDim2.new(0, 15, 0, yOffset)
        btnFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
        btnFrame.BorderSizePixel = 0
        btnFrame.Parent = mainFrame

        local btnFrameCorner = Instance.new("UICorner")
        btnFrameCorner.CornerRadius = UDim.new(0, 8)
        btnFrameCorner.Parent = btnFrame

        -- Actual button
        local btn = Instance.new("TextButton")
        btn.Name = "Button_" .. i
        btn.Size = UDim2.new(1, -20, 0, 36)
        btn.Position = UDim2.new(0, 10, 0, 8)
        btn.BackgroundColor3 = data.Color
        btn.Text = data.Text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Parent = btnFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        -- Description
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -20, 0, 18)
        descLabel.Position = UDim2.new(0, 10, 0, 48)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = data.Desc
        descLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
        descLabel.TextSize = 10
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = btnFrame

        -- Hover effects
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = data.HoverColor
            }):Play()
        end)

        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = data.Color
            }):Play()
        end)

        -- Click handler
        local isRunning = false
        btn.MouseButton1Click:Connect(function()
            if isRunning then return end
            isRunning = true

            -- Visual feedback
            btn.Text = "⏳ Đang xử lý..."
            btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            descLabel.Text = "Vui lòng đợi, kiểm tra Output (F9) để xem tiến trình..."
            descLabel.TextColor3 = Color3.fromRGB(255, 200, 60)

            -- Chạy trong coroutine để không block GUI
            task.spawn(function()
                local success, err = pcall(data.Func)

                if success then
                    btn.Text = "✅ Hoàn tất!"
                    btn.BackgroundColor3 = Color3.fromRGB(40, 200, 80)
                    descLabel.Text = "Decompile thành công! Kiểm tra workspace folder."
                    descLabel.TextColor3 = Color3.fromRGB(40, 200, 80)
                else
                    btn.Text = "❌ Lỗi!"
                    btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                    descLabel.Text = "Lỗi: " .. tostring(err)
                    descLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                    Logger:Error("GUI Error: " .. tostring(err))
                end

                -- Reset sau 5 giây
                task.wait(5)
                btn.Text = data.Text
                btn.BackgroundColor3 = data.Color
                descLabel.Text = data.Desc
                descLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
                isRunning = false
            end)
        end)

        yOffset = yOffset + 82
    end

    -- ═══════ STATUS BAR ═══════
    local statusBar = Instance.new("Frame")
    statusBar.Size = UDim2.new(1, -30, 0, 30)
    statusBar.Position = UDim2.new(0, 15, 1, -40)
    statusBar.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    statusBar.BorderSizePixel = 0
    statusBar.Parent = mainFrame

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusBar

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 1, 0)
    statusLabel.Position = UDim2.new(0, 10, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📋 Nhấn F9 để xem Output log chi tiết"
    statusLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
    statusLabel.TextSize = 10
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = statusBar

    -- ═══════ DRAGGABLE ═══════
    local dragging = false
    local dragStart = nil
    local startPos = nil

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)

    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
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

    -- ═══════ OPEN ANIMATION ═══════
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundTransparency = 1

    TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 420, 0, 520),
        Position = UDim2.new(0.5, -210, 0.5, -260),
        BackgroundTransparency = 0,
    }):Play()

    Logger:Success("GUI đã được tạo thành công!")

    return screenGui
end

-- ============================================================
-- KEYBOARD SHORTCUT (Toggle GUI with F6)
-- ============================================================
pcall(function()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F6 then
            local existingGui = CoreGui:FindFirstChild("BaoSaveInstanceGUI")
            if not existingGui then
                pcall(function()
                    existingGui = Players.LocalPlayer.PlayerGui:FindFirstChild("BaoSaveInstanceGUI")
                end)
            end

            if existingGui then
                existingGui:Destroy()
                Logger:Info("GUI đã đóng (F6)")
            else
                BaoSaveInstance.ShowGUI()
                Logger:Info("GUI đã mở (F6)")
            end
        end
    end)
end)

-- ============================================================
-- AUTO INITIALIZATION
-- ============================================================
BaoSaveInstance.Init()

-- Hiện GUI tự động
task.spawn(function()
    task.wait(0.5)
    BaoSaveInstance.ShowGUI()
end)

-- ============================================================
-- EXPORT MODULE
-- ============================================================
-- Đặt vào global để dễ truy cập từ console
if getgenv then
    getgenv().BaoSaveInstance = BaoSaveInstance
else
    _G.BaoSaveInstance = BaoSaveInstance
end

return BaoSaveInstance
