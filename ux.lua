local me = {}

local function goToBuffer(tabNo)
    local buf = nil
    if tabNo == 0 then
        buf = _BUFFERS[#_BUFFERS]
    else
        if tabNo > 0 and tabNo <= #_BUFFERS then
            buf = _BUFFERS[tabNo]
        end
    end
    if buf ~= nil then
        view.goto_buffer(view, buf)
    end
end

function me.init()
    events.connect(events.BUFFER_DELETED, function(one, two, three)
        ui.statusbar_text = "closed" .. string.format("%q %q %q", one, two, three)
    end)

    keys.a0 = function() goToBuffer(0) end
    keys.a1 = function() goToBuffer(1) end
    keys.a2 = function() goToBuffer(2) end
    keys.a3 = function() goToBuffer(3) end
    keys.a4 = function() goToBuffer(4) end
    keys.a5 = function() goToBuffer(5) end
    keys.a6 = function() goToBuffer(6) end
    keys.a7 = function() goToBuffer(7) end
    keys.a8 = function() goToBuffer(8) end
    keys.a9 = function() goToBuffer(9) end
end

return me
