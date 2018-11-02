local me = {}

local favdirs = require 'metaleap_zentient.favdirs'

keys['f1'] = {}
me.langProgs = {}
me.favDirs = {}

function me.startUp()
    favdirs.init(me.favDirs)
end

return me
