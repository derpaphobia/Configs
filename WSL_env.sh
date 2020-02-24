#!/bin/bash

### Genie, systemd for wsl ##
curl -s https://packagecloud.io/install/repositories/arkane-systems/wsl-translinux/script.deb.sh | sudo bash
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
###

sudo add-apt-repository ppa:neovim-ppa/stable -y
curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -
sudo apt-get upgrade ; sudo apt-get update
sudo apt-get install neovim curl wget zsh nodejs python3 python3-pip libboost-all-dev libyaml-cpp-dev libcurl4 libcurl4-openssl-dev git cmake build-essential libgcrypt20-dev libyajl-dev libboost-all-dev libexpat1-dev libcppunit-dev binutils-dev debhelper zlib1g-dev dpkg-dev pkg-config dotnet-sdk-3.1 systemd-genie -y

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install -y
sudo curl -sL install-node.now.sh/lts | bash
pip3 install pynvim --upgrade

sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -y
wget -q https://raw.githubusercontent.com/derpaphobia/Configs/master/resources/configfiles/.zshrc -O ~/.zshrc
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
wget -q https://raw.githubusercontent.com/derpaphobia/Configs/master/resources/configfiles/.vimrc -O ~/.vimrc


mkdir -p ~/.config/nvim
touch ~/.config/nvim/init.vim

sudo tee -a ~/.config/nvim/init.vim <<EOT
set runtimepath^=~/.vim runtimepath+=~/.vim/after"
let &packpath = &runtimepath
source ~/.vimrc
EOT

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

curl -fLo ~/.vim/colors/PaperColor.vim --create-dirs \
	https://raw.githubusercontent.com/NLKNguyen/papercolor-theme/master/colors/PaperColor.vim

sudo sed -i 's/sudo nano/sudo nvim/g' ~/.zshrc
echo 'alias python="python3"' | sudo tee -a ~/.zshrc


### For ls_extended ###

git clone https://github.com/Electrux/ccp4m.git ; cd ccp4m ; ./build.sh ; sudo mv bin/ccp4m /usr/local/bin/ccp4m ; cd
git clone https://github.com/Electrux/ls_extended.git ; cd ls_extended ; ./build.sh ; sudo mv bin/ls_extended /usr/local/bin/ls_extended ; cd
sudo rm -rf ls_extended ccp4m
echo 'alias ls="ls_extended"' | sudo tee -a ~/.zshrc
#######################

echo '!!!DON'T forget to install a nerdfont and change default fonts in the emulator!!!'
echo 'Delugia nerdfont: https://github.com/adam7/delugia-code/releases?WT.mc_id=-blog-scottha'
source ~/.zshrc
