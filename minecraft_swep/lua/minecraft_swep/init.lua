--[[

Minecraft SWEP addon
created by McKay and 
extended by David Vogel (Dadido3)

]]

AddCSLuaFile( "sh_init.lua" )
AddCSLuaFile( "sh_settings.lua" )
AddCSLuaFile( "sh_waterizer.lua" )

-- #### Physic lag detection and countermeasure ####

local function FreezeAllProps()
	for k, v in pairs( ents.FindByName( "mcblock" ) ) do
		if IsValid( v ) then
			local phys = v:GetPhysicsObject()
			if IsValid( phys ) then
				phys:Sleep()
			end
		end
	end		
end

local Time = 0
local TimerFreq = 1
local function TimerFunction()
	
	if CurTime() - Time > TimerFreq + MC.physTimeout then
		print( "Physics timeout!" )
		FreezeAllProps()
	end
	
	Time = CurTime()
	
end

local function CreateTimers()
	Time = CurTime()
	timer.Create( "MC Phys-lag Detection", TimerFreq, 0, TimerFunction )
end
hook.Add( "Initialize", "MC Create timers", CreateTimers )