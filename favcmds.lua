local me = {}

local util = require 'metaleap_zentient.util'



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


local function onCmd(favCmd, pipeBufOrSel)
    return function()
        local cmd = fillInCmd(favCmd)
        if #cmd > 0 then
            local line = ''
            local println = function(txt)
                if txt then
                    if txt:sub(-1) == '\n' then
                        ui._print(cmd, line .. txt:sub(1, -2))
                        line = ''
                    else
                        line = line .. txt
                    end
                end
            end
            local proc = os.spawn(cmd, println, println, function(exit)
                if line and #line > 0 then ui._print(cmd, line) end
            end)
            if pipeBufOrSel then
                proc:write(util.bufSelText(true))
            end
            proc:close()
        end
    end
end


local function onSh(favCmd, pipeBufOrSel)
    return function()
        local cmd = fillInCmd(favCmd)
        if pipeBufOrSel then
            if buffer.filename and buffer.selection_empty and not buffer.modify then
                cmd = "cat '" .. buffer.filename .. "' | " .. cmd
            else
                local src = (util.bufSelText() or buffer:get_text()):gsub("\"", "\\\"")
                cmd = "echo \"" .. src .. "\" | " .. cmd
            end
        end
        if #cmd > 0 then
            f = io.popen(cmd, 'r')
            for ln in f:lines() do
                ui.print(ln)
            end
            f:close()
        end
    end
end


function me.init(favCmds)
    if #favCmds > 0 then
        local menu = { title = '' }
        for _, fc in ipairs(favCmds) do
            if fc.sh then
                menu[1 + #menu] = { util.menuable(fc.sh), onSh(fc.sh, fc.pipeBufText) }
            elseif fc.cmd then
                menu[1 + #menu] = { util.menuable(fc.cmd), onCmd(fc.cmd, fc.pipeBufText) }
            end
        end
        textadept.menu.menubar[1 + #textadept.menu.menubar] = menu
    end
end



return me
