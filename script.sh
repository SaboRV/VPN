export DEBIAN_FRONTEND=noninteractive
mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd
sudo apt update
sudo apt-get install -y traceroute
sudo apt-get install -y net-tools
