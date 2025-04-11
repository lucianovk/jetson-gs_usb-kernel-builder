# Jetson L4T Kernel Module Builder 🔧  

**Automatically build and install the `gs_usb` CAN kernel module for NVIDIA Jetson devices** running **L4T R36.4.3** (Linux for Tegra). Supports both native (ARM64) and cross-compilation (x86_64) workflows.  

## ✅ Compatible With  
- **Jetson AGX Orin/Xavier, TX2, Nano** (L4T R36.4.3 kernel **5.10.120-tegra**)  
- Ubuntu 20.04 (Jammy) base  

## Features  
✔️ **Plug-and-Play** – Installs dependencies, downloads kernel sources, and configures the build.  
✔️ **Cross-Platform** – Works natively on Jetson or via cross-compilation from x86_64 hosts.  
✔️ **Robust Logging** – Color-coded output and error handling.  
✔️ **Auto-Install** – Optionally installs the module and updates initramfs.  

## Use Cases  
- CAN bus communication (robotics, automotive, ROS2)  
- Custom kernel module development for Jetson  

## Quick Start  
```bash
# Download and run (Jetson or cross-compile host)  
wget https://github.com/lucianovk/jetson-l4t-kernel-module-builder/raw/main/build_gs_usb.sh  
chmod +x build_gs_usb.sh  
./build_gs_usb.sh  
