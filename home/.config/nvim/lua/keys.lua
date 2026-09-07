-- save by pressing Escape.
-- A function rather than ':w<CR>': a normal-mode mapping that starts with ':'
-- turns a pending count into a range, so '5<Esc>' would run ':.,.+4w' and fail
-- instead of just clearing the count. The guard keeps Escape harmless in
-- buffers with no file behind them, which is every plugin window.
vim.keymap.set('n', '<Esc>', function()
  if vim.bo.buftype == '' and vim.api.nvim_buf_get_name(0) ~= '' then
    vim.cmd.write()
  end
end, { desc = 'Save' })
-- select all
vim.keymap.set('n', '<C-a>', 'ggVG', { desc = 'Select All' })
-- pasting over a selection no longer clobbers your clipboard: P has kept the
-- register since 0.9, so the old reselect-and-re-yank dance is gone
vim.keymap.set('x', 'p', 'P', { desc = 'Paste over selection' })
