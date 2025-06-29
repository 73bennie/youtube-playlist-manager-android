#!/usr/bin/env bash

# YouTube Playlist Manager - Backup Script
# Creates a timestamped backup of the entire project

set -e

# Get the script directory and navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT"

# Create timestamp
TIMESTAMP=$(date +"%m-%d-%Y_%I-%M-%S%p")
BACKUP_NAME="Youtube-Playlist-Manager-Windows-backup-$TIMESTAMP.tar.gz"

echo -e "${CYAN}=== Create Project Backup ===${RESET}"
echo

# Check if we're in the right directory
if [[ ! -f "menu" ]] || [[ ! -d "lib" ]]; then
    echo -e "${RED}Error: This doesn't appear to be the YouTube Playlist Manager directory${RESET}"
    echo "Please run this script from the project root directory."
    exit 1
fi

echo "Creating backup: $BACKUP_NAME"
echo

# Create the backup
if tar -czf "$BACKUP_NAME" \
    --exclude='*.tar.gz' \
    --exclude='.git' \
    --exclude='backups' \
    --exclude='node_modules' \
    --exclude='*.log' \
    .; then
    
    # Get file size
    FILE_SIZE=$(du -h "$BACKUP_NAME" | cut -f1)
    
    echo -e "${GREEN}✓ Backup created successfully!${RESET}"
    echo "File: $BACKUP_NAME"
    echo "Size: $FILE_SIZE"
    echo "Location: $(pwd)/$BACKUP_NAME"
    echo
    
    # Show recent backups
    echo -e "${CYAN}Recent backups:${RESET}"
    ls -lah *backup*.tar.gz 2>/dev/null | tail -5 | while read -r line; do
        echo "  $line"
    done || echo "  No previous backups found"
    
else
    echo -e "${RED}✗ Backup failed!${RESET}"
    exit 1
fi

echo
echo -e "${YELLOW}Tip: You can restore this backup by extracting it to a new directory${RESET}" 