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
    iso_release = string
    iso_base_url = string
  })
}

source "qemu" "fedora-base" {
  
  iso_url      = "${var.vm.iso_base_url}/${var.vm.version}/Everything/${var.vm.arch}/iso/Fedora-Everything-netinst-${var.vm.arch}-${var.vm.version}-${var.vm.iso_release}.iso"
  iso_checksum = "file:${var.vm.iso_base_url}/${var.vm.version}/Everything/${var.vm.arch}/iso/Fedora-Everything-${var.vm.version}-${var.vm.iso_release}-${var.vm.arch}-CHECKSUM"

  headless         = false

  vm_name          = "fedora-base-${var.vm.arch}-${var.vm.version}.qcow2"
  format           = "qcow2"
  disk_interface   = "virtio"
  disk_size        = "5G"
  output_directory = "output"

  machine_type     = "q35"
  accelerator      = "kvm"
  cpus             = 1
  memory           = 2048

  http_directory = "assets"

  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "20m"
  ssh_private_key_file = "assets/vagrant_id"

  boot_wait = "5s"
  boot_command = [
    "<wait>c<wait>",
    "setparams 'Install Fedora ${var.vm.version}'<enter>",
    "linux /images/pxeboot/vmlinuz", 
    " inst.stage2=hd:LABEL=Fedora-E-dvd-${var.vm.arch}-${var.vm.version}",
    " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/fedora-base.ks.cfg",
    " inst.notmux inst.noshell inst.noninteractive inst.text",
    " PACKER_HTTP_SSHPUBKEY=\"http://{{ .HTTPIP }}:{{ .HTTPPort }}/vagrant_id.pub\"",
    " quiet",
    "<enter>",
    "initrd /images/pxeboot/initrd.img<enter>",
    "boot<enter><wait>"
  ]

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

  post-processor "vagrant-cloud" {
    box_tag = "l4u/fedora-base"
    version = var.vm.version
    access_token = "ac7807cd8bd799482f5bb9d47d944aef2a427450ffe7969aa0525ff395d81042"
    architecture = var.vm.arch
    keep_input_artifact = true
    box_checksum = "sha512:${path.cwd}/output/${source.name}-${var.vm.arch}/vagrant.sha512" 
  }
}