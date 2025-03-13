function RemoveStatusesFromEntities(statuses)
    local entities = Ext.Entity.GetAllEntitiesWithUuid()
    for Guid, entityHandle in pairs(entities) do
        for _, status in ipairs(statuses) do
            MUWarn(3, "Removing status " .. status .. " from entity " .. Guid)
            Osi.RemoveStatus(Guid, status)
        end
    end
end

function RemoveStatusesForMod(modGuid)
    local statuses = GetStatusesFromMod(modGuid)

    if not statuses or table.isEmpty(statuses) then
        MUSuccess(0, "Mod " .. Ext.Mod.GetMod(modGuid).Info.Name .. " has no statuses")
        return
    end

    -- Filter out vanilla statuses
    local modStatuses = {}
    for _, status in ipairs(statuses) do
        if VanillaStatuses[status] ~= true then
            MUWarn(1, "Queuing status " .. status .. " for removal from mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
            table.insert(modStatuses, status)
        else
            MUWarn(1, "Skipping vanilla status " .. status .. " from mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
        end
    end

    if #modStatuses == 0 then
        MUSuccess(0, "Mod " .. Ext.Mod.GetMod(modGuid).Info.Name .. " has no statuses")
        return
    end

    MUWarn(0, "Removing " .. #modStatuses .. " statuses from all entities for mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
    RemoveStatusesFromEntities(modStatuses)
    MUSuccess(0, "Removed all statuses from all entities for mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
end

Ext.RegisterConsoleCommand("MU_Remove_Statuses", function(cmd, modGuid)
    if not modGuid or not Ext.Mod.IsModLoaded(modGuid) then
        MUWarn(0, "Usage: !" .. cmd .. " <modGuid>")
        return
    end

    VanillaTemplates, ModsTemplates = GetVanillaAndModsTemplates()
    ModsStats = GetStatsEntriesByMod({ "StatusData", "SpellData", "PassiveData" })

    RemoveStatusesForMod(modGuid)
end)
