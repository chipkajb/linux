#! /bin/bash

# define script parameters
ACTION_LIST=(0 1 2 3 4 5 6 7 8)
DESC_LIST=("Exit" "Install dependencies" "Install zsh" "Install vim" "Install neovim" "Install VS Code" "Install tmux" "Install i3" "Install terminator")

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

# install dependencies
install_dependencies() {
    printf "Installing dependencies...\n"
    sudo apt-get update
    sudo apt-get install -y libclang-dev
    printf "${GREEN}DONE${NC} -- Dependecies installed\n"
}

# install zsh
install_zsh() {
    printf "Installing zsh...\n"
    sudo apt-get update
    sudo apt install zsh -y
    chsh -s $(which zsh)
    wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
    printf "${GREEN}DONE${NC} -- zsh installed to ${YELLOW}$(which zsh)${NC} as ${YELLOW}$(zsh --version)${NC}\n"
}

# install vim
install_vim() {
    printf "Installing vim...\n"
    ./install_vim.sh
    printf "${GREEN}DONE${NC} -- vim installed, vimrc file located at ${YELLOW}$(ls ~/.vimrc)${NC}\n"
}

# install neovim
install_neovim() {
    printf "Installing neovim...\n"
    wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
    sudo mv ./nvim.appimage /usr/bin
    sudo chmod 764 /usr/bin/nvim.appimage
    mv ~/.config/nvim ~/.config/nvim.backup 2> /dev/null
    rm -rf ~/.local/share/nvim/
    git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
    ln -s $PWD/../config/nvim/after ~/.config/nvim
    rm -rf ~/.config/nvim/lua/custom/
    ln -s $PWD/../config/nvim/custom ~/.config/nvim/lua/
    sudo apt-get install ripgrep -y
    sudo apt install python3.8-venv -y
    sudo apt-get install install jq -y
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
    ln -sfn $PWD/../config/vscode/settings.json ~/.config/Code/User/
    ln -sfn $PWD/../config/vscode/keybindings.json ~/.config/Code/User/
    printf "${GREEN}DONE${NC} -- VS Code installed to ${YELLOW}$(which code)${NC} -- ${YELLOW}v$(code --version | head -n 1)${NC}\n"
}

# install tmux
install_tmux() {
    printf "Installing tmux...\n"
    sudo apt-get update
    sudo apt-get remove tmux -y
    sudo apt-get purge tmux -y
    rm ~/.config/tmux
    sudo apt install libevent-dev
    wget https://github.com/tmux/tmux/releases/download/3.3a/tmux-3.3a.tar.gz
    tar -xf tmux-3.3a.tar.gz
    rm tmux-3.3a.tar.gz
    cd tmux-3.3a && ./configure && make && sudo make install && cd ..
    mkdir -p ~/software
    rm -rf ~/software/tmux-3.3a 2> /dev/null
    mv tmux-3.3a ~/software/
    rm -rf ~/.tmux/plugins/tpm 2> /dev/null
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ln -s $PWD/../config/tmux ~/.config/
    rm -rf tmux* 2> /dev/null
    printf "${GREEN}DONE${NC} -- tmux installed to ${YELLOW}$(which tmux)${NC} -- ${YELLOW}$(tmux -V)${NC}\n"
}

# install i3
install_i3() {
    printf "Installing i3...\n"
    sudo apt-get update
    sudo apt-get install i3 -y
    ln -s $PWD/../config/i3 ~/.config/
    printf "${GREEN}DONE${NC} -- i3 installed to ${YELLOW}$(which i3)${NC} -- ${YELLOW}$(i3 --version)${NC}\n"
}

# install terminator
install_terminater() {
    printf "Installing terminator...\n"
    sudo apt-get update
    sudo apt-get install terminator -y
    ln -s $PWD/../config/terminator ~/.config/
    printf "${GREEN}DONE${NC} -- terminator installed to ${YELLOW}$(which terminator)${NC} -- ${YELLOW}$(terminator --version)${NC}\n"
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

        # install dependencies
        if [[ "$user_input" -eq 1 ]]; then
            install_dependencies
        fi

        # install zsh
        if [[ "$user_input" -eq 2 ]]; then
            install_zsh
        fi

        # install vim
        if [[ "$user_input" -eq 3 ]]; then
            install_vim
        fi

        # install neovim
        if [[ "$user_input" -eq 4 ]]; then
            install_neovim
        fi

        # install vscode
        if [[ "$user_input" -eq 5 ]]; then
            install_vscode
        fi

        # install tmux
        if [[ "$user_input" -eq 6 ]]; then
            install_tmux
        fi

        # install i3
        if [[ "$user_input" -eq 7 ]]; then
            install_i3
        fi

        # install terminator
        if [[ "$user_input" -eq 8 ]]; then
            install_terminater
        fi

    fi

    # prepare for next iteration
    printf "\n"
done
