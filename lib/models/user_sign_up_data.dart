class SignUpData {
  String? firstName;
  String? lastName;
  String? email;
  String? phoneNumber;
  String? password;
  String? accountType;
  List<String>? selectedGenres; // Assuming you have this in your class

  SignUpData({
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.password,
    this.accountType,
    this.selectedGenres,
  });

  // Override the toString method to print the object in a readable format
  @override
  String toString() {
    return 'SignUpData(firstName: $firstName, lastName: $lastName, email: $email, phoneNumber: $phoneNumber, password: $password, accountType: $accountType, selectedGenres: $selectedGenres)';
  }

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "phoneNumber": phoneNumber,
      "password": password,
      "accountType": accountType,
      "selectedGenres": selectedGenres,
    };
  }
}
