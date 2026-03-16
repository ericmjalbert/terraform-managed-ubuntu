# Go runtime managed via the golang provider.

resource "golang_install" "main" {
  version      = "1.24.1"
  install_path = "/usr/local"
}
