# ✨ Dotfiles Setup & Installation Guide

A complete **automated setup** for a new **macOS** environment using **Homebrew**, **tmux**, **Neovim**, **Alacritty**, and more.

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
* Set up **Git configuration** and **SSH keys**
* Apply **macOS system preferences**
* Create **symlinks** for all dotfiles
* Copy **custom scripts** to `~/bin` and make them executable
* Install **Neovim/LazyVim** and **Powerlevel10k** theme

---

### ==4⃣ Set Up Dotfiles (Automatic)

The install script now automatically handles all dotfile setup:

```zsh
# The script will:
# ✅ Backup existing dotfiles (if any)
# ✅ Create all necessary symlinks
# ✅ Set up config directories
# ✅ Copy and make scripts executable
# ✅ Install TPM for tmux plugins
```

**What gets set up:**
- Core dotfiles: `.zshrc`, `.gitconfig`, `.aliases`, `.p10k.zsh`
- Config files: `~/.config/alacritty/alacritty.toml`, `~/.tmux.conf`
- Tmux plugins: TPM installation and configuration
- Custom scripts: Copied to `~/bin` and made executable

**Safety features:**
- ✅ Existing dotfiles are backed up to `.backup` files
- ✅ Comprehensive verification at the end
- ✅ Error handling for missing dependencies

---

### ==5⃣ Verify Setup

The install script includes comprehensive verification, but you can also check manually:

```zsh
# Check if symlinks are working
ls -la ~/.zshrc ~/.gitconfig ~/.tmux.conf ~/.config/alacritty/alacritty.toml

# Check if scripts are available
which activate gsw gbnew help mkcd backup pull-all

# Check tmux plugins
ls -la ~/.tmux/plugins/tpm

# Check installed packages
brew list
```

---

### ==6⃣ Install Additional Tools

```zsh
# Install Neovim and LazyVim
brew install neovim
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# Install Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

# Install Oh My Zsh (optional)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

---

### ==7⃣ Verify Scripts Are Working

After setup, you should have access to these custom scripts:

```zsh
# Check if scripts are available
which activate gsw gbnew help mkcd backup pull-all

# Test a script
gsw  # Git branch switcher
help # Show available commands
```

**Available Scripts:**
- `activate` - Activate Python virtual environment
- `gsw` - Git branch switcher with interactive menu
- `gbnew` - Create and switch to new git branch
- `help` - Show available commands
- `mkcd` - Create directory and navigate to it
- `backup` - Backup utility
- `pull-all` - Pull all git repositories

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

### 🟢 Custom Scripts

Your custom scripts are automatically copied to `~/bin` and added to your PATH:

```zsh
# Scripts are available from anywhere
gsw     # Git branch switcher
activate # Python venv activator
help     # Show available commands
```

**PATH Setup:**
- `~/bin` - Custom scripts (copied from `~/.dotfiles/scripts/`)
- `~/.dotfiles/scripts` - Original script location (also in PATH)

---

# 🔥 TL;DR

```zsh
xcode-select --install
git clone git@github.com:chris-a-phillips/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/install.sh
# Then manually create symlinks as shown in step 4
```

**Boom. Full setup in a few commands.** 🚀

---

# 🔧 Manual Setup (Alternative)

If you prefer to set up manually instead of using the install script:

1. **Install Homebrew:**
   ```zsh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install packages:**
   ```zsh
   brew bundle --file ~/.dotfiles/Brewfile
   ```

3. **Create symlinks:**
   ```zsh
   # Backup existing files first
   for file in ~/.zshrc ~/.gitconfig ~/.aliases ~/.p10k.zsh ~/.tmux.conf; do
     [[ -f "$file" && ! -L "$file" ]] && mv "$file" "${file}.backup"
   done
   
   # Core dotfiles
   ln -sf ~/.dotfiles/.zshrc ~/.zshrc
   ln -sf ~/.dotfiles/.gitconfig ~/.gitconfig
   ln -sf ~/.dotfiles/.aliases ~/.aliases
   ln -sf ~/.dotfiles/.p10k.zsh ~/.p10k.zsh
   
   # Config directories
   mkdir -p ~/.config/alacritty ~/.config/tmux
   ln -sf ~/.dotfiles/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml
   ln -sf ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf
   ln -sf ~/.dotfiles/tmux/statusline.conf ~/.config/tmux/statusline.conf
   ln -sf ~/.dotfiles/tmux/utility.conf ~/.config/tmux/utility.conf
   ln -sf ~/.dotfiles/tmux/macos.conf ~/.config/tmux/macos.conf
   
   # Set up custom scripts
   mkdir -p ~/bin
   rm -rf ~/bin/* 2>/dev/null || true
   cp -r ~/.dotfiles/scripts/* ~/bin/
   chmod +x ~/bin/*
   
   # Install TPM
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

4. **Set up Git and SSH:**
   ```zsh
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ssh-keygen -t ed25519 -C "your.email@example.com"
   ```
