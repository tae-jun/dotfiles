# ~/.zshrc — managed by ~/dotfiles (setup-shell.sh)
export PATH="$HOME/.local/bin:$HOME/.atuin/bin:$HOME/.cargo/bin:$PATH"
PLUG="$HOME/.zsh/plugins"

# ---------- history ----------
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS INC_APPEND_HISTORY

# ---------- 기본 옵션 ----------
setopt AUTO_CD INTERACTIVE_COMMENTS NO_BEEP
bindkey -e                                  # emacs 키바인딩 (Ctrl+A/E 등)
bindkey '^[[1;5C' forward-word              # Ctrl+→
bindkey '^[[1;5D' backward-word             # Ctrl+←
bindkey '^[[3~'   delete-char               # Delete
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line

# ---------- 완성 (completion) ----------
fpath=("$PLUG/zsh-completions/src" $fpath)
autoload -Uz compinit && compinit -d ~/.zcompdump
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'  # 대소문자 무시 + 부분매칭
zstyle ':completion:*' menu no                      # fzf-tab 이 메뉴 담당
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'
source "$PLUG/fzf-tab/fzf-tab.plugin.zsh"

# ---------- 플러그인 ----------
source "$PLUG/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)       # 히스토리 우선, 없으면 completion 제안
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
bindkey '^ ' autosuggest-accept                      # Ctrl+Space 로 수락 (→ 도 됨)
source "$PLUG/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"  # 마지막에 로드

# ---------- 도구 ----------
command -v fzf     >/dev/null && source <(fzf --zsh)
command -v zoxide  >/dev/null && eval "$(zoxide init zsh)"
command -v atuin   >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"   # Ctrl+R 만 atuin, ↑ 는 zsh 기본
command -v starship>/dev/null && eval "$(starship init zsh)"

# ---------- ↑/↓: 입력한 prefix 로 시작하는 히스토리만 탐색 ----------
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search     # ↑
bindkey '^[OA' up-line-or-beginning-search     # ↑ (application mode)
bindkey '^[[B' down-line-or-beginning-search   # ↓
bindkey '^[OB' down-line-or-beginning-search
bindkey '^P'   up-line-or-beginning-search
bindkey '^N'   down-line-or-beginning-search

# ---------- alias ----------
alias l='ls -AFlvh --group-directories-first --color=auto'
alias ll='ls -alhF --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# 서버별 로컬 설정
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
