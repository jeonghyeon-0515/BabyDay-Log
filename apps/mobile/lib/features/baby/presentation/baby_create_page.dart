import 'package:flutter/material.dart';

import '../data/baby_repository.dart';
import '../domain/baby_create_household_option.dart';

class BabyCreatePage extends StatefulWidget {
  const BabyCreatePage({super.key, required this.repository});

  final BabyRepository repository;

  @override
  State<BabyCreatePage> createState() => _BabyCreatePageState();
}

class _BabyCreatePageState extends State<BabyCreatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final TextEditingController _birthDateController = TextEditingController();
  List<BabyCreateHouseholdOption> _householdOptions = const [];
  String? _selectedHouseholdId;
  String _selectedSex = 'unknown';
  bool _isSaving = false;
  bool _isLoadingOptions = false;
  String? _message;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadHouseholds();
  }

  Future<void> _loadHouseholds() async {
    setState(() {
      _isLoadingOptions = true;
      _message = null;
    });

    try {
      final options = await widget.repository.fetchCreateHouseholdOptions();
      if (!mounted) return;
      setState(() {
        _householdOptions = options;
        _selectedHouseholdId = options.isEmpty ? null : options.first.id;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'household 목록 조회 실패: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOptions = false;
        });
      }
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (picked == null) return;

    setState(() {
      _selectedBirthDate = picked;
      _birthDateController.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      await widget.repository.createBaby(
        householdId: _selectedHouseholdId!,
        name: _nameController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        sex: _selectedSex,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아기를 등록했어요.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '아기를 등록하지 못했어요.';
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
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('아기 등록')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedHouseholdId,
                  decoration: const InputDecoration(
                    labelText: '가족',
                    border: OutlineInputBorder(),
                  ),
                  items: _householdOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.id,
                          child: Text(option.name),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoadingOptions
                      ? null
                      : (value) => setState(() => _selectedHouseholdId = value),
                  validator: (value) =>
                      value == null ? '가족을 선택해 주세요.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '아기 이름',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '아기 이름을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  onTap: _pickBirthDate,
                  decoration: const InputDecoration(
                    labelText: '생년월일',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '생년월일을 선택해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSex,
                  decoration: const InputDecoration(
                    labelText: '성별',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'unknown', child: Text('미정 / 비공개')),
                    DropdownMenuItem(value: 'male', child: Text('남아')),
                    DropdownMenuItem(value: 'female', child: Text('여아')),
                    DropdownMenuItem(value: 'other', child: Text('기타')),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedSex = value ?? 'unknown'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? '저장 중...' : '아기 등록'),
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
