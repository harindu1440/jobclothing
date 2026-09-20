-- ============================================================
--  JobClothing - Server Uniform Management + Storage
-- ============================================================

Uniforms = {}
local _uniformsCache = {}  -- keyed by ped_id

-- ──────────────────────────────────────────────────────────
--  Internal JSON helpers  (referenced by peds.lua too)
-- ──────────────────────────────────────────────────────────

local function GetJsonPath(filename)
    return GetResourcePath(GetCurrentResourceName()) .. "/" .. Config.JsonDataPath .. "/" .. filename
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
    if not f then return false end
    f:write(SafeJsonEncode(data))
    f:close()
    return true
end

local _jsonUniforms = nil
local _nextUniId    = 1

local function LoadJsonUniforms()
    _jsonUniforms = ReadJson(GetJsonPath("uniforms.json"))
    _nextUniId = 1
    for _, u in ipairs(_jsonUniforms) do
        if u.id >= _nextUniId then _nextUniId = u.id + 1 end
    end
end

local function SaveJsonUniforms()
    WriteJson(GetJsonPath("uniforms.json"), _jsonUniforms)
end

local function RebuildCache()
    _uniformsCache = {}
    local list = _jsonUniforms or {}
    if _jsonUniforms == nil then
        -- oxmysql path: cache already populated per call
        return
    end
    for _, u in ipairs(list) do
        local pid = tostring(u.ped_id)
        _uniformsCache[pid] = _uniformsCache[pid] or {}
        local decoded = SafeJsonDecode(u.outfit_data) or u.outfit_data
        _uniformsCache[pid][#_uniformsCache[pid] + 1] = {
            id           = u.id,
            ped_id       = u.ped_id,
            job_name     = u.job_name,
            job_grade    = u.job_grade,
            uniform_name = u.uniform_name,
            outfit_data  = decoded,
        }
    end
end

-- ──────────────────────────────────────────────────────────
--  Public API
-- ──────────────────────────────────────────────────────────

--- Load all uniforms for a specific ped
---@param pedId number
---@param callback function(uniforms)
function Uniforms.GetForPed(pedId, callback)
    pedId = tonumber(pedId)
    if not pedId then return callback({}) end

    if GetResourceState('oxmysql') == 'started' and (Config.Storage == "auto" or Config.Storage == "oxmysql") then
        MySQL.query(
            'SELECT * FROM jobclothing_uniforms WHERE ped_id = ?',
            { pedId },
            function(rows)
                local result = {}
                for _, r in ipairs(rows or {}) do
                    r.outfit_data = SafeJsonDecode(r.outfit_data) or {}
                    result[#result + 1] = r
                end
                callback(result)
            end
        )
    else
        LoadJsonUniforms()
        local result = {}
        for _, u in ipairs(_jsonUniforms) do
            if u.ped_id == pedId then
                local copy = DeepCopy(u)
                copy.outfit_data = SafeJsonDecode(u.outfit_data) or u.outfit_data or {}
                result[#result + 1] = copy
            end
        end
        callback(result)
    end
end

--- Get uniforms for a player (job + grade filter, with inheritance)
---@param pedId number
---@param jobName string
---@param grade number
---@param callback function(uniforms)
function Uniforms.GetForPlayer(pedId, jobName, grade, callback)
    Uniforms.GetForPed(pedId, function(all)
        local result = {}
        local gradeNum = tonumber(grade) or 0
        for _, u in ipairs(all) do
            if u.job_name == jobName then
                local uGrade = tonumber(u.job_grade) or 0
                if Config.GradeInheritance then
                    if uGrade <= gradeNum then
                        result[#result + 1] = u
                    end
                else
                    if uGrade == gradeNum then
                        result[#result + 1] = u
                    end
                end
            end
        end
        callback(result)
    end)
end

--- Create a new uniform
---@param data table {ped_id, job_name, job_grade, uniform_name, outfit_data}
---@param callback function(newUniform)
function Uniforms.Create(data, callback)
    local outfitJson = SafeJsonEncode(data.outfit_data)

    if GetResourceState('oxmysql') == 'started' and (Config.Storage == "auto" or Config.Storage == "oxmysql") then
        MySQL.insert(
            'INSERT INTO jobclothing_uniforms (ped_id, job_name, job_grade, uniform_name, outfit_data) VALUES (?, ?, ?, ?, ?)',
            { data.ped_id, data.job_name, data.job_grade, data.uniform_name, outfitJson },
            function(id)
                local newUni = {
                    id           = id,
                    ped_id       = data.ped_id,
                    job_name     = data.job_name,
                    job_grade    = data.job_grade,
                    uniform_name = data.uniform_name,
                    outfit_data  = data.outfit_data,
                }
                if callback then callback(newUni) end
            end
        )
    else
        LoadJsonUniforms()
        local newUni = {
            id           = _nextUniId,
            ped_id       = data.ped_id,
            job_name     = data.job_name,
            job_grade    = data.job_grade,
            uniform_name = data.uniform_name,
            outfit_data  = outfitJson,
        }
        _nextUniId = _nextUniId + 1
        _jsonUniforms[#_jsonUniforms + 1] = newUni
        SaveJsonUniforms()
        local retUni = DeepCopy(newUni)
        retUni.outfit_data = data.outfit_data
        if callback then callback(retUni) end
    end
end

--- Update an existing uniform's outfit data / name
---@param id number
---@param data table
---@param callback function(success)
function Uniforms.Update(id, data, callback)
    id = tonumber(id)
    local outfitJson = SafeJsonEncode(data.outfit_data)

    if GetResourceState('oxmysql') == 'started' and (Config.Storage == "auto" or Config.Storage == "oxmysql") then
        MySQL.update(
            'UPDATE jobclothing_uniforms SET uniform_name=?, outfit_data=? WHERE id=?',
            { data.uniform_name, outfitJson, id },
            function(rows)
                if callback then callback(rows > 0) end
            end
        )
    else
        LoadJsonUniforms()
        local found = false
        for i, u in ipairs(_jsonUniforms) do
            if u.id == id then
                _jsonUniforms[i].uniform_name = data.uniform_name or u.uniform_name
                _jsonUniforms[i].outfit_data  = outfitJson
                found = true
                break
            end
        end
        if found then SaveJsonUniforms() end
        if callback then callback(found) end
    end
end

--- Delete a uniform by id
---@param id number
---@param callback function(success)
function Uniforms.Delete(id, callback)
    id = tonumber(id)
    if GetResourceState('oxmysql') == 'started' and (Config.Storage == "auto" or Config.Storage == "oxmysql") then
        MySQL.update('DELETE FROM jobclothing_uniforms WHERE id=?', { id }, function(rows)
            if callback then callback(rows > 0) end
        end)
    else
        LoadJsonUniforms()
        local found = false
        for i, u in ipairs(_jsonUniforms) do
            if u.id == id then
                table.remove(_jsonUniforms, i)
                found = true
                break
            end
        end
        if found then SaveJsonUniforms() end
        if callback then callback(found) end
    end
end

--- Delete all uniforms for a ped (used when deleting a ped in JSON mode)
---@param pedId number
function Uniforms.DeleteByPedId(pedId)
    pedId = tonumber(pedId)
    if GetResourceState('oxmysql') == 'started' and (Config.Storage == "auto" or Config.Storage == "oxmysql") then
        MySQL.update('DELETE FROM jobclothing_uniforms WHERE ped_id=?', { pedId }, function() end)
    else
        LoadJsonUniforms()
        local newList = {}
        for _, u in ipairs(_jsonUniforms) do
            if u.ped_id ~= pedId then
                newList[#newList + 1] = u
            end
        end
        _jsonUniforms = newList
        SaveJsonUniforms()
    end
end

--- Get a single uniform by id
---@param id number
---@param callback function(uniform|nil)
function Uniforms.GetById(id, callback)
    id = tonumber(id)
    if GetResourceState('oxmysql') == 'started' and (Config.Storage == "auto" or Config.Storage == "oxmysql") then
        MySQL.single(
            'SELECT * FROM jobclothing_uniforms WHERE id=?',
            { id },
            function(row)
                if row then row.outfit_data = SafeJsonDecode(row.outfit_data) or {} end
                if callback then callback(row) end
            end
        )
    else
        LoadJsonUniforms()
        for _, u in ipairs(_jsonUniforms) do
            if u.id == id then
                local copy = DeepCopy(u)
                copy.outfit_data = SafeJsonDecode(u.outfit_data) or {}
                if callback then callback(copy) end
                return
            end
        end
        if callback then callback(nil) end
    end
end
