# Study — the global F:\study project publisher

> One command for turning current work into a real project: find its home, make it presentable, verify it, and publish it.

[![Codex plugin](https://img.shields.io/badge/Codex-global%20plugin-2563EB)](https://github.com/Michaelunkai/study)
[![PowerShell 5.1](https://img.shields.io/badge/PowerShell-5.1-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Public repository](https://img.shields.io/badge/GitHub-public-2ea44f?logo=github&logoColor=white)](https://github.com/Michaelunkai/study)
[![License: MIT](https://img.shields.io/badge/license-MIT-2ea44f?logo=opensourceinitiative&logoColor=white)](LICENSE)

## Use it in Codex

Invoke the skill in any session with:

```text
$study
```

The skill inspects the current task and then:

- scans `F:\study` at least six levels deep;
- selects the most semantically fitting taxonomy location;
- creates exactly one project folder;
- moves or safely copies the complete project there;
- writes or improves the README and `.gitignore`;
- verifies the project using the appropriate checks;
- commits on `main`;
- reuses the matching public GitHub repository or creates it;
- pushes and verifies that local and remote `main` match;
- reports the exact final project and entry-point paths.

## Direct Windows helper

The companion helper is usable from a normal Windows PowerShell 5.1 prompt:

```powershell
& "C:\Users\Admin\plugins\study\scripts\Invoke-StudyProject.ps1" `
  -SourcePath "C:\path\to\source" `
  -ProjectName "descriptive-repository-name" `
  -Move
```

Use `-CheckOnly` to verify Git, GitHub authentication, and the PS5 environment without changing files. Omit `-Move` to preserve the source and copy it into the new project folder.

## Safety contract

The workflow fails closed when it finds likely credentials, a private matching repository, an occupied destination, a mismatched `origin`, an unavailable GitHub login, or a branch/remote mismatch. It does not delete unrelated files. The only duplicate cleanup performed by installation is removal of the exact older `codex-cmd-study` plugin implementation; separately named tools remain untouched.

## Global installation paths

- Canonical project source: `F:\study\Windows\Applications\PowerShell\Automation\Codex\Plugins\study`
- Global plugin path: `C:\Users\Admin\plugins\study`
- Skill entry point: `C:\Users\Admin\plugins\study\skills\study\SKILL.md`
- Direct helper: `C:\Users\Admin\plugins\study\scripts\Invoke-StudyProject.ps1`

## License

MIT. See [LICENSE](LICENSE).
