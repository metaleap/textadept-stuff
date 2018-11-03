local me = {}

local function goToBufferTab(tabNo)
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

local function setupSaneBufferTabLabels()
    local on = function()
        local all = {}
        for _, buf in ipairs(_BUFFERS) do
            if buf.filename then
                local filebasename = buf.filename:gsub("(.*/)(.*)", "%2")
                buf.tab_label = '    ' .. filebasename .. '    '
                local byname = all[filebasename]
                if byname == nil then
                    all[filebasename] = { buf }
                else
                    byname[1 + #byname] = buf
                end
            end
        end
        local homeprefix = os.getenv("HOME") .. '/'
        for name, bufs in pairs(all) do
            if #bufs > 1 then
                for _, buf in ipairs(bufs) do
                    buf.tab_label = buf.filename
                    if buf.tab_label:sub(1, #homeprefix) == homeprefix then
                        buf.tab_label = '~' .. buf.tab_label:sub(#homeprefix)
                    end
                    buf.tab_label = '    ' .. buf.tab_label .. '    '
                end
            end
        end
    end

    events.connect(events.BUFFER_DELETED, on)
    events.connect(events.FILE_OPENED, on)
    events.connect(events.BUFFER_AFTER_SWITCH, on)
end

local function setupRestoreClosedBufferTabs()
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
    setupRestoreClosedBufferTabs()
    setupSaneBufferTabLabels()

    keys.a0 = function() goToBufferTab(0) end
    keys.a1 = function() goToBufferTab(1) end
    keys.a2 = function() goToBufferTab(2) end
    keys.a3 = function() goToBufferTab(3) end
    keys.a4 = function() goToBufferTab(4) end
    keys.a5 = function() goToBufferTab(5) end
    keys.a6 = function() goToBufferTab(6) end
    keys.a7 = function() goToBufferTab(7) end
    keys.a8 = function() goToBufferTab(8) end
    keys.a9 = function() goToBufferTab(9) end
    events.connect(events.BUFFER_AFTER_SWITCH, function()
        ui.statusbar_text = buffer.filename
    end)
end

return me
