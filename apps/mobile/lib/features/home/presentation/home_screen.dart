import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../../activity/data/activity_repository.dart';
import '../../activity/domain/activity_event_summary.dart';
import '../../activity/presentation/activity_create_page.dart';
import '../../baby/data/baby_repository.dart';
import '../../baby/domain/baby_summary.dart';
import '../../baby/presentation/baby_context_header.dart';
import '../../baby/presentation/baby_create_page.dart';
import '../../household/data/household_repository.dart';
import '../../household/domain/household_summary.dart';
import '../../household/presentation/household_create_page.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/profile_edit_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProfileRepository? _profileRepository;
  HouseholdRepository? _householdRepository;
  ActivityRepository? _activityRepository;

  UserProfile? _profile;
  HouseholdSummary? _household;
  BabySummary? _baby;
  ActivityEventSummary? _latestEvent;

  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.bootstrapState.supabaseInitialized) {
      _profileRepository = ProfileRepository();
      _householdRepository = HouseholdRepository();
      _activityRepository = ActivityRepository();
      _loadHomeData();
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBaby?.id != widget.selectedBaby?.id) {
      _loadHomeData();
    }
  }

  Future<void> _loadHomeData() async {
    final profileRepository = _profileRepository;
    final householdRepository = _householdRepository;
    final activityRepository = _activityRepository;

    if (profileRepository == null ||
        householdRepository == null ||
        activityRepository == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        profileRepository.fetchMyProfile(),
        householdRepository.fetchMyHouseholds(),
        activityRepository.fetchRecentActivityEvents(
          limit: 1,
          babyId: widget.selectedBaby?.id,
        ),
      ]);

      if (!mounted) return;

      final households = (results[1] as List<HouseholdSummary>);
      final events = (results[2] as List<ActivityEventSummary>);

      setState(() {
        _profile = results[0] as UserProfile?;
        _household = households.isEmpty ? null : households.first;
        _baby = widget.selectedBaby;
        _latestEvent = events.isEmpty ? null : events.first;
        _message = _buildMessage(
          profile: _profile,
          household: _household,
          baby: _baby,
          event: _latestEvent,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '홈 데이터 조회 실패: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _buildMessage({
    required UserProfile? profile,
    required HouseholdSummary? household,
    required BabySummary? baby,
    required ActivityEventSummary? event,
  }) {
    if (profile == null) {
      return '프로필을 먼저 설정해 주세요.';
    }
    if (household == null) {
      return '가족을 먼저 만들어 주세요.';
    }
    if (baby == null) {
      return '아기를 등록하면 홈이 채워져요.';
    }
    if (event == null) {
      return '첫 기록을 남겨 보세요.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canUseHome = widget.bootstrapState.supabaseInitialized;
    final headlineName = _profile?.displayName.trim().isNotEmpty == true
        ? _profile!.displayName
        : '육퇴로그';

    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            BabyContextHeader(
              selectedBaby: widget.selectedBaby,
              availableBabies: widget.availableBabies,
              onSelectBaby: widget.onSelectBaby,
            ),
            const SizedBox(height: 12),
            _HeroCard(
              title: '안녕하세요, $headlineName',
              subtitle: _baby == null
                  ? '아기를 등록하면 오늘 상태를 볼 수 있어요.'
                  : '${_baby!.name}의 오늘 기록을 확인해 보세요.',
              badge: _latestEvent == null ? '새 기록 없음' : _latestEvent!.eventTypeLabel,
              badgeColor: colors.primaryContainer,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  label: '아기',
                  value: _baby?.name ?? '미등록',
                  helper: _baby?.birthDate ?? '등록이 필요해요',
                ),
                _MetricCard(
                  label: '가족',
                  value: _household?.name ?? '미등록',
                  helper: _household?.role ?? '가족을 만들어 주세요',
                ),
                _MetricCard(
                  label: '최근 로그',
                  value: _latestEvent?.eventTypeLabel ?? '없음',
                  helper: _latestEvent?.recordedAt ?? '기록을 남겨 보세요',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryCard(
              title: '빠른 실행',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _activityRepository != null
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ActivityCreatePage(
                                repository: _activityRepository!,
                              ),
                            ),
                          )
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('기록 추가'),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: canUseHome && !_isLoading ? _loadHomeData : null,
                        child: Text(_isLoading ? '불러오는 중...' : '새로고침'),
                      ),
                      OutlinedButton(
                        onPressed: _profileRepository != null
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ProfileEditPage(
                                    repository: _profileRepository!,
                                  ),
                                ),
                              )
                            : null,
                        child: const Text('프로필'),
                      ),
                      OutlinedButton(
                        onPressed: _householdRepository != null
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => HouseholdCreatePage(
                                    repository: _householdRepository!,
                                  ),
                                ),
                              )
                            : null,
                        child: const Text('가족 만들기'),
                      ),
                      OutlinedButton(
                        onPressed: canUseHome
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      BabyCreatePage(repository: BabyRepository()),
                                ),
                              )
                            : null,
                        child: const Text('아기 등록'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SummaryCard(
              title: '최근 로그',
              child: _latestEvent == null
                  ? const _EmptyHint(message: '아직 기록이 없습니다.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _latestEvent!.eventTypeLabel,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_latestEvent!.displayDetailSummary),
                        const SizedBox(height: 4),
                        Text(
                          _latestEvent!.recordedAt,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              _InlineMessage(
                message: _message!,
                color: colors.primaryContainer,
                textColor: colors.onPrimaryContainer,
              ),
            ],
            if (!canUseHome) ...[
              const SizedBox(height: 12),
              _InlineMessage(
                message: '지금은 홈을 불러올 수 없어요.',
                color: colors.errorContainer,
                textColor: colors.onErrorContainer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, this.child});

  final String title;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            if (child != null) ...[child!],
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SizedBox(
      width: 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                helper,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(badge),
              backgroundColor: badgeColor,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.message,
    required this.color,
    required this.textColor,
  });

  final String message;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
