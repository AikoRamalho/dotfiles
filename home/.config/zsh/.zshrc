# ─── Powerlevel10k instant prompt ────────────────────────────
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─── plugins ─────────────────────────────────────────────────
# All of these come from home.packages, so flake.lock pins their versions.
# Sourcing by profile instead of by store path keeps hashes out of this file:
# nix-darwin exports NIX_PROFILES from /etc/zshenv.
plugin() {
  local rel=$1 profile
  for profile in ${(z)NIX_PROFILES}; do
    if [[ -r "$profile/share/$rel" ]]; then
      source "$profile/share/$rel"
      return
    fi
  done
  print -u2 "zshrc: plugin not found: $rel"
}

plugin zsh/themes/powerlevel10k/powerlevel9k.zsh-theme

# ─── completion ──────────────────────────────────────────────
# zsh-completions ships its functions under share/zsh/site-functions, which
# /etc/zshenv already adds to fpath for every profile, so it needs no source.
_zcompdir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$_zcompdir"
autoload -Uz compinit
compinit -d "$_zcompdir/zcompdump"

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu no                # fzf-tab draws the menu instead
plugin fzf-tab/fzf-tab.plugin.zsh

# ─── history ─────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt extended_history hist_expire_dups_first hist_ignore_dups \
       hist_ignore_space hist_reduce_blanks hist_verify \
       inc_append_history share_history

plugin zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ─── line editing ────────────────────────────────────────────
bindkey -e
plugin zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh

# ─── mise (version manager) ──────────────────────────────────
eval "$(mise activate zsh)"

# ─── fzf ─────────────────────────────────────────────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --preview "bat --color=always {}"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# ─── atuin (fuzzy history) ───────────────────────────────────
eval "$(atuin init zsh --disable-up-arrow)"

# ─── Modern CLI aliases ──────────────────────────────────────
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --git --group-directories-first'
alias lt='eza --tree --icons --level=2'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
alias top='btm'
alias df='duf'
alias du='dust'
alias ps='procs'
alias g='git'
alias lg='lazygit'
alias k='kubectl'

# ─── Git aliases ─────────────────────────────────────────────
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate --all'

# ─── Python / uv ─────────────────────────────────────────────
alias py='python3'
alias pip='uv pip'
alias venv='uv venv'

# ─── Go ──────────────────────────────────────────────────────
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# ─── PATH extras ─────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ─── Editor ──────────────────────────────────────────────────
export EDITOR="code --wait"

# ─── powerlevel10k config ────────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ─── opencode ────────────────────────────────────────────────
export PATH="$HOME/.opencode/bin:$PATH"

# ─── wezterm ─────────────────────────────────────────────────
export PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"

# ─── syntax highlighting ─────────────────────────────────────
# After every other widget, so it wraps them all.
plugin zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ─── zoxide (smarter cd) ─────────────────────────────────────
# Last: zoxide replaces cd and warns when anything is loaded after it.
eval "$(zoxide init zsh --cmd cd)"
