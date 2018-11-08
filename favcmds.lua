local favcmds = {}

local util = require 'metaleap_zentient.util'
local notify = require 'metaleap_zentient.notify'



local menuPos


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
    local tabtitle = util.uxStrNowTime() .. cmdStr
    local stdout, stderr = { lns = {} }, { lns = {} }
    local onstdout = function(ln)
        stdout.lns[1 + #stdout.lns] = ln
        if favCmd.stdout and favCmd.stdout.lnNotify then
            notifyEmit(cmdStr, ln, '')
        end
    end
    local onstderr = function(ln)
        stderr.lns[1 + #stderr.lns] = ln
        local fce = (favCmd.stderr == true) and favCmd.stdout or favCmd.stderr
        if fce and fce.lnNotify then
            notifyEmit(cmdStr, ln, '')
        end
    end
    return onstdout, onstderr
end


local function onCmd(favCmd)
    return function()
        local cmdstr = fillInCmd(favCmd.cmd)
        if #cmdstr > 0 then
            local onstdout, onstderr = cmdState(favCmd, cmdstr)
            local proc = util.osSpawnProc(cmdstr, '\n', onstdout, '\n', onstderr, false, function(errmsg, exitcode)
                notifyDone(cmdstr, nil, exitcode == 0, errmsg or 'exit', exitcode)
            end)
            if proc then
                if favCmd.pipeBufText then proc:write(util.bufSelText(true)) end
                proc:close()
            end
        end
    end
end

local function onSh(favCmd)
    return function()
        local cmd = fillInCmd(favCmd.sh)
        if favCmd.pipeBufText then
            if buffer.filename and buffer.selection_empty and not buffer.modify then
                cmd = "cat '" .. buffer.filename .. "' | " .. cmd
            else
                local src = (util.bufSelText() or buffer:get_text()):gsub("\"", "\\\"")
                cmd = "echo \"" .. src .. "\" | " .. cmd
            end
        end
        if #cmd > 0 then
            local tabtitle = util.uxStrNowTime() .. cmd
            local sh, errmsg, code = io.popen(cmd, 'r')
            if sh then
                local onstdout = cmdState(favCmd, cmd)
                for ln in sh:lines() do onstdout(ln) end
                sh, errmsg, code = sh:close()
            end
            notifyDone(cmd, nil, sh, errmsg, code)
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
        menu[1 + #menu] = { '' }
        menu[1 + #menu] = { '', function() end }
        textadept.menu.menubar[menuPos] = menu
    end
end



return favcmds
