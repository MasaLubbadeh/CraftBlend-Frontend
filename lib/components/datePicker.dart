// lib/widgets/date_picker_field.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatefulWidget {
  final String label;
  final bool isRequired;

  const DatePickerField({
    Key? key,
    required this.label,
    this.isRequired = false,
  }) : super(key: key);

  @override
  _DatePickerFieldState createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  DateTime? selectedDate;
  final TextEditingController _controller = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label + (widget.isRequired ? ' *' : ''),
            hintText: 'Select a date',
            suffixIcon: const Icon(Icons.calendar_today),
            iconColor: Colors.white70,
            suffixIconColor: Colors.white70,
            border: const OutlineInputBorder(),
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: const TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70, width: 2.0),
            ),
          ),
          /*validator: (value) {
            if (widget.isRequired && (value == null || value.isEmpty)) {
              return 'Please select a date';
            }
            return null;
          },*/
        ),
      ),
    );
  }
}
