packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
    ansible = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/ansible"
    }
    vagrant = {
      version = "~> 1"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

source "qemu" "fedora-base" {
  iso_url      = "${var.FedoraBaseIsoUrl}/${var.FedoraVersion}/Everything/${var.Arch}/iso/Fedora-Everything-netinst-${var.Arch}-${var.FedoraVersion}-${var.IsoRelease}.iso"
  iso_checksum = "file:${var.FedoraBaseIsoUrl}/${var.FedoraVersion}/Everything/${var.Arch}/iso/Fedora-Everything-${var.FedoraVersion}-${var.IsoRelease}-${var.Arch}-CHECKSUM"

  headless         = true

  vm_name          = "fedora-base-${var.Arch}-${var.FedoraVersion}.qcow2"
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
  ssh_timeout    = "30m"
  ssh_private_key_file = "./assets/vagrant_id"

  boot_wait = "5s"
  boot_command = [
    "<wait>c<wait>",
    "setparams 'Install Fedora ${var.FedoraVersion}'<enter>",
    "linux /images/pxeboot/vmlinuz", 
    " inst.stage2=hd:LABEL=Fedora-E-dvd-${var.Arch}-${var.FedoraVersion}",
    " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/fedora-base.ks.cfg",
    " PACKER_HTTP_SSHPUBKEY=\"http://{{ .HTTPIP }}:{{ .HTTPPort }}/vagrant_id.pub\"",
    " quiet",
    "<enter>",
    "initrd /images/pxeboot/initrd.img<enter>",
    "boot<enter><wait>"
  ]
}

build {
  sources = ["source.qemu.fedora-base"]

  post-processors {
    post-processor "manifest" {
      output = "artifacts/fedora-base/manifest.json"
      strip_path = true
      custom_data = {
        author = "Laudivan Almeida"
        email = "lau@hanuky.space"
      }
    }

    post-processor "artifice" {
      files = ["artifacts/fedora-base/fedora-base-${var.Arch}-${var.FedoraVersion}.box"]
    }

    post-processor "vagrant" {
      compression_level = 9
      keep_input_artifact = true
      #provider_override   = "qemu"
    }

    post-processor "checksum" {
      checksum_types = [ "md5", "sha512" ]
      keep_input_artifact = true
    }
  }
}
