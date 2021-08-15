variable "prefix" {
  default = "sandbox"
}

variable "size" {
  default = "Standard_D2as_v4"
}

variable "location" {
  default = "australiaeast"
}

variable "vnet_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.0.0/24"
}

variable "sshdata" {
  description = "SSH key RSA data."
}

variable "tag" {
  default = "UAT Infrastructure"
}
