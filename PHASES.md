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
| `terraform-provider-apt` | ericmjalbert/terraform-provider-apt | `apt_package` | `apt_installed` | **1** ✅ |
| `terraform-provider-snap` | ericmjalbert/terraform-provider-snap | `snap_package` | `snap_installed` | **4** ✅ |
| `terraform-provider-nvim` | ericmjalbert/terraform-provider-nvim | `nvim_config` | — | **2** ✅ |
| `terraform-provider-tmux` | ericmjalbert/terraform-provider-tmux | `tmux_config` | — | **3** ✅ |
| `terraform-provider-claude` | ericmjalbert/terraform-provider-claude | `claude_global_config`, `claude_settings` | — | **3** ✅ |
| `terraform-provider-dotfiles` | ericmjalbert/terraform-provider-dotfiles | `dotfiles_config` | `dotfiles_existing` | **2** ✅ |
| `terraform-provider-golang` | ericmjalbert/terraform-provider-golang | `golang_install` | — | 5 |
| `terraform-provider-pipx` | ericmjalbert/terraform-provider-pipx | `pipx_package` | `pipx_installed` | **4** ✅ |
| `terraform-provider-github-release` | ericmjalbert/terraform-provider-github-release | `github-release_binary` | — | **4** ✅ |

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

### ✅ Phase 1 — First Provider: `terraform-provider-apt` [COMPLETE]

**Status**: Done (2026-03-13)

**Deliverables:**
- [x] Scaffold provider using terraform-plugin-framework
- [x] Implement `apt_package` resource: Create/Read/Update/Delete
- [x] Implement `apt_installed` data source for audit
- [x] Write `packages.tf` with curated package list
- [x] Add unit/integration tests (6 unit tests using mock executor pattern; no system modifications)
- [x] Add CI workflow (GitHub Actions: `go test` + `go build` validation)
- [x] Tag v1.0.0 when done

**Implementation notes:**
- Unit tests use dependency injection + mock executor pattern (CommandExecutor interface)
- Tests run without sudo, without modifying host, in milliseconds
- CI workflow validates on PR and main branch pushes
- Provider is idempotent; `tofu plan` shows 0 changes when packages already installed
- All 11 curated packages in `packages.tf` managed successfully

**Key files:**
- `cmd_executor.go` — CommandExecutor interface with RealCommandExecutor and MockCommandExecutor
- `resource_apt_package_test.go`, `datasource_apt_installed_test.go` — comprehensive unit tests
- `.github/workflows/ci.yml` — GitHub Actions CI pipeline

---

### ✅ Phase 2 — File-Based Providers: `dotfiles` + `nvim` [COMPLETE]

**Status**: Done (2026-03-13)

**Deliverables:**
- [x] Implement `providerlib/fileresource` with generic file CRUD
- [x] Build `terraform-provider-dotfiles` (uses fileresource lib)
- [x] Build `terraform-provider-nvim` (uses fileresource lib + Lua validation)
- [x] Write modules: `shell.tf`, `git.tf`, `neovim.tf`, `scripts.tf` (uncomment and wire up)
- [x] Test on existing machine

**Implementation notes:**
- **dotfiles provider**: Generic file management with permission control (`dotfiles_config` resource)
  - TypeName corrected to "dotfiles" for consistency
  - Resources named `dotfiles_config` following terraform-plugin-framework conventions
- **nvim provider**: Neovim Lua configuration with syntax validation
  - Uses gopher-lua for Lua syntax checking
  - Validates syntax without requiring vim module (uses proxy table with metatable)
  - Single `nvim_config` resource for managing init.lua files
- **Enabled resources**:
  - `shell.tf`: bashrc managed via dotfiles_config
  - `git.tf`: gitconfig managed via dotfiles_config
  - `neovim.tf`: init.lua managed via nvim_config
  - scripts.tf: commented out (gh-logs file not in version control yet)

**Key files:**
- `terraform-provider-nvim/resource_nvim_config.go` — Lua validation with gopher-lua
- Updated `.terraformrc` with nvim provider dev_override
- `shell.tf`, `git.tf`, `neovim.tf` with enabled resources

**Test results:**
- ✅ `tofu plan` shows 3 resources to create (bashrc, gitconfig, init.lua)
- ✅ `tofu apply` successfully creates all files with correct permissions
- ✅ `tofu plan` shows "No changes" (idempotent)

---

### ✅ Phase 3 — Remaining File-Based: `tmux` + `claude` [COMPLETE]

**Status**: Done (2026-03-14)

**Deliverables:**
- [x] Build `terraform-provider-tmux` (copy pattern from nvim, no Lua validation)
- [x] Build `terraform-provider-claude` (2 resources: `claude_global_config` + `claude_settings` with JSON validation)
- [x] Write modules: `tmux.tf`, `claude.tf` (uncomment and wire up)
- [x] Create content files: `claude-global.md`, `claude-settings.json`
- [x] Test on existing machine

**Implementation notes:**
- **tmux provider**: Manages `.tmux.conf` with file permissions attribute
  - Single `tmux_config` resource using fileresource CRUD
  - Permissions defaulted to "0644", fully computed
  - No special validation (simple text config)
- **claude provider**: Manages Claude Code configuration
  - `claude_global_config` resource: Markdown file (`~/.claude/CLAUDE.md`)
  - `claude_settings` resource: JSON file with validation (`~/.claude/settings.json`)
  - Both use fileresource CRUD with permissions support
  - JSON validation in Create/Update using `json.Unmarshal`
- **File organization**:
  - Content files stored in `files/claude-global.md` and `files/claude-settings.json`
  - Both providers use standard fileresource pattern for all CRUD operations

**Key files:**
- `terraform-provider-tmux/` — 4 files (main, provider, resource, go.mod)
- `terraform-provider-claude/` — 5 files (main, provider, 2 resources, go.mod)
- Updated `.terraformrc` with dev_overrides for tmux and claude
- Enabled resources in `tmux.tf` and `claude.tf`

**Test results:**
- ✅ `tofu plan` shows 3 resources to create (tmux_config + claude_global_config + claude_settings)
- ✅ `tofu apply` successfully creates all files with correct permissions
- ✅ `tofu plan` shows "No changes" (idempotent)
- ✅ Files created: `~/.tmux.conf`, `~/.claude/CLAUDE.md`, `~/.claude/settings.json`

---

### ✅ Phase 4 — Package Providers: `snap` + `pipx` + `github-release` [COMPLETE]

**Status**: Done (2026-03-15)

**Deliverables:**
- [x] Build `terraform-provider-snap` (similar pattern to apt)
- [x] Build `terraform-provider-pipx` (similar pattern to apt)
- [x] Build `terraform-provider-github-release` (download + extract binaries from GitHub releases)
- [x] Write modules: `devtools.tf`, `python.tf` (uncomment and wire up)
- [x] Test on existing machine

**Implementation notes:**
- **snap provider**: Manages snap packages with classic confinement support
  - `snap_package` resource: name, channel, classic (bool), version (computed), ensure
  - `snap_installed` data source: lists all installed snaps
  - Uses `sudo snap install/remove` with `--classic` flag support
- **pipx provider**: Manages Python CLI tools via pipx
  - `pipx_package` resource: name, version (computed), ensure
  - `pipx_installed` data source: lists all installed pipx packages
  - Uses `pipx install/uninstall` (no sudo needed)
- **github-release provider**: Downloads and installs binaries from GitHub releases
  - `github-release_binary` resource: repo, tag ("latest" supported), asset_pattern, binary_name, binary_path_in_archive, install_path, installed_version
  - Downloads tar.gz, extracts binary, sudo-installs with chmod 755
  - Supports version drift detection for "latest" tag
- **Resources deployed**:
  - `devtools.tf`: snap_package.opentofu (classic=true), snap_package.firefox, github-release_binary.gh (v2.67.0)
  - `python.tf`: pipx_package.aider_install
- Updated `.terraformrc` with dev_overrides for all three providers
- Generated `.terraform.lock.hcl` for provider version management

**Key files:**
- `terraform-provider-snap/` — 5 files (main, provider, cmd_executor, resource, datasource)
- `terraform-provider-pipx/` — 5 files (main, provider, cmd_executor, resource, datasource)
- `terraform-provider-github-release/` — 4 files (main, provider, resource, go.mod)
- Updated `main.tf`, `devtools.tf`, `python.tf`
- Updated `.terraformrc` with new provider overrides

**Test results:**
- ✅ `tofu plan` shows 4 resources to create (snap opentofu/firefox, pipx aider-install, github-release gh)
- ✅ `tofu apply` successfully creates all resources
- ✅ `tofu plan` shows "No changes" (idempotent)
- ✅ Manual verification: `snap list opentofu`, `snap list firefox`, `pipx list`, `gh --version` all working

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
    "ericmjalbert/nvim"     = "/home/ericmjalbert/go/bin"
    "ericmjalbert/tmux"     = "/home/ericmjalbert/go/bin"
    "ericmjalbert/claude"   = "/home/ericmjalbert/go/bin"
  }
  direct {}
}
```

**Note**: When using dev_overrides, skip `tofu init`. Just run `tofu plan` and `tofu apply` directly.

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
| terraform-provider-apt | https://github.com/ericmjalbert/terraform-provider-apt | Apt package management ✅ |
| terraform-provider-dotfiles | https://github.com/ericmjalbert/terraform-provider-dotfiles | File management ✅ |
| terraform-provider-nvim | https://github.com/ericmjalbert/terraform-provider-nvim | Neovim config ✅ |
| terraform-provider-tmux | https://github.com/ericmjalbert/terraform-provider-tmux | Tmux config ✅ |
| terraform-provider-claude | https://github.com/ericmjalbert/terraform-provider-claude | Claude Code config ✅ |
| terraform-provider-snap | https://github.com/ericmjalbert/terraform-provider-snap | Snap package management ✅ |
| terraform-provider-pipx | https://github.com/ericmjalbert/terraform-provider-pipx | Python CLI tools ✅ |
| terraform-provider-github-release | https://github.com/ericmjalbert/terraform-provider-github-release | Binary downloads ✅ |
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

- [x] Phase 1: `tofu plan` shows 0 changes for managed apt packages on existing machine ✅
- [x] Phase 2: `tofu plan` shows 0 changes for managed config files; manual edit → `tofu plan` shows drift ✅
- [x] Phase 3: All file-based configs under management (tmux.tf, claude.tf) ✅
- [x] Phase 4: Snap and pipx packages managed; GitHub release binary downloaded ✅
- [ ] Phase 5: Full end-to-end: spin up fresh Ubuntu VM, run `bootstrap.sh`, verify setup matches current machine
- [ ] Audit: `tofu output` (or `tofu console`) lists all installed-but-unmanaged packages via data sources

**Completed tests:**
- Phase 1: All 11 curated apt packages managed and idempotent
- Phase 2: bashrc, gitconfig, init.lua created and idempotent via `tofu apply`
- Phase 3: tmux_config, claude_global_config, claude_settings created and idempotent via `tofu apply`
- Phase 4: snap_package.opentofu (classic), snap_package.firefox, pipx_package.aider_install, github-release_binary.gh created and idempotent via `tofu apply`

