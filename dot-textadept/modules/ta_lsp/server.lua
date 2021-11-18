local json = require('ta_lsp.dkjson')

local Server = {}

function Server.new(lang, desc)
    local me = {lang = lang}
    me.proc = assert(os.spawn(desc.cmd, desc.cwd or lfs.currentdir(), desc.env,
                                Server.onStdout(me), Server.onStderr(me), Server.onExit(me)))
    Server.log(me, me.proc:status())
    Server.chk(me)
    return me
end

function Server.log(me, msg)
    local cur_view = view
    ui._print('[LSP]', '['..me.lang..']\t'..msg)
    ui.goto_view(cur_view)
end

function Server.chk(me)
    if me.proc and me.proc:status() == 'terminated' then
        me.proc = nil
    end
end

function Server.die(me, msg)
    if me.proc then
        me.proc:close()
        me.proc:kill()
        me.proc = nil
    end
end

function Server.sendRaw(me, data)
    Server.chk(me)
    if me.proc then
        local ok, err = me.proc:write(data)
        if (not ok) and err and string.len(err) > 0 then
            Server.die(me)
            Server.log(me, msg)
        end
    end
end

local incoming = ""
function Server.onIncomingRaw(me, data)
    Server.log(me, data)
    incoming = incoming .. data
    incoming = ""
end

function Server.onStdout(me) return function(data)
    Server.onIncomingRaw(me, data)
end end

function Server.onStderr(me) return function(data)
    Server.log(me, data)
end end

function Server.onExit(me) return function(exitcode)
    Server.log(me, "exited: "..exitcode)
    me.proc = nil
end end



return Server
