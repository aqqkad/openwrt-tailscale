[简体中文](README.md) | **English**  

![Tailscale & OpenWrt](./banner.png)  
# 📖 One-Click Installation Script for Tailscale on OpenWrt

![GitHub release](https://img.shields.io/github/v/release/GuNanOvO/openwrt-tailscale?style=flat-square)
![Views](https://api.visitorbadge.io/api/combined?path=https%3A%2F%2Fgithub.com%2FGuNanOvO%2Fopenwrt-tailscale&label=Views&countColor=%23b7d079&style=flat)
![Downloads](https://img.shields.io/github/downloads/GuNanOvO/openwrt-tailscale/total?style=flat-square)
![GitHub Stars](https://img.shields.io/github/stars/GuNanOvO/openwrt-tailscale?label=Stars&color=yellow)


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
| `mips/mipsel`  | Not Tested ❌ |             |                         |
| `riscv64`      | Not Tested ❌ |             |                         |
| `geode`        | Not Tested ❌ |             |                         |

---

## 📥 Installation Guide

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
9. Enjoy～🫰🏻

---

## ⚠️ Notes

1. **Temporary Installation Warning**  
   🔥 The `/tmp` directory is cleared upon reboot! This method is only recommended for devices that cannot persistently install due to storage constraints. Since temporary installation heavily depends on network availability, do not solely rely on Tailscale to avoid interruptions.🔥‘ /tmp ’目录在重启时被清除！此方法仅建议用于由于存储限制而无法持久安装的设备。由于临时安装在很大程度上取决于网络的可用性，因此不要仅仅依靠Tailscale来避免中断。

2. **Network Requirements**  2. * * * *网络需求
   🌐 Must have access to GitHub .🌐必须访问GitHub。

3. **Compatibility**  
   ⚠️ Most devices or architectures have not been tested. If you encounter issues, please submit an [issue](https://github.com/GuNanOvO/openwrt-tailscale/issues), and I will work on fixing them as soon as possible.⚠️大多数设备或架构尚未经过测试。如果您遇到问题，请提交[问题](https://github.com/GuNanOvO/openwrt-tailscale/issues)，我会尽快修复。

---

## ⚙️ Implementation Details

### 🛠️ Compilation Optimization

Utilizes the `--extra-small` compilation flag from Tailscale's [official documentation](https://tailscale.com/kb/1207/small-tailscale) along with [UPX](https://upx.github.io/) binary compression technology to shrink Tailscale to **20%** of its original size, making it feasible to use on OpenWrt devices with limited storage. 🎉

### 📦 Core Script Logic

1. **Persistent Installation**  
   - Places the `tailscaled` binary in `/usr/bin`, creating a symbolic link using `ln -sv tailscaled tailscale`. Only **7MB** of storage is required to run Tailscale. Although the minimum space requirement is **7MB**, we recommend having at least **20MB** for a stable persistent installation.

2. **Temporary Installation**  
   - Places the `tailscaled` binary in `/tmp`, creating a symbolic link as above. Since it is stored in the `/tmp` directory, this method **uses device RAM**. Upon reboot, the script will automatically re-download Tailscale.-将‘ tailscaled ’二进制文件放在‘ /tmp ’中，创建一个符号链接，如上所述。由于它存储在“/tmp”目录中，因此该方法**使用设备RAM**。重新启动后，脚本将自动重新下载Tailscale。

---

## 🙏 Special Thanks   ##🙏特别感谢

| Project | Contribution |   |项目|贡献|
|---------|-------------|
| [📦 tailscale-openwrt](https://github.com/CH3NGYZ/tailscale-openwrt) | Provided key implementation ideas about temporary installation for this script. |
| [📦 glinet-tailscale-updater](https://github.com/Admonstrator/glinet-tailscale-updater) | Provided key implementation ideas about persistent installationfor and compression methon this script. |

---

## 🐛 Issue Reporting   ##🐛问题报告

If you encounter any issues, please submit them in [GitHub Issues](https://github.com/GuNanOvO/openwrt-tailscale/issues) along with:如果您遇到任何问题，请将它们提交到[GitHub问题]（https://github.com/GuNanOvO/openwrt-tailscale/issues）以及：
1. Device architecture (`uname -m`)1. 设备架构（' uname -m '）
2. Installation method (Persistent/Temporary)2. 安装方式（持久/临时）
3. Relevant log snippets   3. 相关日志片段

---

> 💖 If this project helps you, feel free to star it!  >💖如果这个项目对你有帮助，请给它点上星星！
> ⭐ [Go to GitHub Repository](https://github.com/GuNanOvO/openwrt-tailscale)>⭐[转到GitHub Repository]（https://github.com/GuNanOvO/openwrt-tailscale）

