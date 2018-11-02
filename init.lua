local me = {}

local favdirs = require 'metaleap_zentient.favdirs'
local favcmds = require 'metaleap_zentient.favcmds'
local ux = require 'metaleap_zentient.ux'

keys['f1'] = {}
me.langProgs = {}
me.favCmds = {}
me.favDirs = {}

function me.startUp()
    ux.init()
    favdirs.init(me.favDirs)
    favcmds.init(me.favCmds)
end

return me
