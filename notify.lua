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
    if #groups > 0 then
        for g = #groups, 1, -1 do
            local group = groups[g]
            if #group.msgs == 1 and nil then
                local msg = group.msgs[1]
                local txt = (msg.cat or '')..'\t '.. msg.txt
                menu[1 + #menu] = { util.uxStrMenuable(msg.time .. group.name .. '  »  ' .. txt),
                                    function() showDetails(msg.txt) end }
            else
                local lastmsg = group.msgs[#group.msgs]
                local submenu = { title = (lastmsg.cat or '')..'\t '..group.name}
                for m = #group.msgs, 1, -1 do
                    local msg = group.msgs[m]
                    local txt = (msg.cat or '')..'\t '.. msg.txt
                    submenu[1 + #submenu] = { util.uxStrMenuable(msg.time .. txt),
                                                function() showDetails(msg.txt) end }
                end
                menu[1 + #menu] = submenu
            end
        end
        menu[1 + #menu] = { '' }
        menu[1 + #menu] = { '', menuClear }
    end
    menu[1 + #menu] = { '', function() end }
    menuApply()
end


local function menuClear()
    groups = {}
    menuBuild()
    menuApply()
end


function notify.emit(groupname, message, cat)
    local now, group = util.uxStrNowTime(), util.arrFind(groups, function(v) return v.name == groupname end)
    local msg = { txt = message, time = now, cat = cat }
    if not group then
        group = { time = now, name = groupname, msgs = { msg } }
        groups[1 + #groups] = group
    else
        group.msgs[1 + #group.msgs] = msg
    end

    timeLastEmit = os.time()
    menuBuild(strIcon..'  '..groupname..'  »  '..util.uxStrMenuable(message))
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
