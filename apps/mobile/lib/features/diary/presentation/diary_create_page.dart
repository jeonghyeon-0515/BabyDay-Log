import 'package:flutter/material.dart';

import '../data/diary_repository.dart';
import '../domain/diary_create_baby_option.dart';

class DiaryCreatePage extends StatefulWidget {
  const DiaryCreatePage({super.key, required this.repository});

  final DiaryRepository repository;

  @override
  State<DiaryCreatePage> createState() => _DiaryCreatePageState();
}

class _DiaryCreatePageState extends State<DiaryCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();
  List<DiaryCreateBabyOption> _babyOptions = const [];
  String? _selectedBabyId;
  String _selectedVisibility = 'private';
  bool _isLoadingOptions = false;
  bool _isSaving = false;
  String? _message;
  DateTime? _selectedEventDate;

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

  Future<void> _pickEventDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEventDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (picked == null) return;

    setState(() {
      _selectedEventDate = picked;
      _eventDateController.text =
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
      await widget.repository.createDiaryEntry(
        babyId: _selectedBabyId!,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        body: _bodyController.text.trim(),
        visibility: _selectedVisibility,
        eventDate: _eventDateController.text.trim().isEmpty
            ? null
            : _eventDateController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _message = '일기가 저장되었습니다.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '일기 저장 실패: $error';
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
    _titleController.dispose();
    _bodyController.dispose();
    _eventDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일기 작성')),
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
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '내용을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedVisibility,
                  decoration: const InputDecoration(
                    labelText: '공개 범위',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'private', child: Text('비공개')),
                    DropdownMenuItem(
                      value: 'household',
                      child: Text('household 공유'),
                    ),
                    DropdownMenuItem(value: 'public', child: Text('공개')),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedVisibility = value ?? 'private'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _eventDateController,
                  readOnly: true,
                  onTap: _pickEventDate,
                  decoration: const InputDecoration(
                    labelText: '일기 날짜',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? '저장 중...' : '일기 저장'),
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
