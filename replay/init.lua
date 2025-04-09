-- init.lua

replay = {}
replay.current_recording = nil
replay.active_replay = nil
replay.undo_data = {}

dofile(minetest.get_modpath("replay") .. "/storage.lua")
dofile(minetest.get_modpath("replay") .. "/record.lua")
dofile(minetest.get_modpath("replay") .. "/playback.lua")
dofile(minetest.get_modpath("replay") .. "/undo.lua")

-- Commande /r_start
minetest.register_chatcommand("r_start", {
    params = "<name>",
    description = "Démarre un enregistrement",
    func = function(_, param)
        if param == "" then return false, "Nom requis." end
        if replay.current_recording then
            return false, "Un enregistrement est déjà en cours."
        end
        if minetest.get_worldpath():match("_replay$") then
            return false, "Impossible d'enregistrer dans un monde _replay."
        end

        replay.current_recording = param
        replay.create_clean_world()
        replay.start_recording(param)
        return true, "Enregistrement démarré : " .. param
    end
})

-- Commande /r_stop
minetest.register_chatcommand("r_stop", {
    description = "Arrête l'enregistrement",
    func = function()
        if not replay.current_recording then
            return false, "Aucun enregistrement actif."
        end

        local name = replay.current_recording
        replay.stop_recording()
        local base_path = minetest.get_worldpath():gsub("_replay$", "")
        replay.duplicate_world(base_path, name)
        replay.current_recording = nil
        return true, "Enregistrement '" .. name .. "' terminé."
    end
})

-- Commande /r_play
minetest.register_chatcommand("r_play", {
    params = "<name>",
    description = "Joue un replay",
    func = function(_, param)
        if param == "" then return false, "Nom du replay requis." end
        if not minetest.get_worldpath():match("_replay$") then
            return false, "Vous devez être dans un monde _replay."
        end
        if replay.active_replay then
            return false, "Un replay est déjà en cours."
        end
        local ok, err = replay.play(param)
        if ok then
            return true, "Lecture de '" .. param .. "' en cours."
        else
            return false, "Erreur: " .. (err or "inconnue")
        end
    end
})

-- Commande /r_undo
minetest.register_chatcommand("r_undo", {
    params = "<name>",
    description = "Annule les modifications du replay donné",
    func = function(_, param)
        if param == "" then return false, "Nom requis." end
        local ok, msg = replay.undo(param)
        return ok, msg
    end
})
