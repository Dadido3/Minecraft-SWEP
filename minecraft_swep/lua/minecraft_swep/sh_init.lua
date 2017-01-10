--[[

Minecraft SWEP addon
created by McKay and 
extended by David Vogel (Dadido3)

]]

MC = MC or {}

AddCSLuaFile( "sh_init.lua" )
AddCSLuaFile( "sh_settings.lua" )
AddCSLuaFile( "sh_waterizer.lua" )

include( "sh_settings.lua" )
include( "sh_waterizer.lua" )

-- #### Helpful stuff ####

MC.cubeSize = 36.5

MC.cubeFace			= { top = 1, bottom = 2, west = 4, east = 8, north = 16, south = 32 }	-- Face of a cube, or direction.
MC.cubeFaceNormal	= { [MC.cubeFace.top] =		Vector(0,0,1),
						[MC.cubeFace.bottom] =	Vector(0,0,-1),
						[MC.cubeFace.west] =	Vector(0,1,0),
						[MC.cubeFace.east] =	Vector(0,-1,0),
						[MC.cubeFace.north] =	Vector(1,0,0),
						[MC.cubeFace.south] =	Vector(-1,0,0),
						}

-- Find the cube face with its normal is closest to the given vector
function MC.GetCubeDirection( vector )
	local absX = math.abs( vector.x )
	local absY = math.abs( vector.y )
	local absZ = math.abs( vector.z )
	local maxValue = math.max( absX, absY, absZ )
	
	if maxValue == absX then
		if vector.x > 0 then return MC.cubeFace.north elseif vector.x < 0 then return MC.cubeFace.south end
	elseif maxValue == absY then
		if vector.y > 0 then return MC.cubeFace.west elseif vector.y < 0 then return MC.cubeFace.east end
	elseif maxValue == absZ then
		if vector.z > 0 then return MC.cubeFace.top elseif vector.z < 0 then return MC.cubeFace.bottom end
	end
	
	return nil
end

-- #### Flat array for storing chunks (Containing stable block entities) ####
-- #### NOT IN USE YET ####
--[[local function newFlatArray(X, Y, Z, Xo, Yo, Zo)
	local MT = {}
	MT.__index = MT
	
	if not(X and Y and Z and Xo and Yo and Zo) then return nil end
	
	local XY = X * Y
	
	function MT:Get(x, y, z)
		x, y, z = x + Xo, y + Yo, z + Zo
		if x > X or y > Y or z > Z or x < 1 or y < 1 or z < 1 then return nil end
		local k = (x) + X * (y - 1) + XY * (z - 1)
		return self[k]
	end
	
	function MT:Add(x, y, z, v)
		x, y, z = x + Xo, y + Yo, z + Zo
		if x > X or y > Y or z > Z or x < 1 or y < 1 or z < 1 then return nil end
		local k = x + X * (y - 1) + XY * (z - 1)
		
		self[k] = self[k] or {}
		return table.insert(self[k], v)
	end
	
	function MT:Remove(x, y, z, v)
		x, y, z = x + Xo, y + Yo, z + Zo
		if x > X or y > Y or z > Z or x < 1 or y < 1 or z < 1 then return nil end
		local k = x + X * (y - 1) + XY * (z - 1)
		
		if self[k] == nil then return nil end
		for i, entry in ipairs(self[k]) do
			if entry == v then
				table.remove(self[k], i)
			end
		end
		
		if not next(self[k]) then
			self[k] = nil
		end
		
		return true
	end
	
	return setmetatable({}, MT)
end

MC.chunkSize = 8
MC.chunkArray = test or newFlatArray(256, 256, 256, 128, 128, 128) -- Around 8x8x8 blocks per chunk
--]]

-- #### Debug stuff ####
cldebugoverlay = {}
function cldebugoverlay.Axis( player, origin, ang, size, lifetime, ignoreZ )
	lifetime = lifetime or 1
	ignoreZ = ignoreZ or false
	player:SendLua( "debugoverlay.Axis( Vector("..origin.x..","..origin.y..","..origin.z.."), Angle("..ang.pitch..","..ang.yaw..","..ang.roll.."), "..size..", "..lifetime..", "..tostring(ignoreZ).." )" )
end
function cldebugoverlay.Box( player, origin, mins, maxs, lifetime, color )
	lifetime = lifetime or 1
	color = color or Color( 255, 255, 255 )
	player:SendLua( "debugoverlay.Box( Vector("..origin.x..","..origin.y..","..origin.z.."), Vector("..mins.x..","..mins.y..","..mins.z.."), Vector("..maxs.x..","..maxs.y..","..maxs.z.."), "..lifetime..", Color( "..color.r..", "..color.g..", "..color.b..", "..color.a.." ) )" )
end
function cldebugoverlay.Cross( player, position, size, lifetime, color, ignoreZ )
	lifetime = lifetime or 1
	color = color or Color( 255, 255, 255 )
	ignoreZ = ignoreZ or false
	player:SendLua( "debugoverlay.Cross( Vector("..position.x..","..position.y..","..position.z.."), "..size..", "..lifetime..", Color( "..color.r..", "..color.g..", "..color.b..", "..color.a.." ), "..tostring(ignoreZ).." )" )
end
function cldebugoverlay.EntityTextAtPosition( player, pos, line, text, lifetime, color )
	lifetime = lifetime or 1
	color = color or Color( 255, 255, 255 )
	player:SendLua( "debugoverlay.EntityTextAtPosition( Vector("..pos.x..","..pos.y..","..pos.z.."), "..line..", \""..text.."\", "..lifetime..", Color( "..color.r..", "..color.g..", "..color.b..", "..color.a.." ) )" )
end
function cldebugoverlay.Line( player, pos1, pos2, lifetime, color, ignoreZ )
	lifetime = lifetime or 1
	color = color or Color( 255, 255, 255 )
	ignoreZ = ignoreZ or false
	player:SendLua( "debugoverlay.Line( Vector("..pos1.x..","..pos1.y..","..pos1.z.."), Vector("..pos2.x..","..pos2.y..","..pos2.z.."), "..lifetime..", Color( "..color.r..", "..color.g..", "..color.b..", "..color.a.." ), "..tostring(ignoreZ).." )" )
end
function cldebugoverlay.Sphere( player, origin, size, lifetime, color, ignoreZ )
	lifetime = lifetime or 1
	color = color or Color( 255, 255, 255 )
	ignoreZ = ignoreZ or false
	player:SendLua( "debugoverlay.Sphere( Vector("..origin.x..","..origin.y..","..origin.z.."), "..size..", "..lifetime..", Color( "..color.r..", "..color.g..", "..color.b..", "..color.a.." ), "..tostring(ignoreZ).." )" )
end