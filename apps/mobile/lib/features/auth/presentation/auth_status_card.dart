import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../bootstrap.dart';
import '../data/auth_repository.dart';
import '../domain/app_auth_provider.dart';

class AuthStatusCard extends StatefulWidget {
  const AuthStatusCard({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  State<AuthStatusCard> createState() => _AuthStatusCardState();
}

class _AuthStatusCardState extends State<AuthStatusCard> {
  AuthRepository? _repository;
  StreamSubscription<AuthState>? _subscription;
  Session? _session;
  String? _feedbackMessage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.bootstrapState.supabaseInitialized) {
      _repository = AuthRepository();
      _session = _repository?.currentSession;
      _subscription = _repository?.authStateChanges().listen((authState) {
        if (!mounted) return;
        setState(() {
          _session = authState.session;
        });
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _signIn(AppAuthProvider provider) async {
    setState(() {
      _isProcessing = true;
      _feedbackMessage = null;
    });

    try {
      final launched = await _repository!.signInWithProvider(provider);
      if (!mounted) return;
      setState(() {
        _feedbackMessage = launched
            ? '${provider.shortLabel} 로그인 브라우저를 열었습니다.'
            : '${provider.shortLabel} 로그인 브라우저를 열지 못했습니다.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _feedbackMessage = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isProcessing = true;
      _feedbackMessage = null;
    });

    try {
      await _repository!.signOut();
      if (!mounted) return;
      setState(() {
        _feedbackMessage = '로그아웃되었습니다.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _feedbackMessage = '로그아웃에 실패했습니다: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bootstrapState = widget.bootstrapState;
    final canUseAuth = bootstrapState.supabaseInitialized;
    final user = _repository?.currentUser;
    final directProviders = AppAuthProvider.values
        .where((provider) => provider.isDirectlySupportedByCurrentStack)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.primary,
                  child: Icon(_session == null ? Icons.person_outline : Icons.check),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('계정', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        _session == null ? '로그인되어 있지 않아요.' : (user?.email ?? '로그인됨'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_session == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final provider in directProviders) ...[
                    if (provider == AppAuthProvider.kakao)
                      FilledButton(
                        onPressed: canUseAuth && !_isProcessing
                            ? () => _signIn(provider)
                            : null,
                        child: Text(provider.label),
                      )
                    else
                      FilledButton.tonal(
                        onPressed: canUseAuth && !_isProcessing
                            ? () => _signIn(provider)
                            : null,
                        child: Text(provider.label),
                      ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    '네이버 로그인은 준비 중이에요.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            else
              OutlinedButton(
                onPressed: !_isProcessing ? _signOut : null,
                child: const Text('로그아웃'),
              ),
            const SizedBox(height: 12),
            if (_feedbackMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _feedbackMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (!canUseAuth) ...[
              const SizedBox(height: 12),
              Text(
                '로그인을 사용할 수 없어요.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
