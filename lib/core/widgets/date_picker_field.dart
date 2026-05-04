import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reusable date picker field that looks like a TextFormField.
class DatePickerField extends StatelessWidget {
  final DateTime value;
  final DateTime firstDate;
  final DateTime? lastDate;
  final String label;
  final ValueChanged<DateTime> onChanged;

  const DatePickerField({
    super.key,
    required this.value,
    required this.firstDate,
    this.lastDate,
    this.label = 'Data',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate,
          lastDate: lastDate ?? DateTime.now(),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(value)),
      ),
    );
  }
}
