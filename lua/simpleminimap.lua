-- set shortcuts
local fn = vim.fn
local bufopt = vim.bo
local winopt = vim.wo

local recent_cache = {}

local function generate_minimap(buf_nr)
  local minimap_win_nr = fn.bufwinnr('-MINIMAP-')
  local minimap_win_id = fn.win_getid(minimap_win_nr)

  local hscale = 2.0 * 15 / math.min(fn.winwidth('%'), 120)
  local vscale = 4.0 * fn.winheight(minimap_win_id) / fn.line('$')
  local output = fn.execute("w !code-minimap "..fn.expand('%').." -H "..hscale.." -V "..vscale.." --padding 15")

  -- save to cache
  recent_cache[buf_nr] = {
    minimap_win_id = minimap_win_id,
    minimap_win_nr = minimap_win_nr,
    minimap_content = output
  }
end

local function render_minimap(buf_nr)
  if recent_cache[buf_nr] == nil then
    return
  end

  local minimap_win_nr = recent_cache[buf_nr].minimap_win_nr
  local minimap_content = recent_cache[buf_nr].minimap_content

  -- switch to the minimap window
  vim.cmd(minimap_win_nr.." . ".."wincmd w")

  bufopt.modifiable = true
  vim.cmd("silent 1,$delete _")
  fn.execute("normal! Go"..tostring(minimap_content)) -- add to minimap buffer
  vim.cmd("silent 1,3delete _")
  bufopt.modifiable = false

  -- back to the source file
  vim.cmd("wincmd p")
end

local function open()
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

  if bufopt.filetype == 'minimap' then
    vim.cmd("wincmd p")
  end

  local curr_buf_nr = fn.bufnr('%')
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

  if fn.winnr() == minimap_win_nr then
    -- make sure to not close other minimaps
    if fn.winbufnr(2) ~= nil then
      fn.close()
      vim.cmd("wincmd p")
    end
  else
    vim.cmd(minimap_win_nr.." . ".."wincmd c")
  end
end

local function simpleminimap()
  open()
end

return {
  simpleminimap = simpleminimap,
  open = open,
  close = close,
  update = update
}
