--[[
  Some shims for Lua and WoW API not available in 1.12.x
  -- Roadblock & rsheep
]]
local _G = getfenv(0)
if not _G.select then
  select = function(index,...)
    assert(tonumber(index) or index=="#","Invalid argument #1 to select(). Usage: select(\"#\"|int,...)")
    if index == "#" then
      local n = 0
      for i=0,arg.n do
        if arg[i] then n = n + 1 end
      end
      return n
    end
    local sub = {}
    for i=index,arg.n do
      sub[table.getn(sub)+1] = arg[i]
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
    return fields
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
if not _G.GetItemCount then
  GetItemCount = function(itemID)
    local itemInfoTexture = select(9, GetItemInfo(itemID))
    if itemInfoTexture == nil then return 0 end
    local totalItemCount = 0
    for i=0,4 do
      local numSlots = GetContainerNumSlots(i)
      if numSlots > 0 then
        for k=1,numSlots do
          local itemTexture, itemCount = GetContainerItemInfo(i, k)
          if itemInfoTexture == itemTexture then
            totalItemCount = totalItemCount + itemCount
          end
        end
      end
    end
    return totalItemCount
  end
  _G.GetItemCount = GetItemCount
end

if not _G.print then
  print = function(str) DEFAULT_CHAT_FRAME:AddMessage(str) end
  _G.print = print
end
