local me = {}

local function goToBuffer(tabNo)
    local buf = nil
    if tabNo == 0 then
        buf = _BUFFERS[#_BUFFERS]
    else
        if tabNo > 0 and tabNo <= #_BUFFERS then
            buf = _BUFFERS[tabNo]
        end
    end
    if buf ~= nil then
        view.goto_buffer(view, buf)
    end
end

local function setupRestoreTabsFeature()
    local openedFiles = {}
    local lastClosedFiles = {}
    events.connect(events.FILE_OPENED, function(fullFilePath)
        openedFiles[1 + #openedFiles] = fullFilePath
    end)

    events.connect(events.BUFFER_DELETED, function()
        for i, fullFilePath in ipairs(openedFiles) do
            local found = false
            for _, buf in ipairs(_BUFFERS) do
                if buf.filename == fullFilePath then
                    found = true
                    break
                end
            end
            if not found then
                lastClosedFiles[1 + #lastClosedFiles] = fullFilePath
                table.remove(openedFiles, i)
            end
        end
    end)

    keys.cT = function()
        if #lastClosedFiles > 0 then
            local restoreFile = lastClosedFiles[#lastClosedFiles]
            table.remove(lastClosedFiles)
            io.open_file(restoreFile)
        end
    end
end

function me.init()
    setupRestoreTabsFeature()

    keys.a0 = function() goToBuffer(0) end
    keys.a1 = function() goToBuffer(1) end
    keys.a2 = function() goToBuffer(2) end
    keys.a3 = function() goToBuffer(3) end
    keys.a4 = function() goToBuffer(4) end
    keys.a5 = function() goToBuffer(5) end
    keys.a6 = function() goToBuffer(6) end
    keys.a7 = function() goToBuffer(7) end
    keys.a8 = function() goToBuffer(8) end
    keys.a9 = function() goToBuffer(9) end
end

return me
