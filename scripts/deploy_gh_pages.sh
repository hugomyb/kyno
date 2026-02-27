#!/usr/bin/env bash
set -euo pipefail

BASE_HREF="/kyno/"
BUILD_DIR="build/web"
WORKTREE_DIR="/tmp/gh-pages"
BRANCH="gh-pages"

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
    git branch "${BRANCH}" "origin/${BRANCH}"
  else
    git checkout --orphan "${BRANCH}"
    git reset --hard
    if git show-ref --verify --quiet "refs/heads/main"; then
      git checkout main
    elif git show-ref --verify --quiet "refs/heads/master"; then
      git checkout master
    else
      git checkout -
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
