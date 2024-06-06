-- TODO: understand how to remove spells from all entities

function RemoveSpellsFromEntities(spells)
    local entities = Ext.Entity.GetAllEntitiesWithUuid()
    for Guid, entityHandle in pairs(entities) do
        MUWarn(2, "Removing spells from entity " .. Guid)
        for _, spell in ipairs(spells) do
            MUWarn(3, "Removing spell " .. spell .. " from entity " .. Guid)
            Osi.RemoveSpell(Guid, spell)
        end
    end
end

function RemoveSpellsForMod(modGuid)
    local spells = GetSpellsFromMod(modGuid)

    if not spells or table.isEmpty(spells) then
        MUSuccess(0, "Mod " .. Ext.Mod.GetMod(modGuid).Info.Name .. " has no spells")
        return
    end

    -- TODO: get vanilla spells
    -- Filter out vanilla spells
    local modSpells = {}
    for _, spell in ipairs(spells) do
        -- if VanillaSpells[spell] ~= true then
        MUWarn(1, "Queuing spell " .. spell .. " for removal from mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
        table.insert(modSpells, spell)
        -- else
        --     MUWarn(1, "Skipping vanilla spell " .. spell .. " from mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
        -- end
    end

    if #modSpells == 0 then
        MUSuccess(0, "Mod " .. Ext.Mod.GetMod(modGuid).Info.Name .. " has no spells")
        return
    end

    MUWarn(0, "Removing " .. #modSpells .. " spells from all entities for mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
    RemoveSpellsFromEntities(modSpells)
    MUSuccess(0, "Removed all spells from all entities for mod " .. Ext.Mod.GetMod(modGuid).Info.Name)
end

Ext.RegisterConsoleCommand("MU_Remove_Spells", function(cmd, modGuid)
    if not modGuid or not Ext.Mod.IsModLoaded(modGuid) then
        MUWarn(0, "Usage: !" .. cmd .. " <modGuid>")
        return
    end

    -- VanillaSpells, ModsSpells = GetVanillaAndModsSpells()

    RemoveSpellsForMod(modGuid)
end)
