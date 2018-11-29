local zipc = { onMsg = function(msg) end }

local util = require 'metaleap_zentient.util'
local json = require 'metaleap_zentient.vendor.dkjson'


local procsByLang, resetting = {}, false


local function onProcStderr(lang, progName)
    return function(ln)
        io.stderr:write(ln)
    end
end


local function onProcStdout(lang, progName)
    return function(ln)
        local obj, pos, err = json.decode(ln, 1, nil)
        if err then
            ui.print(err)
        else
            zipc.onMsg(obj)
        end
    end
end


local function onProcFailOrExit(lang, progName)
    return function (errMsg, exitCode)
        if not resetting then
            ui.print(lang, progName, errMsg, exitCode)
        end
    end
end


function zipc.init(langProgs)
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



return zipc
