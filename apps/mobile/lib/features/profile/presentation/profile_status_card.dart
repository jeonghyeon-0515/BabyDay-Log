import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';
import 'profile_edit_page.dart';

class ProfileStatusCard extends StatefulWidget {
  const ProfileStatusCard({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  State<ProfileStatusCard> createState() => _ProfileStatusCardState();
}

class _ProfileStatusCardState extends State<ProfileStatusCard> {
  ProfileRepository? _repository;
  UserProfile? _profile;
  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.bootstrapState.supabaseInitialized) {
      _repository = ProfileRepository();
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final repository = _repository;
    if (repository == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final profile = await repository.fetchMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _message = profile == null ? 'profiles 테이블에 아직 프로필이 없습니다.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '프로필 조회 실패: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canUseProfile = widget.bootstrapState.supabaseInitialized;
    final currentUser = _repository?.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('프로필 상태', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _ProfileRow(label: '로그인 사용자', value: currentUser?.id ?? '없음'),
            _ProfileRow(label: '표시 이름', value: _profile?.displayName ?? '없음'),
            _ProfileRow(label: 'locale', value: _profile?.locale ?? '없음'),
            _ProfileRow(label: 'timezone', value: _profile?.timezone ?? '없음'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: canUseProfile && !_isLoading ? _loadProfile : null,
                  child: Text(_isLoading ? '조회 중...' : '프로필 다시 조회'),
                ),
                OutlinedButton(
                  onPressed: canUseProfile && _repository != null
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ProfileEditPage(repository: _repository!),
                          ),
                        )
                      : null,
                  child: const Text('프로필 설정'),
                ),
              ],
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
            if (!canUseProfile) ...[
              const SizedBox(height: 12),
              Text(
                'Supabase 초기화 후 프로필 조회를 사용할 수 있습니다.',
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

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

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
