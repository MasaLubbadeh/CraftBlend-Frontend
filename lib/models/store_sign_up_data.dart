class StoreSignUpData {
  String? firstName;
  String? lastName;
  String? email;
  String? phoneNumber;
  String? password;
  String? accountType;
  String? selectedGenre; // Changed from List<String> to a single String

  StoreSignUpData({
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.password,
    this.accountType,
    this.selectedGenre,
  });

  @override
  String toString() {
    return 'StoreSignUpData(firstName: $firstName, lastName: $lastName, email: $email, phoneNumber: $phoneNumber, password: $password, accountType: $accountType, selectedGenre: $selectedGenre)';
  }

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "phoneNumber": phoneNumber,
      "password": password,
      "accountType": accountType,
      "selectedGenre": selectedGenre,
    };
  }
}
