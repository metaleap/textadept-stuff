local zentient = {}

local ipc = require 'metaleap_zentient.z.ipc'



function zentient.init(langProgs)
    ipc.init(langProgs)
end



return zentient
