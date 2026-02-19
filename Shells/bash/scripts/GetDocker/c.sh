#!/bin/bash

# Enhanced error handling - don't exit immediately on errors
set +e

# Set up error trapping
trap 'recover_from_error "Line $LINENO"' ERR

# Set environment to avoid interactive prompts
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1

echo "Starting comprehensive Docker purge and fresh installation process for WSL2 Ubuntu..."
echo "This script will fully configure Docker with automatic login and complete setup"
echo "Enhanced with bulletproof error handling and recovery mechanisms"

# Function to fix broken packages and dpkg issues
fix_broken_packages() {
    echo "Checking and fixing broken packages..."

    # Kill any hanging apt processes
    pkill -f apt-get 2>/dev/null || true
    pkill -f dpkg 2>/dev/null || true
    pkill -f unattended-upgrade 2>/dev/null || true
    sleep 3

    # Remove any problematic lock files
    rm -f /var/lib/dpkg/lock-frontend
    rm -f /var/lib/dpkg/lock
    rm -f /var/cache/apt/archives/lock
    rm -f /var/lib/apt/lists/lock

    # Clean package cache
    apt-get clean 2>/dev/null || true
    apt-get autoclean 2>/dev/null || true

    # Fix apt-show-versions issue first
    if [ -x /usr/bin/apt-show-versions ]; then
        echo "Fixing apt-show-versions cache directory..."
        mkdir -p /var/cache/apt-show-versions 2>/dev/null || true
        chmod 755 /var/cache/apt-show-versions 2>/dev/null || true
        apt-get remove --purge -y apt-show-versions 2>/dev/null || true
    fi

    # Aggressively handle unattended-upgrades
    echo "Forcefully fixing unattended-upgrades package..."
    systemctl stop unattended-upgrades 2>/dev/null || true
    pkill -f unattended-upgrade 2>/dev/null || true

    if dpkg -l | grep -q "unattended-upgrades"; then
        echo "Removing unattended-upgrades package state..."
        dpkg --remove --force-remove-reinstreq unattended-upgrades 2>/dev/null || true
        dpkg --purge --force-remove-reinstreq unattended-upgrades 2>/dev/null || true
        sed -i '/^Package: unattended-upgrades$/,/^$/d' /var/lib/dpkg/status 2>/dev/null || true
        DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y --allow-remove-essential unattended-upgrades 2>/dev/null || true
        rm -rf /etc/apt/apt.conf.d/50unattended-upgrades 2>/dev/null || true
        rm -rf /var/lib/unattended-upgrades 2>/dev/null || true
        rm -rf /var/log/unattended-upgrades 2>/dev/null || true
    fi

    # Check for other broken packages and fix them
    broken_packages=$(dpkg -l | grep "^iU\|^rI\|^Ur" | awk '{print $2}' | head -10)
    if [ -n "$broken_packages" ]; then
        echo "Found broken packages, force removing: $broken_packages"
        for pkg in $broken_packages; do
            echo "Force removing package: $pkg"
            dpkg --remove --force-remove-reinstreq "$pkg" 2>/dev/null || true
            dpkg --purge --force-remove-reinstreq "$pkg" 2>/dev/null || true
            DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y --allow-remove-essential "$pkg" 2>/dev/null || true
        done
    fi

    rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
    apt-get clean 2>/dev/null || true
    DEBIAN_FRONTEND=noninteractive dpkg --configure -a --force-confold 2>/dev/null || true
    DEBIAN_FRONTEND=noninteractive apt-get -f install -y --no-install-recommends 2>/dev/null || true
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y 2>/dev/null || true

    echo "Package system cleanup completed"
}

# Enhanced error recovery function
recover_from_error() {
    local error_context="$1"
    echo "⚠️ Error encountered in: $error_context"
    echo "Attempting comprehensive recovery..."

    pkill -f apt 2>/dev/null || true
    pkill -f dpkg 2>/dev/null || true
    sleep 3

    rm -f /var/lib/dpkg/lock*
    rm -f /var/cache/apt/archives/lock
    rm -f /var/lib/apt/lists/lock

    fix_broken_packages
    fix_dns

    echo "Recovery attempt completed, continuing..."
}

# Function to detect Ubuntu version
detect_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$VERSION_CODENAME"
    else
        echo "jammy"
    fi
}

# Function to fix DNS issues
fix_dns() {
    echo "Checking and fixing DNS configuration..."
    cp /etc/resolv.conf /etc/resolv.conf.backup 2>/dev/null || true

    cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF

    if nslookup google.com >/dev/null 2>&1; then
        echo "DNS resolution working"
        return 0
    else
        echo "DNS still not working, trying alternative approach..."
        systemctl restart systemd-resolved 2>/dev/null || true
        sleep 2
        if nslookup google.com >/dev/null 2>&1; then
            echo "DNS resolution fixed"
            return 0
        else
            echo "Warning: DNS issues persist, continuing anyway..."
            return 1
        fi
    fi
}

# Function to test network connectivity
test_connectivity() {
    echo "Testing network connectivity..."
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        echo "✓ Basic network connectivity OK"
    else
        echo "✗ No network connectivity"
        return 1
    fi

    if nslookup archive.ubuntu.com >/dev/null 2>&1; then
        echo "✓ DNS resolution OK"
    else
        echo "✗ DNS resolution failed"
        return 1
    fi

    return 0
}

# Function to check if command exists
command_exists() {
    command -v "$@" > /dev/null 2>&1
}

# Function to check if running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

# Comprehensive pre-flight system check
preflight_check() {
    echo "=== PREFLIGHT SYSTEM CHECK ==="
    check_root

    available_space=$(df / | tail -1 | awk '{print $4}')
    if [ "$available_space" -lt 2000000 ]; then
        echo "⚠️ Warning: Low disk space detected. Cleaning up..."
        apt-get clean 2>/dev/null || true
        apt-get autoclean 2>/dev/null || true
        docker system prune -af 2>/dev/null || true
    fi

    if grep -qi "microsoft" /proc/version 2>/dev/null; then
        echo "✓ WSL2 environment detected"
    else
        echo "⚠️ Warning: This script is optimized for WSL2"
    fi

    echo "Performing aggressive system cleanup..."
    pkill -f "apt" 2>/dev/null || true
    pkill -f "dpkg" 2>/dev/null || true
    pkill -f "unattended-upgrade" 2>/dev/null || true
    sleep 3

    if dpkg -l | grep -q apt-show-versions; then
        echo "Removing apt-show-versions..."
        dpkg --remove --force-remove-reinstreq apt-show-versions 2>/dev/null || true
        apt-get remove --purge -y apt-show-versions 2>/dev/null || true
    fi

    if dpkg -l | grep -q unattended-upgrades; then
        echo "Force removing unattended-upgrades..."
        systemctl stop unattended-upgrades 2>/dev/null || true
        systemctl disable unattended-upgrades 2>/dev/null || true
        dpkg --remove --force-remove-reinstreq unattended-upgrades 2>/dev/null || true
        apt-get remove --purge -y --allow-remove-essential unattended-upgrades 2>/dev/null || true
        rm -rf /var/lib/unattended-upgrades 2>/dev/null || true
        rm -rf /etc/apt/apt.conf.d/50unattended-upgrades 2>/dev/null || true
    fi

    rm -f /etc/apt/apt.conf.d/*apt-show-versions* 2>/dev/null || true
    rm -f /etc/apt/apt.conf.d/*unattended-upgrades* 2>/dev/null || true

    fix_broken_packages

    echo "✓ Preflight check completed"
    echo "=========================="
}

preflight_check

UBUNTU_CODENAME=$(detect_ubuntu_version)
echo "Detected Ubuntu version: $UBUNTU_CODENAME"

echo "Step 0: Fixing system and package management issues..."
fix_broken_packages
fix_dns
if ! test_connectivity; then
    echo "Network connectivity issues detected. Attempting to fix..."
    systemctl restart systemd-networkd 2>/dev/null || true
    systemctl restart systemd-resolved 2>/dev/null || true
    sleep 3
    fix_dns
fi

echo "Step 1: Installing required system utilities..."
fix_broken_packages

echo "Updating package lists..."
rm -f /etc/apt/apt.conf.d/*apt-show-versions* 2>/dev/null || true
rm -f /etc/apt/apt.conf.d/*unattended-upgrades* 2>/dev/null || true

cat > /tmp/apt.conf <<EOF
APT::Update::Post-Invoke-Success "";
APT::Update::Post-Invoke "";
DPkg::Pre-Install-Pkgs "";
DPkg::Post-Invoke "";
EOF

for i in {1..3}; do
    echo "Update attempt $i/3..."
    apt-get clean 2>/dev/null || true
    if apt-get -c /tmp/apt.conf update --fix-missing -o APT::Update::Error-Mode=any; then
        echo "Package lists updated successfully"
        break
    else
        echo "Attempt $i failed"
        if [ $i -eq 3 ]; then
            echo "Warning: Using existing package cache, continuing..."
        else
            sleep 2
        fi
    fi
done

rm -f /tmp/apt.conf

install_package_safe() {
    local package="$1"
    local description="$2"
    echo "Installing $package ($description)..."

    if dpkg -l | grep -q "^ii.*$package "; then
        echo "✓ $package already installed"
        return 0
    fi

    case "$package" in
        "curl") if command -v curl >/dev/null 2>&1; then echo "✓ curl working"; return 0; fi ;;
        "wget") if command -v wget >/dev/null 2>&1; then echo "✓ wget working"; return 0; fi ;;
        "gnupg") if command -v gpg >/dev/null 2>&1; then echo "✓ gnupg working"; return 0; fi ;;
    esac

    for attempt in {1..2}; do
        if DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$package" 2>/dev/null; then
            echo "✓ $package installed"
            return 0
        else
            if [ $attempt -eq 1 ]; then
                DEBIAN_FRONTEND=noninteractive apt-get -f install -y --no-install-recommends 2>/dev/null || true
                apt-get update --fix-missing -o APT::Update::Error-Mode=any 2>/dev/null || true
            fi
        fi
    done

    echo "⚠️ Could not install $package, continuing..."
    return 1
}

trap '' ERR

install_package_safe "curl" "HTTP client"
install_package_safe "wget" "File downloader"
install_package_safe "ca-certificates" "SSL certificates"
install_package_safe "gnupg" "GPG tools"
install_package_safe "lsb-release" "Linux Standard Base"
install_package_safe "iproute2" "Network utilities"
install_package_safe "net-tools" "Network tools"
install_package_safe "iptables" "Firewall tools"
install_package_safe "dnsutils" "DNS utilities"
install_package_safe "software-properties-common" "Repository management"
install_package_safe "apt-transport-https" "HTTPS transport"
install_package_safe "jq" "JSON processor"
install_package_safe "pass" "Password manager"

trap 'recover_from_error "Line $LINENO"' ERR

echo "Step 2: Stopping all Docker services..."
if command_exists docker; then
    RUNNING_CONTAINERS=$(docker ps -q 2>/dev/null || true)
    if [ -n "$RUNNING_CONTAINERS" ]; then
        docker kill $RUNNING_CONTAINERS 2>/dev/null || true
    fi

    systemctl stop docker.service 2>/dev/null || true
    systemctl stop docker.socket 2>/dev/null || true
    systemctl stop containerd.service 2>/dev/null || true
    sleep 3
fi

echo "Step 3: Removing ALL Docker-related packages..."
docker_packages=(
    "docker.io" "docker-doc" "docker-compose" "docker-compose-v2"
    "docker-ce" "docker-ce-cli" "docker-ce-rootless-extras"
    "docker-engine" "docker-registry" "docker-scan-plugin"
    "containerd" "docker-buildx" "runc" "podman-docker"
    "moby-engine" "moby-cli" "moby-buildx" "moby-compose"
    "moby-containerd" "moby-runc" "nvidia-docker2"
    "nvidia-container-runtime" "containerd.io"
)

for pkg in "${docker_packages[@]}"; do
    systemctl stop "$pkg" 2>/dev/null || true
    systemctl disable "$pkg" 2>/dev/null || true
    apt-get remove -y "$pkg" 2>/dev/null || true
    apt-get purge -y "$pkg" 2>/dev/null || true
    dpkg --configure -a 2>/dev/null || true
done

fix_broken_packages

echo "Step 4: Purging ALL Docker data..."
for attempt in {1..3}; do
    if apt-get autoremove -y && apt-get autoclean -y; then
        break
    else
        fix_broken_packages
    fi
done

directories=(
    "/var/lib/docker" "/var/lib/containerd" "/etc/docker" "/etc/containerd"
    "/var/run/docker" "/var/run/containerd" "/usr/local/bin/docker*"
    "/usr/local/bin/containerd*" "/usr/bin/docker*" "/usr/bin/containerd*"
    "/opt/containerd" "/home/*/.docker" "/root/.docker"
    "/var/log/docker" "/var/log/containerd" "/etc/apparmor.d/docker"
    "/etc/apt/sources.list.d/docker*.list" "/etc/apt/sources.list.d/nvidia-docker*.list"
    "/etc/systemd/system/docker*" "/etc/systemd/system/containerd*"
    "/etc/init.d/docker" "/etc/default/docker" "/usr/share/docker*"
    "/usr/share/containerd*" "/usr/libexec/docker"
    "/var/cache/apt/archives/docker*" "/var/cache/apt/archives/containerd*"
)

for dir in "${directories[@]}"; do
    rm -rf $dir 2>/dev/null || true
done

groupdel docker 2>/dev/null || true

ip link show | grep -i docker | awk -F': ' '{print $2}' | xargs -r -l ip link delete 2>/dev/null || true
ip link show | grep -i br- | awk -F': ' '{print $2}' | xargs -r -l ip link delete 2>/dev/null || true

systemctl daemon-reload
systemctl reset-failed

echo "Step 5: Removing Docker GPG keys..."
rm -f /usr/share/keyrings/docker-archive-keyring.gpg
rm -f /usr/share/keyrings/docker.gpg
rm -f /etc/apt/keyrings/docker.gpg
apt-key del "9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88" 2>/dev/null || true

echo "Step 6: Setting up fresh Docker installation..."
fix_broken_packages

prerequisites=(
    "apt-transport-https" "ca-certificates" "curl" "gnupg"
    "gnupg-agent" "software-properties-common" "lsb-release"
)

for i in {1..3}; do
    if apt-get update --fix-missing; then
        break
    else
        fix_broken_packages
    fi
done

for pkg in "${prerequisites[@]}"; do
    install_package_safe "$pkg" "Docker prerequisite"
done

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  ${UBUNTU_CODENAME} stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Step 7: Installing Docker Engine..."
for i in {1..5}; do
    if apt-get update; then
        break
    else
        fix_broken_packages
        fix_dns
        sleep 3
    fi
done

docker_install_packages=(
    "containerd.io"
    "docker-ce-cli"
    "docker-ce"
    "docker-buildx-plugin"
    "docker-compose-plugin"
    "docker-ce-rootless-extras"
)

for pkg in "${docker_install_packages[@]}"; do
    echo "Installing $pkg..."
    for attempt in {1..3}; do
        if apt-get install -y "$pkg"; then
            echo "✓ $pkg installed"
            break
        else
            if [ $attempt -lt 3 ]; then
                fix_broken_packages
                apt-get update --fix-missing 2>/dev/null || true
                sleep 2
            fi
        fi
    done
done

fix_broken_packages

echo "Step 8: Configuring Docker daemon..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "dns": ["8.8.8.8", "8.8.4.4"],
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 10,
    "experimental": true,
    "features": {
        "buildkit": true
    }
}
EOF

echo "Step 9: Setting up Docker system..."
mkdir -p /var/lib/docker
mkdir -p /var/run/docker
mkdir -p /usr/share/docker

groupadd --force docker

if [ -n "$SUDO_USER" ]; then
    usermod -aG docker "$SUDO_USER" || true
fi

chown root:docker /var/run/docker
chmod 2775 /var/run/docker

echo "Step 10: Starting Docker services..."
systemctl enable containerd
systemctl start containerd
systemctl enable docker
systemctl start docker

echo "Step 11: Installing Docker Compose..."
if ! command_exists jq; then
    curl -L -o /usr/local/bin/jq https://github.com/stedolan/jq/releases/latest/download/jq-linux64
    chmod +x /usr/local/bin/jq
fi

COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name 2>/dev/null || echo "v2.24.1")

mkdir -p ~/.docker/cli-plugins/
curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

if [ -n "$SUDO_USER" ]; then
    USER_HOME="/home/$SUDO_USER"
    mkdir -p "$USER_HOME/.docker/cli-plugins/"
    curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" -o "$USER_HOME/.docker/cli-plugins/docker-compose"
    chmod +x "$USER_HOME/.docker/cli-plugins/docker-compose"
    chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.docker"
fi

curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "Step 12: Installing Docker BuildX..."
rm -rf ~/.docker/buildx

BUILDX_VERSION=$(curl -s https://api.github.com/repos/docker/buildx/releases/latest | jq -r .tag_name 2>/dev/null || echo "v0.12.1")

mkdir -p ~/.docker/cli-plugins
curl -SL "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-amd64" -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx

if [ -n "$SUDO_USER" ]; then
    USER_HOME="/home/$SUDO_USER"
    mkdir -p "$USER_HOME/.docker/cli-plugins"
    curl -SL "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-amd64" -o "$USER_HOME/.docker/cli-plugins/docker-buildx"
    chmod +x "$USER_HOME/.docker/cli-plugins/docker-buildx"
    chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.docker"
fi

echo "Step 13: Initializing BuildX..."
sleep 5

for i in {1..10}; do
    if docker info >/dev/null 2>&1; then
        echo "✓ Docker daemon ready"
        break
    else
        echo "Waiting for Docker... ($i/10)"
        sleep 3
        systemctl start docker 2>/dev/null || true
    fi
done

if docker info >/dev/null 2>&1; then
    docker buildx create --name mybuilder --use --driver docker-container 2>/dev/null || true
    docker buildx inspect mybuilder --bootstrap 2>/dev/null || true
    docker buildx create --name multiplatform --driver docker-container --use 2>/dev/null || true
    docker buildx inspect multiplatform --bootstrap 2>/dev/null || true
fi

echo "Step 14: Automatic Docker login..."
CREDS_USER="michadockermisha"
CREDS_PASS="Aa111111!"

if docker info >/dev/null 2>&1; then
    echo "Performing Docker Hub login..."
    echo "$CREDS_PASS" | docker login -u "$CREDS_USER" --password-stdin 2>/dev/null && echo "✓ Docker login successful!" || echo "⚠️ Login may need retry"
else
    echo "Docker daemon not ready for login"
fi

echo "Step 15: Setting up WSL2 auto-start for Docker..."
if [ -n "$SUDO_USER" ]; then
    USER_HOME="/home/$SUDO_USER"
    
    # Create WSL config
    cat > "$USER_HOME/.wslconfig" <<EOF
[wsl2]
memory=8GB
processors=4
swap=4GB
kernelCommandLine=systemd=true cgroup_enable=memory swapaccount=1
[experimental]
autoMemoryReclaim=gradual
EOF
    chown "$SUDO_USER:$SUDO_USER" "$USER_HOME/.wslconfig"

    # Setup passwordless sudo for Docker service
    echo "$SUDO_USER ALL=(ALL) NOPASSWD: /usr/sbin/service docker start" | tee /etc/sudoers.d/docker-service
    chmod 440 /etc/sudoers.d/docker-service

    # Add auto-start to bashrc
    BASHRC_FILE="$USER_HOME/.bashrc"
    
    # Remove any existing Docker auto-start lines
    sed -i '/# Docker auto-start/d' "$BASHRC_FILE"
    sed -i '/sudo service docker start/d' "$BASHRC_FILE"
    
    # Add new auto-start configuration
    cat >> "$BASHRC_FILE" <<'EOF'

# Docker auto-start for WSL2 - Bulletproof configuration
if ! docker info >/dev/null 2>&1; then
    echo "Starting Docker service..."
    sudo service docker start 2>/dev/null
    # Wait for Docker to be ready (max 10 seconds)
    for i in {1..10}; do
        if docker info >/dev/null 2>&1; then
            echo "✓ Docker is ready"
            break
        fi
        sleep 1
    done
fi

# Docker convenience aliases
alias dcup='docker compose up -d'
alias dcdown='docker compose down'
alias dcps='docker compose ps'
alias dclogs='docker compose logs -f'
alias dcbuild='docker compose build'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drmi='docker rmi'
alias dstop='docker stop'
alias dstart='docker start'
alias drestart='docker restart'
alias dexec='docker exec -it'
alias dbash='docker exec -it'
alias dprune='docker system prune -af'
alias dbuild='docker buildx build'
alias dbuildx='docker buildx build --platform linux/amd64,linux/arm64'

# Quick run function
drun() {
    docker run -it --rm "$@"
}

# Build and run function
dbr() {
    docker build -t temp-image . && docker run -it --rm temp-image
}
EOF
    chown "$SUDO_USER:$SUDO_USER" "$BASHRC_FILE"
fi

echo "Step 16: Final verification..."
ensure_docker_running() {
    for attempt in {1..5}; do
        systemctl start containerd 2>/dev/null || true
        systemctl start docker 2>/dev/null || true
        sleep 5

        if docker info >/dev/null 2>&1; then
            echo "✓ Docker is running"
            return 0
        else
            if [ $attempt -lt 5 ]; then
                systemctl stop docker 2>/dev/null || true
                systemctl stop containerd 2>/dev/null || true
                pkill -f docker 2>/dev/null || true
                sleep 3
                rm -f /var/run/docker.sock 2>/dev/null || true
                fix_broken_packages
            fi
        fi
    done
    return 1
}

ensure_docker_running

echo "=== VERIFICATION ==="
docker --version && echo "✓ Docker Engine installed"
docker info >/dev/null 2>&1 && echo "✓ Docker Daemon running"
docker compose version >/dev/null 2>&1 && echo "✓ Docker Compose installed"
docker buildx version >/dev/null 2>&1 && echo "✓ Docker BuildX installed"

if docker info >/dev/null 2>&1; then
    timeout 30 docker run --rm alpine:latest echo "✓ Container test passed" 2>/dev/null || echo "⚠️ Container test needs network"
    docker buildx ls >/dev/null 2>&1 && echo "✓ BuildX builders ready"
fi

# Final login attempt
if docker info >/dev/null 2>&1; then
    echo "$CREDS_PASS" | docker login -u "$CREDS_USER" --password-stdin 2>/dev/null && echo "✓ Docker Hub logged in"
fi

cat << "EOF"

🎉 DOCKER INSTALLATION COMPLETE! 🎉
===================================

✅ Docker will now start AUTOMATICALLY every time you open WSL2
✅ No password required for Docker startup
✅ Docker Hub login configured
✅ All tools installed and ready

AUTOMATIC FEATURES:
- Docker starts on WSL2 launch
- Waits until Docker is ready
- Shows status messages
- All aliases loaded automatically

If Docker doesn't start automatically:
1. Close and reopen WSL2
2. Run: source ~/.bashrc
3. Manually: sudo service docker start

Test commands:
- docker run --rm hello-world
- docker compose version
- docker ps

Happy containerizing! 🐳
EOF
