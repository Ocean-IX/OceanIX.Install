#!/bin/bash
if [[ "$EUID" -ne 0 ]]; then
	echo "This installer needs to be run with superuser privileges."
	exit
fi

echo "Enter IPv6 Subnet (WITH CIDR) eg, 2000:3000:4000:5000/64 : "  
read v6Subnet  

apt-get -yq remove docker docker-engine docker.io containerd runc

apt-get -yq update

apt-get -yq install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  htop \
  iftop \
  sudo \
  vnstat \
  curl \
  git \
  nano \
  wget \
  atop \
  iotop \
  ioping \
  dsniff \
  ndppd \
  tcpdump \
  software-properties-common
  
echo "Adding Repos"
add-apt-repository main 2>&1 >> /dev/null
add-apt-repository universe 2>&1 >> /dev/null
add-apt-repository restricted 2>&1 >> /dev/null
add-apt-repository multiverse 2>&1 >> /dev/null

  echo "...... Docker Repo ....."
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

echo "Verify that you now have the finger print [9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88]"
apt-key fingerprint 0EBFCD88

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

echo "Doing some updates..."
apt-get -qy update
echo "Installing Docker CE, CE-CLI and ContainerD"
apt-get install -qy docker-ce docker-ce-cli containerd.io

echo "Setting user stuffs"
usermod -aG docker $USER
echo "Enabling Docker"
systemctl enable docker
systemctl start docker

echo "Confirming Docker is operating"
docker version

echo "Get Docker Compose Binary"
wget  https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)
sudo mv ./docker-compose-$(uname -s)-$(uname -m) /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose
export PATH=$PATH:/usr/bin/docker-compose
echo "export PATH=$PATH:/usr/bin/docker-compose" >>  $HOME/.bash_profile
echo "Confirming Docker-Compose is operating"
docker-compose --version

echo "Getting OceanIXP Config & Data Files"
git clone http://github.com/Ocean-IX/OceanIX-Config.git /tmp/OceanIXP
chmod +x /tmp/OceanIXP/bin/*
mv /tmp/OceanIXP/bin/* /bin
cp -rlf /tmp/OceanIXP/* /
rm -rf /tmp/OceanIXP

git clone http://github.com/Ocean-IX/OceanIX.Control.git /opt/oceanixp/www

echo "Setting up IPv6 Connectivity"
sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "ipv6": true,
  "fixed-cidr-v6": "$(v6Subnet)"
}
EOF
sed -i 's/0000:0000:0000:0000/$(v6Subnet)/g' /opt/oceanixp/yml/docker-compose.yml

echo "net.ipv6.conf.eth0.proxy_ndp=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

sudo tee /etc/ndppd.conf > /dev/null << "EOF"
route-ttl 5000
proxy eth0
{
    router yes
    timeout 500
    ttl 30000
  
    # docker bridge
    rule $(v6Subnet):c1::/80
    {
        auto
    }
}
EOF

sudo kill $(cat /var/run/ndppd.pid)
sudo rm /var/run/ndppd.pid
sudo systemctl restart ndppd

sudo systemctl restart docker

start_oceanixp

IP_ADDR=$(curl -s https://api.ipify.org)
clear
echo ""
echo -e "\e[32m      ::::::::   ::::::::  ::::::::::     :::     ::::    ::: ::::::::::: :::    ::: \e[1m"
echo -e "\e[32m    :+:    :+: :+:    :+: :+:          :+: :+:   :+:+:   :+:     :+:     :+:    :+:  \e[1m"
echo -e "\e[32m   +:+    +:+ +:+        +:+         +:+   +:+  :+:+:+  +:+     +:+      +:+  +:+    \e[1m"
echo -e "\e[32m  +#+    +:+ +#+        +#++:++#   +#++:++#++: +#+ +:+ +#+     +#+       +#++:+      \e[1m"
echo -e "\e[32m +#+    +#+ +#+        +#+        +#+     +#+ +#+  +#+#+#     +#+      +#+  +#+      \e[1m"
echo -e "\e[32m#+#    #+# #+#    #+# #+#        #+#     #+# #+#   #+#+#     #+#     #+#    #+#      \e[1m"
echo -e "\e[32m########   ########  ########## ###     ### ###    #### ########### ###    ###       \e[1m"
echo -e "\e[0m"
echo ""
echo "Access Web-Installer: http://$IP_ADDR:9999"
echo "One-Time Password for Installer: NOTYETCOMPLETED"
echo ""
