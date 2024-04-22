export DEBIAN_FRONTEND=noninteractive
            mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
            sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
            systemctl restart sshd
apt-get update
apt-get install -y mc
apt-get install -y openvpn iperf3 selinux-utils
setenforce 0
reboot
