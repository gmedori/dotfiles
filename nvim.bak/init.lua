-- ██████  ██      ██    ██  ██████  ██ ███    ██ ███████
-- ██   ██ ██      ██    ██ ██       ██ ████   ██ ██
-- ██████  ██      ██    ██ ██   ███ ██ ██ ██  ██ ███████
-- ██      ██      ██    ██ ██    ██ ██ ██  ██ ██      ██
-- ██      ███████  ██████   ██████  ██ ██   ████ ███████


local plugin_spec = {


	----------------------------
	-- EDITING PLUGINS
	----------------------------


	-- For making things look pretty and formatted
	{ "godlygeek/tabular", lazy = true },

	-- For changing surrounding characters
	{ "tpope/vim-surround", lazy = true },

	-- For closing brackets, but only when you hit newline.
	{ "rstacruz/vim-closer", lazy = false },

	-- For commenting stuff out
	{ "tpope/vim-commentary", lazy = false },

	-- For auto-inserting end in Ruby
	{ "tpope/vim-endwise", lazy = true },


	----------------------------
	-- NAVIGATION PLUGINS
	----------------------------


	-- For navigating my project structure in the way that I"m used to with IDEs
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		opts = {
			filesystem = {
				filtered_items = {
					visible = true
				},
				hijack_netrw_behavior = "open_current"
			},
			window = {
				mappings = {
					["z"] = ""
				}
			}
		}
	},

	{
		"nvim-telescope/telescope-file-browser.nvim",
		dependencies = { 
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim" 
		}
	},

	-- For finding files quickly
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			-- Helper lib for telescope
			{ "nvim-lua/plenary.nvim" },
			-- Faster sorting
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			-- Ability to pass ripgrep arguments to the live_grep picker
			{ "nvim-telescope/telescope-live-grep-args.nvim" , version = "^1.0.0" },
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			local live_grep_args_actions = require("telescope-live-grep-args.actions")
			local builtin = require("telescope.builtin")

			telescope.setup {
				extensions = {
					live_grep_args = {
						auto_quoting = true,
						mappings = {
							i = {
								["<C-q>"] = live_grep_args_actions.quote_prompt(),
								["<C-f>"] = live_grep_args_actions.to_fuzzy_refine,
								["<CR>"] = function()
									actions.select_default()
									actions.center()
								end,
							}
						}
					}
				}
			}

			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files by name" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Search help tags" })
			vim.keymap.set("n", "<leader>fg", ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", {desc = "Search workspace with ripgrep" })
			vim.keymap.set("n", "<leader>fu", builtin.lsp_references, { desc = "Find usages" })

			telescope.load_extension("fzf")
			telescope.load_extension("live_grep_args")
			telescope.load_extension("file_browser")
		end
	},


	----------------------------
	-- STYLE PLUGINS
	----------------------------


	-- My primary colorscheme. Has been for a long time.
	-- I finally forked it so that I could tweak how it looks in Rust.
	{
		"gposcidonio/badwolf",
		lazy = false ,
		config = function()
			vim.cmd("colorscheme badwolf")
		end
	},

	-- For a nice status line
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", opt = true },
		config = function()
			require("lualine").setup {
				options = {
					theme = "ayu_mirage"
				}
			}
		end,
	},


	----------------------------
	-- QOL PLUGINS
	----------------------------


	-- For a fancy start screen
	{
		"mhinz/vim-startify",
		lazy = false
	},

	-- For no more accidental empty files
	{
		"EinfachToll/DidYouMean",
		lazy = true
	},

	-- What key does that thing again?
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			-- TODO
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	},

	-- Lots of little utilities
	{ 'echasnovski/mini.nvim', version = '*' },


	----------------------------
	-- SYNTAX PLUGINS
	----------------------------


	{ "keith/swift.vim", lazy = true },
	{ "bfontaine/Brewfile.vim", lazy = true },
	{ "khaveesh/vim-fish-syntax", lazy = true },


	----------------------------
	-- LSP PLUGINS
	----------------------------

	{ "folke/neoconf.nvim" },

	-- The default LSP configs everyone uses
	{ "neovim/nvim-lspconfig" },

	-- For viewing LSP progress
	{
		"j-hui/fidget.nvim",
		config = function()
			require("fidget").setup()
		end
	},

	{
		"hrsh7th/nvim-cmp",
		version = false,
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-buffer",
		},
		config = function()
			local cmp = require('cmp')
			local opts = {
				-- Where to get completion results from
				sources = cmp.config.sources {
					{ name = "nvim_lsp" },
					{ name = "buffer"},
					{ name = "path" },
				},
				-- Make 'enter' key select the completion
				mapping = cmp.mapping.preset.insert({
					["<CR>"] = cmp.mapping.confirm({ select = true })
				}),
			}
			cmp.setup(opts)
		end,
	},
}


-- ██       █████  ███████ ██    ██    ███    ██ ██    ██ ██ ███    ███
-- ██      ██   ██    ███   ██  ██     ████   ██ ██    ██ ██ ████  ████
-- ██      ███████   ███     ████      ██ ██  ██ ██    ██ ██ ██ ████ ██
-- ██      ██   ██  ███       ██       ██  ██ ██  ██  ██  ██ ██  ██  ██
-- ███████ ██   ██ ███████    ██    ██ ██   ████   ████   ██ ██      ██
-- lazy.nvim

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = ","
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
	spec = plugin_spec,
	-- Configure any other settings here. See the documentation for more details.
	-- colorscheme that will be used when installing plugins.
	install = { colorscheme = { "habamax" } },
	-- automatically check for plugin updates
	checker = { enabled = true },
})


-- ███    ███  █████  ██████  ██████  ██ ███    ██  ██████  ███████
-- ████  ████ ██   ██ ██   ██ ██   ██ ██ ████   ██ ██       ██
-- ██ ████ ██ ███████ ██████  ██████  ██ ██ ██  ██ ██   ███ ███████
-- ██  ██  ██ ██   ██ ██      ██      ██ ██  ██ ██ ██    ██      ██
-- ██      ██ ██   ██ ██      ██      ██ ██   ████  ██████  ███████
-- mappings

-- Unmap the arrow keys
vim.keymap.set("n"  , "<down>"  , "ddp")
vim.keymap.set("n"  , "<left>"  , "<Nop>")
vim.keymap.set("n"  , "<right>" , "<Nop>")
vim.keymap.set("n"  , "<up>"    , "ddkP")
vim.keymap.set("i" , "<down>"  , "<Nop>")
vim.keymap.set("i" , "<left>"  , "<Nop>")
vim.keymap.set("i" , "<right>" , "<Nop>")
vim.keymap.set("i" , "<up>"    , "<Nop>")
vim.keymap.set("v" , "<down>"  , "<Nop>")
vim.keymap.set("v" , "<left>"  , "<Nop>")
vim.keymap.set("v" , "<right>" , "<Nop>")
vim.keymap.set("v" , "<up>"    , "<Nop>")

-- Default to very magic
vim.keymap.set("n", "/", "/\\v")

-- Auto-center movement commands
vim.keymap.set("n", "G", "Gzz")
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "}", "}zz")
vim.keymap.set("n", "{", "{zz")

-- Search and replace under text
vim.keymap.set("n", "<Leader>s", ":%s/\\<<C-r><C-w>\\>/")

-- Open and close sidebar
vim.keymap.set("n", "<Leader>>", ":Neotree focus left<CR>")
vim.keymap.set("n", "<Leader><", ":Neotree close<CR>")

-- LSP Keymaps
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "<leader>dd", vim.diagnostic.setqflist, { desc = "Open diagnostics in quickfix window" })


-- ███████ ███████ ████████ ████████ ██ ███    ██  ██████  ███████
-- ██      ██         ██       ██    ██ ████   ██ ██       ██
-- ███████ █████      ██       ██    ██ ██ ██  ██ ██   ███ ███████
--      ██ ██         ██       ██    ██ ██  ██ ██ ██    ██      ██
-- ███████ ███████    ██       ██    ██ ██   ████  ██████  ███████
-- settings

-- Vim needs a more POSIX compatible shell than fish for certain functionality to work, such as :%!,
-- compressed help pages and many third-party plugins.

vim.cmd("if &shell =~# 'fish$' | set shell=sh | endif")

-- Enables mouse in vim
vim.o.mouse = "a"

-- Makes cursor line visible
vim.o.cursorline = true

-- Allows fancy menu which you can tab thru when executing commands
vim.o.wildmenu = true

-- Enable syntax... duh
vim.cmd("syntax enable")
vim.cmd("filetype plugin indent on")

-- Remove the col limit on searching for syntax errors
vim.o.synmaxcol = 0

-- Modify messages that are displayed. Hit up the help files for this one.
vim.o.shortmess = "aAIsT"

-- Let's see dem relative line numbers
vim.o.relativenumber = true
vim.o.number = true

-- Visualize whitespace
vim.o.list = true
vim.o.listchars="tab:› ,trail:·,extends:>,precedes:<"

-- TAB MADNESS
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = false

-- New splits should be created to the right and down.
vim.o.splitbelow = true
vim.o.splitright = true

-- Make sure that we're always using utf8 encoding
vim.o.encoding = "utf-8"

-- Recursive search for files
vim.o.path = vim.o.path .. "**"

-- See commands as you're inputting them
vim.o.showcmd = true

-- Wider text width, 0 is no limit
vim.o.textwidth = 0

-- Use ripgrep for grep
vim.o.grepprg = "rg --vimgrep --no-heading --smart-case"

-- Folding is stupid.
vim.o.foldenable = false


-- ██      ███████ ██████         ██
-- ██      ██      ██   ██        ██
-- ██      ███████ ██████      ████████
-- ██           ██ ██          ██  ██
-- ███████ ███████ ██          ██████
--
--
--  ██████  ██████  ███    ███ ██████  ██      ███████ ████████ ██  ██████  ███    ██
-- ██      ██    ██ ████  ████ ██   ██ ██      ██         ██    ██ ██    ██ ████   ██
-- ██      ██    ██ ██ ████ ██ ██████  ██      █████      ██    ██ ██    ██ ██ ██  ██
-- ██      ██    ██ ██  ██  ██ ██      ██      ██         ██    ██ ██    ██ ██  ██ ██
--  ██████  ██████  ██      ██ ██      ███████ ███████    ██    ██  ██████  ██   ████
--  lsp & completion


-- Swift lspconfig setup

vim.lsp.config('sourcekit', {
	    capabilities = {
        workspace = {
            didChangeWatchedFiles = {
                dynamicRegistration = true,
            },
        },
    },
})
vim.api.nvim_create_autocmd('LspAttach', {
	desc = 'LSP Actions',
	callback = function(args)
		vim.keymap.set('n', 'K', vim.lsp.buf.hover, {noremap = true, silent = true})
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {noremap = true, silent = true})
	end,
})


-- ███    ███ ██ ███    ██ ██    ███    ██ ██    ██ ██ ███    ███
-- ████  ████ ██ ████   ██ ██    ████   ██ ██    ██ ██ ████  ████
-- ██ ████ ██ ██ ██ ██  ██ ██    ██ ██  ██ ██    ██ ██ ██ ████ ██
-- ██  ██  ██ ██ ██  ██ ██ ██    ██  ██ ██  ██  ██  ██ ██  ██  ██
-- ██      ██ ██ ██   ████ ██ ██ ██   ████   ████   ██ ██      ██
-- mini.nvim

