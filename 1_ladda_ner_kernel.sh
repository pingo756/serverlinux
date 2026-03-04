#!/bin/bash
# Detta skript laddar ner och förbereder Linux-kärnan från kernel.org för ARM64

KERNEL_VERSION="6.8.4"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"

echo "==========================================="
echo " Laddar ner Linux Kernel v${KERNEL_VERSION}    "
echo "==========================================="

echo "[1/3] Laddar ner källkodsarkivet från kernel.org..."
curl -O $KERNEL_URL

echo "[2/3] Packar upp arkivet (detta kan ta någon minut)..."
tar -xf linux-${KERNEL_VERSION}.tar.xz

echo "[3/3] Nedladdning och uppackning klar!"
echo "Du kan nu navigera in i mappen med:"
echo "cd linux-${KERNEL_VERSION}"
echo "Nästa steg är att konfigurera kärnan för ARM64."
