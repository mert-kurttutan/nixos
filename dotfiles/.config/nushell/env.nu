# env.nu
#
# Installed by:
# version = "0.108.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

# Keep host-provided project environments out of normal shells. Project
# variables belong to the project's Nix development shell instead.
for variable in [
  PYTHON_ENV_DIR
  PYTHONPATH
  TT_METAL_HOME
  VIRTUAL_ENV
  TT_FORGE_PYTHON_VERSION
  TT_FORGE_VENV
  TT_INSTALLER_VENV
  TT_LANG_VENV
  TT_VLLM_VENV
  VLLM_TT_PLUGIN_SRC
  OMPI_PREFIX
  OMPI_VERSION
] {
  if ($env | columns | any {|name| $name == $variable }) {
    hide-env $variable
  }
}
