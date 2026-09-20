-- ============================================================
--  JobClothing - fivem-appearance Clothing Adapter
-- ============================================================

FivemAppearanceAdapter = {}

function FivemAppearanceAdapter.getCurrentClothing()
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

function FivemAppearanceAdapter.openClothingEditor(callback)
    -- fivem-appearance exports openAppearance / openClothes
    local ok = pcall(function()
        exports['fivem-appearance']:openClothesMenu()
    end)

    if not ok then
        -- Fallback: open full appearance editor
        pcall(function()
            exports['fivem-appearance']:openAppearanceMenu()
        end)
    end

    local handler
    handler = AddEventHandler('fivem-appearance:appearanceSaved', function(appearanceData)
        RemoveEventHandler(handler)
        local outfitOnly = FivemAppearanceAdapter.extractClothingOnly(appearanceData)
        if callback then callback(outfitOnly) end
    end)
end

function FivemAppearanceAdapter.extractClothingOnly(appearanceData)
    local result = { components = {}, props = {} }
    if not appearanceData then return result end

    -- fivem-appearance stores clothes per component key
    for _, idx in ipairs(JOBCLOTHING.ClothingComponents) do
        local key = JOBCLOTHING.ComponentMap[idx]
        if key then
            local comp = appearanceData[key] or appearanceData.components and appearanceData.components[key]
            if comp then
                result.components[key] = {
                    drawable = comp.drawable or comp.value or 0,
                    texture  = comp.texture  or 0,
                    palette  = comp.palette  or 0,
                }
            end
        end
    end

    for _, idx in ipairs(JOBCLOTHING.PropIndices) do
        local key = JOBCLOTHING.PropMap[idx]
        if key then
            local prop = appearanceData[key] or appearanceData.props and appearanceData.props[key]
            if prop then
                result.props[key] = {
                    drawable = prop.drawable or prop.value or 0,
                    texture  = prop.texture  or 0,
                }
            end
        end
    end

    return result
end

function FivemAppearanceAdapter.applyClothing(clothingData)
    if not clothingData then return end
    local ped = PlayerPedId()

    local formattedComponents = {}
    local components = clothingData.components or {}
    for key, data in pairs(components) do
        local idx = JOBCLOTHING.ComponentIndex[key]
        if idx then
            formattedComponents[#formattedComponents + 1] = {
                component_id = idx,
                drawable = data.drawable or 0,
                texture = data.texture or 0,
            }
        end
    end

    if #formattedComponents > 0 then
        exports['fivem-appearance']:setPedComponents(ped, formattedComponents)
    end

    local formattedProps = {}
    local props = clothingData.props or {}
    for key, data in pairs(props) do
        local idx = JOBCLOTHING.PropIndex[key]
        if idx then
            if data.drawable == nil or data.drawable == -1 then
                ClearPedProp(ped, idx)
            else
                formattedProps[#formattedProps + 1] = {
                    prop_id = idx,
                    drawable = data.drawable,
                    texture = data.texture or 0,
                }
            end
        end
    end

    if #formattedProps > 0 then
        exports['fivem-appearance']:setPedProps(ped, formattedProps)
    end
end

function FivemAppearanceAdapter.getSupportedComponents()
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
