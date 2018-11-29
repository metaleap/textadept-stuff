local zmenus = {}



local menuPosMain, menuPosIntel, menuPosQuery
local menuMain, menuIntel, menuQuery


function zmenus.init()
    menuPosMain, menuPosIntel, menuPosQuery = 1 + #textadept.menu.menubar, 2 + #textadept.menu.menubar, 3 + #textadept.menu.menubar
    menuMain, menuIntel, menuQuery = { title = '  ' }, { title = '' }, { title = '' }
    textadept.menu.menubar[menuPosMain] = menuMain
    textadept.menu.menubar[menuPosIntel] = menuIntel
    textadept.menu.menubar[menuPosQuery] = menuQuery
end



return zmenus
