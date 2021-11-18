local json = require('ta_lsp.dkjson')

local Server = { log_rpc = true, allow_markdown_docs = true }

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
        me._reqid, me._initRecv = 0, false
        me.proc, err = os.spawn(me.desc.cmd, me.desc.cwd or lfs.currentdir(),
                                Server.onStdout(me), Server.onStderr(me), Server.onExit(me))
        if err then
            Server.die(me)
            Server.log(me, err)
        end
        if me.proc then
            Server.log(me, me.proc:status())
            Server.sendRequest(me, 'initialize', {
                processId = json.null, rootUri = json.null,
                initializationOptions = me.desc.init_options or json.null,
                capabilities = {
                    window = {showMessage = {}},
                    workspace = {},
                    textDocument = {
                        hover = { contentFormat = Server.allow_markdown_docs and { 'markdown', 'plaintext' } or { 'plaintext' } }
                    }
                }
            })
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

function Server.sendMsg(me, msg, addreqid)
    if Server.ensureProc(me) then
        if addreqid then
            me._reqid = me._reqid + 1
            msg.id = me._reqid
        end
        local data = json.encode(msg)
        if Server.log_rpc then
            Server.log(me, data)
        end
        local ok, err = me.proc:write("Content-Length: "..(#data+2).."\r\n\r\n"..data.."\r\n")
        if (not ok) and err and string.len(err) > 0 then
            Server.die(me)
            Server.log(me, err)
            -- the below, via ensureProc, will restart server, which sends init stuff before ours. (they do crash sometimes, or pipes break..)
            return Server.sendMsg(me, data)
        end
    end
    return msg.id
end

function Server.sendNotify(me, method, params)
    Server.sendMsg(me, {jsonrpc = '2.0', method = method, params = params})
end

function Server.sendResponse(me, reqid, result)
    Server.sendMsg(me, {jsonrpc = '2.0', id = reqid, result = result})
end

function Server.sendRequest(me, method, params)
    return Server.sendMsg(me, {jsonrpc = '2.0', method = method, params = params}, true)
end

function Server.onIncomingRaw(me, data)
    Server.log(me, data)
end




return Server
