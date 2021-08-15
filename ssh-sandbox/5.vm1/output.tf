
output "public_ips" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value       = "${azurerm_public_ip.pip.*.ip_address}"
}
