---@class git-blame.Config
---@field lines git-blame.Provider[][]
---@field window any
local Config = {}

---@param opts git-blame.SetupOpts
function Config:create(opts)
	-- TODO: validate `opts`

	---@type git-blame.Config
	local c = {
		lines = opts.lines,
		window = vim.tbl_deep_extend("keep", opts.window, {}),
	}

	return setmetatable(c, { __index = Config })
end

return Config
