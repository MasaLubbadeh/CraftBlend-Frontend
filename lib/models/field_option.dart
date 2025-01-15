// lib/models/field_option.dart

class FieldOption {
  String value;
  double extraCost;

  FieldOption({required this.value, required this.extraCost});

  factory FieldOption.fromMap(Map<String, dynamic> map) {
    return FieldOption(
      value: map['value'] ?? '',
      extraCost: map['extraCost']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'extraCost': extraCost,
    };
  }
}
