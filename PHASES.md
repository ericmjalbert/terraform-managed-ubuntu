# Terraform-Managed Ubuntu: Phased Implementation Plan

Goal: Declaratively manage an Ubuntu 22.04 desktop via OpenTofu. Each `tofu apply` reproduces the full dev environment.

## Architecture Overview

**Three layers:**
1. **Layer 0 (Bootstrap)**: `bootstrap.sh` — installs Go, OpenTofu, git, clones repo, runs `tofu apply`
2. **Layer 1 (Custom Providers)**: 9 Go providers in separate repos, built on `providerlib` shared library
3. **Layer 2 (OpenTofu Config)**: HCL modules by domain, all in this repo

### Provider Inventory

| Provider | Repo | Resources | Data Sources | Phase |
|---|---|---|---|---|
| `terraform-provider-apt` | ericmjalbert/terraform-provider-apt | `apt_package` | `apt_installed` | **1** |
| `terraform-provider-snap` | ericmjalbert/terraform-provider-snap | `snap_package` | `snap_installed` | 4 |
| `terraform-provider-nvim` | ericmjalbert/terraform-provider-nvim | `nvim_config` | — | 2 |
| `terraform-provider-tmux` | ericmjalbert/terraform-provider-tmux | `tmux_config` | — | 3 |
| `terraform-provider-claude` | ericmjalbert/terraform-provider-claude | `claude_*` (3 resources) | — | 3 |
| `terraform-provider-dotfiles` | ericmjalbert/terraform-provider-dotfiles | `dotfile` | `dotfile_existing` | **2** |
| `terraform-provider-golang` | ericmjalbert/terraform-provider-golang | `golang_install` | — | 5 |
| `terraform-provider-pipx` | ericmjalbert/terraform-provider-pipx | `pipx_package` | `pipx_installed` | 4 |
| `terraform-provider-github-release` | ericmjalbert/terraform-provider-github-release | `github_release_binary` | — | 4 |

### Shared Library

**`providerlib`** (ericmjalbert/providerlib) — Go module imported by all providers:
- `fileresource/` — generic Read/Write/Backup/Permissions logic for file-based resources
- `shellexec/` — wrapper for running shell commands with stdout/stderr capture
- `schema/` — common schema attributes and helpers

---

## Phase Progress

### ✅ Phase 0 — Foundation [COMPLETE]

**Status**: Done (2026-03-13)

**Deliverables:**
- [x] Go 1.24.1 installed
- [x] Project structure created (main.tf, variables.tf, outputs.tf, all module .tf stubs, files/)
- [x] bootstrap.sh written and tested
- [x] `providerlib` repo created and tagged v0.1.0
- [x] `terraform-provider-apt` repo created and tagged v0.1.0
- [x] `terraform-provider-dotfiles` repo created and tagged v0.1.0
- [x] main.tf provider declarations (apt + dotfiles active, rest commented out)
- [x] `~/.terraformrc` with dev_overrides for local provider dev
- [x] **`tofu apply` runs successfully**

**Key files:**
- `bootstrap.sh` — ready to run on fresh Ubuntu 22.04
- `main.tf` — provider blocks + module calls
- `packages.tf` — 11 curated apt packages
- `.terraformrc` — points to ~/go/bin for provider development

**Known issues fixed:**
- Parallel apt-get operations cause dpkg lock contention → wrapped with `flock /var/lib/dpkg/lock-frontend`

---

### Phase 1 — First Provider: `terraform-provider-apt` [IN PROGRESS]

**Status**: Core functionality working, needs polish

**Deliverables:**
- [x] Scaffold provider using terraform-plugin-framework
- [x] Implement `apt_package` resource: Create/Read/Update/Delete
- [x] Implement `apt_installed` data source for audit
- [x] Write `packages.tf` with curated package list
- [ ] Add unit/integration tests
- [ ] Add CI workflow (GitHub Actions: `tofu plan` validation)
- [ ] Tag v1.0.0 when done

**Current state:**
- Provider compiles and runs
- `apt_package` resource correctly manages package installation/removal
- `apt_installed` data source lists all installed packages
- 11 packages in `packages.tf`; `tofu plan` shows 0 changes (idempotent)

**Next steps:**
- Write tests for apt provider (use terraform-plugin-testing framework)
- Add GitHub Actions CI to run `tofu plan` on PR
- Tag v1.0.0 release

---

### Phase 2 — File-Based Providers: `dotfiles` + `nvim`

**Status**: `dotfiles` provider implemented, not yet wired into Terraform config

**Deliverables:**
- [x] Implement `providerlib/fileresource` with generic file CRUD
- [x] Build `terraform-provider-dotfiles` (uses fileresource lib)
- [ ] Build `terraform-provider-nvim` (uses fileresource lib + Lua validation)
- [ ] Write modules: `shell.tf`, `git.tf`, `neovim.tf`, `scripts.tf` (uncomment and wire up)
- [ ] Test on existing machine

**Current state:**
- `dotfiles` provider compiles and runs
- `dotfile` resource can write/read/delete files with permission management
- `dotfile_existing` data source can audit existing files
- All module .tf files exist but resources are commented out

**Next steps:**
- Build `terraform-provider-nvim` (copy `dotfiles` pattern, add Lua syntax validation)
- Uncomment resources in shell.tf, git.tf, neovim.tf, scripts.tf
- Test `tofu apply` on existing machine; verify files are managed correctly

---

### Phase 3 — Remaining File-Based: `tmux` + `claude`

**Status**: Not started

**Deliverables:**
- [ ] Build `terraform-provider-tmux` (copy pattern from nvim)
- [ ] Build `terraform-provider-claude` (3 resources: config, settings, script)
- [ ] Write modules: `tmux.tf`, `claude.tf` (uncomment and wire up)
- [ ] Test on existing machine

**Notes:**
- Both follow the same pattern as dotfiles/nvim
- Use providerlib/fileresource for CRUD
- Trivial to build once Phase 2 is done

---

### Phase 4 — Package Providers: `snap` + `pipx` + `github-release`

**Status**: Not started

**Deliverables:**
- [ ] Build `terraform-provider-snap` (similar pattern to apt)
- [ ] Build `terraform-provider-pipx` (similar pattern to apt)
- [ ] Build `terraform-provider-github-release` (download binaries from GitHub releases)
- [ ] Write modules: `devtools.tf`, `python.tf` (uncomment and wire up)
- [ ] Test on existing machine

**Notes:**
- `snap` and `pipx` follow apt pattern (shell execution + locking)
- `github-release` new pattern: download + extract binary

---

### Phase 5 — Language Runtimes + Polish

**Status**: Not started

**Deliverables:**
- [ ] Build `terraform-provider-golang` (download + install Go tarball, version management)
- [ ] Write `modules/golang.tf` (uncomment and wire up)
- [ ] Add import helpers for bootstrapping state from existing machine
- [ ] Add CI workflow to main project (`tofu plan` validation on PR)
- [ ] Documentation (README updates, examples)
- [ ] **Complete system ready**

---

## Development Notes

### Local Provider Testing

Use `~/.terraformrc` with dev_overrides:
```hcl
provider_installation {
  dev_overrides {
    "ericmjalbert/apt"      = "/home/ericmjalbert/go/bin"
    "ericmjalbert/dotfiles" = "/home/ericmjalbert/go/bin"
  }
  direct {}
}
```

Each time you rebuild a provider:
```bash
cd ~/Documents/terraform-provider-<name>
go build -o terraform-provider-<name> .
cp terraform-provider-<name> ~/go/bin/
```

Then in the main project:
```bash
tofu plan    # should show changes
tofu apply   # apply them
```

### Testing on Fresh Machine

Use `bootstrap.sh`:
```bash
# On a fresh Ubuntu 22.04 VM:
bash bootstrap.sh
```

It will install dependencies and run `tofu apply` to set up the full environment.

### Provider Framework

All providers use `terraform-plugin-framework` (modern SDK, not deprecated plugin-sdk v2).

Key patterns:
- `main.go` — entrypoint with `providerserver.Serve()`
- `provider.go` — provider registration (metadata, schema, configure)
- `resource_*.go` — resource implementations (Schema + CRUD methods)
- `datasource_*.go` — read-only data sources

Each resource implements:
- `Metadata()` — type name
- `Schema()` — attribute definitions
- `Create()`, `Read()`, `Update()`, `Delete()` — CRUD
- `Configure()` — optional provider configuration

### flock Usage (apt provider)

To serialize apt operations and avoid dpkg lock contention:
```go
cmd := exec.Command("sudo", "flock", "/var/lib/dpkg/lock-frontend",
    "apt-get", "install", "-y", pkgName)
```

This ensures only one apt-get runs at a time, even with parallel Terraform operations.

---

## Repos

| Repo | URL | Purpose |
|---|---|---|
| terraform-managed-ubuntu | https://github.com/ericmjalbert/terraform-managed-ubuntu | Main project (this repo) |
| providerlib | https://github.com/ericmjalbert/providerlib | Shared Go library for all providers |
| terraform-provider-apt | https://github.com/ericmjalbert/terraform-provider-apt | Apt package management |
| terraform-provider-dotfiles | https://github.com/ericmjalbert/terraform-provider-dotfiles | File management |
| terraform-provider-nvim | (not created yet) | Neovim config |
| terraform-provider-tmux | (not created yet) | Tmux config |
| terraform-provider-claude | (not created yet) | Claude Code config |
| terraform-provider-snap | (not created yet) | Snap package management |
| terraform-provider-pipx | (not created yet) | Python CLI tools |
| terraform-provider-github-release | (not created yet) | Binary downloads |
| terraform-provider-golang | (not created yet) | Go runtime |

---

## Key Decisions

1. **Parallelism**: Use `flock` in apt provider to serialize dpkg access (simpler than `-parallelism=1` flag)
2. **File management**: Separate `dotfiles` provider for generic files vs. domain-specific providers for config files (nvim, tmux, etc.)
3. **Secrets**: Terraform manages config file paths/contents that *reference* secrets, not the secrets themselves (e.g., `.ssh/config` path + key reference, but not the actual key files)
4. **Package management**: Curated list of ~30-80 intentionally-installed packages. Data sources (`apt_installed`, `snap_installed`) let you audit all installed packages and bring unmanaged ones under management as needed.
5. **State**: Local `.tfstate` file (gitignored). Appropriate for single-machine personal use.

---

## Testing Checklist

- [ ] Phase 1: `tofu plan` shows 0 changes for managed apt packages on existing machine
- [ ] Phase 2: `tofu plan` shows 0 changes for managed config files; manual edit → `tofu plan` shows drift
- [ ] Phase 3: All file-based configs under management
- [ ] Phase 4: Snap and pipx packages managed
- [ ] Phase 5: Full end-to-end: spin up fresh Ubuntu VM, run `bootstrap.sh`, verify setup matches current machine
- [ ] Audit: `tofu output` (or `tofu console`) lists all installed-but-unmanaged packages via data sources

