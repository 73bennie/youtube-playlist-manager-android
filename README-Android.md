# YouTube Playlist Manager - Android/Termux Version

A powerful YouTube Music playlist manager optimized for Android devices running Termux. Download, organize, and manage your YouTube Music playlists with metadata tagging and album art.

## 🚀 Features

- **📱 Android Optimized** - Designed specifically for Android/Termux
- **🎵 Music Downloads** - Download YouTube Music playlists as high-quality Opus files
- **🏷️ Metadata Tagging** - Automatic artist, album, and track information
- **🖼️ Album Art** - Download and embed album artwork
- **🗄️ Database Management** - SQLite database for track organization
- **🔄 Playlist Sync** - Keep your playlists up to date
- **🧹 Clean Interface** - Beautiful, organized menu system
- **💾 Backup System** - Backup and restore your database and playlists

## 📋 Requirements

- **Android device** with Termux installed
- **Internet connection** for downloads
- **Storage permission** for saving music files

## 🛠️ Installation

### 1. Install Termux
Download and install Termux from [F-Droid](https://f-droid.org/packages/com.termux/) (recommended) or Google Play Store.

### 2. Clone the Repository
```bash
cd ~
git clone https://github.com/yourusername/youtube-playlist-manager-android.git
cd youtube-playlist-manager-android
```

### 3. Run Installation Script
```bash
chmod +x install-android.sh
./install-android.sh
```

The installation script will:
- Update package lists
- Install required dependencies (Python, FFmpeg, SQLite, yt-dlp)
- Set up Android storage access
- Create necessary directories
- Initialize the database
- Create sample configuration files

## 🎯 Quick Start

### 1. Add Your Playlists
Edit `$PLAYLIST_FILE` and add your YouTube Music playlist URLs or IDs:
```
# Examples:
https://music.youtube.com/playlist?list=OLAK5uy_...
OLAK5uy_... (just the playlist ID)
```

### 2. Launch the Manager
```bash
./menu
```

### 3. Fetch Metadata
Choose option **1** to fetch and update playlist metadata.

### 4. Download Tracks
Choose option **3** to download tracks with metadata tagging.

## 📁 File Structure

```
youtube-playlist-manager-android/
├── menu                    # Main menu interface
├── download.sh            # Download tracks
├── get-metadata.sh        # Fetch playlist metadata
├── normalize.sh           # Normalize artist/album metadata
├── scan-metadata.sh       # View track metadata
├── reset-album.sh         # Reset album downloads
├── database-functions.sh  # Database management
├── install-android.sh     # Installation script
├── lib/                   # Library functions
│   ├── config.sh         # Configuration
│   ├── functions.sh      # Shared functions
│   └── *.sh             # Other library files
├── tools/                # Utility scripts
│   ├── create-backup.sh  # Backup creation
│   └── *.sh             # Other tools
├── ytdata/               # Data directory
│   ├── metadata.db      # SQLite database
│   ├── plist.txt        # Playlist URLs
│   └── logfile          # Log file
└── backups/              # Backup files
```

## 🎵 Music Storage

Music files are saved to:
```
$HOME/storage/shared/Music/YouTube-Playlist-Manager/
├── Artist Name/
│   └── Album Name/
│       ├── 01 - Track Title.opus
│       ├── 02 - Track Title.opus
│       └── folder.jpg
```

## 🗄️ Database Functions

Access database management through the main menu (option 6):

- **Backup Database** - Create timestamped backups
- **Restore Database** - Restore from backup
- **Backup plist.txt** - Backup playlist URLs
- **Restore plist.txt** - Restore playlist URLs
- **Edit plist.txt** - Edit playlist file
- **Clean Database** - Remove corrupted entries
- **Show Statistics** - View database stats

## 🛠️ Troubleshooting

### Storage Permission Issues
If you can't access storage:
```bash
termux-setup-storage
```

### yt-dlp Issues
Update yt-dlp if downloads fail:
```bash
pip install --upgrade yt-dlp
```

### Database Issues
Reset the database if needed:
```bash
rm ytdata/metadata.db
./menu  # This will recreate the database
```

## 🔧 Advanced Usage

### Manual Installation
If the installation script fails, install dependencies manually:
```bash
pkg update -y
pkg install -y python ffmpeg sqlite wget curl git
pip install --upgrade yt-dlp
termux-setup-storage
```

### Custom Download Directory
Edit `lib/config.sh` to change the download directory:
```bash
DOWNLOAD_DIR="/path/to/your/music/directory"
```

### Backup Management
Create backups manually:
```bash
./tools/create-backup.sh
```

## 📱 Android-Specific Features

- **Storage Integration** - Uses Android's shared storage
- **Termux Optimization** - Optimized for Termux environment
- **Mobile-Friendly** - Touch-friendly interface
- **Battery Efficient** - Optimized for mobile devices

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on Android/Termux
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **yt-dlp** - YouTube download functionality
- **FFmpeg** - Audio processing and tagging
- **SQLite** - Database management
- **Termux** - Android terminal environment

---

**Enjoy your music on Android! 🎵📱** 