-- ============================================================
--  JobClothing - Illenium-Appearance Clothing Adapter
-- ============================================================
-- Requires: illenium-appearance (https://github.com/iLLeniumStudios/illenium-appearance)

IlleniumAdapter = {}

--- Get only the clothing components from the player's current appearance
---@return table
function IlleniumAdapter.getCurrentClothing()
    local ped = PlayerPedId()
    local clothing = { components = {}, props = {} }

    -- Read clothing components (skip face=0, hair=2)
    for _, idx in ipairs(JOBCLOTHING.ClothingComponents) do
        local key = JOBCLOTHING.ComponentMap[idx]
        if key then
            clothing.components[key] = {
                drawable  = GetPedDrawableVariation(ped, idx),
                texture   = GetPedTextureVariation(ped, idx),
                palette   = GetPedPaletteVariation(ped, idx),
            }
        end
    end

    -- Read props
    for _, idx in ipairs(JOBCLOTHING.PropIndices) do
        local key = JOBCLOTHING.PropMap[idx]
        if key then
            local drawable = GetPedPropIndex(ped, idx)
            local texture  = GetPedPropTextureIndex(ped, idx)
            clothing.props[key] = { drawable = drawable, texture = texture }
        end
    end

    return clothing
end

--- Open the illenium appearance editor.
--- illenium-appearance has a "clothingOnly" mode we can leverage.
---@param callback function(savedOutfitData)
function IlleniumAdapter.openClothingEditor(callback)
    -- Trigger illenium appearance NUI for clothing
    -- We use startPlayerCustomization export with only components and props enabled
    exports['illenium-appearance']:startPlayerCustomization(function(appearance)
        if appearance then 
            local outfitOnly = IlleniumAdapter.extractClothingOnly(appearance)
            if callback then callback(outfitOnly) end
        else 
            -- Cancelled
            if callback then callback(nil) end
        end
    end, { 
        ped = false, 
        headBlend = false, 
        faceFeatures = false, 
        headOverlays = false, 
        components = true, 
        props = true, 
        tattoos = false, 
        enableExit = true 
    })
end

function IlleniumAdapter.extractClothingOnly(appearanceData)
    local result = { components = {}, props = {} }
    if not appearanceData then return result end

    local components = appearanceData.components or {}
    local props      = appearanceData.props or {}

    -- Handle components array
    for i = 1, #components do
        local comp = components[i]
        if comp and comp.component_id then
            local key = JOBCLOTHING.ComponentMap[comp.component_id]
            if key then
                result.components[key] = {
                    drawable = comp.drawable or 0,
                    texture  = comp.texture or 0,
                    palette  = comp.palette or 0,
                }
            end
        end
    end

    -- Handle props array
    for i = 1, #props do
        local prop = props[i]
        if prop and prop.prop_id then
            local key = JOBCLOTHING.PropMap[prop.prop_id]
            if key then
                result.props[key] = {
                    drawable = prop.drawable or 0,
                    texture  = prop.texture or 0,
                }
            end
        end
    end

    return result
end

function IlleniumAdapter.applyClothing(clothingData)
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
        exports['illenium-appearance']:setPedComponents(ped, formattedComponents)
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
        exports['illenium-appearance']:setPedProps(ped, formattedProps)
    end
end

--- Returns the list of component keys this adapter supports
function IlleniumAdapter.getSupportedComponents()
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
