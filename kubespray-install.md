KUBESPRAY_VERSION=2.21
VENV_DIR=kubespray-venv
ANSIBLE_VERSION=2.12

sudo apt install git python3 python3-venv -y

cd ~
git clone https://github.com/kubernetes-sigs/kubespray.git --branch release-$KUBESPRAY_VERSION
cd kubespray

python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate
python3 -m pip install --upgrade pip
pip install -U -r requirements-$ANSIBLE_VERSION.txt

declare -r CLUSTER_DIR='mycluster'
cp -rfp inventory/local inventory/$CLUSTER_DIR
declare -a IPS=(38.242.242.71 38.242.242.71)
CONFIG_FILE=inventory/$CLUSTER_DIR/hosts.yml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

cd inventory/$CLUSTER_DIR
# Enable kubeconfig on localhost in group_vars/k8s_cluster/k8s-cluster.yml
sed -i 's/kubeconfig_localhost: false/kubeconfig_localhost: true/' group_vars/k8s_cluster/k8s-cluster.yml

# Enable kube_proxy_strict_arp in group_vars/k8s_cluster/k8s-cluster.yml
sed -i 's/kube_proxy_strict_arp: false/kube_proxy_strict_arp: true/' group_vars/k8s_cluster/k8s-cluster.yml
# Enable MetalLB in  group_vars/k8s-cluster/addons.yml
sed -i 's/metallb_enabled: false/metallb_enabled: true/' group_vars/k8s-cluster/addons.yml
sed -i 's/# metallb_ip_range:/metallb_ip_range:/' group_vars/k8s_cluster/addons.yml
sed -i 's/#   - "10.5.0.50-10.5.0.99"/  - "10.5.0.50-10.5.0.99"/' group_vars/k8s_cluster/addons.yml


ansible-playbook \
-i hosts.yml \
-c=local \
-b \
cluster.yml

sudo cp -r /root/.kube $HOME
sudo chown -R $USER $HOME/.kube

ansible-playbook \
-i hosts.yml \
-c=local \
-b \
--verbose \
reset.yml
