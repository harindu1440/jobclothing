-- ============================================================
--  JobClothing - Framework Auto-Detector (Server)
-- ============================================================

Framework = {}
local _activeAdapter = nil
local _frameworkName = "unknown"

local function DetectFramework()
    local cfg = Config.Framework or "auto"

    if cfg == "qbox" then
        if QBoxAdapter.Init() then
            _activeAdapter = QBoxAdapter
            _frameworkName = "QBox"
            return
        end
        print("^1[JobClothing] WARNING: Forced qbox but qbx_core is not running!^7")
    elseif cfg == "qbcore" then
        local ok = pcall(QBCoreAdapter.Init)
        if ok then
            _activeAdapter = QBCoreAdapter
            _frameworkName = "QBCore"
            return
        end
        print("^1[JobClothing] WARNING: Forced qbcore but qb-core is not running!^7")
    else
        -- Auto: prefer qbx_core
        if GetResourceState('qbx_core') == 'started' then
            if QBoxAdapter.Init() then
                _activeAdapter = QBoxAdapter
                _frameworkName = "QBox"
                return
            end
        end

        if GetResourceState('qb-core') == 'started' then
            local ok = pcall(QBCoreAdapter.Init)
            if ok then
                _activeAdapter = QBCoreAdapter
                _frameworkName = "QBCore"
                return
            end
        end

        print("^1[JobClothing] ERROR: No supported framework detected (qbx_core / qb-core)!^7")
    end
end

-- ──────────────────────────────────────────────────────────
--  Public Framework interface
-- ──────────────────────────────────────────────────────────

function Framework.GetName()
    return _frameworkName
end

function Framework.GetPlayer(source)
    if not _activeAdapter then return nil end
    return _activeAdapter.GetPlayer(source)
end

function Framework.GetPlayerJob(source)
    if not _activeAdapter then return nil end
    return _activeAdapter.GetPlayerJob(source)
end

function Framework.HasPermission(source)
    if not _activeAdapter then return false end
    return _activeAdapter.HasPermission(source)
end

function Framework.GetJobs()
    if not _activeAdapter then return {} end
    return _activeAdapter.GetJobs()
end

function Framework.GetJobGrades(jobName)
    if not _activeAdapter then return {} end
    return _activeAdapter.GetJobGrades(jobName)
end

function Framework.JobExists(jobName)
    local jobs = Framework.GetJobs()
    for _, j in ipairs(jobs) do
        if j.name == jobName then return true end
    end
    return false
end

function Framework.GradeExists(jobName, grade)
    local grades = Framework.GetJobGrades(jobName)
    for _, g in ipairs(grades) do
        if g.grade == tonumber(grade) then return true end
    end
    return false
end

-- Run detection at startup
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DetectFramework()
        print(string.format("^2[JobClothing] Framework: %s^7", _frameworkName))
    end
end)
