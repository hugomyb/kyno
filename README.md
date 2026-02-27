# Kyno (Flutter)

Kyno is a training companion focused on tracking workouts, sharing sessions with friends, and keeping momentum with streaks and reminders. This repository contains the Flutter client (mobile + web).

## Highlights
- Log workouts and review past sessions.
- Share sessions with friends and manage requests.
- Track streaks and stay consistent with reminders.
- Web build deployed to GitHub Pages.

## Tech Stack
- Flutter / Dart
- Web build via `flutter build web`
- GitHub Pages for static hosting

## Requirements
- Flutter SDK (Dart >= 3.11)
- Git

## Install
```bash
flutter pub get
```

## Run (dev)
```bash
flutter run
```

## Build (web)
```bash
flutter build web --release --base-href "/kyno/"
```

## Deploy (GitHub Pages)
```bash
./scripts/deploy_gh_pages.sh
```

## Configuration
- `BASE_HREF` is defined in `scripts/deploy_gh_pages.sh` for web routing.
- `BUILD_STAMP` is injected at build time for cache busting.

## Repository Layout
- `lib/`: Flutter app source code
- `assets/`: Fonts, sounds, and static assets
- `scripts/`: Build and deployment utilities
- `web/`: Web-specific entry points and configuration

## Backend
The app expects a Kyno API backend. Configure the API base URL in the app settings or via your environment configuration (see project config files).

## Notes
- Service worker patching for push notifications is handled by `scripts/patch_flutter_service_worker_for_push.sh`.
