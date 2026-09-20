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

--- Extract only clothing/prop components from a full illenium appearance object
---@param appearanceData table
---@return table {components={}, props={}}
function IlleniumAdapter.extractClothingOnly(appearanceData)
    local result = { components = {}, props = {} }
    if not appearanceData then return result end

    -- illenium uses "components" and "props" tables inside its appearance data
    local components = appearanceData.components or {}
    local props      = appearanceData.props or {}

    for _, idx in ipairs(JOBCLOTHING.ClothingComponents) do
        local key = JOBCLOTHING.ComponentMap[idx]
        if key and components[key] then
            result.components[key] = {
                drawable = components[key].drawable,
                texture  = components[key].texture,
                palette  = components[key].palette or 0,
            }
        end
    end

    for _, idx in ipairs(JOBCLOTHING.PropIndices) do
        local key = JOBCLOTHING.PropMap[idx]
        if key and props[key] then
            result.props[key] = {
                drawable = props[key].drawable,
                texture  = props[key].texture,
            }
        end
    end

    return result
end

--- Apply clothing data to the local player WITHOUT changing appearance
---@param clothingData table {components={}, props={}}
function IlleniumAdapter.applyClothing(clothingData)
    if not clothingData then return end
    local ped = PlayerPedId()

    -- Apply components
    local components = clothingData.components or {}
    for key, data in pairs(components) do
        local idx = JOBCLOTHING.ComponentIndex[key]
        if idx then
            SetPedComponentVariation(ped, idx, data.drawable or 0, data.texture or 0, data.palette or 0)
        end
    end

    -- Apply props
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
