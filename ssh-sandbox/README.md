# Mongo API with AWS ELB
## Summary
This sample will fully create two VMs in Azure cloud platform including vnet, subnet, nsg, nic, public ip, vm and create the ssh access straight away.

## Tools
* Terraform version > 0.12
* Ansible playbook

## Config
### terraform.tfvar
* update ssh key in terraform.tfvar
### scripts/ssh-config.tpl
* update sshkey to use self generated ssh key hash

## RUN
* cd ssh-sandbox
* for i in `ls | sort`; do echo $i; cd $i; ll; terraform init; terraform apply -auto-approve; cd ..; done

## Clean Up
* cd ssh-sandbox
* for i in `ls | sort -r`; do echo $i; cd $i; ll; terraform destroy -auto-approve; cd ..; done
* for i in `ls -d */ | sort`; do echo $i; cd $i; ll -a; rm -rf .terraform* terraform.tfstate*; cd ..; done
Please note for some reason osdisk is not destroyed, manual task may need for the osdisk clean up.
