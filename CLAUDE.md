# Diatár — contributor and agent guide

Diatár is a church song projection system: a **sender** app where the operator
builds the song order, and a **receiver** app running on the machine wired to
the projector. Both are Flutter apps built from this repository and released in
lockstep under a single version number.

## Repository layout

| Path | What it is |
|------|------------|
| `Diatar/` | Sender app — library, search, song order editing, all transports. The large app (~46k lines of Dart). |
| `DiaVetito/` | Receiver app — TCP/MQTT listener plus the projection surface. Deliberately small. Also ships to Android TV, tvOS and web. |
| `packages/diatar_common/` | Everything both apps must agree on: DTX parsing, the wire protocol, MQTT, and the projection renderer. |
| `packages/diatar_speech/` | Speech input, used by the sender only. |
| `docs/` | User documentation (Hungarian), published to web.diatar.eu via mkdocs. |
| `release-notes/<App>/hu/` | Store release notes. |
| `.github/workflows/` | CI: ARB key parity, store/Flatpak/web deploy. |

Setup, run targets and everyday commands: **[DEVELOPMENT.md](DEVELOPMENT.md)**.
Release and store deployment: **[DEPLOYMENT.md](DEPLOYMENT.md)**.

## The two rules that are easy to get wrong

### 1. Every user-facing string is a localization key

Mandatory, and enforced in CI by `.github/workflows/l10n-key-parity.yml`.

- No string literals in widgets, controllers, services or view models. Use
  `AppLocalizations` accessors (`l10n.someKey`). Test-only assertion messages
  are exempt.
- Edit only the ARB sources: `Diatar/lib/l10n/app_hu.arb`,
  `Diatar/lib/l10n/app_en.arb`, and the same pair under `DiaVetito/lib/l10n/`.
- **Hungarian is the template language** (`l10n.yaml` →
  `template-arb-file: app_hu.arb`). Add the key to `app_hu.arb` first, then
  mirror it into `app_en.arb` of the *same* app. A key missing from either
  file fails CI.
- `lib/l10n/generated/**` is gitignored and written by `flutter pub get` /
  `flutter gen-l10n`. Never hand-edit it and never commit it.
- Adding a screen, dialog, button or title means adding its keys first, then
  referencing them.

### 2. The sender and the receiver are versioned together but deployed apart

Receivers in the field are updated by whoever owns that projector machine, and
some run on Android TV boxes or tvOS that update late or never. A sender must
keep working against an older receiver.

The wire format lives in `packages/diatar_common/lib/models/`:
`records.dart` holds the record types (`state`, `scrSize`, `pic`, `blank`,
`text`, `askSize`, `idle`, `camera`) and the binary layouts;
`projection_packet.dart` frames them (4-byte magic `DA 69 70 4A`, type byte,
little-endian length, body). The format is inherited from the original Delphi
Diatár, which is why it is byte-oriented and uses Pascal strings.

So, when designing a feature that spans both apps:

- Reusing an existing record type costs nothing and reaches every receiver.
  Anything that can be expressed as a `pic` or `text` slide should be.
- A new record type or a changed body layout needs a compatibility story:
  older receivers must not break on it, and the sender must degrade when the
  receiver cannot handle it.
- Renderer changes in `diatar_common/lib/ui/projector_painter.dart` run on
  *both* sides, and the two sides may be on different builds — the sender's
  preview and the receiver's output can disagree until both update.

## Architecture notes

**Sender.** `main.dart` → `src/app.dart` → `src/ui/home_page.dart`, with
`src/controllers/diatar_main_controller.dart` holding application state.
Those two files plus `src/ui/settings_sheet.dart` and
`src/ui/custom_order_editor_sheet.dart` are each several thousand lines and
hold most of the behaviour. Do not add to them by default: pure business rules
belong in small, testable classes under `src/core/**` (see
`core/custom_order/`, `core/navigation/`, `core/dia/` for the pattern), and I/O
belongs in `src/services/**`.

**Transports.** The sender can project over TCP (`tcp_sender_service.dart`),
MQTT (`mqtt_sender_service.dart`), Google Cast, or a second desktop window
(`desktop_projector_window.dart` via `desktop_projector_bridge.dart`).
`sender_transport_coordinator.dart` picks between them; the desktop projector
window renders with the same `ProjectorPainter` the receiver uses, so it is a
faithful preview.

**Content formats.** DTX song books are parsed by
`diatar_common/lib/services/dtx_parser.dart`. DTZ archives carry score and
chord photographs. Inline musical notation in DTX text is drawn natively by
`ProjectorPainter` using the bitmap glyphs in `Diatar/assets/kotta/`
(`diatar_common/lib/ui/kotta_assets.dart`), and chords by
`diatar_common/lib/ui/chord_renderer.dart`. `.dia` files are the legacy song
order format, handled under `src/core/dia/`.

**Platform splits.** Web-incompatible code is separated with the
`*_stub.dart` / `*_web.dart` / `*_native.dart` conditional-import convention
(see `mqtt_client_factory*.dart`, `browser_window_close*.dart`). Keep it —
DiaVetítő ships a web build, so `dart:io` and FFI-backed packages cannot be
imported unconditionally from shared code.

## Conventions

- Tests live in `<app>/test/` and run without a device; the full suite takes
  seconds. New business logic in `src/core/**` or `src/services/**` should come
  with a test. Run `flutter test` and `flutter analyze` in each package you
  touched before proposing a change.
- User documentation in `docs/` is Hungarian, as are release notes and UI
  strings; code, comments and these guides are English.
- A shipped feature also means: bump `version: X.Y.Z+N` in **both**
  `Diatar/pubspec.yaml` and `DiaVetito/pubspec.yaml`, add a line to
  `release-notes/<App>/hu/release_notes.txt`, and update `docs/` if the change
  is visible to users.
- `HIDDEN.md` lists features currently commented out in `home_page.dart`.
  Check it before concluding something is unimplemented.
