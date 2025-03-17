#!/bin/sh

# Script Information
SCRIPT_VERSION="v1.01"
SCRIPT_DATE="2025/03/18"
script_info() {
    echo "#╔╦╗┌─┐ ┬ ┬  ┌─┐┌─┐┌─┐┬  ┌─┐  ┌─┐┌┐┌  ╔═╗┌─┐┌─┐┌┐┌ ╦ ╦ ┬─┐┌┬┐  ╦ ┌┐┌┌─┐┌┬┐┌─┐┬  ┬  ┌─┐┬─┐#"
    echo "# ║ ├─┤ │ │  └─┐│  ├─┤│  ├┤   │ ││││  ║ ║├─┘├┤ │││ ║║║ ├┬┘ │   ║ │││└─┐ │ ├─┤│  │  ├┤ ├┬┘#"
    echo "# ╩ ┴ ┴ ┴ ┴─┘└─┘└─┘┴ ┴┴─┘└─┘  └─┘┘└┘  ╚═╝┴  └─┘┘└┘ ╚╩╝ ┴└─ ┴   ╩ ┘└┘└─┘ ┴ ┴ ┴┴─┘┴─┘└─┘┴└─#"
    echo "┌────────────────────────────────────────────────────────────────────────────────────────┐"
    echo "│ A script for installing/updating/managing Tailscale on OpenWrt.                        │"
    echo "│ Project URL: https://github.com/GuNanOvO/openwrt-tailscale                             │"
    echo "│ Script Version: "$SCRIPT_VERSION"                                                                  │"
    echo "│ Update Date: "$SCRIPT_DATE"                                                                │"
    echo "│ Thanks for using! If helpful, please give us a star /<3                                │"
    echo "└────────────────────────────────────────────────────────────────────────────────────────┘"
}

# Basic Configuration
TAILSCALE_URL="gunanovo/openwrt-tailscale/releases/latest"
TAILSCALE_NORMAL_URL="gunanovo/openwrt-tailscale/releases/latest"  # TODO
URL_PROXYS="https://ghfast.top/https://github.com
https://cf.ghproxy.cc/https://github.com
https://www.ghproxy.cc/https://github.com
https://gh-proxy.com/https://github.com
https://ghproxy.cc/https://github.com
https://ghproxy.cn/https://github.com
https://www.ghproxy.cn/https://github.com
https://github.com"
INIT_URL="/gunanovo/openwrt-tailscale/blob/main/etc/init.d/tailscale"
MOUNT_POINT="/overlay"
TMP_TAILSCALE='#!/bin/sh
                set -e

                /usr/bin/install.sh --update
                /tmp/tailscale "$@"'
TMP_TAILSCALED='#!/bin/sh
                set -e

                /tmp/tailscaled "$@"'

UPDATE_DIRECTLY="false"
NO_TINY="false"

# Global Variables
available_proxy=""
tailscale_latest_version=""
is_tailscale_installed=false
tailscale_install_status="none"
found_tailscale_file=false
tailscale_version=""
free_space=""
file_size=""
free_space_mb=""
file_size_mb=""
tailscale_persistent_installable=""
show_init_progress_bar="true"

# Function: Set DNS
set_system_dns() {
cat <<EOF > /etc/resolv.conf
search lan
nameserver 223.5.5.5
nameserver 119.29.29.29
EOF
}

# Function: Get system architecture
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
            echo "Current machine architecture: [${arch_}${endianness}]"
            echo "Script does not support this architecture"
            echo "------------------------------------------------------"
            exit 1
            ;;
    esac
}

# Function: Check Tailscale installation status
check_tailscale_install_status() {
    if command -v tailscale >/dev/null 2>&1; then
        version_output=$(tailscale version 2>/dev/null)
        if [ -n "$version_output" ]; then
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

# Function: Check free storage space
get_free_space() {
    if [ -z "$MOUNT_POINT" ]; then
        echo "Error: MOUNT_POINT not defined"
        exit 1
    fi

    free_space_kb=$(df -k "$MOUNT_POINT" | tail -n 1 | awk '{print $4}')
    
    if [ -z "$free_space_kb" ] || ! echo "$free_space_kb" | grep -q '^[0-9]\+$'; then
        echo "Error: Failed to get free space of $MOUNT_POINT"
        exit 1
    fi

    free_space=$((free_space_kb * 1024))
    free_space_mb=$(expr $free_space / 1024 / 1024)
}

# Function: Get Tailscale info
get_tailscale_info() {
    attempt_range="1 2 3"
    attempt_timeout=10

    for attempt_times in $attempt_range; do
        for attempt_proxy in $URL_PROXYS; do
            attempt_url="$attempt_proxy/$TAILSCALE_URL/download/version.txt"
            tailscale_latest_version=$(wget -qO- --timeout=$attempt_timeout "$attempt_url" | sed 's/^v//')

            if [ -n "$tailscale_latest_version" ]; then
                available_proxy="$attempt_proxy"
                break 2
            fi
        done
    done
    
    file_size=$(wget --spider --max-redirect=10 --server-response "$available_proxy/$TAILSCALE_URL/download/tailscaled-linux-${arch}" 2>&1 | 
        grep 'Content-Length' | 
        awk '{print $2}' | 
        tail -n 1)

    if [ -z "$file_size" ] || ! [[ "$file_size" =~ ^[0-9]+$ ]]; then
        echo "Error: Failed to get Tailscale file size"
        echo "1. Check network connection"
        echo "2. Report to developer"
        exit 1
    else
        if [ "$free_space" -gt "$file_size" ]; then
            tailscale_persistent_installable=true
        else
            tailscale_persistent_installable=false
        fi
    fi

    file_size_mb=$(expr $file_size / 1024 / 1024)
}

# Function: Update
update() {
    echo "Updating..."
    if [ "$UPDATE_DIRECTLY" = "true" ]; then
        if [ "$tailscale_install_status" = "temp" ]; then
            temp_install "true"
        elif [ "$tailscale_install_status" = "persistent" ]; then
            persistent_install "true"
        fi
    else
        if [ "$tailscale_install_status" = "temp" ]; then
            temp_install
        elif [ "$tailscale_install_status" = "persistent" ]; then
            persistent_install
        fi
    fi
}

# Function: Uninstall
remove() { 
    while true; do
        read -n 1 -p "Confirm to uninstall Tailscale? (y/N): " choice

        if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
            tailscale_stoper

            directories="/etc/init.d /etc /etc/config /usr/bin /tmp /var/lib"
            binaries="tailscale tailscaled"

            for dir in $directories; do
                for bin in $binaries; do
                    if [ -f "$dir/$bin" ]; then
                        rm -rf $dir/$bin
                    fi
                done
            done

            ip link delete tailscale0
            break
        else
            echo "Uninstallation canceled"
            break
        fi
    done
}

# Function: Persistent install
persistent_install() {
    confirm2persistent_install=$1
    if [ "$confirm2persistent_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!! Please confirm:                            ║"
        echo "║                                                       ║"
        echo "║ For persistent installation, ensure free space >      ║"
        echo "║ "$file_size_mb"MB, recommend >15MB.                   ║"
        echo "║ Report issues at:                                     ║"
        echo "║ https://github.com/GuNanOvO/openwrt-tailscale/issues  ║"
        echo "║ Thanks for using! /<3                                 ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "Confirm persistent installation? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            exit
        fi
    echo "Performing persistent installation..."
    fi 
    downloader
    mv /tmp/tailscaled /usr/bin
    ln -sv /usr/bin/tailscaled /usr/bin/tailscale
    tailscale_starter
    echo "Persistent installation completed"
}

# Function: Switch temp to persistent
temp_to_persistent() {
    confirm2persistent_install=$1
    if [ "$confirm2persistent_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!! Please confirm:                            ║"
        echo "║                                                       ║"
        echo "║ For persistent installation, ensure free space >      ║"
        echo "║ "$file_size_mb"MB, recommend >15MB.                   ║"
        echo "║ Report issues at:                                     ║"
        echo "║ https://github.com/GuNanOvO/openwrt-tailscale/issues  ║"
        echo "║ Thanks for using! /<3                                 ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "Confirm persistent installation? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            exit
        fi
        echo "Performing persistent installation..."
    fi
    tailscale_stoper
    rm -rf /tmp/tailscale
    rm -rf /tmp/tailscaled
    rm -rf /usr/bin/tailscale
    rm -rf /usr/bin/tailscaled
    persistent_install
}

# Function: Temporary install
temp_install() { 
    confirm2temp_install=$1
    if [ "$confirm2temp_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!! Please confirm:                            ║"
        echo "║                                                       ║"
        echo "║ Temporary installation uses /tmp directory,           ║"
        echo "║ which gets cleared on reboot. If script fails         ║"
        echo "║ to reinstall after reboot, services may break.        ║"
        echo "║ Recommended to use persistent installation if possible║"
        echo "║ Report issues at:                                     ║"
        echo "║ https://github.com/GuNanOvO/openwrt-tailscale/issues  ║"
        echo "║ Thanks for using! /<3                                 ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "Confirm temporary installation? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            exit
        fi
    echo "Performing temporary installation..."
    fi 
    downloader
    ln -sv /tmp/tailscaled /tmp/tailscale
    echo "$TMP_TAILSCALE" > /usr/bin/tailscale
    echo "$TMP_TAILSCALED" > /usr/bin/tailscaled
    echo "Temporary installation completed"
    tailscale_starter
}

# Function: Switch persistent to temp
persistent_to_temp() {
    confirm2temp_install=$1
    if [ "$confirm2temp_install" != "true" ]; then
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║ WARNING!!! Please confirm:                            ║"
        echo "║                                                       ║"
        echo "║ Temporary installation uses /tmp directory,           ║"
        echo "║ which gets cleared on reboot. If script fails         ║"
        echo "║ to reinstall after reboot, services may break.        ║"
        echo "║ Recommended to use persistent installation if possible║"
        echo "║ Report issues at:                                     ║"
        echo "║ https://github.com/GuNanOvO/openwrt-tailscale/issues  ║"
        echo "║ Thanks for using! /<3                                 ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        read -n 1 -p "Confirm temporary installation? (y/N): " choice

        if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
            exit
        fi
    fi 
    echo "Switching to temporary installation..."
    tailscale_stoper
    rm -rf /usr/bin/tailscale
    rm -rf /usr/bin/tailscaled
    temp_install "true"
}

# Function: Downloader
downloader() {
    wget -cO /tmp/tailscaled "$available_proxy/$TAILSCALE_URL/download/tailscaled-linux-${arch}"
    wget -cO /etc/init.d/tailscale "$available_proxy/$INIT_URL"
}

# Function: Start Tailscale
tailscale_starter() {
    echo "Starting Tailscale..."
    /etc/init.d/tailscale start
    sleep 3
    tailscale up
    echo "Tailscale started"
}

# Function: Stop Tailscale
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

# Function: Initialize
init() {
    show_init_progress_bar=$1
    local functions="set_system_dns get_system_arch check_tailscale_install_status get_free_space get_tailscale_info"
    local function_count=5
    local total=50
    local progress=0
    
    if [ "$show_init_progress_bar" != "false" ]; then
        printf "\rInitializing: [%-50s] %3d%%" "$(printf '='%.0s $(seq 1 "$progress"))" "$((progress * 2))"
        
        for function in $functions; do
            printf "\rInitializing: [%-50s] %3d%%" "$(printf '='%.0s $(seq 1 "$progress"))" "$((progress * 2))"
            eval "$function"
            progress=$((progress + $((total / $function_count))))
        done
    
        printf "\rCompleted: [%-50s] %3d%%" "$(printf '='%.0s $(seq 1 "$progress"))" "$((progress * 2))"
    else
        for function in $functions; do
            eval "$function"
        done
    fi
}

# Function: Show info
show_info() {
    echo "=============== Basic Information ==============="
    echo "│ Architecture: [${arch}${endianness}]"
    if [ "$is_tailscale_installed" = "true" ]; then
        echo "│ Tailscale Status: Installed"
        if [ "$tailscale_install_status" = "temp" ]; then
        echo "│ Installation Type: Temporary"
        elif [ "$tailscale_install_status" = "persistent" ]; then
        echo "│ Installation Type: Persistent"
        fi
        echo "│ Tailscale Version: $tailscale_version"
    else 
        echo "│ Tailscale Status: Not installed"
        echo "│ Tailscale Version: N/A"
    fi

    echo "│ Latest Version: $tailscale_latest_version"
    echo "│ Free Space: $free_space B / $(expr $free_space / 1024 / 1024) MB"
    echo "│ File Size: $file_size B / $(expr $file_size / 1024 / 1024) MB" 
    if [ "$free_space" -gt "$file_size" ]; then
        echo "│ Space sufficient for persistent install"
    else
        echo "│ Insufficient space for persistent install"
    fi
    echo "=============== Basic Information ==============="
}

# Function: Option menu
option_menu() {
    while true; do
        menu_items=""
        menu_operations=""
        option_index=1

        menu_items="$option_index).Show-basic-info"
        menu_operations="show_info"
        option_index=$((option_index + 1))

        if [ "$is_tailscale_installed" = "true" ] && [ $tailscale_latest_version != $tailscale_version ]; then
            menu_items="$menu_items $option_index).Update"
            menu_operations="$menu_operations update"
            option_index=$((option_index + 1))
        fi

        if [ "$is_tailscale_installed" = "true" ]; then
            menu_items="$menu_items $option_index).Uninstall"
            menu_operations="$menu_operations remove"
            option_index=$((option_index + 1))
        fi

        if [ "$tailscale_install_status" = "temp" ] && [ "$tailscale_persistent_installable" = "true" ]; then
            menu_items="$menu_items $option_index).Switch-to-Persistent"
            menu_operations="$menu_operations temp_to_persistent"
            option_index=$((option_index + 1))
        fi

        if [ "$is_tailscale_installed" = "false" ] && [ "$tailscale_persistent_installable" = "true" ]; then
            menu_items="$menu_items $option_index).Persistent-Install"
            menu_operations="$menu_operations persistent_install"
            option_index=$((option_index + 1))
        fi

        if [ "$tailscale_install_status" = "persistent" ]; then
            menu_items="$menu_items $option_index).Switch-to-Temporary"
            menu_operations="$menu_operations persistent_to_temp"
            option_index=$((option_index + 1))
        fi

        if [ "$is_tailscale_installed" = "false" ]; then
            menu_items="$menu_items $option_index).Temporary-Install"
            menu_operations="$menu_operations temp_install"
            option_index=$((option_index + 1))
        fi

        menu_items="$menu_items $option_index).Exit"
        menu_operations="$menu_operations exit"

        while true; do
            echo ""
            echo "=============== Menu ==============="
            
            for item in $menu_items; do
                echo "│       $item"
            done
            echo ""

            read -n 1 -p "Enter option (0 ~ $option_index): " choice
            echo ""
            echo ""

            if [ "$choice" -ge 0 ] && [ "$choice" -le "$option_index" ]; then
                operation_index=1
                for operation in $menu_operations; do
                    if [ "$operation_index" = "$choice" ]; then
                        eval "$operation"
                    fi
                    operation_index=$((operation_index + 1))
                done
                echo ""
            else
                echo "Invalid option, please retry!"
                echo ""
                break
            fi
        done
    done
}

# Function: Show help
show_help() {
    echo "Tailscale on OpenWrt installer script. $SCRIPT_VERSION"
    echo "https://github.com/GuNanOvO/openwrt-tailscale"
    echo "  Usage:   "
    echo "      --help: Show this help"
    echo "      --update: Update Tailscale directly (no confirmation)"
    echo "      --notiny: Use uncompressed version (TODO)"
}

# Main
for arg in "$@"; do
    case $arg in
    --help)
        show_help
        exit 0
        ;;
    --update)
        UPDATE_DIRECTLY="true"
        ;;
    --notiny)
        NO_TINY="true"
        ;;
    *)
        echo "Unknown argument: $arg"
        show_help
        exit 1
        ;;
    esac
done

if [ "$UPDATE_DIRECTLY" = "true" ]; then
    init "false"
    update
    exit 0
fi

clear
script_info
init
clear
script_info
option_menu