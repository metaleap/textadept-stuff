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


local function menuItem(msg, prefix)
    local txt = (msg.cat or '')..'  '.. msg.txt
    return { util.uxStrMenuable(prefix .. txt),
                msg.action or function() showDetails(msg.txt) end }
end


local function menuBuild(title, dropGroupIdx)
    menu = { title = title or strIcon }
    if dropGroupIdx then table.remove(groups, dropGroupIdx) end
    if #groups > 0 then
        table.sort(groups, function(dis, dat)
            return dis.msgs[#dis.msgs].time < dat.msgs[#dat.msgs].time
        end)
        for g = #groups, 1, -1 do
            local group = groups[g]
            if #group.msgs == 1 then
                local msg = group.msgs[1]
                menu[1 + #menu] = menuItem(msg, msg.time .. group.name .. '    »      ')
            else
                local lastmsg = group.msgs[#group.msgs]
                local submenu = { title = (lastmsg.cat or '')..'\t '..group.name}
                for m = #group.msgs, 1, -1 do
                    local msg = group.msgs[m]
                    if msg.sep and m < #group.msgs then
                        submenu[1 + #submenu] = { '' }
                    end
                    submenu[1 + #submenu] = menuItem(msg, msg.time)
                end
                submenu[1 + #submenu] = { '' }
                submenu[1 + #submenu] = { '', function() menuBuild(nil, g) end }
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


function notify.emit(groupname, message, cat, action, sep)
    local now, group = util.uxStrNowTime(), util.arrFind(groups, function(v) return v.name == groupname end)
    local msg = { txt = message, time = now, cat = cat, sep = sep, action = action }
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
