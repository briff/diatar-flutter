import 'package:flutter/material.dart';

import 'chord_renderer.dart';

class ChordEditorLabels {
  const ChordEditorLabels({
    required this.insertTitle,
    required this.editTitle,
    required this.rootNote,
    required this.quality,
    required this.major,
    required this.minor,
    required this.modifier,
    required this.bassNote,
    required this.none,
    required this.preview,
    required this.cancel,
    required this.apply,
  });

  final String insertTitle;
  final String editTitle;
  final String rootNote;
  final String quality;
  final String major;
  final String minor;
  final String modifier;
  final String bassNote;
  final String none;
  final String preview;
  final String cancel;
  final String apply;
}

Future<String?> showChordEditorDialog({
  required BuildContext context,
  required ChordEditorLabels labels,
  String? initialSource,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) =>
        _ChordEditorDialog(labels: labels, initialSource: initialSource),
  );
}

class _ChordEditorDialog extends StatefulWidget {
  const _ChordEditorDialog({required this.labels, this.initialSource});

  final ChordEditorLabels labels;
  final String? initialSource;

  @override
  State<_ChordEditorDialog> createState() => _ChordEditorDialogState();
}

class _ChordEditorDialogState extends State<_ChordEditorDialog> {
  static const List<String> _notes = <String>[
    'C',
    'C-',
    'C+',
    'D',
    'D-',
    'D+',
    'E',
    'E-',
    'E+',
    'F',
    'F-',
    'F+',
    'G',
    'G-',
    'G+',
    'A',
    'A-',
    'A+',
    'H-',
    'H',
    'H+',
  ];

  late String _root;
  late bool _minor;
  late String _modifier;
  String? _bass;

  @override
  void initState() {
    super.initState();
    final DiatarChord? initial = widget.initialSource == null
        ? null
        : DiatarChord.tryParse(widget.initialSource!);
    _root = initial?.rootCode ?? 'C';
    _minor = initial?.isMinor ?? false;
    _modifier = initial?.modifierCode ?? '';
    _bass = initial?.bassCode;
  }

  List<String> get _availableModifiers => DiatarChord.supportedModifiers
      .where(
        (String modifier) =>
            DiatarChord.supportsModifier(modifier, minor: _minor),
      )
      .toList();

  String get _source =>
      '$_root${_minor ? 'm' : ''}$_modifier${_bass == null ? '' : '/$_bass'}';

  String _noteLabel(String source) {
    return DiatarChord.tryParse(
      source,
    )!.parts.map((ChordPart part) => part.text).join();
  }

  String _modifierLabel(String modifier) {
    if (modifier.isEmpty) {
      return widget.labels.none;
    }
    return DiatarChord.tryParse(
      'C$modifier',
    )!.parts.skip(1).map((ChordPart part) => part.text).join();
  }

  @override
  Widget build(BuildContext context) {
    final ChordEditorLabels labels = widget.labels;
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        widget.initialSource == null ? labels.insertTitle : labels.editTitle,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: _root,
                decoration: InputDecoration(labelText: labels.rootNote),
                items: _notes
                    .map(
                      (String note) => DropdownMenuItem<String>(
                        value: note,
                        child: Text(_noteLabel(note)),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _root = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(labelText: labels.quality),
                child: SegmentedButton<bool>(
                  segments: <ButtonSegment<bool>>[
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(labels.major),
                    ),
                    ButtonSegment<bool>(value: true, label: Text(labels.minor)),
                  ],
                  selected: <bool>{_minor},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() {
                      _minor = selection.single;
                      if (!DiatarChord.supportsModifier(
                        _modifier,
                        minor: _minor,
                      )) {
                        _modifier = '';
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey<bool>(_minor),
                initialValue: _modifier,
                decoration: InputDecoration(labelText: labels.modifier),
                items: _availableModifiers
                    .map(
                      (String modifier) => DropdownMenuItem<String>(
                        value: modifier,
                        child: Text(_modifierLabel(modifier)),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _modifier = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _bass,
                decoration: InputDecoration(labelText: labels.bassNote),
                items: <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(labels.none),
                  ),
                  ..._notes.map(
                    (String note) => DropdownMenuItem<String?>(
                      value: note,
                      child: Text(_noteLabel(note)),
                    ),
                  ),
                ],
                onChanged: (String? value) => setState(() => _bass = value),
              ),
              const SizedBox(height: 20),
              Text(labels.preview, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Center(
                child: ChordDisplay(
                  source: _source,
                  style: theme.textTheme.headlineSmall ?? const TextStyle(),
                  borderColor: theme.colorScheme.outline,
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(labels.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_source),
          child: Text(labels.apply),
        ),
      ],
    );
  }
}
