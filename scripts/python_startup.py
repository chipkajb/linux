import sys
import os

# Identify the current Python installation path
python_lib = os.path.dirname(os.__file__)  # Gets the path to the current Python installation
new_lib_dynload_path = os.path.join(python_lib, "lib-dynload")

# Remove all lib-dynload paths from sys.path
sys.path = [p for p in sys.path if "lib-dynload" not in p]

# Add the new lib-dynload path
sys.path.append(new_lib_dynload_path)
