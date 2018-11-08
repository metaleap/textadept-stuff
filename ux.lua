local ux = {}
-- to read the module, begin from the bottom-most func `init`

local util = require 'metaleap_zentient.util'



ux.keysReopenClosedBuftabs = 'cT'
ux.keysReopenClosedDialog = 'cO'
ux.keysFindIncr = 'cf'
ux.keysFindDiag = 'cF'
ux.keysFindWord = 'cd'


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
        view:goto_buffer(buf)
    end
end


-- ensures no duplicate tab labels by including file paths when necessary
local function setupSaneBuftabLabels()
    local relabel = function(buf, label)
        local namepref, namesuff = '    ', '    '
        if buf.modify then namepref, namesuff = '    ', '      ' end
        local tablabel = namepref..label..namesuff
        if buf.tab_label ~= tablabel then buf.tab_label = tablabel end
    end

    local ensure = function()
        local all = {}
        for _, buf in ipairs(_BUFFERS) do
            if buf.filename then
                filebasename = util.fsPathBaseName(buf.filename)
                local byname = all[filebasename]
                if byname == nil then
                    all[filebasename] = { buf }
                    relabel(buf, filebasename)
                else
                    byname[1 + #byname] = buf
                end
            end
        end

        for _, bufs in pairs(all) do
            if #bufs > 1 then -- name occurs more than once
                for _, buf in ipairs(bufs) do
                    relabel(buf, util.fsPathPrettify(buf.filename, true, false))
                end
            end
        end
    end

    events.connect(events.BUFFER_DELETED, ensure)
    events.connect(util.eventBufSwitch, ensure)
    events.connect(events.FILE_AFTER_SAVE, ensure)
    events.connect(events.UPDATE_UI, function(upd)
        if util.bufIsUpdateOf(upd, buffer.UPDATE_CONTENT) then ensure() end
    end)

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
    util.resetBag['ux.recentlyClosedFiles'] = {
        get = function() return recentlyClosedFiles end,
        set = function(v) recentlyClosedFiles = v end,
    }

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
        return util.uxStrMenuable(util.fsPathPrettify(util.fsPathParentDir(buffer.filename or buffer.tab_label), true, true)) .. '\t'
    end

    local menu = { title = menutitle() }
    for _, stdmenu in ipairs(textadept.menu.menubar) do
        menu[1 + #menu] = stdmenu
    end
    menu[1 + #menu] = { '' }
    menu[1 + #menu] = { '', function() end }
    textadept.menu.menubar = { menu }

    local ensure = function()
        textadept.menu.menubar[1].title = menutitle()
    end

    events.connect(events.FILE_AFTER_SAVE, ensure)
    events.connect(util.eventBufSwitch, ensure)
end


-- keeps a buf-tab's selection-state in mem to restore it on reopen-after-close
local function setupBuftabSelStateRecall()
    local bufstates, bufprops = {}, { 'anchor', 'current_pos', 'first_visible_line', 'x_offset' }

    events.connect(events.UPDATE_UI, function()
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

    util.resetBag['ux.bufstates'] = {
        get = function() return bufstates end,
        set = function(v) bufstates = v end,
    }
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
    events.connect(events.UPDATE_UI, function(upd)
        if util.bufIsUpdateOf(upd, buffer.UPDATE_CONTENT, buffer.UPDATE_SELECTION) then
            if buffer.selection_empty and buffer.selections == 1 then
                textadept.editing.highlight_word()
            else
                util.bufClearHighlightedWords()
            end
        end
    end)
end


-- alternative buffer-tabs navigation: alt-left & alt-right for prev/next,
-- alt-tab & shift-alt-tab based on recent-ness
local function setupAltBuftabNav()
    keys.aright = function() view:goto_buffer(1) end
    keys.aleft = function() view:goto_buffer(-1) end

    local mru, pos, ongoing, lasttime = {}, 1, false, 0

    util.resetBag['ux.buftabmru'] = {
        get = function() return mru end,
        set = function(v) mru = v end,
    }

    for i, buf in ipairs(_BUFFERS) do
        local bufname = buf.filename or buf.tab_label
        if buf == buffer then
            table.insert(mru, 1, bufname)
        else
            mru[1 + #mru] = bufname
        end
    end

    local refresh = function()
        if ongoing then return end
        -- any new bufs for `mru`?
        for _, buf in ipairs(_BUFFERS) do
            local found, bufname = false, buf.filename or buf.tab_label
            for _, mr in ipairs(mru) do
                if mr == bufname then
                    found = true
                    break
                end
            end
            if not found then
                if buf == buffer then
                    table.insert(mru, 1, bufname)
                else
                    mru[1 + #mru] = bufname
                end
            end
        end
        -- any gone bufs still in `mru`?
        for i = #mru, 1, -1 do
            if not util.bufIndexOf(mru[i]) then
                table.remove(mru, i)
            end
        end
        -- is cur-buf already anywhere in `mru`? then ditch first..
        local bufname = buffer.filename or buffer.tab_label
        for i = #mru, 1, -1 do
            if mru[i] == bufname then
                table.remove(mru, i)
                break
            end
        end
        -- ..now cur-buf goes in front of `mru`
        table.insert(mru, 1, bufname)
        pos = 1
    end
    events.connect(util.eventBufSwitch, refresh)

    local tabtime = os.time()
    events.connect(events.KEYPRESS, function(code, shift, ctrl, alt, meta, capslock)
        -- ctrl+tab or ctrl+shift+tab ?
        if ctrl and (not (alt or meta)) and (code == 65289 or code == 65056) then
            if shift then
                pos = (pos == 1) and #mru or (pos - 1)
            else
                pos = (pos == #mru) and 1 or pos + 1
            end
            tabtime = os.time()
            if not ongoing then -- the first of potentially multiple tab presses
                ongoing = true
                timeout(1, function()
                    if ongoing and os.time() - tabtime >= 1 then
                        ongoing = false -- allows refresh-of-mru
                        refresh() -- complete the op via refresh-of-mru
                    end
                    return ongoing
                end)
            end
            view:goto_buffer(_BUFFERS[util.bufIndexOf(mru[pos])])
            return true
        elseif ongoing and pos > 1 and -- is a ctrl(+shift)+tab op still ongoing?
            not (ctrl and (code == 65505 or code == 65506)) -- not a shift press?
        then -- interruption of ongoing ctrl(+shift)+tab op by some unrelated keypress:
            ongoing = false -- allows refresh-of-mru
            refresh() -- complete the op via refresh-of-mru
        end
    end)

    keys['c\t'] = nil
    keys['cs\t'] = nil
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
    keys[ux.keysReopenClosedBuftabs] = setupReopenClosedBuftabs()
    keys[ux.keysReopenClosedDialog] = setupRecentlyClosed()
    setupBuftabCloseOthers()
    setupBuftabSelStateRecall()
    setupAutoEnclosers()
    keys[ux.keysFindIncr], keys[ux.keysFindDiag], keys[ux.keysFindWord] = setupFindRoutines()
    setupHoverTips()
    --setupAutoHighlight()
    setupAltBuftabNav()
end



return ux
