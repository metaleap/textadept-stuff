local json = require('ta_lsp.dkjson')

local Server = {}

function Server.new(lang, desc)
    local me = {lang = lang, desc = desc, _reqid = 0}
    Server.ensureProc(me)
    return me
end

function Server.log(me, msg)
    if msg then
        local cur_view = view
        ui._print('[LSP]', '['..me.lang..']\t'..msg)
        ui.goto_view(cur_view)
        ui.statusbar_text = msg
    end
end

function Server.chk(me)
    if me.proc and me.proc:status() == 'terminated' then
        me.proc = nil
    end
    return me.proc
end

function Server.ensureProc(me)
    local err
    if not Server.chk(me) then
        me._reqid = 0
        me.proc, err = os.spawn(me.desc.cmd, me.desc.cwd or lfs.currentdir(),
                                Server.onStdout(me), Server.onStderr(me), Server.onExit(me))
        if err then
            Server.die(me)
            Server.log(me, err)
        end
        if me.proc then
            Server.log(me, me.proc:status())
        end
    end
    return Server.chk(me)
end

function Server.die(me)
    if me.proc then
        pcall(function() me.proc:close() end)
        pcall(function() me.proc:kill() end)
        me.proc = nil
    end
end

function Server.onExit(me) return function(exitcode)
    Server.log(me, "exited: "..exitcode)
    Server.die(me)
end end

function Server.onStderr(me) return function(data)
    Server.log(me, data)
end end

function Server.onStdout(me) return function(data)
    Server.onIncomingRaw(me, data)
end end

function Server.onIncomingRaw(me, data)
    Server.log(me, data)
end

function Server.sendRaw(me, data)
    if Server.ensureProc(me) then
        local ok, err = me.proc:write(data)
        if (not ok) and err and string.len(err) > 0 then
            Server.die(me)
            Server.log(me, err)
            -- the below, via ensureProc, will restart server, which sends init stuff before ours. (they do crash sometimes, or pipes break..)
            Server.sendRaw(me, data)
        end
    end
end

function Server.sendRequest(me, method, params)
    me._reqid = me._reqid + 1
end



return Server
