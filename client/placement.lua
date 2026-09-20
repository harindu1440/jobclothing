-- ============================================================
--  JobClothing - Interactive Ped Placement (Client)
-- ============================================================
-- Uses a Wait(0) loop ONLY during active placement session.
-- Exits immediately on confirm or cancel.

local PlacementActive = false
local PlacementPed    = nil

-- Controls
local KEYS = {
    FORWARD  = 32,   -- W
    BACKWARD = 33,   -- S
    LEFT     = 34,   -- A
    RIGHT    = 35,   -- D
    UP       = 21,   -- Left Shift (move up)
    DOWN     = 20,   -- Z (move down)
    ROT_L    = 44,   -- Q (rotate left)
    ROT_R    = 45,   -- E (rotate right)
    CONFIRM  = 191,  -- Enter
    CANCEL   = 200,  -- Backspace
}

local MOVE_SPEED = 0.05
local ROT_SPEED  = 2.0

--- Spawn a preview ped at given coords
---@param model string
---@param coords vector3
---@param heading number
---@return number|nil entity handle
local function SpawnPreviewPed(model, coords, heading)
    local modelHash = GetHashKey(model)
    if not IsModelInCdimage(modelHash) then return nil end

    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 3000 do
        Wait(10)
        timeout = timeout + 10
    end

    if not HasModelLoaded(modelHash) then return nil end

    local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z - 1.0, heading, false, true)
    SetEntityAlpha(ped, 200, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    TaskStandStill(ped, -1)
    SetModelAsNoLongerNeeded(modelHash)
    return ped
end

--- Display placement controls hint on screen
local function DrawPlacementHint()
    local lines = {
        "^2[W/S]^7 Forward/Back   ^2[A/D]^7 Left/Right",
        "^2[Shift/Z]^7 Up/Down   ^2[Q/E]^7 Rotate",
        "^2[Enter]^7 Confirm   ^2[Backspace]^7 Cancel",
    }
    local y = 0.85
    for _, line in ipairs(lines) do
        SetTextFont(0)
        SetTextScale(0.35, 0.35)
        SetTextColour(255, 255, 255, 230)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(line)
        DrawText(0.5, y)
        y = y + 0.025
    end
end

--- Start the interactive ped placement mode
---@param model string
---@param onConfirm function(coords, heading)
---@param onCancel function()
function StartPedPlacement(model, onConfirm, onCancel)
    if PlacementActive then return end
    PlacementActive = true

    local playerPed = PlayerPedId()
    local startCoords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    local ped = SpawnPreviewPed(model, startCoords, heading)
    if not ped then
        print("^1[JobClothing] Failed to spawn preview ped: " .. tostring(model) .. "^7")
        PlacementActive = false
        if onCancel then onCancel() end
        return
    end

    PlacementPed = ped

    -- Disable HUD/camera interference
    SetNuiFocus(false, false)

    CreateThread(function()
        while PlacementActive do
            local pos     = GetEntityCoords(ped)
            local rot     = heading
            local changed = false

            -- Movement
            if IsControlPressed(0, KEYS.FORWARD) then
                local fwd = GetEntityForwardVector(ped)
                pos = pos + fwd * MOVE_SPEED
                changed = true
            end
            if IsControlPressed(0, KEYS.BACKWARD) then
                local fwd = GetEntityForwardVector(ped)
                pos = pos - fwd * MOVE_SPEED
                changed = true
            end
            if IsControlPressed(0, KEYS.LEFT) then
                local right = vector3(
                    -math.sin(math.rad(GetEntityHeading(ped))),
                    math.cos(math.rad(GetEntityHeading(ped))),
                    0.0
                )
                pos = pos - right * MOVE_SPEED
                changed = true
            end
            if IsControlPressed(0, KEYS.RIGHT) then
                local right = vector3(
                    -math.sin(math.rad(GetEntityHeading(ped))),
                    math.cos(math.rad(GetEntityHeading(ped))),
                    0.0
                )
                pos = pos + right * MOVE_SPEED
                changed = true
            end
            if IsControlPressed(0, KEYS.UP) then
                pos = vector3(pos.x, pos.y, pos.z + MOVE_SPEED)
                changed = true
            end
            if IsControlPressed(0, KEYS.DOWN) then
                pos = vector3(pos.x, pos.y, pos.z - MOVE_SPEED)
                changed = true
            end

            -- Rotation
            if IsControlPressed(0, KEYS.ROT_L) then
                heading = (heading + ROT_SPEED) % 360
                changed = true
            end
            if IsControlPressed(0, KEYS.ROT_R) then
                heading = (heading - ROT_SPEED + 360) % 360
                changed = true
            end

            if changed then
                SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, false)
                SetEntityHeading(ped, heading)
            end

            DrawPlacementHint()

            -- Confirm
            if IsControlJustPressed(0, KEYS.CONFIRM) then
                PlacementActive = false
                local finalCoords = GetEntityCoords(ped)
                local finalHeading = GetEntityHeading(ped)

                -- Remove alpha (turn solid)
                SetEntityAlpha(ped, 255, false)
                FinaliseSpawnedPed(ped)
                PlacementPed = nil

                if onConfirm then
                    onConfirm(
                        { x = finalCoords.x, y = finalCoords.y, z = finalCoords.z },
                        finalHeading
                    )
                end
                return
            end

            -- Cancel
            if IsControlJustPressed(0, KEYS.CANCEL) then
                PlacementActive = false
                DeleteEntity(ped)
                PlacementPed = nil
                if onCancel then onCancel() end
                return
            end

            Wait(0)
        end
    end)
end

--- Finalise a newly placed ped (freeze, invincible, no tasks)
---@param ped number entity handle
function FinaliseSpawnedPed(ped)
    if not DoesEntityExist(ped) then return end

    if Config.Ped.invincible then
        SetEntityInvincible(ped, true)
    end
    if Config.Ped.frozen then
        FreezeEntityPosition(ped, true)
    end
    if Config.Ped.blockEvents then
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 17, true)
        SetPedCanRagdoll(ped, false)
    end

    TaskStandStill(ped, -1)
    SetEntityAsMissionEntity(ped, true, true)
end

--- Cancel active placement (e.g. if NUI closes)
function CancelPlacement()
    if PlacementActive and PlacementPed then
        PlacementActive = false
        DeleteEntity(PlacementPed)
        PlacementPed = nil
    end
end
