AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Lootable"
ENT.Category = "Dubz Scrap System"
ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "LootEnd")
    self:NetworkVar("Float", 1, "LootDur")
    self:NetworkVar("Bool",  0, "IsLooting")
    self:NetworkVar("String", 0, "LootModel")
end
