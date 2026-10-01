export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin:$HOME/.cargo/bin"

# Keep host-provided project environments out of normal shells. Project
# variables belong to the project's Nix development shell instead.
for variable in \
  PYTHON_ENV_DIR \
  PYTHONPATH \
  TT_METAL_HOME \
  VIRTUAL_ENV \
  TT_FORGE_PYTHON_VERSION \
  TT_FORGE_VENV \
  TT_INSTALLER_VENV \
  TT_LANG_VENV \
  TT_VLLM_VENV \
  VLLM_TT_PLUGIN_SRC \
  OMPI_PREFIX \
  OMPI_VERSION
do
  unset "$variable"
done

if [[ -d "$HOME/.local/share/fnm" ]]; then
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "$(fnm env --shell bash)"
fi

ld-path-python() {
  export LD_LIBRARY_PATH=/run/opengl-driver/lib:$LD_LIBRARY_PATH
}

[[ $- == *i* ]] || return

HISTFILESIZE=100000
HISTSIZE=10000

shopt -s histappend
shopt -s extglob
shopt -s globstar
shopt -s checkjobs

alias k=kubectl
alias urldecode="python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'"
alias urlencode="python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'"

if [[ ! -v BASH_COMPLETION_VERSINFO ]]; then
  for completion in \
    /etc/profile.d/bash_completion.sh \
    /usr/share/bash-completion/bash_completion \
    /etc/bash_completion \
    "$HOME/.nix-profile/etc/profile.d/bash_completion.sh" \
    /run/current-system/sw/etc/profile.d/bash_completion.sh
  do
    if [[ -r "$completion" ]]; then
      . "$completion"
      break
    fi
  done
fi
