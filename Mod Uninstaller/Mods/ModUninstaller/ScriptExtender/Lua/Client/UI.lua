UI = {}
UI.HasLoadedTemplates = false

local comboBox
local loadingText

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
    local separator = tabHeader:AddSeparatorText(Ext.Loca.GetTranslatedString("h5f216c4172094376a5eec94db07ee93ea56d"))
    separator.IDContext = "ModsToUninstall"
    return separator
end

local function createModsToUninstallLabel(tabHeader)
    local label = tabHeader:AddText(Ext.Loca.GetTranslatedString("hc6dae92ec2604cd097e5e6e26ac9ddb8921d"))
    label.IDContext = "ModsToUninstallLabel"
    label.SameLine = false
    return label
end

local function createModsToUninstallDisclaimer(IMGUIElement)
    local comboTooltip = IMGUIElement:Tooltip()
    local modListDisclaimer = comboTooltip:AddText(UIHelpers:ReplaceBrWithNewlines(Ext.Loca.GetTranslatedString(
        "hb94283896cc041b1a1cdaa0dba833fd5a026")))
    modListDisclaimer.IDContext = "ModsToUninstallDisclaimer"
    modListDisclaimer.SameLine = false
end

local function createModsComboBox(tabHeader, modsToUninstallOptions)
    -- Insert placeholder at the beginning of the options
    table.insert(modsToUninstallOptions, 1, Ext.Loca.GetTranslatedString("hd1c4fca19088449c9f3b63396070802e7213"))

    comboBox = tabHeader:AddCombo("")
    createModsToUninstallDisclaimer(comboBox)

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
    xpcall(function()
        if progressLabel then
            progressLabel.Label = message
            progressLabel:SetColor("Text", VCHelpers.Color:hex_to_rgba(color))
        end
    end, function(err)
        -- except pass lmao (this is a hack cause IMGUI is dumb, the label actually exists)
    end)
end


---Update the progress label based on the server response
---@param progressLabel table|nil The progress label to update
---@param data table The parsed JSON data from the server
---@param modName string The name of the mod
local function updateProgressLabelBasedOnResponse(progressLabel, data, modName)
    if data.error then
        updateProgressLabel(progressLabel, "Failed to uninstall mod '" .. modName .. "': " .. data.error, "#FF0000")
    else
        updateProgressLabel(progressLabel, "Successfully uninstalled mod '" .. modName .. "'!", "#00FF00")
    end
end

---Update the modsToUninstallOptions to mark the mod as uninstalled
---@param uninstalledModUUID string The name of the mod that was uninstalled
---@param error string|nil The error message if any
local function updateModsToUninstallOptions(uninstalledModUUID, error)
    if error then
        return
    end

    for i, option in ipairs(comboBox.Options) do
        local optionUUID = UIHelpers:GetModToUninstallUUID(option)
        -- I just want to release this, ok?
        if optionUUID and uninstalledModUUID == optionUUID and not option:find("%(UNINSTALLED%)") then
            comboBox.Options[i] = "(UNINSTALLED) " .. option

            if not comboBox.UserData then
                comboBox.UserData = {}
            end
            comboBox.UserData["Uninstalled"] = comboBox.UserData["Uninstalled"] or {}
            comboBox.UserData["Uninstalled"][optionUUID] = true
            break
        end
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
    local modUUID = mod.Info.ModuleUUID
    updateProgressLabelBasedOnResponse(progressLabel, data, modName)
    updateModsToUninstallOptions(modUUID, data.error)
end

local function createUninstallButton(tabHeader, modsToUninstallOptions, modsComboBox)
    local button = tabHeader:AddButton("", "") -- Initialize with empty strings
    button:SetColor("Text", VCHelpers.Color:hex_to_rgba("#FFFFFF"))
    button:SetColor("Button", VCHelpers.Color:hex_to_rgba("#B21919"))
    button.IDContext = "UninstallButton"

    local progressLabel = tabHeader:AddText("")
    progressLabel.IDContext = "UninstallProgressLabel"
    progressLabel.SameLine = false

    local function updateButtonLabel()
        local selectedMod = modsToUninstallOptions[modsComboBox.SelectedIndex + 1]
        local uninstallText = Ext.Loca.GetTranslatedString("ha2482b4c47ce4044bf3acd25a08a1401fbd6")
        if selectedMod == Ext.Loca.GetTranslatedString("hd1c4fca19088449c9f3b63396070802e7213") then
            button.Label = uninstallText
        else
            local selectedModUUID = UIHelpers:GetModToUninstallUUID(selectedMod)
            if selectedModUUID then
                local mod = Ext.Mod.GetMod(selectedModUUID)
                if mod and mod.Info and mod.Info.Name then
                    button.Label = string.format("%s '%s'", uninstallText, mod.Info.Name)
                else
                    button.Label = uninstallText
                end
            else
                button.Label = uninstallText
            end
        end
    end

    -- Initial update (to set the button label to the placeholder text)
    updateButtonLabel()

    button.OnClick = function()
        local selectedMod = modsToUninstallOptions[modsComboBox.SelectedIndex + 1]
        if selectedMod == Ext.Loca.GetTranslatedString("hd1c4fca19088449c9f3b63396070802e7213") then
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
        xpcall(function()
            if button then
                button.Visible = false
            end
            if progressLabel then
                progressLabel.SameLine = false
            end
        end, function(err)
            -- except pass lmao (this is a hack cause IMGUI is dumb, the button actually exists)
        end)
        handleUninstallResponse(progressLabel, payload, modsComboBox)
    end)

    Ext.RegisterNetListener("MU_Uninstall_Mod_Failed", function(channel, payload)
        if button then
            button.Visible = true
        end
        if progressLabel then
            progressLabel.SameLine = true
        end
        handleUninstallResponse(progressLabel, payload, modsComboBox)
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
            Ext.Loca.GetTranslatedString("hb0be1d2d0151411c9707bce520dd319fc0g1"))
        templateText:SetColor("Text", VCHelpers.Color:hex_to_rgba("#00FF00"))
        return false
    end

    local templateText = modDataGroup:AddText(
        Ext.Loca.GetTranslatedString("ha7a78a2aa8244ae882559699c1e9e2febffd"))
    templateText:SetColor("Text", VCHelpers.Color:hex_to_rgba("#FF2525"))
    templateText.IDContext = "TemplateText" .. selectedModUUID

    local templateCollapsing = modDataGroup:AddCollapsingHeader(Ext.Loca.GetTranslatedString(
        "h311204758fa4422395e190b764354040g23b"))
    templateCollapsing.IDContext = "TemplatesCollapsing" .. selectedModUUID
    templateCollapsing.DefaultOpen = true

    for _, template in ipairs(templates) do
        createItemInfoTable(templateCollapsing,
            template.Icon or "",
            template.Rarity,
            template.DisplayName or template.Name or "<Name>",
            template.Stats or "<StatName>",
            template.Description or Ext.Loca.GetTranslatedString("h11d60dd3992446e8ba94662af4dbef3a0036"))
    end

    return true
end

local function getStatTypeText(entryType)
    local texts = {
        StatusData = Ext.Loca.GetTranslatedString("h75a77c7fd500445b8ed105b43a2eafe58e98"),
        SpellData = Ext.Loca.GetTranslatedString("ha7af21bff6354ed6a9370c35804785afff6a"),
        PassiveData = Ext.Loca.GetTranslatedString("hdc09f83707854627afe4f861f4a6a95c2g38")
    }
    return texts[entryType] or Ext.Loca.GetTranslatedString("ha39ba2327d8f44f08efbfb6b762009990f80")
end

local function renderStatEntries(modDataGroup, selectedModUUID)
    local stats = ModsStats[selectedModUUID]
    MUDebug(1, "Stats for mod " .. selectedModUUID .. ":")
    MUDebug(1, stats)
    modDataGroup:AddDummy(0, 5)
    if not stats or table.isEmpty(stats) then
        local statText = modDataGroup:AddText(
            Ext.Loca.GetTranslatedString("h5141a574bfeb4a058691f0e1f86ccb43ebff"))
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
                Ext.Loca.GetTranslatedString(stat.Description) or
                Ext.Loca.GetTranslatedString("h11d60dd3992446e8ba94662af4dbef3a0036"))
        end
    end

    return true
end

local localTabHeader, parseGroup

local function handleComboBoxChange(modsComboBox, value, modDataGroup, modsToUninstallOptions, uninstallButton)
    local function removePlaceholder(options, comboBox)
        if options[1] == Ext.Loca.GetTranslatedString("hd1c4fca19088449c9f3b63396070802e7213") then
            table.remove(options, 1)
            comboBox.Options = options
            return true
        end
    end

    -- Check if the selected option is the placeholder and do nothing if it is
    if value.SelectedIndex == 0 and modsToUninstallOptions[1] == Ext.Loca.GetTranslatedString("hd1c4fca19088449c9f3b63396070802e7213") then
        if uninstallButton then
            uninstallButton.Visible = false
        end
        return
    else
        if removePlaceholder(modsToUninstallOptions, modsComboBox) then
            value.SelectedIndex = value.SelectedIndex - 1
        end
    end

    local selectedMod = modsToUninstallOptions[value.SelectedIndex + 1]
    local selectedModUUID = UIHelpers:GetModToUninstallUUID(selectedMod)

    -- Create the uninstall button if it doesn't exist
    if not uninstallButton then
        uninstallButton = createUninstallButton(modDataGroup, modsToUninstallOptions, value)
    else
        uninstallButton.Visible = true
    end

    -- Make uninstallButton not visible if mod is already uninstalled
    if modsComboBox and modsComboBox.UserData and modsComboBox.UserData["Uninstalled"] and selectedModUUID and modsComboBox.UserData["Uninstalled"][selectedModUUID] then
        uninstallButton.Visible = false
        local alreadyUninstalledText = modDataGroup:AddText(Ext.Loca.GetTranslatedString(
            "h2d2b7288bbe147dd891a4af46a99b881aefb"))
        alreadyUninstalledText:SetColor("Text", VCHelpers.Color:hex_to_rgba("#00DD00"))
        modDataGroup:AddDummy(0, 10)
    end

    local resultsSeparator = modDataGroup:AddSeparator()
    resultsSeparator:SetColor("Separator", VCHelpers.Color:hex_to_rgba("#808080"))

    local renderedTemplates = renderTemplates(modDataGroup, selectedModUUID)
    local renderedStats = renderStatEntries(modDataGroup, selectedModUUID)

    if not renderedTemplates and not renderedStats then
        local noEntriesText = modDataGroup:AddText(
            UIHelpers:ReplaceBrWithNewlines(Ext.Loca.GetTranslatedString("h657bb402f5f1479abcac2c774eba5bf15633")))
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
        handleComboBoxChange(modsComboBox, value, modDataGroup, modsToUninstallOptions, uninstallButton)
    end

    return modDataGroup
end

local function loadTemplates(tabHeader)
    local function handleException(err)
        if tabHeader then
            local errorText = tabHeader:AddText("Error occurred in loadTemplates function:\n" .. err)
            errorText:SetColor("Text", VCHelpers.Color:hex_to_rgba("#FF2525"))
        else
            MUWarn(0, "Error occurred in loadTemplates function: " .. err)
        end
    end

    xpcall(function()
        if not UI.HasLoadedTemplates then
            local function getTemplatesAndStats()
                VanillaTemplates, ModsTemplates = GetVanillaAndModsTemplates()
                ModsStats = GetStatsEntriesByMod({ "StatusData", "SpellData", "PassiveData" })
                -- Needed cause some load orders might be too big to send via net messages
                Ext.Net.PostMessageToServer("MU_Server_Should_Load_Templates", "")
            end

            xpcall(getTemplatesAndStats, handleException)

            UI.HasLoadedTemplates = true
            if loadingText then
                loadingText.Visible = false
            end

            local function populateModsToUninstallOptions()
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
                return modsToUninstallOptions
            end

            xpcall(populateModsToUninstallOptions, handleException)
        elseif UI.HasTemplates then
            local alreadyLoadedLabel = parseGroup:AddText(
                Ext.Loca.GetTranslatedString("h60a7d03ee73b4af1845608fec9147d15610e"))
            alreadyLoadedLabel.IDContext = "AlreadyLoadedLabel"
            MUSuccess(0, "Templates have already been loaded. You may select a mod to uninstall.")
        end
    end, handleException)
end

local function loadTemplatesWithMessage(tabHeader)
    loadingText = parseGroup:AddText(Ext.Loca.GetTranslatedString("h444ecd5201e246eab95edf6541363fd338e5"))
    loadingText:SetColor("Text", VCHelpers.Color:hex_to_rgba("#ADD8E6"))

    -- Add a small delay so the loading text is displayed before processing starts
    VCHelpers.Timer:OnTicks(2, function()
        loadTemplates(tabHeader)
    end)
end

local function createLoadTemplatesButton(tabHeader)
    parseGroup = tabHeader:AddGroup(Ext.Loca.GetTranslatedString("h5872505ffa094434bf65b4b17b94e8bcg1d1"))
    parseGroup.IDContext = "LoadModDataGroup"
    local buttonSeparator = parseGroup:AddSeparatorText(Ext.Loca.GetTranslatedString(
        "h72312e32006341e69d760806936bbfff5121"))
    buttonSeparator.IDContext = "LoadTemplatesSeparator"
    local buttonLabel = parseGroup:AddText(
        Ext.Loca.GetTranslatedString("h58685c08a5d4413b916ac83e1cd96c2719c4")
    )
    buttonLabel.IDContext = "LoadTemplatesLabel"
    local parseButton = parseGroup:AddButton(Ext.Loca.GetTranslatedString("h5872505ffa094434bf65b4b17b94e8bcg1d1"))
    parseButton.IDContext = "LoadTemplatesButton"

    parseButton.OnClick = function()
        loadTemplatesWithMessage(tabHeader)
    end
end

Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Features", function(tabHeader)
    localTabHeader = tabHeader
    createLoadTemplatesButton(localTabHeader)
end)

Ext.ModEvents.BG3MCM["MCM_Mod_Tab_Activated"]:Subscribe(function(eventData)
    if eventData.modUUID == ModuleUUID and not UI.HasLoadedTemplates then
        loadTemplatesWithMessage(localTabHeader)
    end
end)

return UI
