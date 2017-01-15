
local L = TourGuide.Locale

local zonei, zonec, zonenames = {}, {}, {}
for ci,c in pairs{GetMapContinents()} do
	zonenames[ci] = {GetMapZones(ci)}
	for zi,z in pairs(zonenames[ci]) do
		zonei[z], zonec[z] = zi, ci
	end
end


local cache = {}
local function MapPoint(zone, x, y, desc)
	TourGuide:DebugF(1, "Mapping %q - %s (%.2f, %.2f)", desc, zone, x, y)
	local zi, zc = zone and zonei[zone], zone and zonec[zone]
	if not zi then
		if zone then TourGuide:PrintF("Cannot find zone %q, using current zone.", zone)
		else TourGuide:Print("No zone provided, using current zone.") end

		zi, zc = GetCurrentMapZone(), GetCurrentMapContinent()
		zone = zonenames[zc][zi]
	end

	local opts = { title = "[TG] "..desc }
	if TomTom then TomTom:AddMFWaypoint(zc, zi, x/100, y/100, opts) --AddZWaypoint(c,z,x,y,desc)  select(z, GetMapZones(c))
	elseif Cartographer_Waypoints then
		local pt = NotePoint:new(zone, x/100, y/100, "[TG] "..desc)
		Cartographer_Waypoints:AddWaypoint(pt)
		table.insert(cache, pt.WaypointID)
	end
end


function TourGuide:ParseAndMapCoords(action, note, desc, zone)
	if TomTom then
		local Astrolabe = Astrolabe
		local TomTom = TomTom

		if TomTom.m_points then
			for c,ctbl in pairs(TomTom.m_points) do
				for z,ztbl in pairs(ctbl) do
					for idx,entry in pairs(ztbl) do
						if type(entry) == "table" then
							if entry.label and string.sub(entry.label, 1, 5) == "[TG] " then
								self:DebugF(1, "Removing %q from Astrolabe", entry.label)
								Astrolabe:RemoveIconFromMinimap(entry.icon)
								entry:Hide()
								table.insert(TomTom.minimapIcons, entry.icon)
								ztbl[idx] = nil
							end
						end
					end
				end
			end
		end

		if TomTom.w_points then
			for k,wp in ipairs(TomTom.w_points) do
				if wp.icon.label and string.sub(wp.icon.label, 1, 5) == "[TG] " then
					self:DebugF(1, "Removing %q from TomTom", wp.icon.label)
					local icon = wp.icon
					icon:Hide()
					TomTom.w_points[k] = nil
					table.insert(TomTom.worldmapIcons, icon)
				end
			end
		end
	elseif Cartographer_Waypoints then
		while cache[1] do
			local pt = table.remove(cache)
			Cartographer_Waypoints:CancelWaypoint(pt)
		end
	end

	if (action == "ACCEPT" or action == "TURNIN") and (questDB and spawnDB and zoneDB) then
		local coordx, coordy, zone
		local questTitle = string.gsub(desc, '%([^)]*%)', "")
		if questDB[questTitle] == nil then return end
		for monsterName, monsterDrop in pairs(questDB[questTitle]) do
			for cid, cdata in pairs(spawnDB[monsterName]["coords"]) do
				_, _, coordx, coordy, zone = strfind(spawnDB[monsterName]["coords"][cid], "(.*),(.*),(.*)")
			end
			MapPoint(zoneDB[tonumber(zone)], coordx, coordy, desc)
			return
		end
	else
		if not note then return end
		for x,y in string.gfind(note, L.COORD_MATCH) do MapPoint(zone, tonumber(x), tonumber(y), desc) end
	end
end
