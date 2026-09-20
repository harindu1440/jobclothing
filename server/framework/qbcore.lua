-- ============================================================
--  JobClothing - QBCore Framework Adapter
-- ============================================================

QBCoreAdapter = {}

local QBCore = nil

function QBCoreAdapter.Init()
    QBCore = exports['qb-core']:GetCoreObject()
    return QBCore ~= nil
end

--- Get a player object by server source
---@param source number
---@return table|nil
function QBCoreAdapter.GetPlayer(source)
    if not QBCore then return nil end
    return QBCore.Functions.GetPlayer(source)
end

--- Get the player's current job info {name, grade, gradeLabel, label}
---@param source number
---@return table|nil
function QBCoreAdapter.GetPlayerJob(source)
    local player = QBCoreAdapter.GetPlayer(source)
    if not player then return nil end

    local job = player.PlayerData.job
    return {
        name       = job.name,
        label      = job.label,
        grade      = job.grade.level,
        gradeLabel = job.grade.name,
    }
end

--- Check if source has an admin group
---@param source number
---@return boolean
function QBCoreAdapter.HasPermission(source)
    local player = QBCoreAdapter.GetPlayer(source)
    if not player then return false end

    local group = player.PlayerData.group
    if Config.AdminGroups and Config.AdminGroups[group] then
        return true
    end
    return false
end

--- Return all jobs {name, label, grades=[{grade, name, label}]}
---@return table
function QBCoreAdapter.GetJobs()
    if not QBCore then return {} end
    local jobs = {}
    for name, data in pairs(QBCore.Shared.Jobs) do
        local grades = {}
        for gradeLevel, gradeData in pairs(data.grades) do
            grades[#grades + 1] = {
                grade = tonumber(gradeLevel),
                name  = gradeData.name,
                label = gradeData.name,
            }
        end
        table.sort(grades, function(a, b) return a.grade < b.grade end)
        jobs[#jobs + 1] = {
            name   = name,
            label  = data.label,
            grades = grades,
        }
    end
    table.sort(jobs, function(a, b) return a.label < b.label end)
    return jobs
end

--- Return grades for a specific job
---@param jobName string
---@return table
function QBCoreAdapter.GetJobGrades(jobName)
    if not QBCore then return {} end
    local jobData = QBCore.Shared.Jobs[jobName]
    if not jobData then return {} end

    local grades = {}
    for gradeLevel, gradeData in pairs(jobData.grades) do
        grades[#grades + 1] = {
            grade = tonumber(gradeLevel),
            name  = gradeData.name,
            label = gradeData.name,
        }
    end
    table.sort(grades, function(a, b) return a.grade < b.grade end)
    return grades
end
