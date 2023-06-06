#! /bin/bash

# install zsh
sudo apt install zsh -y

# # To change the default shell for root, run the following commands:
# sudo -s
# chsh -s /bin/zsh root

# change default shell to root for user
chsh -s $(which zsh) # must enter password here

# install oh my zsh
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh

# install neovim
wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
sudo mv ./nvim.appimage /usr/bin
sudo chmod 764 /usr/bin/nvim.appimage

# install NvChad
mv ~/.config/nvim ~/.config/nvim.backup 2> /dev/null
rm -rf ~/.local/share/nvim/
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1

# move custom nvim config
cp ../config/nvim/custom/* ~/.config/nvim/lua/custom
cp -r ../config/nvim/after ~/.config/nvim
