packer {
  required_plugins {
    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
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
    iso_release = string
    iso_base_url = string
  })
}

source "virtualbox-iso" "fedora-server-arm64" {
  iso_url      = "${var.vm.iso_base_url}/${var.vm.version}/Server/aarch64/iso/Fedora-Server-netinst-aarch64-${var.vm.version}-${var.vm.iso_release}.iso"
  iso_checksum = "file:${var.vm.iso_base_url}/${var.vm.version}/Server/aarch64/iso/Fedora-Server-${var.vm.version}-${var.vm.iso_release}-aarch64-CHECKSUM"

  headless         = false

  guest_os_type    = "Fedora_arm64"
  disk_size        = 15360

  firmware = "efi"
  iso_interface = "sata"
  hard_drive_interface = "sata"

  guest_additions_mode = "disable"

  output_directory = "output"
  http_directory = "packer/fedora-server"

  cpus             = 1
  memory           = 2048
  nic_type         = "virtio"
  gfx_controller   = "vboxvga"
  gfx_accelerate_3d = false
  gfx_vram_size = 16

  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "20m"
  ssh_private_key_file = "assets/vagrant_id"

  boot_wait = "10s"
  boot_command = [
    "<wait>c<wait>",
    "setparams 'Install Fedora ${var.vm.version}'<enter>",
    "linux /images/pxeboot/vmlinuz", 
    " inst.stage2=hd:LABEL=Fedora-S-dvd-aarch64-${var.vm.version}",
    " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg",
    # " inst.notmux", 
    # " inst.noshell", 
    # " inst.noninteractive", 
    " inst.text",
    " PACKER_HTTP_SSHPUBKEY=\"http://{{ .HTTPIP }}:{{ .HTTPPort }}/vagrant_id.pub\"",
    " quiet",
    "<enter>",
    "initrd /images/pxeboot/initrd.img<enter>",
    "boot<enter><wait>"
  ]

  acpi_shutdown = true
  shutdown_command = "systemctl poweroff"
}

build {

  sources = ["source.virtualbox-iso.fedora-server-arm64"]

  source "virtualbox-iso.fedora-server-arm64" {
    name = "fedora-server-arm64"
  }

  provisioner "shell-local" {
    inline = [
      "echo 'Building ${source.name}'"
    ]
  }

  post-processor "manifest" {
    output = "output/${source.name}/manifest.json"
    strip_path = true
    custom_data = {
      author = "Laudivan Almeida"
      email = "lau@hanuky.space"
    }
  }

  post-processor "vagrant" {
    compression_level = 9
    output = "output/${source.name}/vagrant.box"
  }

  post-processor "checksum" {
    checksum_types = [ "sha512" ]
    keep_input_artifact = true
    output = "output/${source.name}/vagrant.{{ .ChecksumType }}"
  }
}