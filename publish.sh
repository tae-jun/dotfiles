#!/usr/bin/env bash
# 최초 1회: gh auth login 후 실행. GITHUB_USER 치환 → 커밋 → GitHub repo 생성 → push
set -euo pipefail
cd "$(dirname "$0")"
gh auth status >/dev/null 2>&1 || { echo "먼저: gh auth login"; exit 1; }
user=$(gh api user -q .login)
echo "==> GitHub user: $user"
sed -i "s/GITHUB_USER/$user/g" setup-shell.sh README.md
git config user.name  >/dev/null || git config user.name "$user"
git config user.email >/dev/null || git config user.email "$(gh api user -q '.email // empty')"
[ -n "$(git config user.email)" ] || git config user.email "${user}@users.noreply.github.com"
git add -A
git diff --cached --quiet || git commit -qm "Set GitHub user to $user"
gh auth setup-git   # https push 에 gh 토큰 사용
if git remote get-url origin >/dev/null 2>&1; then
  git push -u origin main
else
  gh repo create dotfiles --public --source . --remote origin --push
fi
echo
echo "==> 완료. 어느 서버에서든:"
echo "curl -fsSL https://raw.githubusercontent.com/$user/dotfiles/main/setup-shell.sh | bash"
