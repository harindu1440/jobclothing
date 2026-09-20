-- ============================================================
--  JobClothing - Server Ped Management + Storage
-- ============================================================

Peds = {}
local _storage = nil   -- "oxmysql" | "json"
local _pedsCache = {}  -- in-memory cache of all peds

-- ──────────────────────────────────────────────────────────
--  Storage Backend Initialisation
-- ──────────────────────────────────────────────────────────

local JSON_PATH_PEDS     = nil
local JSON_PATH_UNIFORMS = nil

local function GetJsonPath(filename)
    return GetResourcePath(GetCurrentResourceName()) .. "/" .. Config.JsonDataPath .. "/" .. filename
end

local function EnsureJsonDir()
    local dir = GetResourcePath(GetCurrentResourceName()) .. "/" .. Config.JsonDataPath
    -- FiveM doesn't expose a mkdir; we write an empty file to create path implicitly
    -- The data/ directory should exist (created by writing any file)
end

local function ReadJson(filepath)
    local f = io.open(filepath, "r")
    if not f then return {} end
    local content = f:read("*a")
    f:close()
    return SafeJsonDecode(content) or {}
end

local function WriteJson(filepath, data)
    local f = io.open(filepath, "w")
    if not f then
        print("^1[JobClothing] ERROR: Cannot write JSON file: " .. filepath .. "^7")
        return false
    end
    f:write(SafeJsonEncode(data))
    f:close()
    return true
end

local function DetectStorage()
    local cfg = Config.Storage or "auto"
    if cfg == "json" then
        _storage = "json"
    elseif cfg == "oxmysql" then
        _storage = "oxmysql"
    else
        -- Auto
        if GetResourceState('oxmysql') == 'started' then
            _storage = "oxmysql"
        else
            _storage = "json"
        end
    end
    print(string.format("^2[JobClothing] Storage: %s^7", _storage))
end

-- ──────────────────────────────────────────────────────────
--  Internal JSON helpers
-- ──────────────────────────────────────────────────────────

local _jsonPeds     = nil
local _nextJsonId   = 1

local function LoadJsonPeds()
    _jsonPeds = ReadJson(GetJsonPath("peds.json"))
    -- Rebuild next ID
    _nextJsonId = 1
    for _, p in ipairs(_jsonPeds) do
        if p.id >= _nextJsonId then _nextJsonId = p.id + 1 end
    end
end

local function SaveJsonPeds()
    WriteJson(GetJsonPath("peds.json"), _jsonPeds)
end

-- ──────────────────────────────────────────────────────────
--  Public API
-- ──────────────────────────────────────────────────────────

--- Load all peds from storage (called at resource start)
function Peds.LoadAll(callback)
    if _storage == "oxmysql" then
        MySQL.query('SELECT * FROM jobclothing_peds', {}, function(rows)
            _pedsCache = rows or {}
            if callback then callback(_pedsCache) end
        end)
    else
        LoadJsonPeds()
        _pedsCache = _jsonPeds
        if callback then callback(_pedsCache) end
    end
end

--- Get all peds (from cache)
function Peds.GetAll()
    return _pedsCache
end

--- Get a single ped by id
function Peds.GetById(id)
    id = tonumber(id)
    for _, p in ipairs(_pedsCache) do
        if p.id == id then return p end
    end
    return nil
end

--- Create a new ped entry
---@param data table {model, label, x, y, z, heading, created_by}
---@param callback function(newPed)
function Peds.Create(data, callback)
    if _storage == "oxmysql" then
        MySQL.insert(
            'INSERT INTO jobclothing_peds (model, label, x, y, z, heading, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)',
            { data.model, data.label or "", data.x, data.y, data.z, data.heading, data.created_by or "" },
            function(id)
                local newPed = {
                    id         = id,
                    model      = data.model,
                    label      = data.label or "",
                    x          = data.x,
                    y          = data.y,
                    z          = data.z,
                    heading    = data.heading,
                    created_by = data.created_by or "",
                    created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                }
                _pedsCache[#_pedsCache + 1] = newPed
                if callback then callback(newPed) end
            end
        )
    else
        LoadJsonPeds()
        local newPed = {
            id         = _nextJsonId,
            model      = data.model,
            label      = data.label or "",
            x          = data.x,
            y          = data.y,
            z          = data.z,
            heading    = data.heading,
            created_by = data.created_by or "",
            created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }
        _nextJsonId = _nextJsonId + 1
        _jsonPeds[#_jsonPeds + 1] = newPed
        SaveJsonPeds()
        _pedsCache = _jsonPeds
        if callback then callback(newPed) end
    end
end

--- Update ped (model, label, position)
---@param id number
---@param data table
---@param callback function(success)
function Peds.Update(id, data, callback)
    id = tonumber(id)
    if _storage == "oxmysql" then
        MySQL.update(
            'UPDATE jobclothing_peds SET model=?, label=?, x=?, y=?, z=?, heading=? WHERE id=?',
            { data.model, data.label or "", data.x, data.y, data.z, data.heading, id },
            function(rows)
                if rows > 0 then
                    -- Update cache
                    for i, p in ipairs(_pedsCache) do
                        if p.id == id then
                            _pedsCache[i].model   = data.model
                            _pedsCache[i].label   = data.label or _pedsCache[i].label
                            _pedsCache[i].x       = data.x
                            _pedsCache[i].y       = data.y
                            _pedsCache[i].z       = data.z
                            _pedsCache[i].heading = data.heading
                            break
                        end
                    end
                end
                if callback then callback(rows > 0) end
            end
        )
    else
        LoadJsonPeds()
        local found = false
        for i, p in ipairs(_jsonPeds) do
            if p.id == id then
                _jsonPeds[i].model   = data.model   or p.model
                _jsonPeds[i].label   = data.label   or p.label
                _jsonPeds[i].x       = data.x       or p.x
                _jsonPeds[i].y       = data.y       or p.y
                _jsonPeds[i].z       = data.z       or p.z
                _jsonPeds[i].heading = data.heading or p.heading
                found = true
                break
            end
        end
        if found then SaveJsonPeds() end
        _pedsCache = _jsonPeds
        if callback then callback(found) end
    end
end

--- Delete ped and all associated uniforms
---@param id number
---@param callback function(success)
function Peds.Delete(id, callback)
    id = tonumber(id)
    if _storage == "oxmysql" then
        -- CASCADE in SQL handles uniforms
        MySQL.update('DELETE FROM jobclothing_peds WHERE id=?', { id }, function(rows)
            -- Remove from cache
            for i, p in ipairs(_pedsCache) do
                if p.id == id then
                    table.remove(_pedsCache, i)
                    break
                end
            end
            if callback then callback(rows > 0) end
        end)
    else
        LoadJsonPeds()
        local found = false
        for i, p in ipairs(_jsonPeds) do
            if p.id == id then
                table.remove(_jsonPeds, i)
                found = true
                break
            end
        end
        if found then SaveJsonPeds() end

        -- Also delete uniforms from JSON
        Uniforms.DeleteByPedId(id)

        _pedsCache = _jsonPeds
        if callback then callback(found) end
    end
end

-- Initialise storage detection (called by main.lua after SQL is ready)
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DetectStorage()
        -- NOTE: Peds.LoadAll() is called by server/main.lua
        -- AFTER AutoInstallSQL() completes, to avoid querying
        -- tables before they exist.
    end
end)

