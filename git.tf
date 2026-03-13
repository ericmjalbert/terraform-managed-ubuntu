# Git configuration managed via the dotfiles provider.

# resource "dotfile" "gitconfig" {
#   path        = "${var.home}/.gitconfig"
#   content     = file("${path.module}/files/gitconfig")
#   permissions = "0644"
# }

# resource "dotfile" "ssh_config" {
#   path        = "${var.home}/.ssh/config"
#   content     = file("${path.module}/files/ssh_config")
#   permissions = "0600"
# }
