local me = {}


local envHome = os.getenv("HOME")



local function expandHomeDirPrefix(path)
    if path:sub(1, 2) == '~/' then
        path = envHome .. path:sub(2)
    end
    return path
end
local function prettifyPathForDisplay(path)
    return path:gsub('/', ' / ')
end
local function doesPathHaveDotDirs(path)
    for split in string.gmatch(path, "([^/]+)") do
        if split:sub(1, 1) == '.' then return true end
    end
    return false
end


local function showFilteredListDialogOfFiles(dir, defaultFilter)
    local filerelpaths = {}
    dir = expandHomeDirPrefix(dir)

    lfs.dir_foreach(dir, function(fullfilepath)
        local relfilepath = fullfilepath:sub(2 + #dir)
        if not doesPathHaveDotDirs(relfilepath) then
            filerelpaths[1 + #filerelpaths] = prettifyPathForDisplay(relfilepath)
        end
    end)

    local button, selfiles = ui.dialogs.filteredlist{
        title = prettifyPathForDisplay(dir), width = 2345, height = 1234, select_multiple = true,
        text = defaultFilter, columns = 'Files:', items = filerelpaths,
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
            local subdirname = fullpath:sub(2 + #dir)
            if subdirname:sub(1, 1) ~= '.' then
                subdirs[1 + #subdirs] = subdirname
            end
        end
    end, nil, 0, true)
    return subdirs
end


local function showFilteredListDialogOfDirs(favDirs)
    local dirlistitems, fulldirpaths, defaultfilters = {}, {}, {}
    for favdir, defaultfilter in pairs(favDirs) do
        for _, subdir in ipairs(subDirs(favdir)) do
            fulldirpaths[1 + #fulldirpaths] = favdir .. '/' .. subdir
            defaultfilters[fulldirpaths[#fulldirpaths]] = defaultfilter
            dirlistitems[1 + #dirlistitems] = prettifyPathForDisplay(favdir .. '/')
            dirlistitems[1 + #dirlistitems] = prettifyPathForDisplay(subdir)
        end
    end

    local button, i = ui.dialogs.filteredlist{
        title = 'Open from..', width = 2345, height = 1234,
        columns = {'favDir', 'sub-Dir'}, items = dirlistitems,
    }
    if button == 1 then
        showFilteredListDialogOfFiles(fulldirpaths[i], defaultfilters[fulldirpaths[i]])
    end
end


function me.init(favDirs)
    local hasany, menu = false, { title = '' }
    for favdir, defaultfilter in pairs(favDirs) do
        local subdirs = subDirs(favdir)
        local submenu = { title = favdir }
        for _, subdir in ipairs(subdirs) do
            submenu[1 + #submenu] = { subdir, function() showFilteredListDialogOfFiles(favdir .. '/' .. subdir, defaultfilter) end }
        end
        hasany, menu[1 + #menu] = true, submenu
    end
    if hasany then
        textadept.menu.menubar[1 + #textadept.menu.menubar] = menu
    end
    return function()
        if hasany then showFilteredListDialogOfDirs(favDirs) end
    end
end



return me
