function replay.undo(name)
    local data = replay.undo_data[name]
    if not data then
        return false, "Aucune donnée pour ce replay."
    end

    for pos_str, old_node in pairs(data) do
        local pos = minetest.string_to_pos(pos_str)
        minetest.set_node(pos, old_node)
    end

    replay.undo_data[name] = nil
    minetest.chat_send_all("[Replay] '" .. name .. "' annulé.")
    return true, "Annulé."
end
