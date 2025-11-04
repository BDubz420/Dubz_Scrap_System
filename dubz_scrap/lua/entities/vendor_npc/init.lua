AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
include("autorun/dubz_dss_config.lua")

util.AddNetworkString("DVS_OpenVendor")
util.AddNetworkString("DVS_RequestVendor")
util.AddNetworkString("DVS_VendorData")
util.AddNetworkString("DVS_BuyItem")
util.AddNetworkString("DVS_SellScrap")

ENT.VendorFaction   = "Civilians"
ENT.NextRefresh     = 0
ENT.ScrapSellPrice  = 10
ENT.Inventory       = { Entities = {}, Weapons = {} }
ENT._NextVoice      = 0

local function GetFactionConfig(name)
    local f = (DVS and DVS.Factions and DVS.Factions[name]) or {}
    local d = (DVS and DVS.DefaultVendor) or {}
    return {
        ScrapSellRange   = f.ScrapSellRange   or d.ScrapSellRange   or {min = 6, max = 14},
        RefreshInterval  = f.RefreshInterval  or d.RefreshInterval  or 900,
        PriceFluctuation = f.PriceFluctuation or d.PriceFluctuation or 0.25,
        ShopItems        = f.ShopItems        or { Entities = {}, Weapons = {} }
    }
end

function ENT:Initialize()
    self:SetModel((DVS and DVS.Models and DVS.Models.Vendor) or "models/Humans/Group01/male_07.mdl")
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_SCRIPT)
    self:SetSolid(SOLID_BBOX)
    self:CapabilitiesAdd(bit.bor(CAP_ANIMATEDFACE, CAP_TURN_HEAD))
    self:SetUseType(SIMPLE_USE)
    self:DropToFloor()
    self:SetSchedule(SCHED_IDLE_STAND)
    self:VendorRefresh(true)
end

function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    net.Start("DVS_OpenVendor")
        net.WriteEntity(self)
    net.Send(ply)
end

function ENT:VendorRefresh(first)
    local cfg = GetFactionConfig(self.VendorFaction)

    -- Sell price
    self.ScrapSellPrice = math.random(cfg.ScrapSellRange.min, cfg.ScrapSellRange.max)

    -- Random pick helper
    local function pick(list)
        local copy = table.Copy(list or {})
        local out  = {}
        local count = math.Clamp(#copy, 0, 4)
        for i = 1, count do
            local idx = math.random(1, #copy)
            table.insert(out, table.remove(copy, idx))
        end
        return out
    end

    -- Build inventory
    local items = cfg.ShopItems or { Entities = {}, Weapons = {} }
    self.Inventory = {
        Entities = pick(items.Entities or {}),
        Weapons  = pick(items.Weapons  or {})
    }

    -- Price fluctuation
    local pf = cfg.PriceFluctuation or 0.25
    for _, bucket in pairs(self.Inventory) do
        for _, it in ipairs(bucket) do
            local base  = it.baseprice or 100
            local delta = base * pf
            it.price    = math.floor(math.Clamp(base + math.random(-delta, delta), 1, 999999))
        end
    end

    self.NextRefresh = CurTime() + (cfg.RefreshInterval or 900)

    -- Broadcast refresh
    for _, v in ipairs(player.GetAll()) do
        v:ChatPrint("📦 Vendor inventory has been refreshed!")
    end
end

function ENT:Think()
    -- timed refresh
    if CurTime() >= (self.NextRefresh or 0) then
        self:VendorRefresh()
    end

    -- eye tracking
    local nearest, nd = nil, 999999
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:Alive() then
            local d = p:GetPos():DistToSqr(self:GetPos())
            if d < nd then nd = d; nearest = p end
        end
    end
    if IsValid(nearest) and nd < (250 * 250) then
        self:SetEyeTarget(nearest:EyePos())
    end

    -- HL2 voice lines (if configured)
    if CurTime() >= (self._NextVoice or 0) then
        local vv = DVS and DVS.VendorVoices
        if vv and vv.Lines and #vv.Lines > 0 then
            self:EmitSound(vv.Lines[math.random(#vv.Lines)], 70, 100, 1, CHAN_AUTO)
            local mn = (vv.Interval and vv.Interval.min) or 25
            local mx = (vv.Interval and vv.Interval.max) or 60
            self._NextVoice = CurTime() + math.Rand(mn, mx)
        else
            self._NextVoice = CurTime() + 45
        end
    end
end

-- Send vendor data to client
net.Receive("DVS_RequestVendor", function(_, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) or ent:GetClass() ~= "vendor_npc" then return end

    local data = {
        faction     = ent.VendorFaction,
        nextRefresh = math.max((ent.NextRefresh or CurTime()) - CurTime(), 0),
        price       = ent.ScrapSellPrice or 10,
        inv         = ent.Inventory or {Entities = {}, Weapons = {}}
    }

    net.Start("DVS_VendorData")
        net.WriteEntity(ent)
        net.WriteTable(data)
    net.Send(ply)
end)

-- Buy item
net.Receive("DVS_BuyItem", function(_, ply)
    local ent    = net.ReadEntity()
    local bucket = net.ReadString()
    local idx    = net.ReadUInt(8)
    if not IsValid(ent) or ent:GetClass() ~= "vendor_npc" then return end

    local list = (ent.Inventory or {})[bucket]
    if not list or not list[idx] then return end

    local item  = list[idx]
    local price = item.price or 100

    if not ply:canAfford(price) then
        if DarkRP and DarkRP.notify then DarkRP.notify(ply, 1, 4, "You can't afford that.") end
        return
    end
    ply:addMoney(-price)

    local e = ents.Create(item.class)
    if IsValid(e) then
        e:SetPos(ply:GetPos() + ply:GetForward() * 40 + Vector(0, 0, 10))
        e:Spawn()
    end

    if DarkRP and DarkRP.notify then
        DarkRP.notify(ply, 0, 4, "Purchased " .. (item.name or item.class) .. " for $" .. price)
    end
end)

-- Sell scrap
net.Receive("DVS_SellScrap", function(_, ply)
    local ent    = net.ReadEntity()
    local amount = net.ReadUInt(16)
    if not IsValid(ent) or ent:GetClass() ~= "vendor_npc" then return end

    local have = ply:GetNWInt("DVS_Scrap", 0)
    local sell = math.min(have, amount)
    if sell <= 0 then
        if DarkRP and DarkRP.notify then DarkRP.notify(ply, 1, 4, "No scrap to sell.") end
        return
    end

    local total = sell * (ent.ScrapSellPrice or 10)
    ply:addMoney(total)
    ply:SetNWInt("DVS_Scrap", have - sell)

    if DarkRP and DarkRP.notify then
        DarkRP.notify(ply, 0, 4, "Sold " .. sell .. " scrap for $" .. total)
    end
end)
