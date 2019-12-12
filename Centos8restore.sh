#!/bin/bash
if [ $(id -u) = 0 ]; then
   echo "This script changes your users gsettings and should thus not be run as root!"
   echo "You may need to enter your password multiple times!"
   exit 1
fi



###
# Updating
###

sudo apt-get update -y
sudo apt-get upgrade -y


###
# Installing apps and adding repos..
###

sudo add-apt-repository -y ppa:andreasbutti/xournalpp-master
sudo apt-get -yqq install build-essential cmake qt5-default wget libxtst-dev libxinerama-dev libice-dev libxrandr-dev libavahi-compat-libdnssd-dev libcurl4-openssl-dev libssl-dev dh-make gnome-tweak-tool curl wget flatpak gnome-software-plugin-flatpak snapd exfat-utils ffmpeg gimp gimp-plugin-registry gnome-shell-extension-appindicator htop inkscape krita mpv nautilus-image-converter p7zip papirus-icon-theme tilix gitg nano zsh zsh-syntax-highlighting fortune-mod nautilus-nextcloud steam lutris fonts-firacode xournalpp gnome-shell-extension-no-annoyance barrier network-manager-openvpn-gnome discord nautilus-admin uswsusp php nodejs npm network-manager libnss3-tools jq xsel php-pear php7.2-dev php7.2-curl php7.2-zip php7.2-sqlite3 php7.2-mysql php7.2-pgsql libmcrypt-dev libreadline-dev cifs-utils mariadb-server spotify-client code glances
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

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
