local notify = {}

local util = require 'metaleap_zentient.util'



local strIcon = ''
local menu, timeLastEmit


local function ensureMenu()
    textadept.menu.menubar[4] = menu
end


local function clearMenu()
    menu = { title = strIcon }
    menu[1 + #menu] = { '(Clear)', clearMenu }
    menu[1 + #menu] = { '(Close)', function() end }
    ensureMenu()
end


local function showDetails(msg)
    ui.print(msg)
end


function notify.emit(msg)
    timeLastEmit = os.time()
    menu.title = strIcon..' '..util.uxStrMenuable(msg)
    table.insert(menu, 1, { util.uxStrMenuable(util.uxStrNowTime() .. msg),
                            function() showDetails(msg) end })
    ensureMenu()
end


function notify.init()
    clearMenu()

    events.connect(events.DWELL_START, function()
        if timeLastEmit and 3 < (os.time() - timeLastEmit) then
            timeLastEmit = nil
            menu.title = strIcon
            ensureMenu()
        end
    end)
end



return notify
