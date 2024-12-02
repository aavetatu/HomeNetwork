# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.network "private_network", ip: "192.168.56.31"

  config.vm.hostname = "homeserver"
  
  config.vm.provision "shell", inline: <<-SHELL
    apt update
    apt install -y bash-completion vim curl
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | sudo tee /etc/apt/keyrings/salt-archive-keyring.pgp
    curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources | sudo tee /etc/apt/sources.list.d/salt.sources
    apt update
    apt install -y salt-minion
    echo "id: homeserver" > /etc/salt/minion.d/id.conf
    echo "master: 192.168.56.10" > /etc/salt/minion.d/master.conf
    systemctl restart salt-minion.service
  SHELL
end
