#!/usr/bin/env bash
# zsh + starship + atuin + zoxide + fzf + zsh plugins 셋업 (Ubuntu/Debian, macOS)
# 여러 번 실행해도 안전(idempotent). sudo 없으면 apt 단계는 건너뜀.
#
# 어디서든 한 줄:
#   curl -fsSL https://raw.githubusercontent.com/tae-jun/dotfiles/main/setup-shell.sh | bash
# 로컬에서 원격 서버로:
#   ssh <server> 'curl -fsSL https://raw.githubusercontent.com/tae-jun/dotfiles/main/setup-shell.sh | bash'
# GitHub 접근 안 되는 서버:
#   scp -r ~/dotfiles server:~/ && ssh server '~/dotfiles/setup-shell.sh'
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/tae-jun/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

command -v git >/dev/null || { echo "git 필요: sudo apt-get install -y git"; exit 1; }

# --- self-bootstrap: curl | bash 로 실행되면 설정 파일이 옆에 없으므로 repo 를 clone 하고 거기서 재실행 ---
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-/dev/null}")" 2>/dev/null && pwd || true)"
if [ ! -f "$SRC_DIR/zshrc" ]; then
  if [ -f "$DOTFILES_DIR/zshrc" ]; then
    git -C "$DOTFILES_DIR" pull -q --ff-only || true
  else
    echo "==> $DOTFILES_REPO → $DOTFILES_DIR"
    git clone -q --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  exec bash "$DOTFILES_DIR/setup-shell.sh" "$@"
fi

LOCAL_BIN="$HOME/.local/bin"
PLUG="$HOME/.zsh/plugins"
mkdir -p "$LOCAL_BIN" "$PLUG"
export PATH="$LOCAL_BIN:$PATH"

log(){ printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }

OS=$(uname -s); ARCH=$(uname -m)

if [ "$OS" = Darwin ]; then
  # ---------- macOS: Homebrew ----------
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && eval "$("$b" shellenv)" && break; done
  command -v brew >/dev/null || { echo "Homebrew 필요: https://brew.sh 의 설치 명령 실행 후 다시 시도"; exit 1; }
  log "brew: starship atuin zoxide fzf coreutils"
  brew list --formula starship atuin zoxide fzf coreutils >/dev/null 2>&1 || brew install -q starship atuin zoxide fzf coreutils
else
  # ---------- Linux ----------
  # 1. apt 패키지 (zsh, git, curl)
  if sudo -n true 2>/dev/null && command -v apt-get >/dev/null; then
    log "apt: zsh git curl"
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq zsh git curl >/dev/null
  else
    log "sudo/apt 없음 → 패키지 설치 건너뜀 (zsh 는 별도 설치 필요)"
  fi

  # 2. fzf: apt 버전(0.44)은 'fzf --zsh' 미지원 → 0.48 미만이면 GitHub 릴리즈에서 최신 바이너리
  fzf_ok(){ command -v fzf >/dev/null && [ "$(fzf --version | cut -d. -f2)" -ge 48 ]; }
  if ! fzf_ok; then
    log "fzf: GitHub 릴리즈에서 설치"
    case "$ARCH" in x86_64) fa=amd64;; aarch64|arm64) fa=arm64;; *) echo "지원 안 하는 arch: $ARCH"; exit 1;; esac
    ver=$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest | grep -oE '"tag_name": *"v?[^"]+"' | grep -oE '[0-9][^"]*')
    curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${ver}/fzf-${ver}-linux_${fa}.tar.gz" | tar xz -C "$LOCAL_BIN"
  fi

  # 3. starship / atuin / zoxide (공식 스크립트, ~/.local/bin)
  command -v starship >/dev/null || { log "starship"; curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN" >/dev/null; }
  command -v atuin    >/dev/null || { log "atuin";    curl -fsSL https://setup.atuin.sh | bash -s -- --no-modify-path >/dev/null 2>&1 || curl -fsSL https://setup.atuin.sh | bash; }
  command -v zoxide   >/dev/null || { log "zoxide";   curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir "$LOCAL_BIN" >/dev/null; }
  # atuin 설치 스크립트는 ~/.atuin/bin 에 넣음 → PATH 에 있게 symlink
  [ -x "$HOME/.atuin/bin/atuin" ] && ln -sf "$HOME/.atuin/bin/atuin" "$LOCAL_BIN/atuin"
fi

# 4. zsh 플러그인 (git clone, 플러그인 매니저 없이)
clone(){ [ -d "$PLUG/$2" ] && git -C "$PLUG/$2" pull -q || git clone -q --depth 1 "https://github.com/$1" "$PLUG/$2"; }
log "zsh plugins"
clone zsh-users/zsh-autosuggestions        zsh-autosuggestions
clone Aloxaf/fzf-tab                       fzf-tab
clone zdharma-continuum/fast-syntax-highlighting fast-syntax-highlighting
clone zsh-users/zsh-completions            zsh-completions

# 5. 설정 파일 복사 (기존 .zshrc 는 백업)
log "config"
if [ -f "$HOME/.zshrc" ] && ! cmp -s "$HOME/.zshrc" "$SRC_DIR/zshrc"; then cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"; fi
cp "$SRC_DIR/zshrc" "$HOME/.zshrc"
mkdir -p "$HOME/.config"
cp "$SRC_DIR/starship.toml" "$HOME/.config/starship.toml"

# 6. 기본 셸 변경 (chsh 는 비밀번호 만료 시 PAM 에서 막히므로 sudo 있으면 usermod 사용)
zsh_path=$(command -v zsh || true)
if [ "$OS" = Darwin ]; then
  cur_shell=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
  [ "$cur_shell" = "$zsh_path" ] || { log "login shell → zsh"; chsh -s "$zsh_path" || echo "chsh 실패: 수동으로 'chsh -s $zsh_path'"; }
elif [ -n "$zsh_path" ] && [ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]; then
  log "login shell → zsh"
  if sudo -n true 2>/dev/null; then
    grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    sudo usermod -s "$zsh_path" "$USER"
  else
    chsh -s "$zsh_path" || echo "chsh 실패: 관리자에게 'usermod -s $zsh_path $USER' 요청"
  fi
fi

log "완료. 새 셸 열거나 'exec zsh' 실행. atuin 동기화 쓰려면 'atuin login'."
