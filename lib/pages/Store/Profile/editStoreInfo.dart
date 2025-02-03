import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../configuration/config.dart';

class EditStoreProfile extends StatefulWidget {
  const EditStoreProfile({super.key});

  @override
  _EditStoreProfileState createState() => _EditStoreProfileState();
}

class _EditStoreProfileState extends State<EditStoreProfile> {
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  String? _originalStoreName;
  String? _originalContactEmail;
  String? _originalPhoneNumber;
  String? _originalCity;

  bool _isSaving = false;
  bool hasChanges = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
  }

  Future<void> _fetchStoreData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token != null) {
      final response = await http.get(
        Uri.parse(getStoreDetails),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _originalStoreName = data['storeName'] ?? '';
          _originalContactEmail = data['contactEmail'] ?? '';
          _originalPhoneNumber = data['phoneNumber'] ?? '';
          _originalCity = data['city'] ?? '';

          _storeNameController.text = _originalStoreName!;
          _contactEmailController.text = _originalContactEmail!;
          _phoneNumberController.text = _originalPhoneNumber!;
          _cityController.text = _originalCity!;

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        title: const Text("Edit Store Profile",
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: Colors.white70)),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                        "Store Name", _storeNameController, Icons.store),
                    const SizedBox(height: 16),
                    _buildInputField(
                        "Contact Email", _contactEmailController, Icons.email),
                    const SizedBox(height: 16),
                    _buildInputField(
                        "Phone Number", _phoneNumberController, Icons.phone,
                        isNumber: true),
                    const SizedBox(height: 16),
                    _buildInputField(
                        "City", _cityController, Icons.location_city),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInputField(
      String label, TextEditingController controller, IconData icon,
      {bool isNumber = false}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            Icon(icon, color: myColor),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType:
                    isNumber ? TextInputType.phone : TextInputType.text,
                decoration: InputDecoration(
                    labelText: label,
                    labelStyle: const TextStyle(color: Colors.black54),
                    border: InputBorder.none),
                onChanged: (value) {
                  _checkForChanges();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: hasChanges && !_isSaving ? _saveChanges : null,
        style: ElevatedButton.styleFrom(
            backgroundColor: myColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0)),
        child: _isSaving
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : const Text("Save Changes",
                style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  void _checkForChanges() {
    setState(() {
      hasChanges = (_storeNameController.text != _originalStoreName) ||
          (_contactEmailController.text != _originalContactEmail) ||
          (_phoneNumberController.text != _originalPhoneNumber) ||
          (_cityController.text != _originalCity);
    });
  }

  Future<void> _saveChanges() async {
    if (!hasChanges) return;

    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token != null) {
      final response = await http.post(
        Uri.parse('updateStoreInfo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'storeName': _storeNameController.text,
          'contactEmail': _contactEmailController.text,
          'phoneNumber': _phoneNumberController.text,
          'city': _cityController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Store information updated successfully'),
            duration: Duration(seconds: 2)));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Error saving changes: please enter valid data'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3)));
      }
    }

    setState(() => _isSaving = false);
  }
}
