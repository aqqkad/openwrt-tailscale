#!/bin/sh

# 基本配置
# TAILSCALE 文件 URL
# https://github.com/gunanovo/openwrt-tailscale/releases/latest
# https://github.com/gunanovo/openwrt-tailscale/releases/latest/download/version.txt
TAILSCALE_URL="gunanovo/openwrt-tailscale/releases/latest"
# tailscale 文件 URL头
URL_PROXYS="
https://ghfast.top/https://github.com
https://cf.ghproxy.cc/https://github.com
https://www.ghproxy.cc/https://github.com
https://gh-proxy.com/https://github.com
https://ghproxy.cc/https://github.com
https://ghproxy.cn/https://github.com
https://www.ghproxy.cn/https://github.com
https://github.com
"
# init.d/tailscale 文件 URL
INIT_URL=""
# OpenWrt 可写存储分区，通常是 /overlay
MOUNT_POINT="/overlay"
# tmp tailscale
TMP_TAILSCALE='#!/bin/sh
                set -e

                /tmp/tailscale "$@"'
# tmp tailscaled
TMP_TAILSCALED='#!/bin/sh
                set -e

                /tmp/tailscaled "$@"'


# 可用proxy头
available_proxy=""
# 最新tailscale版本
tailscale_latest_version=""

# tailscale是否已安装
is_tailscale_installed=false
# tailscale的安装状态（持久安装/临时安装）
tailscale_install_status="none"
# 是否查找到任何tailscale文件
found_tailscale_file=false
# tailscale版本号
tailscale_version=""

# 剩余空间大小bytes
free_space=""
# 文件大小bytes
file_size=""
# 剩余空间大小mb
free_space_mb=""
# 文件大小mb
file_size_mb=""
# tailscale是否可以被永久安装，即存储空间是否足够安装
tailscale_persistent_installable=""


# 函数：设置DNS
set_system_dns() {
cat <<EOF > /etc/resolv.conf
search lan
nameserver 223.5.5.5
nameserver 119.29.29.29
EOF
}

# 函数：获取系统架构
get_system_arch() {
    arch_=$(uname -m)
    endianness=""

    case "$arch_" in
        i386)
            arch=386
            ;;
        x86_64)
            arch=amd64
            ;;
        armv7l)
            arch=arm
            ;;
        aarch64 | armv8l)
            arch=arm64
            ;;
        geode)
            arch=geode
            ;;
        mips)
            arch=mips
            endianness=$(echo -n I | hexdump -o | awk '{ print (substr($2,6,1)=="1") ? "le" : "be"; exit }')
            ;;
        riscv64)
            arch=riscv64
            ;;
        *)
            echo "INSTALL: --------------------------------------------"
            echo "当前机器的架构是 [${arch_}${endianness}]"
            echo "脚本不支持您的机器"
            echo "------------------------------------------------------"
            exit 1
            ;;
    esac
}

# 函数：检测是否已经安装过tailscale
check_tailscale_install_status() {
    # 检查 tailscale version 是否有输出并提取版本号
    if command -v tailscale >/dev/null 2>&1; then
        version_output=$(tailscale version 2>/dev/null)
        if [ -n "$version_output" ]; then
            # 从输出中提取版本号
            tailscale_version=$(echo "$version_output" | sed -n '1p' | tr -d '[:space:]')
            if [ -f "/usr/bin/tailscaled" ] && [ -f "/tmp/tailscaled" ]; then
                tailscale_install_status="temp"
            elif [ -f "/usr/bin/tailscaled" ]; then
                tailscale_install_status="persistent"
            fi
            is_tailscale_installed="true"
        fi
    fi

}

# 函数：检查剩余存储空间（单位：bytes）
get_free_space() {
    # 检查 MOUNT_POINT 是否定义
    if [ -z "$MOUNT_POINT" ]; then
        echo "错误: MOUNT_POINT 未定义"
        exit 1
    fi

    # 使用 df -k 获取以 KB（1024 字节）为单位的剩余空间
    free_space_kb=$(df -k "$MOUNT_POINT" | tail -n 1 | awk '{print $4}')
    
    # 检查输出是否有效
    if [ -z "$free_space_kb" ] || ! echo "$free_space_kb" | grep -q '^[0-9]\+$'; then
        echo "错误: 无法获取 $MOUNT_POINT 的剩余空间"
        exit 1
    fi

    # 将 KB 转换为 bytes（1KB = 1024 bytes）
    free_space=$((free_space_kb * 1024))
    free_space_mb=$(expr $free_space / 1024 / 1024)
    
    echo "$free_space"
}

# 函数：获取 GitHub 文件大小（单位：bytes）
get_tailscale_info() {
    # 先简单wget一下releases的版本，以此确定可用的代理头
    # 尝试3次
    attempt_range="1 2 3"
    # 超时时间（秒）
    attempt_timeout=10

    for attempt_times in $attempt_range; do
        for attempt_proxy in $URL_PROXYS; do
            echo "$attempt_proxy"
            attempt_url="$attempt_proxy/$TAILSCALE_URL/download/version.txt"
            tailscale_latest_version=$(timeout $attempt_timeout wget -qO- "$attempt_url")

            if [ -n "$tailscale_latest_version" ]; then
                available_proxy="$attempt_proxy"
                echo "成功得到可用代理头"
                break 2
            fi

        done
    done
    
    file_size=$(wget --spider --max-redirect=10 --server-response "$available_proxy/$TAILSCALE_URL/download/tailscaled-linux-${arch}" 2>&1 | 
        grep 'Content-Length' | 
        awk '{print $2}' | 
        tail -n 1)

    if [ -z "$file_size" ] || ! [[ "$file_size" =~ ^[0-9]+$ ]]; then
        echo "错误: 无法获取tailscale大小"
        echo "1. 确保网络连接正常"
        echo "2. 报告开发者"
        exit 1
    fi

    file_size_mb=$(expr $file_size / 1024 / 1024)
}

update() {
    if [ "$tailscale_install_status" = "temp" ]; then
        temp_install
    elif [ "$tailscale_install_status" = "persistent" ]; then
        persistent_install
    fi
}

remove() { 
    while true; do
    read -p "确认卸载tailscale吗？(y/N): " choice

    if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
        tailscale_stoper

        # remove指定目录的 tailscale 或 tailscaled 文件
        directories="/etc/init.d /etc /etc/config /usr/bin /tmp /var/lib"
        binaries="tailscale tailscaled"

        # 使用 for 循环遍历目录和文件
        for dir in $directories; do
            for bin in $binaries; do
                if [ -f "$dir/$bin" ]; then
                    rm -rf $dir/$bin
                fi
            done
        done

        ip link delete tailscale0
        cleanup

        break

    elif [ "$choice" = "N" ] || [ "$choice" = "n" ]; then
        echo "取消卸载"
        break
    else
        echo "取消卸载"
        break
    fi
done

}

persistent_install() {
    downloader
    mv /tmp/tailscaled /usr/bin
    ln -sv /usr/bin/tailscaled /usr/bin/tailscale

}

temp_install() {
    downloader
    ln -sv /tmp/tailscaled /tmp/tailscale
    echo "$TMP_TAILSCALE" > /usr/bin/tailscale
    echo "$TMP_TAILSCALED" > /usr/bin/tailscaled
}

persistent_to_temp() {
    tailscale_stoper
    rm -rf /usr/bin/tailscale
    rm -rf /usr/bin/tailscaled
    temp_install
}

temp_to_persistent() {
    tailscale_stoper
    rm -rf /tmp/tailscale
    rm -rf /tmp/tailscaled
    rm -rf /usr/bin/tailscale
    rm -rf /usr/bin/tailscaled
    persistent_install
}

downloader() {
    wget -cO /tmp/tailscaled "$available_proxy/$TAILSCALE_URL/download/tailscaled-linux-${arch}"
    wget -cO /etc/init.d/tailscale "$available_proxy/https://github.com/GuNanOvO/openwrt-tailscale/blob/main/etc/init.d/tailscale"
}

tailscale_starter() {
    /etc/init.d/tailscale start

    sleep 3

    tailscale up
}

tailscale_stoper() {
    if [ "$tailscale_install_status" = "temp" ]; then
        /etc/init.d/tailscale stop
        /tmp/tailscale down --accept-risk=lose-ssh
        /tmp/tailscale logout
        /etc/init.d/tailscale disable
    elif [ "$tailscale_install_status" = "persistent" ]; then
        /etc/init.d/tailscale stop
        /usr/bin/tailscale down --accept-risk=lose-ssh
        /usr/bin/tailscale logout
        /etc/init.d/tailscale disable
    fi
}

init() {
    #设置系统DNS
    set_system_dns
    #获取系统架构
    get_system_arch
    #检查是否安装过
    check_tailscale_install_status
    #获取磁盘剩余空间
    echo "获取磁盘剩余空间"
    get_free_space
    #获取tailscale文件大小
    echo "获取tailscale文件大小"
    get_tailscale_info
    # 比较并判断是否可以持久安装tailscale
    if [ "$free_space" -gt "$file_size" ]; then
        tailscale_persistent_installable=true
    else
        tailscale_persistent_installable=false
    fi

}

info() {
    echo "当前机器架构：[${arch_}${endianness}]"
    if [ "$is_tailscale_installed" = "true" ]; then
        echo "tailscale安装状态：已安装"
        echo "tailscale版本：$tailscale_version"
    else 
        echo "tailscale安装状态：未安装"
        echo "tailscale版本：未安装"
    fi
    echo "剩余存储空间：$free_space B / $(expr $free_space / 1024 / 1024) M"
    echo "tailscale文件大小：$file_size B / $(expr $file_size / 1024 / 1024) M" 
    # 比较并判断
    if [ "$free_space" -gt "$file_size" ]; then
        echo "剩余空间足以持久安装tailscale"
    else
        echo "剩余空间不足以持久安装tailscale"
    fi
}

option_menu() {
    menu_items=""
    menu_operations=""
    option_index=1

    menu_items="$option_index).显示基本信息"
    menu_operations="info"
    option_index=$((option_index + 1))

    if [ "$is_tailscale_installed" = "true" ] && ["$tailscale_latest_version" -gt "$tailscale_version" ]; then
        menu_items="$menu_items $option_index).更新"
        menu_operations="$menu_operations update"
        option_index=$((option_index + 1))
    fi

    if [ "$is_tailscale_installed" = "true" ]; then
        menu_items="$menu_items $option_index).卸载"
        menu_operations="$menu_operations remove"
        option_index=$((option_index + 1))
    fi

    if [ "$tailscale_install_status" = "temp" ] && [ "$tailscale_persistent_installable" = "true" ]; then
        menu_items="$menu_items $option_index).切换至持久安装"
        menu_operations="$menu_operations temp_to_persistent"
        option_index=$((option_index + 1))
    fi

    if [ "$is_tailscale_installed" = "false" ] && [ "$tailscale_persistent_installable" = "true" ]; then
        menu_items="$menu_items $option_index).持久安装"
        menu_operations="$menu_operations persistent_install"
        option_index=$((option_index + 1))
    fi

    if [ "$tailscale_install_status" = "persistent" ]; then
        menu_items="$menu_items $option_index).切换至临时安装"
        menu_operations="$menu_operations persistent_to_temp"
        option_index=$((option_index + 1))
    fi

    if [ "$is_tailscale_installed" = "false" ]; then
        menu_items="$menu_items $option_index).临时安装"
        menu_operations="$menu_operations temp_install"
        option_index=$((option_index + 1))
    fi

    menu_items="$menu_items $option_index).退出"
    menu_operations="$menu_operations exit"
    #option_index=$((option_index + 1))

    # 显示菜单并获取用户输入
    while true; do
        echo "===== 动态菜单 ====="
        
        # 遍历选项列表，动态生成菜单
        for item in $menu_items; do
            echo "$item"
        done
        
        echo "请输入选项: "
        read -n 1 choice

        # 判断输入是否合法
        if [ "$choice" -ge 0 ] && [ "$choice" -le "$option_index" ]; then
            operation_index=1
            for operation in $menu_operations; do
                if [ "$operation_index" = "$choice" ]; then
                    eval "$operation"
                fi
                operation_index=$((operation_index + 1))
            done
        else
            echo "无效选项，请重试！"
        fi

        # 退出判断
        [ "$choice" -eq "$exit_option" ] && break

        echo "按回车键继续..."
        read -r
    done
}

init
option_menu