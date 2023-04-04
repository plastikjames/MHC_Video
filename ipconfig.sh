#! /usr/bin/env bash

# Gather input from user
read -p "Now type the IP address in CIDR notation, i.e. 192.168.1.1/24: " IP_ADDRESS
read -p "The gateway IP: " GATEWAY_ADDRESS
read -p "The primary DNS IP: " PRIMARY_DNS_ADDRESS
read -p "And finally, the secondary DNS IP: " SECONDARY_DNS_ADDRESS

# Create a new netplan yaml config file
touch 99-custom.yaml

#get nic info
apt install net-tools -y
NIC=`ifconfig | awk 'NR==1{print $1}'`

# Apply network config to netplan yaml config file
# Making some assumptions here about the adapter name
echo "network:" > 99-custom.yaml
echo "  ethernets:" >> 99-custom.yaml
echo "    $NIC" >> 99-custom.yaml
echo "      dhcp4: false" >> 99-custom.yaml
echo "      addresses: [$IP_ADDRESS]" >> 99-custom.yaml
echo "      gateway4: $GATEWAY_ADDRESS" >> 99-custom.yaml
echo "      nameservers:" >> 99-custom.yaml
echo "        addresses: [$PRIMARY_DNS_ADDRESS, $SECONDARY_DNS_ADDRESS]" >> 99-custom.yaml
echo "  version: 2" >> 99-custom.yaml

# Copy the custom config to the netplan folder and apply
cp 99-custom.yaml /etc/netplan/99-custom.yaml
rm 99-custom.yaml

# Apply the new config
sudo netplan apply

