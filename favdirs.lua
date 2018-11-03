local me = {}



local function showFilteredListDialogOfFiles(dir)
    if dir:sub(1, 1) == '~' then
        dir = os.getenv("HOME") .. dir:sub(2)
    end

    local filerelpaths = {}
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


local function showFilteredListDialogOfDirs(favDirs)
    local button, i = ui.dialogs.filteredlist{
        title = 'Open from..', width = 2345, height = 1234,
        columns = 'favDir:', items = favDirs,
    }
    if button == 1 then
        showFilteredListDialogOfFiles(favDirs[i])
    end
end


local function subDirs(dir)
    if dir:sub(1, 1) == '~' then
        dir = os.getenv("HOME") .. dir:sub(2)
    end

    local subdirs = {}
    lfs.dir_foreach(dir, function(fullpath)
        if fullpath:sub(-1) == '/' then
            subdirs[1 + #subdirs] = fullpath:sub(2 + #dir)
        end
    end, nil, 0, true)
    return subdirs
end


function me.init(favDirs)
    keys['f1']['o'] = function() showFilteredListDialogOfDirs(favDirs) end

    local menu = { title = ''}
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



return me
