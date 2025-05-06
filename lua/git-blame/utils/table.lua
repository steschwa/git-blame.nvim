local Table = {}

---@param table table
---@param key string
---@return boolean
function Table.has_key(table, key)
	for k in pairs(table) do
		if k == key then
			return true
		end
	end

	return false
end

return Table
