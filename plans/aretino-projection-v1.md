# Plan — Aretino chant projection, V1

Status: proposed
Scope: `Diatar/` only, native platforms only (see Decision 3)
Prior art: `~/prog/flutter-aretino-test` (integration spike, May 2026)

## Goal

The operator can put a Gregorian chant score, written in
[Aretino](https://github.com/aretino-chant/aretino-chant) notation, into the
song order as a slide, and project it on every receiver that exists today.

## How this fits Diatár's content model

Diatár has two separate ways content reaches the screen, and an Aretino score
could in principle use either. V1 uses the first.

**Slides the operator inserts.** The song order is a list of
`CustomOrderEntry`. Most entries point into a song book, but an entry can also
be a self-contained slide the operator made: a custom text slide
(`customType: 'text'`) or a custom image slide (`customType: 'image'`). These
are owned by the song order, imported by the operator, and need no coordination
with anything else. **An Aretino score is a third kind of these** —
`customType: 'aretino'`.

**Content attached to song-book verses.** DTX song books are downloaded from
the server and are read-only; every verse in them has a stable *dia-id*. A DTZ
file is a sidecar that maps dia-id → kotta photo path, so that when the
operator is on a given verse, Diatár can also offer that verse's score
photograph. This is how kotta photos and per-verse audio work today.

An Aretino score *could* be distributed that way too — a sidecar mapping
dia-id → `.aretino` file, so that a chant in the song book renders as real
notation. That is a genuinely useful feature and it is where this should
eventually go, but it drags in a file format, a download service, update
handling and per-file enable/disable. **Out of scope for V1** — see "Where this
goes after V1".

## Non-goals for V1

- Editing Aretino source inside Diatár. Scores are authored elsewhere
  (the Aretino web editor, VS Code extension) and imported as `.aretino` files.
- Attaching scores to song-book verses by dia-id, and any distribution
  mechanism for scores. V1 scores are hand-imported files.
- Receiver-side rendering, reflow or resolution independence.
- The web build of Diatár — the feature is hidden there.
- A Dart port of the renderer.
- Transposition UI, even though `transposeSource()` exists in the library.

## Decisions

### 1. Render to a raster on the sender, ship it as a `pic` packet

The renderer produces SVG; Diatár rasterizes it to PNG and sends it through the
existing picture path. `RecTypes.pic` is understood by every receiver ever
shipped, including the Delphi-era ones, the Android TV and tvOS builds, and the
web receiver.

The alternative — sending Aretino source and rendering on the receiver — needs a
new record type, a DiaVetítő release, and a JS engine on platforms where there
isn't one. It buys resolution independence we do not need yet, because a chant
score fills the whole slide anyway. Rejected for V1.

**Consequence: no protocol change, no `packages/diatar_common` change, no
DiaVetítő release.** This is the main reason V1 is small.

### 2. An Aretino slide is a custom-order entry of a new `customType`

`CustomOrderEntry` (`Diatar/lib/src/models/custom_order_entry.dart`) already
carries a free-form `customType` plus a `customData` map, and
`dtx_order_store.dart` round-trips both, preserving unknown keys through
`storageExtras`/`additionalFields`. So `customType: 'aretino'` needs **no
storage format change**, and an older Diatár build opening a newer song order
preserves the entry instead of dropping it.

### 3. QuickJS on native; the feature is absent on web

The spike proved `flutter_js` (QuickJS over FFI) runs the bundled library
in-process. FFI means no web support, and Diatár does ship a web build.

Web parity is not required for V1. The render service goes behind the repo's
existing conditional-import convention (`*_native.dart` / `*_web.dart`, as
`mqtt_client_factory*.dart` does); the web implementation reports unsupported
and the UI hides the entry point. A real web implementation calling the same
bundle through `dart:js_interop` is a later, self-contained addition.

### 4. Flutter measures the text; the library's fallback is not acceptable

`measureTextWidth` in `packages/core/src/text.js` uses a canvas when `document`
exists and falls back to a character-class width approximation when it does not
— which is the QuickJS case. **That fallback produces visibly bad lyric
spacing and is treated here as a defect, not a degraded mode.**

So Diatár pre-measures character widths with `TextPainter` against the bundled
Linux Libertine O face, serialises them to JSON, injects them into the runtime,
and passes a `ctx.measureText` callback that reads from that map. This is
supported API (`ctx.measureText ?? measureTextWidth`, `lyrics.js:539`), and the
spike already has a working version of it.

This is a **Phase 1 requirement**, not a polish step: no score is projected
until measurement goes through Flutter.

### 5. Bundle the JS, do not vendor the source

`@aretino-chant/core` is an ES module; esbuild bundles it to a single IIFE with
a global name. Check the built `assets/aretino.js` into the repo (Diatár's
build has no Node step) and keep the bundling command in a small
`tools/package.json`, exactly as the spike does.

**The spike's bundle is built from core `0.1.1`; current is `0.26.1`.** Step
zero of this plan is re-bundling against current and re-checking that it still
renders — a large part of the spike's findings may be stale.

## Data flow

```
.aretino source (String)
  → AretinoRenderService                                     [QuickJS]
      inject character-width map measured by TextPainter      (Decision 4)
      Aretino.renderAretino(source, {measureText, …}) → SVG string
      splitRowSVGs(svg) → one SVG per staff system            → slide paging
  → rasterize each slide's SVG → PNG bytes                   [flutter_svg → ui.Image]
  → controller.sendPicBytes(bytes, ext: 'png')
      → _mqttSender.sendPic / _desktopProjectorBridge.sendPic / _sender.sendPic
```

The last step already exists; `sendPicFromPath`
(`diatar_main_controller.dart:5341`) does exactly this fan-out after reading a
file. V1 extracts the half of it that takes bytes.

## Work breakdown

### Phase 0 — Re-validate the spike (half a day)

- `tools/` with `@aretino-chant/core` pinned at `0.26.x`, esbuild,
  `npm run bundle` → `Diatar/assets/aretino.js`.
- Throwaway Dart test that boots `flutter_js`, evaluates the bundle, calls
  `Aretino.renderAretino` on a sample score, and asserts the output starts with
  `<svg`.
- Decide here whether `flutter_svg` renders the output acceptably, or whether
  the abc2svg-style post-processing (CSS class inlining, multi-position `<text>`
  expansion — see the spike's `_postProcessAbcSvg`) is also needed for Aretino
  output. **This is the single biggest unknown in the plan.** If flutter_svg
  cannot handle it, the fallback is rendering in a headless WebView on native
  platforms, which changes Phase 1 substantially.

### Phase 1 — Render service

New, behind interfaces, no UI:

- `Diatar/lib/src/services/aretino_render_service.dart` — the public API
  (`Future<List<Uint8List>> renderSlides(String source, {required Size target})`,
  returning one PNG per projected slide).
- `aretino_render_service_native.dart` — QuickJS implementation, lazily booting
  one long-lived runtime and reusing it; the engine boot is the expensive part.
  Includes the `TextPainter` width measurement and its injection (Decision 4),
  and `splitRowSVGs()` paging: group staff systems into screen-height slides.
- `aretino_render_service_web.dart` / `_stub.dart` — reports unsupported, so web
  builds compile.
- `Diatar/assets/aretino.js` plus the Linux Libertine O font under
  `Diatar/fonts/`, both declared in `pubspec.yaml`. The font is needed twice:
  by `TextPainter` for measurement, and by `flutter_svg` to draw the lyrics.
- Unit tests over committed `.aretino` fixtures: a non-trivial PNG comes out,
  the slide count matches the expected paging, and measured widths are actually
  reaching the renderer (a score rendered with and without injection must
  differ).

### Phase 2 — Slide model and projection

- `CustomOrderEntry` gains `isAretino` (`customType == 'aretino'`), with the
  source path in `customData`. No new fields on the class.
- Extract `sendPicBytes(Uint8List bytes, {String ext, String label})` out of
  `sendPicFromPath` in `diatar_main_controller.dart` and have both call it.
  `lastPicPath` currently assumes a file path — give the byte path its own
  status/label rather than faking one.
- Dispatch: next to `if (entry.isCustomImage)` at
  `diatar_main_controller.dart:5127`, add the Aretino branch — render, then
  `sendPicBytes`.
- A paged chant occupies consecutive slides, so the existing next/previous
  navigation walks it without special cases.
- Cache rendered PNGs keyed by (source hash, target size) so re-projecting a
  slide does not re-enter JS.

### Phase 3 — Import and order editing

- Import a `.aretino` file via `file_selector`, store it under the app's data
  directory alongside the other user content, add the entry to the order.
- Entry point in `custom_order_editor_sheet.dart`, next to the existing custom
  image and custom text actions; hidden when the render service reports
  unsupported (web).
- Preview thumbnail in the editor — `renderFirstRow()` exists in the library for
  exactly this.
- ARB keys in `app_hu.arb` first, mirrored to `app_en.arb` (see CLAUDE.md).

### Phase 4 — Ship

- Settings entry if anything needs configuring (render size, background).
- `docs/` page in Hungarian, added to `mkdocs.yml` nav.
- Version bump in both pubspecs, release note in
  `release-notes/Diatar/hu/release_notes.txt`.

## Testing

- Unit: render service against committed `.aretino` fixtures — PNG output,
  expected slide count from paging, measurement injection taking effect.
- Unit: `CustomOrderEntry` and `dtx_order_store` round-trip of an Aretino entry,
  including that an unknown `customType` survives a load/save cycle.
- Widget: the order editor shows the Aretino action on native and hides it when
  the service is unsupported.
- Manual: two Linux desktop windows (sender + receiver over `127.0.0.1`, see
  DEVELOPMENT.md), confirming the score arrives as a picture slide and that
  next/previous walks a paged chant. Compare lyric spacing against the same
  score in the Aretino web editor — they should be indistinguishable.

## Risks

| Risk | Mitigation |
|------|------------|
| `flutter_svg` cannot render the library's SVG faithfully | Phase 0 answers this before anything is built on it. Fallback: headless WebView on native, or pre-rasterizing at import time. |
| Measurement injection does not close the spacing gap | Phase 1 gates on a visual comparison against the web editor. If injected widths are still wrong, the cause is font mismatch or missing glyph coverage, not the mechanism. |
| QuickJS boot cost on a low-end Android tablet | One long-lived runtime, rendered-PNG cache, render at import rather than at project time if needed. |
| Library churn (0.1.1 → 0.26.1 during the spike's lifetime) | Pin an exact version in `tools/package.json`; the checked-in bundle is the real dependency. |
| Bundle size in the app | ~80 KB of JS plus the font; negligible next to the existing assets. |

## Where this goes after V1

**Scores attached to song-book verses.** Mirror the DTZ machinery
(`dtz_library_service.dart`, `dtz_download_service.dart`,
`dtz_user_import_service.dart`) with a sidecar that maps dia-id → `.aretino`
path, in `diatar/ARETINOs/` next to `DTXs/` and `DTZs/`. That inherits
distribution, updates and per-file enable/disable, and lets a chant in a
downloaded song book render as real notation rather than as a photograph.

**Web support.** The same bundle through `dart:js_interop`, filling in the
`_web.dart` implementation Phase 1 leaves stubbed.

**A Dart renderer.** `projector_painter.dart` already draws DTX inline notation
natively from the bitmap glyphs in `Diatar/assets/kotta/`. The architecturally
consistent end state is an Aretino renderer in Dart, running on both sender and
receiver, letting the receiver reflow a score to its own screen and removing
JavaScript from the app entirely. Large, and not justified until the raster
path has proven the feature is wanted.
