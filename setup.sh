#! /bin/bash

# define script parameters
ACTION_LIST=(0 1 2 3 4 5 6 7 8)
DESC_LIST=(
    "Exit" 
    "Install zsh"
    "Install vim" 
    "Install neovim"
    "Install VS Code" 
    "Install tmux" 
    "Install i3" 
    "Install alacritty"
    "Install all"
)

# define text colors
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# check that both lists have the same size
if [ "${#ACTION_LIST[@]}" -ne "${#DESC_LIST[@]}" ];
then
    printf "${RED}ERROR: ${NC}Action list and description list must be the same lengths.\n"
    printf "Action list length: "
    printf "${CYAN}${#ACTION_LIST[@]}\n${NC}"
    printf "Description list length: "
    printf "${CYAN}${#DESC_LIST[@]}\n${NC}"
    exit
fi

# print possible actions
print_possible_actions() {
    printf "\nPossible actions:\n"
    for (( i=0; i<${#ACTION_LIST[@]}; i++ )); do
        ACTION="${ACTION_LIST[i]}"
        DESC="${DESC_LIST[i]}"

        printf "   ${CYAN}$ACTION.${NC} $DESC\n"
    done
}

# check if input is not in action list
check_bad_input() {
    local user_input=$1
    # check if integer
    re='^[0-9]+$'
    if ! [[ $user_input =~ $re ]] ; then
        return 0 # true, bad input
    fi
    for element in "${ACTION_LIST[@]}"; do
        # check if in list
        if [ "$element" -eq "$user_input" ]; then
            return 1 # false, good input
        fi
    done
    return 0 # true, bad input
}

# prompt user
prompt_user() {
    printf "What would you like to do?"
    print_possible_actions
    printf "Enter one of the possible options above ${YELLOW}["
    for (( i=0; i<${#ACTION_LIST[@]}; i++ )); do
        printf "${ACTION_LIST[i]}"
        if (( $i < ${#ACTION_LIST[@]}-1 )); then printf ", "; fi
    done
    printf "]${NC}: "
}

# install zsh
install_zsh() {
    printf "Installing zsh...\n"
    sudo apt-get update
    sudo apt install zsh -y
    chsh -s $(which zsh)
    wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
    python utils/append_zshrc.py
    printf "${GREEN}DONE${NC} -- zsh installed to ${YELLOW}$(which zsh)${NC} as ${YELLOW}$(zsh --version)${NC}\n"
}

# install vim
install_vim() {
    printf "Installing vim...\n"
    sudo apt-get update
    sudo apt-get install -y libclang-dev
    rm -rf /home/$USER/.viminfo 2> /dev/null
    rm -rf /home/$USER/.vim 2> /dev/null
    rm -rf /home/$USER/.vimrc 2> /dev/null

    ln -s $PWD/config/vim /home/$USER/.vim
    ln -s $PWD/config/vimrc /home/$USER/.vimrc

    rm -rf /home/$USER/.vim/bundle
    mkdir -p ~/.vim/bundle
    git clone https://github.com/VundleVim/Vundle.vim.git /home/$USER/.vim/bundle/Vundle.vim
    vim +PluginInstall +qall > /dev/null

    printf "\nRemember to change path to libclang.so in ~/.vimrc"
    printf "\nCurrent path is:\n"
    cat ~/.vimrc | grep libclang.so | awk '{print $2}' | cut -c 23- | head -c-2
    printf "\nCorrect path is:\n"
    find /usr/lib/ -iname libclang.so
    printf "${GREEN}DONE${NC} -- vim installed, vimrc file located at ${YELLOW}$(ls ~/.vimrc)${NC}\n"
}

# install neovim
install_neovim() {
    printf "Installing neovim...\n"
    wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
    sudo mv ./nvim.appimage /usr/bin
    sudo chmod 764 /usr/bin/nvim.appimage
    rm -rf ~/.local/share/nvim/ 2> /dev/null
    rm -rf ~/.config/nvim/ 2> /dev/null
    git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
    rm -rf ~/.config/nvim/after 2> /dev/null
    ln -s $PWD/config/nvim/after ~/.config/nvim
    rm -rf ~/.config/nvim/lua/custom/ 2> /dev/null
    ln -s $PWD/config/nvim/custom ~/.config/nvim/lua/
    sudo apt-get install ripgrep -y
    sudo apt-get install python3.8-venv -y
    sudo apt-get install jq -y
    sudo python3 -m pip install black
    printf "${GREEN}DONE${NC} -- neovim installed, ${YELLOW}$(/usr/bin/nvim.appimage --version | head -n 1)${NC}\n"
}

# install vs code
install_vscode() {
    printf "Installing VS Code...\n"
    sudo apt update
    sudo apt install software-properties-common apt-transport-https wget
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
    sudo apt install code -y
    code --install-extension Atishay-Jain.All-Autocomplete
    code --install-extension ms-python.black-formatter
    code --install-extension IronGeek.vscode-env
    code --install-extension ZainChen.json
    code --install-extension esbenp.prettier-vscode
    code --install-extension ms-python.vscode-pylance
    code --install-extension ms-python.python
    code --install-extension mechatroner.rainbow-csv
    code --install-extension tickleforce.scrolloff
    code --install-extension vscodevim.vim
    code --install-extension Ransh.ransh
    ln -sfn $PWD/config/vscode/settings.json ~/.config/Code/User/
    ln -sfn $PWD/config/vscode/keybindings.json ~/.config/Code/User/
    printf "${GREEN}DONE${NC} -- VS Code installed to ${YELLOW}$(which code)${NC} -- ${YELLOW}v$(code --version | head -n 1)${NC}\n"
}

# install tmux
install_tmux() {
    printf "Installing tmux...\n"
    sudo apt-get update
    sudo apt-get remove tmux -y
    sudo apt-get purge tmux -y
    rm -rf ~/.config/tmux 2> /dev/null
    sudo apt-get install libevent-dev xclip -y
    wget https://github.com/tmux/tmux/releases/download/3.3a/tmux-3.3a.tar.gz
    tar -xf tmux-3.3a.tar.gz
    rm tmux-3.3a.tar.gz
    cd tmux-3.3a && ./configure && make && sudo make install && cd ..
    mkdir -p ~/software
    rm -rf ~/software/tmux-3.3a 2> /dev/null
    mv tmux-3.3a ~/software/
    rm -rf ~/.tmux/plugins/tpm 2> /dev/null
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ln -s $PWD/config/tmux ~/.config/
    rm -rf tmux* 2> /dev/null
    printf "${GREEN}DONE${NC} -- tmux installed to ${YELLOW}$(which tmux)${NC} -- ${YELLOW}$(tmux -V)${NC}\n"
}

# install i3
install_i3() {
    printf "Installing i3...\n"
    sudo apt-get update
    sudo apt-get install i3 feh arandr blueman lxappearance rofi compton i3blocks -y
    rm -rf ~/.config/i3 2> /dev/null
    rm ~/Pictures/background.png 2> /dev/null
    ln -s $PWD/config/i3 ~/.config/
    ln -s $PWD/assets/background.png ~/Pictures/
    ln -s $PWD/assets/fonts ~/.fonts
    ln -sfn $PWD/config/gtk/settings.ini ~/.config/gtk-3.0
    ln -sfn $PWD/config/gtk/gtkrc-2.0 ~/.gtkrc-2.0
    ln -sfn $PWD/config/rofi ~/.config/
    sudo ln -sfn $PWD/config/i3/gpu_memory /usr/share/i3blocks
    printf "${GREEN}DONE${NC} -- i3 installed to ${YELLOW}$(which i3)${NC} -- ${YELLOW}$(i3 --version)${NC}\n"
}

# install alacritty
install_alacritty() {
    printf "Installing alacritty...\n"
    sudo apt-get update
    sudo add-apt-repository ppa:aslatter/ppa -y
    sudo apt install alacritty -y
    sudo update-alternatives --config x-terminal-emulator
    rm -rf ~/.config/alacritty 2> /dev/null
    ln -s $PWD/config/alacritty ~/.config/
    mkdir -p ~/.config/alacritty/themes
    git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes
    printf "${GREEN}DONE${NC} -- alacritty installed to ${YELLOW}$(which alacritty)${NC} -- ${YELLOW}$(alacritty --version)${NC}\n"
}

# main loop
exit_condition=false
while [ "$exit_condition" = false ]; do
    # execute prompt
    prompt_user
    read user_input
    if
        check_bad_input $user_input;
    then
        printf "${RED}Bad input\n${NC}";
    else
        # check exit condition
        if [[ "$user_input" -eq 0 ]]; then
            printf "Exiting...\n"
            exit
        fi

        # install zsh
        if [[ "$user_input" -eq 1 ]]; then
            install_zsh
        fi

        # install vim
        if [[ "$user_input" -eq 2 ]]; then
            install_vim
        fi

        # install neovim
        if [[ "$user_input" -eq 3 ]]; then
            install_neovim
        fi

        # install vscode
        if [[ "$user_input" -eq 4 ]]; then
            install_vscode
        fi

        # install tmux
        if [[ "$user_input" -eq 5 ]]; then
            install_tmux
        fi

        # install i3
        if [[ "$user_input" -eq 6 ]]; then
            install_i3
        fi

        # install alacritty
        if [[ "$user_input" -eq 7 ]]; then
            install_alacritty
        fi
       
        # install all
        if [[ "$user_input" -eq 8 ]]; then
            install_zsh
            install_vim
            install_neovim
            install_vscode
            install_tmux
            install_i3
            install_alacritty
        fi

    fi

    # prepare for next iteration
    printf "\n"
done
