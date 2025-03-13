Ext.RegisterNetListener("MU_Request_Server_Uninstall_Mod", function(channel, payload)
    local data = Ext.Json.Parse(payload)
    local uuid = data.modUUID
    local mod = Ext.Mod.GetMod(uuid)
    if not Ext.Mod.IsModLoaded(uuid) then
        Ext.Net.BroadcastMessage("MU_Uninstall_Mod_Failed",
            Ext.Json.Stringify({ modUUID = data.modUUID, error = "Mod is not loaded" }))
        return
    end

    UninstallMod(uuid)
end)

function UninstallMod(modUUID)
    local mod = Ext.Mod.GetMod(modUUID)
    if not Ext.Mod.IsModLoaded(modUUID) then
        Ext.Net.BroadcastMessage("MU_Uninstall_Mod_Failed",
            Ext.Json.Stringify({ modUUID = modUUID, error = "Mod is not loaded" }))
        return
    end

    local success, err = xpcall(function()
        if MCM.Get("delete_items") then
            MUWarn(0, "Deleting " .. #ModsTemplates[modUUID] .. " item templates from mod " .. mod.Info.Name)
            DeleteTemplatesForMod(modUUID)
            MUSuccess(0, "Deleted all item templates from mod " .. mod.Info.Name)
        end
        if MCM.Get("remove_stats") then
            MUWarn(0, "Removing statuses from mod " .. mod.Info.Name)
            RemoveStatusesForMod(modUUID)
            MUWarn(0, "Removing spells from mod " .. mod.Info.Name)
            RemoveSpellsForMod(modUUID)
            MUWarn(0, "Removing passives from mod " .. mod.Info.Name)
            RemovePassivesForMod(modUUID)
        end
    end, debug.traceback)

    if success then
        Osi.OpenMessageBox(Osi.GetHostCharacter(), "Mod '" ..
            mod.Info.Name ..
            "' was uninstalled successfully!\nYou may now disable it in your mod manager.")

        VCHelpers.Feedback:PlayEffect("a0157444-7bde-6338-b0ce-7659d7fe6ed0")
        Ext.Net.BroadcastMessage("MU_Uninstalled_Mod", Ext.Json.Stringify({ modUUID = modUUID }))
    else
        Ext.Net.BroadcastMessage("MU_Uninstall_Mod_Failed", Ext.Json.Stringify({ modUUID = modUUID, error = err }))
    end
end

Ext.RegisterNetListener("MU_Server_Should_Load_Templates", function(channel, payload)
    VanillaTemplates, ModsTemplates = GetVanillaAndModsTemplates()
    ModsStats = GetStatsEntriesByMod({ "StatusData", "SpellData", "PassiveData" })
end)

Ext.RegisterConsoleCommand("MU_Uninstall_Mod", function(cmd, modId)
    if not modId then
        MUWarn(0, "No mod ID provided.\nUsage: !" .. cmd .. " <modGuid>")

        return
    end

    local mod = Ext.Mod.GetMod(modId)
    if not mod then
        MUWarn(0, "Mod not found for UUID: " .. modId .. ". Are you sure you have informed the correct mod UUID?")
        return
    end

    VanillaTemplates, ModsTemplates = GetVanillaAndModsTemplates()
    ModsStats = GetStatsEntriesByMod({ "StatusData", "SpellData", "PassiveData" })

    local modTemplates = ModsTemplates[modId]
    if not modTemplates then
        MUWarn(0, "No templates found for mod ID: " .. modId)
        return
    end

    UninstallMod(modId)
end)
