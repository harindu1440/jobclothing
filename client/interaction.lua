-- ============================================================
--  JobClothing - Target / Interaction System (Client)
-- ============================================================

local _targetName  = "none"
local _oxTargets   = {}   -- track added ox_target zones by ped id
local _qbTargets   = {}   -- track added qb-target zones by ped id

-- ──────────────────────────────────────────────────────────
--  Detection
-- ──────────────────────────────────────────────────────────

local function DetectTarget()
    local cfg = Config.Target or "auto"
    if cfg == "ox_target" then
        _targetName = "ox_target"
    elseif cfg == "qb-target" then
        _targetName = "qb-target"
    elseif cfg == "none" then
        _targetName = "none"
    else
        if GetResourceState('ox_target') == 'started' then
            _targetName = "ox_target"
        elseif GetResourceState('qb-target') == 'started' then
            _targetName = "qb-target"
        else
            _targetName = "proximity"
        end
    end
    print(string.format("^2[JobClothing] Target: %s^7", _targetName))
end

-- ──────────────────────────────────────────────────────────
--  Register / Unregister per ped
-- ──────────────────────────────────────────────────────────

function RegisterPedInteraction(dbId, entity)
    if not DoesEntityExist(entity) then return end

    if _targetName == "ox_target" then
        local zoneName = "jobclothing_ped_" .. dbId
        exports.ox_target:addLocalEntity(entity, {
            {
                name    = zoneName,
                icon    = "fas fa-tshirt",
                label   = "Job Clothing",
                onSelect = function()
                    TriggerEvent('jobclothing:client:openUniformSelector', dbId)
                end,
            }
        })
        _oxTargets[dbId] = { entity = entity, zone = zoneName }

    elseif _targetName == "qb-target" then
        local zoneName = "jobclothing_ped_" .. dbId
        exports['qb-target']:AddTargetEntity(entity, {
            options = {
                {
                    type    = "client",
                    event   = "jobclothing:client:openUniformSelector",
                    icon    = "fas fa-tshirt",
                    label   = "Job Clothing",
                    dbId    = dbId,
                }
            },
            distance = Config.InteractionDistance,
        }, zoneName)
        _qbTargets[dbId] = zoneName

    else
        -- Proximity fallback: handled in main polling (see interaction loop below)
        _oxTargets[dbId] = nil
        _qbTargets[dbId] = nil
    end
end

function UnregisterPedInteraction(dbId, entity)
    if _targetName == "ox_target" then
        if _oxTargets[dbId] then
            exports.ox_target:removeLocalEntity(entity)
            _oxTargets[dbId] = nil
        end

    elseif _targetName == "qb-target" then
        if _qbTargets[dbId] then
            exports['qb-target']:RemoveTargetEntity(entity, _qbTargets[dbId])
            _qbTargets[dbId] = nil
        end
    end
end

-- ──────────────────────────────────────────────────────────
--  Proximity fallback loop
--  Only runs if no target system is detected.
--  Uses a modest Wait(500) to be performance-friendly.
-- ──────────────────────────────────────────────────────────

local _proximityActive    = false
local _lastNearPed        = nil

local function StartProximityLoop()
    if _proximityActive then return end
    _proximityActive = true

    CreateThread(function()
        while _proximityActive do
            local playerPed  = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local closestPed  = nil
            local closestDist = Config.InteractionDistance

            for dbId, ent in pairs(GetAllSpawnedPeds()) do
                if DoesEntityExist(ent) then
                    local pedCoords = GetEntityCoords(ent)
                    local dist = #(playerCoords - pedCoords)
                    if dist <= closestDist then
                        closestDist = dist
                        closestPed  = dbId
                    end
                end
            end

            if closestPed then
                -- Draw hint
                DrawText3D(
                    GetEntityCoords(GetSpawnedPed(closestPed)),
                    "~g~[E]~w~ Job Clothing"
                )
                if IsControlJustPressed(0, Config.InteractionKey) then
                    TriggerEvent('jobclothing:client:openUniformSelector', closestPed)
                end
                _lastNearPed = closestPed
            else
                _lastNearPed = nil
            end

            Wait(0)   -- need per-frame for accurate draw + key detection
        end
    end)
end

-- Helper: draw 3D text above a position
function DrawText3D(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z + 1.2)
    if not onScreen then return end
    SetTextFont(0)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(_x, _y)
end

-- Init on resource start
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DetectTarget()
        if _targetName == "proximity" then
            StartProximityLoop()
        end
    end
end)
