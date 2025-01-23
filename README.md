# SmartClock

A configurable smart clock application built with Flutter.

## Features

- Configurable digital clock display
- Configurable layout
- Integration with web apis:
  - Weather
  - Google Calendar
  - Trakt & TMDb
- Integration with self-hosted apis:
  - Home Assistant
  - Immich
- Alexa integration:
  - Devices
  - Timers
  - Alarms
  - Reminders
  - Now Playing
  - Sticky Notes
- Support for all platforms
- Companion mobile app

## Prerequisites

- Flutter SDK (>=3.4.3)

## Quick Start

1. Clone repository:

```sh
git clone https://github.com/smartclock-app/Clock.git
cd Clock
```

2. Install dependencies:

```sh
flutter pub get
```

3. Run application:

```sh
flutter run --release
```

## Building

- [Flutter Deployment Dcos](https://docs.flutter.dev/deployment)
- [Flutter Pi Github](https://github.com/ardera/flutter-pi) (For running on raspberry pi)

## Configuration

All of SmartClock's options are configurable through a JSON configuration file.

SmartClock will log the location of the configuration file on startup. The default locations are:

- macOS/Linux: `~/.smartclock/config.json`
- Windows: `%APPDATA%\SmartClock\config.json`

The configuration file can be edited directly (where the filesystem allows) or by using the built-in editor page, accessible by long-pressing the time, and the clock will reload automatically.

See all config options in the [Configuration Documentation](https://docs.smartclock.app).

## Android

Android devices can use the provided release APKs to install SmartClock.

This allows for easy updates in-app using the Updater widget.

_If none-Android devices enable the Updater widget, the app will not be able to update itself, but will be notified when an update is available._

## Related

- [AlexaQuery](https://github.com/smartclock-app/AlexaQuery): Alexa query library build for SmartClock based on [thorsten-gehrig/alexa-remote-control](https://github.com/thorsten-gehrig/alexa-remote-control)
- [Companion App](#) - Coming soon
- [Config Documentation](https://docs.smartclock.app)
- [Example Auth Server](https://github.com/smartclock-app/Auth) - for Trakt and Google tokens
- [LRCLIB](https://github.com/tranxuanthang/lrclib) - Library of synced song lyrics

## License

MIT License - See [LICENSE](LICENSE) for more information.
