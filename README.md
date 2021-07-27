# simpleminimap.nvim

*A fast, simple minimap plugin for Neovim built in Lua using [wfxr/code-minimap](https://github.com/wfxr/code-minimap) to generate the minimap*

This plugin is similar in looks to [wfxr/minimap.vim](https://github.com/wfxr/minimap.vim) since they are both built using code-minimap,
but simpleminimap.nvim is more performant, especially noticeable in heavy files.
This plugin was inspired by [wfxr/minimap.vim](https://github.com/wfxr/minimap.vim), which is why some things are similar.

### Why use simpleminimap.nvim?
- You want a simple minimap to display an overview of your files and show your current position
- You prefer lighter plugins to heavy ones with an overload of features
- You don't need/care about git highlighting or search highlighting in the minimap
- You want a minimap that won't cause issues with other plugins (if any do, let me know!)

### Why not use simpleminimap.nvim
- You NEED git highlighting in your minimap
- You want search highlighting in the minimap
- You don't like minimaps or don't care for them

### Optimizations over [wfxr/minimap.vim](https://github.com/wfxr/minimap.vim)
1. Highlights are not updated at all when moving horizontally
2. Highlights are only updated vertically when the cooresponding line on the minimap changes
3. It doesn't cause [Telescope's](https://github.com/nvim-telescope/telescope.nvim) registers picker to crash and not open

### How to setup
1. Install [wfxr/code-minimap](https://github.com/wfxr/code-minimap)
2. Use a plugin manager (the example uses [wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim)) to install it  
`use 'micahnico/simpleminimap.nvim'`
3. Customize the options however you want

## How to config
Add the call to the setup function and customize it how you want.
The default options are below
```lua
require("simpleminimap.config").setup {
  width = 15, highlight_group = "Title",
  highlight_match_id = 77777,
  auto_open = false,
  remember_file_pos = false,
  ignored_filetypes = {'nerdtree', 'fugitive', 'NvimTree', ''},
  ignored_buftypes = {'nowrite', 'quickfix', 'terminal'},
  closed_filetypes = {'dashboard', 'TelescopePrompt', 'netrw'},
  closed_buftypes = {'prompt'},
}
```
If you don't want to change anything, the setup call is not required
