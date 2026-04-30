#!/bin/bash

KERNEL_VER="$(rpm -qa | grep -E 'kernel-[0-9].*?[.\\-]ba' | cut -d'-' -f2,3)"

set -ouex pipefail

# Enable RPMFusion repositories
#dnf5 -y install \
#  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
#dnf5 -y install \
#  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Virtualbox
dnf5 -y install dkms
dnf5 -y install "https://download.virtualbox.org/virtualbox/7.2.8/VirtualBox-7.2-7.2.8_173730_fedora40-1.x86_64.rpm"

vbox_hardcode_kv () {
  local TARGET_FILE="$1"
  # sed expression to replace "uname -r" with "echo '[kernel version]'"
  local EXPR_UNAME_R="s/uname -r/echo '$KERNEL_VER'/g"
  # sed expression to replace "depmod -a" with "depmod -v '[kernel version]' -a"
  local EXPR_DEPMOD_A="s/depmod -a/depmod -v '$KERNEL_VER' -a/g"
  sed -i -e "$EXPR_UNAME_R" -e "$EXPR_DEPMOD_A" "$TARGET_FILE"
}
vbox_hardcode_kv /usr/lib/virtualbox/vboxdrv.sh
vbox_hardcode_kv /usr/lib/virtualbox/check_module_dependencies.sh
# run vboxconfig with KERN_VER set to build kernel modules
KERN_VER="$KERNEL_VER" /sbin/vboxconfig
if [[ -e /var/log/vbox-setup.log ]]; then
  cat /var/log/vbox-setup.log
fi
mkdir -p /usr/lib/modules-load.d
cat > /usr/lib/modules-load.d/kinoite-virtualbox.conf << EOF
# load virtualbox kernel drivers
vboxdrv
vboxnetflt
vboxnetflt
EOF

# Packet Tracer Dependencies
dnf5 -y install qt5-qtnetworkauth qt5-qtscript qt5-qtmultimedia qt5-qtwebsockets qt5-qtwebengine
# Download and extract packet tracer .deb archive
curl "https://www.netacad.com/authoring-resources/courses/ff9e491c-49be-4734-803e-a79e6e83dab1/c3636211-1ce6-4f92-8a22-ccddf902dd72/en-US/assets/PacketTracer822_amd64_signed_en-US_35234a27-3127-49bc-91ce-2926af76f07a.deb" -o pt.deb
ar -x pt.deb
tar -xf data.tar.xz
# Copy PacketTracer binary and libssl/libcrypto - Fedora no longer packages openssl 1.1, so we use what has been bundled with PacketTracer.
cp opt/pt/bin/PacketTracer /usr/lib/
cp opt/pt/bin/libssl.so.1.1 /usr/lib
cp opt/pt/bin/libcrypto.so.1.1 /usr/lib
# Copy desktop entry for PacketTracer
# TODO: Should add an icon
echo """
[Desktop Entry]
Type=Application
Name=Cisco Packet Tracer
Exec=/usr/bin/packettracer
StartupNotify=false
Terminal=false
""" >> /usr/share/applications/PacketTracer.desktop
# Copy the packettracer start script into /usr/bin - You can't just run the binary directly on Fedora.
cp opt/pt/packettracer /usr/bin/

# VirtualBox Dependencies
#dnf5 -y install gcc kernel-headers kernel-devel
# We can install VirtualBox itself just using the link to the RPM file

# Additional Software
dnf5 -y install libreoffice putty remmina filezilla tmux btop fastfetch hyfetch picocom bat kitty chromium
# System Restrictions
# Gives non-root users access to USB block devices - But NOT internal drives
echo 'SUBSYSTEMS=="usb", SUBSYSTEM=="block", TAG+="uaccess", MODE="660"' >> /etc/udev/rules.d/00-usb-permissions.rules
