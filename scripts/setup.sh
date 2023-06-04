#! /bin/bash

# install zsh
sudo apt install zsh -y

# To change the default shell for root, run the following commands:
#sudo -s
#chsh -s /bin/zsh root

# change default shell to root for user
chsh -s $(which zsh) # must enter password here

# install oh my zsh
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh

# install neovim
wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
sudo mv ./nvim.appimage /usr/bin
sudo chmod 764 /usr/bin/nvim.appimage

# install nerd font
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.1/Mononoki.zip
mkdir Mononoki
mv Mononoki.zip Mononoki
cd Mononoki && unzip Mononoki.zip && rm Mononoki.zip && cd ..
mv Mononoki ~/.fonts
fc-cache -fv

# install NvChad
mv ~/.config/nvim ~/.config/nvim.backup 2> /dev/null
rm -rf ~/.local/share/nvim/
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
