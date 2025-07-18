[简体中文](README.md) | **English**  

![Tailscale & OpenWrt](./banner.png)  
# 📖 One-Click Installation Script for Tailscale on OpenWrt

![GitHub release](https://img.shields.io/github/v/release/GuNanOvO/openwrt-tailscale?style=flat)
![Views](https://api.visitorbadge.io/api/combined?path=https%3A%2F%2Fgithub.com%2FGuNanOvO%2Fopenwrt-tailscale&label=Views&countColor=%23b7d079&style=flat)
![Downloads](https://img.shields.io/github/downloads/GuNanOvO/openwrt-tailscale/total?style=flat)
![GitHub Stars](https://img.shields.io/github/stars/GuNanOvO/openwrt-tailscale?label=Stars&color=yellow)

Bring the latest Tailscale to small-storage OpenWrt device  
space-saving & easy install & easy update  
> ✨ A Tailscale installation tool designed for OpenWrt devices with limited storage.  
> 🚀 Supports both persistent and temporary installation.  
> 🔥 Reduces Tailscale size by **70%**! (Using compilation optimization + UPX compression technology)  
> 🛠️ Can help update the old Tailscale version on your legacy OpenWrt device

---

## 🖥️ Supported Architectures

| Architecture     | Test Status    | Test Device | Test System Environment |
|-----------------|---------------|-------------|-------------------------|
| `i386`         | Tested ✔️     | kvm VM      | ImmortalWrt 24.10.0     |
| `x86_64`       | Tested ✔️     | kvm VM      | ImmortalWrt 24.10.0     |
| `arm`          | Tested ✔️     | CMCC-XR30   | OpenWrt 23.05.0         |
| `arm64`        | Tested ✔️     | R2S         | ImmortalWrt 23.05.4     |
| `mipsle`       | Tested ✔️     | qemu        | ImmortalWrt 24.10.0     |
| `riscv64`      | Not Tested ❌ |             |                         |
| `geode`        | Not Tested ❌ |             |                         |

---

## 📥 Installation Guide

### ⚠️ Requirements
- **Storage**: less than 10MB (UPX compressed)  
- **RAM**: about 60MB (during operation)  
- **Warning**: May not work on devices with <256MB RAM

### 🔌 Recommended Method (SSH Connection)
```bash
wget -O /usr/bin/install.sh https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install_en.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh
```

### 📦 Install Uncompressed Version (Approx. 25MB)
Use the `--notiny` parameter:
```bash
wget -O /usr/bin/install.sh https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install_en.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh --notiny
```

### 👋🏻 Manual Persistent Installation
1. Download the `tailscaled` file corresponding to your device architecture from [Releases](https://github.com/GuNanOvO/openwrt-tailscale/releases).
2. Place the binary executable in your device's `/usr/bin` directory.
3. Rename the binary executable to `tailscaled`.
4. Create a symbolic link using `ln -sv /usr/bin/tailscaled /usr/bin/tailscale`.
5. Download the `tailscale` script from [Code Directory](https://github.com/GuNanOvO/openwrt-tailscale/tree/main/etc/init.d) (or manually create and copy the contents into a new file).
6. Place this file in your device's `/etc/init.d` directory.
7. Grant execute permissions:`chmod +x /etc/init.d/tailscale && chmod +x /usr/bin/tailscale && chmod +x /usr/bin/tailscaled`
8. Run `/etc/init.d/tailscale start`, wait a moment, then execute `tailscale up`.
9. If you're using OpenWrt == 22.03 you will also need to specify `--netfilter-mode=off`. For versions 23+ do NOT include netfilter-mode.  
10. Enjoy～🫰🏻

---

## ⚠️ Notes

1. **Temporary Installation Warning**  
   🔥 The `/tmp` directory is cleared upon reboot! This method is only recommended for devices that cannot persistently install due to storage constraints. Since temporary installation heavily depends on network availability, do not solely rely on Tailscale to avoid interruptions.

2. **Network Requirements**  
   🌐 Must have access to GitHub  

3. **Compatibility**  
   ⚠️ Most devices or architectures have not been tested. If you encounter issues, please submit an [issue](https://github.com/GuNanOvO/openwrt-tailscale/issues), and I will work on fixing them as soon as possible.  

---

## ⚙️ Implementation Details

**🛠️ Compilation Optimization**:
Utilizes the `--extra-small` compilation flag from Tailscale's [official documentation](https://tailscale.com/kb/1207/small-tailscale) along with [UPX](https://upx.github.io/) binary compression technology to shrink Tailscale to **20%** of its original size, making it feasible to use on OpenWrt devices with limited storage. 🎉

### 📦 Core Script Logic

1. **Persistent Installation**  
   - Places the `tailscaled` binary in `/usr/bin`, creating a symbolic link using `ln -sv tailscaled tailscale`. Only **7MB** of storage is required to run Tailscale. Although the minimum space requirement is **7MB**, we recommend having at least **20MB** for a stable persistent installation.

2. **Temporary Installation**  
   - Places the `tailscaled` binary in `/tmp`, creating a symbolic link as above. Since it is stored in the `/tmp` directory, this method **uses device RAM**. Upon reboot, the script will automatically re-download Tailscale.  

---

## 🙏 Special Thanks

**📦 [tailscale-openwrt](https://github.com/CH3NGYZ/tailscale-openwrt)**: Provided key implementation ideas about temporary installation for this script.  
**📦 [glinet-tailscale-updater](https://github.com/Admonstrator/glinet-tailscale-updater)**: Provided key implementation ideas about persistent installationfor and compression methon this script.  

---

## 🐛 Issue Reporting

If you encounter any issues, please submit them in [Issues](https://github.com/GuNanOvO/openwrt-tailscale/issues) along with:  
1. Device architecture (`uname -m`)  
2. Installation method (Persistent/Temporary)  
3. Relevant log snippets  

---

> 💖 If this project helps you, feel free to star⭐ it!  

