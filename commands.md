# Create SSH key
```shell
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519 -C "Turing Pi SSH key"
ssh-copy-id -i ~/.ssh/id_ed25519 root@turingpi.local
```

# Login to turingpi.local and set hostnames
`sshpass -p turing ssh root@turingpi.local`
```shell
tpi uart --node 1 set --cmd 'ubuntu'
tpi uart --node 1 set --cmd 'ubuntu'
tpi uart --node 1 set --cmd 'ubuntu'
tpi uart --node 1 set --cmd 'password'
tpi uart --node 1 set --cmd 'password'
tpi uart --node 1 get
tpi uart --node 1 set --cmd 'sudo hostnamectl set-hostname node-rk1'
tpi uart --node 1 set --cmd 'hostname'
tpi uart --node 1 get

tpi uart --node 2 set --cmd 'ubuntu'
tpi uart --node 2 set --cmd 'ubuntu'
tpi uart --node 2 set --cmd 'ubuntu'
tpi uart --node 2 set --cmd 'password'
tpi uart --node 2 set --cmd 'password'
tpi uart --node 2 get
tpi uart --node 2 set --cmd 'sudo hostnamectl set-hostname node-rk2'
tpi uart --node 2 set --cmd 'hostname'
tpi uart --node 2 set --cmd 'sudo reboot'
tpi uart --node 2 get

tpi uart --node 3 set --cmd 'ubuntu'
tpi uart --node 3 set --cmd 'ubuntu'
tpi uart --node 3 set --cmd 'ubuntu'
tpi uart --node 3 set --cmd 'password'
tpi uart --node 3 set --cmd 'password'
tpi uart --node 3 get
tpi uart --node 3 set --cmd 'sudo hostnamectl set-hostname node-rk3'
tpi uart --node 3 set --cmd 'hostname'
tpi uart --node 3 set --cmd 'sudo reboot'
tpi uart --node 3 get

tpi uart --node 4 set --cmd 'ubuntu'
tpi uart --node 4 set --cmd 'ubuntu'
tpi uart --node 4 set --cmd 'ubuntu'
tpi uart --node 4 set --cmd 'password'
tpi uart --node 4 set --cmd 'password'
tpi uart --node 4 get
tpi uart --node 4 set --cmd 'sudo hostnamectl set-hostname node-rk4'
tpi uart --node 4 set --cmd 'hostname'
tpi uart --node 4 set --cmd 'sudo reboot'
tpi uart --node 4 get
```
# Copy over the ssh keys
```shell
ssh-copy-id -i ~/.ssh/id_ed25519 ubuntu@node-rk1
ssh-copy-id -i ~/.ssh/id_ed25519 ubuntu@node-rk2
ssh-copy-id -i ~/.ssh/id_ed25519 ubuntu@node-rk3
ssh-copy-id -i ~/.ssh/id_ed25519 ubuntu@node-rk4
```
# WSL
```shell
export ANSIBLE_CONFIG=./ansible.cfg
ansible -m ping all
ansible-playbook playbooks/create-partition.yaml
ansible-playbook playbooks/install-kubernetes.yaml
```

# Create partition
```shell
lsblk -f
sudo gdisk /dev/nvme0n1
n
1
2048
1953525134
8300
w
y
sudo mkfs.ext4 /dev/nvme0n1p1
```

# Mount partition
```shell
lsblk -f
sudo mkdir /mnt/storage
echo "/dev/nvme0n1p1 /mnt/storage ext4 defaults 0 0" | sudo tee -a /etc/fstab
sudo reboot
```
