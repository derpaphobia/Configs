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
sudo sed -i 's/WaylandEnable=false/# WaylandEnable=false/g' /etc/gdm3/custom.conf

mkdir sites
cd /etc/NetworkManager/dispatcher.d && { sudo curl -O https://raw.githubusercontent.com/derpaphobia/Configs/master/90-mountsites ; cd ; }
sudo chmod +x /etc/NetworkManager/dispatcher.d/90-mountsites

echo "Updating packages..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get autoremove -y

echo "Deleting apt cache.."
sudo apt-get clean

echo "Making /lib/systemd/system-sleep/sleep executable...\n"
sudo chmod a+x /lib/systemd/system-sleep/sleep

read -rp "Do you want to replace suspend with hibernate? (type yes or no) " usehibernate;echo

if [ "$usehibernate" = "yes" ]; then
	if [ "$LX_BASE" = "ubuntu" ] && [ 1 -eq "$(echo "${LX_VERSION} >= 17.10" | bc)" ]; then
		echo "Using Hibernate instead of Suspend...\n"
		sudo ln -sfb /lib/systemd/system/hibernate.target /etc/systemd/system/suspend.target && sudo ln -sfb /lib/systemd/system/systemd-hibernate.service /etc/systemd/system/systemd-suspend.service
	else
		echo "Using Hibernate instead of Suspend...\n"
		sudo ln -sfb /usr/lib/systemd/system/hibernate.target /etc/systemd/system/suspend.target && sudo ln -sfb /usr/lib/systemd/system/systemd-hibernate.service /etc/systemd/system/systemd-suspend.service
	fi
else
	echo "Not touching Suspend\n"
fi

read -rp "Do you want use the patched libwacom packages? (type yes or no) " uselibwacom;echo

if [ "$uselibwacom" = "yes" ]; then
	echo "Installing patched libwacom packages..."
	    curl -LSO https://github.com/derpaphobia/Configs/raw/master/libwacom_0.32-surface-1_amd64.deb
		sudo dpkg -i libwacom_0.32-surface-1_amd64.deb
		sudo apt-mark hold libwacom
		sudo rm libwacom_0.32-surface-1_amd64.deb
else
	echo "Not touching libwacom"
fi

echo "Installing all your crap.."
sudo apt-get -y install build-essential cmake qt5-default wget libxtst-dev libxinerama-dev libice-dev libxrandr-dev libavahi-compat-libdnssd-dev libcurl4-openssl-dev libssl-dev dh-make gnome-tweak-tool curl wget flatpak gnome-software-plugin-flatpak snapd exfat-utils ffmpeg gimp gimp-plugin-registry gnome-shell-extension-appindicator htop inkscape krita mpv nautilus-image-converter p7zip papirus-icon-theme tilix gitg nano zsh zsh-syntax-highlighting fortune-mod nautilus-nextcloud steam lutris fonts-firacode xournalpp gnome-shell-extension-no-annoyance barrier network-manager-openvpn-gnome discord nautilus-admin

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

echo "Adding goodies.."

###
# Theming and GNOME Options
###

# Tilix as default terminal
gsettings set org.gnome.desktop.default-applications.terminal exec /usr/bin/tilix
ln -s /etc/profile.d/vte-2.91.sh /etc/profile.d/vte.sh

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

#Nautilus (File Manager) Usability
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'
gsettings set org.gnome.nautilus.preferences executable-text-activation 'ask'
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.nautilus.list-view use-tree-view true

echo "Changing shell.."
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
curl -LSO https://raw.githubusercontent.com/derpaphobia/Configs/master/.zshrc
source ~/.zshrc

#The user needs to reboot to apply all changes.
echo "Please Reboot" && exit 0
