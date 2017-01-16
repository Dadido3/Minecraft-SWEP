--********************************--
--     Minecraft Block Entity     --
--			 (c) McKay			  --
--********************************--

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"
ENT.health			= 100
ENT.spawned 		= false
ENT.blockID			= 0

blockNewPanel = 1

--Setup datatable hook
function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "BlockID" )
	self:NetworkVar( "Int", 1, "Rotation" )
	self:NetworkVar( "Bool", 0, "DoUpdate" )
	
	self:NetworkVar( "Bool", 1, "UpdateStability" )
	self:NetworkVar( "Float", 0, "Stability" )
end

--*******************************************
--	CheckPos - check for block overlapping
--*******************************************

function ENT:CheckPos( ID )
	local blockType = MC.BlockTypes[ID]
	if blockType.noCollide then return true end
	
	local AA, BB = self:GetRotatedAABB( self:OBBMins(), self:OBBMaxs() )
	local BBSize = BB - AA
	
	local pos = self:GetPos()
	local posCenter = pos + AA + BBSize * 0.5
	
	-- Search for other block entities
	local searchBox = BBSize - Vector( 4, 4, 4 )
	for k, v in pairs( ents.FindInBox( posCenter - searchBox / 2, posCenter + searchBox / 2 ) ) do
		if IsValid( v ) and v ~= self and v:GetClass() == "minecraft_block" then
			return false
		end
	end
	
	--cldebugoverlay.Box( self.Owner, posCenter, -searchBox / 2, searchBox / 2, 5, Color( 255, 255, 0, 127 ) )
	
	-- Search for player entities
	local searchBox = BBSize - Vector( 2.6, 2.6, 2.6 )
	for k, v in pairs( ents.FindInBox( posCenter - searchBox / 2, posCenter + searchBox / 2 ) ) do
		if IsValid( v ) and v ~= self and v:GetClass() == "player" and v:GetMoveType() ~= MOVETYPE_NOCLIP then
			return false
		end
	end
	
	return true
end

--*******************************************
--	GetNearbyBlock
--*******************************************

function ENT:GetNearbyBlock( direction )
	-- Use MC.cubeFace. with { top, bottom, west, east, north, south }
	
	-- Deprecated direction numbers: 1 = top, 2 = bottom, 3 = front, 4 = back, 5 = left, 6 = right [when looking at a block in front of you and looking to the north!]
	-- Translating old numbers to the new variables: 1 --> top, 2 --> bottom, 3 --> north, 4 --> south, 5 --> east, 6 --> west
	
	local AA, BB = self:GetRotatedAABB( self:OBBMins(), self:OBBMaxs() )
	local BBSize = BB - AA
	
	local pos = self:GetPos()
	local posCenter = pos + AA + BBSize * 0.5
	local normal = MC.cubeFaceNormal[direction]
	local normalAbs = Vector( math.abs( normal.x ), math.abs( normal.y ), math.abs( normal.z ) )
	local normalAbsInverse = Vector( 1, 1, 1 ) - normalAbs
	local searchBox = Vector( normalAbsInverse.x * BBSize.x, normalAbsInverse.y * BBSize.y, normalAbsInverse.z * BBSize.z ) + normalAbs * 0.5 * MC.cubeSize - Vector( 3, 3, 3 )
	local offset = Vector( normal.x * BBSize.x, normal.y * BBSize.y, normal.z * BBSize.z )
	local neighbourPos = posCenter + offset * 0.5 + MC.cubeSize * normal * 1 / 4
	
	--cldebugoverlay.EntityTextAtPosition( self.Owner, pos, 0, tostring(self) .. ", " .. self:GetBlockID(), 5 )
	--cldebugoverlay.Box( self.Owner, neighbourPos, -searchBox/2, searchBox/2, 5, Color( 0, 255, 0, 10 ) )
	
	for k, v in pairs( ents.FindInBox( neighbourPos - searchBox / 2, neighbourPos + searchBox / 2 ) ) do
		if IsValid( v ) and v ~= self then
			if ( v:GetClass() == "minecraft_block" or v:GetClass() == "minecraft_block_waterized" ) and v.stable then
				--cldebugoverlay.Box( self.Owner, neighbourPos, -Vector(bounds,bounds,bounds), Vector(bounds,bounds,bounds), 7, Color( 255, 0, 0, 10 ) )
				--cldebugoverlay.Line( self.Owner, posCenter + Vector(5,5,5), neighbourPos, 7, Color( 255, 0, 0, 10 ), true )
				--if (GetConVar("minecraft_debug"):GetBool()) then print("[" ..tostring(self:self:GetBlockID()) .. "] found nearby block with ID = " .. tostring(v:GetBlockID())) end
				return v
			end
		end
	end
	
	-- Test if it hits at least the world in the given direction
	local tracedata = {}
	tracedata.start = posCenter
	tracedata.endpos = posCenter + MC.cubeFaceNormal[direction] * MC.cubeSize
	tracedata.filter = { self, self.Owner }
	
	--cldebugoverlay.Line( self.Owner, tracedata.start, tracedata.endpos, 5, Color( 0, 0, 255 ), true )
	
	local trace = util.TraceLine( tracedata )
	if not trace.StartSolid and trace.HitWorld and not trace.HitNoDraw and not trace.HitSky then
		--cldebugoverlay.Sphere( self.Owner, trace.HitPos, 5, 10, Color( 255, 255, 255 ), true )
		return NULL
	else
		return nil
	end
end

--*******************************************
--					Think 
--*******************************************

function ENT:CalculateStability( top, bottom, west, east, north, south )
	local side = {west, east, north, south}
	
	local blockType = MC.BlockTypes[self:GetBlockID()]
	
	local stability = -1.0
	
	-- Check if the given direction is connected to the world
	if bottom == NULL and blockType.bondToWorld[2] > 0 then
		stability = math.max( stability, blockType.bondToWorld[2] )
	end
	if blockType.bondToWorld[3] > 0 then
		for k, v in pairs( side ) do
			if v == NULL then
				stability = math.max( stability, blockType.bondToWorld[3] )
			end
		end
	end
	if top == NULL and blockType.bondToWorld[1] > 0 then
		stability = math.max( stability, blockType.bondToWorld[1] )
	end
	
	-- Check if the bottom is connected to another block
	if IsValid( bottom ) and bottom.stable then
		stability = math.max( stability, bottom:GetStability() - blockType.bondReduction[2] )
	end
	-- Check if the side is connected to another block
	for k, v in pairs( side ) do
		if IsValid( v ) and v.stable then
			stability = math.max( stability, v:GetStability() - blockType.bondReduction[3] )
		end
	end
	-- Check if the top is connected to another block
	if IsValid( top ) and top.stable then
		stability = math.max( stability, top:GetStability() - blockType.bondReduction[1] )
	end
	
	return stability
end

function ENT:Think( )
	if (CLIENT) then return end
	
	-- #### Stability stuff ####
	if self:GetUpdateStability() and self.stable then
		self:SetUpdateStability( false )
		
		local top		= self:GetNearbyBlock( MC.cubeFace.top )
		local bottom	= self:GetNearbyBlock( MC.cubeFace.bottom )
		local north		= self:GetNearbyBlock( MC.cubeFace.north )
		local south		= self:GetNearbyBlock( MC.cubeFace.south )
		local east		= self:GetNearbyBlock( MC.cubeFace.east )
		local west		= self:GetNearbyBlock( MC.cubeFace.west )
		
		local oldStability = self:GetStability()
		local stability = self:CalculateStability( top, bottom, north, south, east, west )
		
		-- If stability changed, update neighbours
		if oldStability ~= stability then
			self:SetStability( stability )
			
			--cldebugoverlay.EntityTextAtPosition( self.Owner, self:GetPos(), 0, "Stability: "..stability, 1 )
			
			if IsValid( top )		then top:SetUpdateStability( true ) end
			if IsValid( bottom )	then bottom:SetUpdateStability( true ) end
			if IsValid( north )		then north:SetUpdateStability( true ) end
			if IsValid( south )		then south:SetUpdateStability( true ) end
			if IsValid( east )		then east:SetUpdateStability( true ) end
			if IsValid( west )		then west:SetUpdateStability( true ) end
			
			-- Unfreeze entity if unstable
			if stability <= 0.0 then
				self.stable = false
				self:SetModelScale( 0.99 )
				self:Activate()
				local phys = self:GetPhysicsObject()
				phys:EnableMotion( true )
				phys:Wake()
			end
		end
		
	end
	
	-- #### DoUpdate stuff ####
	if self:GetDoUpdate() then
		self:SetDoUpdate( false )
		local ID = self:GetBlockID()
	end
end

--***********************************************
--	BlockInit - special block behaviour on spawn
--***********************************************

function ENT:BlockInit( ID , hitEntity )
	if (CLIENT) then
	if (GetConVar("minecraft_debug"):GetBool()) then print("block spawned with ID = " .. tostring(ID)) end
	if (GetConVar("minecraft_debug"):GetBool()) then print("tracer hit " .. tostring(hitEntity:GetClass())) end
	end
	
	self.stable = true
	self:SetUpdateStability( true )
	
	--are we spawning on another block?
	local onBlock = false
	if (!hitEntity:IsWorld() and hitEntity:GetClass() == "minecraft_block") then
		onBlock = true
		
		if (CLIENT) then
			if (GetConVar("minecraft_debug"):GetBool() == 2) then print("onBlock = true!") end
		end
	end

	--get the view direction (1 = North, 2 = East, 3 = South, 4 = West)
	--I hereby declare that North is the direction you are facing in gm_construct on spawn
	local viewdir = -1
	local tr = self.Owner:GetEyeTrace()
	local hitpos = tr.HitPos - self.Owner:GetPos()
	if (CLIENT) then
		if (GetConVar("minecraft_debug"):GetBool() == 2) then print("hitpos.x = ".. tostring(hitpos.x) .. " hitpos.y = ".. tostring(hitpos.y)) end
	end
	local startpos = tr.StartPos - self.Owner:GetPos()
	local rotpoint = RotatePoint2D( hitpos, startpos, 45 ) --rotate the "compass rose" by 45 degrees
	local thevector = rotpoint - startpos
	if (CLIENT) then
		if (GetConVar("minecraft_debug"):GetBool() == 2) then print("posx = " .. tostring(thevector.x)) end
		if (GetConVar("minecraft_debug"):GetBool() == 2) then print("posy = " .. tostring(thevector.y)) end
	end
	if (thevector.x < 0 and thevector.y > 0) then
		if (CLIENT) then
			if (GetConVar("minecraft_debug"):GetBool()) then print("player -> North") end
		end
		viewdir = 1
	end
	if (thevector.x > 0 and thevector.y > 0) then
		if (CLIENT) then
			if (GetConVar("minecraft_debug"):GetBool()) then print("player -> East") end
		end
		viewdir = 2
	end
	if (thevector.x > 0 and thevector.y < 0) then
		if (CLIENT) then
			if (GetConVar("minecraft_debug"):GetBool()) then print("player -> South") end
		end
		viewdir = 3
	end
	if (thevector.x < 0 and thevector.y < 0) then
		if (CLIENT) then
			if (GetConVar("minecraft_debug"):GetBool()) then print("player -> West") end
		end
		viewdir = 4
	end
	
	--on which of the possible 6 sides of an already existing block are we spawning?
	--1 = top, 2 = bottom, 3 = front, 4 = back, 5 = left, 6 = right [when looking at a block in front of you and looking to the north!]
	local onSide = -1
	if (onBlock == true) then
		if (CLIENT) then
			if (GetConVar("minecraft_debug"):GetBool() == 2) then print("self:GetPos() -> x = " .. tostring(self:GetPos().x) .. " ; y = " .. tostring(self:GetPos().y) .. " ; z = " .. tostring(self:GetPos().z)) end
			if (GetConVar("minecraft_debug"):GetBool() == 2) then print("hitE:GetPos() -> x = " .. tostring(hitEntity:GetPos().x) .. " ; y = " .. tostring(hitEntity:GetPos().y) .. " ; z = " .. tostring(hitEntity:GetPos().z)) end
		end
		local selfX = self:GetPos().x;
		local selfY = self:GetPos().y;
		local selfZ = self:GetPos().z;
		local hitX = hitEntity:GetPos().x;
		local hitY = hitEntity:GetPos().y;
		local hitZ = hitEntity:GetPos().z;
		if (selfX == hitX and selfY == hitY and selfZ > hitZ) then
			onSide = 1;
			if (CLIENT) then
				if (GetConVar("minecraft_debug"):GetBool()) then print("top") end
			end
		end
		if (selfX == hitX and selfY == hitY and selfZ < hitZ) then
			onSide = 2;
			if (CLIENT) then
				if (GetConVar("minecraft_debug"):GetBool()) then print("bottom") end
			end
		end
		if (selfX > hitX and selfY == hitY) then
			onSide = 3
			if (CLIENT) then
				if (GetConVar("minecraft_debug"):GetBool()) then print("front") end
			end
		end
		if (selfX < hitX and selfY == hitY) then
			onSide = 4
			if (CLIENT) then
				if (GetConVar("minecraft_debug"):GetBool()) then print("back") end
			end
		end
		if (selfX == hitX and selfY < hitY) then
			onSide = 5
			if (CLIENT) then
				if (GetConVar("minecraft_debug"):GetBool()) then print("left") end
			end
		end
		if (selfX == hitX and selfY > hitY) then
			onSide = 6
			if (CLIENT) then
				if (GetConVar("minecraft_debug"):GetBool()) then print("right") end
			end
		end
	end
	
	
	--***************************************--
	--		Global Per-Block Variables  	 --
	--***************************************--
	
	self.isPowered = false;
	self.isPowerSource = false;
	
	--fix wall sign spawn height
	if ( ID == 65 ) then
		local pos = self:GetPos()
		pos.z = pos.z + (18.25/2)
		self:SetPos( pos )
	end
	
	--fix ender crystal spawn height
	if ( ID == 198 ) then
		local pos = self:GetPos()
		pos.z = pos.z + (75.00/2)
		self:SetPos( pos )
	end
	
	--fix frame spawn height
	if ( ID == 188 ) then
		local pos = self:GetPos()
		pos.z = pos.z + (12.25/2)
		self:SetPos( pos )
	end
	
	--auto rotate furnaces, dispensers, stairs, chests, pumpkins, beds, rails, portals, iron bars, glas panes to face the player on spawn
	if MC.BlockTypes[ID].autoRotate then
		self:SetAngles( Angle( 0, -90*(viewdir-1), 0 ) )
	end
	
	--auto rotate side-hopper
	if ( ID == 178 ) then
		if (viewdir == 1 or viewdir == 3) then
			self:SetAngles( Angle( 0, 90*(viewdir+1), 0 ) )
		else
			self:SetAngles( Angle( 0, 90*(viewdir-1), 0 ) )
		end
	end
	
	--auto rotate fences
	if ( ID == 99 or ID == 100 or ID == 101 or ID == 102 or ID == 103 or ID == 195) then
		self:SetAngles( Angle( 0, -90*(viewdir), 0 ) )
	end
	
	--auto rotate fence gates
	if (ID == 104 or ID == 105) then
		self:SetAngles(  Angle( 0, -90*(viewdir-1), 0 ) )
	end
	
	--auto rotate wall signs and buttons, stick, and ALL items to other blocks
	if ( ID == 65 or ID == 98 or ID == 109 or (ID >= 110 and ID <= 116) or (ID >= 135 and ID <= 171) or ID == 188 or ID == 193 or ID == 194) then
		if ( (ID == 98 or ID == 109 or (ID >= 110 and ID <= 116) or (ID >= 135 and ID <= 171) or ID == 188 or ID == 193 or ID == 194) and onBlock ) then
			self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER );
			local moveValueZ = 16
			local moveValueX = 0
			local moveValueY = 0
			if (ID == 109) then --tripwires
				moveValueZ = 18.5
			end
			if (ID == 110 or ID == 193) then --paintings
				moveValueZ = 16.5
			end
			if (ID == 188) then --paintings
				moveValueZ = 16.5
			end
			if (ID >= 111) then --paintings
				moveValueZ = 17.5
			end
			if (ID == 111) then
				moveValueX = -14
			end
			if (ID == 113) then
				moveValueX = -14
				moveValueY = 2
			end
			if (ID == 114) then
				moveValueX = -18
				moveValueY = 1
			end
			if (ID == 115) then
				moveValueX = -18.5
				moveValueY = 0
				moveValueZ = 17
			end
			if (ID == 116) then
				moveValueX = -18
				moveValueY = 4
			end
			if (onSide == 3) then
				--print("onSide = 3!")
				self:SetPos( self:GetPos() + Vector(-moveValueZ, moveValueX, moveValueY) )
			end
			if (onSide == 4) then
				--print("onSide = 4!")
				self:SetPos( self:GetPos() + Vector( moveValueZ, moveValueX, moveValueY) )
			end
			if (onSide == 5) then
				--print("onSide = 5!")
				self:SetPos( self:GetPos() + Vector( moveValueX, moveValueZ, moveValueY) )
			end
			if (onSide == 6) then
				--print("onSide = 6!")
				self:SetPos( self:GetPos() + Vector( moveValueX, -moveValueZ, moveValueY) ) 
			end
		end
		if (ID >= 135 and ID <= 171) then --special case: item height
			self:SetPos( self:GetPos() + Vector(0,0,18) )
		end
		if (ID == 193) then --special case: item height
			self:SetPos( self:GetPos() + Vector(0,0,18) )
		end
		if (ID == 194) then --special case: item height
			self:SetPos( self:GetPos() + Vector(0,0,18) )
		end
		if (onBlock) then
			if (onSide == 4) then
				self:SetAngles( Angle( 0, -90*2, 0 ) )
			end
			if (onSide == 5) then
				self:SetAngles( Angle( 0, -90, 0 ) )
			end
			if (onSide == 6) then
				self:SetAngles( Angle( 0, -90*3, 0 ) )
			end
		else
			self:SetAngles( Angle( 0, -90*(viewdir-1), 0 ) )
		end
	end
	
	--auto rotate dooors, set correct position
	if (ID == 62 or ID == 63) then
		if (viewdir == 2 or viewdir == 4) then
			self:SetAngles( Angle(0 , 90 , 0) )
		end
		local pos = self:GetPos();
		--local min,max = self:WorldSpaceAABB();       doesn't work because
		--local halfwidth = math.abs(min.x - max.x)/2; the bounding box sadly is a tiny teeny bit bigger than the actual model
		--HACKHACK: I hate having to use fixed values determined by testing with convars
		local halfwidth = 3.4
		if (viewdir == 1) then
			pos.x = pos.x + 18.25 - halfwidth;
		end
		if (viewdir == 2) then
			pos.y = pos.y - 18.25 + halfwidth;
		end
		if (viewdir == 3) then
			pos.x = pos.x - 18.25 + halfwidth;
		end
		if (viewdir == 4) then
			pos.y = pos.y + 18.25 - halfwidth;
		end
		self:SetPos( pos )
	end
	
	--auto rotate signs to always face the player (like in minecraft)
	if (ID == 64) then
		local base = Vector( -1, 0, 0 ) --North vector
		local thevector = self:GetPos() - self.Owner:GetPos()
		local angle = GetAngleBetweenVectors( base, thevector )
		if (CLIENT) then
			if (GetConVar("minecraft_debug"):GetBool()) then print("angle = " .. tostring(angle)) end
		end
		self:SetAngles( Angle( 0, angle, 0) )
	end
	
	--rotate all 2.5d sprites 45 degrees (saplings, shrubs, sugar cane, mushrooms, flowers, grass, plants, cobweb), disable player collisions
	if (ID == 70 or ID == 190 or ID == 191 or ID == 109 or ID == 173 or ID == 172) then
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER );
		self:SetAngles( Angle( 0,45,0 ) )
	end
	
	--auto rotate ladders, stick to other blocks
	if (ID == 72) then
		if (onBlock) then
			if (onSide == 4) then
				self:SetAngles( Angle( 0,-90*2,0) )
			end
			if (onSide == 5) then
				self:SetAngles( Angle( 0,-90,0) )
			end
			if (onSide == 6) then
				self:SetAngles( Angle( 0,-90*3,0) )
			end
		else
			self:SetAngles( Angle( 0,-90*(viewdir-1),0) )
		end
	end
	
	--auto rotate redstone repeaters
	if (ID == 57 or ID == 58 or (ID >= 118 and ID <= 120) or (ID >= 124 and ID <= 130)) then
		if (viewdir == 2 or viewdir == 4) then
			self:SetAngles( Angle( 0, 90*(viewdir-1), 0) )
		else
			self:SetAngles( Angle( 0, 90*(viewdir+1), 0) )
		end
	end
	
	--auto rotate new quartz redstone blocks
	if (ID == 174 or ID == 175 or ID == 176) then
			if (viewdir == 2 or viewdir == 4) then
			self:SetAngles( Angle( 0, 90*(viewdir-3), 0) )
		else
			self:SetAngles( Angle( 0, 90*(viewdir+3), 0) )
		end	
	end
	
	--intelligently place torches, auto rotation and positioning ; also set special collision group
	if (ID == 66 or ID == 67) then
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER );
		local torchAngle = 20;
		if (onSide == 3) then --front
			local pos = self:GetPos();
			pos.x = pos.x - 18.25;
			pos.z = pos.z + (18.25/2);
			self:SetPos( pos );
			self:SetAngles( Angle( torchAngle, 0, 0) )
		end
		if (onSide == 4) then --back
			local pos = self:GetPos();
			pos.x = pos.x + 18.25;
			pos.z = pos.z + (18.25/2);
			self:SetPos( pos );
			self:SetAngles( Angle( -torchAngle, 0, 0) )
		end
		if (onSide == 5) then --left
			local pos = self:GetPos();
			pos.y = pos.y + 18.25;
			pos.z = pos.z + (18.25/2);
			self:SetPos( pos );
			self:SetAngles( Angle( -torchAngle, 90, 0) )
		end
		if (onSide == 6) then --right
			local pos = self:GetPos();
			pos.y = pos.y - 18.25;
			pos.z = pos.z + (18.25/2);
			self:SetPos( pos );
			self:SetAngles( Angle( torchAngle, 90, 0) )
		end
	end
	
	--and the same with levers
	if (ID == 68) then
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER );
		local leverAngle = 90;
		if (onSide == 3) then --front
			local pos = self:GetPos();
			pos.x = pos.x - 18.25;
			pos.z = pos.z + 18.25;
			self:SetPos( pos );
			self:SetAngles( Angle( leverAngle, 0, 0) )
		end
		if (onSide == 4) then --back
			local pos = self:GetPos();
			pos.x = pos.x + 18.25;
			pos.z = pos.z + 18.25;
			self:SetPos( pos );
			self:SetAngles( Angle( -leverAngle, 0, 0) )
		end
		if (onSide == 5) then --left
			local pos = self:GetPos();
			pos.y = pos.y + 18.25;
			pos.z = pos.z + 18.25;
			self:SetPos( pos );
			self:SetAngles( Angle( -leverAngle, 90, 0) )
		end
		if (onSide == 6) then --right
			local pos = self:GetPos();
			pos.y = pos.y - 18.25;
			pos.z = pos.z + 18.25;
			self:SetPos( pos );
			self:SetAngles( Angle( leverAngle, 90, 0) )
		end
	end	
	
	--tnt blocks
	if (ID == 39) then
		if (self:CheckPos(ID)) then
		local thetnt = ents.Create( "mc_tnt" )
		thetnt:SetPos( self:GetPos() )
		thetnt:SetKeyValue( "DisableShadows", "1" )
		thetnt:SetKeyValue( "targetname", "mcblock" )
		thetnt:SetPlayer( self:GetPlayer() ) 
		thetnt:Spawn()
		local phys = thetnt:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:EnableMotion( false ) --freeze the block
			phys:Wake()
		end
		self:Remove()
		end
	end
	
	--cake 
	if (ID == 48) then
		if (self:CheckPos(ID)) then
		local ent = ents.Create( "mc_cake" )
		ent:SetPos( self:GetPos() )
		ent:SetKeyValue( "DisableShadows", "1" )
		ent:SetKeyValue( "targetname", "mcblock" )
		ent:SetPlayer( self.Owner )
		ent:Spawn()
		local phys = ent:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:EnableMotion( false )
			phys:Wake()
		end
		self:Remove()
		end
	end
	
	--auto rotation of glass panes, iron bars, portals, fence-2 if they are spawning touching already existing ones
	if (ID == 59 or ID == 60 or ID == 61 or ID == 100) then
		if (onBlock) then
			if (hitEntity:GetBlockID() == ID) then
				self:SetAngles( hitEntity:GetAngles() );
			end
		else
			local t1 = self:GetNearbyBlock( MC.cubeFace.top )
			local t2 = self:GetNearbyBlock( MC.cubeFace.bottom )
			local t3 = self:GetNearbyBlock( MC.cubeFace.north )
			local t4 = self:GetNearbyBlock( MC.cubeFace.south )
			local t5 = self:GetNearbyBlock( MC.cubeFace.east )
			local t6 = self:GetNearbyBlock( MC.cubeFace.west )
			if IsValid( t1 ) then
				if (t1:GetBlockID() == ID) then
					self:SetAngles( t1:GetAngles() )
				end
			end
			if IsValid( t2 ) then
				if t2:GetBlockID() == ID then
					self:SetAngles( t2:GetAngles() )
				end
			end
			if IsValid( t3 ) then
				if t3:GetBlockID() == ID then
					self:SetAngles( t3:GetAngles() )
				end
			end
			if IsValid( t4 ) then
				if t4:GetBlockID() == ID then
					self:SetAngles( t4:GetAngles() )
				end
			end
			if IsValid( t5 ) then
				if t5:GetBlockID() == ID then
					self:SetAngles( t5:GetAngles() )
				end
			end
			if IsValid( t6 ) then
				if t6:GetBlockID() == ID then
					self:SetAngles( t6:GetAngles() )
				end
			end
		end
	end
	
	--intelligently rotate vines
	if (ID == 82) then
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER );
		local pos = self:GetPos();
		if (onBlock) then
			if (onSide == 3) then
				pos.x = pos.x - 18;
			end
			if (onSide == 4) then
				self:SetAngles( Angle( 0,-90*2,0) )
				pos.x = pos.x + 18;
			end
			if (onSide == 5) then
				self:SetAngles( Angle( 0,-90,0) )
				pos.y = pos.y + 18;
			end
			if (onSide == 6) then
				self:SetAngles( Angle( 0,90,0) )
				pos.y = pos.y - 18;
			end
			self:SetPos( pos );
		else
			self:SetAngles( Angle( 0,-90*(viewdir-1),0) )
			if (viewdir == 1) then
				pos.x = pos.x - 18;
			end
			if (viewdir == 2) then
				pos.y = pos.y + 18;
			end
			if (viewdir == 3) then
				pos.x = pos.x + 18;
			end
			if (viewdir == 4) then
				pos.y = pos.y - 18;
			end
			self:SetPos( pos );
		end
	end
	
	--flip stairs
	if (ID == 45 or ID == 46 or ID == 47 or ID == 181) and ((GetCSConVarB( "minecraft_flipstairs", self.Owner )) or onSide == 2) then
		self:SetAngles( self:GetAngles() + Angle(0,0,180) )
		self:SetPos( self:GetPos() + Vector(0,0,36.5) );
	end
	
	--flip logs, if flipped also auto rotate
	if ( (ID == 31 or ID == 200) and GetCSConVarB( "minecraft_fliplogs", self.Owner ) ) then
		self:SetAngles( self:GetAngles() + Angle(0,0,90) + Angle( 0,-90*(viewdir),0))
		if (viewdir == 1) then
			self:SetPos( self:GetPos() + Vector(18.25,0,18.25) )
		end
		if (viewdir == 2) then
			self:SetPos( self:GetPos() + Vector(0,-18.25,18.25) )
		end
		if (viewdir == 3) then
			self:SetPos( self:GetPos() + Vector(-18.25,0,18.25) )
		end
		if (viewdir == 4) then
			self:SetPos( self:GetPos() + Vector(0,18.25,18.25) )
		end
	end
	
	--place the cauldron just a teeny bit higher so we don't get z-fighting on the ground vertices
	if ( ID == 88 ) then
		self:SetPos( self:GetPos() + Vector(0,0,0.1) )
	end
	
	--auto rotate cocoa beans
	if ( ID >= 89 and ID <= 91 ) then
		self:SetAngles( Angle( 0,-90*(viewdir-1),0) )
		local addHeight = 4;
		if (ID == 91) then
			addHeight = 4
		end
		if (ID == 89) then
			addHeight = 8
		end
		if (ID == 90) then
			addHeight = 6
		end
		self:SetPos( self:GetPos() + Vector(0,0,addHeight) )
	end
	
	--fix spawn height of crops, carrots, tree saplings etc.
	if ( ID == 70 or ID == 71 or ID == 123 or ID == 172 or ID == 173 or ID == 190 or ID == 191 ) then
		self:SetPos( self:GetPos() + Vector(0,0,2.21) )
	end
	
	--stack slabs
	if ( (ID >= 49 and ID <= 54) or ID == 107 or ID == 180 ) then
		self.isSlabStacked = false
		if (onSide == 1) then
			local t1 = self:GetNearbyBlock(2);
			if (t1 ~= nil) then
				if (t1.isSlabStacked ~= nil) then
					if (t1.isSlabStacked == false) then
						self:SetPos( self:GetPos() + Vector(0,0,-18.255) )
						self.isSlabStacked = true
					end
				end
			end
		end
	end
	
	--normal sign 
	if (ID == 64) then
		if (self:CheckPos(ID)) then
		local ent = ents.Create( "minecraft_sign" )
		ent:SetPos( self:GetPos() )
		
			--orient facing the player
			--HACKHACK: code duplication!
			local base = Vector( -1, 0, 0 ) --North vector
			local thevector = self:GetPos() - self.Owner:GetPos()
			local angle = GetAngleBetweenVectors( base, thevector )
			ent:SetAngles( Angle( 0, angle, 0) )
			
		ent:SetKeyValue( "DisableShadows", "1" )
		ent:SetKeyValue( "targetname", "mcblock" )
		ent:Spawn()
		local phys = ent:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:EnableMotion( false )
			phys:Wake()
		end
		self:Remove()
		end
	end
	
	--wall sign 
	if (ID == 65) then
		if (self:CheckPos(ID)) then
		local ent = ents.Create( "minecraft_wall_sign" )
		ent:SetPos( self:GetPos() )
		ent:SetAngles( self:GetAngles() )
		ent:SetKeyValue( "DisableShadows", "1" )
		ent:SetKeyValue( "targetname", "mcblock" )
		ent:Spawn()
		local phys = ent:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:EnableMotion( false )
			phys:Wake()
		end
		self:Remove()
		end
	end
	
	--****************************--
	--		Special blocks 		  --
	--****************************--
	
	--create member variables used by doors and trapdoors, also rotate doors to always face the player
	if ( ID == 55 or ID == 62 or ID == 63 ) then
		self:SetAngles( Angle( 0,-90*(viewdir-1),0) )
		self.isDoorOpen = false
		self.doorAngle = Angle(0,0,0)
	end
end

--*****************************************************************
--	PhysicsCollide + Use
--*****************************************************************

function ENT:PhysicsCollide( data, physobj )
	local hitEntity = data.HitEntity
	
	if hitEntity:IsWorld() or hitEntity:GetClass() == "minecraft_block" or hitEntity:GetClass() == "minecraft_block_waterized" then return end
	
	blockType = MC.BlockTypes[self:GetBlockID()]
	if !blockType then return end
	
	--when running into cactus blocks, deal damage!
	if blockType.contactDamage > 0 then
		data.HitEntity:TakeDamage( blockType.contactDamage, data.HitEntity, self )
	end
	
	if blockType.ignitePlayer then
		data.HitEntity:Ignite( 5, 0 )
	end
	
	--TODO: add moar
end

function ENT:StartTouch( ent )
	if (self:GetBlockID() == 69) then
		ent:Ignite(5,0);
	end
end

function ENT:Use( activator, caller )
	local BlockID = self:GetBlockID()
	if BlockID ~= 55 and BlockID ~= 62 and BlockID ~= 63 and BlockID ~= 98 then return end -- TODO: Don't use hard coded numbers anywhere!
	
	if not IsValid( caller ) or not caller:IsPlayer() then return end
	
	-- Check if the player is allowed to use this object
	if caller:Team() == MC.refuseUseToTeam then
		caller:PrintMessage( HUD_PRINTCENTER, MC.strings.refuseUseToTeam )
		return
	end
	
	if ( activator:IsPlayer() ) then
		
		--open/close doors
		if ( BlockID == 62 or BlockID == 63 ) then
			self:updateDoors( !self.isDoorOpen )
		end
		
		--open/close trapdoors
		if ( BlockID == 55 ) then
			local curAngle = self:GetAngles()
			if ( !self.isDoorOpen ) then
				self:EmitSound( Sound("minecraft/door_open.wav") )
				self.doorAngle = self:GetAngles()
				self:SetAngles( curAngle + Angle(90,0,0) )
				self:SetPos( self:GetPos() + curAngle:Forward() * Vector(-18.25,-18.25,-18.25) + curAngle:Up() * Vector(18.25,18.25,18.25) )
				self.isDoorOpen = true
				if ( GetCSConVarB( "minecraft_doors_disablecollision", self:GetPlayer() ) == true ) then
					self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER );
				end
			else
				self:EmitSound( Sound("minecraft/door_close.wav") )
				self:SetAngles( self.doorAngle )
				self:SetPos( self:GetPos() + self.doorAngle:Forward() * Vector(18.25,18.25,18.25)  + self.doorAngle:Up() * Vector(-18.25,-18.25,-18.25) )	
				self.isDoorOpen = false
				if ( GetCSConVarB( "minecraft_doors_disablecollision", self:GetPlayer() ) == true ) then
					self:SetCollisionGroup( 0 )
				end
			end
		end
		
		--buttons
		if ( BlockID == 98 ) then
			if (!self.isPowered) then
				self.isPowered = true
				self:EmitSound( Sound("minecraft/click.wav") )
				updateBlocksAround( self )
				timer.Simple( 1, function() if (IsValid(self)) then
											self.isPowered = false 
											self:EmitSound( Sound("minecraft/click.wav") ); 
											updateBlocksAround( self )
											end
								 end )
			end
		end
	end
end

function ENT:updateDoors( open )
	local curAngle = self:GetAngles()
	if ( open == true ) then
		self:EmitSound( Sound("minecraft/door_open.wav") )
		self.doorAngle = self:GetAngles()
		self:SetAngles( curAngle + Angle(0,90,0) )
		self:SetPos( self:GetPos() + curAngle:Right() * Vector(14.83, 14.83, 14.83) + curAngle:Forward() * Vector(-14.83,-14.83,-14.83) )
		self.isDoorOpen = true
		if ( GetCSConVarB( "minecraft_doors_disablecollision", self:GetPlayer() ) == true ) then
			self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER );
		end
	else
		self:EmitSound( Sound("minecraft/door_close.wav") )
		self:SetAngles( self.doorAngle )
		self:SetPos( self:GetPos() + self.doorAngle:Right() * Vector(-14.83, -14.83, -14.83) + self.doorAngle:Forward() * Vector(14.83,14.83,14.83) )	
		self.isDoorOpen = false
		if ( GetCSConVarB( "minecraft_doors_disablecollision", self:GetPlayer() ) == true ) then
			self:SetCollisionGroup( 0 )
		end
	end
end

--***************************************
--	Random helper functions
--***************************************

function updateBlocksAround( block )
		local t1 = block:GetNearbyBlock( MC.cubeFace.top )
		local t2 = block:GetNearbyBlock( MC.cubeFace.bottom )
		local t3 = block:GetNearbyBlock( MC.cubeFace.north )
		local t4 = block:GetNearbyBlock( MC.cubeFace.south )
		local t5 = block:GetNearbyBlock( MC.cubeFace.east )
		local t6 = block:GetNearbyBlock( MC.cubeFace.west )
		if (IsValid(t1)) then
			t1:SetDoUpdate( true )
		end
		if (IsValid(t2)) then
			t2:SetDoUpdate( true )
		end
		if (IsValid(t3)) then
			t3:SetDoUpdate( true )
		end
		if (IsValid(t4)) then
			t4:SetDoUpdate( true )
		end
		if (IsValid(t5)) then
			t5:SetDoUpdate( true )
		end
		if (IsValid(t6)) then
			t6:SetDoUpdate( true )
		end	
end

function isPowerBlockAround( block )
	local t1 = block:GetNearbyBlock( MC.cubeFace.top )
	if (IsValid(t1)) then
		if (t1.isPowerSource) then return true end
	end
	
	local t2 = block:GetNearbyBlock( MC.cubeFace.bottom )
	if (IsValid(t2)) then
		if (t2.isPowerSource) then return true end
	end
	
	local t3 = block:GetNearbyBlock( MC.cubeFace.north )
	if (IsValid(t3)) then
		if (t3.isPowerSource) then return true end
	end
	
	local t4 = block:GetNearbyBlock( MC.cubeFace.south )
	if (IsValid(t4)) then
		if (t4.isPowerSource) then return true end
	end
	
	local t5 = block:GetNearbyBlock( MC.cubeFace.east )
	if (IsValid(t5)) then
		if (t5.isPowerSource) then return true end
	end
	
	local t6 = block:GetNearbyBlock( MC.cubeFace.west )
	if (IsValid(t6)) then
		if (t6.isPowerSource) then return true end
	end	
	return false
end

function isPoweredBlockAround( block )
	local t1 = block:GetNearbyBlock( MC.cubeFace.top )
	if (IsValid(t1)) then
		if (t1.isPowered) then return true end
	end
	
	local t2 = block:GetNearbyBlock( MC.cubeFace.bottom )
	if (IsValid(t2)) then
		if (t2.isPowered) then return true end
	end
	
	local t3 = block:GetNearbyBlock( MC.cubeFace.north )
	if (IsValid(t3)) then
		if (t3.isPowered) then return true end
	end
	
	local t4 = block:GetNearbyBlock( MC.cubeFace.south )
	if (IsValid(t4)) then
		if (t4.isPowered) then return true end
	end
	
	local t5 = block:GetNearbyBlock( MC.cubeFace.east )
	if (IsValid(t5)) then
		if (t5.isPowered) then return true end
	end
	
	local t6 = block:GetNearbyBlock( MC.cubeFace.west )
	if (IsValid(t6)) then
		if (t6.isPowered) then return true end
	end	
	return false
end

function RotatePoint2D( toRotate, Anchor, Angle )
	local radians = -Angle*(math.pi/180); --convert degrees to radians
	local xdiff = toRotate.x-Anchor.x;
	local ydiff = toRotate.y-Anchor.y;                                                                        
	return Vector(math.cos(radians)*xdiff-math.sin(radians)*ydiff+Anchor.x,math.sin(radians)*xdiff+math.cos(radians)*ydiff+Anchor.y,0);
end

function GetAngleBetweenVectors( vector1, vector2 )
	vector1.z = 0;
	vector2.z = 0;
	local temp1 = vector1:Dot( vector2 );
	local temp2 = vector1:Length() * vector2:Length();
	local radians = math.acos(temp1 / temp2);
	local final = -radians/(math.pi/180);
	local angle = math.abs(math.atan2(vector2.y,vector2.x) - math.atan2(vector1.y,vector1.x));
	if (angle > math.pi) then
		final = -final;
	end
	return final;
end