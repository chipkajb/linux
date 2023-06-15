from pdb import set_trace as bp
import os

USER = os.getenv("USER")

# get current zshrc
zshrc_read = open(f"/home/{USER}/.zshrc", "r")
lines = zshrc_read.readlines()
for idx, line in enumerate(lines):
    if "CUSTOM CONFIGURATION ADDED BY JORDAN CHIPKA" in line:
        break

# make new zsh
orig_lines = lines[: idx - 1]
new_zshrc = open(os.path.join(os.getcwd(), "config/zshrc"), "r")
new_lines = new_zshrc.readlines()
full_lines = orig_lines + new_lines
os.system(f"rm /home/{USER}/.zshrc && touch /home/{USER}/.zshrc")
zshrc = open(f"/home/{USER}/.zshrc", "a")
for line in full_lines:
    zshrc.write(line)

zshrc_read.close()
new_zshrc.close()
zshrc.close()
