// lib/models/field_option.dart

class FieldOption {
  String value; // The display value of the option (e.g., "Small")
  double extraCost; // The additional cost associated with this option

  FieldOption({
    required this.value,
    this.extraCost = 0.0,
  });

  factory FieldOption.fromMap(Map<String, dynamic> map) {
    return FieldOption(
      value: map['value'] ?? '',
      extraCost: map['extraCost'] != null ? map['extraCost'].toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'extraCost': extraCost,
    };
  }
}
