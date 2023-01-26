
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$PATH:/usr/local/bin
export PATH=/opt/homebrew/bin:$PATH


if [ -f ~/.aliases ]; then
    source ~/.aliases
fi


# mkcd() {
#     mkdir -p "${1}"
#     cd "${1}"
# }
