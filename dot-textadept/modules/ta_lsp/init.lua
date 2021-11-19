local server = require('ta_lsp.server')

local M = {
    log_rpc = false,
    servers = { -- eg:
        --go = {cmd = 'gopls'}
    }
}



function M.ensureRunning(lang)
    if not (M.servers[lang] and M.servers[lang].cmd) then
        return nil
    end
    if not M.servers[lang]._ then
        M.servers[lang].log_rpc = M.log_rpc
        M.servers[lang]._ = server.new(lang, M.servers[lang])
    end
    return M.servers[lang]._
end



return M
