local favdirs = {}


local util = require 'metaleap_zentient.util'



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
            fullfilepaths[1 + #fullfilepaths] = dir .. filerelpaths[idx]
        end
        io.open_file(fullfilepaths)
    end
end


local function showFilteredListDialogOfDirs(favDirs)
    local dirlistitems, fulldirpaths, defaultfilters = {}, {}, {}
    for favdir, defaultfilter in pairs(favDirs) do
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
    local menu = { title = '' }
    for favdir, defaultfilter in pairs(favDirs) do
        if not util.fsPathHasDotNames(favdir) then
            local subdirs = util.fsSubDirNames(util.fsPathExpandHomeDirTildePrefix(favdir))
            local anysubs, submenu = false, { title = util.fsPathPrettify(favdir, false, true) }
            for _, subdir in ipairs(subdirs) do
                if not util.fsPathHasDotNames(subdir) then
                    anysubs, submenu[1 + #submenu] = true, { util.fsPathPrettify(subdir, false, true), function()
                        showFilteredListDialogOfFiles(favdir .. '/' .. subdir, defaultfilter)
                    end }
                end
            end
            if anysubs then menu[1 + #menu] = submenu end
        end
    end

    do
        local lastdirpath = util.envHome
        menu[1 + #menu] = { '(Elsewhere...)', function()
            local dirpath = ui.dialogs.fileselect{
                title = 'Specify directory:', select_only_directories = true, with_directory = lastdirpath,
            }
            if dirpath then
                lastdirpath = dirpath
                showFilteredListDialogOfFiles(dirpath, '')
            end
        end }
    end

    textadept.menu.menubar[1 + #textadept.menu.menubar] = menu
    return function()
        showFilteredListDialogOfDirs(favDirs)
    end
end



return favdirs
