-- record.lua

local json = minetest.write_json
local us_time = minetest.get_us_time

replay.recording = false
replay.recorded_events = {}
replay.record_name = ""

-- Enregistre une modification dans le tableau
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

-- Intercepter les changements de blocs (placement, suppression)
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    record_change("place", pos, newnode)
end)

minetest.register_on_dignode(function(pos, oldnode, digger)
    record_change("remove", pos, oldnode)
end)

-- Intercepter les changements effectués par d'autres mods comme WorldEdit :
-- En utilisant override de set_node
local old_set_node = minetest.set_node
minetest.set_node = function(pos, node)
    local old_node = minetest.get_node_or_nil(pos)
    if old_node and node and old_node.name ~= node.name then
        record_change("modify", pos, node)
    end
    return old_set_node(pos, node)
end

-- Démarre un enregistrement
function replay.start_recording(name)
    replay.recording = true
    replay.recorded_events = {}
    replay.record_name = name
    replay.create_clean_world()
    minetest.chat_send_all("[Replay] Enregistrement démarré : " .. name)
end

-- Stoppe l'enregistrement et sauvegarde
function replay.stop_recording()
    if not replay.recording then
        minetest.chat_send_all("[Replay] Aucun enregistrement en cours.")
        return
    end

    local name = replay.record_name
    replay.recording = false

    replay.save_recording(name, replay.recorded_events)
    replay.duplicate_world(minetest.get_worldpath(), name)

    minetest.chat_send_all("[Replay] Enregistrement terminé.")
end
