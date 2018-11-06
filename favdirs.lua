local favdirs = {}

local util = require 'metaleap_zentient.util'



favdirs.keys = 'cao'


local function showFilteredListDialogOfFiles(dir, defaultFilter)
    local filerelpaths, filerelpathitems = {}, {}
    dir = util.fsPathExpandHomeDirTildePrefix(dir)

    lfs.dir_foreach(dir, function(fullfilepath)
        local relfilepath = fullfilepath:sub(2 + #dir)
        if not util.fsPathHasDotNames(relfilepath) then
            filerelpaths[1 + #filerelpaths] = relfilepath
            filerelpathitems[1 + #filerelpathitems] = util.fsPathPrettify(relfilepath, false, true)
        end
    end)

    local button, selfiles = ui.dialogs.filteredlist{
        title = util.fsPathPrettify(dir, true, true), width = 2345, height = 1234, select_multiple = true,
        text = defaultFilter, columns = 'Files:', items = filerelpathitems,
    }
    if button == 1 then
        local fullfilepaths = {}
        for _, idx in ipairs(selfiles) do
            fullfilepaths[1 + #fullfilepaths] = dir .. '/' .. filerelpaths[idx]
        end
        io.open_file(fullfilepaths)
    end
end


local function showFilteredListDialogOfDirs(favDirs)
    local dirlistitems, fulldirpaths, defaultfilters = {}, {}, {}
    for _, fd in ipairs(favDirs) do
        local favdir, defaultfilter = fd[1], fd[2]
        for _, subdir in ipairs(util.fsSubDirNames(util.fsPathExpandHomeDirTildePrefix(favdir))) do
            fulldirpaths[1 + #fulldirpaths] = favdir .. '/' .. subdir
            defaultfilters[fulldirpaths[#fulldirpaths]] = defaultfilter
            dirlistitems[1 + #dirlistitems] = util.fsPathPrettify(favdir .. '/', false, true)
            dirlistitems[1 + #dirlistitems] = util.fsPathPrettify(subdir, false, true)
        end
    end

    local button, i = ui.dialogs.filteredlist{
        title = 'Open from..', width = 2345, height = 1234,
        columns = {'Filter by:', '...then select:'}, items = dirlistitems,
    }
    if button == 1 then
        showFilteredListDialogOfFiles(fulldirpaths[i], defaultfilters[fulldirpaths[i]])
    end
end


function favdirs.init(favDirs)
    local freshmenu
    freshmenu = function()
        local lastdirpath = util.envHome
        local menu = { title = '' }
        for _, fd in ipairs(favDirs) do
            local favdir, defaultfilter = fd[1], fd[2]
            local subdirs = util.fsSubDirNames(util.fsPathExpandHomeDirTildePrefix(favdir))
            local anysubs, submenu = false, { title = util.menuable(util.fsPathPrettify(favdir, false, true)) }
            for _, subdir in ipairs(subdirs) do
                if not util.fsPathHasDotNames(subdir) then
                    anysubs, submenu[1 + #submenu] = true, { util.menuable(util.fsPathPrettify(subdir, false, true)), function()
                        showFilteredListDialogOfFiles(favdir .. '/' .. subdir, defaultfilter)
                        freshmenu()
                    end }
                end
            end
            if anysubs then menu[1 + #menu] = submenu end
        end

        menu[1 + #menu] = { '(Other...)', function()
            local dirpath = ui.dialogs.fileselect{
                title = 'Specify directory:', select_only_directories = true, with_directory = lastdirpath,
            }
            if dirpath then
                lastdirpath = dirpath
                showFilteredListDialogOfFiles(dirpath, '')
            end
            freshmenu()
        end }

        textadept.menu.menubar[2] = menu
    end

    freshmenu()
    keys[favdirs.keys] = function() showFilteredListDialogOfDirs(favDirs) end
end



return favdirs
