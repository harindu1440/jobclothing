-- ============================================================
--  JobClothing - QBox (qbx_core) Framework Adapter
-- ============================================================

QBoxAdapter = {}

--- Init: QBox uses exports directly, no core object needed
---@return boolean
function QBoxAdapter.Init()
    local state = GetResourceState('qbx_core')
    return state == 'started' or state == 'starting'
end

--- Get player object via qbx_core export
---@param source number
---@return table|nil
function QBoxAdapter.GetPlayer(source)
    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayer(source)
    end)
    if ok then return player else return nil end
end

--- Get player job
---@param source number
---@return table|nil
function QBoxAdapter.GetPlayerJob(source)
    local player = QBoxAdapter.GetPlayer(source)
    if not player then return nil end

    -- qbx_core uses PlayerData.job similar to QBCore
    local job = player.PlayerData.job
    if not job then return nil end

    return {
        name       = job.name,
        label      = job.label or job.name,
        grade      = job.grade and (job.grade.level or job.grade) or 0,
        gradeLabel = job.grade and (job.grade.name or tostring(job.grade)) or "0",
    }
end

--- Check admin group via qbx_core
---@param source number
---@return boolean
function QBoxAdapter.HasPermission(source)
    local player = QBoxAdapter.GetPlayer(source)
    if not player then return false end

    local group = player.PlayerData.group
    if Config.AdminGroups and Config.AdminGroups[group] then
        return true
    end
    return false
end

--- Get all jobs from qbx_core
---@return table
function QBoxAdapter.GetJobs()
    local ok, jobsData = pcall(function()
        return exports.qbx_core:GetJobs()
    end)
    if not ok or not jobsData then return {} end

    local jobs = {}
    for name, data in pairs(jobsData) do
        local grades = {}
        local gradesData = data.grades or {}
        for gradeLevel, gradeData in pairs(gradesData) do
            grades[#grades + 1] = {
                grade = tonumber(gradeLevel),
                name  = gradeData.name or tostring(gradeLevel),
                label = gradeData.name or tostring(gradeLevel),
            }
        end
        table.sort(grades, function(a, b) return a.grade < b.grade end)
        jobs[#jobs + 1] = {
            name   = name,
            label  = data.label or name,
            grades = grades,
        }
    end
    table.sort(jobs, function(a, b) return a.label < b.label end)
    return jobs
end

--- Get grades for a specific job from qbx_core
---@param jobName string
---@return table
function QBoxAdapter.GetJobGrades(jobName)
    local ok, jobsData = pcall(function()
        return exports.qbx_core:GetJobs()
    end)
    if not ok or not jobsData then return {} end

    local jobData = jobsData[jobName]
    if not jobData then return {} end

    local grades = {}
    for gradeLevel, gradeData in pairs(jobData.grades or {}) do
        grades[#grades + 1] = {
            grade = tonumber(gradeLevel),
            name  = gradeData.name or tostring(gradeLevel),
            label = gradeData.name or tostring(gradeLevel),
        }
    end
    table.sort(grades, function(a, b) return a.grade < b.grade end)
    return grades
end
