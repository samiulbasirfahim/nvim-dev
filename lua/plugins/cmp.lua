---@type LazyPluginSpec
return {
	"hrsh7th/nvim-cmp",
	event = { "InsertEnter", "CmdlineEnter" },
	dependencies = {
		"hrsh7th/cmp-buffer", -- source for text in buffer
		"hrsh7th/cmp-path", -- source for file system paths
		"hrsh7th/cmp-nvim-lsp", -- source for lsp
		"onsails/lspkind.nvim",
		{
			"chrisgrieser/nvim-scissors",
			dependencies = "nvim-telescope/telescope.nvim",
			opts = {
				snippetDir = vim.fn.stdpath("data") .. "/lazy/friendly-snippets/snippets",
			},
			config = function()
				vim.keymap.set("n", "<leader>se", function()
					require("scissors").editSnippet()
				end)

				-- When used in visual mode prefills the selection as body.
				vim.keymap.set({ "n", "x" }, "<leader>sa", function()
					require("scissors").addNewSnippet()
				end)
			end,
		},
		{
			"L3MON4D3/LuaSnip",
			event = { "InsertEnter", "CmdlineEnter" },
			version = "v2.*",
			build = "make install_jsregexp",
			dependencies = {
				"saadparwaiz1/cmp_luasnip",
				"rafamadriz/friendly-snippets",
			},
			config = function()
				local luasnip = require("luasnip")
				luasnip.config.set_config({
					history = true,
					updateevents = "TextChanged,TextChangedI",
				})

				require("luasnip.loaders.from_vscode").lazy_load()
				require("luasnip.loaders.from_vscode").lazy_load({ paths = "~/.config/nvim/snippets" })
				vim.api.nvim_create_autocmd("InsertLeave", {
					callback = function()
						if
							require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
							and not require("luasnip").session.jump_active
						then
							require("luasnip").unlink_current()
						end
					end,
				})
			end,
		},
		{
			"windwp/nvim-autopairs",
			event = "InsertEnter",
			opts = {
				fast_wrap = {},
				disable_filetype = { "TelescopePrompt", "vim" },
			},
			config = function(_, opts)
				require("nvim-autopairs").setup(opts)
				local cmp_autopairs = require("nvim-autopairs.completion.cmp")
				require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
			end,
		},
	},
	config = function()
		local cmp = require("cmp")
		local lspkind = require("lspkind")
		local luasnip = require("luasnip")

		cmp.setup({
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
			}, {
				{ name = "path" },
				{ name = "buffer" },
			}),

			mapping = cmp.mapping.preset.insert({
				["<C-p>"] = cmp.mapping.select_prev_item(),
				["<C-n>"] = cmp.mapping.select_next_item(),
				["<C-k>"] = cmp.mapping.select_prev_item(),
				["<C-j>"] = cmp.mapping.select_next_item(),
				["<C-d>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.close(),
				["<CR>"] = cmp.mapping.confirm({
					behavior = cmp.ConfirmBehavior.Insert,
					select = true,
				}),
				["<Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.confirm({ select = true })
					elseif luasnip.expand_or_jumpable() then
						luasnip.expand_or_jump()
					else
						fallback()
					end
				end, { "i", "s" }),

				["<S-Tab>"] = cmp.mapping(function(fallback)
					if luasnip.jumpable(-1) then
						luasnip.jump(-1)
					elseif cmp.visible() then
						cmp.confirm({ select = true })
					else
						fallback()
					end
				end, { "i", "s" }),
			}),

			experimental = {
				ghost_text = true,
			},

			formatting = {
				fields = { "abbr", "menu", "kind" },
				format = function(entry, item)
					local short_name = {
						cmdline = "cmd",
						nvim_lsp = "lsp",
						nvim_lsp_signature_help = "sig",
						nvim_lua = "nvim",
						luasnip = "snip",
						buffer = "buff",
						path = "path",
					}

					local menu_name = short_name[entry.source.name] or entry.source.name
					local icon, hl = require("mini.icons").get("lsp", item.kind)

					local kind = lspkind.cmp_format({
						mode = "symbol",
						maxwidth = 30,
					})(entry, item)

					kind.menu = string.format("[%s]", menu_name)
					kind.kind = icon
					kind.kind_hl_group = hl

					return kind
				end,
			},
			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
			},
		})
	end,
}
