#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
template="${repo_root}/.github/pull_request_template.md"

if [[ ! -f "${template}" ]]; then
  echo "PR template not found: ${template}" >&2
  exit 1
fi

branch="$(git branch --show-current)"
safe_branch="${branch//\//-}"
body_file="$(mktemp "${TMPDIR:-/tmp}/pr-body-${safe_branch}.XXXXXX")"

{
  echo "<!-- Generated from .github/pull_request_template.md. Edit before creating the PR. -->"
  echo
  cat "${template}"
  echo
  echo "<!-- Changed files -->"
  git diff --name-only HEAD
} > "${body_file}"

echo "${body_file}"
