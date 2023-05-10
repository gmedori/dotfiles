-- This function and the local variable after it are for bootstrapping packer on a new install. It should run on first vim boot.
local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath("data").."/site/pack/packer/start/packer.nvim"
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({"git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path})
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

return require("packer").startup(function(use)
    use "wbthomason/packer.nvim"
    -- For navigating my project structure in the way that I"m used to with IDEs
    use {
        "nvim-tree/nvim-tree.lua",
        requires = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("nvim-tree").setup()
        end
    }

    -- For a nice status line
    use {
        "nvim-lualine/lualine.nvim",
        requires = { "nvim-tree/nvim-web-devicons", opt = true }
    } 

    -- For making things look pretty and formatted
    use "godlygeek/tabular"

    -- For no more accidental empty files
    use "EinfachToll/DidYouMean"

    -- For changing surrounding characters
    use "tpope/vim-surround"

    -- For a fancy start screen
    use "mhinz/vim-startify"

    -- For da bad wolf
    use "sjl/badwolf"

    -- For better markdown highlighting
    use "plasticboy/vim-markdown"

    -- For Brewfile editing
    use "bfontaine/Brewfile.vim"

    -- For commenting stuff out
    use "tpope/vim-commentary"

    -- For auto-inserting end in Ruby
    use "tpope/vim-endwise"

    -- For Swift syntax highlighting
    use "keith/swift.vim"

    -- For snippets!
    use { "L3MON4D3/LuaSnip", tag = "v1.*" }

    -- For fish syntax highlighting
    use { "khaveesh/vim-fish-syntax", ft = "fish" }

    -- For closing brackets, but only when you hit newline. I using a package that did string quotes too and it was always more annoying than it was worth.
    use "rstacruz/vim-closer"

    -- For git symbols/colors in the gutter
    use {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()
        end
    }

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if packer_bootstrap then
        require("packer").sync()
    end
end)
