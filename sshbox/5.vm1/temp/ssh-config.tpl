---
- hosts: localhost
  vars:
    configfile: ~/.ssh/config
    marker: "Auto Terraform ${vm}"
    sshkey: /etc/keys/azure-ssh.key
    vm: ${vm}
    user: azureuser
    pub_ip: "${ip}"
  tasks:
  - name: Show IP address
    debug:
      msg: "IP address: {{ pub_ip }}"
  - name: Create SSH config file if not exists
    file:
      path: "{{ configfile }}"
      mode: 0644
      state: touch
  - name: Add VM connection to the SSH config
    blockinfile:
      dest: "{{configfile}}"
      marker: "# {mark} {{ marker }}"
      block: |
        Host {{ vm }}
          User {{user}}
          StrictHostKeyChecking no
          IdentityFile {{ sshkey }}
          Hostname {{ pub_ip }}
          Port 22
