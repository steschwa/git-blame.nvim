---@param opts git-blame.SetupOpts
local function validate_setup_opts(opts)
	vim.validate("lines", opts.lines, "table")
	for i, line in ipairs(opts.lines) do
		vim.validate(string.format("lines[%d]", i), line, "table")

		for j, provider in ipairs(line) do
			vim.validate(string.format("lines[%d][%d]", i, j), provider, "function")
		end
	end

	vim.validate("window", opts.window, "table", true)
end

---@class git-blame.Config
---@field lines git-blame.Provider[][]
---@field window vim.api.keyset.win_config
local Config = {}

---@param opts git-blame.SetupOpts
function Config:create(opts)
	validate_setup_opts(opts)

	---@type git-blame.Config
	local c = {
		lines = opts.lines,
		window = opts.window or {},
	}

	return setmetatable(c, { __index = Config })
end

return Config
