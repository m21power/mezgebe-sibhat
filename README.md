# Mezgebe Sibhat (mezgebe_sibhat)

Treasury of Ethiopian Orthodox Tewahedo Church Teachings — a Flutter mobile app
that collects, plays, and preserves liturgical chants, hymns, and related
materials for study and worship.

## About

This application is dedicated to every soul who desires to learn the sacred teachings of the Ethiopian Orthodox Tewahedo Church, yet has not had the opportunity to do so in traditional settings. Whether due to distance, time, or circumstance, this digital treasury brings centuries of spiritual wisdom, preserved through chant, scripture, and oral tradition, directly to your fingertips.

First and foremost, all glory and thanksgiving belong to God Almighty, who inspired, guided, and empowered the creation of this app. It is by His grace alone that this work has come to fruition. We extend our deepest gratitude to our fathers—the monks, scholars, deacons, and faithful servants across generations—who recorded, preserved, and transmitted the sacred hymns, liturgical texts, and theological teachings of our Church. Though many of their names remain unknown to us today, their labor of love echoes through time and now reaches a global audience in digital form.

This README summarizes the project's purpose, how to build and run it, and the
main features implemented in the code (see `lib/`). The app's in-app About page
contains the same dedication and acknowledgement text for end users.

## Key Features

- Browse a hierarchical collection of hymns and liturgical items (folders and audio entries).
- Stream audio tracks and play within the app (uses `just_audio`).
- Download audio for offline playback and store metadata locally (uses Hive).
- Theme support: light and dark modes with a quick toggle in the app bar.
- Submit feedback and bug reports with optional screenshot attachments.
- Offline-first storage of catalog using Hive; dependency injection via `get_it`.
- Connectivity checks to avoid network operations when offline.

## Project Structure (high level)

- `lib/main.dart` — app entry point, sets up providers (Bloc), loads `.env` and starts app.
- `lib/dependency_injection.dart` — GetIt setup and registration of singletons/factories.
- `lib/features/songs/` — core feature folder handling data, domain, and UI for songs:
  - `data/` — repository and local models (Hive adapters, local storage)
  - `domain/` — use cases and repository interfaces
  - `presentation/` — UI pages, widgets and BLoC state management
    - `pages/home_page.dart` — main browsing UI
    - `pages/song_player_page.dart` — audio player UI
    - `pages/about_page.dart` — about text + feedback form (includes the
      dedication and acknowledgements included above)
- `lib/core/` — core utilities, network info and error handling
- `lib/theme/` — central theme data for light/dark modes

The app relies on BLoC for state management and uses several packages listed in
`pubspec.yaml` (Hive, just_audio, flutter_bloc, get_it, etc.).

## Dependencies

Primary dependencies (also available in `pubspec.yaml`):

- Flutter SDK
- flutter_bloc
- hive, hive_flutter
- just_audio
- http
- shared_preferences
- get_it
- image_picker
- connectivity_plus, internet_connection_checker
- flutter_dotenv

Always review `pubspec.yaml` for exact versions and update constraints.

## Setup & Run

Prerequisites: Flutter SDK (see https://flutter.dev).

Clone the repository and fetch dependencies:

```bash
git clone https://github.com/m21power/mezgebe-sibhat.git
cd mezgebe-sibhat
flutter pub get
```

Run the app on a connected device or emulator:

```bash
flutter run
```

Notes:

- The app uses an `.env` file for environment configuration. A sample or
  required variables should be placed at the project root and listed in
  `.env` (the file is included under `assets/` in `pubspec.yaml`).
- Hive stores local data in app storage — no additional setup required.

## Usage

- Launch the app. The home screen shows a browsable list of folders and
  audio items.
- Tap a folder to expand it or open an item to play. Audio items can be
  streamed or downloaded for offline playback.
- Use the app bar menu to open the About page or toggle theme.
- Open About → use the form to submit feedback or attach screenshots.

## Development notes

- Tests: The repository contains a placeholder `test/widget_test.dart` — add
  more unit and widget tests as features are developed.
- Code generation: Hive type adapters are registered; if you modify model
  annotations, run `flutter pub run build_runner build` to regenerate adapters.

## Contributing

Contributions are welcome. Please create issues for bugs or feature requests,
and open pull requests for fixes and improvements. Keep changes small and
focused, and include tests where possible.

## Credits & Acknowledgements

All glory to God Almighty. Deep thanks to the monks, scholars, deacons, and
faithful servants who preserved and transmitted the liturgical materials that
make this app possible.

This project was scaffolded with Flutter and uses many open-source packages —
see `pubspec.yaml` for details.

## License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.
