# Flutter Terminal

A Termux-like terminal emulator for Android built with Flutter.

## Features

- Full terminal emulator using xterm.dart
- PTY (Pseudo-terminal) support via flutter_pty
- Multiple color themes (Default, Dracula, Monokai, Solarized, Nord)
- Extra keys bar (ESC, CTRL, ALT, Tab, Arrows, etc.)
- Copy/paste support
- Adjustable font size
- Keyboard shortcuts (CTRL+C, CTRL+D, CTRL+L, etc.)

## Screenshots

[Coming soon]

## Requirements

- Android 7.0 (API 24) or higher
- ARM or x86 device/emulator

## Installation

### From GitHub Releases

1. Go to [Releases](../../releases)
2. Download the appropriate APK:
   - `app-arm64-v8a-release.apk` - For modern 64-bit phones
   - `app-armeabi-v7a-release.apk` - For older 32-bit phones
   - `app-release.apk` - Universal (larger file size)
3. Enable "Install from unknown sources" in Settings
4. Install the APK

### Build from Source

```bash
# Clone the repository
git clone https://github.com/zesbe/flutter_terminal.git
cd flutter_terminal

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release
```

## Development

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # MaterialApp setup
├── features/
│   ├── terminal/            # Terminal feature
│   │   ├── presentation/    # UI components
│   │   └── data/services/   # PTY service
│   ├── bootstrap/           # Linux environment (coming soon)
│   ├── packages/            # Package manager (coming soon)
│   └── settings/            # Settings page
└── core/
    └── themes/              # Terminal color themes
```

### Dependencies

- [xterm](https://pub.dev/packages/xterm) - Terminal emulator widget
- [flutter_pty](https://pub.dev/packages/flutter_pty) - Pseudo-terminal
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) - State management

## Roadmap

- [ ] Multi-tab terminal support
- [ ] Session persistence
- [ ] Bootstrap Linux environment
- [ ] Package manager (APT-like)
- [ ] SSH client
- [ ] File manager integration

## Notes

- This app uses `targetSdkVersion 28` to allow binary execution, which means it cannot be published to Google Play Store
- Distribution is done via GitHub Releases, F-Droid, or direct APK download

## License

MIT License
