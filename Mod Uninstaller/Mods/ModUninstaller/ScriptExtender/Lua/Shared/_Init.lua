setmetatable(Mods.ModUninstaller, { __index = Mods.VolitionCabinet })

local function UpdateLoca()
    for _, file in ipairs({ "MU_English.loca" }) do
        local fileName = string.format("Localization/English/%s.xml", file)
        local contents = Ext.IO.LoadFile(fileName, "data")

        if not contents then
            _P("Failed to load file: " .. fileName)
            return
        end

        for line in string.gmatch(contents, "([^\r\n]+)\r*\n") do
            local handle, value = string.match(line, '<content contentuid="(%w+)".->(.+)</content>')
            if handle ~= nil and value ~= nil then
                value = value:gsub("&[lg]t;", {
                    ['&lt;'] = "<",
                    ['&gt;'] = ">"
                })
                Ext.Loca.UpdateTranslatedString(handle, value)
            end
        end
    end
end

UpdateLoca()

local deps = {
    VCModuleUUID = "f97b43be-7398-4ea5-8fe2-be7eb3d4b5ca",
    MCMModuleUUID = "755a8a72-407f-4f0d-9a33-274ac0f0b53d"
}
if not Ext.Mod.IsModLoaded(deps.VCModuleUUID) then
    Ext.Utils.Print(
        "Volition Cabinet is missing and is a hard requirement. PLEASE MAKE SURE IT IS ENABLED IN YOUR MOD MANAGER.")
end

if not Ext.Mod.IsModLoaded(deps.MCMModuleUUID) then
    Ext.Utils.Print(
        "BG3 Mod Configuration Menu is missing and is a hard requirement. PLEASE MAKE SURE IT IS ENABLED IN YOUR MOD MANAGER.")
end


---Ext.Require files at the path
---@param path string
---@param files string[]
function RequireFiles(path, files)
    for _, file in pairs(files) do
        Ext.Require(string.format("%s%s.lua", path, file))
    end
end

RequireFiles("Shared/", {
    "MetaClass",
    "Data/_Init",
    "Helpers/_Init",
    "Classes/_Init",
})

local MODVERSION = Ext.Mod.GetMod(ModuleUUID).Info.ModVersion
if MODVERSION == nil then
    MUWarn(0, "loaded (version unknown)")
else
    -- Remove the last element (build/revision number) from the MODVERSION table
    table.remove(MODVERSION)

    local versionNumber = table.concat(MODVERSION, ".")
    MUPrint(0, "Mod Uninstaller version " .. versionNumber .. " loaded")
end
