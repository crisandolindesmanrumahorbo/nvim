return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
  },
  config = function()
    -- import lspconfig plugin
    local lspconfig = require("lspconfig")

    -- import mason_lspconfig plugin
    local mason_lspconfig = require("mason-lspconfig")

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local keymap = vim.keymap -- for conciseness

    -- Custom handler for import diagnostics
    local function show_import_diagnostics(bufnr)
      local params = vim.lsp.util.make_text_document_params()
      vim.lsp.buf_request(bufnr, "textDocument/codeAction", {
        textDocument = params,
        range = {
          start = { line = 0, character = 0 },
          ["end"] = { line = 0, character = 0 },
        },
        context = {
          diagnostics = {},
          only = { "source.addMissingImports.ts" },
        },
      }, function(err, actions)
        if err or not actions then
          return
        end

        local import_paths = {}
        for _, action in ipairs(actions) do
          if action.kind == "source.addMissingImports.ts" then
            for _, edit in ipairs(action.edit.changes or {}) do
              for _, text_edit in ipairs(edit) do
                table.insert(import_paths, text_edit.newText)
              end
            end
          end
        end

        if #import_paths > 0 then
          local ns = vim.api.nvim_create_namespace("import_diagnostics")
          vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

          local lines = { "Missing imports:" }
          for _, path in ipairs(import_paths) do
            table.insert(lines, "• " .. path:gsub("\n", ""))
          end

          vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
            virt_text = { { table.concat(lines, "\n"), "Comment" } },
            virt_text_pos = "right_align",
          })
        end
      end)
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf, silent = true }

        -- set keybinds
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary

        -- Toggle inlay hints
        if vim.lsp.inlay_hint then
          opts.desc = "Toggle Inlay Hints"
          keymap.set("n", "<leader>gL", function()
            local bufnr = ev.buf
            local enabled = vim.lsp.inlay_hint.is_enabled and vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
            vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
          end, opts)
        end

        -- Missing Import
        opts.desc = "Show missing imports"
        keymap.set("n", "<leader>mi", function()
          show_import_diagnostics(ev.buf)
          vim.diagnostic.open_float({ scope = "line" })
        end, opts)
      end,
    })

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    vim.diagnostic.config({
      virtual_text = true, -- shows inline warnings/errors
      signs = true,
      underline = true,
      update_in_insert = true, -- update diagnostics even while typing
    })

    -- Change the Diagnostic symbols in the sign column (gutter)
    -- (not in youtube nvim video)
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    mason_lspconfig.setup_handlers({
      function(server_name)
        local config = {
          capabilities = capabilities,
        }

        -- TypeScript-specific configuration
        if server_name == "tsserver" then
          config.settings = {
            typescript = {
              suggest = {
                autoImports = true,
                includeCompletionsForModuleExports = true,
              },
              preferences = {
                includeCompletionsForImportStatements = true,
                importModuleSpecifierPreference = "shortest",
              },
            },
            javascript = {
              suggest = {
                autoImports = true,
                includeCompletionsForModuleExports = true,
              },
            },
          }
          config.handlers = {
            ["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
              update_in_insert = true,
              severity_sort = true,
            }),
          }
        end

        lspconfig[server_name].setup(config)
      end,
      ["emmet_ls"] = function()
        -- configure emmet language server
        lspconfig["emmet_ls"].setup({
          capabilities = capabilities,
          filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less" },
        })
      end,
      ["lua_ls"] = function()
        -- configure lua server (with special settings)
        lspconfig["lua_ls"].setup({
          capabilities = capabilities,
          settings = {
            Lua = {
              -- make the language server recognize "vim" global
              diagnostics = {
                globals = { "vim" },
              },
              completion = {
                callSnippet = "Replace",
              },
            },
          },
        })
      end,
    })

    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
      callback = function(args)
        if vim.bo[args.buf].filetype == "typescript" or vim.bo[args.buf].filetype == "javascript" then
          show_import_diagnostics(args.buf)
        end
      end,
    })
  end,
}
