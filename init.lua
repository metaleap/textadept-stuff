local me = {}



local util = require 'metaleap_zentient.util'
local ux = require 'metaleap_zentient.ux'
local favdirs = require 'metaleap_zentient.favdirs'
local favcmds = require 'metaleap_zentient.favcmds'


me.langProgs = {}
me.favCmds = {}
me.favDirs = {}


function me.startUp()
    keys.esc = function()
        buffer:cancel()
        util.bufClearHighlightedWords()
    end

    ux.init()
    keys.cao = favdirs.init(me.favDirs)
    favcmds.init(me.favCmds)

    -- events.connect(events.UPDATE_UI, function(upd) -- temporary diag
    --     if upd and upd > 4 and upd ~= 8 then
    --         _G.print("unknown UPDATE_UI of "..tostring(upd))
    --     end
    -- end)
end



return me
