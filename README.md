# dotfiles

zsh + starship + atuin 터미널 환경. Ubuntu/Debian 서버와 macOS. 한 줄로 설치, 찌꺼기 없음.

```bash
curl -fsSL https://raw.githubusercontent.com/tae-jun/dotfiles/main/setup-shell.sh | bash && exec zsh
```

---

## Claude Code 에게: 이 repo 로 서버 셋업하는 법

이 섹션은 사람이 아니라 Claude Code 가 읽고 그대로 실행하기 위한 것이다. 사용자가 이 repo 주소만 던져주면 아래를 따라 끝까지 알아서 진행할 것.

### 0. 절대 규칙

- **이 repo 는 public 이다. 개인정보를 절대 커밋하지 않는다.** 호스트명, 서버 별칭, IP, 이메일, 사용자명, 경로에 포함된 개인 식별자, API 키, 토큰 전부 금지. 커밋 author 이메일도 `<user>@users.noreply.github.com` 만 사용.
- 서버별 설정(alias, conda init, 환경변수, 호스트 관련 무엇이든)은 `~/.zshrc.local` 에 쓴다. 이 파일은 repo 에 없고 스크립트가 덮어쓰지 않는다.
- 사용자에게 물어보지 말고 진행한다. 막히면 아래 트러블슈팅을 먼저 본다.
- 설치 후 홈에 남는 것은 아래 "남는 파일" 목록이 전부여야 한다. 그 외는 찌꺼기이므로 정리하고, 스크립트 원인이면 고친다.

### 1. 실행

```bash
curl -fsSL https://raw.githubusercontent.com/tae-jun/dotfiles/main/setup-shell.sh | bash
```

- macOS 는 Homebrew 가 먼저 깔려 있어야 한다. 없으면 스크립트가 안내 후 종료. Homebrew 설치는 비밀번호가 필요해 사용자가 직접 해야 함.
- 마지막에 gh 가 로그인 안 돼 있으면 `gh auth login` 이 뜬다. 코드/브라우저 인증은 사용자가 한다. 사용자가 자리에 없으면 건너뛰고 나중에 하라고 알린다.
- repo 를 clone 하지 않는다. `zshrc`, `starship.toml` 은 raw URL 로 직접 받는다. `~/dotfiles` 는 필요 없다.

스크립트는 idempotent 하다. 하는 일:

1. Linux: zsh/git/curl 없으면 apt 로 설치 (sudo 필요). macOS: `brew install starship atuin zoxide fzf gh coreutils`
2. Linux: fzf, starship, atuin, zoxide, gh 를 GitHub 릴리즈 tarball 에서 받아 **바이너리만** `~/.local/bin` 에 설치. 공식 설치 스크립트는 안 씀 (rc 파일 건드리고 디렉토리 흩뿌림)
3. zsh 플러그인 3개를 `~/.zsh/plugins/` 에 git clone
4. `~/.zshrc`, `~/.config/starship.toml` 다운로드. 기존 `.zshrc` 가 이 repo 것이 아니면 `~/.zshrc.bak` 하나만 남김
5. 로그인 셸을 zsh 로 (Linux: sudo 있으면 `usermod -s`, 없으면 `chsh`. macOS: `chsh`)
6. 정리: 옛 버전/공식 설치기가 남긴 `~/.atuin`, `~/.zsh/plugins/fzf-tab`, fish 설정, `.bashrc`/`.profile` 의 atuin 줄, `.zshrc.bak.*`, zoxide man 페이지, `/etc/shells` 중복, 그리고 `~/dotfiles` (커밋·푸시 안 된 변경이 없을 때만)
7. gh 로그인 안 돼 있으면 `gh auth login` 실행

### 2. 남는 파일 (이게 전부)

| 경로 | 용도 |
|---|---|
| `~/.zshrc`, `~/.config/starship.toml` | 설정 |
| `~/.zsh/plugins/` | zsh 플러그인 3개 (autosuggestions, fast-syntax-highlighting, completions) |
| `~/.local/bin/{fzf,starship,atuin,zoxide,gh}` | 바이너리 (Linux. macOS 는 brew) |
| `~/.zcompdump`, `~/.cache/starship`, `~/.cache/fsh` | 런타임 캐시 |
| `~/.config/atuin/`, `~/.local/share/atuin/` | atuin 설정·히스토리 DB |
| `~/.local/share/zoxide/` | zoxide DB |
| `~/.config/gh/` | gh 인증 |
| `~/.zshrc.bak` | 사용자가 직접 쓴 .zshrc 가 있었을 때만 |

### 3. 검증

```bash
export PATH="$HOME/.local/bin:$PATH"
getent passwd "$USER" | cut -d: -f7          # Linux → zsh 경로. macOS 는 dscl . -read /Users/$USER UserShell
script -qc "zsh -ic 'echo RC_OK; exit'" /dev/null | grep -E "RC_OK|error|not found"   # RC_OK 만
zsh -ic 'bindkey "^[[A"' 2>/dev/null         # → up-line-or-beginning-search
zsh -ic 'bindkey "^I"' 2>/dev/null           # → atuin-search
zsh -ic 'alias l' 2>/dev/null                # → ls -AFlvh --group-directories-first (macOS 는 gls)
for t in starship atuin zoxide fzf gh; do $t --version | head -1; done   # fzf 는 0.48 이상
ls -d ~/.atuin ~/.config/fish ~/dotfiles 2>&1 | grep -v "No such"        # 아무것도 안 나와야 함
grep -c atuin ~/.bashrc ~/.profile                                        # 0
```

- `zsh -ic` 는 tty 가 없어서 `can't change option: zle` 가 뜰 수 있다. 무시. tty 검증은 `script -qc` 로.
- 실제 키 동작(↑ prefix 검색, Tab→atuin, transient prompt)을 검증하려면 pty 로 zsh 를 띄우고 pyte 로 렌더링해서 화면을 본다. pty 에 TIOCSWINSZ 로 창 크기를 반드시 설정할 것 (안 하면 atuin TUI 가 아무것도 안 그림). `bindkey` 출력만 믿지 말 것. 과거에 바인딩은 있는데 zshrc 편집 사고로 섹션이 통째로 사라진 적이 있다.

### 4. 서버별 설정

필요하면 `~/.zshrc.local` 을 만든다. 예:

```zsh
[ -f ~/miniconda3/etc/profile.d/conda.sh ] && source ~/miniconda3/etc/profile.d/conda.sh
export DATA_ROOT=/mnt/data
```

이 파일은 커밋하지 않는다.

### 5. 트러블슈팅

| 증상 | 원인 | 처리 |
|---|---|---|
| `chsh: PAM: Authentication token is no longer valid` | 계정 비밀번호 만료 | 스크립트가 `sudo usermod -s` 로 우회함. sudo 없으면 관리자에게 요청 |
| sudo 없고 zsh 도 없음 | | zsh 만 관리자에게 설치 요청. 나머지는 `~/.local/bin` 에 깔려서 동작 |
| GitHub 접근 불가 서버 | | 접근되는 머신에서 `git clone` 후 `scp -r dotfiles server:~/ && ssh server '~/dotfiles/setup-shell.sh'`. 스크립트 옆에 설정 파일이 있으면 그걸 씀 |
| macOS: `Homebrew 필요` 로 종료 | brew 미설치 | 사용자에게 https://brew.sh 설치 요청 후 재실행 |
| macOS: `compinit: insecure directories` | brew site-functions 권한 | `compaudit \| xargs chmod g-w,o-w` |
| macOS: `l` 이 `ls -AFlhG` 로 잡힘 | coreutils 미설치 | `brew install coreutils` 후 새 셸 |
| 로그인 셸은 바뀌었는데 여전히 bash | 현재 세션은 안 바뀜 | `exec zsh` 또는 재접속 |
| 위 화살표가 prefix 검색을 안 함 | 옛 `.zshrc` | 스크립트 재실행 후 `exec zsh` |
| `gh auth login` 이 안 뜸 | tty 없이 실행됨 | 직접 `gh auth login` |

### 6. 설정을 바꾸고 싶을 때

repo 를 clone 해서 `zshrc` 또는 `starship.toml` 을 수정하고 push. 커밋 전에 반드시 개인정보 검사:

```bash
git diff --cached | grep -niE "@|ssh |[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|token|key"
```

걸리는 게 있으면 커밋하지 않는다. push 후 각 서버에서 설치 한 줄을 다시 돌리면 갱신되고, 스크립트가 clone 한 디렉토리는 알아서 지운다.

---

## 구성

| 역할 | 도구 | 비고 |
|---|---|---|
| 셸 | zsh | |
| 프롬프트 | starship | `user@host dir` 한 줄 |
| transient prompt | zle `line-finish` hook | 엔터 후 이전 프롬프트는 `❯` 한 줄로 축약 |
| 히스토리 검색 | atuin | **Tab** 또는 `Ctrl+R`. 입력 중인 글자가 초기 검색어. ↑ 는 atuin 에 안 넘김. `?` AI 모드는 꺼둠 |
| ↑/↓ | zsh `up-line-or-beginning-search` | 입력한 prefix 로 시작하는 히스토리만 탐색 |
| 인라인 히스토리 제안 | zsh-autosuggestions | `→` 또는 `Ctrl+Space` 로 수락 |
| 완성 (파일명·명령어) | zsh 기본 메뉴 | **Shift+Tab**. Tab 은 atuin 이 씀 |
| 대소문자 무시 완성 | zsh `matcher-list` | `cd doc<Tab>` → `Documents` |
| 문법 하이라이트 | fast-syntax-highlighting | |
| fzf | `Ctrl+T` 파일 고르기, `Alt+C` 디렉토리 이동 | |
| 추가 completion | zsh-completions | |
| cd 대체 | zoxide | `z <부분이름>` |
| GitHub CLI | gh | 설치 끝에 자동 login |
| alias | `l` = `ls -AFlvh --group-directories-first` | macOS 는 coreutils `gls` |

## 파일

- `setup-shell.sh` — 설치 스크립트 (idempotent, 찌꺼기 정리 포함)
- `zshrc` — `~/.zshrc` 로 설치됨
- `starship.toml` — `~/.config/starship.toml` 로 설치됨
