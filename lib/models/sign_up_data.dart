class SignUpData {
  String? firstName;
  String? lastName;
  String? email;
  String? phoneNumber;
  String? password;
  String? accountType; // New field for account type

  // Constructor to include accountType
  SignUpData({
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.password,
    this.accountType, // Include accountType in constructor
  });

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "phoneNumber": phoneNumber,
      "password": password,
      "accountType": accountType, // Add accountType to the map
    };
  }
}
