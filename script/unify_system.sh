#!/usr/bin/env bash
#
# OMEGA Super System Unification Script
# Creates unified workspace and sets up all repositories
#
# Usage: ./script/unify_system.sh [workspace_dir]
#

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_WORKSPACE="omega-workspace"
WORKSPACE_DIR="${1:-$DEFAULT_WORKSPACE}"

# Repository URLs (update these to match actual repository locations)
REPO_OH_MY_OPENCODE="https://github.com/code-yeongyu/oh-my-opencode.git"
REPO_OPENCODE="https://github.com/opencode-ai/opencode.git"
REPO_GODMOD3="https://github.com/memeK1NGx/GODMOD3.git"
REPO_GPT_OSS_RECIPES="https://github.com/memeK1NGx/gpt-oss-recipes.git"
REPO_ALPH4="https://github.com/memeK1NGx/ALPH4.git"
REPO_HEAL1="https://github.com/memeK1NGx/HEAL1.git"
REPO_26="https://github.com/memeK1NGx/26.git"
REPO_K1NG="https://github.com/memeK1NGx/K1NG.git"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command_exists git; then
        missing_tools+=("git")
    fi
    
    if ! command_exists bun; then
        missing_tools+=("bun")
    fi
    
    if ! command_exists python3; then
        missing_tools+=("python3")
    fi
    
    if ! command_exists pip3; then
        missing_tools+=("pip3")
    fi
    
    if ! command_exists redis-cli; then
        log_warning "redis-cli not found. Redis integration may not work."
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error "Please install them before continuing."
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Create workspace directory structure
create_workspace() {
    log_info "Creating workspace at: $WORKSPACE_DIR"
    
    if [ -d "$WORKSPACE_DIR" ]; then
        log_warning "Workspace directory already exists"
        read -p "Do you want to continue? This may overwrite existing files (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted by user"
            exit 0
        fi
    fi
    
    mkdir -p "$WORKSPACE_DIR/.omega/"{config,state,logs}
    log_success "Workspace structure created"
}

# Clone a repository
clone_repo() {
    local repo_url=$1
    local repo_name=$2
    local target_dir="$WORKSPACE_DIR/$repo_name"
    
    log_info "Cloning $repo_name..."
    
    if [ -d "$target_dir" ]; then
        log_warning "$repo_name already exists, skipping clone"
        return 0
    fi
    
    if git clone "$repo_url" "$target_dir" 2>/dev/null; then
        log_success "$repo_name cloned successfully"
        return 0
    else
        log_warning "$repo_name not available (repository may not exist yet)"
        mkdir -p "$target_dir"
        echo "# $repo_name - Placeholder" > "$target_dir/README.md"
        return 1
    fi
}

# Clone all repositories
clone_repositories() {
    log_info "Cloning repositories..."
    
    # Core repositories
    clone_repo "$REPO_OH_MY_OPENCODE" "oh-my-opencode"
    clone_repo "$REPO_OPENCODE" "opencode"
    clone_repo "$REPO_GODMOD3" "GODMOD3"
    clone_repo "$REPO_GPT_OSS_RECIPES" "gpt-oss-recipes"
    
    # Future module repositories (these may not exist yet)
    clone_repo "$REPO_ALPH4" "ALPH4" || true
    clone_repo "$REPO_HEAL1" "HEAL1" || true
    clone_repo "$REPO_26" "26" || true
    clone_repo "$REPO_K1NG" "K1NG" || true
    
    log_success "Repository cloning complete"
}

# Install oh-my-opencode dependencies
install_oh_my_opencode() {
    log_info "Installing oh-my-opencode dependencies..."
    
    cd "$WORKSPACE_DIR/oh-my-opencode"
    
    if [ -f "package.json" ]; then
        bun install
        bun run build
        log_success "oh-my-opencode built successfully"
    else
        log_warning "oh-my-opencode package.json not found"
    fi
    
    cd - > /dev/null
}

# Install opencode
install_opencode() {
    log_info "Installing opencode..."
    
    cd "$WORKSPACE_DIR/opencode"
    
    if [ -f "package.json" ]; then
        bun install
        log_success "opencode installed successfully"
    elif [ -f "Cargo.toml" ]; then
        if command_exists cargo; then
            cargo build --release
            log_success "opencode built successfully (Rust)"
        else
            log_warning "cargo not found, skipping opencode build"
        fi
    else
        log_warning "opencode build configuration not found"
    fi
    
    cd - > /dev/null
}

# Install GODMOD3 dependencies
install_godmod3() {
    log_info "Installing GODMOD3 dependencies..."
    
    cd "$WORKSPACE_DIR/GODMOD3"
    
    if [ -f "requirements.txt" ]; then
        python3 -m pip install -r requirements.txt
        log_success "GODMOD3 dependencies installed"
    elif [ -f "pyproject.toml" ]; then
        python3 -m pip install -e .
        log_success "GODMOD3 installed (editable)"
    else
        log_warning "GODMOD3 requirements not found"
    fi
    
    cd - > /dev/null
}

# Install gpt-oss-recipes dependencies
install_gpt_oss_recipes() {
    log_info "Installing gpt-oss-recipes dependencies..."
    
    cd "$WORKSPACE_DIR/gpt-oss-recipes"
    
    if [ -f "requirements.txt" ]; then
        python3 -m pip install -r requirements.txt
        log_success "gpt-oss-recipes dependencies installed"
    elif [ -f "package.json" ]; then
        bun install
        log_success "gpt-oss-recipes dependencies installed"
    else
        log_warning "gpt-oss-recipes requirements not found"
    fi
    
    cd - > /dev/null
}

# Install all dependencies
install_dependencies() {
    log_info "Installing dependencies for all repositories..."
    
    install_oh_my_opencode
    install_opencode
    install_godmod3
    install_gpt_oss_recipes
    
    log_success "All dependencies installed"
}

# Setup GODMOD3 Redis configuration
setup_godmod3_redis() {
    log_info "Configuring GODMOD3 Redis integration..."
    
    local godmod3_dir="$WORKSPACE_DIR/GODMOD3"
    local config_file="$godmod3_dir/config.py"
    
    if [ ! -f "$config_file" ]; then
        cat > "$config_file" << 'EOF'
# GODMOD3 Configuration
# Generated by oh-my-opencode unify_system.sh

# OMEGA Integration Settings
OMEGA_INTEGRATION = {
    "enabled": True,
    "redis_host": "localhost",
    "redis_port": 6379,
    "redis_db": 0,
    "log_format": "json",
    "log_dir": "../.omega/logs/godmod3",
    "export_keys": [
        "positions:*",
        "trades:*",
        "pnl:*",
        "metrics:*"
    ]
}

# Redis connection parameters
REDIS_CONFIG = {
    "host": OMEGA_INTEGRATION["redis_host"],
    "port": OMEGA_INTEGRATION["redis_port"],
    "db": OMEGA_INTEGRATION["redis_db"],
    "decode_responses": True
}
EOF
        log_success "GODMOD3 config.py created"
    else
        log_warning "GODMOD3 config.py already exists, skipping"
    fi
    
    # Create log directory
    mkdir -p "$WORKSPACE_DIR/.omega/logs/godmod3"
}

# Setup oh-my-opencode integration tools
setup_oh_my_opencode_integration() {
    log_info "Configuring oh-my-opencode integration..."
    
    local omega_config="$WORKSPACE_DIR/.omega/config/omega.json"
    
    cat > "$omega_config" << 'EOF'
{
  "version": "1.0",
  "workspace": "omega-workspace",
  "components": {
    "oh-my-opencode": {
      "path": "./oh-my-opencode",
      "role": "orchestrator",
      "status": "active"
    },
    "opencode": {
      "path": "./opencode",
      "role": "runtime",
      "status": "active"
    },
    "GODMOD3": {
      "path": "./GODMOD3",
      "role": "execution",
      "status": "active",
      "redis": {
        "host": "localhost",
        "port": 6379,
        "db": 0
      }
    },
    "gpt-oss-recipes": {
      "path": "./gpt-oss-recipes",
      "role": "training",
      "status": "active"
    },
    "ALPH4": {
      "path": "./ALPH4",
      "role": "experimental",
      "status": "placeholder"
    },
    "HEAL1": {
      "path": "./HEAL1",
      "role": "monitoring",
      "status": "placeholder"
    },
    "26": {
      "path": "./26",
      "role": "reserved",
      "status": "placeholder"
    },
    "K1NG": {
      "path": "./K1NG",
      "role": "governance",
      "status": "placeholder"
    }
  },
  "integration": {
    "omega_loop": {
      "enabled": false,
      "frequency": "hourly",
      "phases": [
        "data_collection",
        "strategic_decision",
        "model_finetuning",
        "deployment",
        "monitoring"
      ]
    }
  }
}
EOF
    
    log_success "OMEGA configuration created at $omega_config"
}

# Create verification script
create_verification_script() {
    log_info "Creating verification script..."
    
    local verify_script="$WORKSPACE_DIR/verify_integration.sh"
    
    cat > "$verify_script" << 'EOF'
#!/usr/bin/env bash
#
# OMEGA System Verification Script
#

set -euo pipefail

echo "=== OMEGA System Verification ==="
echo

# Check repositories
check_repo() {
    if [ -d "$1" ]; then
        echo "✓ $1 exists"
        return 0
    else
        echo "✗ $1 missing"
        return 1
    fi
}

echo "Checking repositories..."
check_repo "oh-my-opencode"
check_repo "opencode"
check_repo "GODMOD3"
check_repo "gpt-oss-recipes"

echo
echo "Checking configuration..."
if [ -f ".omega/config/omega.json" ]; then
    echo "✓ OMEGA config exists"
else
    echo "✗ OMEGA config missing"
fi

echo
echo "Checking Redis connection..."
if command -v redis-cli >/dev/null 2>&1; then
    if redis-cli ping >/dev/null 2>&1; then
        echo "✓ Redis is running"
    else
        echo "✗ Redis is not accessible"
        echo "  Start Redis: redis-server"
    fi
else
    echo "✗ redis-cli not found"
fi

echo
echo "=== Verification Complete ==="
echo
echo "Next steps:"
echo "1. Start Redis: redis-server"
echo "2. Configure OpenCode: see UNIFIED_ARCHITECTURE.md"
echo "3. Run GODMOD3: cd GODMOD3 && python3 main.py"
echo "4. Activate OMEGA loop in .omega/config/omega.json"
EOF
    
    chmod +x "$verify_script"
    log_success "Verification script created"
}

# Create README for workspace
create_workspace_readme() {
    log_info "Creating workspace README..."
    
    cat > "$WORKSPACE_DIR/README.md" << 'EOF'
# OMEGA Super System Workspace

This workspace contains all components of the OMEGA unified architecture.

## Components

- **oh-my-opencode**: The General (Orchestrator)
- **opencode**: The Core Runtime
- **GODMOD3**: The Soldier (Execution Arm)
- **gpt-oss-recipes**: The Academy (Training)
- **ALPH4**: Alpha Sandbox (Future)
- **HEAL1**: Self-Healing Monitor (Future)
- **26**: Reserved (Future)
- **K1NG**: Governance Layer (Future)

## Getting Started

### 1. Verify Setup
```bash
./verify_integration.sh
```

### 2. Start Redis
```bash
redis-server
```

### 3. Configure OpenCode
Edit `~/.config/opencode/opencode.json`:
```json
{
  "plugin": [
    "file:///absolute/path/to/omega-workspace/oh-my-opencode/dist/index.js"
  ]
}
```

### 4. Run GODMOD3
```bash
cd GODMOD3
python3 main.py
```

### 5. Activate OMEGA Loop
Edit `.omega/config/omega.json` and set `integration.omega_loop.enabled` to `true`.

## Architecture

See [UNIFIED_ARCHITECTURE.md](./oh-my-opencode/UNIFIED_ARCHITECTURE.md) for detailed architecture documentation.

## Directory Structure

```
omega-workspace/
├── oh-my-opencode/        # The General
├── opencode/              # Core Runtime
├── GODMOD3/               # The Soldier
├── gpt-oss-recipes/       # The Academy
├── ALPH4/                 # Alpha Sandbox
├── HEAL1/                 # Self-Healing Monitor
├── 26/                    # Reserved
├── K1NG/                  # Governance Layer
└── .omega/                # Shared configuration
    ├── config/
    │   └── omega.json
    ├── state/
    └── logs/
```

## Support

For issues, see individual repository issue trackers or consult the main documentation.
EOF
    
    log_success "Workspace README created"
}

# Print summary
print_summary() {
    echo
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║          OMEGA Super System Setup Complete              ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo
    log_success "Workspace created at: $WORKSPACE_DIR"
    echo
    echo "Next steps:"
    echo "  1. cd $WORKSPACE_DIR"
    echo "  2. ./verify_integration.sh"
    echo "  3. Start Redis: redis-server"
    echo "  4. Configure OpenCode with the plugin path"
    echo "  5. See UNIFIED_ARCHITECTURE.md for detailed setup"
    echo
    log_info "The OMEGA loop is initially disabled."
    log_info "Enable it in .omega/config/omega.json after testing."
    echo
}

# Main execution
main() {
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║       OMEGA Super System Unification Script             ║"
    echo "║              Project Resonance v1.0                      ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo
    
    check_prerequisites
    create_workspace
    clone_repositories
    install_dependencies
    setup_godmod3_redis
    setup_oh_my_opencode_integration
    create_verification_script
    create_workspace_readme
    print_summary
}

# Run main function
main
