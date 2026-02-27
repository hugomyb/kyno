#!/usr/bin/env bash
set -euo pipefail

BASE_HREF="/kyno/"
BUILD_DIR="build/web"
WORKTREE_DIR="/tmp/gh-pages"
BRANCH="gh-pages"
REPO_URL="${GITHUB_REPO_URL:-https://github.com/hugomyb/kyno.git}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found in PATH" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git not found in PATH" >&2
  exit 1
fi

STAMP="$(date -u +%Y%m%d%H%M%S)"

echo "Building Flutter web with base href ${BASE_HREF} (BUILD_STAMP=${STAMP})"
flutter build web --release --base-href "${BASE_HREF}" --dart-define=BUILD_STAMP="${STAMP}"

if [ ! -d "${BUILD_DIR}" ]; then
  echo "Build output not found at ${BUILD_DIR}" >&2
  exit 1
fi

./scripts/patch_flutter_service_worker_for_push.sh "${BUILD_DIR}"

if [ -f "${BUILD_DIR}/index.html" ]; then
  sed -i.bak "s/__BUILD_STAMP__/${STAMP}/g" "${BUILD_DIR}/index.html"
  rm -f "${BUILD_DIR}/index.html.bak"
fi

# Create or reuse the gh-pages worktree
if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  :
else
  if git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
    git fetch origin "${BRANCH}:${BRANCH}" >/dev/null 2>&1 || true
  else
    git fetch origin "${BRANCH}" >/dev/null 2>&1 || true
  fi

  BASE_BRANCH=""
  if git show-ref --verify --quiet "refs/heads/main"; then
    BASE_BRANCH="main"
  elif git show-ref --verify --quiet "refs/heads/master"; then
    BASE_BRANCH="master"
  else
    BASE_BRANCH="$(git branch --show-current || true)"
  fi

  if git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
    git branch "${BRANCH}" "origin/${BRANCH}"
  else
    git checkout --orphan "${BRANCH}"
    git reset --hard
    git commit --allow-empty -m "Init gh-pages"
    if [ -n "${BASE_BRANCH}" ]; then
      git checkout "${BASE_BRANCH}"
    fi
  fi
fi

git worktree prune >/dev/null 2>&1 || true
if git worktree list --porcelain | grep -q "worktree ${WORKTREE_DIR}"; then
  git worktree remove -f "${WORKTREE_DIR}" >/dev/null 2>&1 || true
fi
if [ -e "${WORKTREE_DIR}" ]; then
  rm -rf "${WORKTREE_DIR}" >/dev/null 2>&1 || true
fi

git worktree add "${WORKTREE_DIR}" "${BRANCH}"

# Clean and copy build output into worktree
if command -v rsync >/dev/null 2>&1; then
  rsync -av --delete --exclude ".git" "${BUILD_DIR}/" "${WORKTREE_DIR}/"
else
  rm -rf "${WORKTREE_DIR:?}"/*
  cp -R "${BUILD_DIR}/"* "${WORKTREE_DIR}/"
fi

touch "${WORKTREE_DIR}/.nojekyll"

pushd "${WORKTREE_DIR}" >/dev/null

if [ -n "${GITHUB_TOKEN:-}" ] || [ -n "${GH_TOKEN:-}" ] || [ -n "${GITHUB_PAT:-}" ]; then
  TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-${GITHUB_PAT:-}}}"
  AUTH_URL="https://${TOKEN}@github.com/$(echo "${REPO_URL}" | sed 's#^https://github.com/##')"
  git remote set-url origin "${AUTH_URL}"
fi

if ! git config user.email >/dev/null; then
  git config user.email "ci@local"
fi
if ! git config user.name >/dev/null; then
  git config user.name "CI"
fi

git add -A
if git diff --cached --quiet; then
  echo "No changes to deploy."
else
  git commit -m "Deploy to gh-pages (${STAMP})"
  git push origin "${BRANCH}"
fi

popd >/dev/null

git worktree remove -f "${WORKTREE_DIR}"

echo "Deployment complete."
