# CRUSH.md

AI Assistant guide for working in the `git-blame.nvim` codebase.

## Project Overview

**Type**: Neovim plugin (Lua)  
**Purpose**: Display Git blame information for the current line in a floating window  
**Size**: ~320 lines of Lua code across 5 modules  
**Structure**: Single plugin with modular architecture

## Commands

### Release
```bash
just release          # Run the release script
./scripts/release.sh  # Generate changelog, commit, tag, and push
```

The release process:
1. Uses `git-cliff` to bump version and update CHANGELOG.md
2. Commits changelog with message: `chore(release): prepare for vX.Y.Z`
3. Creates Git tag with version number (e.g., `v1.2.0`)
4. Pushes both main branch and the new tag to remote
5. GitHub Actions workflow creates release from the tag

### Development
No test suite, linter, or formatter is configured in this project.

## Project Structure

```
lua/git-blame/
├── init.lua      # Main entry point, setup(), user command registration
├── config.lua    # Configuration validation and defaults
├── types.lua     # Type definitions for LuaLS
├── git.lua       # Git blame execution and output parsing
└── ui.lua        # Floating window rendering and management
```

### Module Responsibilities

- **init.lua**: Plugin initialization, creates `GitBlameLine` user command
- **config.lua**: Validates setup options, provides defaults for window config
- **types.lua**: Type annotations for git-blame.Part, git-blame.Provider, git-blame.SetupOpts
- **git.lua**: Executes `git blame --incremental`, parses output into BlameInfo objects
- **ui.lua**: Manages floating window lifecycle, renders blame info using provider functions

## Code Patterns

### Type Annotations
All functions use LuaLS annotations extensively:
```lua
---@param opts git-blame.SetupOpts
function M.setup(opts)
  -- implementation
end
```

Key types:
- `git-blame.BlameInfo`: sha, author, author_email, timestamp, message
- `git-blame.Provider`: Function that takes BlameInfo and returns git-blame.Part
- `git-blame.Part`: Table with `text` (string) and optional `hl` (highlight group)
- `git-blame.SetupOpts`: Configuration with `lines` (Provider[][]) and optional `window` config

### Configuration Pattern
- Config validation uses `vim.validate()` with detailed path strings (e.g., `"lines[1][2]"`)
- Config extends defaults using `vim.tbl_deep_extend("keep", user_opts, defaults)`
- Window config extends vim's `keyset.win_config` with user overrides

### UI/Window Management
- Creates scratch buffer (`vim.api.nvim_create_buf(false, true)`)
- Window positioned relative to cursor using `bufpos` and current cursor position
- Highlights applied per-part using `vim.hl.range()` with custom namespace
- Auto-closes window on cursor movement via autocommand group
- Window width calculated dynamically based on rendered content using `vim.api.nvim_strwidth()`

### Git Integration
- Uses `vim.system()` for async git blame execution
- Parses `git blame --incremental` format (tag-word based output)
- Executes blame for single line: `-L{line_nr},+1`
- Runs in context of file's directory (`cwd = vim.fn.fnamemodify(filename, ":h")`)
- Callbacks wrapped in `vim.schedule()` for main thread safety

### Object-Oriented Style
Uses metatables for OOP:
```lua
local Config = {}
function Config:create(opts)
  local c = { ... }
  return setmetatable(c, { __index = Config })
end
```

Window and Config are instantiated objects, not module singletons.

## Naming Conventions

### Files
- All lowercase, hyphenated: `git-blame/init.lua`
- Module names match directory structure

### Variables
- Snake_case for locals: `line_width`, `rendered_lines`, `tag_word`
- SCREAMING_CASE for constants: `WIN_AUGROUP`, `WIN_NS`
- Uppercase for module tables: `M`, `Config`, `Window`, `Git`

### Functions
- Snake_case: `render_lines()`, `blame_current_line()`, `find_by_tag_word()`
- Colon notation for methods: `Window:open()`, `Config:create()`

### Types
- Namespaced with plugin prefix: `git-blame.BlameInfo`, `git-blame.Provider`
- CamelCase for class-like types: `BlameInfo`, `SetupOpts`

## Plugin Architecture

### Setup Flow
1. User calls `require("git-blame").setup(opts)`
2. Config validates and extends options
3. Window instance created with config
4. `:GitBlameLine` user command registered

### Runtime Flow
1. User triggers `:GitBlameLine` command
2. If window already open → focus it and return
3. Otherwise → `Git.blame_current_line()` executes async
4. Parse blame output into BlameInfo object
5. Provider functions render BlameInfo into Parts
6. Window opens with rendered content
7. Autocommand closes window on cursor movement

### Provider System
Users configure output through provider functions:
```lua
lines = {
  { provider_sha, provider_time },  -- Row 1: two parts side-by-side
  { provider_author },               -- Row 2: one part
  {},                                -- Row 3: empty line
  { provider_message },              -- Row 4: one part
}
```

Each provider receives `BlameInfo`, returns `{ text = "...", hl = "..." }`.

## Version Management

### Conventional Commits
Project uses conventional commits with `git-cliff` for changelog generation:
- `feat:` → 🚀 Features
- `fix:` → 🐛 Bug Fixes
- `refactor:` → 🚜 Refactor
- `chore:` → ⚙️ Miscellaneous Tasks (most chore commits skipped)
- `chore(release):` commits are filtered from changelog

### Release Process
Automated via `just release`:
1. `git cliff --bump` updates CHANGELOG.md with new version
2. Script extracts version from `git cliff --bumped-version`
3. Commits changelog and creates tag
4. Pushes to remote (both branch and tag)
5. GitHub Actions generates release notes using `git-cliff-action`

Versions follow semver and are prefixed with `v` (e.g., `v1.2.0`).

## Important Gotchas

### No Highlight Groups Defined
The plugin does NOT define any highlight groups. Users must create them:
```lua
vim.api.nvim_set_hl(0, "GitBlameTime", { link = "Label" })
```
Without this, custom highlight groups won't work.

### Empty Lines Configuration
Empty line in config is just an empty table: `{}`

### Window Reuse
The command checks if window is already open and focuses it instead of creating new window. This prevents duplicate windows.

### Git Blame Format
Uses `--incremental` format which is tag-word based:
```
<sha> <source-line> <result-line> <num-lines>
author <author-name>
author-mail <email>
author-time <unix-timestamp>
summary <commit-message>
```

Parser expects exactly this format and 40-character SHA.

### Async Safety
All git operations are async. Callbacks use `vim.schedule()` to ensure they run on main event loop, not background thread.

### Buffer Cleanup
Window and buffer are force-deleted on close. Namespace is cleared before buffer deletion.

## Context for AI Agents

### When Adding Features
- Maintain extensive type annotations for all new functions
- Follow the provider pattern for extensibility
- Keep git operations async with `vim.system()`
- Use namespace for all highlights to avoid conflicts

### When Fixing Bugs
- Check if issue is in git parsing (git.lua), rendering (ui.lua), or config validation (config.lua)
- Window-related issues often involve buffer/window validity checks
- Git issues typically involve format parsing or async callback timing

### When Refactoring
- Preserve the provider function API (breaking change)
- Keep setup interface backward compatible if possible
- Follow conventional commits for changelog generation
- Test with various git repositories (edge cases in blame output)

### Code Style
- 4-space indentation (not tabs)
- Use `vim.api.*` for Neovim API calls
- Prefer `vim.validate()` over manual validation
- Use `vim.tbl_deep_extend()` for merging tables
- Anonymous functions use `function()`, not arrow syntax
- No trailing commas in tables

### Dependencies
This plugin has zero external dependencies:
- Uses only Neovim built-in APIs
- No external Lua libraries
- Requires Neovim with `vim.system()` support (0.10+)
- Git must be available in PATH

### User Command
Only one command exposed: `:GitBlameLine`
- No arguments
- Focuses existing window if already open
- Shows blame for current line under cursor
