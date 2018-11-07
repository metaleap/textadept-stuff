local util = {}



util.envHome = os.getenv("HOME")
util.eventBufSwitch = 'metaleap_zentient.EVENT_BUFSWITCH'
local envHomeSlash = util.envHome .. '/'


function util.fsPathJoin(...)
    local parts = {...}
    local path = ''
    ui.statusbar_text = tostring(#parts)
    for i, part in ipairs(parts) do
        if part then
            while i > 1 and part:sub(1, 1) == '/' do
                part = part:sub(2)
            end
            while part:sub(-1) == '/' do
                part = part:sub(1, -2)
            end
            if #part > 0 then
                path = path .. part .. '/'
            end
        end
    end
    return path:sub(1, -2)
end


-- if `path` is prefixed with `~/`, changes the prefix to (actual, current) `$HOME/`
function util.fsPathExpandHomeDirTildePrefix(path)
    if path:sub(1, 2) == '~/' then
        path = util.envHome .. path:sub(2)
    end
    return path
end


-- if `homeTilde` and `path` is prefixed with (actual, current) `$HOME/`, the prefix is changed to `~/`.
-- if `spacedSlashes`, all slashes get surrounded by white-space.
function util.fsPathPrettify(path, homeTilde, spacedSlashes)
    if homeTilde and path:sub(1, #envHomeSlash) == envHomeSlash then
        path = '~' .. path:sub(#envHomeSlash)
    end
    if spacedSlashes then
        path = path:gsub('/', ' / ')
    end
    return path
end


-- returns the `baz` in `foo/bar/baz` and `/foo/bar/baz` etc.
function util.fsPathBaseName(path)
    return path:gsub("(.*/)(.*)", "%2")
end

-- returns the `foo/bar/` in `foo/bar/baz` and the `/foo/bar/` in `/foo/bar/baz` etc.
function util.fsPathParentDir(path)
    return path:gsub("(.*/)(.*)", "%1")
end


-- returns whether any segment in `path` begins with a period `.` char
function util.fsPathHasDotNames(path)
    for split in string.gmatch(path, "([^/]+)") do
        if split:sub(1, 1) == '.' then return true end
    end
    return false
end


-- returns the names of all sub-directories in `dirFullPath`
function util.fsSubDirNames(dirFullPath)
    local subdirs = {}
    lfs.dir_foreach(dirFullPath, function(fullpath)
        if fullpath:sub(-1) == '/' then
            local subdirname = fullpath:sub(2 + #dirFullPath)
            if subdirname:sub(1, 1) ~= '.' then
                subdirs[1 + #subdirs] = subdirname
            end
        end
    end, nil, 0, true)
    return subdirs
end


-- because get_sel_text concats all multiple selections, here's one that won't:
function util.bufSelText(fullTextIfNoSelection)
    if buffer.selection_empty then
        return fullTextIfNoSelection and buffer:get_text() or ''
    end
    return buffer:text_range(buffer.selection_start, buffer.selection_end)
end


function util.bufClearHighlightedWords()
    buffer.indicator_current = textadept.editing.INDIC_HIGHLIGHT
    buffer:indicator_clear_range(0, buffer.length)
end


function util.bufIndexOf(bufFilenameOrTablabel)
    for i, buf in ipairs(_BUFFERS) do
        if ((not bufFilenameOrTablabel) and buf == buffer)
            or bufFilenameOrTablabel == buf
                or bufFilenameOrTablabel == (buf.filename or buf.tab_label)
        then
            return i
        end
    end
    return nil
end


function util.bufIsUpdateOf(upd, ...)
    if upd then
        for _, chk in ipairs({...}) do
            if upd&chk == chk then
                return true
            end
        end
    end
    return false
end


function util.uxStrMenuable(text)
    return text:gsub('_', '__')
end


function util.uxStrNowTime(pref, suff)
    if (not pref) and (not suff) then pref, suff = '[ ', ' ]\t' end
    return os.date((pref or '') .. "%H:%M:%S" .. (suff or ''))
end


function util.osSpawnProc(cmd, stdoutSplitSep, onStdout, stderrSplitSep, onStdErr, nonWritable, onExit)
    local lnout, lnerr = '', ''

    local onstdout, onstderr, onexit = function(txt)
        if txt and #txt > 0 then
            if txt:sub(-1) == stdoutSplitSep then
                onStdout(lnout..txt:sub(1, -2))
                lnout = ''
            else
                lnout = lnout..txt
            end
        end
    end, function(txt)
        if txt and #txt > 0 then
            if txt:sub(-1) == stderrSplitSep then
                onStderr(lnerr..txt:sub(1, -2))
                lnerr = ''
            else
                lnerr = lnerr..txt
            end
        end
    end, function(exitcode)
        if lnout ~= '' then onStdout(lnout) end
        if lnerr ~= '' then onStderr(lnerr) end
        if onExit then onExit(exitcode) end
    end

    local proc = os.spawn(cmd, onstdout, onstderr, onexit)
    if nonWritable then proc:close() end
    return proc
end


do
    local emitEventBufSwitch = function()
        events.emit(util.eventBufSwitch, util.bufIndexOf())
    end
    events.connect(events.FILE_OPENED, emitEventBufSwitch)
    events.connect(events.BUFFER_NEW, emitEventBufSwitch)
    events.connect(events.BUFFER_AFTER_SWITCH, emitEventBufSwitch)
end



return util
