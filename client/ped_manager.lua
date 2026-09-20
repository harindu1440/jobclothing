-- ============================================================
--  JobClothing - Client Ped Manager
--  Spawns/despawns/tracks clothing peds client-side
-- ============================================================

local SpawnedPeds = {}   -- { [dbId] = entityHandle }

-- ──────────────────────────────────────────────────────────
--  Internal helpers
-- ──────────────────────────────────────────────────────────

local function LoadModel(model)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 3000 do
        Wait(10)
        timeout = timeout + 10
    end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function SetupPed(ped)
    if Config.Ped.invincible   then SetEntityInvincible(ped, true) end
    if Config.Ped.frozen       then FreezeEntityPosition(ped, true) end
    if Config.Ped.blockEvents  then
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 17, true)
        SetPedCanRagdoll(ped, false)
    end
    if Config.Ped.scenario then
        TaskStartScenarioInPlace(ped, Config.Ped.scenario, 0, true)
    else
        TaskStandStill(ped, -1)
    end
    SetEntityAsMissionEntity(ped, true, true)
end

-- ──────────────────────────────────────────────────────────
--  Public API
-- ──────────────────────────────────────────────────────────

--- Spawn a ped from data table {id, model, x, y, z, heading}
---@param pedData table
function SpawnPed(pedData)
    if not pedData or not pedData.id then return end
    if SpawnedPeds[pedData.id] then
        -- Already spawned; update position if changed
        RemovePed(pedData.id)
    end

    CreateThread(function()
        local modelHash = LoadModel(pedData.model)
        if not modelHash then
            print("^1[JobClothing] Failed to load model: " .. tostring(pedData.model) .. "^7")
            return
        end

        local ped = CreatePed(4, modelHash, pedData.x, pedData.y, pedData.z - 1.0, pedData.heading, false, true)
        SetModelAsNoLongerNeeded(modelHash)

        if not DoesEntityExist(ped) then return end

        SetupPed(ped)
        SpawnedPeds[pedData.id] = ped

        -- Register interaction for this ped
        RegisterPedInteraction(pedData.id, ped)

        DebugPrint("Spawned ped #%d (entity: %d)", pedData.id, ped)
    end)
end

--- Remove/delete a ped by DB id
---@param dbId number
function RemovePed(dbId)
    local ent = SpawnedPeds[dbId]
    if ent and DoesEntityExist(ent) then
        UnregisterPedInteraction(dbId, ent)
        DeleteEntity(ent)
    end
    SpawnedPeds[dbId] = nil
end

--- Get entity handle for a DB ped id
---@param dbId number
---@return number|nil
function GetSpawnedPed(dbId)
    return SpawnedPeds[dbId]
end

--- Get all spawned peds {dbId = entity}
function GetAllSpawnedPeds()
    return SpawnedPeds
end

--- Spawn all peds from a list
---@param pedList table
function SpawnAllPeds(pedList)
    for _, pedData in ipairs(pedList) do
        SpawnPed(pedData)
    end
end

--- Re-spawn all already-known peds (e.g., after resource restart)
function ReloadAllPeds(pedList)
    -- Remove existing
    for dbId, _ in pairs(SpawnedPeds) do
        RemovePed(dbId)
    end
    SpawnedPeds = {}
    SpawnAllPeds(pedList)
end

-- ──────────────────────────────────────────────────────────
--  Network Events
-- ──────────────────────────────────────────────────────────

RegisterNetEvent('jobclothing:spawnAllPeds', function(peds)
    ReloadAllPeds(peds or {})
end)

RegisterNetEvent('jobclothing:spawnPed', function(pedData)
    SpawnPed(pedData)
end)

RegisterNetEvent('jobclothing:deletePed', function(id)
    RemovePed(tonumber(id))
end)

RegisterNetEvent('jobclothing:updatePed', function(id, data)
    -- Re-spawn ped at new position/model
    local merged = data
    merged.id = tonumber(id)
    SpawnPed(merged)
end)

RegisterNetEvent('jobclothing:teleportTo', function(x, y, z)
    local ped = PlayerPedId()
    SetEntityCoords(ped, x, y, z + 0.5, false, false, false, false)
end)

-- ──────────────────────────────────────────────────────────
--  On resource start/restart: request all peds from server
--  This fixes the timing race where server broadcasts peds
--  before client event handlers are registered.
-- ──────────────────────────────────────────────────────────
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    -- Small delay ensures server has finished loading from DB
    CreateThread(function()
        Wait(500)
        TriggerServerEvent('jobclothing:server:requestAllPeds')
    end)
end)

