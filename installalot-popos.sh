#!/bin/bash
if [ $(id -u) = 0 ]; then
   echo "This script changes your users gsettings and should thus not be run as root!"
   echo "You may need to enter your password multiple times!"
   exit 1
fi

echo "Adding repos.."
sudo add-apt-repository universe
sudo add-apt-repository -y ppa:andreasbutti/xournalpp-master

echo "Applying fixes.."
gsettings set com.system76.hidpi enable false
gsettings set org.gnome.desktop.interface clock-format 24h
sudo sed -i 's/<FK21> = 199;/#<FK21> = 199;/g' /usr/share/X11/xkb/keycodes/evdev
sudo sed -i 's/<FK22> = 200;/#<FK22> = 200;/g' /usr/share/X11/xkb/keycodes/evdev
sudo sed -i 's/<FK23> = 201;/#<FK23> = 201;/g' /usr/share/X11/xkb/keycodes/evdev
sudo sed -i 's/#LidSwitchIgnoreInhibited=yes/LidSwitchIgnoreInhibited=no/g' /usr/share/X11/xkb/keycodes/evdev
sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=ignore/g' /usr/share/X11/xkb/keycodes/evdev
sudo sed -i 's/#LidSwitchIgnoreInhibited=yes/LidSwitchIgnoreInhibited=no/g' /etc/systemd/logind.conf
sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=ignore/g' /etc/systemd/logind.conf
sudo sed -i 's/WaylandEnable=false/# WaylandEnable=false/g' /etc/gdm3/custom.conf
sudo sed -i 's/AutoEnable=true/AutoEnable=false/g' /etc/bluetooth/main.conf



mkdir sites
cd /etc/NetworkManager/dispatcher.d && { sudo curl -O https://raw.githubusercontent.com/derpaphobia/Configs/master/90-mountsites ; cd ; }
sudo chmod +x /etc/NetworkManager/dispatcher.d/90-mountsites

echo "Updating packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Deleting apt cache.."
sudo apt-get clean

echo "Installing patched libwacom packages..."
curl -LSO https://github.com/derpaphobia/Configs/raw/master/libwacom_0.32-surface-1_amd64.deb
sudo dpkg -i libwacom_0.32-surface-1_amd64.deb
sudo apt-mark hold libwacom
sudo rm libwacom_0.32-surface-1_amd64.deb
		
echo "Installing all your crap.."
sudo apt-get -y install build-essential cmake qt5-default wget libxtst-dev libxinerama-dev libice-dev libxrandr-dev libavahi-compat-libdnssd-dev libcurl4-openssl-dev libssl-dev dh-make gnome-tweak-tool curl wget flatpak gnome-software-plugin-flatpak snapd exfat-utils ffmpeg gimp gimp-plugin-registry gnome-shell-extension-appindicator htop inkscape krita mpv nautilus-image-converter p7zip papirus-icon-theme tilix gitg nano zsh zsh-syntax-highlighting fortune-mod nautilus-nextcloud steam lutris fonts-firacode xournalpp gnome-shell-extension-no-annoyance barrier network-manager-openvpn-gnome discord nautilus-admin uswsusp php

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

sudo snap install spotify
sudo snap install code --classic

sleep 1

echo "Making keybinds.."
curl -LJO https://raw.githubusercontent.com/derpaphobia/Configs/master/keybinds.conf
dconf load / < keybinds.conf
rm keybinds.conf

echo "Removing some stuff.."
sudo apt-get remove totem chromium flowblade
sudo apt-get autoremove -y

echo "Adding goodies.."

###
# VsCode config
###
curl -LSO https://raw.githubusercontent.com/derpaphobia/Configs/master/settings.json
mv -f settings.json ~/.config/Code/User/settings.json

###
# Setup Valet Linux
###
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"



###
# Adding Hibernate
###

sudo swapoff -a
sudo dd if=/dev/zero of=/swapfile bs=1024 count=16M
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapoff -a
sudo swapon /swapfile
sudo sed -i '/cryptswap/s/^/# /' /etc/fstab
sudo sed -i '/cryptswap/a/swapfile  none  swap  sw  0  0' /etc/fstab

offset=$(sudo swap-offset /swapfile | grep -o 'resume offset = .*' | cut -d" " -f4-)
uuid=$(sudo blkid -s UUID -o value /dev/sda3)
sudo kernelstub -a "resume=UUID=$uuid resume_offset=$offset resumedelay=15"
sudo touch /etc/initramfs-tools/conf.d/resume
echo "RESUME=UUID=$uuid resume_offset=$offset" | sudo tee /etc/initramfs-tools/conf.d/resume > /dev/null
sudo update-initramfs -u -k all

sudo mkdir -p /etc/polkit-1/rules.d/ && sudo touch /etc/polkit-1/rules.d/85-suspend.rules  
echo "polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.suspend" ||
        action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
        action.id == "org.freedesktop.login1.hibernate" ||
        action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
    {
        return polkit.Result.YES;
    }
});" | sudo tee /etc/polkit-1/rules.d/85-suspend.rules > /dev/null

sudo mkdir -p /var/lib/polkit-1/localauthority/50-local.d/ && sudo touch /var/lib/polkit-1/localauthority/50-local.d/50-enable-suspend-on-lockscreen.pkla
echo "[Allow hibernation and suspending with lock screen]
Identity=unix-user:*
Action=org.freedesktop.login1.suspend;org.freedesktop.login1.suspend-multiple-sessions;org.freedesktop.login1.hibernate;org.freedesktop.login1.hibernate-multiple-sessions
ResultAny=yes
ResultInactive=yes
ResultActive=yes" | sudo tee /var/lib/polkit-1/localauthority/50-local.d/50-enable-suspend-on-lockscreen.pkla > /dev/null

echo -e "[Service]                           
ExecStart=
ExecStartPre=-/bin/run-parts -v -a pre /lib/systemd/system-sleep
ExecStart=/usr/sbin/s2disk
ExecStartPost=-/bin/run-parts -v --reverse -a post /lib/systemd/system-sleep" | sudo SYSTEMD_EDITOR=tee systemctl edit systemd-hibernate.service > /dev/null

sudo systemctl daemon-reload

#Disables lockscreen on resume
gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'

#Activate Suspend-then-Hibernate
sudo touch /etc/systemd/sleep.conf
echo "[Sleep]
HibernateDelaySec=3600" | sudo tee /etc/systemd/sleep.conf
sudo ln -s /usr/lib/systemd/system/systemd-suspend-then-hibernate.service /etc/systemd/system/systemd-suspend.service

###
# Theming and GNOME Options
###

# Tilix as default terminal
gsettings set org.gnome.desktop.default-applications.terminal exec /usr/bin/tilix
sudo ln -s /etc/profile.d/vte-2.91.sh /etc/profile.d/vte.sh

# Tilix Dark Theme
gsettings set com.gexperts.Tilix.Settings theme-variant 'dark'
curl -LJO https://raw.githubusercontent.com/derpaphobia/Configs/master/tilixderpa.conf
dconf load /com/gexperts/Tilix/ < tilixderpa.conf
rm tilixderpa.conf

#Better Font Smoothing
gsettings set org.gnome.settings-daemon.plugins.xsettings antialiasing 'rgba'

#Usability Improvements
gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'adaptive'
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true
gsettings set org.gnome.desktop.calendar show-weekdate true
gsettings set org.gnome.desktop.wm.preferences resize-with-right-button true
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.shell.overrides workspaces-only-on-primary false
gsettings set org.gnome.desktop.interface gtk-theme "Pop-slim-dark"
gsettings set org.gnome.desktop.interface text-scaling-factor 1.3

#Nautilus (File Manager) Usability
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'
gsettings set org.gnome.nautilus.preferences executable-text-activation 'ask'
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.nautilus.list-view use-tree-view true

echo "Changing shell.."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
curl -LSO https://raw.githubusercontent.com/derpaphobia/Configs/master/.zshrc
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" && chsh -s $(which zsh)

read -rp "Do you want to reboot? (type yes or no) " doreboot;echo
if [ "$doreboot" = "yes" ]; then
	chsh -s $(which zsh) && sudo reboot
else
	echo "WATAFAKMAAAAN, not rebooting even though you should.. stupid.."
	chsh -s $(which zsh)
fi
#The user needs to reboot to apply all changes.
echo "Please Reboot" && exit 0

