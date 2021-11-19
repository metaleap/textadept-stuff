local json = require('ta_lsp.dkjson')

local Server = { log_rpc = true, allow_markdown_docs = true }

function Server.new(lang, desc)
    local me = {lang = lang, desc = desc}
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
        me._reqid, me._initRecv, me._data, me._inbox = 0, false, "", {}
        me.proc, err = os.spawn(me.desc.cmd, me.desc.cwd or lfs.currentdir())--,
                                --Server.onStdout(me), Server.onStderr(me), Server.onExit(me))
        if err then
            Server.die(me)
            Server.log(me, err)
        end
        if me.proc then
            Server.log(me, me.proc:status())
            local result = Server.sendRequest(me, 'initialize', {
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
            Server.log(me, "INITRESP:" .. json.encode(result))
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
    --Server.onIncomingData(me, data)
    --Server.processInbox(me)
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
    local reqid = Server.sendMsg(me, {jsonrpc = '2.0', method = method, params = params}, true)
    local data = ""
    while Server.ensureProc(me) do
        local chunk = me.proc:read("L")
        if (not chunk) then
            break
        end
        data = data .. chunk
    end
    Server.onIncomingData(me, data)
    return Server.processInbox(me, reqid)
end

function Server.onIncomingData(me, data)
    me._data = me._data .. data
    while true do
        local pos = string.find(me._data, "Content-Length: ", idx, 'plain')
        if not pos then
            break
        end
        local numpos = pos + string.len("Content-Length: ")
        local rnpos = string.find(me._data, "\r\n", numpos, 'plain')
        if not rnpos then
            break
        end
        local clen = tonumber(string.sub(me._data, numpos, rnpos))
        if (not clen) or clen < 2 then
            me._data = string.sub(me._data, rnpos)
            break
        end
        local datapos = string.find(me._data, "\r\n\r\n", numpos, 'plain')
        if not datapos then
            break
        end
        datapos = datapos + string.len("\r\n\r\n")
        local data = string.sub(me._data, datapos, datapos + clen)
        if (not data) or string.len(data) < clen then
            break
        end
        idx, me._data = 1, string.sub(me._data, datapos + clen)
        local msg, errpos, errmsg = json.decode(data)
        if msg then
            me._inbox[1 + #me._inbox] = msg
        end
        if errmsg and string.len(errmsg) > 0 then
            Server.log(me, "UNJSON: '" .. errmsg .. "' at pos " .. errpos .. 'in: ' .. data)
            ui.dialogs.msgbox({text = 'Bad JSON, check LSP log'})
        end
    end
end

function Server.processInbox(me, waitreqid)
    local keeps = {}
    while #me._inbox > 0 do
        local msg = table.remove(me._inbox, 1)
        if msg.id and msg.method then
            Server.onIncomingRequest(me, msg)
        elseif msg.method then
            Server.onIncomingNotification(me, msg)
        elseif msg.id then
            if msg.id == waitreqid then
                return msg
            end
            keeps[1 + #keeps] = msg
        end
    end
    me._inbox = keeps
end

function Server.onIncomingNotification(me, msg)
    Server.log(me, "NOTIF: " .. msg.method)
end

function Server.onIncomingRequest(me, msg)
    Server.log(me, "INREQ: " .. msg.method)
end



return Server
