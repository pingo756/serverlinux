#!/bin/bash
# Detta skript flyttar hela bygget till INSIDAN av en Linux-VM 
# för att undvika problem med macOS-begränsningar för chroot/ARM64.

VM_NAME="minecraft-builder"
BUILD_DIR="/home/ubuntu/MinecraftAI_OS"

echo "========================================================="
echo " STARTAR FULLSTÄNDIGT LINUX-BYGGE AV DITT OS            "
echo "========================================================="

# 1. Kolla om vi har en bygg-maskin, annars skapa den
if ! multipass info $VM_NAME &> /dev/null; then
    echo "Skapar Linux-byggmaskin 'minecraft-builder'..."
    multipass launch 24.04 --name $VM_NAME --cpus 4 --memory 8G --disk 20G
fi

# 2. Montera dina filer in i byggmaskinen
echo "Synkar filer till Linux-miljö..."
multipass mount "$PWD" $VM_NAME:$BUILD_DIR

# 3. Kör bygget inuti Linux-maskinen där sudo/chroot fungerar perfekt
echo "Installerar byggverktyg i VM:en (Debootstrap, QEMU)..."
multipass exec $VM_NAME -- sudo apt-get update
multipass exec $VM_NAME -- sudo apt-get install -y debootstrap qemu-user-static python3-tk xserver-xorg xinit matchbox-window-manager

echo "Kör huvudbygget (3_bygga_rootfs.sh) INIFRÅN Linux..."
multipass exec $VM_NAME -- bash -c "cd $BUILD_DIR && sudo ./3_bygga_rootfs.sh"

# 4. Starta GUI:t inifrån Linux efter bygget
echo "Bygget klart! Startar ditt Ubuntu GUI i VM:en..."
multipass exec $VM_NAME -- python3 $BUILD_DIR/ubuntu_desktop_gui.py

echo "========================================================="
echo " KLART! Ditt OS är nu byggt korrekt inuti Linux-VM:en. "
echo " För att logga in, kör: multipass shell $VM_NAME "
echo "========================================================="
