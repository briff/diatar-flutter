import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'package:diatar_common/diatar_common.dart';

import '../l10n/generated/app_localizations.dart';
import 'controllers/projection_controller.dart';
import 'ui/home_page.dart';

class DiaVetitoApp extends StatefulWidget {
  const DiaVetitoApp({super.key});

  @override
  State<DiaVetitoApp> createState() => _DiaVetitoAppState();
}

class _DiaVetitoAppState extends State<DiaVetitoApp> {
  final ProjectionController _controller = ProjectionController();

  Locale? _resolveAppLocale(String languageCode) {
    if (languageCode.trim().isEmpty) {
      return null;
    }
    for (final Locale locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == languageCode) {
        return locale;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _controller.init();
    // Booting the JavaScript engine is the expensive part of an Aretino
    // slide, not rendering one, so it happens here rather than on the first
    // chant (plans/aretino-projection-v1.md, Decision 6).
    unawaited(AretinoRenderService.instance.ensureLoaded());

    unawaited(KottaAssets.ensureLoaded().then((_) {
      if (mounted) {
        setState(() {});
      }
    }));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final Locale? appLocale = _resolveAppLocale(_controller.settings.appLanguage);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: appLocale,
          theme: ThemeData.dark(useMaterial3: true),
          home: HomePage(controller: _controller),
        );
      },
    );
  }
}
