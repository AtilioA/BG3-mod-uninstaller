-- TODO: add these items to a container instead
function MoveAllItemsFromContainer(containerUUID)
    local campChest = VCHelpers.Camp:GetChestTemplateUUID()
    local items = VCHelpers.Inventory:GetInventory(containerUUID)

    for _, item in pairs(items) do
        if item.Guid then
            if Osi.IsContainer(item.Guid) == 1 then
                -- Recursively move items from nested containers
                MoveAllItemsFromContainer(item.Guid)
            else
                local exact, total = Osi.GetStackAmount(item.Guid)
                Osi.ToInventory(item.Guid, campChest, total)
                MUPrint(0, "Moved item: " .. item.Guid .. " (" .. item.Name .. ") to camp chest.")
            end
        end
    end
end

function DeleteAllMatchingTemplates(entities, templateID)
    local containersToDelete = {}

    for _, entity in pairs(entities) do
        if entity and entity.ServerItem and entity.ServerItem.Template and entity.ServerItem.Template.Id == templateID then
            if Osi.IsContainer(entity.Uuid.EntityUuid) == 1 then
                MUWarn(1,
                    "Container " ..
                    entity.ServerItem.Template.Name ..
                    " found with UUID: " .. entity.Uuid.EntityUuid .. ". Moving its items to camp chest.")
                MoveAllItemsFromContainer(entity.Uuid.EntityUuid)
                table.insert(containersToDelete, entity.Uuid.EntityUuid)
            else
                local itemOwner = VCHelpers.Inventory:GetHolder(entity.Uuid.EntityUuid)
                if itemOwner then
                    MUWarn(1,
                        "Item found in inventory of: " ..
                        VCHelpers.Loca:GetDisplayName(itemOwner.Uuid.EntityUuid) ..
                        " (" ..
                        itemOwner.Uuid.EntityUuid ..
                        ").")
                end
                MUWarn(1,
                    "Deleting entity: " .. entity.ServerItem.Template.Name .. " with UUID: " .. entity.Uuid.EntityUuid)
                Osi.RequestDelete(entity.Uuid.EntityUuid)
            end
        end
    end

    -- Delete the containers after 2 seconds, just to be safe (in case the items are not moved in time)
    -- NOTE: unfortunately, due to limitations in the event system, we can't listen to item move events for this, so we'll be using a timer
    VCHelpers.Timer:OnTime(1500, function()
        for _, uuid in pairs(containersToDelete) do
            MUWarn(1, "Deleting container: " .. uuid)
            Osi.RequestDelete(uuid)
        end
    end)
end

--- Delete a table of templates by ID
---@param uuid string The mod UUID
function DeleteTemplatesForMod(uuid)
    local modsTemplatesData = ModsTemplates[uuid]
    local entities = Ext.Entity.GetAllEntitiesWithComponent("ServerItem")
    for _, templateData in pairs(modsTemplatesData) do
        MUWarn(2, "Processing template ID: " .. templateData.Id)
        DeleteAllMatchingTemplates(entities, templateData.Id)
    end
end

Ext.RegisterConsoleCommand("MU_Delete_Templates_For_Mod", function(cmd, modId)
    if not modId then
        MUWarn(0, "Usage: !" .. cmd .. " <modId>")
        return
    end

    VanillaTemplates, ModsTemplates = GetVanillaAndModsTemplates()
    ModsStats = GetStatsEntriesByMod({ "StatusData", "SpellData", "PassiveData" })

    local modTemplates = ModsTemplates[modId]
    if not modTemplates then
        MUWarn(0, "No templates found for mod ID: " .. modId)
        return
    end

    DeleteTemplatesForMod(modTemplates)
end)
