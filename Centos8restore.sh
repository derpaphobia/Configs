#!/bin/bash
if [ $(id -u) = 0 ]; then
   echo "NO ROOT PLEASE! Also..."
   echo "You may need to enter your password multiple times!"
   exit 1
fi



###
# Updating
###

sudo dnf upgrade -y --refresh

###
# Fixing grub entries for stupid MSI mobo
###
sudo sed -i 's/swap rhgb quiet/swap rhgb quiet radeon.dpm=0/' /etc/default/grub
sudo grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg

###
# Fixing/mapping/formatting drives
###

mkdir media nextcloud
sudo mkfs.xfs -f /dev/sda
sudo mkfs.xfs -f /dev/sdb
sudo mount /dev/sda /home/derpa/nextcloud
sudo mount /dev/sdb /home/derpa/media
sudo chown derpa:derpa /home/derpa/nextcloud
sudo chown derpa:derpa /home/derpa/media
sudo chmod 777 /home/derpa/nextcloud
sudo chmod 777 /home/derpa/media
sudo umask=777 /home/derpa/nextcloud
sudo umask=777 /home/derpa/media

sdbuuid=$(sudo blkid -s UUID -o value /dev/sdb)
sdauuid=$(sudo blkid -s UUID -o value /dev/sda)

echo UUID=$sdauuid  /home/derpa/nextcloud     xfs   defaults 0  0 | sudo tee /etc/fstab -a >/dev/null 2>&1
echo UUID=$sdbuuid  /home/derpa/media     xfs   defaults 0  0 | sudo tee /etc/fstab -a >/dev/null 2>&1

sleep 1

###
# Installing apps..
###

sudo curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
sudo dnf install -y docker nano epel-release wireguard-dkms wireguard-tools samba wget

sudo curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

###
# Samba shares
###
wget https://raw.githubusercontent.com/derpaphobia/Configs/master/server/smb.conf
sudo mv smb.conf /etc/samba/smb.conf


echo "DO NOT FORGET, put Integrity Wireguard file in /etc/wireguard then run sudo wg-quick up integrity_vpn & sudo systemctl enable wg-quick@integrity_vpn"
echo "DO NOT FORGET, set samba password with sudo smbpasswd -a <user_name>"
