local zcaddies = {}

local util = require 'metaleap_zentient.util'



local CaddyStatus_PENDING = 0
local CaddyStatus_ERROR = 1
local CaddyStatus_BUSY = 2
local CaddyStatus_GOOD = 3

local caddyMenus = {}


function zcaddies.on(caddyMsg)
    local menuupd, menuid = false, caddyMsg.LangID .. '__' .. caddyMsg.ID
    local cm = caddyMenus[menuid]
    if not cm then
        cm = { menu = { title = '?' }, pos = 1 + #textadept.menu.menubar }
        util.uxMenuAddBackItem(cm.menu, false, nil)
        caddyMenus[menuid] = cm
        menuupd = true
    end
    if caddyMsg.Status then
        local nutitle = cm.menu.title
        if caddyMsg.Status.Flag == CaddyStatus_PENDING then
            nutitle = ''
        elseif caddyMsg.Status.Flag == CaddyStatus_ERROR then
            nutitle = ''
        elseif caddyMsg.Status.Flag == CaddyStatus_BUSY then
            nutitle = ''
        elseif caddyMsg.Status.Flag == CaddyStatus_GOOD then
            nutitle = caddyMsg.Icon
        end
        if nutitle ~= cm.menu.title then
            cm.menu.title = nutitle
            menuupd = true
        end
    end
    if menuupd then
        textadept.menu.menubar[cm.pos] = cm.menu
    end
end



return zcaddies
