packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
    vagrant = {
      version = "~> 1"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "vm" {
  type    = object({
    name = string
    version = string
    image_release = string
    image_base_url = string
  })
  default = {
    name = "fedora-server"
    version = "43"
    image_release = "1.6"
    image_base_url = "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server"
  }
}

source "qemu" "fedora-server-aarch64" {
  iso_url      = "${var.vm.image_base_url}/aarch64/iso/Fedora-Server-netinst-aarch64-${var.vm.version}-${var.vm.image_release}.iso"
  iso_checksum = "file:${var.vm.image_base_url}/aarch64/iso/Fedora-Server-${var.vm.version}-${var.vm.image_release}-aarch64-CHECKSUM"

  headless         = false

  vm_name          = "fedora-server-aarch64-${var.vm.version}.qcow2"
  format           = "qcow2"
  # disk_interface   = "virtio"
  # disk_size        = "1G"
  output_directory = "output"
  http_directory = "packer/fedora-server"

  # machine_type     = "q35"
  # accelerator      = "kvm"
  cpus             = 1
  memory           = 2048

  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "20m"
  ssh_private_key_file = "assets/vagrant_id"

  boot_wait = "10s"
  boot_command = [
    "<wait><cOn><cOff><wait>",
    "setparams 'Install Fedora ${var.vm.version}'<enter>",
    "linux /images/pxeboot/vmlinuz", 
    " inst.stage2=hd:LABEL=Fedora-S-dvd-aarch64-${var.vm.version}",
    " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg",
    # " inst.notmux", 
    # " inst.noshell", 
    # " inst.noninteractive", 
    " inst.text",
    # " PACKER_HTTP_SSHPUBKEY=\"http://{{ .HTTPIP }}:{{ .HTTPPort }}/vagrant_id.pub\"",
    " quiet",
    "<enter>",
    "initrd /images/pxeboot/initrd.img<enter>",
    "boot<enter><wait>"
  ]

  shutdown_command = "systemctl poweroff"
}

build {

  sources = ["source.qemu.fedora-server-aarch64"]

  source "qemu.fedora-server-aarch64" {
    name = "fedora-server"
  }

  provisioner "shell-local" {
    inline = [
      "echo 'Building ${source.name}'"
    ]
  }

  post-processor "manifest" {
    output = "output/${source.name}-aarch64/manifest.json"
    strip_path = true
    custom_data = {
      author = "Laudivan Almeida"
      email = "lau@hanuky.space"
    }
  }

  post-processor "vagrant" {
    compression_level = 9
    output = "output/${source.name}-aarch64/vagrant.box"
  }

  post-processor "checksum" {
    checksum_types = [ "sha512" ]
    keep_input_artifact = true
    output = "output/${source.name}-aarch64/vagrant.{{ .ChecksumType }}"
  }
}