# Creating HF PAYG CLONE


## Requirements

- SSH Key
- Account with permissions to launch images

## Configuration Notes

- Tested with Packer 1.8.3

## Examples

```
packer build -var "aws_access_key=${AWS_ACCESS_KEY}" -var "aws_secret_key=${AWS_SECRET_KEY}" -var "vpc_id=vpc-2bbaf34e" -var "subnet_id=subnet-b2441ad7" -var "ami_users=[\"111111111111\"]" -var "AWS_TIMEOUT_SECONDS=600" bigip.pkr.hcl
```

ex. with specific SSH Key. 
```
packer build -var "aws_access_key=${AWS_ACCESS_KEY}" -var "aws_secret_key=${AWS_SECRET_KEY}" -var "ssh_keypair_name=YOUR-SSH-KEY-NAME" -var "ssh_private_key_file=/Users/example/.ssh/YOUR-SSH-KEY-NAME.pem" -var "vpc_id=vpc-2bbaf34e" -var "subnet_id=subnet-b2441ad7" -var -var "ami_users=[\"111111111111\"]" bigip.pkr.hcl
```

ex. Packer with debug and verbose logging. Helpful for debugging builds as can see what packer is doing as well as login to image being cloned.

```
PACKER_LOG=1 packer build -debug -var "aws_access_key=${AWS_ACCESS_KEY}" -var "aws_secret_key=${AWS_SECRET_KEY}" -var "ssh_keypair_name=YOUR-SSH-KEY-NAME" -var "ssh_private_key_file=/Users/example/.ssh/YOUR-SSH-KEY-NAME.pem" -var "vpc_id=vpc-2bbaf34e" -var "subnet_id=subnet-b2441ad7" -var "ami_users=[\"111111111111\"]" bigip.pkr.hcl
```


NOTE: 
  - ami_users, an account ID to publish to, is required as we're building from a markteplace AMI and the default settings (which tries to publish to public group "all") won't work.
 - Added "remote_folder": "/var/tmp" due to:
    ```
    Aug 18 09:05:03 ip-172-31-16-138.us-west-2.compute.internal notice shell[3453]: scp -vt /tmp
    Aug 18 09:05:03 ip-172-31-16-138.us-west-2.compute.internal err shell[3514]: path not allowed
    ```