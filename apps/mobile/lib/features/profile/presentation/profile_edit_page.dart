import 'package:flutter/material.dart';

import '../data/profile_repository.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key, required this.repository});

  final ProfileRepository repository;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _localeController;
  late final TextEditingController _timezoneController;
  bool _isSaving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _localeController = TextEditingController(text: 'ko');
    _timezoneController = TextEditingController(text: 'Asia/Seoul');
    _prefill();
  }

  Future<void> _prefill() async {
    final profile = await widget.repository.fetchMyProfile();
    if (!mounted || profile == null) return;
    _displayNameController.text = profile.displayName;
    _localeController.text = profile.locale;
    _timezoneController.text = profile.timezone;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      await widget.repository.upsertMyProfile(
        displayName: _displayNameController.text.trim(),
        locale: _localeController.text.trim(),
        timezone: _timezoneController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _message = '프로필이 저장되었습니다.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '프로필 저장 실패: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _localeController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: '표시 이름',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '표시 이름을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _localeController,
                  decoration: const InputDecoration(
                    labelText: 'locale',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _timezoneController,
                  decoration: const InputDecoration(
                    labelText: 'timezone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? '저장 중...' : '프로필 저장'),
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
        ],
      ),
    );
  }
}
