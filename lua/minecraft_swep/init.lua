--[[

Minecraft SWEP addon
created by McKay and 
extended by David Vogel (Dadido3)

]]

AddCSLuaFile( "sh_init.lua" )
AddCSLuaFile( "sh_settings.lua" )
AddCSLuaFile( "sh_waterizer.lua" )

include( "sv_save_load.lua" )
include( "sv_other.lua" )

-- #### Physic lag detection and countermeasure ####

local function FreezeOrDeleteBlocks()
	for k, v in pairs( ents.FindByName( "mcblock" ) ) do
		if IsValid( v ) and not v.stable then
			if math.random(10) == 1 then
				-- Delete ever 10th block
				v.Entity.health = -1
				v:Remove()
			--[[else
				-- Put other blocks to sleep
				local phys = v:GetPhysicsObject()
				if IsValid( phys ) then
					phys:Sleep()
				end--]]
			end
		end
	end
end

local Time = 0
local Frequency = MC.physTimeoutFrequency
local function TimerFunction()
	
	local lag = ( os.clock() - Time ) - Frequency
	
	if lag > MC.physTimeout then
		--print("MC: Lag of " .. lag .. "s detected. Delete 10% of unstable blocks.")
		FreezeOrDeleteBlocks()
	end
	
	Time = os.clock()
	
end

local function CreateTimers()
	Time = os.clock()
	timer.Create( "MC_Lag_Watchdog", Frequency, 0, TimerFunction )
end
hook.Add( "Initialize", "MC_Create_Timers", CreateTimers )

-- When a player dies, remove ownership of all his blocks
local function OnPlayerDies( victim, inflictor, attacker )
	for k, v in pairs( ents.FindByName( "mcblock" ) ) do
		if IsValid( v ) and v:GetPlayer() == victim then
			v:SetPlayer( nil )
		end
	end
end
hook.Add( "PlayerDeath", "minecraft_swep_OnPlayerDies", OnPlayerDies )

-- When a player disconnects, remove ownership of all his blocks
local function OnPlayerDisconnects( ply )
	for k, v in pairs( ents.FindByName( "mcblock" ) ) do
		if IsValid( v ) and v:GetPlayer() == ply then
			v:SetPlayer( nil )
		end
	end
end
hook.Add( "PlayerDisconnected", "minecraft_swep_OnPlayerDisconnects", OnPlayerDisconnects )