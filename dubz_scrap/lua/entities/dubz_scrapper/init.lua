AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
include("autorun/dubz_dss_config.lua")

function ENT:Initialize()
    self:SetModel((DVS and DVS.Models and DVS.Models.Scrapper) or "models/props_wasteland/laundry_washer003.mdl")
    self:SetMaterial("models/props_wasteland/tugboat01")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
    end

    self:SetBusy(false)
    self._basePos = self:GetPos()
    self._baseAng = self:GetAngles()
    self._csLoop = nil
end

function ENT:OnRemove()
    self:StopAllSounds()
    timer.Remove("DVS_ScrapClunks_" .. self:EntIndex())
    timer.Remove("DVS_ScrapShake_" .. self:EntIndex())
end

function ENT:StopAllSounds()
    local s = DVS and DVS.Scrapper and DVS.Scrapper.Sounds or {}
    local loopPath = s.Loop or ""
    if self._csLoop then
        self._csLoop:FadeOut(0.5)
        timer.Simple(0.6, function()
            if IsValid(self._csLoop) then self._csLoop:Stop() end
            self._csLoop = nil
        end)
    end
    if loopPath ~= "" then self:StopSound(loopPath) end
end

local function classAllowed(classname)
    local allowed = (DVS and DVS.Scrapper and DVS.Scrapper.AllowedItems) or {}
    for _, c in ipairs(allowed) do if c == classname then return true end end
    return false
end

function ENT:StartTouch(ent)
    if not IsValid(ent) or self:GetBusy() then return end
    if not classAllowed(ent:GetClass()) then return end
    self:BeginScrap(ent)
end

function ENT:BeginScrap(ent)
    local cfg = DVS and DVS.Scrapper or {}
    local dur = cfg.Duration or 3
    local s = cfg.Sounds or {}

    self:SetBusy(true)
    local startPos, startAng = self:GetPos(), self:GetAngles()
    if IsValid(ent) then ent:Remove() end

    if s.Start then self:EmitSound(s.Start, 75, 100, 1, CHAN_AUTO) end
    if s.Loop then
        self._csLoop = CreateSound(self, s.Loop)
        if self._csLoop then self._csLoop:SetSoundLevel(75) self._csLoop:PlayEx(1,100) end
    end

    local clunkID = "DVS_ScrapClunks_" .. self:EntIndex()
    timer.Create(clunkID, math.Rand(1.5,3.5), 0, function()
        if not IsValid(self) or not self:GetBusy() then timer.Remove(clunkID) return end
        local cl = s.Clunks or {}
        if #cl>0 then self:EmitSound(cl[math.random(#cl)],75,math.random(95,105),0.8,CHAN_AUTO) end
        timer.Adjust(clunkID, math.Rand(1.5,3.5), 1)
    end)

    local pattern = {
        Angle(0.5,0.4,-0.3), Angle(-0.4,-0.5,0.5),
        Angle(0.6,-0.4,0.3), Angle(-0.5,0.4,-0.4)
    }
    local step=1
    local shakeID="DVS_ScrapShake_"..self:EntIndex()
    timer.Create(shakeID,0.1,math.floor(dur/0.1),function()
        if not IsValid(self) or not self:GetBusy() then timer.Remove(shakeID) return end
        self:SetAngles(startAng + pattern[step])
        step=step+1 if step>#pattern then step=1 end
        local ed=EffectData() ed:SetOrigin(startPos + self:GetUp()*20)
        ed:SetMagnitude(1) ed:SetScale(1) ed:SetRadius(2)
        util.Effect("Sparks",ed,true,true)
    end)

    timer.Simple(dur,function()
        if not IsValid(self) then return end
        self:SetPos(startPos) self:SetAngles(startAng)
        self:FinishScrap()
        if s.End then self:EmitSound(s.End,75,100,1,CHAN_AUTO) end
    end)
end

function ENT:FinishScrap()
    local cfg = DVS and DVS.Scrapper or {}
    self:SetBusy(false)
    timer.Remove("DVS_ScrapClunks_"..self:EntIndex())
    timer.Remove("DVS_ScrapShake_"..self:EntIndex())

    local minOut,maxOut=cfg.ScrapOutput.min or 1,cfg.ScrapOutput.max or 3
    local count=math.random(minOut,maxOut)

    for i=1,count do
        local s=ents.Create("dubz_scrap")
        if IsValid(s) then s:SetPos(self:GetPos()+self:GetUp()*30+VectorRand()*10) s:Spawn() end
    end

    -- 🔹 XP Reward System
    local xpCfg=cfg.XPReward or {}
    local baseXP=xpCfg.Base or 10
    local perScrap=xpCfg.PerScrap or 5
    local scale=xpCfg.LevelScale or 0
    local totalXP=baseXP+(count*perScrap)

    -- Find nearby player (scrapper user)
    local ply=nil
    for _,v in ipairs(ents.FindInSphere(self:GetPos(),128)) do
        if v:IsPlayer() then ply=v break end
    end

    if IsValid(ply) then
        local lvl=ply:GetNWInt("DVS_Level",1)
        totalXP=totalXP*(1+(lvl*scale))

        if DVS.Events.Enabled and DVS.Events.Multipliers and DVS.Events.Multipliers.XPGainBoost then
            totalXP=totalXP*(DVS.Events.Multipliers.XPGainBoost or 1)
        end

        local curXP=ply:GetNWInt("DVS_XP",0)
        ply:SetNWInt("DVS_XP",curXP+math.floor(totalXP))

        if DarkRP and DarkRP.notify then
            DarkRP.notify(ply,0,4,"You gained "..math.floor(totalXP).." XP for scrapping!")
        else
            ply:ChatPrint("You gained "..math.floor(totalXP).." XP for scrapping!")
        end

        if DVS.CheckLevelUp then DVS.CheckLevelUp(ply) end
    end

    self:StopAllSounds()
end
