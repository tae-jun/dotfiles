# ~/.zshrc — managed by ~/dotfiles (setup-shell.sh)
# Homebrew (macOS)
for _b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$_b" ] && eval "$("$_b" shellenv)" && break; done
export PATH="$HOME/.local/bin:$HOME/.atuin/bin:$HOME/.cargo/bin:$PATH"
PLUG="$HOME/.zsh/plugins"
# 서버에 terminfo 가 없는 TERM(예: xterm-ghostty)이면 입력이 깨지므로 xterm-256color 로 fallback
infocmp "$TERM" >/dev/null 2>&1 || export TERM=xterm-256color

# ls: GNU ls 가 있으면 사용 (macOS 는 coreutils 의 gls). 없으면 BSD ls 로 fallback
if command -v gls >/dev/null; then _LS=gls; elif ls --version >/dev/null 2>&1; then _LS=ls; else _LS=; fi
if [ -n "$_LS" ]; then
  command -v gdircolors >/dev/null && eval "$(gdircolors -b)" || { command -v dircolors >/dev/null && eval "$(dircolors -b)"; }
else
  export CLICOLOR=1
fi

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
[ -n "${HOMEBREW_PREFIX:-}" ] && fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
autoload -Uz compinit && compinit -d ~/.zcompdump
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'  # 대소문자 무시 + 부분매칭
zstyle ':completion:*' menu select                  # 후보 여럿이면 화살표로 고르는 메뉴
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{yellow}[%d]%f'

# ---------- 플러그인 ----------
source "$PLUG/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)       # 히스토리 우선, 없으면 completion 제안
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
bindkey '^ ' autosuggest-accept                      # Ctrl+Space 로 수락 (→ 도 됨)
source "$PLUG/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"  # 마지막에 로드

# ---------- 도구 ----------
command -v fzf     >/dev/null && source <(fzf --zsh)
command -v zoxide  >/dev/null && eval "$(zoxide init zsh)"
export ATUIN_SEARCH_MODE_SHELL_UP_KEY_BINDING=prefix   # ↑ 로 열면 입력한 글자로 *시작하는* 것만
export ATUIN_FILTER_MODE_SHELL_UP_KEY_BINDING=global
command -v atuin   >/dev/null && eval "$(atuin init zsh)"   # ↑ 와 Ctrl+R 둘 다 atuin
command -v starship>/dev/null && eval "$(starship init zsh)"

# ---------- transient prompt: 엔터 치면 이전 프롬프트는 ❯ 한 줄로 축약 ----------
# starship 은 PROMPT 를 init 때 한 번만 세팅하므로 line-finish 에서 바꾸고 precmd 에서 복원
_transient_prompt_finish() { _TP_SAVED=$PROMPT; PROMPT='%F{green}❯%f '; zle .reset-prompt }
_transient_prompt_restore() { [[ -n $_TP_SAVED ]] && PROMPT=$_TP_SAVED }
autoload -Uz add-zle-hook-widget add-zsh-hook
add-zle-hook-widget line-finish _transient_prompt_finish
add-zsh-hook precmd _transient_prompt_restore

# ---------- atuin 잡동사니 ----------
(( $+widgets[atuin-search] )) && bindkey '?' self-insert   # 빈 줄에서 '?' 치면 AI 모드 여는 걸 끔

# ---------- ↑ → atuin (입력한 글자로 시작하는 히스토리만), ↓/Ctrl+P/Ctrl+N → zsh prefix 탐색 ----------
# ↑ 는 atuin init 이 atuin-up-search 로 바인딩함. 검색 모드는 위 ATUIN_*_UP_KEY_BINDING env 로 prefix 고정
autoload -Uz down-line-or-beginning-search up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search   # ↓
bindkey '^[OB' down-line-or-beginning-search
bindkey '^P'   up-line-or-beginning-search     # atuin 안 거치는 prefix 탐색이 필요할 때
bindkey '^N'   down-line-or-beginning-search

# ---------- alias ----------
if [ -n "$_LS" ]; then
  alias l="$_LS -AFlvh --group-directories-first --color=auto"
  alias ll="$_LS -alhF --color=auto"
  alias la="$_LS -A --color=auto"
else  # BSD ls
  alias l='ls -AFlhG'
  alias ll='ls -alhFG'
  alias la='ls -AG'
fi
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# 서버별 로컬 설정
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
