---@class git-blame.Config
---@field lines git-blame.Provider[][]
local Config = {}

---@class git-blame.CreateConfigOpts
---@field lines git-blame.Provider[][]

---@param opts git-blame.CreateConfigOpts
function Config:create(opts)
	local o = {
		lines = opts.lines,
	}
	return setmetatable(o, { __index = Config })
end

return Config
