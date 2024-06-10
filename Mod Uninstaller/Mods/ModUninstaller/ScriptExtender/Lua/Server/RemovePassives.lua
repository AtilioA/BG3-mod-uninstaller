-- TODO: understand how to remove passives from all entities

function RemovePassivesFromEntities(passives)
    local entities = Ext.Entity.GetAllEntitiesWithUuid()
    for Guid, entityHandle in pairs(entities) do
        MUWarn(2, "Removing passives from entity " .. Guid)
        for _, passive in ipairs(passives) do
            MUWarn(3, "Removing passive " .. passive .. " from entity " .. Guid)
            Osi.RemovePassive(Guid, passive)
        end
    end
end

function RemovePassivesForMod(modGuid)
    local passives = GetPassivesFromMod(modGuid)

    if not passives or table.isEmpty(passives) then
        MUSuccess(0, "Mod " .. Ext.Mod.GetMod(modGuid).Info.Name .. " has no passives")
        return
    end

    -- TODO: get vanilla passives
    -- Filter out vanilla passives?
    local modPassives = {}
    for _, passive in ipairs(passives) do
        -- if VanillaPassives[passive] ~= true then
        MUWarn(1, "Queuing passive " .. passive .. " for removal from mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
        table.insert(modPassives, passive)
        -- else
        --     MUWarn(1, "Skipping vanilla passive " .. passive .. " from mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
        -- end
    end

    if #modPassives == 0 then
        MUSuccess(0, "Mod " .. Ext.Mod.GetMod(modGuid).Info.Name .. " has no passives")
        return
    end

    MUWarn(0, "Removing " .. #modPassives .. " passives from all entities for mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
    RemovePassivesFromEntities(modPassives)
    MUSuccess(0, "Removed all passives from all entities for mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
end

Ext.RegisterConsoleCommand("MU_Remove_Passives", function(cmd, modGuid)
    if not modGuid or not Ext.Mod.IsModLoaded(modGuid) then
        MUWarn(0, "Usage: !" .. cmd .. " <modGuid>")
        return
    end

    RemovePassivesForMod(modGuid)
end)
