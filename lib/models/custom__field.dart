// lib/models/custom_field.dart

import 'field_option.dart';

enum FieldType { text, number, dropdown, checkbox, date }

class CustomField {
  String id;
  String label;
  FieldType type;
  bool isRequired;
  List<FieldOption>? options;
  double? extraCost;

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
      type: FieldType.values
          .firstWhere((e) => e.toString() == 'FieldType.' + map['type']),
      isRequired: map['isRequired'] ?? false,
      options: map['options'] != null
          ? List<FieldOption>.from(
              map['options'].map((x) => FieldOption.fromMap(x)))
          : null,
      extraCost: map['extraCost']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'type': type.toString().split('.').last.toLowerCase(),
      'isRequired': isRequired,
      'options': options?.map((x) => x.toMap()).toList(),
      'extraCost': extraCost,
    };
  }
}
