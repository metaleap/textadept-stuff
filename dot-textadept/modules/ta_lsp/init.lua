local server = require('ta_lsp.server')

local M = {
    log_rpc = false,
    servers = {
    }
}



function M.ensureRunning(lang)
    if not (M.servers[lang] and M.servers[lang].cmd) then
        return nil
    end
    if (not M.servers[lang]._) or (M.servers[lang]._.dead) then
        M.servers[lang]._ = server.new(lang, M.servers[lang])
    end
    return M.servers[lang]._
end



return M