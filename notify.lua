local notify = {}

local util = require 'metaleap_zentient.util'



local menu


local function ensureMenu()
    textadept.menu.menubar[4] = menu
end


local function clearMenu()
    menu = { title = '' }
    menu[1 + #menu] = { '(Clear)', clearMenu }
    menu[1 + #menu] = { '(Close)', function() end }
    ensureMenu()
end


local function showDetails(msg)
    ui.print(msg)
end


function notify.emit(msg)
    menu.title = ' '..util.menuable(msg)
    table.insert(menu, 1, { util.menuable(os.date("[ %H:%M:%S ]\t")..msg), function() showDetails(msg) end })
    ensureMenu()
end


function notify.init()
    clearMenu()
end



return notify
