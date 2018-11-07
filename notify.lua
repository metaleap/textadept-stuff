local notify = {}

local util = require 'metaleap_zentient.util'



local menu


local function ensureMenu()
    events.emit(events.KEYPRESS, 0xFF1B)
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
    textadept.menu.menubar.
    menu.title = ' '..msg
    table.insert(menu, 1, { util.menuable(os.date("(%H:%M:%S)\t")..msg), function() showDetails(msg) end })
    ensureMenu()
end


function notify.init()
    clearMenu()
    ensureMenu()
end



return notify
