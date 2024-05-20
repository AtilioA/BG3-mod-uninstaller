-- TODO: add these items to a container instead
function MoveAllItemsFromContainer(containerUUID)
    local campChest = VCHelpers.Camp:GetChestTemplateUUID()
    local items = VCHelpers.Inventory:GetInventory(containerUUID)
    for _, item in pairs(items) do
        if item.Guid then
            local exact, total = Osi.GetStackAmount(item.Guid)
            Osi.ToInventory(item.Guid, campChest, total)
        end
    end
end

function DeleteAllMatchingTemplates(entities, templateUUID)
    for _, entity in pairs(entities) do
        if entity and entity.ServerItem and entity.ServerItem.Template and entity.ServerItem.Template.Id == templateUUID then
            if Osi.IsContainer(entity.Uuid.EntityUuid) == 1 then
                MoveAllItemsFromContainer(entity.Uuid.EntityUuid)
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
        DeleteAllMatchingTemplates(entities, templateData.Id)
    end
end
