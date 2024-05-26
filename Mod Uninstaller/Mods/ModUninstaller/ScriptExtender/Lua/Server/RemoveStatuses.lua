function RemoveStatusesFromEntities(statuses)
    local entities = Ext.Entity.GetAllEntitiesWithUuid()
    for Guid, entityHandle in pairs(entities) do
        for _, status in ipairs(statuses) do
            MUWarn(1, "Removing status " .. status .. " from entity " .. Guid)
            Osi.RemoveStatus(Guid, status)
        end
    end
end

function RemoveStatusesFromMod(modGuid)
    local statuses = GetStatusesFromMod(modGuid)
    if #statuses == 0 then
        MUSuccess(0, "Mod " .. Ext.Mod.GetMod(modGuid).Info.Name .. " has no statuses")
        return
    end

    MUWarn(0, "Removing " .. #statuses .. " statuses from all entities for mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
    RemoveStatusesFromEntities(statuses)
    MUSuccess(0, "Removed all statuses from all entities for mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
end

Ext.RegisterConsoleCommand("MU_Remove_Statuses", function(cmd, modGuid)
    if not modGuid or not Ext.Mod.IsModLoaded(modGuid) then
        MUWarn(0, "Usage: !" .. cmd .. " <modGuid>")
        return
    end

    VanillaTemplates, ModsTemplates = GetVanillaAndModsTemplates()

    RemoveStatusesFromMod(modGuid)
end)
