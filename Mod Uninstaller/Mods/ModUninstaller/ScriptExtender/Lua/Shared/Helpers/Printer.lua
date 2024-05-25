MUPrinter = VolitionCabinetPrinter:New { Prefix = "Mod Uninstaller", ApplyColor = true, DebugLevel = MCMGet("debug_level") }

-- Update the Printer debug level when the setting is changed, since the value is only used during the object's creation
Ext.RegisterNetListener("MCM_Saved_Setting", function(call, payload)
    local data = Ext.Json.Parse(payload)
    if not data or data.modGUID ~= ModuleUUID or not data.settingId then
        return
    end

    if data.settingId == "debug_level" then
        MUDebug(0, "Setting debug level to " .. data.value)
        MUPrinter.DebugLevel = data.value
    end
end)

function MUPrint(debugLevel, ...)
    MUPrinter:SetFontColor(0, 255, 255)
    MUPrinter:Print(debugLevel, ...)
end

function MUTest(debugLevel, ...)
    MUPrinter:SetFontColor(100, 200, 150)
    MUPrinter:PrintTest(debugLevel, ...)
end

function MUSuccess(debugLevel, ...)
    MUPrinter:SetFontColor(50, 255, 100)
    MUPrinter:Print(debugLevel, ...)
end

function MUDebug(debugLevel, ...)
    MUPrinter:SetFontColor(200, 200, 0)
    MUPrinter:PrintDebug(debugLevel, ...)
end

function MUWarn(debugLevel, ...)
    MUPrinter:SetFontColor(255, 100, 50)
    MUPrinter:PrintWarning(debugLevel, ...)
end

function MUDump(debugLevel, ...)
    MUPrinter:SetFontColor(190, 150, 225)
    MUPrinter:Dump(debugLevel, ...)
end

function MUDumpArray(debugLevel, ...)
    MUPrinter:DumpArray(debugLevel, ...)
end
