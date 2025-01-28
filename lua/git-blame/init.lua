local Window = require("git-blame.ui")
local Git = require("git-blame.git")
local TableUtils = require("git-blame.utils.table")

---@class git-blame.WinConfig
---@field border string|string[]|nil

---@class git-blame.Config
---@field lines git-blame.Provider[][]
---@field window git-blame.WinConfig

---@class git-blame.Instance
---@field config git-blame.Config
---@field win git-blame.Window
local M = {}

---@param opts git-blame.Config
---@return git-blame.Config
function M.create_config(opts)
	opts = opts or {}

	---@type git-blame.Config
	local config = {
		lines = opts.lines or {},
		window = {
			border = "single",
		},
	}

	if TableUtils.has_key(opts.window or {}, "border") then
		config.window.border = opts.window.border
	end

	return config
end

---@param opts git-blame.Config
function M.setup(opts)
	M.config = M.create_config(opts)
	M.win = Window:new(M.config)

	vim.api.nvim_create_user_command("GitBlameLine", function()
		if M.win:is_open() then
			M.win:focus()
			return
		end

		Git.blame_current_line(function(blame)
			M.win:open(blame)
		end)
	end, {
		force = false,
	})
end

return M
