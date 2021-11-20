local json = require('lsp-adept.deps.dkjson')

local Common = {
    LspAdept = nil, -- ./init.lua sets this
    json_empty = json.decode('{}') -- plain lua {}s would mal-encode into json []s
}


return Common
