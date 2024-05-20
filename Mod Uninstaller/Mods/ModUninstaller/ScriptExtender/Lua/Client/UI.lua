-- REFACTOR: modularize etc

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
    local itemInfoDesc = c4:AddText(UIHelpers:Wrap(description or "No description provided.", descriptionWidth or 33))
    itemInfoDesc.IDContext = "IIidesc"

    return itemInfoTable
end

local function createModsToUninstallSeparator(tabHeader)
    local separator = tabHeader:AddSeparatorText("Mods to uninstall")
    separator.IDContext = "ModsToUninstall"
    return separator
end

local function createModsToUninstallLabel(tabHeader)
    local label = tabHeader:AddText("Select the mod to uninstall:")
    label.IDContext = "ModsToUninstallLabel"
    label.SameLine = false
    return label
end

local function createModsComboBox(tabHeader, modsToUninstallOptions)
    local initialValue = modsToUninstallOptions[1]
    local comboBox = tabHeader:AddCombo("", "initialValue")
    comboBox.IDContext = "ModsToUninstallComboBox"
    comboBox.Options = modsToUninstallOptions
    comboBox.SelectedIndex = 0
    return comboBox
end

local function createUninstallButton(tabHeader, modsToUninstallOptions, modsComboBox)
    local button = tabHeader:AddButton("Uninstall", "Uninstall")
    button.IDContext = "UninstallButton"
    button.OnClick = function()
        local selectedMod = modsToUninstallOptions[modsComboBox.SelectedIndex + 1]
        local selectedModUUID = UIHelpers:GetModToUninstallUUID(selectedMod)
        -- Request the server to take actions to help uninstalling the mod
        Ext.Net.PostMessageToServer("MU_Request_Server_Uninstall_Mod", Ext.Json.Stringify({
            modUUID = selectedModUUID
        }))
    end
    return button
end

local function clearTemplatesGroup(templatesGroup)
    if templatesGroup.Children ~= nil then
        for _, child in ipairs(templatesGroup.Children) do
            child:Destroy()
        end
    end
end

local function renderTemplates(templatesGroup, selectedModUUID)
    local templates = ModsTemplates[selectedModUUID]
    if #templates > 0 then
        local templateText = templatesGroup:AddText(
            "These items will be deleted from your save if you click the 'Uninstall' button:")
        templateText:SetColor("Text", VCHelpers.Color:hex_to_rgba("#FF2525"))
        templateText.IDContext = "TemplateText"

        for _, template in ipairs(templates) do
            createItemInfoTable(templatesGroup,
                template.Icon or "",
                template.DisplayName or template.Name or "<Name>",
                template.Stats or "<StatName>",
                template.Description or "No description provided.")
        end
    end
end

local function renderStatuses(templatesGroup, selectedModUUID)
    local statuses = GetStatusesFromMod(selectedModUUID)
    if #statuses > 0 then
        local statusText = templatesGroup:AddText(
            "These statuses will be removed from all entities in your save if you click the 'Uninstall' button:")
        statusText:SetColor("Text", VCHelpers.Color:hex_to_rgba("#FF2525"))
        statusText.IDContext = "StatusText"

        for _, status in ipairs(statuses) do
            local statusStat = Ext.Stats.Get(status)
            _P(statusStat.Name)
            createItemInfoTable(templatesGroup,
                statusStat.Icon or "",
                Ext.Loca.GetTranslatedString(statusStat.DisplayName) or statusStat.Name or "<Name>",
                statusStat.Name or "<StatusName>",
                Ext.Loca.GetTranslatedString(statusStat.Description) or "No description provided.")
        end
    end
end

local function handleComboBoxChange(value, templatesGroup, modsToUninstallOptions)
    -- First, destroy all the children of the templatesGroup before rendering new ones
    clearTemplatesGroup(templatesGroup)
    templatesGroup.IDContext = "TemplatesGroup"

    local selectedMod = modsToUninstallOptions[value.SelectedIndex + 1]
    local selectedModUUID = UIHelpers:GetModToUninstallUUID(selectedMod)
    local selectedModStatuses = GetStatusesFromMod(selectedModUUID)
    _D(selectedModStatuses)
    MUDebug(1, "Selected mod to uninstall: " .. selectedMod)

    renderTemplates(templatesGroup, selectedModUUID)
    renderStatuses(templatesGroup, selectedModUUID)
end

local function createTemplatesGroup(tabHeader, modsComboBox, modsToUninstallOptions)
    -- Group that will contain the templates elements for the selected mod; useful for destroying the elements when changing the selected mod
    local templatesGroup = tabHeader:AddGroup("Templates")
    -- Handle the change event for the combo box, which will display the templates for the selected mod
    modsComboBox.OnChange = function(value)
        handleComboBoxChange(value, templatesGroup, modsToUninstallOptions)
    end
    return templatesGroup
end

Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Features", function(tabHeader)
    local modsToUninstallOptions = UIHelpers:PopulateModsToUninstallOptions()

    createModsToUninstallSeparator(tabHeader)
    createModsToUninstallLabel(tabHeader)

    local modsComboBox = createModsComboBox(tabHeader, modsToUninstallOptions)
    createUninstallButton(tabHeader, modsToUninstallOptions, modsComboBox)
    createTemplatesGroup(tabHeader, modsComboBox, modsToUninstallOptions)
end)
