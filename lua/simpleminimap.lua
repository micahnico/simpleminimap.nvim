-- set shortcuts
local fn = vim.fn
local bufopt = vim.bo
local winopt = vim.wo

local recent_cache = {}
local curr_hightlight_match_ids = {}
local next_highlight_match_id = 77777

local function clear_highlights()
  for i=1, #curr_hightlight_match_ids do
    fn.matchdelete(curr_hightlight_match_ids[i])
  end
  curr_hightlight_match_ids = {}
end

local function generate_minimap(buf_nr)
  local minimap_win_nr = fn.bufwinnr('-MINIMAP-')
  local minimap_win_id = fn.win_getid(minimap_win_nr)

  local wscale = 2.0 * 15 / math.min(fn.winwidth('%'), 110)
  local hscale = 4.0 * fn.winheight(minimap_win_id) / fn.line('$')
  local output = fn.execute("w !code-minimap "..fn.expand('%').." -H "..wscale.." -V "..hscale.." --padding 15")

  -- save to cache
  recent_cache[buf_nr] = {
    win_id = minimap_win_id,
    win_nr = minimap_win_nr,
    content = output
  }
end

local function render_minimap(buf_nr)
  if recent_cache[buf_nr] == nil then
    return
  end

  local minimap_win_nr = recent_cache[buf_nr].win_nr
  local minimap_content = recent_cache[buf_nr].content

  -- switch to the minimap window
  vim.cmd(minimap_win_nr.." . ".."wincmd w")

  bufopt.modifiable = true
  vim.cmd("silent 1,$delete _")
  fn.execute("normal! Go"..tostring(minimap_content)) -- add to minimap buffer
  vim.cmd("silent 1,3delete _")
  vim.cmd("silent $delete _")
  vim.cmd("silent $delete _")
  bufopt.modifiable = false

  -- back to the source file
  vim.cmd("wincmd p")
end

local function on_scroll()
  local minimap_win_nr = fn.bufwinnr('-MINIMAP-')
  -- return if no minimap open
  -- should never be the case here, but still make sure
  if minimap_win_nr == -1 then
    return
  end

  local curr_total_lns = fn.line("$")
  local curr_line_percent = fn.line(".") / curr_total_lns
  local curr_ft = bufopt.filetype

  vim.cmd("wincmd p")
  local target_total_lns = fn.line("$")
  local target_line = math.max(math.floor(target_total_lns * curr_line_percent + 0.5), 1)

  if curr_ft == 'minimap' then
    fn.cursor(tostring(target_line), 0)
  else
    clear_highlights()
    fn.matchaddpos("Title", {target_line}, 200, next_highlight_match_id)
    curr_hightlight_match_ids[1] = next_highlight_match_id
    next_highlight_match_id = next_highlight_match_id + 1
  end

  vim.cmd("wincmd p")
end

local function open()
  -- return if minimap is already open
  local minimap_win_nr = fn.bufwinnr('-MINIMAP-')
  if minimap_win_nr > -1 then
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

local function update()
  local minimap_win_nr = fn.bufwinnr('-MINIMAP-')

  -- return if no minimap open
  if minimap_win_nr == -1 then
    return
  end

  local curr_buf_nr = fn.bufnr('%')

  if bufopt.filetype == 'minimap' then
    return
  end

  if recent_cache[curr_buf_nr] == nil then
    generate_minimap(curr_buf_nr)
  end
  render_minimap(curr_buf_nr)
end

local function close()
  local minimap_win_nr = fn.bufwinnr('-MINIMAP-')

  -- return if no minimap open
  if minimap_win_nr == -1 then
    return
  end

  vim.cmd(minimap_win_nr.." . ".."wincmd c")
end

return {
  open = open,
  close = close,
  update = update,
  on_scroll = on_scroll
}
