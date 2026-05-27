return {
  -- File explorer on the right side, VS Code style.
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        position = "right",
        width = 32,
      },
    },
  },

  -- Bufferline already ships with LazyVim; tighten it to feel like VS Code tabs.
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        mode = "buffers",
        separator_style = "thin",
        always_show_bufferline = true,
        show_buffer_close_icons = true,
        show_close_icon = false,
        diagnostics = "nvim_lsp",
      },
    },
  },

  -- Bottom-docked toggleable terminal panel. <C-/> toggles it like VS Code.
  {
    "akinsho/toggleterm.nvim",
    event = "VeryLazy",
    opts = {
      direction = "horizontal",
      size = 15,
      shade_terminals = true,
      start_in_insert = true,
      persist_size = true,
      open_mapping = [[<C-/>]],
    },
    keys = {
      { "<C-/>", "<cmd>ToggleTerm<cr>", mode = { "n", "t", "i" }, desc = "Toggle terminal" },
    },
  },
}
