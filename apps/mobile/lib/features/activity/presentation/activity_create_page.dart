import 'package:flutter/material.dart';

import '../data/activity_repository.dart';
import '../domain/activity_event_inputs.dart';
import '../domain/activity_event_type.dart';
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
  String _selectedBottleAmountUnit = 'ml';
  String _selectedBottleContentType = 'formula';
  String _selectedBreastSide = 'both';
  String _selectedSleepType = 'nap';
  String _selectedDiaperType = 'wet';
  bool _selectedRashObserved = false;
  final TextEditingController _recordedAtController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _bottleAmountController = TextEditingController();
  final TextEditingController _breastfeedingDurationController =
      TextEditingController();
  final TextEditingController _sleepDurationController =
      TextEditingController();
  final TextEditingController _sleepLocationController =
      TextEditingController();
  final TextEditingController _stoolColorController = TextEditingController();
  final TextEditingController _stoolTextureController = TextEditingController();
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
      final details = _buildEventDetails();

      await widget.repository.createActivityEvent(
        babyId: _selectedBabyId!,
        eventTypeSlug: _selectedEventType,
        recordedAt: _selectedRecordedAt!,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        feedingDetails: details.feedingDetails,
        sleepDetails: details.sleepDetails,
        diaperDetails: details.diaperDetails,
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
    _bottleAmountController.dispose();
    _breastfeedingDurationController.dispose();
    _sleepDurationController.dispose();
    _sleepLocationController.dispose();
    _stoolColorController.dispose();
    _stoolTextureController.dispose();
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
                  items: activityEventTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type.slug,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _selectedEventType = value ?? 'bottle_feeding',
                  ),
                ),
                const SizedBox(height: 12),
                if (_selectedEventType == 'bottle_feeding') ...[
                  _BuildSectionTitle(
                    title: '젖병/분유 세부 정보',
                    description: '수유량과 종류를 입력해 주세요.',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bottleAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '수유량',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_selectedEventType != 'bottle_feeding') {
                        return null;
                      }

                      final amount = _parsePositiveDouble(value);
                      if (amount == null) {
                        return '수유량을 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedBottleAmountUnit,
                          decoration: const InputDecoration(
                            labelText: '단위',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'ml', child: Text('ml')),
                            DropdownMenuItem(value: 'oz', child: Text('oz')),
                          ],
                          onChanged: (value) => setState(
                            () => _selectedBottleAmountUnit = value ?? 'ml',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedBottleContentType,
                          decoration: const InputDecoration(
                            labelText: '내용물',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'formula',
                              child: Text('분유'),
                            ),
                            DropdownMenuItem(
                              value: 'breast_milk',
                              child: Text('모유'),
                            ),
                            DropdownMenuItem(value: 'mixed', child: Text('혼합')),
                          ],
                          onChanged: (value) => setState(
                            () =>
                                _selectedBottleContentType = value ?? 'formula',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_selectedEventType == 'breastfeeding') ...[
                  _BuildSectionTitle(
                    title: '모유수유 세부 정보',
                    description: '수유 방향과 시간을 입력해 주세요.',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBreastSide,
                    decoration: const InputDecoration(
                      labelText: '수유 방향',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'left', child: Text('왼쪽')),
                      DropdownMenuItem(value: 'right', child: Text('오른쪽')),
                      DropdownMenuItem(value: 'both', child: Text('양쪽')),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedBreastSide = value ?? 'both'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _breastfeedingDurationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '수유 시간(분)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_selectedEventType != 'breastfeeding') {
                        return null;
                      }

                      final duration = _parsePositiveInt(value);
                      if (duration == null) {
                        return '수유 시간을 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                ],
                if (_selectedEventType == 'sleep') ...[
                  _BuildSectionTitle(
                    title: '수면 세부 정보',
                    description: '수면 종류, 장소, 시간을 입력해 주세요.',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSleepType,
                    decoration: const InputDecoration(
                      labelText: '수면 종류',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'nap', child: Text('낮잠')),
                      DropdownMenuItem(value: 'night', child: Text('밤잠')),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedSleepType = value ?? 'nap'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sleepLocationController,
                    decoration: const InputDecoration(
                      labelText: '수면 장소',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sleepDurationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '수면 시간(분)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_selectedEventType != 'sleep') {
                        return null;
                      }

                      final duration = _parsePositiveInt(value);
                      if (duration == null) {
                        return '수면 시간을 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                ],
                if (_selectedEventType == 'diaper') ...[
                  _BuildSectionTitle(
                    title: '기저귀 세부 정보',
                    description: '기저귀 종류와 부가 상태를 입력해 주세요.',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDiaperType,
                    decoration: const InputDecoration(
                      labelText: '기저귀 종류',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'wet', child: Text('소변')),
                      DropdownMenuItem(value: 'dirty', child: Text('대변')),
                      DropdownMenuItem(value: 'mixed', child: Text('혼합')),
                      DropdownMenuItem(value: 'dry', child: Text('건조')),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedDiaperType = value ?? 'wet'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stoolColorController,
                    decoration: const InputDecoration(
                      labelText: '변 색상(선택)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stoolTextureController,
                    decoration: const InputDecoration(
                      labelText: '변 상태(선택)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _selectedRashObserved,
                    title: const Text('발진 관찰'),
                    onChanged: (value) =>
                        setState(() => _selectedRashObserved = value ?? false),
                  ),
                ],
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

  ({
    ActivityFeedingDetails? feedingDetails,
    ActivitySleepDetails? sleepDetails,
    ActivityDiaperDetails? diaperDetails,
  })
  _buildEventDetails() {
    switch (_selectedEventType) {
      case 'bottle_feeding':
        return (
          feedingDetails: ActivityFeedingDetails(
            feedingMode: 'bottle',
            amountValue: _parsePositiveDouble(_bottleAmountController.text)!,
            amountUnit: _selectedBottleAmountUnit,
            contentType: _selectedBottleContentType,
          ),
          sleepDetails: null,
          diaperDetails: null,
        );
      case 'breastfeeding':
        return (
          feedingDetails: ActivityFeedingDetails(
            feedingMode: 'breast',
            breastSide: _selectedBreastSide,
            durationMinutes: _parsePositiveInt(
              _breastfeedingDurationController.text,
            )!,
          ),
          sleepDetails: null,
          diaperDetails: null,
        );
      case 'sleep':
        return (
          feedingDetails: null,
          sleepDetails: ActivitySleepDetails(
            sleepType: _selectedSleepType,
            durationMinutes: _parsePositiveInt(_sleepDurationController.text)!,
            location: _sleepLocationController.text.trim().isEmpty
                ? null
                : _sleepLocationController.text.trim(),
          ),
          diaperDetails: null,
        );
      case 'diaper':
        return (
          feedingDetails: null,
          sleepDetails: null,
          diaperDetails: ActivityDiaperDetails(
            diaperType: _selectedDiaperType,
            rashObserved: _selectedRashObserved,
            stoolColor: _stoolColorController.text.trim().isEmpty
                ? null
                : _stoolColorController.text.trim(),
            stoolTexture: _stoolTextureController.text.trim().isEmpty
                ? null
                : _stoolTextureController.text.trim(),
          ),
        );
      default:
        throw StateError('지원하지 않는 activity event type입니다: $_selectedEventType');
    }
  }

  int? _parsePositiveInt(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  double? _parsePositiveDouble(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }
}

class _BuildSectionTitle extends StatelessWidget {
  const _BuildSectionTitle({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(description, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
