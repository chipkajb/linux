#! /bin/bash

# DIRECTIONS:
# 1. Run this script (./install_vim.sh)
# 2. Open up ~/.vimrc
# 3. Install all plugins (:PluginInstall)
# 4. Make sure libclang is installed (sudo apt-get install -y libclang-dev)
# 5. Change the path to libclang.so to the proper path in ~/.vimrc

rm -rf /home/$USER/.vim
rm -rf /home/$USER/.vimrc

cp -r ../config/.vim /home/$USER 2>/dev/null 
cp ../config/.vimrc /home/$USER 2>/dev/null 

rm -rf /home/$USER/.vim/bundle
git clone https://github.com/VundleVim/Vundle.vim.git /home/$USER/.vim/bundle/Vundle.vim
