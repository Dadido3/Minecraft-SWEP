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
local TimerFreq = 0.5
local function TimerFunction()
	
	print( os.clock() - Time )
	
	if os.clock() - Time > TimerFreq + MC.physTimeout then
		FreezeAllProps()
	end
	
	Time = os.clock()
	
end

local function CreateTimers()
	Time = os.clock()
	timer.Create( "MC Phys-lag Detection", TimerFreq, 0, TimerFunction )
end
hook.Add( "Initialize", "MC Create timers", CreateTimers )