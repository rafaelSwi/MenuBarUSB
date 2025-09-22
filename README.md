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

<img width="481" height="420" alt="Screenshot 2025-09-22 at 12 02 36" src="https://github.com/user-attachments/assets/3c435444-2cb1-42a2-b899-d77b53e91fb0" />

### Rename devices
If you think a device has a name that's too ugly or not intuitive, you can change it to something better.

### Hide devices
It's common for USB hubs to display some connected devices that don't seem to make much sense. In such cases, you can hide them.

### Heritage
MenuBarUSB doesn't automatically detect which devices are connected to which Hubs, but fortunately, you can manually configure it. Create inheritances to organize your list and make it easier to identify connected devices.

### Customization
Some customization options are available, such as making the list more compact by hiding information, forcing light/dark mode, reducing transparency, and other stuff.

<img width="629" height="400" alt="Screenshot 2025-09-22 at 12 00 36" src="https://github.com/user-attachments/assets/bcaaf8da-76a0-4f82-9d9d-1db4a0d67686" />


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

<img width="372" height="358" alt="Screenshot 2025-09-21 at 22 44 30" src="https://github.com/user-attachments/assets/97ead210-a8f7-41a2-a0b0-34b98ada962d" />

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
