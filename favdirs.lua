local me = {}


local envHome = os.getenv("HOME")



local function expandHomeDirPrefix(path)
    if path:sub(1, 2) == '~/' then
        path = envHome .. path:sub(2)
    end
    return path
end


local function showFilteredListDialogOfFiles(dir)
    local filerelpaths = {}
    dir = expandHomeDirPrefix(dir)

    lfs.dir_foreach(dir, function(fullfilepath)
        filerelpaths[1 + #filerelpaths] = fullfilepath:sub(2 + #dir)
    end)

    local button, selfiles = ui.dialogs.filteredlist{
        title = dir, width = 2345, height = 1234, select_multiple = true,
        columns = 'Files:', items = filerelpaths,
    }
    if button == 1 then
        local fullfilepaths = {}
        for _, idx in ipairs(selfiles) do
            fullfilepaths[1 + #fullfilepaths] = dir .. '/' .. filerelpaths[idx]
        end
        io.open_file(fullfilepaths)
    end
end


local function subDirs(dir)
    local subdirs = {}
    dir = expandHomeDirPrefix(dir)

    lfs.dir_foreach(dir, function(fullpath)
        if fullpath:sub(-1) == '/' then
            subdirs[1 + #subdirs] = fullpath:sub(2 + #dir)
        end
    end, nil, 0, true)
    return subdirs
end


local function showFilteredListDialogOfDirs(favDirs)
    local dirlistitems, fulldirpaths = {}, {}
    for _, favdir in ipairs(favDirs) do
        for _, subdir in ipairs(subDirs(favdir)) do
            fulldirpaths[1 + #fulldirpaths] = favdir .. '/' .. subdir
            dirlistitems[1 + #dirlistitems] = favdir
            dirlistitems[1 + #dirlistitems] = subdir
        end
    end

    local button, i = ui.dialogs.filteredlist{
        title = 'Open from..', width = 2345, height = 1234,
        columns = {'favDir', 'sub-Dir'}, items = dirlistitems,
    }
    if button == 1 then
        showFilteredListDialogOfFiles(fulldirpaths[i])
    end
end


function me.init(favDirs)
    keys['f1']['o'] = function() showFilteredListDialogOfDirs(favDirs) end

    if #favDirs > 0 then
        local menu = { title = '  ' }
        for _, favdir in ipairs(favDirs) do
            local subdirs = subDirs(favdir)
            local submenu = { title = favdir }
            for _, subdir in ipairs(subdirs) do
                submenu[1 + #submenu] = { subdir, function() showFilteredListDialogOfFiles(favdir .. '/' .. subdir) end }
            end
            menu[1 + #menu] = submenu
        end
        textadept.menu.menubar[1 + #textadept.menu.menubar] = menu
    end
end



return me
