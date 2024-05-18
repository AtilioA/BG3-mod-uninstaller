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

    local function assignTemplatesToMods()
        local modIds = getModIdsTable()
        local moddedTemplates = getAllModdedTemplates()
        for _, templateData in pairs(moddedTemplates) do
            for modId, _ in pairs(modIds) do
                local mod = Ext.Mod.GetMod(modId)
                if mod and string.find(templateData.FileName, mod.Info.Directory) then
                    table.insert(modIds[modId], templateData.Name)
                end
            end
        end

        return modIds
    end

    return assignTemplatesToMods()
end
