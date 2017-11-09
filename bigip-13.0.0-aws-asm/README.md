ex.

```
packer build -var "aws_access_key=${AWS_ACCESS_KEY}" -var "aws_secret_key=${AWS_SECRET_KEY}" -var "vpc_id=vpc-2bbaf34e" -var "subnet_id=subnet-b2441ad7" -var "ami_users=111111111111" template.json
```

NOTE: ami_users, an account ID to publish to, is required as we're building from a markteplace AMI and the default settings (which tries to publish to public group "all") won't work.


