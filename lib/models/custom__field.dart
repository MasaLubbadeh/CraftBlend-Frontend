// lib/models/custom_field.dart

import 'field_option.dart';

enum FieldType {
  text,
  number,
  dropdown,
  checkbox,
  imageUpload,
  date,
  // Add more types as needed
}

class CustomField {
  String id; // Unique identifier
  String label;
  FieldType type;
  bool isRequired;
  List<FieldOption>? options; // For dropdowns, checkboxes
  double? extraCost; // Applicable if the field affects pricing

  CustomField({
    required this.id,
    required this.label,
    required this.type,
    this.isRequired = false,
    this.options,
    this.extraCost,
  });

  factory CustomField.fromMap(Map<String, dynamic> map) {
    return CustomField(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      type: FieldType.values.firstWhere(
          (e) => e.toString() == 'FieldType.${map['type']}',
          orElse: () => FieldType.text),
      isRequired: map['isRequired'] ?? false,
      options: map['options'] != null
          ? List<FieldOption>.from(
              map['options'].map((option) => FieldOption.fromMap(option)))
          : null,
      extraCost: map['extraCost'] != null ? map['extraCost'].toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'type': type.toString().split('.').last,
      'isRequired': isRequired,
      'options': options?.map((option) => option.toMap()).toList(),
      'extraCost': extraCost,
    };
  }
}
