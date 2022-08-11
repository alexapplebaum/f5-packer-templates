
# REQUIRED
variable "subscription_id" {
  type    = string
}

# REQUIRED
variable "tenant_id" {
  type    = string
}

# REQUIRED
variable "client_id" {
  type    = string
}

# REQUIRED
variable "client_secret" {
  type    = string
}

# REQUIRED
variable "ssh_private_key_file" {
  type    = string
  default = "~/.ssh/id_rsa"
}

# REQUIRED
variable "managed_image_resource_group_name" {
  type    = string
}

# REQUIRED
variable "boot_diag_storage_account" {
  type    = string
}

variable "location" {
  type    = string
  default = "West US"
}

variable "image_name" {
  type    = string
  default = "myPackerImageBigipHF"
}

variable "image_offer" {
  type    = string
  default = "f5-big-ip-best"
}

variable "image_publisher" {
  type    = string
  default = "f5-networks"
}

variable "image_sku" {
  type    = string
  default = "f5-big-best-plus-hourly-25mbps"
}

variable "image_version" {
  type    = string
  default = "16.1.202000"
}

variable "target_version" {
  type    = string
  default = "16.1.2.2"
}

variable "target_build" {
  type    = string
  default = "0.12.28"
}

source "azure-arm" "bigip_base" {
  azure_tags = {
    dept = "Infra"
    task = "Image deployment"
  }
  boot_diag_storage_account         = "${var.boot_diag_storage_account}"
  client_id                         = "${var.client_id}"
  client_secret                     = "${var.client_secret}"
  custom_data_file                  = "scripts/user_data.sh"
  image_offer                       = "${var.image_offer}"
  image_publisher                   = "${var.image_publisher}"
  image_sku                         = "${var.image_sku}"
  image_version                     = "${var.image_version}"
  location                          = "${var.location}"
  managed_image_name                = "${var.image_name}"
  managed_image_resource_group_name = "${var.managed_image_resource_group_name}"
  os_type                           = "Linux"
  # Need to wait until initial startup script (custom_data_file) changes the password
  # to avoid new password prompt and let packer login via SSH Key Auth. 
  # VE Best takes ~ 6-8 min depending on VE size/type.
  pause_before_connecting           = "6m"
  plan_info {
    plan_name      = "${var.image_sku}"
    plan_product   = "${var.image_offer}"
    plan_publisher = "${var.image_publisher}"
  }
  ssh_private_key_file     = "${var.ssh_private_key_file}"
  ssh_timeout              = "20m"
  ssh_username             = "packeruser"
  ssh_handshake_attempts   = 100
  subscription_id          = "${var.subscription_id}"
  temp_resource_group_name = "packer-bigip-temp-rg"
  tenant_id                = "${var.tenant_id}"
  vm_size                  = "Standard_D8s_v4" 
}

build {
  sources = ["source.azure-arm.bigip_base"]

  provisioner "shell" {
    execute_command   = "run util bash -c 'chmod +x {{ .Path }}; env {{ .Vars }} {{ .Path }}'"
    expect_disconnect = "true"
    inline            = ["source /usr/lib/bigstart/bigip-ready-functions; wait_bigip_ready", "tmsh show sys software status"] 
    # However, bug in pause_before_connecting
    # https://github.com/hashicorp/packer/issues/7430
    # https://github.com/rubenst2013/packer-boxes/commit/4b535fe2d544f4071c49ee97e425885a17366daf#commitcomment-38832627
    pause_before      = "180s"
    remote_folder     = "/var/tmp"
    skip_clean        = "true"

  }

  # After password is set, should be safe to upload files via SSH Key Auth

  # Upload reset file to prepare for cloning 
  provisioner "file" {
    destination = "/var/tmp/prepare-for-clone.sh"
    source      = "scripts/prepare-for-clone.sh"
  }

  # Upload HF ISO
  provisioner "file" {
    destination = "/shared/images/Hotfix-BIGIP-16.1.2.2.0.12.28-ENG.iso"
    source      = "software/Hotfix-BIGIP-16.1.2.2.0.12.28-ENG.iso"
  }
  
  # Upload Base ISO
  provisioner "file" {
    destination = "/shared/images/BIGIP-16.1.2.2-0.0.28.iso"
    source      = "software/BIGIP-16.1.2.2-0.0.28.iso"
  }

  # Install HF via TMSH
  provisioner "shell" {
    environment_vars = [
       "TARGET_VERSION=${var.target_version}",
       "TARGET_BUILD=${var.target_build}",
    ]
    execute_command   = "run util bash -c 'chmod +x {{ .Path }}; env {{ .Vars }} {{ .Path }}'"
    expect_disconnect = "true"
    inline            = [ "tmsh install sys software hotfix Hotfix-BIGIP-$TARGET_VERSION.$TARGET_BUILD-ENG.iso create-volume volume HD1.2 reboot", "while [ 1 ]; do if tmsh show sys software status | grep 'HD1.2' | grep $TARGET_BUILD | grep complete; then break; fi; sleep 5; done", "tmsh show sys software status"] 
    pause_before      = "15s"
    remote_folder     = "/var/tmp"
    skip_clean        = "true"
  }

  # Wait for BIG-IP to reboot into new HF slot
  # and run reset file
  provisioner "shell" {
    execute_command     = "run util bash -c 'chmod +x {{ .Path }}; env {{ .Vars }} {{ .Path }}'"
    expect_disconnect   = "true"
    inline              = ["bash /var/tmp/prepare-for-clone.sh"]
    pause_before        = "15m0s"
    remote_folder       = "/var/tmp"
    skip_clean          = "true"
    start_retry_timeout = "10m"
  }

}



