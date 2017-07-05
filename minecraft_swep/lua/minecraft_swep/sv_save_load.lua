function MC.SaveState( name )
	local mapname = game.GetMap()
	local filename = string.lower("minecraftswep/" .. mapname .. "/" .. name .. ".dat")
	file.CreateDir( "minecraftswep/" )
	file.CreateDir( "minecraftswep/" .. string.lower(mapname) .. "/" )
	
	local list = {}
	
	for k, v in pairs( ents.FindByName( "mcblock" ) ) do
		if IsValid( v ) then
			list[k] = { pos = v:GetPos(), angles = v:GetAngles(), rot = v:GetRotation(), blocktype = v:GetBlockID(), skin = v:GetSkin(), stability = v:GetStability(), stable = v.stable }
		end
	end
	
	file.Write( filename, util.TableToJSON(list) )
	
	return true
end

function MC.LoadState( name )
	local mapname = game.GetMap()
	local filename = string.lower("minecraftswep/" .. mapname .. "/" .. name .. ".dat")
	
	if not file.Exists( filename, "DATA" ) then
		return "Can't load " .. filename .. ". File doesn't exist"
	end
	
	-- Delete all (mc)blocks
	for k, v in pairs( ents.FindByName( "mcblock" ) ) do
		if IsValid( v ) then
			v.Entity.health = -1
			v:Remove()
		end
	end
	
	local list = util.JSONToTable( file.Read( filename ) )
	
	for k, v in pairs( list ) do
		ent = SpawnMinecraftBlock( nil, nil, v.blocktype, v.pos, v.rot )
		
		if IsValid( ent ) then
			ent:SetSkin( v.skin )
			ent:SetAngles( v.angles )
			ent:SetStability( v.stability )
			
			if not v.stable then
				ent.stable = false
				ent:SetModelScale( 0.99 )
				ent:Activate()
				local phys = ent:GetPhysicsObject()
				phys:EnableMotion( true )
				phys:Wake()
			end
		end
	end
	
	return true
end

function MC.DeleteState( name )
	local mapname = game.GetMap()
	local filename = string.lower("minecraftswep/" .. mapname .. "/" .. name .. ".dat")
	
	if not file.Exists( filename, "DATA" ) then
		return "Can't delete " .. filename .. ". File doesn't exist"
	end
	
	file.Delete( filename ) 
	
	return true
end

-- Automatic mapload if there is a default state for the given map
local function MapStartTrigger()
	local name = "default"
	local mapname = game.GetMap()
	local filename = string.lower("minecraftswep/" .. mapname .. "/" .. name .. ".dat")
	
	if file.Exists( filename, "DATA" ) then
		MC.LoadState( name )
	end
end
hook.Add( "InitPostEntity", "MinecraftSWEP_InitPostEntity", MapStartTrigger )