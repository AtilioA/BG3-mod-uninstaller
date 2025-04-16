local vanillaPaks = {
    ["GustavX"] = true,
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

    for modId, modData in pairs(statsEntriesByMod) do
        for statType, statEntries in pairs(modData.Entries) do
            table.sort(statEntries, function(a, b)
                local statA = Ext.Stats.Get(a)
                local statB = Ext.Stats.Get(b)
                local aName = Ext.Loca.GetTranslatedString(statA.DisplayName) or statA.Name
                local bName = Ext.Loca.GetTranslatedString(statB.DisplayName) or statB.Name
                return aName < bName
            end)
        end
    end

    return statsEntriesByMod
end

function GetStatsFromMod(modGuid, statsType)
    if not ModsStats or table.isEmpty(ModsStats) then
        ModsStats = GetStatsEntriesByMod({ "StatusData", "SpellData", "PassiveData" })
    end

    local modStatsEntries = ModsStats[modGuid]

    if not modStatsEntries or table.isEmpty(modStatsEntries) then
        return {}
    end

    if not modStatsEntries.Entries or table.isEmpty(modStatsEntries.Entries) then
        return {}
    end

    return modStatsEntries.Entries[statsType]
end

function GetStatusesFromMod(modGuid)
    return GetStatsFromMod(modGuid, "StatusData")
end

function GetSpellsFromMod(modGuid)
    return GetStatsFromMod(modGuid, "SpellData")
end

function GetPassivesFromMod(modGuid)
    return GetStatsFromMod(modGuid, "PassiveData")
end
