packer init packer/fedora-base/utm.pkr.hcl
packer validate --var-file=packer/fedora-base/utm.pkrvars.hcl packer/fedora-base/utm.pkr.hcl
packer build --var-file=packer/fedora-base/utm.pkrvars.hcl packer/fedora-base/utm.pkr.hcl



packer validate --except=vagrant-cloud --var-file=packer/fedora-base/qemu.pkrvars.hcl packer/fedora-base/qemu.pkr.hcl && packer build --except=vagrant-cloud --var-file=packer/fedora-base/qemu.pkrvars.hcl packer/fedora-base/qemu.pkr.hcl