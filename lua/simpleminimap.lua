local config = require('simpleminimap.config').options
local contains = require('helpers').contains
local split = require('helpers').split

local cmd = vim.cmd
local api = vim.api
local fn = vim.fn
local bufopt = vim.bo
local winopt = vim.wo

local recent_cache = {}
local current_highlight

local handling_move = false

local function is_blocked(ft, bt)
  return contains(config.ignored_filetypes, ft) or contains(config.ignored_buftypes, bt)
end

local function is_closed(ft, bt)
  return contains(config.closed_filetypes, ft) or contains(config.closed_buftypes, bt)
end

local function add_highlight(minimap_win_id, target_line)
  if not current_highlight then
    fn.matchaddpos(config.highlight_group, {target_line}, 200, config.highlight_match_id, {window = minimap_win_id })
    current_highlight = {
      id = config.highlight_match_id,
      line = target_line,
    }
  end
end

local function clear_highlight(minimap_win_id)
  if current_highlight then
    -- using a vim.cmd instead of fn.matchdelete because I couldn't figure out how to make it fail silently
    cmd("silent! call matchdelete("..current_highlight.id..", "..minimap_win_id..")")
    current_highlight = nil
  end
end

local function update_cursor_pos(bufnr, line, col)
  recent_cache[bufnr].line = line
  recent_cache[bufnr].col = col
end

local function open()
  local minimap_winnr = fn.bufwinnr('-MINIMAP-')
  if minimap_winnr > -1
      or is_blocked(bufopt.filetype, bufopt.buftype)
      or is_closed(bufopt.filetype, bufopt.buftype) then
    return
  end

  cmd("noautocmd execute 'silent! ' . 'botright vertical' . "..config.width.." . 'split ' . '-MINIMAP-'")

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
  cmd("wincmd p")
end

local function close()
  local minimap_winnr = fn.bufwinnr('-MINIMAP-')

  -- return if no minimap open
  if minimap_winnr == -1 then
    return
  end

  local minimap_win_id = fn.win_getid(minimap_winnr)
  clear_highlight(minimap_win_id)
  api.nvim_win_close(minimap_win_id, true)
end

local function on_quit()
  local minimap_winnr = fn.bufwinnr('-MINIMAP-')
  -- quits if only the minimap and one other window are open
  if minimap_winnr > -1 and #api.nvim_list_wins() == 2 then
    close()
  end
end

local function generate_minimap(bufnr)
  local minimap_winnr = fn.bufwinnr('-MINIMAP-')
  local minimap_win_id = fn.win_getid(minimap_winnr)

  local wscale = 1.75 * config.width / math.min(fn.winwidth('%'), 120)
  local hscale = 4.0 * fn.winheight(minimap_win_id) / fn.line('$')
  local cmd_output = fn.system("code-minimap '"..fn.expand('%').."' -H "..wscale.." -V "..hscale.." --padding "..config.width)
  local minimap_content = split(cmd_output, "\n")

  -- save to cache
  if #minimap_content > 0 then
    recent_cache[bufnr] = {
      content = minimap_content,
      line = fn.line("."),
      col = fn.col("."),
    }
  end
end

local function render_minimap(bufnr)
  local minimap_winnr = fn.bufwinnr('-MINIMAP-')
  if minimap_winnr == -1 or recent_cache[bufnr] == nil then
    return
  end

  local curr_view = fn.winsaveview()
  -- switch to the minimap window
  cmd(minimap_winnr.." . ".."wincmd w")
  bufopt.modifiable = true
  cmd("silent 1,$delete _")
  fn.append(1, recent_cache[bufnr].content)
  cmd("silent 1delete _")
  bufopt.modifiable = false
  -- back to the source file
  cmd("wincmd p")
  fn.winrestview(curr_view)
end

local function on_move()
  if is_closed(bufopt.filetype, bufopt.buftype) then
    close()
    return
  end

  local minimap_winnr = fn.bufwinnr('-MINIMAP-')
  local curr_bufnr = fn.bufnr('%')
  if minimap_winnr == -1
      or (bufopt.filetype ~= 'minimap' and recent_cache[curr_bufnr] == nil)
      or handling_move
      or is_blocked(bufopt.filetype, bufopt.buftype) then
    return
  end

  -- if the column changed but not the line, update the saved cursor position but not the highlights
  if bufopt.filetype ~= 'minimap' and recent_cache[curr_bufnr].col ~= fn.col(".") and recent_cache[curr_bufnr].line == fn.line(".") then
    update_cursor_pos(curr_bufnr, fn.line("."), fn.col("."))
    return
  end

  handling_move = true

  local curr_total_lns = fn.line("$")
  local curr_line_percent = fn.line(".") / curr_total_lns
  local curr_ft = bufopt.filetype

  local source_bufnr = fn.bufnr('%')
  local source_line = fn.line(".")
  local source_col = fn.col(".")

  -- go to the line in the source file if in minimap
  -- update the source variables along the way
  if curr_ft == 'minimap' then
    cmd("wincmd p")
    source_bufnr = fn.bufnr("%")
    local source_total_lns = fn.line("$")
    local coor_source_line = math.max(math.floor(source_total_lns * curr_line_percent + 0.5), 1)
    fn.cursor(tostring(coor_source_line), 0)
    source_line = coor_source_line
    source_col = 0
    cmd("wincmd p")
  end

  -- one more check to handle any weird edge cases
  if recent_cache[source_bufnr] == nil then
    handling_move = false
    return
  end

  local minimap_total_lns = #recent_cache[source_bufnr].content
  local target_line = math.max(math.floor(minimap_total_lns * curr_line_percent + 0.5), 1)

  -- update the cached cursor position for the source buffer
  update_cursor_pos(source_bufnr, source_line, source_col)

  -- if the minimap line doesn't change, then don't update highlights
  if current_highlight ~= nil and target_line == current_highlight.line then
    handling_move = false
    return
  end

  -- update minimap highlight
  local minimap_win_id = fn.win_getid(minimap_winnr)
  clear_highlight(minimap_win_id)
  add_highlight(minimap_win_id, target_line)

  handling_move = false
end

local function on_update(force)
  if is_closed(bufopt.filetype, bufopt.buftype) then
    close()
    return
  end

  local minimap_winnr = fn.bufwinnr('-MINIMAP-')
  if bufopt.filetype == 'minimap'
      or is_blocked(bufopt.filetype, bufopt.buftype)
      or (minimap_winnr == -1 and not config.auto_open) then
    return
  elseif minimap_winnr == -1 and config.auto_open then
    open()
  end

  local curr_bufnr = fn.bufnr('%')

  if force or recent_cache[curr_bufnr] == nil then
    generate_minimap(curr_bufnr)
  end
  render_minimap(curr_bufnr)

  -- go back to the last saved line if remember_file_pos option is enabled
  if not force and config.remember_file_pos and recent_cache[curr_bufnr] ~= nil then
    fn.cursor(recent_cache[curr_bufnr].line, recent_cache[curr_bufnr].col)
  end

  -- set the highlights
  on_move()
end

local function reset()
  recent_cache = {}
  close()
  on_update(true)
end

return {
  open = open,
  close = close,
  reset = reset,
  on_update = on_update,
  on_move = on_move,
  on_quit = on_quit
}
