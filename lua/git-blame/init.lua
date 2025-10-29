local Window = require("git-blame.ui")
local Git = require("git-blame.git")
local Config = require("git-blame.config")

---@class git-blame.Instance
---@field config git-blame.Config
---@field win git-blame.Window
local M = {}

---@param opts git-blame.SetupOpts
function M.setup(opts)
	M.config = Config:create(opts)
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
