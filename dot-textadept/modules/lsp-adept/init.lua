local server = require('lsp-adept.server')


local M = {
    log_rpc = false,
    lang_servers = { -- eg:
        --go = {cmd = 'gopls'}
    }
}


local onShutdown = function()
    for langname, it in pairs(M.lang_servers) do
        local srv = it._
        M.lang_servers[langname]._ = nil
        if srv then
            server.sendRequest(srv, 'shutdown', null, true)
            server.sendNotify(srv, 'exit')
            server.die(srv)
        end
    end
end
events.connect(events.RESET_BEFORE, onShutdown)
events.connect(events.QUIT, onShutdown)


function M.ensureRunning(lang)
    if not (M.lang_servers[lang] and M.lang_servers[lang].cmd) then
        return nil
    end
    if not M.lang_servers[lang]._ then
        M.lang_servers[lang].log_rpc = M.log_rpc
        M.lang_servers[lang]._ = server.new(lang, M.lang_servers[lang])
    end
    return M.lang_servers[lang]._
end



return M
