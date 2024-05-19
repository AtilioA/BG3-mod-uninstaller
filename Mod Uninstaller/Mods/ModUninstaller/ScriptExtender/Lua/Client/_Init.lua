local modTemplates = GetModsTemplates()

local function populateModsToUninstallOptions()
    local modsToUninstallOptions = {}

    for modId, templates in pairs(modTemplates) do
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
local function getModToUninstallUUID(modOption)
    return modOption:match("%(([^)]+)%)")
end


local function wrap(text, width)
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

-- Function to create an item info table
-- Courtesy of Aahz
local function createItemInfoTable(tabHeader, icon, name, statName, description, descriptionWidth)
    local itemInfoTable = tabHeader:AddTable("ItemInfo", 2)
    itemInfoTable.Borders = true
    itemInfoTable.SizingStretchSame = true
    local r1 = itemInfoTable:AddRow("IIr1")
    local r2 = itemInfoTable:AddRow("IIr2")
    local c1 = r1:AddCell("IIc1")
    local c2 = r1:AddCell("IIc2")
    local itemInfoIconCell = r2:AddCell("IIc3")
    local c4 = r2:AddCell("IIc4")
    local itemInfoNameText = c1:AddText(name or "<Name>")
    local itemInfoStatNameText = c2:AddText(statName or "<StatName>")
    local itemInfoIcon = itemInfoIconCell:AddIcon(icon or "Item_ARM_Padded_3")
    local itemInfoDesc = c4:AddText(wrap(description or "No description provided.", descriptionWidth or 33))
    itemInfoDesc.IDContext = "IIidesc"

    return itemInfoTable
end

Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Features", function(tabHeader)
    local modsToUninstallOptions = populateModsToUninstallOptions()
    local modsToUninstall = tabHeader:AddText("Mods to uninstall")
    modsToUninstall.IDContext = "ModsToUninstall"

    local initialValue = modsToUninstallOptions[1]
    local comboBox = tabHeader:AddCombo("", initialValue)
    comboBox.IDContext = "ModsToUninstallComboBox"
    comboBox.Options = modsToUninstallOptions

    -- Set initial selection
    comboBox.SelectedIndex = 0

    -- Group that will contain the templates elements for the selected mod; useful for destroying the elements when changing the selected mod
    local templatesGroup = tabHeader:AddGroup("Templates")

    -- Handle the change event for the combo box, which will display the templates for the selected mod
    comboBox.OnChange = function(value)
        -- First, destroy all the children of the templatesGroup before rendering new ones
        if templatesGroup.Children ~= nil then
            for _, child in ipairs(templatesGroup.Children) do
                child:Destroy()
            end
        end

        templatesGroup.IDContext = "TemplatesGroup"

        local selectedMod = modsToUninstallOptions[value.SelectedIndex + 1]
        local selectedModUUID = getModToUninstallUUID(selectedMod)

        MUDebug(1, "Selected mod to uninstall: " .. selectedMod)

        -- Iterate the table associated with the selectedMod UUID and call createItemInfoTable for each template there
        for _, template in ipairs(modTemplates[selectedModUUID]) do
            createItemInfoTable(templatesGroup,
                template.Icon or "",
                template.DisplayName or template.Name or "<Name>",
                template.Stats or "<StatName>",
                template.Description or "No description provided.")
        end
    end
end)
