# Implementing salt on home network

## Installing vagrant

I started by installing vagrant 

	$ mkdir -p projects/salt-stack && cd projects/salt-stack
	$ sudo apt install -y vagrant

After installation I made new virtual machine with vagrant

	$ vagrant init debian/bullseye64
	$ vagrant up && vagrant ssh
	$ whoami
	vagrant

After I had logged in I updated package list and upgraded software

	$ sudo apt update && sudo apt upgrade -y

## Installing salt master

For installing salt I used [official salt installation guide](https://docs.saltproject.io/salt/install-guide/en/latest/topics/install-by-operating-system/linux-deb.html)

I started by ensuring keyrings directory exists

    $ sudo mkdir -p etc/apt/keyrings

I downloaded public key
	
	curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | sudo tee /etc/apt/keyrings/salt-archive-keyring.pgp

I got an error because my VM didn't have curl installed

	$ sudo apt install -y curl
	$ curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | sudo tee /etc/apt/keyrings/salt-archive-keyring.pgp

I created apt repository for target configuration

	$ curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources | sudo tee /etc/apt/sources.list.d/salt.sources

I updated package lists and installed salt-master on my VM

	$ sudo apt update && sudo apt install -y salt-master
	$ salt --version
	salt 3007.1 (Chlorine)

### First salt state

For making my first salt state, I used a [guide](https://terokarvinen.com/2018/salt-states-i-want-my-computers-like-this/) made by Tero Karvinen

I started by making a directory for Master where it can give instruction to Minions

	$ sudo mkdir -p /srv/salt/

I made a hello world state

	$ sudoedit /srv/salt/hello.sls
	$ cat /srv/salt/hello.sls
	/tmp/hellotatu.txt:
	  file.managed:
	    - source: salt://hellotatu.txt

After I had made the applied the state locally

	$ sudo salt-call --local state.apply hello
	$ cat /tmp/hellotatu.txt
	Hello World!

I confirmed the state works by removing the file and applying the state again

	$ sudo rm /tmp/hellotatu.txt
	$ sudo salt-call --local state.apply hello
	$ cat /tmp/hellotatu.txt
	Hello World!

I had to use `sudo rm` to remove hellotatu.txt because of its permissions

	$ ls -l /tmp/hellotatu.txt
	-rw-r--r-- 1 root root 13 Nov 21 21:18 /tmp/hellotatu.txt

### Making Vagrantfile

Next I wanted to make my own vagrantfile for debian11 salt-master so I wouldn't need to configure everything manually every time I make a new virtual machine

    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    Vagrant.configure("2") do |config|
      # The most common configuration options are documented and commented below.
      # For a complete reference, please see the online documentation at
      # https://docs.vagrantup.com.

      # Every Vagrant development environment requires a box. You can search for
      # boxes at https://vagrantcloud.com/search.
      config.vm.box = "debian/bullseye64"
      
      # For some reason this address has to be 192.168.56.0/21
      # 192.168.56.10 is used for salt-master and other machines will be given
      # another ip in ascending order
      config.vm.network "private_network", ip: "192.168.56.10"

      config.vm.provision "shell", inline: <<-SHELL
        apt-get update
        apt-get install -y bash-completion vim curl
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | sudo tee /etc/apt/keyrings/salt-archive-keyring.pgp
        curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources | sudo tee /etc/apt/sources.list.d/salt.sources
        apt update
        apt install -y salt-master
      SHELL
    end


I ended up making some testing with salt and ended up using these commands

    $ sudo salt-call --local grains.items
    $ sudo salt-call --local grains.item ipv4

## Setting up salt master and salt minion

I had made a Vagrantfile which installs salt-master when booted up for the first time
I booted up salt-master and salt-minion and tested if connection between them works by pinging minion on master

    $ ip a | grep "192"
    inet 192.168.56.10/24 brd 192.168.56.255 scope global eth1

    $ ping 192.168.56.11
    PING 192.168.56.11 (192.168.56.11) 56(84) bytes of data.
    64 bytes from 192.168.56.11: icmp_seq=1 ttl=64 time=0.441 ms

I also installed salt-minion on minion

    sudo apt install -y salt-minion

I made configuration files on minion to recognize master

    $ cat /etc/salt/minion.d/id.conf
    id: minion
    $ cat /etc/salt/minion.d/master.conf
    master: 192.168.56.10

I started master and minion services on their respective machines
Restrarting `salt-minion.service` should send key to master to be accepted

    $ sudo systemctl start salt-minion.service
    $ sudo systemctl start salt-master.service

I tried to accept key from minion but `salt-key` gave error
This was because `salt-key` has to be run as superuser

    $ sudo salt-key
    Accepted Keys:
    Denied Keys:
    Unaccepted Keys:
    minion
    Rejected Keys:
    vagrant@bullseye:~$ sudo salt-key -a "minion"
    The following keys are going to be accepted:
    Unaccepted Keys:
    minion
    Proceed? [n/Y] y
    Key for minion minion accepted.

I tested if the connection between master and minion really works after accepting key

    $ sudo salt '*' grains.item ipv4
    minion:
        ----------
        ipv4:
            - 10.0.2.15
            - 127.0.0.1
            - 192.168.56.11

### Pushing first state to minion

Because I had made new clean VM for master, I needed to make a directory for salt states
I used same instructions as I used for making "### First salt state" at the start of this report 
    
	$ sudo mkdir -p /srv/salt/
	$ sudoedit /srv/salt/hello.sls
	$ cat /srv/salt/hello.sls
	/tmp/hellotatu.txt:
	  file.managed:
	    - source: salt://hellotatu.txt

Before running the state, I tested if minion already had `/tmp/hellotatu.txt`

    $ cat /tmp/hellotatu.txt
    cat: /tmp/hellotatu.txt: No such file or directory

Next I applied the state on master

    $ sudo salt '*' state.apply hello
    minion:
    ----------
              ID: /tmp/hellotatu.txt
        Function: file.managed
          Result: True
         Comment: File /tmp/hellotatu.txt updated
         Started: 12:01:18.749778
        Duration: 19.155 ms
         Changes:
                  ----------
                  diff:
                      New file
                  mode:
                      0644
    
    Summary for minion
    ------------
    Succeeded: 1 (changed=1)
    Failed:    0
    ------------
    Total states run:     1
    Total run time:  19.155 ms

And confirmed if minion now had `hellotatu.txt`

    $ cat /tmp/hellotatu.txt
    Hello World!

## Sources


[Salt install guide](https://docs.saltproject.io/salt/install-guide/en/latest/topics/install-by-operating-system/linux-deb.html)

[Salt States – I Want My Computers Like This](https://terokarvinen.com/2018/salt-states-i-want-my-computers-like-this/) made by Tero Karvinen
