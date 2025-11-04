------------------------------------------
-- Dubz Scrap System HUD + Looting Bars --
------------------------------------------

AddCSLuaFile()
include("autorun/dubz_dss_config.lua")

if SERVER then return end

local lootActive = false
local lootEndTime = 0
local lootDur = 0
local lootEnt = nil
local showLootPrompt = false
local showScrapPrompt = false
local promptAlphaLoot = 0
local promptAlphaScrap = 0

-- When looting starts
net.Receive("DSS_Loot_Begin", function()
    lootEnt = net.ReadEntity()
    lootDur = net.ReadFloat()
    lootEndTime = CurTime() + lootDur
    lootActive = true
    showLootPrompt = false
end)

-- When looting ends
net.Receive("DSS_Loot_End", function()
    lootActive = false
    lootEnt = nil
    lootDur = 0
end)

-- Level up message
net.Receive("DSS_LevelUp", function()
    local lvl = LocalPlayer():GetNWInt("DVS_Level", 1)
    chat.AddText(Color(255, 215, 0), "⭐ You reached Scrap Level ", color_white, tostring(lvl), Color(255, 215, 0), "!")
end)

-----------------------------------
-- Sleek HUD (center-left)
-----------------------------------
hook.Add("HUDPaint", "DVS_ScrapHUD", function()
    if not DVS then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local C = DVS.UIColors or {}
    local w, h = 250, 80
    local x, y = 50, ScrH() / 2 - h / 2  -- center-left

    draw.RoundedBox(10, x, y, w, h, C.Background or Color(0, 0, 0, 160))
    draw.SimpleText("SCRAP SYSTEM", "DermaLarge", x + 15, y + 8, C.TextHighlight or color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local scrap = ply:GetNWInt("DVS_Scrap", 0)
    draw.SimpleText("Scrap: " .. scrap, "Trebuchet24", x + 15, y + 34, C.TextPrimary or color_white)

    local lvl = ply:GetNWInt("DVS_Level", 1)
    local xp = ply:GetNWInt("DVS_XP", 0)
    local need = math.max(1, lvl * ((DVS.XP and DVS.XP.LevelScale) or 100))
    local frac = math.Clamp(xp / need, 0, 1)

    local barW, barH = w - 20, 8
    local bx, by = x + 10, y + h - barH - 6
    draw.RoundedBox(4, bx, by, barW, barH, C.XPBarBG or Color(30, 30, 30, 200))
    surface.SetDrawColor(C.XPBar or Color(0, 120, 255))
    surface.DrawRect(bx + 1, by + 1, (barW - 2) * frac, barH - 2)
    draw.SimpleText("Lv " .. lvl, "DermaDefaultBold", bx + barW / 2, by - 12, C.TextHighlight or Color(0, 200, 255), TEXT_ALIGN_CENTER)
end)

-----------------------------------
-- Lockpick-style Looting Bar
-----------------------------------
hook.Add("HUDPaint", "DVS_LootingBar", function()
    if not lootActive then return end

    local remain = lootEndTime - CurTime()
    if remain <= 0 then lootActive = false return end

    local C = DVS.UIColors or {}
    local frac = 1 - (remain / math.max(lootDur, 0.01))
    local lw, lh = 400, 30
    local cx, cy = ScrW() / 2 - lw / 2, ScrH() * 0.75  -- mid-lower screen

    draw.RoundedBox(8, cx, cy, lw, lh, C.ProgressBarBG or Color(0, 0, 0, 180))
    surface.SetDrawColor(C.ProgressBar or Color(0, 170, 255, 220))
    surface.DrawRect(cx + 2, cy + 2, (lw - 4) * frac, lh - 4)
    draw.SimpleText("Looting...", "Trebuchet24", cx + lw / 2, cy + lh / 2, C.TextPrimary or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

-----------------------------------
-- Prompts for Lootable and Scrap
-----------------------------------
hook.Add("HUDPaint", "DVS_LootAndScrapPrompts", function()
    if lootActive then 
        promptAlphaLoot = math.Approach(promptAlphaLoot, 0, FrameTime() * 400)
        promptAlphaScrap = math.Approach(promptAlphaScrap, 0, FrameTime() * 400)
        return 
    end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    local dist = tr.StartPos:Distance(tr.HitPos)

    showLootPrompt = IsValid(ent) and ent:GetClass() == "dubz_lootable" and dist <= 120
    showScrapPrompt = IsValid(ent) and ent:GetClass() == "dubz_scrap" and dist <= 120

    local targetAlphaLoot = showLootPrompt and 255 or 0
    local targetAlphaScrap = showScrapPrompt and 255 or 0

    promptAlphaLoot = math.Approach(promptAlphaLoot, targetAlphaLoot, FrameTime() * 700)
    promptAlphaScrap = math.Approach(promptAlphaScrap, targetAlphaScrap, FrameTime() * 700)

    -- Draw loot prompt
    if promptAlphaLoot > 1 then
        local text = "[E] Loot container"
        surface.SetFont("Trebuchet24")
        local tw, th = surface.GetTextSize(text)
        local cx, cy = ScrW() / 2, ScrH() / 2 + 60
        draw.RoundedBox(6, cx - tw / 2 - 10, cy - th / 2 - 4, tw + 20, th + 8, Color(0, 0, 0, 180 * (promptAlphaLoot / 255)))
        draw.SimpleText(text, "Trebuchet24", cx, cy, Color(255, 255, 255, promptAlphaLoot), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Draw scrap prompt
    if promptAlphaScrap > 1 then
        local text = "[E] Collect scrap"
        surface.SetFont("Trebuchet24")
        local tw, th = surface.GetTextSize(text)
        local cx, cy = ScrW() / 2, ScrH() / 2 + 60
        draw.RoundedBox(6, cx - tw / 2 - 10, cy - th / 2 - 4, tw + 20, th + 8, Color(0, 0, 0, 180 * (promptAlphaScrap / 255)))
        draw.SimpleText(text, "Trebuchet24", cx, cy, Color(255, 255, 255, promptAlphaScrap), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)
