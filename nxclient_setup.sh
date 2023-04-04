#!/bin/bash
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

echo -e "\nThis script will setup this machine as an ISO NX Witness viewer.\n\nDo you want to continue? (Type 'yes' to confirm)"
read ANSWER

if [ $ANSWER == 'yes' ]
then
    #Do the install

    #Add the user
    adduser mhcoperator --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password

    #Install the packages
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt install lightdm plymouth-themes slick-greeter -y
    echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
    wget https://updates.networkoptix.com/default/35745/linux/nxwitness-client-5.0.0.35745-linux_x64.deb
    apt install ./nxwitness-client-5.0.0.35745-linux_x64.deb -y
    
    #Config grub
    sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="quiet splash"/g' /etc/default/grub
    update grub

    #download config files and coppy to right locations
    git clone https://github.com/plastikjames/MHC_Video
    

    #Disable Gnome Keyring

    #Set Static IP address
    echo -e "\nWould you like to set a static IP address? (Type 'yes' to confirm)"
    read ANSWER2
    if [ $ANSWER2 == 'yes' ]
    then
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
    fi
else 
    echo -e "\n\n~~ Installation cancelled ~~\n"
fi