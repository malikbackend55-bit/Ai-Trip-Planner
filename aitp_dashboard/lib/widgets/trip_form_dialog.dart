import 'package:flutter/material.dart';

import '../core/theme.dart';

class TripFormDialog extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String destinationLabel;
  final String destinationHint;
  final String budgetLabel;
  final String defaultStatus;
  final List<String> statusOptions;
  final Map<String, dynamic>? initialData;
  final Future<String?> Function(Map<String, dynamic> values) onSubmit;

  const TripFormDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.destinationLabel,
    required this.destinationHint,
    required this.budgetLabel,
    required this.defaultStatus,
    required this.statusOptions,
    required this.onSubmit,
    this.initialData,
  });

  @override
  State<TripFormDialog> createState() => _TripFormDialogState();
}

class _TripFormDialogState extends State<TripFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _destinationController;
  late final TextEditingController _budgetController;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _selectedStatus;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final initialData = widget.initialData;
    final now = DateTime.now();
    final defaultStart = DateTime(now.year, now.month, now.day);
    final defaultEnd = defaultStart.add(const Duration(days: 3));

    _destinationController = TextEditingController(
      text: initialData?['destination']?.toString() ?? '',
    );
    _budgetController = TextEditingController(
      text: _normalizeBudget(initialData?['budget']),
    );
    _startDate = _parseDate(initialData?['start_date'], defaultStart);
    _endDate = _parseDate(initialData?['end_date'], defaultEnd);
    if (_endDate.isBefore(_startDate)) {
      _endDate = _startDate;
    }
    _selectedStatus = _normalizeStatus(initialData?['status']);
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  String _normalizeBudget(dynamic value) {
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed == 0) {
      return '';
    }

    if (parsed == parsed.roundToDouble()) {
      return parsed.toStringAsFixed(0);
    }

    return parsed.toStringAsFixed(2);
  }

  DateTime _parseDate(dynamic value, DateTime fallback) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      return fallback;
    }

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  String _normalizeStatus(dynamic value) {
    final rawValue = value?.toString().trim() ?? '';
    if (widget.statusOptions.contains(rawValue)) {
      return rawValue;
    }

    final lower = rawValue.toLowerCase();

    if (widget.statusOptions.contains('Active') &&
        (lower.isEmpty ||
            lower == 'active' ||
            lower == 'upcoming' ||
            lower == 'scheduled' ||
            lower == 'in progress')) {
      return 'Active';
    }

    if (widget.statusOptions.contains('Featured') && lower == 'featured') {
      return 'Featured';
    }

    if (widget.statusOptions.contains('Hidden') &&
        (lower == 'hidden' || lower == 'cancelled' || lower == 'canceled')) {
      return 'Hidden';
    }

    if (widget.statusOptions.contains('Completed') &&
        (lower == 'completed' || lower == 'past')) {
      return 'Completed';
    }

    if (widget.statusOptions.contains('Cancelled') &&
        (lower == 'cancelled' || lower == 'canceled')) {
      return 'Cancelled';
    }

    if (widget.statusOptions.contains('Upcoming') &&
        (lower.isEmpty ||
            lower == 'upcoming' ||
            lower == 'scheduled' ||
            lower == 'in progress' ||
            lower == 'active')) {
      return 'Upcoming';
    }

    return widget.defaultStatus;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = isStart ? DateTime(2020) : _startDate;
    final lastDate = DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = DateTime(picked.year, picked.month, picked.day);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final trimmedBudget = _budgetController.text.trim();
    final parsedBudget = trimmedBudget.isEmpty
        ? null
        : double.tryParse(trimmedBudget);

    if (trimmedBudget.isNotEmpty && parsedBudget == null) {
      setState(() {
        _errorMessage = 'Budget must be a valid number.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final error = await widget.onSubmit({
      'destination': _destinationController.text.trim(),
      'start_date': DateUtils.dateOnly(_startDate).toIso8601String(),
      'end_date': DateUtils.dateOnly(_endDate).toIso8601String(),
      'budget': parsedBudget,
      'status': _selectedStatus,
    });

    if (!mounted) {
      return;
    }

    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage = error;
    });
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _destinationController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: widget.destinationLabel,
                    hintText: widget.destinationHint,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DialogDateField(
                        label: 'Start Date',
                        value: _formatDate(_startDate),
                        onTap: _isSubmitting
                            ? null
                            : () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogDateField(
                        label: 'End Date',
                        value: _formatDate(_endDate),
                        onTap: _isSubmitting
                            ? null
                            : () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _budgetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.budgetLabel,
                    hintText: 'e.g. 2500',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: widget.statusOptions
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          }
                        },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class _DialogDateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _DialogDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value),
      ),
    );
  }
}
