#!/bin/bash

set -ouex pipefail

# Enable RPMFusion repositories
dnf5 -y install \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf5 -y install \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Virtualbox
dnf5 -y install VirtualBox --skip-broken

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
