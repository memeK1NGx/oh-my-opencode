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
REPO_FASCIABASE="https://github.com/memeK1NGx/FASCIABASE.git"
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
        log_warning "redis-cli not found. Legacy Redis integration may not work."
        log_info "FASCIABASE will be the primary transport (Redis is legacy fallback)"
    fi
    
    # Check for Kotlin (optional for FASCIABASE development)
    if ! command_exists kotlin && ! command_exists kotlinc; then
        log_warning "Kotlin not found. FASCIABASE source development will not be available."
        log_info "Pre-built FASCIABASE binaries will be used if available."
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
    log_info "Foundation: FASCIABASE v1.0 Mesh Neuro System"
    
    if [ -d "$WORKSPACE_DIR" ]; then
        log_warning "Workspace directory already exists"
        read -p "Do you want to continue? This may overwrite existing files (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted by user"
            exit 0
        fi
    fi
    
    mkdir -p "$WORKSPACE_DIR/.omega/"{config,fascia,state,logs}
    log_success "Workspace structure created (FASCIABASE-enabled)"
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
    
    # Layer 0: Foundation
    clone_repo "$REPO_FASCIABASE" "FASCIABASE"
    
    # Application layer repositories
    clone_repo "$REPO_OH_MY_OPENCODE" "oh-my-opencode"
    clone_repo "$REPO_OPENCODE" "opencode"
    clone_repo "$REPO_GODMOD3" "GODMOD3"
    clone_repo "$REPO_GPT_OSS_RECIPES" "gpt-oss-recipes"
    
    # Future module repositories (these may not exist yet)
    clone_repo "$REPO_ALPH4" "ALPH4" || true
    clone_repo "$REPO_HEAL1" "HEAL1" || true
    clone_repo "$REPO_26" "26" || true
    clone_repo "$REPO_K1NG" "K1NG" || true
    
    log_success "Repository cloning complete (FASCIABASE + applications)"
}

# Install FASCIABASE dependencies
install_fasciabase() {
    log_info "Installing FASCIABASE dependencies..."
    
    cd "$WORKSPACE_DIR/FASCIABASE"
    
    if [ -f "build.gradle.kts" ] || [ -f "build.gradle" ]; then
        if command_exists gradle; then
            gradle build
            log_success "FASCIABASE built successfully (Gradle)"
        elif command_exists ./gradlew; then
            ./gradlew build
            log_success "FASCIABASE built successfully (Gradle Wrapper)"
        else
            log_warning "Gradle not found, skipping FASCIABASE build"
            log_info "Pre-built binaries will be used if available"
        fi
    elif [ -f "pom.xml" ]; then
        if command_exists mvn; then
            mvn package
            log_success "FASCIABASE built successfully (Maven)"
        else
            log_warning "Maven not found, skipping FASCIABASE build"
        fi
    else
        log_warning "FASCIABASE build configuration not found"
        log_info "Assuming pre-built binaries or repository placeholder"
    fi
    
    cd - > /dev/null
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
    
    install_fasciabase
    install_oh_my_opencode
    install_opencode
    install_godmod3
    install_gpt_oss_recipes
    
    log_success "All dependencies installed (FASCIABASE + applications)"
}

# Setup FASCIABASE mesh configuration
setup_fasciabase_mesh() {
    log_info "Configuring FASCIABASE mesh network..."
    
    local fascia_config="$WORKSPACE_DIR/.omega/fascia/mesh.json"
    
    cat > "$fascia_config" << 'EOF'
{
  "version": "1.0",
  "mesh_id": "omega-super-system",
  "nodes": [
    {
      "node_id": "fasciabase-core",
      "address": "localhost:9000",
      "role": "mesh_coordinator"
    },
    {
      "node_id": "oh-my-opencode",
      "address": "localhost:9001",
      "role": "orchestrator"
    },
    {
      "node_id": "godmod3-trader-1",
      "address": "localhost:9002",
      "role": "executor"
    },
    {
      "node_id": "gpt-oss-recipes",
      "address": "localhost:9003",
      "role": "trainer"
    }
  ],
  "channels": {
    "omega.godmod3.positions": {"buffer_size": 1000, "ttl": 60},
    "omega.godmod3.trades": {"buffer_size": 10000, "ttl": 3600},
    "omega.godmod3.pnl": {"buffer_size": 1000, "ttl": 300},
    "omega.godmod3.metrics": {"buffer_size": 1000, "ttl": 300},
    "omega.godmod3.tensions": {"buffer_size": 100, "ttl": 60},
    "omega.models.deploy": {"buffer_size": 10, "ttl": 0}
  },
  "transport": {
    "protocol": "fascia",
    "encryption": "tls13",
    "compression": "zstd"
  },
  "health": {
    "heartbeat_interval_ms": 1000,
    "timeout_ms": 5000,
    "auto_recovery": true
  }
}
EOF
    
    log_success "FASCIABASE mesh configuration created"
}

# Setup GODMOD3 Redis configuration (legacy fallback)
setup_godmod3_redis() {
    log_info "Configuring GODMOD3 Redis integration..."
    
    local godmod3_dir="$WORKSPACE_DIR/GODMOD3"
    local config_file="$godmod3_dir/config.py"
    
    log_info "Configuring GODMOD3 (FASCIABASE primary, Redis fallback)..."
    
    if [ ! -f "$config_file" ]; then
        cat > "$config_file" << 'EOF'
# GODMOD3 Configuration
# Generated by oh-my-opencode unify_system.sh
# FASCIABASE Edition

# OMEGA Integration Settings (FASCIABASE Primary)
OMEGA_INTEGRATION = {
    "enabled": True,
    "transport": "fasciabase",  # Primary: FASCIABASE mesh
    "fascia_mesh": {
        "node_id": "godmod3-trader-1",
        "mesh_config": "../.omega/fascia/mesh.json",
        "channels": {
            "positions": "omega.godmod3.positions",
            "trades": "omega.godmod3.trades",
            "pnl": "omega.godmod3.pnl",
            "metrics": "omega.godmod3.metrics",
            "errors": "omega.godmod3.tensions"
        }
    },
    "log_format": "json",
    "log_dir": "../.omega/logs/godmod3"
}

# Legacy Redis Configuration (Fallback)
OMEGA_INTEGRATION_LEGACY = {
    "enabled": False,  # Disabled by default, enable for fallback
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

# Redis connection parameters (legacy)
REDIS_CONFIG = {
    "host": OMEGA_INTEGRATION_LEGACY["redis_host"],
    "port": OMEGA_INTEGRATION_LEGACY["redis_port"],
    "db": OMEGA_INTEGRATION_LEGACY["redis_db"],
    "decode_responses": True
}
EOF
        log_success "GODMOD3 config.py created (FASCIABASE-enabled)"
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
  "version": "2.0",
  "workspace": "omega-workspace",
  "foundation": "FASCIABASE v1.0",
  "components": {
    "FASCIABASE": {
      "path": "./FASCIABASE",
      "role": "foundation",
      "layer": 0,
      "status": "active",
      "mesh": {
        "config": "./.omega/fascia/mesh.json",
        "coordinator": "localhost:9000"
      }
    },
    "oh-my-opencode": {
      "path": "./oh-my-opencode",
      "role": "orchestrator",
      "layer": 1,
      "status": "active",
      "fascia_node": "oh-my-opencode"
    },
    "opencode": {
      "path": "./opencode",
      "role": "runtime",
      "layer": 1,
      "status": "active"
    },
    "GODMOD3": {
      "path": "./GODMOD3",
      "role": "execution",
      "layer": 1,
      "status": "active",
      "fascia_node": "godmod3-trader-1",
      "legacy_redis": {
        "enabled": false,
        "host": "localhost",
        "port": 6379,
        "db": 0
      }
    },
    "gpt-oss-recipes": {
      "path": "./gpt-oss-recipes",
      "role": "training",
      "layer": 1,
      "status": "active",
      "fascia_node": "gpt-oss-recipes"
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
    "transport": "fasciabase",
    "omega_loop": {
      "enabled": false,
      "frequency": "hourly",
      "transport": "fascia",
      "phases": [
        "data_collection",
        "strategic_decision",
        "model_finetuning",
        "deployment",
        "monitoring"
      ]
    },
    "performance_targets": {
      "latency_p99_ms": 1,
      "throughput_signals_per_sec": 100000,
      "uptime_percent": 99.99
    }
  }
}
EOF
    
    log_success "OMEGA configuration created at $omega_config (FASCIABASE v2.0)"
}

# Create verification script
create_verification_script() {
    log_info "Creating verification script..."
    
    local verify_script="$WORKSPACE_DIR/verify_integration.sh"
    
    cat > "$verify_script" << 'EOF'
#!/usr/bin/env bash
#
# OMEGA System Verification Script (FASCIABASE Edition)
#

set -euo pipefail

echo "=== OMEGA System Verification (FASCIABASE v2.0) ==="
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

echo "Layer 0 - Foundation:"
check_repo "FASCIABASE"

echo
echo "Layer 1 - Application Components:"
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

if [ -f ".omega/fascia/mesh.json" ]; then
    echo "✓ FASCIABASE mesh config exists"
else
    echo "✗ FASCIABASE mesh config missing"
fi

echo
echo "Checking FASCIABASE mesh (primary transport)..."
# Note: FASCIABASE mesh check would require actual service running
echo "ℹ FASCIABASE mesh status: Check after starting mesh coordinator"
echo "  Start mesh: cd FASCIABASE && ./start-mesh.sh"

echo
echo "Checking Redis connection (legacy fallback)..."
if command -v redis-cli >/dev/null 2>&1; then
    if redis-cli ping >/dev/null 2>&1; then
        echo "✓ Redis is running (fallback available)"
    else
        echo "⚠ Redis is not accessible (optional legacy fallback)"
        echo "  Note: FASCIABASE is primary, Redis is fallback only"
    fi
else
    echo "⚠ redis-cli not found (optional legacy fallback)"
fi

echo
echo "=== Verification Complete ==="
echo
echo "Next steps:"
echo "1. Start FASCIABASE mesh: cd FASCIABASE && ./start-mesh.sh"
echo "2. Configure OpenCode: see UNIFIED_ARCHITECTURE.md"
echo "3. Run GODMOD3: cd GODMOD3 && python3 main.py"
echo "4. Activate OMEGA loop in .omega/config/omega.json"
echo "5. Monitor fascia channels: cd FASCIABASE && ./monitor-mesh.sh"
echo
echo "Performance targets (FASCIABASE):"
echo "- Latency P99: < 1ms"
echo "- Throughput: 100k+ signals/sec"
echo "- Uptime: 99.99%"
EOF
    
    chmod +x "$verify_script"
    log_success "Verification script created (FASCIABASE-aware)"
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

### 2. Start FASCIABASE Mesh (Primary)
```bash
cd FASCIABASE
./start-mesh.sh
```

### 3. (Optional) Start Redis (Legacy Fallback)
```bash
redis-server
```

### 4. Configure OpenCode
Edit `~/.config/opencode/opencode.json`:
```json
{
  "plugin": [
    "file:///absolute/path/to/omega-workspace/oh-my-opencode/dist/index.js"
  ]
}
```

### 5. Run GODMOD3
```bash
cd GODMOD3
python3 main.py
```

### 6. Activate OMEGA Loop
Edit `.omega/config/omega.json` and set `integration.omega_loop.enabled` to `true`.

## Architecture

See [UNIFIED_ARCHITECTURE.md](./oh-my-opencode/UNIFIED_ARCHITECTURE.md) for detailed architecture documentation (FASCIABASE Edition).

## Directory Structure

```
omega-workspace/
├── FASCIABASE/            # Layer 0: The Foundation
│   ├── fascia-core/       # Mesh implementation
│   └── fascia-bindings/   # Language bindings
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
    ├── fascia/            # FASCIABASE mesh config
    │   └── mesh.json
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
    echo "║         FASCIABASE v1.0 Foundation Enabled              ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo
    log_success "Workspace created at: $WORKSPACE_DIR"
    echo
    echo "Next steps:"
    echo "  1. cd $WORKSPACE_DIR"
    echo "  2. ./verify_integration.sh"
    echo "  3. Start FASCIABASE mesh: cd FASCIABASE && ./start-mesh.sh"
    echo "  4. (Optional) Start Redis fallback: redis-server"
    echo "  5. Configure OpenCode with the plugin path"
    echo "  6. See UNIFIED_ARCHITECTURE.md for detailed setup"
    echo
    log_info "The OMEGA loop is initially disabled."
    log_info "Enable it in .omega/config/omega.json after testing."
    log_info "FASCIABASE provides sub-millisecond latency vs. legacy Redis (50-100ms)"
    echo
}

# Main execution
main() {
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║       OMEGA Super System Unification Script             ║"
    echo "║         Project Resonance v2.0 (FASCIABASE)             ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo
    
    check_prerequisites
    create_workspace
    clone_repositories
    install_dependencies
    setup_fasciabase_mesh
    setup_godmod3_redis
    setup_oh_my_opencode_integration
    create_verification_script
    create_workspace_readme
    print_summary
}

# Run main function
main
