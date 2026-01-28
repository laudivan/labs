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
    arch = string
    version = string
    image_release = string
    image_base_url = string
  })
}

source "qemu" "fedora-base" {
  #
  image_url      = "${var.vm.image_base_url}/${var.vm.version}/Cloud/${var.vm.arch}/images/Fedora-Cloud-Base-Generic-${var.vm.version}-${var.vm.image_release}-${var.vm.arch}.qcow2"
  image_checksum = "file:${var.vm.image_base_url}/${var.vm.version}/Cloud/${var.vm.arch}/images/Fedora-Cloud-Base-${var.vm.version}-${var.vm.image_release}-${var.vm.arch}.CHECKSUM"

  headless         = false

  vm_name          = "fedora-base-${var.vm.arch}-${var.vm.version}.qcow2"
  format           = "qcow2"
  disk_interface   = "virtio"
  disk_size        = "1G"
  output_directory = "output"

  machine_type     = "q35"
  accelerator      = "kvm"
  cpus             = 1
  memory           = 2048

  http_directory = "packer/fedora-base"

  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "20m"
  ssh_private_key_file = "assets/vagrant_id"

  shutdown_command = "systemctl poweroff"
}

build {

  sources = ["source.qemu.fedora-base"]

  source "qemu.fedora-base" {
    name = "fedora-base"
  }

  provisioner "shell-local" {
    inline = [
      "echo 'Building ${source.name}/${var.vm.arch}'"
    ]
  }

  post-processor "manifest" {
    output = "output/${source.name}-${var.vm.arch}/manifest.json"
    strip_path = true
    custom_data = {
      author = "Laudivan Almeida"
      email = "lau@hanuky.space"
    }
  }

  post-processor "vagrant" {
    compression_level = 9
    output = "output/${source.name}-${var.vm.arch}/vagrant.box"
  }

  post-processor "checksum" {
    checksum_types = [ "sha512" ]
    keep_input_artifact = true
    output = "output/${source.name}-${var.vm.arch}/vagrant.{{ .ChecksumType }}"
  }
}