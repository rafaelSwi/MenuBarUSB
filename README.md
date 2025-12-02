# MenuBarUSB

A very simple and lightweight app that shows your USB connections in the macOS menu bar.

```bash
brew tap rafaelswi/menubarusb
brew install --cask menubarusb
```

<img width="797" height="585" alt="Screenshot 2025-08-31 at 22 35 10 (2)" src="https://github.com/user-attachments/assets/e68bc061-5385-40d2-8092-1874bca83a1d" />

## Features

### Customization
With MenuBarUSB, you can make your USB list your own.

<img width="1075" height="886" alt="full_image" src="https://github.com/user-attachments/assets/94651ef4-f0b4-4a55-9389-2e37e267b376" />

## Notifications

#### Recommended settings for macOS 26 or higher
<img width="477" height="410" alt="Screenshot 2025-09-26 at 10 36 46" src="https://github.com/user-attachments/assets/5d2476b9-cc1e-4b20-bf6a-005b1df58f1c" />

#### Recommended settings for macOS 15 or lower
<img width="478" height="425" alt="settings_notif" src="https://github.com/user-attachments/assets/f83a7260-8d05-45bc-8d70-b3631f239c97" />

## Monitoring
Keep track of your devices’ connection status

<img width="608" height="665" alt="PRINT" src="https://github.com/user-attachments/assets/87799c1b-acd8-458d-a86a-fcade473b617" />

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
This warning appears because the developer don't have a paid Apple account. To open it, go to Settings > Privacy & Security > (scroll down) > Open Anyway.

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
