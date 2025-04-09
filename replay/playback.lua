local us_time = minetest.get_us_time

function replay.play(name)
    if replay.active_replay then
        return false, "Déjà en lecture."
    end

    local events = replay.load_recording(name)
    if not events or type(events) ~= "table" then
        return false, "Fichier invalide."
    end

    table.sort(events, function(a, b) return a.timestamp < b.timestamp end)
    replay.active_replay = name
    replay.undo_data[name] = {}

    local start_ts = events[1].timestamp or us_time()

    for i, evt in ipairs(events) do
        local delay = (evt.timestamp - start_ts) / 1e6
        minetest.after(delay, function()
            local pos = evt.pos
            local current = minetest.get_node_or_nil(pos)
            if current then
                replay.undo_data[name][minetest.pos_to_string(pos)] = current
            end

            if evt.action == "place" or evt.action == "modify" then
                minetest.set_node(pos, evt.node)
            elseif evt.action == "remove" then
                minetest.remove_node(pos)
            end

            if i == #events then
                replay.active_replay = nil
                minetest.chat_send_all("[Replay] Fin de lecture.")
            end
        end)
    end

    return true
end
