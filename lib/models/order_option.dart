// lib/models/order_option.dart

import 'custom__field.dart';

class OrderOption {
  String name; // Name of the option, e.g., "Custom-Made Cake"
  String description; // Description of the option
  bool isSelected;
  List<CustomField> customFields;
  bool requiresPhotoUpload;
  String photoUploadPrompt;

  OrderOption({
    required this.name,
    this.description = '',
    this.isSelected = false,
    List<CustomField>? customFields,
    this.requiresPhotoUpload = false,
    this.photoUploadPrompt = '',
  }) : customFields = customFields ?? [];

  factory OrderOption.fromMap(Map<String, dynamic> map) {
    return OrderOption(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isSelected: map['isSelected'] ?? false,
      customFields: map['customFields'] != null
          ? List<CustomField>.from(
              map['customFields'].map((x) => CustomField.fromMap(x)))
          : [],
      requiresPhotoUpload: map['requiresPhotoUpload'] ?? false,
      photoUploadPrompt: map['photoUploadPrompt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isSelected': isSelected,
      'customFields': customFields.map((x) => x.toMap()).toList(),
      'requiresPhotoUpload': requiresPhotoUpload,
      'photoUploadPrompt': photoUploadPrompt,
    };
  }
}
