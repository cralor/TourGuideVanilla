--[[
  Some shims for Lua and WoW API not available in 1.12.x
  -- Roadblock & rsheep
]]
local _G = getfenv(0)
if not _G.select then 
  select = function(index,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
    local tab = {a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20}
    if index == "#" then return table.getn(tab) end
    local sub = {}
    for i=index,table.getn(tab) do
      sub[table.getn(sub)+1] = tab[i]
    end
    return unpack(sub)
  end
  _G.select = select
end
if not string.trim then
  string.trim = function(s)
    return (string.gsub(s,"^%s*(.-)%s*$", "%1"))
  end
end
if not string.split then
  string.split = function(sep,s)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(s, pattern, function(c) fields[table.getn(fields)+1] = c end)
    return unpack(fields)
  end
end
if not math.modf then
  math.modf = function(f)
    local a = math.abs(f)
    local itg,fr 
    if f >= 0 then
      itg, fr = math.floor(a), a-math.floor(a)
    else
      itg, fr = -math.floor(a), -(a-math.floor(a))
    end
    return itg,fr
  end
end
if not _G.InCombatLockdown then
  InCombatLockdown = function()
    return UnitAffectingCombat("player")
  end
  _G.InCombatLockdown = InCombatLockdown
end