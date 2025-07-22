# Dotfiles

A comprehensive dotfiles setup with multiple configuration options for different use cases.

## 🚀 Quick Start

### One-Liner Installation
```bash
# Install with one command
curl -fsSL https://raw.githubusercontent.com/chris-a-phillips/dotfiles/main/quick-setup.sh | bash
```

### Manual Installation
```bash
# Clone the repository
git clone https://github.com/chris-a-phillips/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the installer
./install.sh
```

## 📋 Features

### 🎯 Three Configuration Types

1. **Personal** - Minimal setup for personal development
   - Core development tools
   - Essential productivity apps
   - Essential development tools
   - No cloud tools or extensive fonts

2. **Work** - Comprehensive setup with cloud tools
   - All personal features plus:
   - AWS CLI and SAM
   - Docker and Kubernetes tools
   - Extensive Nerd Font collection
   - Remote development tools
   - Unity development tools

3. **Default** - Basic setup with essential tools
   - Minimal core tools
   - Basic development environment
   - Essential development tools
   - No advanced features

### 🛠 What Gets Installed

#### Core Tools
- **Terminal**: tmux, fzf, exa, bat, ripgrep
- **Development**: git, neovim, node, python, rust, go
- **Package Managers**: Homebrew, pip, npm, cargo
- **Version Managers**: pyenv, nvm, asdf

#### Productivity Apps
- **Window Management**: alt-tab, rectangle-pro
- **Menu Bar**: hiddenbar, itsycal
- **Terminal**: alacritty, iTerm2
- **Development**: VS Code, Postman, DB Browser

#### Development Tools
- **Git**: git-delta, lazygit, git-lfs
- **Cloud**: AWS CLI, Docker, Kubernetes, Terraform
- **Databases**: PostgreSQL, MongoDB, MySQL, Redis
- **Languages**: Python, Node.js, Rust, Go, C#

#### Development Tools
- **Git**: git-delta, lazygit, git-lfs
- **Cloud**: AWS CLI, Docker, Kubernetes, Terraform
- **Databases**: PostgreSQL, MongoDB, MySQL, Redis
- **Languages**: Python, Node.js, Rust, Go, C#

## 🎛 Configuration System

### JSON-Based Configuration

Each configuration is defined in a JSON file under `configs/`:

```json
{
  "name": "Personal",
  "description": "Minimal setup for personal development",
  "brewfile": "Brewfile-personal",
  "features": {
    "core_tools": true,
    "development": true,
    "cloud_tools": false,
    "extensive_fonts": false
  },
  "packages": {
    "additional_brews": ["package1", "package2"],
    "additional_casks": ["app1", "app2"],
    "additional_casks": ["app1", "app2"]
  }
}
```

### Configuration Manager

Use the configuration manager to manage your setups:

```bash
# List all configurations
./scripts/config-manager list

# Show details of a configuration
./scripts/config-manager show personal

# Create a new configuration
./scripts/config-manager create gaming

# Compare two configurations
./scripts/config-manager compare personal work

# Validate a configuration
./scripts/config-manager validate work
```

## 📁 Project Structure

```
.dotfiles/
├── install.sh                 # Main installer script
├── configs/                   # Configuration files
│   ├── personal.json         # Personal configuration
│   ├── work.json            # Work configuration
│   └── default.json         # Default configuration
├── Brewfile-personal         # Personal Brewfile
├── Brewfile-work            # Work Brewfile
├── Brewfile-default         # Default Brewfile
├── scripts/                 # Utility scripts
│   ├── config-manager       # Configuration management
│   ├── activate             # Activate environment
│   ├── backup              # Backup current setup
│   └── ...                 # Other utilities
├── tmux/                   # Tmux configuration
├── alacritty/              # Alacritty configuration
├── app_configs/            # App-specific configs
└── ...                     # Other config files
```

## 🔧 Installation Process

The installer performs the following steps:

1. **Configuration Selection** - Choose your setup type
2. **OS Detection** - Automatically detect macOS/Linux
3. **Package Installation** - Install Homebrew and packages
4. **Font Installation** - Install Nerd Fonts
5. **App Configuration** - Restore app settings
6. **Dotfiles Setup** - Create symlinks and copy scripts
7. **Development Tools** - Install additional tools
8. **Git & SSH Setup** - Configure version control
9. **macOS Defaults** - Configure system preferences
10. **Verification** - Verify installation success

## 🎨 Customization

### Creating Custom Configurations

1. Create a new configuration:
   ```bash
   ./scripts/config-manager create myconfig
   ```

2. Edit the configuration file:
   ```bash
   vim configs/myconfig.json
   ```

3. Create a corresponding Brewfile:
   ```bash
   cp Brewfile-default Brewfile-myconfig
   vim Brewfile-myconfig
   ```

4. Install with your custom configuration:
   ```bash
   ./install.sh
   # Choose option 4 (Custom) and enter "myconfig"
   ```

### Adding Packages

To add packages to a configuration:

1. **Brew packages**: Add to the corresponding Brewfile
2. **Additional packages**: Add to the `additional_brews` array in the JSON config
3. **Cask apps**: Add to the `additional_casks` array
4. **Cask apps**: Add to the `additional_casks` array

## 🚀 Available Scripts

After installation, these scripts are available in your `~/bin`:

- `activate` - Activate the development environment
- `backup` - Backup current dotfiles
- `gsw` - Git switch with fuzzy finder
- `gbnew` - Create new git branch
- `help` - Show available commands
- `mkcd` - Make directory and cd into it
- `pull-all` - Pull all git repositories
- `config-manager` - Manage configurations

## 🔍 Troubleshooting

### Common Issues

1. **Permission Denied**: Make sure scripts are executable
   ```bash
   chmod +x scripts/*
   ```

2. **Brewfile Not Found**: Check that the Brewfile exists
   ```bash
   ls -la Brewfile-*
   ```

3. **Configuration Errors**: Validate your configuration
   ```bash
   ./scripts/config-manager validate personal
   ```

4. **Symlink Issues**: Check if files are already symlinks
   ```bash
   ls -la ~/.zshrc ~/.gitconfig ~/.tmux.conf
   ```

### Verification

After installation, verify everything works:

```bash
# Check symlinks
ls -la ~/.zshrc ~/.gitconfig ~/.tmux.conf

# Test scripts
help
tmux
nvim

# Check packages
brew list | wc -l
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with different configurations
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Homebrew](https://brew.sh/) for package management
- [LazyVim](https://www.lazyvim.org/) for Neovim configuration
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) for terminal theme
- [Nerd Fonts](https://www.nerdfonts.com/) for programming fonts
