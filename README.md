
**简体中文** | [English](README_en.md)  

# ⚠️⚠️⚠️尚未完善⚠️⚠️⚠️谨慎使用⚠️⚠️⚠️
# 📖 适用于 OpenWrt 的 Tailscale 一键安装脚本

![GitHub release](https://img.shields.io/github/v/release/GuNanOvO/openwrt-tailscale?style=flat-square)
![Downloads](https://img.shields.io/github/downloads/GuNanOvO/openwrt-tailscale/total?style=flat-square)

> ✨ 一个专为 OpenWrt 小存储空间设备设计的 Tailscale 安装工具  
> 🚀 支持持久化安装、临时安装  
> 🔥 缩小tailscale体积 **70%**！（使用编译优化+UPX压缩技术）

---

## 🖥️ 支持架构列表

| 架构类型        | 测试情况      |
|-----------------|---------------|
| `i386`          | 未测试❌        |
| `x86_64`        | 未测试❌        |
| `arm`           | 已测试✔️        |
| `arm64`         | 未测试❌        |
| `mips/mipsel`   | 未测试❌        |
| `riscv64`       | 未测试❌        |


---

## 📥 使用方法

### 🔌 推荐方式（SSH连接）

```bash
wget -O /usr/bin/install.sh https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh
```

### 🌐 不支持中文的终端
```bash
wget -O /usr/bin/install.sh https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install_en_cnproxy.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh
```
---

## ⚠️ 注意事项

1. **临时安装警告**  
   🔥 `/tmp` 目录会在重启后清空！建议仅用于空间实在无法持久安装的设备

2. **网络要求**  
   🌐 必须能访问 GitHub 和代理镜像站

3. **兼容性**  
   ⚠️ 多数设备架构未经过测试，如果您测试可用，麻烦您提出issues,我会尽快声明已测试


---

## ⚙️ 实现原理

### 🛠️ 编译优化

使用了tailscale[官方文档](https://tailscale.com/kb/1207/small-tailscale)指出的 `--extra-small` 编译选项，加之[UPX](https://upx.github.io/)的二进制文件压缩技术，将tailscale压缩至原来的20%，使得在小存储空间的openwrt设备上使用tailscale变得可能🎉

### 📦 脚本核心逻辑
1. **持久安装**  
   - 将tailscaled二进制文件置于`/usr/bin`，使用`ln -sv tailscaled tailscale`链接tailscaled到tailscale，仅需大约5mb即可正常使用tailscale服务。即便所需空间仅5mb,但我们仍希望您尽量保持存储空间有15mb时才使用持久化安装。

2. **临时安装**  
   - 将tailscaled二进制文件至于`/tmp`，同样使用`ln -sv tailscaled tailscale`链接tailscaled到tailscale，由于至于/tmp目录，该安装方式会占用设备内存。每次重启后，会调用到脚本进行重新下载tailscale。

---

## 🙏 特别致谢

| 项目 | 贡献 |
|------|------|
| [📦 tailscale-openwrt 项目](https://github.com/CH3NGYZ/tailscale-openwrt) | 为本脚本提供了大部分思路 |
| [📦 glinet-tailscale-updater 项目](https://github.com/Admonstrator/glinet-tailscale-updater) | 为本脚本提供了大部分思路 |

---

## 🐛 问题反馈

遇到问题请至 [GitHub Issues](https://github.com/GuNanOvO/openwrt-tailscale/issues) 提交，请附上：
1. 设备架构信息（`uname -m`）
2. 安装模式（持久/临时）
3. 相关日志片段

---

> 💖 如果本项目对您有帮助，欢迎点亮小星星！  
> ⭐ [前往 GitHub 仓库](https://github.com/GuNanOvO/openwrt-tailscale)