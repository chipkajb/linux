#! /bin/bash

sudo apt-get update

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
ln -s $PWD/../config/nvim/after ~/.config/nvim
ln -s $PWD/../config/nvim/custom ~/.config/nvim/lua/

# install nerd font
mkdir -p ~/software
git clone git@github.com:ryanoasis/nerd-fonts.git
cd nerd-fonts && ./install.sh && cd .. && mv nerd-fonts ~/software/

# install ripgrep (for grep searching with Telescope)
sudo apt-get install ripgrep -y

# install pyenv (needed for neovim python linter)
sudo apt install python3.8-venv -y

# install black (needed for neovim python auto-formatter)
sudo python3 -m pip install black

# install pacman
wget https://gitlab.com/trivoxel-utils/deb-pacman/uploads/460d83f8711c1ab5e16065e57e7eeabc/deb-pacman-2.0-0.deb
sudo dpkg -i deb-pacman-2.0-0.deb
rm deb-pacman-2.0-0.deb

# install tmux
sudo apt-get remove tmux -y
sudo apt-get purge tmux -y
sudo apt install libevent-dev
wget https://github.com/tmux/tmux/releases/download/3.3a/tmux-3.3a.tar.gz
tar -xf tmux-3.3a.tar.gz
rm tmux-3.3a.tar.gz
cd tmux-3.3a && ./configure && make && sudo make install && cd ..
mkdir -p ~/software
mv tmux-3.3a ~/software/
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# move tmux config folder
ln -s $PWD/../config/tmux ~/.config/
