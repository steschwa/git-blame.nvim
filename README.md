# git-blame.nvim

A Neovim plugin that displays Git blame information for the current line in a floating window.

![Git blame in a floating window in Neovim](./assets/preview.png)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "steschwa/git-blame.nvim",
    keys = {
        { "gb", "<cmd>GitBlameLine<cr>", desc = "Git blame current line" }
    },
    opts = {
        -- your configuration here
    }
}
```

## Configuration

Customize the blame output by defining **provider functions** that format the information.

### Setup Structure

```lua
{
    lines = {},   -- List of rows, each containing provider functions
    window = {}   -- Window options (passed to vim.api.nvim_open_win)
}
```

**Types:**

- `git-blame.Provider`: `fun(blame: git-blame.BlameInfo): git-blame.Part`
- `git-blame.BlameInfo`: `{ sha, author, author_email, timestamp, message }`
- `git-blame.Part`: `{ text: string, hl?: string }`

### Example

```lua
{
    "steschwa/git-blame.nvim",
    keys = {
        { "gb", "<cmd>GitBlameLine<cr>", desc = "Git blame current line" }
    },
    opts = {
        lines = {
            {
                function(blame)
                    return { text = blame.sha:sub(1, 7) .. "  ", hl = "Comment" }
                end,
                function(blame)
                    return { text = vim.fn.strftime("%Y-%m-%d", blame.timestamp) }
                end,
            },
            {
                function(blame)
                    return { text = blame.author, hl = "Bold" }
                end,
            },
            {}, -- empty line
            {
                function(blame)
                    return { text = blame.message }
                end,
            },
        },
        window = {
            border = "rounded",
        }
    }
}
```

This produces a floating window showing:
```
abc1234  2025-01-15
John Doe

feat: add new feature
```

> [!NOTE]  
> The plugin does not define custom highlight groups. Create them as needed:
> ```lua
> vim.api.nvim_set_hl(0, "GitBlameAuthor", { link = "Bold" })
> ```

## Usage

**Command:** `:GitBlameLine`

Shows blame info for the current line. If the window is already open, focuses it.

## License

MIT License. See [LICENSE](LICENSE) file for details.
