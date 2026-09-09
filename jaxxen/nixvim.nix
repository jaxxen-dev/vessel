_:
{
  colorschemes.catppuccin = {
    enable = true;
    settings = {
      flavour = "mocha";
      transparent_background = true;
    };
  };
  opts = {
    comments = "sO:*\\ -,mO:*\\ \\ ,exO:*/,s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-";
    cursorline = true;
    expandtab = true;
    formatoptions = "jcroql";
    number = true;
    relativenumber = true;
    shiftwidth = 2;
    signcolumn = "yes";
    smartindent = true;
    softtabstop = 2;
    tabstop = 2;
  };
  keymaps = [{
    action = ":%y+<CR>";
    mode = "n";
    key = "<A-c>";
    options = {
      desc = "Copy entire buffer to system clipboard";
      silent = true;
    };
  }];
  plugins = {
    cmp = {
      enable = true;
      settings = {
        sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
        mapping = {
          "<Tab>" = ''
            cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.confirm({ select = true })
              else
                fallback()
              end
            end, {"i", "s"})
          '';
          "<S-Tab>" = "cmp.mapping.select_prev_item()";
          "<CR>" = "cmp.mapping.confirm({ select = false })";
        };
      };
    };
    indent-blankline.enable = true;
    lsp = {
      enable = true;
      servers = {
        cssls.enable = true;
        eslint.enable = true;
        html.enable = true;
        jsonls.enable = true;
        markdown_oxide.enable = true;
        nixd.enable = true;
        pyright.enable = true;
        tofu_ls.enable = true;
        yamlls.enable = true;
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
        };
        ts_ls.enable = true;
      };
    };
    lualine.enable = true;
    treesitter = {
      enable = true;
      nixGrammars = true;
      settings = {
        highlight.enable = true;
        incremental_selection.enable = true;
        indent.enable = false;
      };
    };
  };
}
