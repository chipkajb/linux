#! /bin/bash

# repo root — never use bare $PWD; install steps cd into build dirs
SETUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# define script parameters
ACTION_LIST=(0 1 2 3 4 5 6 7 8 9 10)
DESC_LIST=(
    "Exit" 
    "Install zsh"
    "Install vim" 
    "Install neovim"
    "Install VS Code" 
    "Install tmux" 
    "Install i3" 
    "Install alacritty"
    "Misc setup"
    "Install adlc"
    "Install all"
)

# define text colors
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Ubuntu 22.04 (jammy, glibc 2.35) and 24.04 (noble, glibc 2.39) are supported.
UBUNTU_VERSION=""
UBUNTU_CODENAME=""

detect_ubuntu() {
    if [ ! -r /etc/os-release ]; then
        printf "${RED}ERROR${NC}: /etc/os-release not found; this script targets Ubuntu 22.04 or 24.04\n"
        exit 1
    fi
    # shellcheck source=/dev/null
    . /etc/os-release
    if [ "${ID:-}" != "ubuntu" ]; then
        printf "${RED}ERROR${NC}: detected ID=%s, expected ubuntu (22.04 or 24.04)\n" "${ID:-unknown}"
        exit 1
    fi
    UBUNTU_VERSION="${VERSION_ID:-}"
    UBUNTU_CODENAME="${VERSION_CODENAME:-}"
    case "$UBUNTU_VERSION" in
        22.04|24.04)
            printf "Detected Ubuntu ${CYAN}%s${NC} (%s)\n" "$UBUNTU_VERSION" "$UBUNTU_CODENAME"
            ;;
        *)
            printf "${YELLOW}WARN${NC}: Ubuntu %s is untested; 22.04 and 24.04 are supported\n" "$UBUNTU_VERSION"
            ;;
    esac
}

# true if $UBUNTU_VERSION >= $1 (e.g. ubuntu_at_least 24.04)
ubuntu_at_least() {
    [ "$(printf '%s\n%s\n' "$1" "$UBUNTU_VERSION" | sort -V | head -n 1)" = "$1" ]
}

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

# install atuin
install_atuin() {
    if command -v brew &> /dev/null; then
        brew install atuin
    else
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | bash
    fi
}

# install zsh
install_zsh() {
    printf "Installing zsh...\n"
    sudo apt-get update
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source ~/.cargo/env
    cargo install eza --locked
    sudo apt install zsh fzf -y
    chsh -s $(which zsh)
    rm -rf ~/.oh-my-zsh 2> /dev/null
    wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-history-substring-search.git ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-history-substring-search
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
    ln -sf $SETUP_ROOT/config/zshrc /home/$USER/.zshrc
    # credentials stay outside the repo; seed an empty copy so zshrc has something to source
    if [[ ! -f /home/$USER/.zsh_secrets ]]; then
        cp $SETUP_ROOT/config/zsh_secrets.example /home/$USER/.zsh_secrets
        chmod 600 /home/$USER/.zsh_secrets
        printf "  Fill in ${YELLOW}~/.zsh_secrets${NC} with real credentials\n"
    fi
    for file in $SETUP_ROOT/scripts/*; do
        if [[ $file != *.py ]]; then
            sudo ln -sf "$file" /usr/local/bin/
        fi
    done
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -y -f
    ln -sf $SETUP_ROOT/config/starship.toml /home/$USER/.config/starship.toml
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    install_atuin
    printf "${GREEN}DONE${NC} -- zsh installed to ${YELLOW}$(which zsh)${NC} as ${YELLOW}$(zsh --version)${NC}\n"
}

# install vim
install_vim() {
    printf "Installing vim...\n"
    sudo apt-get update
    sudo apt-get install -y libclang-dev vim
    rm -rf /home/$USER/.viminfo 2> /dev/null
    rm -rf /home/$USER/.vim 2> /dev/null
    rm -rf /home/$USER/.vimrc 2> /dev/null

    ln -s $SETUP_ROOT/config/vim /home/$USER/.vim
    ln -s $SETUP_ROOT/config/vimrc /home/$USER/.vimrc

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

# install tree-sitter-cli 0.26+ (required by nvim-treesitter main on Neovim 0.12)
# 24.04+ (glibc 2.39): upstream linux-x64 zip works
# 22.04  (glibc 2.35): prebuilt needs GLIBC_2.39, so build from source with cargo
install_tree_sitter_from_source() {
    local version=$1
    [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
    if ! command -v cargo &> /dev/null; then
        printf "${RED}FAIL${NC} -- cargo not found, cannot build tree-sitter-cli; run Install zsh first\n"
        return 1
    fi
    cargo install tree-sitter-cli --version "$version" --root "$HOME/.local" --locked --force
}

install_tree_sitter_cli() {
    local version="0.26.11"
    if tree-sitter --version 2>/dev/null | grep -q "$version"; then
        printf "tree-sitter-cli v%s already installed\n" "$version"
        return
    fi
    printf "Installing tree-sitter-cli v%s for Ubuntu %s...\n" "$version" "$UBUNTU_VERSION"
    mkdir -p "$HOME/.local/bin"

    if ubuntu_at_least 24.04; then
        sudo apt-get install -y unzip
        local tmpdir
        tmpdir=$(mktemp -d)
        if wget -q "https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/tree-sitter-cli-linux-x64.zip" \
                -O "$tmpdir/tree-sitter.zip" \
            && unzip -qo "$tmpdir/tree-sitter.zip" -d "$tmpdir" \
            && "$tmpdir/tree-sitter" --version &> /dev/null; then
            install -m 755 "$tmpdir/tree-sitter" "$HOME/.local/bin/tree-sitter"
            rm -rf "$tmpdir"
            return
        fi
        rm -rf "$tmpdir"
        printf "${YELLOW}WARN${NC} -- prebuilt tree-sitter failed on Ubuntu %s, building from source\n" "$UBUNTU_VERSION"
    else
        printf "Ubuntu %s: building tree-sitter-cli from source (release binary needs glibc 2.39)\n" "$UBUNTU_VERSION"
    fi
    install_tree_sitter_from_source "$version"
}

# sync lazy.nvim plugins and install treesitter parsers for markdown rendering
install_neovim_treesitter_parsers() {
    if ! command -v nvim &> /dev/null; then
        printf "${YELLOW}WARN${NC} -- nvim not on PATH, skipping treesitter parser install\n"
        return
    fi
    printf "Installing Neovim plugins and markdown treesitter parsers...\n"
    nvim --headless "+Lazy sync" +qa
    nvim --headless "+lua require('custom.configs.treesitter').install_parsers()" +qa
}

# install mason LSP/tool packages from chadrc M.mason.pkgs (jsonls needs vscode-json-language-server)
install_neovim_mason_packages() {
    if ! command -v nvim &> /dev/null; then
        printf "${YELLOW}WARN${NC} -- nvim not on PATH, skipping mason package install\n"
        return
    fi
    # json-lsp / yaml / ts servers need npm; lua-language-server etc. use github releases
    if ! command -v npm &> /dev/null; then
        printf "${YELLOW}WARN${NC} -- npm not on PATH; some mason packages (json-lsp, yaml-language-server, typescript-language-server) may fail\n"
    fi
    printf "Installing Neovim mason packages from chadrc...\n"
    # headless: avoid :MasonInstallAll (opens UI). Install pkgs listed in chadrc.
    nvim --headless "+lua local pkgs=require('nvconfig').mason.pkgs; if #pkgs==0 then vim.cmd('qa!') else vim.cmd('MasonInstall '..table.concat(pkgs,' ')) end" +qa
}

# install neovim (snap: current nvim on both 22.04 and 24.04; apt/PPA stay on 0.9.x)
install_neovim() {
    printf "Installing neovim...\n"
    sudo apt-get update
    sudo apt-get install -y snapd python3-pip pipx gcc g++ make git unzip
    pipx ensurepath || true
    if ! snap list nvim &> /dev/null; then
        sudo snap install nvim --classic
    else
        sudo snap refresh nvim
    fi
    sudo mkdir -p /usr/local/bin
    sudo ln -sf /snap/bin/nvim /usr/local/bin/nvim
    sudo rm -f /usr/local/bin/vim
    sudo snap alias nvim.nvim vim
    sudo rm -f /usr/bin/nvim-linux-x86_64.appimage 2> /dev/null
    rm -rf ~/.local/share/nvim/ 2> /dev/null
    rm -rf ~/.config/nvim/ 2> /dev/null
    git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
    rm -rf ~/.config/nvim/after 2> /dev/null
    ln -s $SETUP_ROOT/config/nvim/after ~/.config/nvim
    rm -rf ~/.config/nvim/lua/custom/ 2> /dev/null
    ln -s $SETUP_ROOT/config/nvim/custom ~/.config/nvim/lua/custom
    ln -sf $SETUP_ROOT/config/nvim/init.lua ~/.config/nvim/init.lua
    ln -sf $SETUP_ROOT/config/nvim/lua/configs ~/.config/nvim/lua/configs
    ln -sf $SETUP_ROOT/config/nvim/lua/chadrc.lua ~/.config/nvim/lua/chadrc.lua
    sudo apt-get install ripgrep -y
    sudo apt-get install python3-venv -y
    sudo apt-get install jq -y
    pipx install black
    pipx install mypy
    install_tree_sitter_cli
    install_neovim_treesitter_parsers
    install_neovim_mason_packages

    # git merge conflicts: `git mergetool` opens a 4-pane nvim diff (LOCAL/BASE/REMOTE/MERGED).
    # Prefer `nvim` + `:DiffviewOpen` (bound to <leader>gd) for resolving conflicts across a
    # whole merge at once -- this is just a fallback for tools/scripts that call `git mergetool`.
    git config --global merge.tool nvimdiff
    git config --global mergetool.nvimdiff.cmd 'nvim -d $LOCAL $BASE $REMOTE $MERGED -c "wincmd J"'
    git config --global mergetool.nvimdiff.trustExitCode true
    git config --global mergetool.keepBackup false
    git config --global merge.conflictstyle diff3

    printf "${GREEN}DONE${NC} -- neovim installed, ${YELLOW}$(nvim --version | head -n 1)${NC}\n"
}

# install vs code (signed-by keyring works on 22.04 and 24.04; apt-key is gone on 24.04)
install_vscode() {
    printf "Installing VS Code...\n"
    sudo apt-get update
    sudo apt-get install -y wget gpg apt-transport-https
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg
    rm -f /tmp/packages.microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y code
    code --install-extension Atishay-Jain.All-Autocomplete
    code --install-extension ms-python.black-formatter
    code --install-extension anysphere.pyright
    code --install-extension IronGeek.vscode-env
    code --install-extension ZainChen.json
    code --install-extension esbenp.prettier-vscode
    code --install-extension ms-python.vscode-pylance
    code --install-extension ms-python.python
    code --install-extension mechatroner.rainbow-csv
    code --install-extension tickleforce.scrolloff
    code --install-extension vscodevim.vim
    code --install-extension Ransh.ransh
    code --install-extension jdinhlife.gruvbox
    code --install-extension charliermarsh.ruff
    code --install-extension matangover.mypy
    code --install-extension lucien-martijn.parquet-visualizer
    code --install-extension ms-python.debugpy
    code --install-extension ms-vscode-remote.remote-ssh
    code --install-extension ms-vscode-remote.remote-ssh-edit
    code --install-extension ms-vscode-remote.remote-explorer
    code --install-extension tomoki1207.pdf
    ln -sfn $SETUP_ROOT/config/vscode/settings.json ~/.config/Code/User/
    ln -sfn $SETUP_ROOT/config/vscode/keybindings.json ~/.config/Code/User/
    ln -sfn $SETUP_ROOT/config/vscode/settings.json ~/.config/Cursor/User/
    ln -sfn $SETUP_ROOT/config/vscode/keybindings.json ~/.config/Cursor/User/
    python3 "$SETUP_ROOT/config/vscode/hide-staged-gutter-diffs.py" || true
    printf "${GREEN}DONE${NC} -- VS Code installed to ${YELLOW}$(which code)${NC} -- ${YELLOW}v$(code --version | head -n 1)${NC}\n"
}

# install tmux
install_tmux() {
    printf "Installing tmux...\n"
    sudo apt-get update
    sudo apt-get remove tmux -y
    sudo apt-get purge tmux -y
    rm -rf ~/.config/tmux 2> /dev/null
    sudo apt-get install tmux libevent-dev xclip ncurses-dev -y
    rm -rf ~/.tmux/plugins/tpm 2> /dev/null
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ln -s $SETUP_ROOT/config/tmux ~/.config/
    ln -sfn $SETUP_ROOT/config/tmux/tmux.conf ~/.tmux.conf
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$SETUP_ROOT/scripts/osc52-copy" "$HOME/.local/bin/osc52-copy"
    chmod +x "$SETUP_ROOT/scripts/osc52-copy"
    rm -rf tmux* 2> /dev/null
    printf "${GREEN}DONE${NC} -- tmux installed to ${YELLOW}$(which tmux)${NC} -- ${YELLOW}$(tmux -V)${NC}\n"
}

# install adlc tooling: herdr + caveman + superpowers
install_adlc() {
    printf "Installing adlc (herdr + caveman + superpowers)...\n"

    export PATH="$HOME/.local/bin:$PATH"

    # clipboard helper used by pane-copy binding
    sudo apt-get update
    sudo apt-get install -y xclip

    # herdr binary
    if ! command -v herdr &> /dev/null; then
        curl -fsSL https://herdr.dev/install.sh | sh
    else
        printf "  herdr already installed: ${YELLOW}$(herdr --version 2>/dev/null || echo present)${NC}\n"
    fi
    export PATH="$HOME/.local/bin:$PATH"

    # application config
    mkdir -p ~/.config/herdr
    ln -sfn "$SETUP_ROOT/config/herdr/config.toml" ~/.config/herdr/config.toml
    if command -v herdr &> /dev/null; then
        herdr config check || true
    fi

    # launcher for rofi / i3
    chmod +x "$SETUP_ROOT/scripts/herdr-launch" "$SETUP_ROOT/scripts/herdr-reset"
    mkdir -p ~/.local/bin ~/.local/share/applications
    ln -sfn "$SETUP_ROOT/scripts/herdr-launch" ~/.local/bin/herdr-launch
    ln -sfn "$SETUP_ROOT/scripts/herdr-reset" ~/.local/bin/herdr-reset
    ln -sfn "$SETUP_ROOT/config/applications/herdr.desktop" ~/.local/share/applications/herdr.desktop
    # app icons (hicolor → rofi/desktop/dunst pick up Icon=herdr, slack, …)
    for size_dir in "$SETUP_ROOT"/assets/icons/hicolor/*/apps; do
        size=$(basename "$(dirname "$size_dir")")
        mkdir -p "$HOME/.local/share/icons/hicolor/$size/apps"
        for icon in "$size_dir"/*.png; do
            [ -f "$icon" ] || continue
            ln -sfn "$icon" "$HOME/.local/share/icons/hicolor/$size/apps/$(basename "$icon")"
        done
    done
    # Cursor ships only in pixmaps; alias into hicolor for dunst theme lookup
    if [ -f /usr/share/pixmaps/co.anysphere.cursor.png ]; then
        for size in 48x48 128x128 256x256; do
            mkdir -p "$HOME/.local/share/icons/hicolor/$size/apps"
            ln -sfn /usr/share/pixmaps/co.anysphere.cursor.png \
                "$HOME/.local/share/icons/hicolor/$size/apps/co.anysphere.cursor.png"
            ln -sfn /usr/share/pixmaps/co.anysphere.cursor.png \
                "$HOME/.local/share/icons/hicolor/$size/apps/cursor.png"
        done
    fi
    if command -v gtk-update-icon-cache &> /dev/null; then
        gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2> /dev/null || true
    fi
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database ~/.local/share/applications 2> /dev/null || true
    fi

    # caveman — terse agent replies (auto-detects installed agents)
    printf "  Installing caveman...\n"
    curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash || true

    # superpowers — agentic skills methodology (Claude Code + Cursor when available)
    printf "  Installing superpowers...\n"
    if command -v claude &> /dev/null; then
        claude plugin marketplace add obra/superpowers-marketplace 2>/dev/null || true
        claude plugin install superpowers@claude-plugins-official -s user 2>/dev/null \
            || claude plugin install superpowers@superpowers-marketplace -s user 2>/dev/null \
            || true
    else
        printf "  ${YELLOW}claude${NC} not on PATH — skip Claude Code superpowers install\n"
    fi
    if command -v npx &> /dev/null; then
        # cursor skill install (idempotent; safe to re-run)
        npx --yes skills add JuliusBrussee/caveman -a cursor 2>/dev/null || true
    fi

    printf "${GREEN}DONE${NC} -- adlc tooling installed\n"
    printf "  herdr: ${YELLOW}$(command -v herdr || echo "$HOME/.local/bin/herdr")${NC}\n"
    printf "  Launch from rofi (Mod+d) as ${YELLOW}herdr${NC}, or i3 ${YELLOW}Mod+Shift+t${NC}\n"
    printf "  Prefix is ${YELLOW}Ctrl-Space${NC} (see config/herdr/config.toml)\n"
    printf "  caveman: type ${YELLOW}/caveman${NC} in a session (or say \"talk like caveman\")\n"
    printf "  superpowers: restart Claude Code / Cursor after install\n"
    printf "  Update herdr with ${YELLOW}herdr update${NC}\n"
}

# install i3
install_i3() {
    printf "Installing i3...\n"
    sudo apt-get update
    # package renamed in 24.04 (22.04 still uses libgdk-pixbuf2.0-dev)
    local pixbuf_dev="libgdk-pixbuf2.0-dev"
    if ubuntu_at_least 24.04; then
        pixbuf_dev="libgdk-pixbuf-2.0-dev"
    fi
    sudo apt-get install i3 \
        feh \
        arandr \
        blueman \
        lxappearance \
        i3blocks \
        net-tools \
        bison \
        flex \
        pulseaudio \
        pulseaudio-utils \
        pavucontrol \
        libxcb-ewmh2 \
        libglib2.0-dev \
        libxcb1-dev \
        libxcb1 \
        libxcb-xkb-dev \
        libxcb-ewmh-dev \
        libxcb-xkb-dev \
        libxcb-xkb1 \
        libxcb-icccm4 \
        libxcb-icccm4-dev \
        libxcb-cursor-dev \
        libxcb-xinerama0-dev \
        libxcb-randr0-dev \
        libxkbcommon-dev \
        libxkbcommon-x11-dev \
        libxcb-util-dev \
        libstartup-notification0-dev \
        $pixbuf_dev \
        libpango1.0-dev \
        numlockx \
        xdotool \
        xbindkeys \
        lm-sensors \
        brightnessctl \
        fonts-font-awesome -y
    sudo usermod -aG video "$USER"
    sudo ln -sf "$SETUP_ROOT/scripts/set_brightness" /usr/local/bin/set_brightness
    fc-cache -fv
    rm -rf rofi-1.7.5 2> /dev/null
    wget https://github.com/davatorium/rofi/releases/download/1.7.5/rofi-1.7.5.tar.gz
    tar xf rofi-1.7.5.tar.gz
    rm -rf rofi-1.7.5.tar.gz
    cd rofi-1.7.5 && mkdir -p build && cd build && ../configure --disable-check && make && sudo make install && cd ../..
    rm -rf ~/software/rofi-1.7.5 2> /dev/null
    mkdir -p ~/software
    mv rofi-1.7.5 ~/software/rofi-1.7.5
    rm -rf ~/.config/i3 2> /dev/null
    rm ~/Pictures/background.png 2> /dev/null
    ln -s $SETUP_ROOT/config/i3 ~/.config/
    ln -s $SETUP_ROOT/assets/background.png ~/Pictures/
    ln -sfn $SETUP_ROOT/assets/fonts ~/.fonts
    mkdir -p ~/.config/gtk-2.0
    mkdir -p ~/.config/gtk-3.0
    mkdir -p ~/.config/gtk-4.0
    ln -sfn $SETUP_ROOT/config/gtk/settings.ini ~/.config/gtk-2.0/settings.ini
    ln -sfn $SETUP_ROOT/config/gtk/settings.ini ~/.config/gtk-3.0/settings.ini
    ln -sfn $SETUP_ROOT/config/gtk/settings.ini ~/.config/gtk-4.0/settings.ini
    ln -sfn $SETUP_ROOT/config/gtk/gtkfilechooser.ini ~/.config/gtk-2.0/gtkfilechooser.ini
    ln -sfn $SETUP_ROOT/config/gtk/gtkfilechooser.ini ~/.config/gtk-3.0/gtkfilechooser.ini
    ln -sfn $SETUP_ROOT/config/gtk/gtkfilechooser.ini ~/.config/gtk-4.0/gtkfilechooser.ini
    ln -sfn $SETUP_ROOT/config/gtk/set_theme.sh ~/.config/gtk-4.0/set_theme.sh
    chmod +x ~/.config/gtk-4.0/set_theme.sh
    ln -sfn $SETUP_ROOT/config/gtk/gtkrc-2.0 ~/.gtkrc-2.0
    ln -sfn $SETUP_ROOT/config/rofi ~/.config/
    ln -sfn $SETUP_ROOT/config/dunst ~/.config/
    ln -sfn $SETUP_ROOT/config/picom ~/.config/
    ln -sfn $SETUP_ROOT/config/polybar ~/.config/
    ln -sfn $SETUP_ROOT/config/xbindkeys/xbindkeysrc ~/.xbindkeysrc
    sudo ln -sfn $SETUP_ROOT/config/i3/gpu_memory /usr/share/i3blocks
    sudo ln -sfn $SETUP_ROOT/config/i3/wifi /usr/share/i3blocks
    sudo ln -sfn $SETUP_ROOT/config/i3/cpu_usage /usr/share/i3blocks
    sudo ln -sfn $SETUP_ROOT/config/i3/load_average /usr/share/i3blocks
    sudo ln -sfn $SETUP_ROOT/config/i3/battery /usr/share/i3blocks
    sudo ln -sfn $SETUP_ROOT/config/i3/temperature /usr/share/i3blocks
    sudo ln -sfn $SETUP_ROOT/config/i3/x11-common /etc/X11/Xresources
    mkdir -p ~/.icons
    ln -sfn /usr/share/icons/Yaru ~/.icons/default
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
    ln -s $SETUP_ROOT/config/alacritty ~/.config/
    mkdir -p ~/.config/alacritty/themes
    git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes
    printf "${GREEN}DONE${NC} -- alacritty installed to ${YELLOW}$(which alacritty)${NC} -- ${YELLOW}$(alacritty --version)${NC}\n"
}

# install fff-mcp (agent file search; used by claude/cursor instead of rg/fzf)
install_fff_mcp() {
    printf "Installing fff-mcp...\n"
    curl -fsSL https://raw.githubusercontent.com/dmtrKovalenko/fff/main/install-mcp.sh | bash
    if command -v claude &>/dev/null; then
        claude mcp add -s user fff -- "$HOME/.local/bin/fff-mcp" 2>/dev/null || true
    fi
    printf "${GREEN}DONE${NC} -- fff-mcp at ${YELLOW}$HOME/.local/bin/fff-mcp${NC}\n"
}

# misc setup
misc_setup() {
    printf "Miscellaneous setup...\n"
    sudo apt-get update
    sudo apt install python3-gi unclutter-xfixes flameshot simplescreenrecorder gnome-tweaks -y
    # fd/rg/fzf remain for one-shot shell use; agents + nvim use fff
    sudo apt install fd-find ripgrep bat fzf htop tree jq sysstat screen -y
    install_fff_mcp
    ln -s $SETUP_ROOT/scripts/python_startup.py /home/$USER/.python_startup.py
    rm -rf ~/.local/share/gedit 2> /dev/null
    mkdir -p ~/.local/share/gedit/plugins
    (
        cd ~/.local/share/gedit/plugins
        wget https://raw.githubusercontent.com/nparkanyi/gedit3-vim-mode/master/vim-mode.py
        wget https://raw.githubusercontent.com/nparkanyi/gedit3-vim-mode/master/vim-mode.plugin
    )
    cd "$SETUP_ROOT"
    printf "${GREEN}DONE${NC} -- miscellaneous setup complete\n"
}

# main loop
detect_ubuntu
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

        # misc setup
        if [[ "$user_input" -eq 8 ]]; then
            misc_setup
        fi

        # install adlc (herdr + caveman + superpowers)
        if [[ "$user_input" -eq 9 ]]; then
            install_adlc
        fi
       
        # install all
        if [[ "$user_input" -eq 10 ]]; then
            install_zsh
            install_vim
            install_neovim
            install_vscode
            install_tmux
            install_i3
            install_alacritty
            misc_setup
            install_adlc
        fi

    fi

    # prepare for next iteration
    printf "\n"
done
