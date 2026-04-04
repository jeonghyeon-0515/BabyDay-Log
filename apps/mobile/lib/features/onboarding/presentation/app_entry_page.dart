import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../bootstrap.dart';
import '../../app_shell/presentation/app_shell_page.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_auth_provider.dart';
import '../../baby/data/baby_repository.dart';
import '../../baby/presentation/baby_create_page.dart';
import '../../household/data/household_repository.dart';
import '../../household/presentation/household_create_page.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/profile_edit_page.dart';

enum AppEntryStage {
  checking,
  unauthenticated,
  needsProfile,
  needsHousehold,
  needsBaby,
  ready,
}

class AppEntryPage extends StatefulWidget {
  const AppEntryPage({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  State<AppEntryPage> createState() => _AppEntryPageState();
}

class _AppEntryPageState extends State<AppEntryPage> {
  AuthRepository? _authRepository;
  ProfileRepository? _profileRepository;
  HouseholdRepository? _householdRepository;
  BabyRepository? _babyRepository;
  StreamSubscription<AuthState>? _authSubscription;
  AppEntryStage _stage = AppEntryStage.checking;
  bool _isBusy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (!widget.bootstrapState.supabaseInitialized) {
      _stage = AppEntryStage.ready;
      return;
    }

    _authRepository = AuthRepository();
    _profileRepository = ProfileRepository();
    _householdRepository = HouseholdRepository();
    _babyRepository = BabyRepository();
    _authSubscription = _authRepository?.authStateChanges().listen((_) {
      _resolveStage();
    });
    _resolveStage();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _resolveStage() async {
    final authRepository = _authRepository;
    final profileRepository = _profileRepository;
    final householdRepository = _householdRepository;
    final babyRepository = _babyRepository;

    if (authRepository == null ||
        profileRepository == null ||
        householdRepository == null ||
        babyRepository == null) {
      if (mounted) {
        setState(() {
          _stage = AppEntryStage.ready;
        });
      }
      return;
    }

    setState(() {
      _stage = AppEntryStage.checking;
      _message = null;
    });

    try {
      if (authRepository.currentSession == null) {
        if (!mounted) return;
        setState(() => _stage = AppEntryStage.unauthenticated);
        return;
      }

      final profile = await profileRepository.fetchMyProfile();
      if (profile == null) {
        if (!mounted) return;
        setState(() => _stage = AppEntryStage.needsProfile);
        return;
      }

      final households = await householdRepository.fetchMyHouseholds();
      final activeHouseholds = households
          .where((household) => household.status == 'active')
          .toList();
      if (activeHouseholds.isEmpty) {
        if (!mounted) return;
        setState(() => _stage = AppEntryStage.needsHousehold);
        return;
      }

      final babies = await babyRepository.fetchMyBabies();
      if (babies.isEmpty) {
        if (!mounted) return;
        setState(() => _stage = AppEntryStage.needsBaby);
        return;
      }

      if (!mounted) return;
      setState(() => _stage = AppEntryStage.ready);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '초기 진입 상태 판별 실패: $error';
        _stage = AppEntryStage.unauthenticated;
      });
    }
  }

  Future<void> _signIn(AppAuthProvider provider) async {
    final authRepository = _authRepository;
    if (authRepository == null) return;

    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      final launched = await authRepository.signInWithProvider(provider);
      if (!mounted) return;
      setState(() {
        _message = launched
            ? '${provider.shortLabel} 로그인 브라우저를 열었습니다.'
            : '${provider.shortLabel} 로그인 브라우저를 열지 못했습니다.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _openProfileSetup() async {
    final profileRepository = _profileRepository;
    if (profileRepository == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileEditPage(repository: profileRepository),
      ),
    );
    await _resolveStage();
  }

  Future<void> _openHouseholdSetup() async {
    final householdRepository = _householdRepository;
    if (householdRepository == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HouseholdCreatePage(repository: householdRepository),
      ),
    );
    await _resolveStage();
  }

  Future<void> _openBabySetup() async {
    final babyRepository = _babyRepository;
    if (babyRepository == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BabyCreatePage(repository: babyRepository),
      ),
    );
    await _resolveStage();
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case AppEntryStage.checking:
        return const _EntryScaffold(
          title: '시작 준비 중',
          description: '계정과 기본 데이터를 확인하고 있습니다.',
          child: Center(child: CircularProgressIndicator()),
        );
      case AppEntryStage.unauthenticated:
        return _EntryScaffold(
          title: '로그인이 필요합니다',
          description: '카카오 → 네이버 → 구글 순으로 로그인을 지원합니다.',
          message: _message,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppAuthProvider.values.map((provider) {
              final enabled =
                  provider.isDirectlySupportedByCurrentStack && !_isBusy;
              return FilledButton.tonal(
                onPressed: enabled ? () => _signIn(provider) : null,
                child: Text(provider.label),
              );
            }).toList(),
          ),
        );
      case AppEntryStage.needsProfile:
        return _EntryScaffold(
          title: '프로필 설정이 필요합니다',
          description: '표시 이름과 기본 언어/시간대를 먼저 저장해주세요.',
          message: _message,
          child: FilledButton(
            onPressed: _openProfileSetup,
            child: const Text('프로필 설정으로 이동'),
          ),
        );
      case AppEntryStage.needsHousehold:
        return _EntryScaffold(
          title: 'Household 생성이 필요합니다',
          description: '가족/양육 그룹을 먼저 만들어야 아기와 기록을 연결할 수 있습니다.',
          message: _message,
          child: FilledButton(
            onPressed: _openHouseholdSetup,
            child: const Text('Household 생성으로 이동'),
          ),
        );
      case AppEntryStage.needsBaby:
        return _EntryScaffold(
          title: '첫 아기 등록이 필요합니다',
          description: '아기를 등록하면 홈/기록/분석/일기 탭이 실제 데이터와 연결됩니다.',
          message: _message,
          child: FilledButton(
            onPressed: _openBabySetup,
            child: const Text('아기 등록으로 이동'),
          ),
        );
      case AppEntryStage.ready:
        return AppShellPage(bootstrapState: widget.bootstrapState);
    }
  }
}

class _EntryScaffold extends StatelessWidget {
  const _EntryScaffold({
    required this.title,
    required this.description,
    required this.child,
    this.message,
  });

  final String title;
  final String description;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('BabyDay Log')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    Text(description, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    child,
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
