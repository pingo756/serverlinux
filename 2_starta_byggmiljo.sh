#!/bin/bash
# Detta skript skapar en snabb, tillfällig Ubuntu-miljö för att kompilera Linux-kärnan

echo "========================================================="
echo " Startar upp en Ubuntu-byggmiljö för Linux Kernel (ARM64)"
echo "========================================================="

# Kolla om Multipass är installerat, annars installera det
if ! command -v multipass &> /dev/null
then
    echo "Multipass saknas. Installerar via Homebrew..."
    brew install --cask multipass
fi

echo "Skapar en Ubuntu virtuell maskin 'kernel-builder' (detta kan ta någon minut)..."
# Vi ger den 4 processorkärnor och 8GB RAM för att bygga kärnan snabbt
multipass launch 24.04 --name kernel-builder --cpus 4 --memory 8G --disk 20G

echo "Monterar din Kernel-mapp så Ubuntu kommer åt den..."
multipass mount "$PWD" kernel-builder:/home/ubuntu/MinecraftAI_OS

echo "Installerar nödvändiga kompilatorverktyg i Ubuntu..."
multipass exec kernel-builder -- sudo apt-get update
multipass exec kernel-builder -- sudo apt-get install -y build-essential libncurses-dev bison flex libssl-dev libelf-dev bc

echo "========================================================="
echo " KLAR! Du har nu en fullfjädrad Linux-byggmiljö i din Mac."
echo " För att logga in i byggmaskinen, kör kommando:"
echo "   multipass shell kernel-builder"
echo " "
echo " Inne i maskinen kan du sedan gå till: cd ~/MinecraftAI_OS/linux-6.8.4"
echo "========================================================="
