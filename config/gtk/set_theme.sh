#!/bin/bash

# Core interface settings (these work)
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-blue-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Yaru-blue-dark'
gsettings set org.gnome.desktop.interface font-name 'Sans 10'
gsettings set org.gnome.desktop.interface cursor-size 0
gsettings set org.gnome.desktop.interface toolbar-style 'both-horiz'
gsettings set org.gnome.desktop.interface toolbar-icons-size 'large'

# Font rendering settings
gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
gsettings set org.gnome.desktop.interface font-hinting 'medium'

# Sound settings (different schema)
gsettings set org.gnome.desktop.sound event-sounds true
gsettings set org.gnome.desktop.sound input-feedback-sounds true

# WM settings for buttons and menus (if available)
gsettings set org.gnome.settings-daemon.plugins.xsettings overrides "{'Gtk/ButtonImages': <0>, 'Gtk/MenuImages': <0>}" 2>/dev/null || true

# Export environment variables for current session
export GTK_THEME=Yaru-blue-dark
export GTK2_RC_FILES=/usr/share/themes/Yaru-blue-dark/gtk-2.0/gtkrc

echo "Theme applied: Yaru-blue-dark"