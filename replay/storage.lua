-- storage.lua

local json_encode = minetest.write_json
local json_decode = minetest.parse_json

-- Fonction utilitaire : copie de répertoire multiplateforme
local function copy_world(src, dst)
    local cmd
    if package.config:sub(1,1) == "\\" then
        -- Windows
        local quoted_src = "\"" .. src .. "\\\""
        local quoted_dst = "\"" .. dst .. "\\\""
        cmd = "xcopy /E /I /Y /Q " .. quoted_src .. " " .. quoted_dst
    else
        -- Linux / Unix
        cmd = string.format('cp -r "%s" "%s"', src, dst)
    end
    local result = os.execute(cmd)
    return result == 0 or result == true
end

-- Fonction utilitaire : copie de fichier multiplateforme
local function cross_platform_copy(src, dst)
    local cmd
    if package.config:sub(1,1) == "\\" then
        cmd = string.format('copy "%s" "%s"', src, dst)
    else
        cmd = string.format('cp "%s" "%s"', src, dst)
    end
    os.execute(cmd)
end

-- Sauvegarde d'un fichier JSON dans le monde courant
function replay.save_recording(name, data)
    local base_world_path = minetest.get_worldpath()
    local path = base_world_path .. "/replays"
    minetest.mkdir(path)
    local file_path = path .. "/" .. name .. ".json"
    local file = io.open(file_path, "w")
    if file then
        file:write(json_encode(data, true))
        file:close()
        minetest.log("action", "[Replay] Données sauvegardées dans : " .. file_path)
    else
        minetest.log("error", "[Replay] Impossible d’écrire le fichier JSON.")
    end

    -- Copier le fichier JSON dans clean et replay
    local clean_path = base_world_path .. "_clean/replays"
    local replay_path = base_world_path .. "_replay/replays"
    minetest.mkdir(clean_path)
    minetest.mkdir(replay_path)

    cross_platform_copy(file_path, clean_path .. "/" .. name .. ".json")
    cross_platform_copy(file_path, replay_path .. "/" .. name .. ".json")
end

-- Chargement des données JSON
function replay.load_recording(name)
    local base_world_path = minetest.get_worldpath():gsub("_replay$", "")
    local path = base_world_path .. "/replays/" .. name .. ".json"
    local file = io.open(path, "r")
    if not file then
        minetest.log("error", "[Replay] Fichier de replay non trouvé : " .. path)
        return nil
    end
    local content = file:read("*a")
    file:close()
    return json_decode(content)
end

-- Crée une version "propre" du monde (avant modifs)
function replay.create_clean_world()
    local current_path = minetest.get_worldpath()
    local clean_path = current_path .. "_clean"
    if copy_world(current_path, clean_path) then
        minetest.log("action", "[Replay] Monde clean créé.")
        replay.clean_world_created = true
    else
        minetest.log("error", "[Replay] Erreur de création du monde clean.")
    end
end

-- Crée le monde de replay à partir du monde propre
function replay.duplicate_world(original_path, name)
    local clean_path = original_path .. "_clean"
    local replay_path = original_path .. "_replay"

    if not replay.clean_world_created then
        minetest.log("error", "[Replay] Monde clean non trouvé.")
        return
    end

    if copy_world(clean_path, replay_path) then
        minetest.log("action", "[Replay] Monde replay créé depuis clean.")

        -- Modifier world.mt pour le nom visible
        local mt_file = replay_path .. "/world.mt"
        local lines = {}
        local f = io.open(mt_file, "r")
        if f then
            for line in f:lines() do
                if line:match("^name%s*=") then
                    table.insert(lines, "name = " .. name .. " (Replay)")
                else
                    table.insert(lines, line)
                end
            end
            f:close()
            local f2 = io.open(mt_file, "w")
            for _, line in ipairs(lines) do
                f2:write(line .. "\n")
            end
            f2:close()
        end

        -- Supprime le monde clean de la liste visible
        os.remove(clean_path .. "/world.mt")
    else
        minetest.log("error", "[Replay] Erreur lors de la copie du monde clean.")
    end
end
