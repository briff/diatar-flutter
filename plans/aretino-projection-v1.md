# Plan — Aretino chant projection, V1

Status: proposed (second revision — one renderer, rendered on the display side)
Scope: `Diatar/`, `DiaVetito/` and `packages/diatar_common/`; every platform both
apps ship to, including web and tvOS
Prior art: `~/prog/flutter-aretino-test` (integration spike, May 2026; re-tested
September 2026 — `flutter_js` runs the library with no canvas present)

## Goal

A Gregorian chant written in
[Aretino](https://github.com/aretino-chant/aretino-chant) notation is a slide in
a song book, and it renders as real notation — reflowed to the screen it is
shown on — everywhere Diatár draws a slide: the sender's preview, the desktop
projector window, DiaVetítő on desktop, Android TV and tvOS, and the web
receiver someone opened from the QR code on their phone.

## How this differs from the first draft

The first draft rasterized the score on the sender and shipped it as a `pic`
packet, hidden on web. Three requirements killed that:

1. **Lyrics are the point.** Diatár exists to put text on a wall, so a chant
   slide has to reflow and re-break to its target, not arrive as a fixed
   bitmap. Reflow moves from "non-goal" to the defining requirement.
2. **Web parity is required.** The relay QR code
   (`settings_sheet.dart:1250`, `web_diavetito_url.dart`) hands out a URL that
   opens the projection in a browser — often a phone in portrait. One
   pre-rendered raster cannot serve that and a 16:9 projector at once.
3. **It is a dia type, not an imported file.** Aretino slides live in DTX books
   like everything else (a new `aretino.dtx` collection to start with), so the
   content already travels as verse text inside the existing `text` record.

Together: **the score is rendered by whoever displays it, from the source text,
at the size it is displayed at** (Decision 1).

An intermediate revision proposed porting the renderer to Dart. Rejected —
**we are not maintaining a second rendering engine.** The upstream library
is the renderer, on every platform (Decision 2).

## The format

A verse is an Aretino score when its first body line starts with `\?A`. Every
line in a DTX body starts with a space, which the parser strips
(`dtx_parser.dart:132`), so nothing about the file format changes. Sample —
`aretino.dtx` in the repo root:

```
>1
/1
#EF5F32DF
 \?A(g2) g a b a , ab a g e_d_ | g ab ag g. ||
 w: Al-le-lu-ja, al-le-lu-ja, al-le-lu-ja.
```

Consequences worth stating up front:

- `DtxParser` needs **no change** to carry this. What it needs is a flag:
  `DtxVerse.isAretino`, plus a lyric-extraction helper, because several places
  treat verse lines as human text and would otherwise show or index
  `\?A(g2) g a b a`:
  - search (`song_search_service.dart:84,162` — `removeEscapeSequences` strips
    `\K`/`\G` style codes, it does not know about `w:` lines),
  - verse lists and slide previews in the sender,
  - the `title`/`scholaLine` fields of the `text` record.
- The marker is chosen so the rest of the line is Aretino source verbatim, and
  continuation lines (`w:`, further staff lines) need no marker of their own.
  The verse ends where the verse ends.
- One verse is one chant fragment. Making it fit a given screen is the
  renderer's business (Decision 5), not the book's.
- Lyric extraction is the only Aretino parsing Dart ever does. It reads `w:`
  lines and strips syllable hyphens — a dozen lines, not a parser.

## Non-goals for V1

- Editing Aretino source inside Diatár. Scores are authored elsewhere (the
  Aretino web editor, the VS Code extension, `gabc2aretino`) and reach Diatár
  as DTX books.
- Attaching scores to existing song-book verses by dia-id via a DTZ-style
  sidecar. V1 is a whole new collection instead; the sidecar route is the step
  after (see "Where this goes after V1").
- Transposition UI, even though `transposeSource()` exists in the library.
- Importing a loose `.aretino` file as a custom song-order entry. Small once
  the render service exists, but not what V1 is for.
- A Dart renderer. Explicitly rejected, not deferred — see Decision 2.

## Decisions

### 1. The score is rendered where it is displayed

An Aretino verse travels as ordinary verse text inside a `RecTypes.text`
record. Every side that draws a slide renders the score itself, at its own
canvas size, choosing its own line breaks.

This is the only design that satisfies reflow and web parity at once, and it
matches what the codebase already does for DTX kotta: `_buildKottaRows`
(`projector_painter.dart`) breaks a kotta line into rows against the available
width and font size, and the receiver, the sender preview and the desktop
projector window all run that same code.

**Consequence: no protocol change and no new record type** — but DiaVetítő does
need a release, because an old receiver has no idea what `\?A` means
(Decision 7).

### 2. One renderer: `@aretino-chant/core`, running on every platform

The library is the renderer. Diatár embeds it and calls it; nobody
reimplements chant layout in Dart. What differs per platform is only which
JavaScript engine hosts it:

| Platform | Engine | How |
|----------|--------|-----|
| Android, Android TV | QuickJS | `flutter_js`, dart:ffi |
| Windows, Linux | QuickJS | `flutter_js`, dart:ffi |
| iOS, macOS | JavaScriptCore | `flutter_js`, dart:ffi against the JSC C API |
| **tvOS** | JavaScriptCore | `flutter_js` with a tvOS podspec — see below |
| **Web** | the browser's own | `dart:js_interop`, the bundle loaded as a script |

These are *bindings*, not renderers. The rendering logic — the thing that would
be expensive to maintain twice — exists once, upstream, and is consumed as a
checked-in bundle.

**tvOS.** The original "safe path" was a WebView, and that is the one thing
tvOS cannot do: there is no WebKit on tvOS, no `WKWebView`, no in-app browser
— fluttertv.dev declined to ship `webview_flutter` for exactly this reason. It
does not matter, because **JavaScriptCore is a public framework on tvOS**
(react-native-tvos runs on it when Hermes is off), and `flutter_js` on Apple
platforms is already dart:ffi against the JSC C API rather than a WebView or a
platform channel. So tvOS support is packaging, not engineering:

- a `tvos/flutter_js.podspec` linking `JavaScriptCore.framework`, which is what
  `DiaVetito/tvos/Podfile` already looks for per plugin;
- widening any `#if os(iOS)` to `os(iOS) || os(tvOS)` — the mechanical edit
  fluttertv.dev's `flutter-tvos plugin port` tool performs;
- checking what `Platform.operatingSystem` returns under flutter-tvos, since
  `flutter_js` selects its runtime from `Platform.isIOS` / `isMacOS`. If it
  reports `ios`, the Dart side needs no change at all.

Consumed through `dependency_overrides` in `DiaVetito/pubspec.yaml` and
`Diatar/pubspec.yaml` (which already overrides `device_info_plus`), pointing at
the patched fork; upstreamed to `abner/flutter_js` or published via
fluttertv.dev if they will take it.

**Fallback if that stalls:** bind JavaScriptCore ourselves. We need eight C
functions (`JSGlobalContextCreate`, `JSStringCreateWithUTF8CString`,
`JSEvaluateScript`, `JSValueToStringCopy`, `JSStringGetUTF8CString`, the
release calls) and **no JS→Dart callbacks at all**, because measurement is
injected as data (Decision 3). That is a ~150-line FFI file plus a framework
link — smaller than the podspec fork it replaces. Phase 0 picks between them.

**Note: no JIT on iOS/tvOS.** JavaScriptCore runs interpreted there. That is
survivable because rendering happens once per (score, size) and is cached
(Decision 6), never per frame — but Phase 0 measures it on a real Apple TV.

### 3. Flutter measures the text, on every platform including web

`measureTextWidth` (`packages/core/src/text.js`) uses a canvas when `document`
exists and otherwise falls back to a character-class width approximation. That
fallback produces visibly bad lyric spacing and is treated here as a defect,
not a degraded mode.

So Diatár pre-measures character widths with `TextPainter` against the bundled
lyric face, serialises them to JSON, injects them into the runtime, and passes
a `ctx.measureText` callback reading that map — supported API
(`ctx.measureText ?? measureTextWidth`, `lyrics.js:539`), already working in
the spike.

Two changes from the first draft's version of this decision:

- It runs **on web too**, even though the browser has a real canvas. Otherwise
  the web receiver lays the same chant out differently from the projector, and
  the sender's preview stops being a preview. One measurement source, one
  layout, everywhere.
- The callback reads an injected map, so **no JS→Dart call happens during a
  render**. That is what keeps the tvOS fallback binding trivial.

This is a Phase 1 requirement, not polish: no score is projected until
measurement goes through Flutter.

### 4. SVG in, Canvas out — lyrics drawn by Flutter, not by the SVG stack

`renderAretino` returns SVG. Drawing it is the single biggest unknown left, and
now it is unknown on *every* platform rather than just the sender.

Leading candidate, to be confirmed in Phase 0: **split the output**. Notation
shapes (paths, staff lines, glyphs) go through `flutter_svg`, which is pure
Dart and works on tvOS and web alike; `<text>` nodes are pulled out and drawn
with `TextPainter`, using the same font and the same metrics we injected in
Decision 3. That guarantees what flutter_svg's own text path cannot: that the
lyrics land exactly where the layout engine was told they would.

Alternatives Phase 0 evaluates, cheapest first: plain `flutter_svg` for the
whole document if its text rendering matches; the abc2svg-style
post-processing the spike already wrote (`_postProcessAbcSvg`: CSS class
inlining, multi-position `<text>` expansion); a small SVG→`Canvas` walker for
the narrow element subset the library actually emits.

Whatever wins, the result is cached as a `ui.Picture`, not a PNG — resolution
independence is the point.

### 5. An oversized score obeys the receiver's existing fit rules — no paging

DiaVetítő has no notion of pages, and V1 does not add one. A slide that does
not fit is already handled by two mechanisms, chosen by a receiver-local
setting (`scrollableProjection` / "Görgethető vetítés",
`DiaVetito/lib/src/ui/settings_sheet.dart:1233`, default off):

- **Fit (default).** Canvas = viewport, and `_resolveAutoSize`
  (`projector_painter.dart:865`) shrinks the font until the content fits 95 % of
  the height, floor `_minAutoFontSize = 8.0`. Below that it stops shrinking and
  the overflow is clipped.
- **Scroll.** The canvas grows to the measured required height
  (`_scheduleHeightRefresh` / `_estimateCanvasHeight`,
  `DiaVetito/lib/src/ui/home_page.dart:312`) and sits in a
  `SingleChildScrollView` at full font size.

Note that the receiver overwrites the sender's `autoResize` flag with its own
setting (`projection_controller.dart:278`). Fit-versus-scroll belongs to
whoever is watching, not to the operator — which is exactly what the QR-code
case needs, since the phone viewer is not the person running the projector.

An Aretino slide therefore does this: render at the receiver's width, take the
staff systems `splitRowSVGs` returns, stack them, and let the two existing
modes apply unchanged. `splitRowSVGs` is what makes it work — a staff system is
the reflow unit, the way a wrapped line is for text. A chant then behaves like
a long verse does today on every receiver, with **no protocol thinking and no
page count for two differently sized receivers to disagree about**.

V1 wires the Aretino path into `_resolveAutoSize` the straightforward way: the
loop calls the render service, and the render cache (Decision 6) absorbs the
repeats. `_resolveAutoSize` can iterate a lot, and for a score each miss is a
JS render rather than a `TextPainter` measure, so this is a plausible place to
need work later — but only measurement decides that, and there is nothing to
measure until the thing renders. Instrument the render count; do not
pre-optimise it.

Paging — one screenful at a time, advanced with next/previous — stays out of
V1. If real chants turn out to be too long for fit-or-scroll, it is a
receiver-local addition later, and *then* it is a genuine protocol question.

### 6. Rendering is a preparation step, not part of `paint()`

`CustomPainter.paint` is synchronous; booting a JS runtime and rendering is
not. So an Aretino slide is *prepared* when it arrives, and painted from cache
afterwards. Precedent: `KottaAssets.ensureLoaded()` is awaited at startup in
`Diatar/lib/src/app.dart:55`, `desktop_projector_window.dart:52` and
`DiaVetito/lib/src/app.dart:36`.

- One long-lived runtime per app, booted lazily at startup alongside
  `KottaAssets`; engine boot is the expensive part, not the render.
- `AretinoRenderCache` keyed by (source hash, width, height, font size, colors),
  holding `ui.Picture`s. A resize invalidates and re-renders — that is reflow.
- While a slide is preparing, the painter draws the extracted lyrics as plain
  text. A projector never shows an empty screen waiting for JavaScript.

### 7. An old receiver gets the lyrics, not the neumes

There is no version handshake in the protocol — a receiver answers `askSize`
with `scrSize` and nothing else — so the sender cannot detect an old
DiaVetítő. An old receiver handed a `\?A…` line renders it as literal text:
readable garbage, not a crash, but not projectable.

V1 ships a sender setting, **"Aretino küldése kottával / csak szöveggel"**
(default: notation). With the fallback on, the sender sends the extracted lyric
line as a plain text slide — no notation, correct words, works on every
receiver ever shipped including the Delphi ones. The operator owns the
projector machine and knows what runs on it; this is set once.

Phase 0 confirms what an old DiaVetítő actually does with a `\?A` line (its
escape parser may swallow or mangle it); the default flips to lyrics-only if
the answer is worse than "prints it".

### 8. Bundle the JS, do not vendor the source

`@aretino-chant/core` is an ES module; esbuild bundles it to a single IIFE with
a global name. The built `assets/aretino.js` is checked in — Diatár's build has
no Node step — and the bundling command lives in a small `tools/package.json`,
as the spike does. The lyric font ships next to it.

Both apps carry both assets, the way `assets/kotta/` is already duplicated in
`Diatar/pubspec.yaml:94` and `DiaVetito/pubspec.yaml:83` and loaded from the
root bundle. ~80 KB of JS plus a font is negligible beside what is already
there.

**The spike's bundle was built from core `0.1.1`; current is `0.26.1`.** Step
zero is re-bundling against current and re-checking that it still renders. Pin
the exact version; the checked-in bundle is the real dependency.

## Data flow

```
aretino.dtx  → DtxParser → DtxVerse(isAretino: true, lines: [...])
   sender: song order, search over extracted lyrics, preview
   → encodeTextRecord(title, lines)      ← unchanged, existing record type
   → TCP / MQTT / Cast / desktop window / web relay

wherever a slide is drawn (sender preview, desktop projector window, DiaVetítő
native, DiaVetítő web):
   lines → AretinoRenderService.prepare(source, size, style)
             TextPainter character widths → JSON → runtime      (Decision 3)
             Aretino.renderAretino(source, {measureText, width, …}) → SVG
             splitRowSVGs(svg) → staff systems, stacked for this screen
             SVG → ui.Picture, lyrics via TextPainter           (Decision 4)
           → AretinoRenderCache
   ProjectorPainter.paint → canvas.drawPicture(cached)          (Decision 6)
```

Reflow is not a feature added on top; it is what happens because the render
runs on the display side with the display's own width.

## Work breakdown

### Phase 0 — Prove the engine matrix and the drawing path (3–4 days)

Riskiest facts first, no product code. Output is a note in `plans/` plus
throwaway spikes.

- `tools/` with `@aretino-chant/core` pinned at `0.26.x` and esbuild;
  `npm run bundle` → `assets/aretino.js`. Re-check that the current version
  still renders what the spike's `0.1.1` did.
- **tvOS, the gating question.** Build `flutter_js` for tvOS: add the podspec,
  widen the platform conditionals, check `Platform.operatingSystem` under
  flutter-tvos, run the bundle on a real Apple TV. If it fights back, spike the
  ~150-line direct JSC binding instead and compare. **Neither working is the
  one outcome that reopens Decision 2.**
- **Web.** The same bundle through `dart:js_interop`, same injected widths,
  byte-identical SVG to the native path for one fixture. Cross-engine identity
  is the assertion.
- **Drawing.** Decide Decision 4 by trying the candidates on real output at
  several sizes: flutter_svg whole-document, split text, post-processing,
  hand-written walker.
- **Performance.** Engine boot and one render, measured on an Apple TV (no
  JIT), a low-end Android TV box and a phone browser. Budget: boot amortised at
  startup, a slide prepared well inside the gap between pressing next and
  expecting the screen to change.
- Old DiaVetítő versus a `\?A` text slide (Decision 7).
- Catalogue the notation subset the Hungarian material actually uses, so later
  phases have fixtures that mean something.

### Phase 1 — Render service (`packages/diatar_common`)

- `lib/services/aretino/aretino_render_service.dart` — the public API:
  `Future<AretinoRendering> render(String source, {required Size target,
  required AretinoStyle style})`, returning the staff systems as `ui.Picture`s.
- `aretino_render_service_native.dart` — `flutter_js`, one lazily booted
  long-lived runtime, the Decision 3 width injection, `splitRowSVGs` row splitting.
- `aretino_render_service_web.dart` — `dart:js_interop`, same bundle, same
  injection.
- `aretino_render_service_stub.dart` — so every target compiles.
- `aretino_svg_painter.dart` — whatever Phase 0 chose for Decision 4.
- `AretinoRenderCache` and the startup hook next to `KottaAssets.ensureLoaded`.
- Assets in both apps' `assets/` and `pubspec.yaml`, plus the `dependency_overrides`
  entries for the tvOS-capable `flutter_js`.
- Tests: committed `.aretino` fixtures render to non-trivial pictures; row
  count matches expectations at a given size; **rendering with and without
  injected widths must differ** (proves Decision 3 is live); native and web
  produce the same SVG for the same input.

### Phase 2 — DTX integration

- `DtxVerse.isAretino` and `aretinoLyrics` in `dtx_models.dart`; `DtxParser`
  sets the flag from the `\?A` marker.
- Lyric extraction: `w:` lines, hyphens removed, in a small tested class.
- `song_search_service.dart` indexes and snippets lyrics, not source.
- Verse lists, slide previews and the `text` record's title/schola fields use
  lyrics.
- Tests: detection, extraction, search hits on lyric words and not on neume
  letters, and a whole-book parse of `aretino.dtx`.

### Phase 3 — Painting and fitting

- Hook into `projector_painter.dart`: an Aretino verse draws from the cache,
  honouring the `state` record's `txtColor`, `bkColor`, `fontSize`,
  `inverzKotta`, borders and `hideTitle`.
- Lyrics-as-plain-text while a slide is preparing (Decision 6).
- **Fitting (Decision 5).** Staff systems from `splitRowSVGs` stack like
  wrapped text lines, so both existing receiver modes work on them: the
  auto-size path shrinks the staff until the stack fits, the scroll path grows
  the canvas and reports its height through `_estimateCanvasHeight`.
- Auto-size drives the render service through the cache, with a render counter
  behind it so the cost can be measured once there is something to measure.
  Optimisation is a later step, on evidence.
- Tests: golden images at 16:9, 4:3 and phone portrait; a reflow test asserting
  the same score produces a different row breakdown at two widths; a resize
  test asserting cache invalidation.

### Phase 4 — Sender and receiver

- Sender: projecting an Aretino verse sends the source text unchanged — mostly
  "do nothing special", which is the point of Decision 1. Preview renders for
  free, since the preview is `ProjectorPainter`.
- Sender: the Decision 7 fallback setting in `settings_sheet.dart`, conversion
  in a tested class under `src/core/`.
- Receiver: DiaVetítő picks the renderer up from `diatar_common`; the work is
  assets, the tvOS override, and verification on Linux/Windows/macOS desktop,
  Android, Android TV, tvOS and web — including phone-portrait sizes.
- ARB keys in `app_hu.arb` first, mirrored to `app_en.arb`, per app.

### Phase 5 — Content and ship

- `aretino.dtx` as a real downloadable collection on the server, with dia-ids.
- `docs/` page in Hungarian, added to `mkdocs.yml` nav: what an Aretino slide
  is, that the receiver must be updated, what the fallback setting does.
- Version bump in **both** pubspecs, release notes in
  `release-notes/Diatar/hu/` and `release-notes/DiaVetito/hu/`.

## Testing

- Unit: render service against committed fixtures — pictures produced, row
  counts, injected measurement demonstrably in effect.
- Cross-engine: native and web produce identical SVG for the same fixture.
- Unit: `isAretino` detection, lyric extraction, search behaviour, fallback
  conversion.
- Golden: rendered scores at several aspect ratios; reflow and resize tests.
- Manual: sender plus receiver on `127.0.0.1` (see DEVELOPMENT.md); the same
  chant in a browser via the relay QR on a phone in portrait; an unupdated
  DiaVetítő with the fallback on and off; an Apple TV and an Android TV box for
  timing.
- Manual: the same score side by side with the Aretino web editor. With the
  same library and the same measurements, they should differ only in where the
  lines break.

## Risks

| Risk | Mitigation |
|------|------------|
| `flutter_js` cannot be made to build for tvOS | Phase 0 gates on it. Fallback is a direct JSC FFI binding (~150 lines, no callbacks needed). Both failing is the only thing that reopens Decision 2. |
| SVG cannot be drawn faithfully on every platform | Phase 0 decides Decision 4 with four candidates ranked by cost; lyrics drawn by `TextPainter` removes the worst of it by construction. |
| JSC without JIT is too slow on an Apple TV | Measured in Phase 0. One long-lived runtime, prepare-then-paint, `ui.Picture` cache; if it is still slow, prepare the next slide ahead of time — the song order is known. |
| The auto-size fit loop turns into many JS renders | The render cache absorbs the repeats; a render counter makes the real cost measurable. Optimised later if the numbers say so, not designed around now. |
| A chant is illegible on a phone even after fitting | It shrinks to the same 8 px floor everything else does, and the viewer can switch to scroll mode. If real material proves this insufficient, paging becomes a V2 item — deliberately not pre-solved. |
| Upstream library churn (0.1.1 → 0.26.1 during the spike's lifetime) | Exact version pinned in `tools/package.json`; the checked-in bundle is the real dependency; fixture goldens catch a bad re-bundle. |
| A forked `flutter_js` becomes ours to maintain | The fork is a podspec and a platform conditional. Upstream it, or fall back to the direct binding, which has no fork at all. |
| Old receivers in the field | Decision 7's lyric-only fallback. A genuine degraded mode, not a crash. |

## Where this goes after V1

**Scores attached to song-book verses.** Mirror the DTZ machinery
(`dtz_library_service.dart`, `dtz_download_service.dart`,
`dtz_user_import_service.dart`) with a sidecar mapping dia-id → Aretino source,
so an existing chant in an existing book renders as notation instead of as a
kotta photograph — without reissuing the book.

**Loose `.aretino` import** as a custom song-order entry, for a score the
operator was handed for one occasion.

**Transposition**, via `transposeSource()`, which the embedded library already
carries.

## References

- No WebKit on tvOS: [openradar 22738023](https://github.com/lionheart/openradar-mirror/issues/6085),
  and fluttertv.dev's own note on declining `webview_flutter`
  ([fluttertv/plugins](https://github.com/fluttertv/plugins)).
- JavaScriptCore is public on tvOS and used by react-native-tvos:
  [React Native JavaScript environment](https://reactnative.dev/docs/javascript-environment),
  [@react-native-community/javascriptcore](https://www.npmjs.com/package/@react-native-community/javascriptcore).
- `flutter_js` engine-per-platform and dart:ffi JSC bindings:
  [pub.dev/packages/flutter_js](https://pub.dev/packages/flutter_js),
  [abner/flutter_js](https://github.com/abner/flutter_js),
  [xuelongqy/flutter_jscore](https://github.com/xuelongqy/flutter_jscore).
- tvOS plugin porting practice: [fluttertv/plugins](https://github.com/fluttertv/plugins).
