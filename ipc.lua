local ipc = {}

local util = require 'metaleap_zentient.util'



local procsByLang, resetting = {}, false
local menuPosMain, menuPosIntel, menuPosQuery
local menuMain, menuIntel, menuQuery


local function onProcStderr(lang, progName)
    return function()
    end
end


local function onProcStdout(lang, progName)
    return function()
    end
end


local function onProcFailOrExit(lang, progName)
    return function (errMsg, exitCode)
        if not resetting then
            ui.print(lang, progName, errMsg, exitCode)
        end
    end
end


function ipc.init(langProgs)
    for lang, progname in pairs(langProgs) do
        local proc = util.osSpawnProc(progname,
                                        '\n', onProcStdout(lang, progname),
                                        '\n', onProcStderr(lang, progname),
                                        onProcFailOrExit(lang, progname), true)
        if proc then procsByLang[lang] = proc end
    end

    menuPosMain, menuPosIntel, menuPosQuery = 1 + #textadept.menu.menubar, 2 + #textadept.menu.menubar, 3 + #textadept.menu.menubar
    menuMain, menuIntel, menuQuery = { title = '  ' }, { title = '' }, { title = '' }
    textadept.menu.menubar[menuPosMain] = menuMain
    textadept.menu.menubar[menuPosIntel] = menuIntel
    textadept.menu.menubar[menuPosQuery] = menuQuery

    events.connect(events.RESET_BEFORE, function()
        resetting = true
        for lang, proc in pairs(procsByLang) do
            proc:kill()
        end
    end)
end



return ipc
