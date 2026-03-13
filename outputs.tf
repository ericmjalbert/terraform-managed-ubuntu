output "managed_apt_packages" {
  description = "List of apt packages managed by Terraform"
  value       = [for name, pkg in apt_package.managed : name]
}
