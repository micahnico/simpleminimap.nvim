local M = {}

M.options = {
  width = 15,
  highlight_group = "Title",
  highlight_match_id = 77777,
  auto_open = false,
  remember_file_pos = false,
  ignored_filetypes = {'nerdtree', 'fugitive', 'NvimTree', ''},
  ignored_buftypes = {'nowrite', 'quickfix', 'terminal'},
  closed_filetypes = {'dashboard', 'TelescopePrompt', 'netrw'},
  closed_buftypes = {'prompt'},
}

M.setup = function(user_data)
  M.options = vim.tbl_deep_extend("force", M.options, user_data)
end

return M
