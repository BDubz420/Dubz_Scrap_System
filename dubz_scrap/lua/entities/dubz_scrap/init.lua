AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
include("autorun/dubz_dss_config.lua")

local function pickRandomScrapModel()
    local list = (DVS and DVS.Models and DVS.Models.Scrap) or {}
    if istable(list) and #list > 0 then
        return list[math.random(#list)]
    end
    return "models/props_debris/metal_panelchunk02d.mdl"
end

function ENT:Initialize()
    local saved = self:GetNWString("ScrapModel", "")
    local mdl = (saved ~= "" and saved) or pickRandomScrapModel()
    self:SetModel(mdl)
    self:SetNWString("ScrapModel", mdl)

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
    
    self.ScrapAmount = 1
end

function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local cur = ply:GetNWInt("DVS_Scrap", 0)
    local add = math.max(self.ScrapAmount or 1, 1)
    ply:SetNWInt("DVS_Scrap", cur + add)

    if DarkRP and DarkRP.notify then
        DarkRP.notify(ply, 0, 4, "Picked up " .. add .. " scrap.")
    else
        ply:ChatPrint("Picked up " .. add .. " scrap.")
    end

    self:Remove()
end
