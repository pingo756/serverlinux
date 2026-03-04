#!/bin/bash
# Detta skript startar det färdiga RootFS:et som en virtuell maskin i din Mac
# så att du kan se GUI:t "inifrån" OS:et istället för bara på Macen.

VM_NAME="minecraft-ai-os-machine"
# Flytta sökvägen till /tmp för att säkerställa att både Mac och root kan se den
ROOTFS_DIR="/tmp/minecraft-os-root"

echo "========================================================="
echo " STARTAR DITT NYA OS (MINECRAFT AI OS v1.0)             "
echo "========================================================="

# Kolla om vi har byggt RootFS, annars hjälp användaren att starta det
if [ ! -d "$ROOTFS_DIR" ] || [ -z "$(ls -A "$ROOTFS_DIR" 2>/dev/null)" ]; then
    echo "Hittade inte OS-filerna i $ROOTFS_DIR eller katalogen är tom."
    echo "Observera: `3_bygga_rootfs.sh` måste köras i en Linuxmiljö (t ex multipass),"
    echo "inte direkt på macOS."
    echo "Försöker starta ./3_bygga_rootfs.sh åt dig..."
    chmod +x 3_bygga_rootfs.sh
    ./3_bygga_rootfs.sh
    
    # Dubbelkoll efter bygget
    if [ ! -d "$ROOTFS_DIR" ] || [ -z "$(ls -A "$ROOTFS_DIR" 2>/dev/null)" ]; then
        echo "FEL: Bygget av OS-filerna misslyckades eller katalogen är fortfarande tom."
        echo "Kör skriptet i en Linux-miljö, till exempel:"
        echo "  multipass exec kernel-builder -- sudo /home/ubuntu/MinecraftAI_OS/3_bygga_rootfs.sh"
        exit 1
    fi
fi

echo "Skapar en körbar miljö i Multipass..."
multipass launch 24.04 --name $VM_NAME --cpus 2 --memory 4G --disk 10G

echo "Monterar in ditt RootFS som en disk (Simulerar boot)..."
multipass mount $ROOTFS_DIR $VM_NAME:/mnt/minecraft-os

# Kopiera GUI-scriptet till VM:ens lokala filesystem istället för att läsa
# det över den monterade mappen (mounts är noexec/noopen och orsakar
# permission denied när man försöker köra eller öppna filer därifrån).
echo "Installerar GUI-beroenden i VM..."
# se till att tk finns i VM:s paketlager
multipass exec $VM_NAME -- sudo apt-get update
multipass exec $VM_NAME -- sudo apt-get install -y python3-tk

echo "Kopierar GUI-programmet till VM för körning..."
multipass transfer ubuntu_desktop_gui.py $VM_NAME:/tmp/
# flytta till systemplats och sätt rättigheter
multipass exec $VM_NAME -- sudo mv /tmp/ubuntu_desktop_gui.py /usr/local/bin/
multipass exec $VM_NAME -- sudo chmod +x /usr/local/bin/ubuntu_desktop_gui.py

# Starta GUI-scriptet inifrån maskinen
# (Kräver XQuartz på din Mac om du vill se fönstret inifrån en ren VM)
multipass exec $VM_NAME -- python3 /usr/local/bin/ubuntu_desktop_gui.py

echo "========================================================="
echo " OS:et körs nu i bakgrunden! "
echo " Du kan logga in med: multipass shell $VM_NAME "
echo "========================================================="
