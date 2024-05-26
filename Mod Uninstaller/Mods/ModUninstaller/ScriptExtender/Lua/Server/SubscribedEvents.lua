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
        -- if MCMGet("remove_statuses") then
        --     MUWarn(0, "Removing statuses from mod " .. mod.Info.Name)
        --     RemoveStatusesFromMod(uuid)
        -- end
        MUWarn(0,
            "Due to SE limitations, removing statuses has been temporarily disabled.\nTrack Mod Uninstaller on the Nexus to see when it will be re-enabled.")
    end, debug.traceback)

    if success then
        Osi.OpenMessageBox(Osi.GetHostCharacter(), "Mod '" ..
            mod.Info.Name ..
            "' was uninstalled successfully!\nYou may now disable it in your mod manager if it doesn't add statuses.")
        Ext.Net.BroadcastMessage("MU_Uninstalled_Mod", Ext.Json.Stringify({ modUUID = data.modUUID }))
    else
        Ext.Net.BroadcastMessage("MU_Uninstall_Mod_Failed", Ext.Json.Stringify({ modUUID = data.modUUID, error = err }))
    end
end)

Ext.RegisterNetListener("MU_Server_Should_Load_Templates", function(channel, payload)
    VanillaTemplates, ModsTemplates = GetVanillaAndModsTemplates()
end)

Ext.RegisterConsoleCommand("MU_Uninstall_Mod", function(cmd, modId)
    if not modId then
        MUWarn(0, "No mod ID provided.\nUsage: !" .. cmd .. " <modGuid>")

        return
    end

    local mod = Ext.Mod.GetMod(modId)
    if not mod then
        MUWarn(0, "Mod not found for mod ID: " .. modId)
        return
    end

    VanillaTemplates, ModsTemplates = GetVanillaAndModsTemplates()

    local modTemplates = ModsTemplates[modId]
    if not modTemplates then
        MUWarn(0, "No templates found for mod ID: " .. modId)
        return
    end

    if MCMGet("delete_items") then
        MUWarn(0, "Deleting " .. #modTemplates .. " item templates from mod " .. mod.Info.Name)
        DeleteTemplatesForMod(modTemplates)
        MUSuccess(0, "Deleted all item templates from mod " .. mod.Info.Name)
    end
    -- if MCMGet("remove_statuses") then
    --     MUWarn(0, "Removing statuses from mod " .. mod.Info.Name)
    --     RemoveStatusesFromMod(modId)
    -- end

    Osi.OpenMessageBox(Osi.GetHostCharacter(), "Mod '" ..
        mod.Info.Name ..
        "' was uninstalled successfully!\nYou may now disable it in your mod manager if it doesn't add statuses.")
end)
