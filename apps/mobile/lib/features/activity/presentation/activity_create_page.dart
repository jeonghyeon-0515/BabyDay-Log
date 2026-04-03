import 'package:flutter/material.dart';

import '../data/activity_repository.dart';
import '../domain/activity_create_baby_option.dart';

class ActivityCreatePage extends StatefulWidget {
  const ActivityCreatePage({super.key, required this.repository});

  final ActivityRepository repository;

  @override
  State<ActivityCreatePage> createState() => _ActivityCreatePageState();
}

class _ActivityCreatePageState extends State<ActivityCreatePage> {
  final _formKey = GlobalKey<FormState>();
  List<ActivityCreateBabyOption> _babyOptions = const [];
  String? _selectedBabyId;
  String _selectedEventType = 'bottle_feeding';
  final TextEditingController _recordedAtController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingOptions = false;
  String? _message;
  DateTime? _selectedRecordedAt;

  @override
  void initState() {
    super.initState();
    _loadBabies();
  }

  Future<void> _loadBabies() async {
    setState(() {
      _isLoadingOptions = true;
      _message = null;
    });

    try {
      final options = await widget.repository.fetchCreateBabyOptions();
      if (!mounted) return;
      setState(() {
        _babyOptions = options;
        _selectedBabyId = options.isEmpty ? null : options.first.id;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '아기 목록 조회 실패: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOptions = false;
        });
      }
    }
  }

  Future<void> _pickRecordedAt() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedRecordedAt ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedRecordedAt ?? now),
    );

    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _selectedRecordedAt = combined;
      _recordedAtController.text =
          '${combined.year.toString().padLeft(4, '0')}-'
          '${combined.month.toString().padLeft(2, '0')}-'
          '${combined.day.toString().padLeft(2, '0')} '
          '${combined.hour.toString().padLeft(2, '0')}:'
          '${combined.minute.toString().padLeft(2, '0')}';
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
      await widget.repository.createActivityEvent(
        babyId: _selectedBabyId!,
        eventTypeSlug: _selectedEventType,
        recordedAt: _selectedRecordedAt!,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _message = 'activity event가 생성되었습니다.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'activity 생성 실패: $error';
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
    _recordedAtController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity 생성')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedBabyId,
                  decoration: const InputDecoration(
                    labelText: '아기',
                    border: OutlineInputBorder(),
                  ),
                  items: _babyOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.id,
                          child: Text(option.name),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoadingOptions
                      ? null
                      : (value) => setState(() => _selectedBabyId = value),
                  validator: (value) => value == null ? '아기를 선택해주세요.' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedEventType,
                  decoration: const InputDecoration(
                    labelText: '이벤트 타입',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'bottle_feeding',
                      child: Text('젖병/분유'),
                    ),
                    DropdownMenuItem(
                      value: 'breastfeeding',
                      child: Text('모유수유'),
                    ),
                    DropdownMenuItem(value: 'sleep', child: Text('수면')),
                    DropdownMenuItem(value: 'diaper', child: Text('기저귀')),
                  ],
                  onChanged: (value) => setState(
                    () => _selectedEventType = value ?? 'bottle_feeding',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _recordedAtController,
                  readOnly: true,
                  onTap: _pickRecordedAt,
                  decoration: const InputDecoration(
                    labelText: '기록 시각',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '기록 시각을 선택해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '메모',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? '저장 중...' : 'Activity 생성'),
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
