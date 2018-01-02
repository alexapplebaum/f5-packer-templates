ex.

```
packer build -var "aws_access_key=${AWS_ACCESS_KEY}" -var "aws_secret_key=${AWS_SECRET_KEY}" -var "vpc_id=vpc-2bbaf34e" -var "subnet_id=subnet-b2441ad7" -var "ami_users=111111111111" -var "AWS_TIMEOUT_SECONDS=600" template.json
```

ex. with specific SSH Key
```
packer build -var "aws_access_key=${AWS_ACCESS_KEY}" -var "aws_secret_key=${AWS_SECRET_KEY}" -var "ssh_keypair_name=YOUR-SSH-KEY-NAME" -var "ssh_private_key_file=/Users/example/.ssh/YOUR-SSH-KEY-NAME.pem" -var "vpc_id=vpc-2bbaf34e" -var "subnet_id=subnet-b2441ad7" -var "ami_users=111111111111" -var "AWS_TIMEOUT_SECONDS=600" template.json
```


NOTE: ami_users, an account ID to publish to, is required as we're building from a markteplace AMI and the default settings (which tries to publish to public group "all") won't work.


