import 'package:flutter/material.dart';

import '../bootstrap.dart';
import '../features/app_shell/presentation/app_shell_page.dart';

class BabyDayLogApp extends StatelessWidget {
  const BabyDayLogApp({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BabyDay Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7A5AF8)),
        useMaterial3: true,
      ),
      home: AppShellPage(bootstrapState: bootstrapState),
    );
  }
}
