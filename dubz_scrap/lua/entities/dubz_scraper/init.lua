AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()

	self:SetModel("models/props_wasteland/laundry_washer003.mdl")
	self:SetMaterial("models/props_wasteland/tugboat01")

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self.ScrapAmount = 0
	self.ScrapAmount = math.Random(1, 3)
end

function ENT:AcceptInput( Name, ply)	
    if( Name == "Use" ) then
    	ent:Remove()
    	DarkRP.notify(ply, 0, 5, "You scrapped some scrap!")	
    end	
end