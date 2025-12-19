# MenuBarUSB <img width="31" height="31" alt="LOGO_PRINCIPAL" src="https://github.com/user-attachments/assets/e904ea51-7044-44b2-8770-c7925aa46839" />

A very simple and lightweight app that shows your USB connections in the macOS menu bar.

```bash
brew tap rafaelswi/menubarusb
brew install --cask menubarusb
```

### Overview

<img width="797" height="585" alt="Screenshot 2025-08-31 at 22 35 10 (2)" src="https://github.com/user-attachments/assets/e68bc061-5385-40d2-8092-1874bca83a1d" />

## Features

### Customization
With MenuBarUSB, you can make your USB list your own.

<img width="1075" height="886" alt="full_image" src="https://github.com/user-attachments/assets/94651ef4-f0b4-4a55-9389-2e37e267b376" />

## Technical support
You can use MenuBarUSB as a technical support tool to analyze device activity. While MenuBarUSB includes a built-in feature to review recorded activity, [MenuBarUSB Analysis Tool](https://github.com/rafaelSwi/MenuBarUSBAnalysisTool) allows you to view exported logs from other Macs. This is particularly useful for examining logs from clients or colleagues who are experiencing issues with USB devices.

<img width="682" height="239" alt="template" src="https://github.com/user-attachments/assets/2b79e587-d12a-4b7e-99bc-47a2792a8ef6" />

## Notifications

#### Recommended settings for macOS 26 or higher
<img width="477" height="410" alt="Screenshot 2025-09-26 at 10 36 46" src="https://github.com/user-attachments/assets/5d2476b9-cc1e-4b20-bf6a-005b1df58f1c" />

#### Recommended settings for macOS 15 or lower
<img width="478" height="425" alt="settings_notif" src="https://github.com/user-attachments/assets/f83a7260-8d05-45bc-8d70-b3631f239c97" />

## Installation via Homebrew

### 1. Add the tap

```bash
brew tap rafaelswi/menubarusb
```

### 2. Install MenuBarUSB

```bash
brew install --cask menubarusb
```

### 3. "Apple could not verify MenuBarUSB" warning
To open it, go to Settings > Privacy & Security > (scroll down) > Open Anyway.

### Update

To update MenuBarUSB after a new version is released:

```bash
brew upgrade --cask menubarusb
```

### If something goes wrong

```bash
brew upgrade
brew reinstall --cask menubarusb
```

### License

This project is licensed under the terms of [MIT License](LICENSE).
