AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
include("autorun/dubz_dss_config.lua")

util.AddNetworkString("DSS_Loot_Begin")
util.AddNetworkString("DSS_Loot_End")
util.AddNetworkString("DSS_LevelUp")

local function pickRandomLootModel()
    local list = (DVS and DVS.Models and DVS.Models.Lootables) or {}
    if istable(list) and #list > 0 then
        return list[math.random(#list)]
    end
    return "models/props_junk/TrashBin01a.mdl"
end

function ENT:Initialize()
    local saved = self:GetNWString("LootModel", "")
    local mdl = (saved ~= "" and saved) or pickRandomLootModel()
    self:SetModel(mdl)
    self:SetNWString("LootModel", mdl)

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject(); if IsValid(phys) then phys:Wake() end
    self:SetIsLooting(false)
    self.LootCooldown = 0
end

function ENT:SpawnTimedEntity(class, pos, ang)
    local e = ents.Create(class)
    if not IsValid(e) then return end
    e:SetPos(pos); e:SetAngles(ang or Angle(0,0,0))
    e:Spawn(); e:Activate()
    timer.Simple(120, function() if IsValid(e) then e:Remove() end end)
end

function ENT:SpawnTimedProp(model, pos, ang)
    local e = ents.Create("prop_physics")
    if not IsValid(e) then return end
    e:SetModel(model)
    e:SetPos(pos); e:SetAngles(ang or Angle(0,0,0))
    e:Spawn(); e:Activate()
    local phys = e:GetPhysicsObject(); if IsValid(phys) then phys:Wake() end
    timer.Simple(120, function() if IsValid(e) then e:Remove() end end)
end

function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if self:GetIsLooting() then return end

    local cd = (DVS and DVS.Looting and DVS.Looting.Cooldown) or 30
    if CurTime() < (self.LootCooldown or 0) then
        if DarkRP and DarkRP.notify then DarkRP.notify(ply, 1, 4, "It's empty. Try again soon.") end
        return
    end

    local baseDur = (DVS and DVS.Looting and DVS.Looting.LootTime) or 4
    local lvl = ply:GetNWInt("DVS_Level", 1)
    local speedMul = 1 - math.min((DVS.XP and DVS.XP.LootSpeedPerLevel or 0.02) * (lvl-1), 0.5)
    local dur = math.max(0.5, baseDur * speedMul)

    self:SetIsLooting(true)
    self:SetLootDur(dur)
    self:SetLootEnd(CurTime() + dur)
    self.Looter = ply

    net.Start("DSS_Loot_Begin"); net.WriteEntity(self); net.WriteFloat(dur); net.Send(ply)

    local checkName = "DSS_LootCheck_"..self:EntIndex()
    timer.Create(checkName, 0.1, 0, function()
        if not IsValid(self) then timer.Remove(checkName) return end
        if not IsValid(ply) then timer.Remove(checkName) self:SetIsLooting(false) return end
        if not self:GetIsLooting() then timer.Remove(checkName) return end

        local tr = ply:GetEyeTrace()
        local looking = IsValid(tr.Entity) and tr.Entity == self
        local dist = ply:GetPos():Distance(self:GetPos())

        if not looking or dist > (DVS and DVS.Looting and DVS.Looting.MaxDistance or 120) then
            self:SetIsLooting(false)
            timer.Remove(checkName)
            net.Start("DSS_Loot_End") net.Send(ply)
            --if DarkRP and DarkRP.notify then DarkRP.notify(ply, 1, 4, "Looting canceled.") end
            return
        end

        if CurTime() >= self:GetLootEnd() then
            timer.Remove(checkName)
            self:SetIsLooting(false)
            self.LootCooldown = CurTime() + cd
            self:DoLoot(ply)
            net.Start("DSS_Loot_End") net.Send(ply)
        end
    end)
end

function ENT:DoLoot(ply)
    if not DVS or not DVS.Lootables or not DVS.Lootables.Table then return end
    local t = DVS.Lootables.Table
    local basepos = self:GetPos() + self:GetUp()*40

    local rolls = (t.Rolls or 2)
    local milestones = (DVS.XP and DVS.XP.LootBonusMilestones) or {}
    local lvl = ply:GetNWInt("DVS_Level", 1)
    for _, m in ipairs(milestones) do if lvl >= m then rolls = rolls + 1 end end

    if t.ScrapPieces and math.random(1,100) <= (t.ScrapPieces.chance or 100) then
        local n = math.random(t.ScrapPieces.min or 1, t.ScrapPieces.max or 1)
        for i=1,n do
            local e = ents.Create("dubz_scrap")
            if IsValid(e) then e.ScrapAmount = math.random(1,3); e:SetPos(basepos + VectorRand()*20); e:Spawn() end
        end
    end

    local rarityBoost = 1 + ((DVS.XP and DVS.XP.RarityBoostPerLevel or 0.02) * (lvl-1))

    for i=1, rolls do
        for _, w in ipairs(t.Weapons or {}) do
            if math.random(1,100) <= (w.chance or 0) * rarityBoost then
                self:SpawnTimedEntity(w.class, basepos + VectorRand()*20)
                ply:SetNWInt("DVS_XP", ply:GetNWInt("DVS_XP",0) + ((DVS.XP and DVS.XP.RarityXP.rare) or 20))
            end
        end
        for _, eDef in ipairs(t.Entities or {}) do
            if math.random(1,100) <= (eDef.chance or 0) * rarityBoost then
                self:SpawnTimedEntity(eDef.class, basepos + VectorRand()*20)
                ply:SetNWInt("DVS_XP", ply:GetNWInt("DVS_XP",0) + ((DVS.XP and DVS.XP.RarityXP.uncommon) or 10))
            end
        end
        for _, p in ipairs(t.Props or {}) do
            if math.random(1,100) <= (p.chance or 0) * rarityBoost then
                self:SpawnTimedProp(p.model, basepos + VectorRand()*20)
                ply:SetNWInt("DVS_XP", ply:GetNWInt("DVS_XP",0) + ((DVS.XP and DVS.XP.RarityXP.common) or 5))
            end
        end
    end

    local level = ply:GetNWInt("DVS_Level",1)
    local xp = ply:GetNWInt("DVS_XP",0)
    local needed = math.max(1, level * ((DVS.XP and DVS.XP.LevelScale) or 100))
    while xp >= needed do
        level = level + 1; xp = xp - needed; needed = math.max(1, level * ((DVS.XP and DVS.XP.LevelScale) or 100))
        ply:SetNWInt("DVS_Level", level)
        net.Start("DSS_LevelUp") net.Send(ply)
        if DarkRP and DarkRP.notify then DarkRP.notify(ply, 0, 4, "Level Up! Level "..level) end
    end
    ply:SetNWInt("DVS_XP", xp)
end

properties.Add("dss_set_model", {
    MenuLabel = "Set Lootable Model...",
    Order = 1000,
    MenuIcon = "icon16/box.png",
    Filter = function(self, ent, ply) return IsValid(ent) and ent:GetClass()=="dubz_lootable" and (ply:IsAdmin() or ply:IsSuperAdmin()) end,
    Action = function(self, ent)
        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 120); frame:Center(); frame:SetTitle("Set Loot Model"); frame:MakePopup()
        local txt = vgui.Create("DTextEntry", frame); txt:SetPos(20, 50); txt:SetSize(360, 24); txt:SetText(ent:GetModel())
        local btn = vgui.Create("DButton", frame); btn:SetPos(20, 80); btn:SetSize(360, 24); btn:SetText("Apply")
        btn.DoClick = function() RunConsoleCommand("dss_set_loot_model", ent:EntIndex(), txt:GetValue()); frame:Close() end
    end
})

if SERVER then
    concommand.Add("dss_set_loot_model", function(ply, _, args)
        if not (IsValid(ply) and (ply:IsAdmin() or ply:IsSuperAdmin())) then return end
        local entIndex = tonumber(args[1] or "0")
        local model = tostring(args[2] or "")
        if not model or model == "" then return end
        local ent = Entity(entIndex or -1)
        if not IsValid(ent) or ent:GetClass() ~= "dubz_lootable" then return end
        ent:SetModel(model)
        ent:SetNWString("LootModel", model)
        local phys = ent:GetPhysicsObject(); if IsValid(phys) then phys:Wake() end
    end)
end
