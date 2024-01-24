# Terraform-Bulding-K8S-on-AWS

## Architecture
![k8s.png](/k8s.png)

## Description
Create a K8S cluster on AWS EC2 instances. This environment is for the new learners of K8S to build up environments easily. This script will help you to crate the following resources
- 1 EC2 instance as the master node
- 2 EC2 instances as the worker nodes
  
We use the flannel as the CNI for the cluster. Use the `install_k8s_msr.sh` and `install_k8s_wrk.sh` to build up the K8S cluster automatically.

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

