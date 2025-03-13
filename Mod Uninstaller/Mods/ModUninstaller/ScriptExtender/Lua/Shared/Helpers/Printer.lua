MUPrinter = VolitionCabinetPrinter:New { Prefix = "Mod Uninstaller", ApplyColor = true, DebugLevel = MCM.Get("debug_level") }

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


-- Helper to combine varargs into a single string.
local function combineArgs(...)
    local args = { ... }
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    return table.concat(args, " ")
end

function MUPrint(debugLevel, ...)
    MUPrinter:SetFontColor(0, 255, 255)
    MUPrinter:Print(debugLevel, ...)
end

function MUTest(debugLevel, ...)
    if debugLevel > 2 then return end
    if debugLevel == 0 then
        MUPrinter:SetFontColor(100, 200, 150)
        MUPrinter:PrintTest(debugLevel, ...)
    else
        local message = combineArgs(...)
        LogToFile.log("TEST", message)
    end
end

function MUSuccess(debugLevel, ...)
    if debugLevel > 2 then return end
    if debugLevel == 0 then
        MUPrinter:SetFontColor(50, 255, 100)
        MUPrinter:Print(debugLevel, ...)
    else
        local message = combineArgs(...)
        LogToFile.log("SUCCESS", message)
    end
end

function MUDebug(debugLevel, ...)
    if debugLevel > 2 then return end
    if debugLevel == 0 then
        MUPrinter:SetFontColor(200, 200, 0)
        MUPrinter:PrintDebug(debugLevel, ...)
    else
        local message = combineArgs(...)
        LogToFile.log("DEBUG", message)
    end
end

function MUWarn(debugLevel, ...)
    if debugLevel > 2 then return end
    if debugLevel == 0 then
        MUPrinter:SetFontColor(255, 100, 50)
        MUPrinter:PrintWarning(debugLevel, ...)
    else
        local message = combineArgs(...)
        LogToFile.log("WARN", message)
    end
end

function MUDump(debugLevel, ...)
    if debugLevel > 2 then return end
    if debugLevel == 0 then
        MUPrinter:SetFontColor(190, 150, 225)
        MUPrinter:Dump(debugLevel, ...)
    else
        local message = combineArgs(...)
        LogToFile.log("DUMP", message)
    end
end

function MUDumpArray(debugLevel, ...)
    if debugLevel > 2 then return end
    if debugLevel == 0 then
        MUPrinter:DumpArray(debugLevel, ...)
    else
        local message = combineArgs(...)
        LogToFile.log("DUMPARRAY", message)
    end
end
