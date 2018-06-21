TG = {}

TG.join = function(delimiter, list)
  assert(type(delimiter)=="string" and type(list)=="table", "Invalid arguments to join(). Usage: string.join(delimiter, list)")
  local len = getn(list)
  if len == 0 then
    return ""
  end
  local s = list[1]
  for i = 2, len do
    s = string.format("%s%s%s",s,delimiter,list[i])
  end
  return s
end

TG.trim = function(s)
  return (string.gsub(s,"^%s*(.-)%s*$", "%1"))
end

TG.split = function(...) -- separator, string
  assert(arg.n>0 and type(arg[1])=="string", "Invalid arguments to split(). Usage: string.split([separator], subject)")
  local sep, s = arg[1], arg[2]
  if s == nil then
    s, sep = sep, ":"
  end
  local fields = {}
  local pattern = string.format("([^%s]+)", sep)
  string.gsub(s, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return fields
end

TG.modf = function(f)
  if f > 0 then
    return math.floor(f), math.mod(f,1)
  end
  return math.ceil(f), math.mod(f,1)
end
