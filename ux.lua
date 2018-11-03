local me = {}


local currentlyOpenedFiles = {} -- most-recently opened is last
local recentlyClosedFiles = {} -- most-recently closed is first
local envhomeprefix = os.getenv("HOME") .. '/'



local function filePathBaseName(path)
    return path:gsub("(.*/)(.*)", "%2")
end
local function filePathParentDir(path)
    return path:gsub("(.*/)(.*)", "%1")
end
local function prettifiedHomeDirPrefix(path)
    if path:sub(1, #envhomeprefix) == envhomeprefix then
        path = '~' .. path:sub(#envhomeprefix)
    end
    return path
end


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
    local ensure = function()
        local all = {}
        for _, buf in ipairs(_BUFFERS) do
            if buf.filename then
                local namepref, namesuff = '    ', '    '
                if buf.modify then namepref, namesuff = '    ', '      ' end

                local filebasename = filePathBaseName(buf.filename)
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
                    local namepref, namesuff = '    ', '    '
                    if buf.modify then namepref, namesuff = '    ', '      ' end

                    buf.tab_label = buf.filename
                    buf.tab_label = prettifiedHomeDirPrefix(buf.tab_label)
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
    for _, buf in ipairs(_BUFFERS) do
        currentlyOpenedFiles[1 + #currentlyOpenedFiles] = buf.filename
    end

    events.connect(events.FILE_OPENED, function(fullFilePath)
        currentlyOpenedFiles[1 + #currentlyOpenedFiles] = fullFilePath
        for i = #recentlyClosedFiles, 1, -1 do
            if recentlyClosedFiles[i] == fullFilePath then
                table.remove(recentlyClosedFiles, i)
            end
        end
    end)

    events.connect(events.BUFFER_DELETED, function()
        for i = #currentlyOpenedFiles, 1, -1 do
            local fullFilePath, found = currentlyOpenedFiles[i], false
            for _, buf in ipairs(_BUFFERS) do
                if buf.filename == fullFilePath then
                    found = true
                    break
                end
            end
            if not found then -- this one was just closed
                table.insert(recentlyClosedFiles, 1, fullFilePath)
                --recentlyClosedFiles[1 + #recentlyClosedFiles] = fullFilePath
                table.remove(currentlyOpenedFiles, i)
            end
        end
    end)

    return function()
        if #recentlyClosedFiles > 0 then
            local restoreFile = recentlyClosedFiles[1] -- #recentlyClosedFiles]
            io.open_file(restoreFile)
        end
    end
end


-- opens dialog to select "recent files" to open, but sorted by most-recently-
--          closed and without listing files that are already currently opened
local function setupRecentlyClosed()
    return function()
        if #recentlyClosedFiles > 0 then
            local filelistitems = {}
            for _, fullfilepath in ipairs(recentlyClosedFiles) do
                filelistitems[1 + #filelistitems] = prettifiedHomeDirPrefix(filePathParentDir(fullfilepath))
                filelistitems[1 + #filelistitems] = filePathBaseName(fullfilepath)
            end

            local button, selfiles = ui.dialogs.filteredlist {
                title = 'Re-open recently closed:', width = 2345, height = 1234, select_multiple = true,
                columns = { 'Directory', 'File' }, items = filelistitems,
            }
            if button == 1 then
                local fullfilepaths = {}
                for _, idx in ipairs(selfiles) do
                    fullfilepaths[1 + #fullfilepaths] = recentlyClosedFiles[idx]
                end
                io.open_file(fullfilepaths)
            end
        end
    end
end


function me.init()
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

    setupSaneBufferTabLabels()
    keys.cT = setupReopenClosedBufferTabs()
    keys.cO = setupRecentlyClosed()
end



return me
