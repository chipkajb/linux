from pdb import set_trace as bp
import os

USER = os.getenv("USER")

bashrc = open(f"/home/{USER}/.bashrc", "r")
zshrc = open(f"/home/{USER}/.zshrc", "a")
Lines = bashrc.readlines()
zshrc.write("\n")
trigger = False
for line in Lines:
    if (line[:5] == "#####") | (trigger):
        trigger = True
        zshrc.write(line)

zshrc.close()
bashrc.close()
