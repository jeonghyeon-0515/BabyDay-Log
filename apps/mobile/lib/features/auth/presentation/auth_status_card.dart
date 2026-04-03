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
    final bootstrapState = widget.bootstrapState;
    final canUseAuth = bootstrapState.supabaseInitialized;
    final user = _repository?.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('인증 상태', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _AuthInfoRow(
              label: '세션 상태',
              value: _session == null ? '비로그인' : '로그인됨',
            ),
            _AuthInfoRow(label: '사용자 ID', value: user?.id ?? '없음'),
            _AuthInfoRow(label: '이메일', value: user?.email ?? '없음'),
            const SizedBox(height: 12),
            Text(
              '우선순위: 카카오 → 네이버 → 구글',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppAuthProvider.values.map((provider) {
                final supported = provider.isDirectlySupportedByCurrentStack;
                final enabled = canUseAuth && supported && !_isProcessing;
                return FilledButton.tonal(
                  onPressed: enabled ? () => _signIn(provider) : null,
                  child: Text(provider.label),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            for (final provider in AppAuthProvider.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '- ${provider.shortLabel}: ${provider.helperText}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _session != null && !_isProcessing ? _signOut : null,
              child: const Text('로그아웃'),
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _feedbackMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            if (!canUseAuth) ...[
              const SizedBox(height: 12),
              Text(
                'SUPABASE_URL / SUPABASE_ANON_KEY dart-define 설정 후 인증을 사용할 수 있습니다.',
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

class _AuthInfoRow extends StatelessWidget {
  const _AuthInfoRow({required this.label, required this.value});

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
            width: 88,
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
