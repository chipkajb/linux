#! /bin/bash

rm -rf /home/$USER/.vim
rm -rf /home/$USER/.vimrc

cp -r ../config/.vim /home/$USER 2>/dev/null 
cp ../config/.vimrc /home/$USER 2>/dev/null 

rm -rf /home/$USER/.vim/bundle
git clone https://github.com/VundleVim/Vundle.vim.git /home/$USER/.vim/bundle/Vundle.vim
