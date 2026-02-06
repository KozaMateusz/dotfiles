-- Editor
lvim.colorscheme = 'onedarker'
vim.opt.relativenumber = true
vim.opt.colorcolumn = "80"
-- Linux kernel coding style indentation
vim.opt.expandtab     = false   -- never convert tabs to spaces
vim.opt.shiftwidth    = 8       -- indent size
vim.opt.tabstop       = 8       -- a hard tab is 8 columns
vim.opt.softtabstop   = 8
vim.opt.smartindent   = true
vim.opt.cindent       = true
vim.opt.cinoptions    = "L0,(0,W4"
vim.opt.list          = true
vim.opt.listchars     = { tab = "▸ " }

-- Plugins
lvim.plugins = {
  {
    "github/copilot.vim",
    init = function()
      vim.g.copilot_no_tab_map = true
    end,
    config = function()
      vim.keymap.set(
        "i",
        "<C-a>",
        [[copilot#Accept("\<CR>")]],
        {
          silent = true,
          expr = true,
          script = true,
          replace_keycodes = false,
        }
      )
    end,
  },

  {
    "lambdalisue/suda.vim",
    init = function()
      vim.g.suda_smart_edit = 1
    end,
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.list_extend(
        lvim.lsp.automatic_configuration.skipped_servers,
        { "devicetree_ls" }
      )

      local lspconfig = require("lspconfig")
      local configs = require("lspconfig.configs")
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      capabilities.textDocument = capabilities.textDocument or {}
      capabilities.textDocument.semanticTokens = {
        dynamicRegistration = false,
        requests = {
	  range = false,
	  full = true,
        },
         tokenTypes = {
	  "namespace", "class", "enum", "interface", "struct", "typeParameter", "type",
	  "parameter", "variable", "property", "enumMember", "decorator", "event", "function",
	  "method", "macro", "label", "comment", "string", "keyword", "number", "regexp", "operator",
        },
        tokenModifiers = {
	  "declaration", "definition", "readonly", "static", "deprecated", "abstract",
	  "async", "modification", "documentation", "defaultLibrary",
        },
        formats = {'relative'}
      }

      -- Enable formatting
      capabilities.textDocument.formatting = {
        dynamicRegistration = false
      }

      -- Enable folding range support
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }

      if not configs.devicetree_ls then
        configs.devicetree_ls = {
          default_config = {
            cmd = { "devicetree-language-server", "--stdio" },
            filetypes = { "dts", "dtsi" },
            root_dir = lspconfig.util.root_pattern(".git", "Makefile", "Kconfig"),
            capabilities = capabilities,
            settings = {
              cwd = "${workspaceFolder}",
              devicetree = {
                defaultIncludePaths = {
			"include",
                },
                defaultBindingType = "DevicetreeOrg",
		defaultDeviceOrgBindingsMetaSchema = {},
		defaultDeviceOrgTreeBindings = {
			"Documentation/devicetree/bindings",
		},
                autoChangeContext = true,
                allowAdhocContexts = true,
		contexts = {},
              },
            },
          },
        }
      end

      lspconfig.devicetree_ls.setup({
        capabilities = capabilities,
      })

      vim.notify(
        "Custom devicetree_ls LSP loaded with semantic tokens & folding"
      )
    end,
  },
}

-- Fix multiple offset_encoding not supported yet
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "clangd" })
local capabilities = require("lvim.lsp").common_capabilities()
capabilities.offsetEncoding = { "utf-16" }
local opts = { capabilities = capabilities }
require("lvim.lsp.manager").setup("clangd", opts)
