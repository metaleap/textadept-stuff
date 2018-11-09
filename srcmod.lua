local srcmod = {}

local util = require 'metaleap_zentient.util'



srcmod.formatOnSave = false


local function formatSrc()
    local src = util.bufSelText(true)
    if #src > 0 then

        -- temporary dummy formatter
        local srcfmt = src:gsub("\t", " "):gsub("  ", " "):gsub("  ", " "):gsub("  ", " "):gsub("  ", " "):gsub("  ", " "):gsub(" ", "~")

        if srcfmt ~= src then
            local selpos, selfrom = buffer.selection_end, buffer.selection_start
            if buffer.selection_empty then
                buffer:set_text(srcfmt)
                buffer.set_sel(selpos, selpos)
            else
                buffer.set_selection(selpos, selfrom)
                buffer:replace_sel(srcfmt)
            end
        end
    end
end


local function setup()
    keys.caf = formatSrc
    textadept.menu.context_menu[1 + #textadept.menu.context_menu] = { 'Format', formatSrc }
    if srcmod.formatOnSave then
        events.connect(events.FILE_BEFORE_SAVE, formatSrc)
    end
end


function srcmod.init()
    setup()
end

return srcmod
