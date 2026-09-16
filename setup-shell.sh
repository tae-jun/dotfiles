#!/usr/bin/env bash
# zsh + starship + atuin + zoxide + fzf + gh + zsh plugins 셋업 (Ubuntu/Debian, macOS)
# 여러 번 실행해도 안전. 홈에 남기는 것: ~/.zshrc ~/.config/starship.toml ~/.zsh/plugins ~/.local/bin/* 뿐.
#
#   curl -fsSL https://raw.githubusercontent.com/tae-jun/dotfiles/main/setup-shell.sh | bash && exec zsh
#
set -euo pipefail

RAW="${DOTFILES_RAW:-https://raw.githubusercontent.com/tae-jun/dotfiles/main}"
LOCAL_BIN="$HOME/.local/bin"
PLUG="$HOME/.zsh/plugins"
OS=$(uname -s); ARCH=$(uname -m)
mkdir -p "$LOCAL_BIN" "$PLUG" "$HOME/.config"
export PATH="$LOCAL_BIN:$PATH"

log(){ printf '\033[1;32m==> %s\033[0m\n' "$*"; }
have(){ command -v "$1" >/dev/null 2>&1; }

# 설정 파일: 스크립트 옆에 있으면 그걸 쓰고(scp 로 복사한 경우), 없으면 GitHub 에서 직접 받음
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-/dev/null}")" 2>/dev/null && pwd || true)"
fetch_cfg(){ if [ -f "$SRC_DIR/$1" ]; then cat "$SRC_DIR/$1"; else curl -fsSL "$RAW/$1"; fi; }

# GitHub 릴리즈 최신 태그 (API 호출 없이 redirect 로)
latest_tag(){ curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's|.*/tag/v\{0,1\}||'; }
# tarball 에서 바이너리 하나만 꺼내 ~/.local/bin 에 설치
install_bin(){ # name url
  local tmp; tmp=$(mktemp -d)
  curl -fsSL "$2" | tar xz -C "$tmp"
  find "$tmp" -type f -name "$1" -perm -u+x | head -1 | xargs -I{} install -m755 {} "$LOCAL_BIN/$1"
  rm -rf "$tmp"
}

if [ "$OS" = Darwin ]; then
  # ---------- macOS: Homebrew ----------
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && eval "$("$b" shellenv)" && break; done
  have brew || { echo "Homebrew 필요: https://brew.sh 의 설치 명령 실행 후 다시 시도"; exit 1; }
  log "brew: starship atuin zoxide fzf gh coreutils"
  brew list --formula starship atuin zoxide fzf gh coreutils >/dev/null 2>&1 || brew install -q starship atuin zoxide fzf gh coreutils
else
  # ---------- Linux ----------
  if ! have zsh || ! have git || ! have curl; then
    if sudo -n true 2>/dev/null && have apt-get; then
      log "apt: zsh git curl"
      sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq zsh git curl >/dev/null
    else
      echo "zsh/git/curl 필요한데 sudo 가 없음. 관리자에게 설치 요청"; exit 1
    fi
  fi
  case "$ARCH" in
    x86_64)        rust=x86_64;  go=amd64;;
    aarch64|arm64) rust=aarch64; go=arm64;;
    *) echo "지원 안 하는 arch: $ARCH"; exit 1;;
  esac
  # 옛 버전이 atuin 공식 설치기로 깔아둔 것(~/.atuin + symlink) 은 걷어내고 tarball 로 다시
  [ -L "$LOCAL_BIN/atuin" ] && rm -f "$LOCAL_BIN/atuin"; rm -rf "$HOME/.atuin"
  # 전부 GitHub 릴리즈 tarball → ~/.local/bin 에 바이너리만. 설치 스크립트가 rc 파일 건드리는 일 없음
  fzf_ok(){ have fzf && [ "$(fzf --version | cut -d. -f2)" -ge 48 ]; }
  fzf_ok        || { log fzf;      v=$(latest_tag junegunn/fzf);      install_bin fzf      "https://github.com/junegunn/fzf/releases/download/v$v/fzf-$v-linux_$go.tar.gz"; }
  have starship || { log starship;                                    install_bin starship "https://github.com/starship/starship/releases/latest/download/starship-$rust-unknown-linux-musl.tar.gz"; }
  have atuin    || { log atuin;                                       install_bin atuin    "https://github.com/atuinsh/atuin/releases/latest/download/atuin-$rust-unknown-linux-gnu.tar.gz"; }
  have zoxide   || { log zoxide;   v=$(latest_tag ajeetdsouza/zoxide); install_bin zoxide   "https://github.com/ajeetdsouza/zoxide/releases/download/v$v/zoxide-$v-$rust-unknown-linux-musl.tar.gz"; }
  have gh       || { log gh;       v=$(latest_tag cli/cli);            install_bin gh       "https://github.com/cli/cli/releases/download/v$v/gh_${v}_linux_$go.tar.gz"; }
fi

# ---------- zsh 플러그인 ----------
log "zsh plugins"
clone(){ if [ -d "$PLUG/$2/.git" ]; then git -C "$PLUG/$2" pull -q --ff-only || true; else git clone -q --depth 1 "https://github.com/$1" "$PLUG/$2"; fi; }
clone zsh-users/zsh-autosuggestions              zsh-autosuggestions
clone Aloxaf/fzf-tab                             fzf-tab
clone zdharma-continuum/fast-syntax-highlighting fast-syntax-highlighting
clone zsh-users/zsh-completions                  zsh-completions

# ---------- 설정 파일 ----------
log "config"
if [ -f "$HOME/.zshrc" ] && ! head -1 "$HOME/.zshrc" | grep -q "managed by"; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.bak" && echo "기존 .zshrc → ~/.zshrc.bak (직접 쓴 파일이라 보존)"
fi
fetch_cfg zshrc         > "$HOME/.zshrc"
fetch_cfg starship.toml > "$HOME/.config/starship.toml"

# ---------- 로그인 셸 ----------
zsh_path=$(command -v zsh)
if [ "$OS" = Darwin ]; then
  cur=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
  [ "$cur" = "$zsh_path" ] || { log "login shell → zsh"; chsh -s "$zsh_path" || echo "chsh 실패: 수동으로 'chsh -s $zsh_path'"; }
elif [ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]; then
  log "login shell → zsh"
  if sudo -n true 2>/dev/null; then   # chsh 는 비밀번호 만료 계정에서 PAM 에 막히므로 usermod
    grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    sudo usermod -s "$zsh_path" "$USER"
  else
    chsh -s "$zsh_path" || echo "chsh 실패: 관리자에게 'usermod -s $zsh_path $USER' 요청"
  fi
fi

# ---------- 찌꺼기 정리 (이 스크립트 옛 버전 / 공식 설치기가 남긴 것) ----------
log "cleanup"
rm -rf "$HOME/.config/fish/conf.d/atuin.env.fish"
rmdir "$HOME/.config/fish/conf.d" "$HOME/.config/fish" 2>/dev/null || true
for f in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile"; do
  [ -f "$f" ] && sed -i.tmp -e '/\.atuin\/bin\/env/d' -e '/atuin init bash/d' "$f" && rm -f "$f.tmp"
done
for f in "$HOME"/.zshrc.bak.*; do   # 스크립트가 만든 백업만 삭제 (사용자가 쓴 건 보존)
  [ -f "$f" ] || continue
  if head -1 "$f" | grep -q "managed by" || ! grep -vE '^\s*$|atuin' "$f" | grep -q .; then rm -f "$f"; fi
done
rm -f "$HOME"/.local/share/man/man1/zoxide*.1; find "$HOME/.local/share/man" -type d -empty -delete 2>/dev/null || true
[ "$OS" = Darwin ] || { sudo -n true 2>/dev/null && [ "$(sort /etc/shells | uniq -d | wc -l)" -gt 0 ] && awk '!seen[$0]++' /etc/shells | sudo tee /etc/shells.new >/dev/null && sudo mv /etc/shells.new /etc/shells; } || true
# ~/dotfiles: 커밋 안 한 변경이나 push 안 한 커밋이 없을 때만 삭제 (개발 중인 사본 보호)
if [ -d "$HOME/dotfiles/.git" ] && git -C "$HOME/dotfiles" remote get-url origin 2>/dev/null | grep -q "tae-jun/dotfiles"; then
  if [ -z "$(git -C "$HOME/dotfiles" status --porcelain)" ] && [ -z "$(git -C "$HOME/dotfiles" log --oneline '@{u}..' 2>/dev/null)" ]; then
    rm -rf "$HOME/dotfiles"
  else
    echo "~/dotfiles 에 커밋/푸시 안 된 변경이 있어 남겨둠"
  fi
fi

# ---------- gh 로그인 ----------
if have gh && ! gh auth status >/dev/null 2>&1; then
  if [ -e /dev/tty ]; then
    log "gh auth login (브라우저/코드 인증만 해주면 됨)"
    gh auth login -h github.com -p https -w < /dev/tty > /dev/tty 2>&1 && gh auth setup-git || echo "gh 로그인 건너뜀. 나중에: gh auth login"
  else
    echo "tty 없음 → 나중에 직접: gh auth login"
  fi
fi

log "완료. 'exec zsh' 또는 재접속. atuin 동기화 쓰려면 'atuin login'."
