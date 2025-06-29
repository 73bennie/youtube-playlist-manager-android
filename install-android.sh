#!/usr/bin/env bash

# YouTube Playlist Manager - Android/Termux Installation Script
# Installs dependencies and sets up the environment for Android

set -e

echo -e "${CYAN}=== YouTube Playlist Manager - Android Installation ===${RESET}"
echo

# Check if we're running on Android/Termux
if [[ ! -d "/data/data/com.termux" ]] && [[ -z "$TERMUX_VERSION" ]]; then
    echo -e "${RED}Error: This script is designed for Android/Termux only${RESET}"
    echo "Please run this on an Android device with Termux installed."
    exit 1
fi

echo -e "${GREEN}✓ Detected Android/Termux environment${RESET}"
echo

# Update package list
echo "Updating package list..."
pkg update -y

# Install required packages
echo "Installing required packages..."
pkg install -y \
    python \
    ffmpeg \
    sqlite \
    wget \
    curl \
    git

# Install yt-dlp
echo "Installing yt-dlp..."
pip install --upgrade yt-dlp

# Set up Android storage access
echo "Setting up Android storage access..."
if [[ ! -d "$HOME/storage/shared" ]]; then
    echo -e "${YELLOW}Setting up storage permissions...${RESET}"
    termux-setup-storage
    echo -e "${GREEN}✓ Storage access configured${RESET}"
else
    echo -e "${GREEN}✓ Storage access already configured${RESET}"
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p "$HOME/storage/shared/Music/YouTube-Playlist-Manager"
mkdir -p "ytdata"
mkdir -p "backups"

# Set up database
echo "Initializing database..."
if [[ -f "lib/config.sh" ]]; then
    source "lib/config.sh"
    source "lib/functions.sh"
    createEnv
    echo -e "${GREEN}✓ Database initialized${RESET}"
else
    echo -e "${RED}Error: Configuration files not found${RESET}"
    exit 1
fi

# Create sample plist.txt
if [[ ! -f "ytdata/plist.txt" ]]; then
    echo "Creating sample plist.txt..."
    cat > "ytdata/plist.txt" << 'EOF'
# YouTube Playlist Manager - Playlist URLs
# Add your YouTube Music playlist URLs or IDs here
# Examples:
# https://music.youtube.com/playlist?list=OLAK5uy_...
# OLAK5uy_... (just the playlist ID)

EOF
    echo -e "${GREEN}✓ Sample plist.txt created${RESET}"
fi

# Make scripts executable
echo "Making scripts executable..."
chmod +x *.sh
chmod +x lib/*.sh
chmod +x tools/*.sh

echo
echo -e "${GREEN}=== Installation Complete! ===${RESET}"
echo
echo -e "${CYAN}Next steps:${RESET}"
echo "1. Edit ytdata/plist.txt and add your playlist URLs"
echo "2. Run: ./menu"
echo "3. Choose option 1 to fetch metadata"
echo "4. Choose option 3 to download tracks"
echo
echo -e "${YELLOW}Music files will be saved to:${RESET}"
echo "$HOME/storage/shared/Music/YouTube-Playlist-Manager"
echo
echo -e "${GREEN}Enjoy your music! 🎵${RESET}" 