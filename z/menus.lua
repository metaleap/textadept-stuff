local zmenus = {}

local util = require 'metaleap_zentient.util'



local menuPosMain, menuPosIntel, menuPosQuery
local menuMain, menuIntel, menuQuery


function zmenus.init()
    menuPosMain, menuPosIntel, menuPosQuery = 1 + #textadept.menu.menubar, 2 + #textadept.menu.menubar, 3 + #textadept.menu.menubar
    menuMain, menuIntel, menuQuery = { title = '' }, { title = '' }, { title = '      ' }
    util.uxMenuAddBackItem(menuMain, false, nil)
    util.uxMenuAddBackItem(menuIntel, false, nil)
    util.uxMenuAddBackItem(menuQuery, false, nil)
    textadept.menu.menubar[menuPosMain] = menuMain
    textadept.menu.menubar[menuPosIntel] = menuIntel
    textadept.menu.menubar[menuPosQuery] = menuQuery
end



return zmenus
