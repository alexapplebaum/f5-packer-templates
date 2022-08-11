# Creating HF PAYG CLONE

## Requirements

- SSH Key
- Account with permissions to launch images

- An existing Resource Group to Store Images. Azure CLI example to create: 

    ```
    REGION="westus"
    RESOURCE_GROUP="packer-images"
    STORAGE_ACCOUNT_NAME="packerimagestor"

    az group create -n ${RESOURCE_GROUP} -l ${REGION}
    az storage account create -n ${STORAGE_ACCOUNT_NAME} -g ${RESOURCE_GROUP} -l ${REGION}
    ```

- An existing storage account to provide boot diagnostics. Azure CLI example to create: 

    ```
    REGION="westus"
    RESOURCE_GROUP="packer-bootdiag"
    STORAGE_ACCOUNT_NAME="packerdiagstor"

    az group create -n ${RESOURCE_GROUP} -l ${REGION}
    az storage account create -n ${STORAGE_ACCOUNT_NAME} -g ${RESOURCE_GROUP} -l ${REGION}
    ```

## Configuration Notes

- Tested with Packer 1.8.3

## Examples

```
packer build -var "subscription_id=${ARM_SUBSCRIPTION_ID}" -var "tenant_id=${ARM_TENANT_ID}" -var "client_id=${ARM_CLIENT_ID}" -var "client_secret=${ARM_CLIENT_SECRET}" -var "managed_image_resource_group_name=myImageRG" -var "boot_diag_storage_account=mybootdiagstoracct" -var "image_name=myPackerImageBigipHF" bigip.pkr.hcl
```

ex. with specific SSH Key. 
```
packer build -var "subscription_id=${ARM_SUBSCRIPTION_ID}" -var "tenant_id=${ARM_TENANT_ID}" -var "client_id=${ARM_CLIENT_ID}" -var "client_secret=${ARM_CLIENT_SECRET}" -var "image_name=myPackerImageBigipHF" -var "managed_image_resource_group_name=myImageRG" -var "boot_diag_storage_account=mybootdiagstoracct" -var "ssh_private_key_file=~/.ssh/your_key.pem" bigip.pkr.hcl
```

ex. Packer with debug and verbose logging. Helpful for debugging builds as can see what packer is doing as well as login to image being cloned.

```
PACKER_LOG=1 packer build -var "subscription_id=${ARM_SUBSCRIPTION_ID}" -var "tenant_id=${ARM_TENANT_ID}" -var "client_id=${ARM_CLIENT_ID}" -var "client_secret=${ARM_CLIENT_SECRET}" -var "image_name=myPackerImageBigipHF" -var "managed_image_resource_group_name=myImageRG" -var "boot_diag_storage_account=mybootdiagstoracct" -var "ssh_private_key_file=~/.ssh/your_key.pem" bigip.pkr.hcl
```


NOTE: 
 - Added "remote_folder": "/var/tmp" due to:
    ```
    Aug 18 09:05:03 ip-172-31-16-138.us-west-2.compute.internal notice shell[3453]: scp -vt /tmp
    Aug 18 09:05:03 ip-172-31-16-138.us-west-2.compute.internal err shell[3514]: path not allowed
    ```