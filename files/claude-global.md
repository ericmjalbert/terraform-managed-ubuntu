# Global Claude Instructions

## Global Scripts

### gh-logs — GitHub Actions log viewer
**Location:** `~/.local/bin/gh-logs`
**Usage:** `gh-logs [commit-sha]` (defaults to HEAD)

Fetches GitHub Actions logs for a given commit from a private repo.
Reads PAT from `GITHUB_PAT` env var, or falls back to
`opentofu/repo/terraform.tfvars` in the current git repo root.

```bash
gh-logs            # logs for HEAD
gh-logs abc1234    # logs for a specific commit
```

Use this whenever inspecting CI failures — run it instead of asking
the user to paste logs manually.
