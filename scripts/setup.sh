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
