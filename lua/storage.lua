local json_encode = minetest.write_json
local json_decode = minetest.parse_json

local function is_windows()
    return package.config:sub(1, 1) == "\\"
end

local function copy_world(src, dst)
    local cmd
    if is_windows() then
        cmd = string.format('xcopy /E /I /Y /Q "%s\\*" "%s\\"', src, dst)
    else
        cmd = string.format('cp -r "%s/" "%s/"', src, dst)
    end
    return os.execute(cmd)
end

function replay.save_recording(name, data)
    local base = minetest.get_worldpath()
    local path = base .. "/replays"
    minetest.mkdir(path)
    local file_path = path .. "/" .. name .. ".json"
    local file = io.open(file_path, "w")
    if file then
        file:write(json_encode(data, true))
        file:close()
        minetest.log("action", "[Replay] Sauvegarde : " .. file_path)
    else
        minetest.log("error", "[Replay] Échec écriture JSON.")
    end
end

function replay.load_recording(name)
    local base = minetest.get_worldpath():gsub("_replay$", "")
    local path = base .. "/replays/" .. name .. ".json"
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return json_decode(content)
end

function replay.create_clean_world()
    local src = minetest.get_worldpath()
    local dst = src .. "_clean"
    if copy_world(src, dst) then
        replay.clean_world_created = true
        minetest.log("action", "[Replay] Monde clean OK.")
    else
        minetest.log("error", "[Replay] Échec clean.")
    end
end

function replay.duplicate_world(base_path, name)
    local clean = base_path .. "_clean"
    local replay_path = base_path .. "_replay"

    if not replay.clean_world_created then return end

    if copy_world(clean, replay_path) then
        minetest.log("action", "[Replay] Monde de replay créé.")
        local f = io.open(replay_path .. "/world.mt", "r")
        if f then
            local lines = {}
            for line in f:lines() do
                if line:match("^name%s*=") then
                    table.insert(lines, "name = " .. name .. " (Replay)")
                else
                    table.insert(lines, line)
                end
            end
            f:close()
            local wf = io.open(replay_path .. "/world.mt", "w")
            for _, l in ipairs(lines) do
                wf:write(l .. "\n")
            end
            wf:close()
        end
    else
        minetest.log("error", "[Replay] Copie échouée.")
    end
end
