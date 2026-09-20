-- ============================================================
--  JobClothing - Shared Constants
-- ============================================================

JOBCLOTHING = JOBCLOTHING or {}

-- Component index → human-readable key mapping (GTA V drawables)
JOBCLOTHING.ComponentMap = {
    [0]  = "face",
    [1]  = "mask",
    [2]  = "hair",
    [3]  = "torso",
    [4]  = "legs",
    [5]  = "bags",
    [6]  = "shoes",
    [7]  = "accessories",
    [8]  = "undershirt",
    [9]  = "bodyarmor",
    [10] = "decals",
    [11] = "jacket",
}

-- Prop index → human-readable key mapping
JOBCLOTHING.PropMap = {
    [0] = "hat",
    [1] = "glasses",
    [2] = "ears",
    [6] = "watch",
    [7] = "bracelet",
}

-- Clothing-only component indices (exclude face=0, hair=2)
JOBCLOTHING.ClothingComponents = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 }

-- All prop indices
JOBCLOTHING.PropIndices = { 0, 1, 2, 6, 7 }

-- Reverse lookup: key → component index
JOBCLOTHING.ComponentIndex = {}
for k, v in pairs(JOBCLOTHING.ComponentMap) do
    JOBCLOTHING.ComponentIndex[v] = k
end

JOBCLOTHING.PropIndex = {}
for k, v in pairs(JOBCLOTHING.PropMap) do
    JOBCLOTHING.PropIndex[v] = k
end
