**简体中文** | [English](README_en.md)  

![Tailscale & OpenWrt](./banner.png)  
# 📖 适用于 OpenWrt 的 Tailscale 一键安装脚本

![GitHub release](https://img.shields.io/github/v/release/GuNanOvO/openwrt-tailscale?style=flat-square)
![GitHub Repo Views](https://img.shields.io/github/search/GuNanOvO/openwrt-tailscale/git?label=Views&query=is%3Apublic&color=blue)
![Downloads](https://img.shields.io/github/downloads/GuNanOvO/openwrt-tailscale/total?style=flat-square)
![GitHub Stars](https://img.shields.io/github/stars/GuNanOvO/openwrt-tailscale?label=Stars&color=yellow)

> ✨ 一个专为 OpenWrt 小存储空间设备设计的 Tailscale 安装工具  
> 🚀 支持持久化安装、临时安装  
> 🔥 缩小tailscale体积 **70%**！（使用编译优化+UPX压缩技术）  
> 🛠️ 可以帮助您升级您的旧版本OpenWrt设备上的旧版本Tailscale

---

## 🖥️ 支持架构列表

| 架构类型        | 测试情况      | 测试设备 | 测试系统环境 |
|-----------------|---------------|----------|--------------|
| `i386`          | 已测试✔️     | kvm虚拟机 | ImmortalWrt 24.10.0 |
| `x86_64`        | 已测试✔️     | kvm虚拟机 | ImmortalWrt 24.10.0 |
| `arm`           | 已测试✔️     | CMCC-XR30 | OpenWrt 23.05.0     |
| `arm64`         | 已测试✔️     | R2S       | ImmortalWrt 23.05.4 |
| `mips/mipsel`   | 未测试❌     |           |                     |
| `riscv64`       | 未测试❌     |           |                     |
| `geode`         | 未测试❌     |           |                     |


---

## 📥 使用方法

### 🔌 推荐方式（SSH连接）

```bash
wget -O /usr/bin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh
```

### 🖥️ 不支持中文的终端
```bash
wget -O /usr/bin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install_en_cnproxy.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh
```

### 📦 安装未压缩的版本（约25mb）
使用参数`--notiny`
```bash
wget -O /usr/bin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh --notiny
```

### 🌐 自定义代理
使用参数`--custom-proxy`
```bash
wget -O /usr/bin/install.sh https://ghfast.top/https://raw.githubusercontent.com/GuNanOvO/openwrt-tailscale/main/install.sh && chmod +x /usr/bin/install.sh && /usr/bin/install.sh --custom-proxy
```

### 👋🏻 手动持久安装  
1、于本项目[Releases](https://github.com/GuNanOvO/openwrt-tailscale/releases)下载与您设备对应架构的tailscaled文件  
2、将该二进制可执行文件置于您设备的`/usr/bin`目录下  
3、重命名该二进制可执行文件重命名为`tailscaled`  
4、使用命令`ln -sv /usr/bin/tailscaled /usr/bin/tailscale`  
5、于本项目[代码目录](https://github.com/GuNanOvO/openwrt-tailscale/tree/main/etc/init.d)下载tailscale文件（您也可以手动创建文件并填入该文件的内容）  
6、将该文件置于您设备的`/etc/init.d`目录下  
7、将上述文件添加可执行权限`chmod +x /etc/init.d/tailscale && chmod +x /usr/bin/tailscale && chmod +x /usr/bin/tailscaled`
8、执行命令`/etc/init.d/tailscale start`稍等一会，再执行`tailscale up`  
9、enjoy～🫰🏻

---

## ⚠️ 注意事项

1. **临时安装警告**  
   🔥 `/tmp` 目录会在重启后清空！建议仅用于空间实在无法持久安装的设备，由于临时安装原理高度依赖于网络，建议不要仅依赖于tailscale，以免影响您的使用

2. **网络要求**  
   🌐 必须能访问 GitHub 和代理镜像站

3. **兼容性**  
   ⚠️ 多数设备或架构未经过测试，如果您测试不可用，麻烦您提出issues,我会尽快与您沟通进行修复


---

## ⚙️ 实现原理

### 🛠️ 编译优化

使用了tailscale[官方文档](https://tailscale.com/kb/1207/small-tailscale)指出的 `--extra-small` 编译选项，加之[UPX](https://upx.github.io/)的二进制文件压缩技术，将tailscale压缩至原来的20%，使得在小存储空间的openwrt设备上使用tailscale变得可能🎉

### 📦 脚本核心逻辑
1. **持久安装**  
   - 将tailscaled二进制文件置于`/usr/bin`，使用`ln -sv tailscaled tailscale`链接tailscaled到tailscale，仅需大约 **7mb** 即可正常使用tailscale服务。即便所需空间仅 **7mb** ,但我们仍希望您尽量保持存储空间有 **20mb** 时才使用持久化安装。

2. **临时安装**  
   - 将tailscaled二进制文件至于`/tmp`，同样使用`ln -sv tailscaled tailscale`链接tailscaled到tailscale，由于是放置于/tmp目录，该安装方式会占用设备内存。每次重启后，会调用到脚本进行重新下载tailscale。

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