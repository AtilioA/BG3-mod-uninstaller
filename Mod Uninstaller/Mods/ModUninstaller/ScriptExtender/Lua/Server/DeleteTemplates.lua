-- TODO: add these items to a container instead
function MoveAllItemsFromContainer(containerUUID)
    local campChest = VCHelpers.Camp:GetChestTemplateUUID()
    local items = VCHelpers.Inventory:GetInventory(containerUUID)
    for _, item in pairs(items) do
        if item.Guid then
            local exact, total = Osi.GetStackAmount(item.Guid)
            Osi.ToInventory(item.Guid, campChest, total)
            MUPrint(0, "Moved item: " .. item.Guid .. " (" .. item.Name .. ") to camp chest.")
        end
    end

    --- Delete the container after 1 second, just to be safe (in case the items are not moved in time)
    VCHelpers.Timer:OnTime(1500, function()
        MUWarn(0, "Deleting container: " .. containerUUID)
        Osi.RequestDelete(containerUUID)
    end)
end

function DeleteAllMatchingTemplates(entities, templateID)
    for _, entity in pairs(entities) do
        if entity and entity.ServerItem and entity.ServerItem.Template and entity.ServerItem.Template.Id == templateID then
            if Osi.IsContainer(entity.Uuid.EntityUuid) == 1 then
                MUWarn(0,
                    "Container " ..
                    entity.ServerItem.Template.Name ..
                    " found with UUID: " .. entity.Uuid.EntityUuid .. ". Moving its items to camp chest.")
                MoveAllItemsFromContainer(entity.Uuid.EntityUuid)
                return
            end
            local itemOwner = VCHelpers.Inventory:GetHolder(entity.Uuid.EntityUuid)
            if itemOwner then
                MUWarn(0,
                    "Item found in inventory of: " ..
                    VCHelpers.Loca:GetDisplayName(itemOwner.Uuid.EntityUuid) ..
                    " (" ..
                    itemOwner.Uuid.EntityUuid ..
                    ").")
            end
            MUWarn(0,
                "Deleting entity: " .. entity.ServerItem.Template.Name .. " with UUID: " .. entity.Uuid.EntityUuid)
            Osi.RequestDelete(entity.Uuid.EntityUuid)
        end
    end
end

--- Delete a table of templates by ID
---@param modsTemplatesData table<number, table>
function DeleteTemplatesForMod(modsTemplatesData)
    local entities = Ext.Entity.GetAllEntitiesWithComponent("ServerItem")
    for _, templateData in pairs(modsTemplatesData) do
        MUWarn(2, "Processing template ID: " .. templateData.Id)
        DeleteAllMatchingTemplates(entities, templateData.Id)
    end
end
