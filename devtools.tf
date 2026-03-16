# Developer tools managed via apt, snap, and github-release providers.

# Additional apt packages for dev tooling are in packages.tf.

resource "snap_package" "opentofu" {
  name    = "opentofu"
  classic = true
}

resource "snap_package" "firefox" {
  name = "firefox"
}

resource "github-release_binary" "gh" {
  repo                   = "cli/cli"
  tag                    = "v2.67.0"
  asset_pattern          = "*linux_amd64.tar.gz"
  binary_name            = "gh"
  binary_path_in_archive = "bin/gh"
  install_path           = "/usr/local/bin"
}
