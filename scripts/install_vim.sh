#! /bin/bash

# DIRECTIONS:
# 1. Run this script (./install_vim.sh)
# 2. Make sure libclang is installed (sudo apt-get install -y libclang-dev)
# 3. Change path to libclang.so in ~/.vimrc

rm -rf /home/$USER/.vim
rm -rf /home/$USER/.vimrc

ln -s $PWD/../config/.vim /home/$USER
ln -s $PWD/../config/.vimrc /home/$USER

rm -rf /home/$USER/.vim/bundle
git clone https://github.com/VundleVim/Vundle.vim.git /home/$USER/.vim/bundle/Vundle.vim
vim +PluginInstall +qall > /dev/null

printf "\nVIM setup complete."
printf "\nRemember to change path to libclang.so in ~/.vimrc"
printf "\nCurrent path is:\n"
cat ~/.vimrc | grep libclang.so | awk '{print $2}' | cut -c 23- | head -c-2
printf "\nCorrect path is:\n"
find /usr/lib/ -iname libclang.so
