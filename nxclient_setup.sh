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

    #Disable Gnome Keyring

    #Set Static IP address
    
    
else 
    echo -e "\n\n~~ Installation cancelled ~~\n"
fi