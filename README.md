
# **🚀 Dotfiles Setup & Installation Guide**
A complete **automated setup** for a new **macOS** environment using **`chezmoi`**, **Homebrew**, **tmux**, **Neovim**, **Alacritty**, and more.

---

## **📌 Steps to Bootstrap a New Mac**
Follow these steps to **set up your Mac from scratch**.

### **1️⃣ Install Apple's Command Line Tools**
Before installing anything else, install Apple's Command Line Tools, which are required for **Git** and **Homebrew**.

```zsh
xcode-select --install
```

---

### **2️⃣ Clone the Dotfiles Repo**
Clone your **dotfiles repository** into a hidden directory.

```zsh
# Use SSH (if set up)...
git clone git@github.com:chris-a-phillips/dotfiles.git ~/.dotfiles

# ...or use HTTPS and switch remotes later.
git clone https://github.com/chris-a-phillips/dotfiles.git ~/.dotfiles
```

---

### **3️⃣ Run the Install Script (Automated Setup)**
Instead of manually setting up **symlinks**, **installing Homebrew**, and configuring tools, run the install script:

```zsh
bash ~/.dotfiles/install.sh
```

💪 **This will:**
- Install **Homebrew** (if missing)
- Install **all CLI tools, GUI apps, and fonts** from the **Brewfile**
- Install **Nerd Fonts** from the **fonts.txt** list
- Apply **chezmoi-managed dotfiles** (`.zshrc`, `.gitconfig`, `.tmux.conf`, etc.)
- Ensure all symlinks are **automatically** created

---

### **4️⃣ Verify Everything is Installed**
After the script runs, check that everything is set up:

```zsh
chezmoi managed  # Shows all files managed by chezmoi
ls -l ~/.zshrc ~/.gitconfig ~/.tmux.conf ~/.config/alacritty/alacritty.yml
brew list        # Shows installed Homebrew packages
```

If any of your **dotfiles are missing**, run:

```zsh
chezmoi apply
```

---

### **5️⃣ Copy Custom Scripts to `~/bin` (Optional)**
If you have custom scripts that need to be in your `$PATH`, do the following:

```zsh
mkdir -p ~/bin
cp -r ~/.dotfiles/bin/* ~/bin/
chmod +x ~/bin/*
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

# **📂 Tooling Overview**
This section provides details about each tool included in your dotfiles.

### **🟢 Homebrew**
Homebrew is used to install packages and manage system dependencies.

#### **Installation**
Already handled by `install.sh`.
To manually install:
```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### **Brewfile (List of Packages)**
All installed packages are listed in `~/.dotfiles/Brewfile`.

To manually install packages:
```zsh
brew bundle --file ~/.dotfiles/Brewfile
```

To update:
```zsh
brew update && brew upgrade
```

---

### **🟢 Neovim (LazyVim)**
Neovim is set up with [LazyVim](https://github.com/LazyVim/LazyVim).

#### **Configuration**
- Config stored in `~/.config/nvim`
- Managed via `chezmoi`
- Uses `LazyVim` as the default setup

#### **Manual Installation**
```zsh
brew install neovim
```

#### **Updating Plugins**
Inside Neovim, run:
```
:Lazyman
```
Or from the terminal:
```zsh
nvim +Lazy update +qall
```

---

### **🟢 Tmux**
Tmux is a terminal multiplexer for managing multiple terminal sessions.

#### **Configuration**
- Config stored in `~/.tmux.conf`
- Managed via `chezmoi`

#### **Manual Installation**
```zsh
brew install tmux
```

#### **Useful Commands**
```zsh
tmux new -s mysession  # Start a new session
tmux ls                # List active sessions
tmux attach -t mysession  # Attach to a session
tmux kill-session -t mysession  # Kill a session
```

---

### **🟢 Alacritty (Terminal Emulator)**
Alacritty is a fast GPU-accelerated terminal.

#### **Configuration**
- Config stored in `~/.config/alacritty/alacritty.yml`
- Managed via `chezmoi`

#### **Manual Installation**
```zsh
brew install alacritty
```

---

### **🟢 Fonts (Nerd Fonts)**
Nerd Fonts are installed via Homebrew and custom downloads.

#### **Manual Installation**
```zsh
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-fira-code-nerd-font
```

#### **Additional Fonts**
Extra Nerd Fonts are downloaded via `fonts.txt`.

To manually install them:
```zsh
mkdir -p ~/Library/Fonts
cd ~/Library/Fonts
while IFS= read -r font_url; do
    font_name=$(basename "$font_url" .zip)
    curl -fLo "${font_name}.zip" "$font_url"
    unzip "${font_name}.zip" -d "$font_name"
    rm "${font_name}.zip"
done < ~/.dotfiles/fonts.txt
```

---

# **🔥 TL;DR - One-Command Setup**
After installing Apple's Command Line Tools (`xcode-select --install`), **run this:**

```zsh
bash ~/.dotfiles/install.sh
```

💪 **Everything is installed automatically!**
🚀 **Your Mac will be fully set up with one command!**


<!--TODO: list out all utility applications and add them to readme and install script-->
to add:
- jesseduffield/lazydocker
Vs code
Postman
iterm
Figma
Clipy
Raycast -> get backup folder too
Numi
Monitor control
Dropzone
Amphetamine
Itsycal
Alttab
Rectangle pro
Dock door
Hidden bar
Background music
Spotify
Obsidian
