#!/bin/bash
# Detta skript skapar ett ROBUST och MINIMALT root-filsystem (RootFS)
# Designat för att köras i månader/år utan omstart.
#
# OBS! Skriptet måste köras på en Linux-maskin (Debian/Ubuntu) där
# `apt-get` och `debootstrap` finns tillgängliga. På macOS kommer kommandon
# som apt-get saknas; kör istället denna via multipass (se nedan).

# kontrollera att vi är i en Debian/Ubuntu-liknande miljö
if ! command -v apt-get >/dev/null 2>&1; then
    echo "FEL: apt-get saknas. Du måste köra det här skriptet på en Debian/Ubuntu-maskin."
    echo "Exempel (från macOS):"
    echo "  multipass exec kernel-builder -- sudo /home/ubuntu/MinecraftAI_OS/3_bygga_rootfs.sh"
    exit 1
fi

# default placering – kan ändras genom att skicka en parameter
ROOTFS="/tmp/minecraft-os-root"

# Om ett argument ges kan vi köra med anpassad plats (t.ex. en monterad
# katalog från värdmaskinen).
if [ -n "$1" ]; then
    ROOTFS="$1"
fi


# Skapa mappen manuellt ifall den saknas (vid första körning)
sudo mkdir -p $ROOTFS

echo "========================================================="
echo " BYGGER ETT ULTRA-STABILT SERVER-FILSYSTEM              "
echo "========================================================="

# 1. Installera debootstrap om det saknas
sudo apt-get update
sudo apt-get install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-arm64-bin

# 2. Skapa bas-systemet (Debian Minimal)
# Vi använder qemu-user-static ifall vi bygger på en x86-maskin (Mac Intel)
echo "[1/4] Laddar ner minimala Debian-filer..."
sudo apt-get install -y qemu-user-static
sudo debootstrap --variant=minbase --arch=arm64 --include=ca-certificates,lsb-release bookworm $ROOTFS http://deb.debian.org/debian

# 3. Konfigurera OS för stabilitet (Chroot-magi)
echo "[2/4] Optimerar OS-inställningar för evig drift..."
# Kopiera qemu-binary in i rootfs för att kunna köra chroot på Mac/X86
sudo cp /usr/bin/qemu-aarch64-static $ROOTFS/usr/bin/

sudo bash -c "cat <<EOF > $ROOTFS/etc/fstab
# Minimera skrivningar till disken för att spara SSD-livslängd
tmpfs   /tmp         tmpfs   nodev,nosuid,size=512M   0   0
tmpfs   /var/log     tmpfs   nodev,nosuid,size=128M   0   0
EOF"

# 4. Installera Java & Python utan rekommenderat skräp + GUI-stöd (X11)
echo "[3/4] Installerar Java (Minecraft), Python (AI-Supervisor) & Xorg-server..."
# openjdk-21 paket finns inte i Debian bookworm längre, använd standard-jre istället
# för att undvika fel vid paketkonfiguration måste vi montera proc/sys/dev i chrooten
sudo mount --bind /proc $ROOTFS/proc
sudo mount --bind /sys  $ROOTFS/sys
sudo mount --bind /dev  $ROOTFS/dev
sudo mount --bind /dev/pts $ROOTFS/dev/pts

sudo chroot $ROOTFS apt-get update
sudo chroot $ROOTFS apt-get install -y --no-install-recommends \
    default-jre-headless \
    python3-minimal \
    python3-pip \
    python3-tk \
    ssh \
    iptables \
    iproute2 \
    systemd-sysv \
    xserver-xorg \
    xinit \
    x11-xserver-utils \
    matchbox-window-manager

# när vi är klara kan vi unmounta (ignorera eventuella fel)
sudo umount $ROOTFS/dev/pts || true
sudo umount $ROOTFS/dev || true
sudo umount $ROOTFS/sys || true
sudo umount $ROOTFS/proc || true

# [AKTIVERAR OPTIMERINGAR FÖR INTERNET]
# Vi lägger till sysctl-optimeringar direkt i filsystemet
# kopiera konfigurationsfiler för nätet
if [ -f /home/ubuntu/network_optimize.conf ]; then
    sudo cp /home/ubuntu/network_optimize.conf $ROOTFS/etc/sysctl.d/99-minecraft-network.conf
else
    sudo cp network_optimize.conf $ROOTFS/etc/sysctl.d/99-minecraft-network.conf
fi

# Vi installerar Traffic Control (TC) för att förhindra Bufferbloat
if [ -f /home/ubuntu/minecraft-tc.service ]; then
    sudo cp /home/ubuntu/minecraft-tc.service $ROOTFS/etc/systemd/system/minecraft-tc.service
else
    sudo cp minecraft-tc.service $ROOTFS/etc/systemd/system/minecraft-tc.service
fi
sudo chroot $ROOTFS systemctl enable minecraft-tc.service

# [INSTALLERAR UBUNTU DESKTOP GUI I OS-et]
echo "Kopierar GUI-filer och AI-läkar-skript till OS:et..."
# om filerna finns i /home/ubuntu (överförda) använder vi dem, annars försöker vi
#  hämta dem från den monterade katalogen
if [ -f /home/ubuntu/ubuntu_desktop_gui.py ]; then
    sudo cp /home/ubuntu/ubuntu_desktop_gui.py $ROOTFS/usr/local/bin/ubuntu_desktop_gui.py
else
    sudo cp ubuntu_desktop_gui.py $ROOTFS/usr/local/bin/ubuntu_desktop_gui.py
fi
if [ -f /home/ubuntu/mc_self_heal.sh ]; then
    sudo cp /home/ubuntu/mc_self_heal.sh $ROOTFS/usr/local/bin/mc_self_heal.sh
else
    sudo cp mc_self_heal.sh $ROOTFS/usr/local/bin/mc_self_heal.sh
fi
sudo chmod +x $ROOTFS/usr/local/bin/ubuntu_desktop_gui.py
sudo chmod +x $ROOTFS/usr/local/bin/mc_self_heal.sh

# Skapa en tjänst som startar Minecraft-läkaren vid boot
sudo bash -c "cat <<EOF > $ROOTFS/etc/systemd/system/minecraft-healer.service
[Unit]
Description=Minecraft AI OS - Self Healing Daemon
After=network.target

[Service]
ExecStart=/usr/local/bin/mc_self_heal.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF"

sudo chroot $ROOTFS systemctl enable minecraft-healer.service

# Skapa ett startskript för X-sessionen
sudo bash -c "cat <<EOF > $ROOTFS/etc/X11/Xsession.d/10-start-minecraft-gui
#!/bin/bash
# Starta en minimalistisk fönsterhanterare och vårt Ubuntu GUI
matchbox-window-manager &
python3 /usr/local/bin/ubuntu_desktop_gui.py
EOF"
sudo chmod +x $ROOTFS/etc/X11/Xsession.d/10-start-minecraft-gui

# Skapa en tjänst som startar X vid boot
sudo bash -c "cat <<EOF > $ROOTFS/etc/systemd/system/minecraft-gui.service
[Unit]
Description=Minecraft AI OS - Ubuntu Desktop GUI
After=network.target

[Service]
ExecStart=/usr/bin/startx
Restart=always
User=root
Environment=DISPLAY=:0

[Install]
WantedBy=multi-user.target
EOF"

sudo chroot $ROOTFS systemctl enable minecraft-gui.service

# 5. Rensa bort ALLT temporärt för att spara RAM
sudo chroot $ROOTFS apt-get clean
sudo rm -rf $ROOTFS/var/lib/apt/lists/*
sudo rm $ROOTFS/usr/bin/qemu-aarch64-static

echo "========================================================="
echo " KLART! Ditt OS har optimerad nätverkskö, Ubuntu GUI och"
echo " är redo för distrubtion! "
echo "========================================================="
