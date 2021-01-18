#!/bin/bash
if [[ "$EUID" -ne 0 ]]; then
	echo "This installer needs to be run with superuser privileges."
	exit
fi

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
mkdir -p /opt/oceanixp/data/log/oceanixp
touch /opt/oceanixp/data/log/oceanixp/shell.log
chmod 777 /opt/oceanixp/data/log/oceanixp/shell.log

git clone http://github.com/Ocean-IX/OceanIX.Control.git /opt/oceanixp/www

read -p "Use BIRD for BGP Session to Upstream?" -n 1 -r
echo  ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
sed -i 's/&/ /g' /opt/oceanixp/yml/docker-compose.yml
fi

read -p "Network Range (Without Last Octet- ie 10.10.10: "  localNetwork
echo "Setting $localNetwork as Local Network Range"
sed -i 's/10.10.1/$localNetwork/g' /opt/oceanixp/yml/docker-compose.yml

read -p "Include ZeroTier for Virtual Connections?" -n 1 -r
echo  ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
read -p "ZeroTier Network ID: "  zeroNetwork
echo "Setting $zeroNetwork!"
sed -i 's/0000000000000000/$zeroNetwork/g' /opt/oceanixp/yml/docker-compose.yml
sed -i 's/!//g' /opt/oceanixp/yml/docker-compose.yml
fi

read -p "Include WireGuard for Virtual IX Connections?" -n 1 -r
echo  ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
sed -i 's/%/ /g' /opt/oceanixp/yml/docker-compose.yml
fi

read -p "Include OpenVPN for Virtual IX Connections?" -n 1 -r
echo  ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
sed -i 's/^/ /g' /opt/oceanixp/yml/docker-compose.yml
fi

read -p "Include Alice-LG as Looking Glass?" -n 1 -r
echo  ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
sed -i 's/@/ /g' /opt/oceanixp/yml/docker-compose.yml
fi


read -p "Build OceanIXP Locally? (if N, will grab newest updated files from DockerHub)" -n 1 -r
echo  ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
build_ixp
echo "Done!"
exit
fi

sed -i 's/&/#/g' /opt/oceanixp/yml/docker-compose.yml
sed -i 's/!/#/g' /opt/oceanixp/yml/docker-compose.yml
sed -i 's/%/#/g' /opt/oceanixp/yml/docker-compose.yml
sed -i 's/^/#/g' /opt/oceanixp/yml/docker-compose.yml
sed -i 's/@/#/g' /opt/oceanixp/yml/docker-compose.yml

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
echo "ReportIXP: http://$IP_ADDR:9999"
echo "One-Time Password for Installer: NOTYETCOMPLETED"
echo ""
