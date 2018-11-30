local zcaddies = {}

local util = require 'metaleap_zentient.util'

local CaddyStatus_PENDING = 0
local CaddyStatus_ERROR = 1
local CaddyStatus_BUSY = 2
local CaddyStatus_GOOD = 3

local caddyMenus = {}


function zcaddies.on(caddyMsg)
    local menuid = caddyMsg.LangID .. '__' .. caddyMsg.ID
    local menu = caddyMenus(menuid)
    if not menu then
        menu = { menu = { title = caddyMsg.Icon }, pos = 1 + #textadept.menu.menubar }
    end
    if caddyMsg.Status and caddyMsg.Status.Flag ~= CaddyStatus_GOOD then
    end
end



return zcaddies
