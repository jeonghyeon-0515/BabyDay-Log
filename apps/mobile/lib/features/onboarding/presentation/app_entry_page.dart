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
        _message = '상태를 불러오지 못했어요. 다시 시도해 주세요.';
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
            ? '브라우저에서 ${provider.shortLabel} 로그인을 진행해 주세요.'
            : '${provider.shortLabel} 로그인을 열지 못했어요.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '로그인을 시작하지 못했어요.';
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
    final setupSteps = [
      _SetupStep(label: '로그인', done: _stage.index > AppEntryStage.unauthenticated.index),
      _SetupStep(label: '프로필', done: _stage.index > AppEntryStage.needsProfile.index),
      _SetupStep(label: '가족', done: _stage.index > AppEntryStage.needsHousehold.index),
      _SetupStep(label: '아기', done: _stage.index > AppEntryStage.needsBaby.index),
    ];

    switch (_stage) {
      case AppEntryStage.checking:
        return const _EntryScaffold(
          title: '준비 중',
          description: '잠시만 기다려 주세요.',
          child: Center(child: CircularProgressIndicator()),
        );
      case AppEntryStage.unauthenticated:
        return _EntryScaffold(
          title: '로그인해 주세요',
          description: '로그인 방법을 선택해 주세요.',
          message: _message,
          steps: setupSteps,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final provider in AppAuthProvider.values.where(
                (provider) => provider.isDirectlySupportedByCurrentStack,
              )) ...[
                if (provider == AppAuthProvider.kakao)
                  FilledButton(
                    onPressed: _isBusy ? null : () => _signIn(provider),
                    child: Text(provider.label),
                  )
                else
                  FilledButton.tonal(
                    onPressed: _isBusy ? null : () => _signIn(provider),
                    child: Text(provider.label),
                  ),
                const SizedBox(height: 10),
              ],
              Text(
                '네이버 로그인은 준비 중이에요.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      case AppEntryStage.needsProfile:
        return _EntryScaffold(
          title: '프로필을 먼저 설정해 주세요',
          description: '이름만 입력하면 바로 시작할 수 있어요.',
          message: _message,
          steps: setupSteps,
          child: FilledButton(
            onPressed: _openProfileSetup,
            child: const Text('프로필 설정'),
          ),
        );
      case AppEntryStage.needsHousehold:
        return _EntryScaffold(
          title: '가족을 먼저 만들어 주세요',
          description: '가족 이름만 정하면 바로 이어서 등록할 수 있어요.',
          message: _message,
          steps: setupSteps,
          child: FilledButton(
            onPressed: _openHouseholdSetup,
            child: const Text('가족 만들기'),
          ),
        );
      case AppEntryStage.needsBaby:
        return _EntryScaffold(
          title: '아기를 먼저 등록해 주세요',
          description: '이름과 생일만 입력하면 시작할 수 있어요.',
          message: _message,
          steps: setupSteps,
          child: FilledButton(
            onPressed: _openBabySetup,
            child: const Text('아기 등록'),
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
    this.steps = const [],
  });

  final String title;
  final String description;
  final Widget child;
  final String? message;
  final List<_SetupStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primaryContainer.withValues(alpha: 0.8),
              colors.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.nightlight_round,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '육퇴로그',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '기록부터 일기까지 한 번에',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(description, style: theme.textTheme.bodyMedium),
                          if (steps.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: steps
                                  .map(
                                    (step) => Chip(
                                      avatar: Icon(
                                        step.done
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        size: 18,
                                      ),
                                      label: Text(step.label),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 20),
                          child,
                          if (message != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                message!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupStep {
  const _SetupStep({required this.label, required this.done});

  final String label;
  final bool done;
}
