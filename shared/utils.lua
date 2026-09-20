-- ============================================================
--  JobClothing - Shared Utilities
-- ============================================================

--- Print debug message if Config.Debug is enabled
---@param msg string
---@param ... any
function DebugPrint(msg, ...)
    if Config and Config.Debug then
        local formatted = string.format("[JobClothing] " .. msg, ...)
        print(formatted)
    end
end

--- Deep copy a table
---@param orig table
---@return table
function DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for k, v in pairs(orig) do
            copy[DeepCopy(k)] = DeepCopy(v)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

--- Merge table b into table a (shallow for top-level keys)
---@param a table
---@param b table
---@return table
function MergeTable(a, b)
    local result = DeepCopy(a)
    for k, v in pairs(b) do
        result[k] = v
    end
    return result
end

--- Check if a value exists in a table
---@param tbl table
---@param val any
---@return boolean
function TableContains(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then return true end
    end
    return false
end

--- Generate a simple unique ID (server-side only)
---@return string
function GenerateUID()
    return string.format("%08x", math.random(0, 0xFFFFFFFF))
end

--- Safe JSON decode — returns nil on failure
---@param str string
---@return table|nil
function SafeJsonDecode(str)
    if not str or str == "" then return nil end
    local ok, result = pcall(json.decode, str)
    if ok then return result else return nil end
end

--- Safe JSON encode — returns "{}" on failure
---@param tbl table
---@return string
function SafeJsonEncode(tbl)
    if not tbl then return "{}" end
    local ok, result = pcall(json.encode, tbl)
    if ok then return result else return "{}" end
end
