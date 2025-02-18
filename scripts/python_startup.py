import sys
import os

# Get environment variables set in .zshrc
python_stdlib = os.environ.get("PYTHON_STDLIB")
python_site_packages = os.environ.get("PYTHON_SITE_PACKAGES")
python_lib_dynload = os.environ.get("PYTHON_LIB_DYNLOAD")
cwd = os.environ.get("PWD")

# add base conda paths if python path is from conda environment
try:
    if (python_stdlib.split("/")[-5] == "anaconda3") & (python_stdlib.split("/")[-4] == "envs"):
        base_conda_path = "/".join(python_stdlib.split("/")[:5])
        python_versions = [f for f in os.listdir(base_conda_path + "/lib") if "python" in f and "lib" not in f]
        python_version = sorted(python_versions)[-1]
        python_base_stdlib = "/".join([base_conda_path, "lib", python_version])
        python_base_site_packages = "/".join([python_base_stdlib, "site-packages"])
        python_base_lib_dynload = "/".join([python_base_stdlib, "lib-dynload"])
except IndexError:
    pass

if python_stdlib and python_site_packages and python_lib_dynload:
    # Override sys.path to remove system-level Python paths
    sys.path = [cwd, python_stdlib, python_site_packages, python_lib_dynload]

    # Force Python to use the correct stdlib location
    sys.prefix = python_stdlib
    sys.base_prefix = python_stdlib  # Ensure even virtualenvs use the right stdlib
    sys.exec_prefix = python_stdlib  # Affects compiled C extensions

    # Force Python's built-in module loader to look in the correct stdlib
    sys.modules["os"].__file__ = os.path.join(python_stdlib, "os.py")
    sys.modules["sys"].__file__ = os.path.join(python_stdlib, "sys.py")

if python_base_stdlib and python_base_site_packages and python_base_lib_dynload:
    sys.path.append(python_base_stdlib)
    sys.path.append(python_base_site_packages)
    sys.path.append(python_base_lib_dynload)
