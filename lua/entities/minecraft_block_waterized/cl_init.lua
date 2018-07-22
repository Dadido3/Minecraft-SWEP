--************************************--
--  prop_waterized base (c) Meoo~we   --
--     everything else (c) McKay      --
--************************************--

include('shared.lua')

ENT.RenderGroup = RENDERGROUP_BOTH

-- Usermessages hooks
usermessage.Hook("w_StartTouch", function( um )
    local ent = um:ReadEntity()
    LocalPlayer().w_WaterEnts = LocalPlayer().w_WaterEnts or {}
    table.insert(LocalPlayer().w_WaterEnts, ent)
end )

usermessage.Hook("w_EndTouch", function( um )
    local ent = um:ReadEntity()
    if not LocalPlayer().w_WaterEnts then return end
    -- Delete unused entities
    for k, e in ipairs(LocalPlayer().w_WaterEnts) do
        if not IsValid(e) or e == ent then
            table.remove(LocalPlayer().w_WaterEnts, k)
        end
    end
    -- Set nil when table is useless
    if #(LocalPlayer().w_WaterEnts) == 0 then
        LocalPlayer():SetDSP(0)
        LocalPlayer().w_WaterEnts = nil
        LocalPlayer().w_IsInWater = false
    end
end )

function ENT:Initialize()
	
end

function WOnRemove( ent )
	
end	

