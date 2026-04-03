import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/supabase/supabase_bootstrap.dart';

typedef BootstrapAppBuilder = Widget Function(BootstrapState state);

class BootstrapState {
  const BootstrapState({
    required this.config,
    required this.supabaseInitialized,
    this.initializationError,
  });

  final AppConfig config;
  final bool supabaseInitialized;
  final Object? initializationError;

  bool get hasError => initializationError != null;
}

Future<void> bootstrap(BootstrapAppBuilder builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  Object? initializationError;
  var supabaseInitialized = false;

  if (config.hasSupabaseCredentials) {
    try {
      await SupabaseBootstrap.initialize(config);
      supabaseInitialized = true;
    } catch (error, stackTrace) {
      initializationError = error;
      debugPrint('Supabase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(
    builder(
      BootstrapState(
        config: config,
        supabaseInitialized: supabaseInitialized,
        initializationError: initializationError,
      ),
    ),
  );
}
