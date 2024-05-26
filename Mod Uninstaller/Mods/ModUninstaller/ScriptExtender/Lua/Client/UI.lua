UI = {}
UI.HasLoadedTemplates = false

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

    if DevelReady then
        -- TODO: replace with some question mark icon if the game has one
        local itemIcon = iconCell:AddIcon(icon or "")
        if itemIcon then
            itemIcon.IDContext = statName .. "_Icon"
        end
    else
        local itemIcon = iconCell:AddText(icon or "")
        local itemIconPlaceholder = iconCell:AddText(UIHelpers:Wrap(
            "*This icon will be displayed when SE v17 is released*", descriptionWidth or 30))
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
    button:SetColor("Text", VCHelpers.Color:hex_to_rgba("#FFFFFF"))
    button:SetColor("Button", VCHelpers.Color:hex_to_rgba("#FF2525"))
    button.IDContext = "UninstallButton"

    local progressLabel = tabHeader:AddText("")
    progressLabel.IDContext = "UninstallProgressLabel"
    progressLabel.SameLine = false

    button.OnClick = function()
        local selectedMod = modsToUninstallOptions[modsComboBox.SelectedIndex + 1]
        if selectedMod == "Click to see the available mods" then
            return
        end

        local selectedModUUID = UIHelpers:GetModToUninstallUUID(selectedMod)
        button.Visible = false
        progressLabel.SameLine = false
        updateProgressLabel(progressLabel, "Uninstalling mod " .. selectedMod .. "...", "#FFA500")

        -- Request the server to take actions to help uninstalling the mod
        Ext.Net.PostMessageToServer("MU_Request_Server_Uninstall_Mod", Ext.Json.Stringify({
            modUUID = selectedModUUID,
            modTemplates = ModsTemplates[selectedModUUID]
        }))
    end

    Ext.RegisterNetListener("MU_Uninstalled_Mod", function(channel, payload)
        button.Visible = true
        progressLabel.SameLine = true
        handleUninstallResponse(progressLabel, payload)
    end)

    Ext.RegisterNetListener("MU_Uninstall_Mod_Failed", function(channel, payload)
        button.Visible = true
        progressLabel.SameLine = true
        handleUninstallResponse(progressLabel, payload)
    end)

    return button
end

local function clearTemplatesGroup(templatesGroup)
    if not templatesGroup then
        return
    end
    for _, child in ipairs(templatesGroup.Children or {}) do
        child:Destroy()
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
        -- TODO: refactor this mess after v17 is released smh
        if DevelReady then
            clearTemplatesGroup(templatesGroup)
        elseif templatesGroup then
            templatesGroup:Destroy()
        end
        templatesGroup = tabHeader:AddGroup("Templates")
        templatesGroup.IDContext = "TemplatesGroup"
        handleComboBoxChange(value, templatesGroup, modsToUninstallOptions)
    end
    return templatesGroup
end

local function createLoadTemplatesButton(tabHeader, modsToUninstallOptions)
    local buttonGroup = tabHeader:AddGroup("Parse mod data")
    buttonGroup.IDContext = "LoadTemplatesGroup"
    local buttonSeparator = buttonGroup:AddSeparatorText("REQUIRED: Load data from mods")
    buttonSeparator.IDContext = "LoadTemplatesSeparator"
    local buttonLabel = buttonGroup:AddText(
        "For performance reasons, mod data is only parsed after clicking this button:")
    buttonLabel.IDContext = "LoadTemplatesLabel"
    local button = buttonGroup:AddButton("Parse mod data")
    button.IDContext = "LoadTemplatesButton"

    button.OnClick = function()
        if not UI.HasLoadedTemplates then
            VanillaTemplates, ModsTemplates = GetVanillaAndModsTemplates()
            -- Needed cause some load orders might be too big to send via net messages
            Ext.Net.PostMessageToServer("MU_Server_Should_Load_Templates", "")

            UI.HasLoadedTemplates = true

            local modsToUninstallOptions = UIHelpers:PopulateModsToUninstallOptions()
            UIHelpers:SortModUUIDTableByModName(modsToUninstallOptions)

            local uninstallSeparator = createModsToUninstallSeparator(tabHeader)
            local modsToUninstallLabel = createModsToUninstallLabel(tabHeader)

            local modsComboBox = createModsComboBox(tabHeader, modsToUninstallOptions)
            local uninstallButton = createUninstallButton(tabHeader, modsToUninstallOptions, modsComboBox)
            local templatesGroup = createTemplatesGroup(tabHeader, modsComboBox, modsToUninstallOptions)
            buttonGroup:Destroy()
        else
            button.Label = "Templates have already been loaded. You may select a mod to uninstall."
            MUSuccess(0, "Templates have already been loaded. You may select a mod to uninstall.")
        end
    end
end

Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Features", function(tabHeader)
    createLoadTemplatesButton(tabHeader)
end)

return UI
