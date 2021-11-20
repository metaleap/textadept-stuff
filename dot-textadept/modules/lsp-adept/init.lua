local common = require('lsp-adept.common')
local server = require('lsp-adept.server')

local LspAdept = {
    log_rpc = true,
    allow_markdown_docs = true,
    lang_servers = { -- eg:
        --go = {cmd = 'gopls'}
    },
    features = {
        textDocument = {
            hover = require('lsp-adept.textDocument-hover')
        }
    }
}


function LspAdept.ensureRunning(lang)
    if not (LspAdept.lang_servers[lang] and LspAdept.lang_servers[lang].cmd) then
        return nil
    end
    if not LspAdept.lang_servers[lang]._ then
        LspAdept.lang_servers[lang].log_rpc = LspAdept.log_rpc
        LspAdept.lang_servers[lang]._ = server.new(lang, LspAdept.lang_servers[lang])
    end
    return LspAdept.lang_servers[lang]._
end


local onShutdown = function()
    server.shutting_down = true
    for langname, it in pairs(LspAdept.lang_servers) do
        if it._ then
            server.sendRequest(it._, 'shutdown', null, true)
            server.sendNotify(it._, 'exit')
            server.die(it._)
        end
        LspAdept.lang_servers[langname]._ = nil
    end
    server.shutting_down = false
end
events.connect(events.RESET_BEFORE, onShutdown)
events.connect(events.QUIT, onShutdown)


common.LspAdept = LspAdept
return LspAdept
