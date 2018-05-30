
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

function TourGuide:MapPfQuestNPC(qid, action)
	if not self.db.char.mapquestgivers then return end
	local unitId
	local qLookup = pfDB["quests"]["data"]
	local loc, qid = GetLocale(), tonumber(qid)

	if qLookup[qid] then
		if action == "ACCEPT" then
			if qLookup[qid]["start"]["U"] then
				for _, uid in pairs(qLookup[qid]["start"]["U"]) do
					unitId = uid
				end
			end
		else
			if qLookup[qid]["end"]["U"] then
				for _, uid in pairs(qLookup[qid]["end"]["U"]) do
					unitId = uid
				end
			end
		end
		self:DebugF(1, "pfQuest lookup %s %s", action, unitId)

		local unitLookup = pfDB["units"]["data"]
		if unitLookup[unitId]["coords"] then
			for _, data in pairs(unitLookup[unitId]["coords"]) do
				local x, y, zone, _ = unpack(data)
				MapPoint(pfDB.zones.loc[zone], x, y, pfDB.quests.loc[qid]["T"].." ("..pfDB.units.loc[unitId]..")")
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

	if note and string.find(note, L.COORD_MATCH) then
		for x,y in string.gfind(note, L.COORD_MATCH) do MapPoint(zone, tonumber(x), tonumber(y), desc) end
	elseif (action == "ACCEPT" or action == "TURNIN") then
		if pfQuest then
			self:MapPfQuestNPC(qid, action)
		elseif LightHeaded then
			self:MapLightHeadedNPC(qid, action)
		end
	end
end
