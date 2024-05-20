--- Get stats loaded by a specific mod
---@param modGuid string The UUID of the mod
---@param type string The type of stats to retrieve (optional)
---@return table<string> - The names of the stats loaded by the mod
function GetStatsLoadedByMod(modGuid, type)
    local loadOrder = Ext.Mod.GetLoadOrder()
    local modIndex = nil

    -- Find the index of the specified mod in the load order
    for index, guid in ipairs(loadOrder) do
        if guid == modGuid then
            modIndex = index
            break
        end
    end

    if not modIndex then
        -- Mod not found in load order
        return {}
    end

    local allStatsBeforeCurrentMod = Ext.Stats.GetStatsLoadedBefore(modGuid, type)
    local allStatsBeforeNextMod

    if modIndex == #loadOrder then
        -- If the mod is the last in the load order, there is no mod after it, so we get all stats
        allStatsBeforeNextMod = Ext.Stats.GetStats(type)
    else
        local modAfterGuid = loadOrder[modIndex + 1]
        allStatsBeforeNextMod = Ext.Stats.GetStatsLoadedBefore(modAfterGuid, type)
    end

    local modStats = table.getDifference(allStatsBeforeNextMod, allStatsBeforeCurrentMod)

    return modStats
end

function GetStatusesFromMod(modGuid)
    return GetStatsLoadedByMod(modGuid, "StatusData")
end
