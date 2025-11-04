if SERVER then
    ---------------------------------------
    -- Dubz Scrap System Core Data Logic --
    ---------------------------------------
    util.AddNetworkString("DVS_RequestSync")
    util.AddNetworkString("DVS_SendSync")

    local dataPath = "dubz_scrap"  -- Folder name in /garrysmod/data/
    if not file.Exists(dataPath, "DATA") then
        file.CreateDir(dataPath)
        print("[DSS] Created data directory: data/" .. dataPath)
    end

    -- Loads a player's data file or creates defaults if missing
    local function LoadPlayerData(ply)
        if not IsValid(ply) then return end
        local sid = ply:SteamID64() or "unknown"
        local filePath = dataPath .. "/" .. sid .. ".txt"

        local data = {
            scrap = 0,
            xp = 0,
            level = 1
        }

        if file.Exists(filePath, "DATA") then
            local json = file.Read(filePath, "DATA")
            local decoded = util.JSONToTable(json or "")
            if istable(decoded) then
                data = decoded
            end
        end

        -- Network and apply
        ply:SetNWInt("DVS_Scrap", data.scrap or 0)
        ply:SetNWInt("DVS_XP", data.xp or 0)
        ply:SetNWInt("DVS_Level", data.level or 1)
    end

    -- Saves a player's data to disk
    local function SavePlayerData(ply)
        if not IsValid(ply) then return end
        local sid = ply:SteamID64() or "unknown"
        local filePath = dataPath .. "/" .. sid .. ".txt"

        local data = {
            scrap = ply:GetNWInt("DVS_Scrap", 0),
            xp = ply:GetNWInt("DVS_XP", 0),
            level = ply:GetNWInt("DVS_Level", 1)
        }

        file.Write(filePath, util.TableToJSON(data, true))
    end

    -- Auto save when player leaves
    hook.Add("PlayerDisconnected", "DVS_SaveOnLeave", function(ply)
        SavePlayerData(ply)
    end)

    -- Load data on spawn / join
    hook.Add("PlayerInitialSpawn", "DVS_LoadOnJoin", function(ply)
        timer.Simple(1, function()
            LoadPlayerData(ply)
        end)
    end)

    -- Periodic autosave (every 60 seconds)
    timer.Create("DVS_AutoSaveAll", 60, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            SavePlayerData(ply)
        end
    end)

    -- Manual command to save all
    concommand.Add("dvs_saveall", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then return end
        for _, v in ipairs(player.GetAll()) do
            SavePlayerData(v)
        end
        print("[DSS] Manually saved all player data.")
    end)

    -- Level-up check helper
    DVS = DVS or {}
    function DVS.CheckLevelUp(ply)
        if not IsValid(ply) then return end
        local xp = ply:GetNWInt("DVS_XP", 0)
        local lvl = ply:GetNWInt("DVS_Level", 1)
        local needed = (DVS.XP and DVS.XP.LevelScale or 100) * lvl
        if xp >= needed then
            ply:SetNWInt("DVS_Level", lvl + 1)
            ply:SetNWInt("DVS_XP", xp - needed)
            if DarkRP and DarkRP.notify then
                DarkRP.notify(ply, 0, 4, "🎉 You reached scrap level " .. (lvl + 1) .. "!")
            else
                ply:ChatPrint("🎉 You reached scrap level " .. (lvl + 1) .. "!")
            end
        end
    end

    print("[Dubz Scrap System (DSS)] - Successfully Loaded with File-Based Data Saving!")
else
    -------------------------------------
    -- Client-Side (Future UI syncing) --
    -------------------------------------
    net.Receive("DVS_SendSync", function()
        local scrap = net.ReadInt(16)
        local xp = net.ReadInt(32)
        local lvl = net.ReadInt(16)
        LocalPlayer():SetNWInt("DVS_Scrap", scrap)
        LocalPlayer():SetNWInt("DVS_XP", xp)
        LocalPlayer():SetNWInt("DVS_Level", lvl)
    end)
end
