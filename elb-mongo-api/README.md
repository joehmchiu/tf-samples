# Mongo API with AWS ELB
## Summary
This sample will create an ELB for instance and deploy the Mongo API in the VM.

## Tools
* Terraform version > 0.12
* Ansible playbook
* Python flask
* docker ubuntu

## Config
* update ssh key in terraform.tfvar
* update MongoDB account details in terraform.tfvar

## RUN
1. terraform init
2. terraform plan
3. terraform apply -auto-approve
4. eval $(terraform output mongo_api | sed 's/"//g')
5. eval $(terraform output mongo_dns | sed 's/"//g')

Please note it could need to wait for 5 minutes for the elb dns service.

## Clean Up
* terraform destroy -auto-approve

