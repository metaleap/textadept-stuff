local notify = {}

local util = require 'metaleap_zentient.util'



notify.EVENT = "metaleap_zentient.EVENT_NOTIFY"

local menu


local function ensureMenu()
    textadept.menu.menubar[4] = menu
end


local function clearMenu()
    menu = { title = '' }
    menu[1 + #menu] = { '(Clear)', clearMenu }
end


local function showDetails(msg)
    ui.print(msg)
end


function notify.emit(msg)
    events.emit(notify.EVENT, msg)
end


function notify.init()
    clearMenu()

    events.connect(notify.EVENT, function(msg)
        ui.print(msg)
        menu.title = ' '..msg
        table.insert(menu, 1, { util.menuable(msg), function() showDetails(msg) end })
    end)

    ensureMenu()
end



return notify
