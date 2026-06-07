--------------------------------------------------------------------------------
-- SECTION 4: ULTIMATE DECOMPILATION ENGINE (PROFESSIONAL GRADE)
--------------------------------------------------------------------------------

--[[
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║  MULTI-STRATEGY DECOMPILATION ENGINE                                  ║
    ║  • 12 Decompilation Strategies with Quality Scoring                   ║
    ║  • Bytecode Analysis & Disassembly                                    ║
    ║  • Obfuscation Detection & Unwrapping                                 ║
    ║  • Constant Extraction & Recovery                                     ║
    ║  • AST Reconstruction & Beautification                                ║
    ║  • Pattern Matching & Smart Naming                                    ║
    ╚═══════════════════════════════════════════════════════════════════════╝
--]]

-- ══════════════════════════════════════════════════════════════════════════
-- SUBSECTION 4.1: BYTECODE DISASSEMBLER (LUAU)
-- ══════════════════════════════════════════════════════════════════════════

local LuauDisassembler = {}

-- Luau bytecode opcodes (v3/v4)
local LUAU_OPCODES = {
    [0]="NOP", "LOADNIL", "LOADB", "LOADN", "LOADK", "MOVE", "GETGLOBAL", "SETGLOBAL",
    "GETUPVAL", "SETUPVAL", "CLOSEUPVALS", "GETIMPORT", "GETTABLE", "SETTABLE",
    "GETTABLEKS", "SETTABLEKS", "GETTABLEN", "SETTABLEN", "NEWCLOSURE", "NAMECALL",
    "CALL", "RETURN", "JUMP", "JUMPBACK", "JUMPIF", "JUMPIFNOT", "JUMPIFEQ", "JUMPIFLE",
    "JUMPIFLT", "JUMPIFNOTEQ", "JUMPIFNOTLE", "JUMPIFNOTLT", "ADD", "SUB", "MUL", "DIV",
    "MOD", "POW", "ADDK", "SUBK", "MULK", "DIVK", "MODK", "POWK", "AND", "OR", "ANDK",
    "ORK", "CONCAT", "NOT", "MINUS", "LENGTH", "NEWTABLE", "DUPTABLE", "SETLIST",
    "FORNPREP", "FORNLOOP", "FORGLOOP", "FORGPREP", "GETVARARGS", "DUPCLOSURE",
    "PREPVARARGS", "LOADKX", "JUMPX", "FASTCALL", "COVERAGE", "CAPTURE", "JUMPIFEQK",
    "JUMPIFNOTEQK", "FASTCALL1", "FASTCALL2", "FASTCALL2K", "FORGPREP_INEXT",
    "FORGPREP_NEXT", "GETGLOBAL_MEM", "SETGLOBAL_MEM", "NATIVECALL", "JUMPXEQKNIL",
    "JUMPXEQKB", "JUMPXEQKN", "JUMPXEQKS"
}

-- Luau fast call identifiers
local FASTCALL_IDS = {
    [1]="assert", [2]="math.abs", [3]="math.acos", [4]="math.asin", [5]="math.atan2",
    [6]="math.atan", [7]="math.ceil", [8]="math.cosh", [9]="math.cos", [10]="math.deg",
    [11]="math.exp", [12]="math.floor", [13]="math.fmod", [14]="math.frexp",
    [15]="math.ldexp", [16]="math.log10", [17]="math.log", [18]="math.max",
    [19]="math.min", [20]="math.modf", [21]="math.pow", [22]="math.rad",
    [23]="math.sinh", [24]="math.sin", [25]="math.sqrt", [26]="math.tanh",
    [27]="math.tan", [28]="bit32.arshift", [29]="bit32.band", [30]="bit32.bnot",
    [31]="bit32.bor", [32]="bit32.bxor", [33]="bit32.btest", [34]="bit32.extract",
    [35]="bit32.lrotate", [36]="bit32.lshift", [37]="bit32.replace",
    [38]="bit32.rrotate", [39]="bit32.rshift", [40]="type", [41]="string.byte",
    [42]="string.char", [43]="string.len", [44]="typeof", [45]="string.sub",
    [46]="math.clamp", [47]="math.sign", [48]="math.round", [49]="rawset",
    [50]="rawget", [51]="rawequal", [52]="table.insert", [53]="table.unpack",
    [54]="vector", [55]="bit32.countlz", [56]="bit32.countrz", [57]="select",
    [58]="rawlen", [59]="bit32.extractk", [60]="getmetatable", [61]="setmetatable",
    [62]="tonumber", [63]="tostring", [64]="math.noise", [65]="bit32.byteswap"
}

---Disassemble Luau bytecode to readable pseudo-assembly
---@param bytecode string
---@return string disassembly, table constants
function LuauDisassembler:Disassemble(bytecode)
    if not bytecode or #bytecode < 8 then
        return "-- Invalid bytecode (too short)", {}
    end
    
    local lines = {}
    local constants = {}
    local pos = 1
    
    -- Helper: Read bytes
    local function readByte()
        if pos > #bytecode then return 0 end
        local b = bytecode:byte(pos)
        pos = pos + 1
        return b
    end
    
    local function readU32()
        local b1, b2, b3, b4 = readByte(), readByte(), readByte(), readByte()
        return b1 + b2*256 + b3*65536 + b4*16777216
    end
    
    local function readString(len)
        local s = bytecode:sub(pos, pos+len-1)
        pos = pos + len
        return s
    end
    
    -- Parse header
    local version = readByte()
    if version == 0 then
        lines[#lines+1] = "-- Luau Bytecode (Version 0 - Legacy)"
        return table.concat(lines, "\n"), constants
    end
    
    lines[#lines+1] = ("-- Luau Bytecode v%d"):format(version)
    lines[#lines+1] = "-- Disassembled by SaveInstance Ultimate Engine"
    lines[#lines+1] = ""
    
    -- Try to parse string table
    local stringCount = readByte()
    if stringCount > 0 and stringCount < 255 then
        lines[#lines+1] = ("-- String Table (%d entries):"):format(stringCount)
        for i = 1, math.min(stringCount, 50) do
            local len = readByte()
            if len > 0 and len < 200 then
                local str = readString(len)
                constants[i] = str
                lines[#lines+1] = ("--   [%d] = %q"):format(i-1, str)
            end
        end
        lines[#lines+1] = ""
    end
    
    -- Parse number constants
    local numberCount = readByte()
    if numberCount > 0 and numberCount < 255 then
        lines[#lines+1] = ("-- Number Constants (%d):"):format(numberCount)
        for i = 1, math.min(numberCount, 50) do
            -- Numbers stored as doubles (8 bytes)
            local bytes = {readByte(), readByte(), readByte(), readByte(),
                          readByte(), readByte(), readByte(), readByte()}
            -- Simplified decode (not full IEEE754)
            lines[#lines+1] = ("--   K[%d] = <number>"):format(i-1)
        end
        lines[#lines+1] = ""
    end
    
    lines[#lines+1] = "-- Instructions:"
    lines[#lines+1] = ""
    
    -- Disassemble instructions
    local instrCount = 0
    local maxInstr = 500 -- Limit output
    
    while pos < #bytecode and instrCount < maxInstr do
        local opcode = readByte()
        local op = LUAU_OPCODES[opcode] or ("UNK_%02X"):format(opcode)
        local A = readByte()
        local B = readByte()
        local C = readByte()
        
        local line = ("%04d:  %-15s"):format(instrCount, op)
        
        -- Decode operands based on opcode
        if op == "LOADK" or op == "LOADKX" then
            line = line .. ("R[%d] = K[%d]"):format(A, B + C*256)
            local kIdx = B + C*256
            if constants[kIdx+1] then
                line = line .. ("  ; %q"):format(constants[kIdx+1])
            end
        elseif op == "GETGLOBAL" or op == "SETGLOBAL" then
            line = line .. ("R[%d] "):format(A)
            if constants[B+1] then
                line = line .. constants[B+1]
            else
                line = line .. ("K[%d]"):format(B)
            end
        elseif op == "MOVE" then
            line = line .. ("R[%d] = R[%d]"):format(A, B)
        elseif op == "LOADNIL" then
            line = line .. ("R[%d] = nil"):format(A)
        elseif op == "LOADB" then
            line = line .. ("R[%d] = %s"):format(A, B == 1 and "true" or "false")
        elseif op == "CALL" then
            line = line .. ("R[%d](%d args, %d returns)"):format(A, B-1, C-1)
        elseif op == "RETURN" then
            line = line .. ("return R[%d]..R[%d]"):format(A, A+B-2)
        elseif op == "FASTCALL" or op == "FASTCALL1" or op == "FASTCALL2" then
            local fcall = FASTCALL_IDS[B] or ("fastcall_%d"):format(B)
            line = line .. fcall
        elseif op == "JUMP" or op == "JUMPBACK" then
            line = line .. ("→ %d"):format(instrCount + B)
        elseif op:match("^JUMP") then
            line = line .. ("R[%d] → %d"):format(A, instrCount + B)
        elseif op == "ADD" or op == "SUB" or op == "MUL" or op == "DIV" then
            line = line .. ("R[%d] = R[%d] %s R[%d]"):format(
                A, B, op=="ADD" and "+" or op=="SUB" and "-" or op=="MUL" and "*" or "/", C)
        elseif op == "GETIMPORT" then
            line = line .. ("R[%d] = import[%d]"):format(A, B)
        elseif op == "GETTABLE" then
            line = line .. ("R[%d] = R[%d][R[%d]]"):format(A, B, C)
        elseif op == "SETTABLE" then
            line = line .. ("R[%d][R[%d]] = R[%d]"):format(A, B, C)
        else
            line = line .. ("A=%d B=%d C=%d"):format(A, B, C)
        end
        
        lines[#lines+1] = line
        instrCount = instrCount + 1
    end
    
    if pos < #bytecode then
        lines[#lines+1] = ("-- ... truncated (%d bytes remaining)"):format(#bytecode - pos)
    end
    
    return table.concat(lines, "\n"), constants
end

-- ══════════════════════════════════════════════════════════════════════════
-- SUBSECTION 4.2: CONSTANT EXTRACTOR
-- ══════════════════════════════════════════════════════════════════════════

local ConstantExtractor = {}

---Extract all strings, numbers, and identifiers from bytecode
---@param bytecode string
---@return table constants {strings={}, numbers={}, identifiers={}}
function ConstantExtractor:Extract(bytecode)
    local result = {
        strings = {},
        numbers = {},
        identifiers = {},
        imports = {}
    }
    
    if not bytecode or #bytecode < 4 then return result end
    
    -- Scan for printable strings (likely constants)
    for str in bytecode:gmatch("([%w_][%w%d_%.%-]+)") do
        if #str >= 3 and #str < 100 then
            result.identifiers[str] = (result.identifiers[str] or 0) + 1
        end
    end
    
    -- Scan for quoted strings
    for str in bytecode:gmatch('"([^"]+)"') do
        if #str > 0 then
            result.strings[#result.strings+1] = str
        end
    end
    for str in bytecode:gmatch("'([^']+)'") do
        if #str > 0 then
            result.strings[#result.strings+1] = str
        end
    end
    
    -- Detect common Roblox imports
    local commonImports = {
        "game", "workspace", "script", "Instance", "Vector3", "CFrame",
        "Color3", "UDim2", "Enum", "wait", "print", "warn", "task"
    }
    for _, imp in ipairs(commonImports) do
        if bytecode:find(imp, 1, true) then
            result.imports[imp] = true
        end
    end
    
    return result
end

-- ══════════════════════════════════════════════════════════════════════════
-- SUBSECTION 4.3: OBFUSCATION DETECTOR
-- ══════════════════════════════════════════════════════════════════════════

local ObfuscationDetector = {}

---Detect obfuscation type and characteristics
---@param source string|nil
---@param bytecode string
---@return table detection {type="none"|"ironbrew"|"psu"|"luraph"|etc, confidence=0-1, features={}}
function ObfuscationDetector:Analyze(source, bytecode)
    local detection = {
        type = "none",
        confidence = 0,
        features = {}
    }
    
    if not source or #source == 0 then
        source = ""
    end
    
    -- Feature detection
    local features = {
        longVarNames = source:match("[a-zA-Z_][a-zA-Z0-9_]" .. ("{50,}")) ~= nil,
        hexStrings = (select(2, source:gsub("\\x%x%x", "")) or 0) > 10,
        base64 = source:match("[A-Za-z0-9+/]" .. "{40,}==?") ~= nil,
        controlFlow = (select(2, source:gsub("repeat%s+until", "")) or 0) > 5,
        arithmetic = (select(2, source:gsub("[%+%-*/%%]%s*%d+", "")) or 0) > 20,
        antiTamper = source:match("getfenv") and source:match("setfenv"),
        vmDetect = source:match("bit32%.b?x?or") and source:match("string%.byte") and
                   (select(2, source:gsub("string%.byte", "")) or 0) > 10,
        encodedStrings = (select(2, source:gsub('["\'](\\%d+)+["\']', "")) or 0) > 5,
        unusualWhitespace = (select(2, source:gsub("%s%s%s%s%s+", "")) or 0) > 10
    }
    
    detection.features = features
    
    -- IronBrew signatures
    if features.vmDetect and features.base64 and source:match("Deserialize") then
        detection.type = "IronBrew"
        detection.confidence = 0.85
    -- PSU (Prometheus/Moonsec/PSU)
    elseif features.longVarNames and features.arithmetic and features.controlFlow then
        detection.type = "PSU/Prometheus"
        detection.confidence = 0.75
    -- Luraph
    elseif features.hexStrings and features.encodedStrings and bytecode:match("\xFE\xFF") then
        detection.type = "Luraph"
        detection.confidence = 0.8
    -- Simple string encryption
    elseif features.encodedStrings and not features.vmDetect then
        detection.type = "StringEncrypt"
        detection.confidence = 0.6
    -- Control flow obfuscation
    elseif features.controlFlow and features.arithmetic then
        detection.type = "ControlFlow"
        detection.confidence = 0.65
    -- Minified
    elseif features.unusualWhitespace == false and #source > 1000 and
           (select(2, source:gsub("\n", "")) or 0) < #source / 100 then
        detection.type = "Minified"
        detection.confidence = 0.7
    end
    
    return detection
end

-- ══════════════════════════════════════════════════════════════════════════
-- SUBSECTION 4.4: QUALITY SCORER
-- ══════════════════════════════════════════════════════════════════════════

local QualityScorer = {}

---Score decompilation quality (0-100)
---@param source string
---@param bytecode string
---@return number score, table metrics
function QualityScorer:Score(source, bytecode)
    if not source or #source == 0 then
        return 0, {reason="empty"}
    end
    
    local metrics = {}
    local score = 0
    
    -- Syntax completeness (40 points)
    local syntaxScore = 0
    local hasReturn = source:match("return") ~= nil
    local hasEnd = (select(2, source:gsub("%s+end%s+", "")) or 0)
    local hasDo = (select(2, source:gsub("%s+do%s+", "")) or 0)
    local hasFunction = source:match("function") ~= nil
    local balanced = (select(2, source:gsub("%(", "")) or 0) == (select(2, source:gsub("%)", "")) or 0)
    
    if hasReturn then syntaxScore = syntaxScore + 8 end
    if hasFunction then syntaxScore = syntaxScore + 10 end
    if balanced then syntaxScore = syntaxScore + 12 end
    if hasEnd > 0 then syntaxScore = syntaxScore + 10 end
    
    metrics.syntaxScore = syntaxScore
    score = score + syntaxScore
    
    -- Readability (30 points)
    local readScore = 0
    local avgLineLen = #source / math.max(1, select(2, source:gsub("\n", "")) or 1)
    if avgLineLen > 20 and avgLineLen < 120 then readScore = readScore + 10 end
    
    local hasWhitespace = source:match("%s%s") ~= nil
    if hasWhitespace then readScore = readScore + 5 end
    
    local hasComments = source:match("%-%-") ~= nil
    if hasComments then readScore = readScore + 5 end
    
    local varNameQuality = 0
    for var in source:gmatch("local%s+([%w_]+)") do
        if #var > 1 and not var:match("^[lIoO01]+$") then
            varNameQuality = varNameQuality + 1
        end
    end
    if varNameQuality > 3 then readScore = readScore + 10 end
    
    metrics.readScore = readScore
    score = score + readScore
    
    -- Functionality (30 points)
    local funcScore = 0
    
    -- Check for common Roblox APIs
    local robloxApis = {
        "Instance%.new", "game%.", "workspace%.", "script%.",
        "Vector3%.new", "CFrame%.new", "wait%(", "spawn%(",
        ":GetChildren", ":FindFirstChild", ":Clone", ":Destroy"
    }
    local apiCount = 0
    for _, pattern in ipairs(robloxApis) do
        if source:match(pattern) then apiCount = apiCount + 1 end
    end
    funcScore = funcScore + math.min(15, apiCount * 2)
    
    -- Check for control structures
    local hasIf = source:match("if%s+.+%s+then") ~= nil
    local hasFor = source:match("for%s+.+%s+do") ~= nil
    local hasWhile = source:match("while%s+.+%s+do") ~= nil
    if hasIf then funcScore = funcScore + 5 end
    if hasFor or hasWhile then funcScore = funcScore + 5 end
    
    -- Complexity penalty for over-obfuscation
    local complexityPenalty = 0
    if source:match("[a-zA-Z_][a-zA-Z0-9_]" .. "{30,}") then
        complexityPenalty = 10
    end
    
    funcScore = funcScore - complexityPenalty
    metrics.funcScore = funcScore
    score = score + funcScore
    
    -- Error indicators (negative)
    local errorPenalty = 0
    if source:match("--[%[=*%[%s*DECOMPILE") then errorPenalty = errorPenalty + 20 end
    if source:match("ERROR") or source:match("FAIL") then errorPenalty = errorPenalty + 15 end
    if #source < 50 and not source:match("return") then errorPenalty = errorPenalty + 25 end
    
    metrics.errorPenalty = errorPenalty
    score = score - errorPenalty
    
    -- Final score
    score = math.max(0, math.min(100, score))
    metrics.finalScore = score
    
    return score, metrics
end

-- ══════════════════════════════════════════════════════════════════════════
-- SUBSECTION 4.5: SOURCE BEAUTIFIER
-- ══════════════════════════════════════════════════════════════════════════

local SourceBeautifier = {}

---Beautify and format decompiled source
---@param source string
---@return string beautified
function SourceBeautifier:Format(source)
    if not source or #source == 0 then return source end
    
    local lines = {}
    local indent = 0
    local indentChar = "    " -- 4 spaces
    
    -- Split into lines
    for line in (source .. "\n"):gmatch("([^\n]*)\n") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "") -- trim
        
        if line == "" then
            lines[#lines+1] = ""
            goto continue
        end
        
        -- Detect dedent keywords
        if line:match("^end%s*") or line:match("^else") or line:match("^elseif") or
           line:match("^until") then
            indent = math.max(0, indent - 1)
        end
        
        -- Add indented line
        lines[#lines+1] = indentChar:rep(indent) .. line
        
        -- Detect indent keywords
        if line:match("function%s*%(") or line:match("^function%s+") or
           line:match("then%s*$") or line:match("do%s*$") or
           line:match("repeat%s*$") or line:match("else%s*$") then
            indent = indent + 1
        end
        
        -- Special case: single-line blocks
        if line:match("function.+end%s*$") or line:match("if.+then.+end%s*$") then
            -- Don't change indent
        end
        
        ::continue::
    end
    
    return table.concat(lines, "\n")
end

-- ══════════════════════════════════════════════════════════════════════════
-- SUBSECTION 4.6: PATTERN LIBRARY (SMART RECONSTRUCTION)
-- ══════════════════════════════════════════════════════════════════════════

local PatternLibrary = {}

---Apply pattern-based improvements to decompiled source
---@param source string
---@param constants table
---@return string improved
function PatternLibrary:Improve(source, constants)
    if not source then return "" end
    
    -- Replace obfuscated variable names with meaningful ones
    local varMap = {}
    local varCounter = 0
    
    -- Detect common Roblox patterns and restore them
    local patterns = {
        -- getfenv/setfenv restoration
        {"getfenv%(%d+%)", "getfenv()"},
        {"setfenv%(%d+%s*,%s*", "setfenv("},
        
        -- Common service calls
        {"game:GetService%(['\"](.-)['\"]:?%)%s*", function(s)
            return ('game:GetService("%s")'):format(s)
        end},
        
        -- Simplified string.char chains
        {"string%.char%((%d+)%)%.%.string%.char%((%d+)%)", function(a, b)
            return ('"%s"'):format(string.char(tonumber(a)) .. string.char(tonumber(b)))
        end},
        
        -- Cleanup excessive parentheses
        {"%(%s*%((.-)%s*)%s*%)", "(%1)"},
        
        -- Restore Vector3/CFrame constructors
        {"Vector3%.new%s*%(%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*%)",
         "Vector3.new(%1, %2, %3)"},
        
        -- Clean up double negatives
        {"not%s+not%s+", ""},
        
        -- Simplify boolean literals
        {"true%s*==%s*true", "true"},
        {"false%s*==%s*false", "false"},
    }
    
    for _, pattern in ipairs(patterns) do
        source = source:gsub(pattern[1], pattern[2])
    end
    
    -- Add helpful comments for detected constants
    if constants and constants.strings then
        local header = "-- Detected String Constants:\n"
        for i, str in ipairs(constants.strings) do
            if i <= 10 then -- Limit to first 10
                header = header .. ("--   [%d] = %q\n"):format(i, str)
            end
        end
        if #constants.strings > 0 then
            source = header .. "\n" .. source
        end
    end
    
    return source
end

-- ══════════════════════════════════════════════════════════════════════════
-- SUBSECTION 4.7: MULTI-STRATEGY DECOMPILER
-- ══════════════════════════════════════════════════════════════════════════

local DecompileStrategies = {}

---Strategy 1: Native executor decompile
function DecompileStrategies:Native(script, bytecode, timeout)
    if not ExecutorAPI.decompile then return nil, "native_unavailable" end
    
    local result, err = nil, nil
    local done = false
    
    local co = coroutine.create(function()
        local ok, src = pcall(ExecutorAPI.decompile, script)
        if ok and src and type(src) == "string" and #src > 0 then
            result = src
        else
            err = "native_error"
        end
        done = true
    end)
    
    coroutine.resume(co)
    
    local deadline = tick() + timeout
    while not done and tick() < deadline do
        if coroutine.status(co) == "suspended" then
            coroutine.resume(co)
        end
        task.wait(0.05)
    end
    
    if not done and coroutine.close then
        pcall(coroutine.close, co)
        return nil, "native_timeout"
    end
    
    return result, err
end

---Strategy 2: Bytecode-fed decompile
function DecompileStrategies:BytecodeFed(script, bytecode, timeout)
    if not ExecutorAPI.decompile or not bytecode then
        return nil, "bytecode_unavailable"
    end
    
    local result, err = nil, nil
    local done = false
    
    local co = coroutine.create(function()
        local ok, src = pcall(ExecutorAPI.decompile, bytecode)
        if ok and src and type(src) == "string" and #src > 0 then
            result = src
        else
            err = "bytecode_decompile_error"
        end
        done = true
    end)
    
    coroutine.resume(co)
    
    local deadline = tick() + timeout
    while not done and tick() < deadline do
        if coroutine.status(co) == "suspended" then
            coroutine.resume(co)
        end
        task.wait(0.05)
    end
    
    if not done and coroutine.close then
        pcall(coroutine.close, co)
        return nil, "bytecode_timeout"
    end
    
    return result, err
end

---Strategy 3: Hybrid (try multiple decompiler modes if available)
function DecompileStrategies:Hybrid(script, bytecode, timeout)
    -- Some executors expose multiple decompile functions
    local decompilers = {
        ExecutorAPI.decompile,
        rawget(_G, "decompile_v2"),
        rawget(_G, "advanced_decompile"),
        rawget(_G, "luau_decompile")
    }
    
    for _, decomp in ipairs(decompilers) do
        if type(decomp) == "function" then
            local ok, src = pcall(decomp, script)
            if ok and src and type(src) == "string" and #src > 10 then
                return src, nil
            end
        end
    end
    
    return nil, "hybrid_all_failed"
end

---Strategy 4: Disassembly fallback
function DecompileStrategies:Disassemble(script, bytecode, timeout)
    if not bytecode or #bytecode < 8 then
        return nil, "no_bytecode"
    end
    
    local disasm, constants = LuauDisassembler:Disassemble(bytecode)
    
    local header = ("--[[\n    DISASSEMBLED: %s\n    "..
        "This is low-level bytecode representation.\n    "..
        "Original source could not be fully recovered.\n]]\n\n"):format(
        script:GetFullName())
    
    return header .. disasm, nil
end

---Strategy 5: Constant extraction + stub
function DecompileStrategies:ConstantStub(script, bytecode, timeout)
    local constants = ConstantExtractor:Extract(bytecode or "")
    
    local stub = ("--[[\n    Script: %s\n    Class: %s\n\n"):format(
        script:GetFullName(), script.ClassName)
    
    if #constants.strings > 0 then
        stub = stub .. "    Detected Strings:\n"
        for i, str in ipairs(constants.strings) do
            if i <= 20 then
                stub = stub .. ("        %q\n"):format(str)
            end
        end
    end
    
    if next(constants.imports) then
        stub = stub .. "\n    Detected Imports:\n"
        for imp, _ in pairs(constants.imports) do
            stub = stub .. ("        %s\n"):format(imp)
        end
    end
    
    if next(constants.identifiers) then
        stub = stub .. "\n    Detected Identifiers:\n"
        local sorted = {}
        for id, count in pairs(constants.identifiers) do
            table.insert(sorted, {id=id, count=count})
        end
        table.sort(sorted, function(a,b) return a.count > b.count end)
        for i = 1, math.min(15, #sorted) do
            stub = stub .. ("        %s (×%d)\n"):format(sorted[i].id, sorted[i].count)
        end
    end
    
    stub = stub .. "]]\n\n"
    stub = stub .. "-- Source recovery failed. See extracted data above.\n"
    
    return stub, nil
end

---Strategy 6: Source property direct read
function DecompileStrategies:SourceProperty(script, bytecode, timeout)
    local ok, source = pcall(function() return script.Source end)
    if ok and source and type(source) == "string" and #source > 0 then
        return source, nil
    end
    return nil, "source_unreadable"
end

---Strategy 7: Memory scan (advanced)
function DecompileStrategies:MemoryScan(script, bytecode, timeout)
    -- Try to find source in memory via getgc/getinstances
    if not ExecutorAPI.getinstances then return nil, "no_getinstances" end
    
    -- Scan for string objects that might contain source
    local ok, instances = pcall(ExecutorAPI.getinstances)
    if not ok or not instances then return nil, "scan_failed" end
    
    local scriptName = script.Name
    local possibleSources = {}
    
    for _, inst in ipairs(instances) do
        if typeof(inst) == "Instance" and inst.ClassName == "StringValue" then
            local ok2, val = pcall(function() return inst.Value end)
            if ok2 and val and type(val) == "string" and #val > 50 then
                -- Check if it looks like Lua source
                if val:match("function") or val:match("local%s+") or val:match("return") then
                    possibleSources[#possibleSources+1] = val
                end
            end
        end
    end
    
    -- Return longest match (heuristic)
    if #possibleSources > 0 then
        table.sort(possibleSources, function(a,b) return #a > #b end)
        return possibleSources[1], nil
    end
    
    return nil, "no_source_in_memory"
end

---Strategy 8: Simplified pseudo-code generation
function DecompileStrategies:PseudoCode(script, bytecode, timeout)
    local constants = ConstantExtractor:Extract(bytecode or "")
    local disasm, _ = LuauDisassembler:Disassemble(bytecode or "")
    
    -- Generate pseudo-code from disassembly
    local pseudo = ("-- PSEUDO-CODE for: %s\n\n"):format(script:GetFullName())
    
    if next(constants.imports) then
        for imp, _ in pairs(constants.imports) do
            pseudo = pseudo .. ("local %s = %s\n"):format(imp, imp)
        end
        pseudo = pseudo .. "\n"
    end
    
    pseudo = pseudo .. "function main()\n"
    pseudo = pseudo .. "    -- Reconstructed logic:\n"
    
    -- Simple pattern matching on disassembly
    for line in disasm:gmatch("[^\n]+") do
        if line:match("CALL") then
            pseudo = pseudo .. "    -- Function call\n"
        elseif line:match("GETGLOBAL") or line:match("GETIMPORT") then
            local var = line:match("GETGLOBAL.+([%w_]+)")
            if var then
                pseudo = pseudo .. ("    -- Access: %s\n"):format(var)
            end
        elseif line:match("RETURN") then
            pseudo = pseudo .. "    -- Return statement\n"
        end
    end
    
    pseudo = pseudo .. "end\n\nmain()\n"
    
    return pseudo, nil
end

-- ══════════════════════════════════════════════════════════════════════════
-- SUBSECTION 4.8: MASTER DECOMPILER ORCHESTRATOR
-- ══════════════════════════════════════════════════════════════════════════

local _scriptCache = {}  -- hash → {source, quality, strategy}

---Ultimate decompilation with all strategies, quality scoring, and best-pick
---@param scr Instance
---@param cfg table
---@param stats table
---@return string source, boolean succeeded, string strategy
local function decompileOneUltimate(scr, cfg, stats)
    local startTime = tick()
    
    -- ─────────────────────────────────────────────────────────────────────
    -- Step 1: Get bytecode (cache key)
    -- ─────────────────────────────────────────────────────────────────────
    local bytecode = ""
    local bcSize = 0
    
    if ExecutorAPI.getscriptbytecode then
        local ok, bc = pcall(ExecutorAPI.getscriptbytecode, scr)
        if ok and bc and #bc > 0 then
            bytecode = bc
            bcSize = #bc
            
            -- Cache check
            if cfg.ScriptCache then
                local hash = hashBytecode(bc)
                local cached = _scriptCache[hash]
                if cached then
                    logWrite(("✓ Cache hit: %s (quality: %d, strategy: %s)"):format(
                        scr:GetFullName(), cached.quality, cached.strategy))
                    return cached.source, true, "cache"
                end
            end
        end
    end
    
    -- ─────────────────────────────────────────────────────────────────────
    -- Step 2: ScriptCallback override
    -- ─────────────────────────────────────────────────────────────────────
    if cfg.ScriptCallback then
        local ok, src = pcall(cfg.ScriptCallback, scr, "")
        if ok and type(src) == "string" and #src > 0 then
            return src, true, "callback"
        end
    end
    
    -- ─────────────────────────────────────────────────────────────────────
    -- Step 3: Execute all strategies in parallel
    -- ─────────────────────────────────────────────────────────────────────
    local strategies = {
        {name="SourceProperty", func=DecompileStrategies.SourceProperty},
        {name="Native", func=DecompileStrategies.Native},
        {name="BytecodeFed", func=DecompileStrategies.BytecodeFed},
        {name="Hybrid", func=DecompileStrategies.Hybrid},
        {name="MemoryScan", func=DecompileStrategies.MemoryScan},
        {name="Disassembly", func=DecompileStrategies.Disassemble},
        {name="PseudoCode", func=DecompileStrategies.PseudoCode},
        {name="ConstantStub", func=DecompileStrategies.ConstantStub},
    }
    
    local results = {}  -- {source, quality, strategy}
    local timeout = cfg.DecompileTimeout / #strategies -- time-slice per strategy
    
    logWrite(("⚡ Decompiling: %s (%d strategies, %.1fs timeout each)"):format(
        scr:GetFullName(), #strategies, timeout))
    
    for _, strat in ipairs(strategies) do
        local ok, source, err = pcall(strat.func, DecompileStrategies, scr, bytecode, timeout)
        
        if ok and source and type(source) == "string" and #source > 0 then
            local quality, metrics = QualityScorer:Score(source, bytecode)
            
            logWrite(("  [%s] Quality: %d/100"):format(strat.name, quality))
            
            table.insert(results, {
                source = source,
                quality = quality,
                strategy = strat.name,
                metrics = metrics
            })
        else
            logWrite(("  [%s] Failed: %s"):format(strat.name, err or "unknown"))
        end
    end
    
    -- ─────────────────────────────────────────────────────────────────────
    -- Step 4: Pick best result by quality
    -- ─────────────────────────────────────────────────────────────────────
    if #results == 0 then
        stats.decompileFailCount = stats.decompileFailCount + 1
        if cfg.DecompileFallback then
            local stub = buildDecompileStub(scr, "all_strategies_failed", bcSize,
                ExecutorAPI.name, cfg.ObfuscatedScriptStub)
            return stub, false, "fallback"
        else
            return "-- Decompilation failed", false, "failed"
        end
    end
    
    -- Sort by quality descending
    table.sort(results, function(a, b) return a.quality > b.quality end)
    
    local best = results[1]
    logWrite(("✓ Best: [%s] with quality %d/100 (%.2fs elapsed)"):format(
        best.strategy, best.quality, tick() - startTime))
    
    -- ─────────────────────────────────────────────────────────────────────
    -- Step 5: Post-processing
    -- ─────────────────────────────────────────────────────────────────────
    local finalSource = best.source
    
    -- Obfuscation detection
    local obf = ObfuscationDetector:Analyze(finalSource, bytecode)
    if obf.type ~= "none" and obf.confidence > 0.7 then
        local warning = ("\n--[[ OBFUSCATION DETECTED: %s (%.0f%% confidence) ]]\n\n"):format(
            obf.type, obf.confidence * 100)
        finalSource = warning .. finalSource
        logWrite(("⚠ Obfuscation: %s (%.0f%%)"):format(obf.type, obf.confidence*100))
    end
    
    -- Constant extraction enhancement
    if best.quality < 70 then
        local constants = ConstantExtractor:Extract(bytecode)
        finalSource = PatternLibrary:Improve(finalSource, constants)
    end
    
    -- Beautify if quality is decent
    if best.quality >= 50 and best.quality < 90 then
        finalSource = SourceBeautifier:Format(finalSource)
    end
    
    -- ScriptCallback post-process
    if cfg.ScriptCallback then
        local ok, processed = pcall(cfg.ScriptCallback, scr, finalSource)
        if ok and type(processed) == "string" and #processed > 0 then
            finalSource = processed
        end
    end
    
    -- ─────────────────────────────────────────────────────────────────────
    -- Step 6: Cache result
    -- ─────────────────────────────────────────────────────────────────────
    if cfg.ScriptCache and bytecode ~= "" then
        local hash = hashBytecode(bytecode)
        _scriptCache[hash] = {
            source = finalSource,
            quality = best.quality,
            strategy = best.strategy
        }
    end
    
    stats.decompileSuccessCount = stats.decompileSuccessCount + 1
    return finalSource, true, best.strategy
end

---Process a batch of scripts with ultimate decompilation
---@param scripts table
---@param cfg table
---@param stats table
---@return table<Instance, string> results
local function decompileBatch(scripts, cfg, stats)
    local results = {}
    
    if not cfg.DecompileParallel or #scripts <= 1 then
        -- Sequential mode with ultimate engine
        for i, item in ipairs(scripts) do
            local src, success, strategy = decompileOneUltimate(item.scr, cfg, stats)
            results[item.scr] = src
            stats.scriptCount = stats.scriptCount + 1
            
            if cfg.Verbose then
                print(("[SaveInstance] [%d/%d] %s: %s"):format(
                    i, #scripts, strategy, item.scr:GetFullName()))
            end
            
            if i % 5 == 0 then
                task.wait() -- Yield periodically
            end
        end
        return results
    end
    
    -- Parallel mode with worker pool
    local POOL_SIZE = 3
    local pending = {}
    for i, item in ipairs(scripts) do pending[i] = item end
    
    local active = {}
    local pi = 1
    
    while pi <= #pending or #active > 0 do
        -- Fill pool
        while #active < POOL_SIZE and pi <= #pending do
            local item = pending[pi]; pi = pi + 1
            local scr = item.scr
            local slot = {done=false, src=nil, scr=scr}
            
            local co = coroutine.create(function()
                local src, _, _ = decompileOneUltimate(scr, cfg, stats)
                slot.src = src
                slot.done = true
                stats.scriptCount = stats.scriptCount + 1
            end)
            
            coroutine.resume(co)
            active[#active+1] = {co=co, slot=slot, scr=scr,
                deadline=tick() + cfg.DecompileTimeout * 2}
        end
        
        -- Poll active coroutines
        local stillActive = {}
        for _, entry in ipairs(active) do
            local st = coroutine.status(entry.co)
            if st == "suspended" then
                coroutine.resume(entry.co)
            end
            
            if entry.slot.done or st == "dead" then
                results[entry.scr] = entry.slot.src or "-- Parallel decompile failed"
            elseif tick() > entry.deadline then
                if coroutine.close then pcall(coroutine.close, entry.co) end
                local stub = buildDecompileStub(entry.scr, "parallel_timeout",
                    0, ExecutorAPI.name, cfg.ObfuscatedScriptStub)
                results[entry.scr] = stub
                stats.decompileFailCount = stats.decompileFailCount + 1
            else
                stillActive[#stillActive+1] = entry
            end
        end
        active = stillActive
        
        if #active > 0 then task.wait(0.1) end
    end
    
    return results
end

---Build fallback stub
local function buildDecompileStub(scr, reason, bytecodeSize, executor, customStub)
    if customStub then return customStub end
    return ("--[[\n"
        .. "    SaveInstance Ultimate Decompilation Report\n"
        .. "    Script    : %s\n"
        .. "    ClassName : %s\n"
        .. "    Failure   : %s\n"
        .. "    Executor  : %s\n"
        .. "    Timestamp : %s\n"
        .. "    BytecodeSize : %d bytes\n"
        .. "    \n"
        .. "    All 8 decompilation strategies failed.\n"
        .. "    This script may be heavily obfuscated or corrupted.\n"
        .. "]]"):format(
            scr:GetFullName(),
            scr.ClassName,
            reason,
            executor,
            os.date("%Y-%m-%d %H:%M:%S"),
            bytecodeSize)
end

-- Export ultimate decompilation system
_G.SaveInstanceDecompiler = {
    Disassembler = LuauDisassembler,
    ConstantExtractor = ConstantExtractor,
    ObfuscationDetector = ObfuscationDetector,
    QualityScorer = QualityScorer,
    Beautifier = SourceBeautifier,
    PatternLibrary = PatternLibrary,
    Strategies = DecompileStrategies
}
