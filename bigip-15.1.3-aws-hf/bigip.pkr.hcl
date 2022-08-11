# REQUIRED
variable "aws_access_key" {
  type    = string
  default = ""
}

# REQUIRED
variable "aws_secret_key" {
  type    = string
  default = ""
}

# REQUIRED
variable "ssh_keypair_name" {
  type    = string
  default = ""
}

# REQUIRED
variable "ssh_private_key_file" {
  type    = string
  default = ""
}

# REQUIRED
variable "ami_users" {
  type    = list(string)
}

# F5 BIGIP-15.1.2.1-0.0.10 PAYG-Best 25Mbps
# ami-0e5e6c0095256ac49
# F5 BIGIP-15.1.6.1-0.0.10 PAYG-Best Plus 25Mbps
# ami-00e50de456ee2ef22
variable "source_ami" {
  type    = string
  default = "ami-0e5e6c0095256ac49"
}

variable "ami_name" {
  type    = string
  default = "BIGIP-Hotfix-BIGIP-15.1.3.0.261.11"
}

variable "target_version" {
  type    = string
  default = "15.1.3.0"
}

variable "target_build" {
  type    = string
  default = "261.11"
}

variable "ami_regions" {
  type    = list(string)
  default = ["us-west-2"]
}

variable "region" {
  type    = string
  default = "us-west-2"
}

# REQUIRED
variable "vpc_id" {
  type    = string
  default = ""
}

# REQUIRED
variable "subnet_id" {
  type    = string
  default = ""
}

variable "associate_public_ip_address" {
  type    = string
  default = "true"
}

variable "instance_type" {
  type    = string
  default = "c5.xlarge"
}

source "amazon-ebs" "bigip_base" {
  access_key                  = "${var.aws_access_key}"
  ami_name                    = "${var.ami_name}"
  ami_regions                 = "${var.ami_regions}"
  ami_users                   = "${var.ami_users}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  aws_polling {
      delay_seconds = 30
      max_attempts = 60
  }
  instance_type               = "${var.instance_type}"
  region                      = "${var.region}"
  secret_key                  = "${var.aws_secret_key}"
  source_ami                  = "${var.source_ami}"
  ssh_keypair_name            = "${var.ssh_keypair_name}"
  ssh_private_key_file        = "${var.ssh_private_key_file}"
  ssh_timeout                 = "20m"
  ssh_username                = "admin"
  subnet_id                   = "${var.subnet_id}"
  user_data_file              = "scripts/user_data.sh"
  vpc_id                      = "${var.vpc_id}"
}

build {
  sources = ["source.amazon-ebs.bigip_base"]

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
    destination = "/shared/images/Hotfix-BIGIP-15.1.3.0.261.11-ENG.iso"
    source      = "software/Hotfix-BIGIP-15.1.3.0.261.11-ENG.iso"
  }
  
  # Upload Base ISO
   provisioner "file" {
    destination = "/shared/images/BIGIP-15.1.3-0.0.11.iso"
    source      = "software/BIGIP-15.1.3-0.0.11.iso"
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
