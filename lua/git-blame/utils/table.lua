local Table = {}

---@param table table
---@param key string
---@return boolean
function Table.has_key(table, key)
	for _, value in pairs(table) do
		if value == key then
			return true
		end
	end

	return false
end

return Table
