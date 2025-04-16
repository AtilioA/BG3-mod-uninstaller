local function generateVanillaPatterns()
    local folderNames = { "Public", "Mods", "Shared", "SharedDev" }
    local modNames = { "GustavX", "Gustav", "GustavDev", "Shared", "SharedDev", "Honour", "HonourX", "MainUI",
    "ModBrowser" }
    local vanillaPatterns = {}

    for _, folder in ipairs(folderNames) do
        for _, mod in ipairs(modNames) do
            table.insert(vanillaPatterns, folder .. "/" .. mod)
        end
    end

    return vanillaPatterns
end

local function isVanillaFilename(filename)
    local vanillaPatterns = generateVanillaPatterns()

    for _, pattern in ipairs(vanillaPatterns) do
        if string.find(filename, pattern) then
            return true
        end
    end
    return false
end

-- Generate VanillaTemplatesIDs table at runtime
function GenerateVanillaTemplatesIDs()
    MUPrint(1, "Generating VanillaTemplatesIDs at runtime...")
    local templates = Ext.Template.GetAllRootTemplates()
    local count = 0

    -- Reset global table
    VanillaTemplatesIDs = {}

    for _templateId, templateData in pairs(templates) do
        if templateData.TemplateType == 'item' and isVanillaFilename(templateData.FileName) then
            VanillaTemplatesIDs[templateData.Id] = true
            count = count + 1
        end
    end

    MUSuccess(1, "Generated VanillaTemplatesIDs with " .. count .. " entries")
end

-- Generate VanillaStatuses table at runtime
function GenerateVanillaStatuses()
    MUPrint(1, "Generating VanillaStatuses at runtime...")
    local statuses = Ext.Stats.GetStats("StatusData")
    local count = 0

    -- Reset global table
    VanillaStatuses = {}

    -- Mark vanilla status entries
    for _, status in pairs(statuses) do
        local statusId = status
        if type(status) == "table" and status.Name then
            statusId = status.Name
        end

        -- Assume all statuses from Stats.txt are vanilla
        VanillaStatuses[statusId] = true
        count = count + 1
    end

    MUSuccess(1, "Generated VanillaStatuses with " .. count .. " entries")
end

local function isVanillaID(id)
    return VanillaTemplatesIDs[id] == true
end

local function getAllVanillaTemplates()
    local templates = Ext.Template.GetAllRootTemplates()

    local vanillaTemplates = {}
    for templateId, templateData in pairs(templates) do
        if templateData.TemplateType == 'item' and isVanillaFilename(templateData.FileName) then
            table.insert(vanillaTemplates, templateData)
        end
    end

    return vanillaTemplates
end

local function getAllVanillaAndModdedTemplates()
    local templates = Ext.Template.GetAllRootTemplates()

    local vanillaTemplates = {}
    local moddedTemplates = {}
    for templateId, templateData in pairs(templates) do
        if templateData.TemplateType == 'item' then
            if isVanillaFilename(templateData.FileName) or isVanillaID(templateData.Id) then
                table.insert(vanillaTemplates, templateData)
            else
                table.insert(moddedTemplates, templateData)
            end
        end
    end

    return vanillaTemplates, moddedTemplates
end

local function formatTemplateData(templateData)
    local description = Ext.Loca.GetTranslatedString(templateData.TechnicalDescription.Handle.Handle)
    if not description or description == "" then
        description = Ext.Loca.GetTranslatedString(templateData.Description.Handle.Handle)
    end

    local templateStats = Ext.Stats.Get(templateData.Stats)
    local rarity = nil
    xpcall(function()
        if templateStats and templateStats.Rarity then
            rarity = templateStats.Rarity
        end
    end, function(err)
        MUWarn(0, "Error retrieving rarity: " .. tostring(err))
    end)

    return {
        Description = description,
        DisplayName = VCHelpers.Loca:GetTranslatedStringFromTemplateUUID(templateData.Id),
        Icon = templateData.Icon,
        Id = templateData.Id,
        Name = templateData.Name,
        Stats = templateData.Stats,
        Rarity = rarity,
    }
end

local function formatVanillaTemplates(vanillaTemplates)
    local formattedTemplateData = {}
    for _, templateData in pairs(vanillaTemplates) do
        formattedTemplateData[templateData.Id] = formatTemplateData(templateData)
    end
    return formattedTemplateData
end

local function checkDirectoryInPath(filePath, directory)
    -- Normalize the file path and directory to handle differences in path separators, just in case
    local normalizedFilePath = filePath:gsub("\\", "/")
    local normalizedDirectory = directory:gsub("\\", "/")

    -- Find the index of "Data/Public" in the file path; mod Directory should be immediately after this
    local startIndex = normalizedFilePath:find("Data/Public")

    if not startIndex then
        return false
    end

    -- Get the first directory immediately after "Data/Public"
    local relevantPath = normalizedFilePath:sub(startIndex + #"Data/Public/")
    local firstDirectory = relevantPath:match("([^/]+)")

    -- Check if the first directory matches the given directory
    return firstDirectory == normalizedDirectory
end

-- Initialize vanilla template and status tables if they haven't been initialized
function InitializeVanillaTables()
    MUPrint(1, "Initializing vanilla tables...")
    GenerateVanillaTemplatesIDs()
    GenerateVanillaStatuses()
    MUSuccess(1, "Vanilla tables initialized successfully")
end

function GetVanillaAndModsTemplates()
    -- Ensure vanilla tables are initialized before using them
    if table.isEmpty(VanillaTemplatesIDs) then
        InitializeVanillaTables()
    end

    local function getModIdsTable()
        MUPrint(1, "Fetching mod load order")
        local loadOrder = Ext.Mod.GetLoadOrder()
        local modIds = {}
        for _, modId in pairs(loadOrder) do
            local mod = Ext.Mod.GetMod(modId)
            if mod then
                MUPrint(2, "Adding mod to modIds table: " .. modId .. " (" .. mod.Info.Name .. ")")
                modIds[modId] = {}
            else
                MUWarn(2, "Mod not found for modId: " .. modId)
            end
        end
        return modIds
    end

    local function addTemplateToMod(modIds, templateData)
        for modId, _ in pairs(modIds) do
            local mod = Ext.Mod.GetMod(modId)
            -- MUDebug(3,
            --     "Checking if template " ..
            --     templateData.FileName .. " matches mod " .. modId .. " (" .. mod.Info.Name .. ")")
            if mod and checkDirectoryInPath(templateData.FileName, mod.Info.Directory) then
                -- MUPrint(3,
                --     "Template matches mod directory: " ..
                --     modId .. "(" .. mod.Info.Name .. ") in " .. templateData.FileName)
                table.insert(modIds[modId], formatTemplateData(templateData))
            end
        end
    end

    local function assignTemplatesToMods(moddedTemplates)
        MUPrint(1, "Assigning templates to mods")
        local modIds = getModIdsTable()
        for _, templateData in pairs(moddedTemplates) do
            addTemplateToMod(modIds, templateData)
        end
        return modIds
    end


    MUPrint(1, "Getting all vanilla and modded templates")
    local vanillaTemplates, moddedTemplates = getAllVanillaAndModdedTemplates()

    local formattedVanillaTemplates = formatVanillaTemplates(vanillaTemplates)
    local formattedModdedTemplates = assignTemplatesToMods(moddedTemplates)

    -- Sort templates alphabetically by their DisplayName name
    for modId, templates in pairs(formattedModdedTemplates) do
        table.sort(templates, function(a, b)
            local aName = a.DisplayName or a.Name
            local bName = b.DisplayName or b.Name
            return aName < bName
        end)
    end

    return formattedVanillaTemplates, formattedModdedTemplates
end

local function dumpAllVanillaTemplates()
    local vanillaTemplates = getAllVanillaTemplates()
    local vanillaTemplateTable = {}
    for _, templateData in pairs(vanillaTemplates) do
        table.insert(vanillaTemplateTable, templateData.Id)
    end
    Ext.IO.SaveFile("VanillaTemplates.json", Ext.DumpExport(vanillaTemplateTable))
end

local function dumpAllVanillaStatuses()
    local statuses = Ext.Stats.GetStats()
    Ext.IO.SaveFile("VanillaStatuses.json", Ext.DumpExport(statuses))
end

Ext.RegisterConsoleCommand("MU_DVT", function(cmd) dumpAllVanillaTemplates() end)
Ext.RegisterConsoleCommand("MU_DVS", function(cmd) dumpAllVanillaStatuses() end)

-- function GetTemplatesByStats(modData)
--     local templates = Ext.Template.GetAllRootTemplates()
--     local filteredTemplates = {}

--     for _, templateData in pairs(templates) do
--         if templateData.TemplateType == 'item' then
--             for statType, statEntries in pairs(modData) do
--                 if type(statEntries) == "table" then
--                     for _, statName in ipairs(statEntries) do
--                         if templateData.Stats == statName then
--                             table.insert(filteredTemplates, templateData)
--                         end
--                     end
--                 end
--             end
--         end
--     end

--     return formatTemplateData(filteredTemplates)
-- end

-- local statsEntriesByMod = GetStatsEntriesByMod({ "Armor", "Weapon", "Shield", "StatusData" })

-- for modId, modData in pairs(statsEntriesByMod) do
--     _D(modId)
--     _D(GetTemplatesByStats(statsEntriesByMod[modId].Entries))
-- end

-- Example usage:
-- local statNames = { ["Stat1"] = true, ["Stat2"] = true }
-- local templates = getTemplatesByStats(statNames)
