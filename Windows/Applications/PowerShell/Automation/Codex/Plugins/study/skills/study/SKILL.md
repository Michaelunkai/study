---
name: study
description: "Organize, verify, document, and publicly publish the current project under F:\\study. Use when the user invokes $study or /study, asks to package recent work, or asks to move/create a project under F:\\study."
---

# Study

When the user invokes `$study`, `/study`, or clearly asks for this workflow, immediately package the current work as one project under `F:\study` and publish it. Treat the current conversation, workspace, files, downloads, and any explicitly named source path as the project context.

## Required order

1. Inspect the current task and identify the complete project scope.
2. Scan `F:\study` deeply enough to inspect at least six path levels below the root. Use `F:\study` as the Windows root; on WSL use `/mnt/f/study`.
3. Choose the most semantically fitting existing location by matching the project domain to the folder taxonomy. Exclude temporary, cache, backup, archive, build-output, and unrelated directories.
4. If no suitable location exists, create this fallback taxonomy and use a new project folder beneath it:

   `F:\study\Windows\Applications\PowerShell\Automation\Codex\Projects\<repo-name>`

   The final project folder must be at least six levels below `F:\study`.
5. Create exactly one new project folder. Do not scatter project files across `F:\study`.
6. Move source artifacts when doing so will not break a live system. Copy live or production files instead, and report `copied` rather than `moved`.
7. Include the complete project: source, useful tests or verification, a polished `README.md`, and an appropriate `.gitignore`. Do not include credentials, tokens, private keys, caches, generated junk, or unrelated files.
8. Verify the project in proportion to its type. For PowerShell, use Windows PowerShell 5.1, parse the script, and run a safe dry-run or check-only mode when available. Do not use PowerShell 7 as proof of PS5 compatibility.
9. Initialize Git if needed, use branch `main`, stage only this project, run `git diff --cached --check`, and commit all intended files.
10. Run a secret scan before any push. If likely credentials or private keys are found, stop before publishing and explain the exact file without printing the secret.
11. Use the final folder basename as the repository name. If `owner/<repo-name>` already exists, reuse that exact public repository; otherwise create it as a public repository. Never silently switch to a different repository.
12. Ensure `origin` points to the matching repository, push `main`, and verify that local `main` and `origin/main` resolve to the same commit. Verify the remote is public and the working tree is clean.
13. End with verified facts only, including the absolute Windows project path, what was moved or copied, tests/checks, branch, commit, public GitHub URL, and the exact full path to the primary script, executable, or project entry point.

## Modes

### New project

For a new script, app, tool, or other project, derive a concise repository-safe name, locate it using the required deep scan, create one project folder, build the requested files there, and complete the full verification and publication order.

### Existing source or recent work

For an explicitly named path or recently completed task, inspect the source before moving it. Preserve useful directory structure, verify the destination copy before removing a source file, and never move a live production file merely to satisfy organization.

### Plan-only request

If the user explicitly asks for a plan only or says to wait, provide the plan and do not create, move, commit, or push files until the user approves. This exception does not apply to an ordinary `$study` request.

## GitHub and safety rules

- Require authenticated `gh` before publishing and fail clearly if it is unavailable.
- Public is the default; only use private visibility when the user explicitly requests private.
- Never push a repository containing secrets or private authentication material.
- Never use a guessed or temporary browser profile, and never infer permission to sign out of unrelated accounts or services while organizing a project.
- Do not delete unrelated files. Duplicate cleanup is limited to the exact `study` plugin implementation; similarly named but functionally separate plugins must be inspected and preserved.
- If a destination already contains unrelated work, stop before overwriting it and report the conflict.

## Direct helper

For use outside a Codex conversation, run the companion Windows PowerShell 5.1 helper:

```powershell
& "C:\Users\Admin\plugins\study\scripts\Invoke-StudyProject.ps1" `
  -SourcePath "C:\path\to\project-or-file" `
  -ProjectName "descriptive-repository-name" `
  -Move
```

Omit `-Move` to preserve the source and copy it. Use `-CheckOnly` to verify dependencies and configuration without creating or publishing anything.
