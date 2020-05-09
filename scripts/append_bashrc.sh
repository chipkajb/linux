#! /bin/bash

# DIRECTIONS:
# 1. Delete previously appended lines in ~/.basrc
# 2. Run this script (./append_bashrc.sh)

# append to current bashrc
cat ../config/.bashrc >> /home/$USER/.bashrc
