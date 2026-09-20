-- ============================================================
--  JobClothing - Configuration
-- ============================================================

Config = {}

-- Command to open the admin UI
Config.Command = "jobclothing"

-- Framework detection: "auto" | "qbcore" | "qbox"
Config.Framework = "auto"

-- Target detection:  "auto" | "ox_target" | "qb-target" | "none"
Config.Target = "auto"

-- Clothing system detection: "auto" | "illenium-appearance" | "fivem-appearance" | "qb-clothing"
Config.Clothing = "auto"

-- Storage backend: "auto" | "oxmysql" | "json"
Config.Storage = "auto"

-- Admin groups allowed to use /jobclothing
Config.AdminGroups = {
    ["god"]   = true,
    ["admin"] = true,
}

-- Also support ACE permission: jobclothing.admin
-- Grant with: add_ace group.admin jobclothing.admin allow
Config.UseAcePermission = true
Config.AcePermission     = "jobclothing.admin"

-- Grade inheritance for players interacting with the ped
--   false → player can ONLY use uniforms for their exact grade
--   true  → player can use uniforms for their grade AND all lower grades
Config.GradeInheritance = false

-- Ped settings
Config.Ped = {
    invincible  = true,   -- ped cannot be killed
    frozen      = true,   -- ped does not move
    blockEvents = true,   -- disable combat / flee tasks
    scenario    = nil,    -- optional: "WORLD_HUMAN_STAND_MOBILE" etc.
}

-- Interaction distance for the fallback proximity key (when no target resource)
Config.InteractionDistance = 2.0

-- Interaction key for fallback (38 = E)
Config.InteractionKey = 38

-- Show debug prints
Config.Debug = false

-- JSON storage data path (relative to resource root)
Config.JsonDataPath = "data"
