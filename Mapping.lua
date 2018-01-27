
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

function TourGuide:MapPfQuestNPC(quest, action)
	if not self.db.char.mapquestgivers then return end
	local npcname, stype
	local title = quest

	local qLookup = pfDatabase["quests"]
	if not qLookup[quest] then
		for name, tab in pairs(qLookup) do
			local _, _, questname, _ = strfind(name, "(.*),.*")
			if questname == quest then
				quest = name
			end
		end
	end

	if qLookup[quest] then
		if action == "ACCEPT" then
			for name, type in pairs(qLookup[quest]["start"]) do
				npcname, stype = name, type
			end
		else
			for name, type in pairs(qLookup[quest]["end"]) do
				npcname, stype = name, type
			end
		end
		self:DebugF(1, "pfQuest lookup %s %s %s", action, stype, npcname)
		if stype ~= "NPC" then return end

		local sLookup = pfDatabase["spawns"]
		if sLookup[npcname] and sLookup[npcname]["coords"] then
			for id, data in pairs(sLookup[npcname]["coords"]) do
				local _, _, x, y, zone = strfind(data, "(.*),(.*),(.*)")
				MapPoint(pfDatabase["zones"][tonumber(zone)], tonumber(x), tonumber(y), title.." ("..npcname..")")
				return true
			end
		end
	end
end

function TourGuide:MapLightHeadedNPC(qid, action)
	if not self.db.char.mapquestgivers then return end
	local npcid, npcname, stype
	LightHeaded:LoadQIDData(qid)

	local title, level = LightHeaded:QIDToTitleLevel(qid)
	if action == "ACCEPT" then _, _, _, _, stype, npcname, npcid = LightHeaded:GetQuestInfo(title, level)
	else _, _, _, _, _, _, _, stype, npcname, npcid = LightHeaded:GetQuestInfo(title, level) end
	self:DebugF(1, "LightHeaded lookup %s %s %s %s %s", action, qid, stype, npcname, npcid)
	if stype ~= "npc" then return end

	local data = LightHeaded:LoadNPCData(tonumber(npcid))
	if not data then return end
	local _,_,cid,zid,x,y = string.find(data,"([^,]+),([^,]+),([^,]+),([^:]+):")
	MapPoint(zonenames[tonumber(cid)][tonumber(zid)], tonumber(x), tonumber(y), title.." ("..npcname..")")
	return true
end

function TourGuide:ParseAndMapCoords(qid, action, note, desc, zone)
	if TomTom then
		local TomTom = TomTom

		if TomTom.waypoints then
			for k,wp in ipairs(TomTom.waypoints) do
				if wp.title and string.sub(wp.title, 1, 5) == "[TG] " then
					self:DebugF(1, "Removing %q from TomTom", wp.title)
					TomTom:RemoveWaypoint(wp, true)
				end
			end
		end
	elseif Cartographer_Waypoints then
		while cache[1] do
			local pt = table.remove(cache)
			Cartographer_Waypoints:CancelWaypoint(pt)
		end
	end

	if (action == "ACCEPT" or action == "TURNIN") then
		if pfQuest then
			self:MapPfQuestNPC(desc, action)
		elseif LightHeaded then
			self:MapLightHeadedNPC(qid, action)
		end
	else
		if not note then return end
		for x,y in string.gfind(note, L.COORD_MATCH) do MapPoint(zone, tonumber(x), tonumber(y), desc) end
	end
end
