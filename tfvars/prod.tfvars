aws_region    = "us-east-1"
environment   = "prod"
app_name      = "mywebapp"
vpc_id        = "vpc-09ba6d5a99230fa69"
subnet_ids    = ["subnet-02e7c3a75b13b7a8d", "subnet-0bd4f1b1292eb34b1"]
ec2_subnet_id = "subnet-02e7c3a75b13b7a8d"
instance_type = "t3.medium"
ami_id        = "ami-0f7a0c94dce9ab456"
key_pair_name = "devops-jenkins"

enable_deletion_protection = true
multi_az                   = true
backup_retention_days      = 7