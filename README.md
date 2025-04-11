# Jetson L4T gs_usb Kernel Module Builder 🔧  

**Easily build and install the** gs_usb **CAN kernel module for NVIDIA Jetson devices** running **L4T R36.4.3** (Linux for Tegra). Supports both native (ARM64) and cross-compilation (x86_64) workflows.

  

## ✅ Compatible With  
- **Jetson AGX Orin/Xavier, TX2, Nano** (L4T R36.4.3)  
- Ubuntu 20.04 (Jammy) base  

## 🚀 Features  
✔️ **Plug-and-Play** – Installs dependencies, downloads kernel sources, and configures the build.  
✔️ **Cross-Platform** – Works natively on Jetson or via cross-compilation from x86_64 hosts.  
✔️ **Robust Logging** – Color-coded output and error handling.  
✔️ **Auto-Install** – Optionally installs the module and updates initramfs.  

## 🔧 Use Cases  
- CAN bus communication (robotics, automotive, ROS2)  
- Custom kernel module development for Jetson  

## ⚡ Quick Start

###  📦 Native Compilation (on Jetson)

#### 1. On Jetson: Download and run the build script
```bash
wget https://github.com/lucianovk/jetson-gs_usb-kernel-builder/raw/main/jetson-gs_usb-kernel-builder.sh  
chmod +x jetson-gs_usb-kernel-builder.sh  
./jetson-gs_usb-kernel-builder.sh
```   

### 🔁 Cross-Compilation Workflow (Jetson → Host → Jetson)

#### 1. On Jetson: Export kernel config
```bash
zcat /proc/config.gz > config
```

#### 2. Copy config file to your host machine
```bash
scp config user@host:/path/to/jetson-gs_usb-kernel-builder/
```

#### 3. On the host: Download and run the build script
```bash
cd /path/to/jetson-gs_usb-kernel-builder/
wget https://github.com/lucianovk/jetson-gs_usb-kernel-builder/raw/main/jetson-gs_usb-kernel-builder.sh  
chmod +x jetson-gs_usb-kernel-builder.sh  
./jetson-gs_usb-kernel-builder.sh
```
## ⚠️ **For Other Kernel Versions**  
This script is tailored for L4T R36.4.3. For newer kernels, modify:  
- `KERNEL_VERSION` in the script  
- Download matching sources from [NVIDIA L4T](https://developer.nvidia.com/embedded/linux-tegra)  
