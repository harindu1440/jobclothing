-- ============================================================
--  JobClothing - Server-Side Permissions
-- ============================================================

Permissions = {}

--- Check all configured permission methods for the source player.
--- Returns true only if the player passes at least one check.
---@param source number
---@return boolean
function Permissions.IsAdmin(source)
    if not source or source == 0 then return false end

    -- 1. ACE permission check
    if Config.UseAcePermission and Config.AcePermission then
        if IsPlayerAceAllowed(tostring(source), Config.AcePermission) then
            DebugPrint("Permission granted via ACE for source %d", source)
            return true
        end
    end

    -- 2. Framework group check
    if Framework and Framework.HasPermission then
        if Framework.HasPermission(source) then
            DebugPrint("Permission granted via framework group for source %d", source)
            return true
        end
    end

    DebugPrint("Permission denied for source %d", source)
    return false
end

--- Notify the client that a permission check failed
---@param source number
---@param reason string
function Permissions.Deny(source, reason)
    TriggerClientEvent('jobclothing:permissionDenied', source, reason or "Access denied.")
end
