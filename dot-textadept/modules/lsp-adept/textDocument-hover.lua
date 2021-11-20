local common = require('lsp-adept.common')

local Hover = {
}


Hover.clientCapabilities = function()
    return { contentFormat = common.LspAdept.allow_markdown_docs and { 'markdown', 'plaintext' } or { 'plaintext' } }
end


return Hover
