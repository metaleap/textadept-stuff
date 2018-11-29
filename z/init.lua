local zentient = {}

local json = require 'metaleap_zentient.vendor.dkjson'
local zipc = require 'metaleap_zentient.z.ipc'
local zmenus = require 'metaleap_zentient.z.menus'
local zcaddies = require 'metaleap_zentient.z.caddies'



local handlers = {}


--local function onUnhandledMsg(msg)
    --local silent = ui.silent_print
    --ui.silent_print = true
    --ui._print('Z', json.encode(msg))
    --ui.silent_print = silent
--end


local function onAnnounce(msg)
    if msg.caddy then
        zcaddies.on(msg.caddy)
    end
end


zipc.onMsg = function(msg)
    if msg.val and not msg.ii then
        ui.print("open JSON doc: ", msg.val)
    end

    if msg.ri then
        local onresp = handlers[msg.ri]
        handlers[msg.ri] = nil
        if onresp then onresp(msg) end
    else
        onAnnounce(msg)
    end
end


function zentient.init(langProgs)
    zmenus.init()
    zipc.init(langProgs)
end



return zentient
