local M = {}

M.options = {
  width = 15,
  highlight_group = "Title",
  highlight_match_id = 77777,
  auto_open = true,
  ignored_filetypes = {'NvimTree', 'dashboard', "TelescopePrompt", ""},
  ignored_buftypes = {'prompt'},
  closed_filetypes = {'NvimTree', 'dashboard', 'TelescopePrompt'},
  closed_buftypes = {'prompt'},
  -- unimplemented from here down
  remember_file_pos = true,
  cache_limit = 20
}

M.setup = function(user_data)
  M.options = vim.tbl_deep_extend("force", M.options, user_data)
end

return M
