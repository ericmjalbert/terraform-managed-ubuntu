# Curated list of apt packages to manage.
# Add packages here as you identify them; `tofu plan` will show drift.

locals {
  apt_packages = toset([
    "build-essential",
    "curl",
    "git",
    "htop",
    "jq",
    "ripgrep",
    "tmux",
    "tree",
    "unzip",
    "wget",
    "zsh",
  ])
}

resource "apt_package" "managed" {
  for_each = local.apt_packages
  name     = each.value
}
