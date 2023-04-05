#!/bin/bash
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

clear

echo -e "\nThese scripts will setup this machine for ISO NX Witness.\n\nPlease select one of the following options:"
echo -e "\n[1] - Prepare secondary storage drive"
echo -e "[2] - Install NX Witness Server"
echo -e "[3] - Install NX Witness Client & boot setup"
echo -e "[4] - Set static IP address"
echo -e "[0] - Exit"
read ANSWER

while [ $ANSWER != '0' ]
do
    if [ $ANSWER == '1' ]
    then
        echo -e "\n !!WARNING!! If you continue, the storage drive will be completely erased! Are you sure you want to continue?"
        echo "Type 'yes' to continue, type anything else to abort"
        read ANSWER

        if [ $ANSWER == 'yes' ]
        then
            #Format the disk and partition
            sgdisk -Z /dev/sda
            echo -e "\n~~Disk has been wiped~~"
            sgdisk -N=0 /dev/sda
            echo -e "\n~~Partition has been created~~"
            DISKID=`ls -l /dev/disk/by-id | awk 'NR==3{print $9}'`
            mkfs.ext4 /dev/sda1 -F

            #Mount the disk partition
            mkdir /mnt/storage
            mount /dev/sda1 /mnt/storage

            #Add to Fstab if not already done
            if ! grep -q 'storage-disk' /etc/fstab ; then
                echo '# storage-disk' >> /etc/fstab
                echo '/dev/sda1  /mnt/storage  ext4  defaults  0  0' >> /etc/fstab
            fi

        else
        echo -e "\n~~Installation aborted~~"
        exit
        fi

        ANSWER='x'

    elif [ $ANSWER == '2' ]
    then

        apt-get update
        apt-get dist-upgrade -y
 
        #apt-get install dstat htop nano gdisk wget -y
        timedatectl set-timezone Pacific/Auckland

        wget https://updates.networkoptix.com/default/35745/linux/nxwitness-server-5.0.0.35745-linux_x64.deb
        apt install ./nxwitness-server-5.0.0.35745-linux_x64.deb -y

        ANSWER='x'
        
    elif [ $ANSWER == '3' ]
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
        update-grub

        #download config files and coppy to right locations
        git clone https://github.com/plastikjames/MHC_Video
        cp -r ./MHC_Video/configs/isolimited /usr/share/plymouth/themes
        update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/isolimited/isolimited.plymouth 100
        echo 2 | update-alternatives --config default.plymouth
        echo -e "\n\n~~~~ now updating initramfs. This can take a moment so please wait. ~~~~"
        update-initramfs -u

        #Setup greeter config
        touch /etc/lightdm/lightdm.conf.d/greeter.conf
        echo "[Seat:*]" > /etc/lightdm/lightdm.conf.d/greeter.conf
        echo "greeter-session=slick-greeter" >> /etc/lightdm/lightdm.conf.d/greeter.conf

        touch /etc/lightdm/slick-greeter.conf
        echo "[Greeter]" > /etc/lightdm/slick-greeter.conf
        echo "background=/usr/share/plymouth/themes/isolimited/mhc-background.png" >> /etc/lightdm/slick-greeter.conf

        #Disable Gnome Keyring
        mv /usr/bin/gnome-keyring-daemon /usr/bin/gnome-keyring-daemon.bak 
        touch /usr/bin/gnome-keyring-daemon
        chmod a+rx /usr/bin/gnome-keyring-daemon

        #Configure Auto-login
        touch /etc/lightdm/lightdm.conf
        echo "[Seat:*]" > /etc/lightdm/lightdm.conf
        echo "user-session=myxclient" >> /etc/lightdm/lightdm.conf
        echo "autologin-user=mhcoperator" >> /etc/lightdm/lightdm.conf
        echo "autologin-user-timeout=20" >> /etc/lightdm/lightdm.conf
        echo "#xserver-command = X -nocursor" >> /etc/lightdm/lightdm.conf
        echo "display-setup-script=/usr/local/bin/dpms-stop" >> /etc/lightdm/lightdm.conf

        touch /usr/share/xsessions/myxclient.desktop
        echo "[Desktop Entry]" > /usr/share/xsessions/myxclient.desktop
        echo "Name=NXWitness" >> /usr/share/xsessions/myxclient.desktop
        echo "Comment=NX" >> /usr/share/xsessions/myxclient.desktop
        echo "Exec=//opt/networkoptix/client/5.0.0.35745/bin/client-bin --window-geometry=0,0,1920x1080" >> /usr/share/xsessions/myxclient.desktop
        echo "Icon=" >> /usr/share/xsessions/myxclient.desktop
        echo "Type=Application" >> /usr/share/xsessions/myxclient.desktop

        #Disable sleep and suspend
        touch /usr/local/bin/dpms-stop
        echo "#!/bin/sh" > /usr/local/bin/dpms-stop
        echo "sudo xhost +si:mhcoperator:lightdm" >> /usr/local/bin/dpms-stop
        echo "sudo su lightdm -s /bin/bash" >> /usr/local/bin/dpms-stop
        echo "/usr/bin/xset -dpms" >> /usr/local/bin/dpms-stop
        echo "/usr/bin/xset s off" >> /usr/local/bin/dpms-stop
        echo "exit" >> /usr/local/bin/dpms-stop

        chmod +x /usr/local/bin/dpms-stop

        #Remove downloaded files
        rm -r ./MHC_Video
        echo -e "\n\n~~Installation complete - please reboot the machine and use the GUI to configure NX witness display. ~~"

        ANSWER='x'

    elif [ $ANSWER == '4' ]
    then
        #Set Static IP address
        echo -e "\nTo set the IP address, please follow the prompts:"
            # Gather input from user
            read -p "Type the IP address in CIDR notation, i.e. 192.168.1.1/24: " IP_ADDRESS
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
        ANSWER='x'
    else 
    echo -e "\nPlease select one of the following options:"
    echo -e "\n[1] - Prepare secondary storage drive"
    echo -e "[2] - Install NX Witness Server"
    echo -e "[3] - Install NX Witness Client & boot setup"
    echo -e "[4] - Set static IP address"
    echo -e "[0] - Exit"
    read ANSWER
        
    fi

done
echo -e "\n\n~~ Installation exited - Please reboot for any changes to take effect~~\n"