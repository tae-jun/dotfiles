# dotfiles

zsh + starship + atuin + fzf-tab 터미널 환경. Ubuntu/Debian 서버용. 한 줄로 설치.

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

### 1. 실행

```bash
curl -fsSL https://raw.githubusercontent.com/tae-jun/dotfiles/main/setup-shell.sh | bash
```

스크립트는 idempotent 하다. 하는 일:

1. `~/dotfiles` 에 이 repo clone (이미 있으면 pull) 후 거기서 재실행
2. sudo 가 되면 `apt install zsh git curl`. 안 되면 건너뜀
3. fzf 최신 바이너리를 GitHub 릴리즈에서 `~/.local/bin` 에 설치 (apt 버전은 0.44 라 `fzf --zsh` 미지원)
4. starship, atuin, zoxide 를 공식 설치 스크립트로 `~/.local/bin` 에 설치
5. zsh 플러그인 4개를 `~/.zsh/plugins/` 에 git clone
6. `zshrc` → `~/.zshrc`, `starship.toml` → `~/.config/starship.toml` 복사. 기존 `.zshrc` 는 `.zshrc.bak.<ts>` 로 백업
7. 로그인 셸을 zsh 로 변경 (sudo 있으면 `usermod -s`, 없으면 `chsh`)

### 2. 검증

실행 후 반드시 아래를 돌려서 전부 통과하는지 확인한다.

```bash
export PATH="$HOME/.local/bin:$PATH"
getent passwd "$USER" | cut -d: -f7          # → /usr/bin/zsh (또는 zsh 경로)
script -qc "zsh -ic 'echo RC_OK; exit'" /dev/null | grep -E "RC_OK|error|not found"   # RC_OK 만 나와야 함
zsh -ic 'bindkey "^[[A"' 2>/dev/null         # → up-line-or-beginning-search
zsh -ic 'alias l' 2>/dev/null                # → ls -AFlvh --group-directories-first
for t in starship atuin zoxide fzf; do $t --version | head -1; done
```

- `zsh -ic` 로 실행하면 `can't change option: zle` 가 뜰 수 있다. tty 가 없어서 나는 것이고 무시한다. tty 검증이 필요하면 `script -qc` 로 감싼다.
- fzf 는 0.48 이상이어야 한다.

### 3. 서버별 설정

필요하면 `~/.zshrc.local` 을 만든다. 예:

```zsh
# conda
[ -f ~/miniconda3/etc/profile.d/conda.sh ] && source ~/miniconda3/etc/profile.d/conda.sh
# 서버 전용 alias / env
export DATA_ROOT=/mnt/data
```

이 파일은 커밋하지 않는다.

### 4. 트러블슈팅

| 증상 | 원인 | 처리 |
|---|---|---|
| `chsh: PAM: Authentication token is no longer valid` | 계정 비밀번호 만료 | 스크립트가 `sudo usermod -s` 로 우회함. sudo 없으면 관리자에게 요청 |
| `unknown option: --zsh` | fzf 가 apt 구버전 | `sudo apt-get remove fzf` 후 스크립트 재실행 |
| sudo 없고 zsh 도 없음 | | zsh 만 관리자에게 설치 요청. 나머지는 `~/.local/bin` 에 깔려서 동작 |
| GitHub 접근 불가 서버 | | 접근되는 머신에서 `scp -r ~/dotfiles server:~/ && ssh server '~/dotfiles/setup-shell.sh'` |
| 로그인 셸은 바뀌었는데 여전히 bash | 현재 세션은 안 바뀜 | `exec zsh` 또는 재접속 |
| 위 화살표가 prefix 검색을 안 함 | 옛 `.zshrc` 가 남아 있음 | `cmp ~/.zshrc ~/dotfiles/zshrc` 로 확인 후 스크립트 재실행 |

### 5. 설정을 바꾸고 싶을 때

`~/dotfiles/zshrc` 또는 `starship.toml` 을 수정하고 `cp` 로 홈에 반영 (또는 스크립트 재실행). 커밋 전에 반드시 다음을 돌려서 개인정보가 없는지 확인한다.

```bash
cd ~/dotfiles && git diff --cached | grep -niE "@|ssh |[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|token|key" 
```

걸리는 게 있으면 커밋하지 않는다. push 는 `git push` (gh 인증이 git credential 로 등록돼 있음).

---

## 구성

| 역할 | 도구 | 비고 |
|---|---|---|
| 셸 | zsh | |
| 프롬프트 | starship | 호스트명 항상 표시 (서버 구분용) |
| 히스토리 검색 | atuin | `Ctrl+R`. ↑ 는 atuin 에 안 넘김 |
| ↑/↓ | zsh `up-line-or-beginning-search` | 입력한 prefix 로 시작하는 히스토리만 탐색 |
| transient prompt | zle `line-finish` hook | 엔터 후 이전 프롬프트는 `❯` 한 줄로 축약 |
| 인라인 히스토리 제안 | zsh-autosuggestions | `→` 또는 `Ctrl+Space` 로 수락 |
| Tab 완성 UI | fzf-tab + fzf | 퍼지 선택 |
| 대소문자 무시 완성 | zsh `matcher-list` | `cd doc<Tab>` → `Documents` |
| 문법 하이라이트 | fast-syntax-highlighting | |
| 추가 completion | zsh-completions | |
| cd 대체 | zoxide | `z <부분이름>` |
| alias | `l` = `ls -AFlvh --group-directories-first` | |

## 파일

- `setup-shell.sh` — 설치 스크립트 (self-bootstrap, idempotent)
- `zshrc` — `~/.zshrc` 로 복사됨
- `starship.toml` — `~/.config/starship.toml` 로 복사됨
- `publish.sh` — 최초 GitHub push 용. 이미 완료됨, 다시 쓸 일 없음
