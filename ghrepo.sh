#!/usr/bin/env bash
#
# ghrepo - maak een private GitHub-repo met de naam van de huidige directory
#
# Werkt ook zonder terminal (atuin scripts run), dus zonder gum-menu:
# de bestemming geef je mee als argument.
#
#   ghrepo                     -> eigen account
#   ghrepo TechNative-B-V      -> org
#   ghrepo --name site org/naam
#   ghrepo --dry-run [OWNER]   -> alleen tonen wat er zou gebeuren
#
set -euo pipefail

usage() {
  cat <<'EOF'
Gebruik: ghrepo [opties] [OWNER]

  OWNER            eigen GitHub-account, een org, of user/repo.
                   Weglaten = je eigen account.
  -n, --name NAAM  repo-naam (standaard: naam van de huidige directory)
  -d, --dry-run    alleen tonen wat er zou gebeuren
  -h, --help       deze uitleg

Voorbeeld:
  ghrepo TechNative-B-V
  ghrepo -n cckafe-website cckafe
EOF
}

OWNER=""
REPO_NAME="$(basename "$PWD")"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name)    REPO_NAME="${2:?--name verwacht een waarde}"; shift 2 ;;
    -d|--dry-run) DRY_RUN=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    -*)           echo "Onbekende optie: $1" >&2; usage >&2; exit 2 ;;
    *)            OWNER="$1"; shift ;;
  esac
done

command -v gh >/dev/null 2>&1 || { echo "❌ 'gh' is niet geïnstalleerd." >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "❌ Je bent niet ingelogd bij gh. Voer eerst 'gh auth login' uit." >&2; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "❌ $PWD is geen git-repository." >&2; exit 1; }

if git remote get-url origin >/dev/null 2>&1; then
  echo "❌ origin bestaat al: $(git remote get-url origin)" >&2
  echo "   Verwijder die eerst met: git remote remove origin" >&2
  exit 1
fi

if [[ -z "$OWNER" ]]; then
  OWNER="$(gh api user --jq .login)"
fi

# user/repo meegegeven? Dan is de repo-naam daarin leidend.
if [[ "$OWNER" == */* ]]; then
  REPO_NAME="${OWNER#*/}"
  OWNER="${OWNER%%/*}"
fi

FULL="$OWNER/$REPO_NAME"

gh api "users/$OWNER" >/dev/null 2>&1 || {
  echo "❌ '$OWNER' bestaat niet als GitHub-account of org (of je hebt geen toegang)." >&2
  echo "   Beschikbare orgs:" >&2
  gh org list 2>/dev/null | sed 's/^/     /' >&2
  exit 1
}

if gh repo view "$FULL" >/dev/null 2>&1; then
  echo "❌ Repo '$FULL' bestaat al op GitHub." >&2
  exit 1
fi

if [[ $DRY_RUN -eq 1 ]]; then
  echo "Zou aanmaken: $FULL (private), origin koppelen aan $PWD"
  exit 0
fi

gh repo create "$FULL" --private --remote=origin --source=.
echo "✅ Repo 'https://github.com/$FULL' aangemaakt, origin gekoppeld."
echo "   Push met: git push -u origin HEAD"
