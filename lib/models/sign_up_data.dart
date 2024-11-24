class SignUpData {
  String? firstName;
  String? lastName;
  String? email;
  String? phoneNumber;
  String? password;
  String? accountType; // New field for account type
  List<String>? selectedGenres; // New field for selected genres

  // Constructor to include selectedGenres
  SignUpData({
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.password,
    this.accountType,
    this.selectedGenres, // Include selectedGenres in constructor
  });

  // Method to convert the object to JSON
  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "phoneNumber": phoneNumber,
      "password": password,
      "accountType": accountType, // Add accountType to the map
      "selectedGenres": selectedGenres, // Add selectedGenres to the map
    };
  }
}
