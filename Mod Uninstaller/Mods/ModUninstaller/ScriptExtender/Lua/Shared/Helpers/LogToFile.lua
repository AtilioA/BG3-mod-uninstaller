-- LogToFile module: buffered logging to a unique file in ModUninstallerLogs folder.
LogToFile = {}
LogToFile.buffer = {}
LogToFile.maxBufferSize = 1000
LogToFile.flushInterval = 5000
LogToFile.timerStarted = false

local function startFlushTimer()
    VCHelpers.Timer:OnTime(LogToFile.flushInterval, function()
        LogToFile.flush()
        startFlushTimer()
    end)
end

-- Lazy initialization of a unique file path (only create if needed).
function LogToFile.getFilePath()
    if not LogToFile.filePath then
        local timestamp = Ext.Utils.MonotonicTime()
        LogToFile.filePath = "ModUninstallerLogs/mod_uninstaller_" .. tostring(timestamp) .. ".log"
    end
    return LogToFile.filePath
end

-- Flush the log buffer to disk.
function LogToFile.flush()
    if #LogToFile.buffer > 0 then
        local logContent = table.concat(LogToFile.buffer, "\n") .. "\n"
        local filePath = LogToFile.getFilePath()
        local currentContent = Ext.IO.LoadFile(filePath)
        if not currentContent then
            currentContent = ""
        end
        Ext.IO.SaveFile(filePath, currentContent .. logContent)
        LogToFile.buffer = {}
    end
end

-- Append a log message to the buffer.
function LogToFile.log(logType, message)
    table.insert(LogToFile.buffer, logType .. ": " .. message)
    if not LogToFile.timerStarted then
        startFlushTimer()
        LogToFile.timerStarted = true
    end
    if #LogToFile.buffer >= LogToFile.maxBufferSize then
        LogToFile.flush()
    end
end

return LogToFile
