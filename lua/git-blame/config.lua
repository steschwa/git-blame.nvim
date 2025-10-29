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

	---@type vim.api.keyset.win_config
	local default_window = {
		style = "minimal",
	}

	---@type git-blame.Config
	local c = {
		lines = opts.lines,
		window = vim.tbl_deep_extend("keep", opts.window or {}, default_window),
	}

	return setmetatable(c, { __index = Config })
end

return Config
