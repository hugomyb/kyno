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

echo "Building Flutter web with base href ${BASE_HREF}"
flutter build web --release --base-href "${BASE_HREF}"

if [ ! -d "${BUILD_DIR}" ]; then
  echo "Build output not found at ${BUILD_DIR}" >&2
  exit 1
fi

# Create or reuse the gh-pages worktree
if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  :
else
  if git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
    git branch "${BRANCH}" "origin/${BRANCH}"
  else
    git branch --orphan "${BRANCH}"
    git reset --hard
    git checkout -
  fi
fi

if [ -d "${WORKTREE_DIR}/.git" ] || [ -f "${WORKTREE_DIR}/.git" ]; then
  git worktree remove -f "${WORKTREE_DIR}" >/dev/null 2>&1 || true
fi

git worktree add "${WORKTREE_DIR}" "${BRANCH}"

# Clean and copy build output into worktree
if command -v rsync >/dev/null 2>&1; then
  rsync -av --delete "${BUILD_DIR}/" "${WORKTREE_DIR}/"
else
  rm -rf "${WORKTREE_DIR:?}"/*
  cp -R "${BUILD_DIR}/"* "${WORKTREE_DIR}/"
fi

touch "${WORKTREE_DIR}/.nojekyll"

pushd "${WORKTREE_DIR}" >/dev/null

git add -A
if git diff --cached --quiet; then
  echo "No changes to deploy."
else
  git commit -m "Deploy to gh-pages"
  git push origin "${BRANCH}"
fi

popd >/dev/null

git worktree remove -f "${WORKTREE_DIR}"

echo "Deployment complete."
