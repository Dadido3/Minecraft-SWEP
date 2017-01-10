--************************************--
--  prop_waterized base (c) Meoo~we   --
--     everything else (c) McKay      --
--************************************--

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"
ENT.sptime			= 0
ENT.parent			= 0
ENT.child			= 0

ENT.maxspread		= 0
ENT.lavaresiduetime	= -1

local Card = {"x", "y", "z"}
-- Utility: IsPointInside
function ENT:IsPointInside( pt )
    local lPos = self:WorldToLocal( pt )
    local cPos = self:OBBMins()
    for _, k in ipairs(Card) do
        if cPos[k] > lPos[k] then return false end
    end
    cPos = self:OBBMaxs()
    for _, k in ipairs(Card) do
        if cPos[k] < lPos[k] then return false end
    end
    return true
end

-- Setup datatable hook
function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "BlockID" )
    self:NetworkVar( "Int", 1, "Damping" )
    self:NetworkVar( "Int", 2, "Density" )
	self:NetworkVar( "Bool", 3, "DoUpdate" )
end

--***************************************
--	Think - spreading
--***************************************

function ENT:Think( )
	--[[
	if (CLIENT) then return end
	if (self:GetNetworkedString("water") == "false" and self:GetNetworkedString("lava") == "false") then return end
	
	--if we are a child and our parent got removed, remove ourselves
	--lava leaves residue, water vanishes instantly
	if ((self.parent == nil or self.parent == NULL) and tonumber(self.child) > 0) then
		if (self:GetNetworkedString("water") == "false") then
			if (self.lavaresiduetime ~= nil) then
				if (CurTime() > self.lavaresiduetime and self.lavaresiduetime ~= -1) then
					self:Remove();
				end
				if (self.lavaresiduetime == -1) then
					self.lavaresiduetime = CurTime() + GetCSConVarI( "minecraft_lava_residuetime", self:GetPlayer() )
				end
			end
		else
			self:Remove();
		end
	end

	if ( GetConVar( "minecraft_swep_enable_water_spread" ):GetBool() and GetCSConVarB( "minecraft_water_spread", self:GetPlayer() ) and self:GetDoUpdate() ) then
		if (tonumber(self.child) >= GetCSConVarI( "minecraft_water_spread_LIMIT", self:GetPlayer() )) then return end
		if (tonumber(self.child) > 0 and (self.parent == nil or self.parent == NULL or tonumber(self.maxspread) == 0)) then return end
		if (CurTime() > self.sptime) then
			--Spreading logic
			local check = false
			local bottomBlock = self:GetNearbyBlock(2,0,0,true)
			--if (GetConVar("minecraft_debug"):GetBool()) then print("["..tostring(self.child).."] with maxspread = "..tostring(self.maxspread).." is updating...") end
			
			local southblock = self:GetNearbyBlock(3,0,0,false)
			if (southblock == nil and bottomBlock ~= nil and self.child < self.maxspread) then
				--if (GetConVar("minecraft_debug"):GetBool()) then print("water/lava is spreading... [south]") end
				local temp = self:Spread( 3, self.maxspread );
				check = true
			end
			local northblock = self:GetNearbyBlock(4,0,0,false)
			if (northblock == nil and bottomBlock ~= nil and self.child < self.maxspread) then
				--if (GetConVar("minecraft_debug"):GetBool()) then print("water/lava is spreading... [north]") end
				local temp = self:Spread( 4, self.maxspread );
				check = true
			end
			local westblock = self:GetNearbyBlock(5,0,0,false)
			if (westblock == nil and bottomBlock ~= nil and self.child < self.maxspread) then
				--if (GetConVar("minecraft_debug"):GetBool()) then print("water/lava is spreading... [west]") end
				local temp = self:Spread( 5, self.maxspread );
				check = true
			end
			local eastblock = self:GetNearbyBlock(6,0,0,false)
			if (eastblock == nil and bottomBlock ~= nil and self.child < self.maxspread) then
				--if (GetConVar("minecraft_debug"):GetBool()) then print("water/lava is spreading... [east]") end
				local temp = self:Spread( 6, self.maxspread );
				check = true
			end
			
			
			if (self:GetNearbyBlock(2,0,0,false) == nil and self.child <= self.maxspread) then
				--if (GetConVar("minecraft_debug"):GetBool()) then print("water/lava is spreading... [down]") end
				local temp = 0
				if (self:GetNWString("water") == "true") then
					temp = self:Spread( 2, self.child+1+GetCSConVarI( "minecraft_water_maxspread", self:GetPlayer() ) ); --woooooo it finally works correctly
				else
					temp = self:Spread( 2, self.child+2+GetCSConVarI( "minecraft_lava_maxspread", self:GetPlayer() ) );
				end
				--if (GetConVar("minecraft_debug"):GetBool()) then print("max_spread is now = "..tostring(temp.maxspread)) end
				--if (GetConVar("minecraft_debug"):GetBool()) then print("child is = "..tostring(temp.child)) end
				check = true		
			end
			if (!check) then
				--if (GetConVar("minecraft_debug"):GetBool()) then print("doUpdate STOP!") end
				self:SetDoUpdate( false )
			end
			if (self:GetNetworkedString("water") == "true") then
				self.sptime = CurTime() + GetCSConVarI( "minecraft_water_spreadspeed", self:GetPlayer() )
			else
				self.sptime = CurTime() + GetCSConVarI( "minecraft_lava_spreadspeed", self:GetPlayer() )
			end
			
			--water (source block) + lava (source block) creates obsidian, else it creates cobblestone
			local topblock = self:GetNearbyBlock(1,0,0,false)
			bottomblock = self:GetNearbyBlock(2,0,0,false)
			if (topblock ~= NULL) then
				self:ReplaceCheck( topblock )
			end
			if (bottomblock ~= NULL) then
				self:ReplaceCheck( bottomblock )
			end
			if (northblock ~= NULL) then
				self:ReplaceCheck( northblock )
			end
			if (eastblock ~= NULL) then
				self:ReplaceCheck( eastblock )
			end
			if (southblock ~= NULL) then
				self:ReplaceCheck( southblock )
			end
			if (westblock ~= NULL) then
				self:ReplaceCheck( westblock )
			end
		end
	end
	--]]
end

--************************************************
--	ReplaceCheck - used for water-lava collisions
--************************************************

function ENT:ReplaceCheck( block2 ) --block1 is self!
	if (block2 ~= nil) then
		if (block2:GetClass() == "minecraft_block_waterized" and block2 ~= self) then
			if (block2:GetNWString("water") == "true" and self:GetNWString("water") == "false") then
				--self is lava
				--replace child lava blocks with cobblestone, and the lava "source block" (parent block) with obsidian
				if (self.parent == 1) then
					self:SpawnMCBlock( self, 1);
					self:Remove();
				else
					self:SpawnMCBlock( self, 0);
					self:Remove();
				end
				block2:SetDoUpdate( true )
			end
			if (block2:GetNWString("water") == "false" and self:GetNWString("water") == "true") then
				--block2 is lava
				--replace child lava blocks with cobblestone, and the lava "source block" (parent block) with obsidian
				if (block2.parent == 1) then
					block2:SpawnMCBlock( block2, 1);
					block2:Remove();
				else
					block2:SpawnMCBlock( block2, 0);
					block2:Remove();
				end
				self:SetDoUpdate( true )
			end	
		end
	end
end

--***************************************
--	SpawnMCBlock - replace fluid block
--***************************************

function ENT:SpawnMCBlock( toreplace, blocktype )
	local ent = ents.Create( "minecraft_block" )
	if (blocktype == 1) then
		ent:SetModel( "models/MCModelPack/blocks/obsidian.mdl" )
	else
		ent:SetModel( "models/MCModelPack/blocks/cobblestone.mdl" )
	end
	ent:SetPos( toreplace:GetPos() )
	ent:PhysicsInitBox( toreplace:GetPos() + Vector( -18.25, -18.25, -18.25 ), toreplace:GetPos() + Vector(  18.25,  18.25,  18.25 ) )
	
	ent:SetKeyValue( "DisableShadows", "1" )
	ent:SetKeyValue( "targetname", "mcblock" )
	
	ent:SetPlayer( toreplace:GetPlayer() )
	
	if (blocktype == 1) then
		ent:SetBlockID( 14 )
		--ent:BlockInit( 14, toreplace )
	else
		ent:SetBlockID( 8 )
		--ent:BlockInit( 8, toreplace )
	end

	ent.health = GetConVar("minecraft_blockhealth"):GetInt()
	ent:Spawn()
	ent.spawned = true
	
	--this is causing massive fps lag because a LOT of blocks are updating at once
	if (blocktype == 1) then
		ent:PostSpawn( 14 )
	else
		ent:PostSpawn( 8 )
	end
end

--***************************************
--	Spread
--***************************************

function ENT:Spread( onSide, maxspread )
	local pos = self:GetPos()
	--pos.z = pos.z + 18.25; --center
	if (onSide == 1) then
		pos.z = pos.z + 36.5
	end
	if (onSide == 2) then
		pos.z = pos.z - 36.5;
	end
	if (onSide == 3) then
		pos.x = pos.x + 36.5;
	end
	if (onSide == 4) then
		pos.x = pos.x - 36.5;
	end
	if (onSide == 5) then
		pos.y = pos.y - 36.5;
	end
	if (onSide == 6) then
		pos.y = pos.y + 36.5;
	end
	
	local ent = ents.Create( "minecraft_block_waterized" )
			
	if (ent ~= NULL) then
		local what = self:GetNetworkedString("water")
		if (what == "true") then
			ent:SetModel( "models/MCModelPack/blocks/water.mdl" )
		else
			ent:SetModel( "models/MCModelPack/blocks/lava.mdl" )
		end
		ent:PhysicsInitBox( pos + Vector( -18.25, -18.25, -18.25 ), pos + Vector(  18.25,  18.25,  18.25 ) )
		ent:SetKeyValue( "DisableShadows", "1" )
		ent:SetKeyValue( "targetname", "mcblock" )
		ent:SetPos( pos )
		ent:SetPlayer( self:GetPlayer() )
		
		if (what == "true") then
			ent:SetDamping( 15 )
			ent:SetDensity( 70 )
			ent:SetBuoyancy( 600 )
		else
			ent:SetDamping( 40 )
			ent:SetDensity( 90 )
			ent:SetBuoyancy( 300 )
		end
		
		if (what == "true") then
			ent:SetNetworkedString( "water", "true" )
			ent:SetNetworkedString( "lava", "false" )
			ent.sptime = CurTime() + GetCSConVarF( "minecraft_water_spreadspeed", self:GetPlayer() )
			ent:SetBlockID( 41 )
		else
			ent:SetNetworkedString( "water", "false" )
			ent:SetNetworkedString( "lava", "true" )
			ent.sptime = CurTime() + GetCSConVarF( "minecraft_lava_spreadspeed", self:GetPlayer() )
			ent:SetBlockID( 42 )
		end
		ent.child = self.child+1;
		ent.parent = self
		ent.maxspread = maxspread
		
		ent:SetDoUpdate( true )
		ent:Spawn()	
		ent:PostSpawn()
		return ent;
	end
	return nil
end

function ENT:GetNearbyBlock( onSide, zmult, posmult, noself )
	if ( onSide <= 0 or onSide > 6) then print("nope.avi") return end
	--1 = top, 2 = bottom, 3 = front, 4 = back, 5 = left, 6 = right [when looking at a block in front of you and looking to the north!]
	--zmult = {-1,0,1} block detection in a 3x3 grid
	--posmult = {-1,0,1} block detection in a 3x3 grid
	
	local bounds = 15;
	local pos = self:GetPos();
	pos.z = pos.z + 18.25; --center
	if (posmult == 1) then
		posmult = posmult + 1
	end
	if (posmult == 0) then
		posmult = 1;
	end
	if (onSide == 1) then
		pos.z = pos.z + 36.5
	end
	if (onSide == 2) then
		pos.z = pos.z - 36.5;
	end
	if (onSide == 3) then
		pos.x = pos.x + 36.5*posmult;
	end
	if (onSide == 4) then
		pos.x = pos.x - 36.5*posmult;
	end
	if (onSide == 5) then
		pos.y = pos.y - 36.5*posmult;
	end
	if (onSide == 6) then
		pos.y = pos.y + 36.5*posmult;
	end
	
	if (zmult ~= 0) then
		pos.z = pos.z + 36.5*zmult
	end
	for k, v in pairs( ents.FindInBox( pos + Vector(-bounds,-bounds,-bounds), pos + Vector(bounds,bounds,bounds) ) ) do
		if ( v:IsValid() and v ~= self ) then
			if ( v:GetClass() == "minecraft_block") then
				--if (GetConVar("minecraft_debug"):GetBool()) then print("[lava/water] found nearby block with ID = " .. tostring(v:GetBlockID())) end
				return v;
			end
			if ( v:GetClass() == "minecraft_block_waterized" and noself == false) then
				--if (GetConVar("minecraft_debug"):GetBool()) then print("water block is blocking the way") end
				return v;
			end
		end
	end
	--test tracer for detecting world geometry
	--local tracelength = GetConVar("minecraft_water_worldcollision_trl"):GetFloat();
	local tracelength = 14
	local endpos = pos;
	endpos.z = endpos.z - tracelength; --i have to use fixed values again fffffffuuuuuuuUUUUUUUUUUUU; why is 18.25 exactly 1 block too high??!
	local tracedata = {}
	tracedata.start = pos
	tracedata.endpos = endpos
	tracedata.filter = self:GetPlayer()
	local trace = util.TraceLine( tracedata )
	if (trace.HitWorld) then
		return NULL
	else
		return nil
	end
	--and check all 4 sides
	endpos = pos;
	endpos.x = endpos.x - tracelength;
	tracedata.endpos = endpos;
	trace = util.TraceLine( tracedata )
	if (trace.HitWorld) then
		return NULL
	else
		return nil
	end
	
	endpos = pos;
	endpos.x = endpos.x + tracelength;
	tracedata.endpos = endpos;
	trace = util.TraceLine( tracedata )
	if (trace.HitWorld) then
		return NULL
	else
		return nil
	end
	
	endpos = pos;
	endpos.y = endpos.y - tracelength;
	tracedata.endpos = endpos;
	trace = util.TraceLine( tracedata )
	if (trace.HitWorld) then
		return NULL
	else
		return nil
	end
	
	endpos = pos;
	endpos.y = endpos.y + tracelength;
	tracedata.endpos = endpos;
	trace = util.TraceLine( tracedata )
	if (trace.HitWorld) then
		return NULL
	else
		return nil
	end
end
