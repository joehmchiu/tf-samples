# Mongo API with AWS EC2
## Summary
This sample will create an EC2 instance, deploy the Mongo API in the VM and proceed the CRUD tests.

## Synopsis
A pre-design for CI / CD pipelines.

## Tools
* Terraform version > 0.12
* Ansible playbook
* Python flask
* docker ubuntu
* curl requests / bash

## Config
### terraform.tfvar
* update ssh key in terraform.tfvar
* update MongoDB account details in terraform.tfvar
### scripts/ssh-config.tpl
* update sshkey to the key downloaded from EC2 key pairs

## RUN
$ sh run.sh <br>
OR
1. terraform init
2. terraform plan
3. terraform apply -auto-approve

## CURL URI
* curl $(terraform output mongo_api | sed 's/"//')

## Clean Up
* terraform destroy -auto-approve

