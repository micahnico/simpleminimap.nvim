local M = {}

M.split = function(s, sep)
  local fields = {}
  local pattern = string.format("([^%s]+)", sep)
  string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
  return fields
end

M.contains = function(table, element)
  local index={}
  for k,v in pairs(table) do
     index[v]=k
  end
  return index[element]
end

return M
