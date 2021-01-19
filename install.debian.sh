#!/bin/bash
if [[ "$EUID" -ne 0 ]]; then
	echo "This installer needs to be run with superuser privileges."
	exit
fi
IP_ADDR=$(curl -s https://api.ipify.org)
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

echo "Getting Dockerfiles.."
mkdir -p /opt/oceanixp/yml/build_ixp
        echo "Retrieve Files: oceanixau/zerotier.docker:multi"
        /usr/bin/git clone --single-branch --branch multi  https://github.com/RouteIX/zerotier.docker.git /opt/oceanixp/yml/build_ixp/zerotier.docker-multi
        echo "Retrieve Files: oceanixau/zerotier.docker"
        /usr/bin/git clone --single-branch --branch master https://github.com/RouteIX/zerotier.docker.git /opt/oceanixp/yml/build_ixp/zerotier.docker
        echo "Retrieve Files: oceanixau/wireguard.docker"
        /usr/bin/git clone --single-branch --branch master https://github.com/Ocean-IX/wireguard.docker.git /opt/oceanixp/yml/build_ixp/wireguard.docker
	echo "Retrieve Files: oceanixau/openvpn.docker"
        /usr/bin/git clone --single-branch --branch master https://github.com/Ocean-IX/openvpn.docker.git /opt/oceanixp/yml/build_ixp/openvpn.docker
	echo "Retrieve Files: oceanixau/bird.rs.docker"
        /usr/bin/git clone --single-branch --branch master https://github.com/Ocean-IX/bird.rs.docker.git /opt/oceanixp/yml/build_ixp/bird.rs.docker
	echo "Retrieve Files: oceanixau/rs.gen.docker"
        /usr/bin/git clone --single-branch --branch master https://github.com/Ocean-IX/rs.gen.docker.git /opt/oceanixp/yml/build_ixp/rs.gen.docker
	echo "Retrieve Files: oceanixau/reportixp.docker"
        /usr/bin/git clone --single-branch --branch master https://github.com/Ocean-IX/reportixp.docker.git /opt/oceanixp/yml/build_ixp/reportixp.docker

git clone http://github.com/Ocean-IX/OceanIX.Control.git /opt/oceanixp/www

read -p "Use BIRD for BGP Session to Upstream?" -n 1 -r
echo  ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
add-apt-repository ppa:cz.nic-labs/bird
apt-get -qy install bird
read -p "Listen Address: "  bgpListen
echo "Setting $bgpListen"
read -p "Your ASN (NUMBERS ONLY): "  bgpASN
echo "Setting $bgpASN"
read -p "UPSTREAM ASN (NUMBERS ONLY): "  bgpUpASN
echo "Setting $bgpUpASN"
read -p "Neighbour IP: "  bgpUpNeigh
echo "Setting $bgpUpNeigh"
read -p "Anchor Subnet: "  bgpAnchor
echo "Setting $bgpAnchor"

rm rf /etc/bird/bird6.conf
cat >> /etc/bird/bird6.conf <<EOL
router id $IP_ADDR;

listen bgp address $bgpListen port 180;

log syslog { debug, trace, info, remote, warning, error, auth, fatal, bug };
log stderr all;

protocol kernel {
#       learn;                  # Learn all alien routes from the kernel
        persist;                # Don't remove routes on bird shutdown
        scan time 20;           # Scan kernel routing table every 20 seconds
#       import none;            # Default is import all
        export none;            # Default is export none
#       kernel table 5;         # Kernel table to synchronize with (default: main)
}

protocol static export_routes {
    route $bgpAnchor via $bgpListen;
    route 2a0a:6040:dead::/48 via $bgpListen;
    route 2a0a:6040:beef::/48 via $bgpListen;
}

protocol device {
        scan time 60;           # Scan interfaces every 10 seconds
}

# Disable automatically generating direct routes to all network interfaces.
protocol direct {
        disabled;               # Disable by default
}

protocol bgp {
        import all;
        export where proto = "export_routes";
        local as $bgpASN;
        neighbor $bgpUpNeigh as $bgpUpASN;
}

EOL

systemctl restart bird6
systemctl enable bird6
fi


read -p "Include ZeroTier for Virtual Connections?" -n 1 -r
echo  ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
read -p "ZeroTier Network ID: "  zeroNetwork
echo "Setting $zeroNetwork!"
cat >> /opt/oceanixp/yml/docker-compose.yml <<EOL

  zerotier:
    container_name: ZeroTier
    build: build_ixp/zerotier.docker-multi/.
    environment:
      - NETWORK_ID=$zeroNetwork
      - NETWORK_REGIONAL=93afae59635b25f9
    volumes:
      - /opt/oceanixp/data/zerotier:/config
    network_mode: host
    privileged: true
    restart: always
EOL
fi


start_oceanixp



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
