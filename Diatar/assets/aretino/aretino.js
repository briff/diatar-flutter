/* @aretino-chant/core 0.26.1 - bundled by tools/bundle.mjs, do not edit */
var Aretino = (() => {
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toCommonJS = (mod2) => __copyProps(__defProp({}, "__esModule", { value: true }), mod2);

  // entry.js
  var entry_exports = {};
  __export(entry_exports, {
    parse: () => parse,
    render: () => render
  });

  // node_modules/@aretino-chant/core/src/parser.js
  function sourceMapForText(text, srcStart) {
    return Array.from({ length: text.length }, (_, i) => srcStart + i);
  }
  function updateLyricSourceSpan(item) {
    const offsets = (item.sourceMap || []).filter(Number.isFinite);
    if (offsets.length === 0) {
      delete item.srcStart;
      delete item.srcEnd;
      return;
    }
    item.srcStart = Math.min(...offsets);
    item.srcEnd = Math.max(...offsets) + 1;
  }
  function makeLyricItem(text, srcStart) {
    return {
      type: "lyrics",
      text,
      srcStart,
      srcEnd: srcStart + text.length,
      sourceMap: sourceMapForText(text, srcStart)
    };
  }
  function appendLyricChunk(item, text, sourceMap) {
    if (!Array.isArray(item.sourceMap)) {
      item.sourceMap = Array.from({ length: item.text.length }, () => null);
    }
    item.text += text;
    item.sourceMap.push(...sourceMap);
    updateLyricSourceSpan(item);
  }
  function appendLyricContinuation(item, text, srcStart) {
    appendLyricChunk(item, " ", [null]);
    appendLyricChunk(item, text, sourceMapForText(text, srcStart));
  }
  function trimmedSourceText(text, srcStart) {
    const leading = text.match(/^\s*/)[0].length;
    const trailing = text.match(/\s*$/)[0].length;
    const end = Math.max(leading, text.length - trailing);
    return {
      text: text.slice(leading, end),
      srcStart: srcStart + leading
    };
  }
  function parseAretino(source) {
    const src = source ?? "";
    const lines = src.replace(/\r\n/g, "\n").split("\n");
    const lineStarts = [];
    let off = 0;
    for (const line of lines) {
      lineStarts.push(off);
      off += line.length + 1;
    }
    const header = {};
    const optionHeaders = [];
    let bodyStart = 0;
    let sawHeaderEnd = false;
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (/^%%\s*$/.test(line)) {
        bodyStart = i + 1;
        sawHeaderEnd = true;
        break;
      }
      const m = line.match(/^%\s*([^:]+):\s*(.*)$/);
      if (m) {
        const key = m[1].trim();
        const value = m[2].trim();
        header[key] = value;
        if (key.toLowerCase() === "option") {
          optionHeaders.push(value);
        }
        continue;
      }
      if (line.trim() === "" || line.trimStart().startsWith("%")) {
        continue;
      }
      bodyStart = i;
      break;
    }
    if (!sawHeaderEnd && Object.keys(header).length === 0) {
      bodyStart = 0;
    }
    const result = [];
    let lastWasLyrics = false;
    let implicitLyricContinuationIdx = null;
    let sectionLyricIndices = [];
    let pendingMusicContinuationLyricIndices = null;
    let pendingMusicContinuationLyricPos = 0;
    let inBlockComment = false;
    for (let li = bodyStart; li < lines.length; li++) {
      const raw = lines[li];
      const lineStart = lineStarts[li];
      if (inBlockComment) {
        const closeIdx = raw.indexOf("%]");
        if (closeIdx >= 0) {
          inBlockComment = false;
          const remainder = raw.slice(closeIdx + 2);
          if (remainder.trim()) {
            result.push({ type: "music", tokens: tokenizeMusicLine(remainder, lineStart + closeIdx + 2) });
            lastWasLyrics = false;
            implicitLyricContinuationIdx = null;
            pendingMusicContinuationLyricIndices = null;
            pendingMusicContinuationLyricPos = 0;
          }
        }
        continue;
      }
      if (raw.trim() === "") {
        result.push({ type: "blank" });
        lastWasLyrics = false;
        implicitLyricContinuationIdx = null;
        sectionLyricIndices = [];
        pendingMusicContinuationLyricIndices = null;
        pendingMusicContinuationLyricPos = 0;
        continue;
      }
      if (raw[0] === "%") {
        if (raw.startsWith("%[")) {
          const closeIdx = raw.indexOf("%]", 2);
          if (closeIdx >= 0) {
            const inner = raw.slice(2, closeIdx).trim();
            const dm = inner.match(/^(\S+?):\s*(.*)$/);
            if (dm) {
              result.push({ type: "preprocessor", key: dm[1], value: dm[2].trim() });
            }
          } else {
            inBlockComment = true;
          }
        }
        lastWasLyrics = false;
        implicitLyricContinuationIdx = null;
        pendingMusicContinuationLyricIndices = null;
        pendingMusicContinuationLyricPos = 0;
        continue;
      }
      const verseLine = raw.match(/^(\s*W(?:\(([a-z]+)\))?:\s?)(.*)$/);
      if (verseLine) {
        const text = verseLine[3];
        const textStart = lineStart + verseLine[1].length;
        result.push({
          type: "verse",
          style: verseLine[2] ?? null,
          lines: [text],
          spans: [{ srcStart: textStart, srcEnd: textStart + text.length }],
          srcStart: textStart,
          srcEnd: textStart + text.length
        });
        lastWasLyrics = false;
        implicitLyricContinuationIdx = null;
        pendingMusicContinuationLyricIndices = null;
        pendingMusicContinuationLyricPos = 0;
        continue;
      }
      const lyricLine = raw.match(/^(\s*w:\s?)(.*)$/);
      if (lyricLine) {
        const text = lyricLine[2];
        const textStart = lineStart + lyricLine[1].length;
        const hasMusicContinuationLyric = pendingMusicContinuationLyricIndices && pendingMusicContinuationLyricPos < pendingMusicContinuationLyricIndices.length;
        const continuationIdx = hasMusicContinuationLyric ? pendingMusicContinuationLyricIndices[pendingMusicContinuationLyricPos] : null;
        const continuationTarget = continuationIdx !== null ? result[continuationIdx] : null;
        if (continuationTarget && continuationTarget.type === "lyrics") {
          const trimmed = trimmedSourceText(text, textStart);
          appendLyricContinuation(continuationTarget, trimmed.text, trimmed.srcStart);
          implicitLyricContinuationIdx = continuationIdx;
          pendingMusicContinuationLyricPos++;
          if (pendingMusicContinuationLyricPos >= pendingMusicContinuationLyricIndices.length) {
            pendingMusicContinuationLyricIndices = null;
            pendingMusicContinuationLyricPos = 0;
          }
        } else {
          result.push(makeLyricItem(text, textStart));
          implicitLyricContinuationIdx = result.length - 1;
          sectionLyricIndices.push(implicitLyricContinuationIdx);
        }
        lastWasLyrics = true;
        continue;
      }
      const musicContinuation = raw.match(/^(\s*n:\s?)(.*)$/);
      if (musicContinuation) {
        result.push({
          type: "music",
          tokens: tokenizeMusicLine(musicContinuation[2], lineStart + musicContinuation[1].length)
        });
        lastWasLyrics = false;
        implicitLyricContinuationIdx = null;
        pendingMusicContinuationLyricIndices = sectionLyricIndices.slice();
        pendingMusicContinuationLyricPos = 0;
        continue;
      }
      if (lastWasLyrics) {
        const last = implicitLyricContinuationIdx !== null ? result[implicitLyricContinuationIdx] : result[result.length - 1];
        if (last && last.type === "lyrics") {
          const trimmed = trimmedSourceText(raw, lineStart);
          appendLyricContinuation(last, trimmed.text, trimmed.srcStart);
        }
        continue;
      }
      const lastItem = result[result.length - 1];
      if (lastItem && lastItem.type === "verse") {
        const trimmed = trimmedSourceText(raw, lineStart);
        lastItem.lines.push(trimmed.text);
        lastItem.spans.push({ srcStart: trimmed.srcStart, srcEnd: trimmed.srcStart + trimmed.text.length });
        lastItem.srcEnd = trimmed.srcStart + trimmed.text.length;
        continue;
      }
      result.push({ type: "music", tokens: tokenizeMusicLine(raw, lineStart) });
    }
    return { header, optionHeaders, lines: result };
  }
  function isPitchLetter(c) {
    return /[a-gA-G]/.test(c);
  }
  function octaveShiftAt(line, i, limit) {
    let j = i;
    let shift = 0;
    while (j < limit && (line[j] === "^" || line[j] === "v")) {
      shift += line[j] === "^" ? 1 : -1;
      j++;
    }
    if (j < limit && isPitchLetter(line[j])) {
      return { shift, end: j };
    }
    return null;
  }
  var ACCIDENTAL_TOKENS = { b: "x", n: "y", "#": "#" };
  function matchAccidental(inner, defaultPitch = "b") {
    const m = inner.match(/^([a-gA-G]?)([bn#])$/);
    if (!m) {
      return null;
    }
    const pitchLetter = m[1] || defaultPitch;
    return {
      pitch: pitchLetter,
      symbol: ACCIDENTAL_TOKENS[m[2]]
    };
  }
  function peekInlineAccidental(line, pos) {
    if (line[pos] !== "(") {
      return null;
    }
    const end = line.indexOf(")", pos);
    if (end < 0) {
      return null;
    }
    const acc = matchAccidental(line.slice(pos + 1, end).trim());
    if (!acc) {
      return null;
    }
    return { pitch: acc.pitch, symbol: acc.symbol, end: end + 1 };
  }
  function parseNoteGroupSequence(line, i, lineStart, limit) {
    const groups = [];
    const gaps = [];
    while (true) {
      const group = [];
      let pendingAcc = null;
      while (i < limit && (octaveShiftAt(line, i, limit) !== null || line[i] === "(" && peekInlineAccidental(line, i) !== null)) {
        if (line[i] === "(") {
          const accStart = i;
          pendingAcc = peekInlineAccidental(line, i);
          pendingAcc.srcStart = lineStart + accStart;
          pendingAcc.srcEnd = lineStart + pendingAcc.end;
          i = pendingAcc.end;
          continue;
        }
        const noteStart = i;
        const shiftInfo = octaveShiftAt(line, i, limit);
        i = shiftInfo.end;
        const pitchChar = line[i];
        i++;
        const note = {
          pitch: pitchChar,
          ...shiftInfo.shift ? { octaveShift: shiftInfo.shift } : {},
          virga: false,
          noVirga: false,
          shape: "punctum",
          modifiers: [],
          modifierSpans: []
        };
        if (pendingAcc) {
          note.accidental = {
            pitch: pendingAcc.pitch,
            symbol: pendingAcc.symbol,
            srcStart: pendingAcc.srcStart,
            srcEnd: pendingAcc.srcEnd
          };
          pendingAcc = null;
        }
        while (i < limit) {
          const m = line[i];
          const span = { srcStart: lineStart + i, srcEnd: lineStart + i + 1 };
          if (m === "'") {
            note.virga = true;
            i++;
            continue;
          }
          if (m === "`") {
            note.noVirga = true;
            i++;
            continue;
          }
          if (m === "_") {
            note.modifiers.push("episema");
            note.modifierSpans.push(span);
            i++;
            continue;
          }
          if (m === "-") {
            note.modifiers.push("ictus");
            note.modifierSpans.push(span);
            i++;
            continue;
          }
          if (m === ".") {
            note.modifiers.push("mora");
            note.modifierSpans.push(span);
            i++;
            continue;
          }
          if (m === "~") {
            note.modifiers.push("plica");
            note.modifierSpans.push(span);
            i++;
            continue;
          }
          if (m === "w") {
            note.shape = "quilisma";
            i++;
            continue;
          }
          if (m === "t") {
            note.shape = "tenor";
            i++;
            continue;
          }
          if (m === "s") {
            note.modifiers.push("small");
            note.modifierSpans.push(span);
            i++;
            continue;
          }
          break;
        }
        note.srcStart = lineStart + noteStart;
        note.srcEnd = lineStart + i;
        group.push(note);
      }
      if (group.length) groups.push(group);
      let j = i;
      while (j < limit && (line[j] === " " || line[j] === "	")) j++;
      if (j < limit && line[j] === "/") {
        let slashCount = 0;
        let k = j;
        while (k < limit && line[k] === "/") {
          slashCount++;
          k++;
        }
        while (k < limit && (line[k] === " " || line[k] === "	")) k++;
        if (k < limit && (octaveShiftAt(line, k, limit) !== null || line[k] === "(" && peekInlineAccidental(line, k) !== null)) {
          i = k;
          gaps.push(slashCount);
          continue;
        }
      }
      break;
    }
    return { groups, gaps, newI: i };
  }
  function tokenizeMusicLine(line, lineStart = 0) {
    const tokens = [];
    const len = line.length;
    let i = 0;
    while (i < len) {
      const ch = line[i];
      if (ch === " " || ch === "	") {
        i++;
        continue;
      }
      if (ch === "%") {
        if (line[i + 1] === "[") {
          const closeIdx = line.indexOf("%]", i + 2);
          if (closeIdx >= 0) {
            const inner = line.slice(i + 2, closeIdx).trim();
            const srcStart = lineStart + i;
            i = closeIdx + 2;
            const srcEnd = lineStart + i;
            const dm = inner.match(/^(\S+?):\s*(.*)$/);
            if (dm) {
              tokens.push({ type: "inline-directive", key: dm[1], value: dm[2].trim(), srcStart, srcEnd });
            }
          } else {
            break;
          }
          continue;
        }
        break;
      }
      const tokStart = i;
      if (ch === "(") {
        const end = line.indexOf(")", i);
        const value = end < 0 ? line.slice(i + 1) : line.slice(i + 1, end);
        i = end < 0 ? len : end + 1;
        const inner = value.trim();
        const srcStart = lineStart + tokStart;
        const srcEnd = lineStart + i;
        const bareBar = inner.match(/^(,2|[,;'~]|:\|:|:\||\|:|\|0|\|\?|\|{1,3})$/);
        if (bareBar) {
          tokens.push({ type: "barline", kind: bareBar[1], srcStart, srcEnd });
        } else if (/^sp([0-9]*\.?[0-9]*)$/i.test(inner)) {
          const m2 = inner.match(/^sp([0-9]*\.?[0-9]*)$/i);
          const multiplier = m2[1] ? parseFloat(m2[1]) : 1;
          tokens.push({ type: "spacer", multiplier: isFinite(multiplier) && multiplier > 0 ? multiplier : 1, srcStart, srcEnd });
        } else {
          tokens.push({ type: "directive", value: inner, srcStart, srcEnd });
        }
        continue;
      }
      if (ch === "*") {
        tokens.push({ type: "expander", srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + 1 });
        i++;
        continue;
      }
      if (ch === "=") {
        let count = 0;
        while (i < len && line[i] === "=") {
          count++;
          i++;
        }
        tokens.push({ type: "spacer", multiplier: count, srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + count });
        continue;
      }
      if (ch === ":" && line[i + 1] === "|") {
        if (line[i + 2] === ":") {
          tokens.push({ type: "barline", kind: ":|:", srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + 3 });
          i += 3;
        } else {
          tokens.push({ type: "barline", kind: ":|", srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + 2 });
          i += 2;
        }
        continue;
      }
      if (ch === "|") {
        if (line[i + 1] === "0") {
          tokens.push({ type: "barline", kind: "|0", srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + 2 });
          i += 2;
          continue;
        }
        if (line[i + 1] === "?") {
          tokens.push({ type: "barline", kind: "|?", srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + 2 });
          i += 2;
          continue;
        }
        let count = 1;
        while (i + count < len && line[i + count] === "|") {
          count++;
        }
        if (count === 1 && line[i + 1] === ":") {
          tokens.push({ type: "barline", kind: "|:", srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + 2 });
          i += 2;
        } else {
          const kind = "|".repeat(Math.min(count, 3));
          tokens.push({ type: "barline", kind, srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + count });
          i += count;
        }
        continue;
      }
      if (ch === "," && line[i + 1] === "2") {
        tokens.push({ type: "barline", kind: ",2", srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + 2 });
        i += 2;
        continue;
      }
      if (ch === "," || ch === ";") {
        tokens.push({ type: "barline", kind: ch, srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + 1 });
        i++;
        continue;
      }
      if (ch === "'") {
        tokens.push({ type: "barline", kind: "'", srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + 1 });
        i++;
        continue;
      }
      if (ch === "~") {
        tokens.push({ type: "barline", kind: "~", srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + 1 });
        i++;
        continue;
      }
      if (ch === "[") {
        tokens.push({ type: "paren-open", srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + 1 });
        i++;
        continue;
      }
      if (ch === "]") {
        tokens.push({ type: "paren-close", srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + 1 });
        i++;
        continue;
      }
      if (ch === "\\") {
        const m = /^\\([a-zA-Z]+)\{/.exec(line.slice(i));
        if (m) {
          tokens.push({ type: "brace-open", kind: m[1], srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + m[0].length });
          i += m[0].length;
          continue;
        }
      }
      if (ch === "{") {
        tokens.push({ type: "brace-open", kind: "brace", srcStart: lineStart + tokStart, srcEnd: lineStart + tokStart + 1 });
        i++;
        continue;
      }
      if (ch === "}") {
        let label = null;
        let endI = i + 1;
        if (endI < len && line[endI] === '"') {
          const closeIdx = line.indexOf('"', endI + 1);
          if (closeIdx >= 0) {
            label = line.slice(endI + 1, closeIdx);
            endI = closeIdx + 1;
          } else {
            let sp = line.indexOf(" ", endI + 1);
            if (sp === -1) sp = len;
            label = line.slice(endI + 1, sp);
            endI = sp;
          }
        }
        tokens.push({ type: "brace-close", ...label !== null ? { label } : {}, srcStart: lineStart + tokStart, srcEnd: lineStart + endI });
        i = endI;
        continue;
      }
      if (octaveShiftAt(line, i, len) !== null) {
        const r = parseNoteGroupSequence(line, i, lineStart, len);
        i = r.newI;
        if (r.groups.length) {
          let label = null;
          if (i < len && line[i] === '"') {
            const closeIdx = line.indexOf('"', i + 1);
            if (closeIdx >= 0) {
              label = line.slice(i + 1, closeIdx);
              i = closeIdx + 1;
            } else {
              let spaceIdx = line.indexOf(" ", i + 1);
              if (spaceIdx === -1) spaceIdx = len;
              label = line.slice(i + 1, spaceIdx);
              i = spaceIdx;
            }
          }
          tokens.push({ type: "ligature", groups: r.groups, gaps: r.gaps, ...label !== null ? { label } : {}, srcStart: lineStart + tokStart, srcEnd: lineStart + i });
        }
        continue;
      }
      i++;
    }
    return tokens;
  }

  // node_modules/@aretino-chant/core/src/glyphs.js
  var METRICS = {
    // --- Notehead (rotated filled oval) -----------------------------------
    noteheadRx: 0.61,
    // pre-rotation horizontal radius
    noteheadRy: 0.47271,
    // pre-rotation vertical radius
    noteheadRotationDeg: -25,
    noteBoxWidth: 1.1749,
    // layout/bounding-box width  2*sqrt((rx*cos θ)²+(ry*sin θ)²)
    noteBoxHeight: 1,
    // layout/bounding-box height
    // --- Horizontal advances ----------------------------------------------
    singleNoteAdvance: 1.9,
    // use the golden ratio (the spaces between noteheads vs the noteheads)
    ligatureStepAdvance: 1.1749,
    // added per extra note in a ligature
    expanderWidth: 0.75,
    // intrinsic width of '*' expander
    neumeGapAdvance: 0.71 / 2,
    // extra space per '/' between neume groups
    gapOutlierThreshold: 2,
    // gap floors wider than this are outliers: they keep their own width instead of driving the unified neume gap
    gapOutlierThresholdMin: 1,
    // lowest gapOutlierThreshold the line breaker may use for a row it condenses to avoid a lone syllable
    wrapCondenseMin: 0.75,
    // share of the natural white space between neumes a condensed row must keep
    recitationLoneWordMin: 2.25,
    // em of the lyric size: a recited word at least this wide may stand alone at a line break
    wrapStretchMax: 2,
    // most extra white space per gap a row pulled back to avoid a lone syllable may take, in natural white spaces
    // --- Staff lines ------------------------------------------------------
    staffLineCount: 5,
    staffLineStroke: 0.11,
    staffLineStrokeMinPx: 0.6,
    // --- Ledger lines -----------------------------------------------------
    ledgerHalfExtent: 0.81,
    // extent on each side of notehead center
    ledgerLineSpacing: 1,
    // distance between successive ledgers
    ledgerStroke: 0.09,
    ledgerStrokeMinPx: 0.6,
    // --- Stems (virga & tenor side strokes) -------------------------------
    stemStroke: 0.14,
    stemStrokeMinPx: 0.8,
    virgaStemLength: 2.75,
    // default descent of virga stem
    virgaStemDescentBelowPrev: 2.25,
    // descent past a lower preceding note
    virgaMaxBelowBottom: 1.75,
    // stem tip never exceeds this many spatia below bottom staff line
    // --- Tenor notehead (open oval with two side strokes) -----------------
    tenorSideStrokeOffset: 0.14,
    // gap between head edge and side stroke
    tenorSideStrokeHalfHeight: 0.55,
    tenorSideStroke: 0.14,
    // thickness of the two vertical bars
    tenorSideStrokeMinPx: 0.7,
    tenorAdvanceExtra: 1.5,
    // extra advance vs. a normal note (wider glyph)
    tenorCalligraphyWidthScale: 1.1,
    // tenor open oval is wider than a normal notehead
    tenorCalligraphyInnerScaleX: 0.55,
    // inner (hole) ellipse rx as a fraction of the outer rx; controls the thickness of the short ends (keep < ~0.8 so the hole stays inside the outline)
    tenorCalligraphyInnerScaleY: 0.55,
    // inner (hole) ellipse ry as a fraction of the outer ry; controls the thickness of the long sides (keep < ~0.8 so the hole stays inside the outline)
    tenorCalligraphyOuterRotationDeg: 25,
    // tilt of the outer (silhouette) ellipse relative to the normal notehead rotation; rotates the whole open oval
    tenorCalligraphyInnerRotationDeg: 40,
    // tilt of the inner (hole) ellipse relative to the outer; offsets the swell toward one diagonal end for a hand-traced look
    // --- Small notehead (optional psalm-tone notes) ----------------------
    smallNoteScale: 0.7,
    // scale factor for small noteheads
    // --- Mora dot ---------------------------------------------------------
    moraOffsetX: 0.9,
    // horizontal distance from notehead center
    moraRadius: 0.125,
    // --- Episema (horizontal mark above note) -----------------------------
    episemaWidth: 0.65,
    episemaStroke: 0.12,
    episemaStrokeMinPx: 0.8,
    // --- Ictus (vertical mark above note) --------------------------------
    ictusHeight: 0.25,
    ictusStroke: 0.12,
    ictusStrokeMinPx: 0.8,
    // --- Notehead plica (right-parenthesis tail beside the notehead) ----------
    plicaAnchorX: 0.2,
    // x offset of both endpoints from notehead center
    plicaTopY: 0.4,
    // y offset above center (top-right corner of head)
    plicaBottomY: 0.8,
    // y offset below center (under bottom-right corner)
    plicaBulge: 0.6,
    // outward push of control points → curve depth
    plicaStroke: 0.15,
    plicaStrokeMinPx: 0.7,
    // --- Ligature connectors ----------------------------------------------
    ligatureConnectorStroke: 0.11,
    ligatureConnectorStrokeMinPx: 0.1,
    // --- Quilisma (saw-tooth notehead) ------------------------------------
    quilismaTeeth: 4,
    quilismaPeakUp: 0.5,
    // × noteBoxHeight
    quilismaLowerY: 0,
    quilismaTrough: 0.5,
    quilismaSlope: 0.4,
    // total upward rise left→right, × noteBoxHeight
    quilismaOffsetY: 0.3,
    // downward shift of entire glyph, × noteBoxHeight
    // --- Clefs ------------------------------------------------------------
    clefCLeftPadding: 0.15,
    // gap before C-clef body
    clefCRightPadding: 0.6,
    // gap after C-clef body
    clefPostGap: 1,
    // gap after start-of-system clef
    clefInlinePostGap: 0.25,
    // gap after mid-system clef change
    keySigInlinePostGap: 0.5,
    // gap after mid-system key signature change
    // --- Accidentals (flat / natural / sharp) -----------------------------
    accidentalSize: 0.9,
    accidentalAdvanceFlat: 1.08,
    // for flat (b)
    accidentalAdvanceNatural: 0.95,
    // for natural
    accidentalAdvanceSharp: 1.18,
    // for sharp
    // --- Barlines ---------------------------------------------------------
    barlineStroke: 0.18,
    barlineStrokeMinPx: 0.8,
    barlineOffsetX: 0.3,
    // gap before line
    barlineAdvance: 0.8,
    barlinePostGap: 0.5,
    // gap after barline (one staff space)
    barlineDoubleSecondOffsetX: 0.9,
    // second line offset for '||'
    barlineDoubleAdvance: 1.5,
    barlineRepeatAdvance: 2.4,
    // advance for repeat signs (wider than double)
    barlineRepeatDotRadius: 0.15,
    // dot radius for ':|'
    barlineRepeatDotGap: 0.5,
    // gap between dots for ':|'
    barlineFinalThickStroke: 0.4,
    // thick stroke for '|||'
    // --- Spacer -----------------------------------------------------------
    spacerAdvance: 1,
    // default width of one (sp) spacer unit
    // --- Parenthesized neumes ---------------------------------------------
    parenthesisWidth: 0.45,
    // horizontal space reserved for the arc itself
    parenthesisInnerGap: 0.2,
    // gap between arc hinge and the adjacent note
    parenthesisBulge: 1,
    // outward bulge of the arc
    parenthesisVPadding: 0.4,
    // vertical extension beyond the note bounding box
    parenthesisThickness: 0.25,
    // max visual stroke width at the midpoint (staff spaces)
    // --- Overbraces and arcs above neume spans ----------------------------
    overbraceGap: 0.45,
    // gap between top of notes and bottom of brace
    overbraceTipDepth: 0.25,
    // downward V-tip depth (brace only)
    overbraceArmDepth: 0.22,
    // downward arm depth at each end
    overbraceKinkWidth: 0.3,
    // horizontal width of the center brace kink
    overbraceStroke: 0.2,
    overbraceStrokeMinPx: 0.75,
    overarcBulge: 0.75,
    // upward arc height in SS
    overarcStroke: 0.09,
    overarcStrokeMinPx: 0.75,
    // --- Slur (downward arc below notes) ----------------------------------
    slurGap: 0.3,
    // gap below bottom of note bounding box
    slurBulge: 0.9,
    // downward arc depth in SS
    slurStroke: 0.12,
    slurStrokeMinPx: 0.75,
    slurDashLen: 0.5,
    // dash length in SS (dashed slur)
    slurDashGap: 0.5,
    // gap length in SS (dashed slur)
    slurStubWidth: 2,
    // width of line-break stub arcs
    // --- Page layout ------------------------------------------------------
    leftMargin: 1,
    rightMargin: 1,
    staffGap: 2.5,
    titleTopPadding: 2,
    // Clearance between the music's lowest ink and the top of the lyric letters.
    // Both are measured: the ink includes virga stems, morae and ictus (see
    // noteInkBounds), and the letters are measured by their real ascent, so a row
    // of short lower-case syllables rides closer than one carrying capitals.
    //
    // Half a staff space. Because both ends of the measurement are real, this is
    // the gap that actually appears on the page — where a virga stem hangs over a
    // syllable, the letters clear its tip by this much and no less. It is set
    // against `lyricMinStaffDistance` below: a row with something hanging beneath
    // the staff must not be given less air than a row with nothing.
    lyricDistance: 0.5,
    // Lyrics normally sit `lyricDistance` below the lowest ink. This floor keeps
    // the lyric line at least `lyricMinStaffDistance` (SS) below the bottom staff
    // line even when the notes sit high in (or above) the staff.
    lyricMinStaffDistance: 0.75,
    // Stanza advance, as a multiple of the lyric font size.
    lyricLineSkip: 1.2,
    // --- Lyric hyphens ----------------------------------------------------
    // The hyphen between two syllables of a word is a drawn stroke, not the
    // lyric font's '-' glyph: a glyph carries side bearings of its own and
    // differs from face to face, so at a singable lyric size it sets a mark of
    // unpredictable length. Lengths and thickness are fractions of the lyric
    // font size. The stroke gives way to the room there is, between min and max,
    // so a stretched row draws a long one and a tight row a short one without
    // either of them moving a notehead.
    lyricHyphenMinLen: 0.17,
    lyricHyphenMaxLen: 0.33,
    lyricHyphenWidth: 0.04,
    // Air on either side of the stroke, keeping it off the letters.
    lyricHyphenSpace: 0.05,
    // Height above the baseline, in x-heights of the lyric face: .5 puts the
    // stroke across the middle of the letters it stands between, 1 on top of them.
    lyricHyphenPos: 0.55,
    // A gap wider than this many font sizes carries more than one stroke, so a
    // justified row or a long melisma does not leave a lone hyphen adrift.
    lyricHyphenRepeat: 4
  };
  var PITCH_BASE = { A: -4, B: -3, c: -2, d: -1, e: 0, f: 1, g: 2, a: 3, b: 4, C: 5, D: 6, E: 7, F: 8, G: 9 };
  function stroke(ctx, ssFraction, minPx) {
    return Math.max(minPx, ssFraction * ctx.staffSpace);
  }
  function ss(ctx, n) {
    return n * ctx.staffSpace;
  }
  var OCTAVE_STEPS = 7;
  function pitchToPos(note) {
    return (PITCH_BASE[note.pitch] ?? 0) + OCTAVE_STEPS * (note.octaveShift || 0);
  }
  function pitchY(ctx, note, staffBottomY) {
    return staffBottomY - pitchToPos(note) * ctx.pitchStep;
  }
  function attr(s) {
    return String(s).replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;");
  }
  function ovalHead(ctx, cx, cy, opts = {}) {
    const rx = opts.rx ?? ss(ctx, METRICS.noteheadRx);
    const ry = opts.ry ?? ss(ctx, METRICS.noteheadRy);
    const fill = opts.fill ?? "#000";
    const strokeColor = opts.stroke ?? "none";
    const sw = opts.strokeWidth ?? 0;
    return `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${fill}" stroke="${strokeColor}" stroke-width="${sw}" transform="rotate(${METRICS.noteheadRotationDeg}, ${cx}, ${cy})"/>`;
  }
  function calligraphicOval(ctx, cx, cy, opts = {}) {
    const rx = opts.rx ?? ss(ctx, METRICS.noteheadRx);
    const ry = opts.ry ?? ss(ctx, METRICS.noteheadRy);
    const fill = opts.fill ?? "#000";
    const \u03B8 = (METRICS.noteheadRotationDeg + METRICS.tenorCalligraphyOuterRotationDeg) * Math.PI / 180;
    const N = 64;
    const ringPath = (dir, sx, sy, \u03C6) => {
      const cos\u03C6 = Math.cos(\u03C6), sin\u03C6 = Math.sin(\u03C6);
      let d = "";
      for (let k = 0; k <= N; k++) {
        const t = dir * (k / N) * 2 * Math.PI;
        const ex = rx * sx * Math.cos(t), ey = ry * sy * Math.sin(t);
        const px = cx + ex * cos\u03C6 - ey * sin\u03C6;
        const py = cy + ex * sin\u03C6 + ey * cos\u03C6;
        d += `${k === 0 ? "M" : "L"}${px.toFixed(3)} ${py.toFixed(3)}`;
      }
      return d + "Z";
    };
    const innerX = METRICS.tenorCalligraphyInnerScaleX;
    const innerY = METRICS.tenorCalligraphyInnerScaleY;
    const inner\u03B8 = \u03B8 + METRICS.tenorCalligraphyInnerRotationDeg * Math.PI / 180;
    const path = ringPath(1, 1, 1, \u03B8) + ringPath(-1, innerX, innerY, inner\u03B8);
    return `<path d="${path}" fill="${fill}"/>`;
  }
  function ledgerLines(ctx, cx, cy, staffBottomY) {
    const top = staffBottomY - (METRICS.staffLineCount - 1) * ctx.staffSpace;
    const bottom = staffBottomY;
    const halfW = ss(ctx, METRICS.ledgerHalfExtent);
    const spacing = ss(ctx, METRICS.ledgerLineSpacing);
    const tolerance = ctx.pitchStep;
    const epsilon = ctx.pitchStep * 0.1;
    const sw = stroke(ctx, METRICS.ledgerStroke, METRICS.ledgerStrokeMinPx);
    const parts = [];
    if (cy < top - tolerance) {
      let yLine = top - spacing;
      while (yLine >= cy - epsilon) {
        parts.push(`<line x1="${cx - halfW}" y1="${yLine}" x2="${cx + halfW}" y2="${yLine}" stroke="#000" stroke-width="${sw}"/>`);
        yLine -= spacing;
      }
    } else if (cy > bottom + tolerance) {
      let yLine = bottom + spacing;
      while (yLine <= cy + epsilon) {
        parts.push(`<line x1="${cx - halfW}" y1="${yLine}" x2="${cx + halfW}" y2="${yLine}" stroke="#000" stroke-width="${sw}"/>`);
        yLine += spacing;
      }
    }
    return parts.join("");
  }
  function drawNoteHead(ctx, note, cx, cy, staffBottomY, prevCy = null) {
    const parts = [];
    parts.push(ledgerLines(ctx, cx, cy, staffBottomY));
    const noteW = ss(ctx, METRICS.noteBoxWidth);
    const noteH = ss(ctx, METRICS.noteBoxHeight);
    const isSmall = note.modifiers && note.modifiers.includes("small");
    const scale = isSmall ? METRICS.smallNoteScale : 1;
    const headCx = cx;
    if (note.shape === "quilisma") {
      const teeth = METRICS.quilismaTeeth;
      const dx = noteW / teeth;
      const totalRise = noteH * METRICS.quilismaSlope;
      const offsetY = noteH * METRICS.quilismaOffsetY;
      const baseY = (f) => cy + offsetY - f * totalRise;
      let path = `M ${cx - noteW / 2} ${baseY(0)} `;
      for (let t = 0; t < teeth; t++) {
        const xa = cx - noteW / 2 + t * dx;
        const xb = xa + dx / 2;
        const xc = xa + dx;
        const fPeak = (t + 0.5) / teeth;
        const fBase = (t + 1) / teeth;
        path += `L ${xb} ${baseY(fPeak) - noteH * METRICS.quilismaPeakUp} L ${xc} ${baseY(fBase)} `;
      }
      path += `L ${cx + noteW / 2} ${baseY(1) + noteH * METRICS.quilismaLowerY} `;
      for (let t = teeth - 1; t >= 0; t--) {
        const xa = cx - noteW / 2 + t * dx + dx;
        const xb = xa - dx / 2;
        const xc = xa - dx;
        const fTrough = (t + 0.5) / teeth;
        const fBase = t / teeth;
        path += `L ${xb} ${baseY(fTrough) + noteH * METRICS.quilismaTrough} L ${xc} ${baseY(fBase) + noteH * METRICS.quilismaLowerY} `;
      }
      path += "Z";
      parts.push(`<path d="${path}" fill="#000"/>`);
    } else if (note.shape === "tenor") {
      const sideSW = stroke(ctx, METRICS.tenorSideStroke, METRICS.tenorSideStrokeMinPx);
      const sideX = (noteW / 2 + ss(ctx, METRICS.tenorSideStrokeOffset)) * scale;
      const { dx: edgeDx } = noteheadEdgeOffset(ctx);
      const tenorCx = cx + (sideX + sideSW - edgeDx * scale);
      parts.push(calligraphicOval(ctx, tenorCx, cy, { rx: ss(ctx, METRICS.noteheadRx) * METRICS.tenorCalligraphyWidthScale * scale, ry: ss(ctx, METRICS.noteheadRy) * scale }));
      const halfH = ss(ctx, METRICS.tenorSideStrokeHalfHeight) * scale;
      parts.push(`<line x1="${tenorCx - sideX}" y1="${cy - halfH}" x2="${tenorCx - sideX}" y2="${cy + halfH}" stroke="#000" stroke-width="${sideSW}" stroke-linecap="round"/>`);
      parts.push(`<line x1="${tenorCx + sideX}" y1="${cy - halfH}" x2="${tenorCx + sideX}" y2="${cy + halfH}" stroke="#000" stroke-width="${sideSW}" stroke-linecap="round"/>`);
    } else {
      parts.push(ovalHead(ctx, headCx, cy, { rx: ss(ctx, METRICS.noteheadRx) * scale, ry: ss(ctx, METRICS.noteheadRy) * scale }));
    }
    if (note.shape === "virga" || note.virga) {
      const sw = stroke(ctx, METRICS.stemStroke, METRICS.stemStrokeMinPx);
      const scaledNoteW = noteW * scale;
      const stemX = headCx - scaledNoteW / 2 * Math.cos(METRICS.noteheadRotationDeg * Math.PI / 180);
      const stemLength = prevCy !== null && prevCy > cy ? prevCy - cy + ss(ctx, ctx.virgaStemDescentBelowPrev ?? METRICS.virgaStemDescentBelowPrev) : ss(ctx, ctx.virgaStemLength ?? METRICS.virgaStemLength);
      const maxBottom = staffBottomY + ss(ctx, ctx.virgaMaxBelowBottom ?? METRICS.virgaMaxBelowBottom);
      const cappedLength = Math.max(ss(ctx, 1.75), Math.min(stemLength, maxBottom - cy));
      const verticalOffset = ss(ctx, 0.13);
      parts.push(`<line x1="${stemX}" y1="${cy + verticalOffset}" x2="${stemX}" y2="${cy + cappedLength}" stroke="#000" stroke-width="${sw}" stroke-linecap="round"/>`);
    }
    return parts.join("");
  }
  function computeAutoVirga(notes) {
    const autoVirga = new Array(notes.length).fill(false);
    if (notes.length < 2) {
      return autoVirga;
    }
    const pitchPositions = notes.map((n) => pitchToPos(n));
    if (Math.max(...pitchPositions) <= Math.min(...pitchPositions)) {
      return autoVirga;
    }
    for (let i = 0; i < notes.length; i++) {
      const atLeastAsHighAsLeft = i === 0 || pitchPositions[i] >= pitchPositions[i - 1];
      const higherThanRight = i === notes.length - 1 || pitchPositions[i] > pitchPositions[i + 1];
      if (atLeastAsHighAsLeft && higherThanRight && !notes[i].noVirga) {
        autoVirga[i] = true;
      }
    }
    return autoVirga;
  }
  function noteInkBounds(ctx, note, cy, staffBottomY, prevCy = null) {
    const isSmall = note.modifiers && note.modifiers.includes("small");
    const scale = isSmall ? METRICS.smallNoteScale : 1;
    const halfNoteH = ss(ctx, METRICS.noteBoxHeight) * 0.5 * scale;
    let minY = cy - halfNoteH;
    let maxY = cy + halfNoteH;
    if (note.shape === "tenor") {
      const halfH = ss(ctx, METRICS.tenorSideStrokeHalfHeight) * scale;
      minY = Math.min(minY, cy - halfH);
      maxY = Math.max(maxY, cy + halfH);
    }
    if (note.shape === "quilisma") {
      const noteH = ss(ctx, METRICS.noteBoxHeight);
      const totalRise = noteH * METRICS.quilismaSlope;
      const offsetY = noteH * METRICS.quilismaOffsetY;
      minY = Math.min(minY, cy + offsetY - totalRise - noteH * METRICS.quilismaPeakUp);
      maxY = Math.max(maxY, cy + offsetY + noteH * METRICS.quilismaTrough);
    }
    if (note.shape === "virga" || note.virga) {
      const stemLength = prevCy !== null && prevCy > cy ? prevCy - cy + ss(ctx, ctx.virgaStemDescentBelowPrev ?? METRICS.virgaStemDescentBelowPrev) : ss(ctx, ctx.virgaStemLength ?? METRICS.virgaStemLength);
      const maxBottom = staffBottomY + ss(ctx, ctx.virgaMaxBelowBottom ?? METRICS.virgaMaxBelowBottom);
      const cappedLength = Math.max(ss(ctx, 1.75), Math.min(stemLength, maxBottom - cy));
      const half = stroke(ctx, METRICS.stemStroke, METRICS.stemStrokeMinPx) / 2;
      maxY = Math.max(maxY, cy + cappedLength + half);
    }
    for (const mod2 of note.modifiers ?? []) {
      const onLine = pitchToPos(note) % 2 === 0;
      if (mod2 === "episema") {
        minY = Math.min(minY, cy - (onLine ? ctx.staffSpace * 1.5 : ctx.staffSpace));
      } else if (mod2 === "mora") {
        const dotY = onLine ? cy - ctx.staffSpace / 2 : cy;
        const r = ss(ctx, METRICS.moraRadius);
        minY = Math.min(minY, dotY - r);
        maxY = Math.max(maxY, dotY + r);
      } else if (mod2 === "ictus") {
        const below = note.modifiers.includes("episema");
        const topLinePos = (METRICS.staffLineCount - 1) * 2;
        const ictusOnLine = onLine && (below || pitchToPos(note) < topLinePos);
        const h = ss(ctx, METRICS.ictusHeight);
        const center = below ? cy + ctx.staffSpace * (ictusOnLine ? 1.5 : 1) : cy - ctx.staffSpace * (ictusOnLine ? 1.5 : 1);
        const topY = center - h / 2;
        minY = Math.min(minY, topY);
        maxY = Math.max(maxY, topY + h);
      } else if (mod2 === "plica") {
        minY = Math.min(minY, cy - ss(ctx, METRICS.plicaTopY));
        maxY = Math.max(maxY, cy + ss(ctx, METRICS.plicaBottomY));
      }
    }
    return { minY, maxY };
  }
  function drawEpisema(ctx, cx, cy, onLine = false) {
    const w = ss(ctx, METRICS.episemaWidth);
    const y = cy - (onLine ? ctx.staffSpace * 1.5 : ctx.staffSpace);
    const sw = stroke(ctx, METRICS.episemaStroke, METRICS.episemaStrokeMinPx);
    return `<line x1="${cx - w / 2}" y1="${y}" x2="${cx + w / 2}" y2="${y}" stroke="#000" stroke-width="${sw}" stroke-linecap="round"/>`;
  }
  function drawEpisemaSpan(ctx, x1, x2, cy, onLine = false) {
    const y = cy - (onLine ? ctx.staffSpace * 1.5 : ctx.staffSpace);
    const sw = stroke(ctx, METRICS.episemaStroke, METRICS.episemaStrokeMinPx);
    return `<line x1="${x1}" y1="${y}" x2="${x2}" y2="${y}" stroke="#000" stroke-width="${sw}" stroke-linecap="round"/>`;
  }
  function drawIctus(ctx, cx, cy, onLine = false, below = false) {
    const h = ss(ctx, METRICS.ictusHeight);
    const center = below ? cy + ctx.staffSpace * (onLine ? 1.5 : 1) : cy - ctx.staffSpace * (onLine ? 1.5 : 1);
    const topY = center - h / 2;
    const sw = stroke(ctx, METRICS.ictusStroke, METRICS.ictusStrokeMinPx);
    return `<line x1="${cx}" y1="${topY}" x2="${cx}" y2="${topY + h}" stroke="#000" stroke-width="${sw}" stroke-linecap="round"/>`;
  }
  function drawMora(ctx, cx, cy, onLine = false) {
    const dotX = cx + ss(ctx, METRICS.moraOffsetX);
    const r = ss(ctx, METRICS.moraRadius);
    const dotY = onLine ? cy - ctx.staffSpace / 2 : cy;
    return `<circle cx="${dotX}" cy="${dotY}" r="${r}" fill="#000"/>`;
  }
  function drawPlica(ctx, cx, cy, direction = "down") {
    const ax = cx + ss(ctx, METRICS.plicaAnchorX);
    const topY = cy - ss(ctx, METRICS.plicaTopY);
    const bottomY = cy + ss(ctx, METRICS.plicaBottomY);
    const x1 = ax;
    const x2 = ax;
    const y1 = direction === "down" ? topY : bottomY;
    const y2 = direction === "down" ? bottomY : topY;
    const bulge = ss(ctx, METRICS.plicaBulge);
    const sw = stroke(ctx, METRICS.plicaStroke, METRICS.plicaStrokeMinPx);
    return `<path d="M ${x1} ${y1} C ${x1 + bulge} ${y1} ${x2 + bulge} ${y2} ${x2} ${y2}" fill="none" stroke="#000" stroke-width="${sw}" stroke-linecap="round"/>`;
  }
  function drawPlicaBarline(ctx, cx, cy, direction = "down", onLine = false) {
    const scale = ctx.staffSpace / BRAVURA_UNITS_PER_SS * 0.7;
    const targetY = onLine ? cy : cy - ctx.staffSpace * 0.5;
    const tx = cx - BRAVURA_CHANT_STROPHICUS.cx * scale;
    const ty = targetY + BRAVURA_CHANT_STROPHICUS.cy * scale;
    return `<path d="${BRAVURA_CHANT_STROPHICUS.path}" fill="#000" transform="translate(${tx}, ${ty}) scale(${scale}, ${-scale})"/>`;
  }
  function noteheadEdgeOffset(ctx, scale = 1) {
    const rx = ss(ctx, METRICS.noteheadRx) * scale;
    const \u03B8 = METRICS.noteheadRotationDeg * Math.PI / 180;
    return { dx: rx * Math.cos(\u03B8), dy: rx * Math.sin(\u03B8) };
  }
  function noteheadRightPoint(ctx, cx, cy, scale = 1) {
    const { dx, dy } = noteheadEdgeOffset(ctx, scale);
    return { x: cx + dx, y: cy + dy };
  }
  function noteheadLeftPoint(ctx, cx, cy, scale = 1) {
    const { dx, dy } = noteheadEdgeOffset(ctx, scale);
    return { x: cx - dx, y: cy - dy };
  }
  function drawLigatureConnector(ctx, fromX, fromY, toX, toY, kind) {
    const sw = stroke(ctx, METRICS.ligatureConnectorStroke, METRICS.ligatureConnectorStrokeMinPx);
    if (kind === "up") {
      return `<line x1="${fromX}" y1="${fromY}" x2="${toX}" y2="${toY}" stroke="#000" stroke-width="${sw}" stroke-linecap="round"/>`;
    }
    if (kind === "down") {
      return `<line x1="${fromX}" y1="${fromY}" x2="${toX}" y2="${toY}" stroke="#000" stroke-width="${sw}" stroke-linecap="round"/>`;
    }
    return "";
  }
  function ligatureConnectorHalfStroke(ctx) {
    return stroke(ctx, METRICS.ligatureConnectorStroke, METRICS.ligatureConnectorStrokeMinPx) / 2;
  }
  function drawStaffLines(ctx, x1, x2, staffBottomY) {
    const sw = stroke(ctx, METRICS.staffLineStroke, METRICS.staffLineStrokeMinPx);
    const parts = [];
    for (let i = 0; i < METRICS.staffLineCount; i++) {
      const y = staffBottomY - i * ctx.staffSpace;
      parts.push(`<line x1="${x1}" y1="${y}" x2="${x2}" y2="${y}" stroke="#000" stroke-width="${sw}"/>`);
    }
    return parts.join("");
  }
  function drawClef(ctx, clef, x, staffBottomY) {
    const lineY = staffBottomY - (clef.line - 1) * ctx.staffSpace;
    const letter = clef.letter.toLowerCase();
    if (letter === "g") {
      const k = ctx.staffSpace / 591;
      const tx = x - 1186 * k;
      const ty = lineY - 8149 * k;
      const pathD = "M 2002,7851 C 1941,7868 1886,7906 1835,7964 C 1784,8023 1759,8088 1759,8158 C 1759,8202 1774,8252 1803,8305 C 1832,8359 1876,8398 1933,8423 C 1952,8427 1961,8437 1961,8451 C 1961,8456 1954,8461 1937,8465 C 1846,8442 1771,8393 1713,8320 C 1655,8246 1625,8162 1623,8066 C 1626,7963 1657,7867 1716,7779 C 1776,7690 1853,7627 1947,7590 L 1878,7235 C 1724,7363 1599,7496 1502,7636 C 1405,7775 1355,7926 1351,8089 C 1353,8162 1368,8233 1396,8301 C 1424,8370 1466,8432 1522,8489 C 1635,8602 1782,8661 1961,8667 C 2022,8663 2087,8652 2157,8634 L 2002,7851 z M 2074,7841 L 2230,8610 C 2384,8548 2461,8413 2461,8207 C 2452,8138 2432,8076 2398,8021 C 2365,7965 2321,7921 2265,7889 C 2209,7857 2146,7841 2074,7841 z M 1869,6801 C 1902,6781 1940,6746 1981,6697 C 2022,6649 2062,6592 2100,6528 C 2139,6463 2170,6397 2193,6330 C 2216,6264 2227,6201 2227,6143 C 2227,6118 2225,6093 2220,6071 C 2216,6035 2205,6007 2186,5988 C 2167,5970 2143,5960 2113,5960 C 2053,5960 1999,5997 1951,6071 C 1914,6135 1883,6211 1861,6297 C 1838,6384 1825,6470 1823,6557 C 1828,6656 1844,6737 1869,6801 z M 1806,6859 C 1761,6697 1736,6532 1731,6364 C 1732,6256 1743,6155 1764,6061 C 1784,5967 1813,5886 1851,5816 C 1888,5746 1931,5693 1979,5657 C 2022,5625 2053,5608 2070,5608 C 2083,5608 2094,5613 2104,5622 C 2114,5631 2127,5646 2143,5666 C 2262,5835 2322,6039 2322,6277 C 2322,6390 2307,6500 2277,6610 C 2248,6719 2205,6823 2148,6920 C 2090,7018 2022,7103 1943,7176 L 2024,7570 C 2068,7565 2098,7561 2115,7561 C 2191,7561 2259,7577 2322,7609 C 2385,7641 2439,7684 2483,7739 C 2527,7793 2561,7855 2585,7925 C 2608,7995 2621,8068 2621,8144 C 2621,8262 2590,8370 2528,8467 C 2466,8564 2373,8635 2248,8681 C 2256,8730 2270,8801 2291,8892 C 2311,8984 2326,9057 2336,9111 C 2346,9165 2350,9217 2350,9268 C 2350,9347 2331,9417 2293,9479 C 2254,9541 2202,9589 2136,9623 C 2071,9657 1999,9674 1921,9674 C 1811,9674 1715,9643 1633,9582 C 1551,9520 1507,9437 1503,9331 C 1506,9284 1517,9240 1537,9198 C 1557,9156 1584,9122 1619,9096 C 1653,9069 1694,9055 1741,9052 C 1780,9052 1817,9063 1852,9084 C 1886,9106 1914,9135 1935,9172 C 1955,9209 1966,9250 1966,9294 C 1966,9353 1946,9403 1906,9444 C 1866,9485 1815,9506 1754,9506 L 1731,9506 C 1770,9566 1834,9597 1923,9597 C 1968,9597 2014,9587 2060,9569 C 2107,9550 2146,9525 2179,9493 C 2212,9461 2234,9427 2243,9391 C 2260,9350 2268,9293 2268,9222 C 2268,9174 2263,9126 2254,9078 C 2245,9031 2231,8968 2212,8890 C 2193,8813 2179,8753 2171,8712 C 2111,8727 2049,8735 1984,8735 C 1875,8735 1772,8713 1675,8668 C 1578,8623 1493,8561 1419,8481 C 1346,8401 1289,8311 1248,8209 C 1208,8108 1187,8002 1186,7892 C 1190,7790 1209,7692 1245,7600 C 1281,7507 1327,7419 1384,7337 C 1441,7255 1500,7180 1561,7113 C 1623,7047 1704,6962 1806,6859 z";
      const svg = `<g transform="translate(${tx},${ty}) scale(${k})"><path d="${pathD}" fill="#000" fill-rule="evenodd"/></g>`;
      const advance = (2621 - 1186) * k + ss(ctx, METRICS.clefPostGap);
      return { svg, advance, minY: lineY + (5608 - 8149) * k, maxY: lineY + (9674 - 8149) * k };
    }
    if (letter === "f") {
      const k = ctx.staffSpace / 591;
      const tx = x - 1239 * k;
      const ty = lineY - 6968 * k;
      const pathD = "M 1239,8245 C 1397,8138 1515,8057 1591,8001 C 1667,7946 1747,7877 1829,7795 C 1911,7713 1980,7620 2036,7517 C 2080,7441 2118,7353 2149,7253 C 2180,7154 2196,7058 2199,6967 C 2199,6882 2188,6801 2165,6725 C 2143,6648 2105,6585 2051,6534 C 1997,6484 1927,6459 1840,6459 C 1756,6459 1677,6476 1603,6509 C 1530,6543 1478,6597 1449,6673 C 1449,6680 1445,6689 1439,6702 C 1441,6718 1449,6730 1464,6739 C 1479,6748 1492,6752 1504,6752 C 1510,6752 1527,6749 1553,6743 C 1580,6737 1602,6733 1620,6733 C 1673,6733 1720,6752 1763,6789 C 1805,6826 1826,6871 1826,6924 C 1826,6962 1815,6998 1794,7031 C 1773,7064 1744,7091 1707,7110 C 1670,7130 1629,7139 1585,7139 C 1505,7139 1437,7115 1381,7066 C 1326,7016 1298,6953 1298,6874 C 1298,6773 1329,6686 1390,6612 C 1452,6538 1530,6483 1626,6446 C 1721,6408 1817,6390 1915,6390 C 2022,6390 2124,6417 2219,6472 C 2315,6526 2390,6601 2446,6694 C 2502,6788 2531,6888 2531,6996 C 2531,7188 2467,7366 2339,7531 C 2211,7696 2053,7839 1864,7961 C 1738,8044 1534,8156 1253,8297 L 1239,8245 z M 2628,6698 C 2628,6662 2641,6632 2667,6608 C 2692,6583 2723,6571 2760,6571 C 2792,6571 2822,6585 2849,6612 C 2876,6638 2889,6669 2889,6703 C 2889,6739 2875,6770 2849,6795 C 2821,6819 2790,6831 2755,6831 C 2718,6831 2688,6819 2664,6792 C 2640,6766 2628,6735 2628,6698 z M 2628,7222 C 2628,7186 2641,7155 2665,7131 C 2690,7106 2721,7094 2760,7094 C 2792,7094 2821,7107 2849,7134 C 2875,7161 2889,7190 2889,7222 C 2889,7261 2876,7292 2851,7317 C 2825,7342 2795,7355 2760,7355 C 2721,7355 2690,7342 2665,7318 C 2641,7294 2628,7262 2628,7222 z";
      const svg = `<g transform="translate(${tx},${ty}) scale(${k})"><path d="${pathD}" fill="#000" fill-rule="evenodd"/></g>`;
      const advance = (2889 - 1239) * k + ss(ctx, METRICS.clefPostGap);
      return { svg, advance, minY: lineY + (6390 - 6968) * k, maxY: lineY + (8297 - 6968) * k };
    }
    if (letter === "c") {
      const scale = ctx.staffSpace / BRAVURA_UNITS_PER_SS;
      const left = x + ss(ctx, METRICS.clefCLeftPadding);
      const svg = `<path d="${BRAVURA_CHANT_C_CLEF.path}" fill="#000" transform="translate(${left}, ${lineY}) scale(${scale}, ${-scale})"/>`;
      const halfH = BRAVURA_CHANT_C_CLEF.halfHeight * scale;
      return { svg, advance: chantCclefAdvance(ctx), minY: lineY - halfH, maxY: lineY + halfH };
    }
    return { svg: "", advance: 0, minY: Infinity, maxY: -Infinity };
  }
  var BRAVURA_BREATH_MARK_COMMA = {
    path: "M72 251C29 251 1 223 1 188C1 154 24 132 57 132C82 132 85 111 85 111C86 107 87 104 87 100C87 86 80 73 71 61C54 39 28 24 26 22C22 20 18 18 18 12L19 11C20 4 23 2 26 2C59 2 110 46 126 71C146 102 152 137 152 166V173C152 220 118 251 72 251Z",
    advance: 153
  };
  var BRAVURA_CHANT_C_CLEF = {
    path: "M69 61c-33 0 -61 -24 -61 -61s28 -61 61 -61s57 24 57 24c3 2 5 3 6 3c2 0 2 -3 2 -3v-128c0 -15 -9 -53 -58 -56h-5c-66 0 -71 79 -71 113v216c0 34 5 113 70 113h6c49 -3 58 -41 58 -56v-128s0 -3 -2 -3c-1 0 -3 1 -6 3c0 0 -24 24 -57 24z",
    advance: 134,
    halfHeight: 221
  };
  var BRAVURA_CHANT_STROPHICUS = {
    path: "M0 -2v4c0 2 3 5 5 7l31 31s4 0 4 -1c13 -21 31 -29 31 -29c5 -2 10 -4 11 -4c27 29 50 69 50 110c0 42 -30 79 -59 106c-10 11 -23 18 -36 26c-1 1 -2 3 -2 5c0 1 0 3 1 4c7 10 22 29 22 29l32 44c2 2 5 3 7 3s4 -1 6 -3c38 -44 60 -103 60 -161c0 -52 -13 -101 -42 -144c-12 -16 -40 -55 -58 -62c-3 -1 -6 -2 -9 -2c-8 0 -19 7 -27 12c-8 8 -24 13 -27 25z",
    cx: 81.5,
    cy: 147
  };
  var BRAVURA_UNITS_PER_SS = 250;
  function chantCclefAdvance(ctx) {
    const scale = ctx.staffSpace / BRAVURA_UNITS_PER_SS;
    return BRAVURA_CHANT_C_CLEF.advance * scale + ss(ctx, METRICS.clefCRightPadding);
  }
  var BRAVURA_ACCIDENTALS = {
    // U+E4B6 articStressAbove — advance 235
    stress: {
      path: "M169 100c24 0 64 -40 64 -64c0 -4 -1 -7 -4 -10c-9 -10 -190 -158 -224 -158c-2 0 -3 0 -4 1c0 0 -1 2 -1 3c0 31 149 214 159 224c3 2 6 4 10 4z",
      advance: 235
    },
    // U+E260 accidentalFlat — advance 226
    flat: {
      path: "M12 -170C15 -174 18 -175 21 -175C24 -175 27 -173 27 -173C57 -156 81 -129 106 -112C195 -50 226 11 226 57C226 114 182 150 136 153C119 153 95 145 81 136C75 131 64 122 59 122C57 122 56 122 54 123C47 126 43 133 43 140C44 162 50 402 50 422C50 433 41 439 31 439C17 439 1 429 0 411C0 411 4 -160 12 -170ZM47 -81C47 -81 44 -21 44 19C44 35 45 47 46 51C53 71 93 100 116 100C145 100 157 67 157 42C157 -12 111 -66 68 -93C64 -95 61 -96 58 -96C49 -96 47 -86 47 -81Z",
      advance: 226
    },
    // U+E261 accidentalNatural — advance 168
    natural: {
      path: "M141 181C139 181 138 180 137 180C137 180 73 157 47 157C41 157 37 158 37 162V329C37 336 31 341 25 341H12C5 341 0 336 0 329V-186C0 -192 3 -195 9 -195L11 -194C12 -194 14 -194 15 -193C29 -187 85 -163 114 -163C124 -163 131 -166 131 -174V-323C131 -330 136 -335 143 -335H156C162 -335 168 -330 168 -323V179C168 184 164 187 160 187C159 187 157 187 156 186ZM37 39C37 53 98 79 122 79C128 79 131 78 131 74V-29C131 -47 74 -70 49 -70C42 -70 37 -68 37 -64Z",
      advance: 168
    },
    // U+E262 accidentalSharp — advance 249
    sharp: {
      path: "M237 118C244 121 249 129 249 135V206C249 211 246 214 242 214C240 214 239 214 237 213C237 213 217 205 212 204C205 204 198 209 198 217V339C198 345 192 350 184 350C174 350 168 345 168 339V209C167 199 164 186 155 180C143 173 109 159 92 155C83 155 80 167 80 175V295C80 301 73 306 66 306C56 306 50 301 50 295V160C50 146 44 136 38 133C32 130 12 122 12 122C5 120 0 112 0 106V35C0 29 3 26 9 26L11 27C12 27 27 33 35 37L36 38C44 38 50 28 50 20V-79C50 -90 45 -99 39 -102C33 -104 12 -113 12 -113C5 -115 0 -123 0 -129V-200C0 -206 3 -209 9 -209L11 -208C12 -208 26 -202 35 -199C36 -198 37 -198 38 -198C45 -198 50 -209 50 -214V-337C50 -343 56 -348 63 -348C73 -348 80 -343 80 -337V-198C80 -185 85 -178 90 -176L151 -151C151 -151 152 -151 152 -151L154 -150C163 -150 168 -162 168 -168V-293C168 -299 174 -304 181 -304C192 -304 198 -299 198 -293V-151C198 -143 202 -131 209 -128C216 -125 237 -117 237 -117C244 -114 249 -106 249 -100V-29C249 -24 246 -21 242 -21C240 -21 239 -21 237 -22L211 -32C205 -32 198 -26 198 -14V79C198 86 203 105 211 108ZM168 -45C162 -65 115 -85 92 -85C86 -85 81 -83 80 -80C78 -76 77 -54 77 -30C77 1 78 36 80 44C82 61 128 82 153 82C160 82 166 80 168 76C170 71 172 46 172 19C172 -8 170 -36 168 -45Z",
      advance: 249
    }
  };
  function drawInlineGlyph(name, x, baselineY, fontSize, color = "#000") {
    const glyph = BRAVURA_ACCIDENTALS[name];
    if (!glyph) return { svg: "", advance: 0 };
    const scale = fontSize / 650;
    return {
      svg: `<path d="${glyph.path}" fill="${escapeAttr(color)}" transform="translate(${x}, ${baselineY - fontSize * 0.25}) scale(${scale}, ${-scale})"/>`,
      advance: glyph.advance * scale
    };
  }
  function drawAccidental(ctx, pitchLetter, kind, x, staffBottomY) {
    const pos = PITCH_BASE[pitchLetter] ?? 4;
    const cy = staffBottomY - pos * ctx.pitchStep;
    const scale = ctx.staffSpace / 250;
    let glyph;
    if (kind === "x") glyph = BRAVURA_ACCIDENTALS.flat;
    else if (kind === "y") glyph = BRAVURA_ACCIDENTALS.natural;
    else if (kind === "#") glyph = BRAVURA_ACCIDENTALS.sharp;
    let svg = "";
    if (glyph) {
      svg = `<path d="${glyph.path}" fill="#000" transform="translate(${x}, ${cy}) scale(${scale}, ${-scale})"/>`;
    }
    return { svg, advance: glyph ? glyph.advance * scale : ss(ctx, METRICS.accidentalAdvanceFlat) };
  }
  function drawBarline(ctx, kind, x, staffBottomY) {
    const top5 = staffBottomY - 4 * ctx.staffSpace;
    const top3 = staffBottomY - 2 * ctx.staffSpace;
    const sw = stroke(ctx, METRICS.barlineStroke, METRICS.barlineStrokeMinPx);
    const lineX = x + ss(ctx, METRICS.barlineOffsetX);
    let svg = "";
    let advance = ss(ctx, METRICS.barlineAdvance);
    if (kind === ",") {
      const y1 = top5 - ctx.staffSpace * 0.5;
      const y2 = top5 + ctx.staffSpace * 0.5;
      svg = `<line x1="${lineX}" y1="${y1}" x2="${lineX}" y2="${y2}" stroke="#000" stroke-width="${sw}"/>`;
    } else if (kind === ",2") {
      svg = `<line x1="${lineX}" y1="${top5}" x2="${lineX}" y2="${top3}" stroke="#000" stroke-width="${sw}"/>`;
    } else if (kind === ";") {
      const y1 = top3 + ctx.staffSpace * 1.5;
      const y2 = top3 - ctx.staffSpace * 1.5;
      svg = `<line x1="${lineX}" y1="${y1}" x2="${lineX}" y2="${y2}" stroke="#000" stroke-width="${sw}"/>`;
    } else if (kind === "|") {
      svg = `<line x1="${lineX}" y1="${top5}" x2="${lineX}" y2="${staffBottomY}" stroke="#000" stroke-width="${sw}"/>`;
    } else if (kind === "|0") {
      const midY = (top5 + staffBottomY) / 2;
      const r = ss(ctx, METRICS.staffLineStroke / 2);
      svg = `<circle cx="${lineX}" cy="${midY}" r="${r}" fill="#000"/>`;
    } else if (kind === "|?") {
      const dotR = ss(ctx, METRICS.barlineRepeatDotRadius);
      const numSpaces = METRICS.staffLineCount - 1;
      const dots = [];
      for (let sp = 0; sp < numSpaces; sp++) {
        const dotY = staffBottomY - (sp + 0.5) * ctx.staffSpace;
        dots.push(`<circle cx="${lineX}" cy="${dotY}" r="${dotR}" fill="#000"/>`);
      }
      svg = dots.join("");
    } else if (kind === "||") {
      const lineX2 = x + ss(ctx, METRICS.barlineDoubleSecondOffsetX);
      svg = `<line x1="${lineX}" y1="${top5}" x2="${lineX}" y2="${staffBottomY}" stroke="#000" stroke-width="${sw}"/><line x1="${lineX2}" y1="${top5}" x2="${lineX2}" y2="${staffBottomY}" stroke="#000" stroke-width="${sw}"/>`;
      advance = ss(ctx, METRICS.barlineDoubleAdvance);
    } else if (kind === ":|") {
      const dotR = ss(ctx, METRICS.barlineRepeatDotRadius);
      const dotGap = ss(ctx, METRICS.barlineRepeatDotGap);
      const thickSw = ss(ctx, METRICS.barlineFinalThickStroke);
      const midY = (top5 + staffBottomY) / 2;
      const dotX = lineX;
      const thinX = lineX + dotGap;
      const thickX = thinX + (ss(ctx, METRICS.barlineDoubleSecondOffsetX) - ss(ctx, METRICS.barlineOffsetX));
      svg = `<circle cx="${dotX}" cy="${midY - ctx.staffSpace * 0.5}" r="${dotR}" fill="#000"/><circle cx="${dotX}" cy="${midY + ctx.staffSpace * 0.5}" r="${dotR}" fill="#000"/><line x1="${thinX}" y1="${top5}" x2="${thinX}" y2="${staffBottomY}" stroke="#000" stroke-width="${sw}"/><line x1="${thickX}" y1="${top5}" x2="${thickX}" y2="${staffBottomY}" stroke="#000" stroke-width="${thickSw}"/>`;
      advance = ss(ctx, METRICS.barlineRepeatAdvance);
    } else if (kind === "|:") {
      const dotR = ss(ctx, METRICS.barlineRepeatDotRadius);
      const dotGap = ss(ctx, METRICS.barlineRepeatDotGap);
      const thickSw = ss(ctx, METRICS.barlineFinalThickStroke);
      const midY = (top5 + staffBottomY) / 2;
      const secondOffset = ss(ctx, METRICS.barlineDoubleSecondOffsetX) - ss(ctx, METRICS.barlineOffsetX);
      const thickX = lineX;
      const thinX = lineX + secondOffset;
      const dotX = thinX + dotGap;
      svg = `<line x1="${thickX}" y1="${top5}" x2="${thickX}" y2="${staffBottomY}" stroke="#000" stroke-width="${thickSw}"/><line x1="${thinX}" y1="${top5}" x2="${thinX}" y2="${staffBottomY}" stroke="#000" stroke-width="${sw}"/><circle cx="${dotX}" cy="${midY - ctx.staffSpace * 0.5}" r="${dotR}" fill="#000"/><circle cx="${dotX}" cy="${midY + ctx.staffSpace * 0.5}" r="${dotR}" fill="#000"/>`;
      advance = ss(ctx, METRICS.barlineRepeatAdvance);
    } else if (kind === ":|:") {
      const dotR = ss(ctx, METRICS.barlineRepeatDotRadius);
      const dotGap = ss(ctx, METRICS.barlineRepeatDotGap);
      const thickSw = ss(ctx, METRICS.barlineFinalThickStroke);
      const midY = (top5 + staffBottomY) / 2;
      const secondOffset = ss(ctx, METRICS.barlineDoubleSecondOffsetX) - ss(ctx, METRICS.barlineOffsetX);
      const dotXL = lineX;
      const thinXL = lineX + dotGap;
      const thickX = thinXL + secondOffset;
      const thinXR = thickX + secondOffset;
      const dotXR = thinXR + dotGap;
      svg = `<circle cx="${dotXL}" cy="${midY - ctx.staffSpace * 0.5}" r="${dotR}" fill="#000"/><circle cx="${dotXL}" cy="${midY + ctx.staffSpace * 0.5}" r="${dotR}" fill="#000"/><line x1="${thinXL}" y1="${top5}" x2="${thinXL}" y2="${staffBottomY}" stroke="#000" stroke-width="${sw}"/><line x1="${thickX}" y1="${top5}" x2="${thickX}" y2="${staffBottomY}" stroke="#000" stroke-width="${thickSw}"/><line x1="${thinXR}" y1="${top5}" x2="${thinXR}" y2="${staffBottomY}" stroke="#000" stroke-width="${sw}"/><circle cx="${dotXR}" cy="${midY - ctx.staffSpace * 0.5}" r="${dotR}" fill="#000"/><circle cx="${dotXR}" cy="${midY + ctx.staffSpace * 0.5}" r="${dotR}" fill="#000"/>`;
      advance = ss(ctx, METRICS.barlineRepeatAdvance) * 1.5;
    } else if (kind === "|||") {
      const thickSw = ss(ctx, METRICS.barlineFinalThickStroke);
      const lineX2 = x + ss(ctx, METRICS.barlineDoubleSecondOffsetX);
      svg = `<line x1="${lineX}" y1="${top5}" x2="${lineX}" y2="${staffBottomY}" stroke="#000" stroke-width="${sw}"/><line x1="${lineX2}" y1="${top5}" x2="${lineX2}" y2="${staffBottomY}" stroke="#000" stroke-width="${thickSw}"/>`;
      advance = ss(ctx, METRICS.barlineDoubleAdvance);
    } else if (kind === "'") {
      const topLineY = staffBottomY - 3.5 * ctx.staffSpace;
      const scale = ctx.staffSpace / 250;
      svg = `<path d="${BRAVURA_BREATH_MARK_COMMA.path}" fill="#000" transform="translate(${lineX}, ${topLineY}) scale(${scale}, ${-scale})"/>`;
    }
    return { svg, advance };
  }
  function drawParenthesis(ctx, hingeX, y1, y2, side) {
    const bulge = ss(ctx, METRICS.parenthesisBulge);
    const cpThickness = ss(ctx, METRICS.parenthesisThickness) * (4 / 3);
    const dir = side === "left" ? -1 : 1;
    const bxOuter = hingeX + dir * bulge;
    const bxInner = bxOuter - dir * cpThickness;
    const d = `M ${hingeX} ${y1} C ${bxOuter} ${y1} ${bxOuter} ${y2} ${hingeX} ${y2} C ${bxInner} ${y2} ${bxInner} ${y1} ${hingeX} ${y1} Z`;
    return `<path d="${d}" fill="#000"/>`;
  }
  function drawOverbrace(ctx, x1, x2, y, isStart = true, isEnd = true) {
    const sw = stroke(ctx, METRICS.overbraceStroke, METRICS.overbraceStrokeMinPx);
    const arm = ss(ctx, METRICS.overbraceArmDepth);
    const tip = ss(ctx, METRICS.overbraceTipDepth);
    const span = Math.max(0, x2 - x1);
    const armWidth = Math.min(arm * 2.5, span / 4);
    const mx = (x1 + x2) / 2;
    let d;
    if (isStart && isEnd) {
      const leftArmX = x1 + armWidth;
      const rightArmX = x2 - armWidth;
      const halfKink = Math.min(ss(ctx, METRICS.overbraceKinkWidth) / 2, Math.max(0, rightArmX - leftArmX) / 2);
      if (halfKink <= 0) {
        d = `M ${x1} ${y + arm} Q ${x1} ${y} ${mx} ${y} Q ${x2} ${y} ${x2} ${y + arm}`;
      } else {
        const leftKinkX = mx - halfKink;
        const rightKinkX = mx + halfKink;
        d = `M ${x1} ${y + arm} Q ${x1} ${y} ${leftArmX} ${y} L ${leftKinkX} ${y} L ${mx - halfKink * 0.45} ${y - tip * 0.45} L ${mx - halfKink * 0.12} ${y - tip * 0.1} L ${mx} ${y - tip} L ${mx + halfKink * 0.45} ${y - tip * 0.45} L ${rightKinkX} ${y} L ${rightArmX} ${y} Q ${x2} ${y} ${x2} ${y + arm}`;
      }
    } else if (isStart) {
      d = `M ${x1} ${y + arm} Q ${x1} ${y} ${x1 + armWidth} ${y} L ${x2} ${y}`;
    } else if (isEnd) {
      d = `M ${x1} ${y} L ${x2 - armWidth} ${y} Q ${x2} ${y} ${x2} ${y + arm}`;
    } else {
      d = `M ${x1} ${y} L ${x2} ${y}`;
    }
    return `<path d="${d}" fill="none" stroke="#000" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round"/>`;
  }
  function drawOverarc(ctx, x1, x2, y) {
    const sw = stroke(ctx, METRICS.overarcStroke, METRICS.overarcStrokeMinPx);
    const bulge = ss(ctx, METRICS.overarcBulge);
    const d = `M ${x1} ${y} C ${x1} ${y - bulge} ${x2} ${y - bulge} ${x2} ${y}`;
    return `<path d="${d}" fill="none" stroke="#000" stroke-width="${sw}" stroke-linecap="round"/>`;
  }
  function drawOverline(ctx, x1, x2, y) {
    const sw = stroke(ctx, METRICS.overarcStroke, METRICS.overarcStrokeMinPx);
    return `<path d="M ${x1} ${y} L ${x2} ${y}" fill="none" stroke="#000" stroke-width="${sw}" stroke-linecap="round"/>`;
  }
  function drawSlur(ctx, x1, x2, y1, y2, dashed, isStart = true, isEnd = true) {
    const sw = stroke(ctx, METRICS.slurStroke, METRICS.slurStrokeMinPx);
    const fullBulge = ss(ctx, METRICS.slurBulge);
    const stubWidth = ss(ctx, METRICS.slurStubWidth);
    let ax1 = x1, ax2 = x2;
    if (isStart && !isEnd) {
      ax2 = Math.min(x2, x1 + stubWidth);
    } else if (!isStart && isEnd) {
      ax1 = Math.max(x1, x2 - stubWidth);
    } else if (!isStart && !isEnd) {
      return "";
    }
    const span = ax2 - ax1;
    const avgY = (y1 + y2) / 2;
    const verticalDiff = Math.abs(y2 - y1);
    const spanFactor = Math.min(1, span / (stubWidth * 1.5));
    const baseBulge = fullBulge * spanFactor;
    const bulge = baseBulge + verticalDiff * 0.33 * spanFactor;
    const d = `M ${ax1} ${y1} C ${ax1} ${avgY + bulge} ${ax2} ${avgY + bulge} ${ax2} ${y2}`;
    let dashAttr = "";
    if (dashed) {
      const dl = ss(ctx, METRICS.slurDashLen);
      const dg = ss(ctx, METRICS.slurDashGap);
      dashAttr = ` stroke-dasharray="${dl},${dg}"`;
    }
    return `<path d="${d}" fill="none" stroke="#000" stroke-width="${sw}" stroke-linecap="round"${dashAttr}/>`;
  }
  function escapeText(s) {
    return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }
  function escapeAttr(s) {
    return attr(s);
  }

  // node_modules/@aretino-chant/core/src/options.js
  var RENDERER_OPTIONS = [
    { name: "width", type: "number", detail: "output width in pixels", default: "auto" },
    { name: "widthMm", type: "number", detail: "output width in mm", default: 180 },
    { name: "dpi", type: "number", detail: "dots per inch", default: 96 },
    { name: "zoom", type: "number", detail: "zoom factor", default: 1 },
    { name: "staffSpaceMm", type: "number", detail: "staff space in mm", default: 1.75 },
    { name: "lyricSize", type: "number", detail: "lyric font size", default: 10 },
    { name: "textFont", type: "string", detail: "rendered text font family", default: "Palatino Linotype" },
    { name: "noteSpacing", type: "number", detail: "spacing between notes", default: 1 },
    { name: "gapOutlierThreshold", type: "number", detail: "gap ratio flagged as an outlier when justifying", default: 2 },
    { name: "avoidLoneSyllables", type: "boolean", detail: "avoid leaving a single syllable at a line break", default: true },
    { name: "gapOutlierThresholdMin", type: "number", detail: "minimum gap ratio considered for outlier detection", default: 1 },
    { name: "wrapCondenseMin", type: "number", detail: "minimum condense ratio allowed when wrapping", default: 0.75 },
    { name: "wrapStretchMax", type: "number", detail: "maximum stretch ratio allowed when wrapping", default: 2 },
    { name: "recitationLoneWordMin", type: "number", detail: "minimum word count before recitation may end on a lone word", default: 2.25 },
    { name: "staffGap", type: "number", detail: "gap between staves", default: 2.5 },
    { name: "lyricDistance", type: "number", detail: "distance from lowest note to lyrics", default: 0.5 },
    { name: "lyricMinStaffDistance", type: "number", detail: "minimum distance from bottom staff line to lyrics", default: 0.75 },
    { name: "lyricLineSkip", type: "number", detail: "line spacing between stacked lyric lines", default: 1.2 },
    { name: "lyricHyphenMinLen", type: "number", detail: "minimum syllable length before a hyphen may be inserted", default: 0.17 },
    { name: "lyricHyphenMaxLen", type: "number", detail: "maximum gap length that still gets a hyphen", default: 0.33 },
    { name: "lyricHyphenWidth", type: "number", detail: "width of an inserted hyphen", default: 0.04 },
    { name: "lyricHyphenSpace", type: "number", detail: "spacing around an inserted hyphen", default: 0.05 },
    { name: "lyricHyphenPos", type: "number", detail: "vertical position of an inserted hyphen", default: 0.55 },
    { name: "lyricHyphenRepeat", type: "number", detail: "minimum spacing between repeated hyphens", default: 4 },
    { name: "virgaStemLength", type: "number", detail: "virga stem descent (staff-spaces)", default: 2.75 },
    { name: "virgaStemDescentBelowPrev", type: "number", detail: "virga stem descent past a lower preceding note", default: 2.25 },
    { name: "virgaMaxBelowBottom", type: "number", detail: "max virga stem descent below bottom staff line", default: 1.75 },
    { name: "hideRepeatClef", type: "boolean", detail: "hide repeated clef at line start", default: false },
    { name: "justifyWithoutLyrics", type: "boolean", detail: "justify neume gaps even without lyrics", default: false },
    { name: "canvasHeight", type: "number", detail: "canvas height", default: "auto" },
    { name: "sourceMap", type: "boolean", detail: "emit source position data for editor sync", default: true },
    { name: "textStyle", type: "string", detail: "named text style preset", default: "psalm" },
    { name: "textMaxIndent", type: "number", detail: "maximum indent for the first music line", default: 8 },
    { name: "textMarkerAlign", type: "string", detail: "alignment of rubric/caption markers", default: "left" }
  ];
  var HEADER_RENDERER_OPTION_TYPES = Object.fromEntries(
    RENDERER_OPTIONS.map(({ name, type }) => [name, type])
  );
  function parseBooleanOption(valueText) {
    const value = valueText.trim().toLowerCase();
    if (value === "true" || value === "1" || value === "yes" || value === "on") {
      return true;
    }
    if (value === "false" || value === "0" || value === "no" || value === "off") {
      return false;
    }
    return null;
  }
  function parseHeaderRendererOption(raw) {
    const text = String(raw ?? "").trim();
    const flag = text.match(/^([A-Za-z][A-Za-z0-9_]*)$/);
    if (flag && HEADER_RENDERER_OPTION_TYPES[flag[1]] === "boolean") {
      return [flag[1], true];
    }
    const m = text.match(/^([A-Za-z][A-Za-z0-9_]*)\s*(?:=|:)\s*(.*)$/);
    if (!m) {
      return null;
    }
    const name = m[1];
    const valueText = m[2].trim();
    const type = HEADER_RENDERER_OPTION_TYPES[name];
    if (!type) {
      return null;
    }
    if (type === "number") {
      if (valueText === "") {
        return null;
      }
      const value = Number(valueText);
      return Number.isFinite(value) ? [name, value] : null;
    }
    if (type === "boolean") {
      const value = parseBooleanOption(valueText);
      return value === null ? null : [name, value];
    }
    return [name, valueText];
  }
  function parseHeaderRendererOptions(ast) {
    const values = [];
    if (Array.isArray(ast?.optionHeaders)) {
      values.push(...ast.optionHeaders);
    }
    if (values.length === 0) {
      const headerOption = ast?.header?.option;
      if (Array.isArray(headerOption)) {
        values.push(...headerOption);
      } else if (typeof headerOption === "string") {
        values.push(headerOption);
      }
    }
    const parsed = {};
    for (const raw of values) {
      const option = parseHeaderRendererOption(raw);
      if (option) {
        parsed[option[0]] = option[1];
      }
    }
    return parsed;
  }

  // node_modules/@aretino-chant/core/src/text.js
  var LITERAL_HYPHEN = "\uE001";
  var LITERAL_OPEN_PAREN = "\uE002";
  var LITERAL_UNDERSCORE = "\uE003";
  var _measureCanvas = null;
  function measureTextWidth(text, fontSize, fontFamily, bold = false, italic = false) {
    if (text === "") {
      return 0;
    }
    if (typeof document !== "undefined") {
      try {
        if (!_measureCanvas) {
          _measureCanvas = document.createElement("canvas");
        }
        const c2d = _measureCanvas.getContext("2d");
        const style = (italic ? "italic " : "") + (bold ? "bold " : "");
        c2d.font = `${style}${fontSize}px ${fontFamily}`;
        return c2d.measureText(text).width;
      } catch (_e) {
      }
    }
    return text.length * fontSize * 0.55 * (bold ? 1.1 : 1) * (italic ? 0.95 : 1);
  }
  var ACCENTED_CAP_ASCENT = 0.95;
  var ASCENDER_ASCENT = 0.75;
  var XHEIGHT_ASCENT = 0.52;
  var LOWER_ASCENDERS = "bdfhkl\xDF";
  function estimateAscentFactor(text) {
    let factor = 0;
    for (const ch of text) {
      const decomposed = ch.normalize("NFD");
      const base = decomposed[0];
      const accented = decomposed.length > 1;
      const upper = base !== base.toLowerCase() && base === base.toUpperCase();
      let f;
      if (upper && accented) {
        f = ACCENTED_CAP_ASCENT;
      } else if (upper || accented || /[0-9]/.test(base) || LOWER_ASCENDERS.includes(base.toLowerCase()) && base === base.toLowerCase() || "([{|/\\!?\u2020\u2021".includes(base)) {
        f = ASCENDER_ASCENT;
      } else if (/[\p{L}\p{N}]/u.test(base)) {
        f = XHEIGHT_ASCENT;
      } else {
        continue;
      }
      if (f > factor) factor = f;
    }
    return factor;
  }
  function measureTextAscent(text, fontSize, fontFamily, bold = false, italic = false) {
    if (text === "") {
      return 0;
    }
    if (typeof document !== "undefined") {
      try {
        if (!_measureCanvas) {
          _measureCanvas = document.createElement("canvas");
        }
        const c2d = _measureCanvas.getContext("2d");
        const style = (italic ? "italic " : "") + (bold ? "bold " : "");
        c2d.font = `${style}${fontSize}px ${fontFamily}`;
        const m = c2d.measureText(text);
        if (m.actualBoundingBoxAscent) {
          return m.actualBoundingBoxAscent;
        }
        if (m.fontBoundingBoxAscent) {
          return m.fontBoundingBoxAscent;
        }
      } catch (_e) {
      }
    }
    return estimateAscentFactor(text) * fontSize;
  }
  function measureXHeight(fontSize, fontFamily) {
    if (typeof document !== "undefined") {
      try {
        if (!_measureCanvas) {
          _measureCanvas = document.createElement("canvas");
        }
        const c2d = _measureCanvas.getContext("2d");
        c2d.font = `${fontSize}px ${fontFamily}`;
        const m = c2d.measureText("x");
        if (m.actualBoundingBoxAscent) {
          return m.actualBoundingBoxAscent;
        }
      } catch (_e) {
      }
    }
    return fontSize * 0.45;
  }
  function segFontSize(seg, fontSize) {
    if (seg.large) return fontSize * 4 / 3;
    if (seg.small) return fontSize * 0.75;
    return fontSize;
  }
  function measureSegmentsWidth(segments, fontSize, fontFamily, measureFn = measureTextWidth) {
    if (!segments || segments.length === 0) return 0;
    return segments.reduce((sum, seg) => {
      if (seg.glyph) return sum + (seg.glyphAdvance || 0) * segFontSize(seg, fontSize) / 1e3;
      return sum + measureFn(seg.text, segFontSize(seg, fontSize), fontFamily, seg.bold, seg.italic);
    }, 0);
  }
  function measureSegmentsAscent(segments, fontSize, fontFamily, ascentFn = measureTextAscent) {
    if (!segments || segments.length === 0) return 0;
    let max = 0;
    for (const seg of segments) {
      const size = segFontSize(seg, fontSize);
      const a = seg.glyph ? size * ASCENDER_ASCENT : ascentFn(seg.text, size, fontFamily, seg.bold, seg.italic);
      if (a > max) max = a;
    }
    return max;
  }
  var GLYPH_PAD = 0.15;
  function measureSegmentsAdvance(segments, fontSize, fontFamily, measureFn = measureTextWidth) {
    if (!segments || segments.length === 0) return 0;
    return segments.reduce((sum, seg) => {
      if (seg.glyph) return sum + (seg.glyphAdvance || 0) * segFontSize(seg, fontSize) / 1e3 + GLYPH_PAD * 1.5 * segFontSize(seg, fontSize);
      return sum + measureFn(seg.text, segFontSize(seg, fontSize), fontFamily, seg.bold, seg.italic);
    }, 0);
  }
  function sliceSegments(segments, startChar) {
    const result = [];
    let pos = 0;
    for (const seg of segments) {
      const segEnd = pos + seg.text.length;
      if (segEnd > startChar) {
        const cutStart = Math.max(pos, startChar) - pos;
        result.push({ ...seg, text: seg.text.slice(cutStart) });
      }
      pos = segEnd;
    }
    return result;
  }
  function trimSegmentsEnd(segments, length) {
    const result = [];
    let pos = 0;
    for (const seg of segments) {
      if (pos >= length) break;
      const segEnd = pos + seg.text.length;
      const cutEnd = Math.min(segEnd, length);
      result.push({ ...seg, text: seg.text.slice(0, cutEnd - pos) });
      pos = segEnd;
    }
    return result;
  }
  function parseFormattingToSegmentsInternal(text, sourceMap = null, options = {}) {
    text = String(text ?? "");
    const withSource = Array.isArray(sourceMap);
    const allowBreaks = !!options.breaks;
    const stack = [{ type: "root", bold: false, italic: false, underline: false, color: null, smallCaps: false, small: false, large: false }];
    const segments = [];
    function sourceAt(idx) {
      const value = sourceMap?.[idx];
      return Number.isFinite(value) ? value : null;
    }
    function effectiveState() {
      const s = { bold: false, italic: false, underline: false, color: null, smallCaps: false, small: false, large: false };
      for (const e of stack) {
        if (e.bold) s.bold = true;
        if (e.italic) s.italic = true;
        if (e.underline) s.underline = true;
        if (e.color !== null) s.color = e.color;
        if (e.smallCaps) s.smallCaps = true;
        if (e.small) s.small = true;
        if (e.large) s.large = true;
      }
      return s;
    }
    function addText(str, offsets = null) {
      if (!str) return;
      const st = effectiveState();
      const sourceOffsets = withSource ? offsets ?? Array.from({ length: str.length }, () => null) : null;
      const last = segments[segments.length - 1];
      if (last && !last.glyph && !last.break && last.bold === st.bold && last.italic === st.italic && last.underline === st.underline && last.color === st.color && last.smallCaps === st.smallCaps && last.small === st.small && last.large === st.large) {
        last.text += str;
        if (withSource) {
          last.sourceOffsets.push(...sourceOffsets);
        }
      } else {
        const segment = { text: str, bold: st.bold, italic: st.italic, underline: st.underline, color: st.color, smallCaps: st.smallCaps, small: st.small, large: st.large };
        if (withSource) {
          segment.sourceOffsets = sourceOffsets.slice();
        }
        segments.push(segment);
      }
    }
    function popType(...types) {
      for (let k = stack.length - 1; k >= 0; k--) {
        if (types.includes(stack[k].type)) {
          stack.splice(k, 1);
          return;
        }
      }
    }
    let i = 0;
    while (i < text.length) {
      if (text[i] === "+" && text[i + 1] === "+") {
        addText("\u2021", [sourceAt(i)]);
        i += 2;
      } else if (text[i] === "+") {
        addText("\u2020", [sourceAt(i)]);
        i++;
      } else if (text[i] === "\\") {
        const slashIdx = i;
        i++;
        if (i >= text.length) {
          addText("\\", [sourceAt(slashIdx)]);
          break;
        }
        if (text[i] === "R") {
          addText("\u211F", [sourceAt(slashIdx) ?? sourceAt(i)]);
          i++;
        } else if (text[i] === "V") {
          addText("\u2123", [sourceAt(slashIdx) ?? sourceAt(i)]);
          i++;
        } else if (text.slice(i, i + 3) === "sc{") {
          stack.push({ type: "command", bold: false, italic: false, underline: false, color: null, smallCaps: true, small: false, large: false });
          i += 3;
        } else if (text.slice(i, i + 6) === "small{") {
          stack.push({ type: "command", bold: false, italic: false, underline: false, color: null, smallCaps: false, small: true, large: false });
          i += 6;
        } else if (text.slice(i, i + 6) === "large{") {
          stack.push({ type: "command", bold: false, italic: false, underline: false, color: null, smallCaps: false, small: false, large: true });
          i += 6;
        } else if (text.slice(i, i + 4) === "red{") {
          stack.push({ type: "command", bold: false, italic: false, underline: false, color: "red", smallCaps: false, small: false, large: false });
          i += 4;
        } else if (text.slice(i, i + 6) === "color:") {
          i += 6;
          const braceIdx = text.indexOf("{", i);
          if (braceIdx >= 0) {
            const colorName = text.slice(i, braceIdx);
            i = braceIdx + 1;
            stack.push({ type: "command", bold: false, italic: false, underline: false, color: colorName, smallCaps: false, small: false, large: false });
          } else {
            addText("\\color:", Array.from({ length: 7 }, (_, k) => sourceAt(slashIdx + k)));
          }
        } else if (text[i] === "-") {
          addText(LITERAL_HYPHEN, [sourceAt(slashIdx) ?? sourceAt(i)]);
          i++;
        } else if (text[i] === "(") {
          addText(LITERAL_OPEN_PAREN, [sourceAt(slashIdx) ?? sourceAt(i)]);
          i++;
        } else if (text[i] === "_") {
          addText(LITERAL_UNDERSCORE, [sourceAt(slashIdx) ?? sourceAt(i)]);
          i++;
        } else if (text[i] === "b" || text[i] === "n" || text[i] === "#" || text[i] === "'") {
          const glyphMap = { b: ["flat", 226], n: ["natural", 168], "#": ["sharp", 249], "'": ["stress", 235] };
          const [glyphName, glyphAdvance] = glyphMap[text[i]];
          const st = effectiveState();
          const seg = { text: "", glyph: glyphName, glyphAdvance, ...st };
          if (withSource) seg.sourceOffsets = [sourceAt(slashIdx) ?? sourceAt(i)];
          segments.push(seg);
          i++;
        } else {
          addText(text[i], [sourceAt(i)]);
          i++;
        }
      } else if (text[i] === "{") {
        stack.push({ type: "brace", bold: true, italic: false, underline: false, color: null });
        i++;
      } else if (text[i] === "}") {
        popType("brace", "command");
        i++;
      } else if (text[i] === "<") {
        stack.push({ type: "angle", bold: false, italic: true, underline: false, color: null });
        i++;
      } else if (text[i] === ">") {
        popType("angle");
        i++;
      } else if (text[i] === "[") {
        stack.push({ type: "bracket", bold: false, italic: false, underline: true, color: null });
        i++;
      } else if (text[i] === "]") {
        popType("bracket");
        i++;
      } else if (text[i] === "|" && allowBreaks) {
        const seg = { text: "", break: true, ...effectiveState() };
        if (withSource) seg.sourceOffsets = [sourceAt(i)];
        segments.push(seg);
        i++;
      } else {
        addText(text[i], [sourceAt(i)]);
        i++;
      }
    }
    return segments.filter((s) => s.text !== "" || s.glyph || s.break);
  }
  function parseFormattingToSegments(text, options = {}) {
    return parseFormattingToSegmentsInternal(text, null, options);
  }
  function parseFormattingToSegmentsWithSource(text, sourceMap, options = {}) {
    return parseFormattingToSegmentsInternal(text, sourceMap, options);
  }
  function renderSegments(segments) {
    if (!segments || segments.length === 0) return "";
    if (segments.every((s) => !s.bold && !s.italic && !s.underline && !s.color && !s.smallCaps && !s.small && !s.large)) {
      return escapeText(segments.map((s) => s.text).join(""));
    }
    return segments.map((s) => {
      let attrs = "";
      if (s.bold) attrs += ' font-weight="bold"';
      if (s.italic) attrs += ' font-style="italic"';
      if (s.color) attrs += ` fill="${escapeAttr(s.color)}"`;
      if (s.smallCaps) attrs += ' font-variant="small-caps"';
      if (s.small && !s.large) attrs += ' style="font-size:0.75em"';
      if (s.large) attrs += ' style="font-size:1.3333333em"';
      if (!attrs) return escapeText(s.text);
      return `<tspan${attrs}>${escapeText(s.text)}</tspan>`;
    }).join("");
  }
  function renderMixedLabel(segments, cx, y, fontSize, fontFamily, textAnchor = "middle", measureFn = measureTextWidth, fill = "#000") {
    if (!segments || segments.length === 0) return "";
    const hasGlyphs = segments.some((s) => s.glyph);
    if (!hasGlyphs) {
      return `<text xml:space="preserve" x="${cx}" y="${y}" font-family="${escapeAttr(fontFamily)}" font-size="${fontSize}" text-anchor="${textAnchor}" fill="${escapeAttr(fill)}">${renderSegments(segments)}</text>`;
    }
    const totalWidth = measureSegmentsWidth(segments, fontSize, fontFamily, measureFn);
    let x = textAnchor === "middle" ? cx - totalWidth / 2 : cx;
    const parts = [];
    let textRun = [];
    let textRunX = x;
    function flushTextRun() {
      if (textRun.length === 0) return;
      const content = renderSegments(textRun);
      if (content) {
        parts.push(`<text xml:space="preserve" x="${textRunX}" y="${y}" font-family="${escapeAttr(fontFamily)}" font-size="${fontSize}" text-anchor="start" fill="${escapeAttr(fill)}">${content}</text>`);
      }
      textRun = [];
    }
    for (const seg of segments) {
      if (seg.glyph) {
        flushTextRun();
        const efs = segFontSize(seg, fontSize);
        const pad = GLYPH_PAD * efs;
        const { svg } = drawInlineGlyph(seg.glyph, x + pad / 2, y, efs, seg.color || fill);
        parts.push(svg);
        x += (seg.glyphAdvance || 0) * efs / 1e3 + pad * 1.5;
      } else {
        if (textRun.length === 0) textRunX = x;
        textRun.push(seg);
        x += measureFn(seg.text, segFontSize(seg, fontSize), fontFamily, seg.bold, seg.italic);
      }
    }
    flushTextRun();
    return parts.join("");
  }
  function renderUnderlines(segments, textX, textY, fontSize, fontFamily, textAnchor, measureFn = measureTextWidth) {
    if (!segments || segments.every((s) => !s.underline)) return "";
    const totalW = measureSegmentsWidth(segments, fontSize, fontFamily, measureFn);
    let x = textAnchor === "middle" ? textX - totalW / 2 : textX;
    const lineY = textY + fontSize * 0.13;
    const strokeW = Math.max(0.4, fontSize * 0.055);
    const lines = [];
    for (const seg of segments) {
      const w = seg.glyph ? (seg.glyphAdvance || 0) * segFontSize(seg, fontSize) / 1e3 : measureFn(seg.text, segFontSize(seg, fontSize), fontFamily, seg.bold, seg.italic);
      if (seg.underline && !seg.glyph) {
        const stroke2 = seg.color || "#000";
        lines.push(`<line x1="${x}" y1="${lineY}" x2="${x + w}" y2="${lineY}" stroke="${escapeAttr(stroke2)}" stroke-width="${strokeW}"/>`);
      }
      x += w;
    }
    return lines.join("");
  }

  // node_modules/@aretino-chant/core/src/svg.js
  function wrapSrc(item, svg, cls, staffBottomY, staffHeight, bboxX, bboxWidth, enabled = true) {
    if (!enabled || item.srcStart === void 0 || item.srcEnd === void 0) {
      return svg;
    }
    const staffAttrs = staffBottomY !== void 0 ? ` data-staff-bottom="${staffBottomY}" data-staff-height="${staffHeight}"` : "";
    const bboxAttrs = bboxX !== void 0 && bboxWidth !== void 0 ? ` data-bbox-x="${bboxX}" data-bbox-width="${bboxWidth}"` : "";
    return `<g class="${cls}" data-src-start="${item.srcStart}" data-src-end="${item.srcEnd}"${staffAttrs}${bboxAttrs}>${svg}</g>`;
  }

  // node_modules/@aretino-chant/core/src/verse.js
  var NBSP = "\xA0";
  var TEXT_STYLE_PRESETS = {
    psalm: {
      breaks: "honour",
      breakIndent: 2,
      wrapIndent: 2,
      lineHeight: 1.1,
      gapWithin: 1.3,
      gapBefore: 1.3,
      gapAfter: 1.3,
      align: "left",
      size: 1,
      color: "#000",
      markerGap: 0.5,
      markerAlign: "left",
      maxIndent: 8
    },
    prose: {
      breaks: "reflow",
      breakIndent: 0,
      wrapIndent: 0,
      lineHeight: 1.25,
      gapWithin: 1.5,
      gapBefore: 1.6,
      gapAfter: 1.6,
      align: "left",
      size: 1,
      color: "#000",
      markerGap: 0.5,
      markerAlign: "left",
      maxIndent: 8
    },
    stanza: {
      breaks: "honour",
      breakIndent: 0,
      wrapIndent: 1.5,
      lineHeight: 1.15,
      gapWithin: 1.6,
      gapBefore: 1.6,
      gapAfter: 1.6,
      align: "left",
      size: 1,
      color: "#000",
      markerGap: 0.5,
      markerAlign: "left",
      maxIndent: 8
    },
    rubric: {
      breaks: "reflow",
      breakIndent: 0,
      wrapIndent: 0,
      lineHeight: 1.1,
      gapWithin: 1.2,
      gapBefore: 1.8,
      gapAfter: 1.6,
      align: "left",
      size: 0.85,
      color: "red",
      markerGap: 0.5,
      markerAlign: "left",
      maxIndent: 8
    }
  };
  var DEFAULT_TEXT_STYLE = "psalm";
  var MAX_INDENT_WIDTH_SHARE = 0.3;
  var MARKER_ALIGNMENTS = ["left", "right"];
  function resolveTextStyleName(name, ctx = {}) {
    if (name && TEXT_STYLE_PRESETS[name]) return name;
    const docDefault = ctx.textStyle;
    if (docDefault && TEXT_STYLE_PRESETS[docDefault]) return docDefault;
    return DEFAULT_TEXT_STYLE;
  }
  function resolveTextStyle(name, ctx = {}) {
    const preset = TEXT_STYLE_PRESETS[name];
    const override = ctx.textStyles?.[name];
    const style = { ...preset, ...override ?? {} };
    if (override?.maxIndent === void 0 && Number.isFinite(ctx.textMaxIndent)) {
      style.maxIndent = ctx.textMaxIndent;
    }
    if (override?.markerAlign === void 0 && MARKER_ALIGNMENTS.includes(ctx.textMarkerAlign)) {
      style.markerAlign = ctx.textMarkerAlign;
    }
    return style;
  }
  var BLANK_FORMAT = { bold: false, italic: false, underline: false, color: null, smallCaps: false, small: false, large: false };
  function charFormat(seg) {
    return {
      bold: seg.bold,
      italic: seg.italic,
      underline: seg.underline,
      color: seg.color,
      smallCaps: seg.smallCaps,
      small: seg.small,
      large: seg.large
    };
  }
  function charsToSegments(chars) {
    const segs = [];
    for (const c of chars) {
      if (c.glyph) {
        segs.push({ text: "", glyph: c.glyph, glyphAdvance: c.glyphAdvance, ...charFormat(c) });
        continue;
      }
      const last = segs[segs.length - 1];
      if (last && !last.glyph && last.bold === c.bold && last.italic === c.italic && last.underline === c.underline && last.color === c.color && last.smallCaps === c.smallCaps && last.small === c.small && last.large === c.large) {
        last.text += c.ch;
      } else {
        segs.push({ text: c.ch, ...charFormat(c) });
      }
    }
    return segs;
  }
  function segmentsToChars(segments) {
    const chars = [];
    for (const seg of segments) {
      if (seg.glyph) {
        chars.push({ glyph: seg.glyph, glyphAdvance: seg.glyphAdvance, ...charFormat(seg) });
      } else if (seg.break) {
        chars.push({ break: true });
      } else {
        for (const ch of seg.text) chars.push({ ch, ...charFormat(seg) });
      }
    }
    return chars;
  }
  function substituteTildes(text) {
    return text.replace(/~~/g, NBSP).replace(/~/g, NBSP);
  }
  function splitMarker(lineText) {
    const idx = lineText.indexOf("~~");
    if (idx < 0) return { marker: null, body: lineText };
    return { marker: lineText.slice(0, idx), body: lineText.slice(idx + 2) };
  }
  function wrapVerseText(lineText, firstX, breakX, wrapX, rightX, fontSize, fontFamily, measureFn = measureTextWidth) {
    const segments = parseFormattingToSegments(substituteTildes(lineText), { breaks: true });
    const chars = segmentsToChars(segments);
    const tokens = [];
    let wordChars = [];
    let pendingSpace = null;
    function flushWord() {
      if (wordChars.length > 0) {
        tokens.push({ chars: wordChars, spaceBefore: pendingSpace });
        wordChars = [];
        pendingSpace = null;
      }
    }
    for (const c of chars) {
      if (c.break) {
        flushWord();
        tokens.push({ break: true });
        pendingSpace = null;
      } else if (c.ch === " ") {
        flushWord();
        pendingSpace = c;
      } else {
        wordChars.push(c);
      }
    }
    flushWord();
    const spaceW = measureFn(" ", fontSize, fontFamily) || fontSize * 0.25;
    const displayLines = [];
    let lineWords = [];
    let lineWidth = 0;
    let currentX = firstX;
    let currentAvailW = rightX - firstX;
    function wordSegments(word) {
      return charsToSegments(word.chars);
    }
    function pushLine(wrapped) {
      const lineChars = [];
      const words = [];
      for (let i = 0; i < lineWords.length; i++) {
        if (i > 0) lineChars.push(lineWords[i].spaceBefore || { ch: " ", ...BLANK_FORMAT });
        lineChars.push(...lineWords[i].chars);
        words.push({ segments: wordSegments(lineWords[i]), width: lineWords[i].width });
      }
      displayLines.push({
        x: currentX,
        availW: currentAvailW,
        segments: charsToSegments(lineChars),
        words,
        width: lineWidth,
        wrapped
      });
      lineWords = [];
      lineWidth = 0;
    }
    for (const token of tokens) {
      if (token.break) {
        pushLine(false);
        currentX = breakX;
        currentAvailW = rightX - breakX;
        continue;
      }
      const wordW = measureSegmentsAdvance(wordSegments(token), fontSize, fontFamily, measureFn);
      token.width = wordW;
      if (lineWords.length === 0) {
        if (wordW > currentAvailW && currentX > wrapX) {
          pushLine(false);
          currentX = wrapX;
          currentAvailW = rightX - wrapX;
        }
        lineWords.push(token);
        lineWidth = wordW;
      } else if (lineWidth + spaceW + wordW > currentAvailW) {
        pushLine(true);
        currentX = wrapX;
        currentAvailW = rightX - wrapX;
        lineWords.push(token);
        lineWidth = wordW;
      } else {
        lineWords.push(token);
        lineWidth += spaceW + wordW;
      }
    }
    if (lineWords.length > 0 || displayLines.length === 0) {
      pushLine(false);
    }
    return displayLines;
  }
  function renderTextRun(segments, x, y, fontSize, fontFamily, fill, measureFn) {
    if (!segments || segments.length === 0) return "";
    if (segments.some((s) => s.glyph)) {
      return renderMixedLabel(segments, x, y, fontSize, fontFamily, "start", measureFn, fill);
    }
    return `<text xml:space="preserve" x="${x}" y="${y}" font-family="${escapeAttr(fontFamily)}" font-size="${fontSize}" fill="${escapeAttr(fill)}">${renderSegments(segments)}</text>`;
  }
  function renderDisplayLine(line, y, fontSize, fontFamily, fill, justify, measureFn) {
    const parts = [];
    if (justify && line.wrapped && line.words.length > 1) {
      const spaceW = measureFn(" ", fontSize, fontFamily) || fontSize * 0.25;
      const gaps = line.words.length - 1;
      const gapW = spaceW + Math.max(0, line.availW - line.width) / gaps;
      let x = line.x;
      for (const word of line.words) {
        parts.push(renderTextRun(word.segments, x, y, fontSize, fontFamily, fill, measureFn));
        parts.push(renderUnderlines(word.segments, x, y, fontSize, fontFamily, "start", measureFn));
        x += word.width + gapW;
      }
      return parts.join("");
    }
    parts.push(renderTextRun(line.segments, line.x, y, fontSize, fontFamily, fill, measureFn));
    parts.push(renderUnderlines(line.segments, line.x, y, fontSize, fontFamily, "start", measureFn));
    return parts.join("");
  }
  function normaliseVerses(verses) {
    return verses.map((v) => Array.isArray(v) ? { lines: v, style: null, spans: [] } : { lines: v.lines ?? [], style: v.style ?? null, spans: v.spans ?? [], srcStart: v.srcStart, srcEnd: v.srcEnd });
  }
  function groupRuns(blocks, ctx) {
    const runs = [];
    for (const block of blocks) {
      const name = resolveTextStyleName(block.style, ctx);
      const last = runs[runs.length - 1];
      if (last && last.name === name) {
        last.blocks.push(block);
      } else {
        runs.push({ name, style: resolveTextStyle(name, ctx), blocks: [block] });
      }
    }
    return runs;
  }
  function renderVerseLines(ctx, verses, leftX, rightX, startY) {
    const fontSize = ctx.lyricSize;
    const fontFamily = ctx.textFont;
    const measureFn = ctx.measureText ?? measureTextWidth;
    const sourceMap = ctx.sourceMap !== false;
    const runs = groupRuns(normaliseVerses(verses), ctx);
    const parts = [];
    const blockExtents = [];
    let y = startY;
    let first = true;
    let prevStyle = null;
    let prevName = null;
    for (const run of runs) {
      const style = run.style;
      const styleSize = fontSize * style.size;
      const markerGapPx = style.markerGap * styleSize;
      const prepared = run.blocks.map((block) => {
        const lines = block.lines.slice();
        const { marker, body } = splitMarker(lines[0] ?? "");
        const markerSegments = marker === null ? null : parseFormattingToSegments(substituteTildes(marker));
        const markerW = markerSegments ? measureSegmentsAdvance(markerSegments, styleSize, fontFamily, measureFn) : 0;
        lines[0] = body;
        return { block, lines, markerSegments, markerW };
      });
      const widestMarker = prepared.reduce((w, p) => Math.max(w, p.markerW), 0);
      const maxIndentPx = Math.min(style.maxIndent * styleSize, MAX_INDENT_WIDTH_SHARE * (rightX - leftX));
      const markerColumn = widestMarker > 0 ? leftX + Math.min(widestMarker + markerGapPx, maxIndentPx) : leftX;
      const breakX = markerColumn + style.breakIndent * styleSize;
      const wrapX = markerColumn + style.wrapIndent * styleSize;
      const justify = style.align === "justify";
      for (const { block, lines, markerSegments, markerW } of prepared) {
        const markerX = style.markerAlign === "right" ? Math.max(leftX, markerColumn - markerGapPx - markerW) : leftX;
        const blockFirstX = markerSegments ? Math.max(markerColumn, markerX + markerW + markerGapPx) : markerColumn;
        const inputs = style.breaks === "reflow" ? [{ text: lines.join(" "), span: { srcStart: block.srcStart, srcEnd: block.srcEnd } }] : lines.map((text, li) => ({ text, span: block.spans[li] ?? {} }));
        const blockParts = [];
        let blockTop = null;
        for (let li = 0; li < inputs.length; li++) {
          const firstX = li === 0 ? blockFirstX : breakX;
          const displayLines = wrapVerseText(inputs[li].text, firstX, breakX, wrapX, rightX, styleSize, fontFamily, measureFn);
          for (let di = 0; di < displayLines.length; di++) {
            const isBlockFirst = li === 0 && di === 0;
            if (isBlockFirst && !first) {
              const seam = prevName === run.name ? style.gapWithin : Math.max(prevStyle.gapAfter, style.gapBefore);
              y += seam * fontSize;
            } else {
              y += style.lineHeight * styleSize;
            }
            if (blockTop === null) blockTop = y - styleSize;
            first = false;
            let lineSvg = renderDisplayLine(displayLines[di], y, styleSize, fontFamily, style.color, justify, measureFn);
            if (isBlockFirst && markerSegments) {
              lineSvg = renderTextRun(markerSegments, markerX, y, styleSize, fontFamily, style.color, measureFn) + renderUnderlines(markerSegments, markerX, y, styleSize, fontFamily, "start", measureFn) + lineSvg;
            }
            if (lineSvg !== "") {
              blockParts.push(wrapSrc(
                inputs[li].span,
                lineSvg,
                `aretino-verse aretino-verse-line aretino-verse-${run.name}`,
                void 0,
                void 0,
                void 0,
                void 0,
                sourceMap
              ));
            }
          }
        }
        const blockSvg = blockParts.join("");
        parts.push(blockSvg);
        blockExtents.push({ svg: blockSvg, top: blockTop ?? y, bottom: y + styleSize * 0.3 });
        prevStyle = style;
        prevName = run.name;
      }
    }
    const lastSize = prevStyle ? fontSize * prevStyle.size : fontSize;
    return { svg: parts.join(""), bottom: y + lastSize * 0.3, blocks: blockExtents };
  }

  // node_modules/@aretino-chant/core/src/lyrics.js
  function lyricText(input) {
    return typeof input === "string" ? input : input?.text ?? "";
  }
  function lyricSourceMap(input) {
    return typeof input === "string" ? null : Array.isArray(input?.sourceMap) ? input.sourceMap : null;
  }
  function sourceSpanFromOffsets(offsets) {
    const real = offsets.filter(Number.isFinite);
    if (real.length === 0) {
      return {};
    }
    return { srcStart: Math.min(...real), srcEnd: Math.max(...real) + 1 };
  }
  var REAL_LYRIC_CHAR = /[\p{L}\p{N}]/u;
  function hasRealLyricText(syl) {
    if (!syl) {
      return false;
    }
    const text = typeof syl === "string" ? syl : syl.text ?? "";
    return REAL_LYRIC_CHAR.test(text);
  }
  function expandSyllablesForLigatures(notes) {
    const expanded = [];
    for (const syl of notes) {
      const n = syl.noteGroupCount || 1;
      const isExtender = (syl.extenderCount || 0) > 0;
      const realLyric = hasRealLyricText(syl);
      syl.realLyric = realLyric;
      expanded.push(syl);
      for (let k = 1; k < n; k++) {
        const isLast = k === n - 1;
        expanded.push({
          text: "",
          alignText: "",
          segments: [],
          alignSegments: [],
          suffixSegments: [],
          realLyric,
          hyphenAfter: isExtender ? false : isLast ? syl.hyphenAfter : true,
          hyphenMandatory: isExtender ? false : syl.hyphenMandatory || false,
          extender: isExtender,
          extenderLast: isExtender && isLast,
          extenderSuffixSegments: isExtender && isLast ? syl.extenderSuffixSegments || [] : [],
          continuation: true,
          kind: "note"
        });
      }
    }
    return expanded;
  }
  function lyricWords(notes) {
    const result = new Array(notes.length).fill(null);
    let wordId = 0;
    let open = null;
    const close = () => {
      if (!open) return;
      for (const i of open.slots) result[i].len = open.pos;
      open = null;
    };
    for (let i = 0; i < notes.length; i++) {
      const syl = notes[i];
      if (!(syl.realLyric ?? hasRealLyricText(syl))) {
        close();
        continue;
      }
      const joined = open && (syl.continuation || notes[i - 1]?.hyphenAfter);
      if (!joined) {
        close();
        open = { id: ++wordId, slots: [], pos: 1 };
      } else if (!syl.continuation) {
        open.pos++;
      }
      open.slots.push(i);
      result[i] = { word: open.id, pos: open.pos, len: 0 };
    }
    close();
    return result;
  }
  function parseSyllables(input) {
    const text = lyricText(input);
    const sourceMap = lyricSourceMap(input);
    const result = [];
    const rawSegments = sourceMap ? parseFormattingToSegmentsWithSource(text || "", sourceMap) : parseFormattingToSegments(text || "");
    let cleaned = "";
    const formatMap = [];
    const cleanedSourceMap = [];
    for (const seg of rawSegments) {
      for (let ci = 0; ci < seg.text.length; ci++) {
        const c = seg.text[ci];
        cleaned += c;
        formatMap.push({ bold: seg.bold, italic: seg.italic, underline: seg.underline, color: seg.color, smallCaps: seg.smallCaps, small: seg.small, large: seg.large });
        cleanedSourceMap.push(seg.sourceOffsets?.[ci] ?? null);
      }
    }
    function sourceSpanForCleanedRange(start, end) {
      return sourceSpanFromOffsets(cleanedSourceMap.slice(start, end));
    }
    function buildSegments(start, end, displayFn) {
      const segments = [];
      if (start >= end) return segments;
      let runStart = start;
      let f0 = formatMap[start] || { bold: false, italic: false, underline: false, color: null, smallCaps: false, small: false, large: false };
      let runBold = f0.bold, runItalic = f0.italic, runUnderline = f0.underline, runColor = f0.color, runSmallCaps = f0.smallCaps, runSmall = f0.small, runLarge = f0.large;
      for (let p = start + 1; p < end; p++) {
        const f = formatMap[p] || { bold: false, italic: false, underline: false, color: null, smallCaps: false, small: false, large: false };
        if (f.bold !== runBold || f.italic !== runItalic || f.underline !== runUnderline || f.color !== runColor || f.smallCaps !== runSmallCaps || f.small !== runSmall || f.large !== runLarge) {
          segments.push({ text: displayFn(cleaned.slice(runStart, p)), bold: runBold, italic: runItalic, underline: runUnderline, color: runColor, smallCaps: runSmallCaps, small: runSmall, large: runLarge });
          runStart = p;
          runBold = f.bold;
          runItalic = f.italic;
          runUnderline = f.underline;
          runColor = f.color;
          runSmallCaps = f.smallCaps;
          runSmall = f.small;
          runLarge = f.large;
        }
      }
      segments.push({ text: displayFn(cleaned.slice(runStart, end)), bold: runBold, italic: runItalic, underline: runUnderline, color: runColor, smallCaps: runSmallCaps, small: runSmall, large: runLarge });
      return segments;
    }
    let i = 0;
    let noteCount = 0;
    while (i < cleaned.length) {
      const ch = cleaned[i];
      if (ch === " " || ch === "	") {
        i++;
        continue;
      }
      if (ch === "(") {
        const end = cleaned.indexOf(")", i);
        const innerStart = i + 1;
        const innerEnd = end < 0 ? cleaned.length : end;
        const fullEnd = end < 0 ? innerEnd : end + 1;
        const segments = buildSegments(innerStart, innerEnd, (s) => s.replace(/~/g, " ").replaceAll(LITERAL_OPEN_PAREN, "("));
        i = end < 0 ? cleaned.length : end + 1;
        result.push({
          text: cleaned.slice(innerStart, innerEnd).replace(/~/g, " ").replaceAll(LITERAL_OPEN_PAREN, "("),
          segments,
          hyphenAfter: false,
          kind: "barline",
          notesBefore: noteCount,
          ...sourceSpanForCleanedRange(innerStart - 1, fullEnd)
        });
        continue;
      }
      const wordChars = [];
      const wordCharIndexes = [];
      let j = i;
      let skipWhitespaceAfterHyphen = false;
      while (j < cleaned.length) {
        const c = cleaned[j];
        if (c === "(") {
          break;
        }
        if (c === " " || c === "	") {
          if (skipWhitespaceAfterHyphen) {
            j++;
            continue;
          }
          let peek = j + 1;
          while (peek < cleaned.length && (cleaned[peek] === " " || cleaned[peek] === "	")) peek++;
          if (peek < cleaned.length && (cleaned[peek] === "-" || cleaned[peek] === "=")) {
            j++;
            continue;
          }
          break;
        }
        wordChars.push(c);
        wordCharIndexes.push(j);
        skipWhitespaceAfterHyphen = c === "-" || c === "=";
        j++;
      }
      const word = wordChars.join("");
      i = j;
      const sylParts = [];
      let wPos = 0;
      while (wPos < word.length) {
        const sylStart = wPos;
        while (wPos < word.length && word[wPos] !== "-" && word[wPos] !== "=" && word[wPos] !== "_") wPos++;
        const sylEnd = wPos;
        let trailingHyphens = 0;
        let hyphenMandatory = false;
        let extenderCount = 0;
        while (wPos < word.length && (word[wPos] === "-" || word[wPos] === "=" || word[wPos] === "_")) {
          if (word[wPos] === "=") {
            hyphenMandatory = true;
            trailingHyphens++;
          } else if (word[wPos] === "_") {
            extenderCount++;
          } else {
            trailingHyphens++;
          }
          wPos++;
        }
        let sufStart = -1;
        let sufEnd = -1;
        if (extenderCount > 0) {
          sufStart = wPos;
          while (wPos < word.length && ".,;:!?".includes(word[wPos])) wPos++;
          sufEnd = wPos;
        }
        if (sylEnd > sylStart) {
          sylParts.push({ raw: word.slice(sylStart, sylEnd), startIdx: sylStart, endIdx: sylEnd, trailingHyphens, hyphenMandatory, extenderCount, sufStart, sufEnd });
        }
      }
      for (const { raw, startIdx, endIdx, trailingHyphens, hyphenMandatory, extenderCount, sufStart, sufEnd } of sylParts) {
        const isExtender = extenderCount > 0;
        const absStart = wordCharIndexes[startIdx];
        const absEnd = wordCharIndexes[endIdx - 1] + 1;
        const sourceSpan = sourceSpanForCleanedRange(absStart, absEnd);
        const tildeIdx = raw.indexOf("~~");
        let text2, alignText;
        if (tildeIdx !== -1) {
          text2 = raw.slice(0, tildeIdx).replace(/~/g, " ").replaceAll(LITERAL_HYPHEN, "-").replaceAll(LITERAL_OPEN_PAREN, "(").replaceAll(LITERAL_UNDERSCORE, "_") + " " + raw.slice(tildeIdx + 2).replace(/~/g, " ").replaceAll(LITERAL_HYPHEN, "-").replaceAll(LITERAL_OPEN_PAREN, "(").replaceAll(LITERAL_UNDERSCORE, "_");
          alignText = raw.slice(tildeIdx + 2).replace(/~/g, " ").replaceAll(LITERAL_HYPHEN, "-").replaceAll(LITERAL_OPEN_PAREN, "(").replaceAll(LITERAL_UNDERSCORE, "_");
        } else {
          text2 = raw.replace(/~/g, " ").replaceAll(LITERAL_HYPHEN, "-").replaceAll(LITERAL_OPEN_PAREN, "(").replaceAll(LITERAL_UNDERSCORE, "_");
          alignText = text2;
        }
        const segments = buildSegments(absStart, absEnd, (s) => s.replace(/~~/g, " ").replace(/~/g, " ").replaceAll(LITERAL_HYPHEN, "-").replaceAll(LITERAL_OPEN_PAREN, "(").replaceAll(LITERAL_UNDERSCORE, "_"));
        let alignSegments = text2 === alignText ? segments : sliceSegments(segments, text2.length - alignText.length);
        const trailingPunctMatch = alignText.match(/[.,;:!?]+$/);
        let suffixSegments = [];
        if (trailingPunctMatch) {
          const coreLen = alignText.length - trailingPunctMatch[0].length;
          suffixSegments = sliceSegments(alignSegments, coreLen);
          alignSegments = trimSegmentsEnd(alignSegments, coreLen);
        }
        let extenderSuffixSegments = [];
        if (isExtender && sufEnd > sufStart) {
          const sufAbsStart = wordCharIndexes[sufStart];
          const sufAbsEnd = wordCharIndexes[sufEnd - 1] + 1;
          extenderSuffixSegments = buildSegments(sufAbsStart, sufAbsEnd, (s) => s.replace(/~/g, " ").replaceAll(LITERAL_HYPHEN, "-").replaceAll(LITERAL_OPEN_PAREN, "(").replaceAll(LITERAL_UNDERSCORE, "_"));
        }
        const groupCount = isExtender ? extenderCount : Math.max(1, trailingHyphens);
        result.push({
          text: text2,
          alignText,
          segments,
          alignSegments,
          suffixSegments,
          hyphenAfter: !isExtender && trailingHyphens > 0,
          hyphenMandatory: !isExtender && trailingHyphens > 0 && hyphenMandatory,
          noteGroupCount: groupCount,
          extenderCount: isExtender ? extenderCount : 0,
          extenderSuffixSegments,
          kind: "note",
          ...sourceSpan
        });
        noteCount += groupCount;
      }
    }
    return result;
  }
  function formatLyricLine(text) {
    return renderSegments(parseFormattingToSegments(lyricText(text)));
  }
  function emitBarlineLabels(ctx, labels, barlines, lyricY) {
    if (labels.length === 0 || barlines.length === 0) {
      return "";
    }
    const fontSize = ctx.lyricSize;
    const fontFamily = ctx.textFont;
    const parts = [];
    const n = Math.min(labels.length, barlines.length);
    for (let i = 0; i < n; i++) {
      const text = labels[i].text;
      if (text === "") {
        continue;
      }
      const cx = barlines[i].centerX;
      const label = labels[i];
      const labelSvg = renderMixedLabel(label.segments, cx, lyricY, fontSize, fontFamily, "middle", ctx.measureText ?? measureTextWidth) + renderUnderlines(label.segments, cx, lyricY, fontSize, fontFamily, "middle", ctx.measureText ?? measureTextWidth);
      parts.push(wrapSrc(label, labelSvg, "aretino-lyric aretino-barline-label", void 0, void 0, void 0, void 0, ctx.sourceMap));
    }
    return parts.join("");
  }
  var HU_DIGRAPHS = ["dzs", "cs", "dz", "gy", "ly", "ny", "sz", "ty", "zs"];
  function modifySegsSuffix(segs, removeCount, appendStr) {
    let result = segs.map((s) => ({ ...s }));
    let rem = removeCount;
    for (let i = result.length - 1; i >= 0 && rem > 0; i--) {
      const len = result[i].text.length;
      if (len <= rem) {
        rem -= len;
        result[i].text = "";
      } else {
        result[i].text = result[i].text.slice(0, len - rem);
        rem = 0;
      }
    }
    result = result.filter((s) => s.text !== "");
    if (appendStr) {
      if (result.length > 0) {
        const last = result[result.length - 1];
        result[result.length - 1] = { ...last, text: last.text + appendStr };
      } else {
        const orig = segs[segs.length - 1] || {};
        result.push({ text: appendStr, bold: orig.bold || false, italic: orig.italic || false, underline: orig.underline || false, color: orig.color || null, smallCaps: orig.smallCaps || false, small: orig.small || false, large: orig.large || false });
      }
    }
    return result;
  }
  function modifySegsPrefix(segs, removeCount) {
    let result = segs.map((s) => ({ ...s }));
    let rem = removeCount;
    for (let i = 0; i < result.length && rem > 0; i++) {
      const len = result[i].text.length;
      if (len <= rem) {
        rem -= len;
        result[i].text = "";
      } else {
        result[i].text = result[i].text.slice(rem);
        rem = 0;
      }
    }
    return result.filter((s) => s.text !== "");
  }
  function hungarianDigraphTransformPair(syl1, syl2) {
    const text1 = syl1.segments.map((s) => s.text).join("");
    const text2 = syl2.segments.map((s) => s.text).join("");
    for (const g of HU_DIGRAPHS) {
      if (text1.endsWith(g) && text2.startsWith(g)) {
        const gRest = g.slice(1);
        const newSegs1 = modifySegsSuffix(syl1.segments, gRest.length, g[0]);
        const newSegs2 = modifySegsPrefix(syl2.segments, 1);
        const oldAlign1 = syl1.alignSegments;
        const oldAlign2 = syl2.alignSegments;
        const newAlign1 = oldAlign1 === syl1.segments ? newSegs1 : modifySegsSuffix(oldAlign1, gRest.length, g[0]);
        const newAlign2 = oldAlign2 === syl2.segments ? newSegs2 : modifySegsPrefix(oldAlign2, 1);
        return [
          { ...syl1, segments: newSegs1, alignSegments: newAlign1 },
          { ...syl2, segments: newSegs2, alignSegments: newAlign2 }
        ];
      }
    }
    return null;
  }
  function hyphenGeometry(ctx) {
    const sz = ctx.lyricSize;
    const min = (ctx.lyricHyphenMinLen ?? METRICS.lyricHyphenMinLen) * sz;
    const max = Math.max(min, (ctx.lyricHyphenMaxLen ?? METRICS.lyricHyphenMaxLen) * sz);
    return {
      min,
      max,
      space: (ctx.lyricHyphenSpace ?? METRICS.lyricHyphenSpace) * sz,
      width: (ctx.lyricHyphenWidth ?? METRICS.lyricHyphenWidth) * sz,
      dy: (ctx.lyricHyphenPos ?? METRICS.lyricHyphenPos) * (ctx.lyricXHeight ?? measureXHeight(sz, ctx.textFont)),
      repeat: (ctx.lyricHyphenRepeat ?? METRICS.lyricHyphenRepeat) * sz
    };
  }
  function hyphenRoom(ctx) {
    const g = hyphenGeometry(ctx);
    return g.min + g.space * 2;
  }
  function drawHyphenStrokes(gapLeft, gapRight, lyricY, g) {
    const w = gapRight - gapLeft;
    const count = Math.floor(w / g.repeat) + 1;
    const len = count > 1 ? g.max : Math.min(Math.max(w - g.space * 2, g.min), g.max);
    const air = (w - count * len) / (count + 1);
    const y = lyricY - g.dy;
    const parts = [];
    let x = gapLeft + air;
    let rightX = x + len;
    for (let i = 0; i < count; i++) {
      parts.push(`<line class="aretino-lyric-hyphen" x1="${x}" y1="${y}" x2="${x + len}" y2="${y}" stroke="#000" stroke-width="${g.width}"/>`);
      rightX = x + len;
      x += len + air;
    }
    return { svg: parts.join(""), rightX };
  }
  function layoutRowSyllables(ctx, syllables, ligatures, rowLeftLimit = -Infinity, melismaCarry = null) {
    const ops = [];
    const spans = [];
    if (syllables.length === 0) {
      if (melismaCarry && melismaCarry.rightX > melismaCarry.leftX + hyphenRoom(ctx)) {
        ops.push({ op: "hyphen", gapLeft: melismaCarry.leftX, gapRight: melismaCarry.rightX });
        return { ops, spans, maxX: melismaCarry.rightX };
      }
      return { ops, spans, maxX: 0 };
    }
    const fontSize = ctx.lyricSize;
    const fontFamily = ctx.textFont;
    const measureFn = ctx.measureText ?? measureTextWidth;
    const ascentFn = ctx.measureAscent ?? measureTextAscent;
    const minGap = measureFn(" ", fontSize, fontFamily) || fontSize * 0.25;
    const hyphenGap = hyphenRoom(ctx);
    const trailingAdvance = fontSize * 0.6;
    const carriesNoText = (syl) => !syl.segments || !syl.segments.some((seg) => seg.glyph || seg.text);
    let prevRight = -Infinity;
    let lastRight = null;
    let pendingHyphenLeft = melismaCarry ? melismaCarry.leftX : null;
    let maxX = 0;
    let prevSylOp = null;
    const workSyllables = syllables.slice();
    let extStartX = null;
    let extEndX = null;
    let extTextRightX = null;
    const extenderGap = fontSize * 0.15;
    const extenderMinLen = fontSize * 0.5;
    const flushExtender = () => {
      let drewLine = false;
      if (extStartX !== null && extEndX !== null && extEndX - extStartX >= extenderMinLen) {
        ops.push({ op: "extender", x1: extStartX, x2: extEndX });
        if (extEndX > maxX) maxX = extEndX;
        drewLine = true;
      }
      extStartX = null;
      extEndX = null;
      extTextRightX = null;
      return drewLine;
    };
    for (let i = 0; i < workSyllables.length; i++) {
      let syl = workSyllables[i];
      let fullW = measureSegmentsWidth(syl.segments, fontSize, fontFamily, measureFn);
      let alignW = measureSegmentsWidth(syl.alignSegments || syl.segments, fontSize, fontFamily, measureFn);
      let suffixW = syl.suffixSegments ? measureSegmentsWidth(syl.suffixSegments, fontSize, fontFamily, measureFn) : 0;
      let prefixW = fullW - alignW - suffixW;
      let center;
      if (i < ligatures.length) {
        const lig = ligatures[i];
        if (lig.shouldAlignLeft) {
          center = lig.leftX + alignW / 2 - ctx.staffSpace * 0.1;
        } else {
          center = lig.centerX;
        }
      } else {
        center = prevRight + trailingAdvance + alignW / 2;
      }
      let left = center - alignW / 2 - prefixW;
      if (i === 0 && left < rowLeftLimit) {
        left = rowLeftLimit;
        center = left + prefixW + alignW / 2;
      }
      let hyphenGapLeft = null;
      if (i > 0 || pendingHyphenLeft !== null) {
        const prevSyl = i > 0 ? workSyllables[i - 1] : null;
        const needsHyphen = prevSyl ? prevSyl.hyphenAfter : true;
        if (needsHyphen) {
          const gapStart = pendingHyphenLeft ?? prevRight;
          if (left - gapStart >= hyphenGap) {
            hyphenGapLeft = gapStart;
          } else if (prevSyl?.hyphenMandatory || pendingHyphenLeft !== null || left - gapStart > hyphenGap * 0.6) {
            left = gapStart + hyphenGap;
            center = left + prefixW + alignW / 2;
            hyphenGapLeft = gapStart;
          } else {
            const transformed = hungarianDigraphTransformPair(workSyllables[i - 1], syl);
            if (transformed) {
              workSyllables[i - 1] = transformed[0];
              syl = transformed[1];
              workSyllables[i] = syl;
              const newFullW1 = measureSegmentsWidth(transformed[0].segments, fontSize, fontFamily, measureFn);
              prevSylOp.syl = transformed[0];
              prevSylOp.right = prevSylOp.left + newFullW1;
              prevSylOp.textCenter = prevSylOp.left + newFullW1 / 2;
              prevSylOp.span.rightX = prevSylOp.right;
              prevSylOp.span.ascent = measureSegmentsAscent(transformed[0].segments, fontSize, fontFamily, ascentFn);
              prevRight = prevSylOp.right;
              fullW = measureSegmentsWidth(syl.segments, fontSize, fontFamily, measureFn);
              alignW = measureSegmentsWidth(syl.alignSegments || syl.segments, fontSize, fontFamily, measureFn);
              suffixW = syl.suffixSegments ? measureSegmentsWidth(syl.suffixSegments, fontSize, fontFamily, measureFn) : 0;
              prefixW = fullW - alignW - suffixW;
            }
            left = prevRight;
            center = left + prefixW + alignW / 2;
          }
        } else if (prevSyl && left < prevRight + minGap) {
          left = prevRight + minGap;
          center = left + prefixW + alignW / 2;
        }
      }
      const right = left + fullW;
      const span = {
        leftX: left,
        rightX: right,
        ascent: measureSegmentsAscent(syl.segments, fontSize, fontFamily, ascentFn)
      };
      if (!carriesNoText(syl)) {
        spans.push(span);
      }
      prevSylOp = {
        op: "syllable",
        syl,
        left,
        right,
        textCenter: left + fullW / 2,
        span
      };
      ops.push(prevSylOp);
      if (hyphenGapLeft !== null && carriesNoText(syl)) {
        pendingHyphenLeft = hyphenGapLeft;
      } else {
        if (hyphenGapLeft !== null) {
          ops.push({ op: "hyphen", gapLeft: hyphenGapLeft, gapRight: left });
        }
        pendingHyphenLeft = null;
      }
      const isExtenderHead = (syl.extenderCount || 0) > 0;
      if (isExtenderHead || syl.extender) {
        const lig = i < ligatures.length ? ligatures[i] : null;
        const ligRight = lig ? lig.rightX ?? lig.centerX : right;
        if (isExtenderHead) {
          extTextRightX = right;
          extStartX = right + extenderGap;
        } else if (extStartX === null) {
          extStartX = lig ? lig.leftX : left;
        }
        extEndX = ligRight;
        const isLast = isExtenderHead ? syl.extenderCount === 1 : syl.extenderLast;
        if (isLast) {
          const suf = syl.extenderSuffixSegments || [];
          const targetRight = extEndX;
          const sufW = measureSegmentsWidth(suf, fontSize, fontFamily, measureFn);
          if (sufW > 0 && targetRight !== null) {
            extEndX = targetRight - sufW - extenderGap;
          }
          const textRight = extTextRightX;
          const drewLine = flushExtender();
          if (suf.length) {
            const sx = drewLine ? targetRight : textRight ?? targetRight ?? right;
            const anchor = drewLine ? "end" : "start";
            ops.push({ op: "suffix", x: sx, anchor, segments: suf });
            const suffixRight = drewLine ? sx : sx + sufW;
            if (suffixRight > maxX) maxX = suffixRight;
          }
        }
      }
      prevRight = right;
      lastRight = right;
      if (right > maxX) maxX = right;
    }
    flushExtender();
    const lastIdx = workSyllables.length - 1;
    const lastSyl = workSyllables[lastIdx];
    if (lastSyl && lastSyl.hyphenAfter && lastRight !== null) {
      const lastLig = lastIdx < ligatures.length ? ligatures[lastIdx] : null;
      const ligRight = lastLig ? lastLig.rightX ?? lastLig.centerX : -Infinity;
      ops.push({
        op: "hyphen",
        gapLeft: pendingHyphenLeft ?? lastRight,
        gapRight: Math.max(lastRight + hyphenGap, ligRight)
      });
    }
    return { ops, spans, maxX };
  }
  function emitLaidOutSyllables(ctx, layout, lyricY) {
    const fontSize = ctx.lyricSize;
    const fontFamily = ctx.textFont;
    const fontAttr = escapeAttr(fontFamily);
    const measureFn = ctx.measureText ?? measureTextWidth;
    const geom = hyphenGeometry(ctx);
    const extenderStrokeW = Math.max(0.5, fontSize * 0.06);
    const parts = [];
    let maxX = layout.maxX;
    for (const op of layout.ops) {
      if (op.op === "syllable") {
        const svg = `<text xml:space="preserve" x="${op.textCenter}" y="${lyricY}" font-family="${fontAttr}" font-size="${fontSize}" text-anchor="middle" fill="#000">${renderSegments(op.syl.segments)}</text>` + renderUnderlines(op.syl.segments, op.textCenter, lyricY, fontSize, fontFamily, "middle", measureFn);
        parts.push(wrapSrc(op.syl, svg, "aretino-lyric aretino-syllable", void 0, void 0, void 0, void 0, ctx.sourceMap));
      } else if (op.op === "hyphen") {
        const drawn = drawHyphenStrokes(op.gapLeft, op.gapRight, lyricY, geom);
        parts.push(drawn.svg);
        if (drawn.rightX > maxX) maxX = drawn.rightX;
      } else if (op.op === "extender") {
        parts.push(`<line class="aretino-lyric-extender" x1="${op.x1}" y1="${lyricY}" x2="${op.x2}" y2="${lyricY}" stroke="#000" stroke-width="${extenderStrokeW}"/>`);
      } else if (op.op === "suffix") {
        parts.push(`<text xml:space="preserve" x="${op.x}" y="${lyricY}" font-family="${fontAttr}" font-size="${fontSize}" text-anchor="${op.anchor}" fill="#000">${renderSegments(op.segments)}</text>`);
      }
    }
    return { svg: parts.join(""), maxX };
  }

  // node_modules/@aretino-chant/core/src/units.js
  function ss2(ctx, n) {
    return n * ctx.staffSpace;
  }

  // node_modules/@aretino-chant/core/src/accidentals.js
  function ss3(ctx, n) {
    return n * ctx.staffSpace;
  }
  function accidentalSymbolAdvance(ctx, symbol) {
    if (symbol === "y") return ss3(ctx, METRICS.accidentalAdvanceNatural);
    if (symbol === "#") return ss3(ctx, METRICS.accidentalAdvanceSharp);
    return ss3(ctx, METRICS.accidentalAdvanceFlat);
  }
  function accidentalAdvance(ctx, acc) {
    return accidentalSymbolAdvance(ctx, acc.symbol);
  }
  function accidentalListAdvance(ctx, accidentals) {
    if (!accidentals?.length) {
      return 0;
    }
    return accidentals.reduce((sum, acc) => sum + accidentalAdvance(ctx, acc), 0);
  }
  function keySigAdvance(ctx, accidentals) {
    if (!accidentals?.length) return 0;
    return accidentals.reduce((sum, acc) => sum + accidentalSymbolAdvance(ctx, acc.symbol), 0);
  }
  function accidentalKey(acc) {
    return `${pitchToPos(acc)}`;
  }
  function noteAccidentalKey(note) {
    return `${pitchToPos(note)}`;
  }
  function copyAccidental(acc) {
    return { pitch: acc.pitch, symbol: acc.symbol };
  }
  function setActiveAccidental(active, acc) {
    active.set(accidentalKey(acc), copyAccidental(acc));
  }
  function clearCourtesyAccidentals(items) {
    for (const item of items) {
      if (item.kind === "ligature") {
        delete item.leadingCourtesyAccidentals;
      }
    }
  }
  function courtesySignature(items) {
    return items.map((item, idx) => {
      if (item.kind !== "ligature" || !item.leadingCourtesyAccidentals?.length) {
        return "";
      }
      const keys = item.leadingCourtesyAccidentals.map((acc) => `${accidentalKey(acc)}=${acc.symbol}`).join(",");
      return `${idx}:${keys}`;
    }).filter(Boolean).join("|");
  }
  function updateActiveAccidentalsFromLigature(ligature, active, pendingCourtesy = null) {
    const courtesyByKey = /* @__PURE__ */ new Map();
    for (const group of ligature.groups) {
      for (const note of group) {
        if (note.accidental) {
          const key = accidentalKey(note.accidental);
          pendingCourtesy?.delete(key);
          setActiveAccidental(active, note.accidental);
        }
        const noteKey = noteAccidentalKey(note);
        if (pendingCourtesy?.has(noteKey) && !courtesyByKey.has(noteKey)) {
          courtesyByKey.set(noteKey, copyAccidental(pendingCourtesy.get(noteKey)));
          pendingCourtesy.delete(noteKey);
        }
      }
    }
    return Array.from(courtesyByKey.values());
  }
  function annotateCourtesyAccidentals(items, rows) {
    clearCourtesyAccidentals(items);
    const active = /* @__PURE__ */ new Map();
    for (let rowIdx = 0; rowIdx < rows.length; rowIdx++) {
      const row = rows[rowIdx];
      const pendingCourtesy = rowIdx === 0 ? /* @__PURE__ */ new Map() : new Map(active);
      for (const item of row.items) {
        if (item.kind === "barline") {
          active.clear();
          pendingCourtesy.clear();
          continue;
        }
        if (item.kind === "accidental") {
          pendingCourtesy.delete(accidentalKey(item));
          setActiveAccidental(active, item);
          continue;
        }
        if (item.kind === "ligature") {
          const courtesy = updateActiveAccidentalsFromLigature(item, active, pendingCourtesy);
          if (courtesy.length > 0) {
            item.leadingCourtesyAccidentals = courtesy;
          }
        }
      }
    }
    return courtesySignature(items);
  }

  // node_modules/@aretino-chant/core/src/clef.js
  function clefAdvance(ctx, clef) {
    const letter = (clef.letter || "g").toLowerCase();
    const k = ctx.staffSpace / 591;
    if (letter === "g") {
      return (2621 - 1186) * k + ss2(ctx, METRICS.clefPostGap);
    }
    if (letter === "f") {
      return (2889 - 1239) * k + ss2(ctx, METRICS.clefPostGap);
    }
    if (letter === "c") {
      return chantCclefAdvance(ctx);
    }
    return 0;
  }
  function clefInkRightOffset(ctx, clef) {
    const letter = (clef.letter || "g").toLowerCase();
    if (letter === "c") {
      return chantCclefAdvance(ctx) - ss2(ctx, METRICS.clefCRightPadding) + ss2(ctx, METRICS.clefCLeftPadding);
    }
    return clefAdvance(ctx, clef) - ss2(ctx, METRICS.clefPostGap);
  }
  function trailingClef(items, fallback) {
    for (let i = items.length - 1; i >= 0; i--) {
      if (items[i].kind === "clef") {
        return items[i].clef;
      }
    }
    return fallback;
  }
  function trailingKeySig(items, fallback) {
    for (let i = items.length - 1; i >= 0; i--) {
      if (items[i].kind === "keysig") {
        return items[i].accidentals;
      }
    }
    return fallback;
  }

  // node_modules/@aretino-chant/core/src/measure.js
  function splitGroupsAtInternalMora(groups, gaps = []) {
    const resultGroups = [];
    const resultGaps = [];
    for (let gi = 0; gi < groups.length; gi++) {
      const group = groups[gi];
      let current = [];
      for (let i = 0; i < group.length; i++) {
        current.push(group[i]);
        const hasMora = group[i].modifiers && group[i].modifiers.includes("mora");
        if (i < group.length - 1 && hasMora) {
          const isSecondToLast = i === group.length - 2;
          const nextHasMora = isSecondToLast && group[i + 1].modifiers && group[i + 1].modifiers.includes("mora");
          if (!nextHasMora) {
            resultGroups.push(current);
            resultGaps.push("mora");
            current = [];
          }
        }
      }
      if (current.length > 0) {
        resultGroups.push(current);
        if (gi < groups.length - 1) {
          resultGaps.push(gaps[gi] ?? 1);
        }
      }
    }
    return { groups: resultGroups, gaps: resultGaps };
  }
  function splitGroupsAtPlica(groups, gaps = []) {
    const resultGroups = [];
    const resultGaps = [];
    for (let gi = 0; gi < groups.length; gi++) {
      const group = groups[gi];
      let current = [];
      for (let i = 0; i < group.length; i++) {
        current.push(group[i]);
        const hasPlica = group[i].modifiers && group[i].modifiers.includes("plica");
        if (i < group.length - 1 && hasPlica) {
          resultGroups.push(current);
          resultGaps.push(1);
          current = [];
        }
      }
      if (current.length > 0) {
        resultGroups.push(current);
        if (gi < groups.length - 1) {
          resultGaps.push(gaps[gi] ?? 1);
        }
      }
    }
    return { groups: resultGroups, gaps: resultGaps };
  }
  function measureLigature(ctx, groups, gaps = []) {
    const split = splitGroupsAtInternalMora(groups, gaps);
    return measureSplitLigature(ctx, split.groups, split.gaps);
  }
  function measureLigatureVisualRight(ctx, groups, gaps = []) {
    const split = splitGroupsAtInternalMora(groups, gaps);
    groups = split.groups;
    gaps = split.gaps;
    const halfNoteW = ss2(ctx, METRICS.noteBoxWidth) * 0.5;
    let groupStartX = 0;
    let lastNoteCx = null;
    for (let g = 0; g < groups.length; g++) {
      const notes = groups[g];
      let cx = groupStartX + halfNoteW;
      for (let i = 0; i < notes.length; i++) {
        const note = notes[i];
        if (note.accidental) {
          cx += accidentalSymbolAdvance(ctx, note.accidental.symbol);
        }
        lastNoteCx = cx;
        if (i < notes.length - 1) {
          cx += ctx.ligatureStepAdvance;
        }
      }
      if (g < groups.length - 1) {
        const gapType = gaps[g] ?? 1;
        const slashCount = typeof gapType === "number" ? gapType : 0;
        const lastNote2 = notes[notes.length - 1];
        const hasMora2 = lastNote2.modifiers && lastNote2.modifiers.includes("mora");
        const moraNoteCount = notes.filter((note) => note.modifiers && note.modifiers.includes("mora")).length;
        const moraOverhang = hasMora2 || moraNoteCount >= 2 ? ss2(ctx, METRICS.moraOffsetX + METRICS.moraRadius) : 0;
        const accExtra = notes.reduce((sum, note) => sum + (note.accidental ? accidentalSymbolAdvance(ctx, note.accidental.symbol) : 0), 0);
        groupStartX += ss2(ctx, METRICS.noteBoxWidth) + (notes.length - 1) * ctx.ligatureStepAdvance + slashCount * ctx.neumeGapAdvance + moraOverhang + accExtra;
      }
    }
    if (lastNoteCx === null) {
      return 0;
    }
    const lastGroup = groups[groups.length - 1];
    const lastNote = lastGroup?.[lastGroup.length - 1];
    const lastNoteHasMora = lastNote?.modifiers?.includes("mora");
    const allMoraNoteCount = groups.reduce((sum, group) => sum + group.filter((note) => note.modifiers?.includes("mora")).length, 0);
    const hasMora = lastNoteHasMora || allMoraNoteCount >= 2;
    return lastNoteCx + ss2(ctx, hasMora ? METRICS.moraOffsetX + METRICS.moraRadius : METRICS.noteBoxWidth * 0.5);
  }
  function measureSplitLigature(ctx, groups, gaps) {
    let total = 0;
    for (let g = 0; g < groups.length; g++) {
      const notes = groups[g];
      const n = notes.length;
      const accExtra = notes.reduce((sum, note) => sum + (note.accidental ? accidentalSymbolAdvance(ctx, note.accidental.symbol) : 0), 0);
      if (g < groups.length - 1) {
        const gapType = gaps[g] ?? 1;
        const slashCount = typeof gapType === "number" ? gapType : 0;
        const lastNote = notes[n - 1];
        const hasMora = lastNote.modifiers && lastNote.modifiers.includes("mora");
        const moraNoteCount = notes.filter((note) => note.modifiers && note.modifiers.includes("mora")).length;
        const moraOverhang = hasMora || moraNoteCount >= 2 ? ss2(ctx, METRICS.moraOffsetX + METRICS.moraRadius) : 0;
        total += ss2(ctx, METRICS.noteBoxWidth) + (n - 1) * ctx.ligatureStepAdvance + slashCount * ctx.neumeGapAdvance + moraOverhang + accExtra;
      } else {
        const lastNote = notes[n - 1];
        const hasMora = lastNote.modifiers && lastNote.modifiers.includes("mora");
        const moraNoteCount = notes.filter((note) => note.modifiers && note.modifiers.includes("mora")).length;
        const moraExtra = hasMora || moraNoteCount >= 2 ? ss2(ctx, METRICS.moraOffsetX + METRICS.moraRadius) : 0;
        const hasTenor = notes.some((n2) => n2.shape === "tenor");
        const tenorExtra = hasTenor ? ss2(ctx, METRICS.tenorAdvanceExtra) : 0;
        total += ctx.singleNoteAdvance + (n - 1) * ctx.ligatureStepAdvance + moraExtra + accExtra + tenorExtra;
      }
    }
    return total;
  }
  function measureBarline(ctx, kind) {
    if (kind === ":|:") {
      return ss2(ctx, METRICS.barlineDoubleAdvance) * 1.5 + ss2(ctx, METRICS.barlinePostGap);
    }
    const base = kind === "||" || kind === ":|" || kind === "|:" || kind === "|||" ? ss2(ctx, METRICS.barlineDoubleAdvance) : ss2(ctx, METRICS.barlineAdvance);
    return base + ss2(ctx, METRICS.barlinePostGap);
  }
  function lyricBearing(it) {
    return it.kind === "ligature" && it.hasLyric === true;
  }
  function isLeveledGap(it, next) {
    if (it.kind === "accidental" && next.kind === "ligature") return false;
    if (it.kind === "brace-open" || it.kind === "brace-close" || it.kind === "spacer") return false;
    if (it.kind === "paren-open" || next.kind === "paren-close") return false;
    if (it.recitationChainId != null && next.recitationChainId === it.recitationChainId) return false;
    if (!lyricBearing(it) && !lyricBearing(next)) return false;
    return true;
  }
  function gapFloor(ctx, it, next) {
    let f = 0;
    if (it.kind === "ligature") f += it.syllableExtra || 0;
    else if (it.kind === "barline") f += ss2(ctx, METRICS.barlinePostGap) + (it.barlineExtra || 0) / 2 + (it.barlinePostExtra || 0);
    else if (it.kind === "clef") f += ss2(ctx, METRICS.clefInlinePostGap);
    else if (it.kind === "keysig" && it.accidentals.length) f += ss2(ctx, METRICS.keySigInlinePostGap);
    if (next.kind === "barline") f += (next.barlineExtra || 0) / 2;
    return f;
  }
  function isLevelingTargetGap(it, next) {
    return isLeveledGap(it, next) && it.kind !== "barline" && next.kind !== "barline";
  }
  function levelingTarget(ctx, targetFloors, thresholdSS = ctx.gapOutlierThreshold ?? METRICS.gapOutlierThreshold) {
    if (targetFloors.length === 0) return 0;
    const threshold = ss2(ctx, thresholdSS);
    const below = targetFloors.filter((f) => f <= threshold);
    return below.length ? Math.max(...below) : Math.min(...targetFloors);
  }
  function levelingNeed(ctx, rowItems, thresholdSS) {
    const floors = [];
    const targetFloors = [];
    for (let i = 0; i < rowItems.length - 1; i++) {
      const it = rowItems[i];
      const next = rowItems[i + 1];
      if (!isLeveledGap(it, next)) continue;
      const f = gapFloor(ctx, it, next);
      floors.push(f);
      if (isLevelingTargetGap(it, next)) targetFloors.push(f);
    }
    if (floors.length === 0) return 0;
    const top = levelingTarget(ctx, targetFloors, thresholdSS);
    return floors.reduce((s, f) => s + Math.max(0, top - f), 0);
  }
  function levelingTargetFloors(ctx, rowItems) {
    const targetFloors = [];
    for (let i = 0; i < rowItems.length - 1; i++) {
      if (isLevelingTargetGap(rowItems[i], rowItems[i + 1])) {
        targetFloors.push(gapFloor(ctx, rowItems[i], rowItems[i + 1]));
      }
    }
    return targetFloors;
  }
  function breakViolations(left, right) {
    const lw = left?.lyricWord;
    const rw = right?.lyricWord;
    if (!lw || !rw) return 0;
    let count = 0;
    for (let s = 0; s < lw.length; s++) {
      const a = lw[s];
      const b = rw[s];
      if (!a || !b || a.word !== b.word) continue;
      const after = a.len - a.pos;
      if (after === 0) continue;
      if (a.pos === 1) count++;
      if (after === 1) count++;
    }
    return count;
  }
  function naturalNeumeWhite(ctx) {
    return ctx.singleNoteAdvance - ss2(ctx, METRICS.noteBoxWidth);
  }
  function condenseCaps(ctx, rowItems) {
    const limit = Math.max(0, 1 - (ctx.wrapCondenseMin ?? METRICS.wrapCondenseMin)) * naturalNeumeWhite(ctx);
    const caps = new Array(rowItems.length).fill(0);
    for (let i = 0; i < rowItems.length - 1; i++) {
      const it = rowItems[i];
      if (it.kind !== "ligature" || it.recitationGlyphless || it.syllableNeed == null) continue;
      if (!isLevelingTargetGap(it, rowItems[i + 1])) continue;
      const width = measureItem(ctx, it) - accidentalListAdvance(ctx, it.leadingCourtesyAccidentals);
      caps[i] = Math.max(0, Math.min(width - it.syllableNeed, limit));
    }
    return caps;
  }
  function condenseGaps(ctx, rowItems, deficit) {
    const caps = condenseCaps(ctx, rowItems);
    const cuts = new Array(rowItems.length).fill(0);
    if (deficit <= 0) return { cuts, delta: 0 };
    const total = caps.reduce((s, c) => s + c, 0);
    if (total + 1e-9 < deficit) return null;
    const sorted = caps.filter((c) => c > 0).sort((a, b) => a - b);
    let remaining = deficit;
    let delta = 0;
    for (let i = 0; i < sorted.length; i++) {
      const open = sorted.length - i;
      const step = sorted[i] - delta;
      if (step * open >= remaining) {
        delta += remaining / open;
        remaining = 0;
        break;
      }
      remaining -= step * open;
      delta = sorted[i];
    }
    for (let i = 0; i < caps.length; i++) cuts[i] = Math.min(caps[i], delta);
    return { cuts, delta };
  }
  function measureItem(ctx, item) {
    if (item.kind === "clef") {
      return clefAdvance(ctx, item.clef) + ss2(ctx, METRICS.clefInlinePostGap);
    }
    if (item.kind === "accidental") {
      if (item.symbol === "x") return ss2(ctx, METRICS.accidentalAdvanceFlat);
      if (item.symbol === "y") return ss2(ctx, METRICS.accidentalAdvanceNatural);
      if (item.symbol === "#") return ss2(ctx, METRICS.accidentalAdvanceSharp);
      return ss2(ctx, METRICS.accidentalAdvanceFlat);
    }
    if (item.kind === "keysig") {
      return keySigAdvance(ctx, item.accidentals) + (item.accidentals?.length ? ss2(ctx, METRICS.keySigInlinePostGap) : 0);
    }
    if (item.kind === "barline") {
      return measureBarline(ctx, item.value) + (item.barlineExtra || 0) + (item.barlinePostExtra || 0);
    }
    if (item.kind === "spacer") {
      return ss2(ctx, METRICS.spacerAdvance) * item.multiplier;
    }
    if (item.kind === "expander") {
      return ctx.expanderWidth;
    }
    if (item.kind === "paren-open" || item.kind === "paren-close") {
      return ss2(ctx, METRICS.parenthesisWidth) + ss2(ctx, METRICS.parenthesisInnerGap);
    }
    if (item.kind === "brace-open" || item.kind === "brace-close") {
      return 0;
    }
    if (item.kind === "ligature") {
      if (item.recitationGlyphless) {
        return item.syllableExtra || 0;
      }
      return accidentalListAdvance(ctx, item.leadingCourtesyAccidentals) + measureLigature(ctx, item.groups, item.gaps ?? []) + (item.syllableExtra || 0);
    }
    return 0;
  }
  function ligatureLowestInkY(ctx, item, staffBottomY) {
    const { groups } = splitGroupsAtInternalMora(item.groups, item.gaps ?? []);
    let maxY = -Infinity;
    for (const notes of groups) {
      const autoVirga = computeAutoVirga(notes);
      let prevCy = null;
      for (let i = 0; i < notes.length; i++) {
        const cy = pitchY(ctx, notes[i], staffBottomY);
        const drawnNote = autoVirga[i] ? { ...notes[i], virga: true } : notes[i];
        const bounds = noteInkBounds(ctx, drawnNote, cy, staffBottomY, prevCy);
        if (bounds.maxY > maxY) maxY = bounds.maxY;
        prevCy = cy;
      }
    }
    return maxY;
  }
  function rowLowestNoteY(ctx, row, staffBottomY) {
    let maxY = staffBottomY;
    for (const it of row.items) {
      if (it.kind !== "ligature") {
        continue;
      }
      const y = ligatureLowestInkY(ctx, it, staffBottomY);
      if (y > maxY) maxY = y;
    }
    return maxY;
  }
  function firstLyricBaselineY(ctx, spans, inkSpans, staffBottomY, rowLowestY, fallbackAscent) {
    const floor = staffBottomY + ctx.lyricMinStaffDistance;
    if (!spans || spans.length === 0) {
      const top = Math.max(
        (rowLowestY > staffBottomY ? rowLowestY : staffBottomY) + ctx.lyricDistance,
        floor
      );
      return top + fallbackAscent;
    }
    let baseline = -Infinity;
    for (const span of spans) {
      let ink = staffBottomY;
      for (const s of inkSpans) {
        if (s.rightX < span.leftX || s.leftX > span.rightX) {
          continue;
        }
        if (s.maxY > ink) ink = s.maxY;
      }
      const top = Math.max(ink + ctx.lyricDistance, floor);
      const need = top + span.ascent;
      if (need > baseline) baseline = need;
    }
    return baseline;
  }

  // node_modules/@aretino-chant/core/src/items.js
  function groupSections(lines) {
    const sections = [];
    let pending = null;
    function flushPending() {
      if (pending && (pending.tokens.length > 0 || pending.lyrics.length > 0 || pending.verses.length > 0)) {
        sections.push(pending);
      }
      pending = null;
    }
    for (const item of lines) {
      if (item.type === "blank") {
        flushPending();
        continue;
      }
      if (!pending) {
        pending = { tokens: [], lyrics: [], verses: [] };
      }
      if (item.type === "music") {
        pending.tokens.push(...item.tokens);
      } else if (item.type === "lyrics") {
        pending.lyrics.push(item);
      } else if (item.type === "verse") {
        pending.verses.push(item);
      }
    }
    flushPending();
    return sections;
  }
  function flattenItems(tokens) {
    const items = [];
    for (const tok of tokens) {
      const src = { srcStart: tok.srcStart, srcEnd: tok.srcEnd };
      if (tok.type === "directive") {
        const v = tok.value;
        const clefM = v.match(/^([gfcGFC])([0-9])$/);
        if (clefM) {
          items.push({ kind: "clef", clef: { letter: clefM[1].toLowerCase(), line: parseInt(clefM[2], 10) }, ...src });
          continue;
        }
        const accM = matchAccidental(v);
        if (accM) {
          items.push({ kind: "accidental", pitch: accM.pitch, symbol: accM.symbol, ...src });
          continue;
        }
        const keyShortM = v.match(/^K(b+|#+)?$/);
        if (keyShortM) {
          const chars = keyShortM[1] ?? "";
          const accidentals = [];
          if (chars.length > 0) {
            if (chars[0] === "b") {
              const ORDER = ["b", "E", "a", "D", "g", "C", "F"];
              for (let i = 0; i < Math.min(chars.length, ORDER.length); i++)
                accidentals.push({ pitch: ORDER[i], symbol: "x" });
            } else {
              const ORDER = ["F", "C", "G", "D", "a", "E", "b"];
              for (let i = 0; i < Math.min(chars.length, ORDER.length); i++)
                accidentals.push({ pitch: ORDER[i], symbol: "#" });
            }
          }
          items.push({ kind: "keysig", accidentals, ...src });
          continue;
        }
        const keyM = v.match(/^K:\s*(.*)$/);
        if (keyM) {
          const inner = keyM[1].trim();
          const accidentals = [];
          if (inner) {
            for (const part of inner.split(/\s+/)) {
              const acc = matchAccidental(part);
              if (acc) {
                accidentals.push({ pitch: acc.pitch, symbol: acc.symbol });
              }
            }
          }
          items.push({ kind: "keysig", accidentals, ...src });
          continue;
        }
        if (v === "z") {
          items.push({ kind: "break", justify: true, ...src });
          continue;
        }
        if (v === "Z") {
          items.push({ kind: "break", justify: false, ...src });
          continue;
        }
        continue;
      }
      if (tok.type === "expander") {
        items.push({ kind: "expander", ...src });
        continue;
      }
      if (tok.type === "barline") {
        items.push({ kind: "barline", value: tok.kind, ...src });
        continue;
      }
      if (tok.type === "spacer") {
        items.push({ kind: "spacer", multiplier: tok.multiplier, ...src });
        continue;
      }
      if (tok.type === "paren-open") {
        items.push({ kind: "paren-open", ...src });
        continue;
      }
      if (tok.type === "paren-close") {
        items.push({ kind: "paren-close", ...src });
        continue;
      }
      if (tok.type === "brace-open") {
        items.push({ kind: "brace-open", braceKind: tok.kind, ...src });
        continue;
      }
      if (tok.type === "brace-close") {
        items.push({ kind: "brace-close", ...tok.label != null ? { label: tok.label } : {}, ...src });
        continue;
      }
      if (tok.type === "ligature") {
        const { groups, gaps } = splitGroupsAtPlica(tok.groups, tok.gaps ?? []);
        items.push({ kind: "ligature", groups, gaps, ...tok.label != null ? { label: tok.label } : {}, ...src });
        continue;
      }
    }
    return items;
  }

  // node_modules/@aretino-chant/core/src/layout.js
  function layoutRowsWithCourtesyAccidentals(items, ctx, initialClef, staffRightX, drawStartClef, initialKeySig, allowedClefRows = Infinity, firstRowIndentWidth = 0) {
    clearCourtesyAccidentals(items);
    let previousSignature = null;
    let rows = [];
    for (let pass = 0; pass < 8; pass++) {
      rows = layoutRows(items, ctx, initialClef, staffRightX, drawStartClef, initialKeySig, allowedClefRows, firstRowIndentWidth);
      const signature = annotateCourtesyAccidentals(items, rows);
      if (signature === previousSignature) {
        return rows;
      }
      previousSignature = signature;
    }
    rows = layoutRows(items, ctx, initialClef, staffRightX, drawStartClef, initialKeySig, allowedClefRows, firstRowIndentWidth);
    annotateCourtesyAccidentals(items, rows);
    return rows;
  }
  function ligatureHead(lig, k) {
    return {
      ...lig,
      groups: lig.groups.slice(0, k),
      gaps: (lig.gaps ?? []).slice(0, k - 1),
      // The head is row-terminal: nothing follows it on this row, so it needs
      // no trailing reserve for a following syllable.
      syllableExtra: 0
    };
  }
  function ligatureTail(lig, k) {
    const tail = {
      ...lig,
      groups: lig.groups.slice(k),
      gaps: (lig.gaps ?? []).slice(k),
      neumeContinuation: true,
      syllableExtra: 0
    };
    delete tail.label;
    delete tail.leadingCourtesyAccidentals;
    return tail;
  }
  function layoutRows(items, ctx, initialClef, staffRightX, drawStartClef, initialKeySig, allowedClefRows = Infinity, firstRowIndentWidth = 0) {
    const layout = { items, ctx, staffRightX, drawStartClef, allowedClefRows, firstRowIndentWidth };
    const rows = [];
    let state = {
      ii: 0,
      tail: null,
      carry: [],
      rowStartClef: initialClef,
      rowStartClefSource: null,
      runningClef: initialClef,
      rowStartKeySig: initialKeySig ?? [],
      rowStartKeySigSource: null,
      runningKeySig: initialKeySig ?? [],
      clefRowsDrawn: 0,
      isFirstRow: true,
      done: false
    };
    while (!state.done) {
      let filled = fillRow(layout, state);
      if (!filled) {
        break;
      }
      if (filled.reason === "auto" && ctx.avoidLoneSyllables) {
        filled = chooseBreak(layout, state, filled);
      }
      rows.push(filled.row);
      state = filled.state;
    }
    return rows;
  }
  function fillRow(layout, start, bound = null) {
    const { items, ctx, staffRightX, drawStartClef, allowedClefRows, firstRowIndentWidth } = layout;
    let rowStartClef = start.rowStartClef;
    let rowStartClefSource = start.rowStartClefSource;
    let runningClef = start.runningClef;
    let rowStartKeySig = start.rowStartKeySig;
    let rowStartKeySigSource = start.rowStartKeySigSource;
    let runningKeySig = start.runningKeySig;
    let clefRowsDrawn = start.clefRowsDrawn;
    let isFirstRow = start.isFirstRow;
    let cur = [];
    let curWidth = 0;
    for (const it of start.carry) {
      cur.push(it);
      curWidth += measureItem(ctx, it);
    }
    const stopAt = bound?.stopBefore ?? bound?.forceBefore ?? -1;
    const forceBefore = bound?.forceBefore ?? -1;
    let finalized = null;
    function currentRowDrawsClef() {
      return drawStartClef && clefRowsDrawn < allowedClefRows;
    }
    function rowStartLigature(pending) {
      for (const list of pending ? [cur, pending] : [cur]) {
        for (const it of list) {
          if (it.kind === "ligature") {
            return it.neumeContinuation ? null : it;
          }
        }
      }
      return null;
    }
    function rowEndLigature(pending) {
      for (const list of pending ? [pending, cur] : [cur]) {
        for (let i = list.length - 1; i >= 0; i--) {
          if (list[i].kind === "ligature") {
            return list[i];
          }
        }
      }
      return null;
    }
    function rowItemsAvailable(pending = null) {
      const showClef = currentRowDrawsClef();
      const indent = isFirstRow ? firstRowIndentWidth : 0;
      let inset = 0;
      const hasKeySig = rowStartKeySig.length > 0;
      if (showClef) {
        const clefSlot = hasKeySig ? clefAdvance(ctx, rowStartClef) - ss2(ctx, METRICS.clefPostGap) + ss2(ctx, METRICS.clefInlinePostGap) : clefAdvance(ctx, rowStartClef) + ss2(ctx, METRICS.clefInlinePostGap);
        inset += clefSlot;
      }
      if (hasKeySig) {
        inset += keySigAdvance(ctx, rowStartKeySig);
        if (!showClef) {
          inset += ctx.staffSpace / 2 + ss2(ctx, METRICS.clefPostGap);
        } else {
          inset += ss2(ctx, 1);
        }
      }
      if (!showClef && !hasKeySig) {
        inset += ctx.staffSpace;
      }
      const startLig = rowStartLigature(pending);
      const endLig = rowEndLigature(pending);
      const preGap = Math.max(
        0,
        rowStartLyricLimit(startLig) + (startLig?.rowStartOverhang ?? 0) - inset - (endLig?.rowEndSlack ?? 0)
      );
      return staffRightX - ctx.leftMargin - indent - inset - preGap;
    }
    function rowStartLyricLimit(startLig) {
      if (!startLig || !startLig.rowStartHasText || !currentRowDrawsClef()) {
        return 0;
      }
      return clefInkRightOffset(ctx, rowStartClef);
    }
    function finalize(justify) {
      if (cur.length === 0 && rowStartClefSource === null && rowStartKeySigSource === null) {
        return false;
      }
      const showClef = currentRowDrawsClef();
      const rowIsFirst = isFirstRow;
      const available = rowItemsAvailable();
      isFirstRow = false;
      finalized = {
        row: {
          items: cur,
          itemsWidth: curWidth,
          justify,
          startClef: rowStartClef,
          startClefSource: rowStartClefSource,
          startKeySig: rowStartKeySig,
          drawStartClef: showClef,
          indentWidth: rowIsFirst ? firstRowIndentWidth : 0
        },
        available
      };
      if (showClef) {
        clefRowsDrawn++;
      }
      cur = [];
      curWidth = 0;
      rowStartClef = runningClef;
      rowStartClefSource = null;
      rowStartKeySig = runningKeySig;
      rowStartKeySigSource = null;
      return true;
    }
    function done(reason, ii, tail = null, carry = []) {
      return {
        ...finalized,
        reason,
        state: {
          ii,
          tail,
          carry,
          rowStartClef,
          rowStartClefSource,
          runningClef,
          rowStartKeySig,
          rowStartKeySigSource,
          runningKeySig,
          clefRowsDrawn,
          isFirstRow,
          done: reason === "end"
        }
      };
    }
    function placeLigatureWithWrapping(lig, idx) {
      const w = measureItem(ctx, lig);
      const avail = rowItemsAvailable([lig]);
      if (idx < forceBefore || curWidth + w + levelingNeed(ctx, [...cur, lig]) <= avail) {
        cur.push(lig);
        curWidth += w;
        return null;
      }
      const groups = lig.groups;
      let k = 0;
      for (let n = 1; n < groups.length; n++) {
        const head2 = ligatureHead(lig, n);
        if (curWidth + measureItem(ctx, head2) + levelingNeed(ctx, [...cur, head2]) <= avail) {
          k = n;
        } else {
          break;
        }
      }
      if (k === 0) {
        if (cur.length > 0) {
          finalize(true);
          return lig === items[idx] ? done("auto", idx) : done("auto", idx + 1, lig);
        }
        if (groups.length === 1) {
          cur.push(lig);
          curWidth += w;
          return null;
        }
        k = 1;
      }
      const head = ligatureHead(lig, k);
      cur.push(head);
      curWidth += measureItem(ctx, head);
      finalize(true);
      return done("auto", idx + 1, ligatureTail(lig, k));
    }
    if (start.tail) {
      const wrapped = placeLigatureWithWrapping(start.tail, start.ii - 1);
      if (wrapped) {
        return wrapped;
      }
    }
    for (let ii = start.ii; ii < items.length; ii++) {
      const item = items[ii];
      if (ii === stopAt && item.kind !== "break" && finalize(true)) {
        return done("auto", ii);
      }
      if (item.kind === "break") {
        if (finalize(item.justify)) {
          return done("manual", ii + 1);
        }
        continue;
      }
      if (item.kind === "clef") {
        runningClef = item.clef;
        if (cur.length === 0) {
          rowStartClef = item.clef;
          rowStartClefSource = item;
          continue;
        }
      }
      if (item.kind === "keysig") {
        runningKeySig = item.accidentals;
        if (cur.length === 0) {
          rowStartKeySig = item.accidentals;
          rowStartKeySigSource = item;
          continue;
        }
      }
      if (item.kind === "ligature" && !item.recitationGlyphless && !(ii > 0 && items[ii - 1].kind === "accidental")) {
        const wrapped = placeLigatureWithWrapping(item, ii);
        if (wrapped) {
          return wrapped;
        }
        continue;
      }
      let w = measureItem(ctx, item);
      let unit = [item];
      if (item.kind === "accidental" && ii + 1 < items.length && items[ii + 1].kind === "ligature") {
        w += measureItem(ctx, items[ii + 1]);
        unit = [item, items[ii + 1]];
      }
      if (item.kind === "paren-open") {
        let groupW = w;
        const group = [item];
        for (let j = ii + 1; j < items.length; j++) {
          groupW += measureItem(ctx, items[j]);
          group.push(items[j]);
          if (items[j].kind === "paren-close") break;
        }
        if (groupW <= rowItemsAvailable(group)) {
          w = groupW;
          unit = group;
        }
      }
      const gluedToPrev = ii > 0 && items[ii - 1].kind === "accidental" && item.kind === "ligature";
      if (ii >= forceBefore && !gluedToPrev && cur.length > 0 && curWidth + w + levelingNeed(ctx, [...cur, ...unit]) > rowItemsAvailable(unit)) {
        if (item.kind === "barline") {
          let splitIdx = -1;
          for (let k = cur.length - 1; k >= 0; k--) {
            if (cur[k].kind === "ligature") {
              splitIdx = k > 0 && cur[k - 1].kind === "accidental" ? k - 1 : k;
              break;
            }
          }
          if (splitIdx >= 0) {
            const carried = cur.splice(splitIdx);
            curWidth -= carried.reduce((sum, it) => sum + measureItem(ctx, it), 0);
            if (finalize(true)) {
              return done("auto", ii + 1, null, [...carried, item]);
            }
            for (const it of carried) {
              cur.push(it);
              curWidth += measureItem(ctx, it);
            }
            cur.push(item);
            curWidth += measureItem(ctx, item);
            continue;
          }
          finalize(true);
          return done("auto", ii + 1, null, [item]);
        } else if (item.kind === "ligature" && item.recitationGlyphless) {
          const N = item.recitationChainLen;
          const carried = [];
          let p = item.recitationChainIndex;
          const chainStart = ii - p;
          const isShort = (k) => !ctx.avoidLoneSyllables || items[chainStart + k].recitationWordShort;
          const loneAt = (q) => (q === 1 && isShort(0)) + (q === N - 1 && isShort(N - 1));
          const breakAllowed = (q) => q === 0 || loneAt(q) === 0;
          while (!breakAllowed(p) && cur.length > 0) {
            const top = cur[cur.length - 1];
            if (!(top.kind === "ligature" && top.recitationGlyphless && top.recitationChainId === item.recitationChainId)) break;
            cur.pop();
            curWidth -= measureItem(ctx, top);
            carried.unshift(top);
            p = top.recitationChainIndex;
          }
          if (!finalize(true)) {
            for (const c of carried) {
              cur.push(c);
              curWidth += measureItem(ctx, c);
            }
            cur.push(item);
            curWidth += measureItem(ctx, item);
            continue;
          }
          return done("auto", ii + 1, null, [...carried, item]);
        } else {
          finalize(true);
          if (item.kind === "clef") {
            rowStartClef = item.clef;
            rowStartClefSource = item;
            return done("auto", ii + 1);
          }
          if (item.kind === "keysig") {
            rowStartKeySig = item.accidentals;
            return done("auto", ii + 1);
          }
          return done("auto", ii + 1, null, [item]);
        }
      }
      cur.push(item);
      curWidth += measureItem(ctx, item);
    }
    if (finalize(false)) {
      return done("end", items.length);
    }
    return null;
  }
  var VIOLATION_COST = 1e3;
  var BADNESS_SCALE = 100;
  var PULL_BACK_COST = 10;
  function firstLigatureOf(items, state) {
    if (state.tail) return state.tail;
    const carried = state.carry.find((it) => it.kind === "ligature");
    if (carried) return carried;
    for (let i = state.ii; i < items.length; i++) {
      if (items[i].kind === "ligature") return items[i];
      if (items[i].kind === "break") return null;
    }
    return null;
  }
  function lastLigatureOf(rowItems) {
    for (let i = rowItems.length - 1; i >= 0; i--) {
      if (rowItems[i].kind === "ligature") return rowItems[i];
    }
    return null;
  }
  function fillViolations(items, filled) {
    if (filled.reason !== "auto") return 0;
    return breakViolations(lastLigatureOf(filled.row.items), firstLigatureOf(items, filled.state));
  }
  function stretchUse(ctx, filled) {
    const { row, available } = filled;
    const leftover = available - row.itemsWidth;
    if (!row.justify || leftover <= 0) return 0;
    let gaps = 0;
    for (let i = 0; i < row.items.length - 1; i++) {
      if (isLeveledGap(row.items[i], row.items[i + 1])) gaps++;
    }
    const limit = ctx.wrapStretchMax * naturalNeumeWhite(ctx);
    if (gaps === 0 || limit <= 0) return Infinity;
    return leftover / gaps / limit;
  }
  function condenseUse(ctx, filled) {
    const { row, available } = filled;
    const width = row.itemsWidth;
    const T = ctx.gapOutlierThreshold;
    const Tmin = Math.min(T, ctx.gapOutlierThresholdMin);
    const fits = (t) => width + levelingNeed(ctx, row.items, t) <= available;
    if (fits(T)) {
      return { use: stretchUse(ctx, filled), condense: 0 };
    }
    if (T > Tmin && fits(Tmin)) {
      const floors = levelingTargetFloors(ctx, row.items).map((f) => f / ctx.staffSpace).filter((f) => f > Tmin && f <= T).sort((a, b) => a - b);
      const t = floors.find((f) => !fits(f)) ?? T;
      return { use: 0.5 * (T - t) / (T - Tmin), condense: 0 };
    }
    const deficit = Math.max(0, width - available);
    const condensed = condenseGaps(ctx, row.items, deficit);
    if (!condensed) return null;
    const limit = (1 - ctx.wrapCondenseMin) * naturalNeumeWhite(ctx);
    const share = condensed.delta > 0 ? condensed.delta / limit : 0;
    return { use: 0.5 + 0.5 * share, condense: deficit };
  }
  function isBreakPoint(items, i) {
    const it = items[i];
    if (it.kind === "ligature") {
      return !it.recitationGlyphless && !(i > 0 && items[i - 1].kind === "accidental");
    }
    return it.kind === "accidental" && items[i + 1]?.kind === "ligature" && !items[i + 1].recitationGlyphless;
  }
  function isBarrier(it) {
    return it.kind === "break" || it.kind === "clef" || it.kind === "keysig" || it.kind === "paren-open" || it.kind === "paren-close" || it.kind === "ligature" && it.recitationGlyphless;
  }
  function hasOpenParen(rowItems) {
    let open = false;
    for (const it of rowItems) {
      if (it.kind === "paren-open") open = true;
      else if (it.kind === "paren-close") open = false;
    }
    return open;
  }
  function countGreedyRows(layout, state) {
    let rows = 0;
    while (!state.done) {
      const filled = fillRow(layout, state);
      if (!filled) break;
      rows++;
      if (filled.reason === "manual") break;
      state = filled.state;
    }
    return rows;
  }
  function chooseBreak(layout, start, greedy) {
    const { items, ctx } = layout;
    const next = greedy.state;
    const left = lastLigatureOf(greedy.row.items);
    const right = firstLigatureOf(items, next);
    const violations = breakViolations(left, right);
    if (violations === 0 || hasOpenParen(greedy.row.items)) {
      return greedy;
    }
    const splitAt = next.tail ? next.ii - 1 : -1;
    const breakAt = next.tail ? -1 : next.carry.length ? items.indexOf(next.carry[0]) : next.ii;
    if (splitAt < 0 && breakAt < 0) {
      return greedy;
    }
    const origin = splitAt >= 0 ? splitAt : breakAt;
    const broken = left.lyricWord.map((a, s) => {
      const b = right.lyricWord[s];
      return a && b && a.word === b.word ? a.word : null;
    });
    const inBrokenWord = (it) => it.kind === "ligature" && (it.lyricWord ?? []).some((e, s) => e && broken[s] !== null && e.word === broken[s]);
    let wordStart = origin;
    for (let i = origin; i >= 0 && items[i].kind !== "break"; i--) {
      if (items[i].kind !== "ligature") continue;
      if (!inBrokenWord(items[i])) break;
      wordStart = i;
    }
    let wordEnd = origin;
    for (let i = origin; i < items.length && items[i].kind !== "break"; i++) {
      if (items[i].kind !== "ligature") continue;
      if (!inBrokenWord(items[i])) break;
      wordEnd = i;
    }
    const neumeOf = (i) => items[i].kind === "accidental" ? i + 1 : i;
    let best = greedy;
    let bestCost = VIOLATION_COST * violations + BADNESS_SCALE * stretchUse(ctx, greedy) ** 3;
    const consider = (filled, use, extra) => {
      const cost = VIOLATION_COST * fillViolations(items, filled) + BADNESS_SCALE * use ** 3 + extra;
      if (cost < bestCost) {
        best = filled;
        bestCost = cost;
      }
    };
    const endsAt = (filled, p) => {
      if (!filled || !filled.row.items.some((it) => it.kind === "ligature")) return false;
      if (p === items.length) return filled.reason === "end";
      const ii = items[p].kind === "break" ? p + 1 : p;
      return filled.state.ii === ii && !filled.state.tail && filled.state.carry.length === 0;
    };
    for (let p = origin + 1; p <= items.length; p++) {
      const barrier = p === items.length || isBarrier(items[p]);
      if (!barrier && !isBreakPoint(items, p)) continue;
      if (p < items.length && items[p].kind === "paren-close") break;
      const filled = fillRow(layout, start, { forceBefore: p });
      if (!endsAt(filled, p)) break;
      const condensed = condenseUse(ctx, filled);
      if (!condensed || condensed.use > 1) break;
      if (condensed.condense > 0) {
        filled.row.condense = condensed.condense;
      }
      consider(filled, condensed.use, 0);
      if (barrier || neumeOf(p) > wordEnd) break;
    }
    const lowest = start.tail || start.carry.length ? start.ii : start.ii + 1;
    let greedyRows = null;
    for (let p = splitAt >= 0 ? splitAt : breakAt - 1; p >= lowest; p--) {
      if (isBarrier(items[p])) break;
      if (!isBreakPoint(items, p)) continue;
      if (neumeOf(p) < wordStart) break;
      const filled = fillRow(layout, start, { stopBefore: p });
      if (!endsAt(filled, p)) continue;
      const use = stretchUse(ctx, filled);
      if (use > 1) continue;
      greedyRows ?? (greedyRows = countGreedyRows(layout, next));
      if (countGreedyRows(layout, filled.state) > greedyRows) continue;
      consider(filled, use, PULL_BACK_COST);
    }
    return best;
  }

  // node_modules/@aretino-chant/core/src/transpose.js
  var POS_TO_LETTER = {};
  for (const [letter, pos] of Object.entries(PITCH_BASE)) {
    POS_TO_LETTER[pos] = letter;
  }
  var MIN_POS = Math.min(...Object.values(PITCH_BASE));
  var MAX_POS = Math.max(...Object.values(PITCH_BASE));
  var NATURAL_SEMITONE = [0, 2, 4, 5, 7, 9, 11];
  var SHARP_ORDER = ["F", "C", "G", "D", "a", "E", "b"];
  var FLAT_ORDER = ["b", "E", "a", "D", "g", "C", "F"];
  function mod(n, m) {
    return (n % m + m) % m;
  }
  function positionToCIndex(pos) {
    return mod(pos + 2, 7);
  }
  function naturalAbs(pos) {
    return 12 * Math.floor((pos + 2) / 7) + NATURAL_SEMITONE[positionToCIndex(pos)];
  }
  function positionToLetter(pos) {
    const clamped = Math.max(MIN_POS, Math.min(MAX_POS, pos));
    return POS_TO_LETTER[clamped];
  }
  function setNotePosition(note, pos) {
    let p = pos;
    let shift = 0;
    while (p > MAX_POS) {
      p -= 7;
      shift += 1;
    }
    while (p < MIN_POS) {
      p += 7;
      shift -= 1;
    }
    note.pitch = POS_TO_LETTER[p];
    if (shift) {
      note.octaveShift = shift;
    } else {
      delete note.octaveShift;
    }
  }
  function symbolToAlteration(symbol) {
    if (symbol === "x") return -1;
    if (symbol === "#") return 1;
    return 0;
  }
  function alterationToSymbol(alt) {
    if (alt < 0) return "x";
    if (alt > 0) return "#";
    return "y";
  }
  function clampAlt(alt) {
    return Math.max(-1, Math.min(1, alt));
  }
  function keySigToFifths(accidentals) {
    let f = 0;
    for (const acc of accidentals ?? []) {
      f += symbolToAlteration(acc.symbol);
    }
    return f;
  }
  function fifthsToKeySig(f) {
    const out = [];
    if (f > 0) {
      for (let i = 0; i < Math.min(f, SHARP_ORDER.length); i++) {
        out.push({ pitch: SHARP_ORDER[i], symbol: "#" });
      }
    } else if (f < 0) {
      for (let i = 0; i < Math.min(-f, FLAT_ORDER.length); i++) {
        out.push({ pitch: FLAT_ORDER[i], symbol: "x" });
      }
    }
    return out;
  }
  function keySigToAltMap(accidentals) {
    const map = /* @__PURE__ */ new Map();
    for (const acc of accidentals ?? []) {
      const pos = PITCH_BASE[acc.pitch];
      if (pos === void 0) continue;
      map.set(positionToCIndex(pos), symbolToAlteration(acc.symbol));
    }
    return map;
  }
  function transposeTarget(f0, semitones) {
    const r = mod(f0 + 7 * semitones, 12);
    const f1 = r <= 5 ? r : r - 12;
    const d = Math.round((7 * semitones - (f1 - f0)) / 12);
    return { f1, d };
  }
  function transposeNote(oldPos, srcAlt, N, d, newKeyAlt, barActive) {
    const newPos = oldPos + d;
    const targetAbs = naturalAbs(oldPos) + srcAlt + N;
    const reqAlt = clampAlt(targetAbs - naturalAbs(newPos));
    const sounding = barActive.has(newPos) ? barActive.get(newPos) : newKeyAlt.get(positionToCIndex(newPos)) ?? 0;
    return { newPos, reqAlt, sounding };
  }
  function createTransposeState(amount) {
    return {
      amount,
      srcFifths: 0,
      // running source key signature (line of fifths)
      srcKeyAlt: /* @__PURE__ */ new Map(),
      // running source key alterations by C-index
      emittedSig: false
      // whether a (transposed) key signature has been shown
    };
  }
  function applyTranspose(items, state) {
    if (!state || !state.amount) return;
    const N = state.amount;
    const out = [];
    const srcBarActive = /* @__PURE__ */ new Map();
    const barActive = /* @__PURE__ */ new Map();
    const clearBars = () => {
      srcBarActive.clear();
      barActive.clear();
    };
    for (const it of items) {
      if (!state.emittedSig && it.kind === "ligature") {
        const { f1: f12 } = transposeTarget(state.srcFifths, N);
        if (f12 !== 0) {
          out.push({ kind: "keysig", accidentals: fifthsToKeySig(f12) });
        }
        state.emittedSig = true;
      }
      if (it.kind === "keysig") {
        state.srcFifths = keySigToFifths(it.accidentals);
        state.srcKeyAlt = keySigToAltMap(it.accidentals);
        const { f1: f12 } = transposeTarget(state.srcFifths, N);
        it.accidentals = fifthsToKeySig(f12);
        state.emittedSig = true;
        clearBars();
        out.push(it);
        continue;
      }
      if (it.kind === "barline") {
        clearBars();
        out.push(it);
        continue;
      }
      const { f1, d } = transposeTarget(state.srcFifths, N);
      const newKeyAlt = keySigToAltMap(fifthsToKeySig(f1));
      if (it.kind === "accidental") {
        const oldPos = PITCH_BASE[it.pitch] ?? 4;
        const srcAlt = symbolToAlteration(it.symbol);
        srcBarActive.set(oldPos, srcAlt);
        const { newPos, reqAlt, sounding } = transposeNote(oldPos, srcAlt, N, d, newKeyAlt, barActive);
        if (reqAlt === sounding) {
          continue;
        }
        it.pitch = positionToLetter(newPos);
        it.symbol = alterationToSymbol(reqAlt);
        barActive.set(newPos, reqAlt);
        out.push(it);
        continue;
      }
      if (it.kind === "ligature") {
        for (const group of it.groups) {
          for (const note of group) {
            const oldPos = (PITCH_BASE[note.pitch] ?? 0) + 7 * (note.octaveShift || 0);
            const accPos = note.accidental ? PITCH_BASE[note.accidental.pitch] ?? oldPos : oldPos;
            if (note.accidental && accPos !== oldPos) {
              const accSrcAlt = symbolToAlteration(note.accidental.symbol);
              srcBarActive.set(accPos, accSrcAlt);
              const { newPos: newAccPos, reqAlt: reqAccAlt, sounding: accSounding } = transposeNote(accPos, accSrcAlt, N, d, newKeyAlt, barActive);
              if (reqAccAlt === accSounding) {
                delete note.accidental;
              } else {
                note.accidental = {
                  pitch: positionToLetter(newAccPos),
                  symbol: alterationToSymbol(reqAccAlt),
                  ...note.accidental.srcStart !== void 0 ? { srcStart: note.accidental.srcStart, srcEnd: note.accidental.srcEnd } : {}
                };
                barActive.set(newAccPos, reqAccAlt);
              }
              setNotePosition(note, oldPos + d);
              continue;
            }
            const oldCIndex = positionToCIndex(oldPos);
            let srcAlt;
            if (note.accidental) {
              srcAlt = symbolToAlteration(note.accidental.symbol);
              srcBarActive.set(oldPos, srcAlt);
            } else if (srcBarActive.has(oldPos)) {
              srcAlt = srcBarActive.get(oldPos);
            } else {
              srcAlt = state.srcKeyAlt.get(oldCIndex) ?? 0;
            }
            const { newPos, reqAlt, sounding } = transposeNote(oldPos, srcAlt, N, d, newKeyAlt, barActive);
            setNotePosition(note, newPos);
            if (reqAlt === sounding) {
              delete note.accidental;
            } else {
              note.accidental = {
                pitch: positionToLetter(newPos),
                symbol: alterationToSymbol(reqAlt),
                ...note.srcStart !== void 0 ? { srcStart: note.srcStart, srcEnd: note.srcEnd } : {}
              };
              barActive.set(newPos, reqAlt);
            }
          }
        }
        out.push(it);
        continue;
      }
      out.push(it);
    }
    items.length = 0;
    items.push(...out);
  }

  // node_modules/@aretino-chant/core/src/ligature.js
  function emitLigature(ctx, groups, x, staffBottomY, gaps = [], leadingCourtesyAccidentals = []) {
    const splitResult = splitGroupsAtInternalMora(groups, gaps);
    groups = splitResult.groups;
    gaps = splitResult.gaps;
    const parts = [];
    const halfSW = ligatureConnectorHalfStroke(ctx);
    let groupStartX = x;
    let courtesyAdvance = 0;
    let firstNoteCx = null;
    let lastNoteCx = null;
    let allNotesMinY = Infinity;
    let allNotesMaxY = -Infinity;
    for (const acc of leadingCourtesyAccidentals) {
      const accX = groupStartX + courtesyAdvance;
      const a = drawAccidental(ctx, acc.pitch, acc.symbol, accX, staffBottomY);
      parts.push(`<g class="aretino-accidental aretino-courtesy-accidental">${a.svg}</g>`);
      courtesyAdvance += accidentalAdvance(ctx, acc);
    }
    groupStartX += courtesyAdvance;
    for (let g = 0; g < groups.length; g++) {
      const notes = groups[g];
      const positions = [];
      let cx = groupStartX + ss2(ctx, METRICS.noteBoxWidth) * 0.5;
      for (let i = 0; i < notes.length; i++) {
        const note = notes[i];
        if (note.accidental) {
          const accX = cx - ss2(ctx, METRICS.noteBoxWidth) * 0.5;
          const a = drawAccidental(ctx, note.accidental.pitch, note.accidental.symbol, accX, staffBottomY);
          parts.push(wrapSrc(note.accidental, a.svg, "aretino-accidental aretino-inline-accidental", staffBottomY, ctx.staffHeight, void 0, void 0, ctx.sourceMap));
          cx += accidentalSymbolAdvance(ctx, note.accidental.symbol);
        }
        const cy = pitchY(ctx, note, staffBottomY);
        positions.push({ note, cx, cy });
        if (firstNoteCx === null) {
          firstNoteCx = cx;
        }
        lastNoteCx = cx;
        if (i < notes.length - 1) {
          cx += ctx.ligatureStepAdvance;
        }
      }
      const autoVirga = computeAutoVirga(notes);
      const connectorParts = [];
      for (let i = 1; i < positions.length; i++) {
        const prev = positions[i - 1];
        const cur = positions[i];
        if (cur.note.shape === "virga" || cur.note.virga || autoVirga[i]) {
          continue;
        }
        if (cur.note.accidental) {
          continue;
        }
        const prevPos = pitchToPos(prev.note);
        const curPos = pitchToPos(cur.note);
        if (curPos === prevPos) {
          continue;
        }
        const prevScale = prev.note.modifiers && prev.note.modifiers.includes("small") ? METRICS.smallNoteScale : 1;
        const curScale = cur.note.modifiers && cur.note.modifiers.includes("small") ? METRICS.smallNoteScale : 1;
        const from = noteheadRightPoint(ctx, prev.cx, prev.cy, prevScale);
        const to = noteheadLeftPoint(ctx, cur.cx, cur.cy, curScale);
        const kind = curPos > prevPos ? "up" : "down";
        if (kind === "up" && curPos - prevPos <= 0) {
          continue;
        }
        if (kind === "up") {
          connectorParts.push(drawLigatureConnector(ctx, from.x - halfSW / 4, from.y + ss2(ctx, 0.2), to.x + halfSW / 4, to.y - ss2(ctx, 0.2), kind));
        } else {
          connectorParts.push(drawLigatureConnector(ctx, from.x - halfSW + ss2(ctx, 0.03), from.y + ss2(ctx, 0.1), to.x + halfSW - ss2(ctx, 0.04), to.y - ss2(ctx, 0.1), kind));
        }
      }
      const halfEW = ss2(ctx, METRICS.episemaWidth) / 2;
      const episemaInGroup = /* @__PURE__ */ new Set();
      {
        let runStart = null;
        const flushRun = (end) => {
          if (runStart === null) {
            return;
          }
          if (end - runStart >= 2) {
            const run = positions.slice(runStart, end);
            const highest = run.reduce((best, p) => p.cy < best.cy ? p : best, run[0]);
            const onLine = pitchToPos(highest.note) % 2 === 0;
            const x1 = run[0].cx - halfEW;
            const x2 = run[run.length - 1].cx + halfEW;
            parts.push(drawEpisemaSpan(ctx, x1, x2, highest.cy, onLine));
            for (let j = runStart; j < end; j++) {
              episemaInGroup.add(j);
            }
          }
          runStart = null;
        };
        for (let i = 0; i <= positions.length; i++) {
          const hasEpisema = i < positions.length && positions[i].note.modifiers.includes("episema");
          if (hasEpisema) {
            if (runStart === null) {
              runStart = i;
            }
          } else {
            flushRun(i);
          }
        }
      }
      const moraDotYForNote = /* @__PURE__ */ new Map();
      {
        const moraNoteCount = notes.filter((n) => n.modifiers.includes("mora")).length;
        if (moraNoteCount >= 2) {
          const seenDotYs = /* @__PURE__ */ new Set();
          for (let i = 0; i < positions.length; i++) {
            const p = positions[i];
            if (!p.note.modifiers.includes("mora")) continue;
            const onLine = pitchToPos(p.note) % 2 === 0;
            let dotY = onLine ? p.cy - ctx.staffSpace / 2 : p.cy;
            if (seenDotYs.has(dotY)) {
              dotY += ctx.staffSpace;
            }
            seenDotYs.add(dotY);
            moraDotYForNote.set(i, dotY);
          }
        }
      }
      for (let i = 0; i < positions.length; i++) {
        const p = positions[i];
        const prevCy = i > 0 ? positions[i - 1].cy : null;
        const drawnNote = autoVirga[i] ? { ...p.note, virga: true } : p.note;
        const bounds = noteInkBounds(ctx, drawnNote, p.cy, staffBottomY, prevCy);
        if (bounds.minY < allNotesMinY) allNotesMinY = bounds.minY;
        if (bounds.maxY > allNotesMaxY) allNotesMaxY = bounds.maxY;
        const noteParts = [drawNoteHead(ctx, drawnNote, p.cx, p.cy, staffBottomY, prevCy)];
        const modifierSpans = p.note.modifierSpans ?? [];
        for (let mi = 0; mi < p.note.modifiers.length; mi++) {
          const mod2 = p.note.modifiers[mi];
          let glyph = null;
          if (mod2 === "episema") {
            if (!episemaInGroup.has(i)) {
              const onLine = pitchToPos(p.note) % 2 === 0;
              glyph = drawEpisema(ctx, p.cx, p.cy, onLine);
            }
          } else if (mod2 === "mora") {
            const onLine = pitchToPos(p.note) % 2 === 0;
            const moraNoteCount = notes.filter((n) => n.modifiers.includes("mora")).length;
            const drawCx = moraNoteCount >= 2 ? positions[positions.length - 1].cx : p.cx;
            let moraCy = p.cy;
            if (moraDotYForNote.has(i)) {
              const targetDotY = moraDotYForNote.get(i);
              moraCy = onLine ? targetDotY + ctx.staffSpace / 2 : targetDotY;
              const r = ss2(ctx, METRICS.moraRadius);
              if (targetDotY - r < allNotesMinY) allNotesMinY = targetDotY - r;
              if (targetDotY + r > allNotesMaxY) allNotesMaxY = targetDotY + r;
            }
            glyph = drawMora(ctx, drawCx, moraCy, onLine);
          } else if (mod2 === "ictus") {
            const pos = pitchToPos(p.note);
            const below = p.note.modifiers.includes("episema");
            const onLine = pos % 2 === 0 && (below || pos < (METRICS.staffLineCount - 1) * 2);
            glyph = drawIctus(ctx, p.cx, p.cy, onLine, below);
          } else if (mod2 === "plica") {
            glyph = drawPlica(ctx, p.cx, p.cy, "down");
          }
          if (glyph === null) continue;
          noteParts.push(wrapSrc(modifierSpans[mi] ?? {}, glyph, `aretino-modifier aretino-mod-${mod2}`, void 0, void 0, void 0, void 0, ctx.sourceMap));
        }
        parts.push(wrapSrc(p.note, noteParts.join(""), "aretino-note", staffBottomY, ctx.staffHeight, p.cx - ss2(ctx, METRICS.noteBoxWidth) * 0.5, ss2(ctx, METRICS.noteBoxWidth), ctx.sourceMap));
      }
      for (const c of connectorParts) parts.push(c);
      if (g < groups.length - 1) {
        const gapType = gaps[g] ?? 1;
        const slashCount = typeof gapType === "number" ? gapType : 0;
        const lastNote2 = notes[notes.length - 1];
        const hasMora2 = lastNote2.modifiers && lastNote2.modifiers.includes("mora");
        const moraOverhang = hasMora2 ? ss2(ctx, METRICS.moraOffsetX + METRICS.moraRadius) : 0;
        const accExtra = notes.reduce((sum, note) => sum + (note.accidental ? accidentalSymbolAdvance(ctx, note.accidental.symbol) : 0), 0);
        groupStartX += ss2(ctx, METRICS.noteBoxWidth) + (notes.length - 1) * ctx.ligatureStepAdvance + slashCount * ctx.neumeGapAdvance + moraOverhang + accExtra;
      }
    }
    const advance = courtesyAdvance + measureSplitLigature(ctx, groups, gaps);
    const totalNotes = groups.reduce((sum, g) => sum + g.length, 0);
    const lastNote = groups[groups.length - 1]?.[groups[groups.length - 1].length - 1];
    const lastNoteHasMora = lastNote?.modifiers?.includes("mora");
    const allMoraNoteCount = groups.reduce((sum, g) => sum + g.filter((n) => n.modifiers?.includes("mora")).length, 0);
    const hasMora = lastNoteHasMora || allMoraNoteCount >= 2;
    const isTenor = groups.some((g) => g.some((n) => n.shape === "tenor"));
    const shouldAlignLeft = totalNotes > 1 || isTenor;
    const centerX = firstNoteCx !== null ? (firstNoteCx + lastNoteCx) / 2 : x + advance / 2;
    const leftX = firstNoteCx !== null ? firstNoteCx - ss2(ctx, METRICS.noteBoxWidth) * 0.5 : x;
    const rightX = lastNoteCx !== null ? lastNoteCx + ss2(ctx, hasMora ? METRICS.moraOffsetX + METRICS.moraRadius : METRICS.noteBoxWidth * 0.5) : x + advance;
    return { svg: parts.join(""), advance, centerX, leftX, rightX, shouldAlignLeft, minY: allNotesMinY, maxY: allNotesMaxY, firstNoteCx, lastNoteCx };
  }

  // node_modules/@aretino-chant/core/src/renderer.js
  var DEFAULT_FONT = "'Palatino Linotype', 'Book Antiqua', Palatino, serif";
  function justificationWaterLevel(floors, budget) {
    if (floors.length === 0 || budget <= 0) {
      return floors.length ? Math.min(...floors) : 0;
    }
    const sorted = [...floors].sort((a, b) => a - b);
    let level = sorted[0];
    let remaining = budget;
    for (let i = 1; i <= sorted.length; i++) {
      const next = i < sorted.length ? sorted[i] : Infinity;
      const count = i;
      const cost = (next - level) * count;
      if (!isFinite(cost) || cost >= remaining) {
        return level + remaining / count;
      }
      remaining -= cost;
      level = next;
    }
    return level;
  }
  var recitationChainCounter = 0;
  function splitRecitationWords(syl) {
    const text = syl.text || "";
    const alignText = syl.alignText ?? text;
    const prefixLen = Math.max(0, text.length - alignText.length);
    if (!/\s/.test(alignText.trim())) return null;
    const segments = syl.segments || [];
    const words = [];
    const re = /\S+/g;
    let m;
    while ((m = re.exec(alignText)) !== null) {
      const start = prefixLen + m.index;
      const wordSegs = trimSegmentsEnd(sliceSegments(segments, start), m[0].length);
      const withPrefix = words.length === 0 && prefixLen > 0;
      words.push({
        text: withPrefix ? text.slice(0, start + m[0].length) : m[0],
        alignText: m[0],
        segments: withPrefix ? trimSegmentsEnd(segments, start + m[0].length) : wordSegs,
        alignSegments: wordSegs,
        suffixSegments: [],
        realLyric: hasRealLyricText(m[0]),
        hyphenAfter: false,
        hyphenMandatory: false,
        kind: "note"
      });
    }
    if (words.length < 2) return null;
    const last = words[words.length - 1];
    last.hyphenAfter = syl.hyphenAfter || false;
    last.hyphenMandatory = syl.hyphenMandatory || false;
    return words;
  }
  function expandTenorRecitations(items, verseNotes) {
    if (verseNotes.length !== 1) return;
    const notes = verseNotes[0];
    let li = 0;
    for (let ii = 0; ii < items.length; ii++) {
      const it = items[ii];
      if (it.kind !== "ligature") continue;
      const isSingleTenor = it.groups.length === 1 && it.groups[0].length === 1 && it.groups[0][0].shape === "tenor";
      const syl = notes[li];
      const words = isSingleTenor && syl ? splitRecitationWords(syl) : null;
      if (!words) {
        li++;
        continue;
      }
      const chainId = ++recitationChainCounter;
      const pieces = words.map((w, k) => ({
        ...it,
        recitationGlyphless: true,
        recitationChainId: chainId,
        recitationChainIndex: k,
        recitationChainLen: words.length
      }));
      items.splice(ii, 1, ...pieces);
      ii += pieces.length - 1;
      notes.splice(li, 1, ...words);
      li += words.length;
    }
  }
  var MM_PER_INCH = 25.4;
  var DEFAULT_DPI = 96;
  var DEFAULT_STAFF_SPACE_MM = 1.75;
  var DEFAULT_PAGE_WIDTH_MM = 180;
  var DEFAULT_LYRIC_SIZE_PT = 10;
  var HIGHLIGHT_STYLE = `<style>.aretino-active [fill]:not([fill="none"]):not(.aretino-cursor-bg){fill:#ea580c}.aretino-active [stroke]:not([stroke="none"]):not(.aretino-cursor-bg){stroke:#ea580c}</style>`;
  function _flushBrace(ctx, parts, state, staffBottomY, isEnd, textFont) {
    const gap = ss2(ctx, METRICS.overbraceGap);
    const staffTopY = staffBottomY - 4 * ctx.staffSpace;
    const topNoteY = state.minY < Infinity ? Math.min(state.minY, staffTopY) : staffTopY;
    const { braceKind, startX, endX, isStart, placeIdx, label } = state;
    let markY;
    let svg;
    let braceTopY;
    if (braceKind === "arc") {
      markY = topNoteY - gap;
      svg = drawOverarc(ctx, startX, endX, markY);
      braceTopY = markY - ss2(ctx, METRICS.overarcBulge);
    } else if (braceKind === "line") {
      markY = topNoteY - gap;
      svg = drawOverline(ctx, startX, endX, markY);
      braceTopY = markY;
    } else {
      markY = topNoteY - gap * 1.5;
      svg = drawOverbrace(ctx, startX, endX, markY, isStart !== false, isEnd);
      braceTopY = markY - (isStart !== false ? ss2(ctx, METRICS.overbraceTipDepth) : 0);
    }
    if (isEnd && label) {
      const fontSize = ctx.lyricSize * 0.8;
      const mx = (startX + endX) / 2;
      let braceTopOffset;
      if (braceKind === "arc") {
        braceTopOffset = ss2(ctx, METRICS.overarcBulge) * 0.75;
      } else if (braceKind === "line") {
        braceTopOffset = 0;
      } else {
        braceTopOffset = isStart !== false ? ss2(ctx, METRICS.overbraceTipDepth) : 0;
      }
      const textY = markY - braceTopOffset - gap * 0.5 - fontSize * 0.15;
      svg += renderMixedLabel(parseFormattingToSegments(label), mx, textY, fontSize, textFont, "middle", ctx.measureText);
      braceTopY = Math.min(braceTopY, textY - fontSize);
    }
    parts[placeIdx] = svg;
    return braceTopY;
  }
  function _flushSlur(ctx, parts, state, staffBottomY, isEnd) {
    const gap = ss2(ctx, METRICS.slurGap);
    const startNoteY = state.startNoteY != null ? state.startNoteY : staffBottomY;
    const endNoteY = state.endNoteY > -Infinity ? state.endNoteY : staffBottomY;
    const y1 = startNoteY + gap;
    const y2 = endNoteY + gap;
    const svg = drawSlur(ctx, state.startX, state.endX, y1, y2, state.dashed, state.isStart !== false, isEnd);
    parts[state.placeIdx] = svg;
    return Math.max(y1, y2) + ss2(ctx, METRICS.slurBulge);
  }
  function renderAretino(source, options = {}) {
    const ast = typeof source === "string" ? parseAretino(source) : source;
    options = { ...parseHeaderRendererOptions(ast), ...options };
    const dpi = options.dpi ?? DEFAULT_DPI;
    const pxPerMm = dpi / MM_PER_INCH;
    const zoom = Math.max(0.1, options.zoom ?? 1);
    const staffSpacePx = Math.max(0.1, options.staffSpaceMm ?? DEFAULT_STAFF_SPACE_MM) * pxPerMm;
    const width = options.width != null ? options.width : Math.round((options.widthMm ?? DEFAULT_PAGE_WIDTH_MM) * pxPerMm);
    const canvasHeight = options.canvasHeight || null;
    const noteSpacing = Math.max(0.5, options.noteSpacing ?? 1);
    const textFont = options.textFont || DEFAULT_FONT;
    const hideRepeatClef = !!options.hideRepeatClef;
    const justifyWithoutLyrics = !!options.justifyWithoutLyrics;
    const sourceMap = options.sourceMap !== false;
    const ctx = {
      staffSpace: staffSpacePx,
      sourceMap
    };
    ctx.pitchStep = ctx.staffSpace / 2;
    ctx.staffHeight = (METRICS.staffLineCount - 1) * ctx.staffSpace;
    ctx.singleNoteAdvance = ss2(ctx, METRICS.singleNoteAdvance) * noteSpacing;
    ctx.ligatureStepAdvance = ss2(ctx, METRICS.ligatureStepAdvance);
    ctx.expanderWidth = ss2(ctx, METRICS.expanderWidth);
    ctx.neumeGapAdvance = ss2(ctx, METRICS.neumeGapAdvance);
    ctx.gapOutlierThreshold = Number.isFinite(options.gapOutlierThreshold) ? Math.max(0, options.gapOutlierThreshold) : METRICS.gapOutlierThreshold;
    ctx.avoidLoneSyllables = options.avoidLoneSyllables !== false;
    ctx.gapOutlierThresholdMin = Math.min(ctx.gapOutlierThreshold, Math.max(
      0,
      Number.isFinite(options.gapOutlierThresholdMin) ? options.gapOutlierThresholdMin : METRICS.gapOutlierThresholdMin
    ));
    ctx.wrapCondenseMin = Math.min(1, Math.max(
      0,
      Number.isFinite(options.wrapCondenseMin) ? options.wrapCondenseMin : METRICS.wrapCondenseMin
    ));
    ctx.wrapStretchMax = Math.max(
      0,
      Number.isFinite(options.wrapStretchMax) ? options.wrapStretchMax : METRICS.wrapStretchMax
    );
    ctx.recitationLoneWordMin = Math.max(
      0,
      Number.isFinite(options.recitationLoneWordMin) ? options.recitationLoneWordMin : METRICS.recitationLoneWordMin
    );
    ctx.leftMargin = ss2(ctx, METRICS.leftMargin);
    ctx.rightMargin = ss2(ctx, METRICS.rightMargin);
    ctx.staffGap = ss2(ctx, options.staffGap ?? METRICS.staffGap);
    ctx.lyricDistance = ss2(ctx, options.lyricDistance ?? METRICS.lyricDistance);
    ctx.lyricMinStaffDistance = ss2(ctx, options.lyricMinStaffDistance ?? METRICS.lyricMinStaffDistance);
    for (const key of [
      "lyricHyphenMinLen",
      "lyricHyphenMaxLen",
      "lyricHyphenWidth",
      "lyricHyphenSpace",
      "lyricHyphenPos",
      "lyricHyphenRepeat"
    ]) {
      ctx[key] = Number.isFinite(options[key]) ? options[key] : METRICS[key];
    }
    ctx.virgaStemLength = options.virgaStemLength ?? METRICS.virgaStemLength;
    ctx.virgaStemDescentBelowPrev = options.virgaStemDescentBelowPrev ?? METRICS.virgaStemDescentBelowPrev;
    ctx.virgaMaxBelowBottom = options.virgaMaxBelowBottom ?? METRICS.virgaMaxBelowBottom;
    ctx.textFont = textFont;
    ctx.textStyle = typeof options.textStyle === "string" ? options.textStyle : void 0;
    ctx.textStyles = options.textStyles;
    ctx.textMaxIndent = Number.isFinite(options.textMaxIndent) ? options.textMaxIndent : void 0;
    ctx.textMarkerAlign = typeof options.textMarkerAlign === "string" ? options.textMarkerAlign : void 0;
    const escapedTextFont = escapeAttr(textFont);
    const lyricPt = Math.max(1, options.lyricSize ?? DEFAULT_LYRIC_SIZE_PT);
    ctx.lyricSize = lyricPt * dpi / 72;
    const rawMeasure = options.measureText ?? measureTextWidth;
    const measureCache = /* @__PURE__ */ new Map();
    ctx.measureText = (text, fontSize, fontFamily, bold, italic) => {
      if (text === "") return 0;
      const key = text + "\0" + fontSize + (bold ? "b" : "") + (italic ? "i" : "");
      let w = measureCache.get(key);
      if (w === void 0) {
        w = rawMeasure(text, fontSize, fontFamily, bold, italic);
        measureCache.set(key, w);
      }
      return w;
    };
    const rawAscent = options.measureAscent ?? measureTextAscent;
    const ascentCache = /* @__PURE__ */ new Map();
    ctx.measureAscent = (text, fontSize, fontFamily, bold, italic) => {
      if (text === "") return 0;
      const key = text + "\0" + fontSize + (bold ? "b" : "") + (italic ? "i" : "");
      let a = ascentCache.get(key);
      if (a === void 0) {
        a = rawAscent(text, fontSize, fontFamily, bold, italic);
        ascentCache.set(key, a);
      }
      return a;
    };
    ctx.lyricXHeight = measureXHeight(ctx.lyricSize, textFont);
    const fallbackAscent = ctx.measureAscent("\xC1y", ctx.lyricSize, textFont);
    const lyricLineHeight = ctx.lyricSize * (Number.isFinite(options.lyricLineSkip) ? options.lyricLineSkip : METRICS.lyricLineSkip);
    const hasIndent = "indent" in ast.header || "beh\xFAz\xE1s" in ast.header;
    const indentText = hasIndent ? ast.header["indent"] ?? ast.header["beh\xFAz\xE1s"] ?? "" : "";
    const indentFontSize = ctx.lyricSize * 0.85;
    const indentLines = indentText ? indentText.split("|").map((l) => l.trim()) : [];
    let indentWidth = 0;
    if (hasIndent) {
      const maxTextW = indentLines.length > 0 ? Math.max(...indentLines.map((l) => measureSegmentsWidth(parseFormattingToSegments(l), indentFontSize, textFont, ctx.measureText))) : 0;
      indentWidth = Math.max(maxTextW + ctx.staffSpace * 1.5, ctx.staffSpace * 2);
    }
    const sections = groupSections(ast.lines);
    const transposeAmount = parseInt(ast.header?.["transpose"] ?? "", 10) || 0;
    const transposeState = transposeAmount ? createTransposeState(transposeAmount) : null;
    const parts = [];
    let currentClef = { letter: "g", line: 2 };
    let currentKeySig = [];
    let hasSeenClef = false;
    let clefRowsBudget = hideRepeatClef ? 1 : Infinity;
    let firstSectionLayoutDone = false;
    let y = ss2(ctx, METRICS.titleTopPadding);
    let contentBottom = y;
    let globalRowIdx = 0;
    let prevRowBottom = 0;
    let minRenderedY = 0;
    let maxRenderedX = width;
    if (!options.noHeader && ast.header && (ast.header["title"] || ast.header["subtitle"] || ast.header["caption"] || ast.header["rubric"])) {
      const title = ast.header["title"];
      const subtitle = ast.header["subtitle"];
      const titleFontSize = ctx.lyricSize * 1.2;
      const titleLineHeight = titleFontSize * 1.2;
      if (title) {
        const lines = title.split("|").map((l) => l.trim());
        y += titleFontSize;
        for (let li = 0; li < lines.length; li++) {
          if (li > 0) y += titleLineHeight;
          parts.push(`<text x="${width / 2}" y="${y}" font-family="${escapedTextFont}" font-size="${titleFontSize}" font-weight="bold" text-anchor="middle" fill="#000">${renderSegments(parseFormattingToSegments(lines[li]))}</text>`);
        }
      }
      if (subtitle) {
        const subTitleFontSize = titleFontSize * 0.7;
        const subTitleLineHeight = subTitleFontSize * 1.2;
        const lines = subtitle.split("|").map((l) => l.trim());
        if (title) {
          y += titleLineHeight;
        }
        if (!title) y += subTitleFontSize;
        for (let li = 0; li < lines.length; li++) {
          if (li > 0) y += subTitleLineHeight;
          parts.push(`<text x="${width / 2}" y="${y}" font-family="${escapedTextFont}" font-size="${subTitleFontSize}" font-weight="bold" text-anchor="middle" fill="#000">${renderSegments(parseFormattingToSegments(lines[li]))}</text>`);
        }
      }
      if (title || subtitle) y += titleLineHeight * 1.2;
      const caption = ast.header["caption"];
      const rubric = ast.header["rubric"];
      if (caption || rubric) {
        const fontSize = ctx.lyricSize * 0.95;
        const lineHeight = fontSize * 1.2;
        const rubricLines = rubric ? rubric.split("|").map((l) => l.trim()) : [];
        const captionLines = caption ? caption.split("|").map((l) => l.trim()) : [];
        const maxLines = Math.max(rubricLines.length, captionLines.length);
        const rubricTop = maxLines - rubricLines.length;
        const captionTop = maxLines - captionLines.length;
        y += fontSize;
        for (let li = 0; li < maxLines; li++) {
          if (li > 0) y += lineHeight;
          const ri = li - rubricTop;
          const ci = li - captionTop;
          if (ri >= 0) {
            parts.push(`<text x="${ctx.leftMargin}" y="${y - 1.4 * ctx.staffSpace}" font-family="${escapedTextFont}" font-size="${fontSize}" font-variant="small-caps" text-anchor="start" fill="#000">${renderSegments(parseFormattingToSegments(rubricLines[ri]))}</text>`);
          }
          if (ci >= 0) {
            parts.push(`<text x="${width - ctx.rightMargin}" y="${y}" font-family="${escapedTextFont}" font-size="${fontSize}" font-style="italic" text-anchor="end" fill="#000">${renderSegments(parseFormattingToSegments(captionLines[ci]))}</text>`);
          }
        }
        y += fontSize * 0.4;
      }
    }
    const staffRightX = width - ctx.rightMargin;
    const clefPostGapPx = ss2(ctx, METRICS.clefPostGap);
    const clefInlinePostGapPx = ss2(ctx, METRICS.clefInlinePostGap);
    const keySigInlinePostGapPx = ss2(ctx, METRICS.keySigInlinePostGap);
    const barlineOffsetXPx = ss2(ctx, METRICS.barlineOffsetX);
    const barlineAdvancePx = ss2(ctx, METRICS.barlineAdvance);
    const barlinePostGapPx = ss2(ctx, METRICS.barlinePostGap);
    const barlineDoubleCenterOffsetPx = ss2(ctx, (METRICS.barlineOffsetX + METRICS.barlineDoubleSecondOffsetX) / 2);
    const parenWidthPx = ss2(ctx, METRICS.parenthesisWidth);
    const parenInnerGapPx = ss2(ctx, METRICS.parenthesisInnerGap);
    const parenVPadPx = ss2(ctx, METRICS.parenthesisVPadding);
    const parenLeftSpine = (pstate, rightSpine) => {
      if (pstate.firstLeftX == null || pstate.lastRightX == null) return pstate.hingeX;
      const closingInkGap = rightSpine - pstate.lastRightX;
      return pstate.firstLeftX - closingInkGap;
    };
    const spacerAdvancePx = ss2(ctx, METRICS.spacerAdvance);
    const halfNoteWPx = ss2(ctx, METRICS.noteBoxWidth) * 0.5;
    const accAdvFlatPx = ss2(ctx, METRICS.accidentalAdvanceFlat);
    const accAdvNaturalPx = ss2(ctx, METRICS.accidentalAdvanceNatural);
    const accAdvSharpPx = ss2(ctx, METRICS.accidentalAdvanceSharp);
    for (const sec of sections) {
      const items = flattenItems(sec.tokens);
      if (transposeState) applyTranspose(items, transposeState);
      const sectionHasClef = items.some((it) => it.kind === "clef");
      if (sectionHasClef) {
        hasSeenClef = true;
      }
      const drawClefForRows = hasSeenClef;
      let _labelLc = 0;
      const barlineLigsBeforeLabels = [];
      for (const it of items) {
        if (it.kind === "ligature") {
          _labelLc++;
        } else if (it.kind === "barline") {
          barlineLigsBeforeLabels.push(_labelLc);
        }
      }
      const verseSyllables = sec.lyrics.map(parseSyllables);
      const verseNotes = verseSyllables.map((arr) => expandSyllablesForLigatures(arr.filter((s) => s.kind === "note")));
      expandTenorRecitations(items, verseNotes);
      const verseWords = verseNotes.map(lyricWords);
      const verseBarlines = verseSyllables.map((arr) => arr.filter((s) => s.kind === "barline"));
      const verseCount = sec.lyrics.length;
      const totalLigatures = items.reduce((n, it) => n + (it.kind === "ligature" ? 1 : 0), 0);
      const alignSyllables = totalLigatures > 0 && verseCount > 0;
      const hasBarlineLabels = verseBarlines.some((arr) => arr.length > 0);
      const verseBarlineMaps = verseBarlines.map((lbls) => {
        const m = /* @__PURE__ */ new Map();
        for (const lbl of lbls) {
          const K = lbl.notesBefore ?? 0;
          for (let bi = 0; bi < barlineLigsBeforeLabels.length; bi++) {
            if (barlineLigsBeforeLabels[bi] >= K && !m.has(bi)) {
              m.set(bi, lbl);
              break;
            }
          }
        }
        return m;
      });
      for (const it of items) {
        if (it.kind === "ligature") {
          it.hasLyric = justifyWithoutLyrics;
        }
      }
      if (alignSyllables) {
        const minGap = ctx.measureText(" ", ctx.lyricSize, ctx.textFont) || ctx.lyricSize * 0.25;
        const hyphenReserve = hyphenRoom(ctx);
        const halfNoteW = halfNoteWPx;
        const ligInfo = [];
        let li = 0;
        for (let itemIdx = 0; itemIdx < items.length; itemIdx++) {
          const it = items[itemIdx];
          if (it.kind !== "ligature") {
            continue;
          }
          const totalNotes = it.groups.reduce((sum, g) => sum + g.length, 0);
          const lastG = it.groups[it.groups.length - 1];
          const lastN = lastG?.[lastG.length - 1];
          const isCentered = totalNotes === 1 && !it.groups.some((g) => g.some((n) => n.shape === "tenor"));
          let maxSylW = 0;
          let maxCurrRight = 0;
          let maxPrefixW = 0;
          for (const notes of verseNotes) {
            if (li < notes.length) {
              const note = notes[li];
              if (note.realLyric ?? hasRealLyricText(note)) {
                it.hasLyric = true;
              }
              const alignW = measureSegmentsWidth(note.alignSegments || note.segments, ctx.lyricSize, ctx.textFont, ctx.measureText);
              const suffixW = note.suffixSegments ? measureSegmentsWidth(note.suffixSegments, ctx.lyricSize, ctx.textFont, ctx.measureText) : 0;
              if (alignW > maxSylW) maxSylW = alignW;
              const rightEdge = isCentered ? halfNoteW + alignW / 2 + suffixW : alignW + suffixW;
              if (rightEdge > maxCurrRight) maxCurrRight = rightEdge;
              const fullW = measureSegmentsWidth(note.segments, ctx.lyricSize, ctx.textFont, ctx.measureText);
              const prefixW = fullW - alignW - suffixW;
              if (prefixW > maxPrefixW) maxPrefixW = prefixW;
            }
          }
          const visualRight = it.recitationGlyphless ? 0 : measureLigatureVisualRight(ctx, it.groups, it.gaps ?? []);
          const protectedCurrRight = isCentered ? maxCurrRight : Math.max(maxCurrRight, visualRight);
          ligInfo.push({ item: it, maxSylW, protectedCurrRight, isCentered, maxPrefixW, itemIdx, visualRight });
          it.rowStartOverhang = isCentered ? Math.max(0, maxSylW / 2 + maxPrefixW - halfNoteW) : maxPrefixW + ctx.staffSpace * 0.1;
          it.rowStartHasText = maxSylW > 0 || maxPrefixW > 0;
          it.lyricWord = it.recitationGlyphless ? null : verseWords.map((words) => words[li] ?? null);
          if (it.recitationGlyphless) {
            it.recitationWordShort = maxSylW < ctx.recitationLoneWordMin * ctx.lyricSize;
          }
          li++;
        }
        for (let i = 0; i < ligInfo.length; i++) {
          const { item, maxSylW, protectedCurrRight, isCentered } = ligInfo[i];
          const baseAdv = item.recitationGlyphless ? 0 : measureLigature(ctx, item.groups, item.gaps ?? []);
          const currRight = protectedCurrRight;
          const hasBarlineBetween = i + 1 < ligInfo.length && items.slice(ligInfo[i].itemIdx + 1, ligInfo[i + 1].itemIdx).some((it) => it.kind === "barline");
          let nextLeftIntrusion = 0;
          if (i + 1 < ligInfo.length && !hasBarlineBetween) {
            const next = ligInfo[i + 1];
            if (next.isCentered) {
              nextLeftIntrusion = Math.max(0, next.maxSylW / 2 + next.maxPrefixW - halfNoteW);
            } else {
              nextLeftIntrusion = next.maxPrefixW;
            }
          } else if (hasBarlineBetween && i + 1 < ligInfo.length) {
            const next = ligInfo[i + 1];
            const nextIntrusion = next.isCentered ? Math.max(0, next.maxSylW / 2 + next.maxPrefixW - halfNoteW) : next.maxPrefixW;
            if (nextIntrusion > 0) {
              const postExtra = Math.max(0, nextIntrusion + minGap - barlinePostGapPx);
              if (postExtra > 0) {
                for (let k = ligInfo[i + 1].itemIdx - 1; k > ligInfo[i].itemIdx; k--) {
                  if (items[k].kind === "barline") {
                    items[k].barlinePostExtra = Math.max(items[k].barlinePostExtra || 0, postExtra);
                    break;
                  }
                }
              }
            }
          }
          let pairConnected = false;
          let pairMandatory = false;
          if (i + 1 < ligInfo.length && !hasBarlineBetween) {
            let pairExists = false;
            let allHyphenated = true;
            for (const notes of verseNotes) {
              if (i < notes.length && i + 1 < notes.length) {
                pairExists = true;
                const ni = notes[i];
                const connects = ni.hyphenAfter || (ni.extenderCount || 0) >= 2 || ni.extender && !ni.extenderLast;
                if (!connects) {
                  allHyphenated = false;
                  break;
                }
                if (ni.hyphenAfter && ni.hyphenMandatory) pairMandatory = true;
              }
            }
            pairConnected = pairExists && allHyphenated;
          }
          const gap = pairConnected ? pairMandatory ? hyphenReserve : 0 : minGap;
          item.syllableExtra = Math.max(0, currRight + nextLeftIntrusion + gap - baseAdv);
          if (!item.recitationGlyphless) {
            item.syllableNeed = Math.max(currRight + nextLeftIntrusion + gap, ligInfo[i].visualRight);
          }
          const inkRight = Math.max(currRight, ligInfo[i].visualRight);
          item.rowEndSlack = Math.max(0, baseAdv + item.syllableExtra - inkRight);
        }
      }
      if (hasBarlineLabels) {
        const lyricSpace = ctx.measureText(" ", ctx.lyricSize, ctx.textFont) || ctx.lyricSize * 0.25;
        let bi = 0;
        for (const it of items) {
          if (it.kind !== "barline") {
            continue;
          }
          let maxW = 0;
          for (const barlineMap of verseBarlineMaps) {
            const lbl = barlineMap.get(bi);
            if (lbl) {
              const w = measureSegmentsWidth(lbl.segments, ctx.lyricSize, ctx.textFont, ctx.measureText);
              if (w > maxW) {
                maxW = w;
              }
            }
          }
          if (maxW > 0) {
            const baseAdv = measureBarline(ctx, it.value);
            it.barlineExtra = Math.max(0, maxW + 2 * lyricSpace - baseAdv);
          }
          bi++;
        }
      }
      const allowedClefRows = drawClefForRows ? clefRowsBudget : 0;
      const firstRowIndent = firstSectionLayoutDone ? 0 : indentWidth;
      firstSectionLayoutDone = true;
      const rows = layoutRowsWithCourtesyAccidentals(items, ctx, currentClef, staffRightX, drawClefForRows, currentKeySig, allowedClefRows, firstRowIndent);
      if (hideRepeatClef) {
        const clefRowsUsed = rows.filter((r) => r.drawStartClef).length;
        clefRowsBudget = Math.max(0, clefRowsBudget - clefRowsUsed);
      }
      if (rows.length === 0 && sec.lyrics.length > 0) {
        const emptyRowDrawClef = drawClefForRows && clefRowsBudget > 0;
        if (hideRepeatClef && emptyRowDrawClef) {
          clefRowsBudget = 0;
        }
        rows.push({
          items: [],
          itemsWidth: 0,
          justify: false,
          startClef: currentClef,
          startKeySig: currentKeySig,
          drawStartClef: emptyRowDrawClef,
          indentWidth: firstRowIndent
        });
      }
      let ligOffset = 0;
      let globalBarlineIdx = 0;
      let sectionContentBottom = y;
      let lastNote = null;
      let parenState = null;
      let braceState = null;
      let slurState = null;
      const completedBraceOpens = /* @__PURE__ */ new Set();
      const completedSlurOpens = /* @__PURE__ */ new Set();
      let pendingOpen = null;
      for (const row of rows) {
        for (const it of row.items) {
          if (it.kind === "brace-open") {
            pendingOpen = it;
          } else if (it.kind === "brace-close" && pendingOpen) {
            const isSlurKind = pendingOpen.braceKind === "slur" || pendingOpen.braceKind === "slurSolid";
            if (isSlurKind) {
              completedSlurOpens.add(pendingOpen);
            } else {
              completedBraceOpens.add(pendingOpen);
            }
            pendingOpen = null;
          }
        }
      }
      rows.forEach((row, rowIdx) => {
        const rowIndent = row.indentWidth || 0;
        const staffLeftX = ctx.leftMargin + rowIndent;
        const nominalTop = Math.max(0, y - 2 * ctx.staffSpace);
        const rowPrevBottom = prevRowBottom;
        const rowIdxGlobal = globalRowIdx++;
        const markerIdx = parts.length;
        parts.push("");
        let rowTopY = Infinity;
        let rowBottomY = -Infinity;
        const staffBottomY = y + ctx.staffHeight;
        parts.push(drawStaffLines(ctx, staffLeftX, staffRightX, staffBottomY));
        if (rowIndent > 0 && indentLines.length > 0) {
          const tx = ctx.leftMargin + rowIndent / 2;
          const indentLineHeight = indentFontSize * 1.2;
          const blockFirstY = staffBottomY - ctx.staffHeight / 2 + indentFontSize * 0.35 - (indentLines.length - 1) * indentLineHeight / 2;
          for (let li = 0; li < indentLines.length; li++) {
            parts.push(`<text x="${tx}" y="${blockFirstY + li * indentLineHeight}" font-family="${escapedTextFont}" font-size="${indentFontSize}" text-anchor="middle" fill="#000">${renderSegments(parseFormattingToSegments(indentLines[li]))}</text>`);
          }
        }
        let cursorX = staffLeftX;
        const rowLigatures = [];
        const rowBarlines = [];
        let rowCarryLeftX = null;
        let rowLastLigRightX = null;
        const recitationGlyphDrawn = /* @__PURE__ */ new Set();
        let rowClefRightX = -Infinity;
        if (row.drawStartClef) {
          const c = drawClef(ctx, row.startClef, cursorX, staffBottomY);
          if (c.minY < rowTopY) rowTopY = c.minY;
          if (c.maxY > rowBottomY) rowBottomY = c.maxY;
          parts.push(wrapSrc(row.startClefSource || {}, c.svg, "aretino-token aretino-clef", staffBottomY, ctx.staffHeight, void 0, void 0, sourceMap));
          rowClefRightX = cursorX + clefInkRightOffset(ctx, row.startClef);
          cursorX += c.advance - clefPostGapPx + clefInlinePostGapPx;
        }
        const startKeySig = row.startKeySig ?? [];
        if (!row.drawStartClef && startKeySig.length > 0) {
          cursorX += ctx.staffSpace / 2;
        }
        for (const acc of startKeySig) {
          const a = drawAccidental(ctx, acc.pitch, acc.symbol, cursorX, staffBottomY);
          parts.push(a.svg);
          cursorX += a.advance;
        }
        if (row.drawStartClef || startKeySig.length > 0) {
          if (startKeySig.length === 0) {
            cursorX += clefPostGapPx;
          } else {
            cursorX += ctx.staffSpace;
          }
        } else {
          cursorX += ctx.staffSpace;
        }
        let itemsWidth = row.itemsWidth;
        const lastItem = row.items[row.items.length - 1];
        if (lastItem && lastItem.kind === "barline") {
          itemsWidth -= lastItem.barlinePostExtra || 0;
        }
        let rowLyricLeftLimit = -Infinity;
        if (alignSyllables) {
          const firstLig = row.items.find((it) => it.kind === "ligature");
          const firstLigItem = firstLig && !firstLig.neumeContinuation ? firstLig : null;
          if (firstLigItem) {
            const halfNoteW = halfNoteWPx;
            const isCenteredFirst = firstLigItem.groups.reduce((s, g) => s + g.length, 0) === 1 && !firstLigItem.groups.some((g) => g.some((n) => n.shape === "tenor"));
            let maxAlignW = 0;
            let maxPrefixW = 0;
            for (const notes of verseNotes) {
              const ni = ligOffset;
              if (ni < notes.length) {
                const note = notes[ni];
                const aW = measureSegmentsWidth(note.alignSegments || note.segments, ctx.lyricSize, ctx.textFont, ctx.measureText);
                const sW = note.suffixSegments ? measureSegmentsWidth(note.suffixSegments, ctx.lyricSize, ctx.textFont, ctx.measureText) : 0;
                const fW = measureSegmentsWidth(note.segments, ctx.lyricSize, ctx.textFont, ctx.measureText);
                const pW = fW - aW - sW;
                if (aW > maxAlignW) maxAlignW = aW;
                if (pW > maxPrefixW) maxPrefixW = pW;
              }
            }
            let leftLimit = staffLeftX;
            if ((maxAlignW > 0 || maxPrefixW > 0) && rowClefRightX > -Infinity) {
              leftLimit = Math.max(leftLimit, rowClefRightX);
            }
            rowLyricLeftLimit = leftLimit;
            const textLeft = isCenteredFirst ? cursorX + halfNoteW - maxAlignW / 2 - maxPrefixW : cursorX - ctx.staffSpace * 0.1 - maxPrefixW;
            const slack = Math.max(0, staffRightX - cursorX - itemsWidth);
            const preGap = Math.min(Math.max(0, leftLimit - textLeft), slack);
            cursorX += preGap;
          }
        }
        const remaining = staffRightX - cursorX;
        const extra = Math.max(0, remaining - itemsWidth);
        const condenseCuts = row.condense > 0 && itemsWidth > remaining ? condenseGaps(ctx, row.items, itemsWidth - remaining)?.cuts ?? condenseCaps(ctx, row.items) : null;
        const expanderCount = row.items.reduce((n, it) => n + (it.kind === "expander" ? 1 : 0), 0);
        let extraPerExpander = 0;
        const gapExtras = new Array(row.items.length).fill(0);
        if (condenseCuts) {
          for (let i = 0; i < condenseCuts.length; i++) {
            gapExtras[i] = -condenseCuts[i];
          }
        } else if (extra > 0 && expanderCount > 0) {
          if (row.justify) {
            extraPerExpander = extra / expanderCount;
          }
        } else if (extra > 0) {
          const gapIdx = [];
          const floors = [];
          const targetFloors = [];
          for (let i = 0; i < row.items.length - 1; i++) {
            const it = row.items[i];
            const next = row.items[i + 1];
            if (!isLeveledGap(it, next)) {
              continue;
            }
            gapIdx.push(i);
            const f = gapFloor(ctx, it, next);
            floors.push(f);
            if (isLevelingTargetGap(it, next)) targetFloors.push(f);
          }
          if (gapIdx.length > 0) {
            let budget;
            if (row.justify) {
              budget = extra;
            } else {
              const top = levelingTarget(ctx, targetFloors);
              const neededToLevel = floors.reduce((s, f) => s + Math.max(0, top - f), 0);
              budget = Math.min(extra, neededToLevel);
            }
            const level = justificationWaterLevel(floors, budget);
            for (let k = 0; k < gapIdx.length; k++) {
              gapExtras[gapIdx[k]] = Math.max(0, level - floors[k]);
            }
          }
        }
        if (parenState) {
          const placeIdx = parts.length;
          parts.push("");
          cursorX += parenWidthPx;
          const hingeX = cursorX;
          cursorX += parenInnerGapPx;
          parenState = { placeIdx, hingeX, closeHingeX: hingeX, minY: Infinity, maxY: -Infinity };
        }
        if (braceState) {
          const placeIdx = parts.length;
          parts.push("");
          braceState = { ...braceState, placeIdx, startX: cursorX, endX: cursorX, minY: Infinity, isStart: false };
        }
        if (slurState) {
          const placeIdx = parts.length;
          parts.push("");
          slurState = { ...slurState, placeIdx, startX: cursorX, endX: cursorX, startNoteY: slurState.endNoteY, endNoteY: -Infinity, isStart: false };
        }
        for (let idx = 0; idx < row.items.length; idx++) {
          const it = row.items[idx];
          if (it.kind === "clef") {
            const c = drawClef(ctx, it.clef, cursorX, staffBottomY);
            if (c.minY < rowTopY) rowTopY = c.minY;
            if (c.maxY > rowBottomY) rowBottomY = c.maxY;
            parts.push(wrapSrc(it, c.svg, "aretino-token aretino-clef", staffBottomY, ctx.staffHeight, void 0, void 0, sourceMap));
            cursorX += c.advance + clefInlinePostGapPx;
          } else if (it.kind === "accidental") {
            const a = drawAccidental(ctx, it.pitch, it.symbol, cursorX, staffBottomY);
            parts.push(wrapSrc(it, a.svg, "aretino-token aretino-accidental", staffBottomY, ctx.staffHeight, void 0, void 0, sourceMap));
            let adv = a.advance;
            if (it.symbol === "x") adv = Math.max(adv, accAdvFlatPx);
            else if (it.symbol === "y") adv = Math.max(adv, accAdvNaturalPx);
            else if (it.symbol === "#") adv = Math.max(adv, accAdvSharpPx);
            cursorX += adv;
          } else if (it.kind === "keysig") {
            const startX = cursorX;
            const pieces = [];
            for (const acc of it.accidentals) {
              const a = drawAccidental(ctx, acc.pitch, acc.symbol, cursorX, staffBottomY);
              pieces.push(a.svg);
              cursorX += a.advance;
            }
            if (pieces.length) {
              parts.push(wrapSrc(it, pieces.join(""), "aretino-token aretino-keysig", staffBottomY, ctx.staffHeight, void 0, void 0, sourceMap));
              cursorX += keySigInlinePostGapPx;
            } else {
              cursorX = startX;
            }
          } else if (it.kind === "expander") {
            cursorX += ctx.expanderWidth + extraPerExpander;
          } else if (it.kind === "barline") {
            const extra2 = it.barlineExtra || 0;
            const postExtra = it.barlinePostExtra || 0;
            cursorX += extra2 / 2;
            let barlineSvg, barlineAdvance;
            if (it.value === "~") {
              const cy = lastNote ? pitchY(ctx, lastNote, staffBottomY) : staffBottomY - 2 * ctx.staffSpace;
              const onLine = lastNote ? pitchToPos(lastNote) % 2 === 0 : true;
              barlineSvg = drawPlicaBarline(ctx, cursorX + barlineOffsetXPx, cy, "down", onLine);
              barlineAdvance = barlineAdvancePx;
            } else {
              const b = drawBarline(ctx, it.value, cursorX, staffBottomY);
              barlineSvg = b.svg;
              barlineAdvance = b.advance;
            }
            parts.push(wrapSrc(it, barlineSvg, "aretino-token aretino-barline", staffBottomY, ctx.staffHeight, void 0, void 0, sourceMap));
            const offsetXPx = it.value === "||" || it.value === ":|" || it.value === "|:" || it.value === ":|:" || it.value === "|||" ? barlineDoubleCenterOffsetPx : barlineOffsetXPx;
            rowBarlines.push({ centerX: cursorX + offsetXPx, value: it.value, globalIdx: globalBarlineIdx });
            globalBarlineIdx++;
            cursorX += barlineAdvance + barlinePostGapPx + extra2 / 2 + postExtra;
          } else if (it.kind === "spacer") {
            cursorX += spacerAdvancePx * it.multiplier;
          } else if (it.kind === "paren-open") {
            const placeIdx = parts.length;
            parts.push("");
            cursorX += parenWidthPx;
            const hingeX = cursorX;
            cursorX += parenInnerGapPx;
            parenState = { placeIdx, hingeX, closeHingeX: hingeX, minY: Infinity, maxY: -Infinity };
          } else if (it.kind === "paren-close") {
            if (parenState) {
              const vPad = parenVPadPx;
              const spanTop = parenState.minY - vPad;
              if (parenState.minY < Infinity && spanTop < rowTopY) rowTopY = spanTop;
              const spanBot = parenState.maxY + vPad;
              if (parenState.maxY > -Infinity && spanBot > rowBottomY) rowBottomY = spanBot;
              const rightSpine = parenState.closeHingeX - parenInnerGapPx - parenWidthPx;
              parts[parenState.placeIdx] = drawParenthesis(ctx, parenLeftSpine(parenState, rightSpine), spanTop, spanBot, "left");
              parts.push(drawParenthesis(ctx, rightSpine, spanTop, spanBot, "right"));
              parenState = null;
            }
            cursorX += parenInnerGapPx + parenWidthPx;
          } else if (it.kind === "brace-open") {
            if (completedBraceOpens.has(it)) {
              const placeIdx = parts.length;
              parts.push("");
              braceState = { placeIdx, braceKind: it.braceKind, startX: cursorX, endX: cursorX, minY: Infinity, isStart: true };
            } else if (completedSlurOpens.has(it)) {
              const placeIdx = parts.length;
              parts.push("");
              slurState = { placeIdx, dashed: it.braceKind === "slur", startX: cursorX, endX: cursorX, startNoteY: null, endNoteY: -Infinity, isStart: true };
            }
          } else if (it.kind === "brace-close") {
            if (braceState) {
              braceState.label = it.label ?? null;
              const braceTop = _flushBrace(ctx, parts, braceState, staffBottomY, true, textFont);
              if (braceTop < rowTopY) rowTopY = braceTop;
              braceState = null;
            } else if (slurState) {
              const slurBot = _flushSlur(ctx, parts, slurState, staffBottomY, true);
              if (slurBot > rowBottomY) rowBottomY = slurBot;
              slurState = null;
            }
          } else if (it.kind === "ligature" && it.recitationGlyphless) {
            lastNote = it.groups[0][0];
            if (!recitationGlyphDrawn.has(it.recitationChainId)) {
              const g = emitLigature(ctx, it.groups, cursorX, staffBottomY, [], []);
              parts.push(wrapSrc(it, g.svg, "aretino-token aretino-ligature", staffBottomY, ctx.staffHeight, g.leftX, g.rightX - g.leftX, sourceMap));
              if (g.minY < rowTopY) rowTopY = g.minY;
              if (g.maxY > rowBottomY) rowBottomY = g.maxY;
              recitationGlyphDrawn.add(it.recitationChainId);
            }
            rowLigatures.push({ centerX: cursorX, leftX: cursorX, rightX: cursorX, shouldAlignLeft: true, maxY: -Infinity });
            cursorX += it.syllableExtra || 0;
          } else if (it.kind === "ligature") {
            const lastGroup = it.groups[it.groups.length - 1];
            lastNote = lastGroup[lastGroup.length - 1];
            const r = emitLigature(ctx, it.groups, cursorX, staffBottomY, it.gaps ?? [], it.leadingCourtesyAccidentals ?? []);
            let ligSvg = r.svg;
            if (r.minY < rowTopY) rowTopY = r.minY;
            if (r.maxY > rowBottomY) rowBottomY = r.maxY;
            if (it.label != null && r.minY < Infinity) {
              const fontSize = ctx.lyricSize * 0.8;
              const staffTopY = staffBottomY - 4 * ctx.staffSpace - ctx.lyricSize * 0.16;
              const labelY = Math.min(r.minY, staffTopY) - fontSize * 0.15;
              ligSvg += renderMixedLabel(parseFormattingToSegments(it.label), r.leftX, labelY, fontSize, ctx.textFont, "start", ctx.measureText);
              if (labelY - fontSize < rowTopY) rowTopY = labelY - fontSize;
            }
            parts.push(wrapSrc(it, ligSvg, "aretino-token aretino-ligature", staffBottomY, ctx.staffHeight, r.leftX, r.rightX - r.leftX, sourceMap));
            if (!it.neumeContinuation) {
              rowLigatures.push({ centerX: r.centerX, leftX: r.leftX, rightX: r.rightX, shouldAlignLeft: r.shouldAlignLeft, maxY: r.maxY });
            } else if (rowLigatures.length === 0 && rowCarryLeftX === null) {
              rowCarryLeftX = r.leftX;
            }
            rowLastLigRightX = r.rightX;
            if (parenState) {
              if (r.minY < parenState.minY) parenState.minY = r.minY;
              if (r.maxY > parenState.maxY) parenState.maxY = r.maxY;
              if (parenState.firstLeftX == null) parenState.firstLeftX = r.leftX;
              parenState.lastRightX = r.rightX;
              parenState.closeHingeX = cursorX + r.advance;
            }
            if (braceState) {
              if (r.minY < braceState.minY) braceState.minY = r.minY;
              braceState.endX = r.rightX;
            }
            if (slurState) {
              if (slurState.startNoteY == null) {
                slurState.startNoteY = r.maxY;
                slurState.startX = r.firstNoteCx ?? r.centerX;
              }
              slurState.endNoteY = r.maxY;
              slurState.endX = r.lastNoteCx ?? r.centerX;
            }
            cursorX += r.advance + (it.syllableExtra || 0);
          }
          if (idx < row.items.length - 1) {
            cursorX += gapExtras[idx];
          }
        }
        if (parenState) {
          const vPad = parenVPadPx;
          const spanTop = parenState.minY < Infinity ? parenState.minY - vPad : staffBottomY - 4 * ctx.staffSpace - vPad;
          if (spanTop < rowTopY) rowTopY = spanTop;
          const spanBot = parenState.maxY > -Infinity ? parenState.maxY + vPad : staffBottomY + vPad;
          if (spanBot > rowBottomY) rowBottomY = spanBot;
          const overflowRightSpine = parenState.closeHingeX - parenInnerGapPx - parenWidthPx;
          parts[parenState.placeIdx] = drawParenthesis(ctx, parenLeftSpine(parenState, overflowRightSpine), spanTop, spanBot, "left");
          parts.push(drawParenthesis(ctx, overflowRightSpine, spanTop, spanBot, "right"));
          parenState = { continuation: true };
        }
        if (braceState) {
          const braceTop = _flushBrace(ctx, parts, braceState, staffBottomY, false, textFont);
          if (braceTop < rowTopY) rowTopY = braceTop;
          braceState = { braceKind: braceState.braceKind, label: braceState.label, continuation: true };
        }
        if (slurState) {
          const slurBot = _flushSlur(ctx, parts, slurState, staffBottomY, false);
          if (slurBot > rowBottomY) rowBottomY = slurBot;
          slurState = { dashed: slurState.dashed, continuation: true };
        }
        const isLastRow = rowIdx === rows.length - 1;
        const rowLigCount = rowLigatures.length;
        const lowestNoteY = rowLowestNoteY(ctx, row, staffBottomY);
        const verseLayouts = [];
        if (alignSyllables) {
          for (let v = 0; v < verseCount; v++) {
            const notes = verseNotes[v];
            const start = ligOffset;
            const end = isLastRow ? Math.max(notes.length, ligOffset + rowLigCount) : ligOffset + rowLigCount;
            const carried = rowCarryLeftX !== null && start > 0 && notes[start - 1]?.hyphenAfter ? { leftX: rowCarryLeftX, rightX: rowLastLigRightX ?? rowCarryLeftX } : null;
            verseLayouts.push(layoutRowSyllables(ctx, notes.slice(start, end), rowLigatures, rowLyricLeftLimit, carried));
          }
        }
        let lyricY;
        if (alignSyllables && verseLayouts.length > 0) {
          lyricY = firstLyricBaselineY(
            ctx,
            verseLayouts[0].spans,
            rowLigatures,
            staffBottomY,
            lowestNoteY,
            fallbackAscent
          );
        } else {
          const lyricTopY = Math.max(
            (lowestNoteY > staffBottomY ? lowestNoteY : staffBottomY) + ctx.lyricDistance,
            staffBottomY + ctx.lyricMinStaffDistance
          );
          lyricY = lyricTopY + fallbackAscent;
        }
        if (alignSyllables) {
          for (let v = 0; v < verseCount; v++) {
            const aligned = emitLaidOutSyllables(ctx, verseLayouts[v], lyricY);
            parts.push(aligned.svg);
            if (aligned.maxX > maxRenderedX) maxRenderedX = aligned.maxX;
            const barlineMap = verseBarlineMaps[v];
            const matchedLabels = [];
            const matchedBarlines = [];
            for (const rb of rowBarlines) {
              const lbl = barlineMap.get(rb.globalIdx);
              if (lbl) {
                matchedLabels.push(lbl);
                matchedBarlines.push(rb);
              }
            }
            if (matchedLabels.length > 0) {
              parts.push(emitBarlineLabels(ctx, matchedLabels, matchedBarlines, lyricY));
            }
            lyricY += lyricLineHeight;
          }
          ligOffset += rowLigCount;
          const lastLyricBottom = lyricY - lyricLineHeight + ctx.lyricSize * 0.3;
          contentBottom = Math.max(contentBottom, lastLyricBottom);
          sectionContentBottom = lastLyricBottom;
          y = lastLyricBottom + ctx.staffGap;
          prevRowBottom = lastLyricBottom;
        } else if (isLastRow && verseCount > 0) {
          for (const lyric of sec.lyrics) {
            const lyricSvg = `<text xml:space="preserve" x="${staffLeftX}" y="${lyricY}" font-family="${escapedTextFont}" font-size="${ctx.lyricSize}" fill="#000">${formatLyricLine(lyric)}</text>`;
            parts.push(wrapSrc(lyric, lyricSvg, "aretino-lyric aretino-lyric-line", void 0, void 0, void 0, void 0, sourceMap));
            lyricY += lyricLineHeight;
          }
          const lastLyricBottom = lyricY - lyricLineHeight + ctx.lyricSize * 0.3;
          contentBottom = Math.max(contentBottom, lastLyricBottom);
          sectionContentBottom = lastLyricBottom;
          y = lastLyricBottom + ctx.staffGap;
          prevRowBottom = lastLyricBottom;
        } else {
          y = staffBottomY;
          sectionContentBottom = y;
          contentBottom = Math.max(contentBottom, y);
          prevRowBottom = staffBottomY;
        }
        if (rowBottomY > prevRowBottom) {
          prevRowBottom = rowBottomY;
          y = Math.max(y, rowBottomY + ctx.staffGap);
        }
        contentBottom = Math.max(contentBottom, rowBottomY);
        sectionContentBottom = Math.max(sectionContentBottom, rowBottomY);
        const contentTopY = Math.min(nominalTop, rowTopY);
        if (rowTopY < minRenderedY) minRenderedY = rowTopY;
        parts[markerIdx] = `<!-- aretino-row ${rowIdxGlobal} ${nominalTop.toFixed(3)} ${rowPrevBottom.toFixed(3)} ${contentTopY.toFixed(3)} -->`;
      });
      if (sec.verses && sec.verses.length > 0) {
        const verseResult = renderVerseLines(ctx, sec.verses, ctx.leftMargin, staffRightX, sectionContentBottom);
        if (rows.length === 0) {
          let rowPrev = prevRowBottom;
          for (const block of verseResult.blocks) {
            parts.push(`<!-- aretino-row ${globalRowIdx++} ${block.top.toFixed(3)} ${rowPrev.toFixed(3)} ${block.top.toFixed(3)} -->`);
            parts.push(block.svg);
            rowPrev = block.bottom;
          }
        } else {
          parts.push(verseResult.svg);
        }
        y = verseResult.bottom + ctx.staffGap;
        contentBottom = Math.max(contentBottom, verseResult.bottom);
        prevRowBottom = verseResult.bottom;
      }
      currentClef = trailingClef(items, currentClef);
      currentKeySig = trailingKeySig(items, currentKeySig);
    }
    const totalHeight = canvasHeight || contentBottom + ctx.staffSpace * 0.5;
    const viewTop = Math.min(0, Math.floor(minRenderedY));
    const viewWidth = maxRenderedX > width ? Math.ceil(maxRenderedX) + 1 : width;
    const viewHeight = totalHeight - viewTop;
    const renderW = Math.round(viewWidth * zoom);
    const renderH = Math.round(viewHeight * zoom);
    const interactiveStyle = sourceMap ? HIGHLIGHT_STYLE : "";
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 ${viewTop} ${viewWidth} ${viewHeight}" width="${renderW}" height="${renderH}" preserveAspectRatio="xMidYMin meet" style="display:block">${interactiveStyle}${parts.join("")}<!-- aretino-rows-end ${totalHeight.toFixed(3)} --></svg>`;
  }
  function splitRowSVGs(svg) {
    const svgTagMatch = svg.match(/^<svg([^>]*)>/);
    if (!svgTagMatch) return null;
    const attrs = svgTagMatch[1];
    const viewBoxMatch = attrs.match(/viewBox="-?[\d.]+ -?[\d.]+ ([\d.]+) -?[\d.]+"/);
    if (!viewBoxMatch) return null;
    const totalW = parseFloat(viewBoxMatch[1]);
    const widthAttrMatch = attrs.match(/\bwidth="(\d+)"/);
    const zoom = widthAttrMatch ? parseInt(widthAttrMatch[1]) / totalW : 1;
    const inner = svg.slice(svgTagMatch[0].length, svg.lastIndexOf("</svg>"));
    const rowRe = /<!--\s*aretino-row\s+\d+\s+(-?[\d.]+)\s+(-?[\d.]+)(?:\s+(-?[\d.]+))?\s*-->/g;
    const markers = [];
    let m;
    while ((m = rowRe.exec(inner)) !== null) {
      const y = parseFloat(m[1]);
      markers.push({
        y,
        prevContentBottom: parseFloat(m[2]),
        contentTopY: m[3] !== void 0 ? parseFloat(m[3]) : y,
        markerStart: m.index,
        contentStart: m.index + m[0].length
      });
    }
    if (markers.length === 0) return null;
    const endMatch = inner.match(/<!--\s*aretino-rows-end\s+([\d.]+)\s*-->/);
    const totalH = endMatch ? parseFloat(endMatch[1]) : 0;
    const innerEnd = endMatch ? endMatch.index : inner.length;
    const preamble = inner.slice(0, markers[0].markerStart);
    return markers.map((marker, i) => {
      const contentEnd = i + 1 < markers.length ? markers[i + 1].markerStart : innerEnd;
      const content = inner.slice(marker.contentStart, contentEnd);
      const renderW = Math.round(totalW * zoom);
      const nextTopY = i + 1 < markers.length ? markers[i + 1].y : totalH;
      const nextPCB = i + 1 < markers.length ? markers[i + 1].prevContentBottom : totalH;
      const bottomY = Math.max(nextTopY, nextPCB);
      if (i === 0) {
        const rowTop2 = Math.min(0, marker.contentTopY);
        const rowH2 = parseFloat((bottomY - rowTop2).toFixed(3));
        const renderH2 = Math.round(rowH2 * zoom);
        return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 ${rowTop2} ${totalW} ${rowH2}" width="${renderW}" height="${renderH2}" preserveAspectRatio="xMidYMin meet" style="display:block">${preamble}${content}</svg>`;
      }
      const rowTop = Math.min(marker.y, marker.contentTopY);
      const rowH = parseFloat((bottomY - rowTop).toFixed(3));
      const renderH = Math.round(rowH * zoom);
      return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${totalW} ${rowH}" width="${renderW}" height="${renderH}" preserveAspectRatio="xMidYMin meet" style="display:block"><g transform="translate(0,${(-rowTop).toFixed(3)})">${content}</g></svg>`;
    });
  }

  // entry.js
  function measureKey(text, fontSize, bold, italic) {
    return text + "\0" + Math.round(fontSize * 64) + (bold ? "b" : "") + (italic ? "i" : "");
  }
  function approximateWidth(text, fontSize, bold, italic) {
    return text.length * fontSize * 0.55 * (bold ? 1.1 : 1) * (italic ? 0.95 : 1);
  }
  function makeMeasure(known, missing, approximate) {
    return (text, fontSize, fontFamily, bold, italic) => {
      if (text === "") return 0;
      const key = measureKey(text, fontSize, bold, italic);
      const value = known[key];
      if (typeof value === "number") return value;
      if (!(key in missing)) {
        missing[key] = { key, text, fontSize, bold: !!bold, italic: !!italic };
      }
      return approximate(text, fontSize, bold, italic);
    };
  }
  function render(argsJson) {
    let args;
    try {
      args = JSON.parse(argsJson);
    } catch (e) {
      return JSON.stringify({ ok: false, error: "bad args: " + e });
    }
    const widths = args.widths || {};
    const missingWidths = {};
    const options = Object.assign({}, args.options, {
      measureText: makeMeasure(widths, missingWidths, approximateWidth)
    });
    try {
      const svg = renderAretino(args.source, options);
      const result = {
        ok: true,
        missingWidths: Object.values(missingWidths)
      };
      if (args.split) {
        result.rows = splitRowSVGs(svg);
      } else {
        result.svg = svg;
      }
      const viewBox = /viewBox="(-?[\d.]+) (-?[\d.]+) ([\d.]+) ([\d.]+)"/.exec(svg);
      if (viewBox) {
        result.viewBox = viewBox.slice(1).map(Number);
      }
      return JSON.stringify(result);
    } catch (e) {
      return JSON.stringify({ ok: false, error: String(e && e.message || e) });
    }
  }
  function parse(source) {
    try {
      return JSON.stringify({ ok: true, ast: parseAretino(source) });
    } catch (e) {
      return JSON.stringify({ ok: false, error: String(e && e.message || e) });
    }
  }
  return __toCommonJS(entry_exports);
})();
Aretino.version = "0.26.1";
