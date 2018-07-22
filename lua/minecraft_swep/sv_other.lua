function MC.OwnAll( ply )
	for k, v in pairs( ents.FindByName( "mcblock" ) ) do
		if IsValid( v ) then
			v:SetPlayer( ply )
		end
	end
	
	return true
end