-- ============================================================
--  JobClothing - Server Main
--  Registers command, all NUI callbacks, and network events.
-- ============================================================

-- ──────────────────────────────────────────────────────────
--  Helper: respond to a server callback
-- ──────────────────────────────────────────────────────────
local function CB(source, event, data)
    TriggerClientEvent('jobclothing:cb:' .. event, source, data)
end

-- ──────────────────────────────────────────────────────────
--  Auto SQL Install
--  Tables are created sequentially (peds first, then uniforms)
--  because jobclothing_uniforms has a FK → jobclothing_peds.
--  onComplete() is called only after BOTH tables are confirmed.
-- ──────────────────────────────────────────────────────────
local function AutoInstallSQL(onComplete)
    if GetResourceState('oxmysql') ~= 'started' then
        DebugPrint("oxmysql not running — skipping auto SQL install (using JSON storage).")
        if onComplete then onComplete() end
        return
    end

    -- STEP 1: Create jobclothing_peds
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `jobclothing_peds` (
            `id`          INT(11)      NOT NULL AUTO_INCREMENT,
            `model`       VARCHAR(64)  NOT NULL,
            `label`       VARCHAR(128) NOT NULL DEFAULT '',
            `x`           FLOAT        NOT NULL DEFAULT 0,
            `y`           FLOAT        NOT NULL DEFAULT 0,
            `z`           FLOAT        NOT NULL DEFAULT 0,
            `heading`     FLOAT        NOT NULL DEFAULT 0,
            `created_by`  VARCHAR(64)  NOT NULL DEFAULT '',
            `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
        print("^2[JobClothing] Table `jobclothing_peds` OK.^7")

        -- STEP 2: Create jobclothing_uniforms ONLY after peds table exists
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `jobclothing_uniforms` (
                `id`           INT(11)      NOT NULL AUTO_INCREMENT,
                `ped_id`       INT(11)      NOT NULL,
                `job_name`     VARCHAR(64)  NOT NULL,
                `job_grade`    INT(11)      NOT NULL DEFAULT 0,
                `uniform_name` VARCHAR(128) NOT NULL DEFAULT 'Default',
                `outfit_data`  LONGTEXT     NOT NULL,
                `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `updated_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                KEY `idx_ped_id`    (`ped_id`),
                KEY `idx_job_grade` (`job_name`, `job_grade`),
                CONSTRAINT `fk_uniform_ped`
                    FOREIGN KEY (`ped_id`) REFERENCES `jobclothing_peds` (`id`)
                    ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]], {}, function()
            print("^2[JobClothing] Table `jobclothing_uniforms` OK.^7")
            -- Both tables ready — signal caller
            if onComplete then onComplete() end
        end)
    end)
end


-- ──────────────────────────────────────────────────────────
--  Command Registration
-- ──────────────────────────────────────────────────────────
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    -- Register command immediately (doesn't need DB)
    RegisterCommand(Config.Command, function(source, args, rawCommand)
        if source == 0 then return end  -- console

        if not Permissions.IsAdmin(source) then
            Permissions.Deny(source)
            return
        end

        -- Tell client to open the admin NUI
        TriggerClientEvent('jobclothing:openAdmin', source)
    end, false)

    -- Auto-create tables, THEN load peds from DB
    AutoInstallSQL(function()
        -- Tables confirmed ready — now safe to query
        Peds.LoadAll(function(peds)
            DebugPrint("Loaded %d peds from storage", #peds)
            TriggerClientEvent('jobclothing:spawnAllPeds', -1, peds)
        end)
    end)

    print(string.format("^2[JobClothing] Command registered: /%s^7", Config.Command))
end)

RegisterNetEvent('jobclothing:server:requestAllPeds', function()
    local src = source
    TriggerClientEvent('jobclothing:spawnAllPeds', src, Peds.GetAll())
end)

-- ──────────────────────────────────────────────────────────
--  Player joins: send all ped data so client can spawn them
-- ──────────────────────────────────────────────────────────
AddEventHandler('playerJoining', function()
    local src = source
    local peds = Peds.GetAll()
    TriggerClientEvent('jobclothing:spawnAllPeds', src, peds)
end)


-- ──────────────────────────────────────────────────────────
--  Admin NUI Callbacks
-- ──────────────────────────────────────────────────────────

-- Fetch all peds
RegisterNetEvent('jobclothing:server:getPeds', function()
    local src = source
    if not Permissions.IsAdmin(src) then return end
    CB(src, 'getPeds', Peds.GetAll())
end)

-- Fetch all jobs
RegisterNetEvent('jobclothing:server:getJobs', function()
    local src = source
    if not Permissions.IsAdmin(src) then return end
    CB(src, 'getJobs', Framework.GetJobs())
end)

-- Fetch grades for a job
RegisterNetEvent('jobclothing:server:getGrades', function(jobName)
    local src = source
    if not Permissions.IsAdmin(src) then return end
    if type(jobName) ~= "string" then return end
    CB(src, 'getGrades', Framework.GetJobGrades(jobName))
end)

-- Fetch uniforms for a ped
RegisterNetEvent('jobclothing:server:getUniformsForPed', function(pedId)
    local src = source
    if not Permissions.IsAdmin(src) then return end
    pedId = tonumber(pedId)
    if not pedId then return end
    Uniforms.GetForPed(pedId, function(uniforms)
        CB(src, 'getUniformsForPed', uniforms)
    end)
end)

-- Create ped
RegisterNetEvent('jobclothing:server:createPed', function(data)
    local src = source
    if not Permissions.IsAdmin(src) then return end

    -- Validate
    if type(data) ~= "table" then return end
    if type(data.model) ~= "string" or #data.model == 0 then return end
    data.x       = tonumber(data.x)       or 0.0
    data.y       = tonumber(data.y)       or 0.0
    data.z       = tonumber(data.z)       or 0.0
    data.heading = tonumber(data.heading) or 0.0
    data.label   = type(data.label) == "string" and data.label or data.model
    data.created_by = GetPlayerName(src) or "Unknown"

    Peds.Create(data, function(newPed)
        -- Tell the creating admin
        CB(src, 'pedCreated', newPed)
        -- Tell all clients to spawn this ped
        TriggerClientEvent('jobclothing:spawnPed', -1, newPed)
    end)
end)

-- Update ped position/model
RegisterNetEvent('jobclothing:server:updatePed', function(id, data)
    local src = source
    if not Permissions.IsAdmin(src) then return end

    id = tonumber(id)
    if not id then return end
    if not Peds.GetById(id) then
        CB(src, 'error', "Ped not found.")
        return
    end

    Peds.Update(id, data, function(success)
        CB(src, 'pedUpdated', { success = success, id = id })
        if success then
            TriggerClientEvent('jobclothing:updatePed', -1, id, data)
        end
    end)
end)

-- Delete ped
RegisterNetEvent('jobclothing:server:deletePed', function(id)
    local src = source
    if not Permissions.IsAdmin(src) then return end

    id = tonumber(id)
    if not id then return end

    Peds.Delete(id, function(success)
        CB(src, 'pedDeleted', { success = success, id = id })
        if success then
            TriggerClientEvent('jobclothing:deletePed', -1, id)
        end
    end)
end)

-- Create uniform
RegisterNetEvent('jobclothing:server:createUniform', function(data)
    local src = source
    if not Permissions.IsAdmin(src) then return end

    -- Validate
    if type(data) ~= "table" then return end
    data.ped_id    = tonumber(data.ped_id)
    data.job_grade = tonumber(data.job_grade) or 0
    if not data.ped_id then return end
    if not Peds.GetById(data.ped_id) then CB(src, 'error', "Ped not found."); return end
    if not Framework.JobExists(data.job_name) then CB(src, 'error', "Job does not exist."); return end
    if not Framework.GradeExists(data.job_name, data.job_grade) then CB(src, 'error', "Grade does not exist."); return end
    if type(data.outfit_data) ~= "table" then return end

    Uniforms.Create(data, function(newUni)
        CB(src, 'uniformCreated', newUni)
    end)
end)

-- Update uniform
RegisterNetEvent('jobclothing:server:updateUniform', function(id, data)
    local src = source
    if not Permissions.IsAdmin(src) then return end

    id = tonumber(id)
    if not id then return end
    if type(data) ~= "table" then return end
    if type(data.outfit_data) ~= "table" then return end

    Uniforms.Update(id, data, function(success)
        CB(src, 'uniformUpdated', { success = success, id = id })
    end)
end)

-- Delete uniform
RegisterNetEvent('jobclothing:server:deleteUniform', function(id)
    local src = source
    if not Permissions.IsAdmin(src) then return end

    id = tonumber(id)
    if not id then return end

    Uniforms.Delete(id, function(success)
        CB(src, 'uniformDeleted', { success = success, id = id })
    end)
end)

-- ──────────────────────────────────────────────────────────
--  Player Interaction: Apply Uniform
-- ──────────────────────────────────────────────────────────

RegisterNetEvent('jobclothing:server:requestUniforms', function(pedId)
    local src = source
    pedId = tonumber(pedId)
    if not pedId then return end

    -- Server-side validate ped exists
    if not Peds.GetById(pedId) then return end

    -- Get player's job server-side (never trust client)
    local jobData = Framework.GetPlayerJob(src)
    if not jobData then
        TriggerClientEvent('jobclothing:receiveUniforms', src, {}, nil)
        return
    end

    Uniforms.GetForPlayer(pedId, jobData.name, jobData.grade, function(uniforms)
        TriggerClientEvent('jobclothing:receiveUniforms', src, uniforms, jobData)
    end)
end)

RegisterNetEvent('jobclothing:server:applyUniform', function(uniformId)
    local src = source
    uniformId = tonumber(uniformId)
    if not uniformId then return end

    -- Get player's actual job server-side
    local jobData = Framework.GetPlayerJob(src)
    if not jobData then return end

    Uniforms.GetById(uniformId, function(uniform)
        if not uniform then return end

        -- Validate grade access
        local uGrade = tonumber(uniform.job_grade) or 0
        local pGrade = tonumber(jobData.grade) or 0
        local allowed = false

        if Config.GradeInheritance then
            allowed = (uniform.job_name == jobData.name) and (uGrade <= pGrade)
        else
            allowed = (uniform.job_name == jobData.name) and (uGrade == pGrade)
        end

        if not allowed then
            TriggerClientEvent('jobclothing:notifyError', src, "You are not authorized to wear this uniform.")
            return
        end

        -- Send the outfit data to the client to apply
        TriggerClientEvent('jobclothing:applyOutfit', src, uniform.outfit_data)
    end)
end)

-- ──────────────────────────────────────────────────────────
--  Admin Teleport to Ped
-- ──────────────────────────────────────────────────────────
RegisterNetEvent('jobclothing:server:teleportToPed', function(pedId)
    local src = source
    if not Permissions.IsAdmin(src) then return end
    local ped = Peds.GetById(tonumber(pedId))
    if not ped then return end
    TriggerClientEvent('jobclothing:teleportTo', src, ped.x, ped.y, ped.z)
end)
