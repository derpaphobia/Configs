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
# Installing apps..
###

sudo curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
sudo dnf install -y docker nano epel-release wireguard-dkms wireguard-tools

sudo curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

###
# Fixing/mapping/formattings drives
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


# Adding swap to boot options
offset=$(sudo swap-offset /swapfile | grep -o 'resume offset = .*' | cut -d" " -f4-)
uuid=$(sudo blkid -s UUID -o value /dev/sda3)
sudo kernelstub -a "resume=UUID=$uuid resume_offset=$offset resumedelay=15"
sudo touch /etc/initramfs-tools/conf.d/resume
echo "RESUME=UUID=$uuid resume_offset=$offset" | sudo tee /etc/initramfs-tools/conf.d/resume > /dev/null
sudo update-initramfs -u -k all


###
# Cleaning apt cache and removing /Configs folder
###

sudo apt-get clean
sudo rm -r ~/Configs


###
# Installing oh-my-zsh and changing shell to zsh
###

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" && chsh -s $(which zsh)
