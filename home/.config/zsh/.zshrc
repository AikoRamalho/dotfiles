# ─── Powerlevel10k instant prompt ────────────────────────────
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─── Oh My Zsh ───────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  gitignore
  brew
  macos
  docker
  kubectl
  golang
  python
  npm
  node
  mise
  direnv
  fzf-tab
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  zsh-history-substring-search
)

source "$ZSH/oh-my-zsh.sh"

# ─── mise (version manager) ──────────────────────────────────
eval "$(mise activate zsh)"

# ─── zoxide (smarter cd) ─────────────────────────────────────
eval "$(zoxide init zsh --cmd cd)"

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

# ─── direnv ──────────────────────────────────────────────────
eval "$(direnv hook zsh)"

# ─── powerlevel10k config ────────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ─── opencode ────────────────────────────────────────────────
export PATH="$HOME/.opencode/bin:$PATH"

# ─── wezterm ─────────────────────────────────────────────────
export PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"
