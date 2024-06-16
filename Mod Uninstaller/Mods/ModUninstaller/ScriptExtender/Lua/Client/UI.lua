UI = {}
UI.HasLoadedTemplates = false

-- Function to create a table with item info
-- Courtesy of Aahz
local function createItemInfoTable(tabHeader, icon, rarity, name, statName, description, descriptionWidth)
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
    if icon and icon ~= "" then
        local itemIcon = iconCell:AddImage(icon)
        if not itemIcon.ImageData or itemIcon.ImageData.Icon == "" then
            itemIcon:Destroy()
            itemIcon = iconCell:AddImage("Item_Unknown")
            MUPrint("Setting to unknown in row: %s", icon)
        end
        -- iconCell.Children[1]:Destroy()

        local borderColor = UIHelpers:GetColorByRarity(rarity)
        itemIcon.Border = borderColor
        -- TODO: set size?
        if itemIcon then
            itemIcon.IDContext = statName .. "_Icon"
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

        -- It's a bit gross, but Lua is even more
        if ModsStats[selectedModUUID] and not table.isEmpty(ModsStats[selectedModUUID]) then
            updateProgressLabel(progressLabel,
                "Uninstalling mod " .. selectedMod .. "...\nThis might take a while.", "#FFA500")
        else
            updateProgressLabel(progressLabel,
                "Uninstalling mod " .. selectedMod .. "...", "#FFA500")
        end

        -- Request the server to take actions to help uninstalling the mod
        Ext.Net.PostMessageToServer("MU_Request_Server_Uninstall_Mod", Ext.Json.Stringify({
            modUUID = selectedModUUID,
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

local function clearModDataGroup(modDataGroup)
    if not modDataGroup then
        return
    end
    for _, child in ipairs(modDataGroup.Children or {}) do
        child:Destroy()
    end
end

local function renderTemplates(modDataGroup, selectedModUUID)
    local templates = ModsTemplates[selectedModUUID]
    if not templates or table.isEmpty(templates) then
        local templateText = modDataGroup:AddText(
            "This mod does not have any items (templates) to remove.")
        templateText:SetColor("Text", VCHelpers.Color:hex_to_rgba("#00FF00"))
        return false
    end

    local templateText = modDataGroup:AddText(
        "These items will be deleted from your save if you click the 'Uninstall' button:")
    templateText:SetColor("Text", VCHelpers.Color:hex_to_rgba("#FF2525"))
    templateText.IDContext = "TemplateText" .. selectedModUUID

    local templateCollapsing = modDataGroup:AddCollapsingHeader("Templates (weapons, armor, etc.)")
    templateCollapsing.IDContext = "TemplatesCollapsing" .. selectedModUUID
    templateCollapsing.DefaultOpen = true

    for _, template in ipairs(templates) do
        createItemInfoTable(templateCollapsing,
            template.Icon or "",
            template.Rarity,
            template.DisplayName or template.Name or "<Name>",
            template.Stats or "<StatName>",
            template.Description or "No description provided.")
    end

    return true
end

local function getStatTypeText(entryType)
    local texts = {
        StatusData = "These statuses will be removed from all entities in your save if you click the 'Uninstall' button:",
        SpellData = "These spells will be removed from all entities if you click the 'Uninstall' button:",
        PassiveData = "These passives will be removed from all entities if you click the 'Uninstall' button:"
    }
    return texts[entryType] or "These stats will be removed from all entities if you click the 'Uninstall' button:"
end

local function renderStatEntries(modDataGroup, selectedModUUID)
    local stats = ModsStats[selectedModUUID]
    MUDebug(1, "Stats for mod " .. selectedModUUID .. ":")
    MUDebug(1, stats)
    modDataGroup:AddDummy(0, 5)
    if not stats or table.isEmpty(stats) then
        local statText = modDataGroup:AddText(
            "This mod does not have any stats (statuses, spells, passives) to remove.")
        statText:SetColor("Text", VCHelpers.Color:hex_to_rgba("#00FF00"))
        return false
    end

    for entryType, statEntries in pairs(stats.Entries) do
        local statText = modDataGroup:AddText(getStatTypeText(entryType))
        statText:SetColor("Text", VCHelpers.Color:hex_to_rgba("#FF2525"))
        statText.IDContext = "StatText" .. selectedModUUID

        local statCollapsing = modDataGroup:AddCollapsingHeader(entryType)
        statCollapsing.DefaultOpen = true
        statCollapsing.IDContext = entryType .. "StatCollapsing" .. selectedModUUID

        for _, statEntry in ipairs(statEntries) do
            local stat = Ext.Stats.Get(statEntry)
            createItemInfoTable(statCollapsing,
                stat.Icon or "",
                nil, -- rarity (not applicable for stats)
                Ext.Loca.GetTranslatedString(stat.DisplayName) or stat.Name or "<Name>",
                stat.Name or "<StatName>",
                Ext.Loca.GetTranslatedString(stat.Description) or "No description provided.")
        end
    end
    
    return true
end

local localTabHeader, parseGroup

local function handleComboBoxChange(value, modDataGroup, modsToUninstallOptions, uninstallButton)
    -- Check if the selected option is the placeholder and do nothing if it is
    if value.SelectedIndex == 0 then
        if uninstallButton then
            uninstallButton.Visible = false
        end
        return
    end

    local selectedMod = modsToUninstallOptions[value.SelectedIndex + 1]
    local selectedModUUID = UIHelpers:GetModToUninstallUUID(selectedMod)

    -- Create the uninstall button if it doesn't exist
    if not uninstallButton then
        uninstallButton = createUninstallButton(modDataGroup, modsToUninstallOptions, value)
    else
        uninstallButton.Visible = true
    end

    local renderedTemplates = renderTemplates(modDataGroup, selectedModUUID)
    local renderedStats = renderStatEntries(modDataGroup, selectedModUUID)

    if not renderedTemplates and not renderedStats then
        local noEntriesText = modDataGroup:AddText(
            "This mod does not have any items or stats to remove.")
        uninstallButton.Visible = false
    end
end

local function createModDataGroup(tabHeader, modsComboBox, modsToUninstallOptions)
    -- Group that will contain the templates elements for the selected mod; useful for destroying the elements when changing the selected mod
    local modDataGroup = tabHeader:AddGroup("Templates")
    modDataGroup.IDContext = "ModDataGroup"

    -- Handle the change event for the combo box, which will display the templates for the selected mod
    local uninstallButton = nil
    modsComboBox.OnChange = function(value)
        -- First, destroy all the children of the modDataGroup before rendering new ones
        clearModDataGroup(modDataGroup)
        handleComboBoxChange(value, modDataGroup, modsToUninstallOptions, uninstallButton)
    end

    return modDataGroup
end

local function loadTemplates(tabHeader)
    if not UI.HasLoadedTemplates then
        VanillaTemplates, ModsTemplates = GetVanillaAndModsTemplates()
        ModsStats = GetStatsEntriesByMod({ "StatusData", "SpellData", "PassiveData" })
        -- Needed cause some load orders might be too big to send via net messages
        Ext.Net.PostMessageToServer("MU_Server_Should_Load_Templates", "")

        UI.HasLoadedTemplates = true

        local modsToUninstallOptions = UIHelpers:PopulateModsToUninstallOptions()
        if #modsToUninstallOptions == 0 then
            local noModsToUninstallMsg =
                "No mods available to uninstall.\nIf you believe this is an error, please provide your SE console log to " ..
                Ext.Mod.GetMod(ModuleUUID).Info.Author .. "."
            local noModsLabel = parseGroup:AddText(
                noModsToUninstallMsg)
            noModsLabel.IDContext = "NoModsLabel"
            MUWarn(0,
                noModsToUninstallMsg)
            UI.HasTemplates = false
        else
            UI.HasTemplates = true
            local modsToUninstallOptionsDump = Ext.DumpExport(modsToUninstallOptions)
            MUDebug(1, modsToUninstallOptionsDump)
            UIHelpers:SortModUUIDTableByModName(modsToUninstallOptions)

            local uninstallSeparator = createModsToUninstallSeparator(tabHeader)
            local modsToUninstallLabel = createModsToUninstallLabel(tabHeader)

            local modsComboBox = createModsComboBox(tabHeader, modsToUninstallOptions)
            local modDataGroup = createModDataGroup(tabHeader, modsComboBox, modsToUninstallOptions)
            if parseGroup then
                parseGroup:Destroy()
            end
        end
    elseif UI.HasTemplates then
        local alreadyLoadedLabel = parseGroup:AddText(
            "Templates have already been loaded. You may select a mod to uninstall.")
        alreadyLoadedLabel.IDContext = "AlreadyLoadedLabel"
        MUSuccess(0, "Templates have already been loaded. You may select a mod to uninstall.")
    end
end

local function createLoadTemplatesButton(tabHeader, modsToUninstallOptions)
    parseGroup = tabHeader:AddGroup("Parse mod data")
    parseGroup.IDContext = "LoadModDataGroup"
    local buttonSeparator = parseGroup:AddSeparatorText("REQUIRED: Load data from mods")
    buttonSeparator.IDContext = "LoadTemplatesSeparator"
    local buttonLabel = parseGroup:AddText(
        "For performance reasons, mod data is only parsed after clicking this button:")
    buttonLabel.IDContext = "LoadTemplatesLabel"
    local parseButton = parseGroup:AddButton("Parse mod data")
    parseButton.IDContext = "LoadTemplatesButton"

    parseButton.OnClick = function()
        loadTemplates(tabHeader)
    end
end

Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Features", function(tabHeader)
    localTabHeader = tabHeader
    createLoadTemplatesButton(localTabHeader, nil)
end)

Ext.RegisterNetListener("MCM_Mod_Tab_Activated", function(channel, payload)
    local data = Ext.Json.Parse(payload)
    _D(data)
    if data.modGUID == ModuleUUID and not UI.HasLoadedTemplates then
        loadTemplates(localTabHeader)
    end
end)

return UI
