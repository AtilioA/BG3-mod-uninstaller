-- local function isVanilla(name)
--     local vanillaMods = {
--         "Gustav",
--         "GustavDev",
--         "Shared",
--         "SharedDev",
--         "Honour"
--     }
--     for _, mod in pairs(vanillaMods) do
--         if string.find(name, mod) then
--             return true
--         end
--     end
--     return false
-- end

-- function VCHelpers.Template:GetTemplatesByMod()
--     local templates = Ext.Template.GetAllRootTemplates()

--     local templatesByMod = {}
--     for templateId, templateData in pairs(templates) do
--         if templateData.TemplateType ~= 'item' then
--             goto continue
--         end

--         local templateStats = Ext.Stats.Get(templateData.Stats)
--         if isVanillaFilename(templateData.FileName) or not templateStats then
--             goto continue
--         end

--         local modId = templateStats.ModId
--         -- _D(templateData)
--         _P(templateData.Stats, modId)
--         if not modId or isVanilla(modId) then
--             goto continue
--         end

--         local mod = Ext.Mod.GetMod(modId)
--         -- if mod then
--         -- _P(templateData.Name, mod.Info.Name)
--         -- end


--         local modInfo = Ext.Mod.GetMod(modId)
--         if modInfo and modInfo.Info.Name then
--             if not templatesByMod[modInfo.Info.Name] then
--                 templatesByMod[modInfo.Info.Name] = {}
--             end
--             table.insert(templatesByMod[modInfo.Info.Name], {
--                 TemplateId = templateId,
--                 TemplateName = templateData.Name,
--                 DisplayName = VCHelpers.Loca:GetTranslatedStringFromTemplateUUID(templateId)
--             })
--         end

--         ::continue::
--     end
--     return templatesByMod
-- end

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

local function getModsTemplates()
    local function getModDirectoriesTable()
        local loadOrder = Ext.Mod.GetLoadOrder()
        local modDirectories = {}
        for _, modId in pairs(loadOrder) do
            local mod = Ext.Mod.GetMod(modId)
            if mod then
                modDirectories[mod.Info.Directory] = {}
            end
        end
        return modDirectories
    end

    local function assignTemplatesToMods()
        local modDirectories = getModDirectoriesTable()
        local moddedTemplates = getAllModdedTemplates()
        for _, templateData in pairs(moddedTemplates) do
            for directory, _ in pairs(modDirectories) do
                if string.find(templateData.FileName, directory) then
                    table.insert(modDirectories[directory], templateData.Name)
                end
            end
        end
        _D(modDirectories)
    end

    assignTemplatesToMods()
end

getModsTemplates()
