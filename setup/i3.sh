#!/usr/bin/env bash
# i3 window manager, i3blocks, rofi, dunst, picom, GTK theme, and display config.

ROFI_VERSION="1.7.5"

i3_packages() {
    # libgdk-pixbuf dev package was renamed in 24.04
    local pixbuf_dev="libgdk-pixbuf2.0-dev"
    is_ubuntu_at_least 24.04 && pixbuf_dev="libgdk-pixbuf-2.0-dev"

    apt_install \
        i3 feh arandr blueman lxappearance i3blocks net-tools bison flex \
        pulseaudio pulseaudio-utils pavucontrol \
        libxcb-ewmh2 libglib2.0-dev libxcb1-dev libxcb1 \
        libxcb-xkb-dev libxcb-ewmh-dev libxcb-xkb1 \
        libxcb-icccm4 libxcb-icccm4-dev libxcb-cursor-dev \
        libxcb-xinerama0-dev libxcb-randr0-dev \
        libxkbcommon-dev libxkbcommon-x11-dev libxcb-util-dev \
        libstartup-notification0-dev "$pixbuf_dev" libpango1.0-dev \
        numlockx xdotool xbindkeys lm-sensors brightnessctl fonts-font-awesome
}

install_rofi() {
    if have rofi && rofi -v 2>/dev/null | grep -q "$ROFI_VERSION"; then
        ui::info "rofi $ROFI_VERSION already installed"
        return 0
    fi
    ui::info "building rofi $ROFI_VERSION from source"
    ensure_dir "$HOME/software"
    local build="$HOME/software/rofi-$ROFI_VERSION"
    if [[ ! -d "$build" ]]; then
        wget -q "https://github.com/davatorium/rofi/releases/download/$ROFI_VERSION/rofi-$ROFI_VERSION.tar.gz" \
            -O "/tmp/rofi-$ROFI_VERSION.tar.gz"
        tar xf "/tmp/rofi-$ROFI_VERSION.tar.gz" -C "$HOME/software"
        rm -f "/tmp/rofi-$ROFI_VERSION.tar.gz"
    fi
    (
        cd "$build" || exit 1
        mkdir -p build
        cd build || exit 1
        ../configure --disable-check
        make
        sudo make install
    )
}

link_i3_config() {
    replace_with_symlink "$REPO_ROOT/config/i3" "$HOME/.config/i3"

    # host-specific i3 directives live gitignored in the repo, symlinked to ~/.i3_local
    if [[ ! -f "$REPO_ROOT/config/i3/config.local" ]]; then
        if [[ -f "$HOME/.i3_local" && ! -L "$HOME/.i3_local" ]]; then
            cp "$HOME/.i3_local" "$REPO_ROOT/config/i3/config.local"
        else
            cp "$REPO_ROOT/config/i3/config.local.example" "$REPO_ROOT/config/i3/config.local"
        fi
    fi
    symlink_force "$REPO_ROOT/config/i3/config.local" "$HOME/.i3_local"
}

link_gtk_theme() {
    ensure_dir "$HOME/.config/gtk-2.0" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    local gtk_dir
    for gtk_dir in gtk-2.0 gtk-3.0 gtk-4.0; do
        symlink_force "$REPO_ROOT/config/gtk/settings.ini" "$HOME/.config/$gtk_dir/settings.ini"
        symlink_force "$REPO_ROOT/config/gtk/gtkfilechooser.ini" "$HOME/.config/$gtk_dir/gtkfilechooser.ini"
    done
    symlink_force "$REPO_ROOT/config/gtk/set_theme.sh" "$HOME/.config/gtk-4.0/set_theme.sh"
    chmod +x "$REPO_ROOT/config/gtk/set_theme.sh"
    symlink_force "$REPO_ROOT/config/gtk/gtkrc-2.0" "$HOME/.gtkrc-2.0"

    ensure_dir "$HOME/.icons"
    symlink_force /usr/share/icons/Yaru "$HOME/.icons/default"
}

link_desktop_configs() {
    local component
    for component in rofi dunst picom polybar; do
        symlink_force "$REPO_ROOT/config/$component" "$HOME/.config/$component"
    done
    symlink_force "$REPO_ROOT/config/xbindkeys/xbindkeysrc" "$HOME/.xbindkeysrc"
}

install_i3blocks_scripts() {
    local script
    for script in gpu_memory wifi cpu_usage load_average battery temperature; do
        sudo ln -sfn "$REPO_ROOT/config/i3/$script" /usr/share/i3blocks/"$script"
    done
    sudo ln -sfn "$REPO_ROOT/config/i3/x11-common" /etc/X11/Xresources
}

step_i3() {
    apt_update
    i3_packages
    sudo usermod -aG video "$USER"
    chmod +x "$REPO_ROOT/bin/set_brightness"
    sudo ln -sfn "$REPO_ROOT/bin/set_brightness" /usr/local/bin/set_brightness
    fc-cache -fv >/dev/null

    install_rofi
    link_i3_config
    link_gtk_theme
    link_desktop_configs
    install_i3blocks_scripts

    symlink_force "$REPO_ROOT/assets/background.png" "$HOME/Pictures/background.png"
    replace_with_symlink "$REPO_ROOT/assets/fonts" "$HOME/.fonts"

    # i3 config includes ~/.i3_monitors (generated); make sure it exists on a fresh host
    monitors_init
    link_bin
}
