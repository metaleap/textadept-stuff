local ipc = {}

local util = require 'metaleap_zentient.util'



local procsByLang = {}
local resetting = false


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

    events.connect(events.RESET_BEFORE, function()
        resetting = true
        for lang, proc in pairs(procsByLang) do
            proc:kill()
        end
    end)
end



return ipc
