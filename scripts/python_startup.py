import sys
import os

# Get environment variables set in .zshrc
python_stdlib = os.environ.get("PYTHON_STDLIB")
python_site_packages = os.environ.get("PYTHON_SITE_PACKAGES")
python_lib_dynload = os.environ.get("PYTHON_LIB_DYNLOAD")

if python_stdlib and python_site_packages and python_lib_dynload:
    # Override sys.path to remove system-level Python paths
    sys.path = [python_stdlib, python_site_packages, python_lib_dynload]

    # Force Python to use the correct stdlib location
    sys.prefix = python_stdlib
    sys.base_prefix = python_stdlib  # Ensure even virtualenvs use the right stdlib
    sys.exec_prefix = python_stdlib  # Affects compiled C extensions

    # Force Python's built-in module loader to look in the correct stdlib
    sys.modules["os"].__file__ = os.path.join(python_stdlib, "os.py")
    sys.modules["sys"].__file__ = os.path.join(python_stdlib, "sys.py")

# # Debugging output
# print("sys.prefix:", sys.prefix)
# print("sys.base_prefix:", sys.base_prefix)
# print("sys.exec_prefix:", sys.exec_prefix)
# print("sys.path:", sys.path)
# print("os.__file__:", sys.modules["os"].__file__)
