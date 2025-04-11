#!/bin/bash
# https://github.com/lucianovk/jetson-gs_usb-kernel-builder
# Automatically build and install the gs_usb CAN kernel module for NVIDIA Jetson devices running L4T R36.4.3 (Linux for Tegra). Supports both native (ARM64) and cross-compilation (x86_64) workflows.

# Colors for formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Formatting functions
print_header() {
    echo -e "${YELLOW}\n===== $1 =====${NC}"
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "[INFO] $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Initial architecture check
print_header "INITIAL CHECK"
ARCHITECTURE=$(uname -m)
IS_ARM64=0
if [ "$ARCHITECTURE" = "aarch64" ] || [ "$ARCHITECTURE" = "arm64" ]; then
    IS_ARM64=1
    print_success "Running on ARM64 (Jetson - Native Mode)"
else
    print_info "Running on $ARCHITECTURE (Cross-Compile Mode)"
fi

# Install dependencies
print_header "INSTALLING DEPENDENCIES"
if command -v apt-get >/dev/null 2>&1; then
    print_step "Updating package list..."
    sudo apt-get update -qq
    
    print_step "Installing required packages..."
    sudo apt-get install -qq -y \
        build-essential \
        bc \
        libssl-dev \
        flex \
        bison \
        wget \
        git \
        pv \
        kmod \
        ca-certificates \
        libelf-dev
    
    print_success "Dependencies installed"
else
    print_error "Non-apt based system. Install manually:"
    echo "- build-essential, bc, libssl-dev, flex, bison, wget, git, pv, kmod, libelf-dev"
    exit 1
fi

# Main configurations
print_header "INITIAL SETUP"
export KERNEL_VERSION=36.4.3
export MODULE_NAME="gs_usb"
export MODULE_INSTALL_PATH="/lib/modules/$(uname -r)/kernel/net/can/usb"
SCRIPT_DIR=$(pwd)

print_info "Script directory: $SCRIPT_DIR"
print_info "Target kernel version: $KERNEL_VERSION"

# Create directory structure
print_step "Creating directory structure..."
mkdir -p "$KERNEL_VERSION"
cd "$KERNEL_VERSION" || exit
export SRC_PATH=$PWD
export OUT_PATH="$SRC_PATH/kernel_out"
mkdir -p "$OUT_PATH"

print_success "Directories configured:"
print_info " - Source: $SRC_PATH"
print_info " - Output: $OUT_PATH"

# Kernel configuration
print_header "KERNEL CONFIGURATION"
if [ $IS_ARM64 -eq 1 ]; then
    if [ ! -f "../config" ]; then
        print_step "Generating kernel config file..."
        zcat /proc/config.gz > ../config || {
            print_error "Failed to generate config.gz!"
            exit 1
        }
        print_success "Configuration generated: ../config"
    fi
else
    if [ ! -f "../config" ]; then
        print_error "Config file not found! Copy from Jetson to this directory."
        exit 1
    fi
fi

print_step "Setting up build configuration..."
cp ../config "$OUT_PATH/.config" || exit 1

# Add module to configuration
if ! grep -q "CONFIG_CAN_GS_USB=m" "$OUT_PATH/.config"; then
    print_step "Adding $MODULE_NAME module to configuration..."
    echo "CONFIG_CAN_GS_USB=m" >> "$OUT_PATH/.config"
    print_success "Module added to .config"
else
    print_info "Module already configured in .config"
fi

# Download sources
print_header "DOWNLOADING DEPENDENCIES"
if [ ! -f "public_sources.tbz2" ]; then
    print_step "Downloading public_sources.tbz2 (~1.2GB)..."
    wget --show-progress -q https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.3/sources/public_sources.tbz2
else
    print_info "public_sources.tbz2 already exists, skipping download"
fi

# Extraction process
print_header "EXTRACTING FILES"
if [ ! -d "Linux_for_Tegra/source" ]; then
    print_step "Extracting public_sources.tbz2..."
    pv public_sources.tbz2 | tar xjf - || {
        print_error "Extraction failed!"
        exit 1
    }
    print_success "Extraction complete"
else
    print_info "public_sources already extracted"
fi

cd Linux_for_Tegra/source/ || exit

# Extract kernel components
print_step "Verifying kernel components..."
[ ! -d "kernel/kernel-jammy-src" ] && {
    print_info "Extracting kernel_src.tbz2..."
    tar xf kernel_src.tbz2 || exit 1
}

# Toolchain setup
print_header "TOOLCHAIN CONFIGURATION"
if [ $IS_ARM64 -eq 0 ]; then
    cd "$SRC_PATH" || exit
    
    if [ ! -f "aarch64--glibc--stable-2022.08-1.tar.bz2" ]; then
        print_step "Downloading toolchain..."
        wget --show-progress -q https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v3.0/toolchain/aarch64--glibc--stable-2022.08-1.tar.bz2
    else
        print_info "Toolchain already downloaded"
    fi

    if [ ! -d "aarch64--glibc--stable-2022.08-1" ]; then
        print_step "Extracting toolchain..."
        tar xf aarch64--glibc--stable-2022.08-1.tar.bz2 || exit 1
    else
        print_info "Toolchain already extracted"
    fi
    
    export CROSS_COMPILE="$SRC_PATH/aarch64--glibc--stable-2022.08-1/bin/aarch64-buildroot-linux-gnu-"
    print_info "Toolchain configured: $CROSS_COMPILE"
fi

# Module compilation
print_header "MODULE COMPILATION"
cd "$SRC_PATH/Linux_for_Tegra/source/kernel/kernel-jammy-src" || exit

print_step "Preparing build environment..."
if [ $IS_ARM64 -eq 1 ]; then
    make O="$OUT_PATH" modules_prepare |& tee "$OUT_PATH/prepare.log"
else
    make O="$OUT_PATH" ARCH=arm64 CROSS_COMPILE="$CROSS_COMPILE" modules_prepare |& tee "$OUT_PATH/prepare.log"
fi

print_step "Compiling $MODULE_NAME module..."
if [ $IS_ARM64 -eq 1 ]; then
    make O="$OUT_PATH" M=drivers/net/can/usb/ modules |& tee "$OUT_PATH/build.log"
else
    make O="$OUT_PATH" ARCH=arm64 CROSS_COMPILE="$CROSS_COMPILE" M=drivers/net/can/usb/ modules |& tee "$OUT_PATH/build.log"
fi

print_success "Compilation complete! Logs available at:"
print_info " - Preparation: $OUT_PATH/prepare.log"
print_info " - Build: $OUT_PATH/build.log"

# Post-processing
print_header "INSTALLATION/POST-PROCESSING"
MODULE_SOURCE_PATH="$OUT_PATH/drivers/net/can/usb/$MODULE_NAME.ko"

if [ $IS_ARM64 -eq 1 ]; then
    print_step "Installing module..."
    sudo mkdir -p "$MODULE_INSTALL_PATH"
    sudo cp -v "$MODULE_SOURCE_PATH" "$MODULE_INSTALL_PATH/"
    
    print_step "Configuring auto-load..."
    if ! grep -q "^$MODULE_NAME" /etc/modules; then
        echo "$MODULE_NAME" | sudo tee -a /etc/modules
        print_success "Module added to /etc/modules"
    else
        print_info "Module already in /etc/modules"
    fi
    
    print_step "Updating module dependencies..."
    sudo depmod -a
    print_success "Installation complete! ${BLUE}Reboot system to apply changes.${NC}"
else
    print_step "Copying module to script directory..."
    cp -v "$MODULE_SOURCE_PATH" "$SCRIPT_DIR/"
    print_success "Module available at:"
    echo -e "${GREEN}$SCRIPT_DIR/$MODULE_NAME.ko${NC}"
    
    print_header "JETSON INSTALLATION INSTRUCTIONS"
    echo -e "On Jetson, run:"
    echo -e "1. ${YELLOW}sudo mkdir -p $MODULE_INSTALL_PATH${NC}"
    echo -e "2. ${YELLOW}sudo cp $MODULE_NAME.ko $MODULE_INSTALL_PATH/${NC}"
    echo -e "3. ${YELLOW}echo '$MODULE_NAME' | sudo tee -a /etc/modules${NC}"
    echo -e "4. ${YELLOW}sudo depmod -a${NC}"
    echo -e "5. ${YELLOW}sudo reboot${NC}"
fi

print_header "PROCESS COMPLETED"
