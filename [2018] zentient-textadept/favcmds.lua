local favcmds = {}

local util = require 'metaleap_zentient.util'
local notify = require 'metaleap_zentient.notify'



local menuPos
local cmdsRunning = {}


local function fillInCmd(cmd)
    local pat = "%§%(([%w_]+)%)"
    local names = {}

    cmd:gsub(pat, function(name)
        names[1 + #names] = name
    end)

    local kvs, predefined = {}, {}
    predefined['_filePath'] = function() return buffer.filename end
    predefined['_fileName'] = function() return util.fsPathBaseName(buffer.filename) end
    predefined['_fileDir'] = function() return util.fsPathParentDir(buffer.filename) end

    for i = #names, 1, -1 do
        for pname, pfunc in pairs(predefined) do
            if names[i] == pname then
                table.remove(names, i)
                kvs[pname] = pfunc()
                break
            end
        end
    end

    if #names > 0 then
        local namesidx, inputbox = {}, { title = cmd, informative_text = { cmd }, text = {}, width = 2345, height = 1234 }
        for _, name in ipairs(names) do
            if not namesidx[name] then
                namesidx[name] = 1 + #inputbox.text
                inputbox.informative_text[1 + #inputbox.informative_text] = name
                inputbox.text[1 + #inputbox.text] = ''
            end
        end
        local button, inputs = ui.dialogs.standard_inputbox(inputbox)
        if button ~= 1 then
            cmd = ""
        else
            if type(inputs) ~= 'table' then
                kvs[names[1]] = inputs
            else
                for _, name in ipairs(names) do
                    kvs[name] = inputs[namesidx[name]]
                end
            end
            cmd = cmd:gsub(pat, function(name)
                return kvs[name]
            end)
        end
    end

    return cmd
end


local function notifyEmit(cmd, msg, cat, action, sep)
    notify.emit('`'..cmd..'`', msg, cat, action, sep)
end


local function notifyDone(cmd, action, success, notice, code)
    notifyEmit(cmd,
                notice .. (code and (' ‹'..tostring(code)..'›') or ''),
                success and '' or '',
                action, true)
end


local function cmdState(favCmd, cmdStr)
    local strnow, stdoutlns, stderrlns = util.uxStrNowTime(), {}, {}
    local ensurebuf = function(e, curln, canopen)
        if canopen == nil then canopen = true end
        local tabtitle = (e and '‹stderr› ' or '‹stdout› ') .. strnow .. cmdStr
        local buf = util.bufBy(nil, nil, tabtitle, false)
        local lns = e and stderrlns or stdoutlns
        if not buf then
            if canopen then
                for _, ln in ipairs(lns) do
                    ui._print(tabtitle, ln)
                end
            end
        elseif curln then
            buf:append_text(curln..'\n')
            buf:set_sel(-1, -1)
        else
            buf:set_text('')
            for _, ln in ipairs(lns) do
                buf:append_text(ln..'\n')
            end
            buf:set_sel(-1, -1)
            view:goto_buffer(buf)
        end
    end
    local action = function(openout, openerr)
        if openout == nil and openerr == nil then
            openout, openerr = #stdoutlns > 0, #stderrlns > 0
        end
        if openout then ensurebuf(false) end
        if openerr then ensurebuf(true) end
    end
    local onstdout = function(ln)
        stdoutlns[1 + #stdoutlns] = ln
        if favCmd.stdout and favCmd.stdout.lnNotify then
            notifyEmit(cmdStr, ln, '', function() action(true, false) end)
        end
        ensurebuf(false, ln, favCmd.stdout and favCmd.stdout.openBuf or false)
    end
    local onstderr = function(ln)
        stderrlns[1 + #stderrlns] = ln
        local fce = (favCmd.stderr == true) and favCmd.stdout or favCmd.stderr
        if fce and fce.lnNotify then
            notifyEmit(cmdStr, ln, '', function() action(false, true) end)
        end
        ensurebuf(true, ln, fce and fce.openBuf or false)
    end
    return onstdout, onstderr, action
end


local function onCmd(favCmd)
    return function()
        local cmdstr = fillInCmd(favCmd.cmd)
        if #cmdstr > 0 then
            local cur = cmdsRunning[cmdstr]
            if cur then
                local btn = ui.dialogs.msgbox{ title = cmdstr, text = "is still running:", button2 = "_Kill", button3 = "_Show" }
                if btn == 2 then
                    cur.kill()
                elseif btn == 3 then
                    cur.show()
                end
                return
            end

            local onstdout, onstderr, action = cmdState(favCmd, cmdstr)
            local proc = util.osSpawnProc(cmdstr, '\n', onstdout, '\n', onstderr, function(errmsg, exitcode)
                cmdsRunning[cmdstr] = nil
                notifyDone(cmdstr, action, exitcode == 0, errmsg or 'exit', exitcode)
            end)
            if proc then
                cmdsRunning[cmdstr] = { show = action, kill = function() proc:kill() end }
                if favCmd.stdin then proc:write(util.bufSelText(true)) end
                proc:close()
            end
        end
    end
end

local function onSh(favCmd)
    return function()
        local cmdstr = fillInCmd(favCmd.sh)
        if favCmd.stdin then
            if buffer.filename and buffer.selection_empty and not buffer.modify then
                cmdstr = "cat '" .. buffer.filename .. "' | " .. cmdstr
            else
                local src = (util.bufSelText() or buffer:get_text()):gsub("\"", "\\\"")
                cmdstr = "echo \"" .. src .. "\" | " .. cmdstr
            end
        end
        if #cmdstr > 0 then
            local sh, errmsg, code = io.popen(cmdstr, 'r')
            local onstdout, _unused, action
            if sh then
                onstdout, _unused, action = cmdState(favCmd, cmdstr)
                for ln in sh:lines() do onstdout(ln) end
                sh, errmsg, code = sh:close()
            end
            notifyDone(cmdstr, action, sh, errmsg, code)
        end
    end
end


function favcmds.init(favCmds)
    menuPos = 1 + #textadept.menu.menubar

    if #favCmds > 0 then
        local menu = { title = '' }
        for _, fc in ipairs(favCmds) do
            if fc.sh then
                menu[1 + #menu] = { util.uxStrMenuable(fc.sh), onSh(fc) }
            elseif fc.cmd then
                menu[1 + #menu] = { util.uxStrMenuable(fc.cmd), onCmd(fc) }
            end
        end
        util.uxMenuAddBackItem(menu, true, nil)
        textadept.menu.menubar[menuPos] = menu
    end
end



return favcmds
