
WS='/tmp/workspace'

if [ -e $WS ]; then
  if [ -e "$WS/main.tf" ]; then
    echo "Backup workspace exists, pass..."
    # echo "0. Clean Up"
    # echo "terraform destroy -auto-approve"
    # sudo cd $WS
    # sudo terraform init
    # sudo terraform destroy -auto-approve
  fi
else
  echo "0. Create Backup Workspace"
  echo "sudo mkdir -p $WS"
  sudo mkdir -p $WS
fi

echo "1. Deploy VM"
echo "terraform init"
sudo terraform init
echo "terraform apply -auto-approve"
sudo terraform apply -auto-approve

echo "2. Backup the deployment details"
sudo cp -rf * $WS/.

echo "3. Deploy and Install Application"
echo "ansible-playbook -i hosts -e "token=xxxxxxxxxxxx" playbook.yml"
sudo ansible-playbook -i hosts -e "token=pGj0b7PmBH2KD3Wi" playbook.yml

echo "TESTS..."

echo "4. test Create"
sh test/create.sh
sleep 3

echo "5. test Read"
sh test/read.sh
sleep 3

echo "6. test Update"
sh test/update.sh
sleep 3

echo "7. test Delete"
sh test/delete.sh

echo "8. Done!"


# echo "8. Clean Up"
# echo "terraform destroy -auto-approve"
# terraform destroy -auto-approve
