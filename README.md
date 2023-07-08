# Linux

Helpful Linux files: setup scripts, dotfiles, config files, assets, etc.

## Setup

If you are setting up a new machine, you will first need to add an ssh key.

1. `cd ~/.ssh && ssh-keygen`
2. Copy the output of `cat id_rsa.pub`
3. Paste it as a new ssh key [here](https://github.com/settings/keys)
4. Now you should be able to clone this repo: `git clone git@github.com:chipkajb/linux.git`

## Instructions

Run `./setup.sh` to setup various aspects of my preferred Linux environment. You will be presented with an enumerated list of things that you can set up. Choose to setup whatever you desire from that list, then select `0` to exit.
