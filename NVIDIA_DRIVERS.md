## Complete NVIDIA Driver Removal Process

### 1. Remove NVIDIA Packages via Package Manager

First, remove all NVIDIA-related packages installed through apt:

```bash
# Remove NVIDIA drivers and CUDA packages
sudo apt-get remove --purge '^nvidia-.*'
sudo apt-get remove --purge '^libnvidia-.*'
sudo apt-get remove --purge '^cuda-.*'
sudo apt-get remove --purge '^libcuda.*'
sudo apt-get remove --purge '^nvidia-cuda-.*'

# Remove any remaining NVIDIA packages
sudo apt-get autoremove
sudo apt-get autoclean
```

### 2. Remove NVIDIA Installer-Installed Drivers (Might Not Be Necessary)

If you previously installed drivers using NVIDIA's `.run` installer, you need to uninstall them:

```bash
# Check if nvidia-uninstall exists (indicates .run installer was used)
which nvidia-uninstall

# If it exists, run the uninstaller
sudo nvidia-uninstall

# Also check for CUDA uninstaller
which cuda-uninstaller
sudo cuda-uninstaller
```

### 3. Remove NVIDIA Configuration Files and Directories

Clean up remaining configuration files and directories:

```bash
# Remove NVIDIA configuration files
sudo rm -rf /etc/X11/xorg.conf
sudo rm -rf /etc/X11/xorg.conf.backup
sudo rm -rf /usr/share/X11/xorg.conf.d/10-nvidia.conf

# Remove NVIDIA directories
sudo rm -rf /usr/local/cuda*
sudo rm -rf /usr/lib/nvidia*
sudo rm -rf /usr/lib32/nvidia*
sudo rm -rf /usr/lib/x86_64-linux-gnu/nvidia*
sudo rm -rf /usr/lib/i386-linux-gnu/nvidia*

# Remove NVIDIA cache and temporary files
sudo rm -rf /tmp/.X*-lock
sudo rm -rf /tmp/.X11-unix
```

### 4. Clean Module Dependencies and Blacklists

Remove kernel modules and clean blacklists:

```bash
# Remove NVIDIA kernel modules
sudo modprobe -r nvidia_drm
sudo modprobe -r nvidia_modeset
sudo modprobe -r nvidia_uvm
sudo modprobe -r nvidia

# Check and remove any NVIDIA entries in blacklist files
sudo vim /etc/modprobe.d/blacklist.conf
# Remove any lines containing 'nvidia' or 'nouveau'

# Also check other blacklist files
ls /etc/modprobe.d/ | grep -E "(nvidia|nouveau|blacklist)"
```

### 5. Update Package Database and Initramfs

```bash
# Update package database
sudo apt-get update

# Update initramfs to ensure clean boot
sudo update-initramfs -u

# Update GRUB configuration
sudo update-grub
```

### 6. Verify Complete Removal

Check that NVIDIA components are completely removed:

```bash
# Check for remaining NVIDIA packages
dpkg -l | grep -i nvidia

# Check for NVIDIA processes
ps aux | grep -i nvidia

# Check for loaded NVIDIA modules
lsmod | grep nvidia

# Verify no NVIDIA devices are being used
nvidia-smi  # Should return "command not found"
```

### 7. Reboot System

```bash
sudo reboot
```

## Post-Removal Verification Commands

After reboot, run these commands to ensure clean removal:

```bash
# Verify no NVIDIA modules are loaded
lsmod | grep nvidia

# Check GPU detection (should show your GPU without NVIDIA driver)
lspci | grep -i vga
lspci | grep -i nvidia

# Verify Ubuntu is using default display drivers
glxinfo | grep -i vendor
```
