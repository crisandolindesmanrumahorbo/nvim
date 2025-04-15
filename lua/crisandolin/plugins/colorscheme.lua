return {
  "folke/tokyonight.nvim",
  priority = 1000,
  config = function()
    local transparent = true -- set to true if you would like to enable transparency

    local bg = "#011628"
    local bg_dark = "#011423"
    local bg_highlight = "#143652"
    local bg_search = "#0A64AC"
    local bg_visual = "#275378"
    local fg = "#CBE0F0"
    local fg_dark = "#B4D0E9"
    local fg_gutter = "#627E97"
    local border = "#547998"

    require("tokyonight").setup({
      style = "night",
      transparent = transparent,
      styles = {
        sidebars = transparent and "transparent" or "dark",
        floats = transparent and "transparent" or "dark",
      },
      on_colors = function(colors)
        colors.bg = bg
        colors.bg_dark = transparent and colors.none or bg_dark
        colors.bg_float = transparent and colors.none or bg_dark
        colors.bg_highlight = bg_highlight
        colors.bg_popup = bg_dark
        colors.bg_search = bg_search
        colors.bg_sidebar = transparent and colors.none or bg_dark
        colors.bg_statusline = transparent and colors.none or bg_dark
        colors.bg_visual = bg_visual
        colors.border = border
        colors.fg = fg
        colors.fg_dark = fg_dark
        colors.fg_float = fg
        colors.fg_gutter = fg_gutter
        colors.fg_sidebar = fg_dark
      end,

      -- Rust color scheme
      on_highlights = function(hl, c)
        -- LSP suggestion menu improvements
        hl.Pmenu = { bg = c.bg_highlight } -- Background of completion menu
        hl.PmenuSel = { bg = c.bg_visual, fg = c.fg } -- Selected item
        hl.PmenuSbar = { bg = c.bg_dark } -- Scrollbar background
        hl.PmenuThumb = { bg = c.fg_gutter } -- Scrollbar thumb

        -- LSP documentation hover window
        hl.LspFloatWinNormal = { bg = c.bg_dark, fg = c.fg }
        hl.LspFloatWinBorder = { fg = c.border }

        -- Inlay hints (if using Rust Analyzer's inlay hints)
        hl.LspInlayHint = { bg = c.none, fg = c.fg_gutter, italic = true }

        -- LSP reference highlight
        hl.LspReferenceText = { bg = c.bg_visual }
        hl.LspReferenceRead = { bg = c.bg_visual }
        hl.LspReferenceWrite = { bg = c.bg_visual }

        -- Specific Rust LSP improvements
        hl["@lsp.type.function.rust"] = { link = "@function" } -- Rust functions
        hl["@lsp.type.method.rust"] = { link = "@method" } -- Rust methods
        hl["@lsp.typemod.function.defaultLibrary.rust"] = { fg = c.blue } -- Library functions like Box::new
      end,
    })

    vim.cmd("colorscheme tokyonight")
  end,
}