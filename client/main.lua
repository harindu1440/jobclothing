-- ============================================================
--  JobClothing - Client Main
-- ============================================================

local NUIOpen           = false
local _savedClothing    = nil   -- admin's clothing before preview

-- ──────────────────────────────────────────────────────────
--  NUI Helpers
-- ──────────────────────────────────────────────────────────

local function OpenNUI(data)
    NUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "open", payload = data or {} })
end

local function CloseNUI()
    NUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "close" })
    -- Restore admin preview clothing if we have it
    if _savedClothing then
        ClothingAdapter.applyClothing(_savedClothing)
        _savedClothing = nil
    end
end

-- ──────────────────────────────────────────────────────────
--  Server → Client callback router
-- ──────────────────────────────────────────────────────────

local _pendingCallbacks = {}

local function WaitForCB(event, timeout)
    local result = nil
    local done   = false

    _pendingCallbacks[event] = function(data)
        result = data
        done   = true
    end

    RegisterNetEvent('jobclothing:cb:' .. event)
    AddEventHandler('jobclothing:cb:' .. event, function(data)
        if _pendingCallbacks[event] then
            _pendingCallbacks[event](data)
            _pendingCallbacks[event] = nil
        end
    end)

    local elapsed = 0
    while not done and elapsed < (timeout or 5000) do
        Wait(10)
        elapsed = elapsed + 10
    end
    return result
end

-- ──────────────────────────────────────────────────────────
--  NUI Callbacks (from web UI)
-- ──────────────────────────────────────────────────────────

-- Close the NUI
RegisterNUICallback('close', function(data, cb)
    CloseNUI()
    cb({})
end)

-- Fetch peds
RegisterNUICallback('getPeds', function(data, cb)
    TriggerServerEvent('jobclothing:server:getPeds')
    local result = WaitForCB('getPeds')
    cb(result or {})
end)

-- Fetch all jobs
RegisterNUICallback('getJobs', function(data, cb)
    TriggerServerEvent('jobclothing:server:getJobs')
    local result = WaitForCB('getJobs')
    cb(result or {})
end)

-- Fetch grades for a job
RegisterNUICallback('getGrades', function(data, cb)
    TriggerServerEvent('jobclothing:server:getGrades', data.job)
    local result = WaitForCB('getGrades')
    cb(result or {})
end)

-- Fetch uniforms for a ped
RegisterNUICallback('getUniformsForPed', function(data, cb)
    TriggerServerEvent('jobclothing:server:getUniformsForPed', data.pedId)
    local result = WaitForCB('getUniformsForPed')
    cb(result or {})
end)

-- Create ped (after placement)
RegisterNUICallback('startPedPlacement', function(data, cb)
    local model = data.model
    if not model or model == "" then
        cb({ success = false, error = "Invalid model name." })
        return
    end

    -- Close NUI temporarily during placement
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ type = "placementStarted" })

    StartPedPlacement(
        model,
        function(coords, heading)
            -- Confirmed: send to server
            TriggerServerEvent('jobclothing:server:createPed', {
                model   = model,
                label   = data.label or model,
                x       = coords.x,
                y       = coords.y,
                z       = coords.z,
                heading = heading,
            })
            local result = WaitForCB('pedCreated')

            -- Re-open NUI
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(true)
            SendNUIMessage({ type = "placementFinished", payload = result })
            cb({ success = true, ped = result })
        end,
        function()
            -- Cancelled
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(true)
            SendNUIMessage({ type = "placementCancelled" })
            cb({ success = false, cancelled = true })
        end
    )
end)

-- Delete ped
RegisterNUICallback('deletePed', function(data, cb)
    TriggerServerEvent('jobclothing:server:deletePed', data.pedId)
    local result = WaitForCB('pedDeleted')
    cb(result or { success = false })
end)

-- Update ped
RegisterNUICallback('updatePed', function(data, cb)
    TriggerServerEvent('jobclothing:server:updatePed', data.id, data)
    local result = WaitForCB('pedUpdated')
    cb(result or { success = false })
end)

-- Reposition ped (re-run placement)
RegisterNUICallback('repositionPed', function(data, cb)
    local existingPed = Peds and Peds.GetById and Peds.GetById(data.id) or nil
    local model = data.model

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ type = "placementStarted" })

    StartPedPlacement(
        model,
        function(coords, heading)
            TriggerServerEvent('jobclothing:server:updatePed', data.id, {
                model   = model,
                label   = data.label,
                x       = coords.x,
                y       = coords.y,
                z       = coords.z,
                heading = heading,
            })
            local result = WaitForCB('pedUpdated')
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(true)
            SendNUIMessage({ type = "placementFinished" })
            cb({ success = true })
        end,
        function()
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(true)
            SendNUIMessage({ type = "placementCancelled" })
            cb({ success = false, cancelled = true })
        end
    )
end)

-- Create uniform: open clothing editor, then save result
RegisterNUICallback('openClothingEditor', function(data, cb)
    if not ClothingAdapter.IsAvailable() then
        cb({ success = false, error = "No clothing system detected: " .. ClothingAdapter.GetName() })
        return
    end

    -- Save current clothing for preview restore
    _savedClothing = ClothingAdapter.getCurrentClothing()

    -- Close NUI focus so clothing menu can open
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    ClothingAdapter.openClothingEditor(function(outfitData)
        -- Re-open NUI
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)

        if not outfitData then
            cb({ success = false, error = "Clothing editor was cancelled." })
            return
        end

        cb({ success = true, outfitData = outfitData })
    end)
end)

-- Save uniform
RegisterNUICallback('createUniform', function(data, cb)
    TriggerServerEvent('jobclothing:server:createUniform', {
        ped_id       = data.pedId,
        job_name     = data.job,
        job_grade    = data.grade,
        uniform_name = data.name,
        outfit_data  = data.outfitData,
    })
    local result = WaitForCB('uniformCreated')
    cb(result or { success = false })
end)

-- Update uniform
RegisterNUICallback('updateUniform', function(data, cb)
    TriggerServerEvent('jobclothing:server:updateUniform', data.id, {
        uniform_name = data.name,
        outfit_data  = data.outfitData,
    })
    local result = WaitForCB('uniformUpdated')
    cb(result or { success = false })
end)

-- Delete uniform
RegisterNUICallback('deleteUniform', function(data, cb)
    TriggerServerEvent('jobclothing:server:deleteUniform', data.id)
    local result = WaitForCB('uniformDeleted')
    cb(result or { success = false })
end)

-- Teleport to ped
RegisterNUICallback('teleportToPed', function(data, cb)
    TriggerServerEvent('jobclothing:server:teleportToPed', data.pedId)
    cb({})
end)

-- Preview uniform (admin preview)
RegisterNUICallback('previewUniform', function(data, cb)
    if not _savedClothing then
        _savedClothing = ClothingAdapter.getCurrentClothing()
    end
    if data.outfitData then
        ClothingAdapter.applyClothing(data.outfitData)
    end
    cb({})
end)

-- Restore from preview
RegisterNUICallback('restoreClothing', function(data, cb)
    if _savedClothing then
        ClothingAdapter.applyClothing(_savedClothing)
        _savedClothing = nil
    end
    cb({})
end)

-- Get clothing system info
RegisterNUICallback('getSystemInfo', function(data, cb)
    cb({
        clothing = ClothingAdapter.GetName(),
        components = ClothingAdapter.getSupportedComponents(),
    })
end)

-- ──────────────────────────────────────────────────────────
--  Server → Client events
-- ──────────────────────────────────────────────────────────

RegisterNetEvent('jobclothing:openAdmin', function()
    OpenNUI({ admin = true })
end)

RegisterNetEvent('jobclothing:permissionDenied', function(reason)
    -- Show a brief notification
    SetNotificationTextEntry("STRING")
    AddTextComponentString("~r~[JobClothing]~w~ " .. (reason or "Access denied."))
    DrawNotification(false, true)
end)

-- Player uniform selector (from ped interaction)
RegisterNetEvent('jobclothing:receiveUniforms', function(uniforms, jobData)
    if not uniforms or #uniforms == 0 then
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~y~[JobClothing]~w~ No uniforms available for your rank.")
        DrawNotification(false, true)
        return
    end
    -- Open the player-facing selector UI
    OpenNUI({ admin = false, uniforms = uniforms, jobData = jobData })
end)

-- Apply uniform (outfit data sent from server after validation)
RegisterNetEvent('jobclothing:applyOutfit', function(outfitData)
    CloseNUI()
    ClothingAdapter.applyClothing(outfitData)
end)

RegisterNetEvent('jobclothing:notifyError', function(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString("~r~[JobClothing]~w~ " .. (msg or "Error."))
    DrawNotification(false, true)
end)

-- ──────────────────────────────────────────────────────────
--  Player Uniform Selector Trigger
-- ──────────────────────────────────────────────────────────

-- Unified handler: handles both plain number (proximity/ox_target) and table (qb-target)
AddEventHandler('jobclothing:client:openUniformSelector', function(data)
    local pedId
    if type(data) == "table" then
        pedId = data.dbId or data.id or data.pedId
    else
        pedId = tonumber(data)
    end
    if not pedId then
        print("^1[JobClothing] openUniformSelector: missing pedId^7")
        return
    end
    TriggerServerEvent('jobclothing:server:requestUniforms', pedId)
end)

-- Player selects a uniform in the selector UI
RegisterNUICallback('applyUniform', function(data, cb)
    TriggerServerEvent('jobclothing:server:applyUniform', data.uniformId)
    CloseNUI()
    cb({})
end)
