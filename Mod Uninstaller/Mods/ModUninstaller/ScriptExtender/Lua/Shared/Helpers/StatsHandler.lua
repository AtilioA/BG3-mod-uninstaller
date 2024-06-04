local vanillaPaks = {
    ["Gustav"] = true,
    ["GustavDev"] = true,
    ["Shared"] = true,
    ["SharedDev"] = true,
    ["Honour"] = true
}

local function isVanillaPak(pakName)
    return vanillaPaks[pakName] == true
end

local function logUnknownMod(statEntry, stat, mod)
    _D("Unknown mod in stat entry:")
    _D(string.format("  Stat entry: %s", statEntry))
    _D(string.format("  Stat ModId: %s", (stat.ModId ~= "" and stat.ModId) or "?"))
    _D(string.format("  Stat OriginalModId: %s", (stat.OriginalModId ~= "" and stat.OriginalModId) or "?"))
    if mod then
        _D(string.format("  Mod Info.Name: %s", mod.Info.Name or "?"))
    else
        _D("  Mod Info Name: ?")
    end
end
--- Add a stats entry to the statsEntriesByMod table
---@param statsEntriesByMod table<string, table>
---@param modId string - The ID of the mod
---@param modName string - The name of the mod
---@param statType string - The type of the stat entry, e.g. "StatusData"
---@param statEntry string - The name of the stat entry
local function addModEntry(statsEntriesByMod, modId, modName, statType, statEntry)
    if not statsEntriesByMod[modId] then
        statsEntriesByMod[modId] = {
            ModName = modName,
            Entries = {}
        }
    end

    if not statsEntriesByMod[modId].Entries[statType] then
        statsEntriesByMod[modId].Entries[statType] = {}
    end

    table.insert(statsEntriesByMod[modId].Entries[statType], statEntry)
end

--- Process a stat entry and add it to the statsEntriesByMod table
---@param statsEntriesByMod table<string, table> - The table to store stats entries by mod
---@param statEntry string - The name of the stat entry
---@param statType string - The type of the stat
local function processStatEntry(statsEntriesByMod, statEntry, statType)
    local stat = Ext.Stats.Get(statEntry)
    if not stat then
        return
    end

    local modId = stat.OriginalModId
    local mod = Ext.Mod.GetMod(modId)
    local modName = (mod and mod.Info.Name) or "Unknown"

    if modName == "Unknown" then
        logUnknownMod(statEntry, stat, mod)
    end

    if isVanillaPak(modName) then
        return
    end

    addModEntry(statsEntriesByMod, modId, modName, statType, statEntry)
end

local function processStatsType(statsEntriesByMod, type)
    local statsEntries = Ext.Stats.GetStats(type)
    for _, statEntry in ipairs(statsEntries) do
        processStatEntry(statsEntriesByMod, statEntry, type)
    end
end

function GetStatsEntriesByMod(types)
    local statsEntriesByMod = {}
    for _, type in ipairs(types) do
        processStatsType(statsEntriesByMod, type)
    end
    return statsEntriesByMod
end

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

-- Refactor to call GetStatsEntriesByMod only once

function GetStatusesFromMod(modGuid)
    local statsEntriesByMod = GetStatsEntriesByMod({ "StatusData" })

    if not statsEntriesByMod then
        return
    end

    return statsEntriesByMod[modGuid]["StatusData"]
end

function GetSpellsFromMod(modGuid)
    local statsEntriesByMod = GetStatsEntriesByMod({ "SpellData", "PassiveData" })

    if not statsEntriesByMod then
        return
    end
end
