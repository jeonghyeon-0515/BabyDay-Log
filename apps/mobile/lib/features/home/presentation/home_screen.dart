import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../../activity/data/activity_repository.dart';
import '../../activity/domain/activity_event_summary.dart';
import '../../activity/presentation/activity_create_page.dart';
import '../../baby/data/baby_repository.dart';
import '../../baby/domain/baby_summary.dart';
import '../../baby/presentation/baby_create_page.dart';
import '../../household/data/household_repository.dart';
import '../../household/domain/household_summary.dart';
import '../../household/presentation/household_create_page.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/profile_edit_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProfileRepository? _profileRepository;
  HouseholdRepository? _householdRepository;
  BabyRepository? _babyRepository;
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
      _babyRepository = BabyRepository();
      _activityRepository = ActivityRepository();
      _loadHomeData();
    }
  }

  Future<void> _loadHomeData() async {
    final profileRepository = _profileRepository;
    final householdRepository = _householdRepository;
    final babyRepository = _babyRepository;
    final activityRepository = _activityRepository;

    if (profileRepository == null ||
        householdRepository == null ||
        babyRepository == null ||
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
        babyRepository.fetchMyBabies(),
        activityRepository.fetchRecentActivityEvents(limit: 1),
      ]);

      if (!mounted) return;

      final households = (results[1] as List<HouseholdSummary>);
      final babies = (results[2] as List<BabySummary>);
      final events = (results[3] as List<ActivityEventSummary>);

      setState(() {
        _profile = results[0] as UserProfile?;
        _household = households.isEmpty ? null : households.first;
        _baby = babies.isEmpty ? null : babies.first;
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
      return '프로필을 먼저 저장하면 홈 화면 정보를 더 정확하게 보여줄 수 있습니다.';
    }
    if (household == null) {
      return 'Household를 생성하면 아기와 기록을 연결할 수 있습니다.';
    }
    if (baby == null) {
      return '아기를 생성하면 홈에서 오늘 상태를 보여줄 수 있습니다.';
    }
    if (event == null) {
      return '첫 activity를 기록하면 오늘 요약이 채워집니다.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canUseHome = widget.bootstrapState.supabaseInitialized;

    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('오늘 홈', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '현재 사용자, household, 아기, 최근 기록을 기준으로 오늘 상태를 보여줍니다.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _SummaryCard(
              title: '현재 아기',
              rows: [
                _SummaryRow(label: '이름', value: _baby?.name ?? '없음'),
                _SummaryRow(label: '생년월일', value: _baby?.birthDate ?? '없음'),
                _SummaryRow(label: '성별', value: _baby?.sex ?? '없음'),
              ],
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              title: 'Household 요약',
              rows: [
                _SummaryRow(label: '이름', value: _household?.name ?? '없음'),
                _SummaryRow(label: '역할', value: _household?.role ?? '없음'),
                _SummaryRow(
                  label: '성장 기준',
                  value: _household?.growthChartStandard ?? '없음',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              title: '최근 기록',
              rows: [
                _SummaryRow(
                  label: '이벤트 타입',
                  value: _latestEvent?.eventTypeSlug ?? '없음',
                ),
                _SummaryRow(label: '상태', value: _latestEvent?.status ?? '없음'),
                _SummaryRow(
                  label: '기록 시각',
                  value: _latestEvent?.recordedAt ?? '없음',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              title: '빠른 작업',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: canUseHome && !_isLoading ? _loadHomeData : null,
                    child: Text(_isLoading ? '새로고침 중...' : '홈 새로고침'),
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
                    child: const Text('프로필 저장'),
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
                    child: const Text('Household 생성'),
                  ),
                  OutlinedButton(
                    onPressed: _babyRepository != null
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  BabyCreatePage(repository: _babyRepository!),
                            ),
                          )
                        : null,
                    child: const Text('아기 생성'),
                  ),
                  OutlinedButton(
                    onPressed: _activityRepository != null
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ActivityCreatePage(
                                repository: _activityRepository!,
                              ),
                            ),
                          )
                        : null,
                    child: const Text('기록 추가'),
                  ),
                ],
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            if (!canUseHome) ...[
              const SizedBox(height: 12),
              Text(
                'Supabase 초기화 후 홈 탭을 사용할 수 있습니다.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, this.rows = const [], this.child});

  final String title;
  final List<_SummaryRow> rows;
  final Widget? child;

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
            if (child case final widgetChild?)
              widgetChild
            else
              ...rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          row.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(child: SelectableText(row.value)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;
}
