# MenuBarUSB

A very simple and lightweight app that shows your USB connections in the macOS menu bar.

```bash
brew tap rafaelswi/menubarusb
brew install --cask menubarusb
```

<img width="797" height="585" alt="Screenshot 2025-08-31 at 22 35 10 (2)" src="https://github.com/user-attachments/assets/e68bc061-5385-40d2-8092-1874bca83a1d" />

## Features

### Notifications
You can enable notifications for devices that connect and disconnect! I highly recommend setting macOS to not keep notifications in Notification Center to avoid unnecessary clutter. Below are the settings I recommend.

<img width="478" height="425" alt="settings_notif" src="https://github.com/user-attachments/assets/f83a7260-8d05-45bc-8d70-b3631f239c97" />

### Rename devices
If you think a device has a name that's too ugly or not intuitive, you can change it to something better.

### Hide devices
It's common for USB hubs to display some connected devices that don't seem to make much sense. In such cases, you can hide them.

### Heritage
MenuBarUSB doesn't automatically detect which devices are connected to which Hubs, but fortunately, you can manually configure it. Create inheritances to organize your list and make it easier to identify connected devices.

### Customization
Some customization options are available, such as making the list more compact by hiding information, forcing light/dark mode, reducing transparency, and other stuff.

<img width="693" height="513" alt="list" src="https://github.com/user-attachments/assets/6972b881-ca31-43ad-b424-161ab3d09e84" />

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
This warning appears because I don't have a paid Apple subscription. To open it, go to Settings > Privacy & Security > (scroll down) > Open Anyway.

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
