-- ============================================================
--  JobClothing - QB-Clothing Adapter
-- ============================================================

QBClothingAdapter = {}

function QBClothingAdapter.getCurrentClothing()
    local ped      = PlayerPedId()
    local clothing = { components = {}, props = {} }

    for _, idx in ipairs(JOBCLOTHING.ClothingComponents) do
        local key = JOBCLOTHING.ComponentMap[idx]
        if key then
            clothing.components[key] = {
                drawable = GetPedDrawableVariation(ped, idx),
                texture  = GetPedTextureVariation(ped, idx),
                palette  = GetPedPaletteVariation(ped, idx),
            }
        end
    end

    for _, idx in ipairs(JOBCLOTHING.PropIndices) do
        local key = JOBCLOTHING.PropMap[idx]
        if key then
            clothing.props[key] = {
                drawable = GetPedPropIndex(ped, idx),
                texture  = GetPedPropTextureIndex(ped, idx),
            }
        end
    end

    return clothing
end

function QBClothingAdapter.openClothingEditor(callback)
    -- qb-clothing: TriggerEvent to open the menu
    TriggerEvent('qb-clothing:client:openClothingOnly')

    -- qb-clothing does not have a reliable client-side save event that we can hook into.
    -- Instead, we wait for the NUI focus to drop, meaning the player closed the menu.
    Citizen.CreateThread(function()
        -- Wait for menu to open and grab focus
        Wait(1000)
        
        while IsNuiFocused() do
            Wait(500)
        end
        
        -- Menu closed, grab current clothes
        local currentClothes = QBClothingAdapter.getCurrentClothing()
        if callback then callback(currentClothes) end
    end)
end

function QBClothingAdapter.extractClothingOnly(outfit)
    local result = { components = {}, props = {} }
    if not outfit then return result end

    -- qb-clothing uses numeric keys for components
    -- Map them to our string keys
    for _, idx in ipairs(JOBCLOTHING.ClothingComponents) do
        local key = JOBCLOTHING.ComponentMap[idx]
        local data = outfit[tostring(idx)] or outfit[idx]
        if key and data then
            result.components[key] = {
                drawable = data.drawable or data.item or 0,
                texture  = data.texture  or 0,
                palette  = data.palette  or 0,
            }
        end
    end

    -- Props: qb-clothing uses keys like "hat", "glasses" etc. directly
    for _, idx in ipairs(JOBCLOTHING.PropIndices) do
        local key = JOBCLOTHING.PropMap[idx]
        local data = outfit[key] or outfit[tostring(idx + 100)] -- fallback
        if key and data then
            result.props[key] = {
                drawable = data.drawable or data.item or 0,
                texture  = data.texture  or 0,
            }
        end
    end

    return result
end

function QBClothingAdapter.applyClothing(clothingData)
    if not clothingData then return end
    local ped = PlayerPedId()

    local components = clothingData.components or {}
    for key, data in pairs(components) do
        local idx = JOBCLOTHING.ComponentIndex[key]
        if idx then
            SetPedComponentVariation(ped, idx, data.drawable or 0, data.texture or 0, data.palette or 0)
        end
    end

    local props = clothingData.props or {}
    for key, data in pairs(props) do
        local idx = JOBCLOTHING.PropIndex[key]
        if idx then
            if data.drawable == nil or data.drawable == -1 then
                ClearPedProp(ped, idx)
            else
                SetPedPropIndex(ped, idx, data.drawable, data.texture or 0, true)
            end
        end
    end
end

function QBClothingAdapter.getSupportedComponents()
    local components = {}
    for _, idx in ipairs(JOBCLOTHING.ClothingComponents) do
        components[#components + 1] = JOBCLOTHING.ComponentMap[idx]
    end
    local props = {}
    for _, idx in ipairs(JOBCLOTHING.PropIndices) do
        props[#props + 1] = JOBCLOTHING.PropMap[idx]
    end
    return { components = components, props = props }
end
