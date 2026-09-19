# Development setup

This document gets you from a fresh machine to a running Diatár and DiaVetítő.
For release/deploy steps see [DEPLOYMENT.md](DEPLOYMENT.md).

## 1. Flutter SDK

Both apps target the Flutter **stable** channel, Dart SDK `^3.8.1`.
Flutter 3.47.4 / Dart 3.13.3 is the current known-good combination, and is what
the committed `pubspec.lock` files were generated with. Building with a
noticeably older stable can fail inside the vendored `patches/` plugins, which
track recent embedder APIs.

### Linux (including WSL2)

Install via git clone — it is the only method that lets you switch versions
cleanly, and it avoids the snap confinement problems that break `flutter run`
under WSL:

```bash
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
exec bash
flutter --version
```

Do **not** install Flutter with `snap` on WSL, and do not keep the SDK on a
`/mnt/c` path — the NTFS bridge makes builds several times slower and breaks
file watching for hot reload.

Then let Flutter fetch its own build artifacts and check the install:

```bash
flutter precache
flutter doctor
```

`flutter doctor` will report Android toolchain / Chrome as missing unless you
set those up (see §4). That is fine if you develop against the Linux desktop
target.

### Windows / macOS

Follow the official installer at <https://docs.flutter.dev/get-started/install>,
then verify with `flutter --version` that you are on stable.

## 2. Linux desktop target under WSL2 (recommended dev target)

WSL2 on Windows 11 ships **WSLg**, which runs Linux GUI apps directly on the
Windows desktop — no X server, no VcXsrv, no `DISPLAY` fiddling. Check it is
active:

```bash
echo $WAYLAND_DISPLAY   # expect: wayland-0
ls /mnt/wslg            # expect: runtime-dir, versions.txt, ...
```

If both are empty, update WSL from an elevated PowerShell on the Windows side
(`wsl --update`, then `wsl --shutdown`) and reopen the shell.

Flutter's Linux desktop target builds native C++, so the toolchain and GTK
development headers are required. The `audioplayers_linux` plugin additionally
needs the GStreamer development headers, or CMake fails with
`The following required packages were not found: - gstreamer-1.0`. On Ubuntu:

```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-14-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

(On older Ubuntu releases use `libstdc++-12-dev`.)

Optional: `flutter_webrtc` warns at configure time if `libpulse` is missing and
disables Linux system-audio loopback capture, so
`getDisplayMedia({audio: true})` yields no audio track. Install
`libpulse-dev` if you need to test that path, then wipe `Diatar/build/linux`
so CMake re-detects it.

Confirm Flutter now sees the target, then run:

```bash
flutter devices          # expect a "Linux (desktop)" entry
cd Diatar && flutter run -d linux
```

Hot reload (`r`) and hot restart (`R`) work normally in the WSLg window.

Notes specific to this project under WSLg:

- Both apps can run at once — start DiaVetítő in one terminal
  (`cd DiaVetito && flutter run -d linux`) and Diatár in another, then point
  the sender at `127.0.0.1` to exercise the TCP projection path end to end.
- `webview_flutter` has **no Linux implementation**. Any feature built on a
  WebView must be tested on `-d chrome`, Android or Windows instead.
- Audio goes through WSLg's PulseAudio bridge and works out of the box.

## 3. Repository bootstrap

The repo is not a pub workspace; each app resolves its own dependencies and
pulls the shared code in by path:

```bash
cd Diatar    && flutter pub get
cd ../DiaVetito && flutter pub get
cd ../packages/diatar_common && flutter pub get
```

`flutter pub get` rewrites `pubspec.lock` if your Flutter version differs from
the one the lock was generated with — an older SDK silently *downgrades*
entries. Check `git status` afterwards and do not commit that churn unless you
mean to update the pinned versions. Unexpected lock churn is a reliable sign
that you are on the wrong SDK.

## 4. Other run targets

| Target | Command | Notes |
|--------|---------|-------|
| Linux desktop | `flutter run -d linux` | Needs §2. Best iteration speed. |
| Web | `flutter run -d chrome` | Needs Chrome; under WSL set `CHROME_EXECUTABLE` to the Windows binary, e.g. `/mnt/c/Program Files/Google/Chrome/Application/chrome.exe`. |
| Android | `flutter run -d <device>` | Needs the Android SDK + `adb`. Under WSL, USB devices need `usbipd-win`; easier to build the APK and install from Windows. |
| Windows/macOS/iOS | `flutter run -d windows` etc. | Build from that host OS. |

## 5. Everyday commands

```bash
# Tests (run from Diatar/, DiaVetito/, or packages/diatar_common/)
flutter test
flutter test test/song_search_test.dart          # a single file

# Static analysis
flutter analyze

# Regenerate localizations after editing an .arb file
flutter gen-l10n
```

The whole suite is fast (seconds, no device needed) and is the primary
feedback loop — prefer adding a test over launching the app.

## 6. Known rough edges

- **The first Linux build deletes a checked-in Windows binary.**
  `patches/flutter_webrtc/third_party/CMakeLists.txt` wipes
  `third_party/libwebrtc/` before extracting the platform archive, and
  `libwebrtc.dll` plus its import lib are committed inside that directory. After
  a first Linux build on a fresh checkout, check `git status` and restore them
  with `git checkout -- Diatar/patches/flutter_webrtc/third_party/libwebrtc/lib/`.
  Later builds leave them alone, because extraction is skipped once the
  directory exists.
- **A failed CMake configure poisons the build directory.** If configuring
  `linux/` fails for any reason (a missing dev package, say), CMake still
  writes a `CMakeCache.txt` with the default `CMAKE_INSTALL_PREFIX=/usr/local`.
  On the next run the cache exists, so `CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT`
  is false, `linux/CMakeLists.txt` never redirects the prefix to the build
  bundle directory, and the build dies with a misleading
  `file INSTALL cannot copy file ... to "/usr/local/diatar_app": Permission denied`.
  Fix the real error, then `flutter clean` (or `rm -rf build/linux`) before
  rebuilding.
- **Vendored patches.** `Diatar/patches/` holds forked copies of
  `flutter_webrtc`, `desktop_multi_window` and `screen_retriever_macos`, wired
  in via `dependency_overrides`. Their upstream `example/` apps have been
  deleted — they are not part of the build; do not restore them when syncing
  with upstream.
- **Hungarian is the source language.** `l10n.yaml` sets
  `template-arb-file: app_hu.arb`, so new keys are authored in `app_hu.arb`
  first and mirrored into `app_en.arb`.
- **Generated code is not committed.** `lib/l10n/generated/` and the
  `generated_plugin_registrant.*` / `generated_plugins.cmake` files under
  `linux/`, `macos/` and `windows/` are gitignored in both apps; `flutter pub
  get` writes all of them, so a fresh checkout will not analyze until you have
  run it once. The exception is `DiaVetito/tvos/`, whose registrant is written
  by the `flutter-tvos` fork that only the CI macOS runner has, so it stays
  checked in.
- **`HIDDEN.md`** lists UI features currently commented out in
  `home_page.dart`. Check it before concluding a feature is missing.
