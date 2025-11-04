include("autorun/dubz_dss_config.lua")
include("shared.lua")

local function SafeColor(c, fallback)
    if IsColor and IsColor(c) then return c end
    if istable(c) and c.r then
        return Color(c.r or 255, c.g or 255, c.b or 255, c.a or (fallback and fallback.a) or 255)
    end
    return fallback or color_white
end

local UI = (DVS and DVS.UIColors) or {}
local COL_BG     = SafeColor(UI.Background,    Color(20,20,20,240))
local COL_FRAME  = SafeColor(UI.Frame,         Color(30,30,30,255))
local COL_TEXT   = SafeColor(UI.TextPrimary,   Color(220,220,220))
local COL_ACCENT = SafeColor(UI.TextHighlight, Color(0,170,255))
local COL_BTN    = Color(35,35,35,220)
local COL_BTN_H  = Color(45,45,45,240)

--------------------------------------------------
-- 3D2D label
--------------------------------------------------
function ENT:Draw()
    self:DrawModel()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    if lp:GetPos():Distance(self:GetPos()) > 500 then return end
    local pos = self:GetPos() + Vector(0, 0, 80)
    local ang = Angle(0, lp:EyeAngles().y - 90, 90)
    cam.Start3D2D(pos, ang, 0.1)
        draw.RoundedBox(8, -150, -12, 300, 54, Color(0,0,0,180))
        draw.SimpleTextOutlined("Vendor NPC","DermaLarge",0,-8,color_white,
            TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,1,color_black)
    cam.End3D2D()
end

--------------------------------------------------
-- Networking
--------------------------------------------------
net.Receive("DVS_OpenVendor", function()
    local vendor = net.ReadEntity()
    if not IsValid(vendor) then return end
    net.Start("DVS_RequestVendor")
        net.WriteEntity(vendor)
    net.SendToServer()
end)

--------------------------------------------------
-- Vendor Menu
--------------------------------------------------
net.Receive("DVS_VendorData", function()
    local vendor = net.ReadEntity()
    local data   = net.ReadTable()
    if not IsValid(vendor) or not data then return end

    -- Fade-in animation
    local frame = vgui.Create("DFrame")
    frame:SetSize(820, 560)
    frame:Center()
    frame:SetTitle("")
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.3, 0)
    frame:MakePopup()
    frame.Paint = function(self,w,h)
        draw.RoundedBox(10,0,0,w,h,COL_FRAME)
        draw.RoundedBox(6,0,0,w,44,COL_ACCENT)
        draw.SimpleText("Vendor — "..(data.faction or "Unknown"),"Trebuchet24",18,10,
            color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
    end
    frame.OnClose = function(self)
        self:AlphaTo(0, 0.25, 0, function() self:Remove() end)
    end

    ---------------------------------------------
    -- SHOP AREA
    ---------------------------------------------
    local shopPanel = vgui.Create("DScrollPanel", frame)
    shopPanel:SetPos(12, 60)
    shopPanel:SetSize(frame:GetWide() - 292, frame:GetTall() - 72)
    shopPanel:DockMargin(0,0,12,0)

    local function AddSection(labelText, items)
        local header = vgui.Create("DPanel", shopPanel)
        header:Dock(TOP)
        header:SetTall(28)
        header:DockMargin(0,0,0,6)
        header.Paint = function(self,w,h)
            draw.RoundedBox(6,0,0,w,h,COL_ACCENT)
            draw.SimpleText(labelText or "","Trebuchet18",10,h/2,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
        end

        local list = vgui.Create("DIconLayout", shopPanel)
        list:Dock(TOP)
        list:SetSpaceY(8)
        list:SetSpaceX(8)
        list:DockMargin(0,0,0,12)

        if not items or #items==0 then
            local empty = vgui.Create("DPanel", list)
            empty:SetSize(700,40)
            empty.Paint=function(self,w,h)
                draw.RoundedBox(8,0,0,w,h,COL_BTN)
                draw.SimpleText("No "..string.lower(labelText or "").." available this refresh.",
                    "Trebuchet18",w/2,h/2,COL_TEXT,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            end
            return
        end

        for k,item in ipairs(items) do
            local pnl = list:Add("DPanel")
            pnl:SetSize(360,70)
            pnl.Paint=function(self,w,h)
                draw.RoundedBox(8,0,0,w,h,COL_BTN)
                draw.SimpleText(item.name or item.class or "Unknown","Trebuchet18",10,10,COL_TEXT,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
                draw.SimpleText("$"..tostring(item.price or 0),"Trebuchet18",10,h-10,COL_ACCENT,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
            end

            local buy = vgui.Create("DButton", pnl)
            buy:SetText("")
            buy:SetSize(90,34)
            buy:SetPos(pnl:GetWide()-98,(pnl:GetTall()-34)/2)
            buy.Paint=function(self,w,h)
                local col = self:IsHovered() and COL_ACCENT or COL_BTN
                draw.RoundedBox(6,0,0,w,h,col)
                draw.SimpleText("Buy","Trebuchet18",w/2,h/2,COL_TEXT,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            end
            buy.DoClick=function()
                surface.PlaySound("buttons/button14.wav")
                net.Start("DVS_BuyItem")
                    net.WriteEntity(vendor)
                    net.WriteString(labelText or "")
                    net.WriteUInt(k,8)
                net.SendToServer()
            end
        end
    end

    AddSection("Weapons",data.inv and data.inv.Weapons or {})
    AddSection("Entities",data.inv and data.inv.Entities or {})

    ---------------------------------------------
    -- SIDEBAR: Refresh Timer + Scrap Exchange
    ---------------------------------------------
    local sidebar = vgui.Create("DPanel", frame)
    sidebar:SetSize(260, frame:GetTall() - 72)
    sidebar:SetPos(frame:GetWide() - 272, 60)
    sidebar.Paint = function(self,w,h)
        draw.RoundedBox(10, 0, 0, w, h, COL_FRAME)
    end

    -- Refresh timer section
    local refreshTitle = vgui.Create("DLabel", sidebar)
    refreshTitle:SetText("Inventory refresh in:")
    refreshTitle:SetFont("Trebuchet18")
    refreshTitle:SetColor(COL_ACCENT)
    refreshTitle:SetContentAlignment(5)
    refreshTitle:SetSize(260, 28)
    refreshTitle:SetPos(0, 8)

    local refresh = vgui.Create("DLabel", sidebar)
    refresh:SetFont("Trebuchet24")
    refresh:SetColor(COL_ACCENT)
    refresh:SetContentAlignment(5)
    refresh:SetSize(260, 32)
    refresh:SetPos(0, 34)

    local lastSec = -1
    local blinkAlpha = 255
    local blinkDir = -6
    local refreshEnd = CurTime() + (data.nextRefresh or 900)
    refresh.Think = function(self)
        local t = math.max(0, math.floor(refreshEnd - CurTime()))
        local m = math.floor(t / 60)
        local s = t % 60
        if s ~= lastSec then
            blinkAlpha = 255
            lastSec = s
        else
            blinkAlpha = math.Clamp(blinkAlpha + blinkDir * 15 * FrameTime(), 150, 255)
        end
        self:SetColor(Color(COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, blinkAlpha))
        self:SetText(string.format("%02d:%02d", m, s))
    end

    -- Scrap Exchange section
    local header = vgui.Create("DPanel", sidebar)
    header:SetPos(0, 74)
    header:SetSize(260, 28)
    header.Paint = function(self,w,h)
        draw.RoundedBox(0, 0, 0, w, h, COL_ACCENT)
        draw.SimpleText("Scrap Exchange","Trebuchet18",10,h/2,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
    end

    local divider = vgui.Create("DPanel", sidebar)
    divider:SetPos(0, 102)
    divider:SetSize(260, 2)
    divider.Paint = function(self,w,h)
        surface.SetDrawColor(0,0,0,150)
        surface.DrawRect(0,0,w,h)
    end

    local content = vgui.Create("DPanel", sidebar)
    content:SetSize(240, sidebar:GetTall() - 130)
    content:SetPos(10, 110)
    content.Paint = nil

    -- Scrap price display (FINAL)
    local priceTitle = vgui.Create("DLabel", content)
    priceTitle:SetFont("Trebuchet18")
    priceTitle:SetText("Current scrap rate:")
    priceTitle:SetColor(COL_TEXT)
    priceTitle:SetContentAlignment(5)
    priceTitle:SetSize(240, 22)
    priceTitle:SetPos(0, 0)

    local priceValue = vgui.Create("DPanel", content)
    priceValue:SetSize(240, 44)
    priceValue:SetPos(0, 20)
    priceValue.Paint = function(self, w, h)
        draw.SimpleText("$" .. tostring(data.price or 0), "Trebuchet24", w / 2, 10, COL_ACCENT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("per scrap", "Trebuchet18", w / 2, 30, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local amount = vgui.Create("DPanel", content)
    amount:SetSize(240, 36)
    amount:SetPos(0, 70)
    amount.Paint = function(self,w,h)
        draw.RoundedBox(6,0,0,w,h,COL_BTN)
        draw.SimpleText("You have: "..tostring(LocalPlayer():GetNWInt("DVS_Scrap",0)).." scrap",
            "Trebuchet18",w/2,h/2,COL_TEXT,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end

    local sell = vgui.Create("DButton", content)
    sell:SetText("")
    sell:SetSize(240, 50)
    sell:SetPos(0, 116)
    sell.Paint = function(self,w,h)
        local scrapCount = LocalPlayer():GetNWInt("DVS_Scrap",0)
        local rate = tonumber(data.price or 0)
        local total = scrapCount * rate

        local col=self:IsHovered() and COL_ACCENT or COL_BTN
        draw.RoundedBox(8,0,0,w,h,col)
        draw.SimpleText("Sell All Scrap ($"..tostring(total)..")","Trebuchet24",w/2,h/2,COL_TEXT,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
    sell.DoClick = function()
        surface.PlaySound("buttons/button15.wav")
        net.Start("DVS_SellScrap")
            net.WriteEntity(vendor)
            net.WriteUInt(LocalPlayer():GetNWInt("DVS_Scrap",0),16)
        net.SendToServer()
        frame:Close()
    end
end)
