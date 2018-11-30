local zentient = {}

local util = require 'metaleap_zentient.util'
local zipc = require 'metaleap_zentient.z.ipc'
local zmenus = require 'metaleap_zentient.z.menus'
local zcaddies = require 'metaleap_zentient.z.caddies'



local handlers = {}


local function onUnhandledMsg(msg)
    local silent = ui.silent_print
    ui.silent_print = true
    ui._print('Z', util.jsonEncode(msg))
    ui.silent_print = silent
end


local function onAnnounce(msg)
    if msg.caddy then
        zcaddies.on(msg.caddy)
    else
        onUnhandledMsg(msg)
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
