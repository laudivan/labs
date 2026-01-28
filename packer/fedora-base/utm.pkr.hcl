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
    image_url = string
    image_checksum = string
  })
}

source "utm-cloud" "fedora-base" {
  iso_url      = "${var.vm.image_url}"
  iso_checksum = "${var.vm.image_checksum}"

  vm_name          = "utm-fedora-base-${var.vm.arch}-${var.vm.version}.qcow2"
  vm_backend       = "qemu"

  output_directory = "${path.cwd}/output"

  cpus             = 1
  memory           = 2048

  http_directory = "${path.cwd}/packer/fedora-base"

  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "20m"
  ssh_private_key_file = "${path.cwd}/assets/vagrant_id"

  shutdown_command = "systemctl poweroff"
}

build {

  sources = ["source.utm-cloud.fedora-base"]

  source "utm-cloud.fedora-base" {
    name = "fedora-base"
  }

  provisioner "shell-local" {
    inline = [
      "echo 'Building ${source.name}/${var.vm.arch} for {{.Provider}}'"
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

  post-processor "utm-vagrant" {
    compression_level = 9
    output = "${path.cwd}/output/utm-${source.name}-${var.vm.arch}/vagrant.box"
    #vagrantfile_template = "Vagrantfile.tpl"
  }

  post-processor "checksum" {
    checksum_types = [ "md5", "sha512" ]
    keep_input_artifact = true
  }
}