
local msgbufs = 3
local fontsize = 17
local screenwidth = 3840

require('file_diff')

local go_adept = true
local lsp_adept = require('lsp-adept')
local lsp_cmp = require('lsp')
lsp_cmp.log_rpc = true

textadept.run.run_in_background = true
textadept.editing.auto_pairs = nil -- own impl, see `encloseOrPrepend()` below
textadept.editing.highlight_words = textadept.editing.HIGHLIGHT_NONE
textadept.editing.comment_string.ansi_c = '//'
textadept.editing.strip_trailing_spaces = true
textadept.history.maximum_history_size = 1234
ui.find.highlight_all_matches = true
ui.find.incremental = true
ui.SHOW_ALL_TABS = 1
view.caret_width = 5
view.whitespace_size = 5
view.view_ws = view.WS_VISIBLEONLYININDENT
view.tab_draw_mode = view.TD_STRIKEOUT
view.extra_ascent = 3
view.extra_descent = 3
view.annotation_visible = view.ANNOTATION_BOXED
view:set_theme('mulite', {font = 'M+ 2m medium', size = fontsize})

-- spaces-vs-tabs
buffer.use_tabs = false
buffer.tab_width = 4

-- completion-suggest
buffer.auto_c_choose_single = false
buffer.auto_c_ignore_case = true
buffer.auto_c_drop_rest_of_word = true
buffer.auto_c_multi = buffer.MULTIAUTOC_EACH
view.auto_c_max_height = 11



local okStr = function(str)
    return str and (string.len(str) > 0)
end


local clearDbgBufs = function()
    for idx, buf in ipairs(_BUFFERS) do
        if not okStr(buf.filename) then
            buf:clear_all()
            buf:set_save_point()
        end
    end
end



events.connect(events.INITIALIZED, function()
    -- hide top menu bar
    textadept.menu.menubar = nil

    -- style the programmatic-output buffers
    local ensuredbgbufstyles = function()
        if buffer.filename and string.len(buffer.filename) > 0 then
            return
        end
        buffer.zoom = -3
        if buffer:get_lexer() ~= "dbgbuf" then
            buffer:set_lexer("dbgbuf")
        end
    end
    events.connect(events.BUFFER_AFTER_SWITCH, ensuredbgbufstyles)
    events.connect(events.VIEW_AFTER_SWITCH, ensuredbgbufstyles)

    ui.goto_view(1)
    for idx, buf in ipairs(_BUFFERS) do
        if not buf.filename then
            buf:clear_all()
            local buftype = buf._type or ""
            buf:append_text("|" .. string.sub(buftype, 2, #buftype - 1) .. "|\n" .. string.rep("—", #buftype) .. "\n")
            buf:set_save_point()
        end
    end
    ui.goto_view(1)
end)



--local set_title = function()
--    buffer.tab_label = "Foo Bar"
--end
--events.connect(events.SAVE_POINT_REACHED, set_title)
--events.connect(events.SAVE_POINT_LEFT, set_title)
--events.connect(events.BUFFER_AFTER_SWITCH, set_title)
--events.connect(events.VIEW_AFTER_SWITCH, set_title)



-- custom commands / menu items
local menucmd_closeothers = {'Close All Others', function()
    if okStr(buffer.filename) then
        for idx, buf in ipairs(_BUFFERS) do
            if okStr(buf.filename) and buf.filename ~= buffer.filename then
                buf:close()
            end
        end
    end
end}
local menucmd_copyfullpath = {'Copy Full File Path', function()
    if okStr(buffer.filename) then
        ui.clipboard_text = buffer.filename
    end
end}
local menucmd_foldcollapse = {'Collapse All Folds', function()
    view:fold_all(view.FOLDACTION_CONTRACT)
end}
local menucmd_foldexpand = {'Expand All Folds', function()
    view:fold_all(view.FOLDACTION_EXPAND)
end}
local menucmd_cleardbgbufs = {'Clear DbgBufs', clearDbgBufs}
local toolsmenu = textadept.menu.menubar[_L['Tools']]
toolsmenu[#toolsmenu + 1] = menucmd_cleardbgbufs
for i, menucmd in ipairs({ menucmd_closeothers, menucmd_copyfullpath, menucmd_foldcollapse, menucmd_foldexpand }) do
    toolsmenu[#toolsmenu + 1] = menucmd
    textadept.menu.context_menu[#textadept.menu.context_menu + 1] = menucmd
    textadept.menu.tab_context_menu[#textadept.menu.tab_context_menu + 1] = menucmd
end



-- status bar: show stats of selection. if nothing else, show full file path.
-- (also highlight all current-selection occurrences since we're gathering them anyway)
events.connect(events.UPDATE_UI, function(upd)
    if (not okStr(ui.statusbar_text)) and buffer and okStr(buffer.filename) and (not ui.find.active) then
        local idx = _BUFFERS[buffer]
        ui.statusbar_text = buffer.filename
    end
    if ((upd & buffer.UPDATE_SELECTION) == buffer.UPDATE_SELECTION) then
        buffer.indicator_current = textadept.editing.INDIC_HIGHLIGHT
        buffer:indicator_clear_range(1, buffer.length)
        local charcount = buffer:count_characters(buffer.selection_start, buffer.selection_end)
        local linecount = buffer:line_from_position(buffer.selection_end) - buffer:line_from_position(buffer.selection_start) + 1
        if buffer.char_at[buffer:position_before(math.max(buffer.selection_start, buffer.selection_end))] == 10 then
            linecount = linecount - 1
        end
        if charcount > 2 or linecount > 2 then
            local seltxt, seltxtl, buftxt, buftxtl = buffer:get_sel_text(), string.lower(buffer:get_sel_text()), buffer:get_text(), string.lower(buffer:get_text())
            local occurs, occursl, idx, idxl = 0, 0, string.find(buftxt, seltxt, 1, 'plain'), string.find(buftxtl, seltxtl, 1, 'plain')
            while (idx and idx > 0) or (idxl and idxl > 0) do
                if (idx and idx > 0) then
                    occurs = occurs + 1
                    buffer:indicator_fill_range(idx, string.len(seltxt))
                    idx = string.find(buftxt, seltxt, idx + 1, 'plain')
                end
                if (idxl and idxl > 0) then
                    occursl = occursl + 1
                    idxl = string.find(buftxtl, seltxtl, idxl + 1, 'plain')
                end
            end
            ui.statusbar_text = charcount.." chars"..(linecount > 1 and (", "..linecount.." lines") or "")..((occursl > 1) and (", "..occurs.."× ("..occursl.."×)") or "")
        end
    end
end)



--view.mouse_dwell_time = 777
----hover-tips on mouse-dwell
--events.connect(events.DWELL_START, textadept.editing.show_documentation)
----dismiss same on mouse-undwell
--events.connect(events.DWELL_END, view.call_tip_cancel)



-- switch back and forth between the 2 most recent tabs/buffers
local lastbuf
local onBuf = function(buf)
    if buffer and okStr(buffer.filename) then -- remember we DO want buffer here, not buf
        lastbuf = buffer
    end
end
events.connect(events.BUFFER_BEFORE_SWITCH, onBuf)
events.connect(events.BUFFER_NEW, onBuf)



-- to allow reopening "most-recently closed files"
local openfilenames = {}
local recentlyclosedfilenames = {}
refreshOpenFileNames = function()
    local filenames = {}
    for idx, buf in ipairs(_BUFFERS) do
        if buf and okStr(buf.filename) then
            table.insert(filenames, buf.filename)
            local found = -1
            for i, fn in ipairs(recentlyclosedfilenames) do
                if buf.filename == fn then
                    found = i
                    break
                end
            end
            if found > -1 then
                table.remove(recentlyclosedfilenames, found)
            end
        end
    end
    for idx, filename in ipairs(openfilenames) do
        local found = false
        for i, fn in ipairs(filenames) do
            if filename == fn then
                found = true
                break
            end
        end
        if not found then
            table.insert(recentlyclosedfilenames, filename)
        end
    end
    openfilenames = filenames
end
events.connect(events.FILE_OPENED, refreshOpenFileNames)
events.connect(events.BUFFER_DELETED, refreshOpenFileNames)



-- for alt+1 ... alt+9 to move to buffer/tab at the specified position index
local gotoBuffer = function(nr)
    local numbufs = #_BUFFERS - msgbufs
    if numbufs <= 1 then return end
    local curnr = _BUFFERS[buffer] - msgbufs
    if nr > numbufs then
        nr = numbufs
    elseif nr == -1 then
        nr = curnr - 1
    elseif nr == 0 then
        nr = curnr + 1
    end
    if nr < 1 then
        nr = numbufs
    elseif nr > numbufs then
        nr = 1
    end

    nr = msgbufs + nr
    if #_BUFFERS < nr then
        nr = #_BUFFERS
    end
    view:goto_buffer(_BUFFERS[nr])
end



-- lang-specific stuff
textadept.file_types.extensions.dummy = 'dummy'
lsp_adept.lang_servers.dummy = {cmd = 'dummylangserver'}
if go_adept then
    lsp_adept.lang_servers.go = {cmd = 'gopls'}
else
    lsp_cmp.server_commands.go = 'gopls'
end
local onBuildOrRun = function(str)
    clearDbgBufs()
    ui.print("")
    ui.goto_view(1)
    return str
end
textadept.run.compile_commands.go = function()
    return onBuildOrRun('go install')
end
textadept.run.run_commands.go = function()
    return onBuildOrRun('bash -c "go run *.go"')
end
events.connect(events.FILE_BEFORE_SAVE, function(filename)
    if buffer:get_lexer() ~= 'go' then
        return
    end
    local gopath = os.getenv("GOPATH")
    local tabs2spaces = false -- okStr(filename) and okStr(gopath) and (string.len(filename) > string.len(gopath)) and (string.sub(filename, 1, string.len(gopath)) == gopath)
    local cmd = "gofmt"
    if tabs2spaces then
        cmd = cmd .. " | expand -i -t 4"
    end
    textadept.editing.filter_through(cmd)
end)



-- auto-pair-enclose replacement
local encloseOrPrepend = function(left, right, always_both)
    if not left then
        always_both = true
        local btn, vals = ui.dialogs.inputbox({ title = "Enclose", informative_text = {"Enclose selection(s) within...", "Left:", "Right:"} })
        if okStr(vals[1]) and okStr(vals[2]) then
            left, right = vals[1], vals[2]
        else
            return
        end
    end
    if not buffer.selection_empty then
        textadept.editing.enclose(left, right, true)
    else
        local next = string.byte(buffer:get_text(), buffer.current_pos)
        local prev = (buffer.current_pos > 1) and string.byte(buffer:get_text(), buffer:position_before(buffer.current_pos)) or 0
        local both = (next == 32) or (next == 44) or (next == 59) or (next == 10) or (next == 13) or (next == 9) or (next == 41) or (next == 93) or (next == 125)
        both = both and not ((prev ~= 0) and (left == right) and (string.len(left) == 1) and (prev == string.byte(left, 1)))
        buffer:begin_undo_action()
        for i = 1, buffer.selections do
            local i1, i2 = buffer.selection_n_start[i], buffer.selection_n_end[i]
            local str = (both or always_both) and (left..right) or left
            buffer:set_target_range(i1, i2)
            buffer:replace_target(str)
            buffer.selection_n_start[i] = buffer.target_start + string.len(left)
            buffer.selection_n_end[i] = buffer.target_start + string.len(left) -- yes needs to be duplicate, seems like "live-values" or sth...
        end
        buffer:end_undo_action()
    end
end
keys["ctrl+e"] = encloseOrPrepend
keys["'"] = function() encloseOrPrepend("'", "'") end
keys['"'] = function() encloseOrPrepend('"', '"') end
keys['`'] = function() encloseOrPrepend('`', '`') end
keys['('] = function() encloseOrPrepend('(', ')') end
keys['['] = function() encloseOrPrepend('[', ']') end
keys['{'] = function() encloseOrPrepend('{', '}') end




keys['alt+1'] = function() gotoBuffer(1) end
keys['alt+2'] = function() gotoBuffer(2) end
keys['alt+3'] = function() gotoBuffer(3) end
keys['alt+4'] = function() gotoBuffer(4) end
keys['alt+5'] = function() gotoBuffer(5) end
keys['alt+6'] = function() gotoBuffer(6) end
keys['alt+7'] = function() gotoBuffer(7) end
keys['alt+8'] = function() gotoBuffer(8) end
keys['alt+9'] = function() gotoBuffer(9) end
keys['alt+0'] = function() gotoBuffer(#_BUFFERS) end
keys['ctrl+\t'] = function()
    local numbufs = #_BUFFERS - msgbufs
    if numbufs <= 1 then return end
    if lastbuf and _BUFFERS[lastbuf] and lastbuf ~= buffer then
        view:goto_buffer(lastbuf)
    else
        gotoBuffer((_BUFFERS[buffer] == #_BUFFERS) and -1 or 0)
    end
end
keys['ctrl+shift+\t'] = function()
    ui.switch_buffer(true)
end
keys['ctrl+pgup'] = function() gotoBuffer(-1) end
keys['ctrl+pgdn'] = function() gotoBuffer(0) end
keys['ctrl+T'] = function()
    if #recentlyclosedfilenames > 0 then
        io.open_file(recentlyclosedfilenames[#recentlyclosedfilenames])
    end
end
keys['ctrl+S'] = io.save_all_files
keys['ctrl+p'] = textadept.editing.select_paragraph
keys['ctrl+.'] = ui.command_entry.run
keys['ctrl+_'] = textadept.editing.toggle_comment
keys['alt+f1'] = textadept.menu.select_command
keys['alt+left'] = textadept.history.back
keys['alt+right'] = textadept.history.forward
keys['ctrl++'] = view.zoom_in
keys['ctrl+U'] = buffer.upper_case
keys['ctrl+L'] = buffer.lower_case
keys['ctrl+m'] = function()
    local sixth = screenwidth / 6
    view.size = (view.size <= sixth) and (sixth * 5) or sixth
end
keys['ctrl+g'] = function()
    textadept.history.record()
    textadept.editing.goto_line()
end
keys['ctrl+D'] = buffer.line_duplicate
keys['ctrl+d'] = function()
    local seltxt = buffer:get_sel_text()
    textadept.editing.select_word()
    if not okStr(seltxt) then
        ui.find.find_entry_text = buffer:get_sel_text()
    end
end
keys['ctrl+b'] = textadept.run.compile
keys['f5'] = textadept.run.run
keys['ctrl+R'] = buffer.reload
keys['ctrl+r'] = reset
--keys['ctrl+O'] = lsp.goto_symbol
--keys['ctrl+t'] = function()
--    local btn, query = ui.dialogs.inputbox({title = 'LSP Query:',  text = '' })
--    if okStr(query) and (btn == 1) then
--        lsp.goto_symbol(query)
--    end
--end
keys['f1'] = function()
    if lsp_adept.pertinent() then
        lsp_adept.features.textDocument.hover.show()
    elseif buffer:get_lexer(true) == "go" and not go_adept then
        lsp_cmp.hover()
    else
        textadept.editing.show_documentation()
    end
end
keys['ctrl+,'] = function()
    ui.goto_view(1)
end
--keys['shift+f12'] = function()
--    clearDbgBufs()
--    lsp.find_references()
--end
--keys['f12'] = function()
--    textadept.history.record()
--    if not lsp.goto_definition() then
--        if not lsp.goto_implementation() then
--            if not lsp.goto_type_definition() then
--                lsp.goto_declaration()
--            end
--        end
--    end
--end
keys['ctrl+f'] = function()
    ui.find.find_entry_text = buffer:get_sel_text()
    ui.find.focus({ incremental = true })
end
keys['\b'] = function()
    local next = string.byte(buffer:get_text(), buffer.current_pos) or 0
    local prev = (buffer.current_pos > 1) and string.byte(buffer:get_text(), buffer:position_before(buffer.current_pos)) or 0
    if (next == 125 and prev == 123) or (next == 93 and prev == 91) or (next == 41 and prev == 40) or (next == 96 and prev == 96) or (next == 34 and prev == 34) or (next == 39 and prev == 39) then
        buffer:delete_range(buffer:position_before(buffer.current_pos), 2)
    else
        buffer:delete_back()
    end
end
keys['ctrl+shift+del'] = clearDbgBufs
keys['ctrl+\b'] = function()
    local pos = buffer.current_pos
    local line = buffer:line_from_position(pos)
    if pos <= buffer.line_indent_position[line] then
        local txtpre = buffer:get_text()
        buffer:del_line_left()
        if txtpre == buffer:get_text() then
            buffer:delete_back()
        end
    else
        buffer:del_word_left()
    end
end

keys['ctrl+ '] = function()
    local name = buffer:get_lexer()
    textadept.editing.autocomplete((name == "go" or name == "dummy") and "lsp_adept" or (okStr(name) and name or "word"))
end
