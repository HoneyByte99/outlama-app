import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'src/app/app.dart';

Future<void> main() async {
  // Catch all uncaught async errors.
  runZonedGuarded(() async {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: binding);

    // Flutter framework errors (widget build failures, layout overflows, etc.)
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      // TODO: send to Crashlytics when added
      if (kDebugMode) debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    // Platform-level errors (native crashes, unhandled platform exceptions)
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) debugPrint('PlatformError: $error\n$stack');
      // TODO: send to Crashlytics when added
      return true; // prevents app termination
    };

    await Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      initializeDateFormatting('fr_FR'),
    ]);

    FlutterNativeSplash.remove();
    runApp(
      const ProviderScope(
        child: OutalmaServiceApp(),
      ),
    );
  }, (error, stack) {
    if (kDebugMode) debugPrint('ZoneError: $error\n$stack');
    // TODO: send to Crashlytics when added
  });
}
