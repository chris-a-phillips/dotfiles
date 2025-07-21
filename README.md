# ✨ Dotfiles Setup & Installation Guide

A complete **automated setup** for a new **macOS** environment using **`chezmoi`**, **Homebrew**, **tmux**, **Neovim**, **Alacritty**, and more.

---

## 📌 Steps to Bootstrap a New Mac

Follow these steps to fully set up your laptop from scratch.

### ==1⃣ Install Apple's Command Line Tools

Install this first so you can use Git and Homebrew:

```zsh
xcode-select --install
```

---

### ==2⃣ Clone the Dotfiles Repo

```zsh
# If using SSH:
git clone git@github.com:chris-a-phillips/dotfiles.git ~/.dotfiles

# Or use HTTPS:
git clone https://github.com/chris-a-phillips/dotfiles.git ~/.dotfiles
```

---

### ==3⃣ Run the Install Script

```zsh
bash ~/.dotfiles/install.sh
```

**This will:**

* Install **Homebrew** (if missing)
* Install **CLI tools, GUI apps, fonts** from Brewfile
* Install **Nerd Fonts** from `fonts.txt`
* Restore **Raycast** and **Rectangle Pro** settings
* Apply all **chezmoi-managed dotfiles**

---

### ==4⃣ Verify Setup

```zsh
chezmoi managed
ls -l ~/.zshrc ~/.gitconfig ~/.tmux.conf ~/.config/alacritty/alacritty.yml
brew list
```

If something is missing:

```zsh
chezmoi apply
```

---

### ==5⃣ (Optional) Add Custom Scripts to PATH

```zsh
mkdir -p ~/bin
cp -r ~/.dotfiles/bin/* ~/bin/
chmod +x ~/bin/*
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

# 📂 Tooling Overview

### 🟢 Homebrew

Homebrew handles all system dependencies.

```zsh
brew update && brew upgrade
brew bundle --file ~/.dotfiles/Brewfile
```

---

### 🟢 Neovim (LazyVim)

* Config lives in `~/.config/nvim`
* Uses LazyVim

```zsh
brew install neovim
nvim +Lazy update +qall
```

---

### 🟢 Tmux

```zsh
brew install tmux
tmux new -s mysession
tmux attach -t mysession
tmux kill-session -t mysession
```

---

### 🟢 Alacritty

```zsh
brew install alacritty
```

Config: `~/.config/alacritty/alacritty.yml`

---

### 🟢 Fonts (Nerd Fonts)

```zsh
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-fira-code-nerd-font
```

Or use:

```zsh
bash ~/.dotfiles/install.sh  # auto-installs from fonts.txt
```

---

# 🔥 TL;DR

```zsh
xcode-select --install
bash ~/.dotfiles/install.sh
```

**Boom. Full setup in one command.** 🚀
