local me = {}



local ux = require 'metaleap_zentient.ux'
local favdirs = require 'metaleap_zentient.favdirs'
local favcmds = require 'metaleap_zentient.favcmds'


me.langProgs = {}
me.favCmds = {}
me.favDirs = {}


function me.startUp()
    ux.init()
    keys.cao = favdirs.init(me.favDirs)
    favcmds.init(me.favCmds)
end



return me
