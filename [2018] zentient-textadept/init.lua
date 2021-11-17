local me = {}



local util = require 'metaleap_zentient.util'
local ux = require 'metaleap_zentient.ux'
local favdirs = require 'metaleap_zentient.favdirs'
local favcmds = require 'metaleap_zentient.favcmds'
local notify = require 'metaleap_zentient.notify'
local srcmod = require 'metaleap_zentient.srcmod'
local z = require 'metaleap_zentient.z'


me.langProgs = {}
me.favCmds = {}
me.favDirs = {}


function me.startUp()
    ux.init()
    favdirs.init(me.favDirs)
    favcmds.init(me.favCmds)
    notify.init()
    srcmod.init()
    z.init(me.langProgs)
end


events.connect(events.INITIALIZED, me.startUp)



return me
