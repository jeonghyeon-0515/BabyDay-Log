import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../../auth/presentation/auth_status_card.dart';
import '../../profile/presentation/profile_status_card.dart';
import '../../household/presentation/household_status_card.dart';
import '../../baby/presentation/baby_status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = bootstrapState.config;

    return Scaffold(
      appBar: AppBar(title: const Text('BabyDay Log')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Flutter + Supabase Bootstrap',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '다음 단계에서 인증/프로필/household/baby/activity 기능을 이 구조 위에 확장합니다.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _InfoCard(
            title: '앱 환경',
            children: [
              _InfoRow(label: 'APP_ENV', value: config.environment),
              _InfoRow(label: 'PROJECT_REF', value: config.projectRef),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Supabase 연결 상태',
            children: [
              _InfoRow(
                label: '초기화 상태',
                value: bootstrapState.supabaseInitialized
                    ? '연결 완료'
                    : config.hasSupabaseCredentials
                    ? '초기화 실패'
                    : 'dart-define 값 대기',
              ),
              _InfoRow(
                label: 'SUPABASE_URL',
                value: config.supabaseUrl.isEmpty
                    ? 'not-set'
                    : config.supabaseUrl,
              ),
              _InfoRow(
                label: 'SUPABASE_ANON_KEY',
                value: config.redactedAnonKey,
              ),
            ],
          ),
          if (bootstrapState.hasError) ...[
            const SizedBox(height: 12),
            _InfoCard(
              title: '초기화 오류',
              children: [
                Text(
                  '${bootstrapState.initializationError}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          AuthStatusCard(bootstrapState: bootstrapState),
          const SizedBox(height: 12),
          ProfileStatusCard(bootstrapState: bootstrapState),
          const SizedBox(height: 12),
          HouseholdStatusCard(bootstrapState: bootstrapState),
          const SizedBox(height: 12),
          BabyStatusCard(bootstrapState: bootstrapState),
          const SizedBox(height: 12),
          const _InfoCard(
            title: '다음 작업 예정',
            children: [
              Text('1. Auth / Profile / Household 구조 구현'),
              SizedBox(height: 6),
              Text('2. Baby / Activity repository 및 기본 화면 연결'),
              SizedBox(height: 6),
              Text('3. Kakao > Naver > Google 로그인 순서 반영'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 136,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
