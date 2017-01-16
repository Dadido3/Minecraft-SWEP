--********************************--
--     Minecraft Block Entity     --
--			 (c) McKay			  --
--********************************--

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua')

--Accessor Funcs
function ENT:SetPlayer( ply )
    self.Owner = ply
end

function ENT:GetPlayer( )
    return self.Owner
end

--***************************************
--	Serverside init
--***************************************

function ENT:Initialize()
	--remove hook
	--hook.Add( "OnRemove", "blockremove", OnRemove )
	--self:CallOnRemove("blockremove",OnRemove)
    --Basic stuff
    self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )   
	-- Wake the physics object up
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:EnableMotion( false ) --freeze the block
		phys:Wake()
	end
	
	self.simpleRemove = false
	self:SetUseType( SIMPLE_USE )
end

--***************************************
--	OnTakeDamage
--***************************************

function ENT:OnTakeDamage( dmginfo )
	local attacker = dmginfo:GetAttacker()
	
	-- React physically when shot/getting blown
	self.Entity:TakePhysicsDamage( dmginfo )
	
	self.health = self.health - dmginfo:GetDamage()
	if self.health <= 0 then
		self.health = 0
		self:RemoveSpecial()
	end
	
	-- ZS Specific: Show damage floater
	if gmod.GetGamemode().DamageFloater then
		gmod.GetGamemode():DamageFloater( attacker, self, dmginfo)
	end
end

--***************************************
--	Remove with particle effects
--***************************************

function ENT:RemoveSpecial()
	--can't touch this (anymore)
	self:SetNotSolid( true )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetNoDraw( true )
	
	self:OnRemoveSpecial()
	
	if self.health ~= -1 and ( not IsValid( self:GetPlayer() ) or GetCSConVarB( "minecraft_particles", self:GetPlayer() ) ) then
		--create particle effect
		local effect = EffectData();
		local pos = self:GetPos();
		local aabb_min, aabb_max = self:WorldSpaceAABB();
		local zadd = math.abs(aabb_min.z - aabb_max.z)/2
		pos.z = pos.z + zadd;
		effect:SetOrigin( pos )
		effect:SetNormal( Vector(0,0,1) );
		effect:SetEntity( self )
		util.Effect( "mc-sparkle", effect, true, true );
		
		--properly remove 0.2 seconds
		timer.Simple( 0.2, function() if ( IsValid( self ) ) then self:Remove() end end )
	else
		self:Remove()
	end
end

--***************************************
--	OnSpawn - sounds and health values
--***************************************

function ENT:OnSpawn( ID, hitEntity )
	
	blockType = MC.BlockTypes[ID]
	
	self.health = blockType.health
	
	self.stable = true
	
	if not GetCSConVarB( "minecraft_disablesounds", self.Owner ) then
		self:EmitSound( table.Random( blockType.material.soundTable ), 510, math.random(60,100))
	end
	
	self.spawned = true
end

--***************************************
--	PostSpawn - update nearby blocks
--***************************************

function ENT:PostSpawn ( ID )
	--notify all nearby blocks to update themselves
	--i think it's more efficient to update the blocks on spawn instead of every Think() cycle?
	--even though we are calling the function 6 times.. (idk)
	local t1 = self:GetNearbyBlock( MC.cubeFace.top )
	local t2 = self:GetNearbyBlock( MC.cubeFace.bottom )
	local t3 = self:GetNearbyBlock( MC.cubeFace.north )
	local t4 = self:GetNearbyBlock( MC.cubeFace.south )
	local t5 = self:GetNearbyBlock( MC.cubeFace.east )
	local t6 = self:GetNearbyBlock( MC.cubeFace.west )
	
	if (t1 ~= nil) then
		if (t1:IsValid()) then
			t1:SetDoUpdate( true )
		end
	end
	if (t2 ~= nil) then
		if (t2:IsValid()) then
			t2:SetDoUpdate( true )
		end
	end
	if (t3 ~= nil) then
		if (t3:IsValid()) then
			t3:SetDoUpdate( true )
		end
	end
	if (t4 ~= nil) then
		if (t4:IsValid()) then
			t4:SetDoUpdate( true )
		end
	end
	if (t5 ~= nil) then
		if (t5:IsValid()) then
			t5:SetDoUpdate( true )
		end
	end
	if (t6 ~= nil) then
		if (t6:IsValid()) then
			t6:SetDoUpdate( true )
		end
	end
end

--***********************************************
--	OnRemove - sounds, particles and other stuff
--***********************************************

--all blocks added to both these will get autodestroyed when the block they were placed on gets destroyed
--TODO: why doesn't   !(blockID >= 135 and blockID <= 171)    work ???
function notBlockToDestroy( blockID )
	if ( blockID ~= 56 and blockID ~= 65 and blockID ~= 66 and blockID ~= 67 and blockID ~= 68 and blockID ~= 98 and blockID ~= 109 and blockID ~= 110
		and blockID ~= 89 and blockID ~= 90 and blockID ~= 91) then
		return true
	else
		return false
	end
end

function orBlockToDestroy( blockID )
	if ( blockID == 56 or blockID == 65 or blockID == 66 or blockID == 67 or blockID == 68 or blockID == 98 or blockID == 109 or blockID == 110
		or blockID == 89 or blockID == 90 or blockID == 91) then
		return true
	else
		return false
	end
end

function ENT:OnRemoveSpecial( )
	if self.spawned == false then return end
	if self.simpleRemove == true then return end --to get rid of NULL entity bugs because self:GetPlayer = "Player [NULL]"
	
	local ID = self:GetBlockID();
	--if (GetConVar("minecraft_debug"):GetBool()) then print("block with ID = " .. tostring(ID) .. " removed!") end
	
	self.stable = false
	
	--test: spawn a water block if an ice block breaks
	--[[if (ID == 40) then
		if (self.health <= 0 and self.health ~= -1 and self.health ~= -2) then --if we were killed by taking damage
			--if (GetConVar("minecraft_debug"):GetBool()) then print("spawning water block in place of ice block...") end
			local ent = ents.Create( "minecraft_block_waterized" )
			
			ent:SetModel( "models/MCModelPack/blocks/water.mdl" )
			ent:PhysicsInitBox( self:GetPos() + Vector( -18.25, -18.25, -18.25 ), self:GetPos() + Vector(  18.25,  18.25,  18.25 ) )
			ent:SetKeyValue( "DisableShadows", "1" )
			ent:SetKeyValue( "targetname", "mcblock" )
			ent:SetPos( self:GetPos() )
			ent:SetPlayer( self:GetPlayer() )
		
			ent:SetDamping( 15 )
			ent:SetDensity( 70 )
			ent:SetBuoyancy( 600 )
		
			ent:SetNetworkedString( "water", "true" )
			ent:SetNetworkedString( "lava", "false" )
		
			ent.parent = 1
			--ent.maxspread = GetCSConVarI( "minecraft_water_maxspread", self:GetPlayer() )
			ent.maxspread = 2
			ent:SetBlockID( 41 )
			ent:SetDoUpdate( true )
			--if (GetConVar("minecraft_debug"):GetBool()) then ent:SetColor(255,0,0,255) end
			ent:Spawn()
		end
	end--]]
	
	if self.health <= 0 and self.health ~= -1 and ( not IsValid( self:GetPlayer() ) or not GetCSConVarB( "minecraft_disablesounds", self.Owner ) ) then
		local hasSound = false;
		
		--grass
		if (ID == 38 or ID == 70 or ID == 71 or ID == 39 or ID == 2 or ID == 82 or ID == 108 or ID == 123 or ID == 172 or ID == 173 or ID == 183  or ID == 190 or ID == 191 or ID == 192) then
			local grass = { Sound("minecraft/grass1.wav"),Sound("minecraft/grass2.wav"),Sound("minecraft/grass3.wav"),Sound("minecraft/grass4.wav") }
			self:EmitSound( table.Random( grass ), 510, math.random(60,100) )
			hasSound = true;
		end
		
		--stone
		if (ID == 7 or ID == 8 or ID == 9 or ID == 10 or ID == 11 or ID == 12 or ID == 13 or ID == 14 or ID == 15
			or ID == 16 or ID == 19 or ID == 23 or ID == 24 or ID == 37 or ID == 44 or ID == 45 or ID == 46 or ID == 48 or ID == 50
			or ID == 51 or ID == 52 or ID == 53 or ID == 57 or ID == 58 or ID == 63 or ID == 68 or ID == 34 or ID == 49
			or ID == 94 or ID == 95 or ID == 98 or (ID >= 86 and ID <= 88)  or ID == 107 or (ID >= 123 and ID <= 134) or ID == 174 or ID == 175 
			or ID == 176 or ID == 177 or ID == 178 or ID == 180 or ID == 181 or ID == 184 or ID == 185 or ID == 186 or ID == 187 or ID == 197 or ID == 200) then
			
			local stone = { Sound("minecraft/stone1.wav"),Sound("minecraft/stone2.wav"),Sound("minecraft/stone3.wav"),Sound("minecraft/stone4.wav") }
			self:EmitSound( table.Random( stone ), 511, math.random(60,100) )
			hasSound = true;
		end
		
		--wood
		if (ID == 25 or ID == 26 or ID == 27 or ID == 28 or ID == 29 or ID == 30 or ID == 31 or ID == 47 or ID == 54
			or ID == 62 or ID == 64 or ID == 65 or ID == 66 or ID == 67 or ID == 77 or ID == 78 or ID == 55 or ID == 32
			or ID == 72 or ID == 96 or ID == 97 or (ID >= 99 and ID <= 106) or (ID >= 89 and ID <= 93) or ID == 109
			or (ID >= 135 and ID <= 171) or (ID >= 110 and ID <= 116) or ID == 188 or ID == 193 or ID == 194 or ID == 195 or ID == 199) then
			
			local wood = { Sound("minecraft/wood1.wav"),Sound("minecraft/wood2.wav"),Sound("minecraft/wood3.wav"),Sound("minecraft/wood4.wav") }
			self:EmitSound( table.Random( wood ), 511, math.random(60,100) )
			hasSound = true;
		end
		
		--gravel
		if (ID == 1 or ID == 3 or ID == 4) then
			local gravel = { Sound("minecraft/gravel1.wav"),Sound("minecraft/gravel2.wav"),Sound("minecraft/gravel3.wav"),Sound("minecraft/gravel4.wav") }
			self:EmitSound( table.Random( gravel ), 511, math.random(60,100) )
			hasSound = true;
		end
		
		--snow
		if (ID == 5 or ID == 17 or ID == 56) then
			local snow = { Sound("minecraft/snow1.wav"),Sound("minecraft/snow2.wav"),Sound("minecraft/snow3.wav"),Sound("minecraft/snow4.wav") }
			self:EmitSound( table.Random( snow ), 511, math.random(60,100) )
			hasSound = true;
		end
		
		--cloth
		if (ID == 79 or ID == 80 or ID == 35 or ID == 36) then
			local cloth = { Sound("minecraft/cloth1.wav"),Sound("minecraft/cloth2.wav"),Sound("minecraft/cloth3.wav"),Sound("minecraft/cloth4.wav") }
			self:EmitSound( table.Random( cloth ), 511, math.random(60,100) )
			hasSound = true;
		end
		
		--sand
		if (ID == 6 or ID == 20 or ID == 189) then
			local sand = { Sound("minecraft/sand1.wav"),Sound("minecraft/sand2.wav"),Sound("minecraft/sand3.wav"),Sound("minecraft/sand4.wav") }
			self:EmitSound( table.Random( sand ), 510, math.random(60,100))
			hasSound = true;
		end		
		
		--glass
		if (ID == 21 or ID == 22 or ID == 40 or ID == 61 or ID == 85 or ID == 182 or ID == 198) then
			local glass = { Sound("minecraft/glass_1.wav"),Sound("minecraft/glass_2.wav"),Sound("minecraft/glass_3.wav") }
			self:EmitSound( table.Random( glass ), 510, math.random(90,110))
			hasSound = true;
		end
		
		if (hasSound == false) then
			--if (GetConVar("minecraft_debug"):GetBool()) then print("blocks with ID = " .. tostring(ID) .. " have no remove sounds implemented!!!") end
		end
	end
	
	--update all nearby blocks
	local t1 = self:GetNearbyBlock( MC.cubeFace.top )
	local t2 = self:GetNearbyBlock( MC.cubeFace.bottom )
	local t3 = self:GetNearbyBlock( MC.cubeFace.north )
	local t4 = self:GetNearbyBlock( MC.cubeFace.south )
	local t5 = self:GetNearbyBlock( MC.cubeFace.east )
	local t6 = self:GetNearbyBlock( MC.cubeFace.west )
	
	if IsValid( t1 ) then
		t1:SetDoUpdate( true )
		t1:SetUpdateStability( true )
		--remove torches if their base block is removed
		--HACKHACK: when deleting other blocks nearby, torches may also get removed
		--HACKHACK: I'm too lazy to fix that now
		if (notBlockToDestroy(ID)) then
			local ID2 = t1:GetBlockID()
			if (orBlockToDestroy(ID2)) then
				t1.Entity.health = -2
				t1:Remove()
			end
		end
	end
	if IsValid( t2 ) then
		t2:SetDoUpdate( true )
		t2:SetUpdateStability( true )
	end
	if IsValid( t3 ) then
		t3:SetDoUpdate( true )
		t3:SetUpdateStability( true )
		if (notBlockToDestroy(ID)) then
			local ID2 = t3:GetBlockID()
			if (orBlockToDestroy(ID2)) then
				t3.Entity.health = -2
				t3:Remove()
			end
		end
	end
	if IsValid( t4 ) then
		t4:SetDoUpdate( true )
		t4:SetUpdateStability( true )
		if (notBlockToDestroy(ID)) then
			local ID2 = t4:GetBlockID()
			if (orBlockToDestroy(ID2)) then
				t4.Entity.health = -2
				t4:Remove()
			end
		end
	end
	if IsValid( t5 ) then
		t5:SetDoUpdate( true )
		t5:SetUpdateStability( true )
		if (notBlockToDestroy(ID)) then
			local ID2 = t5:GetBlockID()
			if (orBlockToDestroy(ID2)) then
				t5.Entity.health = -2
				t5:Remove()
			end
		end
	end
	if IsValid( t6 ) then
		t6:SetDoUpdate( true )
		t6:SetUpdateStability( true )
		if (notBlockToDestroy(ID)) then
			local ID2 = t6:GetBlockID()
			if (orBlockToDestroy(ID2)) then
				t6.Entity.health = -2
				t6:Remove()
			end
		end
	end
end
