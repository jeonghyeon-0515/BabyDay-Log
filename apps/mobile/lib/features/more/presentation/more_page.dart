import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../../activity/presentation/activity_create_page.dart';
import '../../activity/presentation/activity_list_page.dart';
import '../../activity/data/activity_repository.dart';
import '../../baby/domain/baby_summary.dart';
import '../../baby/presentation/baby_context_header.dart';
import '../../baby/presentation/baby_create_page.dart';
import '../../baby/presentation/baby_list_page.dart';
import '../../baby/data/baby_repository.dart';
import '../../diary/presentation/diary_create_page.dart';
import '../../diary/presentation/diary_list_page.dart';
import '../../diary/data/diary_repository.dart';
import '../../household/presentation/household_create_page.dart';
import '../../household/presentation/household_list_page.dart';
import '../../household/data/household_repository.dart';
import '../../profile/presentation/profile_edit_page.dart';
import '../../profile/data/profile_repository.dart';
import 'auth_manage_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    required this.bootstrapState,
    required this.selectedBaby,
    required this.availableBabies,
    required this.onSelectBaby,
  });

  final BootstrapState bootstrapState;
  final BabySummary? selectedBaby;
  final List<BabySummary> availableBabies;
  final ValueChanged<String> onSelectBaby;

  @override
  Widget build(BuildContext context) {
    final profileRepository = bootstrapState.supabaseInitialized
        ? ProfileRepository()
        : null;
    final householdRepository = bootstrapState.supabaseInitialized
        ? HouseholdRepository()
        : null;
    final babyRepository = bootstrapState.supabaseInitialized
        ? BabyRepository()
        : null;
    final activityRepository = bootstrapState.supabaseInitialized
        ? ActivityRepository()
        : null;
    final diaryRepository = bootstrapState.supabaseInitialized
        ? DiaryRepository()
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('더보기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BabyContextHeader(
            selectedBaby: selectedBaby,
            availableBabies: availableBabies,
            onSelectBaby: onSelectBaby,
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '계정',
            children: [
              _SectionTile(
                title: '계정',
                subtitle: '로그인 상태를 확인합니다.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        AuthManagePage(bootstrapState: bootstrapState),
                  ),
                ),
              ),
              _SectionTile(
                title: '프로필',
                subtitle: '이름을 수정합니다.',
                onTap: profileRepository == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ProfileEditPage(repository: profileRepository),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '가족 설정',
            children: [
              _SectionTile(
                title: '가족 목록',
                subtitle: '참여 중인 가족을 확인합니다.',
                onTap: householdRepository == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => HouseholdListPage(
                            repository: householdRepository,
                          ),
                        ),
                      ),
              ),
              _SectionTile(
                title: '가족 만들기',
                subtitle: '새 가족을 만듭니다.',
                onTap: householdRepository == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => HouseholdCreatePage(
                            repository: householdRepository,
                          ),
                        ),
                      ),
              ),
              _SectionTile(
                title: '아기 목록',
                subtitle: '등록된 아기를 확인합니다.',
                onTap: babyRepository == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              BabyListPage(repository: babyRepository),
                        ),
                      ),
              ),
              _SectionTile(
                title: '아기 등록',
                subtitle: '새 아기를 등록합니다.',
                onTap: babyRepository == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              BabyCreatePage(repository: babyRepository),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '기록 관리',
            children: [
              _SectionTile(
                title: '기록 목록',
                subtitle: '기록을 확인합니다.',
                onTap: activityRepository == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ActivityListPage(repository: activityRepository),
                        ),
                      ),
              ),
              _SectionTile(
                title: '기록 추가',
                subtitle: '새 기록을 남깁니다.',
                onTap: activityRepository == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ActivityCreatePage(
                            repository: activityRepository,
                          ),
                        ),
                      ),
              ),
              _SectionTile(
                title: '일기 목록',
                subtitle: '내 일기를 확인합니다.',
                onTap: diaryRepository == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              DiaryListPage(repository: diaryRepository),
                        ),
                      ),
              ),
              _SectionTile(
                title: '일기 작성',
                subtitle: '새 일기를 작성합니다.',
                onTap: diaryRepository == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              DiaryCreatePage(repository: diaryRepository),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.title, required this.subtitle, this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
