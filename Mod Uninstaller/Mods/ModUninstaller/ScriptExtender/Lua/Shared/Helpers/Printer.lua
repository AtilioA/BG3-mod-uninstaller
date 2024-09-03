MUPrinter = VolitionCabinetPrinter:New { Prefix = "Mod Uninstaller", ApplyColor = true, DebugLevel = MCMGet("debug_level") }

-- Update the Printer debug level when the setting is changed, since the value is only used during the object's creation
Ext.ModEvents.BG3MCM['MCM_Setting_Saved']:Subscribe(function(payload)
    if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
        return
    end

    if payload.settingId == "debug_level" then
        MUDebug(0, "Setting debug level to " .. payload.value)
        MUPrinter.DebugLevel = payload.value
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
