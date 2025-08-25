# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Overview

This is a comprehensive Linux development environment setup repository that automates the installation and configuration of a complete Ubuntu/i3 desktop environment optimized for development work. The repository follows a dotfiles-as-code approach with automated installation scripts and centralized configuration management.

## Architecture

The repository uses a layered architecture approach:

```
┌─ setup.sh ────────────────────────────────────┐
│  Interactive installer with modular functions │
└──────────────┬─────────────────────────────────┘
               │
┌──────────────▼─────────────────────────────────┐
│  config/ - Symlinked dotfiles & configurations │
│  ├─ zshrc, vimrc, starship.toml               │
│  ├─ i3/, nvim/, tmux/, vscode/                 │
│  └─ alacritty/, rofi/, polybar/                │
└──────────────┬─────────────────────────────────┘
               │
┌──────────────▼─────────────────────────────────┐
│  scripts/ - Utility scripts → /usr/local/bin   │
│  ├─ dont_sleep, shutdown_now                   │
│  └─ python_startup.py → ~/.python_startup.py  │
└──────────────┬─────────────────────────────────┘
               │
┌──────────────▼─────────────────────────────────┐
│  Documentation for specialized workflows       │
│  ├─ README.md - End-to-end setup guide        │
│  └─ NVIDIA_DRIVERS.md - GPU driver management │
└────────────────────────────────────────────────┘
```

The repository maintains a single source of truth through symlinks, ensuring consistency across machines and easy updates via git.

## Common Development Commands

### File Operations (Following User Preferences)
```bash
# Enhanced commands (aliases set in zshrc)
rg "pattern"           # Search code (instead of grep)
fd "filename"          # Find files (instead of find)
bat file.txt          # View files with syntax highlighting (instead of cat)
eza -lha              # Directory listings (aliased as 'la')
fzf --preview="bat --color=always {}"  # Fuzzy file search

# File operations
ff                    # Fuzzy find with preview (alias)
vf                    # Edit file selected with fzf (alias)
tree --dirsfirst      # Directory tree view
```

### System Monitoring
```bash
htop                  # Enhanced process monitor (instead of top)
nvidia-smi            # GPU monitoring (aliased as 'gpu')
iostat 2              # Disk I/O monitoring
lsof -i               # Network port monitoring (aliased as 'ports')
```

### Git Operations
```bash
git status            # Aliased as 'gst'
git log --oneline --graph  # Aliased as 'glog'
git --no-pager log    # Avoid pager issues
```

### Repository Management
```bash
# Setup and maintenance
./setup.sh            # Interactive installer menu
rg -n TODO            # Find todos in codebase
fd -t f -e conf -e cfg  # Find config files
```

## Key Scripts

| Script | Purpose | Permissions | Location |
|--------|---------|-------------|----------|
| `setup.sh` | Interactive installer with 9 setup options | 755 | Repository root |
| `scripts/dont_sleep` | Disable screen sleep/power management | 755 | → `/usr/local/bin/dont_sleep` |
| `scripts/shutdown_now` | Immediate system shutdown | 755 | → `/usr/local/bin/shutdown_now` |
| `scripts/python_startup.py` | Python environment setup | 644 | → `~/.python_startup.py` |

### Script inspection
```bash
bat setup.sh                    # View main installer
bat scripts/dont_sleep         # View utility scripts
git log --oneline scripts/     # Track script changes
```

## Configuration Patterns

### Symlink Management
- Uses `ln -sfn` for idempotent symlinks that can be safely re-run
- Removes existing configs before linking (`rm -rf ~/.config/nvim`)
- Separates tool-specific configurations in subdirectories

### Tool-Specific Configurations
```bash
config/
├── zshrc           # Oh-my-zsh with plugins, aliases, conda/mamba setup
├── vimrc           # Vim with Vundle plugin management  
├── starship.toml   # Cross-shell prompt configuration
├── i3/             # i3 window manager + i3blocks + polybar
├── nvim/           # NvChad-based Neovim configuration
├── tmux/           # Tmux with plugin manager (TPM)
├── vscode/         # VS Code settings and keybindings
└── alacritty/      # Terminal emulator configuration
```

### Color Scheme Consistency
- Uses Gruvbox/Yaru themes across tools
- Dark theme enforcement for i3 environment
- Consistent font choices (Font Awesome icons)

### Adding New Tool Configuration
1. Create `config/newtool/` directory with configuration files
2. Add install function to `setup.sh` following existing patterns:
   - Update/install packages
   - Remove existing configs
   - Create symlinks with `ln -sfn $PWD/config/newtool ~/.config/`
3. Add to action list and menu system
4. Test with `./setup.sh` option

## New Machine Setup

### Prerequisites
```bash
# Fresh Ubuntu system
sudo apt update && sudo apt upgrade
sudo apt install git neovim libfuse2 flatpak curl pipx
```

### SSH Key Setup
```bash
cd ~/.ssh && ssh-keygen
# Copy public key content to GitHub: https://github.com/settings/keys
```

### Repository Setup
```bash
mkdir ~/workspace
cd ~/workspace
git clone git@github.com:chipkajb/linux.git
cd linux
```

### Installation
```bash
./setup.sh
# Choose option 9: "Install all" for complete setup
# Or select individual options (1-8) for specific tools
```

### Post-Installation
```bash
# Reboot or logout to apply shell/WM changes
sudo reboot

# Verification commands
zsh --version           # Check shell installation
i3 --version           # Check window manager
nvidia-smi             # Check CUDA/GPU setup
```

### Optional: CUDA Setup
For ML/GPU development, follow the detailed CUDA installation instructions in the README.md, including driver removal process documented in `NVIDIA_DRIVERS.md`.

## Maintenance & Updates

### Updating Dotfiles
```bash
# Edit configurations locally
vim config/zshrc
vim config/i3/config

# Commit changes
git add .
git commit -m "feat: update zsh aliases"
git push origin main
```

### Syncing Across Machines
```bash
git pull --rebase origin main
# Re-run specific setup options if configs changed
./setup.sh  # Choose relevant option (1-8)
```

### System Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade

# Update Rust tools (used by shell)
cargo install eza --locked
sh -c "$(curl -fsSL https://starship.rs/install.sh)" -y -f

# Update conda/mamba environments
mamba update --all
```

### Regenerating Symlinks
If symlinks break or configs get overwritten:
```bash
./setup.sh  # Re-run specific setup options
# This safely removes and recreates all symlinks
```

## tmux & Session Management

The configuration includes tmux setup with TPM (Tmux Plugin Manager):
```bash
tmux new-session -s dev    # Create named session
tmux attach -t dev         # Attach to session
<prefix> + I              # Install plugins (Ctrl-b + Shift-i)
```

## Remote Development
- SSH multiplexing configuration in zshrc
- tmux for persistent remote sessions  
- Port forwarding setup for remote services
- rsync with progress for file transfers

## Further Reading

- **README.md**: Complete end-to-end setup guide with app installation
- **NVIDIA_DRIVERS.md**: Comprehensive NVIDIA driver removal process
- **setup.sh**: Source code for all installation functions
- [Repository](https://github.com/chipkajb/linux): Latest updates and issues

## Environment Variables & Secrets

The zshrc includes conda/mamba initialization, CUDA paths, and development environment variables. Sensitive tokens are included in the shell config for development convenience but should be rotated for production use.
