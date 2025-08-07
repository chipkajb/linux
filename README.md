# Linux

Helpful Linux files: setup scripts, dotfiles, config files, assets, etc.

## End-to-End Setup Guide for New Computer

1. Update/upgrade system

   ```
   sudo apt update && sudo apt upgrade
   ```

2. Make `workspace` directory

   ```
   mkdir workspace
   ```

3. Install packages

   ```
   sudo apt install git neovim libfuse2 flatpak libxcb-xinerama0 libxcb-xtest0 libxcb-cursor0 curl pipx
   ```

4. Clone [this repo](https://github.com/chipkajb/linux) in the new `workspace` directory

   a. First, add an ssh key for the new computer in your github account

   ```
   cd ~/.ssh && ssh-keygen
   ```

   b. Copy the output of the `pub` file that was generated

   c. Paste it as a new ssh key [here](https://github.com/settings/keys)

   d. Install git and clone the repo

   ```
   cd ~/workspace && git clone git@github.com:chipkajb/linux.git
   ```

5. Apps to install

   a. [Slack](https://snapcraft.io/slack)

   b. [Cursor](https://cursor.com/)

   c. [Warp](https://app.warp.dev/get_warp?package=deb)

   d. [Anaconda](https://www.anaconda.com/download/success)

   e. [MongoDB Compass](https://www.mongodb.com/try/download/compass)

   f. [Obsidian](https://obsidian.md/download)

   g. [Pithos](https://ubuntuhandbook.org/index.php/2024/03/pithos-pandora-radio-client-released-1-6-2/) - use Option 2

   ```
   sudo add-apt-repository ppa:ubuntuhandbook1/apps
   sudo apt update
   sudo apt install pithos
   ```

   h. [Blender](https://docs.blender.org/manual/en/latest/getting_started/installing/linux.html)

   i. [Zoom](https://zoom.us/download)

## Additional Setup

Run `./setup.sh` to setup various aspects of my preferred Linux environment. You will be presented with an enumerated list of things that you can set up. Choose to setup whatever you desire from that list, then select `0` to exit.

## CUDA Setup

```
# download cuda toolkit runfile
wget https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_515.65.01_linux.run

# disable nouveau drivers
sudo touch /usr/lib/modprobe.d/blacklist-nouveau.conf
echo 'blacklist nouveau' | sudo tee -a /usr/lib/modprobe.d/blacklist-nouveau.conf
echo 'options nouveau modeset=0' | sudo tee -a /usr/lib/modprobe.d/blacklist-nouveau.conf
sudo update-initramfs -u

# reboot into text mode (i.e. without graphics interface)

# stop display manager
sudo service gdm stop

# install cuda toolkit
sudo sh cuda_11.7.1_515.65.01_linux.run

# start display manager
sudo service gdm start

# reboot
reboot
```
