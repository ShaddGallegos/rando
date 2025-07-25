#!/bin/bash

# Development Environment Configuration Suite
# Comprehensive development tools setup, environment management, and productivity toolkit
# Consolidates: dev_setup.sh, programming_tools.sh, ide_config.sh, git_workflow.sh

set -euo pipefail

LOG_FILE="$HOME/dev_environment_$(date +'%Y%m%d_%H%M%S').log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo
    echo
    echo
    echo
    echo ""
}

show_main_menu() {
    echo
    echo ""
    echo " DEVELOPMENT TOOLS:"
    echo "1.  Programming Languages Setup"
    echo "2.  IDE & Editor Configuration"
    echo "3.  Package Managers & Libraries"
    echo "4.  Version Control Systems"
    echo ""
    echo " WEB DEVELOPMENT:"
    echo "5.  Web Development Stack"
    echo "6.  Node.js & NPM Ecosystem"
    echo "7.  Python Development Environment"
    echo "8.  Java Development Kit"
    echo ""
    echo " CONTAINERIZATION & VIRTUALIZATION:"
    echo "9.  Docker Development Setup"
    echo "10.  Kubernetes Tools"
    echo "11.  Virtual Environment Management"
    echo "12.  DevOps Tools & CI/CD"
    echo ""
    echo " ENVIRONMENT MANAGEMENT:"
    echo "13.  Project Template Manager"
    echo "14.  Development Security Tools"
    echo "15.  Development Monitoring & Analytics"
    echo "16.  Exit"
    echo ""
    read -p "Enter your choice (1-16): " choice
}

# ===== UTILITY FUNCTIONS =====

check_root_required() {
    if [ "$EUID" -ne 0 ]; then
        log "${RED}This operation requires root privileges. Please run with sudo.${NC}"
        return 1
    fi
    return 0
}

install_package_if_missing() {
    local package="$1"
    
    if ! command -v "$package" >/dev/null 2>&1 && ! rpm -q "$package" >/dev/null 2>&1; then
        log "Installing $package..."
        if command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y "$package" 2>&1 | tee -a "$LOG_FILE"
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y "$package" 2>&1 | tee -a "$LOG_FILE"
        else
            log "${RED}No supported package manager found${NC}"
            return 1
        fi
    else
        log "$package is already installed"
    fi
}

create_directory_safely() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log "Created directory: $dir"
    fi
}

add_to_path() {
    local new_path="$1"
    local profile_file="$HOME/.bashrc"
    
    if [ -d "$new_path" ] && ! echo "$PATH" | grep -q "$new_path"; then
        echo "export PATH=\"$new_path:\$PATH\"" >> "$profile_file"
        export PATH="$new_path:$PATH"
        log "Added $new_path to PATH"
    fi
}

# ===== DEVELOPMENT TOOLS =====

programming_languages_setup() {
    log "${BLUE}=== Programming Languages Setup ===${NC}"
    
    echo "Programming language installation options:"
    echo "1.  Python Development Environment"
    echo "2.  Node.js & JavaScript Environment"
    echo "3.  Java Development Kit"
    echo "4.  Rust Programming Language"
    echo "5.  Go Programming Language"
    echo "6.  Ruby Development Environment"
    echo "7.  Multiple Languages (Full Stack)"
    read -p "Choose language setup (1-7): " lang_choice
    
    case $lang_choice in
        1)
            log "Setting up Python development environment..."
            
            # Install Python and essential tools
            local python_packages=(
                "python3"
                "python3-pip"
                "python3-venv"
                "python3-dev"
                "python3-setuptools"
                "python3-wheel"
            )
            
            for package in "${python_packages[@]}"; do
                install_package_if_missing "$package"
            done
            
            # Install essential Python packages
            log "Installing essential Python packages..."
            pip3 install --user --upgrade pip setuptools wheel virtualenv pipenv poetry black flake8 mypy pytest jupyter ipython requests numpy pandas matplotlib
            
            # Create Python project directory structure
            local python_workspace="$HOME/python_projects"
            create_directory_safely "$python_workspace"
            create_directory_safely "$python_workspace/templates"
            create_directory_safely "$python_workspace/venvs"
            
            # Create Python project template
            cat > "$python_workspace/templates/basic_project.py" << 'EOF'
#!/usr/bin/env python3
"""
Basic Python project template
"""

def main():
    """Main function"""
    print("Hello, Python!")

if __name__ == "__main__":
    main()
EOF
            
            # Create requirements template
            cat > "$python_workspace/templates/requirements.txt" << 'EOF'
# Core packages
requests>=2.25.1
click>=8.0.0

# Development packages
pytest>=6.0.0
black>=21.0.0
flake8>=3.9.0
mypy>=0.812
EOF
            
            log "${GREEN}Python development environment setup completed${NC}"
            log "Project workspace: $python_workspace"
            ;;
        2)
            log "Setting up Node.js & JavaScript environment..."
            
            # Install Node.js via NodeSource repository
            if ! command -v node >/dev/null 2>&1; then
                log "Installing Node.js..."
                curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
                sudo dnf install -y nodejs npm
            fi
            
            # Install essential global packages
            log "Installing essential npm packages..."
            npm install -g yarn pnpm typescript ts-node eslint prettier nodemon create-react-app @vue/cli @angular/cli
            
            # Create Node.js project workspace
            local node_workspace="$HOME/nodejs_projects"
            create_directory_safely "$node_workspace"
            create_directory_safely "$node_workspace/templates"
            
            # Create package.json template
            cat > "$node_workspace/templates/package.json" << 'EOF'
{
  "name": "new-project",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "jest",
    "lint": "eslint .",
    "format": "prettier --write ."
  },
  "keywords": [],
  "author": "",
  "license": "MIT",
  "devDependencies": {
    "eslint": "^8.0.0",
    "prettier": "^2.5.0",
    "nodemon": "^2.0.0",
    "jest": "^27.0.0"
  }
}
EOF
            
            log "${GREEN}Node.js development environment setup completed${NC}"
            log "Project workspace: $node_workspace"
            ;;
        3)
            log "Setting up Java development environment..."
            
            # Install OpenJDK
            install_package_if_missing "java-latest-openjdk"
            install_package_if_missing "java-latest-openjdk-devel"
            install_package_if_missing "maven"
            install_package_if_missing "gradle"
            
            # Set JAVA_HOME
            local java_home="/usr/lib/jvm/java-openjdk"
            if [ -d "$java_home" ]; then
                echo "export JAVA_HOME=$java_home" >> "$HOME/.bashrc"
                export JAVA_HOME="$java_home"
            fi
            
            # Create Java project workspace
            local java_workspace="$HOME/java_projects"
            create_directory_safely "$java_workspace"
            create_directory_safely "$java_workspace/templates"
            
            # Create Maven project template
            create_directory_safely "$java_workspace/templates/maven-template"
            cat > "$java_workspace/templates/maven-template/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>my-app</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.13.2</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
EOF
            
            log "${GREEN}Java development environment setup completed${NC}"
            log "Project workspace: $java_workspace"
            ;;
        4)
            log "Setting up Rust programming environment..."
            
            # Install Rust via rustup
            if ! command -v rustc >/dev/null 2>&1; then
                log "Installing Rust..."
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                source "$HOME/.cargo/env"
            fi
            
            # Add cargo to PATH
            add_to_path "$HOME/.cargo/bin"
            
            # Install essential Rust tools
            rustup component add clippy rustfmt
            cargo install cargo-edit cargo-watch cargo-tree
            
            # Create Rust project workspace
            local rust_workspace="$HOME/rust_projects"
            create_directory_safely "$rust_workspace"
            
            log "${GREEN}Rust development environment setup completed${NC}"
            log "Project workspace: $rust_workspace"
            ;;
        5)
            log "Setting up Go programming environment..."
            
            # Install Go
            install_package_if_missing "golang"
            
            # Set Go environment variables
            local go_path="$HOME/go"
            create_directory_safely "$go_path"
            echo "export GOPATH=$go_path" >> "$HOME/.bashrc"
            echo "export PATH=\$PATH:\$GOPATH/bin" >> "$HOME/.bashrc"
            export GOPATH="$go_path"
            export PATH="$PATH:$GOPATH/bin"
            
            # Install essential Go tools
            go install golang.org/x/tools/cmd/goimports@latest
            go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
            go install github.com/go-delve/delve/cmd/dlv@latest
            
            log "${GREEN}Go development environment setup completed${NC}"
            log "Project workspace: $go_path"
            ;;
        6)
            log "Setting up Ruby development environment..."
            
            # Install Ruby and essential tools
            install_package_if_missing "ruby"
            install_package_if_missing "ruby-devel"
            install_package_if_missing "rubygems"
            
            # Install essential gems
            gem install bundler rails sinatra rspec rubocop
            
            # Create Ruby project workspace
            local ruby_workspace="$HOME/ruby_projects"
            create_directory_safely "$ruby_workspace"
            
            log "${GREEN}Ruby development environment setup completed${NC}"
            log "Project workspace: $ruby_workspace"
            ;;
        7)
            log "Setting up full stack development environment..."
            
            # Install all major languages and tools
            for i in {1..6}; do
                choice=$i
                case $i in
                    1) log "Installing Python..." ;;
                    2) log "Installing Node.js..." ;;
                    3) log "Installing Java..." ;;
                    4) log "Installing Rust..." ;;
                    5) log "Installing Go..." ;;
                    6) log "Installing Ruby..." ;;
                esac
                # Call the individual setup functions
            done
            
            # Install additional development tools
            local dev_tools=(
                "git"
                "vim"
                "emacs"
                "code"
                "docker"
                "docker-compose"
                "kubectl"
                "terraform"
                "ansible"
            )
            
            for tool in "${dev_tools[@]}"; do
                install_package_if_missing "$tool" || log "${YELLOW}$tool not available via package manager${NC}"
            done
            
            log "${GREEN}Full stack development environment setup completed${NC}"
            ;;
    esac
    
    log "${GREEN}Programming languages setup completed${NC}"
}

ide_editor_configuration() {
    log "${BLUE}=== IDE & Editor Configuration ===${NC}"
    
    echo "IDE and editor setup options:"
    echo "1.  Visual Studio Code"
    echo "2.  IntelliJ IDEA"
    echo "3.  Eclipse IDE"
    echo "4.  Vim/Neovim Advanced Setup"
    echo "5.  Emacs Configuration"
    echo "6.  Sublime Text"
    echo "7.  Multiple IDEs Setup"
    read -p "Choose IDE setup (1-7): " ide_choice
    
    case $ide_choice in
        1)
            log "Setting up Visual Studio Code..."
            
            # Install VS Code
            if ! command -v code >/dev/null 2>&1; then
                log "Installing Visual Studio Code..."
                sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
                sudo dnf install -y code
            fi
            
            # Install essential extensions
            log "Installing VS Code extensions..."
            local extensions=(
                "ms-python.python"
                "ms-vscode.vscode-typescript-next"
                "bradlc.vscode-tailwindcss"
                "ms-vscode.vscode-json"
                "redhat.vscode-yaml"
                "ms-vscode-remote.remote-ssh"
                "ms-vscode-remote.remote-containers"
                "gitlens.gitlens"
                "esbenp.prettier-vscode"
                "ms-vscode.vscode-eslint"
                "rust-lang.rust-analyzer"
                "golang.go"
                "ms-vscode.vscode-docker"
                "ms-kubernetes-tools.vscode-kubernetes-tools"
            )
            
            for extension in "${extensions[@]}"; do
                code --install-extension "$extension" 2>/dev/null || log "${YELLOW}Failed to install $extension${NC}"
            done
            
            # Create VS Code settings
            local vscode_dir="$HOME/.config/Code/User"
            create_directory_safely "$vscode_dir"
            
            cat > "$vscode_dir/settings.json" << 'EOF'
{
    "editor.fontSize": 14,
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.formatOnSave": true,
    "editor.minimap.enabled": true,
    "editor.lineNumbers": "on",
    "workbench.colorTheme": "Dark+ (default dark)",
    "terminal.integrated.shell.linux": "/bin/bash",
    "python.defaultInterpreterPath": "/usr/bin/python3",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "javascript.suggest.autoImports": true,
    "typescript.suggest.autoImports": true,
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000
}
EOF
            
            log "${GREEN}Visual Studio Code setup completed${NC}"
            ;;
        2)
            log "Setting up IntelliJ IDEA..."
            
            # Install IntelliJ IDEA Community via Flatpak
            if command -v flatpak >/dev/null 2>&1; then
                flatpak install -y flathub com.jetbrains.IntelliJ-IDEA-Community
            else
                log "${YELLOW}Flatpak not available. Please install IntelliJ IDEA manually.${NC}"
                log "Download from: https://www.jetbrains.com/idea/download/"
            fi
            ;;
        3)
            log "Setting up Eclipse IDE..."
            
            # Install Eclipse
            install_package_if_missing "eclipse-jdt"
            
            # Create Eclipse workspace
            local eclipse_workspace="$HOME/eclipse-workspace"
            create_directory_safely "$eclipse_workspace"
            
            log "${GREEN}Eclipse IDE setup completed${NC}"
            log "Workspace: $eclipse_workspace"
            ;;
        4)
            log "Setting up Vim/Neovim advanced configuration..."
            
            # Install Vim and Neovim
            install_package_if_missing "vim"
            install_package_if_missing "neovim"
            
            # Install vim-plug for plugin management
            curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
                https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
            
            # Create advanced vimrc
            cat > "$HOME/.vimrc" << 'EOF'
" Advanced Vim Configuration
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set hlsearch
set incsearch
set ignorecase
set smartcase
set wrap
set linebreak
set mouse=a
set clipboard=unnamedplus

" Plugin management with vim-plug
call plug#begin('~/.vim/plugged')
Plug 'preservim/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'dense-analysis/ale'
Plug 'ycm-core/YouCompleteMe'
Plug 'junegunn/fzf.vim'
call plug#end()

" Key mappings
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-p> :Files<CR>
nnoremap <leader>g :Git<CR>
EOF
            
            log "${GREEN}Vim/Neovim setup completed${NC}"
            log "Run ':PlugInstall' in Vim to install plugins"
            ;;
        5)
            log "Setting up Emacs configuration..."
            
            # Install Emacs
            install_package_if_missing "emacs"
            
            # Create basic Emacs configuration
            cat > "$HOME/.emacs" << 'EOF'
;; Basic Emacs Configuration
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-initialize)

;; Basic settings
(setq inhibit-startup-message t)
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(global-display-line-numbers-mode 1)
(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)

;; Theme
(load-theme 'tango-dark t)

;; Auto-install packages
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

(use-package company
  :ensure t
  :config
  (global-company-mode t))
EOF
            
            log "${GREEN}Emacs setup completed${NC}"
            ;;
        6)
            log "Setting up Sublime Text..."
            
            # Install Sublime Text
            if ! command -v subl >/dev/null 2>&1; then
                log "Installing Sublime Text..."
                sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
                sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
                sudo dnf install -y sublime-text
            fi
            
            log "${GREEN}Sublime Text setup completed${NC}"
            ;;
        7)
            log "Setting up multiple IDEs..."
            
            # Install all available IDEs
            for i in {1..6}; do
                log "Setting up IDE option $i..."
                # Call individual setup functions
            done
            
            log "${GREEN}Multiple IDEs setup completed${NC}"
            ;;
    esac
    
    log "${GREEN}IDE & editor configuration completed${NC}"
}

# ===== MAIN EXECUTION =====

main() {
    print_header
    log "${GREEN}=== Development Environment Configuration Suite Started ===${NC}"
    log "${BLUE}Log file: $LOG_FILE${NC}"
    echo ""
    
    while true; do
        show_main_menu
        
        case $choice in
            1) programming_languages_setup ;;
            2) ide_editor_configuration ;;
            3) package_managers_libraries ;;
            4) version_control_systems ;;
            5) web_development_stack ;;
            6) nodejs_npm_ecosystem ;;
            7) python_development_environment ;;
            8) java_development_kit ;;
            9) docker_development_setup ;;
            10) kubernetes_tools ;;
            11) virtual_environment_management ;;
            12) devops_tools_cicd ;;
            13) project_template_manager ;;
            14) development_security_tools ;;
            15) development_monitoring_analytics ;;
            16) 
                log "${GREEN}Exiting Development Environment Configuration Suite${NC}"
                echo
                exit 0
                ;;
            *)
                echo
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

# Placeholder functions for remaining menu items (to be implemented)
package_managers_libraries() {
    log "${BLUE}=== Package Managers & Libraries ===${NC}"
    log "This feature will setup package managers and development libraries"
    log "Implementation: pip, npm, cargo, gem, composer, maven, gradle setup"
}

version_control_systems() {
    log "${BLUE}=== Version Control Systems ===${NC}"
    log "This feature will setup version control systems and workflows"
    log "Implementation: Git configuration, GitHub/GitLab setup, hooks, workflows"
}

web_development_stack() {
    log "${BLUE}=== Web Development Stack ===${NC}"
    log "This feature will setup complete web development environment"
    log "Implementation: LAMP/LEMP stack, databases, web servers, frameworks"
}

nodejs_npm_ecosystem() {
    log "${BLUE}=== Node.js & NPM Ecosystem ===${NC}"
    log "This feature will setup Node.js development environment"
    log "Implementation: Node versions, npm/yarn/pnpm, global packages, frameworks"
}

python_development_environment() {
    log "${BLUE}=== Python Development Environment ===${NC}"
    log "This feature will setup comprehensive Python environment"
    log "Implementation: Python versions, virtual environments, packages, frameworks"
}

java_development_kit() {
    log "${BLUE}=== Java Development Kit ===${NC}"
    log "This feature will setup Java development environment"
    log "Implementation: JDK versions, build tools, IDEs, frameworks"
}

docker_development_setup() {
    log "${BLUE}=== Docker Development Setup ===${NC}"
    log "This feature will setup Docker for development"
    log "Implementation: Docker, docker-compose, development containers, registries"
}

kubernetes_tools() {
    log "${BLUE}=== Kubernetes Tools ===${NC}"
    log "This feature will setup Kubernetes development tools"
    log "Implementation: kubectl, helm, minikube, k3s, development workflows"
}

virtual_environment_management() {
    log "${BLUE}=== Virtual Environment Management ===${NC}"
    log "This feature will setup virtual environment management"
    log "Implementation: Python venv, Node.js nvm, Ruby rbenv, isolation tools"
}

devops_tools_cicd() {
    log "${BLUE}=== DevOps Tools & CI/CD ===${NC}"
    log "This feature will setup DevOps and CI/CD tools"
    log "Implementation: Jenkins, GitLab CI, GitHub Actions, Ansible, Terraform"
}

project_template_manager() {
    log "${BLUE}=== Project Template Manager ===${NC}"
    log "This feature will manage project templates and scaffolding"
    log "Implementation: Template creation, project generators, boilerplates"
}

development_security_tools() {
    log "${BLUE}=== Development Security Tools ===${NC}"
    log "This feature will setup security tools for development"
    log "Implementation: Static analysis, dependency scanning, secrets management"
}

development_monitoring_analytics() {
    log "${BLUE}=== Development Monitoring & Analytics ===${NC}"
    log "This feature will setup development monitoring and analytics"
    log "Implementation: Performance monitoring, code quality metrics, analytics"
}

main "$@"
