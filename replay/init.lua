-- init.lua
-- Initialisation du mod Replay

-- Crée la table globale Replay si elle n'existe pas
replay = {}

-- Chargement des sous-modules
dofile(minetest.get_modpath("replay") .. "/storage.lua")
dofile(minetest.get_modpath("replay") .. "/record.lua")
dofile(minetest.get_modpath("replay") .. "/playback.lua")

local current_name = nil

-- Commande pour démarrer l'enregistrement
minetest.register_chatcommand("r_start", {
    params = "<name>",
    description = "Démarre l'enregistrement du monde",
    func = function(name, param)
        if param == "" then
            return false, "Vous devez fournir un nom pour l'enregistrement."
        end

        -- Vérifier qu'on n'est pas déjà dans un monde _replay
        if minetest.get_worldpath():match("_replay$") then
            return false, "Vous ne pouvez pas enregistrer dans un monde de replay."
        end

        current_name = param
        replay.create_clean_world()
        replay.start_recording(current_name)
        return true, "Enregistrement démarré sous le nom : " .. current_name
    end
})

-- Commande pour arrêter l'enregistrement
minetest.register_chatcommand("r_stop", {
    description = "Arrête l'enregistrement et crée le monde de replay",
    func = function(name)
        if not current_name then
            return false, "Aucun enregistrement en cours."
        end

        replay.stop_recording()
        local base_path = minetest.get_worldpath():gsub("_replay$", "")
        replay.duplicate_world(base_path, current_name)
        current_name = nil
        return true, "Enregistrement terminé et monde replay créé."
    end
})

-- Commande pour jouer un enregistrement
minetest.register_chatcommand("r_play", {
    params = "<name>",
    description = "Rejoue les modifications enregistrées",
    func = function(name, param)
        if param == "" then
            return false, "Vous devez fournir un nom de replay à jouer."
        end

        if not minetest.get_worldpath():match("_replay$") then
            return false, "Vous devez être dans un monde _replay pour lire un enregistrement."
        end

        local ok, err = replay.play(param)
        if ok then
            return true, "Lecture du replay '" .. param .. "' démarrée."
        else
            return false, "Erreur : " .. (err or "inconnue")
        end
    end
})
