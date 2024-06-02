local function isVanillaFilename(filename)
    local vanillaPaths = {
        "Public/Gustav",
        "Public/GustavDev",
        "Public/Shared",
        "Public/SharedDev",
        "Mods/Gustav",
        "Mods/GustavDev",
        "Mods/Shared",
        "Mods/SharedDev",
        "Public/Honour",
        "Mods/Honour"
    }

    for _, path in pairs(vanillaPaths) do
        if string.find(filename, path) then
            return true
        end
    end

    MUDebug(3, "Filename does not match any vanilla paths")
    return false
end

local function isVanillaID(id)
    return VanillaTemplatesIDs[id] == true
end

local function getAllVanillaTemplates()
    local templates = Ext.Template.GetAllRootTemplates()

    local vanillaTemplates = {}
    for templateId, templateData in pairs(templates) do
        if templateData.TemplateType == 'item' and isVanillaFilename(templateData.FileName) then
            table.insert(vanillaTemplates, templateData)
        end
    end

    return vanillaTemplates
end


local function getAllVanillaAndModdedTemplates()
    local templates = Ext.Template.GetAllRootTemplates()

    local vanillaTemplates = {}
    local moddedTemplates = {}
    for templateId, templateData in pairs(templates) do
        if templateData.TemplateType == 'item' then
            if isVanillaFilename(templateData.FileName) or isVanillaID(templateData.Id) then
                table.insert(vanillaTemplates, templateData)
            else
                table.insert(moddedTemplates, templateData)
            end
        end
    end

    return vanillaTemplates, moddedTemplates
end

local function formatTemplateData(vanillaTemplates)
    MUDebug(1, "Formatting template data")
    local formattedTemplateData = {}
    for _, templateData in pairs(vanillaTemplates) do
        formattedTemplateData[templateData.Id] = {
            Name = templateData.Name,
            DisplayName = VCHelpers.Loca:GetTranslatedStringFromTemplateUUID(templateData.Id),
            Description = Ext.Loca.GetTranslatedString(templateData.TechnicalDescription.Handle.Handle),
            Stats = templateData.Stats,
            Icon = templateData.Icon,
        }
    end
    return formattedTemplateData
end


function GetVanillaAndModsTemplates()
    local function getModIdsTable()
        MUPrint(1, "Fetching mod load order")
        local loadOrder = Ext.Mod.GetLoadOrder()
        local modIds = {}
        for _, modId in pairs(loadOrder) do
            local mod = Ext.Mod.GetMod(modId)
            if mod then
                MUPrint(2, "Adding mod to modIds table: " .. modId .. " (" .. mod.Info.Name .. ")")
                modIds[modId] = {}
            else
                MUWarn(2, "Mod not found for modId: " .. modId)
            end
        end
        return modIds
    end

    local function addTemplateToMod(modIds, templateData)
        for modId, _ in pairs(modIds) do
            local mod = Ext.Mod.GetMod(modId)
            MUDebug(3,
                "Checking if template " ..
                templateData.FileName .. " matches mod " .. modId .. " (" .. mod.Info.Name .. ")")
            if mod and string.find(templateData.FileName, mod.Info.Directory) then
                MUPrint(2,
                    "Template matches mod directory: " ..
                    modId .. "(" .. mod.Info.Name .. ") in " .. templateData.FileName)
                table.insert(modIds[modId], {
                    Id = templateData.Id,
                    Name = templateData.Name,
                    DisplayName = VCHelpers.Loca:GetTranslatedStringFromTemplateUUID(templateData.Id),
                    Description = Ext.Loca.GetTranslatedString(templateData.TechnicalDescription.Handle.Handle),
                    Stats = templateData.Stats,
                    Icon = templateData.Icon,
                })
            end
        end
    end

    local function assignTemplatesToMods(moddedTemplates)
        MUPrint(1, "Assigning templates to mods")
        local modIds = getModIdsTable()
        for _, templateData in pairs(moddedTemplates) do
            addTemplateToMod(modIds, templateData)
        end
        return modIds
    end

    MUPrint(1, "Getting all vanilla and modded templates")
    local vanillaTemplates, moddedTemplates = getAllVanillaAndModdedTemplates()

    MUPrint(1, "Formatting and assigning templates")
    return formatTemplateData(vanillaTemplates), assignTemplatesToMods(moddedTemplates)
end

local function dumpAllVanillaTemplates()
    local vanillaTemplates = getAllVanillaTemplates()
    local vanillaTemplateTable = {}
    for _, templateData in pairs(vanillaTemplates) do
        table.insert(vanillaTemplateTable, templateData.Id)
    end
    Ext.IO.SaveFile("VanillaTemplates.json", Ext.DumpExport(vanillaTemplateTable))
end

Ext.RegisterConsoleCommand("MU_DVT", function(cmd) dumpAllVanillaTemplates() end)
