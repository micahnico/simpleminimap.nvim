-- set shortcuts
local fn = vim.fn
local bufopt = vim.bo
local winopt = vim.wo

local recent_cache = {}

local current_highlights = {}
local curr_highlight_match_id = 77777

local handling_move = false

local function split(s, sep)
  local fields = {}
  local pattern = string.format("([^%s]+)", sep)
  string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
  return fields
end

local function is_blocked(ft, bt)
  -- TODO: make options for these
  return ft == 'NvimTree' or ft == 'dashboard' or ft == "TelescopePrompt" or bt == 'prompt'
end

local function add_highlight(minimap_win_nr, minimap_win_id, target_line)
  if not current_highlights[minimap_win_nr] then
    fn.matchaddpos("Title", {target_line}, 200, curr_highlight_match_id, {window = minimap_win_id })
    current_highlights[minimap_win_nr] = curr_highlight_match_id
    curr_highlight_match_id = curr_highlight_match_id + 1
  end
end

local function clear_highlight(minimap_win_nr, minimap_win_id)
  if current_highlights[minimap_win_nr] then
    fn.matchdelete(current_highlights[minimap_win_nr], minimap_win_id)
    current_highlights[minimap_win_nr] = nil
    curr_highlight_match_id = curr_highlight_match_id - 1
  end
end

local function generate_minimap(buf_nr)
  local minimap_win_nr = fn.bufwinnr('-MINIMAP-')
  local minimap_win_id = fn.win_getid(minimap_win_nr)

  local wscale = 1.75 * 15 / math.min(fn.winwidth('%'), 120)
  local hscale = 4.0 * fn.winheight(minimap_win_id) / fn.line('$')
  local cmd_output = fn.system("code-minimap "..fn.expand('%').." -H "..wscale.." -V "..hscale.." --padding 15")
  local minimap_content = split(cmd_output, "\n")

  -- save to cache
  if #minimap_content > 0 then
    recent_cache[buf_nr] = minimap_content
  end
end

local function render_minimap(buf_nr)
  local minimap_win_nr = fn.bufwinnr('-MINIMAP-')
  if minimap_win_nr == -1 or recent_cache[buf_nr] == nil then
    return
  end

  -- switch to the minimap window
  vim.cmd(minimap_win_nr.." . ".."wincmd w")

  bufopt.modifiable = true
  vim.cmd("silent 1,$delete _")
  fn.append(1, recent_cache[buf_nr])
  vim.cmd("silent 1delete _")
  bufopt.modifiable = false

  -- back to the source file
  vim.cmd("wincmd p")
end

local function on_move()
  local minimap_win_nr = fn.bufwinnr('-MINIMAP-')
  local curr_buf_nr = fn.bufnr('%')
  if minimap_win_nr == -1 or recent_cache[curr_buf_nr] == nil or handling_move or is_blocked(bufopt.filetype, bufopt.buftype) then
    return
  end

  handling_move = true

  local curr_total_lns = fn.line("$")
  local curr_line_percent = fn.line(".") / curr_total_lns
  local curr_ft = bufopt.filetype

  local minimap_win_id = fn.win_getid(minimap_win_nr)
  local minimap_total_lns = fn.getwininfo(minimap_win_id)[1].botline

  -- go to the line in the source file if in minimap
  if curr_ft == 'minimap' then
    vim.cmd("wincmd p")
    local source_total_lns = fn.line("$")
    local coor_source_line = math.max(math.floor(source_total_lns * curr_line_percent + 0.5), 1)
    fn.cursor(tostring(coor_source_line), 0)
    vim.cmd("wincmd p")
  else
    -- fixes an issue where the total minimap line numbers are incorrect
    minimap_total_lns = #recent_cache[fn.bufnr('%')]
  end

  local target_line = math.max(math.floor(minimap_total_lns * curr_line_percent + 0.5), 1)

  -- update minimap highlight
  clear_highlight(minimap_win_nr, minimap_win_id)
  add_highlight(minimap_win_nr, minimap_win_id, target_line)

  handling_move = false
end

local function on_update(force)
  local minimap_win_nr = fn.bufwinnr('-MINIMAP-')
  if minimap_win_nr == -1 or bufopt.filetype == 'minimap' or is_blocked(bufopt.filetype, bufopt.buftype) then
    return
  end

  local curr_buf_nr = fn.bufnr('%')

  if force or recent_cache[curr_buf_nr] == nil then
    generate_minimap(curr_buf_nr)
  end
  render_minimap(curr_buf_nr)

  -- set the highlights
  on_move()
end

local function open()
  local minimap_win_nr = fn.bufwinnr('-MINIMAP-')
  if minimap_win_nr > -1 or is_blocked(bufopt.filetype, bufopt.buftype) then
    return
  end

  vim.cmd("noautocmd execute 'silent! ' . 'botright vertical' . 15 . 'split ' . '-MINIMAP-'")

  -- buffer options
  bufopt.filetype = "minimap"
  bufopt.readonly = false
  bufopt.buftype = "nofile"
  bufopt.bufhidden = "hide"
  bufopt.swapfile = false
  bufopt.buflisted = false
  bufopt.modifiable = false
  bufopt.textwidth = 0

  -- window options
  winopt.list = false
  winopt.winfixwidth = true
  winopt.spell = false
  winopt.wrap = false
  winopt.number = false
  winopt.relativenumber = false
  winopt.foldenable = false
  winopt.foldcolumn = "0"
  winopt.cursorline = false
  winopt.signcolumn = "no"
  winopt.sidescrolloff = 0

  -- switch back to source file
  vim.cmd("wincmd p")
end

local function close()
  local minimap_win_nr = fn.bufwinnr('-MINIMAP-')

  -- return if no minimap open
  if minimap_win_nr == -1 then
    return
  end

  local minimap_win_id = fn.win_getid(minimap_win_nr)
  clear_highlight(minimap_win_nr, minimap_win_id)
  vim.cmd(minimap_win_nr.." . ".."wincmd c")
end

return {
  open = open,
  close = close,
  on_update = on_update,
  on_move = on_move
}
