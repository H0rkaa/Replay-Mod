-- playback.lua

local last_play_time = 0
local is_playing = false

-- Rejoue les modifications avec leur timing original
function replay.play(name)
    if is_playing then
        minetest.chat_send_all("[Replay] Un replay est déjà en cours.")
        return
    end

    -- Ne permettre la lecture que dans un monde _replay
    local world_path = minetest.get_worldpath()
    if not world_path:match("_replay$") then
        minetest.chat_send_all("[Replay] Vous devez être dans un monde _replay pour jouer un replay.")
        return
    end

    local events = replay.load_recording(name)
    if not events or type(events) ~= "table" then
        minetest.chat_send_all("[Replay] Fichier JSON invalide ou vide.")
        return
    end

    -- Tri par timestamp croissant
    table.sort(events, function(a, b)
        return a.timestamp < b.timestamp
    end)

    is_playing = true
    last_play_time = minetest.get_us_time()
    local start_time = events[1].timestamp or 0

    for i, evt in ipairs(events) do
        local delay = (evt.timestamp - start_time) / 1000000  -- convertir µs → s
        minetest.after(delay, function()
            local pos = evt.pos
            if evt.action == "place" or evt.action == "modify" then
                minetest.set_node(pos, {
                    name = evt.node.name,
                    param1 = evt.node.param1 or 0,
                    param2 = evt.node.param2 or 0,
                })
            elseif evt.action == "remove" then
                minetest.remove_node(pos)
            end

            -- Fin du replay
            if i == #events then
                is_playing = false
                minetest.chat_send_all("[Replay] Lecture terminée.")
            end
        end)
    end

    minetest.chat_send_all("[Replay] Lecture du replay '" .. name .. "'...")
end
