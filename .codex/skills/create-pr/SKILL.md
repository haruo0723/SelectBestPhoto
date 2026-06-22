---
name: create-pr
description: Create GitHub pull requests from a local git branch. Use when the user asks to create a PR, open a pull request, prepare PR body, push the current branch for review, or summarize local changes for GitHub review. Covers checking git state, reviewing docs and tests, using the repository PR template, running relevant verification, pushing with approval when needed, and creating the PR with gh.
---

# Create PR

## Workflow

Use this workflow from the repository root.

1. Inspect repository state:
   - `git status --short`
   - `git branch --show-current`
   - `git remote -v`
   - `git diff --stat`
   - `git diff --cached --stat`
2. Identify the base branch:
   - Prefer the remote default branch from `gh repo view --json defaultBranchRef`.
   - Fall back to `main`, then `master`, if GitHub metadata is unavailable.
3. Review the change:
   - Read changed files and related docs.
   - For this project, always check `docs/requirements.md`, `docs/tech-stack.md`, and relevant `docs/spec/`, `docs/design/`, or `docs/tasks/` files when the change affects behavior, mobile UX, Firebase, media handling, or CI.
4. Run relevant verification before creating the PR:
   - Run existing tests, build, lint, and format checks when configured.
   - If there is no Xcode project yet, run repository-level checks that exist, such as GitHub Actions scripts or documentation checks.
   - Report any skipped verification and why.
5. Prepare the PR body:
   - Use `.github/pull_request_template.md` when present.
   - Keep the summary concrete and user-facing.
   - Link related docs, task files, and issues when available.
   - Mark checklist items honestly; leave unchecked items that need follow-up.
6. Push and create the PR:
   - If the branch is not pushed, run `git push -u origin <branch>` with approval when the environment requires it.
   - Create the PR with `gh pr create --base <base> --head <branch> --title "<title>" --body-file <file>`.
   - If `gh` is unavailable or unauthenticated, provide the exact command and body file path instead of pretending the PR was created.
7. Confirm the result:
   - Run `gh pr view --web=false` or `gh pr view --json url,title,baseRefName,headRefName`.
   - Relay the PR URL, title, base/head branches, and verification results.

## Title Guidance

Use concise Japanese titles unless the repository convention indicates otherwise.

Good examples:

- `PR作成フローとCIを整備`
- `月間ベスト入力の公開条件を修正`
- `Firebase Storage削除対象の判定を追加`

Avoid vague titles such as `update`, `fix`, or `changes`.

## Body Guidance

For mobile app changes, include only sections that matter to the change:

- Summary of behavior, UI, data, or docs changed.
- Related docs and acceptance criteria.
- iPhone UI checks, including Dynamic Type and VoiceOver when UI changed.
- Firebase Auth, Firestore, Storage, Security Rules, App Check, or logging impact when touched.
- Media handling impact for photos, videos, Live Photos, metadata, compression, and original photo library safety.
- Verification commands and results.
- Known risks or intentionally deferred items.

Do not claim a build, test, lint, format, or manual check ran unless it actually ran.

## Helper Script

Use `scripts/create_pr_body.sh` to generate a draft PR body from the template:

```bash
.codex/skills/create-pr/scripts/create_pr_body.sh
```

The script writes a temporary Markdown file path to stdout. Review and edit the generated file before passing it to `gh pr create --body-file`.
