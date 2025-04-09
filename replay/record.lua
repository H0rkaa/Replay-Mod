local us_time = minetest.get_us_time

replay.recording = false
replay.recorded_events = {}
replay.record_name = ""

-- Enregistre une modification
local function record_change(action, pos, node)
    if not replay.recording then return end
    table.insert(replay.recorded_events, {
        timestamp = us_time(),
        action = action,
        pos = vector.new(pos),
        node = {
            name = node.name or "",
            param1 = node.param1 or 0,
            param2 = node.param2 or 0,
        }
    })
end

-- Sur placement / suppression
minetest.register_on_placenode(function(pos, newnode)
    record_change("place", pos, newnode)
end)
minetest.register_on_dignode(function(pos, oldnode)
    record_change("remove", pos, oldnode)
end)

-- Pour set_node des autres mods
local old_set_node = minetest.set_node
minetest.set_node = function(pos, node)
    local current = minetest.get_node_or_nil(pos)
    if current and node and current.name ~= node.name then
        record_change("modify", pos, node)
    end
    return old_set_node(pos, node)
end

function replay.start_recording(name)
    replay.recording = true
    replay.recorded_events = {}
    replay.record_name = name
    minetest.chat_send_all("[Replay] Enregistrement : " .. name)
end

function replay.stop_recording()
    if not replay.recording then return end
    local name = replay.record_name
    replay.recording = false
    replay.save_recording(name, replay.recorded_events)
    minetest.chat_send_all("[Replay] Terminé : " .. name)
end
