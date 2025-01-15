// lib/models/order_option.dart

import 'custom__field.dart';

class OrderOption {
  String id; // Mapped from backend's _id
  String name;
  String description;
  bool isSelected; // Managed locally
  bool requiresPhotoUpload;
  String photoUploadPrompt;
  List<CustomField> customFields;

  OrderOption({
    required this.id,
    required this.name,
    this.description = '',
    this.isSelected = false,
    this.requiresPhotoUpload = false,
    this.photoUploadPrompt = '',
    List<CustomField>? customFields,
  }) : customFields = customFields ?? [];

  // Factory constructor to create an OrderOption from a map (e.g., JSON)
  factory OrderOption.fromMap(Map<String, dynamic> map) {
    return OrderOption(
      id: map['_id']?.toString() ?? '', // Map _id to id
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      requiresPhotoUpload: map['requiresPhotoUpload'] ?? false,
      photoUploadPrompt: map['photoUploadPrompt'] ?? '',
      customFields: map['customFields'] != null
          ? List<CustomField>.from(
              map['customFields'].map((x) => CustomField.fromMap(x)))
          : [],
    );
  }

  // Method to convert an OrderOption instance to a map (e.g., for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'requiresPhotoUpload': requiresPhotoUpload,
      'photoUploadPrompt': photoUploadPrompt,
      'customFields': customFields.map((x) => x.toMap()).toList(),
      // 'isSelected' is managed locally and not sent to backend
    };
  }
}
