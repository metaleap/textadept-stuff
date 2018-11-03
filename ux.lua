local me = {}



-- allows alt+1, alt+2 .. alt+0 to switch to that tab
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


-- ensures no duplicate tab labels by including file paths when necessary
local function setupSaneBufferTabLabels()
    local homeprefix = os.getenv("HOME") .. '/'
    local ensure = function()
        local all = {}
        for _, buf in ipairs(_BUFFERS) do
            if buf.filename then
                local namepref, namesuff = '    ', '    '
                if buf.modify then namesuff = '  ☼  ' end

                local filebasename = buf.filename:gsub("(.*/)(.*)", "%2")
                buf.tab_label = namepref .. filebasename .. namesuff
                local byname = all[filebasename]
                if byname == nil then
                    all[filebasename] = { buf }
                else
                    byname[1 + #byname] = buf
                end
            end
        end

        for name, bufs in pairs(all) do
            if #bufs > 1 then -- name occurs more than once
                for _, buf in ipairs(bufs) do
                    local namepref, namesuff = '    ', '    '
                    if buf.modify then namesuff = '  ☼  ' end

                    buf.tab_label = buf.filename
                    if buf.tab_label:sub(1, #homeprefix) == homeprefix then
                        buf.tab_label = '~' .. buf.tab_label:sub(#homeprefix)
                    end
                    buf.tab_label = namepref .. buf.tab_label .. namesuff
                end
            end
        end
    end

    events.connect(events.BUFFER_DELETED, ensure)
    events.connect(events.FILE_OPENED, ensure)
    events.connect(events.BUFFER_AFTER_SWITCH, ensure)
    events.connect(events.FILE_AFTER_SAVE, ensure)
    events.connect(events.UPDATE_UI, function(upd)
        if upd == buffer.UPDATE_CONTENT then ensure() end
    end)

    ensure()
end


-- allows ctrl+shift+tab to reopen recently-closed tabs
local function setupReopenClosedBufferTabs()
    local openedFiles = {}
    local lastClosedFiles = {}

    for _, buf in ipairs(_BUFFERS) do
        openedFiles[1 + #openedFiles] = buf.filename
    end
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
    setupReopenClosedBufferTabs()
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
