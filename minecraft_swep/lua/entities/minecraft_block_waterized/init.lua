--************************************--
--  prop_waterized base (c) Meoo~we   --
--     everything else (c) McKay      --
--************************************--

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua')

-- Accessor Funcs
function ENT:SetBuoyancy( buo )
    self.Buoyancy = tonumber( buo )
end

function ENT:GetBuoyancy( )
    return self.Buoyancy
end

function ENT:SetPlayer( ply )
    self.Owner = ply
end

function ENT:GetPlayer( )
    return self.Owner
end

-- Serverside init
function ENT:Initialize()
	--remove hook
	hook.Add( "waterRemove", "waterremove", WOnRemove )
	self:CallOnRemove("waterremove",WOnRemove)
	
	-- Basic stufff
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:EnableMotion( false ) --freeze the block
		phys:Wake()
	end

    -- Nocollide
    self:SetCollisionGroup( COLLISION_GROUP_WORLD )
    self.CollisionGroup = COLLISION_GROUP_WORLD
	if (self:GetPlayer() != nil) then
		self:SetNotSolid(self:GetPlayer().w_EnableCollisions)
	end
	-- Set Trigger
	self.Entity:SetTrigger( true )
	
	self.lavaresiduetime = -1;
end

-- Start touch hook
function ENT:StartTouch( ent )
    if (!IsValid( ent ) or !IsValid(ent:GetPhysicsObject()) or ent:GetClass() == "minecraft_block_waterized") then return end

	--only ignite certain block types
	local canIgnite = true;
	if (ent:GetClass() == "minecraft_block") then
		canIgnite = false;
		local ID = ent:GetBlockID();
		if (ID == 28 or ID == 29 or ID == 31 or ID == 38 or ID == 47 or ID == 54 or ID == 62 or ID == 64 or ID == 65 or ID == 55
			or ID == 79 or ID == 80 or ID == 56 or ID == 40 or ID == 17) then
			canIgnite = true;
		end
	end
	
	--handle igniting
	if (self:GetNetworkedString("lava") == "true") then
		if ( GetCSConVarB( "minecraft_lavaigniteplayer", self.Owner ) == false and ent:IsPlayer() == false) then
			if (ent:IsOnFire() == false) then
				if ( GetCSConVarB( "minecraft_lavaigniteblocks", self.Owner ) == true) then
					if (canIgnite == true) then
						ent:Ignite(40,0)
					end
				else
					if (ent:GetName() != "mcblock" and canIgnite) then
						ent:Ignite(40,0)
					end			
				end
			end
		end
		if ( GetCSConVarB( "minecraft_lavaigniteplayer", self.Owner ) == true) then
			if (ent:IsOnFire() == false) then
				if ( GetCSConVarB( "minecraft_lavaigniteblocks", self.Owner ) == true) then
					ent:Ignite(40,0)
				end
				if ( GetCSConVarB( "minecraft_lavaigniteblocks", self.Owner ) == false and ent:GetName() != "mcblock") then
					ent:Ignite(40,0)
				end
            end
        end
	end
	
	--and extinguishing
	if (self:GetNetworkedString("water") == "true") then
		if (ent:IsOnFire()) then
			ent:Extinguish()
		end
	end
	
	if (ent:GetClass() == "minecraft_block") then return end --lag prevention
    -- Create table if necessary
    ent.w_WaterEnts = ent.w_WaterEnts or {}
    table.insert(ent.w_WaterEnts, self)
    if not ent:IsPlayer() then
        table.insert(w_EntsInWater, ent)
        return
    end
    -- UMsg
    umsg.Start("w_StartTouch", ent)
        umsg.Entity( self )
    umsg.End()
end

-- End touch hook
function ENT:EndTouch( ent )
	if (!IsValid( ent ) or !IsValid(ent:GetPhysicsObject()) or ent:GetClass() == "minecraft_block_waterized" or ent:GetClass() == "minecraft_block") then return end
	
    if not ent.w_WaterEnts then return end
    -- Delete unused entities
    for k, e in ipairs(ent.w_WaterEnts) do
        if not IsValid(e) or e == self then
            table.remove(ent.w_WaterEnts, k)
        end
    end
    -- Set nil when table is useless
    if #(ent.w_WaterEnts) == 0 then
        ent.w_WaterEnts = nil
        if ent.w_IsInWater then
            ent:SetGravity(1)
            ent.w_IsInWater = false
        end
    end
    if not ent:IsPlayer() then
        for k, e in ipairs(w_EntsInWater) do
            if not IsValid(e) or e == self then
                table.remove(w_EntsInWater, k)
            end
        end
        return
    end
    -- UMsg
    umsg.Start("w_EndTouch", ent)
        umsg.Entity( self )
    umsg.End()
end

function WOnRemove( ent )
	--if (GetConVar("minecraft_debug"):GetBool()) then print("water/lava block removed!") end
	ent:PostSpawn()
end

function ENT:PostSpawn()
	local t1 = self:GetNearbyBlock( 1,0,0,false );
	local t2 = self:GetNearbyBlock( 2,0,0,false );
	local t3 = self:GetNearbyBlock( 3,0,0,false );
	local t4 = self:GetNearbyBlock( 4,0,0,false );
	local t5 = self:GetNearbyBlock( 5,0,0,false );
	local t6 = self:GetNearbyBlock( 6,0,0,false );
	
	if (t1 != nil and t1 != NULL) then
		if (t1:IsValid()) then
			if (t1:GetClass() == "minecraft_block_waterized") then
				if (t1.child > 0) then
					t1.parent:SetDoUpdate( true )
				end
				t1:SetDoUpdate( true )
			else
				t1:SetDoUpdate( true )
			end
		end
	end
	if (t2 != nil and t2 != NULL) then
		if (t2:IsValid()) then
			if (t2:GetClass() == "minecraft_block_waterized") then
				if (t2.child > 0) then
					t2.parent:SetDoUpdate( true )
				end
				t2:SetDoUpdate( true )
			else
				t2:SetDoUpdate( true )
			end
		end
	end
	if (t3 != nil and t3 != NULL) then
		if (t3:IsValid()) then
			if (t3:GetClass() == "minecraft_block_waterized") then
				if (t3.child > 0) then
					t3.parent:SetDoUpdate( true )
				end
				t3:SetDoUpdate( true )
			else
				t3:SetDoUpdate( true )
			end
		end
	end
	if (t4 != nil and t4 != NULL) then
		if (t4:IsValid()) then
			if (t4:GetClass() == "minecraft_block_waterized") then
				if (t4.child > 0) then
					t4.parent:SetDoUpdate( true )
				end
				t4:SetDoUpdate( true )
			else
				t4:SetDoUpdate( true )
			end
		end
	end
	if (t5 != nil and t5 != NULL) then
		if (t5:IsValid()) then
			if (t5:GetClass() == "minecraft_block_waterized") then
				if (t5.child > 0) then
					t5.parent:SetDoUpdate( true )
				end
				t5:SetDoUpdate( true )
			else
				t5:SetDoUpdate( true )
			end
		end
	end
	if (t6 != nil and t6 != NULL) then
		if (t6:IsValid()) then
			if (t6:GetClass() == "minecraft_block_waterized") then
				if (t6.child > 0) then
					t6.parent:SetDoUpdate( true )
				end
				t6:SetDoUpdate( true )
			else
				t6:SetDoUpdate( true )
			end
		end
	end
end
