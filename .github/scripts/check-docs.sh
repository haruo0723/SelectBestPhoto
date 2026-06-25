#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "AGENTS.md"
  "README.md"
  "docs/requirements.md"
  "docs/tech-stack.md"
  "docs/spec/text-candidate-category-mvp/acceptance-criteria.md"
  "docs/design/text-candidate-category-mvp/architecture.md"
)

for file in "${required_files[@]}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Required file is missing or empty: ${file}" >&2
    exit 1
  fi
done

if ! grep -q "iOS 18" docs/tech-stack.md; then
  echo "docs/tech-stack.md must describe the iOS 18 target." >&2
  exit 1
fi

if ! grep -q "Firebase" docs/requirements.md; then
  echo "docs/requirements.md must describe Firebase requirements." >&2
  exit 1
fi

if ! grep -q "Live Photos" docs/requirements.md; then
  echo "docs/requirements.md must describe Live Photos handling." >&2
  exit 1
fi

echo "Documentation checks passed."
