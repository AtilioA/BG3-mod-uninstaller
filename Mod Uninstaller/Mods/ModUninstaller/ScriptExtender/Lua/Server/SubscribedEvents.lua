Ext.RegisterNetListener("MU_Request_Server_Uninstall_Mod", function(channel, payload)
    local data = Ext.Json.Parse(payload)
    local uuid = data.modUUID
    local mod = Ext.Mod.GetMod(uuid)
    if not Ext.Mod.IsModLoaded(uuid) then
        Ext.Net.BroadcastMessage("MU_Uninstall_Mod_Failed",
            Ext.Json.Stringify({ modUUID = data.modUUID, error = "Mod is not loaded" }))
        return
    end
    local modTemplates = data.modTemplates

    local success, err = xpcall(function()
        if MCMGet("delete_items") then
            MUWarn(0, "Deleting " .. #modTemplates .. " item templates from mod " .. mod.Info.Name)
            DeleteTemplatesForMod(modTemplates)
            MUSuccess(0, "Deleted all item templates from mod " .. mod.Info.Name)
        end
        if MCMGet("remove_statuses") then
            MUWarn(0, "Removing statuses from mod " .. mod.Info.Name)
            RemoveStatusesFromMod(uuid)
        end
    end, debug.traceback)

    if success then
        Ext.Net.BroadcastMessage("MU_Uninstalled_Mod", Ext.Json.Stringify({ modUUID = data.modUUID }))
    else
        Ext.Net.BroadcastMessage("MU_Uninstall_Mod_Failed", Ext.Json.Stringify({ modUUID = data.modUUID, error = err }))
    end
end)
