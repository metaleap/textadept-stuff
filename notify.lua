local notify = {}

local util = require 'metaleap_zentient.util'



local strIcon = '' -- ''
local menu, menuPos, timeLastEmit, groups


local function showDetails(msg)
    ui.print(msg)
end


local function menuApply()
    textadept.menu.menubar[menuPos] = menu
end


local function menuBuild(title)
    menu = { title = title or strIcon }
    menu[1 + #menu] = { '', function() end }

    if #groups > 0 then
        menu[1 + #menu] = { '', menuClear }
        menu[1 + #menu] = { '' }
        for _, group in ipairs(groups) do
            if #group.msgs == 1 then
                local msg = group.msgs[1]
                local txt = (msg.cat or '')..'\t'.. msg.txt
                menu[1 + #menu] = { util.uxStrMenuable(util.uxStrNowTime() .. group.name .. '\t»\t' .. txt),
                                    function() showDetails(msg.txt) end }
            else
            end
        end
    end
    menuApply()
end


local function menuClear()
    groups = {}
    menuBuild()
    menuApply()
end


function notify.emit(groupname, message, cat)
    local now, group = os.time(), util.arrFind(groups, function(v) return v.name == groupname end)
    local msg = { txt = message, time = now, cat = cat }
    if not group then
        group = { time = now, name = groupname, msgs = { msg } }
        groups[1 + #groups] = group
    else
        group.msgs[1 + #group.msgs] = msg
    end

    timeLastEmit = now
    menuBuild((cat or strIcon)..'  '..groupname..'\t»\t'..util.uxStrMenuable(message))
end


function notify.init()
    menuPos = 1 + #textadept.menu.menubar
    menuClear()

    events.connect(events.DWELL_START, function()
        if timeLastEmit and menu.title ~= strIcon and 23 < (os.time() - timeLastEmit) then
            menu.title = strIcon
            textadept.menu.menubar[menuPos].title = menu.title
        end
    end)
end



return notify
