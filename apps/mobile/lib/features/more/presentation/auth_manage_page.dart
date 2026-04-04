import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../../auth/presentation/auth_status_card.dart';

class AuthManagePage extends StatelessWidget {
  const AuthManagePage({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('계정 관리')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [AuthStatusCard(bootstrapState: bootstrapState)],
      ),
    );
  }
}
