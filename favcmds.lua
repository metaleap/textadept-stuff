local me = {}



local function fillInCmd(cmd)
    local pat = "%$%(([%w_]+)%)"
    local names = {}

    cmd:gsub(pat, function(name)
        names[1 + #names] = name
    end)

    if #names > 0 then
        local inputbox = { title = cmd, informative_text = { cmd }, text = {}, width = 2345, height = 1234 }
        for _, name in ipairs(names) do
            inputbox.informative_text[1 + #inputbox.informative_text] = name
            inputbox.text[1 + #inputbox.text] = ''
        end
        local button, inputs = ui.dialogs.standard_inputbox(inputbox)
        if button ~= 1 then
            cmd = ""
        else
            local kvs = {}
            if type(inputs) ~= 'table' then
                kvs[names[1]] = inputs
            else
                for i, name in ipairs(names) do
                    kvs[name] = inputs[i]
                end
            end
            cmd = cmd:gsub(pat, function(name)
                return kvs[name]
            end)
        end
    end

    return cmd
end


local function onCmd(cmd)
    return function()
        cmd = fillInCmd(cmd)
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
        local menu = { title = '  ' }
        for _, favcmd in ipairs(favCmds) do
            menu[1 + #menu] = { favcmd, onCmd(favcmd) }
        end
        textadept.menu.menubar[1 + #textadept.menu.menubar] = menu
    end
end



return me
