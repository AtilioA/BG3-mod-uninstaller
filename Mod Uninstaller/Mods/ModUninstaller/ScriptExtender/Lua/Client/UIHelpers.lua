UIHelpers = {}

function UIHelpers:PopulateModsToUninstallOptions()
    local modsToUninstallOptions = {}
    MUDebug(1, "Starting to populate mods to uninstall options.")

    -- STUB: Combine ModsTemplates and StatsEntriesByMod
    -- NOTE: this is a temporary solution to get all mods that have either templates or stats, and will be refactored
    local combinedModsData = {}
    for modId, templates in pairs(ModsTemplates) do
        combinedModsData[modId] = true
    end
    for modId, _ in pairs(ModsStats) do
        combinedModsData[modId] = true
    end

    for modId, _ in pairs(combinedModsData) do
        MUDebug(2, "Checking modId: " .. modId)
        local templates = ModsTemplates[modId]
        local stats = ModsStats[modId]

        -- Check if the mod has either templates or stats
        if (templates and not table.isEmpty(templates)) or (stats and not table.isEmpty(stats)) then
            MUSuccess(1, "Entries found for modId: " .. modId)
            if templates then
                local serializedTemplates = Ext.DumpExport(templates)
                MUDebug(2, serializedTemplates)
            end
            if stats then
                MUDebug(2, "Stats found for modId: " .. modId)
            end
            local mod = Ext.Mod.GetMod(modId)
            if mod then
                local modName = mod.Info.Name
                local modOption = modName .. " (" .. modId .. ")"
                MUDebug(2, "Mod option created: " .. modOption)
                table.insert(modsToUninstallOptions, modOption)
            else
                MUDebug(2, "No mod found for modId: " .. modId)
            end
        else
            MUDebug(2, "No entries found for modId: " .. modId)
        end
    end

    return modsToUninstallOptions
end

-- Extract the modId from the modOption string
function UIHelpers:GetModToUninstallUUID(modOption)
    return modOption:match("%(([^)]+)%)")
end

function UIHelpers:Wrap(text, width)
    -- Ensure width is a positive integer
    if type(width) ~= "number" or width <= 0 then
        error("Width must be a positive integer")
    end

    -- Function to split a string into words
    local function splitIntoWords(str)
        local words = {}
        for word in str:gmatch("%S+") do
            table.insert(words, word)
        end
        return words
    end

    -- Function to join words into lines of specified width
    local function joinWordsIntoLines(words, width)
        local lines, currentLine = {}, ""
        for _, word in ipairs(words) do
            if #currentLine + #word + 1 > width then
                table.insert(lines, currentLine)
                currentLine = word
            else
                if #currentLine > 0 then
                    currentLine = currentLine .. " " .. word
                else
                    currentLine = word
                end
            end
        end
        if #currentLine > 0 then
            table.insert(lines, currentLine)
        end
        return lines
    end

    -- Split the text into words
    local words = splitIntoWords(text)

    -- Join the words into lines of the specified width
    local lines = joinWordsIntoLines(words, width)

    -- Concatenate the lines into a single string with newline characters
    return table.concat(lines, "\n")
end

function UIHelpers:SortModUUIDTableByModName(modUUIDTable)
    if #modUUIDTable < 2 then
        return modUUIDTable
    end

    table.sort(modUUIDTable, function(a, b)
        -- Something is still wrong with the sorting, but it won't throw an error anymore
        local modAUUID = self:GetModToUninstallUUID(a)
        local modBUUID = self:GetModToUninstallUUID(b)

        if not modAUUID or not modBUUID then
            MUWarn(0, "Could not extract mod UUID from mod option: " .. (a or "nil") .. " or " .. (b or "nil"))
            return false
        end

        local modA = Ext.Mod.GetMod(modAUUID)
        local modB = Ext.Mod.GetMod(modBUUID)

        if not modA or not modB or not modA.Info or not modB.Info then
            MUWarn(0, "Could not get mod info for mod UUID: " .. modAUUID .. " or " .. modBUUID)
            return false
        end

        if not modA.Info.Name or not modB.Info.Name then
            MUWarn(0, "Could not get mod name for mod UUID: " .. modAUUID .. " or " .. modBUUID)
            return false
        end

        return modA.Info.Name < modB.Info.Name
    end)
end

--- Get the vec4 color for a rarity string (Common, Uncommon, Rare, Epic, Legendary, Divine, Unique)
-- Courtesy of Aahz
function UIHelpers:GetColorByRarity(rarity)
    local rarity_colors = {
        ["Divine"]        = {0.92, 0.78, 0.03, 1.0},
        ["Legendary"]     = {0.82, 0.00, 0.49, 1.0},
        ["Epic"]          = {0.64, 0.27, 0.91, 1.0},
        ["Rare"]          = {0.20, 0.80, 1.00, 1.0},
        ["Uncommon"]      = {0.00, 0.66, 0.00, 1.0},
        ["Unique"]        = {0.78, 0.65, 0.35, 1.0},
        ["Common"]        = {1.0, 1.0, 1.0, 1.0}
    }
    return rarity_colors[rarity] or {1.0, 1.0, 1.0, 1.0}
end
return UIHelpers
