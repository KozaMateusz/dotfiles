return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    -- Don't let Mason try to handle this custom server
    opts.servers.devicetree_ls = nil

    local lspconfig = require("lspconfig")
    local configs = require("lspconfig.configs")
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    -- Enable semantic tokens
    capabilities.textDocument = capabilities.textDocument or {}
    capabilities.textDocument.semanticTokens = {
      dynamicRegistration = false,
      requests = {
        range = false,
        full = true,
      },
      tokenTypes = {
        "namespace",
        "class",
        "enum",
        "interface",
        "struct",
        "typeParameter",
        "type",
        "parameter",
        "variable",
        "property",
        "enumMember",
        "decorator",
        "event",
        "function",
        "method",
        "macro",
        "label",
        "comment",
        "string",
        "keyword",
        "number",
        "regexp",
        "operator",
      },
      tokenModifiers = {
        "declaration",
        "definition",
        "readonly",
        "static",
        "deprecated",
        "abstract",
        "async",
        "modification",
        "documentation",
        "defaultLibrary",
      },
      formats = { "relative" },
    }

    -- Enable formatting
    capabilities.textDocument.formatting = {
      dynamicRegistration = false,
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

    -- Setup the LSP
    lspconfig.devicetree_ls.setup({
      capabilities = capabilities,
    })
  end,
}
