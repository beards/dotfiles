---
name: commit
description: Commit staged changes with a conventional commits message based on the actual diff.
disable-model-invocation: false
allowed-tools: Bash Read Grep
---

Commit the currently staged changes using the Conventional Commits format.

## Steps

1. Run `git diff --cached` to see what is staged. If nothing is staged, tell the user and stop.
2. Run `git diff --cached --stat` to get a summary of changed files.
3. Analyze the actual code changes to determine:
   - The appropriate **type**: prefer `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `build`, `ci` — only use `chore` when none of the above fit.
   - An optional **scope** if the changes are clearly scoped to a module or component.
   - A concise **description** (imperative mood, lowercase, no period) that accurately reflects the staged diff.
   - A **body** in concise bullet-point form listing what was done (features added, bugs fixed, refactors made, etc.). Each bullet should be factual and derived from the diff — do not speculate or embellish.
4. Format the commit message as:

```
<type>[optional scope]: <description>

- bullet point 1
- bullet point 2
...
```

5. Create the commit using `git commit` with the message passed via a HEREDOC. Do NOT use `--no-verify` or skip any hooks.
6. Show the user the resulting `git log -1` output to confirm.

## Rules

- The description and body MUST be based on the actual staged diff. Do not invent changes that are not present.
- Keep the description under 72 characters.
- Keep body bullets concise — one line each.
- If the diff is too large to analyze fully, focus on the most significant changes and note that in the body.
- Do NOT stage additional files — only commit what is already staged.
- Do NOT amend previous commits.
- Do NOT push after committing.
