variable "FedoraVersion" {
  type    = string
  default = "43"
}

variable "IsoRelease" {
  type    = string
  default = "1.6"
}

variable "SshPort" {
  type = number
  default = 50122
}

variable "KickstarterPath" {
  type    = string
  default = "fedora-base.ks.cfg"
}

variable "FedoraBaseIsoUrl" {
  type    = string
  default = "https://download.fedoraproject.org/pub/fedora/linux/releases"
}

variable "Arch" {
  type    = string
  default = "x86_64"
}
