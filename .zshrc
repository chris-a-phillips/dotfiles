
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$PATH:/usr/local/bin
export PATH=/opt/homebrew/bin:$PATH
export PATH="$HOME/.dotfiles/scripts:$PATH"


# zsh aliases
if [ -f ~/.dotfiles/.aliases ]; then
    . ~/.dotfiles/.aliases
fi
