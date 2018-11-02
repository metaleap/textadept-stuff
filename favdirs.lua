local me = {}

local function showFilteredListDialogOfFiles(dir)
    local button, i = ui.dialogs.filteredlist{
        title = dir,
        columns = 'File:',
        items = {"one", "two", "three"},
    }
    if button == 1 then
        ui.print(i)
    end
end

local function showFilteredListDialogOfDirs(favDirs)
    local button, i = ui.dialogs.filteredlist{
        title = 'Open from..',
        columns = 'favDir:',
        items = favDirs,
    }
    if button == 1 then
        showFilteredListDialogOfFiles(favDirs[i])
    end
end

function me.init(favDirs)
    --for i, favdir in ipairs(favDirs) do
        --if favdir:sub(1, 1) == '~' then
            --favDirs[i] = os.getenv("HOME") .. favdir:sub(2)
        --end
    --end

    keys['f1']['o'] = function() showFilteredListDialogOfDirs(favDirs) end
end

return me
