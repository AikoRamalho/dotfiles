{ config, lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    defaultKeymap = "viins";

    autosuggestion.enable = true; # ghost text from history
    syntaxHighlighting.enable = true; # commands turn green when valid
    historySubstringSearch.enable = true; # up/down filter history by prefix

    completionInit = ''
      autoload -Uz compinit
      mkdir -p "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
      compinit -d "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case-insensitive
      zstyle ':completion:*' menu no                              # fzf-tab draws the menu
    '';

    history = {
      size = 50000;
      save = 50000;
      extended = true;
      expireDuplicatesFirst = true;
      path = "${config.home.homeDirectory}/.zsh_history";
    };
    setOptions = [
      "HIST_REDUCE_BLANKS"
      "HIST_VERIFY"
    ];

    shellAliases = {
      # Modern CLI replacements
      ls = "eza --icons --group-directories-first";
      ll = "eza -la --icons --git --group-directories-first";
      lt = "eza --tree --icons --level=2";
      cat = "bat --paging=never";
      grep = "rg";
      find = "fd";
      top = "btm";
      df = "duf";
      du = "dust";
      ps = "procs";

      # Git
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gpl = "git pull";
      gco = "git checkout";
      gd = "git diff";
      gl = "git log --oneline --graph --decorate --all";
      add = "git add .";
      m = "git switch main";
      lg = "lazygit";

      # Kubernetes
      k = "kubectl";

      # Python / uv
      py = "python3";
      pip = "uv pip";
      venv = "uv venv";

      ".." = "cd ..";
    };

    initContent = lib.mkMerge [
      # fzf-tab replaces the completion menu; it must load after compinit and
      # before plugins that wrap widgets, such as the autosuggestions.
      (lib.mkOrder 600 ''
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      '')

      (lib.mkOrder 1100 ''
        bindkey '^f' autosuggest-accept

        # kubectl comes from mise, which only puts it on PATH at the first
        # prompt, so its completion is loaded on first use instead of here.
        _kubectl_lazy() {
          unfunction _kubectl_lazy
          source <(kubectl completion zsh)
          _kubectl "$@"
        }
        compdef _kubectl_lazy kubectl k

        # Directories for binaries installed outside the declared layers. They
        # go after PATH on purpose: what nixpkgs and mise provide must win over
        # a stray copy installed by hand.
        path+=(
          "$HOME/go/bin"
          "$HOME/.local/bin"
          "$HOME/.cargo/bin"
          "$HOME/.opencode/bin"
          /Applications/WezTerm.app/Contents/MacOS
        )
      '')

      # zoxide replaces cd and warns unless its hook is the last one
      # registered, so it goes after every other integration.
      (lib.mkOrder 1500 ''
        eval "$(${lib.getExe pkgs.zoxide} init zsh --cmd cd)"
      '')
    ];
  };

  # The prompt. Declared here rather than as a starship.toml in the tree, for
  # the same reason as the shell: the layout is configuration, not a file to
  # hand-edit. Right-side modules only render when they have something to say,
  # so the common case is just the path and the branch.
  programs.starship = {
    enable = true;
    settings = {
      format = "$directory$git_branch$git_status$line_break$character";
      right_format = "$status$cmd_duration$jobs$kubernetes$terraform$aws\${custom.azure}$python$nix_shell";

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold green)";
      };

      directory = {
        truncation_length = 4;
        truncate_to_repo = true;
        style = "bold blue";
        read_only = " 󰌾";
      };

      git_branch = {
        symbol = " ";
        style = "bold purple";
      };

      git_status = {
        style = "bold yellow";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
      };

      status = {
        disabled = false;
        symbol = "✘ ";
        style = "bold red";
      };

      cmd_duration = {
        min_time = 2000;
        format = "[$duration]($style) ";
        style = "yellow";
      };

      jobs.symbol = "󰜎 ";

      kubernetes = {
        disabled = false;
        symbol = "󱃾 ";
        format = "[$symbol$context( \\($namespace\\))]($style) ";
        style = "cyan";
        # Only in a directory that looks like it deploys something. Without
        # this the context follows you into every shell, which is how you stop
        # reading it.
        detect_files = [
          "k8s"
          "kubectl"
          "Chart.yaml"
          "helmfile.yaml"
          "Dockerfile"
          "docker-compose.yml"
        ];
        detect_folders = [
          "k8s"
          "kubernetes"
          "charts"
          ".kube"
        ];
        detect_extensions = [
          "k8s.yaml"
          "k8s.yml"
        ];
      };

      terraform = {
        symbol = "󱁢 ";
        format = "[$symbol$workspace]($style) ";
      };

      aws = {
        symbol = "󰸏 ";
        format = "[$symbol$profile( \\($region\\))]($style) ";
      };

      # The native azure module stays off, which is its default: print-config
      # shows it takes only format, symbol, style and subscription_aliases, so
      # it would render anywhere an Azure login exists. The custom module below
      # does take detect_*, and stands in for it.
      custom.azure = {
        disabled = false;
        symbol = "󰠅 ";
        command = "${lib.getExe pkgs.jq} -r '.subscriptions[] | select(.isDefault) | .name' \"$HOME/.azure/azureProfile.json\"";
        detect_files = [
          "azure-pipelines.yml"
          "azure-pipelines.yaml"
          "azure.yaml"
        ];
        detect_folders = [ ".azure" ];
        style = "blue bold";
        format = "on [$symbol($output)]($style) ";
      };

      python = {
        symbol = " ";
        format = "[$symbol$virtualenv]($style) ";
      };

      nix_shell = {
        symbol = "󱄅 ";
        format = "[$symbol$state]($style) ";
      };
    };
  };

  programs.fzf = {
    enable = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
    fileWidgetCommand = config.programs.fzf.defaultCommand;
    fileWidgetOptions = [ "--preview 'bat --color=always {}'" ];
  };

  programs.atuin = {
    enable = true;
    flags = [ "--disable-up-arrow" ];
  };

  programs.mise.enable = true;

  programs.zoxide = {
    enable = true;
    # The hook is added by hand above, at the end of the file.
    enableZshIntegration = false;
  };
}
