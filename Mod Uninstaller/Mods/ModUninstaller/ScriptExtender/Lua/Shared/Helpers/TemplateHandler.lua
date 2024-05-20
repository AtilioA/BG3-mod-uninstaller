local function getAllModdedTemplates()
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
        return false
    end

    local templates = Ext.Template.GetAllRootTemplates()

    local moddedTemplates = {}
    for templateId, templateData in pairs(templates) do
        if templateData.TemplateType == 'item' and not isVanillaFilename(templateData.FileName) then
            table.insert(moddedTemplates, templateData)
        end
    end

    return moddedTemplates
end

function GetModsTemplates()
    local function getModIdsTable()
        local loadOrder = Ext.Mod.GetLoadOrder()
        local modIds = {}
        for _, modId in pairs(loadOrder) do
            local mod = Ext.Mod.GetMod(modId)
            if mod then
                modIds[modId] = {}
            end
        end
        return modIds
    end

    local function addTemplateToMod(modIds, templateData)
        for modId, _ in pairs(modIds) do
            local mod = Ext.Mod.GetMod(modId)
            if mod and string.find(templateData.FileName, mod.Info.Directory) then
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

    local function assignTemplatesToMods()
        local modIds = getModIdsTable()
        local moddedTemplates = getAllModdedTemplates()
        for _, templateData in pairs(moddedTemplates) do
            addTemplateToMod(modIds, templateData)
        end
        return modIds
    end

    return assignTemplatesToMods()
end
