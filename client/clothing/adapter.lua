-- ============================================================
--  JobClothing - Clothing Adapter Auto-Detector (Client)
-- ============================================================

ClothingAdapter = {}
local _activeAdapter = nil
local _clothingName  = "none"

local function DetectClothing()
    local cfg = Config.Clothing or "auto"

    if cfg ~= "auto" then
        -- Forced
        if cfg == "illenium-appearance" and GetResourceState('illenium-appearance') == 'started' then
            _activeAdapter = IlleniumAdapter
            _clothingName  = "illenium-appearance"
        elseif cfg == "fivem-appearance" and GetResourceState('fivem-appearance') == 'started' then
            _activeAdapter = FivemAppearanceAdapter
            _clothingName  = "fivem-appearance"
        elseif cfg == "qb-clothing" and GetResourceState('qb-clothing') == 'started' then
            _activeAdapter = QBClothingAdapter
            _clothingName  = "qb-clothing"
        else
            print("^1[JobClothing] WARNING: Forced clothing '" .. cfg .. "' not running!^7")
        end
    else
        -- Auto detect in priority order
        if GetResourceState('illenium-appearance') == 'started' then
            _activeAdapter = IlleniumAdapter
            _clothingName  = "illenium-appearance"
        elseif GetResourceState('fivem-appearance') == 'started' then
            _activeAdapter = FivemAppearanceAdapter
            _clothingName  = "fivem-appearance"
        elseif GetResourceState('qb-clothing') == 'started' then
            _activeAdapter = QBClothingAdapter
            _clothingName  = "qb-clothing"
        else
            print("^1[JobClothing] WARNING: No supported clothing system detected.^7")
        end
    end

    print(string.format("^2[JobClothing] Clothing: %s^7", _clothingName))
end

-- Public interface —————————————————————————————————

function ClothingAdapter.GetName()
    return _clothingName
end

function ClothingAdapter.IsAvailable()
    return _activeAdapter ~= nil
end

function ClothingAdapter.getCurrentClothing()
    if not _activeAdapter then
        -- Fallback: read directly from GTA natives
        local ped = PlayerPedId()
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
    return _activeAdapter.getCurrentClothing()
end

function ClothingAdapter.openClothingEditor(callback)
    if not _activeAdapter then
        if callback then callback(nil) end
        return
    end
    _activeAdapter.openClothingEditor(callback)
end

function ClothingAdapter.applyClothing(clothingData)
    if not clothingData then return end

    if _activeAdapter and _activeAdapter.applyClothing then
        _activeAdapter.applyClothing(clothingData)
        return
    end

    -- Fallback: Always use native application to ensure clothing-only change
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

function ClothingAdapter.getSupportedComponents()
    if not _activeAdapter then return { components = {}, props = {} } end
    return _activeAdapter.getSupportedComponents()
end

-- Init on resource start
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DetectClothing()
    end
end)
