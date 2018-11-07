local notify = {}

local util = require 'metaleap_zentient.util'



local strIcon = ''
local menu, menuPos, timeLastEmit


local function ensureMenu()
    textadept.menu.menubar[menuPos] = menu
end


local function clearMenu()
    menu = { title = strIcon }
    menu[1 + #menu] = { '', function() end }
    ensureMenu()
end


local function showDetails(msg)
    ui.print(msg)
end


function notify.emit(msg)
    timeLastEmit = os.time()
    menu.title = strIcon..' '..util.uxStrMenuable(msg)

    if 1 == #menu then
        menu[1 + #menu] = { '' }
        menu[1 + #menu] = { '', clearMenu }
    end

    table.insert(menu, 1, { util.uxStrMenuable(util.uxStrNowTime() .. msg),
                            function() showDetails(msg) end })
    ensureMenu()
end


function notify.init()
    menuPos = 1 + #textadept.menu.menubar

    clearMenu()

    events.connect(events.DWELL_START, function()
        if timeLastEmit and menu.title ~= strIcon and 23 < (os.time() - timeLastEmit) then
            textadept.menu.menubar[menuPos].title = strIcon
            ensureMenu()
        end
    end)
end



return notify
