local json = require('ta_lsp.dkjson')

local Server = { log_rpc = true, allow_markdown_docs = true }

local jobj = json.decode('{}') -- plain lua {}s would mal-encode into json []s
local msgicons = {"gtk-dialog-error", "gtk-dialog-warning", "gtk-dialog-info", "gtk-dialog-info", "gtk-dialog-question"}
local inreqs_ignore, inreqs_todo, notifs_ignore = {}, {}, {}
inreqs_todo['client/registerCapability'] = 1
notifs_ignore['telemetry/event'] = 1

function Server.new(lang, desc)
    local me = {lang = lang, desc = desc, server = { caps = nil, name = lang .. " LSP `" .. desc.cmd .. "`" }}
    Server.ensureProc(me)
    return me
end

function setStatusBarText(text)
    ui.statusbar_text = string.gsub(string.gsub(text, "\r", ""), "\n", " — ")
end

function Server.showMsgBox(me, text, level)
    setStatusBarText(text)
    ui.dialogs.msgbox({ title = me.server.name, text = text, icon = level and msgicons[level] or nil })
end

function Server.log(me, msg)
    if msg then
        local cur_view = view
        ui._print('[LSP]', os.date():sub(17,25)..'['..me.lang..']\t'..msg)
        ui.goto_view(cur_view)
        setStatusBarText(msg)
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
        me.proc, err = os.spawn(me.desc.cmd, me.desc.cwd or lfs.currentdir(),
                                Server.onStdout(me), Server.onStderr(me), Server.onExit(me))
        if err then
            Server.die(me)
            Server.log(me, err)
        end
        if me.proc then
            Server.log(me, me.proc:status())
            local resp = Server.sendRequest(me, 'initialize', {
                processId = json.null, rootUri = json.null,
                initializationOptions = me.desc.init_options or json.null,
                capabilities = {
                    window = {showMessage = jobj},
                    workspace = jobj,
                    textDocument = {
                        hover = { contentFormat = Server.allow_markdown_docs and { 'markdown', 'plaintext' } or { 'plaintext' } }
                    }
                }
            })
            Server.sendNotify(me, 'initialized', jobj)
            if resp and resp.result then
                me.server.caps = resp.result.capabilities
                if resp.result.serverInfo and resp.result.serverInfo.name and #resp.result.serverInfo.name > 0 then
                    me.server.name = resp.result.serverInfo.name
                end
            end
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
    Server.onIncomingData(me, data)
    Server.processInbox(me)
end end

function jRpcErr(msg)
    return {code = -32603, message = msg}
end

function parseContentLength(str)
    local pos = string.find(str, "Content-Length:", 1, 'plain')
    if not pos then
        return
    end
    local numpos = pos + #"Content-Length:"
    local rnpos = string.find(str, "\r", numpos, 'plain')
    if not rnpos then
        return
    end
    return tonumber(string.sub(str, numpos, rnpos))
end

function Server.sendMsg(me, msg, addreqid)
    if Server.ensureProc(me) then
        if addreqid then
            me._reqid = me._reqid + 1
            msg.id = me._reqid
        end
        local data = json.encode(msg)
        if Server.log_rpc then
            Server.log(me, ">>>>" .. data)
        end
        local ok, err = me.proc:write("Content-Length: "..(#data+2).."\r\n\r\n"..data.."\r\n")
        if (not ok) and err and #err > 0 then
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

function Server.sendResponse(me, reqid, result, error)
    Server.sendMsg(me, {jsonrpc = '2.0', id = reqid, result = result, error = error})
end

function Server.sendRequest(me, method, params)
    local resp, reqid = nil, Server.sendMsg(me, {jsonrpc = '2.0', method = method, params = params}, true)
    while not resp do
        local accum, posrn = "", nil
        while (not posrn) and Server.ensureProc(me) do
            local chunk = me.proc:read("L")
            if (not chunk) then
                break
            else
                accum = accum .. chunk
                posrn = string.find(accum, "\r\n\r\n", 1, 'plain')
            end
        end
        if posrn then
            local posdata = posrn + 4
            local numbytesgot = #accum - (posdata - 1)
            local clen = parseContentLength(string.sub(accum, 1, posn1))
            if clen then
                local tail = me.proc:read(clen - numbytesgot)
                if tail then
                    local data = string.sub(accum, posdata) .. tail
                    Server.pushToInbox(me, data)
                    resp = Server.processInbox(me, reqid)
                end
            end
        end
    end
    return resp
end

function Server.onIncomingData(me, incoming)
    if not incoming then
        return
    end
    me._data = me._data .. incoming
    while true do
        local pos = string.find(me._data, "Content-Length:", 1, 'plain')
        if not pos then
            break
        end
        local numpos = pos + #"Content-Length:"
        local rnpos = string.find(me._data, "\r", numpos, 'plain')
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
        datapos = datapos + #"\r\n\r\n"
        local data = string.sub(me._data, datapos, (datapos + clen) - 1)
        if (not data) or #data < clen then
            break
        end
        me._data = string.sub(me._data, datapos + clen)
        Server.pushToInbox(me, data)
    end
end

function Server.pushToInbox(me, data)
    if Server.log_rpc then
        Server.log(me, "<<<<" .. data)
    end
    local msg, errpos, errmsg = json.decode(data)
    if msg then
        me._inbox[1 + #me._inbox] = msg
    end
    if errmsg and #errmsg > 0 then
        Server.log(me, "UNJSON: '" .. errmsg .. "' at pos " .. errpos .. 'in: ' .. data)
        Server.showMsgBox(me, 'Bad JSON, check LSP log', 2)
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
            if waitreqid and msg.id == waitreqid then
                return msg
            end
            keeps[1 + #keeps] = msg
        else
            Server.showMsgBox(me, "JSONRPCWOT:"..json.encode(msg), 1)
        end
    end
    me._inbox = keeps
end

function Server.onIncomingNotification(me, msg)
    if msg.params and msg.method == "window/showMessage" and msg.params.message then
        Server.showMsgBox(me, msg.params.message, msg.params.type or 5)
    elseif msg.params and msg.method == "window/logMessage" and msg.params.message then
        Server.log(me, "LOGIT:\t" .. msg.params.message)
    elseif not notifs_ignore[msg.method] then
        Server.log(me, "NOTIF:\t"..json.encode(msg))
        Server.showMsgBox(me, msg.method, 5)
    end
end

function Server.onIncomingRequest(me, msg)
    local known = inreqs_ignore[msg.method] or inreqs_todo[msg.method]
    Server.sendResponse(me, msg.id, nil, jRpcErr("That's not on."))
    if not known then
        Server.log(me, "INREQ:\t" .. json.encode(msg))
        Server.showMsgBox(me, msg.method, 5)
    end
end



return Server
