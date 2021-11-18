local json = require('ta_lsp.dkjson')

local Server = {
}

function method(me, fn)
    return function(...) fn(me, ...) end
end

function Server.new(lang, desc)
    local me = { lang = lang }

    onstdout = function()  end
    onstderr = function()  end
    onexit = function()  end
    me.proc = assert(os.spawn(desc.cmd, desc.cwd, desc.env, onstdout, onstderr, onexit))
    Server.log(me, me.proc:status())
    return me
end

function Server.log(me, msg)
    local cur_view = view
    ui._print('[LSP]', '['..me.lang..']\t'..msg)
    ui.goto_view(cur_view)
end

return Server
