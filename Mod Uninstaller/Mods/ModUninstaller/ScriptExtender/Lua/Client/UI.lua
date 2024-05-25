-- REFACTOR: modularize etc

-- Function to create a table with item info
-- Courtesy of Aahz
local function createItemInfoTable(tabHeader, icon, name, statName, description, descriptionWidth)
    local itemInfoTable = tabHeader:AddTable("ItemInfo", 2)

    itemInfoTable.Borders = true
    itemInfoTable.SizingStretchSame = true

    local row1 = itemInfoTable:AddRow("Row1")
    local row2 = itemInfoTable:AddRow("Row2")

    local nameCell = row1:AddCell("NameCell")
    local statNameCell = row1:AddCell("StatNameCell")
    local iconCell = row2:AddCell("IconCell")
    local descriptionCell = row2:AddCell("DescriptionCell")

    local itemNameText = nameCell:AddText(name or "<Name>")
    itemNameText.IDContext = statName .. "_NameText"

    local itemStatNameText = statNameCell:AddText(statName or "<StatName>")
    itemStatNameText.IDContext = statName .. "_StatNameText"

    -- TODO: replace with some question mark icon if the game has one
    if DevelReady then
        local itemIcon = iconCell:AddIcon(icon or "")
        if itemIcon then
            itemIcon.IDContext = statName .. "_Icon"
        end
    else
        local itemIcon = iconCell:AddText(UIHelpers:Wrap(icon or "", descriptionWidth or 30))
        local itemIconPlaceholder = iconCell:AddText(UIHelpers:Wrap(
            "*This will have an icon when SE v17 is released*", descriptionWidth or 30))
        if itemIcon then
            itemIcon.IDContext = statName .. "_Icon"
        end
        if itemIconPlaceholder then
            itemIconPlaceholder.IDContext = statName .. "_IconPlaceholder"
        end
    end

    local itemDescription = descriptionCell:AddText(UIHelpers:Wrap(description or "No description provided.",
        descriptionWidth or 33))
    itemDescription.IDContext = statName .. "_DescriptionText"

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
    -- Insert placeholder at the beginning of the options
    table.insert(modsToUninstallOptions, 1, "Click to see the available mods")

    local comboBox = tabHeader:AddCombo("")
    comboBox.IDContext = "ModsToUninstallComboBox"
    comboBox.Options = modsToUninstallOptions
    comboBox.SelectedIndex = 0
    return comboBox
end

---Update the progress label with the given message and color
---@param progressLabel table|nil The progress label to update
---@param message string The message to display
---@param color string The color of the text in hex format
local function updateProgressLabel(progressLabel, message, color)
    if progressLabel then
        progressLabel.Label = message
        progressLabel:SetColor("Text", VCHelpers.Color:hex_to_rgba(color))
    end
end

---Handle the response from the server after attempting to uninstall a mod
---@param progressLabel table|nil The progress label to update
---@param payload string The JSON-encoded payload from the server
local function handleUninstallResponse(progressLabel, payload)
    local data = Ext.Json.Parse(payload)
    local mod = Ext.Mod.GetMod(data.modUUID)
    if not mod then
        return
    end

    local modName = mod.Info.Name
    if data.error then
        updateProgressLabel(progressLabel, "Failed to uninstall mod '" .. modName .. "': " .. data.error, "#FF0000")
    else
        updateProgressLabel(progressLabel, "Successfully uninstalled mod '" .. modName .. "'!", "#00FF00")
    end
end

local function createUninstallButton(tabHeader, modsToUninstallOptions, modsComboBox)
    local button = tabHeader:AddButton("Uninstall", "Uninstall")
    button.IDContext = "UninstallButton"

    local progressLabel = tabHeader:AddText("")
    progressLabel.IDContext = "UninstallProgressLabel"
    progressLabel.SameLine = true

    button.OnClick = function()
        local selectedMod = modsToUninstallOptions[modsComboBox.SelectedIndex + 1]
        if selectedMod == "Click to see the available mods" then
            return
        end

        local selectedModUUID = UIHelpers:GetModToUninstallUUID(selectedMod)
        updateProgressLabel(progressLabel, "Uninstalling mod " .. selectedMod .. "...", "#FFA500") -- Orange color for in-progress

        -- Request the server to take actions to help uninstalling the mod
        Ext.Net.PostMessageToServer("MU_Request_Server_Uninstall_Mod", Ext.Json.Stringify({
            modUUID = selectedModUUID,
            modTemplates = ModsTemplates[selectedModUUID]
        }))
    end

    Ext.RegisterNetListener("MU_Uninstalled_Mod", function(channel, payload)
        handleUninstallResponse(progressLabel, payload)
    end)

    Ext.RegisterNetListener("MU_Uninstall_Mod_Failed", function(channel, payload)
        handleUninstallResponse(progressLabel, payload)
    end)

    return button
end

local function clearTemplatesGroup(tabHeader, templatesGroup)
    if not templatesGroup then
        return
    end

    if DevelReady then
        for _, child in ipairs(templatesGroup.Children or {}) do
            child:Destroy()
        end
    else
        templatesGroup:Destroy()
        return tabHeader:AddGroup("Templates")
    end
end

local function renderTemplates(templatesGroup, selectedModUUID)
    local templates = ModsTemplates[selectedModUUID]
    if #templates == 0 then
        return
    end

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

local function renderStatuses(templatesGroup, selectedModUUID)
    local statuses = GetStatusesFromMod(selectedModUUID)
    if #statuses == 0 then
        return
    end

    local statusText = templatesGroup:AddText(
        "These statuses will be removed from all entities in your save if you click the 'Uninstall' button:")
    statusText:SetColor("Text", VCHelpers.Color:hex_to_rgba("#FF2525"))
    statusText.IDContext = "StatusText"

    for _, status in ipairs(statuses) do
        local statusStat = Ext.Stats.Get(status)
        createItemInfoTable(templatesGroup,
            statusStat.Icon or "",
            Ext.Loca.GetTranslatedString(statusStat.DisplayName) or statusStat.Name or "<Name>",
            statusStat.Name or "<StatusName>",
            Ext.Loca.GetTranslatedString(statusStat.Description) or "No description provided.")
    end
end

local function handleComboBoxChange(value, templatesGroup, modsToUninstallOptions)
    templatesGroup.IDContext = "TemplatesGroup"

    -- Check if the selected option is the placeholder and do nothing if it is
    if value.SelectedIndex == 0 then
        return
    end

    local selectedMod = modsToUninstallOptions[value.SelectedIndex + 1]
    local selectedModUUID = UIHelpers:GetModToUninstallUUID(selectedMod)

    renderTemplates(templatesGroup, selectedModUUID)
    renderStatuses(templatesGroup, selectedModUUID)
end

local function createTemplatesGroup(tabHeader, modsComboBox, modsToUninstallOptions)
    -- Group that will contain the templates elements for the selected mod; useful for destroying the elements when changing the selected mod
    local templatesGroup = tabHeader:AddGroup("Templates")
    -- Handle the change event for the combo box, which will display the templates for the selected mod
    modsComboBox.OnChange = function(value)
        -- First, destroy all the children of the templatesGroup before rendering new ones
        templatesGroup = clearTemplatesGroup(tabHeader, templatesGroup)
        handleComboBoxChange(value, templatesGroup, modsToUninstallOptions)
    end
    return templatesGroup
end

Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Features", function(tabHeader)
    -- REFACTOR: only load on `reset` or button press
    VanillaTemplates, ModsTemplates = GetVanillaAndModsTemplates()

    local modsToUninstallOptions = UIHelpers:PopulateModsToUninstallOptions()
    UIHelpers:SortModUUIDTableByModName(modsToUninstallOptions)

    local uninstallSeparator = createModsToUninstallSeparator(tabHeader)
    local modsToUninstallLabel = createModsToUninstallLabel(tabHeader)

    local modsComboBox = createModsComboBox(tabHeader, modsToUninstallOptions)
    local uninstallButton = createUninstallButton(tabHeader, modsToUninstallOptions, modsComboBox)
    local templatesGroup = createTemplatesGroup(tabHeader, modsComboBox, modsToUninstallOptions)
end)
