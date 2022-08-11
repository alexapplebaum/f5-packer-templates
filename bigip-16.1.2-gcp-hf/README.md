# Creating HF PAYG CLONE

## Requirements

- SSH Key
- Account with permissions to launch images

## Configuration Notes

- Tested with Packer 1.8.3

## Examples

```
packer build -var "account_file=/Users/you/.config/google/your-account-file.json" -var "project_id=XXXXXXXXXXXX" -var "target_image_name=my-packer-bigip-hf" bigip.pkr.hcl
```

ex. with specific SSH Key. 
```
packer build -var "account_file=/Users/you/.config/google/your-account-file.json" -var "project_id=XXXXXXXXXXXX" -var "target_image_name=my-packer-bigip-hf" -var "ssh_private_key_file=~/.ssh/your_key.pem" bigip.pkr.hcl
```

ex. Packer with debug and verbose logging. Helpful for debugging builds as can see what packer is doing as well as login to image being cloned.

```
PACKER_LOG=1 packer build -debug -var "account_file=/Users/you/.config/google/your-account-file.json" -var "project_id=XXXXXXXXXXXX" -var "target_image_name=my-packer-bigip-hf" -var "ssh_private_key_file=~/.ssh/your_key.pem" bigip.pkr.hcl
```


NOTE: 
 - Added "remote_folder": "/var/tmp" due to:
    ```
    Aug 18 09:05:03 ip-172-31-16-138.us-west-2.compute.internal notice shell[3453]: scp -vt /tmp
    Aug 18 09:05:03 ip-172-31-16-138.us-west-2.compute.internal err shell[3514]: path not allowed
    ```