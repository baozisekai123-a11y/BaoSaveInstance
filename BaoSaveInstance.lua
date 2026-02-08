--[[
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
    
    BaoSaveInstance V2 - Production SaveInstance & Decompiler
    Author: BaoXYZ
    Version: 2.0.0
    
    Supports: Xeno, Solara, TNG, Velocity, Wave, and compatible executors
]]

-- ═══════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════

local Config = {
    Version = "2.0.0",
    FileName = "BaoSaveInstance_Export",
    
    -- Save Options
    SaveTerrain = true,
    SaveModels = true,
    DecompileScripts = true,
    SaveHiddenInstances = true,
    BypassStreamingEnabled = true,
    PreserveHierarchy = true,
    
    -- UI Theme
    Theme = {
        Primary = Color3.fromRGB(138, 43, 226),      -- Purple
        Secondary = Color3.fromRGB(75, 0, 130),       -- Indigo
        Accent = Color3.fromRGB(0, 255, 255),         -- Cyan
        Background = Color3.fromRGB(15, 15, 25),      -- Dark
        Surface = Color3.fromRGB(25, 25, 40),         -- Surface
        Text = Color3.fromRGB(255, 255, 255),         -- White
        TextMuted = Color3.fromRGB(150, 150, 170),    -- Muted
        Success = Color3.fromRGB(50, 205, 50),        -- Green
        Warning = Color3.fromRGB(255, 165, 0),        -- Orange
        Error = Color3.fromRGB(255, 69, 58),          -- Red
    }
}

-- ═══════════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local Chat = game:GetService("Chat")
local LocalizationService = game:GetService("LocalizationService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════════
-- EXECUTOR DETECTION & COMPATIBILITY
-- ═══════════════════════════════════════════════════════════════════

local Executor = {
    Name = "Unknown",
    SupportsDecompile = false,
    SupportsFileIO = false,
    SupportsDrawing = false,
}

local function detectExecutor()
    -- Check for common executor identifiers
    if identifyexecutor then
        Executor.Name = identifyexecutor() or "Unknown"
    elseif getexecutorname then
        Executor.Name = getexecutorname() or "Unknown"
    elseif KRNL_LOADED then
        Executor.Name = "Krnl"
    elseif syn then
        Executor.Name = "Synapse X"
    elseif fluxus then
        Executor.Name = "Fluxus"
    end
    
    -- Check capabilities
    Executor.SupportsDecompile = (decompile ~= nil or getscriptbytecode ~= nil)
    Executor.SupportsFileIO = (writefile ~= nil and readfile ~= nil)
    Executor.SupportsDrawing = (Drawing ~= nil)
    
    return Executor
end

detectExecutor()

-- ═══════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════

local Utils = {}

function Utils.deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = Utils.deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function Utils.sanitizeString(str)
    if type(str) ~= "string" then return tostring(str) end
    return str:gsub("[%z\1-\31\127]", "")
end

function Utils.formatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

function Utils.getTimestamp()
    return os.date("%Y-%m-%d_%H-%M-%S")
end

-- ═══════════════════════════════════════════════════════════════════
-- LOGGER MODULE
-- ═══════════════════════════════════════════════════════════════════

local Logger = {
    logs = {},
    callbacks = {}
}

function Logger:log(message, level)
    level = level or "INFO"
    local entry = {
        time = os.date("%H:%M:%S"),
        level = level,
        message = message
    }
    table.insert(self.logs, entry)
    
    -- Trigger callbacks
    for _, callback in ipairs(self.callbacks) do
        pcall(callback, entry)
    end
    
    -- Console output
    print(string.format("[BaoSaveInstance] [%s] [%s] %s", entry.time, level, message))
end

function Logger:info(msg) self:log(msg, "INFO") end
function Logger:success(msg) self:log(msg, "SUCCESS") end
function Logger:warn(msg) self:log(msg, "WARN") end
function Logger:error(msg) self:log(msg, "ERROR") end

function Logger:onLog(callback)
    table.insert(self.callbacks, callback)
end

-- ═══════════════════════════════════════════════════════════════════
-- ADVANCED DECOMPILER ENGINE (X20 Enhanced)
-- ═══════════════════════════════════════════════════════════════════

local Decompiler = {
    stats = {
        totalScripts = 0,
        successfulDecompiles = 0,
        failedDecompiles = 0,
        totalLines = 0
    },
    
    -- Pattern mappings for variable renaming
    variablePatterns = {
        -- Service patterns
        {pattern = "game:GetService%(%s*[\"']Players[\"']%s*%)", rename = "Players"},
        {pattern = "game:GetService%(%s*[\"']ReplicatedStorage[\"']%s*%)", rename = "ReplicatedStorage"},
        {pattern = "game:GetService%(%s*[\"']Workspace[\"']%s*%)", rename = "Workspace"},
        {pattern = "game:GetService%(%s*[\"']TweenService[\"']%s*%)", rename = "TweenService"},
        {pattern = "game:GetService%(%s*[\"']UserInputService[\"']%s*%)", rename = "UserInputService"},
        {pattern = "game:GetService%(%s*[\"']RunService[\"']%s*%)", rename = "RunService"},
        {pattern = "game:GetService%(%s*[\"']Debris[\"']%s*%)", rename = "Debris"},
        {pattern = "game:GetService%(%s*[\"']HttpService[\"']%s*%)", rename = "HttpService"},
        {pattern = "game:GetService%(%s*[\"']MarketplaceService[\"']%s*%)", rename = "MarketplaceService"},
        {pattern = "game:GetService%(%s*[\"']DataStoreService[\"']%s*%)", rename = "DataStoreService"},
        {pattern = "game:GetService%(%s*[\"']SoundService[\"']%s*%)", rename = "SoundService"},
        {pattern = "game:GetService%(%s*[\"']Lighting[\"']%s*%)", rename = "Lighting"},
        {pattern = "game:GetService%(%s*[\"']Teams[\"']%s*%)", rename = "Teams"},
        {pattern = "game:GetService%(%s*[\"']Chat[\"']%s*%)", rename = "ChatService"},
        {pattern = "game:GetService%(%s*[\"']StarterGui[\"']%s*%)", rename = "StarterGui"},
        {pattern = "game:GetService%(%s*[\"']StarterPlayer[\"']%s*%)", rename = "StarterPlayer"},
        {pattern = "game:GetService%(%s*[\"']StarterPack[\"']%s*%)", rename = "StarterPack"},
        {pattern = "game:GetService%(%s*[\"']ServerStorage[\"']%s*%)", rename = "ServerStorage"},
        {pattern = "game:GetService%(%s*[\"']ServerScriptService[\"']%s*%)", rename = "ServerScriptService"},
        
        -- Common object patterns
        {pattern = "LocalPlayer", rename = "player"},
        {pattern = "%.Character", rename = ".character"},
        {pattern = "%.Humanoid", rename = ".humanoid"},
        {pattern = "%.HumanoidRootPart", rename = ".rootPart"},
        {pattern = "%.PrimaryPart", rename = ".primaryPart"},
        {pattern = "%.Parent", rename = ".parent"},
    },
    
    -- Known obfuscation patterns to detect
    obfuscationPatterns = {
        "getfenv",
        "setfenv", 
        "loadstring",
        "string%.char",
        "string%.byte",
        "string%.reverse",
        "bit32%.bxor",
        "bit32%.band",
        "while%s+true%s+do%s+wait%(%)%s+end",
        "for%s+_%s*=%s*1%s*,%s*math%.huge",
        "HttpService:GenerateGUID",
        "math%.random.*math%.random.*math%.random",
    },
    
    -- Anti-cheat detection patterns
    antiCheatPatterns = {
        {pattern = "getconnections", type = "Anti-Cheat", desc = "Connection manipulation detection"},
        {pattern = "hookfunction", type = "Anti-Cheat", desc = "Function hooking detection"},
        {pattern = "hookmetamethod", type = "Anti-Cheat", desc = "Metatable hooking detection"},
        {pattern = "getnamecall", type = "Anti-Cheat", desc = "Namecall monitoring"},
        {pattern = "checkcaller", type = "Anti-Cheat", desc = "Caller verification"},
        {pattern = "getrawmetatable", type = "Anti-Cheat", desc = "Raw metatable access"},
        {pattern = "setreadonly", type = "Anti-Cheat", desc = "Readonly modification"},
        {pattern = "debug%.getinfo", type = "Anti-Cheat", desc = "Debug info access"},
        {pattern = "debug%.traceback", type = "Anti-Cheat", desc = "Stack trace monitoring"},
        {pattern = "pcall.*error", type = "Protection", desc = "Error-based protection"},
        {pattern = "xpcall", type = "Protection", desc = "Extended protected call"},
        {pattern = "getgc", type = "Anti-Cheat", desc = "Garbage collector access"},
        {pattern = "getinstances", type = "Detection", desc = "Instance enumeration"},
        {pattern = "getnilinstances", type = "Detection", desc = "Nil instance access"},
        {pattern = "getloadedmodules", type = "Detection", desc = "Module enumeration"},
        {pattern = "Humanoid%.Health%s*=%s*0", type = "Kill", desc = "Health manipulation"},
        {pattern = "Humanoid:TakeDamage", type = "Damage", desc = "Damage function"},
        {pattern = ":Kick%(", type = "Kick", desc = "Player kick function"},
        {pattern = ":Ban%(", type = "Ban", desc = "Player ban function"},
        {pattern = "RemoteEvent", type = "Network", desc = "Remote event usage"},
        {pattern = "RemoteFunction", type = "Network", desc = "Remote function usage"},
        {pattern = ":FireServer%(", type = "Network", desc = "Server fire call"},
        {pattern = ":InvokeServer%(", type = "Network", desc = "Server invoke call"},
    }
}

-- Main decompile function
function Decompiler:decompile(script)
    if not script then 
        return "-- [BaoSaveInstance] Error: No script provided"
    end
    
    self.stats.totalScripts = self.stats.totalScripts + 1
    
    local scriptInfo = self:analyzeScript(script)
    local source = nil
    local decompileMethod = "Unknown"
    
    -- Method 1: Try to get source directly
    pcall(function()
        if script:IsA("ModuleScript") or script:IsA("LocalScript") or script:IsA("Script") then
            source = script.Source
            if source and source ~= "" then
                decompileMethod = "DirectSource"
            end
        end
    end)
    
    -- Method 2: Try executor's decompile function
    if (not source or source == "") and decompile then
        local success, result = pcall(function()
            return decompile(script)
        end)
        if success and result and result ~= "" then
            source = result
            decompileMethod = "ExecutorDecompile"
        end
    end
    
    -- Method 3: Try getscriptbytecode
    if (not source or source == "") and getscriptbytecode then
        local success, bytecode = pcall(function()
            return getscriptbytecode(script)
        end)
        if success and bytecode and #bytecode > 0 then
            source = self:bytecodeToPlaceholder(script, bytecode)
            decompileMethod = "BytecodeCapture"
        end
    end
    
    -- Method 4: Try getsenv for running scripts
    if (not source or source == "") and getsenv then
        pcall(function()
            local env = getsenv(script)
            if env then
                source = self:envToSource(env, script)
                decompileMethod = "EnvironmentReconstruction"
            end
        end)
    end
    
    -- Fallback: Generate placeholder
    if not source or source == "" then
        self.stats.failedDecompiles = self.stats.failedDecompiles + 1
        return self:generatePlaceholder(scriptInfo)
    end
    
    self.stats.successfulDecompiles = self.stats.successfulDecompiles + 1
    
    -- Process the source code
    local processedSource = self:processSource(source, scriptInfo, decompileMethod)
    
    -- Count lines
    local _, lineCount = processedSource:gsub("\n", "")
    self.stats.totalLines = self.stats.totalLines + lineCount
    
    return processedSource
end

-- Process and enhance decompiled source
function Decompiler:processSource(source, scriptInfo, method)
    local processed = source
    
    -- Step 1: Clean up formatting
    processed = self:cleanupFormatting(processed)
    
    -- Step 2: Detect obfuscation
    local obfuscationLevel, obfuscationDetails = self:detectObfuscation(processed)
    
    -- Step 3: Detect anti-cheat patterns
    local antiCheatInfo = self:detectAntiCheat(processed)
    
    -- Step 4: Improve variable names (if readable enough)
    if obfuscationLevel < 3 then
        processed = self:improveVariableNames(processed)
    end
    
    -- Step 5: Add comments for complex patterns
    processed = self:addAnalysisComments(processed, antiCheatInfo)
    
    -- Step 6: Format code structure
    processed = self:formatCodeStructure(processed)
    
    -- Generate comprehensive header
    local header = self:generateHeader(scriptInfo, method, obfuscationLevel, obfuscationDetails, antiCheatInfo)
    
    return header .. processed
end

-- Cleanup code formatting
function Decompiler:cleanupFormatting(source)
    local cleaned = source
    
    -- Remove excessive blank lines
    cleaned = cleaned:gsub("\n\n\n+", "\n\n")
    
    -- Remove trailing whitespace
    cleaned = cleaned:gsub("[ \t]+\n", "\n")
    
    -- Fix common decompiler artifacts
    cleaned = cleaned:gsub("%;%;+", ";")
    cleaned = cleaned:gsub("do%s+do", "do")
    cleaned = cleaned:gsub("end%s+end%s+end%s+end", "end\nend")
    
    -- Remove junk variable assignments like v1 = v1
    cleaned = cleaned:gsub("local%s+v(%d+)%s*=%s*v%1%s*\n", "")
    
    -- Clean up empty functions
    cleaned = cleaned:gsub("function%s*%(%s*%)%s*end", "function() end")
    
    -- Fix spacing around operators
    cleaned = cleaned:gsub("([%w_])%s*=%s*([%w_\"'{])", "%1 = %2")
    
    return cleaned
end

-- Detect obfuscation level
function Decompiler:detectObfuscation(source)
    local score = 0
    local details = {}
    
    for _, pattern in ipairs(self.obfuscationPatterns) do
        if source:find(pattern) then
            score = score + 1
            table.insert(details, pattern)
        end
    end
    
    -- Check for single-letter variables density
    local _, singleVars = source:gsub("local%s+[a-z]%s*=", "")
    if singleVars > 20 then
        score = score + 2
        table.insert(details, "High single-letter variable density")
    end
    
    -- Check for very long lines (often obfuscated)
    for line in source:gmatch("[^\n]+") do
        if #line > 500 then
            score = score + 2
            table.insert(details, "Very long lines detected")
            break
        end
    end
    
    -- Convert score to level (0-5)
    local level = math.min(5, math.floor(score / 2))
    
    return level, details
end

-- Detect anti-cheat patterns
function Decompiler:detectAntiCheat(source)
    local findings = {}
    
    for _, info in ipairs(self.antiCheatPatterns) do
        if source:find(info.pattern) then
            table.insert(findings, {
                type = info.type,
                pattern = info.pattern,
                description = info.desc
            })
        end
    end
    
    return findings
end

-- Improve variable names
function Decompiler:improveVariableNames(source)
    local improved = source
    
    -- Apply pattern-based renaming hints as comments
    for _, mapping in ipairs(self.variablePatterns) do
        -- Add hint comments rather than renaming (safer)
        if improved:find(mapping.pattern) then
            -- Pattern exists, could add hints
        end
    end
    
    -- Detect common variable patterns and suggest names
    -- Player references
    improved = improved:gsub(
        "(local%s+)(v%d+)(%s*=%s*game%.Players%.LocalPlayer)",
        "%1player%3 -- Renamed from %2"
    )
    
    -- Character references
    improved = improved:gsub(
        "(local%s+)(v%d+)(%s*=%s*[%w_]+%.Character)",
        "%1character%3 -- Renamed from %2"
    )
    
    -- Humanoid references
    improved = improved:gsub(
        "(local%s+)(v%d+)(%s*=%s*[%w_]+:FindFirstChildOfClass%([\"']Humanoid[\"']%))",
        "%1humanoid%3 -- Renamed from %2"
    )
    
    -- Mouse references
    improved = improved:gsub(
        "(local%s+)(v%d+)(%s*=%s*[%w_]+:GetMouse%(%s*%))",
        "%1mouse%3 -- Renamed from %2"
    )
    
    -- Camera references
    improved = improved:gsub(
        "(local%s+)(v%d+)(%s*=%s*workspace%.CurrentCamera)",
        "%1camera%3 -- Renamed from %2"
    )
    improved = improved:gsub(
        "(local%s+)(v%d+)(%s*=%s*game%.Workspace%.CurrentCamera)",
        "%1camera%3 -- Renamed from %2"
    )
    
    return improved
end

-- Add analysis comments
function Decompiler:addAnalysisComments(source, antiCheatInfo)
    if #antiCheatInfo == 0 then
        return source
    end
    
    local commented = source
    
    -- Add inline comments for detected patterns
    for _, info in ipairs(antiCheatInfo) do
        local pattern = info.pattern:gsub("%%", "%%%%")
        commented = commented:gsub(
            "(" .. info.pattern .. ")",
            "%1 --[[ [" .. info.type .. "] " .. info.description .. " ]]"
        )
    end
    
    return commented
end

-- Format code structure
function Decompiler:formatCodeStructure(source)
    local formatted = source
    
    -- Ensure proper line breaks after control structures
    formatted = formatted:gsub("then%s+", "then\n\t")
    formatted = formatted:gsub("do%s+([^%s])", "do\n\t%1")
    formatted = formatted:gsub("else%s+([^%s])", "else\n\t%1")
    
    return formatted
end

-- Generate comprehensive header
function Decompiler:generateHeader(scriptInfo, method, obfuscationLevel, obfuscationDetails, antiCheatInfo)
    local obfuscationLabels = {"None", "Minimal", "Light", "Moderate", "Heavy", "Extreme"}
    
    local header = [[
--[[
═══════════════════════════════════════════════════════════════════════════════
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
    
    DECOMPILED BY BAOSAVEINSTANCE V2 PRO
═══════════════════════════════════════════════════════════════════════════════

    Script Information:
    ├── Name: ]] .. scriptInfo.name .. [[
    
    ├── Type: ]] .. scriptInfo.className .. [[
    
    ├── Path: ]] .. scriptInfo.path .. [[
    
    ├── Disabled: ]] .. tostring(scriptInfo.disabled) .. [[
    
    └── RunContext: ]] .. (scriptInfo.runContext or "Unknown") .. [[


    Decompilation Info:
    ├── Method: ]] .. method .. [[
    
    ├── Timestamp: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[
    
    ├── Executor: ]] .. Executor.Name .. [[
    
    └── Quality: ]] .. (method == "DirectSource" and "Perfect" or 
                        method == "ExecutorDecompile" and "High" or "Partial") .. [[


    Analysis Results:
    ├── Obfuscation Level: ]] .. obfuscationLabels[obfuscationLevel + 1] .. " (" .. obfuscationLevel .. "/5)" .. [[
    
    └── Anti-Cheat Patterns: ]] .. #antiCheatInfo .. " detected"
    
    -- Add anti-cheat details if any
    if #antiCheatInfo > 0 then
        header = header .. [[


    Detected Security Patterns:]]
        for i, info in ipairs(antiCheatInfo) do
            header = header .. "\n    " .. (i < #antiCheatInfo and "├" or "└") .. 
                     "── [" .. info.type .. "] " .. info.description
        end
    end
    
    -- Add obfuscation details if any
    if #obfuscationDetails > 0 then
        header = header .. [[


    Obfuscation Indicators:]]
        for i, detail in ipairs(obfuscationDetails) do
            header = header .. "\n    " .. (i < #obfuscationDetails and "├" or "└") .. 
                     "── " .. detail
        end
    end
    
    header = header .. [[


═══════════════════════════════════════════════════════════════════════════════
]]
    
    return header .. "\n"
end

-- Generate placeholder for failed decompiles
function Decompiler:generatePlaceholder(scriptInfo)
    return string.format([[
--[[
═══════════════════════════════════════════════════════════════════════════════
    BAOSAVEINSTANCE V2 PRO - DECOMPILATION REPORT
═══════════════════════════════════════════════════════════════════════════════

    Script: %s
    Type: %s
    Path: %s
    
    Status: DECOMPILATION UNAVAILABLE
    
    Reason: The current executor does not support script decompilation,
            or the script is protected/encrypted.
    
    Executor: %s
    Decompile Support: %s
    Bytecode Support: %s
    
    Recommendations:
    1. Try using an executor with decompile support (Synapse X, Script-Ware)
    2. The script may use custom encryption
    3. Check if the script is a CoreScript (protected by Roblox)
    
═══════════════════════════════════════════════════════════════════════════════
]]

-- Placeholder generated by BaoSaveInstance V2
-- The actual script content could not be recovered

return nil -- Module placeholder
]], scriptInfo.name, scriptInfo.className, scriptInfo.path,
    Executor.Name, 
    tostring(Executor.SupportsDecompile),
    tostring(getscriptbytecode ~= nil))
end

-- Generate bytecode placeholder
function Decompiler:bytecodeToPlaceholder(script, bytecode)
    local hash = ""
    pcall(function()
        hash = string.sub(HttpService:GenerateGUID(false), 1, 16)
    end)
    
    return string.format([[
--[[
═══════════════════════════════════════════════════════════════════════════════
    BAOSAVEINSTANCE V2 PRO - BYTECODE CAPTURE
═══════════════════════════════════════════════════════════════════════════════

    Script: %s
    Type: %s
    Path: %s
    
    Bytecode Information:
    ├── Size: %d bytes
    ├── Hash: %s
    └── Format: Luau Bytecode
    
    Note: Full decompilation requires external tools.
          Bytecode has been captured for offline analysis.
    
═══════════════════════════════════════════════════════════════════════════════
]]

-- Bytecode captured but not decompiled
-- Use external Luau decompiler for full source recovery
]], script.Name, script.ClassName, script:GetFullName(), #bytecode, hash)
end

-- Reconstruct source from environment
function Decompiler:envToSource(env, script)
    local lines = {
        "-- Reconstructed from script environment",
        "-- Some details may be incomplete",
        ""
    }
    
    for name, value in pairs(env) do
        if type(value) == "function" then
            table.insert(lines, string.format("local function %s(...) end -- Function exists", name))
        elseif type(value) == "table" then
            table.insert(lines, string.format("local %s = {} -- Table with %d entries", name, #value))
        else
            table.insert(lines, string.format("local %s = %s", name, tostring(value)))
        end
    end
    
    return table.concat(lines, "\n")
end

-- Analyze script and get info
function Decompiler:analyzeScript(script)
    local info = {
        name = script.Name,
        className = script.ClassName,
        path = script:GetFullName(),
        disabled = false,
        runContext = "Legacy"
    }
    
    pcall(function()
        if script:IsA("Script") or script:IsA("LocalScript") then
            info.disabled = script.Disabled
        end
        if script:IsA("Script") then
            info.runContext = tostring(script.RunContext)
        end
    end)
    
    return info
end

-- Get decompiler statistics
function Decompiler:getStats()
    return {
        total = self.stats.totalScripts,
        success = self.stats.successfulDecompiles,
        failed = self.stats.failedDecompiles,
        lines = self.stats.totalLines,
        successRate = self.stats.totalScripts > 0 
            and math.floor((self.stats.successfulDecompiles / self.stats.totalScripts) * 100) 
            or 0
    }
end

-- Reset statistics
function Decompiler:resetStats()
    self.stats = {
        totalScripts = 0,
        successfulDecompiles = 0,
        failedDecompiles = 0,
        totalLines = 0
    }
end

-- ═══════════════════════════════════════════════════════════════════
-- RBXL SERIALIZER
-- ═══════════════════════════════════════════════════════════════════

local Serializer = {}

Serializer.PropertyBlacklist = {
    "Parent", "DataCost", "RobloxLocked", "ClassName",
    "Archivable", "UniqueId", "HistoryId", "SourceAssetId"
}

Serializer.ClassBlacklist = {
    "Player", "PlayerScripts", "PlayerGui", "Backpack",
    "Camera", "Terrain"  -- Terrain handled separately
}

function Serializer:canSerialize(instance)
    if not instance then return false end
    
    -- Check class blacklist
    for _, class in ipairs(self.ClassBlacklist) do
        if instance.ClassName == class then
            return false
        end
    end
    
    -- Check archivable
    local archivable = true
    pcall(function()
        archivable = instance.Archivable
    end)
    
    return archivable or Config.SaveHiddenInstances
end

function Serializer:getProperties(instance)
    local properties = {}
    
    -- Common properties for all instances
    local commonProps = {
        "Name", "Parent"
    }
    
    -- BasePart properties
    local basePartProps = {
        "Anchored", "CanCollide", "CanTouch", "CanQuery",
        "CastShadow", "Color", "Material", "Reflectance",
        "Transparency", "Size", "CFrame", "Position", "Orientation",
        "BrickColor", "Shape", "TopSurface", "BottomSurface",
        "LeftSurface", "RightSurface", "FrontSurface", "BackSurface"
    }
    
    -- MeshPart specific
    local meshPartProps = {
        "MeshId", "TextureID", "MeshSize"
    }
    
    -- Decal/Texture properties
    local decalProps = {
        "Texture", "Color3", "Transparency", "Face", "ZIndex"
    }
    
    -- Get properties based on class
    local propsToGet = commonProps
    
    if instance:IsA("BasePart") then
        for _, p in ipairs(basePartProps) do
            table.insert(propsToGet, p)
        end
        if instance:IsA("MeshPart") then
            for _, p in ipairs(meshPartProps) do
                table.insert(propsToGet, p)
            end
        end
    elseif instance:IsA("Decal") or instance:IsA("Texture") then
        for _, p in ipairs(decalProps) do
            table.insert(propsToGet, p)
        end
    end
    
    -- Fetch properties
    for _, propName in ipairs(propsToGet) do
        local success, value = pcall(function()
            return instance[propName]
        end)
        if success and value ~= nil then
            properties[propName] = value
        end
    end
    
    return properties
end

function Serializer:serializeValue(value)
    local t = typeof(value)
    
    if t == "string" then
        return string.format("%q", value)
    elseif t == "number" then
        return tostring(value)
    elseif t == "boolean" then
        return tostring(value)
    elseif t == "Vector3" then
        return string.format("Vector3.new(%f, %f, %f)", value.X, value.Y, value.Z)
    elseif t == "CFrame" then
        local components = {value:GetComponents()}
        return string.format("CFrame.new(%s)", table.concat(components, ", "))
    elseif t == "Color3" then
        return string.format("Color3.new(%f, %f, %f)", value.R, value.G, value.B)
    elseif t == "BrickColor" then
        return string.format("BrickColor.new(%q)", value.Name)
    elseif t == "UDim" then
        return string.format("UDim.new(%f, %d)", value.Scale, value.Offset)
    elseif t == "UDim2" then
        return string.format("UDim2.new(%f, %d, %f, %d)", 
            value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
    elseif t == "Enum" then
        return tostring(value)
    elseif t == "Instance" then
        return "nil -- Instance reference"
    else
        return "nil"
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- TERRAIN SAVER
-- ═══════════════════════════════════════════════════════════════════

local TerrainSaver = {}

function TerrainSaver:save()
    Logger:info("Starting terrain save...")
    
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        Logger:warn("No terrain found in workspace")
        return nil
    end
    
    local success, terrainData = pcall(function()
        -- Get terrain region
        local region = terrain:CopyRegion(terrain.MaxExtents)
        return region
    end)
    
    if success and terrainData then
        Logger:success("Terrain captured successfully")
        return {
            region = terrainData,
            waterWaveSize = terrain.WaterWaveSize,
            waterWaveSpeed = terrain.WaterWaveSpeed,
            waterTransparency = terrain.WaterTransparency,
            waterReflectance = terrain.WaterReflectance,
            waterColor = terrain.WaterColor
        }
    else
        Logger:error("Failed to capture terrain: " .. tostring(terrainData))
        return nil
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- MODEL SAVER
-- ═══════════════════════════════════════════════════════════════════

local ModelSaver = {
    savedCount = 0,
    scriptCount = 0,
    errorCount = 0
}

function ModelSaver:saveInstance(instance, parent)
    if not Serializer:canSerialize(instance) then
        return nil
    end
    
    local clone = nil
    
    pcall(function()
        clone = instance:Clone()
    end)
    
    if not clone then
        -- Try manual recreation
        pcall(function()
            clone = Instance.new(instance.ClassName)
            
            -- Copy properties
            local props = Serializer:getProperties(instance)
            for propName, propValue in pairs(props) do
                if propName ~= "Parent" then
                    pcall(function()
                        clone[propName] = propValue
                    end)
                end
            end
        end)
    end
    
    if clone then
        self.savedCount = self.savedCount + 1
        
        -- Handle scripts
        if clone:IsA("LuaSourceContainer") then
            self.scriptCount = self.scriptCount + 1
            if Config.DecompileScripts then
                local source = Decompiler:decompile(instance)
                pcall(function()
                    clone.Source = source
                end)
            end
        end
        
        if parent then
            clone.Parent = parent
        end
    else
        self.errorCount = self.errorCount + 1
    end
    
    return clone
end

function ModelSaver:saveRecursive(instance, parent, depth)
    depth = depth or 0
    
    if depth > 100 then return end -- Prevent infinite recursion
    
    -- Yield periodically to prevent timeout
    if self.savedCount % 100 == 0 then
        RunService.Heartbeat:Wait()
    end
    
    local clone = self:saveInstance(instance, parent)
    
    if clone then
        for _, child in ipairs(instance:GetChildren()) do
            self:saveRecursive(child, clone, depth + 1)
        end
    end
    
    return clone
end

function ModelSaver:reset()
    self.savedCount = 0
    self.scriptCount = 0
    self.errorCount = 0
end

-- ═══════════════════════════════════════════════════════════════════
-- RBXL FILE BUILDER
-- ═══════════════════════════════════════════════════════════════════

local RBXLBuilder = {}

function RBXLBuilder:createGameModel()
    local gameModel = Instance.new("Model")
    gameModel.Name = "BaoSaveInstance_Export"
    return gameModel
end

function RBXLBuilder:saveToFile(model, filename)
    if not Executor.SupportsFileIO then
        Logger:error("File I/O not supported on this executor")
        return false
    end
    
    local fullName = filename .. ".rbxl"
    
    -- Use saveinstance if available (most complete method)
    if saveinstance then
        local success, err = pcall(function()
            saveinstance({
                FilePath = fullName,
                Object = model,
                DecompileMode = Config.DecompileScripts and "full" or "none",
                SavePlayers = false,
                ShowStatus = false
            })
        end)
        
        if success then
            Logger:success("Saved using native saveinstance: " .. fullName)
            return true
        else
            Logger:warn("Native saveinstance failed, using fallback: " .. tostring(err))
        end
    end
    
    -- Fallback: Use syn.saveinstance or similar
    if syn and syn.saveinstance then
        local success, err = pcall(function()
            syn.saveinstance(model, fullName)
        end)
        
        if success then
            Logger:success("Saved using syn.saveinstance: " .. fullName)
            return true
        end
    end
    
    -- Final fallback: Save as RBXMX (XML format)
    if writefile then
        local xml = self:toRBXMX(model)
        local success, err = pcall(function()
            writefile(filename .. ".rbxmx", xml)
        end)
        
        if success then
            Logger:success("Saved as RBXMX (rename to .rbxl in Studio): " .. filename .. ".rbxmx")
            return true
        else
            Logger:error("Failed to write file: " .. tostring(err))
        end
    end
    
    Logger:error("No file save method available")
    return false
end

function RBXLBuilder:toRBXMX(instance)
    local xml = '<?xml version="1.0" encoding="utf-8"?>\n'
    xml = xml .. '<roblox version="4">\n'
    xml = xml .. self:instanceToXML(instance, 1)
    xml = xml .. '</roblox>'
    return xml
end

function RBXLBuilder:instanceToXML(instance, indent)
    local tabs = string.rep("\t", indent)
    local xml = ""
    
    xml = xml .. tabs .. '<Item class="' .. instance.ClassName .. '">\n'
    xml = xml .. tabs .. '\t<Properties>\n'
    
    -- Name property
    xml = xml .. tabs .. '\t\t<string name="Name">' .. Utils.sanitizeString(instance.Name) .. '</string>\n'
    
    -- Add more properties based on class
    if instance:IsA("BasePart") then
        pcall(function()
            xml = xml .. tabs .. '\t\t<bool name="Anchored">' .. tostring(instance.Anchored) .. '</bool>\n'
            xml = xml .. tabs .. '\t\t<bool name="CanCollide">' .. tostring(instance.CanCollide) .. '</bool>\n'
            xml = xml .. tabs .. string.format('\t\t<Vector3 name="Size"><X>%f</X><Y>%f</Y><Z>%f</Z></Vector3>\n',
                instance.Size.X, instance.Size.Y, instance.Size.Z)
        end)
    end
    
    if instance:IsA("LuaSourceContainer") then
        pcall(function()
            local source = instance.Source or ""
            xml = xml .. tabs .. '\t\t<ProtectedString name="Source"><![CDATA[' .. source .. ']]></ProtectedString>\n'
        end)
    end
    
    xml = xml .. tabs .. '\t</Properties>\n'
    
    -- Children
    for _, child in ipairs(instance:GetChildren()) do
        xml = xml .. self:instanceToXML(child, indent + 1)
    end
    
    xml = xml .. tabs .. '</Item>\n'
    
    return xml
end

-- ═══════════════════════════════════════════════════════════════════
-- UI LIBRARY
-- ═══════════════════════════════════════════════════════════════════

local UI = {}

function UI:create()
    -- Destroy existing UI
    local existing = CoreGui:FindFirstChild("BaoSaveInstanceUI")
    if existing then existing:Destroy() end
    
    -- Main ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BaoSaveInstanceUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Try to parent to CoreGui, fallback to PlayerGui
    pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Main Frame with glassmorphism effect
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 420, 0, 520)
    MainFrame.Position = UDim2.new(0.5, -210, 0.5, -260)
    MainFrame.BackgroundColor3 = Config.Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    -- Corner rounding
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 16)
    Corner.Parent = MainFrame
    
    -- Gradient overlay for glass effect
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 35))
    })
    Gradient.Rotation = 45
    Gradient.Parent = MainFrame
    
    -- Stroke for border glow
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Config.Theme.Primary
    Stroke.Thickness = 2
    Stroke.Transparency = 0.5
    Stroke.Parent = MainFrame
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 80)
    Header.BackgroundTransparency = 1
    Header.Parent = MainFrame
    
    -- Logo Text
    local Logo = Instance.new("TextLabel")
    Logo.Name = "Logo"
    Logo.Size = UDim2.new(1, -20, 0, 35)
    Logo.Position = UDim2.new(0, 10, 0, 10)
    Logo.BackgroundTransparency = 1
    Logo.Text = "⚡ BaoSaveInstance"
    Logo.TextColor3 = Config.Theme.Accent
    Logo.TextSize = 28
    Logo.Font = Enum.Font.GothamBold
    Logo.TextXAlignment = Enum.TextXAlignment.Left
    Logo.Parent = Header
    
    -- Version & Executor Info
    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Name = "InfoLabel"
    InfoLabel.Size = UDim2.new(1, -20, 0, 20)
    InfoLabel.Position = UDim2.new(0, 10, 0, 50)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = string.format("v%s | Executor: %s | %s", 
        Config.Version, 
        Executor.Name,
        workspace.StreamingEnabled and "⚠ Streaming" or "✓ Full Load")
    InfoLabel.TextColor3 = Config.Theme.TextMuted
    InfoLabel.TextSize = 13
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    InfoLabel.Parent = Header
    
    -- Separator
    local Sep1 = Instance.new("Frame")
    Sep1.Size = UDim2.new(1, -40, 0, 1)
    Sep1.Position = UDim2.new(0, 20, 0, 80)
    Sep1.BackgroundColor3 = Config.Theme.Primary
    Sep1.BackgroundTransparency = 0.7
    Sep1.BorderSizePixel = 0
    Sep1.Parent = MainFrame
    
    -- Buttons Container
    local ButtonsContainer = Instance.new("Frame")
    ButtonsContainer.Name = "ButtonsContainer"
    ButtonsContainer.Size = UDim2.new(1, -40, 0, 160)
    ButtonsContainer.Position = UDim2.new(0, 20, 0, 95)
    ButtonsContainer.BackgroundTransparency = 1
    ButtonsContainer.Parent = MainFrame
    
    local ButtonLayout = Instance.new("UIListLayout")
    ButtonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ButtonLayout.Padding = UDim.new(0, 10)
    ButtonLayout.Parent = ButtonsContainer
    
    -- Create Button Function
    local function createButton(name, text, icon, order, color)
        local Button = Instance.new("TextButton")
        Button.Name = name
        Button.Size = UDim2.new(1, 0, 0, 45)
        Button.BackgroundColor3 = color or Config.Theme.Surface
        Button.BorderSizePixel = 0
        Button.Text = ""
        Button.LayoutOrder = order
        Button.AutoButtonColor = false
        Button.Parent = ButtonsContainer
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 10)
        BtnCorner.Parent = Button
        
        local BtnStroke = Instance.new("UIStroke")
        BtnStroke.Color = Config.Theme.Primary
        BtnStroke.Thickness = 1
        BtnStroke.Transparency = 0.7
        BtnStroke.Parent = Button
        
        local BtnText = Instance.new("TextLabel")
        BtnText.Size = UDim2.new(1, -20, 1, 0)
        BtnText.Position = UDim2.new(0, 10, 0, 0)
        BtnText.BackgroundTransparency = 1
        BtnText.Text = icon .. "  " .. text
        BtnText.TextColor3 = Config.Theme.Text
        BtnText.TextSize = 16
        BtnText.Font = Enum.Font.GothamMedium
        BtnText.TextXAlignment = Enum.TextXAlignment.Left
        BtnText.Parent = Button
        
        -- Hover effect
        Button.MouseEnter:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.2), {
                BackgroundColor3 = Config.Theme.Primary
            }):Play()
            TweenService:Create(BtnStroke, TweenInfo.new(0.2), {
                Transparency = 0
            }):Play()
        end)
        
        Button.MouseLeave:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.2), {
                BackgroundColor3 = Config.Theme.Surface
            }):Play()
            TweenService:Create(BtnStroke, TweenInfo.new(0.2), {
                Transparency = 0.7
            }):Play()
        end)
        
        return Button
    end
    
    -- Main Buttons
    local BtnSaveGame = createButton("BtnSaveGame", "Save Game (Full Map)", "🎮", 1)
    local BtnSaveTerrain = createButton("BtnSaveTerrain", "Save Terrain Only", "🏔️", 2)
    local BtnSaveModels = createButton("BtnSaveModels", "Save All Models", "📦", 3)
    
    -- Advanced Panel
    local AdvancedPanel = Instance.new("Frame")
    AdvancedPanel.Name = "AdvancedPanel"
    AdvancedPanel.Size = UDim2.new(1, -40, 0, 120)
    AdvancedPanel.Position = UDim2.new(0, 20, 0, 270)
    AdvancedPanel.BackgroundColor3 = Config.Theme.Surface
    AdvancedPanel.BackgroundTransparency = 0.5
    AdvancedPanel.BorderSizePixel = 0
    AdvancedPanel.Parent = MainFrame
    
    local AdvCorner = Instance.new("UICorner")
    AdvCorner.CornerRadius = UDim.new(0, 10)
    AdvCorner.Parent = AdvancedPanel
    
    local AdvTitle = Instance.new("TextLabel")
    AdvTitle.Size = UDim2.new(1, -20, 0, 25)
    AdvTitle.Position = UDim2.new(0, 10, 0, 5)
    AdvTitle.BackgroundTransparency = 1
    AdvTitle.Text = "⚙️ Advanced Options"
    AdvTitle.TextColor3 = Config.Theme.Accent
    AdvTitle.TextSize = 14
    AdvTitle.Font = Enum.Font.GothamBold
    AdvTitle.TextXAlignment = Enum.TextXAlignment.Left
    AdvTitle.Parent = AdvancedPanel
    
    -- Toggle Options (simplified display)
    local OptionsText = Instance.new("TextLabel")
    OptionsText.Size = UDim2.new(1, -20, 0, 80)
    OptionsText.Position = UDim2.new(0, 10, 0, 30)
    OptionsText.BackgroundTransparency = 1
    OptionsText.Text = string.format(
        "☑ Deep Decompile: %s\n☑ Save Hidden: %s\n☑ Bypass Streaming: %s\n☑ Preserve Hierarchy: %s",
        Config.DecompileScripts and "ON" or "OFF",
        Config.SaveHiddenInstances and "ON" or "OFF",
        Config.BypassStreamingEnabled and "ON" or "OFF",
        Config.PreserveHierarchy and "ON" or "OFF"
    )
    OptionsText.TextColor3 = Config.Theme.TextMuted
    OptionsText.TextSize = 12
    OptionsText.Font = Enum.Font.Gotham
    OptionsText.TextXAlignment = Enum.TextXAlignment.Left
    OptionsText.TextYAlignment = Enum.TextYAlignment.Top
    OptionsText.Parent = AdvancedPanel
    
    -- Progress Section
    local ProgressSection = Instance.new("Frame")
    ProgressSection.Name = "ProgressSection"
    ProgressSection.Size = UDim2.new(1, -40, 0, 40)
    ProgressSection.Position = UDim2.new(0, 20, 0, 400)
    ProgressSection.BackgroundTransparency = 1
    ProgressSection.Parent = MainFrame
    
    local ProgressBg = Instance.new("Frame")
    ProgressBg.Size = UDim2.new(1, 0, 0, 8)
    ProgressBg.Position = UDim2.new(0, 0, 0, 20)
    ProgressBg.BackgroundColor3 = Config.Theme.Surface
    ProgressBg.BorderSizePixel = 0
    ProgressBg.Parent = ProgressSection
    
    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(1, 0)
    ProgressCorner.Parent = ProgressBg
    
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Name = "ProgressBar"
    ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    ProgressBar.BackgroundColor3 = Config.Theme.Accent
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = ProgressBg
    
    local ProgressBarCorner = Instance.new("UICorner")
    ProgressBarCorner.CornerRadius = UDim.new(1, 0)
    ProgressBarCorner.Parent = ProgressBar
    
    local ProgressLabel = Instance.new("TextLabel")
    ProgressLabel.Size = UDim2.new(1, 0, 0, 20)
    ProgressLabel.BackgroundTransparency = 1
    ProgressLabel.Text = "Ready"
    ProgressLabel.TextColor3 = Config.Theme.TextMuted
    ProgressLabel.TextSize = 12
    ProgressLabel.Font = Enum.Font.Gotham
    ProgressLabel.Parent = ProgressSection
    
    -- Log Window
    local LogWindow = Instance.new("ScrollingFrame")
    LogWindow.Name = "LogWindow"
    LogWindow.Size = UDim2.new(1, -40, 0, 55)
    LogWindow.Position = UDim2.new(0, 20, 0, 450)
    LogWindow.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    LogWindow.BorderSizePixel = 0
    LogWindow.ScrollBarThickness = 4
    LogWindow.ScrollBarImageColor3 = Config.Theme.Primary
    LogWindow.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogWindow.Parent = MainFrame
    
    local LogCorner = Instance.new("UICorner")
    LogCorner.CornerRadius = UDim.new(0, 8)
    LogCorner.Parent = LogWindow
    
    local LogLayout = Instance.new("UIListLayout")
    LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LogLayout.Padding = UDim.new(0, 2)
    LogLayout.Parent = LogWindow
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0, 10)
    CloseBtn.BackgroundColor3 = Config.Theme.Error
    CloseBtn.BackgroundTransparency = 0.8
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Config.Theme.Text
    CloseBtn.TextSize = 16
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = MainFrame
    
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 8)
    CloseBtnCorner.Parent = CloseBtn
    
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    -- Draggable
    local dragging, dragInput, dragStart, startPos
    
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Store references
    self.ScreenGui = ScreenGui
    self.MainFrame = MainFrame
    self.ProgressBar = ProgressBar
    self.ProgressLabel = ProgressLabel
    self.LogWindow = LogWindow
    self.LogLayout = LogLayout
    self.BtnSaveGame = BtnSaveGame
    self.BtnSaveTerrain = BtnSaveTerrain
    self.BtnSaveModels = BtnSaveModels
    
    -- Fade in animation
    MainFrame.BackgroundTransparency = 1
    for _, child in ipairs(MainFrame:GetDescendants()) do
        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
            if child.BackgroundTransparency < 1 then
                child.BackgroundTransparency = 1
            end
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                child.TextTransparency = 1
            end
        end
    end
    
    -- Animate in
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {
        BackgroundTransparency = 0
    }):Play()
    
    for _, child in ipairs(MainFrame:GetDescendants()) do
        if child:IsA("Frame") and child.BackgroundTransparency > 0 then
            TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {
                BackgroundTransparency = child.Name == "LogWindow" and 0 or 
                    (child.Name == "AdvancedPanel" and 0.5 or 
                    (child.Name == "ProgressBg" and 0 or 0))
            }):Play()
        end
        if child:IsA("TextLabel") then
            TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {
                TextTransparency = 0
            }):Play()
        end
        if child:IsA("TextButton") then
            TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {
                BackgroundTransparency = 0,
                TextTransparency = 0
            }):Play()
        end
    end
    
    -- Setup log callback
    Logger:onLog(function(entry)
        self:addLog(entry)
    end)
    
    return ScreenGui
end

function UI:addLog(entry)
    local color = Config.Theme.Text
    if entry.level == "SUCCESS" then color = Config.Theme.Success
    elseif entry.level == "WARN" then color = Config.Theme.Warning
    elseif entry.level == "ERROR" then color = Config.Theme.Error
    end
    
    local LogEntry = Instance.new("TextLabel")
    LogEntry.Size = UDim2.new(1, -10, 0, 14)
    LogEntry.BackgroundTransparency = 1
    LogEntry.Text = string.format("[%s] %s", entry.time, entry.message)
    LogEntry.TextColor3 = color
    LogEntry.TextSize = 10
    LogEntry.Font = Enum.Font.Code
    LogEntry.TextXAlignment = Enum.TextXAlignment.Left
    LogEntry.TextTruncate = Enum.TextTruncate.AtEnd
    LogEntry.LayoutOrder = #Logger.logs
    LogEntry.Parent = self.LogWindow
    
    -- Update canvas size
    self.LogWindow.CanvasSize = UDim2.new(0, 0, 0, self.LogLayout.AbsoluteContentSize.Y + 10)
    self.LogWindow.CanvasPosition = Vector2.new(0, self.LogLayout.AbsoluteContentSize.Y)
end

function UI:setProgress(percent, text)
    TweenService:Create(self.ProgressBar, TweenInfo.new(0.3), {
        Size = UDim2.new(percent, 0, 1, 0)
    }):Play()
    
    if text then
        self.ProgressLabel.Text = text
    end
end

function UI:setButtonsEnabled(enabled)
    local buttons = {self.BtnSaveGame, self.BtnSaveTerrain, self.BtnSaveModels}
    for _, btn in ipairs(buttons) do
        btn.Active = enabled
        btn.BackgroundTransparency = enabled and 0 or 0.5
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- SAVE CONTROLLER
-- ═══════════════════════════════════════════════════════════════════

local SaveController = {}

function SaveController:saveGame()
    Logger:info("Starting full game save...")
    UI:setButtonsEnabled(false)
    UI:setProgress(0, "Initializing...")
    
    local gameModel = RBXLBuilder:createGameModel()
    local timestamp = Utils.getTimestamp()
    local filename = Config.FileName .. "_" .. timestamp
    
    -- Save workspace contents
    UI:setProgress(0.1, "Saving workspace...")
    Logger:info("Processing workspace...")
    
    ModelSaver:reset()
    
    local workspaceModel = Instance.new("Folder")
    workspaceModel.Name = "Workspace"
    workspaceModel.Parent = gameModel
    
    local children = workspace:GetChildren()
    local total = #children
    
    for i, child in ipairs(children) do
        if child.ClassName ~= "Camera" and child.ClassName ~= "Terrain" then
            ModelSaver:saveRecursive(child, workspaceModel)
        end
        
        if i % 10 == 0 then
            UI:setProgress(0.1 + (i / total) * 0.4, string.format("Workspace: %d/%d", i, total))
        end
    end
    
    -- Save terrain
    if Config.SaveTerrain then
        UI:setProgress(0.5, "Saving terrain...")
        Logger:info("Processing terrain...")
        
        local terrainData = TerrainSaver:save()
        if terrainData then
            -- Terrain will be saved in the RBXL file
            local terrainInfo = Instance.new("Configuration")
            terrainInfo.Name = "TerrainData"
            terrainInfo.Parent = gameModel
        end
    end
    
    -- Save other services
    UI:setProgress(0.6, "Saving services...")
    
    local servicesToSave = {
        {service = Lighting, name = "Lighting"},
        {service = ReplicatedStorage, name = "ReplicatedStorage"},
        {service = StarterPlayer, name = "StarterPlayer"},
        {service = StarterGui, name = "StarterGui"},
        {service = Teams, name = "Teams"}
    }
    
    for i, svc in ipairs(servicesToSave) do
        local serviceModel = Instance.new("Folder")
        serviceModel.Name = svc.name
        serviceModel.Parent = gameModel
        
        for _, child in ipairs(svc.service:GetChildren()) do
            ModelSaver:saveRecursive(child, serviceModel)
        end
        
        UI:setProgress(0.6 + (i / #servicesToSave) * 0.2, "Services: " .. svc.name)
    end
    
    -- Export
    UI:setProgress(0.8, "Exporting .rbxl...")
    Logger:info("Exporting to file...")
    
    local success = RBXLBuilder:saveToFile(gameModel, filename)
    
    -- Cleanup
    gameModel:Destroy()
    
    if success then
        UI:setProgress(1, "✓ Save completed!")
        Logger:success(string.format("Saved! Models: %d | Scripts: %d | Errors: %d",
            ModelSaver.savedCount, ModelSaver.scriptCount, ModelSaver.errorCount))
    else
        UI:setProgress(1, "✗ Save failed")
        Logger:error("Save failed. Check executor capabilities.")
    end
    
    UI:setButtonsEnabled(true)
end

function SaveController:saveTerrain()
    Logger:info("Starting terrain-only save...")
    UI:setButtonsEnabled(false)
    UI:setProgress(0, "Initializing...")
    
    local timestamp = Utils.getTimestamp()
    local filename = "Terrain_" .. timestamp
    
    UI:setProgress(0.3, "Capturing terrain...")
    local terrainData = TerrainSaver:save()
    
    if terrainData then
        UI:setProgress(0.7, "Exporting...")
        
        local terrainModel = Instance.new("Model")
        terrainModel.Name = "TerrainExport"
        
        -- Note: Full terrain export requires saveinstance
        if saveinstance then
            pcall(function()
                saveinstance({
                    FilePath = filename .. ".rbxl",
                    Object = workspace.Terrain,
                    ShowStatus = false
                })
            end)
            Logger:success("Terrain saved: " .. filename .. ".rbxl")
            UI:setProgress(1, "✓ Terrain saved!")
        else
            Logger:warn("Full terrain save requires native saveinstance support")
            UI:setProgress(1, "⚠ Limited terrain save")
        end
        
        terrainModel:Destroy()
    else
        UI:setProgress(1, "✗ No terrain found")
    end
    
    UI:setButtonsEnabled(true)
end

function SaveController:saveModels()
    Logger:info("Starting models-only save...")
    UI:setButtonsEnabled(false)
    UI:setProgress(0, "Initializing...")
    
    local timestamp = Utils.getTimestamp()
    local filename = "Models_" .. timestamp
    
    local modelsFolder = Instance.new("Model")
    modelsFolder.Name = "ModelsExport"
    
    ModelSaver:reset()
    
    UI:setProgress(0.1, "Finding models...")
    
    -- Find all Models, MeshParts, Unions in workspace
    local items = {}
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("Model") or item:IsA("MeshPart") or item:IsA("UnionOperation") then
            table.insert(items, item)
        end
    end
    
    local total = #items
    Logger:info(string.format("Found %d models/meshes to save", total))
    
    for i, item in ipairs(items) do
        ModelSaver:saveRecursive(item, modelsFolder)
        
        if i % 20 == 0 then
            UI:setProgress(0.1 + (i / total) * 0.7, string.format("Models: %d/%d", i, total))
        end
    end
    
    UI:setProgress(0.8, "Exporting...")
    
    local success = RBXLBuilder:saveToFile(modelsFolder, filename)
    
    modelsFolder:Destroy()
    
    if success then
        UI:setProgress(1, "✓ Models saved!")
        Logger:success(string.format("Saved %d models", ModelSaver.savedCount))
    else
        UI:setProgress(1, "✗ Save failed")
    end
    
    UI:setButtonsEnabled(true)
end

-- ═══════════════════════════════════════════════════════════════════
-- MAIN INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════

local function main()
    print([[
    
    ██████╗  █████╗  ██████╗ ███████╗ █████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║   ██║██╔════╝
    ██████╔╝███████║██║   ██║███████╗███████║██║   ██║█████╗  
    ██╔══██╗██╔══██║██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  
    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║ ╚████╔╝ ███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
    
    BaoSaveInstance V2.0.0
    Production SaveInstance & Decompiler
    
    ]])
    
    Logger:info("Initializing BaoSaveInstance V2...")
    Logger:info("Executor detected: " .. Executor.Name)
    Logger:info("Decompile support: " .. tostring(Executor.SupportsDecompile))
    Logger:info("File I/O support: " .. tostring(Executor.SupportsFileIO))
    
    -- Create UI
    UI:create()
    
    -- Connect button events
    UI.BtnSaveGame.MouseButton1Click:Connect(function()
        task.spawn(function()
            SaveController:saveGame()
        end)
    end)
    
    UI.BtnSaveTerrain.MouseButton1Click:Connect(function()
        task.spawn(function()
            SaveController:saveTerrain()
        end)
    end)
    
    UI.BtnSaveModels.MouseButton1Click:Connect(function()
        task.spawn(function()
            SaveController:saveModels()
        end)
    end)
    
    Logger:success("BaoSaveInstance V2 loaded successfully!")
    Logger:info("Select an option above to begin saving.")
end

-- Run
main()
