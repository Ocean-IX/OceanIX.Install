#!/bin/bash
	  
OSARCH=$(uname -m)
OCEANIX_DIR=/root/oceanixp
OCEANIX_CONFIG="$OCEANIX_DIR"/data
OCEANIX_LOGS="$OCEANIX_CONFIG"/logs
OCEANIX_PANEL="$OCEANIX_CONFIG"/www


OCEANIX_IF=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
IP_ADDR=$(curl -s https://api.ipify.org)

if [[ "$os" == "ubuntu" && "$os_version" -lt 1804 ]]; then
	echo "Ubuntu 18.04 or higher is required to use this installer. This version of Ubuntu is too old and unsupported."
	exit
fi
if [[ "$EUID" -ne 0 ]]; then
	echo "This installer needs to be run with superuser privileges."
	exit
fi
clear;

os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
group_name="nogroup"
add-apt-repository main 2>&1 >> /dev/null
add-apt-repository universe 2>&1 >> /dev/null
add-apt-repository restricted 2>&1 >> /dev/null
add-apt-repository multiverse 2>&1 >> /dev/null

echo "Adding Repos"
echo "...... Docker Repo ....."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -;
sudo apt-key fingerprint 0EBFCD88;
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
echo "Updating OS (apt-get update)"
apt-get -qy update > /dev/null;
echo "Updating OS (apt-get upgrade)"
apt-get -qy upgrade > /dev/null;
echo "Installing Dependancies... "
apt-get -qy install htop iftop sudo vnstat curl nano python3 python3-pip screen software-properties-common apt-transport-https ca-certificates git zip unzip dialog iotop ioping dsniff tcpdump lsb-release > /dev/null;
echo "Auto Remove non-required installs (apt-get autoremove)"
apt-get -qy autoremove > /dev/null;
echo "Set VNSTAT Default Interface to '$OCEANIX_IF'"
sed -i 's/eth0/$OCEANIX_IF/g' /etc/vnstat.conf;
echo "Install Docker"
apt-get -qy install docker-ce docker-ce-cli containerd.io > /dev/null;
echo "Adding Docker-Compose Functionality"
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
echo "Set non-requirement of \"Sudo\" for docker commands"
sudo groupadd docker;
sudo usermod -aG docker $USER;
sudo usermod -aG www-data $USER;
sudo systemctl enable docker;

echo "Lets.. GIT UP!"

git clone http://github.com/Ocean-IX/OceanIX-Config.git $OCEANIX_CONFIG
git clone http://github.com/Ocean-IX/OceanIX.Control.git $OCEANIX_PANEL

echo "Lets start configuring! (ADD STUFF HERE)"

