include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local pos = self:GetPos() + Vector(0, 0, 10)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), -90)

    local dist = ply:GetPos():DistToSqr(self:GetPos())
    if dist > 200000 then return end -- 450 units max draw distance

    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
        local alpha = math.Clamp(255 - (dist / 800), 0, 255)
        draw.RoundedBox(8, -60, -15, 120, 30, Color(0, 0, 0, 180))
        draw.SimpleTextOutlined("Scrap", "Trebuchet24", 0, 0, Color(0, 200, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200))
    cam.End3D2D()
end