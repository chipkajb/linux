# Ubuntu

Helpful Ubuntu files and commands

## Setup

If you are setting up a new machine, you will first need to add an ssh key.

1. `cd ~/.ssh && ssh-keygen`
2. Copy the output of `cat id_rsa.pub`
3. Paste it as a new ssh key [here](https://github.com/settings/keys)
4. Now you should be able to clone this repo: `git clone git@github.com:chipkajb/ubuntu.git`

## Instructions

1. `cd scripts`
2. `./append_bashrc.sh`
3. `./setup.sh`
4. `python bashrc_to_zshrc.py`
