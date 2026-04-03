import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../../activity/presentation/activity_status_card.dart';
import '../../auth/presentation/auth_status_card.dart';
import '../../baby/presentation/baby_status_card.dart';
import '../../household/presentation/household_status_card.dart';
import '../../profile/presentation/profile_status_card.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('더보기')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AuthStatusCard(bootstrapState: bootstrapState),
          const SizedBox(height: 12),
          ProfileStatusCard(bootstrapState: bootstrapState),
          const SizedBox(height: 12),
          HouseholdStatusCard(bootstrapState: bootstrapState),
          const SizedBox(height: 12),
          BabyStatusCard(bootstrapState: bootstrapState),
          const SizedBox(height: 12),
          ActivityStatusCard(bootstrapState: bootstrapState),
        ],
      ),
    );
  }
}
