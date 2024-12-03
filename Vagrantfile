# -*- mode: ruby -*-
# vi: set ft=ruby :

# Sources:
# https://github.com/therealhalonen/domain_control

Vagrant.configure("2") do |config|

  # Master
  config.vm.define "master" do |ms|
    ms.vm.box = "debian/bookworm64"
    ms.vm.network "private_network", ip: "192.168.56.100"
    ms.vm.hostname = "master"
    ms.vm.provision "shell", inline: $master
    ms.vm.provider :virtualbox do |vb|
      vb.name = "Master"
    end
  end

  # Homeserver
  config.vm.define "homeserver" do |hs|
    hs.vm.box = "debian/bookworm64"
    hs.vm.network "private_network", ip: "192.168.56.101"
    hs.vm.hostname = "homeserver"
    hs.vm.provision "shell", inline: $linux
    hs.vm.provider :virtualbox do |vb|
      vb.name = "Homeserver"
    end
  end
end

$master = <<MASTER
apt update
apt install -y bash-completion vim curl git
mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | sudo tee /etc/apt/keyrings/salt-archive-keyring.pgp
curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources | sudo tee /etc/apt/sources.list.d/salt.sources
apt update
apt install -y salt-master nfs-common
mkdir -p /srv/salt
systemctl restart salt-master.service
systemctl restart nfs-common.service
MASTER

$linux = <<LINUX
apt update
apt install -y bash-completion vim curl
mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | sudo tee /etc/apt/keyrings/salt-archive-keyring.pgp
curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources | sudo tee /etc/apt/sources.list.d/salt.sources
apt update
apt install -y salt-minion
echo "id: $HOSTNAME" > /etc/salt/minion.d/id.conf
echo "master: 192.168.56.100" > /etc/salt/minion.d/master.conf
systemctl restart salt-minion.service
LINUX
