-- LazyVim defaults are auto-loaded; add overrides here.
-- https://www.lazyvim.org/configuration/autocmds

-- Open neo-tree automatically when nvim is launched on a directory.
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("OpenDirOnStartup", { clear = true }),
  callback = function()
    local arg = vim.fn.argv(0)
    if type(arg) == "string" and vim.fn.isdirectory(arg) == 1 then
      vim.schedule(function()
        require("neo-tree.command").execute({ action = "show", dir = arg })
      end)
    end
  end,
})
