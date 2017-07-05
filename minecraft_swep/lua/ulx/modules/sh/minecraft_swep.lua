local CATEGORY_NAME = "Minecraft SWEP"

function ulx.MC_SaveLoad( calling_ply, name, shouldLoad )
	local result
	
	if shouldLoad == true then
		result = MC.LoadState( name )
		if result ~= true then
			ULib.tsayError( calling_ply, result, true )
		else
			ulx.fancyLogAdmin( calling_ply, false, "#A loaded minecraft state as #s", name )
		end
	else
		result = MC.SaveState( name )
		if result ~= true then
			ULib.tsayError( calling_ply, result, true )
		else
			ulx.fancyLogAdmin( calling_ply, false, "#A saved minecraft state as #s", name )
		end
	end
	
	return result
end
local MC_Save = ulx.command( CATEGORY_NAME, "ulx mcsave", ulx.MC_SaveLoad, "!mcsave" )
MC_Save:addParam{ type=ULib.cmds.StringArg, hint="" }
MC_Save:addParam{ type=ULib.cmds.BoolArg, invisible=true }
MC_Save:defaultAccess( ULib.ACCESS_ADMIN )
MC_Save:help( "Save or load a minecraft state. Save as 'default' to let the state automatically load at map begin." )
MC_Save:setOpposite ( "ulx mcload", { _, _, true, false }, "!mcload" )

function ulx.MC_Delete( calling_ply, name )
	local result = MC.DeleteState( name )
	if result ~= true then
		ULib.tsayError( calling_ply, result, true )
	else
		ulx.fancyLogAdmin( calling_ply, false, "#A deleted minecraft state #s", name )
	end
	
	return result
end
local MC_Delete = ulx.command( CATEGORY_NAME, "ulx mcdelete", ulx.MC_Delete, "!mcdelete" )
MC_Delete:addParam{ type=ULib.cmds.StringArg, hint="" }
MC_Delete:defaultAccess( ULib.ACCESS_ADMIN )
MC_Delete:help( "Delete a minecraft state from disk." )

local function GetFileName( url )
  return url:match( "^(.*)%.dat$" )
end

function ulx.MC_List( calling_ply )
	local mapname = game.GetMap()
	local path = string.lower("minecraftswep/" .. mapname .. "/")
	local files, directories = file.Find( path .. "*.dat", "DATA" )
	
	ULib.tsay(	calling_ply, "Available maps for " .. mapname .. ":" )
	for k, v in pairs( files ) do
		ULib.tsay(	calling_ply, GetFileName( v ) )
	end
	
	return true
end
local MC_List = ulx.command( CATEGORY_NAME, "ulx mclist", ulx.MC_List, "!mclist" )
MC_List:defaultAccess( ULib.ACCESS_ADMIN )
MC_List:help( "List all available minecraft states for the current map." )

function ulx.MC_OwnAll( calling_ply, ply, unown )
	if unown then
		ply = nil
	end
	
	local result = MC.OwnAll( ply )
	
	if result ~= true then
		ULib.tsayError( calling_ply, result, true )
	else
		if ply then
			ulx.fancyLogAdmin( calling_ply, false, "#A changed the ownership of all minecraft blocks to #T", ply )
		else
			ulx.fancyLogAdmin( calling_ply, false, "#A reset the ownership of all minecraft blocks" )
		end
	end
	
	return result
end
local MC_OwnAll = ulx.command( CATEGORY_NAME, "ulx mcownset", ulx.MC_OwnAll, "!mcownset" )
MC_OwnAll:addParam{ type=ULib.cmds.PlayerArg, ULib.cmds.optional }
MC_OwnAll:addParam{ type=ULib.cmds.BoolArg, invisible=true }
MC_OwnAll:defaultAccess( ULib.ACCESS_ADMIN )
MC_OwnAll:help( "Set or reset ownership of all blocks." )
MC_OwnAll:setOpposite ( "ulx mcownreset", { _, _, true }, "!mcownreset" )