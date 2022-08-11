# REQUIRED
variable "account_file" {
  # Must be Absolute Path. no "~/file".
  type    = string
}

# REQUIRED
variable "project_id" {
  type    = string
}

# REQUIRED
variable "ssh_private_key_file" {
  type    = string
  default = "~/.ssh/id_rsa"
}

variable "source_image_project_id" {
  type    = string
  default = "f5-7626-networks-public"
}

variable "source_image" {
  type    = string
  default = "f5-bigip-16-1-2-2-0-0-28-payg-best-plus-25mbps-220505080809"
}

variable "target_version" {
  type    = string
  default = "16.1.2.2"
}

variable "target_build" {
  type    = string
  default = "0.12.28"
}

variable "target_image_name" {
  type    = string
  default = "my-packer-bigip-hf"
}

variable "zone" {
  type    = string
  default = "us-west1-a"
}

variable "network" {
  type    = string
  default = "default"
}

variable "subnetwork" {
  type    = string
  default = "default"
}

variable "use_internal_ip" {
  type    = string
  default = "false"
}

variable "disk_size" {
  type    = string
  default = "81"
}

variable "machine_type" {
  type    = string
  default = "n1-standard-8"
}


source "googlecompute" "bigip_base" {
  account_file            = "${var.account_file}"
  disk_size               = "${var.disk_size}"
  image_name              = "${var.target_image_name}"
  machine_type            = "${var.machine_type}"
  network                 = "${var.network}"
  # Need to wait until initial startup script (custom_data_file) changes the password
  # to avoid new password prompt and let packer login via SSH Key Auth. 
  # VE Best takes ~ 6-8 min depending on VE size/type.
  pause_before_connecting = "6m"
  project_id              = "${var.project_id}"
  source_image            = "${var.source_image}"
  source_image_project_id = ["${var.source_image_project_id}"]
  ssh_private_key_file    = "${var.ssh_private_key_file}" 
  ssh_pty                 = true
  ssh_timeout             = "20m"
  ssh_username            = "admin"
  state_timeout           = "15m"
  startup_script_file     = "scripts/user_data.sh"
  subnetwork              = "${var.subnetwork}"
  use_internal_ip         = "${var.use_internal_ip}"
  zone                    = "${var.zone}"
}

build {
  sources = ["source.googlecompute.bigip_base"]

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
