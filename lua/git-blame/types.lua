---@class git-blame.Part
---@field text string
---@field hl string?

---@class git-blame.SetupOpts
---@field lines git-blame.Provider[][]
---@field window? any

---@alias git-blame.Provider fun(blame: git-blame.BlameInfo): git-blame.Part
