# ☀️ Noon

**Automated Color Accuracy for Creative Professionals** • *Gestion intelligente de la colorimétrie pour les créatifs*

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS%2014.0+-black.svg?logo=apple)](https://www.apple.com/macos/)
[![Swift: 5.10](https://img.shields.io/badge/Swift-5.10-orange.svg?logo=swift)](https://swift.org)

Noon is a premium macOS Menu Bar utility designed for photographers, colorists, and designers. It ensures a 100% color-accurate environment by dynamically managing **True Tone** and **Night Shift** based on the applications you are currently using.

---

## 🚀 Features | Fonctionnalités

### 🎯 Intelligent Monitoring
Automatically detects when professional tools (Photoshop, Lightroom, DaVinci Resolve, etc.) come to the foreground and disables display tinting instantly.
*Détection automatique des outils pro et désactivation instantanée des filtres de couleur.*

### 🛠 CoreBrightness Integration
Uses Private Apple APIs for hardware-level control of display color temperature.
*Contrôle matériel via les APIs privées de macOS pour une précision maximale.*

### ⏱ Flexible Reactivation
- **Immediate**: Restores settings as soon as you switch apps.
- **On Quit**: Keeps the screen neutral until creative apps are closed.
- **Timer**: Customizable delay (30s – 30 min) before restoring.
*Modes de réactivation : immédiat, à la fermeture, ou via un délai personnalisable.*

### 🎨 Total Personalization
- **Dynamic Menu Bar**: Icons change color based on the current state (Normal, Creative, Error).
- **Glassmorphism UI**: A native, modern interface built with SwiftUI.
- **Accent Colors**: Customize the app's accent color to match your workspace.
*Interface moderne en verre dépoli et personnalisation complète des couleurs des icônes.*

---

## 📦 Installation

### 1. Homebrew (Recommended)
Install Noon via Homebrew Cask:
```bash
brew install --cask sunazur/tap/noon
```
*(Note: If the tap is not yet public, you can install the local formula provided in this repo.)*

### 2. Manual Installation
1. Download the latest `.dmg` from the [Releases](https://github.com/Damien-Esilv/Noon/releases) page.
2. Drag **Noon** to your `Applications` folder.
3. Launch the app and grant necessary permissions.

---

## 📖 Usage | Utilisation

1. **Add Apps**: Open Settings (☀️ > Settings) and add your professional applications (e.g., Photoshop, Final Cut Pro).
2. **Choose Features**: Select whether you want to manage True Tone, Night Shift, or both.
3. **Set Mode**: Choose how Noon should react when you leave a professional app (Immediate vs. Timer).
4. **Customize**: Go to the **Appearance** tab to change icon styles and colors.

---

## 🛠 Developer Setup

### Prerequisites
- **Xcode 15.4+** 
- **macOS 14.0+** (Sonoma/Sequoia)
- A Mac with True Tone support (for True Tone features).

### Build Instructions
1. Clone the repository.
2. Open `Noon.xcodeproj`.
3. Select the **Noon** target and your Mac as the destination.
4. Build and Run (`Cmd+R`).

*Important: This app uses Private Frameworks (`CoreBrightness`). It is not suitable for App Store distribution.*

---

## 📄 License & Copyright

**Copyright © 2026 Sunazur. All rights reserved.**

Licensed under the **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)**.

- **Attribution**: You must give appropriate credit.
- **Non-Commercial**: You may **not** use the material for commercial purposes.
- **ShareAlike**: If you remix, transform, or build upon the material, you must distribute your contributions under the same license.

For full details, see the [LICENSE](LICENSE) file.

---

## 👋 Support
Created with ❤️ by **Sunazur**. If you find this tool useful, feel free to contribute or share it with other creative professionals.
