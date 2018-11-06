local ux = {}
-- to read the module, begin from the bottom-most func `init`

local util = require 'metaleap_zentient.util'



local currentlyOpenedFiles = {} -- most-recently opened is last
local recentlyClosedFiles = {} -- most-recently closed is first


-- allows alt+1, alt+2 .. alt+0 to switch to that tab
local function goToBuftab(tabNo)
    local buf = nil
    if tabNo == 0 then
        buf = _BUFFERS[#_BUFFERS]
    elseif tabNo > 0 and tabNo <= #_BUFFERS then
        buf = _BUFFERS[tabNo]
    end
    if buf ~= nil then
        view.goto_buffer(view, buf)
    end
end


-- ensures no duplicate tab labels by including file paths when necessary
local function setupSaneBuftabLabels()
    local relabel = function(label, bufdirty)
        local namepref, namesuff = '    ', '    '
        if bufdirty then namepref, namesuff = '    ', '      ' end
        return namepref..label..namesuff
    end

    local ensure = function()
        local all = {}
        for _, buf in ipairs(_BUFFERS) do
            if buf.filename then
                filebasename = util.fsPathBaseName(buf.filename)
                local byname = all[filebasename]
                if byname == nil then
                    all[filebasename] = { buf }
                    buf.tab_label = relabel(filebasename, buf.modify)
                else
                    byname[1 + #byname] = buf
                end
            end
        end

        for _, bufs in pairs(all) do
            if #bufs > 1 then -- name occurs more than once
                for _, buf in ipairs(bufs) do
                    buf.tab_label = relabel(util.fsPathPrettify(buf.filename, true, false), buf.modify)
                end
            end
        end
    end

    events.connect(events.BUFFER_DELETED, ensure)
    events.connect(events.FILE_OPENED, ensure)
    events.connect(events.BUFFER_NEW, ensure)
    events.connect(events.BUFFER_AFTER_SWITCH, ensure)
    events.connect(events.FILE_AFTER_SAVE, ensure)
    events.connect(events.UPDATE_UI, function(upd)
        if upd == buffer.UPDATE_CONTENT then ensure() end
    end)
    events.connect(events.CHAR_ADDED, ensure) -- workaround for enter / del

    ensure()
end


-- allows ctrl+shift+tab to reopen recently-closed tabs
local function setupReopenClosedBuftabs()
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
                table.remove(currentlyOpenedFiles, i)
            end
        end
    end)

    return function()
        if #recentlyClosedFiles > 0 then
            local restoreFile = recentlyClosedFiles[1]
            io.open_file(restoreFile)
        end
    end
end


-- opens dialog to select "recent files" to open, but sorted by most-recently-
-- closed and without listing files that are already currently opened
local function setupRecentlyClosed()
    return function()
        if #recentlyClosedFiles > 0 then
            local filelistitems = {}
            for _, fullfilepath in ipairs(recentlyClosedFiles) do
                filelistitems[1 + #filelistitems] = util.fsPathPrettify(util.fsPathBaseName(fullfilepath), true, true) .. '\t\t'
                filelistitems[1 + #filelistitems] = util.fsPathPrettify(util.fsPathParentDir(fullfilepath), true, true) .. '\t\t'
                filelistitems[1 + #filelistitems] = fullfilepath
            end

            local button, selfiles = ui.dialogs.filteredlist {
                title = 'Most recently closed:', width = 2345, height = 1234, select_multiple = true,
                columns = { 'File:', 'Location:', 'Full Path:' }, items = filelistitems, search_column = 3,
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


-- when typing opening-brace-or-quote char while selection/s: enclose (rather
-- than overwrite) selection(s), and crucially also preserve all selection(s)
local function setupAutoEnclosers()
    local encloser = function(left, right)
        return function()
            if buffer.selection_empty then
                return false
            else
                local incr, newsels, numsels = 1, {}, buffer.selections
                for i = 1, numsels do
                    newsels[i] = { buffer.selection_n_start[i - 1] , buffer.selection_n_end[i - 1] }
                    if newsels[i][2] < newsels[i][1] then
                        newsels[i][1], newsels[i][2] = newsels[i][2], newsels[i][1]
                    end
                end
                table.sort(newsels, function(dis, dat)
                    return dis[1] < dat[1] and dis[2] < dat[2]
                end)
                textadept.editing.enclose(left, right)
                for i = 0, numsels - 1 do
                    buffer.selection_n_start[i], buffer.selection_n_end[i] = incr + newsels[i+1][1], incr + newsels[i+1][2]
                    incr = incr + 2
                end
            end
        end
    end

    textadept.editing.auto_pairs[96] = '`'
    for l, right in pairs(textadept.editing.auto_pairs) do
        local left = string.char(l)
        keys[left] = encloser(left, right)
    end
end


-- buf-tab context-menu item: "close others" / close-all-but-this-tab
local function setupBuftabCloseOthers()
    textadept.menu.tab_context_menu[1 + #textadept.menu.tab_context_menu] = { 'Close Others', function()
        local curfilename = buffer.filename
        for _, buf in ipairs(_BUFFERS) do
            if buf.filename == nil or buf.filename ~= curfilename then
                -- we don't buffer.delete(buf) as we might lose unsaved-changes
                view:goto_buffer(buf)
                io.close_buffer()
            end
        end
    end }
end


-- all built-in menus are relocated under a single top-level menu that always
-- shows the full dir path of the currently active buf-tab
local function setupShowCurFileFullPath()
    local menutitle = function()
        return util.menuable(util.fsPathPrettify(util.fsPathParentDir(buffer.filename or buffer.tab_label), true, true)) .. '\t'
    end

    local menu = { title = menutitle() }
    for _, stdmenu in ipairs(textadept.menu.menubar) do
        menu[1 + #menu] = stdmenu
    end
    textadept.menu.menubar = { menu }

    local ensure = function()
        textadept.menu.menubar[1].title = menutitle()
    end

    events.connect(events.FILE_AFTER_SAVE, ensure)
    events.connect(events.BUFFER_AFTER_SWITCH, ensure)
    events.connect(events.FILE_OPENED, ensure)
    events.connect(events.BUFFER_NEW, ensure)
end


-- keeps a buf-tab's selection-state in mem to restore it on reopen-after-close
local function setupBuftabSelStateRecall()
    local bufstates, bufprops = {}, { 'anchor', 'current_pos', 'first_visible_line', 'x_offset' }

    events.connect(events.UPDATE_UI, function(upd)
        if buffer.filename then
            local bufstate = {}
            for _, p in ipairs(bufprops) do bufstate[p] = buffer[p] end
            bufstates[buffer.filename] = bufstate
        end
    end)

    events.connect(events.FILE_OPENED, function(filepath)
        local bufstate = bufstates[filepath]
        if bufstate then
            for _, p in ipairs(bufprops) do buffer[p] = bufstate[p] end
        end
    end)
end


-- smoothing out the built-in Find functionalities a bit around the edges..
local function setupFindRoutines()
    local getphrase = function(keepsels)
        local phrase
        if buffer.selection_start ~= buffer.selection_end then
            if buffer.selections > 1 and not keepsels then
                buffer:set_sel(buffer.selection_start, buffer.selection_end)
            end
            phrase = util.bufSelText()
            ui.find.find_entry_text = phrase
        end
        return phrase
    end

    events.connect(events.FIND, function(phrase) ui.find.find_entry_text = phrase end)
    local findincr, finddiag, findword = function()
        ui.find.find_incremental(getphrase(), true, true)
    end, function()
        ui.find.in_files, ui.find.match_case, ui.find.whole_word, ui.find.regex = false, false, false, false
        getphrase()
        ui.find.focus()
    end, function()
        textadept.editing.select_word()
        getphrase(true)
    end
    return findincr, finddiag, findword
end


-- sets up hover-tips for mouse-dwelling-on-symbol
local function setupHoverTips()
    events.connect(events.DWELL_START, function(pos)
        if buffer:call_tip_active() then
            buffer:call_tip_cancel()
        end
        if pos >= 0 then
            textadept.editing.show_documentation(pos)
        end
    end)
end


-- keep auto-highlighting the current symbol or word as the caret moves
local function setupAutoHighlight()
    local on = function(upd)
        if (not upd) or upd == buffer.UPDATE_SELECTION or upd == buffer.UPDATE_CONTENT then
            if buffer.selection_empty and buffer.selections == 1 then
                textadept.editing.highlight_word(true)
            elseif textadept.editing.clear_highlighted_words then
                textadept.editing.clear_highlighted_words()
            end
        end
    end

    events.connect(events.UPDATE_UI, on)
    events.connect(events.CHAR_ADDED, on) -- workaround for enter / del
end


function ux.init()
    keys.a0 = function() goToBuftab(0) end
    keys.a1 = function() goToBuftab(1) end
    keys.a2 = function() goToBuftab(2) end
    keys.a3 = function() goToBuftab(3) end
    keys.a4 = function() goToBuftab(4) end
    keys.a5 = function() goToBuftab(5) end
    keys.a6 = function() goToBuftab(6) end
    keys.a7 = function() goToBuftab(7) end
    keys.a8 = function() goToBuftab(8) end
    keys.a9 = function() goToBuftab(9) end

    setupShowCurFileFullPath()
    setupSaneBuftabLabels()
    keys.cT = setupReopenClosedBuftabs()
    keys.cO = setupRecentlyClosed()
    setupBuftabCloseOthers()
    setupBuftabSelStateRecall()
    setupAutoEnclosers()
    keys.cf, keys.cF, keys.cd = setupFindRoutines()
    setupHoverTips()
    setupAutoHighlight()
end



return ux
