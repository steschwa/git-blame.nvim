---@class git-blame.BlameInfo
---@field sha string
---@field author string
---@field author_email string
---@field timestamp integer -- unix timestamp in seconds
---@field message string

---@param tag_word string
---@param lines string[]
---@return string|nil
local function find_by_tag_word(tag_word, lines)
	for _, line in ipairs(lines) do
		if vim.startswith(line, tag_word) then
			-- format: "<tag-word> <value>"
			return line:sub(#tag_word + 1 + #" ")
		end
	end
end

---@param output string
---@return git-blame.BlameInfo|nil
local function parse_blame_output(output)
	local lines = vim.split(output, "\n")

	if #lines == 0 then
		return
	end

	---@see https://git-scm.com/docs/git-blame#_incremental_output

	local sha = lines[1]:match("^(%x+)")
	if not sha then
		return
	end
	if #sha ~= 40 then
		return
	end

	local author = find_by_tag_word("author", lines)
	if not author then
		return
	end

	local author_email = find_by_tag_word("author-mail", lines)
	if not author_email then
		return
	end
	author_email = author_email:match("<(.+)>")

	local timestamp = tonumber(find_by_tag_word("author-time", lines))
	if not timestamp then
		return
	end

	local message = find_by_tag_word("summary", lines)
	if not message then
		return
	end

	---@type git-blame.BlameInfo
	return {
		sha = sha,
		author = author,
		author_email = author_email,
		timestamp = timestamp,
		message = message,
	}
end

local Git = {}

---@param on_blame fun(blame: git-blame.BlameInfo)
function Git.blame_current_line(on_blame)
	local line_nr = vim.fn.line(".")
	local filename = vim.fn.fnamemodify(vim.fn.expand("%"), ":p")

	local args = { "git", "blame", "--incremental", string.format("-L%d,+1", line_nr), "--", filename }

	---@type vim.SystemOpts
	local opts = {
		text = true,
		cwd = vim.fn.fnamemodify(filename, ":h"),
	}

	vim.system(args, opts, function(out)
		if not out then
			return
		end

		local blame = parse_blame_output(out.stdout)
		if not blame then
			return
		end

		vim.schedule(function()
			on_blame(blame)
		end)
	end)
end

return Git
