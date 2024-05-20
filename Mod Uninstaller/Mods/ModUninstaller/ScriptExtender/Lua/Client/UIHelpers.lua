UIHelpers = {}

function UIHelpers:PopulateModsToUninstallOptions()
    local modsToUninstallOptions = {}

    for modId, templates in pairs(ModsTemplates) do
        -- Check if the table is not empty
        if next(templates) ~= nil then
            local modName = Ext.Mod.GetMod(modId).Info.Name
            -- Needed since we cannot set 'label + value' for the combo box, so we need to store both in the option and extract id later
            local modOption = modName .. " (" .. modId .. ")"
            table.insert(modsToUninstallOptions, modOption)
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
    table.sort(modUUIDTable, function(a, b)
        local modA = Ext.Mod.GetMod(self:GetModToUninstallUUID(a))
        local modB = Ext.Mod.GetMod(self:GetModToUninstallUUID(b))
        return modA.Info.Name < modB.Info.Name
    end)
end

return UIHelpers
