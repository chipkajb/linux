# CUDA toolkit

Install the CUDA toolkit with the NVIDIA runfile. The `.run` file is large
(several GB) — keep it outside the repository (it is gitignored here).

```bash
# 1. Download the toolkit runfile
wget https://developer.download.nvidia.com/compute/cuda/13.0.0/local_installers/cuda_13.0.0_580.65.06_linux.run

# 2. Disable the nouveau driver
sudo touch /usr/lib/modprobe.d/blacklist-nouveau.conf
echo 'blacklist nouveau' | sudo tee -a /usr/lib/modprobe.d/blacklist-nouveau.conf
echo 'options nouveau modeset=0' | sudo tee -a /usr/lib/modprobe.d/blacklist-nouveau.conf
sudo update-initramfs -u

# 3. Remove any previous NVIDIA driver (see nvidia-drivers.md)

# 4. Disable Secure Boot in UEFI/BIOS (F2 on boot, sometimes F12)

# 5. Reboot into text mode (no graphical interface)

# 6. Stop the display manager
sudo service gdm stop

# 7. Install
sudo sh cuda_13.0.0_580.65.06_linux.run

# 8. Start the display manager and reboot
sudo service gdm start
reboot
```

After install, `~/.zshrc` adds `/usr/local/cuda/bin` to `PATH` and
`/usr/local/cuda/lib64` to `LD_LIBRARY_PATH`.

To remove the driver entirely, see [nvidia-drivers.md](nvidia-drivers.md).
