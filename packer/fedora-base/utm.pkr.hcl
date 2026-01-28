packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
    utm = {
      version = ">=v0.0.2"
      source  = "github.com/naveenrajm7/utm"
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

source "utm-iso" "fedora-base" {
  
  iso_url      = "${var.vm.iso_base_url}/${var.vm.version}/Everything/${var.vm.arch}/iso/Fedora-Everything-netinst-${var.vm.arch}-${var.vm.version}-${var.vm.iso_release}.iso"
  iso_checksum = "file:${var.vm.iso_base_url}/${var.vm.version}/Everything/${var.vm.arch}/iso/Fedora-Everything-${var.vm.version}-${var.vm.iso_release}-${var.vm.arch}-CHECKSUM"

  vm_name          = "utm-fedora-base-${var.vm.arch}-${var.vm.version}.qcow2"
  vm_backend       = "qemu"
  # disk_size        = 5120
  output_directory = "${path.cwd}/output"

  cpus             = 1
  memory           = 2048

  http_directory = "${path.cwd}/assets"

  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "20m"
  ssh_private_key_file = "${path.cwd}/assets/vagrant_id"

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

  sources = ["source.utm-iso.fedora-base"]

  source "utm-iso.fedora-base" {
    name = "fedora-base"
  }

  provisioner "shell-local" {
    inline = [
      "echo 'Building ${source.name}/${var.vm.arch} for UTM'"
    ]
  }

  post-processor "manifest" {
    output = "${path.cwd}/output/utm-${source.name}-${var.vm.arch}/manifest.json"
    strip_path = true
    custom_data = {
      author = "Laudivan Almeida"
      email = "lau@hanuky.space"
    }
  }

  post-processor "artifice" {
    files = [
      "${path.cwd}/output/utm-${source.name}-${var.vm.arch}/manifest.json",
      "${path.cwd}/output/utm-${source.name}-${var.vm.arch}/vagrant.box"
    ]
  }

  post-processor "utm-vagrant" {
    compression_level = 9
    output = "${path.cwd}/output/utm-${source.name}-${var.vm.arch}/vagrant.box"
  }

  post-processor "checksum" {
    checksum_types = [ "md5", "sha512" ]
    keep_input_artifact = true
  }
}