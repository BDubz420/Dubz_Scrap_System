AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Scrapper"
ENT.Category = "Dubz Scrap System"
ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Busy")
end
