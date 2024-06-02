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

local function analyzeStatsEntries()
    local function shouldSkipMod(modName)
        local skipMods = { "Shared", "Gustav", "GustavDev", "SharedDev" }
        for _, skipMod in ipairs(skipMods) do
            if modName == skipMod then
                return true
            end
        end
        return false
    end


    local statsTypes = { "StatusData", "SpellData", "PassiveData", "Armor", "Weapon", "Character", "Object",
        "TreasureTable", "TreasureCategory" }
    local statsEntriesByMod = GetStatsEntriesByMod(statsTypes)

    if not statsEntriesByMod then
        return
    end

    for modId, modData in pairs(statsEntriesByMod) do
        if shouldSkipMod(modData.ModName) then
            goto continue
        end

        _P("Mod ID: " .. modId .. ", Mod Name: " .. modData.ModName)
        _D(modData)

        ::continue::
    end
end

-- analyzeStatsEntries()
