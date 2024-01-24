# Terraform-Bulding-K8S-on-AWS

## Architecture
![k8s.png](/k8s.png)

## Varibales

|Name|Description|
|---|---|
|"access_key"|"Access key to AWS console"|
|"secret_key"|"Secret key to AWS console"|
|"ami_key_pair_name"|"keypair to access ec2 instance"|
|"number_of_worker"|"the number of worker instances to be joined on the cluster."|
|"The region zone on AWS"|"choose AWS region"|
|"The AMI to use"|"put AMI ID: ami-XXXXXXXXXXXXXXX" |
| "instance_type"|"put EC2 type"|

## Output
|Name|Description|
|---|---|
|"instance_msr_public_ip"|"Public address IP of master"|
|"instance_wrks_public_ip"|"Public address IP of worker"|

