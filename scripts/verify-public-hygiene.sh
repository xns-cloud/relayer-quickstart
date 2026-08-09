#!/usr/bin/env bash
#
# verify-public-hygiene.sh — public-repo hygiene gate for relayer-quickstart.
#
# This repo is mirrored to GitHub. It must never carry a live .env, an internal
# hostname/path, or a private image channel. Every check below maps to an epic
# E-B2 acceptance criterion and is designed to be run by CI or by a human before
# a mirror push.
#
#   Usage:  ./scripts/verify-public-hygiene.sh
#   Exit:   0 = clean, 1 = one or more violations
#
# Dependencies: bash, grep, find, git. `docker` is optional (check 5 skips
# gracefully without it).

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

FAILED=0
CHECK_NO=0

pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; FAILED=1; }
skip() { printf '  SKIP  %s\n' "$1"; }
head_check() { CHECK_NO=$((CHECK_NO + 1)); printf '\n[%d] %s\n' "$CHECK_NO" "$1"; }

# Files to scan: tracked files if this is a git repo, otherwise the working
# tree minus .git. This script excludes ITSELF from content scans — it
# necessarily contains the forbidden patterns it searches for.
SELF_REL="scripts/$(basename "$0")"

list_files() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git ls-files
  else
    find . -type f -not -path './.git/*' | sed 's|^\./||'
  fi | grep -v -x -F "$SELF_REL"
}

echo "relayer-quickstart public-hygiene verification"
echo "repo: $REPO_ROOT"

# ---------------------------------------------------------------------------
# 1. No live .env tracked in the repo.  (AC2)
# ---------------------------------------------------------------------------
head_check "No live .env file in the repo (AC2)"
ENV_HITS="$(list_files | grep -E '(^|/)\.env($|\.[^e]|\.e[^x])' || true)"
ENV_ON_DISK="$(find . -name '.env' -not -path './.git/*' 2>/dev/null || true)"
if [ -n "$ENV_HITS" ]; then
  fail "tracked .env-style file(s) found:"
  printf '        %s\n' $ENV_HITS
elif [ -n "$ENV_ON_DISK" ]; then
  fail "untracked .env present on disk (must never be committed or mirrored):"
  printf '        %s\n' $ENV_ON_DISK
else
  pass "no .env file tracked or on disk"
fi

# ---------------------------------------------------------------------------
# 2. .env.example carries no assigned value — every key commented or empty. (AC2)
# ---------------------------------------------------------------------------
head_check ".env.example is placeholder-only (AC2)"
if [ ! -f .env.example ]; then
  fail ".env.example is missing"
else
  # A violation is any non-comment, non-blank line whose RHS of '=' is non-empty.
  BAD_ENV="$(grep -nE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=[[:space:]]*[^[:space:]]' .env.example || true)"
  if [ -n "$BAD_ENV" ]; then
    fail ".env.example assigns concrete values (must be commented out or empty):"
    printf '        .env.example:%s\n' "$BAD_ENV"
  else
    pass "every key in .env.example is commented out or empty"
  fi
fi

# ---------------------------------------------------------------------------
# 3. No internal hostnames, IPs, or paths anywhere in the tree.  (AC5, AC6)
# ---------------------------------------------------------------------------
head_check "No internal hostnames / IPs / paths in any file (AC5, AC6)"
# Patterns are deliberately literal so this file's own doc comments are the only
# place they appear; the self-exclusion above keeps that from self-tripping.
INTERNAL_PATTERNS='192\.168\.|172\.28\.|10\.0\.0\.|rxm[0-9]{3}|/mnt/[a-z]/|scpcorp/deployment|relayer-standalone|\.local\b|scpri\.me:[0-9]|xa-miner\.internal|\.lan\b'
INTERNAL_HITS=""
while IFS= read -r f; do
  [ -f "$f" ] || continue
  HIT="$(grep -nEI "$INTERNAL_PATTERNS" "$f" 2>/dev/null || true)"
  if [ -n "$HIT" ]; then
    INTERNAL_HITS="${INTERNAL_HITS}$(printf '%s\n' "$HIT" | sed "s|^|        $f:|")
"
  fi
done <<EOF
$(list_files)
EOF
if [ -n "$INTERNAL_HITS" ]; then
  fail "internal reference(s) found:"
  printf '%s' "$INTERNAL_HITS"
else
  pass "no internal hostnames, IPs, or paths found"
fi

# ---------------------------------------------------------------------------
# 4. Compose points at the public beta channel, not the device-build channel.
#    (HANDOFF Risk Flag 2 — getting this wrong makes AC1 fail outright.)
# ---------------------------------------------------------------------------
head_check "Compose image is the public beta channel (AC1 / Risk Flag 2)"
COMPOSE=""
for c in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
  [ -f "$c" ] && COMPOSE="$c" && break
done
if [ -z "$COMPOSE" ]; then
  fail "no compose file found at repo root"
else
  if grep -qE '^[[:space:]]*image:[[:space:]]*releases\.scpri\.me/xns-relayer:beta-latest[[:space:]]*$' "$COMPOSE"; then
    pass "$COMPOSE image is releases.scpri.me/xns-relayer:beta-latest"
  else
    fail "$COMPOSE does not declare releases.scpri.me/xns-relayer:beta-latest. Found:"
    grep -nE '^[[:space:]]*image:' "$COMPOSE" | sed 's|^|        |' || true
  fi

  NIGHTLY="$(grep -nE 'scprime/xns-relayer|:nightly' "$COMPOSE" || true)"
  if [ -n "$NIGHTLY" ]; then
    fail "$COMPOSE references the internal device-build channel:"
    printf '        %s:%s\n' "$COMPOSE" "$NIGHTLY"
  else
    pass "$COMPOSE has no reference to the internal nightly channel"
  fi

  PULLNEVER="$(grep -nE '^[[:space:]]*pull_policy:[[:space:]]*never' "$COMPOSE" || true)"
  if [ -n "$PULLNEVER" ]; then
    fail "$COMPOSE sets pull_policy: never — a clean host has no cached image:"
    printf '        %s:%s\n' "$COMPOSE" "$PULLNEVER"
  else
    pass "$COMPOSE does not set pull_policy: never"
  fi
fi

# ---------------------------------------------------------------------------
# 5. Compose file parses.
# ---------------------------------------------------------------------------
head_check "Compose file parses"
if ! command -v docker >/dev/null 2>&1; then
  skip "docker not installed — cannot validate compose syntax here (run this check on a host with Docker)"
elif ! docker compose version >/dev/null 2>&1; then
  skip "docker present but Compose V2 plugin unavailable — cannot validate compose syntax"
elif [ -z "$COMPOSE" ]; then
  skip "no compose file to validate"
else
  CONFIG_OUT="$(docker compose -f "$COMPOSE" config 2>&1)"
  if [ $? -eq 0 ]; then
    pass "docker compose config exits 0"
  else
    fail "docker compose config failed:"
    printf '%s\n' "$CONFIG_OUT" | sed 's|^|        |'
  fi
fi

# ---------------------------------------------------------------------------
# 6. LICENSE present and Apache-2.0.  (AC4)
# ---------------------------------------------------------------------------
# Byte-exact against the canonical text from https://www.apache.org/licenses/LICENSE-2.0.txt.
# A substring check ("does it say Apache License?") is NOT sufficient: a paraphrased or
# model-generated licence contains the header and still is not the licence. E-B2 review
# caught exactly that — a 200-line paraphrase with a corrupted appendix clause that a
# grep-based check passed. Legal text is verified by hash or not at all.
APACHE_20_SHA256='cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30'

head_check "LICENSE present and byte-exact Apache-2.0 (AC4)"
if [ ! -f LICENSE ]; then
  fail "LICENSE is missing"
else
  license_sha="$(sha256sum LICENSE | cut -d' ' -f1)"
  if [ "$license_sha" = "$APACHE_20_SHA256" ]; then
    pass "LICENSE is byte-exact Apache-2.0"
  else
    fail "LICENSE:1 is not the canonical Apache-2.0 text (sha256 ${license_sha}, expected ${APACHE_20_SHA256}) — fetch it from https://www.apache.org/licenses/LICENSE-2.0.txt, do not hand-write or generate it"
  fi
fi

# ---------------------------------------------------------------------------
# 7. CONTRIBUTING + PR template exist and both point at GitLab.  (AC7)
# ---------------------------------------------------------------------------
head_check "CONTRIBUTING.md and PR template both state GitLab development (AC7)"
for f in CONTRIBUTING.md .github/PULL_REQUEST_TEMPLATE.md; do
  if [ ! -f "$f" ]; then
    fail "$f is missing"
  elif grep -qi 'gitlab' "$f"; then
    pass "$f exists and mentions GitLab"
  else
    fail "$f exists but never mentions GitLab"
  fi
done

# ---------------------------------------------------------------------------
echo
if [ "$FAILED" -eq 0 ]; then
  echo "RESULT: PASS — repo is safe to mirror publicly."
else
  echo "RESULT: FAIL — fix the violations above before mirroring."
fi
exit "$FAILED"
