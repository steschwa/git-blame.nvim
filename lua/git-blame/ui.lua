---@param lines git-blame.Provider[][]
---@param blame git-blame.BlameInfo
---@return git-blame.Part[][]
local function render_lines(lines, blame)
	if #lines == 0 then
		return {}
	end

	---@type git-blame.Part[][]
	local rendered_lines = {}
	for _, line in ipairs(lines) do
		---@type git-blame.Part[]
		local rendered_line = {}
		for _, provider in ipairs(line) do
			table.insert(rendered_line, provider(blame))
		end

		table.insert(rendered_lines, rendered_line)
	end

	return rendered_lines
end

---@class git-blame.Window
---@field config git-blame.Config
---@field win integer
---@field buf integer
local Window = {
	win = -1,
	buf = -1,
}

local WIN_AUGROUP = vim.api.nvim_create_augroup("git-blame.window", {
	clear = true,
})

---@param config git-blame.Config
---@return git-blame.Window
function Window:new(config)
	local o = {
		config = config,
	}

	return setmetatable(o, { __index = Window })
end

function Window:close()
	local win_valid = vim.api.nvim_win_is_valid(self.win)
	if win_valid then
		vim.api.nvim_win_close(self.win, true)
		self.win = -1
	end

	local buf_valid = vim.api.nvim_buf_is_valid(self.buf)
	if buf_valid then
		vim.api.nvim_buf_delete(self.buf, { force = true })
		self.buf = -1
	end

	vim.api.nvim_clear_autocmds({
		group = WIN_AUGROUP,
	})
end

---@return boolean
function Window:is_open()
	return vim.api.nvim_win_is_valid(self.win) and vim.api.nvim_buf_is_valid(self.buf)
end

function Window:focus()
	local win_valid = vim.api.nvim_win_is_valid(self.win)
	if not win_valid then
		return
	end

	vim.api.nvim_set_current_win(self.win)
end

---@param blame git-blame.BlameInfo
function Window:open(blame)
	local rendered_lines = render_lines(self.config.lines, blame)
	if #rendered_lines == 0 then
		return
	end

	self.buf = vim.api.nvim_create_buf(false, true)

	local line_width = 0
	for row, line in ipairs(rendered_lines) do
		local line_text = ""
		for _, part in ipairs(line) do
			line_text = line_text .. part.text
		end

		vim.api.nvim_buf_set_lines(self.buf, row - 1, row, false, { line_text })

		local col_start = 0
		for _, part in ipairs(line) do
			local col_end = col_start + #part.text

			if part.hl then
				vim.api.nvim_buf_add_highlight(self.buf, -1, part.hl, row - 1, col_start, col_end)
			end

			col_start = col_end
		end

		line_width = math.max(line_width, #line_text)
	end

	vim.bo[self.buf].modifiable = false
	vim.bo[self.buf].filetype = "GitBlame"

	local cursor = vim.api.nvim_win_get_cursor(0)

	self.win = vim.api.nvim_open_win(self.buf, false, {
		relative = "win",
		bufpos = { cursor[1] - 1, cursor[2] },
		width = line_width,
		height = #rendered_lines,
		style = "minimal",
		border = "single",
	})

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = WIN_AUGROUP,
		callback = function(event)
			local is_self = event.buf == self.buf
			if is_self then
				return
			end

			self:close()
		end,
	})
end

return Window
